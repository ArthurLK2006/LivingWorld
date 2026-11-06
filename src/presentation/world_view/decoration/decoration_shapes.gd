class_name DecorationShapes
extends RefCounted
## Formas simples, feitas em código (sem arquivos de modelo nem importação): árvore = tronco (prisma de 6 lados) +
## copa (cone de 8 lados); pedra = poliedro baixo e achatado. Cor de vértice; normais por face. Valores [HIP].

const TRUNK_SIDES: int = 6
const TRUNK_RADIUS_M: float = 0.25
const TRUNK_HEIGHT_M: float = 1.4
const TRUNK_COLOR: Color = Color(0.36, 0.25, 0.15)
const CROWN_SIDES: int = 8
const CROWN_RADIUS_M: float = 1.3
const CROWN_BASE_M: float = 1.2
const CROWN_TOP_M: float = 4.2
const CROWN_COLOR: Color = Color(0.18, 0.42, 0.18)
## Pedra: anel de 6 pontos a meia altura, com raio alternado (aspecto irregular), e dois vértices (topo e base).
const ROCK_SIDES: int = 6
const ROCK_RADIUS_M: float = 0.9
const ROCK_RADIUS_ALTERNATE: float = 0.75
const ROCK_RING_M: float = 0.3
const ROCK_TOP_M: float = 0.6
const ROCK_COLOR: Color = Color(0.46, 0.46, 0.48)
## Fração da altura do cone, a partir da base, onde fica o centro de massa (para orientar as faces para fora).
const CONE_CENTER_FRACTION: float = 0.25
const HALF: float = 0.5
const TRIANGLES_PER_QUAD: int = 2


static func tree_mesh() -> ArrayMesh:
	var buffers: Buffers = Buffers.new()
	var trunk_center: Vector3 = Vector3(0.0, TRUNK_HEIGHT_M * HALF, 0.0)
	for side: int in range(TRUNK_SIDES):
		var low_a: Vector3 = _ring_point(side, TRUNK_SIDES, TRUNK_RADIUS_M, 0.0)
		var low_b: Vector3 = _ring_point(side + 1, TRUNK_SIDES, TRUNK_RADIUS_M, 0.0)
		var high_a: Vector3 = _ring_point(side, TRUNK_SIDES, TRUNK_RADIUS_M, TRUNK_HEIGHT_M)
		var high_b: Vector3 = _ring_point(side + 1, TRUNK_SIDES, TRUNK_RADIUS_M, TRUNK_HEIGHT_M)
		buffers.add_triangle(low_a, low_b, high_b, TRUNK_COLOR, trunk_center)
		buffers.add_triangle(low_a, high_b, high_a, TRUNK_COLOR, trunk_center)
	var crown_center: Vector3 = Vector3(0.0, CROWN_BASE_M + (CROWN_TOP_M - CROWN_BASE_M) * CONE_CENTER_FRACTION, 0.0)
	var apex: Vector3 = Vector3(0.0, CROWN_TOP_M, 0.0)
	var base_middle: Vector3 = Vector3(0.0, CROWN_BASE_M, 0.0)
	for side: int in range(CROWN_SIDES):
		var base_a: Vector3 = _ring_point(side, CROWN_SIDES, CROWN_RADIUS_M, CROWN_BASE_M)
		var base_b: Vector3 = _ring_point(side + 1, CROWN_SIDES, CROWN_RADIUS_M, CROWN_BASE_M)
		buffers.add_triangle(base_a, base_b, apex, CROWN_COLOR, crown_center)
		buffers.add_triangle(base_a, base_b, base_middle, CROWN_COLOR, crown_center)
	return buffers.commit()


static func rock_mesh() -> ArrayMesh:
	var buffers: Buffers = Buffers.new()
	var center: Vector3 = Vector3(0.0, ROCK_RING_M, 0.0)
	var top: Vector3 = Vector3(0.0, ROCK_TOP_M, 0.0)
	var bottom: Vector3 = Vector3.ZERO
	for side: int in range(ROCK_SIDES):
		var ring_a: Vector3 = _ring_point(side, ROCK_SIDES, _rock_radius(side), ROCK_RING_M)
		var ring_b: Vector3 = _ring_point(side + 1, ROCK_SIDES, _rock_radius(side + 1), ROCK_RING_M)
		buffers.add_triangle(ring_a, ring_b, top, ROCK_COLOR, center)
		buffers.add_triangle(ring_a, ring_b, bottom, ROCK_COLOR, center)
	return buffers.commit()


static func _rock_radius(side: int) -> float:
	return ROCK_RADIUS_M if side % 2 == 0 else ROCK_RADIUS_M * ROCK_RADIUS_ALTERNATE


static func _ring_point(side: int, sides: int, radius: float, height: float) -> Vector3:
	var angle: float = TAU * float(side % sides) / float(sides)
	return Vector3(cos(angle) * radius, height, sin(angle) * radius)


## Triângulos de um sólido convexo; cada face é orientada para FORA do centro dado (normal por face).
class Buffers:
	extends RefCounted

	var _vertices: PackedVector3Array = PackedVector3Array()
	var _normals: PackedVector3Array = PackedVector3Array()
	var _colors: PackedColorArray = PackedColorArray()

	func add_triangle(a: Vector3, b: Vector3, c: Vector3, color: Color, solid_center: Vector3) -> void:
		var normal: Vector3 = (c - a).cross(b - a).normalized()
		var centroid: Vector3 = (a + b + c) / 3.0
		var corners: Array[Vector3] = [a, b, c]
		if normal.dot(centroid - solid_center) < 0.0:
			normal = -normal
			corners = [a, c, b]
		for corner: Vector3 in corners:
			_vertices.append(corner)
			_normals.append(normal)
			_colors.append(color)

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
