class_name FlowParams
extends RefCounted
## Os parâmetros PRÓPRIOS do fluxo agregado por rota (LW-100b; `data/economy/flow_params.json`, uma linha; docs/modules/economy.md, 9.16.2 e 9.16.3), SÓ LEITURA depois de montados. Os demais números do fluxo vêm da `CaravanParams` (uma fonte só, para os dois modos ficarem comparáveis). Nenhum move dinheiro nem bem:
## são de DECISÃO (o teto do lote) e de CORTE do envio (o risco). Todos em dados, NENHUM no código (sem valor padrão); valores [HIP], calibração no SP7 (LW-101). Proporções em pontos-base (10000 = 1,0).

## O `id` da única linha do arquivo.
const ROW_ID: String = "flow_defaults"

## O teto de unidades de UM lote (um bem, um sentido, por rota e por dia): 1 a 1000 (partida 50, o `max_order_quantity` de hoje).
var daily_cap_units: int
## Os pontos-base de corte do envio por ponto de risco da rota: 0 a 100 (partida 25, o valor da caravana, mas campo próprio).
var risk_bp_per_point: int


## `record`: a linha de `flow_params.json` já validada (as duas colunas presentes e inteiras).
func _init(record: Dictionary) -> void:
	daily_cap_units = record["daily_cap_units"]
	risk_bp_per_point = record["risk_bp_per_point"]


## A linha no formato do arquivo: reescrita e relida pelo carregador, dá o mesmo objeto (serialização do dado, como no vizinho `CaravanParams`).
func to_record() -> Dictionary:
	return {"id": ROW_ID, "daily_cap_units": daily_cap_units, "risk_bp_per_point": risk_bp_per_point}
