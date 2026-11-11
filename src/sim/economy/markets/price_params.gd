class_name PriceParams
extends RefCounted
## Constantes de preço, spread, escassez e limite de ordem (LW-090; `data/economy/price_params.json`, uma linha; docs/modules/economy.md, seção 4), SÓ LEITURA depois de montadas. Todas em dados, NENHUMA no
## código (arquitetura 11.5): o carregador entrega o registro já validado e esta classe só o guarda (sem valor padrão). Só o piso e o teto vêm do GDD 12.3 (0,5 e 3 vezes o valor-base); o resto é [HIP] e a
## calibração é da LW-112. Proporções em pontos-base (10000 = 1,0).

var min_factor_bp: int
var max_factor_bp: int
var smoothing_bp: int
var spread_bp: int
var significant_change_bp: int
var max_order_quantity: int
var history_days: int
var shortage_threshold_bp: int
var shortage_days: int


## `record`: a linha de `price_params.json` já validada (todas as colunas presentes e inteiras).
func _init(record: Dictionary) -> void:
	min_factor_bp = record["min_factor_bp"]
	max_factor_bp = record["max_factor_bp"]
	smoothing_bp = record["smoothing_bp"]
	spread_bp = record["spread_bp"]
	significant_change_bp = record["significant_change_bp"]
	max_order_quantity = record["max_order_quantity"]
	history_days = record["history_days"]
	shortage_threshold_bp = record["shortage_threshold_bp"]
	shortage_days = record["shortage_days"]
