class_name FoodStubLoader
extends RefCounted
## TEMP-LW-065: lê e valida data/food_stub.json pelo módulo `data` (docs/modules/npc.md, seção 9). SAI NA LW-094, junto com o FoodStub. Uma
## linha por assentamento: `id`, `temp_mark` (obrigatório, igual a "TEMP-LW-065"), `settlement_id`, `start_stock`, `max_stock`, `eat_cost`,
## `yield_occupation_id` e `work_yield`. O que o esquema não vê é conferido aqui: ao menos uma linha, um assentamento por linha, a marca
## certa e números coerentes (estoque inicial, refeição e colheita cabem no teto). Que o assentamento e o ofício EXISTEM nos outros dados
## é conferido por quem monta o módulo (`FoodStub.check_references`), porque o `data` só confere referência dentro da mesma leitura.
## Qualquer problema vira falha com arquivo, item e campo. Nunca carrega recurso nem executa nada do arquivo.

const FOOD_TABLE: String = "food_stub"
const DEFAULT_FILE: String = "food_stub.json"
const DEFAULT_DIR: String = "res://data"
const CODE_INVALID: String = "NPC_FOOD_STUB_INVALID"
## Faixas de segurança [HIP] (não são limites de design).
const MAX_STOCK: int = 1000000
const MAX_MEAL_COST: int = 1000


## Esquema da tabela; o nome do arquivo pode ser trocado (testes).
static func build_schema(file_name: String = DEFAULT_FILE) -> DataSchema:
	var schema: DataSchema = DataSchema.new(FOOD_TABLE, file_name)
	schema.add_field("temp_mark", DataSchema.FieldType.STRING)
	schema.add_field("settlement_id", DataSchema.FieldType.STRING)
	schema.add_field("start_stock", DataSchema.FieldType.INT).set_range(0, MAX_STOCK)
	schema.add_field("max_stock", DataSchema.FieldType.INT).set_range(1, MAX_STOCK)
	schema.add_field("eat_cost", DataSchema.FieldType.INT).set_range(1, MAX_MEAL_COST)
	schema.add_field("yield_occupation_id", DataSchema.FieldType.STRING)
	schema.add_field("work_yield", DataSchema.FieldType.INT).set_range(0, MAX_STOCK)
	return schema


## Lê o arquivo, valida e monta o estoque.
static func load_dir(base_dir: String = DEFAULT_DIR, file_name: String = DEFAULT_FILE) -> LoadResult:
	var bundle: DataBundle = DataLoader.load_all(base_dir, [build_schema(file_name)])
	return from_bundle(bundle)


## Confere o que o esquema não vê e monta o estoque de um pacote já lido e validado pelo `data`.
static func from_bundle(bundle: DataBundle) -> LoadResult:
	check_semantics(bundle)
	if not bundle.is_valid():
		return LoadResult.new(Result.failure(CODE_INVALID, bundle.describe_issues()), null)
	return LoadResult.new(Result.success(), FoodStub.new(_build_rules(bundle)))


## Acrescenta ao pacote o que o esquema não vê (ver o cabeçalho).
static func check_semantics(bundle: DataBundle) -> void:
	if not bundle.tables.has(FOOD_TABLE):
		return
	var file_path: String = bundle.file_paths[FOOD_TABLE]
	var records: Array = bundle.tables[FOOD_TABLE]
	if records.is_empty():
		bundle.add_issue(file_path, "", "", "esperada ao menos 1 linha de regra de comida, encontradas 0")
	var seen_settlements: Dictionary[String, String] = {}
	for record: Dictionary in records:
		var item: String = str(record.get("id", ""))
		_check_text(bundle, file_path, item, record, "temp_mark", FoodStub.TEMP_MARK)
		var settlement: Variant = record.get("settlement_id")
		if typeof(settlement) == TYPE_STRING:
			var settlement_id: String = settlement
			if settlement_id.is_empty():
				bundle.add_issue(file_path, item, "settlement_id", "o assentamento não pode ficar vazio")
			elif seen_settlements.has(settlement_id):
				bundle.add_issue(file_path, item, "settlement_id", "o assentamento '%s' já tem regra na linha '%s'; esperada uma linha por assentamento" % [settlement_id, seen_settlements[settlement_id]])
			else:
				seen_settlements[settlement_id] = item
		var occupation: Variant = record.get("yield_occupation_id")
		if typeof(occupation) == TYPE_STRING and str(occupation).is_empty():
			bundle.add_issue(file_path, item, "yield_occupation_id", "o ofício que produz comida não pode ficar vazio")
		_check_fits_the_ceiling(bundle, file_path, item, record)


## Campo de texto que precisa ser exatamente `expected`.
static func _check_text(bundle: DataBundle, file_path: String, item: String, record: Dictionary, field: String, expected: String) -> void:
	var value: Variant = record.get(field)
	if typeof(value) == TYPE_STRING and str(value) != expected:
		bundle.add_issue(file_path, item, field, "valor '%s'; esperado exatamente '%s'" % [value, expected])


## Estoque inicial, refeição e colheita precisam caber no teto do assentamento.
static func _check_fits_the_ceiling(bundle: DataBundle, file_path: String, item: String, record: Dictionary) -> void:
	if typeof(record.get("max_stock")) != TYPE_INT:
		return
	var max_stock: int = record["max_stock"]
	for field: String in ["start_stock", "eat_cost", "work_yield"]:
		if typeof(record.get(field)) == TYPE_INT and int(record[field]) > max_stock:
			bundle.add_issue(file_path, item, field, "o valor %d passa do teto max_stock = %d" % [record[field], max_stock])


static func _build_rules(bundle: DataBundle) -> Array[FoodStub.FoodRule]:
	var rules: Array[FoodStub.FoodRule] = []
	for record: Dictionary in bundle.tables[FOOD_TABLE]:
		rules.append(FoodStub.FoodRule.new(record["settlement_id"], record["start_stock"], record["max_stock"], record["eat_cost"], record["yield_occupation_id"], record["work_yield"]))
	return rules


## Resultado do carregamento: `stub` só vale se `result.ok` (mesmo padrão dos outros carregadores).
class LoadResult:
	extends RefCounted

	var result: Result
	var stub: FoodStub

	func _init(load_result: Result, loaded_stub: FoodStub) -> void:
		result = load_result
		stub = loaded_stub
