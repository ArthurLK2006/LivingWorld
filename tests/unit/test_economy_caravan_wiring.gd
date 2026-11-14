extends GutTest
## LW-098d3: a LIGAÇÃO da caravana no jogo MONTADO (docs/modules/economy.md, 9.2, 9.9, 9.10 e a linha da 098d3 de 9.12). O jogo REAL de `res://data` sai do `GameModules.register`, a função que o host do app chama, com o `EconomySetup` e o `WorldSetup` reais (rotas A-B 520 m, A-C 430 m e B-C 340 m:
## 143, 124 e 96 minutos por trecho): o `world` chega à economia pelo construtor e `caravan_params.json` chega pelas definições. Sem NPCs (nenhum comerciante em `population.json` até a 098h): o comerciante é um dono aberto pelo teste e o cenário sai de `request_set_stock`
## (o pão é barato no A, estoque 120, e caro no B e no C). A conta, a venda e o desvio já têm teste próprio (098b a 098e): aqui se prova que, no jogo montado, elas enxergam as rotas e os parâmetros reais e que, sem a ligação, não há caravana.

const WORLD_DIR: String = "res://data/world"
const SEED: int = 98
const TRADER: int = 100
const START_MINUTE: int = 1000
const LOT: int = 20
const SETTLEMENT_A: String = "test_settlement_a"
const SETTLEMENT_B: String = "test_settlement_b"
const SETTLEMENT_C: String = "test_settlement_c"

var _terrain: TerrainData
var _settlements: Array[Settlement] = []
var _runners: Array[SimulationRunner] = []
var _temp_dirs: Array[DirAccess] = []


class Rig:
	extends RefCounted

	var runner: SimulationRunner
	var world: WorldModule
	var economy: EconomyModule
	var market_a: int
	var market_b: int
	var market_c: int
	var arrivals: Array[CaravanArrived] = []


func before_all() -> void:
	var terrain: TerrainLoader.LoadResult = TerrainLoader.load_dir(WORLD_DIR)
	assert_true(terrain.result.ok, terrain.result.message)
	_terrain = terrain.terrain
	var loaded: SettlementLoader.LoadResult = SettlementLoader.load_dir(WORLD_DIR, _terrain)
	assert_true(loaded.result.ok, loaded.result.message)
	_settlements = loaded.settlements


## Encerra os mundos (os ouvintes do `EventBus` seguram o `Rig`, que segura o mundo) e apaga as pastas temporárias que o teste criou.
func after_each() -> void:
	for runner: SimulationRunner in _runners:
		runner.finish()
	_runners.clear()
	for dir: DirAccess in _temp_dirs:
		for file_name: String in dir.get_files():
			dir.remove(file_name)
		DirAccess.remove_absolute(dir.get_current_dir())
	_temp_dirs.clear()


## As definições reais da economia, em build de desenvolvimento (`request_set_stock` vale).
func _setup() -> EconomySetup:
	var setup: EconomySetup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR, true)
	assert_true(setup.result.ok, setup.result.message)
	return setup


## O jogo no minuto 1000 com o comerciante (peso 120, saldo 300) e o pão do cenário. `with_routes` falso monta SEM `world_setup` (o `world` vazio); `with_port` falso monta a economia como o app a montava antes da 098d3, SEM a porta de rotas
## (`EconomyModule.new(false, definições)`, com o `world` real registrado ao lado).
func _mount(setup: EconomySetup, with_routes: bool = true, with_port: bool = true) -> Rig:
	var rig: Rig = Rig.new()
	var world_setup: WorldSetup = WorldSetup.from_dir(WORLD_DIR, _settlements, true)
	assert_true(world_setup.result.ok, world_setup.result.message)
	rig.runner = SimulationRunner.new(SEED, START_MINUTE)
	_runners.append(rig.runner)
	if with_port:
		var modules: GameModules = GameModules.register(rig.runner, _terrain, [], null, setup, world_setup if with_routes else null)
		assert_true(modules.result.ok, modules.result.message)
		rig.world = modules.world
		rig.economy = modules.economy
	else:
		rig.world = WorldModule.new(world_setup.routes, true)
		rig.economy = EconomyModule.new(false, setup.definitions)
		assert_true(rig.runner.register_module(GameModules.WORLD_NAME, rig.world).ok)
		assert_true(rig.runner.register_module(GameModules.ECONOMY_NAME, rig.economy).ok)
	rig.runner.start_new_game()
	rig.runner.world.context.events.subscribe("CaravanArrived", func(event: SimEvent) -> void: rig.arrivals.append(event))
	rig.market_a = rig.economy.peek_market_of(SETTLEMENT_A).market_id
	rig.market_b = rig.economy.peek_market_of(SETTLEMENT_B).market_id
	rig.market_c = rig.economy.peek_market_of(SETTLEMENT_C).market_id
	assert_true(rig.economy.request_open_owner(TRADER, EconomyModule.KIND_MERCHANT).ok)
	for stock: Array in [[rig.market_a, 120], [rig.market_b, 15], [rig.market_c, 50]]:
		assert_true(rig.economy.request_set_stock(stock[0], "bread", stock[1]).ok)
	return rig


## Destino, minutos e rotas de cada plano.
func _plan_rows(plans: CaravanReplies.PlansQuery) -> Array:
	return plans.plans.map(func(plan: CaravanReplies.PlanQuery) -> Array: return [plan.destination_market_id, plan.minutes, plan.route_ids])


func test_the_mounted_game_plans_with_the_real_routes() -> void:
	var setup: EconomySetup = _setup()
	var rig: Rig = _mount(setup)
	var before: String = rig.runner.world.state_hash()
	var plans: CaravanReplies.PlansQuery = rig.economy.peek_trade_plans(TRADER, rig.market_a)
	assert_true(plans.result.ok, plans.result.message)
	assert_eq(rig.runner.world.state_hash(), before, "Consultar os planos não muda estado.")
	assert_eq(_plan_rows(plans), [[rig.market_b, 143, ["route_a_b"] as Array[String]], [rig.market_c, 124, ["route_a_c"] as Array[String]]], "As rotas reais chegam ao planejador: A-B em 143 e A-C em 124 minutos à mão.")
	var minutes: Array[int] = []
	for route_id: String in ["route_a_b", "route_a_c", "route_b_c"]:
		var route: Route = rig.world.peek_route(route_id).route
		minutes.append(RouteCost.leg_minutes(RouteCost.Leg.new(route.id, route.length_m, route.difficulty, route.risk), setup.definitions.caravan_params))
	assert_eq(minutes, [143, 124, 96] as Array[int], "`RouteCost` sobre as três rotas lidas do `world` montado e os parâmetros reais: A-B, A-C e B-C.")
	assert_true(rig.world.request_close_route("route_a_b").ok)
	assert_eq(_plan_rows(rig.economy.peek_trade_plans(TRADER, rig.market_a)), [[rig.market_b, 124 + 96, ["route_a_c", "route_b_c"] as Array[String]], [rig.market_c, 124, ["route_a_c"] as Array[String]]], "A porta é o `world` registrado: fechada a A-B, o plano do B passa pelo C (124 + 96 minutos).")


func test_a_merchant_departs_travels_and_arrives_in_the_mounted_game() -> void:
	var rig: Rig = _mount(_setup())
	var started: CaravanReplies.StartResult = rig.economy.request_start_caravan(TRADER, rig.market_a, rig.market_b, "bread", LOT)
	assert_true(started.result.ok, started.result.message)
	assert_eq(started.eta_minute, START_MINUTE + 143, "A-B: 143 minutos à mão.")
	var funds: int = rig.economy.peek_balance(TRADER).balance
	var sum: int = rig.economy.peek_conservation().sum
	rig.runner.run_steps(60)
	var row: CaravanReplies.CaravanQuery = rig.economy.peek_caravan(TRADER)
	assert_eq([row.found, row.state, row.progress_m, row.eta_minute, rig.arrivals.size()], [true, Caravan.STATE_TRAVELLING, 218, started.eta_minute, 0], "Aos 60 minutos ainda viaja: floor(520 × 60 ÷ 143) = 218 m.")
	rig.runner.run_steps(started.eta_minute - START_MINUTE - 60)
	assert_eq(rig.arrivals.size(), 1, "Chegou no minuto do ETA.")
	var arrived: CaravanArrived = rig.arrivals[0]
	assert_eq([arrived.trader_id, arrived.route_id, arrived.destination_id, arrived.cost_paid, arrived.time], [TRADER, "route_a_b", SETTLEMENT_B, started.cost_paid, started.eta_minute], "O evento da chegada, publicado uma vez.")
	assert_gt(arrived.revenue, 0, "O mercado paga pelo lote.")
	assert_eq([rig.economy.peek_caravan(TRADER).found, rig.economy.peek_inventory(TRADER).rows.size(), rig.economy.peek_balance(TRADER).balance], [false, 0, funds + arrived.revenue], "O lote todo foi vendido e o saldo mudou só pela venda.")
	assert_eq([rig.economy.peek_conservation().sum, rig.economy.peek_conservation().ok, rig.economy.peek_goods_conservation().ok, rig.economy.validate()], [sum, true, true, [] as Array[String]], "As duas conservações fecham e o `validate` segue limpo.")
	rig.runner.run_steps(300)
	assert_eq(rig.arrivals.size(), 1, "Um evento por viagem.")


func test_without_the_port_or_the_params_there_is_no_caravan_and_nothing_changes() -> void:
	var no_params: EconomySetup = _setup()
	no_params.definitions.caravan_params = null
	var rigs: Array[Rig] = [_mount(_setup(), true, false), _mount(no_params)]
	for index: int in rigs.size():
		var rig: Rig = rigs[index]
		var before: String = rig.runner.world.state_hash()
		var plans: CaravanReplies.PlansQuery = rig.economy.peek_trade_plans(TRADER, rig.market_a)
		var started: CaravanReplies.StartResult = rig.economy.request_start_caravan(TRADER, rig.market_a, rig.market_b, "bread", LOT)
		assert_eq([plans.result.code, plans.plans.size(), started.result.code, rig.runner.world.state_hash() == before, rig.economy.peek_caravan(TRADER).found], [EconomyCodes.NO_ROUTE, 0, EconomyCodes.NO_ROUTE, true, false], ["Sem a porta.", "Sem os parâmetros."][index])


func test_a_game_mounted_without_world_setup_does_not_break_and_finds_no_route() -> void:
	var rig: Rig = _mount(_setup(), false)
	var before: String = rig.runner.world.state_hash()
	var plans: CaravanReplies.PlansQuery = rig.economy.peek_trade_plans(TRADER, rig.market_a)
	var started: CaravanReplies.StartResult = rig.economy.request_start_caravan(TRADER, rig.market_a, rig.market_b, "bread", LOT)
	assert_eq([plans.result.ok, plans.plans.size(), started.result.code, rig.runner.world.state_hash() == before, rig.economy.peek_caravan(TRADER).found], [true, 0, EconomyCodes.NO_ROUTE, true, false], "O `world` vazio não tem rota: nenhum plano e a partida dá `ECON_NO_ROUTE`.")
	rig.runner.run_days(2)
	assert_eq(rig.economy.validate(), [] as Array[String], "O jogo segue sem quebrar.")


func test_a_missing_or_invalid_params_file_is_one_handled_failure() -> void:
	var real: String = FileAccess.get_file_as_string(EconomySetup.DEFAULT_DIR.path_join(CaravanParamsLoader.PARAMS_FILE))
	var cases: Array[Dictionary] = [
		{"label": "arquivo ausente", "text": null, "expect": ["parâmetros do comerciante", "caravan_params.json", "arquivo não encontrado"]},
		{"label": "linha sem campos", "text": "[{\"id\": \"caravan_defaults\"}]", "expect": ["parâmetros do comerciante", "caravan_params.json", "item 'caravan_defaults'", "campo 'speed_cm_per_min'", "obrigatório ausente"]},
		{"label": "pasta copiada com o arquivo real", "text": real, "expect": []},
	]
	for test_case: Dictionary in cases:
		var setup: EconomySetup = EconomySetup.from_dir(_economy_dir_with(test_case["text"]), true)
		var label: String = test_case["label"]
		if test_case["expect"].is_empty():
			assert_true(setup.result.ok, "%s: %s" % [label, setup.result.message])
			assert_eq(setup.definitions.caravan_params.to_record(), CaravanParamsLoader.load_dir(EconomySetup.DEFAULT_DIR).params.to_record(), "%s: os parâmetros vão para as definições." % label)
			continue
		assert_eq(setup.result.code, EconomySetup.CODE_INVALID, label)
		for fragment: String in test_case["expect"]:
			assert_string_contains(setup.result.message, fragment, label)
		var runner: SimulationRunner = SimulationRunner.new(SEED)
		_runners.append(runner)
		assert_eq(GameModules.register(runner, _terrain, [], null, setup).result.code, EconomySetup.CODE_INVALID, "%s: o jogo não monta com a economia inválida." % label)


## O que prova (e SÓ isto): com a porta de rotas e sem comerciante, ter ou não os parâmetros nas definições não muda o `state_hash` do `world` em 2 dias, sem NPCs. A prova de que o jogo REAL montado (`GameApp`, com os NPCs de `population.json`) não muda com a ligação foi feita por execução na revisão do PR #58 (30 dias, antes e depois: os 31 `state_hash` iguais).
func test_with_the_route_port_and_no_merchant_the_caravan_params_change_no_state_hash() -> void:
	var no_params: EconomySetup = _setup()
	no_params.definitions.caravan_params = null
	var wired: Rig = _mount(_setup())
	var plain: Rig = _mount(no_params)
	for rig: Rig in [wired, plain]:
		rig.runner.run_days(2)
	assert_eq(wired.runner.world.state_hash(), plain.runner.world.state_hash(), "Com a porta e sem comerciante, ter ou não os parâmetros nas definições não muda o `state_hash` do `world` inteiro em 2 dias (sem NPCs).")
	assert_eq(wired.economy.validate(), [] as Array[String])


## Pasta temporária com cópias dos arquivos de `data/economy`; `params_text` é o texto de `caravan_params.json` (nulo: o arquivo não existe).
func _economy_dir_with(params_text: Variant) -> String:
	var dir: DirAccess = DirAccess.create_temp("lw098d3")
	_temp_dirs.append(dir)
	var files: Dictionary[String, String] = {}
	for file_name: String in DirAccess.get_files_at(EconomySetup.DEFAULT_DIR):
		if file_name.ends_with(".json") and file_name != CaravanParamsLoader.PARAMS_FILE:
			files[file_name] = FileAccess.get_file_as_string(EconomySetup.DEFAULT_DIR.path_join(file_name))
	if params_text != null:
		files[CaravanParamsLoader.PARAMS_FILE] = str(params_text)
	for file_name: String in files:
		var file: FileAccess = FileAccess.open(dir.get_current_dir().path_join(file_name), FileAccess.WRITE)
		file.store_string(files[file_name])
		file.close()
	return dir.get_current_dir()
