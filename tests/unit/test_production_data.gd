extends GutTest
## LW-092: os dados da produção (data/economy: receitas, insumos, saídas, manutenção, eficiência e locais) e o `ProductionLoader` (docs/economy/dados.md). Aqui: o arquivo real (10 receitas, cada bem produzido por uma só, a regra de
## margem, 28 regras de manutenção só de `tool`, `plank` e `fabric`, os 14 locais de produção dos povoados, da LW-097), uma receita nova só por dado e o dado inválido, que falha apontando arquivo, item e campo. Os [HIP] só são conferidos quanto à faixa.

const DATA_DIR: String = "res://data/economy"
const TEXT_FILE: String = "res://data/text/pt_br.json"
const RECIPE_IDS: Array[String] = ["grow_grain", "cut_wood", "mine_ore", "shear_wool", "mill_flour", "bake_bread", "saw_plank", "smelt_metal", "forge_tool", "weave_fabric"]
const EXTRACTION: Array[String] = ["grow_grain", "cut_wood", "mine_ore", "shear_wool"]


func _tables() -> Dictionary[String, Array]:
	var bundle: DataBundle = DataLoader.load_all(DATA_DIR, ProductionLoader.build_schemas())
	assert_true(bundle.is_valid(), bundle.describe_issues())
	var copy: Dictionary[String, Array] = {}
	for table_id: String in bundle.tables:
		copy[table_id] = bundle.tables[table_id].duplicate(true)
	return copy


func _row(tables: Dictionary[String, Array], table_id: String, row_id: String) -> Dictionary:
	for record: Dictionary in tables[table_id]:
		if record["id"] == row_id:
			return record
	fail_test("A linha '%s' não existe em '%s'." % [row_id, table_id])
	return {}


func _expect_failure(label: String, tables: Dictionary[String, Array], fragments: Array[String]) -> void:
	var loaded: ProductionLoader.LoadResult = ProductionLoader.from_tables(tables, DATA_DIR)
	assert_false(loaded.result.ok, "%s: deveria falhar." % label)
	assert_eq(loaded.result.code, EconomyCodes.DATA_INVALID, label)
	assert_true(loaded.recipes.is_empty() and loaded.params == null and loaded.sites.is_empty(), "%s: falha não devolve definição." % label)
	for fragment: String in fragments:
		assert_string_contains(loaded.result.message, fragment, "%s: a mensagem deveria citar '%s'." % [label, fragment])


func test_the_real_data_has_ten_recipes_one_producer_per_good_and_the_margin_rule() -> void:
	var loaded: ProductionLoader.LoadResult = ProductionLoader.load_dir(DATA_DIR)
	assert_true(loaded.result.ok, loaded.result.message)
	var goods: GoodsLoader.LoadResult = GoodsLoader.load_dir(DATA_DIR)
	var values: Dictionary[String, int] = {}
	for good: GoodDef in goods.goods:
		values[good.id] = good.base_value
	assert_eq(loaded.recipes.keys(), RECIPE_IDS, "As 10 receitas do contrato, na ordem do arquivo.")
	var producers: Dictionary[String, int] = {}
	for recipe_id: String in loaded.recipes:
		var recipe: RecipeDef = loaded.recipes[recipe_id]
		assert_eq(recipe.is_extraction(), EXTRACTION.has(recipe_id), "%s: só as quatro de extração não têm insumo." % recipe_id)
		assert_eq(recipe.name_key, "recipe.%s.name" % recipe_id)
		var made: int = 0
		var spent: int = recipe.workers_per_batch * recipe.wage_per_hour
		for good_id: String in recipe.outputs:
			made += recipe.outputs[good_id] * values[good_id]
			producers[good_id] = int(producers.get(good_id, 0)) + 1
			assert_false(recipe.inputs.has(good_id), "%s: nenhum bem é insumo e saída." % recipe_id)
		for good_id: String in recipe.inputs:
			spent += recipe.inputs[good_id] * values[good_id]
		assert_gt(made, spent, "%s: os produtos valem mais que os insumos e o salário do lote." % recipe_id)
	for good_id: String in values:
		assert_eq(producers.get(good_id, 0), 1, "%s: produzido por exatamente uma receita." % good_id)
	assert_eq(loaded.recipes["smelt_metal"].inputs, {"ore": 4, "wood": 2} as Dictionary[String, int], "O metal leva minério e madeira (combustível).")
	assert_eq(loaded.recipes["bake_bread"].outputs, {"bread": 6} as Dictionary[String, int])
	assert_eq([loaded.sites.size()], [14], "Os 14 locais de produção dos povoados (LW-097): 5 no A, 6 no B e 3 no C.")


func test_the_real_upkeep_rules_use_only_tool_plank_and_fabric_and_the_site_params_are_in_range() -> void:
	var loaded: ProductionLoader.LoadResult = ProductionLoader.load_dir(DATA_DIR)
	var total: int = 0
	for recipe_id: String in loaded.recipes:
		var recipe: RecipeDef = loaded.recipes[recipe_id]
		var kept: Array[String] = []
		for rule: UpkeepRule in recipe.upkeep:
			kept.append(rule.good_id)
			assert_true(ProductionLoader.UPKEEP_GOODS.has(rule.good_id) and rule.quantity >= 1 and rule.period_days >= 1, "%s: regra na faixa." % recipe_id)
		total += kept.size()
		assert_eq(kept.has("fabric"), recipe_id != "saw_plank" and recipe_id != "forge_tool", "%s: a serraria e a forja não gastam tecido (Q22)." % recipe_id)
	assert_eq(total, 28, "10 de tool, 10 de plank e 8 de fabric.")
	var params: SiteParams = loaded.params
	assert_true(params.min_efficiency_bp >= 1 and params.min_efficiency_bp <= 10000, "O piso da eficiência é maior que 0 (nunca zera).")
	assert_true(params.efficiency_step_bp >= 1 and params.efficiency_recover_bp >= 1)


func test_every_recipe_has_a_text_key_in_the_text_file() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(TEXT_FILE))
	var texts: Dictionary = parsed if typeof(parsed) == TYPE_DICTIONARY else {}
	for recipe: RecipeDef in ProductionLoader.load_dir(DATA_DIR).recipes.values():
		assert_false(str(texts.get(recipe.name_key, "")).is_empty(), "A chave '%s' existe em pt_br.json." % recipe.name_key)


func test_a_recipe_and_a_good_added_only_by_data_pass_and_a_site_line_is_accepted() -> void:
	var tables: Dictionary[String, Array] = _tables()
	tables["goods"].append({"id": "salt", "name_key": "good.salt.name", "category": "raw_material", "base_value": 5, "weight": 1, "perishability_days": 0})
	tables["recipes"].append({"id": "evaporate_salt", "name_key": "recipe.evaporate_salt.name", "occupation_id": "artisan", "workers_per_batch": 2, "max_batches_per_hour": 1, "wage_per_hour": 1})
	tables["recipe_outputs"].append({"id": "evaporate_salt_out_salt", "recipe_id": "evaporate_salt", "good_id": "salt", "quantity": 5})
	tables["production_sites"].append({"id": "site_x", "settlement_id": "test_settlement_a", "place_id": "a_work_06", "recipe_id": "evaporate_salt", "workers_wanted": 4})
	var loaded: ProductionLoader.LoadResult = ProductionLoader.from_tables(tables, DATA_DIR)
	assert_true(loaded.result.ok, loaded.result.message)
	assert_eq([loaded.recipes.size(), loaded.recipes["evaporate_salt"].is_extraction(), loaded.sites.size(), loaded.sites[14].workers_wanted], [11, true, 15, 4], "A linha nova entra depois das 14 dos dados reais, num local de trabalho que ainda não tem local de produção.")


func test_invalid_recipe_lines_are_refused_pointing_at_file_item_and_field() -> void:
	var cases: Array[Dictionary] = [
		{"label": "campo ausente", "table": "recipes", "row": "bake_bread", "erase": "wage_per_hour", "expect": ["recipes.json", "item 'bake_bread'", "campo 'wage_per_hour'", "obrigatório ausente"]},
		{"label": "tipo errado", "table": "recipes", "row": "bake_bread", "set": {"workers_per_batch": "3"}, "expect": ["item 'bake_bread'", "campo 'workers_per_batch'", "tipo inválido"]},
		{"label": "lote sem trabalhadores", "table": "recipes", "row": "bake_bread", "set": {"workers_per_batch": 0}, "expect": ["item 'bake_bread'", "campo 'workers_per_batch'"]},
		{"label": "salário negativo", "table": "recipes", "row": "bake_bread", "set": {"wage_per_hour": -1}, "expect": ["item 'bake_bread'", "campo 'wage_per_hour'"]},
		{"label": "id repetido", "table": "recipes", "row": "bake_bread", "set": {"id": "mill_flour"}, "expect": ["item 'mill_flour'", "campo 'id'", "id duplicado"]},
		{"label": "regra de margem", "table": "recipes", "row": "bake_bread", "set": {"wage_per_hour": 50}, "expect": ["item 'bake_bread'", "campo 'wage_per_hour'", "regra de margem"]},
		{"label": "insumo com receita inexistente", "table": "recipe_inputs", "row": "bake_bread_in_flour", "set": {"recipe_id": "bake_cake"}, "expect": ["recipe_inputs.json", "item 'bake_bread_in_flour'", "campo 'recipe_id'", "'bake_cake' na tabela 'recipes'"]},
		{"label": "insumo com bem inexistente", "table": "recipe_inputs", "row": "bake_bread_in_flour", "set": {"good_id": "gold"}, "expect": ["item 'bake_bread_in_flour'", "campo 'good_id'", "'gold' na tabela 'goods'"]},
		{"label": "quantidade zero", "table": "recipe_outputs", "row": "bake_bread_out_bread", "set": {"quantity": 0}, "expect": ["recipe_outputs.json", "item 'bake_bread_out_bread'", "campo 'quantity'"]},
		{"label": "bem insumo e saída da mesma receita", "table": "recipe_inputs", "row": "bake_bread_in_flour", "set": {"good_id": "bread", "id": "bake_bread_in_bread"}, "expect": ["recipe_outputs.json", "é insumo e saída da receita 'bake_bread'"]},
		{"label": "bem produzido por duas receitas", "table": "recipe_outputs", "row": "mill_flour_out_flour", "set": {"good_id": "bread"}, "expect": ["recipe_outputs.json", "campo 'good_id'", "o bem 'bread' é produzido por 2 receita(s); esperada exatamente 1"]},
	]
	for test_case: Dictionary in cases:
		var tables: Dictionary[String, Array] = _tables()
		var row: Dictionary = _row(tables, test_case["table"], test_case["row"])
		if test_case.has("erase"):
			row.erase(test_case["erase"])
		else:
			row.merge(test_case["set"], true)
		var fragments: Array[String] = []
		fragments.assign(test_case["expect"])
		_expect_failure(test_case["label"], tables, fragments)
	var repeated: Dictionary[String, Array] = _tables()
	repeated["recipe_inputs"].append({"id": "bake_bread_in_flour_again", "recipe_id": "bake_bread", "good_id": "flour", "quantity": 1})
	_expect_failure("par de insumo repetido", repeated, ["recipe_inputs.json", "item 'bake_bread_in_flour_again'", "esperada uma linha por par"])
	var no_output: Dictionary[String, Array] = _tables()
	no_output["recipe_outputs"] = no_output["recipe_outputs"].filter(func(record: Dictionary) -> bool: return record["recipe_id"] != "forge_tool")
	_expect_failure("receita sem saída e bem sem receita", no_output, ["recipes.json", "item 'forge_tool'", "não tem nenhuma linha de saída", "o bem 'tool' é produzido por 0 receita(s)"])


func test_invalid_upkeep_params_and_sites_are_refused_pointing_at_file_item_and_field() -> void:
	var cases: Array[Dictionary] = [
		{"label": "manutenção com bem fora do vocabulário", "table": "site_upkeep", "row": "upkeep_grow_grain_tool", "set": {"good_id": "wood"}, "expect": ["site_upkeep.json", "item 'upkeep_grow_grain_tool'", "campo 'good_id'", "não pode ser de manutenção; esperado um de: tool, plank, fabric"]},
		{"label": "par de manutenção repetido", "table": "site_upkeep", "row": "upkeep_grow_grain_tool", "set": {"good_id": "plank"}, "expect": ["item 'upkeep_grow_grain_plank'", "esperada uma regra por par"]},
		{"label": "período zero", "table": "site_upkeep", "row": "upkeep_grow_grain_tool", "set": {"period_days": 0}, "expect": ["item 'upkeep_grow_grain_tool'", "campo 'period_days'"]},
		{"label": "quantidade zero de manutenção", "table": "site_upkeep", "row": "upkeep_grow_grain_tool", "set": {"quantity": 0}, "expect": ["item 'upkeep_grow_grain_tool'", "campo 'quantity'"]},
		{"label": "piso de eficiência zero", "table": "site_params", "row": "site_defaults", "set": {"min_efficiency_bp": 0}, "expect": ["site_params.json", "item 'site_defaults'", "campo 'min_efficiency_bp'"]},
		{"label": "piso acima de 10000", "table": "site_params", "row": "site_defaults", "set": {"min_efficiency_bp": 10001}, "expect": ["item 'site_defaults'", "campo 'min_efficiency_bp'"]},
		{"label": "queda de eficiência zero", "table": "site_params", "row": "site_defaults", "set": {"efficiency_step_bp": 0}, "expect": ["item 'site_defaults'", "campo 'efficiency_step_bp'"]},
	]
	for test_case: Dictionary in cases:
		var tables: Dictionary[String, Array] = _tables()
		_row(tables, test_case["table"], test_case["row"]).merge(test_case["set"], true)
		var fragments: Array[String] = []
		fragments.assign(test_case["expect"])
		_expect_failure(test_case["label"], tables, fragments)
	var two: Dictionary[String, Array] = _tables()
	two["site_params"].append(two["site_params"][0].duplicate(true))
	two["site_params"][1]["id"] = "site_other"
	_expect_failure("duas linhas de eficiência", two, ["site_params.json", "esperada exatamente 1 linha de constantes de eficiência, encontradas 2"])
	var sites: Dictionary[String, Array] = _tables()
	sites["production_sites"].append({"id": "site_a", "settlement_id": "test_settlement_a", "place_id": "a_work_01", "recipe_id": "grow_grain", "workers_wanted": 4})
	sites["production_sites"].append({"id": "site_b", "settlement_id": "test_settlement_a", "place_id": "a_work_01", "recipe_id": "cut_wood", "workers_wanted": 4})
	_expect_failure("dois locais de produção no mesmo local", sites, ["production_sites.json", "item 'site_b'", "campo 'place_id'", "esperado um por local"])
	var bad_site: Dictionary[String, Array] = _tables()
	bad_site["production_sites"].append({"id": "site_c", "settlement_id": "test_settlement_a", "place_id": "a_work_02", "recipe_id": "no_such_recipe", "workers_wanted": 0})
	_expect_failure("local com receita inexistente e equipe zero", bad_site, ["production_sites.json", "item 'site_c'", "campo 'recipe_id'", "'no_such_recipe' na tabela 'recipes'", "campo 'workers_wanted'"])
