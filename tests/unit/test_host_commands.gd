extends GutTest
## LW-036: comandos de ritmo do SimulationHost (pausa e velocidade) e falha tratada sem jogo iniciado.

var _host: SimulationHostNode


func before_each() -> void:
	_host = SimulationHostNode.new()
	_host.start_new_game(3)


func after_each() -> void:
	_host.runner.finish()
	_host.free()


func _seconds_per_minute() -> float:
	return SimClock.DEFAULT_REAL_MS_PER_MINUTE / 1000.0


func _clock() -> SimClock:
	return _host.runner.world.context.clock


func test_pause_makes_the_host_advance_zero_steps_and_resuming_advances_again() -> void:
	var pause: Result = _host.request_pause(true)
	assert_true(pause.ok, pause.message)
	assert_eq(_host.advance(_seconds_per_minute() * 5.0), 0)
	assert_eq(_clock().total_minutes(), 0)
	var resume: Result = _host.request_pause(false)
	assert_true(resume.ok, resume.message)
	assert_eq(_host.advance(_seconds_per_minute() * 5.0), 5)
	assert_eq(_clock().total_minutes(), 5)


func test_speed_from_1_to_8_is_accepted_and_multiplies_the_steps() -> void:
	for speed: int in range(SimClock.MIN_SPEED, SimClock.MAX_SPEED + 1):
		var result: Result = _host.request_speed(speed)
		assert_true(result.ok, result.message)
		assert_eq(_clock().get_speed(), speed)
		assert_eq(_host.advance(_seconds_per_minute()), speed, "Um minuto real a %dx dá %d passos." % [speed, speed])


func test_speed_outside_1_to_8_is_refused_and_keeps_the_previous_speed() -> void:
	assert_true(_host.request_speed(3).ok)
	var invalid_speeds: Array[int] = [0, 9, -1, 1000]
	for speed: int in invalid_speeds:
		var result: Result = _host.request_speed(speed)
		assert_false(result.ok, "Velocidade %d deveria ser recusada." % speed)
		assert_eq(result.code, "CLOCK_INVALID_SPEED")
		assert_eq(_clock().get_speed(), 3)


func test_commands_without_a_started_game_fail_without_crashing() -> void:
	var idle: SimulationHostNode = SimulationHostNode.new()
	var pause: Result = idle.request_pause(true)
	var speed: Result = idle.request_speed(2)
	assert_false(pause.ok)
	assert_eq(pause.code, SimulationHostNode.CODE_NO_GAME)
	assert_string_contains(pause.message, "request_pause")
	assert_string_contains(pause.message, "start_new_game")
	assert_false(speed.ok)
	assert_eq(speed.code, SimulationHostNode.CODE_NO_GAME)
	assert_string_contains(speed.message, "request_speed")
	idle.free()


func test_pace_commands_do_not_change_the_state_hash() -> void:
	var before: String = _host.runner.world.state_hash()
	assert_true(_host.request_pause(true).ok)
	assert_true(_host.request_speed(8).ok)
	assert_eq(_host.runner.world.state_hash(), before, "Pausa e velocidade não são salvas nem entram no hash.")
