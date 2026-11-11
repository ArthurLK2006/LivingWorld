class_name MarketLoader
extends RefCounted
## Lê e valida data/economy/market_targets.json e data/economy/price_params.json pelo módulo `data` (LW-090; docs/economy/dados.md), LENDO JUNTO os bens (para a referência `good_id`). `market_targets`: `id`,
## `settlement_id`, `good_id` (referência a `goods`), `target_stock` e `initial_stock` (0 ou mais), `buy_cap_bp` (10000 ou mais). `price_params`: uma linha só, as nove constantes (docs/economy/dados.md). O que o
## esquema não vê é conferido aqui: par (assentamento, bem) único, todo assentamento com ao menos um bem negociado, estoque inicial dentro do teto de compra, piso de fator não maior que o teto e faixas
## (`spread_bp` de 1 a 20000, `shortage_days` de 1 a 59). A existência do assentamento no `world` é do verificador da LW-093a (D1). Falha com `ECON_DATA_INVALID`, arquivo, item e campo.

const TARGETS_TABLE: String = "market_targets"
const PARAMS_TABLE: String = "price_params"
const TARGETS_FILE: String = "market_targets.json"
const PARAMS_FILE: String = "price_params.json"
const MAX_VALUE: int = 1000000000
const MAX_BP: int = 100000
const MAX_SPREAD_BP: int = 20000
const MAX_SHORTAGE_DAYS: int = 59


## Os esquemas dos bens e dos tipos de dono (só para a referência) mais os das duas tabelas do mercado.
static func build_schemas() -> Array[DataSchema]:
	var schemas: Array[DataSchema] = GoodsLoader.build_schemas()
	var targets: DataSchema = DataSchema.new(TARGETS_TABLE, TARGETS_FILE)
	targets.add_field("settlement_id", DataSchema.FieldType.STRING)
	targets.add_field("good_id", DataSchema.FieldType.STRING).set_ref(GoodsLoader.GOODS_TABLE)
	targets.add_field("target_stock", DataSchema.FieldType.INT).set_range(0, MAX_VALUE)
	targets.add_field("initial_stock", DataSchema.FieldType.INT).set_range(0, MAX_VALUE)
	targets.add_field("buy_cap_bp", DataSchema.FieldType.INT).set_range(10000, MAX_VALUE)
	var params: DataSchema = DataSchema.new(PARAMS_TABLE, PARAMS_FILE)
	params.add_field("min_factor_bp", DataSchema.FieldType.INT).set_range(1, MAX_BP)
	params.add_field("max_factor_bp", DataSchema.FieldType.INT).set_range(1, MAX_BP)
	params.add_field("smoothing_bp", DataSchema.FieldType.INT).set_range(0, MAX_BP)
	params.add_field("spread_bp", DataSchema.FieldType.INT).set_range(1, MAX_SPREAD_BP)
	params.add_field("significant_change_bp", DataSchema.FieldType.INT).set_range(0, MAX_BP)
	params.add_field("max_order_quantity", DataSchema.FieldType.INT).set_range(1, MAX_VALUE)
	params.add_field("history_days", DataSchema.FieldType.INT).set_range(1, MAX_VALUE)
	params.add_field("shortage_threshold_bp", DataSchema.FieldType.INT).set_range(0, MAX_BP)
	params.add_field("shortage_days", DataSchema.FieldType.INT).set_range(1, MAX_SHORTAGE_DAYS)
	schemas.append(targets)
	schemas.append(params)
	return schemas


static func load_dir(base_dir: String = GoodsLoader.DEFAULT_DIR) -> LoadResult:
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
	_check_targets(bundle)
	_check_params(bundle)
	if not bundle.is_valid():
		return LoadResult.new(Result.failure(EconomyCodes.DATA_INVALID, bundle.describe_issues()), [], null)
	var targets: Array[MarketTargetDef] = []
	for record: Dictionary in bundle.tables[TARGETS_TABLE]:
		targets.append(MarketTargetDef.new(str(record["id"]), str(record["settlement_id"]), str(record["good_id"]), record["target_stock"], record["initial_stock"], record["buy_cap_bp"]))
	var params: Dictionary = bundle.tables[PARAMS_TABLE][0]
	return LoadResult.new(Result.success(), targets, PriceParams.new(params))


## Par único, estoque inicial dentro do teto e todo assentamento com ao menos um bem negociado.
static func _check_targets(bundle: DataBundle) -> void:
	if not bundle.tables.has(TARGETS_TABLE):
		return
	var file_path: String = bundle.file_paths[TARGETS_TABLE]
	var seen: Dictionary[String, String] = {}
	var traded: Dictionary[String, bool] = {}
	for record: Dictionary in bundle.tables[TARGETS_TABLE]:
		var item: String = str(record.get("id", ""))
		if typeof(record.get("settlement_id")) != TYPE_STRING or typeof(record.get("good_id")) != TYPE_STRING:
			continue
		var settlement_id: String = record["settlement_id"]
		traded[settlement_id] = bool(traded.get(settlement_id, false)) or (typeof(record.get("target_stock")) == TYPE_INT and int(record["target_stock"]) > 0)
		var pair: String = "%s/%s" % [settlement_id, record["good_id"]]
		if seen.has(pair):
			bundle.add_issue(file_path, item, "good_id", "o bem '%s' já tem linha no assentamento '%s' (linha '%s'); esperada uma linha por par" % [record["good_id"], settlement_id, seen[pair]])
		else:
			seen[pair] = item
		if typeof(record.get("target_stock")) == TYPE_INT and typeof(record.get("initial_stock")) == TYPE_INT and typeof(record.get("buy_cap_bp")) == TYPE_INT:
			var cap: int = IntMath.floor_div(int(record["target_stock"]) * int(record["buy_cap_bp"]), 10000)
			if int(record["initial_stock"]) > cap:
				bundle.add_issue(file_path, item, "initial_stock", "estoque inicial %d acima do teto de compra %d (alvo %d × buy_cap_bp %d ÷ 10000)" % [int(record["initial_stock"]), cap, int(record["target_stock"]), int(record["buy_cap_bp"])])
	for settlement_id: String in traded:
		if not traded[settlement_id]:
			bundle.add_issue(file_path, "", "target_stock", "o assentamento '%s' não negocia nenhum bem; esperado ao menos um com alvo maior que 0" % settlement_id)


## Uma linha só e o piso de fator não maior que o teto.
static func _check_params(bundle: DataBundle) -> void:
	if not bundle.tables.has(PARAMS_TABLE):
		return
	var file_path: String = bundle.file_paths[PARAMS_TABLE]
	var records: Array = bundle.tables[PARAMS_TABLE]
	if records.size() != 1:
		bundle.add_issue(file_path, "", "", "esperada exatamente 1 linha de constantes de preço, encontradas %d" % records.size())
		return
	var record: Dictionary = records[0]
	if typeof(record.get("min_factor_bp")) == TYPE_INT and typeof(record.get("max_factor_bp")) == TYPE_INT and int(record["min_factor_bp"]) > int(record["max_factor_bp"]):
		bundle.add_issue(file_path, str(record.get("id", "")), "min_factor_bp", "o piso %d é maior que o teto %d (max_factor_bp)" % [int(record["min_factor_bp"]), int(record["max_factor_bp"])])


## Resultado do carregamento: `targets` e `params` só valem se `result.ok`.
class LoadResult:
	extends RefCounted

	var result: Result
	var targets: Array[MarketTargetDef]
	var params: PriceParams

	func _init(load_result: Result, loaded_targets: Array[MarketTargetDef], loaded_params: PriceParams) -> void:
		result = load_result
		targets = loaded_targets
		params = loaded_params
