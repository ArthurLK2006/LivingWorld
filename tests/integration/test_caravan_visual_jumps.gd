extends GutTest
## LW-099c: os SALTOS VISUAIS da caravana no JOGO REAL, sem janela: dados reais, a ponte real, as duas vistas de corpos e o MOTORISTA dos corpos (`NpcBodyDriver`, que para o `NpcView` na borda da caixa do mercado: sem ele o corpo "perfeito" nunca move o `NpcView`, que
## ficaria parado onde nasceu, e a medição da partida não valeria). O foco do jogador fica a 10 m do mercado de partida e depois acompanha a caravana; quadros de 250 ms, e de 16 ms (o de um jogo a 60 por segundo) nos últimos 2 minutos, para a última pose ser a de quase `u` = 1.
## MEDIDAS em metros no plano (24/11/2026, o 1º comerciante que parte no jogo novo, B para C, semente padrão). ANTES da rampa do deslocamento lateral: PARTIDA 3,70 m (o `NpcView` em pé a 2,55 m do centro do mercado e a caravana nascendo a 1,20 m à direita do centro, não no eixo);
## CHEGADA 1,20 m (a última pose a 1,20 m do centro, onde o `NpcView` reaparece); maior passo entre poses 0,65 m. DEPOIS DA RAMPA: PARTIDA 2,55 m, só o ponto onde o `NpcView` ficava em pé (o `peek_npc_detail` dá o centro LÓGICO do mercado, 807,00 e 653,00, e não o do corpo, 807,86 e 655,40: medido) e 0,00 m de lateral; CHEGADA 0,01 m; maior passo 0,65 m (a rampa não mexe em `u`, no tempo nem na velocidade). Giro nas trocas com o `NpcView` (não corrigido: o giro do `NpcView` é do `NpcBodiesView` e do motorista): ele estava a
## 19,7 graus e a caravana parte a 129,8; a caravana chega a 129,8 e ele reaparece a 0. A troca de TRECHO está em `tests/unit/test_caravan_bodies_view_joints.gd`.
## COM A ÂNCORA DA PARTIDA (a `NpcBodiesView` passada ao `setup`, como a cena faz; ela guarda onde cada corpo ficou em pé ao ser devolvido): PARTIDA 0,00 m (a 1ª pose sai do ponto onde o `NpcView` estava em pé, a 2,55 m do centro, e o deslocamento some em linha reta nos primeiros 12 m); CHEGADA 0,01 m e
## maior passo 0,65 m (iguais); o corpo nunca recua ao longo da estrada e a largura máxima ao eixo é 2,39 m (o deslocamento inicial, que desce até os 1,2 m). Sem a âncora (`Mode.VIEW`, o `setup` de antes) a partida segue a de antes: 2,55 m.

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
const STEP_MAX_M: float = 0.8
const LATERAL_M: float = 1.2
## O corpo nunca anda para trás ao longo da estrada: a folga é só de arredondamento.
const BACK_TOLERANCE_M: float = 0.001
## A 1ª pose da âncora está no ponto onde o `NpcView` estava em pé: só arredondamento.
const ON_SPOT_M: float = 0.001
## Mais que a maior viagem (143 minutos).
const TRIP_MINUTES_MAX: int = 400
const HASH_EVERY: int = 10
const HASH_FRAME_MS: int = 500
const RUN_FRAME_LIMIT: int = 20000

## Como o jogo é montado: sem a vista das caravanas, com ela e sem a âncora da partida (o `setup` de antes), e com ela e a âncora (a `NpcBodiesView` passada ao `setup`, como a cena faz).
enum Mode { NO_VIEW, VIEW, ANCHORED }

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
	var npc_spot: Vector2 = NO_SPOT
	var first_spot: Vector2 = NO_SPOT
	var last_spot: Vector2 = NO_SPOT
	var back_spot: Vector2 = NO_SPOT
	var frames: int = 0
	var biggest_step_m: float = 0.0
	var axis: Vector2 = Vector2.ZERO
	var worst_back_m: float = 0.0
	var widest_m: float = 0.0


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
func _new_game(mode: Mode = Mode.ANCHORED) -> Game:
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
	if mode != Mode.NO_VIEW:
		game.caravan_bodies = CaravanBodiesView.new()
		game.root.add_child(game.caravan_bodies)
		assert_true(game.caravan_bodies.setup(game.bridge, game.terrain_view, _routes, game.npc_bodies if mode == Mode.ANCHORED else null))
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


func _road_point(game: Game, row: BridgeReplies.CaravanBodyReply) -> Vector2:
	return game.markets[row.from_settlement_id].lerp(game.markets[row.to_settlement_id], row.u)


## O que o quadro faz: a vista dos NPCs e depois a das caravanas (a ordem da cena); `caravans_first` inverte (a das caravanas consulta ANTES da dos NPCs devolverem o corpo de quem partiu).
func _refresh(game: Game, caravans_first: bool = false) -> void:
	for row: BridgeReplies.CaravanBodyReply in game.bridge.peek_caravan_bodies().bodies:
		_draw_terrain_around(game, _road_point(game, row))
	if caravans_first and game.caravan_bodies != null:
		game.caravan_bodies.reconcile()
	game.npc_bodies.reconcile()
	if not caravans_first and game.caravan_bodies != null:
		game.caravan_bodies.reconcile()


func _row_of(game: Game, trader: int) -> BridgeReplies.CaravanBodyReply:
	for row: BridgeReplies.CaravanBodyReply in game.bridge.peek_caravan_bodies().bodies:
		if row.trader_id == trader:
			return row
	return null


func _plane(view: Node3D) -> Vector2:
	return Vector2(view.position.x, view.position.z)


## O jogo novo com as vistas, o foco a 10 m do mercado de partida, andado minuto a minuto até um comerciante do povoado de partida ter caravana; guarda onde o `NpcView` dele estava no último minuto antes e a 1ª pose do corpo da caravana.
func _start_trip(mode: Mode = Mode.ANCHORED, caravans_first: bool = false) -> Trip:
	var trip: Trip = Trip.new()
	trip.game = _new_game(mode)
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
			trip.axis = (trip.destination - trip.origin).normalized()
			trip.npc_spot = seen.get(trader, NO_SPOT)
			_refresh(game, caravans_first)
			var body: CaravanView = game.caravan_bodies.body_of(trader)
			trip.first_spot = _plane(body)
			return trip
		_refresh(game)
	return trip


## Segue a viagem por quadros (de 250 ms; de 16 ms nos últimos minutos, o quadro de um jogo a 60 por segundo) com o foco junto da caravana; guarda a última pose, o maior passo entre poses e, depois da chegada, onde o `NpcView` reapareceu.
func _follow(trip: Trip) -> void:
	var game: Game = trip.game
	var before: Vector2 = trip.first_spot
	var progress_m: float = (before - trip.origin).dot(trip.axis)
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
			var along_m: float = (before - trip.origin).dot(trip.axis)
			trip.worst_back_m = maxf(trip.worst_back_m, progress_m - along_m)
			progress_m = along_m
			trip.widest_m = maxf(trip.widest_m, absf((before - trip.origin).cross(trip.axis)))
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


## Uma execução inteira até o fim da 1ª viagem, por quadros de 500 ms com o motorista, no `mode` pedido; devolve o `state_hash` a cada 10 minutos e no fim, os contadores da reserva dos NPCs e quantos corpos de caravana a vista retirou.
func _run(mode: Mode) -> Array:
	var game: Game = _new_game(mode)
	_focus(game, _origin_m + Vector2(NEAR_M, 0.0))
	_draw_terrain_around(game, _origin_m)
	var rows: Array[String] = []
	var last_minute: int = -HASH_EVERY
	var has_travelled: bool = false
	for _index: int in RUN_FRAME_LIMIT:
		_frame(game, HASH_FRAME_MS)
		_refresh(game)
		var minute: int = game.runner.world.context.clock.total_minutes()
		if minute >= last_minute + HASH_EVERY:
			last_minute = minute
			rows.append("%d %s" % [minute, game.runner.world.state_hash()])
		var is_travelling: bool = not game.economy.peek_caravans().caravans.is_empty()
		has_travelled = has_travelled or is_travelling
		if has_travelled and not is_travelling:
			break
	rows.append("fim " + game.runner.world.state_hash())
	var pool: NpcViewPool = game.npc_bodies.pool()
	return [rows, [pool.created, pool.taken, pool.returned, pool.peak_active, pool.empty_hits, pool.duplicate_requests], game.caravan_bodies.pool().taken if game.caravan_bodies != null else 0]


func test_with_the_anchor_the_caravan_leaves_from_where_the_merchant_stood_arrives_on_the_axis_and_never_walks_backwards() -> void:
	var trip: Trip = _start_trip(Mode.ANCHORED)
	assert_ne(trip.npc_spot, NO_SPOT, "Premissa: o comerciante tinha o seu `NpcView` na praça antes de partir (foco a 10 m).")
	assert_ne(trip.first_spot, NO_SPOT, "Premissa: a caravana ganhou corpo no passo da partida.")
	assert_eq(trip.game.npc_bodies.standing_spot_of(trip.trader), NpcBodiesView.NO_SPOT, "O ponto em pé do comerciante foi lido UMA vez e esquecido: depois da partida não sobra entrada dele.")
	_follow(trip)
	assert_ne(trip.back_spot, NO_SPOT, "Premissa: o `NpcView` do comerciante volta depois da chegada.")
	var stand_m: float = trip.npc_spot.distance_to(trip.origin)
	assert_between(stand_m, SMALL_JUMP_M, STAND_MAX_M, "Premissa: o `NpcView` ficou em pé a mais de 0,5 m do centro, na borda da caixa do mercado: sem a âncora o salto da partida seria deste tamanho (2,55 m).")
	assert_lt(trip.npc_spot.distance_to(trip.first_spot), ON_SPOT_M, "PARTIDA: a 1ª pose da caravana está no ponto onde o `NpcView` estava em pé, muito dentro dos 0,5 m (sem âncora 2,55 m; antes da rampa 3,70 m).")
	assert_lt(trip.back_spot.distance_to(trip.destination), AXIS_M, "CHEGADA: o `NpcView` reaparece no centro do mercado de destino (`MerchantArrival`).")
	assert_lt(trip.last_spot.distance_to(trip.back_spot), SMALL_JUMP_M, "CHEGADA: a última pose da caravana fica a menos de 0,5 m de onde o `NpcView` reaparece (não piora com a âncora).")
	assert_lt(trip.biggest_step_m, STEP_MAX_M, "Entre quadros de 250 ms a caravana nunca anda mais que a velocidade x o quadro (a âncora e a rampa não mexem em `u`).")
	assert_lt(trip.worst_back_m, BACK_TOLERANCE_M, "A rampa lateral e a âncora juntas nunca fazem o corpo andar para trás ao longo da estrada.")
	assert_lt(trip.widest_m, LATERAL_M + stand_m + AXIS_M, "E o corpo nunca passa de 1,2 m + o deslocamento inicial do eixo da estrada.")
	assert_gt(trip.frames, 500, "A viagem inteira foi acompanhada, quadro a quadro.")


func test_without_the_npc_bodies_view_in_setup_the_caravan_leaves_from_the_market_axis_as_before() -> void:
	var trip: Trip = _start_trip(Mode.VIEW)
	assert_ne(trip.npc_spot, NO_SPOT, "Premissa: o comerciante tinha o seu `NpcView` na praça antes de partir.")
	var stand_m: float = trip.npc_spot.distance_to(trip.origin)
	assert_lt(trip.first_spot.distance_to(trip.origin), AXIS_M, "Sem a `NpcBodiesView` no `setup` (o padrão): sem âncora, a caravana sai do EIXO, o centro do mercado, como antes.")
	assert_almost_eq(trip.npc_spot.distance_to(trip.first_spot), stand_m, AXIS_M, "E o salto da partida é o de antes: a distância do ponto em pé ao centro (2,55 m).")
	assert_false(trip.game.npc_bodies.tracks_last_spots(), "Sem a âncora a `NpcBodiesView` não rastreia nada: o caminho dos NPCs é o de sempre.")


func test_the_view_and_the_tracking_change_nothing_the_state_hash_and_the_npc_counters_are_the_same() -> void:
	var anchored: Array = _run(Mode.ANCHORED)
	var viewing: Array = _run(Mode.VIEW)
	var silent: Array = _run(Mode.NO_VIEW)
	assert_gt(anchored[2], 0, "A vista retirou corpos de caravana durante a viagem (o teste não rodou no vazio).")
	assert_gt(anchored[0].size(), 3, "Vários instantes conferidos, a viagem inteira.")
	assert_eq(anchored[0], silent[0], "O mesmo `state_hash` a cada 10 minutos e no fim, com a vista e o rastreio e sem a vista.")
	assert_eq(viewing[0], silent[0], "E com a vista sem o rastreio.")
	assert_eq(anchored[1], silent[1], "Os contadores da reserva dos NPCs (criados, retirados, devolvidos, pico, reserva vazia, duplicados) são os mesmos com e sem o rastreio.")
	assert_eq(viewing[1], silent[1], "E com a vista sem o rastreio.")


func test_a_spot_stored_after_the_caravan_was_first_seen_still_anchors_it_and_goes_away_when_it_arrives() -> void:
	var trip: Trip = _start_trip(Mode.ANCHORED, true)
	var game: Game = trip.game
	assert_ne(trip.npc_spot, NO_SPOT, "Premissa: o comerciante tinha o seu `NpcView` na praça antes de partir.")
	assert_lt(trip.npc_spot.distance_to(trip.first_spot), ON_SPOT_M, "Na ordem inversa (a vista das caravanas consulta ANTES da dos NPCs) a âncora vale do mesmo jeito: lê o corpo que ainda existe.")
	assert_eq(game.npc_bodies.standing_spot_of(trip.trader), trip.npc_spot, "Depois de a vista dos NPCs devolver o corpo, o ponto em pé ficou guardado (a vista das caravanas já tinha passado).")
	var arrived: bool = false
	for _minute: int in TRIP_MINUTES_MAX:
		_tick(game)
		if _row_of(game, trip.trader) == null:
			arrived = true
			break
		_refresh(game)
	assert_true(arrived, "Premissa: a viagem terminou (com o foco parado no mercado de partida: o destino fica a mais de 120 m e o NPC não volta a ter corpo).")
	assert_eq(game.npc_bodies.standing_spot_of(trip.trader), trip.npc_spot, "No passo da chegada, antes de a vista das caravanas passar, a entrada da partida ainda está lá.")
	game.caravan_bodies.reconcile()
	assert_eq(game.npc_bodies.standing_spot_of(trip.trader), NpcBodiesView.NO_SPOT, "Assim que a vista das caravanas vê a chegada a entrada some (só esta chamada a apaga: o NPC chegou longe e não ganha corpo).")
	assert_null(game.npc_bodies.pool().body_of(trip.trader), "E ele não tem corpo: nada mais teria apagado a entrada.")
