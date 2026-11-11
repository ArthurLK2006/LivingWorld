class_name NpcThinker
extends RefCounted
## Fluxo de decisão do NPC e fila de pensamento (LW-063; contrato em docs/modules/npc.md, seção 5, e arquitetura 9.7), em modo S1 (sem
## corpo). A cada passo, `run_step` deixa pensar só quem chegou no seu `next_think_time`, no máximo `max_thinks_per_step` por passo (o mais
## antigo primeiro, empate pelo menor id; o excedente espera). Cada NPC que pensa: (1) leva as necessidades até agora; (2) termina a ação se
## o tempo dela acabou (e, se uma necessidade LETAL ficou em nível crítico além do limite, o NPC MORRE e nada mais acontece, LW-081); (3) monta as candidatas: com necessidade URGENTE (nível 2 ou mais) as ações que a aliviam, senão (ou se nenhuma
## delas pode começar) a ação da ROTINA da hora, mais a ação em andamento (que ganha o bônus de inércia); só entra quem tem local e pode
## começar (pré-condições); (4) pontua com o
## UtilityScorer; (5) ordena (pontos, depois id da ação, depois id do local), toma até `decision_top_k` dentro de `decision_margin` pontos
## da melhor e SORTEIA com peso no fluxo `npc.decision` do ctx.rng; (6) executa pelo ActionRunner, por uma função de início entregue pelo
## módulo (ponto de extensão do modo S0, LW-070); fora do local da ação, o primeiro passo é `go_to_place`; trocar de ação interrompe a atual
## com efeito proporcional; (7) agenda o próximo pensamento. Sem candidata, faz `wait`. Alarme (LW-076): `react_to_alarm` faz o NPC no raio
## pensar já, com a pressão de `safety` e as candidatas `flee` e `help`. Não guarda estado salvo: tudo está no NpcState.

const RNG_STREAM: String = "npc.decision"
const FALLBACK_ACTION_ID: String = "wait"
## Reações a um alarme (LW-076): ações do catálogo, achadas por estes ids (como `wait` e `go_to_place`). A necessidade que o alarme sobe.
const FLEE_ACTION_ID: String = "flee"
const HELP_ACTION_ID: String = "help"
const ALARM_ACTION_IDS: Array[String] = [FLEE_ACTION_ID, HELP_ACTION_ID]
const SAFETY_NEED_ID: String = "safety"
const CM_PER_METER_INT: int = 100

## Pensamentos do último passo e o maior número de pensamentos já visto num passo (só observação, não vai no save nem no hash).
var last_step_thinks: int = 0
var max_step_thinks: int = 0

var _ctx: SimContext
var _states: Dictionary[int, NpcState]
var _runner: ActionRunner
var _scorer: UtilityScorer
var _chooser: PlaceChooser
var _provider: ConditionProvider
var _routine: RoutineTable
var _params: NpcParams
var _need_defs: Array[NeedDef]
var _actions: Array[ActionDef]
var _action_by_id: Dictionary[String, ActionDef] = {}
var _places: SettlementService
## Função de início de ação do módulo: (npc_id: int, action_id: String, place_id: String, now: int) -> Result.
var _start_action: Callable
## Rastro de decisão dos NPCs marcados (LW-064); nulo = sem rastro. NPC não marcado não gera custo nem dado.
var _tracer: DecisionTracer
## Função de morte do módulo (LW-081): (npc_id: int, cause: String, now: int) -> void. Sem ela (testes do pensador solto) ninguém morre.
var _kill_npc: Callable
## Aviso de ação terminada (LW-080): (npc_id: int, action_id: String, place_id: String, now: int) -> void, chamado quando uma ação COMPLETA (não quando é
## interrompida) para o módulo tirar as consequências sociais dela. Sem ele (testes do pensador solto) nada é avisado.
var _on_action_finished: Callable


func _init(ctx: SimContext, states: Dictionary[int, NpcState], runner: ActionRunner, scorer: UtilityScorer, chooser: PlaceChooser, provider: ConditionProvider, routine: RoutineTable, params: NpcParams, need_defs: Array[NeedDef], actions: Array[ActionDef], places: SettlementService, start_action: Callable, tracer: DecisionTracer = null, kill_npc: Callable = Callable(), on_action_finished: Callable = Callable()) -> void:
	_ctx = ctx
	_states = states
	_runner = runner
	_scorer = scorer
	_chooser = chooser
	_provider = provider
	_routine = routine
	_params = params
	_need_defs = need_defs
	_actions = actions
	_places = places
	_start_action = start_action
	_tracer = tracer
	_kill_npc = kill_npc
	_on_action_finished = on_action_finished
	for action: ActionDef in actions:
		_action_by_id[action.id] = action


## Deixa pensar quem venceu a fila neste passo; devolve quantos pensaram.
func run_step(now: int) -> int:
	var due: Array[int] = due_ids(_states, now, _params.max_thinks_per_step)
	for npc_id: int in due:
		think(npc_id, now)
	last_step_thinks = due.size()
	max_step_thinks = maxi(max_step_thinks, last_step_thinks)
	return due.size()


## IDs dos NPCs vivos cujo `next_think_time` chegou, do mais antigo ao mais novo (empate: menor id), no máximo `cap`.
static func due_ids(states: Dictionary[int, NpcState], now: int, cap: int) -> Array[int]:
	var due: Array = []
	for state: NpcState in states.values():
		if state.is_alive and state.next_think_time <= now:
			due.append([state.next_think_time, state.npc_id])
	due.sort_custom(func(first: Array, second: Array) -> bool: return first[0] < second[0] or (first[0] == second[0] and first[1] < second[1]))
	var ids: Array[int] = []
	for index: int in mini(due.size(), maxi(cap, 0)):
		ids.append(due[index][1])
	return ids


## Reação a um alarme (LW-076): o NPC vivo a até `alarm_radius_m` do ponto PENSA JÁ (fora da fila e do teto), com a pressão de `safety`
## somada e as ações `flee` e `help` entre as candidatas. Fora do raio, morto ou desconhecido: nada acontece.
func react_to_alarm(npc_id: int, alarm: Alarm, now: int) -> void:
	if not _states.has(npc_id):
		return
	var state: NpcState = _states[npc_id]
	if not state.is_alive:
		return
	var radius_cm: int = _params.alarm_radius_m * CM_PER_METER_INT
	var delta_x: int = state.x_cm - alarm.x_cm
	var delta_z: int = state.z_cm - alarm.z_cm
	if delta_x * delta_x + delta_z * delta_z > radius_cm * radius_cm:
		return
	# A janela fica no estado: fugir ou ajudar leva mais de um pensamento (primeiro anda, depois age), e o alarme não pode sumir no meio.
	state.open_alarm_window(now + _params.alarm_window_min, _nearest_place_id(state, alarm))
	think(npc_id, now, alarm)


## Um pensamento do NPC (passos 1 a 7 do cabeçalho). ID desconhecido ou NPC morto: não faz nada (o registro não é tocado). `alarm`: o
## pensamento é a reação a um alarme (LW-076).
func think(npc_id: int, now: int, alarm: Alarm = null) -> void:
	if not _states.has(npc_id):
		return
	var state: NpcState = _states[npc_id]
	if not state.is_alive:
		return
	# Primeiro o fim da ação (o runner leva as necessidades até o MINUTO DO FIM antes de aplicar o efeito, então o resultado não depende do
	# atraso do pensamento) e só depois o resto do caminho até agora.
	var action_before: String = state.action_id
	var progress: ActionRunner.AdvanceResult = _runner.advance(npc_id, now)
	if progress.outcome == ActionRunner.Outcome.COMPLETED and _on_action_finished.is_valid():
		_on_action_finished.call(npc_id, action_before, state.place_id, now)
	if state.needs_updated_at < now:
		NeedMath.settle(state, _need_defs, now)
	NeedMath.update_critical(state, _need_defs, now)
	var lethal_cause: String = NeedMath.lethal_cause(state, _need_defs, now)
	if not lethal_cause.is_empty() and _kill_npc.is_valid():
		_kill_npc.call(npc_id, lethal_cause, now)
		return
	var running: bool = progress.outcome == ActionRunner.Outcome.RUNNING
	_provider.subject = state
	if alarm != null:
		_apply_alarm_pressure(state, alarm)
	var routine_action: String = _routine_action_id(state, now)
	var candidates: Array[Candidate] = _candidates(state, now, running, routine_action)
	if alarm != null or state.alarm_until > now:
		candidates = _with_alarm_reactions(candidates, state, now, running, routine_action)
	var chosen: Candidate = _choose(candidates)
	var reason: String = DecisionTracer.REASON_INERTIA if chosen != null and chosen.is_current else (chosen.source if chosen != null else DecisionTracer.REASON_FALLBACK)
	if chosen == null:
		chosen = _fallback(state, now)
	if _tracer != null and _tracer.is_traced(npc_id):
		_tracer.record(npc_id, now, state.need_values, _candidate_records(candidates), chosen.action.id if chosen != null else "", chosen.place_id if chosen != null else "", reason)
	if chosen != null and not chosen.is_current and not _is_walking_there(state, chosen, running):
		_execute(state, chosen, running, now)
	schedule(state, now)


## Ação da rotina do ofício na hora ("" se o NPC não tem ofício ou a agenda não responde).
func _routine_action_id(state: NpcState, now: int) -> String:
	if state.occupation_id.is_empty():
		return ""
	var hour: int = IntMath.floor_div(now % SimClock.MINUTES_PER_DAY, SimClock.MINUTES_PER_HOUR)
	var query: RoutineTable.RoutineQuery = _routine.peek_action(state.occupation_id, hour)
	return query.action_id if query.result.ok else ""


## Candidatas do pensamento (passo 3). Com necessidade urgente: as ações que a aliviam e que podem começar agora; se nenhuma pode (sem
## comida, sem vaga...), ou se não há urgência, a ação da rotina da hora (assim quem não tem como aliviar a fome ainda vai trabalhar, e é o
## trabalho do agricultor que repõe a comida). A ação em andamento entra sempre, para a inércia poder mantê-la.
func _candidates(state: NpcState, now: int, running: bool, routine_action: String) -> Array[Candidate]:
	var found: Array[Candidate] = _scored(_relieving_actions(state), state, now, running, routine_action, DecisionTracer.REASON_URGENT_NEED)
	if found.is_empty() and _action_by_id.has(routine_action):
		found = _scored([_action_by_id[routine_action]], state, now, running, routine_action, DecisionTracer.REASON_ROUTINE)
	if running and _action_by_id.has(state.action_id) and not _has_candidate(found, state.action_id):
		var current: Candidate = _candidate_for(state, _action_by_id[state.action_id], now, running, routine_action)
		if current != null:
			current.source = DecisionTracer.REASON_INERTIA
			found.append(current)
	return found


## Candidatas pontuadas das ações dadas (as que não têm local, não podem começar ou não pontuam ficam de fora). `source`: de onde vieram.
func _scored(actions: Array[ActionDef], state: NpcState, now: int, running: bool, routine_action: String, source: String) -> Array[Candidate]:
	var found: Array[Candidate] = []
	for action: ActionDef in actions:
		var candidate: Candidate = _candidate_for(state, action, now, running, routine_action)
		if candidate != null:
			candidate.source = source
			found.append(candidate)
	return found


## As candidatas do pensamento como registros do rastro (só chamado para NPC marcado).
func _candidate_records(candidates: Array[Candidate]) -> Array[DecisionTracer.CandidateRecord]:
	var records: Array[DecisionTracer.CandidateRecord] = []
	for candidate: Candidate in candidates:
		records.append(DecisionTracer.CandidateRecord.new(candidate.action.id, candidate.place_id, candidate.breakdown, candidate.is_current, candidate.source))
	return records


func _has_candidate(found: Array[Candidate], action_id: String) -> bool:
	for candidate: Candidate in found:
		if candidate.action.id == action_id:
			return true
	return false


## Ações do catálogo que aliviam alguma necessidade em nível urgente (lista vazia se nenhuma necessidade está urgente), na ordem do catálogo.
func _relieving_actions(state: NpcState) -> Array[ActionDef]:
	var relieving: Array[ActionDef] = []
	var urgent_ids: Array[String] = _urgent_need_ids(state)
	if urgent_ids.is_empty():
		return relieving
	for action: ActionDef in _actions:
		if _relieves(action, urgent_ids):
			relieving.append(action)
	return relieving


## O NPC já está andando para o local da ação escolhida? Então segue andando: recomeçar a caminhada a cada pensamento nunca a terminaria
## se ela durasse mais que o intervalo de pensamento.
func _is_walking_there(state: NpcState, chosen: Candidate, running: bool) -> bool:
	return running and state.action_id == ActionRunner.GO_TO_PLACE_ID and state.action_target_place_id == chosen.place_id and chosen.needs_place


## A candidata pontuada, ou null se a ação não tem local, não pode começar agora ou não pontua.
## `forced_place_id`: local já escolhido de fora (o do `help` do alarme); vazio = o PlaceChooser escolhe pelo tipo de local da ação.
func _candidate_for(state: NpcState, action: ActionDef, now: int, running: bool, routine_action: String, forced_place_id: String = "") -> Candidate:
	var is_current: bool = running and action.id == state.action_id
	var place_id: String = state.action_target_place_id
	var needs_place: bool = not action.place_kind.is_empty() or not forced_place_id.is_empty()
	var distance_cm: int = 0
	if not is_current:
		if forced_place_id.is_empty():
			var chosen_place: PlaceChooser.ChosenPlace = _chooser.place_for(state, action)
			if not chosen_place.result.ok:
				return null
			place_id = chosen_place.place_id
		else:
			place_id = forced_place_id
		if not _runner.peek_blocker(state.npc_id, action.id, place_id, now, true).is_empty():
			return null
		if needs_place:
			distance_cm = _distance_cm(state, place_id)
	var scored: UtilityScorer.ScoreBreakdown = _scorer.score(state, action, distance_cm, is_current, action.id == routine_action)
	if not scored.result.ok:
		return null
	return Candidate.new(action, place_id, scored.total, is_current, scored, needs_place)


## Candidatas da reação a um alarme (LW-076): `flee` (o PlaceChooser a leva para casa) e `help` (o local mais próximo do ponto do alarme)
## entram junto das candidatas normais, que continuam valendo: se uma delas pontuar mais, o NPC IGNORA o alarme e segue a vida (a inércia
## ou a rotina vence). Quem já está fazendo a ação de reação não ganha uma segunda candidata igual.
func _with_alarm_reactions(candidates: Array[Candidate], state: NpcState, now: int, running: bool, routine_action: String) -> Array[Candidate]:
	var result: Array[Candidate] = []
	for candidate: Candidate in candidates:
		if candidate.is_current or not ALARM_ACTION_IDS.has(candidate.action.id):
			result.append(candidate)
	for action_id: String in ALARM_ACTION_IDS:
		if not _action_by_id.has(action_id) or (running and state.action_id == action_id):
			continue
		var forced_place_id: String = ""
		if action_id == HELP_ACTION_ID:
			forced_place_id = state.alarm_place_id
			if forced_place_id.is_empty():
				continue
		var reaction: Candidate = _candidate_for(state, _action_by_id[action_id], now, running, routine_action, forced_place_id)
		if reaction != null:
			reaction.source = DecisionTracer.REASON_INTERRUPTION
			result.append(reaction)
	return result


## O alarme põe pressão em `safety` (a pressão do arquivo vezes a gravidade), limitada a 100.
func _apply_alarm_pressure(state: NpcState, alarm: Alarm) -> void:
	NeedMath.add_pressure(state, _need_defs, SAFETY_NEED_ID, _params.alarm_safety_pressure * alarm.severity)


## Id do local (de qualquer tipo) do assentamento do NPC mais próximo do ponto do alarme; empate: menor id. Vazio se o assentamento não tem local.
func _nearest_place_id(state: NpcState, alarm: Alarm) -> String:
	var best_id: String = ""
	var best_distance: int = 0
	for kind: String in Place.KINDS:
		var found: SettlementService.PlacesQuery = _places.peek_places_of_kind(state.settlement_id, kind)
		if not found.result.ok:
			continue
		for place: Place in found.places:
			var delta_x: int = roundi(place.position.x * TerrainData.CM_PER_METER) - alarm.x_cm
			var delta_z: int = roundi(place.position.z * TerrainData.CM_PER_METER) - alarm.z_cm
			var distance: int = delta_x * delta_x + delta_z * delta_z
			if best_id.is_empty() or distance < best_distance or (distance == best_distance and place.id < best_id):
				best_id = place.id
				best_distance = distance
	return best_id


## Escolha (passo 5): ordena, toma as melhores dentro da margem e sorteia com peso (inteiro) no fluxo `npc.decision`.
func _choose(candidates: Array[Candidate]) -> Candidate:
	if candidates.is_empty():
		return null
	candidates.sort_custom(func(first: Candidate, second: Candidate) -> bool:
		if first.total != second.total:
			return first.total > second.total
		if first.action.id != second.action.id:
			return first.action.id < second.action.id
		return first.place_id < second.place_id)
	var floor_total: int = candidates[0].total - _params.decision_margin
	var pool: Array[Candidate] = []
	for index: int in mini(candidates.size(), _params.decision_top_k):
		if candidates[index].total >= floor_total:
			pool.append(candidates[index])
	if pool.size() == 1:
		return pool[0]
	var sum_of_weights: int = 0
	for candidate: Candidate in pool:
		sum_of_weights += candidate.total - floor_total + 1
	var roll: int = _ctx.rng.range_int(RNG_STREAM, 1, sum_of_weights)
	for candidate: Candidate in pool:
		roll -= candidate.total - floor_total + 1
		if roll <= 0:
			return candidate
	return pool[pool.size() - 1]


## Sem candidata: `wait`, se existir no catálogo e puder começar (o NPC não fica sem fazer nada).
func _fallback(state: NpcState, now: int) -> Candidate:
	if not _action_by_id.has(FALLBACK_ACTION_ID):
		return null
	var action: ActionDef = _action_by_id[FALLBACK_ACTION_ID]
	if not _runner.peek_blocker(state.npc_id, action.id, state.place_id, now, true).is_empty():
		return null
	return Candidate.new(action, state.place_id, 0, false)


## Execução (passo 6). Trocar de ação interrompe a atual; fora do local da ação, o primeiro passo é ir até lá.
func _execute(state: NpcState, chosen: Candidate, running: bool, now: int) -> void:
	if running:
		_runner.interrupt(state.npc_id, now)
	var step_action_id: String = chosen.action.id
	if chosen.needs_place and state.place_id != chosen.place_id and _action_by_id.has(ActionRunner.GO_TO_PLACE_ID):
		step_action_id = ActionRunner.GO_TO_PLACE_ID
	_start_action.call(state.npc_id, step_action_id, chosen.place_id, now)


## Próximo pensamento (passo 7): daqui a `think_interval_min`, ou no fim da ação se ela acaba antes; nunca no mesmo minuto. Público desde a LW-083a:
## quem começa uma ação por pedido, fora do pensamento (a parada para conversar), agenda pela MESMA regra.
func schedule(state: NpcState, now: int) -> void:
	var next_time: int = now + _params.think_interval_min
	if not state.action_id.is_empty():
		next_time = mini(next_time, state.action_ends_at)
	state.next_think_time = maxi(next_time, now + 1)


## Ids das necessidades em nível URGENTE ou pior.
func _urgent_need_ids(state: NpcState) -> Array[String]:
	var ids: Array[String] = []
	for def: NeedDef in _need_defs:
		if NeedMath.urgency(state.need_values[def.order], def) >= NeedMath.URGENCY_URGENT:
			ids.append(def.id)
	return ids


## A ação alivia (efeito negativo) alguma das necessidades?
func _relieves(action: ActionDef, need_ids: Array[String]) -> bool:
	for effect: ActionDef.ActionEffect in action.effects:
		if effect.delta < 0 and need_ids.has(effect.need_id):
			return true
	return false


## Distância em linha reta, em centímetros inteiros (arredondada para cima), do NPC ao local; 0 se já está nele.
func _distance_cm(state: NpcState, place_id: String) -> int:
	if place_id.is_empty() or place_id == state.place_id:
		return 0
	var query: SettlementService.PlaceQuery = _places.peek_place(place_id)
	if not query.result.ok:
		return 0
	var delta_x: int = roundi(query.place.position.x * TerrainData.CM_PER_METER) - state.x_cm
	var delta_z: int = roundi(query.place.position.z * TerrainData.CM_PER_METER) - state.z_cm
	return ceili(sqrt(float(delta_x * delta_x + delta_z * delta_z)))


## Um alarme que chegou ao `npc` (LW-076): o ponto, em centímetros, e a gravidade.
class Alarm:
	extends RefCounted

	var x_cm: int
	var z_cm: int
	var severity: int

	func _init(alarm_x_cm: int, alarm_z_cm: int, alarm_severity: int) -> void:
		x_cm = alarm_x_cm
		z_cm = alarm_z_cm
		severity = alarm_severity


## Ação candidata com local e pontuação.
class Candidate:
	extends RefCounted

	var action: ActionDef
	var place_id: String
	var total: int
	var is_current: bool
	## As parcelas da pontuação (para o rastro); nulo na espera de reserva, que não é pontuada.
	var breakdown: UtilityScorer.ScoreBreakdown
	## De onde veio: motivo de escolha se vencer (URGENT_NEED, ROUTINE ou INTERRUPTION); INERTIA para a ação que só estava em andamento.
	var source: String = DecisionTracer.REASON_FALLBACK
	## A ação acontece num local (do tipo da ação, ou o `help` do alarme): fora dele o primeiro passo é ir até lá.
	var needs_place: bool

	func _init(candidate_action: ActionDef, candidate_place_id: String, candidate_total: int, candidate_is_current: bool, candidate_breakdown: UtilityScorer.ScoreBreakdown = null, candidate_needs_place: bool = false) -> void:
		action = candidate_action
		place_id = candidate_place_id
		total = candidate_total
		is_current = candidate_is_current
		breakdown = candidate_breakdown
		needs_place = candidate_needs_place


## Provedor das condições `has_food` e `place_has_room` do ActionRunner. `place_has_room` = capacidade do `world` menos a ocupação derivada
## do estado dos NPCs (PlaceOccupancy), sem contar o NPC em questão (`subject`) se ele já está no local; `has_food` vai para o provedor de
## comida opcional (TEMP-LW-065); sem ele não há comida.
class ConditionProvider:
	extends ActionConditionProvider

	## NPC para o qual as condições estão sendo conferidas agora (quem chama o define antes).
	var subject: NpcState
	var _places: SettlementService
	var _occupancy: PlaceOccupancy
	var _food: ActionConditionProvider
	var _income: IncomeStub
	var _trade: NpcTrade
	## A conclusão que acabou de tirar comida do inventário do NPC: o `FoodStub` não consome a refeição de novo (LW-093).
	var _food_from_inventory: bool = false

	func _init(places: SettlementService, occupancy: PlaceOccupancy, food: ActionConditionProvider, income: IncomeStub = null, trade: NpcTrade = null) -> void:
		_places = places
		_occupancy = occupancy
		_food = food
		_income = income
		_trade = trade

	func has_food(settlement_id: String) -> bool:
		return _food != null and _food.has_food(settlement_id)

	## Comida PARA O NPC (LW-093): a do inventário dele, na economia, ou, na falta, a do assentamento (o `FoodStub` de reserva).
	func npc_has_food(npc_id: int, settlement_id: String) -> bool:
		return (_trade != null and _trade.has_food(npc_id)) or has_food(settlement_id)

	func can_buy_food(npc_id: int) -> bool:
		return _trade != null and not _trade.plan_food(npc_id).is_empty()

	func has_goods(npc_id: int) -> bool:
		return _trade != null and _trade.has_goods(npc_id)

	## A ação completa do NPC na economia (comprar, comer do inventário, vender); sem economia nada.
	func complete_action(npc_id: int, action_id: String) -> ActionConditionProvider.Completion:
		if _trade == null:
			return ActionConditionProvider.Completion.new()
		var completion: ActionConditionProvider.Completion = _trade.complete(npc_id, action_id)
		_food_from_inventory = completion.consumed_from_inventory
		return completion

	## Repassa o fim de uma ação completa a quem guarda estoque (hoje só o FoodStub, TEMP-LW-065), menos quando a comida saiu do inventário do NPC.
	func on_action_completed(action_id: String, settlement_id: String, occupation_id: String) -> void:
		if _food_from_inventory:
			_food_from_inventory = false
			return
		if _food != null:
			_food.on_action_completed(action_id, settlement_id, occupation_id)

	## Efeitos extras da ação para o ofício (hoje só o alívio de renda do IncomeStub, TEMP-LW-066); sem IncomeStub, nenhum.
	func extra_effects(action_id: String, occupation_id: String) -> Array[ActionDef.ActionEffect]:
		if _income == null:
			return []
		return _income.extra_effects(action_id, occupation_id)

	func place_has_room(place_id: String) -> bool:
		var found: SettlementService.PlaceQuery = _places.peek_place(place_id)
		if not found.result.ok:
			return false
		var present: int = _occupancy.count_at(place_id)
		if subject != null and subject.is_alive and subject.place_id == place_id:
			present -= 1
		return present < found.place.capacity
