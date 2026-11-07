class_name PointOfInterestLoader
extends RefCounted
## Lê e valida data/world/pois.json pelo módulo `data` (LW-049; formato em docs/modules/world.md). Cada objeto tem `id` (texto em
## snake_case, único), `kind` (texto em snake_case), `x_cm` e `z_cm` (inteiros, centímetros, dentro do mapa) e `text_key` (texto não
## vazio). Qualquer problema vira falha com arquivo, item e campo. Nunca carrega recurso nem executa nada do arquivo.

const POIS_TABLE: String = "pois"
const DEFAULT_POIS_FILE: String = "pois.json"
const CODE_INVALID: String = "POI_DATA_INVALID"
## Faixa de segurança [HIP] das coordenadas (100 km); o limite verdadeiro é o tamanho do mapa, conferido adiante.
const MAX_COORDINATE_CM: int = 10000000
const CM_PER_METER: float = TerrainData.CM_PER_METER


## Esquema da tabela; o nome do arquivo pode ser trocado (testes).
static func build_schema(file_name: String = DEFAULT_POIS_FILE) -> DataSchema:
	var schema: DataSchema = DataSchema.new(POIS_TABLE, file_name)
	schema.add_field("kind", DataSchema.FieldType.STRING)
	schema.add_field("x_cm", DataSchema.FieldType.INT).set_range(0, MAX_COORDINATE_CM)
	schema.add_field("z_cm", DataSchema.FieldType.INT).set_range(0, MAX_COORDINATE_CM)
	schema.add_field("text_key", DataSchema.FieldType.STRING)
	return schema


## Lê, valida e monta os pontos, na ordem do arquivo. O terreno dá o limite do mapa e a altura de cada ponto.
static func load_dir(base_dir: String, terrain: TerrainData, file_name: String = DEFAULT_POIS_FILE) -> LoadResult:
	if terrain == null:
		return LoadResult.new(Result.failure(CODE_INVALID, "PointOfInterestLoader.load_dir: terreno nulo; esperado um TerrainData para conferir o mapa."), [])
	var schemas: Array[DataSchema] = [build_schema(file_name)]
	var bundle: DataBundle = DataLoader.load_all(base_dir, schemas)
	_check_semantics(bundle, terrain)
	if not bundle.is_valid():
		return LoadResult.new(Result.failure(CODE_INVALID, bundle.describe_issues()), [])
	return LoadResult.new(Result.success(), _build(bundle, terrain))


## O que o esquema não vê: `kind` em snake_case, chave de texto não vazia e ponto dentro do mapa. Registro com problema de tipo é
## pulado (o erro já foi relatado).
static func _check_semantics(bundle: DataBundle, terrain: TerrainData) -> void:
	if not bundle.tables.has(POIS_TABLE):
		return
	var file_path: String = bundle.file_paths[POIS_TABLE]
	var kind_pattern: RegEx = RegEx.create_from_string(DataValidator.ID_PATTERN)
	var size_m: Vector2 = terrain.peek_size_m()
	for record: Dictionary in bundle.tables[POIS_TABLE]:
		var item: String = str(record.get("id", ""))
		if typeof(record.get("kind")) == TYPE_STRING and kind_pattern.search(str(record["kind"])) == null:
			bundle.add_issue(file_path, item, "kind", "tipo inválido '%s': use snake_case iniciado por letra minúscula" % str(record["kind"]))
		if typeof(record.get("text_key")) == TYPE_STRING and str(record["text_key"]).strip_edges().is_empty():
			bundle.add_issue(file_path, item, "text_key", "chave de texto vazia; esperado o nome de uma chave de data/text")
		if typeof(record.get("x_cm")) == TYPE_INT and typeof(record.get("z_cm")) == TYPE_INT:
			var point_x: float = float(record["x_cm"]) / CM_PER_METER
			var point_z: float = float(record["z_cm"]) / CM_PER_METER
			if not terrain.peek_height(point_x, point_z).result.ok:
				bundle.add_issue(file_path, item, "x_cm", "ponto fora do mapa: x=%d cm e z=%d cm, esperado de 0 a %d cm em x e de 0 a %d cm em z" % [record["x_cm"], record["z_cm"], roundi(size_m.x * CM_PER_METER), roundi(size_m.y * CM_PER_METER)])


## Monta os pontos de um pacote já validado. A altura é a do terreno no ponto.
static func _build(bundle: DataBundle, terrain: TerrainData) -> Array[PointOfInterest]:
	var points: Array[PointOfInterest] = []
	for record: Dictionary in bundle.tables[POIS_TABLE]:
		var point_x: float = float(record["x_cm"]) / CM_PER_METER
		var point_z: float = float(record["z_cm"]) / CM_PER_METER
		var ground: TerrainData.HeightQuery = terrain.peek_height(point_x, point_z)
		points.append(PointOfInterest.new(str(record["id"]), str(record["kind"]), Vector3(point_x, ground.height_m, point_z), str(record["text_key"])))
	return points


## Resultado do carregamento: `points` só vale se `result.ok` (mesmo padrão de TerrainLoader.LoadResult).
class LoadResult:
	extends RefCounted

	var result: Result
	var points: Array[PointOfInterest]

	func _init(load_result: Result, loaded_points: Array[PointOfInterest]) -> void:
		result = load_result
		points = loaded_points
