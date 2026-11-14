extends GutTest
## LW-042: ciclo de dia e noite. Os valores esperados estão ESCRITOS À MÃO (não recalculam a fórmula do código):
## elevação = 60 x sin(TAU x (h - 6) / 24); luz do dia = smoothstep(-2, 3, elevação); energia do sol = a da paleta (crepúsculo, hora dourada ou dia) x a luz do dia.
## ART-4 mudou de propósito a luz do dia (era smoothstep(-2, 12, elevação): o crepúsculo da cena demonstrativa vale a 3 graus) e a energia do horizonte (era a do dia, agora a do crepúsculo).
const DEFAULT_CONFIG_PATH: String = "res://assets/environment/ambient_default.tres"
const ELEVATION_TOLERANCE: float = 0.01
const ENERGY_TOLERANCE: float = 0.0005
const COLOR_TOLERANCE: float = 0.00001
## Elevação máxima da tabela [HIP] e as horas que a conferem.
const MAX_ELEVATION: float = 60.0
const MINUTE_STEP_HOURS: float = 0.25
## smoothstep(-2, 3, 0) = 0,352 (t = 2/5); energia às 06:00 = crepúsculo (0,5) x 0,352 = 0,176.
const SMOOTHSTEP_AT_HORIZON: float = 0.352
## O sol passa pelos 9 graus da hora dourada às 06:34 e às 17:25 (escrito à mão). A energia da dourada (1,7) é maior que a do dia (1,15), de propósito: de manhã sobe até a dourada e desce até a do dia; à tarde sobe do dia
## até a dourada e desce até o horizonte. Nas amostras de 15 em 15 minutos, 06:45 e 17:15 são as últimas que ainda sobem em relação à anterior.
const MORNING_LAST_RISING_SAMPLE_HOUR: float = 6.75
const EVENING_LAST_RISING_SAMPLE_HOUR: float = 17.25
const MINUTES_TO_SIX: int = 360
const PAUSED_REAL_SECONDS: float = 10.0
## A noite é azul-escura e legível: o horizonte do céu não é preto nem claro.
const NIGHT_HORIZON_LUMINANCE_MIN: float = 0.02
const NIGHT_HORIZON_LUMINANCE_MAX: float = 0.3

var _host: SimulationHostNode


func before_each() -> void:
	_host = SimulationHostNode.new()
	_host.start_new_game(3)


func after_each() -> void:
	_host.runner.finish()
	_host.free()


func _config() -> AmbientConfig:
	return load(DEFAULT_CONFIG_PATH) as AmbientConfig


func _state(hour: float) -> DayNightCycle.LightState:
	return DayNightCycle.state_at(_config(), hour)


## Pai com Environment, Sol e AmbientRig (irmãos, como na cena); a ponte vem do host de teste.
func _scene(bridge: SimBridge) -> Array[Node]:
	var parent: Node = Node.new()
	var world_environment: WorldEnvironment = WorldEnvironment.new()
	world_environment.name = "Environment"
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.name = "Sun"
	var rig: AmbientRig = AmbientRig.new()
	rig.name = "AmbientRig"
	rig.config = _config()
	rig.setup(bridge)
	parent.add_child(world_environment)
	parent.add_child(sun)
	parent.add_child(rig)
	add_child_autofree(parent)
	rig.set_process(false)
	var nodes: Array[Node] = [rig, sun, world_environment]
	return nodes


func test_elevation_follows_the_table_at_the_key_hours() -> void:
	assert_almost_eq(DayNightCycle.sun_elevation_degrees(6.0, MAX_ELEVATION), 0.0, ELEVATION_TOLERANCE, "06:00: horizonte.")
	assert_almost_eq(DayNightCycle.sun_elevation_degrees(12.0, MAX_ELEVATION), 60.0, ELEVATION_TOLERANCE, "12:00: 60 graus.")
	assert_almost_eq(DayNightCycle.sun_elevation_degrees(18.0, MAX_ELEVATION), 0.0, ELEVATION_TOLERANCE, "18:00: horizonte.")
	assert_almost_eq(DayNightCycle.sun_elevation_degrees(0.0, MAX_ELEVATION), -60.0, ELEVATION_TOLERANCE, "00:00: -60 graus.")
	assert_almost_eq(DayNightCycle.sun_elevation_degrees(9.0, MAX_ELEVATION), 42.43, ELEVATION_TOLERANCE, "09:00: 60 x sin(45 graus).")
	assert_almost_eq(DayNightCycle.sun_elevation_degrees(12.0, 30.0), 30.0, ELEVATION_TOLERANCE, "Sensibilidade: o máximo vem do parâmetro.")
	assert_almost_eq(DayNightCycle.fractional_hour(6, 30), 6.5, ELEVATION_TOLERANCE)
	assert_almost_eq(DayNightCycle.fractional_hour(23, 59), 23.98333, ELEVATION_TOLERANCE)


## ART-4: o máximo do dia agora é a hora dourada (o nome do teste ficou); ao meio-dia vale a energia do dia e às 06:00 a do crepúsculo.
func test_sun_energy_is_zero_at_midnight_maximum_at_noon_and_small_at_sunrise() -> void:
	var config: AmbientConfig = _config()
	assert_eq(_state(0.0).sun_energy, 0.0, "À meia-noite o sol não ilumina.")
	assert_eq(_state(12.0).sun_energy, config.sun_energy, "Ao meio-dia a energia é a do dia.")
	assert_almost_eq(_state(6.0).sun_energy, config.dusk_sun_energy * SMOOTHSTEP_AT_HORIZON, ENERGY_TOLERANCE, "06:00: 0,5 x 0,352.")
	assert_almost_eq(_state(6.0).daylight, SMOOTHSTEP_AT_HORIZON, COLOR_TOLERANCE)
	assert_almost_eq(_state(18.0).sun_energy, _state(6.0).sun_energy, COLOR_TOLERANCE, "A curva é simétrica em torno do meio-dia.")


func test_the_light_rises_from_six_to_noon_and_falls_from_noon_to_six_pm() -> void:
	var hour: float = 6.0
	var previous: DayNightCycle.LightState = _state(hour)
	while hour < 12.0:
		hour += MINUTE_STEP_HOURS
		var current: DayNightCycle.LightState = _state(hour)
		assert_gt(current.elevation_degrees, previous.elevation_degrees, "Subida estrita da elevação às %s h." % str(hour))
		if hour <= MORNING_LAST_RISING_SAMPLE_HOUR:
			assert_gte(current.sun_energy, previous.sun_energy, "A energia não cai na subida até a hora dourada, às %s h." % str(hour))
		else:
			assert_lte(current.sun_energy, previous.sun_energy, "Depois da hora dourada a energia só desce até a do dia, às %s h." % str(hour))
		previous = current
	while hour < 18.0:
		hour += MINUTE_STEP_HOURS
		var current: DayNightCycle.LightState = _state(hour)
		assert_lt(current.elevation_degrees, previous.elevation_degrees, "Descida estrita da elevação às %s h." % str(hour))
		if hour <= EVENING_LAST_RISING_SAMPLE_HOUR:
			assert_gte(current.sun_energy, previous.sun_energy, "Do dia até a hora dourada a energia não cai, às %s h." % str(hour))
		else:
			assert_lte(current.sun_energy, previous.sun_energy, "Depois da hora dourada a energia não sobe na descida às %s h." % str(hour))
		previous = current


func test_there_is_no_jump_between_23_59_and_midnight() -> void:
	var before: DayNightCycle.LightState = _state(DayNightCycle.fractional_hour(23, 59))
	var after: DayNightCycle.LightState = _state(DayNightCycle.fractional_hour(0, 0))
	assert_lt(absf(before.elevation_degrees - after.elevation_degrees), 0.3, "Um minuto move o sol menos de 0,3 grau (máximo 0,26).")
	assert_eq(before.sun_energy, after.sun_energy)
	assert_true(before.sky_top_color.is_equal_approx(after.sky_top_color))
	assert_true(before.ambient_color.is_equal_approx(after.ambient_color))
	assert_true(before.fog_color.is_equal_approx(after.fog_color))


func test_night_is_dark_blue_and_readable_not_black_and_day_colors_return_at_noon() -> void:
	var config: AmbientConfig = _config()
	var night: DayNightCycle.LightState = _state(0.0)
	assert_true(night.sky_horizon_color.is_equal_approx(config.night_sky_horizon_color), "À meia-noite valem as cores da noite.")
	assert_gt(night.sky_horizon_color.get_luminance(), NIGHT_HORIZON_LUMINANCE_MIN, "A noite não é preta.")
	assert_lt(night.sky_horizon_color.get_luminance(), NIGHT_HORIZON_LUMINANCE_MAX, "A noite é escura.")
	assert_gt(night.sky_horizon_color.b, night.sky_horizon_color.r, "A noite é azulada.")
	assert_gt(night.ambient_energy, 0.0, "Há um ambiente mínimo à noite.")
	var noon: DayNightCycle.LightState = _state(12.0)
	assert_true(noon.sky_top_color.is_equal_approx(config.sky_top_color))
	assert_true(noon.ambient_color.is_equal_approx(config.ambient_color))
	assert_almost_eq(noon.ambient_energy, config.ambient_energy, ENERGY_TOLERANCE)
	var dawn: DayNightCycle.LightState = _state(6.0)
	assert_gt(dawn.sky_top_color.b, minf(night.sky_top_color.b, noon.sky_top_color.b), "No amanhecer a cor está entre a da noite e a do dia.")
	assert_lt(dawn.sky_top_color.b, maxf(night.sky_top_color.b, noon.sky_top_color.b))


func test_advancing_360_simulated_minutes_brings_the_light_to_the_table_value() -> void:
	var nodes: Array[Node] = _scene(SimBridge.new(_host, null))
	var rig: AmbientRig = nodes[0] as AmbientRig
	var sun: DirectionalLight3D = nodes[1] as DirectionalLight3D
	var environment: Environment = (nodes[2] as WorldEnvironment).environment
	assert_eq(sun.light_energy, 0.0, "00:00: noite.")
	_host.runner.run_steps(MINUTES_TO_SIX)
	assert_true(rig.refresh())
	assert_almost_eq(sun.rotation_degrees.x, 0.0, ELEVATION_TOLERANCE, "06:00: sol no horizonte (rotação x = 0).")
	assert_almost_eq(sun.light_energy, _config().dusk_sun_energy * SMOOTHSTEP_AT_HORIZON, ENERGY_TOLERANCE)
	_host.runner.run_steps(MINUTES_TO_SIX)
	assert_true(rig.refresh())
	assert_almost_eq(sun.rotation_degrees.x, -60.0, ELEVATION_TOLERANCE, "12:00: rotação x = -60.")
	assert_almost_eq(sun.light_energy, _config().sun_energy, ENERGY_TOLERANCE)
	assert_true(environment.ambient_light_color.is_equal_approx(_config().ambient_color))


func test_a_paused_clock_freezes_the_light_and_resuming_moves_it_again() -> void:
	var nodes: Array[Node] = _scene(SimBridge.new(_host, null))
	var rig: AmbientRig = nodes[0] as AmbientRig
	var sun: DirectionalLight3D = nodes[1] as DirectionalLight3D
	_host.runner.run_steps(MINUTES_TO_SIX + 20)
	rig.refresh()
	var frozen_rotation: Vector3 = sun.rotation_degrees
	var frozen_energy: float = sun.light_energy
	assert_true(_host.request_pause(true).ok)
	assert_eq(_host.advance(PAUSED_REAL_SECONDS), 0, "Pausado, o host não avança.")
	for frame: int in range(5):
		rig.refresh()
	assert_eq(sun.rotation_degrees, frozen_rotation, "Pausado, a luz não muda.")
	assert_eq(sun.light_energy, frozen_energy)
	assert_true(_host.request_pause(false).ok)
	assert_gt(_host.advance(PAUSED_REAL_SECONDS), 0)
	rig.refresh()
	assert_ne(sun.rotation_degrees, frozen_rotation, "Sensibilidade: andando o relógio, a luz muda.")


func test_a_failing_peek_time_does_not_crash_reports_once_and_keeps_the_light() -> void:
	var nodes: Array[Node] = _scene(SimBridge.new(null, null))
	var rig: AmbientRig = nodes[0] as AmbientRig
	var sun: DirectionalLight3D = nodes[1] as DirectionalLight3D
	var energy_before: float = sun.light_energy
	for attempt: int in range(3):
		assert_false(rig.refresh())
	assert_push_error_count(1, "O erro da hora indisponível aparece uma vez só.")
	assert_eq(sun.light_energy, energy_before, "A luz fica como está.")
