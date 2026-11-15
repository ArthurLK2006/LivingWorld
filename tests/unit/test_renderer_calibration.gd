extends GutTest
## M1: ajuste de luz por renderer. O recurso do Mobile carrega e está em faixa; o AmbientRig só o aplica quando o renderer em uso é o dele (com o Compatibility a luz sai exatamente como o AmbientConfig a define);
## os multiplicadores chegam ao sol, à luz ambiente, à exposição, à saturação e ao bloom; ajuste inválido falha visível. Sem janela.

const CONFIG_PATH: String = "res://assets/environment/ambient_default.tres"
const MOBILE_PATH: String = "res://assets/environment/renderer_calibration_mobile.tres"
const MAIN_SCENE_PATH: String = "res://scenes/main.tscn"
const TOLERANCE: float = 0.0001
const SUN_SCALE: float = 2.6
const AMBIENT_SCALE: float = 1.2
const CUSTOM_EXPOSURE: float = 1.5
const CUSTOM_SATURATION: float = 0.8
const CUSTOM_GLOW: float = 2.0
const OUT_OF_RANGE: float = 99.0


func _config() -> AmbientConfig:
	return load(CONFIG_PATH) as AmbientConfig


## Aplica o dia pleno com o `method` de renderizador e os ajustes dados; devolve [WorldEnvironment, DirectionalLight3D] (quem chama libera).
func _applied(method: String, calibrations: Array[RendererCalibration]) -> Array[Node]:
	var rig: AmbientRig = AmbientRig.new()
	rig.config = _config()
	rig.calibrations = calibrations
	rig.rendering_method = method
	var world_environment: WorldEnvironment = WorldEnvironment.new()
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	assert_true(rig.apply_to(world_environment, sun))
	rig.free()
	var nodes: Array[Node] = [world_environment, sun]
	return nodes


func _mobile() -> RendererCalibration:
	return load(MOBILE_PATH) as RendererCalibration


func test_the_mobile_resource_loads_in_range_with_the_measured_scales() -> void:
	var calibration: RendererCalibration = _mobile()
	assert_not_null(calibration)
	assert_eq(calibration.validate(), [] as Array[String])
	assert_eq(calibration.renderer, "mobile")
	assert_almost_eq(calibration.sun_energy_scale, SUN_SCALE, TOLERANCE)
	assert_almost_eq(calibration.ambient_energy_scale, AMBIENT_SCALE, TOLERANCE)
	assert_eq(calibration.exposure_scale, 1.0, "Exposição, saturação e bloom ficam neutros: a medição não pediu ajuste.")
	assert_eq(calibration.saturation_scale, 1.0)
	assert_eq(calibration.glow_intensity_scale, 1.0)
	assert_eq(calibration.glow_bloom_scale, 1.0)
	assert_eq(calibration.glow_threshold_scale, 1.0)


func test_validate_names_each_field_out_of_range_and_an_empty_renderer() -> void:
	var calibration: RendererCalibration = RendererCalibration.new()
	assert_eq(calibration.validate().size(), 0, "O padrão é neutro e válido.")
	calibration.sun_energy_scale = OUT_OF_RANGE
	calibration.exposure_scale = -1.0
	calibration.renderer = ""
	var problems: Array[String] = calibration.validate()
	assert_eq(problems.size(), 3)
	assert_string_contains(" ".join(PackedStringArray(problems)), "sun_energy_scale")
	assert_string_contains(" ".join(PackedStringArray(problems)), "exposure_scale")


func test_the_mobile_calibration_scales_the_sun_and_the_ambient_only_under_the_mobile_renderer() -> void:
	var config: AmbientConfig = _config()
	var plain: Array[Node] = _applied("gl_compatibility", [] as Array[RendererCalibration])
	var compat: Array[Node] = _applied("gl_compatibility", [_mobile()] as Array[RendererCalibration])
	var mobile: Array[Node] = _applied("mobile", [_mobile()] as Array[RendererCalibration])
	var plain_sun: DirectionalLight3D = plain[1] as DirectionalLight3D
	var compat_sun: DirectionalLight3D = compat[1] as DirectionalLight3D
	var mobile_sun: DirectionalLight3D = mobile[1] as DirectionalLight3D
	assert_eq(compat_sun.light_energy, plain_sun.light_energy, "Com o Compatibility o ajuste do Mobile não vale: a luz é a do recurso, exatamente.")
	assert_almost_eq(plain_sun.light_energy, config.sun_energy, TOLERANCE)
	assert_almost_eq(mobile_sun.light_energy, config.sun_energy * SUN_SCALE, TOLERANCE)
	var plain_environment: Environment = (plain[0] as WorldEnvironment).environment
	var compat_environment: Environment = (compat[0] as WorldEnvironment).environment
	var mobile_environment: Environment = (mobile[0] as WorldEnvironment).environment
	assert_eq(compat_environment.ambient_light_energy, plain_environment.ambient_light_energy)
	assert_almost_eq(mobile_environment.ambient_light_energy, config.ambient_energy * AMBIENT_SCALE, TOLERANCE)
	assert_eq(mobile_environment.tonemap_exposure, plain_environment.tonemap_exposure, "O que o ajuste não escala fica igual.")
	assert_eq(mobile_environment.glow_intensity, plain_environment.glow_intensity)
	for node: Node in plain + compat + mobile:
		node.free()


func test_the_other_scales_reach_exposure_saturation_and_bloom() -> void:
	var config: AmbientConfig = _config()
	var custom: RendererCalibration = RendererCalibration.new()
	custom.renderer = "forward_plus"
	custom.exposure_scale = CUSTOM_EXPOSURE
	custom.saturation_scale = CUSTOM_SATURATION
	custom.glow_intensity_scale = CUSTOM_GLOW
	custom.glow_bloom_scale = CUSTOM_GLOW
	custom.glow_threshold_scale = CUSTOM_GLOW
	var nodes: Array[Node] = _applied("forward_plus", [_mobile(), custom] as Array[RendererCalibration])
	var environment: Environment = (nodes[0] as WorldEnvironment).environment
	assert_almost_eq(environment.tonemap_exposure, config.exposure * CUSTOM_EXPOSURE, TOLERANCE)
	assert_almost_eq(environment.adjustment_saturation, config.saturation * CUSTOM_SATURATION, TOLERANCE)
	assert_almost_eq(environment.glow_intensity, config.glow_intensity * CUSTOM_GLOW, TOLERANCE)
	assert_almost_eq(environment.glow_bloom, config.glow_bloom * CUSTOM_GLOW, TOLERANCE)
	assert_almost_eq(environment.glow_hdr_threshold, config.glow_hdr_threshold * CUSTOM_GLOW, TOLERANCE)
	assert_almost_eq((nodes[1] as DirectionalLight3D).light_energy, config.sun_energy, TOLERANCE, "O ajuste do Mobile não vale no Forward+: vale o primeiro cujo renderer é o em uso.")
	for node: Node in nodes:
		node.free()


func test_an_invalid_calibration_for_the_renderer_in_use_fails_visibly() -> void:
	var broken: RendererCalibration = RendererCalibration.new()
	broken.sun_energy_scale = OUT_OF_RANGE
	var rig: AmbientRig = AmbientRig.new()
	rig.config = _config()
	rig.calibrations = [broken] as Array[RendererCalibration]
	rig.rendering_method = "mobile"
	var world_environment: WorldEnvironment = WorldEnvironment.new()
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	assert_false(rig.apply_to(world_environment, sun))
	assert_push_error("RendererCalibration inválido")
	rig.rendering_method = "gl_compatibility"
	assert_true(rig.apply_to(world_environment, sun), "Para o Compatibility o ajuste inválido do Mobile nem é lido.")
	for node: Node in [rig, world_environment, sun]:
		node.free()


func test_the_main_scene_carries_the_mobile_calibration() -> void:
	var main: Node = (load(MAIN_SCENE_PATH) as PackedScene).instantiate()
	var rig: AmbientRig = main.get_node("AmbientRig") as AmbientRig
	assert_eq(rig.calibrations.size(), 1)
	assert_eq(rig.calibrations[0].resource_path, MOBILE_PATH)
	main.free()
