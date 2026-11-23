extends GutTest
## LW-095f: o gancho `ActionConditionProvider.extra_effects` (LW-066) no `ActionRunner`, sem janela. Até a LW-095 ele era coberto pelo teste da renda simbólica provisória (`test_income_stub.gd`, que saiu com ela); este teste
## guarda a MESMA cobertura do mecanismo com um provedor de teste que dá um efeito extra fixo por ofício (o agricultor tira 30 da `income` por trabalho e o lenhador 12; o guarda, nada): o extra entra na mesma conta dos efeitos da tabela
## (completo, proporcional ao progresso quando interrompido, nunca abaixo de 0), só quando o provedor o pede, e um extra numa necessidade inexistente é recusado sem aplicar nada. O alívio da `income` pelo salário é o
## `WageIncome` (`test_wage_income.gd`).

const VILLAGE: String = "village_a"
const HOME: String = "home_a"
const WORK: String = "work_a"
const NEED_IDS: Array[String] = ["hunger", "rest", "safety", "income", "social"]
const REST: int = 1
const INCOME: int = 3
const HOME_CM: int = 8400


func _need_defs() -> Array[NeedDef]:
	var defs: Array[NeedDef] = []
	for position: int in NEED_IDS.size():
		defs.append(NeedDef.new(NEED_IDS[position], position, 30 if position == INCOME else 0, 0, 40, 65, 90))
	return defs


func _catalog() -> Array[ActionDef]:
	var work: ActionDef = ActionDef.new("work", 240, "work", 5, true)
	work.effects.append(ActionDef.ActionEffect.new("rest", 5))
	return [work, ActionDef.new("wait", 10, "", 0, true), ActionDef.new(ActionRunner.GO_TO_PLACE_ID, 0, "", 0, true)]


func _places() -> SettlementService:
	var settlements: Array[Settlement] = [Settlement.new(VILLAGE, "settlement.a", Vector3.ZERO)]
	var places: Array[Place] = [Place.new(HOME, VILLAGE, Place.KIND_HOME, Vector3(84.0, 0.0, 0.0), 5), Place.new(WORK, VILLAGE, Place.KIND_WORK, Vector3(184.0, 0.0, 0.0), 5)]
	return SettlementService.new(settlements, places)


## Provedor que dá um efeito extra fixo ao `work` de dois ofícios.
class ReliefProvider:
	extends ActionConditionProvider

	func extra_effects(action_id: String, occupation_id: String) -> Array[ActionDef.ActionEffect]:
		var effects: Array[ActionDef.ActionEffect] = []
		var relief: int = {"farmer": 30, "lumberjack": 12}.get(occupation_id, 0)
		if action_id == "work" and relief > 0:
			effects.append(ActionDef.ActionEffect.new("income", -relief))
		return effects


## Provedor que pede um efeito extra numa necessidade que não existe.
class GhostProvider:
	extends ActionConditionProvider

	func extra_effects(_action_id: String, _occupation_id: String) -> Array[ActionDef.ActionEffect]:
		return [ActionDef.ActionEffect.new("ghost", -5)]


class RunnerParts:
	extends RefCounted

	var runner: ActionRunner
	var states: Dictionary[int, NpcState] = {}


func _runner_parts(provider: ActionConditionProvider) -> RunnerParts:
	var parts: RunnerParts = RunnerParts.new()
	parts.runner = ActionRunner.new(parts.states, _catalog(), _need_defs(), _places(), provider)
	assert_eq(parts.runner.peek_problem(), "")
	return parts


func _add_npc(parts: RunnerParts, npc_id: int, occupation_id: String, income: int = 80) -> NpcState:
	var state: NpcState = NpcState.new(npc_id)
	state.occupation_id = occupation_id
	state.settlement_id = VILLAGE
	state.place_id = HOME
	state.x_cm = HOME_CM
	state.need_values = PackedInt64Array([0, 10, 0, income, 0])
	parts.states[npc_id] = state
	return state


func test_a_completed_action_takes_the_extra_effect_and_the_table_effect_still_applies() -> void:
	var parts: RunnerParts = _runner_parts(ReliefProvider.new())
	var farmer: NpcState = _add_npc(parts, 1, "farmer", 80)
	assert_true(parts.runner.begin(1, "work", WORK, 100).ok)
	assert_eq(parts.runner.advance(1, 339).outcome, ActionRunner.Outcome.RUNNING)
	assert_eq(farmer.need_values[INCOME], 80, "Trabalhando ainda não aplica.")
	assert_eq(parts.runner.advance(1, 340).outcome, ActionRunner.Outcome.COMPLETED)
	assert_eq(farmer.need_values[INCOME], 50, "80 - 30.")
	assert_eq(farmer.need_values[REST], 15, "O efeito da tabela de ações (+5 de cansaço) continua valendo.")
	var lumberjack: NpcState = _add_npc(parts, 2, "lumberjack", 80)
	assert_true(parts.runner.begin(2, "work", WORK, 400).ok)
	assert_eq(parts.runner.advance(2, 640).outcome, ActionRunner.Outcome.COMPLETED)
	assert_eq(lumberjack.need_values[INCOME], 68, "80 - 12: o extra é por ofício.")


func test_an_interrupted_action_applies_the_extra_in_proportion_to_the_time_done() -> void:
	# Ação de 240 minutos, extra -30: progresso = piso de (minutos x 1000 / 240), no máximo 999; o efeito é o piso de (-30 x progresso / 1000), que num valor negativo arredonda para MAIS alívio (125 -> -3,75 -> -4).
	var worked: Array[int] = [0, 30, 120, 239, 240]
	var expected: Array[int] = [80, 76, 65, 50, 50]
	for index: int in worked.size():
		var parts: RunnerParts = _runner_parts(ReliefProvider.new())
		var farmer: NpcState = _add_npc(parts, 1, "farmer", 80)
		assert_true(parts.runner.begin(1, "work", WORK, 100).ok)
		assert_true(parts.runner.interrupt(1, 100 + worked[index]).ok)
		assert_eq(farmer.need_values[INCOME], expected[index], "Interrompido após %d de 240 minutos." % worked[index])


func test_only_what_the_provider_asks_is_applied_and_without_a_provider_nothing_extra() -> void:
	var parts: RunnerParts = _runner_parts(ReliefProvider.new())
	var guard: NpcState = _add_npc(parts, 1, "guard", 80)
	var idler: NpcState = _add_npc(parts, 2, "farmer", 80)
	assert_true(parts.runner.begin(1, "work", WORK, 100).ok)
	assert_eq(parts.runner.advance(1, 340).outcome, ActionRunner.Outcome.COMPLETED)
	assert_eq(guard.need_values[INCOME], 80, "Sem extra para o guarda.")
	assert_true(parts.runner.begin(2, "wait", "", 100).ok)
	assert_eq(parts.runner.advance(2, 110).outcome, ActionRunner.Outcome.COMPLETED)
	assert_eq(idler.need_values[INCOME], 80, "Sem extra para outra ação.")
	var bare: RunnerParts = _runner_parts(null)
	var farmer: NpcState = _add_npc(bare, 3, "farmer", 80)
	assert_true(bare.runner.begin(3, "work", WORK, 100).ok)
	assert_eq(bare.runner.advance(3, 340).outcome, ActionRunner.Outcome.COMPLETED)
	assert_eq(farmer.need_values[INCOME], 80, "Sem provedor, nenhum extra.")


func test_an_extra_effect_never_takes_a_need_below_zero() -> void:
	var parts: RunnerParts = _runner_parts(ReliefProvider.new())
	var farmer: NpcState = _add_npc(parts, 1, "farmer", 10)
	assert_true(parts.runner.begin(1, "work", WORK, 100).ok)
	assert_eq(parts.runner.advance(1, 340).outcome, ActionRunner.Outcome.COMPLETED)
	assert_eq(farmer.need_values[INCOME], 0, "10 - 30 fica em 0, não em -20.")


func test_an_extra_effect_on_an_unknown_need_is_refused_without_applying_anything() -> void:
	var parts: RunnerParts = _runner_parts(GhostProvider.new())
	var farmer: NpcState = _add_npc(parts, 1, "farmer", 80)
	var before: Dictionary = farmer.to_dict()
	var refused: Result = parts.runner.apply_effects(1, "work", WORK, ActionRunner.FULL_PROGRESS)
	assert_false(refused.ok)
	assert_eq(refused.code, ActionRunner.CODE_UNKNOWN_NEED)
	assert_string_contains(refused.message, "'ghost'")
	assert_eq(farmer.to_dict(), before, "Nem o efeito da tabela (+5 de cansaço) foi aplicado: tudo ou nada.")
