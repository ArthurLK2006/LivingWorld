class_name TradePlanner
extends RefCounted
## O planejador de lucro do comerciante (LW-098b; docs/modules/economy.md, 9.5): função PURA e compartilhada (o `TradeFlow` e o SP7 a reusam). Só LÊ (cotações, saldos, estoques, parâmetros): não move dinheiro nem bem, não cria estado e não publica evento; INTEIROS, sem sorteio.
## Para o comerciante `T` na origem `O` e cada destino `D` (o caminho já resolvido e aberto, `RouteCost.Leg`), cada bem `g` negociado nos dois mercados é um candidato. `q_max` = o menor de: peso livre de T ÷ peso do bem; estoque de O menos a reserva (`origin_reserve_bp` do ALVO de O);
## teto de compra de D menos o estoque de D; `max_order_quantity`; e o que o saldo de T paga. `custo(q)` e `receita(q)` saem do `TradeEngine`: a cotação de UMA quantidade (`quote`) ou a curva de 1 a N unidades numa passada (`quote_curve`: as mesmas conferências e a mesma aritmética, `totals[q]` igual a `quote(q)`),
## sempre pelas regras (tarifa e `banned` entram sem mudar código); a receita não passa do saldo de D (a cotação não o confere).
## `net(q) = receita − risco − custo − tempo`. `q*` = a quantidade de maior `receita − risco − custo` entre 1 e `q_max` (empate: a menor): varredura linear EXATA, porque o `ceil` do risco acumulado deixa a margem não monotônica em até 1 moeda e a busca binária podia parar antes do pico (o teste confere contra a busca exaustiva, exatamente). Os limiares (`min_net_profit` e `min_margin_bp`)
## filtram os candidatos ANTES da escolha: por destino fica o bem de maior `net` (empate: menor `good_id`) e, no geral, o maior `net` (empate: menor `destination_market_id`). Uma mercadoria por viagem (Q6).

## O custo de uma ordem que não pode ser cotada (bem banido pelas regras, dono fechado): tão alto que nenhum saldo o paga e nenhuma venda o compensa.
const UNPRICED: int = 1 << 40
## Folga da cota quando há tarifa: a tarifa é `ceil` por ORDEM, então a 1ª unidade paga até 1 moeda a mais em cada ponta que o lote (2 moedas na margem).
const TARIFF_SLACK: int = 2

var _engine: TradeEngine
var _markets: MarketBook
var _goods: GoodsStore
var _ledger: Ledger
var _params: CaravanParams
var _max_order_quantity: int


func _init(engine: TradeEngine, markets: MarketBook, goods: GoodsStore, ledger: Ledger, params: CaravanParams, price_params: PriceParams) -> void:
	_engine = engine
	_markets = markets
	_goods = goods
	_ledger = ledger
	_params = params
	_max_order_quantity = price_params.max_order_quantity


## O melhor plano de cada destino que passa dos limiares, por `destination_market_id` crescente. `paths`: destino -> o caminho resolvido até ele (`Array` de `RouteCost.Leg`).
func plan_all(trader_id: int, origin_id: int, paths: Dictionary[int, Array]) -> Array[Plan]:
	var plans: Array[Plan] = []
	var destination_ids: Array[int] = []
	destination_ids.assign(paths.keys())
	destination_ids.sort()
	for destination_id: int in destination_ids:
		var legs: Array[RouteCost.Leg] = []
		legs.assign(paths[destination_id])
		var plan: Plan = plan_for(trader_id, origin_id, destination_id, legs)
		if plan != null:
			plans.append(plan)
	return plans


## O melhor plano para um destino (`null` se nenhum bem passa dos limiares, o caminho é vazio ou a origem é o destino). `legs`: o caminho aberto de O até D.
func plan_for(trader_id: int, origin_id: int, destination_id: int, legs: Array[RouteCost.Leg]) -> Plan:
	if legs.is_empty() or origin_id == destination_id or not _markets.has_market(origin_id) or not _markets.has_market(destination_id):
		return null
	var minutes: int = RouteCost.path_minutes(legs, _params)
	var best: Plan = null
	for good_id: String in _markets.traded_goods(_markets.settlement_of(origin_id)):
		if not _markets.is_traded(destination_id, good_id):
			continue
		var candidate: Plan = _candidate(trader_id, origin_id, destination_id, good_id, legs, minutes)
		if candidate != null and (best == null or _beats(candidate, best)):
			best = candidate
	return best


## O melhor plano no geral: o maior `net_profit`; empate, o menor `destination_market_id` e, então, o menor `good_id`. `null` se a lista é vazia.
static func best_of(plans: Array[Plan]) -> Plan:
	var best: Plan = null
	for plan: Plan in plans:
		if best == null or _beats(plan, best):
			best = plan
	return best


static func _beats(plan: Plan, other: Plan) -> bool:
	if plan.net_profit != other.net_profit:
		return plan.net_profit > other.net_profit
	if plan.destination_market_id != other.destination_market_id:
		return plan.destination_market_id < other.destination_market_id
	return plan.good_id < other.good_id


## O candidato do bem no destino com a quantidade `q*`, ou `null` se não há lote ou ele não passa dos limiares.
func _candidate(trader_id: int, origin_id: int, destination_id: int, good_id: String, legs: Array[RouteCost.Leg], minutes: int) -> Plan:
	var risk_points: int = RouteCost.path_risk_points(legs)
	var time_cost: int = RouteCost.time_cost(minutes, _params)
	var min_gain: int = _params.min_net_profit + time_cost
	if _rules_out(trader_id, origin_id, destination_id, good_id, min_gain):
		return null
	var upper: int = _upper_quantity(trader_id, origin_id, destination_id, good_id)
	var costs: TradeEngine.QuoteCurve = _engine.quote_curve(origin_id, good_id, upper, TradeEngine.SIDE_BUY, trader_id)
	var q_max: int = _funded_quantity(costs, upper, _ledger.balance_of(trader_id))
	var revenues: TradeEngine.QuoteCurve = _engine.quote_curve(destination_id, good_id, q_max, TradeEngine.SIDE_SELL, trader_id)
	var market_funds: int = _ledger.balance_of(destination_id)
	var quantity: int = _best_quantity(risk_points, q_max, min_gain, costs, revenues, market_funds)
	if quantity < 1:
		return null
	var plan: Plan = Plan.new()
	plan.destination_market_id = destination_id
	plan.good_id = good_id
	plan.quantity = quantity
	plan.cost = _curve_cost(costs, quantity)
	plan.revenue = _curve_revenue(revenues, quantity, market_funds)
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


## Pré-checagem EXATA, antes da busca binária do saldo (LW-098h3b; medição da 098h): `true` só quando `_best_quantity` também daria 0. Vale porque `q_max <= _upper_quantity` e a cota dele é `q_max` vezes a margem da 1ª unidade (com a mesma folga da tarifa): sem margem negativa, se nem o maior lote possível alcança `min_gain`, nenhum `q_max` alcança; com margem negativa, a cota de todo `q_max >= 1` é negativa e `min_gain > 0` basta. Sem lote possível (`upper < 1`) não há plano e nada é cotado.
func _rules_out(trader_id: int, origin_id: int, destination_id: int, good_id: String, min_gain: int) -> bool:
	var upper: int = _upper_quantity(trader_id, origin_id, destination_id, good_id)
	if upper < 1:
		return true
	var first_spread: int = _revenue_of(trader_id, destination_id, good_id, 1) - _cost_of(trader_id, origin_id, good_id, 1)
	var spread: int = first_spread + (TARIFF_SLACK if _is_taxed(trader_id, origin_id, destination_id, good_id) else 0)
	if spread >= 0:
		return spread * upper < min_gain
	return min_gain > 0


## `q_max` (9.5): o limite do `_upper_quantity` e depois o que o saldo paga (`custo` só cresce com `q`, então aqui a busca binária é exata), lida da curva de custo da origem. Menos de 1 = sem lote.
func _funded_quantity(costs: TradeEngine.QuoteCurve, upper: int, funds: int) -> int:
	var low: int = 0
	var high: int = upper
	while low < high:
		var middle: int = IntMath.floor_div(low + high + 1, 2)
		if _curve_cost(costs, middle) <= funds:
			low = middle
		else:
			high = middle - 1
	return low


## O maior lote que NÃO depende de cotação (9.5): o menor dos limites de peso livre, estoque com reserva, teto do destino e ordem. Zero se o bem não pesa nada (`weight_per_unit < 1`); pode ser negativo (reserva acima do estoque); `q_max` nunca passa dele.
func _upper_quantity(trader_id: int, origin_id: int, destination_id: int, good_id: String) -> int:
	var unit_weight: int = _goods.weight_per_unit(good_id)
	if unit_weight < 1:
		return 0
	var reserve: int = PriceMath.ceil_div(_markets.target_of(origin_id, good_id) * _params.origin_reserve_bp, PriceMath.BASIS)
	var by_weight: int = IntMath.floor_div(_goods.capacity_of(trader_id) - _goods.weight_of(trader_id), unit_weight)
	var by_stock: int = _goods.quantity_of(origin_id, good_id) - reserve
	var by_cap: int = _markets.buy_cap_of(destination_id, good_id) - _goods.quantity_of(destination_id, good_id)
	return mini(mini(by_weight, by_stock), mini(by_cap, _max_order_quantity))


## `q*`: a `q` de maior ganho entre 1 e `q_max` (empate: a menor), lida das curvas de custo e de receita: varredura linear exata, sem nenhuma cotação nova. Saída antecipada com COTA EXATA: a margem de cada unidade (receita menos custo) só decresce com a quantidade, então nenhuma `q` rende mais que `q_max` vezes a margem da 1ª unidade (o risco só diminui o ganho; com tarifa, que é `ceil` por ordem, a cota ganha a folga `TARIFF_SLACK`); se isso não chega a `min_gain` (o limiar de lucro mais o custo de tempo), não há plano. Passando da cota, varre tudo: uma curva plana pode esconder ganho atrás de uma 1ª unidade de 0 moeda depois do risco (a saída da 1ª versão, por "1ª unidade não rende", perdia esses planos).
func _best_quantity(risk_points: int, q_max: int, min_gain: int, costs: TradeEngine.QuoteCurve, revenues: TradeEngine.QuoteCurve, market_funds: int) -> int:
	if q_max < 1:
		return 0
	var first_spread: int = _curve_revenue(revenues, 1, market_funds) - _curve_cost(costs, 1)
	var slack: int = TARIFF_SLACK if _curve_tariff(costs, 1) > 0 or _curve_tariff(revenues, 1) > 0 else 0
	if (first_spread + slack) * q_max < min_gain:
		return 0
	var best_gain: int = _curve_gain(risk_points, 1, costs, revenues, market_funds)
	var best_quantity: int = 1
	for quantity: int in range(2, q_max + 1):
		var gain: int = _curve_gain(risk_points, quantity, costs, revenues, market_funds)
		if gain > best_gain:
			best_gain = gain
			best_quantity = quantity
	return best_quantity if best_gain > 0 else 0


## Há tarifa na cotação de 1 unidade (compra na origem ou venda no destino)? Com a regra neutra da Fase 3, nunca.
func _is_taxed(trader_id: int, origin_id: int, destination_id: int, good_id: String) -> bool:
	var bought: TradeEngine.Outcome = _engine.quote(origin_id, good_id, 1, TradeEngine.SIDE_BUY, trader_id)
	var sold: TradeEngine.Outcome = _engine.quote(destination_id, good_id, 1, TradeEngine.SIDE_SELL, trader_id)
	return bought.tariff > 0 or sold.tariff > 0


## `receita − risco − custo` de `quantity` unidades (0 para 0 unidades), pelas curvas.
func _curve_gain(risk_points: int, quantity: int, costs: TradeEngine.QuoteCurve, revenues: TradeEngine.QuoteCurve, market_funds: int) -> int:
	if quantity < 1:
		return 0
	var revenue: int = _curve_revenue(revenues, quantity, market_funds)
	return revenue - RouteCost.risk_discount(revenue, risk_points, _params) - _curve_cost(costs, quantity)


## O mesmo que `_cost_of` e `_revenue_of`, lido da curva (`UNPRICED` e 0 onde a cotação falharia) e, para a tarifa, o que `quote` devolve nela (0 onde falharia).
func _curve_cost(curve: TradeEngine.QuoteCurve, quantity: int) -> int:
	return curve.totals[quantity] + curve.tariffs[quantity] if quantity >= 1 and quantity <= curve.ok_through else UNPRICED


func _curve_revenue(curve: TradeEngine.QuoteCurve, quantity: int, market_funds: int) -> int:
	return mini(curve.totals[quantity] - curve.tariffs[quantity], market_funds) if quantity >= 1 and quantity <= curve.ok_through else 0


func _curve_tariff(curve: TradeEngine.QuoteCurve, quantity: int) -> int:
	return curve.tariffs[quantity] if quantity >= 1 and quantity <= curve.ok_through else 0


## `custo(q)`: o total da compra na origem mais a tarifa (`UNPRICED` se a cotação falha).
func _cost_of(trader_id: int, market_id: int, good_id: String, quantity: int) -> int:
	var bought: TradeEngine.Outcome = _engine.quote(market_id, good_id, quantity, TradeEngine.SIDE_BUY, trader_id)
	return bought.total + bought.tariff if bought.result.ok else UNPRICED


## `receita(q)`: o total da venda no destino menos a tarifa, sem passar do saldo do mercado (0 se a cotação falha).
func _revenue_of(trader_id: int, market_id: int, good_id: String, quantity: int) -> int:
	var sold: TradeEngine.Outcome = _engine.quote(market_id, good_id, quantity, TradeEngine.SIDE_SELL, trader_id)
	return mini(sold.total - sold.tariff, _ledger.balance_of(market_id)) if sold.result.ok else 0


## Um plano de viagem: o que `peek_trade_plans` (LW-098d1) devolve por destino, mais o `time_cost` que entra no `net_profit`.
class Plan:
	extends RefCounted

	var destination_market_id: int
	var good_id: String
	var quantity: int
	var cost: int
	var revenue: int
	var risk_discount: int
	var time_cost: int
	var minutes: int
	var net_profit: int
	var margin_bp: int
	var route_ids: Array[String] = []
