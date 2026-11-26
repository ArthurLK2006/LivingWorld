extends GutTest
## LW-099f (curvas naturais, EXPERIMENTAL; só apresentação): a cadeia de corpos rígidos (`CaravanChain`) sobre a estrada com arcos (`CaravanRoad`). Aqui: o carrinho de
## hoje, o veículo comprido de referência (cavalo e carroça de 4 rodas, 9,1 m), o ORÁCULO analítico num arco circular (calculado à mão, independente da bisseção da
## estrada e com uma varredura densa do engate), a pureza e as entradas ruins. Só contas, sem nó nem janela. As medidas do veículo são [HIP]; os números esperados saem da mão.

const TOL_M: float = 1e-5
## Nas retas de 300 m o `Vector2` de 32 bits (7,6 micrômetros de unidade a 100 m) soma ruído de 2 a 4 unidades: 3e-5 m.
const STRAIGHT_TOL_M: float = 3e-5
const LANE: float = CaravanChainProbe.LANE_M
const RAMP: float = CaravanChainProbe.RAMP_M
const LANES: PackedFloat64Array = [0.0, CaravanChainProbe.LANE_M]
const RADII: PackedFloat64Array = [6.0, 8.0, 10.0]
const CART_CHORD_M: float = 2.1
const HORSE_CHORD_M: float = 2.4
## Passo (m) e limite de passos da varredura densa do engate (independente da bisseção).
const DENSE_STEP_M: float = 1e-4
const DENSE_MAX_STEPS: int = 100000


## O arco de uma quina de `turn_deg` graus à DIREITA (chegada em +X, trechos de `leg_m`), calculado à mão, sem a `CaravanRoad`: o centro, o `s` em que o arco começa e o comprimento.
class Circle:
	extends RefCounted

	var radius: float = 0.0
	var center: Vector2 = Vector2.ZERO
	var start_s: float = 0.0
	var arc_m: float = 0.0

	func _init(turn_deg: float, leg_m: float, radius_m: float) -> void:
		radius = radius_m
		var tangent_m: float = radius_m * tan(deg_to_rad(turn_deg) * 0.5)
		center = Vector2(-tangent_m, radius_m)
		start_s = leg_m - tangent_m
		arc_m = radius_m * deg_to_rad(turn_deg)

	## O ponto do arco a `arc` metros do começo do arco.
	func point(arc: float) -> Vector2:
		return center + Vector2.from_angle(-PI * 0.5 + arc / radius) * radius

	## A frente de um corpo com os apoios em `front_arc` e `rear_arc`: a tangente do círculo no ÂNGULO MÉDIO dos dois apoios.
	func heading(front_arc: float, rear_arc: float) -> Vector2:
		return Vector2.from_angle(0.5 * (front_arc + rear_arc) / radius)

	## O apoio de trás de um corpo de corda `chord_m` cujo apoio da frente está em `front_arc` (a corda de um ângulo central `2 asen(c / 2R)`).
	func rear_of(front_arc: float, chord_m: float) -> float:
		return front_arc - radius * 2.0 * asin(chord_m / (2.0 * radius))


func _poses(road: CaravanRoad, spec: CaravanChain.Spec, s: float) -> Array[CaravanChain.RigidPose]:
	var poses: Array[CaravanChain.RigidPose] = CaravanChain.make_poses(spec)
	CaravanChain.poses_into(road, spec, s, poses)
	return poses


## O apoio (da frente ou de trás) do corpo `body`, recuperado da pose.
func _support(poses: Array[CaravanChain.RigidPose], spec: CaravanChain.Spec, body: int, rear: bool) -> Vector2:
	var shape: CaravanChain.Body = spec.bodies[body]
	return poses[body].at_lead_frame(shape.ref_rear_m if rear else shape.ref_front_m)


## Varredura densa, para trás, do primeiro ponto do arco a `distance_m` do engate (com interpolação linear no último passo): o oráculo do engate, sem bisseção.
func _dense_scan_behind(circle: Circle, hitch: Vector2, distance_m: float, from_arc: float) -> float:
	var arc: float = from_arc
	var before: float = circle.point(arc).distance_to(hitch)
	for _step: int in DENSE_MAX_STEPS:
		var next_arc: float = arc - DENSE_STEP_M
		var gap: float = circle.point(next_arc).distance_to(hitch)
		if gap >= distance_m:
			return arc - DENSE_STEP_M * (distance_m - before) / (gap - before)
		arc = next_arc
		before = gap
	return arc


func test_cart_on_a_straight_road_keeps_the_axle_2_1_m_behind_with_the_road_heading() -> void:
	var direction: Vector2 = Vector2(3.0, 4.0).normalized()
	var road: CaravanRoad = CaravanChainProbe.line_road(direction, 300.0, 0.0, 0.0)
	var spec: CaravanChain.Spec = CaravanChain.cart_spec()
	var poses: Array[CaravanChain.RigidPose] = _poses(road, spec, 120.0)
	assert_eq(poses.size(), 1, "o carrinho é UM corpo rígido")
	assert_almost_eq(_support(poses, spec, 0, false).distance_to(direction * 20.0), 0.0, TOL_M, "o comerciante (z 0) fica em s = 120 m (a origem da reta é o s 100)")
	assert_almost_eq(_support(poses, spec, 0, true).distance_to(direction * (20.0 - CaravanView.CART_BACK_M)), 0.0, TOL_M, "o eixo fica 2,1 m atrás, na mesma reta")
	assert_almost_eq(_support(poses, spec, 0, false).distance_to(_support(poses, spec, 0, true)), 2.1, TOL_M, "apoio de trás a 2,1 m exatos")
	assert_almost_eq(poses[0].yaw(), atan2(-direction.x, -direction.y), 1e-6, "o giro é o da estrada (a conta do CaravanPath)")
	assert_almost_eq(poses[0].origin().distance_to(road.sample(120.0)), 0.0, TOL_M, "origin() é o ponto da faixa em s")


func test_cart_on_an_arc_has_the_exact_chord_and_both_supports_on_the_lane() -> void:
	var spec: CaravanChain.Spec = CaravanChain.cart_spec()
	for lane_m: float in LANES:
		var road: CaravanRoad = CaravanChainProbe.corner_road(90.0, 40.0, 60.0, 10.0, lane_m, 0.0)
		for k: int in 12:
			var s: float = 31.0 + 1.1 * float(k)
			var poses: Array[CaravanChain.RigidPose] = _poses(road, spec, s)
			var label: String = "faixa %.1f, s %.1f" % [lane_m, s]
			assert_almost_eq(poses[0].origin().distance_to(road.sample(s)), 0.0, TOL_M, label + ": origin() = o ponto da faixa em s")
			assert_almost_eq(_support(poses, spec, 0, false).distance_to(_support(poses, spec, 0, true)), CART_CHORD_M, TOL_M, label + ": corda exata")
			assert_lt(CaravanChainProbe.lane_distance(road, _support(poses, spec, 0, true), s - CART_CHORD_M, 1.0), TOL_M, label + ": o apoio de trás está SOBRE a faixa")


func test_wagon_on_a_straight_road_has_the_reference_measures_exactly() -> void:
	var spec: CaravanChain.Spec = CaravanChain.wagon_spec()
	for direction: Vector2 in [Vector2.RIGHT, Vector2(3.0, 4.0).normalized(), Vector2(-1.0, -2.0).normalized()]:
		var road: CaravanRoad = CaravanChainProbe.line_road(direction, 300.0, 0.0, 0.0)
		var poses: Array[CaravanChain.RigidPose] = _poses(road, spec, 100.0)
		var hitch: Vector2 = poses[0].at_lead_frame(CaravanChain.HITCH_Z_M)
		var label: String = "direção %s" % direction
		assert_almost_eq(_support(poses, spec, 0, false).distance_to(direction * 1.2), 0.0, STRAIGHT_TOL_M, label + ": apoio da frente do cavalo a +1,2 m")
		assert_almost_eq(_support(poses, spec, 0, true).distance_to(direction * -1.2), 0.0, STRAIGHT_TOL_M, label + ": apoio de trás do cavalo a -1,2 m")
		assert_almost_eq(_support(poses, spec, 0, false).distance_to(_support(poses, spec, 0, true)), 2.4, STRAIGHT_TOL_M, label + ": apoios do cavalo a 2,4 m")
		assert_almost_eq(hitch.distance_to(direction * -1.976), 0.0, STRAIGHT_TOL_M, label + ": o engate é um ponto do corpo do cavalo, 1,976 m atrás da origem do líder")
		assert_almost_eq(_support(poses, spec, 1, false).distance_to(hitch), 2.807, STRAIGHT_TOL_M, label + ": timão de 2,807 m")
		assert_almost_eq(_support(poses, spec, 1, false).distance_to(direction * -4.783), 0.0, STRAIGHT_TOL_M, label + ": eixo da frente da carroça em -4,783 m")
		assert_almost_eq(_support(poses, spec, 1, false).distance_to(_support(poses, spec, 1, true)), 2.46, STRAIGHT_TOL_M, label + ": entre-eixos de 2,46 m")
		assert_almost_eq(_support(poses, spec, 1, true).distance_to(direction * -7.243), 0.0, STRAIGHT_TOL_M, label + ": eixo de trás em -7,243 m")
		assert_almost_eq(CaravanChain.articulation_rad(poses[0], poses[1]), 0.0, 1e-5, label + ": na reta os dois corpos têm o mesmo giro (o Vector2 de 32 bits limita a conta)")
		assert_almost_eq(poses[0].at_lead_frame(0.0, 1.0).distance_to(Vector2(-direction.y, direction.x)), 0.0, STRAIGHT_TOL_M, label + ": lateral positiva = à DIREITA da marcha")
		assert_almost_eq(absf(angle_difference(poses[1].yaw(), atan2(-direction.x, -direction.y))), 0.0, 1e-5, label + ": o giro da carroça é o do jogo, atan2(-x, -z)")


func test_wagon_supports_stay_on_the_lane_and_the_hitch_is_exact_through_a_corner() -> void:
	var spec: CaravanChain.Spec = CaravanChain.wagon_spec()
	var setups: Array[Vector3] = [Vector3(40.0, 0.0, 0.0), Vector3(40.0, LANE, 0.0), Vector3(14.0, LANE, RAMP)]
	for setup: Vector3 in setups:
		var road: CaravanRoad = CaravanChainProbe.corner_road(90.0, setup.x, 60.0, 8.0, setup.y, setup.z)
		var arc_start: float = setup.x - 8.0
		for k: int in 25:
			var s: float = arc_start - 10.0 + (12.57 + 20.0) * float(k) / 24.0
			var poses: Array[CaravanChain.RigidPose] = _poses(road, spec, s)
			var label: String = "faixa %.1f rampa %.0f, s %.1f" % [setup.y, setup.z, s]
			for body: int in 2:
				var shape: CaravanChain.Body = spec.bodies[body]
				for z_m: float in [shape.ref_front_m, shape.ref_rear_m]:
					var support: Vector2 = poses[body].at_lead_frame(z_m)
					assert_lt(CaravanChainProbe.lane_distance(road, support, s + z_m, 3.0), TOL_M, "%s: apoio z %.3f SOBRE a faixa" % [label, z_m])
				assert_almost_eq(_support(poses, spec, body, false).distance_to(_support(poses, spec, body, true)), shape.ref_front_m - shape.ref_rear_m, TOL_M, label + ": corpo rígido")
			var hitch: Vector2 = poses[0].at_lead_frame(spec.bodies[1].hitch_m)
			assert_almost_eq(_support(poses, spec, 1, false).distance_to(hitch), CaravanChain.WAGON_TONGUE_M, TOL_M, label + ": engate exato (timão 2,807 m)")


func test_two_support_bodies_match_the_circle_oracle_for_radii_6_8_and_10() -> void:
	var specs: Array[CaravanChain.Spec] = [CaravanChain.cart_spec(), CaravanChain.wagon_spec()]
	var chords: PackedFloat64Array = [CART_CHORD_M, HORSE_CHORD_M]
	for radius: float in RADII:
		var circle: Circle = Circle.new(90.0, 100.0, radius)
		var road: CaravanRoad = CaravanChainProbe.corner_road(90.0, 100.0, 100.0, radius, 0.0, 0.0)
		for front_arc: float in [3.5, 6.0]:
			for index: int in 2:
				var spec: CaravanChain.Spec = specs[index]
				var poses: Array[CaravanChain.RigidPose] = _poses(road, spec, circle.start_s + front_arc - spec.bodies[0].ref_front_m)
				var rear_arc: float = circle.rear_of(front_arc, chords[index])
				var label: String = "R %.0f, corpo de corda %.1f, apoio da frente a %.1f m do arco" % [radius, chords[index], front_arc]
				assert_almost_eq(poses[0].mid.distance_to(0.5 * (circle.point(front_arc) + circle.point(rear_arc))), 0.0, TOL_M, label + ": ponto médio")
				assert_almost_eq(poses[0].dir.distance_to(circle.heading(front_arc, rear_arc)), 0.0, TOL_M, label + ": o giro é a tangente no ângulo médio dos apoios")
				assert_almost_eq(absf(angle_difference(poses[0].yaw(), atan2(-circle.heading(front_arc, rear_arc).x, -circle.heading(front_arc, rear_arc).y))), 0.0, TOL_M, label + ": o giro do jogo é atan2(-x, -z) da tangente")


func test_wagon_chain_matches_the_circle_oracle_and_the_dense_scan_of_the_hitch() -> void:
	var spec: CaravanChain.Spec = CaravanChain.wagon_spec()
	for radius: float in RADII:
		var circle: Circle = Circle.new(130.0, 100.0, radius)
		var road: CaravanRoad = CaravanChainProbe.corner_road(130.0, 100.0, 100.0, radius, 0.0, 0.0)
		var front_arc: float = circle.arc_m - 0.5
		var poses: Array[CaravanChain.RigidPose] = _poses(road, spec, circle.start_s + front_arc - CaravanChain.HORSE_SUPPORT_M)
		var rear_arc: float = circle.rear_of(front_arc, HORSE_CHORD_M)
		var horse_mid: Vector2 = 0.5 * (circle.point(front_arc) + circle.point(rear_arc))
		var horse_dir: Vector2 = circle.heading(front_arc, rear_arc)
		var hitch: Vector2 = horse_mid + horse_dir * CaravanChain.HITCH_Z_M
		var wagon_front_arc: float = _dense_scan_behind(circle, hitch, CaravanChain.WAGON_TONGUE_M, rear_arc)
		var wagon_rear_arc: float = circle.rear_of(wagon_front_arc, CaravanChain.WAGON_WHEELBASE_M)
		var wagon_dir: Vector2 = circle.heading(wagon_front_arc, wagon_rear_arc)
		var label: String = "R %.0f" % radius
		assert_gt(wagon_rear_arc, 0.0, label + ": a carroça inteira cabe no arco do oráculo")
		assert_almost_eq(poses[0].mid.distance_to(horse_mid), 0.0, TOL_M, label + ": cavalo, ponto médio")
		assert_almost_eq(_support(poses, spec, 1, false).distance_to(circle.point(wagon_front_arc)), 0.0, 2e-5, label + ": eixo da frente da carroça = o ponto achado pela varredura densa")
		assert_almost_eq(_support(poses, spec, 1, true).distance_to(circle.point(wagon_rear_arc)), 0.0, 2e-5, label + ": eixo de trás da carroça")
		assert_almost_eq(poses[1].dir.distance_to(wagon_dir), 0.0, 2e-5, label + ": giro da carroça = tangente no ângulo médio dos eixos")
		assert_almost_eq(_support(poses, spec, 1, false).distance_to(poses[0].at_lead_frame(CaravanChain.HITCH_Z_M)), CaravanChain.WAGON_TONGUE_M, TOL_M, label + ": engate exato")
		assert_almost_eq(CaravanChain.articulation_rad(poses[0], poses[1]), absf(0.5 * (front_arc + rear_arc) - 0.5 * (wagon_front_arc + wagon_rear_arc)) / radius, 2e-5, label + ": articulação = a diferença dos ângulos médios")


func test_poses_depend_only_on_s_in_any_order_and_by_any_path() -> void:
	var road: CaravanRoad = CaravanChainProbe.corner_road(90.0, 60.0, 60.0, 8.0, LANE, RAMP)
	var twin: CaravanRoad = CaravanChainProbe.corner_road(90.0, 60.0, 60.0, 8.0, LANE, RAMP)
	var specs: Array[CaravanChain.Spec] = [CaravanChain.cart_spec(), CaravanChain.wagon_spec(true)]
	for spec: CaravanChain.Spec in specs:
		var fresh: Array[CaravanChain.RigidPose] = _poses(road, spec, 63.7)
		var dirty: Array[CaravanChain.RigidPose] = CaravanChain.make_poses(spec)
		for k: int in 150:
			CaravanChain.poses_into(road, spec, CaravanChainProbe.SPEED_MPS * CaravanChainProbe.FRAME_S * float(k), dirty)
		for k: int in range(30, -1, -1):
			CaravanChain.poses_into(road, spec, CaravanChainProbe.SPEED_MPS * float(k), dirty)
		CaravanChain.poses_into(road, spec, 63.7, dirty)
		var other: Array[CaravanChain.RigidPose] = _poses(twin, spec, 63.7)
		for i: int in fresh.size():
			assert_eq(dirty[i].mid, fresh[i].mid, "corpo %d: o ponto médio não depende do caminho até s" % i)
			assert_eq(dirty[i].dir, fresh[i].dir, "corpo %d: o giro não depende do caminho até s" % i)
			assert_eq(other[i].mid, fresh[i].mid, "corpo %d: a mesma estrada construída de novo dá a mesma pose" % i)
		var ascending: Dictionary[float, Vector2] = {}
		for k: int in 20:
			ascending[float(k) * 3.1] = _poses(road, spec, float(k) * 3.1)[fresh.size() - 1].mid
		for k: int in range(19, -1, -1):
			assert_eq(_poses(road, spec, float(k) * 3.1)[fresh.size() - 1].mid, ascending[float(k) * 3.1], "s %.1f: a mesma pose em ordem inversa" % (float(k) * 3.1))


func test_bad_inputs_give_finite_neutral_poses_and_never_loop_forever() -> void:
	var wagon: CaravanChain.Spec = CaravanChain.wagon_spec(true)
	var unusable: Array[CaravanRoad] = [CaravanRoad.through(PackedVector2Array(), 6.0), null]
	for broken: CaravanRoad in unusable:
		var poses: Array[CaravanChain.RigidPose] = _poses(broken, wagon, 5.0)
		for i: int in poses.size():
			assert_true(poses[i].mid.is_finite() and poses[i].dir.is_finite(), "estrada vazia: pose %d finita" % i)
			assert_almost_eq(poses[i].yaw(), 0.0, 1e-9, "estrada vazia: giro neutro")
			assert_almost_eq(poses[i].origin().length(), 0.0, 1e-9, "estrada vazia: origem neutra em (0, 0)")
	var road: CaravanRoad = CaravanChainProbe.corner_road(90.0, 40.0, 60.0, 8.0, LANE, RAMP)
	var at_zero: Array[CaravanChain.RigidPose] = _poses(road, wagon, 0.0)
	for bad: float in [NAN, INF, -INF]:
		var poses: Array[CaravanChain.RigidPose] = _poses(road, wagon, bad)
		for i: int in poses.size():
			assert_true(poses[i].mid.is_finite() and poses[i].dir.is_finite(), "s não finito: pose %d finita" % i)
			assert_eq(poses[i].mid, at_zero[i].mid, "s não finito conta como 0 (como na CaravanRoad)")
			assert_eq(poses[i].dir, at_zero[i].dir, "s não finito conta como 0: o giro")
	var no_body: CaravanChain.Spec = CaravanChain.Spec.new()
	var none: Array[CaravanChain.RigidPose] = CaravanChain.make_poses(no_body)
	CaravanChain.poses_into(road, no_body, 5.0, none)
	assert_eq(none.size(), 0, "veículo sem corpo: nenhuma pose")
	assert_eq(CaravanChain.make_poses(null).size(), 0, "veículo nulo: nenhuma pose")
	assert_eq(CaravanChain.max_axis_offset_m(road, no_body, 0.0, 10.0, 0.5), 0.0, "veículo sem corpo: nenhum afastamento")
	assert_eq(CaravanChain.max_axis_offset_m(road, wagon, 0.0, NAN, 0.5), 0.0, "alcance não finito: 0")
	assert_gt(CaravanChain.max_axis_offset_m(road, CaravanChain.cart_spec(), 0.0, 2.0, 0.0), 0.0, "passo 0 vira o passo mínimo e termina")
	var sharp: CaravanRoad = CaravanChainProbe.corner_road(90.0, 40.0, 60.0, 0.0, 0.0, 0.0)
	var cart: CaravanChain.Spec = CaravanChain.cart_spec()
	for k: int in 41:
		var s: float = 30.0 + float(k) * 0.5
		var poses: Array[CaravanChain.RigidPose] = _poses(sharp, cart, s)
		assert_true(poses[0].mid.is_finite() and is_equal_approx(poses[0].dir.length(), 1.0), "raio 0 (quina viva, o hoje): pose finita e giro unitário em s %.1f" % s)
		assert_lt(CaravanChainProbe.lane_distance(sharp, _support(poses, cart, 0, true), s - CART_CHORD_M, 1.0), TOL_M, "raio 0: o eixo do carrinho está SOBRE a polilinha")
	var walked: CaravanChainProbe.Walk = CaravanChainProbe.walk(sharp, null, wagon, 0.0, 20.0, 70.0, 0.05)
	assert_true(walked.finite, "raio 0: o veículo comprido atravessa a quina viva sem valor não finito")


func test_articulation_swept_corners_and_axis_offset_helpers() -> void:
	var a: CaravanChain.RigidPose = CaravanChain.RigidPose.new()
	var b: CaravanChain.RigidPose = CaravanChain.RigidPose.new()
	b.dir = Vector2.RIGHT
	assert_almost_eq(CaravanChain.articulation_rad(a, b), PI * 0.5, 1e-9, "dois giros perpendiculares: 90 graus")
	b.dir = Vector2.DOWN
	assert_almost_eq(CaravanChain.articulation_rad(a, b), PI, 1e-9, "giros opostos: 180 graus (PI)")
	assert_almost_eq(CaravanChain.articulation_rad(a, a), 0.0, 1e-9, "o mesmo giro: 0")
	var straight: CaravanRoad = CaravanChainProbe.line_road(Vector2.RIGHT, 300.0, 0.0, 0.0)
	var cart: CaravanChain.Spec = CaravanChain.cart_spec()
	var corners: PackedVector2Array = PackedVector2Array()
	CaravanChain.swept_corners(cart, _poses(straight, cart, 100.0), corners)
	var half: float = CaravanView.WHEEL_SIDE_M + CaravanView.WHEEL_THICKNESS_M * 0.5
	var back: float = -CaravanView.CART_BACK_M - CaravanView.BED_SIZE_M.z * 0.5
	assert_eq(corners.size(), 4, "uma caixa, quatro cantos")
	assert_almost_eq(corners[0].distance_to(Vector2(back, -half)), 0.0, TOL_M, "canto de trás, à esquerda")
	assert_almost_eq(corners[1].distance_to(Vector2(back, half)), 0.0, TOL_M, "canto de trás, à direita (+Z é a direita de quem anda para +X)")
	assert_almost_eq(corners[2].distance_to(Vector2(0.3, half)), 0.0, TOL_M, "canto da frente, à direita")
	for lane_m: float in LANES:
		var lane_road: CaravanRoad = CaravanChainProbe.line_road(Vector2.RIGHT, 300.0, lane_m, 0.0)
		assert_almost_eq(CaravanChain.max_axis_offset_m(lane_road, cart, 40.0, 60.0, 1.0), lane_m + half, TOL_M, "carrinho: afastamento = faixa + meia-largura")
		var wagon_half: float = CaravanChain.WAGON_HALF_WIDTH_M
		assert_almost_eq(CaravanChain.max_axis_offset_m(lane_road, CaravanChain.wagon_spec(), 40.0, 60.0, 1.0), lane_m + wagon_half, TOL_M, "veículo comprido: faixa + 1,005 m")


func test_front_extent_is_the_largest_front_support_and_never_negative() -> void:
	assert_almost_eq(CaravanChain.front_extent_m(CaravanChain.cart_spec()), 0.0, 1e-12, "carrinho: o comerciante está na origem do líder")
	assert_almost_eq(CaravanChain.front_extent_m(CaravanChain.wagon_spec()), CaravanChain.HORSE_SUPPORT_M, 1e-12, "veículo comprido: o apoio da frente do cavalo, 1,2 m")
	assert_almost_eq(CaravanChain.front_extent_m(CaravanChain.wagon_spec_with(6.0, 4.0, true)), 1.2, 1e-12, "outro entre-eixos e timão: o cavalo não muda")
	var behind: CaravanChain.Spec = CaravanChain.Spec.new()
	var body: CaravanChain.Body = CaravanChain.Body.new()
	body.ref_front_m = -3.0
	body.ref_rear_m = -5.0
	behind.bodies.append(body)
	assert_eq(CaravanChain.front_extent_m(behind), 0.0, "todos os apoios atrás da origem: 0, nunca negativo")
	var other: CaravanChain.Body = CaravanChain.Body.new()
	other.ref_front_m = NAN
	behind.bodies.append(other)
	assert_eq(CaravanChain.front_extent_m(behind), 0.0, "apoio não finito é ignorado")
	assert_eq(CaravanChain.front_extent_m(CaravanChain.Spec.new()), 0.0, "veículo sem corpo: 0")
	assert_eq(CaravanChain.front_extent_m(null), 0.0, "veículo nulo: 0")
