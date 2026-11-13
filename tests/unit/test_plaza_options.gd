extends GutTest

## ART-2a, montagem parcial e altura injetável da praça (sem renderizar): cada opção de `PlazaBuilder.build` liga ou desliga só a sua parte, a altura das peças e da mancha de terra batida vem do provedor entregue (aqui um plano inclinado) e as montagens são determinísticas.
const TOLERANCE: float = 0.001
const SLOPE_BASE_M: float = 5.0
const SLOPE_PER_M: float = 0.1
const PATCH_RADIUS_M: float = 9.0
## Contagens de hoje: filhos da raiz e triângulos de malha com tudo ligado (a impressão digital da ART-1 deu 6348 triângulos), e triângulos só das estruturas (medidos na ART-2a; somados ao chão, à vegetação e às casas dão o total).
const ALL_CHILDREN: int = 70
const ALL_TRIANGLES: int = 6348
const STRUCTURE_TRIANGLES: int = 2544
## Um nó que só existe quando a parte correspondente está ligada.
const MARKERS: Dictionary[StringName, String] = {&"ground": "Ground", &"vegetation": "Tree0", &"structures": "Stall0", &"houses": "House0"}

var _root: Node3D


func _slope(x: float, _z: float) -> float:
	return SLOPE_BASE_M + SLOPE_PER_M * x


func _new_root() -> Node3D:
	_root = Node3D.new()
	add_child_autofree(_root)
	return _root


func _build(options: PlazaBuilder.Options = null) -> PlazaBuilder.Built:
	return PlazaBuilder.new().build(_new_root(), options)


func _only(part: StringName) -> PlazaBuilder.Options:
	var options: PlazaBuilder.Options = PlazaBuilder.Options.new()
	options.has_ground = part == &"ground"
	options.has_vegetation = part == &"vegetation"
	options.has_structures = part == &"structures"
	options.has_houses = part == &"houses"
	return options


func _sloped(options: PlazaBuilder.Options) -> PlazaBuilder.Options:
	options.height_provider = _slope
	return options


func _triangles() -> int:
	var vertices: int = 0
	for node: Node in _root.find_children("*", "MeshInstance3D", true, false):
		vertices += (node as MeshInstance3D).mesh.get_faces().size()
	return int(vertices / 3.0)


## Resumo da geometria e da ordem dos nós; o renderer sem janela descarta as posições das instâncias do MultiMesh, então delas só entram o nome e a contagem.
func _digest() -> int:
	var digest: int = 0
	for node: Node in _root.find_children("*", "MeshInstance3D", true, false):
		var instance: MeshInstance3D = node as MeshInstance3D
		digest = hash([digest, instance.name, instance.transform])
		for surface: int in instance.mesh.get_surface_count():
			digest = hash([digest, instance.mesh.surface_get_arrays(surface)])
	for node: Node in _root.find_children("*", "MultiMeshInstance3D", true, false):
		digest = hash([digest, node.name, (node as MultiMeshInstance3D).multimesh.instance_count])
	return digest


func _patch() -> MeshInstance3D:
	return PlazaGround.new(_new_root(), PlazaMaterials.create(), _slope).add_patch(PATCH_RADIUS_M)


func _rgb(color: Color) -> Vector3:
	return Vector3(color.r, color.g, color.b)


## Quanto as cores têm de grama: 0 na terra média da paleta e 1 na grama média, medido pela projeção no eixo terra-grama (não depende do tom sorteado de cada quadro).
func _grass_share(colors: PackedColorArray) -> float:
	var dirt: Vector3 = _rgb(PlazaData.DIRT.lerp(PlazaData.DIRT_DARK, 0.5))
	var axis: Vector3 = _rgb(PlazaData.GRASS.lerp(PlazaData.GRASS_DARK, 0.5)) - dirt
	var total: float = 0.0
	for color: Color in colors:
		total += (_rgb(color) - dirt).dot(axis) / axis.length_squared()
	return total / colors.size()


func test_default_options_build_what_build_always_built() -> void:
	_build()
	var plain: int = _digest()
	assert_eq(_root.get_child_count(), ALL_CHILDREN, "filhos da raiz de hoje")
	assert_eq(_triangles(), ALL_TRIANGLES, "triângulos de malha de hoje")
	_build(PlazaBuilder.Options.new())
	assert_eq(_digest(), plain, "opções padrão montam o mesmo que build(root)")
	var invalid: PlazaBuilder.Options = PlazaBuilder.Options.new()
	invalid.height_provider = Callable()
	_build(invalid)
	assert_eq(_digest(), plain, "provedor inválido cai no relevo da demonstração")
	assert_almost_eq(PlazaGround.new(_root, PlazaMaterials.create()).height_at(3.0, 4.0), PlazaGround.ground_height(3.0, 4.0), TOLERANCE, "sem provedor, o relevo da demonstração")


func test_only_structures_builds_just_the_stalls_props_posts_bunting_torches_and_well() -> void:
	var built: PlazaBuilder.Built = _build(_only(&"structures"))
	var stalls: int = PlazaData.STALL_SPOTS.size()
	assert_eq(_root.get_child_count(), stalls * (1 + PlazaData.PROP_KINDS.size()) + 2 * PlazaData.LAMP_SPOTS.size() + PlazaData.TORCH_SPOTS.size() + 1, "barracas, adereços, postes com fio, tochas e poço")
	assert_eq(_triangles(), STRUCTURE_TRIANGLES, "triângulos das estruturas")
	assert_eq(built.lamp_lights.size() + built.torch_lights.size(), PlazaData.LAMP_SPOTS.size() + PlazaData.TORCH_SPOTS.size(), "as luzes continuam entregues")
	for pattern: String in ["Ground", "Tree*", "Rock*", "House*", "Grass", "Flowers*"]:
		assert_eq(_root.find_children(pattern, "", true, false).size(), 0, "sem %s" % pattern)


func test_each_switch_builds_only_its_own_part_and_the_parts_add_up_to_the_whole() -> void:
	var children: int = 0
	var triangles: int = 0
	for part: StringName in MARKERS:
		_build(_only(part))
		for other: StringName in MARKERS:
			assert_eq(_root.has_node(MARKERS[other]), other == part, "%s: o marcador de %s" % [part, other])
		children += _root.get_child_count()
		triangles += _triangles()
	_build()
	assert_eq(children, _root.get_child_count(), "os filhos das partes somam o todo")
	assert_eq(triangles, _triangles(), "os triângulos das partes somam o todo")
	_build(_only(&""))
	assert_eq(_root.get_child_count(), 0, "tudo desligado não cria nó")


func test_every_piece_sits_at_the_height_the_provider_gives() -> void:
	_build(_sloped(PlazaBuilder.Options.new()))
	var checked: int = 0
	for node: Node in _root.get_children():
		if not node is MeshInstance3D or node.name == &"Ground" or String(node.name).begins_with("Bunting"):
			continue
		var piece: Node3D = node as Node3D
		assert_almost_eq(piece.position.y, _slope(piece.position.x, piece.position.z), TOLERANCE, "%s na altura do provedor" % piece.name)
		checked += 1
	assert_eq(checked, ALL_CHILDREN - 1 - PlazaData.LAMP_SPOTS.size() - 1 - PlazaData.FLOWER_COLORS.size(), "barracas, adereços, postes, tochas, poço, casas, árvores e rochas conferidos")
	var points: PackedVector3Array = ((_root.get_node("Ground") as MeshInstance3D).mesh as ArrayMesh).surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var worst: float = 0.0
	for point: Vector3 in points:
		worst = maxf(worst, absf(point.y - _slope(point.x, point.z)))
	assert_lt(worst, TOLERANCE, "o chão acompanha o provedor")


func test_patch_follows_the_slope_and_sits_above_the_provider_by_the_lift() -> void:
	var patch: MeshInstance3D = _patch()
	assert_eq(patch.name, &"PlazaPatch", "nome do nó")
	assert_eq(patch.get_parent(), _root, "filho da raiz")
	assert_eq(patch.cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "colada no terreno, não projeta sombra")
	var points: PackedVector3Array = (patch.mesh as ArrayMesh).surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	assert_eq(int(points.size() / 3.0), PlazaData.PATCH_SEGMENTS * (2 * PlazaData.PATCH_RINGS - 1), "triângulos do disco")
	var worst: float = 0.0
	var reach: float = 0.0
	for point: Vector3 in points:
		worst = maxf(worst, absf(point.y - _slope(point.x, point.z) - PlazaData.PATCH_LIFT_M))
		reach = maxf(reach, Vector2(point.x, point.z).length())
	assert_lt(worst, TOLERANCE, "cada vértice fica PATCH_LIFT_M acima do provedor")
	assert_almost_eq(reach, PATCH_RADIUS_M, TOLERANCE, "o disco tem o raio pedido")
	var downward: int = 0
	for first: int in range(0, points.size(), 3):
		if (points[first + 2] - points[first]).cross(points[first + 1] - points[first]).y <= 0.0:
			downward += 1
	assert_eq(downward, 0, "todo triângulo vira para cima (o material corta a face de trás)")


func test_patch_rim_blends_into_the_grass_and_two_patches_are_identical() -> void:
	var arrays: Array = (_patch().mesh as ArrayMesh).surface_get_arrays(0)
	var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	var fan: PackedColorArray = colors.slice(0, 3 * PlazaData.PATCH_SEGMENTS)
	var rim: PackedColorArray = colors.slice(colors.size() - 6 * PlazaData.PATCH_SEGMENTS)
	assert_lt(absf(_grass_share(fan)), PlazaData.PATCH_RIM_GRASS * 0.5, "o centro é terra")
	assert_gt(_grass_share(rim), _grass_share(fan) + PlazaData.PATCH_RIM_GRASS * 0.5, "o anel de fora tem grama na cor")
	assert_eq((_patch().mesh as ArrayMesh).surface_get_arrays(0), arrays, "duas manchas iguais")


func test_two_partial_builds_with_the_same_provider_are_identical() -> void:
	_build(_sloped(_only(&"structures")))
	var first: int = _digest()
	assert_ne(first, 0, "a montagem produziu geometria")
	_build(_sloped(_only(&"structures")))
	assert_eq(_digest(), first, "duas montagens iguais")
	_build(_only(&"structures"))
	assert_ne(_digest(), first, "outro provedor, outra altura")
