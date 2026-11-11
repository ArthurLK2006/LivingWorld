extends GutTest
## LW-092e (pedido de Arthur em 11/11/2026): (a) a tarifa que a regra pede é `ceil_div(total × tariff_bp, 10000)` com mínimo 1 quando `tariff_bp > 0` (antes era para baixo e uma ordem pequena pagava 0), continua só calculada e devolvida,
## sem cobrança; (b) `peek_quote` recebe o ATOR, porque a regra de comércio pode depender de quem compra (proibição e tarifa por ator). Usa os dados REAIS (data/economy): mercado A (dono 1), NPC (dono 2, 200) e um ator (dono 3) que
## não abriu conta. Conta à mão: uma unidade de pão (preço 10, spread de 10%) custa 11 na compra.

const SETTLEMENT_A: String = "test_settlement_a"
const MARKET: int = 1
const NPC: int = 2
const OTHER_ACTOR: int = 3
const WORLD_SEED: int = 67


class FlatTariff:
	extends TradeRules

	var tariff_basis_points: int

	func _init(basis_points: int) -> void:
		tariff_basis_points = basis_points

	func peek_terms(_good_id: String, _market_id: int, _actor_id: int) -> TradeTerms:
		return TradeTerms.new(false, tariff_basis_points)


## Só o NPC é taxado (30%) e só o NPC fica proibido de comprar `tool`.
class ByActor:
	extends TradeRules

	func peek_terms(good_id: String, _market_id: int, actor_id: int) -> TradeTerms:
		return TradeTerms.new(actor_id == NPC and good_id == "tool", 3000 if actor_id == NPC else 0)


func _module(rules: TradeRules) -> EconomyModule:
	var setup: EconomySetup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR)
	assert_true(setup.result.ok, setup.result.message)
	var definitions: EconomyDefinitions = setup.definitions
	definitions.trade_rules = rules
	var book: OwnerBook = OwnerBook.new()
	book.open_owner(MARKET, MarketBook.KIND_MARKET)
	book.open_owner(NPC, "npc")
	var ledger: Ledger = Ledger.new(book)
	ledger.mint(MARKET, 3000, Ledger.REASON_GAME_START)
	ledger.mint(NPC, 200, Ledger.REASON_GAME_START)
	var goods: GoodsStore = GoodsStore.new(book, definitions.goods, definitions.kinds)
	for target: MarketTargetDef in definitions.market_targets:
		if target.settlement_id == SETTLEMENT_A:
			goods.create(MARKET, target.good_id, target.initial_stock, GoodsStore.REASON_GAME_START)
	var markets: MarketBook = MarketBook.new(book, goods, definitions.goods, definitions.market_targets, definitions.price_params)
	markets.register_market(SETTLEMENT_A, MARKET)
	var block: Dictionary = {EconomyModule.KEY_OWNERS: book.serialize(), EconomyModule.KEY_LEDGER: ledger.serialize(), EconomyModule.KEY_GOODS: goods.serialize(), EconomyModule.KEY_MARKETS: markets.serialize()}
	# Variant: o JSON devolve qualquer tipo; aqui o formato é conhecido (um objeto).
	var parsed: Variant = JSON.parse_string(JSON.stringify(block))
	var saved: Dictionary = parsed
	var module: EconomyModule = EconomyModule.new(false, definitions)
	var loaded: Result = module.on_load(saved)
	assert_true(loaded.ok, loaded.message)
	return module


func test_the_tariff_rounds_up_with_a_minimum_of_one_and_is_still_not_charged() -> void:
	var cases: Array[Dictionary] = [
		{"bp": 0, "tariff": 0, "label": "sem tarifa, 0"},
		{"bp": -30000, "tariff": 0, "label": "tarifa negativa (regra inválida) não vira crédito: conta como sem tarifa"},
		{"bp": 1, "tariff": 1, "label": "11 × 1 / 10000 = 0,0011: sobe a 1 (o mínimo)"},
		{"bp": 3000, "tariff": 4, "label": "11 × 3000 / 10000 = 3,3: sobe a 4 (para baixo seria 3)"},
		{"bp": 10000, "tariff": 11, "label": "100%: 11, exato"},
	]
	for test_case: Dictionary in cases:
		var module: EconomyModule = _module(FlatTariff.new(test_case["bp"]))
		var quote: EconomyReplies.QuoteQuery = module.peek_quote(NPC, MARKET, "bread", 1, TradeEngine.SIDE_BUY)
		assert_true(quote.result.ok, quote.result.message)
		assert_eq([quote.total, quote.tariff], [11, test_case["tariff"]], test_case["label"])
		var done: EconomyReplies.TradeResult = module.request_trade(NPC, MARKET, "bread", 1, TradeEngine.SIDE_BUY)
		assert_eq([done.total, done.tariff], [11, test_case["tariff"]], "A ordem devolve a mesma tarifa da cotação.")
		assert_eq(module.peek_balance(NPC).balance, 200 - 11, "Mas a tarifa não é cobrada: o ator paga só o total.")
	var small: EconomyModule = _module(FlatTariff.new(1))
	var paid: int = 0
	for _order: int in 5:
		paid += small.request_trade(NPC, MARKET, "bread", 1, TradeEngine.SIDE_BUY).tariff
	assert_eq(paid, 5, "Dividir a compra em cinco ordens pequenas paga a tarifa em cada uma, em vez de escapar dela.")


func test_the_quote_is_for_the_actor_because_the_rule_can_depend_on_who_buys() -> void:
	var module: EconomyModule = _module(ByActor.new())
	var taxed: EconomyReplies.QuoteQuery = module.peek_quote(NPC, MARKET, "bread", 1, TradeEngine.SIDE_BUY)
	var free: EconomyReplies.QuoteQuery = module.peek_quote(OTHER_ACTOR, MARKET, "bread", 1, TradeEngine.SIDE_BUY)
	assert_eq([taxed.result.ok, taxed.tariff, free.result.ok, free.tariff], [true, 4, true, 0], "O NPC é taxado e o outro ator não.")
	assert_eq(module.peek_quote(NPC, MARKET, "tool", 1, TradeEngine.SIDE_BUY).result.code, EconomyCodes.TRADE_BANNED, "Para o NPC o `tool` é proibido...")
	assert_true(module.peek_quote(OTHER_ACTOR, MARKET, "tool", 1, TradeEngine.SIDE_BUY).result.ok, "...e para o outro ator não.")
	assert_eq(module.request_trade(NPC, MARKET, "tool", 1, TradeEngine.SIDE_BUY).result.code, EconomyCodes.TRADE_BANNED, "A ordem diz o mesmo da cotação.")
	assert_eq(module.peek_quote(NPC, 99, "bread", 1, TradeEngine.SIDE_BUY).result.code, EconomyCodes.UNKNOWN_MARKET)
