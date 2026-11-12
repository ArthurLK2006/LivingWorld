class_name CultureService
extends RefCounted
## Consultas sobre as culturas e a cultura de cada povoado (LW-118c; contrato em docs/modules/world.md, "Extensão da Fase 4"). Conteúdo somente leitura e SEM estado: não é salvo nem entra no
## state_hash. Toda consulta devolve CÓPIAS e, quando falha, uma falha tratada com código e mensagem que diz o que falhou, onde e o esperado; as listas saem em ordem crescente de `id`.
## A cultura de um NPC é a do povoado de moradia dele (derivada, sem campo novo no NPC): quem pergunta (o `npc`, a `factions`) informa o povoado.

const CODE_CULTURE_UNKNOWN: String = "CULTURE_UNKNOWN"
## Quantos ids uma mensagem de erro lista antes de resumir o resto.
const MAX_LISTED_IDS: int = 8

var _cultures: Dictionary[String, Culture] = {}
var _culture_ids: Array[String] = []
var _culture_of: Dictionary[String, String] = {}
var _settlement_ids: Array[String] = []
## Inconsistências do conteúdo recebido (id repetido, povoado com cultura que não existe).
var _problems: Array[String] = []


## O serviço guarda os objetos recebidos como conteúdo somente leitura: quem os entrega (o carregador) não deve alterá-los depois.
func _init(cultures: Array[Culture], settlements: Array[Settlement] = []) -> void:
	for culture: Culture in cultures:
		if _cultures.has(culture.id):
			_problems.append("cultura '%s' repetida." % culture.id)
			continue
		_cultures[culture.id] = culture
	_culture_ids.assign(_cultures.keys())
	_culture_ids.sort()
	for settlement: Settlement in settlements:
		_settlement_ids.append(settlement.id)
		if _cultures.has(settlement.culture_id):
			_culture_of[settlement.id] = settlement.culture_id
		else:
			_problems.append("o povoado '%s' cita uma cultura que não existe ('%s')." % [settlement.id, settlement.culture_id])
	_settlement_ids.sort()


## A cultura (cópia). Cultura desconhecida: falha `CULTURE_UNKNOWN`.
func peek_culture(culture_id: String) -> CultureQuery:
	if not _cultures.has(culture_id):
		return CultureQuery.new(_unknown_culture("peek_culture", culture_id), null)
	return CultureQuery.new(Result.success(), _copy(_cultures[culture_id]))


## Todas as culturas (cópias), em ordem crescente de `id`.
func peek_cultures() -> CulturesQuery:
	var found: Array[Culture] = []
	for culture_id: String in _culture_ids:
		found.append(_copy(_cultures[culture_id]))
	return CulturesQuery.new(Result.success(), found)


## A cultura do povoado (cópia). Povoado desconhecido: falha `SETTLEMENT_UNKNOWN`; povoado sem cultura que exista: `CULTURE_UNKNOWN`.
func peek_culture_of(settlement_id: String) -> CultureQuery:
	if not _settlement_ids.has(settlement_id):
		return CultureQuery.new(Result.failure(SettlementService.CODE_SETTLEMENT_UNKNOWN, "CultureService.peek_culture_of: o povoado '%s' não existe; esperado um dos %d carregados (%s)." % [settlement_id, _settlement_ids.size(), ", ".join(_settlement_ids.slice(0, MAX_LISTED_IDS))]), null)
	if not _culture_of.has(settlement_id):
		return CultureQuery.new(Result.failure(CODE_CULTURE_UNKNOWN, "CultureService.peek_culture_of: o povoado '%s' não tem uma cultura que exista; esperado um povoado com culture_id de cultures.json." % settlement_id), null)
	return CultureQuery.new(Result.success(), _copy(_cultures[_culture_of[settlement_id]]))


## As inconsistências do conteúdo recebido (lista vazia quando tudo bate), para o `validate()` do módulo.
func validate() -> Array[String]:
	var problems: Array[String] = []
	problems.assign(_problems)
	return problems


func debug_summary() -> Dictionary:
	return {"culture_count": _culture_ids.size(), "problems": _problems.size()}


func _copy(culture: Culture) -> Culture:
	return Culture.new(culture.id, culture.name_key, culture.trade_openness, culture.foreigner_tolerance, culture.martial_stance, culture.authority_weight)


func _unknown_culture(query_name: String, culture_id: String) -> Result:
	var listed: Array[String] = _culture_ids.slice(0, MAX_LISTED_IDS)
	var more: String = "" if _culture_ids.size() <= MAX_LISTED_IDS else " e mais %d" % (_culture_ids.size() - MAX_LISTED_IDS)
	return Result.failure(CODE_CULTURE_UNKNOWN, "CultureService.%s: a cultura '%s' não existe; esperado uma das %d carregadas (%s%s)." % [query_name, culture_id, _culture_ids.size(), ", ".join(listed), more])


## Resposta de `peek_culture` e `peek_culture_of`: `culture` (cópia) só vale se `result.ok`.
class CultureQuery:
	extends RefCounted

	var result: Result
	var culture: Culture

	func _init(query_result: Result, found: Culture) -> void:
		result = query_result
		culture = found


## Resposta de `peek_cultures`: `cultures` (cópias, em ordem crescente de `id`) só vale se `result.ok`.
class CulturesQuery:
	extends RefCounted

	var result: Result
	var cultures: Array[Culture]

	func _init(query_result: Result, found: Array[Culture]) -> void:
		result = query_result
		cultures = found
