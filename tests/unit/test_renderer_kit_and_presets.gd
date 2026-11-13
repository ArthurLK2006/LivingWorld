extends GutTest

## ARTE-F0, kit de malhas e predefinições (sem renderizar): hash de inteiros reproduzível, faces facetadas e viradas para fora, predefinições de luz e de câmera, suporte de efeitos por renderer e ausência de sorteio da engine (a varredura vale para todos os arquivos da pasta da cena de teste, os que existirem).
const SOURCE_DIR: String = "res://tools/visual/renderer_test"
const FORBIDDEN_RANDOM: String = "\\b(randf|randi|randomize|randf_range|randi_range|randfn|rand_from_seed)\\s*\\(|RandomNumberGenerator|\\.(shuffle|pick_random)\\s*\\("
const TOLERANCE: float = 0.001


func test_hash_is_deterministic_and_spread() -> void:
	assert_eq(RendererMeshKit.hash_int(12345), RendererMeshKit.hash_int(12345), "mesmo valor, mesmo hash")
	assert_ne(RendererMeshKit.unit(1, 0), RendererMeshKit.unit(1, 1), "canais independentes")
	var total: float = 0.0
	var lowest: float = 1.0
	var highest: float = 0.0
	for index: int in 1000:
		var value: float = RendererMeshKit.unit(index, 3)
		total += value
		lowest = minf(lowest, value)
		highest = maxf(highest, value)
	assert_gte(lowest, 0.0, "mínimo")
	assert_lt(highest, 1.0, "máximo")
	assert_almost_eq(total / 1000.0, 0.5, 0.05, "média perto de 0,5")


func test_faces_are_flat_and_point_outward() -> void:
	var kit: RendererMeshKit = RendererMeshKit.new()
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


func test_presets_and_views_have_the_expected_fields() -> void:
	assert_eq(RendererPresets.PRESETS.size(), 3, "dia, hora dourada e crepúsculo")
	var fields: Array = RendererPresets.PRESETS[0].keys()
	for key: String in ["sun_color", "sun_energy", "sun_pitch", "ambient_color", "sky_top", "fog_color", "tonemap", "brightness", "glow", "ssao", "dof", "volumetric_density", "lamp", "torch"]:
		assert_true(fields.has(key), "campo %s" % key)
	for preset: Dictionary in RendererPresets.PRESETS:
		assert_eq(preset.keys(), fields, "as três predefinições têm os mesmos campos, na mesma ordem")
	assert_between(float(RendererPresets.PRESETS[0]["sun_pitch"]), 45.0, 60.0, "sol do dia alto")
	assert_between(float(RendererPresets.PRESETS[1]["sun_pitch"]), 8.0, 15.0, "sol da hora dourada baixo")
	assert_lt(float(RendererPresets.PRESETS[2]["sun_pitch"]), 8.0, "sol do crepúsculo muito baixo")
	assert_eq(float(RendererPresets.PRESETS[0]["lamp"]), 0.0, "lampiões apagados de dia")
	assert_gt(float(RendererPresets.PRESETS[1]["lamp"]), 0.0, "lampiões acesos na hora dourada")
	assert_gt(float(RendererPresets.PRESETS[2]["torch"]), 0.0, "tochas acesas no crepúsculo")
	assert_eq(RendererPresets.VIEWS.size(), 3, "próxima, isométrica e estratégica")
	assert_eq([RendererPresets.VIEWS[0]["distance"], RendererPresets.VIEWS[1]["distance"], RendererPresets.VIEWS[2]["distance"]], [5.0, 22.0, 60.0], "distâncias")
	assert_eq([RendererPresets.VIEWS[0]["pitch"], RendererPresets.VIEWS[1]["pitch"], RendererPresets.VIEWS[2]["pitch"]], [12.0, 50.0, 70.0], "ângulos")


func test_effects_follow_the_renderer_support() -> void:
	var full: Dictionary[StringName, bool] = RendererPresets.supported_effects("forward_plus")
	var none: Dictionary[StringName, bool] = RendererPresets.supported_effects("dummy")
	for effect: StringName in RendererPresets.EFFECTS:
		assert_true(full[effect], "Forward+ aceita %s" % effect)
		assert_false(none[effect], "método desconhecido não aceita %s" % effect)
	assert_eq(RendererPresets.supported_effects("gl_compatibility").size(), RendererPresets.EFFECTS.size(), "o Compatibility também tem uma resposta para cada efeito")


func test_sources_do_not_use_engine_randomness() -> void:
	var regex: RegEx = RegEx.create_from_string(FORBIDDEN_RANDOM)
	var checked: int = 0
	for file_name: String in DirAccess.get_files_at(SOURCE_DIR):
		if file_name.ends_with(".gd"):
			checked += 1
			assert_null(regex.search(FileAccess.get_file_as_string(SOURCE_DIR.path_join(file_name))), "%s não sorteia com a engine" % file_name)
	assert_gt(checked, 0, "arquivos verificados")
