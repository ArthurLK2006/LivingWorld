class_name CaravanRunner
extends RefCounted
## A caravana por dentro (LW-098d1 e LW-098d2; docs/modules/economy.md, 9.2 a 9.8): os PLANOS (o `TradePlanner` da 098b sobre os caminhos abertos do `world`), a PARTIDA (a compra do lote, ATÔMICA, e o registro no `CaravanBook`), os cinco campos derivados de `peek_caravan` e, na 098d2,
## o AVANÇO trecho a trecho, a CHEGADA e a venda do lote (o `CaravanArrived`); a parada e o desvio são da 098e. Trabalha sobre o `EconomyState` do momento e a porta de rotas do `world` (`WorldModule`, dada pelo construtor da economia, 9.2): sem a porta, sem os parâmetros da caravana ou sem
## mercados não há caravana (`ECON_NO_ROUTE`). Dinheiro e bens só se movem no `TradeEngine.execute` (nada nasce nem some; o saldo muda só por `trade`) e o registro é a única escrita. Não sorteia e não lê o relógio: o minuto vem de quem chama.

var _state: EconomyState
var _world: WorldModule
var _params: CaravanParams


func _init(economy_state: EconomyState, world_module: WorldModule) -> void:
	_state = economy_state
	_world = world_module
	_params = economy_state.definitions.caravan_params


## `peek_trade_plans` (9.5 e 9.8): o melhor plano de cada destino com caminho aberto que passa dos limiares, pela MESMA conta do `TradePlanner`, por `destination_market_id` crescente. Não muda estado. Falhas: as de `_check_trader` e `ECON_UNKNOWN_MARKET` (a origem).
func plans(trader_id: int, origin_market_id: int) -> CaravanReplies.PlansQuery:
	var refused: Result = _check_trader(trader_id)
	if refused.ok and not _state.markets.has_market(origin_market_id):
		refused = _failure(EconomyCodes.UNKNOWN_MARKET, "o mercado %d não existe" % origin_market_id)
	if not refused.ok:
		return CaravanReplies.PlansQuery.new(refused)
	var paths: Dictionary[int, Array] = {}
	for destination_id: int in _state.markets.market_ids():
		var legs: Array[RouteCost.Leg] = _open_legs(origin_market_id, destination_id)
		if not legs.is_empty():
			paths[destination_id] = legs
	var planner: TradePlanner = TradePlanner.new(_state.engine, _state.markets, _state.goods, _state.ledger, _params, _state.definitions.price_params)
	return CaravanReplies.PlansQuery.new(Result.success(), planner.plan_all(trader_id, origin_market_id, paths))


## A PARTIDA (9.4, primeira linha; 9.6): confere TUDO antes de escrever (`_check_start`), compra o lote numa só ordem do `TradeEngine.execute` (tudo ou nada: ele confere quantidade, regras, fundos, estoque e capacidade e move dinheiro e bens) e só então registra o
## trecho 0, que começa agora. Falhou em qualquer ponto, nada mudou. NÃO exige lucro (a decisão de partir é do `npc`, 9.2). `now`: o minuto de simulação da partida; devolve o minuto previsto da chegada (a soma dos trechos) e o que o lote custou (o total pago, sem a tarifa que a regra calcula e a Fase 3 não cobra).
func start(trader_id: int, origin_id: int, destination_id: int, good_id: String, quantity: int, now: int) -> CaravanReplies.StartResult:
	var legs: Array[RouteCost.Leg] = []
	var minutes: Array[int] = []
	var refused: Result = _check_start(trader_id, origin_id, destination_id, good_id, legs, minutes)
	if not refused.ok:
		return CaravanReplies.StartResult.new(refused)
	var bought: TradeEngine.Outcome = _state.engine.execute(trader_id, origin_id, good_id, quantity, TradeEngine.SIDE_BUY)
	if not bought.result.ok:
		return CaravanReplies.StartResult.new(bought.result)
	var caravan: Caravan = Caravan.new()
	caravan.trader_id = trader_id
	caravan.origin_market_id = origin_id
	caravan.destination_market_id = destination_id
	caravan.route_ids.assign(legs.map(func(leg: RouteCost.Leg) -> String: return leg.route_id))
	caravan.leg_started_at = now
	caravan.leg_minutes = minutes[0]
	caravan.good_id = good_id
	caravan.quantity = quantity
	caravan.cost_paid = bought.total
	caravan.departed_at = now
	_state.caravans.add(caravan)
	return CaravanReplies.StartResult.new(Result.success(), now + minutes[1], bought.total)


## O AVANÇO e a CHEGADA de UMA caravana no minuto `now` (LW-098d2; 9.4): enquanto o trecho atual já acabou (`now >= leg_started_at + leg_minutes`), o seguinte começa NO MINUTO EXATO em que ele acabou (não em `now`), então o ETA não depende do tamanho do passo e vários trechos cabem num passo só. Ao fim do
## último trecho a caravana CHEGA: vende o lote (`_arrive`), apaga o registro e devolve o `CaravanArrived`, que quem chama publica (o evento só existe depois da venda e do registro apagado). Devolve `null` se não chegou. Só anda a `travelling` (a parada e o desvio são da 098e); sem a porta de rotas, sem
## os parâmetros ou com rota que o `world` não conhece, não faz nada (o registro fica como está).
func advance(trader_id: int, now: int) -> CaravanArrived:
	var caravan: Caravan = _state.caravans.caravan_of(trader_id)
	if caravan == null or caravan.state != Caravan.STATE_TRAVELLING or now < caravan.leg_started_at + caravan.leg_minutes or not _is_available():
		return null
	var legs: Array[RouteCost.Leg] = _legs_of(caravan.route_ids)
	if legs.is_empty():
		return null
	while now >= caravan.leg_started_at + caravan.leg_minutes:
		if caravan.leg_index + 1 >= legs.size():
			return _arrive(caravan)
		caravan.leg_started_at += caravan.leg_minutes
		caravan.leg_index += 1
		caravan.leg_minutes = RouteCost.leg_minutes(legs[caravan.leg_index], _params)
	_state.caravans.add(caravan)
	return null


## A linha de `peek_caravan` e de `peek_caravans_on` (cópia) com os CINCO campos derivados do trecho e do relógio (9.3), nenhum salvo: `leg_from_settlement_id` e `leg_to_settlement_id`, `leg_length_m`, `progress_m` (`floor_div(comprimento × min(minutos andados, leg_minutes), leg_minutes)`;
## parada: `elapsed_at_hold` no lugar de `agora − leg_started_at`) e `eta_minute` (a saída do trecho atual mais os minutos dos trechos que faltam; 0 em `held`). Sem a porta, sem os parâmetros ou com rota que o `world` não conhece, ficam vazios ou 0.
func row_of(caravan: Caravan, now: int) -> CaravanReplies.CaravanQuery:
	var row: CaravanReplies.CaravanQuery = CaravanReplies.CaravanQuery.new(Result.success(), caravan)
	var legs: Array[RouteCost.Leg] = []
	if _is_available():
		legs = _legs_of(caravan.route_ids)
	if legs.is_empty() or caravan.leg_index < 0 or caravan.leg_index >= legs.size() or caravan.leg_minutes < 1:
		return row
	row.leg_from_settlement_id = _settlement_at(caravan, caravan.leg_index)
	row.leg_to_settlement_id = _settlement_at(caravan, caravan.leg_index + 1)
	row.leg_length_m = legs[caravan.leg_index].length_m
	var walked: int = caravan.elapsed_at_hold if caravan.state == Caravan.STATE_HELD else now - caravan.leg_started_at
	row.progress_m = IntMath.floor_div(row.leg_length_m * clampi(walked, 0, caravan.leg_minutes), caravan.leg_minutes)
	if caravan.state == Caravan.STATE_TRAVELLING:
		var remaining: Array[RouteCost.Leg] = legs.slice(caravan.leg_index + 1)
		row.eta_minute = caravan.leg_started_at + caravan.leg_minutes + RouteCost.path_minutes(remaining, _params)
	return row


## Invariante de 9.3 que o livro não confere (ele não tem a porta de rotas): cada rota do caminho existe no `world`. Sem a porta não há como conferir (lista vazia). Uma frase por problema, como as do livro.
func route_problems() -> Array[String]:
	var problems: Array[String] = []
	if _world == null:
		return problems
	for trader_id: int in _state.caravans.trader_ids():
		for route_id: String in _state.caravans.caravan_of(trader_id).route_ids:
			if not _world.peek_route(route_id).result.ok:
				problems.append("a caravana do comerciante %d: a rota '%s' não existe no world" % [trader_id, route_id])
	return problems


## Há com que viajar? A porta de rotas do `world`, os parâmetros da caravana e o comércio (os mercados e o motor de ordens).
func _is_available() -> bool:
	return _world != null and _params != null and _state.engine != null


## Antes de plano ou partida: há com que viajar (`ECON_NO_ROUTE`), o comerciante é dono aberto (`ECON_UNKNOWN_OWNER`, `ECON_OWNER_CLOSED`) e do tipo `merchant` (`ECON_TRADER_NOT_ALLOWED`, Q2).
func _check_trader(trader_id: int) -> Result:
	if not _is_available():
		return _failure(EconomyCodes.NO_ROUTE, "sem a porta de rotas do world, sem os parâmetros da caravana ou sem mercados; esperado o módulo montado com os três (9.2)")
	var opened: Result = _state.book.check_open(trader_id)
	if not opened.ok:
		return _failure(opened.code, opened.message.trim_suffix("."))
	if _state.book.kind_of(trader_id) != CaravanBook.KIND_MERCHANT:
		return _failure(EconomyCodes.TRADER_NOT_ALLOWED, "o dono %d é do tipo '%s'; só o tipo '%s' viaja (Q2)" % [trader_id, _state.book.kind_of(trader_id), CaravanBook.KIND_MERCHANT])
	return Result.success()


## As conferências da partida, na ordem do contrato (9.8): o comerciante, sem caravana, os dois mercados, o caminho aberto (preenche `legs`; origem igual ao destino não tem) e o bem negociado nos dois. As condições da compra ficam com o `TradeEngine.execute`. `minutes` (saída): os minutos do trecho 0 e os do
## caminho inteiro, calculados AQUI, antes da compra (a divisão de `RouteCost` nunca acontece depois de mover dinheiro: a atomicidade não depende de dado válido).
func _check_start(trader_id: int, origin_id: int, destination_id: int, good_id: String, legs: Array[RouteCost.Leg], minutes: Array[int]) -> Result:
	var checked: Result = _check_trader(trader_id)
	if not checked.ok:
		return checked
	if _state.caravans.has_caravan(trader_id):
		return _failure(EconomyCodes.CARAVAN_BUSY, "o comerciante %d já tem caravana; esperado uma por comerciante" % trader_id)
	for market_id: int in [origin_id, destination_id]:
		if not _state.markets.has_market(market_id):
			return _failure(EconomyCodes.UNKNOWN_MARKET, "o mercado %d não existe" % market_id)
	legs.assign(_open_legs(origin_id, destination_id))
	if legs.is_empty():
		return _failure(EconomyCodes.NO_ROUTE, "não há caminho aberto do mercado %d ao %d (origem igual ao destino, rotas fechadas ou sem ligação)" % [origin_id, destination_id])
	for market_id: int in [origin_id, destination_id]:
		if not _state.markets.is_traded(market_id, good_id):
			return _failure(EconomyCodes.UNKNOWN_GOOD, "o bem '%s' não é negociado no mercado %d" % [good_id, market_id])
	minutes.assign([RouteCost.leg_minutes(legs[0], _params), RouteCost.path_minutes(legs, _params)])
	return Result.success()


## A venda do lote e o fim da viagem (9.4, "Venda na chegada (Q4)"): UMA ordem `execute` de venda de `q_sell` unidades; o que sobra FICA no inventário do comerciante (a LW-098g o trata). O dinheiro só muda de mãos nessa ordem (nada nasce nem some), o registro some depois dela e o evento leva o total recebido (0 se nada foi vendido).
func _arrive(caravan: Caravan) -> CaravanArrived:
	var quantity: int = _sellable_quantity(caravan)
	var revenue: int = 0
	if quantity > 0:
		var sold: TradeEngine.Outcome = _state.engine.execute(caravan.trader_id, caravan.destination_market_id, caravan.good_id, quantity, TradeEngine.SIDE_SELL)
		revenue = sold.total if sold.result.ok else 0
	_state.caravans.remove(caravan.trader_id)
	return CaravanArrived.new(caravan.trader_id, caravan.route_ids[-1], _state.markets.settlement_of(caravan.destination_market_id), revenue, caravan.cost_paid)


## `q_sell` (Q4): a maior quantidade, de 0 a `min(lote, inventário do comerciante)`, que o destino aceita (`_market_takes`). Cada condição só piora quando a quantidade cresce (o total da cotação só cresce), então a busca binária é exata.
func _sellable_quantity(caravan: Caravan) -> int:
	var low: int = 0
	var high: int = mini(caravan.quantity, _state.goods.quantity_of(caravan.trader_id, caravan.good_id))
	while low < high:
		var middle: int = IntMath.floor_div(low + high + 1, 2)
		if _market_takes(caravan, middle):
			low = middle
		else:
			high = middle - 1
	return low


## A ordem de venda de `quantity` unidades passaria no `TradeEngine.execute`? As MESMAS conferências dele: a cotação vale (regras, ator aberto, teto de compra do destino), o total não passa do saldo do mercado e a carga cabe nele (capacidade de peso).
func _market_takes(caravan: Caravan, quantity: int) -> bool:
	var market_id: int = caravan.destination_market_id
	var quoted: TradeEngine.Outcome = _state.engine.quote(market_id, caravan.good_id, quantity, TradeEngine.SIDE_SELL, caravan.trader_id)
	return quoted.result.ok and quoted.total <= _state.ledger.balance_of(market_id) and _state.goods.check_transfer(caravan.trader_id, market_id, caravan.good_id, quantity).ok


## O caminho ABERTO entre os dois mercados como trechos (`peek_path` só passa por rotas abertas); vazio se não há, se a origem é o destino ou se o `world` não conhece uma das rotas.
func _open_legs(origin_id: int, destination_id: int) -> Array[RouteCost.Leg]:
	if origin_id == destination_id:
		return []
	var path: RouteService.PathQuery = _world.peek_path(_state.markets.settlement_of(origin_id), _state.markets.settlement_of(destination_id))
	if not path.result.ok:
		return []
	return _legs_of(path.route_ids)


## As rotas como trechos, com o comprimento, a dificuldade e o risco que o `world` dá a cada uma (vazio se alguma não existe).
func _legs_of(route_ids: Array[String]) -> Array[RouteCost.Leg]:
	var legs: Array[RouteCost.Leg] = []
	for route_id: String in route_ids:
		var found: WorldModule.RouteStateQuery = _world.peek_route(route_id)
		if not found.result.ok:
			return []
		legs.append(RouteCost.Leg.new(route_id, found.route.length_m, found.route.difficulty, found.route.risk))
	return legs


## O povoado onde o trecho `leg` COMEÇA: parte do povoado da origem e segue cada rota pelo outro extremo (`Route.other_end`), assim `route_ids` carrega o caminho sem guardar povoado (9.4).
func _settlement_at(caravan: Caravan, leg: int) -> String:
	var at: String = _state.markets.settlement_of(caravan.origin_market_id)
	for index: int in leg:
		at = _world.peek_route(caravan.route_ids[index]).route.other_end(at)
	return at


func _failure(code: String, detail: String) -> Result:
	return Result.failure(code, "CaravanRunner: %s." % detail)
