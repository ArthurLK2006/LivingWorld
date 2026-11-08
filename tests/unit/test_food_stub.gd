extends GutTest
## TEMP-LW-065: o estoque de comida provisório (FoodStub; docs/modules/npc.md, seção 9), sem janela. SAI NA LW-094, junto com o FoodStub, e este
## teste com ele. Mundo de teste montado à mão, com números fáceis de conferir na mão: no assentamento A começa com 10, teto 50, refeição 2 e
## colheita 7 do agricultor; no B começa com 3, teto 20, refeição 3 e colheita 4. Cobre: estoque nunca negativo; "comer" consome só ao
## completar; só o agricultor que COMPLETA o trabalho repõe; teto; dado do arquivo (válido e inválido, marca em cada linha); marca TEMP-LW-065
## em cada arquivo do stub; salvar e carregar; comando de desenvolvimento; e a volta por cima quando a comida chega a zero.

const VILLAGE_A: String = "village_a"
const VILLAGE_B: String = "village_b"
const HOME_A: String = "home_a"
const WORK_A: String = "work_a"
const HOME_B: String = "home_b"
const WORK_B: String = "work_b"
const NEED_IDS: Array[String] = ["hunger", "rest", "safety", "income", "social"]
const TRAIT_IDS: Array[String] = ["caution", "sociability", "ambition", "loyalty"]
const HUNGER: int = 0
const REST: int = 1
const HOME_A_CM: int = 8400
const WORK_A_CM: int = 18400
const HOME_B_CM: int = 108400
const WORK_B_CM: int = 118400
const FILE_LABEL: String = "res://data/food_stub.json"
const ISSUE_CODE: String = "NPC_FOOD_STUB_INVALID"
const FOOD_DIR: String = "res://src/sim/npc/food"


# ---------------------------------------------------------------------------------------------------- mundo de teste

func _need_defs(start_hunger: int = 0) -> Array[NeedDef]:
	var defs: Array[NeedDef] = []
	for position: int in NEED_IDS.size():
		defs.append(NeedDef.new(NEED_IDS[position], position, start_hunger if position == HUNGER else 0, 0, 40, 65, 90))
	return defs


func _action(action_id: String, duration: int, place_kind: String, risk: int = 0) -> ActionDef:
	return ActionDef.new(action_id, duration, place_kind, risk, true)


func _catalog() -> Array[ActionDef]:
	var eat: ActionDef = _action("eat", 20, "home")
	eat.effects.append(ActionDef.ActionEffect.new("hunger", -60))
	eat.conditions.append(ActionDef.ActionCondition.new(ActionDef.CONDITION_HAS_FOOD, "", ActionDef.ABSENT, ActionDef.ABSENT))
	var work: ActionDef = _action("work", 240, "work", 5)
	work.effects.append(ActionDef.ActionEffect.new("rest", 5))
	return [eat, work, _action("wait", 10, ""), _action(ActionRunner.GO_TO_PLACE_ID, 0, "")]


func _routine() -> RoutineTable:
	var occupations: Array[RoutineTable.OccupationDef] = [RoutineTable.OccupationDef.new("farmer", "work"), RoutineTable.OccupationDef.new("guard", "work")]
	var blocks: Array[RoutineTable.RoutineBlock] = [RoutineTable.RoutineBlock.new("f", "farmer", 0, 24, "work"), RoutineTable.RoutineBlock.new("g", "guard", 0, 24, "work")]
	return RoutineTable.new(occupations, blocks)


func _places() -> SettlementService:
	var settlements: Array[Settlement] = [Settlement.new(VILLAGE_A, "settlement.a", Vector3.ZERO), Settlement.new(VILLAGE_B, "settlement.b", Vector3(1000.0, 0.0, 0.0))]
	var places: Array[Place] = [
		Place.new(HOME_A, VILLAGE_A, Place.KIND_HOME, Vector3(84.0, 0.0, 0.0), 5), Place.new(WORK_A, VILLAGE_A, Place.KIND_WORK, Vector3(184.0, 0.0, 0.0), 5),
		Place.new(HOME_B, VILLAGE_B, Place.KIND_HOME, Vector3(1084.0, 0.0, 0.0), 5), Place.new(WORK_B, VILLAGE_B, Place.KIND_WORK, Vector3(1184.0, 0.0, 0.0), 5),
	]
	return SettlementService.new(settlements, places)


func _rules() -> Array[FoodStub.FoodRule]:
	return [FoodStub.FoodRule.new(VILLAGE_A, 10, 50, 2, "farmer", 7), FoodStub.FoodRule.new(VILLAGE_B, 3, 20, 3, "farmer", 4)]


func _stub() -> FoodStub:
	return FoodStub.new(_rules())


func _params() -> NpcParams:
	var params: NpcParams = NpcParams.new()
	params.urgency_weight_attention = 1
	params.urgency_weight_urgent = 3
	params.urgency_weight_critical = 6
	params.time_cost_per_hour = 2
	params.distance_cost_per_100m = 2
	params.risk_cost_percent = 100
	params.inertia_bonus = 25
	params.routine_bonus = 40
	params.think_interval_min = 10
	params.max_thinks_per_step = 20
	params.decision_top_k = 1
	return params


func _definitions(food_stub: FoodStub, is_development_build: bool = false) -> NpcModule.Definitions:
	var definitions: NpcModule.Definitions = NpcModule.Definitions.new()
	definitions.actions = _catalog()
	var traits: Array[TraitLoader.TraitDef] = []
	for position: int in TRAIT_IDS.size():
		traits.append(TraitLoader.TraitDef.new(TRAIT_IDS[position], position))
	definitions.traits = traits
	definitions.params = _params()
	definitions.places = _places()
	definitions.food = food_stub
	definitions.is_development_build = is_development_build
	return definitions


func _module(food_stub: FoodStub, start_hunger: int = 0, is_development_build: bool = false) -> NpcModule:
	return NpcModule.new(_need_defs(start_hunger), _routine(), _definitions(food_stub, is_development_build))


func _world(module: NpcModule) -> World:
	var clock: SimClock = SimClock.new()
	var world: World = World.new(SimContext.new(clock, EventBus.new(clock), WorldRng.new(3), IdGenerator.new()))
	assert_true(world.register_module("npc", module).ok)
	world.setup()
	world.post_setup()
	return world


## NPC em casa, no assentamento A ou no B.
func _spawn(module: NpcModule, occupation_id: String, in_village_b: bool = false) -> int:
	var spec: NpcSpec = NpcSpec.new()
	spec.name_key = "npc.name.villager"
	spec.occupation_id = occupation_id
	spec.settlement_id = VILLAGE_B if in_village_b else VILLAGE_A
	spec.place_id = HOME_B if in_village_b else HOME_A
	spec.home_place_id = spec.place_id
	spec.work_place_id = WORK_B if in_village_b else WORK_A
	spec.x_cm = HOME_B_CM if in_village_b else HOME_A_CM
	var created: NpcModule.CreateResult = module.request_create_npc(spec)
	assert_true(created.result.ok, created.result.message)
	return created.npc_id


func _run(world: World, minutes: int) -> void:
	for _step: int in minutes:
		world.context.clock.advance_step()
		world.tick(1)


func _json_round_trip(data: Dictionary) -> Dictionary:
	var parsed: Variant = JSON.parse_string(JSON.stringify(data, "", true, true))
	var restored: Dictionary = parsed
	return restored


## Runner solto com o FoodStub como provedor. Os NPCs são acrescentados com `_add_npc`.
class RunnerParts:
	extends RefCounted

	var runner: ActionRunner
	var states: Dictionary[int, NpcState] = {}
	var food_stub: FoodStub


func _runner_parts() -> RunnerParts:
	var parts: RunnerParts = RunnerParts.new()
	parts.food_stub = _stub()
	parts.runner = ActionRunner.new(parts.states, _catalog(), _need_defs(), _places(), parts.food_stub)
	assert_eq(parts.runner.peek_problem(), "")
	return parts


func _add_npc(parts: RunnerParts, npc_id: int, occupation_id: String, in_village_b: bool = false, hunger: int = 0) -> NpcState:
	var state: NpcState = NpcState.new(npc_id)
	state.occupation_id = occupation_id
	state.settlement_id = VILLAGE_B if in_village_b else VILLAGE_A
	state.place_id = HOME_B if in_village_b else HOME_A
	state.x_cm = HOME_B_CM if in_village_b else HOME_A_CM
	state.need_values = PackedInt64Array([hunger, 0, 0, 0, 0])
	parts.states[npc_id] = state
	return state


func _stock(food_stub: FoodStub, settlement_id: String) -> int:
	return food_stub.peek_stock(settlement_id).stock


# ---------------------------------------------------------------------------------------------------- o estoque em si

func test_the_stock_never_goes_negative_and_a_refused_consumption_changes_nothing() -> void:
	var food_stub: FoodStub = _stub()
	assert_eq([_stock(food_stub, VILLAGE_A), _stock(food_stub, VILLAGE_B)], [10, 3], "Começa em start_stock.")
	var too_much: Result = food_stub.request_consume(VILLAGE_A, 11)
	assert_false(too_much.ok)
	assert_eq(too_much.code, FoodStub.CODE_NOT_ENOUGH)
	assert_string_contains(too_much.message, "tem 10")
	assert_eq(_stock(food_stub, VILLAGE_A), 10, "Recusado: nada foi consumido.")
	assert_true(food_stub.request_consume(VILLAGE_A, 10).ok, "Consumir exatamente o que há é permitido.")
	assert_eq(_stock(food_stub, VILLAGE_A), 0)
	assert_eq(food_stub.request_consume(VILLAGE_A, 1).code, FoodStub.CODE_NOT_ENOUGH, "Com estoque zero nada cabe.")
	assert_eq(_stock(food_stub, VILLAGE_A), 0, "Nunca negativo.")
	for invalid: int in [0, -3]:
		assert_eq(food_stub.request_consume(VILLAGE_B, invalid).code, FoodStub.CODE_INVALID_AMOUNT, "Quantidade %d." % invalid)
	assert_eq(_stock(food_stub, VILLAGE_B), 3)
	assert_eq(food_stub.request_consume("nowhere", 1).code, FoodStub.CODE_UNKNOWN_SETTLEMENT)


func test_has_food_means_a_whole_meal_for_that_settlement() -> void:
	var food_stub: FoodStub = _stub()
	assert_true(food_stub.has_food(VILLAGE_A), "10 de comida, refeição de 2.")
	assert_true(food_stub.has_food(VILLAGE_B), "3 de comida, refeição de 3: cabe exatamente.")
	assert_true(food_stub.request_consume(VILLAGE_B, 1).ok)
	assert_false(food_stub.has_food(VILLAGE_B), "2 de comida não é uma refeição de 3.")
	assert_false(food_stub.has_food("nowhere"), "Assentamento sem regra: sem comida.")
	assert_false(food_stub.has_food(""), "Sem assentamento: sem comida.")


func test_adding_stops_at_the_ceiling_and_setting_is_range_checked() -> void:
	var food_stub: FoodStub = _stub()
	assert_true(food_stub.request_add(VILLAGE_A, 45).ok)
	assert_eq(_stock(food_stub, VILLAGE_A), 50, "10 + 45 passa do teto 50: o que passa se perde.")
	assert_eq(food_stub.request_add(VILLAGE_A, 0).code, FoodStub.CODE_INVALID_AMOUNT)
	assert_eq(food_stub.request_add(VILLAGE_A, 51).code, FoodStub.CODE_INVALID_AMOUNT, "Mais que o teto de uma vez é pedido absurdo.")
	assert_eq(food_stub.request_add("nowhere", 1).code, FoodStub.CODE_UNKNOWN_SETTLEMENT)
	assert_true(food_stub.request_set_stock(VILLAGE_B, 0).ok)
	assert_true(food_stub.request_set_stock(VILLAGE_B, 20).ok)
	assert_eq(food_stub.request_set_stock(VILLAGE_B, -1).code, FoodStub.CODE_INVALID_AMOUNT)
	assert_eq(food_stub.request_set_stock(VILLAGE_B, 21).code, FoodStub.CODE_INVALID_AMOUNT)
	assert_eq(_stock(food_stub, VILLAGE_B), 20, "Pedido recusado não altera o estoque.")
	var unknown: FoodStub.StockQuery = food_stub.peek_stock("nowhere")
	assert_eq(unknown.result.code, FoodStub.CODE_UNKNOWN_SETTLEMENT)
	assert_eq(food_stub.peek_stock(VILLAGE_A).max_stock, 50)


# ---------------------------------------------------------------------------------------------------- comer e trabalhar pelo runner

func test_eating_takes_the_meal_from_the_npcs_settlement_only_when_the_meal_completes() -> void:
	var parts: RunnerParts = _runner_parts()
	var in_a: NpcState = _add_npc(parts, 1, "farmer", false, 95)
	var in_b: NpcState = _add_npc(parts, 2, "guard", true, 95)
	assert_true(parts.runner.begin(1, "eat", HOME_A, 10).ok)
	assert_true(parts.runner.begin(2, "eat", HOME_B, 10).ok)
	assert_eq(parts.runner.advance(1, 29).outcome, ActionRunner.Outcome.RUNNING)
	assert_eq([_stock(parts.food_stub, VILLAGE_A), _stock(parts.food_stub, VILLAGE_B)], [10, 3], "Durante a refeição o estoque não muda.")
	assert_eq(parts.runner.advance(1, 30).outcome, ActionRunner.Outcome.COMPLETED)
	assert_eq([_stock(parts.food_stub, VILLAGE_A), _stock(parts.food_stub, VILLAGE_B)], [8, 3], "A refeição do A custa 2, e só do A.")
	assert_eq(in_a.need_values[HUNGER], 35)
	assert_eq(parts.runner.advance(2, 30).outcome, ActionRunner.Outcome.COMPLETED)
	assert_eq([_stock(parts.food_stub, VILLAGE_A), _stock(parts.food_stub, VILLAGE_B)], [8, 0], "A refeição do B custa 3 (todo o estoque dele).")
	assert_eq(in_b.need_values[HUNGER], 35)
	var refused: Result = parts.runner.begin(2, "eat", HOME_B, 40)
	assert_false(refused.ok, "Com o estoque do B em zero ninguém começa a comer lá.")
	assert_string_contains(refused.message, "has_food")
	assert_eq(_stock(parts.food_stub, VILLAGE_B), 0, "Nunca negativo.")


func test_two_meals_finishing_together_with_food_for_one_leave_one_fed_and_one_unfed() -> void:
	var parts: RunnerParts = _runner_parts()
	var first: NpcState = _add_npc(parts, 1, "guard", false, 95)
	var second: NpcState = _add_npc(parts, 2, "guard", false, 95)
	assert_true(parts.food_stub.request_set_stock(VILLAGE_A, 2).ok)
	assert_true(parts.runner.begin(1, "eat", HOME_A, 10).ok, "No começo havia comida para uma refeição.")
	assert_true(parts.runner.begin(2, "eat", HOME_A, 10).ok, "E ninguém tinha pegado ainda.")
	assert_eq(parts.runner.advance(1, 30).outcome, ActionRunner.Outcome.COMPLETED)
	var late: ActionRunner.AdvanceResult = parts.runner.advance(2, 30)
	assert_eq(late.outcome, ActionRunner.Outcome.FAILED, "Quando o segundo termina, a comida já acabou.")
	assert_eq(late.result.code, ActionRunner.CODE_ACTION_FAILED)
	assert_eq([first.need_values[HUNGER], second.need_values[HUNGER]], [35, 95], "Só o primeiro comeu.")
	assert_eq(_stock(parts.food_stub, VILLAGE_A), 0, "O estoque parou em zero, não ficou negativo.")
	assert_eq(second.action_id, "", "O segundo ficou livre para decidir de novo.")


func test_only_a_completed_work_of_the_producing_occupation_replenishes_the_stock() -> void:
	var parts: RunnerParts = _runner_parts()
	_add_npc(parts, 1, "farmer")
	_add_npc(parts, 2, "guard")
	assert_true(parts.runner.begin(1, "work", WORK_A, 100).ok)
	assert_eq(parts.runner.advance(1, 339).outcome, ActionRunner.Outcome.RUNNING)
	assert_eq(_stock(parts.food_stub, VILLAGE_A), 10, "Trabalhando ainda não colheu.")
	assert_eq(parts.runner.advance(1, 340).outcome, ActionRunner.Outcome.COMPLETED)
	assert_eq(_stock(parts.food_stub, VILLAGE_A), 17, "Agricultor completou o trabalho: + 7.")
	assert_true(parts.runner.begin(2, "work", WORK_A, 400).ok)
	assert_eq(parts.runner.advance(2, 640).outcome, ActionRunner.Outcome.COMPLETED)
	assert_eq(_stock(parts.food_stub, VILLAGE_A), 17, "Guarda não produz comida.")
	assert_true(parts.runner.begin(1, "work", WORK_A, 700).ok)
	assert_true(parts.runner.interrupt(1, 820).ok)
	assert_eq(_stock(parts.food_stub, VILLAGE_A), 17, "Trabalho interrompido não colhe.")
	assert_eq(_stock(parts.food_stub, VILLAGE_B), 3, "O outro assentamento não foi tocado.")
	assert_true(parts.food_stub.request_set_stock(VILLAGE_A, 48).ok)
	assert_true(parts.runner.begin(1, "work", WORK_A, 900).ok)
	assert_eq(parts.runner.advance(1, 1140).outcome, ActionRunner.Outcome.COMPLETED)
	assert_eq(_stock(parts.food_stub, VILLAGE_A), 50, "48 + 7 passa do teto 50.")


func test_the_hook_is_not_called_for_an_interrupted_action_and_a_base_provider_ignores_it() -> void:
	var base: ActionConditionProvider = ActionConditionProvider.new()
	base.on_action_completed("eat", VILLAGE_A, "farmer")
	assert_false(base.has_food(VILLAGE_A), "A classe-base continua sem comida e o gancho dela não faz nada.")
	var parts: RunnerParts = _runner_parts()
	_add_npc(parts, 1, "farmer", false, 95)
	assert_true(parts.runner.begin(1, "eat", HOME_A, 10).ok)
	assert_true(parts.runner.interrupt(1, 20).ok)
	assert_eq(_stock(parts.food_stub, VILLAGE_A), 10, "Refeição interrompida não consome comida.")


# ---------------------------------------------------------------------------------------------------- no módulo

func test_a_hungry_farmer_with_no_food_works_restocks_the_village_and_then_eats() -> void:
	var food_stub: FoodStub = _stub()
	var module: NpcModule = _module(food_stub, 95, true)
	var world: World = _world(module)
	var npc_id: int = _spawn(module, "farmer")
	assert_true(module.request_set_food_stock(VILLAGE_A, 0).ok, "O teste 'comida a zero' do checklist.")
	var first_think: int = 1 + npc_id % 10
	_run(world, first_think)
	assert_eq(module.peek_npc(npc_id).action_id, ActionRunner.GO_TO_PLACE_ID, "Sem comida a refeição não pode começar: o agricultor vai trabalhar.")
	_run(world, 300)
	var fed: NpcModule.NpcQuery = module.peek_npc(npc_id)
	assert_eq(_stock(food_stub, VILLAGE_A), 5, "Colheu 7, comeu uma refeição de 2.")
	assert_eq(fed.need_values[HUNGER], 35, "A fome de 95 caiu 60 com a refeição.")
	assert_eq(module.validate().size(), 0, str(module.validate()))
	world.teardown()


func test_with_stock_and_a_hungry_npc_the_meal_comes_out_of_the_real_stock() -> void:
	var food_stub: FoodStub = _stub()
	var module: NpcModule = _module(food_stub, 95)
	var world: World = _world(module)
	var npc_id: int = _spawn(module, "guard")
	_run(world, 1 + npc_id % 10 + 20)
	assert_eq(_stock(food_stub, VILLAGE_A), 8, "Um guarda faminto em casa comeu: 10 - 2.")
	assert_eq(module.peek_npc(npc_id).need_values[HUNGER], 35)
	world.teardown()


func test_the_stock_goes_into_the_save_and_comes_back_exactly() -> void:
	var food_stub: FoodStub = _stub()
	var module: NpcModule = _module(food_stub, 0, true)
	var world: World = _world(module)
	_spawn(module, "farmer")
	assert_true(module.request_set_food_stock(VILLAGE_A, 33).ok)
	assert_true(module.request_set_food_stock(VILLAGE_B, 0).ok)
	var saved: Dictionary = _json_round_trip(module.serialize())
	assert_eq(saved[FoodStub.SAVE_KEY], {VILLAGE_A: 33.0, VILLAGE_B: 0.0}, "O save traz o estoque por assentamento, em ordem.")
	var other_stub: FoodStub = _stub()
	var other: NpcModule = _module(other_stub)
	var other_world: World = _world(other)
	assert_true(other.on_load(saved).ok)
	assert_eq([_stock(other_stub, VILLAGE_A), _stock(other_stub, VILLAGE_B)], [33, 0], "O estoque voltou igual (inteiros, mesmo vindo de JSON).")
	assert_eq(other.serialize(), module.serialize(), "Ida e volta sem diferença.")
	assert_eq(module.debug_summary()["food_stock"], {VILLAGE_A: 33, VILLAGE_B: 0})
	var without_stock: Dictionary = saved.duplicate()
	without_stock.erase(FoodStub.SAVE_KEY)
	assert_true(other.on_load(without_stock).ok, "Save de antes do FoodStub (sem o trecho) carrega.")
	assert_eq([_stock(other_stub, VILLAGE_A), _stock(other_stub, VILLAGE_B)], [10, 3], "Sem o trecho o estoque volta ao inicial.")
	world.teardown()
	other_world.teardown()


func test_a_bad_stock_in_the_save_is_refused_and_leaves_everything_as_it_was() -> void:
	var food_stub: FoodStub = _stub()
	var module: NpcModule = _module(food_stub, 0, true)
	var world: World = _world(module)
	_spawn(module, "farmer")
	var good: Dictionary = module.serialize()
	var before: Dictionary = module.serialize()
	var broken_cases: Array[Dictionary] = [
		{"label": "negativo", "stock": {VILLAGE_A: -1, VILLAGE_B: 3}, "fragment": "fora de 0 a 50"},
		{"label": "acima do teto", "stock": {VILLAGE_A: 10, VILLAGE_B: 21}, "fragment": "fora de 0 a 20"},
		{"label": "com fração", "stock": {VILLAGE_A: 10.5, VILLAGE_B: 3}, "fragment": "não é um inteiro"},
		{"label": "texto", "stock": {VILLAGE_A: "dez", VILLAGE_B: 3}, "fragment": "não é um inteiro"},
		{"label": "assentamento sem regra", "stock": {VILLAGE_A: 10, VILLAGE_B: 3, "nowhere": 1}, "fragment": "'nowhere'"},
		{"label": "falta um assentamento", "stock": {VILLAGE_A: 10}, "fragment": "falta o estoque"},
		{"label": "não é objeto", "stock": [10, 3], "fragment": "não é um objeto"},
	]
	for row: Dictionary in broken_cases:
		var data: Dictionary = good.duplicate(true)
		data[FoodStub.SAVE_KEY] = row["stock"]
		var refused: Result = module.on_load(data)
		assert_false(refused.ok, "%s: deveria ser recusado." % row["label"])
		assert_eq(refused.code, NpcModule.CODE_INVALID_SAVE)
		assert_string_contains(refused.message, str(row["fragment"]))
		assert_eq(module.serialize(), before, "%s: o módulo ficou como estava." % row["label"])
	var plain: NpcModule = NpcModule.new()
	var plain_world: World = _world(plain)
	var no_stub: Result = plain.on_load(good)
	assert_false(no_stub.ok, "Módulo sem FoodStub não aceita estoque de comida.")
	assert_string_contains(no_stub.message, FoodStub.SAVE_KEY)
	world.teardown()
	plain_world.teardown()


func test_validate_reports_a_stock_outside_the_range() -> void:
	var food_stub: FoodStub = _stub()
	var module: NpcModule = _module(food_stub)
	var world: World = _world(module)
	assert_eq(module.validate().size(), 0)
	food_stub.load_save({VILLAGE_A: -4, VILLAGE_B: 99})
	var problems: Array[String] = module.validate()
	assert_eq(problems.size(), 2, str(problems))
	assert_string_contains(problems[0], "-4")
	assert_string_contains(problems[1], "99")
	world.teardown()


func test_set_food_stock_exists_only_in_development_builds_and_peek_reports_the_stock() -> void:
	var food_stub: FoodStub = _stub()
	var production: NpcModule = _module(food_stub, 0, false)
	var world: World = _world(production)
	var refused: Result = production.request_set_food_stock(VILLAGE_A, 0)
	assert_eq(refused.code, NpcModule.CODE_DEV_ONLY)
	assert_eq(_stock(food_stub, VILLAGE_A), 10, "Fora do desenvolvimento nada muda.")
	var development_stub: FoodStub = _stub()
	var development: NpcModule = _module(development_stub, 0, true)
	var development_world: World = _world(development)
	assert_true(development.request_set_food_stock(VILLAGE_A, 25).ok)
	var seen: FoodStub.StockQuery = development.peek_food_stock(VILLAGE_A)
	assert_true(seen.result.ok)
	assert_eq([seen.stock, seen.max_stock], [25, 50])
	assert_eq(development.request_set_food_stock(VILLAGE_A, 51).code, FoodStub.CODE_INVALID_AMOUNT)
	assert_eq(development.request_set_food_stock("nowhere", 1).code, FoodStub.CODE_UNKNOWN_SETTLEMENT)
	assert_eq(development.peek_food_stock("nowhere").result.code, FoodStub.CODE_UNKNOWN_SETTLEMENT)
	var plain: NpcModule = NpcModule.new()
	assert_eq(plain.peek_food_stock(VILLAGE_A).result.code, NpcModule.CODE_FOOD_NOT_CONFIGURED)
	assert_eq(plain.request_set_food_stock(VILLAGE_A, 1).code, NpcModule.CODE_DEV_ONLY, "Sem definições também não é desenvolvimento.")
	world.teardown()
	development_world.teardown()


func test_a_rule_naming_a_missing_settlement_or_occupation_turns_the_decisions_off_with_the_reason() -> void:
	var rules_for_nowhere: Array[FoodStub.FoodRule] = [FoodStub.FoodRule.new("nowhere", 1, 5, 1, "farmer", 1)]
	var rules_for_wizard: Array[FoodStub.FoodRule] = [FoodStub.FoodRule.new(VILLAGE_A, 1, 5, 1, "wizard", 1)]
	var cases: Array[Dictionary] = [{"rules": rules_for_nowhere, "fragment": "'nowhere'"}, {"rules": rules_for_wizard, "fragment": "'wizard'"}]
	for row: Dictionary in cases:
		var rules: Array[FoodStub.FoodRule] = row["rules"]
		var module: NpcModule = _module(FoodStub.new(rules))
		var world: World = _world(module)
		_spawn(module, "farmer")
		_run(world, 5)
		var summary: Dictionary = module.debug_summary()
		assert_false(summary["decision_enabled"])
		assert_string_contains(summary["decision_problem"], "TEMP-LW-065")
		assert_string_contains(summary["decision_problem"], str(row["fragment"]))
		world.teardown()


# ---------------------------------------------------------------------------------------------------- dado e marca

func _valid_record() -> Dictionary:
	return {
		"id": "food_a", "temp_mark": "TEMP-LW-065", "settlement_id": VILLAGE_A, "start_stock": 10, "max_stock": 50, "eat_cost": 2,
		"yield_occupation_id": "farmer", "work_yield": 7,
	}


func _load_records(records: Array[Dictionary]) -> FoodStubLoader.LoadResult:
	var bundle: DataBundle = DataBundle.new()
	bundle.tables[FoodStubLoader.FOOD_TABLE] = records
	bundle.file_paths[FoodStubLoader.FOOD_TABLE] = FILE_LABEL
	DataValidator.new().validate(bundle, [FoodStubLoader.build_schema()])
	return FoodStubLoader.from_bundle(bundle)


func _expect_failure(label: String, records: Array[Dictionary], fragments: Array[String]) -> void:
	var loaded: FoodStubLoader.LoadResult = _load_records(records)
	assert_false(loaded.result.ok, "%s: deveria falhar." % label)
	assert_eq(loaded.result.code, ISSUE_CODE, label)
	assert_null(loaded.stub, "%s: falha não devolve estoque." % label)
	for fragment: String in fragments:
		assert_string_contains(loaded.result.message, fragment, "%s: a mensagem deveria citar '%s'." % [label, fragment])


func test_the_real_file_loads_and_every_row_carries_the_temp_mark_and_real_references() -> void:
	var loaded: FoodStubLoader.LoadResult = FoodStubLoader.load_dir()
	assert_true(loaded.result.ok, loaded.result.message)
	var rows: Array = _read_json_rows("res://data/food_stub.json")
	assert_gt(rows.size(), 0)
	var settlement_ids: Array = _ids_of(_read_json_rows("res://data/world/settlements.json"))
	var occupation_ids: Array = _ids_of(_read_json_rows("res://data/occupations.json"))
	for row: Variant in rows:
		var record: Dictionary = row
		assert_eq(record.get("temp_mark"), "TEMP-LW-065", "Linha '%s': a marca TEMP-LW-065 é obrigatória." % record.get("id"))
		assert_true(settlement_ids.has(record.get("settlement_id")), "Linha '%s': o assentamento existe em data/world/settlements.json." % record.get("id"))
		assert_true(occupation_ids.has(record.get("yield_occupation_id")), "Linha '%s': o ofício existe em data/occupations.json." % record.get("id"))
		assert_true(loaded.stub.has_food(str(record.get("settlement_id"))), "Linha '%s': o estoque inicial dá ao menos uma refeição." % record.get("id"))
	assert_eq(loaded.stub.settlement_ids().size(), rows.size())


func _read_json_rows(path: String) -> Array:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert_eq(typeof(parsed), TYPE_ARRAY, "%s deve ser uma lista." % path)
	var rows: Array = parsed if typeof(parsed) == TYPE_ARRAY else []
	return rows


func _ids_of(rows: Array) -> Array:
	var ids: Array = []
	for row: Variant in rows:
		var record: Dictionary = row
		ids.append(record.get("id"))
	return ids


func test_the_in_memory_path_builds_the_rules_from_the_rows() -> void:
	var second: Dictionary = _valid_record()
	second["id"] = "food_b"
	second["settlement_id"] = VILLAGE_B
	second["start_stock"] = 3
	second["max_stock"] = 20
	second["eat_cost"] = 3
	second["work_yield"] = 4
	var loaded: FoodStubLoader.LoadResult = _load_records([_valid_record(), second])
	assert_true(loaded.result.ok, loaded.result.message)
	assert_eq([_stock(loaded.stub, VILLAGE_A), _stock(loaded.stub, VILLAGE_B)], [10, 3])
	assert_eq(loaded.stub.peek_stock(VILLAGE_B).max_stock, 20)
	var expected_ids: Array[String] = [VILLAGE_A, VILLAGE_B]
	assert_eq(loaded.stub.settlement_ids(), expected_ids, "Os assentamentos saem em ordem alfabética.")


func test_invalid_data_fails_pointing_at_file_item_and_field() -> void:
	for field: String in ["temp_mark", "settlement_id", "start_stock", "max_stock", "eat_cost", "yield_occupation_id", "work_yield"]:
		var missing: Dictionary = _valid_record()
		missing.erase(field)
		_expect_failure("%s ausente" % field, [missing], [FILE_LABEL, "item 'food_a'", "campo '%s'" % field, "obrigatório ausente"])
	var wrong_mark: Dictionary = _valid_record()
	wrong_mark["temp_mark"] = "TEMP-LW-066"
	_expect_failure("marca errada", [wrong_mark], [FILE_LABEL, "campo 'temp_mark'", "esperado exatamente 'TEMP-LW-065'"])
	var empty_mark: Dictionary = _valid_record()
	empty_mark["temp_mark"] = ""
	_expect_failure("marca vazia", [empty_mark], [FILE_LABEL, "campo 'temp_mark'"])
	var above_ceiling: Dictionary = _valid_record()
	above_ceiling["start_stock"] = 51
	_expect_failure("estoque inicial acima do teto", [above_ceiling], [FILE_LABEL, "campo 'start_stock'", "passa do teto max_stock = 50"])
	var free_meal: Dictionary = _valid_record()
	free_meal["eat_cost"] = 0
	_expect_failure("refeição de graça", [free_meal], [FILE_LABEL, "campo 'eat_cost'", "abaixo do mínimo"])
	var huge_meal: Dictionary = _valid_record()
	huge_meal["eat_cost"] = 60
	_expect_failure("refeição maior que o teto", [huge_meal], [FILE_LABEL, "campo 'eat_cost'", "passa do teto"])
	var huge_yield: Dictionary = _valid_record()
	huge_yield["work_yield"] = 51
	_expect_failure("colheita maior que o teto", [huge_yield], [FILE_LABEL, "campo 'work_yield'", "passa do teto"])
	var no_settlement: Dictionary = _valid_record()
	no_settlement["settlement_id"] = ""
	_expect_failure("assentamento vazio", [no_settlement], [FILE_LABEL, "campo 'settlement_id'", "não pode ficar vazio"])
	var no_occupation: Dictionary = _valid_record()
	no_occupation["yield_occupation_id"] = ""
	_expect_failure("ofício vazio", [no_occupation], [FILE_LABEL, "campo 'yield_occupation_id'", "não pode ficar vazio"])
	var as_text: Dictionary = _valid_record()
	as_text["max_stock"] = "50"
	_expect_failure("teto como texto", [as_text], [FILE_LABEL, "campo 'max_stock'", "tipo inválido"])
	var unknown: Dictionary = _valid_record()
	unknown["price"] = 3
	_expect_failure("campo desconhecido (dinheiro não existe aqui)", [unknown], [FILE_LABEL, "campo 'price'", "campo desconhecido"])
	var twin: Dictionary = _valid_record()
	twin["id"] = "food_twin"
	_expect_failure("dois estoques para o mesmo assentamento", [_valid_record(), twin], [FILE_LABEL, "item 'food_twin'", "campo 'settlement_id'", "já tem regra na linha 'food_a'"])
	_expect_failure("nenhuma linha", [], [FILE_LABEL, "esperada ao menos 1 linha"])


func test_a_missing_file_fails_pointing_at_the_file() -> void:
	var loaded: FoodStubLoader.LoadResult = FoodStubLoader.load_dir("res://tests/fixtures/data/ok")
	assert_false(loaded.result.ok)
	assert_eq(loaded.result.code, ISSUE_CODE)
	assert_string_contains(loaded.result.message, "food_stub.json")
	assert_string_contains(loaded.result.message, "arquivo não encontrado")


func test_the_temp_mark_is_in_every_file_of_the_stub_and_in_the_docs_and_the_wiring() -> void:
	var files: PackedStringArray = DirAccess.get_files_at(FOOD_DIR)
	var scripts: Array[String] = []
	for file_name: String in files:
		if file_name.ends_with(".gd"):
			scripts.append(file_name)
	assert_gte(scripts.size(), 2, "A pasta do provisório tem o estoque e o carregador.")
	for file_name: String in scripts:
		assert_string_contains(FileAccess.get_file_as_string(FOOD_DIR.path_join(file_name)), FoodStub.TEMP_MARK, "%s precisa da marca %s." % [file_name, FoodStub.TEMP_MARK])
	assert_string_contains(FileAccess.get_file_as_string("res://docs/modules/npc.md"), FoodStub.TEMP_MARK, "A marca também está nos documentos.")
	assert_string_contains(FileAccess.get_file_as_string("res://src/sim/npc/api/npc_module.gd"), FoodStub.TEMP_MARK, "As linhas do módulo que ligam o FoodStub levam a marca (a LW-094 as acha por ela).")
	assert_string_contains(FileAccess.get_file_as_string("res://data/food_stub.json"), FoodStub.TEMP_MARK)
