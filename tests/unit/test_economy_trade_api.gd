extends GutTest
## LW-091b: a porta do comércio no `EconomyModule` (`request_trade`, `peek_quote`, `peek_terms`; docs/modules/economy.md, seções 5 e 10): a ordem pelo módulo é a mesma do `TradeEngine` (atômica, mesmos códigos), a cotação é a
## mesma conta, a regra de comércio entra pelo construtor (`EconomyDefinitions.trade_rules`) e o estado depois das ordens vai e volta pelo save. O módulo recebe um bloco montado pelas peças soltas (a porta não cria
## dinheiro nem bem). Usa os dados REAIS (data/economy): mercado do povoado A (dono 1) e um NPC (dono 2) com 200 de saldo.

const SETTLEMENT_A: String = "test_settlement_a"
const MARKET: int = 1
const NPC: int = 2
const WORLD_SEED: int = 61


class BanBread:
	extends TradeRules

	func peek_terms(good_id: String, _market_id: int, _actor_id: int) -> TradeTerms:
		return TradeTerms.new(good_id == "bread", 0, good_id == "tool")


func _definitions(rules: TradeRules = null) -> EconomyDefinitions:
	var setup: EconomySetup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR)
	assert_true(setup.result.ok, setup.result.message)
	var definitions: EconomyDefinitions = setup.definitions
	definitions.trade_rules = rules
	return definitions


func _through_json(data: Dictionary) -> Dictionary:
	# Variant: o JSON devolve qualquer tipo; aqui o formato é conhecido (um objeto).
	var parsed: Variant = JSON.parse_string(JSON.stringify(data))
	assert_eq(typeof(parsed), TYPE_DICTIONARY)
	var copy: Dictionary = parsed
	return copy


## O bloco `economy` com o mercado A (3000 de saldo e o estoque inicial) e um NPC com 200 de saldo.
func _block(definitions: EconomyDefinitions) -> Dictionary:
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
	return _through_json({EconomyModule.KEY_OWNERS: book.serialize(), EconomyModule.KEY_LEDGER: ledger.serialize(), EconomyModule.KEY_GOODS: goods.serialize(), EconomyModule.KEY_MARKETS: markets.serialize()})


func _module(rules: TradeRules = null) -> EconomyModule:
	var definitions: EconomyDefinitions = _definitions(rules)
	var module: EconomyModule = EconomyModule.new(false, definitions)
	var loaded: Result = module.on_load(_block(definitions))
	assert_true(loaded.ok, loaded.message)
	return module


func test_a_trade_through_the_module_moves_money_and_goods_exactly_as_quoted() -> void:
	var module: EconomyModule = _module()
	var quote: EconomyReplies.QuoteQuery = module.peek_quote(NPC, MARKET, "bread", 5, TradeEngine.SIDE_BUY)
	assert_true(quote.result.ok, quote.result.message)
	assert_eq([quote.total, quote.tariff, quote.average_price], [quote.total, 0, IntMath.floor_div(quote.total, 5)], "O preço médio é o total dividido pela quantidade (para baixo).")
	var done: EconomyReplies.TradeResult = module.request_trade(NPC, MARKET, "bread", 5, TradeEngine.SIDE_BUY)
	assert_true(done.result.ok, done.result.message)
	assert_eq([done.quantity, done.total, done.tariff], [5, quote.total, 0], "A ordem custa o que a cotação disse.")
	assert_eq([module.peek_balance(NPC).balance, module.peek_balance(MARKET).balance], [200 - quote.total, 3000 + quote.total])
	assert_eq([module.peek_stock(MARKET, "bread").value, module.peek_inventory(NPC).rows], [55, [{"good_id": "bread", "quantity": 5}] as Array[Dictionary]])
	var sold: EconomyReplies.TradeResult = module.request_trade(NPC, MARKET, "bread", 5, TradeEngine.SIDE_SELL)
	assert_true(sold.result.ok, sold.result.message)
	assert_true(quote.total - sold.total >= 5, "Comprar e vender 5 na hora dá prejuízo de pelo menos 5.")
	assert_true(module.peek_conservation().ok and module.peek_goods_conservation().ok, "O dinheiro e os bens seguem conservados.")
	assert_eq(module.validate(), [] as Array[String])


func test_failures_through_the_module_keep_the_codes_and_change_nothing() -> void:
	var module: EconomyModule = _module()
	var before: Dictionary = module.serialize()
	var cases: Array[Dictionary] = [
		{"label": "mercado inexistente", "reply": module.request_trade(NPC, 99, "bread", 1, "buy"), "code": EconomyCodes.UNKNOWN_MARKET},
		{"label": "bem inexistente", "reply": module.request_trade(NPC, MARKET, "gold", 1, "buy"), "code": EconomyCodes.UNKNOWN_GOOD},
		{"label": "quantidade zero", "reply": module.request_trade(NPC, MARKET, "bread", 0, "buy"), "code": EconomyCodes.BAD_QUANTITY},
		{"label": "ator inexistente", "reply": module.request_trade(99, MARKET, "bread", 1, "buy"), "code": EconomyCodes.UNKNOWN_OWNER},
		{"label": "estoque insuficiente", "reply": module.request_trade(NPC, MARKET, "ore", 11, "buy"), "code": EconomyCodes.INSUFFICIENT_STOCK},
		{"label": "venda do que não tem", "reply": module.request_trade(NPC, MARKET, "bread", 1, "sell"), "code": EconomyCodes.INSUFFICIENT_GOODS},
		{"label": "peso demais para o NPC", "reply": module.request_trade(NPC, MARKET, "wood", 9, "buy"), "code": EconomyCodes.CAPACITY_EXCEEDED},
	]
	for test_case: Dictionary in cases:
		var reply: EconomyReplies.TradeResult = test_case["reply"]
		assert_eq(reply.result.code, test_case["code"], test_case["label"])
		assert_eq([reply.quantity, reply.total], [0, 0], "%s: nada foi negociado." % test_case["label"])
	assert_eq(module.serialize(), before, "Nenhuma falha muda o estado.")
	assert_eq(module.peek_quote(NPC, 99, "bread", 1, "buy").result.code, EconomyCodes.UNKNOWN_MARKET)
	var bare: EconomyModule = EconomyModule.new()
	assert_eq(bare.request_trade(NPC, MARKET, "bread", 1, "buy").result.code, EconomyCodes.UNKNOWN_MARKET, "Sem mercados, nenhum comércio.")
	assert_eq(bare.peek_terms("bread", MARKET, NPC).result.code, EconomyCodes.UNKNOWN_MARKET)


func test_the_trade_rule_comes_from_the_constructor_and_changes_the_result_without_touching_the_economy() -> void:
	var neutral: EconomyModule = _module()
	var terms: EconomyReplies.TermsQuery = neutral.peek_terms("bread", MARKET, NPC)
	assert_true(terms.result.ok)
	assert_eq([terms.banned, terms.tariff_bp, terms.needs_license], [false, 0, false], "Sem regra no construtor vale a neutra.")
	var strict: EconomyModule = _module(BanBread.new())
	var banned: EconomyReplies.TermsQuery = strict.peek_terms("bread", MARKET, NPC)
	assert_eq([banned.banned, strict.peek_terms("tool", MARKET, NPC).needs_license], [true, true])
	assert_eq(strict.request_trade(NPC, MARKET, "bread", 1, "buy").result.code, EconomyCodes.TRADE_BANNED)
	assert_eq(strict.peek_quote(NPC, MARKET, "bread", 1, "buy").result.code, EconomyCodes.TRADE_BANNED)
	assert_true(strict.request_trade(NPC, MARKET, "grain", 2, "buy").result.ok, "Os outros bens seguem livres.")
	assert_eq(strict.peek_terms("gold", MARKET, NPC).result.code, EconomyCodes.UNKNOWN_GOOD)


func test_the_state_after_trades_survives_json_and_a_loaded_module_keeps_trading() -> void:
	var module: EconomyModule = _module()
	assert_true(module.request_trade(NPC, MARKET, "bread", 4, "buy").result.ok)
	assert_true(module.request_trade(NPC, MARKET, "grain", 6, "buy").result.ok)
	var saved: Dictionary = _through_json(module.serialize())
	var restored: EconomyModule = EconomyModule.new(false, _definitions())
	assert_true(restored.on_load(saved).ok)
	assert_eq(_through_json(restored.serialize()), saved, "O estado depois das ordens vai e volta igual.")
	var first: EconomyReplies.TradeResult = module.request_trade(NPC, MARKET, "bread", 3, "sell")
	var second: EconomyReplies.TradeResult = restored.request_trade(NPC, MARKET, "bread", 3, "sell")
	assert_eq([second.result.ok, second.total], [first.result.ok, first.total], "O módulo carregado faz a mesma ordem pelo mesmo preço.")
	assert_eq(restored.serialize(), module.serialize())
