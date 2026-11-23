extends GutTest
## Correção do "comerciante-fantasma" (diagnóstico de 23/11/2026): `SimBridge.peek_npc_bodies` NÃO lista o NPC que tem caravana (`peek_caravan(id).found`). Antes, o comerciante em viagem seguia em S0 no
## mercado de partida (a posição lógica só muda na chegada) e a apresentação desenhava um corpo PARADO na praça durante toda a viagem. O jogo real é montado como o `GameApp` monta (dados reais, economia e rotas,
## semente e hora do jogo novo, como em `test_merchant_saves.gd`), com um host que dá à ponte o `runner`, o `npc` e a `economy`. A apresentação é um corpo "perfeito" (cumpre cada Intent no fim previsto), com os corpos
## ligados e o foco do jogador a 10 m, 130 m ou 200 m do mercado de partida. O filtro é só de CONSULTA: o LOD, a posição lógica e a economia do NPC não mudam (`state_hash`, níveis e `LodChanged` iguais com e sem a consulta).

const DATA_DIR: String = "res://data"
const WORLD_DIR: String = "res://data/world"
const GAME_VERSION: String = "0.0.1-test"
const MERCHANT: String = "merchant"
const ACTOR_ID: int = 1000
const DAY: int = SimClock.MINUTES_PER_DAY
## Prazo para algum comerciante partir (o jogo real o faz no 1º dia) e para a viagem acabar (a rota B-C leva 96 minutos); passou disso, a premissa mudou.
const SEARCH_LIMIT: int = 3 * DAY
const TRIP_LIMIT: int = 1500
const CM_PER_M: float = 100.0
const NEAR_M: float = 10.0
const OUT_M: float = 130.0
const FAR_M: float = 200.0
const WIGGLE_EVERY: int = 10
const HASH_EVERY: int = 10
const MIN_TRIP_M: float = 100.0
const HELD_MINUTES: int = 30
const ARRIVAL_TOLERANCE_M: float = 1.0

var _data: NpcLifeCheck.GameData
var _runners: Array[SimulationRunner] = []
var _hosts: Array[SimulationHostNode] = []
var _origin_settlement: String = ""
var _origin_m: Vector2 = Vector2.ZERO


class Game:
	extends RefCounted

	var runner: SimulationRunner
	var npc: NpcModule
	var economy: EconomyModule
	var world: WorldModule
	var host: SimulationHostNode
	var bridge: SimBridge
	## Os `LodChanged` do jogo: [minuto, NPC, nível antes, nível depois].
	var lod_events: Array[Array] = []

	func on_lod_changed(event: SimEvent) -> void:
		var change: LodChanged = event as LodChanged
		lod_events.append([runner.world.context.clock.total_minutes(), change.npc_id, change.from_level, change.to_level])


## O comerciante que partiu, o mercado de onde partiu e os corpos listados no minuto ANTES do passo em que ele partiu.
class Trip:
	extends RefCounted

	var game: Game
	var trader: int = IdGenerator.NO_ID
	var origin_cm: Vector2i = Vector2i.ZERO
	var before: Array[int] = []


## O que a viagem mostrou, minuto a minuto: quando o comerciante apareceu na lista (`leaked`), quando a lista não foi "S0 menos ele" (`mismatch`), as linhas comparáveis entre execuções e os `LodChanged`.
class TripLog:
	extends RefCounted

	var minutes: int = 0
	var s0_minutes: int = 0
	var moved_minutes: int = 0
	var leaked: Array[int] = []
	var mismatch: Array[int] = []
	var rows: Array[String] = []
	var events: Array[Array] = []
	var trader_changes: int = 0


func before_all() -> void:
	_data = NpcLifeCheck.load_game_data()
	assert_eq(_data.problem, "", "Os dados reais do jogo carregam.")
	# Descoberta: sem corpos, quem parte primeiro e de que mercado (é ali que o foco do jogador vai ficar).
	var found: Game = _new_game()
	var traders: Array[int] = _merchants(found)
	assert_eq(traders.size(), 6, "Seis comerciantes no jogo novo.")
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
	for runner: SimulationRunner in _runners:
		runner.finish()
	_runners.clear()
	for host: SimulationHostNode in _hosts:
		host.free()
	_hosts.clear()


## O jogo montado como o `GameApp` monta, com a ponte real sobre um host que só guarda `runner`, `npc` e `economy`. `with_merchants` falso: o mundo ANTIGO, sem as três linhas `merchant` da população.
func _build(with_merchants: bool = true) -> Game:
	var setup: NpcSetup = NpcSetup.from_dir(DATA_DIR, SettlementService.new(_data.settlements, _data.places))
	assert_true(setup.result.ok, setup.result.message)
	if not with_merchants:
		var rows: Array[PopulationPlan.PopulationRow] = []
		for row: PopulationPlan.PopulationRow in setup.definitions.population.peek_rows():
			if row.occupation_id != MERCHANT:
				rows.append(row)
		setup.definitions.population = PopulationPlan.new(rows)
	var game: Game = Game.new()
	game.runner = SimulationRunner.new(GameAppNode.DEFAULT_WORLD_SEED, GameAppNode.NEW_GAME_START_MINUTE)
	_runners.append(game.runner)
	var modules: GameModules = GameModules.register(game.runner, _data.terrain, _data.points, setup, EconomySetup.from_dir(EconomySetup.DEFAULT_DIR), WorldSetup.from_dir(WORLD_DIR, _data.settlements, OS.is_debug_build()))
	assert_true(modules.result.ok, modules.result.message)
	game.npc = modules.npc
	game.economy = modules.economy
	game.world = modules.world
	game.host = _host_of(game)
	game.bridge = SimBridge.new(game.host, _data.terrain, _data.places, game.npc)
	game.runner.world.context.events.subscribe("LodChanged", game.on_lod_changed)
	return game


func _host_of(game: Game, with_economy: bool = true) -> SimulationHostNode:
	var host: SimulationHostNode = SimulationHostNode.new()
	host.runner = game.runner
	host.npc = game.npc
	host.economy = game.economy if with_economy else null
	_hosts.append(host)
	return host


func _new_game(with_merchants: bool = true) -> Game:
	var game: Game = _build(with_merchants)
	game.runner.start_new_game()
	return game


## O save como o jogo grava (o codec JSON, em bytes); só se salva entre passos, com a fila de eventos vazia.
func _encode(game: Game) -> PackedByteArray:
	assert_true(game.runner.can_capture_game(), "Só se salva entre passos, com a fila de eventos vazia.")
	return JsonSaveCodec.new().encode(game.runner.capture_game(), GAME_VERSION)


func _load(bytes: PackedByteArray, with_merchants: bool = true) -> Game:
	var decoded: DecodedSave = JsonSaveCodec.new().decode(bytes)
	assert_true(decoded.result.ok, decoded.result.message)
	var game: Game = _build(with_merchants)
	var loaded: Result = game.runner.load_game(decoded.payload)
	assert_true(loaded.ok, loaded.message)
	return game


func _merchants(game: Game, settlement_id: String = "") -> Array[int]:
	var ids: Array[int] = []
	for npc_id: int in game.npc.peek_npc_ids():
		var npc: NpcModule.NpcQuery = game.npc.peek_npc(npc_id)
		if npc.occupation_id == MERCHANT and (settlement_id.is_empty() or npc.settlement_id == settlement_id):
			ids.append(npc_id)
	return ids


## Liga os corpos (pela ponte) e põe o foco do jogador em `focus_m`, como a apresentação faz.
func _watch(game: Game, focus_m: Vector2) -> void:
	assert_true(game.bridge.request_set_bodies_available(true).ok)
	_focus(game, focus_m)


func _focus(game: Game, focus_m: Vector2) -> void:
	var placed: Result = game.npc.request_set_focus(ACTOR_ID, Vector3(focus_m.x, 10.0, focus_m.y))
	assert_true(placed.ok, placed.message)


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
func _tick(game: Game) -> void:
	game.runner.step_once()
	_answer_due(game)


func _bodies(game: Game) -> Array[BridgeReplies.NpcBodyReply]:
	var listed: BridgeReplies.NpcBodiesReply = game.bridge.peek_npc_bodies()
	assert_true(listed.result.ok, listed.result.message)
	return listed.bodies


func _ids(bodies: Array[BridgeReplies.NpcBodyReply]) -> Array[int]:
	var ids: Array[int] = []
	for body: BridgeReplies.NpcBodyReply in bodies:
		ids.append(body.npc_id)
	return ids


## O conjunto S0 menos quem está em viagem (tem caravana na economia): é o que a ponte deve listar.
func _s0_without_caravans(game: Game) -> Array[int]:
	var ids: Array[int] = []
	for npc_id: int in game.npc.lod.s0_ids():
		if not game.economy.peek_caravan(npc_id).found:
			ids.append(npc_id)
	return ids


## O jogo novo com os corpos ligados e o foco a `focus_offset_m` do mercado de partida, andado até um comerciante do povoado de partida ter caravana (as respostas do corpo no meio). `queries`: lista os corpos a cada minuto.
func _start_trip(queries: bool, focus_offset_m: float) -> Trip:
	var trip: Trip = Trip.new()
	trip.game = _new_game()
	_watch(trip.game, _origin_m + Vector2(focus_offset_m, 0.0))
	var traders: Array[int] = _merchants(trip.game, _origin_settlement)
	var previous: Array[int] = _ids(_bodies(trip.game)) if queries else ([] as Array[int])
	for _minute: int in SEARCH_LIMIT:
		trip.game.runner.step_once()
		_answer_due(trip.game)
		for trader: int in traders:
			if trip.game.economy.peek_caravan(trader).found:
				var leaver: NpcModule.NpcQuery = trip.game.npc.peek_npc(trader)
				trip.trader = trader
				trip.origin_cm = Vector2i(leaver.x_cm, leaver.z_cm)
				trip.before = previous
				return trip
		previous = _ids(_bodies(trip.game)) if queries else previous
	assert_ne(trip.trader, IdGenerator.NO_ID, "Algum comerciante do povoado de partida parte em até 3 dias com os corpos ligados.")
	return trip


## Anda `minutes` minutos e devolve os minutos em que o comerciante apareceu na lista de corpos.
func _walk(trip: Trip, minutes: int) -> Array[int]:
	var leaked: Array[int] = []
	for minute: int in minutes:
		_tick(trip.game)
		if trip.trader in _ids(_bodies(trip.game)):
			leaked.append(minute)
	return leaked


## Segue a viagem até a caravana sumir (a chegada): um passo e as respostas do corpo por minuto; com `wiggle` o foco vai e volta (a 10 m e a 130 m do mercado de partida, a cada 10 minutos). Com `queries` também consulta a ponte
## a cada minuto e confere que a lista é exatamente "S0 menos o comerciante". As linhas trazem nível, S0 e, de 10 em 10 minutos e no fim, o `state_hash`. Ao voltar, o jogo está no passo da chegada.
func _follow(trip: Trip, queries: bool, wiggle: bool) -> TripLog:
	var game: Game = trip.game
	var record: TripLog = TripLog.new()
	for minute: int in TRIP_LIMIT:
		if wiggle and minute % WIGGLE_EVERY == 0:
			var out_phase: bool = minute % (2 * WIGGLE_EVERY) >= WIGGLE_EVERY
			_focus(game, Vector2(trip.origin_cm) / CM_PER_M + Vector2(OUT_M if out_phase else NEAR_M, 0.0))
		_tick(game)
		if not game.economy.peek_caravan(trip.trader).found:
			break
		record.minutes += 1
		var level: int = game.npc.lod.level_of(trip.trader)
		var npc: NpcModule.NpcQuery = game.npc.peek_npc(trip.trader)
		record.s0_minutes += 1 if level == NpcLod.LEVEL_S0 else 0
		record.moved_minutes += 1 if Vector2i(npc.x_cm, npc.z_cm) != trip.origin_cm else 0
		if queries:
			var listed: Array[int] = _ids(_bodies(game))
			if trip.trader in listed:
				record.leaked.append(minute)
			if listed != _s0_without_caravans(game):
				record.mismatch.append(minute)
		record.rows.append("%d lod=%d s0=%s%s" % [minute, level, str(game.npc.lod.s0_ids()), (" " + game.runner.world.state_hash()) if minute % HASH_EVERY == 0 else ""])
	record.rows.append("fim " + game.runner.world.state_hash())
	record.events = game.lod_events.duplicate()
	for event: Array in record.events:
		record.trader_changes += 1 if event[1] == trip.trader else 0
	return record


## A chegada: a caravana sumiu e o NPC lógico já está no povoado do destino, longe do mercado de partida; no passo da chegada o corpo não está na lista (o foco segue na partida). Com o foco no destino o corpo volta UMA vez, na posição do destino.
func _assert_back_at_destination(trip: Trip) -> void:
	var game: Game = trip.game
	var npc: NpcModule.NpcQuery = game.npc.peek_npc(trip.trader)
	var spot_m: Vector2 = Vector2(npc.x_cm, npc.z_cm) / CM_PER_M
	assert_false(game.economy.peek_caravan(trip.trader).found, "A caravana chegou (o registro sumiu).")
	assert_ne(npc.settlement_id, _origin_settlement, "O NPC foi realocado no povoado do destino.")
	assert_gt(spot_m.distance_to(Vector2(trip.origin_cm) / CM_PER_M), MIN_TRIP_M, "A posição lógica agora é a do destino, longe do mercado de partida.")
	assert_false(trip.trader in _ids(_bodies(game)), "No passo da chegada não há corpo na praça de partida.")
	_focus(game, spot_m + Vector2(NEAR_M, 0.0))
	_tick(game)
	var bodies: Array[BridgeReplies.NpcBodyReply] = _bodies(game)
	var mine: Array[BridgeReplies.NpcBodyReply] = []
	for body: BridgeReplies.NpcBodyReply in bodies:
		if body.npc_id == trip.trader:
			mine.append(body)
	assert_eq(mine.size(), 1, "Com o foco no destino o corpo volta UMA vez, sem duplicado.")
	assert_eq(_ids(bodies), _s0_without_caravans(game), "E a lista é o conjunto S0 (menos quem está em viagem).")
	if mine.size() == 1:
		assert_almost_eq(Vector2(mine[0].position.x, mine[0].position.z).distance_to(spot_m), 0.0, ARRIVAL_TOLERANCE_M, "O corpo volta na posição do destino.")


func test_the_merchant_loses_its_body_when_it_departs_and_stays_without_it_all_trip_long() -> void:
	var trip: Trip = _start_trip(true, NEAR_M)
	var game: Game = trip.game
	assert_true(trip.trader in trip.before, "ANTES de partir (minuto anterior ao passo da partida) o comerciante tem corpo: foco a 10 m do mercado, corpos ligados.")
	var after: Array[int] = _ids(_bodies(game))
	var s0: Array[int] = game.npc.lod.s0_ids()
	assert_true(trip.trader in s0, "O NPC lógico segue em S0 (o filtro é só de consulta).")
	assert_eq([trip.trader in after, after.size()], [false, s0.size() - 1], "No instante da partida ele some da lista e os outros NPCs em S0 seguem listados (a contagem cai em exatamente 1).")
	var record: TripLog = _follow(trip, true, false)
	assert_gt(record.minutes, 60, "A viagem dura mais de uma hora.")
	assert_eq(record.leaked, [] as Array[int], "Em NENHUM minuto da viagem o comerciante aparece como corpo.")
	assert_eq(record.mismatch, [] as Array[int], "Em todos os minutos a lista é o conjunto S0 menos quem está em viagem.")
	assert_eq([record.s0_minutes, record.moved_minutes], [record.minutes, 0], "Todo o tempo ele segue em S0 e a posição lógica fica no mercado de partida (a localização lógica é preservada).")


func test_a_held_caravan_keeps_the_merchant_hidden_and_the_logical_npc_in_place() -> void:
	var trip: Trip = _start_trip(true, NEAR_M)
	var game: Game = trip.game
	var leaked: Array[int] = _walk(trip, 20)
	var road: CaravanReplies.CaravanQuery = game.economy.peek_caravan(trip.trader)
	assert_true(road.found and road.state == Caravan.STATE_TRAVELLING, "Aos 20 minutos a caravana segue na estrada.")
	assert_true(game.world.request_close_route(road.current_route_id).ok, "A rota do meio da viagem fecha.")
	leaked.append_array(_walk(trip, HELD_MINUTES))
	var held: CaravanReplies.CaravanQuery = game.economy.peek_caravan(trip.trader)
	assert_eq([held.found, held.state], [true, Caravan.STATE_HELD], "A caravana ficou parada (`held`) e continua existindo.")
	assert_eq([game.npc.lod.level_of(trip.trader), Vector2i(game.npc.peek_npc(trip.trader).x_cm, game.npc.peek_npc(trip.trader).z_cm)], [NpcLod.LEVEL_S0, trip.origin_cm], "Parada, o NPC lógico segue em S0 no mercado de partida.")
	assert_true(game.world.request_open_route(road.current_route_id).ok, "A rota reabre.")
	var record: TripLog = _follow(trip, true, false)
	leaked.append_array(record.leaked)
	assert_eq([leaked, record.mismatch], [[] as Array[int], [] as Array[int]], "Parada ou andando, enquanto a caravana existe o comerciante não é listado.")
	_assert_back_at_destination(trip)


func test_with_the_focus_far_the_merchant_is_never_listed_nor_in_s0() -> void:
	var trip: Trip = _start_trip(true, FAR_M)
	assert_false(trip.trader in trip.before, "Controle: com o foco a 200 m ele já não tinha corpo antes de partir.")
	var record: TripLog = _follow(trip, true, false)
	assert_eq([record.leaked, record.mismatch, record.s0_minutes], [[] as Array[int], [] as Array[int], 0], "Foco a 200 m: nunca listado e nunca em S0.")


func test_on_arrival_the_body_comes_back_once_at_the_destination() -> void:
	var trip: Trip = _start_trip(true, NEAR_M)
	var record: TripLog = _follow(trip, true, false)
	assert_eq(record.leaked, [] as Array[int], "Durante a viagem nenhum corpo.")
	_assert_back_at_destination(trip)


func test_the_query_never_shows_the_merchant_changes_nothing_and_is_deterministic() -> void:
	# O foco entra e sai do alcance várias vezes (10 m e 130 m do mercado de partida), com a consulta a cada minuto, duas vezes, e sem consulta nenhuma.
	var first: TripLog = _follow(_start_trip(true, NEAR_M), true, true)
	var second: TripLog = _follow(_start_trip(true, NEAR_M), true, true)
	var silent: TripLog = _follow(_start_trip(false, NEAR_M), false, true)
	assert_eq([first.leaked, first.mismatch], [[] as Array[int], [] as Array[int]], "Entrando e saindo do alcance várias vezes, o comerciante nunca é listado.")
	assert_gt(first.trader_changes, 3, "O LOD do comerciante trocou de nível várias vezes (entrou e saiu de S0).")
	assert_between(first.s0_minutes, 1, first.minutes - 1, "A viagem foi acompanhada dos dois lados do limite.")
	assert_eq(second.rows, first.rows, "Duas execuções idênticas: mesmos níveis, mesmo conjunto S0 e mesmo `state_hash` em vários instantes.")
	assert_eq(second.events, first.events, "E os mesmos `LodChanged`.")
	assert_eq(silent.rows, first.rows, "A execução que NUNCA consulta os corpos dá os mesmos níveis, S0 e `state_hash`: a consulta não escreve nada.")
	assert_eq(silent.events, first.events, "E os mesmos `LodChanged`, com e sem a consulta a cada minuto.")


func test_a_save_made_mid_trip_loads_with_the_merchant_hidden_until_the_arrival() -> void:
	var trip: Trip = _start_trip(true, NEAR_M)
	_walk(trip, 10)
	trip.game.runner.step_once()
	var restored: Trip = Trip.new()
	restored.game = _load(_encode(trip.game))
	restored.trader = trip.trader
	restored.origin_cm = trip.origin_cm
	_watch(restored.game, _origin_m + Vector2(NEAR_M, 0.0))
	_walk(restored, 2)
	var road: CaravanReplies.CaravanQuery = restored.game.economy.peek_caravan(trip.trader)
	assert_true(road.found and road.progress_m > 0, "A caravana voltou em viagem, com progresso na estrada.")
	assert_eq(restored.game.npc.lod.level_of(trip.trader), NpcLod.LEVEL_S0, "O NPC lógico voltou em S0 perto do foco (quem o esconde é a consulta).")
	var record: TripLog = _follow(restored, true, false)
	assert_eq([record.leaked, record.mismatch], [[] as Array[int], [] as Array[int]], "Carregado no meio da viagem, ele segue ausente enquanto a caravana existir.")
	assert_gt(record.s0_minutes, 0, "(e em S0 enquanto isso)")
	_assert_back_at_destination(restored)


func test_a_save_without_a_caravan_and_an_old_save_list_the_s0_bodies_as_before() -> void:
	var fresh: Game = _new_game()
	fresh.runner.run_steps(5)
	for trader: int in _merchants(fresh):
		assert_false(fresh.economy.peek_caravan(trader).found, "Premissa: nenhum comerciante em viagem no save.")
	var old_world: Game = _new_game(false)
	old_world.runner.run_steps(5)
	var cases: Array[Game] = [_load(_encode(fresh)), _load(_encode(old_world))]
	for loaded: Game in cases:
		_watch(loaded, _origin_m + Vector2(NEAR_M, 0.0))
		_tick(loaded)
		var listed: Array[int] = _ids(_bodies(loaded))
		assert_gt(listed.size(), 0, "Com o foco no povoado há corpos.")
		assert_eq(listed, loaded.npc.lod.s0_ids(), "Sem caravana, a lista é exatamente o conjunto S0 (nada filtrado).")
	assert_eq(cases[1].npc.peek_npc_ids().size(), 132, "O save antigo carregou nos dados novos sem criar ninguém.")


func test_without_the_economy_the_query_lists_the_whole_s0_set_as_before() -> void:
	var trip: Trip = _start_trip(true, NEAR_M)
	var game: Game = trip.game
	assert_true(game.economy.peek_caravan(trip.trader).found, "Premissa: o comerciante está em viagem.")
	# Ponte sem economia: um host com jogo mas sem o módulo, e uma ponte sem host. Sem a quem perguntar, nada é filtrado e nada falha.
	var bridges: Array[SimBridge] = [SimBridge.new(_host_of(game, false), _data.terrain, _data.places, game.npc), SimBridge.new(null, _data.terrain, _data.places, game.npc)]
	for bridge: SimBridge in bridges:
		var listed: BridgeReplies.NpcBodiesReply = bridge.peek_npc_bodies()
		assert_true(listed.result.ok, listed.result.message)
		assert_eq(_ids(listed.bodies), game.npc.lod.s0_ids(), "Sem economia a lista é o conjunto S0 inteiro, como antes (sem falha nova).")


func test_the_bodies_view_holds_no_figure_for_the_travelling_merchant() -> void:
	# A apresentação só alcança um NPC pelo corpo que a `NpcBodiesView` mantém (`interaction_view.gd`, `_choose_target`): sem a figura, o comerciante em viagem não é alvo de conversa.
	var trip: Trip = _start_trip(true, NEAR_M)
	var terrain_view: TerrainView = TerrainView.new()
	add_child_autofree(terrain_view)
	terrain_view.setup(trip.game.bridge)
	terrain_view.set_process(false)
	var view: NpcBodiesView = NpcBodiesView.new()
	add_child_autofree(view)
	assert_true(view.setup(trip.game.bridge, terrain_view))
	view.reconcile()
	assert_false(trip.trader in view.active_ids(), "Em viagem não há figura do comerciante na tela.")
	assert_gt(view.active_ids().size(), 0, "Os outros NPCs em S0 seguem com figura.")
	_follow(trip, false, false)
	var spot_m: Vector2 = Vector2(trip.game.npc.peek_npc(trip.trader).x_cm, trip.game.npc.peek_npc(trip.trader).z_cm) / CM_PER_M
	_focus(trip.game, spot_m + Vector2(NEAR_M, 0.0))
	_tick(trip.game)
	view.reconcile()
	assert_eq(view.active_ids().count(trip.trader), 1, "Na chegada a figura volta, uma só.")
	view.release()
