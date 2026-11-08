extends GutTest
## LW-070c: conversar e ajudar (LW-080) valem IGUAL para o NPC com corpo (S0) e para o sem corpo (S1). O mundo não pode mudar porque o jogador olha:
## sem esta tarefa, `talk` e `help` de quem tem corpo terminavam pelo resultado do corpo, caminho em que o gancho social do pensador não era chamado,
## e duas pessoas fazendo a mesma coisa ganhavam (ou não) relação e memória conforme estivessem perto do jogador. Sem janela, com os DADOS REAIS de
## res://data e o jogo montado pelo mesmo caminho do real (NpcSetup, GameModules, SimulationRunner). Para a conversa não depender de quem mais chega
## ao local de convívio (os notáveis formam pares por ordem de ID entre quem conversa ali), o cenário tem só os dois notáveis da conversa, criados
## como artesãos (a rotina real manda conversar das 11h às 12h) e promovidos por `request_promote`; um teste no fim roda o jogo real completo, com os
## 100 NPCs. O "corpo" é o próprio teste: o CORPO PERFEITO devolve ARRIVED ou DONE no fim previsto de cada Intent. GÊMEOS: o mesmo mundo (mesma
## semente) sem corpos e com corpos ligados às 10h30, meia hora antes da conversa. Compara-se a consequência (relação, memórias e eventos), não o
## instante: o S1 fecha a ação no pensamento seguinte e o S0, no minuto do resultado, e o NPC com corpo recomeça a ação um minuto depois do S1.

const DATA_DIR: String = "res://data"
const WORLD_SEEDS: Array[int] = [11, 12, 13]
const ACTOR_ID: int = 77
const SETTLEMENT: String = "test_settlement_a"
const OCCUPATION: String = "artisan"
const SOCIAL_PLACE: String = "a_social_01"
## O primeiro notável mora e trabalha mais perto do convívio; o segundo, mais longe. O primeiro nasce com o menor ID.
const HOME_FIRST: String = "a_home_02"
const WORK_FIRST: String = "a_work_03"
const HOME_SECOND: String = "a_home_01"
const WORK_SECOND: String = "a_work_01"
const TALK: String = "talk"
const WORK: String = "work"
const HELP: String = "help"
const CONVERSATION_KIND: String = "conversation"
const HELP_KIND: String = "help_received"
const MINUTE: int = 1
const HOUR: int = 60 * MINUTE
const DAY: int = SimClock.MINUTES_PER_DAY
## Conversa: às 10h30 os corpos ligam (a rotina manda conversar às 11h) e a janela vai até 12h10, com a rotina já em `eat`.
const BODIES_FOR_TALK_MIN: int = 10 * HOUR + 30 * MINUTE
const TALK_WINDOW_END_MIN: int = 12 * HOUR + 10 * MINUTE
## Trabalho: os corpos ligam às 6h30 (antes do `work`, que vai das 7h05 às 11h05) e a janela acaba às 11h30, com o `work` já terminado e antes de a
## primeira conversa terminar (ela começa depois das 11h05 e dura 30 min).
const BODIES_FOR_WORK_MIN: int = 6 * HOUR + 30 * MINUTE
const WORK_WINDOW_END_MIN: int = 11 * HOUR + 30 * MINUTE
## Ajuda: de madrugada, com todos dormindo em casa. O alarme soa na casa do primeiro (a vítima, notável); quem foge vai para casa, então a vítima
## nunca sai de lá. O ajudante é leal e sociável, volta da fuga e vai ajudar na casa dela.
const ALARM_AT_MIN: int = 2 * HOUR
const ALARM_SEVERITY: int = 2
const HELP_WINDOW_END_MIN: int = 4 * HOUR
const CALM_TRAITS: Array[int] = [10, 10, 50, 10]
const HERO_TRAITS: Array[int] = [5, 90, 50, 95]
## Depois do último evento do cenário de conversa, para os tempos limite vencerem e nada mais sair.
const QUIET_END_MIN: int = 12 * HOUR + 20 * MINUTE
const SAFETY_LIMIT_MIN: int = 3 * HOUR
const NO_LIMIT: int = 0
const NO_BODIES_EVER: int = -1
const CM_PER_M: float = 100.0
## Jogo real completo: os 30 primeiros NPCs (lavradores e lenhadores do assentamento A, que conversam das 19h às 21h) viram notáveis; a janela vai até 22h.
const REAL_GAME_NOTABLES: int = 30
const REAL_GAME_END_MIN: int = 22 * HOUR
const COUNT_ALIVE_TOTAL: int = 100

## O que o corpo faz com cada Intent que chega ao fim previsto: sempre chega ao destino de quem anda; quem age no local depende da política.
enum Body { PERFECT, BLOCKS, CANCELS, SILENT }
## Corpos: ninguém, os dois NPCs, ou só o primeiro (o limite de S0 vira 1, e o primeiro tem o menor ID e fica com a vaga).
enum Mode { NO_BODIES, BOTH, MIXED }

var _data: NpcLifeCheck.GameData
var _places: SettlementService
var _rigs: Array[Rig] = []


## Um jogo de teste: o runner, o módulo `npc` e o que o teste anotou do mundo.
class Rig:
	extends RefCounted

	var runner: SimulationRunner
	var npc: NpcModule
	var talk_gain: int = 0
	var think_interval_min: int = 0
	var bodies_on: bool = false
	## Os dois NPCs do cenário e o nível de LOD de cada um no primeiro minuto em que os dois conversavam.
	var watched: Array[int] = []
	var levels_at_talk: Array[int] = []
	## Ação (id) de cada resultado DONE que o corpo devolveu.
	var completed: Array[String] = []
	## Desfecho de cada resposta que o corpo deu.
	var outcomes: Array[int] = []
	## Cada RelationChanged: [a_id, b_id, valores, minuto da entrega].
	var events: Array = []

	func on_relation_changed(event: SimEvent) -> void:
		var changed: RelationChanged = event as RelationChanged
		events.append([changed.a_id, changed.b_id, Array(changed.values), now()])

	func now() -> int:
		return runner.world.context.clock.total_minutes()


## O que um cenário deixou: relação, memórias de cada um, eventos e os instantes dos registros do primeiro.
class Snapshot:
	extends RefCounted

	## O par se conhece? Sem relação, `relation` traz as cinco dimensões em zero.
	var is_known: bool = false
	var relation: Array = []
	## Uma lista por pessoa; cada registro é [tipo, pessoas, local].
	var memories: Array = []
	var times: Array[int] = []
	## Cada evento é [a_id, b_id, valores].
	var events: Array = []
	var relations_count: int = 0


class Scenario:
	extends RefCounted

	var rig: Rig
	var first_id: int = 0
	var second_id: int = 0
	var snapshot: Snapshot


func before_all() -> void:
	_data = NpcLifeCheck.load_game_data()
	assert_eq(_data.problem, "", "Os dados reais do jogo carregam.")
	_places = SettlementService.new(_data.settlements, _data.places)


func after_each() -> void:
	for rig: Rig in _rigs:
		rig.runner.finish()
	_rigs.clear()


# ---------------------------------------------------------------------------------------------------- montagem

func _place_m(place_id: String) -> Vector3:
	var found: SettlementService.PlaceQuery = _places.peek_place(place_id)
	assert_true(found.result.ok, found.result.message)
	return found.place.position


func _place_cm(place_id: String) -> Vector2i:
	var position_m: Vector3 = _place_m(place_id)
	return Vector2i(roundi(position_m.x * CM_PER_M), roundi(position_m.z * CM_PER_M))


func _setup() -> NpcSetup:
	var setup: NpcSetup = NpcSetup.from_dir(DATA_DIR, SettlementService.new(_data.settlements, _data.places), true)
	assert_true(setup.result.ok, setup.result.message)
	return setup


func _make_rig(setup: NpcSetup, world_seed: int) -> Rig:
	var rig: Rig = Rig.new()
	rig.talk_gain = setup.definitions.params.talk_gain
	rig.think_interval_min = setup.definitions.params.think_interval_min
	rig.runner = SimulationRunner.new(world_seed)
	var modules: GameModules = GameModules.register(rig.runner, _data.terrain, _data.points, setup)
	assert_true(modules.result.ok, modules.result.message)
	rig.npc = modules.npc
	rig.runner.world.context.events.subscribe("RelationChanged", rig.on_relation_changed)
	rig.runner.start_new_game()
	_rigs.append(rig)
	return rig


## Jogo novo igual ao real (dados de res://data, build de desenvolvimento por causa do alarme), mas SEM a população inicial, com o foco do ator no
## local de convívio. `max_s0` maior que zero troca só o limite de NPCs com corpo (os raios continuam os dos dados).
func _rig(world_seed: int, max_s0: int = NO_LIMIT) -> Rig:
	var setup: NpcSetup = _setup()
	setup.definitions.population = null
	if max_s0 > NO_LIMIT:
		var radii: LodParams = setup.definitions.lod_params
		setup.definitions.lod_params = LodParams.new(radii.lod_enter_radius_m, radii.lod_exit_radius_m, max_s0)
	var rig: Rig = _make_rig(setup, world_seed)
	var focused: Result = rig.npc.request_set_focus(ACTOR_ID, _place_m(SOCIAL_PLACE))
	assert_true(focused.ok, focused.message)
	return rig


func _spawn(rig: Rig, is_notable: bool, home_id: String, work_id: String, traits: Array[int] = []) -> int:
	var spec: NpcSpec = NpcSpec.new()
	spec.name_key = "npc.name.villager"
	spec.occupation_id = OCCUPATION
	spec.settlement_id = SETTLEMENT
	spec.home_place_id = home_id
	spec.work_place_id = work_id
	spec.place_id = home_id
	var home_cm: Vector2i = _place_cm(home_id)
	spec.x_cm = home_cm.x
	spec.z_cm = home_cm.y
	if not traits.is_empty():
		spec.traits = PackedInt64Array(traits)
	var created: NpcModule.CreateResult = rig.npc.request_create_npc(spec)
	assert_true(created.result.ok, created.result.message)
	if is_notable:
		var promoted: Result = rig.npc.request_promote(created.npc_id, NpcState.TIER_NOTABLE)
		assert_true(promoted.ok, promoted.message)
	return created.npc_id


# ---------------------------------------------------------------------------------------------------- o corpo

func _body_of(intent: NpcIntent) -> Vector3:
	return Vector3(intent.destination_cm.x / CM_PER_M, 0.0, intent.destination_cm.y / CM_PER_M)


func _outcome_for(kind: NpcIntent.Kind, body: Body) -> NpcActionResult.Outcome:
	if kind == NpcIntent.Kind.MOVE_TO_PLACE:
		return NpcActionResult.Outcome.ARRIVED
	if body == Body.BLOCKS:
		return NpcActionResult.Outcome.BLOCKED
	if body == Body.CANCELS:
		return NpcActionResult.Outcome.CANCELLED
	return NpcActionResult.Outcome.DONE


func _pending_of(rig: Rig, npc_id: int) -> NpcIntent:
	for intent: NpcIntent in rig.npc.peek_pending_intents():
		if intent.npc_id == npc_id:
			return intent
	return null


## Responde cada Intent que chegou ao fim previsto, depois do passo. Falha por regra ao terminar (NPC_ACTION_FAILED) é um desfecho legítimo do jogo.
func _answer_due(rig: Rig, body: Body) -> void:
	for intent: NpcIntent in rig.npc.peek_pending_intents():
		var npc: NpcModule.NpcQuery = rig.npc.peek_npc(intent.npc_id)
		if rig.now() < npc.action_ends_at:
			continue
		if intent.kind == NpcIntent.Kind.ACT_AT_PLACE and body == Body.SILENT:
			continue
		var outcome: NpcActionResult.Outcome = _outcome_for(intent.kind, body)
		var reported: Result = rig.npc.request_report_npc_result(NpcActionResult.new(intent.npc_id, intent.action_serial, outcome, _body_of(intent)))
		assert_true(reported.ok or reported.code == ActionRunner.CODE_ACTION_FAILED, reported.message)
		rig.outcomes.append(outcome)
		if outcome == NpcActionResult.Outcome.DONE:
			rig.completed.append(npc.action_id)


func _bodies_on(rig: Rig) -> void:
	var switched: Result = rig.npc.request_set_bodies_available(true)
	assert_true(switched.ok, switched.message)
	rig.bodies_on = true


## Anda até o minuto `end_min` (o relógio começa em 0). Em `bodies_from_min` (NO_BODIES_EVER = nunca) os corpos ligam e, dali em diante, a
## política do corpo responde depois de cada passo.
func _walk(rig: Rig, end_min: int, bodies_from_min: int, body: Body) -> void:
	while rig.now() < end_min:
		if not rig.bodies_on and bodies_from_min != NO_BODIES_EVER and rig.now() >= bodies_from_min:
			_bodies_on(rig)
		rig.runner.step_once()
		if rig.bodies_on:
			_answer_due(rig, body)
		if rig.watched.size() == 2 and rig.levels_at_talk.is_empty():
			_note_levels_when_both_talk(rig)


func _note_levels_when_both_talk(rig: Rig) -> void:
	for npc_id: int in rig.watched:
		if rig.npc.peek_npc(npc_id).action_id != TALK:
			return
	for npc_id: int in rig.watched:
		rig.levels_at_talk.append(rig.npc.lod.level_of(npc_id))


# ---------------------------------------------------------------------------------------------------- cenários

func _snapshot(rig: Rig, first_id: int, second_id: int, kind_id: String = "") -> Snapshot:
	var taken: Snapshot = Snapshot.new()
	var opinion: NpcModule.OpinionQuery = rig.npc.peek_opinion(first_id, second_id)
	taken.is_known = opinion.is_known
	taken.relation = Array(opinion.values)
	for npc_id: int in [first_id, second_id]:
		var person: Array = []
		for record: MemoryRecord in rig.npc.peek_memories(npc_id, kind_id).records:
			person.append([record.kind, Array(record.actors), record.place_id])
			if npc_id == first_id:
				taken.times.append(record.time)
		taken.memories.append(person)
	for event: Array in rig.events:
		taken.events.append(event.slice(0, 3))
	taken.relations_count = rig.npc.debug_summary()["relations"]
	return taken


## Cidadão sem ofício, em casa: não conversa nem faz nada; só ocupa um ID (a fase do pensamento de cada NPC vem do ID).
func _spawn_filler(rig: Rig) -> void:
	var spec: NpcSpec = NpcSpec.new()
	spec.name_key = "npc.name.villager"
	spec.settlement_id = SETTLEMENT
	spec.home_place_id = HOME_SECOND
	spec.place_id = HOME_SECOND
	var home_cm: Vector2i = _place_cm(HOME_SECOND)
	spec.x_cm = home_cm.x
	spec.z_cm = home_cm.y
	var created: NpcModule.CreateResult = rig.npc.request_create_npc(spec)
	assert_true(created.result.ok, created.result.message)


## Os dois notáveis conversam na janela da rotina. `mode`: sem corpos (S1), os dois com corpo ou só o primeiro; `body`: o que o corpo faz.
## `fillers_between`: cidadãos criados entre os dois notáveis; com `think_interval_min - 1` deles os dois têm a MESMA fase de pensamento (IDs 1 e 11)
## e terminam cada conversa no mesmo minuto.
func _talk_world(world_seed: int, mode: Mode, body: Body, end_min: int = TALK_WINDOW_END_MIN, fillers_between: int = 0) -> Scenario:
	var scenario: Scenario = Scenario.new()
	scenario.rig = _rig(world_seed, 1 if mode == Mode.MIXED else NO_LIMIT)
	scenario.first_id = _spawn(scenario.rig, true, HOME_FIRST, WORK_FIRST)
	for _index: int in fillers_between:
		_spawn_filler(scenario.rig)
	scenario.second_id = _spawn(scenario.rig, true, HOME_SECOND, WORK_SECOND)
	scenario.rig.watched.assign([scenario.first_id, scenario.second_id])
	_walk(scenario.rig, end_min, NO_BODIES_EVER if mode == Mode.NO_BODIES else BODIES_FOR_TALK_MIN, body)
	scenario.snapshot = _snapshot(scenario.rig, scenario.first_id, scenario.second_id, CONVERSATION_KIND)
	return scenario


## O alarme soa de madrugada na casa da vítima (notável, calma); o ajudante (cidadão, leal e sociável) acaba ajudando lá.
func _help_world(world_seed: int, with_bodies: bool) -> Scenario:
	var scenario: Scenario = Scenario.new()
	scenario.rig = _rig(world_seed)
	scenario.first_id = _spawn(scenario.rig, true, HOME_FIRST, WORK_FIRST, CALM_TRAITS)
	scenario.second_id = _spawn(scenario.rig, false, HOME_SECOND, WORK_SECOND, HERO_TRAITS)
	var bodies_from: int = 0 if with_bodies else NO_BODIES_EVER
	_walk(scenario.rig, ALARM_AT_MIN, bodies_from, Body.PERFECT)
	var alarm_cm: Vector2i = _place_cm(HOME_FIRST)
	var raised: Result = scenario.rig.npc.request_raise_alarm(alarm_cm.x, alarm_cm.y, ALARM_SEVERITY)
	assert_true(raised.ok, raised.message)
	_walk(scenario.rig, HELP_WINDOW_END_MIN, bodies_from, Body.PERFECT)
	scenario.snapshot = _snapshot(scenario.rig, scenario.first_id, scenario.second_id, HELP_KIND)
	return scenario


## Maior diferença, em minutos, entre os instantes dos registros de dois cenários (mesma quantidade de registros).
func _largest_gap(first: Array[int], second: Array[int]) -> int:
	assert_eq(first.size(), second.size(), "Mesma quantidade de registros nos dois mundos.")
	var largest: int = 0
	for index: int in mini(first.size(), second.size()):
		largest = maxi(largest, absi(first[index] - second[index]))
	return largest


## O que a conversa tem de deixar depois de `conversations` consequências: cada notável lembra do outro, a relação é o ganho vezes o número delas.
func _assert_talk_consequences(shot: Snapshot, scenario: Scenario, conversations: int) -> void:
	var gain: int = scenario.rig.talk_gain * conversations
	assert_eq(shot.relation, [gain, gain, 0, 0, 0], "A relação é o ganho vezes as conversas.")
	var first_memory: Array = [CONVERSATION_KIND, [scenario.second_id], SOCIAL_PLACE]
	var second_memory: Array = [CONVERSATION_KIND, [scenario.first_id], SOCIAL_PLACE]
	assert_eq(shot.memories[0].size(), conversations, "Cada conversa deixa um registro em cada notável.")
	assert_eq(shot.memories[1].size(), conversations)
	assert_eq(shot.memories[0][0], first_memory)
	assert_eq(shot.memories[1][0], second_memory)


# ---------------------------------------------------------------------------------------------------- (a) gêmeos: conversar

func test_a_conversation_leaves_the_same_relation_memories_and_event_with_or_without_bodies() -> void:
	var worst_gap_min: int = 0
	var think_interval_min: int = 0
	for world_seed: int in WORLD_SEEDS:
		var twin: Scenario = _talk_world(world_seed, Mode.NO_BODIES, Body.PERFECT)
		var embodied: Scenario = _talk_world(world_seed, Mode.BOTH, Body.PERFECT)
		think_interval_min = twin.rig.think_interval_min
		var conversations: int = twin.snapshot.memories[0].size()
		assert_gt(conversations, 1, "Semente %d: o gêmeo sem corpos conversou mais de uma vez (senão o teste não provaria nada)." % world_seed)
		_assert_talk_consequences(twin.snapshot, twin, conversations)
		assert_eq(embodied.snapshot.relation, twin.snapshot.relation, "Semente %d: mesma relação com corpos." % world_seed)
		assert_eq(embodied.snapshot.memories, twin.snapshot.memories, "Semente %d: mesmas memórias (tipo, pessoas, local e quantidade)." % world_seed)
		assert_eq(embodied.snapshot.events, twin.snapshot.events, "Semente %d: mesmos eventos RelationChanged." % world_seed)
		assert_eq(twin.snapshot.events.size(), 1, "Várias conversas no mesmo dia: UM evento só.")
		assert_gt(embodied.rig.completed.count(TALK), 0, "As conversas do mundo com corpos terminaram pelo resultado do corpo.")
		worst_gap_min = maxi(worst_gap_min, _largest_gap(twin.snapshot.times, embodied.snapshot.times))
	assert_lte(worst_gap_min, think_interval_min, "O instante dos registros difere no máximo um intervalo de pensamento (maior diferença vista: %d min)." % worst_gap_min)


# ---------------------------------------------------------------------------------------------------- (b) gêmeos: ajudar

func test_helping_gives_the_notable_at_the_place_the_same_memory_with_or_without_bodies() -> void:
	for world_seed: int in WORLD_SEEDS:
		var twin: Scenario = _help_world(world_seed, false)
		var embodied: Scenario = _help_world(world_seed, true)
		var expected: Array = [[HELP_KIND, [twin.second_id], HOME_FIRST]]
		assert_eq(twin.snapshot.memories[0], expected, "Semente %d: o notável da casa ganhou o registro de ter sido ajudado, com o ajudante como pessoa." % world_seed)
		assert_eq(embodied.snapshot.memories, twin.snapshot.memories, "Semente %d: mesmas memórias com corpos (quantidade, pessoas e local)." % world_seed)
		assert_eq(embodied.snapshot.memories[1].size(), 0, "Quem ajudou não grava nada.")
		assert_eq([embodied.snapshot.relations_count, embodied.snapshot.events.size()], [0, 0], "Ajudar não mexe em relação e não publica evento.")
		assert_gt(embodied.rig.completed.count(HELP), 0, "A ajuda do mundo com corpos terminou pelo resultado do corpo.")
		assert_eq(embodied.rig.npc.validate().size(), 0, str(embodied.rig.npc.validate()))


# ---------------------------------------------------------------------------------------------------- (c) par misto

func test_a_mixed_pair_with_one_body_and_one_without_gets_the_same_as_two_without_bodies() -> void:
	for world_seed: int in WORLD_SEEDS:
		var twin: Scenario = _talk_world(world_seed, Mode.NO_BODIES, Body.PERFECT)
		var mixed: Scenario = _talk_world(world_seed, Mode.MIXED, Body.PERFECT)
		assert_eq(mixed.rig.levels_at_talk, [NpcLod.LEVEL_S0, NpcLod.LEVEL_S1], "Semente %d: quando conversam, o primeiro tem corpo e o segundo não." % world_seed)
		assert_eq(mixed.snapshot.relation, twin.snapshot.relation, "Semente %d: mesma relação no par misto." % world_seed)
		assert_eq(mixed.snapshot.memories, twin.snapshot.memories, "Semente %d: mesmas memórias no par misto." % world_seed)
		assert_eq(mixed.snapshot.events, twin.snapshot.events, "Semente %d: mesmos eventos no par misto." % world_seed)
		assert_gt(mixed.rig.completed.count(TALK), 0, "O participante com corpo terminou a conversa pelo corpo.")


# ---------------------------------------------------------------------------------------------------- [LIM] parceiros que terminam no mesmo minuto

## [LIM] CONHECIDO, registrado em docs/modules/npc.md (seção 6): se os DOIS parceiros têm corpo e terminam a conversa no MESMO minuto, o par com corpo
## ganha uma consequência a menos que o par sem corpo. No S1 o primeiro a terminar recomeça a conversa na mesma passagem de pensamento, então o segundo
## ainda o encontra conversando; no S0 o primeiro só recomeça um minuto depois (o resultado do corpo chega depois do passo), e o segundo resultado do mesmo
## minuto não acha parceiro. O par misto não perde nada. Este teste FIXA o estado atual para a diferença não mudar sem ninguém ver: se alguém a
## corrigir (por exemplo fazendo o pensador fechar a ação do corpo, tarefa de contrato), a comparação abaixo passa a ser de igualdade e este teste muda.
func test_known_limit_embodied_partners_who_finish_in_the_same_minute_get_fewer_consequences() -> void:
	var fillers: int = _setup().definitions.params.think_interval_min - 1
	var twin: Scenario = _talk_world(WORLD_SEEDS[0], Mode.NO_BODIES, Body.PERFECT, TALK_WINDOW_END_MIN, fillers)
	var embodied: Scenario = _talk_world(WORLD_SEEDS[0], Mode.BOTH, Body.PERFECT, TALK_WINDOW_END_MIN, fillers)
	var mixed: Scenario = _talk_world(WORLD_SEEDS[0], Mode.MIXED, Body.PERFECT, TALK_WINDOW_END_MIN, fillers)
	assert_eq(twin.second_id - twin.first_id, fillers + 1, "Os dois notáveis têm a mesma fase de pensamento (IDs a um intervalo de distância).")
	assert_gt(twin.snapshot.memories[0].size(), 2, "O gêmeo sem corpos conversou mais de duas vezes.")
	assert_eq(mixed.snapshot.relation, twin.snapshot.relation, "O par misto não perde nada.")
	assert_eq(mixed.snapshot.memories, twin.snapshot.memories)
	assert_lt(embodied.snapshot.memories[0].size(), twin.snapshot.memories[0].size(), "[LIM] os dois com corpo, no mesmo minuto, ganham menos registros.")
	assert_lt(embodied.snapshot.relation[0], twin.snapshot.relation[0], "[LIM] E uma relação menor.")
	assert_gt(embodied.snapshot.memories[0].size(), 0, "Mas conversam: a consequência existe, só que menos vezes.")


# ---------------------------------------------------------------------------------------------------- (d) o que não é sucesso não deixa nada

func test_blocked_cancelled_and_unanswered_talks_leave_no_relation_memory_or_event() -> void:
	for body: Body in [Body.BLOCKS, Body.CANCELS, Body.SILENT]:
		var scenario: Scenario = _talk_world(WORLD_SEEDS[0], Mode.BOTH, body, QUIET_END_MIN)
		var shot: Snapshot = scenario.snapshot
		assert_eq([shot.is_known, shot.memories, shot.events, shot.relations_count], [false, [[], []], [], 0], "Política do corpo %d: nenhuma relação, nenhuma memória e nenhum evento." % body)
		assert_eq(scenario.rig.npc.peek_memories(scenario.first_id).records.size() + scenario.rig.npc.peek_memories(scenario.second_id).records.size(), 0, "Nenhum registro de nenhum tipo.")
		assert_eq(scenario.rig.completed.count(TALK), 0, "Nenhuma conversa terminou com sucesso.")
		if body == Body.SILENT:
			assert_gt(scenario.rig.npc.intents.debug_summary()["timed_out_intents"], 0, "Sem resposta, o tempo limite do Intent cancelou a ação sem efeito.")
		else:
			assert_gt(scenario.rig.outcomes.count(_outcome_for(NpcIntent.Kind.ACT_AT_PLACE, body)), 0, "O corpo foi consultado e respondeu que não cumpriu.")


# ---------------------------------------------------------------------------------------------------- (e) resultado repetido ou tardio

func test_a_repeated_or_late_result_does_not_repeat_the_consequence() -> void:
	var rig: Rig = _rig(WORLD_SEEDS[0])
	var first_id: int = _spawn(rig, true, HOME_FIRST, WORK_FIRST)
	var second_id: int = _spawn(rig, true, HOME_SECOND, WORK_SECOND)
	_walk(rig, BODIES_FOR_TALK_MIN, NO_BODIES_EVER, Body.SILENT)
	_bodies_on(rig)
	var guard: int = 0
	while guard < SAFETY_LIMIT_MIN:
		rig.runner.step_once()
		_answer_due(rig, Body.SILENT)
		var npc: NpcModule.NpcQuery = rig.npc.peek_npc(first_id)
		if npc.action_id == TALK and rig.now() >= npc.action_ends_at and rig.npc.intents.has_pending(first_id):
			break
		guard += 1
	assert_lt(guard, SAFETY_LIMIT_MIN, "O primeiro notável chegou ao fim previsto da conversa.")
	var first_intent: NpcIntent = _pending_of(rig, first_id)
	var second_intent: NpcIntent = _pending_of(rig, second_id)
	assert_not_null(second_intent, "O segundo também está conversando, com o corpo ainda sem responder.")
	var done: NpcActionResult = NpcActionResult.new(first_id, first_intent.action_serial, NpcActionResult.Outcome.DONE, _body_of(first_intent))
	assert_true(rig.npc.request_report_npc_result(done).ok)
	var once: Snapshot = _snapshot(rig, first_id, second_id, CONVERSATION_KIND)
	assert_eq(once.relation, [rig.talk_gain, rig.talk_gain, 0, 0, 0], "O resultado de sucesso fez a consequência sair.")
	assert_eq([once.memories[0].size(), once.memories[1].size()], [1, 1])
	var discarded_before: int = rig.npc.intents.debug_summary()["discarded_results"]
	assert_eq(rig.npc.request_report_npc_result(done).code, NpcIntentBoard.CODE_STALE_RESULT, "O mesmo resultado de novo é descartado.")
	assert_eq(rig.npc.intents.debug_summary()["discarded_results"], discarded_before + 1, "E contado.")
	assert_eq(_snapshot(rig, first_id, second_id, CONVERSATION_KIND).relation, once.relation, "Nada mudou com o resultado repetido.")
	_walk(rig, QUIET_END_MIN, NO_BODIES_EVER, Body.SILENT)
	assert_gt(rig.npc.intents.debug_summary()["timed_out_intents"], 0, "O Intent do segundo venceu por tempo (o corpo nunca respondeu).")
	var late: NpcActionResult = NpcActionResult.new(second_id, second_intent.action_serial, NpcActionResult.Outcome.DONE, _body_of(second_intent))
	assert_eq(rig.npc.request_report_npc_result(late).code, NpcIntentBoard.CODE_STALE_RESULT, "Resultado tardio, depois do tempo limite: descartado.")
	rig.runner.step_once()
	var final: Snapshot = _snapshot(rig, first_id, second_id, CONVERSATION_KIND)
	assert_eq(final.relation, once.relation, "A consequência saiu UMA vez, mesmo com o resultado repetido e o tardio.")
	assert_eq(final.memories, once.memories)
	assert_eq(final.events.size(), 1, "E um evento só.")


# ---------------------------------------------------------------------------------------------------- (f) ação que não é conversar nem ajudar

func test_an_action_that_is_neither_talk_nor_help_leaves_no_relation_or_memory() -> void:
	var rig: Rig = _rig(WORLD_SEEDS[0])
	var first_id: int = _spawn(rig, true, HOME_FIRST, WORK_FIRST)
	var second_id: int = _spawn(rig, true, HOME_SECOND, WORK_SECOND)
	_walk(rig, WORK_WINDOW_END_MIN, BODIES_FOR_WORK_MIN, Body.PERFECT)
	assert_gt(rig.completed.count(WORK), 0, "O trabalho terminou pelo resultado do corpo.")
	assert_false(rig.completed.has(TALK), "Ninguém conversou nesta janela.")
	var shot: Snapshot = _snapshot(rig, first_id, second_id)
	assert_eq([shot.is_known, shot.memories, shot.events, shot.relations_count], [false, [[], []], [], 0], "Nenhuma relação, nenhuma memória e nenhum evento.")


# ---------------------------------------------------------------------------------------------------- o jogo real completo

func test_in_the_complete_real_game_with_bodies_the_notables_get_acquainted_in_the_evening_talks() -> void:
	var rig: Rig = _make_rig(_setup(), WORLD_SEEDS[0])
	var focused: Result = rig.npc.request_set_focus(ACTOR_ID, _place_m(SOCIAL_PLACE))
	assert_true(focused.ok, focused.message)
	var ids: Array[int] = rig.npc.peek_npc_ids()
	assert_eq(ids.size(), COUNT_ALIVE_TOTAL, "O jogo real nasce com os 100 NPCs.")
	for index: int in REAL_GAME_NOTABLES:
		var promoted: Result = rig.npc.request_promote(ids[index], NpcState.TIER_NOTABLE)
		assert_true(promoted.ok, promoted.message)
	_walk(rig, REAL_GAME_END_MIN, 0, Body.PERFECT)
	var summary: Dictionary = rig.npc.debug_summary()
	assert_gt(rig.completed.count(TALK), 0, "Conversas terminaram pelo resultado do corpo.")
	assert_gt(summary["relations"], 0, "Alguns notáveis passaram a se conhecer.")
	assert_gt(summary["memory_records"], 0, "E guardaram as conversas.")
	var per_pair_and_day: Dictionary = {}
	for event: Array in rig.events:
		var key: String = "%d:%d@%d" % [event[0], event[1], IntMath.floor_div(event[3], DAY)]
		per_pair_and_day[key] = int(per_pair_and_day.get(key, 0)) + 1
	assert_gt(per_pair_and_day.size(), 0, "A mudança das relações foi publicada.")
	assert_eq(per_pair_and_day.values().max(), 1, "Nenhum par publicou mais de uma vez no mesmo dia.")
	assert_eq(rig.npc.peek_counts()[NpcModule.COUNT_ALIVE], COUNT_ALIVE_TOTAL, "Ninguém morreu.")
	assert_eq(rig.runner.world.validate().size(), 0, str(rig.runner.world.validate()))
