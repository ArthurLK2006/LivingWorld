extends GutTest
## LW-094 (B8, regra da refeição por DADO; autorização de Arthur de 21/11/2026, só em ramo isolado): a condição `eat_hungry` de `data/action_conditions.json`
## (`need_at_least` na fome, 40) faz a `eat` começar só com fome. Catálogo e necessidades REAIS (`res://data`), runner montado como no jogo, sem janela e sem código
## novo: o `ActionRunner` já avaliava `need_at_least`. O efeito no jogo inteiro (refeições por dia, fome, determinismo, saves) está em
## `tests/integration/test_eat_hunger_rule_real_game.gd`.

const VILLAGE: String = "village_a"
const HOME: String = "home_a"
const HUNGER: int = 0
## [HIP] O limiar do dado `eat_hungry`: a atenção da fome (data/needs.json). Mudar o dado exige mudar aqui, de propósito (é uma regra de jogo).
const THRESHOLD: int = 40
## Fome que sobe 5 por hora (data/needs.json): o valor projetado ganha 1 ponto a cada 12 minutos.
const MINUTES_PER_POINT: int = 12

var _states: Dictionary[int, NpcState] = {}
var _provider: FoodProvider
var _runner: ActionRunner


## Provedor de teste: há comida ou não, conforme o teste manda.
class FoodProvider:
	extends ActionConditionProvider

	var food: bool = true

	func has_food(_settlement_id: String) -> bool:
		return food


func before_each() -> void:
	_states = {}
	_provider = FoodProvider.new()
	var catalog: ActionCatalogLoader.LoadResult = ActionCatalogLoader.load_dir()
	var needs: NeedLoader.LoadResult = NeedLoader.load_dir()
	assert_true(catalog.result.ok, catalog.result.message)
	assert_true(needs.result.ok, needs.result.message)
	var settlements: Array[Settlement] = [Settlement.new(VILLAGE, "settlement.a", Vector3(0.0, 0.0, 0.0))]
	var places: Array[Place] = [Place.new(HOME, VILLAGE, Place.KIND_HOME, Vector3(84.0, 0.0, 0.0), 5)]
	_runner = ActionRunner.new(_states, catalog.actions, needs.needs, SettlementService.new(settlements, places), _provider)
	assert_eq(_runner.peek_problem(), "", "O runner com os dados reais deveria servir.")


func _npc(npc_id: int, hunger: int, updated_at: int = 0) -> NpcState:
	var state: NpcState = NpcState.new(npc_id)
	state.need_values = PackedInt64Array([hunger, 0, 0, 0, 0])
	state.needs_updated_at = updated_at
	state.settlement_id = VILLAGE
	state.place_id = HOME
	_states[npc_id] = state
	return state


func test_the_real_catalog_gives_eat_the_food_condition_and_the_hunger_threshold() -> void:
	var eat: ActionDef = null
	for action: ActionDef in ActionCatalogLoader.load_dir().actions:
		if action.id == "eat":
			eat = action
	assert_not_null(eat)
	var kinds: Array[String] = []
	for condition: ActionDef.ActionCondition in eat.conditions:
		kinds.append(condition.kind)
	assert_eq(kinds, [ActionDef.CONDITION_HAS_FOOD, ActionDef.CONDITION_NEED_AT_LEAST] as Array[String], "A `eat` exige comida E fome.")
	var hungry: ActionDef.ActionCondition = eat.conditions[1]
	assert_eq([hungry.need_id, hungry.min_value, hungry.max_value], ["hunger", THRESHOLD, ActionDef.ABSENT], "Fome de %d ou mais, sem máximo." % THRESHOLD)


func test_eat_does_not_start_below_the_threshold_and_starts_at_or_above_it() -> void:
	var cases: Array[Array] = [[0, false], [THRESHOLD - 1, false], [THRESHOLD, true], [THRESHOLD + 1, true], [90, true], [100, true]]
	for index: int in cases.size():
		var npc_id: int = index + 1
		var hunger: int = cases[index][0]
		var state: NpcState = _npc(npc_id, hunger)
		var started: Result = _runner.begin(npc_id, "eat", HOME, 0)
		assert_eq(started.ok, cases[index][1], "Fome %d com comida à mão." % hunger)
		if not started.ok:
			assert_eq(started.code, ActionRunner.CODE_CONDITION_NOT_MET, "A recusa é por condição, não por outro motivo (fome %d)." % hunger)
			assert_string_contains(started.message, "hunger")
			assert_eq(state.action_id, "", "Recusada, a `eat` não deixa o NPC em ação (fome %d)." % hunger)


func test_both_conditions_must_hold_food_and_hunger() -> void:
	_npc(1, 95)
	_provider.food = false
	var no_food: Result = _runner.begin(1, "eat", HOME, 0)
	assert_eq([no_food.ok, no_food.code], [false, ActionRunner.CODE_CONDITION_NOT_MET], "Com muita fome e sem comida a `eat` não começa.")
	_npc(2, THRESHOLD - 1)
	_provider.food = true
	var not_hungry: Result = _runner.begin(2, "eat", HOME, 0)
	assert_eq([not_hungry.ok, not_hungry.code], [false, ActionRunner.CODE_CONDITION_NOT_MET], "Com comida e sem fome a `eat` não começa.")
	_npc(3, THRESHOLD)
	assert_true(_runner.begin(3, "eat", HOME, 0).ok, "Com comida e fome no limiar começa.")


func test_the_threshold_uses_the_hunger_projected_to_the_start_and_a_refusal_stores_nothing() -> void:
	var state: NpcState = _npc(1, THRESHOLD - 1, 100)
	var before: Dictionary = state.to_dict()
	assert_false(_runner.begin(1, "eat", HOME, 100 + MINUTES_PER_POINT - 1).ok, "11 minutos depois a fome projetada ainda é %d." % (THRESHOLD - 1))
	assert_eq(state.to_dict(), before, "A recusa não grava nada no NPC.")
	assert_true(_runner.begin(1, "eat", HOME, 100 + MINUTES_PER_POINT).ok, "12 minutos depois a fome projetada chega ao limiar e a `eat` começa.")
	assert_eq(state.need_values[HUNGER], THRESHOLD, "Começada a ação, o valor projetado é gravado.")


func test_a_meal_that_leaves_the_npc_below_the_threshold_ends_the_hunger_for_the_next_one() -> void:
	var state: NpcState = _npc(1, 70)
	assert_true(_runner.begin(1, "eat", HOME, 0).ok)
	assert_eq(_runner.advance(1, state.action_ends_at).outcome, ActionRunner.Outcome.COMPLETED)
	assert_lt(state.need_values[HUNGER], THRESHOLD, "A refeição de 60 deixa quem tinha 70 abaixo do limiar.")
	assert_false(_runner.begin(1, "eat", HOME, state.needs_updated_at).ok, "Quem acabou de comer e está saciado não come de novo no mesmo bloco.")
