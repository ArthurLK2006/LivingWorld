class_name CaravanRig
extends RefCounted
## Ajudante dos testes da viagem visível (LW-099b1; contrato da LW-099, seções 5 a 8): o jogo no minuto 1000 com a economia REAL (data/economy, 3 povoados) e o `world` REAL (A-B 520 m, A-C 430 m e B-C 340 m: 143, 124 e 96 minutos por trecho), dentro do `SimulationRunner` (a ordem de cada passo do host), com
## comerciantes abertos (peso 120, saldo 300) e a ponte `SimBridge` sobre um host que só guarda o `runner` e a `economy`, sem terreno nem `npc`. O dono do teste chama `release()` no fim: os mundos e o `Node` do host não se soltam sozinhos.

const SEED: int = 98
const WORLD_DIR: String = "res://data/world"
const START_MINUTE: int = 1000
const LOT: int = 12
const SETTLEMENT_A: String = "test_settlement_a"
const SETTLEMENT_B: String = "test_settlement_b"
const SETTLEMENT_C: String = "test_settlement_c"
const A_B: String = "route_a_b"
const A_C: String = "route_a_c"
const B_C: String = "route_b_c"

var runner: SimulationRunner
var module: EconomyModule
var routes: WorldModule
var host: SimulationHostNode
var bridge: SimBridge
var market_a: int
var market_b: int
var market_c: int
var _cadence: int
var _route_service: RouteService


## O `RouteService` com as rotas reais dos dados.
static func load_routes() -> RouteService:
	var terrain: TerrainLoader.LoadResult = TerrainLoader.load_dir(WORLD_DIR)
	var settlements: SettlementLoader.LoadResult = SettlementLoader.load_dir(WORLD_DIR, terrain.terrain)
	var loaded: RouteLoader.LoadResult = RouteLoader.load_dir(WORLD_DIR, settlements.settlements)
	if not loaded.result.ok:
		push_error(loaded.result.message)
	return RouteService.new(loaded.routes, settlements.settlements)


## Todos os campos de uma linha de `peek_caravan`, na ordem do tipo, para comparar linhas (cópia contra cópia, antes e depois de salvar, ou uma lista contra a outra).
static func fields_of(row: CaravanReplies.CaravanQuery) -> Array:
	return [row.result.ok, row.found, row.trader_id, row.state, row.origin_market_id, row.destination_market_id, row.route_ids, row.leg_index, row.current_route_id, row.leg_from_settlement_id, row.leg_to_settlement_id, row.leg_length_m, row.progress_m, row.eta_minute, row.leg_minutes, row.leg_walked_min, row.good_id, row.quantity, row.cost_paid, row.departed_at]


## Os módulos na ordem do jogo (`world`, `economy`), SEM iniciar o mundo; a economia é conferida a cada `cadence` minutos (o agendador).
static func build(route_service: RouteService, cadence: int = 1) -> CaravanRig:
	var rig: CaravanRig = CaravanRig.new()
	var setup: EconomySetup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR, true)
	setup.definitions.caravan_params = CaravanParamsLoader.load_dir(EconomySetup.DEFAULT_DIR).params
	rig.routes = WorldModule.new(route_service, true)
	rig.module = EconomyModule.new(false, setup.definitions, rig.routes)
	rig.runner = SimulationRunner.new(SEED, START_MINUTE)
	for entry: Array in [["world", rig.routes], ["economy", rig.module]]:
		if not rig.runner.register_module(entry[0], entry[1]).ok:
			push_error("CaravanRig: módulo '%s' não registrado." % entry[0])
	rig._cadence = cadence
	rig._route_service = route_service
	rig.host = SimulationHostNode.new()
	rig.host.runner = rig.runner
	rig.host.economy = rig.module
	rig.bridge = SimBridge.new(rig.host, null)
	return rig


## O jogo novo, com os `traders` abertos como comerciantes.
func start_new_game(traders: Array[int]) -> void:
	runner.start_new_game(_configure())
	_find_markets()
	for trader_id: int in traders:
		if not module.request_open_owner(trader_id, EconomyModule.KIND_MERCHANT).ok:
			push_error("CaravanRig: o comerciante %d não abriu." % trader_id)


## O mesmo jogo salvo, passado pelo JSON e carregado num mundo novo com os mesmos módulos.
func reload() -> CaravanRig:
	var copy: CaravanRig = CaravanRig.build(_route_service, _cadence)
	# Variant: o JSON devolve qualquer tipo; aqui o formato é conhecido (o save do jogo, um objeto).
	var payload: Variant = JSON.parse_string(JSON.stringify(runner.capture_game()))
	var loaded: Result = copy.runner.load_game(payload as Dictionary, copy._configure())
	if not loaded.ok:
		push_error(loaded.message)
	copy._find_markets()
	return copy


func clock() -> SimClock:
	return runner.world.context.clock


## Roda passos de 1 minuto (relógio, módulos, entrega dos eventos) até o relógio chegar a `minute`.
func until(minute: int) -> void:
	runner.run_steps(minute - clock().total_minutes())


## O comerciante parte do mercado `from_market` ao `to_market` com `LOT` pães.
func depart(trader_id: int, from_market: int, to_market: int) -> CaravanReplies.StartResult:
	return module.request_start_caravan(trader_id, from_market, to_market, "bread", LOT)


## Três caravanas de estados diferentes, até o minuto 1130, com a A-B fechada desde o início: `in_settlement` parte do A ao B às 1000 pelo A-C (124) e C-B (96); `travelling` parte do A ao C às 1030 (andando); `mid_road` parte do B ao C às 1040 e a B-C fecha às 1060 (parada no MEIO da estrada, com 20 minutos
## andados); às 1124 `in_settlement` chega ao C com a B-C fechada e a A-B também: sem caminho, fica parada NUM POVOADO (`elapsed_at_hold` 0 e o trecho bloqueado ainda não andado). A partida é em outra ordem que a dos ids, de propósito.
func three_states(travelling: int, mid_road: int, in_settlement: int) -> void:
	set_route(A_B, false)
	for departure: Array in [[0, in_settlement, market_a, market_b], [30, travelling, market_a, market_c], [40, mid_road, market_b, market_c]]:
		until(START_MINUTE + departure[0])
		if not depart(departure[1], departure[2], departure[3]).result.ok:
			push_error("CaravanRig: o comerciante %d não partiu." % departure[1])
	until(START_MINUTE + 60)
	set_route(B_C, false)
	until(START_MINUTE + 130)


## Abre ou fecha a rota no `world` e entrega o `RouteStateChanged` agora, no minuto em que o relógio está.
func set_route(route_id: String, is_open: bool) -> void:
	var asked: Result = routes.request_open_route(route_id) if is_open else routes.request_close_route(route_id)
	if not asked.ok:
		push_error(asked.message)
	runner.world.context.events.dispatch()


## Encerra o mundo e solta o `Node` do host.
func release() -> void:
	runner.finish()
	host.free()


func _configure() -> Callable:
	var cadence: int = _cadence
	return func(scheduler: Scheduler) -> void:
		if not scheduler.configure_module("economy", cadence).ok:
			push_error("CaravanRig: cadência %d recusada." % cadence)


func _find_markets() -> void:
	market_a = module.peek_market_of(SETTLEMENT_A).market_id
	market_b = module.peek_market_of(SETTLEMENT_B).market_id
	market_c = module.peek_market_of(SETTLEMENT_C).market_id
