class_name RouteObstacles
extends RefCounted
## LW-099g (ajudante dos testes de folga e colisão das caravanas; só leitura, sem estado de jogo): o que o carrinho NÃO pode tocar e a conta da folga. OBSTÁCULOS, todos polígonos CONVEXOS no plano (x, z, metros): (i) as CAIXAS dos locais de data/world/places.json
## (retângulos alinhados aos eixos e centrados no local, de `PlacePalette.SIZES`; o mercado fica de fora, porque a praça esconde a caixa dele) e (ii) os objetos de cada praça de mercado, tal como a PRÓPRIA praça os põe: o casco convexo do rastro no chão de cada peça (barracas com a
## peça de pano e as varas, peça central, postes de lampião, tochas, árvores e rochas; sem grama, flores nem bandeirolas) do `MarketPlazaView` montado com a escala de encaixe dele. A peça é o que a praça desenha (nada a mais, nada a menos), e `test_route_obstacles.gd` prova que as POSIÇÕES batem
## com as constantes de `plaza_data.gd` e `plaza_variants.gd` e que o casco bate com o que elas dizem (a copa da tenda, o toldo, as pedras da peça central). Os adereços das barracas (caixotes, barris, sacos) e os arbustos de C ficam à parte (`is_minor`): a folga contra eles é só informativa.
## (iii) as DECORAÇÕES do mundo (data/world/decorations.json, lidas por `DecorationReader`): cada árvore é um CÍRCULO do raio da copa (`DecorationShapes.CROWN_RADIUS_M` x `scale_pct`/100) e cada pedra um círculo de `ROCK_RADIUS_M` x `scale_pct`/100, no centro (`x_cm`, `z_cm`)/100, conservadores; `test_route_obstacles.gd` prova que são as que a `DecorationView` desenha.
## Uma grade de células de CELL_M metros guarda os obstáculos (são milhares) para `nearest` olhar só os vizinhos.
## O CARRINHO é o retângulo `cart_polygon` (0,30 m à frente dos pés a 2,90 m atrás deles, meia largura do centro da roda à ponta do raio dela, 0,625 m), girado pelo giro do corpo; `gap_between` dá a folga: 0 ou negativa = toca ou atravessa (o negativo é a menor penetração).

## Prefixos dos nós da praça que contam como obstáculo (o nome da peça mais o número dela) e os que só informam.
const MAJOR_PREFIXES: PackedStringArray = ["Stall", "LampPost", "Torch", "Well", "Fountain", "Rotunda", "Tree", "Rock"]
const MINOR_PREFIXES: PackedStringArray = ["Crate", "Barrel", "Sack", "Bush"]
const PLACES_FILE: String = "res://data/world/places.json"
const DECORATIONS_FILE: String = "res://data/world/decorations.json"
const CM_PER_M: float = 100.0
const PERCENT: float = 100.0
## Lado das células da grade de busca (m): maior que a maioria dos obstáculos, menor que o alcance da busca.
const CELL_M: float = 16.0
## O retângulo do carrinho no quadro do corpo (origem nos pés, a frente é -Z, o carrinho vem atrás): [HIP] da missão, 0,30 m à frente dos pés (a cápsula do comerciante) e até o fim do leito atrás.
const CART_AHEAD_M: float = 0.30
const CART_BEHIND_M: float = CaravanView.CART_BACK_M + CaravanView.BED_SIZE_M.z * 0.5
## A meia largura é a do raio da roda (a barra de `SPOKE_SIZE_M.x`, mais larga que o pneu), que sai 2 cm além dos 0,605 m do pneu: o retângulo é o que se vê (provado em test_route_obstacles.gd).
const CART_HALF_WIDTH_M: float = CaravanView.WHEEL_SIDE_M + CaravanView.SPOKE_SIZE_M.x * 0.5
## Distância (m) a partir da qual um obstáculo deixa de contar na busca da menor folga (longe demais para importar: o alvo é 0,5 m e o piso, 0,3 m).
const SEARCH_RANGE_M: float = 3.0

## Todos os obstáculos (os principais e os que só informam).
var items: Array[Item] = []
## A escala de encaixe de cada praça (por id do local mercado).
var plaza_scale: Dictionary[String, float] = {}
var _by_id: Dictionary[String, Item] = {}
var _grid: Dictionary[Vector2i, Array] = {}
var _query: int = 0


## Monta os obstáculos: as caixas dos locais e as peças das praças que o `MarketPlazaView` monta sobre `bridge` (uma ponte com o terreno e os locais reais, como a `ScriptedCaravanBridge`).
static func build(bridge: SimBridge) -> RouteObstacles:
	var built: RouteObstacles = RouteObstacles.new()
	var rows: Variant = JSON.parse_string(FileAccess.get_file_as_string(PLACES_FILE))  # Variant: fronteira com o JSON, conferido abaixo
	if typeof(rows) == TYPE_ARRAY:
		var places: Array = rows
		for row: Variant in places:
			if typeof(row) == TYPE_DICTIONARY:
				built._add_place(row)
	built._add_decorations()
	var plazas: MarketPlazaView = MarketPlazaView.new()
	if plazas.setup(bridge):
		for place: BridgeReplies.PlaceReply in bridge.peek_places().places:
			if place.kind == PlacePalette.KIND_MARKET:
				built._add_plaza(place.id, plazas.plaza_of(place.id))
	plazas.free()
	return built


## O retângulo do carrinho com os pés em `feet` e o giro `yaw` (rad, em torno de Y, como `CaravanView.rotation.y`): a frente do corpo é (-sen, -cos) no plano (x, z).
static func cart_polygon(feet: Vector2, yaw: float) -> PackedVector2Array:
	var polygon: PackedVector2Array = PackedVector2Array()
	for corner: Vector2 in [Vector2(-CART_HALF_WIDTH_M, -CART_AHEAD_M), Vector2(CART_HALF_WIDTH_M, -CART_AHEAD_M), Vector2(CART_HALF_WIDTH_M, CART_BEHIND_M), Vector2(-CART_HALF_WIDTH_M, CART_BEHIND_M)]:
		polygon.append(feet + Vector2(corner.x * cos(yaw) + corner.y * sin(yaw), -corner.x * sin(yaw) + corner.y * cos(yaw)))
	return polygon


## A folga (m) entre dois polígonos CONVEXOS: positiva se há espaço entre eles, 0 se se encostam, negativa se se cruzam (menos a menor penetração).
static func gap_between(first: PackedVector2Array, second: PackedVector2Array) -> float:
	var depth: float = INF
	var base: Vector2 = first[0]
	for polygon: PackedVector2Array in [first, second]:
		for index: int in polygon.size():
			var edge: Vector2 = polygon[(index + 1) % polygon.size()] - polygon[index]
			if edge == Vector2.ZERO:
				continue
			var axis: Vector2 = Vector2(-edge.y, edge.x).normalized()
			var a_span: Vector2 = _span(first, axis, base)
			var b_span: Vector2 = _span(second, axis, base)
			var overlap: float = minf(a_span.y, b_span.y) - maxf(a_span.x, b_span.x)
			if overlap <= 0.0:
				return minf(_boundary_gap(first, second), _boundary_gap(second, first))
			depth = minf(depth, overlap)
	return -depth


## O ponto está dentro do polígono convexo (ou a até `tolerance_m` dele)?
static func contains(polygon: PackedVector2Array, point: Vector2, tolerance_m: float = 0.0) -> bool:
	var sign_of_area: float = signf(_area(polygon))
	for index: int in polygon.size():
		var from: Vector2 = polygon[index]
		var edge: Vector2 = polygon[(index + 1) % polygon.size()] - from
		if edge != Vector2.ZERO and sign_of_area * edge.cross(point - from) / edge.length() < -tolerance_m:
			return false
	return true


## A distância (m) do ponto ao polígono convexo (0 se está dentro).
static func point_gap(polygon: PackedVector2Array, point: Vector2) -> float:
	return 0.0 if contains(polygon, point) else _boundary_gap(PackedVector2Array([point]), polygon)


## O obstáculo com este id ("a_work_07" para um local; "a_market_01/Stall0" para uma peça da praça), ou nulo.
func item(item_id: String) -> Item:
	return _by_id.get(item_id) as Item


## O obstáculo mais perto do polígono dentro de SEARCH_RANGE_M, entre os principais (`minor` falso) ou entre os que só informam (`minor` verdadeiro): `Hit.gap_m` é a folga, INF e `item` nulo se nenhum está ao alcance. Só olha as células da grade que o alcance cobre.
func nearest(polygon: PackedVector2Array, minor: bool = false) -> Hit:
	var hit: Hit = Hit.new()
	var reach: Rect2 = _bounds_of(polygon).grow(SEARCH_RANGE_M)
	var low: Vector2i = Vector2i((reach.position / CELL_M).floor())
	var high: Vector2i = Vector2i((reach.end / CELL_M).floor())
	_query += 1
	for cell_x: int in range(low.x, high.x + 1):
		for cell_z: int in range(low.y, high.y + 1):
			for entry: Item in _grid.get(Vector2i(cell_x, cell_z), []):
				if entry.last_query == _query or entry.is_minor != minor:
					continue
				entry.last_query = _query
				if not reach.intersects(entry.bounds, true):
					continue
				var gap: float = gap_to(entry, polygon)
				if gap < hit.gap_m:
					hit.gap_m = gap
					hit.item = entry
	return hit


## A folga (m) entre o polígono convexo e o obstáculo (casco ou círculo): positiva se há espaço, 0 se se encostam, negativa se se cruzam.
static func gap_to(entry: Item, polygon: PackedVector2Array) -> float:
	if not entry.is_circle:
		return gap_between(polygon, entry.hull)
	var centre_gap: float = _boundary_gap(PackedVector2Array([entry.origin]), polygon)
	return -(entry.radius + centre_gap) if contains(polygon, entry.origin) else centre_gap - entry.radius


func _add_place(row: Dictionary) -> void:
	var kind: String = str(row["kind"])
	if kind == PlacePalette.KIND_MARKET or not PlacePalette.is_drawn(kind):
		return
	var center: Vector2 = Vector2(float(row["x_cm"]), float(row["z_cm"])) / CM_PER_M
	var half: Vector2 = Vector2(PlacePalette.SIZES[kind].x, PlacePalette.SIZES[kind].z) * 0.5
	var hull: PackedVector2Array = PackedVector2Array([center - half, center + Vector2(half.x, -half.y), center + half, center + Vector2(-half.x, half.y)])
	_register(str(row["id"]), kind, center, hull, false)


## Uma peça da praça por nó filho de nome conhecido: o casco do rastro das malhas dela, no mundo (a praça fica no x e no z do local, com a escala de encaixe).
func _add_plaza(market_id: String, plaza: Node3D) -> void:
	plaza_scale[market_id] = plaza.scale.x
	for child: Node in plaza.get_children():
		var mesh_node: MeshInstance3D = child as MeshInstance3D
		if mesh_node == null:
			continue
		var node_name: String = str(child.name)
		var major: String = _prefix_of(node_name, MAJOR_PREFIXES)
		var minor: String = _prefix_of(node_name, MINOR_PREFIXES)
		if major.is_empty() and minor.is_empty():
			continue
		var placement: Transform3D = plaza.transform * mesh_node.transform
		_register("%s/%s" % [market_id, node_name], major if minor.is_empty() else minor, Vector2(placement.origin.x, placement.origin.z), _hull_of(mesh_node.mesh, placement), not minor.is_empty())


## As árvores e pedras do mundo, na ordem do arquivo (o id é o tipo e o número dentro do tipo: "tree612"): círculos conservadores com a escala de cada uma.
func _add_decorations() -> void:
	var read: DecorationReader.ReadResult = DecorationReader.read_file(DECORATIONS_FILE)
	if not read.result.ok:
		push_error("RouteObstacles: decorações ilegíveis: %s" % read.result.message)
		return
	var counts: Dictionary[String, int] = {}
	for entry: DecorationReader.Item in read.items:
		var number: int = counts.get(entry.kind, 0)
		counts[entry.kind] = number + 1
		var base_m: float = DecorationShapes.CROWN_RADIUS_M if entry.kind == DecorationReader.KIND_TREE else DecorationShapes.ROCK_RADIUS_M
		var circle: Item = _register("%s%d" % [entry.kind, number], entry.kind, Vector2(entry.x_cm, entry.z_cm) / CM_PER_M, PackedVector2Array(), false)
		circle.is_circle = true
		circle.radius = base_m * float(entry.scale_pct) / PERCENT
		circle.bounds = Rect2(circle.origin - Vector2.ONE * circle.radius, Vector2.ONE * circle.radius * 2.0)
		_index(circle)


func _register(item_id: String, type: String, origin: Vector2, hull: PackedVector2Array, is_minor: bool) -> Item:
	var entry: Item = Item.new()
	entry.id = item_id
	entry.type = type
	entry.origin = origin
	entry.hull = hull
	entry.bounds = _bounds_of(hull) if not hull.is_empty() else Rect2(origin, Vector2.ZERO)
	entry.is_minor = is_minor
	items.append(entry)
	_by_id[item_id] = entry
	if not hull.is_empty():
		_index(entry)
	return entry


## Põe o obstáculo em todas as células da grade que a caixa dele toca.
func _index(entry: Item) -> void:
	var low: Vector2i = Vector2i((entry.bounds.position / CELL_M).floor())
	var high: Vector2i = Vector2i((entry.bounds.end / CELL_M).floor())
	for cell_x: int in range(low.x, high.x + 1):
		for cell_z: int in range(low.y, high.y + 1):
			var cell: Vector2i = Vector2i(cell_x, cell_z)
			if not _grid.has(cell):
				_grid[cell] = []
			_grid[cell].append(entry)


## O prefixo de `allowed` com que o nome começa (e que só é seguido de dígitos), ou "".
static func _prefix_of(node_name: String, allowed: PackedStringArray) -> String:
	for prefix: String in allowed:
		if node_name == prefix or (node_name.begins_with(prefix) and node_name.substr(prefix.length()).is_valid_int()):
			return prefix
	return ""


## O casco convexo (sem repetir o primeiro ponto) do rastro no chão de todos os vértices da malha, levados ao mundo por `placement`.
static func _hull_of(mesh: Mesh, placement: Transform3D) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for surface: int in mesh.get_surface_count():
		var vertices: PackedVector3Array = mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
		for vertex: Vector3 in vertices:
			var world: Vector3 = placement * vertex
			points.append(Vector2(world.x, world.z))
	var hull: PackedVector2Array = Geometry2D.convex_hull(points)
	if hull.size() > 1 and hull[0] == hull[hull.size() - 1]:
		hull.remove_at(hull.size() - 1)
	return hull


static func _bounds_of(polygon: PackedVector2Array) -> Rect2:
	var bounds: Rect2 = Rect2(polygon[0], Vector2.ZERO)
	for point: Vector2 in polygon:
		bounds = bounds.expand(point)
	return bounds


## O intervalo (menor, maior) das projeções do polígono no eixo (unitário), contadas a partir de `base` (os vetores são de 32 bits: coordenadas de centenas de metros perderiam os milímetros).
static func _span(polygon: PackedVector2Array, axis: Vector2, base: Vector2) -> Vector2:
	var low: float = INF
	var high: float = -INF
	for point: Vector2 in polygon:
		var along: float = (point - base).dot(axis)
		low = minf(low, along)
		high = maxf(high, along)
	return Vector2(low, high)


## A menor distância de um vértice de `from` a uma aresta de `onto` (dois polígonos separados: a distância entre eles é a menor entre os dois sentidos).
static func _boundary_gap(from: PackedVector2Array, onto: PackedVector2Array) -> float:
	var best: float = INF
	for point: Vector2 in from:
		for index: int in onto.size():
			var nearest_point: Vector2 = Geometry2D.get_closest_point_to_segment(point, onto[index], onto[(index + 1) % onto.size()])
			best = minf(best, point.distance_to(nearest_point))
	return best


## A área com sinal do polígono (a ordem dos vértices pode ser qualquer uma), contada a partir do 1º vértice (precisão de 32 bits).
static func _area(polygon: PackedVector2Array) -> float:
	var twice: float = 0.0
	for index: int in polygon.size():
		twice += (polygon[index] - polygon[0]).cross(polygon[(index + 1) % polygon.size()] - polygon[0])
	return twice * 0.5


## Um obstáculo: o id, o tipo (o `kind` do local ou o prefixo do nó da praça), a origem (o centro do local, ou a origem do nó da praça), o casco convexo e a caixa que o contém.
class Item:
	extends RefCounted

	var id: String = ""
	var type: String = ""
	var origin: Vector2 = Vector2.ZERO
	var hull: PackedVector2Array = PackedVector2Array()
	var bounds: Rect2 = Rect2()
	var is_minor: bool = false
	## Decoração (árvore ou pedra): um CÍRCULO de `radius` metros em `origin`, sem casco.
	var is_circle: bool = false
	var radius: float = 0.0
	## Número da última busca que olhou este obstáculo (para não contá-lo duas vezes quando ele ocupa várias células).
	var last_query: int = 0


## A menor folga achada (`gap_m` INF se nenhum obstáculo está ao alcance) e o obstáculo dela.
class Hit:
	extends RefCounted

	var gap_m: float = INF
	var item: Item
