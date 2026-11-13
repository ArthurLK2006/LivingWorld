class_name DayNightCycle
extends RefCounted
## Curva do dia e da noite (LW-042; DEC-059 é PROPOSTA e todos os números são [HIP]): funções PURAS da hora, sem estado
## e sem nó, para a luz ser função da hora simulada. Quem lê a hora (pela ponte) e aplica é o AmbientRig.
## ART-4: pela elevação do sol, a luz mistura quatro paletas do AmbientConfig: noite -> crepúsculo -> hora dourada -> dia (e o contrário de manhã).

const HOURS_PER_DAY: float = 24.0
const MINUTES_PER_HOUR: float = 60.0
## 06:00 e 18:00: sol no horizonte. A elevação é a senoide de período de 24 h que passa por zero às 06:00.
const SUNRISE_HOUR: float = 6.0
## A fração do minuto fica abaixo de 1: a hora oficial (ponte) assume na virada, então a hora nunca passa do minuto seguinte.
const MAX_MINUTE_FRACTION: float = 0.999999


## Hora fracionária: 06:30 vale 6,5. `minute_fraction` é quanto do minuto já passou (limitada a [0, 1)): 06:30 e meio minuto vale 6,508333.
static func fractional_hour(hour_of_day: int, minute_of_hour: int, minute_fraction: float = 0.0) -> float:
	return float(hour_of_day) + (float(minute_of_hour) + clampf(minute_fraction, 0.0, MAX_MINUTE_FRACTION)) / MINUTES_PER_HOUR


## e = máximo x sin(TAU x (h - 6) / 24): 06:00 = 0, 12:00 = máximo, 18:00 = 0, 00:00 = -máximo.
static func sun_elevation_degrees(hour: float, max_elevation_degrees: float) -> float:
	return max_elevation_degrees * sin(TAU * (hour - SUNRISE_HOUR) / HOURS_PER_DAY)


## 0 com o sol abaixo de `from` e 1 acima de `to`: tira a NOITE da mistura (energia do sol e cores).
static func daylight_factor(elevation_degrees: float, from_degrees: float, to_degrees: float) -> float:
	return smoothstep(from_degrees, to_degrees, elevation_degrees)


## Quanto vale cada paleta com o sol a `elevation_degrees` (a soma é 1): noite -> crepúsculo em [`daylight_from`, `daylight_to`], crepúsculo -> hora dourada em [`daylight_to`, `golden_hour`] e
## hora dourada -> dia em [`golden_hour`, `full_day`], cada trecho por smoothstep (contínuo, sem pontas). Em cada elevação-âncora a paleta vale 1 e as outras 0.
static func palette_weights(config: AmbientConfig, elevation_degrees: float) -> PaletteWeights:
	var daylight: float = daylight_factor(elevation_degrees, config.daylight_from_degrees, config.daylight_to_degrees)
	var past_dusk: float = smoothstep(config.daylight_to_degrees, config.golden_hour_degrees, elevation_degrees)
	var past_golden: float = smoothstep(config.golden_hour_degrees, config.full_day_degrees, elevation_degrees)
	var weights: PaletteWeights = PaletteWeights.new()
	weights.night = 1.0 - daylight
	weights.dusk = daylight * (1.0 - past_dusk)
	weights.golden = daylight * past_dusk * (1.0 - past_golden)
	weights.day = daylight * past_dusk * past_golden
	return weights


## Luz da hora `hour`: a mistura contínua, pela elevação do sol, das paletas noite, crepúsculo, hora dourada e dia.
static func state_at(config: AmbientConfig, hour: float) -> LightState:
	var elevation: float = sun_elevation_degrees(hour, config.sun_max_elevation_degrees)
	return _blend(config, elevation, palette_weights(config, elevation))


## Luz do dia pleno com a inclinação FIXA do recurso (sem hora simulada): exatamente os valores do dia.
static func day_state(config: AmbientConfig) -> LightState:
	var weights: PaletteWeights = PaletteWeights.new()
	weights.day = 1.0
	return _blend(config, config.sun_elevation_degrees, weights)


## Cada campo soma as quatro paletas pelos pesos, na ordem noite, crepúsculo, hora dourada, dia. A noite só tem céu, ambiente e névoa próprios (`night_*`); como o sol dela está apagado (energia 0),
## ela herda do crepúsculo a cor e o giro do sol e o bloom (nada gira nem muda de cor enquanto a luz some) e do dia a densidade da névoa (a noite de antes). O chão do horizonte do crepúsculo e da hora dourada é o horizonte.
static func _blend(config: AmbientConfig, elevation: float, weights: PaletteWeights) -> LightState:
	var state: LightState = LightState.new()
	state.elevation_degrees = elevation
	state.daylight = 1.0 - weights.night
	state.sun_energy = _mix(weights, 0.0, config.dusk_sun_energy, config.golden_sun_energy, config.sun_energy)
	state.sun_color = _mix_color(weights, config.dusk_sun_color, config.dusk_sun_color, config.golden_sun_color, config.sun_color)
	state.sun_yaw_degrees = _mix(weights, config.dusk_sun_yaw_degrees, config.dusk_sun_yaw_degrees, config.golden_sun_yaw_degrees, config.sun_yaw_degrees)
	state.sky_top_color = _mix_color(weights, config.night_sky_top_color, config.dusk_sky_top_color, config.golden_sky_top_color, config.sky_top_color)
	state.sky_horizon_color = _mix_color(weights, config.night_sky_horizon_color, config.dusk_sky_horizon_color, config.golden_sky_horizon_color, config.sky_horizon_color)
	state.ground_horizon_color = _mix_color(weights, config.night_ground_horizon_color, config.dusk_sky_horizon_color, config.golden_sky_horizon_color, config.ground_horizon_color)
	state.ground_bottom_color = _mix_color(weights, config.night_ground_bottom_color, config.dusk_ground_bottom_color, config.golden_ground_bottom_color, config.ground_bottom_color)
	state.ambient_color = _mix_color(weights, config.night_ambient_color, config.dusk_ambient_color, config.golden_ambient_color, config.ambient_color)
	state.ambient_energy = _mix(weights, config.night_ambient_energy, config.dusk_ambient_energy, config.golden_ambient_energy, config.ambient_energy)
	state.fog_color = _mix_color(weights, config.night_fog_color, config.dusk_fog_color, config.golden_fog_color, config.fog_color)
	state.fog_density = _mix(weights, config.fog_density, config.dusk_fog_density, config.golden_fog_density, config.fog_density)
	state.glow_intensity = _mix(weights, config.dusk_glow_intensity, config.dusk_glow_intensity, config.golden_glow_intensity, config.glow_intensity)
	state.glow_hdr_threshold = _mix(weights, config.dusk_glow_hdr_threshold, config.dusk_glow_hdr_threshold, config.golden_glow_hdr_threshold, config.glow_hdr_threshold)
	state.glow_bloom = _mix(weights, config.dusk_glow_bloom, config.dusk_glow_bloom, config.golden_glow_bloom, config.glow_bloom)
	return state


## Soma ponderada: com os pesos de uma paleta em 1 e os outros em 0 o resultado é EXATAMENTE o valor dela.
static func _mix(weights: PaletteWeights, night: float, dusk: float, golden: float, day: float) -> float:
	return night * weights.night + dusk * weights.dusk + golden * weights.golden + day * weights.day


static func _mix_color(weights: PaletteWeights, night: Color, dusk: Color, golden: Color, day: Color) -> Color:
	return night * weights.night + dusk * weights.dusk + golden * weights.golden + day * weights.day


## Os valores de luz que dependem da hora (sol, céu, ambiente, névoa e bloom). O resto (sombras, névoa e bloom ligados) vem do recurso.
class LightState:
	extends RefCounted

	var elevation_degrees: float = 0.0
	var daylight: float = 0.0
	var sun_energy: float = 0.0
	var sun_color: Color = Color.BLACK
	var sun_yaw_degrees: float = 0.0
	var sky_top_color: Color = Color.BLACK
	var sky_horizon_color: Color = Color.BLACK
	var ground_horizon_color: Color = Color.BLACK
	var ground_bottom_color: Color = Color.BLACK
	var ambient_color: Color = Color.BLACK
	var ambient_energy: float = 0.0
	var fog_color: Color = Color.BLACK
	var fog_density: float = 0.0
	var glow_intensity: float = 0.0
	var glow_hdr_threshold: float = 0.0
	var glow_bloom: float = 0.0


## Quanto vale cada uma das quatro paletas numa elevação do sol (a soma é 1).
class PaletteWeights:
	extends RefCounted

	var night: float = 0.0
	var dusk: float = 0.0
	var golden: float = 0.0
	var day: float = 0.0
