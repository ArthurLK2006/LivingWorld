class_name Place
extends RefCounted
## Local de um assentamento (LW-056; contrato em docs/modules/world.md, seção "Extensão da Fase 2: assentamentos e locais"): um lugar
## onde se mora, trabalha, descansa ou convive. É CONTEÚDO lido de data/world/places.json (somente leitura depois de montado): não é
## salvo nem entra no state_hash. Só a CAPACIDADE é daqui; quem está em cada local (ocupação) é dado do `npc`. A altura (`position.y`)
## NÃO vem do arquivo: é a do terreno no local.

const KIND_HOME: String = "home"
const KIND_WORK: String = "work"
const KIND_REST: String = "rest"
const KIND_SOCIAL: String = "social"
## O local onde mora o mercado do assentamento (LW-093, DEC-160; antes `market_reserved`, reservado na Fase 2): o NPC vai até ele para comprar e vender.
const KIND_MARKET: String = "market"
## Vocabulário fechado dos tipos de local (texto em snake_case).
const KINDS: Array[String] = [KIND_HOME, KIND_WORK, KIND_REST, KIND_SOCIAL, KIND_MARKET]
## Faixa da capacidade [HIP]: moradores da casa, trabalhadores do local de trabalho ou ocupantes ao mesmo tempo nos de descanso e convívio.
const MIN_CAPACITY: int = 1
const MAX_CAPACITY: int = 64

var id: String
var settlement_id: String
var kind: String
## Metros; y = altura do terreno em (x, z).
var position: Vector3
var capacity: int


func _init(place_id: String, place_settlement_id: String, place_kind: String, place_position: Vector3, place_capacity: int) -> void:
	id = place_id
	settlement_id = place_settlement_id
	kind = place_kind
	position = place_position
	capacity = place_capacity
