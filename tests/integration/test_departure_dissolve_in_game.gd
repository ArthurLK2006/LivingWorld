extends GutTest
## LW-099d: a DISSOLUÇÃO CRUZADA DE 0,4 s na partida da caravana no JOGO REAL, sem janela: dados reais, a ponte real, as duas vistas de corpos e o motorista dos corpos (como em `test_caravan_visual_jumps.gd`), com o foco do jogador a 10 m do mercado de saída do primeiro comerciante
## que parte no jogo novo. O tempo da vista é avançado pelo teste (`advance_departures` e `advance_fade`), em passos de 0,1 s. Só se confere o VALOR de `transparency`; como ela aparece (e as sombras) é da janela de Arthur.
## MEDIDO em 24/11/2026 ANTES da dissolução (base 91de893, o 1º comerciante que parte; minuto 804 do dia 1, 13:24): u = 0,0000, state_hash 2e6642dc... No quadro da partida o corpo do `NpcView` JÁ tinha voltado à reserva (devolvidos no quadro: 1) e a caravana aparecia opaca a 2,549 m do ponto onde
## ele estava: o "pulo". DEPOIS (opção ligada): no mesmo quadro o corpo AINDA existe (transparência 0, 0 devolvidos) e a caravana começa invisível (1); aos 0,2 s os dois estão a 0,5; aos 0,4 s só resta a caravana, opaca. Com a opção desligada o quadro da partida é o de antes (2,549 m, 1 devolvido).

const DATA_DIR: String = "res://data"
const WORLD_DIR: String = "res://data/world"
const MERCHANT: String = "merchant"
const ACTOR_ID: int = 1000
const DAY: int = SimClock.MINUTES_PER_DAY
const SEARCH_LIMIT: int = 3 * DAY
const CM_PER_M: float = 100.0
const CHUNK_M: float = 64.0
const GROUND_M: float = 10.0
const NEAR_M: float = 10.0
const MINUTE_S: float = 1.25
const STEP_S: float = 0.1
const EPS: float = 0.001
const NO_SPOT: Vector2 = Vector2(INF, INF)
## O pulo medido antes (m) e a folga com que a pose da caravana tem de continuar a mesma.
const POP_BEFORE_M: float = 2.549
const POP_TOLERANCE_M: float = 0.01
## Minutos depois da partida em que a simulação com e sem a despedida é comparada (a caravana ainda está na estrada).
const COMPARE_MINUTES: Array[int] = [30, 60]

var _data: NpcLifeCheck.GameData
var _routes: CaravanRoutesReader
var _games: Array[Game] = []
var _origin_settlement: String = ""
var _origin_m: Vector2 = Vector2.ZERO


class Game:
	extends RefCounted

	var runner: SimulationRunner
	var npc: NpcModule
	var economy: EconomyModule
	var host: SimulationHostNode
	var bridge: SimBridge
	var root: Node3D
	var terrain_view: TerrainView
	var npc_bodies: NpcBodiesView
	var caravan_bodies: CaravanBodiesView
	var driver: NpcBodyDriver
	var markets: Dictionary[String, Vector2] = {}


## A partida de um comerciante: o instante (minuto), a fração `u`, o `state_hash` do quadro, onde o `NpcView` estava em pé, onde a caravana nasceu, e quantos corpos de NPC voltaram à reserva e estavam ativos nesse quadro.
class Trip:
	extends RefCounted

	var game: Game
	var trader: int = IdGenerator.NO_ID
	var minute: int = 0
	var u: float = -1.0
	var state_hash: String = ""
	var npc_spot: Vector2 = NO_SPOT
	var first_spot: Vector2 = NO_SPOT
	var returned_in_frame: int = -1
	var active_after: int = 0


func before_all() -> void:
	_data = NpcLifeCheck.load_game_data()
	assert_eq(_data.problem, "", "Os dados reais do jogo carregam.")
	var routes: CaravanRoutesReader.LoadResult = CaravanRoutesReader.from_file()
	assert_true(routes.result.ok, routes.result.message)
	_routes = routes.data
	var found: Game = _build()
	found.runner.start_new_game()
	var traders: Array[int] = _merchants(found)
	for _minute: int in SEARCH_LIMIT:
		found.runner.step_once()
		for trader: int in traders:
			if found.economy.peek_caravan(trader).found and _origin_settlement.is_empty():
				var leaver: NpcModule.NpcQuery = found.npc.peek_npc(trader)
				_origin_settlement = leaver.settlement_id
				_origin_m = Vector2(leaver.x_cm, leaver.z_cm) / CM_PER_M
		if not _origin_settlement.is_empty():
			break
	assert_ne(_origin_settlement, "", "Algum comerciante parte em até 3 dias (a premissa destes testes).")


func after_each() -> void:
	for game: Game in _games:
		if game.caravan_bodies != null:
			game.caravan_bodies.release()
		if game.npc_bodies != null:
			game.npc_bodies.release()
		game.runner.finish()
		game.host.free()
	_games.clear()


func _build() -> Game:
	var setup: NpcSetup = NpcSetup.from_dir(DATA_DIR, SettlementService.new(_data.settlements, _data.places))
	assert_true(setup.result.ok, setup.result.message)
	var game: Game = Game.new()
	game.runner = SimulationRunner.new(GameAppNode.DEFAULT_WORLD_SEED, GameAppNode.NEW_GAME_START_MINUTE)
	var modules: GameModules = GameModules.register(game.runner, _data.terrain, _data.points, setup, EconomySetup.from_dir(EconomySetup.DEFAULT_DIR), WorldSetup.from_dir(WORLD_DIR, _data.settlements, OS.is_debug_build()))
	assert_true(modules.result.ok, modules.result.message)
	game.npc = modules.npc
	game.economy = modules.economy
	game.host = SimulationHostNode.new()
	game.host.runner = game.runner
	game.host.npc = game.npc
	game.host.economy = game.economy
	game.bridge = SimBridge.new(game.host, _data.terrain, _data.places, game.npc)
	_games.append(game)
	return game


## As duas vistas e o motorista ligados ao mesmo terreno, como a cena os liga; `fade_on`: a despedida dos corpos dos NPCs (o que `main_world_view.gd` liga com as caravanas visíveis).
func _new_game(fade_on: bool) -> Game:
	var game: Game = _build()
	game.runner.start_new_game()
	game.root = Node3D.new()
	add_child_autofree(game.root)
	game.terrain_view = TerrainView.new()
	game.root.add_child(game.terrain_view)
	game.terrain_view.setup(game.bridge)
	game.terrain_view.set_process(false)
	game.npc_bodies = NpcBodiesView.new()
	game.root.add_child(game.npc_bodies)
	game.npc_bodies.set_process(false)
	assert_true(game.npc_bodies.setup(game.bridge, game.terrain_view))
	game.npc_bodies.set_departure_fade(fade_on)
	for place: BridgeReplies.PlaceReply in game.bridge.peek_places().places:
		if place.kind == PlacePalette.KIND_MARKET:
			game.markets[place.settlement_id] = Vector2(place.x, place.z)
	game.caravan_bodies = CaravanBodiesView.new()
	game.root.add_child(game.caravan_bodies)
	game.caravan_bodies.set_process(false)
	assert_true(game.caravan_bodies.setup(game.bridge, game.terrain_view, _routes))
	game.driver = NpcBodyDriver.new()
	game.root.add_child(game.driver)
	assert_true(game.driver.setup(game.bridge, game.npc_bodies))
	game.driver.set_physics_process(false)
	return game


func _merchants(game: Game, settlement_id: String = "") -> Array[int]:
	var ids: Array[int] = []
	for npc_id: int in game.npc.peek_npc_ids():
		var npc: NpcModule.NpcQuery = game.npc.peek_npc(npc_id)
		if npc.occupation_id == MERCHANT and (settlement_id.is_empty() or npc.settlement_id == settlement_id):
			ids.append(npc_id)
	return ids


func _focus(game: Game, spot_m: Vector2) -> void:
	var placed: Result = game.npc.request_set_focus(ACTOR_ID, Vector3(spot_m.x, GROUND_M, spot_m.y))
	assert_true(placed.ok, placed.message)
	game.terrain_view.set_focus(Vector3(spot_m.x, GROUND_M, spot_m.y))


func _draw_terrain_around(game: Game, spot_m: Vector2) -> void:
	var center: Vector2i = Vector2i(floori(spot_m.x / CHUNK_M), floori(spot_m.y / CHUNK_M))
	for dz: int in range(-1, 2):
		for dx: int in range(-1, 2):
			var coord: Vector2i = center + Vector2i(dx, dz)
			if not game.terrain_view.has_chunk(coord):
				assert_true(game.terrain_view.build_chunk(coord), "O chunk %s foi desenhado." % coord)


## Um minuto do jogo: um passo, o motorista e a despedida andam o tempo real de um minuto a 1x (1,25 s).
func _tick(game: Game) -> void:
	game.runner.step_once()
	game.driver.advance(MINUTE_S)
	game.npc_bodies.advance_departures(MINUTE_S)


func _row_of(game: Game, trader: int) -> BridgeReplies.CaravanBodyReply:
	for row: BridgeReplies.CaravanBodyReply in game.bridge.peek_caravan_bodies().bodies:
		if row.trader_id == trader:
			return row
	return null


func _refresh(game: Game) -> void:
	for row: BridgeReplies.CaravanBodyReply in game.bridge.peek_caravan_bodies().bodies:
		_draw_terrain_around(game, game.markets[row.from_settlement_id].lerp(game.markets[row.to_settlement_id], row.u))
	game.npc_bodies.reconcile()
	game.caravan_bodies.reconcile()


func _plane(view: Node3D) -> Vector2:
	return Vector2(view.position.x, view.position.z)


func _capsule(view: NpcView) -> GeometryInstance3D:
	return view.get_node(NodePath("%s/%s" % [NpcView.VISUAL_NAME, NpcView.CAPSULE_NAME])) as GeometryInstance3D


func _tire(view: CaravanView) -> GeometryInstance3D:
	return view.get_node(NodePath("%s/%s/%s" % [CaravanView.CART_NAME, CaravanView.WHEEL_NAMES[0], CaravanView.TIRE_NAME])) as GeometryInstance3D


## O jogo novo com as vistas, o foco a 10 m do mercado de partida, andado minuto a minuto até um comerciante do povoado de partida ter caravana; para NO quadro da partida (as duas vistas já em dia, sem o tempo da vista andar).
func _start_trip(fade_on: bool) -> Trip:
	var trip: Trip = Trip.new()
	trip.game = _new_game(fade_on)
	var game: Game = trip.game
	_focus(game, _origin_m + Vector2(NEAR_M, 0.0))
	_draw_terrain_around(game, _origin_m)
	_refresh(game)
	var traders: Array[int] = _merchants(game, _origin_settlement)
	var seen: Dictionary[int, Vector2] = {}
	for _minute: int in SEARCH_LIMIT:
		for trader: int in traders:
			var view: NpcView = game.npc_bodies.pool().body_of(trader)
			if view != null:
				seen[trader] = _plane(view)
		_tick(game)
		for trader: int in traders:
			var row: BridgeReplies.CaravanBodyReply = _row_of(game, trader)
			if row == null:
				continue
			var returned_before: int = game.npc_bodies.pool().returned
			_refresh(game)
			trip.trader = trader
			trip.minute = game.runner.world.context.clock.total_minutes()
			trip.u = row.u
			trip.state_hash = game.runner.world.state_hash()
			trip.npc_spot = seen.get(trader, NO_SPOT)
			trip.first_spot = _plane(game.caravan_bodies.body_of(trader))
			trip.returned_in_frame = game.npc_bodies.pool().returned - returned_before
			trip.active_after = game.npc_bodies.pool().active_count()
			return trip
		_refresh(game)
	fail_test("Nenhum comerciante do povoado de partida partiu em até 3 dias.")
	return trip


## Anda `minutes` minutos depois da partida (o foco fica onde estava) e devolve o `state_hash` e o `u` da caravana (-1 se ela já chegou).
func _walk(trip: Trip, minutes: int) -> Array:
	for _minute: int in minutes:
		_tick(trip.game)
		_refresh(trip.game)
	var row: BridgeReplies.CaravanBodyReply = _row_of(trip.game, trip.trader)
	return [trip.game.runner.world.state_hash(), row.u if row != null else -1.0]


func test_the_body_dissolves_where_it_stood_while_the_caravan_appears_and_then_only_the_caravan_is_left() -> void:
	var trip: Trip = _start_trip(true)
	var game: Game = trip.game
	var npc: NpcView = game.npc_bodies.pool().body_of(trip.trader)
	var caravan: CaravanView = game.caravan_bodies.body_of(trip.trader)
	assert_not_null(npc, "No quadro da partida o corpo do NPC AINDA existe (antes, voltava à reserva nesse mesmo quadro).")
	assert_not_null(caravan, "E a caravana já tem corpo.")
	if npc == null or caravan == null:
		return
	assert_eq([game.npc_bodies.fading_ids(), game.npc_bodies.active_ids().has(trip.trader), trip.returned_in_frame], [[trip.trader] as Array[int], true, 0], "Em despedida, ainda ativo, e nada voltou à reserva no quadro da partida.")
	assert_true(npc.visible and caravan.visible, "Os dois estão na tela no quadro da partida.")
	var waiting_ids: Array[int] = []
	for intent: BridgeReplies.NpcIntentReply in game.bridge.peek_pending_npc_intents().intents:
		waiting_ids.append(intent.npc_id)
	assert_false(trip.trader in waiting_ids, "O comerciante que parte não tem Intent pendente: o motorista dos corpos não tem o que fazer com o corpo em despedida (a simulação não é tocada).")
	assert_eq([npc.fade(), caravan.fade(), _capsule(npc).transparency, _tire(caravan).transparency], [0.0, 1.0, 0.0, 1.0], "O começo da dissolução: o NPC ainda opaco, a caravana ainda invisível.")
	var stand: Vector3 = npc.position
	var elapsed: float = 0.0
	for step: int in 3:
		game.driver.advance(STEP_S)
		game.npc_bodies.advance_departures(STEP_S)
		caravan.advance_fade(STEP_S)
		elapsed += STEP_S
		assert_almost_eq(npc.fade(), PresenceFade.out_amount(elapsed), EPS, "O NPC some na curva.")
		assert_almost_eq(caravan.fade(), PresenceFade.in_amount(elapsed), EPS, "A caravana aparece na curva.")
		assert_almost_eq(npc.fade() + caravan.fade(), 1.0, EPS, "Dissolução CRUZADA: as duas transparências somam 1 a cada instante.")
		assert_almost_eq(_capsule(npc).transparency, npc.fade(), EPS, "A cápsula do NPC de fato.")
		assert_almost_eq(_tire(caravan).transparency, caravan.fade(), EPS, "E a roda da caravana de fato.")
		assert_eq(npc.position, stand, "O corpo do NPC fica ONDE ESTAVA.")
		if step == 1:
			assert_almost_eq(npc.fade(), 0.5, EPS, "Aos 0,2 s os dois estão a meio caminho (0,5).")
			assert_almost_eq(caravan.fade(), 0.5, EPS, "(a caravana também).")
	game.npc_bodies.advance_departures(2.0 * STEP_S)
	caravan.advance_fade(2.0 * STEP_S)
	assert_null(game.npc_bodies.pool().body_of(trip.trader), "Aos 0,4 s o corpo do NPC voltou à reserva: só resta a caravana.")
	assert_eq([game.npc_bodies.fading_ids(), game.npc_bodies.pool().active_count(), game.npc_bodies.pool().lost_count()], [[] as Array[int], trip.active_after - 1, 0], "Sem despedida, um corpo a menos e nada perdido.")
	assert_eq([npc.fade(), npc.visible], [0.0, false], "O corpo devolvido está opaco e escondido (a reserva não guarda transparência).")
	assert_eq([caravan.fade(), _tire(caravan).transparency, caravan.is_processing(), caravan.visible], [0.0, 0.0, false, true], "A caravana ficou opaca, visível e sem `_process`.")
	assert_same(game.caravan_bodies.body_of(trip.trader), caravan, "É o mesmo corpo de caravana de antes.")


func test_with_the_option_off_the_departure_is_the_pop_of_today_and_the_simulation_is_identical() -> void:
	var off: Trip = _start_trip(false)
	var on: Trip = _start_trip(true)
	assert_null(off.game.npc_bodies.pool().body_of(off.trader), "Desligada: o corpo do NPC já voltou à reserva no quadro da partida, como antes.")
	assert_eq([off.game.npc_bodies.fading_ids(), off.returned_in_frame], [[] as Array[int], 1], "Sem despedida, e um corpo devolvido nesse quadro (medido antes: 1).")
	assert_true(off.game.caravan_bodies.body_of(off.trader).visible, "E a caravana já está na tela.")
	assert_almost_eq(off.npc_spot.distance_to(off.first_spot), POP_BEFORE_M, POP_TOLERANCE_M, "O pulo é o de antes (2,549 m): a pose da caravana não mudou.")
	assert_eq(on.first_spot, off.first_spot, "A primeira pose da caravana é a mesma com a despedida ligada.")
	assert_eq([on.minute, on.u, on.state_hash], [off.minute, off.u, off.state_hash], "O instante da partida, o `u` e o `state_hash` são os mesmos com a despedida ligada e desligada.")
	var walked: int = 0
	for minutes: int in COMPARE_MINUTES:
		var with_fade: Array = _walk(on, minutes - walked)
		var without_fade: Array = _walk(off, minutes - walked)
		walked = minutes
		assert_eq(with_fade, without_fade, "Passados %d minutos da partida o `state_hash` e o `u` seguem iguais com e sem a despedida." % minutes)
		assert_gt(with_fade[1], 0.0, "(e a caravana ainda está na estrada)")
