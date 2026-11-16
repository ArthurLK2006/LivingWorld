extends GutTest
## ART-12, entrega 6h: a referência simétrica das pernas. `CharacterRetarget.Options.symmetric_reference` e o campo OPCIONAL de mesmo nome dos metadados do `CharacterFigure`, com a UAL real e o corpo masculino do repositório (nenhum ativo de terceiros, nada de art_samples/); a figura é sintética (o esqueleto do corpo masculino e um triângulo com Skin) e existe só em MEMÓRIA, pelos carregadores injetáveis, com caminhos de mentira: nada toca o disco nem `user://` (AGENTS 4.16 e 9.4). O DEFEITO: com a pose de referência, o quadro 0 do `Idle` da UAL (coxa esquerda a 23 graus e direita a -9) desloca de forma diferente as duas pernas de um destino simétrico e o walk fica manco. SEM a opção a coxa média esquerda e direita do walk difere em muitos graus; COM ela as duas ficam quase iguais (de 25 graus de diferença a 2), a média das duas é a de antes (o peso é 1/2), a amplitude de cada coxa não muda, as médias laterais ficam espelhadas e a canela (do joelho ao tornozelo) também fica simétrica, com a amplitude de antes e as mesmas opções dão as mesmas trilhas; o reflexo x -> -x leva o giro de um vetor ao giro do vetor refletido; num caso SINTÉTICO de quatro pares (thigh, calf, foot e ball, com repouso espelhado e deltas assimétricos DIFERENTES entre si) cada parte listada recebe a sua própria média (a flexão média e a abdução do lado mantida), as não listadas ficam como eram e uma parte sem par no começo da lista não impede as válidas depois dela. Partes sem par `_l` e `_r`, sem a pose de bind ou lista vazia: trilhas IDÊNTICAS às de antes. Na figura o campo é lido, validado (lista de textos, até o limite, cada um com o par de ossos no esqueleto) e muda o walk como no retarget; ausente ou vazio dá a mesma figura; inválido dá null com o campo no motivo curto. A ferramenta `ice_prepare` só grava o campo com `--symmetric` e a proveniência só ganha a linha de mudança nesse caso.

const Writer = preload("res://tools/visual/ice_figure/ice_writer.gd")
const Palette = preload("res://tools/visual/ice_figure/ice_palette.gd")
const Prepare = preload("res://tools/visual/ice_figure/ice_prepare.gd")
const PARTS: Array[String] = ["thigh", "calf", "foot", "ball"]
## Partes que NÃO formam um par de ossos `_l` e `_r` (vazio, osso único, o nome inteiro de um osso, osso que não existe).
const NO_PAIR: PackedStringArray = ["", "root", "Head", "thigh_l", "nao_existe"]
const CLIPS: PackedStringArray = ["idle", "walk"]
const SAMPLES_PER_SECOND: float = 30.0
const DIR: String = "res://figuras_de_teste/"
const ID: String = "figura"
const BODY_M: float = 1.8
const MAX_REASON_CHARS: int = 400
## [HIP] Os limites, em graus. Medido no corpo masculino: a coxa média esquerda e a direita do walk diferem 25 graus sem a opção (-3,4 e 21,6) e 2,1 com ela (10,2 e 8,1; o que resta é a assimetria da própria animação da UAL, cuja coxa direita balança 69 graus e a esquerda 58); a média das duas coxas não muda (9,1 antes e depois), a amplitude muda 0,2 e a soma das médias laterais (-12,3 e 11,9) fica a 0,4 de zero. A canela (do joelho ao tornozelo) difere 11,8 graus sem a opção (-30,4 e -18,7) e 2,1 com ela (-23,3 e -25,4), com a amplitude de 74 graus nos dois lados antes e depois.
const MIN_DEFECT_DEG: float = 10.0
const SYMMETRY_TOLERANCE_DEG: float = 3.0
const MEAN_TOLERANCE_DEG: float = 0.5
const SWING_TOLERANCE_DEG: float = 1.0
const LATERAL_TOLERANCE_DEG: float = 1.0
## [HIP] A tolerância do reflexo (comprimento do vetor) e da coxa média da figura contra a do retarget (graus).
const REFLECTION_TOLERANCE: float = 0.00001
const FIGURE_TOLERANCE_DEG: float = 0.1
## O caso SINTÉTICO das quatro partes (em graus): por parte, [flexão (giro em x) do esquerdo, flexão do direito, abdução (giro em z) do esquerdo]; o direito leva a abdução ESPELHADA (a oposta). Os ossos nascem sem pai, com repouso espelhado (giro em z de 10 graus, um para cada lado), e cada parte tem uma flexão média (10, 5, -15 e 25) e uma abdução (20, 12, -8 e 30) diferentes das outras. O erro de um reflexo que falta na média é uma abdução que some; o de uma parte pulada, ou do laço que para, é a referência que fica como era.
const REST_SPREAD_DEG: float = 10.0
const SYNTHETIC: Dictionary = {"thigh": [30.0, -10.0, 20.0], "calf": [-25.0, 35.0, 12.0], "foot": [15.0, -45.0, -8.0], "ball": [50.0, 0.0, 30.0]}
const SIGNS: Dictionary[String, float] = {"l": 1.0, "r": -1.0}
const ROTATION_TOLERANCE: float = 0.00001

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


## A pose de bind SIMÉTRICA: o repouso em T (mundial) do esqueleto.
func _rest(skeleton: Skeleton3D) -> Dictionary[String, Transform3D]:
	var rest: Dictionary[String, Transform3D] = {}
	for bone: int in skeleton.get_bone_count():
		rest[skeleton.get_bone_name(bone)] = skeleton.get_bone_global_rest(bone)
	return rest


func _options(parts: PackedStringArray, bind: Dictionary[String, Transform3D]) -> CharacterRetarget.Options:
	var options: CharacterRetarget.Options = CharacterRetarget.Options.new()
	options.bind_pose = bind
	options.symmetric_reference = parts
	return options


func _library(skeleton: Skeleton3D, options: CharacterRetarget.Options) -> AnimationLibrary:
	var clips: Dictionary = {}
	for key: String in CLIPS:
		clips[key] = _catalog.animations()[key]
	return CharacterRetarget.library_for(skeleton, clips, options)


## Tudo o que define as trilhas de um clipe (caminho, tipo e cada chave), para comparar por valor.
func _keys(clip: Animation) -> Array:
	var keys: Array = [clip.length, clip.loop_mode]
	for track: int in clip.get_track_count():
		keys.append([clip.track_get_path(track), clip.track_get_type(track)])
		for key: int in clip.track_get_key_count(track):
			keys.append([clip.track_get_key_time(track, key), clip.track_get_key_value(track, key)])
	return keys


func _pose(skeleton: Skeleton3D, clip: Animation, time: float) -> void:
	for track: int in clip.get_track_count():
		var bone: int = skeleton.find_bone(clip.track_get_path(track).get_concatenated_subnames())
		if bone >= 0 and clip.track_get_type(track) == Animation.TYPE_ROTATION_3D:
			skeleton.set_bone_pose_rotation(bone, clip.rotation_track_interpolate(track, time))
		elif bone >= 0 and clip.track_get_type(track) == Animation.TYPE_POSITION_3D:
			skeleton.set_bone_pose_position(bone, clip.position_track_interpolate(track, time))
	skeleton.force_update_all_bone_transforms()


## O ângulo (graus) do segmento de `top` a `bottom`: no plano sagital (0 = vertical para baixo, positivo para a frente) ou, com `lateral`, no frontal (positivo para o +x).
func _angle(top: Vector3, bottom: Vector3, lateral: bool = false) -> float:
	var segment: Vector3 = bottom - top
	return rad_to_deg(atan2(segment.x if lateral else segment.z, -segment.y))


## Por lado ("l" e "r") e por quadro a 30 por segundo de `clip`, os ângulos da coxa (do quadril ao joelho) e da canela (do joelho ao tornozelo); devolve {lado: [coxa: média sagital, média frontal e amplitude sagital; canela: média sagital e amplitude sagital]}.
func _gait(skeleton: Skeleton3D, clip: Animation) -> Dictionary:
	var gait: Dictionary = {}
	for side: String in SIGNS:
		var thigh: Array[float] = []
		var lateral: Array[float] = []
		var shin: Array[float] = []
		for step: int in int(ceil(clip.length * SAMPLES_PER_SECOND)) + 1:
			_pose(skeleton, clip, minf(step / SAMPLES_PER_SECOND, clip.length))
			var hip: Vector3 = skeleton.get_bone_global_pose(skeleton.find_bone("thigh_" + side)).origin
			var knee: Vector3 = skeleton.get_bone_global_pose(skeleton.find_bone("calf_" + side)).origin
			var ankle: Vector3 = skeleton.get_bone_global_pose(skeleton.find_bone("foot_" + side)).origin
			thigh.append(_angle(hip, knee))
			lateral.append(_angle(hip, knee, true))
			shin.append(_angle(knee, ankle))
		gait[side] = [_mean(thigh), _mean(lateral), thigh.max() - thigh.min(), _mean(shin), shin.max() - shin.min()]
	return gait


func _mean(values: Array[float]) -> float:
	var total: float = 0.0
	for value: float in values:
		total += value
	return total / values.size()


## A parte vetorial de a x b^-1: 0 se as rotações são a mesma (q e -q também).
func _apart(a: Quaternion, b: Quaternion) -> float:
	var difference: Quaternion = a * b.inverse()
	return Vector3(difference.x, difference.y, difference.z).length()


func _load_scene(path: String) -> Node:
	return _scenes[path].instantiate() if _scenes.has(path) else null


func _read_text(path: String) -> String:
	return _texts[path] if _texts.has(path) else ""


## A figura sintética em memória (o clone do esqueleto masculino, um triângulo preso à pélvis e metadados com a pose de bind simétrica) com `extra` trocando ou acrescentando campos dos metadados; devolve a raiz, ou null com o motivo em `_failure`.
func _build(extra: Dictionary) -> Node3D:
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
	var meta: Dictionary = {"version": 1, "reference_clip": "idle", "body_m": BODY_M, "height_m": BODY_M, "bind_pose": poses}
	meta.merge(extra, true)
	_scenes[DIR + ID + ".scn"] = packed
	_texts[DIR + ID + ".json"] = JSON.stringify(meta)
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CharacterCatalog.DEFAULT_PATH))
	data["figures"] = [{"id": ID, "scene": DIR + ID + ".scn", "meta": DIR + ID + ".json"}]
	var figure: CharacterFigure = CharacterFigure.new(_load_scene, _read_text)
	var built: Node3D = figure.build(CharacterCatalog.from_json(JSON.stringify(data), "catalogo_de_teste.json").catalog, ID)
	_failure = figure.failure
	return add_child_autofree(built) if built != null else null


func _walk_of(root: Node3D) -> Animation:
	return (root.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer).get_animation("walk")


## O delta do quadro 0 de um osso do caso SINTÉTICO (a rotação mundial que ele acrescenta ao repouso): a abdução (giro em z, de sinal oposto no direito) e depois a flexão (giro em x), a de cada lado ou, com `averaged`, a média das duas.
func _delta(part: String, side: String, averaged: bool) -> Quaternion:
	var angles: Array = SYNTHETIC[part]
	var flexion: float = (angles[0] + angles[1]) / 2.0 if averaged else angles[0 if side == "l" else 1]
	return Quaternion(Vector3.BACK, deg_to_rad(SIGNS[side] * angles[2])) * Quaternion(Vector3.RIGHT, deg_to_rad(flexion))


## Monta o caso SINTÉTICO (os ossos `<parte>_l` e `<parte>_r` de SYNTHETIC, sem pai, com o repouso espelhado e o quadro 0 da referência com o delta de cada lado), retargeta um clipe vazio (o repouso) com `parts` simetrizadas e devolve, por osso, a referência que ficou: o inverso da saída (um osso no repouso sai como o inverso do delta da referência).
func _references(parts: PackedStringArray) -> Dictionary[String, Quaternion]:
	var skeleton: Skeleton3D = add_child_autofree(Skeleton3D.new())
	var reference: Animation = Animation.new()
	var options: CharacterRetarget.Options = CharacterRetarget.Options.new()
	options.symmetric_reference = parts
	for part: String in SYNTHETIC:
		for side: String in SIGNS:
			var bone_name: String = "%s_%s" % [part, side]
			var rest: Quaternion = Quaternion(Vector3.BACK, deg_to_rad(SIGNS[side] * REST_SPREAD_DEG))
			skeleton.add_bone(bone_name)
			skeleton.set_bone_rest(skeleton.find_bone(bone_name), Transform3D(Basis(rest), Vector3.ZERO))
			var track: int = reference.add_track(Animation.TYPE_ROTATION_3D)
			reference.track_set_path(track, NodePath("Skeleton3D:" + bone_name))
			reference.rotation_track_insert_key(track, 0.0, _delta(part, side, false) * rest)
			options.bind_pose[bone_name] = Transform3D.IDENTITY
	var rested: Animation = CharacterRetarget.new(skeleton, skeleton, options, reference).retarget(Animation.new())
	var references: Dictionary[String, Quaternion] = {}
	for bone_name: String in options.bind_pose:
		references[bone_name] = rested.rotation_track_interpolate(rested.find_track(NodePath("Skeleton3D:" + bone_name), Animation.TYPE_ROTATION_3D), 0.0).inverse()
	return references


## Confere o caso SINTÉTICO com `listed` simetrizadas: cada osso de uma parte da lista fica com a referência média (a flexão média e a abdução do lado mantida) e os outros, com a de antes.
func _assert_references(listed: PackedStringArray) -> void:
	var references: Dictionary[String, Quaternion] = _references(listed)
	for part: String in SYNTHETIC:
		for side: String in SIGNS:
			assert_lt(_apart(references["%s_%s" % [part, side]], _delta(part, side, listed.has(part))), ROTATION_TOLERANCE, "%s_%s com a lista %s: %s" % [part, side, listed, "a média" if listed.has(part) else "a de antes"])


func test_the_option_makes_the_walk_thighs_and_shins_symmetric_without_changing_their_swing() -> void:
	var skeleton: Skeleton3D = _male_skeleton()
	var bind: Dictionary[String, Transform3D] = _rest(skeleton)
	var plain: Dictionary = _gait(skeleton, _library(skeleton, _options(PackedStringArray(), bind)).get_animation("walk"))
	var fixed: Dictionary = _gait(skeleton, _library(skeleton, _options(PackedStringArray(PARTS), bind)).get_animation("walk"))
	assert_gt(absf(plain["l"][0] - plain["r"][0]), MIN_DEFECT_DEG, "sem a opção, a coxa média esquerda %.1f e a direita %.1f graus (o defeito)" % [plain["l"][0], plain["r"][0]])
	assert_lt(absf(fixed["l"][0] - fixed["r"][0]), SYMMETRY_TOLERANCE_DEG, "com a opção, a coxa média esquerda %.1f e a direita %.1f graus" % [fixed["l"][0], fixed["r"][0]])
	assert_gt(absf(plain["l"][3] - plain["r"][3]), MIN_DEFECT_DEG, "sem a opção, a canela média esquerda %.1f e a direita %.1f graus (o defeito)" % [plain["l"][3], plain["r"][3]])
	assert_lt(absf(fixed["l"][3] - fixed["r"][3]), SYMMETRY_TOLERANCE_DEG, "com a opção, a canela média esquerda %.1f e a direita %.1f graus" % [fixed["l"][3], fixed["r"][3]])
	assert_lt(absf(fixed["l"][4] - fixed["r"][4]), SWING_TOLERANCE_DEG, "com a opção, a amplitude da canela esquerda %.1f e da direita %.1f graus" % [fixed["l"][4], fixed["r"][4]])
	assert_almost_eq((fixed["l"][0] + fixed["r"][0]) / 2.0, (plain["l"][0] + plain["r"][0]) / 2.0, MEAN_TOLERANCE_DEG, "a média das duas coxas não muda: a referência comum é a média das de antes")
	assert_lt(absf(fixed["l"][1] + fixed["r"][1]), LATERAL_TOLERANCE_DEG, "a simetria lateral: %.1f e %.1f graus" % [fixed["l"][1], fixed["r"][1]])
	for side: String in SIGNS:
		assert_almost_eq(float(fixed[side][2]), float(plain[side][2]), SWING_TOLERANCE_DEG, side + ": a amplitude da coxa não muda")
		assert_almost_eq(float(fixed[side][4]), float(plain[side][4]), SWING_TOLERANCE_DEG, side + ": a amplitude da canela não muda")
	for key: String in CLIPS:
		assert_eq(_keys(_library(skeleton, _options(PackedStringArray(PARTS), bind)).get_animation(key)), _keys(_library(skeleton, _options(PackedStringArray(PARTS), bind)).get_animation(key)), key + ": as mesmas opções, as mesmas trilhas")


func test_the_reflection_turns_a_rotation_into_the_rotation_of_the_reflected_vectors() -> void:
	var turn: Quaternion = Quaternion(Vector3(0.3, 0.5, 0.8).normalized(), 1.1)
	var vector: Vector3 = Vector3(0.4, -0.7, 0.2)
	var turned: Vector3 = turn * vector
	assert_lt((CharacterRetarget._mirrored(turn) * Vector3(-vector.x, vector.y, vector.z) - Vector3(-turned.x, turned.y, turned.z)).length(), REFLECTION_TOLERANCE)


func test_every_listed_part_gets_its_own_mean_keeping_the_lateral_components_and_the_others_stay() -> void:
	_assert_references(PackedStringArray(PARTS))
	_assert_references(PackedStringArray(["calf", "ball"]))


func test_a_part_without_a_pair_does_not_stop_the_valid_parts_after_it() -> void:
	_assert_references(PackedStringArray(["nao_existe", "thigh", "calf"]))


func test_an_ineffective_option_leaves_the_tracks_as_they_were() -> void:
	var skeleton: Skeleton3D = _male_skeleton()
	var bind: Dictionary[String, Transform3D] = _rest(skeleton)
	var plain: AnimationLibrary = _library(skeleton, _options(PackedStringArray(), bind))
	var unpaired: AnimationLibrary = _library(skeleton, _options(NO_PAIR, bind))
	var unbound_plain: AnimationLibrary = _library(skeleton, _options(PackedStringArray(), {}))
	var unbound: AnimationLibrary = _library(skeleton, _options(PackedStringArray(PARTS), {}))
	for key: String in CLIPS:
		assert_eq(_keys(unpaired.get_animation(key)), _keys(plain.get_animation(key)), key + ": partes sem o par de ossos não fazem nada")
		assert_eq(_keys(unbound.get_animation(key)), _keys(unbound_plain.get_animation(key)), key + ": sem a pose de bind não há referência")


func test_the_figure_reads_the_field_and_changes_the_walk_like_the_retarget() -> void:
	var plain: Dictionary = _gait(CharacterSceneLoader.skeleton_of(_build({})), _walk_of(_build({})))
	var fixed_root: Node3D = _build({"symmetric_reference": PARTS})
	var fixed: Dictionary = _gait(CharacterSceneLoader.skeleton_of(fixed_root), _walk_of(fixed_root))
	var skeleton: Skeleton3D = _male_skeleton()
	var direct: Dictionary = _gait(skeleton, _library(skeleton, _options(PackedStringArray(PARTS), _rest(skeleton))).get_animation("walk"))
	assert_gt(absf(plain["l"][0] - plain["r"][0]), MIN_DEFECT_DEG, "sem o campo a figura tem o defeito: %.1f e %.1f graus" % [plain["l"][0], plain["r"][0]])
	assert_lt(absf(fixed["l"][0] - fixed["r"][0]), SYMMETRY_TOLERANCE_DEG, "com o campo, a coxa média esquerda %.1f e a direita %.1f graus" % [fixed["l"][0], fixed["r"][0]])
	assert_lt(absf(fixed["l"][3] - fixed["r"][3]), SYMMETRY_TOLERANCE_DEG, "com o campo, a canela média esquerda %.1f e a direita %.1f graus" % [fixed["l"][3], fixed["r"][3]])
	for side: String in SIGNS:
		for index: int in [0, 3]:
			assert_almost_eq(float(fixed[side][index]), float(direct[side][index]), FIGURE_TOLERANCE_DEG, "%s: a figura anda como o retarget com as mesmas opções (coxa e canela)" % side)


func test_an_absent_or_empty_field_builds_the_same_figure_and_repeated_parts_change_nothing() -> void:
	var absent: Node3D = _build({})
	var empty: Node3D = _build({"symmetric_reference": []})
	var limit: Array = []
	limit.resize(CharacterFigure.MAX_SYMMETRIC_PARTS)
	limit.fill("thigh")
	var repeated: Node3D = _build({"symmetric_reference": limit})
	assert_not_null(repeated, "o limite de partes passa: " + _failure)
	assert_eq(_keys(_walk_of(empty)), _keys(_walk_of(absent)), "lista vazia = campo ausente")
	assert_eq(_keys(_walk_of(repeated)), _keys(_walk_of(_build({"symmetric_reference": ["thigh"]}))), "a mesma parte repetida vale uma vez")
	assert_ne(_keys(_walk_of(_build({"symmetric_reference": PARTS}))), _keys(_walk_of(absent)), "com o campo as poses mudam")


func test_every_invalid_field_returns_null_with_the_field_in_a_short_reason() -> void:
	var too_many: Array = []
	too_many.resize(CharacterFigure.MAX_SYMMETRIC_PARTS + 1)
	too_many.fill("thigh")
	var bad: Dictionary = {"numero": 1.0, "texto": "thigh", "nulo": null, "objeto": {"thigh": 1.0}, "item_numero": [1.0], "item_nulo": [null], "item_lista": [["thigh"]], "demais": too_many, "misturado": ["thigh", "nao_existe"]}
	for part: String in NO_PAIR:
		bad["parte_" + part] = [part]
	for case_name: String in bad:
		assert_null(_build({"symmetric_reference": bad[case_name]}), case_name + ": inválido")
		assert_true(_failure.contains("symmetric_reference") and _failure.length() < MAX_REASON_CHARS, "%s: o motivo cita o campo e é curto: %s" % [case_name, _failure])


func test_the_prepare_tool_writes_the_field_only_with_the_flag_and_the_provenance_gains_one_line() -> void:
	assert_eq(Prepare._symmetric_field(PackedStringArray(["--damping", "--contact"])), {}, "sem --symmetric, nenhum campo")
	assert_eq(Prepare._symmetric_field(PackedStringArray(["--symmetric"])), {"symmetric_reference": PARTS}, "com --symmetric, as partes das pernas")
	var built: Palette.Built = Palette.Built.new()
	built.image = Image.create(8, 8, false, Image.FORMAT_RGB8)
	built.colors = PackedInt32Array([1, 2, 3])
	var plain: String = Writer.provenance("aaaa", "bbbb", built, 1.44)
	assert_eq(Writer.provenance("aaaa", "bbbb", built, 1.44, false, true), plain + "- " + Writer.SYMMETRIC_CHANGE + "\n", "só a linha da referência simétrica")
	assert_eq(Writer.provenance("aaaa", "bbbb", built, 1.44, true, true), plain + "- " + Writer.PRESENTATION_CHANGE + "\n- " + Writer.SYMMETRIC_CHANGE + "\n", "as duas linhas")
