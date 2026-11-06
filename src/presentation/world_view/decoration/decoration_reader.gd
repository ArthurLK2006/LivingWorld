class_name DecorationReader
extends RefCounted
## Lê e VALIDA data/world/decorations.json (LW-043): árvores e pedras só visuais, uma por linha, sem altura (ela vem
## do terreno na hora de montar). Formato em docs/modules/world.md. Não usa src/data: o DataLoader exige um `id` por
## registro e o formato autorizado não tem. Só dados simples; nunca carrega recurso nem executa nada do arquivo.

const KIND_TREE: String = "tree"
const KIND_ROCK: String = "rock"
const KINDS: Array[String] = [KIND_TREE, KIND_ROCK]
const FIELDS: Array[String] = ["kind", "x_cm", "z_cm", "yaw_deg", "scale_pct"]
const MIN_YAW_DEG: int = 0
const MAX_YAW_DEG: int = 359
const MIN_SCALE_PCT: int = 80
const MAX_SCALE_PCT: int = 130
## Faixa de segurança [HIP] das coordenadas (100 km); o mapa de teste tem pouco mais de 1 km.
const MAX_COORDINATE_CM: int = 10000000
const CODE_INVALID: String = "DECORATION_FILE_INVALID"
const ARRAY_OPEN: String = "["
const ARRAY_CLOSE: String = "]"


## Uma decoração do arquivo. A altura NÃO é dado: a TerrainView e a DecorationView a pedem à ponte.
class Item:
	extends RefCounted

	var kind: String = ""
	var x_cm: int = 0
	var z_cm: int = 0
	var yaw_deg: int = 0
	var scale_pct: int = 0


class ReadResult:
	extends RefCounted

	var result: Result = Result.success()
	var items: Array[Item] = []


## Lê o arquivo. Qualquer problema vira falha com arquivo e linha, e nenhuma decoração (lista vazia).
static func read_file(path: String) -> ReadResult:
	var outcome: ReadResult = ReadResult.new()
	if not FileAccess.file_exists(path):
		return _failure(outcome, path, 0, "arquivo não encontrado")
	var text: String = FileAccess.get_file_as_string(path)
	var open_error: Error = FileAccess.get_open_error()
	if open_error != OK:
		return _failure(outcome, path, 0, "não foi possível ler o arquivo (erro %d)" % open_error)
	var lines: PackedStringArray = text.split("\n")
	if lines[0].strip_edges() != ARRAY_OPEN:
		return _failure(outcome, path, 1, "a primeira linha deve ser '[' (uma decoração por linha)")
	var is_closed: bool = false
	for index: int in range(1, lines.size()):
		var line: String = lines[index].strip_edges()
		if line.is_empty():
			continue
		if is_closed:
			return _failure(outcome, path, index + 1, "texto depois do ']' final")
		if line == ARRAY_CLOSE:
			is_closed = true
			continue
		var problem: String = _read_line(outcome, line)
		if not problem.is_empty():
			return _failure(outcome, path, index + 1, problem)
	if not is_closed:
		return _failure(outcome, path, lines.size(), "faltou o ']' final")
	return outcome


static func _failure(outcome: ReadResult, path: String, line: int, message: String) -> ReadResult:
	outcome.items.clear()
	var where: String = path if line < 1 else "%s:%d" % [path, line]
	outcome.result = Result.failure(CODE_INVALID, "%s: %s." % [where, message])
	return outcome


## Lê um objeto (com vírgula final opcional) e o acrescenta a `outcome`. Devolve o problema, ou "" se estiver certo.
static func _read_line(outcome: ReadResult, line: String) -> String:
	var parser: JSON = JSON.new()
	if parser.parse(line.trim_suffix(",")) != OK:
		return "JSON inválido: %s" % parser.get_error_message()
	# Variant é inevitável aqui: é a fronteira com o JSON, conferida logo abaixo.
	var data: Variant = parser.data
	if typeof(data) != TYPE_DICTIONARY:
		return "cada linha deve ser um objeto"
	var record: Dictionary = data
	for field_name: String in FIELDS:
		if not record.has(field_name):
			return "campo '%s' ausente" % field_name
	for key: Variant in record:
		if not FIELDS.has(str(key)):
			return "campo desconhecido '%s'" % str(key)
	var item: Item = Item.new()
	if typeof(record["kind"]) != TYPE_STRING or not KINDS.has(str(record["kind"])):
		return "kind '%s' desconhecido; esperado 'tree' ou 'rock'" % str(record["kind"])
	item.kind = str(record["kind"])
	var ranges: Dictionary[String, Vector2i] = {
		"x_cm": Vector2i(0, MAX_COORDINATE_CM), "z_cm": Vector2i(0, MAX_COORDINATE_CM),
		"yaw_deg": Vector2i(MIN_YAW_DEG, MAX_YAW_DEG), "scale_pct": Vector2i(MIN_SCALE_PCT, MAX_SCALE_PCT),
	}
	var values: Dictionary[String, int] = {}
	for field_name: String in ranges:
		var raw: Variant = record[field_name]
		if (typeof(raw) != TYPE_INT and typeof(raw) != TYPE_FLOAT) or float(raw) != floorf(float(raw)):
			return "campo '%s' deve ser um inteiro" % field_name
		var limits: Vector2i = ranges[field_name]
		if int(raw) < limits.x or int(raw) > limits.y:
			return "campo '%s' = %d fora da faixa %d a %d" % [field_name, int(raw), limits.x, limits.y]
		values[field_name] = int(raw)
	item.x_cm = values["x_cm"]
	item.z_cm = values["z_cm"]
	item.yaw_deg = values["yaw_deg"]
	item.scale_pct = values["scale_pct"]
	outcome.items.append(item)
	return ""
