class_name TerrainLoader
extends RefCounted
## Lê os arquivos de terreno de data/world/ pelo módulo `data`, confere o que o esquema genérico não
## enxerga (tamanhos das listas, códigos de superfície, ponto de nascimento) e monta o TerrainData.
## Formato e convenções em docs/modules/world.md. Nunca carrega recurso nem executa nada do arquivo.

const TERRAIN_TABLE: String = "terrain"
const SURFACE_TABLE: String = "surface_types"
const DEFAULT_TERRAIN_FILE: String = "terrain.json"
const DEFAULT_SURFACE_FILE: String = "surface_types.json"
const CODE_INVALID: String = "TERRAIN_DATA_INVALID"
## Faixas de segurança [HIP]: protegem contra arquivo absurdo e NÃO são o tamanho do terreno do jogo
## (isso é da LW-037 e da DEC-055, pendente).
const MAX_CELLS_PER_SIDE: int = 4096
const MIN_CELL_SIZE_CM: int = 1
const MAX_CELL_SIZE_CM: int = 100000
const MAX_COORDINATE_CM: int = MAX_CELLS_PER_SIDE * MAX_CELL_SIZE_CM
const MIN_HEIGHT_CM: int = -100000
const MAX_HEIGHT_CM: int = 100000
const MAX_SURFACE_CODE: int = 65535
const INT_FIELDS: Array[String] = ["cells_x", "cells_z", "cell_size_cm", "spawn_x_cm", "spawn_z_cm"]
const LIST_FIELDS: Array[String] = ["heights_cm", "surfaces"]


## Esquemas das duas tabelas; os nomes dos arquivos podem ser trocados (testes).
static func build_schemas(terrain_file: String = DEFAULT_TERRAIN_FILE, surface_file: String = DEFAULT_SURFACE_FILE) -> Array[DataSchema]:
	var terrain: DataSchema = DataSchema.new(TERRAIN_TABLE, terrain_file)
	terrain.add_field("cells_x", DataSchema.FieldType.INT).set_range(1, MAX_CELLS_PER_SIDE)
	terrain.add_field("cells_z", DataSchema.FieldType.INT).set_range(1, MAX_CELLS_PER_SIDE)
	terrain.add_field("cell_size_cm", DataSchema.FieldType.INT).set_range(MIN_CELL_SIZE_CM, MAX_CELL_SIZE_CM)
	terrain.add_field("spawn_x_cm", DataSchema.FieldType.INT).set_range(0, MAX_COORDINATE_CM)
	terrain.add_field("spawn_z_cm", DataSchema.FieldType.INT).set_range(0, MAX_COORDINATE_CM)
	terrain.add_field("heights_cm", DataSchema.FieldType.INT_LIST).set_range(MIN_HEIGHT_CM, MAX_HEIGHT_CM)
	terrain.add_field("surfaces", DataSchema.FieldType.INT_LIST).set_range(0, MAX_SURFACE_CODE)
	var surface_types: DataSchema = DataSchema.new(SURFACE_TABLE, surface_file)
	surface_types.add_field("code", DataSchema.FieldType.INT).set_range(0, MAX_SURFACE_CODE)
	var schemas: Array[DataSchema] = [terrain, surface_types]
	return schemas


## Lê, valida e monta o terreno. Qualquer problema vira falha com a lista (arquivo, item e campo).
static func load_dir(base_dir: String, terrain_file: String = DEFAULT_TERRAIN_FILE, surface_file: String = DEFAULT_SURFACE_FILE) -> LoadResult:
	var bundle: DataBundle = DataLoader.load_all(base_dir, build_schemas(terrain_file, surface_file))
	check_semantics(bundle)
	if not bundle.is_valid():
		return LoadResult.new(Result.failure(CODE_INVALID, bundle.describe_issues()), null)
	return LoadResult.new(Result.success(), _build(bundle))


## Confere o que o esquema não vê. Registro com problema de tipo é pulado aqui (o erro já foi relatado).
static func check_semantics(bundle: DataBundle) -> void:
	if not bundle.tables.has(TERRAIN_TABLE) or not bundle.tables.has(SURFACE_TABLE):
		return # arquivo ausente ou ilegível: o erro já foi relatado
	var file_path: String = bundle.file_paths[TERRAIN_TABLE]
	var terrains: Array = bundle.tables[TERRAIN_TABLE]
	if terrains.size() != 1:
		bundle.add_issue(file_path, "", "", "esperado exatamente 1 terreno no arquivo, encontrado %d" % terrains.size())
	var codes: Dictionary[int, String] = _collect_codes(bundle)
	for record: Dictionary in terrains:
		if _is_converted(record):
			_check_terrain(bundle, file_path, record, codes)


static func _is_converted(record: Dictionary) -> bool:
	for field_name: String in INT_FIELDS:
		if typeof(record.get(field_name)) != TYPE_INT:
			return false
	for field_name: String in LIST_FIELDS:
		if typeof(record.get(field_name)) != TYPE_PACKED_INT64_ARRAY:
			return false
	return true


## Mapa código -> id da tabela de superfícies; registra os códigos repetidos.
static func _collect_codes(bundle: DataBundle) -> Dictionary[int, String]:
	var codes: Dictionary[int, String] = {}
	var file_path: String = bundle.file_paths[SURFACE_TABLE]
	for record: Dictionary in bundle.tables[SURFACE_TABLE]:
		if typeof(record.get("code")) != TYPE_INT:
			continue
		var code: int = record["code"]
		var item: String = str(record.get("id", ""))
		if codes.has(code):
			bundle.add_issue(file_path, item, "code", "código %d repetido: já é o de '%s'" % [code, codes[code]])
		else:
			codes[code] = item
	return codes


static func _check_terrain(bundle: DataBundle, file_path: String, record: Dictionary, codes: Dictionary[int, String]) -> void:
	var item: String = str(record.get("id", ""))
	var cells_x: int = record["cells_x"]
	var cells_z: int = record["cells_z"]
	var cell_size_cm: int = record["cell_size_cm"]
	var spawn_x_cm: int = record["spawn_x_cm"]
	var spawn_z_cm: int = record["spawn_z_cm"]
	var heights: PackedInt64Array = record["heights_cm"]
	var surfaces: PackedInt64Array = record["surfaces"]
	if heights.size() != (cells_x + 1) * (cells_z + 1):
		bundle.add_issue(file_path, item, "heights_cm", "tamanho da lista: esperado %d (= (células_x + 1) × (células_z + 1) = %d × %d), encontrado %d" % [(cells_x + 1) * (cells_z + 1), cells_x + 1, cells_z + 1, heights.size()])
	if surfaces.size() != cells_x * cells_z:
		bundle.add_issue(file_path, item, "surfaces", "tamanho da lista: esperado %d (= células_x × células_z = %d × %d), encontrado %d" % [cells_x * cells_z, cells_x, cells_z, surfaces.size()])
	_check_surface_codes(bundle, file_path, item, surfaces, codes)
	if spawn_x_cm > cells_x * cell_size_cm:
		bundle.add_issue(file_path, item, "spawn_x_cm", "ponto de nascimento fora do mapa: x=%d cm, esperado de 0 a %d cm" % [spawn_x_cm, cells_x * cell_size_cm])
	if spawn_z_cm > cells_z * cell_size_cm:
		bundle.add_issue(file_path, item, "spawn_z_cm", "ponto de nascimento fora do mapa: z=%d cm, esperado de 0 a %d cm" % [spawn_z_cm, cells_z * cell_size_cm])


static func _check_surface_codes(bundle: DataBundle, file_path: String, item: String, surfaces: PackedInt64Array, codes: Dictionary[int, String]) -> void:
	var unknown_count: int = 0
	for position: int in surfaces.size():
		if codes.has(surfaces[position]):
			continue
		unknown_count += 1
		if unknown_count <= DataValidator.MAX_ELEMENT_ISSUES:
			bundle.add_issue(file_path, item, "surfaces", "elemento na posição %d: código de superfície %d não existe em %s" % [position, surfaces[position], bundle.file_paths[SURFACE_TABLE].get_file()])
	if unknown_count > DataValidator.MAX_ELEMENT_ISSUES:
		bundle.add_issue(file_path, item, "surfaces", "mais %d códigos inexistentes não detalhados (total %d)" % [unknown_count - DataValidator.MAX_ELEMENT_ISSUES, unknown_count])


## Monta o TerrainData de um pacote já validado (um terreno, tudo coerente).
static func _build(bundle: DataBundle) -> TerrainData:
	var record: Dictionary = bundle.tables[TERRAIN_TABLE][0]
	# O pacote é válido, então esta chamada não registra problema nenhum.
	var codes: Dictionary[int, String] = _collect_codes(bundle)
	return TerrainData.new(Vector2i(record["cells_x"], record["cells_z"]), record["cell_size_cm"], record["heights_cm"], record["surfaces"], codes, Vector2i(record["spawn_x_cm"], record["spawn_z_cm"]))


## Resultado do carregamento: `result.ok` diz se deu certo; só então `terrain` vale
## (mesmo padrão de DecodedSave, em persistence).
class LoadResult:
	extends RefCounted

	var result: Result
	var terrain: TerrainData

	func _init(load_result: Result, loaded_terrain: TerrainData) -> void:
		result = load_result
		terrain = loaded_terrain
