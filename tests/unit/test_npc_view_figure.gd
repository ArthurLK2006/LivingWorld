extends GutTest
## ART-12, entrega 7b-1: o corpo do NPC (`NpcView`) recebe uma figura inteira (`attach_figure`, `clear_figure`, `has_figure`, `set_speed`, `speed_mps`), SÓ o corpo: a ligação no mundo é a 7b-2. A figura é SINTÉTICA e existe só em memória (um Node3D com um AnimationPlayer de `idle`, `walk` e `jog` de 1 s em laço e o metadado de velocidades {walk 0,73; jog 4,1} que o `CharacterFigure.locomotion_of` lê): nenhum ativo de terceiros nem arquivo. Com figura: ela é filha do CORPO (não do `_visual`, que se inclina e quica), vira meia-volta, a cápsula fica escondida e parada, e o clipe e a escala seguem `set_walking` e `set_speed` (parado = idle; andando sem velocidade = walk 1x; andando com velocidade = `CharacterLocomotion.pick`), sem mandar tocar de novo quando nada mudou. `clear_figure` (e o `detach` do pool) solta a figura na hora e a libera; o corpo reciclado não herda figura nem velocidade. Sem figura o corpo é a cápsula de sempre (o `test_npc_view_pool` segue como estava).

const GROUND_M: Vector3 = Vector3(320.0, 12.5, 540.0)
const OTHER_M: Vector3 = Vector3(341.0, 11.0, 560.0)
const TOLERANCE: float = 0.001
const STEP_SECONDS: float = 0.05
const WALK_STEPS: int = 40
const SMALL_PREWARM: int = 2
## A escala da figura sintética (o `build` real a escolhe pela altura da malha): o corpo não pode mexer nela.
const BODY_SCALE: float = 0.5
const CLIP_SECONDS: float = 1.0
const CLIPS: PackedStringArray = ["idle", "walk", "jog"]
const REAL: Dictionary = {"walk": 0.73, "jog": 4.1}
## [velocidade do corpo (m/s), clipe, escala de reprodução] andando, com as velocidades REAL e os limites de escala de 0,7 a 1,6.
const TABLE: Array = [[0.5, "walk", 0.7], [1.0, "walk", 1.0 / 0.73], [4.0, "jog", 4.0 / 4.1], [32.0, "jog", 1.6]]
## Quanto o clipe anda antes de conferir a fase do passo, e um ruído de velocidade abaixo da tolerância do `is_equal_approx`.
const PHASE_SECONDS: float = 0.4
const NOISE_MPS: float = 0.0000001
const SENTINEL_SCALE: float = 3.0


func _new_view() -> NpcView:
	var view: NpcView = NpcView.new()
	add_child_autofree(view)
	return view


func _visual_of(view: NpcView) -> Node3D:
	return view.get_node(NpcView.VISUAL_NAME) as Node3D


func _player_of(figure: Node3D) -> AnimationPlayer:
	return figure.find_children("*", "AnimationPlayer", false, false)[0] as AnimationPlayer


func _monitor(which: Performance.Monitor) -> int:
	return int(Performance.get_monitor(which))


## A figura sintética: escala própria, o metadado de velocidades (se `speeds` não é vazio), uma malha (como a real, o player vem depois dela) e um player com os `clips` em laço.
func _synthetic_figure(speeds: Dictionary = REAL, clips: PackedStringArray = CLIPS) -> Node3D:
	var figure: Node3D = Node3D.new()
	figure.scale = Vector3.ONE * BODY_SCALE
	figure.add_child(MeshInstance3D.new())
	if not speeds.is_empty():
		figure.set_meta(CharacterFigure.LOCOMOTION_META, speeds.duplicate())
	var library: AnimationLibrary = AnimationLibrary.new()
	for clip: String in clips:
		var animation: Animation = Animation.new()
		animation.length = CLIP_SECONDS
		animation.loop_mode = Animation.LOOP_LINEAR
		library.add_animation(StringName(clip), animation)
	var player: AnimationPlayer = AnimationPlayer.new()
	figure.add_child(player)
	player.add_animation_library("", library)
	return figure


func _assert_playing(player: AnimationPlayer, clip: String, play_scale: float, what: String) -> void:
	assert_eq(player.current_animation, clip, "%s: o clipe" % what)
	assert_almost_eq(player.get_playing_speed(), play_scale, TOLERANCE, "%s: a escala de reprodução" % what)


# ---------------------------------------------------------------------------------------------------- montar a figura

func test_attach_makes_the_figure_a_child_of_the_body_turned_around_and_idle_with_the_capsule_hidden_and_still() -> void:
	var view: NpcView = _new_view()
	var figure: Node3D = _synthetic_figure()
	view.attach_figure(figure)
	assert_true(view.has_figure())
	assert_eq(figure.get_parent(), view, "A figura é filha do CORPO...")
	assert_ne(figure.get_parent(), _visual_of(view), "...e não da parte que se inclina e quica.")
	assert_almost_eq(figure.rotation.y, PI, TOLERANCE, "Meia-volta: a figura olha para +Z e o nariz da cápsula para -Z.")
	assert_eq(figure.scale, Vector3.ONE * BODY_SCALE, "A escala é a do build e fica como está.")
	assert_false(_visual_of(view).visible, "A cápsula some enquanto há figura.")
	_assert_playing(_player_of(figure), "idle", 1.0, "Começa parada")
	view.set_walking(true)
	for _step: int in WALK_STEPS:
		view.advance_animation(STEP_SECONDS)
	assert_eq([_visual_of(view).position, _visual_of(view).rotation, view.is_processing(), view.is_walking()], [Vector3.ZERO, Vector3.ZERO, false, true], "Sem quique nem inclinação nem processamento: a figura se anima sozinha.")


func test_attaching_to_a_body_that_is_already_walking_stops_the_capsule_and_starts_the_walk() -> void:
	var view: NpcView = _new_view()
	view.set_walking(true)
	view.advance_animation(STEP_SECONDS)
	assert_gt(_visual_of(view).position.y, 0.0, "A cápsula quicava.")
	var figure: Node3D = _synthetic_figure()
	view.attach_figure(figure)
	assert_eq([_visual_of(view).position, _visual_of(view).rotation, _visual_of(view).visible, view.is_processing()], [Vector3.ZERO, Vector3.ZERO, false, false], "Ao receber a figura a cápsula para onde estava.")
	_assert_playing(_player_of(figure), "walk", 1.0, "Andando sem velocidade conhecida")


func test_a_second_figure_replaces_the_first_frees_it_and_starts_from_the_state_of_the_body() -> void:
	var view: NpcView = _new_view()
	var first: Node3D = _synthetic_figure()
	var second: Node3D = _synthetic_figure()
	view.attach_figure(first)
	view.set_walking(true)
	view.set_speed(4.0)
	view.attach_figure(second)
	assert_eq([first.get_parent() == null, second.get_parent() == view, view.get_child_count()], [true, true, 2], "A antiga sai na hora: ficam só a parte visual e a figura nova.")
	assert_true(first.is_queued_for_deletion(), "E é liberada.")
	await wait_process_frames(2)
	assert_false(is_instance_valid(first))
	_assert_playing(_player_of(second), "jog", 4.0 / 4.1, "A nova começa pelo estado do corpo")
	assert_eq(view.speed_mps(), 4.0, "A velocidade é do corpo: trocar a figura não a zera.")


func test_a_null_or_already_parented_figure_is_refused_with_a_visible_error_and_nothing_changes() -> void:
	var view: NpcView = _new_view()
	var kept: Node3D = _synthetic_figure()
	view.attach_figure(kept)
	view.attach_figure(null)
	assert_push_error("sem pai")
	var parented: Node3D = _synthetic_figure()
	add_child_autofree(parented)
	view.attach_figure(parented)
	assert_push_error("sem pai")
	view.attach_figure(kept)
	assert_push_error("sem pai")
	assert_eq([view.has_figure(), kept.get_parent(), kept.is_queued_for_deletion(), parented.get_parent() == view], [true, view, false, false], "A figura que o corpo já tinha segue intacta.")


func test_only_a_player_that_is_a_direct_child_of_the_figure_is_used() -> void:
	var view: NpcView = _new_view()
	var wrapper: Node3D = Node3D.new()
	var inner: Node3D = _synthetic_figure()
	wrapper.add_child(inner)
	view.attach_figure(wrapper)
	view.set_walking(true)
	assert_eq(_player_of(inner).current_animation, "", "O player de um neto não é o da figura.")


func test_a_figure_without_a_player_is_shown_but_does_not_animate_and_one_freed_from_outside_leaves_a_consistent_body() -> void:
	var view: NpcView = _new_view()
	var bare: Node3D = Node3D.new()
	view.attach_figure(bare)
	view.set_walking(true)
	view.set_speed(4.0)
	assert_eq([view.has_figure(), _visual_of(view).visible, bare.get_parent()], [true, false, view], "Aparece, sem erro, e não anima.")
	bare.free()
	assert_false(view.has_figure(), "Liberada por fora: o corpo percebe.")
	view.clear_figure()
	assert_eq([_visual_of(view).visible, view.is_processing()], [true, true], "E limpar devolve a cápsula, andando.")
	view.attach_figure(_synthetic_figure())
	assert_eq([view.has_figure(), view.get_child_count(), _visual_of(view).visible], [true, 2, false], "E aceita outra figura.")


# ---------------------------------------------------------------------------------------------------- soltar a figura

func test_clear_removes_the_figure_at_once_frees_it_and_brings_back_the_capsule_in_the_state_of_the_body() -> void:
	var view: NpcView = _new_view()
	var figure: Node3D = _synthetic_figure()
	view.attach_figure(figure)
	view.set_walking(true)
	view.set_speed(4.0)
	view.clear_figure()
	assert_eq([view.has_figure(), figure.get_parent() == null, view.get_children().has(figure)], [false, true, false], "Some da lista de filhos NA HORA.")
	assert_true(figure.is_queued_for_deletion(), "E é liberada ao fim do quadro (estava na árvore).")
	await wait_process_frames(2)
	assert_false(is_instance_valid(figure))
	assert_eq([_visual_of(view).visible, view.speed_mps(), view.is_walking(), view.is_processing()], [true, 0.0, true, true], "A cápsula volta e a velocidade zera; o corpo segue andando, e a cápsula com ele.")
	assert_almost_eq(_visual_of(view).rotation.x, -deg_to_rad(4.0), TOLERANCE, "Inclinada como quem anda.")


func test_clearing_a_figure_of_a_body_outside_the_tree_frees_it_at_once() -> void:
	var view: NpcView = NpcView.new()
	autofree(view)
	var figure: Node3D = _synthetic_figure()
	view.attach_figure(figure)
	view.clear_figure()
	assert_false(is_instance_valid(figure), "Fora da árvore o `free` é imediato.")
	assert_eq([view.has_figure(), view.get_child_count(), _visual_of(view).visible], [false, 1, true])


func test_without_a_figure_the_new_calls_are_harmless_and_the_capsule_bounces_and_leans_as_always() -> void:
	var view: NpcView = _new_view()
	view.set_speed(3.0)
	view.clear_figure()
	assert_eq([view.has_figure(), view.speed_mps(), view.get_child_count(), _visual_of(view).visible], [false, 0.0, 1, true], "Limpar sem figura só zera a velocidade.")
	view.set_speed(4.0)
	view.set_walking(true)
	view.advance_animation(STEP_SECONDS)
	assert_almost_eq(_visual_of(view).rotation.x, -deg_to_rad(4.0), TOLERANCE, "Com velocidade e tudo, a cápsula inclina...")
	assert_gt(_visual_of(view).position.y, 0.0, "...e quica.")
	assert_true(view.is_processing())
	view.set_walking(false)
	assert_eq([_visual_of(view).position, _visual_of(view).rotation, view.is_processing()], [Vector3.ZERO, Vector3.ZERO, false])


func test_a_recycled_body_does_not_inherit_the_figure_and_the_pool_neither_leaks_nor_duplicates() -> void:
	var parent: Node3D = Node3D.new()
	add_child_autofree(parent)
	var pool: NpcViewPool = NpcViewPool.new(parent, SMALL_PREWARM)
	await wait_process_frames(1)
	var nodes_before: int = _monitor(Performance.OBJECT_NODE_COUNT)
	var orphans_before: int = _monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	var view: NpcView = pool.take(7, GROUND_M)
	var figure: Node3D = _synthetic_figure()
	view.attach_figure(figure)
	view.set_walking(true)
	view.set_speed(4.0)
	assert_true(pool.give_back(7))
	assert_eq([view.has_figure(), figure.get_parent() == null, view.speed_mps(), view.is_walking(), _visual_of(view).visible], [false, true, 0.0, false, true], "Devolver solta a figura na hora.")
	await wait_process_frames(2)
	assert_false(is_instance_valid(figure), "E a libera.")
	var again: NpcView = pool.take(9, OTHER_M)
	assert_same(again, view, "A reserva devolve o MESMO corpo...")
	assert_eq([again.has_figure(), again.get_child_count(), again.position], [false, 1, OTHER_M], "...sem figura.")
	assert_eq([pool.created, pool.free_count(), pool.active_count(), pool.lost_count(), parent.get_child_count()], [SMALL_PREWARM, SMALL_PREWARM - 1, 1, 0, SMALL_PREWARM], "A reserva não vaza nem duplica.")
	assert_eq([_monitor(Performance.OBJECT_NODE_COUNT), _monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)], [nodes_before, orphans_before], "Nenhum nó da figura ficou para trás.")


# ---------------------------------------------------------------------------------------------------- o clipe

func test_the_clip_and_the_scale_follow_the_body_speed_when_walking_and_a_stopped_body_is_idle() -> void:
	var view: NpcView = _new_view()
	var figure: Node3D = _synthetic_figure()
	view.attach_figure(figure)
	var player: AnimationPlayer = _player_of(figure)
	view.set_speed(0.0)
	_assert_playing(player, "idle", 1.0, "0 m/s, parado")
	view.set_speed(4.0)
	_assert_playing(player, "idle", 1.0, "Parado manda: a velocidade guardada não faz o corpo andar")
	view.set_walking(true)
	for row: Array in TABLE:
		var speed: float = row[0]
		view.set_speed(speed)
		_assert_playing(player, row[1], row[2], "Andando a %s m/s" % speed)
	view.set_walking(false)
	_assert_playing(player, "idle", 1.0, "Parou")


func test_walking_without_a_known_speed_plays_the_walk_at_scale_one_and_stopping_plays_idle() -> void:
	var view: NpcView = _new_view()
	var figure: Node3D = _synthetic_figure()
	view.attach_figure(figure)
	var player: AnimationPlayer = _player_of(figure)
	view.set_walking(true)
	_assert_playing(player, "walk", 1.0, "Só `set_walking`")
	for unknown: float in [0.0, -2.0, NAN, INF]:
		view.set_speed(4.0)
		view.set_speed(unknown)
		_assert_playing(player, "walk", 1.0, "Velocidade %s é desconhecida" % unknown)
	view.set_walking(false)
	_assert_playing(player, "idle", 1.0, "`set_walking(false)`")


func test_the_same_request_does_not_touch_the_player_and_a_new_scale_keeps_the_step_phase() -> void:
	var view: NpcView = _new_view()
	var figure: Node3D = _synthetic_figure()
	view.attach_figure(figure)
	var player: AnimationPlayer = _player_of(figure)
	view.set_walking(true)
	view.set_speed(1.0)
	player.advance(PHASE_SECONDS)
	var phase: float = player.current_animation_position
	assert_gt(phase, 0.0, "O passo andou.")
	view.set_speed(1.0)
	view.set_walking(true)
	assert_almost_eq(player.current_animation_position, phase, TOLERANCE, "Repetir o pedido não reinicia o passo.")
	view.set_speed(1.1)
	assert_almost_eq(player.current_animation_position, phase, TOLERANCE, "Só a escala mudou: o passo segue de onde estava.")
	assert_almost_eq(player.get_playing_speed(), 1.1 / 0.73, TOLERANCE, "E na escala nova.")
	player.play(&"jog", -1.0, SENTINEL_SCALE)
	view.set_speed(1.1)
	view.set_speed(1.1 + NOISE_MPS)
	view.set_walking(true)
	_assert_playing(player, "jog", SENTINEL_SCALE, "Pedido repetido ou com ruído abaixo da tolerância: o corpo não manda tocar (o que o player faz por fora segue)")
	view.set_speed(1.0)
	_assert_playing(player, "walk", 1.0 / 0.73, "Mudou de verdade: manda tocar")


func test_a_figure_without_the_speed_table_only_has_idle_and_walk_and_never_scales() -> void:
	var view: NpcView = _new_view()
	var figure: Node3D = _synthetic_figure({}, ["idle", "walk"])
	view.attach_figure(figure)
	var player: AnimationPlayer = _player_of(figure)
	view.set_walking(true)
	for speed: float in [0.5, 4.0, 32.0]:
		view.set_speed(speed)
		_assert_playing(player, "walk", 1.0, "%s m/s sem tabela" % speed)


func test_a_clip_the_player_does_not_have_is_skipped_without_error() -> void:
	var view: NpcView = _new_view()
	var figure: Node3D = _synthetic_figure(REAL, ["idle", "walk"])
	view.attach_figure(figure)
	view.set_walking(true)
	view.set_speed(4.0)
	_assert_playing(_player_of(figure), "walk", 1.0, "A tabela pede jog, o player não tem: fica no que tocava")
