class_name NpcImpasse
extends RefCounted
## Detector de impasse (LW-073; docs/modules/npc.md, seção 6). Um NPC está em impasse quando uma ação continua ABERTA `limit_min` minutos DEPOIS do fim
## previsto dela (`action_ends_at`), sem ninguém encerrá-la: o progresso era devido no fim previsto, então dormir 480 minutos ou andar 99 (a rota entre
## povoados, DEC-124) não é impasse. A recuperação cancela a ação SEM efeito (o mesmo `cancel_action` do modo S0), leva o NPC à casa (ou, sem casa, ao local de
## trabalho), manda pensar já e publica `NpcImpasseRecovered`. Cada NPC recuperado espera `limit_min` antes de poder ser recuperado de novo. Nesta parte só olha
## quem não tem corpo (S1); quem tem corpo fica com os Intents (a LW-073b cobre o motivo `result_timeout`).
## Não guarda estado salvo: a espera e o registro são só de memória (somem ao carregar) e, enquanto não há impasse, nada aqui escreve no mundo nem gasta ID de
## evento, então o hash do mundo é o mesmo de antes do detector. A tabela de NPCs é a do módulo (a mesma, por referência).

## Motivos do evento (campo `reason`).
const REASON_NO_PROGRESS: String = "no_progress"
## [HIP] Minutos depois do fim previsto da ação em que ela passa a contar como impasse. Medido (LW-073, 30 dias de vida normal): nenhuma ação ficou aberta
## depois do fim previsto, então qualquer valor acima de alguns minutos não dá falso positivo; 60 deixa folga sobre o pensamento (10 min) e o tempo limite do
## Intent (30 min).
const DEFAULT_LIMIT_MIN: int = 60
## [HIP] Quantas recuperações recentes o registro guarda (o painel da LW-082 lê); acima disso a mais antiga sai.
const MAX_RECORDS: int = 32
## Chaves de cada item de `peek_records()`.
const KEY_NPC_ID: String = "npc_id"
const KEY_REASON: String = "reason"
const KEY_PLACE_ID: String = "place_id"
const KEY_MINUTE: String = "minute"
const KEY_ACTION_ID: String = "action_id"
const KEY_OVERDUE_MIN: String = "overdue_min"

var _npcs: Dictionary[int, NpcState]
var _places: SettlementService
## (npc_id: int) -> bool: o NPC tem corpo (S0). Quem tem corpo não é visto aqui.
var _is_embodied: Callable
## (npc_id: int, action_serial: int) -> Result: cancela a ação sem efeito (a do `ActionRunner`, entregue pelo fluxo de decisão).
var _cancel_action: Callable
var _limit_min: int
var _ctx: SimContext
## Minuto da última recuperação de cada NPC (a espera). Só memória.
var _last_recovered_at: Dictionary[int, int] = {}
var _records: Array[Dictionary] = []
var _recovered_total: int = 0


## `places`: o serviço de locais, para achar casa e trabalho (nulo: o NPC só tem a ação cancelada e o evento sai sem local).
func _init(npcs: Dictionary[int, NpcState], places: SettlementService, is_embodied: Callable, cancel_action: Callable, limit_min: int = DEFAULT_LIMIT_MIN) -> void:
	_npcs = npcs
	_places = places
	_is_embodied = is_embodied
	_cancel_action = cancel_action
	_limit_min = maxi(limit_min, 1)


func setup(ctx: SimContext) -> void:
	_ctx = ctx


## A cada passo, antes do pensamento: procura as ações que passaram do fim previsto por `limit_min` ou mais e recupera os NPCs, em ordem crescente de ID.
func tick() -> void:
	if _ctx == null:
		return
	var now: int = _ctx.clock.total_minutes()
	var stuck: Array[int] = []
	for npc_id: int in _npcs:
		if _is_stuck(_npcs[npc_id], now):
			stuck.append(npc_id)
	stuck.sort()
	for npc_id: int in stuck:
		_recover(_npcs[npc_id], REASON_NO_PROGRESS, now)


## Cópias das últimas recuperações (as mais antigas primeiro): `npc_id`, `reason`, `place_id`, `minute`, `action_id` (a cancelada) e `overdue_min`.
func peek_records() -> Array[Dictionary]:
	var copies: Array[Dictionary] = []
	for record: Dictionary in _records:
		copies.append(record.duplicate())
	return copies


## Quantas recuperações houve desde o começo (ou desde o último `reset`).
func recovered_total() -> int:
	return _recovered_total


## Esquece a espera e o registro (um save carregado recomeça a contar).
func reset() -> void:
	_last_recovered_at.clear()
	_records.clear()
	_recovered_total = 0


func _is_stuck(state: NpcState, now: int) -> bool:
	if not state.is_alive or state.action_id.is_empty() or now < state.action_ends_at + _limit_min:
		return false
	var embodied: bool = _is_embodied.call(state.npc_id)
	if embodied:
		return false
	return not _last_recovered_at.has(state.npc_id) or now - _last_recovered_at[state.npc_id] >= _limit_min


func _recover(state: NpcState, reason: String, now: int) -> void:
	var cancelled_action_id: String = state.action_id
	var cancelled_serial: int = state.action_serial
	var overdue_min: int = now - state.action_ends_at
	_last_recovered_at[state.npc_id] = now
	var cancelled: Result = _cancel_action.call(state.npc_id, cancelled_serial)
	if not cancelled.ok:
		push_error("NpcImpasse: a ação '%s' do NPC %d não foi cancelada (%s): %s Esperado cancelar a ação de contador %d." % [cancelled_action_id, state.npc_id, cancelled.code, cancelled.message, cancelled_serial])
		return
	var place_id: String = _move_to_recovery_place(state)
	state.next_think_time = now
	_remember(state.npc_id, reason, place_id, now, cancelled_action_id, overdue_min)
	_ctx.events.publish(NpcImpasseRecovered.new(state.npc_id, reason, place_id))


## Põe o NPC na casa (ou, sem casa, no local de trabalho) e devolve o id do local; sem nenhum local utilizável o NPC não sai de onde está (devolve vazio).
func _move_to_recovery_place(state: NpcState) -> String:
	if _places == null:
		return ""
	for candidate_id: String in [state.home_place_id, state.work_place_id]:
		if candidate_id.is_empty():
			continue
		var query: SettlementService.PlaceQuery = _places.peek_place(candidate_id)
		if not query.result.ok:
			continue
		state.x_cm = roundi(query.place.position.x * TerrainData.CM_PER_METER)
		state.z_cm = roundi(query.place.position.z * TerrainData.CM_PER_METER)
		state.place_id = query.place.id
		state.settlement_id = query.place.settlement_id
		return query.place.id
	return ""


func _remember(npc_id: int, reason: String, place_id: String, now: int, action_id: String, overdue_min: int) -> void:
	_recovered_total += 1
	_records.append({KEY_NPC_ID: npc_id, KEY_REASON: reason, KEY_PLACE_ID: place_id, KEY_MINUTE: now, KEY_ACTION_ID: action_id, KEY_OVERDUE_MIN: overdue_min})
	if _records.size() > MAX_RECORDS:
		_records.remove_at(0)
