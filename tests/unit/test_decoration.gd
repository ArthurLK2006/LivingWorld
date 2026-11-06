extends GutTest
## LW-043: árvores e pedras por dados. Terreno de blockout real e ponte real, sem janela. Só visual: sem colisão.

const DECORATIONS_PATH: String = "res://data/world/decorations.json"
const BLOCKOUT_DIR: String = "res://data/world"
const MAIN_SCENE_PATH: String = "res://scenes/main.tscn"
## Contagens [HIP] do arquivo (decisão de Arthur para o envio da LW-043).
const TREE_COUNT: int = 1200
const ROCK_COUNT: int = 600
const HEIGHT_TOLERANCE_M: float = 0.001
const SPAWN_CLEAR_M: float = 20.0
const MIN_SPACING_M: float = 3.0
const NORMAL_TOLERANCE: float = 0.001
const CM_PER_METER: float = 100.0
## Vértices: árvore = (6 + 8 faces de lado + 8 da base da copa) x ... conferidos pelas constantes das formas.
const TREE_TRIANGLES: int = 28
const ROCK_TRIANGLES: int = 12
const VERTICES_PER_TRIANGLE: int = 3

var _bridge: SimBridge
var _layout: SimBridge.TerrainLayoutReply
var _items: Array[DecorationReader.Item]
var _view: DecorationView
var _temp_dirs: Array[DirAccess] = []


func before_all() -> void:
	var loaded: TerrainLoader.LoadResult = TerrainLoader.load_dir(BLOCKOUT_DIR)
	assert_true(loaded.result.ok, loaded.result.message)
	_bridge = SimBridge.new(null, loaded.terrain)
	_layout = _bridge.peek_terrain_layout()
	var read: DecorationReader.ReadResult = DecorationReader.read_file(DECORATIONS_PATH)
	assert_true(read.result.ok, read.result.message)
	_items = read.items
	_view = DecorationView.new()
	_view.setup(_bridge, _items)


func after_all() -> void:
	_view.free()


func after_each() -> void:
	for directory: DirAccess in _temp_dirs:
		for file_name: String in directory.get_files():
			DirAccess.remove_absolute(directory.get_current_dir().path_join(file_name))
		DirAccess.remove_absolute(directory.get_current_dir())
	_temp_dirs.clear()


## Grava `text` num arquivo temporário e devolve o caminho.
func _write_temp(text: String) -> String:
	var directory: DirAccess = DirAccess.create_temp("lw043")
	_temp_dirs.append(directory)
	var path: String = directory.get_current_dir().path_join(BlockoutDecorationsGenerator.DECORATIONS_FILE)
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()
	return path


func _chunk_size_m() -> float:
	return float(_layout.chunk_cells) * _layout.cell_size_m


## Todas as instâncias montadas: [tipo, chunk (x, z), posição no mundo].
func _placed() -> Array[Dictionary]:
	var placed: Array[Dictionary] = []
	for instance: MultiMeshInstance3D in _view.multimesh_instances():
		var parts: PackedStringArray = instance.name.trim_prefix("Deco_").split("_")
		var transforms: Array[Transform3D] = _view.transforms_of(instance)
		assert_eq(transforms.size(), instance.multimesh.instance_count, "As transformações guardadas batem com o MultiMesh.")
		for transform: Transform3D in transforms:
			placed.append({"kind": parts[0], "chunk": Vector2i(int(parts[1]), int(parts[2])), "origin": transform.origin})
	return placed


func test_the_file_counts_and_the_multimesh_instances_match() -> void:
	var trees: int = 0
	for item: DecorationReader.Item in _items:
		trees += 1 if item.kind == DecorationReader.KIND_TREE else 0
	assert_eq(trees, TREE_COUNT)
	assert_eq(_items.size() - trees, ROCK_COUNT)
	assert_eq(_view.instance_count(DecorationReader.KIND_TREE), TREE_COUNT)
	assert_eq(_view.instance_count(DecorationReader.KIND_ROCK), ROCK_COUNT)
	var summed: int = 0
	for instance: MultiMeshInstance3D in _view.multimesh_instances():
		summed += instance.multimesh.instance_count
		assert_true(instance.name.begins_with("Deco_tree_") or instance.name.begins_with("Deco_rock_"))
	assert_eq(summed, TREE_COUNT + ROCK_COUNT, "A soma dos MultiMesh confere com o arquivo.")
	assert_eq(_view.get_child_count(), _view.multimesh_instances().size(), "Um MultiMeshInstance3D por chunk e tipo, filhos da view.")


func test_each_instance_is_in_the_right_chunk_and_on_the_ground() -> void:
	var size_m: float = _chunk_size_m()
	var wrong_chunk: int = 0
	var wrong_height: int = 0
	for entry: Dictionary in _placed():
		var chunk: Vector2i = entry["chunk"]
		var origin: Vector3 = entry["origin"]
		if floori(origin.x / size_m) != chunk.x or floori(origin.z / size_m) != chunk.y:
			wrong_chunk += 1
		if absf(origin.y - _bridge.peek_height(origin.x, origin.z).height_m) > HEIGHT_TOLERANCE_M:
			wrong_height += 1
	assert_eq(wrong_chunk, 0, "Instância num MultiMesh de outro chunk.")
	assert_eq(wrong_height, 0, "Instância com y diferente de peek_height (flutuando ou enterrada).")


func test_trees_only_on_grass_and_nothing_on_the_path_or_near_the_spawn() -> void:
	var spawn: Vector3 = _bridge.peek_spawn_point().point
	var bad_tree: int = 0
	var on_path: int = 0
	var near_spawn: int = 0
	for entry: Dictionary in _placed():
		var origin: Vector3 = entry["origin"]
		var surface: String = _bridge.peek_surface(origin.x, origin.z).surface_id
		bad_tree += 1 if entry["kind"] == DecorationReader.KIND_TREE and surface != "grass" else 0
		on_path += 1 if surface == "path" else 0
		near_spawn += 1 if Vector2(origin.x - spawn.x, origin.z - spawn.z).length() < SPAWN_CLEAR_M else 0
	assert_eq(bad_tree, 0, "Árvore fora da grama.")
	assert_eq(on_path, 0, "Decoração sobre o caminho.")
	assert_eq(near_spawn, 0, "Decoração a menos de 20 m do nascimento.")
	assert_eq(_view.find_children("*", "CollisionObject3D", true, false).size(), 0, "Decoração não colide.")


func test_instances_keep_the_minimum_spacing() -> void:
	var points: Array[Vector2] = []
	for entry: Dictionary in _placed():
		var origin: Vector3 = entry["origin"]
		points.append(Vector2(origin.x, origin.z))
	points.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
	var too_close: int = 0
	for index: int in range(points.size()):
		var next: int = index + 1
		while next < points.size() and points[next].x - points[index].x < MIN_SPACING_M:
			too_close += 1 if points[index].distance_to(points[next]) < MIN_SPACING_M - HEIGHT_TOLERANCE_M else 0
			next += 1
	assert_eq(too_close, 0, "Pares a menos de 3 m.")


func test_the_generator_is_deterministic_and_check_detects_differences() -> void:
	assert_true(BlockoutDecorationsGenerator.run(PackedStringArray(["--check"])).ok, "O arquivo gravado é idêntico ao que a ferramenta gera.")
	var loaded: TerrainLoader.LoadResult = TerrainLoader.load_dir(BLOCKOUT_DIR)
	var first: String = BlockoutDecorationsGenerator.render(BlockoutDecorationsGenerator.generate(loaded.terrain))
	var second: String = BlockoutDecorationsGenerator.render(BlockoutDecorationsGenerator.generate(loaded.terrain))
	assert_eq(first, second, "Mesma semente, mesmo texto.")
	assert_eq(first, FileAccess.get_file_as_string(DECORATIONS_PATH))
	var tampered: String = _write_temp(first.replace("\"scale_pct\": 100}", "\"scale_pct\": 101}"))
	var differs: Result = BlockoutDecorationsGenerator.run(PackedStringArray(["--check", "--out", tampered.get_base_dir()]))
	assert_false(differs.ok)
	assert_eq(differs.code, BlockoutDecorationsGenerator.CODE_CHECK_DIFFERS)
	var missing: Result = BlockoutDecorationsGenerator.run(PackedStringArray(["--out", "res://pasta_que_nao_existe"]))
	assert_eq(missing.code, BlockoutDecorationsGenerator.CODE_BAD_OUT_DIR)
	assert_eq(BlockoutDecorationsGenerator.run(PackedStringArray(["--invalida"])).code, BlockoutDecorationsGenerator.CODE_USAGE)


func test_invalid_files_are_rejected_with_file_and_line_and_no_decorations() -> void:
	var good_line: String = "\t{\"kind\": \"tree\", \"x_cm\": 5000, \"z_cm\": 6000, \"yaw_deg\": 10, \"scale_pct\": 100}"
	var cases: Dictionary[String, String] = {
		"kind '": "\t{\"kind\": \"bush\", \"x_cm\": 5000, \"z_cm\": 6000, \"yaw_deg\": 10, \"scale_pct\": 100}",
		"'yaw_deg' = 360": "\t{\"kind\": \"tree\", \"x_cm\": 5000, \"z_cm\": 6000, \"yaw_deg\": 360, \"scale_pct\": 100}",
		"'scale_pct' = 79": "\t{\"kind\": \"rock\", \"x_cm\": 5000, \"z_cm\": 6000, \"yaw_deg\": 10, \"scale_pct\": 79}",
		"campo 'scale_pct' ausente": "\t{\"kind\": \"rock\", \"x_cm\": 5000, \"z_cm\": 6000, \"yaw_deg\": 10}",
		"campo desconhecido 'altura'": "\t{\"kind\": \"rock\", \"x_cm\": 5000, \"z_cm\": 6000, \"yaw_deg\": 10, \"scale_pct\": 90, \"altura\": 1}",
		"'x_cm' deve ser um inteiro": "\t{\"kind\": \"rock\", \"x_cm\": 5000.5, \"z_cm\": 6000, \"yaw_deg\": 10, \"scale_pct\": 90}",
		"JSON inválido": "\t{\"kind\": \"rock\", ",
	}
	for expected: String in cases:
		var path: String = _write_temp("[\n%s,\n%s\n]\n" % [good_line, cases[expected]])
		var read: DecorationReader.ReadResult = DecorationReader.read_file(path)
		assert_false(read.result.ok, "Deveria rejeitar: %s" % expected)
		assert_eq(read.result.code, DecorationReader.CODE_INVALID)
		assert_string_contains(read.result.message, path + ":3", "Arquivo e linha do erro (%s)." % expected)
		assert_string_contains(read.result.message, expected)
		assert_eq(read.items.size(), 0, "Arquivo inválido: nenhuma decoração.")
	var absent: DecorationReader.ReadResult = DecorationReader.read_file("res://data/world/nao_existe.json")
	assert_string_contains(absent.result.message, "arquivo não encontrado")


func test_freeing_the_view_frees_its_nodes() -> void:
	var nodes_before: int = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var view: DecorationView = DecorationView.new()
	add_child(view)
	view.setup(_bridge, _items)
	assert_eq(int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)), nodes_before + 1 + view.multimesh_instances().size())
	view.free()
	assert_eq(int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)), nodes_before, "Liberar a view libera todos os MultiMeshInstance3D.")


func test_a_null_bridge_and_a_bridge_without_terrain_build_nothing_with_a_visible_error() -> void:
	var view: DecorationView = DecorationView.new()
	view.setup(null, _items)
	assert_push_error("ponte nula")
	view.setup(SimBridge.new(null, null), _items)
	assert_push_error(SimBridge.CODE_NO_TERRAIN)
	assert_eq(view.multimesh_instances().size(), 0)
	assert_eq(view.instance_count(DecorationReader.KIND_TREE), 0)
	view.free()


func test_the_main_scene_has_one_decoration_view() -> void:
	var main: Node = (load(MAIN_SCENE_PATH) as PackedScene).instantiate()
	assert_eq(main.find_children("*", "DecorationView", true, false).size(), 1)
	main.free()


func test_shapes_have_the_expected_triangles_and_every_face_looks_outward() -> void:
	var meshes: Dictionary[String, ArrayMesh] = {"tree": DecorationShapes.tree_mesh(), "rock": DecorationShapes.rock_mesh()}
	var expected: Dictionary[String, int] = {"tree": TREE_TRIANGLES, "rock": ROCK_TRIANGLES}
	for shape: String in meshes:
		var arrays: Array = meshes[shape].surface_get_arrays(0)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		assert_eq(vertices.size(), expected[shape] * VERTICES_PER_TRIANGLE, "Triângulos da forma '%s'." % shape)
		var wrong: int = 0
		for first: int in range(0, vertices.size(), VERTICES_PER_TRIANGLE):
			var face: Vector3 = (vertices[first + 2] - vertices[first]).cross(vertices[first + 1] - vertices[first]).normalized()
			wrong += 1 if face.dot(normals[first]) < 1.0 - NORMAL_TOLERANCE else 0
		assert_eq(wrong, 0, "Em '%s' a ordem dos vértices tem de concordar com a normal (face da frente para fora)." % shape)
