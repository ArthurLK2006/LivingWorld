extends GutTest

var _runner: SimulationRunner


func after_each() -> void:
	if _runner != null:
		_runner.finish()
		_runner = null


func _runner_with_module(world_seed: int, call_log: Array[String]) -> SimulationRunner:
	var runner: SimulationRunner = SimulationRunner.new(world_seed)
	assert_true(runner.register_module("fake", FakeModule.new("fake", call_log)).ok)
	runner.start_new_game()
	call_log.clear()
	return runner


func test_30_days_advance_exactly_30_days_of_minutes() -> void:
	_runner = SimulationRunner.new(1)
	_runner.start_new_game()
	_runner.run_days(30)
	var clock: SimClock = _runner.world.context.clock
	assert_eq(clock.total_minutes(), 30 * SimClock.MINUTES_PER_DAY)
	assert_eq([clock.year(), clock.day_of_year(), clock.hour_of_day(), clock.minute_of_hour()], [1, 31, 0, 0])
	assert_eq(_runner.world.validate().size(), 0)


func test_each_step_ticks_modules_and_delivers_events() -> void:
	var call_log: Array[String] = []
	_runner = _runner_with_module(1, call_log)
	var received: Array[int] = []
	_runner.world.context.events.subscribe("TestPinged", func(event: SimEvent) -> void: received.append(event.time))
	_runner.step_once()
	_runner.world.context.events.publish(TestEvent.new("TestPinged"))
	assert_eq(received, [] as Array[int], "Publicar só enfileira.")
	_runner.step_once()
	assert_eq(call_log, ["fake.tick(1)", "fake.tick(1)"] as Array[String])
	assert_eq(received, [1] as Array[int], "O evento é entregue no fim do passo seguinte, carimbado com o minuto em que foi publicado.")


func test_same_seed_gives_same_world_state_and_different_seed_does_not() -> void:
	var first: Dictionary = _final_state(7)
	var second: Dictionary = _final_state(7)
	var other: Dictionary = _final_state(8)
	assert_eq(first, second)
	assert_ne(first, other, "Sementes diferentes devem dar estados diferentes (a semente entra no save).")


func _final_state(world_seed: int) -> Dictionary:
	var call_log: Array[String] = []
	var runner: SimulationRunner = _runner_with_module(world_seed, call_log)
	runner.run_days(2)
	var state: Dictionary = runner.world.serialize()
	runner.finish()
	return state


func test_advance_frame_respects_pause_speed_and_tick_cap() -> void:
	_runner = SimulationRunner.new(1)
	_runner.start_new_game()
	var clock: SimClock = _runner.world.context.clock
	var ms_per_minute: int = SimClock.DEFAULT_REAL_MS_PER_MINUTE
	clock.set_paused(true)
	assert_eq(_runner.advance_frame(10 * ms_per_minute), 0)
	assert_eq(clock.total_minutes(), 0)
	clock.set_paused(false)
	assert_eq(_runner.advance_frame(3 * ms_per_minute), 3)
	clock.set_speed(2)
	assert_eq(_runner.advance_frame(2 * ms_per_minute), 4)
	assert_eq(_runner.advance_frame(1000 * ms_per_minute), SimulationRunner.MAX_TICKS_PER_FRAME, "O teto de passos por quadro impede a espiral da morte.")
	assert_eq(clock.total_minutes(), 3 + 4 + SimulationRunner.MAX_TICKS_PER_FRAME)


func test_start_twice_is_refused() -> void:
	_runner = SimulationRunner.new(1)
	_runner.start_new_game()
	_runner.start_new_game()
	assert_push_error("já iniciado")


func test_describe_state_shows_date_and_modules() -> void:
	var call_log: Array[String] = []
	_runner = _runner_with_module(5, call_log)
	_runner.run_steps(61)
	var text: String = _runner.describe_state()
	assert_string_contains(text, "ano 1, dia 1, 01:01 (61 minutos simulados)")
	assert_string_contains(text, "Módulos: 1")
	assert_string_contains(text, "fake")
