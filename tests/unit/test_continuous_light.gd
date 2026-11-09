extends GutTest
## LW-042a: luz contínua entre os minutos. A curva (DayNightCycle.state_at) não mudou; muda a hora que ela recebe: a oficial
## mais a fração do minuto, que o AmbientRig conta pelos quadros. Valores esperados escritos à mão. Sem janela.
const DEFAULT_CONFIG_PATH: String = "res://assets/environment/ambient_default.tres"
## 25 ms por quadro: 50 quadros fecham 1 minuto a 1x (1,25 s), em milissegundos inteiros como no relógio.
const FRAME_SECONDS: float = 0.025
const FRAMES_PER_MINUTE: int = 50
const MINUTES_TO_SIX: int = 360
const MINUTES_TO_23_59: int = 1439
const CLOSE_HOURS: float = 0.0001
## Pior caso das curvas [HIP] para 0,0001 h: elevação 15,7 graus/h x 0,0001 = 0,0016; energia 0,7/h x 0,0001 = 0,00007.
const MAX_CLOSE_ELEVATION_STEP: float = 0.002
const MAX_CLOSE_ENERGY_STEP: float = 0.0001
const MAX_CLOSE_DAYLIGHT_STEP: float = 0.0003
## Um quadro (1/50 de minuto) deve mover a luz bem menos que 1/10 da mudança de um minuto inteiro.
const MAX_FRAME_SHARE_OF_A_MINUTE: float = 0.1
const FRACTION_TOLERANCE: float = 0.0001

var _host: SimulationHostNode


func before_each() -> void:
	_host = SimulationHostNode.new()
	_host.start_new_game(3)


func after_each() -> void:
	_host.runner.finish()
	_host.free()


func _config() -> AmbientConfig:
	return load(DEFAULT_CONFIG_PATH) as AmbientConfig


## Cena mínima (Environment, Sol e AmbientRig irmãos) parada em `minutes` simulados; quem anda o rig é o teste.
func _rig_at(minutes: int) -> AmbientRig:
	var parent: Node = Node.new()
	var world_environment: WorldEnvironment = WorldEnvironment.new()
	world_environment.name = "Environment"
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.name = "Sun"
	var rig: AmbientRig = AmbientRig.new()
	rig.config = _config()
	rig.setup(SimBridge.new(_host, null))
	parent.add_child(world_environment)
	parent.add_child(sun)
	parent.add_child(rig)
	add_child_autofree(parent)
	rig.set_process(false)
	_host.runner.run_steps(minutes)
	rig.refresh()
	return rig


func _sun(rig: AmbientRig) -> DirectionalLight3D:
	return rig.get_node("../Sun") as DirectionalLight3D


func _refresh_frames(rig: AmbientRig, frames: int) -> void:
	for frame: int in range(frames):
		rig.refresh(FRAME_SECONDS)


func test_two_very_close_hours_give_very_close_states_including_at_six() -> void:
	for hour: float in [0.0, 6.0, 12.0, 18.0, 23.9999]:
		var first: DayNightCycle.LightState = DayNightCycle.state_at(_config(), hour)
		var second: DayNightCycle.LightState = DayNightCycle.state_at(_config(), hour + CLOSE_HOURS)
		assert_lt(absf(first.elevation_degrees - second.elevation_degrees), MAX_CLOSE_ELEVATION_STEP, "Elevação às %s h." % str(hour))
		assert_lt(absf(first.sun_energy - second.sun_energy), MAX_CLOSE_ENERGY_STEP, "Energia às %s h." % str(hour))
		assert_lt(absf(first.daylight - second.daylight), MAX_CLOSE_DAYLIGHT_STEP, "Mistura de cores às %s h." % str(hour))
	var minute_step: float = DayNightCycle.state_at(_config(), 6.0 + 1.0 / 60.0).sun_energy - DayNightCycle.state_at(_config(), 6.0).sun_energy
	assert_gt(minute_step, 10.0 * MAX_CLOSE_ENERGY_STEP, "Sensibilidade: um minuto inteiro passa muito do limite, então o teste enxerga um degrau.")


## A constante da apresentação é uma cópia do ritmo do relógio: se um mudar sem o outro, a luz deixa de acompanhar o minuto.
func test_the_presentation_pace_matches_the_simulation_clock_pace() -> void:
	assert_eq(AmbientRig.REAL_SECONDS_PER_MINUTE_AT_1X, float(SimClock.DEFAULT_REAL_MS_PER_MINUTE) / 1000.0)


func test_the_minute_fraction_is_limited_to_zero_inclusive_and_one_exclusive() -> void:
	assert_almost_eq(DayNightCycle.fractional_hour(6, 30, 0.5), 6.508333, FRACTION_TOLERANCE, "06:30 e meio minuto.")
	assert_eq(DayNightCycle.fractional_hour(6, 30, -5.0), DayNightCycle.fractional_hour(6, 30), "Fração negativa vale 0.")
	assert_lt(DayNightCycle.fractional_hour(6, 30, 7.0), DayNightCycle.fractional_hour(6, 31), "Fração acima de 1 não passa do minuto seguinte.")
	var rig: AmbientRig = _rig_at(MINUTES_TO_SIX)
	assert_eq(rig.minute_fraction(), 0.0, "A fração nasce em 0 na virada do minuto.")
	rig.refresh(-1.0)
	assert_eq(rig.minute_fraction(), 0.0, "Quadro negativo não faz a fração voltar.")
	rig.refresh(FRAMES_PER_MINUTE * FRAME_SECONDS * 4.0)
	assert_lt(rig.minute_fraction(), 1.0, "Sem a hora oficial virar, a fração para antes de 1.")
	assert_gt(rig.minute_fraction(), 0.99)


func test_pausing_freezes_the_fraction_and_resuming_continues_without_a_jump() -> void:
	var rig: AmbientRig = _rig_at(MINUTES_TO_SIX)
	_refresh_frames(rig, 20)
	assert_almost_eq(rig.minute_fraction(), 0.4, FRACTION_TOLERANCE, "20 quadros x 0,025 s / 1,25 s = 0,4 do minuto.")
	var frozen_rotation: Vector3 = _sun(rig).rotation_degrees
	var frozen_energy: float = _sun(rig).light_energy
	assert_true(_host.request_pause(true).ok)
	_refresh_frames(rig, 30)
	assert_almost_eq(rig.minute_fraction(), 0.4, FRACTION_TOLERANCE, "Pausado, a fração congela.")
	assert_eq(_sun(rig).rotation_degrees, frozen_rotation)
	assert_eq(_sun(rig).light_energy, frozen_energy)
	assert_true(_host.request_pause(false).ok)
	rig.refresh(FRAME_SECONDS)
	assert_almost_eq(rig.minute_fraction(), 0.42, FRACTION_TOLERANCE, "Ao retomar, anda um quadro a partir de onde parou.")
	assert_gt(_sun(rig).light_energy, frozen_energy)


func test_changing_the_speed_does_not_jump_and_scales_the_rate() -> void:
	var rig: AmbientRig = _rig_at(MINUTES_TO_SIX)
	_refresh_frames(rig, 10)
	assert_almost_eq(rig.minute_fraction(), 0.2, FRACTION_TOLERANCE, "1x: 10 quadros = 0,2 do minuto.")
	var energy_before: float = _sun(rig).light_energy
	assert_true(_host.request_speed(4).ok)
	rig.refresh(0.0)
	assert_eq(_sun(rig).light_energy, energy_before, "Trocar a velocidade não move a luz.")
	_refresh_frames(rig, 5)
	assert_almost_eq(rig.minute_fraction(), 0.6, FRACTION_TOLERANCE, "4x: 5 quadros somam 0,4 (4 vezes mais rápido).")


func test_the_dawn_changes_a_little_in_every_frame_across_minute_turns() -> void:
	var rig: AmbientRig = _rig_at(MINUTES_TO_SIX - 1)
	var minute_step: float = DayNightCycle.state_at(_config(), 6.0).sun_energy - DayNightCycle.state_at(_config(), 359.0 / 60.0).sun_energy
	var previous: float = _sun(rig).light_energy
	for frame: int in range(3 * FRAMES_PER_MINUTE):
		_host.advance(FRAME_SECONDS)
		rig.refresh(FRAME_SECONDS)
		var current: float = _sun(rig).light_energy
		assert_gt(current, previous, "Quadro %d: a luz sobe a cada quadro, sem repetir valor (e sem recuar na virada do minuto)." % frame)
		assert_lt(current - previous, MAX_FRAME_SHARE_OF_A_MINUTE * minute_step, "Quadro %d: nenhum quadro move a luz um minuto inteiro." % frame)
		previous = current


func test_the_turn_of_the_day_has_no_jump() -> void:
	var before: DayNightCycle.LightState = DayNightCycle.state_at(_config(), DayNightCycle.fractional_hour(23, 59, 1.0))
	var after: DayNightCycle.LightState = DayNightCycle.state_at(_config(), DayNightCycle.fractional_hour(0, 0))
	assert_lt(absf(before.elevation_degrees - after.elevation_degrees), MAX_CLOSE_ELEVATION_STEP, "23:59 e todo o minuto chega em 00:00 sem salto.")
	assert_eq(before.sun_energy, after.sun_energy)
	var rig: AmbientRig = _rig_at(MINUTES_TO_23_59)
	var previous: Vector3 = _sun(rig).rotation_degrees
	for frame: int in range(2 * FRAMES_PER_MINUTE):
		_host.advance(FRAME_SECONDS)
		rig.refresh(FRAME_SECONDS)
		assert_lt(absf(_sun(rig).rotation_degrees.x - previous.x), MAX_CLOSE_ELEVATION_STEP, "Quadro %d: o sol não salta na virada do dia." % frame)
		previous = _sun(rig).rotation_degrees
	assert_eq(_host.runner.world.context.clock.hour_of_day(), 0, "O relógio virou o dia durante o teste.")
