extends GutTest
## LW-071 (SP2, DESCARTÁVEL): testa sem janela o mundo do spike, os corpos, o pool, as invariantes, o detector de teleporte, as políticas
## de velocidade e as navegações, com os dados REAIS (terreno, locais, catálogo, LOD, tempo limite de 30 min). Roda no tools/check_all
## (tools/run_tests varre tests/soak). Um passo do relógio = 1 minuto = 1250 ms reais a 1x. Contas da P2 à mão (relatório 0009):
## segundos que faltam = minutos que faltam x 1,25 / velocidade; velocidade = distância / segundos, entre 0,8 x vel. e 7 x vel.

const MS_PER_STEP: int = 1250
const PHYSICS_DELTA: float = 1.0 / 60.0
const CENTER_A: Vector3 = Vector3(320.0, 0.0, 540.0)
const CENTER_B: Vector3 = Vector3(800.0, 0.0, 660.0)
const FOCUS_A: int = 1
const FOCUS_B: int = 2
const CYCLES: int = 20

var _terrain: TerrainData
var _worlds: Array[Sp2World] = []


func before_all() -> void:
	var loaded: TerrainLoader.LoadResult = TerrainLoader.load_dir(Sp2World.WORLD_DIR)
	assert_true(loaded.result.ok, loaded.result.message)
	_terrain = loaded.terrain


func after_each() -> void:
	for world: Sp2World in _worlds:
		world.finish()
	_worlds.clear()


func _world(max_s0: int = Sp2Constants.LOAD_TEST_MAX_S0) -> Sp2World:
	var world: Sp2World = Sp2World.new(_terrain, max_s0)
	assert_eq(world.problem, "", "O mundo do spike deveria montar com os dados reais.")
	_worlds.append(world)
	return world


func _embodiment(world: Sp2World) -> Sp2Embodiment:
	var root: Node3D = Node3D.new()
	add_child_autofree(root)
	var embodied: Sp2Embodiment = Sp2Embodiment.new(world, root)
	embodied.checker.is_verbose = false
	return embodied


## `minutes` passos com o diretor; depois de cada passo, trocas de corpo, Intents, alguns quadros de física e as invariantes.
func _run(world: Sp2World, embodied: Sp2Embodiment, minutes: int, physics_frames: int = 10) -> void:
	for _minute: int in minutes:
		world.advance(MS_PER_STEP, false, 1)
		embodied.apply_lod_changes(world.take_changes())
		embodied.sync_intents(1)
		for _frame: int in physics_frames:
			embodied.physics_step(PHYSICS_DELTA, 1, false)
		embodied.check_invariants()
		assert_eq(embodied.pool.active_count(), world.module.lod.s0_ids().size(), "Corpos ativos devem ser os NPCs em S0 em todo passo.")


func test_population_is_one_hundred_from_real_places() -> void:
	var world: Sp2World = _world()
	assert_eq(world.module.peek_npc_ids().size(), 100)
	var in_b: int = 0
	for npc_id: int in world.module.peek_npc_ids():
		in_b += 1 if world.module.peek_npc(npc_id).settlement_id == Sp2Constants.SETTLEMENT_B else 0
	assert_eq(in_b, 40, "60 em A (12 casas x 5) e 40 em B (8 casas x 5).")


## (a) e (b): 20 ciclos de entrada e saída dos 100 NPCs; zero violações; o pool não cria corpo depois do aquecimento nem vaza nó.
func test_twenty_cycles_without_duplicates_orphans_or_teleports() -> void:
	var world: Sp2World = _world()
	var embodied: Sp2Embodiment = _embodiment(world)
	var created_after_warmup: int = -1
	var nodes_after_warmup: int = -1
	for cycle: int in CYCLES:
		world.module.request_set_focus(FOCUS_A, CENTER_A)
		world.module.request_set_focus(FOCUS_B, CENTER_B)
		_run(world, embodied, 3)
		assert_eq(world.module.lod.s0_ids().size(), 100, "Com um foco em cada povoado, os 100 ficam em S0 (ciclo %d)." % cycle)
		world.module.request_clear_focus(FOCUS_A)
		world.module.request_clear_focus(FOCUS_B)
		_run(world, embodied, 2)
		assert_eq(embodied.pool.active_count(), 0, "Sem foco, nenhum corpo ativo (ciclo %d)." % cycle)
		if cycle == 0:
			created_after_warmup = embodied.pool.created
			nodes_after_warmup = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	assert_eq(embodied.checker.total_violations(), 0, embodied.checker.summary())
	assert_eq(embodied.pool.duplicate_requests, 0)
	assert_eq(embodied.pool.created, created_after_warmup, "Depois do aquecimento, nenhum corpo novo: " + embodied.pool.summary())
	assert_eq(int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)), nodes_after_warmup, "Sem vazamento de nós.")
	assert_eq(embodied.pool.lost_bodies(), 0)
	assert_gt(embodied.pool.taken, 100 * (CYCLES - 1), "Cada ciclo retira e devolve os 100.")


## (c) o detector acusa um salto e ignora o nascimento e a devolução declarados.
func test_teleport_detector() -> void:
	var checker: Sp2Checker = Sp2Checker.new()
	checker.is_verbose = false
	checker.on_spawn(7, Vector3(10.0, 0.0, 10.0), Vector2i(1000, 1000), 0)
	checker.on_moved(7, Vector3(10.05, 0.0, 10.0), PHYSICS_DELTA, 4.0, 0)
	assert_eq(checker.teleports, 0, "0,05 m num quadro a 4 m/s cabe no limite (4 x 1/60 x 1,5 + 0,05 = 0,15 m).")
	checker.on_moved(7, Vector3(10.30, 0.0, 10.0), PHYSICS_DELTA, 4.0, 0)
	assert_eq(checker.teleports, 1, "0,25 m num quadro passa do limite de 0,15 m.")
	var body: Sp2Body = Sp2Body.new()
	add_child_autofree(body)
	checker.on_return(7, body, Vector2i.ZERO, 0)
	checker.on_spawn(7, Vector3(500.0, 0.0, 500.0), Vector2i(50000, 50000), 0)
	checker.on_moved(7, Vector3(500.0, 0.0, 500.0), PHYSICS_DELTA, 4.0, 0)
	assert_eq(checker.teleports, 1, "Devolver e nascer longe não é teleporte.")
	assert_eq(checker.spawn_mismatches, 0)


## (d) contas à mão das políticas.
func test_speed_policies_by_hand() -> void:
	var p1: Sp2SpeedPolicy.Policy = Sp2SpeedPolicy.Policy.P1_NATURAL
	var p2: Sp2SpeedPolicy.Policy = Sp2SpeedPolicy.Policy.P2_FROM_CLOCK
	assert_almost_eq(Sp2SpeedPolicy.speed_mps(p1, 50.0, 1.0, 1, false), 4.0, 0.0001, "P1 a 1x: 4 m/s.")
	assert_almost_eq(Sp2SpeedPolicy.speed_mps(p1, 50.0, 1.0, 8, false), 32.0, 0.0001, "P1 a 8x: 4 x 8 = 32 m/s.")
	assert_almost_eq(Sp2SpeedPolicy.speed_mps(p2, 10.0, 8.0, 1, false), 1.0, 0.0001, "P2 a 1x: 10 m / (8 x 1,25 s) = 1 m/s.")
	assert_almost_eq(Sp2SpeedPolicy.speed_mps(p2, 10.0, 8.0, 8, false), 8.0, 0.0001, "P2 a 8x: 10 m / (8 x 1,25 / 8 s) = 8 m/s.")
	assert_almost_eq(Sp2SpeedPolicy.speed_mps(p2, 100.0, 2.0, 1, false), 7.0, 0.0001, "P2 com teto: 100 m / 2,5 s = 40 m/s, teto 7 m/s.")
	assert_true(Sp2SpeedPolicy.is_ceiling_short(100.0, 2.0, 1), "100 m > 7 m/s x 2,5 s = 17,5 m: chega atrasado.")
	assert_false(Sp2SpeedPolicy.is_ceiling_short(10.0, 8.0, 1), "10 m < 7 x 10 = 70 m: chega a tempo.")
	assert_almost_eq(Sp2SpeedPolicy.speed_mps(p2, 1.0, 10.0, 1, false), 0.8, 0.0001, "P2 com piso: 1 m / 12,5 s = 0,08, piso 0,8 m/s.")
	assert_almost_eq(Sp2SpeedPolicy.speed_mps(p2, 10.0, 0.0, 2, false), 14.0, 0.0001, "P2 atrasada: teto x velocidade = 7 x 2.")
	assert_eq(Sp2SpeedPolicy.speed_mps(p1, 50.0, 1.0, 4, true), 0.0, "Pausa: P1 parado.")
	assert_eq(Sp2SpeedPolicy.speed_mps(p2, 50.0, 1.0, 4, true), 0.0, "Pausa: P2 parado.")


## (e) N1 segue a altura do terreno real e recusa o morro íngreme da LW-047A; N2 contorna e diz "sem caminho" quando não há.
func test_navigation_candidates() -> void:
	var nav: Sp2Nav = Sp2Nav.new(_terrain)
	var village: PackedVector2Array = nav.straight_route(Vector2(285.0, 542.0), Vector2(355.0, 570.0))
	assert_eq(village.size(), 1, "r1 no povoado A: trecho reto aceito.")
	var body: Sp2Body = Sp2Body.new()
	add_child_autofree(body)
	body.position = Vector3(285.0, nav.height_m(Vector2(285.0, 542.0)), 542.0)
	body.path = village
	body.walk(20.0, nav.height_m)
	assert_almost_eq(body.position.y, nav.height_m(body.flat_position()), 0.0001, "O corpo fica na altura do terreno real.")
	var steep_from: Vector2 = Vector2(130.0, 469.0)
	var steep_to: Vector2 = Vector2(200.0, 469.0)
	assert_eq(nav.straight_route(steep_from, steep_to).size(), 0, "r3: N1 recusa o lado de cerca de 50 graus.")
	var around: PackedVector2Array = nav.grid_route(steep_from, steep_to)
	assert_gt(around.size(), 1, "r3: N2 acha caminho em volta do morro.")
	assert_eq(around[around.size() - 1], steep_to)
	for point: Vector2 in around.slice(0, around.size() - 1):
		assert_false(nav.is_cell_blocked(Vector2i((point / Sp2Constants.N2_CELL_M).floor())), "Nenhum ponto da N2 em célula bloqueada.")
	var blocked_cell: Vector2i = _first_blocked_cell(nav, Vector2i(37, 110), Vector2i(48, 125))
	assert_ne(blocked_cell, Vector2i(-1, -1), "Há célula bloqueada no morro.")
	var inside: Vector2 = (Vector2(blocked_cell) + Vector2(0.5, 0.5)) * Sp2Constants.N2_CELL_M
	assert_eq(nav.grid_route(steep_from, inside).size(), 0, "Destino bloqueado: sem caminho.")


func _first_blocked_cell(nav: Sp2Nav, low: Vector2i, high: Vector2i) -> Vector2i:
	for cz: int in range(low.y, high.y):
		for cx: int in range(low.x, high.x):
			if nav.is_cell_blocked(Vector2i(cx, cz)):
				return Vector2i(cx, cz)
	return Vector2i(-1, -1)


## Primeiro NPC do povoado A em S0 com um foco só, sem diretor (o teste começa as ações à mão).
func _s0_npc(world: Sp2World, index: int = 0) -> int:
	world.module.request_set_focus(FOCUS_A, CENTER_A)
	world.runner.step_once()
	var npc_id: int = world.module.peek_npc_ids()[index]
	assert_eq(world.module.lod.level_of(npc_id), NpcLod.LEVEL_S0)
	return npc_id


## (f) resultado com action_serial velho é descartado e contado sem mudar o NPC; Intent vencido cancela a ação sem efeito.
func test_stale_result_and_timeout() -> void:
	var world: Sp2World = _world()
	var npc_id: int = _s0_npc(world)
	var body_m: Vector3 = Vector3(285.0, 0.0, 542.0)
	assert_true(world.module.intents.begin_embodied(npc_id, "wait", "", world.now()).ok)
	var first_serial: int = world.module.peek_npc(npc_id).action_serial
	assert_true(world.module.request_report_npc_result(NpcActionResult.new(npc_id, first_serial, NpcActionResult.Outcome.DONE, body_m)).ok, "A primeira ação termina pelo corpo.")
	assert_true(world.module.intents.begin_embodied(npc_id, "talk", "a_social_01", world.now()).ok)
	var before: NpcModule.NpcQuery = world.module.peek_npc(npc_id)
	var stale: Result = world.module.request_report_npc_result(NpcActionResult.new(npc_id, first_serial, NpcActionResult.Outcome.DONE, body_m))
	assert_eq(stale.code, NpcIntentBoard.CODE_STALE_RESULT)
	assert_eq(world.intent_counters()["discarded_results"], 1)
	var after: NpcModule.NpcQuery = world.module.peek_npc(npc_id)
	assert_eq(after.action_id, "talk", "O NPC não mudou.")
	assert_eq(after.need_values, before.need_values)
	var ends_at: int = before.action_ends_at
	while world.now() < ends_at + 30:
		world.runner.step_once()
	var expired: NpcModule.NpcQuery = world.module.peek_npc(npc_id)
	assert_eq(expired.action_id, "", "Tempo limite: a ação foi cancelada.")
	assert_eq(world.intent_counters()["timed_out_intents"], 1)
	assert_gt(expired.need_values[4], before.need_values[4] - 30, "Sem o efeito de talk (-30 de convívio).")


## (g) NPC que sai de S0 no meio da caminhada continua em modo abstrato; NPC removido com corpo ativo devolve o corpo.
func test_leaving_s0_mid_walk_and_removal() -> void:
	var world: Sp2World = _world()
	var embodied: Sp2Embodiment = _embodiment(world)
	var npc_id: int = _s0_npc(world)
	embodied.apply_lod_changes(world.take_changes())
	assert_true(world.module.intents.begin_embodied(npc_id, ActionRunner.GO_TO_PLACE_ID, "b_social_01", world.now()).ok)
	embodied.sync_intents(1)
	for _frame: int in 120:
		embodied.physics_step(PHYSICS_DELTA, 1, false)
	var walked_to: Vector3 = embodied.pool.body_of(npc_id).position
	world.module.request_clear_focus(FOCUS_A)
	world.runner.step_once()
	embodied.apply_lod_changes(world.take_changes())
	var outside: NpcModule.NpcQuery = world.module.peek_npc(npc_id)
	assert_eq(outside.action_id, ActionRunner.GO_TO_PLACE_ID, "A caminhada continua (abstrata).")
	assert_eq(embodied.pool.active_count(), 0, "Sem foco, o corpo voltou ao pool: " + embodied.pool.summary())
	assert_almost_eq(float(outside.x_cm) / 100.0, walked_to.x, 0.5, "A posição lógica é a do último relato do corpo.")
	while not world.module.peek_npc(npc_id).action_id.is_empty():
		world.runner.step_once()
		world.actions.advance(npc_id, world.now())
	assert_eq(world.module.peek_npc(npc_id).place_id, "b_social_01", "Chegou pelo runner abstrato, sem perder a ação.")
	var other: int = _s0_npc(world, 1)
	embodied.apply_lod_changes(world.take_changes())
	assert_not_null(embodied.pool.body_of(other))
	assert_true(world.module.request_remove_npc(other).ok)
	world.runner.step_once()
	embodied.apply_lod_changes(world.take_changes())
	assert_null(embodied.pool.body_of(other), "NPC removido devolve o corpo.")
	embodied.check_invariants()
	assert_eq(embodied.checker.total_violations(), 0, embodied.checker.summary())


## (h) mesma sequência, mesmo resultado, duas vezes: hash do mundo e contadores.
func test_determinism() -> void:
	var first: String = _scripted_run()
	var second: String = _scripted_run()
	assert_eq(first, second)


func _scripted_run() -> String:
	var world: Sp2World = _world()
	var embodied: Sp2Embodiment = _embodiment(world)
	world.module.request_set_focus(FOCUS_A, CENTER_A)
	_run(world, embodied, 40)
	world.module.request_clear_focus(FOCUS_A)
	_run(world, embodied, 5)
	return "%s | %s | %d %d %d" % [world.runner.world.state_hash(), str(world.intent_counters()), embodied.arrived, embodied.done, embodied.blocked]
