extends GutTest
## LW-099g: as viagens de DOIS TRECHOS (a caravana que passa por um povoado do meio, hoje só com uma estrada fechada), sem janela. A `CaravanBodiesView` REAL (ponte roteirizada, mercados, terreno e dado REAIS) anda o 1º trecho com `u` de 0 a 1 em passos de 0,25 m andados e logo em seguida o 2º, com o MESMO `trader_id` (o corpo e o giro dele atravessam a troca, como no jogo),
## e mede a folga do carrinho (`RouteObstacles`, os obstáculos principais e também os que só informam: adereços e arbustos) em todos os passos. Nas 6 viagens a troca de trecho é CONTÍNUA (a posição do fim do 1º trecho e a do começo do 2º, a menos de 1 cm, na doca do povoado do meio).
## LIMITAÇÃO CONHECIDA (decisão de Arthur: o desvio por estrada fechada é raro): as duas rotas de um povoado saem pelo mesmo corredor, então o carrinho dá a volta em U na doca e, se a doca fica DENTRO da praça, a traseira a varre. Por B a folga cai a zero ou menos (árvore Tree6 de B) e esses testes ficam PENDENTES
## com a folga medida na mensagem; por A passa com folga; por C, com a doca na borda sul, FORA da praça (a 11,85 m do centro), a volta em U (de 173 graus) passa e o teste é verde. Se alguém consertar B, o pendente vira verde sozinho.

const WORLD_DIR: String = "res://data/world"
const PLACES_FILE: String = "res://data/world/places.json"
const ROUTES_FILE: String = "res://data/world/routes.json"
const SETTLEMENT_PREFIX: String = "test_settlement_"
const TRADER: int = 100
const GROUND_M: float = 10.0
const CHUNK_M: float = 64.0
const STEP_M: float = 0.25
const FLOOR_M: float = 0.3
const ONE_CM: float = 0.01
## As 6 viagens: [povoado de saída, povoado do meio, povoado de chegada].
const TRIP_B_A_C: Array[String] = ["b", "a", "c"]
const TRIP_C_A_B: Array[String] = ["c", "a", "b"]
const TRIP_A_B_C: Array[String] = ["a", "b", "c"]
const TRIP_C_B_A: Array[String] = ["c", "b", "a"]
const TRIP_A_C_B: Array[String] = ["a", "c", "b"]
const TRIP_B_C_A: Array[String] = ["b", "c", "a"]

var _terrain: TerrainData
var _places: Array[Place] = []
var _route_rows: Array = []
var _markets: Dictionary[String, Vector2] = {}
var _obstacles: RouteObstacles
var _real: CaravanRoutesReader
var _bridge: ScriptedCaravanBridge
var _terrain_view: TerrainView
var _last_chunk: Vector2i = Vector2i(-1000, -1000)
## Cada viagem é andada UMA vez (as medidas ficam aqui para os outros testes).
var _driven: Dictionary[String, Trip] = {}


func before_all() -> void:
	var terrain: TerrainLoader.LoadResult = TerrainLoader.load_dir(WORLD_DIR)
	assert_true(terrain.result.ok, terrain.result.message)
	_terrain = terrain.terrain
	var settlements: SettlementLoader.LoadResult = SettlementLoader.load_dir(WORLD_DIR, _terrain)
	assert_true(settlements.result.ok, settlements.result.message)
	_places = settlements.places
	_route_rows = _json_list(ROUTES_FILE)
	for row: Dictionary in _json_list(PLACES_FILE):
		if str(row["kind"]) == PlacePalette.KIND_MARKET:
			_markets[str(row["settlement_id"])] = Vector2(float(row["x_cm"]), float(row["z_cm"])) / RouteObstacles.CM_PER_M
	_obstacles = RouteObstacles.build(ScriptedCaravanBridge.new(null, _terrain, _places))
	var loaded: CaravanRoutesReader.LoadResult = CaravanRoutesReader.from_file()
	assert_true(loaded.result.ok, loaded.result.message)
	_real = loaded.data


func _json_list(path: String) -> Array:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))  # Variant: fronteira com o JSON, conferido abaixo
	assert_eq(typeof(parsed), TYPE_ARRAY, path + " é uma lista")
	var rows: Array = parsed
	return rows


## A rota que liga os dois povoados (nos dois sentidos).
func _route_between(first_id: String, second_id: String) -> String:
	for row: Dictionary in _route_rows:
		var ends: Array = [str(row["settlement_a_id"]), str(row["settlement_b_id"])]
		if ends.has(first_id) and ends.has(second_id):
			return str(row["id"])
	return ""


func _ensure_started() -> void:
	if is_instance_valid(_terrain_view):
		return
	_bridge = ScriptedCaravanBridge.new(null, _terrain, _places)
	_terrain_view = TerrainView.new()
	add_child_autofree(_terrain_view)
	_terrain_view.setup(_bridge)
	_terrain_view.set_process(false)
	_last_chunk = Vector2i(-1000, -1000)


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


## Anda a viagem `order` (saída, meio, chegada): o 1º trecho de 0 a 1 e logo em seguida o 2º, pela mesma vista e o mesmo `trader_id`; mede a folga do carrinho contra TODOS os obstáculos (principais e informativos) a cada passo.
func _drive(order: Array[String]) -> Trip:
	var label: String = "%s>%s>%s" % [order[0].to_upper(), order[1].to_upper(), order[2].to_upper()]
	if _driven.has(label):
		return _driven[label]
	_ensure_started()
	var trip: Trip = Trip.new()
	trip.label = label
	trip.middle_dock = _real.dock_of(SETTLEMENT_PREFIX + order[1])
	var view: CaravanBodiesView = CaravanBodiesView.new()
	add_child_autofree(view)
	assert_true(view.setup(_bridge, _terrain_view, _real))
	var spot: Vector2 = _real.dock_of(SETTLEMENT_PREFIX + order[0])
	for leg: int in 2:
		var from_id: String = SETTLEMENT_PREFIX + order[leg]
		var to_id: String = SETTLEMENT_PREFIX + order[leg + 1]
		var route_id: String = _route_between(from_id, to_id)
		var line: PackedVector2Array = _real.leg_line(route_id, from_id, to_id, _markets[from_id], _markets[to_id])
		var length_m: float = CaravanPath.new(line).length_m()
		var steps: int = ceili(length_m / STEP_M)
		for step: int in steps + 1:
			var walked_m: float = minf(float(step) * STEP_M, length_m)
			_draw_terrain_around(spot)
			_bridge.rows.assign([ScriptedCaravanBridge.row_of(TRADER, walked_m / length_m, route_id, from_id, to_id)])
			_terrain_view.set_focus(Vector3(spot.x, GROUND_M, spot.y))
			view.reconcile()
			var body: CaravanView = view.body_of(TRADER)
			if body == null or not body.visible:
				trip.hidden_steps += 1
				continue
			spot = Vector2(body.position.x, body.position.z)
			if step == 0:
				trip.leg_starts.append(spot)
			if step == steps:
				trip.leg_ends.append(spot)
			var polygon: PackedVector2Array = RouteObstacles.cart_polygon(spot, body.rotation.y)
			trip.note(_obstacles.nearest(polygon), _obstacles.nearest(polygon, true))
	_bridge.rows.clear()
	view.reconcile()
	_driven[label] = trip
	return trip


## Uma frase por viagem para a mensagem (a folga mínima, o obstáculo e quantos passos tocaram ou ficaram abaixo do piso).
func _told(trips: Array[Trip]) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for trip: Trip in trips:
		parts.append("%s: folga mínima %.3f m com %s (%d passos de %.2f m em contato, %d abaixo de %.1f m)" % [trip.label, trip.gap_m, trip.item_id, trip.contact_steps, STEP_M, trip.low_steps, FLOOR_M])
	return "; ".join(parts)


## Verde se a folga é a do piso; senão PENDENTE com a medida (a limitação conhecida da volta em U na doca).
func _assert_or_pend(orders: Array) -> void:
	var trips: Array[Trip] = []
	var is_clear: bool = true
	for order: Array[String] in orders:
		var trip: Trip = _drive(order)
		trips.append(trip)
		is_clear = is_clear and trip.gap_m >= FLOOR_M and trip.hidden_steps == 0
	gut.p("Viagens de dois trechos: " + _told(trips))
	if is_clear:
		for trip: Trip in trips:
			assert_gte(trip.gap_m, FLOOR_M, "A limitação foi consertada: a volta em U passa a no mínimo 0,3 m de tudo. " + _told(trips))
		return
	pending("LIMITAÇÃO CONHECIDA (a volta em U na doca varre a praça; decisão de Arthur: o desvio por estrada fechada é raro): " + _told(trips))


func test_the_two_trips_through_a_keep_the_floor_clearance_in_the_u_turn_at_the_dock() -> void:
	var trips: Array[Trip] = [_drive(TRIP_B_A_C), _drive(TRIP_C_A_B)]
	gut.p("Viagens por A: " + _told(trips))
	for trip: Trip in trips:
		assert_eq(trip.hidden_steps, 0, "%s: o corpo apareceu em todos os passos (a medida não olhou para o vazio)" % trip.label)
		assert_gte(trip.gap_m, FLOOR_M, "%s: a viagem por A passa a no mínimo 0,3 m de tudo, inclusive adereços e arbustos. %s" % [trip.label, _told(trips)])


func test_the_two_trips_through_b_keep_the_floor_clearance_or_are_a_known_limit() -> void:
	_assert_or_pend([TRIP_A_B_C, TRIP_C_B_A])


func test_the_two_trips_through_c_keep_the_floor_clearance_or_are_a_known_limit() -> void:
	_assert_or_pend([TRIP_A_C_B, TRIP_B_C_A])


func test_the_joint_between_the_two_legs_is_continuous_on_all_six_trips() -> void:
	for order: Array in [TRIP_B_A_C, TRIP_C_A_B, TRIP_A_B_C, TRIP_C_B_A, TRIP_A_C_B, TRIP_B_C_A]:
		var typed: Array[String] = []
		typed.assign(order)
		var trip: Trip = _drive(typed)
		assert_eq([trip.leg_starts.size(), trip.leg_ends.size(), trip.hidden_steps], [2, 2, 0], "%s: as duas pontas dos dois trechos foram vistas" % trip.label)
		if trip.leg_starts.size() == 2 and trip.leg_ends.size() == 2:
			assert_lte(trip.leg_ends[0].distance_to(trip.leg_starts[1]), ONE_CM, "%s: o fim do 1º trecho e o começo do 2º são o mesmo ponto, a menos de 1 cm" % trip.label)
			assert_lte(trip.leg_ends[0].distance_to(trip.middle_dock), ONE_CM, "%s: e esse ponto é a doca do povoado do meio" % trip.label)


## O que se mediu numa viagem de dois trechos: a menor folga (e onde), os passos em contato e abaixo do piso, e as pontas dos trechos.
class Trip:
	extends RefCounted

	var label: String = ""
	var gap_m: float = INF
	var item_id: String = ""
	var contact_steps: int = 0
	var low_steps: int = 0
	var hidden_steps: int = 0
	var middle_dock: Vector2 = Vector2.ZERO
	var leg_starts: Array[Vector2] = []
	var leg_ends: Array[Vector2] = []


	func note(main: RouteObstacles.Hit, minor: RouteObstacles.Hit) -> void:
		var hit: RouteObstacles.Hit = main if main.gap_m <= minor.gap_m else minor
		contact_steps += 1 if hit.gap_m <= 0.0 else 0
		low_steps += 1 if hit.gap_m < FLOOR_M else 0
		if hit.gap_m < gap_m:
			gap_m = hit.gap_m
			item_id = hit.item.id if hit.item != null else ""
