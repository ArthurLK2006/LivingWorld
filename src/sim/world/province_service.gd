class_name ProvinceService
extends RefCounted
## Consultas sobre as províncias e a adjacência (LW-118b; contrato em docs/modules/world.md, "Extensão da Fase 4"). Conteúdo somente leitura e SEM estado: não é salvo nem entra no state_hash. Toda
## consulta devolve CÓPIAS e, quando falha, uma falha tratada com código e mensagem que diz o que falhou, onde e o esperado. As listas saem sempre em ordem crescente de `id`, nunca pela ordem de um
## Dictionary (regra do MODELO.md). A adjacência não tem direção: se a é vizinha de b, b é vizinha de a. Os povoados de cada província entram com a LW-118c.

const CODE_PROVINCE_UNKNOWN: String = "PROVINCE_UNKNOWN"
## Quantos ids uma mensagem de erro lista antes de resumir o resto.
const MAX_LISTED_IDS: int = 8

var _provinces: Dictionary[String, Province] = {}
var _province_ids: Array[String] = []
## Ids das províncias vizinhas de cada uma, em ordem crescente.
var _neighbors: Dictionary[String, Array] = {}
## Inconsistências do conteúdo recebido (id repetido, ligação para província inexistente).
var _problems: Array[String] = []


## O serviço guarda os objetos recebidos como conteúdo somente leitura: quem os entrega (o carregador) não deve alterá-los depois.
func _init(provinces: Array[Province], links: Array[ProvinceLink]) -> void:
	for province: Province in provinces:
		if _provinces.has(province.id):
			_problems.append("província '%s' repetida." % province.id)
			continue
		_provinces[province.id] = province
		_neighbors[province.id] = []
	_province_ids.assign(_provinces.keys())
	_province_ids.sort()
	for link: ProvinceLink in links:
		if not _provinces.has(link.province_a_id) or not _provinces.has(link.province_b_id):
			_problems.append("ligação '%s' cita uma província que não existe ('%s' ou '%s')." % [link.id, link.province_a_id, link.province_b_id])
			continue
		if not _neighbors[link.province_a_id].has(link.province_b_id):
			_neighbors[link.province_a_id].append(link.province_b_id)
			_neighbors[link.province_b_id].append(link.province_a_id)
	for province_id: String in _province_ids:
		_neighbors[province_id].sort()


## A província (cópia). Província desconhecida: falha `PROVINCE_UNKNOWN`.
func peek_province(province_id: String) -> ProvinceQuery:
	if not _provinces.has(province_id):
		return ProvinceQuery.new(_unknown("peek_province", province_id), null)
	return ProvinceQuery.new(Result.success(), _copy(_provinces[province_id]))


## Todas as províncias (cópias), em ordem crescente de `id`.
func peek_provinces() -> ProvincesQuery:
	var found: Array[Province] = []
	for province_id: String in _province_ids:
		found.append(_copy(_provinces[province_id]))
	return ProvincesQuery.new(Result.success(), found)


## As províncias vizinhas (cópias), em ordem crescente de `id`. Província desconhecida: falha `PROVINCE_UNKNOWN`.
func peek_adjacent_provinces(province_id: String) -> ProvincesQuery:
	if not _provinces.has(province_id):
		return ProvincesQuery.new(_unknown("peek_adjacent_provinces", province_id), [])
	var found: Array[Province] = []
	for neighbor_id: String in _neighbors[province_id]:
		found.append(_copy(_provinces[neighbor_id]))
	return ProvincesQuery.new(Result.success(), found)


## As inconsistências do conteúdo recebido (lista vazia quando tudo bate), para o `validate()` do módulo.
func validate() -> Array[String]:
	var problems: Array[String] = []
	problems.assign(_problems)
	return problems


func debug_summary() -> Dictionary:
	return {"province_count": _province_ids.size(), "problems": _problems.size()}


func _copy(province: Province) -> Province:
	return Province.new(province.id, province.name_key, province.kind)


func _unknown(query_name: String, province_id: String) -> Result:
	var listed: Array[String] = _province_ids.slice(0, MAX_LISTED_IDS)
	var more: String = "" if _province_ids.size() <= MAX_LISTED_IDS else " e mais %d" % (_province_ids.size() - MAX_LISTED_IDS)
	return Result.failure(CODE_PROVINCE_UNKNOWN, "ProvinceService.%s: a província '%s' não existe; esperado uma das %d carregadas (%s%s)." % [query_name, province_id, _province_ids.size(), ", ".join(listed), more])


## Resposta de `peek_province`: `province` (cópia) só vale se `result.ok`.
class ProvinceQuery:
	extends RefCounted

	var result: Result
	var province: Province

	func _init(query_result: Result, found: Province) -> void:
		result = query_result
		province = found


## Resposta de `peek_provinces` e `peek_adjacent_provinces`: `provinces` (cópias, em ordem crescente de `id`) só vale se `result.ok`.
class ProvincesQuery:
	extends RefCounted

	var result: Result
	var provinces: Array[Province]

	func _init(query_result: Result, found: Array[Province]) -> void:
		result = query_result
		provinces = found
