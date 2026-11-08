class_name RelationChanged
extends SimEvent
## Fato: a relação entre duas pessoas mudou (LW-080). AGREGADO: no máximo UM por par por dia de jogo, nunca um por conversa (o dia da última
## publicação fica na própria relação, salvo junto). Carga pequena: os dois IDs (o menor primeiro) e as cinco dimensões de HOJE, na ordem de
## `NpcRelation.DIM_IDS`. `cause_id` é preenchido pelo EventBus. Catalogado em docs/events.md.

var a_id: int
var b_id: int
var values: PackedInt64Array


func _init(first_id: int, second_id: int, current_values: PackedInt64Array) -> void:
	super("RelationChanged")
	a_id = mini(first_id, second_id)
	b_id = maxi(first_id, second_id)
	values = current_values.duplicate()
