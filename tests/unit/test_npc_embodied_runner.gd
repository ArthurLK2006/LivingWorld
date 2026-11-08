extends GutTest
## LW-070b: as peças pequenas do NPC com corpo, sem mundo e sem janela. O `EmbodiedActionRunner` (com Intent pendente a ação não termina pelo
## relógio e trocá-la a cancela sem efeito; sem Intent é o ActionRunner de sempre), a validade dos Intents no quadro (uma ação trocada, cancelada
## ou um NPC morto tiram o Intent da lista sem ninguém avisar o quadro) e a saída em lote do LOD (`release_all`, usada pelo interruptor de corpos).
## Valores ESCRITOS À MÃO: ação `eat` de 20 min que alivia 60 da fome; fome em 100; sem taxa de variação (tudo conferível de cabeça).

const NEED_IDS: Array[String] = ["hunger", "rest", "safety", "income", "social"]
const HUNGER: int = 0
const START_HUNGER: int = 100
const EAT_MIN: int = 20
const EAT_RELIEF: int = -60
## Metade da ação (interrompida no meio): 10 min e metade do alívio.
const HALF_EAT_MIN: int = 10
const HALF_EAT_RELIEF: int = -30
const WALK_SPEED: int = 8400
const TIMEOUT_MIN: int = 30
const FOCUS_M: Vector3 = Vector3(10.0, 0.0, 0.0)
const NEAR_CM: Array[int] = [1000, 1100, 1200]


## Um runner sobre uma tabela de NPCs montada à mão; `embodied` diz quem tem Intent pendente (aqui, uma lista que o teste controla).
class Rig:
	extends RefCounted

	var states: Dictionary[int, NpcState] = {}
	var runner: EmbodiedActionRunner
	var embodied_ids: Array[int] = []

	func is_embodied(npc_id: int) -> bool:
		return embodied_ids.has(npc_id)


func _need_defs() -> Array[NeedDef]:
	var defs: Array[NeedDef] = []
	for position: int in NEED_IDS.size():
		defs.append(NeedDef.new(NEED_IDS[position], position, 0, 0, 40, 65, 90))
	return defs


func _catalog() -> Array[ActionDef]:
	var eat: ActionDef = ActionDef.new("eat", EAT_MIN, "", 0, true)
	eat.effects.append(ActionDef.ActionEffect.new("hunger", EAT_RELIEF))
	var catalog: Array[ActionDef] = [eat]
	return catalog


func _state(npc_id: int, x_cm: int = 0) -> NpcState:
	var state: NpcState = NpcState.new(npc_id)
	state.need_values = PackedInt64Array([START_HUNGER, 0, 0, 0, 0])
	state.need_remainders = PackedInt64Array([0, 0, 0, 0, 0])
	state.x_cm = x_cm
	return state


func _rig(use_callable: bool = true) -> Rig:
	var rig: Rig = Rig.new()
	rig.states[1] = _state(1)
	var embodied: Callable = rig.is_embodied if use_callable else Callable()
	rig.runner = EmbodiedActionRunner.new(rig.states, _catalog(), _need_defs(), null, null, WALK_SPEED, embodied)
	assert_eq(rig.runner.peek_problem(), "", "O runner de teste deveria servir.")
	return rig


# ---------------------------------------------------------------------------------------------------- o runner

func test_with_a_pending_intent_the_planned_end_does_not_finish_the_action() -> void:
	var rig: Rig = _rig()
	assert_true(rig.runner.begin(1, "eat", "", 0).ok)
	rig.embodied_ids.append(1)
	var late: ActionRunner.AdvanceResult = rig.runner.advance(1, EAT_MIN + 15)
	assert_eq(late.outcome, ActionRunner.Outcome.RUNNING, "Passou do fim previsto, mas só o corpo ou o tempo limite encerram a ação.")
	assert_true(late.result.ok)
	assert_eq([rig.states[1].action_id, rig.states[1].need_values[HUNGER]], ["eat", START_HUNGER], "A ação segue e nenhum efeito entrou.")


func test_with_a_pending_intent_interrupting_cancels_without_any_effect() -> void:
	var rig: Rig = _rig()
	assert_true(rig.runner.begin(1, "eat", "", 0).ok)
	var serial: int = rig.states[1].action_serial
	rig.embodied_ids.append(1)
	var cancelled: Result = rig.runner.interrupt(1, HALF_EAT_MIN)
	assert_true(cancelled.ok, cancelled.message)
	var state: NpcState = rig.states[1]
	assert_eq(state.action_id, "", "O NPC ficou livre.")
	assert_eq(state.need_values[HUNGER], START_HUNGER, "Sem efeito algum, nem o proporcional (metade da ação seria -30).")
	assert_eq(state.action_serial, serial, "O contador não volta: quem tinha o Intent velho continua sendo descartado.")
	assert_eq(rig.runner.cancel_action(1, serial).code, ActionRunner.CODE_STALE_ACTION, "E a ação já não existe para ninguém cancelar de novo.")


func test_without_a_pending_intent_the_runner_is_the_abstract_one_it_always_was() -> void:
	for use_callable: bool in [true, false]:
		var rig: Rig = _rig(use_callable)
		assert_true(rig.runner.begin(1, "eat", "", 0).ok)
		assert_eq(rig.runner.advance(1, EAT_MIN - 1).outcome, ActionRunner.Outcome.RUNNING)
		var finished: ActionRunner.AdvanceResult = rig.runner.advance(1, EAT_MIN)
		assert_eq(finished.outcome, ActionRunner.Outcome.COMPLETED, "O tempo acaba e a ação termina (callable ligado: %s)." % use_callable)
		assert_eq(rig.states[1].need_values[HUNGER], START_HUNGER + EAT_RELIEF, "Efeito completo.")
		assert_true(rig.runner.begin(1, "eat", "", EAT_MIN).ok)
		assert_true(rig.runner.interrupt(1, EAT_MIN + HALF_EAT_MIN).ok)
		assert_eq(rig.states[1].need_values[HUNGER], START_HUNGER + EAT_RELIEF + HALF_EAT_RELIEF, "Interrompida pela metade: efeito proporcional (metade de -60).")


# ---------------------------------------------------------------------------------------------------- a validade dos Intents no quadro

## Quadro de Intents sobre o MESMO runner e a MESMA tabela, com o NPC 1 em S0 (perto do foco).
class Board:
	extends RefCounted

	var rig: Rig
	var lod: NpcLod
	var board: NpcIntentBoard


func _board() -> Board:
	var made: Board = Board.new()
	made.rig = _rig(false)
	made.lod = NpcLod.new(LodParams.new(80, 120, 50))
	made.board = NpcIntentBoard.new(made.lod)
	assert_true(made.board.configure(made.rig.runner, made.rig.states, null, NpcIntentParams.new(TIMEOUT_MIN)).ok)
	assert_true(made.lod.set_focus(77, FOCUS_M).ok)
	made.rig.states[1].x_cm = NEAR_CM[0]
	assert_eq(made.lod.update(made.rig.states, 0).size(), 1, "O NPC 1 perto do foco entra em S0.")
	return made


func test_an_intent_stops_being_pending_when_its_action_is_cancelled_by_any_other_path() -> void:
	var made: Board = _board()
	assert_true(made.board.begin_embodied(1, "eat", "", 0).ok)
	var serial: int = made.rig.states[1].action_serial
	assert_eq([made.board.has_pending(1), made.board.peek_pending().size(), made.board.pending_ids()], [true, 1, [1] as Array[int]])
	assert_true(made.rig.runner.cancel_action(1, serial).ok, "A ação sai por outro caminho (o pensador que reavalia), sem avisar o quadro.")
	assert_eq([made.board.has_pending(1), made.board.peek_pending().size(), made.board.pending_ids().size()], [false, 0, 0], "O Intent saiu da lista sozinho.")
	assert_eq(made.board.debug_summary()["pending"], 0)
	var late: Result = made.board.report_result(NpcActionResult.new(1, serial, NpcActionResult.Outcome.DONE, Vector3(10.0, 0.0, 0.0)), 5)
	assert_eq(late.code, NpcIntentBoard.CODE_STALE_RESULT, "Resultado do corpo do Intent que já não vale: descartado.")
	assert_eq(made.board.debug_summary()["discarded_results"], 1)


func test_an_intent_of_a_replaced_action_or_a_dead_npc_is_not_pending_and_expire_purges_it() -> void:
	var made: Board = _board()
	assert_true(made.board.begin_embodied(1, "eat", "", 0).ok)
	var first_serial: int = made.rig.states[1].action_serial
	assert_true(made.rig.runner.cancel_action(1, first_serial).ok)
	assert_true(made.board.begin_embodied(1, "eat", "", 5).ok)
	var second: Array[NpcIntent] = made.board.peek_pending()
	assert_eq(second.size(), 1, "Só o Intent da ação NOVA está na lista.")
	assert_eq(second[0].action_serial, first_serial + 1)
	made.rig.states[1].is_alive = false
	made.rig.states[1].action_id = ""
	assert_false(made.board.has_pending(1), "NPC morto: o Intent não vale.")
	assert_eq(made.board.expire(10), [] as Array[int], "E ninguém foi cancelado por tempo: o quadro só limpou o que não valia mais.")
	assert_eq(made.board.debug_summary()["timed_out_intents"], 0)


# ---------------------------------------------------------------------------------------------------- a saída em lote do LOD

func test_releasing_everyone_uses_the_leaving_path_and_keeps_the_foci() -> void:
	var states: Dictionary[int, NpcState] = {}
	for index: int in NEAR_CM.size():
		states[index + 1] = _state(index + 1, NEAR_CM[index])
	var lod: NpcLod = NpcLod.new(LodParams.new(80, 120, 2))
	assert_true(lod.set_focus(77, FOCUS_M).ok)
	assert_eq(lod.update(states, 0).size(), 2, "Pelo limite, só os dois mais perto entram em S0.")
	assert_eq(lod.s0_ids(), [1, 2] as Array[int])
	assert_true(lod.report_position(1, Vector2i(2500, 300)).ok)
	var changes: Array[NpcLod.Change] = lod.release_all(states, 5)
	assert_eq(changes.size(), 2, "Uma troca por NPC que tinha corpo.")
	assert_eq([changes[0].npc_id, changes[0].from_level, changes[0].to_level], [1, NpcLod.LEVEL_S0, NpcLod.LEVEL_S1])
	assert_eq([changes[1].npc_id, changes[1].from_level, changes[1].to_level], [2, NpcLod.LEVEL_S0, NpcLod.LEVEL_S1])
	assert_eq(lod.s0_ids().size(), 0)
	assert_eq([states[1].x_cm, states[1].z_cm], [2500, 300], "O último relato do corpo virou a posição lógica, como em quem se afasta.")
	assert_eq([states[2].x_cm, states[2].z_cm], [NEAR_CM[1], 0], "Sem relato, a posição lógica não muda.")
	assert_eq(lod.focus_count(), 1, "Os focos ficam guardados.")
	assert_eq(lod.release_all(states, 6).size(), 0, "Soltar de novo, sem ninguém em S0, não troca nada.")
	assert_eq(NpcLod.new().release_all(states, 0).size(), 0, "LOD desligado: nada a soltar.")
