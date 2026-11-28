class_name FlowParamsLoader
extends RefCounted
## Lê e valida data/economy/flow_params.json pelo módulo `data` (LW-100b; docs/modules/economy.md, 9.16.2; docs/economy/dados.md): uma linha só, `id` = `flow_defaults`, duas colunas `INT` com a faixa do contrato. O que o esquema não vê é conferido aqui: uma linha só e o `id` certo. Falha com `ECON_DATA_INVALID`, arquivo, item e campo.
## Nunca executa nada do arquivo. Não lê outras tabelas e fica INERTE até a LW-100e (a fiação no `app`); molde do `CaravanParamsLoader`.

const PARAMS_TABLE: String = "flow_params"
const PARAMS_FILE: String = "flow_params.json"
const MAX_DAILY_CAP_UNITS: int = 1000
const MAX_RISK_BP_PER_POINT: int = 100


static func build_schemas() -> Array[DataSchema]:
	var params: DataSchema = DataSchema.new(PARAMS_TABLE, PARAMS_FILE)
	params.add_field("daily_cap_units", DataSchema.FieldType.INT).set_range(1, MAX_DAILY_CAP_UNITS)
	params.add_field("risk_bp_per_point", DataSchema.FieldType.INT).set_range(0, MAX_RISK_BP_PER_POINT)
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
	return LoadResult.new(Result.success(), FlowParams.new(bundle.tables[PARAMS_TABLE][0]))


## Uma linha só, com o `id` do contrato.
static func _check_row(bundle: DataBundle) -> void:
	if not bundle.tables.has(PARAMS_TABLE):
		return
	var file_path: String = bundle.file_paths[PARAMS_TABLE]
	var records: Array = bundle.tables[PARAMS_TABLE]
	if records.size() != 1:
		bundle.add_issue(file_path, "", "", "esperada exatamente 1 linha de parâmetros do fluxo (id '%s'), encontradas %d" % [FlowParams.ROW_ID, records.size()])
		return
	var record: Dictionary = records[0]
	if str(record.get("id", "")) != FlowParams.ROW_ID:
		bundle.add_issue(file_path, str(record.get("id", "")), "id", "o id da única linha deve ser '%s'" % FlowParams.ROW_ID)


## Resultado do carregamento: `params` só vale se `result.ok`.
class LoadResult:
	extends RefCounted

	var result: Result
	var params: FlowParams

	func _init(load_result: Result, loaded_params: FlowParams) -> void:
		result = load_result
		params = loaded_params
