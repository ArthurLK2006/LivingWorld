class_name CharacterCatalog
extends RefCounted
## O catálogo de peças e animações dos personagens do mundo (ART-12, entrega 3; só apresentação), lido de data/presentation/character_catalog.json e VALIDADO ao carregar: versão, ids únicos, gêneros aceitos, todo caminho res:// existente, animações idle e walk presentes e, para cada gênero de corpo, ao menos uma roupa e um cabelo compatível. Qualquer problema vira UMA falha tratada com arquivo, item e campo (nunca lança erro nem escreve no log) e o catálogo devolvido fica vazio. Só dados simples: nada do arquivo é executado. Contrato: docs/modules/presentation.md.

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

var skeleton_bones: int = 0
var _bodies: Array[Dictionary] = []
var _outfits: Array[Dictionary] = []
var _hair: Array[Dictionary] = []
var _eyebrows: Array[Dictionary] = []
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


func eyebrows() -> Array[Dictionary]:
	return _eyebrows.duplicate(true)


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
		if row["gender"] == gender or row["gender"] == ANY_GENDER:
			found.append(row.duplicate(true))
	return found


func _read(reader: CharacterDataReader, root: Dictionary) -> void:
	reader.whole(root, "version", "", SUPPORTED_VERSION, SUPPORTED_VERSION)
	skeleton_bones = reader.whole(root, "skeleton_bones", "", 1, MAX_BONES)
	_bodies = _table(reader, root, "bodies", BODY_GENDERS, HEAD_PATHS)
	_outfits = _table(reader, root, "outfits", BODY_GENDERS, PackedStringArray())
	_hair = _table(reader, root, "hair", HAIR_GENDERS, SCENE_PATHS)
	_eyebrows = _table(reader, root, "eyebrows", PackedStringArray(), SCENE_PATHS)
	for outfit: Dictionary in _outfits:
		var item: String = str(outfit.get("id", ""))
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


## Uma tabela: linhas com id único, gênero entre os aceitos (se a tabela tem gênero) e os campos de caminho existentes.
func _table(reader: CharacterDataReader, root: Dictionary, table: String, genders: PackedStringArray, path_fields: PackedStringArray) -> Array[Dictionary]:
	var found: Array[Dictionary] = reader.rows(root, table, "")
	var seen: Dictionary = {}
	for index: int in found.size():
		var item: String = reader.identify(found[index], table, index, seen)
		if not genders.is_empty():
			reader.choice(found[index], "gender", item, genders)
		for field: String in path_fields:
			reader.resource(found[index], field, item)
	return found


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
