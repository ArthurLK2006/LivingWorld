class_name ShortageEnded
extends SimEvent
## Fato: o estoque do bem voltou acima do limiar de escassez (LW-090b). Carga pequena: o mercado, o bem e quantos dias a escassez durou. `cause_id` é preenchido pelo EventBus. Catalogado em docs/events.md.

var market_id: int
var good_id: String
var days_in_shortage: int


func _init(ended_market_id: int, ended_good_id: String, days: int) -> void:
	super("ShortageEnded")
	market_id = ended_market_id
	good_id = ended_good_id
	days_in_shortage = days
