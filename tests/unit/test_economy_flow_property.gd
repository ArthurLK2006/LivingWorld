extends FlowTestBase
## LW-100d2, T14 (docs/modules/economy.md, 9.16.8): PROPRIEDADE do fluxo com rotas FECHADAS e REABERTAS ao acaso, e a ORDEM do tick (9.16.2). Economia e `world` REAIS, só o fluxo (sem produção) com as três chaves ligadas, no `SimulationRunner` por 5 viradas de dia. O sorteio é do teste (uma `WorldRng` de semente fixa, fora do mundo): a cada 10 minutos os estoques de um bem podem ser remontados (sobra num mercado, falta noutro) e uma rota pode fechar ou reabrir. O ORÁCULO é do teste e não lê o código do fluxo: quem está fechada vem de um dicionário que o teste mesmo atualiza, o lote enviado tem de sair de rota aberta, o lote segurado não pode mudar em passo nenhum e o dono-trânsito tem de ser a soma dos lotes.
## As conservações e o `validate` fecham A CADA passo; mesma semente, mesmo hash.

const SEED: int = 1402
const END: int = 7600
const DECISION_EVERY: int = 10
const ROUTES: Array[String] = [FlowRig.A_B, FlowRig.A_C, FlowRig.B_C]
const GOODS: Array[String] = ["bread", "grain"]
## Os pães do forno do B na ordem do tick: o teto de compra do B é 80 (alvo 40 e `buy_cap_bp` 20000), então 70 deixam 10 de espaço.
const OVEN_BREAD: int = 70


## Os lotes do livro por `lot_id`, cada um como a lista `[estado, quantidade, chegada, minutos parados]`.
func _by_id(rig: FlowRig) -> Dictionary:
	var rows: Dictionary = {}
	for row: FlowReplies.LotQuery in rig.module.peek_flow_lots().rows:
		rows[row.lot_id] = [row.state, row.quantity, row.arrives_at, row.remaining_minutes]
	return rows


## O dono-trânsito tem, por bem, a soma dos lotes (a conta do teste, sem o `validate`).
func _holder_has_the_lots(rig: FlowRig, holder_id: int) -> bool:
	var wanted: Dictionary = {}
	for row: FlowReplies.LotQuery in rig.module.peek_flow_lots().rows:
		wanted[row.good_id] = int(wanted.get(row.good_id, 0)) + row.quantity
	var held: Dictionary = {}
	for row: Dictionary in rig.module.peek_inventory(holder_id).rows:
		held[row["good_id"]] = row["quantity"]
	return JSON.stringify(held, "", true) == JSON.stringify(wanted, "", true)


func _held_count(rig: FlowRig) -> int:
	return rig.module.peek_flow_lots().rows.filter(func(row: FlowReplies.LotQuery) -> bool: return row.state == FlowBook.Lot.STATE_HELD).size()


## Um ponto de decisão: o `validate` fecha, às vezes os estoques de um bem são remontados e, uma vez em duas, uma rota fecha ou reabre (o teste guarda quem está fechada e conta os lotes que pararam e os que voltaram).
func _decide(rng: WorldRng, rig: FlowRig, closed: Dictionary, found: Dictionary) -> void:
	found["problems"].append_array(rig.module.validate())
	if rng.range_int("restock", 0, 5) == 0:
		var origin: int = rng.range_int("origin", 0, 2)
		var markets: Array[int] = [rig.market_a, rig.market_b, rig.market_c]
		var good_id: String = GOODS[rng.range_int("good", 0, GOODS.size() - 1)]
		var surplus: Result = rig.module.request_set_stock(markets[origin], good_id, rng.range_int("surplus", 100, 300))
		var lack: Result = rig.module.request_set_stock(markets[(origin + rng.range_int("shift", 1, 2)) % 3], good_id, rng.range_int("lack", 0, 15))
		assert_true(surplus.ok and lack.ok, "%s %s" % [surplus.message, lack.message])
	if rng.range_int("toggle", 0, 1) == 0:
		var route_id: String = ROUTES[rng.range_int("route", 0, ROUTES.size() - 1)]
		var was_closed: bool = closed.get(route_id, false)
		var held_before: int = _held_count(rig)
		rig.set_route(route_id, was_closed)
		closed[route_id] = not was_closed
		found["resumed" if was_closed else "held"] += absi(_held_count(rig) - held_before)


## A vida de `END - 1000` passos de 1 minuto; devolve os minutos em que uma conferência falhou, as contagens que mostram que a propriedade não é vazia e o hash final.
func _simulate(random_seed: int) -> Dictionary:
	var rng: WorldRng = WorldRng.new(random_seed)
	var rig: FlowRig = _rig(null, 1, true)
	_enable(rig, ROUTES)
	var holder_id: int = int(_flow(rig.module)["holder_id"])
	var found: Dictionary = {"broken": [], "problems": [], "unbalanced": [], "sent_closed": [], "held_moved": [], "bad_held": [], "sent": 0, "held": 0, "resumed": 0, "delivered": 0, "closed_at_dispatch": 0}
	var closed: Dictionary = {}
	var seen: Dictionary = {}
	var before: Dictionary = _by_id(rig)
	for minute: int in range(FlowRig.START_MINUTE, END):
		if minute % DECISION_EVERY == 0:
			_decide(rng, rig, closed, found)
			before = _by_id(rig)
		if (minute + 1) % DAY == 0:
			found["closed_at_dispatch"] += closed.values().count(true)
		rig.runner.step_once()
		var now: int = rig.runner.world.context.clock.total_minutes()
		var after: Dictionary = _by_id(rig)
		for lot_id: int in before:
			if before[lot_id][0] == FlowBook.Lot.STATE_HELD and after.get(lot_id) != before[lot_id]:
				found["held_moved"].append(now)
			if not after.has(lot_id) or after[lot_id][1] < before[lot_id][1]:
				found["delivered"] += 1
		for row: FlowReplies.LotQuery in rig.module.peek_flow_lots().rows:
			if not seen.has(row.lot_id):
				found["sent"] += 1
				seen[row.lot_id] = true
				if closed.get(row.route_id, false):
					found["sent_closed"].append(now)
			if row.state == FlowBook.Lot.STATE_HELD and (row.arrives_at != 0 or row.remaining_minutes < 1):
				found["bad_held"].append(now)
		if not _holder_has_the_lots(rig, holder_id):
			found["unbalanced"].append(now)
		if not (rig.module.peek_conservation().ok and rig.module.peek_goods_conservation().ok):
			found["broken"].append(now)
		before = after
	found["hash"] = rig.runner.world.state_hash()
	return found


func test_random_closures_keep_the_flow_consistent_and_deterministic() -> void:
	var first: Dictionary = _simulate(SEED)
	assert_eq([first["broken"], first["problems"], first["unbalanced"], first["sent_closed"], first["held_moved"], first["bad_held"]], [[], [], [], [], [], []], "Bens e dinheiro conservados, `validate` vazio, dono-trânsito = soma dos lotes, nenhum envio em rota fechada, lote segurado intacto e todo `held` com chegada 0 e minutos a andar.")
	for key: String in ["sent", "held", "resumed", "delivered", "closed_at_dispatch"]:
		assert_gt(first[key], 0, "A propriedade não é vazia: '%s' aconteceu." % key)
	var second: Dictionary = _simulate(SEED)
	assert_eq([second["hash"], second["sent"], second["held"], second["delivered"]], [first["hash"], first["sent"], first["held"], first["delivered"]], "Mesma semente, mesmo hash e mesmas contagens.")
	assert_ne(_simulate(SEED + 1)["hash"], first["hash"], "Outra semente, outra história.")


## A ordem do tick (9.16.2): o fluxo roda DEPOIS do `close_day` e ANTES da produção da mesma hora. O forno do B guarda 70 pães que a produção das 1440 vende ao B, o mercado de DESTINO (vazio: o espaço dele é 80): o lote certo é o do estoque de ANTES da produção; depois dela sobrariam 10 de espaço. O ORÁCULO não lê a ordem do tick: o jogo `ref` (mesmo cenário, SEM os pães no forno e a chave nunca ligada) dá, lido na hora 1440, o plano de antes da produção; o jogo `off` (com o forno e a chave nunca ligada: o fluxo não faz nada) dá o plano que sairia DEPOIS da produção, o do mutante.
func test_the_flow_runs_before_the_production_of_the_same_hour() -> void:
	var on: FlowRig = _rig()
	var off: FlowRig = _rig()
	var ref: FlowRig = _rig()
	_enable(on, [FlowRig.A_B])
	for rig: FlowRig in [on, off, ref]:
		rig.until(DAY - 1)
		_gap(rig, rig.market_a, rig.market_b)
	for rig: FlowRig in [on, off]:
		assert_true(rig.module.request_set_stock(rig.market_b, "bread", OVEN_BREAD).ok)
		assert_true(rig.module.request_transfer_goods(rig.market_b, rig.module.peek_site_at("b_work_04").workplace_id, "bread", OVEN_BREAD).ok, "o forno do B guarda o pão que a hora 1440 vende")
	for rig: FlowRig in [on, off, ref]:
		rig.until(DAY)
	var wanted: FlowReplies.PlanQuery = ref.module.peek_flow_plan(FlowRig.A_B)
	var mutant: FlowReplies.PlanQuery = off.module.peek_flow_plan(FlowRig.A_B)
	assert_gt(wanted.sent_quantity, mutant.sent_quantity, "o cenário distingue as ordens: depois da produção o plano seria menor")
	assert_eq(_stock(on, on.market_b, "bread"), OVEN_BREAD, "a produção da hora 1440 vendeu o forno ao B (rodou, e depois do envio)")
	var sent: Array = on.module.peek_flow_lots().rows.map(func(lot: FlowReplies.LotQuery) -> Array: return [lot.good_id, lot.origin_market_id, lot.destination_market_id, lot.quantity])
	assert_eq(sent, [[wanted.good_id, wanted.origin_market_id, wanted.destination_market_id, wanted.sent_quantity]], "um só lote no dia, o do plano de antes da produção")
	_assert_consistent(on)
