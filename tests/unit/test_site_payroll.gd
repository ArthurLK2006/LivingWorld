extends GutTest
## LW-095 (parte a): a folha de pagamento dos locais de produção (docs/modules/economy.md, seção 6, DEC-151 e DEC-152). Economia REAL (data/economy) com um local de `bake_bread` no povoado A (3 trabalhadores por lote, 2 de salário por hora
## cada um) e NPCs reais abertos pela porta (saldo inicial 60). A cada hora em que o local produz ele paga `wage_per_hour` a cada trabalhador atribuído, pela conta dele (`Ledger`, motivo `salary`), tudo ou nada, e anuncia UM `WagesPaid`
## por hora; sem o dinheiro da folha inteira o local para por `NO_FUNDS` e ninguém recebe; o dinheiro das vendas volta e a produção retoma; o motivo vai no save. Sem `Ledger` no livro (o rig antigo de test_production.gd) não há folha.

const SEED: int = 59
const MINUTES_PER_HOUR: int = 60
const SETTLEMENT_A: String = "test_settlement_a"
const PLACE_BREAD: String = "a_work_01"
const SITE_BREAD: int = 3
const WORKERS: Array[int] = [100, 101, 102]
const WAGE: int = 2
const NPC_START_MONEY: int = 60


## `site_money`: o saldo inicial do tipo `site`.
func _definitions(site_money: int) -> EconomyDefinitions:
	var setup: EconomySetup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR)
	assert_true(setup.result.ok, setup.result.message)
	var definitions: EconomyDefinitions = setup.definitions
	var sites: Array[SiteDef] = [SiteDef.new("site_bread", SETTLEMENT_A, PLACE_BREAD, "bake_bread", 4)]
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


func _staff(module: EconomyModule) -> void:
	for npc_id: int in WORKERS:
		assert_true(module.request_open_owner(npc_id, "npc", PLACE_BREAD).ok)


func _worker_money(module: EconomyModule) -> Array[int]:
	var money: Array[int] = []
	for npc_id: int in WORKERS:
		money.append(module.peek_balance(npc_id).balance)
	return money


func _salary_moved(module: EconomyModule) -> int:
	for row: Dictionary in module.peek_ledger_totals().rows:
		if row["reason"] == Ledger.REASON_SALARY:
			return int(row["moved"])
	return 0


func test_a_site_with_funds_pays_every_worker_each_hour_it_produces_and_announces_one_event() -> void:
	var module: EconomyModule = EconomyModule.new(false, _definitions(5000))
	var world: World = _world(module)
	_staff(module)
	var paid: Array[WagesPaid] = []
	world.context.events.subscribe("WagesPaid", func(event: SimEvent) -> void: paid.append(event))
	_run_minutes(world, 3 * MINUTES_PER_HOUR)
	assert_eq(paid.size(), 3, "Um evento por hora, não um por trabalhador.")
	assert_eq([paid[0].workplace_id, paid[0].amount_each], [SITE_BREAD, WAGE])
	assert_eq(_worker_money(module), [NPC_START_MONEY + 3 * WAGE, NPC_START_MONEY + 3 * WAGE, NPC_START_MONEY + 3 * WAGE], "Cada trabalhador recebeu 2 por hora, 3 horas.")
	assert_eq(_salary_moved(module), 3 * WAGE * WORKERS.size(), "Todo o salário passou pelo `Ledger` com o motivo `salary`.")
	assert_true(module.peek_conservation().ok and module.peek_goods_conservation().ok)
	assert_eq(module.validate(), [] as Array[String])
	world.teardown()


func test_a_site_without_enough_for_the_whole_payroll_stops_with_no_funds_and_pays_nobody() -> void:
	var module: EconomyModule = EconomyModule.new(false, _definitions(5))
	var world: World = _world(module)
	_staff(module)
	var stopped: Array[ProductionStopped] = []
	world.context.events.subscribe("ProductionStopped", func(event: SimEvent) -> void: stopped.append(event))
	var paid: Array[WagesPaid] = []
	world.context.events.subscribe("WagesPaid", func(event: SimEvent) -> void: paid.append(event))
	_run_minutes(world, 2 * MINUTES_PER_HOUR)
	var site: EconomyReplies.SiteQuery = module.peek_site(SITE_BREAD)
	assert_eq([site.running, site.reason], [false, ProductionBook.NO_INPUT], "Com 5 de saldo o local nem compra a farinha: o primeiro motivo é a falta de insumo.")
	assert_eq(paid.size(), 0, "Sem produzir não há folha.")
	assert_eq(_worker_money(module), [NPC_START_MONEY, NPC_START_MONEY, NPC_START_MONEY], "Ninguém recebeu.")
	assert_eq(stopped.size(), 1, "Parou uma vez, na mudança de estado.")
	world.teardown()


func test_the_payroll_is_all_or_nothing_and_the_sale_of_the_stock_pays_the_next_hour() -> void:
	var module: EconomyModule = EconomyModule.new(false, _definitions(5))
	var world: World = _world(module)
	_staff(module)
	var market_id: int = module.peek_market_of(SETTLEMENT_A).market_id
	assert_true(module.request_transfer_goods(market_id, SITE_BREAD, "flour", 6).ok, "O local já tem a farinha de um lote.")
	assert_true(module.request_transfer_goods(market_id, SITE_BREAD, "bread", 6).ok, "E 6 de pão para vender depois.")
	var stopped: Array[ProductionStopped] = []
	world.context.events.subscribe("ProductionStopped", func(event: SimEvent) -> void: stopped.append(event))
	var resumed: Array[ProductionResumed] = []
	world.context.events.subscribe("ProductionResumed", func(event: SimEvent) -> void: resumed.append(event))
	var paid: Array[WagesPaid] = []
	world.context.events.subscribe("WagesPaid", func(event: SimEvent) -> void: paid.append(event))
	_run_minutes(world, MINUTES_PER_HOUR)
	assert_eq(stopped.size(), 1)
	assert_eq(stopped[0].reason, ProductionBook.NO_FUNDS, "5 de saldo não cobrem a folha de 6 (3 trabalhadores × 2): para por NO_FUNDS.")
	assert_eq([paid.size(), _worker_money(module)], [0, [NPC_START_MONEY, NPC_START_MONEY, NPC_START_MONEY] as Array[int]], "Tudo ou nada: nenhum trabalhador recebeu nada.")
	assert_true(module.peek_balance(SITE_BREAD).balance >= 6, "O local vendeu o pão parado e agora tem dinheiro para a folha.")
	_run_minutes(world, MINUTES_PER_HOUR)
	assert_eq(resumed.size(), 1, "A hora seguinte: o dinheiro da venda cobre a folha e o local volta.")
	assert_eq(paid.size(), 1)
	assert_eq(_worker_money(module), [NPC_START_MONEY + WAGE, NPC_START_MONEY + WAGE, NPC_START_MONEY + WAGE] as Array[int])
	assert_true(module.peek_conservation().ok)
	world.teardown()


func test_a_site_stopped_for_no_funds_comes_back_from_the_save_with_the_same_reason() -> void:
	var module: EconomyModule = EconomyModule.new(false, _definitions(5))
	var world: World = _world(module)
	_staff(module)
	var market_id: int = module.peek_market_of(SETTLEMENT_A).market_id
	assert_true(module.request_transfer_goods(market_id, SITE_BREAD, "flour", 6).ok)
	_run_minutes(world, MINUTES_PER_HOUR)
	assert_eq(module.peek_site(SITE_BREAD).reason, ProductionBook.NO_FUNDS)
	var saved: Dictionary = module.serialize()
	var copy: EconomyModule = EconomyModule.new(false, _definitions(5))
	var other: World = _world(copy)
	var parsed: Variant = JSON.parse_string(JSON.stringify(saved))
	assert_eq(typeof(parsed), TYPE_DICTIONARY)
	var data: Dictionary = parsed
	assert_true(copy.on_load(data).ok)
	assert_eq([copy.peek_site(SITE_BREAD).running, copy.peek_site(SITE_BREAD).reason], [false, ProductionBook.NO_FUNDS])
	assert_eq(JSON.stringify(copy.serialize(), "", true, true), JSON.stringify(saved, "", true, true), "Ida e volta sem mudar nada.")
	world.teardown()
	other.teardown()


func test_without_a_ledger_in_the_book_there_is_no_payroll() -> void:
	var book: OwnerBook = OwnerBook.new()
	var goods: GoodsLoader.LoadResult = GoodsLoader.load_dir(GoodsLoader.DEFAULT_DIR)
	var market: MarketLoader.LoadResult = MarketLoader.load_dir(GoodsLoader.DEFAULT_DIR)
	var loaded: ProductionLoader.LoadResult = ProductionLoader.load_dir(GoodsLoader.DEFAULT_DIR)
	assert_true(goods.result.ok and market.result.ok and loaded.result.ok)
	var store: GoodsStore = GoodsStore.new(book, goods.goods, goods.kinds)
	var markets: MarketBook = MarketBook.new(book, store, goods.goods, market.targets, market.params)
	var engine: TradeEngine = TradeEngine.new(book, Ledger.new(book), store, markets, NeutralTradeRules.new(), market.params)
	var production: ProductionBook = ProductionBook.new(book, store, markets, engine, loaded.recipes, loaded.params, market.params.max_order_quantity)
	assert_true(book.open_owner(SITE_BREAD, ProductionBook.KIND_SITE).ok)
	assert_true(production.register_site(SITE_BREAD, SiteDef.new("site_bread", SETTLEMENT_A, PLACE_BREAD, "bake_bread", 4)).ok)
	for worker_id: int in WORKERS:
		assert_true(production.assign_worker(SITE_BREAD, worker_id).ok)
	var events: Array[SimEvent] = production.hour_step()
	for event: SimEvent in events:
		assert_ne(event.type, "WagesPaid", "Sem `Ledger` não há folha nem evento de folha.")


func _payer_rig() -> Array:
	var book: OwnerBook = OwnerBook.new()
	for owner_id: int in [1, 2, 3]:
		assert_true(book.open_owner(owner_id, "npc").ok)
	var ledger: Ledger = Ledger.new(book)
	assert_true(ledger.mint(1, 100, Ledger.REASON_GAME_START).ok)
	return [book, ledger, WagePayer.new(book, ledger)]


func test_the_wage_payer_needs_the_whole_payroll_and_every_account_open() -> void:
	var rig: Array = _payer_rig()
	var book: OwnerBook = rig[0]
	var ledger: Ledger = rig[1]
	var payer: WagePayer = rig[2]
	assert_true(payer.can_pay(1, 10, [2, 3]), "20 cabem nos 100.")
	assert_false(payer.can_pay(1, 60, [2, 3]), "120 não cabem nos 100.")
	assert_true(payer.can_pay(1, 0, [2, 3]) and payer.can_pay(1, 60, []), "Salário 0 ou ninguém para pagar: sempre cabe.")
	assert_false(payer.can_pay(1, 10, [2, 99]), "Trabalhador sem conta: a folha inteira não cabe.")
	assert_true(book.close_owner(3).ok)
	assert_false(payer.can_pay(1, 10, [2, 3]), "Conta fechada: a folha inteira não cabe.")
	assert_true(payer.pay(1, 10, [2]).ok)
	assert_eq([ledger.balance_of(1), ledger.balance_of(2)], [90, 10])
	assert_true(ledger.is_conserved())
	assert_true(payer.pay(1, 0, [2]).ok and ledger.balance_of(2) == 10, "Salário 0 não move nada.")
	assert_false(payer.pay(1, 10, [99]).ok, "Pagar a quem não tem conta falha e diz por quê.")


func test_a_recipe_with_no_wage_pays_nothing_and_announces_nothing() -> void:
	var definitions: EconomyDefinitions = _definitions(5000)
	definitions.recipes["bake_bread"].wage_per_hour = 0
	var module: EconomyModule = EconomyModule.new(false, definitions)
	var world: World = _world(module)
	_staff(module)
	var paid: Array[WagesPaid] = []
	world.context.events.subscribe("WagesPaid", func(event: SimEvent) -> void: paid.append(event))
	_run_minutes(world, 2 * MINUTES_PER_HOUR)
	assert_true(module.peek_site(SITE_BREAD).running, "Produz do mesmo jeito.")
	assert_eq([paid.size(), _salary_moved(module), _worker_money(module)], [0, 0, [NPC_START_MONEY, NPC_START_MONEY, NPC_START_MONEY] as Array[int]])
	world.teardown()
