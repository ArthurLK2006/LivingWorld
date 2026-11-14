class_name QuaterniusTestScene
extends Node3D
## ART-11 (teste isolado, fora de `src/`; sem ligação com a simulação): personagens da Quaternius (CC0) montados por código em estúdio neutro: como vêm, facetados (normais planas), facetados com paleta, prova de modularidade, silhueta, proporções em cabeças e linha de roupas. Renderiza num SubViewport de 1600 x 1200 (independe do tamanho da janela). Argumentos depois de `--`: `--out=<pasta>` e `--only=<grupos>` (ref, rosto_perto, silhueta, lineup_roupas, modularidade_troca, proporcoes).

const Look := preload("res://tools/visual/quaternius_test/qt_look.gd")
const Assembler := preload("res://tools/visual/quaternius_test/qt_assembler.gd")

const ARG_OUT: String = "--out="
const ARG_ONLY: String = "--only="
const SIZE_FULL: Vector2i = Vector2i(1600, 1200)
const SIZE_HALF: Vector2i = Vector2i(800, 1200)
const SIZE_ROW: Vector2i = Vector2i(1600, 600)
const PACKS: String = "res://art_samples/quaternius/"
const FANTASY_DIR: String = PACKS + "fantasy/extraido/Modular Character Outfits - Fantasy[Standard]/Exports/glTF (Godot-Unreal)/"
const UBC_DIR: String = PACKS + "ubc/extraido/Universal Base Characters[Standard]/"
const UAL_PATH: String = PACKS + "ual/extraido/Universal Animation Library[Standard]/Unreal-Godot/UAL1_Standard.glb"
const IDLE: String = "Idle_Loop"
const IDLE_TIME: float = 0.9
const OUTFITS: Array[String] = ["Female_Peasant", "Male_Peasant", "Female_Ranger", "Male_Ranger"]
const SKY_TOP: Color = Color("8e8ba6")
const SKY_HORIZON: Color = Color("cfccdb")
const FLOOR_COLOR: Color = Color(0.3, 0.29, 0.35)

var _viewport: SubViewport
var _camera: Camera3D
var _rig: Node3D
var _actors: Node3D
var _floor: MeshInstance3D
var _sky: ProceduralSkyMaterial
var _out_dir: String = ""
var _only: PackedStringArray = PackedStringArray()
var _lines: PackedStringArray = PackedStringArray()
var _anims: AnimationLibrary = null
var _idle: String = IDLE
var _head_h: float = 0.24
var _head_mid_y: float = 1.68


func _ready() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with(ARG_OUT):
			_out_dir = arg.substr(ARG_OUT.length())
		elif arg.begins_with(ARG_ONLY):
			_only = arg.substr(ARG_ONLY.length()).split(",")
	if _out_dir.is_empty():
		_out_dir = OS.get_user_data_dir()
	DirAccess.make_dir_recursive_absolute(_out_dir)
	_build_stage()
	_run()


func _wanted(group: String) -> bool:
	return _only.is_empty() or _only.has(group)


func _run() -> void:
	await get_tree().process_frame
	_load_ual()
	_measure()
	if _wanted("ref"):
		await _shots_ref()
	if _wanted("rosto_perto"):
		await _shot_face()
	if _wanted("silhueta"):
		await _shot_silhouette()
	if _wanted("lineup_roupas"):
		await _shot_lineup()
	if _wanted("modularidade_troca"):
		await _shot_modular()
	if _wanted("proporcoes"):
		await _shot_proportions()
	var file: FileAccess = FileAccess.open(_out_dir.path_join("resumo_godot.txt"), FileAccess.WRITE)
	file.store_string("\n".join(_lines) + "\n")
	file.close()
	get_tree().quit()


func _build_stage() -> void:
	_viewport = SubViewport.new()
	_viewport.size = SIZE_FULL
	_viewport.own_world_3d = true
	_viewport.msaa_3d = Viewport.MSAA_4X
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_viewport)
	_sky = ProceduralSkyMaterial.new()
	_sky.sky_top_color = SKY_TOP
	_sky.sky_horizon_color = SKY_HORIZON
	_sky.ground_horizon_color = SKY_HORIZON
	_sky.ground_bottom_color = SKY_TOP
	_sky.sky_curve = 0.5
	_sky.ground_curve = 0.5
	var sky: Sky = Sky.new()
	sky.sky_material = _sky
	var env: Environment = Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("a8a6b4")
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var world_env: WorldEnvironment = WorldEnvironment.new()
	world_env.environment = env
	_viewport.add_child(world_env)
	_rig = Node3D.new()
	_viewport.add_child(_rig)
	var key: DirectionalLight3D = DirectionalLight3D.new()
	key.light_color = Color(1.0, 0.92, 0.8)
	key.light_energy = 1.05
	key.shadow_enabled = true
	key.sky_mode = DirectionalLight3D.SKY_MODE_LIGHT_ONLY
	_rig.add_child(key)
	key.look_at_from_position(Vector3(-3.0, 4.5, 4.0), Vector3(0.0, 1.0, 0.0), Vector3.UP)
	var rim: DirectionalLight3D = DirectionalLight3D.new()
	rim.light_color = Color(0.62, 0.74, 1.0)
	rim.light_energy = 1.0
	rim.sky_mode = DirectionalLight3D.SKY_MODE_LIGHT_ONLY
	_rig.add_child(rim)
	rim.look_at_from_position(Vector3(3.5, 3.0, -4.5), Vector3(0.0, 1.0, 0.0), Vector3.UP)
	_floor = MeshInstance3D.new()
	var disc: CylinderMesh = CylinderMesh.new()
	disc.top_radius = 3.0
	disc.bottom_radius = 3.0
	disc.height = 0.03
	_floor.mesh = disc
	var floor_mat: StandardMaterial3D = StandardMaterial3D.new()
	floor_mat.albedo_color = FLOOR_COLOR
	floor_mat.roughness = 1.0
	_floor.material_override = floor_mat
	_floor.position = Vector3(0.0, -0.015, 0.0)
	_viewport.add_child(_floor)
	_camera = Camera3D.new()
	_camera.far = 60.0
	_viewport.add_child(_camera)
	_camera.current = true
	_actors = Node3D.new()
	_viewport.add_child(_actors)


## Câmera em órbita sobre o ponto de mira (distância, giro e inclinação em graus, campo de visão); as luzes giram junto, então a chave fica sempre à esquerda e acima de quem olha.
func _aim(distance: float, yaw_deg: float, pitch_deg: float, fov: float, target: Vector3) -> void:
	_camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	_camera.fov = fov
	var yaw: float = deg_to_rad(yaw_deg)
	var pitch: float = deg_to_rad(pitch_deg)
	var offset: Vector3 = Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch)) * distance
	_camera.look_at_from_position(target + offset, target, Vector3.UP)
	_rig.rotation.y = yaw


func _clear() -> void:
	for child: Node in _actors.get_children():
		_actors.remove_child(child)
		child.free()


func _grab(size: Vector2i) -> Image:
	_viewport.size = size
	for i: int in 5:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image: Image = _viewport.get_texture().get_image()
	image.convert(Image.FORMAT_RGBA8)
	return image


func _save(image: Image, shot_name: String) -> void:
	image.save_png(_out_dir.path_join(shot_name + ".png"))
	_lines.append("captura: %s.png (%dx%d)" % [shot_name, image.get_width(), image.get_height()])


func _part_path(part_name: String) -> String:
	return FANTASY_DIR + "Modular Parts/" + part_name + ".gltf"


func _hair_path(hair_name: String) -> String:
	return UBC_DIR + "Hairstyles/Rigged to Head Bone/glTF (Godot -Unreal)/" + hair_name + ".gltf"


func _body_path(gender: String) -> String:
	return UBC_DIR + "Base Characters/Godot - UE/Superhero_" + gender + "_FullBody.gltf"


## Personagem "como vem": roupa inteira do pacote Fantasy + só a cabeça do corpo-base (Readme da Quaternius) + cabelo quando a roupa não tem capuz; posa em Idle_Loop se a UAL carregou.
func _character(kind: String, look: int, x: float) -> Assembler:
	var gender: String = "Female" if kind.begins_with("Female") else "Male"
	var asm: Assembler = Assembler.new(look)
	asm.add_part("outfit", FANTASY_DIR + "Outfits/" + kind + ".gltf")
	asm.add_part("head", _body_path(gender), Look.HEAD_BONES)
	if kind == "Male_Peasant":
		asm.add_part("hair", _hair_path("Hair_SimpleParted"))
	elif kind == "Female_Peasant":
		asm.add_part("hair", _hair_path("Hair_Long"))
	asm.root.position = Vector3(x, 0.0, 0.0)
	_actors.add_child(asm.root)
	_pose(asm)
	return asm


func _pose(asm: Assembler) -> void:
	if _anims == null:
		return
	var player: AnimationPlayer = AnimationPlayer.new()
	asm.root.add_child(player)
	player.add_animation_library("", _anims)
	player.play(_idle)
	player.seek(IDLE_TIME, true)
	player.pause()


func _load_ual() -> void:
	var inst: Node = (load(UAL_PATH) as PackedScene).instantiate()
	var players: Array[Node] = inst.find_children("*", "AnimationPlayer", true, false)
	if players.is_empty():
		_lines.append("UAL: sem AnimationPlayer no .glb")
		inst.free()
		return
	var source: AnimationPlayer = players[0] as AnimationPlayer
	_anims = AnimationLibrary.new()
	var names: PackedStringArray = source.get_animation_list()
	var rewritten: int = 0
	var removed: int = 0
	var deltas: int = 0
	var tracks: int = 0
	var sample: String = ""
	var ual_sk: Skeleton3D = inst.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	var ref_inst: Node = (load(FANTASY_DIR + "Outfits/Male_Peasant.gltf") as PackedScene).instantiate()
	var ref_sk: Skeleton3D = ref_inst.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	for anim_name: String in names:
		var anim: Animation = source.get_animation(anim_name).duplicate() as Animation
		for t: int in range(anim.get_track_count() - 1, -1, -1):
			var path: String = String(anim.track_get_path(t))
			if sample.is_empty():
				sample = path
			var colon: int = path.rfind(":")
			if colon >= 0:
				var bone: String = path.substr(colon + 1)
				if anim.track_get_type(t) == Animation.TYPE_POSITION_3D and bone != "root" and bone != "pelvis":
					anim.remove_track(t)
					removed += 1
					continue
				if anim.track_get_type(t) == Animation.TYPE_ROTATION_3D and ual_sk.find_bone(bone) >= 0 and ref_sk.find_bone(bone) >= 0:
					var ual_rest: Quaternion = ual_sk.get_bone_rest(ual_sk.find_bone(bone)).basis.get_rotation_quaternion()
					var ref_rest: Quaternion = ref_sk.get_bone_rest(ref_sk.find_bone(bone)).basis.get_rotation_quaternion()
					for k: int in anim.track_get_key_count(t):
						var q: Quaternion = anim.track_get_key_value(t, k)
						anim.track_set_key_value(t, k, ref_rest * (ual_rest.inverse() * q))
					deltas += 1
				anim.track_set_path(t, NodePath("Skeleton3D:" + bone))
				rewritten += 1
		tracks += anim.get_track_count()
		_anims.add_animation(StringName(anim_name), anim)
		if anim_name.to_lower() == "idle" or anim_name.to_lower() == "idle_loop":
			_idle = anim_name
	_lines.append("UAL: %d animações, %d trilhas (%d com o caminho reescrito para Skeleton3D:<osso>); exemplo de trilha original: %s; a lista inclui %s: %s" % [names.size(), tracks, rewritten, sample, IDLE, str(names.has(IDLE))])
	_lines.append("UAL: primeiros nomes: %s; repouso usado: %s" % [str(names.slice(0, 4)), _idle])
	_lines.append("UAL: %d trilhas de posição de ossos (exceto root e pelvis) removidas do retarget, só rotações, para manter o comprimento dos ossos do personagem" % removed)
	_lines.append("UAL: %d trilhas de rotação reescritas pelo delta de repouso (repouso do personagem x repouso da UAL)" % deltas)
	ref_inst.free()
	inst.free()


func _skeleton_of(path: String, holder: Array[Node]) -> Skeleton3D:
	var inst: Node = (load(path) as PackedScene).instantiate()
	holder.append(inst)
	return inst.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D


func _skeleton_diff(label: String, a: Skeleton3D, b: Skeleton3D) -> void:
	var same: bool = a.get_bone_count() == b.get_bone_count()
	var worst: float = 0.0
	var worst_bone: String = ""
	var worst_rot: float = 0.0
	var worst_rot_bone: String = ""
	for i: int in mini(a.get_bone_count(), b.get_bone_count()):
		if a.get_bone_name(i) != b.get_bone_name(i):
			same = false
		var d: float = (a.get_bone_global_rest(i).origin - b.get_bone_global_rest(i).origin).length()
		var r: float = rad_to_deg(a.get_bone_rest(i).basis.get_rotation_quaternion().angle_to(b.get_bone_rest(i).basis.get_rotation_quaternion()))
		if r > worst_rot:
			worst_rot = r
			worst_rot_bone = a.get_bone_name(i)
		if d > worst:
			worst = d
			worst_bone = a.get_bone_name(i)
	_lines.append("esqueletos %s: %d e %d ossos; nomes iguais na mesma ordem: %s; maior diferença da posição de repouso: %.3f m (osso %s); maior diferença da rotação de repouso local: %.1f graus (osso %s)" % [label, a.get_bone_count(), b.get_bone_count(), str(same), worst, worst_bone, worst_rot, worst_rot_bone])


## Números do corpo-base (pose de repouso = T): altura da pele, cabeça (vértices dominados pelo osso Head), altura em cabeças e largura de ombros; mais as diferenças entre os esqueletos dos pacotes.
func _measure() -> void:
	var holder: Array[Node] = []
	var skeletons: Dictionary = {}
	for gender: String in ["Male", "Female"]:
		var sk: Skeleton3D = _skeleton_of(_body_path(gender), holder)
		skeletons[gender] = sk
		var inst: Node = holder[holder.size() - 1]
		var skin_mi: MeshInstance3D = null
		for node: Node in inst.find_children("*", "MeshInstance3D", true, false):
			if String(node.name).to_lower().begins_with("superhero"):
				skin_mi = node as MeshInstance3D
		var a: Array = skin_mi.mesh.surface_get_arrays(0)
		var pos: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
		var bones: PackedInt32Array = a[Mesh.ARRAY_BONES]
		var wts: PackedFloat32Array = a[Mesh.ARRAY_WEIGHTS]
		@warning_ignore("integer_division")
		var bpv: int = bones.size() / pos.size()
		var min_y: float = 1.0e9
		var max_y: float = -1.0e9
		var head_min: float = 1.0e9
		var head_max: float = -1.0e9
		for v: int in pos.size():
			min_y = minf(min_y, pos[v].y)
			max_y = maxf(max_y, pos[v].y)
			var best: int = 0
			var best_w: float = -1.0
			for k: int in bpv:
				if wts[v * bpv + k] > best_w:
					best_w = wts[v * bpv + k]
					best = bones[v * bpv + k]
			if Look.bind_name(skin_mi.skin, sk, best) == "Head":
				head_min = minf(head_min, pos[v].y)
				head_max = maxf(head_max, pos[v].y)
		var head_h: float = head_max - head_min
		var left: int = sk.find_bone("upperarm_l")
		var right: int = sk.find_bone("upperarm_r")
		var joint_w: float = absf(sk.get_bone_global_rest(left).origin.x - sk.get_bone_global_rest(right).origin.x)
		var height: float = max_y - min_y
		_lines.append("corpo-base Superhero_%s (T, pele sem cabelo): altura %.3f m; cabeça %.3f m (y de %.3f a %.3f); ALTURA = %.2f CABEÇAS; ombros entre as articulações do braço %.3f m = %.2f cabeças (com 4,5 cm de deltoide de cada lado, %.2f cabeças); triângulos da pele %d" % [gender, height, head_h, head_min, head_max, height / head_h, joint_w, joint_w / head_h, (joint_w + 0.09) / head_h, Look.triangles(skin_mi.mesh)])
		if gender == "Male":
			_head_h = head_h
			_head_mid_y = (head_min + head_max) * 0.5
	var fantasy_male: Skeleton3D = _skeleton_of(FANTASY_DIR + "Outfits/Male_Peasant.gltf", holder)
	var fantasy_female: Skeleton3D = _skeleton_of(FANTASY_DIR + "Outfits/Female_Peasant.gltf", holder)
	var ual: Skeleton3D = _skeleton_of(UAL_PATH, holder)
	_skeleton_diff("corpo-base Male x roupa Fantasy Male", skeletons["Male"], fantasy_male)
	_skeleton_diff("corpo-base Female x roupa Fantasy Female", skeletons["Female"], fantasy_female)
	_skeleton_diff("corpo-base Male x UAL", skeletons["Male"], ual)
	_skeleton_diff("roupa Fantasy Male x UAL", fantasy_male, ual)
	for node: Node in holder:
		node.free()


func _stats(label: String, asm: Assembler) -> void:
	var tris: int = 0
	var meshes: int = 0
	var surfaces: int = 0
	var mats: Dictionary = {}
	var texs: Dictionary = {}
	for node: Node in asm.skeleton.find_children("*", "MeshInstance3D", true, false):
		var mi: MeshInstance3D = node as MeshInstance3D
		meshes += 1
		tris += Look.triangles(mi.mesh)
		surfaces += mi.mesh.get_surface_count()
		for s: int in mi.mesh.get_surface_count():
			var m: Material = mi.mesh.surface_get_material(s)
			if m == null:
				continue
			mats[String(m.resource_name)] = true
			var base: BaseMaterial3D = m as BaseMaterial3D
			if base != null:
				for t: int in BaseMaterial3D.TEXTURE_MAX:
					var tx: Texture2D = base.get_texture(t as BaseMaterial3D.TextureParam)
					if tx != null:
						texs[tx.get_instance_id()] = "%dx%d" % [tx.get_width(), tx.get_height()]
	_lines.append("personagem %s: %d malhas, %d superfícies, %d TRIÂNGULOS, %d ossos, materiais %s, %d texturas únicas %s; avisos de montagem: %s" % [label, meshes, surfaces, tris, asm.skeleton.get_bone_count(), str(mats.keys()), texs.size(), str(texs.values()), str(asm.notes)])


func _shots_ref() -> void:
	var views: Array = [["ref_como_vem_frente", Look.LOOK_ASIS, 0.0], ["ref_como_vem_costas", Look.LOOK_ASIS, 180.0], ["ref_como_vem_perspectiva", Look.LOOK_ASIS, 38.0], ["ref_facetado_perspectiva", Look.LOOK_FLAT, 38.0], ["ref_facetado_paleta_perspectiva", Look.LOOK_PALETTE, 38.0]]
	for view: Array in views:
		var look: int = view[1]
		var yaw: float = view[2]
		_clear()
		var left: Assembler = _character("Male_Peasant", look, -0.7)
		var right: Assembler = _character("Male_Ranger", look, 0.7)
		if look == Look.LOOK_ASIS and yaw == 0.0:
			_stats("Male_Peasant (como vem)", left)
			_stats("Male_Ranger (como vem)", right)
		_aim(6.0, yaw, 4.0, 30.0, Vector3(0.0, 0.95, 0.0))
		_save(await _grab(SIZE_FULL), view[0])


func _shot_face() -> void:
	var panels: Array[Image] = []
	for look: int in [Look.LOOK_ASIS, Look.LOOK_FLAT]:
		_clear()
		_character("Male_Peasant", look, 0.0)
		_aim(1.15, 22.0, 3.0, 24.0, Vector3(0.0, _head_mid_y - 0.02, 0.0))
		panels.append(await _grab(SIZE_HALF))
	var out: Image = Image.create(SIZE_FULL.x, SIZE_FULL.y, false, Image.FORMAT_RGBA8)
	for i: int in 2:
		out.blit_rect(panels[i], Rect2i(Vector2i.ZERO, SIZE_HALF), Vector2i(SIZE_HALF.x * i, 0))
	_save(out, "rosto_perto")


func _set_backdrop(flat: bool) -> void:
	var top: Color = Color(0.94, 0.94, 0.96) if flat else SKY_TOP
	var horizon: Color = Color(0.94, 0.94, 0.96) if flat else SKY_HORIZON
	_sky.sky_top_color = top
	_sky.sky_horizon_color = horizon
	_sky.ground_horizon_color = horizon
	_sky.ground_bottom_color = top
	_floor.visible = not flat


func _shot_silhouette() -> void:
	_clear()
	var x: float = -1.5
	for kind: String in OUTFITS:
		_character(kind, Look.LOOK_ASIS, x)
		x += 1.0
	var black: StandardMaterial3D = StandardMaterial3D.new()
	black.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	black.albedo_color = Color.BLACK
	for node: Node in _actors.find_children("*", "MeshInstance3D", true, false):
		(node as MeshInstance3D).material_override = black
	_set_backdrop(true)
	_aim(6.0, 0.0, 0.0, 30.0, Vector3(0.0, 0.95, 0.0))
	_save(await _grab(SIZE_FULL), "silhueta")
	_set_backdrop(false)


func _shot_lineup() -> void:
	var rows: Array[Image] = []
	for look: int in [Look.LOOK_FLAT, Look.LOOK_PALETTE]:
		_clear()
		var x: float = -1.5
		for kind: String in OUTFITS:
			_character(kind, look, x)
			x += 1.0
		_aim(4.4, 12.0, 3.0, 30.0, Vector3(0.0, 0.92, 0.0))
		rows.append(await _grab(SIZE_ROW))
	var out: Image = Image.create(SIZE_FULL.x, SIZE_FULL.y, false, Image.FORMAT_RGBA8)
	for i: int in 2:
		out.blit_rect(rows[i], Rect2i(Vector2i.ZERO, SIZE_ROW), Vector2i(0, SIZE_ROW.y * i))
	_save(out, "lineup_roupas")


func _label(text: String, position_m: Vector3, size_px: int, color: Color) -> void:
	var label: Label3D = Label3D.new()
	label.text = text
	label.font_size = size_px
	label.pixel_size = 0.0028
	label.modulate = color
	label.outline_size = 4
	label.outline_modulate = Color(1.0, 1.0, 1.0, 0.85)
	label.position = position_m
	_actors.add_child(label)


## Prova de modularidade: três personagens montados peça a peça no mesmo esqueleto; B e C partem do A e TROCAM peças já com o personagem na árvore e posado (a troca é só `add_part` num encaixe ocupado).
func _shot_modular() -> void:
	_clear()
	var started: int = Time.get_ticks_usec()
	var combos: Array[Assembler] = []
	for i: int in 3:
		var asm: Assembler = Assembler.new(Look.LOOK_ASIS)
		for part: String in ["Body", "Arms", "Legs", "Feet"]:
			asm.add_part(part.to_lower(), _part_path("Male_Peasant_" + part))
		asm.add_part("head", _body_path("Male"), Look.HEAD_BONES)
		asm.add_part("hair", _hair_path("Hair_SimpleParted"))
		asm.root.position = Vector3((i - 1) * 1.3, 0.0, 0.0)
		_actors.add_child(asm.root)
		_pose(asm)
		combos.append(asm)
	var built: int = Time.get_ticks_usec()
	var b: Assembler = combos[1]
	b.add_part("body", _part_path("Male_Ranger_Body"))
	b.add_part("arms", _part_path("Male_Ranger_Arms"))
	b.add_part("shoulder", _part_path("Male_Ranger_Acc_Pauldron"))
	b.add_part("hair", _hair_path("Hair_Buzzed"))
	b.add_part("beard", _hair_path("Hair_Beard"))
	var c: Assembler = combos[2]
	c.add_part("legs", _part_path("Male_Ranger_Legs"))
	c.add_part("feet", _part_path("Male_Ranger_Feet_Boots"))
	c.add_part("hood", _part_path("Male_Ranger_Head_Hood"))
	c.add_part("shoulder", _part_path("Male_Ranger_Acc_Pauldron"))
	c.remove_slot("hair")
	var swapped: int = Time.get_ticks_usec()
	for i: int in 3:
		_stats("combinação %s (modular)" % ["A", "B", "C"][i], combos[i])
	_lines.append("modularidade: 3 personagens montados (6 peças cada) em %.0f ms; 10 trocas/remoções em tempo de execução em %.0f ms" % [(built - started) / 1000.0, (swapped - built) / 1000.0])
	var texts: Array[String] = ["A: camponês completo\n(4 peças + cabelo)", "B: troca corpo e braços\n(Ranger), ombreira,\ncabelo curto e barba", "C: troca pernas e botas\n(Ranger), capuz e ombreira"]
	for i: int in 3:
		_label(texts[i], Vector3((i - 1) * 1.3, 2.15, 0.0), 32, Color(0.1, 0.1, 0.16))
	_aim(6.4, 0.0, 3.0, 30.0, Vector3(0.0, 1.0, 0.0))
	_save(await _grab(SIZE_FULL), "modularidade_troca")


func _shot_proportions() -> void:
	_clear()
	_character("Male_Peasant", Look.LOOK_ASIS, 0.0)
	var red: StandardMaterial3D = StandardMaterial3D.new()
	red.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	red.albedo_color = Color(0.75, 0.1, 0.1)
	for n: int in range(1, 9):
		var bar: MeshInstance3D = MeshInstance3D.new()
		var box: BoxMesh = BoxMesh.new()
		box.size = Vector3(3.0, 0.008, 0.008)
		bar.mesh = box
		bar.material_override = red
		bar.position = Vector3(0.0, n * _head_h, 0.8)
		_actors.add_child(bar)
		_label(str(n), Vector3(-1.35, n * _head_h + 0.07, 0.8), 72, Color(0.75, 0.1, 0.1))
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.size = 2.6
	_camera.look_at_from_position(Vector3(0.0, 1.1, 6.0), Vector3(0.0, 1.1, 0.0), Vector3.UP)
	_rig.rotation.y = 0.0
	_save(await _grab(SIZE_FULL), "proporcoes")
