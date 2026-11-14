extends GutTest

## ART-6a, a vegetação de cada variante da praça (sem renderizar, chão plano): a A segue com o anel de árvores e rochas de sempre; B e C diferem dela e entre si em pelo menos três medidas da vegetação; a mesma ficha dá a mesma vegetação; e as árvores, rochas e arbustos de B e C ficam dentro do retângulo de encaixe e fora das barracas, dos adereços, dos postes, das tochas e da peça central. As posições das instâncias de grama e flores o renderer sem janela descarta: delas só entram contagens e cores.
const IDS: Array[StringName] = [&"a", &"b", &"c"]
const PAIRS: Array[Vector2i] = [Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 2)]
const MIN_DIFFERENT_ASPECTS: int = 3
const TOLERANCE_M: float = 0.001
const PLANTS: Array[String] = ["Tree*", "Rock*", "Bush*"]
const OBSTACLES: Array[String] = ["Stall?", "Crate*", "Barrel*", "Sack*", "LampPost*", "Torch*"]
## O ponto mais baixo do fio de bandeirolas (no meio do vão de 22 m, com a bandeirola pendurada): as árvores baixas de B ficam abaixo dele.
const BUNTING_LOW_M: float = 3.6

var _root: Node3D


func _flat(_x: float, _z: float) -> float:
	return 0.0


## Monta a variante com a vegetação, sem chão nem casas, num chão plano (como o jogo, mas com a vegetação sempre ligada).
func _plant(variant_id: StringName) -> void:
	_root = Node3D.new()
	add_child_autofree(_root)
	var options: PlazaBuilder.Options = PlazaBuilder.Options.new()
	options.variant = PlazaVariants.named(variant_id)
	options.has_ground = false
	options.has_houses = false
	options.height_provider = _flat
	PlazaBuilder.new().build(_root, options)


func _meshes(pattern: String) -> Array[Node]:
	return _root.find_children(pattern, "MeshInstance3D", true, false)


func _box(node: Node) -> AABB:
	var instance: MeshInstance3D = node as MeshInstance3D
	return instance.transform * instance.mesh.get_aabb()


## O retângulo (x, z) que cobre os vértices da peça no quadro da praça (o das caixas dos eixos de uma peça girada sobra nos cantos).
func _rect(node: Node) -> Rect2:
	var instance: MeshInstance3D = node as MeshInstance3D
	var faces: PackedVector3Array = instance.mesh.get_faces()
	var first: Vector3 = instance.transform * faces[0]
	var rect: Rect2 = Rect2(first.x, first.z, 0.0, 0.0)
	for point: Vector3 in faces:
		var placed: Vector3 = instance.transform * point
		rect = rect.expand(Vector2(placed.x, placed.z))
	return rect


func _last_color(node_name: String) -> Color:
	var colors: PackedColorArray = ((_root.get_node(node_name) as MeshInstance3D).mesh as ArrayMesh).surface_get_arrays(0)[Mesh.ARRAY_COLOR]
	return colors[colors.size() - 1]


## Os triângulos distintos das malhas de árvore, em ordem: cada forma tem o seu tamanho.
func _tree_forms() -> Array[int]:
	var forms: Array[int] = []
	for tree: Node in _meshes("Tree*"):
		var triangles: int = int((tree as MeshInstance3D).mesh.get_faces().size() / 3.0)
		if not forms.has(triangles):
			forms.append(triangles)
	forms.sort()
	return forms


## Cores e quantidades de grama e flores: os materiais de vento levam a cor nos parâmetros, e a quantidade vem da contagem de instâncias do MultiMesh.
func _scatter_facts() -> String:
	var grass: MultiMeshInstance3D = _root.get_node("Grass") as MultiMeshInstance3D
	var shader: ShaderMaterial = grass.material_override as ShaderMaterial
	var facts: Array = [grass.multimesh.instance_count, shader.get_shader_parameter(&"low_color"), shader.get_shader_parameter(&"high_color")]
	for node: Node in _root.find_children("Flowers*", "MultiMeshInstance3D", true, false):
		var flower: MultiMeshInstance3D = node as MultiMeshInstance3D
		facts.append([flower.multimesh.instance_count, (flower.material_override as ShaderMaterial).get_shader_parameter(&"accent_color")])
	return str(facts)


## Monta a variante e mede: árvores (quantidade e formas), tom da copa, rochas, arbustos, tom das rochas e grama e flores (quantidades e cores).
func _measure(variant_id: StringName) -> PackedStringArray:
	_plant(variant_id)
	return PackedStringArray([str(_meshes("Tree*").size()), str(_tree_forms()), str(_last_color("Tree0")), str(_meshes("Rock*").size()), str(_last_color("Rock0")), str(_meshes("Bush*").size()), _scatter_facts()])


func _plants_digest() -> int:
	var digest: int = 0
	for pattern: String in PLANTS:
		for node: Node in _meshes(pattern):
			digest = hash([digest, node.name, (node as MeshInstance3D).transform, (node as MeshInstance3D).mesh.surface_get_arrays(0)])
	return digest


func test_variant_a_keeps_the_ring_of_trees_and_rocks_and_the_fields_default_to_the_plaza_of_today() -> void:
	var spec: PlazaVariants.Spec = PlazaVariants.named(&"a")
	assert_false(spec.plants_in_footprint, "a A não planta dentro do retângulo de encaixe")
	assert_true(spec.tree_spots.is_empty() and spec.rock_spots.is_empty() and spec.bush_spots.is_empty(), "sem lugares na ficha: o anel de hoje e nenhum arbusto")
	assert_eq(spec.tree_forms, PlazaData.TREE_VARIANTS)
	assert_eq(spec.tree_greens, PlazaData.TREE_GREENS)
	assert_eq(spec.flower_colors, PlazaData.FLOWER_COLORS)
	assert_eq(spec.grass_colors, [PlazaData.GRASS_LOW, PlazaData.GRASS_HIGH])
	assert_eq(spec.scatter_half_m, Vector2.ONE * (PlazaData.GROUND_HALF_M - 0.5), "a mesma área de grama e flores de sempre")
	_plant(&"a")
	assert_eq(_meshes("Tree*").size(), PlazaData.TREE_COUNT)
	assert_eq(_meshes("Rock*").size(), PlazaData.ROCK_COUNT)
	assert_eq(_meshes("Bush*").size(), 0)
	assert_eq(_scatter_facts(), str([PlazaData.GRASS_COUNT, PlazaData.GRASS_LOW, PlazaData.GRASS_HIGH, [PlazaData.FLOWERS_PER_COLOR, PlazaData.FLOWER_COLORS[0]], [PlazaData.FLOWERS_PER_COLOR, PlazaData.FLOWER_COLORS[1]], [PlazaData.FLOWERS_PER_COLOR, PlazaData.FLOWER_COLORS[2]]]))


func test_b_and_c_differ_from_a_and_from_each_other_in_at_least_three_aspects_of_the_vegetation() -> void:
	var measures: Array[PackedStringArray] = []
	for variant_id: StringName in IDS:
		measures.append(_measure(variant_id))
	for pair: Vector2i in PAIRS:
		var different: int = 0
		for aspect: int in measures[pair.x].size():
			if measures[pair.x][aspect] != measures[pair.y][aspect]:
				different += 1
		assert_gte(different, MIN_DIFFERENT_ASPECTS, "Aspectos diferentes entre %s e %s: %s" % [IDS[pair.x], IDS[pair.y], measures])
	assert_eq(measures[0][5], "0", "a A não tem arbustos")
	assert_gt(measures[2][5].to_int(), 0, "C tem arbustos")
	assert_lt(measures[1][3].to_int(), measures[2][3].to_int(), "C tem mais rochas que B")


func test_the_planting_of_b_and_c_repeats_and_stays_in_the_footprint_clear_of_the_structures() -> void:
	for variant_id: StringName in [&"b", &"c"]:
		_plant(variant_id)
		var obstacles: Array[Rect2] = []
		for pattern: String in OBSTACLES + PlazaVariants.CENTER_NAMES:
			for node: Node in _meshes(pattern):
				obstacles.append(_rect(node))
		assert_gte(obstacles.size(), PlazaData.LAMP_SPOTS.size() + PlazaData.TORCH_SPOTS.size(), "estruturas medidas na variante %s" % variant_id)
		var planted: int = 0
		for pattern: String in PLANTS:
			for node: Node in _meshes(pattern):
				planted += 1
				assert_true(MarketPlazaView.FOOTPRINT_M.grow(TOLERANCE_M).encloses(_rect(node)), "%s da variante %s dentro do retângulo de encaixe: %s" % [node.name, variant_id, _rect(node)])
				for obstacle: Rect2 in obstacles:
					assert_false(_rect(node).intersects(obstacle), "%s da variante %s (%s) fora de %s" % [node.name, variant_id, _rect(node), obstacle])
		assert_gt(planted, PlazaVariants.named(variant_id).tree_spots.size(), "árvores, rochas e arbustos plantados")
		var first: int = _plants_digest()
		_plant(variant_id)
		assert_eq(_plants_digest(), first, "a mesma ficha, a mesma vegetação (%s)" % variant_id)


func test_every_variant_gives_each_tree_type_a_shape_a_form_and_a_green_and_plants_only_with_spots() -> void:
	for variant_id: StringName in IDS:
		var spec: PlazaVariants.Spec = PlazaVariants.named(variant_id)
		assert_gt(spec.tree_forms.size(), 0, "a variante %s tem tipos de árvore" % variant_id)
		assert_eq(spec.tree_shapes.size(), spec.tree_forms.size(), "uma forma por tipo (%s)" % variant_id)
		assert_eq(spec.tree_greens.size(), spec.tree_forms.size(), "um verde por tipo (%s)" % variant_id)
		assert_gt(spec.flower_colors.size(), 0, "a variante %s tem flores" % variant_id)
		assert_eq(spec.grass_colors.size(), 2, "cor da base e da ponta da grama (%s)" % variant_id)
		assert_true(spec.plants_in_footprint == (not spec.tree_spots.is_empty()), "só quem tem lugares de árvore planta dentro do retângulo (%s)" % variant_id)


func test_the_trees_of_b_are_round_and_stay_under_the_bunting() -> void:
	_plant(&"b")
	var spec: PlazaVariants.Spec = PlazaVariants.named(&"b")
	assert_eq(spec.tree_shapes.count(PlazaData.TreeShape.ROUND), spec.tree_shapes.size(), "as formas de B são todas redondas")
	assert_eq(_meshes("Tree*").size(), spec.tree_spots.size())
	for tree: Node in _meshes("Tree*"):
		assert_lt(_box(tree).end.y, BUNTING_LOW_M, "%s abaixo do fio de bandeirolas" % tree.name)
