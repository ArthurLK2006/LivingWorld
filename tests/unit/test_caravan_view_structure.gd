extends GutTest
## LW-099b2a: a estrutura do corpo da caravana (`CaravanView`), sem janela, ponte nem simulação. Três partes de primitivas (o comerciante à frente, o carrinho atrás e
## a carga), nenhum nó de colisão nem de interação, só o `trader_id` guardado, o corpo que nasce e volta ESCONDIDO e o corpo reciclado que não herda estado, e nada
## que escreva na simulação (a classe não recebe ponte nem módulo de `sim`). Os tamanhos são [HIP]: o teste confere a relação entre as partes, não os números.

const SOURCE: String = "res://src/presentation/world_view/entities/caravan_view.gd"
const POINT: Vector3 = Vector3(320.0, 12.5, 540.0)
const OTHER: Vector3 = Vector3(341.0, 11.0, 560.0)
const FAR: Vector3 = Vector3(900.0, 10.0, 100.0)
## Passo (m) da 2ª pose do corpo religado: uns 2 rad de roda.
const STEP_M: float = 0.76
const EPS: float = 0.001
## Quem, na apresentação, conversa com a simulação: o corpo não pode citar nenhum deles.
const FORBIDDEN: PackedStringArray = ["SimBridge", "SimulationHost", "EventBus", "peek_", "request_", "res://src/sim", "res://src/bridge"]

var _routes: CaravanRoutesReader


func before_all() -> void:
	var loaded: CaravanRoutesReader.LoadResult = CaravanRoutesReader.from_file()
	assert_true(loaded.result.ok, loaded.result.message)
	_routes = loaded.data


func _new_view() -> CaravanView:
	var view: CaravanView = CaravanView.new(_routes)
	add_child_autofree(view)
	return view


func _part(view: CaravanView, path: String) -> Node3D:
	return view.get_node(NodePath(path)) as Node3D


func test_the_body_has_three_parts_the_merchant_in_front_the_cart_behind_and_the_cargo() -> void:
	var view: CaravanView = _new_view()
	assert_eq(view.get_child_count(), 3, "comerciante, carrinho e carga, nada mais")
	var merchant: NpcView = _part(view, CaravanView.MERCHANT_NAME) as NpcView
	assert_not_null(merchant, "o comerciante é um NpcView (a mesma cápsula provisória)")
	assert_same(view.merchant(), merchant, "e `merchant()` entrega esse mesmo")
	assert_eq(merchant.npc_id, IdGenerator.NO_ID, "ele NÃO é um corpo da reserva de NPCs: não está ligado a nenhum NPC")
	assert_null(_part(view, CaravanView.CART_NAME).get_script(), "o carrinho é só um grupo de peças")
	assert_not_null(_part(view, CaravanView.CARGO_NAME))
	var nose: Node3D = _part(view, "%s/%s/%s" % [CaravanView.MERCHANT_NAME, NpcView.VISUAL_NAME, NpcView.NOSE_NAME])
	assert_lt(nose.position.z, 0.0, "a frente do comerciante é -Z local")
	assert_gt(_part(view, CaravanView.CART_NAME).position.z, nose.position.z + NpcView.CAPSULE_RADIUS_M, "o carrinho vem ATRÁS dele (+Z), fora da cápsula")


func test_the_cart_is_a_bed_two_shafts_and_two_wheels_with_their_own_pivots() -> void:
	var view: CaravanView = _new_view()
	var cart: Node3D = _part(view, CaravanView.CART_NAME)
	assert_true((_part(view, "%s/%s" % [CaravanView.CART_NAME, CaravanView.BED_NAME]) as MeshInstance3D).mesh is BoxMesh, "leito de caixa")
	assert_eq(cart.get_child_count(), 1 + 2 + 2, "leito, duas varas e duas rodas")
	var wheel_sides: Array[float] = []
	for index: int in 2:
		assert_true((cart.get_node(NodePath(CaravanView.SHAFT_NAMES[index])) as MeshInstance3D).mesh is BoxMesh, "vara de caixa")
		var pivot: Node3D = cart.get_node(NodePath(CaravanView.WHEEL_NAMES[index])) as Node3D
		assert_false(pivot is MeshInstance3D, "o pivô é um nó à parte: só ele gira, a malha vai junto")
		assert_eq(pivot.get_child_count(), 2, "pneu e raio")
		var tire: MeshInstance3D = pivot.get_node(NodePath(CaravanView.TIRE_NAME)) as MeshInstance3D
		assert_true(tire.mesh is CylinderMesh, "o pneu é um cilindro")
		assert_almost_eq((tire.mesh as CylinderMesh).top_radius, CaravanView.WHEEL_RADIUS_M, EPS)
		assert_almost_eq(pivot.position.y, CaravanView.WHEEL_RADIUS_M, EPS, "a roda toca o chão")
		assert_true((pivot.get_node(NodePath(CaravanView.SPOKE_NAME)) as MeshInstance3D).mesh is BoxMesh, "o raio é uma caixa")
		wheel_sides.append(pivot.position.x)
	assert_almost_eq(wheel_sides[0], -wheel_sides[1], EPS, "uma roda de cada lado do leito")
	assert_gt(absf(wheel_sides[1]), CaravanView.BED_SIZE_M.x * 0.5, "fora do leito, não dentro dele")


func test_everything_is_a_primitive_with_no_collision_and_no_interaction() -> void:
	var view: CaravanView = _new_view()
	for node: Node in view.find_children("*", "MeshInstance3D", true, false):
		assert_true((node as MeshInstance3D).mesh is PrimitiveMesh, "%s é uma primitiva (sem arte nova)" % node.name)
	for forbidden: String in ["CollisionObject3D", "CollisionShape3D", "RayCast3D", "Control", "Label3D"]:
		assert_eq(view.find_children("*", forbidden, true, false).size(), 0, "sem %s" % forbidden)
	assert_false(view.is_processing(), "o corpo não processa por quadro: a pose vem de fora")


func test_the_body_keeps_only_the_trader_id() -> void:
	var view: CaravanView = _new_view()
	var public_vars: PackedStringArray = PackedStringArray()
	for property: Dictionary in view.get_property_list():
		var is_script_var: bool = (int(property["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE) != 0
		if is_script_var and not str(property["name"]).begins_with("_"):
			public_vars.append(str(property["name"]))
	assert_eq(public_vars, PackedStringArray(["trader_id"]), "o único estado público é o ID do comerciante")


func test_the_body_never_touches_the_simulation_or_the_bridge() -> void:
	var source: String = FileAccess.get_file_as_string(SOURCE)
	assert_false(source.is_empty(), "o teste achou o código do corpo")
	for forbidden: String in FORBIDDEN:
		assert_false(source.contains(forbidden), "o corpo não pode citar '%s': só apresentação, sem caminho para a simulação" % forbidden)


func test_a_new_body_is_free_and_hidden_and_binding_shows_it_only_at_the_first_pose() -> void:
	var view: CaravanView = _new_view()
	assert_eq([view.trader_id, view.is_bound(), view.visible], [IdGenerator.NO_ID, false, false], "nasce livre e escondido")
	view.bind(7)
	assert_eq([view.trader_id, view.is_bound(), view.visible], [7, true, false], "ligado, mas sem lugar ainda: escondido")
	view.apply_pose(POINT, 0.0, 0.0)
	assert_true(view.visible, "a primeira pose o mostra")
	view.release()
	assert_eq([view.trader_id, view.is_bound(), view.visible], [IdGenerator.NO_ID, false, false], "devolver esconde")
	assert_eq([view.get_child_count(), view.is_queued_for_deletion()], [3, false], "e nada é apagado")


func test_a_free_body_ignores_pose_and_state_and_a_bad_id_changes_nothing() -> void:
	var view: CaravanView = _new_view()
	view.apply_pose(POINT, 1.0, 0.1)
	view.apply_state(true, "grain", 1000)
	assert_eq([view.visible, view.position, view.rotation, view.volume_count(), view.merchant().is_walking()], [false, Vector3.ZERO, Vector3.ZERO, 0, false])
	view.bind(IdGenerator.NO_ID)
	assert_push_error("inválido")
	view.bind(-4)
	assert_push_error("inválido")
	assert_false(view.is_bound(), "ID inválido não liga o corpo")


## Um corpo já ligado ao comerciante 7 que andou, com carga e rodas giradas.
func _used_view() -> CaravanView:
	var view: CaravanView = _new_view()
	view.bind(7)
	view.apply_state(true, "grain", 1000)
	view.apply_pose(POINT, 0.5, 0.2)
	view.apply_pose(OTHER, 0.5, 0.2)
	assert_ne(_wheel_of(view).rotation, Vector3.ZERO, "o corpo velho andou: a roda girou")
	return view


func _wheel_of(view: CaravanView) -> Node3D:
	return _part(view, "%s/%s" % [CaravanView.CART_NAME, CaravanView.WHEEL_NAMES[0]])


## O comerciante novo recomeça do zero: sem pose, carga nem andar herdados e, ao andar, a pisada liga de novo e a roda gira -passo/raio A PARTIR DE ZERO (nenhum ângulo velho).
func _assert_starts_over(view: CaravanView) -> void:
	var wheel: Node3D = _wheel_of(view)
	assert_eq([view.trader_id, view.visible, view.position, view.rotation], [9, false, Vector3.ZERO, Vector3.ZERO], "religar a outro comerciante não herda a pose")
	assert_eq([view.volume_count(), view.merchant().is_walking(), wheel.rotation], [0, false, Vector3.ZERO], "nem a carga, nem o andar, nem a volta das rodas")
	view.apply_state(true, "grain", 500)
	assert_true(view.merchant().is_walking(), "andando de novo: o comerciante da caravana nova volta a pisar (o `release` esqueceu o 'andava' da velha)")
	view.apply_pose(FAR, 0.0, 0.0)
	assert_eq([wheel.rotation, view.visible], [Vector3.ZERO, true], "a primeira pose do corpo religado não gira as rodas: o 'quadro anterior' do comerciante velho não vale")
	view.apply_pose(FAR + Vector3(0.0, 0.0, -STEP_M), 0.0, 0.0)
	assert_almost_eq(angle_difference(wheel.rotation.x, -STEP_M / CaravanView.WHEEL_RADIUS_M), 0.0, EPS, "a segunda pose gira exatamente -passo/raio: o ângulo da caravana velha não sobra")


func test_a_released_body_bound_again_starts_over() -> void:
	var view: CaravanView = _used_view()
	view.release()
	view.bind(9)
	_assert_starts_over(view)


func test_a_body_bound_again_without_a_release_starts_over() -> void:
	var view: CaravanView = _used_view()
	view.bind(9)
	_assert_starts_over(view)
