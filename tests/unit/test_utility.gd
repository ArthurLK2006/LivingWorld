extends GutTest
## LW-062: pontuação de utilidade (docs/modules/npc.md, seção 5), sem janela. Parâmetros, necessidades e ações de teste montados à mão para
## os valores serem calculados na mão (benefício por nível de urgência, alívio limitado, piso da personalidade, custos, bônus); no fim, uma
## passada com os dados reais confere só PROPRIEDADES (os números de data/npc_params.json e dos pesos de personalidade são [HIP]).

const NEED_IDS: Array[String] = ["hunger", "rest", "safety", "income", "social"]
const TRAIT_IDS: Array[String] = ["caution", "sociability", "ambition", "loyalty"]
const HUNGER: int = 0
const REST: int = 1
const SOCIAL: int = 4


## Parâmetros de teste: pesos 0, 1, 3 e 6 por nível; 2 pontos por hora, 2 por 100 m, risco a 100%; inércia 25 e rotina 40.
func _params() -> NpcParams:
	var params: NpcParams = NpcParams.new()
	params.urgency_weight_comfortable = 0
	params.urgency_weight_attention = 1
	params.urgency_weight_urgent = 3
	params.urgency_weight_critical = 6
	params.time_cost_per_hour = 2
	params.distance_cost_per_100m = 2
	params.risk_cost_percent = 100
	params.inertia_bonus = 25
	params.routine_bonus = 40
	return params


## Cinco necessidades de teste com os limiares 40, 65 e 90 (atenção, urgente, crítica).
func _need_defs() -> Array[NeedDef]:
	var defs: Array[NeedDef] = []
	for position: int in NEED_IDS.size():
		defs.append(NeedDef.new(NEED_IDS[position], position, 0, 0, 40, 65, 90))
	return defs


func _trait_defs() -> Array[TraitLoader.TraitDef]:
	var defs: Array[TraitLoader.TraitDef] = []
	for position: int in TRAIT_IDS.size():
		defs.append(TraitLoader.TraitDef.new(TRAIT_IDS[position], position))
	return defs


func _scorer(params: NpcParams = null) -> UtilityScorer:
	var scorer: UtilityScorer = UtilityScorer.new(params if params != null else _params(), _need_defs(), _trait_defs())
	assert_eq(scorer.peek_problem(), "", "O pontuador de teste deveria servir.")
	return scorer


func _npc(hunger: int, rest: int = 0, social: int = 0, traits: Array[int] = [50, 50, 50, 50]) -> NpcState:
	var state: NpcState = NpcState.new(1)
	state.need_values = PackedInt64Array([hunger, rest, 0, 0, social])
	state.traits = PackedInt64Array(traits)
	return state


func _action(action_id: String, duration: int = 0, risk: int = 0) -> ActionDef:
	return ActionDef.new(action_id, duration, "", risk, true)


func _effect(action: ActionDef, need_id: String, delta: int) -> ActionDef:
	action.effects.append(ActionDef.ActionEffect.new(need_id, delta))
	return action


func _weight(action: ActionDef, trait_id: String, weight: int) -> ActionDef:
	action.trait_weights.append(ActionDef.ActionTraitWeight.new(trait_id, weight))
	return action


func _total(state: NpcState, action: ActionDef, distance_cm: int = 0, is_current: bool = false, is_routine: bool = false) -> int:
	var breakdown: UtilityScorer.ScoreBreakdown = _scorer().score(state, action, distance_cm, is_current, is_routine)
	assert_true(breakdown.result.ok, breakdown.result.message)
	return breakdown.total


# ---------------------------------------------------------------------------------------------------- benefício

func test_benefit_is_the_relief_times_the_weight_of_the_current_urgency_level() -> void:
	var eat: ActionDef = _effect(_action("eat", 20), "hunger", -60)
	var cases: Dictionary = {10: 0, 39: 0, 40: 40, 45: 45, 64: 60, 65: 180, 89: 180, 90: 360, 100: 360}
	for hunger: int in cases:
		var breakdown: UtilityScorer.ScoreBreakdown = _scorer().score(_npc(hunger), eat, 0, false, false)
		assert_eq(breakdown.benefit, cases[hunger], "Fome %d: nível, peso e alívio (limitado ao que a fome ainda tem) dão %d." % [hunger, cases[hunger]])


func test_relief_is_limited_to_what_the_need_still_has() -> void:
	var sleep: ActionDef = _effect(_action("sleep", 480), "rest", -100)
	var breakdown: UtilityScorer.ScoreBreakdown = _scorer().score(_npc(0, 70), sleep, 0, false, false)
	assert_eq(breakdown.benefit, 210, "Descanso em 70 (urgente, peso 3): alivia no máximo 70, não 100: 70 x 3.")
	assert_eq(_scorer().score(_npc(0, 0), sleep, 0, false, false).benefit, 0, "Quem não tem cansaço não ganha nada dormindo.")


func test_an_effect_that_raises_pressure_counts_against_the_action_by_the_urgency_of_that_need() -> void:
	var work: ActionDef = _effect(_action("work", 240), "rest", 5)
	assert_eq(_scorer().score(_npc(0, 90), work, 0, false, false).benefit, -30, "Cansaço crítico (peso 6): sobe 5, custa 30.")
	assert_eq(_scorer().score(_npc(0, 98), work, 0, false, false).benefit, -12, "Só sobem 2 até o limite de 100: 2 x 6.")
	assert_eq(_scorer().score(_npc(0, 10), work, 0, false, false).benefit, 0, "Confortável (peso 0): não pesa.")


# ---------------------------------------------------------------------------------------------------- personalidade

func test_personality_is_the_floor_of_the_weighted_traits_over_50() -> void:
	var cases: Array[Array] = [[100, 10, 10], [0, 10, -10], [51, 10, 0], [49, 10, -1], [50, 10, 0], [100, -20, -20], [100, 20, 20]]
	for case: Array in cases:
		var action: ActionDef = _weight(_action("rest", 0), "caution", case[1])
		var breakdown: UtilityScorer.ScoreBreakdown = _scorer().score(_npc(0, 0, 0, [case[0], 50, 50, 50]), action, 0, false, false)
		assert_eq(breakdown.personality, case[2], "Cautela %d com peso %d." % [case[0], case[1]])
	var two: ActionDef = _weight(_weight(_action("mixed", 0), "caution", 10), "ambition", 15)
	assert_eq(_scorer().score(_npc(0, 0, 0, [100, 50, 0, 50]), two, 0, false, false).personality, -5, "(50 x 10 + (-50) x 15) / 50 = -250 / 50.")


# ---------------------------------------------------------------------------------------------------- custos e bônus

func test_time_distance_and_risk_costs_use_the_floor() -> void:
	var state: NpcState = _npc(0)
	for case: Array in [[240, 8], [90, 3], [20, 0], [0, 0]]:
		assert_eq(_scorer().score(state, _action("a", case[0]), 0, false, false).time_cost, case[1], "Duração %d min." % case[0])
	for case: Array in [[15000, 3], [9900, 1], [10000, 2], [0, 0], [-500, 0]]:
		assert_eq(_scorer().score(state, _action("a"), case[0], false, false).distance_cost, case[1], "Distância %d cm." % case[0])
	assert_eq(_scorer().score(state, _action("a", 0, 5), 0, false, false).risk_cost, 5)
	var heavier: NpcParams = _params()
	heavier.risk_cost_percent = 150
	assert_eq(_scorer(heavier).score(state, _action("a", 0, 7), 0, false, false).risk_cost, 10, "7 x 150% = 10,5, piso 10.")
	var slower: NpcParams = _params()
	slower.time_cost_per_hour = 3
	assert_eq(_scorer(slower).score(state, _action("a", 50), 0, false, false).time_cost, 2, "50 min a 3 por hora = 2,5, piso 2.")


func test_inertia_and_routine_bonuses_come_from_the_flags() -> void:
	var state: NpcState = _npc(0)
	var action: ActionDef = _action("wait")
	assert_eq(_total(state, action), 0)
	assert_eq(_total(state, action, 0, true, false), 25, "Inércia: a ação que o NPC já faz.")
	assert_eq(_total(state, action, 0, false, true), 40, "Rotina: a ação da hora.")
	assert_eq(_total(state, action, 0, true, true), 65)


func test_every_term_adds_up_to_the_total() -> void:
	var state: NpcState = _npc(70, 0, 0, [50, 50, 100, 50])
	var action: ActionDef = _effect(_effect(_action("busy", 240, 5), "hunger", -60), "rest", 5)
	_weight(action, "ambition", 15)
	var breakdown: UtilityScorer.ScoreBreakdown = _scorer().score(state, action, 15000, true, true)
	assert_eq(breakdown.benefit, 180, "Fome 70 (urgente, peso 3) alivia 60 = 180; o cansaço 0 pesa 0.")
	assert_eq(breakdown.personality, 15)
	assert_eq(breakdown.time_cost, 8)
	assert_eq(breakdown.distance_cost, 3)
	assert_eq(breakdown.risk_cost, 5)
	assert_eq(breakdown.inertia_bonus, 25)
	assert_eq(breakdown.routine_bonus, 40)
	assert_eq(breakdown.total, 244, "180 + 15 - 8 - 3 - 5 + 25 + 40.")


# ---------------------------------------------------------------------------------------------------- o que o aceite pede

func test_a_hungry_npc_scores_eating_higher_than_a_fed_one_and_higher_than_working() -> void:
	var eat: ActionDef = _effect(_action("eat", 20), "hunger", -60)
	var work: ActionDef = _effect(_action("work", 240, 5), "rest", 5)
	var hungry: NpcState = _npc(90)
	var fed: NpcState = _npc(10)
	assert_eq(_total(hungry, eat), 360)
	assert_eq(_total(fed, eat), 0)
	assert_gt(_total(hungry, eat), _total(fed, eat), "Faminto pontua mais alto em comer.")
	assert_eq(_total(hungry, work, 0, true, true), 52, "Trabalhar na hora do trabalho e já em andamento: 0 + 40 + 25 - 8 - 5.")
	assert_gt(_total(hungry, eat), _total(hungry, work, 0, true, true), "Mesmo com rotina e inércia a favor, trabalhar perde para a fome crítica.")
	assert_gt(_total(fed, work, 0, false, true), _total(fed, eat), "Sem fome, a rotina manda.")


func test_inertia_keeps_the_current_action_unless_the_alternative_is_much_better() -> void:
	var state: NpcState = _npc(0, 0, 60)
	var current: ActionDef = _effect(_action("a"), "social", -30)
	var slightly_better: ActionDef = _effect(_action("b"), "social", -50)
	var much_better: ActionDef = _effect(_action("c"), "social", -70)
	assert_eq(_total(state, current), 30)
	assert_eq(_total(state, slightly_better), 50)
	assert_eq(_total(state, much_better), 60)
	assert_gt(_total(state, current, 0, true), _total(state, slightly_better), "30 + 25 = 55 contra 50: continua na ação atual.")
	assert_lt(_total(state, current, 0, true), _total(state, much_better), "55 contra 60: a diferença passou do bônus de inércia, troca.")
	assert_lt(_total(state, current), _total(state, slightly_better), "Sem a inércia, a outra já ganharia.")


# ---------------------------------------------------------------------------------------------------- função pura

func test_the_same_state_and_inputs_always_give_the_same_score_and_nothing_changes() -> void:
	var state: NpcState = _npc(70, 30, 20, [10, 90, 50, 70])
	var action: ActionDef = _effect(_weight(_action("talk", 30, 2), "sociability", 7), "social", -30)
	var state_before: Dictionary = state.to_dict()
	var first: UtilityScorer.ScoreBreakdown = _scorer().score(state, action, 4321, true, false)
	var second: UtilityScorer.ScoreBreakdown = _scorer().score(state, action, 4321, true, false)
	var third: UtilityScorer.ScoreBreakdown = UtilityScorer.new(_params(), _need_defs(), _trait_defs()).score(state, action, 4321, true, false)
	assert_eq([first.total, first.benefit, first.personality], [second.total, second.benefit, second.personality])
	assert_eq(third.total, first.total, "Outro pontuador com os mesmos dados dá a mesma pontuação.")
	assert_eq(state.to_dict(), state_before, "Pontuar não altera o estado do NPC.")
	assert_eq(action.effects.size(), 1)
	assert_eq(action.trait_weights.size(), 1)


func test_the_order_in_which_actions_are_scored_does_not_matter() -> void:
	var scorer: UtilityScorer = _scorer()
	var state: NpcState = _npc(80, 60, 10)
	var first_action: ActionDef = _effect(_action("eat", 20), "hunger", -60)
	var second_action: ActionDef = _effect(_action("sleep", 480), "rest", -100)
	var a_then_b: Array[int] = [scorer.score(state, first_action, 0, false, false).total, scorer.score(state, second_action, 0, false, false).total]
	var b_then_a_second: int = scorer.score(state, second_action, 0, false, false).total
	var b_then_a_first: int = scorer.score(state, first_action, 0, false, false).total
	assert_eq([b_then_a_first, b_then_a_second], a_then_b)


func test_the_scorer_source_never_writes_to_the_npc_state() -> void:
	var source: String = FileAccess.get_file_as_string("res://src/sim/npc/decision/utility_scorer.gd")
	var code: PackedStringArray = PackedStringArray()
	for line: String in source.split("\n"):
		var cut: int = line.find("#")
		code.append(line if cut < 0 else line.substr(0, cut))
	var joined: String = "\n".join(code)
	assert_gt(joined.find("state.need_values"), -1, "O pontuador lê as necessidades do estado (a varredura enxerga o arquivo certo).")
	var writes: RegEx = RegEx.create_from_string("\\bstate\\.\\w+(\\[[^\\]]*\\])?\\s*[+\\-*/]?=(?!=)")
	assert_eq(writes.search_all(joined).size(), 0, "Pontuar é leitura: o pontuador não escreve nenhum campo do estado do NPC.")
	var control: String = "state.need_values[0] = 5\nstate.tier += 1\nvar a: bool = state.tier == 1"
	assert_eq(writes.search_all(control).size(), 2, "Controle: a varredura acusa atribuição e `+=`, e ignora comparação.")


# ---------------------------------------------------------------------------------------------------- erros

func test_a_scorer_with_bad_definitions_is_not_ready_and_scoring_fails_cleanly() -> void:
	var four: Array[NeedDef] = _need_defs()
	four.pop_back()
	var three_traits: Array[TraitLoader.TraitDef] = _trait_defs()
	three_traits.pop_back()
	var misordered: Array[TraitLoader.TraitDef] = _trait_defs()
	misordered.reverse()
	var broken: Array[UtilityScorer] = [
		UtilityScorer.new(_params(), four, _trait_defs()),
		UtilityScorer.new(_params(), _need_defs(), three_traits),
		UtilityScorer.new(_params(), _need_defs(), misordered),
		UtilityScorer.new(null, _need_defs(), _trait_defs()),
	]
	var fragments: Array[String] = ["definições de necessidades", "3 definições de traço", "order", "parâmetros nulos"]
	for index: int in broken.size():
		assert_string_contains(broken[index].peek_problem(), fragments[index])
		var breakdown: UtilityScorer.ScoreBreakdown = broken[index].score(_npc(0), _action("a"), 0, false, false)
		assert_false(breakdown.result.ok)
		assert_eq(breakdown.result.code, UtilityScorer.CODE_NOT_READY)
		assert_eq(breakdown.total, 0)


func test_an_action_that_cites_an_unknown_need_or_trait_fails_with_the_reference() -> void:
	var scorer: UtilityScorer = _scorer()
	var unknown_need: UtilityScorer.ScoreBreakdown = scorer.score(_npc(0), _effect(_action("heal"), "thirst", -10), 0, false, false)
	assert_eq(unknown_need.result.code, UtilityScorer.CODE_UNKNOWN_REFERENCE)
	assert_string_contains(unknown_need.result.message, "heal")
	assert_string_contains(unknown_need.result.message, "thirst")
	var unknown_trait: UtilityScorer.ScoreBreakdown = scorer.score(_npc(0), _weight(_action("charm_act"), "charm", 5), 0, false, false)
	assert_eq(unknown_trait.result.code, UtilityScorer.CODE_UNKNOWN_REFERENCE)
	assert_string_contains(unknown_trait.result.message, "charm")


# ---------------------------------------------------------------------------------------------------- dados reais

func _real_scorer_parts() -> Dictionary:
	var params: NpcParamsLoader.LoadResult = NpcParamsLoader.load_dir()
	var needs: NeedLoader.LoadResult = NeedLoader.load_dir()
	var traits: TraitLoader.LoadResult = TraitLoader.load_dir()
	var catalog: ActionCatalogLoader.LoadResult = ActionCatalogLoader.load_dir()
	assert_true(params.result.ok, params.result.message)
	assert_true(needs.result.ok, needs.result.message)
	assert_true(traits.result.ok, traits.result.message)
	assert_true(catalog.result.ok, catalog.result.message)
	return {"params": params.params, "needs": needs.needs, "traits": traits.traits, "actions": catalog.actions}


func test_the_real_personality_weights_cover_every_trait_within_minus_20_and_plus_20() -> void:
	var parts: Dictionary = _real_scorer_parts()
	var nonzero_by_trait: Dictionary = {}
	for trait_def: TraitLoader.TraitDef in parts["traits"]:
		nonzero_by_trait[trait_def.id] = 0
	for action: ActionDef in parts["actions"]:
		for weight: ActionDef.ActionTraitWeight in action.trait_weights:
			assert_true(weight.weight >= -20 and weight.weight <= 20, "%s / %s: peso %d fora de -20 a +20." % [action.id, weight.trait_id, weight.weight])
			if weight.weight != 0:
				nonzero_by_trait[weight.trait_id] += 1
	for trait_id: String in nonzero_by_trait:
		assert_gt(nonzero_by_trait[trait_id], 0, "O traço '%s' precisa de ao menos um peso não nulo." % trait_id)


func test_with_the_real_data_a_critically_hungry_npc_prefers_eating_to_everything_else() -> void:
	var parts: Dictionary = _real_scorer_parts()
	var scorer: UtilityScorer = UtilityScorer.new(parts["params"], parts["needs"], parts["traits"])
	assert_eq(scorer.peek_problem(), "")
	var hungry: NpcState = NpcState.new(1)
	hungry.need_values = PackedInt64Array([95, 0, 0, 0, 0])
	var eat_total: int = 0
	var best_rival: int = -1000000
	for action: ActionDef in parts["actions"]:
		var rival: UtilityScorer.ScoreBreakdown = scorer.score(hungry, action, 0, true, true)
		assert_true(rival.result.ok, rival.result.message)
		if action.id == "eat":
			eat_total = scorer.score(hungry, action, 0, false, false).total
		else:
			best_rival = maxi(best_rival, rival.total)
	assert_gt(eat_total, best_rival, "Fome crítica: comer vence qualquer outra ação, mesmo com rotina e inércia a favor delas.")
	var satiated: NpcState = NpcState.new(2)
	for action: ActionDef in parts["actions"]:
		if action.id == "eat":
			assert_eq(scorer.score(satiated, action, 0, false, false).benefit, 0, "Sem fome, comer não rende benefício.")


func test_with_the_real_data_a_very_tired_npc_prefers_sleeping_to_working() -> void:
	var parts: Dictionary = _real_scorer_parts()
	var scorer: UtilityScorer = UtilityScorer.new(parts["params"], parts["needs"], parts["traits"])
	var tired: NpcState = NpcState.new(1)
	tired.need_values = PackedInt64Array([0, 90, 0, 0, 0])
	var sleep_total: int = 0
	var work_total: int = 0
	for action: ActionDef in parts["actions"]:
		if action.id == "sleep":
			sleep_total = scorer.score(tired, action, 0, false, false).total
		elif action.id == "work":
			work_total = scorer.score(tired, action, 0, true, true).total
	assert_gt(sleep_total, work_total, "Cansaço crítico: dormir vence trabalhar, mesmo com rotina e inércia a favor do trabalho.")


func test_the_real_urgency_weights_never_decrease_with_the_level() -> void:
	var params: NpcParams = NpcParamsLoader.load_dir().params
	for level: int in 3:
		assert_true(params.urgency_weight(level) <= params.urgency_weight(level + 1), "Peso do nível %d contra o do nível %d." % [level, level + 1])
	assert_eq(params.urgency_weight(7), params.urgency_weight_critical, "Nível fora de 0 a 3 usa o do crítico.")
