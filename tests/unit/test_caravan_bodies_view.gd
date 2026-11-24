extends GutTest
## LW-099b2b: a VISTA que decide quem aparece (`CaravanBodiesView`), sem janela e com a ponte ROTEIRIZADA (`ScriptedCaravanBridge`: as linhas de `peek_caravan_bodies` são as do teste; a ponte do jogo real é montada em
## `tests/integration/test_caravan_bodies_in_game.gd`). Terreno, locais (os mercados) e dado de apresentação são os REAIS (alcance de 80 e 120 m, reserva de 8). Confere o alcance com histerese sobre o ponto DERIVADO (não o mercado de
## partida), `held` parado, o terreno não desenhado (corpo escondido e SEM pose, a última boa mantida), a reserva esgotada (sem erro, contada, saídas antes das entradas), a chegada, a consulta que falha, o trecho sem mercado, a recusa do `setup` e que a
## view só lê da ponte.

const WORLD_DIR: String = "res://data/world"
const SOURCE: String = "res://src/presentation/world_view/entities/caravan_bodies_view.gd"
const SETTLEMENT_A: String = "test_settlement_a"
const SETTLEMENT_B: String = "test_settlement_b"
const ROUTE_A_B: String = "route_a_b"
const TRADER: int = 100
const OTHER: int = 101
## Os mercados de A e de B (data/world/places.json, em metros): as pontas da estrada A-B.
const MARKET_A: Vector2 = Vector2(313.0, 556.0)
const MARKET_B: Vector2 = Vector2(807.0, 653.0)
const MIDDLE: float = 0.5
const GROUND_M: float = 10.0
const CHUNK_M: float = 64.0
const LATERAL_M: float = 1.2
const POSE_TOLERANCE_M: float = 0.01
const POOL_DATA: String = "\"pool_size\": 8"
const POOL_OF_ONE: String = "\"pool_size\": 1"
const FADE_EPS: float = 0.0001

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


## A vista ligada a uma ponte roteirizada e a um `TerrainView` de verdade (sem terreno desenhado até o teste pedir); `routes` nulo = o dado real.
func _start(routes: CaravanRoutesReader = null) -> void:
	_bridge = ScriptedCaravanBridge.new(null, _terrain, _places)
	_terrain_view = TerrainView.new()
	add_child_autofree(_terrain_view)
	_terrain_view.setup(_bridge)
	_terrain_view.set_process(false)
	_view = CaravanBodiesView.new()
	add_child_autofree(_view)
	assert_true(_view.setup(_bridge, _terrain_view, routes if routes != null else _routes))


func _row(trader_id: int, u: float, state: String = BridgeReplies.CaravanBodyReply.STATE_TRAVELLING) -> BridgeReplies.CaravanBodyReply:
	return ScriptedCaravanBridge.row_of(trader_id, u, ROUTE_A_B, SETTLEMENT_A, SETTLEMENT_B, state)


## O que a ponte roteirizada devolve na próxima consulta (`rows` é uma lista de `CaravanBodyReply`).
func _show(rows: Array) -> void:
	_bridge.rows.assign(rows)


func _heading() -> Vector2:
	return (MARKET_B - MARKET_A).normalized()


## O ponto da estrada A-B (no eixo, sem o deslocamento lateral) a `u` da polilinha.
func _road_at(u: float) -> Vector2:
	return MARKET_A.lerp(MARKET_B, u)


## Põe o foco do jogador a `gap_m` do ponto `u` da estrada, ao longo dela (para o lado de B).
func _focus_at(u: float, gap_m: float) -> void:
	var spot: Vector2 = _road_at(u) + _heading() * gap_m
	_terrain_view.set_focus(Vector3(spot.x, GROUND_M, spot.y))


func _spot_of(view: CaravanView) -> Vector2:
	return Vector2(view.position.x, view.position.z)


func _chunk_at(spot: Vector2) -> Vector2i:
	return Vector2i(floori(spot.x / CHUNK_M), floori(spot.y / CHUNK_M))


## Desenha o terreno em volta do ponto (o chunk dele e os oito vizinhos), como a `TerrainView` faria ao carregar em volta do foco.
func _draw_terrain_around(spot: Vector2) -> void:
	var center: Vector2i = _chunk_at(spot)
	for dz: int in range(-1, 2):
		for dx: int in range(-1, 2):
			var coord: Vector2i = center + Vector2i(dx, dz)
			if not _terrain_view.has_chunk(coord):
				assert_true(_terrain_view.build_chunk(coord), "O chunk %s foi desenhado." % coord)


## A cada distância (m) do foco ao ponto: "T" se a caravana tem corpo depois da consulta, "F" se não.
func _presence_along(u: float, gaps_m: Array) -> String:
	var seen: String = ""
	for gap_m: float in gaps_m:
		_focus_at(u, gap_m)
		_view.reconcile()
		seen += "T" if _view.body_of(TRADER) != null else "F"
	return seen


func test_the_range_enters_at_80_m_and_leaves_only_above_120_m_without_blinking() -> void:
	_start()
	_show([_row(TRADER, MIDDLE)])
	assert_eq(_presence_along(MIDDLE, [70.0, 79.0, 81.0, 100.0, 119.0, 121.0, 130.0]), "TTTTTFF", "Saindo: dentro até 120 m (a faixa de 80 a 120 m não pisca) e fora acima disso.")
	assert_eq(_presence_along(MIDDLE, [130.0, 121.0, 119.0, 100.0, 81.0, 79.0, 70.0]), "FFFFFTT", "Voltando: fora até 80 m (sem entrar na faixa) e dentro daí em diante.")
	var pool: CaravanViewPool = _view.pool()
	assert_eq([pool.taken, pool.returned, pool.active_count(), pool.created, pool.empty_hits, pool.duplicate_requests, pool.lost_count()], [2, 1, 1, _routes.pool_size, 0, 0, 0], "Duas entradas, uma saída e a reserva intacta.")


func test_the_distance_is_to_the_derived_point_and_not_to_the_departure_market() -> void:
	_start()
	_show([_row(TRADER, MIDDLE)])
	var departure: Vector2 = MARKET_A
	_terrain_view.set_focus(Vector3(departure.x, GROUND_M, departure.y))
	_view.reconcile()
	assert_null(_view.body_of(TRADER), "A caravana a 250 m do mercado de partida (onde o comerciante está, na simulação) não tem corpo para quem está lá.")
	_focus_at(MIDDLE, 10.0)
	_view.reconcile()
	assert_not_null(_view.body_of(TRADER), "Com o foco a 10 m do PONTO DERIVADO ela tem.")


func test_a_held_caravan_stays_put_and_stops_walking() -> void:
	_start()
	_draw_terrain_around(_road_at(0.3))
	_draw_terrain_around(MARKET_A)
	_show([_row(TRADER, 0.3)])
	_focus_at(0.3, 10.0)
	_view.reconcile()
	var body: CaravanView = _view.body_of(TRADER)
	assert_true(body.merchant().is_walking(), "Andando, o comerciante anda.")
	assert_gt(body.position.y, 0.0, "Premissa: o corpo foi posto no chão (terreno desenhado).")
	_show([_row(TRADER, 0.3, BridgeReplies.CaravanBodyReply.STATE_HELD)])
	var spot: Vector3 = body.position
	for _frame: int in 5:
		_view.reconcile()
	assert_eq([body.position, body.merchant().is_walking(), _view.body_of(TRADER)], [spot, false, body], "Parada (rota fechada), fica onde está, no mesmo corpo, e o comerciante para.")
	_show([_row(TRADER, 0.0, BridgeReplies.CaravanBodyReply.STATE_HELD)])
	_focus_at(0.0, 10.0)
	_view.reconcile()
	assert_lt(_spot_of(_view.body_of(TRADER)).distance_to(MARKET_A), LATERAL_M + POSE_TOLERANCE_M, "Parada sem ter andado, fica na ponta de partida do trecho (só o deslocamento lateral de lado).")


func test_without_the_terrain_chunk_the_body_hides_and_gets_no_pose_until_the_terrain_is_drawn() -> void:
	_start()
	_show([_row(TRADER, MIDDLE)])
	_focus_at(MIDDLE, 10.0)
	_view.reconcile()
	var body: CaravanView = _view.body_of(TRADER)
	assert_not_null(body, "O corpo existe mesmo sem o terreno do chunk (a vista escolhe quem aparece; o terreno só decide se se vê).")
	assert_eq([body.visible, body.position], [false, Vector3.ZERO], "Sem terreno desenhado o corpo fica escondido e SEM pose (nenhuma altura inventada).")
	_draw_terrain_around(_road_at(MIDDLE))
	_view.reconcile()
	assert_true(body.visible, "Com o terreno do chunk desenhado o corpo aparece...")
	assert_lt(_spot_of(body).distance_to(_road_at(MIDDLE)), LATERAL_M + POSE_TOLERANCE_M, "...já na pose da caravana (sem salto) e no chão.")
	assert_eq(body.position.y, GROUND_M)
	var last_good: Vector3 = body.position
	var ahead: float = 0.8
	assert_false(_terrain_view.has_chunk(_chunk_at(_road_at(ahead))), "Premissa: o terreno mais adiante na estrada não está desenhado.")
	_show([_row(TRADER, ahead)])
	_focus_at(ahead, 10.0)
	_view.reconcile()
	assert_eq([body.visible, body.position], [false, last_good], "A caravana entra num trecho sem terreno: escondida, e a última pose boa fica (nenhuma pose nova).")
	_draw_terrain_around(_road_at(ahead))
	_view.reconcile()
	assert_true(body.visible, "O terreno aparece e o corpo também...")
	assert_lt(_spot_of(body).distance_to(_road_at(ahead)), LATERAL_M + POSE_TOLERANCE_M, "...na pose de agora, não na antiga.")


func test_an_exhausted_pool_gives_no_error_counts_the_missing_body_and_returns_before_taking() -> void:
	var small: CaravanRoutesReader.LoadResult = CaravanRoutesReader.from_json(FileAccess.get_file_as_string(CaravanRoutesReader.DEFAULT_PATH).replace(POOL_DATA, POOL_OF_ONE), "reserva de um corpo")
	assert_true(small.result.ok, small.result.message)
	_start(small.data)
	_show([_row(TRADER, MIDDLE), _row(OTHER, MIDDLE + 0.02)])
	_focus_at(MIDDLE, 10.0)
	_view.reconcile()
	var pool: CaravanViewPool = _view.pool()
	assert_eq([_view.active_ids(), _view.waiting], [[TRADER] as Array[int], 1], "Um corpo e duas caravanas no alcance: a de menor id fica com ele e a outra espera, sem erro.")
	assert_gt(pool.empty_hits, 0, "A reserva vazia foi contada.")
	assert_eq(pool.created, 1, "A reserva não cresceu.")
	_show([_row(TRADER, 0.95), _row(OTHER, MIDDLE + 0.02)])
	_view.reconcile()
	assert_eq([_view.active_ids(), _view.waiting, pool.lost_count()], [[OTHER] as Array[int], 0, 0], "No mesmo quadro o corpo de quem saiu do alcance voltou ANTES de o outro entrar (reserva de um só).")


func test_the_arrival_returns_the_body_at_once_and_a_later_trip_starts_clean() -> void:
	_start()
	_show([_row(TRADER, 0.9)])
	_focus_at(0.9, 10.0)
	_view.reconcile()
	var body: CaravanView = _view.body_of(TRADER)
	assert_not_null(body)
	_show([])
	_view.reconcile()
	assert_eq([_view.active_ids(), _view.pool().returned, _view.pool().free_count(), body.is_bound(), body.visible], [[] as Array[int], 1, _routes.pool_size, false, false], "Sumiu da consulta (a chegada): o corpo volta à reserva no mesmo quadro, escondido e livre.")
	_draw_terrain_around(_road_at(0.1))
	_show([_row(TRADER, 0.1)])
	_focus_at(0.1, 10.0)
	_view.reconcile()
	assert_lt(_spot_of(_view.body_of(TRADER)).distance_to(_road_at(0.1)), LATERAL_M + POSE_TOLERANCE_M, "A viagem seguinte nasce onde a caravana está, sem pose herdada.")


func test_a_failing_query_leaves_the_bodies_as_they_are_with_one_warning_per_streak() -> void:
	_start()
	_draw_terrain_around(_road_at(MIDDLE))
	_show([_row(TRADER, MIDDLE)])
	_focus_at(MIDDLE, 10.0)
	_view.reconcile()
	var body: CaravanView = _view.body_of(TRADER)
	var spot: Vector3 = body.position
	assert_gt(spot.y, 0.0, "Premissa: o corpo foi posto no chão.")
	_bridge.is_failing = true
	_show([])
	_view.reconcile()
	_view.reconcile()
	assert_push_warning("caravanas indisponíveis")
	assert_push_warning_count(1, "UM aviso por sequência de falhas, não um por quadro.")
	assert_eq([_view.failed_queries, _view.body_of(TRADER), body.position, _view.is_active()], [2, body, spot, true], "Os corpos ficam como estavam e a vista segue ativa.")
	_bridge.is_failing = false
	_view.reconcile()
	assert_null(_view.body_of(TRADER), "A consulta voltou (sem a caravana): a chegada é tratada.")


func test_a_leg_with_an_unknown_settlement_has_no_road_and_no_body() -> void:
	_start()
	var no_geometry: BridgeReplies.CaravanBodyReply = _row(TRADER, MIDDLE)
	no_geometry.from_settlement_id = ""
	no_geometry.to_settlement_id = ""
	var nowhere: BridgeReplies.CaravanBodyReply = _row(OTHER, MIDDLE)
	nowhere.to_settlement_id = "no_such_settlement"
	_show([no_geometry, nowhere])
	_focus_at(MIDDLE, 10.0)
	_view.reconcile()
	assert_eq([_view.active_ids(), _view.unplaced, _view.pool().empty_hits], [[] as Array[int], 2, 0], "Sem o mercado de uma das pontas não há estrada nem corpo (contado), sem erro.")


func test_setup_refuses_what_it_cannot_read_and_stays_inactive() -> void:
	var view: CaravanBodiesView = CaravanBodiesView.new()
	add_child_autofree(view)
	var bridge: ScriptedCaravanBridge = ScriptedCaravanBridge.new(null, _terrain, _places)
	var terrain_view: TerrainView = TerrainView.new()
	add_child_autofree(terrain_view)
	assert_false(view.setup(bridge, null, _routes))
	assert_false(view.setup(bridge, terrain_view, CaravanRoutesReader.new()), "Dado de apresentação não carregado.")
	assert_push_error_count(2)
	assert_false(view.setup(ScriptedCaravanBridge.new(null, _terrain), terrain_view, _routes), "Sem locais não há mercado.")
	assert_push_error("nenhum mercado")
	assert_false(view.setup(ScriptedCaravanBridge.new(null, null), terrain_view, _routes), "Sem terreno.")
	assert_push_error(SimBridge.CODE_NO_TERRAIN)
	view.reconcile()
	assert_eq([view.is_active(), view.pool(), view.active_ids().size()], [false, null, 0], "Nada ligado, nenhum corpo e a consulta não faz nada.")


func test_the_view_only_reads_the_bridge_and_never_requests_anything() -> void:
	var source: String = FileAccess.get_file_as_string(SOURCE)
	assert_false(source.is_empty(), "O arquivo da vista foi lido.")
	assert_false(source.contains("request_"), "Nenhuma chamada `request_*`: a vista só lê (`peek_*`).")
	assert_true(source.contains("peek_caravan_bodies"), "E a consulta de que depende está lá.")


## LW-099d (revisão R8): o corpo devolvido no MEIO da aparição de 0,4 s volta opaco e sem aparição pendente, e o próximo `take` (reserva de um só: o MESMO corpo) começa uma aparição completa, sem herdar nem a transparência nem o tempo.
func test_a_body_given_back_in_the_middle_of_the_appearance_comes_back_opaque_and_the_next_take_inherits_nothing() -> void:
	var small: CaravanRoutesReader.LoadResult = CaravanRoutesReader.from_json(FileAccess.get_file_as_string(CaravanRoutesReader.DEFAULT_PATH).replace(POOL_DATA, POOL_OF_ONE), "reserva de um corpo")
	assert_true(small.result.ok, small.result.message)
	_start(small.data)
	_draw_terrain_around(_road_at(MIDDLE))
	_show([_row(TRADER, MIDDLE)])
	_focus_at(MIDDLE, 10.0)
	_view.reconcile()
	var body: CaravanView = _view.body_of(TRADER)
	assert_not_null(body, "Premissa: a caravana no alcance tem corpo.")
	if body == null:
		return
	assert_eq([body.visible, body.is_appearing(), body.fade()], [true, true, 1.0], "A 1ª pose começa a aparição: visível e ainda invisível.")
	body.advance_fade(0.1)
	assert_almost_eq(body.fade(), 0.75, FADE_EPS, "No meio da aparição.")
	_show([_row(TRADER, 0.95)])
	_view.reconcile()
	assert_null(_view.body_of(TRADER), "A caravana saiu do alcance e o corpo voltou à reserva.")
	assert_eq([body.fade(), body.is_appearing(), body.is_processing(), body.visible], [0.0, false, false, false], "Devolvido no meio da aparição: opaco, sem aparição pendente, sem `_process` e escondido.")
	body.advance_fade(0.3)
	assert_eq(body.fade(), 0.0, "E o tempo que passa depois não muda nada.")
	_show([_row(OTHER, MIDDLE + 0.02)])
	_view.reconcile()
	assert_same(_view.body_of(OTHER), body, "A reserva de um só entrega o MESMO corpo à outra caravana.")
	assert_eq([body.fade(), body.is_appearing(), body.visible], [1.0, true, true], "Uma aparição NOVA, completa: começa invisível.")
	body.advance_fade(0.1)
	assert_almost_eq(body.fade(), 0.75, FADE_EPS, "E com o relógio zerado (nada herdado dos 0,1 s da aparição anterior).")
