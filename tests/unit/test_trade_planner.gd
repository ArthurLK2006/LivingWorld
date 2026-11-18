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


## Regra de comércio de teste: a mesma tarifa em pontos-base em todo bem, mercado e ator (a tarifa real é da Fase 4).
class FlatTariffRules:
	extends TradeRules

	var tariff_basis_points: int


	func _init(basis_points: int) -> void:
		tariff_basis_points = basis_points


	func peek_terms(_good_id: String, _market_id: int, _actor_id: int) -> TradeTerms:
		return TradeTerms.new(false, tariff_basis_points, false)


## Regra de teste: todo bem proibido num mercado (a origem ou o destino), sem tarifa.
class BanRules:
	extends TradeRules

	var banned_market: int


	func _init(market_id: int) -> void:
		banned_market = market_id


	func peek_terms(_good_id: String, market_id: int, _actor_id: int) -> TradeTerms:
		return TradeTerms.new(market_id == banned_market, 0, false)


## O planejador SEM a pré-checagem (LW-098h3b): a busca completa que o `_candidate` fazia antes. É a referência da equivalência: a pré-checagem (descartar sem a busca binária do saldo) só pode rejeitar o que a busca completa também rejeitaria.
class FullSearchPlanner:
	extends TradePlanner

	func _rules_out(_trader_id: int, _origin_id: int, _destination_id: int, _good_id: String, _min_gain: int) -> bool:
		return false


## O motor que conta o trabalho de cotação pedido (o custo que a pré-checagem existe para cortar): as chamadas a `quote`, as curvas pedidas (`quote_curve`) e as unidades que uma e outra precificam.
class CountingEngine:
	extends TradeEngine

	var quotes: int = 0
	var curves: int = 0
	var priced: int = 0


	func quote(market_id: int, good_id: String, quantity: int, side: String, actor_id: int = IdGenerator.NO_ID) -> TradeEngine.Outcome:
		quotes += 1
		var outcome: TradeEngine.Outcome = super.quote(market_id, good_id, quantity, side, actor_id)
		priced += quantity if outcome.result.ok else 0
		return outcome


	func quote_curve(market_id: int, good_id: String, quantity: int, side: String, actor_id: int = IdGenerator.NO_ID) -> TradeEngine.QuoteCurve:
		curves += 1
		var curve: TradeEngine.QuoteCurve = super.quote_curve(market_id, good_id, quantity, side, actor_id)
		priced += curve.ok_through
		return curve


## Motor de teste com curvas NÃO côncavas: compra a 10 por unidade; a venda rende 5 na 1ª unidade e 100 por unidade a partir da 2ª. O planejador lê a curva (não `quote`), então a curva sai da mesma cotação roteirizada.
class ScriptedEngine:
	extends TradeEngine

	func quote(_market_id: int, _good_id: String, quantity: int, side: String, _actor_id: int = IdGenerator.NO_ID) -> TradeEngine.Outcome:
		return TradeEngine.Outcome.new(Result.success(), quantity, 10 * quantity if side == TradeEngine.SIDE_BUY else (5 if quantity == 1 else 100 * quantity), 0)


	func quote_curve(market_id: int, good_id: String, quantity: int, side: String, actor_id: int = IdGenerator.NO_ID) -> TradeEngine.QuoteCurve:
		var curve: TradeEngine.QuoteCurve = TradeEngine.QuoteCurve.new()
		curve.ok_through = maxi(quantity, 0)
		curve.totals.resize(curve.ok_through + 1)
		curve.tariffs.resize(curve.ok_through + 1)
		for step: int in range(1, curve.ok_through + 1):
			curve.totals[step] = quote(market_id, good_id, step, side, actor_id).total
		return curve


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
	for row: Array in [["bread", 10, 1], ["anvil", 30, 10], ["twin_a", 10, 1], ["twin_b", 10, 1], ["grain", 20, 1], ["feather", 10, 0]]:
		defs.append(GoodDef.new(row[0], "good.%s.name" % row[0], GoodDef.CATEGORY_PROCESSED, row[1], row[2], 0))
	return defs


## `spec`: mercado -> bem -> [alvo, estoque, teto em pontos-base]; `funds`: dono -> saldo; `carried`: bem -> quantidade que o comerciante já leva (reduz o peso livre).
func _rig(spec: Dictionary, funds: Dictionary, params: CaravanParams = null, carried: Dictionary = {}, rules: TradeRules = null) -> Rig:
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
			var created: Result = rig.goods.create(market_id, good_id, row[1], GoodsStore.REASON_GAME_START)
			assert_true(created.ok, created.message)
	assert_true(rig.book.open_owner(TRADER, "merchant").ok)
	for good_id: String in carried:
		var loaded: Result = rig.goods.create(TRADER, good_id, carried[good_id], GoodsStore.REASON_GAME_START)
		assert_true(loaded.ok, loaded.message)
	for owner_id: int in funds:
		if rig.book.has_owner(owner_id):
			var minted: Result = rig.ledger.mint(owner_id, funds[owner_id], Ledger.REASON_GAME_START)
			assert_true(minted.ok, minted.message)
	var price_params: PriceParams = PriceParams.new(PRICE_RECORD)
	rig.markets = MarketBook.new(rig.book, rig.goods, _good_defs(), targets, price_params)
	for market_id: int in spec:
		rig.markets.register_market("settlement_%d" % market_id, market_id)
	rig.engine = TradeEngine.new(rig.book, rig.ledger, rig.goods, rig.markets, rules if rules != null else NeutralTradeRules.new(), price_params)
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
func _net_at(rig: Rig, origin_id: int, destination_id: int, good_id: String, quantity: int, legs: Array[RouteCost.Leg], params: CaravanParams = null) -> int:
	var used: CaravanParams = params if params != null else _params()
	var bought: TradeEngine.Outcome = rig.engine.quote(origin_id, good_id, quantity, TradeEngine.SIDE_BUY, TRADER)
	var sold: TradeEngine.Outcome = rig.engine.quote(destination_id, good_id, quantity, TradeEngine.SIDE_SELL, TRADER)
	var revenue: int = mini(sold.total - sold.tariff, rig.ledger.balance_of(destination_id))
	var risk: int = RouteCost.risk_discount(revenue, RouteCost.path_risk_points(legs), used)
	return revenue - risk - (bought.total + bought.tariff) - RouteCost.time_cost(RouteCost.path_minutes(legs, used), used)


## A busca exaustiva: a menor `q` de maior `net` entre 1 e o limite de peso, estoque com reserva, teto do destino, ordem e fundos (com o `net` e o custo dela).
func _exhaustive(rig: Rig, origin_id: int, destination_id: int, good_id: String, legs: Array[RouteCost.Leg], params: CaravanParams = null) -> Dictionary:
	var reserve: int = PriceMath.ceil_div(rig.markets.target_of(origin_id, good_id) * RESERVE_BP, 10000)
	var by_stock: int = rig.goods.quantity_of(origin_id, good_id) - reserve
	var by_cap: int = rig.markets.buy_cap_of(destination_id, good_id) - rig.goods.quantity_of(destination_id, good_id)
	var by_weight: int = IntMath.floor_div(CAPACITY - rig.goods.weight_of(TRADER), rig.goods.weight_per_unit(good_id))
	var best: Dictionary = {"q": 0, "net": NO_NET, "cost": 1}
	for quantity: int in range(1, mini(mini(by_stock, by_cap), mini(by_weight, MAX_ORDER)) + 1):
		var bought: TradeEngine.Outcome = rig.engine.quote(origin_id, good_id, quantity, TradeEngine.SIDE_BUY, TRADER)
		if bought.total + bought.tariff > rig.ledger.balance_of(TRADER):
			break
		var net: int = _net_at(rig, origin_id, destination_id, good_id, quantity, legs, params)
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


func test_a_flat_curve_hides_gain_behind_a_first_unit_of_zero_and_the_scan_still_finds_the_exact_optimum() -> void:
	var relaxed: CaravanParams = CaravanParams.new({"speed_cm_per_min": 400, "difficulty_slowdown_bp": 50, "risk_bp_per_point": 25, "time_cost_per_hour": 0, "fixed_cost": 0, "min_net_profit": 5, "min_margin_bp": 100, "origin_reserve_bp": RESERVE_BP})
	var found: int = 0
	var hidden: int = 0
	for a_stock: int in [5000, 5400, 5800]:
		for b_stock: int in range(3800, 4801, 100):
			var rig: Rig = _rig({MARKET_A: {"grain": [5000, a_stock, 20000]}, MARKET_B: {"grain": [5000, b_stock, 20000]}}, _funds(), relaxed)
			var plan: TradePlanner.Plan = rig.planner.plan_for(TRADER, MARKET_A, MARKET_B, _legs())
			var best: Dictionary = _exhaustive(rig, MARKET_A, MARKET_B, "grain", _legs(), relaxed)
			var label: String = "A=%d B=%d" % [a_stock, b_stock]
			if plan == null:
				assert_true(int(best["net"]) < 5 or int(best["net"]) * 10000 < 100 * int(best["cost"]), "%s: sem plano, o ótimo da busca exaustiva (%d) não passa dos limiares." % [label, int(best["net"])])
				continue
			found += 1
			assert_eq([plan.quantity, plan.net_profit], [int(best["q"]), int(best["net"])], "%s: a quantidade e o net do plano são os da busca exaustiva." % label)
			if _net_at(rig, MARKET_A, MARKET_B, "grain", 1, _legs(), relaxed) <= 0:
				hidden += 1
	assert_gt(found, 3, "A grade de curva plana tem vários casos com plano.")
	assert_gt(hidden, 0, "A grade tem plano com a 1ª unidade em 0 moeda ou menos: a armadilha da saída antecipada.")


func test_with_a_tariff_charged_per_order_the_bound_still_keeps_every_plan_of_the_exhaustive_search() -> void:
	var relaxed: CaravanParams = CaravanParams.new({"speed_cm_per_min": 400, "difficulty_slowdown_bp": 50, "risk_bp_per_point": 25, "time_cost_per_hour": 0, "fixed_cost": 0, "min_net_profit": 5, "min_margin_bp": 100, "origin_reserve_bp": RESERVE_BP})
	var found: int = 0
	var taxed_trap: int = 0
	for tariff_bp: int in [100, 500]:
		for a_stock: int in [5000, 5400, 5800]:
			for b_stock: int in range(3800, 4801, 50):
				var rig: Rig = _rig({MARKET_A: {"grain": [5000, a_stock, 20000]}, MARKET_B: {"grain": [5000, b_stock, 20000]}}, _funds(), relaxed, {}, FlatTariffRules.new(tariff_bp))
				var plan: TradePlanner.Plan = rig.planner.plan_for(TRADER, MARKET_A, MARKET_B, _legs())
				var best: Dictionary = _exhaustive(rig, MARKET_A, MARKET_B, "grain", _legs(), relaxed)
				var label: String = "tarifa %d A=%d B=%d" % [tariff_bp, a_stock, b_stock]
				var passes: bool = int(best["net"]) >= 5 and int(best["net"]) * 10000 >= 100 * int(best["cost"])
				if plan == null:
					assert_false(passes, "%s: sem plano só se o ótimo da busca exaustiva (%d) não passa dos limiares." % [label, int(best["net"])])
					continue
				found += 1
				assert_eq([plan.quantity, plan.net_profit], [int(best["q"]), int(best["net"])], "%s: a quantidade e o net do plano são os da busca exaustiva." % label)
				var bought: TradeEngine.Outcome = rig.engine.quote(MARKET_A, "grain", 1, TradeEngine.SIDE_BUY, TRADER)
				var sold: TradeEngine.Outcome = rig.engine.quote(MARKET_B, "grain", 1, TradeEngine.SIDE_SELL, TRADER)
				if (sold.total - sold.tariff - (bought.total + bought.tariff)) * MAX_ORDER < 5:
					taxed_trap += 1
	assert_gt(found, 6, "A grade com tarifa tem vários casos com plano.")
	assert_gt(taxed_trap, 0, "A grade tem plano com a margem da 1ª unidade abaixo da média por causa do ceil da tarifa: a armadilha da cota sem folga.")


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


## Parâmetros sem custo de tempo nem margem mínima, só com o lucro mínimo dado (pode ser 0 ou negativo).
func _relaxed(min_net_profit: int) -> CaravanParams:
	return CaravanParams.new({"speed_cm_per_min": 400, "difficulty_slowdown_bp": 50, "risk_bp_per_point": 25, "time_cost_per_hour": 0, "fixed_cost": 0, "min_net_profit": min_net_profit, "min_margin_bp": 0, "origin_reserve_bp": RESERVE_BP})


## [o planejador real, o de referência sem a pré-checagem] sobre o MESMO mundo e o mesmo motor; `max_order` vale só para o planejador.
func _planners(rig: Rig, params: CaravanParams, engine: TradeEngine, max_order: int = MAX_ORDER) -> Array[TradePlanner]:
	var record: Dictionary = PRICE_RECORD.duplicate()
	record["max_order_quantity"] = max_order
	var price_params: PriceParams = PriceParams.new(record)
	return [TradePlanner.new(engine, rig.markets, rig.goods, rig.ledger, params, price_params), FullSearchPlanner.new(engine, rig.markets, rig.goods, rig.ledger, params, price_params)]


## Os planos de B e C com e sem a pré-checagem sobre o mesmo mundo: IDÊNTICOS, inclusive "sem plano". Devolve os planos.
func _assert_same_plans(rig: Rig, params: CaravanParams, label: String, max_order: int = MAX_ORDER, risk: int = 10) -> Array[TradePlanner.Plan]:
	var pair: Array[TradePlanner] = _planners(rig, params, rig.engine, max_order)
	var paths: Dictionary[int, Array] = {MARKET_B: _legs(520, risk), MARKET_C: _legs(340, risk + 5)}
	var plans: Array[TradePlanner.Plan] = pair[0].plan_all(TRADER, MARKET_A, paths)
	var got: Array = []
	for plan: TradePlanner.Plan in plans:
		got.append(_describe(plan))
	var want: Array = []
	for plan: TradePlanner.Plan in pair[1].plan_all(TRADER, MARKET_A, paths):
		want.append(_describe(plan))
	assert_eq(got, want, label)
	return plans


## A margem da 1ª unidade de A para B pelas cotações cruas (a conta que a pré-checagem faz).
func _first_spread(rig: Rig, good_id: String) -> int:
	var bought: TradeEngine.Outcome = rig.engine.quote(MARKET_A, good_id, 1, TradeEngine.SIDE_BUY, TRADER)
	var sold: TradeEngine.Outcome = rig.engine.quote(MARKET_B, good_id, 1, TradeEngine.SIDE_SELL, TRADER)
	return sold.total - sold.tariff - (bought.total + bought.tariff)


## O trabalho de cotação que o `plan_all` pede ao motor, com a pré-checagem ou (`full_search`) sem ela: [chamadas a `quote`, curvas pedidas, unidades precificadas por uma e outra].
func _work_of(rig: Rig, params: CaravanParams, full_search: bool, max_order: int = MAX_ORDER) -> Array[int]:
	var engine: CountingEngine = CountingEngine.new(rig.book, rig.ledger, rig.goods, rig.markets, NeutralTradeRules.new(), PriceParams.new(PRICE_RECORD))
	var paths: Dictionary[int, Array] = {MARKET_B: _legs(), MARKET_C: _legs(340, 15)}
	_planners(rig, params, engine, max_order)[1 if full_search else 0].plan_all(TRADER, MARKET_A, paths)
	return [engine.quotes, engine.curves, engine.priced]


## O pão a 5 no A (200) e a 25 no B (40): diferença grande; só A e B existem.
func _gap() -> Dictionary:
	return {MARKET_A: {"bread": [100, 200, 20000]}, MARKET_B: {"bread": [100, 40, 20000]}}


## Mundos com diferença de preço mas SEM lote possível (reserva da origem, teto do destino, mochila, bem sem peso): o `plan_all` não acha plano e a pré-checagem não cota nada.
func _no_room_cases() -> Array[Dictionary]:
	return [
		{"label": "estoque abaixo da reserva da origem", "spec": _spec(45, 10, 100), "expect": 0},
		{"label": "teto do destino já cheio", "spec": {MARKET_A: {"bread": [100, 200, 20000]}, MARKET_B: {"bread": [100, 40, 4000]}}, "expect": 0},
		{"label": "mochila cheia", "spec": _gap(), "carried": {"anvil": 12}, "expect": 0},
		{"label": "bem sem peso", "spec": {MARKET_A: {"feather": [100, 200, 20000]}, MARKET_B: {"feather": [100, 40, 20000]}}, "expect": 0}]


func test_the_precheck_changes_no_plan_in_a_grid_of_worlds() -> void:
	var rules_set: Array[TradeRules] = [NeutralTradeRules.new(), FlatTariffRules.new(100), FlatTariffRules.new(900), BanRules.new(MARKET_A), BanRules.new(MARKET_B)]
	var with_plan: int = 0
	var without_plan: int = 0
	var zero_spread: int = 0
	var negative_spread: int = 0
	var hidden: int = 0
	for rules_at: int in rules_set.size():
		for min_net_profit: int in [-3, 0, 5]:
			for a_stock: int in [5000, 5400]:
				for b_stock: int in range(3800, 4801, 200):
					var params: CaravanParams = _relaxed(min_net_profit)
					var rig: Rig = _rig({MARKET_A: {"grain": [5000, a_stock, 20000]}, MARKET_B: {"grain": [5000, b_stock, 20000]}}, _funds(), params, {}, rules_set[rules_at])
					var plans: Array[TradePlanner.Plan] = _assert_same_plans(rig, params, "curva plana, regra %d, lucro mínimo %d, A=%d B=%d" % [rules_at, min_net_profit, a_stock, b_stock])
					with_plan += 0 if plans.is_empty() else 1
					without_plan += 1 if plans.is_empty() else 0
					if rules_at == 0:
						var spread: int = _first_spread(rig, "grain")
						zero_spread += 1 if spread == 0 else 0
						negative_spread += 1 if spread < 0 else 0
						hidden += 1 if not plans.is_empty() and _net_at(rig, MARKET_A, MARKET_B, "grain", 1, _legs(), params) <= 0 else 0
	for a_stock: int in [30, 60, 100, 200]:
		for b_stock: int in [20, 40, 70, 100, 190]:
			for trader_funds: int in [10000, 100, 0]:
				var funds: Dictionary = _funds(trader_funds, 40 if b_stock == 70 else 3000)
				if trader_funds == 0:
					funds.erase(TRADER)
				var plans: Array[TradePlanner.Plan] = _assert_same_plans(_rig(_spec(a_stock, b_stock, 100), funds), _params(), "pão A=%d B=%d saldo %d" % [a_stock, b_stock, trader_funds])
				with_plan += 0 if plans.is_empty() else 1
				without_plan += 1 if plans.is_empty() else 0
	assert_gt(with_plan, 30, "A grade tem muitos casos com plano.")
	assert_gt(without_plan, 100, "A grade tem muitos casos sem plano.")
	assert_gt(zero_spread, 0, "A grade tem a margem da 1ª unidade exatamente 0.")
	assert_gt(negative_spread, 0, "A grade tem a margem da 1ª unidade negativa.")
	assert_gt(hidden, 0, "A grade tem plano atrás de uma 1ª unidade de 0 moeda ou menos depois do risco: a armadilha da saída antecipada.")


func test_the_precheck_changes_no_plan_in_the_limit_and_special_cases() -> void:
	var no_money: Dictionary = _funds()
	no_money.erase(TRADER)
	var many: Dictionary = {MARKET_A: {"bread": [100, 200, 20000], "anvil": [20, 40, 20000], "twin_a": [100, 200, 20000]}, MARKET_B: {"bread": [100, 40, 20000], "anvil": [20, 4, 20000], "twin_a": [100, 40, 20000]}}
	var cases: Array[Dictionary] = [
		{"label": "controle: lote e diferença", "spec": _gap(), "expect": MAX_ORDER},
		{"label": "saldo 0", "spec": _gap(), "funds": no_money, "expect": 0},
		{"label": "ordem máxima de 1", "spec": _gap(), "max_order": 1, "expect": 1},
		{"label": "estoque 1 acima da reserva", "spec": {MARKET_A: {"bread": [100, 51, 20000]}, MARKET_B: {"bread": [100, 15, 20000]}}, "expect": 1},
		{"label": "bem banido na origem", "spec": _gap(), "rules": BanRules.new(MARKET_A), "expect": 0},
		{"label": "bem banido no destino", "spec": _gap(), "rules": BanRules.new(MARKET_B), "expect": 0},
		{"label": "margem negativa", "spec": _spec(30, 200, 100), "expect": 0},
		{"label": "margem negativa e lucro mínimo negativo", "spec": _spec(30, 200, 100), "params": _relaxed(-5), "expect": 0},
		{"label": "lucro mínimo 0", "spec": _gap(), "params": _relaxed(0)},
		{"label": "tarifa de 5%", "spec": _gap(), "rules": FlatTariffRules.new(500)},
		{"label": "saldo do destino quase vazio", "spec": _gap(), "funds": _funds(10000, 40)},
		{"label": "vários bens", "spec": many}]
	cases.append_array(_no_room_cases())
	for test_case: Dictionary in cases:
		var params: CaravanParams = test_case.get("params", _relaxed(1))
		var rig: Rig = _rig(test_case["spec"], test_case.get("funds", _funds()), params, test_case.get("carried", {}), test_case.get("rules"))
		var plans: Array[TradePlanner.Plan] = _assert_same_plans(rig, params, str(test_case["label"]), test_case.get("max_order", MAX_ORDER))
		if test_case.has("expect"):
			assert_eq(0 if plans.is_empty() else plans[0].quantity, test_case["expect"], "%s: o lote do plano." % test_case["label"])


func test_the_precheck_keeps_a_plan_that_reaches_the_minimum_gain_exactly() -> void:
	var first: int = _first_spread(_rig(_spec(200, 40, 100), _funds()), "bread")
	assert_gt(first, 0, "Controle: a 1ª unidade rende.")
	for min_net_profit: int in [first - 1, first, first + 1]:
		var params: CaravanParams = _relaxed(min_net_profit)
		var plans: Array[TradePlanner.Plan] = _assert_same_plans(_rig(_spec(200, 40, 100), _funds(), params), params, "lucro mínimo %d" % min_net_profit, 1, 0)
		assert_eq(plans.size(), 1 if min_net_profit <= first else 0, "Lucro mínimo %d, 1ª unidade %d: com lote de 1 e sem risco nem tempo, o plano existe se e só se a 1ª unidade alcança o mínimo." % [min_net_profit, first])


func test_the_precheck_spares_the_curves_and_the_balance_search() -> void:
	var stable: Rig = _rig(_spec(100, 100, 100), _funds())
	assert_eq(_work_of(stable, _params(), false), [8, 0, 8], "Sem diferença de preço, cada um dos 2 candidatos custa só as 4 cotações da margem da 1ª unidade (8 unidades) e nenhuma curva.")
	assert_eq(_work_of(stable, _params(), true), [0, 4, 200], "A busca completa pede as 2 curvas de cada candidato (50 unidades de custo e 50 de receita) e nenhuma cotação avulsa, no mesmo mundo.")
	var small_gap: Rig = _rig(_spec(100, 70, 100), _funds())
	var spread: int = _first_spread(small_gap, "bread")
	assert_gt(spread, 0, "Controle: a 1ª unidade rende um pouco.")
	var order: int = PriceMath.ceil_div(_params().min_net_profit, spread)
	assert_eq(_work_of(small_gap, _params(), false, order), [8, 0, 8], "O maior lote (%d) cobre o lucro mínimo mas não o custo de tempo: também só as 4 cotações por candidato e nenhuma curva." % order)
	assert_eq(_work_of(small_gap, _params(), true, order), [0, 4, 4 * order], "A busca completa pede as 2 curvas de cada candidato (%d unidades de custo e %d de receita), no mesmo mundo." % [order, order])
	assert_eq(_work_of(_rig(_spec(100, 70, 100), _funds(30)), _params(), true), [0, 4, 104], "Com 30 de saldo o lote financiado é 2 (11 por unidade): cada candidato pede a curva de custo inteira (50 unidades) e a de receita só até 2.")
	for test_case: Dictionary in _no_room_cases():
		assert_eq(_work_of(_rig(test_case["spec"], _funds(), _params(), test_case.get("carried", {})), _params(), false), [0, 0, 0], "%s: sem lote possível, nada é cotado e nenhuma curva é pedida." % test_case["label"])


func test_the_precheck_keeps_what_the_search_finds_behind_a_first_unit_that_loses_money() -> void:
	var params: CaravanParams = _relaxed(-100)
	var rig: Rig = _rig(_gap(), _funds(100), params)
	var engine: ScriptedEngine = ScriptedEngine.new(rig.book, rig.ledger, rig.goods, rig.markets, NeutralTradeRules.new(), PriceParams.new(PRICE_RECORD))
	var pair: Array[TradePlanner] = _planners(rig, params, engine)
	var full: TradePlanner.Plan = pair[1].plan_for(TRADER, MARKET_A, MARKET_B, _legs())
	var plan: TradePlanner.Plan = pair[0].plan_for(TRADER, MARKET_A, MARKET_B, _legs())
	assert_not_null(full, "Controle: a busca completa acha o plano (lote de 10, o que os 100 de saldo pagam) mesmo com a 1ª unidade em prejuízo.")
	assert_not_null(plan, "A pré-checagem não descarta a margem negativa quando o lucro mínimo não é positivo.")
	if full != null and plan != null:
		assert_eq(full.quantity, 10, "Controle: o lote é o que o saldo paga.")
		assert_eq(_describe(plan), _describe(full), "O plano é o da busca completa.")
