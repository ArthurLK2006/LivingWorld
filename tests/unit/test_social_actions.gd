extends GutTest
## LW-080: ações sociais (docs/modules/npc.md, seção 7), sem janela. Quando uma ação TERMINA, o pensador avisa o módulo; `talk` com outro NPC
## que ainda conversa no mesmo local (o de menor ID) soma `talk_gain` à afeição e à confiança do par, sem passar do teto `talk_limit`, e cada
## NOTÁVEL grava o episódio `conversation`; cidadão com cidadão só alivia a necessidade `social`. `help` grava `help_received` (valência
## positiva) em cada notável que está no local de quem ajudou. A mudança de relação publica `RelationChanged`, AGREGADO: no máximo uma vez por
## par por dia (o dia vai na relação, salvo no save). Primeiro as regras puras, com colaboradores falsos (números exatos); depois o módulo inteiro.

const VILLAGE: String = "village_a"
const HOME: String = "home_a1"
const WORK: String = "work_a1"
const SOCIAL: String = "social_a1"
const OTHER_SOCIAL: String = "social_a2"
const NEED_IDS: Array[String] = ["hunger", "rest", "safety", "income", "social"]
const TRAIT_IDS: Array[String] = ["caution", "sociability", "ambition", "loyalty"]
const SOCIAL_NEED: int = 4
const HOME_X_CM: int = 8400
const WORK_X_CM: int = 18400
const THINK_INTERVAL: int = 10
const NOTABLE: int = NpcState.TIER_NOTABLE
const NORMAL: int = NpcState.TIER_NORMAL
const GAIN: int = 3
const LIMIT: int = 60
const MINUTES_PER_DAY: int = 1440
const HELPER_TRAITS: Array[int] = [5, 90, 50, 95]
const COWARD_TRAITS: Array[int] = [95, 10, 50, 10]
const DATA_DIR: String = "res://data"
const WORLD_DIR: String = "res://data/world"
const PARAMS_LABEL: String = "res://data/npc_params.json"
const PARAMS_ISSUE_CODE: String = "NPC_PARAMS_INVALID"


# ---------------------------------------------------------------------------------------------------- colaboradores falsos

## Os três colaboradores que o módulo entrega ao `SocialActions`, gravando o que recebem.
class Recorder:
	extends RefCounted

	var values: Dictionary = {}
	var adjusts: Array = []
	var memories: Array = []
	var adjust_result: Result = Result.success()
	var memory_result: Result = Result.success()

	func relation_values(a_id: int, b_id: int) -> PackedInt64Array:
		return values.get(NpcRelation.make_key(a_id, b_id), PackedInt64Array())

	func adjust(a_id: int, b_id: int, deltas: PackedInt64Array) -> Result:
		adjusts.append([a_id, b_id, Array(deltas)])
		return adjust_result

	func remember(npc_id: int, kind_id: String, actor_ids: Array[int], place_id: String) -> Result:
		memories.append([npc_id, kind_id, actor_ids.duplicate(), place_id])
		return memory_result


class RealGame:
	extends RefCounted

	var runner: SimulationRunner
	var modules: GameModules


func _state(npc_id: int, tier: int, place_id: String, action_id: String, is_alive: bool = true) -> NpcState:
	var state: NpcState = NpcState.new(npc_id)
	state.tier = tier
	state.place_id = place_id
	state.action_id = action_id
	state.is_alive = is_alive
	return state


func _social(states: Dictionary[int, NpcState], recorder: Recorder, gain: int = GAIN, limit: int = LIMIT) -> SocialActions:
	return SocialActions.new(states, gain, limit, recorder.relation_values, recorder.adjust, recorder.remember)


func _table(list: Array[NpcState]) -> Dictionary[int, NpcState]:
	var table: Dictionary[int, NpcState] = {}
	for state: NpcState in list:
		table[state.npc_id] = state
	return table


# ---------------------------------------------------------------------------------------------------- regras puras: o parceiro

## Quem conversa no MESMO local (o que terminou e os vivos que ainda estão em `talk`) forma pares por ordem de ID: (1º, 2º), (3º, 4º)... Quem conversa em outro
## local, está parado, foi embora ou morreu não entra na lista.
func test_talkers_at_the_same_place_are_paired_by_id_order_and_the_odd_one_out_has_no_partner() -> void:
	var states: Dictionary[int, NpcState] = _table([
		_state(1, NORMAL, SOCIAL, ""), _state(2, NORMAL, OTHER_SOCIAL, "talk"), _state(3, NORMAL, SOCIAL, "wait"), _state(4, NORMAL, SOCIAL, "talk", false),
		_state(5, NORMAL, SOCIAL, "talk"), _state(6, NOTABLE, SOCIAL, "talk"), _state(7, NORMAL, SOCIAL, "talk"),
	])
	var social: SocialActions = _social(states, Recorder.new())
	assert_eq(social.talk_partner(1, SOCIAL), 5, "O 1 acabou de terminar: a lista é 1, 5, 6, 7 (o 2 está em outro local, o 3 espera, o 4 morreu) e o par é (1, 5).")
	assert_eq(social.talk_partner(5, SOCIAL), 6, "Para o 5 a lista é 5, 6, 7 (o 1 já não conversa): o par é (5, 6).")
	assert_eq(social.talk_partner(6, SOCIAL), 5, "O par é o mesmo visto do outro lado.")
	assert_eq(social.talk_partner(7, SOCIAL), IdGenerator.NO_ID, "O 7 é o terceiro da lista 5, 6, 7: sobrou sem par.")
	assert_eq(social.talk_partner(2, OTHER_SOCIAL), IdGenerator.NO_ID, "Sozinho no local: ninguém.")
	assert_eq(social.talk_partner(1, "lugar_que_nao_existe"), IdGenerator.NO_ID)


# ---------------------------------------------------------------------------------------------------- regras puras: conversar

func test_two_citizens_who_talk_only_relieve_the_need_and_nothing_else_happens() -> void:
	var recorder: Recorder = Recorder.new()
	var states: Dictionary[int, NpcState] = _table([_state(1, NORMAL, SOCIAL, ""), _state(2, NORMAL, SOCIAL, "talk")])
	_social(states, recorder).on_action_finished(1, "talk", SOCIAL, 100)
	assert_eq([recorder.adjusts.size(), recorder.memories.size()], [0, 0], "Cidadão com cidadão: nem relação nem memória (Q11).")


func test_a_notable_and_a_citizen_get_a_relation_but_only_the_notable_remembers() -> void:
	var recorder: Recorder = Recorder.new()
	var states: Dictionary[int, NpcState] = _table([_state(1, NORMAL, SOCIAL, ""), _state(2, NOTABLE, SOCIAL, "talk")])
	_social(states, recorder).on_action_finished(1, "talk", SOCIAL, 100)
	assert_eq(recorder.adjusts, [[1, 2, [GAIN, GAIN, 0, 0, 0]]], "Uma mudança no par: afeição e confiança sobem o ganho.")
	assert_eq(recorder.memories, [[2, "conversation", [1], SOCIAL]], "Só o notável grava, com o outro como pessoa e o local da conversa.")
	var reverse: Recorder = Recorder.new()
	var reverse_states: Dictionary[int, NpcState] = _table([_state(1, NOTABLE, SOCIAL, ""), _state(2, NORMAL, SOCIAL, "talk")])
	_social(reverse_states, reverse).on_action_finished(1, "talk", SOCIAL, 100)
	assert_eq(reverse.memories, [[1, "conversation", [2], SOCIAL]], "Quem termina primeiro pode ser o notável: o resultado é o mesmo.")


func test_two_notables_both_remember_each_other_and_the_relation_changes_once() -> void:
	var recorder: Recorder = Recorder.new()
	var states: Dictionary[int, NpcState] = _table([_state(1, NOTABLE, SOCIAL, ""), _state(2, NOTABLE, SOCIAL, "talk")])
	_social(states, recorder).on_action_finished(1, "talk", SOCIAL, 100)
	assert_eq(recorder.adjusts.size(), 1)
	assert_eq(recorder.memories, [[1, "conversation", [2], SOCIAL], [2, "conversation", [1], SOCIAL]])


## Teto 60, ganho 3. Afeição 58 sobe 2 (para no teto); 60 e 75 não sobem; -20 sobe 3 (o teto só segura de cima); par desconhecido sobe 3; afeição e confiança
## têm tetos independentes (afeição 59 sobe 1, confiança 10 sobe 3).
func test_the_gain_never_passes_the_limit_and_each_dimension_is_capped_on_its_own() -> void:
	var states: Dictionary[int, NpcState] = _table([_state(1, NOTABLE, SOCIAL, ""), _state(2, NOTABLE, SOCIAL, "talk")])
	var cases: Array = [
		[PackedInt64Array([58, 58, 0, 0, 0]), [2, 2]], [PackedInt64Array([60, 60, 0, 0, 0]), [0, 0]], [PackedInt64Array([75, 100, 0, 0, 0]), [0, 0]],
		[PackedInt64Array([-20, -100, 0, 0, 0]), [3, 3]], [PackedInt64Array(), [3, 3]], [PackedInt64Array([59, 10, 0, 0, 0]), [1, 3]],
	]
	for case: Array in cases:
		var recorder: Recorder = Recorder.new()
		if not (case[0] as PackedInt64Array).is_empty():
			recorder.values[NpcRelation.make_key(1, 2)] = case[0]
		_social(states, recorder).on_action_finished(1, "talk", SOCIAL, 100)
		assert_eq(recorder.adjusts[0][2], [case[1][0], case[1][1], 0, 0, 0], "Valores atuais %s." % str(case[0]))
	var social: SocialActions = _social(states, Recorder.new())
	assert_eq([social.capped_gain(0), social.capped_gain(57), social.capped_gain(60), social.capped_gain(61), social.capped_gain(-100)], [3, 3, 0, 0, 3])


func test_a_refused_relation_does_not_stop_the_memory_and_a_refused_memory_does_not_stop_the_relation() -> void:
	var states: Dictionary[int, NpcState] = _table([_state(1, NOTABLE, SOCIAL, ""), _state(2, NOTABLE, SOCIAL, "talk")])
	var relation_refused: Recorder = Recorder.new()
	relation_refused.adjust_result = Result.failure(RelationGraph.CODE_NOT_CONFIGURED, "sem relações")
	_social(states, relation_refused).on_action_finished(1, "talk", SOCIAL, 100)
	assert_eq(relation_refused.memories.size(), 2, "Sem relações configuradas as memórias saem do mesmo jeito.")
	var memory_refused: Recorder = Recorder.new()
	memory_refused.memory_result = Result.failure(NpcModule.CODE_MEMORY_NOT_CONFIGURED, "sem memória")
	_social(states, memory_refused).on_action_finished(1, "talk", SOCIAL, 100)
	assert_eq(memory_refused.adjusts.size(), 1, "Sem memória configurada a relação sai do mesmo jeito.")


func test_talking_alone_or_other_actions_or_odd_requests_do_nothing() -> void:
	var recorder: Recorder = Recorder.new()
	var states: Dictionary[int, NpcState] = _table([_state(1, NOTABLE, SOCIAL, ""), _state(2, NOTABLE, SOCIAL, "wait")])
	var social: SocialActions = _social(states, recorder)
	social.on_action_finished(1, "talk", SOCIAL, 100)
	for action_id: String in ["work", "wait", "go_to_place", "eat", "sleep", "flee", ""]:
		social.on_action_finished(1, action_id, SOCIAL, 100)
	social.on_action_finished(99, "talk", SOCIAL, 100)
	social.on_action_finished(1, "talk", "", 100)
	assert_eq([recorder.adjusts.size(), recorder.memories.size()], [0, 0], "Sozinho, outras ações, NPC desconhecido e local vazio: nada.")


# ---------------------------------------------------------------------------------------------------- regras puras: ajudar

func test_helping_gives_a_positive_memory_to_every_notable_at_the_place_but_not_to_anyone_else() -> void:
	var recorder: Recorder = Recorder.new()
	var states: Dictionary[int, NpcState] = _table([
		_state(1, NOTABLE, SOCIAL, ""), _state(2, NOTABLE, SOCIAL, "work"), _state(3, NORMAL, SOCIAL, "work"), _state(4, NOTABLE, OTHER_SOCIAL, "work"),
		_state(5, NOTABLE, SOCIAL, "work", false), _state(6, NOTABLE, SOCIAL, "wait"),
	])
	_social(states, recorder).on_action_finished(1, "help", SOCIAL, 100)
	assert_eq(recorder.memories, [[2, "help_received", [1], SOCIAL], [6, "help_received", [1], SOCIAL]], "Só os notáveis vivos do mesmo local, menos quem ajudou, em ordem de ID.")
	assert_eq(recorder.adjusts.size(), 0, "Ajudar grava memória; a relação não muda (contrato).")
	var alone: Recorder = Recorder.new()
	_social(_table([_state(1, NOTABLE, SOCIAL, "")]), alone).on_action_finished(1, "help", SOCIAL, 100)
	assert_eq(alone.memories.size(), 0, "Ninguém por perto: ninguém foi ajudado.")


# ---------------------------------------------------------------------------------------------------- o módulo inteiro: mundo de teste

func _need_defs() -> Array[NeedDef]:
	var defs: Array[NeedDef] = []
	for position: int in NEED_IDS.size():
		defs.append(NeedDef.new(NEED_IDS[position], position, 50 if position == SOCIAL_NEED else 0, 0, 40, 65, 90))
	return defs


func _catalog() -> Array[ActionDef]:
	var work: ActionDef = ActionDef.new("work", 240, "work", 5, true)
	work.effects.append(ActionDef.ActionEffect.new("rest", 5))
	var talk: ActionDef = ActionDef.new("talk", 30, "social", 0, true)
	talk.effects.append(ActionDef.ActionEffect.new("social", -30))
	var help: ActionDef = ActionDef.new("help", 20, "", 10, true)
	help.effects.append(ActionDef.ActionEffect.new("safety", -20))
	help.trait_weights.append(ActionDef.ActionTraitWeight.new("loyalty", 20))
	help.trait_weights.append(ActionDef.ActionTraitWeight.new("sociability", 10))
	help.trait_weights.append(ActionDef.ActionTraitWeight.new("caution", -10))
	return [work, talk, help, ActionDef.new("wait", 10, "", 0, true), ActionDef.new(ActionRunner.GO_TO_PLACE_ID, 0, "", 0, true)]


func _routine() -> RoutineTable:
	var occupations: Array[RoutineTable.OccupationDef] = [RoutineTable.OccupationDef.new("talker", "talk"), RoutineTable.OccupationDef.new("worker", "work")]
	var blocks: Array[RoutineTable.RoutineBlock] = [RoutineTable.RoutineBlock.new("t", "talker", 0, 24, "talk"), RoutineTable.RoutineBlock.new("w", "worker", 0, 24, "work")]
	return RoutineTable.new(occupations, blocks)


func _places() -> SettlementService:
	var settlements: Array[Settlement] = [Settlement.new(VILLAGE, "settlement.a", Vector3.ZERO)]
	var places: Array[Place] = [
		Place.new(HOME, VILLAGE, Place.KIND_HOME, Vector3(84.0, 0.0, 0.0), 12), Place.new(WORK, VILLAGE, Place.KIND_WORK, Vector3(184.0, 0.0, 0.0), 12),
		Place.new(SOCIAL, VILLAGE, Place.KIND_SOCIAL, Vector3(300.0, 0.0, 0.0), 12),
	]
	return SettlementService.new(settlements, places)


func _params(gain: int, limit: int, decay: int) -> NpcParams:
	var params: NpcParams = NpcParams.new()
	params.urgency_weight_attention = 1
	params.urgency_weight_urgent = 3
	params.urgency_weight_critical = 6
	params.time_cost_per_hour = 2
	params.distance_cost_per_100m = 2
	params.risk_cost_percent = 100
	params.inertia_bonus = 25
	params.routine_bonus = 40
	params.think_interval_min = THINK_INTERVAL
	params.max_thinks_per_step = 20
	params.decision_top_k = 1
	params.alarm_radius_m = 150
	params.alarm_safety_pressure = 40
	params.alarm_window_min = 30
	params.relations_capacity = 8
	params.relation_decay_per_day = decay
	params.relation_friend_threshold = 50
	params.relation_rival_threshold = 40
	params.memory_capacity = 60
	params.trait_threshold = 80
	params.trait_slots = 3
	params.talk_gain = gain
	params.talk_limit = limit
	return params


## Módulo completo. `memory` e `relations` ligados; ganho e teto da conversa por parâmetro.
func _module(gain: int = GAIN, limit: int = LIMIT, decay: int = 0, is_development_build: bool = true) -> NpcModule:
	var definitions: NpcModule.Definitions = NpcModule.Definitions.new()
	definitions.actions = _catalog()
	var traits: Array[TraitLoader.TraitDef] = []
	for position: int in TRAIT_IDS.size():
		traits.append(TraitLoader.TraitDef.new(TRAIT_IDS[position], position))
	definitions.traits = traits
	definitions.params = _params(gain, limit, decay)
	definitions.places = _places()
	definitions.is_development_build = is_development_build
	definitions.memory_kinds = [MemoryKindLoader.KindDef.new("conversation", 20, 30, 2), MemoryKindLoader.KindDef.new("help_received", 60, 70, 1)]
	return NpcModule.new(_need_defs(), _routine(), definitions)


func _world(module: NpcModule, world_seed: int = 3) -> World:
	var clock: SimClock = SimClock.new()
	var world: World = World.new(SimContext.new(clock, EventBus.new(clock), WorldRng.new(world_seed), IdGenerator.new()))
	assert_true(world.register_module("npc", module).ok)
	world.setup()
	world.post_setup()
	return world


func _spawn(module: NpcModule, tier: int, occupation_id: String, traits: Array[int] = [], place_id: String = HOME, x_cm: int = HOME_X_CM) -> int:
	var spec: NpcSpec = NpcSpec.new()
	spec.name_key = "npc.name.villager"
	spec.tier = tier
	spec.occupation_id = occupation_id
	spec.settlement_id = VILLAGE
	spec.place_id = place_id
	spec.home_place_id = HOME
	spec.work_place_id = WORK
	spec.x_cm = x_cm
	if not traits.is_empty():
		spec.traits = PackedInt64Array(traits)
	var created: NpcModule.CreateResult = module.request_create_npc(spec)
	assert_true(created.result.ok, created.result.message)
	return created.npc_id


func _run(world: World, minutes: int) -> void:
	for _step: int in minutes:
		world.context.clock.advance_step()
		world.tick(1)
		world.context.events.dispatch()


func _listen(world: World) -> Array[RelationChanged]:
	var heard: Array[RelationChanged] = []
	world.context.events.subscribe("RelationChanged", func(event: SimEvent) -> void: heard.append(event as RelationChanged))
	return heard


func _values(module: NpcModule, first_id: int, second_id: int) -> Array:
	var found: Array = []
	for value: int in module.peek_opinion(first_id, second_id).values:
		found.append(value)
	return found


# ---------------------------------------------------------------------------------------------------- o módulo inteiro: conversar

## Dois notáveis da rotina "conversar" andam até o local de convívio e conversam por seis horas (as conversas duram 30 minutos). A afeição e a confiança
## são o ganho vezes o número de conversas (cada uma deixa UM registro em cada um), sem passar do teto. O evento sai uma vez no dia, não uma por conversa.
func test_two_notables_who_talk_get_acquainted_remember_it_and_the_event_is_aggregated() -> void:
	var module: NpcModule = _module(1, 100)
	var world: World = _world(module)
	var heard: Array[RelationChanged] = _listen(world)
	var first: int = _spawn(module, NOTABLE, "talker")
	var second: int = _spawn(module, NOTABLE, "talker")
	_run(world, 360)
	var conversations: int = module.peek_memories(first, "conversation").records.size()
	assert_gt(conversations, 1, "Conversaram mais de uma vez em seis horas.")
	assert_eq(module.peek_memories(second, "conversation").records.size(), conversations, "Cada conversa deixa um registro nos dois.")
	assert_eq(_values(module, first, second), [conversations, conversations, 0, 0, 0], "Ganho 1 por conversa, em afeição e confiança.")
	assert_eq(module.peek_memories(first).records[0].actors[0], second, "O registro guarda o outro como pessoa.")
	assert_eq(module.peek_memories(first).records[0].place_id, SOCIAL)
	assert_eq(module.peek_opinion(first, second).met_at, module.peek_memories(first).records[0].time, "Conheceram-se na primeira conversa.")
	assert_eq(heard.size(), 1, "Várias conversas no mesmo dia, UM evento só.")
	assert_eq([heard[0].a_id, heard[0].b_id], [first, second])
	assert_eq(Array(heard[0].values), [1, 1, 0, 0, 0], "O evento leva as dimensões de quando saiu: depois da primeira conversa.")
	assert_lt(module.peek_npc(first).need_values[SOCIAL_NEED], 50, "A conversa também aliviou a necessidade `social` (o que já existia).")
	_run(world, MINUTES_PER_DAY)
	assert_eq(heard.size(), 2, "No dia seguinte a relação mudou de novo: o segundo evento (e só ele).")
	assert_eq(module.validate().size(), 0, str(module.validate()))
	world.teardown()


func test_the_gain_stops_at_the_limit() -> void:
	var module: NpcModule = _module(5, 12)
	var world: World = _world(module)
	var first: int = _spawn(module, NOTABLE, "talker")
	var second: int = _spawn(module, NOTABLE, "talker")
	_run(world, 600)
	assert_gt(module.peek_memories(first, "conversation").records.size(), 3, "Mais conversas do que cabem no teto.")
	assert_eq(_values(module, first, second), [12, 12, 0, 0, 0], "5, 10, 12 (para no teto) e fica.")
	world.teardown()


func test_citizens_who_talk_only_relieve_the_need_and_a_notable_with_a_citizen_gets_a_one_sided_memory() -> void:
	var citizens: NpcModule = _module()
	var citizens_world: World = _world(citizens)
	var citizens_heard: Array[RelationChanged] = _listen(citizens_world)
	var first_citizen: int = _spawn(citizens, NORMAL, "talker")
	var second_citizen: int = _spawn(citizens, NORMAL, "talker")
	_run(citizens_world, 360)
	assert_false(citizens.peek_opinion(first_citizen, second_citizen).is_known, "Cidadão com cidadão não cria relação.")
	assert_eq([citizens.peek_memories(first_citizen).records.size(), citizens_heard.size()], [0, 0], "Nem memória, nem evento.")
	assert_lt(citizens.peek_npc(first_citizen).need_values[SOCIAL_NEED], 50, "Mas a necessidade `social` foi aliviada.")
	var mixed: NpcModule = _module()
	var mixed_world: World = _world(mixed)
	var mixed_heard: Array[RelationChanged] = _listen(mixed_world)
	var notable: int = _spawn(mixed, NOTABLE, "talker")
	var citizen: int = _spawn(mixed, NORMAL, "talker")
	_run(mixed_world, 360)
	assert_true(mixed.peek_opinion(notable, citizen).is_known, "Notável com cidadão: a relação existe.")
	assert_gt(mixed.peek_memories(notable, "conversation").records.size(), 0)
	assert_eq(mixed.peek_memories(citizen).records.size(), 0, "O cidadão não tem memória (só T2).")
	assert_eq(mixed_heard.size(), 1)
	assert_eq(mixed.validate().size(), 0, str(mixed.validate()))
	citizens_world.teardown()
	mixed_world.teardown()


func test_talking_alone_creates_nothing_but_still_relieves_the_need() -> void:
	var module: NpcModule = _module()
	var world: World = _world(module)
	var heard: Array[RelationChanged] = _listen(world)
	var lonely: int = _spawn(module, NOTABLE, "talker")
	_run(world, 360)
	assert_eq([module.peek_memories(lonely).records.size(), heard.size(), module.debug_summary()["relations"]], [0, 0, 0], "Sem parceiro, só alivia a necessidade.")
	assert_lt(module.peek_npc(lonely).need_values[SOCIAL_NEED], 50)
	world.teardown()


# ---------------------------------------------------------------------------------------------------- o módulo inteiro: o evento agregado

func test_the_event_comes_out_once_per_pair_per_day_and_only_when_something_changed() -> void:
	var module: NpcModule = _module()
	var world: World = _world(module)
	var heard: Array[RelationChanged] = _listen(world)
	var notable: int = _spawn(module, NOTABLE, "")
	var citizen: int = _spawn(module, NORMAL, "")
	var other_citizen: int = _spawn(module, NORMAL, "")
	for _index: int in 5:
		assert_true(module.request_adjust_relation(notable, citizen, PackedInt64Array([4, 0, 0, 0, 0])).ok)
	_run(world, 1)
	assert_eq(heard.size(), 1, "Cinco mudanças no mesmo dia: um evento.")
	assert_eq(Array(heard[0].values), [4, 0, 0, 0, 0], "Com os valores de quando saiu (na primeira mudança do dia).")
	assert_true(module.request_adjust_relation(notable, citizen, PackedInt64Array([0, 0, 0, 0, 0])).ok)
	_run(world, 1)
	assert_eq(heard.size(), 1, "Mudança zero não é mudança.")
	assert_true(module.request_adjust_relation(notable, other_citizen, PackedInt64Array([0, 0, 0, 0, 0])).ok)
	_run(world, 1)
	assert_eq(heard.size(), 2, "Mas conhecer-se, mesmo sem número, é uma relação nova: evento do outro par.")
	_run(world, MINUTES_PER_DAY)
	assert_true(module.request_adjust_relation(notable, citizen, PackedInt64Array([0, 0, 0, 0, 0])).ok)
	_run(world, 1)
	assert_eq(heard.size(), 2, "No dia seguinte o espaço do evento está livre, mas tocar na relação sem mudar nada não publica.")
	assert_true(module.request_adjust_relation(notable, citizen, PackedInt64Array([1, 0, 0, 0, 0])).ok)
	_run(world, 1)
	assert_eq(heard.size(), 3, "No dia seguinte o mesmo par pode publicar de novo, quando algo muda.")
	assert_eq(Array(heard[2].values), [21, 0, 0, 0, 0], "O evento leva os valores NOVOS (depois da mudança), não os de antes.")
	assert_true(module.request_adjust_relation(notable, citizen, PackedInt64Array([100, 0, 0, 0, 0])).ok)
	assert_true(module.request_adjust_relation(notable, citizen, PackedInt64Array([5, 0, 0, 0, 0])).ok)
	_run(world, 1)
	assert_eq(heard.size(), 3, "Já saiu hoje, e a segunda (no teto de 100) não mudou nada de qualquer jeito.")
	var refused: Result = module.request_adjust_relation(citizen, other_citizen, PackedInt64Array([1, 0, 0, 0, 0]))
	assert_false(refused.ok)
	_run(world, 1)
	assert_eq(heard.size(), 3, "Pedido recusado não publica nada.")
	world.teardown()


func test_the_day_of_the_last_event_is_saved_so_a_loaded_game_does_not_repeat_it() -> void:
	var module: NpcModule = _module()
	var world: World = _world(module)
	var notable: int = _spawn(module, NOTABLE, "")
	var citizen: int = _spawn(module, NORMAL, "")
	assert_true(module.request_adjust_relation(notable, citizen, PackedInt64Array([4, 0, 0, 0, 0])).ok)
	_run(world, 10)
	var saved_relation: Dictionary = module.serialize()["relations"][0]
	assert_eq(saved_relation["last_event_day"], 0)
	var parsed: Variant = JSON.parse_string(JSON.stringify(world.serialize(), "", true, true))
	var saved: Dictionary = parsed
	var other: NpcModule = _module()
	var other_world: World = _world(other)
	var heard: Array[RelationChanged] = _listen(other_world)
	assert_true(other_world.on_load(saved).ok)
	assert_true(other.request_adjust_relation(notable, citizen, PackedInt64Array([4, 0, 0, 0, 0])).ok)
	_run(other_world, 1)
	assert_eq(heard.size(), 0, "Depois de carregar, o dia continua marcado: o evento de hoje não sai de novo.")
	_run(other_world, MINUTES_PER_DAY)
	assert_true(other.request_adjust_relation(notable, citizen, PackedInt64Array([4, 0, 0, 0, 0])).ok)
	_run(other_world, 1)
	assert_eq(heard.size(), 1, "No dia seguinte sai.")
	var old_save: Dictionary = module.serialize()
	var old_relations: Array = old_save["relations"]
	var old_entry: Dictionary = old_relations[0]
	old_entry.erase("last_event_day")
	assert_true(module.on_load(old_save).ok, "Save de antes da LW-080 carrega (nunca publicou).")
	assert_eq(module.serialize()["relations"][0]["last_event_day"], NpcRelation.NO_EVENT_DAY)
	old_entry["last_event_day"] = "ontem"
	assert_string_contains(module.on_load(old_save).message, "last_event_day")
	old_entry["last_event_day"] = -7
	assert_true(module.on_load(old_save).ok)
	assert_string_contains("\n".join(module.validate()), "last_event_day -7")
	old_entry["last_event_day"] = 99
	assert_true(module.on_load(old_save).ok)
	assert_string_contains("\n".join(module.validate()), "last_event_day 99")
	world.teardown()
	other_world.teardown()


# ---------------------------------------------------------------------------------------------------- o módulo inteiro: ajudar

## O alarme soa no trabalho. O ajudante (leal e sociável) sai de casa, anda até o trabalho e ajuda por 20 minutos. O notável que trabalha ali (e não vai
## ajudar: covarde) ganha o registro `help_received` com o ajudante como pessoa; o cidadão que também está ali não ganha nada.
func test_helping_at_the_alarm_gives_the_notable_at_the_place_a_positive_memory() -> void:
	var module: NpcModule = _module()
	var world: World = _world(module)
	var victim: int = _spawn(module, NOTABLE, "worker", COWARD_TRAITS, WORK, WORK_X_CM)
	var bystander: int = _spawn(module, NORMAL, "worker", COWARD_TRAITS, WORK, WORK_X_CM)
	var helper: int = _spawn(module, NORMAL, "", HELPER_TRAITS)
	_run(world, 14)
	assert_true(module.request_raise_alarm(WORK_X_CM, 0, 1).ok)
	_run(world, 60)
	assert_gt(module.peek_memories(victim, "help_received").records.size(), 0, "O notável do local ganhou a memória de ter sido ajudado.")
	var record: MemoryRecord = module.peek_memories(victim, "help_received").records[0]
	assert_eq([record.kind, Array(record.actors), record.place_id, record.valence], ["help_received", [helper], WORK, 60], "Quem ajudou é a pessoa do episódio; a valência é positiva.")
	assert_eq(module.peek_memories(bystander).records.size(), 0, "O cidadão não tem memória.")
	assert_eq(module.peek_memories(helper).records.size(), 0, "Quem ajudou não grava nada: foi ele quem ajudou.")
	assert_eq(module.debug_summary()["relations"], 0, "Ajudar não mexe na relação.")
	assert_eq(module.validate().size(), 0, str(module.validate()))
	world.teardown()


# ---------------------------------------------------------------------------------------------------- o dado e o mundo real

func _valid_params_record() -> Dictionary:
	return {
		"id": "default", "urgency_weight_comfortable": 0, "urgency_weight_attention": 1, "urgency_weight_urgent": 3, "urgency_weight_critical": 6,
		"time_cost_per_hour": 2, "distance_cost_per_100m": 2, "risk_cost_percent": 100, "inertia_bonus": 25, "routine_bonus": 40,
		"think_interval_min": 10, "max_thinks_per_step": 20, "decision_top_k": 3, "decision_margin": 15,
	}


func _load_params(record: Dictionary) -> NpcParamsLoader.LoadResult:
	var records: Array[Dictionary] = [record]
	var bundle: DataBundle = DataBundle.new()
	bundle.tables[NpcParamsLoader.PARAMS_TABLE] = records
	bundle.file_paths[NpcParamsLoader.PARAMS_TABLE] = PARAMS_LABEL
	DataValidator.new().validate(bundle, [NpcParamsLoader.build_schema()])
	return NpcParamsLoader.from_bundle(bundle)


func test_the_talk_parameters_come_from_the_data_are_optional_and_are_checked() -> void:
	var real: NpcParams = NpcParamsLoader.load_dir().params
	assert_eq([real.talk_gain, real.talk_limit], [3, 60], "O arquivo real tem os números [HIP].")
	var absent: NpcParams = _load_params(_valid_params_record()).params
	assert_eq([absent.talk_gain, absent.talk_limit], [0, 0], "Sem os campos, conversar não muda a relação.")
	var record: Dictionary = _valid_params_record()
	record["talk_gain"] = 4
	record["talk_limit"] = 70
	var built: NpcParams = _load_params(record).params
	assert_eq([built.talk_gain, built.talk_limit], [4, 70])
	for case: Array in [["talk_gain", -1], ["talk_gain", 101], ["talk_gain", "muito"], ["talk_limit", -1], ["talk_limit", 101]]:
		var invalid: Dictionary = _valid_params_record()
		invalid[case[0]] = case[1]
		var failed: NpcParamsLoader.LoadResult = _load_params(invalid)
		assert_false(failed.result.ok, "%s = %s deveria falhar." % [case[0], str(case[1])])
		assert_eq(failed.result.code, PARAMS_ISSUE_CODE)
		assert_string_contains(failed.result.message, case[0])


func _real_game() -> RealGame:
	var terrain_loaded: TerrainLoader.LoadResult = TerrainLoader.load_dir(WORLD_DIR)
	assert_true(terrain_loaded.result.ok, terrain_loaded.result.message)
	var settlements_loaded: SettlementLoader.LoadResult = SettlementLoader.load_dir(WORLD_DIR, terrain_loaded.terrain)
	assert_true(settlements_loaded.result.ok, settlements_loaded.result.message)
	var setup: NpcSetup = NpcSetup.from_dir(DATA_DIR, SettlementService.new(settlements_loaded.settlements, settlements_loaded.places), false)
	assert_true(setup.result.ok, setup.result.message)
	var game: RealGame = RealGame.new()
	game.runner = SimulationRunner.new(5)
	game.modules = GameModules.register(game.runner, terrain_loaded.terrain, [], setup)
	assert_true(game.modules.result.ok, game.modules.result.message)
	game.runner.start_new_game()
	return game


## O mundo real: 40 notáveis, dois dias. Nas noites de conversa (a rotina manda `talk` às 19 h) os notáveis que conversam no mesmo local formam pares por
## ordem de ID e passam a se conhecer. Tudo continua vivo e válido; para cada par e cada dia saiu no MÁXIMO um evento.
func test_the_real_world_notables_get_acquainted_in_the_evening_talks_and_the_world_stays_valid() -> void:
	var game: RealGame = _real_game()
	var npc: NpcModule = game.modules.npc
	var per_pair_and_day: Dictionary = {}
	var world: World = game.runner.world
	world.context.events.subscribe("RelationChanged", func(event: SimEvent) -> void:
		var changed: RelationChanged = event as RelationChanged
		var key: String = "%d:%d@%d" % [changed.a_id, changed.b_id, IntMath.floor_div(world.context.clock.total_minutes(), MINUTES_PER_DAY)]
		per_pair_and_day[key] = int(per_pair_and_day.get(key, 0)) + 1)
	var ids: Array[int] = npc.peek_npc_ids()
	for index: int in 40:
		assert_true(npc.request_promote(ids[index], NOTABLE).ok)
	game.runner.run_steps(MINUTES_PER_DAY * 2)
	var summary: Dictionary = npc.debug_summary()
	assert_gt(summary["relations"], 0, "Alguns notáveis conversaram juntos.")
	assert_gt(summary["memory_records"], 0)
	assert_gt(per_pair_and_day.size(), 0, "E a mudança das relações foi publicada.")
	assert_eq(per_pair_and_day.values().max(), 1, "Nenhum par publicou mais de uma vez no mesmo dia.")
	assert_eq(npc.peek_counts()[NpcModule.COUNT_ALIVE], 100)
	assert_eq(world.validate().size(), 0, str(world.validate()))
	game.runner.finish()
