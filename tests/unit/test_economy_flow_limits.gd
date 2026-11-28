extends FlowTestBase
## LW-100d1b (docs/modules/economy.md, 9.16.8): os limites do fluxo, com a economia e as rotas REAIS. T8: desligar a chave barra o envio novo e o lote a caminho chega; desligar e religar mantém o resto de risco, que o plano de hoje usa. T10: risco 0 entrega tudo; risco máximo não envia nem perde; o resto de risco é gravado mesmo quando o corte leva o envio a 0. T11: origem na reserva ou vazia e destino sem espaço dão dia sem lote e sem erro; destino sem peso livre: o lote espera e a entrega é parcial, sem perda.


func test_the_maximum_risk_sends_nothing_and_loses_nothing() -> void:
	var rig: FlowRig = _rig(_risk(1000))
	_enable(rig, [FlowRig.A_B])
	rig.until(DAY - 30)
	_gap(rig, rig.market_a, rig.market_b)
	rig.until(DAY - 1)
	assert_gt(rig.module.peek_flow_plan(FlowRig.A_B).planned_quantity, 0, "a regra quer enviar")
	assert_eq(rig.module.peek_flow_plan(FlowRig.A_B).sent_quantity, 0, "mas o corte leva tudo")
	var before: Dictionary = _stocks(rig)
	rig.until(2 * DAY)
	assert_eq(_lots(rig.module).size(), 0, "risk_bp 10000: nada sai")
	assert_eq(_carry(rig.module), 0)
	assert_eq(_stocks(rig), before, "e nenhum bem se perde")
	_assert_consistent(rig)


func test_a_risk_of_zero_delivers_everything_that_left() -> void:
	var rig: FlowRig = _rig(_risk(0))
	_enable(rig, [FlowRig.A_B])
	rig.until(DAY - 30)
	_gap(rig, rig.market_a, rig.market_b)
	rig.until(DAY)
	var lot: FlowReplies.LotQuery = rig.module.peek_flow_lots().rows[0]
	var before: int = _stock(rig, lot.destination_market_id, lot.good_id)
	rig.until(DAY + 180)
	assert_eq(_stock(rig, lot.destination_market_id, lot.good_id) - before, lot.quantity, "chega tudo o que saiu")
	assert_eq([rig.module.peek_flow_lots().rows.size(), _carry(rig.module), rig.module.peek_inventory(int(_flow(rig.module)["holder_id"])).rows.size()], [0, 0, 0], "sem lote, sem resto e o dono-trânsito vazio")
	_assert_consistent(rig)


func test_the_remainder_is_kept_even_when_the_cut_leaves_nothing_to_send() -> void:
	var rig: FlowRig = _rig(_risk(999))
	_enable(rig, [FlowRig.A_B])
	var carries: Array[int] = []
	var sent: Array[int] = []
	for day: int in range(1, 3):
		rig.until(day * DAY - 30)
		_gap(rig, rig.market_a, rig.market_b)
		rig.until(day * DAY)
		carries.append(_carry(rig.module))
		sent.append(_lots(rig.module).reduce(func(total: int, lot: Dictionary) -> int: return total + int(lot["quantity"]), 0))
	assert_eq([sent, int(_flow(rig.module)["next_lot_id"])], [[1, 0], 2], "o dia 1 enviou uma unidade; no dia 2 o corte levou tudo e não saiu lote")
	assert_lt(carries[1], carries[0], "o resto do dia 2 foi gravado mesmo sem lote")
	assert_gt(carries[1], 0, "e é diferente de zero")


func test_turning_the_key_off_stops_new_sends_but_the_lot_on_the_road_arrives() -> void:
	var rig: FlowRig = _rig()
	_enable(rig, [FlowRig.A_B])
	rig.until(DAY - 30)
	_gap(rig, rig.market_a, rig.market_b)
	rig.until(DAY)
	assert_eq(_lots(rig.module).size(), 1)
	assert_true(rig.module.request_set_flow_enabled(FlowRig.A_B, false).ok)
	rig.until(DAY + 180)
	assert_eq(_lots(rig.module).size(), 0, "o lote chegou")
	rig.until(2 * DAY - 30)
	_gap(rig, rig.market_a, rig.market_b)
	rig.until(2 * DAY)
	assert_gt(rig.module.peek_flow_plan(FlowRig.A_B).planned_quantity, 0, "a regra ainda enviaria hoje: quem barra é a chave")
	rig.until(2 * DAY + 180)
	assert_eq(int(_flow(rig.module)["next_lot_id"]), 2, "nenhum lote novo com a chave desligada")
	_assert_consistent(rig)


func test_turning_the_key_off_and_on_keeps_the_remainder_and_the_plan_of_today_uses_it() -> void:
	var rig: FlowRig = _rig()
	_enable(rig, [FlowRig.A_B])
	for day: int in range(1, 3):
		rig.until(day * DAY - 30)
		_gap(rig, rig.market_a, rig.market_b)
		rig.until(day * DAY)
	var carry: int = _carry(rig.module)
	assert_gt(carry, 0, "os cortes dos dois primeiros dias deixaram resto")
	assert_true(rig.module.request_set_flow_enabled(FlowRig.A_B, false).ok)
	rig.until(3 * DAY - 30)
	assert_eq(_carry(rig.module), carry, "desligar mantém o resto")
	assert_true(rig.module.request_set_flow_enabled(FlowRig.A_B, true).ok)
	assert_eq(_carry(rig.module), carry, "religar mantém o resto")
	_gap(rig, rig.market_a, rig.market_b)
	var plan: FlowReplies.PlanQuery = rig.module.peek_flow_plan(FlowRig.A_B)
	assert_gt(plan.planned_quantity, 0)
	assert_lt(plan.planned_quantity * 250, PriceMath.BASIS, "sem o resto o corte de hoje seria zero")
	assert_gte(carry + plan.planned_quantity * 250, PriceMath.BASIS, "com o resto o corte de hoje já passa de uma unidade")
	assert_eq(plan.sent_quantity, plan.planned_quantity - IntMath.floor_div(carry + plan.planned_quantity * 250, PriceMath.BASIS), "o plano de hoje corta com o resto guardado")
	assert_lt(plan.sent_quantity, plan.planned_quantity, "e por isso envia menos do que planejou")


func test_an_empty_origin_the_reserve_and_a_destination_without_space_make_no_lot_and_no_error() -> void:
	for mode: String in ["reserve", "full", "empty"]:
		var rig: FlowRig = _rig()
		_enable(rig, [FlowRig.A_B])
		for target: MarketTargetDef in rig.definitions.market_targets:
			if ["test_settlement_a", "test_settlement_b"].has(target.settlement_id):
				var stock: int = {"reserve": PriceMath.ceil_div(target.target_stock * rig.definitions.caravan_params.origin_reserve_bp, PriceMath.BASIS), "full": target.buy_cap(), "empty": 0}[mode]
				assert_true(rig.module.request_set_stock(rig.module.peek_market_of(target.settlement_id).market_id, target.good_id, stock).ok)
		rig.until(DAY - 1)
		var plan: FlowReplies.PlanQuery = rig.module.peek_flow_plan(FlowRig.A_B)
		assert_eq([plan.result.ok, plan.planned_quantity], [true, 0], "a regra não planeja nada (%s)" % mode)
		rig.until(2 * DAY)
		assert_eq(int(_flow(rig.module)["next_lot_id"]), 1, "nenhum lote (%s)" % mode)
		_assert_consistent(rig)


func test_a_delivery_that_does_not_fit_in_the_destination_weight_stays_in_the_lot_until_there_is_room() -> void:
	var rig: FlowRig = _rig(null, -1, true)
	_enable(rig, [FlowRig.A_B])
	rig.until(DAY - 30)
	_gap(rig, rig.market_a, rig.market_b)
	rig.until(DAY)
	var lot: Dictionary = _lots(rig.module)[0]
	assert_gt(int(lot["quantity"]), 7, "o lote é maior do que o peso que vai sobrar")
	var destination: int = lot["destination_market_id"]
	var inventory: EconomyReplies.InventoryQuery = rig.module.peek_inventory(destination)
	var wool: int = _stock(rig, destination, "wool")
	var free: int = inventory.capacity - inventory.weight
	assert_true(rig.module.request_set_stock(destination, "wool", wool + free).ok, "o destino fica sem peso livre (cada lã pesa 1)")
	rig.until(DAY + 180)
	assert_eq(_lots(rig.module).size(), 1, "sem peso livre o lote espera")
	assert_eq(int(_lots(rig.module)[0]["quantity"]), int(lot["quantity"]), "inteiro e sem perda")
	_assert_consistent(rig)
	assert_true(rig.module.request_set_stock(destination, "wool", wool + free - 7).ok, "sobra peso para 7")
	rig.until(DAY + 240)
	var rest: Array = _lots(rig.module)
	assert_eq(rest.size(), 1, "o que não coube fica no lote")
	assert_eq(int(rest[0]["quantity"]), int(lot["quantity"]) - 7, "entrega parcial: só o que coube")
	_assert_consistent(rig)
	assert_true(rig.module.request_set_stock(destination, "wool", wool).ok)
	rig.until(DAY + 300)
	assert_eq(_lots(rig.module).size(), 0, "tenta de novo na hora seguinte e o lote some")
	_assert_consistent(rig)
