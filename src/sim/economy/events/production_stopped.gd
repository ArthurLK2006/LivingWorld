class_name ProductionStopped
extends SimEvent
## Fato: um local de produção passou de produzindo a parado (LW-092b), SÓ na mudança de estado, nunca a cada hora. Carga pequena: o local, o assentamento, a receita e o motivo (`NO_WORKER`, `NO_INPUT`, `OUTPUT_FULL` ou
## `NO_FUNDS`, a folha que a conta do local não cobre, LW-095). `cause_id` é preenchido pelo EventBus. Catalogado em docs/events.md.

var site_id: int
var settlement_id: String
var recipe_id: String
var reason: String


func _init(stopped_site_id: int, site_settlement_id: String, site_recipe_id: String, stop_reason: String) -> void:
	super("ProductionStopped")
	site_id = stopped_site_id
	settlement_id = site_settlement_id
	recipe_id = site_recipe_id
	reason = stop_reason
