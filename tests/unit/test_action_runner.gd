extends GutTest
## LW-060: ActionRunner abstrato (docs/modules/npc.md, seção 3), sem janela. Catálogo e necessidades de teste montados à mão para os
## valores esperados serem calculados na mão (piso de delta x progresso / 1000, tempo antes do efeito, janela de horas, duração por
## distância); no fim, uma passada com os dados reais só confere direção e limites (os números dos dados são [HIP]).

const VILLAGE: String = "village_a"
const HOME: String = "home_a"
const WORK: String = "work_a"
const NEED_IDS: Array[String] = ["hunger", "rest", "safety", "income", "social"]
const DAY: int = 1440
const HUNGER: int = 0
const REST: int = 1
const SOCIAL: int = 4

var _states: Dictionary[int, NpcState] = {}


## Provedor de teste: responde o que o teste mandar e guarda as perguntas.
class FakeProvider:
	extends ActionConditionProvider

	var food: bool = true
	var room: bool = true
	var food_questions: Array[String] = []

	func has_food(settlement_id: String) -> bool:
		food_questions.append(settlement_id)
		return food

	func place_has_room(_place_id: String) -> bool:
		return room


func before_each() -> void:
	_states = {}


func _action(action_id: String, duration: int = 10) -> ActionDef:
	return ActionDef.new(action_id, duration, "", 0, true)


func _with_effect(action: ActionDef, need_id: String, delta: int) -> ActionDef:
	action.effects.append(ActionDef.ActionEffect.new(need_id, delta))
	return action


func _with_condition(action: ActionDef, kind: String, need_id: String = "", min_value: int = ActionDef.ABSENT, max_value: int = ActionDef.ABSENT) -> ActionDef:
	action.conditions.append(ActionDef.ActionCondition.new(kind, need_id, min_value, max_value))
	return action


func _need_defs(rates: Array[int]) -> Array[NeedDef]:
	var defs: Array[NeedDef] = []
	for position: int in NEED_IDS.size():
		defs.append(NeedDef.new(NEED_IDS[position], position, 0, rates[position], 40, 65, 90))
	return defs


func _npc(npc_id: int, values: Array[int] = [0, 0, 0, 0, 0], updated_at: int = 0) -> NpcState:
	var state: NpcState = NpcState.new(npc_id)
	state.need_values = PackedInt64Array(values)
	state.needs_updated_at = updated_at
	state.settlement_id = VILLAGE
	state.place_id = HOME
	_states[npc_id] = state
	return state


func _world() -> SettlementService:
	var settlements: Array[Settlement] = [Settlement.new(VILLAGE, "settlement.a", Vector3(0.0, 0.0, 0.0))]
	var places: Array[Place] = [
		Place.new(HOME, VILLAGE, Place.KIND_HOME, Vector3(84.0, 0.0, 0.0), 5),
		Place.new(WORK, VILLAGE, Place.KIND_WORK, Vector3(100.5, 0.0, 0.0), 10),
		Place.new("diagonal_a", VILLAGE, Place.KIND_REST, Vector3(30.0, 0.0, 40.0), 3),
	]
	return SettlementService.new(settlements, places)


func _runner(catalog: Array[ActionDef], rates: Array[int] = [0, 0, 0, 0, 0], provider: ActionConditionProvider = null, places: SettlementService = null, speed: int = ActionRunner.DEFAULT_WALK_SPEED_CM_PER_MIN) -> ActionRunner:
	var runner: ActionRunner = ActionRunner.new(_states, catalog, _need_defs(rates), places, provider, speed)
	assert_eq(runner.peek_problem(), "", "O runner de teste deveria servir.")
	return runner


func _eat() -> ActionDef:
	return _with_condition(_with_effect(_action("eat", 20), "hunger", -60), ActionDef.CONDITION_HAS_FOOD)


# ---------------------------------------------------------------------------------------------------- começar

func test_begin_fixes_the_action_fields_and_the_end_minute() -> void:
	var state: NpcState = _npc(1)
	var runner: ActionRunner = _runner([_action("wait", 10)])
	var started: Result = runner.begin(1, "wait", HOME, 100)
	assert_true(started.ok, started.message)
	assert_eq(state.action_id, "wait")
	assert_eq(state.action_target_place_id, HOME)
	assert_eq(state.action_started_at, 100)
	assert_eq(state.action_ends_at, 110, "Fim = início + duração.")
	assert_eq(state.action_serial, 1)
	assert_eq(state.needs_updated_at, 100, "As necessidades são levadas até o início antes de qualquer efeito.")


func test_a_second_action_gets_the_next_serial_and_the_npc_is_free_after_the_first() -> void:
	var state: NpcState = _npc(1)
	var runner: ActionRunner = _runner([_action("wait", 10)])
	assert_true(runner.begin(1, "wait", HOME, 0).ok)
	assert_eq(runner.advance(1, 10).outcome, ActionRunner.Outcome.COMPLETED)
	assert_eq(state.action_id, "", "Terminada a ação, o NPC fica livre.")
	assert_eq(state.action_ends_at, 0)
	assert_true(runner.begin(1, "wait", HOME, 10).ok)
	assert_eq(state.action_serial, 2, "O contador de ações do NPC sobe a cada começo.")


func test_zero_duration_actions_other_than_go_to_place_end_at_once() -> void:
	_npc(1)
	var runner: ActionRunner = _runner([_action("blink", 0)])
	assert_true(runner.begin(1, "blink", HOME, 50).ok)
	assert_eq(_states[1].action_ends_at, 50)
	assert_eq(runner.advance(1, 50).outcome, ActionRunner.Outcome.COMPLETED)


# ---------------------------------------------------------------------------------------------------- comer reduz a fome após a duração

func test_eating_reduces_hunger_only_after_the_duration() -> void:
	var state: NpcState = _npc(1, [80, 0, 0, 0, 0], 100)
	var provider: FakeProvider = FakeProvider.new()
	var runner: ActionRunner = _runner([_eat()], [6, 0, 0, 0, 0], provider)
	assert_true(runner.begin(1, "eat", HOME, 100).ok)
	assert_eq(provider.food_questions, [VILLAGE] as Array[String], "A comida é pedida para o assentamento do NPC.")
	var early: ActionRunner.AdvanceResult = runner.advance(1, 119)
	assert_eq(early.outcome, ActionRunner.Outcome.RUNNING)
	assert_eq(state.need_values[HUNGER], 80, "Antes do fim nada muda.")
	assert_eq(state.action_id, "eat")
	var done: ActionRunner.AdvanceResult = runner.advance(1, 120)
	assert_true(done.result.ok, done.result.message)
	assert_eq(done.outcome, ActionRunner.Outcome.COMPLETED)
	assert_eq(state.need_values[HUNGER], 22, "80, mais 2 pontos de 20 minutos a 6 por hora, menos 60 da refeição.")
	assert_eq(state.needs_updated_at, 120)
	assert_eq(state.action_id, "")


func test_the_effect_comes_after_the_time_passed_even_when_the_npc_thinks_late() -> void:
	var rates: Array[int] = [60, 0, 0, 0, 0]
	var on_time: NpcState = _npc(1, [99, 0, 0, 0, 0], 100)
	var late: NpcState = _npc(2, [99, 0, 0, 0, 0], 100)
	var provider: FakeProvider = FakeProvider.new()
	var runner: ActionRunner = _runner([_eat()], rates, provider)
	assert_true(runner.begin(1, "eat", HOME, 100).ok)
	assert_true(runner.begin(2, "eat", HOME, 100).ok)
	assert_eq(runner.advance(1, 120).outcome, ActionRunner.Outcome.COMPLETED)
	assert_eq(runner.advance(2, 157).outcome, ActionRunner.Outcome.COMPLETED)
	assert_eq(on_time.need_values[HUNGER], 40, "99 sobe até 100 (limite) em 20 minutos e a refeição tira 60.")
	assert_eq(late.need_values[HUNGER], 40, "Atrasar o pensamento não muda o efeito: o tempo é contado até o fim, não até agora.")
	assert_eq(late.needs_updated_at, 120)
	var defs: Array[NeedDef] = _need_defs(rates)
	assert_true(NeedMath.settle(on_time, defs, 157).ok)
	assert_true(NeedMath.settle(late, defs, 157).ok)
	assert_eq(late.need_values, on_time.need_values, "Depois de levar os dois ao mesmo minuto o estado é igual.")
	assert_eq(late.need_values[HUNGER], 77, "40 mais os 37 minutos que faltavam.")
	assert_eq(late.need_remainders, on_time.need_remainders)


func test_calling_advance_every_minute_gives_the_same_result_as_calling_it_once() -> void:
	var every_minute: NpcState = _npc(1, [10, 50, 0, 0, 0], 0)
	var once: NpcState = _npc(2, [10, 50, 0, 0, 0], 0)
	var catalog: Array[ActionDef] = [_with_effect(_with_effect(_action("rest_up", 90), "rest", -40), "hunger", 7)]
	var runner: ActionRunner = _runner(catalog, [7, 5, 0, 0, 0])
	assert_true(runner.begin(1, "rest_up", HOME, 0).ok)
	assert_true(runner.begin(2, "rest_up", HOME, 0).ok)
	for minute: int in range(1, 91):
		runner.advance(1, minute)
	runner.advance(2, 90)
	assert_eq(every_minute.need_values, once.need_values)
	assert_eq(every_minute.need_remainders, once.need_remainders)
	assert_eq(every_minute.action_id, "")


func test_advance_changes_nothing_one_minute_before_the_end_and_completes_exactly_at_it() -> void:
	var state: NpcState = _npc(1)
	var runner: ActionRunner = _runner([_with_effect(_action("rest_up", 60), "rest", -10)])
	assert_true(runner.begin(1, "rest_up", HOME, 0).ok)
	assert_eq(runner.advance(1, 59).outcome, ActionRunner.Outcome.RUNNING)
	assert_eq(state.action_id, "rest_up")
	assert_eq(runner.advance(1, 60).outcome, ActionRunner.Outcome.COMPLETED, "No minuto do fim a ação termina.")
	assert_eq(runner.advance(1, 61).outcome, ActionRunner.Outcome.NONE, "Sem ação em andamento não há o que avançar.")


# ---------------------------------------------------------------------------------------------------- condições

func test_unmet_condition_prevents_the_start_and_changes_nothing() -> void:
	var state: NpcState = _npc(1, [80, 0, 0, 0, 0], 100)
	var provider: FakeProvider = FakeProvider.new()
	provider.food = false
	var runner: ActionRunner = _runner([_eat()], [6, 0, 0, 0, 0], provider)
	var before: Dictionary = state.to_dict()
	var refused: Result = runner.begin(1, "eat", HOME, 150)
	assert_false(refused.ok)
	assert_eq(refused.code, ActionRunner.CODE_CONDITION_NOT_MET)
	assert_string_contains(refused.message, "has_food")
	assert_string_contains(refused.message, VILLAGE)
	assert_eq(state.to_dict(), before, "Recusa não altera o estado (nem as necessidades).")
	provider.food = true
	assert_true(runner.begin(1, "eat", HOME, 150).ok, "Com comida a mesma ação começa.")


func test_without_a_provider_has_food_and_place_has_room_are_not_met() -> void:
	_npc(1)
	var talk: ActionDef = _with_condition(_action("talk", 30), ActionDef.CONDITION_PLACE_HAS_ROOM)
	var runner: ActionRunner = _runner([_eat(), talk])
	assert_eq(runner.begin(1, "eat", HOME, 0).code, ActionRunner.CODE_CONDITION_NOT_MET, "Sem provedor a comida não é atendida.")
	var no_room: Result = runner.begin(1, "talk", HOME, 0)
	assert_eq(no_room.code, ActionRunner.CODE_CONDITION_NOT_MET)
	assert_string_contains(no_room.message, "place_has_room")
	var base_class: ActionConditionProvider = ActionConditionProvider.new()
	var with_base: ActionRunner = _runner([_eat()], [0, 0, 0, 0, 0], base_class)
	assert_eq(with_base.begin(1, "eat", HOME, 0).code, ActionRunner.CODE_CONDITION_NOT_MET, "A classe-base responde não.")


func test_place_has_room_asks_the_provider_about_the_action_place() -> void:
	_npc(1)
	var provider: FakeProvider = FakeProvider.new()
	var talk: ActionDef = _with_condition(_action("talk", 30), ActionDef.CONDITION_PLACE_HAS_ROOM)
	var runner: ActionRunner = _runner([talk], [0, 0, 0, 0, 0], provider)
	provider.room = false
	assert_false(runner.begin(1, "talk", WORK, 0).ok)
	provider.room = true
	assert_true(runner.begin(1, "talk", WORK, 0).ok)
	assert_eq(_states[1].action_target_place_id, WORK)


func test_need_conditions_are_inclusive_at_the_limits() -> void:
	var at_least: ActionDef = _with_condition(_action("needs_rest", 10), ActionDef.CONDITION_NEED_AT_LEAST, "rest", 50)
	var at_most: ActionDef = _with_condition(_action("needs_calm", 10), ActionDef.CONDITION_NEED_AT_MOST, "rest", ActionDef.ABSENT, 80)
	var runner: ActionRunner = _runner([at_least, at_most])
	for case: Array in [[1, 49, "needs_rest", false], [2, 50, "needs_rest", true], [3, 80, "needs_calm", true], [4, 81, "needs_calm", false]]:
		_npc(case[0], [0, case[1], 0, 0, 0])
		assert_eq(runner.begin(case[0], case[2], HOME, 0).ok, case[3], "Valor %d em %s." % [case[1], case[2]])


func test_need_conditions_use_the_value_projected_to_the_start_without_storing_it_on_refusal() -> void:
	var state: NpcState = _npc(1, [49, 0, 0, 0, 0], 10)
	var needs_hunger: ActionDef = _with_condition(_action("needs_food", 10), ActionDef.CONDITION_NEED_AT_LEAST, "hunger", 50)
	var runner: ActionRunner = _runner([needs_hunger], [60, 0, 0, 0, 0])
	var before: Dictionary = state.to_dict()
	assert_false(runner.begin(1, "needs_food", HOME, 10).ok, "No minuto 10 a fome ainda é 49.")
	assert_eq(state.to_dict(), before)
	assert_true(runner.begin(1, "needs_food", HOME, 11).ok, "No minuto 11 o valor projetado é 50: atende.")
	assert_eq(state.need_values[HUNGER], 50, "Com a ação começada, o valor projetado é gravado.")


func test_hour_windows_inside_the_day_across_midnight_empty_and_whole_day() -> void:
	var cases: Array[Array] = [
		[8, 17, [7, 8, 16, 17], [false, true, true, false]],
		[22, 6, [21, 22, 23, 0, 5, 6], [false, true, true, true, true, false]],
		[6, 6, [0, 6, 12, 23], [false, false, false, false]],
		[0, 24, [0, 12, 23], [true, true, true]],
		[20, 24, [19, 20, 23], [false, true, true]],
		[0, 0, [0, 23], [false, false]],
	]
	for window: Array in cases:
		for index: int in window[2].size():
			var hour: int = window[2][index]
			assert_eq(ActionRunner.hour_in_window(hour, window[0], window[1]), window[3][index], "Hora %d na janela %d a %d." % [hour, window[0], window[1]])


func test_begin_reads_the_hour_of_the_day_from_the_minute() -> void:
	_npc(1)
	var day_job: ActionDef = _with_condition(_action("day_job", 60), ActionDef.CONDITION_HOUR_BETWEEN, "", 8, 17)
	var runner: ActionRunner = _runner([day_job])
	assert_false(runner.begin(1, "day_job", HOME, 3 * DAY + 7 * 60 + 59).ok, "7h59 está fora.")
	assert_true(runner.begin(1, "day_job", HOME, 3 * DAY + 8 * 60).ok, "8h00 está dentro, em qualquer dia.")
	var refused: Result = runner.begin(1, "day_job", HOME, 3 * DAY + 8 * 60)
	assert_eq(refused.code, ActionRunner.CODE_BUSY)
	_npc(2)
	assert_false(runner.begin(2, "day_job", HOME, 17 * 60).ok, "17h00 já está fora (o fim da janela não vale).")
	var message: String = runner.begin(2, "day_job", HOME, 5 * DAY + 20 * 60 + 30).message
	assert_string_contains(message, "hora 20")


func test_an_unknown_condition_kind_is_never_met() -> void:
	_npc(1)
	var strange: ActionDef = _with_condition(_action("strange", 10), "is_raining")
	var refused: Result = _runner([strange]).begin(1, "strange", HOME, 0)
	assert_eq(refused.code, ActionRunner.CODE_CONDITION_NOT_MET)
	assert_string_contains(refused.message, "is_raining")


# ---------------------------------------------------------------------------------------------------- função única de efeitos

func test_effects_are_proportional_to_the_progress_with_floor_rounding() -> void:
	var heal: ActionDef = _with_effect(_with_effect(_action("heal", 60), "rest", -61), "hunger", 20)
	var runner: ActionRunner = _runner([heal])
	var cases: Array[Array] = [[500, 19, 20], [0, 50, 10], [1000, 0, 30], [333, 29, 16], [1, 49, 10]]
	for case: Array in cases:
		var state: NpcState = _npc(7, [10, 50, 0, 0, 0])
		assert_true(runner.apply_effects(7, "heal", HOME, case[0]).ok)
		assert_eq(state.need_values[REST], case[1], "Descanso com progresso %d (piso de -61 x progresso / 1000, limitado a 0)." % case[0])
		assert_eq(state.need_values[HUNGER], case[2], "Fome com progresso %d." % case[0])


func test_effects_are_clamped_to_the_range() -> void:
	var overshoot: ActionDef = _with_effect(_with_effect(_action("overshoot", 10), "rest", -100), "hunger", 100)
	var runner: ActionRunner = _runner([overshoot])
	var state: NpcState = _npc(1, [95, 5, 0, 0, 0])
	assert_true(runner.apply_effects(1, "overshoot", HOME, 1000).ok)
	assert_eq(state.need_values[HUNGER], 100)
	assert_eq(state.need_values[REST], 0)


func test_apply_effects_refuses_bad_progress_unknown_npc_unknown_action_and_dead_npc_without_changing_anything() -> void:
	var state: NpcState = _npc(1, [10, 50, 0, 0, 0])
	var runner: ActionRunner = _runner([_with_effect(_action("heal", 10), "rest", -10)])
	var before: Dictionary = state.to_dict()
	assert_eq(runner.apply_effects(1, "heal", HOME, -1).code, ActionRunner.CODE_INVALID_PROGRESS)
	assert_eq(runner.apply_effects(1, "heal", HOME, 1001).code, ActionRunner.CODE_INVALID_PROGRESS)
	assert_eq(runner.apply_effects(99, "heal", HOME, 1000).code, ActionRunner.CODE_UNKNOWN_NPC)
	assert_eq(runner.apply_effects(1, "ghost", HOME, 1000).code, ActionRunner.CODE_UNKNOWN_ACTION)
	state.is_alive = false
	before = state.to_dict()
	assert_eq(runner.apply_effects(1, "heal", HOME, 1000).code, ActionRunner.CODE_NOT_ALIVE)
	assert_eq(state.to_dict(), before)


func test_a_rule_that_stops_holding_at_the_end_fails_the_action_without_any_effect() -> void:
	var state: NpcState = _npc(1, [80, 0, 0, 0, 0], 100)
	var provider: FakeProvider = FakeProvider.new()
	var runner: ActionRunner = _runner([_eat()], [6, 0, 0, 0, 0], provider)
	assert_true(runner.begin(1, "eat", HOME, 100).ok)
	provider.food = false
	var finished: ActionRunner.AdvanceResult = runner.advance(1, 120)
	assert_false(finished.result.ok)
	assert_eq(finished.result.code, ActionRunner.CODE_ACTION_FAILED)
	assert_eq(finished.outcome, ActionRunner.Outcome.FAILED)
	assert_string_contains(finished.result.message, "nenhum efeito")
	assert_eq(state.need_values[HUNGER], 82, "Só o tempo passou (80 + 2): a refeição não deu efeito.")
	assert_eq(state.action_id, "", "O NPC fica livre para tentar outra coisa.")
	assert_eq(state.action_serial, 1)
	provider.food = true
	assert_true(runner.begin(1, "eat", HOME, 120).ok)


func test_the_completion_check_applies_only_to_the_complete_action() -> void:
	var state: NpcState = _npc(1, [80, 0, 0, 0, 0])
	var provider: FakeProvider = FakeProvider.new()
	provider.food = false
	var runner: ActionRunner = _runner([_eat()], [0, 0, 0, 0, 0], provider)
	var complete: Result = runner.apply_effects(1, "eat", HOME, 1000)
	assert_eq(complete.code, ActionRunner.CODE_ACTION_FAILED)
	assert_eq(state.need_values[HUNGER], 80)
	assert_true(runner.apply_effects(1, "eat", HOME, 999).ok, "Interrompida (999) não confere a comida de novo: aplica o que cumpriu.")
	assert_eq(state.need_values[HUNGER], 20, "80 mais o piso de -60 x 999 / 1000: floor(-59,94) = -60 (o piso arredonda para o lado de quem alivia).")


# ---------------------------------------------------------------------------------------------------- ir até um local

func test_go_to_place_takes_the_distance_divided_by_the_walk_speed_rounded_up() -> void:
	var catalog: Array[ActionDef] = [_action(ActionRunner.GO_TO_PLACE_ID, 0)]
	var cases: Array[Array] = [
		["origem até a casa, 84 m", 0, 0, HOME, 8400, 1],
		["origem até o trabalho, 100,5 m", 0, 0, WORK, 8400, 2],
		["da casa ao trabalho, 16,5 m", 8400, 0, WORK, 8400, 1],
		["a mesma posição: no mínimo 1 minuto", 8400, 0, HOME, 8400, 1],
		["100,5 m a 100 cm por minuto", 0, 0, WORK, 100, 101],
		["diagonal 30 m e 40 m = 50 m exatos, a 1000 cm por minuto", 0, 0, "diagonal_a", 1000, 5],
	]
	for case: Array in cases:
		_states.clear()
		var state: NpcState = _npc(1)
		state.x_cm = case[1]
		state.z_cm = case[2]
		var runner: ActionRunner = _runner(catalog, [0, 0, 0, 0, 0], null, _world(), case[4])
		var started: Result = runner.begin(1, ActionRunner.GO_TO_PLACE_ID, case[3], 1000)
		assert_true(started.ok, "%s: %s" % [case[0], started.message])
		assert_eq(state.action_ends_at, 1000 + case[5], case[0])


func test_go_to_place_moves_the_npc_only_when_it_arrives() -> void:
	var state: NpcState = _npc(1)
	state.settlement_id = ""
	state.place_id = ""
	var runner: ActionRunner = _runner([_action(ActionRunner.GO_TO_PLACE_ID, 0)], [0, 0, 0, 0, 0], null, _world())
	assert_true(runner.begin(1, ActionRunner.GO_TO_PLACE_ID, WORK, 0).ok)
	assert_eq(state.action_ends_at, 2)
	assert_eq(runner.advance(1, 1).outcome, ActionRunner.Outcome.RUNNING)
	assert_eq([state.x_cm, state.z_cm, state.place_id], [0, 0, ""], "A caminho o NPC ainda não mudou de lugar.")
	var arrived: ActionRunner.AdvanceResult = runner.advance(1, 2)
	assert_eq(arrived.outcome, ActionRunner.Outcome.COMPLETED)
	assert_eq([state.x_cm, state.z_cm], [10050, 0], "Chegou: a posição lógica é a do destino, em centímetros.")
	assert_eq(state.place_id, WORK)
	assert_eq(state.settlement_id, VILLAGE)
	assert_eq(state.action_id, "")


func test_go_to_place_needs_a_known_destination_and_the_world_service() -> void:
	var state: NpcState = _npc(1)
	var catalog: Array[ActionDef] = [_action(ActionRunner.GO_TO_PLACE_ID, 0), _action("wait", 10)]
	var with_world: ActionRunner = _runner(catalog, [0, 0, 0, 0, 0], null, _world())
	var before: Dictionary = state.to_dict()
	var unknown: Result = with_world.begin(1, ActionRunner.GO_TO_PLACE_ID, "nowhere", 0)
	assert_eq(unknown.code, ActionRunner.CODE_PLACE_UNKNOWN)
	assert_string_contains(unknown.message, "nowhere")
	assert_eq(state.to_dict(), before)
	var without_world: ActionRunner = _runner(catalog)
	var no_service: Result = without_world.begin(1, ActionRunner.GO_TO_PLACE_ID, HOME, 0)
	assert_eq(no_service.code, ActionRunner.CODE_NOT_READY)
	assert_string_contains(no_service.message, "serviço de locais")
	assert_true(without_world.begin(1, "wait", HOME, 0).ok, "As outras ações não dependem do `world`.")


# ---------------------------------------------------------------------------------------------------- erros de uso

func test_begin_and_advance_handle_wrong_use_without_crashing_and_without_changes() -> void:
	var state: NpcState = _npc(1, [0, 0, 0, 0, 0], 50)
	var runner: ActionRunner = _runner([_action("wait", 10)])
	var before: Dictionary = state.to_dict()
	assert_eq(runner.begin(99, "wait", HOME, 60).code, ActionRunner.CODE_UNKNOWN_NPC)
	assert_eq(runner.begin(1, "ghost", HOME, 60).code, ActionRunner.CODE_UNKNOWN_ACTION)
	assert_string_contains(runner.begin(1, "ghost", HOME, 60).message, "ghost")
	var backwards: Result = runner.begin(1, "wait", HOME, 49)
	assert_eq(backwards.code, NeedMath.CODE_TIME_WENT_BACK)
	assert_eq(runner.advance(99, 60).result.code, ActionRunner.CODE_UNKNOWN_NPC)
	assert_eq(state.to_dict(), before)
	state.is_alive = false
	assert_eq(runner.begin(1, "wait", HOME, 60).code, ActionRunner.CODE_NOT_ALIVE)
	state.is_alive = true
	assert_true(runner.begin(1, "wait", HOME, 60).ok)
	var busy: Result = runner.begin(1, "wait", HOME, 61)
	assert_eq(busy.code, ActionRunner.CODE_BUSY)
	assert_string_contains(busy.message, "'wait'")
	assert_eq(state.action_serial, 1, "A recusa por ocupado não conta como ação.")


func test_a_runner_with_bad_definitions_is_not_ready_and_every_call_says_so() -> void:
	_npc(1)
	var four: Array[NeedDef] = _need_defs([0, 0, 0, 0, 0])
	four.pop_back()
	var catalog: Array[ActionDef] = [_action("wait", 10)]
	var unknown_need: Array[ActionDef] = [_with_effect(_action("heal", 10), "thirst", -10)]
	var unknown_condition_need: Array[ActionDef] = [_with_condition(_action("limit", 10), ActionDef.CONDITION_NEED_AT_LEAST, "thirst", 10)]
	var twice: Array[ActionDef] = [_action("wait", 10), _action("wait", 20)]
	var broken: Array[ActionRunner] = [
		ActionRunner.new(_states, catalog, four),
		ActionRunner.new(_states, unknown_need, _need_defs([0, 0, 0, 0, 0])),
		ActionRunner.new(_states, unknown_condition_need, _need_defs([0, 0, 0, 0, 0])),
		ActionRunner.new(_states, twice, _need_defs([0, 0, 0, 0, 0])),
		ActionRunner.new(_states, catalog, _need_defs([0, 0, 0, 0, 0]), null, null, 0),
	]
	var fragments: Array[String] = ["definições de necessidades", "thirst", "thirst", "duas vezes", "velocidade de caminhada"]
	for index: int in broken.size():
		assert_string_contains(broken[index].peek_problem(), fragments[index])
		assert_eq(broken[index].begin(1, "wait", HOME, 0).code, ActionRunner.CODE_NOT_READY)
		assert_eq(broken[index].advance(1, 0).result.code, ActionRunner.CODE_NOT_READY)
		assert_eq(broken[index].apply_effects(1, "wait", HOME, 1000).code, ActionRunner.CODE_NOT_READY)


func test_the_same_script_twice_gives_the_same_states() -> void:
	var dumps: Array[Dictionary] = []
	for _repetition: int in 2:
		_states = {}
		_npc(1, [30, 60, 10, 0, 40], 0)
		var provider: FakeProvider = FakeProvider.new()
		var catalog: Array[ActionDef] = [_eat(), _with_effect(_action("sleep", 480), "rest", -100), _action(ActionRunner.GO_TO_PLACE_ID, 0)]
		var runner: ActionRunner = _runner(catalog, [5, 4, -5, 2, 2], provider, _world())
		assert_true(runner.begin(1, ActionRunner.GO_TO_PLACE_ID, HOME, 3).ok)
		runner.advance(1, 20)
		assert_true(runner.begin(1, "eat", HOME, 20).ok)
		runner.advance(1, 400)
		assert_true(runner.begin(1, "sleep", HOME, 400).ok)
		runner.advance(1, 900)
		dumps.append(_states[1].to_dict())
	assert_eq(dumps[0], dumps[1])


# ---------------------------------------------------------------------------------------------------- dados reais

func test_the_real_catalog_and_needs_work_in_the_runner() -> void:
	var catalog: ActionCatalogLoader.LoadResult = ActionCatalogLoader.load_dir()
	var needs: NeedLoader.LoadResult = NeedLoader.load_dir()
	assert_true(catalog.result.ok, catalog.result.message)
	assert_true(needs.result.ok, needs.result.message)
	var state: NpcState = _npc(1, [70, 90, 0, 0, 0], 0)
	state.settlement_id = VILLAGE
	var provider: FakeProvider = FakeProvider.new()
	var runner: ActionRunner = ActionRunner.new(_states, catalog.actions, needs.needs, _world(), provider)
	assert_eq(runner.peek_problem(), "")
	var hunger_before: int = state.need_values[HUNGER]
	assert_true(runner.begin(1, "eat", HOME, 0).ok)
	assert_eq(runner.advance(1, state.action_ends_at).outcome, ActionRunner.Outcome.COMPLETED)
	assert_lt(state.need_values[HUNGER], hunger_before, "Comer reduz a fome.")
	var rest_before: int = state.need_values[REST]
	assert_true(runner.begin(1, "sleep", HOME, state.needs_updated_at).ok)
	assert_eq(runner.advance(1, state.action_ends_at).outcome, ActionRunner.Outcome.COMPLETED)
	assert_lt(state.need_values[REST], rest_before, "Dormir reduz o cansaço.")
	provider.food = false
	assert_eq(runner.begin(1, "eat", HOME, state.needs_updated_at).code, ActionRunner.CODE_CONDITION_NOT_MET, "Sem comida o mesmo `eat` não começa.")
	for need_value: int in state.need_values:
		assert_true(need_value >= 0 and need_value <= 100)
