extends GutTest


class RecordingModule:
	extends SimModule
	var calls: Array[String] = []
	var ctx: SimContext
	var value: int = 0
	var received_events: Array[String] = []

	func setup(context: SimContext) -> void:
		calls.append("setup")
		ctx = context

	func post_setup() -> void:
		calls.append("post_setup")
		ctx.events.subscribe("TestPinged", _on_ping)

	func on_new_game(world_seed: int) -> void:
		calls.append("on_new_game:%d" % world_seed)
		value = ctx.rng.range_int("recording_module", 1, 6)

	func on_load(data: Dictionary) -> void:
		calls.append("on_load")
		value = int(data["value"])

	func tick(dt_sim: float) -> void:
		calls.append("tick:%s" % str(dt_sim))
		value += 1

	func serialize() -> Dictionary:
		calls.append("serialize")
		return {"value": value}

	func validate() -> Array[String]:
		calls.append("validate")
		var problems: Array[String] = []
		if value < 0:
			problems.append("value negativo")
		return problems

	func debug_summary() -> Dictionary:
		calls.append("debug_summary")
		return {"value": value}

	func teardown() -> void:
		calls.append("teardown")

	func _on_ping(event: SimEvent) -> void:
		received_events.append("%s#%d" % [event.type, event.id])


var _context: SimContext


func before_each() -> void:
	var clock: SimClock = SimClock.new()
	_context = SimContext.new(clock, EventBus.new(clock), WorldRng.new(77), IdGenerator.new())


func after_each() -> void:
	_context.events.teardown()


func test_base_class_hooks_are_harmless_defaults() -> void:
	var module: SimModule = SimModule.new()
	module.setup(_context)
	module.post_setup()
	module.on_new_game(1)
	module.on_load({})
	module.tick(1.0)
	module.teardown()
	assert_eq(module.serialize(), {})
	assert_eq(module.validate(), [] as Array[String])
	assert_eq(module.debug_summary(), {})


func test_fake_module_follows_the_lifecycle_signatures() -> void:
	var module: RecordingModule = RecordingModule.new()
	var base: SimModule = module
	base.setup(_context)
	base.post_setup()
	base.on_new_game(77)
	base.tick(1.0)
	var saved: Dictionary = base.serialize()
	base.on_load(saved)
	assert_eq(base.validate().size(), 0)
	assert_true(base.debug_summary().has("value"))
	base.teardown()
	assert_eq(module.calls, [
		"setup", "post_setup", "on_new_game:77", "tick:1.0", "serialize", "on_load",
		"validate", "debug_summary", "teardown",
	] as Array[String])


func test_context_gives_modules_the_four_core_services() -> void:
	var module: RecordingModule = RecordingModule.new()
	module.setup(_context)
	assert_same(module.ctx.clock, _context.clock)
	assert_not_null(module.ctx.events)
	assert_not_null(module.ctx.rng)
	assert_eq(module.ctx.ids.next_id(), IdGenerator.FIRST_ID)


func test_module_draws_from_its_own_named_stream_of_the_shared_rng() -> void:
	var module: RecordingModule = RecordingModule.new()
	module.setup(_context)
	module.on_new_game(77)
	var expected: int = WorldRng.new(77).range_int("recording_module", 1, 6)
	assert_eq(module.value, expected)


func test_module_receives_events_through_the_context_bus() -> void:
	var module: RecordingModule = RecordingModule.new()
	module.setup(_context)
	module.post_setup()
	_context.events.publish(TestEvent.new("TestPinged"))
	_context.events.dispatch()
	assert_eq(module.received_events, ["TestPinged#1"] as Array[String])
	module.teardown()


func test_serialize_and_on_load_round_trip_through_json() -> void:
	var original: RecordingModule = RecordingModule.new()
	original.value = 42
	var parsed: Variant = JSON.parse_string(JSON.stringify(original.serialize()))
	var restored: RecordingModule = RecordingModule.new()
	restored.on_load(parsed)
	assert_eq(restored.value, 42)
