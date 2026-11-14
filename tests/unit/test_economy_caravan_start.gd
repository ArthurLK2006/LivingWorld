extends GutTest
## LW-098d1: a PARTIDA da caravana e os planos (docs/modules/economy.md, 9.2 a 9.6 e 9.8), com a economia REAL (data/economy, 3 povoados) e o `world` REAL (data/world/routes.json: A-B 520 m, A-C 430 m e B-C 340 m; com os parâmetros reais são 143, 124 e 96 minutos por trecho), montados
## aqui. O pão é barato no A (estoque 120) e caro no B e no C. Os números esperados vêm da mão (minutos, comprimentos, povoados, ETA, posição) e do `TradePlanner` da 098b sobre uma CÓPIA do estado; `peek_trade_plans` e cada falha não mudam NADA (o save inteiro do mundo é o mesmo).

const SEED: int = 98
const WORLD_DIR: String = "res://data/world"
const TRADER: int = 100
const OUTSIDER: int = 101
const START_MINUTE: int = 1000
const SETTLEMENT_A: String = "test_settlement_a"
const SETTLEMENT_B: String = "test_settlement_b"
const SETTLEMENT_C: String = "test_settlement_c"

var _routes: RouteService


class Rig:
	extends RefCounted

	var world: World
	var module: EconomyModule
	var routes: WorldModule
	var clock: SimClock
	var definitions: EconomyDefinitions
	var market_a: int
	var market_b: int
	var market_c: int


func before_all() -> void:
	var terrain: TerrainLoader.LoadResult = TerrainLoader.load_dir(WORLD_DIR)
	var settlements: SettlementLoader.LoadResult = SettlementLoader.load_dir(WORLD_DIR, terrain.terrain)
	var loaded: RouteLoader.LoadResult = RouteLoader.load_dir(WORLD_DIR, settlements.settlements)
	assert_true(loaded.result.ok, loaded.result.message)
	_routes = RouteService.new(loaded.routes, settlements.settlements)


## O jogo no minuto 1000 com um comerciante (peso 120, saldo 300). `with_port` e `with_params` ligam a porta de rotas e os parâmetros da caravana (sem eles não há caravana); `dropped_target`: o id de uma linha de `market_targets.json` que este mercado não terá (um bem que ele não negocia).
func _rig(with_port: bool = true, with_params: bool = true, dropped_target: String = "") -> Rig:
	var rig: Rig = Rig.new()
	var setup: EconomySetup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR, true)
	assert_true(setup.result.ok, setup.result.message)
	rig.definitions = setup.definitions
	rig.definitions.market_targets.assign(rig.definitions.market_targets.filter(func(target: MarketTargetDef) -> bool: return target.id != dropped_target))
	if with_params:
		rig.definitions.caravan_params = CaravanParamsLoader.load_dir(EconomySetup.DEFAULT_DIR).params
	rig.routes = WorldModule.new(_routes, true)
	rig.module = EconomyModule.new(false, rig.definitions, rig.routes if with_port else null)
	rig.clock = SimClock.new()
	rig.world = World.new(SimContext.new(rig.clock, EventBus.new(rig.clock), WorldRng.new(SEED), IdGenerator.new()))
	assert_true(rig.world.register_module("world", rig.routes).ok)
	assert_true(rig.world.register_module("economy", rig.module).ok)
	rig.world.setup()
	rig.world.post_setup()
	rig.world.on_new_game(SEED)
	rig.market_a = rig.module.peek_market_of(SETTLEMENT_A).market_id
	rig.market_b = rig.module.peek_market_of(SETTLEMENT_B).market_id
	rig.market_c = rig.module.peek_market_of(SETTLEMENT_C).market_id
	assert_true(rig.module.request_open_owner(TRADER, EconomyModule.KIND_MERCHANT).ok)
	assert_true(rig.module.request_open_owner(OUTSIDER, "npc").ok)
	for stock: Array in [[rig.market_a, 120], [rig.market_b, 15], [rig.market_c, 50]]:
		assert_true(rig.module.request_set_stock(stock[0], "bread", stock[1]).ok)
	assert_true(rig.clock.on_load({"total_minutes": START_MINUTE}).ok)
	return rig


## O mundo inteiro como texto: se é igual antes e depois, nada mudou (dinheiro, bens, livro de caravanas, rotas e relógio).
func _snapshot(rig: Rig) -> String:
	return JSON.stringify(rig.world.serialize(), "", true, true)


func _at(rig: Rig, minutes_after_start: int) -> void:
	assert_true(rig.clock.on_load({"total_minutes": START_MINUTE + minutes_after_start}).ok)


## Põe no livro, pelo save, a caravana do A ao B pelo C (rotas reais) com `changes` por cima: serve para chegar a trechos que a partida sozinha não alcança.
func _load_caravan(rig: Rig, changes: Dictionary = {}) -> void:
	var record: Dictionary = {"trader_id": TRADER, "state": "travelling", "origin_market_id": rig.market_a, "destination_market_id": rig.market_b, "route_ids": ["route_a_c", "route_b_c"], "leg_index": 0, "leg_started_at": START_MINUTE, "leg_minutes": 124, "elapsed_at_hold": 0, "good_id": "bread", "quantity": 20, "cost_paid": 120, "departed_at": START_MINUTE}
	record.merge(changes, true)
	var block: Dictionary = rig.module.serialize()
	block["caravans"] = [record]
	assert_true(rig.module.on_load(block).ok)


func _derived(row: CaravanReplies.CaravanQuery) -> Array:
	return [row.leg_from_settlement_id, row.leg_to_settlement_id, row.leg_length_m, row.progress_m, row.eta_minute]


func _fields(plan: Object) -> Array:
	return [plan.get("destination_market_id"), plan.get("good_id"), plan.get("quantity"), plan.get("cost"), plan.get("revenue"), plan.get("risk_discount"), plan.get("minutes"), plan.get("net_profit"), plan.get("margin_bp"), plan.get("route_ids")]


## O `TradePlanner` da 098b sobre uma CÓPIA do estado do módulo (o save dele recarregado) com os caminhos escritos à mão: `paths` (destino -> trechos) ou, sem ele, os diretos (A-B e A-C reais).
func _planner_plans(rig: Rig, paths: Dictionary[int, Array] = {}) -> Array[TradePlanner.Plan]:
	var copy: EconomyState = EconomyState.new(rig.definitions, NeutralTradeRules.new(), false)
	assert_true(EconomyPersistence.load_into(copy, rig.module.serialize()).ok)
	var planner: TradePlanner = TradePlanner.new(copy.engine, copy.markets, copy.goods, copy.ledger, rig.definitions.caravan_params, rig.definitions.price_params)
	if paths.is_empty():
		paths = {rig.market_b: [RouteCost.Leg.new("route_a_b", 520, 20, 10)], rig.market_c: [RouteCost.Leg.new("route_a_c", 430, 30, 20)]}
	return planner.plan_all(TRADER, rig.market_a, paths)


func test_trade_plans_match_the_planner_by_destination_and_change_nothing() -> void:
	var rig: Rig = _rig()
	var before: String = _snapshot(rig)
	var plans: CaravanReplies.PlansQuery = rig.module.peek_trade_plans(TRADER, rig.market_a)
	assert_true(plans.result.ok, plans.result.message)
	assert_eq(_snapshot(rig), before, "Consultar os planos não muda estado.")
	var expected: Array[TradePlanner.Plan] = _planner_plans(rig)
	assert_eq(plans.plans.size(), 2, "O pão passa dos limiares nos dois destinos.")
	assert_eq(plans.plans.map(_fields), expected.map(_fields), "Mesmos números e mesma ordem que o planejador da 098b.")
	assert_eq(plans.plans.map(func(plan: CaravanReplies.PlanQuery) -> Array: return [plan.destination_market_id, plan.minutes, plan.route_ids]), [[rig.market_b, 143, ["route_a_b"] as Array[String]], [rig.market_c, 124, ["route_a_c"] as Array[String]]], "Por destino crescente; 143 e 124 minutos à mão.")
	assert_eq(rig.module.peek_trade_plans(TRADER, rig.market_a).plans.map(_fields), plans.plans.map(_fields), "A mesma consulta duas vezes dá o mesmo resultado.")
	assert_eq(rig.module.peek_trade_plans(TRADER, 999).result.code, EconomyCodes.UNKNOWN_MARKET)


func test_the_plans_follow_a_detour_around_a_closed_route() -> void:
	var rig: Rig = _rig()
	assert_true(rig.routes.request_close_route("route_a_b").ok)
	var plans: CaravanReplies.PlansQuery = rig.module.peek_trade_plans(TRADER, rig.market_a)
	assert_true(plans.result.ok, plans.result.message)
	var around: Array[RouteCost.Leg] = [RouteCost.Leg.new("route_a_c", 430, 30, 20), RouteCost.Leg.new("route_b_c", 340, 25, 15)]
	var direct: Array[RouteCost.Leg] = [RouteCost.Leg.new("route_a_c", 430, 30, 20)]
	assert_eq(plans.plans.map(_fields), _planner_plans(rig, {rig.market_b: around, rig.market_c: direct}).map(_fields), "Mesmos números que o planejador da 098b sobre o caminho de DOIS trechos.")
	assert_eq(plans.plans.map(func(plan: CaravanReplies.PlanQuery) -> Array: return [plan.destination_market_id, plan.minutes, plan.route_ids]), [[rig.market_b, 124 + 96, ["route_a_c", "route_b_c"] as Array[String]], [rig.market_c, 124, ["route_a_c"] as Array[String]]], "A-B fechada: o plano do B passa pelo C (124 + 96 minutos).")


func test_a_plan_leads_to_a_start_with_the_planned_cost_and_eta() -> void:
	var rig: Rig = _rig()
	var plan: CaravanReplies.PlanQuery = rig.module.peek_trade_plans(TRADER, rig.market_a).plans[0]
	var started: CaravanReplies.StartResult = rig.module.request_start_caravan(TRADER, rig.market_a, plan.destination_market_id, plan.good_id, plan.quantity)
	assert_true(started.result.ok, started.result.message)
	assert_eq([started.cost_paid, started.eta_minute, rig.module.peek_caravan(TRADER).quantity], [plan.cost, START_MINUTE + plan.minutes, plan.quantity], "Partir com o plano: custa o que ele previu (sem tarifa na Fase 3) e chega no minuto que ele previu.")


func test_the_start_buys_the_lot_atomically_and_returns_the_eta_and_the_cost() -> void:
	var rig: Rig = _rig()
	var quoted: int = rig.module.peek_quote(TRADER, rig.market_a, "bread", 20, "buy").total
	var conservation: EconomyReplies.ConservationQuery = rig.module.peek_conservation()
	var market_funds: int = rig.module.peek_balance(rig.market_a).balance
	var started: CaravanReplies.StartResult = rig.module.request_start_caravan(TRADER, rig.market_a, rig.market_b, "bread", 20)
	assert_true(started.result.ok, started.result.message)
	assert_eq([started.cost_paid, started.eta_minute], [quoted, START_MINUTE + 143], "O lote custa a cotação; o ETA é a saída mais os 143 minutos da A-B.")
	assert_eq([rig.module.peek_balance(TRADER).balance, rig.module.peek_balance(rig.market_a).balance], [300 - quoted, market_funds + quoted], "O dinheiro só trocou de mãos.")
	assert_eq([rig.module.peek_inventory(TRADER).rows, rig.module.peek_stock(rig.market_a, "bread").value], [[{"good_id": "bread", "quantity": 20}] as Array[Dictionary], 100], "A carga é o inventário do comerciante.")
	var after: EconomyReplies.ConservationQuery = rig.module.peek_conservation()
	assert_eq([after.sum, after.created, after.destroyed, after.ok, rig.module.peek_goods_conservation().ok], [conservation.sum, conservation.created, conservation.destroyed, true, true], "Nenhum dinheiro nasce nem some; as duas conservações fecham.")
	assert_eq(rig.module.peek_ledger_totals().rows.filter(func(totals: Dictionary) -> bool: return totals["reason"] == "trade"), [{"reason": "trade", "moved": quoted, "created": 0, "destroyed": 0}] as Array[Dictionary], "O saldo mudou só por `trade`.")
	var row: CaravanReplies.CaravanQuery = rig.module.peek_caravan(TRADER)
	assert_eq([row.found, row.state, row.origin_market_id, row.destination_market_id, row.route_ids, row.leg_index, row.current_route_id, row.good_id, row.quantity, row.cost_paid, row.departed_at], [true, "travelling", rig.market_a, rig.market_b, ["route_a_b"] as Array[String], 0, "route_a_b", "bread", 20, quoted, START_MINUTE])
	assert_eq(_derived(row), [SETTLEMENT_A, SETTLEMENT_B, 520, 0, START_MINUTE + 143], "Os cinco campos derivados na saída.")
	var saved: String = JSON.stringify(rig.module.serialize(), "", true, true)
	_at(rig, 60)
	assert_eq(_derived(rig.module.peek_caravan(TRADER)), [SETTLEMENT_A, SETTLEMENT_B, 520, 218, START_MINUTE + 143], "Aos 60 minutos: floor(520 × 60 ÷ 143) = 218 m.")
	_at(rig, 500)
	assert_eq(rig.module.peek_caravan(TRADER).progress_m, 520, "Passou do fim do trecho: a posição para no fim.")
	assert_eq(JSON.stringify(rig.module.serialize(), "", true, true), saved, "A posição é derivada do relógio: nunca salva.")
	assert_eq([rig.module.peek_caravans_on("route_a_b").caravans.map(func(on_road: CaravanReplies.CaravanQuery) -> int: return on_road.trader_id), rig.module.peek_caravans_on("route_a_c").caravans.size(), rig.module.validate()], [[TRADER], 0, [] as Array[String]])


func test_a_detour_around_a_closed_route_has_two_legs_with_the_real_minutes() -> void:
	var rig: Rig = _rig()
	assert_true(rig.routes.request_close_route("route_a_b").ok)
	var started: CaravanReplies.StartResult = rig.module.request_start_caravan(TRADER, rig.market_a, rig.market_b, "bread", 20)
	assert_true(started.result.ok, started.result.message)
	assert_eq(started.eta_minute, START_MINUTE + 124 + 96, "A-B fechada: o caminho é A-C (124) e C-B (96); o ETA é a saída mais a soma dos trechos.")
	_at(rig, 62)
	var first: CaravanReplies.CaravanQuery = rig.module.peek_caravan(TRADER)
	assert_eq(first.route_ids, ["route_a_c", "route_b_c"] as Array[String])
	assert_eq(_derived(first), [SETTLEMENT_A, SETTLEMENT_C, 430, 215, START_MINUTE + 220], "Trecho 0 (A até C): floor(430 × 62 ÷ 124) = 215 m.")
	_load_caravan(rig, {"leg_index": 1, "leg_started_at": START_MINUTE + 124, "leg_minutes": 96})
	_at(rig, 124 + 48)
	assert_eq(_derived(rig.module.peek_caravan(TRADER)), [SETTLEMENT_C, SETTLEMENT_B, 340, 170, START_MINUTE + 220], "Trecho 1 (C até B, na ordem da viagem): floor(340 × 48 ÷ 96) = 170 m; o ETA é o mesmo da saída.")
	_load_caravan(rig, {"state": "held", "leg_index": 1, "leg_started_at": START_MINUTE + 124, "leg_minutes": 96, "elapsed_at_hold": 40})
	assert_eq(_derived(rig.module.peek_caravan(TRADER)), [SETTLEMENT_C, SETTLEMENT_B, 340, 141, 0], "Parada no meio: a posição usa `elapsed_at_hold` (floor(340 × 40 ÷ 96) = 141) e o ETA é 0.")
	assert_eq(rig.module.validate(), [] as Array[String])


func test_every_failure_changes_nothing_and_has_its_code() -> void:
	var rig: Rig = _rig()
	var cases: Array[Dictionary] = [
		{"label": "sem saldo", "args": [TRADER, rig.market_a, rig.market_c, "tool", 14], "code": EconomyCodes.INSUFFICIENT_FUNDS},
		{"label": "sem estoque", "args": [TRADER, rig.market_a, rig.market_c, "ore", 11], "code": EconomyCodes.INSUFFICIENT_STOCK},
		{"label": "sem capacidade", "args": [TRADER, rig.market_a, rig.market_c, "wood", 25], "code": EconomyCodes.CAPACITY_EXCEEDED},
		{"label": "quantidade zero", "args": [TRADER, rig.market_a, rig.market_c, "bread", 0], "code": EconomyCodes.BAD_QUANTITY},
		{"label": "lote acima do máximo por ordem", "args": [TRADER, rig.market_a, rig.market_c, "bread", rig.definitions.price_params.max_order_quantity + 1], "code": EconomyCodes.BAD_QUANTITY},
		{"label": "bem que não existe", "args": [TRADER, rig.market_a, rig.market_c, "salt", 5], "code": EconomyCodes.UNKNOWN_GOOD},
		{"label": "mercado que não existe", "args": [TRADER, rig.market_a, 999, "bread", 5], "code": EconomyCodes.UNKNOWN_MARKET},
		{"label": "origem igual ao destino", "args": [TRADER, rig.market_a, rig.market_a, "bread", 5], "code": EconomyCodes.NO_ROUTE},
		{"label": "dono que não é merchant", "args": [OUTSIDER, rig.market_a, rig.market_c, "bread", 5], "code": EconomyCodes.TRADER_NOT_ALLOWED},
		{"label": "dono que não existe", "args": [999, rig.market_a, rig.market_c, "bread", 5], "code": EconomyCodes.UNKNOWN_OWNER},
	]
	var before: String = _snapshot(rig)
	var queued: int = rig.world.context.events.debug_summary()["pending"]
	for test_case: Dictionary in cases:
		var args: Array = test_case["args"]
		var refused: CaravanReplies.StartResult = rig.module.request_start_caravan(args[0], args[1], args[2], args[3], args[4])
		assert_eq(refused.result.code, test_case["code"], test_case["label"])
		assert_eq([refused.eta_minute, refused.cost_paid, _snapshot(rig) == before, rig.world.context.events.debug_summary()["pending"]], [0, 0, true, queued], "%s: nada mudou, nada foi devolvido e nenhum evento foi publicado." % test_case["label"])
	assert_true(rig.module.request_start_caravan(TRADER, rig.market_a, rig.market_c, "bread", 5).result.ok)
	before = _snapshot(rig)
	assert_eq(rig.module.request_start_caravan(TRADER, rig.market_a, rig.market_b, "bread", 5).result.code, EconomyCodes.CARAVAN_BUSY, "Uma caravana por comerciante.")
	assert_eq(_snapshot(rig), before, "A recusa não muda nada.")
	assert_eq([rig.module.peek_trade_plans(OUTSIDER, rig.market_a).result.code, rig.module.peek_trade_plans(999, rig.market_a).result.code], [EconomyCodes.TRADER_NOT_ALLOWED, EconomyCodes.UNKNOWN_OWNER], "Os planos recusam quem não é comerciante.")
	assert_true(rig.module.request_open_owner(102, EconomyModule.KIND_MERCHANT).ok)
	assert_true(rig.routes.request_close_route("route_a_b").ok and rig.routes.request_close_route("route_a_c").ok)
	before = _snapshot(rig)
	assert_eq(rig.module.request_start_caravan(102, rig.market_a, rig.market_b, "bread", 5).result.code, EconomyCodes.NO_ROUTE, "O A ficou sem rota aberta.")
	assert_eq([_snapshot(rig) == before, rig.module.peek_trade_plans(102, rig.market_a).plans.size(), rig.module.peek_trade_plans(102, rig.market_a).result.ok], [true, 0, true], "Sem caminho aberto também não há plano.")


func test_the_good_must_be_traded_in_both_markets() -> void:
	var rig: Rig = _rig(true, true, "mt_test_settlement_c_ore")
	var before: String = _snapshot(rig)
	assert_eq(rig.module.request_start_caravan(TRADER, rig.market_a, rig.market_c, "ore", 5).result.code, EconomyCodes.UNKNOWN_GOOD, "O C não negocia minério.")
	assert_eq(_snapshot(rig), before, "A compra não aconteceu.")


func test_the_death_of_the_merchant_removes_the_record_and_keeps_the_sum() -> void:
	var rig: Rig = _rig()
	assert_true(rig.module.request_start_caravan(TRADER, rig.market_a, rig.market_c, "bread", 20).result.ok)
	var sum: int = rig.module.peek_conservation().sum
	rig.world.context.events.publish(NpcDied.new(TRADER, "test", 0))
	rig.world.context.events.dispatch()
	assert_false(rig.module.peek_caravan(TRADER).found, "O registro some.")
	assert_eq(rig.module.request_start_caravan(TRADER, rig.market_a, rig.market_c, "bread", 1).result.code, EconomyCodes.OWNER_CLOSED, "Morto, não parte mais.")
	assert_eq([rig.module.peek_conservation().sum, rig.module.peek_conservation().ok, rig.module.peek_goods_conservation().ok, rig.module.peek_inventory(TRADER).rows.size(), rig.module.validate()], [sum, true, true, 1, [] as Array[String]], "Saldo e carga ficam na conta fechada e a soma se mantém (DEC-146).")


func test_without_the_route_port_or_the_params_there_is_no_caravan() -> void:
	for flags: Array in [[false, true], [true, false], [false, false]]:
		var rig: Rig = _rig(flags[0], flags[1])
		var before: String = _snapshot(rig)
		var plans: CaravanReplies.PlansQuery = rig.module.peek_trade_plans(TRADER, rig.market_a)
		var started: CaravanReplies.StartResult = rig.module.request_start_caravan(TRADER, rig.market_a, rig.market_c, "bread", 5)
		assert_eq([plans.result.code, plans.plans.size(), started.result.code, _snapshot(rig) == before, rig.module.peek_caravan(TRADER).found], [EconomyCodes.NO_ROUTE, 0, EconomyCodes.NO_ROUTE, true, false], "Porta e parâmetros: %s." % str(flags))
	var attached: Rig = _rig()
	var detached: EconomyModule = EconomyModule.new(false, attached.definitions, attached.routes)
	assert_eq(detached.request_start_caravan(TRADER, attached.market_a, attached.market_c, "bread", 5).result.code, EconomyCodes.NO_ROUTE, "Sem `setup` (sem relógio) também não parte.")
	var no_port: Rig = _rig(false)
	_load_caravan(no_port)
	assert_eq([_derived(no_port.module.peek_caravan(TRADER)), no_port.module.validate()], [["", "", 0, 0, 0], [] as Array[String]], "Sem a porta, o registro segue consultável e os cinco campos ficam vazios (compatível com a 098c).")


func test_validate_catches_negative_times_and_cost_and_routes_the_world_does_not_know() -> void:
	var rig: Rig = _rig()
	for changes: Dictionary in [{"cost_paid": -1}, {"departed_at": -2}, {"leg_started_at": -3}]:
		_load_caravan(rig, changes)
		var field: String = changes.keys()[0]
		assert_string_contains("\n".join(rig.module.validate()), "'%s' é %d; esperado 0 ou mais" % [field, changes[field]], field)
	_load_caravan(rig, {"route_ids": ["route_a_c", "route_x"]})
	assert_string_contains("\n".join(rig.module.validate()), "[caravans] a caravana do comerciante 100: a rota 'route_x' não existe no world")
	var no_port: Rig = _rig(false)
	_load_caravan(no_port, {"route_ids": ["route_x"]})
	assert_eq(no_port.module.validate(), [] as Array[String], "Sem a porta de rotas não há como conferir as rotas (9.2).")
