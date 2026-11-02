extends GutTest


var _clock: SimClock
var _bus: EventBus
var _log: Array[String] = []


func after_each() -> void:
	_bus.teardown()


func before_each() -> void:
	_clock = SimClock.new()
	_bus = EventBus.new(_clock)
	_log = []


func _record(event: SimEvent) -> void:
	_log.append("%s#%d(cause %d)" % [event.type, event.id, event.cause_id])


func test_events_arrive_in_emission_order() -> void:
	_bus.subscribe("TestPinged", func(event: SimEvent) -> void: _log.append((event as TestEvent).tag))
	for tag: String in ["a", "b", "c"]:
		_bus.publish(TestEvent.new("TestPinged", tag))
	assert_eq(_bus.dispatch(), 3)
	assert_eq(_log, ["a", "b", "c"] as Array[String])


func test_publish_only_queues_until_dispatch() -> void:
	_bus.subscribe("TestPinged", _record)
	_bus.publish(TestEvent.new("TestPinged"))
	assert_eq(_log.size(), 0, "Publicar não pode entregar na hora.")
	_bus.dispatch()
	assert_eq(_log.size(), 1)


func test_listeners_run_in_subscription_order_and_only_for_their_type() -> void:
	_bus.subscribe("TestPinged", func(_e: SimEvent) -> void: _log.append("first"))
	_bus.subscribe("TestPonged", func(_e: SimEvent) -> void: _log.append("other type"))
	_bus.subscribe("TestPinged", func(_e: SimEvent) -> void: _log.append("second"))
	_bus.publish(TestEvent.new("TestPinged"))
	_bus.dispatch()
	assert_eq(_log, ["first", "second"] as Array[String])


func test_event_published_while_handling_is_queued_and_gets_cause_id() -> void:
	_bus.subscribe("TestPinged", func(event: SimEvent) -> void:
		_record(event)
		_bus.publish(TestEvent.new("TestPonged"))
		_log.append("end of ping handler"))
	_bus.subscribe("TestPonged", _record)
	_bus.publish(TestEvent.new("TestPinged"))
	_bus.dispatch()
	assert_eq(_log, ["TestPinged#1(cause 0)", "end of ping handler", "TestPonged#2(cause 1)"] as Array[String], "O evento novo só é tratado depois que o ouvinte atual termina.")


func test_cause_chain_is_followed_across_rounds() -> void:
	_bus.subscribe("TestPinged", func(event: SimEvent) -> void:
		_record(event)
		_bus.publish(TestEvent.new("TestPonged")))
	_bus.subscribe("TestPonged", func(event: SimEvent) -> void:
		_record(event)
		_bus.publish(TestEvent.new("TestEchoed")))
	_bus.subscribe("TestEchoed", _record)
	_bus.publish(TestEvent.new("TestPinged"))
	_bus.publish(TestEvent.new("TestPinged"))
	_bus.dispatch()
	assert_eq(_log, [
		"TestPinged#1(cause 0)", "TestPinged#2(cause 0)",
		"TestPonged#3(cause 1)", "TestPonged#4(cause 2)",
		"TestEchoed#5(cause 3)", "TestEchoed#6(cause 4)",
	] as Array[String])


func test_two_identical_runs_give_same_sequence() -> void:
	var first: Array[String] = _run_scenario()
	var second: Array[String] = _run_scenario()
	assert_eq(first, second)
	assert_gt(first.size(), 3)


func _run_scenario() -> Array[String]:
	var bus: EventBus = EventBus.new(SimClock.new())
	var call_log: Array[String] = []
	bus.subscribe("TestPinged", func(event: SimEvent) -> void:
		call_log.append("%s#%d<-%d@%d" % [event.type, event.id, event.cause_id, event.time])
		bus.publish(TestEvent.new("TestPonged")))
	bus.subscribe("TestPonged", func(event: SimEvent) -> void:
		call_log.append("%s#%d<-%d@%d" % [event.type, event.id, event.cause_id, event.time]))
	for _i: int in 3:
		bus.publish(TestEvent.new("TestPinged"))
	bus.dispatch()
	bus.teardown()
	return call_log


func test_round_limit_keeps_excess_for_next_dispatch() -> void:
	var counter: Array[int] = [0]
	_bus.subscribe("TestPinged", func(_e: SimEvent) -> void:
		counter[0] += 1
		_bus.publish(TestEvent.new("TestPinged")))
	_bus.publish(TestEvent.new("TestPinged"))
	assert_eq(_bus.dispatch(), EventBus.MAX_ROUNDS_PER_DISPATCH)
	assert_push_error("limite de 8 rodadas")
	assert_eq(counter[0], EventBus.MAX_ROUNDS_PER_DISPATCH)
	assert_eq(_bus.debug_summary()["pending"], 1, "O excedente fica na fila, sem perda.")
	assert_eq(_bus.dispatch(), EventBus.MAX_ROUNDS_PER_DISPATCH)
	assert_push_error("limite de 8 rodadas")


func test_events_carry_simulation_time() -> void:
	var times: Array[int] = []
	_bus.subscribe("TestPinged", func(event: SimEvent) -> void: times.append(event.time))
	_bus.publish(TestEvent.new("TestPinged"))
	_clock.advance_step()
	_clock.advance_step()
	_bus.publish(TestEvent.new("TestPinged"))
	_bus.dispatch()
	assert_eq(times, [0, 2] as Array[int])


func test_unsubscribe_stops_delivery_even_during_dispatch() -> void:
	var late_id: Array[int] = [0]
	_bus.subscribe("TestPinged", func(_e: SimEvent) -> void:
		_log.append("early")
		_bus.unsubscribe(late_id[0]))
	late_id[0] = _bus.subscribe("TestPinged", func(_e: SimEvent) -> void: _log.append("late"))
	_bus.publish(TestEvent.new("TestPinged"))
	_bus.dispatch()
	assert_eq(_log, ["early"] as Array[String], "Ouvinte cancelado antes da sua vez não é chamado.")
	_bus.unsubscribe(late_id[0])
	_bus.unsubscribe(999)


func test_invalid_subscription_is_reported() -> void:
	assert_eq(_bus.subscribe("", _record), EventBus.NO_SUBSCRIPTION)
	assert_push_error("tipo vazio ou ouvinte inválido")
	assert_eq(_bus.subscribe("TestPinged", Callable()), EventBus.NO_SUBSCRIPTION)
	assert_push_error("tipo vazio ou ouvinte inválido")


func test_dispatch_inside_a_listener_is_refused() -> void:
	_bus.subscribe("TestPinged", func(_e: SimEvent) -> void: _log.append(str(_bus.dispatch())))
	_bus.publish(TestEvent.new("TestPinged"))
	_bus.dispatch()
	assert_push_error("durante uma entrega")
	assert_eq(_log, ["0"] as Array[String])


func test_event_ids_continue_after_save_and_load() -> void:
	_bus.publish(TestEvent.new("TestPinged"))
	_bus.publish(TestEvent.new("TestPinged"))
	_bus.dispatch()
	var restored: EventBus = EventBus.new(_clock)
	var result: Result = restored.on_load(_bus.serialize())
	assert_true(result.ok, result.message)
	var event: TestEvent = TestEvent.new("TestPinged")
	restored.publish(event)
	assert_eq(event.id, 3)


func test_on_load_rejects_invalid_data() -> void:
	assert_false(_bus.on_load({}).ok)
	assert_false(_bus.on_load({"ids": {"next_id": "x"}}).ok)
	var event: TestEvent = TestEvent.new("TestPinged")
	_bus.publish(event)
	assert_eq(event.id, 1, "Dado inválido não pode alterar o contador.")


func test_validate_flags_pending_events_and_teardown_clears() -> void:
	assert_eq(_bus.validate().size(), 0)
	_bus.subscribe("TestPinged", _record)
	_bus.publish(TestEvent.new("TestPinged"))
	assert_eq(_bus.validate().size(), 1)
	assert_eq(_bus.debug_summary()["subscriptions"], 1)
	_bus.teardown()
	assert_eq(_bus.validate().size(), 0)
	assert_eq(_bus.debug_summary()["subscriptions"], 0)
