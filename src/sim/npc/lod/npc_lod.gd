class_name NpcLod
extends RefCounted
## LOD lógico dos NPCs (LW-069; contrato em docs/modules/npc.md, seção 6). A cada passo decide quem está em S0 (com corpo: a simulação
## emite Intent e espera o resultado) e quem está em S1 (sem corpo: ação abstrata). O nível é DERIVADO dos pontos de foco e NÃO é salvo
## nem entra no state_hash: vive só nesta instância (começa tudo em S1). Vários focos (nada supõe um jogador só): um NPC vira S0 a até
## `lod_enter_radius_m` do foco MAIS PRÓXIMO (inclusive no limite) e só volta a S1 acima de `lod_exit_radius_m` (histerese); no máximo
## `max_s0` em S0, os mais próximos, desempate pelo ID menor. Contas em centímetros inteiros (exatas e repetíveis). Só a parte lógica:
## sem corpo nem apresentação. Quem publica o evento LodChanged é o NpcModule, com a lista que `update` devolve.

## Níveis (valores do evento LodChanged): 0 = S0 (com corpo), 1 = S1 (sem corpo).
const LEVEL_S0: int = 0
const LEVEL_S1: int = 1
const CODE_NOT_CONFIGURED: String = "NPC_LOD_NOT_CONFIGURED"
const CODE_INVALID_FOCUS: String = "NPC_INVALID_FOCUS"
const CODE_UNKNOWN_FOCUS: String = "NPC_UNKNOWN_FOCUS"
const CODE_NOT_IN_S0: String = "NPC_NOT_IN_S0"
const CODE_INVALID_POSITION: String = "NPC_INVALID_POSITION"
const CM_PER_METER_FLOAT: float = 100.0
## Faixa de segurança [HIP] das coordenadas (cm): a mesma do NpcState.
const MAX_COORDINATE_CM: int = NpcState.MAX_COORDINATE_CM

## Posição em cm de um local pelo id (`Vector2i`), ou LodReconstruction.NO_POSITION se não conhece. Opcional: sem ele, o NPC em trânsito
## conta como parado na posição lógica. Quem monta o módulo o liga quando o módulo passar a conhecer os locais.
var place_position_cm: Callable = Callable()

var _params: LodParams
var _params_problem: String = ""
## Focos: id do ator (ou de quem for) -> posição em cm. Volátil.
var _foci: Dictionary[int, Vector2i] = {}
## NPCs em S0 -> posição atual do corpo (a reconstruída na entrada, depois o último relato). Volátil.
var _s0: Dictionary[int, S0Slot] = {}
## NPC -> (action_serial, minuto) quando o corpo saiu de S0 em trânsito com relato: a nova origem do trecho. Volátil (perde-se ao carregar).
var _leg_starts: Dictionary[int, Vector2i] = {}


## Sem `params` (padrão) o LOD nasce DESLIGADO: os pedidos de foco falham com `NPC_LOD_NOT_CONFIGURED` e `update` não faz nada.
func _init(params: LodParams = null) -> void:
	if params != null:
		configure(params)


## Liga o LOD com os parâmetros dados (lidos por LodParamsLoader). Nulo ou inválido: falha com o motivo e o LOD fica desligado.
func configure(params: LodParams) -> Result:
	_params = null
	_params_problem = "" if params != null else "parâmetros nulos"
	if params != null:
		_params_problem = params.problem()
	if not _params_problem.is_empty():
		return Result.failure(CODE_NOT_CONFIGURED, "NpcLod.configure: parâmetros de LOD inválidos: %s." % _params_problem)
	_params = params
	return Result.success()


## Põe (ou move) o foco `focus_id` em `position_m` (metros; só x e z contam). ID sem valor, posição não finita ou fora da faixa: falha tratada.
func set_focus(focus_id: int, position_m: Vector3) -> Result:
	if _params == null:
		return _unconfigured("request_set_focus")
	if focus_id <= IdGenerator.NO_ID:
		return Result.failure(CODE_INVALID_FOCUS, "NpcLod.request_set_focus: focus_id %d inválido; esperado um ID maior que %d." % [focus_id, IdGenerator.NO_ID])
	if not position_m.is_finite():
		return Result.failure(CODE_INVALID_FOCUS, "NpcLod.request_set_focus: foco %d com posição %s não finita; esperado números finitos." % [focus_id, str(position_m)])
	var max_m: float = float(MAX_COORDINATE_CM) / CM_PER_METER_FLOAT
	if position_m.x < 0.0 or position_m.x > max_m or position_m.z < 0.0 or position_m.z > max_m:
		return Result.failure(CODE_INVALID_FOCUS, "NpcLod.request_set_focus: foco %d na posição %s fora da faixa; esperado x e z de 0 a %s m." % [focus_id, str(position_m), str(max_m)])
	_foci[focus_id] = Vector2i(roundi(position_m.x * CM_PER_METER_FLOAT), roundi(position_m.z * CM_PER_METER_FLOAT))
	return Result.success()


## Tira o foco. Foco que não existe: falha tratada (nada muda).
func clear_focus(focus_id: int) -> Result:
	if _params == null:
		return _unconfigured("request_clear_focus")
	if not _foci.has(focus_id):
		return Result.failure(CODE_UNKNOWN_FOCUS, "NpcLod.request_clear_focus: o foco %d não existe; esperado um foco posto por request_set_focus (há %d)." % [focus_id, _foci.size()])
	_foci.erase(focus_id)
	return Result.success()


func focus_count() -> int:
	return _foci.size()


## Nível do NPC: LEVEL_S0 se está em S0; senão LEVEL_S1 (inclusive NPC que não existe).
func level_of(npc_id: int) -> int:
	return LEVEL_S0 if _s0.has(npc_id) else LEVEL_S1


## IDs em S0, em ordem crescente.
func s0_ids() -> Array[int]:
	var ids: Array[int] = []
	ids.assign(_s0.keys())
	ids.sort()
	return ids


## Posição (cm) do corpo de um NPC em S0: a reconstruída na entrada ou o último relato. Fora de S0: NO_POSITION.
func position_of(npc_id: int) -> Vector2i:
	return _s0[npc_id].position if _s0.has(npc_id) else LodReconstruction.NO_POSITION


## Último relato de posição (cm) do corpo de um NPC em S0. Ao sair de S0 ele vira a posição lógica. Fora de S0 ou fora da faixa: falha.
func report_position(npc_id: int, position_cm: Vector2i) -> Result:
	if not _s0.has(npc_id):
		return Result.failure(CODE_NOT_IN_S0, "NpcLod.report_position: o NPC %d não está em S0; relato descartado (há %d em S0)." % [npc_id, _s0.size()])
	if position_cm.x < 0 or position_cm.y < 0 or position_cm.x > MAX_COORDINATE_CM or position_cm.y > MAX_COORDINATE_CM:
		return Result.failure(CODE_INVALID_POSITION, "NpcLod.report_position: NPC %d com posição %s fora da faixa; esperado x e z de 0 a %d cm." % [npc_id, str(position_cm), MAX_COORDINATE_CM])
	var slot: S0Slot = _s0[npc_id]
	slot.position = position_cm
	slot.has_report = true
	return Result.success()


## Reclassifica os NPCs em `now_minutes` e devolve as TROCAS de nível, em ordem crescente de ID (vazia se nada trocou). Não escolhe por
## ordem de Dictionary. Quem sai de S0 (afastou-se, morreu, foi removido ou perdeu a vaga) leva o último relato do corpo, se houve um,
## para a posição lógica; a ação e o local não são tocados (a ação segue em modo abstrato com o tempo que falta).
func update(npcs: Dictionary[int, NpcState], now_minutes: int) -> Array[Change]:
	var changes: Array[Change] = []
	if _params == null or (_foci.is_empty() and _s0.is_empty()):
		return changes
	var candidates: Array[Candidate] = _candidates(npcs, now_minutes)
	if candidates.size() > _params.max_s0:
		candidates.sort_custom(Candidate.is_closer)
		candidates.resize(_params.max_s0)
	var kept: Dictionary[int, bool] = {}
	for candidate: Candidate in candidates:
		kept[candidate.npc_id] = true
	for npc_id: int in s0_ids():
		if not kept.has(npc_id):
			_leave(npc_id, npcs.get(npc_id) as NpcState, now_minutes)
			changes.append(Change.new(npc_id, LEVEL_S0, LEVEL_S1))
	for candidate: Candidate in candidates:
		if not _s0.has(candidate.npc_id):
			_s0[candidate.npc_id] = S0Slot.new(candidate.spot)
			changes.append(Change.new(candidate.npc_id, LEVEL_S1, LEVEL_S0))
	changes.sort_custom(Change.is_before)
	_forget_removed(npcs)
	return changes


func debug_summary() -> Dictionary:
	return {"configured": _params != null, "focus_count": _foci.size(), "s0_count": _s0.size(), "s0_ids": s0_ids()}


## Quem pode estar em S0 agora, ainda sem o limite de vagas: vivo, a até o raio de entrada do foco mais próximo (quem já está em S0
## fica até o raio de saída, medido a partir da posição do corpo).
func _candidates(npcs: Dictionary[int, NpcState], now_minutes: int) -> Array[Candidate]:
	var found: Array[Candidate] = []
	if _foci.is_empty():
		return found
	var enter_sq: int = _squared(_params.enter_radius_cm())
	var exit_sq: int = _squared(_params.exit_radius_cm())
	var ids: Array[int] = []
	ids.assign(npcs.keys())
	ids.sort()
	for npc_id: int in ids:
		var state: NpcState = npcs[npc_id]
		if not state.is_alive:
			continue
		var spot: Vector2i = _spot_of(state, now_minutes)
		var distance_sq: int = _nearest_focus_sq(spot)
		if distance_sq <= (exit_sq if _s0.has(npc_id) else enter_sq):
			found.append(Candidate.new(npc_id, distance_sq, spot))
	return found


## Onde o NPC está agora para o LOD: em S0, onde o corpo está; em S1, a posição derivada da ação e da hora (a reconstrução).
func _spot_of(state: NpcState, now_minutes: int) -> Vector2i:
	if _s0.has(state.npc_id):
		return _s0[state.npc_id].position
	var destination: Vector2i = LodReconstruction.NO_POSITION
	if place_position_cm.is_valid() and LodReconstruction.is_in_transit(state):
		# Variant: a resposta do chamador é conferida antes de usar.
		var answer: Variant = place_position_cm.call(state.action_target_place_id)
		if typeof(answer) == TYPE_VECTOR2I:
			destination = answer
	return LodReconstruction.position_at(state, now_minutes, destination, _leg_start_minute(state))


## Início do trecho em trânsito: o da ação, ou o minuto em que o corpo saiu de S0 com relato naquela mesma ação.
func _leg_start_minute(state: NpcState) -> int:
	var rebased: Vector2i = _leg_starts.get(state.npc_id, Vector2i(-1, -1))
	return rebased.y if rebased.x == state.action_serial else state.action_started_at


## Quadrado da distância (cm²) ao foco mais próximo, em inteiros de 64 bits (sem Vector2i.length_squared, que é de 32 bits).
func _nearest_focus_sq(spot: Vector2i) -> int:
	var best: int = -1
	for focus: Vector2i in _foci.values():
		var delta_x: int = spot.x - focus.x
		var delta_z: int = spot.y - focus.y
		var distance_sq: int = delta_x * delta_x + delta_z * delta_z
		if best < 0 or distance_sq < best:
			best = distance_sq
	return best


func _leave(npc_id: int, state: NpcState, now_minutes: int) -> void:
	var slot: S0Slot = _s0[npc_id]
	_s0.erase(npc_id)
	if state == null or not slot.has_report:
		return
	if LodReconstruction.is_in_transit(state):
		_leg_starts[npc_id] = Vector2i(state.action_serial, now_minutes)
	state.x_cm = slot.position.x
	state.z_cm = slot.position.y


func _forget_removed(npcs: Dictionary[int, NpcState]) -> void:
	for npc_id: int in _leg_starts.keys():
		if not npcs.has(npc_id):
			_leg_starts.erase(npc_id)


func _squared(value: int) -> int:
	return value * value


func _unconfigured(caller: String) -> Result:
	var why: String = "" if _params_problem.is_empty() else " (%s)" % _params_problem
	return Result.failure(CODE_NOT_CONFIGURED, "NpcLod.%s: LOD desligado, sem parâmetros válidos%s; esperado configure(LodParams) com o conteúdo de data/lod_params.json antes de usar." % [caller, why])


## Uma troca de nível, para o módulo publicar LodChanged.
class Change:
	extends RefCounted

	var npc_id: int
	var from_level: int
	var to_level: int

	func _init(changed_npc_id: int, level_before: int, level_after: int) -> void:
		npc_id = changed_npc_id
		from_level = level_before
		to_level = level_after

	static func is_before(first: Change, second: Change) -> bool:
		return first.npc_id < second.npc_id


## NPC em S0: onde o corpo está e se já houve relato dele (só relato vira posição lógica ao sair).
class S0Slot:
	extends RefCounted

	var position: Vector2i
	var has_report: bool = false

	func _init(start_position: Vector2i) -> void:
		position = start_position


## NPC elegível a S0 neste passo, com a distância ao foco mais próximo (cm²) e a posição usada.
class Candidate:
	extends RefCounted

	var npc_id: int
	var distance_sq: int
	var spot: Vector2i

	func _init(candidate_npc_id: int, candidate_distance_sq: int, candidate_spot: Vector2i) -> void:
		npc_id = candidate_npc_id
		distance_sq = candidate_distance_sq
		spot = candidate_spot

	## Mais perto primeiro; empate, o ID menor.
	static func is_closer(first: Candidate, second: Candidate) -> bool:
		return first.distance_sq < second.distance_sq or (first.distance_sq == second.distance_sq and first.npc_id < second.npc_id)
