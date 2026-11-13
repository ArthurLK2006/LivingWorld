extends GutTest

## ARTE-F0, chão da praça (sem renderizar): o relevo e o caminho, a peça posta sobre o chão, e o conteúdo e o determinismo do chão, das árvores, das rochas, da grama e das flores.
const TOLERANCE: float = 0.001

var _root: Node3D


func _ground() -> RendererMarketGround:
	_root = Node3D.new()
	add_child_autofree(_root)
	return RendererMarketGround.new(_root, RendererMarketMaterials.create())


func _count(pattern: String, type: String) -> int:
	return _root.find_children(pattern, type, true, false).size()


func _floor_arrays() -> Array:
	_ground().add_floor()
	return ((_root.get_node("Ground") as MeshInstance3D).mesh as ArrayMesh).surface_get_arrays(0)


func test_floor_trees_rocks_and_scatter_have_the_requested_content() -> void:
	var ground: RendererMarketGround = _ground()
	ground.add_floor()
	ground.add_trees()
	ground.add_rocks()
	ground.add_scatter()
	assert_eq(_count("Ground", "MeshInstance3D"), 1, "chão")
	assert_eq(_count("Tree*", "MeshInstance3D"), RendererMarketData.TREE_COUNT, "árvores")
	assert_eq(_count("Rock*", "MeshInstance3D"), RendererMarketData.ROCK_COUNT, "rochas")
	var instances: int = 0
	for node: Node in _root.find_children("*", "MultiMeshInstance3D", true, false):
		instances += (node as MultiMeshInstance3D).multimesh.instance_count
	assert_eq(instances, RendererMarketData.GRASS_COUNT + RendererMarketData.FLOWERS_PER_COLOR * RendererMarketData.FLOWER_COLORS.size(), "instâncias de grama e flores")
	var cells: int = RendererMarketData.GROUND_HALF_M * 2
	assert_eq(int((_root.get_node("Ground") as MeshInstance3D).mesh.get_faces().size() / 3.0), cells * cells * 2, "dois triângulos por célula do chão")


func test_relief_stays_in_range_and_the_path_is_where_the_data_says() -> void:
	var highest: float = 0.0
	for x: int in range(-18, 19, 3):
		for z: int in range(-18, 19, 3):
			highest = maxf(highest, absf(RendererMarketGround.ground_height(float(x), float(z))))
	assert_lte(highest, 1.5 * RendererMarketData.RELIEF_AMPLITUDE_M, "o relevo fica dentro da amplitude")
	assert_almost_eq(RendererMarketGround.path_weight(0.0, 0.0), 1.0, TOLERANCE, "clareira do poço é terra")
	assert_almost_eq(RendererMarketGround.path_weight(15.0, 15.0), 0.0, TOLERANCE, "longe do caminho é grama")


func test_spawn_puts_the_mesh_on_the_ground_with_yaw_and_size() -> void:
	var node: MeshInstance3D = _ground().spawn(BoxMesh.new(), "Probe", Vector2(3.0, 4.0), 0.5, 2.0)
	assert_eq(node.get_parent(), _root, "filho da raiz")
	assert_eq(node.name, &"Probe", "nome")
	assert_almost_eq(node.position, Vector3(3.0, RendererMarketGround.ground_height(3.0, 4.0), 4.0), Vector3.ONE * TOLERANCE, "apoiada na altura do relevo")
	assert_almost_eq(node.transform.basis.get_scale(), Vector3.ONE * 2.0, Vector3.ONE * TOLERANCE, "escala")
	assert_almost_eq(node.rotation.y, 0.5, TOLERANCE, "giro")


func test_two_floors_are_identical() -> void:
	var first: Array = _floor_arrays()
	assert_gt((first[Mesh.ARRAY_VERTEX] as PackedVector3Array).size(), 0, "o chão tem triângulos")
	assert_eq(_floor_arrays(), first, "duas montagens do chão iguais")
