class_name SettlementLoader
extends RefCounted
## Lê e valida data/world/settlements.json e data/world/places.json pelo módulo `data` (LW-056; formato em docs/modules/world.md, seção
## "Extensão da Fase 2: assentamentos e locais"). Assentamento: `id`, `name_key` (texto não vazio), `x_cm` e `z_cm` (inteiros, centímetros,
## dentro do mapa). Local: `id` (único em todo o jogo), `settlement_id` (referência a um assentamento), `kind` (vocabulário fechado de
## Place.KINDS), `x_cm` e `z_cm` (inteiros, dentro do mapa, a no máximo SETTLEMENT_MAX_RADIUS_M do centro do assentamento) e `capacity`
## (inteiro de Place.MIN_CAPACITY a Place.MAX_CAPACITY). Qualquer problema vira falha com arquivo, item e campo. Nunca carrega recurso
## nem executa nada do arquivo. Mesmo padrão do PointOfInterestLoader.

const SETTLEMENTS_TABLE: String = "settlements"
const PLACES_TABLE: String = "places"
const DEFAULT_SETTLEMENTS_FILE: String = "settlements.json"
const DEFAULT_PLACES_FILE: String = "places.json"
const CODE_INVALID: String = "SETTLEMENT_DATA_INVALID"
## Faixa de segurança [HIP] das coordenadas (100 km); o limite verdadeiro é o tamanho do mapa, conferido adiante.
const MAX_COORDINATE_CM: int = 10000000
## Distância máxima [HIP] de um local ao centro do seu assentamento (metros): inclusive no limite; um povoado cabe num raio assim.
const SETTLEMENT_MAX_RADIUS_M: float = 150.0
const CM_PER_METER: float = TerrainData.CM_PER_METER


## Esquemas das duas tabelas; os nomes dos arquivos podem ser trocados (testes). `settlement_id` é referência à tabela de assentamentos.
static func build_schemas(settlements_file: String = DEFAULT_SETTLEMENTS_FILE, places_file: String = DEFAULT_PLACES_FILE) -> Array[DataSchema]:
	var settlements: DataSchema = DataSchema.new(SETTLEMENTS_TABLE, settlements_file)
	settlements.add_field("name_key", DataSchema.FieldType.STRING)
	settlements.add_field("x_cm", DataSchema.FieldType.INT).set_range(0, MAX_COORDINATE_CM)
	settlements.add_field("z_cm", DataSchema.FieldType.INT).set_range(0, MAX_COORDINATE_CM)
	## LW-118c: `province_id` e `culture_id` são OPCIONAIS aqui (arquivos antigos e de teste não as trazem); o `SettlementProvinceCheck` exige as duas e confere as referências.
	settlements.add_field("province_id", DataSchema.FieldType.STRING, false)
	settlements.add_field("culture_id", DataSchema.FieldType.STRING, false)
	var places: DataSchema = DataSchema.new(PLACES_TABLE, places_file)
	places.add_field("settlement_id", DataSchema.FieldType.STRING).set_ref(SETTLEMENTS_TABLE)
	places.add_field("kind", DataSchema.FieldType.STRING)
	places.add_field("x_cm", DataSchema.FieldType.INT).set_range(0, MAX_COORDINATE_CM)
	places.add_field("z_cm", DataSchema.FieldType.INT).set_range(0, MAX_COORDINATE_CM)
	places.add_field("capacity", DataSchema.FieldType.INT).set_range(Place.MIN_CAPACITY, Place.MAX_CAPACITY)
	var schemas: Array[DataSchema] = [settlements, places]
	return schemas


## Lê, valida e monta assentamentos e locais, na ordem dos arquivos. O terreno dá o limite do mapa e a altura de cada um.
static func load_dir(base_dir: String, terrain: TerrainData, settlements_file: String = DEFAULT_SETTLEMENTS_FILE, places_file: String = DEFAULT_PLACES_FILE) -> LoadResult:
	if terrain == null:
		return LoadResult.new(Result.failure(CODE_INVALID, "SettlementLoader.load_dir: terreno nulo; esperado um TerrainData para conferir o mapa."), [], [])
	var bundle: DataBundle = DataLoader.load_all(base_dir, build_schemas(settlements_file, places_file))
	_check_semantics(bundle, terrain)
	if not bundle.is_valid():
		return LoadResult.new(Result.failure(CODE_INVALID, bundle.describe_issues()), [], [])
	return _build(bundle, terrain)


## O que o esquema não vê: texto do nome não vazio, tipo no vocabulário, posição dentro do mapa e as relações entre as duas tabelas.
## Registro com problema de tipo é pulado (o erro já foi relatado); tabela ausente também (idem).
static func _check_semantics(bundle: DataBundle, terrain: TerrainData) -> void:
	if bundle.tables.has(SETTLEMENTS_TABLE):
		_check_settlements(bundle, terrain)
	if bundle.tables.has(PLACES_TABLE):
		_check_places(bundle, terrain)
	if bundle.tables.has(SETTLEMENTS_TABLE) and bundle.tables.has(PLACES_TABLE):
		_check_relations(bundle)


static func _check_settlements(bundle: DataBundle, terrain: TerrainData) -> void:
	var file_path: String = bundle.file_paths[SETTLEMENTS_TABLE]
	for record: Dictionary in bundle.tables[SETTLEMENTS_TABLE]:
		var item: String = str(record.get("id", ""))
		if typeof(record.get("name_key")) == TYPE_STRING and str(record["name_key"]).strip_edges().is_empty():
			bundle.add_issue(file_path, item, "name_key", "chave de texto vazia; esperado o nome de uma chave de data/text")
		_check_inside_map(bundle, file_path, item, record, terrain, "assentamento")


static func _check_places(bundle: DataBundle, terrain: TerrainData) -> void:
	var file_path: String = bundle.file_paths[PLACES_TABLE]
	for record: Dictionary in bundle.tables[PLACES_TABLE]:
		var item: String = str(record.get("id", ""))
		if typeof(record.get("kind")) == TYPE_STRING and not Place.KINDS.has(str(record["kind"])):
			bundle.add_issue(file_path, item, "kind", "tipo '%s' fora do vocabulário; esperado um de: %s" % [str(record["kind"]), ", ".join(Place.KINDS)])
		_check_inside_map(bundle, file_path, item, record, terrain, "local")


## Posição dentro do mapa (intervalo fechado, a mesma regra do terreno): fora dele, mesmo por 1 cm, é problema do campo `x_cm`.
static func _check_inside_map(bundle: DataBundle, file_path: String, item: String, record: Dictionary, terrain: TerrainData, what: String) -> void:
	if typeof(record.get("x_cm")) != TYPE_INT or typeof(record.get("z_cm")) != TYPE_INT:
		return
	var point_x: float = float(record["x_cm"]) / CM_PER_METER
	var point_z: float = float(record["z_cm"]) / CM_PER_METER
	if terrain.peek_height(point_x, point_z).result.ok:
		return
	var size_m: Vector2 = terrain.peek_size_m()
	bundle.add_issue(file_path, item, "x_cm", "%s fora do mapa: x=%d cm e z=%d cm, esperado de 0 a %d cm em x e de 0 a %d cm em z" % [what, record["x_cm"], record["z_cm"], roundi(size_m.x * CM_PER_METER), roundi(size_m.y * CM_PER_METER)])


## Relações entre as tabelas: local longe demais do centro do seu assentamento e assentamento sem nenhum local. A referência quebrada
## (`settlement_id` inexistente) já foi relatada pelo validador do `data`; aqui ela só é pulada.
static func _check_relations(bundle: DataBundle) -> void:
	var centers: Dictionary[String, Vector2] = {}
	for record: Dictionary in bundle.tables[SETTLEMENTS_TABLE]:
		if typeof(record.get("x_cm")) == TYPE_INT and typeof(record.get("z_cm")) == TYPE_INT:
			centers[str(record.get("id", ""))] = Vector2(float(record["x_cm"]) / CM_PER_METER, float(record["z_cm"]) / CM_PER_METER)
	var place_counts: Dictionary[String, int] = {}
	var places_path: String = bundle.file_paths[PLACES_TABLE]
	for record: Dictionary in bundle.tables[PLACES_TABLE]:
		var owner_id: String = str(record.get("settlement_id", ""))
		place_counts[owner_id] = place_counts.get(owner_id, 0) + 1
		if not centers.has(owner_id) or typeof(record.get("x_cm")) != TYPE_INT or typeof(record.get("z_cm")) != TYPE_INT:
			continue
		var place_xz: Vector2 = Vector2(float(record["x_cm"]) / CM_PER_METER, float(record["z_cm"]) / CM_PER_METER)
		var distance_m: float = place_xz.distance_to(centers[owner_id])
		if distance_m > SETTLEMENT_MAX_RADIUS_M:
			bundle.add_issue(places_path, str(record.get("id", "")), "x_cm", "local a %s m do centro do assentamento '%s', acima do limite de %s m; esperado perto do centro do povoado" % [str(snappedf(distance_m, 0.01)), owner_id, str(SETTLEMENT_MAX_RADIUS_M)])
	var settlements_path: String = bundle.file_paths[SETTLEMENTS_TABLE]
	for record: Dictionary in bundle.tables[SETTLEMENTS_TABLE]:
		var settlement_id: String = str(record.get("id", ""))
		if not place_counts.has(settlement_id):
			bundle.add_issue(settlements_path, settlement_id, "id", "assentamento sem nenhum local em %s; esperado ao menos 1 local com settlement_id '%s'" % [places_path.get_file(), settlement_id])


## Monta os objetos de um pacote já validado. A altura de cada um é a do terreno no ponto.
static func _build(bundle: DataBundle, terrain: TerrainData) -> LoadResult:
	var settlements: Array[Settlement] = []
	for record: Dictionary in bundle.tables[SETTLEMENTS_TABLE]:
		settlements.append(Settlement.new(str(record["id"]), str(record["name_key"]), _ground_position(record, terrain), str(record.get("province_id", "")), str(record.get("culture_id", ""))))
	var places: Array[Place] = []
	for record: Dictionary in bundle.tables[PLACES_TABLE]:
		places.append(Place.new(str(record["id"]), str(record["settlement_id"]), str(record["kind"]), _ground_position(record, terrain), int(record["capacity"])))
	return LoadResult.new(Result.success(), settlements, places)


static func _ground_position(record: Dictionary, terrain: TerrainData) -> Vector3:
	var point_x: float = float(record["x_cm"]) / CM_PER_METER
	var point_z: float = float(record["z_cm"]) / CM_PER_METER
	return Vector3(point_x, terrain.peek_height(point_x, point_z).height_m, point_z)


## Resultado do carregamento: `settlements` e `places` só valem se `result.ok` (mesmo padrão de TerrainLoader.LoadResult).
class LoadResult:
	extends RefCounted

	var result: Result
	var settlements: Array[Settlement]
	var places: Array[Place]

	func _init(load_result: Result, loaded_settlements: Array[Settlement], loaded_places: Array[Place]) -> void:
		result = load_result
		settlements = loaded_settlements
		places = loaded_places
