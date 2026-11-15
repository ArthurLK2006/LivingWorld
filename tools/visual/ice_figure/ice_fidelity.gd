extends SceneTree
## Prova de fidelidade da paleta própria (ferramenta de arte; usa JANELA: renderer Mobile, uma execução por vez). Renderiza a MESMA malha (mesmas posições, normais e índices), com a mesma câmera e a mesma luz, duas vezes: com o material importado (textura original) e com a paleta própria, e mede a diferença de cor na área da figura (pixels que diferem do fundo em alguma das duas imagens).
## Uso: godot --path <projeto> --rendering-method mobile --resolution 320x240 -s res://tools/visual/ice_figure/ice_fidelity.gd -- <pasta de saída das imagens>
## Saída: por vista, a diferença média (0 a 255, média dos 3 canais), a maior diferença e onde ela aparece (pixel e altura da figura); termina com código 1 se a média geral passa de MEAN_LIMIT.
const Source = preload("res://tools/visual/ice_figure/ice_source.gd")
const Palette = preload("res://tools/visual/ice_figure/ice_palette.gd")
const VIEW: Vector2i = Vector2i(384, 576)
const VIEWS: Dictionary[String, float] = {"frente": 0.0, "tres_quartos": 40.0, "costas": 180.0}
const FOV_DEG: float = 30.0
const FRAME_MARGIN: float = 1.15
const SUN_PITCH_DEG: float = -45.0
const SUN_OFFSET_DEG: float = 25.0
const AMBIENT_ENERGY: float = 0.6
const BACKGROUND: Color = Color(0.2, 0.22, 0.25)
const SETTLE_FRAMES: int = 4
const DIFF_GAIN: int = 8
const MEAN_LIMIT: float = 2.0
const CHANNELS: int = 3


## Medidas de uma vista (ou do conjunto): pixels da figura, soma das diferenças, maior diferença, onde, e as linhas extremas da figura.
class Stat:
	extends RefCounted
	var pixels: int = 0
	var sum: int = 0
	var peak: int = 0
	var peak_at: Vector2i = Vector2i.ZERO
	var top: int = VIEW.y
	var bottom: int = 0

	func mean() -> float:
		return sum / maxf(pixels * 3.0, 1.0)


func _initialize() -> void:
	_run()


func _run() -> void:
	var surfs: Array[Source.Surf] = Source.load_surfaces()
	var images: Array[Image] = []
	var original_uvs: Array[PackedVector2Array] = []
	var original: Array[Material] = []
	var height: float = 0.0
	for surf: Source.Surf in surfs:
		images.append(Palette.image_of(surf.material))
		original_uvs.append(surf.uvs)
		original.append(surf.material)
		for point: Vector3 in surf.positions:
			height = maxf(height, point.y)
	var built: Palette.Built = Palette.build(surfs, images)
	if surfs.is_empty() or not built.error.is_empty():
		print("FALHA: %s" % ("fonte ausente" if surfs.is_empty() else built.error))
		quit(1)
		return
	var texture: ImageTexture = ImageTexture.create_from_image(built.image)
	var palette: Array[Material] = []
	for surf: Source.Surf in surfs:
		palette.append(Palette.material_for(surf.material, texture))
	var ports: Array[SubViewport] = [_stage(Source.mesh_of(surfs, original_uvs, original)), _stage(Source.mesh_of(surfs, built.uvs, palette))]
	var total: Stat = Stat.new()
	for view: String in VIEWS:
		var shots: Array[Image] = []
		for port: SubViewport in ports:
			_aim(port, height, VIEWS[view])
		for frame: int in SETTLE_FRAMES:
			await process_frame
		await RenderingServer.frame_post_draw
		for port: SubViewport in ports:
			var shot: Image = port.get_texture().get_image()
			shot.convert(Image.FORMAT_RGB8)
			shots.append(shot)
		var stat: Stat = _compare(shots[0], shots[1], total)
		print("%s: pixels da figura %d | diferença média %.3f de 255 | maior %d em (%d, %d), a %.0f%% da altura da figura" % [view, stat.pixels, stat.mean(), stat.peak, stat.peak_at.x, stat.peak_at.y, 100.0 * (stat.bottom - stat.peak_at.y) / maxf(stat.bottom - stat.top, 1.0)])
		_save(shots, OS.get_cmdline_user_args(), view)
	print("TOTAL: diferença média %.3f de 255 (limite %.1f) em %d pixels | paleta %d cores, imagem %s" % [total.mean(), MEAN_LIMIT, total.pixels, built.colors.size(), str(built.image.get_size())])
	quit(0 if total.mean() < MEAN_LIMIT else 1)


func _stage(mesh: Mesh) -> SubViewport:
	var port: SubViewport = SubViewport.new()
	port.size = VIEW
	port.own_world_3d = true
	port.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var environment: Environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = BACKGROUND
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color.WHITE
	environment.ambient_light_energy = AMBIENT_ENERGY
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	environment.sky = Sky.new()
	environment.sky.sky_material = ProceduralSkyMaterial.new()
	var world: WorldEnvironment = WorldEnvironment.new()
	world.environment = environment
	var holder: MeshInstance3D = MeshInstance3D.new()
	holder.mesh = mesh
	for node: Node in [world, DirectionalLight3D.new(), Camera3D.new(), holder]:
		port.add_child(node)
	root.add_child(port)
	return port


func _aim(port: SubViewport, height: float, yaw_deg: float) -> void:
	var camera: Camera3D = port.get_child(2) as Camera3D
	var sun: DirectionalLight3D = port.get_child(1) as DirectionalLight3D
	var target: Vector3 = Vector3(0.0, height * 0.5, 0.0)
	var away: Vector3 = Vector3(sin(deg_to_rad(yaw_deg)), 0.0, cos(deg_to_rad(yaw_deg))) * (height * FRAME_MARGIN * 0.5 / tan(deg_to_rad(FOV_DEG * 0.5)))
	camera.fov = FOV_DEG
	camera.transform = Transform3D(Basis.looking_at(-away, Vector3.UP), target + away)
	sun.rotation_degrees = Vector3(SUN_PITCH_DEG, yaw_deg + SUN_OFFSET_DEG, 0.0)


static func _compare(first: Image, second: Image, total: Stat) -> Stat:
	var a: PackedByteArray = first.get_data()
	var b: PackedByteArray = second.get_data()
	var stat: Stat = Stat.new()
	var width: int = first.get_width()
	for pixel: int in floori(a.size() / float(CHANNELS)):
		var at: int = pixel * CHANNELS
		var diff_r: int = absi(a[at] - b[at])
		var diff_g: int = absi(a[at + 1] - b[at + 1])
		var diff_b: int = absi(a[at + 2] - b[at + 2])
		var is_figure: bool = a[at] != a[0] or a[at + 1] != a[1] or a[at + 2] != a[2] or b[at] != b[0] or b[at + 1] != b[1] or b[at + 2] != b[2]
		if not is_figure:
			continue
		var row: int = floori(pixel / float(width))
		for target: Stat in [stat, total]:
			target.pixels += 1
			target.sum += diff_r + diff_g + diff_b
			target.top = mini(target.top, row)
			target.bottom = maxi(target.bottom, row)
		if maxi(diff_r, maxi(diff_g, diff_b)) > stat.peak:
			stat.peak = maxi(diff_r, maxi(diff_g, diff_b))
			stat.peak_at = Vector2i(pixel - row * width, row)
	return stat


static func _save(shots: Array[Image], args: PackedStringArray, view: String) -> void:
	if args.is_empty():
		return
	var size: Vector2i = shots[0].get_size()
	var a: PackedByteArray = shots[0].get_data()
	var b: PackedByteArray = shots[1].get_data()
	var amplified: PackedByteArray = PackedByteArray()
	amplified.resize(a.size())
	for index: int in a.size():
		amplified[index] = mini(absi(a[index] - b[index]) * DIFF_GAIN, 255)
	var sheet: Image = Image.create(size.x * 3, size.y, false, Image.FORMAT_RGB8)
	sheet.blit_rect(shots[0], Rect2i(Vector2i.ZERO, size), Vector2i.ZERO)
	sheet.blit_rect(shots[1], Rect2i(Vector2i.ZERO, size), Vector2i(size.x, 0))
	sheet.blit_rect(Image.create_from_data(size.x, size.y, false, Image.FORMAT_RGB8, amplified), Rect2i(Vector2i.ZERO, size), Vector2i(size.x * 2, 0))
	sheet.save_png("%s/fidelidade_%s.png" % [args[0], view])
