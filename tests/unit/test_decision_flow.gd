extends GutTest
## LW-063: fluxo de decisão do NPC (docs/modules/npc.md, seção 5; arquitetura 9.7), sem janela. Mundo de teste montado à mão (catálogo, rotina,
## locais, parâmetros e provedor de comida falso) para os números serem calculados na mão: faminto com comida come; sem comida não tenta;
## sem urgência segue a rotina da hora (anda até o trabalho e trabalha); a fome interrompe o sono com efeito proporcional; o sorteio usa o
## fluxo `npc.decision` e a mesma semente dá o mesmo resultado; salvar e carregar no meio não muda nada; definições incompletas desligam o
## fluxo sem quebrar nada. As propriedades dos dados reais [HIP] não são fixadas aqui.

const VILLAGE: String = "village_a"
const HOME: String = "home_a1"
const WORK: String = "work_a1"
const NEED_IDS: Array[String] = ["hunger", "rest", "safety", "income", "social"]
const TRAIT_IDS: Array[String] = ["caution", "sociability", "ambition", "loyalty"]
const HUNGER: int = 0
const REST: int = 1
const HOME_X_CM: int = 8400
const WORK_X_M: float = 184.0
const WORK_X_CM: int = 18400
## Trabalho a 2 km: a caminhada de/para casa dura 23 minutos, mais que o intervalo de pensamento.
const FAR_WORK_X_M: float = 2000.0
const FAR_WORK_X_CM: int = 200000
const THINK_INTERVAL: int = 10


## Provedor de comida de teste.
class FakeFood:
	extends ActionConditionProvider

	var food: bool = true

	func has_food(_settlement_id: String) -> bool:
		return food


func _need_defs(start_values: Array[int], rates: Array[int]) -> Array[NeedDef]:
	var defs: Array[NeedDef] = []
	for position: int in NEED_IDS.size():
		defs.append(NeedDef.new(NEED_IDS[position], position, start_values[position], rates[position], 40, 65, 90))
	return defs


## Pesos de urgência 0, 1, 3, 6; 2 pontos por hora, 2 por 100 m, risco a 100%; inércia 25; rotina 40; pensa a cada 10 min, no máximo 20 por passo.
func _params(max_thinks: int = 20) -> NpcParams:
	var params: NpcParams = NpcParams.new()
	params.urgency_weight_attention = 1
	params.urgency_weight_urgent = 3
	params.urgency_weight_critical = 6
	params.time_cost_per_hour = 2
	params.distance_cost_per_100m = 2
	params.risk_cost_percent = 100
	params.inertia_bonus = 25
	params.routine_bonus = 40
	params.think_interval_min = THINK_INTERVAL
	params.max_thinks_per_step = max_thinks
	params.decision_top_k = 3
	params.decision_margin = 15
	return params


func _action(action_id: String, duration: int, place_kind: String, risk: int = 0) -> ActionDef:
	return ActionDef.new(action_id, duration, place_kind, risk, true)


func _catalog(with_snack: bool = false) -> Array[ActionDef]:
	var eat: ActionDef = _action("eat", 20, "home")
	eat.effects.append(ActionDef.ActionEffect.new("hunger", -60))
	eat.conditions.append(ActionDef.ActionCondition.new(ActionDef.CONDITION_HAS_FOOD, "", ActionDef.ABSENT, ActionDef.ABSENT))
	var sleep: ActionDef = _action("sleep", 480, "home")
	sleep.effects.append(ActionDef.ActionEffect.new("rest", -100))
	var work: ActionDef = _action("work", 240, "work", 5)
	work.effects.append(ActionDef.ActionEffect.new("rest", 5))
	var catalog: Array[ActionDef] = [eat, sleep, work, _action("wait", 10, ""), _action(ActionRunner.GO_TO_PLACE_ID, 0, "")]
	if with_snack:
		var snack: ActionDef = _action("snack", 5, "")
		snack.effects.append(ActionDef.ActionEffect.new("hunger", -60))
		catalog.append(snack)
	return catalog


## Ofício "tester": das 0h às 12h faz `first_half`, das 12h às 24h faz `second_half`.
func _routine(first_half: String, second_half: String) -> RoutineTable:
	var occupations: Array[RoutineTable.OccupationDef] = [RoutineTable.OccupationDef.new("tester", "work")]
	var blocks: Array[RoutineTable.RoutineBlock] = [
		RoutineTable.RoutineBlock.new("t1", "tester", 0, 12, first_half), RoutineTable.RoutineBlock.new("t2", "tester", 12, 24, second_half),
	]
	return RoutineTable.new(occupations, blocks)


func _places(work_x_m: float = WORK_X_M) -> SettlementService:
	var settlements: Array[Settlement] = [Settlement.new(VILLAGE, "settlement.a", Vector3(0.0, 0.0, 0.0))]
	var places: Array[Place] = [
		Place.new(HOME, VILLAGE, Place.KIND_HOME, Vector3(HOME_X_CM / 100.0, 0.0, 0.0), 5),
		Place.new(WORK, VILLAGE, Place.KIND_WORK, Vector3(work_x_m, 0.0, 0.0), 5),
	]
	return SettlementService.new(settlements, places)


func _definitions(food: ActionConditionProvider, with_snack: bool = false, max_thinks: int = 20, work_x_m: float = WORK_X_M) -> NpcModule.Definitions:
	var definitions: NpcModule.Definitions = NpcModule.Definitions.new()
	definitions.actions = _catalog(with_snack)
	var traits: Array[TraitLoader.TraitDef] = []
	for position: int in TRAIT_IDS.size():
		traits.append(TraitLoader.TraitDef.new(TRAIT_IDS[position], position))
	definitions.traits = traits
	definitions.params = _params(max_thinks)
	definitions.places = _places(work_x_m)
	definitions.food = food
	return definitions


func _module(start_values: Array[int], rates: Array[int], first_half: String, food: ActionConditionProvider, with_snack: bool = false, max_thinks: int = 20, work_x_m: float = WORK_X_M) -> NpcModule:
	return NpcModule.new(_need_defs(start_values, rates), _routine(first_half, first_half), _definitions(food, with_snack, max_thinks, work_x_m))


func _world(module: NpcModule, world_seed: int = 3) -> World:
	var clock: SimClock = SimClock.new()
	var world: World = World.new(SimContext.new(clock, EventBus.new(clock), WorldRng.new(world_seed), IdGenerator.new()))
	assert_true(world.register_module("npc", module).ok)
	world.setup()
	world.post_setup()
	return world


## NPC do ofício "tester", em casa (ou, com `at_far_work`, no trabalho distante de FAR_WORK_X_M).
func _spawn(module: NpcModule, at_far_work: bool = false) -> int:
	var spec: NpcSpec = NpcSpec.new()
	spec.name_key = "npc.name.villager"
	spec.occupation_id = "tester"
	spec.settlement_id = VILLAGE
	spec.place_id = WORK if at_far_work else HOME
	spec.home_place_id = HOME
	spec.work_place_id = WORK
	spec.x_cm = FAR_WORK_X_CM if at_far_work else HOME_X_CM
	var created: NpcModule.CreateResult = module.request_create_npc(spec)
	assert_true(created.result.ok, created.result.message)
	return created.npc_id


## Minuto do primeiro pensamento de um NPC criado no minuto 0: 1 mais o resto da divisão do id pelo intervalo (a fase fixa dele).
func _first_think(npc_id: int) -> int:
	return 1 + npc_id % THINK_INTERVAL


## Avança o relógio um minuto por vez e roda os módulos (como o SimulationRunner faz a cada passo).
func _run(world: World, minutes: int) -> void:
	for _step: int in minutes:
		world.context.clock.advance_step()
		world.tick(1)


func _json_round_trip(data: Dictionary) -> Dictionary:
	var parsed: Variant = JSON.parse_string(JSON.stringify(data, "", true, true))
	var restored: Dictionary = parsed
	return restored


# ---------------------------------------------------------------------------------------------------- urgência e rotina

func test_a_hungry_npc_with_food_available_eats() -> void:
	var module: NpcModule = _module([95, 0, 0, 0, 0], [0, 0, 0, 0, 0], "work", FakeFood.new())
	var world: World = _world(module)
	var npc_id: int = _spawn(module)
	assert_eq(module.debug_summary()["decision_problem"], "", "Definições completas: o módulo decide.")
	assert_true(module.debug_summary()["decision_enabled"])
	assert_eq(module.peek_npc(npc_id).action_id, "", "Antes de pensar o NPC não faz nada.")
	var first_think: int = _first_think(npc_id)
	_run(world, first_think)
	var eating: NpcModule.NpcQuery = module.peek_npc(npc_id)
	assert_eq(eating.action_id, "eat", "Fome crítica e comida disponível: come.")
	assert_eq(eating.action_target_place_id, HOME)
	assert_eq([eating.action_started_at, eating.action_ends_at], [first_think, first_think + 20], "Já estava em casa: começa na hora, 20 minutos.")
	_run(world, 19)
	assert_eq(module.peek_npc(npc_id).need_values[HUNGER], 95, "A refeição só tem efeito quando termina.")
	_run(world, 1)
	var after: NpcModule.NpcQuery = module.peek_npc(npc_id)
	assert_eq(after.need_values[HUNGER], 35, "95 menos os 60 da refeição.")
	assert_eq(after.action_id, ActionRunner.GO_TO_PLACE_ID, "Sem urgência, no minuto seguinte a rotina (trabalhar) manda: primeiro vai até o trabalho.")
	assert_eq(after.action_target_place_id, WORK)
	world.teardown()


func test_without_food_the_hungry_npc_never_starts_eating_and_follows_the_routine_instead() -> void:
	var food: FakeFood = FakeFood.new()
	food.food = false
	var module: NpcModule = _module([95, 0, 0, 0, 0], [0, 0, 0, 0, 0], "work", food)
	var world: World = _world(module)
	var npc_id: int = _spawn(module)
	var first_think: int = _first_think(npc_id)
	_run(world, first_think)
	var walking: NpcModule.NpcQuery = module.peek_npc(npc_id)
	assert_eq(walking.action_id, ActionRunner.GO_TO_PLACE_ID, "Fome crítica, mas a ação que alivia não pode começar: vale a rotina (trabalhar), em outro lugar.")
	assert_eq(walking.action_target_place_id, WORK)
	for minute: int in 25:
		_run(world, 1)
		assert_ne(module.peek_npc(npc_id).action_id, "eat", "Minuto %d: sem comida nenhuma ação que exija comida é escolhida." % (first_think + minute + 1))
	assert_eq(module.peek_npc(npc_id).action_id, "work", "Quem não tem como aliviar a fome continua trabalhando (é o trabalho do agricultor que repõe a comida).")
	food.food = true
	var started_eating: bool = false
	for _minute: int in 25:
		_run(world, 1)
		if module.peek_npc(npc_id).action_id == "eat":
			started_eating = true
			break
	assert_true(started_eating, "Quando a comida aparece, no pensamento seguinte ele deixa o trabalho, volta para casa e come.")
	world.teardown()


func test_a_walk_longer_than_the_think_interval_is_not_restarted_by_the_next_thoughts() -> void:
	var module: NpcModule = _module([95, 0, 0, 0, 0], [0, 0, 0, 0, 0], "work", FakeFood.new(), false, 20, FAR_WORK_X_M)
	var world: World = _world(module)
	var npc_id: int = _spawn(module, true)
	var first_think: int = _first_think(npc_id)
	_run(world, first_think)
	var walking: NpcModule.NpcQuery = module.peek_npc(npc_id)
	assert_eq([walking.action_id, walking.action_target_place_id], [ActionRunner.GO_TO_PLACE_ID, HOME], "Faminto no trabalho distante: vai para casa comer.")
	assert_eq([walking.action_ends_at, walking.action_serial], [first_think + 23, 1], "1.916 m a 84 m por minuto: 23 minutos.")
	_run(world, 10)
	var later: NpcModule.NpcQuery = module.peek_npc(npc_id)
	assert_eq([later.action_id, later.action_ends_at, later.action_serial], [ActionRunner.GO_TO_PLACE_ID, first_think + 23, 1], "Pensou no meio da caminhada, escolheu a mesma refeição e NÃO recomeçou a caminhada.")
	_run(world, 13)
	var eating: NpcModule.NpcQuery = module.peek_npc(npc_id)
	assert_eq([eating.action_id, eating.place_id, eating.x_cm], ["eat", HOME, HOME_X_CM], "Chegou em casa no minuto %d e começou a comer." % (first_think + 23))
	world.teardown()


func test_without_urgency_the_npc_follows_the_routine_of_the_hour_walking_to_work_first() -> void:
	var module: NpcModule = _module([0, 0, 0, 0, 0], [0, 0, 0, 0, 0], "work", FakeFood.new())
	var world: World = _world(module)
	var npc_id: int = _spawn(module)
	var first_think: int = _first_think(npc_id)
	_run(world, first_think)
	var walking: NpcModule.NpcQuery = module.peek_npc(npc_id)
	assert_eq(walking.action_id, ActionRunner.GO_TO_PLACE_ID, "A rotina das 0h é trabalhar, mas o trabalho é em outro lugar: primeiro anda.")
	assert_eq(walking.action_target_place_id, WORK)
	assert_eq(walking.action_ends_at, first_think + 2, "100 m a 84 m por minuto: 2 minutos.")
	assert_eq(walking.next_think_time, first_think + 2, "Volta a pensar quando a caminhada acaba, não só daqui a 10 minutos.")
	_run(world, 2)
	var working: NpcModule.NpcQuery = module.peek_npc(npc_id)
	assert_eq(working.action_id, "work", "Chegou: trabalha.")
	assert_eq([working.place_id, working.x_cm], [WORK, WORK_X_CM])
	assert_eq(working.action_ends_at, first_think + 2 + 240)
	world.teardown()


func test_an_npc_without_an_occupation_has_no_routine_and_waits() -> void:
	var module: NpcModule = _module([0, 0, 0, 0, 0], [0, 0, 0, 0, 0], "work", FakeFood.new())
	var world: World = _world(module)
	var spec: NpcSpec = NpcSpec.new()
	spec.name_key = "npc.name.villager"
	spec.settlement_id = VILLAGE
	var npc_id: int = module.request_create_npc(spec).npc_id
	_run(world, _first_think(npc_id))
	assert_eq(module.peek_npc(npc_id).action_id, "wait")
	world.teardown()


# ---------------------------------------------------------------------------------------------------- inércia e interrupção

func test_hunger_interrupts_sleep_with_the_effect_proportional_to_the_time_slept() -> void:
	var module: NpcModule = _module([30, 50, 0, 0, 0], [30, 0, 0, 0, 0], "sleep", FakeFood.new())
	var world: World = _world(module)
	var npc_id: int = _spawn(module)
	var first_think: int = _first_think(npc_id)
	assert_eq(first_think, 2, "O primeiro NPC do mundo tem id 1: fase 1, primeiro pensamento no minuto 2 (os números abaixo contam com isso).")
	_run(world, first_think)
	assert_eq(module.peek_npc(npc_id).action_id, "sleep", "Rotina das 0h: dormir (480 minutos, a partir do minuto 2).")
	_run(world, 68)
	var still_asleep: NpcModule.NpcQuery = module.peek_npc(npc_id)
	assert_eq(still_asleep.action_id, "sleep", "Minuto 70: o último pensamento foi o do minuto 62 (fome 61, só atenção) e o próximo é o 72.")
	assert_eq(still_asleep.need_values[REST], 50, "O sono só tem efeito quando termina ou é interrompido.")
	_run(world, 2)
	var awake: NpcModule.NpcQuery = module.peek_npc(npc_id)
	assert_eq(awake.action_id, "eat", "Minuto 72: a fome chega a 66 (urgente); comer (180 pontos) vence continuar dormindo (99): interrompe o sono.")
	assert_eq(awake.need_values[HUNGER], 66)
	assert_eq(awake.need_values[REST], 35, "Dormiu 70 de 480 minutos: progresso 145 de 1000, efeito piso de -100 x 145 / 1000 = -15.")
	assert_eq(awake.action_serial, 2, "Dormir (1) e comer (2): interromper uma ação não conta como começar outra.")
	world.teardown()


func test_inertia_keeps_the_current_action_while_nothing_better_appears() -> void:
	var module: NpcModule = _module([0, 0, 0, 0, 0], [0, 0, 0, 0, 0], "sleep", FakeFood.new())
	var world: World = _world(module)
	var npc_id: int = _spawn(module)
	_run(world, _first_think(npc_id))
	var serial: int = module.peek_npc(npc_id).action_serial
	_run(world, 120)
	var later: NpcModule.NpcQuery = module.peek_npc(npc_id)
	assert_eq(later.action_id, "sleep")
	assert_eq(later.action_serial, serial, "Pensou a cada 10 minutos e nunca trocou de ação.")
	world.teardown()


# ---------------------------------------------------------------------------------------------------- sorteio com semente

## A PRIMEIRA ação de cada um dos 20 NPCs famintos (em ordem de id), anotada no passo em que aparece (cada um pensa uma vez a cada 10
## minutos, com fase própria, então em 10 passos todos já escolheram).
func _first_choices(world_seed: int) -> Array[String]:
	var module: NpcModule = _module([95, 0, 0, 0, 0], [0, 0, 0, 0, 0], "work", FakeFood.new(), true)
	var world: World = _world(module, world_seed)
	var ids: Array[int] = []
	var first_action: Dictionary[int, String] = {}
	for _index: int in 20:
		ids.append(_spawn(module))
	for _step: int in 10:
		_run(world, 1)
		for npc_id: int in ids:
			var action_id: String = module.peek_npc(npc_id).action_id
			if not action_id.is_empty() and not first_action.has(npc_id):
				first_action[npc_id] = action_id
	var chosen: Array[String] = []
	for npc_id: int in ids:
		chosen.append(first_action.get(npc_id, ""))
	var streams: Dictionary = world.context.rng.serialize()["streams"]
	assert_true(streams.has("npc.decision"), "O sorteio usa o fluxo `npc.decision` do ctx.rng.")
	world.teardown()
	return chosen


func test_the_weighted_draw_uses_the_seed_and_the_same_seed_gives_the_same_choices() -> void:
	var first: Array[String] = _first_choices(1)
	var again: Array[String] = _first_choices(1)
	var other: Array[String] = _first_choices(2)
	assert_eq(first, again, "Mesma semente, mesmas escolhas.")
	assert_ne(first, other, "Outra semente, outro sorteio entre as duas opções empatadas.")
	assert_true(first.has("eat") and first.has("snack"), "As duas candidatas empatadas aparecem no sorteio.")
	for choice: String in first:
		assert_true(choice == "eat" or choice == "snack", "Só as ações que aliviam a fome entram (veio '%s')." % choice)


## Dados de todos os NPCs (serialize do módulo) de um mundo com a semente dada, depois de `minutes` minutos de simulação.
func _npc_data_after(world_seed: int, minutes: int) -> Dictionary:
	var module: NpcModule = _module([95, 0, 0, 0, 0], [3, 2, 0, 0, 1], "work", FakeFood.new(), true)
	var world: World = _world(module, world_seed)
	for _index: int in 12:
		_spawn(module)
	_run(world, minutes)
	var data: Dictionary = module.serialize()
	world.teardown()
	return data


func test_the_same_seed_gives_the_same_npcs_and_another_seed_gives_other_choices() -> void:
	var first: Dictionary = _npc_data_after(5, 300)
	assert_eq(_npc_data_after(5, 300), first, "Mesma semente, mesmos NPCs depois de 300 minutos.")
	assert_ne(_npc_data_after(6, 300), first, "Outra semente muda o sorteio entre as ações empatadas (comer ou lanchar).")


func test_saving_and_loading_in_the_middle_changes_nothing_even_for_a_module_that_already_ran() -> void:
	var module: NpcModule = _module([95, 0, 0, 0, 0], [3, 2, 0, 0, 1], "work", FakeFood.new(), true)
	var world: World = _world(module, 7)
	for _index: int in 8:
		_spawn(module)
	_run(world, 25)
	var saved: Dictionary = _json_round_trip(world.serialize())
	var hash_mid: String = world.state_hash()
	_run(world, 60)
	var hash_end: String = world.state_hash()
	var fresh_module: NpcModule = _module([95, 0, 0, 0, 0], [3, 2, 0, 0, 1], "work", FakeFood.new(), true)
	var fresh: World = _world(fresh_module, 7)
	var loaded: Result = fresh.on_load(saved)
	assert_true(loaded.ok, loaded.message)
	assert_eq(fresh.state_hash(), hash_mid, "O mundo carregado tem o hash do momento do salvamento.")
	_run(fresh, 60)
	assert_eq(fresh.state_hash(), hash_end, "Carregar e continuar dá o mesmo que continuar direto.")
	var rewound: Result = world.on_load(saved)
	assert_true(rewound.ok, rewound.message)
	assert_eq(world.state_hash(), hash_mid)
	_run(world, 60)
	assert_eq(world.state_hash(), hash_end, "O módulo que já tinha rodado enxerga a tabela recarregada (a tabela é atualizada no lugar).")
	assert_eq(world.validate().size(), 0, str(world.validate()))
	world.teardown()
	fresh.teardown()


func test_next_think_time_survives_the_save_and_a_save_without_it_loads_as_zero() -> void:
	var module: NpcModule = _module([0, 0, 0, 0, 0], [0, 0, 0, 0, 0], "work", FakeFood.new())
	var world: World = _world(module)
	var npc_id: int = _spawn(module)
	_run(world, _first_think(npc_id))
	var thought_at: int = module.peek_npc(npc_id).next_think_time
	assert_gt(thought_at, _first_think(npc_id), "Depois de pensar, o próximo pensamento é agendado para depois.")
	var saved: Dictionary = _json_round_trip(module.serialize())
	var other: NpcModule = NpcModule.new()
	assert_true(other.on_load(saved).ok)
	assert_eq(other.peek_npc(npc_id).next_think_time, thought_at)
	var without: Dictionary = saved["npcs"][str(npc_id)]
	without.erase("next_think_time")
	assert_true(other.on_load({"npcs": {str(npc_id): without}}).ok, "Save sem o campo novo carrega.")
	assert_eq(other.peek_npc(npc_id).next_think_time, 0, "Sem o campo: pensa no primeiro passo.")
	var broken: Dictionary = without.duplicate()
	broken["next_think_time"] = "amanhã"
	var refused: Result = other.on_load({"npcs": {str(npc_id): broken}})
	assert_false(refused.ok)
	assert_string_contains(refused.message, "next_think_time")
	world.teardown()


# ---------------------------------------------------------------------------------------------------- definições incompletas

func test_incomplete_definitions_turn_the_flow_off_without_breaking_anything() -> void:
	var complete: NpcModule.Definitions = _definitions(FakeFood.new())
	var no_params: NpcModule.Definitions = _definitions(null)
	no_params.params = null
	var no_places: NpcModule.Definitions = _definitions(null)
	no_places.places = null
	var no_actions: NpcModule.Definitions = _definitions(null)
	no_actions.actions = []
	var modules: Array[NpcModule] = [
		NpcModule.new(_need_defs([0, 0, 0, 0, 0], [0, 0, 0, 0, 0]), _routine("work", "work"), null),
		NpcModule.new(_need_defs([0, 0, 0, 0, 0], [0, 0, 0, 0, 0]), _routine("work", "work"), no_params),
		NpcModule.new(_need_defs([0, 0, 0, 0, 0], [0, 0, 0, 0, 0]), _routine("work", "work"), no_places),
		NpcModule.new(_need_defs([0, 0, 0, 0, 0], [0, 0, 0, 0, 0]), _routine("work", "work"), no_actions),
		NpcModule.new([], _routine("work", "work"), complete),
		NpcModule.new(_need_defs([0, 0, 0, 0, 0], [0, 0, 0, 0, 0]), null, complete),
	]
	var fragments: Array[String] = ["sem as definições", "parâmetros", "serviço de locais", "catálogo", "necessidades", "tabela de rotina"]
	for index: int in modules.size():
		var world: World = _world(modules[index])
		var npc_id: int = _spawn(modules[index])
		var before: Dictionary = modules[index].serialize()
		_run(world, 15)
		var summary: Dictionary = modules[index].debug_summary()
		assert_false(summary["decision_enabled"], "Caso %d." % index)
		assert_string_contains(summary["decision_problem"], fragments[index], "Caso %d." % index)
		assert_eq(modules[index].serialize(), before, "Caso %d: sem decidir, o tick não muda nada." % index)
		assert_eq(modules[index].peek_npc(npc_id).action_id, "")
		world.teardown()


func test_a_dead_npc_never_thinks_and_a_living_one_next_to_it_still_does() -> void:
	var module: NpcModule = _module([0, 0, 0, 0, 0], [0, 0, 0, 0, 0], "work", FakeFood.new())
	var world: World = _world(module)
	var dead_id: int = _spawn(module)
	var alive_id: int = _spawn(module)
	var saved: Dictionary = _json_round_trip(module.serialize())
	var entry: Dictionary = saved["npcs"][str(dead_id)]
	entry["is_alive"] = false
	entry["death_cause"] = "hunger"
	entry["died_at"] = 0
	assert_true(module.on_load(saved).ok)
	var before: Dictionary = module.serialize()["npcs"][str(dead_id)]
	_run(world, 30)
	var dead: NpcModule.NpcQuery = module.peek_npc(dead_id)
	assert_false(dead.is_alive)
	assert_eq(dead.action_id, "")
	assert_eq(dead.action_serial, 0, "Morto não pensa nem começa ação.")
	assert_eq(module.serialize()["npcs"][str(dead_id)], before, "O registro do morto não mudou em 30 passos.")
	assert_ne(module.peek_npc(alive_id).action_id, "", "O vivo ao lado pensou e agiu.")
	world.teardown()


# ---------------------------------------------------------------------------------------------------- runner: peek_blocker e interrupt

## Runner solto, sem módulo: um NPC em casa (descanso 80, fome 80), necessidades paradas (taxa 0) salvo se `rates` disser outra coisa.
class RunnerParts:
	extends RefCounted

	var runner: ActionRunner
	var state: NpcState
	var food: FakeFood


func _runner_parts(rates: Array[int] = [0, 0, 0, 0, 0]) -> RunnerParts:
	var states: Dictionary[int, NpcState] = {}
	var parts: RunnerParts = RunnerParts.new()
	parts.state = NpcState.new(1)
	parts.state.need_values = PackedInt64Array([80, 80, 0, 0, 0])
	parts.state.settlement_id = VILLAGE
	parts.state.place_id = HOME
	parts.state.x_cm = HOME_X_CM
	states[1] = parts.state
	parts.food = FakeFood.new()
	parts.runner = ActionRunner.new(states, _catalog(), _need_defs([0, 0, 0, 0, 0], rates), _places(), parts.food)
	assert_eq(parts.runner.peek_problem(), "")
	return parts


func test_peek_blocker_agrees_with_begin_and_changes_nothing() -> void:
	var rows: Array[Dictionary] = [
		{"action": "eat", "place": HOME, "food": true, "can_start": true},
		{"action": "eat", "place": HOME, "food": false, "can_start": false},
		{"action": "ghost", "place": HOME, "food": true, "can_start": false},
		{"action": "work", "place": WORK, "food": true, "can_start": true},
		{"action": ActionRunner.GO_TO_PLACE_ID, "place": WORK, "food": true, "can_start": true},
		{"action": ActionRunner.GO_TO_PLACE_ID, "place": "nowhere", "food": true, "can_start": false},
	]
	for row: Dictionary in rows:
		var action_id: String = row["action"]
		var place_id: String = row["place"]
		var can_start: bool = row["can_start"]
		var parts: RunnerParts = _runner_parts()
		parts.food.food = row["food"]
		var before: Dictionary = parts.state.to_dict()
		var blocker: String = parts.runner.peek_blocker(1, action_id, place_id, 5)
		assert_eq(parts.state.to_dict(), before, "peek_blocker não altera o estado (%s)." % action_id)
		assert_eq(blocker.is_empty(), can_start, "peek_blocker de %s em %s: '%s'." % [action_id, place_id, blocker])
		assert_eq(parts.runner.begin(1, action_id, place_id, 5).ok, can_start, "begin de %s concorda com peek_blocker." % action_id)


func test_peek_blocker_reports_busy_dead_unknown_and_time_going_back_and_can_ignore_busy() -> void:
	var parts: RunnerParts = _runner_parts()
	var runner: ActionRunner = parts.runner
	var state: NpcState = parts.state
	assert_eq(runner.peek_blocker(1, "wait", HOME, 5), "")
	assert_true(runner.begin(1, "wait", HOME, 5).ok)
	assert_string_contains(runner.peek_blocker(1, "work", WORK, 6), "já está na ação 'wait'")
	assert_eq(runner.peek_blocker(1, "work", WORK, 6, true), "", "Com ignore_busy a troca de ação pode ser avaliada.")
	assert_string_contains(runner.peek_blocker(99, "wait", HOME, 6), "99")
	state.is_alive = false
	assert_string_contains(runner.peek_blocker(1, "wait", HOME, 6, true), "morto")
	state.is_alive = true
	assert_string_contains(runner.peek_blocker(1, "wait", HOME, 4, true), "anterior")


func test_interrupt_applies_the_proportional_effect_and_never_the_full_one() -> void:
	# Dormir 480 minutos (efeito -100 no descanso, que está em 80): minutos já dormidos -> descanso esperado. O progresso é
	# floor(minutos x 1000 / 480), no máximo 999, e o efeito é o piso de (-100 x progresso / 1000), limitado a 0.
	var slept_minutes: Array[int] = [0, 240, 479, 100, 480, -5]
	var expected_rest: Array[int] = [80, 30, 0, 59, 0, 80]
	for index: int in slept_minutes.size():
		var parts: RunnerParts = _runner_parts()
		assert_true(parts.runner.begin(1, "sleep", HOME, 100).ok)
		var interrupted: Result = parts.runner.interrupt(1, 100 + slept_minutes[index])
		assert_true(interrupted.ok, interrupted.message)
		assert_eq(parts.state.need_values[REST], expected_rest[index], "Interrompido após %d de 480 minutos." % slept_minutes[index])
		assert_eq(parts.state.action_id, "", "A ação é liberada.")
		assert_eq(parts.state.action_serial, 1, "Interromper não é começar outra ação.")


func test_interrupt_brings_the_needs_up_to_now_before_applying_the_effect() -> void:
	var parts: RunnerParts = _runner_parts([60, 0, 0, 0, 0])
	parts.state.need_values[HUNGER] = 50
	parts.state.needs_updated_at = 100
	assert_true(parts.runner.begin(1, "sleep", HOME, 100).ok)
	assert_true(parts.runner.interrupt(1, 130).ok)
	assert_eq(parts.state.need_values[HUNGER], 80, "A fome subiu 1 ponto por minuto durante os 30 minutos de sono.")
	assert_eq(parts.state.need_values[REST], 73, "30 de 480 minutos: progresso 62, efeito piso de -100 x 62 / 1000 = -7.")
	assert_eq(parts.state.needs_updated_at, 130)


func test_interrupt_handles_idle_unknown_and_walking_npcs() -> void:
	var parts: RunnerParts = _runner_parts()
	var before: Dictionary = parts.state.to_dict()
	assert_true(parts.runner.interrupt(1, 50).ok, "Sem ação em andamento não há o que interromper.")
	assert_eq(parts.state.to_dict(), before)
	assert_eq(parts.runner.interrupt(99, 50).code, ActionRunner.CODE_UNKNOWN_NPC)
	assert_true(parts.runner.begin(1, ActionRunner.GO_TO_PLACE_ID, WORK, 60).ok)
	assert_true(parts.runner.interrupt(1, 61).ok)
	assert_eq([parts.state.x_cm, parts.state.place_id, parts.state.action_id], [HOME_X_CM, HOME, ""], "Caminhada interrompida: o NPC fica onde estava.")


# ---------------------------------------------------------------------------------------------------- o pensador só escreve o próximo pensamento

func test_the_thinker_source_writes_only_the_next_think_time_into_the_npc_state() -> void:
	var source: String = FileAccess.get_file_as_string("res://src/sim/npc/decision/npc_thinker.gd")
	var code: PackedStringArray = PackedStringArray()
	for line: String in source.split("\n"):
		var cut: int = line.find("#")
		code.append(line if cut < 0 else line.substr(0, cut))
	var joined: String = "\n".join(code)
	var writes: RegEx = RegEx.create_from_string("\\bstate\\.(?!next_think_time\\b)\\w+(\\[[^\\]]*\\])?\\s*[+\\-*/]?=(?!=)")
	assert_gt(joined.find("state.next_think_time ="), -1, "O pensador agenda o próximo pensamento (a varredura enxerga o arquivo certo).")
	assert_eq(writes.search_all(joined).size(), 0, "Necessidades, ação e posição só mudam pelo ActionRunner e por NeedMath.")
	var control: String = "state.next_think_time = 5\nstate.need_values[0] = 1\nstate.tier += 1\nvar a: bool = state.tier == 1"
	assert_eq(writes.search_all(control).size(), 2, "Controle: acusa atribuição e `+=`, ignora o próximo pensamento e a comparação.")
