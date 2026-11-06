extends GutTest

var _host: SimulationHostNode
var _app: GameAppNode


func before_each() -> void:
	_host = SimulationHostNode.new()
	_host.start_new_game(3)
	_app = GameAppNode.new()
	_app.bind_host(_host)


func after_each() -> void:
	_host.free()
	_app.free()


func test_host_advances_simulation_with_frame_time() -> void:
	var seconds_per_minute: float = SimClock.DEFAULT_REAL_MS_PER_MINUTE / 1000.0
	assert_eq(_host.advance(seconds_per_minute * 2.0), 2)
	assert_eq(_host.runner.world.context.clock.total_minutes(), 2)


func test_host_without_game_does_nothing_and_new_game_replaces_the_world() -> void:
	var empty: SimulationHostNode = SimulationHostNode.new()
	assert_eq(empty.advance(10.0), 0)
	empty.free()
	_host.advance(100.0)
	var first_runner: SimulationRunner = _host.runner
	_host.start_new_game(4)
	assert_ne(_host.runner, first_runner)
	assert_eq(_host.runner.world.context.clock.total_minutes(), 0)


func test_status_text_shows_title_version_date_and_pace() -> void:
	var text: String = _app.status_text()
	assert_string_contains(text, "Living World")
	assert_string_contains(text, "versão " + GameAppNode.GAME_VERSION)
	assert_string_contains(text, "ano 1, dia 1, 00:00")
	assert_string_contains(text, "1x")
	assert_string_contains(text, "[P] pausar ou continuar")


func test_pause_toggle_stops_the_simulated_clock_and_shows_it() -> void:
	var seconds_per_minute: float = SimClock.DEFAULT_REAL_MS_PER_MINUTE / 1000.0
	_app.toggle_pause()
	assert_string_contains(_app.status_text(), "PAUSADO")
	assert_eq(_host.advance(seconds_per_minute * 5.0), 0)
	_app.toggle_pause()
	assert_string_contains(_app.status_text(), "1x")
	assert_eq(_host.advance(seconds_per_minute * 5.0), 5)
	assert_string_contains(_app.status_text(), "ano 1, dia 1, 00:05")


func test_status_changed_signal_fires_only_when_text_changes() -> void:
	watch_signals(_app)
	_app._process(0.0)
	_app._process(0.0)
	assert_signal_emit_count(_app, "status_changed", 1)
	_host.advance(SimClock.DEFAULT_REAL_MS_PER_MINUTE / 1000.0)
	_app._process(0.0)
	assert_signal_emit_count(_app, "status_changed", 2)


func _key(keycode: Key, pressed: bool, echo: bool = false) -> InputEventKey:
	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = keycode
	event.pressed = pressed
	event.echo = echo
	return event


## Tecla que o InputMap liga à ação de pausa (LW-044): o teste simula a AÇÃO, sem escrever a tecla.
func _pause_key() -> Key:
	var event: InputEventKey = InputMap.action_get_events(InputActions.PAUSE)[0] as InputEventKey
	return event.physical_keycode


func test_pause_action_toggles_pause_and_other_input_does_not() -> void:
	var clock: SimClock = _host.runner.world.context.clock
	assert_false(_app.handle_key(_key(KEY_A, true)), "Outra tecla não é consumida.")
	assert_false(_app.handle_key(_key(KEY_SPACE, true)), "Espaço é pulo, não pausa.")
	assert_false(_app.handle_key(_key(_pause_key(), false)), "Soltar a tecla não conta.")
	assert_false(_app.handle_key(_key(_pause_key(), true, true)), "Repetição da tecla não conta.")
	assert_false(_app.handle_key(InputEventMouseButton.new()))
	assert_false(clock.is_paused())
	assert_true(_app.handle_key(_key(_pause_key(), true)))
	assert_true(clock.is_paused())
	assert_true(_app.handle_key(_key(_pause_key(), true)))
	assert_false(clock.is_paused())


func test_main_scene_shows_the_status_overlay_with_the_real_autoloads() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	var main: Node = add_child_autofree(scene.instantiate())
	await wait_frames(3)
	var label: Label = main.get_node("HUD/StatusLabel")
	assert_string_contains(label.text, "Living World")
	assert_string_contains(label.text, "Data simulada:")
