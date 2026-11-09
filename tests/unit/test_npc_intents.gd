extends GutTest
## LW-070: protocolo Intent e ActionResult do modo S0 (docs/modules/npc.md, seção 6), sem janela e com uma "apresentação simulada": o
## próprio teste cumpre as intenções e devolve os resultados. Mundo montado pelo SimulationRunner (relógio, agendador e eventos de
## verdade). Catálogo, necessidades e locais feitos à mão para os números esperados serem calculados na mão: taxas de necessidade zero
## (salvo onde o teste compara S0 com S1), `eat` de 20 min que alivia 60 de fome, `wait` de 10 min, `go_to_place` por distância
## (8400 cm/min: 3000 cm = 1 min; 14000 cm = 2 min). O tempo limite do Intent é 30 min nos testes (o valor real está em
## data/intent_params.json). Um passo do relógio = 1 minuto.

const WORLD_SEED: int = 3
const ACTOR_ID: int = 77
const OTHER_ACTOR_ID: int = 78
const FOCUS_M: Vector3 = Vector3(1000.0, 10.0, 500.0)
const VILLAGE: String = "village_a"
const HOME: String = "home_a"
const WORK: String = "work_a"
const FAR: String = "far_a"
const HOME_CM: Vector2i = Vector2i(101000, 50000)
const WORK_CM: Vector2i = Vector2i(104000, 50000)
const AWAY_X_CM: int = 160000
const NEED_IDS: Array[String] = ["hunger", "rest", "safety", "income", "social"]
const HUNGER: int = 0
const START_HUNGER: int = 80
const EAT_RELIEF: int = -60
const EAT_MIN: int = 20
const WAIT_MIN: int = 10
const TIMEOUT_MIN: int = 30
const NO_RATES: Array[int] = [0, 0, 0, 0, 0]
const HUNGER_RATE: Array[int] = [6, 0, 0, 0, 0]
const BODY_AT_HOME_M: Vector3 = Vector3(1010.0, 0.0, 500.0)
const S0: int = NpcLod.LEVEL_S0
const S1: int = NpcLod.LEVEL_S1
const TEMP_ROOT: String = "res://.godot/lw070_intent_params_tests"

var _rigs: Array[Rig] = []
var _temp_dirs: Array[String] = []


## Provedor de teste: responde o que o teste mandar.
class FakeProvider:
	extends ActionConditionProvider

	var food: bool = true

	func has_food(_settlement_id: String) -> bool:
		return food


## Um mundo de teste: o runner do mundo, o módulo, o ActionRunner (S1) e os LodChanged que chegaram.
class Rig:
	extends RefCounted

	var runner: SimulationRunner
	var module: NpcModule
	var actions: ActionRunner
	var provider: FakeProvider
	var changes: Array[LodChanged] = []

	func on_lod_changed(event: SimEvent) -> void:
		changes.append(event as LodChanged)

	func now() -> int:
		return runner.world.context.clock.total_minutes()


func after_each() -> void:
	for rig: Rig in _rigs:
		rig.runner.finish()
	_rigs.clear()
	for dir_path: String in _temp_dirs:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(dir_path.path_join(NpcIntentParams.DEFAULT_FILE)))
		DirAccess.remove_absolute(ProjectSettings.globalize_path(dir_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP_ROOT))
	_temp_dirs.clear()


# ---------------------------------------------------------------------------------------------------- montagem

func _need_defs(rates: Array[int]) -> Array[NeedDef]:
	var defs: Array[NeedDef] = []
	for position: int in NEED_IDS.size():
		var start_value: int = START_HUNGER if position == HUNGER else 0
		defs.append(NeedDef.new(NEED_IDS[position], position, start_value, rates[position], 40, 65, 90))
	return defs


func _catalog() -> Array[ActionDef]:
	var eat: ActionDef = ActionDef.new("eat", EAT_MIN, "", 0, true)
	eat.effects.append(ActionDef.ActionEffect.new("hunger", EAT_RELIEF))
	eat.conditions.append(ActionDef.ActionCondition.new(ActionDef.CONDITION_HAS_FOOD, "", ActionDef.ABSENT, ActionDef.ABSENT))
	var wait: ActionDef = ActionDef.new("wait", WAIT_MIN, "", 0, true)
	var go: ActionDef = ActionDef.new(ActionRunner.GO_TO_PLACE_ID, 0, "", 0, true)
	var catalog: Array[ActionDef] = [eat, wait, go]
	return catalog


func _places() -> SettlementService:
	var settlements: Array[Settlement] = [Settlement.new(VILLAGE, "settlement.a", Vector3(1000.0, 0.0, 500.0))]
	var places: Array[Place] = [
		Place.new(HOME, VILLAGE, Place.KIND_HOME, Vector3(1010.0, 0.0, 500.0), 5),
		Place.new(WORK, VILLAGE, Place.KIND_WORK, Vector3(1040.0, 0.0, 500.0), 10),
		Place.new(FAR, VILLAGE, Place.KIND_REST, Vector3(1180.0, 0.0, 500.0), 3),
	]
	return SettlementService.new(settlements, places)


## Mundo com o módulo `npc` registrado, LOD com os parâmetros reais (80 m, 120 m, 50) e, se `configured`, o protocolo ligado.
func _rig(rates: Array[int] = NO_RATES, configured: bool = true) -> Rig:
	var rig: Rig = Rig.new()
	rig.provider = FakeProvider.new()
	rig.module = NpcModule.new(_need_defs(rates))
	var lod_loaded: LodParamsLoader.LoadResult = LodParamsLoader.load_dir()
	assert_true(rig.module.lod.configure(lod_loaded.params).ok, lod_loaded.result.message)
	rig.runner = SimulationRunner.new(WORLD_SEED)
	assert_true(rig.runner.register_module("npc", rig.module).ok)
	rig.runner.world.context.events.subscribe("LodChanged", rig.on_lod_changed)
	rig.runner.start_new_game()
	var places: SettlementService = _places()
	rig.actions = rig.module.create_action_runner(_catalog(), places, rig.provider)
	assert_eq(rig.actions.peek_problem(), "", "O runner de teste deveria servir.")
	if configured:
		var linked: Result = rig.module.configure_intents(rig.actions, places, NpcIntentParams.new(TIMEOUT_MIN))
		assert_true(linked.ok, linked.message)
	_rigs.append(rig)
	return rig


func _create(rig: Rig, x_cm: int, z_cm: int) -> int:
	var spec: NpcSpec = NpcSpec.new()
	spec.name_key = "npc.name.villager"
	spec.x_cm = x_cm
	spec.z_cm = z_cm
	spec.settlement_id = VILLAGE
	spec.place_id = HOME
	var created: NpcModule.CreateResult = rig.module.request_create_npc(spec)
	assert_true(created.result.ok, created.result.message)
	return created.npc_id


## NPC em casa, a 10 m do foco: o primeiro passo o põe em S0 (e o relógio vai a 1).
func _s0_npc(rig: Rig) -> int:
	var npc_id: int = _create(rig, HOME_CM.x, HOME_CM.y)
	assert_true(rig.module.request_set_focus(ACTOR_ID, FOCUS_M).ok)
	rig.runner.step_once()
	assert_eq(rig.module.lod.level_of(npc_id), S0, "O NPC a 10 m do foco deveria estar em S0.")
	return npc_id


## NPC a 600 m do foco: fica em S1.
func _far_npc(rig: Rig) -> int:
	return _create(rig, AWAY_X_CM, HOME_CM.y)


func _begin(rig: Rig, npc_id: int, action_id: String, place_id: String) -> Result:
	return rig.module.intents.begin_embodied(npc_id, action_id, place_id, rig.now())


func _outcome(npc_id: int, serial: int, outcome: NpcActionResult.Outcome, body_m: Vector3 = BODY_AT_HOME_M) -> NpcActionResult:
	return NpcActionResult.new(npc_id, serial, outcome, body_m)


func _hunger(rig: Rig, npc_id: int) -> int:
	return rig.module.peek_npc(npc_id).need_values[HUNGER]


# ---------------------------------------------------------------------------------------------------- Intent emitido, efeito só depois

func test_starting_an_action_in_s0_emits_the_intent_and_applies_no_effect() -> void:
	var rig: Rig = _rig()
	var npc_id: int = _s0_npc(rig)
	var started: Result = _begin(rig, npc_id, "eat", HOME)
	assert_true(started.ok, started.message)
	var intents: Array[NpcIntent] = rig.module.peek_pending_intents()
	assert_eq(intents.size(), 1)
	var intent: NpcIntent = intents[0]
	assert_eq([intent.npc_id, intent.action_serial, intent.kind, intent.place_id], [npc_id, 1, NpcIntent.Kind.ACT_AT_PLACE, HOME])
	assert_eq(intent.destination_cm, HOME_CM, "O destino é o centro do local, em centímetros.")
	assert_eq(intent.expected_minutes, EAT_MIN, "A duração esperada é a da ação.")
	var npc: NpcModule.NpcQuery = rig.module.peek_npc(npc_id)
	assert_eq(npc.action_id, "eat", "A ação começou (o runner fixou o fim).")
	assert_eq(npc.action_ends_at, 1 + EAT_MIN)
	assert_eq(npc.need_values[HUNGER], START_HUNGER, "Os efeitos NÃO entram ao emitir o Intent: só com o resultado de sucesso.")


func test_a_move_action_emits_move_to_place_with_the_place_center_and_the_travel_time() -> void:
	var rig: Rig = _rig()
	var npc_id: int = _s0_npc(rig)
	assert_true(_begin(rig, npc_id, ActionRunner.GO_TO_PLACE_ID, WORK).ok)
	var intent: NpcIntent = rig.module.peek_pending_intents()[0]
	assert_eq(intent.kind, NpcIntent.Kind.MOVE_TO_PLACE)
	assert_eq(intent.destination_cm, WORK_CM)
	assert_eq(intent.expected_minutes, 1, "3000 cm a 8400 cm por minuto: 1 minuto (no mínimo).")
	assert_true(rig.module.request_report_npc_result(_outcome(npc_id, 1, NpcActionResult.Outcome.ARRIVED)).ok)
	assert_eq(rig.actions.advance(npc_id, rig.now()).outcome, ActionRunner.Outcome.COMPLETED, "O pensamento seguinte encerra a ação que o relato marcou (LW-070d).")
	assert_true(_begin(rig, npc_id, ActionRunner.GO_TO_PLACE_ID, FAR).ok)
	var longer: NpcIntent = rig.module.peek_pending_intents()[0]
	assert_eq([longer.expected_minutes, longer.action_serial], [2, 2], "Do centro do trabalho (104000) a FAR (118000): 14000 cm a 8400 por minuto, arredondado para cima, 2 minutos; é a segunda ação do NPC.")


func test_an_action_without_a_place_aims_at_the_current_body_position() -> void:
	var rig: Rig = _rig()
	var npc_id: int = _s0_npc(rig)
	assert_true(_begin(rig, npc_id, "wait", "").ok)
	var intent: NpcIntent = rig.module.peek_pending_intents()[0]
	assert_eq([intent.place_id, intent.destination_cm, intent.expected_minutes], ["", HOME_CM, WAIT_MIN])


func test_a_success_result_applies_the_effects_once_and_frees_the_npc() -> void:
	var rig: Rig = _rig()
	var npc_id: int = _s0_npc(rig)
	assert_true(_begin(rig, npc_id, "eat", HOME).ok)
	rig.runner.run_steps(EAT_MIN)
	var body_m: Vector3 = Vector3(1012.34, 0.0, 500.56)
	var reported: Result = rig.module.request_report_npc_result(_outcome(npc_id, 1, NpcActionResult.Outcome.DONE, body_m))
	assert_true(reported.ok, reported.message)
	assert_eq(_hunger(rig, npc_id), START_HUNGER, "O relato só marca o fim: nenhum efeito ainda (LW-070d).")
	assert_eq(rig.actions.advance(npc_id, rig.now()).outcome, ActionRunner.Outcome.COMPLETED, "O pensamento seguinte encerra a ação: os efeitos entram agora.")
	var npc: NpcModule.NpcQuery = rig.module.peek_npc(npc_id)
	assert_eq(npc.need_values[HUNGER], START_HUNGER + EAT_RELIEF, "80 menos 60 da refeição, uma só vez.")
	assert_eq(npc.action_id, "", "O NPC fica livre para pensar de novo.")
	assert_eq(npc.needs_updated_at, 1 + EAT_MIN)
	assert_eq(rig.module.peek_pending_intents().size(), 0, "O Intent foi cumprido.")
	assert_eq(rig.module.lod.position_of(npc_id), Vector2i(101234, 50056), "A posição final vira o último relato do corpo.")
	var again: Result = rig.module.request_report_npc_result(_outcome(npc_id, 1, NpcActionResult.Outcome.DONE, body_m))
	assert_eq(again.code, NpcIntentBoard.CODE_STALE_RESULT, "O mesmo resultado de novo não aplica o efeito duas vezes.")
	assert_eq(_hunger(rig, npc_id), START_HUNGER + EAT_RELIEF)


func test_arriving_moves_the_logical_position_to_the_place_and_the_body_keeps_its_own() -> void:
	var rig: Rig = _rig()
	var npc_id: int = _s0_npc(rig)
	assert_true(_begin(rig, npc_id, ActionRunner.GO_TO_PLACE_ID, WORK).ok)
	rig.runner.step_once()
	var arrived: Result = rig.module.request_report_npc_result(_outcome(npc_id, 1, NpcActionResult.Outcome.ARRIVED, Vector3(1039.6, 0.0, 500.2)))
	assert_true(arrived.ok, arrived.message)
	assert_eq(rig.actions.advance(npc_id, rig.now()).outcome, ActionRunner.Outcome.COMPLETED, "O pensamento seguinte encerra a ação que o relato marcou (LW-070d).")
	var npc: NpcModule.NpcQuery = rig.module.peek_npc(npc_id)
	assert_eq([npc.x_cm, npc.z_cm, npc.place_id], [WORK_CM.x, WORK_CM.y, WORK], "A chegada põe o NPC no centro do local, como no modo S1.")
	assert_eq(npc.action_id, "")
	assert_eq(rig.module.lod.position_of(npc_id), Vector2i(103960, 50020), "O corpo fica onde parou.")


# ---------------------------------------------------------------------------------------------------- S0 igual a S1

func test_s0_and_s1_leave_the_same_needs_whether_the_result_is_on_time_or_late() -> void:
	for lateness: int in [0, 5]:
		var rig: Rig = _rig(HUNGER_RATE)
		var in_s1: int = _far_npc(rig)
		var in_s0: int = _s0_npc(rig)
		assert_true(_begin(rig, in_s0, "eat", HOME).ok)
		assert_true(rig.actions.begin(in_s1, "eat", HOME, rig.now()).ok)
		rig.runner.run_steps(EAT_MIN + lateness)
		assert_true(rig.module.request_report_npc_result(_outcome(in_s0, 1, NpcActionResult.Outcome.DONE)).ok)
		assert_eq(rig.actions.advance(in_s0, rig.now()).outcome, ActionRunner.Outcome.COMPLETED, "O pensamento seguinte encerra a ação que o relato marcou (LW-070d).")
		assert_eq(rig.actions.advance(in_s1, rig.now()).outcome, ActionRunner.Outcome.COMPLETED)
		var embodied: NpcModule.NpcQuery = rig.module.peek_npc(in_s0)
		var abstract: NpcModule.NpcQuery = rig.module.peek_npc(in_s1)
		assert_eq(embodied.need_values, abstract.need_values, "Mesma função de efeitos: S0 e S1 deixam as mesmas necessidades (atraso %d)." % lateness)
		assert_eq(embodied.needs_updated_at, abstract.needs_updated_at, "O efeito entra no fim planejado, não importa o atraso (atraso %d)." % lateness)
		assert_eq(embodied.action_serial, abstract.action_serial)


func test_a_result_before_the_planned_end_finishes_the_action_at_that_minute() -> void:
	var rig: Rig = _rig()
	var npc_id: int = _s0_npc(rig)
	assert_true(_begin(rig, npc_id, "eat", HOME).ok)
	rig.runner.run_steps(10)
	assert_true(rig.module.request_report_npc_result(_outcome(npc_id, 1, NpcActionResult.Outcome.DONE)).ok)
	assert_eq(rig.actions.advance(npc_id, rig.now()).outcome, ActionRunner.Outcome.COMPLETED, "O pensamento seguinte encerra a ação que o relato marcou (LW-070d).")
	var npc: NpcModule.NpcQuery = rig.module.peek_npc(npc_id)
	assert_eq(npc.need_values[HUNGER], START_HUNGER + EAT_RELIEF)
	assert_eq(npc.needs_updated_at, rig.now(), "A ação acabou antes do planejado: as necessidades vão só até agora.")
	assert_eq(npc.action_id, "")


# ---------------------------------------------------------------------------------------------------- BLOCKED e CANCELLED

func test_blocked_and_cancelled_results_cancel_the_action_without_any_effect() -> void:
	for outcome: NpcActionResult.Outcome in [NpcActionResult.Outcome.BLOCKED, NpcActionResult.Outcome.CANCELLED]:
		var rig: Rig = _rig()
		var npc_id: int = _s0_npc(rig)
		assert_true(_begin(rig, npc_id, "eat", HOME).ok)
		rig.runner.run_steps(5)
		var reported: Result = rig.module.request_report_npc_result(_outcome(npc_id, 1, outcome, Vector3(1011.0, 0.0, 500.0)))
		assert_true(reported.ok, reported.message)
		var npc: NpcModule.NpcQuery = rig.module.peek_npc(npc_id)
		assert_eq(npc.need_values[HUNGER], START_HUNGER, "Sem efeito nenhum (%d)." % outcome)
		assert_eq(npc.needs_updated_at, 1, "As necessidades nem foram tocadas.")
		assert_eq(npc.action_id, "", "O NPC está livre para pensar de novo.")
		assert_eq(rig.module.peek_pending_intents().size(), 0)
		assert_eq(rig.module.lod.position_of(npc_id), Vector2i(101100, 50000), "O corpo parou onde disse.")
		assert_true(_begin(rig, npc_id, "wait", HOME).ok, "Livre para começar outra ação.")
		assert_eq(rig.module.peek_npc(npc_id).action_serial, 2)


# ---------------------------------------------------------------------------------------------------- serial velho e resultado tardio

func test_a_result_for_an_old_action_serial_is_discarded_and_counted() -> void:
	var rig: Rig = _rig()
	var npc_id: int = _s0_npc(rig)
	assert_true(_begin(rig, npc_id, "eat", HOME).ok)
	assert_true(rig.module.request_report_npc_result(_outcome(npc_id, 1, NpcActionResult.Outcome.BLOCKED)).ok)
	assert_true(_begin(rig, npc_id, "wait", HOME).ok)
	var stale: Result = rig.module.request_report_npc_result(_outcome(npc_id, 1, NpcActionResult.Outcome.DONE))
	assert_false(stale.ok)
	assert_eq(stale.code, NpcIntentBoard.CODE_STALE_RESULT)
	assert_string_contains(stale.message, "ação 1")
	assert_eq(rig.module.peek_npc(npc_id).action_id, "wait", "O resultado velho não mexeu na ação nova.")
	assert_eq(rig.module.peek_pending_intents()[0].action_serial, 2)
	assert_eq(rig.module.intents.debug_summary()["discarded_results"], 1, "Descartado e contado.")
	assert_true(rig.module.request_report_npc_result(_outcome(npc_id, 2, NpcActionResult.Outcome.DONE)).ok, "O resultado da ação certa vale.")


func test_a_result_for_an_unknown_npc_or_a_npc_without_intent_is_discarded() -> void:
	var rig: Rig = _rig()
	var npc_id: int = _s0_npc(rig)
	var unknown: Result = rig.module.request_report_npc_result(_outcome(999, 1, NpcActionResult.Outcome.DONE))
	assert_eq(unknown.code, NpcIntentBoard.CODE_STALE_RESULT)
	var idle: Result = rig.module.request_report_npc_result(_outcome(npc_id, 1, NpcActionResult.Outcome.DONE))
	assert_eq(idle.code, NpcIntentBoard.CODE_STALE_RESULT)
	assert_eq(rig.module.intents.debug_summary()["discarded_results"], 2)
	assert_eq(_hunger(rig, npc_id), START_HUNGER)


func test_without_a_result_the_intent_times_out_and_the_npc_is_free_with_no_effect() -> void:
	var rig: Rig = _rig()
	var npc_id: int = _s0_npc(rig)
	assert_true(_begin(rig, npc_id, "eat", HOME).ok)
	var deadline: int = 1 + EAT_MIN + TIMEOUT_MIN
	rig.runner.run_steps(deadline - 1 - rig.now())
	assert_eq(rig.now(), deadline - 1)
	assert_eq(rig.module.peek_pending_intents().size(), 1, "Um minuto antes do limite o Intent ainda espera.")
	rig.runner.step_once()
	assert_eq(rig.now(), deadline)
	assert_eq(rig.module.peek_pending_intents().size(), 0, "No minuto do limite o Intent venceu.")
	var npc: NpcModule.NpcQuery = rig.module.peek_npc(npc_id)
	assert_eq(npc.action_id, "", "A ação foi cancelada: o NPC pode pensar de novo.")
	assert_eq(npc.need_values[HUNGER], START_HUNGER, "Cancelada por tempo: sem efeito.")
	assert_eq(rig.module.intents.debug_summary()["timed_out_intents"], 1)
	var late: Result = rig.module.request_report_npc_result(_outcome(npc_id, 1, NpcActionResult.Outcome.DONE))
	assert_eq(late.code, NpcIntentBoard.CODE_STALE_RESULT, "Resultado tardio é ignorado.")
	assert_eq(_hunger(rig, npc_id), START_HUNGER)
	assert_true(_begin(rig, npc_id, "wait", HOME).ok, "O NPC não ficou preso.")


func test_expire_reports_who_timed_out_at_the_exact_limit_minute() -> void:
	var rig: Rig = _rig()
	var npc_id: int = _s0_npc(rig)
	assert_true(_begin(rig, npc_id, "eat", HOME).ok)
	var deadline: int = 1 + EAT_MIN + TIMEOUT_MIN
	assert_eq(rig.module.intents.expire(deadline - 1), [] as Array[int])
	assert_eq(rig.module.peek_pending_intents().size(), 1)
	assert_eq(rig.module.intents.expire(deadline), [npc_id] as Array[int], "A partir do minuto fim + limite o Intent venceu.")
	assert_eq(rig.module.peek_pending_intents().size(), 0)
	assert_eq(rig.module.intents.expire(deadline + 1), [] as Array[int], "Nada pendente: nada a vencer.")


# ---------------------------------------------------------------------------------------------------- erros

func test_an_outcome_that_does_not_match_the_intent_kind_is_refused_and_the_intent_stays() -> void:
	var rig: Rig = _rig()
	var npc_id: int = _s0_npc(rig)
	assert_true(_begin(rig, npc_id, "eat", HOME).ok)
	var wrong: Result = rig.module.request_report_npc_result(_outcome(npc_id, 1, NpcActionResult.Outcome.ARRIVED))
	assert_eq(wrong.code, NpcIntentBoard.CODE_OUTCOME_MISMATCH)
	assert_eq(rig.module.peek_pending_intents().size(), 1, "O Intent continua pendente.")
	assert_eq([rig.module.peek_npc(npc_id).action_id, _hunger(rig, npc_id)], ["eat", START_HUNGER])
	assert_true(rig.module.request_report_npc_result(_outcome(npc_id, 1, NpcActionResult.Outcome.DONE)).ok)
	assert_eq(rig.actions.advance(npc_id, rig.now()).outcome, ActionRunner.Outcome.COMPLETED, "O pensamento seguinte encerra a ação que o relato marcou (LW-070d).")
	assert_true(_begin(rig, npc_id, ActionRunner.GO_TO_PLACE_ID, WORK).ok)
	var other: Result = rig.module.request_report_npc_result(_outcome(npc_id, 2, NpcActionResult.Outcome.DONE))
	assert_eq(other.code, NpcIntentBoard.CODE_OUTCOME_MISMATCH, "DONE não vale para MOVE_TO_PLACE.")


func test_malformed_results_are_refused_with_a_code_and_change_nothing() -> void:
	var rig: Rig = _rig()
	var npc_id: int = _s0_npc(rig)
	assert_true(_begin(rig, npc_id, "eat", HOME).ok)
	var raw_outcome: int = 9
	var cases: Array[NpcActionResult] = [
		null,
		_outcome(0, 1, NpcActionResult.Outcome.DONE),
		_outcome(npc_id, 0, NpcActionResult.Outcome.DONE),
		_outcome(npc_id, 1, raw_outcome as NpcActionResult.Outcome),
	]
	for malformed: NpcActionResult in cases:
		var refused: Result = rig.module.request_report_npc_result(malformed)
		assert_eq(refused.code, NpcIntentBoard.CODE_INVALID_RESULT, refused.message)
	for bad_body_m: Vector3 in [Vector3(NAN, 0.0, 500.0), Vector3(-1.0, 0.0, 500.0), Vector3(1000.0, 0.0, 100001.0), Vector3(INF, 0.0, 0.0)]:
		var bad_position: Result = rig.module.request_report_npc_result(_outcome(npc_id, 1, NpcActionResult.Outcome.DONE, bad_body_m))
		assert_eq(bad_position.code, NpcLod.CODE_INVALID_POSITION, str(bad_body_m))
	assert_eq(rig.module.peek_pending_intents().size(), 1, "Nada disso consumiu o Intent.")
	assert_eq([rig.module.peek_npc(npc_id).action_id, _hunger(rig, npc_id)], ["eat", START_HUNGER])


func test_a_npc_outside_s0_an_unknown_npc_and_an_unknown_place_refuse_to_start_and_change_nothing() -> void:
	var rig: Rig = _rig()
	var in_s0: int = _s0_npc(rig)
	var in_s1: int = _far_npc(rig)
	var outside: Result = _begin(rig, in_s1, "wait", HOME)
	assert_eq(outside.code, NpcLod.CODE_NOT_IN_S0, "NPC sem corpo usa o runner abstrato.")
	assert_eq(_begin(rig, 999, "wait", HOME).code, ActionRunner.CODE_UNKNOWN_NPC)
	assert_eq(_begin(rig, in_s0, "wait", "nowhere").code, ActionRunner.CODE_PLACE_UNKNOWN)
	assert_eq(_begin(rig, in_s0, ActionRunner.GO_TO_PLACE_ID, "").code, ActionRunner.CODE_PLACE_UNKNOWN, "Ir a lugar nenhum não faz sentido.")
	for npc_id: int in [in_s0, in_s1]:
		var npc: NpcModule.NpcQuery = rig.module.peek_npc(npc_id)
		assert_eq([npc.action_id, npc.action_serial], ["", 0], "Recusa não deixa a ação pela metade.")
	assert_eq(rig.module.peek_pending_intents().size(), 0)


func test_runner_refusals_pass_through_and_leave_no_second_intent() -> void:
	var rig: Rig = _rig()
	var npc_id: int = _s0_npc(rig)
	rig.provider.food = false
	var hungry: Result = _begin(rig, npc_id, "eat", HOME)
	assert_eq(hungry.code, ActionRunner.CODE_CONDITION_NOT_MET)
	assert_eq(rig.module.peek_pending_intents().size(), 0)
	assert_true(_begin(rig, npc_id, "wait", HOME).ok)
	var busy: Result = _begin(rig, npc_id, "wait", HOME)
	assert_eq(busy.code, ActionRunner.CODE_BUSY)
	var intents: Array[NpcIntent] = rig.module.peek_pending_intents()
	assert_eq([intents.size(), intents[0].action_serial], [1, 1], "O primeiro Intent segue intacto.")


func test_the_runner_guards_cancel_and_mark_the_end_by_action_serial() -> void:
	var rig: Rig = _rig()
	var npc_id: int = _s0_npc(rig)
	assert_true(_begin(rig, npc_id, "eat", HOME).ok)
	assert_eq(rig.actions.cancel_action(npc_id, 99).code, ActionRunner.CODE_STALE_ACTION)
	assert_eq(rig.actions.mark_embodied_end(npc_id, 99, rig.now()).result.code, ActionRunner.CODE_STALE_ACTION)
	assert_eq(rig.module.peek_npc(npc_id).action_id, "eat", "Contador errado não mexe na ação.")
	assert_eq(rig.actions.cancel_action(999, 1).code, ActionRunner.CODE_UNKNOWN_NPC)
	assert_true(rig.actions.cancel_action(npc_id, 1).ok)
	assert_eq(rig.actions.cancel_action(npc_id, 1).code, ActionRunner.CODE_STALE_ACTION, "Sem ação, nada a cancelar.")
	assert_eq(rig.actions.mark_embodied_end(npc_id, 1, rig.now()).outcome, ActionRunner.Outcome.NONE)


func test_an_unconfigured_protocol_fails_visibly_and_changes_nothing() -> void:
	var rig: Rig = _rig(NO_RATES, false)
	var npc_id: int = _s0_npc(rig)
	assert_eq(_begin(rig, npc_id, "wait", HOME).code, NpcIntentBoard.CODE_NOT_CONFIGURED)
	var reported: Result = rig.module.request_report_npc_result(_outcome(npc_id, 1, NpcActionResult.Outcome.DONE))
	assert_eq(reported.code, NpcIntentBoard.CODE_NOT_CONFIGURED)
	assert_eq(rig.module.peek_pending_intents().size(), 0)
	assert_eq(rig.module.intents.expire(1000), [] as Array[int])
	assert_eq(rig.module.peek_npc(npc_id).action_serial, 0)
	rig.runner.run_steps(3)


func test_configure_refuses_a_bad_runner_or_bad_parameters_and_stays_off() -> void:
	var rig: Rig = _rig(NO_RATES, false)
	var places: SettlementService = _places()
	var good: NpcIntentParams = NpcIntentParams.new(TIMEOUT_MIN)
	assert_eq(rig.module.configure_intents(null, places, good).code, NpcIntentBoard.CODE_NOT_CONFIGURED)
	assert_eq(rig.module.configure_intents(rig.actions, places, null).code, NpcIntentBoard.CODE_NOT_CONFIGURED)
	var no_defs: NpcModule = NpcModule.new()
	var broken_runner: ActionRunner = no_defs.create_action_runner(_catalog(), places)
	assert_false(broken_runner.peek_problem().is_empty(), "Sem definições de necessidade o runner não serve.")
	assert_eq(rig.module.configure_intents(broken_runner, places, good).code, NpcIntentBoard.CODE_NOT_CONFIGURED)
	for bad_minutes: int in [0, NpcIntentParams.MAX_TIMEOUT_MIN + 1, -5]:
		var refused: Result = rig.module.configure_intents(rig.actions, places, NpcIntentParams.new(bad_minutes))
		assert_eq(refused.code, NpcIntentBoard.CODE_NOT_CONFIGURED)
		assert_string_contains(refused.message, "intent_timeout_min")
	assert_false(rig.module.intents.is_configured(), "Nenhuma tentativa recusada ligou o quadro.")
	for edge_minutes: int in [NpcIntentParams.MIN_TIMEOUT_MIN, NpcIntentParams.MAX_TIMEOUT_MIN]:
		assert_true(rig.module.configure_intents(rig.actions, places, NpcIntentParams.new(edge_minutes)).ok, "Os extremos da faixa valem.")


# ---------------------------------------------------------------------------------------------------- sair de S0, posições do corpo, cópias

func test_a_npc_that_leaves_s0_loses_the_intent_and_its_action_goes_on_abstractly() -> void:
	var rig: Rig = _rig()
	var npc_id: int = _s0_npc(rig)
	assert_true(_begin(rig, npc_id, "eat", HOME).ok)
	var batch: Dictionary[int, Vector3] = {npc_id: Vector3(1500.0, 0.0, 500.0)}
	assert_true(rig.module.request_report_npc_positions(batch).ok)
	rig.runner.step_once()
	assert_eq(rig.module.lod.level_of(npc_id), S1, "O corpo foi a 500 m do foco: saiu de S0.")
	assert_eq(rig.module.peek_pending_intents().size(), 0, "Quem sai de S0 perde o Intent.")
	var npc: NpcModule.NpcQuery = rig.module.peek_npc(npc_id)
	assert_eq([npc.action_id, npc.x_cm], ["eat", 150000], "A ação segue (não foi cancelada) e o último relato virou a posição lógica.")
	assert_eq(rig.module.intents.debug_summary()["timed_out_intents"], 0, "Sair de S0 não é tempo limite.")
	assert_true(rig.module.request_set_focus(OTHER_ACTOR_ID, Vector3(1500.0, 10.0, 500.0)).ok, "Outro ator chega perto de onde o NPC ficou.")
	rig.runner.step_once()
	assert_eq(rig.module.lod.level_of(npc_id), S0, "O NPC voltou a S0.")
	assert_eq(rig.module.peek_pending_intents().size(), 0, "O Intent antigo não ressuscita: a ação segue abstrata.")
	rig.runner.run_steps(EAT_MIN - 2)
	assert_eq(rig.actions.advance(npc_id, rig.now()).outcome, ActionRunner.Outcome.COMPLETED, "O runner abstrato termina a ação no fim.")
	assert_eq(_hunger(rig, npc_id), START_HUNGER + EAT_RELIEF, "Os mesmos efeitos, pela mesma função.")
	var late: Result = rig.module.request_report_npc_result(_outcome(npc_id, 1, NpcActionResult.Outcome.DONE))
	assert_eq(late.code, NpcIntentBoard.CODE_STALE_RESULT, "O corpo antigo não manda mais.")


func test_a_position_batch_applies_the_valid_entries_and_reports_the_first_refusal() -> void:
	var rig: Rig = _rig()
	var in_s0: int = _s0_npc(rig)
	var in_s1: int = _far_npc(rig)
	var batch: Dictionary[int, Vector3] = {999: Vector3(1.0, 0.0, 1.0), in_s1: Vector3(5.0, 0.0, 5.0), in_s0: Vector3(1011.5, 0.0, 500.25)}
	var refused: Result = rig.module.request_report_npc_positions(batch)
	assert_false(refused.ok)
	assert_eq(refused.code, NpcLod.CODE_NOT_IN_S0, "A primeira recusada é a do menor ID fora de S0.")
	assert_string_contains(refused.message, "aplicadas: 1 de 3")
	assert_eq(rig.module.lod.position_of(in_s0), Vector2i(101150, 50025), "A posição válida do lote valeu.")
	var invalid: Dictionary[int, Vector3] = {in_s0: Vector3(NAN, 0.0, 0.0)}
	assert_eq(rig.module.request_report_npc_positions(invalid).code, NpcLod.CODE_INVALID_POSITION)
	assert_eq(rig.module.lod.position_of(in_s0), Vector2i(101150, 50025), "Posição inválida não mexe no corpo.")
	var empty: Dictionary[int, Vector3] = {}
	assert_true(rig.module.request_report_npc_positions(empty).ok, "Lote vazio é válido.")


func test_pending_intents_come_back_as_copies_in_ascending_npc_order() -> void:
	var rig: Rig = _rig()
	var first: int = _s0_npc(rig)
	var second: int = _create(rig, HOME_CM.x + 500, HOME_CM.y)
	rig.runner.step_once()
	assert_eq(rig.module.lod.level_of(second), S0)
	assert_true(_begin(rig, second, "wait", HOME).ok)
	assert_true(_begin(rig, first, "wait", HOME).ok)
	var listed: Array[NpcIntent] = rig.module.peek_pending_intents()
	assert_eq([listed[0].npc_id, listed[1].npc_id], [first, second], "Ordem crescente de NPC, e não a de chegada.")
	listed[0].expected_minutes = 999
	listed[0].destination_cm = Vector2i.ZERO
	listed.clear()
	var again: Array[NpcIntent] = rig.module.peek_pending_intents()
	assert_eq([again.size(), again[0].expected_minutes, again[0].destination_cm], [2, WAIT_MIN, HOME_CM], "Mexer na cópia não muda o quadro.")


# ---------------------------------------------------------------------------------------------------- save, hash e determinismo

func test_pending_intents_are_not_saved_and_a_loaded_module_starts_with_none() -> void:
	var rig: Rig = _rig()
	var npc_id: int = _s0_npc(rig)
	assert_true(_begin(rig, npc_id, "eat", HOME).ok)
	var saved: Dictionary = rig.module.serialize()
	assert_eq(saved.keys(), [NpcModule.KEY_NPCS] as Array, "O módulo só salva a tabela de NPCs.")
	assert_false(JSON.stringify(saved).contains("intent"), "Nada de Intent no save.")
	var other: NpcModule = NpcModule.new(_need_defs(NO_RATES))
	assert_true(other.on_load(saved).ok)
	assert_eq(other.peek_npc(npc_id).action_id, "eat", "A ação em curso é estado do NPC e volta.")
	assert_eq(other.peek_pending_intents().size(), 0, "Um mundo carregado começa sem Intents (e todos em S1).")


func test_the_intent_board_does_not_enter_the_world_hash() -> void:
	var embodied: Rig = _rig()
	var abstract: Rig = _rig()
	var npc_s0: int = _s0_npc(embodied)
	var npc_s1: int = _s0_npc(abstract)
	assert_true(_begin(embodied, npc_s0, "eat", HOME).ok)
	assert_true(abstract.actions.begin(npc_s1, "eat", HOME, abstract.now()).ok)
	assert_eq(embodied.module.peek_pending_intents().size(), 1)
	assert_eq(abstract.module.peek_pending_intents().size(), 0)
	assert_eq(embodied.runner.world.state_hash(), abstract.runner.world.state_hash(), "Com e sem Intent pendente o hash é o mesmo: o quadro não é salvo.")


func test_same_inputs_give_the_same_world() -> void:
	var hashes: Array[String] = []
	for _run: int in 2:
		var rig: Rig = _rig(HUNGER_RATE)
		var npc_id: int = _s0_npc(rig)
		assert_true(_begin(rig, npc_id, "eat", HOME).ok)
		rig.runner.run_steps(EAT_MIN + 3)
		assert_true(rig.module.request_report_npc_result(_outcome(npc_id, 1, NpcActionResult.Outcome.DONE)).ok)
		rig.runner.run_steps(5)
		hashes.append(rig.runner.world.state_hash())
	assert_eq(hashes[0], hashes[1], "Mesma entrada, mesmo mundo.")


# ---------------------------------------------------------------------------------------------------- parâmetros (data/intent_params.json)

func _dir_with(text: String) -> String:
	var dir_path: String = "%s/case_%d" % [TEMP_ROOT, _temp_dirs.size()]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir_path))
	var file: FileAccess = FileAccess.open(dir_path.path_join(NpcIntentParams.DEFAULT_FILE), FileAccess.WRITE)
	file.store_string(text)
	file.close()
	_temp_dirs.append(dir_path)
	return dir_path


func test_the_real_parameters_file_has_the_agreed_value() -> void:
	var loaded: NpcIntentParams.LoadResult = NpcIntentParams.load_dir()
	assert_true(loaded.result.ok, loaded.result.message)
	assert_eq(loaded.params.intent_timeout_min, 30)
	assert_eq(loaded.params.problem(), "")


func test_parameter_files_are_validated_with_the_file_and_the_field_in_the_message() -> void:
	var invalid_cases: Dictionary = {
		'[{"id": "intents", "intent_timeout_min": 0}]': "intent_timeout_min",
		'[{"id": "intents", "intent_timeout_min": 1441}]': "intent_timeout_min",
		'[{"id": "intents", "intent_timeout_min": "30"}]': "intent_timeout_min",
		'[{"id": "intents", "intent_timeout_min": 1.5}]': "intent_timeout_min",
		'[{"id": "intents"}]': "intent_timeout_min",
		'[{"id": "a", "intent_timeout_min": 30}, {"id": "b", "intent_timeout_min": 40}]': "exatamente 1 linha",
		'[]': "exatamente 1 linha",
	}
	for text: String in invalid_cases:
		var loaded: NpcIntentParams.LoadResult = NpcIntentParams.load_dir(_dir_with(text))
		assert_false(loaded.result.ok, "Deveria falhar: " + text)
		assert_eq(loaded.result.code, NpcIntentParams.CODE_INVALID)
		assert_null(loaded.params)
		assert_string_contains(loaded.result.message, invalid_cases[text])
		assert_string_contains(loaded.result.message, NpcIntentParams.DEFAULT_FILE)
	for edge: int in [NpcIntentParams.MIN_TIMEOUT_MIN, NpcIntentParams.MAX_TIMEOUT_MIN]:
		var ok_loaded: NpcIntentParams.LoadResult = NpcIntentParams.load_dir(_dir_with('[{"id": "intents", "intent_timeout_min": %d}]' % edge))
		assert_true(ok_loaded.result.ok, ok_loaded.result.message)
		assert_eq(ok_loaded.params.intent_timeout_min, edge)
	var missing: NpcIntentParams.LoadResult = NpcIntentParams.load_dir("res://.godot/lw070_does_not_exist")
	assert_false(missing.result.ok, "Arquivo ausente falha em vez de usar um valor escondido.")
