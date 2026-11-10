class_name NpcRoutineView
extends RefCounted
## Visão da rotina do ofício para quem está FORA do módulo `npc` (LW-085a; contrato em docs/modules/npc.md, "A porta `api/` e a fronteira com a ponte"): cópia do que
## `NpcModule.peek_routine_action` devolve, para a ponte nunca citar `RoutineTable`. `result.ok` diz se deu certo; só então `action_id` vale. Só lê: sem estado, fora do save e do hash.

var result: Result
var action_id: String = ""


func _init(query_result: Result, found_action_id: String = "") -> void:
	result = query_result
	action_id = found_action_id


## Copia o retorno de `peek_routine_action`.
static func of(query: RoutineTable.RoutineQuery) -> NpcRoutineView:
	return NpcRoutineView.new(query.result, query.action_id)
