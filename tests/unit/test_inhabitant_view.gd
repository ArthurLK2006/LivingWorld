extends GutTest

## ART-9, o nó do habitante e a cena de demonstração montada (sem renderizar): um MeshInstance3D só, respiração pequena e movida pelo `delta`, o alinhamento dos seis e a multidão de 132 com LOD pela distância da câmera.
const SCENE_PATH: String = "res://scenes/demo/inhabitants_demo.tscn"
const LINEUP_SIZE: int = 6
const BREATH_STEPS: int = 120
const BREATH_STEP_S: float = 0.05
const TOLERANCE: float = 0.0001


func _count_near(scene: InhabitantsDemoScene) -> int:
	var near: int = 0
	for view: Node in scene.get_node("Inhabitants").get_children():
		near += int((view as InhabitantView).lod == InhabitantBuilder.LOD_NEAR)
	return near


func test_spawn_builds_one_mesh_node_and_respawn_reuses_it() -> void:
	var view: InhabitantView = InhabitantView.new()
	add_child_autofree(view)
	view.spawn(InhabitantSpec.for_inhabitant(3, InhabitantSpec.GUARD), InhabitantBuilder.LOD_NEAR)
	assert_eq(view.get_child_count(), 1, "um nó só")
	assert_eq((view.get_child(0) as MeshInstance3D).mesh.get_surface_count(), 1, "uma superfície")
	assert_true(view.is_processing(), "de perto respira")
	view.spawn(InhabitantSpec.for_inhabitant(4, InhabitantSpec.MERCHANT), InhabitantBuilder.LOD_FAR)
	assert_eq(view.get_child_count(), 1, "remontar troca só a malha")
	assert_false(view.is_processing(), "de longe não respira")


func test_breathing_is_small_and_driven_by_delta() -> void:
	var view: InhabitantView = InhabitantView.new()
	add_child_autofree(view)
	view.spawn(InhabitantSpec.for_inhabitant(5, InhabitantSpec.VILLAGER), InhabitantBuilder.LOD_NEAR)
	var body: MeshInstance3D = view.get_child(0) as MeshInstance3D
	var widest: float = 0.0
	for step: int in BREATH_STEPS:
		simulate(view, 1, BREATH_STEP_S)
		widest = maxf(widest, absf(body.scale.y - 1.0))
		assert_lte(absf(body.rotation.z), InhabitantView.SWAY_RAD + TOLERANCE, "balanço pequeno")
	assert_gt(widest, 0.0, "respira")
	assert_lte(widest, InhabitantView.BREATH_AMOUNT + TOLERANCE, "respiração pequena")


func test_demo_scene_stages_the_lineup_and_the_crowd_with_lod_by_distance() -> void:
	var scene: InhabitantsDemoScene = (load(SCENE_PATH) as PackedScene).instantiate()
	add_child_autofree(scene)
	assert_eq(scene.get_node("Inhabitants").get_child_count(), LINEUP_SIZE, "o alinhamento dos seis")
	scene.apply_view(InhabitantsDemoScene.ISOMETRIC_VIEW)
	scene.stage_crowd()
	assert_eq(scene.get_node("Inhabitants").get_child_count(), InhabitantsDemoScene.CROWD_SIZE, "multidão de 132")
	assert_between(_count_near(scene), 1, InhabitantsDemoScene.CROWD_SIZE - 1, "isométrica: perto e longe misturados")
	scene.apply_view(InhabitantsDemoScene.STRATEGIC_VIEW)
	scene.stage_crowd()
	assert_eq(_count_near(scene), 0, "estratégica: todos de longe")
