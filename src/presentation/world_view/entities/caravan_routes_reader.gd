class_name CaravanRoutesReader
extends RefCounted
## LW-099a (viagem visível dos comerciantes; só apresentação): lê e VALIDA data/presentation/caravan_routes.json, o dado de apresentação da caravana
## (contrato técnico da LW-099: docs/economia/contrato-lw-099-viagem-visivel.md, seções 2 e 3). Três blocos: `view` (os números da vista: raio de entrada e de saída do alcance,
## deslocamento lateral, tamanho da reserva de corpos e inclinação máxima do carrinho), `routes` (por `route_id`,
## os pontos de passagem OPCIONAIS `points_m`: pares [x, z] em metros, do povoado `settlement_a_id` para o `settlement_b_id`, SEM as pontas, que vêm dos
## mercados; sem pontos a estrada é a reta) e `cargo` (por `good_id`, a cor `#RRGGBB` e a forma do volume, de um conjunto fechado). TODOS os valores são
## [HIP] PROVISÓRIOS: a afinação é visual, na janela de Arthur; `lateral_offset_m` e `max_pitch_deg` aceitam ZERO (desligam o deslocamento lateral e a inclinação por
## dado) e os demais números são estritamente positivos. Este leitor não conhece a simulação (a apresentação só fala com ela pela ponte): conferir
## que os ids existem em routes.json e goods.json é do teste. Falha tratada, nunca erro: todo problema vira UMA falha com arquivo, item e campo e o dado
## devolvido fica VAZIO (nunca pela metade); o leitor não escreve no log e nada do arquivo é executado.

const DEFAULT_PATH: String = "res://data/presentation/caravan_routes.json"
const CODE_INVALID: String = "CARAVAN_ROUTES_INVALID"
const SUPPORTED_VERSION: int = 1
const VIEW: String = "view"
const ROUTES: String = "routes"
const CARGO: String = "cargo"
const ROUTE_ID: String = "route_id"
const GOOD_ID: String = "good_id"
const POINTS: String = "points_m"
const ROOT_FIELDS: PackedStringArray = ["version", VIEW, ROUTES, CARGO]
const VIEW_FIELDS: PackedStringArray = ["enter_m", "exit_m", "lateral_offset_m", "pool_size", "max_pitch_deg"]
const ROUTE_FIELDS: PackedStringArray = [ROUTE_ID, POINTS]
const CARGO_FIELDS: PackedStringArray = [GOOD_ID, "color", "shape"]
## O volume da carga é desenhado com primitivas: o conjunto de formas é FECHADO (forma nova pede código na vista, não só dado).
const SHAPES: PackedStringArray = ["box", "sack", "barrel", "bundle"]
const COLOR_LENGTH: int = 7
## [HIP] Tetos de segurança, não limites de design: o mapa de teste tem pouco mais de 1 km (metros); a inclinação fica abaixo da vertical; a reserva é pequena.
const MAX_METERS: float = 10000.0
const MAX_PITCH_DEG: float = 89.0
const MAX_POOL_SIZE: int = 64

## Os números da vista (zero até o dado carregar; confira `is_ready`).
var enter_m: float = 0.0
var exit_m: float = 0.0
var lateral_offset_m: float = 0.0
var pool_size: int = 0
var max_pitch_deg: float = 0.0
var _points: Dictionary[String, PackedVector2Array] = {}
var _colors: Dictionary[String, Color] = {}
var _shapes: Dictionary[String, String] = {}


## Lê e valida o arquivo.
static func from_file(path: String = DEFAULT_PATH) -> LoadResult:
	var reader: CharacterDataReader = CharacterDataReader.new(path)
	return _finish(reader, reader.parse_file())


## Igual a `from_file`, para um texto JSON já lido; `label` é o nome do arquivo nas falhas.
static func from_json(content: String, label: String) -> LoadResult:
	var reader: CharacterDataReader = CharacterDataReader.new(label)
	return _finish(reader, reader.parse_json(content))


## Carregado com sucesso (rotas e cargas preenchidas); o dado da falha é vazio.
func is_ready() -> bool:
	return pool_size > 0 and not _points.is_empty() and not _shapes.is_empty()


## Os `route_id` do arquivo, na ordem dele.
func route_ids() -> PackedStringArray:
	return PackedStringArray(_points.keys())


## Os pontos de passagem da rota, de `settlement_a_id` para `settlement_b_id`, SEM as pontas (cópia). Vazio: a estrada é a reta (ou a rota não existe: confira `route_ids`).
func points_of(route_id: String) -> PackedVector2Array:
	return _points[route_id].duplicate() if _points.has(route_id) else PackedVector2Array()


## Os `good_id` com cor e forma, na ordem do arquivo.
func cargo_ids() -> PackedStringArray:
	return PackedStringArray(_shapes.keys())


## A cor do volume do bem; magenta (a cor de "faltou") se o bem não tem entrada.
func cargo_color(good_id: String) -> Color:
	return _colors.get(good_id, Color.MAGENTA)


## A forma do volume do bem (uma de SHAPES); "" se o bem não tem entrada.
func cargo_shape(good_id: String) -> String:
	return _shapes.get(good_id, "")


static func _finish(reader: CharacterDataReader, root: Dictionary) -> LoadResult:
	var loaded: CaravanRoutesReader = CaravanRoutesReader.new()
	if reader.bundle.is_valid():
		loaded._read(reader, root)
	if reader.bundle.is_valid():
		return LoadResult.new(Result.success(), loaded)
	return LoadResult.new(Result.failure(CODE_INVALID, reader.bundle.describe_issues()), CaravanRoutesReader.new())


func _read(reader: CharacterDataReader, root: Dictionary) -> void:
	_reject_unknown(reader, root, ROOT_FIELDS, "")
	reader.whole(root, "version", "", SUPPORTED_VERSION, SUPPORTED_VERSION)
	_read_view(reader, reader.object(root, VIEW, ""))
	_read_routes(reader, reader.rows(root, ROUTES, ""))
	_read_cargo(reader, reader.rows(root, CARGO, ""))


func _read_view(reader: CharacterDataReader, view: Dictionary) -> void:
	_reject_unknown(reader, view, VIEW_FIELDS, VIEW)
	var problems: int = reader.bundle.issues.size()
	enter_m = _number(reader, view, "enter_m", MAX_METERS)
	exit_m = _number(reader, view, "exit_m", MAX_METERS)
	lateral_offset_m = _number(reader, view, "lateral_offset_m", MAX_METERS, true)
	pool_size = reader.whole(view, "pool_size", VIEW, 1, MAX_POOL_SIZE)
	max_pitch_deg = _number(reader, view, "max_pitch_deg", MAX_PITCH_DEG, true)
	if reader.bundle.issues.size() == problems and exit_m <= enter_m:
		reader.fail(VIEW, "exit_m", "exit_m (%s) deve ser maior que enter_m (%s): a diferença é a histerese contra o piscar" % [exit_m, enter_m])


func _read_routes(reader: CharacterDataReader, rows: Array[Dictionary]) -> void:
	var seen: Dictionary[String, bool] = {}
	for index: int in rows.size():
		var item: String = _identify(reader, rows[index], ROUTES, ROUTE_ID, index, seen)
		_reject_unknown(reader, rows[index], ROUTE_FIELDS, item)
		_points[item] = _read_points(reader, rows[index], item)


func _read_cargo(reader: CharacterDataReader, rows: Array[Dictionary]) -> void:
	var seen: Dictionary[String, bool] = {}
	for index: int in rows.size():
		var item: String = _identify(reader, rows[index], CARGO, GOOD_ID, index, seen)
		_reject_unknown(reader, rows[index], CARGO_FIELDS, item)
		var hex: String = reader.text(rows[index], "color", item)
		# `Color.html_is_valid` também aceita sem "#" e com 3, 4 ou 8 dígitos: aqui só vale #RRGGBB.
		var is_color: bool = hex.length() == COLOR_LENGTH and hex.begins_with("#") and Color.html_is_valid(hex)
		if not hex.is_empty() and not is_color:
			reader.fail(item, "color", "'%s' não é uma cor no formato #RRGGBB" % hex)
		_colors[item] = Color.html(hex) if is_color else Color.MAGENTA
		_shapes[item] = reader.choice(rows[index], "shape", item, SHAPES)


## `points_m` é opcional; presente, é uma lista de pares [x, z] de números finitos (até MAX_METERS em módulo).
func _read_points(reader: CharacterDataReader, row: Dictionary, item: String) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	if not row.has(POINTS):
		return points
	var listed: Variant = row[POINTS]  # Variant: fronteira com o JSON, conferido logo abaixo
	if typeof(listed) != TYPE_ARRAY:
		reader.fail(item, POINTS, "tipo inválido: esperado uma lista de pares [x, z]")
		return points
	var pairs: Array = listed
	for index: int in pairs.size():
		var pair: Array = pairs[index] if typeof(pairs[index]) == TYPE_ARRAY else []
		if pair.size() == 2 and _is_coordinate(pair[0]) and _is_coordinate(pair[1]):
			points.append(Vector2(float(pair[0]), float(pair[1])))
		else:
			reader.fail(item, POINTS, "o ponto %d deve ser um par [x, z] de números finitos, de até %s m em módulo" % [index, MAX_METERS])
	return points


## O id de uma linha (texto único na tabela, no campo `field`) e o nome dela nas falhas: o próprio id, ou "tabela[índice]" se o id não presta.
static func _identify(reader: CharacterDataReader, row: Dictionary, table: String, field: String, index: int, seen: Dictionary[String, bool]) -> String:
	var item: String = "%s[%d]" % [table, index]
	var id: String = reader.text(row, field, item)
	if id.is_empty():
		return item
	if seen.has(id):
		reader.fail(id, field, "id repetido na tabela '%s'" % table)
	seen[id] = true
	return id


## Número obrigatório da vista: finito e até `high` (teto de segurança), maior que zero ou, com `allow_zero`, maior ou igual a zero (zero DESLIGA o efeito por
## dado: o deslocamento lateral e o limite de inclinação). Zero, com o problema registrado, se faltar ou não prestar.
static func _number(reader: CharacterDataReader, view: Dictionary, field: String, high: float, allow_zero: bool = false) -> float:
	var value: Variant = view.get(field)  # Variant: fronteira com o JSON, conferido logo abaixo
	if typeof(value) != TYPE_FLOAT and typeof(value) != TYPE_INT:
		reader.fail(VIEW, field, "campo obrigatório ausente" if typeof(value) == TYPE_NIL else "tipo inválido: esperado um número")
		return 0.0
	var number: float = float(value)
	if not is_finite(number) or number < 0.0 or (number == 0.0 and not allow_zero) or number > high:
		reader.fail(VIEW, field, "esperado um número finito %s zero, de até %s" % ["maior ou igual a" if allow_zero else "maior que", high])
		return 0.0
	return number


static func _is_coordinate(value: Variant) -> bool:  # Variant: fronteira com o JSON
	return (typeof(value) == TYPE_FLOAT or typeof(value) == TYPE_INT) and is_finite(float(value)) and absf(float(value)) <= MAX_METERS


static func _reject_unknown(reader: CharacterDataReader, entry: Dictionary, allowed: PackedStringArray, item: String) -> void:
	for field: String in entry:
		if not allowed.has(field):
			reader.fail(item, field, "campo desconhecido")


## Resultado da leitura: `data` só vale se `result.ok` (mesmo padrão dos outros carregadores).
class LoadResult:
	extends RefCounted

	var result: Result
	var data: CaravanRoutesReader

	func _init(load_result: Result, loaded: CaravanRoutesReader) -> void:
		result = load_result
		data = loaded
