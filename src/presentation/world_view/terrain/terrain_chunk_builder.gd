class_name TerrainChunkBuilder
extends RefCounted
## Monta a malha low-poly de UM chunk do terreno. Lê alturas e superfícies SÓ pela ponte (SimBridge), ponto a
## ponto (decisão D3). Convenções de nós, células e chunks em docs/modules/world.md; contrato em
## docs/modules/presentation.md. O chunk (ci, cj) começa na célula (ci·chunk_cells, cj·chunk_cells) e a malha
## usa coordenadas LOCAIS ao chunk (a origem do MeshInstance3D é o canto de menor x e menor z).

## Passo = células por quadrado. O jogo usa o fino; o grosso existe para a escolha por distância (LW-040).
const STEP_FINE: int = 1
const STEP_COARSE: int = 2
const SUPPORTED_STEPS: Array[int] = [STEP_FINE, STEP_COARSE]
## Profundidade das saias [HIP]: uma célula do blockout (2 m). Tem de ser maior que o maior desnível entre os
## perfis de borda de dois vizinhos de passos diferentes (medido em todas as bordas do blockout: no máximo
## 2,5 cm) e bem menor que a colina (30 m); mais fundo só criaria geometria escondida sob o chão.
const SKIRT_DEPTH_M: float = 2.0
const VERTICES_PER_TRIANGLE: int = 3
const TRIANGLES_PER_QUAD: int = 2
const SKIRT_SIDES: int = 4
## Fração do quadrado onde se consulta a superfície: o centro.
const QUAD_CENTER: float = 0.5
## Saias usam normal para cima: se uma fresta deixar a saia aparecer, ela tem o brilho do chão ao lado.
const SKIRT_NORMAL: Vector3 = Vector3.UP

var _bridge: SimBridge
var _layout: SimBridge.TerrainLayoutReply


func _init(bridge: SimBridge, layout: SimBridge.TerrainLayoutReply) -> void:
	_bridge = bridge
	_layout = layout


## Vértices de um chunk com `q = chunk_cells / passo` quadrados por lado: 3 por triângulo, 2 triângulos por
## quadrado (q²) e, nas 4 bordas, 2 triângulos por segmento (4q) de saia.
static func expected_vertex_count(chunk_cells: int, step: int) -> int:
	var quads: int = IntMath.floor_div(chunk_cells, step)
	return VERTICES_PER_TRIANGLE * TRIANGLES_PER_QUAD * (quads * quads + SKIRT_SIDES * quads)


## Vértices só do corpo da malha (sem saias): 3 por triângulo, 2 triângulos por quadrado.
static func expected_body_vertex_count(chunk_cells: int, step: int) -> int:
	var quads: int = IntMath.floor_div(chunk_cells, step)
	return VERTICES_PER_TRIANGLE * TRIANGLES_PER_QUAD * quads * quads


func chunk_size_m() -> float:
	return float(_layout.chunk_cells) * _layout.cell_size_m


## Canto de menor x e menor z do chunk, em metros do mundo (y = 0).
func chunk_origin_m(coord: Vector2i) -> Vector3:
	return Vector3(float(coord.x) * chunk_size_m(), 0.0, float(coord.y) * chunk_size_m())


## Malha do chunk, ou nulo (depois de push_error) se o pedido for inválido ou uma consulta à ponte falhar.
func build(coord: Vector2i, step: int, skirt_depth_m: float = SKIRT_DEPTH_M) -> ArrayMesh:
	var problem: String = _request_problem(coord, step)
	if not problem.is_empty():
		push_error("TerrainChunkBuilder.build: %s" % problem)
		return null
	var quads: int = IntMath.floor_div(_layout.chunk_cells, step)
	var step_m: float = float(step) * _layout.cell_size_m
	var origin: Vector3 = chunk_origin_m(coord)
	var heights: PackedFloat32Array = _sample_heights(origin, quads, step_m)
	var colors: PackedColorArray = _sample_colors(origin, quads, step_m)
	if heights.is_empty() or colors.is_empty():
		return null
	var buffers: MeshBuffers = MeshBuffers.new(expected_vertex_count(_layout.chunk_cells, step))
	_add_body(buffers, heights, colors, quads, step_m)
	_add_skirts(buffers, heights, colors, quads, step_m, skirt_depth_m)
	return buffers.commit()


## Triângulos do corpo do chunk para a colisão (LW-039), SEMPRE no passo fino, qualquer que seja o passo da malha
## desenhada (decisão D6). Usa a mesma `_add_body` da malha: a mesma triangulação. Vazio (depois de push_error)
## se o pedido for inválido ou uma consulta à ponte falhar.
func build_collision_faces(coord: Vector2i) -> PackedVector3Array:
	var problem: String = _request_problem(coord, STEP_FINE)
	if not problem.is_empty():
		push_error("TerrainChunkBuilder.build_collision_faces: %s" % problem)
		return PackedVector3Array()
	var quads: int = _layout.chunk_cells
	var heights: PackedFloat32Array = _sample_heights(chunk_origin_m(coord), quads, _layout.cell_size_m)
	if heights.is_empty():
		return PackedVector3Array()
	var buffers: MeshBuffers = MeshBuffers.new(expected_body_vertex_count(_layout.chunk_cells, STEP_FINE))
	var unused_colors: PackedColorArray = PackedColorArray()
	unused_colors.resize(quads * quads)
	_add_body(buffers, heights, unused_colors, quads, _layout.cell_size_m)
	return buffers.vertices()


func _request_problem(coord: Vector2i, step: int) -> String:
	var count: Vector2i = _layout.chunk_count
	if coord.x < 0 or coord.y < 0 or coord.x >= count.x or coord.y >= count.y:
		return "chunk (%d, %d) fora da grade de %d x %d chunks; esperado x de 0 a %d e z de 0 a %d." % [coord.x, coord.y, count.x, count.y, count.x - 1, count.y - 1]
	if not SUPPORTED_STEPS.has(step) or _layout.chunk_cells % step != 0:
		return "passo %d inválido; esperado 1 ou 2 e que divida as %d células do chunk." % [step, _layout.chunk_cells]
	return ""


## Alturas nos (q+1)² nós do chunk, por linhas de z. Vazio (depois de push_error) se uma consulta falhar.
func _sample_heights(origin: Vector3, quads: int, step_m: float) -> PackedFloat32Array:
	var nodes_per_side: int = quads + 1
	var heights: PackedFloat32Array = PackedFloat32Array()
	heights.resize(nodes_per_side * nodes_per_side)
	for node_z: int in range(nodes_per_side):
		for node_x: int in range(nodes_per_side):
			var x: float = minf(origin.x + float(node_x) * step_m, _layout.size_m.x)
			var z: float = minf(origin.z + float(node_z) * step_m, _layout.size_m.y)
			var reply: SimBridge.HeightReply = _bridge.peek_height(x, z)
			if not reply.result.ok:
				push_error("TerrainChunkBuilder: altura indisponível em (x=%s, z=%s): %s" % [str(x), str(z), reply.result.message])
				return PackedFloat32Array()
			heights[node_z * nodes_per_side + node_x] = reply.height_m
	return heights


## Cor de cada quadrado, por linhas de z, pela superfície no CENTRO do quadrado. Vazio se uma consulta falhar.
func _sample_colors(origin: Vector3, quads: int, step_m: float) -> PackedColorArray:
	var colors: PackedColorArray = PackedColorArray()
	colors.resize(quads * quads)
	for quad_z: int in range(quads):
		for quad_x: int in range(quads):
			var x: float = minf(origin.x + (float(quad_x) + QUAD_CENTER) * step_m, _layout.size_m.x)
			var z: float = minf(origin.z + (float(quad_z) + QUAD_CENTER) * step_m, _layout.size_m.y)
			var reply: SimBridge.SurfaceReply = _bridge.peek_surface(x, z)
			if not reply.result.ok:
				push_error("TerrainChunkBuilder: superfície indisponível em (x=%s, z=%s): %s" % [str(x), str(z), reply.result.message])
				return PackedColorArray()
			colors[quad_z * quads + quad_x] = TerrainPalette.color_for(reply.surface_id)
	return colors


## Dois triângulos por quadrado, na mesma diagonal em todo o terreno (a=canto de menor x e z, d=o oposto).
func _add_body(buffers: MeshBuffers, heights: PackedFloat32Array, colors: PackedColorArray, quads: int, step_m: float) -> void:
	var nodes_per_side: int = quads + 1
	for quad_z: int in range(quads):
		for quad_x: int in range(quads):
			var near_row: int = quad_z * nodes_per_side + quad_x
			var far_row: int = near_row + nodes_per_side
			var left: float = float(quad_x) * step_m
			var right: float = float(quad_x + 1) * step_m
			var near: float = float(quad_z) * step_m
			var far: float = float(quad_z + 1) * step_m
			var a: Vector3 = Vector3(left, heights[near_row], near)
			var b: Vector3 = Vector3(right, heights[near_row + 1], near)
			var c: Vector3 = Vector3(left, heights[far_row], far)
			var d: Vector3 = Vector3(right, heights[far_row + 1], far)
			var color: Color = colors[quad_z * quads + quad_x]
			buffers.add_triangle(a, b, d, color)
			buffers.add_triangle(a, d, c, color)


func _add_skirts(buffers: MeshBuffers, heights: PackedFloat32Array, colors: PackedColorArray, quads: int, step_m: float, depth_m: float) -> void:
	var last: int = quads
	var side_m: float = float(quads) * step_m
	for i: int in range(quads):
		var along: float = float(i) * step_m
		var next_along: float = float(i + 1) * step_m
		# Norte (z = 0) e sul (z = lado): bordas ao longo de x. Oeste (x = 0) e leste (x = lado): ao longo de z.
		var north: int = i
		var south: int = last * (quads + 1) + i
		var west: int = i * (quads + 1)
		var east: int = west + last
		buffers.add_wall(Vector3(along, heights[north], 0.0), Vector3(next_along, heights[north + 1], 0.0), depth_m, Vector3(0.0, 0.0, -1.0), colors[i])
		buffers.add_wall(Vector3(along, heights[south], side_m), Vector3(next_along, heights[south + 1], side_m), depth_m, Vector3(0.0, 0.0, 1.0), colors[(quads - 1) * quads + i])
		buffers.add_wall(Vector3(0.0, heights[west], along), Vector3(0.0, heights[west + quads + 1], next_along), depth_m, Vector3(-1.0, 0.0, 0.0), colors[i * quads])
		buffers.add_wall(Vector3(side_m, heights[east], along), Vector3(side_m, heights[east + quads + 1], next_along), depth_m, Vector3(1.0, 0.0, 0.0), colors[i * quads + quads - 1])


## Vértices, normais e cores de um chunk, preenchidos em ordem (sem índices: vértices não compartilhados).
class MeshBuffers:
	extends RefCounted

	var _vertices: PackedVector3Array = PackedVector3Array()
	var _normals: PackedVector3Array = PackedVector3Array()
	var _colors: PackedColorArray = PackedColorArray()
	var _used: int = 0

	func _init(vertex_count: int) -> void:
		_vertices.resize(vertex_count)
		_normals.resize(vertex_count)
		_colors.resize(vertex_count)

	## Triângulo (a, b, c) com normal de face. No Godot a face da frente é a de ordem horária; a normal
	## geométrica de (a, b, c) nessa ordem é (c - a) x (b - a).
	func add_triangle(a: Vector3, b: Vector3, c: Vector3, color: Color) -> void:
		_push(a, b, c, (c - a).cross(b - a).normalized(), color)

	## Parede vertical sob o segmento top_a-top_b, com a frente voltada para `outward` (para fora do chunk).
	func add_wall(top_a: Vector3, top_b: Vector3, depth_m: float, outward: Vector3, color: Color) -> void:
		var drop: Vector3 = Vector3(0.0, depth_m, 0.0)
		var low_a: Vector3 = top_a - drop
		var low_b: Vector3 = top_b - drop
		if (low_b - top_a).cross(top_b - top_a).dot(outward) < 0.0:
			_push(top_b, top_a, low_a, SKIRT_NORMAL, color)
			_push(top_b, low_a, low_b, SKIRT_NORMAL, color)
		else:
			_push(top_a, top_b, low_b, SKIRT_NORMAL, color)
			_push(top_a, low_b, low_a, SKIRT_NORMAL, color)

	func vertices() -> PackedVector3Array:
		return _vertices

	func commit() -> ArrayMesh:
		# Array sem tipo: é a forma que a API de malhas do Godot exige (um slot por tipo de dado do vértice).
		var arrays: Array = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = _vertices
		arrays[Mesh.ARRAY_NORMAL] = _normals
		arrays[Mesh.ARRAY_COLOR] = _colors
		var mesh: ArrayMesh = ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		return mesh

	func _push(a: Vector3, b: Vector3, c: Vector3, normal: Vector3, color: Color) -> void:
		_set_vertex(a, normal, color)
		_set_vertex(b, normal, color)
		_set_vertex(c, normal, color)

	func _set_vertex(position: Vector3, normal: Vector3, color: Color) -> void:
		_vertices[_used] = position
		_normals[_used] = normal
		_colors[_used] = color
		_used += 1
