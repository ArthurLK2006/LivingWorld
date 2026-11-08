extends GutTest
## LW-070c: o aviso de ação COMPLETA do quadro de Intents (docs/modules/npc.md, seção 6), sem mundo e sem janela. Quando o resultado de SUCESSO do corpo
## termina a ação de um NPC em S0, o quadro chama o MESMO gancho que o pensador chama no modo sem corpo (as consequências sociais da LW-080), com os
## mesmos três valores: o id da ação que terminou (lido ANTES de ela ser encerrada), o local do NPC e o minuto. Aqui só se confere QUANDO ele
## dispara; o que a conversa e a ajuda fazem com ele está em tests/integration/test_npc_s0_social.gd. Valores ESCRITOS À MÃO: `talk` de 30 min que
## alivia 30 de `social`, `eat` de 20 min que alivia 60 de `hunger` (e exige comida), as duas necessidades em 80, sem taxa de variação.

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


## Quem recebe o aviso. Guarda cada chamada com o que o NPC mostrava NA HORA dela (ação e necessidade `social`), para provar a ordem: os efeitos já
## entraram e a ação já foi encerrada quando o gancho roda.
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


## Um NPC em S0 (perto do foco), no local de convívio, com o quadro ligado e o aviso apontando para o `Listener`.
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
	var runner: ActionRunner = ActionRunner.new(rig.states, _catalog(), _need_defs(), null, rig.provider, WALK_SPEED)
	assert_eq(runner.peek_problem(), "", "O runner de teste deveria servir.")
	rig.lod = NpcLod.new(LodParams.new(80, 120, 50))
	rig.board = NpcIntentBoard.new(rig.lod)
	assert_true(rig.board.configure(runner, rig.states, null, NpcIntentParams.new(TIMEOUT_MIN)).ok)
	rig.board.set_completion_hook(rig.listener.on_completed)
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


# ---------------------------------------------------------------------------------------------------- quando dispara

func test_a_success_result_calls_the_hook_once_after_the_effects_with_the_ended_action_the_place_and_the_minute() -> void:
	var rig: Rig = _rig()
	var serial: int = _begin(rig, "talk")
	assert_eq(rig.listener.calls.size(), 0, "Começar a ação não avisa nada: ela ainda não terminou.")
	var reported: Result = rig.board.report_result(_result(serial, NpcActionResult.Outcome.DONE), TALK_MIN)
	assert_true(reported.ok, reported.message)
	assert_eq(rig.listener.calls, [[NPC_ID, "talk", PLACE_ID, TALK_MIN, "", START_VALUE + TALK_RELIEF]], "Uma chamada, com a ação que terminou (lida antes de ser encerrada), o local e o minuto; na hora dela o efeito já tinha entrado e a ação já estava encerrada.")


func test_every_completed_action_is_announced_and_choosing_the_social_ones_belongs_to_the_listener() -> void:
	var rig: Rig = _rig()
	var serial: int = _begin(rig, "eat")
	assert_true(rig.board.report_result(_result(serial, NpcActionResult.Outcome.DONE), EAT_MIN).ok)
	assert_eq(rig.listener.calls.size(), 1)
	assert_eq(rig.listener.calls[0].slice(0, 4), [NPC_ID, "eat", PLACE_ID, EAT_MIN], "Como no pensador: toda ação completa é avisada, e o `SocialActions` ignora as que não são conversa nem ajuda.")


# ---------------------------------------------------------------------------------------------------- quando NÃO dispara

func test_blocked_and_cancelled_results_cancel_the_action_without_calling_the_hook() -> void:
	for outcome: NpcActionResult.Outcome in [NpcActionResult.Outcome.BLOCKED, NpcActionResult.Outcome.CANCELLED]:
		var rig: Rig = _rig()
		var serial: int = _begin(rig, "talk")
		var reported: Result = rig.board.report_result(_result(serial, outcome), TALK_MIN)
		assert_true(reported.ok, "Cancelar sem efeito é sucesso do pedido: %s" % reported.message)
		assert_eq(rig.states[NPC_ID].action_id, "", "A ação foi cancelada.")
		assert_eq(rig.states[NPC_ID].need_values[SOCIAL], START_VALUE, "Sem efeito algum.")
		assert_eq(rig.listener.calls.size(), 0, "Resultado %d: nada a avisar." % outcome)


func test_a_timeout_a_stale_serial_an_invalid_or_mismatched_result_and_an_npc_that_left_s0_never_call_the_hook() -> void:
	var timed_out: Rig = _rig()
	_begin(timed_out, "talk")
	assert_eq(timed_out.board.expire(TALK_MIN + TIMEOUT_MIN), [NPC_ID] as Array[int], "O tempo limite cancela a ação.")
	assert_eq(timed_out.listener.calls.size(), 0, "Tempo limite: cancelada sem efeito, nada a avisar.")
	var stale: Rig = _rig()
	var serial: int = _begin(stale, "talk")
	assert_eq(stale.board.report_result(_result(serial + 5, NpcActionResult.Outcome.DONE), TALK_MIN).code, NpcIntentBoard.CODE_STALE_RESULT)
	assert_eq(stale.listener.calls.size(), 0, "Contador de outra ação: descartado.")
	var mismatched: Rig = _rig()
	serial = _begin(mismatched, "talk")
	assert_eq(mismatched.board.report_result(_result(serial, NpcActionResult.Outcome.ARRIVED), TALK_MIN).code, NpcIntentBoard.CODE_OUTCOME_MISMATCH)
	assert_eq(mismatched.listener.calls.size(), 0, "ARRIVED não vale para ação no local: recusado, o Intent continua pendente.")
	assert_true(mismatched.board.has_pending(NPC_ID))
	assert_true(mismatched.board.report_result(_result(serial, NpcActionResult.Outcome.DONE), TALK_MIN).ok)
	assert_eq(mismatched.listener.calls.size(), 1, "Corrigido o desfecho, o aviso sai uma vez.")
	var invalid: Rig = _rig()
	_begin(invalid, "talk")
	assert_eq(invalid.board.report_result(null, TALK_MIN).code, NpcIntentBoard.CODE_INVALID_RESULT)
	assert_eq(invalid.listener.calls.size(), 0)
	var left: Rig = _rig()
	serial = _begin(left, "talk")
	assert_true(left.lod.set_focus(ACTOR_ID, FAR_FOCUS_M).ok)
	assert_eq(left.lod.update(left.states, 5).size(), 1, "O NPC se afasta e sai de S0: a ação segue abstrata.")
	assert_eq(left.board.report_result(_result(serial, NpcActionResult.Outcome.DONE), TALK_MIN).code, NpcIntentBoard.CODE_STALE_RESULT)
	assert_eq(left.listener.calls.size(), 0, "Quem termina a ação abstrata é o pensador, com o gancho dele.")


func test_a_repeated_success_result_is_discarded_and_the_hook_is_called_only_once() -> void:
	var rig: Rig = _rig()
	var serial: int = _begin(rig, "talk")
	var done: NpcActionResult = _result(serial, NpcActionResult.Outcome.DONE)
	assert_true(rig.board.report_result(done, TALK_MIN).ok)
	assert_eq(rig.board.report_result(done, TALK_MIN).code, NpcIntentBoard.CODE_STALE_RESULT, "O mesmo resultado de novo: descartado.")
	assert_eq(rig.board.report_result(done, TALK_MIN + 1).code, NpcIntentBoard.CODE_STALE_RESULT, "E também em outro minuto.")
	assert_eq(rig.listener.calls.size(), 1, "Uma só chamada.")
	assert_eq(rig.states[NPC_ID].need_values[SOCIAL], START_VALUE + TALK_RELIEF, "E o efeito entrou uma vez só.")


func test_a_completion_that_fails_its_final_check_does_not_call_the_hook() -> void:
	var rig: Rig = _rig()
	var serial: int = _begin(rig, "eat")
	rig.provider.food = false
	var reported: Result = rig.board.report_result(_result(serial, NpcActionResult.Outcome.DONE), EAT_MIN)
	assert_eq(reported.code, ActionRunner.CODE_ACTION_FAILED, "Sem comida na hora de terminar, a regra do runner falha a ação.")
	assert_eq(rig.states[NPC_ID].action_id, "", "O NPC ficou livre.")
	assert_eq(rig.states[NPC_ID].need_values[HUNGER], START_VALUE, "Nenhum efeito entrou.")
	assert_eq(rig.listener.calls.size(), 0, "A ação não COMPLETOU (o `outcome` do runner diz): nada a avisar.")


# ---------------------------------------------------------------------------------------------------- sem gancho, ou com gancho que não existe mais

func test_without_a_hook_or_with_a_hook_whose_listener_is_gone_the_result_still_works() -> void:
	var bare: Rig = _rig()
	bare.board.set_completion_hook(Callable())
	var serial: int = _begin(bare, "talk")
	assert_true(bare.board.report_result(_result(serial, NpcActionResult.Outcome.DONE), TALK_MIN).ok, "Sem gancho (o quadro solto) tudo segue como antes.")
	assert_eq(bare.states[NPC_ID].need_values[SOCIAL], START_VALUE + TALK_RELIEF)
	var orphan: Rig = _rig()
	var gone: Listener = Listener.new()
	orphan.board.set_completion_hook(gone.on_completed)
	gone = null
	serial = _begin(orphan, "talk")
	assert_true(orphan.board.report_result(_result(serial, NpcActionResult.Outcome.DONE), TALK_MIN).ok, "O gancho aponta para quem já foi liberado: o Callable deixou de valer e o resultado passa sem erro.")
	assert_eq(orphan.states[NPC_ID].need_values[SOCIAL], START_VALUE + TALK_RELIEF)
