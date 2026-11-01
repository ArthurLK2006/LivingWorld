extends GutTest

const MODULE_NAMES: Array[String] = ["alpha", "beta", "gamma"]

var _log: Array[String] = []
var _world: World
var _modules: Array[FakeModule] = []


func _build_world(world_seed: int = 5) -> World:
	var clock: SimClock = SimClock.new()
	var context: SimContext = SimContext.new(clock, EventBus.new(clock), WorldRng.new(world_seed), IdGenerator.new())
	var world: World = World.new(context)
	return world


func _register_all(world: World, log: Array[String], modules: Array[FakeModule]) -> void:
	for module_name: String in MODULE_NAMES:
		var module: FakeModule = FakeModule.new(module_name, log)
		modules.append(module)
		assert_true(world.register_module(module_name, module).ok)


func before_each() -> void:
	_log = []
	_modules = []
	_world = _build_world()
	_register_all(_world, _log, _modules)


func after_each() -> void:
	_world.teardown()


func test_lifecycle_calls_modules_in_declared_order() -> void:
	_world.setup()
	_world.post_setup()
	_world.on_new_game(99)
	_world.tick(1)
	assert_eq(_log, [
		"alpha.setup", "beta.setup", "gamma.setup",
		"alpha.post_setup", "beta.post_setup", "gamma.post_setup",
		"alpha.on_new_game(99)", "beta.on_new_game(99)", "gamma.on_new_game(99)",
		"alpha.tick(1)", "beta.tick(1)", "gamma.tick(1)",
	] as Array[String])


func test_teardown_runs_in_reverse_order_and_only_once() -> void:
	_world.setup()
	_log.clear()
	_world.teardown()
	_world.teardown()
	assert_eq(_log, ["gamma.teardown", "beta.teardown", "alpha.teardown"] as Array[String])


func test_teardown_before_setup_does_not_touch_modules() -> void:
	_world.teardown()
	assert_eq(_log.size(), 0, "Módulo que não passou por setup não deve receber teardown.")
	_world.setup()
	assert_eq(_log.size(), 0, "Depois de encerrado, o mundo não roda setup.")
	assert_push_error("já executado ou mundo encerrado")


func test_registration_rejects_duplicates_empty_names_and_late_registration() -> void:
	var duplicate: Result = _world.register_module("alpha", FakeModule.new("again", _log))
	assert_false(duplicate.ok)
	assert_eq(duplicate.code, "WORLD_DUPLICATE_MODULE")
	assert_eq(_world.register_module("", FakeModule.new("x", _log)).code, "WORLD_INVALID_MODULE")
	assert_eq(_world.register_module("nullable", null).code, "WORLD_INVALID_MODULE")
	_world.setup()
	assert_eq(_world.register_module("late", FakeModule.new("late", _log)).code, "WORLD_REGISTRATION_CLOSED")
	assert_eq(_world.module_names(), MODULE_NAMES)


func test_second_setup_is_refused() -> void:
	_world.setup()
	_world.setup()
	assert_push_error("já executado")
	assert_eq(_log.filter(func(line: String) -> bool: return line.ends_with(".setup")).size(), 3)


func test_validate_aggregates_module_problems_with_their_names() -> void:
	_modules[1].problems.append("estoque negativo")
	var problems: Array[String] = _world.validate()
	assert_eq(problems, ["[beta] estoque negativo"] as Array[String])
	var summary: Dictionary = _world.debug_summary()
	assert_eq(summary["problems"], problems, "O erro de validate() deve aparecer no resumo.")
	assert_eq(summary["modules"].keys(), MODULE_NAMES)
	assert_true(summary["clock"].has("year"))


func test_validate_includes_core_problems() -> void:
	_world.context.events.publish(TestEvent.new("TestPinged"))
	var problems: Array[String] = _world.validate()
	assert_eq(problems.size(), 1)
	assert_true(problems[0].begins_with("[core] "))


func test_save_and_load_restore_core_and_modules_through_json() -> void:
	_world.setup()
	_world.tick(3)
	_world.context.clock.advance_step()
	_world.context.ids.next_id()
	_world.context.rng.range_int("shared_stream", 0, 1000)
	var original_state: Dictionary = _world.serialize()
	var saved: Variant = JSON.parse_string(JSON.stringify(original_state))
	var other_log: Array[String] = []
	var other_modules: Array[FakeModule] = []
	var other: World = _build_world(0)
	_register_all(other, other_log, other_modules)
	other.setup()
	var result: Result = other.on_load(saved)
	assert_true(result.ok, result.message)
	assert_eq(other.serialize(), original_state, "Logo após carregar, o estado deve ser idêntico ao salvo.")
	assert_eq(other.context.clock.total_minutes(), 1)
	assert_eq(other.context.ids.next_id(), 2)
	assert_eq(other.context.rng.range_int("shared_stream", 0, 1000), _world.context.rng.range_int("shared_stream", 0, 1000))
	assert_eq(other_modules[2].value, 3)
	other.teardown()


func test_on_load_rejects_bad_structure_without_touching_modules() -> void:
	var good: Dictionary = _world.serialize()
	var missing_module: Dictionary = good.duplicate(true)
	missing_module["modules"].erase("beta")
	var unknown_module: Dictionary = good.duplicate(true)
	unknown_module["modules"]["ghost"] = {}
	var broken_core: Dictionary = good.duplicate(true)
	broken_core["core"].erase("rng")
	var expectations: Array[Array] = [
		[{}, "WORLD_INVALID_SAVE"],
		[missing_module, "WORLD_MODULE_DATA_MISSING"],
		[unknown_module, "WORLD_UNKNOWN_MODULE"],
		[broken_core, "WORLD_INVALID_SAVE"],
	]
	_log.clear()
	for expectation: Array in expectations:
		var result: Result = _world.on_load(expectation[0])
		assert_false(result.ok)
		assert_eq(result.code, expectation[1])
	assert_eq(_log.size(), 0, "Estrutura inválida não pode chamar on_load dos módulos.")


func test_module_load_failure_names_the_module() -> void:
	_modules[2].fails_on_load = true
	var result: Result = _world.on_load(_world.serialize())
	assert_false(result.ok)
	assert_eq(result.code, "FAKE_LOAD_FAILED")
	assert_string_contains(result.message, "módulo 'gamma'")
