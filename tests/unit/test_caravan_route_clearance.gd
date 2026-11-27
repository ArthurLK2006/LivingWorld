extends GutTest
## LW-099g (opção B): a PROVA de FOLGA e COLISÃO do DADO REAL (data/presentation/caravan_routes.json), sem janela. Para cada rota e cada sentido o `u` anda de 0 a 1 em passos de 0,25 m andados pela `CaravanBodiesView` REAL (ponte roteirizada, mercados e terreno reais; lê-se a POSIÇÃO e o `rotation.y` do `CaravanView`, que é o que se vê, com o
## deslocamento lateral de 1,2 m, a rampa de 12 m e o giro limitado de hoje) e, a cada passo, o retângulo do carrinho (`RouteObstacles.cart_polygon`) tem de ficar a pelo menos FLOOR_M (0,3 m) de TODOS os obstáculos: as caixas dos locais e as peças das praças (`RouteObstacles`, provado contra a praça em
## `test_route_obstacles.gd`); nas poses de saída e de chegada também. A contagem de passos com folga menor que TARGET_M (0,5 m, o alvo) sai como número informativo, e a folga contra os adereços e arbustos das praças (que não entram no piso) também. Além disso: cada doca a no máximo 12 m do centro do mercado (a de C fica na borda sul da praça) e FORA da peça central;
## o comprimento do caminho MOSTRADO (doca à doca) entre 90% e 110% do `length_m` nos dois sentidos; os `settlement_a_id` e os povoados do dado batem com data/world. O teste de folga FALHA, com o local e o passo, se um ponto vai para dentro de uma casa (prova por mutante embutido). Sem as docas e os pontos no dado do jogo estes testes FALHAM (nunca pendentes nem verdes).

const WORLD_DIR: String = "res://data/world"
const PLACES_FILE: String = "res://data/world/places.json"
const ROUTES_FILE: String = "res://data/world/routes.json"
const TRADER: int = 100
const GROUND_M: float = 10.0
const CHUNK_M: float = 64.0
const STEP_M: float = 0.25
## O piso (nunca menos) e o alvo da folga entre o carrinho e qualquer obstáculo, em metros.
const FLOOR_M: float = 0.3
const TARGET_M: float = 0.5
## O deslocamento lateral da caravana (o do dado de apresentação).
const LATERAL_M: float = 1.2
## (doca) 6 -> 12 m: a doca de C fica na borda sul da praça, a 11,85 m do centro (A: 5,70 m; B: 6,00 m); a doca continua exigida FORA da peça central, a 0,3 m ou mais da borda dela.
const MAX_DOCK_FROM_CENTER_M: float = 12.0
## Tolerância de 1 mm na distância da doca ao centro (a conta é de ponto flutuante).
const DOCK_TOLERANCE_M: float = 0.001
const CENTER_PIECE_MARGIN_M: float = 0.3
const MIN_RATIO: float = 0.9
const MAX_RATIO: float = 1.1
const REPORTED_TOUCHES: int = 3
const MUTANT_ROUTE: String = "route_a_b"
const MUTANT_HOUSE: String = "a_home_05"
## O caso do limiar: um caminho reto, indo para oeste, que passa a 0,2 m da parede sul da fileira de casas de a_home_05 (o carrinho anda 1,2 m à direita do eixo, que indo para oeste é o norte).
const NEAR_GAP_M: float = 0.2
const NEAR_REACH_M: float = 20.0

var _terrain: TerrainData
var _places: Array[Place] = []
var _place_rows: Array = []
var _route_rows: Array = []
var _markets: Dictionary[String, Vector2] = {}
var _market_ids: Dictionary[String, String] = {}
var _obstacles: RouteObstacles
var _real: CaravanRoutesReader
var _bridge: ScriptedCaravanBridge
var _terrain_view: TerrainView
var _last_chunk: Vector2i = Vector2i(-1000, -1000)


func before_all() -> void:
	var terrain: TerrainLoader.LoadResult = TerrainLoader.load_dir(WORLD_DIR)
	assert_true(terrain.result.ok, terrain.result.message)
	_terrain = terrain.terrain
	var settlements: SettlementLoader.LoadResult = SettlementLoader.load_dir(WORLD_DIR, _terrain)
	assert_true(settlements.result.ok, settlements.result.message)
	_places = settlements.places
	_place_rows = _json_list(PLACES_FILE)
	_route_rows = _json_list(ROUTES_FILE)
	for row: Dictionary in _place_rows:
		if str(row["kind"]) == PlacePalette.KIND_MARKET:
			_markets[str(row["settlement_id"])] = Vector2(float(row["x_cm"]), float(row["z_cm"])) / RouteObstacles.CM_PER_M
			_market_ids[str(row["settlement_id"])] = str(row["id"])
	_obstacles = RouteObstacles.build(ScriptedCaravanBridge.new(null, _terrain, _places))
	var loaded: CaravanRoutesReader.LoadResult = CaravanRoutesReader.from_file()
	assert_true(loaded.result.ok, loaded.result.message)
	_real = loaded.data


func _json_list(path: String) -> Array:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))  # Variant: fronteira com o JSON, conferido abaixo
	assert_eq(typeof(parsed), TYPE_ARRAY, path + " é uma lista")
	var rows: Array = parsed
	return rows


## O dado real das 3 rotas TEM de ter doca e pontos de passagem: estes testes medem o dado real, e sem docas nem pontos (o arquivo de antes da opção B) eles não provariam nada, então FALHAM (antes ficavam pendentes e o dado sem docas deixava tudo verde).
func _is_data_missing() -> bool:
	var has_everything: bool = not _markets.is_empty()
	for settlement_id: String in _markets:
		has_everything = has_everything and _real.has_dock(settlement_id)
	for row: Dictionary in _route_rows:
		has_everything = has_everything and not _real.points_of(str(row["id"])).is_empty() and not _real.route_a_of(str(row["id"])).is_empty()
	assert_true(has_everything, "o dado real das 3 rotas tem de ter doca e pontos (data/presentation/caravan_routes.json): sem eles o teste de folga não mede nada")
	return not has_everything


func _start() -> void:
	_bridge = ScriptedCaravanBridge.new(null, _terrain, _places)
	_terrain_view = TerrainView.new()
	add_child_autofree(_terrain_view)
	_terrain_view.setup(_bridge)
	_terrain_view.set_process(false)
	_last_chunk = Vector2i(-1000, -1000)


## O terreno em volta do ponto (o chunk dele e os oito vizinhos), só quando o chunk muda: sem terreno desenhado a vista não põe pose.
func _draw_terrain_around(spot: Vector2) -> void:
	var center: Vector2i = Vector2i(floori(spot.x / CHUNK_M), floori(spot.y / CHUNK_M))
	if center == _last_chunk:
		return
	_last_chunk = center
	for dz: int in range(-1, 2):
		for dx: int in range(-1, 2):
			var coord: Vector2i = center + Vector2i(dx, dz)
			if not _terrain_view.has_chunk(coord):
				assert_true(_terrain_view.build_chunk(coord), "O chunk %s foi desenhado." % coord)


## Anda o trecho `from_id` -> `to_id` da rota, da doca à doca, em passos de STEP_M pela vista REAL (uma caravana nova: a primeira pose não tem limite de giro) e mede a folga a cada passo.
func _walk(routes: CaravanRoutesReader, route_id: String, from_id: String, to_id: String) -> Walk:
	var line: PackedVector2Array = routes.leg_line(route_id, from_id, to_id, _markets[from_id], _markets[to_id])
	var length_m: float = CaravanPath.new(line).length_m()
	var view: CaravanBodiesView = CaravanBodiesView.new()
	add_child_autofree(view)
	assert_true(view.setup(_bridge, _terrain_view, routes))
	var walk: Walk = Walk.new()
	var steps: int = ceili(length_m / STEP_M)
	var spot: Vector2 = line[0]
	for step: int in steps + 1:
		var walked_m: float = minf(float(step) * STEP_M, length_m)
		_draw_terrain_around(spot)
		_bridge.rows.assign([ScriptedCaravanBridge.row_of(TRADER, walked_m / length_m, route_id, from_id, to_id)])
		_terrain_view.set_focus(Vector3(spot.x, GROUND_M, spot.y))
		view.reconcile()
		var body: CaravanView = view.body_of(TRADER)
		if body == null or not body.visible:
			walk.hidden_steps += 1
			continue
		spot = Vector2(body.position.x, body.position.z)
		var polygon: PackedVector2Array = RouteObstacles.cart_polygon(spot, body.rotation.y)
		walk.note(step, walked_m, spot, body.rotation.y, _obstacles.nearest(polygon), _obstacles.nearest(polygon, true), steps)
	_bridge.rows.clear()
	view.reconcile()
	return walk


## Os trechos (rota, saída, chegada) das três rotas nos dois sentidos, na ordem de data/world/routes.json.
func _legs() -> Array:
	var legs: Array = []
	for row: Dictionary in _route_rows:
		legs.append([str(row["id"]), str(row["settlement_a_id"]), str(row["settlement_b_id"])])
		legs.append([str(row["id"]), str(row["settlement_b_id"]), str(row["settlement_a_id"])])
	return legs


func _tell(walk: Walk) -> String:
	var names: PackedStringArray = PackedStringArray()
	var ordered: Array = walk.touched.keys()
	ordered.sort_custom(func(a: String, b: String) -> bool: return walk.touched[a] < walk.touched[b])
	for item_id: String in ordered.slice(0, REPORTED_TOUCHES):
		names.append("%s (%.2f m)" % [item_id, walk.touched[item_id]])
	return "a menor folga é %.3f m com %s, no passo %d (%.2f m andados, em x=%.2f z=%.2f, giro %.1f graus); abaixo do piso de %.1f m: %s" % [walk.gap_m, walk.item_id, walk.step, walk.walked_m, walk.spot.x, walk.spot.y, rad_to_deg(walk.yaw), FLOOR_M, ", ".join(names)]


func test_every_route_in_both_directions_keeps_the_floor_clearance_from_dock_to_dock() -> void:
	if _is_data_missing():
		return
	_start()
	for leg: Array in _legs():
		var label: String = "%s de %s para %s" % [leg[0], leg[1], leg[2]]
		var walk: Walk = _walk(_real, str(leg[0]), str(leg[1]), str(leg[2]))
		assert_eq(walk.hidden_steps, 0, "%s: o corpo apareceu em todos os passos (a medida não olhou para o vazio)" % label)
		assert_gte(walk.gap_m, FLOOR_M, "%s: %s" % [label, _tell(walk)])
		assert_gte(walk.first_gap_m, FLOOR_M, "%s: na pose de SAÍDA na doca o carrinho inteiro está livre (folga %.3f m)" % [label, walk.first_gap_m])
		assert_gte(walk.last_gap_m, FLOOR_M, "%s: na pose de CHEGADA na doca também (folga %.3f m)" % [label, walk.last_gap_m])
		gut.p("%s: %d passos, folga mínima %.3f m (%s), %d passos abaixo do alvo de %.1f m, folga contra adereços e arbustos (informativa) %.3f m" % [label, walk.steps, walk.gap_m, walk.item_id, walk.tight_steps, TARGET_M, walk.minor_gap_m])


func test_each_dock_is_near_its_market_and_outside_the_center_piece() -> void:
	if _is_data_missing():
		return
	for settlement_id: String in _markets:
		assert_true(_real.has_dock(settlement_id), "%s: tem doca" % settlement_id)
		var dock: Vector2 = _real.dock_of(settlement_id)
		assert_lte(dock.distance_to(_markets[settlement_id]), MAX_DOCK_FROM_CENTER_M + DOCK_TOLERANCE_M, "%s: (doca) a doca fica a no máximo 12 m do centro do mercado (A 5,70 m, B 6,00 m, C 11,85 m)" % settlement_id)
		var center_name: String = PlazaVariants.CENTER_NAMES[PlazaVariants.for_market(_market_ids[settlement_id]).center]
		var center: RouteObstacles.Item = _obstacles.item("%s/%s" % [_market_ids[settlement_id], center_name])
		assert_not_null(center, "%s: a praça tem a peça central %s" % [settlement_id, center_name])
		if center != null:
			assert_gte(RouteObstacles.point_gap(center.hull, dock), CENTER_PIECE_MARGIN_M, "%s: a doca fica FORA da peça central (%s), a pelo menos 0,3 m da borda dela" % [settlement_id, center_name])


## A regra de dado da LW-099 (90% a 110% do `length_m`) vale para o caminho MOSTRADO, da doca à doca, e não mais para a reta entre os mercados.
func test_the_shown_path_is_within_ten_percent_of_the_leg_length_in_both_directions() -> void:
	if _is_data_missing():
		return
	for leg: Array in _legs():
		var line: PackedVector2Array = _real.leg_line(str(leg[0]), str(leg[1]), str(leg[2]), _markets[str(leg[1])], _markets[str(leg[2])])
		var length_m: float = 0.0
		for row: Dictionary in _route_rows:
			if str(row["id"]) == str(leg[0]):
				length_m = float(row["length_m"])
		assert_between(CaravanPath.new(line).length_m() / length_m, MIN_RATIO, MAX_RATIO, "%s de %s para %s: o caminho mostrado fica entre 90%% e 110%% do length_m" % [leg[0], leg[1], leg[2]])


func test_the_data_matches_the_world_routes_and_settlements() -> void:
	if _is_data_missing():
		return
	for row: Dictionary in _route_rows:
		var route_id: String = str(row["id"])
		assert_true(_real.route_ids().has(route_id), "%s: está no dado de apresentação" % route_id)
		assert_eq(_real.route_a_of(route_id), str(row["settlement_a_id"]), "%s: o `settlement_a_id` do dado é o de data/world/routes.json (é ele que dá o sentido dos pontos)" % route_id)
	for settlement_id: String in _real.dock_ids():
		assert_true(_markets.has(settlement_id), "%s: a doca é de um povoado que tem mercado em places.json" % settlement_id)


## O mutante embutido: o MESMO teste de folga, com um ponto de passagem posto no centro de uma casa, tem de reprovar e dizer qual é a casa. (Funciona com o dado de hoje ou com o novo: o ponto é injetado na rota A-B.)
func test_the_clearance_check_catches_a_point_moved_into_a_house() -> void:
	var house: Vector2 = Vector2.ZERO
	for row: Dictionary in _place_rows:
		if str(row["id"]) == MUTANT_HOUSE:
			house = Vector2(float(row["x_cm"]), float(row["z_cm"])) / RouteObstacles.CM_PER_M
	assert_ne(house, Vector2.ZERO, "Premissa: a casa %s existe em places.json." % MUTANT_HOUSE)
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CaravanRoutesReader.DEFAULT_PATH))  # Variant: fronteira com o JSON, conferido abaixo
	var root: Dictionary = parsed
	var a_id: String = ""
	for row: Dictionary in _route_rows:
		if str(row["id"]) == MUTANT_ROUTE:
			a_id = str(row["settlement_a_id"])
	for row: Dictionary in root["routes"]:
		if str(row["route_id"]) == MUTANT_ROUTE:
			row["settlement_a_id"] = a_id
			row["points_m"] = [[house.x, house.y]]
	var loaded: CaravanRoutesReader.LoadResult = CaravanRoutesReader.from_json(JSON.stringify(root), "dado com um ponto dentro de %s" % MUTANT_HOUSE)
	assert_true(loaded.result.ok, loaded.result.message)
	_start()
	var walk: Walk = _walk(loaded.data, MUTANT_ROUTE, a_id, _other_end(MUTANT_ROUTE, a_id))
	assert_lt(walk.gap_m, 0.0, "O carrinho atravessa a casa: folga negativa. " + _tell(walk))
	assert_true(walk.touched.has(MUTANT_HOUSE) and float(walk.touched[MUTANT_HOUSE]) < 0.0, "E o teste diz QUAL é a casa: %s. %s" % [MUTANT_HOUSE, _tell(walk)])
	assert_lt(walk.gap_m, FLOOR_M, "Abaixo do piso: o teste de folga reprovaria este dado.")


## O LIMIAR: um caminho que passa a 0,2 m da parede de uma casa (sem encostar) fica ABAIXO do piso de 0,3 m e NÃO é colisão (folga positiva). Com o piso trocado por 0 este teste reprova (o piso é o que separa 0,2 m de 0,5 m).
func test_a_path_that_passes_0_2_m_from_a_house_is_below_the_floor_but_is_not_a_collision() -> void:
	var house: Vector2 = Vector2.ZERO
	for row: Dictionary in _place_rows:
		if str(row["id"]) == MUTANT_HOUSE:
			house = Vector2(float(row["x_cm"]), float(row["z_cm"])) / RouteObstacles.CM_PER_M
	var south_wall_z: float = house.y + PlacePalette.SIZES[PlacePalette.KIND_HOME].z * 0.5
	var axis_z: float = south_wall_z + NEAR_GAP_M + LATERAL_M + RouteObstacles.CART_HALF_WIDTH_M
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CaravanRoutesReader.DEFAULT_PATH))  # Variant: fronteira com o JSON, conferido abaixo
	var root: Dictionary = parsed
	var a_id: String = ""
	for row: Dictionary in _route_rows:
		if str(row["id"]) == MUTANT_ROUTE:
			a_id = str(row["settlement_a_id"])
	for row: Dictionary in root["routes"]:
		if str(row["route_id"]) == MUTANT_ROUTE:
			row["settlement_a_id"] = a_id
			row["points_m"] = [[house.x + NEAR_REACH_M, axis_z], [house.x - NEAR_REACH_M, axis_z]]
	var loaded: CaravanRoutesReader.LoadResult = CaravanRoutesReader.from_json(JSON.stringify(root), "dado com um caminho a 0,2 m de %s" % MUTANT_HOUSE)
	assert_true(loaded.result.ok, loaded.result.message)
	_start()
	var walk: Walk = _walk(loaded.data, MUTANT_ROUTE, a_id, _other_end(MUTANT_ROUTE, a_id))
	assert_true(walk.touched.has(MUTANT_HOUSE), "O caminho a 0,2 m de %s fica abaixo do piso de %.1f m e o teste diz qual é a casa. %s" % [MUTANT_HOUSE, FLOOR_M, _tell(walk)])
	assert_between(float(walk.touched.get(MUTANT_HOUSE, -1.0)), NEAR_GAP_M - 0.05, NEAR_GAP_M + 0.05, "E a folga medida é a construída (0,2 m), positiva: não é colisão.")


func _other_end(route_id: String, settlement_id: String) -> String:
	for row: Dictionary in _route_rows:
		if str(row["id"]) == route_id:
			return str(row["settlement_b_id"]) if str(row["settlement_a_id"]) == settlement_id else str(row["settlement_a_id"])
	return ""


## O que se mediu ao andar um trecho: a menor folga (e onde), os obstáculos que ficaram abaixo do piso (com a menor folga de cada um), a folga na saída e na chegada e quantos passos ficaram abaixo do alvo.
class Walk:
	extends RefCounted

	var gap_m: float = INF
	var item_id: String = ""
	var step: int = 0
	var walked_m: float = 0.0
	var spot: Vector2 = Vector2.ZERO
	var yaw: float = 0.0
	var first_gap_m: float = INF
	var last_gap_m: float = INF
	var minor_gap_m: float = INF
	var tight_steps: int = 0
	var steps: int = 0
	var hidden_steps: int = 0
	var touched: Dictionary[String, float] = {}


	func note(at_step: int, at_walked_m: float, at_spot: Vector2, at_yaw: float, main: RouteObstacles.Hit, minor: RouteObstacles.Hit, last_step: int) -> void:
		steps += 1
		if at_step == 0:
			first_gap_m = main.gap_m
		if at_step == last_step:
			last_gap_m = main.gap_m
		minor_gap_m = minf(minor_gap_m, minor.gap_m)
		if main.gap_m < TARGET_M:
			tight_steps += 1
		if main.gap_m < FLOOR_M and main.item != null:
			touched[main.item.id] = minf(touched.get(main.item.id, INF), main.gap_m)
		if main.gap_m < gap_m:
			gap_m = main.gap_m
			item_id = main.item.id if main.item != null else ""
			step = at_step
			walked_m = at_walked_m
			spot = at_spot
			yaw = at_yaw
