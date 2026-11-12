class_name Settlement
extends RefCounted
## Assentamento (LW-056; contrato em docs/modules/world.md, seção "Extensão da Fase 2: assentamentos e locais"): um povoado do mapa,
## com um centro. É CONTEÚDO lido de data/world/settlements.json (somente leitura depois de montado): não é salvo nem entra no
## state_hash. A simulação guarda só a CHAVE do nome (`name_key`, texto genérico e provisório, DEC-100); quem a traduz em frase é a
## apresentação. A altura (`position.y`) NÃO vem do arquivo: é a do terreno no centro.

var id: String
## Chave de texto do nome (resolvida só pela apresentação).
var name_key: String
## Metros; centro do assentamento, y = altura do terreno em (x, z).
var position: Vector3
## A província do povoado (LW-118c, `provinces.json`) e a cultura dele (`cultures.json`); vazios quando o arquivo não traz as colunas. A conferência de que existem e de que batem com as
## províncias e as culturas é do `SettlementProvinceCheck`, não do `SettlementLoader`.
var province_id: String
var culture_id: String


func _init(settlement_id: String, settlement_name_key: String, settlement_position: Vector3, settlement_province_id: String = "", settlement_culture_id: String = "") -> void:
	id = settlement_id
	name_key = settlement_name_key
	position = settlement_position
	province_id = settlement_province_id
	culture_id = settlement_culture_id
