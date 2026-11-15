extends GutTest
## ART-12, entrega 4a: o retarget global (CharacterRetarget) com a UAL e os esqueletos REAIS, sem janela: a biblioteca tem um clipe por chave do catálogo (sem `_Loop`), uma trilha de rotação por osso e a de translação da pélvis apontando para o "Skeleton3D" montado, mantém o laço, e a razão da perna sai da diferença real dos esqueletos. Arquivo ou animação ausente devolve null, sem erro.

const BONES: int = 65
const CLIPS: Array[String] = ["idle", "interact", "jog", "pick_up", "talk", "walk"]
const ANIMATIONS: String = "res://assets/characters/quaternius/animations/UAL1_Standard_Subset.glb"
## Medido nos ativos: perna (pélvis a pé) de 0,8626 m (homem) e 0,8611 m (mulher) sobre 0,8130 m da UAL.
const LEG_RATIO_MIN: float = 1.05
const LEG_RATIO_MAX: float = 1.07

var _catalog: CharacterCatalog = CharacterCatalog.from_file().catalog


func _skeleton_for(body: String, outfit: String) -> Skeleton3D:
	var look: CharacterAppearance = CharacterAppearance.new()
	look.body_id = body
	look.outfit_id = outfit
	var assembler: CharacterAssembler = autofree(CharacterAssembler.new())
	assert_true(assembler.build(look, _catalog), "montou " + outfit)
	return CharacterSceneLoader.skeleton_of(assembler)


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


func test_a_missing_file_or_animation_gives_null_without_error() -> void:
	var skeleton: Skeleton3D = _skeleton_for("female_a", "peasant_f")
	assert_null(CharacterRetarget.library_for(skeleton, {"idle": {"path": "res://assets/nao_existe.glb", "name": "Idle"}}), "arquivo ausente")
	assert_null(CharacterRetarget.library_for(skeleton, {"idle": {"path": ANIMATIONS, "name": "No_Such_Clip"}}), "animação ausente")
	assert_not_null(CharacterRetarget.library_for(skeleton, {}), "sem clipes: biblioteca vazia")
