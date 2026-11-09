class_name NpcRelationsQuery
extends RefCounted
## Resposta de `NpcModule.peek_relations` (LW-082b; contrato em docs/modules/npc.md, seção 10): as relações de UM NPC, em CÓPIAS, uma por pessoa que ele
## conhece, em ordem crescente do ID da outra pessoa. `result.ok` diz se deu certo; só então `entries` vale. As dimensões são as de HOJE (com o
## decaimento diário, a mesma conta de `peek_opinion`). Só lê: nada aqui escreve no grafo.

var result: Result
var entries: Array[Entry] = []


func _init(query_result: Result) -> void:
	result = query_result


## Monta a resposta de `npc_id` a partir do grafo. `npcs` só serve para saber se a outra pessoa vive; quem não é NPC (o jogador) conta como vivo.
static func build(graph: RelationGraph, npcs: Dictionary[int, NpcState], npc_id: int, today: int, rules: RelationGraph.Rules) -> NpcRelationsQuery:
	var query: NpcRelationsQuery = NpcRelationsQuery.new(Result.success())
	for relation: NpcRelation in graph.relations_of(npc_id):
		var entry: Entry = Entry.new()
		entry.other_id = relation.other_id(npc_id)
		entry.values = relation.values_at(today, rules.decay_per_day)
		entry.label = RelationGraph.label_for(entry.values[NpcRelation.DIM_AFFECTION], rules)
		entry.met_at = relation.met_at
		entry.other_is_alive = not npcs.has(entry.other_id) or npcs[entry.other_id].is_alive
		query.entries.append(entry)
	query.entries.sort_custom(func(first: Entry, second: Entry) -> bool: return first.other_id < second.other_id)
	return query


## Uma relação do NPC perguntado com `other_id`: as cinco dimensões na ordem de `NpcRelation.DIM_IDS`, o rótulo (conhecido, amigo ou rival), o minuto
## em que se conheceram e se a outra pessoa está viva.
class Entry:
	extends RefCounted

	var other_id: int = 0
	var values: PackedInt64Array = PackedInt64Array()
	var label: String = ""
	var met_at: int = 0
	var other_is_alive: bool = true
