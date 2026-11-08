class_name LodParamsLoader
extends RefCounted
## Lê e valida data/lod_params.json pelo módulo `data` (LW-069; contrato em docs/modules/npc.md, seção 6). UMA linha (tabela plana) com
## `id`, `lod_enter_radius_m`, `lod_exit_radius_m` (inteiros, metros, saída maior que entrada) e `max_s0`. Arquivo só do LOD, e não o
## `npc_params.json` do contrato (outra tarefa do módulo o cria; dois arquivos novos de mesmo nome colidiriam): unificar depois. Qualquer
## problema vira falha com arquivo, item e campo. Nunca carrega recurso nem executa nada do arquivo.

const LOD_TABLE: String = "lod_params"
const DEFAULT_FILE: String = "lod_params.json"
const DEFAULT_DIR: String = "res://data"
const CODE_INVALID: String = "LOD_PARAMS_INVALID"


## Esquema da tabela; o nome do arquivo pode ser trocado (testes).
static func build_schema(file_name: String = DEFAULT_FILE) -> DataSchema:
	var schema: DataSchema = DataSchema.new(LOD_TABLE, file_name)
	schema.add_field("lod_enter_radius_m", DataSchema.FieldType.INT).set_range(LodParams.MIN_RADIUS_M, LodParams.MAX_RADIUS_M)
	schema.add_field("lod_exit_radius_m", DataSchema.FieldType.INT).set_range(LodParams.MIN_RADIUS_M, LodParams.MAX_RADIUS_M)
	schema.add_field("max_s0", DataSchema.FieldType.INT).set_range(LodParams.MIN_S0_LIMIT, LodParams.MAX_S0_LIMIT)
	return schema


## Lê o arquivo, valida e monta os parâmetros.
static func load_dir(base_dir: String = DEFAULT_DIR, file_name: String = DEFAULT_FILE) -> LoadResult:
	var bundle: DataBundle = DataLoader.load_all(base_dir, [build_schema(file_name)])
	_check_semantics(bundle)
	if not bundle.is_valid():
		return LoadResult.new(Result.failure(CODE_INVALID, bundle.describe_issues()), null)
	var record: Dictionary = bundle.tables[LOD_TABLE][0]
	return LoadResult.new(Result.success(), LodParams.new(record["lod_enter_radius_m"], record["lod_exit_radius_m"], record["max_s0"]))


## O que o esquema não vê: exatamente uma linha e raio de saída maior que o de entrada. Registro com problema de tipo é pulado
## (o erro já foi relatado); tabela ausente também.
static func _check_semantics(bundle: DataBundle) -> void:
	if not bundle.tables.has(LOD_TABLE):
		return
	var file_path: String = bundle.file_paths[LOD_TABLE]
	var records: Array = bundle.tables[LOD_TABLE]
	if records.size() != 1:
		bundle.add_issue(file_path, "", "", "esperada exatamente 1 linha de parâmetros, encontradas %d" % records.size())
	for record: Dictionary in records:
		if typeof(record.get("lod_enter_radius_m")) == TYPE_INT and typeof(record.get("lod_exit_radius_m")) == TYPE_INT and int(record["lod_exit_radius_m"]) <= int(record["lod_enter_radius_m"]):
			bundle.add_issue(file_path, str(record.get("id", "")), "lod_exit_radius_m", "raio de saída (%d m) precisa ser maior que o de entrada (%d m): é isso que dá a histerese" % [record["lod_exit_radius_m"], record["lod_enter_radius_m"]])


## Resultado do carregamento: `params` só vale se `result.ok` (mesmo padrão dos outros carregadores).
class LoadResult:
	extends RefCounted

	var result: Result
	var params: LodParams

	func _init(load_result: Result, loaded_params: LodParams) -> void:
		result = load_result
		params = loaded_params
