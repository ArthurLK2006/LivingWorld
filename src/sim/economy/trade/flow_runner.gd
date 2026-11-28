class_name FlowRunner
extends RefCounted
## O fluxo agregado por rota por dentro (LW-100d1a; docs/modules/economy.md, 9.16.2, 9.16.3 e 9.16.7): LIGAR a chave de uma rota (o comando de desenvolvimento), as ENTREGAS dos lotes vencidos e os ENVIOS do início do dia, com o corte de risco. O par do `CaravanRunner`: trabalha sobre o `EconomyState` do momento e a porta de rotas do `world` (`WorldModule`) e decide pela
## `FlowRule` (função pura). Os bens só se movem por `GoodsStore.transfer` (nada nasce nem some) e NENHUM dinheiro muda: não há chamada ao `Ledger`. Não sorteia e não lê o relógio: o minuto de simulação (`hora × 60`) vem de quem chama. As consultas `peek_flow_*` (LW-100d1b) leem o livro e a MESMA decisão do envio (`_choose`), sem gravar nada. LW-100d2: a rota FECHADA segura os lotes a caminho e a reaberta os retoma (`route_state_changed`, 9.16.4).

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


## `RouteStateChanged` (LW-100d2; 9.16.4: a economia só OUVE), por `lot_id` crescente e sem sorteio: `closed` SEGURA cada lote `travelling` da rota cuja chegada ainda está no futuro (`held`: `remaining_minutes = arrives_at − now`, `arrives_at` 0) e `open` RETOMA cada `held` dela (`travelling` com `arrives_at = now + remaining_minutes`; o envio novo só vem na primeira hora do próximo dia, em `run_hour`). O lote JÁ VENCIDO (`arrives_at <= now`) não congela: chega na próxima hora cheia. A chave NÃO conta (desligar não interrompe lote). Fechar duas vezes, reabrir duas vezes,
## rota sem lote e `new_state` que não é `open` nem `closed`: nada muda. `now`: o minuto em que o evento é tratado (depois dos `tick` do passo). Quem chama sai antes com o livro virgem (9.16.6).
func route_state_changed(route_id: String, new_state: String, now: int) -> void:
	if not [WorldModule.STATE_OPEN, WorldModule.STATE_CLOSED].has(new_state):
		return
	for lot_id: int in _state.flow.lot_ids():
		var lot: FlowBook.Lot = _state.flow.lot_of(lot_id)
		if lot.route_id != route_id:
			continue
		if new_state == WorldModule.STATE_CLOSED and lot.state == FlowBook.Lot.STATE_TRAVELLING and lot.arrives_at > now:
			_state.flow.hold_lot(lot_id, lot.arrives_at - now)
		elif new_state == WorldModule.STATE_OPEN and lot.state == FlowBook.Lot.STATE_HELD:
			_state.flow.resume_lot(lot_id, now + lot.remaining_minutes)


## `peek_flow_routes` (9.16.7): as rotas já ligadas alguma vez, em cópias e por `route_id` crescente. `route_state` é o do `world` (vazio se ele não conhece a rota ou não há a porta de rotas) e `lots_count`, os lotes dela.
func routes() -> FlowReplies.RoutesQuery:
	var rows: Array[FlowReplies.RouteQuery] = []
	for route_id: String in _state.flow.route_ids():
		var row: FlowReplies.RouteQuery = FlowReplies.RouteQuery.new(_state.flow.route_of(route_id))
		var found: WorldModule.RouteStateQuery = _world.peek_route(route_id) if _world != null else null
		row.route_state = found.state if found != null and found.result.ok else ""
		for lot_id: int in _state.flow.lot_ids():
			row.lots_count += 1 if _state.flow.lot_of(lot_id).route_id == route_id else 0
		rows.append(row)
	return FlowReplies.RoutesQuery.new(Result.success(), rows)


## `peek_flow_lots` (9.16.7): os lotes (os da rota, ou todos se `route_id` é vazio), em cópias e por `lot_id` crescente. `minutes_left`: em `held`, o `remaining_minutes`; senão, o que falta para `arrives_at` no relógio `now` (0 se já venceu e espera a hora cheia).
func lots(route_id: String, now: int) -> FlowReplies.LotsQuery:
	var rows: Array[FlowReplies.LotQuery] = []
	for lot_id: int in _state.flow.lot_ids():
		var lot: FlowBook.Lot = _state.flow.lot_of(lot_id)
		if route_id == "" or lot.route_id == route_id:
			var row: FlowReplies.LotQuery = FlowReplies.LotQuery.new(lot)
			row.minutes_left = lot.remaining_minutes if lot.state == FlowBook.Lot.STATE_HELD else maxi(lot.arrives_at - now, 0)
			rows.append(row)
	return FlowReplies.LotsQuery.new(Result.success(), rows)


## `peek_flow_plan` (9.16.7): o que a regra enviaria AGORA na rota, com a chave ligada ou não (a regra é a do envio, `_choose`) e sem gravar nada, nem o resto do risco. As falhas são as do comando. Sem lote hoje (rota fechada, nada que valha o envio) a resposta é ok com `planned_quantity` 0; `sent_quantity` já leva o resto de risco de hoje (0 se a rota nunca foi ligada).
func plan(route_id: String, ids: IdGenerator) -> FlowReplies.PlanQuery:
	var refused: Result = _check_command(route_id, ids)
	if not refused.ok:
		return FlowReplies.PlanQuery.new(refused)
	var reply: FlowReplies.PlanQuery = FlowReplies.PlanQuery.new(Result.success())
	var terms: FlowRule.Terms = FlowRule.Terms.new()
	var chosen: FlowRule.Lot = _choose(route_id, terms)
	if chosen == null:
		return reply
	var row: FlowBook.RouteRow = _state.flow.route_of(route_id)
	reply.origin_market_id = chosen.origin_market_id
	reply.destination_market_id = chosen.destination_market_id
	reply.good_id = chosen.good_id
	reply.planned_quantity = chosen.quantity
	reply.sent_quantity = FlowRule.apply_cut(chosen.quantity, FlowRule.risk_bp_of(terms.risk_points, _flow), row.risk_carry_bp if row != null else 0).sent
	reply.minutes = terms.minutes
	reply.net_profit = chosen.net
	return reply


## Há com que mover bens? A porta de rotas do `world`, os parâmetros do fluxo e da caravana (uma fonte só, 9.16.2) e o motor de ordens (que vem dos mercados).
func _is_available() -> bool:
	return _world != null and _flow != null and _caravan != null and _state.engine != null


## As conferências do comando, na ordem do contrato (9.16.7): há com que ligar, a rota existe no `world` e o tipo `flow` existe e não tem saldo.
func _check_command(route_id: String, ids: IdGenerator) -> Result:
	if ids == null or not _is_available():
		return _failure(EconomyCodes.NO_ROUTE, "sem setup, sem a porta de rotas do world ou sem os parâmetros do fluxo e da caravana (9.16.7)")
	if not _world.peek_route(route_id).result.ok:
		return _failure(EconomyCodes.NO_ROUTE, "a rota '%s' não existe no world" % route_id)
	var kind: OwnerKindDef = _flow_kind()
	if kind == null:
		return _failure(EconomyCodes.NO_ROUTE, "o tipo de dono '%s' não existe nas definições" % FlowBook.KIND_FLOW)
	if kind.initial_balance != 0:
		return _failure(EconomyCodes.DATA_INVALID, "o tipo '%s' tem saldo inicial %d; esperado 0 (o fluxo não move dinheiro)" % [kind.id, kind.initial_balance])
	return Result.success()


## O tipo de dono do dono-trânsito nas definições (nulo se não existe).
func _flow_kind() -> OwnerKindDef:
	for kind: OwnerKindDef in _state.definitions.kinds:
		if kind.id == FlowBook.KIND_FLOW:
			return kind
	return null


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


## O envio de UMA rota ligada: o lote do dia (`_choose`) e o corte do risco; o resto novo do corte é gravado SEMPRE, saia lote ou não (9.16.3).
func _dispatch(row: FlowBook.RouteRow, now: int) -> void:
	var terms: FlowRule.Terms = FlowRule.Terms.new()
	var chosen: FlowRule.Lot = _choose(row.route_id, terms)
	if chosen == null:
		return
	var cut: FlowRule.Cut = FlowRule.apply_cut(chosen.quantity, FlowRule.risk_bp_of(terms.risk_points, _flow), row.risk_carry_bp)
	_state.flow.set_carry(row.route_id, cut.carry_bp)
	if cut.sent >= 1:
		_send(row.route_id, chosen, cut.sent, now, terms.minutes)


## A decisão do dia numa rota (a conta do envio e do plano; só lê): nula se a rota não está ABERTA no `world`, sem os dois mercados ou sem lote que valha. Preenche `terms` (os minutos e o risco da rota, que quem chama usa no corte).
func _choose(route_id: String, terms: FlowRule.Terms) -> FlowRule.Lot:
	var found: WorldModule.RouteStateQuery = _world.peek_route(route_id)
	if not found.result.ok or found.state != WorldModule.STATE_OPEN:
		return null
	var market_a: int = _state.markets.market_of(found.route.settlement_a_id)
	var market_b: int = _state.markets.market_of(found.route.settlement_b_id)
	if market_a == IdGenerator.NO_ID or market_b == IdGenerator.NO_ID:
		return null
	var leg: RouteCost.Leg = RouteCost.Leg.new(route_id, found.route.length_m, found.route.difficulty, found.route.risk)
	terms.minutes = RouteCost.leg_minutes(leg, _caravan)
	terms.risk_points = leg.risk
	terms.free_weight = _free_weight()
	terms.max_order_quantity = _state.definitions.price_params.max_order_quantity
	var offers: Array[FlowRule.Offer] = _offers(market_a, market_b, terms)
	offers.append_array(_offers(market_b, market_a, terms))
	return FlowRule.best_lot(offers, terms, _flow, _caravan)


## O peso que ainda cabe no dono-trânsito; antes de ele existir (a chave nunca foi ligada), o do tipo `flow` vazio, para o plano valer com a chave desligada.
func _free_weight() -> int:
	var holder_id: int = _state.flow.holder_id()
	if holder_id != IdGenerator.NO_ID:
		return _state.goods.capacity_of(holder_id) - _state.goods.weight_of(holder_id)
	var kind: OwnerKindDef = _flow_kind()
	return kind.weight_capacity if kind != null else 0


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
