class_name PlazaGround
extends RefCounted
## O chão da praça e o que cresce ou repousa nele: relevo suave com caminho de terra (altura e peso do caminho, que também apoiam as peças de PlazaStructures), malha do chão facetada, as árvores, rochas e arbustos da variante (a A tem 12 árvores e 8 rochas em anel), e grama e flores por MultiMesh com vento por shader. Tudo procedural e facetado (cor por vértice, sem textura), variação por hash de inteiros (PlazaMeshKit); formas e lugares são [HIP] a calibrar olhando a cena. A altura de cada peça vem de um provedor `Callable(x, z) -> float` em coordenadas LOCAIS da raiz (ART-2a; sem provedor, o relevo da demonstração, `ground_height`), e `add_patch` faz a mancha de terra batida do jogo.

var _root: Node3D
var _materials: Dictionary[StringName, Material]
var _height: Callable
var _variant: PlazaVariants.Spec


## `variant` (ART-6a) traz a vegetação da praça: a mistura de árvores, rochas, arbustos, grama e flores; sem ficha vale a de hoje (a A).
func _init(root: Node3D, materials: Dictionary[StringName, Material], height_provider: Callable = Callable(), variant: PlazaVariants.Spec = null) -> void:
	_root = root
	_materials = materials
	_height = height_provider if height_provider.is_valid() else ground_height
	_variant = variant if variant != null else PlazaVariants.named(PlazaVariants.DEFAULT)


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


## Altura do chão em (x, z), em coordenadas locais da raiz, pelo provedor entregue na criação. O retorno de Callable.call é Variant (fronteira com o código de quem monta): a conversão para float é feita aqui, num lugar só.
func height_at(x: float, z: float) -> float:
	return _height.call(x, z)


## Cria o MeshInstance3D `node_name` com a transformação dada como filho da raiz da praça e o devolve.
func attach(mesh: Mesh, node_name: String, placement: Transform3D) -> MeshInstance3D:
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.transform = placement
	_root.add_child(instance)
	return instance


## Põe a malha no chão em (x, z) (a altura vem do provedor), com giro e escala.
func spawn(mesh: Mesh, node_name: String, spot: Vector2, yaw: float = 0.0, size: float = 1.0) -> MeshInstance3D:
	var placement: Transform3D = Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3.ONE * size), Vector3(spot.x, height_at(spot.x, spot.y), spot.y))
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
	return Vector3(x, height_at(x, z), z)


## Cor do triângulo: terra ocre no caminho e na clareira, oliva no resto, com manchas e variação por triângulo.
func _ground_color(point: Vector3, tri_index: int) -> Color:
	var patch: float = 0.5 + 0.5 * sin(point.x * 0.37 + 1.1) * sin(point.z * 0.29 + 2.3)
	var wear: float = path_weight(point.x, point.z) + (patch - 0.5) * 0.7 + (PlazaMeshKit.unit(tri_index, PlazaData.Channel.PATCH) - 0.5) * 0.3
	var dirt: Color = _variant.ground_dirt[0].lerp(_variant.ground_dirt[1], PlazaMeshKit.unit(tri_index, PlazaData.Channel.DIRT) * 0.7)
	var grass: Color = _variant.ground_greens[0].lerp(_variant.ground_greens[1], PlazaMeshKit.unit(tri_index, PlazaData.Channel.GRASS))
	return grass.lerp(dirt, smoothstep(0.35, 0.65, wear))


## A mancha de terra batida do jogo (ART-2a, ART-2c): um disco facetado de `radius_m` em torno da origem da raiz (PlazaData.PATCH_RINGS anéis de PlazaData.PATCH_SEGMENTS setores, do centro para fora), cada ponto na altura do provedor mais PlazaData.PATCH_LIFT_M, com a cor por vértice de `_patch_color` (o PlazaMeshKit só aceita uma cor por triângulo, que deixaria a roda de fatias). Não projeta sombra: colada no terreno, só a recebe (evita acne de sombra [HIP], a conferir no jogo). Devolve o nó `PlazaPatch`.
func add_patch(radius_m: float) -> MeshInstance3D:
	assert(radius_m > 0.0, "PlazaGround.add_patch: o raio da mancha deve ser positivo, recebeu %s" % radius_m)
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for ring: int in PlazaData.PATCH_RINGS:
		for sector: int in PlazaData.PATCH_SEGMENTS:
			var inner: Vector2i = Vector2i(ring, sector)
			var inner_next: Vector2i = Vector2i(ring, sector + 1)
			var outer: Vector2i = Vector2i(ring + 1, sector)
			var outer_next: Vector2i = Vector2i(ring + 1, sector + 1)
			if ring > 0:
				_patch_tri(surface, radius_m, [inner, outer_next, inner_next])
			_patch_tri(surface, radius_m, [inner, outer, outer_next])
	surface.set_material(_materials[&"solid"])
	var patch: MeshInstance3D = attach(surface.commit(), "PlazaPatch", Transform3D.IDENTITY)
	patch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return patch


## Triângulo da mancha de normal plana para cima, com a cor de cada vértice; `corners` traz (anel, setor) de cada ponto na ordem horária vista de cima (a face da frente do material).
func _patch_tri(surface: SurfaceTool, radius_m: float, corners: Array[Vector2i]) -> void:
	var points: Array[Vector3] = []
	for corner: Vector2i in corners:
		points.append(_patch_point(radius_m * corner.x / PlazaData.PATCH_RINGS, corner.y))
	var normal: Vector3 = (points[2] - points[0]).cross(points[1] - points[0]).normalized()
	for index: int in points.size():
		surface.set_normal(normal)
		surface.set_color(_patch_color(points[index], float(corners[index].x) / PlazaData.PATCH_RINGS))
		surface.add_vertex(points[index])


## Ponto do disco no raio dado; o setor volta ao zero depois do último, então a costura reaproveita o mesmo vértice.
func _patch_point(radius_m: float, sector: int) -> Vector3:
	var angle: float = TAU * (sector % PlazaData.PATCH_SEGMENTS) / PlazaData.PATCH_SEGMENTS
	var x: float = cos(angle) * radius_m
	var z: float = sin(angle) * radius_m
	return Vector3(x, height_at(x, z) + PlazaData.PATCH_LIFT_M, z)


## Cor do vértice `point`, a `reach` (0 a 1) do raio da mancha, contínua do centro para fora: terra batida escura e compacta no centro, terra seca mais clara até PlazaData.PATCH_DRY_REACH e, a partir de PlazaData.PATCH_FADE_FROM, cada vez mais cor do terreno (PlazaData.PATCH_RIM_COLOR), para a borda se perder no chão. Só depende da posição, então vértices que coincidem (o centro, a costura) têm a mesma cor.
func _patch_color(point: Vector3, reach: float) -> Color:
	var tint: float = _patch_noise(point.x, point.z) * PlazaData.PATCH_TINT
	var dirt: Color = PlazaData.DIRT_DARK.lerp(PlazaData.DIRT, smoothstep(0.0, PlazaData.PATCH_DRY_REACH, reach) + tint)
	return dirt.lerp(PlazaData.PATCH_RIM_COLOR, PlazaData.PATCH_RIM_GRASS * smoothstep(PlazaData.PATCH_FADE_FROM, 1.0, reach))


## Variação de tom em (x, z), de -0,5 a 0,5: ruído de valor (hash de inteiros nos cantos de uma grade de PlazaData.PATCH_NOISE_CELL_M metros, interpolado suave). Baixa frequência e sem relação com a malha de anéis e setores, que se adensa no centro e faria estrias.
func _patch_noise(x: float, z: float) -> float:
	var cell: Vector2 = Vector2(x, z) / PlazaData.PATCH_NOISE_CELL_M
	var base: Vector2i = Vector2i(cell.floor())
	var along: float = smoothstep(0.0, 1.0, cell.x - base.x)
	var near: float = lerpf(_patch_lattice(base.x, base.y), _patch_lattice(base.x + 1, base.y), along)
	var far: float = lerpf(_patch_lattice(base.x, base.y + 1), _patch_lattice(base.x + 1, base.y + 1), along)
	return lerpf(near, far, smoothstep(0.0, 1.0, cell.y - base.y)) - 0.5


func _patch_lattice(cell_x: int, cell_z: int) -> float:
	return PlazaMeshKit.unit(cell_x * PlazaData.PATCH_NOISE_STRIDE + cell_z, PlazaData.Channel.PATCH)


## As árvores da variante, nos lugares da ficha ou, sem lugares, em anel em volta da praça (as formas se repartem por índice).
func add_trees() -> void:
	var meshes: Array[ArrayMesh] = []
	for kind: int in _variant.tree_forms.size():
		meshes.append(_tree_mesh(kind))
	var count: int = _planted_count(_variant.tree_spots, PlazaData.TREE_COUNT)
	for index: int in count:
		var spot: Vector2 = _planted_spot(_variant.tree_spots, index, count, PlazaData.Channel.TREE_ANGLE, PlazaData.TREE_RADII_M, Vector2(0.0, TAU))
		spawn(meshes[index % meshes.size()], "Tree%d" % index, spot, PlazaMeshKit.between(index, PlazaData.Channel.TREE_YAW, 0.0, TAU), PlazaMeshKit.between(index, PlazaData.Channel.TREE_SCALE, 0.85, 1.15))


## A árvore do tipo `kind` da ficha: de cones empilhados ou redonda.
func _tree_mesh(kind: int) -> ArrayMesh:
	var kit: PlazaMeshKit = PlazaMeshKit.new()
	if _variant.tree_shapes[kind] == PlazaData.TreeShape.ROUND:
		_round_tree(kit, _variant.tree_forms[kind], _variant.tree_greens[kind], kind)
	else:
		_cone_tree(kit, _variant.tree_forms[kind], _variant.tree_greens[kind])
	return kit.finish(ArrayMesh.new(), _materials[&"solid"])


## Árvore de cones empilhados (tronco + copas que estreitam e clareiam para cima).
func _cone_tree(kit: PlazaMeshKit, spec: Vector3, green: Color) -> void:
	kit.frustum(Vector3(0.0, -0.3, 0.0), 0.3, 0.2, PlazaData.TRUNK_HEIGHT_M + 0.3, 6, PlazaData.TRUNK)
	for level: int in int(spec.x):
		var tone: Color = green.lightened(0.25 * level / spec.x)
		kit.frustum(Vector3(0.0, PlazaData.TRUNK_HEIGHT_M * 0.6 + level * spec.z * 0.62, 0.0), spec.y * (1.0 - 0.2 * level), 0.0, spec.z, 7, tone, level * 0.5)


## Árvore redonda: tronco fino e uma copa de esferoide facetado que começa um pouco dentro dele; `spec` = (altura do tronco, raio da copa, meia altura da copa) e `kind` varia a irregularidade.
func _round_tree(kit: PlazaMeshKit, spec: Vector3, green: Color, kind: int) -> void:
	kit.frustum(Vector3(0.0, -0.3, 0.0), 0.26, 0.18, spec.x + 0.3, 6, PlazaData.TRUNK)
	kit.blob(Vector3(0.0, spec.x + spec.z * PlazaData.CANOPY_SINK, 0.0), Vector3(spec.y, spec.z, spec.y), Vector3i(PlazaData.CANOPY_SHAPE.x, PlazaData.CANOPY_SHAPE.y, kind), PlazaData.CANOPY_JITTER, green)


## As rochas da variante, nos lugares da ficha ou, sem lugares, no arco da frente e das laterais.
func add_rocks() -> void:
	var count: int = _planted_count(_variant.rock_spots, PlazaData.ROCK_COUNT)
	for index: int in count:
		var radii: Vector3 = Vector3(PlazaMeshKit.between(index, PlazaData.Channel.ROCK_SIZE, 0.6, 1.1), PlazaMeshKit.between(index, PlazaData.Channel.ROCK_SIZE + 100, 0.4, 0.8), PlazaMeshKit.between(index, PlazaData.Channel.ROCK_SIZE + 200, 0.5, 0.9))
		var kit: PlazaMeshKit = PlazaMeshKit.new()
		kit.blob(Vector3(0.0, radii.y * 0.6, 0.0), radii, Vector3i(4, 6, index), 0.3, _variant.rock_color.darkened(PlazaMeshKit.unit(index, PlazaData.Channel.STONE) * 0.3))
		var spot: Vector2 = _planted_spot(_variant.rock_spots, index, count, PlazaData.Channel.ROCK_ANGLE, PlazaData.ROCK_RADII_M, PlazaData.ROCK_ARC)
		spawn(kit.finish(ArrayMesh.new(), _materials[&"solid"]), "Rock%d" % index, spot, PlazaMeshKit.between(index, PlazaData.Channel.ROCK_YAW, 0.0, TAU), _variant.rock_size)


## Os arbustos (ART-6a, só nos lugares da ficha): esferoide baixo e achatado, de baixo custo, no verde de uma das árvores.
func add_bushes() -> void:
	for index: int in _variant.bush_spots.size():
		var radius: float = PlazaMeshKit.between(index, PlazaData.Channel.BUSH_SIZE, PlazaData.BUSH_RADII_M.x, PlazaData.BUSH_RADII_M.y)
		var radii: Vector3 = Vector3(radius, radius * PlazaData.BUSH_FLATTEN, radius)
		var green: Color = _variant.tree_greens[index % _variant.tree_greens.size()].lightened(0.15)
		var kit: PlazaMeshKit = PlazaMeshKit.new()
		kit.blob(Vector3(0.0, radii.y * 0.6, 0.0), radii, Vector3i(PlazaData.BUSH_SHAPE.x, PlazaData.BUSH_SHAPE.y, index), PlazaData.BUSH_JITTER, green)
		spawn(kit.finish(ArrayMesh.new(), _materials[&"solid"]), "Bush%d" % index, _variant.bush_spots[index], PlazaMeshKit.between(index, PlazaData.Channel.BUSH_YAW, 0.0, TAU))


## Quantos itens a ficha planta: um por lugar dela ou, sem lugares, `ring_count` (o anel de hoje).
func _planted_count(spots: Array[Vector2], ring_count: int) -> int:
	return spots.size() if not spots.is_empty() else ring_count


## O lugar do item `index`: o da ficha ou, sem lugares, o do anel de hoje.
func _planted_spot(spots: Array[Vector2], index: int, count: int, channel: int, radii: Vector2, arc: Vector2) -> Vector2:
	return spots[index] if not spots.is_empty() else _ring_spot(index, count, channel, radii, arc)


## Ponto de um anel: o item `index` de `count` ocupa a sua fatia do arco (rad) com jitter no ângulo (canal) e no raio (canal + 1).
func _ring_spot(index: int, count: int, channel: int, radii: Vector2, arc: Vector2) -> Vector2:
	var angle: float = lerpf(arc.x, arc.y, (float(index) + PlazaMeshKit.unit(index, channel) * 0.6) / count)
	return Vector2(cos(angle), sin(angle)) * PlazaMeshKit.between(index, channel + 1, radii.x, radii.y)


## Grama (um MultiMesh) e as flores (um MultiMesh por cor), sempre depois de tudo o mais, como na montagem original; as quantidades, o tamanho do tufo e as cores vêm da ficha.
func add_scatter() -> void:
	_scatter("Grass", _tuft_mesh(), _variant.grass_count, 0, &"grass", _variant.grass_size)
	var flower: ArrayMesh = _flower_mesh()
	for index: int in _variant.flower_colors.size():
		_scatter("Flowers%d" % index, flower, _variant.flowers_per_color, (index + 1) * PlazaData.SCATTER_KEY_STRIDE, StringName("flower%d" % index), Vector2(0.8, 1.3))


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
		multimesh.set_instance_transform(index, Transform3D(turned, Vector3(spot.x, height_at(spot.x, spot.y), spot.y)))
	var instance: MultiMeshInstance3D = MultiMeshInstance3D.new()
	instance.name = node_name
	instance.multimesh = multimesh
	instance.material_override = _materials[material_key]
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_root.add_child(instance)


## Sorteia (por hash) até PlazaData.SCATTER_ATTEMPTS posições e fica com a primeira aceita; onde há mais terra, menos chance.
func _scatter_spot(key: int) -> Vector2:
	var spot: Vector2 = Vector2.ZERO
	var extent: Vector2 = _variant.scatter_half_m
	for attempt: int in PlazaData.SCATTER_ATTEMPTS:
		var candidate: int = key * PlazaData.SCATTER_ATTEMPTS + attempt
		spot = Vector2(PlazaMeshKit.between(candidate, PlazaData.Channel.SCATTER_X, -extent.x, extent.x), PlazaMeshKit.between(candidate, PlazaData.Channel.SCATTER_Z, -extent.y, extent.y))
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
