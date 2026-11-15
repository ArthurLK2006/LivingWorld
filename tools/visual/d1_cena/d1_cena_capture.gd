extends "res://tools/visual/d1_mundo/d1_mundo_capture.gd"
## D1-C (estudo isolado, nada entra no jogo): a cena integrada, a praça A com os habitantes de hoje (cápsulas) ou a praça `d` com o guarda facetado, no renderer do projeto (Mobile). Reaproveita da D1-B o cabeçalho e o `_shoot` (acomodação, PNG e medição pela janela); os habitantes vêm do D1CenaCrowd.
## Captura (padrão): 3 luzes x 3 câmeras da RendererTestScene mais as CLOSE_VIEWS, habitantes em pose parada, e o recorte ampliado das vistas isométrica e estratégica (igual nos dois lados). `--measure`: só a medição de vazão (desenho forçado sem apresentar, como o `_measure` do D1-A, porque o Mobile trava a taxa apresentada na da tela), habitantes animados.
## Uso (ABRE janela): godot --path <projeto> --rendering-method mobile --resolution 1280x720 -s res://tools/visual/d1_cena/d1_cena_capture.gd -- --scenario=atual|nova|i|ii|iii|iv --out=<pasta> [--measure] [--close-only]

const WARMUP_FRAMES: int = 10
const DRAW_STEP_S: float = 0.016
const MEASURE_HEADER: String = "captura | CPU de render mediana (ms) | CPU pior (ms) | vazão: quadro mediano (ms) | vazão pior (ms) | GPU de render mediana (ms) | GPU pior (ms) | chamadas | triângulos | objetos | memória de vídeo (MB)"
## Recortes ampliados (região e fator) em volta dos habitantes nas vistas de longe.
const ZOOMS: Dictionary[String, Array] = {"isometric": [Rect2i(320, 180, 640, 360), 2], "strategic": [Rect2i(480, 270, 320, 180), 4]}
## Vistas de perto em coordenadas do mundo: a luz, o ponto olhado e o da câmera.
const CLOSE_VIEWS: Array[Dictionary] = [
	{"name": "perto_poco_dia", "light": 0, "aim": Vector3(-1.2, 1.1, 1.2), "eye": Vector3(1.8, 1.5, 4.4)},
	{"name": "perto_barraca_dourada", "light": 1, "aim": Vector3(1.0, 1.2, -3.9), "eye": Vector3(1.4, 1.45, -0.4)},
	{"name": "perto_grupo_crepusculo", "light": 2, "aim": Vector3(0.6, 1.1, -0.5), "eye": Vector3(-4.6, 1.6, 4.4)},
]


func _initialize() -> void:
	var scenario_id: String = "nova"
	var out_dir: String = ""
	var measuring: bool = false
	var close_only: bool = false
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--scenario="):
			scenario_id = argument.trim_prefix("--scenario=")
		elif argument.begins_with("--out="):
			out_dir = argument.trim_prefix("--out=")
		elif argument == "--measure":
			measuring = true
		elif argument == "--close-only":
			close_only = true
	if DisplayServer.get_name() == HEADLESS_DISPLAY or out_dir.is_empty() or DirAccess.make_dir_recursive_absolute(out_dir) != OK or not D1CenaCrowd.SCENARIOS.has(scenario_id):
		push_error("d1_cena_capture: precisa de janela (sem --headless), de --out=<pasta> válida e de --scenario= conhecido.")
		quit(1)
		return
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	var scenario: Dictionary = D1CenaCrowd.SCENARIOS[scenario_id]
	var scene: RendererTestScene = RendererTestScene.new()
	scene.options = D1MundoOptions.for_variant(String(scenario["variant"]))
	root.add_child(scene)
	D1CenaCrowd.populate(scene, scenario, measuring)
	await process_frame
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(), true)
	var lines: Array[String] = _header("%s (cenário %s)" % [scenario["variant"], scenario_id], scene)
	if measuring:
		lines[lines.size() - 1] = MEASURE_HEADER
	var wide_lights: int = 0 if close_only else RendererPresets.PRESETS.size()
	for light: int in wide_lights:
		for view: int in RendererPresets.VIEWS.size():
			scene.apply_preset(light)
			scene.apply_view(view)
			var view_name: String = RendererPresets.VIEWS[view]["name"]
			var label: String = "%s_%s" % [RendererPresets.PRESETS[light]["name"], view_name]
			if measuring:
				lines.append(await _throughput(label))
			else:
				lines.append(await _shoot(out_dir, label, MEASURE_FRAMES))
				if ZOOMS.has(view_name):
					_zoom(out_dir, label, view_name)
	if not measuring:
		for shot: Dictionary in CLOSE_VIEWS:
			scene.apply_preset(int(shot["light"]))
			scene.camera.fov = CLOSE_FOV
			scene.camera.look_at_from_position(shot["eye"], shot["aim"])
			lines.append(await _shoot(out_dir, String(shot["name"]), 0))
	var file: FileAccess = FileAccess.open(out_dir.path_join(SUMMARY_FILE), FileAccess.WRITE)
	if file != null:
		file.store_string("\n".join(lines) + "\n")
		file.close()
	quit()


## Vazão: as acomodações normais, WARMUP_FRAMES e MEASURE_FRAMES de desenho forçado sem apresentar (sem esperar a tela); CPU e GPU de render do viewport, tempo de cada quadro, chamadas, triângulos, objetos e memória de vídeo do último quadro.
func _throughput(label: String) -> String:
	var view_rid: RID = root.get_viewport_rid()
	for frame: int in SETTLE_FRAMES:
		await process_frame
	RenderingServer.render_loop_enabled = false
	var cpu: Array[float] = []
	var gpu: Array[float] = []
	var step: Array[float] = []
	var last_us: int = Time.get_ticks_usec()
	for frame: int in WARMUP_FRAMES + MEASURE_FRAMES:
		await process_frame
		RenderingServer.force_draw(false, DRAW_STEP_S)
		var now_us: int = Time.get_ticks_usec()
		if frame >= WARMUP_FRAMES:
			step.append(float(now_us - last_us) / US_PER_MS)
			cpu.append(RenderingServer.viewport_get_measured_render_time_cpu(view_rid))
			gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(view_rid))
		last_us = now_us
	RenderingServer.render_loop_enabled = true
	return " | ".join([label, "%.3f" % _median(cpu), "%.3f" % _worst(cpu), "%.2f" % _median(step), "%.2f" % _worst(step), "%.3f" % _median(gpu), "%.3f" % _worst(gpu), str(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)), str(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)), str(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME)), "%.1f" % (RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_VIDEO_MEM_USED) / BYTES_PER_MB)])


## Grava ao lado da captura (<rótulo>_zoom.png) o recorte ampliado em volta dos habitantes.
func _zoom(out_dir: String, label: String, view_name: String) -> void:
	var spec: Array = ZOOMS[view_name]
	var region: Rect2i = spec[0]
	var factor: int = spec[1]
	var image: Image = Image.load_from_file(out_dir.path_join("%s.png" % label))
	if image == null:
		return
	var crop: Image = image.get_region(region)
	crop.resize(region.size.x * factor, region.size.y * factor, Image.INTERPOLATE_NEAREST)
	crop.save_png(out_dir.path_join("%s_zoom.png" % label))
