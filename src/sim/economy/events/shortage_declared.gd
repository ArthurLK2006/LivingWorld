class_name ShortageDeclared
extends SimEvent
## Fato: o estoque de um bem num mercado ficou abaixo de `shortage_threshold_bp` do alvo por `shortage_days` dias seguidos (LW-090b); uma vez por escassez. Carga pequena: o mercado, o bem, o estoque e o alvo; a
## gravidade (quanto falta do alvo, de 0 a 100) vai no campo comum `severity`. `cause_id` é preenchido pelo EventBus. Catalogado em docs/events.md.

var market_id: int
var good_id: String
var stock: int
var target_stock: int


func _init(short_market_id: int, short_good_id: String, current_stock: int, target: int) -> void:
	super("ShortageDeclared")
	market_id = short_market_id
	good_id = short_good_id
	stock = current_stock
	target_stock = target
