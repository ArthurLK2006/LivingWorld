class_name Culture
extends RefCounted
## Cultura (LW-118a; contrato em docs/modules/world.md, "Extensão da Fase 4", DEC-203): um conjunto de quatro parâmetros que descreve como um povo vê o comércio, o estrangeiro, a guerra
## e o poder. É CONTEÚDO lido de data/world/cultures.json (somente leitura depois de montado): não é salvo nem entra no state_hash. O `world` NÃO usa os parâmetros em conta nenhuma: quem
## lê são a `factions` (afinidade inicial), o `military` (doutrina padrão) e a `politics`. Os quatro valores são inteiros de 0 a 100 [HIP]; os nomes dos campos seguem PROPOSTA.

const MIN_PARAMETER: int = 0
const MAX_PARAMETER: int = 100

var id: String
## Chave de texto do nome (resolvida só pela apresentação).
var name_key: String
## O quanto a cultura valoriza comércio e novidade (100 = mercantil).
var trade_openness: int
## Atitude com estrangeiros (100 = acolhedora).
var foreigner_tolerance: int
## Doutrina militar (0 = defensiva, 100 = ofensiva).
var martial_stance: int
## Estrutura de poder (0 = descentralizada, 100 = centralizada).
var authority_weight: int


func _init(culture_id: String, culture_name_key: String, trade: int, tolerance: int, martial: int, authority: int) -> void:
	id = culture_id
	name_key = culture_name_key
	trade_openness = trade
	foreigner_tolerance = tolerance
	martial_stance = martial
	authority_weight = authority
