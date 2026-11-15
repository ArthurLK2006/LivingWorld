class_name CharacterFigure
extends RefCounted
## Figura de malha inteira (ART-12, entrega 6b; só apresentação): `build(catalog, id)` instancia a figura gravada (cena com um Node3D na raiz, o `Skeleton3D` de 65 ossos com os nomes da UAL como filho direto, e as `MeshInstance3D` com malha e `Skin`) e monta nela um `AnimationPlayer` com `idle` e `walk` (em laço, PARADO) pelo MESMO `CharacterRetarget` do montador, com as opções da entrega 6a vindas dos metadados: pose de bind, clipe de referência e trava de chão LIGADA. Só idle e walk, numa ÚNICA chamada de `library_for` com os clipes do catálogo FILTRADOS e as opções já inteiras (a trava vale para todos os clipes da chamada e o jog tem fase aérea). Devolve a raiz pronta: escala uniforme para o corpo de `body_m`, origem nos pés, sem girar (a cena gravada já nasce de frente para +Z). Qualquer falha (figura fora do catálogo, cena ou JSON ausente ou inválido, esqueleto sem os ossos do catálogo, malha sem `Skin`, retarget que falha) devolve null e deixa o motivo legível em `failure`, sem exceção e sem log: o chamador volta ao montador ou à cápsula (entrega 4 do contrato). O `CharacterAssembler` não muda. Contrato: docs/modules/presentation.md.
## METADADOS (o JSON do caminho `meta`, gravado pela ferramenta da entrega 6c): `version` (1), `reference_clip` (a chave do clipe cujo quadro 0 é a pose da malha: `idle`), `body_m` (altura do corpo no jogo, m), `height_m` (altura da malha no arquivo, m; a escala é `body_m / height_m`) e `bind_pose` (osso -> 12 números, os eixos x, y e z e a origem da transformação MUNDIAL do osso na pose da malha, em metros do arquivo, pés em y = 0), com todos os ossos do esqueleto. O resto (`figure`, `credit`, `bones`, `palette`, `source`, hashes...) é proveniência e o `build` ignora.

const META_VERSION: int = 1
## Os números da pose de bind de um osso: três vetores (eixos x, y e z e origem) de três componentes.
const VECTOR_SIZE: int = 3
const POSE_NUMBERS: int = 4 * VECTOR_SIZE

## O motivo da última falha de `build` ("" se deu certo).
var failure: String = ""


## A raiz pronta da figura `figure_id` do catálogo, ou null com o motivo em `failure`. Quem recebe a raiz é dono dela (free, ou add_child).
func build(catalog: CharacterCatalog, figure_id: String) -> Node3D:
	var row: Dictionary = catalog.figure(figure_id) if catalog != null else {}
	if row.is_empty():
		failure = "a figura '%s' não está no catálogo" % figure_id
		return null
	var root: Node3D = _load(String(row["scene"]))
	if root == null:
		failure = "a cena '%s' não existe ou não tem um Node3D na raiz" % row["scene"]
		return null
	failure = _assemble(root, String(row["meta"]), catalog)
	if not failure.is_empty():
		root.free()
		return null
	return root


static func _load(path: String) -> Node3D:
	var scene: Node = CharacterSceneLoader.instantiate(path)
	if scene is Node3D:
		return scene as Node3D
	if scene != null:
		scene.free()
	return null


## Confere a cena e os metadados e monta o `AnimationPlayer` e a escala em `root`; devolve o motivo da falha ("" se deu certo); numa falha não deixa nada montado em `root` (o `AnimationPlayer` só entra depois de todas as conferências).
func _assemble(root: Node3D, meta_path: String, catalog: CharacterCatalog) -> String:
	var skeleton: Skeleton3D = CharacterSceneLoader.skeleton_of(root)
	var problem: String = _scene_problem(root, skeleton, catalog)
	if not problem.is_empty():
		return problem
	var meta: Meta = _read_meta(meta_path, skeleton)
	if not meta.problem.is_empty():
		return meta.problem
	var clips: Dictionary = {}
	for key: String in CharacterCatalog.REQUIRED_CLIPS:
		clips[key] = catalog.animations()[key]
	var library: AnimationLibrary = CharacterRetarget.library_for(skeleton, clips, meta.options)
	if library == null:
		return "o retarget falhou: o clipe de referência '%s' deve ser idle ou walk e os arquivos de animação precisam existir" % meta.options.reference_key
	var player: AnimationPlayer = AnimationPlayer.new()
	root.add_child(player)
	player.add_animation_library("", library)
	root.scale = Vector3.ONE * meta.factor
	return ""


## O motivo de a cena não servir ("" se serve): o `Skeleton3D` filho direto da raiz com os ossos do catálogo e malha com `Skin` que o sirva.
static func _scene_problem(root: Node3D, skeleton: Skeleton3D, catalog: CharacterCatalog) -> String:
	if skeleton == null or skeleton.get_bone_count() != catalog.skeleton_bones or root.get_node_or_null(NodePath(CharacterRetarget.SKELETON_NODE)) != skeleton:
		return "a cena não tem um '%s' filho da raiz com os %d ossos do catálogo" % [CharacterRetarget.SKELETON_NODE, catalog.skeleton_bones]
	if not CharacterSceneLoader.fits(root, skeleton):
		return "a malha da cena não tem Skin que sirva ao esqueleto"
	return ""


## Lê o JSON de metadados: as opções do retarget e a escala; só um problema (já escrito) se o arquivo falta, não é JSON de objeto ou um campo está errado.
static func _read_meta(path: String, skeleton: Skeleton3D) -> Meta:
	var meta: Meta = Meta.new()
	var reader: CharacterDataReader = CharacterDataReader.new(path)
	var data: Dictionary = reader.parse_file()
	if reader.bundle.is_valid():
		reader.whole(data, "version", "", META_VERSION, META_VERSION)
		meta.options = _options(reader, data, skeleton)
		meta.factor = _scale_of(reader, data)
	if not reader.bundle.is_valid():
		meta.problem = "os metadados são inválidos: " + reader.bundle.describe_issues()
	return meta


## As opções do retarget (6a): a pose de bind, o clipe de referência e a trava de chão ligada.
static func _options(reader: CharacterDataReader, meta: Dictionary, skeleton: Skeleton3D) -> CharacterRetarget.Options:
	var options: CharacterRetarget.Options = CharacterRetarget.Options.new()
	options.reference_key = reader.text(meta, "reference_clip", "")
	options.bind_pose = _bind_pose(reader, meta, skeleton)
	options.ground_lock = true
	return options


## osso -> transformação mundial da pose de bind, de TODOS os ossos do esqueleto; osso sem os 12 números vira problema no leitor.
static func _bind_pose(reader: CharacterDataReader, meta: Dictionary, skeleton: Skeleton3D) -> Dictionary[String, Transform3D]:
	var bind: Dictionary[String, Transform3D] = {}
	var poses: Dictionary = reader.object(meta, "bind_pose", "")
	for bone: int in skeleton.get_bone_count():
		var bone_name: String = skeleton.get_bone_name(bone)
		var numbers: Variant = poses.get(bone_name)  # Variant: fronteira com o JSON, conferido por _is_pose
		if _is_pose(numbers):
			bind[bone_name] = _transform_of(numbers)
		else:
			reader.fail(bone_name, "bind_pose", "esperados %d números" % POSE_NUMBERS)
	return bind


## Os 12 números de uma pose: uma lista com 12 reais. `value` é Variant porque vem do JSON; o tipo é conferido aqui.
static func _is_pose(value: Variant) -> bool:
	if typeof(value) != TYPE_ARRAY or (value as Array).size() != POSE_NUMBERS:
		return false
	for number: Variant in value as Array:
		if typeof(number) != TYPE_FLOAT:
			return false
	return true


## Os 12 números (eixos x, y, z e origem) viram a transformação.
static func _transform_of(numbers: Array) -> Transform3D:
	var vectors: Array[Vector3] = []
	for start: int in range(0, POSE_NUMBERS, VECTOR_SIZE):
		vectors.append(Vector3(numbers[start], numbers[start + 1], numbers[start + 2]))
	return Transform3D(Basis(vectors[0], vectors[1], vectors[2]), vectors[3])


## A escala uniforme: a altura do corpo no jogo sobre a da malha no arquivo (1 com o problema registrado no leitor).
static func _scale_of(reader: CharacterDataReader, meta: Dictionary) -> float:
	var body: float = _metric(reader, meta, "body_m")
	var height: float = _metric(reader, meta, "height_m")
	return body / height if body > 0.0 and height > 0.0 else 1.0


static func _metric(reader: CharacterDataReader, meta: Dictionary, field: String) -> float:
	var value: Variant = meta.get(field)  # Variant: fronteira com o JSON, conferido logo abaixo
	if typeof(value) != TYPE_FLOAT or float(value) <= 0.0:
		reader.fail("", field, "esperado um número maior que zero")
		return 0.0
	return float(value)


## O que se lê dos metadados: as opções do retarget, a escala uniforme e o problema (vazio = tudo certo).
class Meta:
	extends RefCounted

	var options: CharacterRetarget.Options = null
	var factor: float = 1.0
	var problem: String = ""
