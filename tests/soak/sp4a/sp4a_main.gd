extends Node3D
## SPIKE descartável (LW-033/SP4a). Ponto de entrada como cena principal (tests/soak/run_sp4a
## roda com janela: --rendering-method muda só por processo nunca por script, confirmado por
## teste curto; por isso run_sp4a chama o Godot uma vez por renderizador pedido).

@onready var camera: Sp4aFreeCamera = $Sp4aFreeCamera
@onready var label: Label = $Hud/Label

var _terrain_data: Sp4aTerrainData
var _ver_terrain: Sp4aTerrainOwn
var _ver_quality_index: int = 1


func _ready() -> void:
	get_window().title = "Living World — SP4a (spike descartável, LW-033)"
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	_terrain_data = Sp4aTerrainData.new()

	var args: Dictionary = Sp4aScenarioRunner.parse_args(OS.get_cmdline_user_args())
	if args["modo"] == "ver":
		_start_modo_ver()
	else:
		_run_benchmark(args)


func _start_modo_ver() -> void:
	label.visible = true
	camera.interactive = true
	camera.global_position = _terrain_data.peek_spawn_point() + Vector3(0.0, 10.0, 20.0)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_ver_terrain = Sp4aTerrainOwn.new()
	_ver_terrain.setup(_terrain_data, Sp4aQualityLevels.get_level(Sp4aQualityLevels.ORDER[_ver_quality_index])["espaco_vertice"], 6)
	add_child(_ver_terrain)


func _process(_delta: float) -> void:
	if label.visible:
		var fps: float = Performance.get_monitor(Performance.TIME_FPS)
		label.text = "SP4a — modo ver (SPIKE, LW-033)\nterreno: próprio | nível: %s\nFPS: %.0f\n[1/2/3] nível  [Q/E] subir/descer  [Esc] soltar mouse" % [
			Sp4aQualityLevels.ORDER[_ver_quality_index], fps,
		]
		if _ver_terrain != null:
			_ver_terrain.set_focus(camera.global_position)
		_handle_ver_keys()


func _handle_ver_keys() -> void:
	for index: int in range(Sp4aQualityLevels.ORDER.size()):
		if Input.is_key_pressed(KEY_1 + index) and index != _ver_quality_index:
			_ver_quality_index = index
			_ver_terrain.vertex_spacing = Sp4aQualityLevels.get_level(Sp4aQualityLevels.ORDER[index])["espaco_vertice"]


func _run_benchmark(args: Dictionary) -> void:
	var runner: Sp4aScenarioRunner = Sp4aScenarioRunner.new()
	runner.scene_root = self
	runner.camera = camera
	runner.terrain_data = _terrain_data
	# ProjectSettings não reflete --rendering-method da linha de comando (testado e confirmado na
	# revisão da Parte A — ver relatório, seção 4); por isso o rótulo vem de --renderer-label,
	# que tests/soak/run_sp4a já sabe de antemão e passa explicitamente.
	runner.renderer_label = args["renderer_label"]
	runner.machine_label = OS.get_name()

	var writer: Sp4aResultWriter = Sp4aResultWriter.new()
	writer.set_machine_label(OS.get_name())
	var run_id: String = args["run_id"] if not args["run_id"].is_empty() else Sp4aResultWriter.build_run_id()
	var output_dir: String = "%s/tests/soak/sp4a/resultados" % ProjectSettings.globalize_path("res://").trim_suffix("/")
	var json_path: String = args["acumular_em"] if not args["acumular_em"].is_empty() else "%s/sp4a_%s.json" % [output_dir, run_id]
	if FileAccess.file_exists(json_path):
		var existing: FileAccess = FileAccess.open(json_path, FileAccess.READ)
		var parsed: Variant = JSON.parse_string(existing.get_as_text())
		existing.close()
		if parsed is Dictionary and parsed.has("resultados"):
			for row: Dictionary in parsed["resultados"]:
				writer.rows().append(row)
			for header: Dictionary in parsed.get("cabecalhos_maquina", []):
				writer.add_machine_header(header)
	writer.add_machine_header(Sp4aMetrics.machine_header(runner.renderer_label, DisplayServer.window_get_size()))
	runner.result_writer = writer

	await runner.run(args)

	writer.print_result_block()
	writer.save_files(output_dir, run_id)
	get_tree().quit(0)
