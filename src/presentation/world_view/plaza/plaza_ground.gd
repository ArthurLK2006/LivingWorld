class_name PlazaGround
extends RefCounted
## O chão da praça e o que cresce ou repousa nele: relevo suave com caminho de terra (altura e peso do caminho, que também apoiam as peças de PlazaStructures), malha do chão facetada, 12 árvores, rochas, e grama e flores por MultiMesh com vento por shader. Tudo procedural e facetado (cor por vértice, sem textura), variação por hash de inteiros (PlazaMeshKit); formas e lugares são [HIP] a calibrar olhando a cena.

var _root: Node3D
var _materials: Dictionary[StringName, Material]


func _init(root: Node3D, materials: Dictionary[StringName, Material]) -> void:
	_root = root
	_materials = materials


## Altura do relevo em (x, z): ondas suaves que crescem fora da clareira do poço.
static func ground_height(x: float, z: float) -> float:
	var swell: float = sin(x * 0.23 + 1.3) * cos(z * 0.19 + 4.1) + 0.5 * sin((x + z) * 0.41 + 2.2)
	var open_field: float = clampf((Vector2(x, z).length() - PlazaData.RELIEF_FLAT_RADIUS_M) / PlazaData.RELIEF_RAMP_M, 0.15, 1.0)
	return swell * PlazaData.RELIEF_AMPLITUDE_M * open_field


## Quanto de caminho de terra há em (x, z): 1 no caminho e na clareira do poço, 0 na grama.
static func path_weight(x: float, z: float) -> float:
	var lane: float = absf(x - PlazaData.PATH_SWAY_M * sin(z * PlazaData.PATH_WAVE))
	var on_lane: float = 1.0 - smoothstep(PlazaData.PATH_HALF_WIDTH_M, PlazaData.PATH_HALF_WIDTH_M + PlazaData.PATH_EDGE_M, lane)
	var on_plaza: float = 1.0 - smoothstep(PlazaData.PLAZA_RADIUS_M, PlazaData.PLAZA_RADIUS_M + PlazaData.PATH_EDGE_M, Vector2(x, z).length())
	return maxf(on_lane, on_plaza)


## Cria o MeshInstance3D `node_name` com a transformação dada como filho da raiz da praça e o devolve.
func attach(mesh: Mesh, node_name: String, placement: Transform3D) -> MeshInstance3D:
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.transform = placement
	_root.add_child(instance)
	return instance


## Põe a malha no chão em (x, z) (a altura vem do relevo), com giro e escala.
func spawn(mesh: Mesh, node_name: String, spot: Vector2, yaw: float = 0.0, size: float = 1.0) -> MeshInstance3D:
	var placement: Transform3D = Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3.ONE * size), Vector3(spot.x, ground_height(spot.x, spot.y), spot.y))
	return attach(mesh, node_name, placement)


## Malha do chão: grade de células de 1 m (PlazaData.GROUND_HALF_M metros para cada lado do centro), 2 triângulos por célula com as diagonais alternadas, sem o escurecimento da base e com a cor do terreno por triângulo.
func add_floor() -> void:
	var kit: PlazaMeshKit = PlazaMeshKit.new()
	kit.is_shaded = false
	var cells: int = PlazaData.GROUND_HALF_M * 2
	for row: int in cells:
		for col: int in cells:
			var x: float = float(col - PlazaData.GROUND_HALF_M)
			var z: float = float(row - PlazaData.GROUND_HALF_M)
			var corners: Array[Vector3] = [_ground_point(x, z), _ground_point(x + 1.0, z), _ground_point(x + 1.0, z + 1.0), _ground_point(x, z + 1.0)]
			var split: PackedInt32Array = PlazaData.DIAGONAL_A if (row + col) % 2 == 0 else PlazaData.DIAGONAL_B
			for half: int in 2:
				var a: Vector3 = corners[split[half * 3]]
				var b: Vector3 = corners[split[half * 3 + 1]]
				var c: Vector3 = corners[split[half * 3 + 2]]
				var center: Vector3 = (a + b + c) / 3.0
				kit.tri(a, b, c, _ground_color(center, (row * cells + col) * 2 + half), Vector3(center.x, PlazaData.GROUND_FLOOR_M, center.z))
	attach(kit.finish(ArrayMesh.new(), _materials[&"solid"]), "Ground", Transform3D.IDENTITY)


func _ground_point(x: float, z: float) -> Vector3:
	return Vector3(x, ground_height(x, z), z)


## Cor do triângulo: terra ocre no caminho e na clareira, oliva no resto, com manchas e variação por triângulo.
func _ground_color(point: Vector3, tri_index: int) -> Color:
	var patch: float = 0.5 + 0.5 * sin(point.x * 0.37 + 1.1) * sin(point.z * 0.29 + 2.3)
	var wear: float = path_weight(point.x, point.z) + (patch - 0.5) * 0.7 + (PlazaMeshKit.unit(tri_index, PlazaData.Channel.PATCH) - 0.5) * 0.3
	var dirt: Color = PlazaData.DIRT.lerp(PlazaData.DIRT_DARK, PlazaMeshKit.unit(tri_index, PlazaData.Channel.DIRT) * 0.7)
	var grass: Color = PlazaData.GRASS.lerp(PlazaData.GRASS_DARK, PlazaMeshKit.unit(tri_index, PlazaData.Channel.GRASS))
	return grass.lerp(dirt, smoothstep(0.35, 0.65, wear))


## As árvores, em anel em volta da praça (as variações de malha se repartem por índice).
func add_trees() -> void:
	var meshes: Array[ArrayMesh] = []
	for variant: int in PlazaData.TREE_VARIANTS.size():
		meshes.append(_tree_mesh(variant))
	for index: int in PlazaData.TREE_COUNT:
		var spot: Vector2 = _ring_spot(index, PlazaData.TREE_COUNT, PlazaData.Channel.TREE_ANGLE, PlazaData.TREE_RADII_M, Vector2(0.0, TAU))
		spawn(meshes[index % meshes.size()], "Tree%d" % index, spot, PlazaMeshKit.between(index, PlazaData.Channel.TREE_YAW, 0.0, TAU), PlazaMeshKit.between(index, PlazaData.Channel.TREE_SCALE, 0.85, 1.15))


## Árvore de cones empilhados (tronco + copas que estreitam e clareiam para cima).
func _tree_mesh(variant: int) -> ArrayMesh:
	var spec: Vector3 = PlazaData.TREE_VARIANTS[variant]
	var kit: PlazaMeshKit = PlazaMeshKit.new()
	kit.frustum(Vector3(0.0, -0.3, 0.0), 0.3, 0.2, PlazaData.TRUNK_HEIGHT_M + 0.3, 6, PlazaData.TRUNK)
	for level: int in int(spec.x):
		var tone: Color = PlazaData.TREE_GREENS[variant].lightened(0.25 * level / spec.x)
		kit.frustum(Vector3(0.0, PlazaData.TRUNK_HEIGHT_M * 0.6 + level * spec.z * 0.62, 0.0), spec.y * (1.0 - 0.2 * level), 0.0, spec.z, 7, tone, level * 0.5)
	return kit.finish(ArrayMesh.new(), _materials[&"solid"])


## As rochas, no arco da frente e das laterais.
func add_rocks() -> void:
	for index: int in PlazaData.ROCK_COUNT:
		var radii: Vector3 = Vector3(PlazaMeshKit.between(index, PlazaData.Channel.ROCK_SIZE, 0.6, 1.1), PlazaMeshKit.between(index, PlazaData.Channel.ROCK_SIZE + 100, 0.4, 0.8), PlazaMeshKit.between(index, PlazaData.Channel.ROCK_SIZE + 200, 0.5, 0.9))
		var kit: PlazaMeshKit = PlazaMeshKit.new()
		kit.blob(Vector3(0.0, radii.y * 0.6, 0.0), radii, Vector3i(4, 6, index), 0.3, PlazaData.STONE.darkened(PlazaMeshKit.unit(index, PlazaData.Channel.STONE) * 0.3))
		var spot: Vector2 = _ring_spot(index, PlazaData.ROCK_COUNT, PlazaData.Channel.ROCK_ANGLE, PlazaData.ROCK_RADII_M, PlazaData.ROCK_ARC)
		spawn(kit.finish(ArrayMesh.new(), _materials[&"solid"]), "Rock%d" % index, spot, PlazaMeshKit.between(index, PlazaData.Channel.ROCK_YAW, 0.0, TAU))


## Ponto de um anel: o item `index` de `count` ocupa a sua fatia do arco (rad) com jitter no ângulo (canal) e no raio (canal + 1).
func _ring_spot(index: int, count: int, channel: int, radii: Vector2, arc: Vector2) -> Vector2:
	var angle: float = lerpf(arc.x, arc.y, (float(index) + PlazaMeshKit.unit(index, channel) * 0.6) / count)
	return Vector2(cos(angle), sin(angle)) * PlazaMeshKit.between(index, channel + 1, radii.x, radii.y)


## Grama (um MultiMesh) e as flores (um MultiMesh por cor), sempre depois de tudo o mais, como na montagem original.
func add_scatter() -> void:
	_scatter("Grass", _tuft_mesh(), PlazaData.GRASS_COUNT, 0, &"grass", Vector2(0.7, 1.4))
	var flower: ArrayMesh = _flower_mesh()
	for index: int in PlazaData.FLOWER_COLORS.size():
		_scatter("Flowers%d" % index, flower, PlazaData.FLOWERS_PER_COLOR, (index + 1) * PlazaData.SCATTER_KEY_STRIDE, StringName("flower%d" % index), Vector2(0.8, 1.3))


## Espalha `count` instâncias do `mesh` (MultiMesh, sem sombra) pelo chão, longe do caminho de terra, com giro e tamanho por hash.
func _scatter(node_name: String, mesh: ArrayMesh, count: int, key_offset: int, material_key: StringName, size_range: Vector2) -> void:
	var multimesh: MultiMesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	multimesh.instance_count = count
	for index: int in count:
		var key: int = key_offset + index
		var spot: Vector2 = _scatter_spot(key)
		var fade: float = 1.0 - smoothstep(PlazaData.SCATTER_FADE_FROM, 1.0, path_weight(spot.x, spot.y))
		var size: float = PlazaMeshKit.between(key, PlazaData.Channel.SCATTER_SIZE, size_range.x, size_range.y) * fade
		var turned: Basis = Basis(Vector3.UP, PlazaMeshKit.between(key, PlazaData.Channel.SCATTER_YAW, 0.0, TAU)).scaled(Vector3.ONE * size)
		multimesh.set_instance_transform(index, Transform3D(turned, Vector3(spot.x, ground_height(spot.x, spot.y), spot.y)))
	var instance: MultiMeshInstance3D = MultiMeshInstance3D.new()
	instance.name = node_name
	instance.multimesh = multimesh
	instance.material_override = _materials[material_key]
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_root.add_child(instance)


## Sorteia (por hash) até PlazaData.SCATTER_ATTEMPTS posições e fica com a primeira aceita; onde há mais terra, menos chance.
func _scatter_spot(key: int) -> Vector2:
	var spot: Vector2 = Vector2.ZERO
	var extent: float = PlazaData.GROUND_HALF_M - 0.5
	for attempt: int in PlazaData.SCATTER_ATTEMPTS:
		var candidate: int = key * PlazaData.SCATTER_ATTEMPTS + attempt
		spot = Vector2(PlazaMeshKit.between(candidate, PlazaData.Channel.SCATTER_X, -extent, extent), PlazaMeshKit.between(candidate, PlazaData.Channel.SCATTER_Z, -extent, extent))
		if PlazaMeshKit.unit(candidate, PlazaData.Channel.SCATTER_ACCEPT) > path_weight(spot.x, spot.y):
			return spot
	return spot


## Tufo de lâminas cruzadas (PlazaData.BLADES_PER_TUFT lâminas giradas em torno do eixo vertical); alfa 0 = cor de grama.
func _tuft_mesh() -> ArrayMesh:
	var points: PackedVector3Array = PackedVector3Array()
	var indices: PackedInt32Array = PackedInt32Array()
	var colors: PackedColorArray = PackedColorArray()
	for blade: int in PlazaData.BLADES_PER_TUFT:
		var first: int = points.size()
		for point: Vector3 in PlazaData.BLADE_POINTS:
			points.append(point.rotated(Vector3.UP, PI * blade / PlazaData.BLADES_PER_TUFT))
			colors.append(Color(0.0, 0.0, 0.0, 0.0))
		for corner: int in PlazaData.BLADE_INDICES:
			indices.append(first + corner)
	return _foliage_mesh(points, indices, colors)


## Flor: caule fino (alfa 0) e cabeça em pirâmide (alfa 1, recebe a cor de acento do material).
func _flower_mesh() -> ArrayMesh:
	var head: float = PlazaData.FLOWER_STEM_M
	var points: PackedVector3Array = [Vector3(-0.012, 0.0, 0.0), Vector3(0.012, 0.0, 0.0), Vector3(0.0, head, 0.0), Vector3(-0.07, head, -0.07), Vector3(0.07, head, -0.07), Vector3(0.07, head, 0.07), Vector3(-0.07, head, 0.07), Vector3(0.0, head + 0.1, 0.0)]
	var indices: PackedInt32Array = [0, 1, 2, 3, 4, 7, 4, 5, 7, 5, 6, 7, 6, 3, 7]
	var colors: PackedColorArray = PackedColorArray()
	for index: int in points.size():
		colors.append(Color(0.0, 0.0, 0.0, 0.0 if index < 3 else 1.0))
	return _foliage_mesh(points, indices, colors)


func _foliage_mesh(points: PackedVector3Array, indices: PackedInt32Array, colors: PackedColorArray) -> ArrayMesh:
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh: ArrayMesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
