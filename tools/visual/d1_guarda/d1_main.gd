extends SceneTree
## D1-A (estudo isolado, nada entra no jogo): o guarda da base Quaternius em três versões (original, facetado PERTO, facetado LONGE). Modos: `build` (gera as malhas em .res), `shots` (comparações lado a lado), `group` (cena de grupo), `measure` (custo).
## Uso: godot --path <projeto> -s res://tools/visual/d1_guarda/d1_main.gd -- --mode=build,shots,group [--out=<pasta de PNG>]
const Facet = preload("res://tools/visual/d1_guarda/d1_facet.gd")
const Rigid = preload("res://tools/visual/d1_guarda/d1_rigid.gd")
const MESH_DIR: String = "res://art_samples/d1/"
const BEARD: String = "res://assets/characters/quaternius/hair/Hair_Beard.glb"
const SLOTS: PackedStringArray = ["torso_arms", "legs", "boots", "head", "hair", "eyebrow", "extra_0", "extra_1", "extra_2", "extra_3", "extra_4", "beard"]
const VERSIONS: PackedStringArray = ["orig", "near", "far"]
const ALL: PackedStringArray = ["orig", "near", "far", "near_tex"]
const SIZE: Vector2i = Vector2i(1280, 720)
const CELL: int = 426
## Por superfície ("malha:superfície"): triângulos (perto, longe) e o papel de cor; o que não está na lista fica de fora (capuz, botas e ombreira do pacote, cabelo curto: viram peças rígidas ou cor por posição).
const PARTS: Dictionary[String, Array] = {
	"Male_Ranger_Arms:0": [650, 120, "sleeve"], "Male_Ranger_Arms:1": [420, 70, "glove"], "Male_Ranger_Body:0": [800, 140, "torso"], "Male_Ranger_Legs:0": [380, 80, "legs"],
	"Male_Ranger_Arms_Bracer:0": [260, 0, "leather"], "Male_Ranger_Body_Belt_1:0": [120, 0, "leather"], "Male_Ranger_Body_Belt_2:0": [120, 0, "leather"],
	"Eyes:0": [40, 0, "eye"], "SuperHero_Male:0": [700, 100, "skin"], "Eyebrows_Regular:0": [60, 0, "hair"], "Hair_Beard:0": [330, 0, "hair"],
}
## Construções: nome, camada (0 perto, 1 longe) e se a cor passa pela paleta (a "tex" fica com a cor da textura, só para comparar).
const BUILDS: Array = [["near", 0, true], ["far", 1, true], ["near_tex", 0, false]]
const SKIN: Color = Color("D8B48C")
const HAIR: Color = Color("3E352F")
const EYE: Color = Color("17171A")
## Papel da peça: cores para o verde, o marrom e o cinza da textura de origem e o brilho de referência dela.
const ROLES: Dictionary[String, Array] = {
	"torso": [Rigid.SLATE, Rigid.WINE_L, Rigid.STEEL, 0.55], "sleeve": [Rigid.PETROL, Rigid.WINE_D, Rigid.STEEL, 0.55], "legs": [Rigid.CHARCOAL, Rigid.WINE_D, Rigid.STEEL, 0.55],
	"leather": [Rigid.WINE_L, Rigid.WINE_D, Rigid.STEEL, 0.55], "glove": [Rigid.WINE_D, Rigid.WINE_D, Rigid.WINE_D, 0.55], "skin": [SKIN, SKIN, SKIN, 0.8], "hair": [HAIR, HAIR, HAIR, 0.55], "eye": [EYE, EYE, EYE, 0.55],
}
## Vistas: distância, ângulo para baixo, campo de visão vertical e ponto de mira (as de 20 e 60 m imitam a câmera do jogo, com o campo padrão de 75 graus).
const VIEWS: Dictionary[String, Dictionary] = {
	"rosto": {"d": 4.5, "pitch": 4.0, "fov": 11.0, "aim": Vector3(0.0, 1.62, 0.0)},
	"proxima": {"d": 4.0, "pitch": 10.0, "fov": 32.0, "aim": Vector3(0.0, 0.95, 0.0)},
	"tres_quartos": {"d": 4.0, "pitch": 10.0, "fov": 32.0, "aim": Vector3(0.0, 0.95, 0.0), "yaw": 35.0},
	"iso": {"d": 20.0, "pitch": 50.0, "fov": 75.0, "aim": Vector3(0.0, 1.0, 0.0)},
	"estrategica": {"d": 60.0, "pitch": 70.0, "fov": 75.0, "aim": Vector3(0.0, 1.0, 0.0)},
}
## Luzes: predefinição da cena de renderizadores e giro extra do sol em graus (a dourada original é contraluz; a "_f" gira o sol para iluminar a frente).
const LIGHTS: Dictionary[String, Vector2i] = {"dia": Vector2i(0, 0), "dourada": Vector2i(1, 0), "dourada_f": Vector2i(1, 120)}

var _out: String = "/private/tmp/claude-501/-Users-arthurlk-LivingWorld/42f6a974-1a60-4dc8-a2f5-233cb25a262e/scratchpad/d1_capturas/guarda/"
var _catalog: CharacterCatalog = CharacterCatalog.from_file().catalog
var _look: CharacterAppearance = CharacterAppearance.new()
var _port: SubViewport = SubViewport.new()
var _sun: DirectionalLight3D = DirectionalLight3D.new()
var _env: Environment = Environment.new()
var _sky: ProceduralSkyMaterial = ProceduralSkyMaterial.new()
var _camera: Camera3D = Camera3D.new()
var _actors: Dictionary[String, Node3D] = {}
var _only: PackedStringArray = ALL


func _initialize() -> void:
	var modes: PackedStringArray = []
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--mode="):
			modes = arg.substr(7).split(",")
		elif arg.begins_with("--out="):
			_out = arg.substr(6)
		elif arg.begins_with("--versions="):
			_only = arg.substr(11).split(",")
	_look.body_id = "male_a"
	_look.outfit_id = "ranger_m"
	_look.hair_id = "buzzed"
	_look.eyebrow_id = "brow_regular"
	DirAccess.make_dir_recursive_absolute(_out)
	if modes.has("build"):
		_build()
	if modes.has("shots") or modes.has("group") or modes.has("measure"):
		_stage()
		for version: String in _only:
			_actors[version] = _character(version)
			_port.add_child(_actors[version])
			_actors[version].visible = false
	if modes.has("measure"):
		await _measure(_only[0])
	if modes.has("shots"):
		for view: String in VIEWS:
			for light: String in LIGHTS:
				await _shot(view, light, VERSIONS, "")
		await _shot("proxima", "dia", ["orig", "near_tex", "near"], "_paleta")
		await _shot("rosto", "dia", ["orig", "near_tex", "near"], "_paleta")
		await _shot("proxima", "dia", VERSIONS, "_walk", "walk", 0.35)
	if modes.has("group"):
		for light: String in LIGHTS:
			await _group(light)
	quit()


## O guarda montado pelo CharacterAssembler (homem, Ranger sem o capuz, cabelo curto e barba acoplada à mão).
func _assembled() -> CharacterAssembler:
	var assembler: CharacterAssembler = CharacterAssembler.new()
	assembler.build(_look, _catalog)
	assembler.swap_part("extra_0", "")
	assembler.swap_part("beard", BEARD)
	return assembler


## Passagem de facetamento, offline: grava as malhas e a pele em .res (perto, longe e a variante de cor da textura).
func _build() -> void:
	var assembler: CharacterAssembler = _assembled()
	var meshes: Array[MeshInstance3D] = CharacterSceneLoader.meshes_of(assembler)
	for spec: Array in BUILDS:
		var facet: Facet = Facet.new(meshes[0].skin)
		for mi: MeshInstance3D in meshes:
			for surface: int in mi.mesh.get_surface_count():
				var part: Array = PARTS.get("%s:%d" % [mi.name, surface], [0, 0, ""])
				if part[spec[1]] > 0:
					facet.add_surface(mi, surface, part[spec[1]], _tone.bind(part[2]) if spec[2] else Callable())
		for piece: Dictionary in Rigid.new().pieces(spec[1]):
			facet.add_rigid(piece)
		ResourceSaver.save(facet.build(), MESH_DIR + "guard_%s.res" % spec[0])
		ResourceSaver.save(facet.skin(), MESH_DIR + "guard_skin.res")
		print("build %s: %d triangulos" % [spec[0], facet.triangles()])
	assembler.free()


## Cor por bloco: o verde, o marrom e o cinza da textura de origem viram a cor da paleta do guarda do papel da peça; o brilho da textura só varia o tom (referência no 4o item). A pele do crânio vira cabelo por posição.
func _tone(color: Color, centroid: Vector3, role: String) -> Color:
	var table: Array = ROLES["hair" if role == "skin" and (centroid.y > 1.745 or (centroid.y > 1.70 and centroid.z < -0.01)) else role]
	var base: Color = table[2] if color.s < 0.18 else (table[1] if color.h < 0.17 or color.h > 0.9 else table[0])
	var shade: float = clampf(color.v / float(table[3]), 0.8, 1.05 if role == "skin" else 1.3)
	return Color(base.r * shade, base.g * shade, base.b * shade)


## Uma versão do guarda: a original (as 13 malhas do catálogo) ou o esqueleto do montador com a malha facetada única no lugar delas.
func _character(version: String) -> Node3D:
	var assembler: CharacterAssembler = _assembled()
	if version != "orig":
		for slot: String in SLOTS:
			assembler.swap_part(slot, "")
		var node: MeshInstance3D = MeshInstance3D.new()
		node.mesh = load(MESH_DIR + "guard_%s.res" % version)
		node.skin = load(MESH_DIR + "guard_skin.res")
		CharacterSceneLoader.skeleton_of(assembler).add_child(node)
		node.skeleton = NodePath("..")
	return assembler


func _stage() -> void:
	_port.size = SIZE
	_port.own_world_3d = true
	_port.msaa_3d = Viewport.MSAA_4X
	_port.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_port)
	_env.background_mode = Environment.BG_SKY
	_env.sky = Sky.new()
	_env.sky.sky_material = _sky
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_env.adjustment_enabled = true
	var world: WorldEnvironment = WorldEnvironment.new()
	world.environment = _env
	_sun.shadow_enabled = true
	_sun.directional_shadow_max_distance = 150.0
	_camera.far = 600.0
	var ground: MeshInstance3D = MeshInstance3D.new()
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(400.0, 400.0)
	ground.mesh = plane
	var paint: StandardMaterial3D = StandardMaterial3D.new()
	paint.albedo_color = Color(0.36, 0.33, 0.28)
	paint.roughness = 1.0
	ground.material_override = paint
	for node: Node in [world, _sun, _camera, ground]:
		_port.add_child(node)


func _light(light: String) -> void:
	RendererPresets.apply(RendererPresets.PRESETS[LIGHTS[light].x], _sun, _env, _sky, RendererPresets.supported_effects(RenderingServer.get_current_rendering_method()))
	_sun.rotation_degrees.y += LIGHTS[light].y


func _aim(view: Dictionary) -> void:
	var pitch: float = deg_to_rad(float(view["pitch"]))
	var arm: Vector3 = Vector3(0.0, sin(pitch), cos(pitch)) * float(view["d"])
	_camera.fov = float(view["fov"])
	_camera.transform = Transform3D(Basis.looking_at(-arm, Vector3.UP), (view["aim"] as Vector3) + arm)


func _pose(actor: Node3D, clip: String, time: float) -> void:
	var player: AnimationPlayer = actor.find_children("*", "AnimationPlayer", true, false)[0]
	player.play(clip)
	player.seek(time, true)
	player.pause()


func _grab() -> Image:
	for frame: int in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = _port.get_texture().get_image()
	image.convert(Image.FORMAT_RGB8)
	return image


## Uma vista nas três versões lado a lado [original | perto | longe], cada uma sozinha no centro da MESMA câmera, luz e pose; nas vistas distantes grava também o recorte ampliado.
func _shot(view: String, light: String, versions: PackedStringArray, suffix: String, clip: String = "idle", time: float = 0.9) -> void:
	_light(light)
	_aim(VIEWS[view])
	var sheet: Image = Image.create(SIZE.x, SIZE.y, false, Image.FORMAT_RGB8)
	sheet.fill(Color.WHITE)
	var zoom: Image = Image.create(SIZE.x, SIZE.y, false, Image.FORMAT_RGB8)
	for index: int in versions.size():
		for version: String in ALL:
			_actors[version].visible = version == versions[index]
		_actors[versions[index]].rotation_degrees.y = float(VIEWS[view].get("yaw", 0.0))
		_pose(_actors[versions[index]], clip, time)
		var image: Image = await _grab()
		sheet.blit_rect(image, Rect2i((SIZE.x - CELL) / 2, 0, CELL, SIZE.y), Vector2i(index * (CELL + 1), 0))
		var crop: Image = image.get_region(Rect2i((SIZE.x - 107) / 2, SIZE.y / 2 - 90, 107, 180))
		crop.resize(CELL, 720, Image.INTERPOLATE_NEAREST)
		zoom.blit_rect(crop, Rect2i(0, 0, CELL, SIZE.y), Vector2i(index * (CELL + 1), 0))
	sheet.save_png(_out + "%s_%s%s.png" % [view, light, suffix])
	if VIEWS[view]["d"] >= 20.0:
		zoom.save_png(_out + "%s_%s%s_x4.png" % [view, light, suffix])


## Cena de grupo na vista isométrica: 5 guardas PERTO na frente e 25 LONGE espalhados atrás, com idle e walk misturados.
func _group(light: String) -> void:
	_light(light)
	_aim(VIEWS["iso"])
	for version: String in ALL:
		_actors[version].visible = false
	var crowd: Node3D = Node3D.new()
	_port.add_child(crowd)
	for index: int in 30:
		var near: bool = index < 5
		var actor: Node3D = _actors["near" if near else "far"].duplicate()
		actor.position = Vector3((index - 2) * 2.4, 0.0, 6.0) if near else Vector3(((index - 5) % 5 - 2) * 5.0, 0.0, 2.0 - float((index - 5) / 5) * 4.0)
		actor.visible = true
		crowd.add_child(actor)
		_pose(actor, "walk" if index % 3 == 0 else "idle", 0.13 * index)
	(await _grab()).save_png(_out + "grupo_%s.png" % light)
	crowd.free()


## Custo por quadro no Mobile com N guardas animados (idle e walk) em grade de 2 m na vista isométrica: sem MSAA, vsync desligado, sombra do sol ligada, desenho forçado sem apresentar (vazão). CPU e GPU de render do viewport, chamadas e triângulos do quadro, memória de vídeo.
func _measure(version: String) -> void:
	_port.msaa_3d = Viewport.MSAA_DISABLED
	_light("dia")
	_aim(VIEWS["iso"])
	var port: RID = _port.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(port, true)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	var rows: PackedStringArray = ["versao=%s modo=%s build_de_depuracao=%s renderer=%s" % [version, "depuracao" if OS.is_debug_build() else "release", str(OS.is_debug_build()), RenderingServer.get_current_rendering_method()]]
	rows.append("N | triangulos/quadro | chamadas/quadro | objetos | VRAM MB | CPU render ms mediana/pior | quadro (vazao) ms mediana/pior")
	for count: int in [1, 10, 25, 50, 100, 200]:
		if count > 50 and version != "far":
			continue
		var crowd: Node3D = Node3D.new()
		_port.add_child(crowd)
		var cols: int = ceili(sqrt(count * 1.4))
		for index: int in count:
			var actor: Node3D = _actors[version].duplicate()
			actor.visible = true
			actor.position = Vector3((index % cols - (cols - 1) * 0.5) * 2.0, 0.0, (index / cols - count / cols * 0.5) * 2.0)
			crowd.add_child(actor)
			var player: AnimationPlayer = actor.find_children("*", "AnimationPlayer", true, false)[0]
			player.play("walk" if index % 2 == 0 else "idle")
			player.seek(0.1 * index, true)
		for frame: int in 40:
			await process_frame
		RenderingServer.render_loop_enabled = false
		var cpu: Array[float] = []
		var step: Array[float] = []
		var last: int = Time.get_ticks_usec()
		for frame: int in 150:
			await process_frame
			RenderingServer.force_draw(false, 0.016)
			var now: int = Time.get_ticks_usec()
			step.append((now - last) / 1000.0)
			last = now
			cpu.append(RenderingServer.viewport_get_measured_render_time_cpu(port))
		RenderingServer.render_loop_enabled = true
		rows.append("%d | %d | %d | %d | %.1f | %s | %s" % [count, RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME), RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME), RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME), RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_VIDEO_MEM_USED) / 1048576.0, _stat(cpu), _stat(step.slice(10))])
		crowd.free()
		await process_frame
	var file: FileAccess = FileAccess.open(_out + "medicao_%s.txt" % version, FileAccess.WRITE)
	file.store_string("\n".join(rows) + "\n")
	print("\n".join(rows))


## "mediana/pior" de uma lista de tempos em ms.
func _stat(values: Array[float]) -> String:
	var sorted: Array[float] = values.duplicate()
	sorted.sort()
	return "%.2f/%.2f" % [sorted[sorted.size() / 2], sorted[sorted.size() - 1]]
