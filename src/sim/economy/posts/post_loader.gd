class_name PostLoader
extends RefCounted
## Lê e valida data/economy/service_posts.json pelo módulo `data` (LW-095; docs/economy/dados.md): `settlement_id`, `place_id` e `occupation_id` (texto não vazio), `workers_wanted` (1 ou mais) e `wage_per_hour` (0 ou mais). O arquivo é OPCIONAL por enquanto:
## sem ele não há posto (lista vazia); a tabela, se existe, pode estar vazia. O que o esquema não vê é conferido aqui: texto em branco e um posto por `place_id`. Falha com `ECON_DATA_INVALID`, arquivo, item e campo. Nunca carrega recurso nem executa nada do arquivo.
## O arquivo `service_posts.json` (6 linhas) é da LW-095 e só entra depois da LW-097 no `main`, com o aviso de Arthur por escrito; esta classe só lê.

const POSTS_TABLE: String = "service_posts"
const POSTS_FILE: String = "service_posts.json"
const MAX_VALUE: int = 1000000000
const TEXT_FIELDS: Array[String] = ["settlement_id", "place_id", "occupation_id"]


static func build_schemas() -> Array[DataSchema]:
	var posts: DataSchema = DataSchema.new(POSTS_TABLE, POSTS_FILE)
	for field: String in TEXT_FIELDS:
		posts.add_field(field, DataSchema.FieldType.STRING)
	posts.add_field("workers_wanted", DataSchema.FieldType.INT).set_range(1, MAX_VALUE)
	posts.add_field("wage_per_hour", DataSchema.FieldType.INT).set_range(0, MAX_VALUE)
	return [posts]


## Sem o arquivo na pasta não há posto (lista vazia, sucesso): o arquivo é opcional até a distribuição de dados dos povoados.
static func load_dir(base_dir: String = GoodsLoader.DEFAULT_DIR) -> LoadResult:
	if not FileAccess.file_exists(base_dir.path_join(POSTS_FILE)):
		return LoadResult.new(Result.success(), [] as Array[PostDef])
	return _finish(DataLoader.load_all(base_dir, build_schemas()))


## Mesmo caminho a partir de tabelas já em memória (id da tabela -> registros), sem tocar em disco: para testar dado inválido.
static func from_tables(tables: Dictionary[String, Array], base_dir: String) -> LoadResult:
	var schemas: Array[DataSchema] = build_schemas()
	var bundle: DataBundle = DataBundle.new()
	for schema: DataSchema in schemas:
		if tables.has(schema.table_id):
			bundle.tables[schema.table_id] = tables[schema.table_id]
			bundle.file_paths[schema.table_id] = base_dir.path_join(schema.file_name)
	DataValidator.new().validate(bundle, schemas)
	return _finish(bundle)


static func _finish(bundle: DataBundle) -> LoadResult:
	_check_texts_and_places(bundle)
	if not bundle.is_valid():
		return LoadResult.new(Result.failure(EconomyCodes.DATA_INVALID, bundle.describe_issues()), [] as Array[PostDef])
	var posts: Array[PostDef] = []
	for record: Dictionary in bundle.tables[POSTS_TABLE]:
		posts.append(PostDef.new(str(record["id"]), str(record["settlement_id"]), str(record["place_id"]), str(record["occupation_id"]), record["workers_wanted"], record["wage_per_hour"]))
	return LoadResult.new(Result.success(), posts)


## Texto em branco é recusado e um posto por local: o mesmo `place_id` em duas linhas é recusado, apontando a primeira.
static func _check_texts_and_places(bundle: DataBundle) -> void:
	if not bundle.tables.has(POSTS_TABLE):
		return
	var file_path: String = bundle.file_paths[POSTS_TABLE]
	var places: Dictionary[String, String] = {}
	for record: Dictionary in bundle.tables[POSTS_TABLE]:
		var item: String = str(record.get("id", ""))
		for field: String in TEXT_FIELDS:
			if typeof(record.get(field)) == TYPE_STRING and str(record[field]).strip_edges().is_empty():
				bundle.add_issue(file_path, item, field, "o texto está em branco; esperado o id de %s" % field.trim_suffix("_id"))
		if typeof(record.get("place_id")) != TYPE_STRING or str(record["place_id"]).strip_edges().is_empty():
			continue
		var place_id: String = record["place_id"]
		if places.has(place_id):
			bundle.add_issue(file_path, item, "place_id", "o local '%s' já tem um posto (linha '%s'); esperado um por local" % [place_id, places[place_id]])
		else:
			places[place_id] = item


## Resultado do carregamento: `posts` (na ordem do arquivo) só vale se `result.ok`.
class LoadResult:
	extends RefCounted

	var result: Result
	var posts: Array[PostDef]

	func _init(load_result: Result, loaded_posts: Array[PostDef]) -> void:
		result = load_result
		posts = loaded_posts
