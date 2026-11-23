extends GutTest
## LW-094b (PROPOSTA; docs/economia/contrato-lw-094b-regras-de-oferta.md): as regras de oferta no livro de produção, com a economia REAL (data/economy) e um local de `bake_bread` no povoado A (3 por equipe, 2 de salário por hora).
## Regra P: sem a folha inteira o local paga as equipes inteiras que cabem, só elas rodam, e o `WagesPaid` leva a lista dos pagos; nenhuma equipe sem pagamento, nenhum pagamento sem equipe; dinheiro e bens conservados em toda hora.

const SEED: int = 59
const MINUTES_PER_HOUR: int = 60
const SETTLEMENT_A: String = "test_settlement_a"
const PLACE_BREAD: String = "a_work_01"
const SITE_BREAD: int = 4
const WAGE: int = 2
const TEAM: int = 3
const FIRST_WORKER: int = 100
const SITE_KEYS: Array[String] = ["batch_progress_bp", "efficiency_bp", "place_id", "reason", "recipe_id", "settlement_id", "stopped", "upkeep_days", "worker_ids", "workers_wanted"]


func _definitions(site_money: int, wanted: int, max_batches: int) -> EconomyDefinitions:
	var setup: EconomySetup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR)
	assert_true(setup.result.ok, setup.result.message)
	var definitions: EconomyDefinitions = setup.definitions
	var sites: Array[SiteDef] = [SiteDef.new("site_bread", SETTLEMENT_A, PLACE_BREAD, "bake_bread", wanted)]
	definitions.production_sites = sites
	definitions.recipes["bake_bread"].max_batches_per_hour = max_batches
	for kind: OwnerKindDef in definitions.kinds:
		if kind.id == ProductionBook.KIND_SITE:
			kind.initial_balance = site_money
	return definitions


func _world(module: EconomyModule, workers: int) -> World:
	var clock: SimClock = SimClock.new()
	var world: World = World.new(SimContext.new(clock, EventBus.new(clock), WorldRng.new(SEED), IdGenerator.new()))
	assert_true(world.register_module("economy", module).ok)
	world.setup()
	world.post_setup()
	world.on_new_game(SEED)
	for offset: int in workers:
		assert_true(module.request_open_owner(FIRST_WORKER + offset, "npc", PLACE_BREAD).ok)
	return world


func _run_hour(world: World) -> void:
	for _minute: int in MINUTES_PER_HOUR:
		world.context.clock.advance_step()
		world.tick(1)
	world.context.events.dispatch()


func _give_flour(module: EconomyModule, quantity: int) -> void:
	if quantity > 0:
		var market_id: int = module.peek_market_of(SETTLEMENT_A).market_id
		assert_true(module.request_transfer_goods(market_id, SITE_BREAD, "flour", quantity).ok)


func _balances(module: EconomyModule, workers: int) -> Array[int]:
	var money: Array[int] = []
	for offset: int in workers:
		money.append(module.peek_balance(FIRST_WORKER + offset).balance)
	return money


func test_without_the_whole_payroll_the_site_pays_one_team_runs_and_names_the_paid() -> void:
	var module: EconomyModule = EconomyModule.new(false, _definitions(8, 6, 2))
	var world: World = _world(module, 6)
	_give_flour(module, 12)
	var paid: Array[WagesPaid] = []
	world.context.events.subscribe("WagesPaid", func(event: SimEvent) -> void: paid.append(event))
	var before: Array[int] = _balances(module, 6)
	_run_hour(world)
	var site: EconomyReplies.SiteQuery = module.peek_site(SITE_BREAD)
	assert_eq([site.running, site.reason], [true, ""], "8 de saldo não cobrem 12 (6 × 2), mas cobrem uma equipe de 3: o local roda, não é NO_FUNDS.")
	assert_eq(paid.size(), 1, "Um evento por local e hora.")
	assert_eq(paid[0].paid_worker_ids.size(), TEAM, "Só a equipe paga vai na lista.")
	var after: Array[int] = _balances(module, 6)
	var gained: int = 0
	for offset: int in 6:
		var delta: int = after[offset] - before[offset]
		assert_eq(delta, WAGE if paid[0].paid_worker_ids.has(FIRST_WORKER + offset) else 0, "Trabalhador %d: recebe o salário exato só se está na equipe paga." % (FIRST_WORKER + offset))
		gained += delta
	assert_eq(gained, WAGE * TEAM, "O total pago é o salário vezes a equipe.")
	assert_true(module.peek_balance(SITE_BREAD).balance >= 0)
	assert_true(module.peek_conservation().ok and module.peek_goods_conservation().ok)
	world.teardown()


func test_the_paid_team_rotates_with_the_absolute_hour() -> void:
	var definitions: EconomyDefinitions = _definitions(17, 9, 1)
	definitions.is_development_build = true
	var module: EconomyModule = EconomyModule.new(false, definitions)
	var world: World = _world(module, 9)
	assert_true(module.request_set_stock(module.peek_market_of(SETTLEMENT_A).market_id, "bread", 120).ok, "O mercado no teto de compra do pão (60 × 2): sem espaço para pão: o local não vende e não ganha dinheiro.")
	_give_flour(module, 18)
	var paid: Array[WagesPaid] = []
	world.context.events.subscribe("WagesPaid", func(event: SimEvent) -> void: paid.append(event))
	var hours: Array[int] = []
	for _hour: int in 3:
		_run_hour(world)
		hours.append(IntMath.floor_div(world.context.clock.total_minutes(), MINUTES_PER_HOUR))
	assert_eq(paid.size(), 2, "17 pagam uma equipe (6) duas vezes e na terceira hora sobram 5: NO_FUNDS.")
	assert_eq(module.peek_site(SITE_BREAD).reason, ProductionBook.NO_FUNDS)
	var workers: Array[int] = []
	for offset: int in 9:
		workers.append(FIRST_WORKER + offset)
	for index: int in paid.size():
		assert_eq(paid[index].paid_worker_ids, SupplyRules.rotated_team(workers, hours[index], TEAM), "Hora %d: a equipe paga é a da rotação pela hora absoluta." % hours[index])
	assert_ne(paid[0].paid_worker_ids, paid[1].paid_worker_ids, "Horas diferentes, equipes diferentes.")
	assert_eq(module.peek_balance(SITE_BREAD).balance, 17 - 2 * WAGE * TEAM)
	assert_true(module.peek_conservation().ok and module.peek_goods_conservation().ok)
	world.teardown()


func test_random_scenarios_keep_money_goods_and_pay_exactly_the_teams_that_ran() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 94
	var partial_hours: int = 0
	var full_hours: int = 0
	var stopped_hours: int = 0
	for scenario: int in 10:
		var workers: int = rng.randi_range(3, 9)
		var max_batches: int = rng.randi_range(1, 3)
		var module: EconomyModule = EconomyModule.new(false, _definitions(rng.randi_range(4, 30), workers, max_batches))
		var world: World = _world(module, workers)
		_give_flour(module, rng.randi_range(0, 18))
		var paid: Array[WagesPaid] = []
		world.context.events.subscribe("WagesPaid", func(event: SimEvent) -> void: paid.append(event))
		var teams: int = mini(max_batches, IntMath.floor_div(workers, TEAM))
		for hour: int in 24:
			paid.clear()
			module.request_transfer_goods(module.peek_market_of(SETTLEMENT_A).market_id, SITE_BREAD, "flour", rng.randi_range(1, 9))
			var before: Array[int] = _balances(module, workers)
			_run_hour(world)
			var after: Array[int] = _balances(module, workers)
			var label: String = "Cenário %d (%d trabalhadores, %d lotes), hora %d" % [scenario, workers, max_batches, hour]
			var running: bool = module.peek_site(SITE_BREAD).running
			assert_eq(paid.size(), 1 if running else 0, "%s: há folha exatamente quando o local roda." % label)
			var listed: Array[int] = []
			if not paid.is_empty():
				listed = paid[0].paid_worker_ids
			if paid.is_empty():
				stopped_hours += 1
			elif listed.size() < workers:
				partial_hours += 1
			else:
				full_hours += 1
			assert_true(listed.size() == workers or (listed.size() % TEAM == 0 and listed.size() <= teams * TEAM), "%s: pagos = todos (folha cheia) ou equipes inteiras." % label)
			for offset: int in workers:
				assert_eq(after[offset] - before[offset], WAGE if listed.has(FIRST_WORKER + offset) else 0, "%s: trabalhador %d." % [label, FIRST_WORKER + offset])
				assert_true(after[offset] >= 0)
			assert_true(module.peek_balance(SITE_BREAD).balance >= 0, "%s: saldo do local nunca negativo." % label)
			assert_true(module.peek_conservation().ok and module.peek_goods_conservation().ok, "%s: dinheiro e bens conservados." % label)
		world.teardown()
	gut.p("Horas: folha cheia %d, parcial %d, paradas %d." % [full_hours, partial_hours, stopped_hours])
	assert_true(partial_hours > 0 and full_hours > 0 and stopped_hours > 0, "Os cenários passam pelos três casos (cheia, parcial e parada).")


func test_the_save_keys_of_the_production_book_do_not_change() -> void:
	var module: EconomyModule = EconomyModule.new(false, _definitions(8, 6, 2))
	var world: World = _world(module, 6)
	_give_flour(module, 6)
	for _hour: int in 3:
		_run_hour(world)
	var production: Dictionary = module.serialize()["production"]
	assert_eq(production.keys(), ["sites"], "O bloco `production` só tem os locais.")
	var site: Dictionary = (production["sites"] as Dictionary).values()[0]
	var keys: Array[String] = []
	keys.assign(site.keys())
	keys.sort()
	assert_eq(keys, SITE_KEYS, "Nenhuma chave nova no local: a rotação vem só da hora do relógio.")
	world.teardown()
