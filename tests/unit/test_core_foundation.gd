extends GutTest

const Ids = preload("res://src/core/ids.gd")
const Rng = preload("res://src/core/rng/world_rng.gd")
const Clock = preload("res://src/core/sim_clock.gd")


func test_ids_crescentes_e_restauracao() -> void:
	var ids: EntityIds = Ids.new()
	assert_eq(ids.allocate(), 1)
	assert_eq(ids.allocate(), 2)
	assert_true(ids.release(1))
	assert_false(ids.release(0))
	var restored: EntityIds = Ids.new()
	assert_true(restored.on_load(ids.serialize()))
	assert_eq(restored.allocate(), 3)
	assert_false(restored.on_load({"next_id": 0}))
	assert_eq(restored.allocate(), 4)


func test_rng_repeticao_isolamento_e_restauracao() -> void:
	var first: WorldRng = Rng.new(123)
	var second: WorldRng = Rng.new(123)
	assert_eq(first.next_int("economy"), second.next_int("economy"))
	first.next_int("npc")
	assert_eq(first.next_int("economy"), second.next_int("economy"))
	var restored: WorldRng = Rng.new()
	assert_true(restored.on_load(first.serialize()))
	assert_eq(first.next_int("economy"), restored.next_int("economy"))
	assert_false(restored.on_load({"world_seed": "invalid", "streams": {}}))


func test_clock_pausa_velocidade_e_restauracao() -> void:
	var clock: SimClock = Clock.new()
	assert_eq(clock.advance_steps(1), 1)
	clock.set_paused(true)
	assert_eq(clock.advance_steps(1), 0)
	assert_eq(clock.total_minutes(), 1)
	clock.set_paused(false)
	assert_true(clock.set_speed(4))
	assert_eq(clock.advance_steps(1), 4)
	assert_eq(clock.total_minutes(), 5)
	assert_false(clock.set_speed(3))
	assert_eq(clock.advance_steps(-1), 0)
	assert_true(clock.calendar(0).is_empty())
	var restored: SimClock = Clock.new()
	assert_true(restored.on_load(clock.serialize()))
	assert_eq(restored.total_minutes(), 5)
	assert_false(restored.on_load({"minutes": -1, "paused": false, "speed": 1}))
