extends GutTest
## LW-082b: as duas consultas novas do `npc` para o painel de depuração (docs/modules/npc.md, seção 10; contrato na LW-082a), sem janela.
## `peek_need_ids`: os ids das necessidades na ordem dos dados, em cópia. `peek_relations`: as relações de um NPC, em cópias, em ordem crescente do ID
## da outra pessoa, com a mesma conta de `peek_opinion` (dimensões de hoje, rótulo, quando se conheceram, se a outra vive). As duas só leem.

const VILLAGE: String = "village_a"
const HOME: String = "home_a1"
const WORK: String = "work_a1"
const NEED_IDS: Array[String] = ["hunger", "rest", "safety", "income", "social"]
const TRAIT_IDS: Array[String] = ["caution", "sociability", "ambition", "loyalty"]
const HOME_X_CM: int = 8400
const NOTABLE: int = NpcState.TIER_NOTABLE
const NORMAL: int = NpcState.TIER_NORMAL
const PLAYER: int = 9000
const MINUTES_PER_DAY: int = 1440
const FRIEND_AT: int = 50
const RIVAL_AT: int = 40
const CAPACITY: int = 8
const DECAY_PER_DAY: int = 2
## Quase todos os pedidos de teste somam só na afeição (a primeira das cinco dimensões).
const AFFECTION: int = NpcRelation.DIM_AFFECTION


func _need_defs() -> Array[NeedDef]:
	var defs: Array[NeedDef] = []
	for position: int in NEED_IDS.size():
		defs.append(NeedDef.new(NEED_IDS[position], position, 0, 0, 40, 65, 90))
	return defs


func _module(with_definitions: bool = true) -> NpcModule:
	if not with_definitions:
		return NpcModule.new()
	var definitions: NpcModule.Definitions = NpcModule.Definitions.new()
	var work: ActionDef = ActionDef.new("work", 240, "work", 5, true)
	work.effects.append(ActionDef.ActionEffect.new("rest", 5))
	definitions.actions = [work, ActionDef.new("wait", 10, "", 0, true), ActionDef.new(ActionRunner.GO_TO_PLACE_ID, 0, "", 0, true)]
	var traits: Array[TraitLoader.TraitDef] = []
	for position: int in TRAIT_IDS.size():
		traits.append(TraitLoader.TraitDef.new(TRAIT_IDS[position], position))
	definitions.traits = traits
	var params: NpcParams = NpcParams.new()
	params.urgency_weight_attention = 1
	params.urgency_weight_urgent = 3
	params.urgency_weight_critical = 6
	params.time_cost_per_hour = 2
	params.distance_cost_per_100m = 2
	params.risk_cost_percent = 100
	params.inertia_bonus = 25
	params.routine_bonus = 40
	params.think_interval_min = 10
	params.max_thinks_per_step = 20
	params.decision_top_k = 1
	params.relations_capacity = CAPACITY
	params.relation_decay_per_day = DECAY_PER_DAY
	params.relation_friend_threshold = FRIEND_AT
	params.relation_rival_threshold = RIVAL_AT
	var settlements: Array[Settlement] = [Settlement.new(VILLAGE, "settlement.a", Vector3.ZERO)]
	var places: Array[Place] = [Place.new(HOME, VILLAGE, Place.KIND_HOME, Vector3(84.0, 0.0, 0.0), 12), Place.new(WORK, VILLAGE, Place.KIND_WORK, Vector3(184.0, 0.0, 0.0), 12)]
	definitions.params = params
	definitions.places = SettlementService.new(settlements, places)
	definitions.is_development_build = true
	var occupations: Array[RoutineTable.OccupationDef] = [RoutineTable.OccupationDef.new("tester", "work")]
	var blocks: Array[RoutineTable.RoutineBlock] = [RoutineTable.RoutineBlock.new("t", "tester", 0, 24, "work")]
	return NpcModule.new(_need_defs(), RoutineTable.new(occupations, blocks), definitions)


func _world(module: NpcModule) -> World:
	var clock: SimClock = SimClock.new()
	var world: World = World.new(SimContext.new(clock, EventBus.new(clock), WorldRng.new(3), IdGenerator.new()))
	assert_true(world.register_module("npc", module).ok)
	world.setup()
	world.post_setup()
	return world


func _spawn(module: NpcModule, tier: int = NOTABLE) -> int:
	var spec: NpcSpec = NpcSpec.new()
	spec.name_key = "npc.name.villager"
	spec.tier = tier
	spec.settlement_id = VILLAGE
	spec.place_id = HOME
	spec.home_place_id = HOME
	spec.work_place_id = WORK
	spec.x_cm = HOME_X_CM
	var created: NpcModule.CreateResult = module.request_create_npc(spec)
	assert_true(created.result.ok, created.result.message)
	return created.npc_id


func _relate(module: NpcModule, first_id: int, second_id: int, affection: int, trust: int = 0) -> void:
	var adjusted: Result = module.request_adjust_relation(first_id, second_id, PackedInt64Array([affection, trust, 0, 0, 0]))
	assert_true(adjusted.ok, adjusted.message)


func _run(world: World, minutes: int) -> void:
	for _step: int in minutes:
		world.context.clock.advance_step()
		world.tick(1)
		world.context.events.dispatch()


func _ids_of(query: NpcRelationsQuery) -> Array[int]:
	var ids: Array[int] = []
	for entry: NpcRelationsQuery.Entry in query.entries:
		ids.append(entry.other_id)
	return ids


# ---------------------------------------------------------------------------------------------------- peek_need_ids

func test_need_ids_come_in_the_order_of_the_data_and_as_a_copy() -> void:
	var module: NpcModule = _module()
	assert_eq(module.peek_need_ids(), NEED_IDS, "Os ids das necessidades, na ordem dos dados.")
	var first: Array[String] = module.peek_need_ids()
	first.append("intruder")
	first[0] = "changed"
	assert_eq(module.peek_need_ids(), NEED_IDS, "Mexer na resposta não muda o módulo.")


func test_a_module_without_need_definitions_has_no_need_ids() -> void:
	assert_eq(_module(false).peek_need_ids().size(), 0)


# ---------------------------------------------------------------------------------------------------- peek_relations

## Aceite: as relações vêm em ordem crescente do outro, não importa quem é o "a" do par, com a mesma conta de `peek_opinion`.
func test_relations_come_in_ascending_order_of_the_other_person_with_the_opinion_numbers() -> void:
	var module: NpcModule = _module()
	var world: World = _world(module)
	var low: int = _spawn(module, NORMAL)
	var subject: int = _spawn(module)
	var high: int = _spawn(module)
	_relate(module, high, subject, 60, 10)
	_relate(module, subject, PLAYER, -45)
	_relate(module, low, subject, 5)
	var query: NpcRelationsQuery = module.peek_relations(subject)
	assert_true(query.result.ok, query.result.message)
	assert_eq(_ids_of(query), [low, high, PLAYER] as Array[int], "Ordem crescente do ID da outra pessoa.")
	for entry: NpcRelationsQuery.Entry in query.entries:
		var opinion: NpcModule.OpinionQuery = module.peek_opinion(subject, entry.other_id)
		assert_eq(entry.values, opinion.values, "Mesmas dimensões de peek_opinion (%d)." % entry.other_id)
		assert_eq([entry.label, entry.met_at, entry.other_is_alive], [opinion.label, opinion.met_at, true], "Mesmo rótulo, mesmo encontro e a outra pessoa viva.")
	assert_eq([query.entries[0].label, query.entries[1].label, query.entries[2].label], ["acquaintance", "friend", "rival"], "Os rótulos seguem os limiares dos dados.")
	assert_eq(Array(query.entries[1].values), [60, 10, 0, 0, 0])
	world.teardown()


func test_a_citizen_without_relations_a_dead_npc_and_an_unknown_id() -> void:
	var module: NpcModule = _module()
	var world: World = _world(module)
	var citizen: int = _spawn(module, NORMAL)
	var dead: int = _spawn(module)
	var saved: Dictionary = module.serialize()
	var entries: Dictionary = saved["npcs"]
	entries[str(dead)]["is_alive"] = false
	entries[str(dead)]["death_cause"] = "hunger"
	entries[str(dead)]["died_at"] = 1
	assert_true(module.on_load(saved).ok)
	for npc_id: int in [citizen, dead]:
		var empty: NpcRelationsQuery = module.peek_relations(npc_id)
		assert_true(empty.result.ok, empty.result.message)
		assert_eq(empty.entries.size(), 0, "Sem relação (ou morto): lista vazia, com sucesso.")
	var unknown: NpcRelationsQuery = module.peek_relations(777)
	assert_eq(unknown.result.code, NpcModule.CODE_UNKNOWN, "ID inexistente é falha tratada, sem derrubar o jogo.")
	assert_eq(unknown.entries.size(), 0)
	world.teardown()


func test_removing_the_other_person_drops_the_entry_and_the_answer_is_a_copy() -> void:
	var module: NpcModule = _module()
	var world: World = _world(module)
	var subject: int = _spawn(module)
	var friend: int = _spawn(module)
	_relate(module, subject, friend, 30)
	_relate(module, subject, PLAYER, 20)
	var query: NpcRelationsQuery = module.peek_relations(subject)
	query.entries[0].values[AFFECTION] = 99
	query.entries.clear()
	assert_eq(module.peek_relations(subject).entries[0].values[AFFECTION], 30, "Mexer na resposta não muda a relação guardada.")
	assert_true(module.request_remove_npc(friend).ok)
	assert_eq(_ids_of(module.peek_relations(subject)), [PLAYER] as Array[int], "Quem saiu do jogo leva a relação junto.")
	world.teardown()


func test_relations_show_the_decayed_values_of_today_and_looking_changes_nothing() -> void:
	var module: NpcModule = _module()
	var world: World = _world(module)
	var subject: int = _spawn(module)
	_relate(module, subject, PLAYER, 9)
	_run(world, MINUTES_PER_DAY * 3)
	var before: Dictionary = module.serialize()
	var summary_before: Dictionary = module.debug_summary()
	var entry: NpcRelationsQuery.Entry = module.peek_relations(subject).entries[0]
	assert_eq(Array(entry.values), [3, 0, 0, 0, 0], "Três dias a 2 por dia: 9 viram 3, como em peek_opinion.")
	assert_eq(entry.values, module.peek_opinion(subject, PLAYER).values)
	module.peek_need_ids()
	assert_eq(module.serialize(), before, "As consultas não gravam nada no save.")
	assert_eq(module.debug_summary(), summary_before, "Nem mudam o resumo de depuração.")
	world.teardown()
