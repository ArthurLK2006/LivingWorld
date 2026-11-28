class_name FlowRunner
extends RefCounted
## O fluxo agregado por rota por dentro (LW-100d1a; docs/modules/economy.md, 9.16.2, 9.16.3 e 9.16.7): LIGAR a chave de uma rota (o comando de desenvolvimento), as ENTREGAS dos lotes vencidos e os ENVIOS do início do dia, com o corte de risco. O par do `CaravanRunner`: trabalha sobre o `EconomyState` do momento e a porta de rotas do `world` (`WorldModule`) e decide pela
## `FlowRule` (função pura). Os bens só se movem por `GoodsStore.transfer` (nada nasce nem some) e NENHUM dinheiro muda: não há chamada ao `Ledger`. Não sorteia e não lê o relógio: o minuto de simulação (`hora × 60`) vem de quem chama. Rota fechada (reter e retomar) é da LW-100d2 e as consultas `peek_flow_*`, da LW-100d1b.

var _state: EconomyState
var _world: WorldModule
var _flow: FlowParams
var _caravan: CaravanParams


func _init(economy_state: EconomyState, world_module: WorldModule) -> void:
	_state = economy_state
	_world = world_module
	_flow = economy_state.definitions.flow_params
	_caravan = economy_state.definitions.caravan_params


## O comando `request_set_flow_enabled` (9.16.7), idempotente. Na PRIMEIRA ligação do jogo abre o dono-trânsito (tipo `flow`, o mesmo `OwnerBook.open_owner` do `request_open_owner`, com EXATAMENTE 1 ID de `ids`) e cria a linha da rota; tudo é conferido ANTES (nada muda e nenhum ID é gasto se falha). Desligar só muda a chave (o lote a caminho chega) e rota nunca ligada fica como está (livro virgem).
## Falhas: `ECON_NO_ROUTE` (sem `setup`, sem a porta de rotas, sem os parâmetros do fluxo ou da caravana, rota que o `world` não conhece ou sem o tipo `flow`) e `ECON_DATA_INVALID` (tipo `flow` com saldo inicial: o fluxo não move dinheiro).
func set_enabled(route_id: String, enabled: bool, ids: IdGenerator) -> Result:
	var refused: Result = _check_command(route_id, ids)
	if not refused.ok:
		return refused
	if not enabled:
		if _state.flow.route_of(route_id) != null:
			_state.flow.set_enabled(route_id, false)
		return Result.success()
	if _state.flow.holder_id() == IdGenerator.NO_ID:
		var holder_id: int = ids.next_id()
		var opened: Result = _state.book.open_owner(holder_id, FlowBook.KIND_FLOW)
		if not opened.ok:
			return opened
		_state.flow.set_holder(holder_id)
	_state.flow.set_enabled(route_id, true)
	return Result.success()


## A hora cheia `now` (= `hora × 60`; 9.16.2, "Quando roda"): primeiro as ENTREGAS dos lotes vencidos, por `lot_id` crescente; só na primeira hora de cada dia (`hora % 24 == 0`) os ENVIOS, por `route_id` crescente. Sem a porta de rotas, sem os parâmetros ou sem dono-trânsito não faz nada.
func run_hour(now: int) -> void:
	if not _is_available() or _state.flow.holder_id() == IdGenerator.NO_ID:
		return
	_deliver_due(now)
	if IntMath.floor_div(now, SimClock.MINUTES_PER_HOUR) % SimClock.HOURS_PER_DAY != 0:
		return
	for route_id: String in _state.flow.route_ids():
		var row: FlowBook.RouteRow = _state.flow.route_of(route_id)
		if row.enabled:
			_dispatch(row, now)


## Há com que mover bens? A porta de rotas do `world`, os parâmetros do fluxo e da caravana (uma fonte só, 9.16.2) e o motor de ordens (que vem dos mercados).
func _is_available() -> bool:
	return _world != null and _flow != null and _caravan != null and _state.engine != null


## As conferências do comando, na ordem do contrato (9.16.7): há com que ligar, a rota existe no `world` e o tipo `flow` existe e não tem saldo.
func _check_command(route_id: String, ids: IdGenerator) -> Result:
	if ids == null or not _is_available():
		return _failure(EconomyCodes.NO_ROUTE, "sem setup, sem a porta de rotas do world ou sem os parâmetros do fluxo e da caravana (9.16.7)")
	if not _world.peek_route(route_id).result.ok:
		return _failure(EconomyCodes.NO_ROUTE, "a rota '%s' não existe no world" % route_id)
	for kind: OwnerKindDef in _state.definitions.kinds:
		if kind.id == FlowBook.KIND_FLOW:
			if kind.initial_balance != 0:
				return _failure(EconomyCodes.DATA_INVALID, "o tipo '%s' tem saldo inicial %d; esperado 0 (o fluxo não move dinheiro)" % [kind.id, kind.initial_balance])
			return Result.success()
	return _failure(EconomyCodes.NO_ROUTE, "o tipo de dono '%s' não existe nas definições" % FlowBook.KIND_FLOW)


## A ENTREGA (9.16.3): cada lote `travelling` que venceu (`now >= arrives_at`: a primeira hora cheia em que a chegada já passou) entra no mercado de destino, por `lot_id` crescente: o que COUBER no peso dele; o resto fica no lote e tenta na hora seguinte. O teto de compra do destino NÃO é conferido (entrega não é compra) e o lote some quando chega a 0.
func _deliver_due(now: int) -> void:
	for lot_id: int in _state.flow.lot_ids():
		var lot: FlowBook.Lot = _state.flow.lot_of(lot_id)
		if lot.state != FlowBook.Lot.STATE_TRAVELLING or now < lot.arrives_at:
			continue
		var free_weight: int = _state.goods.capacity_of(lot.destination_market_id) - _state.goods.weight_of(lot.destination_market_id)
		var delivered: int = mini(lot.quantity, IntMath.floor_div(free_weight, maxi(_state.goods.weight_per_unit(lot.good_id), 1)))
		if delivered >= 1 and _state.goods.transfer(_state.flow.holder_id(), lot.destination_market_id, lot.good_id, delivered).ok:
			_state.flow.reduce_lot(lot_id, delivered)


## O envio de UMA rota ligada: só se está ABERTA no `world` e tem os dois mercados. As ofertas dos dois sentidos, o melhor lote do dia (um só, pela `FlowRule`) e o corte do risco; o resto novo do corte é gravado SEMPRE, saia lote ou não (9.16.3).
func _dispatch(row: FlowBook.RouteRow, now: int) -> void:
	var found: WorldModule.RouteStateQuery = _world.peek_route(row.route_id)
	if not found.result.ok or found.state != WorldModule.STATE_OPEN:
		return
	var market_a: int = _state.markets.market_of(found.route.settlement_a_id)
	var market_b: int = _state.markets.market_of(found.route.settlement_b_id)
	if market_a == IdGenerator.NO_ID or market_b == IdGenerator.NO_ID:
		return
	var leg: RouteCost.Leg = RouteCost.Leg.new(row.route_id, found.route.length_m, found.route.difficulty, found.route.risk)
	var terms: FlowRule.Terms = FlowRule.Terms.new()
	terms.minutes = RouteCost.leg_minutes(leg, _caravan)
	terms.risk_points = leg.risk
	terms.free_weight = _state.goods.capacity_of(_state.flow.holder_id()) - _state.goods.weight_of(_state.flow.holder_id())
	terms.max_order_quantity = _state.definitions.price_params.max_order_quantity
	var offers: Array[FlowRule.Offer] = _offers(market_a, market_b, terms)
	offers.append_array(_offers(market_b, market_a, terms))
	var chosen: FlowRule.Lot = FlowRule.best_lot(offers, terms, _flow, _caravan)
	if chosen == null:
		return
	var cut: FlowRule.Cut = FlowRule.apply_cut(chosen.quantity, FlowRule.risk_bp_of(terms.risk_points, _flow), row.risk_carry_bp)
	_state.flow.set_carry(row.route_id, cut.carry_bp)
	if cut.sent >= 1:
		_send(row.route_id, chosen, cut.sent, now, terms.minutes)


## As ofertas de um sentido: cada bem negociado nos DOIS mercados, por `good_id` crescente, com o estoque, o alvo, o teto de compra, o que já está a caminho do destino, o peso e as curvas de cotação (compra na origem e venda no destino, sem ator; só ajudam a decidir: nenhum dinheiro muda de mãos).
func _offers(origin_id: int, destination_id: int, terms: FlowRule.Terms) -> Array[FlowRule.Offer]:
	var offers: Array[FlowRule.Offer] = []
	var wanted: int = mini(_flow.daily_cap_units, terms.max_order_quantity)
	for good_id: String in _state.markets.traded_goods(_state.markets.settlement_of(origin_id)):
		if not _state.markets.is_traded(destination_id, good_id):
			continue
		var offer: FlowRule.Offer = FlowRule.Offer.new()
		offer.good_id = good_id
		offer.origin_market_id = origin_id
		offer.destination_market_id = destination_id
		offer.origin_stock = _state.goods.quantity_of(origin_id, good_id)
		offer.origin_target = _state.markets.target_of(origin_id, good_id)
		offer.destination_stock = _state.goods.quantity_of(destination_id, good_id)
		offer.destination_buy_cap = _state.markets.buy_cap_of(destination_id, good_id)
		offer.incoming = _state.flow.incoming_of(destination_id, good_id)
		offer.unit_weight = _state.goods.weight_per_unit(good_id)
		offer.buy_totals = _state.engine.quote_curve(origin_id, good_id, wanted, TradeEngine.SIDE_BUY).totals
		offer.sell_totals = _state.engine.quote_curve(destination_id, good_id, wanted, TradeEngine.SIDE_SELL).totals
		offers.append(offer)
	return offers


## Tira `sent` unidades da origem para o dono-trânsito e registra o lote, tudo ou nada: `transfer` confere antes de mexer (estoque da origem e peso do dono-trânsito) e o registro no livro não tem recusa. A chegada é a saída mais os minutos da rota (a entrega arredonda à hora cheia).
func _send(route_id: String, chosen: FlowRule.Lot, sent: int, now: int, minutes: int) -> void:
	if not _state.goods.transfer(chosen.origin_market_id, _state.flow.holder_id(), chosen.good_id, sent).ok:
		return
	var lot: FlowBook.Lot = FlowBook.Lot.new()
	lot.route_id = route_id
	lot.origin_market_id = chosen.origin_market_id
	lot.destination_market_id = chosen.destination_market_id
	lot.good_id = chosen.good_id
	lot.quantity = sent
	lot.departed_at = now
	lot.arrives_at = now + minutes
	_state.flow.add_lot(lot)


func _failure(code: String, detail: String) -> Result:
	return Result.failure(code, "FlowRunner: %s." % detail)
