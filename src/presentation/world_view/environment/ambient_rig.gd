class_name AmbientRig
extends Node
## Aplica o AmbientConfig ao WorldEnvironment e ao Sol (DirectionalLight3D) da cena principal (LW-041). Sem regra
## de jogo e sem estado: o ambiente é função do recurso. Sol e ambiente não conhecem a simulação nesta tarefa.

@export var config: AmbientConfig
@export var environment_path: NodePath = ^"../Environment"
@export var sun_path: NodePath = ^"../Sun"


func _ready() -> void:
	apply()


## Resolve os nós pelos caminhos e aplica o recurso. Falha visível (push_error) se faltar nó ou recurso válido.
func apply() -> bool:
	var world_environment: WorldEnvironment = get_node_or_null(environment_path) as WorldEnvironment
	var sun: DirectionalLight3D = get_node_or_null(sun_path) as DirectionalLight3D
	if world_environment == null or sun == null:
		push_error("AmbientRig: WorldEnvironment em '%s' ou DirectionalLight3D em '%s' não encontrado." % [str(environment_path), str(sun_path)])
		return false
	return apply_to(world_environment, sun)


func apply_to(world_environment: WorldEnvironment, sun: DirectionalLight3D) -> bool:
	if config == null:
		push_error("AmbientRig: sem AmbientConfig; esperado o recurso em assets/environment/.")
		return false
	var problems: Array[String] = config.validate()
	if not problems.is_empty():
		push_error("AmbientRig: AmbientConfig inválido: %s." % "; ".join(problems))
		return false
	_apply_sun(sun)
	_apply_environment(world_environment)
	return true


func _apply_sun(sun: DirectionalLight3D) -> void:
	sun.light_color = config.sun_color
	sun.light_energy = config.sun_energy
	sun.rotation_degrees = Vector3(-config.sun_elevation_degrees, config.sun_yaw_degrees, 0.0)
	sun.shadow_enabled = config.shadows_enabled
	sun.directional_shadow_mode = config.shadow_mode
	sun.directional_shadow_max_distance = config.shadow_max_distance_m
	sun.shadow_bias = config.shadow_bias
	sun.shadow_normal_bias = config.shadow_normal_bias
	sun.shadow_blur = config.shadow_blur


## Cria o que faltar (Environment, Sky e material do céu) e grava os valores do recurso, sem acrescentar nada.
func _apply_environment(world_environment: WorldEnvironment) -> void:
	var environment: Environment = world_environment.environment
	if environment == null:
		environment = Environment.new()
		world_environment.environment = environment
	if environment.sky == null:
		environment.sky = Sky.new()
	var sky_material: ProceduralSkyMaterial = environment.sky.sky_material as ProceduralSkyMaterial
	if sky_material == null:
		sky_material = ProceduralSkyMaterial.new()
		environment.sky.sky_material = sky_material
	environment.background_mode = Environment.BG_SKY
	sky_material.sky_top_color = config.sky_top_color
	sky_material.sky_horizon_color = config.sky_horizon_color
	sky_material.ground_horizon_color = config.ground_horizon_color
	sky_material.ground_bottom_color = config.ground_bottom_color
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = config.ambient_color
	environment.ambient_light_energy = config.ambient_energy
	environment.fog_enabled = config.fog_enabled
	environment.fog_light_color = config.fog_color
	environment.fog_density = config.fog_density
	environment.fog_sky_affect = config.fog_sky_affect
