extends GutTest

const DAYS: int = 30


func _hash_after(world_seed: int, days: int) -> String:
	var runner: SimulationRunner = SimulationRunner.new(world_seed)
	assert_true(runner.register_module("walker", WalkerModule.new()).ok)
	runner.start_new_game()
	runner.run_days(days)
	var state_hash: String = runner.world.state_hash()
	runner.finish()
	return state_hash


func test_three_runs_with_same_seed_and_30_days_give_the_same_hash() -> void:
	var first: String = _hash_after(1, DAYS)
	assert_eq(_hash_after(1, DAYS), first)
	assert_eq(_hash_after(1, DAYS), first)


func test_different_seeds_give_different_hashes() -> void:
	assert_ne(_hash_after(1, DAYS), _hash_after(2, DAYS))


func test_hash_changes_as_the_world_evolves() -> void:
	assert_ne(_hash_after(1, 1), _hash_after(1, 2))


func test_hash_is_a_sha256_in_hexadecimal() -> void:
	var state_hash: String = _hash_after(1, 1)
	assert_eq(state_hash.length(), 64)
	assert_true(state_hash.is_valid_hex_number(false))


func test_hash_does_not_depend_on_dictionary_key_order() -> void:
	var first: World = _world_with_module(FakeModule.new("m", []))
	var second: World = _world_with_module(FakeModule.new("m", []))
	assert_eq(first.state_hash(), second.state_hash())
	var reordered: String = JSON.stringify({"b": 2, "a": 1, "c": {"y": 1, "x": 2}}, "", true, true).sha256_text()
	assert_eq(reordered, JSON.stringify({"c": {"x": 2, "y": 1}, "a": 1, "b": 2}, "", true, true).sha256_text())
	first.teardown()
	second.teardown()


func _world_with_module(module: SimModule) -> World:
	var clock: SimClock = SimClock.new()
	var world: World = World.new(SimContext.new(clock, EventBus.new(clock), WorldRng.new(4), IdGenerator.new()))
	world.register_module("m", module)
	world.setup()
	return world


func test_hash_reflects_module_state_changes() -> void:
	var module: FakeModule = FakeModule.new("m", [])
	var world: World = _world_with_module(module)
	var before: String = world.state_hash()
	module.value = 99
	assert_ne(world.state_hash(), before)
	world.teardown()
