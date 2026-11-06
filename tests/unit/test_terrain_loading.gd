extends GutTest
## LW-040: carga e descarga de chunks pela TerrainView com foco, sem janela. Terreno de blockout real e ponte real; só a
## contagem de nós depois de 500 deslocamentos usa um terreno sintético de chunks pequenos (para ficar rápido).

const BLOCKOUT_DIR: String = "res://data/world"
const DECORATIONS_PATH: String = "res://data/world/decorations.json"
const FINE: int = TerrainChunkBuilder.STEP_FINE
const COARSE: int = TerrainChunkBuilder.STEP_COARSE
const ABSENT: int = TerrainStreaming.ABSENT
const HUGE_BUDGET_MS: float = 1.0e9
const HUGE_COUNT: int = 100000
const CHUNK_SIZE_M: float = 64.0
## Raios iniciais [HIP] do envio, escritos à mão.
const LOAD_M: float = 384.0
const FINE_M: float = 128.0
const HYSTERESIS_M: float = 64.0
const CELLS_PER_CHUNK: int = 32
const HEIGHT_TOLERANCE_M: float = 0.01
## Rota scriptada pelo mapa (x, z em metros): do nascimento ao leste, subindo para a colina e até o canto de nordeste.
const ROUTE: Array[Vector2] = [Vector2(100.0, 512.0), Vector2(400.0, 512.0), Vector2(520.0, 360.0), Vector2(700.0, 300.0), Vector2(900.0, 100.0)]
const FAR_CORNER: Vector2 = Vector2(950.0, 950.0)
const NEAR_ORIGIN: Vector2 = Vector2(100.0, 100.0)
## Terreno sintético: 128 x 128 células de 2 m (256 m), chunks de 4 células (8 m).
const SMALL_CELLS: int = 128
const SMALL_CHUNK_CELLS: int = 4
const SMALL_CELL_CM: int = 200
const SMALL_CODE: int = 5
const SMALL_LOAD_M: float = 32.0
const SMALL_FINE_M: float = 16.0
const SMALL_HYSTERESIS_M: float = 8.0
const DISPLACEMENT_M: float = 6.0
## O trajeto vai e volta por 36 passos de ida e 36 de volta (216 m): período de 72 deslocamentos; 504 = 7 períodos.
const HALF_PERIOD_STEPS: int = 36
const PERIOD_STEPS: int = HALF_PERIOD_STEPS * 2
const DISPLACEMENTS: int = 504
const FIRST_STEADY_STEP: int = 144
const NODES_PER_FINE_CHUNK: int = 3
const SETTLE_FRAMES: int = 4

var _bridge: SimBridge
var _layout: SimBridge.TerrainLayoutReply


func before_all() -> void:
	var loaded: TerrainLoader.LoadResult = TerrainLoader.load_dir(BLOCKOUT_DIR)
	assert_true(loaded.result.ok, loaded.result.message)
	_bridge = SimBridge.new(null, loaded.terrain)
	_layout = _bridge.peek_terrain_layout()


## View nova sobre o terreno real, com o replanejamento a cada set_focus (para os testes não dependerem da distância mínima).
func _new_view() -> TerrainView:
	var view: TerrainView = TerrainView.new()
	view.setup(_bridge)
	view.replan_move_m = 0.0
	return view


func _focus(view: TerrainView, point: Vector2) -> void:
	view.set_focus(Vector3(point.x, 0.0, point.y))


func _center(coord: Vector2i) -> Vector2:
	return Vector2((float(coord.x) + 0.5) * CHUNK_SIZE_M, (float(coord.y) + 0.5) * CHUNK_SIZE_M)


## Quantos chunks do mapa têm o centro a até `radius_m` do ponto: contagem direta, sem usar o código testado.
func _count_within(point: Vector2, radius_m: float) -> int:
	var count: int = 0
	for chunk_z: int in range(_layout.chunk_count.y):
		for chunk_x: int in range(_layout.chunk_count.x):
			if _center(Vector2i(chunk_x, chunk_z)).distance_to(point) <= radius_m:
				count += 1
	return count


func _small_bridge() -> SimBridge:
	var nodes_per_side: int = SMALL_CELLS + 1
	var heights: PackedInt64Array = PackedInt64Array()
	heights.resize(nodes_per_side * nodes_per_side)
	var surfaces: PackedInt64Array = PackedInt64Array()
	surfaces.resize(SMALL_CELLS * SMALL_CELLS)
	surfaces.fill(SMALL_CODE)
	var ids: Dictionary[int, String] = {SMALL_CODE: "grass"}
	var terrain: TerrainData = TerrainData.new(Vector2i(SMALL_CELLS, SMALL_CELLS), SMALL_CELL_CM, SMALL_CHUNK_CELLS, heights, surfaces, ids, Vector2i.ZERO)
	return SimBridge.new(null, terrain)


func test_only_the_chunks_inside_the_radius_exist_after_a_scripted_route() -> void:
	var view: TerrainView = _new_view()
	for point: Vector2 in ROUTE:
		_focus(view, point)
		view.process_budget(HUGE_BUDGET_MS)
		assert_eq(view.pending_count() + view.collision_pending_count() + view.free_pending_count(), 0, "Tudo foi feito.")
		var loaded_count: int = 0
		for chunk_z: int in range(_layout.chunk_count.y):
			for chunk_x: int in range(_layout.chunk_count.x):
				var coord: Vector2i = Vector2i(chunk_x, chunk_z)
				var distance: float = _center(coord).distance_to(point)
				if distance <= LOAD_M:
					assert_true(view.has_chunk(coord), "Falta o chunk %s a %s m do foco %s." % [str(coord), str(distance), str(point)])
				if view.has_chunk(coord):
					loaded_count += 1
					assert_lte(distance, LOAD_M + HYSTERESIS_M, "O chunk %s está a %s m do foco %s: devia ter saído." % [str(coord), str(distance), str(point)])
		assert_eq(view.built_count(), loaded_count)
		assert_lt(view.built_count(), _layout.chunk_count.x * _layout.chunk_count.y, "Nunca o mapa todo.")
	view.free()


func test_node_and_orphan_counts_stay_stable_after_500_displacements() -> void:
	var nodes_at_start: int = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var orphans_at_start: int = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	var view: TerrainView = TerrainView.new()
	add_child(view)
	view.setup(_small_bridge())
	view.streaming.load_radius_m = SMALL_LOAD_M
	view.streaming.fine_radius_m = SMALL_FINE_M
	view.streaming.hysteresis_m = SMALL_HYSTERESIS_M
	view.replan_move_m = 0.0
	var size_m: float = float(SMALL_CELLS) * float(SMALL_CELL_CM) / 100.0
	var start_x: float = SMALL_LOAD_M
	var counts_at_phase: Dictionary[int, int] = {}
	var most_nodes: int = 0
	for step: int in range(DISPLACEMENTS + 1):
		var phase: int = step % PERIOD_STEPS
		var along: float = float(phase if phase <= HALF_PERIOD_STEPS else PERIOD_STEPS - phase) * DISPLACEMENT_M
		view.set_focus(Vector3(start_x + along, 0.0, size_m * 0.5))
		view.process_budget(HUGE_BUDGET_MS)
		var nodes: int = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)) - nodes_at_start
		most_nodes = maxi(most_nodes, nodes)
		if step >= FIRST_STEADY_STEP and phase == 0:
			counts_at_phase[step] = nodes
	var reference: int = counts_at_phase[FIRST_STEADY_STEP]
	for step: int in counts_at_phase:
		assert_eq(counts_at_phase[step], reference, "Contagem de nós no deslocamento %d diferente da do %d: vazamento." % [step, FIRST_STEADY_STEP])
	var chunks_in_reach: int = ceili(PI * pow(SMALL_LOAD_M + SMALL_HYSTERESIS_M + float(SMALL_CHUNK_CELLS * SMALL_CELL_CM) / 100.0, 2.0) / pow(float(SMALL_CHUNK_CELLS * SMALL_CELL_CM) / 100.0, 2.0))
	assert_lte(most_nodes, 1 + chunks_in_reach * NODES_PER_FINE_CHUNK, "Mais nós do que os chunks ao alcance explicam.")
	view.free()
	assert_eq(int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)), nodes_at_start, "Liberar a view libera todos os nós.")
	assert_eq(int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)), orphans_at_start, "Nenhum nó órfão ficou para trás.")


func test_near_chunks_are_fine_with_collision_and_far_chunks_are_coarse_without_it() -> void:
	var view: TerrainView = _new_view()
	var focus: Vector2 = Vector2(512.0, 512.0)
	_focus(view, focus)
	view.process_budget(HUGE_BUDGET_MS)
	var fine_count: int = 0
	for coord: Vector2i in view.loaded_chunks():
		var distance: float = _center(coord).distance_to(focus)
		var expected_step: int = FINE if distance <= FINE_M else COARSE
		assert_eq(view.chunk_step(coord), expected_step, "Passo do chunk %s a %s m." % [str(coord), str(distance)])
		assert_eq(view.chunk_body(coord) != null, expected_step == FINE, "Só o chunk fino tem colisão (%s)." % str(coord))
		assert_eq(view.chunk_node(coord).mesh.surface_get_array_len(0), TerrainChunkBuilder.expected_vertex_count(CELLS_PER_CHUNK, expected_step), "Vértices do chunk %s." % str(coord))
		fine_count += 1 if expected_step == FINE else 0
	assert_gt(fine_count, 5)
	assert_lt(fine_count * 2, view.built_count(), "Perto é minoria: a maior parte do terreno é grossa.")
	view.free()


func test_a_chunk_outside_the_radius_leaves_the_queue_before_being_built() -> void:
	var view: TerrainView = _new_view()
	var loaded_log: Array[Vector2i] = []
	view.chunk_loaded.connect(func(coord: Vector2i) -> void: loaded_log.append(coord))
	_focus(view, NEAR_ORIGIN)
	var queued_near_origin: int = _count_within(NEAR_ORIGIN, LOAD_M)
	assert_gt(queued_near_origin, 20, "Em volta do foco de origem há pelo menos 20 chunks.")
	assert_eq(view.pending_count(), queued_near_origin, "A fila tem exatamente os chunks dentro do raio de carga.")
	_focus(view, FAR_CORNER)
	view.process_budget(HUGE_BUDGET_MS)
	assert_false(loaded_log.has(Vector2i(0, 0)), "O chunk (0, 0) saiu da fila antes de ser construído.")
	for coord: Vector2i in loaded_log:
		assert_lte(_center(coord).distance_to(FAR_CORNER), LOAD_M, "Só foi construído o que está em volta do foco novo (%s)." % str(coord))
	assert_eq(view.pending_count(), 0)
	view.free()


func test_the_initial_build_starts_with_the_chunk_under_the_focus_and_the_collision_comes_next() -> void:
	var view: TerrainView = _new_view()
	var under_focus: Vector2i = Vector2i(1, 8)
	_focus(view, Vector2(100.0, 530.0))
	assert_eq(view.process_chunks(1), 1)
	assert_true(view.has_chunk(under_focus), "O primeiro chunk construído é o que está sob o foco.")
	assert_eq(view.chunk_step(under_focus), FINE)
	assert_null(view.chunk_body(under_focus), "A malha vem primeiro e o corpo de colisão é outra tarefa.")
	assert_eq(view.collision_pending_count(), 1)
	assert_eq(view.process_budget(0.0), 0, "Com orçamento zero sai uma tarefa só, e a de colisão tem prioridade.")
	assert_not_null(view.chunk_body(under_focus))
	assert_eq(view.collision_pending_count(), 0)
	view.free()


func test_freeing_is_budgeted_like_building_and_building_comes_first() -> void:
	var view: TerrainView = _new_view()
	_focus(view, NEAR_ORIGIN)
	view.process_budget(HUGE_BUDGET_MS)
	var loaded_before: int = view.built_count()
	_focus(view, FAR_CORNER)
	assert_gt(view.pending_count(), 0)
	assert_gt(view.free_pending_count(), 0)
	var meshes_pending: int = view.pending_count()
	var frees_pending: int = view.free_pending_count()
	var built_now: int = view.built_count()
	view.process_budget(0.0)
	assert_eq(view.free_pending_count(), frees_pending, "Com construção pendente, nada é liberado ainda.")
	assert_eq(view.pending_count(), meshes_pending - 1, "Uma tarefa por chamada com orçamento zero.")
	assert_eq(view.built_count(), built_now + 1)
	view.process_chunks(HUGE_COUNT)
	while view.collision_pending_count() > 0:
		view.process_budget(0.0)
	assert_eq(view.pending_count(), 0)
	var before_frees: int = view.built_count()
	for expected_left: int in range(frees_pending - 1, -1, -1):
		view.process_budget(0.0)
		assert_eq(view.free_pending_count(), expected_left, "Cada chamada com orçamento zero libera um chunk.")
	assert_eq(view.built_count(), before_frees - frees_pending)
	assert_lt(view.built_count(), loaded_before + 40, "O total carregado não cresce sem limite.")
	view.free()


func test_decoration_is_visible_only_where_the_terrain_is_loaded() -> void:
	var view: TerrainView = _new_view()
	var decoration: DecorationView = DecorationView.new()
	var read: DecorationReader.ReadResult = DecorationReader.read_file(DECORATIONS_PATH)
	assert_true(read.result.ok, read.result.message)
	decoration.setup(_bridge, read.items)
	view.chunk_loaded.connect(decoration.set_chunk_visible.bind(true))
	view.chunk_unloaded.connect(decoration.set_chunk_visible.bind(false))
	assert_eq(_visible_instances(decoration).size(), 0, "Antes de existir terreno, nenhuma decoração aparece.")
	_focus(view, NEAR_ORIGIN)
	view.process_budget(HUGE_BUDGET_MS)
	var visible_near: Array[String] = _visible_instances(decoration)
	_assert_visibility_follows_terrain(decoration, view)
	assert_gt(visible_near.size(), 0, "Em volta do foco há decoração visível.")
	_focus(view, FAR_CORNER)
	view.process_budget(HUGE_BUDGET_MS)
	_assert_visibility_follows_terrain(decoration, view)
	var visible_far: Array[String] = _visible_instances(decoration)
	assert_gt(visible_far.size(), 0)
	var gone: int = 0
	for instance_name: String in visible_near:
		gone += 0 if visible_far.has(instance_name) else 1
	assert_gt(gone, 0, "O que ficou longe do foco novo sumiu junto com o terreno.")
	decoration.free()
	view.free()


func _visible_instances(decoration: DecorationView) -> Array[String]:
	var names: Array[String] = []
	for instance: MultiMeshInstance3D in decoration.multimesh_instances():
		if instance.visible:
			names.append(String(instance.name))
	return names


func _assert_visibility_follows_terrain(decoration: DecorationView, view: TerrainView) -> void:
	for instance: MultiMeshInstance3D in decoration.multimesh_instances():
		var parts: PackedStringArray = String(instance.name).trim_prefix("Deco_").split("_")
		var chunk: Vector2i = Vector2i(int(parts[1]), int(parts[2]))
		assert_eq(instance.visible, view.has_chunk(chunk), "%s: visível só se o chunk %s está carregado." % [instance.name, str(chunk)])


func test_has_collision_at_is_false_before_the_chunk_exists_and_true_once_the_physics_settles() -> void:
	var view: TerrainView = TerrainView.new()
	add_child(view)
	view.setup(_bridge)
	var spawn: Vector3 = _bridge.peek_spawn_point().point
	assert_false(view.has_collision_at(spawn), "Antes de existir o chunk, sem colisão.")
	_focus(view, Vector2(spawn.x, spawn.z))
	view.set_process(false)
	assert_false(view.has_collision_at(spawn), "Foco informado, mas nada construído ainda.")
	view.process_budget(HUGE_BUDGET_MS)
	assert_true(view.chunk_body(Vector2i(1, 8)) != null or view.chunk_body(Vector2i(1, 7)) != null)
	assert_false(view.has_collision_at(spawn), "No mesmo quadro de física em que o corpo entrou, ele ainda não vale.")
	for frame: int in range(TerrainView.COLLISION_SETTLE_PHYSICS_FRAMES + 1):
		await get_tree().physics_frame
	assert_true(view.has_collision_at(spawn), "Passados os quadros de física, a colisão vale.")
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(Vector3(spawn.x, 100.0, spawn.z), Vector3(spawn.x, -50.0, spawn.z), 1 << (TerrainView.TERRAIN_PHYSICS_LAYER - 1))
	var hit: Dictionary = get_viewport().find_world_3d().direct_space_state.intersect_ray(query)
	assert_false(hit.is_empty(), "Quando has_collision_at é verdadeiro, o raio acerta o chão.")
	var hit_position: Vector3 = hit["position"]
	assert_almost_eq(hit_position.y, spawn.y, HEIGHT_TOLERANCE_M)
	assert_false(view.has_collision_at(Vector3(FAR_CORNER.x, 0.0, FAR_CORNER.y)), "Longe do foco não há colisão.")
	view.free()


func test_a_focus_outside_the_map_is_clamped_without_error_and_bad_calls_report() -> void:
	var lonely: TerrainView = TerrainView.new()
	lonely.set_focus(Vector3.ZERO)
	assert_push_error("view sem terreno")
	lonely.free()
	var view: TerrainView = _new_view()
	view.set_focus(Vector3(NAN, 0.0, 10.0))
	assert_push_error("não numérica")
	view.set_focus(Vector3(-500.0, 0.0, 5000.0))
	assert_eq(view.focus(), Vector2(0.0, _layout.size_m.y), "O foco é limitado ao mapa.")
	view.process_budget(HUGE_BUDGET_MS)
	assert_true(view.has_chunk(Vector2i(0, _layout.chunk_count.y - 1)), "O chunk do canto mais perto do foco limitado existe.")
	view.free()


func test_small_moves_do_not_replan_and_large_moves_do() -> void:
	var view: TerrainView = TerrainView.new()
	view.setup(_bridge)
	assert_eq(view.replan_move_m, TerrainView.DEFAULT_REPLAN_MOVE_M)
	_focus(view, Vector2(512.0, 512.0))
	view.process_budget(HUGE_BUDGET_MS)
	_focus(view, Vector2(515.0, 512.0))
	assert_eq(view.pending_count() + view.free_pending_count(), 0, "3 m não refazem o plano.")
	_focus(view, Vector2(640.0, 512.0))
	assert_gt(view.pending_count(), 0, "128 m refazem o plano.")
	view.free()


func test_the_seam_between_a_fine_chunk_and_a_coarse_neighbor_stays_covered_by_the_skirt() -> void:
	var view: TerrainView = _new_view()
	view.streaming.load_radius_m = 200.0
	view.streaming.fine_radius_m = 100.0
	_focus(view, Vector2(620.0, 288.0))
	view.process_budget(HUGE_BUDGET_MS)
	var fine_coord: Vector2i = Vector2i(10, 4)
	var coarse_coord: Vector2i = Vector2i(11, 4)
	assert_eq(view.chunk_step(fine_coord), FINE, "O chunk da colina, perto do foco, é fino.")
	assert_eq(view.chunk_step(coarse_coord), COARSE, "O vizinho a leste, mais longe, é grosso.")
	var fine_top: Dictionary[float, float] = _edge(view.chunk_node(fine_coord).mesh, true, CHUNK_SIZE_M, false)
	var coarse_top: Dictionary[float, float] = _edge(view.chunk_node(coarse_coord).mesh, true, 0.0, false)
	var fine_low: Dictionary[float, float] = _edge(view.chunk_node(fine_coord).mesh, true, CHUNK_SIZE_M, true)
	var coarse_low: Dictionary[float, float] = _edge(view.chunk_node(coarse_coord).mesh, true, 0.0, true)
	var largest_gap: float = 0.0
	var uncovered: float = 0.0
	for along: float in fine_top:
		var coarse_height: float = _interpolate(coarse_top, along)
		var gap: float = fine_top[along] - coarse_height
		largest_gap = maxf(largest_gap, absf(gap))
		var reach: float = fine_top[along] - fine_low[along] if gap > 0.0 else coarse_height - _interpolate(coarse_low, along)
		uncovered = maxf(uncovered, absf(gap) - reach)
	assert_gt(largest_gap, 0.0, "A borda da colina varia: o teste não é vazio.")
	assert_lte(largest_gap, 0.0251, "A maior diferença de borda do Lote 1 (2,5 cm) não piora.")
	assert_lte(uncovered, 0.0001, "A saia cobre a diferença.")
	view.free()


## y por posição ao longo da borda (z, neste teste, na leste ou oeste) a x local fixo; `lowest` pega o ponto mais baixo (fundo da saia).
func _edge(mesh: ArrayMesh, _east_west: bool, edge_x: float, lowest: bool) -> Dictionary[float, float]:
	var vertices: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var profile: Dictionary[float, float] = {}
	for vertex: Vector3 in vertices:
		if is_equal_approx(vertex.x, edge_x):
			profile[vertex.z] = minf(profile.get(vertex.z, INF), vertex.y) if lowest else maxf(profile.get(vertex.z, -INF), vertex.y)
	return profile


func _interpolate(profile: Dictionary[float, float], at: float) -> float:
	var keys: Array[float] = []
	for key: float in profile:
		keys.append(key)
	keys.sort()
	for index: int in range(keys.size() - 1):
		if at >= keys[index] and at <= keys[index + 1]:
			return lerpf(profile[keys[index]], profile[keys[index + 1]], (at - keys[index]) / (keys[index + 1] - keys[index]))
	return NAN
