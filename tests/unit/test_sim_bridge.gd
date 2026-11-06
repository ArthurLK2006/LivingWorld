extends GutTest
## LW-036: ponte mínima (consultas, pedidos de ritmo e fila de intenções), sem cena e sem janela.

## Terreno de teste (somente leitura): 4 x 3 células de 2 m; os valores esperados vêm do arquivo
## (mesmos de tests/unit/test_terrain_data.gd).
const OK_DIR: String = "res://tests/fixtures/world/terrain_ok"
const TOLERANCE: float = 0.000001

var _host: SimulationHostNode
var _terrain: TerrainData
var _bridge: SimBridge


func before_each() -> void:
	var loaded: TerrainLoader.LoadResult = TerrainLoader.load_dir(OK_DIR)
	assert_true(loaded.result.ok, loaded.result.message)
	_terrain = loaded.terrain
	_host = SimulationHostNode.new()
	_host.start_new_game(3)
	_bridge = SimBridge.new(_host, _terrain)


func after_each() -> void:
	_host.runner.finish()
	_host.free()


func _seconds_per_minute() -> float:
	return SimClock.DEFAULT_REAL_MS_PER_MINUTE / 1000.0


func test_height_matches_the_terrain_data() -> void:
	# [x, z, altura em metros]: dois nós e dois pontos intermediários do terreno de teste.
	var samples: Array[Array] = [[2.0, 0.0, 1.0], [4.0, 2.0, 17.0], [1.0, 1.0, 5.5], [3.0, 1.0, 7.75]]
	for row: Array in samples:
		var reply: SimBridge.HeightReply = _bridge.peek_height(row[0], row[1])
		assert_true(reply.result.ok, reply.result.message)
		assert_almost_eq(reply.height_m, row[2], TOLERANCE, "Altura em x=%s z=%s." % [row[0], row[1]])
		assert_eq(reply.height_m, _terrain.peek_height(row[0], row[1]).height_m, "A ponte repassa o valor do world sem alterar.")


func test_surface_matches_the_terrain_data() -> void:
	# [x, z, código, id]
	var samples: Array[Array] = [[1.0, 1.0, 1, "grass"], [3.0, 3.0, 7, "rock"], [7.0, 1.0, 2, "path"]]
	for row: Array in samples:
		var reply: SimBridge.SurfaceReply = _bridge.peek_surface(row[0], row[1])
		assert_true(reply.result.ok, reply.result.message)
		assert_eq(reply.surface_code, row[2])
		assert_eq(reply.surface_id, row[3])


func test_spawn_point_matches_the_terrain_data() -> void:
	var reply: SimBridge.SpawnReply = _bridge.peek_spawn_point()
	assert_true(reply.result.ok, reply.result.message)
	assert_eq(reply.point, _terrain.peek_spawn_point())
	assert_almost_eq(reply.point.y, 14.0, TOLERANCE, "Altura do chão no ponto de nascimento do terreno de teste.")


func test_outside_the_map_and_non_finite_coordinates_fail_with_the_world_codes() -> void:
	var outside: SimBridge.HeightReply = _bridge.peek_height(8.001, 0.0)
	assert_false(outside.result.ok)
	assert_eq(outside.result.code, TerrainData.CODE_OUT_OF_BOUNDS)
	assert_string_contains(outside.result.message, "fora do mapa")
	var not_a_number: SimBridge.SurfaceReply = _bridge.peek_surface(NAN, 1.0)
	assert_false(not_a_number.result.ok)
	assert_eq(not_a_number.result.code, TerrainData.CODE_INVALID_COORDINATE)
	assert_eq(not_a_number.surface_code, TerrainData.NO_SURFACE_CODE)
	var infinite: SimBridge.HeightReply = _bridge.peek_height(1.0, INF)
	assert_eq(infinite.result.code, TerrainData.CODE_INVALID_COORDINATE)


func test_without_terrain_the_queries_fail_but_time_still_works() -> void:
	var bare: SimBridge = SimBridge.new(_host, null)
	assert_eq(bare.peek_height(1.0, 1.0).result.code, SimBridge.CODE_NO_TERRAIN)
	assert_eq(bare.peek_surface(1.0, 1.0).result.code, SimBridge.CODE_NO_TERRAIN)
	assert_eq(bare.peek_spawn_point().result.code, SimBridge.CODE_NO_TERRAIN)
	assert_true(bare.peek_time().result.ok)


func test_peek_time_follows_the_clock_and_each_answer_is_a_copy() -> void:
	var start: SimBridge.TimeSnapshot = _bridge.peek_time()
	assert_true(start.result.ok, start.result.message)
	assert_eq([start.year, start.day_of_year, start.hour_of_day, start.minute_of_hour, start.total_minutes], [1, 1, 0, 0, 0])
	_host.runner.run_steps(SimClock.MINUTES_PER_DAY + 61)
	var later: SimBridge.TimeSnapshot = _bridge.peek_time()
	assert_eq([later.year, later.day_of_year, later.hour_of_day, later.minute_of_hour, later.total_minutes], [1, 2, 1, 1, 1501])
	assert_eq(start.total_minutes, 0, "Uma resposta já entregue não muda com o relógio.")


func test_pause_and_speed_requests_reach_the_host_clock() -> void:
	assert_true(_bridge.request_pause(true).ok)
	assert_true(_bridge.peek_time().is_paused)
	assert_eq(_host.advance(_seconds_per_minute() * 5.0), 0, "Pausado, o host não avança.")
	assert_true(_bridge.request_pause(false).ok)
	assert_false(_bridge.peek_time().is_paused)
	assert_true(_bridge.request_speed(4).ok)
	assert_eq(_bridge.peek_time().speed, 4)
	assert_eq(_host.advance(_seconds_per_minute()), 4)


func test_speed_from_1_to_8_is_accepted_and_other_values_are_refused() -> void:
	for speed: int in range(SimClock.MIN_SPEED, SimClock.MAX_SPEED + 1):
		assert_true(_bridge.request_speed(speed).ok, "Velocidade %d deveria ser aceita." % speed)
		assert_eq(_bridge.peek_time().speed, speed)
	var invalid_speeds: Array[int] = [0, 9, -2]
	for speed: int in invalid_speeds:
		var result: Result = _bridge.request_speed(speed)
		assert_false(result.ok, "Velocidade %d deveria ser recusada." % speed)
		assert_eq(result.code, "CLOCK_INVALID_SPEED")
		assert_eq(_bridge.peek_time().speed, SimClock.MAX_SPEED, "A velocidade anterior continua valendo.")


func test_without_a_game_or_a_host_the_calls_fail_without_crashing() -> void:
	var idle: SimulationHostNode = SimulationHostNode.new()
	var no_game: SimBridge = SimBridge.new(idle, _terrain)
	assert_eq(no_game.peek_time().result.code, SimBridge.CODE_NO_GAME)
	assert_eq(no_game.request_pause(true).code, SimulationHostNode.CODE_NO_GAME)
	assert_eq(no_game.request_speed(2).code, SimulationHostNode.CODE_NO_GAME)
	assert_true(no_game.peek_height(1.0, 1.0).result.ok, "O terreno não depende de haver jogo iniciado.")
	idle.free()
	var no_host: SimBridge = SimBridge.new(null, _terrain)
	assert_eq(no_host.peek_time().result.code, SimBridge.CODE_NO_GAME)
	assert_eq(no_host.request_pause(true).code, SimBridge.CODE_NO_GAME)
	assert_eq(no_host.request_speed(2).code, SimBridge.CODE_NO_GAME)


func test_intents_come_out_in_arrival_order_and_the_queue_empties() -> void:
	var first: BridgeIntent = BridgeIntent.new(7)
	var second: BridgeIntent = BridgeIntent.new(9)
	assert_true(_bridge.submit_intent(first).ok)
	assert_true(_bridge.submit_intent(second).ok)
	assert_eq(_bridge.pending_intent_count(), 2)
	var taken: Array[BridgeIntent] = _bridge.take_pending_intents()
	assert_eq(taken.size(), 2)
	assert_true(taken[0] == first and taken[1] == second, "Ordem de chegada.")
	assert_eq(_bridge.pending_intent_count(), 0)
	assert_eq(_bridge.take_pending_intents().size(), 0)
	assert_true(_bridge.submit_intent(BridgeIntent.new(11)).ok)
	assert_eq(taken.size(), 2, "A lista entregue não é a fila viva.")


func test_null_intent_and_invalid_actor_are_refused_and_not_queued() -> void:
	var null_result: Result = _bridge.submit_intent(null)
	assert_false(null_result.ok)
	assert_eq(null_result.code, SimBridge.CODE_NULL_INTENT)
	var invalid_actors: Array[int] = [IdGenerator.NO_ID, -5]
	for actor_id: int in invalid_actors:
		var result: Result = _bridge.submit_intent(BridgeIntent.new(actor_id))
		assert_false(result.ok, "actor_id %d deveria ser recusado." % actor_id)
		assert_eq(result.code, SimBridge.CODE_INVALID_ACTOR)
		assert_string_contains(result.message, str(actor_id))
	assert_eq(_bridge.pending_intent_count(), 0)


func test_queueing_intents_does_not_change_the_state_hash() -> void:
	var other_host: SimulationHostNode = SimulationHostNode.new()
	other_host.start_new_game(3)
	for actor_id: int in [1, 2, 3]:
		assert_true(_bridge.submit_intent(BridgeIntent.new(actor_id)).ok)
	_host.runner.run_steps(100)
	other_host.runner.run_steps(100)
	assert_eq(_host.runner.world.state_hash(), other_host.runner.world.state_hash(), "A fila não é salva nem entra no hash.")
	assert_eq(_bridge.pending_intent_count(), 3, "Nada consome a fila ainda.")
	other_host.runner.finish()
	other_host.free()


func test_bridge_needs_no_scene_tree_or_node() -> void:
	assert_false(is_instance_of(_bridge, Node), "A ponte é RefCounted, sem Node.")
	assert_false(_host.is_inside_tree(), "O host de teste está fora da árvore de cena.")
