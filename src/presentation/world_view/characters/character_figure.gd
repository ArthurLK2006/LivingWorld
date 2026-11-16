class_name CharacterFigure
extends RefCounted
## Figura de malha inteira (ART-12, entrega 6b; só apresentação): `build(catalog, id)` instancia a figura gravada (cena com um Node3D na raiz, o `Skeleton3D` de 65 ossos com os nomes da UAL como filho direto, e as `MeshInstance3D` com malha e `Skin`, mais o equipamento da 6d, uma malha sem pele filha de um `BoneAttachment3D` do esqueleto; SEM `AnimationPlayer`: o `build` monta o dele e rejeita a cena que já tenha um) e monta nela um `AnimationPlayer` com `idle` e `walk` (em laço, PARADO) pelo MESMO `CharacterRetarget` do montador, com as opções da entrega 6a vindas dos metadados: pose de bind, clipe de referência e trava de chão LIGADA. Só idle e walk, numa ÚNICA chamada de `library_for` com os clipes do catálogo FILTRADOS e as opções já inteiras (a trava vale para todos os clipes da chamada e o jog tem fase aérea). Devolve a raiz pronta: escala uniforme para o corpo de `body_m`, origem nos pés, sem girar (a cena gravada já nasce de frente para +Z). Qualquer falha (figura fora do catálogo, cena ou JSON ausente ou inválido, cena com `AnimationPlayer`, esqueleto sem os ossos do catálogo, malha sem `Skin`, pose de bind incompleta ou degenerada, retarget que falha) devolve null e deixa o motivo legível em `failure`, sem exceção e sem log PRÓPRIO: o chamador volta ao montador ou à cápsula (entrega 4 do contrato). O `CharacterAssembler` não muda. Contrato: docs/modules/presentation.md.
## CARREGADORES (opcionais): `new(scene_loader, text_reader)` trocam a leitura da cena e a do JSON, para os testes não tocarem o disco nem `user://` (AGENTS 4.16 e 9.4). `scene_loader(path: String) -> Node` devolve uma instância NOVA da cena, ou null se ela não existe (padrão: `CharacterSceneLoader.instantiate`, que NÃO é filtrado: se a cena existe mas está corrompida, o MOTOR registra erro de carga no log e o `build` só devolve null com o motivo); `text_reader(path: String) -> String` devolve o texto do JSON, ou "" se ele não existe (padrão: o arquivo do disco). Os caminhos vêm do catálogo, que só aceita `res://` sem `..`.
## METADADOS (o JSON do caminho `meta`, gravado pela ferramenta da entrega 6c): `version` (1), `reference_clip` (a chave do clipe cujo quadro 0 é a pose da malha: `idle`), `body_m` (altura do corpo no jogo, m), `height_m` (altura da malha no arquivo, m; a escala é `body_m / height_m`) e `bind_pose` (osso -> 12 números FINITOS, os eixos x, y e z e a origem da transformação MUNDIAL do osso na pose da malha, em metros do arquivo, pés em y = 0; cada eixo com comprimento acima de `MIN_AXIS_LENGTH`), com todos os ossos do esqueleto, e dois campos OPCIONAIS da entrega 6e: `damping` (osso do esqueleto -> fator FINITO de 0 a 1, para `Options.damping`: o amortecimento por osso) e `ground_points` (osso do esqueleto -> lista de 1 a `MAX_GROUND_POINTS` pontos [x, y, z] finitos no espaço local do osso, medidos na malha, para `Options.ground_points`: o contato da bota na trava de chão); ausentes ou vazios = a figura sai IDÊNTICA à de antes, e presentes e inválidos = `build` devolve null com o motivo (os ossos inválidos entram num só problema, com a contagem e os primeiros nomes). O resto (`figure`, `credit`, `bones`, `palette`, `source`, hashes...) é proveniência e o `build` ignora.

const META_VERSION: int = 1
## A pose de bind de um osso: quatro vetores (os eixos x, y e z e a origem) de três componentes.
const VECTOR_SIZE: int = 3
const POSE_VECTORS: int = 4
const POSE_NUMBERS: int = POSE_VECTORS * VECTOR_SIZE
## [HIP] O menor comprimento de um eixo da base de uma pose de bind (nas reais vale 1): abaixo disso a base é degenerada e o motor registra erro ao orientá-la.
const MIN_AXIS_LENGTH: float = 0.001
const MIN_DETERMINANT: float = 0.000001
## [HIP] Quantos ossos o motivo de uma pose de bind inválida nomeia (o resto entra só na contagem).
const LISTED_BONES: int = 5
## [HIP] O máximo de pontos de contato de um osso (a ferramenta gera até 33, um por direção de apoio, e na prática 11 por bota; cada ponto custa uma passada pela cadeia do osso a cada quadro da trava de chão).
const MAX_GROUND_POINTS: int = 64

## O motivo da última falha de `build` ("" se deu certo).
var failure: String = ""
var _scene_loader: Callable
var _text_reader: Callable


## Os carregadores são opcionais (ver o cabeçalho): sem eles a cena vem do `CharacterSceneLoader` e o JSON, do disco.
func _init(scene_loader: Callable = Callable(), text_reader: Callable = Callable()) -> void:
	_scene_loader = scene_loader if scene_loader.is_valid() else CharacterSceneLoader.instantiate
	_text_reader = text_reader if text_reader.is_valid() else _read_text


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


func _load(path: String) -> Node3D:
	var scene: Node = _scene_loader.call(path)
	if scene is Node3D:
		return scene as Node3D
	if scene != null:
		scene.free()
	return null


## O texto do arquivo do disco; "" se ele não existe ou não abre.
static func _read_text(path: String) -> String:
	return FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else ""


## Confere a cena e os metadados e monta o `AnimationPlayer` e a escala em `root`; devolve o motivo da falha ("" se deu certo); numa falha não deixa nada montado em `root` (o `AnimationPlayer` só entra depois de todas as conferências).
func _assemble(root: Node3D, meta_path: String, catalog: CharacterCatalog) -> String:
	var skeleton: Skeleton3D = CharacterSceneLoader.skeleton_of(root)
	var problem: String = _scene_problem(root, skeleton, catalog)
	if not problem.is_empty():
		return problem
	var meta: Meta = _read_meta(meta_path, _text_reader.call(meta_path), skeleton)
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


## O motivo de a cena não servir ("" se serve): sem `AnimationPlayer` (o `build` monta o dele), com o `Skeleton3D` filho direto da raiz com os ossos do catálogo e malha com `Skin` que o sirva.
static func _scene_problem(root: Node3D, skeleton: Skeleton3D, catalog: CharacterCatalog) -> String:
	if not root.find_children("*", "AnimationPlayer", true, false).is_empty():
		return "a cena já tem um AnimationPlayer: a figura gravada não tem player, o build monta o dele"
	if skeleton == null or skeleton.get_bone_count() != catalog.skeleton_bones or root.get_node_or_null(NodePath(CharacterRetarget.SKELETON_NODE)) != skeleton:
		return "a cena não tem um '%s' filho da raiz com os %d ossos do catálogo" % [CharacterRetarget.SKELETON_NODE, catalog.skeleton_bones]
	if not _fits(root, skeleton):
		return "a malha da cena não tem Skin que sirva ao esqueleto"
	return ""


## A figura serve ao esqueleto: ao menos uma malha com pele, toda malha com pele cita só ossos dele, e malha SEM pele só como equipamento (a espada da 6d): filha de um `BoneAttachment3D` filho do esqueleto, ligado a um osso dele. Como `CharacterSceneLoader.fits`, que o montador usa e não muda, mas aceitando o equipamento.
static func _fits(root: Node, skeleton: Skeleton3D) -> bool:
	var skinned: int = 0
	for mesh: MeshInstance3D in CharacterSceneLoader.meshes_of(root):
		var holder: BoneAttachment3D = mesh.get_parent() as BoneAttachment3D
		if mesh.skin == null:
			if holder == null or holder.get_parent() != skeleton or skeleton.find_bone(holder.bone_name) < 0:
				return false
			continue
		skinned += 1
		for bind: int in mesh.skin.get_bind_count():
			if skeleton.find_bone(mesh.skin.get_bind_name(bind)) < 0:
				return false
	return skinned > 0


## Lê o texto JSON dos metadados (`text`, do arquivo `path`; "" = o arquivo não existe): as opções do retarget e a escala; só um problema (já escrito) se o arquivo falta, não é JSON de objeto ou um campo está errado.
static func _read_meta(path: String, text: String, skeleton: Skeleton3D) -> Meta:
	var meta: Meta = Meta.new()
	var reader: CharacterDataReader = CharacterDataReader.new(path)
	var data: Dictionary = {}
	if text.is_empty():
		reader.fail("", "", "arquivo não encontrado ou vazio")
	else:
		data = reader.parse_json(text)
	if reader.bundle.is_valid():
		reader.whole(data, "version", "", META_VERSION, META_VERSION)
		meta.options = _options(reader, data, skeleton)
		meta.factor = _scale_of(reader, data)
	if not reader.bundle.is_valid():
		meta.problem = "os metadados são inválidos: " + reader.bundle.describe_issues()
	return meta


## As opções do retarget (6a): a pose de bind, o clipe de referência e a trava de chão ligada; com o amortecimento e os pontos de contato, se os metadados os trazem (6e).
static func _options(reader: CharacterDataReader, meta: Dictionary, skeleton: Skeleton3D) -> CharacterRetarget.Options:
	var options: CharacterRetarget.Options = CharacterRetarget.Options.new()
	options.reference_key = reader.text(meta, "reference_clip", "")
	options.bind_pose = _bind_pose(reader, meta, skeleton)
	options.damping = _damping(reader, meta, skeleton)
	options.ground_points = _ground_points(reader, meta, skeleton)
	options.ground_lock = true
	return options


## O amortecimento por osso (campo OPCIONAL `damping`; ausente = {}): osso do esqueleto -> fator finito de 0 a 1; os ossos inválidos (fora do esqueleto, ou fator que não é número de 0 a 1) viram UM só problema no leitor.
static func _damping(reader: CharacterDataReader, meta: Dictionary, skeleton: Skeleton3D) -> Dictionary[String, float]:
	var damping: Dictionary[String, float] = {}
	var invalid: PackedStringArray = PackedStringArray()
	var factors: Dictionary = reader.object(meta, "damping", "") if meta.has("damping") else {}
	for bone_name: String in factors:
		var factor: Variant = factors[bone_name]  # Variant: fronteira com o JSON, conferido logo abaixo
		if skeleton.find_bone(bone_name) >= 0 and typeof(factor) == TYPE_FLOAT and float(factor) >= 0.0 and float(factor) <= 1.0:
			damping[bone_name] = float(factor)
		else:
			invalid.append(bone_name)
	_report(reader, "damping", invalid, "um osso do esqueleto com um fator de 0 a 1")
	return damping


## Os contatos da trava de chão (campo OPCIONAL `ground_points`; ausente = {}): osso do esqueleto -> pontos [x, y, z] no espaço local do osso; os ossos inválidos (fora do esqueleto, ou lista que não serve a `_points_of`) viram UM só problema no leitor.
static func _ground_points(reader: CharacterDataReader, meta: Dictionary, skeleton: Skeleton3D) -> Dictionary[String, PackedVector3Array]:
	var points: Dictionary[String, PackedVector3Array] = {}
	var invalid: PackedStringArray = PackedStringArray()
	var table: Dictionary = reader.object(meta, "ground_points", "") if meta.has("ground_points") else {}
	for bone_name: String in table:
		var found: PackedVector3Array = _points_of(table[bone_name])
		if skeleton.find_bone(bone_name) >= 0 and not found.is_empty():
			points[bone_name] = found
		else:
			invalid.append(bone_name)
	_report(reader, "ground_points", invalid, "um osso do esqueleto com de 1 a %d pontos [x, y, z] finitos" % MAX_GROUND_POINTS)
	return points


## Os pontos de uma lista do JSON: de 1 a `MAX_GROUND_POINTS`, cada um com 3 reais finitos; vazio se a lista não serve. `value` é Variant porque vem do JSON; o tipo é conferido aqui.
static func _points_of(value: Variant) -> PackedVector3Array:
	var points: PackedVector3Array = PackedVector3Array()
	if typeof(value) != TYPE_ARRAY or (value as Array).size() > MAX_GROUND_POINTS:
		return points
	for point: Variant in value as Array:  # Variant: o ponto do JSON, conferido por _is_numbers
		if not _is_numbers(point, VECTOR_SIZE):
			return PackedVector3Array()
		points.append(Vector3(point[0], point[1], point[2]))
	return points


## O problema único de um campo opcional com ossos inválidos (a contagem e os primeiros nomes, para o motivo não crescer com o esqueleto).
static func _report(reader: CharacterDataReader, field: String, invalid: PackedStringArray, expected: String) -> void:
	if not invalid.is_empty():
		reader.fail("", field, "ossos inválidos: %d (esperado %s); os primeiros: %s" % [invalid.size(), expected, ", ".join(invalid.slice(0, LISTED_BONES))])


## osso -> transformação mundial da pose de bind, de TODOS os ossos do esqueleto; os ossos sem uma pose válida viram UM só problema no leitor (a contagem e os primeiros nomes, para o motivo não crescer com o esqueleto).
static func _bind_pose(reader: CharacterDataReader, meta: Dictionary, skeleton: Skeleton3D) -> Dictionary[String, Transform3D]:
	var bind: Dictionary[String, Transform3D] = {}
	var invalid: PackedStringArray = PackedStringArray()
	var poses: Dictionary = reader.object(meta, "bind_pose", "")
	for bone: int in skeleton.get_bone_count():
		var bone_name: String = skeleton.get_bone_name(bone)
		var numbers: Variant = poses.get(bone_name)  # Variant: fronteira com o JSON, conferido por _is_pose
		if _is_pose(numbers):
			bind[bone_name] = _transform_of(numbers)
		else:
			invalid.append(bone_name)
	if not invalid.is_empty():
		reader.fail("", "bind_pose", "ossos com pose de bind inválida: %d (esperados %d números finitos e eixos da base com comprimento acima de %s e independentes); os primeiros: %s" % [invalid.size(), POSE_NUMBERS, MIN_AXIS_LENGTH, ", ".join(invalid.slice(0, LISTED_BONES))])
	return bind


## Os 12 números de uma pose: uma lista com 12 reais finitos e os três eixos da base com comprimento acima de `MIN_AXIS_LENGTH` e independentes (determinante acima de `MIN_DETERMINANT`: uma base singular faria o motor registrar erro). `value` é Variant porque vem do JSON; o tipo é conferido aqui.
static func _is_pose(value: Variant) -> bool:
	if not _is_numbers(value, POSE_NUMBERS):
		return false
	var basis: Basis = _transform_of(value as Array).basis
	for axis: Vector3 in [basis.x, basis.y, basis.z]:
		if axis.length() <= MIN_AXIS_LENGTH:
			return false
	return absf(basis.determinant()) > MIN_DETERMINANT


## Uma lista com `count` reais finitos. `value` é Variant porque vem do JSON; o tipo é conferido aqui.
static func _is_numbers(value: Variant, count: int) -> bool:
	if typeof(value) != TYPE_ARRAY or (value as Array).size() != count:
		return false
	for number: Variant in value as Array:
		if typeof(number) != TYPE_FLOAT or not is_finite(float(number)):
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
