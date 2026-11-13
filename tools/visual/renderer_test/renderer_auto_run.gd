class_name RendererAutoRun
extends RefCounted
## Modo automático da cena de teste de renderizadores (ARTE-F0): com `--auto --out=<pasta>` (argumentos de usuário, depois de `--`), para cada predefinição de luz x câmera espera alguns quadros,
## mede, salva um PNG e, no fim, grava `resumo.txt` e encerra. Mede com o vsync desligado (senão todo renderer rápido mostra o mesmo valor da tela). Ferramenta de desenvolvimento: só mede, não decide.

const ARG_AUTO: String = "--auto"
const ARG_OUT_PREFIX: String = "--out="
## Quadros de acomodação (compilação de shaders, estabilização) e quadros medidos em cada captura.
const SETTLE_FRAMES: int = 30
const MEASURE_FRAMES: int = 180
const SUMMARY_FILE: String = "resumo.txt"
## Sem janela (--headless) o Godot não desenha quadro nenhum: esperar o desenho travaria, então o modo automático recusa.
const HEADLESS_DISPLAY: String = "headless"
## A saturação e o brilho médios saem de uma versão reduzida da imagem (alvo do dia: saturação 0,44 e brilho 0,59).
const COLOR_SAMPLE: Vector2i = Vector2i(160, 90)
const BYTES_PER_MB: float = 1048576.0
const MICROSECONDS_PER_SECOND: float = 1000000.0
const MICROSECONDS_PER_MS: float = 1000.0
const TABLE_HEADER: String = "captura | fps médio | pior quadro (ms) | chamadas de desenho | primitivos | objetos | memória de vídeo (MB) | saturação média | brilho médio | arquivo"


## Resultado de uma captura.
class Shot extends RefCounted:
	var label: String = ""
	var fps: float = 0.0
	var worst_ms: float = 0.0
	var draw_calls: int = 0
	var primitives: int = 0
	var objects: int = 0
	var video_mb: float = 0.0
	var saturation: float = 0.0
	var brightness: float = 0.0
	var file: String = ""

	func to_line() -> String:
		return " | ".join([label, "%.1f" % fps, "%.1f" % worst_ms, str(draw_calls), str(primitives), str(objects), "%.1f" % video_mb, "%.3f" % saturation, "%.3f" % brightness, file])


static func is_requested(args: PackedStringArray) -> bool:
	return args.has(ARG_AUTO)


## Pasta pedida em `--out=<pasta>`; vazia se não veio.
static func out_dir(args: PackedStringArray) -> String:
	for argument: String in args:
		if argument.begins_with(ARG_OUT_PREFIX):
			return argument.trim_prefix(ARG_OUT_PREFIX)
	return ""


## Roda todas as combinações, grava o resumo em `out_path` e encerra o jogo (código 1 se a pasta de saída for inválida).
func run(scene: RendererTestScene, out_path: String) -> void:
	var tree: SceneTree = scene.get_tree()
	if DisplayServer.get_name() == HEADLESS_DISPLAY:
		push_error("RendererAutoRun.run: o modo automático precisa de janela e renderer de verdade; sem janela não há quadro desenhado nem imagem para medir.")
		tree.quit(1)
		return
	if out_path.is_empty() or DirAccess.make_dir_recursive_absolute(out_path) != OK:
		push_error("RendererAutoRun.run: pasta de saída inválida ou impossível de criar ('%s'); esperado --out=<pasta>." % out_path)
		tree.quit(1)
		return
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var lines: Array[String] = _header(scene)
	for preset: int in RendererPresets.PRESETS.size():
		for view: int in RendererPresets.VIEWS.size():
			scene.apply_preset(preset)
			scene.apply_view(view)
			var shot: Shot = await _capture(scene, out_path)
			lines.append(shot.to_line())
	_write(out_path.path_join(SUMMARY_FILE), lines)
	tree.quit()


func _header(scene: RendererTestScene) -> Array[String]:
	var on: Array[String] = []
	var off: Array[String] = []
	for effect: StringName in RendererPresets.EFFECTS:
		if scene.supported[effect]:
			on.append(String(effect))
		else:
			off.append(String(effect))
	var lines: Array[String] = []
	lines.append("renderer: %s | driver: %s | placa: %s | godot: %s" % [scene.rendering_method, RenderingServer.get_current_rendering_driver_name(), RenderingServer.get_video_adapter_name(), Engine.get_version_info()["string"]])
	lines.append("janela: %s | vsync: desligado no modo automático | quadros por captura: %d de acomodação e %d medidos" % [DisplayServer.window_get_size(), SETTLE_FRAMES, MEASURE_FRAMES])
	lines.append("cena: %d triângulos (orçamento %d), %d materiais" % [scene.triangle_count(), RendererTestScene.TRIANGLE_BUDGET, scene.built.materials.size()])
	lines.append("efeitos ligados: %s | DESLIGADOS (o renderer não os aceita, tabela [HIP]): %s" % [", ".join(on), ", ".join(off)])
	lines.append(TABLE_HEADER)
	return lines


## Espera os quadros, mede o tempo de cada um (os de acomodação não contam) e, depois do desenho do último, lê os monitores e salva o PNG.
func _capture(scene: RendererTestScene, out_path: String) -> Shot:
	var tree: SceneTree = scene.get_tree()
	var shot: Shot = Shot.new()
	shot.label = "%s_%s" % [RendererPresets.PRESETS[scene.preset_index]["name"], RendererPresets.VIEWS[scene.view_index]["name"]]
	var total_us: int = 0
	var worst_us: int = 0
	var last_us: int = Time.get_ticks_usec()
	for frame: int in SETTLE_FRAMES + MEASURE_FRAMES:
		await tree.process_frame
		var now_us: int = Time.get_ticks_usec()
		if frame >= SETTLE_FRAMES:
			total_us += now_us - last_us
			worst_us = maxi(worst_us, now_us - last_us)
		last_us = now_us
	await RenderingServer.frame_post_draw
	shot.fps = float(MEASURE_FRAMES) * MICROSECONDS_PER_SECOND / float(maxi(total_us, 1))
	shot.worst_ms = float(worst_us) / MICROSECONDS_PER_MS
	shot.draw_calls = int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	shot.primitives = int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	shot.objects = int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))
	shot.video_mb = Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / BYTES_PER_MB
	var image: Image = scene.get_viewport().get_texture().get_image()
	if image == null or image.is_empty():
		push_error("RendererAutoRun._capture: a captura '%s' veio vazia (renderer sem imagem, como o modo sem janela)." % shot.label)
		return shot
	var path: String = out_path.path_join("%s.png" % shot.label)
	if image.save_png(path) == OK:
		shot.file = path.get_file()
	else:
		push_error("RendererAutoRun._capture: não foi possível gravar o PNG '%s'." % path)
	_measure_color(image, shot)
	return shot


func _measure_color(image: Image, shot: Shot) -> void:
	image.resize(COLOR_SAMPLE.x, COLOR_SAMPLE.y, Image.INTERPOLATE_BILINEAR)
	var saturation_sum: float = 0.0
	var brightness_sum: float = 0.0
	for y: int in COLOR_SAMPLE.y:
		for x: int in COLOR_SAMPLE.x:
			var pixel: Color = image.get_pixel(x, y)
			saturation_sum += pixel.s
			brightness_sum += pixel.v
	var pixels: float = float(COLOR_SAMPLE.x * COLOR_SAMPLE.y)
	shot.saturation = saturation_sum / pixels
	shot.brightness = brightness_sum / pixels


func _write(path: String, lines: Array[String]) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("RendererAutoRun._write: não foi possível gravar '%s' (%s)." % [path, error_string(FileAccess.get_open_error())])
		return
	file.store_string("\n".join(lines) + "\n")
	file.close()
