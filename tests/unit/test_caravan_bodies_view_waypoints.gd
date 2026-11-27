extends GutTest
## LW-099g (opção B): a `CaravanBodiesView` com docas e pontos de passagem no dado, sem janela, com a ponte roteirizada (`ScriptedCaravanBridge`), os mercados e o terreno REAIS e um dado SINTÉTICO (o dado do jogo é conferido em `test_caravan_route_clearance.gd`).
## A estrada vem de `CaravanRoutesReader.leg_line`: o caminho mostrado nasce na doca do povoado de saída e termina na do de chegada, passa por cada ponto NA ORDEM CERTA nos dois sentidos (o sentido vem do `settlement_a_id` do dado), a troca de trecho de uma viagem de dois trechos não salta
## (a doca é compartilhada), `u` anda o comprimento da polilinha mostrada, o dado de hoje (sem docas nem pontos) dá BIT A BIT as poses de hoje (`CaravanPath.through(mercado, vazio, mercado)`), e nenhum aviso novo aparece. Trecho sem mercado conhecido continua sem estrada (`unplaced`).

const WORLD_DIR: String = "res://data/world"
const A: String = "test_settlement_a"
const B: String = "test_settlement_b"
const C: String = "test_settlement_c"
const ROUTE_A_B: String = "route_a_b"
const ROUTE_A_C: String = "route_a_c"
const ROUTE_B_C: String = "route_b_c"
const TRADER: int = 100
const MARKETS: Dictionary[String, Vector2] = {A: Vector2(313.0, 556.0), B: Vector2(807.0, 653.0), C: Vector2(567.0, 853.0)}
## Dado SINTÉTICO: uma doca a uns 6 m do mercado de cada povoado e pontos de passagem longe das pontas (mais de 12 m andados: a rampa lateral já está cheia), na ordem do povoado `a` da rota para o outro.
const DOCKS: Dictionary[String, Vector2] = {A: Vector2(313.0, 562.0), B: Vector2(801.0, 653.0), C: Vector2(567.0, 847.0)}
const ROUTE_A: Dictionary[String, String] = {ROUTE_A_B: A, ROUTE_A_C: A, ROUTE_B_C: B}
const ROUTE_POINTS: Dictionary[String, Array] = {
	ROUTE_A_B: [Vector2(400.0, 520.0), Vector2(560.0, 540.0), Vector2(700.0, 600.0)],
	ROUTE_A_C: [Vector2(350.0, 700.0), Vector2(450.0, 780.0)],
	ROUTE_B_C: [Vector2(700.0, 720.0), Vector2(640.0, 800.0)],
}
const ROUTE_ENDS: Dictionary[String, Array] = {ROUTE_A_B: [A, B], ROUTE_A_C: [A, C], ROUTE_B_C: [B, C]}
const VIEW: Dictionary = {"enter_m": 80, "exit_m": 120, "lateral_offset_m": 1.2, "pool_size": 8, "max_pitch_deg": 25}
const CARGO: Array = [{"good_id": "grain", "color": "#C4A24C", "shape": "sack"}]
const GROUND_M: float = 10.0
const CHUNK_M: float = 64.0
const LATERAL_M: float = 1.2
const ONE_CM: float = 0.01
const ANGLE_TOLERANCE: float = 0.0001
const MIN_DOCK_GAP_M: float = 5.0
const SAMPLES: Array[float] = [0.0, 0.001, 0.1, 0.37, 0.5, 0.9, 1.0]

var _terrain: TerrainData
var _places: Array[Place] = []
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


## O dado sintético (com as docas e os pontos acima) ou, com `bare`, o de hoje: as três rotas, sem docas nem pontos nem `settlement_a_id`.
func _reader(bare: bool = false, extra_docks: Array = []) -> CaravanRoutesReader:
	var routes: Array = []
	var docks: Array = extra_docks.duplicate()
	for route_id: String in ROUTE_POINTS:
		var row: Dictionary = {"route_id": route_id}
		if not bare:
			var points: Array = []
			for point: Vector2 in ROUTE_POINTS[route_id]:
				points.append([point.x, point.y])
			row["settlement_a_id"] = ROUTE_A[route_id]
			row["points_m"] = points
		routes.append(row)
	for settlement_id: String in DOCKS:
		if not bare:
			docks.append({"settlement_id": settlement_id, "point_m": [DOCKS[settlement_id].x, DOCKS[settlement_id].y]})
	var root: Dictionary = {"version": 1, "view": VIEW, "routes": routes, "cargo": CARGO}
	if not docks.is_empty():
		root["docks"] = docks
	var loaded: CaravanRoutesReader.LoadResult = CaravanRoutesReader.from_json(JSON.stringify(root), "dado sintético")
	assert_true(loaded.result.ok, loaded.result.message)
	return loaded.data


func _start(routes: CaravanRoutesReader) -> void:
	_bridge = ScriptedCaravanBridge.new(null, _terrain, _places)
	_terrain_view = TerrainView.new()
	add_child_autofree(_terrain_view)
	_terrain_view.setup(_bridge)
	_terrain_view.set_process(false)
	_view = CaravanBodiesView.new()
	add_child_autofree(_view)
	assert_true(_view.setup(_bridge, _terrain_view, routes))


func _draw_terrain_around(spot: Vector2) -> void:
	var center: Vector2i = Vector2i(floori(spot.x / CHUNK_M), floori(spot.y / CHUNK_M))
	for dz: int in range(-1, 2):
		for dx: int in range(-1, 2):
			var coord: Vector2i = center + Vector2i(dx, dz)
			if not _terrain_view.has_chunk(coord):
				assert_true(_terrain_view.build_chunk(coord), "O chunk %s foi desenhado." % coord)


## Mostra a caravana no trecho de `from_id` a `to_id` na fração `u`, com o foco do jogador em `focus_m` (perto da pose esperada), consulta e devolve o corpo.
func _show(route_id: String, from_id: String, to_id: String, u: float, focus_m: Vector2) -> CaravanView:
	_draw_terrain_around(focus_m)
	_bridge.rows.assign([ScriptedCaravanBridge.row_of(TRADER, u, route_id, from_id, to_id)])
	_terrain_view.set_focus(Vector3(focus_m.x, GROUND_M, focus_m.y))
	_view.reconcile()
	return _view.body_of(TRADER)


## A caravana some da consulta (a chegada): o registro dela se perde, e a próxima pose é uma PRIMEIRA pose (sem limite de giro).
func _forget() -> void:
	_bridge.rows.clear()
	_view.reconcile()


func _spot_of(view: CaravanView) -> Vector2:
	return Vector2(view.position.x, view.position.z)


## O giro de quem anda na direção `heading` (a convenção do `CaravanPath`: a frente é -Z).
func _yaw_of(heading: Vector2) -> float:
	var unit: Vector2 = heading.normalized()
	return atan2(-unit.x, -unit.y)


## A polilinha ESPERADA do trecho, montada aqui à mão a partir das constantes (nunca por `leg_line`): doca de saída, pontos (na ordem do dado se sai do `a` da rota, invertidos se não), doca de chegada.
func _expected_line(route_id: String, from_id: String, to_id: String) -> PackedVector2Array:
	var via: Array = ROUTE_POINTS[route_id]
	var line: PackedVector2Array = PackedVector2Array()
	line.append(DOCKS[from_id])
	for index: int in via.size():
		line.append(via[index] if from_id == ROUTE_A[route_id] else via[via.size() - 1 - index])
	line.append(DOCKS[to_id])
	return line


func _length_of(line: PackedVector2Array) -> float:
	var total: float = 0.0
	for index: int in range(1, line.size()):
		total += line[index].distance_to(line[index - 1])
	return total


## Os dois sentidos de cada rota: [rota, saída, chegada].
func _legs() -> Array:
	var legs: Array = []
	for route_id: String in ROUTE_ENDS:
		legs.append([route_id, ROUTE_ENDS[route_id][0], ROUTE_ENDS[route_id][1]])
		legs.append([route_id, ROUTE_ENDS[route_id][1], ROUTE_ENDS[route_id][0]])
	return legs


func test_the_shown_path_is_born_and_ends_on_the_docks_in_both_directions() -> void:
	_start(_reader())
	for leg: Array in _legs():
		var route_id: String = leg[0]
		var from_id: String = leg[1]
		var to_id: String = leg[2]
		var line: PackedVector2Array = _expected_line(route_id, from_id, to_id)
		var label: String = "%s de %s para %s" % [route_id, from_id, to_id]
		_forget()
		var leaving: CaravanView = _show(route_id, from_id, to_id, 0.0, DOCKS[from_id])
		assert_lt(_spot_of(leaving).distance_to(DOCKS[from_id]), ONE_CM, "%s: nasce na doca do povoado de saída (a 1 cm)." % label)
		assert_gt(_spot_of(leaving).distance_to(MARKETS[from_id]), MIN_DOCK_GAP_M, "%s: e não no centro do mercado." % label)
		assert_almost_eq(leaving.rotation.y, _yaw_of(line[1] - line[0]), ANGLE_TOLERANCE, "%s: sai olhando para o primeiro ponto (ou para a doca de chegada, se não há pontos)." % label)
		var arriving: CaravanView = _show(route_id, from_id, to_id, 1.0, DOCKS[to_id])
		assert_lt(_spot_of(arriving).distance_to(DOCKS[to_id]), ONE_CM, "%s: termina na doca do povoado de chegada (a 1 cm)." % label)
		assert_gt(_spot_of(arriving).distance_to(MARKETS[to_id]), MIN_DOCK_GAP_M, "%s: e não no centro do mercado." % label)
	assert_push_warning_count(0, "Nenhum aviso: o sentido dos pontos vem do dado.")


func test_the_shown_path_passes_through_every_point_in_the_right_order_in_both_directions() -> void:
	_start(_reader())
	for leg: Array in _legs():
		var route_id: String = leg[0]
		var from_id: String = leg[1]
		var to_id: String = leg[2]
		var line: PackedVector2Array = _expected_line(route_id, from_id, to_id)
		var total_m: float = _length_of(line)
		var walked_m: float = 0.0
		for index: int in range(1, line.size() - 1):
			walked_m += line[index].distance_to(line[index - 1])
			_forget()
			var body: CaravanView = _show(route_id, from_id, to_id, walked_m / total_m, line[index])
			assert_almost_eq(_spot_of(body).distance_to(line[index]), LATERAL_M, ONE_CM, "%s de %s para %s: na fração do ponto %d (%s) o corpo está nele (a 1,2 m, o deslocamento lateral); fora da ordem estaria longe." % [route_id, from_id, to_id, index, line[index]])
	assert_push_warning_count(0, "Nenhum aviso.")


func test_the_two_legs_of_a_trip_share_the_dock_with_no_gap() -> void:
	_start(_reader())
	var arriving: CaravanView = _show(ROUTE_A_C, A, C, 1.0, DOCKS[C])
	var end_of_first: Vector2 = _spot_of(arriving)
	var leaving: CaravanView = _show(ROUTE_B_C, C, B, 0.0, DOCKS[C])
	assert_eq(leaving, arriving, "O mesmo corpo atravessa o povoado de passagem.")
	assert_lt(_spot_of(leaving).distance_to(end_of_first), ONE_CM, "TROCA DE TRECHO: o fim do primeiro trecho e o começo do segundo são o mesmo ponto (a doca de C), a menos de 1 cm.")
	assert_lt(end_of_first.distance_to(DOCKS[C]), ONE_CM, "E esse ponto é a doca de C.")


func test_u_maps_the_length_of_the_polyline_shown() -> void:
	_start(_reader())
	for leg: Array in _legs():
		var route_id: String = leg[0]
		var from_id: String = leg[1]
		var to_id: String = leg[2]
		var line: PackedVector2Array = _expected_line(route_id, from_id, to_id)
		var total_m: float = _length_of(line)
		var before_m: float = _length_of(line.slice(0, 2))
		var segment_m: float = line[1].distance_to(line[2])
		var near: Vector2 = line[1].lerp(line[2], 0.25)
		var far: Vector2 = line[1].lerp(line[2], 0.75)
		var first: Vector2 = _spot_of(_show(route_id, from_id, to_id, (before_m + 0.25 * segment_m) / total_m, near))
		var second: Vector2 = _spot_of(_show(route_id, from_id, to_id, (before_m + 0.75 * segment_m) / total_m, far))
		assert_almost_eq(first.distance_to(second), 0.5 * segment_m, ONE_CM, "%s de %s para %s: andar 50%% de um trecho da polilinha (u) anda 50%% do comprimento dele; `u` é a fração do comprimento da polilinha mostrada." % [route_id, from_id, to_id])
		assert_almost_eq(first.distance_to(near), LATERAL_M, ONE_CM, "%s de %s para %s: e o corpo está na reta do trecho, 1,2 m à direita." % [route_id, from_id, to_id])


## O dado de hoje (sem docas, pontos nem `settlement_a_id`) dá as MESMAS poses que `CaravanPath.through(mercado, vazio, mercado)`: posição igual bit a bit (a primeira pose de uma caravana não tem limite de giro; o giro aqui é conferido a 0,1 mrad).
func test_the_data_of_today_still_gives_the_poses_of_today_bit_for_bit() -> void:
	_start(_reader(true))
	var pose: CaravanPath.Pose = CaravanPath.Pose.new()
	var worst_m: float = 0.0
	for leg: Array in _legs():
		var route_id: String = leg[0]
		var from_id: String = leg[1]
		var to_id: String = leg[2]
		var road: CaravanPath = CaravanPath.through(MARKETS[from_id], PackedVector2Array(), MARKETS[to_id])
		for u: float in SAMPLES:
			road.sample_into(u, true, LATERAL_M, pose, CaravanBodiesView.LATERAL_RAMP_M)
			_forget()
			var body: CaravanView = _show(route_id, from_id, to_id, u, pose.position)
			assert_eq(_spot_of(body), pose.position, "%s de %s para %s, u=%s: a posição é a de hoje, bit a bit." % [route_id, from_id, to_id, u])
			assert_almost_eq(body.rotation.y, pose.yaw, ANGLE_TOLERANCE, "%s de %s para %s, u=%s: e o giro também." % [route_id, from_id, to_id, u])
			worst_m = maxf(worst_m, _spot_of(body).distance_to(pose.position))
	assert_eq(worst_m, 0.0, "O maior desvio contra a estrada de hoje é zero.")
	assert_push_warning_count(0, "E nenhum aviso (antes da LW-099g, com pontos no dado, a vista avisava e caía na reta).")


func test_a_leg_with_a_settlement_that_has_no_known_market_stays_unplaced_even_with_a_dock() -> void:
	_start(_reader(false, [{"settlement_id": "ghost", "point_m": [100.0, 100.0]}]))
	_bridge.rows.assign([ScriptedCaravanBridge.row_of(TRADER, 0.5, ROUTE_A_B, "ghost", B)])
	_terrain_view.set_focus(Vector3(DOCKS[B].x, GROUND_M, DOCKS[B].y))
	_view.reconcile()
	assert_eq([_view.unplaced, _view.body_of(TRADER)], [1, null], "Sem mercado conhecido no povoado de saída (mesmo com doca no dado): sem estrada e sem corpo.")
