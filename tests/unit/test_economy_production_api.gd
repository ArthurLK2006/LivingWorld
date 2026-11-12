extends GutTest
## LW-092c: os locais de produção ligados ao `EconomyModule` (docs/modules/economy.md, seções 6, 8 e 10): criados no jogo novo a partir de `production_sites.json` (aqui injetados nas definições, porque a lista real é da LW-097), com a hora de
## produção a cada hora cheia do relógio e o fim do dia depois dos mercados; os trabalhadores entram quando o NPC abre a conta com o `work_place_id` e saem no `NpcDied`; a porta `peek_site`, `peek_site_at` e `peek_sites_of`; os eventos só na
## mudança de estado; e o bloco `production` do save, com a ida e volta e a recusa de bloco inválido sem mudar nada. Usa os dados REAIS (data/economy): dois locais no povoado A, `bake_bread` (3 trabalhadores por lote, insumo `flour`;
## manutenção de `tool` a cada 10 dias, `plank` a cada 5 e `fabric` a cada 10) e `mill_flour`. Os mercados A, B e C (LW-097) levam os IDs 1 a 3 e os locais, 4 e 5.

const SEED: int = 53
const MINUTES_PER_HOUR: int = 60
const MINUTES_PER_DAY: int = 1440
const SETTLEMENT_A: String = "test_settlement_a"
const PLACE_BREAD: String = "a_work_01"
const PLACE_MILL: String = "a_work_02"
const MARKET_A: int = 1
const SITE_BREAD: int = 4
const SITE_MILL: int = 5
const WORKERS: Array[int] = [100, 101, 102]


## `site_money`: o saldo inicial do tipo `site` (alto, para o local não ficar sem dinheiro nas contas dos testes).
func _definitions(site_money: int = 5000, with_mill: bool = true) -> EconomyDefinitions:
	var setup: EconomySetup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR)
	assert_true(setup.result.ok, setup.result.message)
	var definitions: EconomyDefinitions = setup.definitions
	var sites: Array[SiteDef] = [SiteDef.new("site_bread", SETTLEMENT_A, PLACE_BREAD, "bake_bread", 4)]
	if with_mill:
		sites.append(SiteDef.new("site_mill", SETTLEMENT_A, PLACE_MILL, "mill_flour", 4))
	definitions.production_sites = sites
	for kind: OwnerKindDef in definitions.kinds:
		if kind.id == ProductionBook.KIND_SITE:
			kind.initial_balance = site_money
	return definitions


func _world(module: EconomyModule) -> World:
	var clock: SimClock = SimClock.new()
	var world: World = World.new(SimContext.new(clock, EventBus.new(clock), WorldRng.new(SEED), IdGenerator.new()))
	assert_true(world.register_module("economy", module).ok)
	world.setup()
	world.post_setup()
	world.on_new_game(SEED)
	return world


func _run_minutes(world: World, minutes: int) -> void:
	for _minute: int in minutes:
		world.context.clock.advance_step()
		world.tick(1)
	world.context.events.dispatch()


func _staff(module: EconomyModule, place_id: String = PLACE_BREAD) -> void:
	for npc_id: int in WORKERS:
		assert_true(module.request_open_owner(npc_id, "npc", place_id).ok)


func _through_json(data: Dictionary) -> Dictionary:
	# Variant: o JSON devolve qualquer tipo; aqui o formato é conhecido (um objeto).
	var parsed: Variant = JSON.parse_string(JSON.stringify(data))
	assert_eq(typeof(parsed), TYPE_DICTIONARY)
	var copy: Dictionary = parsed
	return copy


func test_a_new_game_opens_the_funded_sites_and_the_door_shows_them() -> void:
	var module: EconomyModule = EconomyModule.new(false, _definitions())
	var world: World = _world(module)
	var site: EconomyReplies.SiteQuery = module.peek_site(SITE_BREAD)
	assert_true(site.result.ok, site.result.message)
	assert_eq([site.workplace_id, site.place_id, site.settlement_id, site.recipe_id, site.occupation_id, site.wage_per_hour, site.workers_wanted, site.workers_assigned], [SITE_BREAD, PLACE_BREAD, SETTLEMENT_A, "bake_bread", "artisan", 2, 4, 0])
	assert_eq([site.running, site.reason, site.efficiency_bp, site.batch_progress_bp, site.worker_ids, site.stock], [true, "", 10000, 0, [] as Array[int], [] as Array[Dictionary]], "Nasce produzindo, com eficiência cheia, sem equipe e sem estoque.")
	assert_eq(site.upkeep, [{"good_id": "tool", "quantity": 1, "period_days": 10, "days_since_paid": 0}, {"good_id": "plank", "quantity": 1, "period_days": 5, "days_since_paid": 0}, {"good_id": "fabric", "quantity": 1, "period_days": 10, "days_since_paid": 0}] as Array[Dictionary])
	assert_eq([module.peek_site_at(PLACE_MILL).workplace_id, module.peek_site_at(PLACE_MILL).recipe_id], [SITE_MILL, "mill_flour"])
	assert_eq([module.peek_sites_of(SETTLEMENT_A).sites.size(), module.peek_sites_of("test_settlement_b").sites.size()], [2, 0])
	assert_eq([module.peek_sites_of(SETTLEMENT_A).sites[0].workplace_id, module.peek_sites_of(SETTLEMENT_A).sites[1].workplace_id], [SITE_BREAD, SITE_MILL], "Por ID crescente.")
	assert_eq([module.peek_balance(SITE_BREAD).balance, module.peek_balance(SITE_MILL).balance], [5000, 5000], "O saldo inicial do tipo `site`.")
	var conservation: EconomyReplies.ConservationQuery = module.peek_conservation()
	assert_eq([conservation.sum, conservation.created, conservation.ok], [19000, 19000, true], "Dinheiro criado só por `game_start`: 3 mercados e 2 locais.")
	assert_eq([module.peek_site(99).result.code, module.peek_site_at("nowhere").result.code, module.peek_site(MARKET_A).result.code], [EconomyCodes.UNKNOWN_OWNER, EconomyCodes.UNKNOWN_OWNER, EconomyCodes.UNKNOWN_OWNER], "Quem não é local de produção não aparece.")
	assert_eq(module.validate(), [] as Array[String])
	assert_eq(world.validate(), [] as Array[String])
	world.teardown()


func test_a_npc_joins_the_site_when_the_account_opens_and_leaves_it_when_it_dies() -> void:
	var module: EconomyModule = EconomyModule.new(false, _definitions())
	var world: World = _world(module)
	_staff(module)
	assert_true(module.request_open_owner(103, "npc", PLACE_MILL).ok)
	assert_true(module.request_open_owner(104, "npc", "a_work_03").ok, "Local sem local de produção: a conta abre e ninguém é atribuído.")
	assert_true(module.request_open_owner(105, "player", PLACE_BREAD).ok, "Só o tipo `npc` é atribuído.")
	assert_true(module.request_open_owner(106, "npc").ok, "Sem `work_place_id` também vale.")
	assert_eq([module.peek_site(SITE_BREAD).worker_ids, module.peek_site(SITE_BREAD).workers_assigned, module.peek_site(SITE_MILL).worker_ids], [WORKERS, 3, [103] as Array[int]])
	assert_true(module.request_open_owner(100, "npc", PLACE_MILL).ok, "Abrir de novo é idempotente e não muda o emprego (um trabalho, um pagamento).")
	assert_eq([module.peek_site(SITE_BREAD).worker_ids, module.peek_site(SITE_MILL).worker_ids], [WORKERS, [103] as Array[int]])
	world.context.events.publish(NpcDied.new(101, "hunger", 1))
	world.context.events.publish(NpcDied.new(999, "hunger", 1))
	world.context.events.dispatch()
	assert_eq(module.peek_site(SITE_BREAD).worker_ids, [100, 102] as Array[int], "O NPC morto sai da equipe; quem nunca foi atribuído não é erro.")
	assert_eq(module.peek_balance(101).result.ok, true, "A conta do morto continua para consulta.")
	assert_eq(module.validate(), [] as Array[String])
	world.teardown()


func test_the_site_works_every_hour_of_the_clock_and_the_events_come_only_on_the_change() -> void:
	var module: EconomyModule = EconomyModule.new(false, _definitions(5000, false))
	var world: World = _world(module)
	var stopped: Array[ProductionStopped] = []
	var resumed: Array[ProductionResumed] = []
	world.context.events.subscribe("ProductionStopped", func(event: SimEvent) -> void: stopped.append(event))
	world.context.events.subscribe("ProductionResumed", func(event: SimEvent) -> void: resumed.append(event))
	_run_minutes(world, MINUTES_PER_HOUR - 1)
	assert_eq([stopped.size(), module.peek_stock(MARKET_A, "bread").value], [0, 60], "Antes da hora cheia nada acontece.")
	_run_minutes(world, 1)
	assert_eq(stopped.size(), 1, "Na primeira hora cheia o local para por falta de equipe.")
	assert_eq([stopped[0].site_id, stopped[0].settlement_id, stopped[0].recipe_id, stopped[0].reason], [SITE_BREAD, SETTLEMENT_A, "bake_bread", ProductionBook.NO_WORKER])
	assert_eq([module.peek_site(SITE_BREAD).running, module.peek_site(SITE_BREAD).reason], [false, ProductionBook.NO_WORKER])
	_run_minutes(world, MINUTES_PER_HOUR)
	assert_eq([stopped.size(), resumed.size()], [1, 0], "Continuar parado não publica de novo.")
	_staff(module)
	_run_minutes(world, MINUTES_PER_HOUR)
	assert_eq(resumed.size(), 1, "Com a equipe, o local volta a produzir: um evento.")
	assert_eq([resumed[0].site_id, resumed[0].settlement_id, resumed[0].recipe_id], [SITE_BREAD, SETTLEMENT_A, "bake_bread"])
	assert_eq([module.peek_stock(MARKET_A, "flour").value, module.peek_stock(MARKET_A, "bread").value], [34, 66], "Um lote: o local comprou 6 de farinha e vendeu 6 de pão ao mercado.")
	assert_eq([module.peek_site(SITE_BREAD).running, module.peek_site(SITE_BREAD).stock], [true, [] as Array[Dictionary]])
	_run_minutes(world, MINUTES_PER_HOUR * 3)
	assert_eq([module.peek_stock(MARKET_A, "flour").value, module.peek_stock(MARKET_A, "bread").value], [16, 84], "Mais três lotes, uma hora cada.")
	assert_true(module.peek_goods_conservation().ok and module.peek_conservation().ok, "Nada é criado nem destruído de graça.")
	world.teardown()


func test_the_end_of_the_day_pays_the_maintenance_and_the_efficiency_steps_down_and_up() -> void:
	var module: EconomyModule = EconomyModule.new(false, _definitions(5000, false))
	var world: World = _world(module)
	_staff(module)
	_run_minutes(world, MINUTES_PER_DAY * 5)
	var fifth: EconomyReplies.SiteQuery = module.peek_site(SITE_BREAD)
	assert_eq([fifth.efficiency_bp, fifth.upkeep[1]["days_since_paid"], fifth.upkeep[0]["days_since_paid"]], [9000, 5, 5], "No 5º dia as tábuas (a cada 5 dias) vencem sem estar no inventário: a eficiência cai um degrau.")
	_run_minutes(world, MINUTES_PER_DAY)
	var sixth: EconomyReplies.SiteQuery = module.peek_site(SITE_BREAD)
	assert_eq([sixth.efficiency_bp, sixth.upkeep[1]["days_since_paid"], sixth.upkeep[0]["days_since_paid"]], [10000, 0, 6], "No 6º dia o local comprou a tábua, pagou a manutenção no fim do dia e a eficiência voltou.")
	assert_eq(module.peek_stock(MARKET_A, "plank").value, 29, "A tábua veio do mercado.")
	var plank: Array[Dictionary] = module.peek_goods_conservation().rows.filter(func(row: Dictionary) -> bool: return row["good_id"] == "plank")
	assert_eq([plank[0]["created"], plank[0]["destroyed"], plank[0]["ok"]], [66, 1, true], "As 66 tábuas são o estoque inicial dos três mercados (30, 21 e 15); a do local foi destruída com o motivo `maintenance` e a conservação fecha.")
	assert_true(module.peek_conservation().ok)
	assert_eq(module.validate(), [] as Array[String])
	world.teardown()


func test_the_day_closes_exactly_when_the_clock_turns_the_day_and_not_before() -> void:
	var module: EconomyModule = EconomyModule.new(false, _definitions(5000, false))
	var world: World = _world(module)
	_run_minutes(world, MINUTES_PER_DAY - 1)
	assert_eq(module.peek_site(SITE_BREAD).upkeep[0]["days_since_paid"], 0, "Um minuto antes da virada o dia ainda não fechou.")
	_run_minutes(world, 1)
	assert_eq(module.peek_site(SITE_BREAD).upkeep[0]["days_since_paid"], 1, "Na virada o dia fecha, uma vez.")
	_run_minutes(world, MINUTES_PER_DAY)
	assert_eq(module.peek_site(SITE_BREAD).upkeep[0]["days_since_paid"], 2, "E de novo na virada seguinte.")
	world.teardown()


func test_the_sites_survive_the_save_and_a_bad_block_changes_nothing() -> void:
	var module: EconomyModule = EconomyModule.new(false, _definitions())
	var world: World = _world(module)
	_staff(module)
	_run_minutes(world, MINUTES_PER_DAY * 2)
	var saved: Dictionary = _through_json(module.serialize())
	assert_true(saved.has("production"))
	var restored: EconomyModule = EconomyModule.new(false, _definitions())
	var loaded: Result = restored.on_load(saved)
	assert_true(loaded.ok, loaded.message)
	assert_eq(_through_json(restored.serialize()), saved, "Ida e volta pelo JSON.")
	assert_eq([restored.peek_site(SITE_BREAD).worker_ids, restored.peek_site(SITE_BREAD).efficiency_bp, restored.peek_site(SITE_BREAD).stock], [module.peek_site(SITE_BREAD).worker_ids, module.peek_site(SITE_BREAD).efficiency_bp, module.peek_site(SITE_BREAD).stock])
	assert_eq(restored.validate(), [] as Array[String])
	var site_entry: Dictionary = (saved["production"] as Dictionary)["sites"]["4"]
	var cases: Array[Dictionary] = [
		{"label": "campo ausente", "mutate": func(block: Dictionary) -> void: block["production"] = {"other": 1}, "fragment": "campo 'sites' ausente"},
		{"label": "dono que não é local", "mutate": func(block: Dictionary) -> void: block["production"]["sites"] = {"1": site_entry.duplicate(true)}, "fragment": "o ID de um dono do tipo 'site'"},
		{"label": "receita desconhecida", "mutate": func(block: Dictionary) -> void: block["production"]["sites"]["4"]["recipe_id"] = "no_such_recipe", "fragment": "o id de uma receita"},
		{"label": "eficiência abaixo do piso", "mutate": func(block: Dictionary) -> void: block["production"]["sites"]["4"]["efficiency_bp"] = 100, "fragment": "'efficiency_bp' de 3000 a 10000"},
		{"label": "progresso de um lote inteiro", "mutate": func(block: Dictionary) -> void: block["production"]["sites"]["4"]["batch_progress_bp"] = 10000, "fragment": "'batch_progress_bp' de 0 a 9999"},
		{"label": "parado sem motivo", "mutate": func(block: Dictionary) -> void: block["production"]["sites"]["4"]["stopped"] = true; block["production"]["sites"]["4"]["reason"] = "", "fragment": "um motivo de NO_WORKER, NO_INPUT, OUTPUT_FULL, NO_FUNDS só quando parado"},
		{"label": "motivo fora do conjunto", "mutate": func(block: Dictionary) -> void: block["production"]["sites"]["4"]["stopped"] = true; block["production"]["sites"]["4"]["reason"] = "NO_SPACE", "fragment": "um motivo de NO_WORKER"},
		{"label": "equipe fora de ordem", "mutate": func(block: Dictionary) -> void: block["production"]["sites"]["4"]["worker_ids"] = [102, 100], "fragment": "em ordem crescente e sem repetição"},
		{"label": "manutenção que não é a da receita", "mutate": func(block: Dictionary) -> void: block["production"]["sites"]["4"]["upkeep_days"] = {"tool": 1}, "fragment": "exatamente as 3 regras de manutenção"},
		{"label": "dias de manutenção negativos", "mutate": func(block: Dictionary) -> void: block["production"]["sites"]["4"]["upkeep_days"]["tool"] = -1, "fragment": "um inteiro de 0 ou mais para 'tool'"},
		{"label": "equipe desejada zero", "mutate": func(block: Dictionary) -> void: block["production"]["sites"]["4"]["workers_wanted"] = 0, "fragment": "'workers_wanted' deve ser 1 ou mais"},
		{"label": "eficiência acima de 10000", "mutate": func(block: Dictionary) -> void: block["production"]["sites"]["4"]["efficiency_bp"] = 10001, "fragment": "'efficiency_bp' de 3000 a 10000"},
		{"label": "equipe com ID zero", "mutate": func(block: Dictionary) -> void: block["production"]["sites"]["4"]["worker_ids"] = [0, 102], "fragment": "IDs inteiros positivos"},
		{"label": "local sem nome", "mutate": func(block: Dictionary) -> void: block["production"]["sites"]["4"]["place_id"] = "", "fragment": "'place_id' deve ser texto não vazio"},
		{"label": "produzindo com motivo", "mutate": func(block: Dictionary) -> void: block["production"]["sites"]["4"]["stopped"] = false; block["production"]["sites"]["4"]["reason"] = "NO_INPUT", "fragment": "só quando parado"},
		{"label": "produzindo com motivo qualquer", "mutate": func(block: Dictionary) -> void: block["production"]["sites"]["4"]["stopped"] = false; block["production"]["sites"]["4"]["reason"] = "x", "fragment": "só quando parado"},
		{"label": "dois locais de produção no mesmo local", "mutate": func(block: Dictionary) -> void: block["production"]["sites"]["5"]["place_id"] = PLACE_BREAD, "fragment": "já tem um local de produção"},
	]
	var before: Dictionary = restored.serialize()
	for test_case: Dictionary in cases:
		var block: Dictionary = saved.duplicate(true)
		var mutate: Callable = test_case["mutate"]
		mutate.call(block)
		var result: Result = restored.on_load(block)
		assert_false(result.ok, "%s: deveria falhar." % test_case["label"])
		assert_eq(result.code, EconomyCodes.INVALID_SAVE, test_case["label"])
		assert_string_contains(result.message, test_case["fragment"], test_case["label"])
		assert_eq(restored.serialize(), before, "%s: o módulo continua como estava." % test_case["label"])
	var without_recipes: EconomyDefinitions = _definitions()
	without_recipes.recipes = {}
	var bare: Result = EconomyModule.new(false, without_recipes).on_load(saved)
	assert_eq(bare.code, EconomyCodes.INVALID_SAVE, "Um save com locais de produção num módulo sem receitas é recusado.")
	assert_string_contains(bare.message, "locais de produção")
	world.teardown()


func test_without_sites_in_the_data_nothing_changes_and_validate_finds_a_site_that_lost_its_owner() -> void:
	var setup: EconomySetup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR)
	assert_true(setup.result.ok, setup.result.message)
	var no_sites: Array[SiteDef] = []
	setup.definitions.production_sites = no_sites
	var module: EconomyModule = EconomyModule.new(false, setup.definitions)
	var world: World = _world(module)
	_run_minutes(world, MINUTES_PER_DAY * 2)
	assert_eq([module.peek_sites_of(SETTLEMENT_A).sites.size(), module.serialize().has("production"), world.context.ids.next_id()], [0, false, 4], "Sem locais nos dados: o jogo só gasta os IDs dos três mercados e o save não ganha o bloco.")
	world.teardown()
	var real_setup: EconomySetup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR)
	assert_true(real_setup.result.ok, real_setup.result.message)
	var real_module: EconomyModule = EconomyModule.new(false, real_setup.definitions)
	var real_world: World = _world(real_module)
	_run_minutes(real_world, MINUTES_PER_DAY * 2)
	assert_eq([real_module.peek_sites_of(SETTLEMENT_A).sites.size(), real_module.serialize().has("production"), real_world.context.ids.next_id()], [5, true, 32], "A lista real de locais (LW-097) tem 5 no A: 3 mercados, 14 locais e as 14 vagas que a economia posta (LW-096e) gastam 31 IDs e o save ganha o bloco.")
	assert_eq(real_module.validate(), [] as Array[String])
	real_world.teardown()
	var loaded: ProductionLoader.LoadResult = ProductionLoader.load_dir(GoodsLoader.DEFAULT_DIR)
	var book: OwnerBook = OwnerBook.new()
	assert_true(book.open_owner(5, ProductionBook.KIND_SITE).ok)
	var production: ProductionBook = ProductionBook.new(book, null, null, null, loaded.recipes, loaded.params, 50)
	assert_true(production.register_site(5, SiteDef.new("site_bread", SETTLEMENT_A, PLACE_BREAD, "bake_bread", 4)).ok)
	assert_eq(production.validate(), [] as Array[String])
	var owners: Dictionary = book.serialize()
	owners["5"][OwnerBook.KEY_KIND] = "npc"
	assert_true(book.load_from(owners).ok)
	var problems: Array[String] = production.validate()
	assert_eq(problems.size(), 1)
	assert_string_contains(problems[0], "o local de produção 5 não é um dono do tipo 'site'")
