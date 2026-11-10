class_name NpcDecisionRuntime
extends RefCounted
## O fluxo de decisão do `npc` montado e em andamento (LW-063): o provedor de condições, o runner, o pontuador, o pensador (`NpcThinker`) e as ações
## sociais (`SocialActions`, LW-080), e a função única que inicia uma ação. LW-081a (passo 5): o código saiu do `NpcModule` sem mudar de comportamento; o
## módulo segue sendo a única porta e só delega aqui. A montagem é preguiçosa: acontece no primeiro `tick` (`run_step`), só se as definições estão completas.
## A tabela de NPCs é a do módulo (a mesma, por referência). O módulo dá as peças prontas (corpos, Intents, notáveis, ciclo de vida e rastro).

## LW-083a: a ação de conversar com o jogador (data/actions.json: 6 min [HIP], sem efeitos e sem local; só nasce por pedido, nunca por decisão do NPC).
const TALK_PLAYER_ACTION_ID: String = "talk_player"

var _npcs: Dictionary[int, NpcState]
var _bodies: NpcBodies
var _intents: NpcIntentBoard
var _notables: NpcNotables
var _lifecycle: NpcLifecycle
var _tracer: DecisionTracer
var _definitions: NpcModule.Definitions
var _need_defs: Array[NeedDef]
## Motivo de as definições de necessidades não servirem (vazio = servem), conferido uma vez pelo módulo.
var _defs_problem: String
var _routine: RoutineTable
var _ctx: SimContext
## Fluxo de decisão (LW-063): montado no primeiro `tick`, só se as definições estão completas. `_decision_problem` diz por que não.
var _decision_checked: bool = false
var _decision_problem: String = ""
var _runner: ActionRunner
var _provider: NpcThinker.ConditionProvider
var _thinker: NpcThinker
## Consequências sociais de `talk` e `help` (LW-080): montado junto com o pensador, que avisa quando uma ação termina.
var _social: SocialActions


func _init(npcs: Dictionary[int, NpcState], bodies: NpcBodies, intents: NpcIntentBoard, notables: NpcNotables, lifecycle: NpcLifecycle, tracer: DecisionTracer, definitions: NpcModule.Definitions, need_defs: Array[NeedDef], defs_problem: String, routine: RoutineTable) -> void:
	_npcs = npcs
	_bodies = bodies
	_intents = intents
	_notables = notables
	_lifecycle = lifecycle
	_tracer = tracer
	_definitions = definitions
	_need_defs = need_defs
	_defs_problem = defs_problem
	_routine = routine


func setup(ctx: SimContext) -> void:
	_ctx = ctx


## A fila de pensamento de um passo (LW-063): quem chegou no seu `next_think_time` pensa, até `max_thinks_per_step` por passo. Sem definições, sem
## `setup` ou com o fluxo que não monta, não faz nada.
func run_step() -> void:
	if _definitions == null or _ctx == null or not _ensure_thinker():
		return
	_thinker.run_step(_ctx.clock.total_minutes())


## Reação ao evento `AlarmRaised` (LW-076): os NPCs de `npc_ids` (em ordem de ID) a até `alarm_radius_m` do ponto pensam já (a pressão de
## `safety` sobe, `flee` e `help` entram entre as candidatas e a ação atual é interrompida com efeito proporcional se uma reação vencer).
func react_to_alarm(event: SimEvent, npc_ids: Array[int]) -> void:
	var raised: AlarmRaised = event as AlarmRaised
	if raised == null or _definitions == null or _ctx == null or not _ensure_thinker():
		return
	var alarm: NpcThinker.Alarm = NpcThinker.Alarm.new(raised.x_cm, raised.z_cm, raised.severity)
	var now: int = _ctx.clock.total_minutes()
	for npc_id: int in npc_ids:
		_thinker.react_to_alarm(npc_id, alarm, now)


## A parada para conversar (LW-083a): o NPC com corpo (S0) interrompe o que fazia e começa `talk_player`; a Intent é ACT_AT_PLACE de local vazio, então o
## corpo fica onde está até o fim previsto, e o NPC só volta a pensar nesse fim (`schedule`, a regra do pensador). Confere TUDO antes de interromper:
## recusado, nada muda. A interrupção é a do alarme (`ActionRunner.interrupt`; com corpo, cancela SEM efeito) e o início é a função única. Recusas:
## NPC_NOT_READY, NPC desconhecido ou morto, NPC_NOT_IN_S0 (sem corpo), NPC_ACTION_BUSY (já conversando: a conversa não se renova) e a condição do
## runner. Se o início falhar depois da interrupção (não deveria: foi conferido), o NPC fica livre e pensa no horário que já tinha. Relação, promoção
## e memória não são daqui (LW-083c).
func begin_talk_player(npc_id: int) -> Result:
	if _definitions == null or _ctx == null or not _ensure_thinker():
		return Result.failure(NpcModule.CODE_NOT_READY, "NpcDecisionRuntime.begin_talk_player: %s." % problem_text())
	var state: NpcState = _npcs.get(npc_id)
	if state == null:
		return Result.failure(ActionRunner.CODE_UNKNOWN_NPC, "NpcDecisionRuntime.begin_talk_player: o NPC %d não existe; esperado um ID da tabela de NPCs." % npc_id)
	if not state.is_alive:
		return Result.failure(ActionRunner.CODE_NOT_ALIVE, "NpcDecisionRuntime.begin_talk_player: o NPC %d está morto; esperado um NPC vivo." % npc_id)
	if not _bodies.is_embodied(npc_id):
		return Result.failure(NpcLod.CODE_NOT_IN_S0, "NpcDecisionRuntime.begin_talk_player: o NPC %d não tem corpo (não está em S0); só quem tem corpo para e conversa." % npc_id)
	if state.action_id == TALK_PLAYER_ACTION_ID:
		return Result.failure(ActionRunner.CODE_BUSY, "NpcDecisionRuntime.begin_talk_player: o NPC %d já está conversando (até o minuto %d)." % [npc_id, state.action_ends_at])
	var now: int = _ctx.clock.total_minutes()
	var blocker: String = _runner.peek_blocker(npc_id, TALK_PLAYER_ACTION_ID, "", now, true)
	if not blocker.is_empty():
		return Result.failure(ActionRunner.CODE_CONDITION_NOT_MET, "NpcDecisionRuntime.begin_talk_player: NPC %d: %s." % [npc_id, blocker])
	if not state.action_id.is_empty():
		var interrupted: Result = _runner.interrupt(npc_id, now)
		if not interrupted.ok:
			return interrupted
	var started: Result = _start_action(npc_id, TALK_PLAYER_ACTION_ID, "", now)
	if started.ok:
		_thinker.schedule(state, now)
	return started


## Cancela, SEM efeito, a ação de contador `action_serial` do NPC (o detector de impasse, LW-073): é o `ActionRunner.cancel_action` do fluxo montado. Sem
## definições, sem `setup` ou com o fluxo que não monta: falha tratada, nada muda.
func cancel_action(npc_id: int, action_serial: int) -> Result:
	if _definitions == null or _ctx == null or not _ensure_thinker():
		return Result.failure(NpcModule.CODE_NOT_READY, "NpcDecisionRuntime.cancel_action: %s." % problem_text())
	return _runner.cancel_action(npc_id, action_serial)


## Por que o módulo não decide (texto vazio = decide): sem `Definitions`, sem setup() ou com definições incompletas ou inválidas. Aparece no
## debug_summary(), para o módulo nunca ficar parado em silêncio.
func problem_text() -> String:
	if _definitions == null:
		return "o módulo foi criado sem as definições para decidir (NpcModule.Definitions)"
	if _thinker != null:
		return ""
	if _ctx == null:
		return "módulo sem setup()"
	_ensure_thinker()
	return _decision_problem


## As chaves do `debug_summary()` do módulo que dizem respeito ao fluxo de decisão.
func add_summary(summary: Dictionary) -> void:
	summary["decision_problem"] = problem_text()
	summary["decision_enabled"] = _thinker != null
	summary["thinks_last_step"] = _thinker.last_step_thinks if _thinker != null else 0
	summary["max_thinks_in_a_step"] = _thinker.max_step_thinks if _thinker != null else 0


## Monta o runner, o pontuador e o pensador na primeira vez que o `tick` roda. Falso (e `_decision_problem` preenchido) se faltar algo.
func _ensure_thinker() -> bool:
	if _thinker != null:
		return true
	if _decision_checked:
		return false
	_decision_checked = true
	_decision_problem = _build_decision_runtime()
	return _decision_problem.is_empty()


## Texto vazio = montou; senão, o que falta ou está inválido.
func _build_decision_runtime() -> String:
	if _need_defs.is_empty() or not _defs_problem.is_empty():
		return "faltam as definições de necessidades (ou estão inválidas)"
	if _routine == null:
		return "falta a tabela de rotina"
	if _definitions.actions.is_empty():
		return "falta o catálogo de ações"
	if _definitions.params == null:
		return "faltam os parâmetros do `npc` (npc_params.json)"
	if _definitions.places == null:
		return "falta o serviço de locais do `world`"
	var food_stub: FoodStub = _definitions.food as FoodStub
	if food_stub != null:
		var food_problem: String = food_stub.check_references(_definitions.places, _routine.peek_occupation_ids())
		if not food_problem.is_empty():
			return "FoodStub (TEMP-LW-065): %s" % food_problem
	if _definitions.income != null:
		var need_ids: Array[String] = []
		for def: NeedDef in _need_defs:
			need_ids.append(def.id)
		var income_problem: String = _definitions.income.check_references(need_ids, _routine.peek_occupation_ids())
		if not income_problem.is_empty():
			return "IncomeStub (TEMP-LW-066): %s" % income_problem
	var occupancy: PlaceOccupancy = PlaceOccupancy.new(_npcs)
	var provider: NpcThinker.ConditionProvider = NpcThinker.ConditionProvider.new(_definitions.places, occupancy, _definitions.food, _definitions.income)
	# LW-070b: o runner do jogo respeita o corpo (ver EmbodiedActionRunner); quem tem Intent pendente é o quadro de Intents que diz.
	var runner: ActionRunner = EmbodiedActionRunner.new(_npcs, _definitions.actions, _need_defs, _definitions.places, provider, _definitions.walk_speed_cm_per_min, _intents.has_pending)
	if not runner.peek_problem().is_empty():
		return "ActionRunner: %s" % runner.peek_problem()
	var scorer: UtilityScorer = UtilityScorer.new(_definitions.params, _need_defs, _definitions.traits)
	if not scorer.peek_problem().is_empty():
		return "UtilityScorer: %s" % scorer.peek_problem()
	var intents_problem: String = _bodies.link_intents(runner, _definitions.places, _definitions.intent_params)
	if not intents_problem.is_empty():
		return intents_problem
	_provider = provider
	_runner = runner
	_social = SocialActions.new(_npcs, _definitions.params.talk_gain, _definitions.params.talk_limit, _notables.relation_values, _notables.adjust_relation, _notables.record_memory)
	_thinker = NpcThinker.new(_ctx, _npcs, runner, scorer, PlaceChooser.new(_definitions.places, occupancy), provider, _routine, _definitions.params, _need_defs, _definitions.actions, _definitions.places, _start_action, _tracer, _lifecycle.kill, _social.on_action_finished)
	return ""


## A ÚNICA função que inicia uma ação (LW-063). Modo S1: pelo ActionRunner. Modo S0 (LW-070a, o ponto de extensão preenchido): NPC com corpo e
## protocolo ligado emite a Intent (`intents.begin_embodied`), que usa o MESMO runner: os efeitos só entram com o resultado do corpo. Sem corpos
## disponíveis (LW-070b) nenhuma ação nasce com Intent.
func _start_action(npc_id: int, action_id: String, place_id: String, now: int) -> Result:
	_provider.subject = _npcs.get(npc_id)
	if _bodies.is_embodied(npc_id):
		return _intents.begin_embodied(npc_id, action_id, place_id, now)
	return _runner.begin(npc_id, action_id, place_id, now)
