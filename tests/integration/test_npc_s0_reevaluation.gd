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
## LW-098h5: o mundo tem 6 comerciantes (2 por povoado; no A, os ids 61 e 62) com agenda própria: de 0h às 6h e de 21h às 24h fazem `rest` (60 min no local de descanso), não `sleep` (480 min em casa). Os 48 não comerciantes com corpo seguem com as
## asserções de sempre e os 2 comerciantes ganham as próprias (o 1º `rest` nasce antes do corpo e não tem Intent; às 6h eles ANDAM até a casa para comer).

const DATA_DIR: String = "res://data"
const WORLD_SEED: int = 11
const ACTOR_ID: int = 77
const FOCUS_A_M: Vector3 = Vector3(320.0, 10.0, 540.0)
const FOCUS_A_CM: Vector2i = Vector2i(32000, 54000)
const MAX_S0: int = 50
const SLEEP: String = "sleep"
const EAT: String = "eat"
const REST_ACTION: String = "rest"
const MERCHANT: String = "merchant"
## Os 2 comerciantes do A (dados da opção A): `_pair_asleep_at` confere que são EXATAMENTE os comerciantes entre os 50 com corpo.
const MERCHANT_IDS: Array[int] = [61, 62]
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
	## Os Intents pendentes da ação de partida no S0 (o sono; no comerciante, o `rest`), por NPC (cópias tiradas antes da reavaliação).
	var start_intents: Dictionary[int, NpcIntent] = {}
	## O contador da ação de partida de cada NPC no S0 (o 1º `rest` do comerciante não tem Intent, mas tem contador).
	var start_serials: Dictionary[int, int] = {}


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
	## O tipo do Intent pendente do NPC com corpo nesse minuto (-1 = nenhum), o local alvo da ação nova e o `rest` de cada mundo nesse minuto.
	var intent_kind0: int = -1
	var target0: String = ""
	var rest0: int = 0
	var rest1: int = 0


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


## Os comerciantes (por id) e os não comerciantes de `ids`, em ordem crescente.
func _among(ids: Array[int], merchants: bool) -> Array[int]:
	var found: Array[int] = []
	for npc_id: int in ids:
		if MERCHANT_IDS.has(npc_id) == merchants:
			found.append(npc_id)
	found.sort()
	return found


## Os NPCs de `ids` cujo ofício é comerciante, em ordem crescente (a conferência de que `MERCHANT_IDS` são mesmo eles).
func _merchants_by_trade(rig: Rig, ids: Array[int]) -> Array[int]:
	var found: Array[int] = []
	for npc_id: int in ids:
		if rig.npc.peek_npc(npc_id).occupation_id == MERCHANT:
			found.append(npc_id)
	found.sort()
	return found


## A ação com que o NPC parte nos cenários: `rest` no comerciante (no local de descanso) e `sleep` nos outros (em casa).
func _start_action(npc_id: int) -> String:
	return REST_ACTION if MERCHANT_IDS.has(npc_id) else SLEEP


## Os dois mundos do cenário, andados em passo travado até `minute` (cada NPC na ação de partida: os 48 não comerciantes dormindo, os 2 comerciantes em `rest`; os de S0 com o Intent dela pendente). `merchants_have_intent`: o 1º `rest` do comerciante já estava
## em curso quando ele ganhou corpo (cerca de t=14) e não tem Intent; os ciclos seguintes (a partir de t=73) têm, e de `ACT_AT_PLACE`.
func _pair_asleep_at(minute: int, scenario: int = PLAIN, merchants_have_intent: bool = true) -> Pair:
	var pair: Pair = Pair.new()
	pair.s0 = _rig(true, scenario)
	pair.s1 = _rig(false, scenario)
	_walk_both(pair, minute)
	pair.ids = pair.s0.npc.lod.s0_ids()
	assert_eq(pair.ids.size(), MAX_S0, "Dos 62 do assentamento A, 50 ganham corpo.")
	assert_eq(_merchants_by_trade(pair.s0, pair.ids), MERCHANT_IDS, "Dos 50 com corpo, EXATAMENTE 2 são comerciantes (os do A, que fazem `rest` no local de descanso em vez de `sleep` em casa) e 48 não são.")
	for intent: NpcIntent in pair.s0.npc.peek_pending_intents():
		pair.start_intents[intent.npc_id] = intent
	assert_eq(pair.start_intents.size(), MAX_S0 if merchants_have_intent else MAX_S0 - MERCHANT_IDS.size(), "Todo NPC com corpo que já pensou tem o Intent da ação de partida pendente (o 1º `rest` do comerciante não tem).")
	for npc_id: int in pair.ids:
		pair.start_serials[npc_id] = pair.s0.npc.peek_npc(npc_id).action_serial
		assert_eq(pair.s0.npc.peek_npc(npc_id).action_id, _start_action(npc_id), "Sanidade: na ação de partida (`sleep`; `rest` no comerciante).")
		assert_eq(pair.s1.npc.peek_npc(npc_id).action_id, _start_action(npc_id), "Sanidade: o gêmeo S1 também.")
	for npc_id: int in MERCHANT_IDS:
		assert_eq(pair.start_intents.has(npc_id), merchants_have_intent, "Comerciante %d: o Intent do `rest` só existe a partir do 2º ciclo." % npc_id)
		if merchants_have_intent and pair.start_intents.has(npc_id):
			assert_eq(pair.start_intents[npc_id].kind, NpcIntent.Kind.ACT_AT_PLACE, "Comerciante %d: o `rest` é uma ação no local de descanso." % npc_id)
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


## Anda os dois mundos em passo travado até todos os NPCs de `pair.ids` terem deixado a ação de partida deles (`sleep`; `rest` no comerciante) nos dois (ou `limit` minutos) e devolve, por NPC, o que aconteceu no primeiro minuto em que a ação deixou de ser
## a de partida em cada mundo. No mundo S0 guarda também o Intent pendente desse minuto (tipo e contador), o local alvo da ação nova e o `rest`.
func _first_change_minutes(pair: Pair, limit: int) -> Dictionary[int, Reaction]:
	var reactions: Dictionary[int, Reaction] = {}
	var from_actions: Dictionary[int, String] = {}
	for npc_id: int in pair.ids:
		reactions[npc_id] = Reaction.new()
		from_actions[npc_id] = _start_action(npc_id)
	var end_minute: int = pair.s0.now() + limit
	var open_count: int = pair.ids.size() * 2
	while pair.s0.now() < end_minute and open_count > 0:
		_step_both(pair)
		for npc_id: int in pair.ids:
			var reaction: Reaction = reactions[npc_id]
			if reaction.minute0 < 0:
				var with_body: NpcModule.NpcQuery = pair.s0.npc.peek_npc(npc_id)
				if with_body.action_id != from_actions[npc_id]:
					reaction.minute0 = pair.s0.now()
					reaction.action0 = with_body.action_id
					reaction.serial0 = with_body.action_serial
					reaction.target0 = with_body.action_target_place_id
					reaction.rest0 = with_body.need_values[REST]
					var current: NpcIntent = _pending_of(pair.s0, npc_id)
					reaction.intent_serial0 = current.action_serial if current != null else 0
					reaction.intent_kind0 = current.kind if current != null else -1
					open_count -= 1
			if reaction.minute1 < 0:
				var without_body: NpcModule.NpcQuery = pair.s1.npc.peek_npc(npc_id)
				if without_body.action_id != from_actions[npc_id]:
					reaction.minute1 = pair.s1.now()
					reaction.action1 = without_body.action_id
					reaction.serial1 = without_body.action_serial
					reaction.rest1 = without_body.need_values[REST]
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
	var pair: Pair = _pair_asleep_at(HUNGRY_CHECKPOINT_MIN, HUNGRY, false)
	var reactions: Dictionary[int, Reaction] = _first_change_minutes(pair, SEARCH_LIMIT_MIN)
	var changed: Array[int] = _changed_in_s1(reactions)
	var changed_commons: Array[int] = _among(changed, false)
	assert_gt(changed_commons.size(), 0, "Sanidade: no gêmeo S1 a fome urgente acordou ao menos um NPC.")
	for npc_id: int in pair.ids:
		var reaction: Reaction = reactions[npc_id]
		assert_eq(reaction.minute0, reaction.minute1, "NPC %d: o NPC com corpo reage no mesmo minuto que o gêmeo sem corpo." % npc_id)
		assert_eq(reaction.action0, reaction.action1, "NPC %d: e escolhe a MESMA ação nova (a que alivia a fome)." % npc_id)
		assert_eq(reaction.serial0, reaction.serial1, "NPC %d: com o mesmo contador de ações." % npc_id)
	for npc_id: int in changed_commons:
		var reaction: Reaction = reactions[npc_id]
		assert_eq(reaction.action0, EAT, "Fome urgente: `eat`.")
		assert_ne(reaction.serial0, pair.start_intents[npc_id].action_serial, "A ação mudou de verdade.")
		assert_eq(reaction.intent_serial0, reaction.serial0, "No minuto da reação o Intent pendente já é o da ação NOVA: o do sono foi cancelado e sumiu da lista.")
	assert_eq(_among(changed, true), MERCHANT_IDS, "Os 2 comerciantes também reagem à fome urgente.")
	for npc_id: int in MERCHANT_IDS:
		var reaction: Reaction = reactions[npc_id]
		assert_eq(reaction.action0, ActionRunner.GO_TO_PLACE_ID, "Comerciante %d: está no local de descanso, então a reação é ANDAR até a casa (e não `eat` ali)." % npc_id)
		assert_eq(reaction.target0, pair.s0.npc.peek_npc(npc_id).home_place_id, "Comerciante %d: o destino é a casa dele." % npc_id)
		assert_false(pair.start_intents.has(npc_id), "Comerciante %d: o `rest` em curso não tinha Intent, então não havia o que cancelar." % npc_id)
		assert_eq([reaction.intent_kind0, reaction.intent_serial0], [NpcIntent.Kind.MOVE_TO_PLACE as int, reaction.serial0], "Comerciante %d: a caminhada nasce com o Intent de mover." % npc_id)
	assert_eq(pair.s0.npc.validate().size(), 0, str(pair.s0.npc.validate()))


func test_the_cancelled_sleep_intent_leaves_no_partial_effect_while_the_s1_twin_gets_one() -> void:
	# [LIM] documentada: cancelar o sono pela reavaliação não aplica o efeito proporcional do modo S1.
	var pair: Pair = _pair_asleep_at(HUNGRY_CHECKPOINT_MIN, HUNGRY, false)
	var reactions: Dictionary[int, Reaction] = _first_change_minutes(pair, SEARCH_LIMIT_MIN)
	var npc_id: int = _among(_changed_in_s1(reactions), false)[0]
	var with_body: NpcModule.NpcQuery = pair.s0.npc.peek_npc(npc_id)
	var without_body: NpcModule.NpcQuery = pair.s1.npc.peek_npc(npc_id)
	assert_true(with_body.need_values[REST] >= REST_START_VALUE, "No NPC com corpo o sono cancelado não aliviou o `rest`.")
	assert_lt(without_body.need_values[REST], with_body.need_values[REST], "O gêmeo S1 aplicou o efeito proporcional do sono interrompido: é a diferença conhecida.")
	for merchant_id: int in MERCHANT_IDS:
		assert_eq(reactions[merchant_id].rest0, reactions[merchant_id].rest1, "Comerciante %d: sem Intent para cancelar, o `rest` interrompido aplicou o efeito proporcional nos DOIS mundos (a [LIM] é só do Intent cancelado)." % merchant_id)


# ---------------------------------------------------------------------------------------------------- (f) resultado tardio do Intent cancelado

func test_a_late_result_of_the_cancelled_intent_is_discarded_and_counted_and_changes_nothing() -> void:
	var pair: Pair = _pair_asleep_at(HUNGRY_CHECKPOINT_MIN, HUNGRY, false)
	var reactions: Dictionary[int, Reaction] = _first_change_minutes(pair, SEARCH_LIMIT_MIN)
	var npc_id: int = _among(_changed_in_s1(reactions), false)[0]
	var old_intent: NpcIntent = pair.start_intents[npc_id]
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
	for merchant_id: int in MERCHANT_IDS:
		var merchant_before: NpcModule.NpcQuery = pair.s0.npc.peek_npc(merchant_id)
		var merchant_discarded_before: int = _discarded(pair.s0)
		var stale: Result = pair.s0.npc.request_report_npc_result(NpcActionResult.new(merchant_id, pair.start_serials[merchant_id], NpcActionResult.Outcome.DONE, Vector3.ZERO))
		assert_eq(stale.code, NpcIntentBoard.CODE_STALE_RESULT, "Comerciante %d: o contador do `rest` antigo (que nasceu antes do corpo e não teve Intent) também é descartado." % merchant_id)
		assert_eq(_discarded(pair.s0), merchant_discarded_before + 1, "Descartado e contado.")
		var merchant_after: NpcModule.NpcQuery = pair.s0.npc.peek_npc(merchant_id)
		assert_eq([merchant_after.need_values, merchant_after.action_id, merchant_after.action_serial, merchant_after.next_think_time], [merchant_before.need_values, merchant_before.action_id, merchant_before.action_serial, merchant_before.next_think_time], "O comerciante não mudou.")
		assert_not_null(_pending_of(pair.s0, merchant_id), "E o Intent da caminhada dele continua pendente.")


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
			assert_ne(current.action_serial, pair.start_intents[npc_id].action_serial, "E o Intent do sono sumiu.")
	for npc_id: int in pair.ids:
		if not reacted_in_s1.has(npc_id):
			var kept: NpcIntent = _pending_of(pair.s0, npc_id)
			assert_not_null(kept, "Quem ignorou o alarme (inércia) segue dormindo, esperando o corpo.")
			if kept != null:
				assert_eq(kept.action_serial, pair.start_intents[npc_id].action_serial, "Com o MESMO Intent: nada foi cancelado.")
	assert_eq(pair.s0.npc.validate().size(), 0, str(pair.s0.npc.validate()))


# ---------------------------------------------------------------------------------------------------- (e) fim do bloco da rotina

## O primeiro pensamento no minuto `from_minute` ou depois, de quem tem o pensamento agendado em `next_think` e pensa a cada `THINK_INTERVAL_MIN` minutos.
func _first_think_from(next_think: int, from_minute: int) -> int:
	return next_think + THINK_INTERVAL_MIN * IntMath.floor_div(maxi(0, from_minute - next_think) + THINK_INTERVAL_MIN - 1, THINK_INTERVAL_MIN)


## Os 48 não comerciantes trocam no mesmo minuto do gêmeo S1. Os comerciantes NÃO: ganham corpo com o `rest` em curso e, com o corpo mudo do teste, o Intent do `rest` expira por tempo limite e o ciclo seguinte recomeça depois do que no gêmeo; a fase do pensamento
## deles em S0 difere da do gêmeo (aqui 1 minuto), então cada mundo troca no primeiro pensamento da PRÓPRIA fase depois das 6h (asserção exata, a partir do `next_think_time` de cada mundo antes das 6h).
func test_the_end_of_the_routine_block_swaps_the_long_action_in_the_same_minute_as_the_s1_twin() -> void:
	var pair: Pair = _pair_asleep_at(BEFORE_THE_SWAP_MIN)
	var thinks0: Dictionary[int, int] = {}
	var thinks1: Dictionary[int, int] = {}
	for merchant_id: int in MERCHANT_IDS:
		thinks0[merchant_id] = pair.s0.npc.peek_npc(merchant_id).next_think_time
		thinks1[merchant_id] = pair.s1.npc.peek_npc(merchant_id).next_think_time
	var reactions: Dictionary[int, Reaction] = _first_change_minutes(pair, 2 * THINK_INTERVAL_MIN + (ROUTINE_SWAP_MIN - BEFORE_THE_SWAP_MIN))
	for npc_id: int in pair.ids:
		var reaction: Reaction = reactions[npc_id]
		assert_gte(reaction.minute1, ROUTINE_SWAP_MIN, "NPC %d: o gêmeo S1 só troca o sono depois das 6h." % npc_id)
		assert_lt(reaction.minute1, ROUTINE_SWAP_MIN + THINK_INTERVAL_MIN + 1, "NPC %d: e troca no primeiro pensamento depois das 6h." % npc_id)
		assert_eq([reaction.action0, reaction.serial0], [reaction.action1, reaction.serial1], "NPC %d: para a mesma ação, com o mesmo contador." % npc_id)
		assert_eq(reaction.intent_serial0, reaction.serial0, "NPC %d: a ação nova nasce com Intent e o do sono sumiu." % npc_id)
		assert_ne(reaction.intent_serial0, pair.start_intents[npc_id].action_serial)
		if not MERCHANT_IDS.has(npc_id):
			assert_eq(reaction.minute0, reaction.minute1, "NPC %d: o NPC com corpo troca no mesmo minuto." % npc_id)
			assert_eq(reaction.action0, EAT, "A rotina das 6h manda comer.")
	for npc_id: int in MERCHANT_IDS:
		var reaction: Reaction = reactions[npc_id]
		assert_eq(reaction.minute1, _first_think_from(thinks1[npc_id], ROUTINE_SWAP_MIN), "Comerciante %d: o gêmeo S1 troca no primeiro pensamento da fase dele depois das 6h." % npc_id)
		assert_eq(reaction.minute0, _first_think_from(thinks0[npc_id], ROUTINE_SWAP_MIN), "Comerciante %d: e o NPC com corpo, no primeiro pensamento da fase dele." % npc_id)
		assert_eq(reaction.action0, ActionRunner.GO_TO_PLACE_ID, "Comerciante %d: às 6h ele anda do local de descanso até a casa (para comer lá)." % npc_id)
		assert_eq(reaction.target0, pair.s0.npc.peek_npc(npc_id).home_place_id, "Comerciante %d: o destino é a casa dele." % npc_id)
		assert_eq(reaction.intent_kind0, NpcIntent.Kind.MOVE_TO_PLACE as int, "Comerciante %d: a troca das 6h nasce com o Intent de mover." % npc_id)
	for npc_id: int in pair.ids:
		var current: NpcIntent = _pending_of(pair.s0, npc_id)
		assert_not_null(current)
		if current != null:
			assert_eq(current.kind, NpcIntent.Kind.MOVE_TO_PLACE if MERCHANT_IDS.has(npc_id) else NpcIntent.Kind.ACT_AT_PLACE)
	assert_eq(_differing(pair), [] as Array[int], "Mesma ação e mesmo contador nos dois mundos.")


# ---------------------------------------------------------------------------------------------------- (g) morte com Intent pendente

## No minuto da morte de `npc_id`: o Intent já não vale nem está na lista, o NPC está morto e sem ação, e o resultado tardio do corpo (do `intent`, se havia) é descartado e contado, sem erro.
func _check_the_death_released_the_intent(rig: Rig, npc_id: int, intent: NpcIntent) -> void:
	assert_false(rig.npc.intents.has_pending(npc_id), "NPC %d: no minuto da morte o Intent já não vale." % npc_id)
	assert_null(_pending_of(rig, npc_id), "E não está mais na lista de Intents pendentes.")
	var dead: NpcModule.NpcQuery = rig.npc.peek_npc(npc_id)
	assert_eq([dead.is_alive, dead.action_id], [false, ""], "NPC morto, sem ação.")
	if intent == null:
		return
	var discarded_before: int = _discarded(rig)
	var late: Result = rig.npc.request_report_npc_result(_result_for(intent, NpcActionResult.Outcome.DONE))
	assert_eq(late.code, NpcIntentBoard.CODE_STALE_RESULT, "O resultado do corpo do morto é descartado, sem erro.")
	assert_eq(_discarded(rig), discarded_before + 1, "E contado.")


## Os mortos (id -> quantos LodChanged já existiam no minuto da morte) que ainda não foram conferidos: no passo seguinte o corpo voltou (LodChanged de S0 para S1) e o morto não ocupa mais vaga de S0.
func _check_the_return_of_the_dead(rig: Rig, deaths: Dictionary[int, int], returned: Array[int]) -> void:
	for npc_id: int in deaths:
		if returned.has(npc_id):
			continue
		var back: bool = false
		for index: int in range(deaths[npc_id], rig.changes.size()):
			if rig.changes[index].npc_id == npc_id and rig.changes[index].to_level == NpcLod.LEVEL_S1:
				back = true
		assert_true(back, "NPC %d: no passo seguinte o corpo volta (LodChanged de S0 para S1)." % npc_id)
		assert_false(rig.npc.lod.s0_ids().has(npc_id), "E o morto não ocupa mais vaga de S0.")
		returned.append(npc_id)


func test_a_death_with_a_pending_intent_releases_it_without_error_and_the_body_goes_back() -> void:
	var rig: Rig = _rig(true, STARVING)
	rig.runner.run_steps(60)
	var ids: Array[int] = rig.npc.lod.s0_ids()
	assert_eq(ids.size(), MAX_S0)
	assert_eq(_merchants_by_trade(rig, ids), MERCHANT_IDS, "Dos 50 com corpo, EXATAMENTE 2 são comerciantes (os do A).")
	var intents: Dictionary[int, NpcIntent] = {}
	for intent: NpcIntent in rig.npc.peek_pending_intents():
		intents[intent.npc_id] = intent
	assert_eq(intents.size(), MAX_S0 - MERCHANT_IDS.size(), "Sanidade: os 48 não comerciantes com corpo têm o Intent do sono pendente (o 1º `rest` do comerciante nasceu antes do corpo e não tem).")
	# `dead_id`: o primeiro NÃO comerciante com corpo a morrer. Os comerciantes: cada um, no minuto da própria morte, com o último Intent pendente que teve em vida (o `rest` que começou depois do corpo).
	var dead_id: int = IdGenerator.NO_ID
	var last_intents: Dictionary[int, NpcIntent] = {}
	var deaths: Dictionary[int, int] = {}
	var returned: Array[int] = []
	while rig.now() < SEARCH_LIMIT_MIN and (dead_id == IdGenerator.NO_ID or deaths.size() < 1 + MERCHANT_IDS.size()):
		rig.runner.step_once()
		_check_the_return_of_the_dead(rig, deaths, returned)
		for npc_id: int in ids:
			var is_merchant: bool = MERCHANT_IDS.has(npc_id)
			if rig.npc.peek_npc(npc_id).is_alive:
				if is_merchant:
					last_intents[npc_id] = _pending_of(rig, npc_id)
			elif not deaths.has(npc_id) and (is_merchant or dead_id == IdGenerator.NO_ID):
				dead_id = dead_id if is_merchant else npc_id
				deaths[npc_id] = rig.changes.size()
				_check_the_death_released_the_intent(rig, npc_id, last_intents.get(npc_id) if is_merchant else intents[npc_id])
	rig.runner.step_once()
	_check_the_return_of_the_dead(rig, deaths, returned)
	assert_ne(dead_id, IdGenerator.NO_ID, "Sem comida e com a fome letal em 2 h, alguém com corpo morre durante o sono.")
	assert_eq(returned.size(), deaths.size(), "Todo morto com corpo voltou a S1 no passo seguinte à morte.")
	for merchant_id: int in MERCHANT_IDS:
		assert_true(deaths.has(merchant_id), "Comerciante %d: também morre sem comida." % merchant_id)
		assert_not_null(last_intents.get(merchant_id), "Comerciante %d: o `rest` que começou depois do corpo tem o Intent pendente até a morte." % merchant_id)
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
		assert_eq(rig.npc.peek_counts()["alive"], 138, "Todos vivos.")
	assert_gt(answered_per_run[0], 0, "O corpo perfeito cumpriu Intents ao longo da manhã (as reavaliações não travaram o fluxo).")
	assert_eq(answered_per_run[0], answered_per_run[1])
	assert_eq(hashes[0], hashes[1], "Mesma sequência, mesmo hash.")
