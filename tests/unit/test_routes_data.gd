extends GutTest
## LW-097b: os dados REAIS do grafo de rotas (data/world/routes.json) sobre os três povoados de teste, sem janela. Os comprimentos,
## a dificuldade e o risco são [HIP] e NÃO são conferidos por número: confere-se o desenho (o triângulo A-B, A-C e B-C, DEC-158) e o que ele
## permite (caminho direto mais curto que o desvio pelo terceiro povoado, para a LW-097c fechar uma rota e o caminho mudar).
## A validação de arquivo inválido e as consultas estão em tests/unit/test_routes.gd.

const BLOCKOUT_DIR: String = "res://data/world"
const SETTLEMENT_IDS: Array[String] = ["test_settlement_a", "test_settlement_b", "test_settlement_c"]

var _loaded: RouteLoader.LoadResult
var _service: RouteService


func before_all() -> void:
	var terrain_loaded: TerrainLoader.LoadResult = TerrainLoader.load_dir(BLOCKOUT_DIR)
	assert_true(terrain_loaded.result.ok, terrain_loaded.result.message)
	var settlements_loaded: SettlementLoader.LoadResult = SettlementLoader.load_dir(BLOCKOUT_DIR, terrain_loaded.terrain)
	assert_true(settlements_loaded.result.ok, settlements_loaded.result.message)
	_loaded = RouteLoader.load_dir(BLOCKOUT_DIR, settlements_loaded.settlements)
	assert_true(_loaded.result.ok, _loaded.result.message)
	_service = RouteService.new(_loaded.routes, settlements_loaded.settlements)


func _length_of_direct(first: String, second: String) -> int:
	var path: RouteService.PathQuery = _service.peek_path(first, second)
	assert_true(path.result.ok, path.result.message)
	assert_eq(path.route_ids.size(), 1, "O caminho entre '%s' e '%s' é a rota direta." % [first, second])
	return path.total_length_m


func test_the_real_file_is_the_triangle_between_the_three_test_settlements() -> void:
	assert_eq(_loaded.routes.size(), 3)
	var links: Array[String] = []
	for route: Route in _loaded.routes:
		var ends: Array[String] = [route.settlement_a_id, route.settlement_b_id]
		ends.sort()
		links.append("%s|%s" % ends)
	links.sort()
	assert_eq(links, ["test_settlement_a|test_settlement_b", "test_settlement_a|test_settlement_c", "test_settlement_b|test_settlement_c"] as Array[String])
	for settlement_id: String in SETTLEMENT_IDS:
		assert_eq(_service.peek_routes_of(settlement_id).routes.size(), 2, "'%s' tem duas rotas." % settlement_id)
	assert_eq(_service.validate().size(), 0, "O conteúdo real não tem problema.")


func test_every_pair_is_reached_by_its_direct_route_and_the_detour_is_longer() -> void:
	for pair: Array in [[SETTLEMENT_IDS[0], SETTLEMENT_IDS[1], SETTLEMENT_IDS[2]], [SETTLEMENT_IDS[0], SETTLEMENT_IDS[2], SETTLEMENT_IDS[1]], [SETTLEMENT_IDS[1], SETTLEMENT_IDS[2], SETTLEMENT_IDS[0]]]:
		var direct: int = _length_of_direct(pair[0], pair[1])
		var detour: int = _length_of_direct(pair[0], pair[2]) + _length_of_direct(pair[2], pair[1])
		assert_lt(direct, detour, "Entre '%s' e '%s' o caminho direto é mais curto que o desvio por '%s'." % pair)
		assert_eq(_service.peek_path(pair[1], pair[0]).total_length_m, direct, "A rota não tem direção: ida e volta medem o mesmo.")


func test_the_real_routes_have_rating_inside_the_ranges_and_a_unique_id_each() -> void:
	var ids: Dictionary[String, bool] = {}
	for route: Route in _loaded.routes:
		assert_false(ids.has(route.id), "O id '%s' é único." % route.id)
		ids[route.id] = true
		assert_between(route.difficulty, 0, Route.MAX_RATING)
		assert_between(route.risk, 0, Route.MAX_RATING)
		assert_between(route.length_m, Route.MIN_LENGTH_M, Route.MAX_LENGTH_M)
