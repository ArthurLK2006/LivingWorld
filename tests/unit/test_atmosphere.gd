extends GutTest
## ART-4: a atmosfera aprovada da cena demonstrativa (RendererPresets.PRESETS: dia, hora dourada e crepúsculo) no ciclo de dia e noite do jogo. A cena é a fonte da verdade: o estado do jogo é comparado
## com as predefinições dela, dentro de PRESET_TOLERANCE; a noite, com os números ESCRITOS À MÃO da LW-042. Sem janela.
const DEFAULT_CONFIG_PATH: String = "res://assets/environment/ambient_default.tres"
const DAY: int = 0
const GOLDEN: int = 1
const DUSK: int = 2
## Erro aceito entre o jogo e a cena: 8 bits por canal mais as horas escritas à mão (o sol erra menos de 0,01 grau da âncora e a mistura tem derivada zero nela).
const PRESET_TOLERANCE: float = 0.002
const EXACT_TOLERANCE: float = 0.000001
const ELEVATION_TOLERANCE: float = 0.01
## Horas escritas à mão em que o sol está a 9 graus (hora dourada) e a 3 graus (crepúsculo), [manhã, tarde]: 60 x sin(TAU x (h - 6) / 24).
const GOLDEN_HOURS: Array[float] = [6.575, 17.425]
const DUSK_HOURS: Array[float] = [6.191, 17.809]
const NIGHT_HOURS: Array[float] = [0.0, 3.0, 5.0, 19.0, 23.9]
const NOON: float = 12.0
const MINUTES_PER_DAY: int = 1440
## Maior mudança aceita entre dois minutos vizinhos. Pior caso medido nas curvas [HIP]: energia 0,078; giro 1,96 graus; cor 0,036; densidade da névoa 0,00007; bloom 0,013. Um degrau entre paletas é muito maior.
const MAX_MINUTE_STEP_ENERGY: float = 0.1
const MAX_MINUTE_STEP_YAW: float = 3.0
const MAX_MINUTE_STEP_COLOR: float = 0.05
const MAX_MINUTE_STEP_FOG: float = 0.0001
const MAX_MINUTE_STEP_GLOW: float = 0.02
const GAP_HOURS: Array[float] = [6.2, 6.7]
const CHANGED_BLOOM: float = 2.0


func _config() -> AmbientConfig:
	return load(DEFAULT_CONFIG_PATH) as AmbientConfig


func _number(preset: Dictionary, key: String) -> float:
	return preset[key]


func _color(preset: Dictionary, key: String) -> Color:
	return preset[key]


func _assert_color(actual: Color, expected: Color, label: String, tolerance: float = PRESET_TOLERANCE) -> void:
	for channel: int in range(3):
		assert_almost_eq(actual[channel], expected[channel], tolerance, "%s, canal %d" % [label, channel])


## Confere o estado do jogo com a predefinição da cena: sol, ambiente, céu, névoa (a razão com a do dia, na escala do jogo) e bloom.
func _assert_preset(state: DayNightCycle.LightState, index: int) -> void:
	var preset: Dictionary = RendererPresets.PRESETS[index]
	var label: String = str(preset["name"])
	_assert_color(state.sun_color, _color(preset, "sun_color"), label + ": cor do sol")
	assert_almost_eq(state.sun_energy, _number(preset, "sun_energy"), PRESET_TOLERANCE, label + ": energia do sol")
	assert_almost_eq(state.sun_yaw_degrees, _number(preset, "sun_yaw"), PRESET_TOLERANCE, label + ": giro do sol")
	_assert_color(state.ambient_color, _color(preset, "ambient_color"), label + ": cor do ambiente")
	assert_almost_eq(state.ambient_energy, _number(preset, "ambient_energy"), PRESET_TOLERANCE, label + ": energia do ambiente")
	_assert_color(state.sky_top_color, _color(preset, "sky_top"), label + ": topo do céu")
	_assert_color(state.sky_horizon_color, _color(preset, "sky_horizon"), label + ": horizonte do céu")
	_assert_color(state.ground_horizon_color, _color(preset, "sky_horizon"), label + ": o chão do horizonte tem a cor do horizonte")
	_assert_color(state.ground_bottom_color, _color(preset, "sky_ground"), label + ": fundo do chão do céu")
	_assert_color(state.fog_color, _color(preset, "fog_color"), label + ": cor da névoa")
	var fog_ratio: float = _number(preset, "fog_density") / _number(RendererPresets.PRESETS[DAY], "fog_density")
	assert_almost_eq(state.fog_density / _config().fog_density, fog_ratio, PRESET_TOLERANCE, label + ": razão da névoa com a do dia")
	assert_almost_eq(state.glow_intensity, _number(preset, "glow"), PRESET_TOLERANCE, label + ": intensidade do bloom")
	assert_almost_eq(state.glow_hdr_threshold, _number(preset, "glow_threshold"), PRESET_TOLERANCE, label + ": limiar do bloom")
	assert_almost_eq(state.glow_bloom, _number(preset, "bloom"), PRESET_TOLERANCE, label + ": bloom")


func _weights_at(elevation: float) -> Array[float]:
	var weights: DayNightCycle.PaletteWeights = DayNightCycle.palette_weights(_config(), elevation)
	var result: Array[float] = [weights.night, weights.dusk, weights.golden, weights.day]
	return result


func _colors(state: DayNightCycle.LightState) -> Array[Color]:
	var colors: Array[Color] = [state.sun_color, state.sky_top_color, state.sky_horizon_color, state.ground_horizon_color, state.ground_bottom_color, state.ambient_color, state.fog_color]
	return colors


## Guarda em `worst` a maior mudança de cada grandeza entre dois estados.
func _track_steps(worst: Dictionary[String, float], first: DayNightCycle.LightState, second: DayNightCycle.LightState) -> void:
	worst["energy"] = maxf(worst["energy"], maxf(absf(first.sun_energy - second.sun_energy), absf(first.ambient_energy - second.ambient_energy)))
	worst["yaw"] = maxf(worst["yaw"], absf(first.sun_yaw_degrees - second.sun_yaw_degrees))
	worst["fog"] = maxf(worst["fog"], absf(first.fog_density - second.fog_density))
	worst["glow"] = maxf(worst["glow"], maxf(absf(first.glow_intensity - second.glow_intensity), maxf(absf(first.glow_hdr_threshold - second.glow_hdr_threshold), absf(first.glow_bloom - second.glow_bloom))))
	var first_colors: Array[Color] = _colors(first)
	var second_colors: Array[Color] = _colors(second)
	for index: int in range(first_colors.size()):
		for channel: int in range(3):
			worst["color"] = maxf(worst["color"], absf(first_colors[index][channel] - second_colors[index][channel]))


func _new_worst() -> Dictionary[String, float]:
	var worst: Dictionary[String, float] = {"energy": 0.0, "yaw": 0.0, "color": 0.0, "fog": 0.0, "glow": 0.0}
	return worst


func test_noon_is_the_demonstration_day_preset_at_the_scale_of_the_game_fog() -> void:
	var noon: DayNightCycle.LightState = DayNightCycle.state_at(_config(), NOON)
	_assert_preset(noon, DAY)
	assert_almost_eq(noon.fog_density, 0.0004, EXACT_TOLERANCE, "A névoa do dia é a que o jogo já tinha (0,0004), e não a da praça de 36 m (0,0025).")


func test_the_golden_hour_elevation_gives_the_demonstration_golden_preset_in_the_morning_and_the_evening() -> void:
	for hour: float in GOLDEN_HOURS:
		var state: DayNightCycle.LightState = DayNightCycle.state_at(_config(), hour)
		assert_almost_eq(state.elevation_degrees, 9.0, ELEVATION_TOLERANCE, "Sol a 9 graus às %s h." % str(hour))
		_assert_preset(state, GOLDEN)
	assert_almost_eq(DayNightCycle.state_at(_config(), GOLDEN_HOURS[0]).fog_density, 0.00096, EXACT_TOLERANCE, "0,0004 x (0,006 / 0,0025).")


func test_the_dusk_elevation_gives_the_demonstration_dusk_preset_in_the_morning_and_the_evening() -> void:
	for hour: float in DUSK_HOURS:
		var state: DayNightCycle.LightState = DayNightCycle.state_at(_config(), hour)
		assert_almost_eq(state.elevation_degrees, 3.0, ELEVATION_TOLERANCE, "Sol a 3 graus às %s h." % str(hour))
		_assert_preset(state, DUSK)
	assert_almost_eq(DayNightCycle.state_at(_config(), DUSK_HOURS[1]).fog_density, 0.00128, EXACT_TOLERANCE, "0,0004 x (0,008 / 0,0025).")


func test_the_night_did_not_change() -> void:
	for hour: float in NIGHT_HOURS:
		var night: DayNightCycle.LightState = DayNightCycle.state_at(_config(), hour)
		assert_eq(night.sun_energy, 0.0, "Sol apagado às %s h." % str(hour))
		_assert_color(night.sky_top_color, Color(0.02, 0.03, 0.10), "topo do céu", EXACT_TOLERANCE)
		_assert_color(night.sky_horizon_color, Color(0.07, 0.10, 0.22), "horizonte", EXACT_TOLERANCE)
		_assert_color(night.ground_bottom_color, Color(0.03, 0.05, 0.07), "fundo do chão", EXACT_TOLERANCE)
		_assert_color(night.ambient_color, Color(0.45, 0.55, 0.85), "ambiente", EXACT_TOLERANCE)
		assert_almost_eq(night.ambient_energy, 0.5, EXACT_TOLERANCE, "energia do ambiente às %s h." % str(hour))
		_assert_color(night.fog_color, Color(0.05, 0.07, 0.15), "névoa", EXACT_TOLERANCE)
		assert_almost_eq(night.fog_density, 0.0004, EXACT_TOLERANCE, "densidade da névoa às %s h." % str(hour))


func test_the_elevation_anchors_come_from_the_demonstration_and_each_palette_is_pure_there() -> void:
	var config: AmbientConfig = _config()
	assert_eq(config.sun_elevation_degrees, _number(RendererPresets.PRESETS[DAY], "sun_pitch"), "Dia: a inclinação da cena.")
	assert_eq(config.golden_hour_degrees, _number(RendererPresets.PRESETS[GOLDEN], "sun_pitch"), "Hora dourada: a inclinação da cena.")
	assert_eq(config.daylight_to_degrees, _number(RendererPresets.PRESETS[DUSK], "sun_pitch"), "Crepúsculo: a inclinação da cena.")
	assert_between(config.full_day_degrees, 45.0, config.sun_max_elevation_degrees, "Dia pleno de 45 graus para cima (a cena usa 45 a 60).")
	assert_eq(_weights_at(-60.0), [1.0, 0.0, 0.0, 0.0] as Array[float], "Meia-noite: noite pura.")
	assert_eq(_weights_at(config.daylight_from_degrees), [1.0, 0.0, 0.0, 0.0] as Array[float], "A noite pura vai até -2 graus, como antes.")
	assert_eq(_weights_at(3.0), [0.0, 1.0, 0.0, 0.0] as Array[float], "3 graus: crepúsculo puro.")
	assert_eq(_weights_at(9.0), [0.0, 0.0, 1.0, 0.0] as Array[float], "9 graus: hora dourada pura.")
	assert_eq(_weights_at(45.0), [0.0, 0.0, 0.0, 1.0] as Array[float], "45 graus: dia puro.")
	assert_eq(_weights_at(60.0), [0.0, 0.0, 0.0, 1.0] as Array[float], "Meio-dia: dia puro.")
	for elevation: float in [-10.0, -1.0, 0.0, 1.5, 3.0, 6.0, 9.0, 20.0, 30.0, 44.0, 60.0]:
		var weights: Array[float] = _weights_at(elevation)
		assert_almost_eq(weights[0] + weights[1] + weights[2] + weights[3], 1.0, EXACT_TOLERANCE, "Os pesos somam 1 a %s graus." % str(elevation))


func test_the_light_has_no_jump_between_neighbouring_minutes_over_24_hours() -> void:
	var config: AmbientConfig = _config()
	var worst: Dictionary[String, float] = _new_worst()
	var previous: DayNightCycle.LightState = DayNightCycle.state_at(config, 0.0)
	for minute: int in range(1, MINUTES_PER_DAY + 1):
		var current: DayNightCycle.LightState = DayNightCycle.state_at(config, float(minute) / DayNightCycle.MINUTES_PER_HOUR)
		_track_steps(worst, previous, current)
		previous = current
	assert_lt(worst["energy"], MAX_MINUTE_STEP_ENERGY, "Energia do sol e do ambiente.")
	assert_lt(worst["yaw"], MAX_MINUTE_STEP_YAW, "Giro do sol.")
	assert_lt(worst["color"], MAX_MINUTE_STEP_COLOR, "Cores (sol, céu, ambiente e névoa).")
	assert_lt(worst["fog"], MAX_MINUTE_STEP_FOG, "Densidade da névoa.")
	assert_lt(worst["glow"], MAX_MINUTE_STEP_GLOW, "Bloom.")
	var gap: Dictionary[String, float] = _new_worst()
	_track_steps(gap, DayNightCycle.state_at(config, GAP_HOURS[0]), DayNightCycle.state_at(config, GAP_HOURS[1]))
	assert_gt(gap["energy"], MAX_MINUTE_STEP_ENERGY, "Sensibilidade: meia hora de luz é bem mais que um minuto, então a medida enxerga um degrau.")
	assert_gt(gap["color"], MAX_MINUTE_STEP_COLOR)
	assert_gt(gap["yaw"], MAX_MINUTE_STEP_YAW)


func test_the_rig_applies_the_bloom_of_the_state_to_the_environment() -> void:
	var config: AmbientConfig = _config().duplicate() as AmbientConfig
	var rig: AmbientRig = AmbientRig.new()
	rig.config = config
	var world_environment: WorldEnvironment = WorldEnvironment.new()
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	for node: Node in [rig, world_environment, sun]:
		autofree(node)
	assert_true(rig.apply_to(world_environment, sun))
	var environment: Environment = world_environment.environment
	assert_true(environment.glow_enabled, "O bloom nasce ligado no recurso do jogo.")
	assert_almost_eq(environment.glow_intensity, 0.4, EXACT_TOLERANCE)
	assert_almost_eq(environment.glow_hdr_threshold, 1.1, EXACT_TOLERANCE)
	assert_almost_eq(environment.glow_bloom, 0.03, EXACT_TOLERANCE)
	assert_true(rig.apply_state_to(world_environment, sun, DayNightCycle.state_at(config, DUSK_HOURS[1])))
	assert_almost_eq(environment.glow_intensity, 1.0, PRESET_TOLERANCE, "No crepúsculo o bloom é o da cena: 1,0, limiar 0,7, bloom 0,2.")
	assert_almost_eq(environment.glow_hdr_threshold, 0.7, PRESET_TOLERANCE)
	assert_almost_eq(environment.glow_bloom, 0.2, PRESET_TOLERANCE)
	assert_almost_eq(environment.fog_density, 0.00128, EXACT_TOLERANCE, "A névoa do crepúsculo também vai ao Environment.")
	config.glow_enabled = false
	assert_true(rig.apply_to(world_environment, sun))
	assert_false(environment.glow_enabled, "Bloom desligado no recurso: desligado no Environment.")


func test_the_rig_applies_the_sun_yaw_and_pitch_of_the_state_outside_the_day() -> void:
	var config: AmbientConfig = _config().duplicate() as AmbientConfig
	var rig: AmbientRig = AmbientRig.new()
	rig.config = config
	var world_environment: WorldEnvironment = WorldEnvironment.new()
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	for node: Node in [rig, world_environment, sun]:
		autofree(node)
	var day_yaw: float = DayNightCycle.state_at(config, NOON).sun_yaw_degrees
	for hour: float in [GOLDEN_HOURS[0], DUSK_HOURS[1], NOON]:
		var state: DayNightCycle.LightState = DayNightCycle.state_at(config, hour)
		assert_true(rig.apply_state_to(world_environment, sun, state))
		assert_almost_eq(sun.rotation_degrees.y, state.sun_yaw_degrees, ELEVATION_TOLERANCE, "O giro do sol do estado (%s h) vai ao nó." % hour)
		assert_almost_eq(sun.rotation_degrees.x, -state.elevation_degrees, ELEVATION_TOLERANCE, "A elevação do estado (%s h) vai ao nó." % hour)
	assert_gt(absf(DayNightCycle.state_at(config, GOLDEN_HOURS[0]).sun_yaw_degrees - day_yaw), 100.0, "Sensibilidade: o giro da dourada é bem diferente do giro do dia, então ler o giro do recurso em vez do estado seria pego.")


func test_the_resource_loads_validates_and_flags_bad_atmosphere_fields() -> void:
	var config: AmbientConfig = _config()
	assert_not_null(config, "O .tres tem de carregar como AmbientConfig.")
	assert_eq(config.validate(), [] as Array[String], "Campos fora de faixa.")
	var bad: AmbientConfig = config.duplicate() as AmbientConfig
	bad.golden_glow_bloom = CHANGED_BLOOM
	bad.dusk_fog_density = NAN
	bad.golden_hour_degrees = bad.daylight_to_degrees
	var problems: String = "\n".join(bad.validate())
	assert_string_contains(problems, "golden_glow_bloom")
	assert_string_contains(problems, "dusk_fog_density")
	assert_string_contains(problems, "golden_hour_degrees")
