extends GutTest

## ARTE-F0 (praça promovida ao jogo na ART-1), kit de malhas da praça (sem renderizar): hash de inteiros reproduzível, faces facetadas e viradas para fora e ausência de sorteio da engine (a varredura vale para todos os arquivos das duas pastas, a da praça em `src/presentation` e a da cena de teste, os que existirem).
const SOURCE_DIRS: Array[String] = ["res://src/presentation/world_view/plaza", "res://tools/visual/renderer_test"]
const FORBIDDEN_RANDOM: String = "\\b(randf|randi|randomize|randf_range|randi_range|randfn|rand_from_seed)\\s*\\(|RandomNumberGenerator|\\.(shuffle|pick_random)\\s*\\("
const TOLERANCE: float = 0.001


func test_hash_is_deterministic_and_spread() -> void:
	assert_eq(PlazaMeshKit.hash_int(12345), PlazaMeshKit.hash_int(12345), "mesmo valor, mesmo hash")
	assert_ne(PlazaMeshKit.unit(1, 0), PlazaMeshKit.unit(1, 1), "canais independentes")
	var total: float = 0.0
	var lowest: float = 1.0
	var highest: float = 0.0
	for index: int in 1000:
		var value: float = PlazaMeshKit.unit(index, 3)
		total += value
		lowest = minf(lowest, value)
		highest = maxf(highest, value)
	assert_gte(lowest, 0.0, "mínimo")
	assert_lt(highest, 1.0, "máximo")
	assert_almost_eq(total / 1000.0, 0.5, 0.05, "média perto de 0,5")


func test_faces_are_flat_and_point_outward() -> void:
	var kit: PlazaMeshKit = PlazaMeshKit.new()
	kit.box(Vector3.ZERO, Vector3(2.0, 1.0, 3.0), Color.WHITE, 0.4)
	kit.frustum(Vector3(5.0, 0.0, 0.0), 1.0, 0.5, 2.0, 7, Color.WHITE)
	kit.blob(Vector3(0.0, 0.0, 9.0), Vector3(1.0, 1.0, 1.0), Vector3i(4, 6, 2), 0.3, Color.WHITE)
	var arrays: Array = kit.finish(ArrayMesh.new(), StandardMaterial3D.new()).surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	assert_gt(vertices.size(), 0, "há triângulos")
	for first: int in range(0, vertices.size(), 3):
		var winding: Vector3 = (vertices[first + 2] - vertices[first]).cross(vertices[first + 1] - vertices[first]).normalized()
		assert_gt(winding.dot(normals[first]), 1.0 - TOLERANCE, "a normal segue o sentido horário dos vértices (face da frente na Godot)")
		assert_eq(normals[first], normals[first + 1], "normal plana: o vértice 2 repete a do 1")
		assert_eq(normals[first], normals[first + 2], "normal plana: o vértice 3 repete a do 1")


func test_sources_do_not_use_engine_randomness() -> void:
	var regex: RegEx = RegEx.create_from_string(FORBIDDEN_RANDOM)
	for directory: String in SOURCE_DIRS:
		var checked: int = 0
		for file_name: String in DirAccess.get_files_at(directory):
			if file_name.ends_with(".gd"):
				checked += 1
				assert_null(regex.search(FileAccess.get_file_as_string(directory.path_join(file_name))), "%s não sorteia com a engine" % file_name)
		assert_gt(checked, 0, "arquivos verificados em %s" % directory)
