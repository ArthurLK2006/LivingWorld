extends GutTest
## LW-070d (antes, LW-070c): o fechamento da ação do NPC com corpo e o aviso de ação COMPLETA (docs/modules/npc.md, seções 5 e 6), sem mundo e sem janela.
## O resultado de SUCESSO do corpo só MARCA o fim da ação e solta o Intent; quem a encerra é o `advance` do pensador, no pensamento seguinte, e é ele que
## chama o MESMO gancho do modo sem corpo (as consequências sociais da LW-080), com os três valores de sempre: o id da ação que terminou (lido ANTES de
## ela ser encerrada), o local do NPC e o minuto do pensamento. O quadro NÃO tem mais gancho (na LW-070c ele o chamava na hora do relato). Aqui o
## `Listener` e `_think` fazem o papel do pensador, com as linhas de `NpcThinker.think` que fecham a ação (um teste de varredura confere que elas
## continuam lá); o pensador de verdade, com a conversa e a ajuda reais, está em tests/integration/test_npc_s0_social.gd. O runner é o do jogo
## (`EmbodiedActionRunner`). Valores ESCRITOS À MÃO: `talk` de 30 min que alivia 30 de `social`, `eat` de 20 min que alivia 60 de `hunger` (e exige
## comida), as duas necessidades em 80, sem taxa de variação.

const NEED_IDS: Array[String] = ["hunger", "rest", "safety", "income", "social"]
const HUNGER: int = 0
const SOCIAL: int = 4
const START_VALUE: int = 80
const TALK_MIN: int = 30
const TALK_RELIEF: int = -30
const EAT_MIN: int = 20
const EAT_RELIEF: int = -60
const TIMEOUT_MIN: int = 30
const PLACE_ID: String = "social_x"
const ACTOR_ID: int = 77
const FOCUS_M: Vector3 = Vector3(10.0, 0.0, 0.0)
const FAR_FOCUS_M: Vector3 = Vector3(5000.0, 0.0, 0.0)
const BODY_M: Vector3 = Vector3(10.0, 0.0, 0.0)
const NEAR_CM: int = 1000
const WALK_SPEED: int = 8400
const NPC_ID: int = 1


## Provedor de teste: responde o que o teste mandar.
class Provider:
	extends ActionConditionProvider

	var food: bool = true

	func has_food(_settlement_id: String) -> bool:
		return food


## Quem recebe o aviso (o papel do `SocialActions`). Guarda cada chamada com o que o NPC mostrava NA HORA dela (ação e necessidade `social`), para
## provar a ordem: os efeitos já entraram e a ação já foi encerrada quando o gancho roda.
class Listener:
	extends RefCounted

	var states: Dictionary[int, NpcState] = {}
	var social_index: int = 0
	## [npc_id, action_id, place_id, now, ação do NPC na hora da chamada, `social` do NPC na hora da chamada]
	var calls: Array = []

	func on_completed(npc_id: int, action_id: String, place_id: String, now: int) -> void:
		var state: NpcState = states[npc_id]
		calls.append([npc_id, action_id, place_id, now, state.action_id, state.need_values[social_index]])


class Rig:
	extends RefCounted

	var states: Dictionary[int, NpcState] = {}
	var provider: Provider
	var lod: NpcLod
	var board: NpcIntentBoard
	var runner: ActionRunner
	var listener: Listener


func _need_defs() -> Array[NeedDef]:
	var defs: Array[NeedDef] = []
	for position: int in NEED_IDS.size():
		defs.append(NeedDef.new(NEED_IDS[position], position, 0, 0, 40, 65, 90))
	return defs


func _catalog() -> Array[ActionDef]:
	var talk: ActionDef = ActionDef.new("talk", TALK_MIN, "", 0, true)
	talk.effects.append(ActionDef.ActionEffect.new("social", TALK_RELIEF))
	var eat: ActionDef = ActionDef.new("eat", EAT_MIN, "", 0, true)
	eat.effects.append(ActionDef.ActionEffect.new("hunger", EAT_RELIEF))
	eat.conditions.append(ActionDef.ActionCondition.new(ActionDef.CONDITION_HAS_FOOD, "", ActionDef.ABSENT, ActionDef.ABSENT))
	var catalog: Array[ActionDef] = [talk, eat]
	return catalog


## Um NPC em S0 (perto do foco), no local de convívio, com o quadro ligado ao runner do jogo (o `EmbodiedActionRunner` pergunta ao quadro se há Intent
## pendente) e o `Listener` no lugar do gancho do pensador.
func _rig() -> Rig:
	var rig: Rig = Rig.new()
	rig.provider = Provider.new()
	rig.listener = Listener.new()
	var state: NpcState = NpcState.new(NPC_ID)
	state.need_values = PackedInt64Array([START_VALUE, 0, 0, 0, START_VALUE])
	state.need_remainders = PackedInt64Array([0, 0, 0, 0, 0])
	state.x_cm = NEAR_CM
	state.place_id = PLACE_ID
	rig.states[NPC_ID] = state
	rig.listener.states = rig.states
	rig.listener.social_index = SOCIAL
	rig.lod = NpcLod.new(LodParams.new(80, 120, 50))
	rig.board = NpcIntentBoard.new(rig.lod)
	rig.runner = EmbodiedActionRunner.new(rig.states, _catalog(), _need_defs(), null, rig.provider, WALK_SPEED, rig.board.has_pending)
	assert_eq(rig.runner.peek_problem(), "", "O runner de teste deveria servir.")
	assert_true(rig.board.configure(rig.runner, rig.states, null, NpcIntentParams.new(TIMEOUT_MIN)).ok)
	assert_true(rig.lod.set_focus(ACTOR_ID, FOCUS_M).ok)
	assert_eq(rig.lod.update(rig.states, 0).size(), 1, "O NPC perto do foco entra em S0.")
	return rig


## Começa a ação em S0 no minuto 0 e devolve o contador dela.
func _begin(rig: Rig, action_id: String) -> int:
	var started: Result = rig.board.begin_embodied(NPC_ID, action_id, "", 0)
	assert_true(started.ok, started.message)
	return rig.states[NPC_ID].action_serial


func _result(serial: int, outcome: NpcActionResult.Outcome) -> NpcActionResult:
	return NpcActionResult.new(NPC_ID, serial, outcome, BODY_M)


## O que `NpcThinker.think` faz ao encerrar a ação (npc_thinker.gd, linhas 122 a 125): lê a ação que está acabando, chama `advance` e, se ela COMPLETOU,
## avisa o gancho com o local do NPC e o minuto do pensamento.
func _think(rig: Rig, now: int) -> ActionRunner.AdvanceResult:
	var state: NpcState = rig.states[NPC_ID]
	var action_before: String = state.action_id
	var progress: ActionRunner.AdvanceResult = rig.runner.advance(NPC_ID, now)
	if progress.outcome == ActionRunner.Outcome.COMPLETED:
		rig.listener.on_completed(NPC_ID, action_before, state.place_id, now)
	return progress


# ---------------------------------------------------------------------------------------------------- quando dispara

func test_a_success_result_only_marks_the_end_and_the_next_think_applies_the_effects_and_calls_the_hook_once() -> void:
	var rig: Rig = _rig()
	var serial: int = _begin(rig, "talk")
	assert_eq(rig.listener.calls.size(), 0, "Começar a ação não avisa nada: ela ainda não terminou.")
	assert_eq(_think(rig, TALK_MIN).outcome, ActionRunner.Outcome.RUNNING, "Com o Intent pendente o fim previsto não encerra a ação: só o resultado do corpo.")
	var reported: Result = rig.board.report_result(_result(serial, NpcActionResult.Outcome.DONE), TALK_MIN)
	assert_true(reported.ok, reported.message)
	assert_eq([rig.states[NPC_ID].action_id, rig.states[NPC_ID].need_values[SOCIAL], rig.listener.calls.size()], ["talk", START_VALUE, 0], "O relato só marca o fim: a ação segue, sem efeito e sem aviso.")
	assert_false(rig.board.has_pending(NPC_ID), "E o Intent foi solto.")
	assert_eq(_think(rig, TALK_MIN + 1).outcome, ActionRunner.Outcome.COMPLETED, "O pensamento seguinte encerra a ação.")
	assert_eq(rig.listener.calls, [[NPC_ID, "talk", PLACE_ID, TALK_MIN + 1, "", START_VALUE + TALK_RELIEF]], "Uma chamada, com a ação que terminou (lida antes de ser encerrada), o local e o minuto do pensamento; na hora dela o efeito já tinha entrado e a ação já estava encerrada.")


func test_every_completed_action_is_announced_at_the_next_think_and_choosing_the_social_ones_belongs_to_the_listener() -> void:
	var rig: Rig = _rig()
	var serial: int = _begin(rig, "eat")
	assert_true(rig.board.report_result(_result(serial, NpcActionResult.Outcome.DONE), EAT_MIN).ok)
	assert_eq(rig.listener.calls.size(), 0, "Ainda não: o pensador não pensou.")
	assert_eq(_think(rig, EAT_MIN + 1).outcome, ActionRunner.Outcome.COMPLETED)
	assert_eq(rig.listener.calls.size(), 1)
	assert_eq(rig.listener.calls[0].slice(0, 4), [NPC_ID, "eat", PLACE_ID, EAT_MIN + 1], "Como no pensador: toda ação completa é avisada, e o `SocialActions` ignora as que não são conversa nem ajuda.")


# ---------------------------------------------------------------------------------------------------- quando NÃO dispara

func test_blocked_and_cancelled_results_cancel_the_action_at_once_and_the_next_think_calls_nothing() -> void:
	for outcome: NpcActionResult.Outcome in [NpcActionResult.Outcome.BLOCKED, NpcActionResult.Outcome.CANCELLED]:
		var rig: Rig = _rig()
		var serial: int = _begin(rig, "talk")
		var reported: Result = rig.board.report_result(_result(serial, outcome), TALK_MIN)
		assert_true(reported.ok, "Cancelar sem efeito é sucesso do pedido: %s" % reported.message)
		assert_eq(rig.states[NPC_ID].action_id, "", "A ação foi cancelada na hora.")
		assert_eq(rig.states[NPC_ID].need_values[SOCIAL], START_VALUE, "Sem efeito algum.")
		assert_eq(_think(rig, TALK_MIN + 1).outcome, ActionRunner.Outcome.NONE, "Não há o que encerrar.")
		assert_eq(rig.listener.calls.size(), 0, "Resultado %d: nada a avisar." % outcome)


func test_a_timeout_a_stale_serial_an_invalid_or_mismatched_result_and_an_npc_that_left_s0_never_reach_the_hook_through_the_board() -> void:
	var timed_out: Rig = _rig()
	_begin(timed_out, "talk")
	assert_eq(timed_out.board.expire(TALK_MIN + TIMEOUT_MIN), [NPC_ID] as Array[int], "O tempo limite cancela a ação.")
	assert_eq(_think(timed_out, TALK_MIN + TIMEOUT_MIN + 1).outcome, ActionRunner.Outcome.NONE)
	assert_eq(timed_out.listener.calls.size(), 0, "Tempo limite: cancelada sem efeito, nada a avisar.")
	var stale: Rig = _rig()
	var serial: int = _begin(stale, "talk")
	assert_eq(stale.board.report_result(_result(serial + 5, NpcActionResult.Outcome.DONE), 10).code, NpcIntentBoard.CODE_STALE_RESULT)
	assert_eq([stale.states[NPC_ID].action_ends_at, _think(stale, TALK_MIN).outcome, stale.listener.calls.size()], [TALK_MIN, ActionRunner.Outcome.RUNNING, 0], "Contador de outra ação: descartado, o fim não foi marcado e nada a avisar.")
	var mismatched: Rig = _rig()
	serial = _begin(mismatched, "talk")
	assert_eq(mismatched.board.report_result(_result(serial, NpcActionResult.Outcome.ARRIVED), TALK_MIN).code, NpcIntentBoard.CODE_OUTCOME_MISMATCH)
	assert_true(mismatched.board.has_pending(NPC_ID), "ARRIVED não vale para ação no local: recusado, o Intent continua pendente.")
	assert_true(mismatched.board.report_result(_result(serial, NpcActionResult.Outcome.DONE), TALK_MIN).ok)
	assert_eq(mismatched.listener.calls.size(), 0, "Corrigido o desfecho, o relato só marca o fim.")
	_think(mismatched, TALK_MIN + 1)
	assert_eq(mismatched.listener.calls.size(), 1, "E o aviso sai uma vez, no pensamento seguinte.")
	var invalid: Rig = _rig()
	_begin(invalid, "talk")
	assert_eq(invalid.board.report_result(null, TALK_MIN).code, NpcIntentBoard.CODE_INVALID_RESULT)
	assert_eq(invalid.listener.calls.size(), 0)
	var left: Rig = _rig()
	serial = _begin(left, "talk")
	assert_true(left.lod.set_focus(ACTOR_ID, FAR_FOCUS_M).ok)
	assert_eq(left.lod.update(left.states, 5).size(), 1, "O NPC se afasta e sai de S0: a ação segue abstrata.")
	assert_eq(left.board.report_result(_result(serial, NpcActionResult.Outcome.DONE), TALK_MIN).code, NpcIntentBoard.CODE_STALE_RESULT)
	assert_eq(left.listener.calls.size(), 0, "O relato do corpo antigo não avisa nada.")
	assert_eq(_think(left, TALK_MIN).outcome, ActionRunner.Outcome.COMPLETED, "Quem termina a ação abstrata é o pensador, com o gancho dele.")
	assert_eq(left.listener.calls.size(), 1)


func test_a_repeated_success_result_is_discarded_and_the_hook_is_called_only_once() -> void:
	var rig: Rig = _rig()
	var serial: int = _begin(rig, "talk")
	var done: NpcActionResult = _result(serial, NpcActionResult.Outcome.DONE)
	assert_true(rig.board.report_result(done, TALK_MIN).ok)
	assert_eq(rig.board.report_result(done, TALK_MIN).code, NpcIntentBoard.CODE_STALE_RESULT, "O mesmo resultado de novo: descartado.")
	assert_eq(rig.board.report_result(done, TALK_MIN + 1).code, NpcIntentBoard.CODE_STALE_RESULT, "E também em outro minuto.")
	assert_eq(_think(rig, TALK_MIN + 1).outcome, ActionRunner.Outcome.COMPLETED)
	assert_eq(_think(rig, TALK_MIN + 2).outcome, ActionRunner.Outcome.NONE, "Um pensamento a mais não encerra nada.")
	assert_eq(rig.listener.calls.size(), 1, "Uma só chamada.")
	assert_eq(rig.states[NPC_ID].need_values[SOCIAL], START_VALUE + TALK_RELIEF, "E o efeito entrou uma vez só.")


func test_a_completion_that_fails_its_final_check_is_found_by_the_next_think_and_does_not_call_the_hook() -> void:
	var rig: Rig = _rig()
	var serial: int = _begin(rig, "eat")
	rig.provider.food = false
	var reported: Result = rig.board.report_result(_result(serial, NpcActionResult.Outcome.DONE), EAT_MIN)
	assert_true(reported.ok, "O relato só marca o fim: a falha por regra não volta mais por aqui (LW-070d).")
	assert_eq(rig.states[NPC_ID].action_id, "eat", "A conferência final ainda não aconteceu.")
	var closed: ActionRunner.AdvanceResult = _think(rig, EAT_MIN + 1)
	assert_eq(closed.result.code, ActionRunner.CODE_ACTION_FAILED, "Sem comida na hora de terminar, a regra do runner falha a ação, no pensamento seguinte.")
	assert_eq(closed.outcome, ActionRunner.Outcome.FAILED)
	assert_eq(rig.states[NPC_ID].action_id, "", "O NPC ficou livre.")
	assert_eq(rig.states[NPC_ID].need_values[HUNGER], START_VALUE, "Nenhum efeito entrou.")
	assert_eq(rig.listener.calls.size(), 0, "A ação não COMPLETOU (o `outcome` do runner diz): nada a avisar.")


# ---------------------------------------------------------------------------------------------------- sem pensador, e o que o relato marca

func test_without_a_thinker_the_result_still_works_and_the_board_has_no_hook_any_more() -> void:
	var rig: Rig = _rig()
	var serial: int = _begin(rig, "talk")
	assert_true(rig.board.report_result(_result(serial, NpcActionResult.Outcome.DONE), TALK_MIN).ok, "Sem ninguém pensando (o quadro solto) o relato vale.")
	assert_eq(rig.states[NPC_ID].need_values[SOCIAL], START_VALUE, "E só marca: o efeito espera o pensamento.")
	assert_eq(rig.runner.advance(NPC_ID, TALK_MIN + 1).outcome, ActionRunner.Outcome.COMPLETED, "Quando alguém chamar o `advance`, a ação se encerra.")
	assert_eq(rig.states[NPC_ID].need_values[SOCIAL], START_VALUE + TALK_RELIEF)
	assert_false(rig.board.has_method("set_completion_hook"), "O gancho saiu do quadro: o pensador é o único que avisa.")


func test_marking_the_end_shortens_it_for_an_early_result_keeps_the_planned_end_for_a_late_one_and_applies_nothing() -> void:
	var early: Rig = _rig()
	var serial: int = _begin(early, "talk")
	assert_true(early.board.report_result(_result(serial, NpcActionResult.Outcome.DONE), 10).ok)
	var marked: NpcState = early.states[NPC_ID]
	assert_eq([marked.action_ends_at, marked.need_values[SOCIAL], marked.action_id], [10, START_VALUE, "talk"], "Resultado adiantado: o fim passa a ser o minuto dele; nada mais mudou.")
	assert_eq(_think(early, 11).outcome, ActionRunner.Outcome.COMPLETED)
	assert_eq(marked.needs_updated_at, 10, "As necessidades vão só até o fim marcado.")
	var late: Rig = _rig()
	serial = _begin(late, "talk")
	assert_eq(_think(late, TALK_MIN + 8).outcome, ActionRunner.Outcome.RUNNING, "Corpo atrasado: o NPC espera o resultado.")
	assert_true(late.board.report_result(_result(serial, NpcActionResult.Outcome.DONE), TALK_MIN + 8).ok)
	assert_eq(late.states[NPC_ID].action_ends_at, TALK_MIN, "Resultado atrasado: vale o fim planejado.")
	assert_eq(_think(late, TALK_MIN + 9).outcome, ActionRunner.Outcome.COMPLETED)
	assert_eq(late.states[NPC_ID].needs_updated_at, TALK_MIN, "E as necessidades vão até o fim planejado, não até o relato nem até o pensamento.")


func test_the_real_thinker_closes_the_action_and_calls_the_hook_the_way_this_file_assumes() -> void:
	var source: String = FileAccess.get_file_as_string("res://src/sim/npc/decision/npc_thinker.gd")
	assert_string_contains(source, "var action_before: String = state.action_id", "O pensador lê a ação ANTES de encerrá-la.")
	assert_string_contains(source, "_runner.advance(npc_id, now)", "Encerra pelo `advance`.")
	assert_string_contains(source, "_on_action_finished.call(npc_id, action_before, state.place_id, now)", "E avisa o gancho com a ação lida, o local e o minuto do pensamento.")
