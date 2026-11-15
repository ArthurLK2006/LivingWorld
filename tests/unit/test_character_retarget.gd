extends GutTest
## ART-12, entrega 4a: o retarget global (CharacterRetarget) com a UAL e os esqueletos REAIS, sem janela: a biblioteca tem um clipe por chave do catálogo (sem `_Loop`), uma trilha de rotação por osso e a de translação da pélvis apontando para o "Skeleton3D" montado, mantém o laço, e a razão da perna sai da diferença real dos esqueletos. A 1ª chave da pélvis, no clipe do próprio montador (prova que `build` retargeta para o esqueleto do corpo, não de outro gênero), é o repouso do corpo mais o deslocamento da UAL x a razão da perna; o repouso LOCAL da UAL dá o repouso local do corpo (nos dois gêneros); uma coxa girada gira o corpo pelo mesmo delta MUNDIAL em relação ao repouso. Arquivo ou animação ausente devolve null, sem erro.

const BONES: int = 65
const BODIES: Array = [["male_a", "peasant_m"], ["female_a", "peasant_f"]]
const CLIPS: Array[String] = ["idle", "interact", "jog", "pick_up", "talk", "walk"]
const ANIMATIONS: String = "res://assets/characters/quaternius/animations/UAL1_Standard_Subset.glb"
## Medido nos ativos: perna (pélvis a pé) de 0,8626 m (homem) e 0,8611 m (mulher) sobre 0,8130 m da UAL.
const LEG_RATIO_MIN: float = 1.05
const LEG_RATIO_MAX: float = 1.07

var _catalog: CharacterCatalog = CharacterCatalog.from_file().catalog


func _assembled(body: String, outfit: String) -> CharacterAssembler:
	var look: CharacterAppearance = CharacterAppearance.new()
	look.body_id = body
	look.outfit_id = outfit
	var assembler: CharacterAssembler = autofree(CharacterAssembler.new())
	assert_true(assembler.build(look, _catalog), "montou " + outfit)
	return assembler


func _skeleton_for(body: String, outfit: String) -> Skeleton3D:
	return CharacterSceneLoader.skeleton_of(_assembled(body, outfit))


## O valor da 1ª chave da trilha de translação do osso (a trilha da UAL leva o caminho do arquivo, então se acha pelo nome do osso).
func _first_position(clip: Animation, bone_name: String) -> Vector3:
	for track: int in clip.get_track_count():
		if clip.track_get_type(track) == Animation.TYPE_POSITION_3D and clip.track_get_path(track).get_concatenated_subnames() == bone_name:
			return clip.track_get_key_value(track, 0)
	return Vector3.INF


## Retargeta um clipe de 1 quadro com a pose atual da UAL e põe a 1ª chave de cada rotação na pose de `skeleton`.
func _pose_like(ual: Skeleton3D, skeleton: Skeleton3D) -> void:
	var clip: Animation = Animation.new()
	for bone: int in ual.get_bone_count():
		var track: int = clip.add_track(Animation.TYPE_ROTATION_3D)
		clip.track_set_path(track, NodePath("Skeleton3D:" + ual.get_bone_name(bone)))
		clip.rotation_track_insert_key(track, 0.0, ual.get_bone_pose_rotation(bone))
	var out: Animation = CharacterRetarget.new(ual, skeleton).retarget(clip)
	for track: int in out.get_track_count():
		skeleton.set_bone_pose_rotation(skeleton.find_bone(out.track_get_path(track).get_concatenated_subnames()), out.track_get_key_value(track, 0))
	skeleton.force_update_all_bone_transforms()


## A rotação MUNDIAL que a pose acrescenta ao repouso do osso.
func _delta(skeleton: Skeleton3D, bone: int) -> Quaternion:
	return skeleton.get_bone_global_pose(bone).basis.get_rotation_quaternion() * skeleton.get_bone_global_rest(bone).basis.get_rotation_quaternion().inverse()


## q e -q são a mesma rotação.
func _same(a: Quaternion, b: Quaternion) -> bool:
	return a.is_equal_approx(b) or a.is_equal_approx(-b)


func test_the_library_has_one_looping_clip_per_catalog_key_with_global_tracks_for_every_bone() -> void:
	var skeleton: Skeleton3D = _skeleton_for("male_a", "peasant_m")
	var library: AnimationLibrary = CharacterRetarget.library_for(skeleton, _catalog.animations())
	assert_not_null(library)
	assert_eq(library.get_animation_list().size(), CLIPS.size(), "uma animação por chave do catálogo")
	for key: String in CLIPS:
		assert_true(library.has_animation(key), "chave sem o sufixo _Loop da UAL: " + key)
	for key: String in ["idle", "walk"]:
		var clip: Animation = library.get_animation(key)
		var rotations: int = 0
		var moving: PackedStringArray = PackedStringArray()
		assert_gt(clip.length, 0.0, key)
		assert_ne(clip.loop_mode, Animation.LOOP_NONE, key + " em laço")
		for track: int in clip.get_track_count():
			var path: NodePath = clip.track_get_path(track)
			assert_eq(String(path.get_concatenated_names()), CharacterRetarget.SKELETON_NODE, "a trilha aponta para o esqueleto montado")
			assert_gte(skeleton.find_bone(path.get_concatenated_subnames()), 0, "osso existe: " + String(path.get_concatenated_subnames()))
			if clip.track_get_type(track) == Animation.TYPE_ROTATION_3D:
				rotations += 1
			else:
				moving.append(path.get_concatenated_subnames())
		moving.sort()
		assert_eq(rotations, BONES, key + ": uma rotação por osso")
		assert_eq(",".join(moving), "pelvis", key + ": a UAL só anima a translação da pélvis (a raiz também seria copiada, escalada)")


func test_the_leg_ratio_comes_from_the_real_rest_poses_of_both_genders() -> void:
	for outfit: Array in [["male_a", "peasant_m"], ["female_a", "peasant_f"]]:
		var source: Node = CharacterSceneLoader.instantiate(ANIMATIONS)
		var retarget: CharacterRetarget = CharacterRetarget.new(CharacterSceneLoader.skeleton_of(source), _skeleton_for(outfit[0], outfit[1]))
		assert_between(retarget.leg_ratio, LEG_RATIO_MIN, LEG_RATIO_MAX, "razão da perna: " + str(outfit[0]))
		source.free()


func test_the_first_pelvis_key_is_the_rest_of_the_body_plus_the_ual_offset_scaled_by_the_leg_ratio() -> void:
	var scene: Node = autofree(CharacterSceneLoader.instantiate(ANIMATIONS))
	var ual: Skeleton3D = CharacterSceneLoader.skeleton_of(scene)
	var ual_player: AnimationPlayer = scene.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	for body: Array in BODIES:
		var assembler: CharacterAssembler = _assembled(body[0], body[1])
		var skeleton: Skeleton3D = CharacterSceneLoader.skeleton_of(assembler)
		var clips: AnimationPlayer = assembler.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
		var ratio: float = CharacterRetarget.new(ual, skeleton).leg_ratio
		for key: String in ["idle", "walk"]:
			var offset: Vector3 = _first_position(ual_player.get_animation(StringName(_catalog.animations()[key]["name"])), "pelvis") - ual.get_bone_rest(ual.find_bone("pelvis")).origin
			var expected: Vector3 = skeleton.get_bone_rest(skeleton.find_bone("pelvis")).origin + offset * ratio
			assert_gt(offset.length() * (ratio - 1.0), 0.001, "o deslocamento é grande o bastante para a razão pesar: " + key)
			assert_lt(_first_position(clips.get_animation(key), "pelvis").distance_to(expected), 0.0001, "%s %s: repouso do corpo + deslocamento da UAL x razão da perna (clipe do próprio montador)" % [body[1], key])


func test_the_rest_pose_of_the_ual_retargets_to_the_own_rest_pose_of_each_body() -> void:
	var ual: Skeleton3D = CharacterSceneLoader.skeleton_of(autofree(CharacterSceneLoader.instantiate(ANIMATIONS)))
	ual.reset_bone_poses()
	for body: Array in BODIES:
		var skeleton: Skeleton3D = _skeleton_for(body[0], body[1])
		_pose_like(ual, skeleton)
		for bone: int in skeleton.get_bone_count():
			assert_true(_same(skeleton.get_bone_pose_rotation(bone), skeleton.get_bone_rest(bone).basis.get_rotation_quaternion()), "%s: repouso local de %s" % [body[1], skeleton.get_bone_name(bone)])


func test_a_turned_thigh_of_the_ual_turns_every_bone_of_each_body_by_the_same_world_delta() -> void:
	var ual: Skeleton3D = CharacterSceneLoader.skeleton_of(autofree(CharacterSceneLoader.instantiate(ANIMATIONS)))
	ual.reset_bone_poses()
	var thigh: int = ual.find_bone("thigh_l")
	ual.set_bone_pose_rotation(thigh, ual.get_bone_rest(thigh).basis.get_rotation_quaternion() * Quaternion(Vector3(0.3, 0.5, 0.8).normalized(), 1.0))
	ual.force_update_all_bone_transforms()
	for body: Array in BODIES:
		var skeleton: Skeleton3D = _skeleton_for(body[0], body[1])
		_pose_like(ual, skeleton)
		for bone: int in skeleton.get_bone_count():
			assert_true(_same(_delta(skeleton, bone), _delta(ual, ual.find_bone(skeleton.get_bone_name(bone)))), "%s: delta mundial de %s" % [body[1], skeleton.get_bone_name(bone)])
		assert_gt(_delta(skeleton, skeleton.find_bone("foot_l")).angle_to(Quaternion.IDENTITY), 0.5, body[1] + ": o pé acompanhou a coxa")


func test_a_missing_file_or_animation_gives_null_without_error() -> void:
	var skeleton: Skeleton3D = _skeleton_for("female_a", "peasant_f")
	assert_null(CharacterRetarget.library_for(skeleton, {"idle": {"path": "res://assets/nao_existe.glb", "name": "Idle"}}), "arquivo ausente")
	assert_null(CharacterRetarget.library_for(skeleton, {"idle": {"path": ANIMATIONS, "name": "No_Such_Clip"}}), "animação ausente")
	assert_not_null(CharacterRetarget.library_for(skeleton, {}), "sem clipes: biblioteca vazia")
