extends Node
## LW-053A: mede os QUADROS DO JOGO (cena principal, COM janela) e imprime o resultado. Roda no binário de release (tests/soak/run_game_release)
## ou no do editor (tests/soak/run_game_release --editor). É código de TESTE: usa o relógio do sistema só para medir (Time.get_ticks_usec), não acelera
## o relógio do motor e não mexe em valor nenhum do jogo. Ensaios, nesta ordem: ROTA (60 s a 7 m/s para o leste pelo caminho, entrada por ações do
## InputMap), PARADO (30 s, HUD visível) e PAUSADO (30 s). Argumento opcional: --ensaios rota,parado,pausado (padrão: os três).

const GAME_SCENE: String = "res://scenes/main.tscn"
const ROUTE_SECONDS: float = 60.0
const STILL_SECONDS: float = 30.0
const PAUSED_SECONDS: float = 30.0
const SETTLE_TIMEOUT_SECONDS: float = 30.0
const AFTER_SETTLE_SECONDS: float = 2.0
## Os primeiros quadros do ensaio ficam fora das estatísticas (o 4º quadro do jogo é lento na partida; LW-040).
const SKIPPED_FRAMES: int = 3
const BUDGET_60_HZ_MS: float = 16.7
const BUDGET_30_HZ_MS: float = 33.0
const SUSPENDED_MS: float = 1000.0
const US_PER_MS: float = 1000.0
const US_PER_SECOND: float = 1000000.0

var _terrain: TerrainView
var _body: PlayerBody
var _frames_ms: Array[float] = []
var _stamps_s: Array[float] = []


func _ready() -> void:
	var game: Node = (load(GAME_SCENE) as PackedScene).instantiate()
	add_child(game)
	_terrain = game.get_node("TerrainView") as TerrainView
	_body = game.get_node("PlayerBody") as PlayerBody
	DisplayServer.window_move_to_foreground()
	await _run()


func _run() -> void:
	_print_header()
	await _wait_for_terrain()
	var trials: PackedStringArray = _requested_trials()
	if trials.has("rota"):
		Input.action_press(InputActions.MOVE_FORWARD)
		Input.action_press(InputActions.RUN)
		await _measure("ROTA 60 s a 7 m/s para o leste", ROUTE_SECONDS)
		Input.action_release(InputActions.MOVE_FORWARD)
		Input.action_release(InputActions.RUN)
	if trials.has("parado"):
		await _measure("PARADO 30 s com HUD", STILL_SECONDS)
	if trials.has("pausado"):
		var bridge: SimBridge = (get_node("/root/GameApp") as GameAppNode).peek_bridge()
		bridge.request_pause(true)
		await _wait_seconds(1.0)
		await _measure("PAUSADO 30 s com HUD", PAUSED_SECONDS)
	get_tree().quit(0)


func _requested_trials() -> PackedStringArray:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var at: int = args.find("--ensaios")
	return args[at + 1].split(",") if at >= 0 and at + 1 < args.size() else PackedStringArray(["rota", "parado", "pausado"])


func _print_header() -> void:
	print("LW-053A: medição de quadros do jogo (cena principal, com janela)")
	print("build de depuração: %s" % ("sim" if OS.is_debug_build() else "não"))
	print("Motor: Godot %s, %s, %s" % [Engine.get_version_info()["string"], OS.get_name(), RenderingServer.get_video_adapter_name()])
	print("Renderização: driver %s, método %s" % [RenderingServer.get_current_rendering_driver_name(), RenderingServer.get_current_rendering_method()])
	print("Tela: %.0f Hz, vsync %d, max_fps %d, janela %s" % [DisplayServer.screen_get_refresh_rate(), DisplayServer.window_get_vsync_mode(), Engine.max_fps, str(DisplayServer.window_get_size())])


## Espera o terreno assentar (nada na fila de construção, de liberação e de colisão), com limite de tempo, e mais um pouco.
func _wait_for_terrain() -> void:
	var start_us: int = Time.get_ticks_usec()
	await get_tree().process_frame
	while _terrain.pending_count() + _terrain.free_pending_count() + _terrain.collision_pending_count() > 0 and float(Time.get_ticks_usec() - start_us) / US_PER_SECOND < SETTLE_TIMEOUT_SECONDS:
		await get_tree().process_frame
	print("terreno assentou em %.1f s (%d chunks)" % [float(Time.get_ticks_usec() - start_us) / US_PER_SECOND, _terrain.loaded_chunks().size()])
	await _wait_seconds(AFTER_SETTLE_SECONDS)


func _wait_seconds(seconds: float) -> void:
	var start_us: int = Time.get_ticks_usec()
	while float(Time.get_ticks_usec() - start_us) / US_PER_SECOND < seconds:
		await get_tree().process_frame


func _snapshot() -> String:
	return "%d nós, %d chunks" % [int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)), _terrain.loaded_chunks().size()]


## Mede `seconds` de quadros (intervalo entre um quadro e o seguinte) e imprime o relatório do ensaio.
func _measure(label: String, seconds: float) -> void:
	_frames_ms.clear()
	_stamps_s.clear()
	var snapshots: PackedStringArray = ["começo: " + _snapshot(), ""]
	var start_us: int = Time.get_ticks_usec()
	var last_us: int = start_us
	while float(last_us - start_us) / US_PER_SECOND < seconds:
		await get_tree().process_frame
		var now_us: int = Time.get_ticks_usec()
		_frames_ms.append(float(now_us - last_us) / US_PER_MS)
		_stamps_s.append(float(now_us - start_us) / US_PER_SECOND)
		last_us = now_us
		if snapshots[1].is_empty() and float(now_us - start_us) / US_PER_SECOND >= seconds / 2.0:
			snapshots[1] = "meio: " + _snapshot()
	snapshots.append("fim: " + _snapshot())
	_print_report(label, snapshots)


func _print_report(label: String, snapshots: PackedStringArray) -> void:
	var counted: Array[float] = _frames_ms.slice(SKIPPED_FRAMES)
	var sorted: Array[float] = counted.duplicate()
	sorted.sort()
	var sum: float = 0.0
	var over_60: int = 0
	var over_30: int = 0
	var slow_list: PackedStringArray = PackedStringArray()
	for index: int in counted.size():
		sum += counted[index]
		over_60 += 1 if counted[index] > BUDGET_60_HZ_MS else 0
		if counted[index] > BUDGET_30_HZ_MS:
			over_30 += 1
			slow_list.append("%.1f ms em %.1f s" % [counted[index], _stamps_s[index + SKIPPED_FRAMES]])
	print("ENSAIO %s" % label)
	print("  quadros %d, média %.2f ms, mediana %.2f ms, percentil 99 %.2f ms, pior (sem os %d primeiros) %.1f ms" % [counted.size(), sum / float(maxi(counted.size(), 1)), sorted[IntMath.floor_div(sorted.size(), 2)], sorted[mini(int(float(sorted.size()) * 0.99), sorted.size() - 1)], SKIPPED_FRAMES, sorted[sorted.size() - 1]])
	print("  acima de 16,7 ms: %d · acima de 33 ms: %d%s" % [over_60, over_30, "" if slow_list.is_empty() else " (" + "; ".join(slow_list) + ")"])
	print("  %s | %s | %s | posição final x=%.1f m" % [snapshots[0], snapshots[1], snapshots[2], _body.global_position.x])
	if sorted[sorted.size() - 1] > SUSPENDED_MS:
		print("  ATENÇÃO: quadro de mais de 1 s; o Mac pode ter suspendido, estes números não valem.")
