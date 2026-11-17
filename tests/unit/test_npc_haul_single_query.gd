extends GutTest
## LW-098h3a (docs/modules/economy.md 9.15.4, otimização 1): o pensamento do comerciante pergunta o plano de viagem UMA vez só. O jogo é montado como o real (dados de `res://data`, rotas e economia reais; `world`, `economy` e `npc` nessa ordem, como o `GameModules`) e só a
## economia é trocada por uma que CONTA as chamadas de `peek_trade_plans` (cada uma refaz o plano de todos os destinos: é o custo que a otimização poupa) e que responde igual à real. O primeiro pensamento do comerciante, rastreado: com plano é 1 consulta (eram 2, `has_trade_plan` e
## depois `haul_value`) e o benefício da `haul` segue sendo o `net_profit` do melhor plano vezes o percentual; sem plano é 1 consulta e a `haul` não é candidata (o comerciante espera); fora das horas de `haul` nenhuma.

const DATA_DIR: String = "res://data"
const WORLD_DIR: String = "res://data/world"
const SEED: int = 98
const SETTLEMENT_A: String = "test_settlement_a"
const SETTLEMENT_B: String = "test_settlement_b"
const MARKET_A: String = "a_market_01"
const HOME_A: String = "a_home_01"
const HAUL: String = "haul"
const BREAD: String = "bread"
const HAUL_PERCENT: int = 50
## 10:00 é hora de `haul` na agenda do comerciante; 03:00 é de `rest`.
const HAUL_HOUR: int = 10 * 60
const REST_HOUR: int = 3 * 60
const MAX_WAIT_MIN: int = 60

var _data: NpcLifeCheck.GameData
var _places: SettlementService
var _runners: Array[SimulationRunner] = []


## A economia real, só com a contagem das chamadas de `peek_trade_plans`.
class CountingEconomy:
	extends EconomyModule

	var plan_queries: int = 0

	func _init(definitions: EconomyDefinitions, world_module: WorldModule) -> void:
		super(false, definitions, world_module)

	func peek_trade_plans(trader_id: int, origin_market_id: int) -> CaravanReplies.PlansQuery:
		plan_queries += 1
		return super.peek_trade_plans(trader_id, origin_market_id)


class Rig:
	extends RefCounted

	var runner: SimulationRunner
	var economy: CountingEconomy
	var npc: NpcModule


func before_all() -> void:
	_data = NpcLifeCheck.load_game_data()
	assert_eq(_data.problem, "", "Os dados reais do jogo carregam.")
	_places = SettlementService.new(_data.settlements, _data.places)


func after_each() -> void:
	for runner: SimulationRunner in _runners:
		runner.finish()
	_runners.clear()


## O jogo como o real, sem população. `spread`: pão 120 no A e 15 no B (há plano de viagem); falso = preços iguais (nenhum plano).
func _rig(start_minute: int, spread: bool) -> Rig:
	var setup: NpcSetup = NpcSetup.from_dir(DATA_DIR, _places, true)
	var economy_setup: EconomySetup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR, true)
	var world_setup: WorldSetup = WorldSetup.from_dir(WORLD_DIR, _data.settlements, true)
	assert_true(setup.result.ok and economy_setup.result.ok and world_setup.result.ok, "Os dados reais montam o jogo.")
	setup.definitions.population = null
	setup.definitions.params.haul_value_percent = HAUL_PERCENT
	var world_module: WorldModule = WorldModule.new(world_setup.routes, world_setup.is_development_build, world_setup.provinces, world_setup.cultures)
	var rig: Rig = Rig.new()
	rig.economy = CountingEconomy.new(economy_setup.definitions, world_module)
	rig.npc = NpcModule.new(setup.need_defs, setup.routine, setup.definitions, rig.economy)
	rig.runner = SimulationRunner.new(SEED, start_minute)
	_runners.append(rig.runner)
	assert_true(rig.runner.register_module(GameModules.WORLD_NAME, world_module).ok)
	assert_true(rig.runner.register_module(GameModules.ECONOMY_NAME, rig.economy).ok)
	assert_true(rig.runner.register_module(GameModules.NPC_NAME, rig.npc).ok)
	rig.runner.start_new_game()
	if spread:
		assert_true(rig.economy.request_set_stock(rig.economy.peek_market_of(SETTLEMENT_A).market_id, BREAD, 120).ok)
		assert_true(rig.economy.request_set_stock(rig.economy.peek_market_of(SETTLEMENT_B).market_id, BREAD, 15).ok)
	return rig


## O comerciante nasce no mercado do A, rastreado.
func _spawn(rig: Rig) -> int:
	var spot: Vector3 = _places.peek_place(MARKET_A).place.position
	var spec: NpcSpec = NpcSpec.new()
	spec.name_key = "npc.name.villager"
	spec.name_number = 1
	spec.occupation_id = "merchant"
	spec.settlement_id = SETTLEMENT_A
	spec.place_id = MARKET_A
	spec.home_place_id = HOME_A
	spec.work_place_id = MARKET_A
	spec.x_cm = roundi(spot.x * TerrainData.CM_PER_METER)
	spec.z_cm = roundi(spot.z * TerrainData.CM_PER_METER)
	var created: NpcModule.CreateResult = rig.npc.request_create_npc(spec)
	assert_true(created.result.ok, created.result.message)
	assert_true(rig.npc.request_set_traced(created.npc_id, true).ok)
	return created.npc_id


## O plano de maior `net_profit` do comerciante no mercado do A (nulo se não há); a conta é da economia, o teste só a lê.
func _best_plan(rig: Rig, merchant: int) -> CaravanReplies.PlanQuery:
	var best: CaravanReplies.PlanQuery = null
	for plan: CaravanReplies.PlanQuery in rig.economy.peek_trade_plans(merchant, rig.economy.peek_market_of(SETTLEMENT_A).market_id).plans:
		if best == null or plan.net_profit > best.net_profit:
			best = plan
	return best


## Anda até o primeiro pensamento do comerciante e devolve [as consultas que a economia recebeu até ele, o registro dele].
func _first_thought(rig: Rig, merchant: int) -> Array:
	rig.economy.plan_queries = 0
	for _minute: int in MAX_WAIT_MIN:
		if not rig.npc.explain_decision(merchant).records.is_empty():
			break
		rig.runner.step_once()
	var records: Array[DecisionTracer.DecisionRecord] = rig.npc.explain_decision(merchant).records
	assert_eq(records.size(), 1, "O comerciante pensou uma vez.")
	return [rig.economy.plan_queries, records[0]]


func _haul_rows(record: DecisionTracer.DecisionRecord) -> Array:
	return record.candidates.filter(func(row: DecisionTracer.CandidateRecord) -> bool: return row.action_id == HAUL)


func test_a_thought_with_a_plan_asks_the_economy_once_and_haul_keeps_the_value_of_the_best_plan() -> void:
	var rig: Rig = _rig(HAUL_HOUR, true)
	var merchant: int = _spawn(rig)
	var plan: CaravanReplies.PlanQuery = _best_plan(rig, merchant)
	assert_not_null(plan, "Com a diferença de preço há plano.")
	var thought: Array = _first_thought(rig, merchant)
	var record: DecisionTracer.DecisionRecord = thought[1]
	assert_eq([thought[0], record.chosen_action_id, _haul_rows(record).size()], [1, HAUL, 1], "Com plano: UMA consulta (eram duas), a `haul` é candidata e é a escolhida.")
	assert_eq(_haul_rows(record)[0].benefit, IntMath.floor_div(plan.net_profit * HAUL_PERCENT, 100), "O benefício é o `net_profit` do melhor plano vezes o percentual, como antes.")


func test_a_thought_without_a_plan_asks_once_and_haul_is_no_candidate_so_the_merchant_waits() -> void:
	var rig: Rig = _rig(HAUL_HOUR, false)
	var merchant: int = _spawn(rig)
	assert_null(_best_plan(rig, merchant), "Preços iguais: nenhum plano passa dos limiares.")
	var thought: Array = _first_thought(rig, merchant)
	var record: DecisionTracer.DecisionRecord = thought[1]
	assert_eq([thought[0], record.chosen_action_id, _haul_rows(record).size()], [1, "wait", 0], "Sem plano: UMA consulta, valor 0 e a `haul` nem é candidata; o comerciante espera, como antes.")


func test_a_thought_outside_the_haul_hours_never_asks_the_economy() -> void:
	var rig: Rig = _rig(REST_HOUR, true)
	var merchant: int = _spawn(rig)
	assert_not_null(_best_plan(rig, merchant), "Há plano, mas a hora é de descanso.")
	var thought: Array = _first_thought(rig, merchant)
	var record: DecisionTracer.DecisionRecord = thought[1]
	assert_eq([thought[0], _haul_rows(record).size()], [0, 0], "Só a `haul` pergunta o plano: as outras ações têm valor derivado 0 sem consultar a economia.")
