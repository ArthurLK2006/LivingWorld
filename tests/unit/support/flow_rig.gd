class_name FlowRig
extends RefCounted
## Ajudante dos testes do fluxo agregado (LW-100d1a; docs/modules/economy.md, 9.16): o jogo no minuto 1000 com a economia REAL (data/economy, 3 povoados) e o `world` REAL (A-B 143 min, A-C 124 e B-C 96 por trecho), só com os dois módulos (`world` e `economy`) dentro do `SimulationRunner` (passos de 1 minuto, a ordem de cada passo do host), em build de desenvolvimento e com os parâmetros da caravana e do fluxo POSTOS NAS DEFINIÇÕES
## (a leitura do `flow_params.json` no jogo montado é da LW-100e). Copia só o necessário do `CaravanRig`, que não é alterado. O dono do teste chama `release()` no fim.

const SEED: int = 100
const START_MINUTE: int = 1000
const A_B: String = "route_a_b"
const A_C: String = "route_a_c"
const B_C: String = "route_b_c"
const GOODS: Array[String] = ["grain", "flour", "bread", "wood", "plank", "ore", "metal", "tool", "wool", "fabric"]

var runner: SimulationRunner
var module: EconomyModule
var definitions: EconomyDefinitions
var market_a: int
var market_b: int
var market_c: int


## Os módulos na ordem do jogo, SEM iniciar o mundo. `flow`: os parâmetros do fluxo (os reais dos dados se nulo); `slowdown_bp`: troca o `difficulty_slowdown_bp` da caravana (negativo = o real); `quiet`: sem produção, postos nem contratos (nenhum outro ator mexe em dinheiro).
static func build(route_service: RouteService, flow: FlowParams = null, slowdown_bp: int = -1, quiet: bool = false) -> FlowRig:
	var rig: FlowRig = FlowRig.new()
	rig.definitions = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR, true).definitions
	var caravan: CaravanParams = CaravanParamsLoader.load_dir(EconomySetup.DEFAULT_DIR).params
	if slowdown_bp >= 0:
		var record: Dictionary = caravan.to_record()
		record["difficulty_slowdown_bp"] = slowdown_bp
		caravan = CaravanParams.new(record)
	rig.definitions.caravan_params = caravan
	rig.definitions.flow_params = flow if flow != null else FlowParamsLoader.load_dir(EconomySetup.DEFAULT_DIR).params
	if quiet:
		rig.definitions.recipes = {}
		rig.definitions.production_sites = []
		rig.definitions.service_posts = []
		rig.definitions.contract_templates = []
	var routes: WorldModule = WorldModule.new(route_service, true)
	rig.module = EconomyModule.new(false, rig.definitions, routes)
	rig.runner = SimulationRunner.new(SEED, START_MINUTE)
	for entry: Array in [["world", routes], ["economy", rig.module]]:
		if not rig.runner.register_module(entry[0], entry[1]).ok:
			push_error("FlowRig: módulo '%s' não registrado." % entry[0])
	return rig


func start_new_game() -> void:
	runner.start_new_game(func(scheduler: Scheduler) -> void: scheduler.configure_module("economy", 1))
	market_a = module.peek_market_of("test_settlement_a").market_id
	market_b = module.peek_market_of("test_settlement_b").market_id
	market_c = module.peek_market_of("test_settlement_c").market_id


## Roda passos de 1 minuto (relógio, módulos, entrega dos eventos) até o relógio chegar a `minute`.
func until(minute: int) -> void:
	runner.run_steps(minute - runner.world.context.clock.total_minutes())


func release() -> void:
	runner.finish()
