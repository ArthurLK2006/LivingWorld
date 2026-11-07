class_name SettlementService
extends RefCounted
## Consultas sobre assentamentos e locais (LW-056; contrato em docs/modules/world.md, seção "Extensão da Fase 2: assentamentos e
## locais"). Conteúdo somente leitura e SEM estado salvo: NÃO é módulo registrado no `World` (como o InteractionService), então não
## entra no save nem no state_hash. Toda consulta devolve CÓPIAS e, quando falha, uma falha tratada com código e mensagem que diz o que
## falhou, onde e o esperado. As listas saem sempre em ordem crescente de `id`, nunca pela ordem de um Dictionary (regra do MODELO.md).
## Aqui só existe a CAPACIDADE de cada local: quem está em cada um (ocupação) é dado do `npc`.

const CODE_SETTLEMENT_UNKNOWN: String = "SETTLEMENT_UNKNOWN"
const CODE_PLACE_UNKNOWN: String = "PLACE_UNKNOWN"
const CODE_PLACE_KIND_INVALID: String = "PLACE_KIND_INVALID"
## Quantos ids uma mensagem de erro lista antes de resumir o resto.
const MAX_LISTED_IDS: int = 8

var _settlements: Dictionary[String, Settlement] = {}
var _places: Dictionary[String, Place] = {}
## Ids dos assentamentos e dos locais em ordem crescente (para listar e para as mensagens).
var _settlement_ids: Array[String] = []
var _place_ids: Array[String] = []
## Ids dos locais de cada assentamento, em ordem crescente.
var _place_ids_by_settlement: Dictionary[String, Array] = {}
## Inconsistências do conteúdo recebido (id repetido, local com assentamento inexistente, assentamento sem local).
var _problems: Array[String] = []


## O serviço guarda os objetos recebidos como conteúdo somente leitura: quem os entrega (o carregador) não deve alterá-los depois.
func _init(settlements: Array[Settlement], places: Array[Place]) -> void:
	for settlement: Settlement in settlements:
		if _settlements.has(settlement.id):
			_problems.append("assentamento '%s' repetido." % settlement.id)
			continue
		_settlements[settlement.id] = settlement
		_place_ids_by_settlement[settlement.id] = []
	for place: Place in places:
		if _places.has(place.id):
			_problems.append("local '%s' repetido." % place.id)
			continue
		if not _settlements.has(place.settlement_id):
			_problems.append("local '%s' cita o assentamento '%s', que não existe." % [place.id, place.settlement_id])
			continue
		_places[place.id] = place
		_place_ids_by_settlement[place.settlement_id].append(place.id)
	_settlement_ids.assign(_settlements.keys())
	_settlement_ids.sort()
	_place_ids.assign(_places.keys())
	_place_ids.sort()
	for settlement_id: String in _settlement_ids:
		var ids_of_settlement: Array = _place_ids_by_settlement[settlement_id]
		ids_of_settlement.sort()
		if ids_of_settlement.is_empty():
			_problems.append("assentamento '%s' sem nenhum local." % settlement_id)


## O assentamento (cópia) e os ids dos seus locais, em ordem crescente. Assentamento desconhecido: falha `SETTLEMENT_UNKNOWN`.
func peek_settlement(settlement_id: String) -> SettlementQuery:
	if not _settlements.has(settlement_id):
		return SettlementQuery.new(_unknown_settlement("peek_settlement", settlement_id), null, [])
	var place_ids: Array[String] = []
	place_ids.assign(_place_ids_by_settlement[settlement_id])
	return SettlementQuery.new(Result.success(), _copy_settlement(_settlements[settlement_id]), place_ids)


## O local (cópia). Local desconhecido: falha `PLACE_UNKNOWN`.
func peek_place(place_id: String) -> PlaceQuery:
	if not _places.has(place_id):
		return PlaceQuery.new(Result.failure(CODE_PLACE_UNKNOWN, "SettlementService.peek_place: o local '%s' não existe; esperado um dos %d locais carregados (%s)." % [place_id, _place_ids.size(), _describe_ids(_place_ids)]), null)
	return PlaceQuery.new(Result.success(), _copy_place(_places[place_id]))


## Os locais (cópias) do assentamento que têm o tipo, em ordem crescente de `id`. Tipo válido sem nenhum local NÃO é erro: lista vazia.
## Assentamento desconhecido: `SETTLEMENT_UNKNOWN`; tipo fora do vocabulário de Place.KINDS: `PLACE_KIND_INVALID`.
func peek_places_of_kind(settlement_id: String, kind: String) -> PlacesQuery:
	if not _settlements.has(settlement_id):
		return PlacesQuery.new(_unknown_settlement("peek_places_of_kind", settlement_id), [])
	if not Place.KINDS.has(kind):
		return PlacesQuery.new(Result.failure(CODE_PLACE_KIND_INVALID, "SettlementService.peek_places_of_kind: tipo '%s' fora do vocabulário; esperado um de: %s." % [kind, ", ".join(Place.KINDS)]), [])
	var found: Array[Place] = []
	for place_id: String in _place_ids_by_settlement[settlement_id]:
		var place: Place = _places[place_id]
		if place.kind == kind:
			found.append(_copy_place(place))
	return PlacesQuery.new(Result.success(), found)


## Problemas do conteúdo recebido (vazio se estiver certo). O carregador já impede todos eles; isto protege quem monta o serviço à mão.
func validate() -> Array[String]:
	var problems: Array[String] = []
	problems.assign(_problems)
	return problems


func debug_summary() -> Dictionary:
	return {"settlement_count": _settlements.size(), "place_count": _places.size(), "settlement_ids": _settlement_ids.duplicate(), "problems": validate()}


func _copy_settlement(settlement: Settlement) -> Settlement:
	return Settlement.new(settlement.id, settlement.name_key, settlement.position)


func _copy_place(place: Place) -> Place:
	return Place.new(place.id, place.settlement_id, place.kind, place.position, place.capacity)


func _unknown_settlement(caller: String, settlement_id: String) -> Result:
	return Result.failure(CODE_SETTLEMENT_UNKNOWN, "SettlementService.%s: o assentamento '%s' não existe; esperado um dos %d carregados (%s)." % [caller, settlement_id, _settlement_ids.size(), _describe_ids(_settlement_ids)])


## Os primeiros ids da lista, separados por vírgula; se houver mais, diz quantos faltam.
func _describe_ids(ids: Array[String]) -> String:
	if ids.size() <= MAX_LISTED_IDS:
		return ", ".join(ids)
	return "%s e mais %d" % [", ".join(ids.slice(0, MAX_LISTED_IDS)), ids.size() - MAX_LISTED_IDS]


## Resposta de `peek_settlement`: `settlement` (cópia) e `place_ids` (ids dos locais, em ordem crescente) só valem se `result.ok`.
class SettlementQuery:
	extends RefCounted

	var result: Result
	var settlement: Settlement
	var place_ids: Array[String]

	func _init(query_result: Result, found: Settlement, found_place_ids: Array[String]) -> void:
		result = query_result
		settlement = found
		place_ids = found_place_ids


## Resposta de `peek_place`: `place` (cópia) só vale se `result.ok`.
class PlaceQuery:
	extends RefCounted

	var result: Result
	var place: Place

	func _init(query_result: Result, found: Place) -> void:
		result = query_result
		place = found


## Resposta de `peek_places_of_kind`: `places` (cópias, em ordem crescente de `id`) só vale se `result.ok`; pode ser vazia.
class PlacesQuery:
	extends RefCounted

	var result: Result
	var places: Array[Place]

	func _init(query_result: Result, found: Array[Place]) -> void:
		result = query_result
		places = found
