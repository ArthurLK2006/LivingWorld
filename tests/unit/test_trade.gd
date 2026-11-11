extends GutTest
## LW-091: as regras de comércio (`TradeRules`, `NeutralTradeRules`) e o `TradeEngine` (docs/modules/economy.md, seção 5): a ordem é ATÔMICA (tudo ou nada), cada falha devolve o código certo sem mudar nada, comprar e vender
## na hora dá prejuízo, uma regra trocada em teste muda o resultado sem tocar na economia e o dinheiro e os bens ficam conservados. Usa os dados REAIS (data/economy): mercado do povoado A (dono 1), um NPC comprador (dono 2,
## capacidade 40) e um jogador (dono 3, capacidade 60). Os totais esperados são contas à mão com as constantes reais (valor-base do pão 10, alvo 60, spread 10%, ordem de até 50).

const SETTLEMENT_A: String = "test_settlement_a"
const MARKET: int = 1
const NPC: int = 2
const PLAYER: int = 3
const WORLD_SEED: int = 51
const STREAM: String = "trade_test"


class BanBread:
	extends TradeRules

	func peek_terms(good_id: String, _market_id: int, _actor_id: int) -> TradeTerms:
		return TradeTerms.new(good_id == "bread")


class Tariff:
	extends TradeRules

	func peek_terms(_good_id: String, _market_id: int, _actor_id: int) -> TradeTerms:
		return TradeTerms.new(false, 500)


class Rig:
	extends RefCounted

	var book: OwnerBook
	var ledger: Ledger
	var goods: GoodsStore
	var markets: MarketBook
	var engine: TradeEngine
	var params: PriceParams


func _rig(rules: TradeRules = null) -> Rig:
	var goods: GoodsLoader.LoadResult = GoodsLoader.load_dir(GoodsLoader.DEFAULT_DIR)
	var loaded: MarketLoader.LoadResult = MarketLoader.load_dir(GoodsLoader.DEFAULT_DIR)
	assert_true(goods.result.ok and loaded.result.ok, goods.result.message + loaded.result.message)
	var rig: Rig = Rig.new()
	rig.params = loaded.params
	rig.book = OwnerBook.new()
	rig.book.open_owner(MARKET, "market")
	rig.book.open_owner(NPC, "npc")
	rig.book.open_owner(PLAYER, "player")
	rig.ledger = Ledger.new(rig.book)
	rig.goods = GoodsStore.new(rig.book, goods.goods, goods.kinds)
	assert_true(rig.ledger.mint(MARKET, 3000, Ledger.REASON_GAME_START).ok)
	assert_true(rig.ledger.mint(NPC, 200, Ledger.REASON_GAME_START).ok)
	assert_true(rig.ledger.mint(PLAYER, 500, Ledger.REASON_GAME_START).ok)
	for target: MarketTargetDef in loaded.targets:
		if target.settlement_id == SETTLEMENT_A:
			assert_true(rig.goods.create(MARKET, target.good_id, target.initial_stock, GoodsStore.REASON_GAME_START).ok)
	rig.markets = MarketBook.new(rig.book, rig.goods, goods.goods, loaded.targets, loaded.params)
	rig.markets.register_market(SETTLEMENT_A, MARKET)
	rig.engine = TradeEngine.new(rig.book, rig.ledger, rig.goods, rig.markets, rules if rules != null else NeutralTradeRules.new(), loaded.params)
	return rig


## Tudo o que dá para ver de fora: saldos, inventários e o estado dos mercados.
func _snapshot(rig: Rig) -> Array:
	var rows: Array = []
	for owner_id: int in [MARKET, NPC, PLAYER]:
		rows.append([rig.ledger.balance_of(owner_id), rig.goods.inventory_rows(owner_id)])
	return [rows, rig.ledger.totals_rows(), rig.goods.conservation_rows(), rig.markets.serialize()]


func test_a_buy_moves_the_goods_and_exactly_the_quoted_money_and_the_market_gets_paid() -> void:
	var rig: Rig = _rig()
	var expected: int = PriceMath.quote_buy(10, 10, 60, 60, 60, 5, rig.params)
	var quoted: TradeEngine.Outcome = rig.engine.quote(MARKET, "bread", 5, TradeEngine.SIDE_BUY)
	assert_true(quoted.result.ok, quoted.result.message)
	assert_eq([quoted.quantity, quoted.total, quoted.tariff], [5, expected, 0], "A cotação é a soma por degrau, sem tarifa.")
	var before: Array = _snapshot(rig)
	assert_eq(rig.engine.quote(MARKET, "bread", 5, TradeEngine.SIDE_BUY).total, expected)
	assert_eq(_snapshot(rig), before, "Cotar não muda nada.")
	var done: TradeEngine.Outcome = rig.engine.execute(NPC, MARKET, "bread", 5, TradeEngine.SIDE_BUY)
	assert_true(done.result.ok, done.result.message)
	assert_eq([done.quantity, done.total], [5, expected])
	assert_eq([rig.ledger.balance_of(NPC), rig.ledger.balance_of(MARKET)], [200 - expected, 3000 + expected], "O dinheiro muda de mãos pelo total, uma vez.")
	assert_eq([rig.goods.quantity_of(NPC, "bread"), rig.goods.quantity_of(MARKET, "bread")], [5, 55])
	assert_true(rig.ledger.is_conserved() and rig.goods.is_conserved(), "Nada é criado nem destruído.")
	assert_eq(rig.ledger.totals_rows(), [{"reason": "game_start", "moved": 0, "created": 3700, "destroyed": 0}, {"reason": "trade", "moved": expected, "created": 0, "destroyed": 0}] as Array[Dictionary])


func test_a_sell_gives_the_bid_side_and_respects_the_buy_cap() -> void:
	var rig: Rig = _rig()
	assert_true(rig.goods.create(PLAYER, "metal", 11, GoodsStore.REASON_PRODUCED).ok)
	var expected: int = PriceMath.quote_sell(rig.markets.price_of(MARKET, "metal"), 16, 10, 10, 10, 10, rig.params)
	var done: TradeEngine.Outcome = rig.engine.execute(PLAYER, MARKET, "metal", 10, TradeEngine.SIDE_SELL)
	assert_true(done.result.ok, done.result.message)
	assert_eq(done.total, expected)
	assert_eq([rig.ledger.balance_of(PLAYER), rig.ledger.balance_of(MARKET), rig.goods.quantity_of(MARKET, "metal"), rig.goods.quantity_of(PLAYER, "metal")], [500 + expected, 3000 - expected, 20, 1], "O mercado compra até o teto (alvo 10 × 20000 ÷ 10000 = 20).")
	var full: TradeEngine.Outcome = rig.engine.execute(PLAYER, MARKET, "metal", 1, TradeEngine.SIDE_SELL)
	assert_eq(full.result.code, EconomyCodes.MARKET_FULL, "Acima do teto o mercado não compra.")
	assert_true(rig.ledger.is_conserved() and rig.goods.is_conserved())


func test_every_failure_returns_the_right_code_and_changes_nothing() -> void:
	var rig: Rig = _rig()
	rig.book.open_owner(4, "npc")
	rig.book.close_owner(4)
	rig.ledger.mint(4, 100, Ledger.REASON_GAME_START)
	var poor: int = 5
	rig.book.open_owner(poor, "npc")
	var before: Array = _snapshot(rig)
	var cases: Array[Dictionary] = [
		{"label": "mercado inexistente", "outcome": rig.engine.execute(NPC, 99, "bread", 1, "buy"), "code": EconomyCodes.UNKNOWN_MARKET},
		{"label": "bem inexistente", "outcome": rig.engine.execute(NPC, MARKET, "gold", 1, "buy"), "code": EconomyCodes.UNKNOWN_GOOD},
		{"label": "lado inexistente", "outcome": rig.engine.execute(NPC, MARKET, "bread", 1, "swap"), "code": EconomyCodes.DATA_INVALID},
		{"label": "quantidade zero", "outcome": rig.engine.execute(NPC, MARKET, "bread", 0, "buy"), "code": EconomyCodes.BAD_QUANTITY},
		{"label": "quantidade acima da ordem máxima", "outcome": rig.engine.execute(NPC, MARKET, "bread", rig.params.max_order_quantity + 1, "buy"), "code": EconomyCodes.BAD_QUANTITY},
		{"label": "ator inexistente", "outcome": rig.engine.execute(99, MARKET, "bread", 1, "buy"), "code": EconomyCodes.UNKNOWN_OWNER},
		{"label": "ator fechado", "outcome": rig.engine.execute(4, MARKET, "bread", 1, "buy"), "code": EconomyCodes.OWNER_CLOSED},
		{"label": "estoque insuficiente na compra", "outcome": rig.engine.execute(PLAYER, MARKET, "ore", 11, "buy"), "code": EconomyCodes.INSUFFICIENT_STOCK},
		{"label": "ator sem dinheiro", "outcome": rig.engine.execute(poor, MARKET, "bread", 3, "buy"), "code": EconomyCodes.INSUFFICIENT_FUNDS},
		{"label": "compra maior que o estoque de ferramentas", "outcome": rig.engine.execute(PLAYER, MARKET, "tool", 31, "buy"), "code": EconomyCodes.INSUFFICIENT_STOCK},
		{"label": "venda do que o ator não tem", "outcome": rig.engine.execute(NPC, MARKET, "bread", 2, "sell"), "code": EconomyCodes.INSUFFICIENT_GOODS},
	]
	for test_case: Dictionary in cases:
		var outcome: TradeEngine.Outcome = test_case["outcome"]
		assert_false(outcome.result.ok, "%s: deveria falhar." % test_case["label"])
		assert_eq(outcome.result.code, test_case["code"], test_case["label"])
		assert_eq([outcome.quantity, outcome.total, outcome.tariff], [0, 0, 0], "%s: nada foi negociado." % test_case["label"])
	assert_eq(_snapshot(rig), before, "Nenhuma falha muda saldo, bem ou mercado: a ordem é atômica.")
	var heavy: TradeEngine.Outcome = rig.engine.execute(PLAYER, MARKET, "wood", 13, TradeEngine.SIDE_BUY)
	assert_eq(heavy.result.code, EconomyCodes.CAPACITY_EXCEEDED, "13 de madeira pesam 65 e o jogador carrega até 60.")
	rig.ledger.burn(MARKET, 2990, Ledger.REASON_SALARY)
	rig.goods.create(NPC, "bread", 5, GoodsStore.REASON_PRODUCED)
	var no_funds: TradeEngine.Outcome = rig.engine.execute(NPC, MARKET, "bread", 5, TradeEngine.SIDE_SELL)
	assert_eq(no_funds.result.code, EconomyCodes.MARKET_NO_FUNDS, "O mercado sem dinheiro não paga a venda.")
	assert_eq(rig.goods.quantity_of(NPC, "bread"), 5, "E a venda não levou o pão.")


func test_buying_and_selling_the_same_quantity_at_once_loses_at_least_the_quantity() -> void:
	var rig: Rig = _rig()
	rig.ledger.mint(NPC, 800, Ledger.REASON_GAME_START)
	for quantity: int in [1, 3, 8]:
		var start: int = rig.ledger.balance_of(NPC)
		assert_true(rig.engine.execute(NPC, MARKET, "bread", quantity, TradeEngine.SIDE_BUY).result.ok)
		assert_true(rig.engine.execute(NPC, MARKET, "bread", quantity, TradeEngine.SIDE_SELL).result.ok)
		assert_true(start - rig.ledger.balance_of(NPC) >= quantity, "Comprar e vender %d na hora dá prejuízo de pelo menos %d." % [quantity, quantity])
	assert_eq(rig.goods.quantity_of(NPC, "bread"), 0)
	assert_true(rig.ledger.is_conserved() and rig.goods.is_conserved())


func test_a_replaced_rule_changes_the_result_without_touching_the_economy() -> void:
	var banned: Rig = _rig(BanBread.new())
	var refused: TradeEngine.Outcome = banned.engine.execute(NPC, MARKET, "bread", 1, TradeEngine.SIDE_BUY)
	assert_eq(refused.result.code, EconomyCodes.TRADE_BANNED, "A regra que proíbe o pão recusa a ordem.")
	assert_eq(banned.engine.quote(MARKET, "bread", 1, TradeEngine.SIDE_SELL).result.code, EconomyCodes.TRADE_BANNED, "E a cotação também.")
	assert_true(banned.engine.execute(NPC, MARKET, "grain", 1, TradeEngine.SIDE_BUY).result.ok, "Os outros bens seguem livres.")
	var taxed: Rig = _rig(Tariff.new())
	var done: TradeEngine.Outcome = taxed.engine.execute(NPC, MARKET, "bread", 5, TradeEngine.SIDE_BUY)
	assert_true(done.result.ok, done.result.message)
	assert_eq(done.tariff, IntMath.floor_div(done.total * 500, 10000), "A tarifa pedida pela regra é calculada e devolvida.")
	assert_eq(taxed.ledger.balance_of(NPC), 200 - done.total, "Mas não é cobrada na Fase 3: o ator paga só o total.")
	var neutral: TradeTerms = NeutralTradeRules.new().peek_terms("bread", MARKET, NPC)
	assert_eq([neutral.banned, neutral.tariff_bp, neutral.needs_license], [false, 0, false], "A regra neutra: nada proibido, tarifa 0, sem licença.")


func test_hundreds_of_random_trades_keep_the_money_and_the_goods_conserved() -> void:
	var rig: Rig = _rig()
	var rng: WorldRng = WorldRng.new(WORLD_SEED)
	var good_ids: Array[String] = rig.markets.traded_goods(SETTLEMENT_A)
	var done: int = 0
	var refused: int = 0
	for _step: int in 400:
		var good_id: String = good_ids[rng.range_int(STREAM, 0, good_ids.size() - 1)]
		var actor: int = NPC if rng.range_int(STREAM, 0, 1) == 0 else PLAYER
		var side: String = TradeEngine.SIDE_BUY if rng.range_int(STREAM, 0, 1) == 0 else TradeEngine.SIDE_SELL
		var before: Array = _snapshot(rig)
		var outcome: TradeEngine.Outcome = rig.engine.execute(actor, MARKET, good_id, rng.range_int(STREAM, 1, 12), side)
		if outcome.result.ok:
			done += 1
		else:
			refused += 1
			assert_eq(_snapshot(rig), before, "A ordem recusada não mudou nada.")
		assert_true(rig.ledger.is_conserved() and rig.goods.is_conserved(), "A conservação fecha a cada ordem.")
		assert_eq(rig.goods.validate(), [] as Array[String])
	assert_true(done > 30 and refused > 30, "O sorteio tem ordens feitas (%d) e recusadas (%d)." % [done, refused])
