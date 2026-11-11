class_name Route
extends RefCounted
## Rota entre dois assentamentos (LW-097b; contrato em docs/modules/world.md, seção "Extensão da Fase 3"): CONTEÚDO lido de
## data/world/routes.json, somente leitura depois de montado, sem estado salvo (o estado aberta/fechada é da LW-097c). Sem direção: a
## rota (a, b) é a rota (b, a). `difficulty` e `risk` são só dados: o `world` não os usa em conta nenhuma, quem viaja os pesa (economia).

const MIN_LENGTH_M: int = 1
const MAX_LENGTH_M: int = 100000
const MAX_RATING: int = 100

var id: String
var settlement_a_id: String
var settlement_b_id: String
## Comprimento em metros inteiros [HIP].
var length_m: int
## De 0 (estrada plana) a 100 (o pior caso) [HIP].
var difficulty: int
## De 0 (segura) a 100 (o pior caso) [HIP].
var risk: int


func _init(route_id: String, route_settlement_a_id: String, route_settlement_b_id: String, route_length_m: int, route_difficulty: int, route_risk: int) -> void:
	id = route_id
	settlement_a_id = route_settlement_a_id
	settlement_b_id = route_settlement_b_id
	length_m = route_length_m
	difficulty = route_difficulty
	risk = route_risk


## O assentamento do outro lado da rota (vazio se `settlement_id` não é uma das pontas).
func other_end(settlement_id: String) -> String:
	if settlement_id == settlement_a_id:
		return settlement_b_id
	if settlement_id == settlement_b_id:
		return settlement_a_id
	return ""
