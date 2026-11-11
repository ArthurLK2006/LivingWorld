class_name RouteService
extends RefCounted
## Consultas sobre as rotas entre assentamentos (LW-097b; contrato em docs/modules/world.md, seção "Extensão da Fase 3"). Conteúdo somente
## leitura e SEM estado: não é módulo registrado no `World` (o estado aberta/fechada e o módulo são da LW-097c), então não entra no save nem
## no state_hash. Toda consulta devolve CÓPIAS e, quando falha, uma falha tratada com código e mensagem que diz o que falhou, onde e o
## esperado. As listas saem sempre em ordem crescente de `id`, nunca pela ordem de um Dictionary (regra do MODELO.md).
## Caminho mais curto = menor soma de `length_m`; empate desfeito pela menor sequência de ids de rota, na ordem da viagem. `difficulty` e
## `risk` não pesam na escolha (quem viaja os pesa, economia).

const CODE_ROUTE_UNKNOWN: String = "ROUTE_UNKNOWN"
const CODE_NO_PATH: String = "ROUTE_NO_PATH"
## Quantos ids uma mensagem de erro lista antes de resumir o resto.
const MAX_LISTED_IDS: int = 8

var _routes: Dictionary[String, Route] = {}
var _route_ids: Array[String] = []
var _settlement_ids: Array[String] = []
## Ids das rotas que tocam cada assentamento, em ordem crescente.
var _route_ids_by_settlement: Dictionary[String, Array] = {}
## Inconsistências do conteúdo recebido (id repetido, rota para assentamento inexistente).
var _problems: Array[String] = []


## O serviço guarda os objetos recebidos como conteúdo somente leitura: quem os entrega (o carregador) não deve alterá-los depois.
func _init(routes: Array[Route], settlements: Array[Settlement]) -> void:
	for settlement: Settlement in settlements:
		_route_ids_by_settlement[settlement.id] = []
	for route: Route in routes:
		if _routes.has(route.id):
			_problems.append("rota '%s' repetida." % route.id)
			continue
		if not _route_ids_by_settlement.has(route.settlement_a_id) or not _route_ids_by_settlement.has(route.settlement_b_id):
			_problems.append("rota '%s' cita um assentamento que não existe ('%s' ou '%s')." % [route.id, route.settlement_a_id, route.settlement_b_id])
			continue
		_routes[route.id] = route
		_route_ids_by_settlement[route.settlement_a_id].append(route.id)
		_route_ids_by_settlement[route.settlement_b_id].append(route.id)
	_route_ids.assign(_routes.keys())
	_route_ids.sort()
	_settlement_ids.assign(_route_ids_by_settlement.keys())
	_settlement_ids.sort()
	for settlement_id: String in _settlement_ids:
		_route_ids_by_settlement[settlement_id].sort()


## A rota (cópia). Rota desconhecida: falha `ROUTE_UNKNOWN`.
func peek_route(route_id: String) -> RouteQuery:
	if not _routes.has(route_id):
		return RouteQuery.new(Result.failure(CODE_ROUTE_UNKNOWN, "RouteService.peek_route: a rota '%s' não existe; esperado uma das %d carregadas (%s)." % [route_id, _route_ids.size(), _describe_ids(_route_ids)]), null)
	return RouteQuery.new(Result.success(), _copy_route(_routes[route_id]))


## As rotas (cópias) que tocam o assentamento, em ordem crescente de `id`. Assentamento desconhecido: `SETTLEMENT_UNKNOWN`.
func peek_routes_of(settlement_id: String) -> RoutesQuery:
	if not _route_ids_by_settlement.has(settlement_id):
		return RoutesQuery.new(_unknown_settlement("peek_routes_of", settlement_id), [])
	var found: Array[Route] = []
	for route_id: String in _route_ids_by_settlement[settlement_id]:
		found.append(_copy_route(_routes[route_id]))
	return RoutesQuery.new(Result.success(), found)


## O caminho mais curto entre dois assentamentos: os ids das rotas na ordem da viagem e o comprimento total. Do assentamento para ele mesmo
## o caminho é vazio, de comprimento 0. Assentamento desconhecido: `SETTLEMENT_UNKNOWN`; sem caminho: `ROUTE_NO_PATH`.
func peek_path(from_settlement_id: String, to_settlement_id: String) -> PathQuery:
	for settlement_id: String in [from_settlement_id, to_settlement_id]:
		if not _route_ids_by_settlement.has(settlement_id):
			return PathQuery.new(_unknown_settlement("peek_path", settlement_id), [], 0)
	var distance: Dictionary[String, int] = {from_settlement_id: 0}
	var trip: Dictionary[String, Array] = {from_settlement_id: []}
	var done: Dictionary[String, bool] = {}
	while true:
		var current: String = _closest_pending(distance, done)
		if current.is_empty() or current == to_settlement_id:
			break
		done[current] = true
		for route_id: String in _route_ids_by_settlement[current]:
			var route: Route = _routes[route_id]
			var next_id: String = route.other_end(current)
			var next_distance: int = distance[current] + route.length_m
			var next_trip: Array = trip[current].duplicate()
			next_trip.append(route_id)
			if not distance.has(next_id) or next_distance < distance[next_id] or (next_distance == distance[next_id] and _is_before(next_trip, trip[next_id])):
				distance[next_id] = next_distance
				trip[next_id] = next_trip
	if not trip.has(to_settlement_id):
		return PathQuery.new(Result.failure(CODE_NO_PATH, "RouteService.peek_path: não há caminho de '%s' até '%s' pelas rotas carregadas." % [from_settlement_id, to_settlement_id]), [], 0)
	var route_ids: Array[String] = []
	route_ids.assign(trip[to_settlement_id])
	return PathQuery.new(Result.success(), route_ids, distance[to_settlement_id])


## Problemas do conteúdo recebido (vazio se estiver certo). O carregador já impede todos eles; isto protege quem monta o serviço à mão.
func validate() -> Array[String]:
	var problems: Array[String] = []
	problems.assign(_problems)
	return problems


func debug_summary() -> Dictionary:
	return {"route_count": _routes.size(), "route_ids": _route_ids.duplicate(), "problems": validate()}


## O assentamento ainda não fechado com a menor distância (empate: o menor id); vazio se não sobrou nenhum alcançado.
func _closest_pending(distance: Dictionary[String, int], done: Dictionary[String, bool]) -> String:
	var best: String = ""
	for settlement_id: String in _settlement_ids:
		if distance.has(settlement_id) and not done.has(settlement_id) and (best.is_empty() or distance[settlement_id] < distance[best]):
			best = settlement_id
	return best


## A sequência `first` vem antes de `second` na ordem de ids (comparação por posição).
func _is_before(first: Array, second: Array) -> bool:
	for index: int in mini(first.size(), second.size()):
		if first[index] != second[index]:
			return str(first[index]) < str(second[index])
	return first.size() < second.size()


func _copy_route(route: Route) -> Route:
	return Route.new(route.id, route.settlement_a_id, route.settlement_b_id, route.length_m, route.difficulty, route.risk)


func _unknown_settlement(caller: String, settlement_id: String) -> Result:
	return Result.failure(SettlementService.CODE_SETTLEMENT_UNKNOWN, "RouteService.%s: o assentamento '%s' não existe; esperado um dos %d carregados (%s)." % [caller, settlement_id, _settlement_ids.size(), _describe_ids(_settlement_ids)])


## Os primeiros ids da lista, separados por vírgula; se houver mais, diz quantos faltam.
func _describe_ids(ids: Array[String]) -> String:
	if ids.size() <= MAX_LISTED_IDS:
		return ", ".join(ids)
	return "%s e mais %d" % [", ".join(ids.slice(0, MAX_LISTED_IDS)), ids.size() - MAX_LISTED_IDS]


## Resposta de `peek_route`: `route` (cópia) só vale se `result.ok`.
class RouteQuery:
	extends RefCounted

	var result: Result
	var route: Route

	func _init(query_result: Result, found: Route) -> void:
		result = query_result
		route = found


## Resposta de `peek_routes_of`: `routes` (cópias, em ordem crescente de `id`) só vale se `result.ok`.
class RoutesQuery:
	extends RefCounted

	var result: Result
	var routes: Array[Route]

	func _init(query_result: Result, found: Array[Route]) -> void:
		result = query_result
		routes = found


## Resposta de `peek_path`: `route_ids` (na ordem da viagem) e `total_length_m` só valem se `result.ok`.
class PathQuery:
	extends RefCounted

	var result: Result
	var route_ids: Array[String]
	var total_length_m: int

	func _init(query_result: Result, found_route_ids: Array[String], total_m: int) -> void:
		result = query_result
		route_ids = found_route_ids
		total_length_m = total_m
