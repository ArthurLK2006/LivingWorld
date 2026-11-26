extends GutTest
## LW-099f (curvas naturais, EXPERIMENTAL): o veículo andando. (1) CONTINUIDADE e ausência de salto da cadeia de corpos numa quina de 90 graus (raios de 6 e 10 m, com e sem a
## faixa de 1,2 m e a rampa suave de 12 m, curva por dentro e por fora da faixa), a 2,9 m/s, em quadros de 1/60 s e de 1 s. (2) A VARREDURA DE RAIOS do veículo comprido: R do CAMINHO
## de 4,1 m (o limite duro do estudo), 6 m (a referência), 8 e 10 m, sem faixa e com a faixa cheia de 1,2 m. Convenção do raio: `R` é o PISO do raio do CAMINHO do veículo (a faixa é
## à direita): sem faixa o eixo tem `R`; com faixa, a curva à direita (por dentro) pede o raio do EIXO `R + 1,2` e a curva à esquerda (por fora) pede `R - 1,2` (assim o menor raio do
## caminho é sempre `R`). Os limites são os MEDIDOS, com a margem declarada em cada constante.

const LANE: float = CaravanChainProbe.LANE_M
const RAMP: float = CaravanChainProbe.RAMP_M
const SPEED: float = CaravanChainProbe.SPEED_MPS
const FRAME: float = CaravanChainProbe.FRAME_S
## Margem de 2% do estudo sobre `v * dt * fator da faixa` (o fator é o MAIOR do caminho da faixa sobre o do eixo, medido na própria estrada).
const JUMP_MARGIN: float = 1.02
const HITCH_TOL_M: float = 2e-5
## Braço (m) do ponto que balança além de um apoio que gira com o caminho: o engate (1,976 m atrás do centro do cavalo) e a cauda (até 1,85 m atrás do centro do último corpo).
const SWING_ARM_M: float = 2.0
## Distância (m) do centro do cavalo ao centro da carroça: a regra do estudo é `articulação = d / R` (R mínimo = d ÷ ângulo máximo).
const CENTER_SPAN_M: float = 6.013
## O giro de um corpo por metro andado não passa de `curvatura máxima do caminho` x 1,1: a curvatura é `1 / R do caminho` mais, com a rampa de 12 m, a que ela soma (`faixa x 6 / rampa^2`).
const TURN_MARGIN: float = 1.1
## Margem de 5% sobre essa regra: o teste afirma `articulação <= 1,05 * d / R`.
const ART_MARGIN: float = 1.05
const CONT_RADII: PackedFloat64Array = [6.0, 10.0]
const SWEEP_RADII: PackedFloat64Array = [4.1, 6.0, 8.0, 10.0]
const SWEEP_TURNS: PackedFloat64Array = [90.0, 140.0]
const SWEEP_STEP_M: float = 0.1
const SWEEP_LEG_M: float = 70.0


## O fator REAL de velocidade na tela, declarado: o da faixa (o maior `|d faixa / d s|`, medido na própria estrada) vezes a ampliação cinemática de um ponto a `SWING_ARM_M` de um apoio
## que gira em um caminho de raio `r_path_m` (`sqrt(1 + (braço / R)^2)`: o engate e a cauda varrem mais depressa que o apoio). O passo de cada corpo por quadro tem de ficar em 1,02 x v x dt x isso.
func _factor(road: CaravanRoad, from_s: float, to_s: float, r_path_m: float) -> float:
	return CaravanChainProbe.lane_speed_range(road, from_s, to_s).y * sqrt(1.0 + pow(SWING_ARM_M / r_path_m, 2.0))


func _check_frames(label: String, road: CaravanRoad, spec: CaravanChain.Spec, min_path_radius_m: float, curvature_max: float, to_s: float) -> void:
	var factor: float = _factor(road, -14.0, to_s + 4.0, min_path_radius_m)
	for dt_s: float in [FRAME, 1.0]:
		var step_m: float = SPEED * dt_s
		var walked: CaravanChainProbe.Walk = CaravanChainProbe.walk(road, null, spec, 0.0, 0.0, to_s, step_m)
		var bound_m: float = JUMP_MARGIN * step_m * factor
		var tag: String = "%s, quadro de %.3f s (fator da faixa %.4f)" % [label, dt_s, factor]
		assert_true(walked.finite, tag + ": nenhum valor não finito")
		assert_lte(walked.max_center_step_m, bound_m, tag + ": passo do centro de cada corpo <= 1,02 x v x dt x fator")
		assert_lte(walked.max_tail_step_m, bound_m, tag + ": passo da cauda <= 1,02 x v x dt x fator")
		assert_lte(walked.max_hitch_error_m, HITCH_TOL_M, tag + ": engate exato")
		if dt_s < 0.5:
			var turn_bound_rad: float = TURN_MARGIN * step_m * curvature_max
			assert_lte(walked.max_yaw_step_rad, turn_bound_rad, tag + ": o giro de cada corpo por quadro não salta")
			assert_lte(walked.max_articulation_step_rad, 2.0 * turn_bound_rad, tag + ": a articulação cavalo x carroça é contínua")


func test_no_jump_through_90_degree_corners_with_and_without_the_lane() -> void:
	var specs: Array[CaravanChain.Spec] = [CaravanChain.cart_spec(), CaravanChain.wagon_spec()]
	for radius: float in CONT_RADII:
		for turn_deg: float in [90.0, -90.0]:
			for with_lane: bool in [false, true]:
				var lane_m: float = LANE if with_lane else 0.0
				var lead_m: float = 14.0 if radius <= 6.0 else 22.0
				var road: CaravanRoad = CaravanChainProbe.corner_road(turn_deg, lead_m, 60.0, radius, lane_m, RAMP if with_lane else 0.0)
				assert_almost_eq(road.corners()[0].radius_eff_m, radius, 1e-9, "o raio pedido cabe (o trecho de chegada de %.0f m dá tangente de até %.1f m)" % [lead_m, 0.5 * lead_m])
				var inside: float = lane_m if turn_deg > 0.0 else 0.0
				for spec: CaravanChain.Spec in specs:
					var label: String = "R do eixo %.0f, %s, %s, %d corpo(s)" % [radius, "direita" if turn_deg > 0.0 else "esquerda", "com faixa e rampa" if with_lane else "sem faixa", spec.bodies.size()]
					var curvature: float = 1.0 / (radius - inside) + (LANE * 6.0 / (RAMP * RAMP) if with_lane else 0.0)
					_check_frames(label, road, spec, radius - inside, curvature, 45.0)


func test_radius_sweep_of_the_wagon_on_90_and_140_degree_corners() -> void:
	var spec: CaravanChain.Spec = CaravanChain.wagon_spec()
	gut.p("Varredura de raios, veículo comprido (R = piso do raio do CAMINHO; limite = %.2f x d/R, d = %.3f m):" % [ART_MARGIN, CENTER_SPAN_M])
	for turn_deg: float in SWEEP_TURNS:
		var previous_deg: float = INF
		for radius: float in SWEEP_RADII:
			var modes: PackedStringArray = ["sem faixa", "faixa por dentro (curva à direita)", "faixa por fora (curva à esquerda)"]
			for mode: int in 3:
				var lane_m: float = 0.0 if mode == 0 else LANE
				var axis_m: float = radius + LANE if mode == 1 else (radius - LANE if mode == 2 else radius)
				var road: CaravanRoad = CaravanChainProbe.corner_road(-turn_deg if mode == 2 else turn_deg, SWEEP_LEG_M, SWEEP_LEG_M, axis_m, lane_m, 0.0)
				var apex_s: float = SWEEP_LEG_M - axis_m * tan(deg_to_rad(turn_deg) * 0.5) + 0.5 * axis_m * deg_to_rad(turn_deg)
				var walked: CaravanChainProbe.Walk = CaravanChainProbe.walk(road, null, spec, 0.0, apex_s - 25.0, apex_s + 30.0, SWEEP_STEP_M)
				var factor: float = _factor(road, apex_s - 35.0, apex_s + 35.0, radius)
				var art_deg: float = rad_to_deg(walked.max_articulation_rad)
				var limit_deg: float = ART_MARGIN * rad_to_deg(CENTER_SPAN_M / radius)
				var label: String = "curva de %.0f graus, R %.1f, %s" % [turn_deg, radius, modes[mode]]
				gut.p("  %s: articulação máx. %.1f graus (limite %.1f), engate %.8f m, maior passo %.4f x v dt (fator real %.4f)" % [label, art_deg, limit_deg, walked.max_hitch_error_m, walked.max_center_step_m / SWEEP_STEP_M, factor])
				assert_true(walked.finite, label + ": nenhum valor não finito")
				assert_lte(art_deg, limit_deg, label + ": articulação dentro do limite do raio")
				assert_lte(walked.max_hitch_error_m, HITCH_TOL_M, label + ": engate exato")
				assert_lte(walked.max_center_step_m, JUMP_MARGIN * SWEEP_STEP_M * factor, label + ": nenhum salto do centro de cada corpo")
				assert_lte(walked.max_tail_step_m, JUMP_MARGIN * SWEEP_STEP_M * factor, label + ": nenhum salto da cauda")
				if mode == 0:
					assert_lt(art_deg, previous_deg, label + ": raio maior, articulação menor (curva sem faixa)")
					previous_deg = art_deg
					if turn_deg > 100.0:
						assert_gte(art_deg, 0.75 * rad_to_deg(CENTER_SPAN_M / radius), label + ": a articulação chega perto da regra d / R numa curva longa")
