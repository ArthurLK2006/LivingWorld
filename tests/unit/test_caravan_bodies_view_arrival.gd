extends GutTest
## LW-099h (chegada suave; só apresentação): o PONTO DE CHEGADA da `CaravanBodiesView`, sem janela, com a ponte roteirizada, os mercados e o terreno REAIS e dado SINTÉTICO. Quando a caravana some da consulta com o corpo à vista do jogador, a vista guarda onde a viagem terminou
## (a doca do povoado de chegada, ou o mercado dele se o dado não tem doca) por `ARRIVAL_SPOT_TTL_S`, e quem o pega (`take_arrival_spot`, o `NpcBodiesView`) o esquece: vale UMA vez. Sem corpo à vista (longe, terreno não desenhado, saiu do alcance antes) não há ponto, e o de um
## comerciante nunca é o de outro. O prazo anda só com o `delta` do `reconcile` (sem argumento, o tempo não passa).

const WORLD_DIR: String = "res://data/world"
const A: String = "test_settlement_a"
const B: String = "test_settlement_b"
const ROUTE_A_B: String = "route_a_b"
const TRADER: int = 100
const OTHER: int = 101
const MARKET_B: Vector2 = Vector2(807.0, 653.0)
## Dado SINTÉTICO: uma doca a 6 m do mercado de cada povoado.
const DOCK_A: Vector2 = Vector2(313.0, 562.0)
const DOCK_B: Vector2 = Vector2(801.0, 653.0)
const NEARLY_THERE: float = 0.97
const GROUND_M: float = 10.0
const CHUNK_M: float = 64.0
const FAR_M: Vector2 = Vector2(130.0, 130.0)
const TTL_MARGIN_S: float = 0.1

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


## O dado de apresentação com a rota A-B e, se `with_docks`, uma doca em cada povoado; sem docas é o dado de hoje.
func _start(with_docks: bool) -> void:
	var root: Dictionary = {"version": 1, "view": {"enter_m": 80, "exit_m": 120, "lateral_offset_m": 1.2, "pool_size": 8, "max_pitch_deg": 25}, "routes": [{"route_id": ROUTE_A_B}], "cargo": [{"good_id": "grain", "color": "#C4A24C", "shape": "sack"}]}
	if with_docks:
		root["docks"] = [{"settlement_id": A, "point_m": [DOCK_A.x, DOCK_A.y]}, {"settlement_id": B, "point_m": [DOCK_B.x, DOCK_B.y]}]
	var loaded: CaravanRoutesReader.LoadResult = CaravanRoutesReader.from_json(JSON.stringify(root), "dado sintético")
	assert_true(loaded.result.ok, loaded.result.message)
	_bridge = ScriptedCaravanBridge.new(null, _terrain, _places)
	_terrain_view = TerrainView.new()
	add_child_autofree(_terrain_view)
	_terrain_view.setup(_bridge)
	_terrain_view.set_process(false)
	_view = CaravanBodiesView.new()
	add_child_autofree(_view)
	assert_true(_view.setup(_bridge, _terrain_view, loaded.data))


func _draw_terrain_around(spot: Vector2) -> void:
	var center: Vector2i = Vector2i(floori(spot.x / CHUNK_M), floori(spot.y / CHUNK_M))
	for dz: int in range(-1, 2):
		for dx: int in range(-1, 2):
			var coord: Vector2i = center + Vector2i(dx, dz)
			if not _terrain_view.has_chunk(coord):
				assert_true(_terrain_view.build_chunk(coord), "O chunk %s foi desenhado." % coord)


## Põe os comerciantes dados no trecho A-B, perto do fim, com o foco do jogador em `focus_m` e o terreno em volta desenhado (`draw` falso: sem terreno, o corpo fica escondido).
func _show(traders: Array[int], focus_m: Vector2, draw: bool = true) -> void:
	if draw:
		_draw_terrain_around(focus_m)
	var rows: Array[BridgeReplies.CaravanBodyReply] = []
	for trader: int in traders:
		rows.append(ScriptedCaravanBridge.row_of(trader, NEARLY_THERE, ROUTE_A_B, A, B))
	_bridge.rows.assign(rows)
	_terrain_view.set_focus(Vector3(focus_m.x, GROUND_M, focus_m.y))
	_view.reconcile()


## A caravana de `trader` some da consulta (a chegada); os outros ficam.
func _arrive(trader: int, others: Array[int] = []) -> void:
	var rows: Array[BridgeReplies.CaravanBodyReply] = []
	for other: int in others:
		rows.append(ScriptedCaravanBridge.row_of(other, NEARLY_THERE, ROUTE_A_B, A, B))
	_bridge.rows.assign(rows)
	_view.reconcile()
	assert_null(_view.body_of(trader), "A caravana que chegou perdeu o corpo (voltou à reserva).")


func test_the_spot_is_the_dock_of_the_destination_and_is_taken_only_once() -> void:
	_start(true)
	_show([TRADER], DOCK_B)
	var body: CaravanView = _view.body_of(TRADER)
	assert_true(body != null and body.visible, "Premissa: o jogador vê o corpo da caravana.")
	assert_false(_view.has_arrival_spot(TRADER), "Em viagem não há ponto de chegada.")
	_arrive(TRADER)
	assert_true(_view.has_arrival_spot(TRADER), "A caravana sumiu com o corpo à vista: o ponto fica guardado.")
	assert_eq(_view.take_arrival_spot(TRADER), DOCK_B, "O ponto é a DOCA do povoado de chegada (e não o mercado, nem a última pose).")
	assert_false(_view.has_arrival_spot(TRADER), "Pegar o ponto o esquece...")
	assert_false(_view.take_arrival_spot(TRADER).is_finite(), "...e o pedido seguinte volta sem ponto (`NO_SPOT`): vale uma vez.")


func test_with_the_data_of_today_without_docks_the_spot_is_the_market_centre_of_the_destination() -> void:
	_start(false)
	_show([TRADER], MARKET_B)
	assert_true(_view.body_of(TRADER).visible, "Premissa: o jogador vê o corpo da caravana.")
	_arrive(TRADER)
	assert_eq(_view.take_arrival_spot(TRADER), MARKET_B, "Sem doca o ponto é o centro do mercado de chegada: a posição lógica do comerciante (quem usa o ponto o ignora ali).")


func test_a_caravan_the_player_did_not_see_leaves_no_spot() -> void:
	_start(true)
	_show([TRADER], FAR_M)
	assert_null(_view.body_of(TRADER), "Premissa: longe do foco (mais de 80 m) a caravana não tem corpo.")
	_arrive(TRADER)
	assert_false(_view.has_arrival_spot(TRADER), "Longe: ninguém viu o carrinho, não há de que ser contínuo.")
	_show([TRADER], DOCK_B, false)
	var hidden: CaravanView = _view.body_of(TRADER)
	assert_true(hidden != null and not hidden.visible, "Premissa: sem o terreno desenhado o corpo existe, mas está escondido.")
	_arrive(TRADER)
	assert_false(_view.has_arrival_spot(TRADER), "Escondido (sem terreno): o jogador não o via, e o ponto não é guardado.")


func test_a_caravan_that_left_the_range_before_arriving_leaves_no_spot() -> void:
	_start(true)
	_show([TRADER], DOCK_B)
	assert_not_null(_view.body_of(TRADER), "Premissa: no alcance a caravana tem corpo.")
	_show([TRADER], FAR_M)
	assert_null(_view.body_of(TRADER), "Premissa: o jogador se afastou (mais de 120 m) e o corpo voltou à reserva.")
	_arrive(TRADER)
	assert_false(_view.has_arrival_spot(TRADER), "Sair do alcance não é chegar, e quem chega sem ser visto não deixa ponto.")


func test_the_spot_expires_after_the_ttl_and_time_only_passes_with_a_delta() -> void:
	_start(true)
	_show([TRADER], DOCK_B)
	_arrive(TRADER)
	for _frame: int in 10:
		_view.reconcile()
	assert_true(_view.has_arrival_spot(TRADER), "`reconcile()` sem `delta` não faz o tempo passar.")
	_view.reconcile(CaravanBodiesView.ARRIVAL_SPOT_TTL_S - TTL_MARGIN_S)
	assert_true(_view.has_arrival_spot(TRADER), "Um pouco antes do prazo o ponto ainda vale.")
	_view.reconcile(TTL_MARGIN_S * 2.0)
	assert_false(_view.has_arrival_spot(TRADER), "Passado o prazo o ponto é esquecido.")
	assert_false(_view.take_arrival_spot(TRADER).is_finite(), "E ninguém o pega mais.")


func test_the_spot_of_one_merchant_is_never_the_spot_of_another() -> void:
	_start(true)
	_show([TRADER, OTHER], DOCK_B)
	assert_not_null(_view.body_of(OTHER), "Premissa: o outro comerciante também está à vista.")
	_arrive(TRADER, [OTHER])
	assert_true(_view.has_arrival_spot(TRADER), "Quem chegou tem ponto.")
	assert_false(_view.has_arrival_spot(OTHER), "Quem segue viajando não tem.")
	assert_false(_view.take_arrival_spot(OTHER).is_finite(), "Nem pega o do outro.")
	assert_not_null(_view.body_of(OTHER), "E o corpo dele segue como estava.")
	assert_eq(_view.take_arrival_spot(TRADER), DOCK_B, "O ponto de quem chegou continua o dele.")
