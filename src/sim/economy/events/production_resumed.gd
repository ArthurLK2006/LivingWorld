class_name ProductionResumed
extends SimEvent
## Fato: um local de produção voltou a produzir depois de parado (LW-092b), SÓ na mudança de estado. Carga pequena: o local, o assentamento e a receita. `cause_id` é preenchido pelo EventBus. Catalogado em docs/events.md.

var site_id: int
var settlement_id: String
var recipe_id: String


func _init(resumed_site_id: int, site_settlement_id: String, site_recipe_id: String) -> void:
	super("ProductionResumed")
	site_id = resumed_site_id
	settlement_id = site_settlement_id
	recipe_id = site_recipe_id
