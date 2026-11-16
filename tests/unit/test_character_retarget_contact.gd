extends GutTest
## ART-12, entrega 6e (i): a opção `ground_points` do CharacterRetarget (os contatos da trava de chão, por figura), com a UAL real e o corpo masculino do repositório (nenhum ativo de terceiros, nada de art_samples/). Cada pé ganha dois pontos de SOLA, 10 cm à frente e 10 cm atrás da origem do osso, no chão no repouso ou 2 cm acima dele (a sola fica abaixo da origem do osso). Com a opção, o ponto de sola mais baixo fica no chão (y = 0, o chão de referência, e não a altura do ponto no repouso) a até 1 cm em todo quadro do idle e do walk e as mesmas opções dão as mesmas trilhas duas vezes; sem ela, com a mesma trava pelos ossos do pé, a sola afunda no walk. `ground_points` vazio dá as mesmas trilhas das opções sem o campo, e sem a trava de chão os pontos não mudam nada.

const FEET: PackedStringArray = ["foot_l", "foot_r"]
const CLIPS: PackedStringArray = ["idle", "walk"]
const SOLE_HALF_M: float = 0.1
## A altura das solas no repouso: no chão e 2 cm acima dele.
const LIFTS: Array[float] = [0.0, 0.02]
const SAMPLES_PER_SECOND: float = 30.0
## [HIP] 1 cm do chão com a opção; sem ela a sola afunda ao menos 2 cm no walk (medido: 3,5 cm, e no idle 0,02 cm).
const GROUND_TOLERANCE_M: float = 0.01
const MIN_SINK_M: float = 0.02

var _catalog: CharacterCatalog = CharacterCatalog.from_file().catalog


func _male_skeleton() -> Skeleton3D:
	var look: CharacterAppearance = CharacterAppearance.new()
	look.body_id = "male_a"
	look.outfit_id = "peasant_m"
	var assembler: CharacterAssembler = add_child_autofree(CharacterAssembler.new())
	assert_true(assembler.build(look, _catalog), "montou o corpo masculino")
	return CharacterSceneLoader.skeleton_of(assembler)


## Dois pontos de sola por pé, no espaço local do osso: no repouso, 10 cm à frente e 10 cm atrás da origem do pé, na altura `lift`.
func _soles(skeleton: Skeleton3D, lift: float) -> Dictionary[String, PackedVector3Array]:
	var soles: Dictionary[String, PackedVector3Array] = {}
	for bone_name: String in FEET:
		var rest: Transform3D = skeleton.get_bone_global_rest(skeleton.find_bone(bone_name))
		soles[bone_name] = PackedVector3Array([rest.affine_inverse() * Vector3(rest.origin.x, lift, rest.origin.z + SOLE_HALF_M), rest.affine_inverse() * Vector3(rest.origin.x, lift, rest.origin.z - SOLE_HALF_M)])
	return soles


func _library(skeleton: Skeleton3D, options: CharacterRetarget.Options) -> AnimationLibrary:
	var clips: Dictionary = {}
	for key: String in CLIPS:
		clips[key] = _catalog.animations()[key]
	return CharacterRetarget.library_for(skeleton, clips, options)


func _options(lock: bool, soles: Dictionary[String, PackedVector3Array]) -> CharacterRetarget.Options:
	var options: CharacterRetarget.Options = CharacterRetarget.Options.new()
	options.ground_lock = lock
	options.ground_points = soles
	return options


## Por quadro a 30 por segundo, a altura do ponto de sola mais baixo.
func _lowest(skeleton: Skeleton3D, clip: Animation, soles: Dictionary[String, PackedVector3Array]) -> Array[float]:
	var lows: Array[float] = []
	for step: int in int(ceil(clip.length * SAMPLES_PER_SECOND)) + 1:
		for track: int in clip.get_track_count():
			var bone: int = skeleton.find_bone(clip.track_get_path(track).get_concatenated_subnames())
			var time: float = minf(step / SAMPLES_PER_SECOND, clip.length)
			if bone >= 0 and clip.track_get_type(track) == Animation.TYPE_ROTATION_3D:
				skeleton.set_bone_pose_rotation(bone, clip.rotation_track_interpolate(track, time))
			elif bone >= 0 and clip.track_get_type(track) == Animation.TYPE_POSITION_3D:
				skeleton.set_bone_pose_position(bone, clip.position_track_interpolate(track, time))
		skeleton.force_update_all_bone_transforms()
		var low: float = INF
		for bone_name: String in soles:
			for point: Vector3 in soles[bone_name]:
				low = minf(low, (skeleton.get_bone_global_pose(skeleton.find_bone(bone_name)) * point).y)
		lows.append(low)
	return lows


## Tudo o que define as trilhas de um clipe (caminho, tipo e cada chave), para comparar por valor.
func _keys(clip: Animation) -> Array:
	var keys: Array = [clip.length, clip.loop_mode]
	for track: int in clip.get_track_count():
		keys.append([clip.track_get_path(track), clip.track_get_type(track)])
		for key: int in clip.track_get_key_count(track):
			keys.append([clip.track_get_key_time(track, key), clip.track_get_key_value(track, key)])
	return keys


func test_the_lock_with_contact_points_holds_the_lowest_sole_point_at_the_ground_and_without_them_the_sole_sinks() -> void:
	var skeleton: Skeleton3D = _male_skeleton()
	for lift: float in LIFTS:
		var soles: Dictionary[String, PackedVector3Array] = _soles(skeleton, lift)
		var held: AnimationLibrary = _library(skeleton, _options(true, soles))
		for key: String in CLIPS:
			var lows: Array[float] = _lowest(skeleton, held.get_animation(key), soles)
			assert_lt(maxf(lows.max(), -lows.min()), GROUND_TOLERANCE_M, "%s, sola a %.0f cm no repouso: o ponto de sola mais baixo fica no chão" % [key, lift * 100.0])
			assert_eq(_lowest(skeleton, _library(skeleton, _options(true, soles)).get_animation(key), soles), lows, key + ": as mesmas opções, as mesmas trilhas")
	var flat: Dictionary[String, PackedVector3Array] = _soles(skeleton, 0.0)
	assert_lt(_lowest(skeleton, _library(skeleton, _options(true, {})).get_animation("walk"), flat).min(), -MIN_SINK_M, "sem os pontos, a trava pelos ossos do pé deixa a sola afundar")


func test_an_empty_table_changes_nothing_and_the_points_do_nothing_without_the_lock() -> void:
	var skeleton: Skeleton3D = _male_skeleton()
	var plain: CharacterRetarget.Options = CharacterRetarget.Options.new()
	plain.ground_lock = true
	var empty: AnimationLibrary = _library(skeleton, _options(true, {}))
	var unlocked: AnimationLibrary = _library(skeleton, _options(false, _soles(skeleton, 0.0)))
	var plain_library: AnimationLibrary = _library(skeleton, plain)
	var off: AnimationLibrary = _library(skeleton, null)
	for key: String in CLIPS:
		assert_eq(_keys(empty.get_animation(key)), _keys(plain_library.get_animation(key)), key + ": ground_points vazio = o campo ausente")
		assert_eq(_keys(unlocked.get_animation(key)), _keys(off.get_animation(key)), key + ": sem ground_lock os pontos não valem")
