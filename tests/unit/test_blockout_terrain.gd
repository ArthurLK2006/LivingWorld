extends GutTest

## Terreno de blockout (LW-037, DEC-118): gerador, arquivos commitados em data/world e propriedades do
## relevo. As propriedades são RELACIONAIS (colina acima da planície, vale abaixo...) porque os números
## do relevo são [HIP] e mudam na LW-038; já a grade (1.024 m, células de 2 m, chunks de 64 m) é decisão.
const COMMITTED_DIR: String = "res://data/world"
const TOLERANCE: float = 0.000001
const MAP_SIZE_M: float = 1024.0
const CENTIMETERS_PER_METER: float = 100.0

var _heights: PackedInt64Array
var _surfaces: PackedInt64Array
var _files: Dictionary[String, String]
var _loaded: TerrainLoader.LoadResult
var _temp_dirs: Array[DirAccess] = []


func before_all() -> void:
	_heights = BlockoutTerrainGenerator.build_heights()
	_surfaces = BlockoutTerrainGenerator.build_surfaces(_heights)
	_files = BlockoutTerrainGenerator.render_files(_heights, _surfaces)
	_loaded = TerrainLoader.load_dir(_write_to_temp_dir(_files))
	_remove_temp_dirs()


func after_each() -> void:
	_remove_temp_dirs()


## Grava os arquivos numa pasta temporária (a mesma técnica dos testes de save) e devolve o caminho.
func _write_to_temp_dir(files: Dictionary[String, String]) -> String:
	var directory: DirAccess = DirAccess.create_temp("lw037")
	_temp_dirs.append(directory)
	for file_name: String in files:
		_write_text(directory.get_current_dir().path_join(file_name), files[file_name])
	return directory.get_current_dir()


func _write_text(path: String, text: String) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	assert_not_null(file, "Não foi possível gravar %s." % path)
	if file != null:
		file.store_string(text)
		file.close()


func _remove_temp_dirs() -> void:
	for directory: DirAccess in _temp_dirs:
		for file_name: String in directory.get_files():
			DirAccess.remove_absolute(directory.get_current_dir().path_join(file_name))
		DirAccess.remove_absolute(directory.get_current_dir())
	_temp_dirs.clear()


func _height_at_cm(terrain: TerrainData, point_cm: Vector2i) -> float:
	return terrain.peek_height(float(point_cm.x) / CENTIMETERS_PER_METER, float(point_cm.y) / CENTIMETERS_PER_METER).height_m


func _plain_m() -> float:
	return float(BlockoutTerrainGenerator.PLAIN_HEIGHT_CM) / CENTIMETERS_PER_METER


func _assert_blockout_grid(terrain: TerrainData) -> void:
	assert_eq(terrain.peek_cells(), Vector2i(512, 512))
	assert_almost_eq(terrain.peek_cell_size_m(), 2.0, TOLERANCE)
	assert_eq(terrain.peek_size_m(), Vector2(MAP_SIZE_M, MAP_SIZE_M))
	assert_eq(terrain.peek_chunk_cells(), 32)
	assert_eq(terrain.peek_chunk_count(), Vector2i(16, 16), "16 x 16 chunks.")
	assert_almost_eq(float(terrain.peek_chunk_cells()) * terrain.peek_cell_size_m(), 64.0, TOLERANCE, "Chunks de 64 m.")


# --- geração ---

func test_lists_have_one_value_per_node_and_per_cell() -> void:
	assert_eq(_heights.size(), 263169, "513 x 513 nós.")
	assert_eq(_surfaces.size(), 262144, "512 x 512 células.")


func test_two_generations_are_identical_text_for_text() -> void:
	var heights: PackedInt64Array = BlockoutTerrainGenerator.build_heights()
	var second: Dictionary[String, String] = BlockoutTerrainGenerator.render_files(heights, BlockoutTerrainGenerator.build_surfaces(heights))
	assert_eq(second.keys(), _files.keys())
	for file_name: String in _files:
		assert_true(second[file_name] == _files[file_name], "%s difere entre duas gerações." % file_name)


func test_generated_content_loads_and_validates() -> void:
	assert_true(_loaded.result.ok, _loaded.result.message)
	if _loaded.result.ok:
		assert_eq(_loaded.terrain.validate().size(), 0, str(_loaded.terrain.validate()))
		_assert_blockout_grid(_loaded.terrain)


func test_committed_files_are_what_the_tool_generates_and_load() -> void:
	for file_name: String in _files:
		var path: String = COMMITTED_DIR.path_join(file_name)
		assert_true(FileAccess.file_exists(path), "Arquivo ausente: %s" % path)
		assert_true(FileAccess.get_file_as_string(path) == _files[file_name], "%s difere do que a ferramenta gera; rode tools/make_blockout_terrain." % path)
	var loaded: TerrainLoader.LoadResult = TerrainLoader.load_dir(COMMITTED_DIR)
	assert_true(loaded.result.ok, loaded.result.message)
	if loaded.result.ok:
		assert_eq(loaded.terrain.validate().size(), 0, str(loaded.terrain.validate()))
		_assert_blockout_grid(loaded.terrain)
	var checked: Result = BlockoutTerrainGenerator.run(PackedStringArray(["--check"]))
	assert_true(checked.ok, "--check sem --out confere data/world: %s" % checked.message)


# --- relevo ---

func test_hill_is_higher_than_the_plain_and_valley_is_lower() -> void:
	var terrain: TerrainData = _loaded.terrain
	var plain: float = _plain_m()
	assert_gt(_height_at_cm(terrain, BlockoutTerrainGenerator.HILL_CENTER_CM), plain + 1.0, "Topo da colina acima da planície.")
	assert_lt(_height_at_cm(terrain, BlockoutTerrainGenerator.VALLEY_CENTER_CM), plain - 1.0, "Fundo do vale abaixo da planície.")
	for corner: Array in [[0.0, 0.0], [MAP_SIZE_M, 0.0], [0.0, MAP_SIZE_M], [MAP_SIZE_M, MAP_SIZE_M]]:
		assert_almost_eq(terrain.peek_height(corner[0], corner[1]).height_m, plain, TOLERANCE, "Planície no canto %s." % [corner])


func test_path_is_flat_and_paved_from_west_to_east_and_nowhere_else() -> void:
	var terrain: TerrainData = _loaded.terrain
	var band_start_m: float = float(BlockoutTerrainGenerator.PATH_AXIS_Z_CM - BlockoutTerrainGenerator.PATH_HALF_WIDTH_CM) / CENTIMETERS_PER_METER
	var band_end_m: float = float(BlockoutTerrainGenerator.PATH_AXIS_Z_CM + BlockoutTerrainGenerator.PATH_HALF_WIDTH_CM) / CENTIMETERS_PER_METER
	assert_almost_eq(band_end_m - band_start_m, 6.0, TOLERANCE, "Caminho de 6 m de largura.")
	var wrong_surface: int = 0
	var wrong_height: int = 0
	for step: int in 129: # de oeste (0 m) a leste (1.024 m), de 8 em 8 m
		var x: float = 8.0 * float(step)
		for z: float in [band_start_m, band_start_m + 1.5, band_start_m + 3.0, band_end_m - 0.1]:
			wrong_surface += 0 if terrain.peek_surface(x, z).surface_code == BlockoutTerrainGenerator.SURFACE_PATH else 1
			wrong_height += 0 if absf(terrain.peek_height(x, z).height_m - _plain_m()) <= TOLERANCE else 1
		assert_ne(terrain.peek_surface(x, band_start_m - 0.1).surface_code, BlockoutTerrainGenerator.SURFACE_PATH, "Logo antes da faixa (z menor), x=%s." % x)
		assert_ne(terrain.peek_surface(x, band_end_m).surface_code, BlockoutTerrainGenerator.SURFACE_PATH, "A divisa final da faixa (z maior) pertence à célula seguinte, x=%s." % x)
	assert_eq(wrong_surface, 0, "Pontos do caminho sem a superfície path.")
	assert_eq(wrong_height, 0, "Pontos do caminho fora da altura da planície.")


func test_spawn_point_is_inside_the_map_on_the_path_and_to_the_west() -> void:
	var terrain: TerrainData = _loaded.terrain
	var spawn: Vector3 = terrain.peek_spawn_point()
	assert_true(spawn.x >= 0.0 and spawn.x < MAP_SIZE_M * 0.5 and spawn.z >= 0.0 and spawn.z <= MAP_SIZE_M, "Dentro do mapa e na metade oeste: %s." % [spawn])
	assert_eq(terrain.peek_surface(spawn.x, spawn.z).surface_code, BlockoutTerrainGenerator.SURFACE_PATH)
	assert_almost_eq(spawn.y, _plain_m(), TOLERANCE, "O caminho está na altura da planície.")


func test_surfaces_follow_the_relief() -> void:
	var terrain: TerrainData = _loaded.terrain
	var hill: Vector2i = BlockoutTerrainGenerator.HILL_CENTER_CM
	var valley: Vector2i = BlockoutTerrainGenerator.VALLEY_CENTER_CM
	assert_eq(terrain.peek_surface(float(hill.x) / CENTIMETERS_PER_METER, float(hill.y) / CENTIMETERS_PER_METER).surface_code, BlockoutTerrainGenerator.SURFACE_ROCK, "Topo da colina é pedra.")
	assert_eq(terrain.peek_surface(float(valley.x) / CENTIMETERS_PER_METER, float(valley.y) / CENTIMETERS_PER_METER).surface_code, BlockoutTerrainGenerator.SURFACE_GRASS, "Fundo do vale é grama.")
	assert_eq(terrain.peek_surface(50.0, 200.0).surface_code, BlockoutTerrainGenerator.SURFACE_GRASS, "Planície é grama.")


func test_map_corners_and_the_last_surface_cell_can_be_queried() -> void:
	var terrain: TerrainData = _loaded.terrain
	for corner: Array in [[0.0, 0.0], [MAP_SIZE_M, 0.0], [0.0, MAP_SIZE_M], [MAP_SIZE_M, MAP_SIZE_M]]:
		assert_true(terrain.peek_height(corner[0], corner[1]).result.ok, "Altura no canto %s." % [corner])
		assert_true(terrain.peek_surface(corner[0], corner[1]).result.ok, "Superfície no canto %s." % [corner])
	var last_code: int = _surfaces[_surfaces.size() - 1]
	assert_eq(terrain.peek_surface(MAP_SIZE_M, MAP_SIZE_M).surface_code, last_code, "A borda final pertence à última célula.")
	assert_eq(terrain.peek_surface(MAP_SIZE_M - 0.1, MAP_SIZE_M - 0.1).surface_code, last_code)
	assert_false(terrain.peek_height(MAP_SIZE_M + 0.001, 0.0).result.ok, "Fora do mapa continua sendo falha tratada.")


# --- linha de comando ---

func test_unknown_option_is_refused_with_a_clear_message() -> void:
	var outcome: Result = BlockoutTerrainGenerator.run(PackedStringArray(["--bogus"]))
	assert_false(outcome.ok)
	assert_eq(outcome.code, BlockoutTerrainGenerator.CODE_USAGE)
	assert_string_contains(outcome.message, "opção desconhecida: '--bogus'")
	assert_string_contains(outcome.message, BlockoutTerrainGenerator.USAGE)


func test_out_without_a_folder_is_refused() -> void:
	var outcome: Result = BlockoutTerrainGenerator.run(PackedStringArray(["--out"]))
	assert_false(outcome.ok)
	assert_eq(outcome.code, BlockoutTerrainGenerator.CODE_USAGE)
	assert_string_contains(outcome.message, "a opção --out precisa de uma pasta")


func test_missing_output_folder_is_refused_and_nothing_is_created() -> void:
	var missing: String = _write_to_temp_dir({}).path_join("pasta_inexistente")
	var outcome: Result = BlockoutTerrainGenerator.run(PackedStringArray(["--out", missing]))
	assert_false(outcome.ok)
	assert_eq(outcome.code, BlockoutTerrainGenerator.CODE_BAD_OUT_DIR)
	assert_string_contains(outcome.message, "pasta de saída inexistente: %s" % missing)
	assert_false(DirAccess.dir_exists_absolute(missing), "A ferramenta não cria pastas.")


func test_run_writes_the_files_and_check_flags_a_changed_or_missing_one_without_writing() -> void:
	var dir: String = _write_to_temp_dir({})
	var written: Result = BlockoutTerrainGenerator.run(PackedStringArray(["--out", dir]))
	assert_true(written.ok, written.message)
	assert_string_contains(written.message, "Gravado:")
	for file_name: String in _files:
		assert_true(FileAccess.get_file_as_string(dir.path_join(file_name)) == _files[file_name], "%s gravado difere da geração." % file_name)
	var checked: Result = BlockoutTerrainGenerator.run(PackedStringArray(["--check", "--out", dir]))
	assert_true(checked.ok, checked.message)
	assert_string_contains(checked.message, "idênticos")
	var tampered: String = _files[BlockoutTerrainGenerator.SURFACE_FILE].replace("\"code\": 3", "\"code\": 4")
	_write_text(dir.path_join(BlockoutTerrainGenerator.SURFACE_FILE), tampered)
	DirAccess.remove_absolute(dir.path_join(BlockoutTerrainGenerator.TERRAIN_FILE))
	var differs: Result = BlockoutTerrainGenerator.run(PackedStringArray(["--check", "--out", dir]))
	assert_false(differs.ok)
	assert_eq(differs.code, BlockoutTerrainGenerator.CODE_CHECK_DIFFERS)
	assert_string_contains(differs.message, "surface_types.json: conteúdo diferente")
	assert_string_contains(differs.message, "terrain.json: arquivo ausente")
	assert_true(FileAccess.get_file_as_string(dir.path_join(BlockoutTerrainGenerator.SURFACE_FILE)) == tampered, "--check não grava.")
	assert_false(FileAccess.file_exists(dir.path_join(BlockoutTerrainGenerator.TERRAIN_FILE)), "--check não recria o arquivo ausente.")
