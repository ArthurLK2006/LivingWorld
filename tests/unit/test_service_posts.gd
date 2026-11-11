extends GutTest
## LW-095 (parte b): os postos de serviço (docs/modules/economy.md, seção 6; DEC-164 e DEC-174). Economia REAL (data/economy) com as definições de postos montadas à mão (o dado `service_posts.json` é da distribuição dos povoados): um posto de
## `guard` em `a_work_05` do povoado A, 3 de salário por hora, e NPCs reais abertos pela porta (saldo inicial 60). A folha sai da conta do MERCADO do povoado, todo ou nada por posto (sem fundos o posto para por `NO_FUNDS` e ninguém recebe, sem
## evento), é paga ANTES dos locais de produção, publica UM `WagesPaid` por posto e por hora, o NPC que morre sai da folha e o estado dos postos vai e volta pelo save. O livro (`ServicePostBook`) tem o seu teste de unidade no fim.

const SEED: int = 61
const MINUTES_PER_HOUR: int = 60
const SETTLEMENT_A: String = "test_settlement_a"
const PLACE_POST: String = "a_work_05"
const PLACE_BREAD: String = "a_work_01"
const MARKET_A: int = 1
const SITE_BREAD: int = 3
const POST: int = 4
const GUARDS: Array[int] = [100, 101, 102]
const WAGE: int = 3
const NPC_START_MONEY: int = 60


## `market_money`: o saldo inicial do tipo `market`; `with_site`: acrescenta um local de produção de pão em `a_work_01` (ID 3; o posto fica com o 4).
func _definitions(market_money: int, with_site: bool = false) -> EconomyDefinitions:
	var setup: EconomySetup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR)
	assert_true(setup.result.ok, setup.result.message)
	var definitions: EconomyDefinitions = setup.definitions
	var posts: Array[PostDef] = [PostDef.new("post_a_guard", SETTLEMENT_A, PLACE_POST, "guard", 8, WAGE)]
	definitions.service_posts = posts
	if with_site:
		var sites: Array[SiteDef] = [SiteDef.new("site_bread", SETTLEMENT_A, PLACE_BREAD, "bake_bread", 4)]
		definitions.production_sites = sites
	for kind: OwnerKindDef in definitions.kinds:
		if kind.id == MarketBook.KIND_MARKET:
			kind.initial_balance = market_money
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


func _hire(module: EconomyModule, npc_ids: Array[int] = GUARDS, place_id: String = PLACE_POST) -> void:
	for npc_id: int in npc_ids:
		assert_true(module.request_open_owner(npc_id, "npc", place_id).ok)


func _money(module: EconomyModule, owner_ids: Array[int]) -> Array[int]:
	var money: Array[int] = []
	for owner_id: int in owner_ids:
		money.append(module.peek_balance(owner_id).balance)
	return money


func test_the_market_pays_every_guard_each_hour_and_one_event_comes_out_per_post() -> void:
	var module: EconomyModule = EconomyModule.new(false, _definitions(3000))
	var world: World = _world(module)
	_hire(module)
	var paid: Array[WagesPaid] = []
	world.context.events.subscribe("WagesPaid", func(event: SimEvent) -> void: paid.append(event))
	var market_before: int = module.peek_balance(MARKET_A).balance
	_run_minutes(world, 2 * MINUTES_PER_HOUR)
	assert_eq(paid.size(), 2, "Um evento por hora, não um por guarda.")
	assert_eq([paid[0].workplace_id, paid[0].amount_each], [POST - 1, WAGE], "O posto leva o ID depois dos mercados (1 e 2): sem local de produção é o 3.")
	assert_eq(_money(module, GUARDS), [NPC_START_MONEY + 2 * WAGE, NPC_START_MONEY + 2 * WAGE, NPC_START_MONEY + 2 * WAGE] as Array[int])
	assert_eq(module.peek_balance(MARKET_A).balance, market_before - 2 * WAGE * GUARDS.size(), "O dinheiro saiu da conta do mercado, pelo `Ledger`.")
	assert_true(module.peek_conservation().ok)
	assert_eq(module.validate(), [] as Array[String])
	world.teardown()


func test_a_market_without_the_whole_payroll_stops_the_post_pays_nobody_and_publishes_nothing() -> void:
	var module: EconomyModule = EconomyModule.new(false, _definitions(5))
	var world: World = _world(module)
	_hire(module)
	var paid: Array[WagesPaid] = []
	world.context.events.subscribe("WagesPaid", func(event: SimEvent) -> void: paid.append(event))
	_run_minutes(world, MINUTES_PER_HOUR)
	assert_eq(paid.size(), 0, "5 no mercado não cobrem a folha de 9 (3 guardas × 3): ninguém recebe e não há evento.")
	assert_eq(_money(module, GUARDS), [NPC_START_MONEY, NPC_START_MONEY, NPC_START_MONEY] as Array[int], "Tudo ou nada.")
	var other: int = 200
	assert_true(module.request_open_owner(other, "npc").ok)
	assert_true(module.request_trade(other, MARKET_A, "grain", 5, "buy").result.ok, "Um NPC compra grão e o dinheiro entra na conta do mercado.")
	_run_minutes(world, MINUTES_PER_HOUR)
	assert_eq(paid.size(), 1, "Com dinheiro de novo o posto volta a pagar na hora seguinte.")
	assert_eq(_money(module, GUARDS), [NPC_START_MONEY + WAGE, NPC_START_MONEY + WAGE, NPC_START_MONEY + WAGE] as Array[int])
	world.teardown()


func test_the_posts_are_paid_before_the_production_sites() -> void:
	var module: EconomyModule = EconomyModule.new(false, _definitions(3000, true))
	var world: World = _world(module)
	_hire(module)
	_hire(module, [110, 111, 112], PLACE_BREAD)
	var order: Array[int] = []
	world.context.events.subscribe("WagesPaid", func(event: SimEvent) -> void: order.append((event as WagesPaid).workplace_id))
	_run_minutes(world, MINUTES_PER_HOUR)
	assert_eq(order, [POST, SITE_BREAD] as Array[int], "A folha do posto (ID 4) sai antes da do local de produção (ID 3).")
	world.teardown()


func test_a_post_without_workers_pays_nothing_and_a_dead_guard_leaves_the_payroll() -> void:
	var module: EconomyModule = EconomyModule.new(false, _definitions(3000))
	var world: World = _world(module)
	var paid: Array[WagesPaid] = []
	world.context.events.subscribe("WagesPaid", func(event: SimEvent) -> void: paid.append(event))
	_run_minutes(world, MINUTES_PER_HOUR)
	assert_eq(paid.size(), 0, "Sem guarda não há folha nem evento.")
	_hire(module)
	world.context.events.publish(NpcDied.new(GUARDS[2], "test", 0))
	world.context.events.dispatch()
	var market_before: int = module.peek_balance(MARKET_A).balance
	_run_minutes(world, MINUTES_PER_HOUR)
	assert_eq(paid.size(), 1)
	assert_eq(module.peek_balance(MARKET_A).balance, market_before - WAGE * 2, "O guarda morto saiu da folha: só dois recebem.")
	world.teardown()


func test_the_state_of_the_posts_survives_the_save_and_a_bad_block_is_refused_without_changing_anything() -> void:
	var module: EconomyModule = EconomyModule.new(false, _definitions(5))
	var world: World = _world(module)
	_hire(module)
	_run_minutes(world, MINUTES_PER_HOUR)
	var saved: Dictionary = module.serialize()
	assert_true(saved.has("posts"), "Com postos o bloco ganha a chave `posts`.")
	assert_eq([saved["posts"]["posts"][str(POST - 1)]["stopped"], saved["posts"]["posts"][str(POST - 1)]["worker_ids"]], [true, GUARDS], "O mercado com 5 não cobre a folha: o posto está parado e a equipe vai no save.")
	var parsed: Variant = JSON.parse_string(JSON.stringify(saved))
	assert_eq(typeof(parsed), TYPE_DICTIONARY)
	var data: Dictionary = parsed
	var copy: EconomyModule = EconomyModule.new(false, _definitions(5))
	var other: World = _world(copy)
	assert_true(copy.on_load(data).ok)
	assert_eq(JSON.stringify(copy.serialize(), "", true, true), JSON.stringify(saved, "", true, true), "Ida e volta sem mudar nada.")
	var broken: Variant = JSON.parse_string(JSON.stringify(saved))
	var broken_block: Dictionary = broken
	broken_block["posts"]["posts"][str(POST - 1)]["worker_ids"] = [102, 101]
	var refused: Result = copy.on_load(broken_block)
	assert_false(refused.ok)
	assert_eq(refused.code, EconomyCodes.INVALID_SAVE)
	assert_string_contains(refused.message, "ordem crescente")
	assert_eq(JSON.stringify(copy.serialize(), "", true, true), JSON.stringify(saved, "", true, true), "Recusou sem mudar o estado.")
	world.teardown()
	other.teardown()


func test_a_world_without_posts_keeps_the_save_block_free_of_the_posts_key() -> void:
	var setup: EconomySetup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR)
	assert_true(setup.result.ok, setup.result.message)
	var module: EconomyModule = EconomyModule.new(false, setup.definitions)
	var world: World = _world(module)
	assert_false(module.serialize().has("posts"), "Sem postos nada muda no bloco do save (nem no hash).")
	world.teardown()


func _book() -> ServicePostBook:
	var book: OwnerBook = OwnerBook.new()
	var goods: GoodsLoader.LoadResult = GoodsLoader.load_dir(GoodsLoader.DEFAULT_DIR)
	var market: MarketLoader.LoadResult = MarketLoader.load_dir(GoodsLoader.DEFAULT_DIR)
	assert_true(goods.result.ok and market.result.ok)
	var store: GoodsStore = GoodsStore.new(book, goods.goods, goods.kinds)
	var markets: MarketBook = MarketBook.new(book, store, goods.goods, market.targets, market.params)
	return ServicePostBook.new(markets, WagePayer.new(book, Ledger.new(book)))


func test_the_post_book_refuses_a_second_post_on_the_same_place_and_knows_its_posts() -> void:
	var posts: ServicePostBook = _book()
	var guard: PostDef = PostDef.new("post_a_guard", SETTLEMENT_A, PLACE_POST, "guard", 8, WAGE)
	assert_true(posts.register_post(5, guard).ok)
	assert_false(posts.register_post(5, PostDef.new("other", SETTLEMENT_A, "a_work_04", "guard", 1, 1)).ok, "O mesmo ID.")
	var twice: Result = posts.register_post(6, PostDef.new("inn", SETTLEMENT_A, PLACE_POST, "innkeeper", 6, WAGE))
	assert_false(twice.ok)
	assert_string_contains(twice.message, PLACE_POST)
	assert_true(posts.register_post(7, PostDef.new("inn", SETTLEMENT_A, "a_work_04", "innkeeper", 6, WAGE)).ok)
	assert_eq([posts.post_ids(), posts.post_at(PLACE_POST), posts.post_at("nowhere"), posts.posts_of(SETTLEMENT_A), posts.posts_of("elsewhere")], [[5, 7] as Array[int], 5, IdGenerator.NO_ID, [5, 7] as Array[int], [] as Array[int]])
	assert_true(posts.assign_worker(5, 12).ok and posts.assign_worker(5, 10).ok and posts.assign_worker(5, 12).ok)
	assert_false(posts.assign_worker(99, 1).ok, "Posto que não existe.")
	assert_eq(posts.state_of(5)["worker_ids"], [10, 12], "Em ordem crescente e sem repetição.")
	posts.remove_worker(10)
	assert_eq([posts.state_of(5)["worker_ids"], posts.state_of(5)["running"], posts.state_of(99)], [[12], true, {}])
	assert_false(posts.is_pristine())
