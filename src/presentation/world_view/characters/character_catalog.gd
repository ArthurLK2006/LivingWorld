class_name CharacterCatalog
extends RefCounted
## O catálogo de peças e animações dos personagens do mundo (ART-12, entrega 3; só apresentação), lido de data/presentation/character_catalog.json e VALIDADO ao carregar: versão, ids únicos, gêneros aceitos, todo caminho res:// existente, animações idle e walk presentes e, para cada gênero de corpo, ao menos uma roupa e um cabelo compatível. A tabela `beards` (barba, uma camada que se soma ao cabelo) é OPCIONAL (ausente ou vazia = sem barba, sem erro) e o `gender` das sobrancelhas também (ausente = qualquer um). A tabela `figures` (figuras de malha inteira, entrega 6b: `id`, `scene` e `meta`, caminhos `res://` ou `user://`) também é OPCIONAL, mas é mais estrita (campo desconhecido falha); a EXISTÊNCIA dos arquivos dela NÃO é conferida aqui (nem pelo `exists` injetável): o ativo não está no Git, e quem não o tem (o CI, outro computador) não pode perder o catálogo inteiro por isso; quem a usa, o `CharacterFigure`, devolve o motivo e o chamador volta ao montador. Qualquer problema vira UMA falha tratada com arquivo, item e campo (nunca lança erro nem escreve no log) e o catálogo devolvido fica vazio. Só dados simples: nada do arquivo é executado. Contrato: docs/modules/presentation.md.

const DEFAULT_PATH: String = "res://data/presentation/character_catalog.json"
const CODE_INVALID: String = "CHARACTER_CATALOG_INVALID"
const SUPPORTED_VERSION: int = 1
## Teto de segurança [HIP] do número de ossos (o esqueleto compartilhado da Quaternius tem 65).
const MAX_BONES: int = 512
const MALE: String = "male"
const FEMALE: String = "female"
const ANY_GENDER: String = "any"
const BODY_GENDERS: PackedStringArray = [MALE, FEMALE]
const HAIR_GENDERS: PackedStringArray = [MALE, FEMALE, ANY_GENDER]
const HEAD_PATHS: PackedStringArray = ["head_scene"]
const SCENE_PATHS: PackedStringArray = ["scene"]
const OUTFIT_PARTS: PackedStringArray = ["torso_arms", "legs", "boots"]
const REQUIRED_CLIPS: PackedStringArray = ["idle", "walk"]
const FIGURE_TABLE: String = "figures"
const FIGURE_PATHS: PackedStringArray = ["scene", "meta"]
const FIGURE_FIELDS: PackedStringArray = ["id", "scene", "meta"]
const FIGURE_PREFIXES: PackedStringArray = ["res://", "user://"]

var skeleton_bones: int = 0
var _bodies: Array[Dictionary] = []
var _outfits: Array[Dictionary] = []
var _hair: Array[Dictionary] = []
var _beards: Array[Dictionary] = []
var _eyebrows: Array[Dictionary] = []
var _figures: Array[Dictionary] = []
var _animations: Dictionary = {}


## Lê e valida o arquivo. `exists` (opcional) substitui a conferência de caminhos res:// (os testes injetam a deles).
static func from_file(path: String = DEFAULT_PATH, exists: Callable = Callable()) -> LoadResult:
	var reader: CharacterDataReader = CharacterDataReader.new(path, exists)
	return _finish(reader, reader.parse_file())


## Igual a `from_file`, para um texto JSON já lido; `label` é o nome do arquivo nas falhas.
static func from_json(content: String, label: String, exists: Callable = Callable()) -> LoadResult:
	var reader: CharacterDataReader = CharacterDataReader.new(label, exists)
	return _finish(reader, reader.parse_json(content))


## Carregado com sucesso (todas as categorias preenchidas); o catálogo da falha é vazio.
func is_ready() -> bool:
	return not _bodies.is_empty()


## As consultas devolvem cópias: quem chama não mexe no catálogo.
func bodies() -> Array[Dictionary]:
	return _bodies.duplicate(true)


## Roupas do gênero do corpo.
func outfits_for(gender: String) -> Array[Dictionary]:
	return _compatible(_outfits, gender)


## Cabelos do gênero do corpo ou de gênero "any".
func hair_for(gender: String) -> Array[Dictionary]:
	return _compatible(_hair, gender)


## Barbas do gênero do corpo ou de gênero "any"; vazia se o catálogo não tem a tabela `beards`. Quem monta decide se o corpo usa barba.
func beards_for(gender: String) -> Array[Dictionary]:
	return _compatible(_beards, gender)


## Todas as sobrancelhas, de qualquer gênero.
func eyebrows() -> Array[Dictionary]:
	return _eyebrows.duplicate(true)


## Sobrancelhas do gênero do corpo ou sem gênero (sem `gender` = qualquer um).
func eyebrows_for(gender: String) -> Array[Dictionary]:
	return _compatible(_eyebrows, gender)


## As figuras de malha inteira (entrega 6b), cópias; vazia se o catálogo não tem a tabela `figures`.
func figures() -> Array[Dictionary]:
	return _figures.duplicate(true)


## A figura de id `id` (cópia: `id`, `scene`, `meta`); {} se não existe.
func figure(id: String) -> Dictionary:
	for row: Dictionary in _figures:
		if row["id"] == id:
			return row.duplicate(true)
	return {}


func animations() -> Dictionary:
	return _animations.duplicate(true)


static func _finish(reader: CharacterDataReader, root: Dictionary) -> LoadResult:
	var catalog: CharacterCatalog = CharacterCatalog.new()
	if reader.bundle.is_valid():
		catalog._read(reader, root)
	if reader.bundle.is_valid():
		return LoadResult.new(Result.success(), catalog)
	return LoadResult.new(Result.failure(CODE_INVALID, reader.bundle.describe_issues()), CharacterCatalog.new())


static func _compatible(table: Array[Dictionary], gender: String) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for row: Dictionary in table:
		var row_gender: String = row.get("gender", ANY_GENDER)
		if row_gender == gender or row_gender == ANY_GENDER:
			found.append(row.duplicate(true))
	return found


## O rótulo da linha de roupa nos erros: o `id` quando é texto não vazio; senão "outfits[i]" (como o `identify` do leitor).
static func _row_label(row: Dictionary, index: int) -> String:
	var id: Variant = row.get("id")
	return String(id) if typeof(id) == TYPE_STRING and not String(id).is_empty() else "outfits[%d]" % index


func _read(reader: CharacterDataReader, root: Dictionary) -> void:
	reader.whole(root, "version", "", SUPPORTED_VERSION, SUPPORTED_VERSION)
	skeleton_bones = reader.whole(root, "skeleton_bones", "", 1, MAX_BONES)
	_bodies = _table(reader, root, "bodies", BODY_GENDERS, HEAD_PATHS)
	_outfits = _table(reader, root, "outfits", BODY_GENDERS, PackedStringArray())
	_hair = _table(reader, root, "hair", HAIR_GENDERS, SCENE_PATHS)
	_beards = _optional_table(reader, root, "beards", HAIR_GENDERS, SCENE_PATHS)
	_eyebrows = _table(reader, root, "eyebrows", BODY_GENDERS, SCENE_PATHS, false)
	_read_figures(reader, root)
	for index: int in _outfits.size():
		var outfit: Dictionary = _outfits[index]
		var item: String = _row_label(outfit, index)
		var parts: Dictionary = reader.object(outfit, "parts", item)
		for part: String in OUTFIT_PARTS:
			reader.resource(parts, part, item)
		reader.paths(parts, "extras", item)
	_animations = reader.object(root, "animations", "")
	for clip_id: String in REQUIRED_CLIPS:
		if not _animations.has(clip_id):
			reader.fail("animations", clip_id, "animação obrigatória ausente")
	for clip_id: String in _animations:
		var clip: Dictionary = reader.object(_animations, clip_id, "animations")
		reader.resource(clip, "path", clip_id)
		reader.text(clip, "name", clip_id)
	if reader.bundle.is_valid():
		_check_coverage(reader)


## Uma tabela: linhas com id único, gênero entre os aceitos (se a tabela tem gênero; com `gender_required` falso o campo pode faltar, e então vale "qualquer um") e os campos de caminho existentes.
func _table(reader: CharacterDataReader, root: Dictionary, table: String, genders: PackedStringArray, path_fields: PackedStringArray, gender_required: bool = true) -> Array[Dictionary]:
	var found: Array[Dictionary] = reader.rows(root, table, "")
	var seen: Dictionary = {}
	for index: int in found.size():
		var item: String = reader.identify(found[index], table, index, seen)
		if not genders.is_empty() and (gender_required or found[index].has("gender")):
			reader.choice(found[index], "gender", item, genders)
		for field: String in path_fields:
			reader.resource(found[index], field, item)
	return found


## Tabela OPCIONAL: ausente ou vazia = nenhuma linha e nenhum erro (arquivo antigo, sem a tabela, continua válido); presente, é validada como as outras (lista de tipo errado e linha ruim falham).
func _optional_table(reader: CharacterDataReader, root: Dictionary, table: String, genders: PackedStringArray, path_fields: PackedStringArray) -> Array[Dictionary]:
	var declared: Variant = root.get(table)  # Variant: fronteira com o JSON, conferido logo abaixo
	if declared == null or (typeof(declared) == TYPE_ARRAY and (declared as Array).is_empty()):
		var none: Array[Dictionary] = []
		return none
	return _table(reader, root, table, genders, path_fields)


## Tabela OPCIONAL `figures` (ausente ou vazia = nenhuma figura, sem erro): cada linha tem `id` único, `scene` e `meta` (texto com prefixo res:// ou user://) e nenhum outro campo. Só a FORMA é conferida: o arquivo pode não existir (ver o cabeçalho).
func _read_figures(reader: CharacterDataReader, root: Dictionary) -> void:
	var declared: Variant = root.get(FIGURE_TABLE)  # Variant: fronteira com o JSON, conferido logo abaixo
	if declared == null or (typeof(declared) == TYPE_ARRAY and (declared as Array).is_empty()):
		return
	_figures = reader.rows(root, FIGURE_TABLE, "")
	var seen: Dictionary = {}
	for index: int in _figures.size():
		var item: String = reader.identify(_figures[index], FIGURE_TABLE, index, seen)
		for field: String in _figures[index]:
			if not FIGURE_FIELDS.has(field):
				reader.fail(item, field, "campo desconhecido na tabela '%s'" % FIGURE_TABLE)
		for field: String in FIGURE_PATHS:
			var path: String = reader.text(_figures[index], field, item)
			if not path.is_empty() and not Array(FIGURE_PREFIXES).any(path.begins_with):
				reader.fail(item, field, "o caminho '%s' deve começar com %s" % [path, " ou ".join(FIGURE_PREFIXES)])


## Todo corpo precisa ter roupa e cabelo do próprio gênero, senão a escolha da aparência não teria o que escolher.
func _check_coverage(reader: CharacterDataReader) -> void:
	for body: Dictionary in _bodies:
		var gender: String = body["gender"]
		if outfits_for(gender).is_empty():
			reader.fail(body["id"], "gender", "nenhuma roupa do gênero '%s' na tabela 'outfits'" % gender)
		if hair_for(gender).is_empty():
			reader.fail(body["id"], "gender", "nenhum cabelo compatível com o gênero '%s' na tabela 'hair'" % gender)


## Resultado da leitura: `catalog` só vale se `result.ok` (mesmo padrão dos outros carregadores).
class LoadResult:
	extends RefCounted

	var result: Result
	var catalog: CharacterCatalog

	func _init(load_result: Result, loaded_catalog: CharacterCatalog) -> void:
		result = load_result
		catalog = loaded_catalog
