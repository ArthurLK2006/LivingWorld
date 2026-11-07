extends GutTest
## LW-049: a ponte expõe os pontos de interesse (em cópias) e o pedido de interação. A posição do ator vem SEMPRE do que está guardado
## no personagem (o último relato do corpo), nunca da apresentação. Mundo do jogo montado como o jogo monta (host com terreno e pontos
## reais), sem janela e sem física.

const BLOCKOUT_DIR: String = "res://data/world"
const WORLD_SEED: int = 3
const NEAR_POINT: Vector3 = Vector3(120.0, 10.0, 513.0)
const FAR_POINT: Vector3 = Vector3(220.0, 10.0, 513.0)
const BESIDE_NEAR: Vector3 = Vector3(121.0, 10.0, 513.0)
const REACH_M: float = 3.0
const HEIGHT_TOLERANCE_M: float = 0.001
const UNKNOWN_ACTOR_ID: int = 999
const EVENT_TYPE: String = "InteractionPerformed"

var _terrain: TerrainData
var _points: Array[PointOfInterest] = []
var _host: SimulationHostNode
var _bridge: SimBridge
var _received: Array[InteractionPerformed] = []


func before_all() -> void:
	var terrain_loaded: TerrainLoader.LoadResult = TerrainLoader.load_dir(BLOCKOUT_DIR)
	assert_true(terrain_loaded.result.ok, terrain_loaded.result.message)
	_terrain = terrain_loaded.terrain
	var points_loaded: PointOfInterestLoader.LoadResult = PointOfInterestLoader.load_dir(BLOCKOUT_DIR, _terrain)
	assert_true(points_loaded.result.ok, points_loaded.result.message)
	_points = points_loaded.points


func before_each() -> void:
	_received.clear()
	_host = SimulationHostNode.new()
	_host.start_new_game(WORLD_SEED, _terrain, _points)
	_bridge = SimBridge.new(_host, _terrain)
	_host.runner.world.context.events.subscribe(EVENT_TYPE, _on_interaction)


func after_each() -> void:
	_host.runner.finish()
	_host.free()


func _on_interaction(event: SimEvent) -> void:
	_received.append(event as InteractionPerformed)


func _spawned_actor_at(point: Vector3) -> int:
	var reply: BridgeReplies.SpawnCharacterReply = _bridge.request_spawn_character()
	assert_true(reply.result.ok, reply.result.message)
	var reported: Result = _bridge.request_report_position(reply.actor_id, point, 0.0)
	assert_true(reported.ok, reported.message)
	return reply.actor_id


func test_peek_points_of_interest_returns_the_two_markers_as_copies_with_ground_height_and_reach() -> void:
	var reply: BridgeReplies.PointsReply = _bridge.peek_points_of_interest()
	assert_true(reply.result.ok, reply.result.message)
	assert_eq(reply.points.size(), 2)
	var near: BridgeReplies.PointReply = reply.points[0]
	assert_eq(near.id, "test_marker_near")
	assert_eq(near.kind, "test_marker")
	assert_eq(near.text_key, "poi.test_marker_near")
	assert_eq(near.x, NEAR_POINT.x)
	assert_eq(near.z, NEAR_POINT.z)
	assert_eq(near.reach_m, REACH_M)
	for point: BridgeReplies.PointReply in reply.points:
		var ground: BridgeReplies.HeightReply = _bridge.peek_height(point.x, point.z)
		assert_true(ground.result.ok)
		assert_almost_eq(point.y, ground.height_m, HEIGHT_TOLERANCE_M, "A altura é a do terreno.")
	near.text_key = "alterado"
	near.x = 0.0
	var again: BridgeReplies.PointsReply = _bridge.peek_points_of_interest()
	assert_eq(again.points[0].text_key, "poi.test_marker_near", "A resposta é cópia: mexer nela não altera a próxima.")
	assert_eq(again.points[0].x, NEAR_POINT.x)


func test_interacting_close_to_the_marker_returns_the_text_key_and_the_event_arrives_at_the_next_step() -> void:
	var actor_id: int = _spawned_actor_at(BESIDE_NEAR)
	var reply: BridgeReplies.InteractReply = _bridge.request_interact(actor_id, "test_marker_near")
	assert_true(reply.result.ok, reply.result.message)
	assert_eq(reply.poi_id, "test_marker_near")
	assert_eq(reply.text_key, "poi.test_marker_near")
	assert_eq(_received.size(), 0, "O evento só é entregue no dispatch do passo.")
	_host.runner.step_once()
	assert_eq(_received.size(), 1)
	assert_eq(_received[0].actor_id, actor_id)
	assert_eq(_received[0].poi_id, "test_marker_near")
	assert_eq(_received[0].cause_id, SimEvent.NO_CAUSE)


func test_interacting_from_the_spawn_point_is_too_far_and_publishes_nothing() -> void:
	var spawn: BridgeReplies.SpawnCharacterReply = _bridge.request_spawn_character()
	assert_true(spawn.result.ok)
	var outcome: BridgeReplies.InteractReply = _bridge.request_interact(spawn.actor_id, "test_marker_near")
	assert_false(outcome.result.ok, "O nascimento fica a cerca de 20 m do marco perto.")
	assert_eq(outcome.result.code, InteractionService.CODE_TOO_FAR)
	assert_string_contains(outcome.result.message, "muito longe")
	assert_eq(outcome.text_key, "")
	_host.runner.step_once()
	assert_eq(_received.size(), 0)


func test_the_position_used_is_the_one_stored_in_the_character_not_one_given_by_the_caller() -> void:
	var actor_id: int = _spawned_actor_at(BESIDE_NEAR)
	assert_true(_bridge.request_interact(actor_id, "test_marker_near").result.ok)
	assert_true(_bridge.request_report_position(actor_id, FAR_POINT, 0.0).ok)
	var from_far: BridgeReplies.InteractReply = _bridge.request_interact(actor_id, "test_marker_near")
	assert_false(from_far.result.ok, "Depois de o corpo relatar que está longe, a simulação recusa; a ponte não aceita posição de fora.")
	assert_eq(from_far.result.code, InteractionService.CODE_TOO_FAR)
	assert_true(_bridge.request_interact(actor_id, "test_marker_far").result.ok, "Junto do marco longe, o marco longe vale.")


func test_an_unknown_actor_and_an_unknown_point_are_handled_errors() -> void:
	var unknown_actor: BridgeReplies.InteractReply = _bridge.request_interact(UNKNOWN_ACTOR_ID, "test_marker_near")
	assert_false(unknown_actor.result.ok)
	assert_eq(unknown_actor.result.code, CharacterModule.CODE_UNKNOWN_ACTOR, "Ator desconhecido: o código é o do personagem.")
	var actor_id: int = _spawned_actor_at(BESIDE_NEAR)
	var unknown_point: BridgeReplies.InteractReply = _bridge.request_interact(actor_id, "no_such_point")
	assert_false(unknown_point.result.ok)
	assert_eq(unknown_point.result.code, InteractionService.CODE_UNKNOWN_POI)
	_host.runner.step_once()
	assert_eq(_received.size(), 0)
	assert_eq(_host.runner.world.validate().size(), 0)


func test_a_bridge_without_host_or_without_a_game_gives_the_no_game_code() -> void:
	var alone: SimBridge = SimBridge.new(null, _terrain)
	assert_eq(alone.peek_points_of_interest().result.code, SimBridge.CODE_NO_GAME)
	assert_eq(alone.request_interact(1, "test_marker_near").result.code, SimBridge.CODE_NO_GAME)
	var idle: SimulationHostNode = SimulationHostNode.new()
	var idle_bridge: SimBridge = SimBridge.new(idle, _terrain)
	assert_eq(idle_bridge.peek_points_of_interest().result.code, SimBridge.CODE_NO_GAME)
	assert_eq(idle_bridge.request_interact(1, "test_marker_near").result.code, SimBridge.CODE_NO_GAME)
	idle.free()


func test_a_game_started_without_terrain_has_no_interaction_service() -> void:
	var bare: SimulationHostNode = SimulationHostNode.new()
	bare.start_new_game(WORLD_SEED)
	assert_null(bare.interaction)
	var bridge: SimBridge = SimBridge.new(bare, _terrain)
	var points: BridgeReplies.PointsReply = bridge.peek_points_of_interest()
	assert_false(points.result.ok)
	assert_eq(points.result.code, SimBridge.CODE_NO_INTERACTION)
	assert_string_contains(points.result.message, "start_new_game")
	assert_eq(bridge.request_interact(1, "test_marker_near").result.code, SimBridge.CODE_NO_INTERACTION)
	bare.runner.finish()
	bare.free()


func test_the_real_boot_has_the_points_in_the_world_of_the_game() -> void:
	var host: SimulationHostNode = get_node("/root/SimulationHost") as SimulationHostNode
	var app: GameAppNode = get_node("/root/GameApp") as GameAppNode
	assert_not_null(host.interaction, "O GameApp leu o pois.json ao iniciar o jogo.")
	var reply: BridgeReplies.PointsReply = app.peek_bridge().peek_points_of_interest()
	assert_true(reply.result.ok, reply.result.message)
	assert_eq(reply.points.size(), 2)
