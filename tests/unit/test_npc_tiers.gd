extends GutTest
## LW-077: promoção e rebaixamento entre T1 (cidadão) e T2 (notável) (docs/modules/npc.md, seção 7), sem janela. `request_promote` e
## `request_demote` mudam SÓ o tier: identidade, ofício, rotina e ação em andamento ficam como estavam (o mundo com notáveis anda igual ao mundo
## sem eles, campo a campo, exceto o tier). Há um teto global `max_t2` de notáveis VIVOS: cheio, a promoção é recusada e ninguém é expulso; a
## morte e o rebaixamento liberam a vaga. O rebaixamento chama um ponto de extensão (`Definitions.on_demote`) ANTES de mudar o tier, testado aqui
## com um espião: memória e relações (LW-078, LW-079) ainda não existem. Mundo de teste montado à mão.

const VILLAGE: String = "village_a"
const HOME: String = "home_a1"
const WORK: String = "work_a1"
const NEED_IDS: Array[String] = ["hunger", "rest", "safety", "income", "social"]
const TRAIT_IDS: Array[String] = ["caution", "sociability", "ambition", "loyalty"]
const HOME_X_CM: int = 8400
const THINK_INTERVAL: int = 10
const NOTABLE: int = NpcState.TIER_NOTABLE
const NORMAL: int = NpcState.TIER_NORMAL
const DATA_DIR: String = "res://data"
const WORLD_DIR: String = "res://data/world"
const PARAMS_LABEL: String = "res://data/npc_params.json"
const PARAMS_ISSUE_CODE: String = "NPC_PARAMS_INVALID"
const REAL_LIMIT: int = 40


# ---------------------------------------------------------------------------------------------------- mundo de teste

## Espião do ponto de extensão do rebaixamento: guarda, para cada chamada, o ID e o tier que o NPC TINHA na hora da chamada.
class DemoteSpy:
	extends RefCounted

	var module: NpcModule
	var calls: Array = []

	func on_demote(npc_id: int) -> void:
		calls.append([npc_id, module.peek_npc(npc_id).tier])


## O jogo real (terreno, povoados e dados de verdade), com os 100 NPCs nascidos.
class RealGame:
	extends RefCounted

	var runner: SimulationRunner
	var modules: GameModules


func _need_defs() -> Array[NeedDef]:
	var defs: Array[NeedDef] = []
	for position: int in NEED_IDS.size():
		defs.append(NeedDef.new(NEED_IDS[position], position, 0, 0, 40, 65, 90))
	return defs


func _catalog() -> Array[ActionDef]:
	var work: ActionDef = ActionDef.new("work", 240, "work", 5, true)
	work.effects.append(ActionDef.ActionEffect.new("rest", 5))
	return [work, ActionDef.new("wait", 10, "", 0, true), ActionDef.new(ActionRunner.GO_TO_PLACE_ID, 0, "", 0, true)]


func _routine() -> RoutineTable:
	var occupations: Array[RoutineTable.OccupationDef] = [RoutineTable.OccupationDef.new("tester", "work")]
	var blocks: Array[RoutineTable.RoutineBlock] = [RoutineTable.RoutineBlock.new("t", "tester", 0, 24, "work")]
	return RoutineTable.new(occupations, blocks)


func _places() -> SettlementService:
	var settlements: Array[Settlement] = [Settlement.new(VILLAGE, "settlement.a", Vector3.ZERO)]
	var places: Array[Place] = [
		Place.new(HOME, VILLAGE, Place.KIND_HOME, Vector3(84.0, 0.0, 0.0), 8), Place.new(WORK, VILLAGE, Place.KIND_WORK, Vector3(184.0, 0.0, 0.0), 8),
	]
	return SettlementService.new(settlements, places)


func _params(max_t2: int) -> NpcParams:
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
	params.decision_margin = 0
	params.max_t2 = max_t2
	return params


## Módulo completo (decide e anda). `max_t2` 0 = sem teto. `spy` opcional: vira o `Definitions.on_demote`.
func _module(max_t2: int = 0, spy: DemoteSpy = null) -> NpcModule:
	var definitions: NpcModule.Definitions = NpcModule.Definitions.new()
	definitions.actions = _catalog()
	var traits: Array[TraitLoader.TraitDef] = []
	for position: int in TRAIT_IDS.size():
		traits.append(TraitLoader.TraitDef.new(TRAIT_IDS[position], position))
	definitions.traits = traits
	definitions.params = _params(max_t2)
	definitions.places = _places()
	if spy != null:
		definitions.on_demote = spy.on_demote
	var module: NpcModule = NpcModule.new(_need_defs(), _routine(), definitions)
	if spy != null:
		spy.module = module
	return module


func _world(module: NpcModule, world_seed: int = 3) -> World:
	var clock: SimClock = SimClock.new()
	var world: World = World.new(SimContext.new(clock, EventBus.new(clock), WorldRng.new(world_seed), IdGenerator.new()))
	assert_true(world.register_module("npc", module).ok)
	world.setup()
	world.post_setup()
	return world


## NPC em casa; com ofício "tester" segue a rotina de trabalho, sem ofício só espera.
func _spawn(module: NpcModule, occupation_id: String = "", tier: int = NORMAL) -> int:
	var spec: NpcSpec = NpcSpec.new()
	spec.name_key = "npc.name.villager"
	spec.tier = tier
	spec.occupation_id = occupation_id
	spec.settlement_id = VILLAGE
	spec.place_id = HOME
	spec.home_place_id = HOME
	spec.work_place_id = WORK
	spec.x_cm = HOME_X_CM
	var created: NpcModule.CreateResult = module.request_create_npc(spec)
	assert_true(created.result.ok, created.result.message)
	return created.npc_id


## Um minuto por vez, como o SimulationRunner: relógio, módulos e entrega dos eventos.
func _run(world: World, minutes: int) -> void:
	for _step: int in minutes:
		world.context.clock.advance_step()
		world.tick(1)
		world.context.events.dispatch()


func _entry(module: NpcModule, npc_id: int) -> Dictionary:
	var entries: Dictionary = module.serialize()["npcs"]
	var entry: Dictionary = entries[str(npc_id)]
	return entry


func _without_tier(entry: Dictionary) -> Dictionary:
	var copy: Dictionary = entry.duplicate(true)
	copy.erase("tier")
	return copy


## Marca o NPC como morto pelo caminho do save (a morte de verdade é do pensador; aqui só importa o estado).
func _mark_dead(module: NpcModule, npc_id: int) -> void:
	var saved: Dictionary = module.serialize()
	var entries: Dictionary = saved["npcs"]
	var entry: Dictionary = entries[str(npc_id)]
	entry["is_alive"] = false
	entry["death_cause"] = "hunger"
	entry["died_at"] = 1
	assert_true(module.on_load(saved).ok)


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


# ---------------------------------------------------------------------------------------------------- promover mantém tudo, só muda o tier

func test_promoting_changes_only_the_tier_and_the_world_goes_on_exactly_as_before() -> void:
	var control_module: NpcModule = _module(5)
	var control_world: World = _world(control_module)
	var promoted_module: NpcModule = _module(5)
	var promoted_world: World = _world(promoted_module)
	var ids: Array[int] = []
	for index: int in 3:
		ids.append(_spawn(control_module, "tester"))
		assert_eq(_spawn(promoted_module, "tester"), ids[index], "Os dois mundos dão os mesmos IDs.")
	_run(control_world, 100)
	_run(promoted_world, 100)
	var before: Dictionary = _entry(promoted_module, ids[1])
	assert_eq(before["action_id"], "work", "Promovido no meio do trabalho.")
	assert_true(promoted_module.request_promote(ids[1], NOTABLE).ok)
	var after: Dictionary = _entry(promoted_module, ids[1])
	assert_eq([before["tier"], after["tier"]], [NORMAL, NOTABLE])
	assert_eq(_without_tier(after), _without_tier(before), "Identidade, ofício, locais, ação, necessidades e traços: nada mudou além do tier.")
	_run(control_world, 700)
	_run(promoted_world, 700)
	for npc_id: int in ids:
		assert_eq(_without_tier(_entry(promoted_module, npc_id)), _without_tier(_entry(control_module, npc_id)), "NPC %d: a rotina seguiu igual com ou sem notável." % npc_id)
	assert_eq(promoted_module.peek_counts()[NpcModule.COUNT_TIER_NOTABLE], 1)
	assert_eq(control_module.peek_counts()[NpcModule.COUNT_TIER_NOTABLE], 0)
	assert_eq(promoted_module.validate().size(), 0, str(promoted_module.validate()))
	control_world.teardown()
	promoted_world.teardown()


# ---------------------------------------------------------------------------------------------------- o teto global

func test_the_limit_is_global_and_a_full_limit_refuses_without_expelling_anyone() -> void:
	var module: NpcModule = _module(2)
	var world: World = _world(module)
	var ids: Array[int] = []
	for _index: int in 4:
		ids.append(_spawn(module))
	assert_true(module.request_promote(ids[0], NOTABLE).ok)
	assert_true(module.request_promote(ids[1], NOTABLE).ok)
	var refused: Result = module.request_promote(ids[2], NOTABLE)
	assert_false(refused.ok)
	assert_eq(refused.code, NpcTiers.CODE_T2_LIMIT_REACHED)
	assert_string_contains(refused.message, "max_t2")
	assert_string_contains(refused.message, str(ids[2]))
	var tiers: Array[int] = []
	for npc_id: int in ids:
		tiers.append(module.peek_npc(npc_id).tier)
	assert_eq(tiers, [NOTABLE, NOTABLE, NORMAL, NORMAL], "Os dois notáveis continuam; o recusado e o outro continuam cidadãos.")
	assert_eq(module.request_promote(ids[3], NOTABLE).code, NpcTiers.CODE_T2_LIMIT_REACHED, "Continua cheio para qualquer outro.")
	assert_eq(module.validate().size(), 0, str(module.validate()))
	world.teardown()


func test_a_demotion_and_a_death_each_free_a_slot() -> void:
	var module: NpcModule = _module(1)
	var world: World = _world(module)
	var first: int = _spawn(module)
	var second: int = _spawn(module)
	assert_true(module.request_promote(first, NOTABLE).ok)
	assert_eq(module.request_promote(second, NOTABLE).code, NpcTiers.CODE_T2_LIMIT_REACHED)
	assert_true(module.request_demote(first, NORMAL).ok)
	assert_true(module.request_promote(second, NOTABLE).ok, "O rebaixamento liberou a vaga.")
	assert_eq(module.request_promote(first, NOTABLE).code, NpcTiers.CODE_T2_LIMIT_REACHED, "E agora quem ocupa a vaga é o outro.")
	_mark_dead(module, second)
	assert_eq(module.peek_npc(second).tier, NOTABLE, "O morto guarda o tier que tinha.")
	assert_true(module.request_promote(first, NOTABLE).ok, "A morte do notável liberou a vaga: o morto não conta.")
	assert_eq(module.validate().size(), 0, str(module.validate()))
	world.teardown()


func test_creating_a_notable_respects_the_limit_and_a_refusal_spends_no_id() -> void:
	var module: NpcModule = _module(1)
	var world: World = _world(module)
	var notable: int = _spawn(module, "", NOTABLE)
	var spec: NpcSpec = NpcSpec.new()
	spec.name_key = "npc.name.villager"
	spec.tier = NOTABLE
	spec.settlement_id = VILLAGE
	spec.x_cm = HOME_X_CM
	var refused: NpcModule.CreateResult = module.request_create_npc(spec)
	assert_eq(refused.result.code, NpcTiers.CODE_T2_LIMIT_REACHED)
	assert_eq(refused.npc_id, IdGenerator.NO_ID)
	spec.tier = NORMAL
	assert_eq(module.request_create_npc(spec).npc_id, notable + 1, "O pedido recusado não gastou ID.")
	var unlimited: NpcModule = _module(0)
	var unlimited_world: World = _world(unlimited)
	for _index: int in 3:
		_spawn(unlimited, "", NOTABLE)
	assert_eq(unlimited.peek_counts()[NpcModule.COUNT_TIER_NOTABLE], 3, "Teto 0 = sem teto configurado.")
	assert_eq(unlimited.validate().size(), 0, str(unlimited.validate()))
	world.teardown()
	unlimited_world.teardown()


func test_validate_flags_more_living_notables_than_the_limit_and_only_when_there_is_a_limit() -> void:
	var module: NpcModule = _module(2)
	var world: World = _world(module)
	var ids: Array[int] = []
	for _index: int in 3:
		ids.append(_spawn(module))
	var saved: Dictionary = module.serialize()
	var entries: Dictionary = saved["npcs"]
	for npc_id: int in ids:
		var entry: Dictionary = entries[str(npc_id)]
		entry["tier"] = NOTABLE
	assert_true(module.on_load(saved).ok, "O formato é aceito; a coerência é do validate().")
	assert_string_contains(str(module.validate()), "3 NPCs notáveis")
	assert_string_contains(str(module.validate()), "max_t2 2")
	_mark_dead(module, ids[0])
	assert_eq(module.validate().size(), 0, "Um notável morto não conta para o teto.")
	world.teardown()


# ---------------------------------------------------------------------------------------------------- o ponto de extensão do rebaixamento

func test_demoting_calls_the_extension_point_once_before_the_tier_changes() -> void:
	var spy: DemoteSpy = DemoteSpy.new()
	var module: NpcModule = _module(5, spy)
	var world: World = _world(module)
	var npc_id: int = _spawn(module, "tester")
	assert_true(module.request_promote(npc_id, NOTABLE).ok)
	assert_eq(spy.calls.size(), 0, "Promover não chama o ponto de extensão do rebaixamento.")
	assert_true(module.request_demote(npc_id, NORMAL).ok)
	assert_eq(spy.calls, [[npc_id, NOTABLE]], "Uma chamada, com o NPC ainda notável.")
	assert_eq(module.peek_npc(npc_id).tier, NORMAL, "Depois da chamada o tier mudou.")
	assert_true(module.request_demote(npc_id, NORMAL).ok, "Já é cidadão: nada a fazer.")
	assert_eq(spy.calls.size(), 1, "Rebaixar quem já é cidadão não chama de novo.")
	world.teardown()


func test_a_demotion_that_does_not_happen_never_reaches_the_extension_point() -> void:
	var spy: DemoteSpy = DemoteSpy.new()
	var module: NpcModule = _module(5, spy)
	var world: World = _world(module)
	var notable: int = _spawn(module, "", NOTABLE)
	var dead: int = _spawn(module, "", NOTABLE)
	_mark_dead(module, dead)
	assert_eq(module.request_demote(999, NORMAL).code, NpcModule.CODE_UNKNOWN)
	assert_eq(module.request_demote(notable, NOTABLE).code, NpcTiers.CODE_INVALID_TIER)
	assert_eq(module.request_demote(dead, NORMAL).code, NpcTiers.CODE_DEAD)
	assert_eq(spy.calls.size(), 0)
	assert_eq(module.peek_npc(notable).tier, NOTABLE)
	var without_hook: NpcModule = _module(5)
	var other_world: World = _world(without_hook)
	var plain: int = _spawn(without_hook, "", NOTABLE)
	assert_true(without_hook.request_demote(plain, NORMAL).ok, "Sem ponto de extensão o rebaixamento só muda o tier.")
	var no_definitions: NpcModule = NpcModule.new()
	var third_world: World = _world(no_definitions)
	var bare: int = _spawn(no_definitions, "", NOTABLE)
	assert_true(no_definitions.request_demote(bare, NORMAL).ok, "Módulo sem definições também rebaixa.")
	assert_true(no_definitions.request_promote(bare, NOTABLE).ok, "E promove, sem teto configurado.")
	world.teardown()
	other_world.teardown()
	third_world.teardown()


# ---------------------------------------------------------------------------------------------------- ida, volta e ida de novo

func test_promote_demote_promote_does_not_duplicate_or_lose_the_essential() -> void:
	var module: NpcModule = _module(3)
	var world: World = _world(module)
	var npc_id: int = _spawn(module, "tester")
	_run(world, 100)
	var original: Dictionary = _entry(module, npc_id)
	assert_true(module.request_promote(npc_id, NOTABLE).ok)
	var as_notable: Dictionary = _entry(module, npc_id)
	assert_true(module.request_demote(npc_id, NORMAL).ok)
	assert_eq(_entry(module, npc_id), original, "Voltou a ser exatamente o que era.")
	assert_true(module.request_promote(npc_id, NOTABLE).ok)
	assert_eq(_entry(module, npc_id), as_notable, "Promover de novo dá o mesmo notável de antes.")
	var counts: Dictionary = module.peek_counts()
	assert_eq([counts[NpcModule.COUNT_TOTAL], counts[NpcModule.COUNT_TIER_NOTABLE], counts[NpcModule.COUNT_TIER_NORMAL]], [1, 1, 0], "Nenhum NPC duplicado nem perdido.")
	assert_eq(module.serialize()["npcs"].size(), 1)
	assert_eq(_spawn(module), npc_id + 1, "Os IDs seguem sem reuso.")
	world.teardown()


func test_asking_for_the_tier_the_npc_already_has_succeeds_without_using_a_slot() -> void:
	var spy: DemoteSpy = DemoteSpy.new()
	var module: NpcModule = _module(1, spy)
	var world: World = _world(module)
	var notable: int = _spawn(module, "", NOTABLE)
	var citizen: int = _spawn(module)
	assert_true(module.request_promote(notable, NOTABLE).ok, "Já é notável: sucesso mesmo com o teto cheio, sem gastar vaga.")
	assert_eq(module.request_promote(citizen, NOTABLE).code, NpcTiers.CODE_T2_LIMIT_REACHED, "O teto continua cheio para o outro.")
	assert_true(module.request_demote(citizen, NORMAL).ok)
	assert_eq(spy.calls.size(), 0)
	assert_eq(module.peek_counts()[NpcModule.COUNT_TIER_NOTABLE], 1)
	world.teardown()


# ---------------------------------------------------------------------------------------------------- erros

func test_invalid_requests_are_refused_and_change_nothing() -> void:
	var module: NpcModule = _module(5)
	var world: World = _world(module)
	var citizen: int = _spawn(module)
	var notable: int = _spawn(module, "", NOTABLE)
	var dead: int = _spawn(module)
	_mark_dead(module, dead)
	var snapshot: Dictionary = module.serialize()
	assert_eq(module.request_promote(999, NOTABLE).code, NpcModule.CODE_UNKNOWN, "ID inexistente: falha tratada.")
	assert_string_contains(module.request_promote(999, NOTABLE).message, "999")
	assert_eq(module.request_demote(999, NORMAL).code, NpcModule.CODE_UNKNOWN)
	for wrong: int in [0, NORMAL, 3, -1]:
		assert_eq(module.request_promote(citizen, wrong).code, NpcTiers.CODE_INVALID_TIER, "Promover para o tier %d." % wrong)
	for wrong: int in [0, NOTABLE, 3, -1]:
		assert_eq(module.request_demote(notable, wrong).code, NpcTiers.CODE_INVALID_TIER, "Rebaixar para o tier %d." % wrong)
	assert_string_contains(module.request_promote(citizen, 3).message, "T2", "Não existe T3 nesta fase.")
	assert_eq(module.request_promote(dead, NOTABLE).code, NpcTiers.CODE_DEAD, "Morto não é promovido.")
	assert_eq(module.request_demote(dead, NORMAL).code, NpcTiers.CODE_DEAD)
	assert_eq(module.serialize(), snapshot, "Nada foi alterado por pedido recusado.")
	world.teardown()


# ---------------------------------------------------------------------------------------------------- save e determinismo

func _hash_of_a_busy_run(world_seed: int, save_at_minute: int) -> String:
	var module: NpcModule = _module(2)
	var active_world: World = _world(module, world_seed)
	var ids: Array[int] = []
	for _index: int in 4:
		ids.append(_spawn(module, "tester"))
	_run(active_world, 50)
	assert_true(module.request_promote(ids[0], NOTABLE).ok)
	assert_true(module.request_promote(ids[2], NOTABLE).ok)
	assert_eq(module.request_promote(ids[3], NOTABLE).code, NpcTiers.CODE_T2_LIMIT_REACHED)
	_run(active_world, 100)
	assert_true(module.request_demote(ids[2], NORMAL).ok)
	assert_true(module.request_promote(ids[3], NOTABLE).ok)
	var remaining: int = 400
	if save_at_minute > 0:
		_run(active_world, save_at_minute - 150)
		var parsed: Variant = JSON.parse_string(JSON.stringify(active_world.serialize(), "", true, true))
		var saved: Dictionary = parsed
		var other_module: NpcModule = _module(2)
		var other_world: World = _world(other_module, world_seed)
		var loaded: Result = other_world.on_load(saved)
		assert_true(loaded.ok, loaded.message)
		active_world.teardown()
		active_world = other_world
		remaining = 400 - (save_at_minute - 150)
	_run(active_world, remaining)
	var result: String = active_world.state_hash()
	active_world.teardown()
	return result


func test_the_tier_goes_into_the_save_and_the_same_seed_gives_the_same_world() -> void:
	var direct: String = _hash_of_a_busy_run(7, 0)
	assert_eq(_hash_of_a_busy_run(7, 0), direct, "Mesma semente, mesmo mundo com promoções e rebaixamentos.")
	assert_eq(_hash_of_a_busy_run(7, 260), direct, "Salvar e carregar no meio dá o mesmo mundo: o tier vai no save.")
	assert_ne(_hash_of_a_busy_run(8, 0), direct, "Controle: outra semente dá outro mundo.")


# ---------------------------------------------------------------------------------------------------- o dado e o mundo real

func _valid_params_record() -> Dictionary:
	return {
		"id": "default", "urgency_weight_comfortable": 0, "urgency_weight_attention": 1, "urgency_weight_urgent": 3, "urgency_weight_critical": 6,
		"time_cost_per_hour": 2, "distance_cost_per_100m": 2, "risk_cost_percent": 100, "inertia_bonus": 25, "routine_bonus": 40,
		"think_interval_min": 10, "max_thinks_per_step": 20, "decision_top_k": 3, "decision_margin": 15,
	}


func _load_records(records: Array[Dictionary]) -> NpcParamsLoader.LoadResult:
	var bundle: DataBundle = DataBundle.new()
	bundle.tables[NpcParamsLoader.PARAMS_TABLE] = records
	bundle.file_paths[NpcParamsLoader.PARAMS_TABLE] = PARAMS_LABEL
	DataValidator.new().validate(bundle, [NpcParamsLoader.build_schema()])
	return NpcParamsLoader.from_bundle(bundle)


func test_the_limit_comes_from_the_data_is_optional_and_is_checked_by_range_and_type() -> void:
	assert_eq(NpcParamsLoader.load_dir().params.max_t2, REAL_LIMIT, "O arquivo real tem o teto de 40 [HIP].")
	var absent: NpcParamsLoader.LoadResult = _load_records([_valid_params_record()])
	assert_true(absent.result.ok, absent.result.message)
	assert_eq(absent.params.max_t2, 0, "Sem o campo: sem teto configurado.")
	var record: Dictionary = _valid_params_record()
	record["max_t2"] = 7
	assert_eq(_load_records([record]).params.max_t2, 7)
	for bad: Variant in [-1, NpcParamsLoader.MAX_T2_LIMIT + 1, "quarenta", 1.5]:
		var invalid: Dictionary = _valid_params_record()
		invalid["max_t2"] = bad
		var loaded: NpcParamsLoader.LoadResult = _load_records([invalid])
		assert_false(loaded.result.ok, "max_t2 = %s deveria falhar." % str(bad))
		assert_eq(loaded.result.code, PARAMS_ISSUE_CODE)
		assert_string_contains(loaded.result.message, "max_t2")
		assert_string_contains(loaded.result.message, PARAMS_LABEL)


func test_the_real_world_takes_forty_notables_refuses_the_next_and_lives_on_exactly_as_before() -> void:
	var with_notables: RealGame = _real_game()
	var control: RealGame = _real_game()
	var ids: Array[int] = with_notables.modules.npc.peek_npc_ids()
	assert_eq(ids.size(), 132)
	for index: int in REAL_LIMIT:
		var promoted: Result = with_notables.modules.npc.request_promote(ids[index], NOTABLE)
		assert_true(promoted.ok, promoted.message)
	var refused: Result = with_notables.modules.npc.request_promote(ids[REAL_LIMIT], NOTABLE)
	assert_eq(refused.code, NpcTiers.CODE_T2_LIMIT_REACHED)
	assert_eq(with_notables.modules.npc.peek_counts()[NpcModule.COUNT_TIER_NOTABLE], REAL_LIMIT)
	assert_eq(with_notables.modules.npc.peek_npc(ids[REAL_LIMIT]).tier, NORMAL, "Ninguém foi expulso e o recusado segue cidadão.")
	with_notables.runner.run_steps(1440)
	control.runner.run_steps(1440)
	var entries_with: Dictionary = with_notables.modules.npc.serialize()["npcs"]
	var entries_control: Dictionary = control.modules.npc.serialize()["npcs"]
	assert_eq(entries_with.size(), 132)
	for key: Variant in entries_control:
		var with_entry: Dictionary = entries_with[key]
		var control_entry: Dictionary = entries_control[key]
		assert_eq(_without_tier(with_entry), _without_tier(control_entry), "NPC %s: um dia depois, igual com ou sem notáveis." % str(key))
	assert_eq(with_notables.runner.world.validate().size(), 0, str(with_notables.runner.world.validate()))
	with_notables.runner.finish()
	control.runner.finish()
