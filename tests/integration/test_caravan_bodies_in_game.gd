extends GutTest
## LW-099b2b: a VISTA das caravanas (`CaravanBodiesView`) no JOGO REAL, sem janela: dados reais, economia e rotas, os 6 comerciantes, a ponte real e as DUAS vistas de corpos (`NpcBodiesView` e `CaravanBodiesView`) ligadas ao mesmo terreno, montadas como em
## `test_merchant_ghost_body.gd` (um host com `runner`, `npc` e `economy`; o corpo "perfeito" cumpre cada Intent no fim previsto). Confere, por MINUTO da viagem: a caravana nasce junto do mercado de saída, anda a estrada em passos que casam com
## `length_m ÷ leg_minutes` e some na chegada (o corpo volta no passo em que o registro some, e o `NpcView` volta); NUNCA dois corpos do mesmo comerciante, contados pelos `NpcView` VISÍVEIS da árvore inteira (o filho do `CaravanView` tem `npc_id` NO_ID e conta
## pelo `trader_id` do pai); com o foco longe nenhum dos dois; salvar e carregar no meio da viagem (o corpo volta até 1 passo atrás); e NADA MUDA: o `state_hash` é o mesmo com a vista rodando e sem ela.

const DATA_DIR: String = "res://data"
const WORLD_DIR: String = "res://data/world"
const GAME_VERSION: String = "0.0.1-test"
const MERCHANT: String = "merchant"
const ACTOR_ID: int = 1000
const DAY: int = SimClock.MINUTES_PER_DAY
## Prazo para algum comerciante partir (o jogo real o faz no 1º dia) e para a viagem acabar; passou disso, a premissa mudou.
const SEARCH_LIMIT: int = 3 * DAY
const TRIP_LIMIT: int = 1500
const CM_PER_M: float = 100.0
const CHUNK_M: float = 64.0
const GROUND_M: float = 10.0
const NEAR_M: float = 10.0
## Folgas em torno das bordas do alcance (80 e 120 m), maiores que o deslocamento lateral de 1,2 m (a vista mede até o corpo, o teste até o eixo da estrada): dentro de IN_M a caravana TEM de ter corpo e acima de OUT_M NÃO pode ter.
const IN_M: float = 78.0
const OUT_M: float = 122.0
const DEPARTURE_SPOT_M: float = 6.0
const STEP_TOLERANCE_M: float = 0.01
const STEP_RATIO_MIN: float = 0.9
const STEP_RATIO_MAX: float = 1.1
const FRAME_MS: int = 500
const FRAME_LIMIT: int = (SEARCH_LIMIT + TRIP_LIMIT) * 3
const HASH_EVERY: int = 10
const SAVE_AFTER_MINUTES: int = 40
const PART_OF_STEP_MS: int = 600
const MS_PER_MINUTE: float = 1250.0
const AFTER_LOAD_MINUTES: int = 20
const ARRIVAL_GRACE: int = 2

var _data: NpcLifeCheck.GameData
var _routes: CaravanRoutesReader
var _games: Array[Game] = []
var _origin_settlement: String = ""
var _origin_m: Vector2 = Vector2.ZERO


## Um jogo montado com as duas vistas (a das caravanas é opcional).
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
	var markets: Dictionary[String, Vector2] = {}


## O comerciante que partiu, o primeiro trecho (mercados e estrada) e quantos `NpcView` dele estavam visíveis no minuto ANTES da partida.
class Trip:
	extends RefCounted

	var game: Game
	var trader: int = IdGenerator.NO_ID
	var route_id: String = ""
	var from_id: String = ""
	var origin: Vector2 = Vector2.ZERO
	var heading: Vector2 = Vector2.ZERO
	var road_m: float = 0.0
	var length_m: int = 0
	var leg_minutes: int = 0
	var npc_views_before: int = 0


## O que a viagem mostrou, minuto a minuto: quando o comerciante teve mais de um corpo, quando um `NpcView` dele apareceu em viagem, quando faltou ou sobrou o corpo da caravana (só perto e só longe do foco) e o avanço ao longo da estrada.
class TripLog:
	extends RefCounted

	var minutes: int = 0
	var near_minutes: int = 0
	var far_minutes: int = 0
	var duplicated: Array[int] = []
	var npc_leaks: Array[int] = []
	var missing_near: Array[int] = []
	var lingering_far: Array[int] = []
	var progress: PackedFloat64Array = PackedFloat64Array()


func before_all() -> void:
	_data = NpcLifeCheck.load_game_data()
	assert_eq(_data.problem, "", "Os dados reais do jogo carregam.")
	var routes: CaravanRoutesReader.LoadResult = CaravanRoutesReader.from_file()
	assert_true(routes.result.ok, routes.result.message)
	_routes = routes.data
	# Descoberta: sem corpos, quem parte primeiro e de que povoado (é ali que o foco do jogador fica).
	var found: Game = _build()
	found.runner.start_new_game()
	var traders: Array[int] = _merchants(found)
	assert_gt(traders.size(), 0, "O jogo novo tem comerciantes.")
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


## O jogo montado como o `GameApp` monta, com a ponte real sobre um host que só guarda `runner`, `npc` e `economy`.
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


## As duas vistas ligadas ao mesmo terreno, como a cena as liga; `with_caravans` falso: só a dos NPCs (o jogo igual, sem a vista das caravanas).
func _attach_views(game: Game, with_caravans: bool) -> void:
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
	if with_caravans:
		game.caravan_bodies = CaravanBodiesView.new()
		game.root.add_child(game.caravan_bodies)
		assert_true(game.caravan_bodies.setup(game.bridge, game.terrain_view, _routes))


func _new_game(with_caravans: bool) -> Game:
	var game: Game = _build()
	game.runner.start_new_game()
	_attach_views(game, with_caravans)
	return game


## O save como o jogo grava (o codec JSON, em bytes); só se salva entre passos, com a fila de eventos vazia.
func _encode(game: Game) -> PackedByteArray:
	assert_true(game.runner.can_capture_game(), "Só se salva entre passos, com a fila de eventos vazia.")
	return JsonSaveCodec.new().encode(game.runner.capture_game(), GAME_VERSION)


func _load(bytes: PackedByteArray, with_caravans: bool) -> Game:
	var decoded: DecodedSave = JsonSaveCodec.new().decode(bytes)
	assert_true(decoded.result.ok, decoded.result.message)
	var game: Game = _build()
	var loaded: Result = game.runner.load_game(decoded.payload)
	assert_true(loaded.ok, loaded.message)
	_attach_views(game, with_caravans)
	return game


func _merchants(game: Game, settlement_id: String = "") -> Array[int]:
	var ids: Array[int] = []
	for npc_id: int in game.npc.peek_npc_ids():
		var npc: NpcModule.NpcQuery = game.npc.peek_npc(npc_id)
		if npc.occupation_id == MERCHANT and (settlement_id.is_empty() or npc.settlement_id == settlement_id):
			ids.append(npc_id)
	return ids


## O foco do jogador, como a cena o dá: ao LOD da simulação e ao terreno.
func _focus(game: Game, spot_m: Vector2) -> void:
	var placed: Result = game.npc.request_set_focus(ACTOR_ID, Vector3(spot_m.x, GROUND_M, spot_m.y))
	assert_true(placed.ok, placed.message)
	game.terrain_view.set_focus(Vector3(spot_m.x, GROUND_M, spot_m.y))


## Desenha o terreno em volta do ponto (o chunk dele e os oito vizinhos): sem terreno desenhado os corpos ficam escondidos.
func _draw_terrain_around(game: Game, spot_m: Vector2) -> void:
	var center: Vector2i = Vector2i(floori(spot_m.x / CHUNK_M), floori(spot_m.y / CHUNK_M))
	for dz: int in range(-1, 2):
		for dx: int in range(-1, 2):
			var coord: Vector2i = center + Vector2i(dx, dz)
			if not game.terrain_view.has_chunk(coord):
				assert_true(game.terrain_view.build_chunk(coord), "O chunk %s foi desenhado." % coord)


## O corpo perfeito: cumpre cada Intent pendente no fim previsto (ARRIVED para ir, DONE para agir), no destino.
func _answer_due(game: Game) -> void:
	var now: int = game.runner.world.context.clock.total_minutes()
	for intent: NpcIntent in game.npc.peek_pending_intents():
		if now < game.npc.peek_npc(intent.npc_id).action_ends_at:
			continue
		var outcome: NpcActionResult.Outcome = NpcActionResult.Outcome.ARRIVED if intent.kind == NpcIntent.Kind.MOVE_TO_PLACE else NpcActionResult.Outcome.DONE
		var spot_m: Vector3 = Vector3(intent.destination_cm.x / CM_PER_M, 0.0, intent.destination_cm.y / CM_PER_M)
		var reported: Result = game.npc.request_report_npc_result(NpcActionResult.new(intent.npc_id, intent.action_serial, outcome, spot_m))
		assert_true(reported.ok or reported.code == ActionRunner.CODE_ACTION_FAILED, reported.message)


## Um minuto do jogo: um passo e as respostas do corpo.
func _step(game: Game) -> void:
	game.runner.step_once()
	_answer_due(game)


## O que o quadro faria: o terreno desenhado em volta de cada caravana (a estrada é reta) e as duas vistas em dia.
func _refresh(game: Game) -> void:
	if game.caravan_bodies != null:
		for row: BridgeReplies.CaravanBodyReply in game.bridge.peek_caravan_bodies().bodies:
			_draw_terrain_around(game, _road_point(game, row))
	game.npc_bodies.reconcile()
	if game.caravan_bodies != null:
		game.caravan_bodies.reconcile()


## O ponto da estrada reta entre os mercados do trecho (sem o deslocamento lateral).
func _road_point(game: Game, row: BridgeReplies.CaravanBodyReply) -> Vector2:
	return game.markets[row.from_settlement_id].lerp(game.markets[row.to_settlement_id], row.u)


func _row_of(game: Game, trader: int) -> BridgeReplies.CaravanBodyReply:
	for row: BridgeReplies.CaravanBodyReply in game.bridge.peek_caravan_bodies().bodies:
		if row.trader_id == trader:
			return row
	return null


func _collect_views(node: Node, found: Array[NpcView]) -> void:
	if node is NpcView:
		found.append(node as NpcView)
	for child: Node in node.get_children():
		_collect_views(child, found)


## Os corpos VISÍVEIS do comerciante na árvore inteira: [`NpcView` dele, corpos de caravana dele]. O `NpcView` filho de um `CaravanView` tem `npc_id` NO_ID e conta como corpo da caravana do `trader_id` do pai.
func _visible_bodies(game: Game, trader: int) -> Array[int]:
	var views: Array[NpcView] = []
	_collect_views(game.root, views)
	var counts: Array[int] = [0, 0]
	for view: NpcView in views:
		if not view.is_visible_in_tree():
			continue
		var carrier: CaravanView = view.get_parent() as CaravanView
		if carrier != null:
			counts[1] += 1 if carrier.trader_id == trader else 0
		elif view.npc_id == trader:
			counts[0] += 1
	return counts


func _progress_of(trip: Trip, body: CaravanView) -> float:
	return (Vector2(body.position.x, body.position.z) - trip.origin).dot(trip.heading)


## O jogo novo com as duas vistas, o foco a 10 m do mercado de partida e o terreno desenhado ali, andado até um comerciante do povoado de partida ter caravana (o foco fica onde está).
func _start_trip() -> Trip:
	var trip: Trip = Trip.new()
	trip.game = _new_game(true)
	var game: Game = trip.game
	_focus(game, _origin_m + Vector2(NEAR_M, 0.0))
	_draw_terrain_around(game, _origin_m)
	_refresh(game)
	var traders: Array[int] = _merchants(game, _origin_settlement)
	var views_before: Dictionary[int, int] = {}
	for _minute: int in SEARCH_LIMIT:
		for trader: int in traders:
			views_before[trader] = _visible_bodies(game, trader)[0]
		_step(game)
		for trader: int in traders:
			var row: BridgeReplies.CaravanBodyReply = _row_of(game, trader)
			if row == null:
				continue
			trip.trader = trader
			trip.route_id = row.route_id
			trip.from_id = row.from_settlement_id
			trip.origin = game.markets[row.from_settlement_id]
			trip.road_m = trip.origin.distance_to(game.markets[row.to_settlement_id])
			trip.heading = (game.markets[row.to_settlement_id] - trip.origin).normalized()
			trip.length_m = game.economy.peek_caravan(trader).leg_length_m
			trip.leg_minutes = game.economy.peek_caravan(trader).leg_minutes
			trip.npc_views_before = views_before[trader]
			_refresh(game)
			return trip
		_refresh(game)
	assert_ne(trip.trader, IdGenerator.NO_ID, "Algum comerciante do povoado de partida parte em até 3 dias com as vistas ligadas.")
	return trip


## Segue a viagem minuto a minuto (até a caravana sumir ou `max_minutes`): confere os corpos DEPOIS de cada passo e das duas vistas. `follow`: o foco anda junto com a caravana (a 10 m dela); senão fica no mercado de partida. Ao voltar, o jogo está no passo seguinte
## ao último minuto visto (na chegada, o passo em que o registro some), SEM as vistas em dia.
func _follow(trip: Trip, follow: bool, max_minutes: int = TRIP_LIMIT) -> TripLog:
	var game: Game = trip.game
	var record: TripLog = TripLog.new()
	for minute: int in max_minutes:
		var row: BridgeReplies.CaravanBodyReply = _row_of(game, trip.trader)
		if row == null:
			break
		var spot: Vector2 = _road_point(game, row)
		if follow:
			_focus(game, spot + Vector2(NEAR_M, 0.0))
		_refresh(game)
		var gap_m: float = spot.distance_to(game.terrain_view.focus())
		var seen: Array[int] = _visible_bodies(game, trip.trader)
		record.minutes += 1
		record.near_minutes += 1 if gap_m <= IN_M else 0
		record.far_minutes += 1 if gap_m > OUT_M else 0
		if seen[0] + seen[1] > 1:
			record.duplicated.append(minute)
		if seen[0] > 0:
			record.npc_leaks.append(minute)
		if gap_m <= IN_M and seen[1] != 1:
			record.missing_near.append(minute)
		if gap_m > OUT_M and seen[1] != 0:
			record.lingering_far.append(minute)
		var body: CaravanView = game.caravan_bodies.body_of(trip.trader)
		if body != null and body.visible and row.route_id == trip.route_id and row.from_settlement_id == trip.from_id:
			record.progress.append(_progress_of(trip, body))
		_step(game)
	return record


func test_the_caravan_leaves_the_departure_market_and_the_merchant_never_has_two_bodies_or_a_ghost() -> void:
	var trip: Trip = _start_trip()
	assert_eq(trip.npc_views_before, 1, "ANTES de partir o comerciante tem o seu `NpcView` na praça (foco a 10 m).")
	assert_eq(_visible_bodies(trip.game, trip.trader), [0, 1] as Array[int], "No passo da partida o `NpcView` some e o corpo da caravana aparece, no mesmo quadro: um corpo só.")
	var body: CaravanView = trip.game.caravan_bodies.body_of(trip.trader)
	assert_lt(Vector2(body.position.x, body.position.z).distance_to(trip.origin), DEPARTURE_SPOT_M, "O corpo da caravana nasce junto do mercado de saída.")
	var record: TripLog = _follow(trip, false)
	assert_gt(record.minutes, 60, "A viagem dura mais de uma hora.")
	assert_eq([record.duplicated, record.npc_leaks, record.missing_near, record.lingering_far], [[] as Array[int], [] as Array[int], [] as Array[int], [] as Array[int]], "Em NENHUM minuto há dois corpos ou um `NpcView` do comerciante em viagem, perto do foco (80 m) a caravana TEM corpo e longe (120 m) NÃO tem.")
	assert_true(record.near_minutes > 0 and record.far_minutes > 0, "A viagem foi acompanhada dos dois lados do alcance (entrou e saiu).")


func test_walking_with_the_caravan_the_body_is_always_there_alone_and_steps_match_length_over_leg_minutes() -> void:
	var trip: Trip = _start_trip()
	var record: TripLog = _follow(trip, true)
	assert_eq([record.duplicated, record.npc_leaks, record.missing_near, record.lingering_far, record.far_minutes], [[] as Array[int], [] as Array[int], [] as Array[int], [] as Array[int], 0], "Com o foco junto da caravana ela tem corpo em todos os minutos, um só, e nenhum fantasma.")
	assert_gt(record.progress.size(), trip.leg_minutes - 3, "O corpo foi visto andando quase todos os minutos do trecho.")
	var expected_m: float = trip.road_m / float(trip.leg_minutes)
	var smallest: float = INF
	var worst_error: float = 0.0
	for index: int in range(1, record.progress.size()):
		var step_m: float = record.progress[index] - record.progress[index - 1]
		smallest = minf(smallest, step_m)
		worst_error = maxf(worst_error, absf(step_m - expected_m))
	assert_gt(smallest, 0.0, "A posição ao longo da estrada só cresce (monótona).")
	assert_lt(worst_error, STEP_TOLERANCE_M, "Cada minuto avança a estrada ÷ `leg_minutes`.")
	var ratio: float = expected_m / (float(trip.length_m) / float(trip.leg_minutes))
	assert_between(ratio, STEP_RATIO_MIN, STEP_RATIO_MAX, "E isso é compatível (90% a 110%) com o `length_m ÷ leg_minutes` da simulação.")


func test_on_arrival_the_body_goes_back_to_the_pool_in_the_same_step_and_the_npc_view_returns_once() -> void:
	var trip: Trip = _start_trip()
	var game: Game = trip.game
	var record: TripLog = _follow(trip, true)
	assert_false(game.economy.peek_caravan(trip.trader).found, "A caravana chegou (o registro sumiu).")
	var pool: CaravanViewPool = game.caravan_bodies.pool()
	assert_not_null(game.caravan_bodies.body_of(trip.trader), "Premissa: antes de a vista consultar o passo da chegada o corpo ainda é dela.")
	_refresh(game)
	assert_null(game.caravan_bodies.body_of(trip.trader), "No passo em que o registro some o corpo volta à reserva...")
	assert_eq([pool.active_count(), pool.lost_count(), pool.empty_hits, pool.duplicate_requests], [0, 0, 0, 0], "...a reserva fica inteira e sem pedido repetido nem esgotada.")
	var doubled: Array[int] = []
	var counts: Array[int] = _visible_bodies(game, trip.trader)
	for _grace: int in ARRIVAL_GRACE:
		if counts[0] == 1:
			break
		_step(game)
		_refresh(game)
		counts = _visible_bodies(game, trip.trader)
		if counts[0] + counts[1] > 1:
			doubled.append(counts[0] + counts[1])
	assert_eq(counts, [1, 0] as Array[int], "O `NpcView` do comerciante volta em até 1 passo, UMA vez, e a caravana não tem mais corpo.")
	assert_eq([record.duplicated, doubled], [[] as Array[int], [] as Array[int]], "Nunca dois corpos, nem na troca.")


func test_a_save_made_mid_trip_brings_the_body_back_at_most_one_step_behind_and_changes_nothing() -> void:
	var trip: Trip = _start_trip()
	var game: Game = trip.game
	_follow(trip, true, SAVE_AFTER_MINUTES)
	game.runner.advance_frame(PART_OF_STEP_MS)
	_refresh(game)
	var body: CaravanView = game.caravan_bodies.body_of(trip.trader)
	assert_true(body != null and body.visible, "Premissa: no meio da viagem o corpo está na tela.")
	var before_m: float = _progress_of(trip, body)
	var bytes: PackedByteArray = _encode(game)
	var focus_m: Vector2 = game.terrain_view.focus()
	var restored: Game = _load(bytes, true)
	var silent: Game = _load(bytes, false)
	for loaded: Game in [restored, silent]:
		_focus(loaded, focus_m)
		_draw_terrain_around(loaded, focus_m)
		assert_eq(loaded.runner.world.state_hash(), game.runner.world.state_hash(), "O estado carregado é idêntico ao salvo (mesmo hash).")
		_refresh(loaded)
	var revived: CaravanView = restored.caravan_bodies.body_of(trip.trader)
	assert_true(revived != null and revived.visible, "O corpo da caravana reaparece no mundo carregado.")
	var step_m: float = trip.road_m / float(trip.leg_minutes)
	var behind_m: float = before_m - _progress_of(trip, revived)
	assert_between(behind_m, 0.0, step_m + STEP_TOLERANCE_M, "Reaparece atrás do que se via (a fração de passo volta a 0), a menos de 1 passo, nunca à frente.")
	assert_almost_eq(behind_m, float(PART_OF_STEP_MS) / MS_PER_MINUTE * step_m, 0.05, "E atrás exatamente a fração de passo que se perdeu.")
	assert_eq(_visible_bodies(restored, trip.trader), [0, 1] as Array[int], "Um corpo só, o da caravana (o fantasma não volta com o save).")
	for _minute: int in AFTER_LOAD_MINUTES:
		_step(restored)
		_refresh(restored)
		_step(silent)
		_refresh(silent)
	assert_eq(restored.runner.world.state_hash(), silent.runner.world.state_hash(), "Carregado e seguido por 20 minutos com a vista das caravanas e sem ela: o mesmo hash.")


## Uma execução inteira até o fim da 1ª viagem, por QUADROS de 500 ms (a fração de passo assume vários valores), com a vista das caravanas ou sem ela; devolve o `state_hash` a cada 10 minutos e no fim, e quantos corpos de caravana a vista retirou.
func _hash_rows(with_caravans: bool) -> Array:
	var game: Game = _new_game(with_caravans)
	_focus(game, _origin_m + Vector2(NEAR_M, 0.0))
	_draw_terrain_around(game, _origin_m)
	var rows: Array[String] = []
	var last_minute: int = -HASH_EVERY
	var has_travelled: bool = false
	for _frame: int in FRAME_LIMIT:
		game.runner.advance_frame(FRAME_MS)
		_answer_due(game)
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
	return [rows, game.caravan_bodies.pool().taken if with_caravans else 0]


func test_the_view_changes_nothing_the_state_hash_is_the_same_with_it_running_and_without_it() -> void:
	var watched: Array = _hash_rows(true)
	var silent: Array = _hash_rows(false)
	assert_gt(watched[1], 0, "A vista retirou corpos durante a viagem (o teste não rodou no vazio).")
	assert_gt(watched[0].size(), 3, "Vários instantes conferidos, a viagem inteira.")
	assert_eq(watched[0], silent[0], "O mesmo `state_hash` a cada 10 minutos e no fim, com a vista das caravanas rodando e sem ela: a vista só lê.")
