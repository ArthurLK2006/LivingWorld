extends GutTest
## LW-099g (opção B: pontos de passagem e docas): o que o `CaravanRoutesReader` ganhou, sem janela e com dado SINTÉTICO (o dado do jogo é conferido em `test_caravan_route_clearance.gd`). A seção `docks` (opcional: uma doca [x, z] por povoado), o campo `settlement_a_id` da rota
## (opcional, mas obrigatório com `points_m`: é ele que dá o sentido dos pontos), e `leg_line`, a polilinha COMPLETA do trecho no sentido da marcha (ponta de saída, pontos na ordem certa, ponta de chegada). Cada regra de erro vira falha tratada com arquivo, item e campo e o dado devolvido
## fica vazio, nunca pela metade; o arquivo de antes (sem docas nem `settlement_a_id`) continua válido.

const LABEL: String = "caravan_routes_docks_test.json"
const VIEW_OK: String = '{"enter_m": 80, "exit_m": 120, "lateral_offset_m": 1.2, "pool_size": 8, "max_pitch_deg": 25}'
const CARGO_OK: String = '[{"good_id": "g1", "color": "#C4A24C", "shape": "sack"}]'
const ROUTES_OK: String = '[{"route_id": "r1", "settlement_a_id": "sa", "points_m": [[10, 20], [30.5, 40], [60, 15]]}, {"route_id": "r2"}]'
const DOCKS_OK: String = '[{"settlement_id": "sa", "point_m": [5, 6]}, {"settlement_id": "sb", "point_m": [100.5, 200]}]'
const BASE: String = '{"version": 1, "view": ' + VIEW_OK + ', "routes": ' + ROUTES_OK + ', "cargo": ' + CARGO_OK + ', "docks": ' + DOCKS_OK + "}"
const OLD_FORMAT: String = '{"version": 1, "view": ' + VIEW_OK + ', "routes": [{"route_id": "r1"}], "cargo": ' + CARGO_OK + "}"
const MARKET_A: Vector2 = Vector2(1000.0, 1000.0)
const MARKET_B: Vector2 = Vector2(2000.0, 2000.0)
const DOCK_A: Vector2 = Vector2(5.0, 6.0)
const DOCK_B: Vector2 = Vector2(100.5, 200.0)
const POINTS: PackedVector2Array = [Vector2(10, 20), Vector2(30.5, 40), Vector2(60, 15)]
## [descrição, trecho do BASE, texto que o substitui, item esperado na falha ("" = sem item), campo esperado ("" = sem campo)].
const INVALID: Array = [
	["doca repetida", '{"settlement_id": "sb"', '{"settlement_id": "sa"', "sa", "settlement_id"],
	["doca sem settlement_id", '{"settlement_id": "sb", "point_m": [100.5, 200]}', '{"point_m": [100.5, 200]}', "docks[1]", "settlement_id"],
	["settlement_id que não é texto", '"settlement_id": "sb"', '"settlement_id": 7', "docks[1]", "settlement_id"],
	["doca sem point_m", ', "point_m": [100.5, 200]', "", "sb", "point_m"],
	["point_m que não é lista", '"point_m": [100.5, 200]', '"point_m": 5', "sb", "point_m"],
	["point_m com três números", "[100.5, 200]", "[100.5, 200, 1]", "sb", "point_m"],
	["point_m com texto", "[100.5, 200]", '["100.5", 200]', "sb", "point_m"],
	["point_m acima do teto", "[100.5, 200]", "[100.5, 20000]", "sb", "point_m"],
	["campo desconhecido na doca", '"point_m": [5, 6]', '"point_m": [5, 6], "height": 2', "sa", "height"],
	["docks vazio", '"docks": ' + DOCKS_OK, '"docks": []', "", "docks"],
	["docks que não é lista", '"docks": ' + DOCKS_OK, '"docks": 5', "", "docks"],
	["points_m sem settlement_a_id", '"settlement_a_id": "sa", ', "", "r1", "settlement_a_id"],
	["settlement_a_id que não é texto", '"settlement_a_id": "sa"', '"settlement_a_id": 7', "r1", "settlement_a_id"],
	["settlement_a_id vazio", '"settlement_a_id": "sa"', '"settlement_a_id": ""', "r1", "settlement_a_id"],
	["campo desconhecido na rota", '{"route_id": "r2"}', '{"route_id": "r2", "settlement_b_id": "sb"}', "r2", "settlement_b_id"],
]


func _read(content: String) -> CaravanRoutesReader:
	var loaded: CaravanRoutesReader.LoadResult = CaravanRoutesReader.from_json(content, LABEL)
	assert_true(loaded.result.ok, loaded.result.message)
	return loaded.data


## O mesmo arquivo-base sem a seção de docas.
func _without_docks() -> CaravanRoutesReader:
	return _read(BASE.replace(', "docks": ' + DOCKS_OK, ""))


func test_docks_and_the_route_origin_are_read() -> void:
	var data: CaravanRoutesReader = _read(BASE)
	assert_eq(data.dock_ids(), PackedStringArray(["sa", "sb"]), "docas, na ordem do arquivo")
	assert_true(data.has_dock("sa") and data.has_dock("sb") and not data.has_dock("sc"), "quem tem doca")
	assert_eq([data.dock_of("sa"), data.dock_of("sb"), data.dock_of("sc")], [DOCK_A, DOCK_B, Vector2.ZERO], "a doca lida; sem doca, a origem (confira `has_dock`)")
	assert_eq([data.route_a_of("r1"), data.route_a_of("r2"), data.route_a_of("nenhuma")], ["sa", "", ""], "o povoado `a` da rota que o declara; as outras, texto vazio")
	assert_eq(data.points_of("r1"), POINTS, "`points_of` segue como era: de `a` para o outro, sem as pontas")


func test_the_file_of_before_is_still_valid_and_has_no_docks() -> void:
	var data: CaravanRoutesReader = _read(OLD_FORMAT)
	assert_true(data.is_ready() and data.dock_ids().is_empty() and data.route_a_of("r1").is_empty(), "sem `docks` nem `settlement_a_id`: pronto, sem doca e sem `a`")
	assert_eq(data.leg_line("r1", "sa", "sb", MARKET_A, MARKET_B), PackedVector2Array([MARKET_A, MARKET_B]), "e a estrada é a reta entre os mercados")


func test_a_route_may_declare_its_origin_without_points() -> void:
	var data: CaravanRoutesReader = _read(BASE.replace('{"route_id": "r2"}', '{"route_id": "r2", "settlement_a_id": "sb"}'))
	assert_eq(data.route_a_of("r2"), "sb", "declarado sem pontos: vale")
	assert_eq(data.leg_line("r2", "sb", "sa", MARKET_B, MARKET_A), PackedVector2Array([DOCK_B, DOCK_A]), "sem pontos a polilinha é só as duas docas")


func test_every_invalid_file_is_a_handled_failure_with_file_item_and_field_and_an_empty_result() -> void:
	for row: Array in INVALID:
		var why: String = str(row[0])
		assert_true(BASE.contains(str(row[1])), "o trecho a trocar existe no arquivo-base (" + why + ")")
		var loaded: CaravanRoutesReader.LoadResult = CaravanRoutesReader.from_json(BASE.replace(str(row[1]), str(row[2])), LABEL)
		assert_false(loaded.result.ok, "recusado (" + why + ")")
		assert_eq(loaded.result.code, CaravanRoutesReader.CODE_INVALID, "código da falha (" + why + ")")
		assert_true(loaded.result.message.begins_with(LABEL), "cita o arquivo (" + why + "): " + loaded.result.message)
		assert_true(str(row[3]).is_empty() or loaded.result.message.contains("item '%s'" % row[3]), "cita o item (" + why + "): " + loaded.result.message)
		assert_true(str(row[4]).is_empty() or loaded.result.message.contains("campo '%s'" % row[4]), "cita o campo (" + why + "): " + loaded.result.message)
		var data: CaravanRoutesReader = loaded.data
		assert_true(not data.is_ready() and data.route_ids().is_empty() and data.dock_ids().is_empty() and data.route_a_of("r1").is_empty(), "dado vazio, nunca pela metade (" + why + ")")


## Só um literal como 1e999 estoura o real do JSON e vira infinito; o motor AVISA disso ao ler (um aviso por literal; o GUT o conta como erro do motor, então ele é declarado por CONTAGEM).
func test_a_dock_number_too_big_for_a_real_is_refused_as_not_finite() -> void:
	var loaded: CaravanRoutesReader.LoadResult = CaravanRoutesReader.from_json(BASE.replace("[100.5, 200]", "[1e999, 200]"), LABEL)
	assert_false(loaded.result.ok, "recusado")
	assert_true(loaded.result.message.contains("item 'sb'") and loaded.result.message.contains("campo 'point_m'"), loaded.result.message)
	assert_engine_error_count(1, "o motor avisa do estouro do número")


func test_leg_line_runs_from_dock_through_the_points_in_order_to_dock() -> void:
	var data: CaravanRoutesReader = _read(BASE)
	var forward: PackedVector2Array = PackedVector2Array([DOCK_A])
	forward.append_array(POINTS)
	forward.append(DOCK_B)
	assert_eq(data.leg_line("r1", "sa", "sb", MARKET_A, MARKET_B), forward, "de `a` para o outro: doca de saída, os pontos NA ORDEM DO DADO, doca de chegada (os mercados não entram)")
	var backward: PackedVector2Array = PackedVector2Array([DOCK_B, POINTS[2], POINTS[1], POINTS[0], DOCK_A])
	assert_eq(data.leg_line("r1", "sb", "sa", MARKET_B, MARKET_A), backward, "no sentido contrário: os mesmos pontos INVERTIDOS, e as docas trocam de lugar")
	assert_eq(data.points_of("r1"), POINTS, "o dado guardado não foi invertido pela consulta (`points_of` segue de `a` para o outro)")


func test_leg_line_uses_the_market_where_a_settlement_has_no_dock() -> void:
	var no_docks: CaravanRoutesReader = _without_docks()
	assert_eq(no_docks.leg_line("r1", "sa", "sb", MARKET_A, MARKET_B), PackedVector2Array([MARKET_A, POINTS[0], POINTS[1], POINTS[2], MARKET_B]), "sem nenhuma doca as pontas são os mercados")
	assert_eq(no_docks.leg_line("r1", "sb", "sa", MARKET_B, MARKET_A), PackedVector2Array([MARKET_B, POINTS[2], POINTS[1], POINTS[0], MARKET_A]), "e na volta também, com os pontos invertidos")
	var only_a: CaravanRoutesReader = _read(BASE.replace(', {"settlement_id": "sb", "point_m": [100.5, 200]}', ""))
	assert_eq(only_a.leg_line("r1", "sa", "sb", MARKET_A, MARKET_B), PackedVector2Array([DOCK_A, POINTS[0], POINTS[1], POINTS[2], MARKET_B]), "só `a` tem doca: sai da doca e chega ao mercado")
	assert_eq(only_a.leg_line("r1", "sb", "sa", MARKET_B, MARKET_A), PackedVector2Array([MARKET_B, POINTS[2], POINTS[1], POINTS[0], DOCK_A]), "e na volta sai do mercado e chega à doca")


func test_leg_line_of_a_route_without_points_or_unknown_is_the_straight_line_between_the_ends() -> void:
	var data: CaravanRoutesReader = _read(BASE)
	assert_eq(data.leg_line("r2", "sa", "sb", MARKET_A, MARKET_B), PackedVector2Array([DOCK_A, DOCK_B]), "rota sem pontos: só as docas")
	assert_eq(data.leg_line("r2", "sb", "sa", MARKET_B, MARKET_A), PackedVector2Array([DOCK_B, DOCK_A]), "nos dois sentidos")
	assert_eq(data.leg_line("nenhuma", "sa", "sb", MARKET_A, MARKET_B), PackedVector2Array([DOCK_A, DOCK_B]), "rota que o dado não tem: a reta (como `points_of`, que devolve vazio; quem confere os ids é o teste)")
	assert_eq(data.leg_line("nenhuma", "sx", "sy", MARKET_A, MARKET_B), PackedVector2Array([MARKET_A, MARKET_B]), "povoados sem doca nem rota: os mercados")


func test_a_departure_that_is_not_settlement_a_walks_the_points_backwards() -> void:
	var data: CaravanRoutesReader = _read(BASE)
	assert_eq(data.leg_line("r1", "qualquer", "sa", MARKET_B, MARKET_A), PackedVector2Array([MARKET_B, POINTS[2], POINTS[1], POINTS[0], DOCK_A]), "a regra é literal: só quem parte do `settlement_a_id` da rota anda os pontos na ordem do dado")


func test_leg_line_is_pure_and_returns_a_copy() -> void:
	var data: CaravanRoutesReader = _read(BASE)
	var first: PackedVector2Array = data.leg_line("r1", "sb", "sa", MARKET_B, MARKET_A)
	var second: PackedVector2Array = data.leg_line("r1", "sb", "sa", MARKET_B, MARKET_A)
	assert_eq(first, second, "a mesma entrada dá a mesma saída")
	first[1] = Vector2(-1.0, -1.0)
	first.append(Vector2.ZERO)
	assert_eq(data.leg_line("r1", "sb", "sa", MARKET_B, MARKET_A), second, "mexer no resultado não muda o dado (cópia, não referência)")
	assert_eq(data.leg_line("r1", "sa", "sb", MARKET_A, MARKET_B).size(), POINTS.size() + 2, "nem o sentido de ida")
