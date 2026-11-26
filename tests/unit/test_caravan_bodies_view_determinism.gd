extends GutTest
## LW-099g: DETERMINISMO da pose da caravana mostrada (`CaravanBodiesView`, sem janela, ponte roteirizada, dado REAL de apresentação, qualquer que ele seja). A POSIÇÃO é função PURA da fração `u`: a mesma posição, bit a bit, por qualquer caminho de quadros até ela (direto, andando de 0,3 m em 0,3 m, aos saltos e indo e voltando). O GIRO tem
## memória por desenho (anda no máximo `TURN_RAD_PER_M` por metro andado, e a primeira pose de uma caravana é o giro da estrada), então a pureza dele vale depois de assentado: a mais de 6 m de qualquer quina ele é o giro da estrada por todos os caminhos, a 0,1 mrad. Isso vale com docas e pontos de passagem no dado (as quinas são deles) ou sem.

const WORLD_DIR: String = "res://data/world"
const ROUTES_FILE: String = "res://data/world/routes.json"
const PLACES_FILE: String = "res://data/world/places.json"
const TRADER: int = 100
const GROUND_M: float = 10.0
const CHUNK_M: float = 64.0
const FINE_STEP_M: float = 0.3
const SETTLED_M: float = 6.0
const SAFE_SAMPLES: int = 3
const CANDIDATES: Array[float] = [0.15, 0.3, 0.45, 0.6, 0.75, 0.9]
const ANGLE_TOLERANCE: float = 0.0001

var _terrain: TerrainData
var _places: Array[Place] = []
var _routes: CaravanRoutesReader
var _markets: Dictionary[String, Vector2] = {}
var _bridge: ScriptedCaravanBridge
var _terrain_view: TerrainView
var _view: CaravanBodiesView


func before_all() -> void:
	var terrain: TerrainLoader.LoadResult = TerrainLoader.load_dir(WORLD_DIR)
	assert_true(terrain.result.ok, terrain.result.message)
	_terrain = terrain.terrain
	var settlements: SettlementLoader.LoadResult = SettlementLoader.load_dir(WORLD_DIR, _terrain)
	assert_true(settlements.result.ok, settlements.result.message)
	_places = settlements.places
	var rows: Variant = JSON.parse_string(FileAccess.get_file_as_string(PLACES_FILE))  # Variant: fronteira com o JSON, conferido abaixo
	assert_eq(typeof(rows), TYPE_ARRAY, "places.json é uma lista")
	for row: Dictionary in rows:
		if str(row["kind"]) == PlacePalette.KIND_MARKET:
			_markets[str(row["settlement_id"])] = Vector2(float(row["x_cm"]), float(row["z_cm"])) / RouteObstacles.CM_PER_M
	var loaded: CaravanRoutesReader.LoadResult = CaravanRoutesReader.from_file()
	assert_true(loaded.result.ok, loaded.result.message)
	_routes = loaded.data


func _start() -> void:
	_bridge = ScriptedCaravanBridge.new(null, _terrain, _places)
	_terrain_view = TerrainView.new()
	add_child_autofree(_terrain_view)
	_terrain_view.setup(_bridge)
	_terrain_view.set_process(false)
	_view = CaravanBodiesView.new()
	add_child_autofree(_view)
	assert_true(_view.setup(_bridge, _terrain_view, _routes))


func _draw_terrain_around(spot: Vector2) -> void:
	var center: Vector2i = Vector2i(floori(spot.x / CHUNK_M), floori(spot.y / CHUNK_M))
	for dz: int in range(-1, 2):
		for dx: int in range(-1, 2):
			var coord: Vector2i = center + Vector2i(dx, dz)
			if not _terrain_view.has_chunk(coord):
				assert_true(_terrain_view.build_chunk(coord), "O chunk %s foi desenhado." % coord)


## A pose [posição, giro] depois de passar pelas frações `via`, na ordem, e chegar a `u`: uma caravana NOVA (a primeira pose não tem limite de giro), com o foco do jogador no ponto da estrada.
func _pose_after(leg: Array, road: CaravanPath, via: Array[float], u: float) -> Array:
	_bridge.rows.clear()
	_view.reconcile()
	var pose: CaravanPath.Pose = CaravanPath.Pose.new()
	var seen: Array = []
	for fraction: float in via + [u]:
		road.sample_into(fraction, true, 0.0, pose)
		_draw_terrain_around(pose.position)
		_bridge.rows.assign([ScriptedCaravanBridge.row_of(TRADER, fraction, str(leg[0]), str(leg[1]), str(leg[2]))])
		_terrain_view.set_focus(Vector3(pose.position.x, GROUND_M, pose.position.y))
		_view.reconcile()
		var body: CaravanView = _view.body_of(TRADER)
		seen = [Vector2(body.position.x, body.position.z), body.rotation.y]
	return seen


func _legs() -> Array:
	var rows: Variant = JSON.parse_string(FileAccess.get_file_as_string(ROUTES_FILE))  # Variant: fronteira com o JSON, conferido abaixo
	assert_eq(typeof(rows), TYPE_ARRAY, "routes.json é uma lista")
	var legs: Array = []
	for row: Dictionary in rows:
		legs.append([str(row["id"]), str(row["settlement_a_id"]), str(row["settlement_b_id"])])
		legs.append([str(row["id"]), str(row["settlement_b_id"]), str(row["settlement_a_id"])])
	return legs


## As frações de `CANDIDATES` a mais de SETTLED_M de qualquer vértice da polilinha mostrada (e das pontas), até SAFE_SAMPLES.
func _settled_fractions(line: PackedVector2Array) -> Array[float]:
	var cumulative: Array[float] = [0.0]
	for index: int in range(1, line.size()):
		cumulative.append(cumulative[index - 1] + line[index].distance_to(line[index - 1]))
	var found: Array[float] = []
	for candidate: float in CANDIDATES:
		var walked_m: float = candidate * cumulative[cumulative.size() - 1]
		var is_settled: bool = true
		for corner_m: float in cumulative:
			is_settled = is_settled and absf(walked_m - corner_m) >= SETTLED_M
		if is_settled and found.size() < SAFE_SAMPLES:
			found.append(candidate)
	return found


func test_the_position_is_a_pure_function_of_u_and_the_heading_settles_to_the_road_whatever_the_frames() -> void:
	_start()
	for leg: Array in _legs():
		var line: PackedVector2Array = _routes.leg_line(str(leg[0]), str(leg[1]), str(leg[2]), _markets[str(leg[1])], _markets[str(leg[2])])
		var road: CaravanPath = CaravanPath.new(line)
		var label: String = "%s de %s para %s" % [leg[0], leg[1], leg[2]]
		var samples: Array[float] = _settled_fractions(line)
		assert_gt(samples.size(), 0, "%s: há frações longe das quinas para conferir" % label)
		for u: float in samples:
			var fine: Array[float] = []
			var step: float = FINE_STEP_M / road.length_m()
			for index: int in range(0, int(u / step)):
				fine.append(float(index) * step)
			var paths: Array = [[] as Array[float], fine, [0.0, 0.8, 0.05, u * 0.5, 1.0] as Array[float], [minf(u + 0.2, 1.0), 1.0, 0.0, u * 0.9] as Array[float]]
			var direct: Array = _pose_after(leg, road, [] as Array[float], u)
			for via: Array[float] in paths:
				var seen: Array = _pose_after(leg, road, via, u)
				assert_eq(seen[0], direct[0], "%s, u=%.3f: a posição é a mesma, bit a bit, depois de %d quadros antes (função pura de u)" % [label, u, via.size()])
				assert_almost_eq(float(seen[1]), float(direct[1]), ANGLE_TOLERANCE, "%s, u=%.3f: o giro assentou no da estrada depois de %d quadros antes" % [label, u, via.size()])
	assert_push_warning_count(0, "Nenhum aviso.")
