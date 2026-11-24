extends GutTest
## LW-099d: a APARIÇÃO de 0,4 s do corpo da caravana (`CaravanView`), sem janela, ponte nem simulação. A primeira pose depois de `bind` começa a dissolução (transparência 1 a 0, linear, em tempo real) e cobre o comerciante, o carrinho, as rodas e a carga; o
## `_process` só roda enquanto aparece; trocar de trecho (outra pose) não recomeça; `release` volta tudo a opaco e sem aparição pendente (o corpo reaproveitado não herda nada). Só se confere o VALOR da propriedade `transparency`; a aparência é da janela de Arthur.

const EPS: float = 0.0001
const GROUND: Vector3 = Vector3(20.0, 10.0, 40.0)
const STEP_S: float = 0.05
const STEPS_TO_END: int = 9

var _routes: CaravanRoutesReader


func before_all() -> void:
	var loaded: CaravanRoutesReader.LoadResult = CaravanRoutesReader.from_file()
	assert_true(loaded.result.ok, loaded.result.message)
	_routes = loaded.data


## Um corpo ligado, andando e com carga, ainda SEM pose.
func _bound() -> CaravanView:
	var view: CaravanView = CaravanView.new(_routes)
	add_child_autofree(view)
	view.bind(7)
	view.apply_state(true, "grain", 900)
	return view


func _geometry(root: Node, found: Array[GeometryInstance3D] = []) -> Array[GeometryInstance3D]:
	if root is GeometryInstance3D:
		found.append(root as GeometryInstance3D)
	for child: Node in root.get_children():
		_geometry(child, found)
	return found


## Toda a geometria do corpo tem exatamente `expected` de transparência (e a lista não é vazia).
func _all_are(view: CaravanView, expected: float) -> bool:
	var parts: Array[GeometryInstance3D] = _geometry(view)
	for part: GeometryInstance3D in parts:
		if absf(part.transparency - expected) > EPS:
			return false
	return parts.size() > 10


func _tire(view: CaravanView) -> GeometryInstance3D:
	return view.get_node(NodePath("%s/%s/%s" % [CaravanView.CART_NAME, CaravanView.WHEEL_NAMES[0], CaravanView.TIRE_NAME])) as GeometryInstance3D


func test_without_a_pose_the_body_is_opaque_idle_and_ignores_the_clock() -> void:
	var view: CaravanView = _bound()
	assert_eq([view.fade(), view.is_appearing(), view.is_processing(), view.visible], [0.0, false, false, false], "ligado e sem pose: opaco, sem aparição, sem `_process` e escondido")
	view.advance_fade(1.0)
	assert_eq([view.fade(), view.is_appearing(), _all_are(view, 0.0)], [0.0, false, true], "sem aparição o tempo não faz nada")


func test_the_first_pose_makes_the_whole_body_invisible_and_it_becomes_opaque_in_0_4_seconds() -> void:
	var view: CaravanView = _bound()
	view.apply_pose(GROUND, 0.0, 0.0)
	assert_eq([view.visible, view.is_appearing(), view.is_processing(), view.fade()], [true, true, true, 1.0], "a 1ª pose mostra o corpo, já invisível, e liga o `_process`")
	assert_true(_all_are(view, 1.0), "comerciante (cápsula e nariz), carrinho, varas, rodas, raios e volumes: toda a geometria nasce transparente")
	assert_eq([_tire(view).transparency, view.merchant().fade()], [1.0, 1.0], "a roda (do carrinho) e o `NpcView` do comerciante, que também guarda a conta dele")
	var previous: float = 1.0
	for step: int in STEPS_TO_END:
		view.advance_fade(STEP_S)
		var elapsed: float = float(step + 1) * STEP_S
		assert_lte(view.fade(), previous, "monotônica: nunca fica mais transparente")
		assert_almost_eq(view.fade(), PresenceFade.in_amount(elapsed), EPS, "segue a curva linear")
		assert_true(_all_are(view, view.fade()), "e o corpo todo acompanha")
		previous = view.fade()
		if step == 3:
			assert_almost_eq(view.fade(), 0.5, EPS, "na metade de 0,4 s, meio transparente")
	assert_eq([view.fade(), view.is_appearing(), view.is_processing()], [0.0, false, false], "passados 0,4 s: opaco, aparição acabada e `_process` desligado")
	assert_true(_all_are(view, 0.0), "toda a geometria opaca")
	view.advance_fade(5.0)
	assert_eq(view.fade(), 0.0, "depois de acabar, o tempo não muda mais nada")


func test_odd_deltas_are_safe_zero_changes_nothing_negative_and_nan_are_ignored_and_a_huge_one_finishes() -> void:
	var view: CaravanView = _bound()
	view.apply_pose(GROUND, 0.0, 0.0)
	view.advance_fade(0.1)
	var quarter: float = view.fade()
	view.advance_fade(0.0)
	view.advance_fade(-5.0)
	view.advance_fade(NAN)
	assert_almost_eq(view.fade(), quarter, EPS, "delta 0, negativo e NaN não andam")
	assert_true(_all_are(view, quarter), "nem o corpo")
	view.advance_fade(1.0e9)
	assert_eq([view.fade(), view.is_appearing(), view.is_processing()], [0.0, false, false], "um delta enorme termina a aparição de uma vez, sem sobra")
	assert_true(_all_are(view, 0.0), "opaco")


func test_another_pose_neither_restarts_nor_stops_the_appearance_and_a_leg_change_does_not_start_one() -> void:
	var view: CaravanView = _bound()
	view.apply_pose(GROUND, 0.0, 0.0)
	view.advance_fade(0.2)
	view.apply_pose(GROUND + Vector3(0.0, 0.0, -1.0), 0.3, 0.0)
	assert_almost_eq(view.fade(), 0.5, EPS, "a 2ª pose no meio da aparição não a recomeça")
	view.advance_fade(0.3)
	assert_eq(view.fade(), 0.0, "e ela termina no prazo")
	view.apply_pose(GROUND + Vector3(40.0, 0.0, 0.0), 2.0, 0.0)
	view.apply_state(true, "wood", 300)
	assert_eq([view.fade(), view.is_appearing(), view.is_processing()], [0.0, false, false], "a troca de trecho (mesmo corpo, outra pose e outra carga) não começa nova aparição")


func test_release_zeroes_it_and_a_reused_body_is_opaque_with_nothing_pending_and_appears_again() -> void:
	var view: CaravanView = _bound()
	view.apply_pose(GROUND, 0.0, 0.0)
	view.advance_fade(0.1)
	view.release()
	assert_eq([view.fade(), view.is_appearing(), view.is_processing(), view.visible], [0.0, false, false, false], "`release` no meio da aparição: opaco, sem aparição pendente, sem `_process`, escondido")
	assert_true(_all_are(view, 0.0), "toda a geometria opaca")
	view.advance_fade(0.3)
	assert_eq(view.fade(), 0.0, "o tempo que passa depois não ressuscita nada")
	view.bind(8)
	assert_true(_all_are(view, 0.0), "o corpo reaproveitado sai da reserva opaco")
	view.apply_pose(GROUND, 0.0, 0.0)
	assert_eq([view.fade(), view.is_appearing()], [1.0, true], "e a primeira aparição dele é uma aparição completa")


func test_a_body_that_starts_appearing_outside_the_tree_keeps_processing_once_inside() -> void:
	var view: CaravanView = CaravanView.new(_routes)
	view.bind(7)
	view.apply_pose(GROUND, 0.0, 0.0)
	assert_true(view.is_appearing(), "começou fora da árvore")
	add_child_autofree(view)
	assert_eq([view.is_processing(), view.merchant().is_processing()], [true, false], "dentro da árvore o `_process` do corpo segue ligado e o do comerciante filho, desligado")


func test_real_frames_advance_the_appearance_and_the_process_stops_when_it_ends() -> void:
	var view: CaravanView = _bound()
	view.apply_pose(GROUND, 0.0, 0.0)
	await wait_process_frames(3)
	assert_lt(view.fade(), 1.0, "os quadros reais (delta > 0) já fizeram o corpo aparecer um pouco")
	view.advance_fade(1.0)
	assert_eq([view.fade(), view.is_processing()], [0.0, false], "e ao completar o `_process` desliga")


func test_the_appearance_ends_exactly_at_0_4_seconds_and_not_a_moment_before() -> void:
	var early: CaravanView = _bound()
	early.apply_pose(GROUND, 0.0, 0.0)
	early.advance_fade(0.2)
	early.advance_fade(0.19)
	assert_eq([early.is_appearing(), early.is_processing()], [true, true], "aos 0,39 s ainda aparece")
	assert_almost_eq(early.fade(), 0.025, EPS, "quase opaco, mas ainda não")
	var exact: CaravanView = _bound()
	exact.apply_pose(GROUND, 0.0, 0.0)
	exact.advance_fade(0.2)
	exact.advance_fade(0.2)
	assert_eq([exact.is_appearing(), exact.is_processing(), exact.fade()], [false, false, 0.0], "aos 0,4 s EXATOS (dois passos de 0,2 s, soma exata em double) a aparição acabou e o `_process` desligou")
	assert_true(_all_are(exact, 0.0), "toda a geometria opaca")
