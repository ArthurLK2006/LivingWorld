class_name Sp4aTerrainOwn
extends Node3D
## SPIKE descartável (LW-033/SP4a). Variante "terreno próprio": malha por chunk gerada por script
## a partir de Sp4aTerrainData, colisão por chunk (HeightMapShape3D) e carga/descarga por
## distância ao foco. API do HeightMapShape3D (centrado na origem local, índice = z*largura+x,
## 1 unidade por amostra) confirmada por teste curto com raycast antes de escrever este arquivo
## (ver relatório da LW-033, seção 4).

const SURFACE_COLORS: Dictionary = {
	"plain": Color(0.33, 0.56, 0.22),
	"path": Color(0.62, 0.52, 0.35),
	"hill_top": Color(0.55, 0.55, 0.55),
	"hill_slope": Color(0.45, 0.4, 0.28),
	"valley": Color(0.22, 0.3, 0.26),
}

var terrain_data: Sp4aTerrainData
var vertex_spacing: float = 2.0
var view_distance_chunks: int = 5

var _chunks: Dictionary = {}  # Vector2i -> Node3D
var last_chunk_build_times_usec: Array[int] = []


func setup(data: Sp4aTerrainData, spacing: float, view_distance: int) -> void:
	terrain_data = data
	vertex_spacing = spacing
	view_distance_chunks = view_distance


func chunk_node_count() -> int:
	return _chunks.size()


func clear_all() -> void:
	for coord: Vector2i in _chunks.keys():
		var node: Node3D = _chunks[coord]
		node.queue_free()
	_chunks.clear()


## Carrega os chunks dentro de view_distance_chunks de world_pos e descarrega o resto.
func set_focus(world_pos: Vector3) -> void:
	var focus_chunk: Vector2i = Vector2i(
		floori(world_pos.x / Sp4aTerrainData.CHUNK_SIZE), floori(world_pos.z / Sp4aTerrainData.CHUNK_SIZE)
	)
	var needed: Dictionary = {}
	for dz: int in range(-view_distance_chunks, view_distance_chunks + 1):
		for dx: int in range(-view_distance_chunks, view_distance_chunks + 1):
			var coord: Vector2i = Vector2i(focus_chunk.x + dx, focus_chunk.y + dz)
			if coord.x >= 0 and coord.y >= 0 and coord.x < Sp4aTerrainData.CHUNKS_PER_SIDE and coord.y < Sp4aTerrainData.CHUNKS_PER_SIDE:
				needed[coord] = true
	for coord: Vector2i in _chunks.keys():
		if not needed.has(coord):
			var node: Node3D = _chunks[coord]
			node.queue_free()
			_chunks.erase(coord)
	for coord: Vector2i in needed.keys():
		if not _chunks.has(coord):
			var start_usec: int = Time.get_ticks_usec()
			var chunk: Node3D = _build_chunk(coord.x, coord.y)
			last_chunk_build_times_usec.append(Time.get_ticks_usec() - start_usec)
			add_child(chunk)
			_chunks[coord] = chunk


func _build_chunk(cx: int, cz: int) -> Node3D:
	var samples_per_side: int = int(Sp4aTerrainData.CHUNK_SIZE / vertex_spacing) + 1
	var origin_x: float = cx * Sp4aTerrainData.CHUNK_SIZE
	var origin_z: float = cz * Sp4aTerrainData.CHUNK_SIZE

	var heights: PackedFloat32Array = PackedFloat32Array()
	heights.resize(samples_per_side * samples_per_side)
	var positions: Array[Vector3] = []
	positions.resize(samples_per_side * samples_per_side)
	var colors: Array[Color] = []
	colors.resize(samples_per_side * samples_per_side)

	for zi: int in range(samples_per_side):
		for xi: int in range(samples_per_side):
			var world_x: float = origin_x + xi * vertex_spacing
			var world_z: float = origin_z + zi * vertex_spacing
			var height: float = terrain_data.get_height(world_x, world_z)
			var index: int = zi * samples_per_side + xi
			heights[index] = height
			positions[index] = Vector3(xi * vertex_spacing, height, zi * vertex_spacing)
			colors[index] = SURFACE_COLORS.get(terrain_data.get_surface(world_x, world_z), Color.WHITE)

	var surface_tool: SurfaceTool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for zi: int in range(samples_per_side - 1):
		for xi: int in range(samples_per_side - 1):
			var a: int = zi * samples_per_side + xi
			var b: int = zi * samples_per_side + xi + 1
			var c: int = (zi + 1) * samples_per_side + xi
			var d: int = (zi + 1) * samples_per_side + xi + 1
			# Vencimento (a,c,b)/(b,c,d) dava normais para BAIXO (confirmado: as 18.432 normais de
			# um chunk de teste apontavam todas para y<0, achado na revisão da Parte A — por isso
			# o chão ficava invisível de cima, só visível de baixo/de raspão). Corrigido para
			# (a,b,c)/(b,d,c) e reconferido: normais passaram a apontar para cima (ver teste
			# test_chunk_normals_point_up em test_sp4a_sanity.gd).
			_add_triangle(surface_tool, positions, colors, a, b, c)
			_add_triangle(surface_tool, positions, colors, b, d, c)
	surface_tool.generate_normals()
	var mesh: ArrayMesh = surface_tool.commit()

	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true

	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material

	var shape: HeightMapShape3D = HeightMapShape3D.new()
	shape.map_width = samples_per_side
	shape.map_depth = samples_per_side
	shape.map_data = heights
	var collision_shape: CollisionShape3D = CollisionShape3D.new()
	collision_shape.shape = shape
	var span: float = (samples_per_side - 1) * vertex_spacing
	collision_shape.position = Vector3(span / 2.0, 0.0, span / 2.0)
	collision_shape.scale = Vector3(vertex_spacing, 1.0, vertex_spacing)

	var body: StaticBody3D = StaticBody3D.new()
	body.add_child(collision_shape)

	var chunk_root: Node3D = Node3D.new()
	chunk_root.name = "Chunk_%d_%d" % [cx, cz]
	chunk_root.position = Vector3(origin_x, 0.0, origin_z)
	chunk_root.add_child(mesh_instance)
	chunk_root.add_child(body)
	return chunk_root


static func _add_triangle(surface_tool: SurfaceTool, positions: Array[Vector3], colors: Array[Color], i0: int, i1: int, i2: int) -> void:
	surface_tool.set_color(colors[i0])
	surface_tool.add_vertex(positions[i0])
	surface_tool.set_color(colors[i1])
	surface_tool.add_vertex(positions[i1])
	surface_tool.set_color(colors[i2])
	surface_tool.add_vertex(positions[i2])
