extends GutTest
## LW-100d1a (docs/modules/economy.md, 9.16.2, 9.16.3, 9.16.7 e 9.16.8): o fluxo agregado FUNCIONANDO, com a economia e as rotas REAIS dos dados (`FlowRig`) e a chave ligada pelo comando de desenvolvimento. T1: a origem cai no envio e o destino só sobe na hora de entrega (3, 3 e 2 h), mais a chegada exatamente na hora cheia. T3: o corte é `floor(soma(q x risk_bp) / 10000)` com resto que persiste (duas corridas iguais, risco 0 e 25, a primeira é o oráculo do `q*`).
## T4: bens conservados e dono-trânsito = soma dos lotes a cada hora. T12: nenhum dinheiro se mexe. O comando: `ECON_DEV_ONLY` e cada causa de `ECON_NO_ROUTE` e `ECON_DATA_INVALID` sem mudar nada, 1 ID só e idempotência. As consultas `peek_flow_*`, as cadências (T5), T8 em detalhe (desligar sem interromper o lote), T10 (risco máximo) e T11 (origem na reserva, destino sem espaço e entrega parcial) são da LW-100d1b, por causa do teto de tamanho; rota fechada, da LW-100d2.

const DAY: int = 1440
const FLOW_CAPACITY: int = 5000

var _service: RouteService
var _rigs: Array[FlowRig] = []


func before_all() -> void:
	_service = CaravanRig.load_routes()


func after_each() -> void:
	for rig: FlowRig in _rigs:
		rig.release()
	_rigs.clear()


func _rig(flow: FlowParams = null, slowdown_bp: int = -1, quiet: bool = false) -> FlowRig:
	var rig: FlowRig = FlowRig.build(_service, flow, slowdown_bp, quiet)
	rig.start_new_game()
	_rigs.append(rig)
	return rig


## O bloco `trade_flow` do save da economia (vazio com o livro virgem).
func _flow(module: EconomyModule) -> Dictionary:
	var block: Dictionary = module.serialize()
	return block.get("trade_flow", {})


func _lots(module: EconomyModule) -> Array:
	return _flow(module).get("lots", [])


func _stock(rig: FlowRig, market_id: int, good_id: String) -> int:
	return rig.module.peek_stock(market_id, good_id).value


func _stocks(rig: FlowRig) -> Dictionary:
	var stocks: Dictionary = {}
	for market_id: int in [rig.market_a, rig.market_b, rig.market_c]:
		for good_id: String in FlowRig.GOODS:
			stocks["%d:%s" % [market_id, good_id]] = _stock(rig, market_id, good_id)
	return stocks


func _enable(rig: FlowRig, routes: Array[String]) -> void:
	for route: String in routes:
		assert_true(rig.module.request_set_flow_enabled(route, true).ok, route)


## Pão em sobra no mercado de origem e em falta no de destino, 30 minutos antes do dia virar: o lote do dia sai desse sentido e cada dia recomeça igual (o preço só reage ao estoque no fim do dia).
func _gap(rig: FlowRig, origin: int, destination: int) -> void:
	assert_true(rig.module.request_set_stock(origin, "bread", 600).ok)
	assert_true(rig.module.request_set_stock(destination, "bread", 0).ok)


## A conservação dos bens e do dinheiro, o `validate` e, por bem, dono-trânsito = soma dos lotes.
func _assert_consistent(rig: FlowRig) -> void:
	assert_true(rig.module.peek_goods_conservation().ok, "bens conservados")
	assert_true(rig.module.peek_conservation().ok, "dinheiro conservado")
	assert_eq(rig.module.validate().size(), 0, "validate: %s" % str(rig.module.validate()))
	var wanted: Dictionary = {}
	for lot: Dictionary in _lots(rig.module):
		wanted[lot["good_id"]] = int(wanted.get(lot["good_id"], 0)) + int(lot["quantity"])
	var held: Dictionary = {}
	for row: Dictionary in rig.module.peek_inventory(int(_flow(rig.module).get("holder_id", 0))).rows:
		held[row["good_id"]] = row["quantity"]
	assert_eq(held, wanted, "o dono-trânsito tem a soma dos lotes, por bem")


func test_each_route_sends_at_the_day_start_and_the_destination_gains_only_at_the_delivery_hour() -> void:
	for spec: Array in [[FlowRig.A_B, 143, 3, "a", "b"], [FlowRig.A_C, 124, 3, "a", "c"], [FlowRig.B_C, 96, 2, "b", "c"]]:
		var route: String = spec[0]
		var rig: FlowRig = _rig()
		_enable(rig, [route])
		rig.until(DAY - 30)
		_gap(rig, rig.module.peek_market_of("test_settlement_" + str(spec[3])).market_id, rig.module.peek_market_of("test_settlement_" + str(spec[4])).market_id)
		rig.until(DAY - 1)
		assert_eq(_lots(rig.module).size(), 0, "nada sai antes do início do dia (%s)" % route)
		var before: Dictionary = _stocks(rig)
		rig.until(DAY)
		var lots: Array = _lots(rig.module)
		assert_eq(lots.size(), 1, "um lote por rota por dia (%s)" % route)
		var lot: Dictionary = lots[0]
		var good: String = lot["good_id"]
		var origin: int = lot["origin_market_id"]
		var destination: int = lot["destination_market_id"]
		var quantity: int = lot["quantity"]
		assert_eq([lot["route_id"], lot["state"], lot["departed_at"], lot["arrives_at"]], [route, "travelling", DAY, DAY + int(spec[1])], route)
		assert_eq(_stock(rig, origin, good), int(before["%d:%s" % [origin, good]]) - quantity, "a origem cai no envio (%s)" % route)
		var rows: Array[Dictionary] = rig.module.peek_inventory(int(_flow(rig.module)["holder_id"])).rows
		assert_eq([rows.size(), rows[0]["good_id"], rows[0]["quantity"]], [1, good, quantity], "os bens estão no dono-trânsito")
		_assert_consistent(rig)
		var arrival: int = DAY + int(spec[2]) * 60
		rig.until(arrival - 1)
		assert_eq(_stock(rig, destination, good), before["%d:%s" % [destination, good]], "o destino ainda não subiu (%s)" % route)
		assert_eq(_lots(rig.module).size(), 1, "o lote ainda está a caminho (%s)" % route)
		_assert_consistent(rig)
		rig.until(arrival)
		assert_eq(_stock(rig, destination, good), int(before["%d:%s" % [destination, good]]) + quantity, "o destino sobe na hora de entrega (%s)" % route)
		assert_eq(_lots(rig.module).size(), 0, "o lote some ao chegar a 0 (%s)" % route)
		_assert_consistent(rig)


func test_a_lot_arriving_exactly_on_a_full_hour_is_delivered_in_that_hour() -> void:
	var rig: FlowRig = _rig(null, 162)
	_enable(rig, [FlowRig.B_C])
	rig.until(DAY - 30)
	_gap(rig, rig.market_b, rig.market_c)
	rig.until(DAY)
	assert_eq(_lots(rig.module).size(), 1)
	assert_eq(int(_lots(rig.module)[0]["arrives_at"]), DAY + 120, "162 pontos-base por dificuldade dão exatamente 120 minutos na B-C")
	rig.until(DAY + 119)
	assert_eq(_lots(rig.module).size(), 1, "a hora cheia anterior ainda não entrega")
	rig.until(DAY + 120)
	assert_eq(_lots(rig.module).size(), 0, "hora x 60 igual à chegada já entrega")


## Os 6 primeiros dias da A-B com o pão em sobra no A e em falta no B, para um `risk_bp_per_point`: por dia, [quantidade enviada, resto de risco depois]. O `q*` do dia não depende do corte (a decisão usa o risco da caravana), então a corrida de risco 0 é o oráculo do que a regra planejou.
func _six_days(risk_bp_per_point: int) -> Array:
	var rig: FlowRig = _rig(FlowParams.new({"id": "flow_defaults", "daily_cap_units": 50, "risk_bp_per_point": risk_bp_per_point}))
	_enable(rig, [FlowRig.A_B])
	var days: Array = []
	for day: int in range(1, 7):
		rig.until(day * DAY - 30)
		_gap(rig, rig.market_a, rig.market_b)
		rig.until(day * DAY)
		var lots: Array = _lots(rig.module)
		assert_lte(lots.size(), 1, "no máximo um lote por rota por dia")
		days.append([int(lots[0]["quantity"]) if lots.size() == 1 else 0, int(_flow(rig.module)["routes"][0]["risk_carry_bp"])])
	return days


func test_the_cut_is_exactly_the_floor_of_the_summed_risk_and_the_carry_persists() -> void:
	var planned: Array = _six_days(0)
	var cut: Array = _six_days(25)
	var planned_sum: int = 0
	var sent_sum: int = 0
	for day: int in 6:
		assert_gt(int(planned[day][0]), 0, "dia %d: a regra planeja um lote" % day)
		assert_eq(int(planned[day][1]), 0, "risco 0: nunca sobra resto")
		planned_sum += planned[day][0]
		sent_sum += cut[day][0]
		assert_lte(int(cut[day][0]), int(planned[day][0]), "mais risco nunca entrega mais")
		assert_eq(planned_sum - sent_sum, IntMath.floor_div(planned_sum * 250, 10000), "dia %d: corte acumulado = floor(soma(q x 250) / 10000)" % day)
		assert_eq(int(cut[day][1]), planned_sum * 250 % 10000, "dia %d: o resto persiste" % day)
	assert_gt(planned_sum - sent_sum, 0, "o cenário corta de verdade")


func test_goods_are_conserved_and_the_transit_owner_matches_the_lots_at_every_hour() -> void:
	var rig: FlowRig = _rig()
	_enable(rig, [FlowRig.A_B, FlowRig.A_C, FlowRig.B_C])
	for day: int in range(1, 4):
		rig.until(day * DAY - 30)
		_gap(rig, rig.market_a, rig.market_b)
		assert_true(rig.module.request_set_stock(rig.market_c, "bread", 0).ok)
		for minute: int in range(day * DAY - 30 + 60, (day + 1) * DAY - 30, 60):
			rig.until(minute)
			_assert_consistent(rig)
			if minute == day * DAY + 30:
				var route_ids: Array = _lots(rig.module).map(func(lot: Dictionary) -> String: return lot["route_id"])
				var ordered: Array = route_ids.duplicate()
				ordered.sort()
				assert_gte(route_ids.size(), 2, "dia %d: ao menos duas rotas enviaram" % day)
				assert_eq(route_ids, ordered, "dia %d: os envios saem por route_id crescente" % day)
	assert_gt(int(_flow(rig.module)["next_lot_id"]), 4, "o cenário envia de verdade")


func test_no_money_moves() -> void:
	var rig: FlowRig = _rig(null, -1, true)
	_enable(rig, [FlowRig.A_B, FlowRig.A_C, FlowRig.B_C])
	var totals: Array[Dictionary] = rig.module.peek_ledger_totals().rows
	var owners: Array[int] = [rig.market_a, rig.market_b, rig.market_c, int(_flow(rig.module)["holder_id"])]
	var balances: Array[int] = []
	for owner_id: int in owners:
		balances.append(rig.module.peek_balance(owner_id).balance)
	for day: int in range(1, 4):
		rig.until(day * DAY - 30)
		_gap(rig, rig.market_a, rig.market_b)
	rig.until(4 * DAY)
	assert_gt(int(_flow(rig.module)["next_lot_id"]), 1, "o fluxo moveu bens")
	assert_true(rig.module.peek_conservation().ok)
	assert_eq(rig.module.peek_ledger_totals().rows, totals, "os totais do Ledger não mudam")
	for index: int in owners.size():
		assert_eq(rig.module.peek_balance(owners[index]).balance, balances[index], "o saldo do dono %d não muda" % owners[index])


## Um jogo só com a economia (`World` com o módulo, a porta de rotas e o `setup`); `mutate` altera as definições antes. Devolve [módulo, `World`] (`World` nulo sem `setup`).
func _game(mutate: Callable = Callable(), with_routes: bool = true, with_setup: bool = true) -> Array:
	var definitions: EconomyDefinitions = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR, true).definitions
	definitions.caravan_params = CaravanParamsLoader.load_dir(EconomySetup.DEFAULT_DIR).params
	definitions.flow_params = FlowParamsLoader.load_dir(EconomySetup.DEFAULT_DIR).params
	if mutate.is_valid():
		mutate.call(definitions)
	var module: EconomyModule = EconomyModule.new(false, definitions, WorldModule.new(_service, true) if with_routes else null)
	if not with_setup:
		return [module, null]
	var clock: SimClock = SimClock.new()
	var world: World = World.new(SimContext.new(clock, EventBus.new(clock), WorldRng.new(FlowRig.SEED), IdGenerator.new()))
	assert_true(world.register_module("economy", module).ok)
	world.setup()
	world.post_setup()
	world.on_new_game(FlowRig.SEED)
	return [module, world]


func _next_id(world: World) -> int:
	return int(world.context.ids.serialize()["next_id"])


func test_the_command_refuses_each_cause_without_changing_anything_or_spending_an_id() -> void:
	var with_flow_kind: Callable = func(definitions: EconomyDefinitions, balance: int) -> void:
		var kinds: Array[OwnerKindDef] = []
		for kind: OwnerKindDef in definitions.kinds:
			if kind.id != FlowBook.KIND_FLOW:
				kinds.append(kind)
		if balance >= 0:
			kinds.append(OwnerKindDef.new(FlowBook.KIND_FLOW, FLOW_CAPACITY, balance))
		definitions.kinds = kinds
	var cases: Array = [
		["sem build de desenvolvimento", func(d: EconomyDefinitions) -> void: d.is_development_build = false, FlowRig.A_B, true, EconomyCodes.DEV_ONLY],
		["rota que o world não conhece", Callable(), "route_zzz", true, EconomyCodes.NO_ROUTE],
		["sem a porta de rotas", Callable(), FlowRig.A_B, false, EconomyCodes.NO_ROUTE],
		["sem flow_params", func(d: EconomyDefinitions) -> void: d.flow_params = null, FlowRig.A_B, true, EconomyCodes.NO_ROUTE],
		["sem caravan_params", func(d: EconomyDefinitions) -> void: d.caravan_params = null, FlowRig.A_B, true, EconomyCodes.NO_ROUTE],
		["sem o tipo flow", func(d: EconomyDefinitions) -> void: with_flow_kind.call(d, -1), FlowRig.A_B, true, EconomyCodes.NO_ROUTE],
		["tipo flow com saldo inicial", func(d: EconomyDefinitions) -> void: with_flow_kind.call(d, 5), FlowRig.A_B, true, EconomyCodes.DATA_INVALID],
	]
	for spec: Array in cases:
		var game: Array = _game(spec[1], spec[3])
		var module: EconomyModule = game[0]
		var world: World = game[1]
		var bytes: String = JSON.stringify(module.serialize())
		var next_id: int = _next_id(world)
		for enabled: bool in [true, false]:
			var refused: Result = module.request_set_flow_enabled(spec[2], enabled)
			assert_false(refused.ok, str(spec[0]))
			assert_eq(refused.code, spec[4], str(spec[0]))
		assert_eq(JSON.stringify(module.serialize()), bytes, "nada muda: %s" % spec[0])
		assert_eq(_next_id(world), next_id, "nenhum ID gasto: %s" % spec[0])
	var without_setup: Array = _game(Callable(), true, false)
	assert_eq((without_setup[0] as EconomyModule).request_set_flow_enabled(FlowRig.A_B, true).code, EconomyCodes.NO_ROUTE, "sem setup")


func test_the_first_enabling_opens_the_transit_owner_with_one_id_and_every_other_call_is_idempotent() -> void:
	var game: Array = _game()
	var module: EconomyModule = game[0]
	var world: World = game[1]
	var untouched: String = JSON.stringify(module.serialize())
	var first_id: int = _next_id(world)
	assert_true(module.request_set_flow_enabled(FlowRig.B_C, false).ok, "desligar rota nunca ligada")
	assert_eq(JSON.stringify(module.serialize()), untouched, "o livro segue virgem")
	assert_true(module.request_set_flow_enabled(FlowRig.A_B, true).ok)
	var holder: int = _flow(module)["holder_id"]
	assert_eq([holder, _next_id(world)], [first_id, first_id + 1], "o dono-trânsito gasta 1 ID")
	assert_eq([module.peek_inventory(holder).capacity, module.peek_balance(holder).balance], [FLOW_CAPACITY, 0], "tipo flow: peso 5000 e saldo 0")
	var enabled: String = JSON.stringify(module.serialize())
	assert_true(module.request_set_flow_enabled(FlowRig.A_B, true).ok)
	assert_eq(JSON.stringify(module.serialize()), enabled, "ligar de novo não muda nada")
	assert_true(module.request_set_flow_enabled(FlowRig.A_C, true).ok)
	assert_true(module.request_set_flow_enabled(FlowRig.A_B, false).ok)
	var routes: Array = _flow(module)["routes"]
	assert_eq([_next_id(world), routes.size(), routes[0]["enabled"], routes[1]["enabled"]], [first_id + 1, 2, false, true], "a segunda rota não gasta ID")


func test_the_book_mutators_do_their_part_and_ignore_what_does_not_apply() -> void:
	var book: FlowBook = FlowBook.new()
	assert_false(book.set_holder(0), "id 0 não é dono")
	assert_true(book.is_pristine())
	assert_true(book.set_holder(7))
	assert_false(book.set_holder(8), "o dono-trânsito é aberto uma vez")
	book.set_enabled(FlowRig.A_B, true)
	book.set_enabled(FlowRig.A_B, true)
	assert_eq([book.route_ids(), book.route_of(FlowRig.A_B).enabled, book.route_of(FlowRig.A_B).risk_carry_bp], [[FlowRig.A_B], true, 0])
	assert_true(book.set_carry(FlowRig.A_B, 9999))
	assert_false(book.set_carry(FlowRig.A_B, 10000))
	assert_false(book.set_carry("route_zzz", 5))
	assert_eq(book.route_of(FlowRig.A_B).risk_carry_bp, 9999)
	book.set_enabled(FlowRig.A_B, false)
	assert_eq([book.route_of(FlowRig.A_B).enabled, book.route_of(FlowRig.A_B).risk_carry_bp], [false, 9999], "desligar mantém o resto")
	var lot: FlowBook.Lot = FlowBook.Lot.new()
	lot.route_id = FlowRig.A_B
	lot.destination_market_id = 2
	lot.good_id = "bread"
	lot.quantity = 10
	assert_eq(book.add_lot(lot), 1)
	assert_eq([book.incoming_of(2, "bread"), book.incoming_of(3, "bread"), book.incoming_of(2, "flour")], [10, 0, 0])
	assert_eq([book.reduce_lot(1, 0), book.reduce_lot(1, 11), book.reduce_lot(9, 1)], [false, false, false])
	assert_true(book.reduce_lot(1, 4))
	assert_eq(book.lot_of(1).quantity, 6, "entrega parcial")
	assert_true(book.reduce_lot(1, 6))
	assert_eq([book.lot_of(1), book.next_lot_id(), book.incoming_of(2, "bread")], [null, 2, 0], "zero sai com o lote e o id não volta")
