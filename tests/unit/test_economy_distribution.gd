extends GutTest
## LW-097e: a distribuição das cadeias de produção pelos três povoados (princípio da DEC-142; tabela do economy.md, seção 6; docs/economy/dados.md, "Distribuição das cadeias"). Lê só tabelas da economia
## (locais de produção, receitas, insumos, saídas e manutenção) mais a população: nenhum povoado se basta, todo bem necessário em algum lugar é produzido em algum lugar, e a equipe de cada local
## é a da linha de população que o ocupa. Os valores esperados dos locais são escritos à mão a partir da tabela aprovada.

const DATA_DIR: String = "res://data/economy"
const POPULATION_DIR: String = "res://data"
const BREAD_ID: String = "bread"
const TOWN_A: String = "test_settlement_a"
const TOWN_B: String = "test_settlement_b"
const TOWN_C: String = "test_settlement_c"
const SETTLEMENTS: Array[String] = [TOWN_A, TOWN_B, TOWN_C]


func _load() -> ProductionLoader.LoadResult:
	var loaded: ProductionLoader.LoadResult = ProductionLoader.load_dir(DATA_DIR)
	assert_true(loaded.result.ok, loaded.result.message)
	return loaded


func _recipes_of(loaded: ProductionLoader.LoadResult, settlement_id: String) -> Array[RecipeDef]:
	var recipes: Array[RecipeDef] = []
	for site: SiteDef in loaded.sites:
		if site.settlement_id == settlement_id:
			recipes.append(loaded.recipes[site.recipe_id])
	return recipes


func _add_once(list: Array[String], good_id: String) -> void:
	if not list.has(good_id):
		list.append(good_id)


## `Produzido(P)`: os bens que as receitas dos locais do povoado fazem.
func _produced(recipes: Array[RecipeDef]) -> Array[String]:
	var produced: Array[String] = []
	for recipe: RecipeDef in recipes:
		for good_id: String in recipe.outputs:
			_add_once(produced, good_id)
	produced.sort()
	return produced


## `Necessário(P)`: insumos das receitas, bens de manutenção dos locais e o pão (comida do povoado).
func _needed(recipes: Array[RecipeDef]) -> Array[String]:
	var needed: Array[String] = [BREAD_ID]
	for recipe: RecipeDef in recipes:
		for good_id: String in recipe.inputs:
			_add_once(needed, good_id)
		for rule: UpkeepRule in recipe.upkeep:
			_add_once(needed, rule.good_id)
	needed.sort()
	return needed


## O que o povoado precisa e não faz: vazio quer dizer que ele se basta.
func _missing(recipes: Array[RecipeDef]) -> Array[String]:
	var produced: Array[String] = _produced(recipes)
	var missing: Array[String] = []
	for good_id: String in _needed(recipes):
		if not produced.has(good_id):
			missing.append(good_id)
	return missing


func _recipe(recipe_id: String, inputs: Dictionary[String, int], outputs: Dictionary[String, int]) -> RecipeDef:
	var recipe: RecipeDef = RecipeDef.new(recipe_id, "recipe.%s.name" % recipe_id, "artisan", 1, 1, 1)
	recipe.inputs = inputs
	recipe.outputs = outputs
	return recipe


func test_the_real_data_has_fourteen_sites_with_the_documented_recipes_in_each_settlement() -> void:
	var loaded: ProductionLoader.LoadResult = _load()
	assert_eq(loaded.sites.size(), 14, "A tabela aprovada: 5 locais no A, 6 no B e 3 no C.")
	var recipe_ids: Dictionary[String, Array] = {TOWN_A: [], TOWN_B: [], TOWN_C: []}
	for site: SiteDef in loaded.sites:
		assert_true(recipe_ids.has(site.settlement_id), "%s: povoado conhecido." % site.id)
		recipe_ids[site.settlement_id].append(site.recipe_id)
	assert_eq(recipe_ids[TOWN_A], ["grow_grain", "grow_grain", "cut_wood", "mill_flour", "saw_plank"])
	assert_eq(recipe_ids[TOWN_B], ["grow_grain", "grow_grain", "cut_wood", "bake_bread", "weave_fabric", "shear_wool"])
	assert_eq(recipe_ids[TOWN_C], ["mine_ore", "smelt_metal", "forge_tool"])


func test_every_site_has_its_own_work_place_and_a_team_equal_to_the_population_row_that_works_there() -> void:
	var loaded: ProductionLoader.LoadResult = _load()
	var population: PopulationLoader.LoadResult = PopulationLoader.load_dir(POPULATION_DIR)
	assert_true(population.result.ok, population.result.message)
	var team_of_place: Dictionary[String, int] = {}
	for row: PopulationPlan.PopulationRow in population.plan.peek_rows():
		team_of_place[row.work_place_id] = row.count
	var places_seen: Array[String] = []
	var ids_seen: Array[String] = []
	for site: SiteDef in loaded.sites:
		assert_false(places_seen.has(site.place_id), "%s: um local de produção por local de trabalho." % site.id)
		assert_false(ids_seen.has(site.id), "%s: id repetido." % site.id)
		places_seen.append(site.place_id)
		ids_seen.append(site.id)
		assert_eq(team_of_place.get(site.place_id, -1), site.workers_wanted, "%s: a equipe pedida é a da linha de população do local %s." % [site.id, site.place_id])


func test_no_settlement_is_self_sufficient() -> void:
	var loaded: ProductionLoader.LoadResult = _load()
	var missing_by_town: Dictionary[String, Array] = {}
	for settlement_id: String in SETTLEMENTS:
		var missing: Array[String] = _missing(_recipes_of(loaded, settlement_id))
		assert_false(missing.is_empty(), "%s: um povoado que faz tudo o que precisa não tem o que trocar." % settlement_id)
		missing_by_town[settlement_id] = missing
	assert_eq(missing_by_town[TOWN_A], ["bread", "fabric", "tool"], "O A depende de pão, tecido e ferramenta.")
	assert_eq(missing_by_town[TOWN_B], ["flour", "plank", "tool"], "O B tece o próprio tecido e depende de farinha, tábua e ferramenta.")
	assert_eq(missing_by_town[TOWN_C], ["bread", "fabric", "plank", "wood"], "O C depende de pão, tecido, tábua e madeira.")


func test_every_needed_good_has_a_producer() -> void:
	var loaded: ProductionLoader.LoadResult = _load()
	var produced_anywhere: Array[String] = []
	for settlement_id: String in SETTLEMENTS:
		for good_id: String in _produced(_recipes_of(loaded, settlement_id)):
			_add_once(produced_anywhere, good_id)
	for settlement_id: String in SETTLEMENTS:
		for good_id: String in _needed(_recipes_of(loaded, settlement_id)):
			assert_true(produced_anywhere.has(good_id), "%s precisa de %s e nenhum local do mundo o produz." % [settlement_id, good_id])


func test_the_checks_themselves_catch_a_self_sufficient_settlement_and_a_good_nobody_makes() -> void:
	var chain: Array[RecipeDef] = [
		_recipe("grow", {}, {"grain": 1}),
		_recipe("mill", {"grain": 1}, {"flour": 1}),
		_recipe("bake", {"flour": 1}, {"bread": 1}),
	]
	assert_eq(_missing(chain), [] as Array[String], "A cadeia inteira dentro do povoado: ele se basta, e o teste deve acusar.")
	var lonely: Array[RecipeDef] = [_recipe("mill", {"grain": 1}, {"flour": 1})]
	assert_eq(_missing(lonely), ["bread", "grain"] as Array[String], "Sem lavoura e sem padaria faltam o grão e o pão.")
	assert_eq(_produced([] as Array[RecipeDef]), [] as Array[String], "Povoado sem local de produção não produz nada.")
	assert_eq(_needed([] as Array[RecipeDef]), [BREAD_ID] as Array[String], "Sem receita, ainda precisa de comida.")
