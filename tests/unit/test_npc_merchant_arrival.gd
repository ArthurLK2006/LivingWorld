extends GutTest
## LW-098g (docs/modules/economy.md 9.12 e 9.7; docs/modules/npc.md 14.11): a CHEGADA do comerciante no `npc`, sem nenhum comerciante no jogo real (população em memória, como a LW-098f2). O jogo é MONTADO como o real (`GameModules`, dados de `res://data`,
## rotas e economia reais, build de desenvolvimento) e SEM população: quem nasce é o comerciante que o teste cria. Cobre: `CaravanArrived` realoca o NPC no mercado do destino e o libera, e o lucro realizado alivia `income` (prejuízo não alivia; nunca abaixo
## de 0); o ciclo A, B, A em dois mercados; a `sell` da sobra (valor derivado do que o mercado ACEITA, só do que não é comida, só do comerciante; destino cheio ou sem fundos não dá valor, então nada se repete); o comerciante que come da carga em trânsito
## (`consumed`); o evento que não toca ninguém; a ação começada no passo da chegada; o corpo (S0) que sai antes da mudança de lugar. Dos números [HIP] só se fixam os de contrato; o resto sai da economia (cotações e plano são a fonte da verdade).

const DATA_DIR: String = "res://data"
const WORLD_DIR: String = "res://data/world"
const NPC_DIR: String = "res://src/sim/npc"
const SEED: int = 98
const ACTOR_ID: int = 77
const SETTLEMENT_A: String = "test_settlement_a"
const SETTLEMENT_B: String = "test_settlement_b"
const MARKET_A: String = "a_market_01"
const MARKET_B: String = "b_market_01"
const HOME_A: String = "a_home_01"
const MERCHANT: String = "merchant"
const HAUL: String = "haul"
const SELL: String = "sell"
const BUY: String = "buy"
const BREAD: String = "bread"
const GRAIN: String = "grain"
const WOOL: String = "wool"
const TOOL: String = "tool"
const HUNGER: int = 0
const INCOME: int = 3
## O caso do `npc` 151 (098h0): mochila cheia (capacidade do comerciante), 505 moedas e as 72 horas em que ele morria de fome.
const PACK: int = 120
const CASE_BALANCE: int = 505
const CASE_HOURS: int = 72
const MINUTES_PER_HOUR: int = 60
const MORNING: int = 7 * MINUTES_PER_HOUR
const EVENING: int = 17 * MINUTES_PER_HOUR

var _data: NpcLifeCheck.GameData
var _places: SettlementService
var _runners: Array[SimulationRunner] = []


class Rig:
	extends RefCounted

	var runner: SimulationRunner
	var economy: EconomyModule
	var npc: NpcModule
	var market_a: int
	var market_b: int
	var arrivals: Array[CaravanArrived] = []


func before_all() -> void:
	_data = NpcLifeCheck.load_game_data()
	assert_eq(_data.problem, "", "Os dados reais do jogo carregam.")
	_places = SettlementService.new(_data.settlements, _data.places)


func after_each() -> void:
	for runner: SimulationRunner in _runners:
		runner.finish()
	_runners.clear()


# ---------------------------------------------------------------------------------------------------- montagem

## O jogo como o real, sem população. `spread`: pão 120 no A e 15 no B (o cenário de lucro). `income_start`: `income` inicial, sem subir com o tempo (-1 = os dados). `tweak`: muda as definições da economia antes de montar. `starving`: a fome nasce crítica e letal em 2 h.
func _rig(start_minute: int, spread: bool = true, income_start: int = -1, tweak: Callable = Callable(), starving: bool = false) -> Rig:
	var setup: NpcSetup = NpcSetup.from_dir(DATA_DIR, _places, true)
	assert_true(setup.result.ok, setup.result.message)
	setup.definitions.population = null
	if income_start >= 0:
		setup.need_defs[INCOME].start_value = income_start
		setup.need_defs[INCOME].rate_per_hour = 0
	if starving:
		setup.need_defs[HUNGER].start_value = 95
		setup.need_defs[HUNGER].weaken_after_hours = 1
		setup.need_defs[HUNGER].lethal_after_hours = 2
	var economy_setup: EconomySetup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR, true)
	if tweak.is_valid():
		tweak.call(economy_setup.definitions)
	var rig: Rig = Rig.new()
	rig.runner = SimulationRunner.new(SEED, start_minute)
	_runners.append(rig.runner)
	var modules: GameModules = GameModules.register(rig.runner, _data.terrain, _data.points, setup, economy_setup, WorldSetup.from_dir(WORLD_DIR, _data.settlements, true))
	assert_true(modules.result.ok, modules.result.message)
	rig.runner.start_new_game()
	rig.runner.world.context.events.subscribe("CaravanArrived", func(event: SimEvent) -> void: rig.arrivals.append(event))
	rig.economy = modules.economy
	rig.npc = modules.npc
	rig.market_a = rig.economy.peek_market_of(SETTLEMENT_A).market_id
	rig.market_b = rig.economy.peek_market_of(SETTLEMENT_B).market_id
	if spread:
		_stock(rig, BREAD, 120, 15)
	return rig


func _stock(rig: Rig, good_id: String, in_a: int, in_b: int) -> void:
	assert_true(rig.economy.request_set_stock(rig.market_a, good_id, in_a).ok)
	assert_true(rig.economy.request_set_stock(rig.market_b, good_id, in_b).ok)


## Cria um NPC no local dado, com a casa no A. Devolve o ID.
func _spawn(rig: Rig, occupation_id: String, settlement_id: String, place_id: String, work_place_id: String = "") -> int:
	var spot: Vector3 = _places.peek_place(place_id).place.position
	var spec: NpcSpec = NpcSpec.new()
	spec.name_key = "npc.name.villager"
	spec.name_number = 1
	spec.occupation_id = occupation_id
	spec.settlement_id = settlement_id
	spec.place_id = place_id
	spec.home_place_id = HOME_A
	spec.work_place_id = work_place_id
	spec.x_cm = roundi(spot.x * TerrainData.CM_PER_METER)
	spec.z_cm = roundi(spot.z * TerrainData.CM_PER_METER)
	var created: NpcModule.CreateResult = rig.npc.request_create_npc(spec)
	assert_true(created.result.ok, created.result.message)
	return created.npc_id


func _run_until(rig: Rig, done: Callable, limit: int) -> bool:
	for _minute: int in limit:
		if done.call():
			return true
		rig.runner.step_once()
	return done.call()


func _now(rig: Rig) -> int:
	return rig.runner.world.context.clock.total_minutes()


func _departed(rig: Rig, merchant: int) -> bool:
	return rig.economy.peek_caravan(merchant).found


func _doing(rig: Rig, npc_id: int, action_id: String) -> bool:
	return rig.npc.peek_npc(npc_id).action_id == action_id


func _held(rig: Rig, owner_id: int, good_id: String) -> int:
	for row: Dictionary in rig.economy.peek_inventory(owner_id).rows:
		if row["good_id"] == good_id:
			return int(row["quantity"])
	return 0


func _conserved(rig: Rig) -> bool:
	return rig.economy.peek_conservation().ok and rig.economy.peek_goods_conservation().ok and rig.economy.validate().is_empty()


## O `CaravanArrived` que o teste publica (a economia não o publicou) e o passo que o entrega ao `npc`.
func _arrive(rig: Rig, trader_id: int, settlement_id: String, revenue: int, cost_paid: int) -> void:
	rig.runner.world.context.events.publish(CaravanArrived.new(trader_id, "route_a_b", settlement_id, revenue, cost_paid))
	rig.runner.step_once()


## O `NpcTrade` do mercado do povoado dado, com a tabela real de ofícios (a conta do ator vem da economia; o estado é só o povoado e o ofício).
func _trade(rig: Rig, npc_id: int, settlement_id: String, occupation_id: String) -> NpcTrade:
	var states: Dictionary[int, NpcState] = {}
	states[npc_id] = NpcState.new(npc_id)
	states[npc_id].settlement_id = settlement_id
	states[npc_id].occupation_id = occupation_id
	return NpcTrade.new(rig.economy, states, 2, 100, 100, RoutineLoader.load_dir().table)


## O comerciante parte do A ao B com `quantity` de `good_id` pela porta da economia (sem plano) e devolve o ETA.
func _depart(rig: Rig, merchant: int, good_id: String, quantity: int) -> int:
	var started: CaravanReplies.StartResult = rig.economy.request_start_caravan(merchant, rig.market_a, rig.market_b, good_id, quantity)
	assert_true(started.result.ok, started.result.message)
	return started.eta_minute


func _arrived_by(rig: Rig, minute: int) -> bool:
	return _run_until(rig, func() -> bool: return not rig.arrivals.is_empty(), minute - _now(rig) + 1)


# ---------------------------------------------------------------------------------------------------- chegada: realoca, libera e alivia income

func test_the_arrival_relocates_the_merchant_frees_it_and_the_realized_profit_relieves_income() -> void:
	var rig: Rig = _rig(EVENING, true, 100)
	var merchant: int = _spawn(rig, MERCHANT, SETTLEMENT_A, MARKET_A, MARKET_A)
	var eta: int = _depart(rig, merchant, BREAD, 2)
	assert_eq([rig.npc.peek_npc(merchant).place_id, rig.npc.peek_npc(merchant).need_values[INCOME]], [MARKET_A, 100], "Em viagem a posição lógica fica na origem e `income` não mexe.")
	assert_true(_arrived_by(rig, eta), "A caravana chega no ETA.")
	var arrived: CaravanArrived = rig.arrivals[0]
	var profit: int = arrived.revenue - arrived.cost_paid
	var spot: Vector3 = _places.peek_place(MARKET_B).place.position
	var now: NpcModule.NpcQuery = rig.npc.peek_npc(merchant)
	assert_between(profit, 1, 99, "A viagem deu lucro realizado (menor que a necessidade, para o alívio não ser limitado a 0).")
	assert_eq([now.settlement_id, now.place_id, now.x_cm, now.z_cm, now.action_id], [SETTLEMENT_B, MARKET_B, roundi(spot.x * TerrainData.CM_PER_METER), roundi(spot.z * TerrainData.CM_PER_METER), ""], "Realocado no mercado do destino.")
	assert_eq(now.need_values[INCOME], 100 - profit, "`income` alivia pelo lucro realizado: `revenue - cost_paid` vezes 1 ponto por moeda.")
	assert_eq(now.next_think_time, _now(rig), "Liberado: a caravana já foi apagada e ele pensa no passo seguinte.")
	rig.runner.step_once()
	assert_ne(rig.npc.peek_npc(merchant).action_id, "", "Pensou e começou uma ação no povoado novo.")
	assert_eq([rig.economy.peek_balance(merchant).balance, _conserved(rig)], [300 - arrived.cost_paid + arrived.revenue, true], "O `npc` não mexeu em dinheiro: o lucro é só a diferença de saldo da economia.")


func test_a_loss_relieves_nothing_and_a_big_profit_stops_at_zero() -> void:
	var rig: Rig = _rig(MORNING, false, 80)
	var merchant: int = _spawn(rig, MERCHANT, SETTLEMENT_A, MARKET_A, MARKET_A)
	var incomes: Array[int] = []
	for sale: Array in [[40, 100], [100, 100], [130, 100], [600, 100]]:
		_arrive(rig, merchant, SETTLEMENT_B, sale[0], sale[1])
		incomes.append(rig.npc.peek_npc(merchant).need_values[INCOME])
	assert_eq(incomes, [80, 80, 50, 0] as Array[int], "Prejuízo e zero a zero não aliviam; 30 de lucro tiram 30; lucro maior que a necessidade a leva a 0, nunca abaixo.")


func test_an_arrival_for_a_dead_or_unknown_trader_changes_nothing() -> void:
	var rig: Rig = _rig(EVENING, false, -1, Callable(), true)
	var merchant: int = _spawn(rig, MERCHANT, SETTLEMENT_A, MARKET_A, MARKET_A)
	var eta: int = _depart(rig, merchant, BREAD, 1)
	assert_true(_run_until(rig, func() -> bool: return not rig.npc.peek_npc(merchant).is_alive, eta - _now(rig) - 1), "Em viagem ele não age e a fome crítica o mata em 2 h, antes do ETA.")
	var before: Dictionary = rig.npc.serialize()
	_arrive(rig, merchant, SETTLEMENT_B, 500, 100)
	_arrive(rig, 987654, SETTLEMENT_B, 500, 100)
	assert_eq(rig.npc.serialize(), before, "O morto e o desconhecido não são realocados nem aliviados.")


func test_an_action_started_in_the_arrival_step_is_cancelled_without_effect_before_the_move() -> void:
	var rig: Rig = _rig(MORNING)
	var merchant: int = _spawn(rig, MERCHANT, SETTLEMENT_A, MARKET_A, MARKET_A)
	assert_true(_run_until(rig, _doing.bind(rig, merchant, HAUL), 40), "A `haul` começou (o pensador rodou depois da economia, com a caravana já apagada).")
	_arrive(rig, merchant, SETTLEMENT_B, 0, 0)
	var now: NpcModule.NpcQuery = rig.npc.peek_npc(merchant)
	assert_eq([now.action_id, now.settlement_id, now.place_id, _departed(rig, merchant), rig.economy.peek_balance(merchant).balance, _held(rig, merchant, BREAD)], ["", SETTLEMENT_B, MARKET_B, false, 300, 0], "A ação foi cancelada sem efeito (nada comprado, nenhuma partida) e a mudança de lugar valeu.")


# ---------------------------------------------------------------------------------------------------- ciclo A, B, A

func test_the_merchant_goes_from_a_to_b_and_back_in_two_markets_and_the_same_world_gives_the_same_hash() -> void:
	var digests: Array = []
	for _run: int in 2:
		var rig: Rig = _rig(MORNING)
		_stock(rig, TOOL, 5, 58)
		var merchant: int = _spawn(rig, MERCHANT, SETTLEMENT_A, MARKET_A, MARKET_A)
		var conserved: Array[bool] = []
		for count: int in [1, 2]:
			assert_true(_run_until(rig, func() -> bool: return rig.arrivals.size() == count, 10 * MINUTES_PER_HOUR), "Chegada %d." % count)
			conserved.append(_conserved(rig))
		var now: NpcModule.NpcQuery = rig.npc.peek_npc(merchant)
		assert_eq(rig.arrivals.map(func(arrived: CaravanArrived) -> String: return arrived.destination_id), [SETTLEMENT_B, SETTLEMENT_A], "Pão do A ao B (A barato, B caro) e ferramenta do B ao A (B barata, A cara).")
		assert_eq([now.settlement_id, now.place_id, conserved], [SETTLEMENT_A, MARKET_A, [true, true] as Array[bool]], "De volta ao mercado de onde saiu e as duas conservações fecham a cada chegada.")
		digests.append([rig.runner.world.state_hash(), rig.economy.peek_balance(merchant).balance, now.x_cm, now.next_think_time])
	assert_eq(digests[0], digests[1], "Mesma semente e mesmos pedidos dão o mesmo mundo.")


# ---------------------------------------------------------------------------------------------------- a sobra e a `sell`

func test_the_leftover_is_sold_by_sell_once_the_market_can_take_it_and_not_before() -> void:
	var rig: Rig = _rig(MORNING, false)
	_stock(rig, WOOL, 30, 5)
	var merchant: int = _spawn(rig, MERCHANT, SETTLEMENT_A, MARKET_A, MARKET_A)
	var eta: int = _depart(rig, merchant, WOOL, 20)
	assert_true(rig.economy.request_set_stock(rig.market_b, WOOL, 52).ok, "O B enche enquanto ele viaja (teto de compra 60): só cabem 8.")
	assert_true(_arrived_by(rig, eta))
	var leftover: int = _held(rig, merchant, WOOL)
	assert_between(leftover, 1, 19, "Vendeu o que coube e a sobra ficou com ele.")
	assert_false(_run_until(rig, _doing.bind(rig, merchant, SELL), 90), "Com o B cheio a sobra não tem valor: a `sell` nem é candidata (e não se repete sem fim).")
	assert_true(rig.economy.request_set_stock(rig.market_b, WOOL, 10).ok, "Abre espaço no B.")
	var expected: int = rig.economy.peek_quote(merchant, rig.market_b, WOOL, leftover, "sell").total
	var before: int = rig.economy.peek_balance(merchant).balance
	assert_true(rig.npc.request_set_traced(merchant, true).ok)
	assert_true(_run_until(rig, _doing.bind(rig, merchant, SELL), 90), "Agora a `sell` vale e o comerciante a escolhe.")
	var record: DecisionTracer.DecisionRecord = rig.npc.explain_decision(merchant).records.back()
	var candidate: DecisionTracer.CandidateRecord = record.candidates.filter(func(row: DecisionTracer.CandidateRecord) -> bool: return row.action_id == SELL)[0]
	assert_eq([record.chosen_action_id, candidate.benefit, candidate.place_id], [SELL, expected, MARKET_B], "O valor derivado é o total da cotação da sobra (100%), no mercado do povoado onde ele está.")
	assert_true(_run_until(rig, func() -> bool: return _held(rig, merchant, WOOL) == 0, 30))
	assert_eq([rig.economy.peek_balance(merchant).balance - before, _conserved(rig)], [expected, true], "Vendeu a sobra toda pelo preço cotado, sem nada nascer nem sumir.")


func test_the_sale_plan_agrees_with_what_the_economy_accepts_in_every_case() -> void:
	var cases: Array[Dictionary] = [
		{"label": "cabe tudo", "stock": 10},
		{"label": "mercado cheio", "stock": 60},
		{"label": "cabem 8", "stock": 52},
		{"label": "sem fundos", "stock": 10, "funds": 0},
		{"label": "fundos para parte", "stock": 10, "funds": 30},
		{"label": "peso", "stock": 10, "room": 4},
	]
	for test_case: Dictionary in cases:
		var tweak: Callable = func(definitions: EconomyDefinitions) -> void:
			for kind: OwnerKindDef in definitions.kinds:
				if kind.id == "market" and test_case.has("funds"):
					kind.initial_balance = test_case["funds"]
		var rig: Rig = _rig(MORNING, false, -1, tweak)
		var merchant: int = _spawn(rig, MERCHANT, SETTLEMENT_B, MARKET_B)
		assert_true(rig.economy.request_set_stock(rig.market_a, WOOL, 40).ok)
		assert_true(rig.economy.request_transfer_goods(rig.market_a, merchant, WOOL, 12).ok)
		assert_true(rig.economy.request_set_stock(rig.market_b, WOOL, test_case["stock"]).ok)
		if test_case.has("room"):
			var market: EconomyReplies.InventoryQuery = rig.economy.peek_inventory(rig.market_b)
			assert_true(rig.economy.request_set_stock(rig.market_b, "wood", rig.economy.peek_stock(rig.market_b, "wood").value + (market.capacity - market.weight - test_case["room"]) / 5).ok, "Enche o peso do mercado, sobrando de 4 a 8.")
		var plan: NpcTrade.SalePlan = _trade(rig, merchant, SETTLEMENT_B, MERCHANT).plan_sale(merchant)
		var accepted: Array = [0, 0]
		for quantity: int in range(12, 0, -1):
			var sold: EconomyReplies.TradeResult = rig.economy.request_trade(merchant, rig.market_b, WOOL, quantity, "sell")
			if sold.result.ok:
				accepted = [quantity, sold.total]
				break
		assert_eq([plan.units, plan.total], accepted, "%s: o plano é a maior venda que a economia aceita (a conta da economia é a verdade)." % test_case["label"])
		assert_eq(plan.is_empty(), test_case["label"] in ["mercado cheio", "sem fundos"], "%s: sem o que o mercado aceite, o plano é vazio e o valor é 0." % test_case["label"])
		assert_true(_conserved(rig))


func test_only_the_merchant_sells_and_never_its_own_food() -> void:
	var rig: Rig = _rig(MORNING, false)
	var merchant: int = _spawn(rig, MERCHANT, SETTLEMENT_A, MARKET_A, MARKET_A)
	var farmer: int = _spawn(rig, "farmer", SETTLEMENT_A, MARKET_A, "a_work_01")
	for holder: int in [merchant, farmer]:
		assert_true(rig.economy.request_transfer_goods(rig.market_a, holder, BREAD, 3).ok)
	assert_true(rig.economy.request_transfer_goods(rig.market_a, farmer, WOOL, 2).ok)
	var merchant_trade: NpcTrade = _trade(rig, merchant, SETTLEMENT_A, MERCHANT)
	assert_true(merchant_trade.sell_value(merchant) == 0 and merchant_trade.plan_sale(merchant).is_empty(), "Só pão no inventário: a comida é a refeição dele e não se vende.")
	assert_true(rig.economy.request_transfer_goods(rig.market_a, merchant, WOOL, 2).ok)
	var plan: NpcTrade.SalePlan = merchant_trade.plan_sale(merchant)
	assert_eq([plan.good_id, plan.units, merchant_trade.sell_value(merchant) > 0], [WOOL, 2, true], "Com lã (depois do pão, por id) o plano vende a lã e deixa o pão.")
	var farmer_trade: NpcTrade = _trade(rig, farmer, SETTLEMENT_A, "farmer")
	assert_eq([farmer_trade.sell_value(farmer), farmer_trade.has_goods(farmer), merchant_trade.is_merchant(farmer)], [0, true, false], "O lavrador tem bens e a `sell` dele vale 0: só o comerciante vende.")
	var farmer_sold: bool = false
	for _minute: int in 5 * MINUTES_PER_HOUR:
		rig.runner.step_once()
		farmer_sold = farmer_sold or _doing(rig, farmer, SELL)
	assert_eq([farmer_sold, _held(rig, farmer, WOOL), _held(rig, merchant, WOOL), _held(rig, merchant, BREAD) > 0, _conserved(rig)], [false, 2, 0, true, true], "Em 5 horas o lavrador nunca vendeu; o comerciante vendeu a lã e guardou o pão.")


func test_the_merchant_that_ate_from_its_cargo_in_transit_arrives_with_less_and_everything_conserves() -> void:
	var rig: Rig = _rig(MORNING, true, 80)
	var merchant: int = _spawn(rig, MERCHANT, SETTLEMENT_A, MARKET_A, MARKET_A)
	var eta: int = _depart(rig, merchant, BREAD, 20)
	rig.runner.run_steps(60)
	assert_true(rig.economy.request_consume(merchant, BREAD, 4).result.ok, "Comeu 4 da própria carga no caminho (`consumed`, legítimo).")
	rig.runner.run_steps(eta - _now(rig) - 1)
	var expected: int = rig.economy.peek_quote(merchant, rig.market_b, BREAD, 16, "sell").total
	rig.runner.step_once()
	var arrived: CaravanArrived = rig.arrivals[0]
	var profit: int = maxi(0, arrived.revenue - arrived.cost_paid)
	assert_eq([arrived.revenue, rig.npc.peek_npc(merchant).need_values[INCOME], rig.npc.peek_npc(merchant).settlement_id, _held(rig, merchant, BREAD)], [expected, maxi(0, 80 - profit), SETTLEMENT_B, 0], "Vendeu os 16 que restaram (`min(lote, inventário)`), o lucro (limitado a 0) alivia `income` e ele foi realocado.")
	assert_true(_conserved(rig), "As duas conservações fecham com o consumo da carga.")


# ---------------------------------------------------------------------------------------------------- comida: o caso dos 120 pães (LW-098h0)

## Muda o saldo inicial do tipo de dono `merchant` (em memória, antes de o mundo começar) para o do caso do `npc` 151.
func _fund_merchants(definitions: EconomyDefinitions) -> void:
	for kind: OwnerKindDef in definitions.kinds:
		if kind.id == MERCHANT:
			kind.initial_balance = CASE_BALANCE


func _destroyed(rig: Rig, good_id: String) -> int:
	for row: Dictionary in rig.economy.peek_goods_conservation().rows:
		if row["good_id"] == good_id:
			return int(row["destroyed"])
	return 0


## O caso do `npc` 151 do diagnóstico da 098h0: comerciante no mercado com a mochila cheia de pão (120 de 120), 505 moedas, pão à venda (o grão esgotado: a melhor compra é de pão e vale mais que a refeição em casa) e a fome já crítica. Sem a correção a `buy` (que ignorava o
## pão da mochila e a capacidade) vencia a `eat`, a conclusão falhava na capacidade e ele a repetia a cada 10 minutos até morrer de fome. Agora ele nunca escolhe `buy`, come da mochila e vive as 72 horas. Com 118 pães sobra lugar para a compra de 2: a `buy` caberia, mas ele já tem comida.
func test_the_merchant_with_a_pack_of_bread_and_critical_hunger_eats_it_and_never_repeats_a_buy() -> void:
	for packed: int in [PACK, PACK - 2]:
		var rig: Rig = _rig(MORNING, false, -1, _fund_merchants, true)
		var merchant: int = _spawn(rig, MERCHANT, SETTLEMENT_A, MARKET_A, MARKET_A)
		assert_true(rig.economy.request_set_stock(rig.market_a, BREAD, 2 * PACK).ok and rig.economy.request_set_stock(rig.market_a, GRAIN, 0).ok and rig.economy.request_transfer_goods(rig.market_a, merchant, BREAD, packed).ok, "Pão à venda e o grão esgotado.")
		assert_eq([_held(rig, merchant, BREAD), rig.economy.peek_inventory(merchant).weight, rig.economy.peek_inventory(merchant).capacity, rig.economy.peek_balance(merchant).balance, rig.economy.peek_stock(rig.market_a, BREAD).value], [packed, packed, PACK, CASE_BALANCE, 2 * PACK - packed], "O caso: %d pães na mochila de 120, 505 moedas e pão à venda." % packed)
		assert_true(rig.npc.peek_npc(merchant).need_urgencies[HUNGER] >= NeedMath.URGENCY_CRITICAL, "A fome nasce em nível crítico.")
		var destroyed: int = _destroyed(rig, BREAD)
		var bought_minutes: int = 0
		var first_meal: int = -1
		for minute: int in CASE_HOURS * MINUTES_PER_HOUR:
			rig.runner.step_once()
			bought_minutes += 1 if _doing(rig, merchant, BUY) else 0
			if first_meal < 0 and _held(rig, merchant, BREAD) < packed:
				first_meal = minute
		var now: NpcModule.NpcQuery = rig.npc.peek_npc(merchant)
		assert_eq([now.is_alive, bought_minutes], [true, 0], "Com %d pães: vivo depois de 72 horas e nenhum minuto em `buy` (nenhuma conclusão de compra falhou na capacidade)." % packed)
		assert_true(first_meal >= 0 and first_meal < MINUTES_PER_HOUR, "Com %d pães: comeu da mochila na primeira hora (ele só precisa chegar em casa)." % packed)
		assert_true(_destroyed(rig, BREAD) > destroyed and _held(rig, merchant, BREAD) < packed and now.need_urgencies[HUNGER] < NeedMath.URGENCY_CRITICAL, "Com %d pães: o pão foi consumido e a fome saiu do nível crítico." % packed)
		assert_true(_conserved(rig))


# ---------------------------------------------------------------------------------------------------- corpo (S0) e escritores de `need_values`

func test_the_body_leaves_s0_before_the_merchant_changes_place() -> void:
	var rig: Rig = _rig(MORNING, false)
	var merchant: int = _spawn(rig, MERCHANT, SETTLEMENT_A, MARKET_A, MARKET_A)
	var spot: Vector3 = _places.peek_place(MARKET_A).place.position
	assert_true(rig.npc.request_set_bodies_available(true).ok)
	assert_true(rig.npc.request_set_focus(ACTOR_ID, spot).ok)
	rig.runner.step_once()
	assert_eq(rig.npc.peek_level_of(merchant), NpcLod.LEVEL_S0, "Com o foco no mercado do A o comerciante tem corpo.")
	var eta: int = _depart(rig, merchant, WOOL, 5)
	assert_true(_arrived_by(rig, eta))
	var now: NpcModule.NpcQuery = rig.npc.peek_npc(merchant)
	assert_eq([rig.npc.peek_level_of(merchant), now.settlement_id, now.place_id, now.x_cm, now.z_cm], [NpcLod.LEVEL_S1, SETTLEMENT_B, MARKET_B, roundi(_places.peek_place(MARKET_B).place.position.x * TerrainData.CM_PER_METER), roundi(_places.peek_place(MARKET_B).place.position.z * TerrainData.CM_PER_METER)], "O corpo saiu de S0 antes da mudança (senão o relato dele devolveria a posição velha) e a posição nova (inclusive x e z) ficou.")


func test_the_arrival_never_writes_needs_itself_and_income_has_one_writer_outside_the_actions() -> void:
	var callers: Array[String] = []
	var scanned: Array[String] = []
	for path: String in _gd_files(NPC_DIR):
		var code: String = _code_of(FileAccess.get_file_as_string(path))
		scanned.append(path.get_file())
		if code.contains("add_pressure("):
			callers.append(path.get_file())
		if path.get_file() == "merchant_arrival.gd":
			assert_false(code.contains("need_values") or code.contains("NeedMath"), "A chegada pede o alívio ao `WageIncome` e não escreve necessidade nenhuma.")
	assert_true(scanned.has("merchant_arrival.gd") and scanned.has("wage_income.gd"), "A varredura enxerga os arquivos certos.")
	callers.sort()
	assert_eq(callers, ["need_math.gd", "npc_thinker.gd", "wage_income.gd"] as Array[String], "Quem soma pressão a uma necessidade: a definição, o alarme (pensador) e o `WageIncome` (salário e lucro realizado).")


func _gd_files(dir_path: String) -> Array[String]:
	var found: Array[String] = []
	for file_name: String in DirAccess.get_files_at(dir_path):
		if file_name.ends_with(".gd"):
			found.append(dir_path.path_join(file_name))
	for folder: String in DirAccess.get_directories_at(dir_path):
		found.append_array(_gd_files(dir_path.path_join(folder)))
	found.sort()
	return found


## Só as linhas de código: o que vem depois de um `#` não conta.
func _code_of(text: String) -> String:
	var kept: PackedStringArray = PackedStringArray()
	for line: String in text.split("\n"):
		var cut: int = line.find("#")
		kept.append(line if cut < 0 else line.substr(0, cut))
	return "\n".join(kept)
