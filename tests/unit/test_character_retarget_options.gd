extends GutTest
## ART-12, entrega 6a: as opções do CharacterRetarget (pose de referência, trava de chão e amortecimento) com a UAL real e esqueletos SINTÉTICOS derivados do corpo masculino do repositório (nenhum ativo de terceiros, nada de art_samples/). Tudo desligado: trilhas idênticas às do retarget sem opções (idle e walk, dois corpos). Pose de referência: um destino com bind diferente do repouso reproduz o bind no quadro 0 do idle (posição e rotação dos 65 ossos), os outros quadros andam pelo delta da UAL em relação a esse quadro, e sem o clipe de referência a biblioteca é null. Trava de chão: com a perna 25% mais curta o pé mais baixo afunda sem a opção e fica a no máximo 1 cm da referência com ela, no idle e no walk, com e sem pose de referência. Amortecimento: fator 0 = osso parado, 1 = igual a sem amortecer, 0,4 = 40% do ângulo, fora de 0 a 1 é limitado. A chave de referência escolhe o clipe. Clipe sem trilha da pélvis: a trava a cria. Esqueleto sem ossos de pé: a trava não muda nada. Determinismo.

const ANIMATIONS: String = "res://assets/characters/quaternius/animations/UAL1_Standard_Subset.glb"
const BODIES: Array = [["male_a", "peasant_m"], ["female_a", "peasant_f"]]
const CLIPS: Array[String] = ["idle", "walk"]
const LEG_BONES: PackedStringArray = ["calf_l", "calf_r", "foot_l", "foot_r"]
const LEG_SCALE: float = 0.75
const BIND_AXIS: Vector3 = Vector3(0.3, 0.5, 0.8)
const BIND_TURNS: Dictionary[String, float] = {"upperarm_l": 1.1, "upperarm_r": -0.9, "thigh_l": 0.25, "thigh_r": -0.25, "spine_02": 0.2}
const SAMPLES_PER_SECOND: float = 30.0
const WALK_TIME: float = 0.4
const MOVES: Array = [["idle", IDLE_TIME, MIN_IDLE_MOVE], ["walk", WALK_TIME, MIN_WALK_MOVE]]
const DAMPED_BONE: String = "thigh_l"
const FACTORS: Array[float] = [0.0, 0.4, 1.0]
const SWING_TIMES: Array[float] = [0.2, 0.5, 0.9, 1.2]
## [HIP] 0,01 cm (posição), 1 cm (pé a partir da referência), 0,0001 (parte vetorial do quaternion, cerca de 0,01 grau) e 0,002 rad (ângulo, com o ruído do acos em float).
const POSITION_TOLERANCE_M: float = 0.0001
const GROUND_TOLERANCE_M: float = 0.01
const ROTATION_TOLERANCE: float = 0.0001
const ANGLE_TOLERANCE: float = 0.002
## [HIP] o bind sintético gira o braço ao menos 0,5 rad do repouso, o destino se move ao menos 0,05 (parte vetorial) no walk e 0,002 no idle (um delta pequeno), e a coxa balança ao menos 0,3 rad: o teste só vale com movimento.
const MIN_BIND_TURN: float = 0.5
const MIN_WALK_MOVE: float = 0.05
const MIN_IDLE_MOVE: float = 0.002
const IDLE_TIME: float = 1.0
const MIN_THIGH_SWING: float = 0.3
## [HIP] o afundamento mínimo que o retarget SEM a trava mostra com a perna 25% mais curta (medido: idle 0,42 cm, walk 3,87 cm).
const SINK_M: Dictionary[String, float] = {"idle": 0.003, "walk": 0.01}
const PELVIS_POSITION: NodePath = ^"Skeleton3D:pelvis"
## [HIP] com o walk como referência, o idle fica a pelo menos 0,1 (parte vetorial) do bind no quadro 0 (medido: 0,50).
const MIN_REFERENCE_GAP: float = 0.1

var _catalog: CharacterCatalog = CharacterCatalog.from_file().catalog


func _body(body: String, outfit: String) -> Skeleton3D:
	var look: CharacterAppearance = CharacterAppearance.new()
	look.body_id = body
	look.outfit_id = outfit
	var assembler: CharacterAssembler = add_child_autofree(CharacterAssembler.new())
	assert_true(assembler.build(look, _catalog), "montou " + outfit)
	return CharacterSceneLoader.skeleton_of(assembler)


func _ual() -> Node:
	return add_child_autofree(CharacterSceneLoader.instantiate(ANIMATIONS))


func _source_clip(scene: Node, key: String) -> Animation:
	return (scene.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer).get_animation(StringName(String(_catalog.animations()[key]["name"])))


func _clone(source: Skeleton3D, leg_scale: float) -> Skeleton3D:
	var clone: Skeleton3D = add_child_autofree(Skeleton3D.new())
	for bone: int in source.get_bone_count():
		clone.add_bone(source.get_bone_name(bone))
	for bone: int in source.get_bone_count():
		clone.set_bone_parent(bone, source.get_bone_parent(bone))
		clone.set_bone_rest(bone, source.get_bone_rest(bone))
	var foot: int = clone.find_bone("foot_l")
	var before: float = clone.get_bone_global_rest(foot).origin.y
	for leg_bone: String in LEG_BONES:
		var bone: int = clone.find_bone(leg_bone)
		clone.set_bone_rest(bone, Transform3D(clone.get_bone_rest(bone).basis, clone.get_bone_rest(bone).origin * leg_scale))
	var pelvis: int = clone.find_bone("pelvis")
	var rise: Vector3 = Vector3(0.0, before - clone.get_bone_global_rest(foot).origin.y, 0.0)
	var rest: Transform3D = clone.get_bone_rest(pelvis)
	clone.set_bone_rest(pelvis, Transform3D(rest.basis, rest.origin + clone.get_bone_global_rest(clone.find_bone("root")).basis.inverse() * rise))
	clone.reset_bone_poses()
	return clone


func _rest(skeleton: Skeleton3D) -> Dictionary[String, Transform3D]:
	var rest: Dictionary[String, Transform3D] = {}
	for bone: int in skeleton.get_bone_count():
		rest[skeleton.get_bone_name(bone)] = skeleton.get_bone_global_rest(bone)
	return rest


## A pose de bind sintética: o repouso com alguns ossos girados (mundial, pelo FK do próprio Skeleton3D).
func _bind(skeleton: Skeleton3D) -> Dictionary[String, Transform3D]:
	for bone_name: String in BIND_TURNS:
		var bone: int = skeleton.find_bone(bone_name)
		skeleton.set_bone_pose_rotation(bone, skeleton.get_bone_rest(bone).basis.get_rotation_quaternion() * Quaternion(BIND_AXIS.normalized(), BIND_TURNS[bone_name]))
	skeleton.force_update_all_bone_transforms()
	var bind: Dictionary[String, Transform3D] = {}
	for bone: int in skeleton.get_bone_count():
		bind[skeleton.get_bone_name(bone)] = skeleton.get_bone_global_pose(bone)
	skeleton.reset_bone_poses()
	return bind


func _pose(skeleton: Skeleton3D, clip: Animation, time: float) -> void:
	for track: int in clip.get_track_count():
		var bone: int = skeleton.find_bone(clip.track_get_path(track).get_concatenated_subnames())
		if bone >= 0 and clip.track_get_type(track) == Animation.TYPE_ROTATION_3D:
			skeleton.set_bone_pose_rotation(bone, clip.rotation_track_interpolate(track, time))
		elif bone >= 0 and clip.track_get_type(track) == Animation.TYPE_POSITION_3D:
			skeleton.set_bone_pose_position(bone, clip.position_track_interpolate(track, time))
	skeleton.force_update_all_bone_transforms()


func _worlds(skeleton: Skeleton3D) -> Dictionary[String, Quaternion]:
	var worlds: Dictionary[String, Quaternion] = {}
	for bone: int in skeleton.get_bone_count():
		worlds[skeleton.get_bone_name(bone)] = skeleton.get_bone_global_pose(bone).basis.get_rotation_quaternion()
	return worlds


## A parte vetorial de a x b^-1: 0 se as rotações são a mesma (q e -q também), sem o ruído do acos perto de 0.
func _distance(a: Quaternion, b: Quaternion) -> float:
	var difference: Quaternion = a * b.inverse()
	return Vector3(difference.x, difference.y, difference.z).length()


## Por quadro a 30 por segundo, o desvio do osso do pé mais baixo em relação à altura do mesmo osso em `reference`.
func _gaps(skeleton: Skeleton3D, clip: Animation, reference: Dictionary[String, Transform3D]) -> Array[float]:
	var gaps: Array[float] = []
	for step: int in int(ceil(clip.length * SAMPLES_PER_SECOND)) + 1:
		_pose(skeleton, clip, minf(step / SAMPLES_PER_SECOND, clip.length))
		var gap: float = INF
		for bone_name: String in CharacterRetarget.GROUND_BONES:
			gap = minf(gap, skeleton.get_bone_global_pose(skeleton.find_bone(bone_name)).origin.y - reference[bone_name].origin.y)
		gaps.append(gap)
	return gaps


## (posição, rotação): o maior desvio dos ossos de `bind` no quadro 0 de `clip`, aplicado a `target`.
func _bind_error(target: Skeleton3D, clip: Animation, bind: Dictionary[String, Transform3D]) -> Vector2:
	_pose(target, clip, 0.0)
	var worst: Vector2 = Vector2.ZERO
	for bone_name: String in bind:
		var pose: Transform3D = target.get_bone_global_pose(target.find_bone(bone_name))
		worst.x = maxf(worst.x, pose.origin.distance_to(bind[bone_name].origin))
		worst.y = maxf(worst.y, _distance(pose.basis.get_rotation_quaternion(), bind[bone_name].basis.get_rotation_quaternion()))
	return worst


func _without_positions(clip: Animation) -> Animation:
	var copy: Animation = clip.duplicate() as Animation
	for track: int in range(copy.get_track_count() - 1, -1, -1):
		if copy.track_get_type(track) == Animation.TYPE_POSITION_3D:
			copy.remove_track(track)
	return copy


## Um esqueleto sem os ossos que a trava de chão mede (tornozelo, base e ponta dos dedos), o resto igual a `source`.
func _without_feet(source: Skeleton3D) -> Skeleton3D:
	var clone: Skeleton3D = add_child_autofree(Skeleton3D.new())
	for bone: int in source.get_bone_count():
		if not CharacterRetarget.GROUND_BONES.has(source.get_bone_name(bone)):
			clone.add_bone(source.get_bone_name(bone))
	for bone: int in clone.get_bone_count():
		var original: int = source.find_bone(clone.get_bone_name(bone))
		var parent: int = source.get_bone_parent(original)
		clone.set_bone_parent(bone, -1 if parent < 0 else clone.find_bone(source.get_bone_name(parent)))
		clone.set_bone_rest(bone, source.get_bone_rest(original))
	clone.reset_bone_poses()
	return clone


func _same_clip(a: Animation, b: Animation) -> bool:
	if a.length != b.length or a.loop_mode != b.loop_mode or a.get_track_count() != b.get_track_count():
		return false
	for track: int in a.get_track_count():
		if a.track_get_path(track) != b.track_get_path(track) or a.track_get_type(track) != b.track_get_type(track) or a.track_get_key_count(track) != b.track_get_key_count(track):
			return false
		for key: int in a.track_get_key_count(track):
			if a.track_get_key_time(track, key) != b.track_get_key_time(track, key) or a.track_get_key_value(track, key) != b.track_get_key_value(track, key):
				return false
	return true


## (erro, movimento) em `time` de `key`: o maior desvio entre os ossos do delta mundial do destino (sobre o bind) contra o da UAL (o mesmo quadro contra o quadro 0 do idle), e o maior delta que o destino fez.
func _delta_check(scene: Node, target: Skeleton3D, library: AnimationLibrary, bind: Dictionary[String, Transform3D], key: String, time: float) -> Vector2:
	var ual: Skeleton3D = CharacterSceneLoader.skeleton_of(scene)
	ual.reset_bone_poses()
	_pose(ual, _source_clip(scene, "idle"), 0.0)
	var reference: Dictionary[String, Quaternion] = _worlds(ual)
	_pose(ual, _source_clip(scene, key), time)
	var animated: Dictionary[String, Quaternion] = _worlds(ual)
	_pose(target, library.get_animation(key), time)
	var moved: Dictionary[String, Quaternion] = _worlds(target)
	var check: Vector2 = Vector2.ZERO
	for bone_name: String in reference:
		var base: Quaternion = bind[bone_name].basis.get_rotation_quaternion()
		check.x = maxf(check.x, _distance(moved[bone_name], animated[bone_name] * reference[bone_name].inverse() * base))
		check.y = maxf(check.y, _distance(moved[bone_name], base))
	return check


func _damped(ual: Skeleton3D, target: Skeleton3D, clip: Animation, factor: float) -> Animation:
	var options: CharacterRetarget.Options = CharacterRetarget.Options.new()
	options.damping = {DAMPED_BONE: factor}
	return CharacterRetarget.new(ual, target, options).retarget(clip)


func test_all_options_off_give_the_same_tracks_as_the_retarget_without_options() -> void:
	var scene: Node = _ual()
	var ual: Skeleton3D = CharacterSceneLoader.skeleton_of(scene)
	for body: Array in BODIES:
		var target: Skeleton3D = _body(body[0], body[1])
		var plain: AnimationLibrary = CharacterRetarget.library_for(target, _catalog.animations())
		var off: AnimationLibrary = CharacterRetarget.library_for(target, _catalog.animations(), CharacterRetarget.Options.new())
		for key: String in CLIPS:
			assert_true(_same_clip(plain.get_animation(key), off.get_animation(key)), "%s %s: library_for com Options nova" % [body[1], key])
			var source: Animation = _source_clip(scene, key)
			var ignored: Animation = CharacterRetarget.new(ual, target, null, _source_clip(scene, "idle")).retarget(source)
			assert_true(_same_clip(plain.get_animation(key), ignored), "%s %s: a referência sem bind_pose é ignorada" % [body[1], key])
			assert_true(_same_clip(plain.get_animation(key), CharacterRetarget.new(ual, target, CharacterRetarget.Options.new()).retarget(source)), "%s %s: construtor com Options nova" % [body[1], key])


func test_a_reference_pose_makes_frame_zero_of_the_idle_the_bind_pose_and_moves_by_the_ual_delta() -> void:
	var scene: Node = _ual()
	var ual: Skeleton3D = CharacterSceneLoader.skeleton_of(scene)
	var target: Skeleton3D = _clone(_body("male_a", "peasant_m"), 1.0)
	var options: CharacterRetarget.Options = CharacterRetarget.Options.new()
	options.bind_pose = _bind(target)
	assert_gt(options.bind_pose["upperarm_l"].basis.get_rotation_quaternion().angle_to(target.get_bone_global_rest(target.find_bone("upperarm_l")).basis.get_rotation_quaternion()), MIN_BIND_TURN, "o bind difere do repouso")
	var library: AnimationLibrary = CharacterRetarget.library_for(target, _catalog.animations(), options)
	assert_not_null(library)
	var offset: Vector2 = _bind_error(target, library.get_animation("idle"), options.bind_pose)
	assert_lt(offset.x, POSITION_TOLERANCE_M, "quadro 0 do idle: ossos na posição do bind")
	assert_lt(offset.y, ROTATION_TOLERANCE, "quadro 0 do idle: ossos na rotação do bind")
	for move: Array in MOVES:
		var check: Vector2 = _delta_check(scene, target, library, options.bind_pose, move[0], move[1])
		assert_lt(check.x, ROTATION_TOLERANCE, "%s: delta mundial = o da UAL em relação ao quadro 0 do idle, sobre o bind" % move[0])
		assert_gt(check.y, move[2], "%s: o destino anda (e no sentido do delta da UAL)" % move[0])
	var direct: Animation = CharacterRetarget.new(ual, target, options, _source_clip(scene, "idle")).retarget(_source_clip(scene, "walk"))
	assert_true(_same_clip(library.get_animation("walk"), direct), "a library_for acha o clipe de referência pela chave")
	assert_null(CharacterRetarget.library_for(target, {"walk": _catalog.animations()["walk"]}, options), "sem o clipe de referência na lista: null")


func test_the_ground_lock_holds_the_lowest_foot_bone_at_its_reference_height_where_a_short_leg_sinks() -> void:
	var target: Skeleton3D = _clone(_body("male_a", "peasant_m"), LEG_SCALE)
	var locking: CharacterRetarget.Options = CharacterRetarget.Options.new()
	locking.ground_lock = true
	var rebased: CharacterRetarget.Options = CharacterRetarget.Options.new()
	rebased.ground_lock = true
	rebased.bind_pose = _bind(target)
	var plain: AnimationLibrary = CharacterRetarget.library_for(target, _catalog.animations())
	var locked: AnimationLibrary = CharacterRetarget.library_for(target, _catalog.animations(), locking)
	var both: AnimationLibrary = CharacterRetarget.library_for(target, _catalog.animations(), rebased)
	var rest: Dictionary[String, Transform3D] = _rest(target)
	for key: String in CLIPS:
		var sunk: Array[float] = _gaps(target, plain.get_animation(key), rest)
		var held: Array[float] = _gaps(target, locked.get_animation(key), rest)
		var held_rebased: Array[float] = _gaps(target, both.get_animation(key), rebased.bind_pose)
		assert_lt(sunk.min(), -SINK_M[key], key + ": sem a trava o pé afunda")
		assert_lt(maxf(held.max(), -held.min()), GROUND_TOLERANCE_M, key + ": com a trava, o pé mais baixo fica na altura de repouso")
		assert_lt(maxf(held_rebased.max(), -held_rebased.min()), GROUND_TOLERANCE_M, key + ": com a trava e a pose de referência, na altura do bind")
	var real: Skeleton3D = _body("female_a", "peasant_f")
	var real_library: AnimationLibrary = CharacterRetarget.library_for(real, _catalog.animations(), locking)
	for key: String in CLIPS:
		var gaps: Array[float] = _gaps(real, real_library.get_animation(key), _rest(real))
		assert_lt(maxf(gaps.max(), -gaps.min()), GROUND_TOLERANCE_M, key + ": o corpo feminino real também")


func test_the_damping_blends_the_world_delta_of_one_bone_with_the_identity() -> void:
	var scene: Node = _ual()
	var ual: Skeleton3D = CharacterSceneLoader.skeleton_of(scene)
	var target: Skeleton3D = _body("male_a", "peasant_m")
	var walk: Animation = _source_clip(scene, "walk")
	var plain: Animation = CharacterRetarget.new(ual, target).retarget(walk)
	var rest: Quaternion = target.get_bone_global_rest(target.find_bone(DAMPED_BONE)).basis.get_rotation_quaternion()
	var largest: float = 0.0
	for factor: float in FACTORS:
		var damped: Animation = _damped(ual, target, walk, factor)
		for time: float in SWING_TIMES:
			_pose(target, plain, time)
			var full: Dictionary[String, Quaternion] = _worlds(target)
			_pose(target, damped, time)
			var worlds: Dictionary[String, Quaternion] = _worlds(target)
			largest = maxf(largest, full[DAMPED_BONE].angle_to(rest))
			assert_almost_eq(worlds[DAMPED_BONE].angle_to(rest), factor * full[DAMPED_BONE].angle_to(rest), ANGLE_TOLERANCE, "fator %s em %s s: o ângulo do delta é o fator vezes o inteiro" % [factor, time])
			assert_lt(_distance(worlds["calf_l"], full["calf_l"]), ROTATION_TOLERANCE, "só o osso amortecido muda (o delta do filho é dele)")
		assert_eq(_same_clip(damped, plain), factor == 1.0, "fator %s: só o 1 é idêntico a sem amortecer" % factor)
	assert_gt(largest, MIN_THIGH_SWING, "o balanço da coxa no walk é grande o bastante para o teste valer")


func test_the_same_options_give_the_same_tracks_twice() -> void:
	var target: Skeleton3D = _clone(_body("male_a", "peasant_m"), LEG_SCALE)
	var options: CharacterRetarget.Options = CharacterRetarget.Options.new()
	options.bind_pose = _bind(target)
	options.ground_lock = true
	options.damping = {"upperarm_r": 0.4, "lowerarm_r": 0.4, "hand_r": 0.4}
	var first: AnimationLibrary = CharacterRetarget.library_for(target, _catalog.animations(), options)
	var second: AnimationLibrary = CharacterRetarget.library_for(target, _catalog.animations(), options)
	assert_eq(first.get_animation_list().size(), _catalog.animations().size(), "todos os clipes do catálogo")
	for key: StringName in first.get_animation_list():
		assert_true(_same_clip(first.get_animation(key), second.get_animation(key)), "%s: duas execuções, mesmas trilhas" % key)


func test_a_damping_factor_outside_zero_to_one_is_limited() -> void:
	var scene: Node = _ual()
	var ual: Skeleton3D = CharacterSceneLoader.skeleton_of(scene)
	var target: Skeleton3D = _body("male_a", "peasant_m")
	var walk: Animation = _source_clip(scene, "walk")
	assert_true(_same_clip(_damped(ual, target, walk, 1.5), _damped(ual, target, walk, 1.0)), "fator 1,5 vale 1")
	assert_true(_same_clip(_damped(ual, target, walk, -0.5), _damped(ual, target, walk, 0.0)), "fator -0,5 vale 0")


func test_the_reference_key_picks_the_clip_whose_frame_zero_is_the_bind_pose() -> void:
	var target: Skeleton3D = _clone(_body("male_a", "peasant_m"), 1.0)
	var options: CharacterRetarget.Options = CharacterRetarget.Options.new()
	options.bind_pose = _bind(target)
	options.reference_key = "walk"
	var library: AnimationLibrary = CharacterRetarget.library_for(target, _catalog.animations(), options)
	assert_lt(_bind_error(target, library.get_animation("walk"), options.bind_pose).y, ROTATION_TOLERANCE, "o quadro 0 do walk é o bind")
	assert_gt(_bind_error(target, library.get_animation("idle"), options.bind_pose).y, MIN_REFERENCE_GAP, "o do idle deixa de ser")


func test_the_ground_lock_makes_the_pelvis_track_a_clip_without_one_lacks() -> void:
	var scene: Node = _ual()
	var ual: Skeleton3D = CharacterSceneLoader.skeleton_of(scene)
	var target: Skeleton3D = _clone(_body("male_a", "peasant_m"), LEG_SCALE)
	var rotations: Animation = _without_positions(_source_clip(scene, "walk"))
	var options: CharacterRetarget.Options = CharacterRetarget.Options.new()
	options.ground_lock = true
	assert_eq(CharacterRetarget.new(ual, target).retarget(rotations).find_track(PELVIS_POSITION, Animation.TYPE_POSITION_3D), -1, "sem a trava, nenhuma trilha de translação da pélvis")
	var locked: Animation = CharacterRetarget.new(ual, target, options).retarget(rotations)
	assert_gte(locked.find_track(PELVIS_POSITION, Animation.TYPE_POSITION_3D), 0, "com a trava, a trilha nasce")
	var gaps: Array[float] = _gaps(target, locked, _rest(target))
	assert_lt(maxf(gaps.max(), -gaps.min()), GROUND_TOLERANCE_M, "e segura o pé mais baixo")


func test_the_ground_lock_does_nothing_for_a_skeleton_without_foot_bones() -> void:
	var scene: Node = _ual()
	var ual: Skeleton3D = CharacterSceneLoader.skeleton_of(scene)
	var target: Skeleton3D = _without_feet(_body("male_a", "peasant_m"))
	var options: CharacterRetarget.Options = CharacterRetarget.Options.new()
	options.ground_lock = true
	var walk: Animation = _source_clip(scene, "walk")
	assert_true(_same_clip(CharacterRetarget.new(ual, target, options).retarget(walk), CharacterRetarget.new(ual, target).retarget(walk)), "sem ossos de pé a trava não muda nada")
