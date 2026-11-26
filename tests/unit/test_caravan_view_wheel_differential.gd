extends GutTest
## LW-099f (curvas naturais, EXPERIMENTAL): o modo RODAS POR RODA do `CaravanView` (`set_wheel_differential`), sem janela, ponte nem simulação. Desligado (o padrão) o corpo é o de sempre: as duas rodas giram
## juntas, a distância da origem ÷ raio. Ligado, cada roda gira pelo deslocamento do PRÓPRIO centro, projetado na frente do corpo na pose média: em reta as duas dão o que o desligado dá; em curva a de fora
## gira mais que a de dentro (conferido contra um ORÁCULO independente, a 1 mm, sobre o mesmo arco analítico); nada rola com a origem parada, sem pose anterior, com a caravana parada ou com entrada ruim;
## `release` e `bind` zeram as rodas; ligar ou desligar o modo no meio da viagem não dá salto; a pisada é a de sempre e o caminho quente não cria objeto.

const EPS: float = 0.0001
## "Igual" entre as duas rodas e entre os dois modos (rad).
const SAME_RAD: float = 0.00001
## Perto da origem de propósito: com coordenadas pequenas o float de 32 bits da Godot erra menos de 1e-5 m por posição (como em `test_caravan_view_motion.gd`).
const GROUND: Vector3 = Vector3(20.0, 10.0, 40.0)
const START_YAW: float = 0.7
const CODE: String = "res://src/presentation/world_view/entities/caravan_view.gd"
const HOT_PATHS: PackedStringArray = ["apply_pose", "_roll", "_roll_by_wheel", "_turn_wheel"]

## Os arcos: 10 m de comprimento (20 poses de 0,5 m ou 200 de 0,05 m), nos três raios e nas duas mãos (1 = esquerda, o giro cresce); o oráculo anda o mesmo arco de milímetro em milímetro.
const ARC_M: float = 10.0
const FINE_M: float = 0.001
const RADII_M: PackedFloat64Array = [4.0, 6.0, 10.0]
const TURNS: PackedFloat64Array = [1.0, -1.0]
const STEPS_M: PackedFloat64Array = [0.5, 0.05]
## Erro relativo aceito contra o oráculo, na ordem de STEPS_M: a razão fora/dentro (2% nos passos de 0,5 m, como pedido) e o quanto cada roda rolou (1% e 0,2%); o espelho, 0,05%.
const RATIO_TOLERANCE: PackedFloat64Array = [0.02, 0.002]
const ROLLED_TOLERANCE: PackedFloat64Array = [0.01, 0.002]
const MIRROR_TOLERANCE: float = 0.0005

## Retas: giros e inclinações constantes (a reta anda pela frente do corpo, com a subida junto) e os passos andados em cada uma.
const LINE_YAWS: PackedFloat64Array = [0.0, 1.0, -2.4, 0.7, -2.0]
const LINE_PITCHES: PackedFloat64Array = [0.0, 0.0, 0.0, 0.3, -0.2]
const LINE_STEPS_M: PackedFloat64Array = [0.05, 0.3, 1.2, 0.004, 2.5, 0.7]
## Uma caminhada mista (deslocamento a partir de GROUND, giro, inclinação): reta, giro parado no lugar, subida, a mesma pose de novo, salto grande e volta pelo ±PI.
const MIXED_WALK: Array = [
	[Vector3(0.0, 0.0, -0.4), 0.0, 0.0],
	[Vector3(0.0, 0.0, -1.9), 0.0, 0.0],
	[Vector3(0.0, 0.0, -1.9), 1.2, 0.0],
	[Vector3(0.5, 0.2, -2.3), 1.0, 0.1],
	[Vector3(1.3, 0.2, -2.9), 0.4, -0.2],
	[Vector3(1.3, 0.2, -2.9), 0.4, -0.2],
	[Vector3(-4.0, 1.0, -2.0), -3.0, 0.3],
	[Vector3(-4.2, 1.0, -2.1), 3.0, 0.0],
]

var _routes: CaravanRoutesReader
## O que cada roda rolou (m, [esquerda, direita]) em cada arco ("raio|mão|passo") e o que o oráculo diz de cada arco ("raio|mão|0").
var _rolled: Dictionary[String, PackedFloat64Array] = {}
var _oracle: Dictionary[String, PackedFloat64Array] = {}


func before_all() -> void:
	var loaded: CaravanRoutesReader.LoadResult = CaravanRoutesReader.from_file()
	assert_true(loaded.result.ok, loaded.result.message)
	_routes = loaded.data
	for radius: float in RADII_M:
		for turn: float in TURNS:
			_oracle[_key(radius, turn, 0.0)] = PackedFloat64Array([_oracle_rolled(-1.0, turn, radius), _oracle_rolled(1.0, turn, radius)])
			for step_m: float in STEPS_M:
				var view: CaravanView = CaravanView.new(_routes)
				view.bind(7)
				view.apply_state(true, "grain", 500)
				view.set_wheel_differential(true)
				_rolled[_key(radius, turn, step_m)] = _rolled_along_arc(view, turn, radius, step_m)
				view.free()


func _key(radius: float, turn: float, step_m: float) -> String:
	return "%s|%s|%s" % [radius, turn, step_m]


func _new_view() -> CaravanView:
	var view: CaravanView = CaravanView.new(_routes)
	add_child_autofree(view)
	return view


## Um corpo ligado e andando, com carga, no modo pedido; ainda sem pose.
func _bound_view(differential: bool) -> CaravanView:
	var view: CaravanView = _new_view()
	view.bind(7)
	view.apply_state(true, "grain", 500)
	view.set_wheel_differential(differential)
	return view


func _wheels(view: CaravanView) -> Array[Node3D]:
	var wheels: Array[Node3D] = []
	for wheel_name: String in CaravanView.WHEEL_NAMES:
		wheels.append(view.get_node(NodePath("%s/%s" % [CaravanView.CART_NAME, wheel_name])) as Node3D)
	return wheels


func _angles(view: CaravanView) -> PackedFloat64Array:
	var wheels: Array[Node3D] = _wheels(view)
	return PackedFloat64Array([wheels[0].rotation.x, wheels[1].rotation.x])


## O que a animação mexe: o quique do comerciante (posição e giro do visual) e o giro de cada roda.
func _animated_state(view: CaravanView) -> Array:
	var visual: Node3D = view.merchant().get_node(NodePath(NpcView.VISUAL_NAME)) as Node3D
	var state: Array = [visual.position, visual.rotation]
	for wheel: Node3D in _wheels(view):
		state.append(wheel.rotation)
	return state


## A frente (-Z local) de um corpo com giro `yaw` e inclinação `pitch` (ordem Y depois X, a do nó), escrita à mão, sem `Basis`.
func _front(yaw: float, pitch: float) -> Vector3:
	return Vector3(-sin(yaw) * cos(pitch), sin(pitch), -cos(yaw) * cos(pitch))


## O arco que parte de GROUND com o giro START_YAW: o giro do corpo é a tangente do arco (cresce à esquerda, `turn` 1; diminui à direita, -1) e a origem anda `along_m` por ele.
func _arc_yaw(turn: float, radius: float, along_m: float) -> float:
	return START_YAW + turn * along_m / radius


func _arc_origin(turn: float, radius: float, along_m: float) -> Vector3:
	var yaw: float = _arc_yaw(turn, radius, along_m)
	return GROUND + Vector3(cos(yaw) - cos(START_YAW), 0.0, sin(START_YAW) - sin(yaw)) * (turn * radius)


## Aplica as poses do arco de `step_m` em `step_m` e devolve quanto cada roda rolou, em metros (o ângulo é desenrolado a cada pose; o raio da roda o leva a distância).
func _rolled_along_arc(view: CaravanView, turn: float, radius: float, step_m: float) -> PackedFloat64Array:
	var rolled: PackedFloat64Array = PackedFloat64Array([0.0, 0.0])
	view.apply_pose(GROUND, START_YAW, 0.0)
	var previous: PackedFloat64Array = _angles(view)
	for step: int in range(1, roundi(ARC_M / step_m) + 1):
		var along_m: float = float(step) * step_m
		view.apply_pose(_arc_origin(turn, radius, along_m), _arc_yaw(turn, radius, along_m), 0.0)
		var now: PackedFloat64Array = _angles(view)
		for index: int in 2:
			rolled[index] -= angle_difference(previous[index], now[index]) * CaravanView.WHEEL_RADIUS_M
		previous = now
	return rolled


## ORÁCULO independente (nada do `CaravanView`), tudo em double: o centro (x, z) da roda de lado `side` (-1 esquerda, 1 direita) depois de andar `along_m` pelo arco: a origem analítica mais o deslocamento local da roda girado pelo giro do arco.
func _oracle_centre(side: float, turn: float, radius: float, along_m: float) -> PackedFloat64Array:
	var yaw: float = _arc_yaw(turn, radius, along_m)
	var local_x: float = side * CaravanView.WHEEL_SIDE_M
	var back_m: float = CaravanView.CART_BACK_M
	var origin_x: float = turn * radius * (cos(yaw) - cos(START_YAW))
	var origin_z: float = turn * radius * (sin(START_YAW) - sin(yaw))
	return PackedFloat64Array([origin_x + local_x * cos(yaw) + back_m * sin(yaw), origin_z - local_x * sin(yaw) + back_m * cos(yaw)])


## O que o centro da roda andou NA FRENTE do corpo, integrado a 1 mm: o deslocamento de cada milímetro projetado na frente do meio desse milímetro.
func _oracle_rolled(side: float, turn: float, radius: float) -> float:
	var total_m: float = 0.0
	var before: PackedFloat64Array = _oracle_centre(side, turn, radius, 0.0)
	for step: int in range(1, roundi(ARC_M / FINE_M) + 1):
		var after: PackedFloat64Array = _oracle_centre(side, turn, radius, float(step) * FINE_M)
		var heading: float = _arc_yaw(turn, radius, (float(step) - 0.5) * FINE_M)
		total_m -= (after[0] - before[0]) * sin(heading) + (after[1] - before[1]) * cos(heading)
		before = after
	return total_m


func test_the_mode_is_off_by_default_and_off_the_wheels_keep_todays_single_angle_to_the_bit() -> void:
	var view: CaravanView = _new_view()
	assert_false(view.wheel_differential(), "um corpo novo nasce com o modo desligado")
	view.bind(7)
	view.apply_state(true, "grain", 500)
	assert_false(view.wheel_differential(), "e o `bind` não o liga")
	view.apply_pose(GROUND, 0.0, 0.0)
	var angle: float = 0.0
	var previous: Vector3 = GROUND
	for entry: Array in MIXED_WALK:
		var offset: Vector3 = entry[0]
		var yaw: float = entry[1]
		var pitch: float = entry[2]
		var here: Vector3 = GROUND + offset
		view.apply_pose(here, yaw, pitch)
		var walked_m: float = previous.distance_to(here)
		if walked_m > 0.0:
			# A conta única de sempre: o ângulo diminui distância ÷ raio, dentro de uma volta; giro e inclinação não entram.
			angle = fposmod(angle - walked_m / CaravanView.WHEEL_RADIUS_M, TAU)
		previous = here
		for wheel: Node3D in _wheels(view):
			assert_eq(wheel.rotation.x, Vector3(angle, 0.0, 0.0).x, "pose %s: o ângulo é o da conta única, bit a bit" % here)
	assert_ne(angle, 0.0, "o teste só vale se as rodas giraram")


func test_on_a_straight_line_both_wheels_roll_the_same_as_the_mode_off_with_or_without_pitch() -> void:
	for kind: int in LINE_YAWS.size():
		var yaw: float = LINE_YAWS[kind]
		var pitch: float = LINE_PITCHES[kind]
		var front: Vector3 = _front(yaw, pitch)
		var off: CaravanView = _bound_view(false)
		var on: CaravanView = _bound_view(true)
		off.apply_pose(GROUND, yaw, pitch)
		on.apply_pose(GROUND, yaw, pitch)
		var along_m: float = 0.0
		for step_m: float in LINE_STEPS_M:
			along_m += step_m
			off.apply_pose(GROUND + front * along_m, yaw, pitch)
			on.apply_pose(GROUND + front * along_m, yaw, pitch)
			var label: String = "giro %s, inclinação %s, %s m andados" % [yaw, pitch, along_m]
			var wheels_on: PackedFloat64Array = _angles(on)
			var wheels_off: PackedFloat64Array = _angles(off)
			assert_almost_eq(angle_difference(wheels_on[0], wheels_on[1]), 0.0, SAME_RAD, "%s: as duas rodas iguais entre si" % label)
			for index: int in 2:
				assert_almost_eq(angle_difference(wheels_on[index], wheels_off[index]), 0.0, SAME_RAD, "%s: roda %d igual à do modo desligado" % [label, index])
		assert_ne(_angles(on)[0], 0.0, "o caso só vale se as rodas giraram")


func test_in_a_curve_the_outer_wheel_rolls_more_and_the_mirror_swaps_the_sides() -> void:
	for radius: float in RADII_M:
		for step_m: float in STEPS_M:
			var left_turn: PackedFloat64Array = _rolled[_key(radius, 1.0, step_m)]
			var right_turn: PackedFloat64Array = _rolled[_key(radius, -1.0, step_m)]
			var label: String = "raio %s m, passo %s m" % [radius, step_m]
			assert_gt(left_turn[1], left_turn[0], "%s, curva à esquerda: a roda de fora (a direita) rola mais" % label)
			assert_gt(right_turn[0], right_turn[1], "%s, curva à direita: a roda de fora (a esquerda) rola mais" % label)
			assert_almost_eq(left_turn[1], right_turn[0], left_turn[1] * MIRROR_TOLERANCE, "%s: no espelho a roda de fora é a mesma, do outro lado" % label)
			assert_almost_eq(left_turn[0], right_turn[1], left_turn[0] * MIRROR_TOLERANCE, "%s: e a de dentro também" % label)


func test_the_outer_to_inner_ratio_matches_the_fine_oracle() -> void:
	var worst: PackedFloat64Array = PackedFloat64Array([0.0, 0.0])
	for radius: float in RADII_M:
		for turn: float in TURNS:
			var oracle: PackedFloat64Array = _oracle[_key(radius, turn, 0.0)]
			var outer: int = 1 if turn > 0.0 else 0
			var oracle_ratio: float = oracle[outer] / oracle[1 - outer]
			assert_gt(oracle_ratio, 1.05, "raio %s m, mão %s: o caso discrimina (o oráculo vê a diferença entre as rodas)" % [radius, turn])
			for size_index: int in STEPS_M.size():
				var rolled: PackedFloat64Array = _rolled[_key(radius, turn, STEPS_M[size_index])]
				var gap: float = absf(rolled[outer] / rolled[1 - outer] / oracle_ratio - 1.0)
				worst[size_index] = maxf(worst[size_index], gap)
				assert_lt(gap, RATIO_TOLERANCE[size_index], "raio %s m, mão %s, passo %s m: razão fora/dentro contra o oráculo" % [radius, turn, STEPS_M[size_index]])
	print("LW-099f rodas por roda: erro relativo máximo da razão fora/dentro contra o oráculo de 1 mm: %.9f (passo 0,5 m), %.9f (passo 0,05 m)" % [worst[0], worst[1]])


func test_each_wheel_rolls_the_distance_the_fine_oracle_says() -> void:
	var worst: PackedFloat64Array = PackedFloat64Array([0.0, 0.0])
	for radius: float in RADII_M:
		for turn: float in TURNS:
			var oracle: PackedFloat64Array = _oracle[_key(radius, turn, 0.0)]
			for size_index: int in STEPS_M.size():
				var rolled: PackedFloat64Array = _rolled[_key(radius, turn, STEPS_M[size_index])]
				for index: int in 2:
					var gap: float = absf(rolled[index] / oracle[index] - 1.0)
					worst[size_index] = maxf(worst[size_index], gap)
					assert_lt(gap, ROLLED_TOLERANCE[size_index], "raio %s m, mão %s, passo %s m, roda %d: o que rolou contra o oráculo" % [radius, turn, STEPS_M[size_index], index])
	print("LW-099f rodas por roda: erro relativo máximo do que cada roda rolou contra o oráculo de 1 mm: %.9f (passo 0,5 m), %.9f (passo 0,05 m)" % [worst[0], worst[1]])


func test_the_fine_oracle_agrees_with_the_closed_form_so_it_can_be_trusted() -> void:
	for radius: float in RADII_M:
		for turn: float in TURNS:
			var oracle: PackedFloat64Array = _oracle[_key(radius, turn, 0.0)]
			for index: int in 2:
				var closed_m: float = ARC_M * (1.0 + turn * CaravanView.SIDES[index] * CaravanView.WHEEL_SIDE_M / radius)
				assert_almost_eq(oracle[index], closed_m, ARC_M * 0.00001, "raio %s m, mão %s, roda %d: o oráculo é o arco vezes (1 ± lado ÷ raio)" % [radius, turn, index])


func test_nothing_rolls_when_standing_without_a_previous_pose_when_stopped_or_when_only_the_heading_changes() -> void:
	var view: CaravanView = _bound_view(true)
	view.apply_pose(GROUND, 1.0, 0.2)
	var rest: Array = _animated_state(view)
	assert_eq(_angles(view), PackedFloat64Array([0.0, 0.0]), "sem pose anterior (a primeira depois do `bind`): nada gira")
	view.apply_pose(GROUND, 1.0, 0.2)
	assert_eq(_animated_state(view), rest, "parado (a mesma pose de novo): nada rola nem pisa")
	view.apply_pose(GROUND, -2.0, -0.3)
	view.apply_pose(GROUND, 2.9, 0.4)
	assert_eq(_animated_state(view), rest, "a origem no mesmo lugar, só o giro e a inclinação mudam: o corpo não rola parado em cima do chão")
	view.apply_pose(GROUND + Vector3(0.0, 0.0, -1.0), 2.9, 0.4)
	assert_ne(_animated_state(view), rest, "controle: andando de verdade, rola e pisa")
	view.apply_state(false, "grain", 500)
	var stopped: Array = _animated_state(view)
	var stopped_angles: PackedFloat64Array = _angles(view)
	view.apply_pose(GROUND + Vector3(3.0, 0.0, -4.0), -1.0, 0.0)
	assert_eq(_animated_state(view), stopped, "a caravana parada (`apply_state(false)`) não gira roda nem pisa, mesmo que a pose mude")
	view.apply_state(true, "grain", 500)
	view.apply_pose(GROUND + Vector3(3.0, 0.0, -6.0), -1.0, 0.0)
	assert_ne(_angles(view), stopped_angles, "voltou a andar: gira de novo")


func test_release_and_rebind_leave_the_wheels_at_zero_and_keep_the_switch() -> void:
	var view: CaravanView = _bound_view(true)
	var wheels: Array[Node3D] = _wheels(view)
	_rolled_along_arc(view, 1.0, 6.0, 0.5)
	assert_ne(wheels[0].rotation.x, wheels[1].rotation.x, "controle: depois de uma curva as duas rodas estão em ângulos diferentes")
	view.release()
	assert_eq([wheels[0].rotation, wheels[1].rotation], [Vector3.ZERO, Vector3.ZERO], "`release` zera o giro de cada roda")
	assert_true(view.wheel_differential(), "o interruptor é configuração do corpo: sobrevive ao `release`")
	view.bind(8)
	view.apply_state(true, "grain", 500)
	view.apply_pose(GROUND, START_YAW, 0.0)
	assert_eq([wheels[0].rotation, wheels[1].rotation], [Vector3.ZERO, Vector3.ZERO], "o corpo reciclado não herda nada: a primeira pose não anima")
	var fresh: CaravanView = _bound_view(true)
	fresh.apply_pose(GROUND, START_YAW, 0.0)
	view.apply_pose(_arc_origin(1.0, 6.0, 1.0), _arc_yaw(1.0, 6.0, 1.0), 0.0)
	fresh.apply_pose(_arc_origin(1.0, 6.0, 1.0), _arc_yaw(1.0, 6.0, 1.0), 0.0)
	assert_eq(_angles(view), _angles(fresh), "a segunda pose do corpo reciclado dá o que dá a de um corpo novo: nenhum ângulo velho sobrou")
	var unposed: CaravanView = _new_view()
	unposed.set_wheel_differential(true)
	assert_true(unposed.wheel_differential(), "trocar o modo não precisa de pose, nem de `bind`")
	assert_eq(_angles(unposed), PackedFloat64Array([0.0, 0.0]), "e não gira nada")


func test_switching_the_mode_mid_trip_does_not_make_the_wheels_jump_in_either_direction() -> void:
	var view: CaravanView = _bound_view(false)
	var front: Vector3 = _front(START_YAW, 0.0)
	view.apply_pose(GROUND, START_YAW, 0.0)
	view.apply_pose(GROUND + front, START_YAW, 0.0)
	var before: PackedFloat64Array = _angles(view)
	assert_ne(before[0], 0.0, "controle: já rolou 1 m")
	view.set_wheel_differential(true)
	assert_eq(_angles(view), before, "ligar no meio da viagem não gira nada por si")
	view.apply_pose(GROUND + front * 1.5, START_YAW, 0.0)
	for index: int in 2:
		assert_almost_eq(angle_difference(_angles(view)[index], before[index] - 0.5 / CaravanView.WHEEL_RADIUS_M), 0.0, EPS, "roda %d: o próximo ângulo continua de onde estava" % index)
	# Desligar no meio de uma curva (as rodas em ângulos diferentes): cada uma segue do seu ângulo, as duas pelo mesmo passo.
	var curve: CaravanView = _bound_view(true)
	_rolled_along_arc(curve, 1.0, 6.0, 0.5)
	var apart: PackedFloat64Array = _angles(curve)
	assert_gt(absf(angle_difference(apart[0], apart[1])), 0.1, "controle: as rodas estão em ângulos bem diferentes")
	curve.set_wheel_differential(false)
	assert_eq(_angles(curve), apart, "desligar também não gira nada por si")
	var end_yaw: float = _arc_yaw(1.0, 6.0, ARC_M)
	curve.apply_pose(_arc_origin(1.0, 6.0, ARC_M) + _front(end_yaw, 0.0) * 0.5, end_yaw, 0.0)
	for index: int in 2:
		assert_almost_eq(angle_difference(_angles(curve)[index], apart[index] - 0.5 / CaravanView.WHEEL_RADIUS_M), 0.0, EPS, "roda %d: desligado, as duas rolam o mesmo passo a partir do ângulo de cada uma" % index)


func test_the_mean_heading_goes_through_the_wrap_at_pi_in_both_directions() -> void:
	var delta: float = 0.5 / 6.0
	for turn: float in TURNS:
		var wrapped: CaravanView = _bound_view(true)
		var unwrapped: CaravanView = _bound_view(true)
		var yaw_from: float = 3.1 * turn
		var yaw_to: float = yaw_from + turn * delta
		var origin_to: Vector3 = GROUND + Vector3(cos(yaw_to) - cos(yaw_from), 0.0, sin(yaw_from) - sin(yaw_to)) * (turn * 6.0)
		assert_ne(wrapf(yaw_to, -PI, PI), yaw_to, "controle: o giro de chegada atravessa o ±PI (o enrolado e o corrido são números diferentes)")
		for view: CaravanView in [wrapped, unwrapped]:
			view.apply_pose(GROUND, yaw_from, 0.0)
		wrapped.apply_pose(origin_to, wrapf(yaw_to, -PI, PI), 0.0)
		unwrapped.apply_pose(origin_to, yaw_to, 0.0)
		var outer: int = 1 if turn > 0.0 else 0
		for index: int in 2:
			var chord_m: float = 2.0 * (6.0 + (CaravanView.WHEEL_SIDE_M if index == outer else -CaravanView.WHEEL_SIDE_M)) * sin(delta * 0.5)
			var rolled_m: float = -angle_difference(0.0, _angles(wrapped)[index]) * CaravanView.WHEEL_RADIUS_M
			assert_almost_eq(rolled_m, chord_m, chord_m * 0.001, "mão %s, roda %d: com o giro enrolado, rola a corda do arco, para a frente" % [turn, index])
			assert_almost_eq(angle_difference(_angles(wrapped)[index], _angles(unwrapped)[index]), 0.0, SAME_RAD, "mão %s, roda %d: enrolado ou corrido, o mesmo" % [turn, index])


## Uma lombada e uma depressão (arco no plano vertical, raio 3 m, o giro fixo): o centro da roda fica a WHEEL_RADIUS_M do chão, então anda (raio ∓ 0,38) ÷ raio do que anda a origem; só dá certo com a inclinação média e o 3D.
func test_the_pitch_is_averaged_and_the_displacement_counts_in_3d_over_a_valley_and_a_crest() -> void:
	var radius: float = 3.0
	var delta: float = 0.5 / radius
	var heading: Vector3 = _front(START_YAW, 0.0)
	for turn: float in TURNS:
		var view: CaravanView = _bound_view(true)
		view.apply_pose(GROUND, START_YAW, 0.0)
		var previous: PackedFloat64Array = _angles(view)
		var rolled: PackedFloat64Array = PackedFloat64Array([0.0, 0.0])
		for step: int in range(1, 7):
			var pitch: float = turn * float(step) * delta
			view.apply_pose(GROUND + heading * (turn * radius * sin(pitch)) + Vector3.UP * (turn * radius * (1.0 - cos(pitch))), START_YAW, pitch)
			var now: PackedFloat64Array = _angles(view)
			for index: int in 2:
				rolled[index] -= angle_difference(previous[index], now[index]) * CaravanView.WHEEL_RADIUS_M
			previous = now
		var expected_m: float = 6.0 * 2.0 * (radius - turn * CaravanView.WHEEL_RADIUS_M) * sin(delta * 0.5)
		for index: int in 2:
			assert_almost_eq(rolled[index], expected_m, expected_m * 0.003, "%s: roda %d rola a corda do arco vertical" % ["depressão" if turn > 0.0 else "lombada", index])


func test_a_bad_pose_is_ignored_and_the_wheels_never_get_nan() -> void:
	var view: CaravanView = _bound_view(true)
	view.apply_pose(GROUND, 0.3, 0.1)
	view.apply_pose(GROUND + Vector3(0.0, 0.0, -1.0), 0.5, 0.1)
	var before: Array = _animated_state(view)
	var transform_before: Transform3D = view.transform
	view.apply_pose(Vector3(NAN, 0.0, 0.0), 0.5, 0.1)
	view.apply_pose(Vector3(0.0, INF, 0.0), 0.5, 0.1)
	view.apply_pose(Vector3(0.0, 0.0, -INF), 0.5, 0.1)
	view.apply_pose(GROUND, INF, 0.1)
	view.apply_pose(GROUND, NAN, 0.1)
	view.apply_pose(GROUND, 0.5, NAN)
	view.apply_pose(GROUND, 0.5, -INF)
	assert_eq([_animated_state(view), view.transform], [before, transform_before], "entrada não finita (posição, giro ou inclinação) é ignorada: nada muda")
	view.apply_pose(GROUND + Vector3(0.0, 0.0, -2.0), 0.9, 0.0)
	for angle: float in _angles(view):
		assert_true(is_finite(angle), "e a pose boa que vem depois gira as rodas sem NaN")
	assert_ne(_animated_state(view), before, "controle: a pose boa foi aplicada")


func test_the_merchant_steps_alike_in_both_modes_by_the_distance_of_the_origin() -> void:
	var off: CaravanView = _bound_view(false)
	var on: CaravanView = _bound_view(true)
	_rolled_along_arc(off, 1.0, 6.0, 0.5)
	_rolled_along_arc(on, 1.0, 6.0, 0.5)
	var stride: Array = _animated_state(off).slice(0, 2)
	assert_ne(stride, [Vector3.ZERO, Vector3.ZERO], "o teste só vale se a pisada saiu do repouso")
	assert_eq(_animated_state(on).slice(0, 2), stride, "a pisada é a mesma nos dois modos: a distância da ORIGEM ÷ 4 m/s")


func test_the_hot_path_with_the_mode_on_retains_no_object_or_node() -> void:
	var view: CaravanView = _bound_view(true)
	view.apply_pose(GROUND, START_YAW, 0.0)
	var objects_before: int = int(Performance.get_monitor(Performance.OBJECT_COUNT))
	var nodes_before: int = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	for step: int in 600:
		var along_m: float = float(step + 1) * 0.05
		view.apply_pose(_arc_origin(1.0, 6.0, along_m), _arc_yaw(1.0, 6.0, along_m), 0.1)
	assert_eq(int(Performance.get_monitor(Performance.OBJECT_COUNT)), objects_before, "nenhum objeto ficou retido depois de 600 quadros com o modo ligado (alocação temporária: ver a varredura do texto)")
	assert_eq(int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)), nodes_before, "nenhum nó ficou retido")


## O corpo (sem comentários) de cada função de `names` que cria objeto ou coleção (a varredura de `test_caravan_view_motion.gd`, agora com o caminho novo): `.new(`, `Array(`, `Dictionary(`, `Packed...Array(`,
## `[` de construção e `{`. O corpo vai da linha `func` até as duas linhas em branco que separam as funções. Função não achada também conta como achado.
func _allocations_in(source: String, names: PackedStringArray) -> PackedStringArray:
	var found: PackedStringArray = PackedStringArray()
	var builds: RegEx = RegEx.create_from_string("\\.new\\(|\\b(Array|Dictionary|Packed\\w+Array)\\(|(=|\\(|,|%|return)\\s*\\[|\\{")
	var comment: RegEx = RegEx.create_from_string("#[^\\n]*")
	for function_name: String in names:
		var start: int = source.find("func %s(" % function_name)
		var end: int = source.find("\n\n\n", start)
		var hit: RegExMatch = null if start < 0 else builds.search(comment.sub(source.substr(start, end - start if end > start else -1), "", true))
		if start < 0 or hit != null:
			found.append("%s: %s" % [function_name, "função não achada" if start < 0 else hit.get_string()])
	return found


func test_the_text_of_the_hot_paths_with_the_new_mode_builds_no_object_or_collection_and_the_scan_can_fail() -> void:
	assert_eq(_allocations_in(FileAccess.get_file_as_string(CODE), HOT_PATHS), PackedStringArray(), "o texto dos caminhos quentes (o novo e o de sempre) não cria objeto nem coleção")
	for planted: String in ["var tmp: RefCounted = RefCounted.new()", "var tmp: Array[int] = [1]", "var tmp: Dictionary = {}", "var tmp: PackedFloat64Array = PackedFloat64Array()"]:
		assert_eq(_allocations_in("func _roll_by_wheel(a: int) -> void:\n\t%s\n\n\n" % planted, ["_roll_by_wheel"]).size(), 1, "a varredura pega: %s" % planted)
	assert_eq(_allocations_in("func _roll_by_wheel(a: int) -> void:\n\tvar b: Basis = Basis.from_euler(Vector3(a, 0.0, 0.0))  # Array() em comentário não conta\n\t_wheel_angles[a] = 0.0\n\n\n", ["_roll_by_wheel"]).size(), 0, "Basis, Vector3, índices e comentários passam")
	assert_eq(_allocations_in("func outra() -> void:\n\tpass\n", ["_roll_by_wheel"]).size(), 1, "função que sumiu do texto reprova, não passa em branco")
