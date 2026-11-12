extends GutTest
## LW-097e: o estoque inicial de 30 dias dos mercados (DEC-176; docs/economy/dados.md, "Estoque inicial até o comerciante"). O comerciante só chega na LW-098, então o que um povoado importa vem do
## `initial_stock` do próprio mercado. Para cada bem que NÃO é comida e que o povoado NÃO produz, o estoque inicial cobre 30 dias do consumo: soma, nos locais do povoado, da manutenção (`quantity` ÷
## `period_days`) e dos insumos (`quantity` × lotes por hora × horas de trabalho por dia), com os lotes por hora = o menor entre o teto da receita e a equipe ÷ trabalhadores por lote, e as horas de
## trabalho tiradas da agenda do ofício esperado da receita (a conta de 24 h por dia do rascunho era impossível: passava de 5.000 de peso). Tudo em inteiros, arredondado para cima. A comida não tem
## teste de dados: quem prova é o soak de 30 dias sem morte. Os valores esperados são escritos à mão a partir de data/economy/site_upkeep.json e recipe_inputs.json.

const DATA_DIR: String = "res://data/economy"
const ROUTINE_DIR: String = "res://data"
const DAYS: int = 30
const WORK_ACTION_ID: String = "work"
const FOOD_CATEGORY: String = "food"
## Múltiplo comum dos períodos de manutenção (hoje 3, 4, 5, 10 e 20 dias; divisível também por 1 a 10, 12, 14, 15, 18, 21, 24 e 30): a manutenção vira inteiro exato antes de arredondar a soma. Um
## período novo que não divida este número faz o teste falhar com mensagem clara, e a constante sobe.
const PERIOD_LCM: int = 2520
const TOWN_A: String = "test_settlement_a"
const TOWN_B: String = "test_settlement_b"
const TOWN_C: String = "test_settlement_c"
const SETTLEMENTS: Array[String] = [TOWN_A, TOWN_B, TOWN_C]


func _production() -> ProductionLoader.LoadResult:
	var loaded: ProductionLoader.LoadResult = ProductionLoader.load_dir(DATA_DIR)
	assert_true(loaded.result.ok, loaded.result.message)
	return loaded


## Horas por dia em que o ofício está na ação de trabalho, lidas da agenda (data/routine_blocks.json).
func _work_hours(occupation_ids: Array[String]) -> Dictionary[String, int]:
	var routine: RoutineLoader.LoadResult = RoutineLoader.load_dir(ROUTINE_DIR)
	assert_true(routine.result.ok, routine.result.message)
	var hours: Dictionary[String, int] = {}
	for occupation_id: String in occupation_ids:
		var worked: int = 0
		for hour: int in range(RoutineTable.HOURS_PER_DAY):
			var query: RoutineTable.RoutineQuery = routine.table.peek_action(occupation_id, hour)
			if query.result.ok and query.action_id == WORK_ACTION_ID:
				worked += 1
		hours[occupation_id] = worked
	return hours


func _occupations_of(recipes: Dictionary[String, RecipeDef]) -> Array[String]:
	var occupations: Array[String] = []
	for recipe_id: String in recipes:
		var occupation_id: String = recipes[recipe_id].occupation_id
		if not occupations.has(occupation_id):
			occupations.append(occupation_id)
	return occupations


## O consumo de 30 dias, por bem, dos locais dados (soma antes de arredondar para cima).
func _need_for_30_days(sites: Array[SiteDef], recipes: Dictionary[String, RecipeDef], work_hours: Dictionary[String, int]) -> Dictionary[String, int]:
	var scaled: Dictionary[String, int] = {}
	for site: SiteDef in sites:
		var recipe: RecipeDef = recipes[site.recipe_id]
		var batches_per_hour: int = mini(recipe.max_batches_per_hour, IntMath.floor_div(site.workers_wanted, recipe.workers_per_batch))
		for good_id: String in recipe.inputs:
			scaled[good_id] = int(scaled.get(good_id, 0)) + recipe.inputs[good_id] * batches_per_hour * work_hours[recipe.occupation_id] * DAYS * PERIOD_LCM
		for rule: UpkeepRule in recipe.upkeep:
			assert_true(rule.period_days >= 1 and PERIOD_LCM % rule.period_days == 0, "%s/%s: o período de %d dias não divide %d; suba PERIOD_LCM." % [recipe.id, rule.good_id, rule.period_days, PERIOD_LCM])
			scaled[rule.good_id] = int(scaled.get(rule.good_id, 0)) + rule.quantity * DAYS * IntMath.floor_div(PERIOD_LCM, rule.period_days)
	var needed: Dictionary[String, int] = {}
	for good_id: String in scaled:
		needed[good_id] = -IntMath.floor_div(-int(scaled[good_id]), PERIOD_LCM)
	return needed


func _sites_of(loaded: ProductionLoader.LoadResult, settlement_id: String) -> Array[SiteDef]:
	var sites: Array[SiteDef] = []
	for site: SiteDef in loaded.sites:
		if site.settlement_id == settlement_id:
			sites.append(site)
	return sites


func _produced_by(sites: Array[SiteDef], recipes: Dictionary[String, RecipeDef]) -> Array[String]:
	var produced: Array[String] = []
	for site: SiteDef in sites:
		for good_id: String in recipes[site.recipe_id].outputs:
			if not produced.has(good_id):
				produced.append(good_id)
	return produced


## O que o povoado importa e que não é comida: bem -> consumo de 30 dias.
func _imports(sites: Array[SiteDef], recipes: Dictionary[String, RecipeDef], work_hours: Dictionary[String, int], categories: Dictionary[String, String]) -> Dictionary[String, int]:
	var produced: Array[String] = _produced_by(sites, recipes)
	var imports: Dictionary[String, int] = {}
	var needed: Dictionary[String, int] = _need_for_30_days(sites, recipes, work_hours)
	for good_id: String in needed:
		if not produced.has(good_id) and categories[good_id] != FOOD_CATEGORY:
			imports[good_id] = needed[good_id]
	return imports


func _categories() -> Dictionary[String, String]:
	var goods: GoodsLoader.LoadResult = GoodsLoader.load_dir(DATA_DIR)
	assert_true(goods.result.ok, goods.result.message)
	var categories: Dictionary[String, String] = {}
	for good: GoodDef in goods.goods:
		categories[good.id] = good.category
	return categories


func _initial_stocks() -> Dictionary[String, int]:
	var markets: MarketLoader.LoadResult = MarketLoader.load_dir(DATA_DIR)
	assert_true(markets.result.ok, markets.result.message)
	var stocks: Dictionary[String, int] = {}
	for target: MarketTargetDef in markets.targets:
		stocks["%s/%s" % [target.settlement_id, target.good_id]] = target.initial_stock
	return stocks


## Os bens importados cujo estoque inicial não cobre o consumo de 30 dias (ou que nem têm linha no mercado), como "povoado/bem".
func _shortages(settlement_id: String, imports: Dictionary[String, int], stocks: Dictionary[String, int]) -> Array[String]:
	var short: Array[String] = []
	for good_id: String in imports:
		var key: String = "%s/%s" % [settlement_id, good_id]
		if int(stocks.get(key, -1)) < imports[good_id]:
			short.append(key)
	short.sort()
	return short


func test_initial_stock_covers_30_days() -> void:
	var loaded: ProductionLoader.LoadResult = _production()
	var work_hours: Dictionary[String, int] = _work_hours(_occupations_of(loaded.recipes))
	var categories: Dictionary[String, String] = _categories()
	var stocks: Dictionary[String, int] = _initial_stocks()
	var checked: int = 0
	for settlement_id: String in SETTLEMENTS:
		var imports: Dictionary[String, int] = _imports(_sites_of(loaded, settlement_id), loaded.recipes, work_hours, categories)
		assert_eq(_shortages(settlement_id, imports, stocks), [] as Array[String], "%s: todo bem importado tem linha no mercado e estoque inicial para 30 dias." % settlement_id)
		checked += imports.size()
	assert_eq(checked, 8, "Os bens importados e que não são comida: A (2), B (3) e C (3).")


func test_the_thirty_day_needs_of_the_real_data_match_the_hand_made_table() -> void:
	var loaded: ProductionLoader.LoadResult = _production()
	var work_hours: Dictionary[String, int] = _work_hours(_occupations_of(loaded.recipes))
	var categories: Dictionary[String, String] = _categories()
	assert_eq(_imports(_sites_of(loaded, TOWN_A), loaded.recipes, work_hours, categories), {"fabric": 25, "tool": 29} as Dictionary[String, int], "O A importa tecido e ferramenta.")
	assert_eq(_imports(_sites_of(loaded, TOWN_B), loaded.recipes, work_hours, categories), {"flour": 1620, "plank": 21, "tool": 29} as Dictionary[String, int], "O B importa farinha, tábua e ferramenta (tece o próprio tecido).")
	assert_eq(_imports(_sites_of(loaded, TOWN_C), loaded.recipes, work_hours, categories), {"fabric": 9, "plank": 15, "wood": 540} as Dictionary[String, int], "O C importa tecido, tábua e madeira.")
	assert_eq([work_hours["farmer"], work_hours["lumberjack"], work_hours["artisan"]], [10, 9, 9], "As horas de trabalho vêm da agenda: lavrador 10, lenhador 9 e artesão 9.")


func test_the_comparison_catches_a_stock_that_is_one_unit_short_and_the_sum_is_rounded_up_once() -> void:
	var recipe: RecipeDef = RecipeDef.new("r", "recipe.r.name", "artisan", 3, 1, 1)
	recipe.upkeep = [UpkeepRule.new("tool", 1, 4), UpkeepRule.new("tool", 1, 5), UpkeepRule.new("fabric", 1, 10)]
	var recipes: Dictionary[String, RecipeDef] = {"r": recipe}
	var sites: Array[SiteDef] = [SiteDef.new("s1", "t", "p1", "r", 3), SiteDef.new("s2", "t", "p2", "r", 3)]
	var needed: Dictionary[String, int] = _need_for_30_days(sites, recipes, {"artisan": 9})
	assert_eq(needed, {"tool": 27, "fabric": 6} as Dictionary[String, int], "Dois locais: tool = 2 × (7,5 + 6) = 27 e fabric = 2 × 3 = 6.")
	var single: Array[SiteDef] = [SiteDef.new("s1", "t", "p1", "r", 3)]
	var rounded: Dictionary[String, int] = _need_for_30_days(single, recipes, {"artisan": 9})
	assert_eq(rounded, {"tool": 14, "fabric": 3} as Dictionary[String, int], "Um local: 13,5 de ferramenta sobe para 14 (a soma dos dois períodos é arredondada uma vez só).")
	assert_eq(_shortages("t", needed, {"t/tool": 27, "t/fabric": 6}), [] as Array[String], "Estoque igual ao consumo cobre.")
	assert_eq(_shortages("t", needed, {"t/tool": 26, "t/fabric": 6}), ["t/tool"] as Array[String], "Uma unidade a menos não cobre os 30 dias.")
	assert_eq(_shortages("t", needed, {"t/tool": 27}), ["t/fabric"] as Array[String], "Bem importado sem linha no mercado também é falta.")


func test_the_batches_per_hour_follow_the_team_and_the_recipe_cap_and_the_inputs_use_the_work_hours() -> void:
	var recipe: RecipeDef = RecipeDef.new("r", "recipe.r.name", "artisan", 3, 2, 1)
	recipe.inputs = {"flour": 6}
	var recipes: Dictionary[String, RecipeDef] = {"r": recipe}
	var small_team: Array[SiteDef] = [SiteDef.new("s1", "t", "p1", "r", 4)]
	var big_team: Array[SiteDef] = [SiteDef.new("s1", "t", "p1", "r", 9)]
	assert_eq(_need_for_30_days(small_team, recipes, {"artisan": 9}), {"flour": 6 * 1 * 9 * 30} as Dictionary[String, int], "Equipe de 4 e lote de 3: 1 lote por hora.")
	assert_eq(_need_for_30_days(big_team, recipes, {"artisan": 9}), {"flour": 6 * 2 * 9 * 30} as Dictionary[String, int], "Equipe de 9 daria 3 lotes, mas o teto da receita é 2.")
	assert_eq(_need_for_30_days(small_team, recipes, {"artisan": 0}), {"flour": 0} as Dictionary[String, int], "Sem hora de trabalho não há consumo de insumo.")
