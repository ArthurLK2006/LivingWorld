extends GutTest
## LW-070a: a costura do LOD e dos Intents com o fluxo de decisão (LW-063), sem janela e com o jogo montado como o real: os dados reais de
## res://data (NpcSetup.from_dir), os NPCs da população inicial (138: A 62, B 46 e C 30), o mundo do SimulationRunner e o relógio
## de verdade (1 passo = 1 minuto). O foco fica no centro do assentamento A (os 62 ficam a menos de 80 m; o limite de S0 é 50). O "corpo" é
## o próprio teste: cumpre cada Intent no fim previsto ou o deixa sem resposta de propósito. À meia-noite a rotina real manda todos dormirem
## (`sleep`, 480 min, na casa, alivia `rest` em 100), então os primeiros Intents são ACT_AT_PLACE; os de ir a um local (MOVE_TO_PLACE) só
## aparecem quando o sono acaba (cerca das 8h). ATENÇÃO: com 62 NPCs perto do foco e só 50 vagas, quem está em S0 oscila (o limite de S0 não
## tem histerese): a partir das 7h os NPCs de fora andam, passam mais perto do foco que os de corpo parado e tomam a vaga deles (medido na LW-070a, com 60 NPCs no A: 188
## trocas de nível em 1 dia de corpos parados; o NPC 1 sai por volta das 7h30 e o mais perto do foco só às 19h30, na reunião do `talk`). Por
## isso os testes de UM NPC escolhem o mais perto do foco; os testes do dia inteiro só conferem as propriedades que valem sempre.
## LW-098h5: o A tem 2 dos 6 comerciantes (ids 61 e 62), com agenda PRÓPRIA: descansam (`rest`, 60 min, em um local de descanso) de madrugada em
## vez de dormir e, às 6h, vão a pé para casa (Intent de ir) antes de comer. Os testes de UM NPC escolhem entre os que NÃO são comerciantes (a
## premissa deles é a rotina comum: `sleep` e depois `eat`) e cada comerciante ganha o teste IRMÃO com a asserção própria.

const DATA_DIR: String = "res://data"
const WORLD_SEED: int = 11
const ACTOR_ID: int = 77
const FOCUS_A_M: Vector3 = Vector3(320.0, 10.0, 540.0)
const FOCUS_A_CM: Vector2i = Vector2i(32000, 54000)
## Longe dos três povoados (o C, da LW-097d, fica em 560 m, 860 m; o raio de saída do S0 é de 120 m).
const FOCUS_FAR_M: Vector3 = Vector3(700.0, 10.0, 960.0)
const ENTER_RADIUS_CM: int = 8000
const MAX_S0: int = 50
const TIMEOUT_MIN: int = 30
## O primeiro pensamento de cada NPC cai nos minutos 1 a 10.
const FIRST_THINKS_DONE: int = 12
const SLEEP: String = "sleep"
const SLEEP_MIN: int = 480
const REST: int = 1
const MERCHANT: String = "merchant"
const A_MERCHANT_IDS: Array[int] = [61, 62]
const A_MERCHANT_HOME: String = "a_home_13"
const A_REST_PLACE: String = "a_rest_02"
const REST_ACTION: String = "rest"
const EAT_ACTION: String = "eat"
## Valor inicial de `rest` e índice/efeito de `hunger` (data/needs.json e data/action_effects.json), escritos à mão.
const REST_START_VALUE: int = 10
const HUNGER: int = 0
## LW-070b: às 6h a rotina troca o sono por `eat`, e o NPC em S0 reavalia como em S1. 6h12 = todos já trocaram e têm o Intent de `eat` (20 min).
const AFTER_THE_ROUTINE_SWAP: int = 6 * 60 + 12
const DAY: int = SimClock.MINUTES_PER_DAY
const CM_PER_M: float = 100.0

var _data: NpcLifeCheck.GameData
var _rigs: Array[Rig] = []


## Um jogo de teste: o runner, o módulo `npc` e os LodChanged que chegaram.
class Rig:
	extends RefCounted

	var runner: SimulationRunner
	var npc: NpcModule
	var changes: Array[LodChanged] = []

	func on_lod_changed(event: SimEvent) -> void:
		changes.append(event as LodChanged)

	func now() -> int:
		return runner.world.context.clock.total_minutes()


func before_all() -> void:
	_data = NpcLifeCheck.load_game_data()
	assert_eq(_data.problem, "", "Os dados reais do jogo carregam.")


func after_each() -> void:
	for rig: Rig in _rigs:
		rig.runner.finish()
	_rigs.clear()


# ---------------------------------------------------------------------------------------------------- montagem

## Jogo novo igual ao real. `s0_on` falso tira os parâmetros do LOD e dos Intents (o módulo como era antes da LW-070a).
func _rig(s0_on: bool = true, world_seed: int = WORLD_SEED) -> Rig:
	var setup: NpcSetup = NpcSetup.from_dir(DATA_DIR, SettlementService.new(_data.settlements, _data.places))
	assert_true(setup.result.ok, setup.result.message)
	if not s0_on:
		setup.definitions.lod_params = null
		setup.definitions.intent_params = null
	var rig: Rig = Rig.new()
	rig.runner = SimulationRunner.new(world_seed)
	var modules: GameModules = GameModules.register(rig.runner, _data.terrain, _data.points, setup)
	assert_true(modules.result.ok, modules.result.message)
	rig.npc = modules.npc
	rig.runner.world.context.events.subscribe("LodChanged", rig.on_lod_changed)
	rig.runner.start_new_game()
	if s0_on:
		assert_true(rig.npc.request_set_bodies_available(true).ok, "LW-070b: o teste faz o papel da apresentação e declara que há corpos.")
	_rigs.append(rig)
	return rig


## Jogo com o foco do ator no centro do assentamento A.
func _rig_with_focus() -> Rig:
	var rig: Rig = _rig()
	var focused: Result = rig.npc.request_set_focus(ACTOR_ID, FOCUS_A_M)
	assert_true(focused.ok, focused.message)
	return rig


func _body_of(intent: NpcIntent) -> Vector3:
	return Vector3(intent.destination_cm.x / CM_PER_M, 0.0, intent.destination_cm.y / CM_PER_M)


func _result_for(intent: NpcIntent, outcome: NpcActionResult.Outcome) -> NpcActionResult:
	return NpcActionResult.new(intent.npc_id, intent.action_serial, outcome, _body_of(intent))


## O NPC, entre os `ids`, mais perto do foco (empate: menor ID). É o último a perder a vaga de S0 quando os NPCs de fora andam perto do foco
## (ver o cabeçalho), então os testes de UM NPC o escolhem.
func _closest_to_focus(rig: Rig, ids: Array[int]) -> int:
	var closest_id: int = IdGenerator.NO_ID
	var closest_sq: int = 0
	for npc_id: int in ids:
		var npc: NpcModule.NpcQuery = rig.npc.peek_npc(npc_id)
		var delta_x: int = npc.x_cm - FOCUS_A_CM.x
		var delta_z: int = npc.z_cm - FOCUS_A_CM.y
		var distance_sq: int = delta_x * delta_x + delta_z * delta_z
		if closest_id == IdGenerator.NO_ID or distance_sq < closest_sq:
			closest_id = npc_id
			closest_sq = distance_sq
	assert_ne(closest_id, IdGenerator.NO_ID, "Esperava ao menos um NPC.")
	return closest_id


func _is_merchant(rig: Rig, npc_id: int) -> bool:
	return rig.npc.peek_npc(npc_id).occupation_id == MERCHANT


## Os `ids` que são comerciantes (`merchant` verdadeiro) ou os que NÃO são (falso), na mesma ordem.
func _of_kind(rig: Rig, ids: Array[int], merchant: bool) -> Array[int]:
	var picked: Array[int] = []
	for npc_id: int in ids:
		if _is_merchant(rig, npc_id) == merchant:
			picked.append(npc_id)
	return picked


func _merchants_in_s0(rig: Rig) -> Array[int]:
	return _of_kind(rig, rig.npc.lod.s0_ids(), true)


## O Intent pendente do NPC mais perto do foco, entre os que NÃO são comerciantes (padrão) ou, com `merchant`, entre os comerciantes.
func _closest_pending(rig: Rig, merchant: bool = false) -> NpcIntent:
	var waiting: Array[NpcIntent] = rig.npc.peek_pending_intents()
	var ids: Array[int] = []
	for intent: NpcIntent in waiting:
		ids.append(intent.npc_id)
	var closest_id: int = _closest_to_focus(rig, _of_kind(rig, ids, merchant))
	for intent: NpcIntent in waiting:
		if intent.npc_id == closest_id:
			return intent
	return null


func _first_pending_of_kind(rig: Rig, kind: NpcIntent.Kind, merchant: bool = false) -> NpcIntent:
	for intent: NpcIntent in rig.npc.peek_pending_intents():
		if intent.kind == kind and _is_merchant(rig, intent.npc_id) == merchant:
			return intent
	return null


func _discarded(rig: Rig) -> int:
	return rig.npc.intents.debug_summary()["discarded_results"]


## O corpo perfeito: cumpre, no fim previsto, cada Intent pendente (ARRIVED para ir, DONE para agir), no destino. Falha por regra ao terminar
## (sem comida, por exemplo) é um desfecho legítimo do jogo, não do teste. Devolve quantos cumpriu.
func _answer_due(rig: Rig) -> int:
	var answered: int = 0
	for intent: NpcIntent in rig.npc.peek_pending_intents():
		if rig.now() < rig.npc.peek_npc(intent.npc_id).action_ends_at:
			continue
		var outcome: NpcActionResult.Outcome = NpcActionResult.Outcome.ARRIVED if intent.kind == NpcIntent.Kind.MOVE_TO_PLACE else NpcActionResult.Outcome.DONE
		var reported: Result = rig.npc.request_report_npc_result(_result_for(intent, outcome))
		assert_true(reported.ok or reported.code == ActionRunner.CODE_ACTION_FAILED, reported.message)
		answered += 1
	return answered


## Anda `minutes` minutos com o corpo perfeito respondendo depois de cada passo; devolve quantos Intents foram cumpridos.
func _run_with_perfect_bodies(rig: Rig, minutes: int) -> int:
	var answered: int = 0
	for _minute: int in minutes:
		rig.runner.step_once()
		answered += _answer_due(rig)
		assert_true(rig.npc.lod.s0_ids().size() <= MAX_S0, "Nunca mais corpos que o limite de S0.")
	return answered


# ---------------------------------------------------------------------------------------------------- (a) Intent emitido, nada aplicado

func test_an_s0_npc_that_decides_an_action_emits_an_intent_and_nothing_is_applied() -> void:
	var rig: Rig = _rig_with_focus()
	rig.runner.run_steps(FIRST_THINKS_DONE)
	var s0: Array[int] = rig.npc.lod.s0_ids()
	assert_eq(s0.size(), MAX_S0, "Dos 62 do assentamento A, 50 ganham corpo.")
	# A PREMISSA, explícita: o comerciante (agenda própria: `rest`, não `sleep`) está entre os 12 de fora do S0 neste minuto, ainda a caminho do
	# descanso, com a caminhada começada ANTES de ter corpo (sem Intent). É só por isso que todo Intent abaixo é de sono: se a geometria mudar,
	# este teste falha AQUI, dizendo o porquê, e não por um Intent de comerciante no meio da conferência do sono.
	assert_eq(_merchants_in_s0(rig).size(), 0, "Os comerciantes (casa a 56 m do foco) estão entre os 12 de fora do S0 no minuto %d." % FIRST_THINKS_DONE)
	for merchant_id: int in A_MERCHANT_IDS:
		var walking: NpcModule.NpcQuery = rig.npc.peek_npc(merchant_id)
		assert_eq([walking.action_id, walking.action_target_place_id, rig.npc.intents.has_pending(merchant_id)], [ActionRunner.GO_TO_PLACE_ID, A_REST_PLACE, false], "O comerciante caminha ao descanso, sem Intent.")
	var sleepers: Array[int] = _of_kind(rig, s0, false)
	assert_eq(sleepers.size(), s0.size(), "Quem está em S0 é gente comum, que dorme.")
	var intents: Array[NpcIntent] = rig.npc.peek_pending_intents()
	assert_eq(intents.size(), s0.size(), "Todo NPC em S0 que já pensou emitiu um Intent.")
	for intent: NpcIntent in intents:
		assert_true(s0.has(intent.npc_id), "Só quem tem corpo emite Intent.")
		var npc: NpcModule.NpcQuery = rig.npc.peek_npc(intent.npc_id)
		assert_eq([npc.action_id, npc.action_serial], [SLEEP, intent.action_serial], "O Intent é da ação que o NPC começou.")
		assert_true(npc.need_values[REST] >= REST_START_VALUE, "Nenhum efeito do sono foi aplicado (o `rest` não foi aliviado); o relógio passa nas necessidades a cada pensamento, como em S1.")
		assert_eq([intent.kind, intent.expected_minutes], [NpcIntent.Kind.ACT_AT_PLACE, SLEEP_MIN])
	for npc_id: int in rig.npc.peek_npc_ids():
		if not s0.has(npc_id):
			assert_false(rig.npc.intents.has_pending(npc_id), "NPC sem corpo começa a ação em modo abstrato, sem Intent.")


# ---------------------------------------------------------------------------------------------------- (b) o tempo não encerra a ação

func test_with_a_pending_intent_the_planned_end_passing_changes_nothing() -> void:
	var rig: Rig = _rig_with_focus()
	rig.runner.run_steps(AFTER_THE_ROUTINE_SWAP)
	var intent: NpcIntent = _closest_pending(rig)
	rig.runner.run_steps(rig.npc.peek_npc(intent.npc_id).action_ends_at - rig.now())
	var before: NpcModule.NpcQuery = rig.npc.peek_npc(intent.npc_id)
	rig.runner.run_steps(5)
	assert_gt(rig.now(), before.action_ends_at, "O relógio passou do fim planejado.")
	var after: NpcModule.NpcQuery = rig.npc.peek_npc(intent.npc_id)
	assert_true(rig.npc.intents.has_pending(intent.npc_id), "O Intent segue pendente (o limite é 30 min depois do fim).")
	assert_eq([after.action_id, after.action_serial, after.action_ends_at, after.needs_updated_at], [before.action_id, before.action_serial, before.action_ends_at, before.needs_updated_at], "A ação continua exatamente como estava.")
	assert_eq(after.need_values, before.need_values, "Nenhum efeito foi aplicado pelo tempo.")
	assert_gt(after.next_think_time, rig.now(), "O NPC com Intent pendente não está no ponto de pensar.")


func test_a_pending_move_intent_does_not_arrive_by_itself() -> void:
	var rig: Rig = _rig_with_focus()
	var move: NpcIntent = null
	for _minute: int in DAY:
		rig.runner.step_once()
		_answer_due(rig)
		move = _first_pending_of_kind(rig, NpcIntent.Kind.MOVE_TO_PLACE)
		if move != null:
			break
	assert_not_null(move, "Depois do sono os NPCs vão ao trabalho: aparece um Intent de ir.")
	var before: NpcModule.NpcQuery = rig.npc.peek_npc(move.npc_id)
	assert_eq(before.action_id, ActionRunner.GO_TO_PLACE_ID)
	rig.runner.run_steps(before.action_ends_at + 5 - rig.now())
	var after: NpcModule.NpcQuery = rig.npc.peek_npc(move.npc_id)
	assert_true(rig.npc.intents.has_pending(move.npc_id))
	assert_eq([after.action_id, after.place_id, after.x_cm, after.z_cm, after.action_ends_at], [before.action_id, before.place_id, before.x_cm, before.z_cm, before.action_ends_at], "Sem resultado do corpo o NPC não chega sozinho.")


# ---------------------------------------------------------------------------------------------------- (c) e (e) sucesso, uma vez, e resultado velho

func test_a_success_result_applies_the_effects_once_and_the_npc_thinks_again_within_a_minute() -> void:
	var rig: Rig = _rig_with_focus()
	rig.runner.run_steps(AFTER_THE_ROUTINE_SWAP)
	var intent: NpcIntent = _closest_pending(rig)
	var before: NpcModule.NpcQuery = rig.npc.peek_npc(intent.npc_id)
	rig.runner.run_steps(before.action_ends_at - rig.now())
	var done: NpcActionResult = _result_for(intent, NpcActionResult.Outcome.DONE)
	var reported: Result = rig.npc.request_report_npc_result(done)
	assert_true(reported.ok, reported.message)
	var after: NpcModule.NpcQuery = rig.npc.peek_npc(intent.npc_id)
	assert_eq(after.action_id, before.action_id, "Logo depois do relato a ação só tem o fim marcado: o pensador ainda não a encerrou (LW-070d).")
	assert_gt(after.need_values[HUNGER], 0, "E o efeito de `eat` ainda não entrou: a fome só zera no pensamento seguinte (LW-070d).")
	assert_true(after.next_think_time <= rig.now() + 1, "Volta a pensar no minuto seguinte, no máximo.")
	assert_false(rig.npc.intents.has_pending(intent.npc_id))
	rig.runner.step_once()
	var thinking: NpcModule.NpcQuery = rig.npc.peek_npc(intent.npc_id)
	assert_eq(thinking.need_values[HUNGER], 0, "`eat` alivia `hunger` em 60: os efeitos entraram, no pensamento seguinte.")
	assert_eq(thinking.needs_updated_at, rig.now(), "O pensador aplica o efeito no fim planejado e leva as necessidades até o minuto do pensamento (LW-070d).")
	assert_eq(thinking.action_serial, intent.action_serial + 1, "Pensou de novo no minuto seguinte, encerrou a ação (o NPC ficou livre) e começou a próxima ação.")
	var next_intent: NpcIntent = null
	for waiting_intent: NpcIntent in rig.npc.peek_pending_intents():
		if waiting_intent.npc_id == intent.npc_id:
			next_intent = waiting_intent
	assert_not_null(next_intent, "Em S0, a próxima ação também nasce com Intent.")
	var discarded_before: int = _discarded(rig)
	var again: Result = rig.npc.request_report_npc_result(done)
	assert_eq(again.code, NpcIntentBoard.CODE_STALE_RESULT, "O mesmo resultado, agora de uma ação velha, é descartado.")
	assert_eq(_discarded(rig), discarded_before + 1, "E contado.")
	var unchanged: NpcModule.NpcQuery = rig.npc.peek_npc(intent.npc_id)
	assert_eq([unchanged.need_values, unchanged.action_id, unchanged.action_serial, unchanged.next_think_time], [thinking.need_values, thinking.action_id, thinking.action_serial, thinking.next_think_time], "Resultado descartado não muda o NPC.")


## O irmão do teste acima para o comerciante: às 6h ele caminha para casa (Intent de ir), então o desfecho do corpo é ARRIVED; DONE é recusado.
func test_a_merchants_walk_home_takes_arrived_and_refuses_done_and_the_npc_thinks_again_within_a_minute() -> void:
	var rig: Rig = _rig_with_focus()
	rig.runner.run_steps(AFTER_THE_ROUTINE_SWAP)
	var intent: NpcIntent = _closest_pending(rig, true)
	var before: NpcModule.NpcQuery = rig.npc.peek_npc(intent.npc_id)
	assert_eq([before.action_id, intent.kind, intent.place_id], [ActionRunner.GO_TO_PLACE_ID, NpcIntent.Kind.MOVE_TO_PLACE, A_MERCHANT_HOME], "Sanidade: às 6h o comerciante caminha para casa, com Intent de ir.")
	rig.runner.run_steps(before.action_ends_at - rig.now())
	var at_the_end: NpcModule.NpcQuery = rig.npc.peek_npc(intent.npc_id)
	var refused: Result = rig.npc.request_report_npc_result(_result_for(intent, NpcActionResult.Outcome.DONE))
	assert_eq(refused.code, NpcIntentBoard.CODE_OUTCOME_MISMATCH, "DONE só vale para agir no local: para um Intent de ir é recusado.")
	assert_true(rig.npc.intents.has_pending(intent.npc_id), "E o Intent segue esperando o resultado certo.")
	var kept: NpcModule.NpcQuery = rig.npc.peek_npc(intent.npc_id)
	assert_eq([kept.need_values, kept.action_id, kept.action_serial, kept.next_think_time], [at_the_end.need_values, at_the_end.action_id, at_the_end.action_serial, at_the_end.next_think_time], "Resultado recusado não muda o NPC.")
	var arrived: NpcActionResult = _result_for(intent, NpcActionResult.Outcome.ARRIVED)
	var reported: Result = rig.npc.request_report_npc_result(arrived)
	assert_true(reported.ok, reported.message)
	var after: NpcModule.NpcQuery = rig.npc.peek_npc(intent.npc_id)
	assert_eq(after.action_id, before.action_id, "Logo depois do relato a caminhada só tem o fim marcado: o pensador ainda não a encerrou (LW-070d).")
	assert_true(after.next_think_time <= rig.now() + 1, "Volta a pensar no minuto seguinte, no máximo.")
	assert_false(rig.npc.intents.has_pending(intent.npc_id))
	rig.runner.step_once()
	var home: NpcModule.NpcQuery = rig.npc.peek_npc(intent.npc_id)
	assert_eq([home.action_id, home.action_serial, home.place_id], [EAT_ACTION, intent.action_serial + 1, A_MERCHANT_HOME], "Pensou de novo no minuto seguinte, encerrou a caminhada (o comerciante está em casa) e começou a próxima ação: comer.")
	assert_eq([home.x_cm, home.z_cm], [intent.destination_cm.x, intent.destination_cm.y], "E o corpo o deixou no destino.")
	var level_at_home: int = rig.npc.lod.level_of(intent.npc_id)
	assert_eq(level_at_home, NpcLod.LEVEL_S1, "Em casa, a 56 m do foco, o comerciante já está entre os 12 de fora do S0 (a regra de proximidade vale para ele como para todos).")
	assert_eq(rig.npc.intents.has_pending(intent.npc_id), level_at_home == NpcLod.LEVEL_S0, "A próxima ação nasce com Intent se, e só se, o NPC tem corpo: sem corpo, o `eat` segue em modo abstrato.")
	var discarded_before: int = _discarded(rig)
	var again: Result = rig.npc.request_report_npc_result(arrived)
	assert_eq(again.code, NpcIntentBoard.CODE_STALE_RESULT, "O mesmo ARRIVED, agora de uma ação velha, é descartado.")
	assert_eq(_discarded(rig), discarded_before + 1, "E contado.")
	var unchanged: NpcModule.NpcQuery = rig.npc.peek_npc(intent.npc_id)
	assert_eq([unchanged.need_values, unchanged.action_id, unchanged.action_serial, unchanged.next_think_time], [home.need_values, home.action_id, home.action_serial, home.next_think_time], "Resultado descartado não muda o NPC.")


func test_a_result_in_the_very_minute_the_intent_was_born_also_wakes_the_npc() -> void:
	var rig: Rig = _rig_with_focus()
	var born: NpcIntent = null
	for _minute: int in FIRST_THINKS_DONE:
		rig.runner.step_once()
		for waiting_intent: NpcIntent in rig.npc.peek_pending_intents():
			if rig.npc.peek_npc(waiting_intent.npc_id).action_started_at == rig.now():
				born = waiting_intent
		if born != null:
			break
	assert_not_null(born, "Algum NPC em S0 começou uma ação neste minuto.")
	var before: NpcModule.NpcQuery = rig.npc.peek_npc(born.npc_id)
	assert_gt(before.next_think_time, rig.now() + 1, "Recém-agendado: o próximo pensamento está longe (o intervalo ou o fim da ação).")
	var blocked: Result = rig.npc.request_report_npc_result(NpcActionResult.new(born.npc_id, born.action_serial, NpcActionResult.Outcome.BLOCKED, _body_of(born)))
	assert_true(blocked.ok, blocked.message)
	assert_true(rig.npc.peek_npc(born.npc_id).next_think_time <= rig.now() + 1, "Acordou para pensar no minuto seguinte: não espera o fim de uma ação que o corpo nem fez.")


# ---------------------------------------------------------------------------------------------------- (d) sem resultado, o tempo limite

func test_without_a_result_the_action_is_cancelled_at_the_timeout_without_effect_and_the_npc_thinks_again() -> void:
	var rig: Rig = _rig_with_focus()
	rig.runner.run_steps(AFTER_THE_ROUTINE_SWAP)
	var intent: NpcIntent = _closest_pending(rig)
	var before: NpcModule.NpcQuery = rig.npc.peek_npc(intent.npc_id)
	var deadline: int = before.action_ends_at + TIMEOUT_MIN
	rig.runner.run_steps(deadline - 1 - rig.now())
	assert_true(rig.npc.intents.has_pending(intent.npc_id), "Um minuto antes do limite o Intent ainda espera.")
	rig.runner.step_once()
	assert_eq(rig.now(), deadline)
	for waiting_intent: NpcIntent in rig.npc.peek_pending_intents():
		if waiting_intent.npc_id == intent.npc_id:
			assert_ne(waiting_intent.action_serial, intent.action_serial, "No minuto do limite o Intent antigo venceu (o que existe agora é o da ação nova).")
	var after: NpcModule.NpcQuery = rig.npc.peek_npc(intent.npc_id)
	assert_eq(after.action_serial, intent.action_serial + 1, "A ação foi cancelada e o NPC pensou de novo no mesmo passo.")
	assert_ne(after.action_id, "", "E já começou outra coisa.")
	assert_true(after.need_values[HUNGER] >= before.need_values[HUNGER], "Cancelada por tempo: o alívio de `eat` NÃO entrou.")
	assert_gt(rig.npc.intents.debug_summary()["timed_out_intents"], 0)
	var discarded_before: int = _discarded(rig)
	var late: Result = rig.npc.request_report_npc_result(_result_for(intent, NpcActionResult.Outcome.DONE))
	assert_eq(late.code, NpcIntentBoard.CODE_STALE_RESULT, "Resultado tardio é ignorado.")
	assert_eq(_discarded(rig), discarded_before + 1)
	assert_eq(rig.npc.peek_npc(intent.npc_id).need_values, after.need_values, "E não muda o NPC.")


# ---------------------------------------------------------------------------------------------------- (f) o foco se afasta

func test_when_the_focus_moves_away_the_intent_is_released_and_the_action_goes_on_abstractly() -> void:
	var rig: Rig = _rig_with_focus()
	rig.runner.run_steps(FIRST_THINKS_DONE)
	var intent: NpcIntent = _closest_pending(rig)
	var before: NpcModule.NpcQuery = rig.npc.peek_npc(intent.npc_id)
	assert_true(rig.npc.request_set_focus(ACTOR_ID, FOCUS_FAR_M).ok, "O mesmo ator vai para longe.")
	rig.runner.step_once()
	assert_eq(rig.npc.lod.s0_ids().size(), 0, "Ninguém mais está em S0.")
	assert_eq(rig.npc.peek_pending_intents().size(), 0, "Os Intents foram soltos.")
	assert_eq(rig.npc.intents.debug_summary()["timed_out_intents"], 0, "Sair de S0 não é tempo limite.")
	var left: NpcModule.NpcQuery = rig.npc.peek_npc(intent.npc_id)
	assert_eq([left.action_id, left.action_serial, left.action_ends_at], [before.action_id, before.action_serial, before.action_ends_at], "A ação segue, com o tempo que falta.")
	rig.runner.run_steps(before.action_ends_at + 12 - rig.now())
	var finished: NpcModule.NpcQuery = rig.npc.peek_npc(intent.npc_id)
	assert_gt(finished.action_serial, before.action_serial, "O pensador abstrato assumiu o NPC (terminou ou trocou a ação) e ele seguiu a vida.")
	var late: Result = rig.npc.request_report_npc_result(_result_for(intent, NpcActionResult.Outcome.DONE))
	assert_eq(late.code, NpcIntentBoard.CODE_STALE_RESULT, "O corpo antigo já não manda: nada é aplicado duas vezes.")
	assert_eq(rig.npc.peek_npc(intent.npc_id).need_values, finished.need_values)


# ---------------------------------------------------------------------------------------------------- (g) entrar em S0 no meio da ação

func test_entering_s0_in_the_middle_of_an_abstract_action_finishes_it_abstractly_and_the_next_one_has_an_intent() -> void:
	var rig: Rig = _rig()
	rig.runner.run_steps(30)
	assert_eq(rig.npc.peek_pending_intents().size(), 0, "Sem foco ninguém tem corpo.")
	assert_true(rig.npc.request_set_focus(ACTOR_ID, FOCUS_A_M).ok)
	rig.runner.step_once()
	var s0: Array[int] = rig.npc.lod.s0_ids()
	assert_eq(s0.size(), MAX_S0, "Cinquenta NPCs entram em S0 no meio do sono.")
	assert_eq(rig.npc.peek_pending_intents().size(), 0, "Nenhum Intent para a ação que já estava em curso.")
	var npc_id: int = _closest_to_focus(rig, _of_kind(rig, s0, false))
	var sleeping: NpcModule.NpcQuery = rig.npc.peek_npc(npc_id)
	assert_eq([sleeping.action_id, sleeping.action_serial], [SLEEP, 1])
	for _minute: int in DAY:
		rig.runner.step_once()
		if rig.npc.peek_npc(npc_id).action_serial > 1:
			break
		assert_false(rig.npc.intents.has_pending(npc_id), "Enquanto a ação que já estava em curso não acaba, não há Intent para ela.")
	var awake: NpcModule.NpcQuery = rig.npc.peek_npc(npc_id)
	assert_eq(awake.action_serial, 2, "O sono acabou em modo abstrato (a rotina das 6h o trocou) e o NPC começou a próxima ação.")
	assert_lt(rig.now(), sleeping.action_ends_at, "E foi a rotina, não o relógio, que o acordou: o pensador abstrato o tratou como qualquer NPC sem Intent.")
	assert_true(awake.need_values[REST] <= 10, "O alívio proporcional do sono entrou (pelo runner abstrato).")
	var next_intent: NpcIntent = null
	for waiting_intent: NpcIntent in rig.npc.peek_pending_intents():
		if waiting_intent.npc_id == npc_id:
			next_intent = waiting_intent
	assert_not_null(next_intent, "A PRÓXIMA ação já nasce com Intent.")
	assert_eq(next_intent.action_serial, 2)


## O irmão do teste acima para o comerciante: ele não dorme, descansa (`rest`, 60 min) em um local de descanso a 17 m do foco.
func test_entering_s0_in_the_middle_of_a_merchants_rest_finishes_it_abstractly_and_the_next_one_has_an_intent() -> void:
	var rig: Rig = _rig()
	rig.runner.run_steps(30)
	assert_true(rig.npc.request_set_focus(ACTOR_ID, FOCUS_A_M).ok)
	rig.runner.step_once()
	assert_eq(_merchants_in_s0(rig), A_MERCHANT_IDS, "Os dois comerciantes, no descanso a 17 m do foco, estão entre os 50 que entram em S0.")
	assert_eq(rig.npc.peek_pending_intents().size(), 0, "Nenhum Intent para a ação que já estava em curso.")
	var npc_id: int = _closest_to_focus(rig, _merchants_in_s0(rig))
	var resting: NpcModule.NpcQuery = rig.npc.peek_npc(npc_id)
	assert_eq([resting.action_id, resting.action_serial, resting.place_id], [REST_ACTION, 2, A_REST_PLACE], "Série 1: a caminhada ao descanso; série 2: o 1º `rest`.")
	for _minute: int in DAY:
		rig.runner.step_once()
		if rig.npc.peek_npc(npc_id).action_serial > 2:
			break
		assert_false(rig.npc.intents.has_pending(npc_id), "Enquanto o `rest` que já estava em curso não acaba, não há Intent para ele.")
	var next: NpcModule.NpcQuery = rig.npc.peek_npc(npc_id)
	assert_eq([next.action_id, next.action_serial], [REST_ACTION, 3], "O `rest` acabou em modo abstrato (série 2 para 3) e o comerciante começou o ciclo seguinte.")
	assert_gte(rig.now(), resting.action_ends_at, "E foi o relógio que o terminou, no fim previsto: o `rest` não é trocado no meio pela rotina.")
	assert_eq(next.need_values[REST], 0, "O alívio do `rest` (-20) entrou, pelo runner abstrato: a necessidade `rest` chegou a 0.")
	var next_intent: NpcIntent = null
	for waiting_intent: NpcIntent in rig.npc.peek_pending_intents():
		if waiting_intent.npc_id == npc_id:
			next_intent = waiting_intent
	assert_not_null(next_intent, "O PRÓXIMO `rest` já nasce com Intent.")
	assert_eq([next_intent.action_serial, next_intent.kind, next_intent.place_id], [3, NpcIntent.Kind.ACT_AT_PLACE, A_REST_PLACE], "Descansar no local de descanso: agir no local.")


# ---------------------------------------------------------------------------------------------------- (h) limite de S0

func test_the_closest_fifty_of_the_sixty_two_get_a_body() -> void:
	var rig: Rig = _rig_with_focus()
	rig.runner.step_once()
	var ranked: Array = []
	for npc_id: int in rig.npc.peek_npc_ids():
		var npc: NpcModule.NpcQuery = rig.npc.peek_npc(npc_id)
		var delta_x: int = npc.x_cm - FOCUS_A_CM.x
		var delta_z: int = npc.z_cm - FOCUS_A_CM.y
		var distance_sq: int = delta_x * delta_x + delta_z * delta_z
		if distance_sq <= ENTER_RADIUS_CM * ENTER_RADIUS_CM:
			ranked.append([distance_sq, npc_id])
	ranked.sort_custom(func(first: Array, second: Array) -> bool: return first[0] < second[0] or (first[0] == second[0] and first[1] < second[1]))
	assert_eq(ranked.size(), 62, "Os 62 do assentamento A (60 moradores e 2 comerciantes) estão a menos de 80 m do foco.")
	var expected: Array[int] = []
	for index: int in MAX_S0:
		expected.append(ranked[index][1])
	expected.sort()
	assert_eq(rig.npc.lod.s0_ids(), expected, "Ficam em S0 os 50 mais perto (empate pelo menor ID).")
	assert_eq(rig.changes.size(), MAX_S0, "Um LodChanged por NPC que ganhou corpo.")
	# Os comerciantes entram na MESMA regra de proximidade (nenhuma regra por ofício): a casa deles, a 56 m, é a mais longe do foco, então são os
	# dois últimos do ranking e ficam entre os 12 de fora do S0.
	var ranked_ids: Array[int] = []
	for entry: Array in ranked:
		ranked_ids.append(entry[1])
	for merchant_id: int in A_MERCHANT_IDS:
		assert_gte(ranked_ids.find(merchant_id), MAX_S0, "O comerciante %d está no ranking, entre os 12 mais longe do foco." % merchant_id)
		assert_false(rig.npc.lod.s0_ids().has(merchant_id), "E por isso fica sem corpo.")


# ---------------------------------------------------------------------------------------------------- (i) sem foco o LOD não muda o mundo

func test_without_any_focus_the_world_hash_after_a_day_is_the_same_with_or_without_lod_and_intents() -> void:
	var with_s0: Rig = _rig(true)
	var without_s0: Rig = _rig(false)
	with_s0.runner.run_days(1)
	without_s0.runner.run_days(1)
	assert_eq(with_s0.changes.size(), 0, "Sem foco nenhum LodChanged sai (então nenhum ID de evento é gasto).")
	assert_eq(with_s0.runner.world.state_hash(), without_s0.runner.world.state_hash(), "O hash depois de 1 dia é o mesmo com o LOD e os Intents ligados.")
	assert_eq(with_s0.npc.peek_pending_intents().size(), 0)


# ---------------------------------------------------------------------------------------------------- (j) e (k) determinismo e validação

func test_the_same_sequence_with_a_focus_gives_the_same_world_and_the_module_validates() -> void:
	var hashes: Array[String] = []
	var answered_per_run: Array[int] = []
	for _run: int in 2:
		var rig: Rig = _rig_with_focus()
		answered_per_run.append(_run_with_perfect_bodies(rig, DAY))
		hashes.append(rig.runner.world.state_hash())
		assert_gt(rig.changes.size(), 0, "Houve trocas de nível com o foco.")
		assert_eq(rig.npc.validate().size(), 0, str(rig.npc.validate()))
		assert_eq(rig.runner.world.validate().size(), 0, str(rig.runner.world.validate()))
		assert_eq(rig.npc.peek_counts()["alive"], 138, "Todos vivos.")
	assert_gt(answered_per_run[0], MAX_S0, "O corpo perfeito cumpriu muitos Intents ao longo do dia (mais de uma ação por NPC).")
	assert_eq(answered_per_run[0], answered_per_run[1])
	assert_eq(hashes[0], hashes[1], "Mesma sequência com foco, mesmo hash.")
