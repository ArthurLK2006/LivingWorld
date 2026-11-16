class_name CharacterFigure
extends RefCounted
## Figura de malha inteira (ART-12, entrega 6b; só apresentação): `build(catalog, id)` instancia a figura gravada (cena com um Node3D na raiz, o `Skeleton3D` de 65 ossos com os nomes da UAL como filho direto, e as `MeshInstance3D` com malha e `Skin`, mais o equipamento da 6d, uma malha sem pele filha de um `BoneAttachment3D` do esqueleto; SEM `AnimationPlayer`: o `build` monta o dele e rejeita a cena que já tenha um) e monta nela um `AnimationPlayer` com `idle` e `walk` (em laço, PARADO) pelo MESMO `CharacterRetarget` do montador, com as opções da entrega 6a vindas dos metadados: pose de bind, clipe de referência e trava de chão LIGADA. Só idle e walk, numa ÚNICA chamada de `library_for` com os clipes do catálogo FILTRADOS e as opções já inteiras (a trava vale para todos os clipes da chamada e o jog tem fase aérea), mais o `jog`, quando pedido, numa chamada própria (campo OPCIONAL `jog` dos metadados, 6j): os clipes {o de referência, `jog`}, as mesmas opções e a trava SÓ DE PISO (`Options.ground_floor_only`: a pélvis só sobe e a fase aérea fica), reamostrada a `JOG_SAMPLES_PER_SECOND` (60 por segundo, 6k; idle e walk ficam nos 30 de sempre); só o `jog` dessa chamada entra no `AnimationPlayer`. Devolve a raiz pronta: escala uniforme para o corpo de `body_m`, origem nos pés, sem girar (a cena gravada já nasce de frente para +Z). Qualquer falha (figura fora do catálogo, cena ou JSON ausente ou inválido, cena com `AnimationPlayer`, esqueleto sem os ossos do catálogo, malha sem `Skin`, pose de bind incompleta ou degenerada, retarget que falha) devolve null e deixa o motivo legível em `failure`, sem exceção e sem log PRÓPRIO: o chamador volta ao montador ou à cápsula (entrega 4 do contrato). O `CharacterAssembler` não muda. Contrato: docs/modules/presentation.md.
## CARREGADORES (opcionais): `new(scene_loader, text_reader)` trocam a leitura da cena e a do JSON, para os testes não tocarem o disco nem `user://` (AGENTS 4.16 e 9.4). `scene_loader(path: String) -> Node` devolve uma instância NOVA da cena, ou null se ela não existe (padrão: `CharacterSceneLoader.instantiate`, que NÃO é filtrado: se a cena existe mas está corrompida, o MOTOR registra erro de carga no log e o `build` só devolve null com o motivo); `text_reader(path: String) -> String` devolve o texto do JSON, ou "" se ele não existe (padrão: o arquivo do disco). Os caminhos vêm do catálogo, que só aceita `res://` sem `..`.
## METADADOS (o JSON do caminho `meta`, gravado pela ferramenta da entrega 6c): `version` (1), `reference_clip` (a chave do clipe cujo quadro 0 é a pose da malha: `idle`), `body_m` (altura do corpo no jogo, m), `height_m` (altura da malha no arquivo, m; a escala é `body_m / height_m`) e `bind_pose` (osso -> 12 números FINITOS, os eixos x, y e z e a origem da transformação MUNDIAL do osso na pose da malha, em metros do arquivo, pés em y = 0; cada eixo com comprimento acima de `MIN_AXIS_LENGTH`), com todos os ossos do esqueleto, e dois campos OPCIONAIS da entrega 6e: `damping` (osso do esqueleto -> fator FINITO de 0 a 1, para `Options.damping`: o amortecimento por osso) e `ground_points` (osso do esqueleto -> lista de 1 a `MAX_GROUND_POINTS` pontos [x, y, z] finitos no espaço local do osso, medidos na malha, para `Options.ground_points`: o contato da bota na trava de chão); e o da 6h, `symmetric_reference` (lista de até `MAX_SYMMETRIC_PARTS` prefixos de pares de ossos `<parte>_l` e `<parte>_r` do esqueleto, por exemplo ["thigh", "calf", "foot", "ball"], para `Options.symmetric_reference`: a pose de referência simétrica, para corrigir o passo manco); ausentes ou vazios = a figura sai IDÊNTICA à de antes, e presentes e inválidos = `build` devolve null com o motivo (os ossos ou partes inválidos entram num só problema, com a contagem e os primeiros nomes). E o da 6j, `jog` (booleano: ausente ou `false` = a figura sai IDÊNTICA, só `idle` e `walk`; `true` = ganha também o clipe `jog`, em laço e parado, montado como no cabeçalho; outro tipo, ou catálogo sem a animação `jog` = `build` devolve null com o motivo). E o da 7a, `locomotion` (objeto: `walk` e `jog` -> a velocidade em m/s, de 0 (exclusivo) a `MAX_LOCOMOTION_SPEED_MPS`, em que o pé de apoio do clipe fica colado ao chão, para o `CharacterLocomotion.pick` escolher o clipe e a escala; `jog` só com o campo `jog` verdadeiro; ausente ou vazio = a figura sai IDÊNTICA, sem metadado no nó; presente, o `build` o grava no nó raiz (`LOCOMOTION_META`) e `locomotion_of(root)` o devolve, conferindo os tipos; inválido = `build` devolve null com o motivo). O resto (`figure`, `credit`, `bones`, `palette`, `source`, hashes...) é proveniência e o `build` ignora.

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
## [HIP] O máximo de pontos de contato da figura INTEIRA, somados os ossos (na prática 11 por bota, 22 no Ice Warrior; cada ponto custa uma passada pela cadeia do osso a cada quadro da trava de chão: 65 ossos com 64 pontos cada levaram o `build` de 8 para 895 ms).
const MAX_GROUND_POINTS: int = 64
## [HIP] O máximo de partes da lista `symmetric_reference` (o esqueleto de 65 ossos tem 29 pares `<parte>_l` e `<parte>_r`; a do Ice Warrior lista 4).
const MAX_SYMMETRIC_PARTS: int = 32
## A chave da animação de corrida no catálogo e na biblioteca da figura (campo `jog`, 6j).
const JOG_KEY: String = "jog"
## [HIP] A taxa de reamostragem do clipe `jog` (6k, `Options.samples_per_second`; idle e walk ficam nos 30 por segundo de sempre): a pélvis interpola linearmente entre as chaves da trava de chão e a sola afundava até 1,28 cm entre elas (o critério é de 1 cm); com mais chaves por segundo o erro cai com o quadrado do passo. Medido no Ice Warrior, em 600 e 3000 instantes do ciclo: 30 por segundo = 1,28 cm, 60 = 0,32 cm, 90 = 0,14 cm, 120 = 0,08 cm; fica o MENOR valor com margem (no máximo 0,9 cm), e o custo do `build` cresce com a taxa (jog a 60: cerca de 6 ms a mais).
const JOG_SAMPLES_PER_SECOND: float = 60.0
## O nome do metadado do nó raiz com as velocidades da figura (campo `locomotion`, 7a): o `build` o grava e `locomotion_of` o lê.
const LOCOMOTION_META: String = "locomotion"
## [HIP] A maior velocidade aceita no campo `locomotion` (m/s): muito acima de qualquer corrida de um corpo de 1,8 m, só para barrar um número absurdo (um erro de unidade). As medidas do Ice Warrior são 0,73 (walk) e 4,1 (jog).
const MAX_LOCOMOTION_SPEED_MPS: float = 100.0
## [HIP] O maior módulo de um número de pose de bind ou de ponto de contato (a figura tem uns 1,5 m): acima disso o real de 32 bits do motor vira infinito ao converter e a trilha da pélvis sai NaN, mesmo com o número finito em precisão dupla.
const MAX_COORDINATE: float = 1000.0

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


## As velocidades que a figura montada carrega (o metadado `LOCOMOTION_META` do nó raiz, gravado pelo `build` a partir do campo `locomotion`): clipe (`walk` ou `jog`) -> m/s em que o pé de apoio fica colado ao chão, a tabela que o `CharacterLocomotion.pick` consome. Confere os tipos, porque o metadado é de quem o gravou: valor que não é número, não é finito ou não é positivo é ignorado, e chave que não é walk nem jog também; sem o metadado (a figura sem o campo, ou um nó qualquer) ou com ele de outro tipo, devolve {}. A tabela devolvida é uma cópia nova a cada chamada.
static func locomotion_of(root: Node) -> Dictionary[String, float]:
	var speeds: Dictionary[String, float] = {}
	var stored: Variant = root.get_meta(LOCOMOTION_META, {}) if root != null else {}  # Variant: o metadado é de quem o gravou, conferido logo abaixo (o padrão não pode ser null: o motor registra um erro)
	if typeof(stored) != TYPE_DICTIONARY:
		return speeds
	var table: Dictionary = stored
	for key: Variant in table:  # Variant: a chave do metadado, conferida logo abaixo
		var speed: Variant = table[key]  # Variant: o valor do metadado, conferido logo abaixo
		var is_number: bool = typeof(speed) == TYPE_FLOAT or typeof(speed) == TYPE_INT
		if typeof(key) == TYPE_STRING and CharacterLocomotion.CLIPS.has(String(key)) and is_number and is_finite(float(speed)) and float(speed) > 0.0:
			speeds[String(key)] = float(speed)
	return speeds


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
	if meta.jog:
		var jog: Animation = _jog_clip(skeleton, catalog, meta.options)
		if jog == null:
			return "o campo jog pede o clipe '%s', que o catálogo não tem ou o retarget não conseguiu montar" % JOG_KEY
		library.add_animation(StringName(JOG_KEY), jog)
	var player: AnimationPlayer = AnimationPlayer.new()
	root.add_child(player)
	player.add_animation_library("", library)
	root.scale = Vector3.ONE * meta.factor
	if not meta.locomotion.is_empty():
		root.set_meta(LOCOMOTION_META, meta.locomotion)
	return ""


## O clipe `jog` (6j) retargetado numa chamada PRÓPRIA de `library_for`: os clipes {o de referência, `jog`} do catálogo e as mesmas opções, com a trava SÓ DE PISO e a taxa `JOG_SAMPLES_PER_SECOND` ligadas em `options` (o jog tem fase aérea; a trava de sempre a apagaria; o chamador não usa mais as opções). Só o `jog` interessa. Null se o catálogo não tem o clipe ou o retarget falha.
static func _jog_clip(skeleton: Skeleton3D, catalog: CharacterCatalog, options: CharacterRetarget.Options) -> Animation:
	var animations: Dictionary = catalog.animations()
	if not animations.has(JOG_KEY):
		return null
	var clips: Dictionary = {options.reference_key: animations[options.reference_key], JOG_KEY: animations[JOG_KEY]}
	options.ground_floor_only = true
	options.samples_per_second = JOG_SAMPLES_PER_SECOND
	var library: AnimationLibrary = CharacterRetarget.library_for(skeleton, clips, options)
	return library.get_animation(StringName(JOG_KEY)) if library != null else null


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
		meta.jog = _wants_jog(reader, data)
		meta.locomotion = _locomotion(reader, data, meta.jog)
		meta.factor = _scale_of(reader, data)
	if not reader.bundle.is_valid():
		meta.problem = "os metadados são inválidos: " + reader.bundle.describe_issues()
	return meta


## As opções do retarget (6a): a pose de bind, o clipe de referência e a trava de chão ligada; com o amortecimento e os pontos de contato (6e) e a referência simétrica (6h), se os metadados os trazem.
static func _options(reader: CharacterDataReader, meta: Dictionary, skeleton: Skeleton3D) -> CharacterRetarget.Options:
	var options: CharacterRetarget.Options = CharacterRetarget.Options.new()
	options.reference_key = reader.text(meta, "reference_clip", "")
	options.bind_pose = _bind_pose(reader, meta, skeleton)
	options.damping = _damping(reader, meta, skeleton)
	options.ground_points = _ground_points(reader, meta, skeleton)
	options.symmetric_reference = _symmetric_reference(reader, meta, skeleton)
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
	var total: int = 0
	for bone_name: String in table:
		var found: PackedVector3Array = _points_of(table[bone_name])
		if skeleton.find_bone(bone_name) >= 0 and not found.is_empty():
			points[bone_name] = found
			total += found.size()
		else:
			invalid.append(bone_name)
	_report(reader, "ground_points", invalid, "um osso do esqueleto com pontos [x, y, z] finitos")
	if total > MAX_GROUND_POINTS:
		reader.fail("", "ground_points", "pontos demais: %d (no máximo %d no total)" % [total, MAX_GROUND_POINTS])
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


## As partes cuja pose de referência é simetrizada (campo OPCIONAL `symmetric_reference`; ausente = []): lista de até `MAX_SYMMETRIC_PARTS` prefixos de pares de ossos `<parte>_l` e `<parte>_r` do esqueleto. Campo que não é lista, ou lista longa demais, vira um problema no leitor; os itens inválidos (que não são texto ou sem o par de ossos no esqueleto, como "" ou o nome inteiro de um osso) entram num só.
static func _symmetric_reference(reader: CharacterDataReader, meta: Dictionary, skeleton: Skeleton3D) -> PackedStringArray:
	var parts: PackedStringArray = PackedStringArray()
	var invalid: PackedStringArray = PackedStringArray()
	var listed: Variant = meta.get("symmetric_reference", [])  # Variant: fronteira com o JSON, conferido logo abaixo
	if typeof(listed) != TYPE_ARRAY or (listed as Array).size() > MAX_SYMMETRIC_PARTS:
		reader.fail("", "symmetric_reference", "esperada uma lista de até %d textos" % MAX_SYMMETRIC_PARTS)
		return parts
	for part: Variant in listed as Array:  # Variant: o item do JSON, conferido logo abaixo
		if typeof(part) == TYPE_STRING and skeleton.find_bone(String(part) + CharacterRetarget.LEFT_SUFFIX) >= 0 and skeleton.find_bone(String(part) + CharacterRetarget.RIGHT_SUFFIX) >= 0:
			parts.append(String(part))
		else:
			invalid.append(str(part))
	_report(reader, "symmetric_reference", invalid, "o prefixo de um par de ossos <parte>_l e <parte>_r do esqueleto")
	return parts


## Se a figura pede o clipe `jog` (campo OPCIONAL `jog`; ausente = false): um booleano; de outro tipo vira um problema no leitor.
static func _wants_jog(reader: CharacterDataReader, meta: Dictionary) -> bool:
	var value: Variant = meta.get("jog", false)  # Variant: fronteira com o JSON, conferido logo abaixo
	if typeof(value) != TYPE_BOOL:
		reader.fail("", "jog", "esperado verdadeiro ou falso")
		return false
	return bool(value)


## As velocidades da figura (campo OPCIONAL `locomotion`, 7a; ausente = {}): objeto clipe (`walk` ou `jog`, os de `CharacterLocomotion.CLIPS`) -> m/s em que o pé de apoio do clipe fica colado ao chão, um número finito maior que zero e até `MAX_LOCOMOTION_SPEED_MPS`. Campo que não é objeto, clipe inválido (chave que não é walk nem jog, ou valor que não serve) e `jog` sem o campo `jog` verdadeiro (`wants_jog`: a figura não tem o clipe) viram UM só problema no leitor, o primeiro que se acha.
static func _locomotion(reader: CharacterDataReader, meta: Dictionary, wants_jog: bool) -> Dictionary[String, float]:
	var speeds: Dictionary[String, float] = {}
	var invalid: PackedStringArray = PackedStringArray()
	var table: Dictionary = reader.object(meta, "locomotion", "") if meta.has("locomotion") else {}
	for key: String in table:
		var speed: Variant = table[key]  # Variant: fronteira com o JSON, conferido logo abaixo
		if CharacterLocomotion.CLIPS.has(key) and typeof(speed) == TYPE_FLOAT and is_finite(float(speed)) and float(speed) > 0.0 and float(speed) <= MAX_LOCOMOTION_SPEED_MPS:
			speeds[key] = float(speed)
		else:
			invalid.append(key)
	_report(reader, "locomotion", invalid, "walk ou jog com uma velocidade maior que zero e até %.0f m/s" % MAX_LOCOMOTION_SPEED_MPS, "clipes")
	if invalid.is_empty() and speeds.has(JOG_KEY) and not wants_jog:
		reader.fail("", "locomotion", "a chave jog pede o clipe jog, e a figura não o tem (o campo jog não é verdadeiro)")
	return speeds


## O problema único de um campo opcional com itens inválidos (ossos, por padrão: a contagem e os primeiros nomes, para o motivo não crescer com o esqueleto).
static func _report(reader: CharacterDataReader, field: String, invalid: PackedStringArray, expected: String, items: String = "ossos") -> void:
	if not invalid.is_empty():
		reader.fail("", field, "%s inválidos: %d (esperado %s); os primeiros: %s" % [items, invalid.size(), expected, ", ".join(invalid.slice(0, LISTED_BONES))])


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


## Uma lista com `count` reais finitos e de módulo até `MAX_COORDINATE`. `value` é Variant porque vem do JSON; o tipo é conferido aqui.
static func _is_numbers(value: Variant, count: int) -> bool:
	if typeof(value) != TYPE_ARRAY or (value as Array).size() != count:
		return false
	for number: Variant in value as Array:
		if typeof(number) != TYPE_FLOAT or not is_finite(float(number)) or absf(float(number)) > MAX_COORDINATE:
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


## O que se lê dos metadados: as opções do retarget, a escala uniforme, se a figura pede o `jog` (6j), as velocidades da locomoção (7a, vazio = o campo ausente) e o problema (vazio = tudo certo).
class Meta:
	extends RefCounted

	var options: CharacterRetarget.Options = null
	var factor: float = 1.0
	var jog: bool = false
	var locomotion: Dictionary[String, float] = {}
	var problem: String = ""
