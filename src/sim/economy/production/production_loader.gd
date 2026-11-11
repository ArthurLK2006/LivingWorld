class_name ProductionLoader
extends RefCounted
## Lê e valida as seis tabelas da produção pelo módulo `data` (LW-092; docs/economy/dados.md), LENDO JUNTO os bens (para as referências `good_id`): `recipes`, `recipe_inputs`, `recipe_outputs`, `site_upkeep`, `site_params` (uma linha) e
## `production_sites` (pode estar vazia: os dados dos povoados são da LW-097). O que o esquema não vê é conferido aqui: par (receita, bem) único em cada tabela; toda receita com ao menos uma saída e nenhum bem como insumo e saída
## da mesma receita; todo bem produzido por EXATAMENTE uma receita; a REGRA DE MARGEM (o valor dos produtos é maior que o dos insumos mais o salário do lote, senão o local não paga a folha com a venda); manutenção só de `tool`, `plank`
## ou `fabric`; `min_efficiency_bp` de 1 a 10000; um local de produção por `place_id`. Falha com `ECON_DATA_INVALID`, arquivo, item e campo. Nunca carrega recurso nem executa nada do arquivo.

const RECIPES_TABLE: String = "recipes"
const INPUTS_TABLE: String = "recipe_inputs"
const OUTPUTS_TABLE: String = "recipe_outputs"
const UPKEEP_TABLE: String = "site_upkeep"
const PARAMS_TABLE: String = "site_params"
const SITES_TABLE: String = "production_sites"
const MAX_VALUE: int = 1000000000
const MAX_BP: int = 10000
const UPKEEP_GOODS: Array[String] = ["tool", "plank", "fabric"]


static func build_schemas() -> Array[DataSchema]:
	var schemas: Array[DataSchema] = GoodsLoader.build_schemas()
	var recipes: DataSchema = DataSchema.new(RECIPES_TABLE, "recipes.json")
	recipes.add_field("name_key", DataSchema.FieldType.STRING)
	recipes.add_field("occupation_id", DataSchema.FieldType.STRING)
	recipes.add_field("workers_per_batch", DataSchema.FieldType.INT).set_range(1, MAX_VALUE)
	recipes.add_field("max_batches_per_hour", DataSchema.FieldType.INT).set_range(1, MAX_VALUE)
	recipes.add_field("wage_per_hour", DataSchema.FieldType.INT).set_range(0, MAX_VALUE)
	schemas.append(recipes)
	for table_and_file: Array in [[INPUTS_TABLE, "recipe_inputs.json"], [OUTPUTS_TABLE, "recipe_outputs.json"]]:
		var lines: DataSchema = DataSchema.new(table_and_file[0], table_and_file[1])
		lines.add_field("recipe_id", DataSchema.FieldType.STRING).set_ref(RECIPES_TABLE)
		lines.add_field("good_id", DataSchema.FieldType.STRING).set_ref(GoodsLoader.GOODS_TABLE)
		lines.add_field("quantity", DataSchema.FieldType.INT).set_range(1, MAX_VALUE)
		schemas.append(lines)
	var upkeep: DataSchema = DataSchema.new(UPKEEP_TABLE, "site_upkeep.json")
	upkeep.add_field("recipe_id", DataSchema.FieldType.STRING).set_ref(RECIPES_TABLE)
	upkeep.add_field("good_id", DataSchema.FieldType.STRING).set_ref(GoodsLoader.GOODS_TABLE)
	upkeep.add_field("quantity", DataSchema.FieldType.INT).set_range(1, MAX_VALUE)
	upkeep.add_field("period_days", DataSchema.FieldType.INT).set_range(1, MAX_VALUE)
	schemas.append(upkeep)
	var params: DataSchema = DataSchema.new(PARAMS_TABLE, "site_params.json")
	for field: String in ["efficiency_step_bp", "efficiency_recover_bp", "min_efficiency_bp"]:
		params.add_field(field, DataSchema.FieldType.INT).set_range(1, MAX_BP)
	schemas.append(params)
	var sites: DataSchema = DataSchema.new(SITES_TABLE, "production_sites.json")
	sites.add_field("settlement_id", DataSchema.FieldType.STRING)
	sites.add_field("place_id", DataSchema.FieldType.STRING)
	sites.add_field("recipe_id", DataSchema.FieldType.STRING).set_ref(RECIPES_TABLE)
	sites.add_field("workers_wanted", DataSchema.FieldType.INT).set_range(1, MAX_VALUE)
	schemas.append(sites)
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
	_check_lines(bundle)
	_check_recipes(bundle)
	_check_upkeep_and_sites(bundle)
	if not bundle.is_valid():
		return LoadResult.new(Result.failure(EconomyCodes.DATA_INVALID, bundle.describe_issues()), {}, null, [])
	return _build(bundle)


## Par (receita, bem) único em cada tabela de linhas; nenhum bem é insumo e saída da mesma receita.
static func _check_lines(bundle: DataBundle) -> void:
	var inputs_seen: Dictionary[String, String] = {}
	for table_id: String in [INPUTS_TABLE, OUTPUTS_TABLE]:
		if not bundle.tables.has(table_id):
			continue
		var file_path: String = bundle.file_paths[table_id]
		var seen: Dictionary[String, String] = {}
		for record: Dictionary in bundle.tables[table_id]:
			if typeof(record.get("recipe_id")) != TYPE_STRING or typeof(record.get("good_id")) != TYPE_STRING:
				continue
			var item: String = str(record.get("id", ""))
			var pair: String = "%s/%s" % [record["recipe_id"], record["good_id"]]
			if seen.has(pair):
				bundle.add_issue(file_path, item, "good_id", "o bem '%s' já tem linha na receita '%s' (linha '%s'); esperada uma linha por par" % [record["good_id"], record["recipe_id"], seen[pair]])
			else:
				seen[pair] = item
			if table_id == INPUTS_TABLE:
				inputs_seen[pair] = item
			elif inputs_seen.has(pair):
				bundle.add_issue(file_path, item, "good_id", "o bem '%s' é insumo e saída da receita '%s' (insumo na linha '%s')" % [record["good_id"], record["recipe_id"], inputs_seen[pair]])


## Toda receita com ao menos uma saída, todo bem produzido por exatamente uma receita e a regra de margem.
static func _check_recipes(bundle: DataBundle) -> void:
	if not bundle.tables.has(RECIPES_TABLE) or not bundle.tables.has(OUTPUTS_TABLE) or not bundle.tables.has(GoodsLoader.GOODS_TABLE):
		return
	var values: Dictionary[String, int] = {}
	for good: Dictionary in bundle.tables[GoodsLoader.GOODS_TABLE]:
		if typeof(good.get("base_value")) == TYPE_INT:
			values[str(good["id"])] = good["base_value"]
	var produced_by: Dictionary[String, Array] = {}
	var output_value: Dictionary[String, int] = {}
	for record: Dictionary in bundle.tables[OUTPUTS_TABLE]:
		if typeof(record.get("recipe_id")) != TYPE_STRING or typeof(record.get("good_id")) != TYPE_STRING or typeof(record.get("quantity")) != TYPE_INT:
			continue
		var good_id: String = record["good_id"]
		produced_by[good_id] = produced_by.get(good_id, []) + [record["recipe_id"]]
		output_value[record["recipe_id"]] = int(output_value.get(record["recipe_id"], 0)) + int(record["quantity"]) * int(values.get(good_id, 0))
	var input_value: Dictionary[String, int] = {}
	for record: Dictionary in bundle.tables.get(INPUTS_TABLE, []):
		if typeof(record.get("recipe_id")) == TYPE_STRING and typeof(record.get("good_id")) == TYPE_STRING and typeof(record.get("quantity")) == TYPE_INT:
			input_value[record["recipe_id"]] = int(input_value.get(record["recipe_id"], 0)) + int(record["quantity"]) * int(values.get(str(record["good_id"]), 0))
	var recipes_path: String = bundle.file_paths[RECIPES_TABLE]
	for recipe: Dictionary in bundle.tables[RECIPES_TABLE]:
		var recipe_id: String = str(recipe.get("id", ""))
		if not output_value.has(recipe_id):
			bundle.add_issue(recipes_path, recipe_id, "", "a receita não tem nenhuma linha de saída em recipe_outputs.json; esperado ao menos uma")
		elif typeof(recipe.get("workers_per_batch")) == TYPE_INT and typeof(recipe.get("wage_per_hour")) == TYPE_INT:
			var cost: int = int(input_value.get(recipe_id, 0)) + int(recipe["workers_per_batch"]) * int(recipe["wage_per_hour"])
			if int(output_value[recipe_id]) <= cost:
				bundle.add_issue(recipes_path, recipe_id, "wage_per_hour", "regra de margem: os produtos valem %d e os insumos mais o salário do lote custam %d; esperado produtos de maior valor" % [int(output_value[recipe_id]), cost])
	for good_id: String in values:
		var producers: Array = produced_by.get(good_id, [])
		if producers.size() != 1:
			bundle.add_issue(bundle.file_paths[OUTPUTS_TABLE], "", "good_id", "o bem '%s' é produzido por %d receita(s); esperada exatamente 1" % [good_id, producers.size()])


## Manutenção só de `tool`, `plank` ou `fabric` e par único; uma linha de constantes de eficiência; um local de produção por `place_id`.
static func _check_upkeep_and_sites(bundle: DataBundle) -> void:
	if bundle.tables.has(UPKEEP_TABLE):
		var file_path: String = bundle.file_paths[UPKEEP_TABLE]
		var seen: Dictionary[String, String] = {}
		for record: Dictionary in bundle.tables[UPKEEP_TABLE]:
			var item: String = str(record.get("id", ""))
			if typeof(record.get("good_id")) == TYPE_STRING and not UPKEEP_GOODS.has(str(record["good_id"])):
				bundle.add_issue(file_path, item, "good_id", "o bem '%s' não pode ser de manutenção; esperado um de: %s" % [str(record["good_id"]), ", ".join(UPKEEP_GOODS)])
			if typeof(record.get("recipe_id")) == TYPE_STRING and typeof(record.get("good_id")) == TYPE_STRING:
				var pair: String = "%s/%s" % [record["recipe_id"], record["good_id"]]
				if seen.has(pair):
					bundle.add_issue(file_path, item, "good_id", "o bem '%s' já tem regra na receita '%s' (linha '%s'); esperada uma regra por par" % [record["good_id"], record["recipe_id"], seen[pair]])
				else:
					seen[pair] = item
	if bundle.tables.has(PARAMS_TABLE) and bundle.tables[PARAMS_TABLE].size() != 1:
		bundle.add_issue(bundle.file_paths[PARAMS_TABLE], "", "", "esperada exatamente 1 linha de constantes de eficiência, encontradas %d" % bundle.tables[PARAMS_TABLE].size())
	if bundle.tables.has(SITES_TABLE):
		var places: Dictionary[String, String] = {}
		for record: Dictionary in bundle.tables[SITES_TABLE]:
			if typeof(record.get("place_id")) != TYPE_STRING:
				continue
			var place_id: String = record["place_id"]
			if places.has(place_id):
				bundle.add_issue(bundle.file_paths[SITES_TABLE], str(record.get("id", "")), "place_id", "o local '%s' já tem um local de produção (linha '%s'); esperado um por local" % [place_id, places[place_id]])
			else:
				places[place_id] = str(record.get("id", ""))


static func _build(bundle: DataBundle) -> LoadResult:
	var recipes: Dictionary[String, RecipeDef] = {}
	for record: Dictionary in bundle.tables[RECIPES_TABLE]:
		recipes[str(record["id"])] = RecipeDef.new(str(record["id"]), str(record["name_key"]), str(record["occupation_id"]), record["workers_per_batch"], record["max_batches_per_hour"], record["wage_per_hour"])
	for record: Dictionary in bundle.tables[INPUTS_TABLE]:
		recipes[str(record["recipe_id"])].inputs[str(record["good_id"])] = record["quantity"]
	for record: Dictionary in bundle.tables[OUTPUTS_TABLE]:
		recipes[str(record["recipe_id"])].outputs[str(record["good_id"])] = record["quantity"]
	for record: Dictionary in bundle.tables[UPKEEP_TABLE]:
		recipes[str(record["recipe_id"])].upkeep.append(UpkeepRule.new(str(record["good_id"]), record["quantity"], record["period_days"]))
	var sites: Array[SiteDef] = []
	for record: Dictionary in bundle.tables[SITES_TABLE]:
		sites.append(SiteDef.new(str(record["id"]), str(record["settlement_id"]), str(record["place_id"]), str(record["recipe_id"]), record["workers_wanted"]))
	return LoadResult.new(Result.success(), recipes, SiteParams.new(bundle.tables[PARAMS_TABLE][0]), sites)


## Resultado do carregamento: `recipes` (por id, na ordem do arquivo), `params` e `sites` só valem se `result.ok`.
class LoadResult:
	extends RefCounted

	var result: Result
	var recipes: Dictionary[String, RecipeDef]
	var params: SiteParams
	var sites: Array[SiteDef]

	func _init(load_result: Result, loaded_recipes: Dictionary[String, RecipeDef], loaded_params: SiteParams, loaded_sites: Array[SiteDef]) -> void:
		result = load_result
		recipes = loaded_recipes
		params = loaded_params
		sites = loaded_sites
