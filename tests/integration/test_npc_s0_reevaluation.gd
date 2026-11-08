extends GutTest
## LW-070b: o NPC com corpo (S0) e Intent pendente REAVALIA a ação pelos mesmos motivos que o NPC sem corpo (S1): necessidade urgente ou crítica
## (LW-081), alarme (LW-076), fim do bloco da rotina e morte. Se escolhe OUTRA ação, o Intent é cancelado explicitamente (sem efeito, e some de
## `peek_pending_intents`) e a ação nova nasce com Intent; se escolhe a mesma (inércia), segue esperando o corpo. Sem janela, com o jogo montado
## como o real (dados reais de res://data, 100 NPCs, relógio de verdade); o "corpo" é o próprio teste e, aqui, não responde nada: os Intents
## ficam pendentes até a reavaliação os cancelar. Cada cenário anda DOIS mundos iguais em passo travado: o S0 (corpos ligados, foco no assentamento
## A) e o gêmeo S1 (mesma semente, sem corpos); o que o gêmeo S1 faz, o NPC com corpo tem de fazer no mesmo minuto. Só vale até o fim previsto da
## primeira ação nova: dali em diante o gêmeo S1 a termina pelo relógio e o NPC com corpo espera o corpo, e isso é de propósito. [LIM] Cancelar
## o sono pela reavaliação NÃO aplica o efeito proporcional que o modo S1 aplicaria (nada foi cumprido de verdade): o `rest` do NPC com corpo
## fica mais alto que o do gêmeo.

const DATA_DIR: String = "res://data"
const WORLD_SEED: int = 11
const ACTOR_ID: int = 77
const FOCUS_A_M: Vector3 = Vector3(320.0, 10.0, 540.0)
const FOCUS_A_CM: Vector2i = Vector2i(32000, 54000)
const MAX_S0: int = 50
const SLEEP: String = "sleep"
const EAT: String = "eat"
const HUNGER: int = 0
const REST: int = 1
const REST_START_VALUE: int = 10
const DAY: int = SimClock.MINUTES_PER_DAY
const CM_PER_M: float = 100.0
## Cenários: a rotina de sempre; fome que sobe 60 por hora (urgente e crítica durante o sono); fome que sobe 100 por hora, sem comida e letal em
## 2 h (o NPC morre durante o sono).
const PLAIN: int = 0
const HUNGRY: int = 1
const STARVING: int = 2
const HUNGRY_RATE_PER_HOUR: int = 60
## Com a fome subindo 60 por hora ela fica urgente (65) aos 45 min: aos 30 todos ainda dormem.
const HUNGRY_CHECKPOINT_MIN: int = 30
const STARVING_RATE_PER_HOUR: int = 100
const WEAKEN_HOURS: int = 1
const LETHAL_HOURS: int = 2
const FOOD_SETTLEMENTS: Array[String] = ["test_settlement_a", "test_settlement_b"]
## Alarme forte no centro do assentamento A (gravidade máxima), no meio do sono.
const ALARM_SEVERITY: int = 10
const ALARM_AT_MIN: int = 120
const BEFORE_THE_SWAP_MIN: int = 5 * 60 + 30
const ROUTINE_SWAP_MIN: int = 6 * 60
## O pensamento acontece a cada 10 min (data/npc_params.json): a troca da rotina cai nos 10 min seguintes às 6h.
const THINK_INTERVAL_MIN: int = 10
const SEARCH_LIMIT_MIN: int = 5 * 60

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


## Os dois mundos gêmeos de um cenário e quem tem corpo no S0 (preenchido por `_settle_into_the_sleep`).
class Pair:
	extends RefCounted

	var s0: Rig
	var s1: Rig
	var ids: Array[int] = []
	## Os Intents pendentes do sono no S0, por NPC (cópias tiradas antes da reavaliação).
	var sleep_intents: Dictionary[int, NpcIntent] = {}


## O que aconteceu com um NPC no primeiro minuto em que ele deixou a ação de partida, nos dois mundos (-1 = ainda não deixou).
class Reaction:
	extends RefCounted

	var minute0: int = -1
	var minute1: int = -1
	var action0: String = ""
	var action1: String = ""
	var serial0: int = 0
	var serial1: int = 0
	## Contador da ação do Intent pendente do NPC com corpo nesse minuto (0 = nenhum Intent pendente).
	var intent_serial0: int = 0


func before_all() -> void:
	_data = NpcLifeCheck.load_game_data()
	assert_eq(_data.problem, "", "Os dados reais do jogo carregam.")


func after_each() -> void:
	for rig: Rig in _rigs:
		rig.runner.finish()
	_rigs.clear()


# ---------------------------------------------------------------------------------------------------- montagem

## Jogo novo igual ao real, em build de desenvolvimento (o alarme e o estoque de comida são comandos de desenvolvimento), com o foco do ator no
## centro do assentamento A. `bodies_on`: liga os corpos (o teste faz o papel da apresentação).
func _rig(bodies_on: bool, scenario: int = PLAIN) -> Rig:
	var setup: NpcSetup = NpcSetup.from_dir(DATA_DIR, SettlementService.new(_data.settlements, _data.places), true)
	assert_true(setup.result.ok, setup.result.message)
	var hunger: NeedDef = setup.need_defs[HUNGER]
	if scenario == HUNGRY:
		hunger.rate_per_hour = HUNGRY_RATE_PER_HOUR
	elif scenario == STARVING:
		hunger.rate_per_hour = STARVING_RATE_PER_HOUR
		hunger.weaken_after_hours = WEAKEN_HOURS
		hunger.lethal_after_hours = LETHAL_HOURS
	var rig: Rig = Rig.new()
	rig.runner = SimulationRunner.new(WORLD_SEED)
	var modules: GameModules = GameModules.register(rig.runner, _data.terrain, _data.points, setup)
	assert_true(modules.result.ok, modules.result.message)
	rig.npc = modules.npc
	rig.runner.world.context.events.subscribe("LodChanged", rig.on_lod_changed)
	rig.runner.start_new_game()
	if scenario == STARVING:
		for settlement_id: String in FOOD_SETTLEMENTS:
			assert_true(rig.npc.request_set_food_stock(settlement_id, 0).ok)
	assert_true(rig.npc.request_set_focus(ACTOR_ID, FOCUS_A_M).ok)
	if bodies_on:
		assert_true(rig.npc.request_set_bodies_available(true).ok)
	_rigs.append(rig)
	return rig


## Os dois mundos do cenário, andados em passo travado até `minute` (todos dormindo, os de S0 com o Intent do sono pendente).
func _pair_asleep_at(minute: int, scenario: int = PLAIN) -> Pair:
	var pair: Pair = Pair.new()
	pair.s0 = _rig(true, scenario)
	pair.s1 = _rig(false, scenario)
	_walk_both(pair, minute)
	pair.ids = pair.s0.npc.lod.s0_ids()
	assert_eq(pair.ids.size(), MAX_S0, "Dos 60 do assentamento A, 50 ganham corpo.")
	for intent: NpcIntent in pair.s0.npc.peek_pending_intents():
		pair.sleep_intents[intent.npc_id] = intent
	assert_eq(pair.sleep_intents.size(), MAX_S0, "Todo NPC com corpo que já pensou tem o Intent do sono pendente.")
	for npc_id: int in pair.ids:
		assert_eq(pair.s0.npc.peek_npc(npc_id).action_id, SLEEP, "Sanidade: dormindo.")
		assert_eq(pair.s1.npc.peek_npc(npc_id).action_id, SLEEP, "Sanidade: o gêmeo S1 também.")
	return pair


func _walk_both(pair: Pair, until_minute: int) -> void:
	while pair.s0.now() < until_minute:
		_step_both(pair)


func _step_both(pair: Pair) -> void:
	pair.s0.runner.step_once()
	pair.s1.runner.step_once()


func _body_of(intent: NpcIntent) -> Vector3:
	return Vector3(intent.destination_cm.x / CM_PER_M, 0.0, intent.destination_cm.y / CM_PER_M)


func _result_for(intent: NpcIntent, outcome: NpcActionResult.Outcome) -> NpcActionResult:
	return NpcActionResult.new(intent.npc_id, intent.action_serial, outcome, _body_of(intent))


func _discarded(rig: Rig) -> int:
	return rig.npc.intents.debug_summary()["discarded_results"]


## Anda os dois mundos em passo travado até todos os NPCs de `pair.ids` terem deixado `from_action` nos dois (ou `limit` minutos) e devolve, por
## NPC, o que aconteceu no primeiro minuto em que a ação deixou de ser `from_action` em cada mundo. No mundo S0 guarda também o Intent pendente
## desse minuto.
func _first_change_minutes(pair: Pair, from_action: String, limit: int) -> Dictionary[int, Reaction]:
	var reactions: Dictionary[int, Reaction] = {}
	for npc_id: int in pair.ids:
		reactions[npc_id] = Reaction.new()
	var end_minute: int = pair.s0.now() + limit
	var open_count: int = pair.ids.size() * 2
	while pair.s0.now() < end_minute and open_count > 0:
		_step_both(pair)
		for npc_id: int in pair.ids:
			var reaction: Reaction = reactions[npc_id]
			if reaction.minute0 < 0:
				var with_body: NpcModule.NpcQuery = pair.s0.npc.peek_npc(npc_id)
				if with_body.action_id != from_action:
					reaction.minute0 = pair.s0.now()
					reaction.action0 = with_body.action_id
					reaction.serial0 = with_body.action_serial
					var current: NpcIntent = _pending_of(pair.s0, npc_id)
					reaction.intent_serial0 = current.action_serial if current != null else 0
					open_count -= 1
			if reaction.minute1 < 0:
				var without_body: NpcModule.NpcQuery = pair.s1.npc.peek_npc(npc_id)
				if without_body.action_id != from_action:
					reaction.minute1 = pair.s1.now()
					reaction.action1 = without_body.action_id
					reaction.serial1 = without_body.action_serial
					open_count -= 1
	return reactions


## NPCs cuja ação (id e contador) difere entre o mundo S0 e o gêmeo S1.
func _differing(pair: Pair) -> Array[int]:
	var differing: Array[int] = []
	for npc_id: int in pair.ids:
		var with_body: NpcModule.NpcQuery = pair.s0.npc.peek_npc(npc_id)
		var without_body: NpcModule.NpcQuery = pair.s1.npc.peek_npc(npc_id)
		if with_body.action_id != without_body.action_id or with_body.action_serial != without_body.action_serial:
			differing.append(npc_id)
	return differing


## Os NPCs que mudaram de ação no gêmeo S1, em ordem crescente.
func _changed_in_s1(reactions: Dictionary[int, Reaction]) -> Array[int]:
	var changed: Array[int] = []
	for npc_id: int in reactions:
		if reactions[npc_id].minute1 >= 0:
			changed.append(npc_id)
	changed.sort()
	return changed


## O Intent pendente do NPC, ou nulo.
func _pending_of(rig: Rig, npc_id: int) -> NpcIntent:
	for intent: NpcIntent in rig.npc.peek_pending_intents():
		if intent.npc_id == npc_id:
			return intent
	return null


## O corpo perfeito: cumpre, no fim previsto, cada Intent pendente (ARRIVED para ir, DONE para agir). Falha por regra ao terminar é um
## desfecho legítimo do jogo. Devolve quantos cumpriu.
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


# ---------------------------------------------------------------------------------------------------- (d) necessidade urgente

func test_an_urgent_need_cancels_the_sleep_intent_and_the_s0_npc_reacts_in_the_same_minute_as_its_s1_twin() -> void:
	var pair: Pair = _pair_asleep_at(HUNGRY_CHECKPOINT_MIN, HUNGRY)
	var reactions: Dictionary[int, Reaction] = _first_change_minutes(pair, SLEEP, SEARCH_LIMIT_MIN)
	var changed: Array[int] = _changed_in_s1(reactions)
	assert_gt(changed.size(), 0, "Sanidade: no gêmeo S1 a fome urgente acordou ao menos um NPC.")
	for npc_id: int in pair.ids:
		var reaction: Reaction = reactions[npc_id]
		assert_eq(reaction.minute0, reaction.minute1, "NPC %d: o NPC com corpo reage no mesmo minuto que o gêmeo sem corpo." % npc_id)
		assert_eq(reaction.action0, reaction.action1, "NPC %d: e escolhe a MESMA ação nova (a que alivia a fome)." % npc_id)
		assert_eq(reaction.serial0, reaction.serial1, "NPC %d: com o mesmo contador de ações." % npc_id)
	for npc_id: int in changed:
		var reaction: Reaction = reactions[npc_id]
		assert_eq(reaction.action0, EAT, "Fome urgente: `eat`.")
		assert_ne(reaction.serial0, pair.sleep_intents[npc_id].action_serial, "A ação mudou de verdade.")
		assert_eq(reaction.intent_serial0, reaction.serial0, "No minuto da reação o Intent pendente já é o da ação NOVA: o do sono foi cancelado e sumiu da lista.")
	assert_eq(pair.s0.npc.validate().size(), 0, str(pair.s0.npc.validate()))


func test_the_cancelled_sleep_intent_leaves_no_partial_effect_while_the_s1_twin_gets_one() -> void:
	# [LIM] documentada: cancelar o sono pela reavaliação não aplica o efeito proporcional do modo S1.
	var pair: Pair = _pair_asleep_at(HUNGRY_CHECKPOINT_MIN, HUNGRY)
	var reactions: Dictionary[int, Reaction] = _first_change_minutes(pair, SLEEP, SEARCH_LIMIT_MIN)
	var npc_id: int = _changed_in_s1(reactions)[0]
	var with_body: NpcModule.NpcQuery = pair.s0.npc.peek_npc(npc_id)
	var without_body: NpcModule.NpcQuery = pair.s1.npc.peek_npc(npc_id)
	assert_true(with_body.need_values[REST] >= REST_START_VALUE, "No NPC com corpo o sono cancelado não aliviou o `rest`.")
	assert_lt(without_body.need_values[REST], with_body.need_values[REST], "O gêmeo S1 aplicou o efeito proporcional do sono interrompido: é a diferença conhecida.")


# ---------------------------------------------------------------------------------------------------- (f) resultado tardio do Intent cancelado

func test_a_late_result_of_the_cancelled_intent_is_discarded_and_counted_and_changes_nothing() -> void:
	var pair: Pair = _pair_asleep_at(HUNGRY_CHECKPOINT_MIN, HUNGRY)
	var reactions: Dictionary[int, Reaction] = _first_change_minutes(pair, SLEEP, SEARCH_LIMIT_MIN)
	var npc_id: int = _changed_in_s1(reactions)[0]
	var old_intent: NpcIntent = pair.sleep_intents[npc_id]
	var snapshot: NpcModule.NpcQuery = pair.s0.npc.peek_npc(npc_id)
	var discarded_before: int = _discarded(pair.s0)
	var late: Result = pair.s0.npc.request_report_npc_result(_result_for(old_intent, NpcActionResult.Outcome.DONE))
	assert_eq(late.code, NpcIntentBoard.CODE_STALE_RESULT, "O corpo antigo ainda responde, e o resultado é de uma ação que já não existe.")
	assert_eq(_discarded(pair.s0), discarded_before + 1, "Descartado e contado.")
	var unchanged: NpcModule.NpcQuery = pair.s0.npc.peek_npc(npc_id)
	assert_eq([unchanged.need_values, unchanged.action_id, unchanged.action_serial, unchanged.next_think_time], [snapshot.need_values, snapshot.action_id, snapshot.action_serial, snapshot.next_think_time], "O NPC não mudou: o sono cancelado não entra.")
	var current: NpcIntent = _pending_of(pair.s0, npc_id)
	assert_not_null(current, "E o Intent da ação nova continua pendente.")
	if current != null:
		assert_ne(current.action_serial, old_intent.action_serial)


# ---------------------------------------------------------------------------------------------------- (d) alarme

func test_an_alarm_cancels_the_sleep_intent_and_the_s0_npcs_react_like_their_s1_twins() -> void:
	var pair: Pair = _pair_asleep_at(ALARM_AT_MIN)
	assert_true(pair.s0.npc.request_raise_alarm(FOCUS_A_CM.x, FOCUS_A_CM.y, ALARM_SEVERITY).ok)
	assert_true(pair.s1.npc.request_raise_alarm(FOCUS_A_CM.x, FOCUS_A_CM.y, ALARM_SEVERITY).ok)
	var reacted_in_s1: Array[int] = []
	for _minute: int in 3:
		_step_both(pair)
		assert_eq(_differing(pair), [] as Array[int], "A cada minuto, o NPC com corpo está na mesma ação (id e contador) que o gêmeo sem corpo.")
	for npc_id: int in pair.ids:
		if pair.s1.npc.peek_npc(npc_id).action_id != SLEEP:
			reacted_in_s1.append(npc_id)
	assert_gt(reacted_in_s1.size(), 0, "Sanidade: o alarme forte no meio da vila acorda alguém no gêmeo S1.")
	for npc_id: int in reacted_in_s1:
		var current: NpcIntent = _pending_of(pair.s0, npc_id)
		assert_not_null(current, "A reação nasce com Intent (o NPC segue em S0).")
		if current != null:
			assert_ne(current.action_serial, pair.sleep_intents[npc_id].action_serial, "E o Intent do sono sumiu.")
	for npc_id: int in pair.ids:
		if not reacted_in_s1.has(npc_id):
			var kept: NpcIntent = _pending_of(pair.s0, npc_id)
			assert_not_null(kept, "Quem ignorou o alarme (inércia) segue dormindo, esperando o corpo.")
			if kept != null:
				assert_eq(kept.action_serial, pair.sleep_intents[npc_id].action_serial, "Com o MESMO Intent: nada foi cancelado.")
	assert_eq(pair.s0.npc.validate().size(), 0, str(pair.s0.npc.validate()))


# ---------------------------------------------------------------------------------------------------- (e) fim do bloco da rotina

func test_the_end_of_the_routine_block_swaps_the_long_action_in_the_same_minute_as_the_s1_twin() -> void:
	var pair: Pair = _pair_asleep_at(BEFORE_THE_SWAP_MIN)
	var reactions: Dictionary[int, Reaction] = _first_change_minutes(pair, SLEEP, 2 * THINK_INTERVAL_MIN + (ROUTINE_SWAP_MIN - BEFORE_THE_SWAP_MIN))
	for npc_id: int in pair.ids:
		var reaction: Reaction = reactions[npc_id]
		assert_gte(reaction.minute1, ROUTINE_SWAP_MIN, "NPC %d: o gêmeo S1 só troca o sono depois das 6h." % npc_id)
		assert_lt(reaction.minute1, ROUTINE_SWAP_MIN + THINK_INTERVAL_MIN + 1, "NPC %d: e troca no primeiro pensamento depois das 6h." % npc_id)
		assert_eq(reaction.minute0, reaction.minute1, "NPC %d: o NPC com corpo troca no mesmo minuto." % npc_id)
		assert_eq([reaction.action0, reaction.serial0], [reaction.action1, reaction.serial1], "NPC %d: para a mesma ação, com o mesmo contador." % npc_id)
		assert_eq(reaction.action0, EAT, "A rotina das 6h manda comer.")
		assert_eq(reaction.intent_serial0, reaction.serial0, "NPC %d: a ação nova nasce com Intent e o do sono sumiu." % npc_id)
		assert_ne(reaction.intent_serial0, pair.sleep_intents[npc_id].action_serial)
	for npc_id: int in pair.ids:
		var current: NpcIntent = _pending_of(pair.s0, npc_id)
		assert_not_null(current)
		if current != null:
			assert_eq(current.kind, NpcIntent.Kind.ACT_AT_PLACE)
	assert_eq(_differing(pair), [] as Array[int], "Mesma ação e mesmo contador nos dois mundos.")


# ---------------------------------------------------------------------------------------------------- (g) morte com Intent pendente

func test_a_death_with_a_pending_intent_releases_it_without_error_and_the_body_goes_back() -> void:
	var rig: Rig = _rig(true, STARVING)
	rig.runner.run_steps(60)
	var ids: Array[int] = rig.npc.lod.s0_ids()
	assert_eq(ids.size(), MAX_S0)
	var intents: Dictionary[int, NpcIntent] = {}
	for intent: NpcIntent in rig.npc.peek_pending_intents():
		intents[intent.npc_id] = intent
	assert_eq(intents.size(), MAX_S0, "Sanidade: todos com corpo têm o Intent do sono pendente.")
	var dead_id: int = IdGenerator.NO_ID
	while dead_id == IdGenerator.NO_ID and rig.now() < SEARCH_LIMIT_MIN:
		rig.runner.step_once()
		for npc_id: int in ids:
			if not rig.npc.peek_npc(npc_id).is_alive:
				dead_id = npc_id
				break
	assert_ne(dead_id, IdGenerator.NO_ID, "Sem comida e com a fome letal em 2 h, alguém com corpo morre durante o sono.")
	assert_false(rig.npc.intents.has_pending(dead_id), "No minuto da morte o Intent já não vale.")
	assert_null(_pending_of(rig, dead_id), "E não está mais na lista de Intents pendentes.")
	var dead: NpcModule.NpcQuery = rig.npc.peek_npc(dead_id)
	assert_eq([dead.is_alive, dead.action_id], [false, ""], "NPC morto, sem ação.")
	var changes_before: int = rig.changes.size()
	var discarded_before: int = _discarded(rig)
	var late: Result = rig.npc.request_report_npc_result(_result_for(intents[dead_id], NpcActionResult.Outcome.DONE))
	assert_eq(late.code, NpcIntentBoard.CODE_STALE_RESULT, "O resultado do corpo do morto é descartado, sem erro.")
	assert_eq(_discarded(rig), discarded_before + 1, "E contado.")
	rig.runner.step_once()
	var returned: bool = false
	for index: int in range(changes_before, rig.changes.size()):
		if rig.changes[index].npc_id == dead_id and rig.changes[index].to_level == NpcLod.LEVEL_S1:
			returned = true
	assert_true(returned, "No passo seguinte o corpo volta (LodChanged de S0 para S1).")
	assert_false(rig.npc.lod.s0_ids().has(dead_id), "E o morto não ocupa mais vaga de S0.")
	assert_eq(rig.npc.validate().size(), 0, str(rig.npc.validate()))
	assert_eq(rig.runner.world.validate().size(), 0, str(rig.runner.world.validate()))


# ---------------------------------------------------------------------------------------------------- (h) determinismo

func test_the_same_busy_morning_gives_the_same_world_and_the_module_validates() -> void:
	var hashes: Array[String] = []
	var answered_per_run: Array[int] = []
	for _run: int in 2:
		var rig: Rig = _rig(true, HUNGRY)
		var answered: int = 0
		for minute: int in ROUTINE_SWAP_MIN + 90:
			if minute == ALARM_AT_MIN:
				assert_true(rig.npc.request_raise_alarm(FOCUS_A_CM.x, FOCUS_A_CM.y, ALARM_SEVERITY).ok)
			rig.runner.step_once()
			answered += _answer_due(rig)
		answered_per_run.append(answered)
		hashes.append(rig.runner.world.state_hash())
		assert_gt(rig.changes.size(), 0, "Houve corpos.")
		assert_eq(rig.npc.validate().size(), 0, str(rig.npc.validate()))
		assert_eq(rig.runner.world.validate().size(), 0, str(rig.runner.world.validate()))
		assert_eq(rig.npc.peek_counts()["alive"], 100, "Todos vivos.")
	assert_gt(answered_per_run[0], 0, "O corpo perfeito cumpriu Intents ao longo da manhã (as reavaliações não travaram o fluxo).")
	assert_eq(answered_per_run[0], answered_per_run[1])
	assert_eq(hashes[0], hashes[1], "Mesma sequência, mesmo hash.")
