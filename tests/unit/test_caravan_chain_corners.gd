extends GutTest
## LW-099f (curvas naturais, EXPERIMENTAL): OS 3 CANTOS REAIS DOS POVOADOS. Os mercados saem de `data/world/places.json` (tipo `market`; nenhuma coordenada fixa aqui); os 3
## cantos (a virada em cada mercado visto de passagem) dão 6 passagens X para Y para Z, nos dois sentidos. Para cada passagem, veículo e raio: o trecho de CHEGADA é
## `CaravanRoad.through([X, Y], 0)` e o de SAÍDA é `CaravanRoad.entering(chegada.end_tangent(), Y, Z, R_eixo, CaravanChain.front_extent_m(veículo))`, ambos com a faixa de 1,2 m e a rampa suave
## de 12 m; o líder anda de 25 m antes do fim da chegada a 40 m depois do começo da saída, a 2,9 m/s, e a troca de trecho acontece quando a ORIGEM do líder chega ao fim da chegada. `R` é o PISO do raio do
## CAMINHO do veículo (ver `CaravanChainProbe.axis_radius`): curva à direita (por dentro da faixa) usa o raio do eixo `R + 1,2`; à esquerda, `R`. O `straight_m` (1,2 m no veículo comprido, 0 no carrinho)
## é o que torna a troca pela origem EXATA: o apoio da frente do cavalo está a +1,2 m, e sem o trecho reto ele já estaria dentro do arco da saída (contraprova no último teste de troca).
## NÃO existe largura oficial de estrada no jogo: a de 2,0 m de meia-largura é [HIP] do estudo (a trilha da praça tem 1,6 m, `PlazaData.PATH_HALF_WIDTH_M`); aqui só se afirmam CONTAS.

const RADII: PackedFloat64Array = [4.1, 6.0, 8.0, 10.0]
const SPEED: float = CaravanChainProbe.SPEED_MPS
const FRAME: float = CaravanChainProbe.FRAME_S
const BEFORE_M: float = 25.0
const AFTER_M: float = 40.0
## Janela (m) em volta da troca onde se mede o passo por quadro de 1/60 s.
const WINDOW_BEFORE_M: float = 6.0
const WINDOW_AFTER_M: float = 12.0
const FULL_STEP_M: float = 0.1
const JUMP_MARGIN: float = 1.02
const POSITION_TOL_M: float = 0.001
const YAW_TOL_RAD: float = 0.0017453292519943296
## O `Vector2` de 32 bits tem 61 micrômetros de unidade a 800 m (onde ficam os mercados reais): o engate e as larguras são conferidos a 5e-4 m.
const HITCH_TOL_M: float = 5e-4
const WIDTH_TOL_M: float = 5e-4
## Braço (m) do ponto que balança além de um apoio (o engate e a cauda); ver `test_caravan_chain_motion.gd`.
const SWING_ARM_M: float = 2.0
const CENTER_SPAN_M: float = 6.013
## Limite da articulação (graus) por raio de `RADII`, com a rampa suave de 12 m: o MÁXIMO MEDIDO nos 6 cantos reais (74,96; 56,21; 45,28 e 38,46 graus, para R de 4,1, 6, 8 e 10 m, sem o trecho reto) mais 5%,
## arredondado para cima. A regra do estudo `d / R` (d = 6,013 m) dá 84,0; 57,4; 43,1 e 34,5: a rampa soma curvatura ao caminho (`faixa x 6 / rampa^2` = 0,05 por metro), então a regra fica
## 11% acima nos raios pequenos e 11% abaixo no de 10 m. O trecho reto de 1,2 m do veículo comprido não passa disso (o teste confere).
const ART_LIMIT_DEG: PackedFloat64Array = [79.0, 59.0, 47.6, 40.5]
const RATIO_MIN: float = 0.90
const RATIO_MAX: float = 1.10
## A meia-largura de estrada [HIP] do estudo (m).
const STUDY_HALF_WIDTH_M: float = 2.0


## Tudo o que se mede numa passagem, num veículo e num raio. `gap` e `jump` são com o trecho reto (`straight_m`); `gap_plain` e `jump_plain` (só no veículo comprido) são SEM ele (a contraprova).
class Case:
	extends RefCounted

	var label: String = ""
	var wagon: bool = false
	var radius_m: float = 0.0
	var gap: Vector2 = Vector2.ZERO
	var jump: float = 0.0
	var gap_plain: Vector2 = Vector2.ZERO
	var jump_plain: float = 0.0
	var full: CaravanChainProbe.Walk = null
	var length_ratio: float = 0.0
	var factor: float = 1.0
	var radius_fits: bool = false
	var straight_ok: bool = false


var _passages: Array[CaravanChainProbe.Passage] = []
var _cases: Array[Case] = []


func before_all() -> void:
	_passages = CaravanChainProbe.passages(CaravanChainProbe.markets())
	for passage: CaravanChainProbe.Passage in _passages:
		for radius: float in RADII:
			for wagon: bool in [false, true]:
				_cases.append(_measure(passage, CaravanChain.wagon_spec() if wagon else CaravanChain.cart_spec(), radius, wagon))


func _measure(passage: CaravanChainProbe.Passage, spec: CaravanChain.Spec, radius: float, wagon: bool) -> Case:
	var straight_m: float = CaravanChain.front_extent_m(spec)
	var roads: Array[CaravanRoad] = CaravanChainProbe.legs(passage, radius, straight_m)
	var arrival: CaravanRoad = roads[0]
	var leave: CaravanRoad = roads[1]
	var measured: Case = Case.new()
	measured.label = "%s, %s, R %.1f" % [passage.label, "carroça" if wagon else "carrinho", radius]
	measured.wagon = wagon
	measured.radius_m = radius
	var end_m: float = arrival.length_m()
	var step_m: float = SPEED * FRAME
	measured.gap = CaravanChainProbe.junction_gap(arrival, leave, spec, 0.0)
	var lane_factor: float = maxf(CaravanChainProbe.lane_speed_range(arrival, end_m - BEFORE_M - 14.0, end_m + 4.0).y, CaravanChainProbe.lane_speed_range(leave, -14.0, AFTER_M + 4.0).y)
	measured.factor = lane_factor * sqrt(1.0 + pow(SWING_ARM_M / radius, 2.0))
	var bound_m: float = step_m * measured.factor
	var crossing: CaravanChainProbe.Walk = CaravanChainProbe.walk(arrival, leave, spec, 0.0, end_m - WINDOW_BEFORE_M, end_m + WINDOW_AFTER_M, step_m)
	measured.jump = maxf(crossing.max_center_step_m, crossing.max_tail_step_m) / bound_m
	if wagon:
		var plain: Array[CaravanRoad] = CaravanChainProbe.legs(passage, radius, 0.0)
		measured.gap_plain = CaravanChainProbe.junction_gap(plain[0], plain[1], spec, 0.0)
		var plain_walk: CaravanChainProbe.Walk = CaravanChainProbe.walk(plain[0], plain[1], spec, 0.0, end_m - WINDOW_BEFORE_M, end_m + WINDOW_AFTER_M, step_m)
		measured.jump_plain = maxf(plain_walk.max_center_step_m, plain_walk.max_tail_step_m) / bound_m
	measured.full = CaravanChainProbe.walk(arrival, leave, spec, 0.0, end_m - BEFORE_M, end_m + AFTER_M, FULL_STEP_M, PackedVector2Array([passage.from_point, passage.corner, passage.to_point]))
	measured.radius_fits = leave.corners().size() == 1 and absf(leave.corners()[0].radius_eff_m - CaravanChainProbe.axis_radius(passage, radius)) < 1e-6
	measured.straight_ok = leave.axis_point(straight_m).distance_to(passage.corner + arrival.end_tangent() * straight_m) < WIDTH_TOL_M and leave.axis_tangent(straight_m + 1.0).distance_to(arrival.end_tangent()) > 1e-3
	measured.length_ratio = leave.length_m() / passage.corner.distance_to(passage.to_point)
	return measured


func test_the_three_real_corners_are_read_from_the_data_with_sane_turn_angles() -> void:
	assert_eq(CaravanChainProbe.markets().size(), 3, "o world de teste tem 3 mercados")
	assert_eq(_passages.size(), 6, "3 cantos nos dois sentidos: 6 passagens")
	for index: int in 3:
		var turn_a: float = _passages[2 * index].turn_deg
		var turn_b: float = _passages[2 * index + 1].turn_deg
		assert_almost_eq(turn_a, -turn_b, 1e-9, "o mesmo canto nos dois sentidos: a mesma virada, com o sinal trocado")
	for passage: CaravanChainProbe.Passage in _passages:
		assert_between(absf(passage.turn_deg), 80.0, 150.0, "%s: a virada fica numa faixa sã" % passage.label)
	gut.p("Viradas dos cantos reais (graus, + = direita): %s" % ", ".join(_passages.map(func(p: CaravanChainProbe.Passage) -> String: return "%s %.1f" % [p.label, p.turn_deg])))


func test_exit_leg_goes_straight_for_the_front_extent_then_curves_and_keeps_the_contract_ratio() -> void:
	var worst_ratio: float = 0.0
	for measured: Case in _cases:
		assert_true(measured.radius_fits, "%s: o raio efetivo da saída é o pedido (o canto cabe)" % measured.label)
		assert_true(measured.straight_ok, "%s: a saída segue reta por straight_m depois do mercado e só então faz o arco" % measured.label)
		assert_between(measured.length_ratio, RATIO_MIN, RATIO_MAX, "%s: comprimento do trecho de saída com arco / reta de Y a Z" % measured.label)
		worst_ratio = maxf(worst_ratio, measured.length_ratio)
	gut.p("Maior razão de comprimento do trecho de saída (com o trecho reto): %.4f." % worst_ratio)


func test_pose_is_continuous_when_the_leg_changes_by_the_origin_of_the_leader() -> void:
	var worst: Vector2 = Vector2.ZERO
	for measured: Case in _cases:
		assert_lte(measured.gap.x, POSITION_TOL_M, "%s: posição de TODOS os corpos na troca de trecho (chegada em seu fim x saída em s = 0)" % measured.label)
		assert_lte(measured.gap.y, YAW_TOL_RAD, "%s: giro de TODOS os corpos na troca de trecho" % measured.label)
		worst = Vector2(maxf(worst.x, measured.gap.x), maxf(worst.y, measured.gap.y))
	gut.p("Troca de trecho pela ORIGEM do líder, com o trecho reto: diferença máxima %.6f m e %.4f graus (6 passagens x 2 veículos x 4 raios)." % [worst.x, rad_to_deg(worst.y)])


func test_no_frame_jump_across_the_leg_change_for_the_horse_and_the_wagon() -> void:
	var worst: float = 0.0
	for measured: Case in _cases:
		assert_lte(measured.jump, JUMP_MARGIN, "%s: maior passo do centro e da cauda atravessando a troca, em unidades de v x dt x fator real" % measured.label)
		worst = maxf(worst, measured.jump)
	gut.p("Maior passo por quadro de 1/60 s atravessando a troca (com o trecho reto): %.3f x v x dt x fator real." % worst)


func test_without_the_straight_run_the_horse_still_jumps_at_the_leg_change() -> void:
	var worst_m: float = 0.0
	var worst_rad: float = 0.0
	var worst_jump: float = 0.0
	for measured: Case in _cases:
		if not measured.wagon:
			continue
		assert_gt(measured.gap_plain.x, POSITION_TOL_M, "%s: SEM o trecho reto o cavalo salta na troca pela origem (o apoio da frente, a +1,2 m, já está dentro do arco)" % measured.label)
		worst_m = maxf(worst_m, measured.gap_plain.x)
		worst_rad = maxf(worst_rad, measured.gap_plain.y)
		worst_jump = maxf(worst_jump, measured.jump_plain)
	gut.p("Contraprova, SEM o trecho reto (straight_m = 0): salto do cavalo %.4f m e %.2f graus; passo %.2f x v x dt x fator real." % [worst_m, rad_to_deg(worst_rad), worst_jump])
	assert_between(worst_m, 0.08, 0.10, "o pior salto sem o trecho reto é o medido: 0,088 m")
	assert_between(rad_to_deg(worst_rad), 4.0, 4.4, "e 4,2 graus")
	assert_gt(worst_jump, JUMP_MARGIN, "o passo no quadro da troca passa de 1,02 x v x dt x fator real (medido 1,59)")


func test_articulation_and_the_hitch_stay_within_the_limit_of_the_radius_on_the_real_corners() -> void:
	var worst_deg: PackedFloat64Array = PackedFloat64Array([0.0, 0.0, 0.0, 0.0])
	for measured: Case in _cases:
		assert_true(measured.full.finite, "%s: nenhum valor não finito" % measured.label)
		assert_lte(measured.full.max_hitch_error_m, HITCH_TOL_M, "%s: engate exato" % measured.label)
		if measured.wagon:
			var index: int = RADII.find(measured.radius_m)
			worst_deg[index] = maxf(worst_deg[index], rad_to_deg(measured.full.max_articulation_rad))
			assert_lte(rad_to_deg(measured.full.max_articulation_rad), ART_LIMIT_DEG[index], "%s: articulação máxima dentro do limite do raio" % measured.label)
	for index: int in RADII.size():
		gut.p("R %.1f: articulação máxima nos 6 cantos %.2f graus (regra d/R = %.2f; limite do teste %.1f)" % [RADII[index], worst_deg[index], rad_to_deg(CENTER_SPAN_M / RADII[index]), ART_LIMIT_DEG[index]])


func test_the_vehicle_strays_from_the_official_roads_more_with_a_larger_radius() -> void:
	for passage_index: int in _passages.size():
		for wagon: bool in [false, true]:
			var previous_m: float = 0.0
			for radius_index: int in RADII.size():
				var measured: Case = _cases[(passage_index * RADII.size() + radius_index) * 2 + (1 if wagon else 0)]
				assert_gte(measured.full.max_official_offset_m, previous_m - 0.05, "%s: o afastamento das estradas oficiais cresce com o raio" % measured.label)
				previous_m = measured.full.max_official_offset_m
	var worst_m: float = 0.0
	for measured: Case in _cases:
		worst_m = maxf(worst_m, measured.full.max_official_offset_m)
	gut.p("Maior afastamento do varrido do veículo em relação às duas estradas oficiais (retas X-Y e Y-Z), entre todas as passagens, veículos e raios: %.2f m." % worst_m)
	assert_gt(worst_m, 2.0, "nas curvas o varrido sai da estrada oficial por bem mais que a largura da faixa")


func test_the_half_width_the_straight_roads_need_is_the_lane_plus_the_half_width_of_the_vehicle() -> void:
	var needed_cart_m: float = 0.0
	var needed_wagon_m: float = 0.0
	for passage: CaravanChainProbe.Passage in _passages:
		var arrival: CaravanRoad = CaravanChainProbe.legs(passage, 6.0)[0]
		var middle_m: float = arrival.length_m() * 0.5
		needed_cart_m = maxf(needed_cart_m, CaravanChain.max_axis_offset_m(arrival, CaravanChain.cart_spec(), middle_m - 5.0, middle_m + 5.0, 0.5))
		needed_wagon_m = maxf(needed_wagon_m, CaravanChain.max_axis_offset_m(arrival, CaravanChain.wagon_spec(), middle_m - 5.0, middle_m + 5.0, 0.5))
	var cart_half: float = CaravanView.WHEEL_SIDE_M + CaravanView.WHEEL_THICKNESS_M * 0.5
	assert_almost_eq(needed_cart_m, CaravanChainProbe.LANE_M + cart_half, WIDTH_TOL_M, "carrinho: a estrada precisa de faixa + meia-largura do carrinho")
	assert_almost_eq(needed_wagon_m, CaravanChainProbe.LANE_M + CaravanChain.WAGON_HALF_WIDTH_M, WIDTH_TOL_M, "veículo comprido: faixa + 1,005 m")
	gut.p("Meia-largura que a estrada precisa nas retas: carrinho %.3f m (folga %+.3f m com 2,0 m), veículo comprido %.3f m (folga %+.3f m com 2,0 m)." % [needed_cart_m, STUDY_HALF_WIDTH_M - needed_cart_m, needed_wagon_m, STUDY_HALF_WIDTH_M - needed_wagon_m])
	assert_lt(needed_cart_m, STUDY_HALF_WIDTH_M, "com 2,0 m de meia-largura o carrinho cabe")
	assert_gt(needed_wagon_m, STUDY_HALF_WIDTH_M, "com 2,0 m de meia-largura o veículo comprido passa da borda")
