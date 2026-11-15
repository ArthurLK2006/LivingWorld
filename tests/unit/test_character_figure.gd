extends GutTest
## ART-12, entrega 6b (2): o CharacterFigure com uma figura SINTÉTICA (nenhum ativo de terceiros): esqueleto = clone do corpo masculino do repositório, ENCOLHIDO a cerca de 1,44 m como o do Ice Warrior (o fator de escala até 1,80 m é 1,25 e não 1,00: escala ausente ou invertida não passa), pernas 25% mais curtas e pose de bind diferente do T; malha = dois triângulos com Skin. A cena (PackedScene) e o JSON de metadados existem só em MEMÓRIA e entram pelos carregadores injetáveis do `CharacterFigure`, com caminhos de mentira `res://figuras_de_teste/...`: nada toca o disco nem `user://` (AGENTS 4.16 e 9.4), então rodadas simultâneas não colidem. `build` devolve a raiz com os 65 ossos, escala para 1,80 m, pés em y = 0, sem girar, com o AnimationPlayer só com idle e walk, em laço e PARADO; as opções do retarget vêm dos metadados (o quadro 0 do idle reproduz o bind; o pé mais baixo fica a 1 cm do bind no idle e no walk); `build` repetido e `duplicate()` animam igual; cada falha (figura fora do catálogo, cena ausente (o carregador devolve null, sem erro do motor) ou com AnimationPlayer próprio, metadados ausentes, JSON quebrado, campo inválido, 64 ossos, sem Skin, osso da pose de bind ausente, zerado, não finito ou com 11 números, clipe de referência fora de idle e walk) devolve null com o motivo curto e sem vazar nó; os carregadores PADRÃO só leem arquivos do repositório.

const DIR: String = "res://figuras_de_teste/"
const REAL_JSON: String = "res://tests/unit/support/character_catalog_ok.json"
const ID: String = "figura"
const GOOD_ID: String = "boa"
const BODY_M: float = 1.8
const BONES: int = 65
const CLIPS: Array[String] = ["idle", "walk"]
const SHORT_TURNED: Dictionary = {"legs": 0.75, "turned": true}
const LEG_BONES: PackedStringArray = ["calf_l", "calf_r", "foot_l", "foot_r"]
const BIND_AXIS: Vector3 = Vector3(0.3, 0.5, 0.8)
const BIND_TURNS: Dictionary[String, float] = {"upperarm_l": 1.1, "upperarm_r": -0.9, "thigh_l": 0.25, "thigh_r": -0.25, "spine_02": 0.2}
## [HIP] O esqueleto sintético, de 1,6 m na cabeça, é multiplicado por isto para a malha ter cerca de 1,44 m (a do Ice Warrior), e o fator de escala mínimo que a figura precisa ter (o do Ice é 1,25).
const SHRINK: float = 0.775
const MIN_SCALE: float = 1.2
## Os ossos que a malha sintética segue (um triângulo em cada; o índice na pele é a posição aqui) e o tamanho do triângulo.
const SKINNED_BONES: PackedStringArray = ["pelvis", "Head"]
const TRIANGLE_M: float = 0.2
const TRIANGLE_VERTICES: int = 3
const SAMPLES_PER_SECOND: float = 30.0
const WALK_TIME: float = 0.4
## [HIP] 0,01 cm (posição e altura), 1 cm (pé a partir do bind), 0,0001 (parte vetorial do quaternion), o giro mínimo (rad) do bind sintético em relação ao T e o maior motivo de falha (caracteres).
const SIZE_TOLERANCE_M: float = 0.0001
const GROUND_TOLERANCE_M: float = 0.01
const ROTATION_TOLERANCE: float = 0.0001
const MIN_BIND_TURN: float = 0.5
const MAX_REASON_CHARS: int = 400
## O osso cuja pose de bind os casos de falha estragam (uma base zerada ou singular, ausente, com 11 ou 13 números ou com infinito) e a base zerada.
const BROKEN_BONE: String = "calf_l"
const ZERO_BASIS_POSE: Array = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.1, 0.2, 0.3]
const SINGULAR_BASIS_POSE: Array = [1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.1, 0.2, 0.3]
## O `stringify` escreve o infinito como 1e99999, que o motor lê com aviso ("Exponent too high"): o caso "infinito" grava o texto "infinito" no lugar do número e o troca por este literal, que passa do maior real (1,8e308) e vira infinito sem aviso.
const INFINITE_LITERAL: String = "1e309"
## Cada caso de falha: [id da figura, trecho esperado do motivo].
const FAILURES: Array = [
	["nao_existe", "não está no catálogo"], ["sem_cena", "não existe"], ["sem_meta", "arquivo não encontrado"], ["quebrado", "JSON inválido"],
	["sem_osso", "ossos do catálogo"], ["armadura", "filho da raiz"], ["sem_skin", "Skin"], ["com_player", "AnimationPlayer"], ["versao", "version"], ["altura", "height_m"],
	["sem_bind", "inválida: 65"], ["osso_zerado", BROKEN_BONE], ["osso_faltando", BROKEN_BONE], ["onze_numeros", BROKEN_BONE], ["treze_numeros", BROKEN_BONE], ["base_singular", BROKEN_BONE], ["infinito", BROKEN_BONE], ["jog", "retarget falhou"],
]

## Os "arquivos" da figura, só em memória: caminho -> cena empacotada e caminho -> texto dos metadados.
var _scenes: Dictionary[String, PackedScene] = {}
var _texts: Dictionary[String, String] = {}


func before_each() -> void:
	_scenes.clear()
	_texts.clear()


## Os carregadores injetados no CharacterFigure: o caminho que não está na memória não existe (null e "").
func _load_scene(path: String) -> Node:
	return _scenes[path].instantiate() if _scenes.has(path) else null


func _read_text(path: String) -> String:
	return _texts[path] if _texts.has(path) else ""


func _figure() -> CharacterFigure:
	return CharacterFigure.new(_load_scene, _read_text)


func _catalog(rows: Array) -> CharacterCatalog:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CharacterCatalog.DEFAULT_PATH))
	data["figures"] = rows
	var loaded: CharacterCatalog.LoadResult = CharacterCatalog.from_json(JSON.stringify(data), "catalogo_de_teste.json")
	assert_true(loaded.result.ok, loaded.result.message)
	return loaded.catalog


func _male_skeleton() -> Skeleton3D:
	var look: CharacterAppearance = CharacterAppearance.new()
	look.body_id = "male_a"
	look.outfit_id = "peasant_m"
	var assembler: CharacterAssembler = add_child_autofree(CharacterAssembler.new())
	assert_true(assembler.build(look, CharacterCatalog.from_file().catalog), "montou o corpo masculino")
	return CharacterSceneLoader.skeleton_of(assembler)


## O clone do esqueleto masculino com os primeiros `bones` ossos, encolhido por SHRINK e com a perna (panturrilha e pé) multiplicada por `leg_scale`; solto (sem pai), com o nome da cena gravada.
func _clone(leg_scale: float, bones: int) -> Skeleton3D:
	var source: Skeleton3D = _male_skeleton()
	var clone: Skeleton3D = Skeleton3D.new()
	clone.name = CharacterRetarget.SKELETON_NODE
	for bone: int in bones:
		clone.add_bone(source.get_bone_name(bone))
	for bone: int in bones:
		var rest: Transform3D = source.get_bone_rest(bone)
		clone.set_bone_parent(bone, source.get_bone_parent(bone))
		clone.set_bone_rest(bone, Transform3D(rest.basis, rest.origin * SHRINK * (leg_scale if LEG_BONES.has(clone.get_bone_name(bone)) else 1.0)))
	clone.reset_bone_poses()
	return clone


func _globals(skeleton: Skeleton3D) -> Dictionary[String, Transform3D]:
	skeleton.force_update_all_bone_transforms()
	var globals: Dictionary[String, Transform3D] = {}
	for bone: int in skeleton.get_bone_count():
		globals[skeleton.get_bone_name(bone)] = skeleton.get_bone_global_pose(bone)
	return globals


## Dois triângulos com a malha na pose de bind: um do chão (y = 0) até a pélvis, preso a ela, e um na cabeça, preso a ela.
func _mesh(bind: Dictionary[String, Transform3D]) -> ArrayMesh:
	var pelvis: Vector3 = bind["pelvis"].origin
	var head: Vector3 = bind["Head"].origin
	var corners: Array[Vector3] = [Vector3(pelvis.x, 0.0, pelvis.z), pelvis, Vector3(pelvis.x + TRIANGLE_M, 0.0, pelvis.z), head, head + Vector3.RIGHT * TRIANGLE_M, head + Vector3.UP * TRIANGLE_M]
	var bones: PackedInt32Array = PackedInt32Array()
	var weights: PackedFloat32Array = PackedFloat32Array()
	for index: int in corners.size():
		bones.append_array([int(index >= TRIANGLE_VERTICES), 0, 0, 0])
		weights.append_array([1.0, 0.0, 0.0, 0.0])
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array(corners)
	arrays[Mesh.ARRAY_BONES] = bones
	arrays[Mesh.ARRAY_WEIGHTS] = weights
	var mesh: ArrayMesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _skin(bind: Dictionary[String, Transform3D]) -> Skin:
	var skin: Skin = Skin.new()
	for bone_name: String in SKINNED_BONES:
		skin.add_named_bind(bone_name, bind[bone_name].affine_inverse())
	return skin


func _pack(skeleton: Skeleton3D, mesh: ArrayMesh, skin: Skin, with_player: bool) -> PackedScene:
	var root: Node3D = Node3D.new()
	var holder: MeshInstance3D = MeshInstance3D.new()
	holder.mesh = mesh
	holder.skin = skin
	root.add_child(skeleton)
	skeleton.add_child(holder)
	holder.skeleton = NodePath("..")
	skeleton.owner = root
	holder.owner = root
	if with_player:
		var player: AnimationPlayer = AnimationPlayer.new()
		root.add_child(player)
		player.owner = root
	var packed: PackedScene = PackedScene.new()
	packed.pack(root)
	root.free()
	return packed


## O JSON de metadados no formato da ferramenta da 6c (com campos de proveniência que o `build` ignora).
func _meta_of(bind: Dictionary[String, Transform3D], mesh: ArrayMesh) -> Dictionary:
	var poses: Dictionary = {}
	for bone_name: String in bind:
		var numbers: Array = []
		for vector: Vector3 in [bind[bone_name].basis.x, bind[bone_name].basis.y, bind[bone_name].basis.z, bind[bone_name].origin]:
			numbers.append_array([vector.x, vector.y, vector.z])
		poses[bone_name] = numbers
	return {"version": 1, "figure": "sintetica", "credit": "teste", "reference_clip": "idle", "body_m": BODY_M, "height_m": mesh.get_aabb().end.y, "bind_pose": poses, "triangles": 2}


## Registra a figura sintética `figure_name` em memória (a cena e o JSON) e devolve a linha do catálogo. `variant`: `legs` (fator da perna), `turned` (bind diferente do T), `bones` (quantos ossos), `skeleton` (nome do nó do esqueleto), `skinned` (com Skin), `player` (com AnimationPlayer) e `meta` (campos que trocam os do JSON).
func _write(figure_name: String, variant: Dictionary = {}) -> Dictionary:
	var skeleton: Skeleton3D = _clone(variant.get("legs", 1.0), variant.get("bones", BONES))
	skeleton.name = variant.get("skeleton", skeleton.name)
	if variant.get("turned", false):
		for bone_name: String in BIND_TURNS:
			var bone: int = skeleton.find_bone(bone_name)
			skeleton.set_bone_pose_rotation(bone, skeleton.get_bone_rest(bone).basis.get_rotation_quaternion() * Quaternion(BIND_AXIS.normalized(), BIND_TURNS[bone_name]))
	var bind: Dictionary[String, Transform3D] = _globals(skeleton)
	var mesh: ArrayMesh = _mesh(bind)
	var meta: Dictionary = _meta_of(bind, mesh)
	meta.merge(variant.get("meta", {}), true)
	var row: Dictionary = {"id": figure_name, "scene": DIR + figure_name + ".scn", "meta": DIR + figure_name + ".json"}
	_scenes[row["scene"]] = _pack(skeleton, mesh, _skin(bind) if variant.get("skinned", true) else null, variant.get("player", false))
	_texts[row["meta"]] = JSON.stringify(meta)
	return row


## A figura boa `figure_name` com a pose de bind estragada por `edit`, que recebe o osso -> 12 números dos metadados.
func _broken_poses(figure_name: String, edit: Callable) -> Dictionary:
	var row: Dictionary = _write(figure_name)
	var meta: Dictionary = JSON.parse_string(_texts[row["meta"]])
	edit.call(meta["bind_pose"])
	_texts[row["meta"]] = JSON.stringify(meta)
	return row


func _built(catalog: CharacterCatalog, id: String) -> Node3D:
	var figure: CharacterFigure = _figure()
	var root: Node3D = figure.build(catalog, id)
	assert_not_null(root, "build(%s): %s" % [id, figure.failure])
	return add_child_autofree(root)


func _player_of(root: Node3D) -> AnimationPlayer:
	return root.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer


func _pose(skeleton: Skeleton3D, clip: Animation, time: float) -> void:
	for track: int in clip.get_track_count():
		var bone: int = skeleton.find_bone(clip.track_get_path(track).get_concatenated_subnames())
		if bone >= 0 and clip.track_get_type(track) == Animation.TYPE_ROTATION_3D:
			skeleton.set_bone_pose_rotation(bone, clip.rotation_track_interpolate(track, time))
		elif bone >= 0 and clip.track_get_type(track) == Animation.TYPE_POSITION_3D:
			skeleton.set_bone_pose_position(bone, clip.position_track_interpolate(track, time))
	skeleton.force_update_all_bone_transforms()


## A parte vetorial de a x b^-1: 0 se as rotações são a mesma (q e -q também).
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


## As poses mundiais dos ossos depois de tocar `key` pelo AnimationPlayer da própria figura e avançar `time`.
func _played(root: Node3D, key: String, time: float) -> Dictionary[String, Transform3D]:
	var player: AnimationPlayer = _player_of(root)
	player.play(key)
	player.advance(time)
	return _globals(CharacterSceneLoader.skeleton_of(root))


func test_build_returns_the_scaled_figure_with_idle_and_walk_in_loop_and_not_playing() -> void:
	var catalog: CharacterCatalog = _catalog([_write(ID, SHORT_TURNED)])
	var figure: CharacterFigure = _figure()
	var root: Node3D = add_child_autofree(figure.build(catalog, ID))
	assert_eq(figure.failure, "")
	assert_eq(CharacterSceneLoader.skeleton_of(root).get_bone_count(), BONES)
	var players: Array[Node] = root.find_children("*", "AnimationPlayer", true, false)
	assert_eq(players.size(), 1, "um AnimationPlayer, achável por find_children")
	var player: AnimationPlayer = players[0] as AnimationPlayer
	assert_eq(Array(player.get_animation_list()), CLIPS, "só idle e walk (o jog não passa pela trava de chão)")
	for key: String in CLIPS:
		assert_ne(player.get_animation(key).loop_mode, Animation.LOOP_NONE, key + " em laço")
	assert_false(player.is_playing(), "a figura nasce parada")
	assert_eq(root.scale.x, root.scale.y, "escala uniforme")
	assert_eq(root.scale.y, root.scale.z, "escala uniforme")
	assert_gt(root.scale.y, MIN_SCALE, "o fator da figura sintética (como o do Ice, 1,25) não é 1: escala ausente ou invertida não passa")
	assert_true(root.basis.orthonormalized().is_equal_approx(Basis.IDENTITY), "sem girar: a cena gravada já olha para +Z")
	var world: AABB = root.transform * CharacterSceneLoader.meshes_of(root)[0].get_aabb()
	assert_almost_eq(world.size.y, BODY_M, SIZE_TOLERANCE_M, "altura do corpo 1,80 m")
	assert_almost_eq(world.position.y, 0.0, SIZE_TOLERANCE_M, "pés em y = 0")


func test_the_retarget_options_come_from_the_metadata() -> void:
	var root: Node3D = _built(_catalog([_write(ID, SHORT_TURNED)]), ID)
	var skeleton: Skeleton3D = CharacterSceneLoader.skeleton_of(root)
	var player: AnimationPlayer = _player_of(root)
	var bind: Dictionary[String, Transform3D] = _globals(skeleton)
	var arm: int = skeleton.find_bone("upperarm_l")
	assert_gt(bind["upperarm_l"].basis.get_rotation_quaternion().angle_to(skeleton.get_bone_global_rest(arm).basis.get_rotation_quaternion()), MIN_BIND_TURN, "o bind difere do repouso em T")
	_pose(skeleton, player.get_animation("idle"), 0.0)
	var worst_position: float = 0.0
	var worst_rotation: float = 0.0
	for bone_name: String in bind:
		var pose: Transform3D = skeleton.get_bone_global_pose(skeleton.find_bone(bone_name))
		worst_position = maxf(worst_position, pose.origin.distance_to(bind[bone_name].origin))
		worst_rotation = maxf(worst_rotation, _distance(pose.basis.get_rotation_quaternion(), bind[bone_name].basis.get_rotation_quaternion()))
	assert_lt(worst_position, SIZE_TOLERANCE_M, "quadro 0 do idle: ossos na posição do bind")
	assert_lt(worst_rotation, ROTATION_TOLERANCE, "quadro 0 do idle: ossos na rotação do bind")
	for key: String in CLIPS:
		var gaps: Array[float] = _gaps(skeleton, player.get_animation(key), bind)
		assert_lt(maxf(gaps.max(), -gaps.min()), GROUND_TOLERANCE_M, key + ": com a perna 25% mais curta, o pé mais baixo fica a 1 cm do bind")


func test_build_is_deterministic_and_a_duplicate_animates_the_same() -> void:
	var catalog: CharacterCatalog = _catalog([_write(ID, SHORT_TURNED)])
	var first: Node3D = _built(catalog, ID)
	var second: Node3D = _built(catalog, ID)
	var copy: Node3D = add_child_autofree(first.duplicate())
	var still: Dictionary[String, Transform3D] = _globals(CharacterSceneLoader.skeleton_of(second))
	for key: String in CLIPS:
		assert_true(_same_clip(_player_of(first).get_animation(key), _player_of(second).get_animation(key)), key + ": dois builds, mesmas trilhas")
	var walked: Dictionary[String, Transform3D] = _played(first, "walk", WALK_TIME)
	assert_ne(walked, still, "o AnimationPlayer move o esqueleto da figura")
	assert_eq(_played(second, "walk", WALK_TIME), walked, "build repetido anima igual")
	assert_eq(_played(copy, "walk", WALK_TIME), walked, "duplicate() anima igual")
	assert_eq(copy.scale, first.scale, "o duplicate mantém a escala")


func test_every_failure_returns_null_with_a_short_readable_reason_and_leaks_nothing() -> void:
	var good: Dictionary = _write(GOOD_ID)
	_texts[DIR + "quebrado.json"] = "{ isso nao e json"
	var catalog: CharacterCatalog = _catalog([
		good,
		{"id": "sem_cena", "scene": DIR + "ausente.scn", "meta": good["meta"]},
		{"id": "sem_meta", "scene": good["scene"], "meta": DIR + "ausente.json"},
		{"id": "quebrado", "scene": good["scene"], "meta": DIR + "quebrado.json"},
		_write("sem_osso", {"bones": BONES - 1}),
		_write("armadura", {"skeleton": "Armature"}),
		_write("sem_skin", {"skinned": false}),
		_write("com_player", {"player": true}),
		_write("versao", {"meta": {"version": 2}}),
		_write("altura", {"meta": {"height_m": 0.0}}),
		_write("sem_bind", {"meta": {"bind_pose": {}}}),
		_broken_poses("osso_zerado", func(poses: Dictionary) -> void: poses[BROKEN_BONE] = ZERO_BASIS_POSE),
		_broken_poses("osso_faltando", func(poses: Dictionary) -> void: poses.erase(BROKEN_BONE)),
		_broken_poses("onze_numeros", func(poses: Dictionary) -> void: poses[BROKEN_BONE].pop_back()),
		_broken_poses("treze_numeros", func(poses: Dictionary) -> void: poses[BROKEN_BONE].append(0.0)),
		_broken_poses("base_singular", func(poses: Dictionary) -> void: poses[BROKEN_BONE] = SINGULAR_BASIS_POSE),
		_broken_poses("infinito", func(poses: Dictionary) -> void: poses[BROKEN_BONE][0] = "infinito"),
		_write("jog", {"meta": {"reference_clip": "jog"}}),
	])
	_texts[DIR + "infinito.json"] = _texts[DIR + "infinito.json"].replace("\"infinito\"", INFINITE_LITERAL)
	_built(catalog, GOOD_ID)
	for spec: Array in FAILURES:
		var figure: CharacterFigure = _figure()
		assert_null(figure.build(catalog, spec[0]), spec[0])
		assert_string_contains(figure.failure, spec[1])
		assert_lt(figure.failure.length(), MAX_REASON_CHARS, spec[0] + ": o motivo é curto")
	var empty: CharacterFigure = _figure()
	assert_null(empty.build(null, ID), "sem catálogo")
	assert_false(empty.failure.is_empty())
	add_child_autofree(empty.build(catalog, GOOD_ID))
	assert_eq(empty.failure, "", "um build que dá certo limpa o motivo da falha anterior")
	assert_no_new_orphans()


func test_the_default_loaders_only_read_repository_files() -> void:
	var good: Dictionary = _write(GOOD_ID)
	var real_hair: String = CharacterCatalog.from_file().catalog.hair_for("male")[0]["scene"]
	var catalog: CharacterCatalog = _catalog([
		{"id": "cena_real", "scene": real_hair, "meta": REAL_JSON},
		{"id": "cena_ausente", "scene": DIR + "ausente.scn", "meta": REAL_JSON},
		{"id": "meta_real", "scene": good["scene"], "meta": REAL_JSON},
		{"id": "meta_ausente", "scene": good["scene"], "meta": DIR + "ausente.json"},
	])
	var default_loaders: CharacterFigure = CharacterFigure.new()
	assert_null(default_loaders.build(catalog, "cena_real"))
	assert_string_contains(default_loaders.failure, "filho da raiz", "o carregador padrão leu a cena real do repositório")
	assert_null(default_loaders.build(catalog, "cena_ausente"))
	assert_string_contains(default_loaders.failure, "não existe")
	var default_text: CharacterFigure = CharacterFigure.new(_load_scene)
	assert_null(default_text.build(catalog, "meta_real"))
	assert_string_contains(default_text.failure, "reference_clip", "o leitor padrão leu o JSON real do repositório (e ele não é metadado de figura)")
	assert_null(default_text.build(catalog, "meta_ausente"))
	assert_string_contains(default_text.failure, "arquivo não encontrado")
	assert_no_new_orphans()
