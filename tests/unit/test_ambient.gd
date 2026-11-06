extends GutTest
## LW-041: ambiente estático. O recurso editável carrega e está em faixa; o AmbientRig aplica EXATAMENTE os valores
## dele ao Environment e à luz; a cena principal tem 1 WorldEnvironment e 1 DirectionalLight3D com sombra. Sem janela.

const DEFAULT_CONFIG_PATH: String = "res://assets/environment/ambient_default.tres"
const MAIN_SCENE_PATH: String = "res://scenes/main.tscn"
const FLOAT_TOLERANCE: float = 0.0001
## Valor de teste fora da faixa de qualquer campo de energia.
const NEGATIVE_ENERGY: float = -1.0
const CHANGED_ENERGY: float = 2.5
const CHANGED_DENSITY: float = 0.01
const CHANGED_SKY: Color = Color(0.9, 0.1, 0.2)
const SCENE_FRAMES: int = 3


func _default_config() -> AmbientConfig:
	return load(DEFAULT_CONFIG_PATH) as AmbientConfig


func _rig_with(config: AmbientConfig) -> AmbientRig:
	var rig: AmbientRig = AmbientRig.new()
	rig.config = config
	return rig


## Aplica `config` a um WorldEnvironment e a um Sol novos (fora da árvore) e devolve os dois.
func _apply(config: AmbientConfig) -> Array[Node]:
	var world_environment: WorldEnvironment = WorldEnvironment.new()
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	var rig: AmbientRig = _rig_with(config)
	assert_true(rig.apply_to(world_environment, sun))
	rig.free()
	var nodes: Array[Node] = [world_environment, sun]
	return nodes


func _free_all(nodes: Array[Node]) -> void:
	for node: Node in nodes:
		node.free()


func _assert_applied(config: AmbientConfig, world_environment: WorldEnvironment, sun: DirectionalLight3D) -> void:
	_assert_fixed_parts(config, world_environment, sun)
	assert_almost_eq(sun.light_energy, config.sun_energy, FLOAT_TOLERANCE)
	assert_true(sun.rotation_degrees.is_equal_approx(Vector3(-config.sun_elevation_degrees, config.sun_yaw_degrees, 0.0)), "Rotação do sol: x = -inclinação, y = giro.")
	var sky: ProceduralSkyMaterial = world_environment.environment.sky.sky_material as ProceduralSkyMaterial
	assert_eq(sky.sky_top_color, config.sky_top_color)
	assert_eq(sky.sky_horizon_color, config.sky_horizon_color)
	assert_eq(sky.ground_horizon_color, config.ground_horizon_color)
	assert_eq(sky.ground_bottom_color, config.ground_bottom_color)
	assert_eq(world_environment.environment.ambient_light_color, config.ambient_color)
	assert_almost_eq(world_environment.environment.ambient_light_energy, config.ambient_energy, FLOAT_TOLERANCE)
	assert_eq(world_environment.environment.fog_light_color, config.fog_color)


## Valores que NÃO dependem da hora (a partir da LW-042 a luz e as cores são função da hora simulada).
func _assert_fixed_parts(config: AmbientConfig, world_environment: WorldEnvironment, sun: DirectionalLight3D) -> void:
	assert_eq(sun.light_color, config.sun_color)
	assert_eq(sun.shadow_enabled, config.shadows_enabled)
	assert_eq(sun.directional_shadow_mode, config.shadow_mode)
	assert_almost_eq(sun.directional_shadow_max_distance, config.shadow_max_distance_m, FLOAT_TOLERANCE)
	assert_almost_eq(sun.shadow_bias, config.shadow_bias, FLOAT_TOLERANCE)
	assert_almost_eq(sun.shadow_normal_bias, config.shadow_normal_bias, FLOAT_TOLERANCE)
	assert_almost_eq(sun.shadow_blur, config.shadow_blur, FLOAT_TOLERANCE)
	var environment: Environment = world_environment.environment
	assert_eq(environment.background_mode, Environment.BG_SKY)
	assert_eq(environment.ambient_light_source, Environment.AMBIENT_SOURCE_COLOR)
	assert_eq(environment.fog_enabled, config.fog_enabled)
	assert_almost_eq(environment.fog_density, config.fog_density, FLOAT_TOLERANCE)
	assert_almost_eq(environment.fog_sky_affect, config.fog_sky_affect, FLOAT_TOLERANCE)


func test_the_default_resource_loads_and_every_field_is_in_range() -> void:
	var config: AmbientConfig = _default_config()
	assert_not_null(config, "O .tres tem de carregar como AmbientConfig.")
	assert_eq(config.validate(), [] as Array[String], "Campos fora de faixa.")
	for color: Color in [config.sun_color, config.sky_top_color, config.sky_horizon_color, config.ground_horizon_color, config.ground_bottom_color, config.ambient_color, config.fog_color]:
		assert_true(color.r >= 0.0 and color.r <= 1.0 and color.g >= 0.0 and color.g <= 1.0 and color.b >= 0.0 and color.b <= 1.0, "Cor fora de 0 a 1: %s" % str(color))
	assert_true(config.shadows_enabled, "O sol do dia projeta sombra.")
	assert_eq(config.shadow_mode, DirectionalLight3D.SHADOW_ORTHOGONAL, "Sombra simples: uma divisão só.")


func test_validate_reports_each_out_of_range_field() -> void:
	var config: AmbientConfig = _default_config().duplicate() as AmbientConfig
	config.sun_energy = NEGATIVE_ENERGY
	config.fog_density = NAN
	var problems: Array[String] = config.validate()
	assert_eq(problems.size(), 2)
	assert_string_contains("\n".join(problems), "sun_energy")
	assert_string_contains("\n".join(problems), "fog_density")


func test_the_rig_applies_exactly_the_values_of_the_resource() -> void:
	var config: AmbientConfig = _default_config()
	var nodes: Array[Node] = _apply(config)
	_assert_applied(config, nodes[0] as WorldEnvironment, nodes[1] as DirectionalLight3D)
	_free_all(nodes)


func test_sensitivity_changing_a_resource_value_changes_the_applied_result() -> void:
	var config: AmbientConfig = _default_config().duplicate() as AmbientConfig
	var before: Array[Node] = _apply(config)
	config.sun_energy = CHANGED_ENERGY
	config.fog_density = CHANGED_DENSITY
	config.sky_top_color = CHANGED_SKY
	var after: Array[Node] = _apply(config)
	var sun_before: DirectionalLight3D = before[1] as DirectionalLight3D
	var sun_after: DirectionalLight3D = after[1] as DirectionalLight3D
	assert_ne(sun_before.light_energy, sun_after.light_energy)
	assert_almost_eq(sun_after.light_energy, CHANGED_ENERGY, FLOAT_TOLERANCE)
	var environment_after: Environment = (after[0] as WorldEnvironment).environment
	assert_almost_eq(environment_after.fog_density, CHANGED_DENSITY, FLOAT_TOLERANCE)
	assert_eq((environment_after.sky.sky_material as ProceduralSkyMaterial).sky_top_color, CHANGED_SKY)
	_assert_applied(config, after[0] as WorldEnvironment, sun_after)
	_free_all(before)
	_free_all(after)


func test_an_invalid_resource_or_missing_nodes_apply_nothing_with_a_visible_error() -> void:
	var config: AmbientConfig = _default_config().duplicate() as AmbientConfig
	config.sun_energy = NEGATIVE_ENERGY
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	var untouched_energy: float = sun.light_energy
	var world_environment: WorldEnvironment = WorldEnvironment.new()
	var invalid_rig: AmbientRig = _rig_with(config)
	assert_false(invalid_rig.apply_to(world_environment, sun))
	assert_push_error("fora da faixa")
	assert_eq(sun.light_energy, untouched_energy, "Recurso inválido: nada é aplicado.")
	assert_null(world_environment.environment)
	var empty_rig: AmbientRig = AmbientRig.new()
	assert_false(empty_rig.apply_to(world_environment, sun))
	assert_push_error("sem AmbientConfig")
	var lonely_rig: AmbientRig = _rig_with(_default_config())
	assert_false(lonely_rig.apply())
	assert_push_error("não encontrado")
	for node: Node in [sun, world_environment, invalid_rig, empty_rig, lonely_rig]:
		node.free()


func test_the_main_scene_has_one_environment_and_one_shadowed_sun_with_the_resource_applied() -> void:
	var main: Node = (load(MAIN_SCENE_PATH) as PackedScene).instantiate()
	assert_eq(main.find_children("*", "WorldEnvironment", true, false).size(), 1)
	var suns: Array[Node] = main.find_children("*", "DirectionalLight3D", true, false)
	assert_eq(suns.size(), 1)
	assert_true((suns[0] as DirectionalLight3D).shadow_enabled, "A cena já nasce com a sombra ligada.")
	add_child_autofree(main)
	for frame: int in range(SCENE_FRAMES):
		await get_tree().process_frame
	var rig: AmbientRig = main.get_node("AmbientRig") as AmbientRig
	assert_not_null(rig)
	assert_eq(rig.config.resource_path, DEFAULT_CONFIG_PATH, "A cena usa o recurso editável de assets/environment.")
	var world_environment: WorldEnvironment = main.get_node("Environment") as WorldEnvironment
	var sun: DirectionalLight3D = main.get_node("Sun") as DirectionalLight3D
	_assert_fixed_parts(rig.config, world_environment, sun)
	# O jogo nasce à meia-noite (LW-042): a luz é a da noite, com o sol bem abaixo do horizonte.
	var sky: ProceduralSkyMaterial = world_environment.environment.sky.sky_material as ProceduralSkyMaterial
	assert_eq(sun.light_energy, 0.0)
	assert_eq(sky.sky_top_color, rig.config.night_sky_top_color)
	assert_eq(world_environment.environment.ambient_light_color, rig.config.night_ambient_color)
	assert_eq(world_environment.environment.fog_light_color, rig.config.night_fog_color)
