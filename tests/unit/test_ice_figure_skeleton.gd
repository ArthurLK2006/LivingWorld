extends GutTest
## ART-12, entrega 6c-ii: o esqueleto do Ice Warrior (os 65 ossos, a hierarquia e o repouso em T do male_a; articulações medidas no arranjo de bind, lado esquerdo em +X) e a tabela de articulações. Não precisa do ativo: só usa o corpo male_a do repositório.

const Skel = preload("res://tools/visual/ice_figure/ice_skeleton.gd")
const BONES: int = 65
const TOLERANCE: float = 0.00001
const HEAD_TIP_M: float = 0.21
const MIN_MEASURED_BONES: int = 14
const SIDED_BONES: int = 58

var _rig: Skel.Rig
var _male: Skeleton3D
var _assembler: CharacterAssembler
var _landmarks: Dictionary


func before_all() -> void:
	var catalog: CharacterCatalog = CharacterCatalog.from_file().catalog
	_landmarks = Skel.load_landmarks()
	_rig = Skel.build(catalog, _landmarks)
	var look: CharacterAppearance = CharacterAppearance.new()
	look.body_id = Skel.BODY_ID
	look.outfit_id = Skel.OUTFIT_ID
	_assembler = CharacterAssembler.new()
	_assembler.build(look, catalog)
	_male = CharacterSceneLoader.skeleton_of(_assembler)


func after_all() -> void:
	_rig.skeleton.free()
	_assembler.free()


func test_same_bones_hierarchy_and_t_rest_as_the_male_body() -> void:
	assert_eq([_rig.skeleton.get_bone_count(), _male.get_bone_count()], [BONES, BONES])
	var wrong: PackedStringArray = PackedStringArray()
	for bone: int in BONES:
		if _rig.skeleton.get_bone_name(bone) != _male.get_bone_name(bone) or _rig.skeleton.get_bone_parent(bone) != _male.get_bone_parent(bone):
			wrong.append("%d: nome ou pai" % bone)
		elif not _rig.skeleton.get_bone_rest(bone).basis.is_equal_approx(_male.get_bone_rest(bone).basis):
			wrong.append("%s: o repouso não é o T do male_a" % _rig.skeleton.get_bone_name(bone))
	assert_eq(wrong, PackedStringArray())


func test_bind_origins_are_the_measured_landmarks_and_the_right_side_mirrors() -> void:
	var measured: int = 0
	for group: String in ["center", "side"]:
		for key: String in (_landmarks[group] as Dictionary):
			var left: Vector3 = Skel.vec(_landmarks[group][key]) * Skel.CM
			var names: Dictionary[String, Vector3] = {}
			if group == "center":
				names[key] = left
			else:
				names[key + Skel.LEFT] = left
				names[key + Skel.RIGHT] = Vector3(-left.x, left.y, left.z)
			for bone_name: String in names:
				if _rig.skeleton.find_bone(bone_name) >= 0:
					measured += 1
					assert_lt(_rig.origin(bone_name).distance_to(names[bone_name]), TOLERANCE, bone_name)
	assert_gt(measured, MIN_MEASURED_BONES)


## Independe do conteúdo do JSON: o lado vem só do nome (`_l` em +X, `_r` em -X, como no male_a do jogo), então trocar o sinal do x de uma articulação na tabela reprova aqui.
func test_left_bones_sit_at_positive_x_and_right_bones_at_negative_x_like_in_the_male_body() -> void:
	var sided: int = 0
	for bone: int in BONES:
		var side: String = Skel.side_suffix(_rig.skeleton.get_bone_name(bone))
		if side.is_empty():
			continue
		sided += 1
		var direction: float = 1.0 if side == Skel.LEFT else -1.0
		assert_gt(_rig.bind[bone].origin.x * direction, 0.0, "%s no arranjo de bind" % _rig.skeleton.get_bone_name(bone))
		assert_gt(_male.get_bone_global_rest(bone).origin.x * direction, 0.0, "%s no male_a do jogo" % _rig.skeleton.get_bone_name(bone))
	assert_eq(sided, SIDED_BONES)


func test_rest_offsets_compose_to_the_bind_origins_and_locals_rebuild_the_bind() -> void:
	var rebuilt: Array[Transform3D] = []
	for bone: int in BONES:
		var parent: int = _rig.skeleton.get_bone_parent(bone)
		var parent_bind: Transform3D = Transform3D.IDENTITY if parent < 0 else _rig.bind[parent]
		var by_rest: Vector3 = parent_bind.origin + parent_bind.basis * _rig.skeleton.get_bone_rest(bone).origin
		assert_lt(by_rest.distance_to(_rig.bind[bone].origin), TOLERANCE, _rig.skeleton.get_bone_name(bone))
		rebuilt.append(_rig.bind_local(bone) if parent < 0 else rebuilt[parent] * _rig.bind_local(bone))
		assert_lt(rebuilt[bone].origin.distance_to(_rig.bind[bone].origin), TOLERANCE)
		assert_true(rebuilt[bone].basis.is_equal_approx(_rig.bind[bone].basis))


func test_tips_and_axis_children_resolve() -> void:
	assert_lt(_rig.tips["Head"].distance_to(_rig.origin("Head") + Vector3(0.0, HEAD_TIP_M, 0.0)), TOLERANCE)
	assert_lt(_rig.tips["hand_r"].distance_to(Vector3(-0.32, 0.68, 0.005)), TOLERANCE)
	for bone: int in BONES:
		var bone_name: String = _rig.skeleton.get_bone_name(bone)
		var side: String = Skel.side_suffix(bone_name)
		var base: String = bone_name.trim_suffix(side)
		if _rig.axis_child.has(base):
			var child: String = _rig.axis_child[base]
			assert_gte(_rig.skeleton.find_bone((Skel.MIDDLE_FINGER if child == Skel.TIP else child) + side), 0, "filho do eixo de " + bone_name)
