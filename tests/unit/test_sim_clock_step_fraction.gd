extends GutTest
## LW-099b1: a FRAÇÃO DE PASSO do relógio (contrato da LW-099, seção 6), `SimClock.step_fraction()`: o acúmulo pendente dividido por `real_ms_per_minute`, em [0, 1). É SÓ LEITURA: não muda o ritmo, o passo, o save nem o hash do relógio; em pausa não anda; depois de `on_load` vale 0.
## A conta dos passos (`steps_for_frame`) continua em inteiros e é a que decide quantos passos rodar.

const MS_PER_MINUTE: int = 1000
const YEAR_DAYS: int = 10
## Quadros de tempos "quebrados" (ms reais), para os acúmulos não caírem sempre nos mesmos valores.
const FRAMES_MS: Array[int] = [7, 33, 16, 250, 999, 1, 1000, 3, 480, 17, 2500]


func _clock() -> SimClock:
	return SimClock.new(YEAR_DAYS, MS_PER_MINUTE)


func test_a_new_clock_has_fraction_zero() -> void:
	assert_eq(_clock().step_fraction(), 0.0)
	assert_eq(SimClock.new().step_fraction(), 0.0, "Com o ritmo padrão (1250 ms por minuto) também.")


func test_the_fraction_is_the_pending_time_over_the_minute_and_resets_when_a_step_is_due() -> void:
	var clock: SimClock = _clock()
	var seen: Array[float] = []
	var steps: Array[int] = []
	for frame_ms: int in [300, 300, 300, 300, 300]:
		steps.append(clock.steps_for_frame(frame_ms))
		seen.append(clock.step_fraction())
	assert_eq(steps, [0, 0, 0, 1, 0] as Array[int], "A conta dos passos é a de sempre: o quarto quadro completa o minuto.")
	for index: int in seen.size():
		assert_almost_eq(seen[index], [0.3, 0.6, 0.9, 0.2, 0.5][index], 0.000001, "Quadro %d: o que sobrou do minuto, em fração." % index)
	var standard: SimClock = SimClock.new()
	assert_eq(standard.steps_for_frame(100), 0)
	assert_almost_eq(standard.step_fraction(), 0.08, 0.000001, "Com o ritmo padrão: 100 ms de 1250.")
	assert_true(standard.set_speed(4).ok)
	assert_eq(standard.steps_for_frame(100), 0)
	assert_almost_eq(standard.step_fraction(), 0.4, 0.000001, "A 4x os mesmos 100 ms valem 400 de 1250 (0,08 + 0,32).")


func test_the_fraction_is_never_one_or_more_whatever_the_frames_and_the_speed() -> void:
	for speed: int in range(SimClock.MIN_SPEED, SimClock.MAX_SPEED + 1):
		var clock: SimClock = _clock()
		assert_true(clock.set_speed(speed).ok)
		for _round: int in 12:
			for frame_ms: int in FRAMES_MS:
				var steps: int = clock.steps_for_frame(frame_ms)
				var fraction: float = clock.step_fraction()
				assert_true(fraction >= 0.0 and fraction < 1.0, "Velocidade %d, %d passos: f = %s fora de [0, 1)." % [speed, steps, str(fraction)])
				assert_eq(clock.validate(), [] as Array[String], "O relógio segue válido (o acúmulo continua dentro do minuto).")


func test_the_fraction_does_not_move_while_paused_and_comes_back_to_moving_after() -> void:
	var clock: SimClock = _clock()
	clock.steps_for_frame(400)
	clock.set_paused(true)
	for _round: int in 5:
		assert_eq(clock.steps_for_frame(700), 0, "Pausado, nenhum passo.")
		assert_almost_eq(clock.step_fraction(), 0.4, 0.000001, "Pausado, a fração fica onde estava.")
	clock.set_paused(false)
	assert_eq(clock.steps_for_frame(100), 0)
	assert_almost_eq(clock.step_fraction(), 0.5, 0.000001, "Despausado, segue de onde estava (0,4 + 0,1).")


func test_on_load_zeroes_the_fraction() -> void:
	var clock: SimClock = _clock()
	clock.steps_for_frame(850)
	assert_gt(clock.step_fraction(), 0.0)
	assert_true(clock.on_load({SimClock.KEY_TOTAL_MINUTES: 77}).ok)
	assert_eq([clock.step_fraction(), clock.total_minutes()], [0.0, 77], "Carregar zera o acúmulo (o ritmo não é salvo): a fração volta a 0.")
	assert_eq(clock.steps_for_frame(250), 0)
	assert_almost_eq(clock.step_fraction(), 0.25, 0.000001, "Depois de carregar o acúmulo recomeça do zero.")


func test_reading_the_fraction_changes_nothing_in_the_steps_the_save_or_the_hash() -> void:
	var watched: SimClock = _clock()
	var silent: SimClock = _clock()
	var watched_steps: Array[int] = []
	var silent_steps: Array[int] = []
	for _round: int in 30:
		for frame_ms: int in FRAMES_MS:
			watched_steps.append(watched.steps_for_frame(frame_ms))
			watched.step_fraction()
			silent_steps.append(silent.steps_for_frame(frame_ms))
	assert_eq(watched_steps, silent_steps, "Os mesmos passos por quadro, com e sem a leitura.")
	assert_eq([watched.serialize(), watched.debug_summary(), watched.validate()], [silent.serialize(), silent.debug_summary(), silent.validate()], "O save, o resumo e a validação do relógio são os mesmos.")
	assert_eq(watched.serialize().keys(), [SimClock.KEY_TOTAL_MINUTES], "O save do relógio continua com uma só chave (o tempo simulado).")
