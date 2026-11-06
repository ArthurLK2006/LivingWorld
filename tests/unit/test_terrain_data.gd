extends GutTest

## Terreno de teste: 4 x 3 células de 2 m (mapa de 8 x 6 m); o nó (ix, iz) fica em x = 2·ix, z = 2·iz.
const OK_DIR: String = "res://tests/fixtures/world/terrain_ok"
const BAD_DIR: String = "res://tests/fixtures/data/bad"
const TERRAIN_PATH: String = "res://tests/fixtures/world/terrain.json"
const SURFACE_PATH: String = "res://tests/fixtures/world/surface_types.json"
const TOLERANCE: float = 0.000001


func _load_ok() -> TerrainData:
	var loaded: TerrainLoader.LoadResult = TerrainLoader.load_dir(OK_DIR)
	assert_true(loaded.result.ok, loaded.result.message)
	return loaded.terrain


func test_valid_files_load_and_pass_validation() -> void:
	var terrain: TerrainData = _load_ok()
	assert_eq(terrain.validate().size(), 0, str(terrain.validate()))
	assert_eq(terrain.peek_cells(), Vector2i(4, 3))
	assert_almost_eq(terrain.peek_cell_size_m(), 2.0, TOLERANCE)
	assert_eq(terrain.peek_size_m(), Vector2(8.0, 6.0))


func test_height_matches_the_file_at_the_nodes() -> void:
	var terrain: TerrainData = _load_ok()
	# [x, z, altura em metros]: valores do terreno de teste, incluindo uma altura negativa.
	var expected: Array[Array] = [[0.0, 0.0, 0.0], [2.0, 0.0, 1.0], [4.0, 2.0, 17.0], [8.0, 0.0, 4.0], [0.0, 6.0, 30.0], [8.0, 6.0, -2.5]]
	for row: Array in expected:
		var query: TerrainData.HeightQuery = terrain.peek_height(row[0], row[1])
		assert_true(query.result.ok, query.result.message)
		assert_almost_eq(query.height_m, row[2], TOLERANCE, "Altura em x=%s z=%s." % [row[0], row[1]])


func test_height_between_nodes_is_bilinear() -> void:
	var terrain: TerrainData = _load_ok()
	# Centro da célula (0,0); ponto assimétrico (u=0,75 e v=0,25) na mesma célula; centro da célula "torcida" (1,0).
	var expected: Array[Array] = [[1.0, 1.0, 5.5], [1.5, 0.5, 3.25], [3.0, 1.0, 7.75]]
	for row: Array in expected:
		assert_almost_eq(terrain.peek_height(row[0], row[1]).height_m, row[2], TOLERANCE, "Altura em x=%s z=%s." % [row[0], row[1]])


func test_bilinear_stays_within_the_documented_tolerance_of_a_triangle_mesh() -> void:
	var terrain: TerrainData = _load_ok()
	# Célula (1,0), em metros: h00=1, h10=2, h01=11, h11=17. Tolerância do contrato: |h00-h10-h01+h11| / 4.
	var h00: float = 1.0
	var h10: float = 2.0
	var h01: float = 11.0
	var h11: float = 17.0
	var max_difference: float = absf(h00 - h10 - h01 + h11) / 4.0
	for step_u: int in 5:
		for step_v: int in 5:
			var u: float = float(step_u) / 4.0
			var v: float = float(step_v) / 4.0
			# Malha de triângulos com a diagonal h00-h11.
			var triangle: float = h00 + u * (h10 - h00) + v * (h11 - h10) if u >= v else h00 + v * (h01 - h00) + u * (h11 - h01)
			var bilinear: float = terrain.peek_height(2.0 + 2.0 * u, 2.0 * v).height_m
			assert_true(absf(bilinear - triangle) <= max_difference + TOLERANCE, "u=%s v=%s: bilinear %s, triângulo %s." % [u, v, bilinear, triangle])


func test_surface_matches_the_file() -> void:
	var terrain: TerrainData = _load_ok()
	# [x, z, código, id]: um ponto no meio de cada tipo de superfície do terreno de teste.
	var expected: Array[Array] = [[1.0, 1.0, 1, "grass"], [3.0, 3.0, 7, "rock"], [7.0, 1.0, 2, "path"], [1.0, 5.0, 7, "rock"]]
	for row: Array in expected:
		var query: TerrainData.SurfaceQuery = terrain.peek_surface(row[0], row[1])
		assert_true(query.result.ok, query.result.message)
		assert_eq(query.surface_code, row[2], "Código em x=%s z=%s." % [row[0], row[1]])
		assert_eq(query.surface_id, row[3])


func test_surface_on_a_cell_border_belongs_to_the_higher_cell() -> void:
	var terrain: TerrainData = _load_ok()
	assert_eq(terrain.peek_surface(3.999, 1.0).surface_code, 1, "Logo antes da divisa x=4: célula de grama.")
	assert_eq(terrain.peek_surface(4.0, 1.0).surface_code, 2, "Na divisa x=4: célula de maior índice (caminho).")
	assert_eq(terrain.peek_surface(3.0, 1.999).surface_code, 1, "Logo antes da divisa z=2: grama.")
	assert_eq(terrain.peek_surface(3.0, 2.0).surface_code, 7, "Na divisa z=2: célula de maior índice (pedra).")


func test_points_exactly_on_the_map_border_are_inside() -> void:
	var terrain: TerrainData = _load_ok()
	for corner: Array in [[0.0, 0.0], [8.0, 0.0], [0.0, 6.0], [8.0, 6.0]]:
		assert_true(terrain.peek_height(corner[0], corner[1]).result.ok, "Altura no canto %s." % [corner])
		assert_true(terrain.peek_surface(corner[0], corner[1]).result.ok, "Superfície no canto %s." % [corner])
	assert_eq(terrain.peek_surface(8.0, 6.0).surface_code, 1, "A borda final pertence à última célula (3,2).")
	assert_eq(terrain.peek_surface(8.0, 0.0).surface_code, 2, "A borda final pertence à última célula (3,0).")


func test_points_just_outside_each_border_fail_with_a_handled_error() -> void:
	var terrain: TerrainData = _load_ok()
	for point: Array in [[-0.001, 3.0], [8.001, 3.0], [4.0, -0.001], [4.0, 6.001]]:
		var height: TerrainData.HeightQuery = terrain.peek_height(point[0], point[1])
		assert_false(height.result.ok, "Altura fora do mapa em %s." % [point])
		assert_eq(height.result.code, TerrainData.CODE_OUT_OF_BOUNDS)
		assert_string_contains(height.result.message, "fora do mapa")
		var surface: TerrainData.SurfaceQuery = terrain.peek_surface(point[0], point[1])
		assert_false(surface.result.ok, "Superfície fora do mapa em %s." % [point])
		assert_eq(surface.result.code, TerrainData.CODE_OUT_OF_BOUNDS)
		assert_eq(surface.surface_code, TerrainData.NO_SURFACE_CODE)


func test_non_finite_coordinates_fail_with_a_handled_error() -> void:
	var terrain: TerrainData = _load_ok()
	for bad: float in [NAN, INF, -INF]:
		for point: Array in [[bad, 1.0], [1.0, bad]]:
			var height: TerrainData.HeightQuery = terrain.peek_height(point[0], point[1])
			assert_false(height.result.ok, "Altura com %s." % [point])
			assert_eq(height.result.code, TerrainData.CODE_INVALID_COORDINATE)
			assert_string_contains(height.result.message, "não numérica")
			assert_false(terrain.peek_surface(point[0], point[1]).result.ok, "Superfície com %s." % [point])


func test_spawn_point_is_inside_the_map_and_on_the_ground() -> void:
	var terrain: TerrainData = _load_ok()
	var spawn: Vector3 = terrain.peek_spawn_point()
	assert_eq(spawn, Vector3(3.0, 14.0, 2.0), "Nascimento do arquivo: x=300 cm, z=200 cm; altura 14 m entre dois nós.")
	var size: Vector2 = terrain.peek_size_m()
	assert_true(spawn.x >= 0.0 and spawn.x <= size.x and spawn.z >= 0.0 and spawn.z <= size.y, "O nascimento deve estar dentro do mapa.")
	assert_almost_eq(terrain.peek_height(spawn.x, spawn.z).height_m, spawn.y, TOLERANCE)


func test_debug_summary_describes_the_grid() -> void:
	var summary: Dictionary = _load_ok().debug_summary()
	assert_eq(summary["cells_x"], 4)
	assert_eq(summary["node_count"], 20)
	assert_eq(summary["surface_kinds"], 3)
	assert_eq(summary["problems"].size(), 0)


func test_loading_twice_gives_the_same_answers() -> void:
	var first: TerrainData = _load_ok()
	var second: TerrainData = _load_ok()
	var differences: int = 0
	for step_x: int in 17:
		for step_z: int in 13:
			var x: float = 0.5 * float(step_x)
			var z: float = 0.5 * float(step_z)
			if first.peek_height(x, z).height_m != second.peek_height(x, z).height_m or first.peek_surface(x, z).surface_code != second.peek_surface(x, z).surface_code:
				differences += 1
	assert_eq(differences, 0, "Duas cargas do mesmo arquivo devem responder igual.")


func test_validate_reports_an_incoherent_grid_without_crashing() -> void:
	var ids: Dictionary[int, String] = {1: "grass"}
	var broken: TerrainData = TerrainData.new(Vector2i(2, 1), 100, 1, PackedInt64Array([0, 10]), PackedInt64Array([1, 5]), ids, Vector2i(500, 0))
	var problems: String = str(broken.validate())
	assert_string_contains(problems, "alturas: esperado 6 nós, encontrado 2")
	assert_string_contains(problems, "ponto de nascimento (500, 0) cm fora do mapa")
	assert_string_contains(problems, "código 5 não existe")
	assert_eq(broken.peek_spawn_point(), Vector3.ZERO, "Grade incoerente não calcula o nascimento.")


# --- arquivos inválidos ---

func _good_record() -> Dictionary:
	return {"id": "t", "cells_x": 2, "cells_z": 1, "cell_size_cm": 100, "chunk_cells": 1, "spawn_x_cm": 100, "spawn_z_cm": 50, "heights_cm": [0, 10, 20, 30, 40, 50], "surfaces": [1, 2]}


## Valida registros em memória com os mesmos esquemas e verificações do carregamento de arquivos.
func _inspect(terrains: Array, surface_types: Array = []) -> DataBundle:
	var bundle: DataBundle = DataBundle.new()
	bundle.tables[TerrainLoader.TERRAIN_TABLE] = terrains
	bundle.file_paths[TerrainLoader.TERRAIN_TABLE] = TERRAIN_PATH
	bundle.tables[TerrainLoader.SURFACE_TABLE] = surface_types if not surface_types.is_empty() else [{"id": "grass", "code": 1}, {"id": "path", "code": 2}]
	bundle.file_paths[TerrainLoader.SURFACE_TABLE] = SURFACE_PATH
	DataValidator.new().validate(bundle, TerrainLoader.build_schemas())
	TerrainLoader.check_semantics(bundle)
	return bundle


func _assert_reported(bundle: DataBundle, file: String, item: String, field: String, message_part: String) -> void:
	assert_string_contains(bundle.describe_issues(), "%s | item '%s' | campo '%s' | %s" % [file, item, field, message_part])


func test_good_record_has_no_issues() -> void:
	var bundle: DataBundle = _inspect([_good_record()])
	assert_true(bundle.is_valid(), bundle.describe_issues())


func test_missing_and_unknown_fields_are_reported() -> void:
	var record: Dictionary = _good_record()
	record.erase("cell_size_cm")
	record["heigths_cm"] = [1]
	var bundle: DataBundle = _inspect([record])
	_assert_reported(bundle, TERRAIN_PATH, "t", "cell_size_cm", "campo obrigatório ausente")
	_assert_reported(bundle, TERRAIN_PATH, "t", "heigths_cm", "campo desconhecido")


func test_grid_step_must_be_positive() -> void:
	var record: Dictionary = _good_record()
	record["cell_size_cm"] = 0
	_assert_reported(_inspect([record]), TERRAIN_PATH, "t", "cell_size_cm", "valor 0 abaixo do mínimo")


func test_lists_with_the_wrong_size_are_reported() -> void:
	var record: Dictionary = _good_record()
	record["heights_cm"] = [0, 10, 20]
	record["surfaces"] = [1]
	var bundle: DataBundle = _inspect([record])
	_assert_reported(bundle, TERRAIN_PATH, "t", "heights_cm", "tamanho da lista: esperado 6")
	_assert_reported(bundle, TERRAIN_PATH, "t", "surfaces", "tamanho da lista: esperado 2")


func test_height_out_of_range_is_reported() -> void:
	var record: Dictionary = _good_record()
	record["heights_cm"] = [0, 10, 20, 30, 40, TerrainLoader.MAX_HEIGHT_CM + 1]
	_assert_reported(_inspect([record]), TERRAIN_PATH, "t", "heights_cm", "elemento na posição 5: valor 100001 acima do máximo")


func test_unknown_surface_code_is_reported() -> void:
	var record: Dictionary = _good_record()
	record["surfaces"] = [1, 99]
	_assert_reported(_inspect([record]), TERRAIN_PATH, "t", "surfaces", "elemento na posição 1: código de superfície 99 não existe em surface_types.json")


func test_spawn_outside_the_map_is_reported() -> void:
	var record: Dictionary = _good_record()
	record["spawn_x_cm"] = 201
	record["spawn_z_cm"] = 101
	var bundle: DataBundle = _inspect([record])
	_assert_reported(bundle, TERRAIN_PATH, "t", "spawn_x_cm", "ponto de nascimento fora do mapa: x=201 cm, esperado de 0 a 200 cm")
	_assert_reported(bundle, TERRAIN_PATH, "t", "spawn_z_cm", "ponto de nascimento fora do mapa: z=101 cm, esperado de 0 a 100 cm")


func test_repeated_surface_code_is_reported() -> void:
	var bundle: DataBundle = _inspect([_good_record()], [{"id": "grass", "code": 1}, {"id": "path", "code": 1}])
	_assert_reported(bundle, SURFACE_PATH, "path", "code", "código 1 repetido: já é o de 'grass'")


func test_a_file_must_hold_exactly_one_terrain() -> void:
	var other: Dictionary = _good_record()
	other["id"] = "u"
	assert_string_contains(_inspect([_good_record(), other]).describe_issues(), TERRAIN_PATH + " | esperado exatamente 1 terreno no arquivo, encontrado 2")


func test_missing_file_fails_naming_the_file() -> void:
	var loaded: TerrainLoader.LoadResult = TerrainLoader.load_dir(OK_DIR, "no_such_terrain.json")
	assert_false(loaded.result.ok)
	assert_eq(loaded.result.code, TerrainLoader.CODE_INVALID)
	assert_null(loaded.terrain)
	assert_string_contains(loaded.result.message, "no_such_terrain.json | arquivo não encontrado")


func test_malformed_json_fails_with_the_line() -> void:
	var loaded: TerrainLoader.LoadResult = TerrainLoader.load_dir(BAD_DIR, "malformed.json", "not_a_list.json")
	assert_false(loaded.result.ok)
	assert_string_contains(loaded.result.message, "malformed.json | JSON inválido na linha")


# --- chunks (LW-037, DEC-118) ---

## Terreno plano de 4 x 2 células (todas com o código 0), com o tamanho de chunk dado.
func _flat_terrain(chunk_cells: int) -> TerrainData:
	var heights: PackedInt64Array = PackedInt64Array()
	heights.resize(15) # 5 x 3 nós, todos em 0
	var surfaces: PackedInt64Array = PackedInt64Array()
	surfaces.resize(8)
	var ids: Dictionary[int, String] = {0: "grass"}
	return TerrainData.new(Vector2i(4, 2), 100, chunk_cells, heights, surfaces, ids, Vector2i(0, 0))


func test_chunk_metadata_matches_the_file() -> void:
	var terrain: TerrainData = _load_ok()
	assert_eq(terrain.peek_chunk_cells(), 1)
	assert_eq(terrain.peek_chunk_count(), Vector2i(4, 3), "4 x 3 células em chunks de 1 célula.")
	var summary: Dictionary = terrain.debug_summary()
	assert_eq(summary["chunk_cells"], 1)
	assert_eq(summary["chunk_count"], Vector2i(4, 3))


func test_chunk_count_is_the_grid_divided_by_chunk_cells() -> void:
	var terrain: TerrainData = _flat_terrain(2)
	assert_eq(terrain.validate().size(), 0, str(terrain.validate()))
	assert_eq(terrain.peek_chunk_cells(), 2)
	assert_eq(terrain.peek_chunk_count(), Vector2i(2, 1), "4 x 2 células em chunks de 2 células.")


func test_validate_reports_a_chunk_size_that_does_not_divide_the_grid() -> void:
	for chunk_cells: int in [3, 0, -2]:
		var terrain: TerrainData = _flat_terrain(chunk_cells)
		assert_string_contains(str(terrain.validate()), "chunk_cells %d não divide a grade de 4 x 2" % chunk_cells)
		assert_eq(terrain.peek_chunk_count(), Vector2i.ZERO, "Grade incoerente não calcula os chunks.")


func test_chunk_cells_must_divide_the_cells_of_the_file() -> void:
	var record: Dictionary = _good_record()
	record["chunk_cells"] = 3
	var bundle: DataBundle = _inspect([record])
	_assert_reported(bundle, TERRAIN_PATH, "t", "chunk_cells", "células_x (2) não é múltiplo de chunk_cells (3); esperado um divisor de 2")
	_assert_reported(bundle, TERRAIN_PATH, "t", "chunk_cells", "células_z (1) não é múltiplo de chunk_cells (3); esperado um divisor de 1")
	record["chunk_cells"] = 2
	var only_z: String = _inspect([record]).describe_issues()
	assert_string_contains(only_z, "células_z (1) não é múltiplo de chunk_cells (2)")
	assert_false(only_z.contains("células_x"), "chunk_cells 2 divide células_x = 2.")


func test_chunk_cells_out_of_range_is_reported() -> void:
	for row: Array in [[0, "valor 0 abaixo do mínimo"], [-4, "valor -4 abaixo do mínimo"], [TerrainLoader.MAX_CHUNK_CELLS + 1, "valor 257 acima do máximo"]]:
		var record: Dictionary = _good_record()
		record["chunk_cells"] = row[0]
		_assert_reported(_inspect([record]), TERRAIN_PATH, "t", "chunk_cells", row[1])


func test_chunk_cells_is_required() -> void:
	var record: Dictionary = _good_record()
	record.erase("chunk_cells")
	_assert_reported(_inspect([record]), TERRAIN_PATH, "t", "chunk_cells", "campo obrigatório ausente")
