extends GutTest
## LW-099b2b: ONDE a vista põe o corpo da caravana (`CaravanBodiesView`), sem janela e com a ponte roteirizada (`ScriptedCaravanBridge`; o jogo real está em `tests/integration/test_caravan_bodies_in_game.gd`): o corpo anda a estrada RETA do mercado de
## saída ao de chegada (as pontas vêm de `peek_places`), 1,2 m à DIREITA da marcha (quem vai e quem volta não se atravessam), de frente para o destino, na altura do terreno sob os pés e inclinado pelo declive entre os pés e o eixo do carrinho (limitado a 25 graus); a altura que a ponte não dá
## deixa o corpo escondido e sem pose; a troca de trecho (viagem de vários trechos) não salta; e uma rota com pontos de passagem no dado, que a ponte ainda não consegue orientar, cai na reta com UM aviso.

const WORLD_DIR: String = "res://data/world"
const A: String = "test_settlement_a"
const B: String = "test_settlement_b"
const C: String = "test_settlement_c"
const ROUTE_A_B: String = "route_a_b"
const ROUTE_A_C: String = "route_a_c"
const ROUTE_B_C: String = "route_b_c"
const TRADER: int = 100
const OTHER: int = 101
## Os mercados dos três povoados (data/world/places.json, em metros).
const MARKETS: Dictionary[String, Vector2] = {A: Vector2(313.0, 556.0), B: Vector2(807.0, 653.0), C: Vector2(567.0, 853.0)}
const GROUND_M: float = 10.0
const CHUNK_M: float = 64.0
const LATERAL_M: float = 1.2
const MAX_PITCH_DEG: float = 25.0
const POSE_TOLERANCE_M: float = 0.01
const ANGLE_TOLERANCE: float = 0.0001
const GENTLE_SLOPE: float = 0.2
const STEEP_SLOPE: float = 1.0
const WAYPOINT_JUMP_M: float = 2.5
const VIA_ROUTE: String = "{\"route_id\": \"route_a_b\"}"
const VIA_ROUTE_WITH_POINT: String = "{\"route_id\": \"route_a_b\", \"points_m\": [[500, 700]]}"

var _terrain: TerrainData
var _places: Array[Place] = []
var _routes: CaravanRoutesReader
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
	var loaded: CaravanRoutesReader.LoadResult = CaravanRoutesReader.from_file()
	assert_true(loaded.result.ok, loaded.result.message)
	_routes = loaded.data


func _start(routes: CaravanRoutesReader = null) -> void:
	_bridge = ScriptedCaravanBridge.new(null, _terrain, _places)
	_terrain_view = TerrainView.new()
	add_child_autofree(_terrain_view)
	_terrain_view.setup(_bridge)
	_terrain_view.set_process(false)
	_view = CaravanBodiesView.new()
	add_child_autofree(_view)
	assert_true(_view.setup(_bridge, _terrain_view, routes if routes != null else _routes))


func _chunk_at(spot: Vector2) -> Vector2i:
	return Vector2i(floori(spot.x / CHUNK_M), floori(spot.y / CHUNK_M))


## Desenha o terreno em volta do ponto (o chunk dele e os oito vizinhos): sem terreno desenhado a vista não põe pose nenhuma.
func _draw_terrain_around(spot: Vector2) -> void:
	var center: Vector2i = _chunk_at(spot)
	for dz: int in range(-1, 2):
		for dx: int in range(-1, 2):
			var coord: Vector2i = center + Vector2i(dx, dz)
			if not _terrain_view.has_chunk(coord):
				assert_true(_terrain_view.build_chunk(coord), "O chunk %s foi desenhado." % coord)


## Desenha o terreno em volta de `focus_m`, mostra as caravanas `rows` com o foco do jogador ali (todas no alcance) e consulta.
func _watch(rows: Array, focus_m: Vector2) -> void:
	_draw_terrain_around(focus_m)
	_bridge.rows.assign(rows)
	_terrain_view.set_focus(Vector3(focus_m.x, GROUND_M, focus_m.y))
	_view.reconcile()


func _spot_of(view: CaravanView) -> Vector2:
	return Vector2(view.position.x, view.position.z)


## Para onde o corpo olha no plano (a frente é -Z local, girada de `yaw` em torno de Y).
func _facing_of(view: CaravanView) -> Vector2:
	return Vector2(-sin(view.rotation.y), -cos(view.rotation.y))


## A direita da marcha na direção `heading` (a mesma regra do `CaravanPath`).
func _right_of(heading: Vector2) -> Vector2:
	return Vector2(-heading.y, heading.x)


func test_the_body_walks_the_straight_road_from_market_to_market_facing_the_destination() -> void:
	_start()
	var heading: Vector2 = (MARKETS[B] - MARKETS[A]).normalized()
	for u: float in [0.0, 0.25, 0.5, 0.75, 1.0]:
		var on_road: Vector2 = MARKETS[A].lerp(MARKETS[B], u)
		_watch([ScriptedCaravanBridge.row_of(TRADER, u, ROUTE_A_B, A, B)], on_road)
		var body: CaravanView = _view.body_of(TRADER)
		var side_m: float = 0.0 if u == 0.0 or u == 1.0 else LATERAL_M
		assert_almost_eq(_spot_of(body).distance_to(on_road + _right_of(heading) * side_m), 0.0, POSE_TOLERANCE_M, "u=%s: sobre a reta entre os mercados, 1,2 m à direita da marcha (a LW-099c leva o deslocamento a 0 nas duas pontas: a caravana sai e chega no eixo)." % u)
		assert_almost_eq(_facing_of(body).distance_to(heading), 0.0, ANGLE_TOLERANCE, "u=%s: de frente para o mercado de chegada." % u)
		assert_eq(body.position.y, GROUND_M, "u=%s: na altura do terreno (chão plano de 10 m)." % u)
	assert_eq(_view.pool().active_count(), 1, "Sempre o mesmo corpo da caravana.")


func test_the_return_trip_uses_the_same_road_on_the_other_side() -> void:
	_start()
	var heading: Vector2 = (MARKETS[B] - MARKETS[A]).normalized()
	var middle: Vector2 = MARKETS[A].lerp(MARKETS[B], 0.5)
	_watch([ScriptedCaravanBridge.row_of(TRADER, 0.5, ROUTE_A_B, A, B), ScriptedCaravanBridge.row_of(OTHER, 0.5, ROUTE_A_B, B, A)], middle)
	var going: CaravanView = _view.body_of(TRADER)
	var coming: CaravanView = _view.body_of(OTHER)
	assert_almost_eq(_facing_of(coming).distance_to(-heading), 0.0, ANGLE_TOLERANCE, "Quem volta olha para o outro lado.")
	assert_almost_eq(_spot_of(coming).distance_to(middle - _right_of(heading) * LATERAL_M), 0.0, POSE_TOLERANCE_M, "E fica à direita DELE, que é a esquerda de quem vai.")
	assert_almost_eq(_spot_of(going).distance_to(_spot_of(coming)), 2.0 * LATERAL_M, POSE_TOLERANCE_M, "No cruzamento os dois passam a 2,4 m um do outro.")


func test_the_pitch_follows_the_slope_and_is_limited() -> void:
	_start()
	var middle: Vector2 = MARKETS[A].lerp(MARKETS[B], 0.5)
	var rise: float = (MARKETS[B] - MARKETS[A]).normalized().x
	for slope: float in [0.0, GENTLE_SLOPE, STEEP_SLOPE]:
		_bridge.slope_x = slope
		_watch([ScriptedCaravanBridge.row_of(TRADER, 0.5, ROUTE_A_B, A, B), ScriptedCaravanBridge.row_of(OTHER, 0.5, ROUTE_A_B, B, A)], middle)
		var up: float = minf(atan(slope * rise), deg_to_rad(MAX_PITCH_DEG))
		var going: CaravanView = _view.body_of(TRADER)
		var coming: CaravanView = _view.body_of(OTHER)
		assert_almost_eq(going.rotation.x, up, ANGLE_TOLERANCE, "Subindo (A para B, x cresce) com declive %s: inclinado para cima, até 25 graus." % slope)
		assert_almost_eq(coming.rotation.x, -up, ANGLE_TOLERANCE, "Descendo (B para A) com declive %s: o mesmo, para baixo." % slope)
		assert_almost_eq(going.position.y, GROUND_M + slope * going.position.x, POSE_TOLERANCE_M, "Declive %s: a altura é a do terreno no ponto." % slope)


func test_a_ground_the_bridge_cannot_read_leaves_the_body_hidden_and_without_a_pose() -> void:
	_start()
	var middle: Vector2 = MARKETS[A].lerp(MARKETS[B], 0.5)
	_draw_terrain_around(middle)
	_bridge.is_blind = true
	_watch([ScriptedCaravanBridge.row_of(TRADER, 0.5, ROUTE_A_B, A, B)], middle)
	var body: CaravanView = _view.body_of(TRADER)
	assert_true(body.is_bound(), "O corpo existe: quem está no alcance tem corpo.")
	assert_eq([body.visible, body.position, _view.ground_misses], [false, Vector3.ZERO, 1], "Sem altura a pose não é aplicada (nada de corpo na origem nem de altura inventada) e a falta é contada.")
	_bridge.is_blind = false
	_view.reconcile()
	assert_true(body.visible and absf(body.position.y - GROUND_M) < POSE_TOLERANCE_M, "Com a altura de volta o corpo é posto no chão e aparece.")


func test_a_trip_of_two_legs_does_not_jump_where_one_leg_ends_and_the_next_begins() -> void:
	_start()
	_watch([ScriptedCaravanBridge.row_of(TRADER, 1.0, ROUTE_A_C, A, C)], MARKETS[C])
	var body: CaravanView = _view.body_of(TRADER)
	var end_of_first: Vector2 = _spot_of(body)
	_watch([ScriptedCaravanBridge.row_of(TRADER, 0.0, ROUTE_B_C, C, B)], MARKETS[C])
	assert_eq(_view.body_of(TRADER), body, "O mesmo corpo atravessa o povoado de passagem.")
	assert_lt(_spot_of(body).distance_to(end_of_first), WAYPOINT_JUMP_M, "Do fim do primeiro trecho ao começo do segundo só muda o lado do deslocamento lateral (no máximo 2,4 m).")
	assert_lt(_spot_of(body).distance_to(MARKETS[C]), LATERAL_M + POSE_TOLERANCE_M, "O segundo trecho começa no mercado do povoado de passagem.")
	_watch([ScriptedCaravanBridge.row_of(TRADER, 0.5, ROUTE_B_C, C, B)], MARKETS[C].lerp(MARKETS[B], 0.5))
	assert_almost_eq(_spot_of(body).distance_to(MARKETS[C].lerp(MARKETS[B], 0.5)), LATERAL_M, POSE_TOLERANCE_M, "E segue pela estrada nova (C a B), não pela velha.")


func test_a_route_with_waypoints_falls_back_to_the_straight_road_with_one_warning_per_route() -> void:
	var text: String = FileAccess.get_file_as_string(CaravanRoutesReader.DEFAULT_PATH)
	assert_true(text.contains(VIA_ROUTE), "Premissa: a rota A-B do dado real não tem pontos de passagem.")
	var loaded: CaravanRoutesReader.LoadResult = CaravanRoutesReader.from_json(text.replace(VIA_ROUTE, VIA_ROUTE_WITH_POINT), "rota com ponto de passagem")
	assert_true(loaded.result.ok, loaded.result.message)
	_start(loaded.data)
	var middle: Vector2 = MARKETS[A].lerp(MARKETS[B], 0.5)
	_watch([ScriptedCaravanBridge.row_of(TRADER, 0.5, ROUTE_A_B, A, B)], middle)
	_watch([ScriptedCaravanBridge.row_of(TRADER, 0.5, ROUTE_A_B, B, A)], middle)
	assert_push_warning("pontos de passagem")
	assert_push_warning_count(1, "UM aviso por rota, mesmo com as duas direções e vários quadros.")
	var heading: Vector2 = (MARKETS[B] - MARKETS[A]).normalized()
	assert_almost_eq(_spot_of(_view.body_of(TRADER)).distance_to(middle - _right_of(heading) * LATERAL_M), 0.0, POSE_TOLERANCE_M, "A estrada fica reta (nunca desenhada de trás para a frente).")
