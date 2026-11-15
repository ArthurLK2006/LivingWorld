extends SceneTree
## D1-B (estudo isolado, nada entra no jogo): captura e mede a praça de demonstração de uma variante (ver D1MundoOptions) no renderer do projeto (Mobile), em 1280 x 720. De longe: 3 luzes x 3 câmeras da cena de teste (RendererTestScene), com 30 quadros de acomodação e 180 medidos por captura. De perto: as vistas de CLOSE_SHOTS a cerca de 4 m, só com a acomodação. Grava os PNG e o `resumo.txt` em --out.
## Uso (ABRE janela do Godot): godot --path <projeto> --rendering-method mobile --resolution 1280x720 -s res://tools/visual/d1_mundo/d1_mundo_capture.gd -- --variant=a|a_lean|d --out=<pasta>

const SETTLE_FRAMES: int = 30
const MEASURE_FRAMES: int = 180
const CLOSE_FOV: float = 55.0
const BYTES_PER_MB: float = 1048576.0
const US_PER_MS: float = 1000.0
const HEADLESS_DISPLAY: String = "headless"
const SUMMARY_FILE: String = "resumo.txt"
## Vistas de perto: a luz (0 dia, 1 hora dourada, 2 crepúsculo), o nó olhado e, somados à posição dele no mundo, o ponto olhado e o da câmera. A barraca 2 fica em (0, -6) com a frente para +Z; os adereços dela são Crate10, Crate11, Barrel12, Sack13 e Sack14.
const CLOSE_SHOTS: Array[Dictionary] = [
	{"name": "close_stall_day", "light": 0, "node": "Stall2", "aim": Vector3(0.0, 1.3, 0.0), "eye": Vector3(1.6, 1.5, 4.4)},
	{"name": "close_stall_golden", "light": 1, "node": "Stall2", "aim": Vector3(0.0, 1.3, 0.0), "eye": Vector3(1.6, 1.5, 4.4)},
	{"name": "close_well_day", "light": 0, "node": "Well", "aim": Vector3(0.0, 1.2, 0.0), "eye": Vector3(2.6, 1.5, 3.6)},
	{"name": "close_well_golden", "light": 1, "node": "Well", "aim": Vector3(0.0, 1.2, 0.0), "eye": Vector3(-2.6, 1.5, 3.6)},
	{"name": "close_props_day", "light": 0, "node": "Stall2", "aim": Vector3(0.1, 0.35, 2.5), "eye": Vector3(-2.2, 1.2, 5.1)},
	{"name": "close_lamp_dusk", "light": 2, "node": "LampPost0", "aim": Vector3(0.8, 4.3, 0.0), "eye": Vector3(3.6, 2.4, 4.2)},
]


func _initialize() -> void:
	var variant_id: String = "a"
	var out_dir: String = ""
	var close_only: bool = false
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--variant="):
			variant_id = argument.trim_prefix("--variant=")
		elif argument.begins_with("--out="):
			out_dir = argument.trim_prefix("--out=")
		elif argument == "--close-only":
			close_only = true
	if DisplayServer.get_name() == HEADLESS_DISPLAY or out_dir.is_empty() or DirAccess.make_dir_recursive_absolute(out_dir) != OK:
		push_error("d1_mundo_capture: precisa de janela (sem --headless) e de --out=<pasta> válida.")
		quit(1)
		return
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var scene: RendererTestScene = RendererTestScene.new()
	scene.options = D1MundoOptions.for_variant(variant_id)
	root.add_child(scene)
	await process_frame
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(), true)
	var lines: Array[String] = _header(variant_id, scene)
	var wide_lights: int = 0 if close_only else RendererPresets.PRESETS.size()
	for light: int in wide_lights:
		for view: int in RendererPresets.VIEWS.size():
			scene.apply_preset(light)
			scene.apply_view(view)
			lines.append(await _shoot(out_dir, "%s_%s" % [RendererPresets.PRESETS[light]["name"], RendererPresets.VIEWS[view]["name"]], MEASURE_FRAMES))
	for shot: Dictionary in CLOSE_SHOTS:
		var light: int = shot["light"]
		var anchor: Vector3 = (scene.get_node(String(shot["node"])) as Node3D).global_position
		var aim: Vector3 = shot["aim"]
		var eye: Vector3 = shot["eye"]
		scene.apply_preset(light)
		scene.camera.fov = CLOSE_FOV
		scene.camera.look_at_from_position(anchor + eye, anchor + aim)
		lines.append(await _shoot(out_dir, String(shot["name"]), 0))
	var file: FileAccess = FileAccess.open(out_dir.path_join(SUMMARY_FILE), FileAccess.WRITE)
	if file != null:
		file.store_string("\n".join(lines) + "\n")
		file.close()
	quit()


func _header(variant_id: String, scene: RendererTestScene) -> Array[String]:
	var lines: Array[String] = []
	lines.append("variante: %s | renderer: %s | driver: %s | placa: %s | godot: %s | modo: %s" % [variant_id, scene.rendering_method, RenderingServer.get_current_rendering_driver_name(), RenderingServer.get_video_adapter_name(), Engine.get_version_info()["string"], "depuração (binário do editor)" if OS.is_debug_build() else "release"])
	lines.append("viewport: %s | janela: %s | quadros por captura de longe: %d de acomodação e %d medidos, vsync desligado" % [root.size, DisplayServer.window_get_size(), SETTLE_FRAMES, MEASURE_FRAMES])
	lines.append("cena: %d triângulos | %d materiais | %d nós (%d MeshInstance3D, %d MultiMeshInstance3D)" % [scene.triangle_count(), scene.built.materials.size(), scene.find_children("*", "", true, false).size(), scene.find_children("*", "MeshInstance3D", true, false).size(), scene.find_children("*", "MultiMeshInstance3D", true, false).size()])
	lines.append("captura | quadro mediano (ms) | pior quadro (ms) | CPU de render mediana (ms) | CPU pior (ms) | GPU de render mediana (ms) | GPU pior (ms) | chamadas de desenho | primitivos | objetos | memória de vídeo (MB) | arquivo")
	return lines


## Espera os quadros (os de acomodação não contam), grava o PNG depois do desenho do último e devolve a linha do resumo; `measured` = 0 só captura.
func _shoot(out_dir: String, label: String, measured: int) -> String:
	var view_rid: RID = root.get_viewport_rid()
	var wall: Array[float] = []
	var cpu: Array[float] = []
	var gpu: Array[float] = []
	var last_us: int = Time.get_ticks_usec()
	for frame: int in SETTLE_FRAMES + measured:
		await process_frame
		var now_us: int = Time.get_ticks_usec()
		if frame >= SETTLE_FRAMES:
			wall.append(float(now_us - last_us) / US_PER_MS)
			cpu.append(RenderingServer.viewport_get_measured_render_time_cpu(view_rid))
			gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(view_rid))
		last_us = now_us
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	var file_name: String = "%s.png" % label
	if image == null or image.is_empty() or image.save_png(out_dir.path_join(file_name)) != OK:
		push_error("d1_mundo_capture: a captura '%s' falhou." % label)
		file_name = "FALHOU"
	return " | ".join([label, "%.2f" % _median(wall), "%.2f" % _worst(wall), "%.3f" % _median(cpu), "%.3f" % _worst(cpu), "%.3f" % _median(gpu), "%.3f" % _worst(gpu), str(int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))), str(int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))), str(int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))), "%.1f" % (Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / BYTES_PER_MB), file_name])


func _median(values: Array[float]) -> float:
	if values.is_empty():
		return 0.0
	var sorted: Array[float] = values.duplicate()
	sorted.sort()
	return sorted[int(sorted.size() * 0.5)]


func _worst(values: Array[float]) -> float:
	return 0.0 if values.is_empty() else values.max()
