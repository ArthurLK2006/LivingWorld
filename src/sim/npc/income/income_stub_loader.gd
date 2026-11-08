class_name IncomeStubLoader
extends RefCounted
## TEMP-LW-066: lê e valida data/income_stub.json pelo módulo `data` (docs/modules/npc.md, seção 9). SAI NA LW-095, junto com o IncomeStub.
## Uma linha por ofício: `id`, `temp_mark` (obrigatório, igual a "TEMP-LW-066"), `occupation_id` e `income_relief` (de 0 a 100, a faixa de
## uma necessidade). O que o esquema não vê é conferido aqui: ao menos uma linha, um ofício por linha e a marca certa. Que o ofício EXISTE nos
## dados de ofícios é conferido por quem monta o módulo (`IncomeStub.check_references`), porque o `data` só confere referência dentro da mesma
## leitura. Qualquer problema vira falha com arquivo, item e campo. Nunca carrega recurso nem executa nada do arquivo.

const INCOME_TABLE: String = "income_stub"
const DEFAULT_FILE: String = "income_stub.json"
const DEFAULT_DIR: String = "res://data"
const CODE_INVALID: String = "NPC_INCOME_STUB_INVALID"


## Esquema da tabela; o nome do arquivo pode ser trocado (testes).
static func build_schema(file_name: String = DEFAULT_FILE) -> DataSchema:
	var schema: DataSchema = DataSchema.new(INCOME_TABLE, file_name)
	schema.add_field("temp_mark", DataSchema.FieldType.STRING)
	schema.add_field("occupation_id", DataSchema.FieldType.STRING)
	schema.add_field("income_relief", DataSchema.FieldType.INT).set_range(0, NpcState.VALUE_MAX)
	return schema


## Lê o arquivo, valida e monta a tabela de renda.
static func load_dir(base_dir: String = DEFAULT_DIR, file_name: String = DEFAULT_FILE) -> LoadResult:
	var bundle: DataBundle = DataLoader.load_all(base_dir, [build_schema(file_name)])
	return from_bundle(bundle)


## Confere o que o esquema não vê e monta a tabela de um pacote já lido e validado pelo `data`.
static func from_bundle(bundle: DataBundle) -> LoadResult:
	check_semantics(bundle)
	if not bundle.is_valid():
		return LoadResult.new(Result.failure(CODE_INVALID, bundle.describe_issues()), null)
	return LoadResult.new(Result.success(), IncomeStub.new(_build_rules(bundle)))


## Acrescenta ao pacote o que o esquema não vê (ver o cabeçalho).
static func check_semantics(bundle: DataBundle) -> void:
	if not bundle.tables.has(INCOME_TABLE):
		return
	var file_path: String = bundle.file_paths[INCOME_TABLE]
	var records: Array = bundle.tables[INCOME_TABLE]
	if records.is_empty():
		bundle.add_issue(file_path, "", "", "esperada ao menos 1 linha de renda, encontradas 0")
	var seen_occupations: Dictionary[String, String] = {}
	for record: Dictionary in records:
		var item: String = str(record.get("id", ""))
		var mark: Variant = record.get("temp_mark")
		if typeof(mark) == TYPE_STRING and str(mark) != IncomeStub.TEMP_MARK:
			bundle.add_issue(file_path, item, "temp_mark", "valor '%s'; esperado exatamente '%s'" % [mark, IncomeStub.TEMP_MARK])
		var occupation: Variant = record.get("occupation_id")
		if typeof(occupation) != TYPE_STRING:
			continue
		var occupation_id: String = occupation
		if occupation_id.is_empty():
			bundle.add_issue(file_path, item, "occupation_id", "o ofício não pode ficar vazio")
		elif seen_occupations.has(occupation_id):
			bundle.add_issue(file_path, item, "occupation_id", "o ofício '%s' já tem regra na linha '%s'; esperada uma linha por ofício" % [occupation_id, seen_occupations[occupation_id]])
		else:
			seen_occupations[occupation_id] = item


static func _build_rules(bundle: DataBundle) -> Array[IncomeStub.IncomeRule]:
	var rules: Array[IncomeStub.IncomeRule] = []
	for record: Dictionary in bundle.tables[INCOME_TABLE]:
		rules.append(IncomeStub.IncomeRule.new(record["occupation_id"], record["income_relief"]))
	return rules


## Resultado do carregamento: `stub` só vale se `result.ok` (mesmo padrão dos outros carregadores).
class LoadResult:
	extends RefCounted

	var result: Result
	var stub: IncomeStub

	func _init(load_result: Result, loaded_stub: IncomeStub) -> void:
		result = load_result
		stub = loaded_stub
