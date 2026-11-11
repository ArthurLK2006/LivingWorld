extends GutTest
## LW-048: a ponte repassa o nascimento e o relato de posição ao módulo do personagem do jogo (sem janela e sem física). Usa o
## terreno de blockout real e o MESMO registro de módulos que o jogo (GameModules). Quem decide "dentro do mapa", valor finito e ator
## existente é o CharacterModule; a ponte só repassa e traduz a ausência de jogo ou de personagem em códigos próprios.

const BLOCKOUT_DIR: String = "res://data/world"
const WORLD_SEED: int = 3
const POSITION_TOLERANCE_M: float = 0.001
const REPORTED_POSITION: Vector3 = Vector3(120.0, 10.0, 500.0)
const REPORTED_YAW: float = 1.5
const OTHER_POSITION: Vector3 = Vector3(300.0, 12.0, 400.0)
const OUTSIDE_POSITION: Vector3 = Vector3(-5.0, 10.0, 500.0)
const UNKNOWN_ACTOR_ID: int = 999
## Escrito à mão: é a chave do módulo no save, e mudá-la sem querer quebraria os saves.
const EXPECTED_MODULE_NAME: String = "character"
## Desde a LW-057 o mundo do jogo também tem o módulo `npc` e, desde a LW-088a, a `economy` antes dele: a ordem é `character`, `economy`, `npc` (escrito à mão, como acima).
const EXPECTED_ECONOMY_MODULE_NAME: String = "economy"
const EXPECTED_NPC_MODULE_NAME: String = "npc"

var _terrain: TerrainData
var _host: SimulationHostNode
var _bridge: SimBridge


func before_all() -> void:
	var loaded: TerrainLoader.LoadResult = TerrainLoader.load_dir(BLOCKOUT_DIR)
	assert_true(loaded.result.ok, loaded.result.message)
	_terrain = loaded.terrain


func before_each() -> void:
	_host = SimulationHostNode.new()
	_host.start_new_game(WORLD_SEED, _terrain)
	_bridge = SimBridge.new(_host, _terrain)


func after_each() -> void:
	_host.runner.finish()
	_host.free()


func _spawned_actor() -> int:
	var reply: BridgeReplies.SpawnCharacterReply = _bridge.request_spawn_character()
	assert_true(reply.result.ok, reply.result.message)
	return reply.actor_id


func test_spawn_gives_a_new_actor_at_the_spawn_point_with_zero_yaw() -> void:
	var actor_id: int = _spawned_actor()
	assert_gt(actor_id, IdGenerator.NO_ID)
	var spawn: Vector3 = _bridge.peek_spawn_point().point
	var stored: BridgeReplies.CharacterReply = _bridge.peek_character(actor_id)
	assert_true(stored.result.ok, stored.result.message)
	assert_almost_eq(stored.position.x, spawn.x, POSITION_TOLERANCE_M)
	assert_almost_eq(stored.position.y, spawn.y, POSITION_TOLERANCE_M)
	assert_almost_eq(stored.position.z, spawn.z, POSITION_TOLERANCE_M)
	assert_eq(stored.yaw, CharacterModule.SPAWN_YAW)


func test_each_spawn_gets_a_different_actor_id() -> void:
	var first: int = _spawned_actor()
	var second: int = _spawned_actor()
	assert_ne(first, second, "A ponte não supõe um jogador só: cada nascimento é um ator novo.")
	assert_true(_bridge.peek_character(first).result.ok)
	assert_true(_bridge.peek_character(second).result.ok)


func test_a_reported_position_and_yaw_are_stored_and_read_back_as_a_copy() -> void:
	var actor_id: int = _spawned_actor()
	var outcome: Result = _bridge.request_report_position(actor_id, REPORTED_POSITION, REPORTED_YAW)
	assert_true(outcome.ok, outcome.message)
	var first: BridgeReplies.CharacterReply = _bridge.peek_character(actor_id)
	assert_eq(first.position, REPORTED_POSITION)
	assert_eq(first.yaw, REPORTED_YAW)
	assert_true(_bridge.request_report_position(actor_id, OTHER_POSITION, 0.0).ok)
	assert_eq(first.position, REPORTED_POSITION, "A resposta já entregue é cópia: não muda com o relato seguinte.")
	assert_eq(_bridge.peek_character(actor_id).position, OTHER_POSITION)


func test_unknown_actor_is_a_handled_error_for_report_and_peek() -> void:
	var invalid_ids: Array[int] = [UNKNOWN_ACTOR_ID, IdGenerator.NO_ID, -1]
	for actor_id: int in invalid_ids:
		var report: Result = _bridge.request_report_position(actor_id, REPORTED_POSITION, REPORTED_YAW)
		assert_false(report.ok, "Relato para o ator %d deveria ser recusado." % actor_id)
		assert_eq(report.code, CharacterModule.CODE_UNKNOWN_ACTOR)
		var peek: BridgeReplies.CharacterReply = _bridge.peek_character(actor_id)
		assert_false(peek.result.ok)
		assert_eq(peek.result.code, CharacterModule.CODE_UNKNOWN_ACTOR)
	assert_eq(_host.runner.world.validate().size(), 0, "Nada foi corrompido pelos pedidos recusados.")


func test_non_finite_values_and_positions_outside_the_map_are_refused_and_change_nothing() -> void:
	var actor_id: int = _spawned_actor()
	assert_true(_bridge.request_report_position(actor_id, REPORTED_POSITION, REPORTED_YAW).ok)
	var hash_before: String = _host.runner.world.state_hash()
	var not_a_number: Result = _bridge.request_report_position(actor_id, Vector3(NAN, 10.0, 500.0), REPORTED_YAW)
	assert_false(not_a_number.ok)
	assert_eq(not_a_number.code, CharacterModule.CODE_INVALID_VALUE)
	var infinite_yaw: Result = _bridge.request_report_position(actor_id, REPORTED_POSITION, INF)
	assert_false(infinite_yaw.ok)
	assert_eq(infinite_yaw.code, CharacterModule.CODE_INVALID_VALUE)
	var outside: Result = _bridge.request_report_position(actor_id, OUTSIDE_POSITION, REPORTED_YAW)
	assert_false(outside.ok)
	assert_eq(outside.code, CharacterModule.CODE_OUT_OF_BOUNDS)
	assert_eq(_host.runner.world.state_hash(), hash_before, "Relato recusado não altera o estado.")
	assert_eq(_bridge.peek_character(actor_id).position, REPORTED_POSITION)


func test_a_bridge_without_host_fails_with_a_code_and_does_not_crash() -> void:
	var alone: SimBridge = SimBridge.new(null, _terrain)
	var spawn: BridgeReplies.SpawnCharacterReply = alone.request_spawn_character()
	assert_false(spawn.result.ok)
	assert_eq(spawn.result.code, SimBridge.CODE_NO_GAME)
	assert_string_contains(spawn.result.message, "request_spawn_character")
	var report: Result = alone.request_report_position(1, REPORTED_POSITION, REPORTED_YAW)
	assert_eq(report.code, SimBridge.CODE_NO_GAME)
	assert_string_contains(report.message, "request_report_position")
	var peek: BridgeReplies.CharacterReply = alone.peek_character(1)
	assert_eq(peek.result.code, SimBridge.CODE_NO_GAME)
	assert_string_contains(peek.result.message, "peek_character")


func test_a_host_that_has_not_started_a_game_gives_the_no_game_code() -> void:
	var idle: SimulationHostNode = SimulationHostNode.new()
	var bridge: SimBridge = SimBridge.new(idle, _terrain)
	assert_eq(bridge.request_spawn_character().result.code, SimBridge.CODE_NO_GAME)
	assert_eq(bridge.request_report_position(1, REPORTED_POSITION, 0.0).code, SimBridge.CODE_NO_GAME)
	assert_eq(bridge.peek_character(1).result.code, SimBridge.CODE_NO_GAME)
	idle.free()


func test_a_game_started_without_terrain_has_no_character_module() -> void:
	var bare: SimulationHostNode = SimulationHostNode.new()
	bare.start_new_game(WORLD_SEED)
	assert_null(bare.character)
	assert_eq(bare.runner.world.module_names().size(), 0, "Sem terreno o mundo nasce só com o núcleo.")
	var bridge: SimBridge = SimBridge.new(bare, _terrain)
	var spawn: BridgeReplies.SpawnCharacterReply = bridge.request_spawn_character()
	assert_false(spawn.result.ok)
	assert_eq(spawn.result.code, SimBridge.CODE_NO_CHARACTER)
	assert_string_contains(spawn.result.message, "start_new_game")
	assert_eq(bridge.request_report_position(1, REPORTED_POSITION, 0.0).code, SimBridge.CODE_NO_CHARACTER)
	assert_eq(bridge.peek_character(1).result.code, SimBridge.CODE_NO_CHARACTER)
	bare.runner.finish()
	bare.free()


func test_the_game_world_registers_the_character_module_under_its_name() -> void:
	assert_not_null(_host.character)
	var expected_names: Array[String] = [EXPECTED_MODULE_NAME, GameModules.WORLD_NAME, EXPECTED_ECONOMY_MODULE_NAME, EXPECTED_NPC_MODULE_NAME]
	assert_eq(_host.runner.world.module_names(), expected_names)
	assert_eq(GameModules.CHARACTER_NAME, EXPECTED_MODULE_NAME)


func test_game_modules_refuse_a_null_terrain_and_a_second_registration() -> void:
	var runner: SimulationRunner = SimulationRunner.new(WORLD_SEED)
	var without_terrain: GameModules = GameModules.register(runner, null)
	assert_false(without_terrain.result.ok)
	assert_eq(without_terrain.result.code, "GAME_MODULES_NO_TERRAIN")
	assert_null(without_terrain.character)
	assert_eq(runner.world.module_names().size(), 0, "Falha não registra nada.")
	var first: GameModules = GameModules.register(runner, _terrain)
	assert_true(first.result.ok, first.result.message)
	var second: GameModules = GameModules.register(runner, _terrain)
	assert_false(second.result.ok)
	assert_eq(second.result.code, "WORLD_DUPLICATE_MODULE")
	runner.start_new_game()
	var late: GameModules = GameModules.register(runner, _terrain)
	assert_false(late.result.ok)
	assert_eq(late.result.code, "WORLD_REGISTRATION_CLOSED")
	runner.finish()


func test_a_new_game_discards_the_previous_characters() -> void:
	var old_actor: int = _spawned_actor()
	_host.start_new_game(WORLD_SEED, _terrain)
	var peek: BridgeReplies.CharacterReply = _bridge.peek_character(old_actor)
	assert_false(peek.result.ok, "O mundo novo não tem o personagem do mundo antigo.")
	assert_eq(peek.result.code, CharacterModule.CODE_UNKNOWN_ACTOR)


func test_reporting_changes_the_state_hash_only_when_the_position_changes() -> void:
	var actor_id: int = _spawned_actor()
	var at_birth: String = _host.runner.world.state_hash()
	assert_true(_bridge.request_report_position(actor_id, REPORTED_POSITION, REPORTED_YAW).ok)
	var after_report: String = _host.runner.world.state_hash()
	assert_ne(after_report, at_birth, "O relato entra no state_hash.")
	assert_true(_bridge.request_report_position(actor_id, REPORTED_POSITION, REPORTED_YAW).ok)
	assert_eq(_host.runner.world.state_hash(), after_report, "Relatar o mesmo valor de novo não muda o hash.")


func test_two_new_games_with_the_same_seed_have_the_same_initial_hash_and_it_includes_the_character() -> void:
	var other: SimulationHostNode = SimulationHostNode.new()
	other.start_new_game(WORLD_SEED, _terrain)
	var bare: SimulationHostNode = SimulationHostNode.new()
	bare.start_new_game(WORLD_SEED)
	assert_eq(other.runner.world.state_hash(), _host.runner.world.state_hash(), "Mesma semente, mesmo hash inicial.")
	assert_ne(bare.runner.world.state_hash(), _host.runner.world.state_hash(), "Com o personagem registrado o hash do jogo mudou.")
	other.runner.finish()
	other.free()
	bare.runner.finish()
	bare.free()
