extends GutTest
## ART-5a: o fator dos lampiões e das tochas da praça (`LightState.lamp_factor`) e o sinal `state_applied` da AmbientRig. Os esperados são as âncoras (horas escritas à mão, as de test_atmosphere) e valores calculados À MÃO com uma fração de PROVA,
## nunca o valor calibrado no .tres: a calibração (olhando o jogo real) não quebra estes testes. Sem janela.
const DEFAULT_CONFIG_PATH: String = "res://assets/environment/ambient_default.tres"
const NOON: float = 12.0
const ANCHOR_TOLERANCE: float = 0.002
const EXACT_TOLERANCE: float = 0.000001
## Horas com o sol a 9 graus (hora dourada) e a 3 graus (crepúsculo), [manhã, tarde], e da noite.
const GOLDEN_HOURS: Array[float] = [6.575, 17.425]
const DUSK_HOURS: Array[float] = [6.191, 17.809]
const NIGHT_HOURS: Array[float] = [0.0, 3.0, 5.0, 19.0, 23.9]
const PROBE_FRACTION: float = 0.7
## Sol a 30 graus (08:00 e 16:00): só a hora dourada e o dia se misturam, com o peso da dourada 1 - smoothstep(9, 45, 30) = 1 - 0,623842 = 0,376158; o fator é 0,7 x 0,376158.
const SUN_30_HOURS: Array[float] = [8.0, 16.0]
const SUN_30_PROBE_FACTOR: float = 0.26331
## Sol a 6 graus (06:22:57 e 17:37:03): o crepúsculo e a hora dourada pesam 0,5 cada (smoothstep(3, 9, 6) = 0,5); o fator é 0,5 + 0,7 x 0,5.
const SUN_6_HOURS: Array[float] = [6.382611, 17.617389]
const SUN_6_PROBE_FACTOR: float = 0.85
const MINUTES_PER_DAY: int = 1440
const NOON_MINUTE: int = 720
## Maior mudança aceita entre dois minutos vizinhos. Pior caso medido: 0,065 com a fração 0 (a descida mais íngreme: do crepúsculo ao dia pela dourada), 0,039 com a do recurso (0,4) e 0,0098 com a fração 1.
## Um degrau entre paletas é bem maior: de 06:12 a 06:42 o fator muda cerca de 0,6.
const MAX_MINUTE_STEP_LAMP: float = 0.08
const GAP_HOURS: Array[float] = [6.2, 6.7]
const TOO_HIGH: float = 9.0
const PAUSED_REAL_SECONDS: float = 10.0
const FRAME_SECONDS: float = 0.5

var _host: SimulationHostNode


func before_each() -> void:
	_host = SimulationHostNode.new()
	_host.start_new_game(3)


func after_each() -> void:
	_host.runner.finish()
	_host.free()


func _config() -> AmbientConfig:
	return load(DEFAULT_CONFIG_PATH) as AmbientConfig


func _probe(fraction: float) -> AmbientConfig:
	var config: AmbientConfig = _config().duplicate() as AmbientConfig
	config.lamp_golden_fraction = fraction
	return config


func _lamp(config: AmbientConfig, hour: float) -> float:
	return DayNightCycle.state_at(config, hour).lamp_factor


## Pai com Environment, Sol e AmbientRig (irmãos, como na cena), com a ponte do host de teste; o relógio de luz do rig fica desligado (o teste chama `refresh`).
func _rig_scene() -> AmbientRig:
	var parent: Node = Node.new()
	var world_environment: WorldEnvironment = WorldEnvironment.new()
	world_environment.name = "Environment"
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.name = "Sun"
	var rig: AmbientRig = AmbientRig.new()
	rig.name = "AmbientRig"
	rig.config = _config()
	rig.setup(SimBridge.new(_host, null))
	parent.add_child(world_environment)
	parent.add_child(sun)
	parent.add_child(rig)
	add_child_autofree(parent)
	rig.set_process(false)
	return rig


func test_the_lamp_factor_is_0_at_noon_1_at_dusk_and_at_night_and_the_golden_fraction_at_the_golden_hour() -> void:
	var config: AmbientConfig = _config()
	assert_almost_eq(_lamp(config, NOON), 0.0, EXACT_TOLERANCE, "Meio-dia: apagados.")
	assert_almost_eq(DayNightCycle.day_state(config).lamp_factor, 0.0, EXACT_TOLERANCE, "O dia de inclinação fixa também.")
	for hour: float in NIGHT_HOURS + DUSK_HOURS:
		assert_almost_eq(_lamp(config, hour), 1.0, ANCHOR_TOLERANCE, "Noite e crepúsculo (%s h): acesos." % str(hour))
	for fraction: float in [0.0, PROBE_FRACTION, 1.0]:
		for hour: float in GOLDEN_HOURS:
			assert_almost_eq(_lamp(_probe(fraction), hour), fraction, ANCHOR_TOLERANCE, "Hora dourada (%s h): a fração do recurso, %s." % [str(hour), str(fraction)])


func test_the_lamp_factor_is_between_the_anchors_with_the_values_worked_out_by_hand() -> void:
	var probe: AmbientConfig = _probe(PROBE_FRACTION)
	for hour: float in SUN_30_HOURS:
		assert_almost_eq(_lamp(probe, hour), SUN_30_PROBE_FACTOR, ANCHOR_TOLERANCE, "Entre a hora dourada e o dia (%s h): só uma parte da fração." % str(hour))
	for hour: float in SUN_6_HOURS:
		assert_almost_eq(_lamp(probe, hour), SUN_6_PROBE_FACTOR, ANCHOR_TOLERANCE, "Entre o crepúsculo e a hora dourada (%s h)." % str(hour))
	assert_almost_eq(_lamp(_probe(0.0), SUN_30_HOURS[0]), 0.0, ANCHOR_TOLERANCE, "Fração 0: a hora dourada não acende nada.")


func test_the_lamp_factor_has_no_jump_between_neighbouring_minutes_and_only_falls_in_the_morning_and_rises_in_the_afternoon() -> void:
	for fraction: float in [0.0, _config().lamp_golden_fraction, 1.0]:
		var config: AmbientConfig = _probe(fraction)
		var worst: float = 0.0
		var reversals: int = 0
		var previous: float = _lamp(config, 0.0)
		for minute: int in range(1, MINUTES_PER_DAY + 1):
			var current: float = _lamp(config, float(minute) / DayNightCycle.MINUTES_PER_HOUR)
			worst = maxf(worst, absf(current - previous))
			if (minute <= NOON_MINUTE and current > previous + EXACT_TOLERANCE) or (minute > NOON_MINUTE and current < previous - EXACT_TOLERANCE):
				reversals += 1
			previous = current
		assert_lt(worst, MAX_MINUTE_STEP_LAMP, "Maior degrau entre dois minutos com a fração %s." % str(fraction))
		assert_eq(reversals, 0, "O fator só cai de manhã e só sobe à tarde (fração %s)." % str(fraction))
	assert_gt(absf(_lamp(_config(), GAP_HOURS[0]) - _lamp(_config(), GAP_HOURS[1])), MAX_MINUTE_STEP_LAMP, "Sensibilidade: meia hora de luz é bem mais que um minuto, então a medida enxerga um degrau.")


func test_a_golden_fraction_out_of_range_is_refused_and_the_range_ends_are_accepted() -> void:
	assert_eq(_config().validate(), [] as Array[String], "O recurso do jogo está em faixa.")
	for bad: float in [-0.1, 1.5, NAN]:
		assert_string_contains("\n".join(_probe(bad).validate()), "lamp_golden_fraction")
	for good: float in [0.0, 1.0]:
		assert_eq(_probe(good).validate(), [] as Array[String], "Os extremos da faixa valem: %s." % str(good))


func test_the_rig_emits_state_applied_for_each_applied_state_and_keeps_the_lamp_factor_of_the_last() -> void:
	var rig: AmbientRig = AmbientRig.new()
	rig.config = _config().duplicate() as AmbientConfig
	var world_environment: WorldEnvironment = WorldEnvironment.new()
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	for node: Node in [rig, world_environment, sun]:
		autofree(node)
	watch_signals(rig)
	assert_eq(rig.lamp_factor(), 0.0, "Sem estado aplicado: o dia.")
	var night: DayNightCycle.LightState = DayNightCycle.state_at(rig.config, 0.0)
	assert_true(rig.apply_state_to(world_environment, sun, night))
	assert_signal_emit_count(rig, "state_applied", 1)
	assert_eq(get_signal_parameters(rig, "state_applied", 0)[0], night, "O sinal leva o estado aplicado.")
	assert_eq(rig.lamp_factor(), night.lamp_factor)
	assert_true(rig.apply_state_to(world_environment, sun, DayNightCycle.state_at(rig.config, NOON)))
	assert_signal_emit_count(rig, "state_applied", 2)
	assert_eq(rig.lamp_factor(), 0.0)
	rig.config.sun_energy = TOO_HIGH
	assert_false(rig.apply_state_to(world_environment, sun, night))
	assert_push_error("AmbientRig: AmbientConfig inválido")
	assert_signal_emit_count(rig, "state_applied", 2, "Estado recusado: nada aplicado, nada emitido.")
	assert_eq(rig.lamp_factor(), 0.0, "E o fator guardado não muda.")


func test_refresh_emits_the_state_it_applies_and_nothing_while_the_clock_is_paused_and_the_light_does_not_change() -> void:
	var rig: AmbientRig = _rig_scene()
	assert_almost_eq(rig.lamp_factor(), 1.0, EXACT_TOLERANCE, "O jogo nasce à meia-noite: o `_ready` da rig já aplicou a luz da noite.")
	watch_signals(rig)
	assert_true(_host.request_pause(true).ok)
	for frame: int in range(5):
		assert_true(rig.refresh(FRAME_SECONDS))
	assert_signal_not_emitted(rig, "state_applied")
	assert_true(_host.request_pause(false).ok)
	assert_true(rig.refresh(FRAME_SECONDS))
	assert_true(rig.refresh(FRAME_SECONDS))
	assert_signal_emit_count(rig, "state_applied", 2, "Com o relógio andando a rig reaplica a luz a cada quadro (a fração do minuto cresce): o sinal vem junto.")
	assert_gt(_host.advance(PAUSED_REAL_SECONDS), 0)
	assert_true(rig.refresh())
	assert_signal_emit_count(rig, "state_applied", 3, "Minuto novo: a luz é aplicada de novo.")
