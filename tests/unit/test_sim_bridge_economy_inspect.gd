extends GutTest
## LW-108b: as consultas de inspeção da economia da ponte, só de leitura (docs/modules/bridge.md, "Inspeção da economia"; contrato na LW-108a), sem janela e com o jogo real
## (`GameApp.start_default_game`: 3 mercados e 14 locais de produção): `peek_economy_overview` (dinheiro, bens e livro-razão), `peek_economy_markets` (preço e estoque por povoado)
## e `peek_economy_sites` (locais de produção e motivo de parada). A ponte não tem regra de jogo: confere-se que as respostas são cópias fiéis do que a economia diz, a ordem, os
## códigos de falha e que consultar não escreve nada na simulação (hash, save, relógio, RNG e IDs ficam iguais).

const SETTLEMENTS: Array[String] = ["test_settlement_a", "test_settlement_b", "test_settlement_c"]
const MARKET_COUNT: int = 3
const SITE_COUNT: int = 14
const GOOD_COUNT: int = 10
## 1 passo = 1 minuto de jogo: mais de 24 horas, para passar por pelo menos um fim de dia (o preço anda e a produção roda).
const ONE_DAY_AND_MORE_STEPS: int = 1500
const NO_SUCH_SETTLEMENT: String = "no_such_settlement"

var _host: SimulationHostNode
var _app: GameAppNode
var _bridge: SimBridge
var _economy: EconomyModule


func before_each() -> void:
	_host = SimulationHostNode.new()
	_app = GameAppNode.new()
	_app.bind_host(_host)
	_app.start_default_game(_host)
	_bridge = _app.peek_bridge()
	_economy = _host.economy


func after_each() -> void:
	_app.free()
	if _host.runner != null:
		_host.runner.finish()
	_host.free()


func _step(count: int) -> void:
	for _index: int in count:
		_host.runner.step_once()


## Confere uma resposta de visão geral contra as consultas da própria economia (a ponte só copia).
func _assert_overview_matches_the_economy(reply: BridgeEconomyReplies.EconomyOverviewReply) -> void:
	assert_true(reply.result.ok, reply.result.message)
	var money: EconomyReplies.ConservationQuery = _economy.peek_conservation()
	assert_eq([reply.money_sum, reply.money_created, reply.money_destroyed, reply.is_money_ok], [money.sum, money.created, money.destroyed, money.ok], "O dinheiro é o de `peek_conservation`.")
	var goods: EconomyReplies.GoodsConservationQuery = _economy.peek_goods_conservation()
	assert_eq(reply.is_goods_ok, goods.ok)
	assert_eq(reply.goods.size(), goods.rows.size(), "Uma linha por bem que já teve movimento.")
	for index: int in goods.rows.size():
		var row: BridgeEconomyReplies.EconomyGoodsRow = reply.goods[index]
		var source: Dictionary = goods.rows[index]
		assert_eq([row.good_id, row.in_stock, row.created, row.destroyed, row.is_ok], [source["good_id"], source["in_stock"], source["created"], source["destroyed"], source["ok"]], "Bem %d: as colunas de `peek_goods_conservation`." % index)
	var ledger: Array[Dictionary] = _economy.peek_ledger_totals().rows
	assert_eq(reply.ledger.size(), ledger.size(), "Uma linha por motivo que já teve movimento.")
	for index: int in ledger.size():
		var line: BridgeEconomyReplies.EconomyLedgerRow = reply.ledger[index]
		assert_eq([line.reason, line.moved, line.created, line.destroyed], [ledger[index]["reason"], ledger[index]["moved"], ledger[index]["created"], ledger[index]["destroyed"]], "Motivo %d: as colunas de `peek_ledger_totals`." % index)
	assert_eq(reply.problems, _economy.validate(), "Os problemas são o `validate()` da economia.")


## Confere os mercados e os locais contra as consultas da economia, para cada um dos povoados.
func _assert_markets_and_sites_match_the_economy() -> void:
	var markets: BridgeEconomyReplies.EconomyMarketsReply = _bridge.peek_economy_markets()
	assert_true(markets.result.ok, markets.result.message)
	assert_eq(markets.markets.size(), MARKET_COUNT)
	for entry: BridgeEconomyReplies.EconomyMarketEntry in markets.markets:
		var query: EconomyReplies.MarketQuery = _economy.peek_market(entry.market_id)
		assert_true(query.result.ok, query.result.message)
		assert_eq(entry.settlement_id, query.settlement_id)
		assert_eq(entry.cash, _economy.peek_balance(entry.market_id).balance, "O dinheiro do mercado é o saldo da conta dele.")
		assert_eq(entry.rows.size(), query.rows.size())
		for index: int in query.rows.size():
			var row: BridgeEconomyReplies.EconomyMarketRow = entry.rows[index]
			var source: Dictionary = query.rows[index]
			assert_eq([row.good_id, row.stock, row.target_stock, row.price, row.ask, row.bid, row.is_in_shortage], [source["good_id"], source["stock"], source["target_stock"], source["price"], source["ask"], source["bid"], source["in_shortage"]], "Mercado %d, linha %d: as colunas de `peek_market`." % [entry.market_id, index])
			assert_eq(row.price, _economy.peek_price(entry.market_id, row.good_id).value, "O preço da tela é o de `peek_price`.")
			assert_eq(row.stock, _economy.peek_stock(entry.market_id, row.good_id).value, "O estoque da tela é o de `peek_stock`.")
	var sites: BridgeEconomyReplies.EconomySitesReply = _bridge.peek_economy_sites()
	assert_true(sites.result.ok, sites.result.message)
	assert_eq(sites.sites.size(), SITE_COUNT)
	for entry: BridgeEconomyReplies.EconomySiteEntry in sites.sites:
		var query: EconomyReplies.SiteQuery = _economy.peek_site(entry.site_id)
		assert_true(query.result.ok, query.result.message)
		assert_eq([entry.settlement_id, entry.place_id, entry.recipe_id, entry.occupation_id, entry.wage_per_hour], [query.settlement_id, query.place_id, query.recipe_id, query.occupation_id, query.wage_per_hour])
		assert_eq([entry.workers_wanted, entry.workers_assigned, entry.is_running, entry.reason, entry.efficiency_bp, entry.batch_progress_bp], [query.workers_wanted, query.workers_assigned, query.running, query.reason, query.efficiency_bp, query.batch_progress_bp], "Local %d: o estado de `peek_site`." % entry.site_id)


func test_the_overview_is_a_faithful_copy_of_the_money_goods_and_ledger_queries() -> void:
	var reply: BridgeEconomyReplies.EconomyOverviewReply = _bridge.peek_economy_overview()
	_assert_overview_matches_the_economy(reply)
	assert_gt(reply.money_sum, 0, "O jogo real nasce com dinheiro em circulação.")
	assert_true(reply.is_money_ok and reply.is_goods_ok, "Jogo novo: a conservação do dinheiro e a dos bens fecham.")
	assert_eq(reply.problems.size(), 0, "O jogo real saudável não acusa problema.")
	assert_gt(reply.ledger.size(), 0, "Os saldos iniciais já têm motivo no livro-razão.")


func test_the_markets_are_the_three_settlement_markets_in_ascending_order_with_ten_goods_each() -> void:
	var reply: BridgeEconomyReplies.EconomyMarketsReply = _bridge.peek_economy_markets()
	assert_true(reply.result.ok, reply.result.message)
	var market_ids: Array[int] = []
	var settlements: Array[String] = []
	for entry: BridgeEconomyReplies.EconomyMarketEntry in reply.markets:
		market_ids.append(entry.market_id)
		settlements.append(entry.settlement_id)
		assert_eq(entry.rows.size(), GOOD_COUNT, "%s negocia os 10 bens." % entry.settlement_id)
		var good_ids: Array[String] = []
		for row: BridgeEconomyReplies.EconomyMarketRow in entry.rows:
			good_ids.append(row.good_id)
		var sorted_ids: Array[String] = good_ids.duplicate()
		sorted_ids.sort()
		assert_eq(good_ids, sorted_ids, "Os bens vêm por `good_id` crescente.")
	var sorted_market_ids: Array[int] = market_ids.duplicate()
	sorted_market_ids.sort()
	assert_eq(market_ids, sorted_market_ids, "Os mercados vêm por `market_id` crescente.")
	var sorted_settlements: Array[String] = settlements.duplicate()
	sorted_settlements.sort()
	assert_eq(sorted_settlements, SETTLEMENTS, "Um mercado para cada um dos três povoados.")


func test_the_sites_are_the_fourteen_production_sites_in_ascending_order() -> void:
	var reply: BridgeEconomyReplies.EconomySitesReply = _bridge.peek_economy_sites()
	assert_true(reply.result.ok, reply.result.message)
	assert_eq(reply.sites.size(), SITE_COUNT, "Os 14 locais dos dados reais (5 no A, 6 no B e 3 no C).")
	var site_ids: Array[int] = []
	var per_settlement: Dictionary[String, int] = {}
	for entry: BridgeEconomyReplies.EconomySiteEntry in reply.sites:
		site_ids.append(entry.site_id)
		per_settlement[entry.settlement_id] = per_settlement.get(entry.settlement_id, 0) + 1
		if not entry.is_running:
			assert_false(entry.reason.is_empty(), "Local %d parado diz o motivo." % entry.site_id)
		else:
			assert_eq(entry.reason, "", "Local %d rodando não tem motivo." % entry.site_id)
	var sorted_site_ids: Array[int] = site_ids.duplicate()
	sorted_site_ids.sort()
	assert_eq(site_ids, sorted_site_ids, "Os locais vêm por `site_id` crescente.")
	assert_eq(per_settlement, {"test_settlement_a": 5, "test_settlement_b": 6, "test_settlement_c": 3} as Dictionary[String, int])


func test_the_answers_still_match_the_economy_after_more_than_a_day_of_play() -> void:
	_step(ONE_DAY_AND_MORE_STEPS)
	_assert_overview_matches_the_economy(_bridge.peek_economy_overview())
	_assert_markets_and_sites_match_the_economy()
	var overview: BridgeEconomyReplies.EconomyOverviewReply = _bridge.peek_economy_overview()
	assert_true(overview.is_money_ok, "Depois de um dia a soma das contas ainda é o criado menos o destruído.")
	assert_true(overview.is_goods_ok, "E os bens também fecham.")
	assert_eq(overview.problems.size(), 0, "E o `validate()` da economia continua sem problema.")


func test_a_settlement_without_a_market_is_not_an_error_and_does_not_appear() -> void:
	var asked: Array[String] = [SETTLEMENTS[1], NO_SUCH_SETTLEMENT, SETTLEMENTS[0]]
	var reply: BridgeEconomyReplies.EconomyMarketsReply = BridgeEconomyInspect.markets(_economy, asked)
	assert_true(reply.result.ok, reply.result.message)
	assert_eq(reply.markets.size(), 2, "Só os dois que têm mercado.")
	assert_lt(reply.markets[0].market_id, reply.markets[1].market_id, "E em ordem crescente de mercado, não na ordem em que foram pedidos.")
	var sites: BridgeEconomyReplies.EconomySitesReply = BridgeEconomyInspect.sites(_economy, [NO_SUCH_SETTLEMENT] as Array[String])
	assert_true(sites.result.ok, "Sem local de produção no assentamento: lista vazia, com sucesso.")
	assert_eq(sites.sites.size(), 0)


func test_the_settlement_ids_come_from_the_places_without_repeats_in_ascending_order() -> void:
	var places: Array[Place] = []
	for settlement_id: String in [SETTLEMENTS[2], SETTLEMENTS[0], SETTLEMENTS[2], SETTLEMENTS[1], SETTLEMENTS[0]]:
		places.append(Place.new("p_%d" % places.size(), settlement_id, Place.KIND_HOME, Vector3.ZERO, 1))
	assert_eq(BridgeEconomyInspect.settlement_ids_of(places), SETTLEMENTS, "Distintos e em ordem crescente.")
	assert_eq(BridgeEconomyInspect.settlement_ids_of([] as Array[Place]), [] as Array[String], "Sem locais, sem assentamentos.")


func test_the_replies_are_copies_and_changing_one_does_not_change_the_economy() -> void:
	var overview: BridgeEconomyReplies.EconomyOverviewReply = _bridge.peek_economy_overview()
	var money_before: int = _economy.peek_conservation().sum
	overview.money_sum += 1000
	overview.goods.clear()
	overview.problems.append("intruso")
	var markets: BridgeEconomyReplies.EconomyMarketsReply = _bridge.peek_economy_markets()
	var first_price: int = markets.markets[0].rows[0].price
	markets.markets[0].rows[0].price += 99
	markets.markets.clear()
	var sites: BridgeEconomyReplies.EconomySitesReply = _bridge.peek_economy_sites()
	sites.sites[0].workers_assigned += 5
	sites.sites.clear()
	assert_eq(_economy.peek_conservation().sum, money_before, "O dinheiro da economia não mudou.")
	var again: BridgeEconomyReplies.EconomyOverviewReply = _bridge.peek_economy_overview()
	assert_eq(again.money_sum, money_before)
	assert_eq(again.problems.size(), 0)
	assert_gt(again.goods.size(), 0)
	assert_eq(_bridge.peek_economy_markets().markets[0].rows[0].price, first_price, "O preço de uma nova consulta é o de antes.")
	assert_eq(_bridge.peek_economy_sites().sites.size(), SITE_COUNT)


func test_a_bridge_without_a_game_or_without_the_economy_fails_with_codes() -> void:
	var without_host: SimBridge = SimBridge.new(null, null)
	assert_eq(without_host.peek_economy_overview().result.code, SimBridge.CODE_NO_GAME)
	assert_eq(without_host.peek_economy_markets().result.code, SimBridge.CODE_NO_GAME)
	assert_eq(without_host.peek_economy_sites().result.code, SimBridge.CODE_NO_GAME)
	var idle_host: SimulationHostNode = SimulationHostNode.new()
	var without_game: SimBridge = SimBridge.new(idle_host, null)
	assert_eq(without_game.peek_economy_overview().result.code, SimBridge.CODE_NO_GAME, "Host sem jogo iniciado.")
	idle_host.free()
	var bare: SimulationHostNode = SimulationHostNode.new()
	bare.start_new_game(1)
	assert_null(bare.economy, "Sem terreno o jogo nasce sem economia.")
	var without_economy: SimBridge = SimBridge.new(bare, null)
	for reply_result: Result in [without_economy.peek_economy_overview().result, without_economy.peek_economy_markets().result, without_economy.peek_economy_sites().result]:
		assert_false(reply_result.ok)
		assert_eq(reply_result.code, SimBridge.CODE_NO_ECONOMY)
		assert_string_contains(reply_result.message, "start_new_game")
	bare.runner.finish()
	bare.free()


func test_the_inspection_queries_write_nothing_in_the_simulation() -> void:
	_step(ONE_DAY_AND_MORE_STEPS)
	var world: World = _host.runner.world
	var hash_before: String = world.state_hash()
	var save_before: Dictionary = _economy.serialize()
	var summary_before: Dictionary = world.debug_summary()
	var rng_before: Dictionary = world.context.rng.debug_summary()
	var ids_before: Dictionary = world.context.ids.debug_summary()
	for _round: int in 3:
		_bridge.peek_economy_overview()
		_bridge.peek_economy_markets()
		_bridge.peek_economy_sites()
	assert_eq(world.state_hash(), hash_before, "O hash do mundo não muda.")
	assert_eq(_economy.serialize(), save_before, "O save da economia não muda.")
	assert_eq(world.debug_summary(), summary_before, "O resumo de depuração do mundo (relógio, eventos, módulos) não muda.")
	assert_eq(world.context.rng.debug_summary(), rng_before, "Nenhum sorteio é gasto.")
	assert_eq(world.context.ids.debug_summary(), ids_before, "Nenhum ID é gerado.")
