class_name LodParams
extends RefCounted
## Parâmetros do LOD lógico (LW-069; contrato em docs/modules/npc.md, seção 6): lidos de data/lod_params.json por LodParamsLoader e
## entregues ao LOD por quem monta o módulo, sem global nem autoload. Somente leitura depois de montados; nada aqui é salvo. Os números
## dos dados são [HIP] de trabalho. Raios em metros inteiros nos dados; as contas do LOD usam centímetros inteiros (CM_PER_METER).

const CM_PER_METER: int = 100
## Faixas de segurança [HIP] dos dados: protegem contra arquivo absurdo e não são requisito de jogo.
const MIN_RADIUS_M: int = 1
const MAX_RADIUS_M: int = 100000
const MIN_S0_LIMIT: int = 1
const MAX_S0_LIMIT: int = 10000

## A que distância do foco mais próximo um NPC vira S0 (inclusive no limite).
var lod_enter_radius_m: int
## Acima de que distância do foco mais próximo um NPC em S0 volta a S1 (a exatos `lod_exit_radius_m` ainda é S0). Maior que a de entrada.
var lod_exit_radius_m: int
## Quantos NPCs podem estar em S0 ao mesmo tempo.
var max_s0: int


func _init(enter_radius_m: int, exit_radius_m: int, s0_limit: int) -> void:
	lod_enter_radius_m = enter_radius_m
	lod_exit_radius_m = exit_radius_m
	max_s0 = s0_limit


func enter_radius_cm() -> int:
	return lod_enter_radius_m * CM_PER_METER


func exit_radius_cm() -> int:
	return lod_exit_radius_m * CM_PER_METER


## Primeiro motivo de os parâmetros não servirem (texto vazio se servem): raios e limite nas faixas, saída maior que entrada.
func problem() -> String:
	for entry: Array in [["lod_enter_radius_m", lod_enter_radius_m], ["lod_exit_radius_m", lod_exit_radius_m]]:
		if entry[1] < MIN_RADIUS_M or entry[1] > MAX_RADIUS_M:
			return "%s %d fora de %d a %d" % [entry[0], entry[1], MIN_RADIUS_M, MAX_RADIUS_M]
	if lod_exit_radius_m <= lod_enter_radius_m:
		return "lod_exit_radius_m (%d) precisa ser maior que lod_enter_radius_m (%d)" % [lod_exit_radius_m, lod_enter_radius_m]
	if max_s0 < MIN_S0_LIMIT or max_s0 > MAX_S0_LIMIT:
		return "max_s0 %d fora de %d a %d" % [max_s0, MIN_S0_LIMIT, MAX_S0_LIMIT]
	return ""
