class_name Province
extends RefCounted
## Província (LW-118b; contrato em docs/modules/world.md, "Extensão da Fase 4", DEC-207): uma divisão do mapa que agrupa povoados. É CONTEÚDO lido de data/world/provinces.json (somente leitura
## depois de montado): não é salvo nem entra no state_hash. O `world` guarda só a ESTRUTURA; quem controla a província é a `politics` e a influência é da `factions` (DEC-213, PROPOSTA). `kind`:
## `settled` (com pelo menos um povoado) ou `frontier` (sem nenhum; o terreno não cresce, DEC-161). Nomes de campos e valores seguem PROPOSTA.

const KIND_SETTLED: String = "settled"
const KIND_FRONTIER: String = "frontier"
const KINDS: Array[String] = [KIND_SETTLED, KIND_FRONTIER]

var id: String
## Chave de texto do nome (resolvida só pela apresentação).
var name_key: String
var kind: String


func _init(province_id: String, province_name_key: String, province_kind: String) -> void:
	id = province_id
	name_key = province_name_key
	kind = province_kind
