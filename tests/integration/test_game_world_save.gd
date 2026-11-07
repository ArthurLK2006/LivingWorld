extends GutTest
## LW-048: o mundo do JOGO (núcleo + módulo do personagem, montado por GameModules) sobrevive à ida e volta de salvamento sem janela:
## SimulationRunner.capture_game -> JsonSaveCodec.encode -> decode -> SimulationRunner.load_game. Posição e orientação do personagem
## voltam EXATAS e o state_hash bate. A versão do formato do save não mudou (o arquivo tem a mesma estrutura {world, scheduler}; só o
## conjunto de módulos do jogo cresceu): um save de um mundo sem o personagem é recusado com mensagem clara (World.on_load).

const BLOCKOUT_DIR: String = "res://data/world"
const GAME_VERSION: String = "0.0.1-test"
const WORLD_SEED: int = 7
## Decimais longos de propósito: a ida e volta por JSON precisa devolver exatamente o mesmo Vector3 (32 bits).
const SAVED_POSITION: Vector3 = Vector3(123.456789, 10.123456, 321.987654)
const SAVED_YAW: float = -1.2345678901234
const STEPS_BEFORE_SAVE: int = 90
const STEPS_AFTER_LOAD: int = 300

var _terrain: TerrainData
var _codec: JsonSaveCodec = JsonSaveCodec.new()


## Um mundo do jogo: o runner e os módulos que GameModules registrou nele.
class GameWorldUnderTest:
	extends RefCounted

	var runner: SimulationRunner
	var modules: GameModules


func before_all() -> void:
	var loaded: TerrainLoader.LoadResult = TerrainLoader.load_dir(BLOCKOUT_DIR)
	assert_true(loaded.result.ok, loaded.result.message)
	_terrain = loaded.terrain


## Mundo montado como o do jogo, ainda não iniciado.
func _new_game_world() -> GameWorldUnderTest:
	var game: GameWorldUnderTest = GameWorldUnderTest.new()
	game.runner = SimulationRunner.new(WORLD_SEED)
	game.modules = GameModules.register(game.runner, _terrain)
	assert_true(game.modules.result.ok, game.modules.result.message)
	return game


## Mundo novo e iniciado, com um personagem que já relatou a posição de teste.
func _started_game_with_actor() -> Array:
	var game: GameWorldUnderTest = _new_game_world()
	game.runner.start_new_game()
	var spawn: SpawnResult = game.modules.character.request_spawn()
	assert_true(spawn.result.ok, spawn.result.message)
	var reported: Result = game.modules.character.report_position(spawn.actor_id, SAVED_POSITION, SAVED_YAW)
	assert_true(reported.ok, reported.message)
	return [game, spawn.actor_id]


func _decode(runner: SimulationRunner) -> DecodedSave:
	assert_true(runner.can_capture_game(), "Entre passos a fila de eventos está vazia.")
	var decoded: DecodedSave = _codec.decode(_codec.encode(runner.capture_game(), GAME_VERSION))
	assert_true(decoded.result.ok, decoded.result.message)
	return decoded


func test_the_game_world_round_trips_with_the_character_position_and_yaw_exact() -> void:
	var started: Array = _started_game_with_actor()
	var original: GameWorldUnderTest = started[0]
	var actor_id: int = started[1]
	original.runner.run_steps(STEPS_BEFORE_SAVE)
	var hash_before: String = original.runner.world.state_hash()
	var restored: GameWorldUnderTest = _new_game_world()
	var loaded: Result = restored.runner.load_game(_decode(original.runner).payload)
	assert_true(loaded.ok, loaded.message)
	assert_eq(restored.runner.world.state_hash(), hash_before, "O mundo carregado tem o hash do momento do salvamento.")
	var after: CharacterQuery = restored.modules.character.peek_character(actor_id)
	assert_true(after.result.ok, after.result.message)
	assert_eq(after.position, SAVED_POSITION, "Posição exata depois da ida e volta.")
	assert_eq(after.yaw, SAVED_YAW, "Orientação exata depois da ida e volta.")
	original.runner.run_steps(STEPS_AFTER_LOAD)
	restored.runner.run_steps(STEPS_AFTER_LOAD)
	assert_eq(restored.runner.world.state_hash(), original.runner.world.state_hash(), "Os dois mundos seguem iguais depois de rodar mais.")
	assert_eq(restored.runner.world.validate().size(), 0)
	original.runner.finish()
	restored.runner.finish()


func test_the_saved_payload_carries_the_character_under_its_module_name() -> void:
	var started: Array = _started_game_with_actor()
	var game: GameWorldUnderTest = started[0]
	var payload: Dictionary = _decode(game.runner).payload
	var modules: Dictionary = payload["world"]["modules"]
	assert_true(modules.has(GameModules.CHARACTER_NAME), "O personagem está no save do jogo.")
	var characters: Dictionary = modules[GameModules.CHARACTER_NAME]["characters"]
	assert_true(characters.has(str(started[1])))
	game.runner.finish()


func test_a_save_from_a_world_without_the_character_is_refused_with_a_clear_message() -> void:
	var bare: SimulationRunner = SimulationRunner.new(WORLD_SEED)
	bare.start_new_game()
	bare.run_steps(STEPS_BEFORE_SAVE)
	var game: GameWorldUnderTest = _new_game_world()
	var refused: Result = game.runner.load_game(_decode(bare).payload)
	assert_false(refused.ok, "Save antigo (sem o personagem) não carrega no mundo do jogo atual.")
	assert_eq(refused.code, "WORLD_MODULE_DATA_MISSING")
	assert_string_contains(refused.message, GameModules.CHARACTER_NAME)
	bare.finish()
	game.runner.finish()


func test_a_game_save_is_refused_by_a_world_that_does_not_register_the_character() -> void:
	var started: Array = _started_game_with_actor()
	var original: GameWorldUnderTest = started[0]
	var core_only: SimulationRunner = SimulationRunner.new(WORLD_SEED)
	var refused: Result = core_only.load_game(_decode(original.runner).payload)
	assert_false(refused.ok)
	assert_eq(refused.code, "WORLD_UNKNOWN_MODULE")
	assert_string_contains(refused.message, GameModules.CHARACTER_NAME)
	original.runner.finish()
	core_only.finish()


func test_two_full_game_runs_with_the_same_seed_end_with_the_same_hash() -> void:
	var first: GameWorldUnderTest = _new_game_world()
	first.runner.start_new_game()
	var second: GameWorldUnderTest = _new_game_world()
	second.runner.start_new_game()
	assert_eq(first.runner.world.state_hash(), second.runner.world.state_hash(), "Dois jogos novos com a mesma semente: mesmo hash.")
	first.runner.run_days(2)
	second.runner.run_days(2)
	assert_eq(first.runner.world.state_hash(), second.runner.world.state_hash())
	first.runner.finish()
	second.runner.finish()
