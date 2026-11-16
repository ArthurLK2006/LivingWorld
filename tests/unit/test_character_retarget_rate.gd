extends GutTest
## ART-12, entrega 6k: a taxa de reamostragem do retarget (`CharacterRetarget.Options.samples_per_second`, padrão 30, validada de 1 a 240) e o clipe `jog` da figura a `CharacterFigure.JOG_SAMPLES_PER_SECOND` (60), com a UAL real e o corpo masculino do repositório (nenhum ativo de terceiros, nada de art_samples/); a figura é sintética (o esqueleto do corpo masculino e um triângulo com Skin) e existe só em MEMÓRIA, pelos carregadores injetáveis, com caminhos de mentira: nada toca o disco nem `user://` (AGENTS 4.16 e 9.4). O PROBLEMA: a trava de chão só mede a sola nos instantes das chaves (30 por segundo) e entre eles a pélvis interpola linearmente (e a rotação, por slerp), então a sola afunda entre as chaves (no Ice Warrior, 0,00 cm nas chaves e até 1,28 cm entre elas; o critério do contrato é de 1 cm); o erro de interpolação cai com o quadrado do passo. Aqui: o padrão da opção é 30 e sem ela as trilhas são as de sempre (opção omitida, `Options.new()` e 30 explícito idênticos); com 60 o jog tem o dobro de chaves (rotação e pélvis, com os instantes de 30 por segundo no meio); a sola, medida em 600 instantes do ciclo, afunda ESTRITAMENTE menos com 60 do que com 30; valor fora de 1 a 240 é limitado e o que não é finito volta ao padrão; na figura só o `jog` usa a constante (idle e walk ficam nos 30 de sempre).

const CLIPS: PackedStringArray = ["idle", "walk", "jog"]
const JOG_CLIPS: PackedStringArray = ["idle", "jog"]
const PLAIN_CLIPS: PackedStringArray = ["idle", "walk"]
const IDLE_ONLY: PackedStringArray = ["idle"]
const PARTS: Array[String] = ["thigh", "calf", "foot", "ball"]
const FEET: PackedStringArray = ["foot_l", "foot_r"]
const USUAL_RATE: float = 30.0
## [HIP] A taxa do jog da figura (a constante escolhida na 6k; medida no Ice Warrior: afunda 0,32 cm em 600 e 3000 instantes, contra 1,28 cm a 30 por segundo).
const JOG_RATE: float = 60.0
## [HIP] Cada par é (taxa pedida, taxa que vale): limitada a [1, 240]; NaN e infinitos voltam ao padrão (30). O teste usa o idle (2,5 s) para os limites se distinguirem de valores vizinhos (o jog, de 0,93 s, tem 2 chaves a 1 e a 0,5 por segundo).
const RATES: Array[Vector2] = [Vector2(0.0, 1.0), Vector2(-5.0, 1.0), Vector2(0.5, 1.0), Vector2(1.0, 1.0), Vector2(240.0, 240.0), Vector2(1000.0, 240.0), Vector2(NAN, 30.0), Vector2(INF, 30.0), Vector2(-INF, 30.0)]
## A meia-sola (m): os pontos de contato ficam 10 cm à frente e 10 cm atrás da origem do pé.
const SOLE_HALF_M: float = 0.1
## [HIP] A tolerância (s) dos instantes das chaves.
const TIME_TOLERANCE_S: float = 0.000001
## O jog a 60 por segundo tem o dobro de intervalos entre chaves do de 30.
const DOUBLE: int = 2
## [HIP] A fração de intervalo que não conta no número de chaves (ver `_steps`), os instantes da medida densa do ciclo e o afundamento mínimo (m) que a 30 por segundo o teste exige para valer.
const STEP_TOLERANCE: float = 0.001
const DENSE_INSTANTS: int = 600
const MIN_SAG_M: float = 0.001
const DIR: String = "res://figuras_de_teste/"
const ID: String = "figura"
const BODY_M: float = 1.8

var _catalog: CharacterCatalog = CharacterCatalog.from_file().catalog
var _male: Skeleton3D = null


func _male_skeleton() -> Skeleton3D:
	var look: CharacterAppearance = CharacterAppearance.new()
	look.body_id = "male_a"
	look.outfit_id = "peasant_m"
	var assembler: CharacterAssembler = add_child_autofree(CharacterAssembler.new())
	assert_true(assembler.build(look, _catalog), "montou o corpo masculino")
	_male = CharacterSceneLoader.skeleton_of(assembler)
	return _male


func _rest(skeleton: Skeleton3D) -> Dictionary[String, Transform3D]:
	var rest: Dictionary[String, Transform3D] = {}
	for bone: int in skeleton.get_bone_count():
		rest[skeleton.get_bone_name(bone)] = skeleton.get_bone_global_rest(bone)
	return rest


## Dois pontos de sola por pé no espaço local do osso: na pose de bind, 10 cm à frente e 10 cm atrás da origem do pé, `sag` (m) abaixo do chão.
func _soles(skeleton: Skeleton3D, sag: float) -> Dictionary[String, PackedVector3Array]:
	var bind: Dictionary[String, Transform3D] = _rest(skeleton)
	var soles: Dictionary[String, PackedVector3Array] = {}
	for bone_name: String in FEET:
		soles[bone_name] = PackedVector3Array()
		for offset: float in [SOLE_HALF_M, -SOLE_HALF_M]:
			soles[bone_name].append(bind[bone_name].affine_inverse() * Vector3(bind[bone_name].origin.x, -sag, bind[bone_name].origin.z + offset))
	return soles


## As opções da figura (pose de bind, referência simétrica e contatos com a sola `sag` abaixo do chão) com a trava SÓ DE PISO ligada (ou não, com `locked` falso) e a taxa `rate`.
func _options(skeleton: Skeleton3D, rate: float, sag: float = 0.0, locked: bool = true) -> CharacterRetarget.Options:
	var options: CharacterRetarget.Options = CharacterRetarget.Options.new()
	options.bind_pose = _rest(skeleton)
	options.symmetric_reference = PackedStringArray(PARTS)
	options.ground_points = _soles(skeleton, sag)
	options.ground_lock = locked
	options.ground_floor_only = true
	options.samples_per_second = rate
	return options


func _library(skeleton: Skeleton3D, keys: PackedStringArray, options: CharacterRetarget.Options = null) -> AnimationLibrary:
	var clips: Dictionary = {}
	for key: String in keys:
		clips[key] = _catalog.animations()[key]
	return CharacterRetarget.library_for(skeleton, clips, options)


func _jog_of(skeleton: Skeleton3D, options: CharacterRetarget.Options) -> Animation:
	return _library(skeleton, JOG_CLIPS, options).get_animation("jog")


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


func _path_of(bone_name: String) -> NodePath:
	return NodePath("%s:%s" % [CharacterRetarget.SKELETON_NODE, bone_name])


## O número de chaves da trilha de `type` do osso `bone_name`.
func _track_keys(clip: Animation, bone_name: String, type: Animation.TrackType) -> int:
	return clip.track_get_key_count(clip.find_track(_path_of(bone_name), type))


## O número de chaves de uma trilha reamostrada a `rate` por segundo: uma por intervalo de 1/rate e a última cai em `length`. O motor guarda o comprimento em 32 bits (28,0000001 intervalos) e funde chaves a menos de 0,00001 s, então o intervalo que sobra por erro de arredondamento não conta (`STEP_TOLERANCE`).
func _steps(clip: Animation, rate: float) -> int:
	return int(ceil(clip.length * rate - STEP_TOLERANCE)) + 1


## A trilha de `type` do osso `bone_name` do jog a 60 por segundo tem o dobro de intervalos da de 30, e cada chave da de 30 cai no mesmo instante de uma chave da de 60.
func _assert_doubled(usual: Animation, dense: Animation, bone_name: String, type: Animation.TrackType) -> void:
	var track_low: int = usual.find_track(_path_of(bone_name), type)
	var track_high: int = dense.find_track(_path_of(bone_name), type)
	var low: int = usual.track_get_key_count(track_low)
	var high: int = dense.track_get_key_count(track_high)
	assert_eq(low, _steps(usual, USUAL_RATE), "%s a 30 por segundo: uma chave a cada 1/30 s" % bone_name)
	assert_eq(high, _steps(dense, JOG_RATE), "%s a 60 por segundo: uma chave a cada 1/60 s" % bone_name)
	assert_eq(high, DOUBLE * (low - 1) + 1, "%s: o dobro de intervalos" % bone_name)
	for key: int in low:
		assert_almost_eq(dense.track_get_key_time(track_high, mini(DOUBLE * key, high - 1)), usual.track_get_key_time(track_low, key), TIME_TOLERANCE_S, "%s: a chave %d de 30 por segundo também é chave a 60" % [bone_name, key])


func _pose(skeleton: Skeleton3D, clip: Animation, time: float) -> void:
	for track: int in clip.get_track_count():
		var bone: int = skeleton.find_bone(clip.track_get_path(track).get_concatenated_subnames())
		if bone >= 0 and clip.track_get_type(track) == Animation.TYPE_ROTATION_3D:
			skeleton.set_bone_pose_rotation(bone, clip.rotation_track_interpolate(track, time))
		elif bone >= 0 and clip.track_get_type(track) == Animation.TYPE_POSITION_3D:
			skeleton.set_bone_pose_position(bone, clip.position_track_interpolate(track, time))
	skeleton.force_update_all_bone_transforms()


## A altura (m) da sola mais baixa de `soles` no instante `time` de `clip`.
func _lowest(skeleton: Skeleton3D, clip: Animation, soles: Dictionary[String, PackedVector3Array], time: float) -> float:
	_pose(skeleton, clip, time)
	var lowest: float = INF
	for bone_name: String in soles:
		for point: Vector3 in soles[bone_name]:
			lowest = minf(lowest, (skeleton.get_bone_global_pose(skeleton.find_bone(bone_name)) * point).y)
	return lowest


## O afundamento máximo (m) da sola mais baixa de `soles` abaixo do chão (y = 0) em `DENSE_INSTANTS` instantes igualmente espaçados do ciclo de `clip` (0 = nunca afunda).
func _dense_sag(skeleton: Skeleton3D, clip: Animation, soles: Dictionary[String, PackedVector3Array]) -> float:
	var worst: float = 0.0
	for step: int in DENSE_INSTANTS:
		worst = maxf(worst, -_lowest(skeleton, clip, soles, clip.length * step / DENSE_INSTANTS))
	return worst


## Metade dos instantes de 30 por segundo do jog SEM trava tem a sola mais baixa abaixo deste valor: com o chão aqui, a trava só de piso trabalha em metade do ciclo.
func _median_height(skeleton: Skeleton3D) -> float:
	var plain: Animation = _jog_of(skeleton, _options(skeleton, USUAL_RATE, 0.0, false))
	var flat: Dictionary[String, PackedVector3Array] = _soles(skeleton, 0.0)
	var heights: Array[float] = []
	for step: int in _steps(plain, USUAL_RATE):
		heights.append(_lowest(skeleton, plain, flat, minf(step / USUAL_RATE, plain.length)))
	heights.sort()
	return heights[int(heights.size() * 0.5)]


func _scene(_path: String) -> Node:
	var skeleton: Skeleton3D = Skeleton3D.new()
	skeleton.name = CharacterRetarget.SKELETON_NODE
	for bone: int in _male.get_bone_count():
		skeleton.add_bone(_male.get_bone_name(bone))
	for bone: int in _male.get_bone_count():
		skeleton.set_bone_parent(bone, _male.get_bone_parent(bone))
		skeleton.set_bone_rest(bone, _male.get_bone_rest(bone))
	skeleton.reset_bone_poses()
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
	return root


## Os metadados da figura sintética: a pose de bind (o repouso em T) e o pedido do `jog`.
func _meta_text() -> String:
	var poses: Dictionary = {}
	var rest: Dictionary[String, Transform3D] = _rest(_male)
	for bone_name: String in rest:
		var numbers: Array = []
		for vector: Vector3 in [rest[bone_name].basis.x, rest[bone_name].basis.y, rest[bone_name].basis.z, rest[bone_name].origin]:
			numbers.append_array([vector.x, vector.y, vector.z])
		poses[bone_name] = numbers
	return JSON.stringify({"version": 1, "reference_clip": "idle", "body_m": BODY_M, "height_m": BODY_M, "bind_pose": poses, "jog": true})


func test_the_rate_defaults_to_30_and_without_the_option_the_tracks_are_the_usual_ones() -> void:
	assert_eq(CharacterRetarget.Options.new().samples_per_second, USUAL_RATE, "o padrão da opção é 30")
	var skeleton: Skeleton3D = _male_skeleton()
	var omitted: AnimationLibrary = _library(skeleton, CLIPS)
	var fresh: AnimationLibrary = _library(skeleton, CLIPS, CharacterRetarget.Options.new())
	var explicit: CharacterRetarget.Options = CharacterRetarget.Options.new()
	explicit.samples_per_second = USUAL_RATE
	var thirty: AnimationLibrary = _library(skeleton, CLIPS, explicit)
	for key: String in CLIPS:
		var clip: Animation = omitted.get_animation(key)
		assert_true(_same(clip, fresh.get_animation(key)) and _same(clip, thirty.get_animation(key)), key + ": opção omitida, Options.new() e 30 explícito dão as mesmas trilhas")
		assert_eq(_track_keys(clip, "thigh_l", Animation.TYPE_ROTATION_3D), _steps(clip, USUAL_RATE), key + ": as chaves de rotação caem a cada 1/30 s")
		assert_almost_eq(clip.track_get_key_time(clip.find_track(_path_of("thigh_l"), Animation.TYPE_ROTATION_3D), 1), 1.0 / USUAL_RATE, TIME_TOLERANCE_S, key + ": a segunda chave cai em 1/30 s")


func test_sixty_per_second_doubles_the_jog_keys_of_the_rotation_and_of_the_locked_pelvis() -> void:
	var skeleton: Skeleton3D = _male_skeleton()
	var usual: Animation = _jog_of(skeleton, _options(skeleton, USUAL_RATE))
	var dense: Animation = _jog_of(skeleton, _options(skeleton, JOG_RATE))
	_assert_doubled(usual, dense, "thigh_l", Animation.TYPE_ROTATION_3D)
	_assert_doubled(usual, dense, CharacterRetarget.PELVIS_BONE, Animation.TYPE_POSITION_3D)


func test_the_dense_foot_sag_is_strictly_smaller_at_60_per_second_than_at_30() -> void:
	var skeleton: Skeleton3D = _male_skeleton()
	var sag: float = _median_height(skeleton)
	var soles: Dictionary[String, PackedVector3Array] = _soles(skeleton, sag)
	var usual: float = _dense_sag(skeleton, _jog_of(skeleton, _options(skeleton, USUAL_RATE, sag)), soles)
	var dense: float = _dense_sag(skeleton, _jog_of(skeleton, _options(skeleton, JOG_RATE, sag)), soles)
	assert_gt(usual, MIN_SAG_M, "a 30 por segundo a sola afunda entre as chaves: %.3f cm" % (usual * 100.0))
	assert_lt(dense, usual, "a 60 por segundo afunda menos: %.3f cm contra %.3f cm" % [dense * 100.0, usual * 100.0])


func test_a_rate_outside_1_to_240_is_limited_and_one_that_is_not_finite_falls_back_to_30() -> void:
	var skeleton: Skeleton3D = _male_skeleton()
	for pair: Vector2 in RATES:
		var clip: Animation = _library(skeleton, IDLE_ONLY, _options(skeleton, pair.x)).get_animation("idle")
		assert_eq(_track_keys(clip, "thigh_l", Animation.TYPE_ROTATION_3D), _steps(clip, pair.y), "taxa %s: vale %s (rotação)" % [pair.x, pair.y])
		assert_eq(_track_keys(clip, CharacterRetarget.PELVIS_BONE, Animation.TYPE_POSITION_3D), _steps(clip, pair.y), "taxa %s: vale %s (pélvis)" % [pair.x, pair.y])


func test_in_the_figure_only_the_jog_uses_the_jog_rate_and_idle_and_walk_keep_30() -> void:
	var skeleton: Skeleton3D = _male_skeleton()
	var text: String = _meta_text()
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CharacterCatalog.DEFAULT_PATH))
	data["figures"] = [{"id": ID, "scene": DIR + ID + ".scn", "meta": DIR + ID + ".json"}]
	var catalog: CharacterCatalog = CharacterCatalog.from_json(JSON.stringify(data), "catalogo_de_teste.json").catalog
	var maker: CharacterFigure = CharacterFigure.new(_scene, func(_path: String) -> String: return text)
	var built: Node3D = maker.build(catalog, ID)
	assert_not_null(built, "a figura com jog monta: " + maker.failure)
	if built == null:
		return
	var root: Node3D = add_child_autofree(built)
	var player: AnimationPlayer = root.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	var options: CharacterRetarget.Options = CharacterFigure._read_meta(DIR + ID + ".json", text, skeleton).options
	options.samples_per_second = USUAL_RATE
	var usual: AnimationLibrary = _library(skeleton, PLAIN_CLIPS, options)
	for key: String in ["idle", "walk"]:
		assert_true(_same(player.get_animation(key), usual.get_animation(key)), key + ": a 30 por segundo, como sempre")
		assert_eq(_track_keys(player.get_animation(key), CharacterRetarget.PELVIS_BONE, Animation.TYPE_POSITION_3D), _steps(player.get_animation(key), USUAL_RATE), key + ": a pélvis com chaves a cada 1/30 s")
	options.ground_floor_only = true
	options.samples_per_second = JOG_RATE
	var jog: Animation = player.get_animation("jog")
	assert_true(_same(jog, _jog_of(skeleton, options)), "o jog da figura é o do retarget com as opções da figura, a trava só de piso e 60 por segundo")
	assert_eq(_track_keys(jog, CharacterRetarget.PELVIS_BONE, Animation.TYPE_POSITION_3D), _steps(jog, JOG_RATE), "o jog tem a pélvis com chaves a cada 1/60 s")
	assert_eq(CharacterFigure.JOG_SAMPLES_PER_SECOND, JOG_RATE, "a constante do jog é a escolhida na 6k")
