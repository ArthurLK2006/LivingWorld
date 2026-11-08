class_name ActionRunner
extends RefCounted
## ActionRunner abstrato (LW-060; contrato em docs/modules/npc.md, seção 3, e arquitetura 8.5): executa as ações do catálogo em modo S1
## (sem corpo). `begin` confere as condições e fixa o fim; `advance` termina a ação quando o tempo acaba; `apply_effects` é a ÚNICA
## função que escreve efeitos de ação nas necessidades, e é a mesma que o modo corpóreo (S0) vai chamar na LW-070. Os efeitos entram UMA
## vez, proporcionais ao progresso, SEM sorteio (senão a equivalência abstrato x corpóreo da LW-075 não se prova). Não está ligado ao tick:
## quem o chama é o fluxo de decisão (LW-063). O runner altera só os campos de ação e de necessidade do NpcState e nunca a tabela.
## O mesmo Dictionary do módulo dono é entregue pelo construtor; o runner só o lê por ID.

const CODE_NOT_READY: String = "NPC_RUNNER_NOT_READY"
const CODE_UNKNOWN_NPC: String = "NPC_UNKNOWN"
const CODE_NOT_ALIVE: String = "NPC_NOT_ALIVE"
const CODE_UNKNOWN_ACTION: String = "NPC_ACTION_UNKNOWN"
const CODE_BUSY: String = "NPC_ACTION_BUSY"
const CODE_CONDITION_NOT_MET: String = "NPC_ACTION_CONDITION_NOT_MET"
## "Falha por regra": uma condição deixou de valer ao terminar a ação (ex.: sem comida ao terminar `eat`); nenhum efeito é aplicado.
const CODE_ACTION_FAILED: String = "NPC_ACTION_FAILED"
const CODE_INVALID_PROGRESS: String = "NPC_INVALID_PROGRESS"
const CODE_PLACE_UNKNOWN: String = "NPC_PLACE_UNKNOWN"
## A única ação cuja duração vem da distância (contrato, seção 3); `duration_min` 0 nos dados significa "calculada em execução".
const GO_TO_PLACE_ID: String = "go_to_place"
## Progresso em milésimos: 1000 = ação completa. Ação interrompida aplica o que cumpriu.
const FULL_PROGRESS: int = 1000
## Velocidade de caminhada [HIP]: cerca de 1,4 m/s, em centímetros por minuto de simulação. A LW-062 a leva para data/npc_params.json.
const DEFAULT_WALK_SPEED_CM_PER_MIN: int = 8400
## Nenhuma viagem dura menos que isto [HIP], para uma ação de ida não terminar no mesmo minuto em que começa.
const MIN_TRAVEL_MINUTES: int = 1
## Condições que são conferidas DE NOVO ao completar a ação (recurso compartilhado que outro NPC pode ter levado durante a ação). As de
## necessidade, hora e vaga valem só no início: a necessidade sobe durante a ação, a hora passa e o NPC já ocupa o seu lugar.
const RECHECKED_AT_COMPLETION: Array[String] = [ActionDef.CONDITION_HAS_FOOD]

enum Outcome { NONE, RUNNING, COMPLETED, FAILED }

var _states: Dictionary[int, NpcState]
var _catalog: Dictionary[String, ActionDef] = {}
var _need_defs: Array[NeedDef]
var _need_position: Dictionary[String, int] = {}
var _places: SettlementService
var _provider: ActionConditionProvider
var _walk_speed_cm_per_min: int
## Motivo de o runner não servir (vazio = serve). Conferido uma vez, no construtor.
var _problem: String = ""


## `states`: a tabela de NPCs do módulo dono (a mesma, não uma cópia). `need_defs`: as cinco definições, na ordem de `order`.
## `places`: o serviço de locais do `world`, só para a duração e a chegada de `go_to_place` (sem ele essa ação não começa).
## `provider`: opcional, responde `has_food` e `place_has_room` (sem ele essas condições não são atendidas).
func _init(states: Dictionary[int, NpcState], catalog: Array[ActionDef], need_defs: Array[NeedDef], places: SettlementService = null, provider: ActionConditionProvider = null, walk_speed_cm_per_min: int = DEFAULT_WALK_SPEED_CM_PER_MIN) -> void:
	_states = states
	_need_defs = need_defs
	_places = places
	_provider = provider
	_walk_speed_cm_per_min = walk_speed_cm_per_min
	_problem = _definitions_problem(catalog)


## Motivo de o runner não servir (texto vazio se serve).
func peek_problem() -> String:
	return _problem


## Começa uma ação: confere as condições (todas) e fixa o fim (`now` + duração). Recusa não altera o estado. `place_id` é o local da
## ação (em `go_to_place`, o destino); o tipo de local não é conferido aqui, quem escolhe o local (LW-061) o faz pelo `world`.
func begin(npc_id: int, action_id: String, place_id: String, now: int) -> Result:
	var found: Result = _ready_status("begin")
	if not found.ok:
		return found
	if not _states.has(npc_id):
		return _unknown_npc("begin", npc_id)
	var state: NpcState = _states[npc_id]
	if not state.is_alive:
		return Result.failure(CODE_NOT_ALIVE, "ActionRunner.begin: o NPC %d está morto; esperado um NPC vivo." % npc_id)
	if not _catalog.has(action_id):
		return _unknown_action("begin", action_id)
	var action: ActionDef = _catalog[action_id]
	if not state.action_id.is_empty():
		return Result.failure(CODE_BUSY, "ActionRunner.begin: o NPC %d já está na ação '%s' (até o minuto %d); esperado terminá-la antes de começar '%s'." % [npc_id, state.action_id, state.action_ends_at, action_id])
	if now < state.needs_updated_at:
		return Result.failure(NeedMath.CODE_TIME_WENT_BACK, "ActionRunner.begin: NPC %d: o minuto %d é anterior à última atualização das necessidades (minuto %d); o relógio só avança." % [npc_id, now, state.needs_updated_at])
	var unmet: String = _unmet_condition(state, action, place_id, now)
	if not unmet.is_empty():
		return Result.failure(CODE_CONDITION_NOT_MET, "ActionRunner.begin: NPC %d, ação '%s': %s." % [npc_id, action_id, unmet])
	var duration: int = action.duration_min
	if action.id == GO_TO_PLACE_ID:
		var destination: SettlementService.PlaceQuery = _destination(place_id)
		if not destination.result.ok:
			return Result.failure(destination.result.code, "ActionRunner.begin: NPC %d, ação '%s': %s" % [npc_id, action_id, destination.result.message])
		duration = _travel_minutes(state, destination.place)
	# Leva as necessidades até o início: o tempo que passou entra ANTES de qualquer efeito.
	var settled: Result = NeedMath.settle(state, _need_defs, now)
	if not settled.ok:
		return settled
	state.action_id = action_id
	state.action_target_place_id = place_id
	state.action_started_at = now
	state.action_ends_at = now + duration
	state.action_serial += 1
	return Result.success()


## Diz, SEM alterar nada, o que impediria `begin` agora: texto vazio = a ação pode começar. Confere as mesmas coisas que `begin` (NPC, vida,
## ação, hora, condições e, em `go_to_place`, o destino); `ignore_busy` não conta o NPC já estar em outra ação (quem decide trocar de ação
## a interrompe antes de começar a nova). Serve para a ação só ser candidata se ela puder começar.
func peek_blocker(npc_id: int, action_id: String, place_id: String, now: int, ignore_busy: bool = false) -> String:
	var found: Result = _ready_status("peek_blocker")
	if not found.ok:
		return found.message
	if not _states.has(npc_id):
		return _unknown_npc("peek_blocker", npc_id).message
	var state: NpcState = _states[npc_id]
	if not state.is_alive:
		return "o NPC %d está morto" % npc_id
	if not _catalog.has(action_id):
		return _unknown_action("peek_blocker", action_id).message
	var action: ActionDef = _catalog[action_id]
	if not ignore_busy and not state.action_id.is_empty():
		return "o NPC %d já está na ação '%s'" % [npc_id, state.action_id]
	if now < state.needs_updated_at:
		return "o minuto %d é anterior à última atualização das necessidades (minuto %d)" % [now, state.needs_updated_at]
	var unmet: String = _unmet_condition(state, action, place_id, now)
	if not unmet.is_empty():
		return unmet
	if action.id == GO_TO_PLACE_ID and not _destination(place_id).result.ok:
		return _destination(place_id).result.message
	return ""


## Interrompe a ação em andamento: leva as necessidades até `now`, aplica o que ela cumpriu (efeitos proporcionais ao tempo decorrido,
## nunca 1000: interrompida não é completa) pela mesma função única `apply_effects` e libera o NPC. Sem ação em andamento não faz nada.
## `go_to_place` interrompido deixa o NPC onde estava.
func interrupt(npc_id: int, now: int) -> Result:
	var found: Result = _ready_status("interrupt")
	if not found.ok:
		return found
	if not _states.has(npc_id):
		return _unknown_npc("interrupt", npc_id)
	var state: NpcState = _states[npc_id]
	if state.action_id.is_empty():
		return Result.success()
	if not _catalog.has(state.action_id):
		return _unknown_action("interrupt", state.action_id)
	var settled: Result = NeedMath.settle(state, _need_defs, maxi(now, state.needs_updated_at))
	if not settled.ok:
		return settled
	var length: int = maxi(1, state.action_ends_at - state.action_started_at)
	var elapsed: int = clampi(now - state.action_started_at, 0, length)
	var progress: int = mini(IntMath.floor_div(elapsed * FULL_PROGRESS, length), FULL_PROGRESS - 1)
	var applied: Result = apply_effects(npc_id, state.action_id, state.action_target_place_id, progress)
	_clear_action(state)
	return applied


## Modo S1: termina a ação quando o tempo acaba (`now` a partir de `action_ends_at`). Antes do fim não muda nada. Ao terminar, leva as
## necessidades até o MINUTO DO FIM (e não até `now`), aplica os efeitos completos e libera o NPC; assim o resultado não depende de
## com que atraso o NPC pensa. Se a regra falhar ao terminar, nenhum efeito é aplicado, o NPC é liberado e o resultado é NPC_ACTION_FAILED.
func advance(npc_id: int, now: int) -> AdvanceResult:
	var found: Result = _ready_status("advance")
	if not found.ok:
		return AdvanceResult.new(found, Outcome.NONE)
	if not _states.has(npc_id):
		return AdvanceResult.new(_unknown_npc("advance", npc_id), Outcome.NONE)
	var state: NpcState = _states[npc_id]
	if state.action_id.is_empty():
		return AdvanceResult.new(Result.success(), Outcome.NONE)
	if now < state.action_ends_at:
		return AdvanceResult.new(Result.success(), Outcome.RUNNING)
	if not _catalog.has(state.action_id):
		return AdvanceResult.new(_unknown_action("advance", state.action_id), Outcome.NONE)
	var action: ActionDef = _catalog[state.action_id]
	var target_place_id: String = state.action_target_place_id
	if state.needs_updated_at < state.action_ends_at:
		var settled: Result = NeedMath.settle(state, _need_defs, state.action_ends_at)
		if not settled.ok:
			return AdvanceResult.new(settled, Outcome.NONE)
	var applied: Result = apply_effects(npc_id, action.id, target_place_id, FULL_PROGRESS)
	if not applied.ok:
		_clear_action(state)
		return AdvanceResult.new(applied, Outcome.FAILED)
	if action.id == GO_TO_PLACE_ID:
		_arrive(state, target_place_id)
	_clear_action(state)
	return AdvanceResult.new(Result.success(), Outcome.COMPLETED)


## A ÚNICA função que escreve efeitos de ação nas necessidades (os dois modos, S1 e S0, passam por aqui). Cada efeito entra uma vez:
## piso de (delta x progresso) / 1000, limitado a 0..100. Progresso 1000 é a ação completa e antes confere de novo as condições de
## RECHECKED_AT_COMPLETION (se falharem: NPC_ACTION_FAILED, sem efeito); progresso menor é ação interrompida e aplica só o que cumpriu.
## Sem sorteio. QUEM CHAMA leva as necessidades até o minuto do efeito antes (NeedMath.settle). `_place_id` é do contrato e fica para os
## efeitos que dependam do local (provisórios da seção 9).
func apply_effects(npc_id: int, action_id: String, _place_id: String, progress_permille: int) -> Result:
	var found: Result = _ready_status("apply_effects")
	if not found.ok:
		return found
	if not _states.has(npc_id):
		return _unknown_npc("apply_effects", npc_id)
	var state: NpcState = _states[npc_id]
	if not state.is_alive:
		return Result.failure(CODE_NOT_ALIVE, "ActionRunner.apply_effects: o NPC %d está morto; esperado um NPC vivo." % npc_id)
	if not _catalog.has(action_id):
		return _unknown_action("apply_effects", action_id)
	if progress_permille < 0 or progress_permille > FULL_PROGRESS:
		return Result.failure(CODE_INVALID_PROGRESS, "ActionRunner.apply_effects: NPC %d, ação '%s': progresso %d fora de 0 a %d." % [npc_id, action_id, progress_permille, FULL_PROGRESS])
	var action: ActionDef = _catalog[action_id]
	if progress_permille == FULL_PROGRESS:
		var broken: String = _completion_problem(state, action)
		if not broken.is_empty():
			return Result.failure(CODE_ACTION_FAILED, "ActionRunner.apply_effects: NPC %d, ação '%s' falhou ao terminar: %s; nenhum efeito foi aplicado." % [npc_id, action_id, broken])
	for effect: ActionDef.ActionEffect in action.effects:
		var position: int = _need_position[effect.need_id]
		var scaled: int = IntMath.floor_div(effect.delta * progress_permille, FULL_PROGRESS)
		state.need_values[position] = clampi(state.need_values[position] + scaled, NpcState.VALUE_MIN, NpcState.VALUE_MAX)
	return Result.success()


## A hora (0 a 23) está na janela [de, até)? Janela que cruza a meia-noite (de maior que até) vale de `de` até 24 e de 0 até `até`;
## de igual a até é janela vazia (nunca). `até` 24 é o fim do dia.
static func hour_in_window(hour: int, from_hour: int, to_hour: int) -> bool:
	if from_hour < to_hour:
		return hour >= from_hour and hour < to_hour
	if from_hour > to_hour:
		return hour >= from_hour or hour < to_hour
	return false


## Primeira condição NÃO atendida da ação (texto vazio se todas valem). Necessidade com o valor projetado até `now`, sem gravar nada.
func _unmet_condition(state: NpcState, action: ActionDef, place_id: String, now: int) -> String:
	for condition: ActionDef.ActionCondition in action.conditions:
		match condition.kind:
			ActionDef.CONDITION_NEED_AT_LEAST:
				var low_value: int = _need_value_at(state, condition.need_id, now)
				if low_value < condition.min_value:
					return "a necessidade '%s' está em %d, abaixo do mínimo %d (condição need_at_least)" % [condition.need_id, low_value, condition.min_value]
			ActionDef.CONDITION_NEED_AT_MOST:
				var high_value: int = _need_value_at(state, condition.need_id, now)
				if high_value > condition.max_value:
					return "a necessidade '%s' está em %d, acima do máximo %d (condição need_at_most)" % [condition.need_id, high_value, condition.max_value]
			ActionDef.CONDITION_HOUR_BETWEEN:
				var hour: int = IntMath.floor_div(now % SimClock.MINUTES_PER_DAY, SimClock.MINUTES_PER_HOUR)
				if not hour_in_window(hour, condition.min_value, condition.max_value):
					return "a hora %d está fora da janela de %d a %d (condição hour_between)" % [hour, condition.min_value, condition.max_value]
			ActionDef.CONDITION_PLACE_HAS_ROOM:
				if _provider == null or not _provider.place_has_room(place_id):
					return "o local '%s' não tem vaga, ou não há quem responda (condição place_has_room)" % place_id
			ActionDef.CONDITION_HAS_FOOD:
				if _provider == null or not _provider.has_food(state.settlement_id):
					return "não há comida no assentamento '%s', ou não há quem responda (condição has_food)" % state.settlement_id
			_:
				return "tipo de condição desconhecido '%s'" % condition.kind
	return ""


## Condição de RECHECKED_AT_COMPLETION que deixou de valer ao terminar (texto vazio se todas valem).
func _completion_problem(state: NpcState, action: ActionDef) -> String:
	for condition: ActionDef.ActionCondition in action.conditions:
		if not RECHECKED_AT_COMPLETION.has(condition.kind):
			continue
		if condition.kind == ActionDef.CONDITION_HAS_FOOD and (_provider == null or not _provider.has_food(state.settlement_id)):
			return "não há mais comida no assentamento '%s' (condição has_food)" % state.settlement_id
	return ""


## Valor da necessidade no minuto `now`, projetado sem gravar (a conta é a mesma de NeedMath.settle).
func _need_value_at(state: NpcState, need_id: String, now: int) -> int:
	var position: int = _need_position[need_id]
	var elapsed: int = maxi(0, now - state.needs_updated_at)
	return NeedMath.advance(state.need_values[position], state.need_remainders[position], _need_defs[position].rate_per_hour, elapsed).value


func _destination(place_id: String) -> SettlementService.PlaceQuery:
	if _places == null:
		return SettlementService.PlaceQuery.new(Result.failure(CODE_NOT_READY, "esta ação precisa do serviço de locais do `world` para saber a distância, e o runner foi criado sem ele."), null)
	var query: SettlementService.PlaceQuery = _places.peek_place(place_id)
	if not query.result.ok:
		return SettlementService.PlaceQuery.new(Result.failure(CODE_PLACE_UNKNOWN, "destino '%s' desconhecido (%s)." % [place_id, query.result.message]), null)
	return query


## Minutos para andar até o local: distância em centímetros (arredondada para cima) dividida pela velocidade, no mínimo MIN_TRAVEL_MINUTES.
func _travel_minutes(state: NpcState, place: Place) -> int:
	var delta_x: int = roundi(place.position.x * TerrainData.CM_PER_METER) - state.x_cm
	var delta_z: int = roundi(place.position.z * TerrainData.CM_PER_METER) - state.z_cm
	var distance_cm: int = ceili(sqrt(float(delta_x * delta_x + delta_z * delta_z)))
	var minutes: int = IntMath.floor_div(distance_cm + _walk_speed_cm_per_min - 1, _walk_speed_cm_per_min)
	return maxi(MIN_TRAVEL_MINUTES, minutes)


## Chegada de `go_to_place` em modo S1: a posição lógica passa a ser a do destino.
func _arrive(state: NpcState, place_id: String) -> void:
	var destination: SettlementService.PlaceQuery = _destination(place_id)
	if not destination.result.ok:
		return
	state.x_cm = roundi(destination.place.position.x * TerrainData.CM_PER_METER)
	state.z_cm = roundi(destination.place.position.z * TerrainData.CM_PER_METER)
	state.place_id = destination.place.id
	state.settlement_id = destination.place.settlement_id


func _clear_action(state: NpcState) -> void:
	state.action_id = ""
	state.action_target_place_id = ""
	state.action_started_at = 0
	state.action_ends_at = 0


## Motivo de as definições não servirem (texto vazio se servem); monta os índices de consulta.
func _definitions_problem(catalog: Array[ActionDef]) -> String:
	var need_problem: String = NeedMath.definitions_problem(_need_defs)
	if not need_problem.is_empty():
		return "definições de necessidades: %s" % need_problem
	if _walk_speed_cm_per_min <= 0:
		return "velocidade de caminhada %d; esperado mais que zero" % _walk_speed_cm_per_min
	for def: NeedDef in _need_defs:
		_need_position[def.id] = def.order
	for action: ActionDef in catalog:
		if _catalog.has(action.id):
			return "a ação '%s' aparece duas vezes no catálogo" % action.id
		_catalog[action.id] = action
		for effect: ActionDef.ActionEffect in action.effects:
			if not _need_position.has(effect.need_id):
				return "a ação '%s' tem efeito sobre a necessidade '%s', que não existe nas definições" % [action.id, effect.need_id]
		for condition: ActionDef.ActionCondition in action.conditions:
			if not condition.need_id.is_empty() and not _need_position.has(condition.need_id):
				return "a ação '%s' tem condição sobre a necessidade '%s', que não existe nas definições" % [action.id, condition.need_id]
	return ""


func _ready_status(caller: String) -> Result:
	if _problem.is_empty():
		return Result.success()
	return Result.failure(CODE_NOT_READY, "ActionRunner.%s: runner não está pronto (%s)." % [caller, _problem])


func _unknown_npc(caller: String, npc_id: int) -> Result:
	return Result.failure(CODE_UNKNOWN_NPC, "ActionRunner.%s: o NPC %d não existe; esperado um ID da tabela de NPCs." % [caller, npc_id])


func _unknown_action(caller: String, action_id: String) -> Result:
	return Result.failure(CODE_UNKNOWN_ACTION, "ActionRunner.%s: a ação '%s' não está no catálogo (%d ações)." % [caller, action_id, _catalog.size()])


## Resultado de `advance`: `result` falha só em erro de uso ou em NPC_ACTION_FAILED; `outcome` diz o que aconteceu.
class AdvanceResult:
	extends RefCounted

	var result: Result
	var outcome: ActionRunner.Outcome

	func _init(advance_result: Result, advance_outcome: ActionRunner.Outcome) -> void:
		result = advance_result
		outcome = advance_outcome
