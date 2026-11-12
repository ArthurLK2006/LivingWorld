extends GutTest
## LW-090b: o estado dos mercados (`MarketBook`) e os eventos de preço e de escassez (docs/modules/economy.md, seção 4; DEC-150 e DEC-177). Usa os dados REAIS (data/economy): o mercado do povoado A, com o dono 1 do tipo `market`.
## Aqui: o preço que nasce do estoque, o passo do fim do dia (suavizado, com histórico curto), `PriceChanged` só acima do limiar, escassez declarada e encerrada uma vez, determinismo e a ida e volta de save.
## Os valores esperados são contas à mão com as constantes reais (piso 0,5, teto 3, suavização 20%, spread 10%, limiar de 10%).

const SETTLEMENT_A: String = "test_settlement_a"
const MARKET: int = 1
const BREAD_BASE: int = 10
const BREAD_TARGET: int = 60


class Rig:
	extends RefCounted

	var book: OwnerBook
	var store: GoodsStore
	var markets: MarketBook
	var params: PriceParams


func _rig() -> Rig:
	var goods: GoodsLoader.LoadResult = GoodsLoader.load_dir(GoodsLoader.DEFAULT_DIR)
	var loaded: MarketLoader.LoadResult = MarketLoader.load_dir(GoodsLoader.DEFAULT_DIR)
	assert_true(goods.result.ok and loaded.result.ok, goods.result.message + loaded.result.message)
	var rig: Rig = Rig.new()
	rig.params = loaded.params
	rig.book = OwnerBook.new()
	assert_true(rig.book.open_owner(MARKET, MarketBook.KIND_MARKET).ok)
	rig.store = GoodsStore.new(rig.book, goods.goods, goods.kinds)
	for target: MarketTargetDef in loaded.targets:
		if target.settlement_id == SETTLEMENT_A:
			assert_true(rig.store.create(MARKET, target.good_id, target.initial_stock, GoodsStore.REASON_GAME_START).ok)
	rig.markets = MarketBook.new(rig.book, rig.store, goods.goods, loaded.targets, loaded.params)
	rig.markets.register_market(SETTLEMENT_A, MARKET)
	return rig


func _set_bread(rig: Rig, quantity: int) -> void:
	var current: int = rig.store.quantity_of(MARKET, "bread")
	if quantity < current:
		assert_true(rig.store.destroy(MARKET, "bread", current - quantity, GoodsStore.REASON_CONSUMED).ok)
	elif quantity > current:
		assert_true(rig.store.create(MARKET, "bread", quantity - current, GoodsStore.REASON_PRODUCED).ok)


func _types(events: Array[SimEvent]) -> Array[String]:
	var types: Array[String] = []
	for event: SimEvent in events:
		types.append(event.type)
	return types


func test_a_registered_market_starts_with_the_price_of_the_stock_and_answers_the_queries() -> void:
	var rig: Rig = _rig()
	var markets: MarketBook = rig.markets
	assert_eq([markets.market_of(SETTLEMENT_A), markets.market_of("test_settlement_b"), markets.settlement_of(MARKET)], [MARKET, IdGenerator.NO_ID, SETTLEMENT_A])
	assert_eq(markets.settlement_ids(), ["test_settlement_a", "test_settlement_b", "test_settlement_c"] as Array[String], "Três povoados com mercado (o C é da LW-097).")
	assert_eq(markets.traded_goods(SETTLEMENT_A).size(), 10)
	assert_true(markets.has_market(MARKET) and markets.is_traded(MARKET, "bread") and not markets.is_traded(MARKET, "gold") and not markets.has_market(99))
	assert_eq([markets.price_of(MARKET, "bread"), markets.ref_stock_of(MARKET, "bread"), markets.target_of(MARKET, "bread"), markets.buy_cap_of(MARKET, "bread")], [BREAD_BASE, BREAD_TARGET, BREAD_TARGET, 120], "Estoque igual ao alvo: fator 1, preço igual ao valor-base.")
	assert_eq([markets.ask_of(MARKET, "bread"), markets.bid_of(MARKET, "bread")], [11, 9], "Spread de 10%: a margem é ceil(10 × 1000 ÷ 20000) = 1 de cada lado.")
	assert_eq(markets.history_of(MARKET, "bread"), [BREAD_BASE] as Array[int])
	assert_eq([markets.price_of(MARKET, "gold"), markets.price_of(99, "bread"), markets.is_in_shortage(MARKET, "bread")], [0, 0, false])
	assert_eq(markets.market_ids(), [MARKET] as Array[int])
	assert_eq(markets.validate(), [] as Array[String])


func test_the_end_of_day_moves_the_price_by_the_smoothing_towards_the_goal_and_keeps_a_short_history() -> void:
	var rig: Rig = _rig()
	_set_bread(rig, 30)
	assert_eq(PriceMath.goal_price(BREAD_BASE, BREAD_TARGET, 30, rig.params), 20, "Estoque pela metade do alvo: o preço-alvo dobra.")
	rig.markets.end_of_day()
	assert_eq([rig.markets.price_of(MARKET, "bread"), rig.markets.ref_stock_of(MARKET, "bread")], [12, 30], "Primeiro dia: 10 + 20% da diferença (2) = 12.")
	rig.markets.end_of_day()
	assert_eq(rig.markets.price_of(MARKET, "bread"), 13, "Segundo dia: 12 + 20% de 8 (1,6, para baixo 1) = 13.")
	var previous: int = 13
	for _day: int in 20:
		rig.markets.end_of_day()
		var price: int = rig.markets.price_of(MARKET, "bread")
		assert_true(price >= previous and price <= 20, "O preço sobe devagar e nunca passa do alvo.")
		previous = price
	assert_eq(rig.markets.price_of(MARKET, "bread"), 20, "Chega ao alvo e fica.")
	assert_eq(rig.markets.history_of(MARKET, "bread").size(), rig.params.history_days, "O histórico guarda só os últimos dias.")
	assert_eq(rig.markets.history_of(MARKET, "bread")[rig.params.history_days - 1], 20)
	_set_bread(rig, 240)
	rig.markets.end_of_day()
	assert_eq(rig.markets.price_of(MARKET, "bread"), 17, "Estoque alto derruba o alvo ao piso (5) e o preço desce 20% da diferença (15 × 0,2 = 3): 20 − 3 = 17.")


func test_price_changed_is_published_only_above_the_significant_change_since_the_last_published_price() -> void:
	var rig: Rig = _rig()
	_set_bread(rig, 30)
	var first: Array[SimEvent] = rig.markets.end_of_day()
	assert_eq(_types(first), ["PriceChanged"], "10 para 12 é uma variação de 20%, acima do limiar de 10%.")
	var changed: PriceChanged = first[0]
	assert_eq([changed.market_id, changed.good_id, changed.old_price, changed.new_price], [MARKET, "bread", 10, 12])
	assert_eq(_types(rig.markets.end_of_day()), [] as Array[String], "12 para 13 é menos de 10% do último preço publicado (12): nenhum evento.")
	var third: Array[SimEvent] = rig.markets.end_of_day()
	assert_eq(_types(third), ["PriceChanged"], "Para 14 a variação sobre o último publicado (12) passa de 10%.")
	assert_eq([(third[0] as PriceChanged).old_price, (third[0] as PriceChanged).new_price], [12, 14], "O evento sai com o último preço PUBLICADO, não o de ontem.")
	assert_eq(_types(rig.markets.end_of_day()).size(), 0, "14 para 15 não chega a 10% de 14.")


func test_a_shortage_is_declared_once_after_the_configured_days_and_ended_once_when_the_stock_recovers() -> void:
	var rig: Rig = _rig()
	_set_bread(rig, 10)
	var shortage_days: int = rig.params.shortage_days
	for day: int in range(1, shortage_days):
		for event: SimEvent in rig.markets.end_of_day():
			assert_ne(event.type, "ShortageDeclared", "Dia %d: ainda dentro do prazo." % day)
	assert_false(rig.markets.is_in_shortage(MARKET, "bread"))
	var declared: Array[ShortageDeclared] = []
	for event: SimEvent in rig.markets.end_of_day():
		if event is ShortageDeclared:
			declared.append(event)
	assert_eq(declared.size(), 1, "No dia %d a escassez é declarada." % shortage_days)
	assert_eq([declared[0].market_id, declared[0].good_id, declared[0].stock, declared[0].target_stock, declared[0].severity], [MARKET, "bread", 10, BREAD_TARGET, 84], "Gravidade = 100 − 100 × 10 ÷ 60 = 84.")
	assert_true(rig.markets.is_in_shortage(MARKET, "bread"))
	for event: SimEvent in rig.markets.end_of_day():
		assert_ne(event.type, "ShortageDeclared", "Uma vez só por escassez.")
	_set_bread(rig, BREAD_TARGET)
	var ended: Array[ShortageEnded] = []
	for event: SimEvent in rig.markets.end_of_day():
		if event is ShortageEnded:
			ended.append(event)
	assert_eq(ended.size(), 1)
	assert_eq([ended[0].market_id, ended[0].good_id, ended[0].days_in_shortage], [MARKET, "bread", shortage_days + 1], "Durou os dias abaixo do limiar, contados um a um.")
	assert_false(rig.markets.is_in_shortage(MARKET, "bread"))
	for event: SimEvent in rig.markets.end_of_day():
		assert_ne(event.type, "ShortageEnded", "Encerrar também é uma vez só.")


func test_a_market_without_a_producer_for_sixty_days_declares_the_shortage() -> void:
	var rig: Rig = _rig()
	_set_bread(rig, 0)
	var declared_on: int = 0
	for day: int in range(1, 61):
		for event: SimEvent in rig.markets.end_of_day():
			if event is ShortageDeclared and declared_on == 0:
				declared_on = day
	assert_true(declared_on > 0 and declared_on < 60, "A escassez foi declarada bem antes dos 60 dias (no dia %d)." % declared_on)
	assert_eq(rig.markets.price_of(MARKET, "bread"), PriceMath.ceiling_price(BREAD_BASE, rig.params), "Sem estoque o preço chega ao teto.")


func test_goods_with_target_zero_are_not_traded_and_the_same_days_give_the_same_state() -> void:
	var goods: GoodsLoader.LoadResult = GoodsLoader.load_dir(GoodsLoader.DEFAULT_DIR)
	var loaded: MarketLoader.LoadResult = MarketLoader.load_dir(GoodsLoader.DEFAULT_DIR)
	var targets: Array[MarketTargetDef] = []
	for target: MarketTargetDef in loaded.targets:
		targets.append(MarketTargetDef.new(target.id, target.settlement_id, target.good_id, 0 if target.good_id == "ore" else target.target_stock, 0 if target.good_id == "ore" else target.initial_stock, target.buy_cap_bp))
	var book: OwnerBook = OwnerBook.new()
	book.open_owner(MARKET, MarketBook.KIND_MARKET)
	var markets: MarketBook = MarketBook.new(book, GoodsStore.new(book, goods.goods, goods.kinds), goods.goods, targets, loaded.params)
	assert_false(markets.traded_goods(SETTLEMENT_A).has("ore"), "Alvo 0 = bem não negociado nesse mercado.")
	assert_eq(markets.traded_goods(SETTLEMENT_A).size(), 9)
	var first: Rig = _rig()
	var second: Rig = _rig()
	for rig: Rig in [first, second]:
		_set_bread(rig, 25)
		for _day: int in 15:
			rig.markets.end_of_day()
	assert_eq(first.markets.serialize(), second.markets.serialize(), "Mesmos dias, mesmo estado.")


func test_the_market_state_survives_json_and_invalid_data_is_refused() -> void:
	var rig: Rig = _rig()
	_set_bread(rig, 12)
	for _day: int in 12:
		rig.markets.end_of_day()
	var good: Dictionary = rig.markets.serialize()
	# Variant: o JSON devolve qualquer tipo; aqui o formato é conhecido (um objeto).
	var parsed: Variant = JSON.parse_string(JSON.stringify(good))
	var through_json: Dictionary = parsed
	var restored: Rig = _rig()
	var loaded: Result = restored.markets.load_from(through_json)
	assert_true(loaded.ok, loaded.message)
	assert_eq(JSON.stringify(restored.markets.serialize(), "", true, true).sha256_text(), JSON.stringify(good, "", true, true).sha256_text(), "Mesmo estado, mesma impressão digital.")
	assert_eq([restored.markets.price_of(MARKET, "bread"), restored.markets.is_in_shortage(MARKET, "bread"), restored.markets.history_of(MARKET, "bread").size()], [rig.markets.price_of(MARKET, "bread"), true, rig.params.history_days])
	var cases: Array[Dictionary] = [
		{"label": "campo ausente", "mutate": func(data: Dictionary) -> void: data.erase(MarketBook.KEY_MARKETS), "fragment": "campo 'markets' ausente"},
		{"label": "dono que não é mercado", "mutate": func(data: Dictionary) -> void: data[MarketBook.KEY_MARKETS] = {"7": data[MarketBook.KEY_MARKETS]["1"]}, "fragment": "o ID de um dono do tipo 'market'"},
		{"label": "assentamento desconhecido", "mutate": func(data: Dictionary) -> void: data[MarketBook.KEY_MARKETS]["1"][MarketBook.KEY_SETTLEMENT] = "nowhere", "fragment": "assentamento inválido ou repetido"},
		{"label": "bem a menos", "mutate": func(data: Dictionary) -> void: data[MarketBook.KEY_MARKETS]["1"][MarketBook.KEY_GOODS].erase("tool"), "fragment": "esperados exatamente os 10 bens"},
		{"label": "preço fora da faixa", "mutate": func(data: Dictionary) -> void: data[MarketBook.KEY_MARKETS]["1"][MarketBook.KEY_GOODS]["bread"][MarketBook.KEY_PRICE] = 31, "fragment": "'price' deve ser um inteiro de 5 a 30"},
		{"label": "preço com fração", "mutate": func(data: Dictionary) -> void: data[MarketBook.KEY_MARKETS]["1"][MarketBook.KEY_GOODS]["bread"][MarketBook.KEY_PRICE] = 12.5, "fragment": "'price' deve ser um inteiro"},
		{"label": "histórico longo demais", "mutate": func(data: Dictionary) -> void: data[MarketBook.KEY_MARKETS]["1"][MarketBook.KEY_GOODS]["bread"][MarketBook.KEY_HISTORY] = [10, 10, 10, 10, 10, 10, 10, 10], "fragment": "lista de 1 a 7 preços"},
		{"label": "declarada que não é booleano", "mutate": func(data: Dictionary) -> void: data[MarketBook.KEY_MARKETS]["1"][MarketBook.KEY_GOODS]["bread"][MarketBook.KEY_DECLARED] = 1, "fragment": "verdadeiro ou falso"},
		{"label": "dias abaixo negativos", "mutate": func(data: Dictionary) -> void: data[MarketBook.KEY_MARKETS]["1"][MarketBook.KEY_GOODS]["bread"][MarketBook.KEY_DAYS_BELOW] = -1, "fragment": "'days_below' deve ser um inteiro de 0 ou mais"},
	]
	for test_case: Dictionary in cases:
		var data: Dictionary = good.duplicate(true)
		var mutate: Callable = test_case["mutate"]
		mutate.call(data)
		var result: Result = restored.markets.load_from(data)
		assert_false(result.ok, "%s: deveria falhar." % test_case["label"])
		assert_eq(result.code, EconomyCodes.INVALID_SAVE, test_case["label"])
		assert_string_contains(result.message, test_case["fragment"], test_case["label"])
		assert_eq(restored.markets.serialize(), good, "%s: o livro continua como estava." % test_case["label"])
