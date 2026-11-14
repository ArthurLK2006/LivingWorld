extends GutTest
## ART-4: a atmosfera aprovada da cena demonstrativa (RendererPresets.PRESETS: dia, hora dourada e crepúsculo) no ciclo de dia e noite do jogo. A cena é a fonte da verdade: o estado do jogo é comparado
## com as predefinições dela, dentro de PRESET_TOLERANCE; a noite, com os números ESCRITOS À MÃO da LW-042. Sem janela.
## ART-4b (tonemap e ajuste de cor por paleta): os esperados vêm do recurso ou de números de PROVA distintos em cada paleta, nunca da cena, para a calibração dos valores do .tres (olhando o jogo real) não quebrar estes testes.
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
const GRADE_FIELDS: Array[String] = ["exposure", "brightness", "contrast", "saturation"]
## Prefixo dos campos de cada paleta no AmbientConfig, na ordem de DAY, GOLDEN e DUSK.
const PALETTE_PREFIXES: Array[String] = ["", "golden_", "dusk_"]
## Números de prova, todos distintos (cada campo muda de uma paleta para outra e nenhum se repete): ler o campo ou a paleta errados é pego. Estão nas faixas do recurso.
const PROBE_GRADES: Dictionary[String, float] = {
	"exposure": 0.8, "brightness": 0.9, "contrast": 1.3, "saturation": 0.7,
	"golden_exposure": 1.2, "golden_brightness": 1.4, "golden_contrast": 0.6, "golden_saturation": 1.5,
	"dusk_exposure": 1.6, "dusk_brightness": 0.5, "dusk_contrast": 1.7, "dusk_saturation": 1.1,
}
## Maior mudança aceita entre dois minutos vizinhos em cada número. Pior caso medido nas curvas de prova: exposição 0,026; brilho 0,058; contraste 0,071; saturação 0,026 (no recurso do jogo, no máximo 0,0065).
## Um degrau entre paletas é bem maior: em meia hora (GAP_HOURS) a prova muda de 0,39 a 1,09.
const MAX_MINUTE_STEP_GRADE: Dictionary[String, float] = {"exposure": 0.04, "brightness": 0.08, "contrast": 0.1, "saturation": 0.04}
const PROBE_TONEMAP_WHITE: float = 9.5
const NEUTRAL: float = 1.0
const CHANGED_ADJUSTMENT: float = 1.2
const TOO_HIGH: float = 9.0
const TOO_LOW: float = -1.0
const INVALID_TONEMAP_MODE: int = 9


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


## O recurso do jogo com os 12 números de PROVA no lugar dos dele.
func _probe_config() -> AmbientConfig:
	var config: AmbientConfig = _config().duplicate() as AmbientConfig
	for field: String in PROBE_GRADES:
		config.set(field, PROBE_GRADES[field])
	return config


func _grade_of(state: DayNightCycle.LightState) -> Array[float]:
	var grade: Array[float] = [state.exposure, state.brightness, state.contrast, state.saturation]
	return grade


## Os números de prova de uma paleta (DAY, GOLDEN ou DUSK), na ordem de GRADE_FIELDS.
func _probe_grade(palette: int) -> Array[float]:
	var grade: Array[float] = []
	for field: String in GRADE_FIELDS:
		grade.append(PROBE_GRADES[PALETTE_PREFIXES[palette] + field])
	return grade


func _assert_probe_grade(state: DayNightCycle.LightState, palette: int, label: String) -> void:
	var actual: Array[float] = _grade_of(state)
	var expected: Array[float] = _probe_grade(palette)
	for field: int in range(GRADE_FIELDS.size()):
		assert_almost_eq(actual[field], expected[field], PRESET_TOLERANCE, "%s: %s" % [label, GRADE_FIELDS[field]])


## Maior mudança de cada número entre dois minutos vizinhos ao longo de 24 horas.
func _worst_grade_steps(config: AmbientConfig) -> Array[float]:
	var worst: Array[float] = [0.0, 0.0, 0.0, 0.0]
	var previous: Array[float] = _grade_of(DayNightCycle.state_at(config, 0.0))
	for minute: int in range(1, MINUTES_PER_DAY + 1):
		var current: Array[float] = _grade_of(DayNightCycle.state_at(config, float(minute) / DayNightCycle.MINUTES_PER_HOUR))
		for field: int in range(GRADE_FIELDS.size()):
			worst[field] = maxf(worst[field], absf(current[field] - previous[field]))
		previous = current
	return worst


## Aplica a luz de `hour` com `config` a um Environment que já tinha o ajuste de cor `adjustment_before` (ligado ou não); o rig e os nós são liberados no fim do teste.
func _environment_at(config: AmbientConfig, hour: float, adjustment_before: bool = false) -> Environment:
	var rig: AmbientRig = AmbientRig.new()
	rig.config = config
	var world_environment: WorldEnvironment = WorldEnvironment.new()
	world_environment.environment = Environment.new()
	world_environment.environment.adjustment_enabled = adjustment_before
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	for node: Node in [rig, world_environment, sun]:
		autofree(node)
	assert_true(rig.apply_state_to(world_environment, sun, DayNightCycle.state_at(config, hour)))
	return world_environment.environment


func test_each_anchor_has_the_exposure_and_color_adjustment_of_its_own_palette_and_the_night_the_dusk_ones() -> void:
	var config: AmbientConfig = _probe_config()
	_assert_probe_grade(DayNightCycle.state_at(config, NOON), DAY, "meio-dia")
	for hour: float in GOLDEN_HOURS:
		_assert_probe_grade(DayNightCycle.state_at(config, hour), GOLDEN, "hora dourada às %s h" % str(hour))
	for hour: float in DUSK_HOURS:
		_assert_probe_grade(DayNightCycle.state_at(config, hour), DUSK, "crepúsculo às %s h" % str(hour))
	for hour: float in NIGHT_HOURS:
		_assert_probe_grade(DayNightCycle.state_at(config, hour), DUSK, "noite (herda o crepúsculo) às %s h" % str(hour))


func test_the_exposure_and_color_adjustments_have_no_jump_between_neighbouring_minutes_over_24_hours() -> void:
	var probe: AmbientConfig = _probe_config()
	var game_worst: Array[float] = _worst_grade_steps(_config())
	var probe_worst: Array[float] = _worst_grade_steps(probe)
	var gap_start: Array[float] = _grade_of(DayNightCycle.state_at(probe, GAP_HOURS[0]))
	var gap_end: Array[float] = _grade_of(DayNightCycle.state_at(probe, GAP_HOURS[1]))
	for field: int in range(GRADE_FIELDS.size()):
		var limit: float = MAX_MINUTE_STEP_GRADE[GRADE_FIELDS[field]]
		assert_lt(game_worst[field], limit, "%s do recurso do jogo." % GRADE_FIELDS[field])
		assert_lt(probe_worst[field], limit, "%s da prova." % GRADE_FIELDS[field])
		assert_gt(absf(gap_start[field] - gap_end[field]), limit, "Sensibilidade: meia hora de luz muda %s bem mais que um minuto, então a medida enxerga um degrau." % GRADE_FIELDS[field])


func test_the_rig_applies_the_tonemap_of_the_resource_and_the_exposure_and_adjustments_of_the_state() -> void:
	var config: AmbientConfig = _probe_config()
	config.tonemap_mode = Environment.TONE_MAPPER_ACES
	config.tonemap_white = PROBE_TONEMAP_WHITE
	var golden: Environment = _environment_at(config, GOLDEN_HOURS[0])
	assert_eq(golden.tonemap_mode, Environment.TONE_MAPPER_ACES, "O modo vem do recurso, não de uma paleta.")
	assert_almost_eq(golden.tonemap_white, PROBE_TONEMAP_WHITE, EXACT_TOLERANCE)
	var expected: Array[float] = _probe_grade(GOLDEN)
	assert_almost_eq(golden.tonemap_exposure, expected[0], PRESET_TOLERANCE, "Exposição da hora dourada.")
	assert_almost_eq(golden.adjustment_brightness, expected[1], PRESET_TOLERANCE, "Brilho da hora dourada.")
	assert_almost_eq(golden.adjustment_contrast, expected[2], PRESET_TOLERANCE, "Contraste da hora dourada.")
	assert_almost_eq(golden.adjustment_saturation, expected[3], PRESET_TOLERANCE, "Saturação da hora dourada.")
	assert_true(golden.adjustment_enabled, "Números fora do neutro ligam o ajuste de cor.")


func test_the_game_resource_has_one_filmic_tonemap_for_the_whole_cycle_and_the_color_adjustment_on() -> void:
	var config: AmbientConfig = _config()
	for hour: float in [NOON, GOLDEN_HOURS[0], DUSK_HOURS[1], NIGHT_HOURS[0]]:
		var environment: Environment = _environment_at(config, hour)
		assert_eq(environment.tonemap_mode, Environment.TONE_MAPPER_FILMIC, "Um só modo (a hora dourada da cena usa ACES), FILMIC, às %s h." % str(hour))
		assert_almost_eq(environment.tonemap_white, config.tonemap_white, EXACT_TOLERANCE, "Branco do tonemap às %s h." % str(hour))
		assert_true(environment.adjustment_enabled, "O recurso do jogo traz o ajuste de cor da cena, às %s h." % str(hour))


func test_the_color_adjustment_is_enabled_only_when_brightness_contrast_or_saturation_leave_the_neutral() -> void:
	var config: AmbientConfig = _probe_config()
	assert_true(_environment_at(config, NOON).adjustment_enabled, "Números fora do neutro ligam o ajuste.")
	for field: String in PROBE_GRADES:
		config.set(field, NEUTRAL)
	var neutral: Environment = _environment_at(config, NOON, true)
	assert_false(neutral.adjustment_enabled, "Os três neutros desligam o ajuste, mesmo ligado antes.")
	assert_almost_eq(neutral.tonemap_exposure, NEUTRAL, EXACT_TOLERANCE)
	for field: String in ["brightness", "contrast", "saturation"]:
		config.set(field, CHANGED_ADJUSTMENT)
		assert_true(_environment_at(config, NOON).adjustment_enabled, "Só %s fora do neutro já liga o ajuste." % field)
		config.set(field, NEUTRAL)
	config.exposure = CHANGED_ADJUSTMENT
	var exposed: Environment = _environment_at(config, NOON)
	assert_almost_eq(exposed.tonemap_exposure, CHANGED_ADJUSTMENT, EXACT_TOLERANCE)
	assert_false(exposed.adjustment_enabled, "A exposição é do tonemap, não do ajuste: sozinha, não liga o ajuste.")


func test_a_new_resource_is_neutral_in_the_color_adjustments_and_the_out_of_range_fields_are_flagged() -> void:
	var fresh: AmbientConfig = AmbientConfig.new()
	assert_eq(fresh.validate(), [] as Array[String], "Um recurso novo é válido.")
	for prefix: String in PALETTE_PREFIXES:
		for field: String in GRADE_FIELDS:
			assert_eq(fresh.get(prefix + field), NEUTRAL, "Padrão neutro de %s%s." % [prefix, field])
	var bad: AmbientConfig = _config().duplicate() as AmbientConfig
	bad.tonemap_white = TOO_LOW
	bad.exposure = TOO_HIGH
	bad.golden_contrast = NAN
	bad.dusk_saturation = TOO_LOW
	bad.set("tonemap_mode", INVALID_TONEMAP_MODE)
	var problems: Array[String] = bad.validate()
	assert_eq(problems.size(), 5, "Só os cinco campos errados são apontados.")
	for field: String in ["tonemap_white", "exposure", "golden_contrast", "dusk_saturation", "tonemap_mode"]:
		assert_string_contains("\n".join(problems), field)
