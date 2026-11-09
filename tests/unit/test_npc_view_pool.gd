extends GutTest
## LW-072b: o corpo do NPC (`NpcView`) e a reserva de corpos (`NpcViewPool`), sem janela e sem a simulação. Corpo: cápsula de 0,4 x 1,8 m, azul-
## acinzentada, com nariz e sem colisão; parado fica imóvel, andando quica e se inclina, e o corpo religado não herda estado. Reserva: 60
## corpos de antemão, um corpo por NPC, 100 entradas e saídas sem perder nem criar nó, pedido duplicado ou ID inválido recusado com erro visível.

const GROUND_M: Vector3 = Vector3(320.0, 12.5, 540.0)
const OTHER_M: Vector3 = Vector3(341.0, 11.0, 560.0)
const TOLERANCE: float = 0.001
const STEP_SECONDS: float = 0.05
const WALK_STEPS: int = 40
const PREWARM: int = 60
const ROUNDS: int = 100
## Quantos NPCs ficam com corpo ao mesmo tempo no teste das 100 entradas (o limite de S0 é 50).
const KEPT_AT_ONCE: int = 40
const SMALL_PREWARM: int = 2

var _parent: Node3D


func before_each() -> void:
	_parent = Node3D.new()
	add_child_autofree(_parent)


func _new_view() -> NpcView:
	var view: NpcView = NpcView.new()
	add_child_autofree(view)
	return view


func _visual_of(view: NpcView) -> Node3D:
	return view.get_node(NpcView.VISUAL_NAME) as Node3D


func _monitor(which: Performance.Monitor) -> int:
	return int(Performance.get_monitor(which))


# ---------------------------------------------------------------------------------------------------- o corpo

func test_the_body_is_a_blue_grayish_capsule_with_a_nose_in_front_and_no_collision() -> void:
	var view: NpcView = _new_view()
	var capsule: MeshInstance3D = _visual_of(view).get_node(NpcView.CAPSULE_NAME) as MeshInstance3D
	var mesh: CapsuleMesh = capsule.mesh as CapsuleMesh
	assert_not_null(mesh, "O corpo é uma cápsula.")
	assert_almost_eq(mesh.radius, 0.4, TOLERANCE)
	assert_almost_eq(mesh.height, 1.8, TOLERANCE)
	assert_almost_eq(capsule.position.y, 0.9, TOLERANCE, "O centro fica a meia altura: a origem do corpo é nos pés.")
	var color: Color = (mesh.material as StandardMaterial3D).albedo_color
	assert_between(color.h, 0.5, 0.7, "Matiz azul.")
	assert_lt(color.s, 0.5, "Pouco saturada: acinzentada.")
	assert_ne(color, PlayerBody.CAPSULE_COLOR, "E não se confunde com o laranja do jogador.")
	var nose: MeshInstance3D = _visual_of(view).get_node(NpcView.NOSE_NAME) as MeshInstance3D
	assert_lt(nose.position.z, 0.0, "O nariz fica à frente (-Z local).")
	assert_gt(nose.position.y, capsule.position.y, "E na altura da cabeça.")
	assert_eq(view.find_children("*", "CollisionObject3D", true, false).size() + view.find_children("*", "CollisionShape3D", true, false).size(), 0, "Sem física.")


func test_attach_puts_the_feet_on_the_point_detach_hides_and_a_reused_body_starts_clean() -> void:
	var view: NpcView = _new_view()
	assert_eq(view.npc_id, IdGenerator.NO_ID, "Um corpo novo é livre.")
	view.attach(7, GROUND_M)
	assert_eq([view.npc_id, view.position, view.visible, view.is_walking()], [7, GROUND_M, true, false], "Liga ao NPC, pés no ponto, visível e parado.")
	view.set_walking(true)
	view.advance_animation(STEP_SECONDS)
	view.rotation.y = 1.0
	view.detach()
	assert_eq([view.npc_id, view.visible, view.is_walking()], [IdGenerator.NO_ID, false, false], "Soltar esconde e para o andar.")
	view.attach(9, OTHER_M)
	assert_eq([view.npc_id, view.position, view.rotation], [9, OTHER_M, Vector3.ZERO], "Religar não herda a direção do NPC anterior.")
	assert_eq([_visual_of(view).position, _visual_of(view).rotation], [Vector3.ZERO, Vector3.ZERO], "Nem o quique.")


func test_an_idle_body_stays_still_and_does_not_process() -> void:
	var view: NpcView = _new_view()
	view.attach(7, GROUND_M)
	for _step: int in WALK_STEPS:
		view.advance_animation(STEP_SECONDS)
	assert_eq([_visual_of(view).position, _visual_of(view).rotation], [Vector3.ZERO, Vector3.ZERO])
	assert_false(view.is_processing(), "Parado, o corpo não gasta processamento por quadro.")


func test_a_walking_body_bounces_from_the_ground_up_and_leans_forward_and_stopping_puts_it_back_on_its_feet() -> void:
	var view: NpcView = _new_view()
	view.attach(7, GROUND_M)
	view.set_walking(true)
	var visual: Node3D = _visual_of(view)
	assert_almost_eq(visual.rotation.x, -deg_to_rad(4.0), TOLERANCE, "Inclina para a frente (-Z).")
	var lowest: float = INF
	var highest: float = -INF
	for _step: int in WALK_STEPS:
		view.advance_animation(STEP_SECONDS)
		lowest = minf(lowest, visual.position.y)
		highest = maxf(highest, visual.position.y)
	assert_gte(lowest, 0.0, "O quique nunca afunda o corpo no chão.")
	assert_almost_eq(highest, 0.06, TOLERANCE, "E chega à altura do quique.")
	assert_eq([visual.position.x, visual.position.z, view.position], [0.0, 0.0, GROUND_M], "O quique é só do visual: a posição lógica não muda.")
	view.set_walking(false)
	assert_eq([visual.position, visual.rotation, view.is_processing()], [Vector3.ZERO, Vector3.ZERO, false], "Parar põe o corpo de pé de novo.")


func test_the_frames_of_the_game_drive_the_walk_even_when_the_body_was_set_to_walk_before_entering_the_tree() -> void:
	var walker: NpcView = NpcView.new()
	walker.attach(7, GROUND_M)
	walker.set_walking(true)
	add_child_autofree(walker)
	assert_true(walker.is_processing(), "Entrar na árvore não desliga o andar.")
	await wait_process_frames(3)
	assert_gt(_visual_of(walker).position.y, 0.0, "Os quadros do jogo fazem o corpo quicar.")


# ---------------------------------------------------------------------------------------------------- a reserva

func test_the_pool_prewarms_hidden_bodies_and_taking_and_giving_back_shows_hides_and_counts() -> void:
	var pool: NpcViewPool = NpcViewPool.new(_parent)
	assert_eq([pool.created, pool.free_count(), pool.active_count(), _parent.get_child_count(), pool.lost_count()], [PREWARM, PREWARM, 0, PREWARM, 0])
	for child: Node in _parent.get_children():
		assert_false((child as NpcView).visible, "Os corpos de antemão ficam escondidos.")
	for npc_id: int in [9, 3, 7]:
		assert_not_null(pool.take(npc_id, GROUND_M))
	assert_eq(pool.active_ids(), [3, 7, 9] as Array[int], "Os ativos saem em ordem crescente.")
	var view: NpcView = pool.body_of(7)
	assert_eq([view.npc_id, view.position, view.visible, pool.free_count()], [7, GROUND_M, true, PREWARM - 3])
	assert_true(pool.give_back(7))
	assert_eq([view.visible, view.npc_id, pool.body_of(7), pool.free_count(), pool.returned], [false, IdGenerator.NO_ID, null, PREWARM - 2, 1])
	assert_false(pool.give_back(7), "Devolver de novo não faz nada.")
	assert_eq(pool.returned, 1, "E não conta como devolução.")


func test_100_enters_and_exits_keep_every_node_and_never_grow_the_pool() -> void:
	var pool: NpcViewPool = NpcViewPool.new(_parent)
	var nodes_before: int = _monitor(Performance.OBJECT_NODE_COUNT)
	var orphans_before: int = _monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	for npc_id: int in range(1, ROUNDS + 1):
		assert_not_null(pool.take(npc_id, GROUND_M + Vector3(float(npc_id), 0.0, 0.0)))
		if npc_id > KEPT_AT_ONCE:
			assert_true(pool.give_back(npc_id - KEPT_AT_ONCE))
		assert_eq(pool.lost_count(), 0)
	for npc_id: int in pool.active_ids():
		assert_true(pool.give_back(npc_id))
	assert_eq([pool.created, pool.taken, pool.returned, pool.peak_active], [PREWARM, ROUNDS, ROUNDS, KEPT_AT_ONCE + 1], "Depois do aquecimento nada foi criado.")
	assert_eq([pool.empty_hits, pool.duplicate_requests, pool.lost_count(), pool.active_count(), pool.free_count()], [0, 0, 0, 0, PREWARM])
	assert_eq(_monitor(Performance.OBJECT_NODE_COUNT), nodes_before, "Nenhum nó nasceu nem morreu.")
	assert_eq(_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT), orphans_before, "E nenhum nó ficou órfão.")


func test_when_the_pool_runs_out_it_creates_one_body_at_a_time_counts_it_and_reuses_it() -> void:
	var pool: NpcViewPool = NpcViewPool.new(_parent, SMALL_PREWARM)
	for npc_id: int in range(1, SMALL_PREWARM + 2):
		assert_not_null(pool.take(npc_id, GROUND_M))
	assert_eq([pool.created, pool.empty_hits], [SMALL_PREWARM + 1, 1], "Faltou um corpo: o pool criou um.")
	for npc_id: int in pool.active_ids():
		assert_true(pool.give_back(npc_id))
	for npc_id: int in range(10, 13):
		assert_not_null(pool.take(npc_id, GROUND_M))
	assert_eq([pool.created, pool.empty_hits, pool.lost_count()], [SMALL_PREWARM + 1, 1, 0], "O corpo novo é reaproveitado, sem criar outro.")


func test_a_second_body_for_the_same_npc_and_an_invalid_id_are_refused_with_a_visible_error() -> void:
	var pool: NpcViewPool = NpcViewPool.new(_parent)
	var first: NpcView = pool.take(5, GROUND_M)
	assert_null(pool.take(5, OTHER_M), "Um NPC nunca tem dois corpos.")
	assert_push_error("já tem corpo")
	assert_eq([pool.duplicate_requests, pool.body_of(5), first.position, pool.taken], [1, first, GROUND_M, 1], "O corpo que ele tinha segue o mesmo e intocado.")
	assert_null(pool.take(IdGenerator.NO_ID, GROUND_M))
	assert_push_error("inválido")
	assert_null(pool.take(-3, GROUND_M))
	assert_push_error("inválido")
	assert_eq([pool.active_count(), pool.taken], [1, 1], "ID inválido não tira corpo da reserva.")


func test_a_body_that_is_neither_free_nor_active_is_counted_as_lost() -> void:
	var pool: NpcViewPool = NpcViewPool.new(_parent)
	_parent.add_child(NpcView.new())
	assert_eq(pool.lost_count(), 1, "O contador de corpos perdidos enxerga um corpo estranho no pai.")
