extends GutTest
## LW-098d2: PROPRIEDADE das viagens (docs/modules/economy.md, 9.6 e 9.10): viagens ALEATÓRIAS e DETERMINÍSTICAS de três comerciantes entre os três povoados reais, no `SimulationRunner`, por 2,5 dias. O sorteio é do teste (uma `WorldRng` de semente fixa, fora do mundo): os estoques de cinco bens saem sorteados e, a cada 30
## minutos, cada comerciante parado tenta partir com origem, destino, bem e lote sorteados (a economia recusa o que não cabe e a recusa não muda nada) e, de vez em quando, um deles morre (às vezes na estrada, às vezes no passo da chegada). As DUAS conservações fecham A CADA passo; mesma semente, mesmo hash e mesmas chegadas.

const WORLD_DIR: String = "res://data/world"
const SEED: int = 98
const SETTLEMENTS: Array[String] = ["test_settlement_a", "test_settlement_b", "test_settlement_c"]
const TRADERS: Array[int] = [100, 101, 102]
const GOODS: Array[String] = ["bread", "grain", "wool", "fabric", "tool"]
const MINUTES: int = 3600
const DECISION_EVERY: int = 30

var _routes: RouteService


func before_all() -> void:
	var terrain: TerrainLoader.LoadResult = TerrainLoader.load_dir(WORLD_DIR)
	var settlements: SettlementLoader.LoadResult = SettlementLoader.load_dir(WORLD_DIR, terrain.terrain)
	var loaded: RouteLoader.LoadResult = RouteLoader.load_dir(WORLD_DIR, settlements.settlements)
	assert_true(loaded.result.ok, loaded.result.message)
	_routes = RouteService.new(loaded.routes, settlements.settlements)


## Um mundo novo (economia real, três comerciantes de saldo 300) vivido por `MINUTES` passos de 1 minuto com os sorteios de `random_seed`. Devolve o que a propriedade confere: os minutos em que uma conservação falhou, os em que uma recusa mudou o mundo, os problemas do `validate`, as chegadas (com o evento inteiro), quem morreu, quem partiu, quem ficou com as contas das viagens erradas (`unbalanced`) e o hash final.
func _simulate(random_seed: int) -> Dictionary:
	var rng: WorldRng = WorldRng.new(random_seed)
	var setup: EconomySetup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR, true)
	assert_true(setup.result.ok, setup.result.message)
	setup.definitions.caravan_params = CaravanParamsLoader.load_dir(EconomySetup.DEFAULT_DIR).params
	var routes: WorldModule = WorldModule.new(_routes, true)
	var module: EconomyModule = EconomyModule.new(false, setup.definitions, routes)
	var runner: SimulationRunner = SimulationRunner.new(SEED, 1000)
	assert_true(runner.register_module("world", routes).ok and runner.register_module("economy", module).ok)
	runner.start_new_game()
	var result: Dictionary = {"broken": [], "changed": [], "problems": [], "arrivals": [], "dead": [], "departed": [], "unbalanced": []}
	runner.world.context.events.subscribe("CaravanArrived", func(event: SimEvent) -> void: result["arrivals"].append([event.trader_id, event.route_id, event.destination_id, event.revenue, event.cost_paid, event.time]))
	var markets: Array[int] = []
	for settlement_id: String in SETTLEMENTS:
		markets.append(module.peek_market_of(settlement_id).market_id)
		for good_id: String in GOODS:
			assert_true(module.request_set_stock(markets[-1], good_id, rng.range_int("stock", 0, 40)).ok)
	for trader_id: int in TRADERS:
		assert_true(module.request_open_owner(trader_id, EconomyModule.KIND_MERCHANT).ok)
	for minute: int in MINUTES:
		if minute % DECISION_EVERY == 0:
			result["problems"].append_array(module.validate())
			_decide(rng, module, runner, markets, result)
		runner.step_once()
		if not (module.peek_conservation().ok and module.peek_goods_conservation().ok):
			result["broken"].append(runner.world.context.clock.total_minutes())
	for trader_id: int in TRADERS:
		var gap: int = result["departed"].count(trader_id) - result["arrivals"].filter(func(arrival: Array) -> bool: return arrival[0] == trader_id).size() - (1 if module.peek_caravan(trader_id).found else 0)
		if gap != 0 and not (gap == 1 and result["dead"].has(trader_id)):
			result["unbalanced"].append(trader_id)
	result["hash"] = runner.world.state_hash()
	return result


## Um ponto de decisão: cada comerciante vivo e parado tenta partir (uma vez em três) e uma recusa não pode mudar nada; de vez em quando um comerciante vivo morre (o `NpcDied` sai no passo seguinte, depois da conferência das chegadas).
func _decide(rng: WorldRng, module: EconomyModule, runner: SimulationRunner, markets: Array[int], result: Dictionary) -> void:
	for trader_id: int in TRADERS:
		if result["dead"].has(trader_id) or module.peek_caravan(trader_id).found or rng.range_int("try", 0, 1) > 0:
			continue
		var before: String = runner.world.state_hash()
		var started: CaravanReplies.StartResult = module.request_start_caravan(trader_id, markets[rng.range_int("origin", 0, 2)], markets[rng.range_int("destination", 0, 2)], GOODS[rng.range_int("good", 0, GOODS.size() - 1)], rng.range_int("lot", 1, 15))
		if started.result.ok:
			result["departed"].append(trader_id)
		elif runner.world.state_hash() != before:
			result["changed"].append(runner.world.context.clock.total_minutes())
	var victim: int = TRADERS[rng.range_int("victim", 0, 2)]
	if rng.range_int("death", 0, 99) == 0 and not result["dead"].has(victim):
		result["dead"].append(victim)
		runner.world.context.events.publish(NpcDied.new(victim, "test", 0))


func test_random_trips_are_deterministic_and_conserve_money_and_goods_every_step() -> void:
	var first: Dictionary = _simulate(SEED)
	assert_eq([first["broken"], first["changed"], first["problems"], first["unbalanced"]], [[], [], [], []], "As duas conservações fecham a cada passo, a recusa não muda o mundo, o `validate` fica vazio e cada viagem termina uma vez só: chega, segue na estrada ou o comerciante morreu nela.")
	assert_gt(first["arrivals"].size(), 5, "A propriedade não é vazia: houve viagens concluídas (com venda).")
	assert_gt(first["dead"].size(), 0, "...e houve morte de comerciante.")
	var second: Dictionary = _simulate(SEED)
	assert_eq([second["hash"], second["arrivals"], second["dead"]], [first["hash"], first["arrivals"], first["dead"]], "Mesma semente, mesmo hash do estado e mesmas chegadas.")
	assert_ne(_simulate(SEED + 1)["hash"], first["hash"], "Outra semente, outra história.")
