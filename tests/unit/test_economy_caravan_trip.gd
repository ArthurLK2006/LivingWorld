extends GutTest
## LW-098d2: a CHEGADA da caravana (docs/modules/economy.md, 9.3, 9.4, 9.6 e 9.7), com a economia REAL (data/economy, 3 povoados) e o `world` REAL (A-B 520 m, A-C 430 m e B-C 340 m: 143, 124 e 96 minutos por trecho), dentro do `SimulationRunner` (a ordem de cada passo do host: relógio, módulos no `tick`,
## entrega dos eventos) e com os módulos na ordem do jogo: `world`, `economy` e, por último, um "ceifador" no lugar do `npc` (publica a morte). O comerciante leva pão do A ao B. Os minutos saem da mão; a venda sai das cotações da própria economia (`peek_quote`) e de uma contagem unidade a unidade, não de uma segunda cópia da regra.

const SEED: int = 98
const WORLD_DIR: String = "res://data/world"
const TRADER: int = 100
const START_MINUTE: int = 1000
const LOT: int = 20
const SETTLEMENT_A: String = "test_settlement_a"
const SETTLEMENT_B: String = "test_settlement_b"

var _routes: RouteService
var _rigs: Array[Rig] = []


## Faz o papel do `npc` no passo: no minuto `at_minute` publica a morte do comerciante. Registrado depois da economia, como o `npc` no jogo.
class Reaper:
	extends SimModule

	var victim: int = 0
	var at_minute: int = -1
	var _context: SimContext

	func setup(ctx: SimContext) -> void:
		_context = ctx

	func tick(_elapsed_minutes: int) -> void:
		if _context.clock.total_minutes() == at_minute:
			_context.events.publish(NpcDied.new(victim, "test", 0))


class Rig:
	extends RefCounted

	var runner: SimulationRunner
	var module: EconomyModule
	var routes: WorldModule
	var reaper: Reaper
	var definitions: EconomyDefinitions
	var arrivals: Array[CaravanArrived] = []
	var market_a: int
	var market_b: int


func before_all() -> void:
	var terrain: TerrainLoader.LoadResult = TerrainLoader.load_dir(WORLD_DIR)
	var settlements: SettlementLoader.LoadResult = SettlementLoader.load_dir(WORLD_DIR, terrain.terrain)
	var loaded: RouteLoader.LoadResult = RouteLoader.load_dir(WORLD_DIR, settlements.settlements)
	assert_true(loaded.result.ok, loaded.result.message)
	_routes = RouteService.new(loaded.routes, settlements.settlements)


## Encerra os mundos do teste: os ouvintes do `EventBus` seguram o `Rig` e o `Rig` segura o mundo (sem isto o motor acusa vazamento ao sair).
func after_each() -> void:
	for rig: Rig in _rigs:
		rig.runner.finish()
	_rigs.clear()


## O jogo no minuto 1000 com um comerciante (peso 120, saldo 300), as quantidades dos dados nos mercados (pão: A 60, B 40 e C 200, todos no alvo) e a economia conferida a cada `cadence` minutos (o agendador). `market_balance`: o saldo inicial do tipo `market` (-1 = o dos dados).
func _rig(cadence: int = 1, market_balance: int = -1) -> Rig:
	var rig: Rig = Rig.new()
	var setup: EconomySetup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR, true)
	assert_true(setup.result.ok, setup.result.message)
	rig.definitions = setup.definitions
	rig.definitions.caravan_params = CaravanParamsLoader.load_dir(EconomySetup.DEFAULT_DIR).params
	if market_balance >= 0:
		_market_kind(rig).initial_balance = market_balance
	rig.routes = WorldModule.new(_routes, true)
	rig.module = EconomyModule.new(false, rig.definitions, rig.routes)
	rig.reaper = Reaper.new()
	rig.reaper.victim = TRADER
	rig.runner = SimulationRunner.new(SEED, START_MINUTE)
	for entry: Array in [["world", rig.routes], ["economy", rig.module], ["reaper", rig.reaper]]:
		assert_true(rig.runner.register_module(entry[0], entry[1]).ok)
	rig.runner.start_new_game(func(scheduler: Scheduler) -> void: assert_true(scheduler.configure_module("economy", cadence).ok))
	rig.runner.world.context.events.subscribe("CaravanArrived", func(event: SimEvent) -> void: rig.arrivals.append(event))
	rig.market_a = rig.module.peek_market_of(SETTLEMENT_A).market_id
	rig.market_b = rig.module.peek_market_of(SETTLEMENT_B).market_id
	assert_true(rig.module.request_open_owner(TRADER, EconomyModule.KIND_MERCHANT).ok)
	_rigs.append(rig)
	return rig


func _market_kind(rig: Rig) -> OwnerKindDef:
	return rig.definitions.kinds.filter(func(kind: OwnerKindDef) -> bool: return kind.id == "market")[0]


## Roda passos de 1 minuto (relógio, módulos, entrega dos eventos) até o relógio chegar a `minute`.
func _until(rig: Rig, minute: int) -> void:
	rig.runner.run_steps(minute - rig.runner.world.context.clock.total_minutes())


## O comerciante parte do A ao B com o lote de pão.
func _depart(rig: Rig) -> CaravanReplies.StartResult:
	var started: CaravanReplies.StartResult = rig.module.request_start_caravan(TRADER, rig.market_a, rig.market_b, "bread", LOT)
	assert_true(started.result.ok, started.result.message)
	return started


func _conserved(rig: Rig) -> bool:
	return rig.module.peek_conservation().ok and rig.module.peek_goods_conservation().ok


## A maior quantidade do lote que o B aceita agora, contada unidade a unidade (sem busca binária): a cotação de venda vale (cabe no teto de compra), o total não passa do saldo do B e o peso cabe nele.
func _largest_order(rig: Rig) -> int:
	var inventory: EconomyReplies.InventoryQuery = rig.module.peek_inventory(rig.market_b)
	var fits: int = 0
	for quantity: int in range(1, LOT + 1):
		var quoted: EconomyReplies.QuoteQuery = rig.module.peek_quote(TRADER, rig.market_b, "bread", quantity, "sell")
		if quoted.result.ok and quoted.total <= rig.module.peek_balance(rig.market_b).balance and inventory.weight + quantity <= inventory.capacity:
			fits = quantity
	return fits


func test_each_leg_starts_at_the_exact_minute_the_previous_one_ended_whatever_the_step() -> void:
	var outcomes: Array = []
	for cadence: int in [1, 7, 60, 180]:
		var rig: Rig = _rig(cadence)
		assert_true(rig.routes.request_close_route("route_a_b").ok)
		var started: CaravanReplies.StartResult = _depart(rig)
		assert_eq(started.eta_minute, START_MINUTE + 124 + 96, "A-B fechada: o caminho é A-C (124) e B-C (96).")
		if cadence < 96:
			_until(rig, START_MINUTE + 124 + cadence)
			var saved: Dictionary = rig.module.serialize()["caravans"][0]
			assert_eq([saved["leg_index"], saved["leg_started_at"], saved["leg_minutes"], rig.module.peek_caravan(TRADER).eta_minute], [1, START_MINUTE + 124, 96, started.eta_minute], "Passo de %d minutos: o trecho 1 começa no minuto 124 da viagem, não no da conferência; o ETA não muda." % cadence)
		_until(rig, START_MINUTE + 300)
		assert_eq(rig.arrivals.size(), 1, "Passo de %d minutos: uma chegada por viagem." % cadence)
		var arrived: CaravanArrived = rig.arrivals[0]
		outcomes.append([arrived.trader_id, arrived.route_id, arrived.destination_id, arrived.revenue, arrived.cost_paid, rig.runner.world.state_hash()])
	assert_eq(outcomes[0].slice(0, 3), [TRADER, "route_b_c", SETTLEMENT_B], "`route_id` é o último trecho do caminho.")
	assert_eq([outcomes[1], outcomes[2], outcomes[3]], [outcomes[0], outcomes[0], outcomes[0]], "Passos de 1, 7 e 60 minutos (e de 180, que cobre os DOIS trechos num passo só): o mesmo resultado e o mesmo hash do estado.")


func test_the_arrival_sells_the_lot_and_publishes_one_event_after_the_sale() -> void:
	var rig: Rig = _rig()
	var started: CaravanReplies.StartResult = _depart(rig)
	var seen: Array[bool] = []
	rig.runner.world.context.events.subscribe("CaravanArrived", func(_event: SimEvent) -> void: seen.append(rig.module.peek_caravan(TRADER).found))
	var expected: int = rig.module.peek_quote(TRADER, rig.market_b, "bread", LOT, "sell").total
	var before: Dictionary = {"sum": rig.module.peek_conservation().sum, "stock": rig.module.peek_stock(rig.market_b, "bread").value, "funds": rig.module.peek_balance(rig.market_b).balance}
	_until(rig, started.eta_minute - 1)
	assert_eq([rig.module.peek_caravan(TRADER).found, rig.arrivals.size()], [true, 0], "Um minuto antes do ETA ainda viaja.")
	_until(rig, started.eta_minute)
	assert_eq(rig.arrivals.size(), 1, "Chegou no minuto do ETA.")
	var arrived: CaravanArrived = rig.arrivals[0]
	assert_eq([arrived.trader_id, arrived.route_id, arrived.destination_id, arrived.revenue, arrived.cost_paid, arrived.time], [TRADER, "route_a_b", SETTLEMENT_B, expected, started.cost_paid, started.eta_minute], "Os cinco campos de 9.7, publicados no passo da chegada.")
	assert_gt(expected, 0, "O mercado paga pelo lote.")
	assert_eq(seen, [false] as Array[bool], "Quem ouve vê o registro já apagado: o evento sai depois da venda.")
	assert_eq([rig.module.peek_stock(rig.market_b, "bread").value, rig.module.peek_balance(rig.market_b).balance, rig.module.peek_balance(TRADER).balance, rig.module.peek_inventory(TRADER).rows.size()], [before["stock"] + LOT, before["funds"] - expected, 300 - started.cost_paid + expected, 0], "O lote todo foi vendido: o estoque do destino subiu e o saldo mudou só pela venda.")
	var reasons: Array = rig.module.peek_ledger_totals().rows.map(func(row: Dictionary) -> String: return row["reason"])
	assert_eq([rig.module.peek_conservation().sum, _conserved(rig), reasons], [before["sum"], true, ["game_start", "trade"]], "Nenhum dinheiro nasce nem some, as duas conservações fecham e só `game_start` e `trade` mexeram.")
	_until(rig, START_MINUTE + 300)
	assert_eq(rig.arrivals.size(), 1, "Um evento por viagem.")


func test_the_sale_moves_the_destination_stock_and_the_prices_follow_at_the_end_of_the_day() -> void:
	var trip: Rig = _rig()
	var idle: Rig = _rig()
	_depart(trip)
	for rig: Rig in [trip, idle]:
		_until(rig, START_MINUTE + 500)
	var price: Callable = func(rig: Rig, market_id: int) -> int: return rig.module.peek_price(market_id, "bread").value
	assert_eq([trip.arrivals.size(), idle.arrivals.size()], [1, 0], "Passou do fim do dia (minuto 1440) com e sem a viagem.")
	assert_lt(price.call(trip, trip.market_b), price.call(idle, idle.market_b), "O destino recebeu pão (estoque acima do alvo): o preço dele cai.")
	assert_gt(price.call(trip, trip.market_a), price.call(idle, idle.market_a), "A origem perdeu pão: o preço dela sobe.")


func test_a_full_or_broke_destination_buys_only_what_it_can_and_the_rest_stays_with_the_trader() -> void:
	var cases: Array[Dictionary] = [
		{"label": "teto de compra", "stock": 72, "code": EconomyCodes.MARKET_FULL},
		{"label": "capacidade de peso", "room": 7, "code": EconomyCodes.CAPACITY_EXCEEDED},
		{"label": "saldo do mercado", "balance": 60, "code": EconomyCodes.MARKET_NO_FUNDS},
		{"label": "mercado sem saldo", "balance": 0, "code": EconomyCodes.MARKET_NO_FUNDS},
	]
	for test_case: Dictionary in cases:
		var label: String = test_case["label"]
		var rig: Rig = _rig(1, test_case.get("balance", -1))
		if test_case.has("stock"):
			assert_true(rig.module.request_set_stock(rig.market_b, "bread", test_case["stock"]).ok)
		if test_case.has("room"):
			_market_kind(rig).weight_capacity = rig.module.peek_inventory(rig.market_b).weight + test_case["room"]
		var started: CaravanReplies.StartResult = _depart(rig)
		var fits: int = _largest_order(rig)
		var revenue: int = rig.module.peek_quote(TRADER, rig.market_b, "bread", fits, "sell").total if fits > 0 else 0
		_until(rig, started.eta_minute)
		assert_between(fits, 0, LOT - 1, "%s: a venda é parcial." % label)
		assert_eq(rig.arrivals.size(), 1, "%s: chegou mesmo sem vender tudo." % label)
		assert_eq([rig.arrivals[0].revenue, rig.module.peek_inventory(TRADER).weight, rig.module.request_trade(TRADER, rig.market_b, "bread", 1, "sell").result.code, _conserved(rig)], [revenue, LOT - fits, test_case["code"], true], "%s: vendeu a maior quantidade (%d), a sobra fica com o comerciante e mais uma unidade não passa." % [label, fits])


func test_a_merchant_who_dies_on_the_road_never_arrives() -> void:
	var rig: Rig = _rig()
	var started: CaravanReplies.StartResult = _depart(rig)
	var stock: int = rig.module.peek_stock(rig.market_b, "bread").value
	rig.reaper.at_minute = START_MINUTE + 50
	_until(rig, started.eta_minute + 200)
	assert_eq([rig.arrivals.size(), rig.module.peek_caravan(TRADER).found, rig.module.peek_stock(rig.market_b, "bread").value, rig.module.peek_balance(TRADER).balance, rig.module.peek_inventory(TRADER).weight, _conserved(rig), rig.module.validate()], [0, false, stock, 300 - started.cost_paid, LOT, true, [] as Array[String]], "O registro sumiu no `NpcDied`: ninguém chega nem vende; saldo e carga ficam na conta fechada.")


func test_arrival_and_death_in_the_same_step_follow_the_host_order() -> void:
	var rig: Rig = _rig()
	var started: CaravanReplies.StartResult = _depart(rig)
	var order: Array[String] = []
	for event_type: String in ["CaravanArrived", "NpcDied"]:
		rig.runner.world.context.events.subscribe(event_type, func(event: SimEvent) -> void: order.append(event.type))
	rig.reaper.at_minute = started.eta_minute
	_until(rig, started.eta_minute)
	assert_eq(order, ["CaravanArrived", "NpcDied"] as Array[String], "No passo a economia anda antes do `npc` (módulos no `tick`) e os eventos saem depois, na ordem de publicação: chega, vende e só então o dono fecha.")
	assert_gt(rig.arrivals[0].revenue, 0, "A venda aconteceu antes da morte.")
	assert_eq([rig.module.peek_balance(TRADER).balance, rig.module.request_start_caravan(TRADER, rig.market_a, rig.market_b, "bread", 1).result.code, _conserved(rig)], [300 - started.cost_paid + rig.arrivals[0].revenue, EconomyCodes.OWNER_CLOSED, true], "O lucro ficou na conta, agora fechada (DEC-146), e a soma se mantém.")
