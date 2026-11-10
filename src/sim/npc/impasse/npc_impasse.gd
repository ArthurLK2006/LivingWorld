class_name NpcImpasse
extends RefCounted
## Detector de impasse (LW-073; docs/modules/npc.md, seção 6). Dois motivos:
## - `no_progress` (LW-073a): uma ação continua ABERTA `limit_min` minutos DEPOIS do fim previsto dela (`action_ends_at`), sem ninguém encerrá-la. O progresso era devido
##   no fim previsto, então dormir 480 minutos ou andar 99 (a rota entre povoados, DEC-124) não é impasse.
## - `result_timeout` (LW-073b): o NPC com corpo teve os Intents vencidos por tempo (sem resultado do corpo) em SEQUÊNCIA, sem outra ação no meio, e a sequência já dura
##   `limit_min` minutos ou mais desde o primeiro vencimento. Um vencimento só é tratado pelo próprio tempo limite do Intent (a ação é cancelada e o NPC pensa de novo).
## A recuperação cancela a ação SEM efeito (a do `result_timeout` o tempo limite já cancelou), tira o corpo de S0 se ele tem um (o corpo volta ao pool e o NPC volta a S0 no
## passo seguinte, no local novo, se ainda estiver perto do foco), leva o NPC à casa (ou, sem casa, ao local de trabalho), manda pensar já e publica `NpcImpasseRecovered`.
## Cada NPC recuperado espera `limit_min` antes de poder ser recuperado de novo. NPC com Intent pendente (dentro do prazo) é do tempo limite do Intent, não daqui.
## Não guarda estado salvo: a espera, a sequência de vencimentos e o registro são só de memória (somem ao carregar) e, enquanto não há impasse, nada aqui escreve no mundo
## nem gasta ID de evento, então o hash do mundo é o mesmo de antes do detector. A tabela de NPCs é a do módulo (a mesma, por referência).

## Motivos do evento (campo `reason`).
const REASON_NO_PROGRESS: String = "no_progress"
const REASON_RESULT_TIMEOUT: String = "result_timeout"
## [HIP] Minutos depois do fim previsto da ação (ou desde o primeiro vencimento de Intent da sequência) em que o NPC passa a contar como impasse. Medido (LW-073, 30 dias de
## vida normal): nenhuma ação ficou aberta depois do fim previsto, então qualquer valor acima de alguns minutos não dá falso positivo; 60 deixa folga sobre o pensamento
## (10 min) e o tempo limite do Intent (30 min).
const DEFAULT_LIMIT_MIN: int = 60
## [HIP] Quantas recuperações recentes o registro guarda (o painel da LW-082 lê); acima disso a mais antiga sai.
const MAX_RECORDS: int = 32
## Chaves de cada item de `peek_records()`. `overdue_min`: no `no_progress`, quanto a ação passou do fim previsto; no `result_timeout`, há quantos minutos a sequência de
## vencimentos começou. `action_id`: a ação cancelada pelo detector (vazio no `result_timeout`: o tempo limite do Intent já a tinha cancelado).
const KEY_NPC_ID: String = "npc_id"
const KEY_REASON: String = "reason"
const KEY_PLACE_ID: String = "place_id"
const KEY_MINUTE: String = "minute"
const KEY_ACTION_ID: String = "action_id"
const KEY_OVERDUE_MIN: String = "overdue_min"

var _npcs: Dictionary[int, NpcState]
var _places: SettlementService
## (npc_id: int) -> bool: o NPC tem corpo (S0).
var _is_embodied: Callable
## (npc_id: int, action_serial: int) -> Result: cancela a ação sem efeito (a do `ActionRunner`, entregue pelo fluxo de decisão).
var _cancel_action: Callable
## (npc_id: int) -> bool: o NPC tem Intent pendente, que ainda vale. Sem ele (nulo), todo NPC com corpo fica fora do `no_progress` (como na LW-073a).
var _has_pending: Callable
## (npc_id: int) -> void: tira o corpo do NPC de S0. Sem ele (nulo), o corpo não é solto.
var _release_body: Callable
var _limit_min: int
var _ctx: SimContext
## Minuto da última recuperação de cada NPC (a espera). Só memória.
var _last_recovered_at: Dictionary[int, int] = {}
## Sequência de Intents vencidos de cada NPC: x = minuto do primeiro vencimento, y = contador da última ação vencida. Só memória.
var _faults: Dictionary[int, Vector2i] = {}
var _records: Array[Dictionary] = []
var _recovered_total: int = 0


## `places`: o serviço de locais, para achar casa e trabalho (nulo: o NPC só tem a ação cancelada e o evento sai sem local).
func _init(npcs: Dictionary[int, NpcState], places: SettlementService, is_embodied: Callable, cancel_action: Callable, limit_min: int = DEFAULT_LIMIT_MIN, has_pending: Callable = Callable(), release_body: Callable = Callable()) -> void:
	_npcs = npcs
	_places = places
	_is_embodied = is_embodied
	_cancel_action = cancel_action
	_has_pending = has_pending
	_release_body = release_body
	_limit_min = maxi(limit_min, 1)


func setup(ctx: SimContext) -> void:
	_ctx = ctx


## A cada passo, antes do pensamento. `expired_by_timeout`: os NPCs cujo Intent venceu por tempo NESTE passo (a ação deles já foi cancelada), vindos de `NpcBodies.tick`.
## Recupera, em ordem crescente de ID, quem fechou uma sequência de vencimentos de `limit_min` e quem tem uma ação aberta além do fim previsto por `limit_min`.
func tick(expired_by_timeout: Array[int] = []) -> void:
	if _ctx == null:
		return
	var now: int = _ctx.clock.total_minutes()
	for npc_id: int in expired_by_timeout:
		_note_timeout(npc_id, now)
	var stuck: Array[int] = []
	for npc_id: int in _npcs:
		if _is_stuck(_npcs[npc_id], now):
			stuck.append(npc_id)
	stuck.sort()
	for npc_id: int in stuck:
		var state: NpcState = _npcs[npc_id]
		_recover(state, REASON_NO_PROGRESS, now, now - state.action_ends_at)


## Cópias das últimas recuperações (as mais antigas primeiro): `npc_id`, `reason`, `place_id`, `minute`, `action_id` e `overdue_min`.
func peek_records() -> Array[Dictionary]:
	var copies: Array[Dictionary] = []
	for record: Dictionary in _records:
		copies.append(record.duplicate())
	return copies


## Quantas recuperações houve desde o começo (ou desde o último `reset`).
func recovered_total() -> int:
	return _recovered_total


## Esquece a espera, as sequências de vencimentos e o registro (um save carregado recomeça a contar).
func reset() -> void:
	_last_recovered_at.clear()
	_faults.clear()
	_records.clear()
	_recovered_total = 0


func _is_waiting(npc_id: int, now: int) -> bool:
	return _last_recovered_at.has(npc_id) and now - _last_recovered_at[npc_id] < _limit_min


func _is_stuck(state: NpcState, now: int) -> bool:
	if not state.is_alive or state.action_id.is_empty() or now < state.action_ends_at + _limit_min:
		return false
	var embodied: bool = _is_embodied.call(state.npc_id)
	if embodied and (not _has_pending.is_valid() or _has_pending.call(state.npc_id)):
		return false
	return not _is_waiting(state.npc_id, now)


## Um Intent do NPC venceu por tempo agora. A sequência continua se esta ação é a SEGUINTE à última vencida (nenhuma outra ação começou no meio, então nenhuma terminou com
## resultado); senão recomeça neste vencimento. Fecha a sequência de `limit_min` minutos ou mais: recupera.
func _note_timeout(npc_id: int, now: int) -> void:
	var state: NpcState = _npcs.get(npc_id)
	if state == null or not state.is_alive:
		_faults.erase(npc_id)
		return
	var serial: int = state.action_serial
	if not _faults.has(npc_id) or _faults[npc_id].y + 1 != serial:
		_faults[npc_id] = Vector2i(now, serial)
		return
	var first_at: int = _faults[npc_id].x
	_faults[npc_id] = Vector2i(first_at, serial)
	if now - first_at >= _limit_min and not _is_waiting(npc_id, now):
		_faults.erase(npc_id)
		_recover(state, REASON_RESULT_TIMEOUT, now, now - first_at)


func _recover(state: NpcState, reason: String, now: int, overdue_min: int) -> void:
	var cancelled_action_id: String = state.action_id
	_last_recovered_at[state.npc_id] = now
	if not cancelled_action_id.is_empty():
		var cancelled: Result = _cancel_action.call(state.npc_id, state.action_serial)
		if not cancelled.ok:
			push_error("NpcImpasse: a ação '%s' do NPC %d não foi cancelada (%s): %s Esperado cancelar a ação de contador %d." % [cancelled_action_id, state.npc_id, cancelled.code, cancelled.message, state.action_serial])
			return
	# O corpo sai antes de o NPC mudar de lugar: a saída de S0 grava o último relato do corpo como posição lógica, e a posição nova tem de vir depois.
	var embodied: bool = _is_embodied.call(state.npc_id)
	if embodied and _release_body.is_valid():
		_release_body.call(state.npc_id)
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
