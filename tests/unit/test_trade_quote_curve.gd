extends GutTest
## LW-098h3c1: a curva de cotações (`TradeEngine.quote_curve`, `MarketBook.buy_curve` e `sell_curve`, `PriceMath.buy_curve` e `sell_curve`; docs/modules/economy.md, 9.5) é a MESMA aritmética de `quote` numa passada só, e o `TradePlanner` que a lê decide exatamente o que decidia com uma `quote` por quantidade.
## A curva é conferida contra `quote` em CADA quantidade, nos dados reais (data/economy) com o estoque do vazio ao teto e acima dele, nos dois lados, com tarifa, bem banido e ator desconhecido ou fechado. O planejador é conferido, campo a campo, contra o `QuotePlanner` deste teste (a cópia do de antes da curva) numa grade de mundos, nos casos de limite e nos mercados reais.

const MARKET_A: int = 1
const MARKET_B: int = 2
const MARKET_C: int = 3
const TRADER: int = 10
const STRANGER: int = 99
const CAPACITY: int = 120
const MAX_ORDER: int = 50
const PRICE_RECORD: Dictionary = {"min_factor_bp": 5000, "max_factor_bp": 30000, "smoothing_bp": 2000, "spread_bp": 1000, "significant_change_bp": 1000, "max_order_quantity": 50, "history_days": 7, "shortage_threshold_bp": 3000, "shortage_days": 10}


## Tarifa de teste em pontos-base: em todo mercado ou só em `only_market`.
class TariffRules:
	extends TradeRules

	var basis_points: int
	var only_market: int


	func _init(basis: int, market_id: int = 0) -> void:
		basis_points = basis
		only_market = market_id


	func peek_terms(_good_id: String, market_id: int, _actor_id: int) -> TradeTerms:
		return TradeTerms.new(false, basis_points if only_market == 0 or market_id == only_market else 0, false)


## Proíbe todo bem do mercado dado (ou só `banned_good`, se dado).
class BanRules:
	extends TradeRules

	var banned_market: int
	var banned_good: String


	func _init(market_id: int, good_id: String = "") -> void:
		banned_market = market_id
		banned_good = good_id


	func peek_terms(good_id: String, market_id: int, _actor_id: int) -> TradeTerms:
		return TradeTerms.new(market_id == banned_market and (banned_good.is_empty() or good_id == banned_good), 0, false)


## O planejador de REFERÊNCIA: o de antes da curva (LW-098h3b), com UMA `quote` por quantidade (cópia do `_candidate` e dos auxiliares de então, só renomeados `_old_`). `plan_for`, `plan_all`, `_upper_quantity` e a pré-checagem `_rules_out` (que não mudou e o `test_trade_planner.gd` já confere contra a busca completa) são os do planejador real.
class QuotePlanner:
	extends TradePlanner

	func _candidate(trader_id: int, origin_id: int, destination_id: int, good_id: String, legs: Array[RouteCost.Leg], minutes: int) -> TradePlanner.Plan:
		var risk_points: int = RouteCost.path_risk_points(legs)
		var time_cost: int = RouteCost.time_cost(minutes, _params)
		var min_gain: int = _params.min_net_profit + time_cost
		if _rules_out(trader_id, origin_id, destination_id, good_id, min_gain):
			return null
		var quantity: int = _old_best_quantity(trader_id, origin_id, destination_id, good_id, risk_points, _old_max_quantity(trader_id, origin_id, destination_id, good_id), min_gain)
		if quantity < 1:
			return null
		var plan: TradePlanner.Plan = TradePlanner.Plan.new()
		plan.destination_market_id = destination_id
		plan.good_id = good_id
		plan.quantity = quantity
		plan.cost = _old_cost_of(trader_id, origin_id, good_id, quantity)
		plan.revenue = _old_revenue_of(trader_id, destination_id, good_id, quantity)
		plan.risk_discount = RouteCost.risk_discount(plan.revenue, risk_points, _params)
		plan.time_cost = time_cost
		plan.minutes = minutes
		plan.net_profit = plan.revenue - plan.risk_discount - plan.cost - plan.time_cost
		plan.margin_bp = IntMath.floor_div(plan.net_profit * PriceMath.BASIS, plan.cost)
		if plan.net_profit < _params.min_net_profit or plan.net_profit * PriceMath.BASIS < _params.min_margin_bp * plan.cost:
			return null
		for leg: RouteCost.Leg in legs:
			plan.route_ids.append(leg.route_id)
		return plan


	func _old_max_quantity(trader_id: int, origin_id: int, destination_id: int, good_id: String) -> int:
		var funds: int = _ledger.balance_of(trader_id)
		var low: int = 0
		var high: int = _upper_quantity(trader_id, origin_id, destination_id, good_id)
		while low < high:
			var middle: int = IntMath.floor_div(low + high + 1, 2)
			if _old_cost_of(trader_id, origin_id, good_id, middle) <= funds:
				low = middle
			else:
				high = middle - 1
		return low


	func _old_best_quantity(trader_id: int, origin_id: int, destination_id: int, good_id: String, risk_points: int, q_max: int, min_gain: int) -> int:
		if q_max < 1:
			return 0
		var first_spread: int = _old_revenue_of(trader_id, destination_id, good_id, 1) - _old_cost_of(trader_id, origin_id, good_id, 1)
		var slack: int = TARIFF_SLACK if _old_taxed(trader_id, origin_id, destination_id, good_id) else 0
		if (first_spread + slack) * q_max < min_gain:
			return 0
		var best_gain: int = _old_gain_at(trader_id, origin_id, destination_id, good_id, risk_points, 1)
		var best_quantity: int = 1
		for quantity: int in range(2, q_max + 1):
			var gain: int = _old_gain_at(trader_id, origin_id, destination_id, good_id, risk_points, quantity)
			if gain > best_gain:
				best_gain = gain
				best_quantity = quantity
		return best_quantity if best_gain > 0 else 0


	func _old_taxed(trader_id: int, origin_id: int, destination_id: int, good_id: String) -> bool:
		var bought: TradeEngine.Outcome = _engine.quote(origin_id, good_id, 1, TradeEngine.SIDE_BUY, trader_id)
		var sold: TradeEngine.Outcome = _engine.quote(destination_id, good_id, 1, TradeEngine.SIDE_SELL, trader_id)
		return bought.tariff > 0 or sold.tariff > 0


	func _old_gain_at(trader_id: int, origin_id: int, destination_id: int, good_id: String, risk_points: int, quantity: int) -> int:
		if quantity < 1:
			return 0
		var revenue: int = _old_revenue_of(trader_id, destination_id, good_id, quantity)
		return revenue - RouteCost.risk_discount(revenue, risk_points, _params) - _old_cost_of(trader_id, origin_id, good_id, quantity)


	func _old_cost_of(trader_id: int, market_id: int, good_id: String, quantity: int) -> int:
		var bought: TradeEngine.Outcome = _engine.quote(market_id, good_id, quantity, TradeEngine.SIDE_BUY, trader_id)
		return bought.total + bought.tariff if bought.result.ok else UNPRICED


	func _old_revenue_of(trader_id: int, market_id: int, good_id: String, quantity: int) -> int:
		var sold: TradeEngine.Outcome = _engine.quote(market_id, good_id, quantity, TradeEngine.SIDE_SELL, trader_id)
		return mini(sold.total - sold.tariff, _ledger.balance_of(market_id)) if sold.result.ok else 0


class Rig:
	extends RefCounted

	var book: OwnerBook
	var ledger: Ledger
	var goods: GoodsStore
	var markets: MarketBook
	var engine: TradeEngine


func _good_defs() -> Array[GoodDef]:
	var defs: Array[GoodDef] = []
	for row: Array in [["bread", 10, 1], ["anvil", 30, 10], ["twin_a", 10, 1], ["twin_b", 10, 1], ["grain", 20, 1], ["feather", 10, 0]]:
		defs.append(GoodDef.new(row[0], "good.%s.name" % row[0], GoodDef.CATEGORY_PROCESSED, row[1], row[2], 0))
	return defs


## `spec`: mercado -> bem -> [alvo, estoque, teto em pontos-base]; `funds`: dono -> saldo; `carried`: bem -> quantidade que o comerciante já leva; `defs`: os bens (padrão: os do teste).
func _rig(spec: Dictionary, funds: Dictionary, rules: TradeRules = null, carried: Dictionary = {}, defs: Array[GoodDef] = []) -> Rig:
	var rig: Rig = Rig.new()
	var good_defs: Array[GoodDef] = defs if not defs.is_empty() else _good_defs()
	rig.book = OwnerBook.new()
	rig.ledger = Ledger.new(rig.book)
	rig.goods = GoodsStore.new(rig.book, good_defs, [OwnerKindDef.new("market", 100000, 0), OwnerKindDef.new("merchant", CAPACITY, 0)])
	var targets: Array[MarketTargetDef] = []
	for market_id: int in spec:
		assert_true(rig.book.open_owner(market_id, "market").ok)
		for good_id: String in spec[market_id]:
			var row: Array = spec[market_id][good_id]
			targets.append(MarketTargetDef.new("mt_%d_%s" % [market_id, good_id], "settlement_%d" % market_id, good_id, row[0], row[1], row[2]))
			assert_true(rig.goods.create(market_id, good_id, row[1], GoodsStore.REASON_GAME_START).ok)
	assert_true(rig.book.open_owner(TRADER, "merchant").ok)
	for good_id: String in carried:
		assert_true(rig.goods.create(TRADER, good_id, carried[good_id], GoodsStore.REASON_GAME_START).ok)
	for owner_id: int in funds:
		if funds[owner_id] > 0 and rig.book.has_owner(owner_id):
			assert_true(rig.ledger.mint(owner_id, funds[owner_id], Ledger.REASON_GAME_START).ok)
	var price_params: PriceParams = PriceParams.new(PRICE_RECORD)
	rig.markets = MarketBook.new(rig.book, rig.goods, good_defs, targets, price_params)
	for market_id: int in spec:
		rig.markets.register_market("settlement_%d" % market_id, market_id)
	rig.engine = TradeEngine.new(rig.book, rig.ledger, rig.goods, rig.markets, rules if rules != null else NeutralTradeRules.new(), price_params)
	return rig


## Os três povoados dos dados reais (mercados 1 a 3), com o estoque inicial de `market_targets.json`.
func _real_rig(rules: TradeRules = null, funds: Dictionary = {}) -> Rig:
	var goods: GoodsLoader.LoadResult = GoodsLoader.load_dir(GoodsLoader.DEFAULT_DIR)
	var loaded: MarketLoader.LoadResult = MarketLoader.load_dir(GoodsLoader.DEFAULT_DIR)
	assert_true(goods.result.ok and loaded.result.ok, goods.result.message + loaded.result.message)
	var spec: Dictionary = {}
	for target: MarketTargetDef in loaded.targets:
		var market_id: int = MARKET_A + ["test_settlement_a", "test_settlement_b", "test_settlement_c"].find(target.settlement_id)
		spec[market_id] = spec.get(market_id, {})
		spec[market_id][target.good_id] = [target.target_stock, target.initial_stock, target.buy_cap_bp]
	return _rig(spec, funds if not funds.is_empty() else _funds(), rules, {}, goods.goods)


func _funds(trader: int = 10000, market_b: int = 3000) -> Dictionary:
	return {MARKET_A: 3000, MARKET_B: market_b, MARKET_C: 3000, TRADER: trader}


func _legs(length_m: int = 520, risk: int = 10) -> Array[RouteCost.Leg]:
	var legs: Array[RouteCost.Leg] = [RouteCost.Leg.new("route_a_b", length_m, 20, risk)]
	return legs


func _params(min_net_profit: int = 20, min_margin_bp: int = 500, time_cost_per_hour: int = 2, fixed_cost: int = 5) -> CaravanParams:
	return CaravanParams.new({"speed_cm_per_min": 400, "difficulty_slowdown_bp": 50, "risk_bp_per_point": 25, "time_cost_per_hour": time_cost_per_hour, "fixed_cost": fixed_cost, "min_net_profit": min_net_profit, "min_margin_bp": min_margin_bp, "origin_reserve_bp": 5000})


## Sem custo de tempo nem margem mínima, só com o lucro mínimo dado (pode ser 0 ou negativo).
func _relaxed(min_net_profit: int) -> CaravanParams:
	return _params(min_net_profit, 0, 0, 0)


## Muda o estoque do mercado para `level` SEM mexer no preço de tabela nem no estoque de referência (o estado depois de um dia de negócios).
func _set_stock(rig: Rig, market_id: int, good_id: String, level: int) -> void:
	var delta: int = level - rig.goods.quantity_of(market_id, good_id)
	var moved: Result = rig.goods.create(market_id, good_id, delta, GoodsStore.REASON_GAME_START) if delta > 0 else rig.goods.destroy(market_id, good_id, -delta, GoodsStore.REASON_CONSUMED)
	assert_true(delta == 0 or moved.ok, "estoque de %s no mercado %d em %d" % [good_id, market_id, level])


## A curva de `requested` unidades contra `quote` em CADA quantidade de 1 a `requested`: `quote` só aceita de 1 a `ok_through` e nessa faixa o total e a tarifa são os da curva. Devolve o `ok_through`.
func _check_curve(engine: TradeEngine, market_id: int, good_id: String, requested: int, side: String, actor_id: int, label: String) -> int:
	var curve: TradeEngine.QuoteCurve = engine.quote_curve(market_id, good_id, requested, side, actor_id)
	var through: int = 0
	var differences: Array[int] = []
	for quantity: int in range(1, requested + 1):
		var outcome: TradeEngine.Outcome = engine.quote(market_id, good_id, quantity, side, actor_id)
		through = quantity if outcome.result.ok else through
		if outcome.result.ok != (quantity <= curve.ok_through) or (outcome.result.ok and [curve.totals[quantity], curve.tariffs[quantity]] != [outcome.total, outcome.tariff]):
			differences.append(quantity)
	assert_eq(differences, [] as Array[int], "%s: as quantidades em que a curva e `quote` divergem." % label)
	assert_eq(curve.ok_through, through, "%s: `ok_through` é a maior quantidade que `quote` aceita." % label)
	return curve.ok_through


func test_the_curve_equals_the_quote_for_every_quantity_in_the_real_markets() -> void:
	var rig: Rig = _real_rig()
	var by_max_order: int = 0
	var by_stock: int = 0
	var empty: int = 0
	for market_id: int in rig.markets.market_ids():
		for good_id: String in rig.markets.traded_goods("settlement_%d" % market_id):
			var cap: int = rig.markets.buy_cap_of(market_id, good_id)
			for level: int in [0, 1, 2, 17, rig.markets.target_of(market_id, good_id), cap - 3, cap - 1, cap, cap + 4]:
				_set_stock(rig, market_id, good_id, level)
				for side: String in [TradeEngine.SIDE_BUY, TradeEngine.SIDE_SELL]:
					var through: int = _check_curve(rig.engine, market_id, good_id, MAX_ORDER + 2, side, TRADER, "%s no mercado %d com %d, %s" % [good_id, market_id, level, side])
					by_max_order += 1 if through == MAX_ORDER else 0
					by_stock += 1 if through > 0 and through < MAX_ORDER else 0
					empty += 1 if through == 0 else 0
	assert_gt(by_max_order, 50, "Há muitos estados em que a ordem máxima limita a curva.")
	assert_gt(by_stock, 50, "Há muitos estados em que o estoque (compra) ou o teto do destino (venda) limita a curva.")
	assert_gt(empty, 20, "Há muitos estados sem curva (estoque zero, teto cheio).")


func test_the_curve_tariff_is_the_ceiling_tariff_of_each_quantity() -> void:
	var reached: int = 0
	for basis: int in [1, 50, 100, 333, 900]:
		var rig: Rig = _real_rig(TariffRules.new(basis))
		for market_id: int in [MARKET_A, MARKET_B]:
			for good_id: String in ["bread", "tool", "flour"]:
				for side: String in [TradeEngine.SIDE_BUY, TradeEngine.SIDE_SELL]:
					reached += _check_curve(rig.engine, market_id, good_id, MAX_ORDER + 2, side, TRADER, "tarifa %d, %s no mercado %d, %s" % [basis, good_id, market_id, side])
	assert_gt(reached, 500, "As curvas com tarifa têm muitas quantidades.")
	var taxed: TradeEngine.QuoteCurve = _real_rig(TariffRules.new(900)).engine.quote_curve(MARKET_A, "bread", MAX_ORDER, TradeEngine.SIDE_BUY, TRADER)
	assert_true(taxed.tariffs[1] >= 1 and taxed.tariffs[MAX_ORDER] > taxed.tariffs[1], "Controle: com tarifa a curva traz a tarifa de cada quantidade, crescente.")


func test_the_curve_refuses_what_quote_refuses() -> void:
	var rig: Rig = _real_rig()
	var buy: String = TradeEngine.SIDE_BUY
	var cases: Array[Dictionary] = [
		{"label": "controle", "expect": MAX_ORDER},
		{"label": "mercado desconhecido", "market": 77},
		{"label": "bem que o mercado não negocia", "good": "no_such_good"},
		{"label": "lado inválido", "side": "swap"},
		{"label": "quantidade 0", "requested": 0},
		{"label": "quantidade negativa", "requested": -4},
		{"label": "ator desconhecido", "actor": STRANGER},
		{"label": "pedido acima da ordem máxima", "requested": 3 * MAX_ORDER, "expect": MAX_ORDER},
		{"label": "sem ator", "actor": IdGenerator.NO_ID, "expect": MAX_ORDER}]
	for test_case: Dictionary in cases:
		var through: int = _check_curve(rig.engine, test_case.get("market", MARKET_A), test_case.get("good", "bread"), test_case.get("requested", MAX_ORDER), test_case.get("side", buy), test_case.get("actor", TRADER), str(test_case["label"]))
		assert_eq(through, test_case.get("expect", 0), "%s: a maior quantidade aceita." % test_case["label"])
	var banned: Rig = _real_rig(BanRules.new(MARKET_A, "bread"))
	for side: String in [TradeEngine.SIDE_BUY, TradeEngine.SIDE_SELL]:
		assert_eq([_check_curve(banned.engine, MARKET_A, "bread", MAX_ORDER, side, TRADER, "banido"), _check_curve(banned.engine, MARKET_C, "bread", MAX_ORDER, side, TRADER, "outro mercado"), _check_curve(banned.engine, MARKET_A, "grain", MAX_ORDER, side, TRADER, "outro bem")], [0, MAX_ORDER, MAX_ORDER], "Bem banido: sem curva no mercado do veto, curva inteira no resto (%s)." % side)
	assert_true(rig.book.close_owner(TRADER).ok)
	assert_eq(_check_curve(rig.engine, MARKET_A, "bread", MAX_ORDER, buy, TRADER, "ator fechado"), 0, "Ator fechado: sem curva.")
	assert_eq(_check_curve(rig.engine, MARKET_A, "bread", MAX_ORDER, buy, IdGenerator.NO_ID, "ator fechado, sem ator na cotação"), MAX_ORDER, "Sem ator na cotação, o fechado não importa.")


func test_the_price_math_curves_are_the_running_sums_of_the_quotes() -> void:
	var params: PriceParams = PriceParams.new(PRICE_RECORD)
	var differences: Array[String] = []
	for base: int in [1, 10, 26]:
		for ref_stock: int in [1, 60, 300]:
			var price: int = PriceMath.goal_price(base, 100, ref_stock, params)
			for stock: int in [0, 1, 7, 60, 400]:
				var buy: PackedInt64Array = PriceMath.buy_curve(price, base, 100, ref_stock, stock, MAX_ORDER + 2, params)
				var sell: PackedInt64Array = PriceMath.sell_curve(price, base, 100, ref_stock, stock, MAX_ORDER + 2, params)
				assert_eq([buy.size(), sell.size(), buy[0], sell[0]], [MAX_ORDER + 3, MAX_ORDER + 3, 0, 0], "Índice 0 é 0 e o tamanho é a quantidade mais 1.")
				for quantity: int in range(1, MAX_ORDER + 3):
					if buy[quantity] != PriceMath.quote_buy(price, base, 100, ref_stock, stock, quantity, params) or sell[quantity] != PriceMath.quote_sell(price, base, 100, ref_stock, stock, quantity, params):
						differences.append("base %d, referência %d, estoque %d, quantidade %d" % [base, ref_stock, stock, quantity])
	assert_eq(differences, [] as Array[String], "A curva é a soma por degrau de `quote_buy` e `quote_sell`.")
	assert_eq([PriceMath.buy_curve(10, 10, 100, 100, 100, 0, params), PriceMath.sell_curve(10, 10, 100, 100, 100, 0, params), PriceMath.buy_curve(10, 10, 100, 100, 100, -3, params)], [PackedInt64Array([0]), PackedInt64Array([0]), PackedInt64Array([0])], "Quantidade 0 ou negativa: só o índice 0.")


## Os planos de B e C do planejador real e do de referência sobre o MESMO mundo: IDÊNTICOS, inclusive "sem plano". `max_order` vale só para o planejador (o motor segue com 50). Devolve os planos.
func _assert_same_plans(rig: Rig, params: CaravanParams, label: String, max_order: int = MAX_ORDER, risk: int = 10) -> Array[TradePlanner.Plan]:
	var record: Dictionary = PRICE_RECORD.duplicate()
	record["max_order_quantity"] = max_order
	var price_params: PriceParams = PriceParams.new(record)
	var paths: Dictionary[int, Array] = {MARKET_B: _legs(520, risk), MARKET_C: _legs(340, risk + 5)}
	var plans: Array[TradePlanner.Plan] = TradePlanner.new(rig.engine, rig.markets, rig.goods, rig.ledger, params, price_params).plan_all(TRADER, MARKET_A, paths)
	var want: Array[TradePlanner.Plan] = QuotePlanner.new(rig.engine, rig.markets, rig.goods, rig.ledger, params, price_params).plan_all(TRADER, MARKET_A, paths)
	assert_eq(_describe(plans), _describe(want), label)
	return plans


func _describe(plans: Array[TradePlanner.Plan]) -> Array:
	var rows: Array = []
	for plan: TradePlanner.Plan in plans:
		rows.append([plan.destination_market_id, plan.good_id, plan.quantity, plan.cost, plan.revenue, plan.risk_discount, plan.time_cost, plan.minutes, plan.net_profit, plan.margin_bp, plan.route_ids])
	return rows


## A margem da 1ª unidade de A para B pelas cotações cruas (a conta da saída antecipada).
func _first_spread(rig: Rig, good_id: String) -> int:
	var bought: TradeEngine.Outcome = rig.engine.quote(MARKET_A, good_id, 1, TradeEngine.SIDE_BUY, TRADER)
	var sold: TradeEngine.Outcome = rig.engine.quote(MARKET_B, good_id, 1, TradeEngine.SIDE_SELL, TRADER)
	return sold.total - sold.tariff - (bought.total + bought.tariff)


## O pão a 5 no A (200) e a 25 no B (40): diferença grande; só A e B existem.
func _gap() -> Dictionary:
	return {MARKET_A: {"bread": [100, 200, 20000]}, MARKET_B: {"bread": [100, 40, 20000]}}


func _grain(a_stock: int, b_stock: int) -> Dictionary:
	return {MARKET_A: {"grain": [5000, a_stock, 20000]}, MARKET_B: {"grain": [5000, b_stock, 20000]}}


func _bread(a_stock: int, b_stock: int, c_stock: int = 100) -> Dictionary:
	return {MARKET_A: {"bread": [100, a_stock, 20000]}, MARKET_B: {"bread": [100, b_stock, 20000]}, MARKET_C: {"bread": [100, c_stock, 20000]}}


func test_the_planner_decides_like_the_quote_planner_in_a_grid_of_worlds() -> void:
	var rules_set: Array[TradeRules] = [NeutralTradeRules.new(), TariffRules.new(100), TariffRules.new(900), TariffRules.new(500, MARKET_B), TariffRules.new(500, MARKET_A), BanRules.new(MARKET_A), BanRules.new(MARKET_B)]
	var with_plan: int = 0
	var without_plan: int = 0
	for rules_at: int in rules_set.size():
		for min_net_profit: int in [-3, 0, 5]:
			for a_stock: int in [5000, 5400]:
				for b_stock: int in range(3800, 4801, 200):
					var params: CaravanParams = _relaxed(min_net_profit)
					var rig: Rig = _rig(_grain(a_stock, b_stock), _funds(), rules_set[rules_at])
					var plans: Array[TradePlanner.Plan] = _assert_same_plans(rig, params, "curva plana, regra %d, lucro mínimo %d, A=%d B=%d" % [rules_at, min_net_profit, a_stock, b_stock])
					with_plan += 0 if plans.is_empty() else 1
					without_plan += 1 if plans.is_empty() else 0
	for a_stock: int in [30, 60, 100, 200]:
		for b_stock: int in [20, 40, 70, 100, 190]:
			for trader_funds: int in [10000, 100, 0]:
				var plans: Array[TradePlanner.Plan] = _assert_same_plans(_rig(_bread(a_stock, b_stock), _funds(trader_funds, 40 if b_stock == 70 else 3000)), _params(), "pão A=%d B=%d saldo %d" % [a_stock, b_stock, trader_funds])
				with_plan += 0 if plans.is_empty() else 1
				without_plan += 1 if plans.is_empty() else 0
	assert_gt(with_plan, 30, "A grade tem muitos casos com plano.")
	assert_gt(without_plan, 100, "A grade tem muitos casos sem plano.")


func test_the_planner_decides_like_the_quote_planner_with_a_tariff_charged_per_order() -> void:
	var found: int = 0
	var trap: int = 0
	for rules: TariffRules in [TariffRules.new(100), TariffRules.new(500), TariffRules.new(500, MARKET_B), TariffRules.new(500, MARKET_A)]:
		for a_stock: int in [5000, 5400, 5800]:
			for b_stock: int in range(3800, 4801, 50):
				var params: CaravanParams = _params(5, 100, 0, 0)
				var rig: Rig = _rig(_grain(a_stock, b_stock), _funds(), rules)
				var plans: Array[TradePlanner.Plan] = _assert_same_plans(rig, params, "tarifa %d no mercado %d, A=%d B=%d" % [rules.basis_points, rules.only_market, a_stock, b_stock])
				found += 0 if plans.is_empty() else 1
				trap += 1 if not plans.is_empty() and _first_spread(rig, "grain") * MAX_ORDER < 5 else 0
	assert_gt(found, 20, "A grade com tarifa tem vários casos com plano.")
	assert_gt(trap, 0, "A grade tem plano com a margem da 1ª unidade abaixo da média por causa do `ceil` da tarifa: a armadilha da cota sem folga.")


func test_the_planner_decides_like_the_quote_planner_in_the_limit_and_special_cases() -> void:
	var many: Dictionary = {MARKET_A: {"bread": [100, 200, 20000], "anvil": [20, 40, 20000], "twin_a": [100, 200, 20000]}, MARKET_B: {"bread": [100, 40, 20000], "anvil": [20, 4, 20000], "twin_a": [100, 40, 20000]}}
	var gap: Dictionary = _gap()
	var cases: Array[Dictionary] = [
		{"label": "controle: lote e diferença", "spec": gap, "expect": MAX_ORDER},
		{"label": "saldo 0", "spec": gap, "funds": _funds(0), "expect": 0},
		{"label": "ordem máxima de 1", "spec": gap, "max_order": 1, "expect": 1},
		{"label": "estoque 1 acima da reserva", "spec": {MARKET_A: {"bread": [100, 51, 20000]}, MARKET_B: {"bread": [100, 15, 20000]}}, "expect": 1},
		{"label": "bem banido na origem", "spec": gap, "rules": BanRules.new(MARKET_A), "expect": 0},
		{"label": "bem banido no destino", "spec": gap, "rules": BanRules.new(MARKET_B), "expect": 0},
		{"label": "margem negativa", "spec": _bread(30, 200), "expect": 0},
		{"label": "margem negativa e lucro mínimo negativo", "spec": _bread(30, 200), "params": _relaxed(-5), "expect": 0},
		{"label": "lucro mínimo 0", "spec": gap, "params": _relaxed(0)},
		{"label": "tarifa de 5%", "spec": gap, "rules": TariffRules.new(500)},
		{"label": "saldo do destino quase vazio", "spec": gap, "funds": _funds(10000, 40)},
		{"label": "vários bens", "spec": many},
		{"label": "estoque abaixo da reserva da origem", "spec": _bread(45, 10), "expect": 0},
		{"label": "teto do destino já cheio", "spec": {MARKET_A: {"bread": [100, 200, 20000]}, MARKET_B: {"bread": [100, 40, 4000]}}, "expect": 0},
		{"label": "mochila cheia", "spec": gap, "carried": {"anvil": 12}, "expect": 0},
		{"label": "peso livre de 2 bigornas", "spec": many, "carried": {"anvil": 11}},
		{"label": "bem sem peso", "spec": {MARKET_A: {"feather": [100, 200, 20000]}, MARKET_B: {"feather": [100, 40, 20000]}}, "expect": 0}]
	var cost_of_7: int = _rig(gap, _funds()).engine.quote(MARKET_A, "bread", 7, TradeEngine.SIDE_BUY, TRADER).total
	cases.append({"label": "saldo exatamente igual ao custo de 7 unidades", "spec": gap, "funds": _funds(cost_of_7), "expect": 7})
	cases.append({"label": "saldo 1 abaixo do custo de 7 unidades", "spec": gap, "funds": _funds(cost_of_7 - 1), "expect": 6})
	for test_case: Dictionary in cases:
		var params: CaravanParams = test_case.get("params", _relaxed(1))
		var rig: Rig = _rig(test_case["spec"], test_case.get("funds", _funds()), test_case.get("rules"), test_case.get("carried", {}))
		var plans: Array[TradePlanner.Plan] = _assert_same_plans(rig, params, str(test_case["label"]), test_case.get("max_order", MAX_ORDER))
		if test_case.has("expect"):
			assert_eq(0 if plans.is_empty() else plans[0].quantity, test_case["expect"], "%s: o lote do plano." % test_case["label"])
	var first: int = _first_spread(_rig(gap, _funds()), "bread")
	assert_gt(first, 0, "Controle: a 1ª unidade rende.")
	for min_net_profit: int in [first - 1, first, first + 1]:
		var exact: CaravanParams = _relaxed(min_net_profit)
		assert_eq(_assert_same_plans(_rig(gap, _funds()), exact, "lucro mínimo %d" % min_net_profit, 1, 0).size(), 1 if min_net_profit <= first else 0, "Lote de 1, sem risco nem tempo: o plano existe se e só se a 1ª unidade alcança o lucro mínimo (%d, 1ª unidade %d)." % [min_net_profit, first])
