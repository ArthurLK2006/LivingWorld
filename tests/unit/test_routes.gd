extends GutTest
## LW-097b: o grafo de rotas do `world` (docs/modules/world.md, "Extensão da Fase 3"), sem janela e SEM estado: o carregador (cada arquivo
## inválido falha apontando arquivo, item e campo) e as consultas `peek_route`, `peek_routes_of` e `peek_path` (cópias, ordem crescente de
## `id`, falhas tratadas, caminho mais curto com desempate pelo menor `id`). Os dados reais estão em tests/unit/test_routes_data.gd.
## Os valores esperados estão escritos à mão a partir do contrato.

const MISSING_DIR: String = "res://tests/fixtures/world/pasta_que_nao_existe"
## Três assentamentos em ângulo reto: sa-sb a 300 m, sa-sc a 400 m e sb-sc a 500 m em linha reta.
const ROUTE_AB: String = '{"id": "r_ab", "settlement_a_id": "sa", "settlement_b_id": "sb", "length_m": 320, "difficulty": 10, "risk": 5}'
const ROUTE_AC: String = '{"id": "r_ac", "settlement_a_id": "sa", "settlement_b_id": "sc", "length_m": 420, "difficulty": 20, "risk": 15}'
const ROUTE_BC: String = '{"id": "r_bc", "settlement_a_id": "sb", "settlement_b_id": "sc", "length_m": 520, "difficulty": 30, "risk": 25}'

var _settlements: Array[Settlement] = []
var _temp_dirs: Array[DirAccess] = []


func before_each() -> void:
	_settlements = [Settlement.new("sa", "k.a", Vector3(0.0, 0.0, 0.0)), Settlement.new("sb", "k.b", Vector3(300.0, 0.0, 0.0)), Settlement.new("sc", "k.c", Vector3(0.0, 0.0, 400.0))]


func after_each() -> void:
	for dir: DirAccess in _temp_dirs:
		for file_name: String in dir.get_files():
			dir.remove(file_name)
		DirAccess.remove_absolute(dir.get_current_dir())
	_temp_dirs.clear()


func _load(text: String) -> RouteLoader.LoadResult:
	var dir: DirAccess = DirAccess.create_temp("lw097b")
	_temp_dirs.append(dir)
	var file: FileAccess = FileAccess.open(dir.get_current_dir().path_join(RouteLoader.DEFAULT_ROUTES_FILE), FileAccess.WRITE)
	file.store_string(text)
	file.close()
	return RouteLoader.load_dir(dir.get_current_dir(), _settlements)


func _assert_invalid(text: String, expected_parts: Array[String]) -> void:
	var loaded: RouteLoader.LoadResult = _load(text)
	assert_false(loaded.result.ok, "Arquivo inválido deveria falhar: " + text)
	assert_eq(loaded.result.code, RouteLoader.CODE_INVALID)
	assert_eq(loaded.routes.size(), 0, "Falha não devolve rota.")
	for part: String in expected_parts:
		assert_string_contains(loaded.result.message, part)


func _route(id: String, settlement_a_id: String, settlement_b_id: String, length_m: int) -> Route:
	return Route.new(id, settlement_a_id, settlement_b_id, length_m, 0, 0)


## Quatro assentamentos em losango, para os empates: sa-sb e sb-sd (r_1 e r_2) contra sa-sc e sc-sd (r_3 e r_0), todas de 100 m.
func _diamond_routes() -> Array[Route]:
	var routes: Array[Route] = [_route("r_1", "sa", "sb", 100), _route("r_2", "sb", "sd", 100), _route("r_3", "sa", "sc", 100), _route("r_0", "sc", "sd", 100)]
	return routes


func _diamond_service(routes: Array[Route]) -> RouteService:
	var all: Array[Settlement] = _settlements.duplicate()
	all.append(Settlement.new("sd", "k.d", Vector3(400.0, 0.0, 400.0)))
	return RouteService.new(routes, all)


# ---------------------------------------------------------------- arquivo inválido

func test_a_valid_file_loads_in_file_order_with_every_field() -> void:
	var loaded: RouteLoader.LoadResult = _load("[%s, %s, %s]" % [ROUTE_BC, ROUTE_AB, ROUTE_AC])
	assert_true(loaded.result.ok, loaded.result.message)
	assert_eq([loaded.routes[0].id, loaded.routes[1].id, loaded.routes[2].id], ["r_bc", "r_ab", "r_ac"], "A ordem do arquivo é mantida.")
	assert_eq([loaded.routes[1].settlement_a_id, loaded.routes[1].settlement_b_id, loaded.routes[1].length_m, loaded.routes[1].difficulty, loaded.routes[1].risk], ["sa", "sb", 320, 10, 5])


func test_a_missing_or_an_unknown_field_is_reported_with_file_item_and_field() -> void:
	_assert_invalid("[%s, %s, %s]" % [ROUTE_AB.replace(', "risk": 5', ""), ROUTE_AC, ROUTE_BC], ["routes.json", "r_ab", "risk", "campo obrigatório ausente"])
	_assert_invalid("[%s, %s, %s]" % [ROUTE_AB.replace('"risk": 5', '"risk": 5, "capacity": 3'), ROUTE_AC, ROUTE_BC], ["routes.json", "r_ab", "capacity", "campo desconhecido"])


func test_a_repeated_id_is_reported() -> void:
	_assert_invalid("[%s, %s, %s, %s]" % [ROUTE_AB, ROUTE_AC, ROUTE_BC, ROUTE_AB], ["routes.json", "r_ab", "id", "duplicado"])


func test_a_wrong_type_and_values_outside_the_ranges_are_reported_and_the_edges_are_valid() -> void:
	_assert_invalid("[%s, %s, %s]" % [ROUTE_AB.replace('"length_m": 320', '"length_m": "320"'), ROUTE_AC, ROUTE_BC], ["r_ab", "length_m"])
	_assert_invalid("[%s, %s, %s]" % [ROUTE_AB.replace('"length_m": 320', '"length_m": 0'), ROUTE_AC, ROUTE_BC], ["r_ab", "length_m"])
	_assert_invalid("[%s, %s, %s]" % [ROUTE_AB, ROUTE_AC.replace('"difficulty": 20', '"difficulty": 101'), ROUTE_BC], ["r_ac", "difficulty"])
	_assert_invalid("[%s, %s, %s]" % [ROUTE_AB, ROUTE_AC, ROUTE_BC.replace('"risk": 25', '"risk": -1')], ["r_bc", "risk"])
	var edges: String = "[%s, %s, %s]" % [ROUTE_AB.replace('"difficulty": 10', '"difficulty": 0').replace('"risk": 5', '"risk": 100'), ROUTE_AC.replace('"length_m": 420', '"length_m": 100000'), ROUTE_BC]
	assert_true(_load(edges).result.ok, "Os limites das faixas valem (0 e 100; 100.000 m).")


func test_a_broken_reference_is_reported_with_file_item_and_field() -> void:
	_assert_invalid("[%s, %s, %s]" % [ROUTE_AB.replace('"sb"', '"nowhere"'), ROUTE_AC, ROUTE_BC], ["routes.json", "r_ab", "settlement_b_id", "nowhere"])


func test_a_route_from_a_settlement_to_itself_is_reported() -> void:
	_assert_invalid("[%s, %s, %s, %s]" % [ROUTE_AB, ROUTE_AC, ROUTE_BC, ROUTE_AB.replace("r_ab", "r_loop").replace('"settlement_b_id": "sb"', '"settlement_b_id": "sa"')], ["r_loop", "settlement_b_id", "ele mesmo"])


func test_the_same_link_in_both_directions_is_reported_as_a_repeated_pair() -> void:
	var backwards: String = ROUTE_AB.replace("r_ab", "r_ba").replace('"settlement_a_id": "sa", "settlement_b_id": "sb"', '"settlement_a_id": "sb", "settlement_b_id": "sa"')
	_assert_invalid("[%s, %s, %s, %s]" % [ROUTE_AB, ROUTE_AC, ROUTE_BC, backwards], ["r_ba", "settlement_b_id", "r_ab"])


func test_a_route_shorter_than_the_straight_line_is_reported_and_exactly_the_line_is_valid() -> void:
	_assert_invalid("[%s, %s, %s]" % [ROUTE_AB.replace('"length_m": 320', '"length_m": 299'), ROUTE_AC, ROUTE_BC], ["r_ab", "length_m", "linha reta"])
	assert_true(_load("[%s, %s, %s]" % [ROUTE_AB.replace('"length_m": 320', '"length_m": 300'), ROUTE_AC, ROUTE_BC]).result.ok, "Exatamente a reta vale.")


func test_a_settlement_without_routes_and_a_disconnected_graph_are_reported() -> void:
	_assert_invalid("[%s]" % ROUTE_AB, ["sc", "nenhuma rota"])
	_settlements.append(Settlement.new("sd", "k.d", Vector3(900.0, 0.0, 900.0)))
	_settlements.append(Settlement.new("se", "k.e", Vector3(900.0, 0.0, 1300.0)))
	var far_pair: String = '{"id": "r_de", "settlement_a_id": "sd", "settlement_b_id": "se", "length_m": 450, "difficulty": 0, "risk": 0}'
	_assert_invalid("[%s, %s, %s, %s]" % [ROUTE_AB, ROUTE_AC, ROUTE_BC, far_pair], ["não conectado", "sd"])


func test_malformed_json_and_missing_files_are_reported_without_crashing() -> void:
	_assert_invalid("[{", ["routes.json"])
	var missing: RouteLoader.LoadResult = RouteLoader.load_dir(MISSING_DIR, _settlements)
	assert_false(missing.result.ok)
	assert_eq(missing.result.code, RouteLoader.CODE_INVALID)


# ---------------------------------------------------------------- consultas

func test_peek_route_returns_a_copy_and_an_unknown_route_is_a_handled_error() -> void:
	var service: RouteService = RouteService.new(_load("[%s, %s, %s]" % [ROUTE_AB, ROUTE_AC, ROUTE_BC]).routes, _settlements)
	var query: RouteService.RouteQuery = service.peek_route("r_ac")
	assert_true(query.result.ok, query.result.message)
	assert_eq([query.route.settlement_a_id, query.route.settlement_b_id, query.route.length_m, query.route.difficulty, query.route.risk], ["sa", "sc", 420, 20, 15])
	query.route.length_m = 1
	assert_eq(service.peek_route("r_ac").route.length_m, 420, "Mexer na cópia não altera o conteúdo.")
	var unknown: RouteService.RouteQuery = service.peek_route("r_zz")
	assert_eq(unknown.result.code, RouteService.CODE_ROUTE_UNKNOWN)
	assert_string_contains(unknown.result.message, "r_zz")
	assert_string_contains(unknown.result.message, "r_ab")


func test_peek_routes_of_is_in_ascending_order_and_an_unknown_settlement_is_a_handled_error() -> void:
	var service: RouteService = RouteService.new(_load("[%s, %s, %s]" % [ROUTE_BC, ROUTE_AC, ROUTE_AB]).routes, _settlements)
	var of_a: RouteService.RoutesQuery = service.peek_routes_of("sa")
	assert_true(of_a.result.ok, of_a.result.message)
	assert_eq([of_a.routes[0].id, of_a.routes[1].id], ["r_ab", "r_ac"], "As rotas saem por id, não pela ordem do arquivo.")
	assert_eq(service.peek_routes_of("sc").routes.size(), 2)
	assert_eq(service.peek_routes_of("nowhere").result.code, SettlementService.CODE_SETTLEMENT_UNKNOWN)


func test_the_shortest_path_is_the_lowest_total_length() -> void:
	var service: RouteService = RouteService.new(_load("[%s, %s, %s]" % [ROUTE_AB, ROUTE_AC, ROUTE_BC]).routes, _settlements)
	var direct: RouteService.PathQuery = service.peek_path("sa", "sb")
	assert_true(direct.result.ok, direct.result.message)
	assert_eq([direct.route_ids, direct.total_length_m], [["r_ab"] as Array[String], 320])
	var around: Array[Route] = [_route("long", "sa", "sb", 900), _route("s1", "sa", "sc", 300), _route("s2", "sc", "sb", 300)]
	var detour: RouteService.PathQuery = RouteService.new(around, _settlements).peek_path("sb", "sa")
	assert_eq([detour.route_ids, detour.total_length_m], [["s2", "s1"] as Array[String], 600], "Dois trechos curtos vencem uma rota longa, na ordem da viagem.")


func test_a_tie_is_broken_by_the_lowest_route_ids_in_the_order_of_the_trip() -> void:
	var service: RouteService = _diamond_service(_diamond_routes())
	assert_eq(service.peek_path("sa", "sd").route_ids, ["r_1", "r_2"] as Array[String], "Empate: vale a sequência de ids menor (r_1 antes de r_3).")
	assert_eq(service.peek_path("sd", "sa").route_ids, ["r_0", "r_3"] as Array[String], "Na volta o primeiro id é o r_0 (menor que o r_2).")
	assert_eq(service.peek_path("sa", "sd").total_length_m, 200)


func test_the_answers_do_not_depend_on_the_order_the_routes_were_given() -> void:
	var reversed: Array[Route] = _diamond_routes()
	reversed.reverse()
	var first: RouteService = _diamond_service(_diamond_routes())
	var second: RouteService = _diamond_service(reversed)
	for pair: Array in [["sa", "sd"], ["sd", "sa"], ["sb", "sc"], ["sa", "sb"]]:
		assert_eq(first.peek_path(pair[0], pair[1]).route_ids, second.peek_path(pair[0], pair[1]).route_ids)
	assert_eq(first.peek_routes_of("sa").routes[0].id, second.peek_routes_of("sa").routes[0].id)


func test_the_path_to_the_same_settlement_is_empty_a_missing_link_has_no_path_and_unknown_ids_are_errors() -> void:
	var service: RouteService = RouteService.new([_route("r_ab", "sa", "sb", 320)], _settlements)
	var same: RouteService.PathQuery = service.peek_path("sa", "sa")
	assert_true(same.result.ok)
	assert_eq([same.route_ids.size(), same.total_length_m], [0, 0])
	var cut_off: RouteService.PathQuery = service.peek_path("sa", "sc")
	assert_eq(cut_off.result.code, RouteService.CODE_NO_PATH)
	assert_string_contains(cut_off.result.message, "sc")
	assert_eq(service.peek_path("sa", "nowhere").result.code, SettlementService.CODE_SETTLEMENT_UNKNOWN)
	assert_eq(service.peek_path("nowhere", "sa").result.code, SettlementService.CODE_SETTLEMENT_UNKNOWN)


func test_a_service_made_by_hand_with_inconsistent_content_reports_problems_and_survives() -> void:
	var routes: Array[Route] = [_route("r_ab", "sa", "sb", 320), _route("r_ab", "sa", "sc", 420), _route("r_zz", "sa", "nowhere", 100)]
	var service: RouteService = RouteService.new(routes, _settlements)
	assert_eq(service.validate().size(), 2, "Um id repetido e uma rota para assentamento inexistente.")
	assert_eq(service.peek_route("r_ab").route.settlement_b_id, "sb", "Em caso de repetição vale a primeira.")
	assert_eq(service.peek_route("r_zz").result.code, RouteService.CODE_ROUTE_UNKNOWN)
	assert_eq(RouteService.new(_load("[%s, %s, %s]" % [ROUTE_AB, ROUTE_AC, ROUTE_BC]).routes, _settlements).validate().size(), 0)
