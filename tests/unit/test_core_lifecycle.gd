extends GutTest

var received: Array[Dictionary] = []
var bus: SimEventBus
var trace: Array[String] = []

class FakeModule extends SimModule:
	var label: String
	var trace: Array[String]
	var has_error: bool
	func _init(module_label: String, log: Array[String], error: bool = false) -> void:
		label = module_label
		trace = log
		has_error = error
	func setup(_ctx: SimContext) -> void: trace.append("setup:" + label)
	func post_setup() -> void: trace.append("post:" + label)
	func on_new_game(_world_seed: int) -> void: trace.append("new:" + label)
	func on_load(_data: Dictionary) -> void: trace.append("load:" + label)
	func tick(_dt_sim: float) -> void: trace.append("tick:" + label)
	func serialize() -> Dictionary: return {"name": label}
	func validate() -> Array[String]:
		var errors: Array[String] = []
		if has_error: errors.append("erro")
		return errors
	func debug_summary() -> Dictionary: return {"name": label}
	func teardown() -> void: trace.append("end:" + label)


func _receive(event: Dictionary) -> void:
	received.append(event)
	if event["type"] == "FirstOccurred":
		bus.publish("SecondOccurred")


func _receive_loop(_event: Dictionary) -> void:
	received.append(_event)
	bus.publish("LoopOccurred")


func _event_sequence() -> Array[Dictionary]:
	received.clear()
	bus = SimEventBus.new()
	bus.subscribe("FirstOccurred", _receive)
	bus.subscribe("SecondOccurred", _receive)
	bus.publish("FirstOccurred")
	bus.dispatch()
	return received.duplicate(true)


func test_event_order_cause_and_determinism() -> void:
	var first: Array[Dictionary] = _event_sequence()
	var second: Array[Dictionary] = _event_sequence()
	assert_eq(first, second)
	assert_eq(first.size(), 2)
	assert_eq(first[0]["type"], "FirstOccurred")
	assert_eq(first[1]["cause_id"], first[0]["id"])


func test_event_cycle_stops_with_identifiable_error() -> void:
	received.clear()
	bus = SimEventBus.new()
	bus.subscribe("LoopOccurred", _receive_loop)
	bus.publish("LoopOccurred")
	var result: SimResult = bus.dispatch(3)
	assert_false(result.ok)
	assert_eq(result.code, "EVENT_LIMIT_EXCEEDED")
	assert_eq(received.size(), 3)
	assert_eq(received[2]["cause_id"], received[1]["id"])
	assert_eq(bus.dispatch(0).code, "INVALID_EVENT_LIMIT")
	assert_eq(bus.dispatch(1).code, "EVENT_LIMIT_EXCEEDED")


func test_result_and_module_lifecycle() -> void:
	var success: SimResult = SimResult.new(true)
	var failure: SimResult = SimResult.new(false, "BAD", "erro")
	assert_true(success.ok)
	assert_false(failure.ok)
	assert_eq(failure.code, "BAD")
	assert_eq(failure.message, "erro")
	trace.clear()
	var world: SimWorld = SimWorld.new(SimContext.new(7))
	assert_true(world.register_module("a", FakeModule.new("a", trace)))
	assert_true(world.register_module("b", FakeModule.new("b", trace, true)))
	assert_true(world.register_module("c", FakeModule.new("c", trace)))
	assert_false(world.register_module("a", FakeModule.new("duplicate", trace)))
	world.setup()
	world.on_new_game(7)
	world.on_load({})
	world.tick(1.0)
	assert_eq(world.serialize().size(), 3)
	assert_eq(world.debug_summary().size(), 3)
	assert_eq(world.validate(), ["b: erro"])
	world.teardown()
	assert_eq(trace, ["setup:a", "setup:b", "setup:c", "post:a", "post:b", "post:c", "new:a", "new:b", "new:c", "load:a", "load:b", "load:c", "tick:a", "tick:b", "tick:c", "end:c", "end:b", "end:a"])
