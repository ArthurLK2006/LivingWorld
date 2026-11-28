extends FlowTestBase
## LW-100d1b (docs/modules/economy.md, 9.16.7): as três consultas do fluxo agregado, em CÓPIAS e só leitura, com a economia e as rotas REAIS. `peek_flow_routes` (as rotas já ligadas alguma vez, por `route_id`), `peek_flow_lots` (todos os campos do lote, a ordem por `lot_id`, o filtro por rota e os `minutes_left`, inclusive em `held`) e `peek_flow_plan` (o que a regra enviaria agora, com a chave nunca ligada, ligada ou desligada; `ECON_NO_ROUTE` nos casos do comando). Consultar ou mexer na resposta nunca muda o livro nem o hash.


func _snapshot(rig: FlowRig) -> String:
	return JSON.stringify(rig.module.serialize()) + rig.runner.world.state_hash()


func test_peek_flow_routes_lists_only_the_routes_ever_enabled_by_route_id() -> void:
	var rig: FlowRig = _rig()
	var untouched: FlowReplies.RoutesQuery = rig.module.peek_flow_routes()
	assert_eq([untouched.result.ok, untouched.rows.size()], [true, 0], "livro virgem: lista vazia")
	_enable(rig, [FlowRig.B_C, FlowRig.A_B])
	assert_true(rig.module.request_set_flow_enabled(FlowRig.B_C, false).ok)
	rig.until(DAY - 30)
	_gap(rig, rig.market_a, rig.market_b)
	rig.until(DAY)
	var rows: Array[FlowReplies.RouteQuery] = rig.module.peek_flow_routes().rows
	assert_eq(rows.size(), 2, "A_C nunca foi ligada")
	assert_eq([rows[0].route_id, rows[0].enabled, rows[0].route_state, rows[0].lots_count], [FlowRig.A_B, true, WorldModule.STATE_OPEN, 1])
	assert_eq([rows[1].route_id, rows[1].enabled, rows[1].route_state, rows[1].lots_count], [FlowRig.B_C, false, WorldModule.STATE_OPEN, 0], "desligada segue na lista")
	assert_eq([rows[0].risk_carry_bp, rows[1].risk_carry_bp], [_carry(rig.module, 0), _carry(rig.module, 1)], "o resto vem do livro")
	assert_gt(rows[0].risk_carry_bp, 0, "a A-B cortou e guardou resto")


func test_the_replies_are_copies_and_reading_changes_neither_the_book_nor_the_hash() -> void:
	var rig: FlowRig = _rig()
	_enable(rig, [FlowRig.A_B])
	rig.until(DAY - 30)
	_gap(rig, rig.market_a, rig.market_b)
	rig.until(DAY - 1)
	var before: String = _snapshot(rig)
	var plan: FlowReplies.PlanQuery = rig.module.peek_flow_plan(FlowRig.A_B)
	assert_gt(plan.planned_quantity, 0, "há plano para a leitura gravar algo")
	plan.planned_quantity = 999
	var routes: FlowReplies.RoutesQuery = rig.module.peek_flow_routes()
	routes.rows[0].enabled = false
	routes.rows[0].risk_carry_bp = 7
	routes.rows.clear()
	assert_eq(_snapshot(rig), before, "consultar e mexer na resposta não muda o livro nem o hash")
	assert_eq([rig.module.peek_flow_routes().rows[0].enabled, rig.module.peek_flow_plan(FlowRig.A_B).planned_quantity == 999], [true, false])
	rig.until(DAY + 10)
	before = _snapshot(rig)
	var lots: FlowReplies.LotsQuery = rig.module.peek_flow_lots()
	lots.rows[0].quantity = 999
	lots.rows[0].good_id = "x"
	lots.rows.clear()
	assert_eq(_snapshot(rig), before, "o mesmo para os lotes")
	assert_eq([rig.module.peek_flow_lots().rows.size(), rig.module.peek_flow_lots().rows[0].good_id], [1, "bread"])


func test_peek_flow_lots_has_every_field_by_lot_id_with_the_minutes_left_and_filters_by_route() -> void:
	var rig: FlowRig = _rig()
	_enable(rig, [FlowRig.A_B, FlowRig.A_C, FlowRig.B_C])
	rig.until(DAY - 30)
	_gap(rig, rig.market_a, rig.market_b)
	assert_true(rig.module.request_set_stock(rig.market_c, "bread", 0).ok)
	rig.until(DAY + 20)
	var saved: Array = _lots(rig.module)
	var rows: Array[FlowReplies.LotQuery] = rig.module.peek_flow_lots().rows
	assert_gte(rows.size(), 2, "ao menos duas rotas enviaram")
	assert_eq(rows.size(), saved.size())
	for index: int in rows.size():
		var row: FlowReplies.LotQuery = rows[index]
		var lot: Dictionary = saved[index]
		var copy: Array = [row.lot_id, row.route_id, row.origin_market_id, row.destination_market_id, row.good_id, row.quantity, row.state, row.departed_at, row.arrives_at, row.remaining_minutes]
		assert_eq(copy, [lot["lot_id"], lot["route_id"], lot["origin_market_id"], lot["destination_market_id"], lot["good_id"], lot["quantity"], lot["state"], lot["departed_at"], lot["arrives_at"], lot["remaining_minutes"]], "a linha %d é a cópia do lote, por lot_id" % index)
		assert_eq(row.minutes_left, row.arrives_at - (DAY + 20), "faltam os minutos até a chegada")
	var only: Array[FlowReplies.LotQuery] = rig.module.peek_flow_lots(rows[0].route_id).rows
	assert_between(only.size(), 1, rows.size() - 1, "o filtro só traz a rota pedida")
	for row: FlowReplies.LotQuery in only:
		assert_eq(row.route_id, rows[0].route_id)
	assert_eq(rig.module.peek_flow_lots("route_zzz").rows.size(), 0, "rota sem lote: lista vazia, sem erro")


func test_minutes_left_counts_down_to_zero_and_a_held_lot_shows_its_remaining_minutes() -> void:
	var rig: FlowRig = _rig()
	_enable(rig, [FlowRig.B_C])
	rig.until(DAY - 30)
	_gap(rig, rig.market_b, rig.market_c)
	rig.until(DAY + 36)
	assert_eq(rig.module.peek_flow_lots().rows[0].minutes_left, 60, "B-C: chega em DAY + 96")
	rig.until(DAY + 100)
	assert_eq(rig.module.peek_flow_lots().rows[0].minutes_left, 0, "venceu e espera a hora cheia, sem número negativo")
	var block: Dictionary = rig.module.serialize()
	var lot: Dictionary = block["trade_flow"]["lots"][0]
	lot["state"] = "held"
	lot["arrives_at"] = 0
	lot["remaining_minutes"] = 77
	assert_true(rig.module.on_load(block).ok, "um lote parado (a rota fechada é da 100d2)")
	var held: FlowReplies.LotQuery = rig.module.peek_flow_lots().rows[0]
	assert_eq([held.state, held.arrives_at, held.remaining_minutes, held.minutes_left], ["held", 0, 77, 77])
	rig.until(DAY + 300)
	assert_eq(rig.module.peek_flow_lots().rows[0].minutes_left, 77, "o relógio não mexe no que está parado")


func test_peek_flow_plan_works_with_the_key_never_turned_on_and_reads_the_same_when_turned_on_and_off() -> void:
	var rig: FlowRig = _rig(null, 1, true)
	rig.until(DAY - 30)
	_gap(rig, rig.market_a, rig.market_b)
	var plan: FlowReplies.PlanQuery = rig.module.peek_flow_plan(FlowRig.A_B)
	var fields: Callable = func(reply: FlowReplies.PlanQuery) -> Array: return [reply.result.ok, reply.origin_market_id, reply.destination_market_id, reply.good_id, reply.planned_quantity, reply.sent_quantity, reply.minutes, reply.net_profit]
	assert_eq(fields.call(plan).slice(0, 4), [true, rig.market_a, rig.market_b, "bread"], "o sentido e o bem")
	assert_eq([plan.minutes, plan.planned_quantity > 0, plan.sent_quantity > 0, plan.sent_quantity <= plan.planned_quantity, plan.net_profit > 0], [143, true, true, true, true])
	assert_eq([rig.module.peek_flow_routes().rows.size(), rig.module.serialize().has("trade_flow")], [0, false], "a consulta não liga nada")
	_enable(rig, [FlowRig.A_B])
	assert_eq(fields.call(rig.module.peek_flow_plan(FlowRig.A_B)), fields.call(plan), "ligada: o mesmo plano")
	assert_true(rig.module.request_set_flow_enabled(FlowRig.A_B, false).ok)
	assert_eq(fields.call(rig.module.peek_flow_plan(FlowRig.A_B)), fields.call(plan), "desligada de novo: o mesmo plano")


func test_peek_flow_plan_refuses_with_no_route_where_the_command_does_and_changes_nothing() -> void:
	var cases: Array = [
		["rota que o world não conhece", Callable(), "route_zzz"],
		["sem flow_params", func(d: EconomyDefinitions) -> void: d.flow_params = null, FlowRig.A_B],
		["sem caravan_params", func(d: EconomyDefinitions) -> void: d.caravan_params = null, FlowRig.A_B],
	]
	for spec: Array in cases:
		var rig: FlowRig = FlowRig.build(_service)
		_rigs.append(rig)
		if (spec[1] as Callable).is_valid():
			(spec[1] as Callable).call(rig.definitions)
		rig.start_new_game()
		var before: String = _snapshot(rig)
		var plan: FlowReplies.PlanQuery = rig.module.peek_flow_plan(spec[2])
		assert_eq([plan.result.ok, plan.result.code, plan.planned_quantity], [false, EconomyCodes.NO_ROUTE, 0], str(spec[0]))
		assert_eq(_snapshot(rig), before, "nada muda: %s" % spec[0])
