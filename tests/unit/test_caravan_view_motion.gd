extends GutTest
## LW-099b2a: a pose, as rodas e a pisada do corpo da caravana (`CaravanView`), sem janela, ponte nem simulação. A pose (posição, giro e inclinação) é aplicada como vem;
## a frente é -Z local e bate com o giro do `CaravanPath`; a inclinação positiva levanta a frente; a mesma pose de novo não faz nada. As rodas giram pela DISTÂNCIA REAL
## entre duas poses seguidas (distância ÷ raio, para a frente) e o comerciante pisa com a cadência do `NpcView` na mesma distância; parada (`travelling` falso), em pausa
## (a mesma pose) ou sem "quadro anterior" (a primeira pose), nada anima; e o caminho quente não cria objeto nenhum.

const EPS: float = 0.0001
## Perto da origem de propósito: com coordenadas pequenas o float de 32 bits da Godot erra menos de 1e-5 m por posição, e a conta distância ÷ raio fecha na tolerância.
const GROUND: Vector3 = Vector3(20.0, 10.0, 40.0)
const FRAME_STEPS: int = 600
const CODE: String = "res://src/presentation/world_view/entities/caravan_view.gd"
## Os caminhos quentes (por quadro, ou a cada mudança de estado): a pose, o estado, o passo das rodas e da pisada, o andar do comerciante e a troca de carga.
const HOT_PATHS: PackedStringArray = ["apply_pose", "apply_state", "_roll", "_set_merchant_walking", "_refresh_cargo", "volumes_for"]

var _routes: CaravanRoutesReader


func before_all() -> void:
	var loaded: CaravanRoutesReader.LoadResult = CaravanRoutesReader.from_file()
	assert_true(loaded.result.ok, loaded.result.message)
	_routes = loaded.data


## Um corpo ligado, andando, com carga, e já com a primeira pose (a que não anima) em GROUND.
func _walking_view() -> CaravanView:
	var view: CaravanView = CaravanView.new(_routes)
	add_child_autofree(view)
	view.bind(7)
	view.apply_state(true, "grain", 500)
	view.apply_pose(GROUND, 0.0, 0.0)
	return view


func _wheels(view: CaravanView) -> Array[Node3D]:
	var wheels: Array[Node3D] = []
	for wheel_name: String in CaravanView.WHEEL_NAMES:
		wheels.append(view.get_node(NodePath("%s/%s" % [CaravanView.CART_NAME, wheel_name])) as Node3D)
	return wheels


func _stride_height(view: CaravanView) -> float:
	return (view.merchant().get_node(NodePath(NpcView.VISUAL_NAME)) as Node3D).position.y


## O que a animação mexe: o giro de cada roda e o quique do comerciante (altura e inclinação).
func _animated_state(view: CaravanView) -> Array:
	var visual: Node3D = view.merchant().get_node(NodePath(NpcView.VISUAL_NAME)) as Node3D
	var state: Array = [visual.position, visual.rotation]
	for wheel: Node3D in _wheels(view):
		state.append(wheel.rotation)
	return state


func test_the_pose_puts_the_feet_turns_the_front_like_the_road_and_leaves_the_cart_behind() -> void:
	var view: CaravanView = CaravanView.new(_routes)
	add_child_autofree(view)
	view.bind(7)
	var road: CaravanPath = CaravanPath.new(PackedVector2Array([Vector2(0.0, 40.0), Vector2(400.0, 40.0)]))
	var pose: CaravanPath.Pose = CaravanPath.Pose.new()
	road.sample_into(0.5, true, 0.0, pose)
	view.apply_pose(Vector3(pose.position.x, 10.0, pose.position.y), pose.yaw, 0.0)
	assert_eq([view.position, view.visible], [Vector3(200.0, 10.0, 40.0), true], "pés no ponto da estrada, e a primeira pose mostra o corpo")
	var forward: Vector3 = view.global_transform.basis * Vector3.FORWARD
	assert_lt(forward.distance_to(Vector3.RIGHT), EPS, "a estrada vai para leste (+X): a frente (-Z local) vai com ela")
	var cart_offset: Vector3 = (view.get_node(NodePath(CaravanView.CART_NAME)) as Node3D).global_position - view.global_position
	assert_lt(cart_offset.dot(forward), 0.0, "o carrinho vem atrás do comerciante, no sentido contrário à marcha")
	var nose: Node3D = view.get_node(NodePath("%s/%s/%s" % [CaravanView.MERCHANT_NAME, NpcView.VISUAL_NAME, NpcView.NOSE_NAME])) as Node3D
	assert_gt((nose.global_position - view.global_position).dot(forward), 0.0, "e o nariz do comerciante aponta para onde ele anda")


func test_a_positive_pitch_lifts_the_front_and_lowers_the_cart_behind_whatever_the_heading() -> void:
	var view: CaravanView = _walking_view()
	# Com o giro fora de zero a inclinação é em torno do eixo do próprio carrinho (a ordem Y depois X dos ângulos), não do eixo do mundo.
	view.apply_pose(GROUND, 1.0, deg_to_rad(20.0))
	var forward: Vector3 = view.global_transform.basis * Vector3.FORWARD
	assert_almost_eq(forward.y, sin(deg_to_rad(20.0)), EPS, "a frente sobe o seno do ângulo")
	assert_almost_eq(Vector2(forward.x, forward.z).angle_to(Vector2(-sin(1.0), -cos(1.0))), 0.0, EPS, "e continua apontando para onde o giro mandou")
	assert_lt((view.get_node(NodePath(CaravanView.CART_NAME)) as Node3D).global_position.y, GROUND.y, "o carrinho, atrás, fica abaixo dos pés do comerciante")
	view.apply_pose(GROUND, 1.0, -deg_to_rad(20.0))
	assert_lt((view.global_transform.basis * Vector3.FORWARD).y, 0.0, "negativa: a frente desce")


func test_the_same_pose_again_changes_nothing_and_a_bad_pose_is_ignored() -> void:
	var view: CaravanView = _walking_view()
	view.apply_pose(GROUND + Vector3(0.0, 0.0, -1.0), 0.3, 0.1)
	var before: Array = _animated_state(view)
	var transform_before: Transform3D = view.transform
	for _step: int in 5:
		view.apply_pose(GROUND + Vector3(0.0, 0.0, -1.0), 0.3, 0.1)
	assert_eq([_animated_state(view), view.transform], [before, transform_before], "a mesma pose: nem corpo nem rodas se mexem")
	view.apply_pose(Vector3(NAN, 0.0, 0.0), 0.3, 0.1)
	view.apply_pose(GROUND, INF, 0.1)
	view.apply_pose(GROUND, 0.3, NAN)
	assert_eq([_animated_state(view), view.transform], [before, transform_before], "valor não finito é ignorado: a tela nunca recebe NaN")


func test_the_wheels_turn_forward_by_the_distance_over_the_radius_and_both_the_same() -> void:
	var view: CaravanView = _walking_view()
	var wheels: Array[Node3D] = _wheels(view)
	assert_eq([wheels[0].rotation, wheels[1].rotation], [Vector3.ZERO, Vector3.ZERO], "a primeira pose não tem 'quadro anterior': nada gira")
	var walked: float = 0.0
	for step_m: float in [0.05, 0.3, 1.2, 0.004, 2.5]:
		walked += step_m
		view.apply_pose(GROUND + Vector3(0.0, 0.0, -walked), 0.0, 0.0)
		for wheel: Node3D in wheels:
			assert_almost_eq(angle_difference(wheel.rotation.x, -walked / CaravanView.WHEEL_RADIUS_M), 0.0, EPS, "%s m andados: distância ÷ raio" % walked)
			assert_eq([wheel.rotation.y, wheel.rotation.z], [0.0, 0.0], "a roda gira só em torno do eixo X")


func test_a_wheel_rolls_forward_so_its_top_goes_toward_the_front() -> void:
	var view: CaravanView = _walking_view()
	view.apply_pose(GROUND + Vector3(0.0, 0.0, -0.1), 0.0, 0.0)
	var top: Vector3 = _wheels(view)[0].transform.basis * Vector3.UP
	assert_lt(top.z, 0.0, "andou para -Z: o topo da roda, que partiu do alto, foi para -Z (rolou, não deslizou)")
	assert_gt(top.y, 0.0, "e ainda está em cima")


func test_the_wheels_follow_the_real_distance_whatever_the_direction_and_the_lap_count() -> void:
	var view: CaravanView = _walking_view()
	var road: CaravanPath = CaravanPath.new(PackedVector2Array([Vector2(GROUND.x, GROUND.z), Vector2(GROUND.x + 60.0, GROUND.z), Vector2(GROUND.x + 60.0, GROUND.z + 40.0)]))
	var pose: CaravanPath.Pose = CaravanPath.Pose.new()
	var walked: float = 0.0
	var previous: Vector3 = GROUND
	for step: int in range(1, 201):
		road.sample_into(float(step) / 200.0, true, 0.0, pose)
		var here: Vector3 = Vector3(pose.position.x, 10.0, pose.position.y)
		walked += previous.distance_to(here)
		previous = here
		view.apply_pose(here, pose.yaw, 0.0)
	var wheel: Node3D = _wheels(view)[0]
	assert_almost_eq(walked, 100.0, 0.05, "60 m para leste e 40 m para o sul")
	assert_almost_eq(angle_difference(wheel.rotation.x, -walked / CaravanView.WHEEL_RADIUS_M), 0.0, 0.001, "mais de 40 voltas depois, o ângulo ainda é o certo")
	assert_between(wheel.rotation.x, 0.0, TAU, "e fica guardado dentro de uma volta")


func test_a_stopped_caravan_and_a_paused_clock_animate_nothing() -> void:
	var view: CaravanView = _walking_view()
	view.apply_pose(GROUND + Vector3(0.0, 0.0, -1.0), 0.0, 0.0)
	var moving: Array = _animated_state(view)
	view.apply_pose(GROUND + Vector3(0.0, 0.0, -1.0), 0.0, 0.0)
	assert_eq(_animated_state(view), moving, "pausa do relógio: a mesma pose de novo, nada se mexe")
	view.apply_state(false, "grain", 500)
	assert_eq([view.merchant().is_walking(), _stride_height(view)], [false, 0.0], "rota fechada: o comerciante para de pé")
	var wheel_before: Vector3 = _wheels(view)[0].rotation
	view.apply_pose(GROUND + Vector3(0.0, 0.0, -9.0), 0.0, 0.0)
	assert_eq([_wheels(view)[0].rotation, _stride_height(view)], [wheel_before, 0.0], "parada, ela não gira roda nem pisa, mesmo que a pose mude")
	assert_eq(view.position, GROUND + Vector3(0.0, 0.0, -9.0), "mas a pose é aplicada como vem")
	view.apply_state(true, "grain", 500)
	view.apply_pose(GROUND + Vector3(0.0, 0.0, -10.0), 0.0, 0.0)
	assert_ne(_wheels(view)[0].rotation, wheel_before, "voltou a andar: gira de novo")


func test_the_merchant_steps_with_the_real_distance_at_the_cadence_of_the_npc_body() -> void:
	var view: CaravanView = _walking_view()
	var merchant: NpcView = view.merchant()
	assert_true(merchant.is_walking(), "andando")
	assert_false(merchant.is_processing(), "mas não em tempo real: a pisada só anda com o deslocamento")
	var reference: NpcView = NpcView.new()
	add_child_autofree(reference)
	reference.set_walking(true)
	reference.set_process(false)
	var walked: float = 0.0
	for _step: int in 30:
		walked += 0.17
		view.apply_pose(GROUND + Vector3(0.0, 0.0, -walked), 0.0, 0.0)
	reference.advance_animation(walked / NpcRoute.WALK_SPEED_MPS)
	var visual: Node3D = reference.get_node(NodePath(NpcView.VISUAL_NAME)) as Node3D
	assert_gt(visual.position.y, 0.0, "o teste só vale se o quique saiu do zero")
	assert_almost_eq(_stride_height(view), visual.position.y, EPS, "a pisada é a do NpcView para essa distância (a 4 m/s)")


func test_a_body_set_to_walk_before_entering_the_tree_does_not_get_real_time_steps() -> void:
	var view: CaravanView = CaravanView.new(_routes)
	view.bind(7)
	view.apply_pose(GROUND, 0.0, 0.0)
	view.apply_state(true, "grain", 500)
	add_child_autofree(view)
	assert_false(view.merchant().is_processing(), "o NpcView religa o `_process` ao entrar andando; o corpo da caravana o desliga de novo")
	await wait_process_frames(3)
	assert_eq(_stride_height(view), 0.0, "e os quadros reais não fazem o comerciante pisar sem sair do lugar")


func test_the_frames_of_the_game_do_not_advance_the_stride_of_a_standing_caravan() -> void:
	var view: CaravanView = _walking_view()
	view.apply_pose(GROUND + Vector3(0.0, 0.0, -0.4), 0.0, 0.0)
	var frozen: Array = _animated_state(view)
	await wait_process_frames(4)
	assert_eq(_animated_state(view), frozen, "os quadros reais passam, a pose não: o corpo fica como estava (pausa)")


## O monitor de objetos só vê o que FICA retido: uma alocação que nasce e morre no mesmo quadro passa por ele. Quem a pega é a varredura do texto, logo abaixo.
func test_the_hot_path_leaves_no_object_or_node_retained() -> void:
	var view: CaravanView = _walking_view()
	var objects_before: int = int(Performance.get_monitor(Performance.OBJECT_COUNT))
	var nodes_before: int = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	for step: int in FRAME_STEPS:
		var along: float = float(step) * 0.05
		view.apply_pose(GROUND + Vector3(along, 0.0, 0.0), 0.5 + along * 0.001, 0.1)
		view.apply_state(step % 100 < 50, "grain" if step % 7 < 4 else "wood", (step * 37) % 1001)
	assert_eq(int(Performance.get_monitor(Performance.OBJECT_COUNT)), objects_before, "nenhum objeto ficou retido depois de 600 quadros (alocação temporária: ver a varredura do texto)")
	assert_eq(int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)), nodes_before, "nenhum nó ficou retido")


## O corpo (sem comentários) de cada função de `names` que cria objeto ou coleção: `.new(`, `Array(`, `Dictionary(`, `Packed...Array(`, `[` de construção (depois de `=`, `(`, `,`, `%` ou `return`) e `{`.
## O corpo vai da linha `func` até as duas linhas em branco que separam as funções. Função não achada também conta como achado (a varredura não passa em branco).
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


func test_the_text_of_the_hot_paths_builds_no_object_or_collection_and_the_scan_can_fail() -> void:
	assert_eq(_allocations_in(FileAccess.get_file_as_string(CODE), HOT_PATHS), PackedStringArray(), "o texto dos caminhos quentes não cria objeto nem coleção")
	for planted: String in ["var tmp: RefCounted = RefCounted.new()", "var tmp: Array[int] = [1]", "var tmp: Array = Array()", "var tmp: Dictionary = {}", "var tmp: String = \"%d\" % [1]"]:
		assert_eq(_allocations_in("func apply_pose(a: int) -> void:\n\t%s\n\n\n" % planted, ["apply_pose"]).size(), 1, "a varredura pega: %s" % planted)
	assert_eq(_allocations_in("func apply_pose(a: int) -> void:\n\tvar v: Vector3 = Vector3(a, 0.0, 0.0)  # Array() e .new( em comentário não contam\n\t_wheels[a].rotation.x = _shapes[\"x\"]\n\n\n", ["apply_pose"]).size(), 0, "valores (Vector3), índices e comentários passam")
	assert_eq(_allocations_in("func outra() -> void:\n\tpass\n", ["apply_pose"]).size(), 1, "função que sumiu do texto reprova, não passa em branco")
