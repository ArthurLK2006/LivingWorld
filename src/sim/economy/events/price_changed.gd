class_name PriceChanged
extends SimEvent
## Fato: o preço de um bem num mercado variou, desde o último preço publicado, mais que `significant_change_bp` (nunca por centavo; LW-090b). Publicado ao fim do dia. Carga pequena: o mercado, o bem e os dois preços.
## `cause_id` é preenchido pelo EventBus. Catalogado em docs/events.md.

var market_id: int
var good_id: String
var old_price: int
var new_price: int


func _init(changed_market_id: int, changed_good_id: String, previous_price: int, current_price: int) -> void:
	super("PriceChanged")
	market_id = changed_market_id
	good_id = changed_good_id
	old_price = previous_price
	new_price = current_price
