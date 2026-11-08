class_name Sp2Nav
extends RefCounted
## LW-071 (SP2, DESCARTÁVEL): as navegações candidatas (pergunta P-c), sem física do motor e sem nós: só o TerrainData real.
## N1 (rota simples por pontos): linha reta do ponto atual ao destino; recusa o trecho se a inclinação entre duas amostras passar do
## limite do PlayerBody. N2 (caminho em grade): AStarGrid2D (recurso embutido do Godot 4.7.2) numa grade local que cobre o retângulo da
## rota com margem; célula bloqueada = inclinação acima do limite ou superfície rock. Ambas devolvem a lista de pontos (x, z em metros)
## ou vazia ("sem caminho"). N3 (malha de navegação) não foi construída.

enum Kind { N1_STRAIGHT, N2_GRID }

var _terrain: TerrainData
var _max_slope_tan: float = tan(deg_to_rad(Sp2Constants.MAX_SLOPE_DEGREES))
## Cache das células da N2 (0 = ainda não visto, 1 = livre, 2 = bloqueada): cada célula é calculada uma vez só.
var _blocked_cache: PackedByteArray = PackedByteArray()
var _cache_width: int = 0
## Tempo (µs) da última rota calculada; só para a medição.
var last_route_usec: int = 0


func _init(terrain: TerrainData) -> void:
	_terrain = terrain
	var cells: Vector2i = Vector2i((terrain.peek_size_m() / Sp2Constants.N2_CELL_M).ceil())
	_cache_width = cells.x
	_blocked_cache.resize(cells.x * cells.y)


func route(kind: Kind, from_m: Vector2, to_m: Vector2) -> PackedVector2Array:
	var start_us: int = Time.get_ticks_usec()
	var points: PackedVector2Array = straight_route(from_m, to_m) if kind == Kind.N1_STRAIGHT else grid_route(from_m, to_m)
	last_route_usec = Time.get_ticks_usec() - start_us
	return points


## N1: [destino] se nenhum trecho passa do limite de inclinação; senão vazio.
func straight_route(from_m: Vector2, to_m: Vector2) -> PackedVector2Array:
	var length: float = from_m.distance_to(to_m)
	var samples: int = maxi(1, ceili(length / Sp2Constants.N1_SAMPLE_STEP_M))
	var previous: float = height_m(from_m)
	for index: int in range(1, samples + 1):
		var point: Vector2 = from_m.lerp(to_m, float(index) / float(samples))
		var current: float = height_m(point)
		if absf(current - previous) > _max_slope_tan * (length / float(samples)):
			return PackedVector2Array()
		previous = current
	return PackedVector2Array([to_m])


## N2: caminho pela grade (pontos em metros, o último é o destino exato); vazio se não há caminho.
func grid_route(from_m: Vector2, to_m: Vector2) -> PackedVector2Array:
	var cell: float = Sp2Constants.N2_CELL_M
	var size_m: Vector2 = _terrain.peek_size_m()
	var low: Vector2 = Vector2(maxf(minf(from_m.x, to_m.x) - Sp2Constants.N2_MARGIN_M, 0.0), maxf(minf(from_m.y, to_m.y) - Sp2Constants.N2_MARGIN_M, 0.0))
	var high: Vector2 = Vector2(minf(maxf(from_m.x, to_m.x) + Sp2Constants.N2_MARGIN_M, size_m.x - cell), minf(maxf(from_m.y, to_m.y) + Sp2Constants.N2_MARGIN_M, size_m.y - cell))
	var origin: Vector2i = Vector2i(floori(low.x / cell), floori(low.y / cell))
	var region: Rect2i = Rect2i(origin, Vector2i(floori(high.x / cell), floori(high.y / cell)) - origin + Vector2i.ONE)
	var grid: AStarGrid2D = AStarGrid2D.new()
	grid.region = region
	grid.cell_size = Vector2(cell, cell)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	grid.update()
	for cz: int in range(region.position.y, region.end.y):
		for cx: int in range(region.position.x, region.end.x):
			if _is_cell_blocked_cached(Vector2i(cx, cz)):
				grid.set_point_solid(Vector2i(cx, cz), true)
	var start_cell: Vector2i = Vector2i(floori(from_m.x / cell), floori(from_m.y / cell))
	var end_cell: Vector2i = Vector2i(floori(to_m.x / cell), floori(to_m.y / cell))
	if not region.has_point(start_cell) or not region.has_point(end_cell) or grid.is_point_solid(end_cell):
		return PackedVector2Array()
	# A célula de partida pode estar bloqueada (o corpo já está ali): libera só ela.
	grid.set_point_solid(start_cell, false)
	var cells: Array[Vector2i] = grid.get_id_path(start_cell, end_cell)
	if cells.is_empty():
		return PackedVector2Array()
	var points: PackedVector2Array = PackedVector2Array()
	for index: int in range(1, cells.size() - 1):
		points.append((Vector2(cells[index]) + Vector2(0.5, 0.5)) * cell)
	points.append(to_m)
	return points


func _is_cell_blocked_cached(cell_coord: Vector2i) -> bool:
	var index: int = cell_coord.y * _cache_width + cell_coord.x
	if _blocked_cache[index] == 0:
		_blocked_cache[index] = 2 if is_cell_blocked(cell_coord) else 1
	return _blocked_cache[index] == 2


## Célula da N2 bloqueada: algum canto acima do limite de inclinação em relação ao centro, ou superfície rock no centro.
func is_cell_blocked(cell_coord: Vector2i) -> bool:
	var cell: float = Sp2Constants.N2_CELL_M
	var center: Vector2 = (Vector2(cell_coord) + Vector2(0.5, 0.5)) * cell
	var surface: TerrainData.SurfaceQuery = _terrain.peek_surface(center.x, center.y)
	if surface.result.ok and surface.surface_id == Sp2Constants.ROCK_SURFACE_ID:
		return true
	var middle: float = height_m(center)
	var half_diagonal: float = cell * 0.5 * sqrt(2.0)
	for corner: Vector2 in [Vector2(0.0, 0.0), Vector2(1.0, 0.0), Vector2(0.0, 1.0), Vector2(1.0, 1.0)]:
		if absf(height_m((Vector2(cell_coord) + corner) * cell) - middle) > _max_slope_tan * half_diagonal:
			return true
	return false


## Altura do chão (metros); fora do mapa, 0 (as rotas do spike ficam dentro).
func height_m(point: Vector2) -> float:
	var query: TerrainData.HeightQuery = _terrain.peek_height(point.x, point.y)
	return query.height_m if query.result.ok else 0.0


static func label(kind: Kind) -> String:
	return "N1 rota reta" if kind == Kind.N1_STRAIGHT else "N2 grade A*"
