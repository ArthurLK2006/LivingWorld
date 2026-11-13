extends GutTest

## ARTE-F0, a cena de teste montada (sem renderizar: o modo sem janela usa renderer de mentira): conteúdo pedido, orçamento de triângulos e de materiais, determinismo, predefinições e câmeras aplicadas, efeitos conforme o suporte do renderer e teclas. O que só a janela mostra (cor, sombra, bloom, desempenho) não é testado aqui.
const SCENE_PATH: String = "res://scenes/demo/renderer_test.tscn"
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
	var stalls: int = RendererMarketData.STALL_SPOTS.size()
	assert_eq(_count(scene, "Stall?", "MeshInstance3D"), stalls, "barracas")
	assert_eq(_count(scene, "Crate*", "MeshInstance3D"), 2 * stalls, "caixotes")
	assert_eq(_count(scene, "Barrel*", "MeshInstance3D"), stalls, "barris")
	assert_eq(_count(scene, "Sack*", "MeshInstance3D"), 2 * stalls, "sacos")
	assert_eq(_count(scene, "LampPost?", "MeshInstance3D"), 4, "postes com lampião")
	assert_eq(_count(scene, "Bunting?", "MeshInstance3D"), 4, "fios de bandeirolas")
	assert_eq(_count(scene, "House?", "MeshInstance3D"), 3, "casas")
	assert_eq(_count(scene, "Tree*", "MeshInstance3D"), RendererMarketData.TREE_COUNT, "árvores")
	assert_eq(_count(scene, "Well", "MeshInstance3D"), 1, "poço")
	assert_eq(scene.built.lamp_lights.size(), 4, "luzes dos lampiões")
	assert_eq(_count(scene, "*", "OmniLight3D"), 4 + RendererMarketData.TORCH_SPOTS.size(), "luzes pequenas (lampiões e tochas)")
	assert_eq(_count(scene, "*", "DirectionalLight3D"), 1, "sol")
	var instances: int = 0
	for node: Node in scene.find_children("*", "MultiMeshInstance3D", true, false):
		instances += (node as MultiMeshInstance3D).multimesh.instance_count
	assert_eq(instances, RendererMarketData.GRASS_COUNT + RendererMarketData.FLOWERS_PER_COLOR * RendererMarketData.FLOWER_COLORS.size(), "instâncias de grama e flores")


func test_triangle_and_material_budgets() -> void:
	var scene: RendererTestScene = _build()
	var triangles: int = scene.triangle_count()
	assert_between(triangles, 1, RendererTestScene.TRIANGLE_BUDGET, "triângulos dentro do orçamento (%d)" % triangles)
	assert_lte(scene.built.materials.size(), RendererTestScene.MAX_MATERIALS, "materiais compartilhados")


func test_two_builds_are_identical() -> void:
	var first: int = _build().fingerprint()
	assert_ne(first, 0, "a montagem produziu geometria")
	assert_eq(_build().fingerprint(), first, "duas montagens iguais")


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


func test_scene_turns_effects_on_only_with_renderer_support() -> void:
	var none: Dictionary[StringName, bool] = RendererPresets.supported_effects("dummy")
	var scene: RendererTestScene = _build()
	scene.supported = none
	scene.apply_preset(2)
	assert_false(scene.environment.glow_enabled or scene.environment.ssao_enabled or scene.environment.volumetric_fog_enabled or scene.environment.fog_enabled, "nada ligado sem suporte")
	scene.supported = COMPAT_SAFE
	scene.apply_preset(2)
	assert_true(scene.environment.glow_enabled and scene.environment.fog_enabled, "o que tem suporte liga")
	assert_false(scene.environment.ssao_enabled or scene.environment.volumetric_fog_enabled or (scene.camera.attributes as CameraAttributesPractical).dof_blur_far_enabled, "o que não tem suporte continua desligado")


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
