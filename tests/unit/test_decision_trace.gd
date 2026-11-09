extends GutTest
## LW-064: o rastro de decisão do NPC (DecisionTracer, NpcModule.explain_decision e request_set_traced; docs/modules/npc.md, seção 5), sem
## janela. Para o NPC MARCADO: as candidatas com cada parcela da pontuação, a escolha e o motivo; para o NÃO marcado: nenhum custo nem dado.
## Só em build de desenvolvimento, não é salvo, não entra no hash e não muda nenhuma decisão. Mundo de teste montado à mão (os números do
## teste_decision_flow.gd), com contas fáceis de conferir.

## Velocidade de caminhada fixada na antiga (8400 cm/min): este teste mede a lógica, não a velocidade padrão; a velocidade padrão (500 cm/min, DEC-123) é coberta em test_action_runner.gd.
const WALK_SPEED_CM_PER_MIN: int = 8400
const VILLAGE: String = "village_a"
const HOME: String = "home_a1"
const WORK: String = "work_a1"
const NEED_IDS: Array[String] = ["hunger", "rest", "safety", "income", "social"]
const TRAIT_IDS: Array[String] = ["caution", "sociability", "ambition", "loyalty"]
const HOME_X_CM: int = 8400
const THINK_INTERVAL: int = 10


## Provedor de comida de teste.
class FakeFood:
	extends ActionConditionProvider

	func has_food(_settlement_id: String) -> bool:
		return true


func _need_defs(start_hunger: int) -> Array[NeedDef]:
	var defs: Array[NeedDef] = []
	for position: int in NEED_IDS.size():
		defs.append(NeedDef.new(NEED_IDS[position], position, start_hunger if position == 0 else 0, 0, 40, 65, 90))
	return defs


func _action(action_id: String, duration: int, place_kind: String, risk: int = 0) -> ActionDef:
	return ActionDef.new(action_id, duration, place_kind, risk, true)


func _catalog() -> Array[ActionDef]:
	var eat: ActionDef = _action("eat", 20, "home")
	eat.effects.append(ActionDef.ActionEffect.new("hunger", -60))
	eat.conditions.append(ActionDef.ActionCondition.new(ActionDef.CONDITION_HAS_FOOD, "", ActionDef.ABSENT, ActionDef.ABSENT))
	var snack: ActionDef = _action("snack", 5, "")
	snack.effects.append(ActionDef.ActionEffect.new("hunger", -60))
	var work: ActionDef = _action("work", 240, "work", 5)
	work.effects.append(ActionDef.ActionEffect.new("rest", 5))
	return [eat, snack, work, _action("wait", 10, ""), _action(ActionRunner.GO_TO_PLACE_ID, 0, "")]


func _routine() -> RoutineTable:
	var occupations: Array[RoutineTable.OccupationDef] = [RoutineTable.OccupationDef.new("tester", "work")]
	var blocks: Array[RoutineTable.RoutineBlock] = [RoutineTable.RoutineBlock.new("t", "tester", 0, 24, "work")]
	return RoutineTable.new(occupations, blocks)


func _places() -> SettlementService:
	var settlements: Array[Settlement] = [Settlement.new(VILLAGE, "settlement.a", Vector3.ZERO)]
	var places: Array[Place] = [Place.new(HOME, VILLAGE, Place.KIND_HOME, Vector3(84.0, 0.0, 0.0), 5), Place.new(WORK, VILLAGE, Place.KIND_WORK, Vector3(184.0, 0.0, 0.0), 5)]
	return SettlementService.new(settlements, places)


func _params() -> NpcParams:
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
	params.decision_top_k = 3
	params.decision_margin = 15
	return params


func _module(start_hunger: int, is_development_build: bool = true) -> NpcModule:
	var definitions: NpcModule.Definitions = NpcModule.Definitions.new()
	definitions.actions = _catalog()
	var traits: Array[TraitLoader.TraitDef] = []
	for position: int in TRAIT_IDS.size():
		traits.append(TraitLoader.TraitDef.new(TRAIT_IDS[position], position))
	definitions.traits = traits
	definitions.params = _params()
	definitions.walk_speed_cm_per_min = WALK_SPEED_CM_PER_MIN
	definitions.places = _places()
	definitions.food = FakeFood.new()
	definitions.is_development_build = is_development_build
	return NpcModule.new(_need_defs(start_hunger), _routine(), definitions)


func _world(module: NpcModule, world_seed: int = 3) -> World:
	var clock: SimClock = SimClock.new()
	var world: World = World.new(SimContext.new(clock, EventBus.new(clock), WorldRng.new(world_seed), IdGenerator.new()))
	assert_true(world.register_module("npc", module).ok)
	world.setup()
	world.post_setup()
	return world


## NPC em casa; sem ofício ele não tem rotina e só espera.
func _spawn(module: NpcModule, occupation_id: String = "tester") -> int:
	var spec: NpcSpec = NpcSpec.new()
	spec.name_key = "npc.name.villager"
	spec.occupation_id = occupation_id
	spec.settlement_id = VILLAGE
	spec.place_id = HOME
	spec.home_place_id = HOME
	spec.work_place_id = WORK
	spec.x_cm = HOME_X_CM
	var created: NpcModule.CreateResult = module.request_create_npc(spec)
	assert_true(created.result.ok, created.result.message)
	return created.npc_id


func _run(world: World, minutes: int) -> void:
	for _step: int in minutes:
		world.context.clock.advance_step()
		world.tick(1)


func _first_think(npc_id: int) -> int:
	return 1 + npc_id % THINK_INTERVAL


## As parcelas somam o total: benefício + personalidade - tempo - distância - risco + inércia + rotina.
func _parts_add_up(candidate: DecisionTracer.CandidateRecord) -> bool:
	return candidate.benefit + candidate.personality - candidate.time_cost - candidate.distance_cost - candidate.risk_cost + candidate.inertia_bonus + candidate.routine_bonus == candidate.total


# ---------------------------------------------------------------------------------------------------- o rastro de quem está marcado

func test_a_marked_hungry_npc_shows_every_candidate_with_its_score_parts_and_the_urgent_need_reason() -> void:
	var module: NpcModule = _module(95)
	var world: World = _world(module)
	var npc_id: int = _spawn(module)
	assert_true(module.request_set_traced(npc_id, true).ok)
	_run(world, _first_think(npc_id))
	var explained: DecisionTracer.Explanation = module.explain_decision(npc_id)
	assert_true(explained.result.ok, explained.result.message)
	assert_eq(explained.records.size(), 1)
	var record: DecisionTracer.DecisionRecord = explained.records[0]
	assert_eq(record.minute, _first_think(npc_id))
	assert_eq(record.need_values[0], 95, "As necessidades do momento da decisão.")
	assert_eq(record.reason, DecisionTracer.REASON_URGENT_NEED)
	assert_eq(record.candidates.size(), 2, "Comer e lanchar aliviam a fome crítica; trabalhar (rotina) fica de fora com fome urgente.")
	for candidate: DecisionTracer.CandidateRecord in record.candidates:
		assert_true(_parts_add_up(candidate), "%s: as parcelas somam o total." % candidate.action_id)
		assert_eq(candidate.source, DecisionTracer.REASON_URGENT_NEED)
		assert_false(candidate.is_current)
	var eat: DecisionTracer.CandidateRecord = record.candidates[0]
	assert_eq([eat.action_id, eat.place_id], ["eat", HOME], "Empate nos pontos: a ordem é o id da ação.")
	assert_eq([eat.benefit, eat.time_cost, eat.distance_cost, eat.risk_cost, eat.total], [360, 0, 0, 0, 360], "Alívio 60 x peso crítico 6; já em casa, sem custo.")
	assert_eq(record.candidates[1].action_id, "snack")
	assert_true(record.chosen_action_id == "eat" or record.chosen_action_id == "snack", "Escolheu uma das duas empatadas.")
	assert_eq(record.chosen_place_id, HOME, "Em casa tanto comer quanto lanchar (que não tem local próprio) acontecem em casa.")
	world.teardown()


func test_the_routine_the_walk_and_inertia_show_up_as_reasons_with_their_bonuses() -> void:
	var module: NpcModule = _module(0)
	var world: World = _world(module)
	var npc_id: int = _spawn(module)
	assert_true(module.request_set_traced(npc_id, true).ok)
	var first: int = _first_think(npc_id)
	_run(world, first + 2 + THINK_INTERVAL)
	var records: Array[DecisionTracer.DecisionRecord] = module.explain_decision(npc_id).records
	assert_eq(records.size(), 3, "Pensou no minuto %d (rotina), no %d (chegou ao trabalho) e no %d (trabalhando)." % [first, first + 2, first + 2 + THINK_INTERVAL])
	var routine: DecisionTracer.DecisionRecord = records[0]
	assert_eq(routine.reason, DecisionTracer.REASON_ROUTINE)
	assert_eq([routine.chosen_action_id, routine.chosen_place_id], ["work", WORK], "Escolheu trabalhar; o primeiro passo é andar, mas o rastro guarda a ação escolhida.")
	var work: DecisionTracer.CandidateRecord = routine.candidates[0]
	assert_eq([work.routine_bonus, work.distance_cost, work.time_cost, work.risk_cost, work.inertia_bonus], [40, 2, 8, 5, 0], "Bônus de rotina 40; 100 m = 2; 4 h = 8; risco 5.")
	assert_eq(work.total, 40 - 2 - 8 - 5)
	assert_true(_parts_add_up(work))
	var arrived: DecisionTracer.DecisionRecord = records[1]
	assert_eq(arrived.reason, DecisionTracer.REASON_ROUTINE, "No fim da caminhada o NPC já está no trabalho e a rotina manda trabalhar.")
	var inertia: DecisionTracer.DecisionRecord = records[2]
	assert_eq(inertia.reason, DecisionTracer.REASON_INERTIA, "Trabalhando e nada melhor: continua.")
	var kept: DecisionTracer.CandidateRecord = inertia.candidates[0]
	assert_true(kept.is_current)
	assert_eq([kept.action_id, kept.inertia_bonus, kept.routine_bonus], ["work", 25, 40], "A ação em andamento ganha a inércia (25) e é também a da rotina (40).")
	assert_eq(inertia.chosen_action_id, "work")
	world.teardown()


func test_without_any_candidate_the_trace_says_fallback_and_lists_no_candidates() -> void:
	var module: NpcModule = _module(0)
	var world: World = _world(module)
	var npc_id: int = _spawn(module, "")
	assert_true(module.request_set_traced(npc_id, true).ok)
	_run(world, _first_think(npc_id))
	var record: DecisionTracer.DecisionRecord = module.explain_decision(npc_id).records[0]
	assert_eq(record.candidates.size(), 0)
	assert_eq([record.chosen_action_id, record.reason], ["wait", DecisionTracer.REASON_FALLBACK])
	world.teardown()


func test_only_the_last_few_thoughts_are_kept_oldest_first() -> void:
	var module: NpcModule = _module(0)
	var world: World = _world(module)
	var npc_id: int = _spawn(module, "")
	assert_true(module.request_set_traced(npc_id, true).ok)
	_run(world, 1440)
	var records: Array[DecisionTracer.DecisionRecord] = module.explain_decision(npc_id).records
	assert_eq(records.size(), DecisionTracer.TRACE_DEPTH, "Um dia de pensamentos a cada 10 minutos, mas só os últimos %d ficam." % DecisionTracer.TRACE_DEPTH)
	for index: int in range(1, records.size()):
		assert_eq(records[index].minute - records[index - 1].minute, THINK_INTERVAL, "Em ordem, do mais antigo ao mais novo.")
	assert_true(records[records.size() - 1].minute <= 1440 and records[records.size() - 1].minute > 1440 - THINK_INTERVAL, "O último é o pensamento mais recente.")
	assert_gt(module.debug_summary()["trace_records_made"], DecisionTracer.TRACE_DEPTH, "Foram feitos mais registros do que os guardados.")
	world.teardown()


# ---------------------------------------------------------------------------------------------------- quem não está marcado

func test_an_unmarked_npc_generates_no_cost_and_no_data() -> void:
	var module: NpcModule = _module(95)
	var world: World = _world(module)
	var ids: Array[int] = []
	for _index: int in 5:
		ids.append(_spawn(module))
	_run(world, 300)
	var summary: Dictionary = module.debug_summary()
	assert_eq([summary["traced_npcs"], summary["trace_records_made"]], [0, 0], "Ninguém marcado: nenhum registro foi criado.")
	var explained: DecisionTracer.Explanation = module.explain_decision(ids[0])
	assert_false(explained.result.ok)
	assert_eq(explained.result.code, DecisionTracer.CODE_NOT_TRACED)
	assert_eq(explained.records.size(), 0)
	assert_true(module.request_set_traced(ids[1], true).ok)
	_run(world, 100)
	assert_eq(module.explain_decision(ids[1]).records.size(), 8)
	assert_false(module.explain_decision(ids[0]).result.ok, "O outro continua sem rastro.")
	var after: Dictionary = module.debug_summary()
	assert_eq(after["traced_npcs"], 1)
	assert_true(after["trace_records_made"] > 0 and after["trace_records_made"] <= 100, "Só o NPC marcado fez registros (%d)." % after["trace_records_made"])
	world.teardown()


func test_unmarking_discards_the_trace_and_marking_again_starts_empty() -> void:
	var module: NpcModule = _module(0)
	var world: World = _world(module)
	var npc_id: int = _spawn(module, "")
	assert_true(module.request_set_traced(npc_id, true).ok)
	_run(world, 60)
	assert_gt(module.explain_decision(npc_id).records.size(), 0)
	assert_true(module.request_set_traced(npc_id, false).ok)
	assert_eq(module.explain_decision(npc_id).result.code, DecisionTracer.CODE_NOT_TRACED)
	assert_true(module.request_set_traced(npc_id, true).ok)
	assert_eq(module.explain_decision(npc_id).records.size(), 0, "Marcou de novo: começa do zero.")
	assert_true(module.request_set_traced(npc_id, true).ok, "Marcar quem já está marcado não apaga o rastro nem dá erro.")
	world.teardown()


func test_the_explanation_is_a_copy() -> void:
	var module: NpcModule = _module(95)
	var world: World = _world(module)
	var npc_id: int = _spawn(module)
	assert_true(module.request_set_traced(npc_id, true).ok)
	_run(world, _first_think(npc_id))
	var first: DecisionTracer.Explanation = module.explain_decision(npc_id)
	first.records[0].need_values[0] = 0
	first.records[0].candidates.clear()
	first.records.clear()
	var second: DecisionTracer.Explanation = module.explain_decision(npc_id)
	assert_eq(second.records.size(), 1)
	assert_eq(second.records[0].need_values[0], 95)
	assert_eq(second.records[0].candidates.size(), 2)
	world.teardown()


# ---------------------------------------------------------------------------------------------------- só em desenvolvimento

func test_marking_exists_only_in_development_builds_and_unknown_npcs_are_handled() -> void:
	var production: NpcModule = _module(0, false)
	var world: World = _world(production)
	var npc_id: int = _spawn(production)
	var refused: Result = production.request_set_traced(npc_id, true)
	assert_false(refused.ok)
	assert_eq(refused.code, NpcModule.CODE_DEV_ONLY)
	assert_eq(production.debug_summary()["traced_npcs"], 0, "Fora do desenvolvimento nada é marcado.")
	assert_eq(production.explain_decision(npc_id).result.code, DecisionTracer.CODE_NOT_TRACED)
	assert_eq(NpcModule.new().request_set_traced(1, true).code, NpcModule.CODE_DEV_ONLY, "Módulo sem definições também não é desenvolvimento.")
	var development: NpcModule = _module(0, true)
	var development_world: World = _world(development)
	assert_eq(development.request_set_traced(99, true).code, NpcModule.CODE_UNKNOWN)
	assert_eq(development.explain_decision(99).result.code, NpcModule.CODE_UNKNOWN)
	world.teardown()
	development_world.teardown()


# ---------------------------------------------------------------------------------------------------- só para olhar

func _hash_after(world_seed: int, trace_everyone: bool) -> String:
	var module: NpcModule = _module(95)
	var world: World = _world(module, world_seed)
	for _index: int in 6:
		var npc_id: int = _spawn(module)
		if trace_everyone:
			assert_true(module.request_set_traced(npc_id, true).ok)
	_run(world, 400)
	var result: String = world.state_hash()
	assert_false(JSON.stringify(world.serialize()).contains("trace"), "O rastro não vai no save.")
	world.teardown()
	return result


func test_tracing_changes_nothing_in_the_world_the_hash_or_the_random_numbers() -> void:
	assert_eq(_hash_after(7, true), _hash_after(7, false), "Com ou sem rastro o mundo é o mesmo.")


func test_removing_or_loading_forgets_the_marks() -> void:
	var module: NpcModule = _module(0)
	var world: World = _world(module)
	var first: int = _spawn(module)
	var second: int = _spawn(module)
	assert_true(module.request_set_traced(first, true).ok)
	assert_true(module.request_set_traced(second, true).ok)
	assert_eq(module.debug_summary()["traced_npcs"], 2)
	assert_true(module.request_remove_npc(first).ok)
	assert_eq(module.debug_summary()["traced_npcs"], 1, "NPC removido deixa de ser rastreado.")
	var parsed: Variant = JSON.parse_string(JSON.stringify(module.serialize(), "", true, true))
	var saved: Dictionary = parsed
	assert_true(module.on_load(saved).ok)
	assert_eq(module.debug_summary()["traced_npcs"], 0, "As marcas não são salvas: carregar as apaga.")
	assert_eq(module.explain_decision(second).result.code, DecisionTracer.CODE_NOT_TRACED)
	world.teardown()
