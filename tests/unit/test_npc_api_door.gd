extends GutTest
## LW-085a: a porta `api/` do módulo `npc` para quem está fora dele (a ponte), sem janela (docs/modules/npc.md, "A porta `api/` e a fronteira com a ponte"): os códigos e o nível
## reexportados valem o mesmo que os originais (e os VALORES escritos à mão, para um alias errado não passar por igual a si mesmo), `peek_level_of` e `peek_s0_count` seguem o LOD, e as
## três visões (`NpcTraceView`, `NpcMemoryView`, `NpcRoutineView`) copiam os campos do que o módulo devolve, sem dividir objeto com ele. A conferência de que a ponte só cita a `api/`
## é a regra D do `tools/check_architecture` (`tests/test_check_architecture.sh`).

const WORLD_SEED: int = 3
const ACTOR_ID: int = 77
const FOCUS_M: Vector3 = Vector3(1000.0, 10.0, 500.0)
const NEAR_X_M: float = 1050.0
const FAR_X_M: float = 1300.0
const Z_M: float = 500.0
const UNKNOWN_NPC_ID: int = 999999
const TRACED_NPC_ID: int = 5
const TRACE_MINUTE: int = 725

var _runners: Array[SimulationRunner] = []


## Mundo de teste: o runner e o módulo `npc` montado à mão (nasce com corpos, como nos testes do LOD), com o LOD ligado pelos parâmetros reais.
class Rig:
	extends RefCounted

	var runner: SimulationRunner
	var module: NpcModule


func after_each() -> void:
	for runner: SimulationRunner in _runners:
		runner.finish()
	_runners.clear()


func _new_rig() -> Rig:
	var rig: Rig = Rig.new()
	rig.runner = SimulationRunner.new(WORLD_SEED)
	rig.module = NpcModule.new()
	var loaded: LodParamsLoader.LoadResult = LodParamsLoader.load_dir()
	assert_true(loaded.result.ok, loaded.result.message)
	assert_true(rig.module.lod.configure(loaded.params).ok)
	assert_true(rig.runner.register_module("npc", rig.module).ok)
	rig.runner.start_new_game()
	_runners.append(rig.runner)
	return rig


func _create(module: NpcModule, x_m: float) -> int:
	var spec: NpcSpec = NpcSpec.new()
	spec.name_key = "npc.name.villager"
	spec.x_cm = roundi(x_m * 100.0)
	spec.z_cm = roundi(Z_M * 100.0)
	var created: NpcModule.CreateResult = module.request_create_npc(spec)
	assert_true(created.result.ok, created.result.message)
	return created.npc_id


func test_the_reexported_codes_and_the_level_are_the_originals_with_the_same_values() -> void:
	assert_eq(NpcModule.CODE_NOT_IN_S0, NpcLod.CODE_NOT_IN_S0)
	assert_eq(NpcModule.CODE_NOT_IN_S0, "NPC_NOT_IN_S0")
	assert_eq(NpcModule.CODE_INVALID_POSITION, NpcLod.CODE_INVALID_POSITION)
	assert_eq(NpcModule.CODE_INVALID_POSITION, "NPC_INVALID_POSITION")
	assert_eq(NpcModule.CODE_DEAD, NpcTiers.CODE_DEAD)
	assert_eq(NpcModule.CODE_DEAD, "NPC_DEAD")
	assert_eq(NpcModule.CODE_RELATION_INVALID, RelationGraph.CODE_INVALID)
	assert_eq(NpcModule.CODE_RELATION_INVALID, "NPC_INVALID_RELATION")
	assert_eq(NpcModule.CODE_RELATION_NOT_ALLOWED, RelationGraph.CODE_NOT_ALLOWED)
	assert_eq(NpcModule.CODE_RELATION_NOT_ALLOWED, "NPC_RELATION_NOT_ALLOWED")
	assert_eq(NpcModule.LEVEL_S0, NpcLod.LEVEL_S0)
	assert_eq(NpcModule.LEVEL_S0, 0)


func test_the_level_and_the_s0_count_follow_the_lod() -> void:
	var rig: Rig = _new_rig()
	var near_id: int = _create(rig.module, NEAR_X_M)
	var far_id: int = _create(rig.module, FAR_X_M)
	assert_eq(rig.module.peek_s0_count(), 0, "Sem foco ninguém tem corpo.")
	assert_eq(rig.module.peek_level_of(near_id), NpcLod.LEVEL_S1)
	assert_true(rig.module.request_set_focus(ACTOR_ID, FOCUS_M).ok)
	rig.runner.step_once()
	assert_eq(rig.module.peek_level_of(near_id), NpcModule.LEVEL_S0, "O NPC a 50 m do foco ganhou corpo.")
	assert_eq(rig.module.peek_level_of(far_id), NpcLod.LEVEL_S1, "O NPC a 300 m segue sem corpo.")
	assert_eq(rig.module.peek_s0_count(), 1)
	assert_eq(rig.module.peek_level_of(near_id), rig.module.lod.level_of(near_id), "Mesmo valor do membro público.")
	assert_eq(rig.module.peek_s0_count(), rig.module.lod.s0_ids().size())


func test_an_unknown_npc_counts_as_s1_and_the_count_is_zero_without_bodies() -> void:
	var rig: Rig = _new_rig()
	assert_eq(rig.module.peek_level_of(UNKNOWN_NPC_ID), NpcLod.LEVEL_S1, "ID inexistente conta como S1, como `lod.level_of`.")
	assert_eq(rig.module.peek_s0_count(), 0)
	assert_true(rig.module.request_set_bodies_available(false).ok)
	_create(rig.module, NEAR_X_M)
	assert_true(rig.module.request_set_focus(ACTOR_ID, FOCUS_M).ok)
	rig.runner.step_once()
	assert_eq(rig.module.peek_s0_count(), 0, "Com os corpos indisponíveis o LOD fica inerte: ninguém em S0.")


func test_the_trace_view_copies_every_field_and_shares_nothing() -> void:
	var tracer: DecisionTracer = DecisionTracer.new()
	tracer.set_traced(TRACED_NPC_ID, true)
	var breakdown: UtilityScorer.ScoreBreakdown = UtilityScorer.ScoreBreakdown.new()
	breakdown.benefit = 60
	breakdown.personality = 3
	breakdown.time_cost = 4
	breakdown.distance_cost = 5
	breakdown.risk_cost = 6
	breakdown.inertia_bonus = 7
	breakdown.routine_bonus = 8
	breakdown.total = 55
	var candidates: Array[DecisionTracer.CandidateRecord] = [DecisionTracer.CandidateRecord.new("eat", "home_a1", breakdown, true, DecisionTracer.REASON_URGENT_NEED)]
	tracer.record(TRACED_NPC_ID, TRACE_MINUTE, PackedInt64Array([10, 20, 30]), candidates, "eat", "home_a1", DecisionTracer.REASON_URGENT_NEED)
	var view: NpcTraceView = NpcTraceView.of(tracer.explain(TRACED_NPC_ID))
	assert_true(view.result.ok, view.result.message)
	assert_eq(view.records.size(), 1)
	var record: NpcTraceView.Record = view.records[0]
	assert_eq([record.minute, record.chosen_action_id, record.chosen_place_id, record.reason], [TRACE_MINUTE, "eat", "home_a1", "URGENT_NEED"])
	assert_eq(record.need_values, PackedInt64Array([10, 20, 30]))
	assert_eq(record.candidates.size(), 1)
	var candidate: NpcTraceView.Candidate = record.candidates[0]
	assert_eq([candidate.action_id, candidate.place_id, candidate.is_current, candidate.source], ["eat", "home_a1", true, "URGENT_NEED"])
	assert_eq([candidate.benefit, candidate.personality, candidate.time_cost, candidate.distance_cost], [60, 3, 4, 5])
	assert_eq([candidate.risk_cost, candidate.inertia_bonus, candidate.routine_bonus, candidate.total], [6, 7, 8, 55])
	record.need_values[0] = 99
	candidate.total = 1
	var again: NpcTraceView = NpcTraceView.of(tracer.explain(TRACED_NPC_ID))
	assert_eq(again.records[0].need_values[0], 10, "Mexer na cópia não muda o rastro guardado.")
	assert_eq(again.records[0].candidates[0].total, 55)


func test_the_trace_view_keeps_the_failure_and_has_no_records() -> void:
	var tracer: DecisionTracer = DecisionTracer.new()
	var view: NpcTraceView = NpcTraceView.of(tracer.explain(TRACED_NPC_ID))
	assert_false(view.result.ok)
	assert_eq(view.result.code, DecisionTracer.CODE_NOT_TRACED, "O código do `npc` passa como está.")
	assert_eq(view.records.size(), 0)


func test_the_memory_view_copies_records_and_traits_and_shares_nothing() -> void:
	var record: MemoryRecord = MemoryRecord.new()
	record.kind = "conversation"
	record.actors = PackedInt64Array([4, 8])
	record.place_id = "square_a1"
	record.time = 900
	record.valence = 12
	record.salience = 70
	record.confidence = 90
	var stored_trait: NpcMemory.Trait = NpcMemory.Trait.new(4, -15, 640)
	var found: Array[MemoryRecord] = [record]
	var traits: Array[NpcMemory.Trait] = [stored_trait]
	var view: NpcMemoryView = NpcMemoryView.of(NpcModule.MemoriesQuery.new(Result.success(), found, traits))
	assert_true(view.result.ok)
	assert_eq(view.records.size(), 1)
	var entry: NpcMemoryView.Entry = view.records[0]
	assert_eq([entry.kind, entry.place_id, entry.source], ["conversation", "square_a1", MemoryRecord.SOURCE_WITNESSED])
	assert_eq([entry.time, entry.valence, entry.salience, entry.confidence], [900, 12, 70, 90])
	assert_eq(entry.actors, PackedInt64Array([4, 8]))
	assert_eq(view.traits.size(), 1)
	var memory_trait: NpcMemoryView.TraitEntry = view.traits[0]
	assert_eq([memory_trait.actor_id, memory_trait.valence, memory_trait.since], [4, -15, 640])
	entry.actors[0] = 99
	assert_eq(record.actors[0], 4, "Mexer na cópia não muda o registro de origem.")


func test_the_memory_view_keeps_the_failure_and_ignores_the_lists() -> void:
	var stray: Array[MemoryRecord] = [MemoryRecord.new()]
	var no_traits: Array[NpcMemory.Trait] = []
	var failed: Result = Result.failure(NpcModule.CODE_UNKNOWN, "NPC inexistente (teste).")
	var view: NpcMemoryView = NpcMemoryView.of(NpcModule.MemoriesQuery.new(failed, stray, no_traits))
	assert_false(view.result.ok)
	assert_eq(view.result.code, NpcModule.CODE_UNKNOWN)
	assert_eq(view.records.size(), 0, "Resposta que falhou não traz registros.")
	assert_eq(view.traits.size(), 0)


func test_the_routine_view_copies_the_action_and_the_failure() -> void:
	var found: NpcRoutineView = NpcRoutineView.of(RoutineTable.RoutineQuery.new(Result.success(), "work"))
	assert_true(found.result.ok)
	assert_eq(found.action_id, "work")
	var failed: NpcRoutineView = NpcRoutineView.of(RoutineTable.RoutineQuery.new(Result.failure(NpcModule.CODE_ROUTINE_NOT_CONFIGURED, "sem tabela (teste)."), ""))
	assert_false(failed.result.ok)
	assert_eq(failed.result.code, NpcModule.CODE_ROUTINE_NOT_CONFIGURED)
	assert_eq(failed.action_id, "")
