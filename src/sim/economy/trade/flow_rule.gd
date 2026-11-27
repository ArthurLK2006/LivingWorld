class_name FlowRule
extends RefCounted
## A regra PURA do fluxo agregado por rota (LW-100b; docs/modules/economy.md, 9.16.2 e 9.16.3): o atraso, o corte do risco e a escolha do lote de cada rota. Funções estáticas em INTEIROS (DEC-150), sem estado, E/S, sorteio nem relógio: só DECIDE, não move bem nem dinheiro e não lê o `world`, o `MarketBook`, o `GoodsStore` nem o `Ledger`.
## Quem chama (o executor, LW-100d1) resolve a entrada: curvas, estoques, alvos, tetos, pesos e o que já está a caminho. A conta de lucro é a do `TradePlanner` (forma (ii) de 9.16.2: o planejador não é tocado e `test_flow_rule.gd` prova a equivalência), sem comerciante, saldo nem tarifa; o `RouteCost` é reusado.

## Um bem num sentido da rota, já resolvido. `buy_totals` (compra na origem) e `sell_totals` (venda no destino) são as curvas de `MarketBook.buy_curve` e `sell_curve` sem ator: o índice é a quantidade (o 0 vale 0) e o fim da curva limita `q`. `incoming`: o que desse bem já está a caminho do destino.
class Offer:
	extends RefCounted

	var good_id: String = ""
	var origin_market_id: int = 0
	var destination_market_id: int = 0
	var origin_stock: int = 0
	var origin_target: int = 0
	var destination_stock: int = 0
	var destination_buy_cap: int = 0
	var incoming: int = 0
	var unit_weight: int = 0
	var buy_totals: PackedInt64Array = PackedInt64Array()
	var sell_totals: PackedInt64Array = PackedInt64Array()


## O que vale para a rota toda no dia: os minutos da rota (`RouteCost.leg_minutes` de UMA rota), a soma de risco (`soma_risk`), o peso que ainda cabe no dono-trânsito e o `max_order_quantity` do `price_params.json`.
class Terms:
	extends RefCounted

	var minutes: int = 0
	var risk_points: int = 0
	var free_weight: int = 0
	var max_order_quantity: int = 0


## O lote escolhido: `quantity` é o `q*` (antes do corte do risco) e `net = receita − risco − custo − tempo`.
class Lot:
	extends RefCounted

	var good_id: String = ""
	var origin_market_id: int = 0
	var destination_market_id: int = 0
	var quantity: int = 0
	var cost: int = 0
	var revenue: int = 0
	var risk_discount: int = 0
	var time_cost: int = 0
	var net: int = 0


## O envio depois do corte: `cut` fica na origem, `sent` = `q* − cut` (menos de 1 = não sai lote) e `carry_bp` é o resto novo da rota (0 a 9999), que o chamador registra SEMPRE, saia lote ou não.
class Cut:
	extends RefCounted

	var cut: int = 0
	var sent: int = 0
	var carry_bp: int = 0


## As horas cheias de atraso, para cima: `ceil_div(minutos, 60)` (143 min = 3 h; 124 = 3 h; 96 = 2 h): o lote enviado na hora H entra na hora H + isto, a primeira hora cheia com `hora × 60 >= chegada`. Minutos 0 ou negativos dão 0 (uma rota real nunca dura menos de 1 min).
static func delivery_hours(minutes: int) -> int:
	return PriceMath.ceil_div(maxi(minutes, 0), RouteCost.MINUTES_PER_HOUR)


## O corte do envio em pontos-base: `min(10000, soma_risk × risk_bp_per_point)` (A–B 250, A–C 500 e B–C 375 com os dados de hoje).
static func risk_bp_of(risk_points: int, flow: FlowParams) -> int:
	return clampi(risk_points * flow.risk_bp_per_point, 0, PriceMath.BASIS)


## O corte com resto acumulado, sem sorteio: `acc = resto + q × risk_bp`; `corte = floor_div(acc, 10000)`; novo resto = `acc − corte × 10000`; `enviado = q − corte`. Com resto de 0 a 9999 e `risk_bp` de 0 a 10000, o corte vai de 0 a `q` e o corte acumulado de uma sequência é exatamente `floor(soma(q × risk_bp) / 10000)`.
static func apply_cut(quantity: int, basis_points: int, carry_bp: int) -> Cut:
	var result: Cut = Cut.new()
	var accumulated: int = carry_bp + quantity * basis_points
	result.cut = IntMath.floor_div(accumulated, PriceMath.BASIS)
	result.carry_bp = accumulated - result.cut * PriceMath.BASIS
	result.sent = quantity - result.cut
	return result


## O `q_max` de 9.16.2: o menor de `daily_cap_units`, `max_order_quantity`, o estoque da origem menos a reserva (`ceil_div(alvo × origin_reserve_bp, 10000)`), o espaço do destino (teto de compra menos estoque menos o que já está a caminho), o peso que ainda cabe no dono-trânsito e o fim das duas curvas. Zero ou negativo = sem lote; bem sem peso (`unit_weight < 1`) = 0, como no planejador.
static func max_quantity(offer: Offer, terms: Terms, flow: FlowParams, caravan: CaravanParams) -> int:
	if offer.unit_weight < 1:
		return 0
	var reserve: int = PriceMath.ceil_div(offer.origin_target * caravan.origin_reserve_bp, PriceMath.BASIS)
	var limit: int = mini(flow.daily_cap_units, terms.max_order_quantity)
	limit = mini(limit, offer.origin_stock - reserve)
	limit = mini(limit, offer.destination_buy_cap - offer.destination_stock - offer.incoming)
	limit = mini(limit, IntMath.floor_div(terms.free_weight, offer.unit_weight))
	return mini(limit, mini(offer.buy_totals.size(), offer.sell_totals.size()) - 1)


## O lote da rota no dia, ou `null` se nenhum bem em nenhum sentido passa dos limiares: o de maior `net`; empate, o menor `destination_market_id` e depois o menor `good_id` (ordem total: o resultado não depende da ordem de `offers`). Um lote por rota por dia: o chamador envia só este.
static func best_lot(offers: Array[Offer], terms: Terms, flow: FlowParams, caravan: CaravanParams) -> Lot:
	var best: Lot = null
	for offer: Offer in offers:
		var lot: Lot = _lot_of(offer, terms, flow, caravan)
		if lot != null and (best == null or _beats(lot, best)):
			best = lot
	return best


## O melhor lote do bem: `q*` por varredura EXATA de 1 a `q_max`, a `q` de maior `receita − risco − custo` (empate: a menor; o `risk_discount` e o `time_cost` são os do `RouteCost`), com ganho positivo como no planejador; só vale se `net >= min_net_profit` e `net × 10000 >= min_margin_bp × custo`.
static func _lot_of(offer: Offer, terms: Terms, flow: FlowParams, caravan: CaravanParams) -> Lot:
	var best_quantity: int = 0
	var best_gain: int = 0
	for quantity: int in range(1, max_quantity(offer, terms, flow, caravan) + 1):
		var revenue: int = offer.sell_totals[quantity]
		var gain: int = revenue - RouteCost.risk_discount(revenue, terms.risk_points, caravan) - offer.buy_totals[quantity]
		if best_quantity == 0 or gain > best_gain:
			best_quantity = quantity
			best_gain = gain
	if best_gain <= 0:
		return null
	var lot: Lot = Lot.new()
	lot.good_id = offer.good_id
	lot.origin_market_id = offer.origin_market_id
	lot.destination_market_id = offer.destination_market_id
	lot.quantity = best_quantity
	lot.cost = offer.buy_totals[best_quantity]
	lot.revenue = offer.sell_totals[best_quantity]
	lot.risk_discount = RouteCost.risk_discount(lot.revenue, terms.risk_points, caravan)
	lot.time_cost = RouteCost.time_cost(terms.minutes, caravan)
	lot.net = best_gain - lot.time_cost
	if lot.net < caravan.min_net_profit or lot.net * PriceMath.BASIS < caravan.min_margin_bp * lot.cost:
		return null
	return lot


static func _beats(lot: Lot, other: Lot) -> bool:
	if lot.net != other.net:
		return lot.net > other.net
	if lot.destination_market_id != other.destination_market_id:
		return lot.destination_market_id < other.destination_market_id
	return lot.good_id < other.good_id
