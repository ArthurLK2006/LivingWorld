extends GutTest
## ART-12, entrega 6j: a CORRIDA (clipe `jog`) da figura inteira. `CharacterRetarget.Options.ground_floor_only` (a trava de chão SÓ DE PISO) e o campo OPCIONAL `jog` dos metadados do `CharacterFigure`, com a UAL real e o corpo masculino do repositório (nenhum ativo de terceiros, nada de art_samples/); a figura é sintética (o esqueleto do corpo masculino e um triângulo com Skin) e existe só em MEMÓRIA, pelos carregadores injetáveis, com caminhos de mentira: nada toca o disco nem `user://` (AGENTS 4.16 e 9.4). O PROBLEMA: o jog tem FASE AÉREA (os dois pés fora do chão) e a trava de sempre sobe E DESCE a pélvis para o pé mais baixo tocar o chão em todo quadro, o que apaga a fase aérea; a trava SÓ DE PISO só sobe (quando um contato afunda) e nunca desce. Com a opção, a trilha da pélvis nunca fica abaixo da trilha SEM trava, coincide com a da trava de sempre onde esta SOBE a pélvis e com a SEM trava onde esta a DESCERIA, e a sola mais baixa nunca afunda e fica no ar em parte do ciclo (a trava de sempre a põe no chão em todos os quadros). Desligada (o padrão), a trava é a de sempre. Na figura o campo é um booleano: ausente ou `false` dá só `idle` e `walk`, os de sempre; `true` acrescenta o `jog` (em laço e parado), montado numa chamada PRÓPRIA de `library_for` com as MESMAS opções da figura (pose de bind, referência simétrica, amortecimento e pontos de contato) e a trava só de piso, igual ao retarget direto com essas opções; de outro tipo, ou com o catálogo sem a animação `jog`, `build` devolve null com o motivo curto. A ferramenta `ice_prepare` só grava o campo com `--jog`.

const Prepare = preload("res://tools/visual/ice_figure/ice_prepare.gd")
const JOG_CLIPS: PackedStringArray = ["idle", "jog"]
const PARTS: Array[String] = ["thigh", "calf", "foot", "ball"]
const DAMPING: Dictionary = {"upperarm_l": 0.4, "upperarm_r": 0.4, "hand_r": 0.5}
const SAMPLES_PER_SECOND: float = 30.0
const DIR: String = "res://figuras_de_teste/"
const ID: String = "figura"
const BODY_M: float = 1.8
## A meia-sola (m): os pontos de contato ficam 10 cm à frente e 10 cm atrás da origem do pé.
const SOLE_HALF_M: float = 0.1
const MAX_REASON_CHARS: int = 400
## [HIP] As tolerâncias: a elevação da pélvis e a altura da sola (m), e o que conta como sola no ar (m) e quantos quadros do ciclo (29) ficam no ar com a trava só de piso.
const LIFT_TOLERANCE_M: float = 0.0001
const GROUND_TOLERANCE_M: float = 0.0005
const AIRBORNE_M: float = 0.02
const MIN_AIRBORNE_FRAMES: int = 5
## Valores de JSON que NÃO são booleanos.
const NOT_BOOLEANS: Array = ["true", "", 1.0, 0.0, null, [true], {"jog": true}]

var _catalog: CharacterCatalog = CharacterCatalog.from_file().catalog
var _scenes: Dictionary[String, PackedScene] = {}
var _texts: Dictionary[String, String] = {}
var _failure: String = ""


func _male_skeleton() -> Skeleton3D:
	var look: CharacterAppearance = CharacterAppearance.new()
	look.body_id = "male_a"
	look.outfit_id = "peasant_m"
	var assembler: CharacterAssembler = add_child_autofree(CharacterAssembler.new())
	assert_true(assembler.build(look, _catalog), "montou o corpo masculino")
	return CharacterSceneLoader.skeleton_of(assembler)


## A pose de bind: o repouso em T (mundial) do esqueleto.
func _rest(skeleton: Skeleton3D) -> Dictionary[String, Transform3D]:
	var rest: Dictionary[String, Transform3D] = {}
	for bone: int in skeleton.get_bone_count():
		rest[skeleton.get_bone_name(bone)] = skeleton.get_bone_global_rest(bone)
	return rest


## Dois pontos de sola por pé, em listas [x, y, z] do espaço local do osso (como no JSON): na pose de bind, 10 cm à frente e 10 cm atrás da origem do pé, `sag` (m) abaixo do chão.
func _soles(skeleton: Skeleton3D, sag: float = 0.0) -> Dictionary:
	var bind: Dictionary[String, Transform3D] = _rest(skeleton)
	var soles: Dictionary = {}
	for bone_name: String in ["foot_l", "foot_r"]:
		soles[bone_name] = []
		for offset: float in [SOLE_HALF_M, -SOLE_HALF_M]:
			var point: Vector3 = bind[bone_name].affine_inverse() * Vector3(bind[bone_name].origin.x, -sag, bind[bone_name].origin.z + offset)
			soles[bone_name].append([point.x, point.y, point.z])
	return soles


## As opções da figura (pose de bind, referência simétrica, amortecimento e pontos de contato, com a sola `sag` abaixo do chão) com a trava de chão `lock` e a trava só de piso `floor_only`.
func _options(skeleton: Skeleton3D, lock: bool, floor_only: bool, sag: float = 0.0) -> CharacterRetarget.Options:
	var options: CharacterRetarget.Options = CharacterRetarget.Options.new()
	options.bind_pose = _rest(skeleton)
	options.symmetric_reference = PackedStringArray(PARTS)
	options.damping.assign(DAMPING)
	var soles: Dictionary = _soles(skeleton, sag)
	for bone_name: String in soles:
		options.ground_points[bone_name] = PackedVector3Array()
		for point: Array in soles[bone_name]:
			options.ground_points[bone_name].append(Vector3(point[0], point[1], point[2]))
	options.ground_lock = lock
	options.ground_floor_only = floor_only
	return options


## O `jog` do catálogo retargetado para `skeleton`, numa chamada de `library_for` com o idle (a referência) e o jog.
func _jog_of(skeleton: Skeleton3D, options: CharacterRetarget.Options) -> Animation:
	var clips: Dictionary = {}
	for key: String in JOG_CLIPS:
		clips[key] = _catalog.animations()[key]
	return CharacterRetarget.library_for(skeleton, clips, options).get_animation("jog")


## Tudo o que define as trilhas de um clipe (caminho, tipo e cada chave), para comparar por valor.
func _keys(clip: Animation) -> Array:
	var keys: Array = [clip.length, clip.loop_mode]
	for track: int in clip.get_track_count():
		keys.append([clip.track_get_path(track), clip.track_get_type(track)])
		for key: int in clip.track_get_key_count(track):
			keys.append([clip.track_get_key_time(track, key), clip.track_get_key_value(track, key)])
	return keys


func _same(a: Animation, b: Animation) -> bool:
	return _keys(a) == _keys(b)


func _pose(skeleton: Skeleton3D, clip: Animation, time: float) -> void:
	for track: int in clip.get_track_count():
		var bone: int = skeleton.find_bone(clip.track_get_path(track).get_concatenated_subnames())
		if bone >= 0 and clip.track_get_type(track) == Animation.TYPE_ROTATION_3D:
			skeleton.set_bone_pose_rotation(bone, clip.rotation_track_interpolate(track, time))
		elif bone >= 0 and clip.track_get_type(track) == Animation.TYPE_POSITION_3D:
			skeleton.set_bone_pose_position(bone, clip.position_track_interpolate(track, time))
	skeleton.force_update_all_bone_transforms()


## A elevação VERTICAL (m) da pélvis de `moved` sobre a de `plain`, por quadro a 30 por segundo: a diferença das trilhas (no espaço do pai da pélvis, a raiz, que gira) levada ao espaço do esqueleto pela rotação da raiz.
func _lifts(plain: Animation, moved: Animation) -> Array[float]:
	var pelvis: NodePath = NodePath("%s:%s" % [CharacterRetarget.SKELETON_NODE, CharacterRetarget.PELVIS_BONE])
	var root_path: NodePath = NodePath("%s:root" % CharacterRetarget.SKELETON_NODE)
	var lifts: Array[float] = []
	for step: int in int(ceil(plain.length * SAMPLES_PER_SECOND)) + 1:
		var time: float = minf(step / SAMPLES_PER_SECOND, plain.length)
		var difference: Vector3 = moved.position_track_interpolate(moved.find_track(pelvis, Animation.TYPE_POSITION_3D), time) - plain.position_track_interpolate(plain.find_track(pelvis, Animation.TYPE_POSITION_3D), time)
		lifts.append((plain.rotation_track_interpolate(plain.find_track(root_path, Animation.TYPE_ROTATION_3D), time) * difference).y)
	return lifts


## Por quadro a 30 por segundo de `clip`, a altura (m) da sola mais baixa (os pontos de `_soles`, no chão): 0 = a sola mais baixa no chão.
func _gaps(skeleton: Skeleton3D, clip: Animation) -> Array[float]:
	var soles: Dictionary = _soles(skeleton)
	var gaps: Array[float] = []
	for step: int in int(ceil(clip.length * SAMPLES_PER_SECOND)) + 1:
		_pose(skeleton, clip, minf(step / SAMPLES_PER_SECOND, clip.length))
		var lowest: float = INF
		for bone_name: String in soles:
			for point: Array in soles[bone_name]:
				lowest = minf(lowest, (skeleton.get_bone_global_pose(skeleton.find_bone(bone_name)) * Vector3(point[0], point[1], point[2])).y)
		gaps.append(lowest)
	return gaps


func _airborne(gaps: Array[float]) -> int:
	return gaps.filter(func(gap: float) -> bool: return gap > AIRBORNE_M).size()


func _median(values: Array[float]) -> float:
	var sorted: Array[float] = []
	sorted.assign(values)
	sorted.sort()
	return sorted[int(sorted.size() * 0.5)]


func _load_scene(path: String) -> Node:
	return _scenes[path].instantiate() if _scenes.has(path) else null


func _read_text(path: String) -> String:
	return _texts[path] if _texts.has(path) else ""


## A figura sintética em memória (o clone do esqueleto masculino, um triângulo preso à pélvis e metadados com a pose de bind, a referência simétrica, o amortecimento e os pontos de contato) com `extra` trocando ou acrescentando campos dos metadados e, com `without_jog`, o catálogo sem a animação `jog`; devolve a raiz, ou null com o motivo em `_failure`.
func _build(extra: Dictionary, without_jog: bool = false) -> Node3D:
	var source: Skeleton3D = _male_skeleton()
	var skeleton: Skeleton3D = Skeleton3D.new()
	skeleton.name = CharacterRetarget.SKELETON_NODE
	for bone: int in source.get_bone_count():
		skeleton.add_bone(source.get_bone_name(bone))
	for bone: int in source.get_bone_count():
		skeleton.set_bone_parent(bone, source.get_bone_parent(bone))
		skeleton.set_bone_rest(bone, source.get_bone_rest(bone))
	skeleton.reset_bone_poses()
	var poses: Dictionary = {}
	var rest: Dictionary[String, Transform3D] = _rest(skeleton)
	for bone_name: String in rest:
		var numbers: Array = []
		for vector: Vector3 in [rest[bone_name].basis.x, rest[bone_name].basis.y, rest[bone_name].basis.z, rest[bone_name].origin]:
			numbers.append_array([vector.x, vector.y, vector.z])
		poses[bone_name] = numbers
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([Vector3.ZERO, Vector3.UP, Vector3.RIGHT])
	var holder: MeshInstance3D = MeshInstance3D.new()
	holder.mesh = ArrayMesh.new()
	(holder.mesh as ArrayMesh).add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	holder.skin = Skin.new()
	holder.skin.add_named_bind("pelvis", Transform3D.IDENTITY)
	var root: Node3D = Node3D.new()
	root.add_child(skeleton)
	skeleton.add_child(holder)
	holder.skeleton = NodePath("..")
	skeleton.owner = root
	holder.owner = root
	var packed: PackedScene = PackedScene.new()
	packed.pack(root)
	root.free()
	var meta: Dictionary = {"version": 1, "reference_clip": "idle", "body_m": BODY_M, "height_m": BODY_M, "bind_pose": poses, "symmetric_reference": PARTS, "damping": DAMPING, "ground_points": _soles(source)}
	meta.merge(extra, true)
	_scenes[DIR + ID + ".scn"] = packed
	_texts[DIR + ID + ".json"] = JSON.stringify(meta)
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CharacterCatalog.DEFAULT_PATH))
	if without_jog:
		data["animations"].erase("jog")
	data["figures"] = [{"id": ID, "scene": DIR + ID + ".scn", "meta": DIR + ID + ".json"}]
	var figure: CharacterFigure = CharacterFigure.new(_load_scene, _read_text)
	var built: Node3D = figure.build(CharacterCatalog.from_json(JSON.stringify(data), "catalogo_de_teste.json").catalog, ID)
	_failure = figure.failure
	return add_child_autofree(built) if built != null else null


func _player_of(root: Node3D) -> AnimationPlayer:
	return root.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer


func _names_of(root: Node3D) -> Array:
	var names: Array = Array(_player_of(root).get_animation_list())
	names.sort()
	return names


func test_floor_only_never_lowers_the_pelvis_and_matches_the_usual_lock_where_it_rises_and_no_lock_where_it_would_descend() -> void:
	var skeleton: Skeleton3D = _male_skeleton()
	var plain: Animation = _jog_of(skeleton, _options(skeleton, false, false))
	var sag: float = _median(_gaps(skeleton, plain))
	var locked: Array[float] = _lifts(plain, _jog_of(skeleton, _options(skeleton, true, false, sag)))
	var floored: Array[float] = _lifts(plain, _jog_of(skeleton, _options(skeleton, true, true, sag)))
	var rising: int = 0
	var falling: int = 0
	var below: int = 0
	var off_lock: int = 0
	var off_plain: int = 0
	for step: int in locked.size():
		below += 1 if floored[step] < -LIFT_TOLERANCE_M else 0
		if locked[step] > LIFT_TOLERANCE_M:
			rising += 1
			off_lock += 1 if absf(floored[step] - locked[step]) > LIFT_TOLERANCE_M else 0
		elif locked[step] < -LIFT_TOLERANCE_M:
			falling += 1
			off_plain += 1 if absf(floored[step]) > LIFT_TOLERANCE_M else 0
	assert_gt(rising, 0, "o caso de teste tem quadros em que a trava de sempre SOBE a pélvis (o chão na mediana da sola mais baixa do jog sem trava, %.1f cm: metade dos quadros afunda)" % (sag * 100.0))
	assert_gt(falling, 0, "o caso de teste tem quadros em que a trava de sempre a DESCERIA")
	assert_eq(below, 0, "a trilha só de piso nunca fica abaixo da trilha sem trava")
	assert_eq(off_lock, 0, "onde a trava de sempre sobe, a só de piso a acompanha")
	assert_eq(off_plain, 0, "onde a trava de sempre desceria, a só de piso fica na trilha sem trava")


func test_the_option_is_off_by_default_the_usual_lock_grounds_every_frame_and_the_floor_only_lock_keeps_the_flight_phase() -> void:
	assert_false(CharacterRetarget.Options.new().ground_floor_only, "desligada por padrão")
	var skeleton: Skeleton3D = _male_skeleton()
	var usual: Array[float] = _gaps(skeleton, _jog_of(skeleton, _options(skeleton, true, false)))
	var floored: Array[float] = _gaps(skeleton, _jog_of(skeleton, _options(skeleton, true, true)))
	assert_lt(maxf(usual.max(), -usual.min()), GROUND_TOLERANCE_M, "a trava de sempre põe a sola mais baixa no chão em todos os quadros")
	assert_gt(floored.min(), -GROUND_TOLERANCE_M, "a trava só de piso nunca deixa a sola afundar")
	assert_gt(_airborne(floored), MIN_AIRBORNE_FRAMES, "a trava só de piso mantém a fase aérea: %d de %d quadros" % [_airborne(floored), floored.size()])
	assert_eq(_airborne(usual), 0, "a trava de sempre apaga a fase aérea")


func test_a_figure_with_jog_true_gets_the_jog_made_with_the_floor_only_lock_and_keeps_idle_and_walk() -> void:
	var before: Node3D = _build({})
	var root: Node3D = _build({"jog": true})
	assert_not_null(root, "a figura com jog monta: " + _failure)
	var player: AnimationPlayer = _player_of(root)
	assert_eq(_names_of(root), ["idle", "jog", "walk"], "idle, walk e jog")
	for key: String in _names_of(root):
		assert_eq(player.get_animation(key).loop_mode, Animation.LOOP_LINEAR, key + ": em laço")
	assert_false(player.is_playing(), "parado")
	assert_eq(player.autoplay, "", "sem autoplay")
	for key: String in ["idle", "walk"]:
		assert_true(_same(player.get_animation(key), _player_of(before).get_animation(key)), key + ": o de sempre")
	var skeleton: Skeleton3D = CharacterSceneLoader.skeleton_of(root)
	var options: CharacterRetarget.Options = CharacterFigure._read_meta(DIR + ID + ".json", _texts[DIR + ID + ".json"], skeleton).options
	options.ground_floor_only = true
	assert_true(_same(player.get_animation("jog"), _jog_of(skeleton, options)), "o jog da figura é o do retarget com as opções da figura e a trava só de piso")
	options.ground_floor_only = false
	assert_false(_same(player.get_animation("jog"), _jog_of(skeleton, options)), "e não o da trava de sempre")
	assert_false(_same(player.get_animation("jog"), player.get_animation("walk")), "o jog difere do walk")
	assert_gt(_airborne(_gaps(skeleton, player.get_animation("jog"))), MIN_AIRBORNE_FRAMES, "a fase aérea do jog fica na figura")


func test_the_jog_of_a_figure_with_sunk_contacts_is_raised_like_the_floor_only_retarget_with_the_figure_options() -> void:
	var reference: Skeleton3D = _male_skeleton()
	var sag: float = _median(_gaps(reference, _jog_of(reference, _options(reference, false, false))))
	var root: Node3D = _build({"jog": true, "ground_points": _soles(reference, sag)})
	assert_not_null(root, "a figura com contatos afundados monta: " + _failure)
	var skeleton: Skeleton3D = CharacterSceneLoader.skeleton_of(root)
	var options: CharacterRetarget.Options = CharacterFigure._read_meta(DIR + ID + ".json", _texts[DIR + ID + ".json"], skeleton).options
	options.ground_floor_only = true
	var jog: Animation = _player_of(root).get_animation("jog")
	assert_true(_same(jog, _jog_of(skeleton, options)), "o jog da figura é o do retarget com os contatos da figura e a trava só de piso")
	options.ground_lock = false
	assert_gt(_lifts(_jog_of(skeleton, options), jog).max(), LIFT_TOLERANCE_M, "a pélvis do jog sobe onde a sola afunda")


func test_an_absent_or_false_jog_builds_the_same_figure_with_only_idle_and_walk() -> void:
	var absent: Node3D = _build({})
	var off: Node3D = _build({"jog": false})
	assert_eq(_names_of(absent), ["idle", "walk"], "sem o campo: idle e walk")
	assert_eq(_names_of(off), ["idle", "walk"], "com false: idle e walk")
	for key: String in ["idle", "walk"]:
		assert_true(_same(_player_of(off).get_animation(key), _player_of(absent).get_animation(key)), key + ": a mesma figura")


func test_an_invalid_jog_field_or_a_catalog_without_the_jog_clip_returns_null_with_the_reason_and_leaks_nothing() -> void:
	for value: Variant in NOT_BOOLEANS:  # Variant: valores de JSON inválidos, de tipos diferentes
		assert_null(_build({"jog": value}), "jog = %s: inválido" % str(value))
		assert_true(_failure.contains("jog") and _failure.length() < MAX_REASON_CHARS, "o motivo cita o campo e é curto: " + _failure)
	assert_null(_build({"jog": true}, true), "catálogo sem a animação jog")
	assert_true(_failure.contains("jog") and _failure.length() < MAX_REASON_CHARS, "o motivo cita o jog e é curto: " + _failure)
	assert_not_null(_build({"jog": false}, true), "sem pedir o jog, o catálogo sem ele serve: " + _failure)
	assert_no_new_orphans()


func test_the_prepare_tool_writes_the_jog_field_only_with_the_flag() -> void:
	assert_eq(Prepare._jog_field(PackedStringArray(["--damping", "--contact", "--symmetric"])), {}, "sem --jog, nenhum campo")
	assert_eq(Prepare._jog_field(PackedStringArray()), {}, "sem argumentos, nenhum campo")
	assert_eq(Prepare._jog_field(PackedStringArray(["--damping", "--jog"])), {"jog": true}, "com --jog, jog verdadeiro")


func test_the_jog_call_uses_the_reference_clip_of_the_figure() -> void:
	var root: Node3D = _build({"jog": true, "reference_clip": "walk"})
	assert_not_null(root, "a figura com o walk de referência e o jog monta: " + _failure)
	var skeleton: Skeleton3D = CharacterSceneLoader.skeleton_of(root)
	var options: CharacterRetarget.Options = CharacterFigure._read_meta(DIR + ID + ".json", _texts[DIR + ID + ".json"], skeleton).options
	options.ground_floor_only = true
	var clips: Dictionary = {"walk": _catalog.animations()["walk"], "jog": _catalog.animations()["jog"]}
	assert_true(_same(_player_of(root).get_animation("jog"), CharacterRetarget.library_for(skeleton, clips, options).get_animation("jog")), "o jog é montado com o clipe de referência da figura")
