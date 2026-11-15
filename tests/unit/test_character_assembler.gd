extends GutTest
## ART-12, entrega 4a: o CharacterAssembler com os ativos REAIS e o catálogo real (sem janela). Homem e mulher, Peasant e Ranger montam sobre UM esqueleto de 65 ossos com toda malha ligada a ele; origem nos pés e escala pela ficha; idle e walk tocam em laço e a pose muda; os pés não afundam (osso do pé em coordenadas globais); a troca de peça em tempo de execução mantém esqueleto e animação; falhas devolvem falso sem erro e sem deixar nada; nenhum nó órfão. O tempo avança por `AnimationPlayer.advance`, sem esperar quadros.

const BONES: int = 65
const OUTFITS: String = "res://assets/characters/quaternius/outfits/"
const ANIMATIONS: String = "res://assets/characters/quaternius/animations/UAL1_Standard_Subset.glb"
## Corpo, roupa, cabelo e sobrancelha de cada combinação.
const MALE_PEASANT: Array = ["male_a", "peasant_m", "buzzed", "brow_regular"]
const FEMALE_PEASANT: Array = ["female_a", "peasant_f", "long", "brow_female"]
const MALE_RANGER: Array = ["male_a", "ranger_m", "simple_parted", "brow_regular"]
const FEMALE_RANGER: Array = ["female_a", "ranger_f", "buns", "brow_female"]
## Malhas esperadas: Peasant = rosto, olhos, tronco, braços, calça, botas, cabelo e sobrancelha; Ranger = Peasant + capuz, ombreira, braçadeira e 2 cintos.
const PEASANT_MESHES: int = 8
const RANGER_MESHES: int = 13
const FOOT_TOLERANCE_M: float = 0.02
const CYCLE_SAMPLES: int = 40
const CYCLE_STEP_S: float = 0.0625

var _catalog: CharacterCatalog


func before_all() -> void:
	var loaded: CharacterCatalog.LoadResult = CharacterCatalog.from_file()
	assert_true(loaded.result.ok, loaded.result.message)
	_catalog = loaded.catalog


## O montador lê o gênero do corpo no catálogo: a ficha de teste só precisa dos ids.
func _look(combo: Array, permille: int = 1000) -> CharacterAppearance:
	var look: CharacterAppearance = CharacterAppearance.new()
	look.body_id = combo[0]
	look.outfit_id = combo[1]
	look.hair_id = combo[2]
	look.eyebrow_id = combo[3]
	look.scale_permille = permille
	return look


func _built(combo: Array, permille: int = 1000) -> CharacterAssembler:
	var assembler: CharacterAssembler = add_child_autofree(CharacterAssembler.new())
	assert_true(assembler.build(_look(combo, permille), _catalog), "montou " + str(combo))
	return assembler


func _player(assembler: CharacterAssembler) -> AnimationPlayer:
	return assembler.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer


func _at(skeleton: Skeleton3D, bone_name: String) -> Vector3:
	skeleton.force_update_all_bone_transforms()
	return skeleton.get_bone_global_pose(skeleton.find_bone(bone_name)).origin


## Altura do osso sobre a que ele tem no repouso, em que a sola está no chão.
func _lift(skeleton: Skeleton3D, bone_name: String) -> float:
	return _at(skeleton, bone_name).y - skeleton.get_bone_global_rest(skeleton.find_bone(bone_name)).origin.y


func _bounds(assembler: CharacterAssembler) -> AABB:
	var meshes: Array[MeshInstance3D] = CharacterSceneLoader.meshes_of(assembler)
	var box: AABB = meshes[0].global_transform * meshes[0].mesh.get_aabb()
	for mesh: MeshInstance3D in meshes:
		box = box.merge(mesh.global_transform * mesh.mesh.get_aabb())
	return box


func test_four_looks_share_one_65_bone_skeleton_with_every_mesh_bound_to_it() -> void:
	for combo: Array in [MALE_PEASANT, FEMALE_PEASANT, MALE_RANGER, FEMALE_RANGER]:
		var assembler: CharacterAssembler = _built(combo)
		var skeleton: Skeleton3D = CharacterSceneLoader.skeleton_of(assembler)
		var meshes: Array[MeshInstance3D] = CharacterSceneLoader.meshes_of(assembler)
		assert_eq(assembler.find_children("*", "Skeleton3D", true, false).size(), 1, "um esqueleto só: " + str(combo[1]))
		assert_eq(skeleton.get_bone_count(), BONES, "ossos: " + str(combo[1]))
		assert_true(skeleton.transform.is_equal_approx(Transform3D.IDENTITY), "esqueleto na identidade")
		assert_eq(meshes.size(), PEASANT_MESHES if String(combo[1]).begins_with("peasant") else RANGER_MESHES, "malhas: " + str(combo[1]))
		for mesh: MeshInstance3D in meshes:
			assert_true(mesh.get_parent() == skeleton and mesh.get_node(mesh.skeleton) == skeleton and mesh.skin != null, "malha ligada ao esqueleto e com pele: " + str(mesh.name))
		assert_false(assembler.is_playing(), "montar não começa a tocar sozinho")
		assert_eq(assembler.current_clip(), "")


func test_the_shared_skeleton_has_the_rest_pose_of_the_outfit_not_of_the_male_base_head() -> void:
	var skeleton: Skeleton3D = CharacterSceneLoader.skeleton_of(_built(MALE_PEASANT))
	var outfit: Node = CharacterSceneLoader.instantiate(OUTFITS + "Male_Peasant_Legs.glb")
	var reference: Skeleton3D = CharacterSceneLoader.skeleton_of(outfit)
	for bone: int in BONES:
		assert_true(skeleton.get_bone_rest(bone).is_equal_approx(reference.get_bone_rest(bone)), "repouso do osso " + skeleton.get_bone_name(bone))
	outfit.free()


func test_origin_is_at_the_feet_and_scale_permille_scales_the_height_proportionally() -> void:
	var tops: Array[float] = []
	for permille: int in [960, 1000, 1040]:
		var box: AABB = _bounds(_built(MALE_PEASANT, permille))
		assert_lt(absf(box.position.y), FOOT_TOLERANCE_M, "a base da caixa fica a menos de 2 cm de y = 0 (permille %d)" % permille)
		tops.append(box.end.y)
	assert_almost_eq(tops[0] / tops[1], 0.96, 0.001, "960 milésimos")
	assert_almost_eq(tops[2] / tops[1], 1.04, 0.001, "1040 milésimos")
	assert_eq(_built(MALE_PEASANT, 0).scale, Vector3.ONE, "escala inválida na ficha cai na neutra")


func test_idle_and_walk_play_in_a_loop_and_the_pose_changes_between_two_instants() -> void:
	var assembler: CharacterAssembler = _built(MALE_PEASANT)
	var skeleton: Skeleton3D = CharacterSceneLoader.skeleton_of(assembler)
	var player: AnimationPlayer = _player(assembler)
	for clip: String in ["idle", "walk"]:
		assert_true(assembler.play(clip), clip)
		assert_true(assembler.is_playing())
		assert_eq(assembler.current_clip(), clip)
		assert_ne(player.get_animation(clip).loop_mode, Animation.LOOP_NONE, clip + " em laço")
		player.advance(0.01)
		var start: float = player.current_animation_position
		assert_true(assembler.play(clip))
		assert_eq(player.current_animation_position, start, clip + ": tocar de novo o mesmo clipe não reinicia")
		var hand_start: Vector3 = _at(skeleton, "hand_l")
		player.advance(0.6)
		assert_gt(player.current_animation_position, start, clip + ": a posição da animação avança")
		assert_gt(_at(skeleton, "hand_l").distance_to(hand_start), 0.01, clip + ": a pose muda")
		player.advance(player.get_animation(clip).length)
		assert_true(assembler.is_playing(), clip + ": passou do fim e continua tocando")
	assert_false(assembler.play("no_such_clip"), "chave desconhecida")
	assert_eq(assembler.current_clip(), "walk", "e a animação atual não muda")


func test_feet_stay_within_2_cm_of_the_ground_in_idle_and_never_sink_in_walk_for_both_genders() -> void:
	for combo: Array in [MALE_PEASANT, FEMALE_PEASANT]:
		var assembler: CharacterAssembler = _built(combo)
		var skeleton: Skeleton3D = CharacterSceneLoader.skeleton_of(assembler)
		var player: AnimationPlayer = _player(assembler)
		assembler.play("idle")
		for sample: int in CYCLE_SAMPLES:
			player.advance(CYCLE_STEP_S)
			for foot: String in ["foot_l", "foot_r"]:
				assert_lt(absf(_lift(skeleton, foot)), FOOT_TOLERANCE_M, "%s idle %s (amostra %d)" % [combo[1], foot, sample])
		assembler.play("walk")
		var highest: float = 0.0
		for sample: int in CYCLE_SAMPLES:
			player.advance(CYCLE_STEP_S)
			var left: float = _lift(skeleton, "foot_l")
			var right: float = _lift(skeleton, "foot_r")
			assert_gt(minf(left, right), -FOOT_TOLERANCE_M, "%s walk: o pé mais baixo afunda (amostra %d)" % [combo[1], sample])
			highest = maxf(highest, maxf(left, right))
		assert_gt(highest, 0.1, combo[1] + ": no passo o pé sai do chão")


func test_swapping_a_part_at_runtime_keeps_the_skeleton_the_bones_and_the_animation() -> void:
	var assembler: CharacterAssembler = _built(MALE_PEASANT)
	var skeleton: Skeleton3D = CharacterSceneLoader.skeleton_of(assembler)
	var player: AnimationPlayer = _player(assembler)
	assembler.play("walk")
	player.advance(0.3)
	var before: float = player.current_animation_position
	assert_true(assembler.swap_part(CharacterAssembler.SLOT_TORSO, OUTFITS + "Male_Ranger_Body_Arms.glb"))
	assert_same(CharacterSceneLoader.skeleton_of(assembler), skeleton, "o esqueleto é o mesmo")
	assert_same(_player(assembler), player, "o AnimationPlayer é o mesmo")
	assert_eq(skeleton.get_bone_count(), BONES)
	assert_eq([assembler.is_playing(), assembler.current_clip(), player.current_animation_position], [true, "walk", before], "a troca não reinicia a animação")
	player.advance(0.1)
	assert_gt(player.current_animation_position, before, "e ela segue andando")
	var meshes: Array[MeshInstance3D] = CharacterSceneLoader.meshes_of(assembler)
	assert_eq(meshes.size(), PEASANT_MESHES, "mesmo número de malhas")
	for mesh: MeshInstance3D in meshes:
		assert_true(mesh.get_parent() == skeleton and mesh.skin != null, "toda malha segue ligada: " + str(mesh.name))
	assert_true(assembler.swap_part(CharacterAssembler.SLOT_HAIR, ""), "caminho vazio tira a peça")
	assert_eq(CharacterSceneLoader.meshes_of(assembler).size(), PEASANT_MESHES - 1)
	assert_true(assembler.swap_part(CharacterAssembler.SLOT_HAIR, "res://assets/characters/quaternius/hair/Hair_SimpleParted.glb"))
	assert_eq(CharacterSceneLoader.meshes_of(assembler).size(), PEASANT_MESHES)
	for bad_path: String in [OUTFITS + "Missing_Legs.glb", ANIMATIONS]:
		assert_false(assembler.swap_part(CharacterAssembler.SLOT_LEGS, bad_path), "peça inexistente ou sem malha: " + bad_path)
	assert_eq(CharacterSceneLoader.meshes_of(assembler).size(), PEASANT_MESHES, "a falha deixa a peça atual")
	var empty: CharacterAssembler = autofree(CharacterAssembler.new())
	assert_false(empty.swap_part(CharacterAssembler.SLOT_HAIR, ANIMATIONS), "sem personagem montado não há o que trocar")


func test_incomplete_requests_fail_with_false_and_leave_nothing_behind() -> void:
	var assembler: CharacterAssembler = add_child_autofree(CharacterAssembler.new())
	var unknown_outfit: Array = [MALE_PEASANT[0], "no_such_outfit", MALE_PEASANT[2], MALE_PEASANT[3]]
	var unknown_hair: Array = [MALE_PEASANT[0], MALE_PEASANT[1], "no_such_hair", MALE_PEASANT[3]]
	var unknown_eyebrow: Array = [MALE_PEASANT[0], MALE_PEASANT[1], MALE_PEASANT[2], "no_such_brow"]
	assert_false(assembler.build(CharacterAppearance.new(), _catalog), "ficha vazia")
	assert_false(assembler.build(null, _catalog), "sem ficha")
	assert_false(assembler.build(_look(MALE_PEASANT), null), "sem catálogo")
	for combo: Array in [unknown_outfit, unknown_hair, unknown_eyebrow]:
		assert_false(assembler.build(_look(combo), _catalog), "peça fora do catálogo: " + str(combo))
	var text: String = FileAccess.get_file_as_string(CharacterCatalog.DEFAULT_PATH).replace("Male_Peasant_Legs.glb", "Missing_Legs.glb")
	var missing_file: CharacterCatalog = CharacterCatalog.from_json(text, "teste", func(_path: String) -> bool: return true).catalog
	assert_false(assembler.build(_look(MALE_PEASANT), missing_file), "peça do catálogo ausente em res://")
	assert_eq(assembler.get_child_count(), 0, "nada pela metade")
	assert_true(assembler.build(_look(MALE_PEASANT), _catalog))
	var skeleton: Skeleton3D = CharacterSceneLoader.skeleton_of(assembler)
	assert_false(assembler.build(_look(MALE_PEASANT), missing_file), "remontagem que falha")
	assert_same(CharacterSceneLoader.skeleton_of(assembler), skeleton, "mantém o personagem anterior")
	assert_true(assembler.play("idle"))


func test_every_path_frees_everything_and_leaves_no_orphan_nodes() -> void:
	var orphans_before: int = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	var loose: CharacterAssembler = CharacterAssembler.new()
	assert_true(loose.build(_look(MALE_RANGER), _catalog))
	assert_true(loose.build(_look(FEMALE_PEASANT), _catalog), "remontar libera o anterior")
	assert_true(loose.swap_part(CharacterAssembler.SLOT_BOOTS, OUTFITS + "Female_Ranger_Feet.glb"))
	assert_false(loose.swap_part(CharacterAssembler.SLOT_BOOTS, ANIMATIONS))
	assert_false(loose.build(CharacterAppearance.new(), _catalog))
	loose.clear()
	assert_eq(loose.get_child_count(), 0, "clear() desmonta tudo")
	assert_true(loose.build(_look(MALE_RANGER), _catalog))
	loose.free()
	assert_eq(int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)), orphans_before, "free() não deixa órfão")
	var in_tree: CharacterAssembler = _built(FEMALE_RANGER)
	in_tree.queue_free()
	await wait_process_frames(2)
	assert_eq(int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)), orphans_before, "queue_free() não deixa órfão")
