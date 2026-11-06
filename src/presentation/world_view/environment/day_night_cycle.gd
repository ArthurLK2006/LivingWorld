class_name DayNightCycle
extends RefCounted
## Curva do dia e da noite (LW-042; DEC-059 é PROPOSTA e todos os números são [HIP]): funções PURAS da hora, sem estado
## e sem nó, para a luz ser função da hora simulada. Quem lê a hora (pela ponte) e aplica é o AmbientRig.

const HOURS_PER_DAY: float = 24.0
const MINUTES_PER_HOUR: float = 60.0
## 06:00 e 18:00: sol no horizonte. A elevação é a senoide de período de 24 h que passa por zero às 06:00.
const SUNRISE_HOUR: float = 6.0


## Hora fracionária: 06:30 vale 6,5.
static func fractional_hour(hour_of_day: int, minute_of_hour: int) -> float:
	return float(hour_of_day) + float(minute_of_hour) / MINUTES_PER_HOUR


## e = máximo x sin(TAU x (h - 6) / 24): 06:00 = 0, 12:00 = máximo, 18:00 = 0, 00:00 = -máximo.
static func sun_elevation_degrees(hour: float, max_elevation_degrees: float) -> float:
	return max_elevation_degrees * sin(TAU * (hour - SUNRISE_HOUR) / HOURS_PER_DAY)


## 0 com o sol bem abaixo do horizonte, 1 bem acima: o mesmo fator move a energia do sol e as cores.
static func daylight_factor(elevation_degrees: float, from_degrees: float, to_degrees: float) -> float:
	return smoothstep(from_degrees, to_degrees, elevation_degrees)


## Luz da hora `hour`: energia do sol e mistura contínua das cores da noite para as do dia.
static func state_at(config: AmbientConfig, hour: float) -> LightState:
	var elevation: float = sun_elevation_degrees(hour, config.sun_max_elevation_degrees)
	return _blend(config, elevation, daylight_factor(elevation, config.daylight_from_degrees, config.daylight_to_degrees))


## Luz do dia pleno com a inclinação FIXA do recurso (sem hora simulada): exatamente os valores do dia.
static func day_state(config: AmbientConfig) -> LightState:
	return _blend(config, config.sun_elevation_degrees, 1.0)


static func _blend(config: AmbientConfig, elevation: float, daylight: float) -> LightState:
	var state: LightState = LightState.new()
	state.elevation_degrees = elevation
	state.daylight = daylight
	state.sun_energy = config.sun_energy * daylight
	state.sky_top_color = config.night_sky_top_color.lerp(config.sky_top_color, daylight)
	state.sky_horizon_color = config.night_sky_horizon_color.lerp(config.sky_horizon_color, daylight)
	state.ground_horizon_color = config.night_ground_horizon_color.lerp(config.ground_horizon_color, daylight)
	state.ground_bottom_color = config.night_ground_bottom_color.lerp(config.ground_bottom_color, daylight)
	state.ambient_color = config.night_ambient_color.lerp(config.ambient_color, daylight)
	state.ambient_energy = lerpf(config.night_ambient_energy, config.ambient_energy, daylight)
	state.fog_color = config.night_fog_color.lerp(config.fog_color, daylight)
	return state


## Os valores de luz que dependem da hora. O resto (cor do sol, giro, sombras, densidade da névoa) vem do recurso.
class LightState:
	extends RefCounted

	var elevation_degrees: float = 0.0
	var daylight: float = 0.0
	var sun_energy: float = 0.0
	var sky_top_color: Color = Color.BLACK
	var sky_horizon_color: Color = Color.BLACK
	var ground_horizon_color: Color = Color.BLACK
	var ground_bottom_color: Color = Color.BLACK
	var ambient_color: Color = Color.BLACK
	var ambient_energy: float = 0.0
	var fog_color: Color = Color.BLACK
