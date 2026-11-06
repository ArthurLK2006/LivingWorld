extends GutTest
## LW-038: TerrainView (malha por chunk, construção incremental, passos e saias), sem janela, com o terreno de
## blockout real (DEC-118) e a ponte real. Os casos de borda extrema usam um terreno pequeno em memória.

const BLOCKOUT_DIR: String = "res://data/world"
## A colina do blockout (centro em 700 m, 300 m) fica neste chunk; o vizinho a leste divide a borda x = 704 m.
const HILL_CHUNK: Vector2i = Vector2i(10, 4)
const EAST_OF_HILL_CHUNK: Vector2i = Vector2i(11, 4)
## O nascimento (100 m, 512 m) está exatamente na divisa z = 512 m: toca os chunks (1, 7) e (1, 8), à mesma distância.
const SPAWN_CHUNK: Vector2i = Vector2i(1, 8)
const SPAWN_CHUNK_NORTH: Vector2i = Vector2i(1, 7)
const TOLERANCE: float = 0.0001
## O Godot guarda normal e cor de vértice comprimidas (cor em 8 bits: passos de 1/255); folga ao reler.
const NORMAL_TOLERANCE: float = 0.001
const COLOR_TOLERANCE: float = 0.005
## Fórmula de vértices (a mesma de docs/modules/presentation.md): 3 por triângulo, 2 triângulos por quadrado, 4 bordas.
const VERTICES_PER_TRIANGLE: int = 3
const TRIANGLES_PER_QUAD: int = 2
const SKIRT_SIDES: int = 4
const FINE: int = 1
const COARSE: int = 2
const MAX_BUDGET_CALLS: int = 1000
const HUGE_BUDGET_MS: float = 1.0e9
## Terreno em memória: 8 x 8 células de 2 m em chunks de 4 células (2 x 2 chunks), uma superfície só.
const SMALL_CELLS: int = 8
const SMALL_CHUNK_CELLS: int = 4
const SMALL_CELL_CM: int = 200
const SMALL_CODE: int = 5
## Nó ímpar da borda entre os dois chunks de cima: o passo 1 enxerga o desnível, o passo 2 não.
const BUMP_NODE: Vector2i = Vector2i(4, 1)
const BUMP_CM: int = 150
const SHALLOW_SKIRT_M: float = 1.0

var _bridge: SimBridge
var _layout: SimBridge.TerrainLayoutReply
var _view: TerrainView
var _calls_to_finish: int = 0


func before_all() -> void:
	var loaded: TerrainLoader.LoadResult = TerrainLoader.load_dir(BLOCKOUT_DIR)
	assert_true(loaded.result.ok, loaded.result.message)
	_bridge = SimBridge.new(null, loaded.terrain)
	_layout = _bridge.peek_terrain_layout()
	_view = TerrainView.new()
	_view.setup(_bridge)
	# Orçamento zero: cada chamada constrói exatamente 1 chunk (o mínimo garantido por quadro).
	while _view.pending_count() > 0 and _calls_to_finish < MAX_BUDGET_CALLS:
		_view.process_budget(0.0)
		_calls_to_finish += 1


func after_all() -> void:
	_view.free()


func _chunk_size_m(layout: SimBridge.TerrainLayoutReply) -> float:
	return float(layout.chunk_cells) * layout.cell_size_m


func _quads(layout: SimBridge.TerrainLayoutReply, step: int) -> int:
	return IntMath.floor_div(layout.chunk_cells, step)


func _body_vertices(layout: SimBridge.TerrainLayoutReply, step: int) -> int:
	return VERTICES_PER_TRIANGLE * TRIANGLES_PER_QUAD * _quads(layout, step) * _quads(layout, step)


func _vertices_per_chunk(layout: SimBridge.TerrainLayoutReply, step: int) -> int:
	return _body_vertices(layout, step) + VERTICES_PER_TRIANGLE * TRIANGLES_PER_QUAD * SKIRT_SIDES * _quads(layout, step)


## Ponte sobre um terreno pequeno em memória: plano, de uma superfície só, com os nós de `bumps` elevados (cm).
func _small_bridge(surface_id: String, bumps: Dictionary[Vector2i, int]) -> SimBridge:
	var nodes_per_side: int = SMALL_CELLS + 1
	var heights: PackedInt64Array = PackedInt64Array()
	heights.resize(nodes_per_side * nodes_per_side)
	for node: Vector2i in bumps:
		heights[node.y * nodes_per_side + node.x] = bumps[node]
	var surfaces: PackedInt64Array = PackedInt64Array()
	surfaces.resize(SMALL_CELLS * SMALL_CELLS)
	surfaces.fill(SMALL_CODE)
	var ids: Dictionary[int, String] = {SMALL_CODE: surface_id}
	var terrain: TerrainData = TerrainData.new(Vector2i(SMALL_CELLS, SMALL_CELLS), SMALL_CELL_CM, SMALL_CHUNK_CELLS, heights, surfaces, ids, Vector2i.ZERO)
	return SimBridge.new(null, terrain)


func _vertices_of(mesh: ArrayMesh) -> PackedVector3Array:
	var vertices: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	return vertices


## y por posição ao longo da borda leste (`east`) ou oeste do chunk, olhando os `count` primeiros vértices.
## `lowest` guarda o vértice mais baixo de cada posição (fundo da saia); senão, o do corpo da malha.
func _east_west_edge(mesh: ArrayMesh, layout: SimBridge.TerrainLayoutReply, east: bool, count: int, lowest: bool) -> Dictionary[float, float]:
	var vertices: PackedVector3Array = _vertices_of(mesh)
	var edge_x: float = _chunk_size_m(layout) if east else 0.0
	var profile: Dictionary[float, float] = {}
	for index: int in range(count):
		if is_equal_approx(vertices[index].x, edge_x):
			var along: float = vertices[index].z
			profile[along] = minf(profile.get(along, INF), vertices[index].y) if lowest else vertices[index].y
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


## Maior diferença de altura entre a borda leste do chunk fino (passo 1) e a oeste do grosso (passo 2) vizinho.
func _largest_gap(fine: ArrayMesh, coarse: ArrayMesh, layout: SimBridge.TerrainLayoutReply) -> float:
	var fine_top: Dictionary[float, float] = _east_west_edge(fine, layout, true, _body_vertices(layout, FINE), false)
	var coarse_top: Dictionary[float, float] = _east_west_edge(coarse, layout, false, _body_vertices(layout, COARSE), false)
	var largest: float = 0.0
	for along: float in fine_top:
		largest = maxf(largest, absf(fine_top[along] - _interpolate(coarse_top, along)))
	return largest


## Quanto da diferença de altura fica SEM saia que a cubra. A profundidade é MEDIDA na malha (topo do corpo
## menos o ponto mais baixo da saia) e vale a saia do lado mais alto em cada ponto da borda.
func _largest_uncovered_gap(fine: ArrayMesh, coarse: ArrayMesh, layout: SimBridge.TerrainLayoutReply) -> float:
	var fine_top: Dictionary[float, float] = _east_west_edge(fine, layout, true, _body_vertices(layout, FINE), false)
	var coarse_top: Dictionary[float, float] = _east_west_edge(coarse, layout, false, _body_vertices(layout, COARSE), false)
	var fine_low: Dictionary[float, float] = _east_west_edge(fine, layout, true, _vertices_of(fine).size(), true)
	var coarse_low: Dictionary[float, float] = _east_west_edge(coarse, layout, false, _vertices_of(coarse).size(), true)
	var uncovered: float = 0.0
	for along: float in fine_top:
		var coarse_height: float = _interpolate(coarse_top, along)
		var gap: float = fine_top[along] - coarse_height
		var reach: float = fine_top[along] - fine_low[along] if gap > 0.0 else coarse_height - _interpolate(coarse_low, along)
		uncovered = maxf(uncovered, absf(gap) - reach)
	return uncovered


func _colors_of(mesh: ArrayMesh) -> Dictionary[Color, bool]:
	var colors: PackedColorArray = mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR]
	var found: Dictionary[Color, bool] = {}
	for color: Color in colors:
		found[color] = true
	return found


func _has_color(found: Dictionary[Color, bool], wanted: Color) -> bool:
	for color: Color in found:
		if absf(color.r - wanted.r) <= COLOR_TOLERANCE and absf(color.g - wanted.g) <= COLOR_TOLERANCE and absf(color.b - wanted.b) <= COLOR_TOLERANCE:
			return true
	return false


func test_the_whole_terrain_is_built_as_one_mesh_instance_per_chunk() -> void:
	var expected: int = _layout.chunk_count.x * _layout.chunk_count.y
	assert_eq(expected, 256, "16 x 16 chunks no blockout (DEC-118).")
	assert_eq(_view.built_count(), expected)
	assert_eq(_view.get_child_count(), expected, "Um nó por chunk, filho da view.")
	var last: Vector2i = _layout.chunk_count - Vector2i.ONE
	var spawn: Vector3 = _bridge.peek_spawn_point().point
	var size_m: float = _chunk_size_m(_layout)
	assert_eq(Vector2i(floori(spawn.x / size_m), floori(spawn.z / size_m)), SPAWN_CHUNK)
	var wanted: Array[Vector2i] = [Vector2i.ZERO, Vector2i(last.x, 0), Vector2i(0, last.y), last, SPAWN_CHUNK]
	for coord: Vector2i in wanted:
		assert_true(_view.has_chunk(coord), "Falta o chunk %s." % str(coord))
	assert_eq(_view.chunk_node(last).position, Vector3(float(last.x) * size_m, 0.0, float(last.y) * size_m), "O nó fica na origem do chunk.")


func test_vertex_counts_follow_the_formula_for_both_steps() -> void:
	var per_chunk: int = _vertices_per_chunk(_layout, FINE)
	assert_eq(per_chunk, 6912, "q = 32: 3 x 2 x (32 x 32 + 4 x 32).")
	var sampled_total: int = 0
	var sampled: Array[Vector2i] = [Vector2i.ZERO, HILL_CHUNK, _layout.chunk_count - Vector2i.ONE]
	for coord: Vector2i in sampled:
		sampled_total += _view.chunk_node(coord).mesh.surface_get_array_len(0)
	assert_eq(sampled_total, sampled.size() * per_chunk)
	assert_eq(_view.total_vertex_count(), _layout.chunk_count.x * _layout.chunk_count.y * per_chunk, "256 x 6.912 = 1.769.472.")
	var coarse: ArrayMesh = TerrainChunkBuilder.new(_bridge, _layout).build(HILL_CHUNK, COARSE)
	assert_eq(_vertices_of(coarse).size(), _vertices_per_chunk(_layout, COARSE), "Passo 2: q = 16, 1.920 vértices.")


func test_the_frame_budget_spreads_the_building_over_many_steps_and_ends_with_nothing_pending() -> void:
	assert_eq(_calls_to_finish, _layout.chunk_count.x * _layout.chunk_count.y, "Orçamento zero = um chunk por chamada.")
	assert_eq(_view.pending_count(), 0)
	var small: TerrainView = TerrainView.new()
	small.setup(_small_bridge("grass", {}))
	assert_eq(small.pending_count(), 4)
	assert_eq(small.process_budget(0.0), 1, "Mesmo sem orçamento sai ao menos um chunk.")
	assert_eq(small.pending_count(), 3)
	assert_eq(small.process_budget(HUGE_BUDGET_MS), 3, "Com orçamento de sobra a fila esvazia de uma vez.")
	assert_eq(small.pending_count(), 0)
	assert_eq(small.process_budget(HUGE_BUDGET_MS), 0)
	small.free()


func test_the_queue_starts_at_the_chunk_of_the_spawn_point_and_freeing_the_view_frees_the_nodes() -> void:
	var nodes_before: int = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var view: TerrainView = TerrainView.new()
	add_child(view)
	view.setup(_bridge)
	assert_eq(view.process_chunks(1), 1)
	assert_true(view.has_chunk(SPAWN_CHUNK) or view.has_chunk(SPAWN_CHUNK_NORTH), "O primeiro construído toca o ponto de nascimento.")
	assert_eq(view.built_count(), 1)
	assert_eq(view.process_chunks(7), 7)
	assert_eq(int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)), nodes_before + 1 + 8)
	view.free()
	assert_eq(int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)), nodes_before, "Liberar a view libera os 8 chunks.")


func test_body_faces_look_up_and_neighbors_of_the_same_step_share_their_border() -> void:
	var mesh: ArrayMesh = _view.chunk_node(HILL_CHUNK).mesh
	var vertices: PackedVector3Array = _vertices_of(mesh)
	var normals: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_NORMAL]
	var wrong: int = 0
	for first: int in range(0, _body_vertices(_layout, FINE), VERTICES_PER_TRIANGLE):
		var face: Vector3 = (vertices[first + 2] - vertices[first]).cross(vertices[first + 1] - vertices[first]).normalized()
		if face.y <= 0.0 or face.dot(normals[first]) < 1.0 - NORMAL_TOLERANCE:
			wrong += 1
	assert_eq(wrong, 0, "Toda face do corpo aponta para cima (ordem horária vista de cima) e concorda com a normal gravada.")
	var body: int = _body_vertices(_layout, FINE)
	var east: Dictionary[float, float] = _east_west_edge(mesh, _layout, true, body, false)
	var west: Dictionary[float, float] = _east_west_edge(_view.chunk_node(EAST_OF_HILL_CHUNK).mesh, _layout, false, body, false)
	assert_eq(east.size(), _layout.chunk_cells + 1)
	assert_eq(east, west, "Os nós da divisa são os mesmos: sem emenda entre chunks do mesmo passo.")


func test_skirt_covers_the_largest_gap_between_neighbors_of_different_steps_on_the_hill() -> void:
	var builder: TerrainChunkBuilder = TerrainChunkBuilder.new(_bridge, _layout)
	var fine: ArrayMesh = builder.build(HILL_CHUNK, FINE)
	var coarse: ArrayMesh = builder.build(EAST_OF_HILL_CHUNK, COARSE)
	assert_gt(_largest_gap(fine, coarse, _layout), TOLERANCE, "A borda da colina varia: o teste não é vazio.")
	assert_lte(_largest_uncovered_gap(fine, coarse, _layout), TOLERANCE, "A saia cobre a maior diferença.")
	var no_skirt_fine: ArrayMesh = builder.build(HILL_CHUNK, FINE, 0.0)
	var no_skirt_coarse: ArrayMesh = builder.build(EAST_OF_HILL_CHUNK, COARSE, 0.0)
	assert_gt(_largest_uncovered_gap(no_skirt_fine, no_skirt_coarse, _layout), TOLERANCE, "Sensibilidade: com saia de profundidade 0 o teste falha.")


func test_skirt_covers_a_steep_gap_of_one_and_a_half_meters_and_a_shallower_skirt_does_not() -> void:
	var bridge: SimBridge = _small_bridge("grass", {BUMP_NODE: BUMP_CM})
	var layout: SimBridge.TerrainLayoutReply = bridge.peek_terrain_layout()
	var builder: TerrainChunkBuilder = TerrainChunkBuilder.new(bridge, layout)
	var bump_m: float = float(BUMP_CM) / TerrainData.CM_PER_METER
	var fine: ArrayMesh = builder.build(Vector2i(0, 0), FINE)
	var coarse: ArrayMesh = builder.build(Vector2i(1, 0), COARSE)
	assert_almost_eq(_largest_gap(fine, coarse, layout), bump_m, TOLERANCE, "O passo 2 não enxerga o nó ímpar: sobra 1,5 m de fresta.")
	assert_true(TerrainChunkBuilder.SKIRT_DEPTH_M >= bump_m, "A profundidade da paleta de saias cobre 1,5 m.")
	assert_lte(_largest_uncovered_gap(fine, coarse, layout), TOLERANCE)
	var shallow_fine: ArrayMesh = builder.build(Vector2i(0, 0), FINE, SHALLOW_SKIRT_M)
	var shallow_coarse: ArrayMesh = builder.build(Vector2i(1, 0), COARSE, SHALLOW_SKIRT_M)
	assert_almost_eq(_largest_uncovered_gap(shallow_fine, shallow_coarse, layout), bump_m - SHALLOW_SKIRT_M, TOLERANCE, "Saia de 1 m deixa 0,5 m aberto.")


func test_surface_colors_follow_the_palette_and_unknown_surfaces_are_magenta() -> void:
	var spawn_colors: Dictionary[Color, bool] = _colors_of(_view.chunk_node(SPAWN_CHUNK).mesh)
	assert_true(_has_color(spawn_colors, TerrainPalette.PATH_COLOR) and _has_color(spawn_colors, TerrainPalette.GRASS_COLOR), "O nascimento tem caminho e grama.")
	var hill_colors: Dictionary[Color, bool] = _colors_of(_view.chunk_node(HILL_CHUNK).mesh)
	assert_true(_has_color(hill_colors, TerrainPalette.ROCK_COLOR), "A colina tem pedra.")
	assert_false(_has_color(spawn_colors, TerrainPalette.UNKNOWN_COLOR) or _has_color(hill_colors, TerrainPalette.UNKNOWN_COLOR), "O blockout não tem superfície sem cor.")
	assert_eq(TerrainPalette.color_for("lava"), Color(1.0, 0.0, 1.0))
	assert_eq(TerrainPalette.color_for(""), TerrainPalette.UNKNOWN_COLOR)
	var lava_bridge: SimBridge = _small_bridge("lava", {})
	var lava: ArrayMesh = TerrainChunkBuilder.new(lava_bridge, lava_bridge.peek_terrain_layout()).build(Vector2i.ZERO, FINE)
	var lava_colors: Dictionary[Color, bool] = _colors_of(lava)
	assert_eq(lava_colors.size(), 1)
	assert_true(_has_color(lava_colors, TerrainPalette.UNKNOWN_COLOR), "Id de superfície sem cor na paleta aparece magenta.")


func test_all_chunks_share_one_material_that_uses_the_vertex_color() -> void:
	var material: StandardMaterial3D = _view.chunk_node(Vector2i.ZERO).material_override as StandardMaterial3D
	assert_not_null(material)
	assert_true(material.vertex_color_use_as_albedo)
	assert_same(_view.chunk_node(HILL_CHUNK).material_override, material, "UM material para o terreno todo.")


func test_a_null_bridge_and_a_bridge_without_terrain_report_the_error_and_build_nothing() -> void:
	var view: TerrainView = TerrainView.new()
	view.setup(null)
	assert_push_error("ponte nula")
	assert_eq(view.pending_count(), 0)
	assert_eq(view.process_budget(HUGE_BUDGET_MS), 0)
	assert_false(view.build_chunk(Vector2i.ZERO))
	assert_push_error("view sem terreno")
	view.setup(SimBridge.new(null, null))
	assert_push_error(SimBridge.CODE_NO_TERRAIN)
	assert_eq(view.built_count(), 0)
	assert_eq(view.pending_count(), 0)
	view.free()


func test_invalid_chunk_and_step_requests_are_refused_visibly() -> void:
	var builder: TerrainChunkBuilder = TerrainChunkBuilder.new(_bridge, _layout)
	assert_null(builder.build(_layout.chunk_count, FINE))
	assert_push_error("fora da grade")
	assert_null(builder.build(Vector2i(-1, 0), FINE))
	assert_push_error("fora da grade")
	assert_null(builder.build(Vector2i.ZERO, 3))
	assert_push_error("passo 3 inválido")
	assert_null(builder.build(Vector2i.ZERO, 0))
	assert_push_error("passo 0 inválido")
