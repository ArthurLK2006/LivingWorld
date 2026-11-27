extends GutTest
## LW-099h (chegada suave; só apresentação): o comerciante que chega reaparece ONDE A CARAVANA TERMINOU (a doca) e caminha até o mercado, no JOGO REAL e sem janela: dados reais (com as docas da LW-099g), economia e rotas, os 6 comerciantes, a ponte real, as duas vistas de corpos ligadas
## como a cena as liga (`set_arrival_spots`) e o MOTORISTA REAL (`NpcBodyDriver`) levando os corpos. O foco do jogador acompanha o carrinho a 10 m, então ele vê a chegada. Mede, na 1ª viagem: onde o `NpcView` nasce (na doca, a 5,70 a 11,85 m do centro do mercado), quanto ele anda
## até a borda do mercado, e que NUNCA há dois corpos do comerciante. E NADA MUDA: o `state_hash` é o mesmo com a ligação e sem ela, com o corpo perfeito e com o motorista real (a posição do corpo só vira a posição lógica do NPC quando ele SAI de S0, `NpcLod.report_position`: o estado depois disso guarda onde o corpo parou); o corpo só nasce em outro lugar.

const DATA_DIR: String = "res://data"
const WORLD_DIR: String = "res://data/world"
const GAME_VERSION: String = "0.0.1-test"
const MERCHANT: String = "merchant"
const ACTOR_ID: int = 1000
const DAY: int = SimClock.MINUTES_PER_DAY
const SEARCH_LIMIT: int = 3 * DAY
const TRIP_LIMIT: int = 1500
const CM_PER_M: float = 100.0
const CHUNK_M: float = 64.0
const GROUND_M: float = 10.0
const NEAR_M: float = 10.0
const FAR_SPOT_M: Vector2 = Vector2(130.0, 130.0)
## Depois da chegada: quadros de 100 ms (60 s reais a 1x) e o prazo, em minutos de jogo, para o `NpcView` voltar (o passo seguinte, mais folga).
const FRAME_MS: int = 100
const WALK_FRAMES: int = 600
const BACK_WITHIN_MINUTES: float = 3.0
const MS_PER_MINUTE: float = 1250.0
const HASH_EVERY: int = 10
const DOCK_MIN_M: float = 5.6
const DOCK_MAX_M: float = 12.0 + 0.001
const SAME_SPOT_M: float = 0.01
## Tolerância (m) da posição de parada e da distância andada (os quadros de 100 ms e o passo de 0,4 m).
const WALK_TOLERANCE_M: float = 0.1

var _data: NpcLifeCheck.GameData
var _routes: CaravanRoutesReader
var _games: Array[Game] = []


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


## O que uma execução mediu: os hashes, onde e quando o `NpcView` do comerciante nasceu depois da chegada, quanto andou, onde parou e o pior número de corpos dele.
class Outcome:
	extends RefCounted

	var hashes: Array[String] = []
	var trader: int = IdGenerator.NO_ID
	var dock_m: Vector2 = Vector2.ZERO
	var market_m: Vector2 = Vector2.ZERO
	var born: Vector3 = Vector3(NAN, NAN, NAN)
	var born_after_ms: int = -1
	var walked_m: float = 0.0
	var stopped: Vector3 = Vector3(NAN, NAN, NAN)
	var worst_bodies: int = 0


func before_all() -> void:
	_data = NpcLifeCheck.load_game_data()
	assert_eq(_data.problem, "", "Os dados reais do jogo carregam.")
	var routes: CaravanRoutesReader.LoadResult = CaravanRoutesReader.from_file()
	assert_true(routes.result.ok, routes.result.message)
	_routes = routes.data
	for settlement_id: String in ["test_settlement_a", "test_settlement_b", "test_settlement_c"]:
		assert_true(_routes.has_dock(settlement_id), "Premissa: o dado real tem a doca do povoado %s (LW-099g)." % settlement_id)


func after_each() -> void:
	for game: Game in _games:
		game.caravan_bodies.release()
		game.npc_bodies.release()
		game.driver.free()
		game.runner.finish()
		game.host.free()
	_games.clear()


## O jogo montado como o `GameApp` monta, a ponte real sobre um host de teste, as duas vistas e o motorista ligados (`wired` falso: sem a fonte dos pontos de chegada, o jogo de antes).
func _new_game(wired: bool) -> Game:
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
	game.driver = NpcBodyDriver.new()
	assert_true(game.driver.setup(game.bridge, game.npc_bodies))
	game.caravan_bodies = CaravanBodiesView.new()
	game.root.add_child(game.caravan_bodies)
	assert_true(game.caravan_bodies.setup(game.bridge, game.terrain_view, _routes))
	if wired:
		game.npc_bodies.set_arrival_spots(game.caravan_bodies.take_arrival_spot)
	for place: BridgeReplies.PlaceReply in game.bridge.peek_places().places:
		if place.kind == PlacePalette.KIND_MARKET:
			game.markets[place.settlement_id] = Vector2(place.x, place.z)
	return game


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


## O corpo perfeito: cumpre cada Intent pendente no fim previsto, no destino (sem motorista, o canal de posições da LW-072 não é usado).
func _answer_due(game: Game) -> void:
	var now: int = game.runner.world.context.clock.total_minutes()
	for intent: NpcIntent in game.npc.peek_pending_intents():
		if now < game.npc.peek_npc(intent.npc_id).action_ends_at:
			continue
		var outcome: NpcActionResult.Outcome = NpcActionResult.Outcome.ARRIVED if intent.kind == NpcIntent.Kind.MOVE_TO_PLACE else NpcActionResult.Outcome.DONE
		var spot_m: Vector3 = Vector3(intent.destination_cm.x / CM_PER_M, 0.0, intent.destination_cm.y / CM_PER_M)
		var reported: Result = game.npc.request_report_npc_result(NpcActionResult.new(intent.npc_id, intent.action_serial, outcome, spot_m))
		assert_true(reported.ok or reported.code == ActionRunner.CODE_ACTION_FAILED, reported.message)


func _row_of(game: Game, trader: int) -> BridgeReplies.CaravanBodyReply:
	for row: BridgeReplies.CaravanBodyReply in game.bridge.peek_caravan_bodies().bodies:
		if row.trader_id == trader:
			return row
	return null


## O ponto do caminho mostrado do trecho na fração `u` da linha (sem o deslocamento lateral).
func _road_point(game: Game, row: BridgeReplies.CaravanBodyReply) -> Vector2:
	var line: PackedVector2Array = _routes.leg_line(row.route_id, row.from_settlement_id, row.to_settlement_id, game.markets[row.from_settlement_id], game.markets[row.to_settlement_id])
	var pose: CaravanPath.Pose = CaravanPath.Pose.new()
	CaravanPath.new(line).sample_into(row.u, true, 0.0, pose)
	return pose.position


## Quantos corpos VISÍVEIS o comerciante tem na árvore inteira: o `NpcView` dele e o `CaravanView` dele (com o `NpcView` filho, que tem `npc_id` NO_ID, contado pelo pai).
func _bodies_of(node: Node, trader: int) -> int:
	var count: int = 0
	if node is NpcView and (node as NpcView).npc_id == trader and (node as NpcView).is_visible_in_tree():
		count += 1
	if node is CaravanView and (node as CaravanView).trader_id == trader and (node as CaravanView).is_visible_in_tree():
		count += 1
	for child: Node in node.get_children():
		count += _bodies_of(child, trader)
	return count


## A 1ª viagem inteira, com o foco a 10 m do carrinho (as duas vistas a cada minuto e o corpo perfeito), e depois `WALK_FRAMES` quadros de 100 ms até o comerciante reaparecer e andar. `with_driver`: o motorista real leva os corpos (e relata posições à simulação); senão o corpo perfeito.
func _run(wired: bool, with_driver: bool) -> Outcome:
	var game: Game = _new_game(wired)
	var out: Outcome = Outcome.new()
	_focus(game, FAR_SPOT_M)
	for _minute: int in SEARCH_LIMIT:
		game.runner.step_once()
		_answer_due(game)
		var rows: Array[BridgeReplies.CaravanBodyReply] = game.bridge.peek_caravan_bodies().bodies
		if not rows.is_empty():
			out.trader = rows[0].trader_id
			out.dock_m = _routes.dock_of(rows[0].to_settlement_id)
			out.market_m = game.markets[rows[0].to_settlement_id]
			break
	assert_ne(out.trader, IdGenerator.NO_ID, "Algum comerciante parte em até 3 dias (a premissa destes testes).")
	var last_minute: int = -HASH_EVERY
	for _minute: int in TRIP_LIMIT:
		var row: BridgeReplies.CaravanBodyReply = _row_of(game, out.trader)
		if row == null:
			break
		var spot_m: Vector2 = _road_point(game, row)
		_focus(game, spot_m + Vector2(NEAR_M, 0.0))
		_draw_terrain_around(game, spot_m)
		game.npc_bodies.reconcile()
		game.caravan_bodies.reconcile()
		out.worst_bodies = maxi(out.worst_bodies, _bodies_of(game.root, out.trader))
		game.runner.step_once()
		_answer_due(game)
		var minute: int = game.runner.world.context.clock.total_minutes()
		if minute >= last_minute + HASH_EVERY:
			last_minute = minute
			out.hashes.append("%d %s" % [minute, game.runner.world.state_hash()])
	assert_false(game.economy.peek_caravan(out.trader).found, "A caravana chegou (o registro sumiu).")
	var delta_s: float = float(FRAME_MS) / 1000.0
	var previous: Vector3 = Vector3(NAN, NAN, NAN)
	for frame: int in WALK_FRAMES:
		game.runner.advance_frame(FRAME_MS)
		if with_driver:
			game.driver.advance(delta_s)
		else:
			_answer_due(game)
		game.npc_bodies.reconcile()
		game.caravan_bodies.reconcile(delta_s)
		out.worst_bodies = maxi(out.worst_bodies, _bodies_of(game.root, out.trader))
		var view: NpcView = game.npc_bodies.pool().body_of(out.trader)
		if view == null:
			continue
		if not out.born.is_finite():
			out.born = view.position
			out.born_after_ms = frame * FRAME_MS
		elif previous.is_finite():
			out.walked_m += Vector2(view.position.x, view.position.z).distance_to(Vector2(previous.x, previous.z))
		previous = view.position
		out.stopped = view.position
	out.hashes.append("fim " + game.runner.world.state_hash())
	return out


func _flat(point: Vector3) -> Vector2:
	return Vector2(point.x, point.z)


func test_the_merchant_reappears_on_the_dock_and_walks_to_the_market_with_the_real_driver() -> void:
	var out: Outcome = _run(true, true)
	assert_true(out.born.is_finite(), "O `NpcView` do comerciante voltou depois da chegada.")
	assert_lt(float(out.born_after_ms), BACK_WITHIN_MINUTES * MS_PER_MINUTE, "E voltou em poucos passos (o filtro e o LOD de sempre).")
	assert_lt(_flat(out.born).distance_to(out.dock_m), SAME_SPOT_M, "Nasceu na DOCA onde a caravana terminou (e não no centro do mercado).")
	assert_between(_flat(out.born).distance_to(out.market_m), DOCK_MIN_M, DOCK_MAX_M, "A doca fica a 5,70 a 11,85 m do centro do mercado (limite do dado: 12 m): era esse o salto de antes.")
	assert_eq(out.worst_bodies, 1, "NUNCA dois corpos do comerciante, na viagem e na troca.")
	gut.p("LW-099h medido: nasceu a %.2f m do centro (doca a %.2f m), %d ms depois da chegada; andou %.2f m e parou a %.2f m do centro do mercado." % [_flat(out.born).distance_to(out.market_m), out.dock_m.distance_to(out.market_m), out.born_after_ms, out.walked_m, _flat(out.stopped).distance_to(out.market_m)])
	assert_gt(out.walked_m, 0.0, "O motorista o levou andando (ele não ficou parado na doca).")
	assert_lt(_flat(out.stopped).distance_to(out.market_m), _flat(out.born).distance_to(out.market_m), "E ele terminou mais perto do mercado do que nasceu.")
	var half_box: Vector2 = Vector2(PlacePalette.SIZES[PlacePalette.KIND_MARKET].x, PlacePalette.SIZES[PlacePalette.KIND_MARKET].z) * NpcView.HALF
	var edge: Vector2 = NpcRoute.stop_point(out.dock_m, out.market_m, half_box)
	assert_lt(_flat(out.stopped).distance_to(edge), WALK_TOLERANCE_M, "Parou na BORDA da caixa do mercado (o destino de sempre da rota N1), e não no centro.")
	assert_almost_eq(out.walked_m, out.dock_m.distance_to(edge), WALK_TOLERANCE_M, "Andou só o trecho da doca até a borda: o único acréscimo ao que se via antes.")


func test_the_state_hash_is_the_same_with_the_arrival_spots_wired_and_without() -> void:
	for with_driver: bool in [false, true]:
		var who: String = "motorista real" if with_driver else "corpo perfeito"
		var wired: Outcome = _run(true, with_driver)
		var plain: Outcome = _run(false, with_driver)
		assert_true(wired.born.is_finite() and plain.born.is_finite(), "(%s) Nas duas execuções o `NpcView` voltou (a prova não olhou para o vazio)." % who)
		assert_lt(_flat(wired.born).distance_to(wired.dock_m), SAME_SPOT_M, "(%s) Com a ligação o corpo nasceu na doca..." % who)
		assert_lt(_flat(plain.born).distance_to(plain.market_m), SAME_SPOT_M, "(%s) ...e sem ela, no centro do mercado, como antes: é a ÚNICA diferença." % who)
		assert_gt(wired.hashes.size(), 3, "(%s) Vários instantes conferidos, a viagem inteira e a caminhada." % who)
		assert_eq(wired.hashes, plain.hashes, "(%s) O mesmo `state_hash` a cada 10 minutos e no fim: onde o corpo nasce é só apresentação." % who)
		if with_driver:
			assert_gt(wired.walked_m, plain.walked_m + 1.0, "(%s) E o motorista de fato andou mais com a ligação (o teste não olhou para o vazio)." % who)
