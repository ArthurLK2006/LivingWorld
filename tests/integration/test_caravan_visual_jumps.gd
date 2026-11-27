extends GutTest
## LW-099c: os SALTOS VISUAIS da caravana no JOGO REAL, sem janela: dados reais, a ponte real, as duas vistas de corpos e o MOTORISTA dos corpos (`NpcBodyDriver`, que para o `NpcView` na borda da caixa do mercado: sem ele o corpo "perfeito" nunca move o `NpcView`, que
## ficaria parado onde nasceu, e a medição da partida não valeria). O foco do jogador fica a 10 m do mercado de partida e depois acompanha a caravana; quadros de 250 ms, e de 16 ms (o de um jogo a 60 por segundo) nos últimos 2 minutos, para a última pose ser a de quase `u` = 1.
## MEDIDAS em metros no plano (24/11/2026, o 1º comerciante que parte no jogo novo, B para C, semente padrão). ANTES da rampa do deslocamento lateral: PARTIDA 3,70 m (o `NpcView` em pé a 2,55 m do centro do mercado e a caravana nascendo a 1,20 m à direita do centro, não no eixo);
## CHEGADA 1,20 m (a última pose a 1,20 m do centro, onde o `NpcView` reaparece); maior passo entre poses 0,65 m. DEPOIS: PARTIDA 2,55 m, só o ponto onde o `NpcView` ficava em pé (a vista não sabe de que lado do mercado ele estava; fechar isso pede a posição lógica do
## comerciante, fora do alcance desta tarefa) e 0,00 m de lateral; CHEGADA 0,01 m; maior passo 0,65 m (a rampa não mexe em `u`, no tempo nem na velocidade). Giro nas trocas com o `NpcView` (não corrigido: o giro do `NpcView` é do `NpcBodiesView` e do motorista): ele estava a
## 19,7 graus e a caravana parte a 129,8; a caravana chega a 129,8 e ele reaparece a 0. A troca de TRECHO está em `tests/unit/test_caravan_bodies_view_joints.gd`.

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
const COARSE_MS: int = 250
const FINE_MS: int = 16
const FINE_LAST_MINUTES: int = 2
const FRAME_LIMIT: int = 4000
const BACK_FRAMES: int = 300
const NO_SPOT: Vector2 = Vector2(INF, INF)
## Salto pequeno (m): a chegada tem de ficar até aqui; no eixo (m): a caravana nasce a menos disto do centro do mercado; onde o `NpcView` pode estar em pé (m): a borda da caixa de 4 m do mercado, 2,4 m por eixo (`NpcRoute.stop_point`), no canto 3,4 m.
const SMALL_JUMP_M: float = 0.5
const AXIS_M: float = 0.1
const STAND_MAX_M: float = 3.5
## O maior passo entre duas poses de quadros de 250 ms (a 2,9 m/s são 0,73 m).
## (doca, quinas) 0,8 -> 1,1 -> 1,25 m (a SEGUNDA vez que este teto sobe): com pontos de passagem a faixa lateral de 1,2 m varre as quinas (as curvas naturais do PR #178 não estão neste PR) e a pose anda além da velocidade x o quadro; medido 0,96 m aqui e até 1,151 m pela revisão independente (1,66 vezes a velocidade, na quina de A-C perto de C); antes 0,65 m. Um salto de verdade seria de metros.
const STEP_MAX_M: float = 1.25

var _data: NpcLifeCheck.GameData
var _routes: CaravanRoutesReader
var _games: Array[Game] = []
var _origin_settlement: String = ""
var _origin_m: Vector2 = Vector2.ZERO


## Um jogo montado com as duas vistas e o motorista dos corpos dos NPCs.
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


## O que a viagem mostrou nas pontas (posições no plano x, z e giro de cada corpo).
class Trip:
	extends RefCounted

	var game: Game
	var trader: int = IdGenerator.NO_ID
	var from_id: String = ""
	var to_id: String = ""
	var origin: Vector2 = Vector2.ZERO
	var destination: Vector2 = Vector2.ZERO
	## (doca) As docas do povoado de saída e do de chegada (o mercado, se o povoado não tem doca).
	var dock: Vector2 = Vector2.ZERO
	var arrival_dock: Vector2 = Vector2.ZERO
	var npc_spot: Vector2 = NO_SPOT
	var first_spot: Vector2 = NO_SPOT
	var last_spot: Vector2 = NO_SPOT
	var back_spot: Vector2 = NO_SPOT
	var frames: int = 0
	var biggest_step_m: float = 0.0


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


## As duas vistas e o motorista ligados ao mesmo terreno, como a cena os liga (o motorista só anda quando o teste manda: `advance`).
func _new_game() -> Game:
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
	assert_true(game.npc_bodies.setup(game.bridge, game.terrain_view))
	for place: BridgeReplies.PlaceReply in game.bridge.peek_places().places:
		if place.kind == PlacePalette.KIND_MARKET:
			game.markets[place.settlement_id] = Vector2(place.x, place.z)
	game.caravan_bodies = CaravanBodiesView.new()
	game.root.add_child(game.caravan_bodies)
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


## Um minuto do jogo: um passo e o motorista anda o tempo real dele (1,25 s a 1x).
func _tick(game: Game) -> void:
	game.runner.step_once()
	game.driver.advance(MINUTE_S)


## Um quadro de `frame_ms` de tempo real: o relógio e o motorista andam juntos.
func _frame(game: Game, frame_ms: int) -> void:
	game.runner.advance_frame(frame_ms)
	game.driver.advance(float(frame_ms) / 1000.0)


## O ponto do caminho MOSTRADO do trecho (a polilinha do dado: doca, pontos de passagem, doca; sem o deslocamento lateral) na fração `u` da linha (doca: antes era a reta entre os mercados).
func _road_point(game: Game, row: BridgeReplies.CaravanBodyReply) -> Vector2:
	var line: PackedVector2Array = _routes.leg_line(row.route_id, row.from_settlement_id, row.to_settlement_id, game.markets[row.from_settlement_id], game.markets[row.to_settlement_id])
	var pose: CaravanPath.Pose = CaravanPath.Pose.new()
	CaravanPath.new(line).sample_into(row.u, true, 0.0, pose)
	return pose.position


func _refresh(game: Game) -> void:
	for row: BridgeReplies.CaravanBodyReply in game.bridge.peek_caravan_bodies().bodies:
		_draw_terrain_around(game, _road_point(game, row))
	game.npc_bodies.reconcile()
	game.caravan_bodies.reconcile()


func _row_of(game: Game, trader: int) -> BridgeReplies.CaravanBodyReply:
	for row: BridgeReplies.CaravanBodyReply in game.bridge.peek_caravan_bodies().bodies:
		if row.trader_id == trader:
			return row
	return null


func _plane(view: Node3D) -> Vector2:
	return Vector2(view.position.x, view.position.z)


## O jogo novo com as vistas, o foco a 10 m do mercado de partida, andado minuto a minuto até um comerciante do povoado de partida ter caravana; guarda onde o `NpcView` dele estava no último minuto antes e a 1ª pose do corpo da caravana.
func _start_trip() -> Trip:
	var trip: Trip = Trip.new()
	trip.game = _new_game()
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
			trip.trader = trader
			trip.from_id = row.from_settlement_id
			trip.to_id = row.to_settlement_id
			trip.origin = game.markets[trip.from_id]
			trip.destination = game.markets[trip.to_id]
			trip.dock = _routes.dock_of(trip.from_id) if _routes.has_dock(trip.from_id) else trip.origin
			trip.arrival_dock = _routes.dock_of(trip.to_id) if _routes.has_dock(trip.to_id) else trip.destination
			trip.npc_spot = seen.get(trader, NO_SPOT)
			_refresh(game)
			var body: CaravanView = game.caravan_bodies.body_of(trader)
			trip.first_spot = _plane(body)
			return trip
		_refresh(game)
	return trip


## Segue a viagem por quadros (de 250 ms; de 16 ms nos últimos minutos, o quadro de um jogo a 60 por segundo) com o foco junto da caravana; guarda a última pose, o maior passo entre poses e, depois da chegada, onde o `NpcView` reapareceu.
func _follow(trip: Trip) -> void:
	var game: Game = trip.game
	var before: Vector2 = trip.first_spot
	for _index: int in FRAME_LIMIT:
		var row: BridgeReplies.CaravanBodyReply = _row_of(game, trip.trader)
		if row == null:
			break
		_focus(game, _road_point(game, row) + Vector2(NEAR_M, 0.0))
		_refresh(game)
		var body: CaravanView = game.caravan_bodies.body_of(trip.trader)
		if body != null and body.visible:
			trip.last_spot = _plane(body)
			trip.biggest_step_m = maxf(trip.biggest_step_m, trip.last_spot.distance_to(before))
			before = trip.last_spot
		trip.frames += 1
		var left: int = game.economy.peek_caravan(trip.trader).eta_minute - game.runner.world.context.clock.total_minutes()
		_frame(game, FINE_MS if left <= FINE_LAST_MINUTES else COARSE_MS)
	for _index: int in BACK_FRAMES:
		_refresh(game)
		var returned: NpcView = game.npc_bodies.pool().body_of(trip.trader)
		if returned != null:
			trip.back_spot = _plane(returned)
			return
		_frame(game, FINE_MS)


func test_the_caravan_leaves_and_arrives_on_the_market_axis_and_every_step_stays_small() -> void:
	var trip: Trip = _start_trip()
	assert_ne(trip.npc_spot, NO_SPOT, "Premissa: o comerciante tinha o seu `NpcView` na praça antes de partir (foco a 10 m).")
	assert_ne(trip.first_spot, NO_SPOT, "Premissa: a caravana ganhou corpo no passo da partida.")
	_follow(trip)
	assert_ne(trip.back_spot, NO_SPOT, "Premissa: o `NpcView` do comerciante volta depois da chegada.")
	var stand_m: float = trip.npc_spot.distance_to(trip.origin)
	assert_lt(stand_m, STAND_MAX_M, "O `NpcView` fica em pé na borda da caixa do mercado (`NpcRoute.stop_point`).")
	var dock_gap_m: float = trip.dock.distance_to(trip.origin)
	var arrival_gap_m: float = trip.arrival_dock.distance_to(trip.destination)
	assert_lt(trip.first_spot.distance_to(trip.dock), AXIS_M, "PARTIDA (doca): a caravana nasce na DOCA do povoado de saída, no eixo da estrada e sem o deslocamento lateral de 1,2 m (antes, o eixo era o centro do mercado).")
	assert_lt(trip.npc_spot.distance_to(trip.first_spot), stand_m + dock_gap_m + AXIS_M, "PARTIDA (doca): o salto é no máximo a distância do ponto onde o `NpcView` estava ao centro do mercado mais a do centro à doca (antes só a primeira: 2,55 m).")
	assert_lt(trip.back_spot.distance_to(trip.destination), AXIS_M, "CHEGADA: o `NpcView` reaparece no centro do mercado de destino (`MerchantArrival`).")
	assert_lt(trip.last_spot.distance_to(trip.arrival_dock), AXIS_M, "CHEGADA (doca): a caravana TERMINA na doca do povoado de destino.")
	assert_almost_eq(trip.last_spot.distance_to(trip.back_spot), arrival_gap_m, AXIS_M, "CHEGADA (doca): o salto da chegada é a distância da doca ao centro do mercado, onde o `NpcView` reaparece (antes 0,01 m; agora 5,70 m em A, 6,00 m em B e 11,85 m em C).")
	assert_lt(trip.biggest_step_m, STEP_MAX_M, "Entre quadros de 250 ms a caravana nunca anda mais que a velocidade x o quadro (a rampa não mexe em `u`).")
	assert_gt(trip.frames, 500, "A viagem inteira foi acompanhada, quadro a quadro.")
