extends GutTest
## LW-090: as fórmulas de preço em inteiros (`PriceMath`; docs/modules/economy.md, seção 4; DEC-150). O que vale como contrato são as PROPRIEDADES, conferidas aqui nos valores reais de `data/economy` e em contas
## escritas à mão: o preço fica na faixa; estoque baixo sobe e alto desce; ordem grande custa mais por unidade; comprar e vender na hora dá prejuízo de pelo menos a quantidade; o preço não salta mais que a suavização.

const DATA_DIR: String = "res://data/economy"
const HAND: Dictionary = {"min_factor_bp": 5000, "max_factor_bp": 30000, "smoothing_bp": 2000, "spread_bp": 1000, "significant_change_bp": 1000, "max_order_quantity": 50, "history_days": 7, "shortage_threshold_bp": 3000, "shortage_days": 10}


func _real_params() -> PriceParams:
	var loaded: MarketLoader.LoadResult = MarketLoader.load_dir(DATA_DIR)
	assert_true(loaded.result.ok, loaded.result.message)
	return loaded.params


func test_factor_floor_ceiling_and_goal_price_by_hand() -> void:
	var params: PriceParams = PriceParams.new(HAND)
	assert_eq([PriceMath.floor_price(10, params), PriceMath.ceiling_price(10, params)], [5, 30], "Piso 0,5 e teto 3 vezes o valor-base.")
	assert_eq([PriceMath.floor_price(1, params), PriceMath.ceiling_price(1, params)], [1, 3], "Valor-base 1: o piso nunca é 0.")
	assert_eq([PriceMath.factor_bp(100, 100, params), PriceMath.factor_bp(100, 50, params), PriceMath.factor_bp(100, 10, params), PriceMath.factor_bp(100, 200, params), PriceMath.factor_bp(100, 400, params)], [10000, 20000, 30000, 5000, 5000])
	assert_eq(PriceMath.factor_bp(100, 0, params), 30000, "Estoque zero conta como 1: preço no teto.")
	assert_eq([PriceMath.goal_price(10, 100, 100, params), PriceMath.goal_price(10, 100, 50, params), PriceMath.goal_price(10, 100, 10, params), PriceMath.goal_price(10, 100, 400, params)], [10, 20, 30, 5])
	assert_eq(PriceMath.price_at(10, 10, 100, 100, 50, params), 20, "Com o estoque pela metade do de referência o preço dobra.")
	assert_eq(PriceMath.price_at(10, 10, 100, 100, 100, params), 10, "No estoque de referência vale o preço de tabela.")
	assert_eq([PriceMath.price_at(30, 10, 100, 50, 10, params), PriceMath.price_at(5, 10, 100, 50, 400, params)], [30, 5], "Com o preço de tabela já no teto ou no piso, o degrau não sai da faixa.")


func test_the_smoothing_moves_towards_the_goal_by_at_least_one_and_never_past_it() -> void:
	assert_eq([PriceMath.smoothed_price(10, 20, 2000), PriceMath.smoothed_price(20, 10, 2000), PriceMath.smoothed_price(10, 10, 2000)], [12, 18, 10])
	assert_eq(PriceMath.smoothed_price(10, 11, 2000), 11, "Diferença de 1 fecha em 1 (mínimo 1, sem passar do alvo).")
	assert_eq(PriceMath.smoothed_price(10, 12, 100), 11, "Suavização minúscula ainda anda 1 quando há diferença.")
	assert_eq(PriceMath.smoothed_price(10, 12, 10000), 12, "Suavização total chega ao alvo e para.")
	for price: int in range(1, 60):
		for goal: int in range(1, 60):
			var next: int = PriceMath.smoothed_price(price, goal, 2000)
			assert_true(absi(next - price) <= maxi(1, IntMath.floor_div(absi(goal - price) * 2000, 10000)), "Nenhum salto maior que a suavização (%d para %d)." % [price, goal])
			assert_true((next - price) * (goal - price) >= 0 and absi(next - price) <= absi(goal - price), "Anda em direção ao alvo e não passa dele.")


func test_the_price_stays_in_range_falls_as_stock_grows_and_the_order_walks_the_curve() -> void:
	var params: PriceParams = _real_params()
	for base: int in [1, 4, 10, 26]:
		var low: int = PriceMath.floor_price(base, params)
		var high: int = PriceMath.ceiling_price(base, params)
		var previous: int = high
		for stock: int in range(0, 400):
			var price: int = PriceMath.price_at(base, base, 100, 100, stock, params)
			assert_true(price >= low and price <= high, "Valor-base %d, estoque %d: o preço fica na faixa." % [base, stock])
			assert_true(price <= previous, "O preço não cresce quando o estoque cresce.")
			previous = price
		assert_true(PriceMath.goal_price(base, 100, 25, params) >= PriceMath.goal_price(base, 100, 100, params) and PriceMath.goal_price(base, 100, 100, params) >= PriceMath.goal_price(base, 100, 400, params))
	assert_gt(PriceMath.goal_price(26, 100, 25, params), PriceMath.goal_price(26, 100, 400, params), "Estoque baixo sobe o preço e estoque alto o desce.")
	var small: int = PriceMath.quote_buy(26, 26, 100, 100, 100, 1, params)
	var medium: int = PriceMath.quote_buy(26, 26, 100, 100, 100, 10, params)
	var large: int = PriceMath.quote_buy(26, 26, 100, 100, 100, 40, params)
	assert_true(medium * 1 > small * 10 and large * 10 > medium * 40, "A ordem grande custa mais por unidade que a pequena (o preço médio cresce com a quantidade).")


func test_buying_and_selling_the_same_quantity_at_once_always_loses_at_least_the_quantity() -> void:
	var params: PriceParams = _real_params()
	for base: int in [1, 3, 10, 26]:
		for stock: int in [5, 20, 60, 100, 250]:
			for quantity: int in [1, 2, 5, 12]:
				if quantity > stock:
					continue
				var paid: int = PriceMath.quote_buy(base, base, 100, 100, stock, quantity, params)
				var received: int = PriceMath.quote_sell(base, base, 100, 100, stock - quantity, quantity, params)
				assert_true(paid - received >= quantity, "Valor-base %d, estoque %d, quantidade %d: o prejuízo é de pelo menos a quantidade (%d)." % [base, stock, quantity, paid - received])


func test_the_spread_keeps_one_bid_at_most_the_price_below_the_ask_even_at_price_one() -> void:
	for spread_bp: int in [1, 500, 1000, 19999, 20000]:
		for price: int in range(1, 300):
			var bid: int = PriceMath.bid(price, spread_bp)
			var ask: int = PriceMath.ask(price, spread_bp)
			assert_true(bid >= 1 and bid <= price and price < ask, "Preço %d, spread %d: 1 ≤ bid ≤ preço < ask." % [price, spread_bp])
			assert_true(ask - bid >= 1)
	assert_eq([PriceMath.ask(100, 1000), PriceMath.bid(100, 1000)], [105, 95], "Spread de 10%: cada lado paga metade.")
	assert_eq([PriceMath.ask(1, 20000), PriceMath.bid(1, 20000)], [2, 1], "Preço 1 com o spread máximo: o bid continua 1.")
