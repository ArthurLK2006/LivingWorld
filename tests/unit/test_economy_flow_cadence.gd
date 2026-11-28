extends FlowTestBase
## LW-100d1b, T5 (docs/modules/economy.md, 9.16.2 e 9.16.8): o resultado do fluxo NÃO depende da cadência da economia. O mesmo cenário (3 rotas ligadas, 3 viradas de dia com o pão em sobra no A e em falta no B e no C) em passos de 1, 60 e 180 minutos, mais 7 (um passo desalinhado: o fluxo que lê o relógio do FIM do passo no lugar de `hora x 60` sai com `departed_at` 1442 em vez de 1440; o de 180 também o pega, porque as 3 horas do passo usariam o mesmo relógio: 18 lotes contra 7) dá o mesmo `serialize`, o mesmo `state_hash` e os mesmos IDs. O ORÁCULO prova a ordem do tick: o lote enviado na virada é o do plano lido logo depois do `close_day` (o `peek_flow_plan` funciona com a chave nunca ligada), não o que sairia com os preços de antes dele.

const CADENCES: Array[int] = [1, 7, 60, 180]
## Os minutos 1260, 2520 e 3780 (3 h antes de cada virada) e o 5040 são passos de TODAS as cadências: os comandos entram no mesmo ponto da economia em todas.
const GAP_STEP: int = 1260
const FINAL: int = 5040


## O cenário numa cadência: [save em texto, hash do estado, próximo ID, próximo lot_id]. Logo depois da primeira virada os lotes têm de ter saído com o relógio da HORA (`departed_at` = DAY), qualquer que seja o passo.
func _run(cadence: int) -> Array:
	var rig: FlowRig = _rig(null, cadence)
	_enable(rig, [FlowRig.A_B, FlowRig.A_C, FlowRig.B_C])
	for step: int in 3:
		rig.until(GAP_STEP * (step + 1))
		_gap(rig, rig.market_a, rig.market_b)
		assert_true(rig.module.request_set_stock(rig.market_c, "bread", 0).ok)
		if step == 0:
			rig.until(DAY + 7)
			assert_gt(rig.module.peek_flow_lots().rows.size(), 0, "a primeira virada enviou (passo de %d)" % cadence)
			for row: FlowReplies.LotQuery in rig.module.peek_flow_lots().rows:
				assert_eq(row.departed_at, DAY, "saiu com o relógio da hora, não do fim do passo (passo de %d)" % cadence)
	rig.until(FINAL)
	_assert_consistent(rig)
	return [JSON.stringify(rig.module.serialize()), rig.runner.world.state_hash(), int(rig.runner.world.context.ids.serialize()["next_id"]), int(_flow(rig.module)["next_lot_id"])]


func test_the_result_does_not_depend_on_the_step_size() -> void:
	var first: Array = _run(CADENCES[0])
	assert_gt(int(first[3]), 4, "o cenário envia de verdade")
	for cadence: int in CADENCES.slice(1):
		var other: Array = _run(cadence)
		assert_true(other[0] == first[0], "o save é o mesmo no passo de %d" % cadence)
		assert_eq(other.slice(1), first.slice(1), "o hash, o ID e o contador de lotes são os mesmos no passo de %d" % cadence)


func test_the_lot_of_the_day_is_the_plan_read_right_after_the_close_day() -> void:
	var off: FlowRig = _rig(null, 1, true)
	var on: FlowRig = _rig(null, 1, true)
	_enable(on, [FlowRig.A_B])
	for rig: FlowRig in [off, on]:
		rig.until(GAP_STEP)
		_gap(rig, rig.market_a, rig.market_b)
		rig.until(DAY - 1)
	var stale: FlowReplies.PlanQuery = off.module.peek_flow_plan(FlowRig.A_B)
	off.until(DAY)
	on.until(DAY)
	var plan: FlowReplies.PlanQuery = off.module.peek_flow_plan(FlowRig.A_B)
	var lots: Array[FlowReplies.LotQuery] = on.module.peek_flow_lots().rows
	assert_ne(stale.planned_quantity, plan.planned_quantity, "o cenário pesa: o fechamento do dia muda o plano")
	assert_eq(lots.size(), 1)
	assert_eq([lots[0].good_id, lots[0].quantity, lots[0].origin_market_id, lots[0].destination_market_id, lots[0].arrives_at - lots[0].departed_at], [plan.good_id, plan.sent_quantity, plan.origin_market_id, plan.destination_market_id, plan.minutes], "o lote é o do plano lido DEPOIS do close_day")
	assert_false(off.module.serialize().has("trade_flow"), "no outro jogo a chave nunca foi ligada")
