class_name NpcTraceView
extends RefCounted
## Visão do rastro de decisão para quem está FORA do módulo `npc` (LW-085a; contrato em docs/modules/npc.md, "A porta `api/` e a fronteira com a ponte"): cópias de dados
## puros do que `NpcModule.explain_decision` devolve, para a ponte nunca citar `DecisionTracer`. `result.ok` diz se deu certo; só então `records` vale (do mais antigo ao mais
## novo). Só lê: não guarda estado, não é salvo e não entra no hash. Os campos têm os mesmos nomes e valores dos registros do `DecisionTracer`.

var result: Result
var records: Array[Record] = []


func _init(query_result: Result) -> void:
	result = query_result


## Copia o retorno de `explain_decision`. Falha (NPC inexistente ou sem marca): o mesmo `result`, sem registros.
static func of(explanation: DecisionTracer.Explanation) -> NpcTraceView:
	var view: NpcTraceView = NpcTraceView.new(explanation.result)
	for source: DecisionTracer.DecisionRecord in explanation.records:
		var record: Record = Record.new()
		record.minute = source.minute
		record.need_values = source.need_values.duplicate()
		record.chosen_action_id = source.chosen_action_id
		record.chosen_place_id = source.chosen_place_id
		record.reason = source.reason
		for found: DecisionTracer.CandidateRecord in source.candidates:
			var candidate: Candidate = Candidate.new()
			candidate.action_id = found.action_id
			candidate.place_id = found.place_id
			candidate.benefit = found.benefit
			candidate.personality = found.personality
			candidate.time_cost = found.time_cost
			candidate.distance_cost = found.distance_cost
			candidate.risk_cost = found.risk_cost
			candidate.inertia_bonus = found.inertia_bonus
			candidate.routine_bonus = found.routine_bonus
			candidate.total = found.total
			candidate.is_current = found.is_current
			candidate.source = found.source
			record.candidates.append(candidate)
		view.records.append(record)
	return view


## Uma candidata do pensamento, com as parcelas da pontuação.
class Candidate:
	extends RefCounted

	var action_id: String = ""
	var place_id: String = ""
	var benefit: int = 0
	var personality: int = 0
	var time_cost: int = 0
	var distance_cost: int = 0
	var risk_cost: int = 0
	var inertia_bonus: int = 0
	var routine_bonus: int = 0
	var total: int = 0
	var is_current: bool = false
	var source: String = ""


## Um pensamento: o minuto, as necessidades, as candidatas, a escolha (vazia se o NPC não fez nada) e o motivo.
class Record:
	extends RefCounted

	var minute: int = 0
	var need_values: PackedInt64Array = PackedInt64Array()
	var candidates: Array[Candidate] = []
	var chosen_action_id: String = ""
	var chosen_place_id: String = ""
	var reason: String = ""
