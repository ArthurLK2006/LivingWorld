extends GutTest
## LW-100b: a regra pura do fluxo (`FlowRule`, docs/modules/economy.md, 9.16.2 e 9.16.3) com os números de PARTIDA em memória (50 por dia e 25 pontos-base por ponto de risco; o resto, os da caravana). O atraso usa as três rotas REAIS (data/world/routes.json); o `q*` é conferido contra uma BUSCA EXAUSTIVA escrita aqui, sem `FlowRule` (o `net` e o desempate refeitos à mão);
## o corte é conferido com resto exato e por invariante; a equivalência com o `TradePlanner` (T13) usa mercados reais montados no teste e limites altos o bastante para valer "sem limite" (capacidade do viajante 1.000.000 e saldos de 1.000.000; o planejador não é alterado).

const ROUTES_FILE: String = "res://data/world/routes.json"
const MARKET_A: int = 1
const MARKET_B: int = 2
const TRADER: int = 10
const MAX_ORDER: int = 50
const BIG: int = 1000000
const PRICE_RECORD: Dictionary = {"min_factor_bp": 5000, "max_factor_bp": 30000, "smoothing_bp": 2000, "spread_bp": 1000, "significant_change_bp": 1000, "max_order_quantity": 50, "history_days": 7, "shortage_threshold_bp": 3000, "shortage_days": 10}


class Rig:
	extends RefCounted

	var goods: GoodsStore
	var markets: MarketBook
	var engine: TradeEngine
	var planner: TradePlanner


func _caravan(min_net_profit: int = 20, min_margin_bp: int = 500) -> CaravanParams:
	return CaravanParams.new({"speed_cm_per_min": 400, "difficulty_slowdown_bp": 50, "risk_bp_per_point": 25, "time_cost_per_hour": 2, "fixed_cost": 5, "min_net_profit": min_net_profit, "min_margin_bp": min_margin_bp, "origin_reserve_bp": 5000})


func _flow(cap: int = 50, risk_bp_per_point: int = 25) -> FlowParams:
	return FlowParams.new({"daily_cap_units": cap, "risk_bp_per_point": risk_bp_per_point})


func _real_legs() -> Dictionary[String, RouteCost.Leg]:
	var legs: Dictionary[String, RouteCost.Leg] = {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(ROUTES_FILE))  # Variant: fronteira com o JSON, tipada logo abaixo.
	var rows: Array = parsed if typeof(parsed) == TYPE_ARRAY else []
	for row: Dictionary in rows:
		legs[str(row["id"])] = RouteCost.Leg.new(str(row["id"]), int(row["length_m"]), int(row["difficulty"]), int(row["risk"]))
	return legs


## Curva à mão: a unidade `i` (1 a `count`) custa `first + step × (i − 1)`; o índice da curva é a quantidade (o 0 vale 0).
func _curve(first: int, step: int, count: int) -> PackedInt64Array:
	var totals: PackedInt64Array = PackedInt64Array([0])
	for unit: int in range(1, count + 1):
		totals.append(totals[unit - 1] + first + step * (unit - 1))
	return totals


func _fill(target: Object, values: Dictionary, over: Dictionary) -> void:
	for key: String in values:
		target.set(key, values[key])
	for key: String in over:
		target.set(key, over[key])


## A oferta padrão: diferença GRANDE (compra a 100, venda a 200, sem curva), reserva 50, espaço 180 e peso livre de sobra, então `q_max` = 50 (o teto diário).
func _offer(over: Dictionary = {}) -> FlowRule.Offer:
	var offer: FlowRule.Offer = FlowRule.Offer.new()
	_fill(offer, {"good_id": "bread", "origin_market_id": MARKET_A, "destination_market_id": MARKET_B, "origin_stock": 200, "origin_target": 100, "destination_stock": 20, "destination_buy_cap": 200, "unit_weight": 1, "buy_totals": _curve(100, 0, 60), "sell_totals": _curve(200, 0, 60)}, over)
	return offer


## A rota A–B real (143 min, risco 10) com peso livre de sobra.
func _terms(over: Dictionary = {}) -> FlowRule.Terms:
	var terms: FlowRule.Terms = FlowRule.Terms.new()
	_fill(terms, {"minutes": 143, "risk_points": 10, "free_weight": 5000, "max_order_quantity": MAX_ORDER}, over)
	return terms


## A busca exaustiva, SEM `FlowRule`: refaz o `q_max` do zero (reserva e custos com `ceili` em decimal), o `net` de cada `q` de 1 a `q_max` (empate: a menor), os limiares e o desempate por ordenação. Devolve {good_id, destination, q, net} ou {} se nada passa.
func _exhaustive(offers: Array[FlowRule.Offer], terms: FlowRule.Terms, flow: FlowParams, caravan: CaravanParams) -> Dictionary:
	var valid: Array[Dictionary] = []
	var time_cost: int = ceili(terms.minutes * caravan.time_cost_per_hour / 60.0) + caravan.fixed_cost
	for offer: FlowRule.Offer in offers:
		var q_max: int = mini(mini(flow.daily_cap_units, terms.max_order_quantity), offer.origin_stock - ceili(offer.origin_target * caravan.origin_reserve_bp / 10000.0))
		q_max = mini(q_max, mini(offer.destination_buy_cap - offer.destination_stock - offer.incoming, mini(offer.buy_totals.size(), offer.sell_totals.size()) - 1))
		q_max = mini(q_max, floori(float(terms.free_weight) / offer.unit_weight) if offer.unit_weight >= 1 else 0)
		var best: Dictionary = {}
		for quantity: int in range(1, q_max + 1):
			var revenue: int = offer.sell_totals[quantity]
			var net: int = revenue - ceili(revenue * terms.risk_points * caravan.risk_bp_per_point / 10000.0) - offer.buy_totals[quantity] - time_cost
			if best.is_empty() or net > int(best["net"]):
				best = {"good_id": offer.good_id, "destination": offer.destination_market_id, "q": quantity, "net": net, "cost": offer.buy_totals[quantity]}
		if not best.is_empty() and int(best["net"]) + time_cost > 0 and int(best["net"]) >= caravan.min_net_profit and int(best["net"]) * 10000 >= caravan.min_margin_bp * int(best["cost"]):
			valid.append(best)
	valid.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return [-int(a["net"]), a["destination"], a["good_id"]] < [-int(b["net"]), b["destination"], b["good_id"]])
	return valid[0] if not valid.is_empty() else {}


func _good_defs() -> Array[GoodDef]:
	var defs: Array[GoodDef] = []
	for row: Array in [["anvil", 30, 10], ["bread", 10, 1], ["twin_a", 10, 1], ["twin_b", 10, 1]]:
		defs.append(GoodDef.new(row[0], "good.%s.name" % row[0], GoodDef.CATEGORY_PROCESSED, row[1], row[2], 0))
	return defs


## `a_over` e `b_over`: bem -> [alvo, estoque, teto em pontos-base] que muda no mercado A e no B (o resto: 100, 100 e 20000).
func _spec(a_over: Dictionary, b_over: Dictionary) -> Dictionary:
	var spec: Dictionary = {MARKET_A: {}, MARKET_B: {}}
	for good_id: String in ["anvil", "bread", "twin_a", "twin_b"]:
		spec[MARKET_A][good_id] = a_over.get(good_id, [100, 100, 20000])
		spec[MARKET_B][good_id] = b_over.get(good_id, [100, 100, 20000])
	return spec


func _rig(spec: Dictionary) -> Rig:
	var rig: Rig = Rig.new()
	var book: OwnerBook = OwnerBook.new()
	var ledger: Ledger = Ledger.new(book)
	var kinds: Array[OwnerKindDef] = [OwnerKindDef.new("market", BIG, 0), OwnerKindDef.new("merchant", BIG, 0)]
	rig.goods = GoodsStore.new(book, _good_defs(), kinds)
	var targets: Array[MarketTargetDef] = []
	for market_id: int in spec:
		assert_true(book.open_owner(market_id, "market").ok)
		assert_true(ledger.mint(market_id, BIG, Ledger.REASON_GAME_START).ok)
		for good_id: String in spec[market_id]:
			var row: Array = spec[market_id][good_id]
			targets.append(MarketTargetDef.new("mt_%d_%s" % [market_id, good_id], "settlement_%d" % market_id, good_id, row[0], row[1], row[2]))
			assert_true(rig.goods.create(market_id, good_id, row[1], GoodsStore.REASON_GAME_START).ok)
	assert_true(book.open_owner(TRADER, "merchant").ok)
	assert_true(ledger.mint(TRADER, BIG, Ledger.REASON_GAME_START).ok)
	var price_params: PriceParams = PriceParams.new(PRICE_RECORD)
	rig.markets = MarketBook.new(book, rig.goods, _good_defs(), targets, price_params)
	for market_id: int in spec:
		rig.markets.register_market("settlement_%d" % market_id, market_id)
	rig.engine = TradeEngine.new(book, ledger, rig.goods, rig.markets, NeutralTradeRules.new(), price_params)
	rig.planner = TradePlanner.new(rig.engine, rig.markets, rig.goods, ledger, _caravan(), price_params)
	return rig


## As ofertas de um sentido, resolvidas como o executor fará: curvas sem ator, estoques, alvo, teto, peso e nada a caminho.
func _offers_between(rig: Rig, origin: int, destination: int) -> Array[FlowRule.Offer]:
	var offers: Array[FlowRule.Offer] = []
	for good_id: String in rig.markets.traded_goods("settlement_%d" % origin):
		if rig.markets.is_traded(destination, good_id):
			offers.append(_offer({"good_id": good_id, "origin_market_id": origin, "destination_market_id": destination, "origin_stock": rig.goods.quantity_of(origin, good_id), "origin_target": rig.markets.target_of(origin, good_id), "destination_stock": rig.goods.quantity_of(destination, good_id), "destination_buy_cap": rig.markets.buy_cap_of(destination, good_id), "unit_weight": rig.goods.weight_per_unit(good_id), "buy_totals": rig.engine.quote_curve(origin, good_id, MAX_ORDER, TradeEngine.SIDE_BUY).totals, "sell_totals": rig.engine.quote_curve(destination, good_id, MAX_ORDER, TradeEngine.SIDE_SELL).totals}))
	return offers


func test_delivery_is_the_first_full_hour_and_never_below_the_minutes() -> void:
	var legs: Dictionary[String, RouteCost.Leg] = _real_legs()
	for row: Array in [["route_a_b", 143, 3], ["route_a_c", 124, 3], ["route_b_c", 96, 2]]:
		var minutes: int = RouteCost.leg_minutes(legs[row[0]], _caravan())
		assert_eq(minutes, row[1], "%s: os minutos vêm dos dados reais." % row[0])
		assert_eq(FlowRule.delivery_hours(minutes), row[2], "%s: a entrega cai na primeira hora cheia, para cima." % row[0])
	for pair: Array in [[60, 1], [61, 2], [120, 2], [121, 3], [1, 1], [0, 0], [-5, 0]]:
		assert_eq(FlowRule.delivery_hours(pair[0]), pair[1], "%d min: limite do arredondamento (0 ou negativo dá 0 h)." % pair[0])
	var exact: bool = true
	for minutes: int in range(1, 301):
		var hours: int = FlowRule.delivery_hours(minutes)
		exact = exact and hours * 60 >= minutes and (hours - 1) * 60 < minutes
	assert_true(exact, "De 1 a 300 min: nunca antes da chegada e nunca uma hora a mais.")


func test_risk_bp_follows_the_route_points_and_is_capped_at_10000() -> void:
	var legs: Dictionary[String, RouteCost.Leg] = _real_legs()
	for row: Array in [["route_a_b", 250], ["route_a_c", 500], ["route_b_c", 375]]:
		assert_eq(FlowRule.risk_bp_of(legs[row[0]].risk, _flow()), row[1], "%s: soma_risk × 25." % row[0])
	assert_eq(FlowRule.risk_bp_of(400, _flow()), 10000, "400 × 25: o teto exato.")
	assert_eq(FlowRule.risk_bp_of(401, _flow()), 10000, "Acima do teto: preso em 10000.")
	assert_eq(FlowRule.risk_bp_of(20, _flow(50, 0)), 0, "Sem pontos-base por ponto de risco, nada corta.")
	assert_eq(FlowRule.risk_bp_of(0, _flow()), 0, "Rota sem risco, nada corta.")


func test_the_cut_keeps_an_exact_remainder_across_days_and_small_lots() -> void:
	var carry: int = 0
	var cuts: Array = []
	var sent: Array = []
	for _day: int in range(4):
		var result: FlowRule.Cut = FlowRule.apply_cut(50, 250, carry)
		cuts.append(result.cut)
		sent.append(result.sent)
		carry = result.carry_bp
	assert_eq(cuts, [1, 1, 1, 2], "A–B, 4 dias de 50 a 250 bp: 5 de 200 (2,5%).")
	assert_eq(sent, [49, 49, 49, 48])
	assert_eq(carry, 0, "Fechou exato: não sobra resto.")
	carry = 0
	var first_cut_at: int = 0
	var total_cut: int = 0
	for send: int in range(1, 41):
		var small: FlowRule.Cut = FlowRule.apply_cut(1, 250, carry)
		total_cut += small.cut
		carry = small.carry_bp
		first_cut_at = send if small.cut == 1 and first_cut_at == 0 else first_cut_at
		assert_eq(small.sent, 0 if small.cut == 1 else 1, "Lote de 1: ou sai inteiro ou não sai.")
	assert_eq([first_cut_at, total_cut, carry], [40, 1, 0], "Lotes de 1 a 250 bp: o resto só fecha no 40º envio (e o resto novo fica registrado).")


func test_risk_zero_cuts_nothing_and_risk_ten_thousand_sends_nothing_but_loses_nothing() -> void:
	var none: FlowRule.Cut = FlowRule.apply_cut(50, 0, 1234)
	assert_eq([none.cut, none.sent, none.carry_bp], [0, 50, 1234], "Risco 0: nada corta e o resto não muda.")
	var all: FlowRule.Cut = FlowRule.apply_cut(50, 10000, 9999)
	assert_eq([all.cut, all.sent, all.carry_bp], [50, 0, 9999], "Risco 10000: o corte é o lote inteiro, nada sai, o resto fica (o bem cortado fica na origem).")
	var edge: FlowRule.Cut = FlowRule.apply_cut(1, 10000, 9999)
	assert_eq([edge.cut, edge.sent, edge.carry_bp], [1, 0, 9999], "Lote de 1, resto 9999 e risco 10000: o limite de cima.")


func test_the_cut_sum_over_a_long_sequence_is_exactly_the_floor_of_the_fraction() -> void:
	var state: int = 12345
	for basis_points: int in [250, 500, 375, 7777, 10000]:
		var carry: int = 0
		var cuts: int = 0
		var weighted: int = 0
		var consistent: bool = true
		for _step: int in range(400):
			state = (state * 1103515245 + 12345) % 2147483648
			var quantity: int = 1 + (state >> 8) % 50
			var result: FlowRule.Cut = FlowRule.apply_cut(quantity, basis_points, carry)
			consistent = consistent and result.sent + result.cut == quantity and result.cut >= 0 and result.sent >= 0 and result.carry_bp >= 0 and result.carry_bp < 10000
			carry = result.carry_bp
			cuts += result.cut
			weighted += quantity * basis_points
		assert_true(consistent, "%d bp: enviado + corte = q, corte de 0 a q e resto de 0 a 9999 em todo envio." % basis_points)
		assert_eq(cuts, IntMath.floor_div(weighted, 10000), "%d bp: soma dos cortes = floor(soma(q × bp) / 10000)." % basis_points)
		assert_eq(carry, weighted % 10000, "%d bp: o resto final é o que sobrou da soma." % basis_points)


func test_best_quantity_matches_the_exhaustive_search_in_hand_made_scenarios() -> void:
	var cases: Array[Dictionary] = [
		{"label": "preços iguais: nada", "offer": {"sell_totals": _curve(100, 0, 60)}, "q": 0},
		{"label": "diferença grande: o teto diário", "q": 50},
		{"label": "diferença pequena: meio", "offer": {"buy_totals": _curve(100, 10, 10), "sell_totals": _curve(140, -10, 10)}, "q": 2},
		{"label": "diferença só na 1ª unidade: 1", "offer": {"buy_totals": _curve(100, 40, 10), "sell_totals": _curve(150, -10, 10)}, "q": 1},
		{"label": "empate de ganho entre quantidades: a menor", "terms": {"risk_points": 0}, "offer": {"buy_totals": _curve(100, 0, 10), "sell_totals": _curve(150, -50, 5)}, "q": 1},
		{"label": "destino sem espaço", "offer": {"destination_stock": 200}, "q": 0},
		{"label": "o que está a caminho ocupa o espaço", "offer": {"destination_stock": 190, "incoming": 7}, "q": 3},
		{"label": "origem na reserva", "offer": {"origin_stock": 50}, "q": 0},
		{"label": "origem 3 acima da reserva", "offer": {"origin_stock": 53}, "q": 3},
		{"label": "reserva arredonda para cima (alvo 101: reserva 51, não 50)", "offer": {"origin_target": 101, "origin_stock": 53}, "q": 2},
		{"label": "peso curto (25 de peso livre, 10 por unidade)", "offer": {"unit_weight": 10}, "terms": {"free_weight": 25}, "q": 2},
		{"label": "sem peso livre", "terms": {"free_weight": 0}, "q": 0},
		{"label": "bem sem peso", "offer": {"unit_weight": 0}, "q": 0},
		{"label": "teto do pedido (30)", "terms": {"max_order_quantity": 30}, "q": 30},
		{"label": "teto diário (20)", "cap": 20, "q": 20},
		{"label": "curva de venda curta (7)", "offer": {"sell_totals": _curve(200, 0, 7)}, "q": 7},
		{"label": "curva de compra curta (7)", "offer": {"buy_totals": _curve(100, 0, 7)}, "q": 7},
	]
	for test_case: Dictionary in cases:
		var label: String = test_case["label"]
		var terms: FlowRule.Terms = _terms(test_case.get("terms", {}))
		var flow: FlowParams = _flow(test_case.get("cap", 50))
		var offers: Array[FlowRule.Offer] = [_offer(test_case.get("offer", {}))]
		var lot: FlowRule.Lot = FlowRule.best_lot(offers, terms, flow, _caravan())
		var oracle: Dictionary = _exhaustive(offers, terms, flow, _caravan())
		assert_eq(0 if lot == null else lot.quantity, test_case["q"], "%s: a quantidade à mão." % label)
		assert_eq(0 if lot == null else lot.quantity, int(oracle.get("q", 0)), "%s: a quantidade da busca exaustiva." % label)
		assert_eq(0 if lot == null else lot.net, int(oracle.get("net", 0)), "%s: o net da busca exaustiva." % label)


func test_both_thresholds_are_exact_at_the_limit() -> void:
	var offers: Array[FlowRule.Offer] = [_offer({"origin_stock": 51, "buy_totals": _curve(100, 0, 5), "sell_totals": _curve(133, 0, 5)})]
	var terms: FlowRule.Terms = _terms({"minutes": 60})
	var lot: FlowRule.Lot = FlowRule.best_lot(offers, terms, _flow(), _caravan(22, 2200))
	assert_not_null(lot, "Receita 133, risco 4, custo 100 e tempo 7: net 22; lucro mínimo 22 e margem 2200 bp (220000 = 2200 × 100) passam.")
	if lot == null:
		return
	assert_eq([lot.quantity, lot.cost, lot.revenue, lot.risk_discount, lot.time_cost, lot.net], [1, 100, 133, 4, 7, 22])
	assert_null(FlowRule.best_lot(offers, terms, _flow(), _caravan(23, 2200)), "Lucro mínimo 23: net 22 não basta.")
	assert_null(FlowRule.best_lot(offers, terms, _flow(), _caravan(22, 2201)), "Margem 2201 bp: 220000 < 2201 × 100.")


func test_ties_pick_the_smaller_destination_then_the_smaller_good_whatever_the_order() -> void:
	var richer: Dictionary = {"good_id": "zzz", "destination_market_id": 9, "sell_totals": _curve(201, 0, 60)}
	var sets: Array[Dictionary] = [
		{"offers": [{"good_id": "twin_b"}, {"good_id": "twin_a"}, {"good_id": "aaa", "destination_market_id": 7}], "expect": ["twin_a", MARKET_B]},
		{"offers": [{"good_id": "twin_b"}, {"good_id": "twin_a"}, richer], "expect": ["zzz", 9]},
	]
	for test_set: Dictionary in sets:
		var offers: Array[FlowRule.Offer] = []
		for over: Dictionary in test_set["offers"]:
			offers.append(_offer(over))
		for shift: int in range(offers.size()):
			var order: Array[FlowRule.Offer] = []
			order.assign(offers.slice(shift) + offers.slice(0, shift))
			for reverse: bool in [false, true]:
				if reverse:
					order.reverse()
				var lot: FlowRule.Lot = FlowRule.best_lot(order, _terms(), _flow(), _caravan())
				var again: FlowRule.Lot = FlowRule.best_lot(order, _terms(), _flow(), _caravan())
				assert_eq([lot.good_id, lot.destination_market_id, lot.net], [again.good_id, again.destination_market_id, again.net], "Função pura: mesma entrada, mesma saída.")
				assert_eq([lot.good_id, lot.destination_market_id], test_set["expect"], "Maior net; empate, menor destino e depois menor good_id, em qualquer ordem de consulta (giro %d, invertida %s)." % [shift, reverse])
				assert_eq(_exhaustive(order, _terms(), _flow(), _caravan())["good_id"], lot.good_id, "A busca exaustiva concorda no bem.")


func test_every_real_good_weighs_at_least_one_and_the_market_lists_goods_in_id_order() -> void:
	var setup: EconomySetup = EconomySetup.from_dir("res://data/economy")
	assert_true(setup.result.ok, setup.result.message)
	for good: GoodDef in setup.definitions.goods:
		assert_gte(good.weight, 1, "%s: a regra exige peso por unidade de 1 ou mais (como o planejador)." % good.id)
	var reversed_spec: Dictionary = {MARKET_A: {}, MARKET_B: {}}
	for good_id: String in ["twin_b", "twin_a", "bread", "anvil"]:
		reversed_spec[MARKET_A][good_id] = [100, 100, 20000]
		reversed_spec[MARKET_B][good_id] = [100, 100, 20000]
	assert_eq(_rig(reversed_spec).markets.traded_goods("settlement_1"), ["anvil", "bread", "twin_a", "twin_b"], "MarketBook.traded_goods ordena por good_id mesmo com os bens cadastrados ao contrário (a regra, de todo modo, não depende dessa ordem: ver o teste de desempate).")


func test_the_rule_matches_the_trade_planner_in_the_same_scenarios() -> void:
	var leg: RouteCost.Leg = _real_legs()["route_a_b"]
	var legs: Array[RouteCost.Leg] = [leg]
	var terms: FlowRule.Terms = _terms({"minutes": RouteCost.leg_minutes(leg, _caravan()), "risk_points": leg.risk})
	var scenarios: Array[Dictionary] = [
		{"label": "pão caro no B", "a": {}, "b": {"bread": [100, 40, 20000]}, "plans": 1},
		{"label": "gêmeos iguais caros no A: empate pelo good_id", "a": {"twin_a": [100, 40, 20000], "twin_b": [100, 40, 20000]}, "b": {}, "plans": 1},
		{"label": "bigorna pesada cara no A e pão com diferença pequena no B: só a bigorna passa", "a": {"anvil": [100, 30, 20000]}, "b": {"bread": [100, 70, 20000]}, "plans": 1},
		{"label": "bigorna cara no A e pão caro no B: um plano em cada sentido", "a": {"anvil": [100, 30, 20000]}, "b": {"bread": [100, 40, 20000]}, "plans": 2},
		{"label": "sem diferença: nada", "a": {}, "b": {}, "plans": 0},
		{"label": "a reserva da origem limita", "a": {"bread": [100, 70, 20000]}, "b": {"bread": [100, 20, 20000]}, "plans": 1},
		{"label": "o espaço do destino limita", "a": {"bread": [100, 200, 20000]}, "b": {"bread": [100, 80, 10000]}, "plans": 1},
	]
	for test_case: Dictionary in scenarios:
		var rig: Rig = _rig(_spec(test_case["a"], test_case["b"]))
		var found: int = 0
		for pair: Array in [[MARKET_A, MARKET_B], [MARKET_B, MARKET_A]]:
			var plan: TradePlanner.Plan = rig.planner.plan_for(TRADER, pair[0], pair[1], legs)
			var lot: FlowRule.Lot = FlowRule.best_lot(_offers_between(rig, pair[0], pair[1]), terms, _flow(), _caravan())
			var expected: Array = [] if plan == null else [plan.good_id, plan.quantity, plan.cost, plan.revenue, plan.risk_discount, plan.time_cost, plan.net_profit]
			var actual: Array = [] if lot == null else [lot.good_id, lot.quantity, lot.cost, lot.revenue, lot.risk_discount, lot.time_cost, lot.net]
			assert_eq(actual, expected, "%s (%d → %d): mesmo bem, quantidade, totais e net que o planejador." % [test_case["label"], pair[0], pair[1]])
			found += 0 if plan == null else 1
		assert_eq(found, test_case["plans"], "%s: o cenário tem os planos esperados (a equivalência não é vazia)." % test_case["label"])
