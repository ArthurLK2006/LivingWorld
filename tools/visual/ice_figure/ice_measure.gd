extends SceneTree
## Medidor dos critérios objetivos da figura do Ice Warrior (ferramenta de arte, entrega 6d; SEM janela). Monta a figura REAL pelo `CharacterFigure` (um catálogo de teste em memória, sem arquivo, com `figures` apontando para a cena e o JSON gravados por `ice_prepare.gd`), toca idle e walk e mede, em FRAMES quadros espaçados do ciclo, cada critério do contrato "Figura inteira" (docs/modules/presentation.md). Imprime a tabela e a grava em `medidas_6d.txt` ao lado da figura (fora do Git). Espera UM quadro depois de pôr a figura na árvore (antes dele o `Skeleton3D` não atualiza as poses globais). PULA, com código 0, se a figura preparada não existe (o ativo fica fora do Git); termina com 1 se algum critério falha.
## godot --headless --path <projeto> -s res://tools/visual/ice_figure/ice_measure.gd [-- --dir=res://art_samples/ice_figure]
## (a) PÉS: o ponto mais baixo da malha dos pés (vértices com peso de pé de pelo menos FOOT_WEIGHT; pele em CPU) contra o chão (y = 0), no idle e no walk. (b) ESTICAMENTO: por triângulo, a maior aresta posada sobre a maior aresta no bind, a maior das FRAMES poses do walk (o critério do `ice_selftest.gd` da prova de movimento), e o mesmo nas zonas de ombro, cotovelo, quadril e pescoço (triângulos a menos de JOINT_RADIUS_M da articulação, no bind). (c) LÂMINA x COXA: o eixo da espada (da base à ponta; `Metrics.blade_ends`) contra a cápsula de cada coxa (o segmento do osso da coxa ao do joelho, raio THIGH_RADIUS_M na escala do jogo, 1,80 m); o quadro conta se algum VÉRTICE da lâmina chega a menos que o raio do eixo da coxa (a tabela mostra também a distância do eixo da lâmina, mais otimista). O raio é [HIP], perto da mediana medida (0,102 m no jogo) da distância dos vértices das calças ao eixo da coxa. (d) SUPERFÍCIES: as das malhas com pele (o corpo) e as da malha sem pele (a espada). (e) DETERMINISMO: `build` repetido e `duplicate()` dão as mesmas poses no `AnimationPlayer`, e a amostragem direta das trilhas (a que (a) a (c) usam) dá a pose do player.
const Metrics = preload("res://tools/visual/ice_figure/ice_metrics.gd")
const Writer = preload("res://tools/visual/ice_figure/ice_writer.gd")
const FIGURE_ID: String = "ice"
const DIR_ARG: String = "--dir="
const REPORT_FILE: String = "medidas_6d.txt"
const FRAMES: int = 40
const CLIPS: PackedStringArray = ["idle", "walk"]
const FOOT_BONES: PackedStringArray = ["foot_l", "foot_r"]
const FOOT_WEIGHT: float = 0.9
const MAX_FOOT_GAP_M: float = 0.01
const MAX_STRETCH: float = 1.5
const JOINT_RADIUS_M: float = 0.12
## O raio ampliado das zonas: os triângulos mais esticados ficam FORA do raio de 12 cm (a revisão mediu 13,5 cm da articulação mais próxima), então a tabela mostra também o máximo com este raio.
const WIDE_JOINT_RADIUS_M: float = 0.2
const WALK: String = "walk"
## Cada zona: o nome e os ossos da articulação (uma lista de listas: o Godot 4.7 esvazia os valores de um Dictionary constante tipado com PackedStringArray).
const JOINTS: Array = [["ombro", "upperarm_l", "upperarm_r"], ["cotovelo", "lowerarm_l", "lowerarm_r"], ["quadril", "thigh_l", "thigh_r"], ["pescoço", "neck_01"]]
const THIGH_RADIUS_M: float = 0.1
const MAX_CROSSING_FRAMES: int = 2
const MAX_BODY_SURFACES: int = 2
const SWORD_SURFACES: int = 1
const SIDES: PackedStringArray = ["_l", "_r"]
const PLAY_TIMES: PackedFloat32Array = [0.1, 0.37, 0.8, 1.2]
const MAX_POSE_DIFFERENCE: float = 0.00001
const CM: float = 100.0

var _failed: bool = false


## Uma superfície com pele: o que as medidas reaproveitam a cada quadro. `feet` marca os vértices da malha dos pés; `zone` e `wide_zone` dizem, por triângulo, a zona de articulação (índice em JOINTS) com o raio de 12 e o de 20 cm, ou -1; `gap` é a distância do triângulo à articulação mais próxima; `worst` guarda o maior esticamento do triângulo no walk.
class Part:
	extends RefCounted
	var skin: Skin
	var arrays: Array
	var feet: PackedByteArray = PackedByteArray()
	var zone: PackedInt32Array = PackedInt32Array()
	var wide_zone: PackedInt32Array = PackedInt32Array()
	var gap: PackedFloat32Array = PackedFloat32Array()
	var worst: PackedFloat32Array = PackedFloat32Array()


func _initialize() -> void:
	_run()


func _run() -> void:
	var dir: String = Writer.OUT_DIR
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with(DIR_ARG):
			dir = argument.trim_prefix(DIR_ARG)
	if not FileAccess.file_exists("%s/%s" % [dir, Writer.SCENE_FILE]):
		print("PULA: figura preparada ausente (fica fora do Git): rode ice_prepare.gd antes")
		quit(0)
		return
	var figure: Node3D = _build(dir)
	if figure == null:
		quit(1)
		return
	root.add_child(figure)
	await process_frame
	var lines: PackedStringArray = PackedStringArray(["critério | medido | limite | resultado"])
	lines.append_array(_skin(figure))
	lines.append_array(_blade(figure))
	lines.append_array(_surfaces(figure))
	lines.append_array(await _determinism(figure, dir))
	for line: String in lines:
		print(line)
	var report: FileAccess = FileAccess.open("%s/%s%s.txt" % [dir, REPORT_FILE.get_basename(), Writer.variant_suffix(Writer.meta_file())], FileAccess.WRITE)
	if report != null:
		report.store_string("\n".join(lines) + "\n")
	quit(1 if _failed else 0)


func _build(dir: String) -> Node3D:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CharacterCatalog.DEFAULT_PATH))
	data["figures"] = [{"id": FIGURE_ID, "scene": "%s/%s" % [dir, Writer.SCENE_FILE], "meta": "%s/%s" % [dir, Writer.meta_file()]}]
	var maker: CharacterFigure = CharacterFigure.new()
	var figure: Node3D = maker.build(CharacterCatalog.from_json(JSON.stringify(data), "catalogo_de_medida.json").catalog, FIGURE_ID)
	if figure == null:
		print("FALHA: %s" % maker.failure)
	return figure


func _line(name: String, measured: String, limit: String, passed: bool) -> String:
	_failed = _failed or not passed
	return "%s | %s | %s | %s" % [name, measured, limit, "OK" if passed else "FALHA"]


## (a) e (b): pele em CPU das superfícies com pele a cada quadro do idle e do walk.
func _skin(figure: Node3D) -> PackedStringArray:
	var skeleton: Skeleton3D = CharacterSceneLoader.skeleton_of(figure)
	var player: AnimationPlayer = figure.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	var parts: Array[Part] = _parts(figure, skeleton)
	var sink: Dictionary[String, float] = {}
	var float_up: Dictionary[String, float] = {}
	for key: String in CLIPS:
		var clip: Animation = player.get_animation(key)
		sink[key] = 0.0
		float_up[key] = 0.0
		for frame: int in FRAMES:
			Metrics.pose_at(skeleton, clip, clip.length * frame / FRAMES)
			var low: float = INF
			for part: Part in parts:
				var posed: PackedVector3Array = Metrics.skinned(skeleton, part.skin, part.arrays)
				low = minf(low, Metrics.lowest(posed, part.feet))
				if key == WALK:
					var ratios: PackedFloat32Array = Metrics.stretch(part.arrays[Mesh.ARRAY_VERTEX], posed, part.arrays[Mesh.ARRAY_INDEX])
					for tri: int in ratios.size():
						part.worst[tri] = maxf(part.worst[tri], ratios[tri])
			sink[key] = maxf(sink[key], -low * figure.scale.y)
			float_up[key] = maxf(float_up[key], low * figure.scale.y)
	var lines: PackedStringArray = PackedStringArray()
	for key: String in CLIPS:
		lines.append(_line("(a) pés, ponto mais baixo da malha dos pés, %s" % key, "afunda até %.1f cm, flutua até %.1f cm" % [sink[key] * CM, float_up[key] * CM], "no máximo %.0f cm do chão" % (MAX_FOOT_GAP_M * CM), maxf(sink[key], float_up[key]) <= MAX_FOOT_GAP_M))
	var over: int = 0
	var top: float = 0.0
	var wide_top: float = 0.0
	var nearest_over: float = INF
	var zones: PackedFloat32Array = PackedFloat32Array()
	zones.resize(JOINTS.size())
	var members: PackedInt32Array = PackedInt32Array()
	members.resize(JOINTS.size())
	for part: Part in parts:
		for tri: int in part.worst.size():
			over += 1 if part.worst[tri] > MAX_STRETCH else 0
			top = maxf(top, part.worst[tri])
			nearest_over = minf(nearest_over, part.gap[tri]) if part.worst[tri] > MAX_STRETCH else nearest_over
			wide_top = maxf(wide_top, part.worst[tri]) if part.wide_zone[tri] >= 0 else wide_top
			if part.zone[tri] >= 0:
				zones[part.zone[tri]] = maxf(zones[part.zone[tri]], part.worst[tri])
				members[part.zone[tri]] += 1
	lines.append(_line("(b) triângulos esticados no walk", "%d acima de %.1fx, o máximo %.2fx (o mais próximo de uma articulação: %s)" % [over, MAX_STRETCH, top, "%.1f cm no arquivo" % (nearest_over * CM) if over > 0 else "n/d"], "nenhum acima de %.1fx" % MAX_STRETCH, over == 0))
	var names: PackedStringArray = PackedStringArray()
	var zone_top: float = 0.0
	for index: int in zones.size():
		names.append("%s %.2fx (%d triângulos)" % [JOINTS[index][0], zones[index], members[index]])
		zone_top = maxf(zone_top, zones[index])
	lines.append(_line("(b) esticamento máximo por zona (raio %.0f cm no arquivo)" % (JOINT_RADIUS_M * CM), ", ".join(names), "até %.1fx" % MAX_STRETCH, zone_top <= MAX_STRETCH))
	lines.append(_line("(b) esticamento máximo nas zonas ampliadas (raio %.0f cm no arquivo)" % (WIDE_JOINT_RADIUS_M * CM), "%.2fx" % wide_top, "até %.1fx" % MAX_STRETCH, wide_top <= MAX_STRETCH))
	return lines


## As superfícies com pele, com a malha dos pés e as zonas de articulação marcadas no bind (a pose em que a figura nasce).
func _parts(figure: Node3D, skeleton: Skeleton3D) -> Array[Part]:
	var parts: Array[Part] = []
	var centers: Array[PackedVector3Array] = []
	for joint: Array in JOINTS:
		var origins: PackedVector3Array = PackedVector3Array()
		for bone_name: String in joint.slice(1):
			origins.append(skeleton.get_bone_global_pose(skeleton.find_bone(bone_name)).origin)
		centers.append(origins)
	for mesh: MeshInstance3D in CharacterSceneLoader.meshes_of(figure):
		if mesh.skin == null:
			continue
		for index: int in mesh.mesh.get_surface_count():
			var part: Part = Part.new()
			part.skin = mesh.skin
			part.arrays = mesh.mesh.surface_get_arrays(index)
			var vertices: PackedVector3Array = part.arrays[Mesh.ARRAY_VERTEX]
			var bones: PackedInt32Array = part.arrays[Mesh.ARRAY_BONES]
			var weights: PackedFloat32Array = part.arrays[Mesh.ARRAY_WEIGHTS]
			part.feet.resize(vertices.size())
			for vertex: int in vertices.size():
				var foot: float = 0.0
				for slot: int in Metrics.SLOTS:
					foot += weights[vertex * Metrics.SLOTS + slot] if FOOT_BONES.has(mesh.skin.get_bind_name(bones[vertex * Metrics.SLOTS + slot])) else 0.0
				part.feet[vertex] = 1 if foot >= FOOT_WEIGHT else 0
			var indices: PackedInt32Array = part.arrays[Mesh.ARRAY_INDEX]
			for first: int in range(0, indices.size(), Metrics.TRI):
				var center: Vector3 = (vertices[indices[first]] + vertices[indices[first + 1]] + vertices[indices[first + 2]]) / float(Metrics.TRI)
				var found: int = -1
				var wide: int = -1
				var gap: float = INF
				for zone: int in centers.size():
					for origin: Vector3 in centers[zone]:
						var distance: float = center.distance_to(origin)
						gap = minf(gap, distance)
						found = zone if distance < JOINT_RADIUS_M else found
						wide = zone if distance < WIDE_JOINT_RADIUS_M else wide
				part.zone.append(found)
				part.wide_zone.append(wide)
				part.gap.append(gap)
				part.worst.append(0.0)
			parts.append(part)
	return parts


## (c): em quantos dos FRAMES quadros do walk o eixo da espada chega a menos de THIGH_RADIUS_M de uma coxa, e a menor distância. Sem espada separada (figura da 6c), não há o que medir.
func _blade(figure: Node3D) -> PackedStringArray:
	var carriers: Array[Node] = figure.find_children("*", "BoneAttachment3D", true, false)
	if carriers.is_empty():
		return PackedStringArray(["(c) lâmina x coxa | espada não separada | n/d | n/d"])
	var skeleton: Skeleton3D = CharacterSceneLoader.skeleton_of(figure)
	var hand: int = skeleton.find_bone((carriers[0] as BoneAttachment3D).bone_name)
	var holder: MeshInstance3D = carriers[0].get_child(0) as MeshInstance3D
	var points: PackedVector3Array = holder.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var ends: PackedVector3Array = Metrics.blade_ends(points, holder.transform.affine_inverse().origin)
	var walk: Animation = (figure.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer).get_animation("walk")
	var crossing: int = 0
	var closest: float = INF
	var closest_vertex: float = INF
	var lowest_tip: float = INF
	for frame: int in FRAMES:
		Metrics.pose_at(skeleton, walk, walk.length * frame / FRAMES)
		var carried: Transform3D = skeleton.get_bone_global_pose(hand) * holder.transform
		var nearest: float = INF
		var nearest_vertex: float = INF
		for side: String in SIDES:
			var hip: Vector3 = skeleton.get_bone_global_pose(skeleton.find_bone("thigh" + side)).origin
			var knee: Vector3 = skeleton.get_bone_global_pose(skeleton.find_bone("calf" + side)).origin
			nearest = minf(nearest, Metrics.segment_distance(carried * ends[0], carried * ends[1], hip, knee) * figure.scale.y)
			for point: Vector3 in points:
				nearest_vertex = minf(nearest_vertex, Metrics.segment_distance(carried * point, carried * point, hip, knee) * figure.scale.y)
		closest = minf(closest, nearest)
		closest_vertex = minf(closest_vertex, nearest_vertex)
		lowest_tip = minf(lowest_tip, (carried * ends[1]).y * figure.scale.y)
		crossing += 1 if nearest_vertex < THIGH_RADIUS_M else 0
	return PackedStringArray([_line("(c) lâmina x coxa (raio %.0f cm), quadros do walk com cruzamento" % (THIGH_RADIUS_M * CM), "%d de %d (menor distância de qualquer vértice da lâmina ao eixo da coxa %.1f cm, do eixo da lâmina %.1f cm; a ponta da espada chega a %.1f cm do chão)" % [crossing, FRAMES, closest_vertex * CM, closest * CM, lowest_tip * CM], "no máximo %d" % MAX_CROSSING_FRAMES, crossing <= MAX_CROSSING_FRAMES)])


## (d): superfícies do corpo (malhas com pele) e da espada (malha sem pele).
func _surfaces(figure: Node3D) -> PackedStringArray:
	var body: int = 0
	var sword: int = 0
	for mesh: MeshInstance3D in CharacterSceneLoader.meshes_of(figure):
		if mesh.skin == null:
			sword += mesh.mesh.get_surface_count()
		else:
			body += mesh.mesh.get_surface_count()
	return PackedStringArray([_line("(d) superfícies do corpo e da espada", "corpo %d, espada %d" % [body, sword], "corpo até %d, espada %d" % [MAX_BODY_SURFACES, SWORD_SURFACES], body <= MAX_BODY_SURFACES and sword == SWORD_SURFACES)])


## (e): as poses dos 65 ossos, no idle e no walk em PLAY_TIMES, da figura, de um `build` repetido e de `duplicate()` (todas pelo `AnimationPlayer`), e da amostragem direta contra o player; a maior diferença (posição em m, eixos da base).
func _determinism(figure: Node3D, dir: String) -> PackedStringArray:
	var again: Node3D = _build(dir)
	var copy: Node3D = figure.duplicate()
	root.add_child(again)
	root.add_child(copy)
	await process_frame
	var worst: float = 0.0
	var direct: float = 0.0
	var skeleton: Skeleton3D = CharacterSceneLoader.skeleton_of(figure)
	for key: String in CLIPS:
		var clip: Animation = (figure.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer).get_animation(key)
		for time: float in PLAY_TIMES:
			var base: Array[Transform3D] = _played(figure, key, time)
			worst = maxf(worst, maxf(_apart(base, _played(again, key, time)), _apart(base, _played(copy, key, time))))
			Metrics.pose_at(skeleton, clip, time)
			direct = maxf(direct, _apart(base, _poses(skeleton)))
	again.free()
	copy.free()
	return PackedStringArray([_line("(e) determinismo: build repetido e duplicate(), e amostragem direta x AnimationPlayer", "diferença máxima %.6f e %.6f" % [worst, direct], "até %.5f" % MAX_POSE_DIFFERENCE, maxf(worst, direct) <= MAX_POSE_DIFFERENCE)])


func _played(figure: Node3D, key: String, time: float) -> Array[Transform3D]:
	var player: AnimationPlayer = figure.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	player.stop()
	player.play(key)
	player.advance(time)
	var skeleton: Skeleton3D = CharacterSceneLoader.skeleton_of(figure)
	skeleton.force_update_all_bone_transforms()
	return _poses(skeleton)


func _poses(skeleton: Skeleton3D) -> Array[Transform3D]:
	var poses: Array[Transform3D] = []
	for bone: int in skeleton.get_bone_count():
		poses.append(skeleton.get_bone_global_pose(bone))
	return poses


func _apart(first: Array[Transform3D], second: Array[Transform3D]) -> float:
	var worst: float = 0.0
	for bone: int in first.size():
		worst = maxf(worst, first[bone].origin.distance_to(second[bone].origin))
		worst = maxf(worst, maxf((first[bone].basis.x - second[bone].basis.x).length(), maxf((first[bone].basis.y - second[bone].basis.y).length(), (first[bone].basis.z - second[bone].basis.z).length())))
	return worst
