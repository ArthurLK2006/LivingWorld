extends GutTest
## LW-090c: os mercados ligados ao `EconomyModule` (docs/modules/economy.md, seções 4 e 10): um mercado por assentamento dos dados criado no jogo novo, com saldo e estoque iniciais; o preço andando ao fim de cada dia do
## relógio, com os eventos publicados; a porta (`peek_market_of`, `peek_market`, `peek_price`, `peek_stock`, `request_set_stock`); o save com os mercados e o dia; e o `EconomySetup`. Usa os dados REAIS (data/economy).
## Os valores esperados são contas à mão com as constantes reais (saldo do mercado 3000, pão com alvo 60 e valor-base 10, escassez em 10 dias, limiar de 10% para o evento de preço).

const SEED: int = 41
const MINUTES_PER_DAY: int = 1440
const MARKET_A: int = 1
const MARKET_B: int = 2
const SITE: int = 1000


func _setup(development_build: bool = false) -> EconomySetup:
	var setup: EconomySetup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR, development_build)
	assert_true(setup.result.ok, setup.result.message)
	return setup


func _world(module: EconomyModule, world_seed: int = SEED) -> World:
	var clock: SimClock = SimClock.new()
	var world: World = World.new(SimContext.new(clock, EventBus.new(clock), WorldRng.new(world_seed), IdGenerator.new()))
	assert_true(world.register_module("economy", module).ok)
	world.setup()
	world.post_setup()
	world.on_new_game(world_seed)
	return world


func _run_days(world: World, days: int) -> void:
	for _minute: int in days * MINUTES_PER_DAY:
		world.context.clock.advance_step()
		world.tick(1)
	world.context.events.dispatch()


func _through_json(data: Dictionary) -> Dictionary:
	# Variant: o JSON devolve qualquer tipo; aqui o formato é conhecido (um objeto).
	var parsed: Variant = JSON.parse_string(JSON.stringify(data))
	assert_eq(typeof(parsed), TYPE_DICTIONARY)
	var copy: Dictionary = parsed
	return copy


func _row(rows: Array[Dictionary], good_id: String) -> Dictionary:
	for row: Dictionary in rows:
		if row["good_id"] == good_id:
			return row
	fail_test("O bem '%s' não está no mercado." % good_id)
	return {}


func test_a_new_game_opens_one_funded_market_per_settlement_with_the_initial_stock() -> void:
	var module: EconomyModule = EconomyModule.new(false, _setup().definitions)
	var world: World = _world(module)
	var market: EconomyReplies.MarketQuery = module.peek_market_of("test_settlement_a")
	assert_true(market.result.ok, market.result.message)
	assert_eq([market.market_id, market.settlement_id, market.rows.size()], [MARKET_A, "test_settlement_a", 10], "Os IDs vêm do `core`, por assentamento em ordem alfabética.")
	assert_eq(module.peek_market_of("test_settlement_b").market_id, MARKET_B)
	assert_eq([module.peek_balance(MARKET_A).balance, module.peek_balance(MARKET_B).balance], [3000, 3000], "O saldo inicial do tipo `market`.")
	var conservation: EconomyReplies.ConservationQuery = module.peek_conservation()
	assert_eq([conservation.sum, conservation.created, conservation.ok], [6000, 6000, true], "Dinheiro criado só por `game_start`.")
	assert_eq(module.peek_ledger_totals().rows, [{"reason": "game_start", "moved": 0, "created": 6000, "destroyed": 0}] as Array[Dictionary])
	var bread: Dictionary = _row(market.rows, "bread")
	assert_eq([bread["stock"], bread["target_stock"], bread["price"], bread["ask"], bread["bid"], bread["in_shortage"]], [60, 60, 10, 11, 9, false], "Estoque igual ao alvo: preço igual ao valor-base; spread de 10%.")
	assert_eq([module.peek_stock(MARKET_A, "tool").value, module.peek_stock(MARKET_B, "plank").value, module.peek_price(MARKET_A, "tool").value], [29, 21, PriceMath.goal_price(26, 29, 29, MarketLoader.load_dir(EconomySetup.DEFAULT_DIR).params)])
	assert_true(module.peek_goods_conservation().ok)
	assert_eq(module.peek_inventory(MARKET_A).rows.size(), 10)
	assert_eq(module.validate(), [] as Array[String])
	assert_eq(world.validate(), [] as Array[String])
	assert_eq([module.peek_market_of("nowhere").result.code, module.peek_market(99).result.code, module.peek_price(99, "bread").result.code, module.peek_stock(MARKET_A, "gold").result.code], [EconomyCodes.UNKNOWN_MARKET, EconomyCodes.UNKNOWN_MARKET, EconomyCodes.UNKNOWN_MARKET, EconomyCodes.UNKNOWN_GOOD])
	world.teardown()


func test_the_price_walks_at_the_end_of_each_day_and_the_events_are_published() -> void:
	var module: EconomyModule = EconomyModule.new(false, _setup().definitions)
	var world: World = _world(module)
	var price_events: Array[PriceChanged] = []
	var shortage_events: Array[ShortageDeclared] = []
	world.context.events.subscribe("PriceChanged", func(event: SimEvent) -> void: price_events.append(event))
	world.context.events.subscribe("ShortageDeclared", func(event: SimEvent) -> void: shortage_events.append(event))
	assert_true(module.request_open_owner(SITE, "site").ok)
	assert_true(module.request_transfer_goods(MARKET_A, SITE, "bread", 55).ok, "O pão do mercado A cai de 60 para 5.")
	_run_days(world, 1)
	assert_eq(module.peek_price(MARKET_A, "bread").value, 14, "Fim do 1º dia: o preço-alvo vai ao teto (30) e o preço anda 20% da diferença (20 × 0,2 = 4): 10 + 4 = 14.")
	assert_eq(price_events.size(), 1, "Só o pão variou mais que o limiar de 10%.")
	assert_eq([price_events[0].market_id, price_events[0].good_id, price_events[0].old_price, price_events[0].new_price], [MARKET_A, "bread", 10, module.peek_price(MARKET_A, "bread").value])
	assert_eq(shortage_events.size(), 0, "Ainda dentro do prazo da escassez.")
	_run_days(world, 9)
	assert_eq(shortage_events.size(), 1, "No 10º dia a escassez do pão é declarada, uma vez.")
	assert_eq([shortage_events[0].market_id, shortage_events[0].good_id, shortage_events[0].stock, shortage_events[0].target_stock], [MARKET_A, "bread", 5, 60])
	assert_true(_row(module.peek_market(MARKET_A).rows, "bread")["in_shortage"])
	assert_eq(module.peek_price(MARKET_B, "bread").value, 10, "O mercado B não mudou.")
	assert_true(module.peek_goods_conservation().ok and module.peek_conservation().ok, "Nada disso cria nem destrói bem ou dinheiro.")
	world.teardown()


func test_set_stock_is_a_development_command_that_keeps_the_conservation_of_goods() -> void:
	var locked: EconomyModule = EconomyModule.new(false, _setup(false).definitions)
	var locked_world: World = _world(locked)
	assert_eq(locked.request_set_stock(MARKET_A, "bread", 10).code, EconomyCodes.DEV_ONLY, "Fora do build de desenvolvimento o comando não existe.")
	assert_eq(locked.peek_stock(MARKET_A, "bread").value, 60)
	locked_world.teardown()
	var module: EconomyModule = EconomyModule.new(false, _setup(true).definitions)
	var world: World = _world(module)
	assert_true(module.request_set_stock(MARKET_A, "bread", 20).ok)
	assert_eq(module.peek_stock(MARKET_A, "bread").value, 20)
	assert_true(module.request_set_stock(MARKET_A, "bread", 80).ok)
	assert_eq(module.peek_stock(MARKET_A, "bread").value, 80)
	assert_true(module.request_set_stock(MARKET_A, "bread", 80).ok, "Pôr o mesmo estoque não muda nada.")
	var conservation: Array[Dictionary] = module.peek_goods_conservation().rows
	assert_eq([_row(conservation, "bread")["created"], _row(conservation, "bread")["destroyed"], _row(conservation, "bread")["ok"]], [60 + 40 + 60, 40, true], "O pão criado é o dos dois mercados (60 e 40) mais os 60 de `produced`; destruído, os 40 de `consumed`; e a conservação fecha.")
	assert_eq(module.request_set_stock(99, "bread", 1).code, EconomyCodes.UNKNOWN_MARKET)
	assert_eq(module.request_set_stock(MARKET_A, "gold", 1).code, EconomyCodes.UNKNOWN_GOOD)
	assert_eq(module.request_set_stock(MARKET_A, "bread", -1).code, EconomyCodes.BAD_QUANTITY)
	assert_eq(module.request_set_stock(MARKET_A, "metal", 5000).code, EconomyCodes.CAPACITY_EXCEEDED, "Estoque que não cabe no peso do mercado é recusado sem mudar nada.")
	assert_eq(module.peek_stock(MARKET_A, "metal").value, 10)
	world.teardown()


func test_the_save_carries_the_markets_and_a_loaded_world_keeps_walking_the_same() -> void:
	var module: EconomyModule = EconomyModule.new(false, _setup().definitions)
	var world: World = _world(module)
	module.request_open_owner(SITE, "site")
	module.request_transfer_goods(MARKET_A, SITE, "bread", 40)
	_run_days(world, 3)
	var saved: Dictionary = world.serialize()
	var block: Dictionary = saved["modules"]["economy"]
	assert_true(block.has("markets"), "O bloco leva os mercados.")
	var other_module: EconomyModule = EconomyModule.new(false, _setup().definitions)
	var other: World = _world(other_module, SEED + 1)
	assert_true(other.on_load(_through_json(saved)).ok)
	assert_eq(other.state_hash(), world.state_hash(), "Salvar e carregar não muda o hash.")
	_run_days(world, 2)
	_run_days(other, 2)
	assert_eq(other.state_hash(), world.state_hash(), "Depois de carregar, os mesmos dias dão o mesmo estado (o relógio restaurado evita fechar um dia duas vezes).")
	assert_eq(other_module.peek_price(MARKET_A, "bread").value, module.peek_price(MARKET_A, "bread").value)
	var extra: Dictionary = _through_json(saved)
	extra["modules"]["economy"]["day"] = 3
	assert_eq(other.on_load(extra).code, EconomyCodes.INVALID_SAVE, "Chave desconhecida no bloco é recusada.")
	var strange: Dictionary = _through_json(saved)
	strange["modules"]["economy"]["markets"]["markets"]["1"]["settlement_id"] = "nowhere"
	assert_eq(other.on_load(strange).code, EconomyCodes.INVALID_SAVE, "O mercado de um assentamento que não existe é recusado.")
	world.teardown()
	other.teardown()


func test_a_module_without_price_constants_has_no_markets_and_the_setup_reports_invalid_data() -> void:
	var definitions: EconomyDefinitions = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR).definitions
	var without: EconomyModule = EconomyModule.new(false, EconomyDefinitions.new(definitions.goods, definitions.kinds))
	var world: World = _world(without)
	assert_eq(without.peek_market_of("test_settlement_a").result.code, EconomyCodes.UNKNOWN_MARKET)
	assert_eq(world.serialize()["modules"]["economy"], {}, "Sem mercados nem dono, o bloco continua vazio.")
	_run_days(world, 2)
	assert_eq(without.peek_conservation().sum, 0)
	world.teardown()
	var missing: EconomySetup = EconomySetup.from_dir("res://tests/fixtures/world/pasta_que_nao_existe")
	assert_false(missing.result.ok)
	assert_eq(missing.result.code, EconomySetup.CODE_INVALID)
	assert_string_contains(missing.result.message, "bens e tipos de dono inválidos")


func test_the_game_world_gets_the_markets_only_when_it_receives_the_setup() -> void:
	var loaded: TerrainLoader.LoadResult = TerrainLoader.load_dir("res://data/world")
	assert_true(loaded.result.ok, loaded.result.message)
	var runner: SimulationRunner = SimulationRunner.new(SEED)
	var bare: GameModules = GameModules.register(SimulationRunner.new(SEED), loaded.terrain)
	assert_true(bare.result.ok, bare.result.message)
	assert_eq(bare.economy.peek_market_of("test_settlement_a").result.code, EconomyCodes.UNKNOWN_MARKET, "Sem EconomySetup o jogo não cria mercados (o NPC ainda não usa a economia).")
	var modules: GameModules = GameModules.register(runner, loaded.terrain, [], null, _setup())
	assert_true(modules.result.ok, modules.result.message)
	runner.start_new_game()
	var market: EconomyReplies.MarketQuery = modules.economy.peek_market_of("test_settlement_a")
	assert_true(market.result.ok, market.result.message)
	assert_eq(market.rows.size(), 10)
	assert_eq(modules.economy.peek_balance(market.market_id).balance, 3000)
	runner.finish()
