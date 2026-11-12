class_name WorldModule
extends SimModule
## Módulo `world` (LW-097c; contrato em docs/modules/world.md, "Extensão da Fase 3"): o PRIMEIRO estado que o `world` possui, o estado de cada
## rota (`open` ou `closed`, DEC-159). Terreno, assentamentos, locais e rotas continuam conteúdo sem estado salvo; aqui só mora a lista das rotas
## FECHADAS (todas nascem abertas). Registrado no `World`, o módulo ganha uma entrada no save e no `state_hash`, mesmo vazia (marco 3 de hash, DEC-175).
## `request_close_route` e `request_open_route` só existem em build de desenvolvimento (DEC-140; `is_development_build` vem da fronteira do app, a
## simulação nunca lê `OS`); fora dele, `WORLD_DEV_ONLY` e nada muda. Pedir o estado que a rota já tem é sucesso SEM efeito e SEM evento; cada mudança
## real publica um `RouteStateChanged`. As consultas devolvem cópias; `peek_path` só passa pelas rotas abertas. Sem `RouteService`, nenhuma rota existe.
## LW-118d: o módulo também responde sobre a ESTRUTURA de províncias, adjacência e culturas (`peek_province`, `peek_provinces`, `peek_province_of`, `peek_adjacent_provinces`, `peek_culture`
## e `peek_culture_of`; DEC-203, DEC-207; DEC-213 PROPOSTA). É conteúdo: não entra no save nem no `state_hash`; quem controla a província é a `politics`. Sem os serviços, nenhuma existe.

const CODE_DEV_ONLY: String = "WORLD_DEV_ONLY"
const CODE_INVALID_SAVE: String = "WORLD_INVALID_SAVE"
const STATE_OPEN: String = "open"
const STATE_CLOSED: String = "closed"
const KEY_CLOSED_ROUTES: String = "closed_routes"

var _routes: RouteService
var _provinces: ProvinceService
var _cultures: CultureService
var _is_development_build: bool
var _events: EventBus
## Rotas fechadas (id como chave); o que não está aqui está aberto.
var _closed: Dictionary[String, bool] = {}


## `routes`: o grafo já lido e validado (RouteLoader); sem ele o módulo nasce sem rotas. `provinces` e `cultures` (LW-118d): a estrutura já lida e conferida (WorldSetup); sem elas o módulo nasce sem
## províncias e sem culturas.
func _init(routes: RouteService = null, is_development_build: bool = false, provinces: ProvinceService = null, cultures: CultureService = null) -> void:
	_routes = routes if routes != null else RouteService.new([], [])
	_provinces = provinces if provinces != null else ProvinceService.new([], [])
	_cultures = cultures if cultures != null else CultureService.new([])
	_is_development_build = is_development_build


func setup(ctx: SimContext) -> void:
	_events = ctx.events


func on_new_game(_world_seed: int) -> void:
	_closed.clear()


## A rota (cópia) e o estado dela. Rota desconhecida: falha `ROUTE_UNKNOWN`.
func peek_route(route_id: String) -> RouteStateQuery:
	var found: RouteService.RouteQuery = _routes.peek_route(route_id)
	return RouteStateQuery.new(found.result, found.route, _state_of(route_id))


## As rotas (cópias) que tocam o assentamento, em ordem crescente de `id`; o estado de cada uma vem de `peek_route`.
func peek_routes_of(settlement_id: String) -> RouteService.RoutesQuery:
	return _routes.peek_routes_of(settlement_id)


## O caminho mais curto pelas rotas ABERTAS (`ROUTE_NO_PATH` se as fechadas cortam todos os caminhos).
func peek_path(from_settlement_id: String, to_settlement_id: String) -> RouteService.PathQuery:
	return _routes.peek_path(from_settlement_id, to_settlement_id, _closed)


## A província (cópia) e os ids dos povoados dela, em ordem crescente. Província desconhecida: falha `PROVINCE_UNKNOWN`.
func peek_province(province_id: String) -> ProvinceService.ProvinceQuery:
	return _provinces.peek_province(province_id)


## Todas as províncias (cópias), em ordem crescente de `id`.
func peek_provinces() -> ProvinceService.ProvincesQuery:
	return _provinces.peek_provinces()


## A província do povoado. Povoado desconhecido: `SETTLEMENT_UNKNOWN`; povoado sem província que exista: `PROVINCE_UNKNOWN`.
func peek_province_of(settlement_id: String) -> ProvinceService.ProvinceQuery:
	return _provinces.peek_province_of(settlement_id)


## As províncias vizinhas, em ordem crescente de `id`. Província desconhecida: `PROVINCE_UNKNOWN`.
func peek_adjacent_provinces(province_id: String) -> ProvinceService.ProvincesQuery:
	return _provinces.peek_adjacent_provinces(province_id)


## A cultura (cópia). Cultura desconhecida: falha `CULTURE_UNKNOWN`.
func peek_culture(culture_id: String) -> CultureService.CultureQuery:
	return _cultures.peek_culture(culture_id)


## A cultura do povoado (a do NPC é a do povoado de moradia dele). Povoado desconhecido: `SETTLEMENT_UNKNOWN`; sem cultura que exista: `CULTURE_UNKNOWN`.
func peek_culture_of(settlement_id: String) -> CultureService.CultureQuery:
	return _cultures.peek_culture_of(settlement_id)


## Comando de DESENVOLVIMENTO: fecha a rota. Fora de build de desenvolvimento, `WORLD_DEV_ONLY`; rota desconhecida, `ROUTE_UNKNOWN`.
func request_close_route(route_id: String) -> Result:
	return _request_state("request_close_route", route_id, STATE_CLOSED)


## Comando de DESENVOLVIMENTO: reabre a rota (mesmas falhas de `request_close_route`).
func request_open_route(route_id: String) -> Result:
	return _request_state("request_open_route", route_id, STATE_OPEN)


## Só as rotas fechadas, em ordem crescente (nada, se todas estão abertas: o jogo sem fechamento salva o mesmo que o padrão).
func serialize() -> Dictionary:
	if _closed.is_empty():
		return {}
	return {KEY_CLOSED_ROUTES: _closed_ids()}


## Confere tudo antes de mudar algo: lista de ids de rotas que existem, sem repetição. Sem a chave, todas abertas.
func on_load(data: Dictionary) -> Result:
	var restored: Dictionary[String, bool] = {}
	if data.has(KEY_CLOSED_ROUTES):
		var raw: Variant = data[KEY_CLOSED_ROUTES]  # Variant: vem cru do save (JSON), o tipo é conferido abaixo.
		if typeof(raw) != TYPE_ARRAY:
			return _invalid_save("o campo '%s' não é uma lista (veio %s)" % [KEY_CLOSED_ROUTES, type_string(typeof(raw))])
		for entry: Variant in raw:
			if typeof(entry) != TYPE_STRING:
				return _invalid_save("o campo '%s' tem um item que não é texto (veio %s)" % [KEY_CLOSED_ROUTES, str(entry)])
			if not _routes.peek_route(str(entry)).result.ok:
				return _invalid_save("o campo '%s' cita a rota '%s', que não existe nos dados" % [KEY_CLOSED_ROUTES, str(entry)])
			if restored.has(str(entry)):
				return _invalid_save("o campo '%s' repete a rota '%s'" % [KEY_CLOSED_ROUTES, str(entry)])
			restored[str(entry)] = true
	_closed = restored
	return Result.success()


## Rota fechada que não existe nos dados e as inconsistências da estrutura de províncias e culturas (vazio se estiver tudo certo).
func validate() -> Array[String]:
	var problems: Array[String] = []
	for route_id: String in _closed_ids():
		if not _routes.peek_route(route_id).result.ok:
			problems.append("rota fechada '%s' não existe nos dados." % route_id)
	problems.append_array(_provinces.validate())
	problems.append_array(_cultures.validate())
	return problems


func debug_summary() -> Dictionary:
	return {"route_count": _routes.debug_summary()["route_count"], "closed_routes": _closed_ids(), "development_build": _is_development_build}


func _request_state(caller: String, route_id: String, new_state: String) -> Result:
	if not _is_development_build:
		return Result.failure(CODE_DEV_ONLY, "WorldModule.%s: comando só existe em build de desenvolvimento (is_development_build)." % caller)
	var found: RouteService.RouteQuery = _routes.peek_route(route_id)
	if not found.result.ok:
		return found.result
	if _state_of(route_id) == new_state:
		return Result.success()
	if new_state == STATE_CLOSED:
		_closed[route_id] = true
	else:
		_closed.erase(route_id)
	_events.publish(RouteStateChanged.new(route_id, new_state))
	return Result.success()


func _state_of(route_id: String) -> String:
	return STATE_CLOSED if _closed.has(route_id) else STATE_OPEN


func _closed_ids() -> Array[String]:
	var ids: Array[String] = []
	ids.assign(_closed.keys())
	ids.sort()
	return ids


func _invalid_save(reason: String) -> Result:
	return Result.failure(CODE_INVALID_SAVE, "WorldModule.on_load: %s; esperado uma lista de ids de rotas que existem, sem repetição." % reason)


## Resposta de `peek_route`: `route` (cópia) e `state` (`open` ou `closed`) só valem se `result.ok`.
class RouteStateQuery:
	extends RefCounted

	var result: Result
	var route: Route
	var state: String

	func _init(query_result: Result, found: Route, route_state: String) -> void:
		result = query_result
		route = found
		state = route_state
