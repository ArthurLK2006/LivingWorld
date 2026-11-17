class_name ContractLimitLoader
extends RefCounted
## Lê e valida data/economy/contract_limits.json pelo módulo `data` (LW-107f2; docs/economy/dados.md): o LIMITE de encomendas aceitas ao mesmo tempo, POR CATEGORIA de contrato (uma linha por `kind`). O arquivo é OPCIONAL, como
## `contract_templates.json`: sem ele, com a tabela vazia ou numa categoria sem linha NÃO há limite definido (lista vazia; `EconomyModule.peek_contract_limit` devolve 0). O esquema confere campos, tipos e a faixa (nenhum FLOAT); o que ele
## não vê é conferido aqui: `kind` do vocabulário de `ContractBook.CONTRACT_TYPES` e uma linha só por categoria. Falha com `ECON_DATA_INVALID`, arquivo, item e campo. Nunca carrega recurso, executa nada do arquivo, lança erro nem escreve no log.

const LIMITS_TABLE: String = "contract_limits"
const LIMITS_FILE: String = "contract_limits.json"
## Faixa [HIP] do `dados.md`: de 1 a 20 encomendas aceitas ao mesmo tempo (a categoria sem limite é a categoria SEM linha, não uma linha com 0).
const MIN_ACCEPTED: int = 1
const MAX_ACCEPTED: int = 20


## O esquema da tabela dos limites (ela não cita outra tabela: o arquivo é lido sozinho).
static func build_schemas() -> Array[DataSchema]:
	var limits: DataSchema = DataSchema.new(LIMITS_TABLE, LIMITS_FILE)
	limits.add_field("kind", DataSchema.FieldType.STRING)
	limits.add_field("max_accepted", DataSchema.FieldType.INT).set_range(MIN_ACCEPTED, MAX_ACCEPTED)
	var schemas: Array[DataSchema] = [limits]
	return schemas


## Sem o arquivo na pasta não há limite (lista vazia, sucesso): o arquivo é opcional.
static func load_dir(base_dir: String = GoodsLoader.DEFAULT_DIR) -> LoadResult:
	if not FileAccess.file_exists(base_dir.path_join(LIMITS_FILE)):
		return LoadResult.new(Result.success(), [] as Array[ContractLimitDef])
	var bundle: DataBundle = DataLoader.load_all(base_dir, build_schemas())
	_check_limits(bundle)
	if not bundle.is_valid():
		return LoadResult.new(Result.failure(EconomyCodes.DATA_INVALID, bundle.describe_issues()), [] as Array[ContractLimitDef])
	var limits: Array[ContractLimitDef] = []
	for record: Dictionary in bundle.tables.get(LIMITS_TABLE, []):
		limits.append(ContractLimitDef.new(str(record["id"]), str(record["kind"]), record["max_accepted"]))
	return LoadResult.new(Result.success(), limits)


## O que o esquema não vê, linha a linha: `kind` do vocabulário dos contratos e uma linha por categoria. Campo de tipo errado já tem o problema do esquema e é pulado aqui; o item é o `id` da linha (ou `#posição` se o `id` não presta).
static func _check_limits(bundle: DataBundle) -> void:
	if not bundle.tables.has(LIMITS_TABLE):
		return
	var file_path: String = bundle.file_paths[LIMITS_TABLE]
	var first_of_kind: Dictionary[String, String] = {}
	var records: Array = bundle.tables[LIMITS_TABLE]
	for index: int in records.size():
		var record: Dictionary = records[index]
		if typeof(record.get("kind")) != TYPE_STRING:
			continue
		var kind: String = record["kind"]
		var item: String = record["id"] if typeof(record.get("id")) == TYPE_STRING else "#%d" % index
		if not ContractBook.CONTRACT_TYPES.has(kind):
			bundle.add_issue(file_path, item, "kind", "a categoria '%s' não é um tipo de contrato; esperado um de: %s" % [kind, ", ".join(ContractBook.CONTRACT_TYPES)])
		elif first_of_kind.has(kind):
			bundle.add_issue(file_path, item, "kind", "a categoria '%s' já tem o limite '%s'; esperado uma linha por categoria" % [kind, first_of_kind[kind]])
		else:
			first_of_kind[kind] = item


## Resultado do carregamento: `limits` (na ordem do arquivo) só vale se `result.ok`.
class LoadResult:
	extends RefCounted

	var result: Result
	var limits: Array[ContractLimitDef]

	func _init(load_result: Result, loaded_limits: Array[ContractLimitDef]) -> void:
		result = load_result
		limits = loaded_limits
