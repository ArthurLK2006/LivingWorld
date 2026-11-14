class_name CaravanParams
extends RefCounted
## Os parâmetros do comerciante e da caravana (LW-098b; `data/economy/caravan_params.json`, uma linha; docs/modules/economy.md, 9.3 e 9.5; docs/economy/dados.md), SÓ LEITURA depois de montados. São de DECISÃO e de TEMPO: nenhum move dinheiro (9.6). Todos em dados, NENHUM no código
## (sem valor padrão); valores [HIP], calibração na LW-112. Proporções em pontos-base (10000 = 1,0); dinheiro na menor unidade.

## O `id` da única linha do arquivo.
const ROW_ID: String = "caravan_defaults"

var speed_cm_per_min: int
var difficulty_slowdown_bp: int
var risk_bp_per_point: int
var time_cost_per_hour: int
var fixed_cost: int
var min_net_profit: int
var min_margin_bp: int
var origin_reserve_bp: int


## `record`: a linha de `caravan_params.json` já validada (todas as colunas presentes e inteiras).
func _init(record: Dictionary) -> void:
	speed_cm_per_min = record["speed_cm_per_min"]
	difficulty_slowdown_bp = record["difficulty_slowdown_bp"]
	risk_bp_per_point = record["risk_bp_per_point"]
	time_cost_per_hour = record["time_cost_per_hour"]
	fixed_cost = record["fixed_cost"]
	min_net_profit = record["min_net_profit"]
	min_margin_bp = record["min_margin_bp"]
	origin_reserve_bp = record["origin_reserve_bp"]


## A linha no formato do arquivo: reescrita e relida pelo carregador, dá o mesmo objeto (serialização do dado, exigida por Arthur em 14/11/2026).
func to_record() -> Dictionary:
	return {"id": ROW_ID, "speed_cm_per_min": speed_cm_per_min, "difficulty_slowdown_bp": difficulty_slowdown_bp, "risk_bp_per_point": risk_bp_per_point, "time_cost_per_hour": time_cost_per_hour, "fixed_cost": fixed_cost, "min_net_profit": min_net_profit, "min_margin_bp": min_margin_bp, "origin_reserve_bp": origin_reserve_bp}
