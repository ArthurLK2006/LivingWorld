extends GutTest

## Terreno de teste (somente leitura): mapa de 8 x 6 m; nascimento do arquivo em x 3,0 m, z 2,0 m.
const TERRAIN_DIR: String = "res://tests/fixtures/world/terrain_ok"
const FAR_X: float = 8.0
const FAR_Z: float = 6.0
const MILLIMETER: float = 0.001
const SPAWN_POINT: Vector3 = Vector3(3.0, 14.0, 2.0)

var _terrain: TerrainData
var _module: CharacterModule
var _world: World


func _load_terrain() -> TerrainData:
	var loaded: TerrainLoader.LoadResult = TerrainLoader.load_dir(TERRAIN_DIR)
	assert_true(loaded.result.ok, loaded.result.message)
	return loaded.terrain


## Mundo de teste com o módulo registrado e já em setup(); quem chama faz o teardown().
func _new_world(module: CharacterModule) -> World:
	var clock: SimClock = SimClock.new()
	var world: World = World.new(SimContext.new(clock, EventBus.new(clock), WorldRng.new(3), IdGenerator.new()))
	assert_true(world.register_module("character", module).ok)
	world.setup()
	return world


func before_each() -> void:
	_terrain = _load_terrain()
	_module = CharacterModule.new(_terrain)
	_world = _new_world(_module)


func after_each() -> void:
	_world.teardown()


func _spawn() -> int:
	var spawned: SpawnResult = _module.request_spawn()
	assert_true(spawned.result.ok, spawned.result.message)
	return spawned.actor_id


func _scripted_hash() -> String:
	var module: CharacterModule = CharacterModule.new(_load_terrain())
	var world: World = _new_world(module)
	module.report_position(module.request_spawn().actor_id, Vector3(2.0, 3.0, 4.0), 0.75)
	var state_hash: String = world.state_hash()
	world.teardown()
	return state_hash


func test_spawn_happens_at_the_terrain_spawn_point() -> void:
	var query: CharacterQuery = _module.peek_character(_spawn())
	assert_true(query.result.ok, query.result.message)
	assert_eq(query.position, _terrain.peek_spawn_point(), "Deve nascer no ponto de nascimento do world.")
	assert_eq(query.position, SPAWN_POINT)
	assert_eq(query.yaw, CharacterModule.SPAWN_YAW)


func test_spawns_get_different_increasing_ids_from_the_core_counter() -> void:
	var counter_before: int = _world.context.ids.debug_summary()["next_id"]
	var first: int = _spawn()
	var second: int = _spawn()
	assert_eq(first, counter_before, "O ID vem do contador do core (ctx.ids).")
	assert_gt(second, first)
	assert_eq(_world.context.ids.debug_summary()["next_id"], counter_before + 2, "O contador do core avançou.")


func test_reported_position_is_accepted_and_returned_as_given() -> void:
	var actor_id: int = _spawn()
	var in_the_air: Vector3 = Vector3(1.5, 100.0, 4.25)
	assert_true(_module.report_position(actor_id, in_the_air, 2.5).ok, "Altura Y só precisa ser finita.")
	var query: CharacterQuery = _module.peek_character(actor_id)
	assert_eq(query.position, in_the_air)
	assert_eq(query.yaw, 2.5)
	assert_true(_module.report_position(actor_id, in_the_air, 10.0).ok)
	assert_eq(_module.peek_character(actor_id).yaw, 10.0, "O yaw é guardado como veio, sem normalizar.")


func test_points_exactly_on_the_map_border_are_accepted() -> void:
	var actor_id: int = _spawn()
	for corner: Vector3 in [Vector3(0.0, 5.0, 0.0), Vector3(FAR_X, 5.0, 0.0), Vector3(0.0, 5.0, FAR_Z), Vector3(FAR_X, 5.0, FAR_Z)]:
		assert_true(_module.report_position(actor_id, corner, 0.0).ok, "Canto %s." % [corner])


func test_points_one_millimeter_outside_are_refused_without_changing_the_state() -> void:
	var actor_id: int = _spawn()
	var state_before: Dictionary = _module.serialize()
	var hash_before: String = _world.state_hash()
	for outside: Vector3 in [Vector3(-MILLIMETER, 0.0, 3.0), Vector3(FAR_X + MILLIMETER, 0.0, 3.0), Vector3(4.0, 0.0, -MILLIMETER), Vector3(4.0, 0.0, FAR_Z + MILLIMETER)]:
		var result: Result = _module.report_position(actor_id, outside, 1.0)
		assert_false(result.ok, "Fora do mapa em %s." % [outside])
		assert_eq(result.code, CharacterModule.CODE_OUT_OF_BOUNDS)
		assert_string_contains(result.message, "fora do mapa")
	assert_eq(_module.serialize(), state_before, "Recusa não altera o estado.")
	assert_eq(_world.state_hash(), hash_before)


func test_non_finite_values_are_refused_without_changing_the_state() -> void:
	var actor_id: int = _spawn()
	var state_before: Dictionary = _module.serialize()
	for bad: float in [NAN, INF, -INF]:
		for attempt: Array in [[Vector3(bad, 1.0, 1.0), 0.0], [Vector3(1.0, bad, 1.0), 0.0], [Vector3(1.0, 1.0, bad), 0.0], [Vector3(1.0, 1.0, 1.0), bad]]:
			var result: Result = _module.report_position(actor_id, attempt[0], attempt[1])
			assert_false(result.ok, "Valor %s." % [attempt])
			assert_eq(result.code, CharacterModule.CODE_INVALID_VALUE)
	assert_eq(_module.serialize(), state_before)


func test_unknown_actor_ids_fail_without_crashing() -> void:
	var known: int = _spawn()
	for bad_id: int in [0, -1, known + 1, 99999999]:
		var reported: Result = _module.report_position(bad_id, Vector3(1.0, 1.0, 1.0), 0.0)
		assert_eq(reported.code, CharacterModule.CODE_UNKNOWN_ACTOR, "report_position com ID %d." % bad_id)
		assert_string_contains(reported.message, str(bad_id))
		var query: CharacterQuery = _module.peek_character(bad_id)
		assert_false(query.result.ok)
		assert_eq(query.result.code, CharacterModule.CODE_UNKNOWN_ACTOR, "peek_character com ID %d." % bad_id)


func test_commands_fail_when_the_module_is_not_ready() -> void:
	var without_setup: CharacterModule = CharacterModule.new(_terrain)
	assert_eq(without_setup.request_spawn().result.code, CharacterModule.CODE_NOT_READY)
	assert_eq(without_setup.report_position(1, Vector3.ZERO, 0.0).code, CharacterModule.CODE_NOT_READY)
	var ids: Dictionary[int, String] = {1: "grass"}
	var broken: TerrainData = TerrainData.new(Vector2i(2, 1), 100, 1, PackedInt64Array([0, 10]), PackedInt64Array([1, 5]), ids, Vector2i(500, 0))
	for bad_terrain: TerrainData in [null, broken]:
		var module: CharacterModule = CharacterModule.new(bad_terrain)
		var world: World = _new_world(module)
		assert_eq(module.request_spawn().result.code, CharacterModule.CODE_NOT_READY, "Terreno nulo ou inválido.")
		assert_false(module.debug_summary()["terrain_ready"])
		assert_gt(module.validate().size(), 0)
		world.teardown()


func test_save_round_trip_through_json_keeps_answers_and_hash() -> void:
	var first: int = _spawn()
	var second: int = _spawn()
	assert_true(_module.report_position(first, Vector3(1.1, 2.2, 3.3), 0.1 + 0.2).ok)
	var saved: Variant = JSON.parse_string(JSON.stringify(_world.serialize(), "", true, true))
	var other_module: CharacterModule = CharacterModule.new(_load_terrain())
	var other: World = _new_world(other_module)
	var loaded: Result = other.on_load(saved)
	assert_true(loaded.ok, loaded.message)
	for actor_id: int in [first, second]:
		var before: CharacterQuery = _module.peek_character(actor_id)
		var after: CharacterQuery = other_module.peek_character(actor_id)
		assert_eq(after.position, before.position, "Posição do ator %d." % actor_id)
		assert_eq(after.yaw, before.yaw, "Yaw do ator %d." % actor_id)
	assert_eq(other.state_hash(), _world.state_hash(), "O hash deve ser igual antes e depois de salvar e carregar.")
	assert_eq(other_module.request_spawn().actor_id, _module.request_spawn().actor_id, "O contador de IDs também volta do save.")
	other.teardown()


func test_character_enters_the_state_hash() -> void:
	var empty_hash: String = _world.state_hash()
	var actor_id: int = _spawn()
	var spawned_hash: String = _world.state_hash()
	assert_ne(spawned_hash, empty_hash)
	assert_true(_world.serialize()["modules"].has("character"), "O estado do módulo vai no serialize do mundo.")
	assert_true(_module.report_position(actor_id, Vector3(2.0, 3.0, 4.0), 0.75).ok)
	var moved_hash: String = _world.state_hash()
	assert_ne(moved_hash, spawned_hash, "Só a posição mudou (o contador de IDs não): o módulo entra no hash.")
	assert_false(_module.report_position(actor_id, Vector3(-1.0, 0.0, 0.0), 0.0).ok)
	assert_eq(_world.state_hash(), moved_hash, "Comando recusado não muda o hash.")


func test_two_identical_runs_give_the_same_hash() -> void:
	assert_eq(_scripted_hash(), _scripted_hash())


func test_on_load_rejects_invalid_data_and_keeps_the_state() -> void:
	_spawn()
	var state_before: Dictionary = _module.serialize()
	var good: Dictionary = {"position": [1.0, 2.0, 3.0], "yaw": 0.5}
	var cases: Array[Dictionary] = [
		{}, {"characters": 5}, {"characters": {"1": 5}},
		{"characters": {"1": {"yaw": 0.5}}},
		{"characters": {"1": {"position": [1.0, 2.0], "yaw": 0.5}}},
		{"characters": {"1": {"position": [1.0, "dois", 3.0], "yaw": 0.5}}},
		{"characters": {"1": {"position": [NAN, 2.0, 3.0], "yaw": 0.5}}},
		{"characters": {"1": {"position": [1.0e300, 2.0, 3.0], "yaw": 0.5}}},
		{"characters": {"1": {"position": [1.0, 2.0, 3.0], "yaw": INF}}},
		{"characters": {"1": {"position": [1.0, 2.0, 3.0]}}},
		{"characters": {"abc": good}}, {"characters": {"1.5": good}}, {"characters": {"0": good}},
		{"characters": {"-3": good}}, {"characters": {"9007199254740992": good}},
		{"characters": {"1": good, "01": good}},
	]
	for invalid: Dictionary in cases:
		var result: Result = _module.on_load(invalid)
		assert_false(result.ok, "Deveria recusar %s." % [invalid])
		assert_eq(result.code, CharacterModule.CODE_INVALID_SAVE)
	assert_eq(_module.serialize(), state_before, "Carga recusada não altera o estado.")


func test_spawn_never_overwrites_a_loaded_character_with_the_same_id() -> void:
	assert_true(_module.on_load({"characters": {"1": {"position": [1.0, 2.0, 3.0], "yaw": 0.5}}}).ok)
	assert_eq(_module.request_spawn().result.code, CharacterModule.CODE_DUPLICATE_ID, "O contador do mundo novo ainda está em 1.")
	assert_eq(_module.peek_character(1).position, Vector3(1.0, 2.0, 3.0))


func test_peek_returns_a_copy_that_does_not_follow_later_changes() -> void:
	var actor_id: int = _spawn()
	var old: CharacterQuery = _module.peek_character(actor_id)
	assert_true(_module.report_position(actor_id, Vector3(5.0, 5.0, 5.0), 1.0).ok)
	assert_eq(old.position, SPAWN_POINT)
	assert_eq(old.yaw, CharacterModule.SPAWN_YAW)


func test_validate_and_debug_summary_describe_the_state() -> void:
	assert_eq(_module.validate().size(), 0, str(_module.validate()))
	var first: int = _spawn()
	var second: int = _spawn()
	var summary: Dictionary = _module.debug_summary()
	assert_eq(summary["count"], 2)
	assert_eq(summary["actor_ids"].size(), 2)
	assert_eq(summary["actor_ids"][0], first)
	assert_eq(summary["actor_ids"][1], second)
	assert_true(summary["terrain_ready"])
	assert_eq(_module.validate().size(), 0)


func test_validate_points_out_positions_outside_the_map_and_corrupted_values() -> void:
	assert_true(_module.on_load({"characters": {"1": {"position": [100.0, 0.0, 0.0], "yaw": 0.0}}}).ok, "Formato válido: carrega.")
	assert_string_contains(str(_module.validate()), "fora do mapa")
	# Acesso direto ao Dictionary interno só aqui, para simular estado corrompido que on_load nunca aceita.
	_module._characters[0] = CharacterState.new(Vector3(NAN, 0.0, 0.0), INF)
	var problems: String = str(_module.validate())
	assert_string_contains(problems, "ID fora da faixa")
	assert_string_contains(problems, "valor não finito")
