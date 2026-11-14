extends GutTest
## LW-098b: o planejador de lucro (`TradePlanner`, docs/modules/economy.md, 9.5) com mercados e bens MONTADOS no teste (alvo, estoque e teto de cada bem por mercado; o preço sai da curva real do `MarketBook`) e os parâmetros de PARTIDA do contrato em memória. O pão custa 10 e pesa 1; a bigorna custa 30 e
## pesa 10; "twin_a" e "twin_b" são idênticos (desempate). O comerciante leva 120 de peso, como o carrinho da Q2. A busca exaustiva do teste é independente da varredura do planejador: refaz o `net` de cada quantidade pelas cotações cruas do `TradeEngine`, e o planejador tem de chegar ao MESMO ótimo (a mesma quantidade e o mesmo `net`).

const MARKET_A: int = 1
const MARKET_B: int = 2
const MARKET_C: int = 3
const TRADER: int = 10
const CAPACITY: int = 120
const RESERVE_BP: int = 5000
const MAX_ORDER: int = 50
const NO_NET: int = -1000000000
const PRICE_RECORD: Dictionary = {"min_factor_bp": 5000, "max_factor_bp": 30000, "smoothing_bp": 2000, "spread_bp": 1000, "significant_change_bp": 1000, "max_order_quantity": 50, "history_days": 7, "shortage_threshold_bp": 3000, "shortage_days": 10}


class Rig:
	extends RefCounted

	var book: OwnerBook
	var ledger: Ledger
	var goods: GoodsStore
	var markets: MarketBook
	var engine: TradeEngine
	var planner: TradePlanner


func _params(time_cost_per_hour: int = 2) -> CaravanParams:
	return CaravanParams.new({"speed_cm_per_min": 400, "difficulty_slowdown_bp": 50, "risk_bp_per_point": 25, "time_cost_per_hour": time_cost_per_hour, "fixed_cost": 5, "min_net_profit": 20, "min_margin_bp": 500, "origin_reserve_bp": RESERVE_BP})


func _good_defs() -> Array[GoodDef]:
	var defs: Array[GoodDef] = []
	for row: Array in [["bread", 10, 1], ["anvil", 30, 10], ["twin_a", 10, 1], ["twin_b", 10, 1]]:
		defs.append(GoodDef.new(row[0], "good.%s.name" % row[0], GoodDef.CATEGORY_PROCESSED, row[1], row[2], 0))
	return defs


## `spec`: mercado -> bem -> [alvo, estoque, teto em pontos-base]; `funds`: dono -> saldo; `carried`: bem -> quantidade que o comerciante já leva (reduz o peso livre).
func _rig(spec: Dictionary, funds: Dictionary, params: CaravanParams = null, carried: Dictionary = {}) -> Rig:
	var rig: Rig = Rig.new()
	rig.book = OwnerBook.new()
	rig.ledger = Ledger.new(rig.book)
	var kinds: Array[OwnerKindDef] = [OwnerKindDef.new("market", 100000, 0), OwnerKindDef.new("merchant", CAPACITY, 0)]
	rig.goods = GoodsStore.new(rig.book, _good_defs(), kinds)
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
		if rig.book.has_owner(owner_id):
			assert_true(rig.ledger.mint(owner_id, funds[owner_id], Ledger.REASON_GAME_START).ok)
	var price_params: PriceParams = PriceParams.new(PRICE_RECORD)
	rig.markets = MarketBook.new(rig.book, rig.goods, _good_defs(), targets, price_params)
	for market_id: int in spec:
		rig.markets.register_market("settlement_%d" % market_id, market_id)
	rig.engine = TradeEngine.new(rig.book, rig.ledger, rig.goods, rig.markets, NeutralTradeRules.new(), price_params)
	rig.planner = TradePlanner.new(rig.engine, rig.markets, rig.goods, rig.ledger, params if params != null else _params(), price_params)
	return rig


## Pão com o mesmo alvo (100) e teto (2×) nos três mercados; o estoque define o preço (alvo ÷ estoque, entre 0,5 e 3 vezes o valor-base).
func _spec(a_stock: int, b_stock: int, c_stock: int) -> Dictionary:
	return {MARKET_A: {"bread": [100, a_stock, 20000]}, MARKET_B: {"bread": [100, b_stock, 20000]}, MARKET_C: {"bread": [100, c_stock, 20000]}}


func _funds(trader: int = 10000, market_b: int = 3000) -> Dictionary:
	return {MARKET_A: 3000, MARKET_B: market_b, MARKET_C: 3000, TRADER: trader}


func _legs(length_m: int = 520, risk: int = 10) -> Array[RouteCost.Leg]:
	var legs: Array[RouteCost.Leg] = [RouteCost.Leg.new("route_a_b", length_m, 20, risk)]
	return legs


## O `net(q)` pelas cotações cruas e pela conta de 9.5, sem passar pelo planejador.
func _net_at(rig: Rig, origin_id: int, destination_id: int, good_id: String, quantity: int, legs: Array[RouteCost.Leg]) -> int:
	var bought: TradeEngine.Outcome = rig.engine.quote(origin_id, good_id, quantity, TradeEngine.SIDE_BUY, TRADER)
	var sold: TradeEngine.Outcome = rig.engine.quote(destination_id, good_id, quantity, TradeEngine.SIDE_SELL, TRADER)
	var revenue: int = mini(sold.total - sold.tariff, rig.ledger.balance_of(destination_id))
	var risk: int = RouteCost.risk_discount(revenue, RouteCost.path_risk_points(legs), _params())
	return revenue - risk - (bought.total + bought.tariff) - RouteCost.time_cost(RouteCost.path_minutes(legs, _params()), _params())


## A busca exaustiva: a menor `q` de maior `net` entre 1 e o limite de peso, estoque com reserva, teto do destino, ordem e fundos (com o `net` e o custo dela).
func _exhaustive(rig: Rig, origin_id: int, destination_id: int, good_id: String, legs: Array[RouteCost.Leg]) -> Dictionary:
	var reserve: int = PriceMath.ceil_div(rig.markets.target_of(origin_id, good_id) * RESERVE_BP, 10000)
	var by_stock: int = rig.goods.quantity_of(origin_id, good_id) - reserve
	var by_cap: int = rig.markets.buy_cap_of(destination_id, good_id) - rig.goods.quantity_of(destination_id, good_id)
	var by_weight: int = IntMath.floor_div(CAPACITY - rig.goods.weight_of(TRADER), rig.goods.weight_per_unit(good_id))
	var best: Dictionary = {"q": 0, "net": NO_NET, "cost": 1}
	for quantity: int in range(1, mini(mini(by_stock, by_cap), mini(by_weight, MAX_ORDER)) + 1):
		var bought: TradeEngine.Outcome = rig.engine.quote(origin_id, good_id, quantity, TradeEngine.SIDE_BUY, TRADER)
		if bought.total + bought.tariff > rig.ledger.balance_of(TRADER):
			break
		var net: int = _net_at(rig, origin_id, destination_id, good_id, quantity, legs)
		if net > int(best["net"]):
			best = {"q": quantity, "net": net, "cost": bought.total + bought.tariff}
	return best


func _snapshot(rig: Rig) -> Array:
	var rows: Array = [rig.ledger.serialize(), rig.goods.serialize(), rig.ledger.is_conserved(), rig.goods.is_conserved()]
	for market_id: int in rig.markets.market_ids():
		for good_id: String in rig.markets.traded_goods("settlement_%d" % market_id):
			rows.append([rig.markets.price_of(market_id, good_id), rig.markets.ref_stock_of(market_id, good_id), rig.markets.history_of(market_id, good_id)])
	return rows


func _describe(plan: TradePlanner.Plan) -> Array:
	return [plan.destination_market_id, plan.good_id, plan.quantity, plan.cost, plan.revenue, plan.risk_discount, plan.time_cost, plan.minutes, plan.net_profit, plan.margin_bp, plan.route_ids]


func test_without_a_gap_bigger_than_spread_time_and_risk_there_is_no_plan() -> void:
	for b_stock: int in [100, 85, 70]:
		var rig: Rig = _rig(_spec(100, b_stock, 100), _funds())
		assert_null(rig.planner.plan_for(TRADER, MARKET_A, MARKET_B, _legs()), "B com %d de pão: a diferença de preço não cobre spread, tempo e risco." % b_stock)


func test_with_a_gap_the_plan_has_positive_net_and_its_fields_add_up() -> void:
	var rig: Rig = _rig(_spec(100, 40, 100), _funds())
	var plan: TradePlanner.Plan = rig.planner.plan_for(TRADER, MARKET_A, MARKET_B, _legs())
	assert_not_null(plan, "Pão a 10 no A e a 25 no B: há plano.")
	if plan == null:
		return
	var bought: TradeEngine.Outcome = rig.engine.quote(MARKET_A, "bread", plan.quantity, TradeEngine.SIDE_BUY, TRADER)
	var sold: TradeEngine.Outcome = rig.engine.quote(MARKET_B, "bread", plan.quantity, TradeEngine.SIDE_SELL, TRADER)
	assert_eq([plan.destination_market_id, plan.good_id, plan.minutes, plan.route_ids.size(), plan.route_ids[0]], [MARKET_B, "bread", 143, 1, "route_a_b"])
	assert_eq(plan.cost, bought.total + bought.tariff, "O custo é a cotação de compra na origem.")
	assert_eq(plan.revenue, sold.total - sold.tariff, "A receita é a cotação de venda no destino (o saldo do B não limita).")
	assert_eq(plan.risk_discount, PriceMath.ceil_div(plan.revenue * 10 * 25, 10000), "Risco: ceil_div(receita × 10 pontos × 25 bp, 10000).")
	assert_eq(plan.time_cost, 10, "Tempo: ceil_div(143 × 2, 60) + 5 (o exemplo do contrato).")
	assert_eq(plan.net_profit, plan.revenue - plan.risk_discount - plan.cost - plan.time_cost, "net = receita − risco − custo − tempo.")
	assert_gt(plan.net_profit, 0, "Com diferença, o lucro é positivo.")
	assert_eq(plan.margin_bp, IntMath.floor_div(plan.net_profit * 10000, plan.cost), "margin_bp = floor_div(net × 10000, custo).")
	assert_true(plan.net_profit >= 20 and plan.net_profit * 10000 >= 500 * plan.cost, "Passa dos dois limiares.")


func test_a_wider_gap_creates_the_plan_and_keeps_it() -> void:
	var nets: Array[int] = []
	for b_stock: int in [100, 90, 80, 70, 60, 50, 40, 30, 20]:
		var plan: TradePlanner.Plan = _rig(_spec(100, b_stock, 100), _funds()).planner.plan_for(TRADER, MARKET_A, MARKET_B, _legs())
		if plan != null:
			assert_true(plan.net_profit >= 20 and plan.net_profit > 0, "B com %d: o plano que existe tem lucro positivo e passa do limiar." % b_stock)
			nets.append(plan.net_profit)
		else:
			assert_true(nets.is_empty(), "B com %d: com diferença maior, uma vez que o plano existe ele não some." % b_stock)
	assert_gt(nets.size(), 3, "A partir de alguma diferença o plano existe.")
	assert_gt(nets[nets.size() - 1], nets[0], "A maior diferença rende mais que a menor que já compensa.")


func test_more_time_or_more_risk_lowers_the_net() -> void:
	var rig: Rig = _rig(_spec(100, 40, 100), _funds())
	var base: TradePlanner.Plan = rig.planner.plan_for(TRADER, MARKET_A, MARKET_B, _legs())
	var longer: TradePlanner.Plan = rig.planner.plan_for(TRADER, MARKET_A, MARKET_B, _legs(1040))
	var riskier: TradePlanner.Plan = rig.planner.plan_for(TRADER, MARKET_A, MARKET_B, _legs(520, 40))
	var costlier: TradePlanner.Plan = _rig(_spec(100, 40, 100), _funds(), _params(20)).planner.plan_for(TRADER, MARKET_A, MARKET_B, _legs())
	for plan: TradePlanner.Plan in [base, longer, riskier, costlier]:
		assert_not_null(plan, "Os quatro cenários ainda têm plano.")
	if base == null or longer == null or riskier == null or costlier == null:
		return
	assert_gt(longer.minutes, base.minutes, "O trecho de 1040 m leva mais minutos.")
	assert_lt(longer.net_profit, base.net_profit, "Mais tempo, menos lucro.")
	assert_gt(riskier.risk_discount, base.risk_discount, "Risco 40 desconta mais que risco 10.")
	assert_lt(riskier.net_profit, base.net_profit, "Mais risco, menos lucro.")
	assert_lt(costlier.net_profit, base.net_profit, "Hora mais cara, menos lucro.")


func test_the_planned_quantity_is_the_exact_optimum_of_an_exhaustive_search() -> void:
	var found: int = 0
	for a_stock: int in [60, 100, 140, 200]:
		for b_stock: int in [20, 35, 50, 70, 100]:
			var rig: Rig = _rig(_spec(a_stock, b_stock, 100), _funds())
			var plan: TradePlanner.Plan = rig.planner.plan_for(TRADER, MARKET_A, MARKET_B, _legs())
			var best: Dictionary = _exhaustive(rig, MARKET_A, MARKET_B, "bread", _legs())
			var label: String = "A=%d B=%d" % [a_stock, b_stock]
			if plan == null:
				assert_true(int(best["net"]) < 20 or int(best["net"]) * 10000 < 500 * int(best["cost"]), "%s: sem plano, o ótimo da busca exaustiva (%d) não passa dos limiares." % [label, int(best["net"])])
				continue
			found += 1
			assert_eq(plan.net_profit, _net_at(rig, MARKET_A, MARKET_B, "bread", plan.quantity, _legs()), "%s: o net do plano é o da conta independente." % label)
			assert_eq([plan.quantity, plan.net_profit], [int(best["q"]), int(best["net"])], "%s: a quantidade e o net do plano são os da busca exaustiva." % label)
	assert_gt(found, 6, "A grade tem vários casos com plano.")


func test_every_limit_is_respected() -> void:
	var cases: Array[Dictionary] = [
		{"label": "ordem máxima", "spec": _spec(200, 40, 100), "funds": _funds(), "expect": MAX_ORDER},
		{"label": "reserva de 50% do alvo na origem (20 − 10)", "spec": {MARKET_A: {"bread": [20, 20, 20000]}, MARKET_B: {"bread": [100, 20, 20000]}}, "funds": _funds(), "expect": 10},
		{"label": "peso livre (120 menos 2 bigornas levadas, de 10 cada)", "spec": {MARKET_A: {"anvil": [20, 40, 20000]}, MARKET_B: {"anvil": [20, 4, 20000]}}, "funds": _funds(), "carried": {"anvil": 2}, "expect": 10},
		{"label": "teto de compra do destino (20 − 14)", "spec": {MARKET_A: {"anvil": [20, 40, 20000]}, MARKET_B: {"anvil": [20, 14, 10000]}}, "funds": _funds(), "expect": 6},
	]
	for test_case: Dictionary in cases:
		var carried: Dictionary = test_case.get("carried", {})
		var rig: Rig = _rig(test_case["spec"], test_case["funds"], null, carried)
		var good_id: String = "anvil" if test_case["spec"][MARKET_A].has("anvil") else "bread"
		var plan: TradePlanner.Plan = rig.planner.plan_for(TRADER, MARKET_A, MARKET_B, _legs())
		assert_not_null(plan, "%s: há plano." % test_case["label"])
		if plan != null:
			assert_eq(plan.quantity, test_case["expect"], test_case["label"])
			assert_eq(plan.quantity, int(_exhaustive(rig, MARKET_A, MARKET_B, good_id, _legs())["q"]), "%s: confere com a busca exaustiva." % test_case["label"])
	var poor: Rig = _rig(_spec(200, 40, 100), _funds(100))
	var affordable: int = 0
	for quantity: int in range(1, MAX_ORDER + 1):
		var bought: TradeEngine.Outcome = poor.engine.quote(MARKET_A, "bread", quantity, TradeEngine.SIDE_BUY, TRADER)
		if bought.total + bought.tariff <= 100:
			affordable = quantity
	var poor_plan: TradePlanner.Plan = poor.planner.plan_for(TRADER, MARKET_A, MARKET_B, _legs())
	assert_not_null(poor_plan, "Com 100 moedas ainda há plano.")
	if poor_plan != null:
		assert_eq(poor_plan.quantity, affordable, "Fundos: a maior quantidade que o saldo do comerciante paga.")
		assert_lt(poor_plan.quantity, MAX_ORDER)
	var broke_market: Rig = _rig(_spec(200, 40, 100), _funds(10000, 100))
	var broke_plan: TradePlanner.Plan = broke_market.planner.plan_for(TRADER, MARKET_A, MARKET_B, _legs())
	assert_not_null(broke_plan, "Com 100 moedas no B ainda há plano.")
	if broke_plan != null:
		assert_true(broke_plan.revenue <= 100 and broke_plan.quantity < MAX_ORDER, "Saldo do destino: a receita não passa de 100 e o lote encolhe.")
		assert_eq(broke_plan.quantity, int(_exhaustive(broke_market, MARKET_A, MARKET_B, "bread", _legs())["q"]), "Saldo do destino: confere com a busca exaustiva.")


func test_the_planner_does_not_change_any_state() -> void:
	var rig: Rig = _rig(_spec(100, 40, 40), _funds())
	var before: Array = _snapshot(rig)
	var paths: Dictionary[int, Array] = {MARKET_B: _legs(), MARKET_C: _legs(340, 15)}
	assert_eq(rig.planner.plan_all(TRADER, MARKET_A, paths).size(), 2, "Os dois destinos têm plano.")
	assert_eq(_snapshot(rig), before, "Saldos, estoques, preços e somas de conservação seguem iguais.")


func test_ties_go_to_the_lowest_ids_and_planning_twice_gives_the_same_result() -> void:
	var rig: Rig = _rig(_spec(200, 40, 40), _funds())
	var paths: Dictionary[int, Array] = {MARKET_C: _legs(), MARKET_B: _legs()}
	var plans: Array[TradePlanner.Plan] = rig.planner.plan_all(TRADER, MARKET_A, paths)
	assert_eq([plans.size(), plans[0].destination_market_id, plans[1].destination_market_id], [2, MARKET_B, MARKET_C], "A lista sai por destino crescente.")
	assert_eq(plans[0].net_profit, plans[1].net_profit, "B e C são iguais: empate no net.")
	assert_eq(TradePlanner.best_of(plans).destination_market_id, MARKET_B, "Empate: o menor destination_market_id.")
	plans.reverse()
	assert_eq(TradePlanner.best_of(plans).destination_market_id, MARKET_B, "A ordem da lista não decide.")
	var again: Array[TradePlanner.Plan] = rig.planner.plan_all(TRADER, MARKET_A, paths)
	assert_eq(_describe(again[0]), _describe(rig.planner.plan_for(TRADER, MARKET_A, MARKET_B, _legs())), "Planejar de novo com a mesma entrada dá o mesmo plano.")
	var twins: Dictionary = {MARKET_A: {"twin_a": [100, 200, 20000], "twin_b": [100, 200, 20000]}, MARKET_B: {"twin_a": [100, 40, 20000], "twin_b": [100, 40, 20000]}}
	var twin_plan: TradePlanner.Plan = _rig(twins, _funds()).planner.plan_for(TRADER, MARKET_A, MARKET_B, _legs())
	assert_not_null(twin_plan, "Os gêmeos têm plano.")
	if twin_plan != null:
		assert_eq(twin_plan.good_id, "twin_a", "Empate entre bens do mesmo destino: o menor good_id.")
	assert_null(TradePlanner.best_of([] as Array[TradePlanner.Plan]), "Sem planos, sem melhor.")


func test_requests_that_cannot_be_planned_give_no_plan() -> void:
	var rig: Rig = _rig(_spec(200, 40, 100), _funds())
	assert_not_null(rig.planner.plan_for(TRADER, MARKET_A, MARKET_B, _legs()), "Controle: o cenário tem plano.")
	assert_null(rig.planner.plan_for(99, MARKET_A, MARKET_B, _legs()), "Comerciante que não existe.")
	assert_null(rig.planner.plan_for(TRADER, MARKET_A, 99, _legs()), "Destino que não é mercado.")
	assert_null(rig.planner.plan_for(TRADER, MARKET_A, MARKET_A, _legs()), "Origem igual ao destino.")
	var no_legs: Array[RouteCost.Leg] = []
	assert_null(rig.planner.plan_for(TRADER, MARKET_A, MARKET_B, no_legs), "Sem caminho.")
	assert_true(rig.book.close_owner(TRADER).ok)
	assert_null(rig.planner.plan_for(TRADER, MARKET_A, MARKET_B, _legs()), "Comerciante fechado (morreu): a cotação falha, não há plano.")

