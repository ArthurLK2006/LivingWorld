class_name CharacterPalettes
extends RefCounted
## As paletas dos personagens do mundo (ART-12, entrega 3; só apresentação), lidas de data/presentation/character_palettes.json e VALIDADAS ao carregar: versão, ids únicos e todo campo inteiro dentro da faixa de segurança. Três tabelas, escolhidas por índice: `cloth` (os parâmetros do sombreador de paleta do pano da ART-12a: rotação de matiz em graus, escalas de saturação e de valor e saturação somada em milésimos, e o valor do couro em milésimos), `skin` e `hair` (o multiplicador r, g, b da cor do material, em milésimos: 1000 é a cor original). Tudo inteiro; a conversão para o sombreador (graus para voltas, milésimos para decimais) é da apresentação. Qualquer problema vira UMA falha tratada com arquivo, item e campo (nunca lança erro nem escreve no log) e as paletas devolvidas ficam vazias.

const DEFAULT_PATH: String = "res://data/presentation/character_palettes.json"
const CODE_INVALID: String = "CHARACTER_PALETTES_INVALID"
const SUPPORTED_VERSION: int = 1
const CLOTH: String = "cloth"
const SKIN: String = "skin"
const HAIR: String = "hair"
## Campos inteiros de cada tabela, com a faixa de segurança [HIP] [mínimo, máximo] (não são limites de design; a afinação visual é da apresentação).
const RANGES: Dictionary = {
	CLOTH: {"hue_deg": [-360, 360], "sat_permille": [0, 2000], "val_permille": [0, 2000], "sat_add_permille": [-1000, 1000], "leather_val_permille": [0, 2000]},
	SKIN: {"r_permille": [0, 2000], "g_permille": [0, 2000], "b_permille": [0, 2000]},
	HAIR: {"r_permille": [0, 2000], "g_permille": [0, 2000], "b_permille": [0, 2000]},
}

var _tables: Dictionary = {}


## Lê e valida o arquivo.
static func from_file(path: String = DEFAULT_PATH) -> LoadResult:
	var reader: CharacterDataReader = CharacterDataReader.new(path)
	return _finish(reader, reader.parse_file())


## Igual a `from_file`, para um texto JSON já lido; `label` é o nome do arquivo nas falhas.
static func from_json(content: String, label: String) -> LoadResult:
	var reader: CharacterDataReader = CharacterDataReader.new(label)
	return _finish(reader, reader.parse_json(content))


## Carregadas com sucesso (todas as tabelas preenchidas); as paletas da falha são vazias.
func is_ready() -> bool:
	return count(CLOTH) > 0 and count(SKIN) > 0 and count(HAIR) > 0


## Quantas entradas a tabela (CLOTH, SKIN ou HAIR) tem.
func count(kind: String) -> int:
	var entries: Array = _tables.get(kind, [])
	return entries.size()


## A entrada `index` da tabela: `id` e os campos inteiros de RANGES (cópia). Índice fora da tabela: {}.
func entry(kind: String, index: int) -> Dictionary:
	var entries: Array = _tables.get(kind, [])
	if index < 0 or index >= entries.size():
		return {}
	var found: Dictionary = entries[index]
	return found.duplicate()


static func _finish(reader: CharacterDataReader, root: Dictionary) -> LoadResult:
	var palettes: CharacterPalettes = CharacterPalettes.new()
	if reader.bundle.is_valid():
		palettes._read(reader, root)
	if reader.bundle.is_valid():
		return LoadResult.new(Result.success(), palettes)
	return LoadResult.new(Result.failure(CODE_INVALID, reader.bundle.describe_issues()), CharacterPalettes.new())


func _read(reader: CharacterDataReader, root: Dictionary) -> void:
	reader.whole(root, "version", "", SUPPORTED_VERSION, SUPPORTED_VERSION)
	for kind: String in RANGES:
		var fields: Dictionary = RANGES[kind]
		var entries: Array[Dictionary] = []
		var seen: Dictionary = {}
		var found: Array[Dictionary] = reader.rows(root, kind, "")
		for index: int in found.size():
			var item: String = reader.identify(found[index], kind, index, seen)
			var palette: Dictionary = {"id": item}
			for field: String in fields:
				var limits: Array = fields[field]
				palette[field] = reader.whole(found[index], field, item, limits[0], limits[1])
			entries.append(palette)
		_tables[kind] = entries


## Resultado da leitura: `palettes` só vale se `result.ok` (mesmo padrão dos outros carregadores).
class LoadResult:
	extends RefCounted

	var result: Result
	var palettes: CharacterPalettes

	func _init(load_result: Result, loaded_palettes: CharacterPalettes) -> void:
		result = load_result
		palettes = loaded_palettes
