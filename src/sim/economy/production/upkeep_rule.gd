class_name UpkeepRule
extends RefCounted
## Uma regra de manutenção de uma receita (LW-092; `data/economy/site_upkeep.json`): o local gasta `quantity` unidades de `good_id` (`tool`, `plank` ou `fabric`) a cada `period_days` dias. SÓ LEITURA. Valores [HIP] em dados
## (calibração na LW-112). "Por dia" = quantidade ÷ período.

var good_id: String
var quantity: int
var period_days: int


func _init(upkeep_good_id: String, upkeep_quantity: int, upkeep_period_days: int) -> void:
	good_id = upkeep_good_id
	quantity = upkeep_quantity
	period_days = upkeep_period_days
