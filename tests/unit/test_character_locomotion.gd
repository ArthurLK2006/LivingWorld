extends GutTest
## ART-12, entrega 7a: a escolha do clipe e da escala de reprodução (`CharacterLocomotion.pick`): funções puras, só números (nenhum arquivo, nó nem relógio). Com as velocidades medidas do Ice Warrior ({walk 0,73; jog 4,1} m/s) e os limites de escala de 0,7 a 1,6, a tabela por velocidade do corpo fixa o clipe, a escala e o deslize esperados (calculados à mão: o que cabe na faixa do clipe tem deslize 0; fora dela a escala trava no limite e o deslize é a diferença). Parado ou velocidade inválida = idle; sem velocidade de figura válida = walk sem escala; no empate vence o clipe de menor velocidade; a saída nunca tem NaN nem escala fora dos limites; a função é determinística e não mexe nas velocidades recebidas.

const REAL: Dictionary = {"walk": 0.73, "jog": 4.1}
const TOLERANCE: float = 0.0001
## [velocidade do corpo (m/s), clipe, escala, deslize (m/s)] com as velocidades REAL.
const TABLE: Array = [
	[0.0, "idle", 1.0, 0.0],
	[0.5, "walk", 0.7, 0.011],
	[1.0, "walk", 1.0 / 0.73, 0.0],
	[1.2, "walk", 1.6, 0.032],
	[2.0, "walk", 1.6, 0.832],
	[4.0, "jog", 4.0 / 4.1, 0.0],
	[7.0, "jog", 1.6, 0.44],
	[8.0, "jog", 1.6, 1.44],
	[16.0, "jog", 1.6, 9.44],
	[32.0, "jog", 1.6, 25.44],
]
## Os pontos de varredura (m/s): de 0 a 40 de 0,01 em 0,01.
const SWEEP_STEPS: int = 4000
const SWEEP_STEP_MPS: float = 0.01


func _pick(speed: float, values: Dictionary = REAL) -> CharacterLocomotion.Pick:
	var speeds: Dictionary[String, float] = {}
	speeds.assign(values)
	return CharacterLocomotion.pick(speed, speeds)


func test_the_table_by_body_speed_gives_the_expected_clip_scale_and_slide() -> void:
	for row: Array in TABLE:
		var speed: float = row[0]
		var found: CharacterLocomotion.Pick = _pick(speed)
		assert_eq(found.clip, row[1], "%s m/s: o clipe" % speed)
		assert_almost_eq(found.scale, float(row[2]), TOLERANCE, "%s m/s: a escala" % speed)
		assert_almost_eq(found.slide_mps, float(row[3]), TOLERANCE, "%s m/s: o deslize" % speed)


func test_at_two_m_per_s_the_walk_at_the_top_scale_wins_over_the_jog_at_the_bottom_scale_by_a_small_margin() -> void:
	var walk: CharacterLocomotion.Pick = _pick(2.0, {"walk": 0.73})
	var jog: CharacterLocomotion.Pick = _pick(2.0, {"jog": 4.1})
	assert_almost_eq(walk.scale, CharacterLocomotion.MAX_SCALE, TOLERANCE, "o walk a 1,6x")
	assert_almost_eq(jog.scale, CharacterLocomotion.MIN_SCALE, TOLERANCE, "o jog a 0,7x")
	assert_almost_eq(jog.slide_mps - walk.slide_mps, 0.038, TOLERANCE, "o walk desliza 0,832 e o jog 0,870: quase empatam")
	assert_eq(_pick(2.0).clip, "walk", "com os dois, o de menor deslize: o walk")


func test_an_exact_tie_goes_to_the_clip_with_the_lower_speed_whatever_its_name() -> void:
	var tie: Array = [[{"walk": 1.0, "jog": 2.0}, "walk"], [{"jog": 2.0, "walk": 1.0}, "walk"], [{"walk": 2.0, "jog": 1.0}, "jog"], [{"walk": 1.0, "jog": 1.0}, "walk"]]
	for row: Array in tie:
		var found: CharacterLocomotion.Pick = _pick(1.5, row[0])
		assert_eq(found.clip, row[1], "empate com %s: vence %s" % [row[0], row[1]])
		assert_almost_eq(found.slide_mps, 0.0, TOLERANCE, "os dois cabem na faixa: deslize 0")


func test_a_near_tie_within_the_float_tolerance_counts_as_a_tie_and_a_clear_difference_does_not() -> void:
	var speeds: Dictionary = {"walk": 1.0, "jog": 4.0}
	assert_eq(_pick(2.200001, speeds).clip, "walk", "deslizes 0,600001 e 0,599999 (diferença de 0,000002, dentro da tolerância): empate, vence a menor velocidade de clipe")
	assert_eq(_pick(2.201, speeds).clip, "jog", "deslizes 0,601 e 0,599: o jog desliza menos e vence")


func test_without_a_valid_figure_speed_the_walk_plays_without_scale_and_only_walk_and_jog_count() -> void:
	var nothing: Array = [{}, {"walk": 0.0, "jog": -4.1}, {"walk": NAN, "jog": INF}, {"run": 3.0, "idle": 1.0}]
	for values: Dictionary in nothing:
		for speed: float in [0.3, 1.0, 5.0]:
			var found: CharacterLocomotion.Pick = _pick(speed, values)
			assert_eq(found.clip, "walk", "%s a %s m/s: walk" % [values, speed])
			assert_eq(found.scale, 1.0, "sem escala")
			assert_eq(found.slide_mps, 0.0, "sem deslize conhecido")
	var only_jog: CharacterLocomotion.Pick = _pick(1.0, {"walk": 0.0, "jog": 4.1})
	assert_eq(only_jog.clip, "jog", "o valor inválido do walk é ignorado e o jog vale")
	assert_almost_eq(only_jog.slide_mps, 1.87, TOLERANCE, "jog a 0,7x: |1 - 2,87|")


func test_a_still_or_invalid_body_speed_is_idle_with_scale_one_and_no_slide() -> void:
	for speed: float in [0.0, -1.0, -0.0001, NAN, INF, -INF]:
		for values: Dictionary in [REAL, {}]:
			var found: CharacterLocomotion.Pick = _pick(speed, values)
			assert_eq(found.clip, "idle", "%s m/s: idle" % speed)
			assert_eq(found.scale, 1.0, "escala 1")
			assert_eq(found.slide_mps, 0.0, "deslize 0")


func test_the_output_is_always_finite_and_the_scale_stays_within_the_limits() -> void:
	var tables: Array = [REAL, {"walk": 0.73}, {"jog": 4.1}, {}, {"walk": 0.000001, "jog": 100.0}, {"walk": 100.0, "jog": 100.0}]
	var bad: int = 0
	for values: Dictionary in tables:
		for step: int in SWEEP_STEPS + 1:
			var found: CharacterLocomotion.Pick = _pick(step * SWEEP_STEP_MPS, values)
			var inside: bool = found.scale >= CharacterLocomotion.MIN_SCALE and found.scale <= CharacterLocomotion.MAX_SCALE
			bad += 0 if inside and is_finite(found.scale) and is_finite(found.slide_mps) and found.slide_mps >= 0.0 else 1
	assert_eq(bad, 0, "nenhuma saída com NaN, infinito, deslize negativo ou escala fora de [MIN_SCALE, MAX_SCALE]")


func test_the_choice_is_deterministic_and_does_not_change_the_speeds() -> void:
	var speeds: Dictionary[String, float] = {"walk": 0.73, "jog": 4.1}
	var before: Dictionary[String, float] = speeds.duplicate()
	var first: CharacterLocomotion.Pick = CharacterLocomotion.pick(3.3, speeds)
	var second: CharacterLocomotion.Pick = CharacterLocomotion.pick(3.3, speeds)
	assert_eq([first.clip, first.scale, first.slide_mps], [second.clip, second.scale, second.slide_mps], "a mesma entrada, a mesma saída")
	assert_eq(speeds, before, "as velocidades recebidas ficam como estavam")
