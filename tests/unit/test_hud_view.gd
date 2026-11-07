extends GutTest
## LW-051: o HUD mínimo reflete relógio, pausa e velocidade pela ponte e trata as ações de velocidade, sem janela. Mundo do jogo real
## (host com terreno e pontos reais); a hora avança chamando o host à mão (a simulação anda no tempo do quadro: 1,25 s reais por minuto
## simulado a 1x, [HIP] do núcleo). Valores esperados escritos à mão.

const BLOCKOUT_DIR: String = "res://data/world"
const WORLD_SEED: int = 3
## O título vem da configuração do projeto e a versão do GameApp, como na cena principal.
const TITLE_SETTING: String = "application/config/name"
const SECONDS_PER_MINUTE: float = SimClock.DEFAULT_REAL_MS_PER_MINUTE / 1000.0

var _terrain: TerrainData
var _texts: UiText
var _host: SimulationHostNode
var _bridge: SimBridge
var _hud: HudView
var _title: String = ""


func before_all() -> void:
	var terrain_loaded: TerrainLoader.LoadResult = TerrainLoader.load_dir(BLOCKOUT_DIR)
	assert_true(terrain_loaded.result.ok, terrain_loaded.result.message)
	_terrain = terrain_loaded.terrain
	var texts_loaded: UiText.LoadResult = UiText.from_file(UiText.DEFAULT_PATH)
	assert_true(texts_loaded.result.ok, texts_loaded.result.message)
	_texts = texts_loaded.texts


func before_each() -> void:
	_title = str(ProjectSettings.get_setting(TITLE_SETTING, ""))
	_host = SimulationHostNode.new()
	_host.start_new_game(WORLD_SEED, _terrain)
	_bridge = SimBridge.new(_host, _terrain)
	_hud = HudView.new()
	add_child_autofree(_hud)
	assert_true(_hud.setup(_bridge, _texts, _title, GameAppNode.GAME_VERSION))


func after_each() -> void:
	_host.runner.finish()
	_host.free()


func _action(action: StringName, pressed: bool = true) -> InputEventAction:
	var event: InputEventAction = InputEventAction.new()
	event.action = action
	event.pressed = pressed
	return event


func test_the_hud_shows_title_version_date_time_speed_and_the_pause_key() -> void:
	var lines: PackedStringArray = _hud.text.split("\n")
	assert_eq(lines.size(), 3)
	assert_string_contains(_hud.text, "Living World")
	assert_string_contains(_hud.text, "versão " + GameAppNode.GAME_VERSION)
	assert_string_contains(_hud.text, "ano 1, dia 1, 00:00")
	assert_string_contains(_hud.text, "1x")
	assert_string_contains(_hud.text, "[P] pausar ou continuar")
	assert_eq(lines[0], "Living World · versão " + GameAppNode.GAME_VERSION)
	assert_eq(lines[1], "Data simulada: ano 1, dia 1, 00:00 · 1x")
	assert_eq(lines[2], "[P] pausar ou continuar")


func test_the_hud_follows_the_simulated_clock() -> void:
	_host.advance(SECONDS_PER_MINUTE * 5.0)
	_hud.refresh()
	assert_string_contains(_hud.text, "ano 1, dia 1, 00:05")
	_host.runner.run_steps(60 * 14 + 30)
	_hud.refresh()
	assert_string_contains(_hud.text, "ano 1, dia 1, 14:35")
	_host.runner.run_days(1)
	_hud.refresh()
	assert_string_contains(_hud.text, "ano 1, dia 2, 14:35")


func test_the_hud_shows_pause_and_goes_back_to_the_speed_when_resumed() -> void:
	assert_true(_bridge.request_pause(true).ok)
	_hud.refresh()
	assert_string_contains(_hud.text, "PAUSADO")
	assert_false(_hud.text.contains("1x"), "Pausado, o indicador é o de pausa, não o de velocidade.")
	assert_true(_bridge.request_pause(false).ok)
	_hud.refresh()
	assert_string_contains(_hud.text, "1x")
	assert_false(_hud.text.contains("PAUSADO"))


func test_the_pause_action_of_the_app_is_shown_by_the_hud_and_the_clock_resumes() -> void:
	var app: GameAppNode = GameAppNode.new()
	app.bind_host(_host)
	app.toggle_pause()
	_hud.refresh()
	assert_string_contains(_hud.text, "PAUSADO")
	assert_eq(_host.advance(SECONDS_PER_MINUTE * 5.0), 0, "Pausado, o relógio não anda.")
	app.toggle_pause()
	_hud.refresh()
	assert_string_contains(_hud.text, "1x")
	assert_eq(_host.advance(SECONDS_PER_MINUTE * 5.0), 5)
	_hud.refresh()
	assert_string_contains(_hud.text, "ano 1, dia 1, 00:05")
	app.free()


func test_the_main_scene_hud_is_the_hud_view_with_the_real_autoloads() -> void:
	var main: Node = add_child_autofree((load("res://scenes/main.tscn") as PackedScene).instantiate())
	await wait_process_frames(3)
	var label: HudView = main.get_node("HUD/StatusLabel") as HudView
	assert_not_null(label, "O rótulo do HUD usa o HudView.")
	assert_string_contains(label.text, "Living World")
	assert_string_contains(label.text, "Data simulada:")


func test_the_speed_actions_change_the_clock_pace_and_the_indicator() -> void:
	assert_true(_hud.handle_action(_action(InputActions.SPEED_DOUBLE)))
	assert_eq(_bridge.peek_time().speed, 2)
	assert_eq(_host.advance(SECONDS_PER_MINUTE), 2, "Um minuto real a 2x dá 2 passos.")
	_hud.refresh()
	assert_string_contains(_hud.text, "2x")
	assert_true(_hud.handle_action(_action(InputActions.SPEED_NORMAL)))
	assert_eq(_bridge.peek_time().speed, 1)
	assert_eq(_host.advance(SECONDS_PER_MINUTE), 1)
	_hud.refresh()
	assert_string_contains(_hud.text, "1x")


func test_other_actions_and_released_keys_are_not_consumed() -> void:
	assert_false(_hud.handle_action(_action(InputActions.JUMP)))
	assert_false(_hud.handle_action(_action(InputActions.SPEED_DOUBLE, false)), "Soltar a tecla não conta.")
	assert_eq(_bridge.peek_time().speed, 1)
	assert_false(_hud.handle_action(InputEventMouseButton.new()))


func test_the_text_is_rewritten_only_when_the_clock_pause_or_speed_changes() -> void:
	var count: int = _hud.update_count
	_hud.refresh()
	_hud.refresh()
	assert_eq(_hud.update_count, count, "Nada mudou: o texto não é reescrito.")
	_host.advance(SECONDS_PER_MINUTE)
	_hud.refresh()
	assert_eq(_hud.update_count, count + 1)
	_bridge.request_pause(true)
	_hud.refresh()
	assert_eq(_hud.update_count, count + 2)
	_hud.refresh()
	assert_eq(_hud.update_count, count + 2)


func test_a_hud_without_a_game_reports_the_error_once_and_keeps_its_text() -> void:
	var idle: SimulationHostNode = SimulationHostNode.new()
	var hud: HudView = HudView.new()
	add_child_autofree(hud)
	assert_true(hud.setup(SimBridge.new(idle, _terrain), _texts, _title, GameAppNode.GAME_VERSION))
	assert_push_error("hora simulada indisponível")
	hud.refresh()
	assert_eq(hud.text, "")
	idle.free()


func test_setup_with_a_null_piece_reports_the_error() -> void:
	var hud: HudView = HudView.new()
	add_child_autofree(hud)
	assert_false(hud.setup(null, _texts, _title, GameAppNode.GAME_VERSION))
	assert_push_error("HudView.setup")
	assert_false(hud.setup(_bridge, null, _title, GameAppNode.GAME_VERSION))
	assert_push_error("HudView.setup")
