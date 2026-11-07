extends GutTest
## LW-047A: o morro de teste íngreme do terreno de blockout (formato dos dados, sem janela). A inclinação é a do ÂNGULO DA NORMAL de cada
## triângulo da malha de 2 m (nas duas diagonais), a mesma que o PlayerBody enfrenta (limite de 40°). Os valores esperados vêm do envio:
## lado íngreme de 45° a 55° (alvo 50°), lado oposto de 25° a 35°, 15 a 20 m de altura, a 60 a 100 m do nascimento, fora do caminho e a mais
## de 25 m dos dois pontos de interesse. O resto do mapa mantém o relevo antigo (declive máximo de 16,49°, medido antes da tarefa).

const COMMITTED_DIR: String = "res://data/world"
const DECORATIONS_PATH: String = "res://data/world/decorations.json"
const CELLS: int = 512
const NODES: int = 513
const CELL_M: float = 2.0
const CM_PER_METER: float = 100.0
const STEEP_MIN_DEG: float = 45.0
const STEEP_MAX_DEG: float = 55.0
const GENTLE_MIN_DEG: float = 25.0
const GENTLE_MAX_DEG: float = 35.0
## Faixa do declive máximo do resto do mapa (medido: 16,49°, a colina antiga) e do mapa inteiro (medido: 50,26°, o morro).
const OLD_RELIEF_MIN_DEG: float = 16.0
const OLD_RELIEF_MAX_DEG: float = 17.0
const WHOLE_MAP_MIN_DEG: float = 49.5
const WHOLE_MAP_MAX_DEG: float = 51.0
const RISE_MIN_M: float = 15.0
const RISE_MAX_M: float = 20.0
const SPAWN_MIN_M: float = 60.0
const SPAWN_MAX_M: float = 100.0
const POI_MIN_M: float = 25.0
const ROAD_NEAR_M: float = 510.0
const ROAD_MARGIN_M: float = 5.0
const CENTER_ROW_TOLERANCE_M: float = 2.0
const PLAIN_M: float = 10.0
const FLAT_TOLERANCE_DEG: float = 0.001
const MIN_BAND_CELLS: int = 20
## Caixa em volta do morro (m), maior que a pegada, para separar "o morro" do "resto do mapa".
const HILL_BOX_X_M: Vector2 = Vector2(140.0, 215.0)
const HILL_BOX_Z_M: Vector2 = Vector2(430.0, 508.0)

var _heights: PackedInt64Array
var _terrain: TerrainData
var _steepest_deg: float = 0.0
var _outside_max_deg: float = 0.0
var _west_line_max_deg: float = 0.0
var _east_line_max_deg: float = 0.0
var _path_max_deg: float = 0.0
var _band_cells: int = 0
var _footprint_cells: Dictionary[Vector2i, bool] = {}


func before_all() -> void:
	var loaded: TerrainLoader.LoadResult = TerrainLoader.load_dir(COMMITTED_DIR)
	assert_true(loaded.result.ok, loaded.result.message)
	_terrain = loaded.terrain
	# O arquivo commitado é idêntico ao gerado (test_blockout_terrain.gd confere); a varredura usa a lista gerada, que é rápida.
	_heights = BlockoutTerrainGenerator.build_heights()
	_scan()


func _node_m(node_x: int, node_z: int) -> float:
	return float(_heights[node_z * NODES + node_x]) / CM_PER_METER


## Maior ângulo entre as normais dos triângulos de uma célula, nas duas diagonais possíveis.
func _cell_max_deg(cell_x: int, cell_z: int) -> float:
	var h00: float = _node_m(cell_x, cell_z)
	var h10: float = _node_m(cell_x + 1, cell_z)
	var h01: float = _node_m(cell_x, cell_z + 1)
	var h11: float = _node_m(cell_x + 1, cell_z + 1)
	var normals: Array[Vector3] = [
		Vector3(CELL_M, h10 - h00, 0.0).cross(Vector3(CELL_M, h11 - h00, CELL_M)),
		Vector3(CELL_M, h11 - h00, CELL_M).cross(Vector3(0.0, h01 - h00, CELL_M)),
		Vector3(CELL_M, h10 - h00, 0.0).cross(Vector3(0.0, h01 - h00, CELL_M)),
		Vector3(0.0, h11 - h10, CELL_M).cross(Vector3(-CELL_M, h01 - h10, CELL_M)),
	]
	var steepest: float = 0.0
	for normal: Vector3 in normals:
		steepest = maxf(steepest, rad_to_deg(acos(absf(normal.normalized().y))))
	return steepest


func _scan() -> void:
	var center_x_m: float = float(BlockoutTerrainGenerator.STEEP_HILL_CENTER_CM.x) / CM_PER_METER
	var center_z_m: float = float(BlockoutTerrainGenerator.STEEP_HILL_CENTER_CM.y) / CM_PER_METER
	var path_from_row: int = floori((float(BlockoutTerrainGenerator.PATH_AXIS_Z_CM - BlockoutTerrainGenerator.PATH_HALF_WIDTH_CM) / CM_PER_METER) / CELL_M)
	var path_to_row: int = floori((float(BlockoutTerrainGenerator.PATH_AXIS_Z_CM + BlockoutTerrainGenerator.PATH_HALF_WIDTH_CM) / CM_PER_METER) / CELL_M)
	for cell_z: int in range(CELLS):
		for cell_x: int in range(CELLS):
			var angle: float = _cell_max_deg(cell_x, cell_z)
			var x_m: float = float(cell_x) * CELL_M
			var z_m: float = float(cell_z) * CELL_M
			_steepest_deg = maxf(_steepest_deg, angle)
			if cell_z >= path_from_row and cell_z <= path_to_row:
				_path_max_deg = maxf(_path_max_deg, angle)
			var in_box: bool = x_m >= HILL_BOX_X_M.x and x_m <= HILL_BOX_X_M.y and z_m >= HILL_BOX_Z_M.x and z_m <= HILL_BOX_Z_M.y
			if not in_box:
				_outside_max_deg = maxf(_outside_max_deg, angle)
				continue
			if angle > STEEP_MIN_DEG and angle < STEEP_MAX_DEG:
				_band_cells += 1
			if absf(z_m - center_z_m) <= CENTER_ROW_TOLERANCE_M:
				if x_m < center_x_m:
					_west_line_max_deg = maxf(_west_line_max_deg, angle)
				else:
					_east_line_max_deg = maxf(_east_line_max_deg, angle)
			# Pegada do morro: células com algum nó acima da planície.
			for corner_z: int in [cell_z, cell_z + 1]:
				for corner_x: int in [cell_x, cell_x + 1]:
					if _node_m(corner_x, corner_z) > PLAIN_M and _node_is_hill(corner_x, corner_z):
						_footprint_cells[Vector2i(cell_x, cell_z)] = true


## Nó levantado pelo morro (e não pela colina antiga): a caixa em volta do morro está longe da colina e do vale.
func _node_is_hill(node_x: int, node_z: int) -> bool:
	return float(node_x) * CELL_M >= HILL_BOX_X_M.x and float(node_x) * CELL_M <= HILL_BOX_X_M.y and float(node_z) * CELL_M >= HILL_BOX_Z_M.x and float(node_z) * CELL_M <= HILL_BOX_Z_M.y


func test_the_hill_has_a_stretch_between_45_and_55_degrees_and_nothing_steeper() -> void:
	assert_gt(_band_cells, MIN_BAND_CELLS, "Há um trecho de 45° a 55°: %d células." % _band_cells)
	assert_between(_steepest_deg, WHOLE_MAP_MIN_DEG, WHOLE_MAP_MAX_DEG, "O declive máximo do mapa inteiro é o do morro: %s°." % str(_steepest_deg))


func test_the_west_side_is_steep_and_the_east_side_is_gentle() -> void:
	assert_between(_west_line_max_deg, STEEP_MIN_DEG, STEEP_MAX_DEG, "Lado oeste (de frente para o nascimento): %s°." % str(_west_line_max_deg))
	assert_between(_east_line_max_deg, GENTLE_MIN_DEG, GENTLE_MAX_DEG, "Lado leste, o oposto: %s°." % str(_east_line_max_deg))


func test_the_rest_of_the_map_keeps_the_old_gentle_relief() -> void:
	assert_between(_outside_max_deg, OLD_RELIEF_MIN_DEG, OLD_RELIEF_MAX_DEG, "Fora do morro o declive máximo segue o de antes (16,49°): %s°." % str(_outside_max_deg))


func test_the_path_is_still_flat_and_the_hill_does_not_touch_it() -> void:
	assert_lte(_path_max_deg, FLAT_TOLERANCE_DEG, "O caminho continua plano: %s°." % str(_path_max_deg))
	var highest_row: int = 0
	for cell: Vector2i in _footprint_cells:
		highest_row = maxi(highest_row, cell.y + 1)
	assert_gt(_footprint_cells.size(), 0, "A pegada existe (o teste não é vazio).")
	assert_lt(float(highest_row) * CELL_M, ROAD_NEAR_M - ROAD_MARGIN_M, "A pegada termina antes do caminho (que começa em 510 m), com folga.")


func test_the_hill_is_15_to_20_meters_high_and_the_peak_is_60_to_100_meters_from_the_spawn() -> void:
	var center: Vector2i = BlockoutTerrainGenerator.STEEP_HILL_CENTER_CM
	var peak_x: float = float(center.x) / CM_PER_METER
	var peak_z: float = float(center.y) / CM_PER_METER
	var rise_m: float = _terrain.peek_height(peak_x, peak_z).height_m - PLAIN_M
	assert_between(rise_m, RISE_MIN_M, RISE_MAX_M, "Subida de %s m." % str(rise_m))
	var spawn: Vector3 = _terrain.peek_spawn_point()
	var distance_m: float = Vector2(peak_x - spawn.x, peak_z - spawn.z).length()
	assert_between(distance_m, SPAWN_MIN_M, SPAWN_MAX_M, "O pico fica a %s m do nascimento." % str(distance_m))


func test_the_spawn_point_did_not_change() -> void:
	var spawn: Vector3 = _terrain.peek_spawn_point()
	assert_eq(Vector2(spawn.x, spawn.z), Vector2(100.0, 512.0))
	assert_almost_eq(spawn.y, PLAIN_M, 0.000001)


func test_the_footprint_is_more_than_25_meters_from_both_points_of_interest() -> void:
	var points: PointOfInterestLoader.LoadResult = PointOfInterestLoader.load_dir(COMMITTED_DIR, _terrain)
	assert_true(points.result.ok, points.result.message)
	var closest_m: float = INF
	for cell: Vector2i in _footprint_cells:
		for point: PointOfInterest in points.points:
			closest_m = minf(closest_m, Vector2(float(cell.x) * CELL_M - point.position.x, float(cell.y) * CELL_M - point.position.z).length())
	assert_gt(closest_m, POI_MIN_M + CELL_M, "A pegada fica a %s m do ponto de interesse mais próximo." % str(closest_m))


func test_no_tree_stands_on_the_hill_and_the_decoration_file_is_unchanged() -> void:
	var read: DecorationReader.ReadResult = DecorationReader.read_file(DECORATIONS_PATH)
	assert_true(read.result.ok, read.result.message)
	var trees_on_hill: int = 0
	for item: DecorationReader.Item in read.items:
		if item.kind == DecorationReader.KIND_TREE and _footprint_cells.has(Vector2i(floori(float(item.x_cm) / CM_PER_METER / CELL_M), floori(float(item.z_cm) / CM_PER_METER / CELL_M))):
			trees_on_hill += 1
	assert_eq(trees_on_hill, 0, "Nenhuma árvore de pé na encosta íngreme.")
	assert_true(BlockoutDecorationsGenerator.run(PackedStringArray(["--check"])).ok, "decorations.json segue idêntico ao que o gerador faz com este terreno.")


func test_generating_twice_gives_the_same_file_as_the_committed_one() -> void:
	var first: Dictionary[String, String] = BlockoutTerrainGenerator.render_files(_heights, BlockoutTerrainGenerator.build_surfaces(_heights))
	var again_heights: PackedInt64Array = BlockoutTerrainGenerator.build_heights()
	var second: Dictionary[String, String] = BlockoutTerrainGenerator.render_files(again_heights, BlockoutTerrainGenerator.build_surfaces(again_heights))
	assert_true(first[BlockoutTerrainGenerator.TERRAIN_FILE] == second[BlockoutTerrainGenerator.TERRAIN_FILE], "Duas gerações dão o mesmo terrain.json.")
	assert_true(FileAccess.get_file_as_string(COMMITTED_DIR.path_join(BlockoutTerrainGenerator.TERRAIN_FILE)) == first[BlockoutTerrainGenerator.TERRAIN_FILE], "E ele é o commitado.")
