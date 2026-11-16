extends GutTest
## ART-12, entrega 7a-2: o campo OPCIONAL `locomotion` dos metadados do `CharacterFigure` (clipe -> m/s em que o pé de apoio fica colado ao chão, a tabela do `CharacterLocomotion.pick`), `CharacterFigure.locomotion_of(root)` e a opção `--locomotion` da ferramenta `ice_prepare`. A figura é sintética (o esqueleto do corpo masculino do repositório e um triângulo com Skin; nenhum ativo de terceiros, nada de art_samples/) e existe só em MEMÓRIA, pelos carregadores injetáveis, com caminhos de mentira: nada toca o disco nem `user://` (AGENTS 4.16 e 9.4). Campo válido (`walk` e `jog`, só `walk`, só `jog`): o `build` o grava no nó raiz e `locomotion_of` o devolve como cópia nova, e as animações ficam as mesmas da figura sem o campo; ausente ou `{}`: a figura sai IDÊNTICA (as trilhas, a árvore e a escala), sem metadado no nó; inválido (campo que não é objeto, chave que não é walk nem jog, valor que não é número, zero, negativo, infinito, acima de 100 m/s, `jog` sem o campo `jog` verdadeiro): `build` devolve null com UM motivo curto que cita o campo, sem vazar nó. `locomotion_of` ignora lixo no metadado (outro tipo, valor que não é número finito positivo, chave que não é walk nem jog) sem exceção. A ferramenta só grava o campo com `--locomotion`, que exige `--jog`, e a tabela dela é aceita pela figura.

const Prepare = preload("res://tools/visual/ice_figure/ice_prepare.gd")
const DIR: String = "res://figuras_de_teste/"
const ID: String = "figura"
const BODY_M: float = 1.8
const MAX_REASON_CHARS: int = 400
## As velocidades medidas do Ice Warrior (m/s) e o limite [HIP] do contrato, por extenso: se o limite do código mudar, o teste acusa.
const WALK_MPS: float = 0.73
const JOG_MPS: float = 4.1
const LIMIT_MPS: float = 100.0
## O `stringify` escreve o infinito como 1e99999, que o motor lê com aviso ("Exponent too high"): o caso "infinito" grava este texto e o troca por um literal que passa do maior real (1,8e308) e vira infinito sem aviso.
const INFINITE_MARK: String = "\"infinito\""
const INFINITE_LITERAL: String = "1e309"
## Os valores de `locomotion` que o `build` recusa (o caso e o campo inteiro). O NaN não existe em JSON (o `stringify` o troca por null, com aviso): o caso é o próprio null.
const INVALID: Array = [
	["texto", "0.73"], ["numero", 0.73], ["lista", [0.73]], ["nulo", null], ["booleano", true],
	["chave_run", {"run": 6.0}], ["chave_vazia", {"": 1.0}], ["chave_maiuscula", {"Walk": 0.73}], ["chave_idle", {"idle": 1.0}], ["uma_boa_e_uma_ruim", {"walk": 0.73, "sprint": 9.0}],
	["zero", {"walk": 0.0}], ["negativo", {"walk": -0.73}], ["nan_vira_nulo", {"walk": null}], ["infinito", {"walk": "infinito"}], ["acima_do_limite", {"walk": 100.01}],
	["valor_texto", {"walk": "0.73"}], ["valor_booleano", {"walk": true}], ["valor_lista", {"walk": [0.73]}], ["valor_objeto", {"walk": {"v": 0.73}}],
	["jog_zero", {"jog": 0.0}], ["jog_acima_do_limite", {"jog": 100.01}],
]

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


func _load_scene(path: String) -> Node:
	return _scenes[path].instantiate() if _scenes.has(path) else null


func _read_text(path: String) -> String:
	return _texts[path] if _texts.has(path) else ""


## A figura sintética em memória (o clone do esqueleto masculino, um triângulo preso à pélvis e metadados só com o obrigatório: a pose de bind, o clipe de referência e as alturas) com `extra` trocando ou acrescentando campos dos metadados; devolve a raiz, ou null com o motivo em `_failure`.
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
	for bone: int in skeleton.get_bone_count():
		var rest: Transform3D = skeleton.get_bone_global_rest(bone)
		var numbers: Array = []
		for vector: Vector3 in [rest.basis.x, rest.basis.y, rest.basis.z, rest.origin]:
			numbers.append_array([vector.x, vector.y, vector.z])
		poses[skeleton.get_bone_name(bone)] = numbers
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
	_texts[DIR + ID + ".json"] = JSON.stringify(meta).replace(INFINITE_MARK, INFINITE_LITERAL)
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CharacterCatalog.DEFAULT_PATH))
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


## Tudo o que define as trilhas de um clipe (caminho, tipo e cada chave), para comparar por valor.
func _keys(clip: Animation) -> Array:
	var keys: Array = [clip.length, clip.loop_mode]
	for track: int in clip.get_track_count():
		keys.append([clip.track_get_path(track), clip.track_get_type(track)])
		for key: int in clip.track_get_key_count(track):
			keys.append([clip.track_get_key_time(track, key), clip.track_get_key_value(track, key)])
	return keys


## A árvore de nós da figura: a classe de cada nó e o caminho por posição (o motor dá nomes automáticos, diferentes a cada cena, às malhas sem nome).
func _tree(node: Node, path: String = "") -> Array:
	var lines: Array = [[path, node.get_class()]]
	for index: int in node.get_child_count():
		lines.append_array(_tree(node.get_child(index), "%s/%d" % [path, index]))
	return lines


## Um dicionário tipado como o de `locomotion_of`, para comparar por valor com o esperado.
func _speeds(walk: float = 0.0, jog: float = 0.0) -> Dictionary[String, float]:
	var speeds: Dictionary[String, float] = {}
	if walk > 0.0:
		speeds["walk"] = walk
	if jog > 0.0:
		speeds["jog"] = jog
	return speeds


func test_the_locomotion_field_is_read_validated_and_exposed_by_locomotion_of() -> void:
	var plain: Node3D = _build({"jog": true})
	var both: Node3D = _build({"jog": true, "locomotion": {"walk": WALK_MPS, "jog": JOG_MPS}})
	assert_not_null(both, "walk e jog: " + _failure)
	assert_eq(CharacterFigure.locomotion_of(both), _speeds(WALK_MPS, JOG_MPS), "walk e jog")
	assert_true(both.has_meta(CharacterFigure.LOCOMOTION_META), "o metadado fica no nó raiz")
	assert_eq(_names_of(both), ["idle", "jog", "walk"], "o campo não acrescenta nem tira clipe")
	for key: String in _names_of(both):
		assert_eq(_keys(_player_of(both).get_animation(key)), _keys(_player_of(plain).get_animation(key)), key + ": as trilhas da figura sem o campo")
	var table: Dictionary[String, float] = CharacterFigure.locomotion_of(both)
	table.erase("walk")
	assert_eq(CharacterFigure.locomotion_of(both), _speeds(WALK_MPS, JOG_MPS), "a tabela devolvida é uma cópia nova")
	assert_eq(CharacterFigure.locomotion_of(add_child_autofree(both.duplicate())), _speeds(WALK_MPS, JOG_MPS), "a cópia da figura leva as velocidades")
	assert_eq(CharacterFigure.locomotion_of(_build({"locomotion": {"walk": WALK_MPS}})), _speeds(WALK_MPS), "só walk, sem o campo jog")
	assert_eq(CharacterFigure.locomotion_of(_build({"jog": true, "locomotion": {"jog": JOG_MPS}})), _speeds(0.0, JOG_MPS), "só jog, com o campo jog")
	assert_eq(CharacterFigure.locomotion_of(_build({"locomotion": {"walk": LIMIT_MPS}})), _speeds(LIMIT_MPS), "o limite de 100 m/s passa")
	assert_eq(CharacterFigure.locomotion_of(_build({"locomotion": {"walk": 0.001}})), _speeds(0.001), "um positivo pequeno passa")


func test_an_absent_or_empty_locomotion_builds_the_same_figure_without_metadata() -> void:
	var absent: Node3D = _build({"jog": true})
	var empty: Node3D = _build({"jog": true, "locomotion": {}})
	assert_not_null(empty, "locomotion vazio monta: " + _failure)
	assert_false(absent.has_meta(CharacterFigure.LOCOMOTION_META), "a figura sem o campo não tem metadado")
	assert_false(empty.has_meta(CharacterFigure.LOCOMOTION_META), "com o campo vazio também não")
	assert_eq(empty.get_meta_list(), absent.get_meta_list(), "os mesmos metadados do nó")
	assert_eq(CharacterFigure.locomotion_of(absent), _speeds(), "sem o campo, locomotion_of devolve {}")
	assert_eq(CharacterFigure.locomotion_of(empty), _speeds(), "com o campo vazio também")
	assert_eq(_tree(empty), _tree(absent), "a mesma árvore de nós")
	assert_eq(empty.scale, absent.scale, "a mesma escala")
	assert_eq(_names_of(empty), _names_of(absent), "os mesmos clipes")
	for key: String in _names_of(empty):
		assert_eq(_keys(_player_of(empty).get_animation(key)), _keys(_player_of(absent).get_animation(key)), key + ": as mesmas trilhas")
	assert_eq(CharacterFigure.locomotion_of(_build({"locomotion": {}})), _speeds(), "vazio sem o campo jog também monta")


func test_an_invalid_locomotion_returns_null_with_one_short_reason_and_leaks_nothing() -> void:
	for pair: Array in INVALID:
		assert_null(_build({"jog": true, "locomotion": pair[1]}), "locomotion inválido: " + String(pair[0]))
		assert_true(_failure.contains("locomotion") and _failure.length() < MAX_REASON_CHARS and not _failure.contains("\n"), "%s: o motivo cita o campo, é curto e é um só: %s" % [pair[0], _failure])
	assert_no_new_orphans()


func test_a_jog_speed_without_the_jog_field_returns_null_with_the_reason_and_leaks_nothing() -> void:
	for extra: Dictionary in [{}, {"jog": false}]:
		assert_null(_build(extra.merged({"locomotion": {"walk": WALK_MPS, "jog": JOG_MPS}})), "jog em locomotion sem o campo jog verdadeiro: %s" % str(extra))
		assert_true(_failure.contains("locomotion") and _failure.contains("jog") and _failure.length() < MAX_REASON_CHARS and not _failure.contains("\n"), "o motivo cita o campo e o jog, é curto e é um só: " + _failure)
	assert_not_null(_build({"jog": true, "locomotion": {"jog": JOG_MPS}}), "com o campo jog verdadeiro passa: " + _failure)
	assert_no_new_orphans()


func test_locomotion_of_ignores_junk_in_the_metadata_without_error() -> void:
	var node: Node3D = add_child_autofree(Node3D.new())
	assert_eq(CharacterFigure.locomotion_of(node), _speeds(), "sem metadado")
	assert_eq(CharacterFigure.locomotion_of(null), _speeds(), "sem nó")
	for junk: Variant in ["texto", 4.1, [4.1], true, 7]:  # Variant: metadados de tipos errados
		node.set_meta(CharacterFigure.LOCOMOTION_META, junk)
		assert_eq(CharacterFigure.locomotion_of(node), _speeds(), "metadado do tipo errado: " + str(junk))
	var tables: Array = [
		{"walk": "0.73", "jog": true}, {"walk": [0.73], "jog": {"v": 4.1}}, {"walk": NAN, "jog": INF}, {"walk": -INF}, {"walk": 0.0, "jog": -4.1},
		{"run": 6.0, "idle": 1.0, "Walk": 0.73, "": 2.0}, {5: 1.0, Vector2.ONE: 2.0}, {},
	]
	for table: Dictionary in tables:
		node.set_meta(CharacterFigure.LOCOMOTION_META, table)
		assert_eq(CharacterFigure.locomotion_of(node), _speeds(), "lixo ignorado: " + str(table))
	node.set_meta(CharacterFigure.LOCOMOTION_META, {"walk": 1, "jog": JOG_MPS, "run": 6.0, "sprint": "x", 5: 2.0})
	assert_eq(CharacterFigure.locomotion_of(node), _speeds(1.0, JOG_MPS), "o que serve fica (o inteiro vira real), o resto sai")
	var typed: Dictionary[String, float] = {"walk": WALK_MPS}
	node.set_meta(CharacterFigure.LOCOMOTION_META, typed)
	assert_eq(CharacterFigure.locomotion_of(node), _speeds(WALK_MPS), "um dicionário tipado também")


func test_the_prepare_tool_writes_the_locomotion_field_only_with_the_flag_and_the_flag_needs_jog() -> void:
	assert_eq(Prepare._locomotion_field(PackedStringArray(["--damping", "--contact", "--symmetric", "--jog"])), {}, "sem --locomotion, nenhum campo")
	assert_eq(Prepare._locomotion_field(PackedStringArray()), {}, "sem argumentos, nenhum campo")
	var field: Dictionary = Prepare._locomotion_field(PackedStringArray(["--jog", "--locomotion"]))
	assert_eq(field, {"locomotion": {"walk": WALK_MPS, "jog": JOG_MPS}}, "com --locomotion, a tabela medida")
	var root: Node3D = _build({"jog": true, "locomotion": field["locomotion"]})
	assert_not_null(root, "a figura aceita a tabela da ferramenta: " + _failure)
	assert_eq(CharacterFigure.locomotion_of(root), _speeds(WALK_MPS, JOG_MPS), "e a expõe")
	assert_true(Prepare._locomotion_errors(PackedStringArray(["--damping", "--contact"])).is_empty(), "sem --locomotion, nada a corrigir")
	assert_true(Prepare._locomotion_errors(PackedStringArray(["--jog", "--locomotion"])).is_empty(), "com --jog, nada a corrigir")
	var errors: PackedStringArray = Prepare._locomotion_errors(PackedStringArray(["--damping", "--locomotion"]))
	assert_eq(errors.size(), 1, "sem --jog, um só problema")
	assert_true(errors[0].contains("--jog") and errors[0].contains("--locomotion"), "a mensagem diz o que falta: " + errors[0])
