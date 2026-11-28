extends FlowTestBase
## LW-100d2, T2 e T9 (docs/modules/economy.md, 9.16.4 e 9.16.8): a rota FECHADA interrompe o fluxo e a reaberta o retoma. Economia e `world` REAIS (A-B 143 min), SÓ o fluxo (sem produção) com a chave da A-B ligada e o pão em sobra no A e em falta no B: o envio do dia sai no minuto 1440 e chega no 1583, e a hora cheia de entrega é a 27 (minuto 1620). Fechar e reabrir saem do `world` e o evento é entregue NA HORA (`FlowRig.set_route`); o evento REPETIDO (que o `world` não publica) vem direto do `EventBus`.
## O oráculo é o contrato, em minutos feitos à mão: fechado no 1500 faltam 83; reaberto no 1700 chega no 1783 e entra na hora 30 (1800); a hora 27 passou com a rota fechada e nada entrou.

const ARRIVAL: int = DAY + 143
const GAP_AT: int = 1260


## O jogo só com o fluxo, a chave da A-B ligada e o pão em sobra no A e em falta no B (desde o minuto 1260), parado no minuto `minute`.
func _lot_rig(minute: int) -> FlowRig:
	var rig: FlowRig = _rig(null, 1, true)
	_enable(rig, [FlowRig.A_B])
	rig.until(GAP_AT)
	_gap(rig, rig.market_a, rig.market_b)
	rig.until(minute)
	return rig


## O estado, a chegada e os minutos parados do primeiro lote, como estão no save.
func _shape(rig: FlowRig) -> Array:
	var lot: Dictionary = _lots(rig.module)[0]
	return [lot["state"], lot["arrives_at"], lot["remaining_minutes"]]


## Entrega um `RouteStateChanged` direto (o `world` só publica na mudança real): o evento repetido ou de um estado que não existe.
func _announce(rig: FlowRig, route_id: String, new_state: String) -> void:
	rig.runner.world.context.events.publish(RouteStateChanged.new(route_id, new_state))
	rig.runner.world.context.events.dispatch()


func test_closing_holds_the_lot_and_reopening_resumes_it_with_the_arrival_shifted() -> void:
	var rig: FlowRig = _lot_rig(DAY)
	assert_eq(_shape(rig), ["travelling", ARRIVAL, 0], "o envio do dia: 143 minutos de caminho")
	var sent: int = int(_lots(rig.module)[0]["quantity"])
	var stock_b: int = _stock(rig, rig.market_b, "bread")
	rig.until(1500)
	rig.set_route(FlowRig.A_B, false)
	assert_eq(_shape(rig), ["held", 0, ARRIVAL - 1500], "fechou: segurado com os 83 minutos que faltavam e chegada 0")
	assert_eq(rig.module.peek_flow_lots().rows[0].minutes_left, ARRIVAL - 1500, "peek_flow_lots mostra o que falta")
	_assert_consistent(rig)
	rig.until(1700)
	assert_eq([_lots(rig.module).size(), _stock(rig, rig.market_b, "bread")], [1, stock_b], "a hora 27 (1620) passou com a rota fechada: nada entrou")
	rig.set_route(FlowRig.A_B, true)
	assert_eq(_shape(rig), ["travelling", 1700 + ARRIVAL - 1500, 0], "reabriu: a chegada anda para agora mais os 83 minutos")
	rig.until(1741)
	assert_eq(_stock(rig, rig.market_b, "bread"), stock_b, "a hora 29 (1740) ainda é cedo: com a chegada de antes o lote já teria entrado")
	rig.until(1800)
	assert_eq([_lots(rig.module).size(), _stock(rig, rig.market_b, "bread")], [0, stock_b + sent], "a hora 30 entrega tudo")
	_assert_consistent(rig)


func test_a_closed_route_sends_nothing_and_reopening_sends_only_on_the_next_day() -> void:
	var rig: FlowRig = _lot_rig(1400)
	assert_gt(rig.module.peek_flow_plan(FlowRig.A_B).planned_quantity, 0, "o cenário pesa: com a rota aberta o plano envia")
	rig.set_route(FlowRig.A_B, false)
	assert_eq(rig.module.peek_flow_plan(FlowRig.A_B).planned_quantity, 0, "fechada, o plano não envia")
	rig.until(DAY + 90)
	assert_eq(_lots(rig.module).size(), 0, "fechada antes da hora do envio (1440), com a chave ligada: nada sai")
	rig.until(1500)
	rig.set_route(FlowRig.A_B, true)
	rig.until(2 * DAY - 1)
	assert_eq(_lots(rig.module).size(), 0, "reaberta no mesmo dia: o envio só vem no início do próximo")
	rig.until(2 * DAY)
	assert_eq(_lots(rig.module).size(), 1, "no início do dia seguinte sai o lote")
	assert_eq(int(_lots(rig.module)[0]["departed_at"]), 2 * DAY)
	_assert_consistent(rig)


func test_a_lot_already_due_is_not_frozen_and_arrives_with_the_route_closed() -> void:
	for closing: int in [ARRIVAL, 1600, 1620]:
		var rig: FlowRig = _lot_rig(DAY)
		var sent: int = int(_lots(rig.module)[0]["quantity"])
		rig.until(closing)
		rig.set_route(FlowRig.A_B, false)
		if closing < 1620:
			assert_eq(_shape(rig), ["travelling", ARRIVAL, 0], "fechou em %d, com a chegada (1583) já passada ou nela: não congela" % closing)
		rig.until(1620)
		assert_eq([_lots(rig.module).size(), _stock(rig, rig.market_b, "bread")], [0, sent], "fechado em %d, o lote entra na hora 27, com a rota fechada (em 1620 a entrega veio antes do evento)" % closing)
		_assert_consistent(rig)


func test_closing_twice_and_reopening_twice_change_nothing_the_second_time() -> void:
	var rig: FlowRig = _lot_rig(1500)
	rig.set_route(FlowRig.A_B, false)
	var held: Array = _lots(rig.module)
	rig.until(1520)
	_announce(rig, FlowRig.A_B, WorldModule.STATE_CLOSED)
	assert_eq(_lots(rig.module), held, "fechar de novo: o lote segue segurado, com os mesmos 83 minutos")
	rig.until(1700)
	rig.set_route(FlowRig.A_B, true)
	var resumed: Array = _lots(rig.module)
	rig.until(1710)
	_announce(rig, FlowRig.A_B, WorldModule.STATE_OPEN)
	assert_eq(_lots(rig.module), resumed, "reabrir de novo: a chegada não anda outra vez")


func test_another_route_or_an_unknown_state_does_not_touch_the_lot() -> void:
	var rig: FlowRig = _lot_rig(1500)
	var before: Array = _lots(rig.module)
	rig.set_route(FlowRig.A_C, false)
	_announce(rig, FlowRig.A_B, "paused")
	assert_eq(_lots(rig.module), before, "fechar a A-C ou um estado que não é open nem closed não mexe no lote da A-B")


func test_a_caravan_and_a_flow_lot_on_the_same_route_are_held_and_resumed_by_the_same_event() -> void:
	var rig: FlowRig = _lot_rig(DAY)
	assert_true(rig.module.request_open_owner(9000, EconomyModule.KIND_MERCHANT).ok)
	assert_true(rig.module.request_start_caravan(9000, rig.market_a, rig.market_b, "bread", 10).result.ok)
	rig.until(1500)
	rig.set_route(FlowRig.A_B, false)
	assert_eq([rig.module.peek_caravan(9000).state, _lots(rig.module)[0]["state"]], ["held", "held"], "as caravanas e o fluxo param no mesmo evento")
	rig.until(1700)
	rig.set_route(FlowRig.A_B, true)
	assert_eq([rig.module.peek_caravan(9000).state, _lots(rig.module)[0]["state"]], ["travelling", "travelling"], "e retomam no mesmo evento")
	_assert_consistent(rig)


func test_the_book_holds_and_resumes_only_what_fits() -> void:
	var book: FlowBook = FlowBook.new()
	var lot: FlowBook.Lot = FlowBook.Lot.new()
	lot.quantity = 5
	lot.arrives_at = 100
	var lot_id: int = book.add_lot(lot)
	assert_eq([book.hold_lot(lot_id + 1, 5), book.hold_lot(lot_id, -1), book.resume_lot(lot_id, 50)], [false, false, false], "lote que não existe, minutos negativos e retomar o que anda: nada muda")
	assert_true(book.hold_lot(lot_id, 0), "limite: 0 minutos a andar ainda segura")
	assert_eq([book.lot_of(lot_id).state, book.lot_of(lot_id).arrives_at, book.lot_of(lot_id).range_problem()], ["held", 0, ""])
	assert_eq([book.hold_lot(lot_id, 7), book.resume_lot(lot_id + 1, 5), book.resume_lot(lot_id, 0)], [false, false, false], "segurar o segurado, lote que não existe e chegada 0: nada muda")
	assert_true(book.resume_lot(lot_id, 1), "limite: chegada 1 retoma")
	assert_eq([book.lot_of(lot_id).state, book.lot_of(lot_id).arrives_at, book.lot_of(lot_id).remaining_minutes, book.lot_of(lot_id).range_problem()], ["travelling", 1, 0, ""])
