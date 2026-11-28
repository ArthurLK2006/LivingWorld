extends GutTest
## LW-099a: o dado de apresentação da viagem visível (data/presentation/caravan_routes.json) e o leitor `CaravanRoutesReader`, sem janela. O dado REAL carrega, tem
## uma entrada por rota de data/world/routes.json e por bem de data/economy/goods.json (esta conferência é DO TESTE: o leitor, da apresentação, não conhece a
## simulação), e as pontas nos mercados de data/world/places.json dão uma polilinha entre 90% e 110% do `length_m` da rota. Todo arquivo inválido (um caso por
## regra) vira falha tratada com arquivo, item e campo e o dado devolvido fica vazio. TODOS os valores do dado (80 e 120 m, 1,2 m, reserva de 8, 25 graus,
## cores e formas) são [HIP] PROVISÓRIOS: Arthur os ajusta na janela, por isso o teste confere só faixas e propriedades, não os números.

const ROUTES_FILE: String = "res://data/world/routes.json"
const GOODS_FILE: String = "res://data/economy/goods.json"
const PLACES_FILE: String = "res://data/world/places.json"
const POPULATION_FILE: String = "res://data/population.json"
const LABEL: String = CaravanRoutesReader.DEFAULT_PATH
const VIEW_OK: String = '{"enter_m": 80, "exit_m": 120, "lateral_offset_m": 1.2, "pool_size": 8, "max_pitch_deg": 25}'
## LW-099g: `settlement_a_id` é obrigatório numa rota com `points_m` (é ele que dá o sentido dos pontos), então a rota r1 o declara; o resto do arquivo-base é o de antes.
const ROUTES_OK: String = '[{"route_id": "r1", "settlement_a_id": "sa", "points_m": [[10, 20], [30.5, 40]]}, {"route_id": "r2"}]'
const CARGO_OK: String = '[{"good_id": "g1", "color": "#C4A24C", "shape": "sack"}, {"good_id": "g2", "color": "#48535E", "shape": "box"}]'
const MINIMAL: String = '{"version": 1, "view": ' + VIEW_OK + ', "routes": ' + ROUTES_OK + ', "cargo": ' + CARGO_OK + "}"
## Distância mínima entre duas cores de carga (RGB de 0 a 1) e saturação máxima: [HIP], "sóbrias e distinguíveis".
const MIN_COLOR_GAP: float = 0.15
const MAX_SATURATION: float = 0.7
## [descrição, trecho do MINIMAL, texto que o substitui, item esperado na falha ("" = sem item), campo esperado ("" = sem campo].
const INVALID: Array = [
	["versão errada", '"version": 1', '"version": 2', "", "version"],
	["campo desconhecido na raiz", '"version": 1,', '"version": 1, "extra": 1,', "", "extra"],
	["bloco view ausente", '"view": ' + VIEW_OK + ", ", "", "", "view"],
	["campo desconhecido na vista", '"pool_size": 8,', '"pool_size": 8, "extra": 1,', "view", "extra"],
	["campo da vista ausente", ', "max_pitch_deg": 25', "", "view", "max_pitch_deg"],
	["pitch_spacing_m (campo removido na LW-099c) é desconhecido", '"pool_size": 8,', '"pool_size": 8, "pitch_spacing_m": 1.5,', "view", "pitch_spacing_m"],
	["enter_m negativo", '"enter_m": 80', '"enter_m": -5', "view", "enter_m"],
	["enter_m zero", '"enter_m": 80', '"enter_m": 0', "view", "enter_m"],
	["enter_m texto", '"enter_m": 80', '"enter_m": "80"', "view", "enter_m"],
	["enter_m acima do teto", '"enter_m": 80', '"enter_m": 99999', "view", "enter_m"],
	["exit_m não passa de enter_m", '"exit_m": 120', '"exit_m": 80', "view", "exit_m"],
	["exit_m zero", '"exit_m": 120', '"exit_m": 0', "view", "exit_m"],
	["pool_size fracionário", '"pool_size": 8', '"pool_size": 8.5', "view", "pool_size"],
	["pool_size zero", '"pool_size": 8', '"pool_size": 0', "view", "pool_size"],
	["max_pitch_deg vertical", '"max_pitch_deg": 25', '"max_pitch_deg": 90', "view", "max_pitch_deg"],
	["max_pitch_deg negativo", '"max_pitch_deg": 25', '"max_pitch_deg": -1', "view", "max_pitch_deg"],
	["lateral_offset_m negativo", '"lateral_offset_m": 1.2', '"lateral_offset_m": -1.2', "view", "lateral_offset_m"],
	["rotas vazias", '"routes": ' + ROUTES_OK, '"routes": []', "", "routes"],
	["route_id repetido", '{"route_id": "r2"}', '{"route_id": "r1"}', "r1", "route_id"],
	["route_id que não é texto", '{"route_id": "r2"}', '{"route_id": 7}', "routes[1]", "route_id"],
	["campo desconhecido na rota", '{"route_id": "r2"}', '{"route_id": "r2", "width": 3}', "r2", "width"],
	["points_m que não é lista", '"points_m": [[10, 20], [30.5, 40]]', '"points_m": 5', "r1", "points_m"],
	["ponto com três números", "[30.5, 40]", "[30.5, 40, 1]", "r1", "points_m"],
	["ponto com texto", "[10, 20]", '["10", 20]', "r1", "points_m"],
	["ponto acima do teto", "[10, 20]", "[10, 20000]", "r1", "points_m"],
	["cargas vazias", '"cargo": ' + CARGO_OK, '"cargo": []', "", "cargo"],
	["good_id repetido", '{"good_id": "g2"', '{"good_id": "g1"', "g1", "good_id"],
	["cor sem #", '"#48535E"', '"48535E"', "g2", "color"],
	["cor com alfa", '"#48535E"', '"#48535EFF"', "g2", "color"],
	["cor que não é hexadecimal", '"#48535E"', '"#48535G"', "g2", "color"],
	["cor que não é texto", '"#48535E"', "5", "g2", "color"],
	["forma desconhecida", '"shape": "box"', '"shape": "triangle"', "g2", "shape"],
	["forma ausente", ', "shape": "box"', "", "g2", "shape"],
	["campo desconhecido na carga", '"shape": "box"', '"shape": "box", "size": 2', "g2", "size"],
	["JSON malformado", MINIMAL, '{"version": 1, "view": [', "", ""],
	["raiz que não é objeto", MINIMAL, "[]", "", ""],
]

var _real: CaravanRoutesReader


func before_all() -> void:
	var loaded: CaravanRoutesReader.LoadResult = CaravanRoutesReader.from_file()
	assert_true(loaded.result.ok, loaded.result.message)
	_real = loaded.data


## As linhas de um JSON de dados do jogo (uma lista de objetos).
func _rows(path: String) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))  # Variant: fronteira com o JSON, conferido logo abaixo
	assert_eq(typeof(parsed), TYPE_ARRAY, path + " é uma lista")
	if typeof(parsed) == TYPE_ARRAY:
		for row: Variant in parsed:
			if typeof(row) == TYPE_DICTIONARY:
				rows.append(row)
	return rows


## `listed` tem exatamente os ids do JSON de dados do jogo: o mesmo tamanho (os ids de `listed` são únicos, o leitor garante) e nenhum faltando.
func _assert_exactly_the_ids_of(listed: PackedStringArray, path: String) -> void:
	var rows: Array[Dictionary] = _rows(path)
	assert_eq(listed.size(), rows.size(), "uma entrada por id de %s, nem mais nem menos" % path)
	for row: Dictionary in rows:
		assert_true(listed.has(str(row["id"])), "falta o id %s de %s" % [row["id"], path])


func test_the_real_file_loads_and_is_ready() -> void:
	assert_true(_real.is_ready(), "rotas, cargas e vista preenchidas")
	assert_gt(_real.exit_m, _real.enter_m, "a saída é mais longe que a entrada: histerese contra o piscar")


func test_the_real_routes_are_exactly_the_routes_of_the_world() -> void:
	_assert_exactly_the_ids_of(_real.route_ids(), ROUTES_FILE)


func test_the_real_cargo_is_exactly_the_goods_of_the_economy() -> void:
	_assert_exactly_the_ids_of(_real.cargo_ids(), GOODS_FILE)


func test_the_road_between_the_markets_is_within_ten_percent_of_the_leg_length() -> void:
	var markets: Dictionary[String, Vector2] = {}
	for place: Dictionary in _rows(PLACES_FILE):
		if str(place["kind"]) == "market":
			markets[str(place["settlement_id"])] = Vector2(float(place["x_cm"]), float(place["z_cm"])) / 100.0
	for route: Dictionary in _rows(ROUTES_FILE):
		var start: Vector2 = markets[str(route["settlement_a_id"])]
		var end: Vector2 = markets[str(route["settlement_b_id"])]
		# LW-099g: o caminho MOSTRADO (`leg_line`: com docas, de doca a doca; sem elas, de mercado a mercado, como antes) e não mais mercado, pontos, mercado.
		var road: CaravanPath = CaravanPath.new(_real.leg_line(str(route["id"]), str(route["settlement_a_id"]), str(route["settlement_b_id"]), start, end))
		assert_between(road.length_m() / float(route["length_m"]), 0.9, 1.1, "%s: a polilinha mostrada fica entre 90%% e 110%% do length_m" % route["id"])


func test_the_pool_has_room_for_every_merchant() -> void:
	var merchants: int = 0
	for row: Dictionary in _rows(POPULATION_FILE):
		if str(row["occupation_id"]) == "merchant":
			merchants += int(row["count"])
	assert_gt(merchants, 0, "há comerciantes na população")
	assert_gte(_real.pool_size, merchants, "a reserva comporta todos os comerciantes (sem teto menor que a população)")


func test_the_real_cargo_colors_are_sober_and_distinct() -> void:
	var ids: PackedStringArray = _real.cargo_ids()
	for index: int in ids.size():
		var color: Color = _real.cargo_color(ids[index])
		assert_lte(color.s, MAX_SATURATION, "%s: cor sóbria" % ids[index])
		for other: int in range(index + 1, ids.size()):
			var rival: Color = _real.cargo_color(ids[other])
			assert_gte(Vector3(color.r, color.g, color.b).distance_to(Vector3(rival.r, rival.g, rival.b)), MIN_COLOR_GAP, "%s e %s se distinguem" % [ids[index], ids[other]])


func test_a_valid_file_is_read_completely() -> void:
	var loaded: CaravanRoutesReader.LoadResult = CaravanRoutesReader.from_json(MINIMAL, LABEL)
	assert_true(loaded.result.ok, loaded.result.message)
	var data: CaravanRoutesReader = loaded.data
	assert_true(data.is_ready(), "pronto")
	assert_eq(data.route_ids(), PackedStringArray(["r1", "r2"]), "rotas, na ordem do arquivo")
	assert_eq(data.points_of("r1"), PackedVector2Array([Vector2(10, 20), Vector2(30.5, 40)]), "pontos de passagem de A para B, sem as pontas")
	assert_true(data.points_of("r2").is_empty() and data.points_of("nenhuma").is_empty(), "sem pontos: a reta")
	assert_eq(data.cargo_ids(), PackedStringArray(["g1", "g2"]), "cargas, na ordem do arquivo")
	assert_eq(data.cargo_color("g1"), Color.html("#C4A24C"), "cor lida")
	assert_eq(data.cargo_shape("g2"), "box", "forma lida")
	assert_eq([data.enter_m, data.exit_m, data.lateral_offset_m, data.pool_size, data.max_pitch_deg], [80.0, 120.0, 1.2, 8, 25.0], "vista lida")
	assert_true(data.cargo_color("faltou") == Color.MAGENTA and data.cargo_shape("faltou") == "", "bem sem entrada: a cor de 'faltou' e nenhuma forma")
	var copy: PackedVector2Array = data.points_of("r1")
	copy.append(Vector2.ZERO)
	assert_eq(data.points_of("r1").size(), 2, "points_of devolve cópia: o dado lido não muda por fora")


func test_every_invalid_file_is_a_handled_failure_with_file_item_and_field_and_an_empty_result() -> void:
	for row: Array in INVALID:
		var why: String = str(row[0])
		assert_true(MINIMAL.contains(str(row[1])), "o trecho a trocar existe no arquivo-base (" + why + ")")
		var loaded: CaravanRoutesReader.LoadResult = CaravanRoutesReader.from_json(MINIMAL.replace(str(row[1]), str(row[2])), LABEL)
		assert_false(loaded.result.ok, "recusado (" + why + ")")
		assert_eq(loaded.result.code, CaravanRoutesReader.CODE_INVALID, "código da falha (" + why + ")")
		assert_true(loaded.result.message.begins_with(LABEL), "cita o arquivo (" + why + "): " + loaded.result.message)
		assert_true(str(row[3]).is_empty() or loaded.result.message.contains("item '%s'" % row[3]), "cita o item (" + why + "): " + loaded.result.message)
		assert_true(str(row[4]).is_empty() or loaded.result.message.contains("campo '%s'" % row[4]), "cita o campo (" + why + "): " + loaded.result.message)
		assert_true(not loaded.data.is_ready() and loaded.data.route_ids().is_empty() and loaded.data.cargo_ids().is_empty(), "dado vazio, nunca pela metade (" + why + ")")


## Zero só vale para o deslocamento lateral e o limite de inclinação (desligam o efeito por dado); nos outros números a tabela acima recusa o zero.
func test_zero_turns_off_the_lateral_offset_and_the_pitch_limit() -> void:
	var loaded: CaravanRoutesReader.LoadResult = CaravanRoutesReader.from_json(MINIMAL.replace('"lateral_offset_m": 1.2', '"lateral_offset_m": 0').replace('"max_pitch_deg": 25', '"max_pitch_deg": 0'), LABEL)
	assert_true(loaded.result.ok, loaded.result.message)
	assert_eq([loaded.data.lateral_offset_m, loaded.data.max_pitch_deg, loaded.data.enter_m], [0.0, 0.0, 80.0], "os dois zeros são lidos; o resto da vista fica como estava")


## Só um literal como 1e999 estoura o real do JSON e vira infinito; o motor AVISA disso ao ler, um aviso por literal (o GUT conta o aviso como erro do motor: ele é declarado
## por CONTAGEM, sem depender do texto do aviso, que é do motor).
func test_a_number_too_big_for_a_real_is_refused_as_not_finite() -> void:
	var cases: Array = [['"enter_m": 80', '"enter_m": 1e999', "view", "enter_m"], ["[10, 20]", "[1e999, 20]", "r1", "points_m"]]
	for row: Array in cases:
		var loaded: CaravanRoutesReader.LoadResult = CaravanRoutesReader.from_json(MINIMAL.replace(str(row[0]), str(row[1])), LABEL)
		assert_false(loaded.result.ok, "recusado (%s)" % row[1])
		assert_true(loaded.result.message.contains("item '%s'" % row[2]) and loaded.result.message.contains("campo '%s'" % row[3]), loaded.result.message)
	assert_engine_error_count(cases.size(), "o motor avisa do estouro de cada número")


func test_a_missing_file_is_a_handled_failure() -> void:
	var loaded: CaravanRoutesReader.LoadResult = CaravanRoutesReader.from_file("res://data/presentation/nao_existe.json")
	assert_false(loaded.result.ok, "recusado")
	assert_true(loaded.result.message.contains("arquivo não encontrado") and not loaded.data.is_ready(), loaded.result.message)
