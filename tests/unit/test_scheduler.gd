extends GutTest

var _log: Array[String] = []
var _world: World
var _scheduler: Scheduler


func _build(module_names: Array[String], log: Array[String], budget: int = Scheduler.UNLIMITED_BUDGET, usec_source: Callable = Callable()) -> Array:
	var clock: SimClock = SimClock.new()
	var context: SimContext = SimContext.new(clock, EventBus.new(clock), WorldRng.new(3), IdGenerator.new())
	var world: World = World.new(context)
	for module_name: String in module_names:
		assert_true(world.register_module(module_name, FakeModule.new(module_name, log)).ok)
	world.setup()
	log.clear()
	return [world, Scheduler.new(world, budget, usec_source)]


func _run_steps(world: World, scheduler: Scheduler, log: Array[String], steps: int) -> void:
	for _i: int in steps:
		world.context.clock.advance_step()
		log.append("@%d" % world.context.clock.total_minutes())
		scheduler.step()


func _only(log: Array[String], prefix: String) -> Array[String]:
	return log.filter(func(line: String) -> bool: return line.begins_with(prefix))


func before_each() -> void:
	_log = []
	_world = null


func after_each() -> void:
	if _world != null:
		_world.teardown()
		_world = null


func test_default_module_runs_every_step_with_one_elapsed_minute() -> void:
	var built: Array = _build(["a"], _log)
	_world = built[0]
	_run_steps(_world, built[1], _log, 3)
	assert_eq(_log, ["@1", "a.tick(1)", "@2", "a.tick(1)", "@3", "a.tick(1)"] as Array[String])


func test_frequency_10_runs_once_every_10_steps() -> void:
	var built: Array = _build(["a", "b"], _log)
	_world = built[0]
	assert_true(built[1].configure_module("a", 10).ok)
	var minutes_a_ran: Array[int] = []
	for _i: int in 100:
		_world.context.clock.advance_step()
		var log_size: int = _log.size()
		built[1].step()
		if _log.slice(log_size).has("a.tick(10)"):
			minutes_a_ran.append(_world.context.clock.total_minutes())
	assert_eq(minutes_a_ran, [10, 20, 30, 40, 50, 60, 70, 80, 90, 100] as Array[int], "Frequência 10: uma execução a cada 10 passos, com 10 minutos decorridos.")
	assert_eq(_only(_log, "a.tick").size(), 10)
	assert_eq(_only(_log, "b.tick").size(), 100, "O módulo de frequência 1 roda todo passo.")


func test_offset_staggers_modules() -> void:
	var built: Array = _build(["a"], _log)
	_world = built[0]
	assert_true(built[1].configure_module("a", 10, 1, 3).ok)
	var minutes: Array[int] = []
	for _i: int in 25:
		_world.context.clock.advance_step()
		if built[1].step() > 0:
			minutes.append(_world.context.clock.total_minutes())
	assert_eq(minutes, [3, 13, 23] as Array[int])


func test_over_budget_modules_are_deferred_without_losing_minutes() -> void:
	var built: Array = _build(["big_a", "big_b", "small"], _log, 100)
	_world = built[0]
	var scheduler: Scheduler = built[1]
	scheduler.configure_module("big_a", 1, 60)
	scheduler.configure_module("big_b", 1, 60)
	scheduler.configure_module("small", 1, 10)
	_run_steps(_world, scheduler, _log, 1)
	assert_eq(_log, ["@1", "big_a.tick(1)", "small.tick(1)"] as Array[String], "big_b não cabe e é adiado.")
	assert_eq(scheduler.debug_summary()["last_step"], {"ran": 2, "deferred": 1})
	_run_steps(_world, scheduler, _log, 1)
	assert_eq(_log.slice(3), ["@2", "big_b.tick(2)", "small.tick(1)"] as Array[String], "O adiado passa à frente e recebe os 2 minutos acumulados.")
	_run_steps(_world, scheduler, _log, 38)
	var now: int = _world.context.clock.total_minutes()
	var summary: Dictionary = scheduler.debug_summary()["modules"]
	for module_name: String in ["big_a", "big_b", "small"]:
		var delivered: int = 0
		for line: String in _only(_log, module_name + ".tick("):
			delivered += int(line.get_slice("(", 1).trim_suffix(")"))
		assert_eq(delivered + (now - int(summary[module_name]["last_run"])), now, "Nenhum minuto de %s pode se perder." % module_name)
		assert_gt(summary[module_name]["runs"], 10, "Ninguém pode passar fome: %s" % module_name)


func test_first_module_runs_even_if_it_alone_exceeds_the_budget() -> void:
	var built: Array = _build(["huge"], _log, 10)
	_world = built[0]
	built[1].configure_module("huge", 1, 500)
	_run_steps(_world, built[1], _log, 2)
	assert_eq(_only(_log, "huge.tick").size(), 2)


func test_execution_is_deterministic_and_independent_of_measured_time() -> void:
	var first: Array[String] = _scenario(Callable())
	var counter: Array[int] = [0]
	var erratic: Callable = func() -> int:
		counter[0] += 12345 if counter[0] % 3 == 0 else 7
		return counter[0]
	var second: Array[String] = _scenario(erratic)
	assert_eq(first, second, "O tempo medido não pode mudar o que roda.")
	assert_gt(first.size(), 30)


func _scenario(usec_source: Callable) -> Array[String]:
	var log: Array[String] = []
	var built: Array = _build(["a", "b", "c"], log, 70, usec_source)
	var scheduler: Scheduler = built[1]
	scheduler.configure_module("a", 3, 50)
	scheduler.configure_module("b", 1, 40)
	scheduler.configure_module("c", 5, 30, 2)
	_run_steps(built[0], scheduler, log, 40)
	built[0].teardown()
	return log


func test_save_and_load_continue_the_exact_schedule() -> void:
	var log_a: Array[String] = []
	var built_a: Array = _build(["a", "b"], log_a, 60)
	built_a[1].configure_module("a", 4, 50)
	built_a[1].configure_module("b", 3, 40)
	_run_steps(built_a[0], built_a[1], log_a, 7)
	var clock_state: Dictionary = built_a[0].context.clock.serialize()
	var scheduler_state: Variant = JSON.parse_string(JSON.stringify(built_a[1].serialize()))
	log_a.clear()
	_run_steps(built_a[0], built_a[1], log_a, 20)
	var log_b: Array[String] = []
	var built_b: Array = _build(["a", "b"], log_b, 60)
	built_b[1].configure_module("a", 4, 50)
	built_b[1].configure_module("b", 3, 40)
	assert_true(built_b[0].context.clock.on_load(clock_state).ok)
	var result: Result = built_b[1].on_load(scheduler_state)
	assert_true(result.ok, result.message)
	_run_steps(built_b[0], built_b[1], log_b, 20)
	assert_eq(log_b, log_a, "Depois de carregar, a agenda continua exatamente igual.")
	assert_eq(built_b[1].validate().size(), 0)
	built_a[0].teardown()
	built_b[0].teardown()


func test_on_load_rejects_invalid_data_without_changing_state() -> void:
	var built: Array = _build(["a", "b"], _log)
	_world = built[0]
	var scheduler: Scheduler = built[1]
	_run_steps(_world, scheduler, _log, 3)
	var before: Dictionary = scheduler.serialize()
	var bad_inputs: Array[Dictionary] = [
		{},
		{"modules": {"a": {"last_run": 1, "next_due": 2}}},
		{"modules": {"a": {"last_run": 1, "next_due": 2}, "b": {"last_run": "x", "next_due": 2}}},
		{"modules": {"a": {"last_run": 5, "next_due": 5}, "b": {"last_run": 1, "next_due": 2}}},
		{"modules": {"a": {"last_run": 1, "next_due": 2}, "b": {"last_run": 1, "next_due": 2}, "ghost": {}}},
	]
	for bad: Dictionary in bad_inputs:
		assert_false(scheduler.on_load(bad).ok, "Deveria rejeitar %s" % str(bad))
	assert_eq(scheduler.serialize(), before)


func test_configure_module_rejects_invalid_arguments() -> void:
	var built: Array = _build(["a"], _log)
	_world = built[0]
	assert_eq(built[1].configure_module("ghost", 1).code, "SCHEDULER_UNKNOWN_MODULE")
	assert_eq(built[1].configure_module("a", 0).code, "SCHEDULER_INVALID_CONFIG")
	assert_eq(built[1].configure_module("a", 5, -1).code, "SCHEDULER_INVALID_CONFIG")
	assert_eq(built[1].configure_module("a", 5, 1, 5).code, "SCHEDULER_INVALID_CONFIG")
	assert_eq(_world.tick_module("ghost", 1).code, "WORLD_UNKNOWN_MODULE")


func test_timing_stats_and_alert_counter() -> void:
	var fake_time: Array[int] = [0]
	var usec_source: Callable = func() -> int:
		fake_time[0] += 250
		return fake_time[0]
	var built: Array = _build(["a"], _log, Scheduler.UNLIMITED_BUDGET, usec_source)
	_world = built[0]
	built[1].set_time_alert_usec(200)
	_run_steps(_world, built[1], _log, 4)
	var stats: Dictionary = built[1].debug_summary()["modules"]["a"]
	assert_eq(stats["runs"], 4)
	assert_eq(stats["total_usec"], 1000)
	assert_eq(stats["max_usec"], 250)
	assert_eq(stats["over_limit"], 4, "Toda execução acima do limite de alerta é contada.")
