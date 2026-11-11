class_name GoodsLoader
extends RefCounted
## Lê e valida data/economy/goods.json e data/economy/owner_kinds.json pelo módulo `data` (LW-089; docs/economy/dados.md). Bem: `id`, `name_key`, `category` (vocabulário fechado de `GoodDef.CATEGORIES`),
## `base_value` e `weight` (inteiros de 1 ou mais), `perishability_days` (0 ou mais) e, só no bem de consumo do NPC, `need_id` e `need_relief` JUNTOS (1 ou mais). Tipo de dono: `id`, `weight_capacity` e
## `initial_balance` (0 ou mais). Qualquer problema vira `ECON_DATA_INVALID` com arquivo, item e campo. Nunca carrega recurso nem executa nada do arquivo. Mesmo padrão dos outros carregadores. Não exige
## que os ids sejam exatamente os do contrato: um bem novo só por dado também funciona (a quantidade de bens e a receita que o produz são conferidas pelas tarefas seguintes).

const GOODS_TABLE: String = "goods"
const OWNER_KINDS_TABLE: String = "owner_kinds"
const DEFAULT_DIR: String = "res://data/economy"
const GOODS_FILE: String = "goods.json"
const OWNER_KINDS_FILE: String = "owner_kinds.json"
## Faixa de segurança [HIP] de valor, peso, capacidade e saldo inicial (não é limite de design): longe do teto exato do save.
const MAX_VALUE: int = 1000000000


static func build_schemas() -> Array[DataSchema]:
	var goods: DataSchema = DataSchema.new(GOODS_TABLE, GOODS_FILE)
	goods.add_field("name_key", DataSchema.FieldType.STRING)
	goods.add_field("category", DataSchema.FieldType.STRING)
	goods.add_field("base_value", DataSchema.FieldType.INT).set_range(1, MAX_VALUE)
	goods.add_field("weight", DataSchema.FieldType.INT).set_range(1, MAX_VALUE)
	goods.add_field("perishability_days", DataSchema.FieldType.INT).set_range(0, MAX_VALUE)
	goods.add_field("need_id", DataSchema.FieldType.STRING, false)
	goods.add_field("need_relief", DataSchema.FieldType.INT, false).set_range(1, MAX_VALUE)
	var kinds: DataSchema = DataSchema.new(OWNER_KINDS_TABLE, OWNER_KINDS_FILE)
	kinds.add_field("weight_capacity", DataSchema.FieldType.INT).set_range(0, MAX_VALUE)
	kinds.add_field("initial_balance", DataSchema.FieldType.INT).set_range(0, MAX_VALUE)
	var schemas: Array[DataSchema] = [goods, kinds]
	return schemas


## Lê os dois arquivos de `base_dir`, valida e monta as definições, na ordem dos arquivos.
static func load_dir(base_dir: String = DEFAULT_DIR) -> LoadResult:
	return _finish(DataLoader.load_all(base_dir, build_schemas()))


## Mesmo caminho a partir de tabelas já em memória (id da tabela -> registros), sem tocar em disco: para testar dado inválido. `base_dir` só rotula os arquivos nas mensagens.
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
	_check_goods(bundle)
	if not bundle.is_valid():
		return LoadResult.new(Result.failure(EconomyCodes.DATA_INVALID, bundle.describe_issues()), [], [])
	return _build(bundle)


## O que o esquema não vê: categoria do vocabulário, nome de chave não vazio e `need_id` e `need_relief` sempre juntos.
static func _check_goods(bundle: DataBundle) -> void:
	if not bundle.tables.has(GOODS_TABLE):
		return
	var file_path: String = bundle.file_paths[GOODS_TABLE]
	for record: Dictionary in bundle.tables[GOODS_TABLE]:
		var item: String = str(record.get("id", ""))
		var category: Variant = record.get("category")
		if typeof(category) == TYPE_STRING and not GoodDef.CATEGORIES.has(str(category)):
			bundle.add_issue(file_path, item, "category", "categoria '%s' fora do vocabulário; esperado uma de: %s" % [str(category), ", ".join(GoodDef.CATEGORIES)])
		if typeof(record.get("name_key")) == TYPE_STRING and str(record["name_key"]).strip_edges().is_empty():
			bundle.add_issue(file_path, item, "name_key", "chave de texto vazia; esperado o nome de uma chave de data/text")
		var has_need: bool = record.has("need_id")
		if has_need != record.has("need_relief"):
			bundle.add_issue(file_path, item, "need_relief" if has_need else "need_id", "'need_id' e 'need_relief' vêm juntos ou nenhum")
		elif has_need and typeof(record["need_id"]) == TYPE_STRING and str(record["need_id"]).is_empty():
			bundle.add_issue(file_path, item, "need_id", "necessidade vazia; esperado o id de uma necessidade ou omitir o campo")


static func _build(bundle: DataBundle) -> LoadResult:
	var goods: Array[GoodDef] = []
	for record: Dictionary in bundle.tables.get(GOODS_TABLE, []):
		goods.append(GoodDef.new(str(record["id"]), str(record["name_key"]), str(record["category"]), record["base_value"], record["weight"], record["perishability_days"], str(record.get("need_id", "")), int(record.get("need_relief", 0))))
	var kinds: Array[OwnerKindDef] = []
	for record: Dictionary in bundle.tables.get(OWNER_KINDS_TABLE, []):
		kinds.append(OwnerKindDef.new(str(record["id"]), record["weight_capacity"], record["initial_balance"]))
	return LoadResult.new(Result.success(), goods, kinds)


## Resultado do carregamento: `goods` e `kinds` só valem se `result.ok` (mesmo padrão dos outros carregadores).
class LoadResult:
	extends RefCounted

	var result: Result
	var goods: Array[GoodDef]
	var kinds: Array[OwnerKindDef]

	func _init(load_result: Result, loaded_goods: Array[GoodDef], loaded_kinds: Array[OwnerKindDef]) -> void:
		result = load_result
		goods = loaded_goods
		kinds = loaded_kinds
