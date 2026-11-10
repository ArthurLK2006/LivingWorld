extends GutTest
## LW-044: mapa de entradas. Todas as ações existem no InputMap com as teclas de E1 (por tecla física), nenhuma tecla vale para
## duas ações, e a pausa do GameApp é tratada pela AÇÃO, sem tecla fixa. Sem janela.

const ACTION_COUNT: int = 22
const GAME_APP_SOURCE: String = "res://src/app/game_app.gd"
const UNSPECIFIED: KeyLocation = KEY_LOCATION_UNSPECIFIED
## Teclas padrão da decisão E1 de Arthur (DEC-116): ação -> [tecla física, localização].
const EXPECTED_KEYS: Dictionary[StringName, Array] = {
	InputActions.MOVE_FORWARD: [KEY_W, KEY_LOCATION_UNSPECIFIED],
	InputActions.MOVE_BACK: [KEY_S, KEY_LOCATION_UNSPECIFIED],
	InputActions.MOVE_LEFT: [KEY_A, KEY_LOCATION_UNSPECIFIED],
	InputActions.MOVE_RIGHT: [KEY_D, KEY_LOCATION_UNSPECIFIED],
	InputActions.RUN: [KEY_SHIFT, KEY_LOCATION_LEFT],
	InputActions.JUMP: [KEY_SPACE, KEY_LOCATION_UNSPECIFIED],
	InputActions.INTERACT: [KEY_E, KEY_LOCATION_UNSPECIFIED],
	InputActions.PAUSE: [KEY_P, KEY_LOCATION_UNSPECIFIED],
	InputActions.LOOK_LEFT: [KEY_LEFT, KEY_LOCATION_UNSPECIFIED],
	InputActions.LOOK_RIGHT: [KEY_RIGHT, KEY_LOCATION_UNSPECIFIED],
	InputActions.LOOK_UP: [KEY_UP, KEY_LOCATION_UNSPECIFIED],
	InputActions.LOOK_DOWN: [KEY_DOWN, KEY_LOCATION_UNSPECIFIED],
	InputActions.SPEED_NORMAL: [KEY_1, KEY_LOCATION_UNSPECIFIED],
	InputActions.SPEED_DOUBLE: [KEY_2, KEY_LOCATION_UNSPECIFIED],
	InputActions.INSPECTOR_TOGGLE: [KEY_F3, KEY_LOCATION_UNSPECIFIED],
	InputActions.INSPECTOR_TOGGLE_ALT: [KEY_TAB, KEY_LOCATION_UNSPECIFIED],
	InputActions.INSPECTOR_NEXT: [KEY_N, KEY_LOCATION_UNSPECIFIED],
	InputActions.INSPECTOR_PREVIOUS: [KEY_B, KEY_LOCATION_UNSPECIFIED],
	InputActions.INSPECTOR_TRACE: [KEY_T, KEY_LOCATION_UNSPECIFIED],
}
## Botões de mouse da decisão D3 do lote 3: ação -> botão (botão direito arrastado gira a câmera, a roda dá zoom).
const MOUSE_BUTTONS: Dictionary[StringName, MouseButton] = {
	InputActions.CAMERA_ORBIT: MOUSE_BUTTON_RIGHT,
	InputActions.ZOOM_IN: MOUSE_BUTTON_WHEEL_UP,
	InputActions.ZOOM_OUT: MOUSE_BUTTON_WHEEL_DOWN,
}
## Palavras que não podem aparecer no código do GameApp (tecla escrita direto).
const FORBIDDEN_WORDS: Array[String] = ["PAUSE_KEY", "InputEventKey", "keycode", "KEY_SPACE", "is_key_pressed"]

var _host: SimulationHostNode
var _app: GameAppNode


func before_each() -> void:
	_host = SimulationHostNode.new()
	_host.start_new_game(3)
	_app = GameAppNode.new()
	_app.bind_host(_host)


func after_each() -> void:
	_app.free()
	_host.runner.finish()
	_host.free()


func _action_event(action: StringName) -> InputEventAction:
	var event: InputEventAction = InputEventAction.new()
	event.action = action
	event.pressed = true
	return event


func _key_events(action: StringName) -> Array[InputEventKey]:
	var keys: Array[InputEventKey] = []
	for event: InputEvent in InputMap.action_get_events(action):
		var key_event: InputEventKey = event as InputEventKey
		if key_event != null:
			keys.append(key_event)
	return keys


func test_all_actions_exist_with_snake_case_names_and_no_extra_game_action() -> void:
	assert_eq(InputActions.ALL.size(), ACTION_COUNT)
	var seen: Dictionary[StringName, bool] = {}
	var name_pattern: RegEx = RegEx.create_from_string("^[a-z]+(_[a-z]+)*$")
	for action: StringName in InputActions.ALL:
		assert_true(InputMap.has_action(action), "A ação '%s' não existe no InputMap." % action)
		assert_not_null(name_pattern.search(String(action)), "Nome fora de snake_case: %s" % action)
		assert_false(seen.has(action), "Ação repetida em InputActions.ALL: %s" % action)
		seen[action] = true
	for action: StringName in InputMap.get_actions():
		if not String(action).begins_with("ui_"):
			assert_true(InputActions.ALL.has(action), "Ação '%s' no InputMap que não está em InputActions." % action)


func test_each_action_has_at_least_one_event_and_the_keys_of_the_decision_E1() -> void:
	for action: StringName in InputActions.ALL:
		assert_gt(InputMap.action_get_events(action).size(), 0, "A ação '%s' não tem nenhum evento." % action)
		if not EXPECTED_KEYS.has(action):
			continue # ações de mouse da câmera (decisão D3): têm o teste próprio mais abaixo
		var expected: Array = EXPECTED_KEYS[action]
		var keys: Array[InputEventKey] = _key_events(action)
		assert_eq(keys.size(), 1, "A ação '%s' deve ter exatamente uma tecla." % action)
		assert_eq(keys[0].physical_keycode, expected[0], "Tecla física errada em '%s'." % action)
		assert_eq(keys[0].location, expected[1], "Localização errada em '%s'." % action)
		assert_eq(keys[0].keycode, 0 as Key, "A tecla de '%s' deve ser física (sem keycode)." % action)


func test_no_key_is_bound_to_two_actions_and_space_is_jump_not_pause() -> void:
	var owner_of: Dictionary[String, StringName] = {}
	for action: StringName in InputActions.ALL:
		for key_event: InputEventKey in _key_events(action):
			var key_id: String = "%d/%d" % [key_event.physical_keycode, key_event.location]
			assert_false(owner_of.has(key_id), "A tecla %s serve a '%s' e a '%s'." % [key_id, owner_of.get(key_id, &""), action])
			owner_of[key_id] = action
	assert_eq(_key_events(InputActions.JUMP)[0].physical_keycode, KEY_SPACE, "Espaço é o pulo.")
	assert_ne(_key_events(InputActions.PAUSE)[0].physical_keycode, KEY_SPACE, "Espaço NÃO pausa.")


func test_the_pause_action_toggles_the_pause_and_other_actions_do_not() -> void:
	var clock: SimClock = _host.runner.world.context.clock
	var seconds_per_minute: float = SimClock.DEFAULT_REAL_MS_PER_MINUTE / 1000.0
	assert_false(_app.handle_key(_action_event(InputActions.SPEED_DOUBLE)), "Velocidade só existe como ação; ninguém a trata ainda.")
	assert_false(_app.handle_key(_action_event(InputActions.JUMP)), "O pulo não pausa.")
	assert_false(clock.is_paused())
	assert_true(_app.handle_key(_action_event(InputActions.PAUSE)))
	assert_true(clock.is_paused())
	assert_eq(_host.advance(seconds_per_minute * 5.0), 0, "Pausado, o host não avança.")
	assert_true(_app.handle_key(_action_event(InputActions.PAUSE)))
	assert_false(clock.is_paused())
	assert_eq(_host.advance(seconds_per_minute * 5.0), 5, "Retomado, o host volta a avançar.")
	assert_eq(clock.get_speed(), SimClock.MIN_SPEED, "A ação de velocidade não mudou o ritmo.")


func test_the_game_app_uses_no_fixed_key() -> void:
	var source: String = FileAccess.get_file_as_string(GAME_APP_SOURCE)
	assert_false(source.is_empty(), "Não foi possível ler %s." % GAME_APP_SOURCE)
	for word: String in FORBIDDEN_WORDS:
		assert_false(source.contains(word), "O GameApp não pode conter '%s' (tecla fixa)." % word)
	assert_true(source.contains("InputActions.PAUSE"), "A pausa é tratada pela ação nomeada.")
	var throwaway: GameAppNode = GameAppNode.new()
	assert_false(throwaway.get_script().get_script_constant_map().has("PAUSE_KEY"), "A constante PAUSE_KEY foi apagada.")
	throwaway.free()


func test_a_real_key_event_matches_its_own_action_and_only_it_and_run_is_the_left_shift() -> void:
	for action: StringName in InputActions.ALL:
		if not EXPECTED_KEYS.has(action):
			continue # ações de mouse da câmera (decisão D3): têm o teste próprio
		var expected: Array = EXPECTED_KEYS[action]
		var event: InputEventKey = InputEventKey.new()
		event.physical_keycode = expected[0]
		event.location = expected[1]
		event.pressed = true
		for other: StringName in InputActions.ALL:
			assert_eq(InputMap.event_is_action(event, other), other == action, "A tecla de '%s' casou com '%s'." % [action, other])
	var right_shift: InputEventKey = InputEventKey.new()
	right_shift.physical_keycode = KEY_SHIFT
	right_shift.location = KEY_LOCATION_RIGHT
	right_shift.pressed = true
	assert_false(InputMap.event_is_action(right_shift, InputActions.RUN), "Só o Shift esquerdo corre.")


func test_the_camera_actions_are_bound_to_the_mouse_buttons_of_the_decision_D3_and_only_to_them() -> void:
	for action: StringName in MOUSE_BUTTONS:
		var events: Array[InputEvent] = InputMap.action_get_events(action)
		assert_eq(events.size(), 1, "A ação '%s' deve ter exatamente um evento." % action)
		var button: InputEventMouseButton = events[0] as InputEventMouseButton
		assert_not_null(button, "A ação '%s' deve ser um botão do mouse." % action)
		assert_eq(button.button_index, MOUSE_BUTTONS[action], "Botão errado em '%s'." % action)
		assert_eq(button.device, -1, "A ação '%s' deve valer para qualquer dispositivo." % action)
		assert_eq(_key_events(action).size(), 0, "A ação '%s' não tem tecla." % action)
		var real: InputEventMouseButton = InputEventMouseButton.new()
		real.button_index = MOUSE_BUTTONS[action]
		real.pressed = true
		for other: StringName in InputActions.ALL:
			assert_eq(InputMap.event_is_action(real, other), other == action, "O botão de '%s' casou com '%s'." % [action, other])
