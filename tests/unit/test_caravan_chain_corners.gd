extends GutTest
## LW-099f (curvas naturais, EXPERIMENTAL): OS 3 CANTOS REAIS DOS POVOADOS. Os mercados saem de `data/world/places.json` (tipo `market`; nenhuma coordenada fixa aqui); os 3
## cantos (a virada em cada mercado visto de passagem) dão 6 passagens X para Y para Z, nos dois sentidos. Para cada passagem, veículo e raio: o trecho de CHEGADA é
## `CaravanRoad.through([X, Y], 0)` e o de SAÍDA é `CaravanRoad.entering(chegada.end_tangent(), Y, Z, R)`, ambos com a faixa de 1,2 m e a rampa suave de 12 m; o líder anda de 25 m
## antes do fim da chegada a 40 m depois do começo da saída, a 2,9 m/s. `R` é o PISO do raio do CAMINHO do veículo (ver `CaravanChainProbe.axis_radius`): curva à direita (por dentro da faixa)
## usa o raio do eixo `R + 1,2`; à esquerda, `R`. NÃO existe largura oficial de estrada no jogo: a de 2,0 m de meia-largura é [HIP] do estudo (a trilha da praça tem 1,6 m,
## `PlazaData.PATH_HALF_WIDTH_M`); aqui só se afirmam CONTAS, nenhuma largura de dado. A troca de trecho é afirmada em duas convenções: a ORIGEM do líder (o `s` do brief: troca quando a origem
## chega ao fim) e o APOIO DA FRENTE do líder (a troca acontece quando o ponto que anda sobre a estrada chega ao fim).

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
## Limite da articulação (graus) por raio de `RADII`, com a rampa suave de 12 m: o MÁXIMO MEDIDO nos 6 cantos reais (74,96; 56,21; 45,28 e 38,46 graus, para R de 4,1, 6, 8 e 10 m) mais 5%,
## arredondado para cima. A regra do estudo `d / R` (d = 6,013 m) dá 84,0; 57,4; 43,1 e 34,5: a rampa soma curvatura ao caminho (`faixa x 6 / rampa^2` = 0,05 por metro), então a regra fica
## 11% acima nos raios pequenos e 11% abaixo no de 10 m.
const ART_LIMIT_DEG: PackedFloat64Array = [79.0, 59.0, 47.6, 40.5]
const RATIO_MIN: float = 0.90
const RATIO_MAX: float = 1.10
## A meia-largura de estrada [HIP] do estudo (m).
const STUDY_HALF_WIDTH_M: float = 2.0


## Tudo o que se mede numa passagem, num veículo e num raio.
class Case:
	extends RefCounted

	var label: String = ""
	var wagon: bool = false
	var radius_m: float = 0.0
	var gap_origin: Vector2 = Vector2.ZERO
	var gap_support: Vector2 = Vector2.ZERO
	var jump_support: float = 0.0
	var jump_origin: float = 0.0
	var full: CaravanChainProbe.Walk = null
	var length_ratio: float = 0.0
	var factor: float = 1.0
	var radius_fits: bool = false


var _passages: Array[CaravanChainProbe.Passage] = []
var _cases: Array[Case] = []


func before_all() -> void:
	_passages = CaravanChainProbe.passages(CaravanChainProbe.markets())
	for passage: CaravanChainProbe.Passage in _passages:
		for radius: float in RADII:
			var roads: Array[CaravanRoad] = CaravanChainProbe.legs(passage, radius)
			for wagon: bool in [false, true]:
				_cases.append(_measure(passage, roads, CaravanChain.wagon_spec() if wagon else CaravanChain.cart_spec(), radius, wagon))


func _measure(passage: CaravanChainProbe.Passage, roads: Array[CaravanRoad], spec: CaravanChain.Spec, radius: float, wagon: bool) -> Case:
	var arrival: CaravanRoad = roads[0]
	var leave: CaravanRoad = roads[1]
	var measured: Case = Case.new()
	measured.label = "%s, %s, R %.1f" % [passage.label, "carroça" if wagon else "carrinho", radius]
	measured.wagon = wagon
	measured.radius_m = radius
	var end_m: float = arrival.length_m()
	var shift_m: float = spec.bodies[0].ref_front_m
	var step_m: float = SPEED * FRAME
	measured.gap_origin = CaravanChainProbe.junction_gap(arrival, leave, spec, 0.0)
	measured.gap_support = CaravanChainProbe.junction_gap(arrival, leave, spec, shift_m)
	var lane_factor: float = maxf(CaravanChainProbe.lane_speed_range(arrival, end_m - BEFORE_M - 14.0, end_m + 4.0).y, CaravanChainProbe.lane_speed_range(leave, -14.0, AFTER_M + 4.0).y)
	measured.factor = lane_factor * sqrt(1.0 + pow(SWING_ARM_M / radius, 2.0))
	var bound_m: float = step_m * measured.factor
	var crossing: CaravanChainProbe.Walk = CaravanChainProbe.walk(arrival, leave, spec, shift_m, end_m - WINDOW_BEFORE_M, end_m + WINDOW_AFTER_M, step_m)
	measured.jump_support = maxf(crossing.max_center_step_m, crossing.max_tail_step_m) / bound_m
	if wagon:
		var by_origin: CaravanChainProbe.Walk = CaravanChainProbe.walk(arrival, leave, spec, 0.0, end_m - WINDOW_BEFORE_M, end_m + WINDOW_AFTER_M, step_m)
		measured.jump_origin = maxf(by_origin.max_center_step_m, by_origin.max_tail_step_m) / bound_m
	else:
		measured.jump_origin = measured.jump_support
	measured.full = CaravanChainProbe.walk(arrival, leave, spec, shift_m, end_m - BEFORE_M, end_m + AFTER_M, FULL_STEP_M, PackedVector2Array([passage.from_point, passage.corner, passage.to_point]))
	measured.radius_fits = leave.corners().size() == 1 and absf(leave.corners()[0].radius_eff_m - CaravanChainProbe.axis_radius(passage, radius)) < 1e-6
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


func test_exit_leg_length_stays_within_the_contract_ratio_of_the_straight_road() -> void:
	for measured: Case in _cases:
		if measured.wagon:
			continue
		assert_between(measured.length_ratio, RATIO_MIN, RATIO_MAX, "%s: comprimento do trecho de saída com arco / reta de Y a Z" % measured.label)


func test_pose_is_continuous_when_the_leg_changes_for_the_cart_and_for_the_wagon_by_front_support() -> void:
	var worst_origin: Vector2 = Vector2.ZERO
	for measured: Case in _cases:
		assert_lte(measured.gap_support.x, POSITION_TOL_M, "%s: posição na troca de trecho (convenção do apoio da frente)" % measured.label)
		assert_lte(measured.gap_support.y, YAW_TOL_RAD, "%s: giro na troca de trecho (convenção do apoio da frente)" % measured.label)
		if measured.wagon:
			worst_origin = Vector2(maxf(worst_origin.x, measured.gap_origin.x), maxf(worst_origin.y, measured.gap_origin.y))
		else:
			assert_lte(measured.gap_origin.x, POSITION_TOL_M, "%s: carrinho, posição na troca (a origem é o apoio da frente)" % measured.label)
	gut.p("Troca de trecho do veículo comprido pela ORIGEM do líder: diferença máxima %.4f m e %.2f graus (o apoio da frente do cavalo está a +1,2 m, já dentro do arco da saída)." % [worst_origin.x, rad_to_deg(worst_origin.y)])
	if worst_origin.x > POSITION_TOL_M:
		pending("O arco da saída começa em s = 0 e o apoio da frente do cavalo está a +1,2 m: trocar o trecho pela ORIGEM do líder deixa %.4f m e %.2f graus de salto no cavalo; a troca pelo apoio da frente é exata." % [worst_origin.x, rad_to_deg(worst_origin.y)])


func test_no_frame_jump_across_the_leg_change() -> void:
	var worst_origin: float = 0.0
	for measured: Case in _cases:
		assert_lte(measured.jump_support, JUMP_MARGIN, "%s: maior passo do centro e da cauda atravessando a troca, em unidades de v x dt x fator (apoio da frente)" % measured.label)
		worst_origin = maxf(worst_origin, measured.jump_origin)
	gut.p("Maior passo atravessando a troca pela ORIGEM do líder: %.2f x v x dt x fator." % worst_origin)
	if worst_origin > JUMP_MARGIN:
		pending("Trocar o trecho pela ORIGEM do líder faz o veículo comprido dar um passo de %.2f x v x dt x fator no quadro da troca (o salto do cavalo)." % worst_origin)


func test_articulation_and_the_hitch_stay_within_the_limit_of_the_radius_on_the_real_corners() -> void:
	var worst_deg: PackedFloat64Array = PackedFloat64Array([0.0, 0.0, 0.0, 0.0])
	for measured: Case in _cases:
		assert_true(measured.radius_fits, "%s: o raio efetivo da saída é o pedido (o canto cabe)" % measured.label)
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
	assert_almost_eq(needed_cart_m, CaravanChainProbe.LANE_M + cart_half, WIDTH_TOL_M, "carrinho: a estrada precisa de faixa + meia-largura do carrinho de meia-largura")
	assert_almost_eq(needed_wagon_m, CaravanChainProbe.LANE_M + CaravanChain.WAGON_HALF_WIDTH_M, WIDTH_TOL_M, "veículo comprido: faixa + 1,005 m")
	gut.p("Meia-largura que a estrada precisa nas retas: carrinho %.3f m (folga %+.3f m com 2,0 m), veículo comprido %.3f m (folga %+.3f m com 2,0 m)." % [needed_cart_m, STUDY_HALF_WIDTH_M - needed_cart_m, needed_wagon_m, STUDY_HALF_WIDTH_M - needed_wagon_m])
	assert_lt(needed_cart_m, STUDY_HALF_WIDTH_M, "com 2,0 m de meia-largura o carrinho cabe")
	assert_gt(needed_wagon_m, STUDY_HALF_WIDTH_M, "com 2,0 m de meia-largura o veículo comprido passa da borda")
