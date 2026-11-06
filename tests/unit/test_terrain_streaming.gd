extends GutTest
## LW-040: TerrainStreaming (função pura). Os valores esperados estão ESCRITOS À MÃO: raio de carga 384 m, raio fino 128 m e
## histerese 64 m (os valores iniciais [HIP] do envio). O centro do chunk (x, z) fica em ((x + 0,5) x 64, (z + 0,5) x 64).

const FINE: int = TerrainChunkBuilder.STEP_FINE
const COARSE: int = TerrainChunkBuilder.STEP_COARSE
const ABSENT: int = TerrainStreaming.ABSENT
const CHUNK_SIZE_M: float = 64.0
const GRID: Vector2i = Vector2i(16, 16)
const LOAD_M: float = 384.0
const FINE_M: float = 128.0
const HYSTERESIS_M: float = 64.0
const OSCILLATIONS: int = 40
## Um metro para cada lado da borda.
const JITTER_M: float = 1.0
const CENTER_FOCUS: Vector2 = Vector2(512.0, 512.0)


func _center(coord: Vector2i) -> Vector2:
	return Vector2((float(coord.x) + 0.5) * CHUNK_SIZE_M, (float(coord.y) + 0.5) * CHUNK_SIZE_M)


func test_the_default_radii_are_the_values_of_the_task() -> void:
	var streaming: TerrainStreaming = TerrainStreaming.new()
	assert_eq(streaming.load_radius_m, 384.0)
	assert_eq(streaming.fine_radius_m, 128.0)
	assert_eq(streaming.hysteresis_m, 64.0)


func test_each_distance_and_current_step_gives_the_expected_band() -> void:
	var streaming: TerrainStreaming = TerrainStreaming.new()
	# [distância, passo atual, passo desejado]
	var table: Array[Array] = [
		[0.0, ABSENT, FINE], [128.0, ABSENT, FINE], [128.01, ABSENT, COARSE], [384.0, ABSENT, COARSE], [384.01, ABSENT, ABSENT],
		[100.0, FINE, FINE], [192.0, FINE, FINE], [192.01, FINE, COARSE], [448.0, FINE, COARSE], [448.01, FINE, ABSENT],
		[100.0, COARSE, FINE], [128.0, COARSE, FINE], [129.0, COARSE, COARSE], [448.0, COARSE, COARSE], [449.0, COARSE, ABSENT],
	]
	for row: Array in table:
		assert_eq(streaming.desired_step(row[0], row[1]), row[2], "Distância %s com passo atual %s." % [str(row[0]), str(row[1])])


func test_a_focus_oscillating_one_meter_across_each_border_loads_and_changes_at_most_once() -> void:
	var streaming: TerrainStreaming = TerrainStreaming.new()
	# Borda de carga: o chunk começa descarregado, perto do raio de carga.
	var state: int = ABSENT
	var loads: int = 0
	var unloads: int = 0
	for index: int in range(OSCILLATIONS):
		var wanted: int = streaming.desired_step(LOAD_M + (-JITTER_M if index % 2 == 0 else JITTER_M), state)
		loads += 1 if state == ABSENT and wanted != ABSENT else 0
		unloads += 1 if state != ABSENT and wanted == ABSENT else 0
		state = wanted
	assert_eq(loads, 1, "Carrega uma vez e fica.")
	assert_eq(unloads, 0, "Nunca descarta na oscilação.")
	# Borda de descarte: o chunk já está carregado, perto do raio de carga mais a histerese.
	state = COARSE
	loads = 0
	unloads = 0
	for index: int in range(OSCILLATIONS):
		var wanted: int = streaming.desired_step(LOAD_M + HYSTERESIS_M + (-JITTER_M if index % 2 == 0 else JITTER_M), state)
		loads += 1 if state == ABSENT and wanted != ABSENT else 0
		unloads += 1 if state != ABSENT and wanted == ABSENT else 0
		state = wanted
	assert_eq(unloads, 1, "Descarta uma vez e não volta a carregar.")
	assert_eq(loads, 0)
	# Borda do detalhe fino: começa grosso, perto do raio fino.
	state = COARSE
	var rebuilds: int = 0
	for index: int in range(OSCILLATIONS):
		var wanted: int = streaming.desired_step(FINE_M + (-JITTER_M if index % 2 == 0 else JITTER_M), state)
		rebuilds += 1 if wanted != state else 0
		state = wanted
	assert_eq(rebuilds, 1, "Vira fino uma vez e fica fino.")
	assert_eq(state, FINE)


func test_the_plan_for_a_central_focus_is_exactly_the_chunks_inside_the_load_radius() -> void:
	var streaming: TerrainStreaming = TerrainStreaming.new()
	var plan: TerrainStreaming.Plan = streaming.plan(GRID, CHUNK_SIZE_M, CENTER_FOCUS, {})
	var expected_count: int = 0
	for chunk_z: int in range(GRID.y):
		for chunk_x: int in range(GRID.x):
			var coord: Vector2i = Vector2i(chunk_x, chunk_z)
			var distance: float = _center(coord).distance_to(CENTER_FOCUS)
			if distance <= LOAD_M:
				expected_count += 1
				assert_true(plan.wanted.has(coord), "Falta o chunk %s a %s m." % [str(coord), str(distance)])
				assert_eq(plan.wanted[coord], FINE if distance <= FINE_M else COARSE, "Passo do chunk %s." % str(coord))
			else:
				assert_false(plan.wanted.has(coord), "Chunk %s a %s m não deveria existir." % [str(coord), str(distance)])
	assert_eq(plan.wanted.size(), expected_count)
	assert_gt(expected_count, 100, "Em volta do centro há mais de 100 chunks.")
	assert_eq(plan.unload.size(), 0, "Nada carregado, nada a descartar.")


func test_the_plan_unloads_only_what_passed_the_load_radius_plus_the_hysteresis() -> void:
	var streaming: TerrainStreaming = TerrainStreaming.new()
	var loaded: Dictionary[Vector2i, int] = streaming.plan(GRID, CHUNK_SIZE_M, CENTER_FOCUS, {}).wanted
	var new_focus: Vector2 = Vector2(900.0, 900.0)
	var plan: TerrainStreaming.Plan = streaming.plan(GRID, CHUNK_SIZE_M, new_focus, loaded)
	var kept_by_hysteresis: int = 0
	for coord: Vector2i in loaded:
		var distance: float = _center(coord).distance_to(new_focus)
		if distance > LOAD_M + HYSTERESIS_M:
			assert_true(plan.unload.has(coord), "O chunk %s a %s m devia sair." % [str(coord), str(distance)])
		else:
			assert_false(plan.unload.has(coord), "O chunk %s a %s m devia ficar." % [str(coord), str(distance)])
			assert_true(plan.wanted.has(coord))
			kept_by_hysteresis += 1 if distance > LOAD_M else 0
	assert_gt(plan.unload.size(), 0)
	assert_gt(kept_by_hysteresis, 0, "Há chunks entre o raio de carga e o de descarte: a histerese os segura.")


func test_the_plan_never_leaves_the_grid_and_a_focus_far_outside_asks_for_nothing() -> void:
	var streaming: TerrainStreaming = TerrainStreaming.new()
	for focus: Vector2 in [Vector2.ZERO, Vector2(1024.0, 1024.0), Vector2(0.0, 1024.0), Vector2(1024.0, 0.0)]:
		var plan: TerrainStreaming.Plan = streaming.plan(GRID, CHUNK_SIZE_M, focus, {})
		assert_gt(plan.wanted.size(), 20, "Num canto ainda há chunks (focus %s)." % str(focus))
		for coord: Vector2i in plan.wanted:
			assert_true(coord.x >= 0 and coord.y >= 0 and coord.x < GRID.x and coord.y < GRID.y, "Chunk fora da grade: %s" % str(coord))
	var outside: TerrainStreaming.Plan = streaming.plan(GRID, CHUNK_SIZE_M, Vector2(-1000.0, -1000.0), {})
	assert_eq(outside.wanted.size(), 0)
	assert_eq(outside.unload.size(), 0)
