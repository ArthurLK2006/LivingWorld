class_name SiteParams
extends RefCounted
## As constantes de eficiência dos locais de produção (LW-092; `data/economy/site_params.json`, uma linha), SÓ LEITURA: quanto a eficiência cai por dia com manutenção vencida e não paga, quanto sobe por dia sem ela e o piso, que
## é MAIOR que 0 (a produção cai por degrau, nunca zera por falta de manutenção). Pontos-base (10000 = 100%). NENHUMA no código: sem valor padrão. Valores [HIP], calibração na LW-112.

var efficiency_step_bp: int
var efficiency_recover_bp: int
var min_efficiency_bp: int


## `record`: a linha de `site_params.json` já validada.
func _init(record: Dictionary) -> void:
	efficiency_step_bp = record["efficiency_step_bp"]
	efficiency_recover_bp = record["efficiency_recover_bp"]
	min_efficiency_bp = record["min_efficiency_bp"]
