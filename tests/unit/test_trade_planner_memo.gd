extends GutTest
## LW-098h3c2: a memória de cotações POR CHAMADA do `TradePlanner` (`_quote` e `_upper_quantity`; docs/modules/economy.md, 9.5) só poupa trabalho: com ela o planejador decide EXATAMENTE o que decide sem ela (a REFERÊNCIA é o `Probe` com a memória desligada: cada cotação e cada lote refeitos, a ponta da 098h3c1), não guarda nada entre chamadas públicas, nenhuma chave mistura dois pedidos (ids até `IdGenerator.MAX_ID`, quantidades acima do limite, os dois lados e dois bens) e as contagens de cotação são exatas.

const MARKET_A: int = 1
const MARKET_B: int = 2
const MARKET_C: int = 3
const TRADER: int = 10
const STRANGER: int = 99
const CAPACITY: int = 120
const MAX_ORDER: int = 50
const PRICE_RECORD: Dictionary = {"min_factor_bp": 5000, "max_factor_bp": 30000, "smoothing_bp": 2000, "spread_bp": 1000, "significant_change_bp": 1000, "max_order_quantity": 50, "history_days": 7, "shortage_threshold_bp": 3000, "shortage_days": 10}


## Regra de teste mutável: a mesma tarifa (pontos-base) em todo bem e mercado e todo bem proibido em `banned_market` (0 = nenhum).
class Rules:
	extends TradeRules

	var tariff_bp: int = 0
	var banned_market: int = 0


	func peek_terms(_good_id: String, market_id: int, _actor_id: int) -> TradeTerms:
		return TradeTerms.new(market_id == banned_market, tariff_bp, false)


## O motor que conta as cotações avulsas e as curvas pedidas.
class CountingEngine:
	extends TradeEngine

	var quotes: int = 0
	var curves: int = 0


	func quote(market_id: int, good_id: String, quantity: int, side: String, actor_id: int = IdGenerator.NO_ID) -> TradeEngine.Outcome:
		quotes += 1
		return super.quote(market_id, good_id, quantity, side, actor_id)


	func quote_curve(market_id: int, good_id: String, quantity: int, side: String, actor_id: int = IdGenerator.NO_ID) -> TradeEngine.QuoteCurve:
		curves += 1
		return super.quote_curve(market_id, good_id, quantity, side, actor_id)


## O planejador com um interruptor: `memory = false` refaz cada cotação e cada lote máximo (a REFERÊNCIA); `uppers` conta as contas do lote máximo.
class Probe:
	extends TradePlanner

	var memory: bool = true
	var uppers: int = 0


	func _quote(market_id: int, good_id: String, quantity: int, side: String, trader_id: int) -> TradeEngine.Outcome:
		return super._quote(market_id, good_id, quantity, side, trader_id) if memory else _engine.quote(market_id, good_id, quantity, side, trader_id)


	func _upper_quantity(trader_id: int, origin_id: int, destination_id: int, good_id: String) -> int:
		return super._upper_quantity(trader_id, origin_id, destination_id, good_id) if memory else _upper_quantity_raw(trader_id, origin_id, destination_id, good_id)


	func _upper_quantity_raw(trader_id: int, origin_id: int, destination_id: int, good_id: String) -> int:
		uppers += 1
		return super._upper_quantity_raw(trader_id, origin_id, destination_id, good_id)


## O planejador que guarda o que a memória entrega (cada `Outcome`, o pedido e um retrato dos campos NA ENTREGA) e o maior tamanho das memórias durante a chamada.
class Peeker:
	extends TradePlanner

	var quoted: int = 0
	var uppered: int = 0
	var handed: Array[TradeEngine.Outcome] = []
	var requests: Array = []
	var snapshots: Array = []


	static func row(outcome: TradeEngine.Outcome) -> Array:
		return [outcome.result.ok, outcome.result.code, outcome.quantity, outcome.total, outcome.tariff]


	func _quote(market_id: int, good_id: String, quantity: int, side: String, trader_id: int) -> TradeEngine.Outcome:
		var outcome: TradeEngine.Outcome = super._quote(market_id, good_id, quantity, side, trader_id)
		handed.append(outcome)
		requests.append([market_id, good_id, quantity, side, trader_id])
		snapshots.append(row(outcome))
		quoted = maxi(quoted, _quotes.size())
		return outcome


	func _upper_quantity(trader_id: int, origin_id: int, destination_id: int, good_id: String) -> int:
		var upper: int = super._upper_quantity(trader_id, origin_id, destination_id, good_id)
		uppered = maxi(uppered, _uppers.size())
		return upper


class Rig:
	extends RefCounted

	var book: OwnerBook
	var ledger: Ledger
	var goods: GoodsStore
	var markets: MarketBook
	var engine: TradeEngine
	var rules: Rules
	var params: CaravanParams
	var price_params: PriceParams


func _good_defs() -> Array[GoodDef]:
	var defs: Array[GoodDef] = []
	for row: Array in [["bread", 10, 1], ["anvil", 30, 10], ["twin_a", 10, 1], ["grain", 20, 1], ["feather", 10, 0]]:
		defs.append(GoodDef.new(row[0], "good.%s.name" % row[0], GoodDef.CATEGORY_PROCESSED, row[1], row[2], 0))
	return defs


func _params(min_net_profit: int = 20, min_margin_bp: int = 500, time_cost_per_hour: int = 2, fixed_cost: int = 5) -> CaravanParams:
	return CaravanParams.new({"speed_cm_per_min": 400, "difficulty_slowdown_bp": 50, "risk_bp_per_point": 25, "time_cost_per_hour": time_cost_per_hour, "fixed_cost": fixed_cost, "min_net_profit": min_net_profit, "min_margin_bp": min_margin_bp, "origin_reserve_bp": 5000})


func _relaxed(min_net_profit: int) -> CaravanParams:
	return _params(min_net_profit, 0, 0, 0)


## `spec`: mercado -> bem -> [alvo, estoque, teto em pontos-base]; `funds`: dono -> saldo (padrão 3000 por mercado e 10000 para o comerciante; 0 = sem saldo); `carried`: bem -> quantidade que o comerciante já leva.
func _rig(spec: Dictionary, funds: Dictionary = {}, carried: Dictionary = {}, params: CaravanParams = null) -> Rig:
	var rig: Rig = Rig.new()
	rig.rules = Rules.new()
	rig.params = params if params != null else _params()
	rig.price_params = PriceParams.new(PRICE_RECORD)
	rig.book = OwnerBook.new()
	rig.ledger = Ledger.new(rig.book)
	rig.goods = GoodsStore.new(rig.book, _good_defs(), [OwnerKindDef.new("market", 100000, 0), OwnerKindDef.new("merchant", CAPACITY, 0)])
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
	var owners: Array[int] = [TRADER]
	for market_id: int in spec:
		owners.append(market_id)
	for owner_id: int in owners:
		var amount: int = funds.get(owner_id, 10000 if owner_id == TRADER else 3000)
		if amount > 0:
			assert_true(rig.ledger.mint(owner_id, amount, Ledger.REASON_GAME_START).ok)
	rig.markets = MarketBook.new(rig.book, rig.goods, _good_defs(), targets, rig.price_params)
	for market_id: int in spec:
		rig.markets.register_market("settlement_%d" % market_id, market_id)
	rig.engine = TradeEngine.new(rig.book, rig.ledger, rig.goods, rig.markets, rig.rules, rig.price_params)
	return rig


func _prices(max_order: int) -> PriceParams:
	var record: Dictionary = PRICE_RECORD.duplicate()
	record["max_order_quantity"] = max_order
	return PriceParams.new(record)


## O planejador REAL (com a memória); `max_order` vale só para ele (o motor segue com 50).
func _real(rig: Rig, max_order: int = MAX_ORDER, engine: TradeEngine = null) -> TradePlanner:
	return TradePlanner.new(engine if engine != null else rig.engine, rig.markets, rig.goods, rig.ledger, rig.params, _prices(max_order))


func _probe(rig: Rig, memory: bool, max_order: int = MAX_ORDER, engine: TradeEngine = null) -> Probe:
	var probe: Probe = Probe.new(engine if engine != null else rig.engine, rig.markets, rig.goods, rig.ledger, rig.params, _prices(max_order))
	probe.memory = memory
	return probe


func _legs(length_m: int = 520, risk: int = 10) -> Array[RouteCost.Leg]:
	var legs: Array[RouteCost.Leg] = [RouteCost.Leg.new("route_a_b", length_m, 20, risk)]
	return legs


func _paths(risk: int = 10) -> Dictionary[int, Array]:
	var paths: Dictionary[int, Array] = {MARKET_B: _legs(520, risk), MARKET_C: _legs(340, risk + 5)}
	return paths


func _describe(plans: Array[TradePlanner.Plan]) -> Array:
	var rows: Array = []
	for plan: TradePlanner.Plan in plans:
		rows.append([plan.destination_market_id, plan.good_id, plan.quantity, plan.cost, plan.revenue, plan.risk_discount, plan.time_cost, plan.minutes, plan.net_profit, plan.margin_bp, plan.route_ids])
	return rows


func _bread(a_stock: int, b_stock: int, c_stock: int = 100) -> Dictionary:
	return {MARKET_A: {"bread": [100, a_stock, 20000]}, MARKET_B: {"bread": [100, b_stock, 20000]}, MARKET_C: {"bread": [100, c_stock, 20000]}}


## O pão a 5 no A (200) e a 25 no B (40): diferença grande; só A e B existem.
func _gap() -> Dictionary:
	return {MARKET_A: {"bread": [100, 200, 20000]}, MARKET_B: {"bread": [100, 40, 20000]}}


## Três bens (pão, bigorna, gêmeo do pão) com diferença de preço de A para B e C.
func _three_goods() -> Dictionary:
	var from: Dictionary = {"bread": [100, 200, 20000], "anvil": [20, 40, 20000], "twin_a": [100, 200, 20000]}
	var to: Dictionary = {"bread": [100, 40, 20000], "anvil": [20, 4, 20000], "twin_a": [100, 40, 20000]}
	return {MARKET_A: from, MARKET_B: to, MARKET_C: to.duplicate(true)}


func _first_spread(rig: Rig, good_id: String) -> int:
	var bought: TradeEngine.Outcome = rig.engine.quote(MARKET_A, good_id, 1, TradeEngine.SIDE_BUY, TRADER)
	var sold: TradeEngine.Outcome = rig.engine.quote(MARKET_B, good_id, 1, TradeEngine.SIDE_SELL, TRADER)
	return sold.total - sold.tariff - (bought.total + bought.tariff)


## Os planos de B e C com a memória (o planejador real, por `plan_all` e destino a destino por `plan_for`) e sem ela (a referência): IDÊNTICOS campo a campo, inclusive "sem plano". Devolve os planos.
func _assert_same(rig: Rig, label: String, max_order: int = MAX_ORDER, risk: int = 10) -> Array[TradePlanner.Plan]:
	var paths: Dictionary[int, Array] = _paths(risk)
	var plans: Array[TradePlanner.Plan] = _real(rig, max_order).plan_all(TRADER, MARKET_A, paths)
	assert_eq(_describe(plans), _describe(_probe(rig, false, max_order).plan_all(TRADER, MARKET_A, paths)), "%s: com a memória x sem ela." % label)
	var one_by_one: Array[TradePlanner.Plan] = []
	var single: TradePlanner = _real(rig, max_order)
	for destination_id: int in paths:
		var legs: Array[RouteCost.Leg] = []
		legs.assign(paths[destination_id])
		var plan: TradePlanner.Plan = single.plan_for(TRADER, MARKET_A, destination_id, legs)
		if plan != null:
			one_by_one.append(plan)
	assert_eq(_describe(one_by_one), _describe(plans), "%s: `plan_all` (cotações repartidas entre os destinos) x `plan_for` destino a destino." % label)
	return plans


func test_the_memory_changes_no_plan_in_a_grid_of_worlds() -> void:
	var with_plan: int = 0
	var without_plan: int = 0
	var only_c: int = 0
	var zero_spread: int = 0
	var negative_spread: int = 0
	for rules_at: int in 5:
		for min_net_profit: int in [-3, 0, 5]:
			for a_stock: int in [5000, 5400]:
				for b_stock: int in range(3800, 4801, 200):
					var rig: Rig = _rig({MARKET_A: {"grain": [5000, a_stock, 20000]}, MARKET_B: {"grain": [5000, b_stock, 20000]}}, {}, {}, _relaxed(min_net_profit))
					rig.rules.tariff_bp = [0, 100, 900, 0, 0][rules_at]
					rig.rules.banned_market = [0, 0, 0, MARKET_A, MARKET_B][rules_at]
					var plans: Array[TradePlanner.Plan] = _assert_same(rig, "curva plana, regra %d, lucro mínimo %d, A=%d B=%d" % [rules_at, min_net_profit, a_stock, b_stock])
					with_plan += 0 if plans.is_empty() else 1
					without_plan += 1 if plans.is_empty() else 0
					if rules_at == 0:
						zero_spread += 1 if _first_spread(rig, "grain") == 0 else 0
						negative_spread += 1 if _first_spread(rig, "grain") < 0 else 0
	for a_stock: int in [30, 60, 100, 200]:
		for b_stock: int in [20, 40, 70, 100, 190]:
			for trader_funds: int in [10000, 100, 0]:
				var plans: Array[TradePlanner.Plan] = _assert_same(_rig(_bread(a_stock, b_stock), {TRADER: trader_funds, MARKET_B: 40 if b_stock == 70 else 3000}), "pão A=%d B=%d saldo %d" % [a_stock, b_stock, trader_funds])
				with_plan += 0 if plans.is_empty() else 1
				without_plan += 1 if plans.is_empty() else 0
				only_c += 1 if plans.size() == 1 and plans[0].destination_market_id == MARKET_C else 0
	assert_gt(with_plan, 30, "A grade tem muitos casos com plano.")
	assert_gt(without_plan, 100, "A grade tem muitos casos sem plano.")
	assert_gt(zero_spread, 0, "A grade tem a margem da 1ª unidade exatamente 0.")
	assert_gt(negative_spread, 0, "A grade tem a margem da 1ª unidade negativa.")
	assert_gt(only_c, 0, "A grade tem mundos em que a pré-checagem descarta B e só C tem plano: um mercado que herda a cotação do outro erraria aqui.")


func test_the_memory_changes_no_plan_in_the_limit_and_special_cases() -> void:
	var gap: Dictionary = _gap()
	var cost_of_7: int = _rig(gap).engine.quote(MARKET_A, "bread", 7, TradeEngine.SIDE_BUY, TRADER).total
	var cases: Array[Dictionary] = [
		{"label": "controle: lote e diferença", "spec": gap, "expect": MAX_ORDER},
		{"label": "saldo 0", "spec": gap, "funds": {TRADER: 0}, "expect": 0},
		{"label": "ordem máxima de 1", "spec": gap, "max_order": 1, "expect": 1},
		{"label": "estoque 1 acima da reserva", "spec": {MARKET_A: {"bread": [100, 51, 20000]}, MARKET_B: {"bread": [100, 15, 20000]}}, "expect": 1},
		{"label": "bem banido na origem", "spec": gap, "ban": MARKET_A, "expect": 0},
		{"label": "bem banido no destino", "spec": gap, "ban": MARKET_B, "expect": 0},
		{"label": "margem negativa", "spec": _bread(30, 200), "expect": 0},
		{"label": "margem negativa e lucro mínimo negativo", "spec": _bread(30, 200), "params": _relaxed(-5), "expect": 0},
		{"label": "lucro mínimo 0", "spec": gap, "params": _relaxed(0)},
		{"label": "tarifa de 5%", "spec": gap, "tariff": 500},
		{"label": "saldo do destino quase vazio", "spec": gap, "funds": {MARKET_B: 40}},
		{"label": "vários bens", "spec": _three_goods()},
		{"label": "estoque abaixo da reserva da origem", "spec": _bread(45, 10), "expect": 0},
		{"label": "teto do destino já cheio", "spec": {MARKET_A: {"bread": [100, 200, 20000]}, MARKET_B: {"bread": [100, 40, 4000]}}, "expect": 0},
		{"label": "mochila cheia", "spec": gap, "carried": {"anvil": 12}, "expect": 0},
		{"label": "bem sem peso", "spec": {MARKET_A: {"feather": [100, 200, 20000]}, MARKET_B: {"feather": [100, 40, 20000]}}, "expect": 0},
		{"label": "saldo exatamente igual ao custo de 7 unidades", "spec": gap, "funds": {TRADER: cost_of_7}, "expect": 7},
		{"label": "saldo 1 abaixo do custo de 7 unidades", "spec": gap, "funds": {TRADER: cost_of_7 - 1}, "expect": 6}]
	for test_case: Dictionary in cases:
		var rig: Rig = _rig(test_case["spec"], test_case.get("funds", {}), test_case.get("carried", {}), test_case.get("params", _relaxed(1)))
		rig.rules.tariff_bp = test_case.get("tariff", 0)
		rig.rules.banned_market = test_case.get("ban", 0)
		var plans: Array[TradePlanner.Plan] = _assert_same(rig, str(test_case["label"]), test_case.get("max_order", MAX_ORDER))
		if test_case.has("expect"):
			assert_eq(0 if plans.is_empty() else plans[0].quantity, test_case["expect"], "%s: o lote do plano." % test_case["label"])
	var first: int = _first_spread(_rig(gap), "bread")
	assert_gt(first, 0, "Controle: a 1ª unidade rende.")
	for min_net_profit: int in [first - 1, first, first + 1]:
		assert_eq(_assert_same(_rig(gap, {}, {}, _relaxed(min_net_profit)), "lucro mínimo %d" % min_net_profit, 1, 0).size(), 1 if min_net_profit <= first else 0, "Lote de 1, sem risco nem tempo: o plano existe se e só se a 1ª unidade alcança o lucro mínimo (%d, 1ª unidade %d)." % [min_net_profit, first])


func test_no_id_and_no_quantity_makes_two_different_requests_share_an_answer() -> void:
	var ids: Array[int] = [MARKET_A, MARKET_B, (1 << 23) + MARKET_A, (1 << 31) - 2, (1 << 31) - 1, 1 << 31, (1 << 31) + MARKET_B, (1 << 43) + MARKET_A, IdGenerator.MAX_ID - 1, IdGenerator.MAX_ID]
	var spec: Dictionary = {}
	for at: int in ids.size():
		spec[ids[at]] = {"bread": [100, 20 + 20 * at, 20000], "anvil": [100, 30 + 15 * at, 20000]}
	var rig: Rig = _rig(spec)
	var planner: TradePlanner = _real(rig)
	var quantities: Array[int] = [-1, 0, 1, 2, MAX_ORDER, MAX_ORDER + 1, (1 << 19) + 1, (1 << 20) - 1, 1 << 20, (1 << 20) + 1, (1 << 21) + 1, 1 << 40]
	assert_eq([TradePlanner.MEMO_QUANTITY_LIMIT, TradePlanner.MEMO_ID_LIMIT], [1 << 20, 1 << 31], "Os limites da chave são os que a matriz abaixo usa (valores LITERAIS: o teste não acompanha a constante).")
	var mixed: Array[String] = []
	var answered: int = 0
	for _round: int in 2:
		for market_id: int in ids:
			for good_id: String in ["bread", "anvil"]:
				for side: String in [TradeEngine.SIDE_BUY, TradeEngine.SIDE_SELL, "swap"]:
					for quantity: int in quantities:
						var got: Array = Peeker.row(planner._quote(market_id, good_id, quantity, side, TRADER))
						answered += 1 if got[0] else 0
						if got != Peeker.row(rig.engine.quote(market_id, good_id, quantity, side, TRADER)):
							mixed.append("mercado %d, %s, %s, quantidade %d" % [market_id, good_id, side, quantity])
		for origin_id: int in ids:
			for destination_id: int in ids:
				for good_id: String in ["bread", "anvil"]:
					if planner._upper_quantity(TRADER, origin_id, destination_id, good_id) != planner._upper_quantity_raw(TRADER, origin_id, destination_id, good_id):
						mixed.append("lote máximo: origem %d, destino %d, %s" % [origin_id, destination_id, good_id])
	assert_eq(mixed, [] as Array[String], "Pedidos em que a memória respondeu o de outro (mercado ou origem, destino, bem, lado, quantidade).")
	assert_gt(answered, 100, "Controle: muitos pedidos válidos entre os feitos.")
	var big: Dictionary = {MARKET_A: {"bread": [100, 200, 20000]}, MARKET_B: {"bread": [100, 200, 20000]}, MARKET_C: {"bread": [100, 190, 20000]}, (1 << 31) + MARKET_B: {"bread": [100, 40, 20000]}, (1 << 43) + MARKET_C: {"bread": [100, 40, 20000]}, IdGenerator.MAX_ID: {"bread": [100, 40, 20000]}}
	var big_rig: Rig = _rig(big)
	var paths: Dictionary[int, Array] = {}
	for market_id: int in big:
		if market_id != MARKET_A:
			paths[market_id] = _legs()
	var plans: Array[TradePlanner.Plan] = _real(big_rig).plan_all(TRADER, MARKET_A, paths)
	assert_eq(_describe(plans), _describe(_probe(big_rig, false).plan_all(TRADER, MARKET_A, paths)), "Planos com ids enormes: com a memória x sem ela.")
	var planned: Array[int] = []
	for plan: TradePlanner.Plan in plans:
		planned.append(plan.destination_market_id)
	assert_eq(planned, [(1 << 31) + MARKET_B, (1 << 43) + MARKET_C, IdGenerator.MAX_ID] as Array[int], "Controle: B e C são descartados (sem lote e sem lucro) e os três mercados de ids enormes, que um id pequeno herdaria pela chave, têm plano.")


func test_a_request_outside_the_key_limits_never_touches_the_memory() -> void:
	var planner: TradePlanner = _real(_rig({MARKET_A: {"bread": [100, 200, 20000]}, MARKET_B: {"bread": [100, 40, 20000]}, (1 << 31): {"bread": [100, 40, 20000]}}))
	for quantity: int in [-1, 0, 1 << 20, (1 << 20) + 1, 1 << 40]:
		planner._quote(MARKET_A, "bread", quantity, TradeEngine.SIDE_BUY, TRADER)
	for market_id: int in [-1, 1 << 31]:
		planner._quote(market_id, "bread", 1, TradeEngine.SIDE_BUY, TRADER)
	planner._quote(MARKET_A, "bread", 1, "swap", TRADER)
	planner._upper_quantity(TRADER, 1 << 31, MARKET_B, "bread")
	planner._upper_quantity(TRADER, MARKET_A, 1 << 31, "bread")
	assert_eq([planner._quotes.size(), planner._uppers.size()], [0, 0], "Fora dos limites da chave (quantidade, id ou lado) a conta é direta e a memória não é tocada.")
	planner._quote(MARKET_A, "bread", 1, TradeEngine.SIDE_BUY, TRADER)
	planner._upper_quantity(TRADER, MARKET_A, MARKET_B, "bread")
	assert_eq([planner._quotes.size(), planner._uppers.size()], [1, 1], "Controle: dentro dos limites o pedido entra na memória.")


func _assert_forgotten(planner: Peeker, label: String) -> void:
	assert_eq([planner._quotes.size(), planner._uppers.size()], [0, 0], "%s: nenhuma cotação nem lote fica na memória depois da chamada." % label)


func test_nothing_is_kept_after_any_public_call() -> void:
	var rig: Rig = _rig(_bread(200, 40, 40))
	var peeker: Peeker = Peeker.new(rig.engine, rig.markets, rig.goods, rig.ledger, rig.params, rig.price_params)
	assert_eq(peeker.plan_all(TRADER, MARKET_A, _paths()).size(), 2, "Controle: os dois destinos têm plano.")
	assert_true(peeker.quoted > 0 and peeker.uppered > 0, "Controle: durante a chamada as duas memórias foram usadas.")
	_assert_forgotten(peeker, "`plan_all` com planos")
	assert_not_null(peeker.plan_for(TRADER, MARKET_A, MARKET_B, _legs()), "Controle: `plan_for` acha o plano.")
	_assert_forgotten(peeker, "`plan_for` com plano")
	assert_null(peeker.plan_for(TRADER, MARKET_A, MARKET_A, _legs()), "Origem igual ao destino.")
	_assert_forgotten(peeker, "`plan_for` que sai na guarda")
	assert_null(peeker.plan_for(STRANGER, MARKET_A, MARKET_B, _legs()), "Comerciante que não existe.")
	_assert_forgotten(peeker, "`plan_for` sem plano (cotação falha)")
	assert_eq(peeker.plan_all(STRANGER, MARKET_A, _paths()).size(), 0, "Comerciante que não existe: sem planos.")
	_assert_forgotten(peeker, "`plan_all` sem planos")


## A mudança de estado `change` aplicada ao mundo entre duas chamadas do MESMO planejador.
func _apply(rig: Rig, change: String) -> Result:
	match change:
		"origin_stock":
			return rig.goods.create(MARKET_A, "bread", 100, GoodsStore.REASON_GAME_START)
		"destination_stock":
			return rig.goods.destroy(MARKET_B, "bread", 60, GoodsStore.REASON_CONSUMED)
		"trader_funds":
			return rig.ledger.mint(TRADER, 10000, Ledger.REASON_GAME_START)
		"market_funds":
			return rig.ledger.mint(MARKET_B, 3000, Ledger.REASON_GAME_START)
		"unban":
			rig.rules.banned_market = 0
		"close_trader":
			return rig.book.close_owner(TRADER)
	return Result.success()


func test_a_reused_planner_answers_like_a_new_one_after_the_state_changed() -> void:
	var cases: Array[Dictionary] = [
		{"label": "estoque da origem", "spec": _bread(100, 100, 100), "change": "origin_stock", "first": false, "second": true},
		{"label": "estoque do destino", "spec": _bread(100, 100, 100), "change": "destination_stock", "first": false, "second": true},
		{"label": "saldo do comerciante", "spec": _gap(), "funds": {TRADER: 0}, "change": "trader_funds", "first": false, "second": true},
		{"label": "saldo do destino", "spec": _gap(), "funds": {MARKET_B: 0}, "change": "market_funds", "first": false, "second": true},
		{"label": "bem banido", "spec": _gap(), "ban": MARKET_B, "change": "unban", "first": false, "second": true},
		{"label": "outro comerciante (o 1º não existe)", "spec": _gap(), "trader": STRANGER, "change": "none", "first": false, "second": true},
		{"label": "dono fechado", "spec": _gap(), "change": "close_trader", "first": true, "second": false}]
	for test_case: Dictionary in cases:
		var rig: Rig = _rig(test_case["spec"], test_case.get("funds", {}))
		rig.rules.banned_market = test_case.get("ban", 0)
		var planner: TradePlanner = _real(rig)
		var first: Array = _describe(planner.plan_all(test_case.get("trader", TRADER), MARKET_A, _paths()))
		assert_eq(first.is_empty(), not test_case["first"], "%s: controle da 1ª chamada." % test_case["label"])
		assert_true(_apply(rig, test_case["change"]).ok, "%s: a mudança de estado." % test_case["label"])
		var second: Array = _describe(planner.plan_all(TRADER, MARKET_A, _paths()))
		assert_eq(second, _describe(_real(rig).plan_all(TRADER, MARKET_A, _paths())), "%s: a 2ª chamada do mesmo planejador é igual à de um planejador novo sobre o mesmo estado." % test_case["label"])
		assert_eq(second.is_empty(), not test_case["second"], "%s: controle da 2ª chamada." % test_case["label"])


func test_the_start_of_a_call_forgets_what_an_interrupted_call_left() -> void:
	var rig: Rig = _rig(_bread(100, 100, 100))
	var planner: TradePlanner = _real(rig)
	assert_null(planner._plan_for(TRADER, MARKET_A, MARKET_B, _legs()), "Controle: sem diferença de preço não há plano.")
	assert_false(planner._quotes.is_empty(), "Controle: a chamada interna não esvazia as memórias (como uma chamada que não chegou ao fim).")
	assert_true(_apply(rig, "destination_stock").ok)
	var plans: Array[TradePlanner.Plan] = planner.plan_all(TRADER, MARKET_A, _paths())
	assert_eq(_describe(plans), _describe(_real(rig).plan_all(TRADER, MARKET_A, _paths())), "A chamada seguinte não vê a cotação velha.")
	assert_false(plans.is_empty(), "Controle: com o destino escasso agora há plano.")


func test_the_shared_outcomes_are_never_changed_by_a_caller() -> void:
	var rig: Rig = _rig(_three_goods())
	rig.rules.tariff_bp = 500
	var peeker: Peeker = Peeker.new(rig.engine, rig.markets, rig.goods, rig.ledger, rig.params, rig.price_params)
	assert_eq(peeker.plan_all(TRADER, MARKET_A, _paths()).size(), 2, "Controle: os dois destinos têm plano.")
	var instances: Dictionary = {}
	for outcome: TradeEngine.Outcome in peeker.handed:
		instances[outcome.get_instance_id()] = true
	assert_gt(peeker.handed.size() - instances.size(), 0, "Controle: a memória entrega a MESMA instância a quem pede de novo.")
	var changed: Array[int] = []
	for at: int in peeker.handed.size():
		var request: Array = peeker.requests[at]
		var fresh: Array = Peeker.row(rig.engine.quote(request[0], request[1], request[2], request[3], request[4]))
		if Peeker.row(peeker.handed[at]) != peeker.snapshots[at] or peeker.snapshots[at] != fresh:
			changed.append(at)
	assert_eq(changed, [] as Array[int], "Entregas cujos campos mudaram depois da entrega ou diferem de uma cotação nova.")
	assert_gt(peeker.snapshots.filter(func(snapshot: Array) -> bool: return snapshot[4] > 0).size(), 0, "Controle: há cotações com tarifa entre as entregues.")


## [cotações avulsas, curvas, contas do lote máximo] de um `plan_all` com a memória ligada ou desligada.
func _work_of(rig: Rig, memory: bool) -> Array[int]:
	var engine: CountingEngine = CountingEngine.new(rig.book, rig.ledger, rig.goods, rig.markets, rig.rules, rig.price_params)
	var probe: Probe = _probe(rig, memory, MAX_ORDER, engine)
	probe.plan_all(TRADER, MARKET_A, _paths())
	return [engine.quotes, engine.curves, probe.uppers]


func test_the_memory_cuts_the_quotes_and_never_adds_work() -> void:
	var cases: Array[Dictionary] = [
		{"label": "sem diferença de preço (2 candidatos, ambos descartados na pré-checagem)", "spec": _bread(100, 100, 100), "off": [8, 0, 2], "on": [3, 0, 2]},
		{"label": "dois planos (2 candidatos)", "spec": _bread(200, 40, 40), "off": [8, 4, 4], "on": [3, 4, 2]},
		{"label": "três bens e dois destinos (6 candidatos)", "spec": _three_goods(), "off": [24, 12, 12], "on": [9, 12, 6]}]
	for test_case: Dictionary in cases:
		var rig: Rig = _rig(test_case["spec"])
		var off: Array[int] = _work_of(rig, false)
		var on: Array[int] = _work_of(rig, true)
		assert_eq(off, test_case["off"], "%s: sem a memória, 4 cotações por candidato e 2 contas do lote máximo por candidato que sobrevive." % test_case["label"])
		assert_eq(on, test_case["on"], "%s: com a memória, 1 compra por bem (a da origem, repartida entre os destinos) e 1 venda por bem e destino, e 1 conta do lote máximo por candidato." % test_case["label"])
		assert_true(on[0] <= off[0] and on[1] <= off[1] and on[2] <= off[2], "%s: a memória nunca aumenta o trabalho (cotações, curvas, lotes máximos)." % test_case["label"])
