class_name CaravanRoutesReader
extends RefCounted
## LW-099a (viagem visível dos comerciantes; só apresentação): lê e VALIDA data/presentation/caravan_routes.json, o dado de apresentação da caravana
## (contrato técnico da LW-099: docs/economia/contrato-lw-099-viagem-visivel.md, seções 2 e 3). Quatro blocos: `view` (os números da vista: raio de entrada e de saída do alcance,
## deslocamento lateral, tamanho da reserva de corpos e inclinação máxima do carrinho), `routes` (por `route_id`, os pontos de passagem OPCIONAIS `points_m`: pares [x, z] em metros,
## do povoado `settlement_a_id` para o outro, SEM as pontas; `settlement_a_id` é opcional, mas OBRIGATÓRIO com pontos: é ele que dá o SENTIDO deles, e o leitor nunca o adivinha), `docks`
## (LW-099g, opcional: por `settlement_id`, a DOCA `point_m` [x, z], o ponto onde a caravana do povoado nasce e termina, fora da peça central do mercado; sem doca a ponta é o mercado) e `cargo`
## (por `good_id`, a cor `#RRGGBB` e a forma do volume, de um conjunto fechado). `leg_line` monta a polilinha COMPLETA de um trecho no sentido da marcha (ponta de saída, pontos na ordem certa, ponta
## de chegada): a vista não monta estrada por outro caminho. TODOS os valores são
## [HIP] PROVISÓRIOS: a afinação é visual, na janela de Arthur; `lateral_offset_m` e `max_pitch_deg` aceitam ZERO (desligam o deslocamento lateral e a inclinação por
## dado) e os demais números são estritamente positivos. Este leitor não conhece a simulação (a apresentação só fala com ela pela ponte): conferir
## que os ids existem em routes.json, places.json e goods.json é do teste. Falha tratada, nunca erro: todo problema vira UMA falha com arquivo, item e campo e o dado
## devolvido fica VAZIO (nunca pela metade); o leitor não escreve no log e nada do arquivo é executado.

const DEFAULT_PATH: String = "res://data/presentation/caravan_routes.json"
const CODE_INVALID: String = "CARAVAN_ROUTES_INVALID"
const SUPPORTED_VERSION: int = 1
const VIEW: String = "view"
const ROUTES: String = "routes"
const CARGO: String = "cargo"
const DOCKS: String = "docks"
const ROUTE_ID: String = "route_id"
const GOOD_ID: String = "good_id"
const POINTS: String = "points_m"
const SETTLEMENT_A: String = "settlement_a_id"
const SETTLEMENT_ID: String = "settlement_id"
const DOCK_POINT: String = "point_m"
const ROOT_FIELDS: PackedStringArray = ["version", VIEW, ROUTES, CARGO, DOCKS]
const VIEW_FIELDS: PackedStringArray = ["enter_m", "exit_m", "lateral_offset_m", "pool_size", "max_pitch_deg"]
const ROUTE_FIELDS: PackedStringArray = [ROUTE_ID, SETTLEMENT_A, POINTS]
const DOCK_FIELDS: PackedStringArray = [SETTLEMENT_ID, DOCK_POINT]
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
## O `settlement_a_id` de cada rota que o declara (as outras ficam fora do dicionário).
var _route_a: Dictionary[String, String] = {}
## A doca (x, z em metros) de cada povoado que tem uma.
var _docks: Dictionary[String, Vector2] = {}
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


## Os pontos de passagem da rota, do povoado `settlement_a_id` (`route_a_of`) para o outro, SEM as pontas (cópia). Vazio: a estrada é a reta (ou a rota não existe: confira `route_ids`).
func points_of(route_id: String) -> PackedVector2Array:
	return _points[route_id].duplicate() if _points.has(route_id) else PackedVector2Array()


## O `settlement_a_id` da rota (o povoado de onde `points_of` conta os pontos); "" se a rota não o declara (só vale sem pontos) ou não existe.
func route_a_of(route_id: String) -> String:
	return _route_a.get(route_id, "")


## Se o povoado tem doca no dado.
func has_dock(settlement_id: String) -> bool:
	return _docks.has(settlement_id)


## A doca do povoado: onde a caravana dele nasce e termina (x, z em metros); `Vector2.ZERO` se ele não tem (confira `has_dock`).
func dock_of(settlement_id: String) -> Vector2:
	return _docks.get(settlement_id, Vector2.ZERO)


## Os povoados com doca, na ordem do arquivo.
func dock_ids() -> PackedStringArray:
	return PackedStringArray(_docks.keys())


## A polilinha COMPLETA do trecho de `from_settlement_id` a `to_settlement_id` da rota, no sentido da marcha (cópia nova; só se chama quando o trecho muda, nunca por quadro): a ponta de saída
## (a doca do povoado de saída, ou `from_market` se ele não tem doca), os pontos de passagem da rota (na ordem do dado se o povoado de saída é o `settlement_a_id` da rota; invertidos se não)
## e a ponta de chegada (a doca do povoado de chegada, ou `to_market`). Rota sem pontos, ou que o dado não tem: só as duas pontas (a reta). Pura: a mesma entrada dá a mesma saída.
func leg_line(route_id: String, from_settlement_id: String, to_settlement_id: String, from_market: Vector2, to_market: Vector2) -> PackedVector2Array:
	var start: Vector2 = _docks.get(from_settlement_id, from_market)
	var finish: Vector2 = _docks.get(to_settlement_id, to_market)
	var via: PackedVector2Array = points_of(route_id)
	if from_settlement_id != route_a_of(route_id):
		via.reverse()
	var line: PackedVector2Array = PackedVector2Array()
	line.append(start)
	line.append_array(via)
	line.append(finish)
	return line


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
	if root.has(DOCKS):
		_read_docks(reader, reader.rows(root, DOCKS, ""))


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
		_read_settlement_a(reader, rows[index], item, not _points[item].is_empty())


## Uma doca por povoado (`settlement_id` único); a doca é o par `point_m` [x, z]. Que o povoado existe é conferido no teste, não aqui.
func _read_docks(reader: CharacterDataReader, rows: Array[Dictionary]) -> void:
	var seen: Dictionary[String, bool] = {}
	for index: int in rows.size():
		var item: String = _identify(reader, rows[index], DOCKS, SETTLEMENT_ID, index, seen)
		_reject_unknown(reader, rows[index], DOCK_FIELDS, item)
		var listed: Variant = rows[index].get(DOCK_POINT)  # Variant: fronteira com o JSON, conferido logo abaixo
		if not _is_point(listed):
			reader.fail(item, DOCK_POINT, "campo obrigatório: um par [x, z] de números finitos, de até %s m em módulo" % MAX_METERS)
			continue
		var pair: Array = listed
		_docks[item] = Vector2(float(pair[0]), float(pair[1]))


## `settlement_a_id` é opcional, mas OBRIGATÓRIO com pontos de passagem: é ele que diz de que ponta da rota os pontos são contados (o dado não adivinha o sentido).
func _read_settlement_a(reader: CharacterDataReader, row: Dictionary, item: String, has_points: bool) -> void:
	if not row.has(SETTLEMENT_A):
		if has_points:
			reader.fail(item, SETTLEMENT_A, "obrigatório quando a rota tem pontos de passagem (%s): é ele que dá o sentido dos pontos" % POINTS)
		return
	var settlement_a: String = reader.text(row, SETTLEMENT_A, item)
	if not settlement_a.is_empty():
		_route_a[item] = settlement_a


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
		if _is_point(pairs[index]):
			var pair: Array = pairs[index]
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


## Um par [x, z] de números finitos, de até MAX_METERS em módulo.
static func _is_point(value: Variant) -> bool:  # Variant: fronteira com o JSON
	if typeof(value) != TYPE_ARRAY:
		return false
	var pair: Array = value
	return pair.size() == 2 and _is_coordinate(pair[0]) and _is_coordinate(pair[1])


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
