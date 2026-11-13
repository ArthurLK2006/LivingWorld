extends GutTest

## ARTE-F0: a cena de teste de renderizadores monta SEM renderizar (o modo sem janela usa renderer de mentira): contagens, orçamento de triângulos e de materiais, determinismo, predefinições, teclas,
## faces facetadas e viradas para fora, e ausência de sorteio da engine. O que só a janela mostra (cor, sombra, bloom, desempenho) não é testado aqui.
const SCENE_PATH: String = "res://scenes/demo/renderer_test.tscn"
const SOURCE_DIR: String = "res://tools/visual/renderer_test"
const FORBIDDEN_RANDOM: String = "\\b(randf|randi|randomize|randf_range|randi_range|randfn|rand_from_seed)\\s*\\(|RandomNumberGenerator|\\.(shuffle|pick_random)\\s*\\("
const TOLERANCE: float = 0.001
const BOUND_ACTIONS: int = 10
## O que o Compatibility aceita sem a engine reclamar (a própria 4.7.2 avisa: névoa volumétrica só no Forward+ e desfoque de profundidade só no Forward+ ou Mobile); ligar o resto num teste sem janela faria a engine imprimir erro.
const COMPAT_SAFE: Dictionary[StringName, bool] = {&"bloom": true, &"ssao": false, &"fog": true, &"dof": false, &"volumetric": false}


func _build() -> RendererTestScene:
	var scene: RendererTestScene = (load(SCENE_PATH) as PackedScene).instantiate()
	add_child_autofree(scene)
	return scene


func _count(scene: Node, pattern: String, type: String) -> int:
	return scene.find_children(pattern, type, true, false).size()


func _key(code: Key) -> InputEventKey:
	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	return event


func test_scene_has_the_requested_content() -> void:
	var scene: RendererTestScene = _build()
	var stalls: int = RendererMarketBuilder.STALL_SPOTS.size()
	assert_eq(_count(scene, "Stall?", "MeshInstance3D"), stalls, "barracas")
	assert_eq(_count(scene, "Crate*", "MeshInstance3D"), 2 * stalls, "caixotes")
	assert_eq(_count(scene, "Barrel*", "MeshInstance3D"), stalls, "barris")
	assert_eq(_count(scene, "Sack*", "MeshInstance3D"), 2 * stalls, "sacos")
	assert_eq(_count(scene, "LampPost?", "MeshInstance3D"), 4, "postes com lampião")
	assert_eq(_count(scene, "Bunting?", "MeshInstance3D"), 4, "fios de bandeirolas")
	assert_eq(_count(scene, "House?", "MeshInstance3D"), 3, "casas")
	assert_eq(_count(scene, "Tree*", "MeshInstance3D"), RendererMarketBuilder.TREE_COUNT, "árvores")
	assert_eq(_count(scene, "Well", "MeshInstance3D"), 1, "poço")
	assert_eq(scene.built.lamp_lights.size(), 4, "luzes dos lampiões")
	assert_eq(_count(scene, "*", "OmniLight3D"), 4 + RendererMarketBuilder.TORCH_SPOTS.size(), "luzes pequenas (lampiões e tochas)")
	assert_eq(_count(scene, "*", "DirectionalLight3D"), 1, "sol")
	var instances: int = 0
	for node: Node in scene.find_children("*", "MultiMeshInstance3D", true, false):
		instances += (node as MultiMeshInstance3D).multimesh.instance_count
	assert_eq(instances, RendererMarketBuilder.GRASS_COUNT + RendererMarketBuilder.FLOWERS_PER_COLOR * RendererMarketBuilder.FLOWER_COLORS.size(), "instâncias de grama e flores")


func test_triangle_and_material_budgets() -> void:
	var scene: RendererTestScene = _build()
	var triangles: int = scene.triangle_count()
	assert_between(triangles, 1, RendererTestScene.TRIANGLE_BUDGET, "triângulos dentro do orçamento (%d)" % triangles)
	assert_lte(scene.built.materials.size(), RendererTestScene.MAX_MATERIALS, "materiais compartilhados")


func test_two_builds_are_identical() -> void:
	var first: int = _build().fingerprint()
	assert_ne(first, 0, "a montagem produziu geometria")
	assert_eq(_build().fingerprint(), first, "duas montagens iguais")


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
	var scene: RendererTestScene = _build()
	scene.supported = none
	scene.apply_preset(2)
	assert_false(scene.environment.glow_enabled or scene.environment.ssao_enabled or scene.environment.volumetric_fog_enabled or scene.environment.fog_enabled, "nada ligado sem suporte")
	scene.supported = COMPAT_SAFE
	scene.apply_preset(2)
	assert_true(scene.environment.glow_enabled and scene.environment.fog_enabled, "o que tem suporte liga")
	assert_false(scene.environment.ssao_enabled or scene.environment.volumetric_fog_enabled or (scene.camera.attributes as CameraAttributesPractical).dof_blur_far_enabled, "o que não tem suporte continua desligado")


func test_presets_and_views_are_applied_to_the_rig() -> void:
	var scene: RendererTestScene = _build()
	scene.apply_view(2)
	scene.apply_preset(1)
	assert_eq(scene.sun.light_color, RendererPresets.PRESETS[1]["sun_color"], "cor do sol")
	assert_gt(scene.built.lamp_lights[0].light_energy, 0.0, "lampião aceso")
	assert_true(scene.built.lamp_lights[0].visible, "luz do lampião visível")
	var arm: Vector3 = scene.camera.position - RendererPresets.AIM_POINT_M
	assert_almost_eq(arm.length(), 60.0, TOLERANCE, "distância da câmera estratégica")
	assert_almost_eq(rad_to_deg(asin(arm.y / arm.length())), 70.0, TOLERANCE, "ângulo para baixo da câmera estratégica")
	scene.apply_preset(0)
	assert_false(scene.built.lamp_lights[0].visible, "lampião apagado de dia")


func test_keys_live_in_the_scene_and_drive_light_view_and_effects() -> void:
	var scene: RendererTestScene = _build()
	scene.supported = COMPAT_SAFE
	assert_eq(scene.key_bindings.size(), BOUND_ACTIONS, "uma tecla por ação, guardada na cena")
	assert_eq(scene.action_for(_key(KEY_2)), &"light_golden", "tecla 2")
	assert_eq(scene.action_for(_key(KEY_Z)), &"", "tecla sem ação")
	var released: InputEventKey = _key(KEY_1)
	released.pressed = false
	assert_eq(scene.action_for(released), &"", "tecla solta não conta")
	scene._unhandled_input(_key(KEY_3))
	assert_eq(scene.preset_index, 2, "3 = crepúsculo")
	scene._unhandled_input(_key(KEY_E))
	assert_eq(scene.view_index, 2, "E = câmera estratégica")
	scene._unhandled_input(_key(KEY_B))
	assert_false(scene.switches[&"bloom"], "B desliga o bloom")
	assert_false(scene.environment.glow_enabled, "o bloom saiu do ambiente")
	scene._unhandled_input(_key(KEY_B))
	assert_true(scene.environment.glow_enabled, "B liga o bloom de novo")


func test_auto_mode_arguments() -> void:
	var args: PackedStringArray = PackedStringArray(["--auto", "--out=/tmp/saida"])
	assert_true(RendererAutoRun.is_requested(args), "--auto")
	assert_eq(RendererAutoRun.out_dir(args), "/tmp/saida", "--out=<pasta>")
	assert_false(RendererAutoRun.is_requested(PackedStringArray()), "sem argumentos a cena fica interativa")
	assert_eq(RendererAutoRun.out_dir(PackedStringArray(["--auto"])), "", "sem --out a pasta vem vazia")


func test_sources_do_not_use_engine_randomness() -> void:
	var regex: RegEx = RegEx.create_from_string(FORBIDDEN_RANDOM)
	var checked: int = 0
	for file_name: String in DirAccess.get_files_at(SOURCE_DIR):
		if file_name.ends_with(".gd"):
			checked += 1
			assert_null(regex.search(FileAccess.get_file_as_string(SOURCE_DIR.path_join(file_name))), "%s não sorteia com a engine" % file_name)
	assert_gt(checked, 0, "arquivos verificados")


func test_auto_mode_report_pieces() -> void:
	var scene: RendererTestScene = _build()
	var auto_run: RendererAutoRun = RendererAutoRun.new()
	var header: Array[String] = auto_run._header(scene)
	assert_eq(header.size(), 5, "cabeçalho do resumo")
	assert_string_contains(header[0], "renderer: %s" % scene.rendering_method)
	assert_string_contains(header[2], "triângulos")
	assert_eq(header[4], RendererAutoRun.TABLE_HEADER, "tabela")
	var shot: RendererAutoRun.Shot = RendererAutoRun.Shot.new()
	shot.label = "day_near"
	shot.fps = 123.456
	assert_string_contains(shot.to_line(), "day_near | 123.5 | 0.0 | 0 | 0 | 0 | 0.0 | 0.000 | 0.000 | ")
	var image: Image = Image.create(8, 8, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.8, 0.4, 0.2))
	auto_run._measure_color(image, shot)
	assert_almost_eq(shot.saturation, 0.75, 0.02, "saturação de uma cor lisa")
	assert_almost_eq(shot.brightness, 0.8, 0.02, "brilho de uma cor lisa")
	var directory: DirAccess = DirAccess.create_temp("lw_arte_f0")
	var summary: String = directory.get_current_dir().path_join(RendererAutoRun.SUMMARY_FILE)
	auto_run._write(summary, ["a", "b"])
	assert_eq(FileAccess.get_file_as_string(summary), "a\nb\n", "resumo gravado")
	DirAccess.remove_absolute(summary)
	DirAccess.remove_absolute(directory.get_current_dir())
