extends GutTest
## LW-063: fila de pensamento e teto por passo (docs/modules/npc.md, seção 5; linha I5 do backlog), sem janela. Aqui só o que é da FILA: quem
## está na vez (`NpcThinker.due_ids`), a fase fixa por NPC, o teto `max_thinks_per_step` com o excedente esperando (o mais antigo primeiro,
## sem deixar ninguém para trás), o máximo de pensamentos por passo com 100 NPCs e a proteção contra id desconhecido e NPC morto. O fluxo
## de decisão em si está em test_decision_flow.gd. Mundo mínimo (NPCs sem ofício e sem necessidade só esperam), repetido aqui de propósito:
## um arquivo de apoio compartilhado passaria o teto de arquivos .gd da tarefa.

const VILLAGE: String = "village_a"
const HOME: String = "home_a1"
const NEED_IDS: Array[String] = ["hunger", "rest", "safety", "income", "social"]
const TRAIT_IDS: Array[String] = ["caution", "sociability", "ambition", "loyalty"]
const INTERVAL: int = 10
const DEFAULT_CAP: int = 25
## Quantos NPCs o teste do máximo por passo usa, quantos passos ele roda (um dia de jogo) e quantos NPCs há em cada fase (100 / intervalo 10).
const CROWD: int = 100
const ONE_DAY_STEPS: int = 1440
const NPCS_PER_PHASE: int = 10


func _need_defs() -> Array[NeedDef]:
	var defs: Array[NeedDef] = []
	for position: int in NEED_IDS.size():
		defs.append(NeedDef.new(NEED_IDS[position], position, 0, 0, 40, 65, 90))
	return defs


func _definitions(interval: int, cap: int) -> NpcModule.Definitions:
	var definitions: NpcModule.Definitions = NpcModule.Definitions.new()
	definitions.actions = [ActionDef.new("wait", 10, "", 0, true), ActionDef.new(ActionRunner.GO_TO_PLACE_ID, 0, "", 0, true)]
	var traits: Array[TraitLoader.TraitDef] = []
	for position: int in TRAIT_IDS.size():
		traits.append(TraitLoader.TraitDef.new(TRAIT_IDS[position], position))
	definitions.traits = traits
	var params: NpcParams = NpcParams.new()
	params.think_interval_min = interval
	params.max_thinks_per_step = cap
	params.decision_top_k = 1
	definitions.params = params
	var settlements: Array[Settlement] = [Settlement.new(VILLAGE, "settlement.a", Vector3.ZERO)]
	var places: Array[Place] = [Place.new(HOME, VILLAGE, Place.KIND_HOME, Vector3(84.0, 0.0, 0.0), 5)]
	definitions.places = SettlementService.new(settlements, places)
	return definitions


func _module(interval: int = INTERVAL, cap: int = DEFAULT_CAP) -> NpcModule:
	var occupations: Array[RoutineTable.OccupationDef] = []
	var blocks: Array[RoutineTable.RoutineBlock] = []
	return NpcModule.new(_need_defs(), RoutineTable.new(occupations, blocks), _definitions(interval, cap))


func _world(module: NpcModule) -> World:
	var clock: SimClock = SimClock.new()
	var world: World = World.new(SimContext.new(clock, EventBus.new(clock), WorldRng.new(3), IdGenerator.new()))
	assert_true(world.register_module("npc", module).ok)
	world.setup()
	world.post_setup()
	return world


func _spawn(module: NpcModule) -> int:
	var spec: NpcSpec = NpcSpec.new()
	spec.name_key = "npc.name.villager"
	spec.settlement_id = VILLAGE
	var created: NpcModule.CreateResult = module.request_create_npc(spec)
	assert_true(created.result.ok, created.result.message)
	return created.npc_id


func _spawn_many(module: NpcModule, count: int) -> Array[int]:
	var ids: Array[int] = []
	for _index: int in count:
		ids.append(_spawn(module))
	return ids


## Avança o relógio um minuto por vez e roda os módulos (como o SimulationRunner faz a cada passo).
func _run(world: World, minutes: int) -> void:
	for _step: int in minutes:
		world.context.clock.advance_step()
		world.tick(1)


## Lista de inteiros tipada a partir de um literal (para comparar com o que a simulação devolve).
func _ints(values: Array[int]) -> Array[int]:
	return values


func _next_times(module: NpcModule, ids: Array[int]) -> Array[int]:
	var times: Array[int] = []
	for npc_id: int in ids:
		times.append(module.peek_npc(npc_id).next_think_time)
	return times


func _state(npc_id: int, next_think_time: int, is_alive: bool = true) -> NpcState:
	var state: NpcState = NpcState.new(npc_id)
	state.next_think_time = next_think_time
	state.is_alive = is_alive
	return state


# ---------------------------------------------------------------------------------------------------- fase fixa

func test_each_npc_gets_a_phase_from_its_id_and_never_thinks_in_the_creation_minute() -> void:
	var module: NpcModule = _module()
	var world: World = _world(module)
	for npc_id: int in _spawn_many(module, 25):
		assert_eq(module.peek_npc(npc_id).next_think_time, 1 + npc_id % INTERVAL, "NPC %d: fase fixa (1 + id mod intervalo)." % npc_id)
	for _step: int in 37:
		world.context.clock.advance_step()
	var later: int = _spawn(module)
	assert_eq(module.peek_npc(later).next_think_time, 37 + 1 + later % INTERVAL, "A fase vale também para NPC criado depois.")
	world.teardown()


func test_without_definitions_the_first_think_is_the_creation_minute_and_the_tick_does_nothing() -> void:
	var module: NpcModule = NpcModule.new()
	var world: World = _world(module)
	for _step: int in 5:
		world.context.clock.advance_step()
	var npc_id: int = _spawn(module)
	assert_eq(module.peek_npc(npc_id).next_think_time, 5)
	var before: Dictionary = module.serialize()
	_run(world, 20)
	assert_eq(module.serialize(), before, "Sem definições o módulo só guarda estado.")
	assert_false(module.debug_summary()["decision_enabled"])
	world.teardown()


func test_a_negative_next_think_time_is_reported_by_validate() -> void:
	var module: NpcModule = _module()
	var world: World = _world(module)
	var npc_id: int = _spawn(module)
	assert_eq(module.validate().size(), 0)
	var saved: Dictionary = module.serialize()
	var entry: Dictionary = saved["npcs"][str(npc_id)]
	entry["next_think_time"] = -3
	assert_true(module.on_load(saved).ok, "O formato é aceito; a coerência é do validate().")
	var problems: Array[String] = module.validate()
	assert_eq(problems.size(), 1, str(problems))
	assert_string_contains(problems[0], "next_think_time -3 negativo")
	world.teardown()


# ---------------------------------------------------------------------------------------------------- quem está na vez

func test_due_ids_orders_by_age_then_id_and_skips_the_dead_and_those_not_due_yet() -> void:
	var table: Array[Array] = [[5, 10], [3, 4], [9, 4], [1, 20], [7, 0], [2, 4]]
	var states: Dictionary[int, NpcState] = {}
	for row: Array in table:
		states[row[0]] = _state(row[0], row[1])
	states[6] = _state(6, 0, false)
	states[8] = _state(8, 50)
	assert_eq(NpcThinker.due_ids(states, 12, 100), _ints([7, 2, 3, 9, 5]), "Mais antigo primeiro; empate pelo menor id; sem o morto (6), o que só pensa no 20 (1) e o do 50 (8).")
	assert_eq(NpcThinker.due_ids(states, 12, 3), _ints([7, 2, 3]), "O teto corta no fim da fila.")
	assert_eq(NpcThinker.due_ids(states, 12, 0), _ints([]))
	assert_eq(NpcThinker.due_ids(states, 12, -4), _ints([]), "Teto negativo não derruba nada: ninguém pensa.")
	assert_eq(NpcThinker.due_ids(states, 3, 100), _ints([7]), "Só quem chegou no seu minuto.")
	assert_eq(NpcThinker.due_ids(states, 20, 100), _ints([7, 2, 3, 9, 5, 1]), "No minuto 20 entra o que pensava no 20.")
	var reversed_states: Dictionary[int, NpcState] = {}
	for npc_id: int in _ints([8, 6, 2, 7, 1, 9, 3, 5]):
		reversed_states[npc_id] = states[npc_id]
	assert_eq(NpcThinker.due_ids(reversed_states, 12, 100), _ints([7, 2, 3, 9, 5]), "A ordem de inserção na tabela não conta.")


func test_thinking_for_an_unknown_or_dead_npc_changes_nothing() -> void:
	var states: Dictionary[int, NpcState] = {}
	var dead: NpcState = _state(5, 7, false)
	states[5] = dead
	var no_needs: Array[NeedDef] = []
	var no_actions: Array[ActionDef] = []
	var thinker: NpcThinker = NpcThinker.new(null, states, null, null, null, null, null, null, no_needs, no_actions, null, Callable())
	var before: Dictionary = dead.to_dict()
	thinker.think(5, 100)
	thinker.think(999, 100)
	assert_eq(dead.to_dict(), before, "O morto não foi tocado.")
	assert_eq(states.size(), 1, "O id desconhecido não criou registro.")


# ---------------------------------------------------------------------------------------------------- teto por passo

func test_the_cap_defers_the_excess_and_the_oldest_waiting_goes_first() -> void:
	var module: NpcModule = _module(1, 3)
	var world: World = _world(module)
	var ids: Array[int] = _spawn_many(module, 8)
	assert_eq(_next_times(module, ids), _ints([1, 1, 1, 1, 1, 1, 1, 1]), "Intervalo 1: todos na mesma fase, todos na vez no minuto 1.")
	_run(world, 1)
	assert_eq(_next_times(module, ids), _ints([2, 2, 2, 1, 1, 1, 1, 1]), "Passo 1: pensam os 3 de menor id; os outros 5 esperam.")
	assert_eq(module.debug_summary()["thinks_last_step"], 3)
	_run(world, 1)
	assert_eq(_next_times(module, ids), _ints([2, 2, 2, 3, 3, 3, 1, 1]), "Passo 2: os que esperam desde o minuto 1 passam na frente dos que pensaram no 1.")
	_run(world, 1)
	assert_eq(_next_times(module, ids), _ints([4, 2, 2, 3, 3, 3, 4, 4]), "Passo 3: os 2 que ainda esperavam e, em seguida, o mais antigo dos outros.")
	var summary: Dictionary = module.debug_summary()
	assert_eq([summary["thinks_last_step"], summary["max_thinks_in_a_step"]], [3, 3], "Nunca mais que o teto.")
	assert_true(summary["decision_enabled"])
	world.teardown()


func test_with_a_cap_below_the_demand_nobody_is_left_behind() -> void:
	var cap: int = 7
	var module: NpcModule = _module(INTERVAL, cap)
	var world: World = _world(module)
	var ids: Array[int] = _spawn_many(module, CROWD)
	_run(world, 300)
	assert_eq(module.debug_summary()["max_thinks_in_a_step"], cap, "A demanda (10 por passo) passa do teto (7): o teto é o que vale.")
	var times: Array[int] = _next_times(module, ids)
	var spread: int = times.max() - times.min()
	assert_true(spread <= 15, "Fila em rodízio: os agendamentos ficam numa janela de ceil(100 / 7) = 15 minutos, e não se espalham (veio %d)." % spread)
	assert_eq(module.validate().size(), 0)
	world.teardown()


func test_with_100_npcs_the_busiest_step_has_one_phase_group_and_the_phase_never_drifts() -> void:
	var module: NpcModule = _module(INTERVAL, DEFAULT_CAP)
	var world: World = _world(module)
	var ids: Array[int] = _spawn_many(module, CROWD)
	for step: int in ONE_DAY_STEPS:
		_run(world, 1)
		if step == 0:
			assert_eq(module.debug_summary()["thinks_last_step"], NPCS_PER_PHASE, "Primeiro passo: só um grupo de fase.")
	var summary: Dictionary = module.debug_summary()
	assert_eq(summary["max_thinks_in_a_step"], NPCS_PER_PHASE, "Em 1 dia o passo mais cheio teve 10 pensamentos (100 NPCs / intervalo 10), bem abaixo do teto %d." % DEFAULT_CAP)
	assert_true(summary["max_thinks_in_a_step"] <= DEFAULT_CAP)
	for npc_id: int in ids:
		assert_eq(module.peek_npc(npc_id).next_think_time % INTERVAL, (1 + npc_id) % INTERVAL, "NPC %d manteve a fase." % npc_id)
	assert_eq(module.validate().size(), 0)
	world.teardown()
