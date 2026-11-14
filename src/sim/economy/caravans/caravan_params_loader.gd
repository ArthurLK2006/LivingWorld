class_name CaravanParamsLoader
extends RefCounted
## Lê e valida data/economy/caravan_params.json pelo módulo `data` (LW-098b; docs/economy/dados.md): uma linha só, `id` = `caravan_defaults`, oito colunas `INT` com a faixa do `dados.md`. O que o esquema não vê é conferido aqui: uma linha só e o `id` certo. Falha com `ECON_DATA_INVALID`,
## arquivo, item e campo. Nunca executa nada do arquivo. Não lê outras tabelas (sem referência a bens): o `EconomySetup` o liga à economia no jogo montado desde a LW-098d3.

const PARAMS_TABLE: String = "caravan_params"
const PARAMS_FILE: String = "caravan_params.json"
## Teto de 1 bilhão nas colunas que o `dados.md` dá como "0 ou mais" (evita estouro de inteiro nas contas; não está no contrato, a LW-098b o acrescentou).
const MAX_VALUE: int = 1000000000
const MAX_BP: int = 10000
const MAX_MARGIN_BP: int = 100000
const MAX_SPEED_CM_PER_MIN: int = 100000


static func build_schemas() -> Array[DataSchema]:
	var params: DataSchema = DataSchema.new(PARAMS_TABLE, PARAMS_FILE)
	params.add_field("speed_cm_per_min", DataSchema.FieldType.INT).set_range(1, MAX_SPEED_CM_PER_MIN)
	params.add_field("difficulty_slowdown_bp", DataSchema.FieldType.INT).set_range(0, MAX_BP)
	params.add_field("risk_bp_per_point", DataSchema.FieldType.INT).set_range(0, MAX_BP)
	params.add_field("time_cost_per_hour", DataSchema.FieldType.INT).set_range(0, MAX_VALUE)
	params.add_field("fixed_cost", DataSchema.FieldType.INT).set_range(0, MAX_VALUE)
	params.add_field("min_net_profit", DataSchema.FieldType.INT).set_range(0, MAX_VALUE)
	params.add_field("min_margin_bp", DataSchema.FieldType.INT).set_range(0, MAX_MARGIN_BP)
	params.add_field("origin_reserve_bp", DataSchema.FieldType.INT).set_range(0, MAX_BP)
	var schemas: Array[DataSchema] = []
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
	_check_row(bundle)
	if not bundle.is_valid():
		return LoadResult.new(Result.failure(EconomyCodes.DATA_INVALID, bundle.describe_issues()), null)
	return LoadResult.new(Result.success(), CaravanParams.new(bundle.tables[PARAMS_TABLE][0]))


## Uma linha só, com o `id` do contrato.
static func _check_row(bundle: DataBundle) -> void:
	if not bundle.tables.has(PARAMS_TABLE):
		return
	var file_path: String = bundle.file_paths[PARAMS_TABLE]
	var records: Array = bundle.tables[PARAMS_TABLE]
	if records.size() != 1:
		bundle.add_issue(file_path, "", "", "esperada exatamente 1 linha de parâmetros da caravana (id '%s'), encontradas %d" % [CaravanParams.ROW_ID, records.size()])
		return
	var record: Dictionary = records[0]
	if str(record.get("id", "")) != CaravanParams.ROW_ID:
		bundle.add_issue(file_path, str(record.get("id", "")), "id", "o id da única linha deve ser '%s'" % CaravanParams.ROW_ID)


## Resultado do carregamento: `params` só vale se `result.ok`.
class LoadResult:
	extends RefCounted

	var result: Result
	var params: CaravanParams

	func _init(load_result: Result, loaded_params: CaravanParams) -> void:
		result = load_result
		params = loaded_params
