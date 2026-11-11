class_name MarketTargetDef
extends RefCounted
## Uma linha de `data/economy/market_targets.json` (LW-090): o estoque-alvo, o estoque inicial e o teto de compra de um bem num mercado, SÓ LEITURA. `target_stock` 0 = bem não negociado nesse mercado; o teto de
## compra é `target_stock × buy_cap_bp ÷ 10000` (DEC-177): acima dele o mercado não compra mais. Valores [HIP] em dados (calibração na LW-112).

var id: String
var settlement_id: String
var good_id: String
var target_stock: int
var initial_stock: int
var buy_cap_bp: int


func _init(row_id: String, settlement: String, good: String, target: int, initial: int, cap_bp: int) -> void:
	id = row_id
	settlement_id = settlement
	good_id = good
	target_stock = target
	initial_stock = initial
	buy_cap_bp = cap_bp


## O estoque máximo que o mercado aceita por compra (arredondado para baixo).
func buy_cap() -> int:
	return IntMath.floor_div(target_stock * buy_cap_bp, 10000)
