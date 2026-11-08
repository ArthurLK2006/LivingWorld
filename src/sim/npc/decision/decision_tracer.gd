class_name DecisionTracer
extends RefCounted
## Rastro de decisão do NPC (LW-064; docs/modules/npc.md, seção 5): para os NPCs MARCADOS guarda os últimos `TRACE_DEPTH` pensamentos, cada um
## com as necessidades no momento, TODAS as candidatas com cada parcela da pontuação (a mesma que o UtilityScorer devolveu), a ação e o local
## escolhidos e o motivo. NPC não marcado não gera custo nem dado: o pensador pergunta `is_traced` (uma consulta a um Dictionary) e só então
## monta os registros. O rastro é só para olhar: não é salvo, não entra no hash, não usa sorteio e não muda nenhuma decisão. Quem marca é o
## NpcModule (`request_set_traced`, só em build de desenvolvimento). Não há evento "NpcDecided" (seria evento em laço quente, AGENTS 4.14).

## Motivos de a ação ter sido escolhida (`INTERRUPTION`, do alarme, entra com a LW-076).
const REASON_URGENT_NEED: String = "URGENT_NEED"
const REASON_ROUTINE: String = "ROUTINE"
const REASON_INERTIA: String = "INERTIA"
## Nenhuma candidata pôde começar: o NPC espera (ação `wait`).
const REASON_FALLBACK: String = "FALLBACK"
const CODE_NOT_TRACED: String = "NPC_NOT_TRACED"
## Quantos pensamentos guardar por NPC marcado [HIP].
const TRACE_DEPTH: int = 8

## Registros criados desde que o rastreador nasceu (observação para teste: com ninguém marcado fica em zero). Não é salvo.
var records_made: int = 0
var _traced: Dictionary[int, Array] = {}


## Marca ou desmarca o NPC. Desmarcar apaga o rastro dele; marcar de novo começa do zero.
func set_traced(npc_id: int, is_traced_now: bool) -> void:
	if is_traced_now:
		if not _traced.has(npc_id):
			_traced[npc_id] = []
	else:
		_traced.erase(npc_id)


func is_traced(npc_id: int) -> bool:
	return _traced.has(npc_id)


## Esquece o NPC (removido do jogo).
func forget(npc_id: int) -> void:
	_traced.erase(npc_id)


## Esquece todos (depois de carregar um save: as marcas não são salvas).
func clear() -> void:
	_traced.clear()


func traced_count() -> int:
	return _traced.size()


## Guarda um pensamento do NPC marcado, copiando os valores; mantém só os últimos TRACE_DEPTH. NPC não marcado: não faz nada.
func record(npc_id: int, minute: int, need_values: PackedInt64Array, candidates: Array[CandidateRecord], chosen_action_id: String, chosen_place_id: String, reason: String) -> void:
	if not _traced.has(npc_id):
		return
	var records: Array = _traced[npc_id]
	records.append(DecisionRecord.new(minute, need_values.duplicate(), candidates, chosen_action_id, chosen_place_id, reason))
	records_made += 1
	while records.size() > TRACE_DEPTH:
		records.pop_front()


## Os pensamentos guardados (cópias; o mais antigo primeiro). NPC não marcado: falha tratada `NPC_NOT_TRACED`.
func explain(npc_id: int) -> Explanation:
	if not _traced.has(npc_id):
		return Explanation.new(Result.failure(CODE_NOT_TRACED, "DecisionTracer.explain: o NPC %d não está marcado para rastro; esperado marcá-lo antes com request_set_traced (só em build de desenvolvimento)." % npc_id), [])
	var copies: Array[DecisionRecord] = []
	for stored: Variant in _traced[npc_id]:
		var stored_record: DecisionRecord = stored
		copies.append(stored_record.duplicate_record())
	return Explanation.new(Result.success(), copies)


## Uma candidata do pensamento, com as parcelas da pontuação.
class CandidateRecord:
	extends RefCounted

	var action_id: String
	var place_id: String
	var benefit: int
	var personality: int
	var time_cost: int
	var distance_cost: int
	var risk_cost: int
	var inertia_bonus: int
	var routine_bonus: int
	var total: int
	## Era a ação em andamento do NPC?
	var is_current: bool
	## De onde a candidata veio: `URGENT_NEED` (alivia uma necessidade urgente), `ROUTINE` (ação da rotina da hora) ou `INERTIA` (só estava em andamento).
	var source: String

	func _init(candidate_action_id: String, candidate_place_id: String, breakdown: UtilityScorer.ScoreBreakdown, candidate_is_current: bool, candidate_source: String) -> void:
		action_id = candidate_action_id
		place_id = candidate_place_id
		benefit = breakdown.benefit
		personality = breakdown.personality
		time_cost = breakdown.time_cost
		distance_cost = breakdown.distance_cost
		risk_cost = breakdown.risk_cost
		inertia_bonus = breakdown.inertia_bonus
		routine_bonus = breakdown.routine_bonus
		total = breakdown.total
		is_current = candidate_is_current
		source = candidate_source

	func duplicate_record() -> CandidateRecord:
		var breakdown: UtilityScorer.ScoreBreakdown = UtilityScorer.ScoreBreakdown.new()
		breakdown.benefit = benefit
		breakdown.personality = personality
		breakdown.time_cost = time_cost
		breakdown.distance_cost = distance_cost
		breakdown.risk_cost = risk_cost
		breakdown.inertia_bonus = inertia_bonus
		breakdown.routine_bonus = routine_bonus
		breakdown.total = total
		return CandidateRecord.new(action_id, place_id, breakdown, is_current, source)


## Um pensamento: o minuto, as necessidades, as candidatas (da melhor para a pior, a ordem em que foram sorteadas), a escolha e o motivo.
class DecisionRecord:
	extends RefCounted

	var minute: int
	var need_values: PackedInt64Array
	var candidates: Array[CandidateRecord]
	## Vazios se o NPC não fez nada (nem a espera).
	var chosen_action_id: String
	var chosen_place_id: String
	var reason: String

	func _init(record_minute: int, record_need_values: PackedInt64Array, record_candidates: Array[CandidateRecord], record_action_id: String, record_place_id: String, record_reason: String) -> void:
		minute = record_minute
		need_values = record_need_values
		candidates = record_candidates
		chosen_action_id = record_action_id
		chosen_place_id = record_place_id
		reason = record_reason

	func duplicate_record() -> DecisionRecord:
		var copies: Array[CandidateRecord] = []
		for candidate: CandidateRecord in candidates:
			copies.append(candidate.duplicate_record())
		return DecisionRecord.new(minute, need_values.duplicate(), copies, chosen_action_id, chosen_place_id, reason)


## Resposta de `explain_decision`: `records` só vale se `result.ok`.
class Explanation:
	extends RefCounted

	var result: Result
	var records: Array[DecisionRecord]

	func _init(explain_result: Result, explain_records: Array[DecisionRecord]) -> void:
		result = explain_result
		records = explain_records
