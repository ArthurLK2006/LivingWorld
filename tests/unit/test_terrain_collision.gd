extends GutTest
## LW-039: colisão do terreno por chunk. Teste de física sem janela: raios lançados de cima devolvem a altura que a
## ponte informa (peek_height). Motor de física em uso: GodotPhysics3D (physics/3d/physics_engine = DEFAULT em
## project.godot, que resolve para ele no Godot 4.7.2; confirmado nesta tarefa pelos tipos de RID alocados).

const BLOCKOUT_DIR: String = "res://data/world"
## Tolerância entre o impacto e peek_height (metros). A malha de triângulos difere da interpolação bilinear do
## terreno, dentro de uma célula, por no máximo |h00 - h10 - h01 + h11| / 4 (docs/modules/world.md, convenção 5):
## no blockout o maior valor é 0,0075 m (medido nas 262.144 células). O resto é precisão de float32 (cerca de
## 0,1 mm a 1.000 m). 1 cm cobre os dois com folga e está longe do limite de 25 cm do envio.
const HEIGHT_TOLERANCE_M: float = 0.01
## O raio nasce acima do topo da colina (40 m) e termina abaixo do fundo do vale (-2 m).
const RAY_FROM_Y_M: float = 100.0
const RAY_TO_Y_M: float = -50.0
const SEAM_STEP_M: float = 1.0
const BORDER_EPSILON_M: float = 0.001
const DISPLACEMENT_M: float = 0.5
const PHYSICS_FRAMES_TO_SETTLE: int = 2
## Retângulo de chunks (inclusive) cujas divisas internas são varridas: a região da colina, onde a altura varia.
const SEAM_FIRST_CHUNK: Vector2i = Vector2i(9, 3)
const SEAM_LAST_CHUNK: Vector2i = Vector2i(12, 6)
## Os 20 pontos de teste (x, z em metros); o nascimento vem da ponte. Emendas: duas divisas de chunk, uma divisa
## no topo da colina e dois encontros de quatro chunks.
const SEAM_POINTS: Array[Vector2] = [Vector2(64.0, 100.0), Vector2(300.0, 128.0), Vector2(704.0, 300.0), Vector2(640.0, 320.0), Vector2(128.0, 512.0)]
const SLOPE_POINTS: Array[Vector2] = [Vector2(610.3, 300.7), Vector2(700.9, 390.1), Vector2(790.4, 330.6), Vector2(700.2, 215.8)]
const VALLEY_POINTS: Array[Vector2] = [Vector2(300.4, 750.7), Vector2(230.9, 800.2)]
const PATH_POINTS: Array[Vector2] = [Vector2(400.7, 513.0), Vector2(800.3, 512.9), Vector2(50.2, 511.1), Vector2(1000.2, 514.4)]
const PLAIN_POINTS: Array[Vector2] = [Vector2(200.5, 200.5), Vector2(900.1, 900.9), Vector2(500.3, 100.7), Vector2(950.2, 600.4)]
## Chunk que nenhum dos outros testes constrói.
const FAR_CHUNK: Vector2i = Vector2i(15, 0)
const CHUNK_CENTER: Vector2 = Vector2(0.5, 0.5)
const VERTICES_PER_TRIANGLE: int = 3
const TRIANGLES_PER_QUAD: int = 2
## Nós de um chunk: MeshInstance3D, StaticBody3D e CollisionShape3D.
const NODES_PER_CHUNK: int = 3

var _bridge: SimBridge
var _layout: SimBridge.TerrainLayoutReply
var _view: TerrainView
var _chunk_size_m: float = 0.0
var _moved_body: StaticBody3D
var _moved_origin: Vector3 = Vector3.ZERO
var _removed_body: StaticBody3D
var _removed_parent: Node


func before_all() -> void:
	var loaded: TerrainLoader.LoadResult = TerrainLoader.load_dir(BLOCKOUT_DIR)
	assert_true(loaded.result.ok, loaded.result.message)
	_bridge = SimBridge.new(null, loaded.terrain)
	_layout = _bridge.peek_terrain_layout()
	_chunk_size_m = float(_layout.chunk_cells) * _layout.cell_size_m
	_view = TerrainView.new()
	add_child(_view)
	_view.setup(_bridge)
	_view.set_process(false) # só os chunks pedidos aqui: sem construir a fila inteira durante os testes
	for point: Vector2 in _sample_points():
		_build_touching(point.x, point.y)
	for chunk_z: int in range(SEAM_FIRST_CHUNK.y, SEAM_LAST_CHUNK.y + 1):
		for chunk_x: int in range(SEAM_FIRST_CHUNK.x, SEAM_LAST_CHUNK.x + 1):
			assert_true(_view.build_chunk(Vector2i(chunk_x, chunk_z)))


## Desfaz os estragos propositais dos testes de sensibilidade (a view é compartilhada entre os testes).
func after_each() -> void:
	if _moved_body != null:
		_moved_body.position = _moved_origin
		_moved_body = null
	if _removed_body != null:
		_removed_parent.add_child(_removed_body)
		_removed_body = null


func after_all() -> void:
	_view.free()


func _shape_of(body: StaticBody3D) -> ConcavePolygonShape3D:
	var collision_shape: CollisionShape3D = body.get_child(0) as CollisionShape3D
	return collision_shape.shape as ConcavePolygonShape3D


func _sample_points() -> Array[Vector2]:
	var spawn: Vector3 = _bridge.peek_spawn_point().point
	var points: Array[Vector2] = [Vector2(spawn.x, spawn.z)]
	points.append_array(SEAM_POINTS)
	points.append_array(SLOPE_POINTS)
	points.append_array(VALLEY_POINTS)
	points.append_array(PATH_POINTS)
	points.append_array(PLAIN_POINTS)
	return points


func _chunk_of(point: Vector2) -> Vector2i:
	return Vector2i(floori(point.x / _chunk_size_m), floori(point.y / _chunk_size_m))


## Constrói os chunks que tocam o ponto (numa divisa, os dois lados).
func _build_touching(x: float, z: float) -> void:
	for offset_x: float in [-BORDER_EPSILON_M, BORDER_EPSILON_M]:
		for offset_z: float in [-BORDER_EPSILON_M, BORDER_EPSILON_M]:
			var coord: Vector2i = _chunk_of(Vector2(x + offset_x, z + offset_z))
			if coord.x >= 0 and coord.y >= 0 and coord.x < _layout.chunk_count.x and coord.y < _layout.chunk_count.y and not _view.has_chunk(coord):
				assert_true(_view.build_chunk(coord), "Chunk %s não foi construído." % str(coord))


func _settle() -> void:
	for frame: int in range(PHYSICS_FRAMES_TO_SETTLE):
		await get_tree().physics_frame


## Altura do impacto de um raio vertical em (x, z) contra a camada do terreno, ou NAN se não acertar nada.
func _ray_height(x: float, z: float) -> float:
	var layer_mask: int = 1 << (TerrainView.TERRAIN_PHYSICS_LAYER - 1)
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(Vector3(x, RAY_FROM_Y_M, z), Vector3(x, RAY_TO_Y_M, z), layer_mask)
	var hit: Dictionary = get_viewport().find_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return NAN
	var position: Vector3 = hit["position"]
	return position.y


## Texto do problema (vazio se a altura do impacto bate com peek_height dentro da tolerância).
func _height_problem(x: float, z: float) -> String:
	var expected: float = _bridge.peek_height(x, z).height_m
	var hit_y: float = _ray_height(x, z)
	if is_nan(hit_y):
		return "raio sem impacto em (x=%s, z=%s): chunk %s sem corpo de colisão ou buraco na colisão" % [str(x), str(z), str(_chunk_of(Vector2(x, z)))]
	if absf(hit_y - expected) > HEIGHT_TOLERANCE_M:
		return "em (x=%s, z=%s) o impacto está a %s m e peek_height diz %s m (tolerância %s m)" % [str(x), str(z), str(hit_y), str(expected), str(HEIGHT_TOLERANCE_M)]
	return ""


func _problems_at(points: Array[Vector2]) -> PackedStringArray:
	var problems: PackedStringArray = PackedStringArray()
	for point: Vector2 in points:
		var problem: String = _height_problem(point.x, point.y)
		if not problem.is_empty():
			problems.append(problem)
	return problems


func test_ray_height_matches_the_bridge_on_20_points() -> void:
	await _settle()
	var points: Array[Vector2] = _sample_points()
	assert_eq(points.size(), 20)
	assert_gte(SEAM_POINTS.size(), 4)
	assert_gte(SLOPE_POINTS.size(), 4)
	assert_gte(VALLEY_POINTS.size(), 2)
	var problems: PackedStringArray = _problems_at(points)
	assert_true(problems.is_empty(), "\n".join(problems))


func test_every_built_chunk_has_a_full_resolution_body_on_the_terrain_layer() -> void:
	var full_resolution_vertices: int = VERTICES_PER_TRIANGLE * TRIANGLES_PER_QUAD * _layout.chunk_cells * _layout.chunk_cells
	for chunk_z: int in range(_layout.chunk_count.y):
		for chunk_x: int in range(_layout.chunk_count.x):
			var coord: Vector2i = Vector2i(chunk_x, chunk_z)
			if not _view.has_chunk(coord):
				continue
			var body: StaticBody3D = _view.chunk_body(coord)
			assert_not_null(body, "O chunk %s está construído mas não tem corpo de colisão." % str(coord))
			if body == null:
				continue
			assert_true(body.get_collision_layer_value(TerrainView.TERRAIN_PHYSICS_LAYER), "Chunk %s fora da camada do terreno." % str(coord))
			assert_eq(body.collision_mask, 0)
			assert_eq(_shape_of(body).get_faces().size(), full_resolution_vertices, "Chunk %s: colisão sempre em resolução cheia." % str(coord))


func test_rays_exactly_on_the_chunk_borders_hit_without_holes() -> void:
	await _settle()
	var points: Array[Vector2] = []
	var first: Vector2 = Vector2(SEAM_FIRST_CHUNK) * _chunk_size_m
	var steps: Vector2i = Vector2i((Vector2(SEAM_LAST_CHUNK - SEAM_FIRST_CHUNK + Vector2i.ONE) * _chunk_size_m / SEAM_STEP_M))
	for border: int in range(SEAM_FIRST_CHUNK.x + 1, SEAM_LAST_CHUNK.x + 1):
		for step: int in range(steps.y + 1):
			points.append(Vector2(float(border) * _chunk_size_m, first.y + float(step) * SEAM_STEP_M))
	for border: int in range(SEAM_FIRST_CHUNK.y + 1, SEAM_LAST_CHUNK.y + 1):
		for step: int in range(steps.x + 1):
			points.append(Vector2(first.x + float(step) * SEAM_STEP_M, float(border) * _chunk_size_m))
	assert_gt(points.size(), 1000)
	var problems: PackedStringArray = _problems_at(points)
	assert_true(problems.is_empty(), "%d raios sobre divisas sem acerto ou fora da tolerância; o primeiro: %s" % [problems.size(), problems[0] if not problems.is_empty() else ""])


func test_collision_stays_at_full_resolution_when_the_drawn_mesh_uses_a_coarser_step() -> void:
	var coord: Vector2i = _chunk_of(Vector2(200.5, 200.5))
	assert_true(_view.build_chunk(coord, TerrainChunkBuilder.STEP_COARSE))
	assert_eq(_view.chunk_node(coord).mesh.surface_get_array_len(0), TerrainChunkBuilder.expected_vertex_count(_layout.chunk_cells, TerrainChunkBuilder.STEP_COARSE), "A malha desenhada é a do passo 2.")
	await _settle()
	var inside: Array[Vector2] = [Vector2(200.5, 200.5), Vector2(193.7, 210.3)]
	var problems: PackedStringArray = _problems_at(inside)
	assert_true(problems.is_empty(), "\n".join(problems))
	assert_eq(_shape_of(_view.chunk_body(coord)).get_faces().size(), VERTICES_PER_TRIANGLE * TRIANGLES_PER_QUAD * _layout.chunk_cells * _layout.chunk_cells, "O corpo continua na resolução cheia.")
	assert_true(_view.build_chunk(coord, TerrainChunkBuilder.STEP_FINE))


func test_sensitivity_a_displaced_collision_fails_the_height_check() -> void:
	await _settle()
	var spawn: Vector3 = _bridge.peek_spawn_point().point
	assert_eq(_height_problem(spawn.x, spawn.z), "", "Antes de deslocar, o ponto de nascimento passa.")
	_moved_body = _view.chunk_body(_chunk_of(Vector2(spawn.x, spawn.z)))
	_moved_origin = _moved_body.position
	_moved_body.position += Vector3(0.0, DISPLACEMENT_M, 0.0)
	await _settle()
	var problem: String = _height_problem(spawn.x, spawn.z)
	assert_false(problem.is_empty(), "Com a colisão deslocada o teste TEM de falhar.")
	assert_string_contains(problem, "peek_height diz")


func test_a_chunk_without_a_body_makes_the_ray_miss_with_a_clear_message() -> void:
	await _settle()
	var point: Vector2 = Vector2(400.7, 513.0)
	assert_eq(_height_problem(point.x, point.y), "")
	_removed_body = _view.chunk_body(_chunk_of(point))
	_removed_parent = _removed_body.get_parent()
	_removed_parent.remove_child(_removed_body)
	await _settle()
	var problem: String = _height_problem(point.x, point.y)
	assert_string_contains(problem, "sem corpo de colisão")
	assert_string_contains(problem, str(_chunk_of(point)))


func test_freeing_the_view_frees_its_bodies_from_the_physics_space() -> void:
	var far: Vector2 = (Vector2(FAR_CHUNK) + CHUNK_CENTER) * _chunk_size_m
	await _settle()
	assert_true(is_nan(_ray_height(far.x, far.y)), "Antes: nada no chunk distante.")
	var nodes_before: int = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var view: TerrainView = TerrainView.new()
	add_child(view)
	view.setup(_bridge)
	view.set_process(false)
	assert_true(view.build_chunk(FAR_CHUNK))
	await _settle()
	assert_eq(_height_problem(far.x, far.y), "", "Com o chunk construído o raio acerta.")
	assert_eq(int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)), nodes_before + 1 + NODES_PER_CHUNK)
	view.free()
	await _settle()
	assert_eq(int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)), nodes_before, "Liberar a view libera os nós do chunk e do corpo.")
	assert_true(is_nan(_ray_height(far.x, far.y)), "O corpo saiu do espaço de física junto com o chunk.")
