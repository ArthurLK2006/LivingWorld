extends GutTest
## LW-099d: a DESPEDIDA do corpo do NPC que parte com caravana (`NpcBodiesView.set_departure_fade`), sem janela, com uma ponte que devolve a lista de corpos e as caravanas que o teste manda (e o terreno real só para o formato) e um terreno que sempre tem o chunk desenhado.
## Cobre: desligada (o padrão) o corpo sai no mesmo quadro de sempre e as caravanas nem são consultadas; ligada, quem sai POR TER CARAVANA (em viagem ou parada) fica onde está por 0,4 s, cada vez mais transparente, e só então volta à reserva; quem sai por outro motivo volta NA HORA e UMA consulta
## cobre todos os que saíram no quadro (a reserva não cresce numa troca grande); quem já está em despedida não consulta de novo; consulta que falha manda todos de volta; voltar à lista cancela; `release`, `setup` e desligar a opção encerram a despedida com os corpos opacos; o laço de visibilidade vale para o corpo em despedida.
## Os instantes usam passos de 0,1 s e 0,2 s (somas que não dependem do arredondamento do ponto flutuante no prazo de 0,4 s).

const EPS: float = 0.0001
const HELD: String = BridgeReplies.CaravanBodyReply.STATE_HELD

var _data: NpcLifeCheck.GameData
var _bridge: ScriptedBridge
var _terrain: DrawnTerrain
var _view: NpcBodiesView


## A ponte do teste: a lista de corpos e as linhas de caravana são as que o teste põe, e a consulta das caravanas é contada (ou falha, se mandarem).
class ScriptedBridge:
	extends SimBridge

	var npc_rows: Array[BridgeReplies.NpcBodyReply] = []
	var caravan_rows: Array[BridgeReplies.CaravanBodyReply] = []
	var caravan_queries: int = 0
	var caravans_fail: bool = false

	func request_set_bodies_available(_available: bool) -> Result:
		return Result.success()

	func peek_npc_bodies() -> BridgeReplies.NpcBodiesReply:
		return BridgeReplies.NpcBodiesReply.new(Result.success(), npc_rows)

	func peek_caravan_bodies() -> BridgeReplies.CaravanBodiesReply:
		caravan_queries += 1
		if caravans_fail:
			return BridgeReplies.CaravanBodiesReply.new(Result.failure("TEST_CARAVANS_DOWN", "ponte de teste fora do ar."), [])
		return BridgeReplies.CaravanBodiesReply.new(Result.success(), caravan_rows)


## O terreno do teste: o chunk está desenhado ou não conforme `drawn`.
class DrawnTerrain:
	extends TerrainView

	var drawn: bool = true

	func has_chunk(_coord: Vector2i) -> bool:
		return drawn


func before_all() -> void:
	_data = NpcLifeCheck.load_game_data()
	assert_eq(_data.problem, "", "Os dados reais do jogo carregam.")


func after_each() -> void:
	if _view != null:
		_view.release()
	_view = null


## A view ligada à ponte do teste, sem `_process` (o teste avança o tempo) e SEM tocar na opção da despedida: o que o teste vê é o PADRÃO.
func _start_default() -> void:
	_bridge = ScriptedBridge.new(null, _data.terrain, _data.places)
	_terrain = DrawnTerrain.new()
	add_child_autofree(_terrain)
	_view = NpcBodiesView.new()
	add_child_autofree(_view)
	_view.set_process(false)
	assert_true(_view.setup(_bridge, _terrain))


## O mesmo, com a opção da despedida posta em `fade`.
func _start(fade: bool = true) -> void:
	_start_default()
	_view.set_departure_fade(fade)


## Os NPCs que a ponte lista agora e a view em dia.
func _list(ids: Array[int]) -> void:
	_bridge.npc_rows.clear()
	for npc_id: int in ids:
		_bridge.npc_rows.append(BridgeReplies.NpcBodyReply.new(npc_id, Vector3(float(npc_id) * 3.0, 10.0, 5.0)))
	_view.reconcile()


## Os comerciantes com caravana agora, no estado `state`.
func _travelling(ids: Array[int], state: String = BridgeReplies.CaravanBodyReply.STATE_TRAVELLING) -> void:
	_bridge.caravan_rows.clear()
	for trader_id: int in ids:
		var row: BridgeReplies.CaravanBodyReply = BridgeReplies.CaravanBodyReply.new()
		row.trader_id = trader_id
		row.state = state
		_bridge.caravan_rows.append(row)


func _capsule_fade(view: NpcView) -> float:
	return (view.get_node(NodePath("%s/%s" % [NpcView.VISUAL_NAME, NpcView.CAPSULE_NAME])) as GeometryInstance3D).transparency


func test_off_by_default_a_leaver_goes_back_in_the_same_frame_and_the_caravans_are_never_asked() -> void:
	_start_default()
	assert_false(_view.departure_fade_enabled(), "nasce desligada (o teste não tocou na opção)")
	_travelling([2])
	_list([1, 2, 3])
	_list([1, 3])
	assert_eq([_view.active_ids(), _view.fading_ids()], [[1, 3] as Array[int], [] as Array[int]], "o corpo do NPC com caravana sai no mesmo quadro, como antes")
	assert_eq([_bridge.caravan_queries, _view.pool().returned, _view.pool().lost_count()], [0, 1, 0], "nenhuma consulta a mais")
	var fresh: NpcBodiesView = NpcBodiesView.new()
	add_child_autofree(fresh)
	assert_false(fresh.departure_fade_enabled(), "o padrão de uma view nova também")


func test_a_leaver_with_a_caravan_stays_where_it_is_fades_and_goes_back_after_0_4_seconds() -> void:
	_start()
	_travelling([2])
	_list([1, 2, 3])
	var body: NpcView = _view.pool().body_of(2)
	var stand: Vector3 = body.position
	_list([1, 3])
	assert_eq([_view.active_ids(), _view.fading_ids()], [[1, 2, 3] as Array[int], [2] as Array[int]], "o corpo segue na lista dos ativos e em `fading_ids`")
	assert_same(_view.pool().body_of(2), body, "o mesmo corpo, no mesmo lugar")
	assert_eq([body.fade(), body.visible, body.position], [0.0, true, stand], "começa opaco, visível e onde estava")
	assert_eq([_bridge.caravan_queries, _view.pool().returned], [1, 0], "UMA consulta das caravanas e nada devolvido ainda")
	_view.advance_departures(0.1)
	assert_almost_eq(body.fade(), 0.25, EPS, "a 0,1 s, um quarto")
	assert_almost_eq(_capsule_fade(body), 0.25, EPS, "e a cápsula de fato")
	_view.advance_departures(0.1)
	assert_almost_eq(body.fade(), 0.5, EPS, "a 0,2 s, a metade")
	_view.advance_departures(0.1)
	assert_almost_eq(body.fade(), 0.75, EPS, "a 0,3 s, três quartos")
	assert_eq([body.position, body.visible, _view.fading_ids()], [stand, true, [2] as Array[int]], "sempre no mesmo lugar, ainda na tela e em despedida")
	_view.advance_departures(0.2)
	assert_eq([_view.active_ids(), _view.fading_ids(), _view.pool().returned, _view.pool().lost_count()], [[1, 3] as Array[int], [] as Array[int], 1, 0], "passados 0,4 s o corpo volta à reserva (nada se perde)")
	assert_eq([body.fade(), _capsule_fade(body), body.visible, _view.pool().free_count()], [0.0, 0.0, false, NpcViewPool.PREWARM_COUNT - 2], "opaco e escondido na reserva, que tem de volta o corpo")


func test_a_leaver_without_a_caravan_goes_back_at_once_one_query_covers_everyone_and_a_big_swap_does_not_grow_the_pool() -> void:
	_start()
	_travelling([2])
	_list([1, 2, 3])
	_list([])
	assert_eq([_view.active_ids(), _view.fading_ids(), _view.pool().returned, _bridge.caravan_queries], [[2] as Array[int], [2] as Array[int], 2, 1], "dos três que saíram só o com caravana fica; os outros voltam na hora; UMA consulta para os três")
	_start()
	_travelling([])
	var first: Array[int] = []
	var second: Array[int] = []
	for npc_id: int in range(1, 51):
		first.append(npc_id)
		second.append(npc_id + 50)
	_list(first)
	var asked: int = _bridge.caravan_queries
	_list(second)
	assert_eq([_bridge.caravan_queries - asked, _view.fading_ids(), _view.active_ids().size()], [1, [] as Array[int], 50], "troca grande (50 saem, 50 entram): uma consulta, ninguém em despedida")
	assert_eq([_view.pool().created, _view.pool().empty_hits, _view.pool().lost_count()], [NpcViewPool.PREWARM_COUNT, 0, 0], "e a reserva não cresceu")


func test_held_caravans_count_who_is_in_despedida_is_not_asked_again_and_a_failed_query_sends_everyone_back() -> void:
	_start()
	_travelling([2], HELD)
	_list([1, 2])
	_list([1])
	assert_eq(_view.fading_ids(), [2] as Array[int], "caravana parada (`held`) também é caravana")
	var asked: int = _bridge.caravan_queries
	for _frame: int in 3:
		_view.reconcile()
	assert_eq(_bridge.caravan_queries, asked, "quem já está em despedida não consulta de novo")
	_list([])
	assert_eq([_bridge.caravan_queries - asked, _view.fading_ids(), _view.active_ids()], [1, [2] as Array[int], [2] as Array[int]], "um NPC novo que sai gera UMA consulta (volta na hora, sem caravana); o 2 segue em despedida")
	_start()
	_travelling([2])
	_list([1, 2])
	_bridge.caravans_fail = true
	_list([1])
	assert_eq([_view.active_ids(), _view.fading_ids(), _view.pool().returned], [[1] as Array[int], [] as Array[int], 1], "consulta que falha: todo mundo volta na hora, como sem a despedida")


func test_coming_back_to_the_list_cancels_the_departure_and_the_body_is_opaque_again() -> void:
	_start()
	_travelling([2])
	_list([1, 2, 3])
	var body: NpcView = _view.pool().body_of(2)
	_list([1, 3])
	_view.advance_departures(0.2)
	assert_almost_eq(body.fade(), 0.5, EPS, "a meio caminho")
	_list([1, 2, 3])
	assert_eq([_view.fading_ids(), body.fade(), _capsule_fade(body)], [[] as Array[int], 0.0, 0.0], "voltou à lista: a despedida é cancelada e o corpo, opaco")
	assert_same(_view.pool().body_of(2), body, "é o mesmo corpo (nada de corpo duplicado)")
	_view.advance_departures(5.0)
	assert_eq([_view.active_ids(), _view.pool().taken, _view.pool().duplicate_requests, _view.pool().returned], [[1, 2, 3] as Array[int], 3, 0, 0], "e o tempo que passa depois não o devolve")


func test_release_setup_and_turning_the_option_off_end_the_departures_with_opaque_bodies() -> void:
	_start()
	_travelling([2])
	_list([1, 2, 3])
	var body: NpcView = _view.pool().body_of(2)
	_list([1, 3])
	_view.advance_departures(0.1)
	_view.release()
	assert_eq([_view.active_ids(), _view.fading_ids(), body.fade(), _view.pool().returned, _view.pool().lost_count(), _view.is_active()], [[] as Array[int], [] as Array[int], 0.0, 3, 0, false], "`release` no meio da despedida: tudo volta à reserva, opaco")
	_view.advance_departures(1.0)
	assert_true(_view.fading_ids().is_empty(), "e o tempo que passa depois não faz nada")
	_start()
	_travelling([2])
	_list([1, 2, 3])
	_list([1, 3])
	_view.advance_departures(0.1)
	assert_true(_view.setup(_bridge, _terrain), "outro `setup` no meio da despedida")
	assert_eq([_view.fading_ids(), _view.active_ids(), _view.pool().created, _view.departure_fade_enabled()], [[] as Array[int], [] as Array[int], NpcViewPool.PREWARM_COUNT, true], "reserva nova, sem despedida; a opção sobrevive ao `setup`")
	_start()
	_travelling([2])
	_list([1, 2, 3])
	body = _view.pool().body_of(2)
	_list([1, 3])
	_view.advance_departures(0.1)
	_view.set_departure_fade(false)
	assert_eq([_view.active_ids(), _view.fading_ids(), body.fade(), _view.pool().returned], [[1, 3] as Array[int], [] as Array[int], 0.0, 1], "desligar a opção encerra a despedida: o corpo volta à reserva, opaco")
	_list([1])
	assert_eq([_view.active_ids(), _bridge.caravan_queries], [[1] as Array[int], 1], "e desligada, quem sai volta na hora, sem consultar as caravanas (a única consulta foi a de antes)")
	var fresh: NpcBodiesView = NpcBodiesView.new()
	add_child_autofree(fresh)
	fresh.set_departure_fade(true)
	fresh.set_departure_fade(false)
	fresh.advance_departures(1.0)
	assert_eq(fresh.fading_ids(), [] as Array[int], "ligar e desligar a opção numa view sem `setup` não quebra")


func test_the_chunk_visibility_loop_covers_the_fading_body() -> void:
	_start()
	_travelling([2])
	_list([1, 2, 3])
	var body: NpcView = _view.pool().body_of(2)
	_list([1, 3])
	assert_true(body.visible, "terreno desenhado: o corpo em despedida se vê")
	_terrain.drawn = false
	_view.reconcile()
	assert_eq([body.visible, _view.fading_ids()], [false, [2] as Array[int]], "sem o terreno do chunk ele se esconde, e a despedida segue")
	_terrain.drawn = true
	_view.reconcile()
	assert_true(body.visible, "e volta a aparecer com o terreno")


func test_odd_deltas_are_ignored_and_the_real_process_advances_the_departure() -> void:
	_start()
	_view.advance_departures(1.0)
	assert_eq(_view.fading_ids(), [] as Array[int], "sem despedida o tempo não faz nada")
	_travelling([2])
	_list([1, 2, 3])
	var body: NpcView = _view.pool().body_of(2)
	_list([1, 3])
	_view.advance_departures(NAN)
	_view.advance_departures(-3.0)
	_view.advance_departures(0.0)
	assert_eq([body.fade(), _view.fading_ids()], [0.0, [2] as Array[int]], "NaN, negativo e zero não andam")
	_view.set_process(true)
	await wait_process_frames(3)
	assert_true(not _view.fading_ids().has(2) or body.fade() > 0.0, "os quadros reais (delta > 0) fazem a despedida andar")


func test_the_departure_ends_exactly_at_0_4_seconds_and_not_a_moment_before() -> void:
	_start()
	_travelling([2])
	_list([1, 2, 3])
	var early: NpcView = _view.pool().body_of(2)
	_list([1, 3])
	_view.advance_departures(0.2)
	_view.advance_departures(0.19)
	assert_eq([_view.fading_ids(), _view.active_ids()], [[2] as Array[int], [1, 2, 3] as Array[int]], "aos 0,39 s o corpo ainda está em despedida")
	assert_almost_eq(early.fade(), 0.975, EPS, "quase invisível, mas ainda ali")
	_start()
	_travelling([2])
	_list([1, 2, 3])
	var exact: NpcView = _view.pool().body_of(2)
	_list([1, 3])
	_view.advance_departures(0.2)
	_view.advance_departures(0.2)
	assert_eq([_view.fading_ids(), _view.active_ids(), _view.pool().returned, exact.visible, exact.fade()], [[] as Array[int], [1, 3] as Array[int], 1, false, 0.0], "aos 0,4 s EXATOS (dois passos de 0,2 s, soma exata em double) o corpo já voltou à reserva, opaco e escondido")


func test_a_departure_whose_caravan_row_vanishes_but_who_is_not_listed_again_still_ends_at_0_4_seconds() -> void:
	_start()
	_travelling([2])
	_list([1, 2, 3])
	var body: NpcView = _view.pool().body_of(2)
	_list([1, 3])
	assert_eq([_view.is_departing(2), _view.is_departing(1), _view.is_departing(99)], [true, false, false], "`is_departing` só vale para quem está em despedida")
	var asked: int = _bridge.caravan_queries
	_travelling([])
	_list([1, 3])
	assert_eq([_view.fading_ids(), _bridge.caravan_queries], [[2] as Array[int], asked], "a linha da caravana sumiu da consulta, mas o NPC não voltou à lista: a despedida segue e ninguém é consultado de novo")
	_view.advance_departures(0.1)
	assert_almost_eq(body.fade(), 0.25, EPS, "a despedida segue na curva")
	_view.advance_departures(0.4)
	assert_eq([_view.active_ids(), _view.fading_ids(), body.fade(), body.visible, _view.pool().returned, _view.pool().lost_count()], [[1, 3] as Array[int], [] as Array[int], 0.0, false, 1, 0], "no fim dos 0,4 s o corpo volta, opaco e escondido, sem vazar")
	assert_eq([_view.pool().free_count(), _view.is_departing(2)], [NpcViewPool.PREWARM_COUNT - 2, false], "e a reserva fica com ele de volta")


func test_the_same_npc_departing_again_after_a_cancel_starts_a_new_departure_from_zero() -> void:
	_start()
	_travelling([2])
	_list([1, 2, 3])
	var body: NpcView = _view.pool().body_of(2)
	_list([1, 3])
	_view.advance_departures(0.2)
	assert_almost_eq(body.fade(), 0.5, EPS, "a primeira despedida está na metade")
	_list([1, 2, 3])
	assert_eq([_view.fading_ids(), body.fade()], [[] as Array[int], 0.0], "cancelada: opaco de novo")
	_list([1, 3])
	assert_eq([_view.fading_ids(), body.fade(), _bridge.caravan_queries], [[2] as Array[int], 0.0, 2], "partiu de novo: nova despedida, do ZERO (opaco), com nova consulta")
	_view.advance_departures(0.1)
	assert_almost_eq(body.fade(), 0.25, EPS, "a conta de tempo também recomeçou (nada herdado dos 0,2 s da primeira)")
	assert_same(_view.pool().body_of(2), body)
	_view.advance_departures(0.4)
	assert_eq([_view.active_ids(), _view.pool().returned, _view.pool().lost_count(), _view.pool().duplicate_requests], [[1, 3] as Array[int], 1, 0, 0], "e a segunda despedida termina no prazo, devolvendo UM corpo")


func test_leaving_the_tree_in_the_middle_of_a_departure_returns_every_body_opaque_and_leaves_no_orphan() -> void:
	_start()
	_travelling([2])
	_list([1, 2, 3])
	var pool: NpcViewPool = _view.pool()
	var body: NpcView = pool.body_of(2)
	_list([1, 3])
	_view.advance_departures(0.1)
	assert_gt(body.fade(), 0.0, "premissa: o corpo está no meio da despedida")
	var orphans_before: int = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	remove_child(_view)
	assert_eq([_view.is_active(), _view.fading_ids(), body.fade(), body.visible, pool.active_count(), pool.returned, pool.lost_count()], [false, [] as Array[int], 0.0, false, 0, 3, 0], "`_exit_tree` no meio da despedida: tudo volta à reserva, opaco e escondido")
	_view.free()
	_view = null
	assert_eq(int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)), orphans_before, "liberada a view, nenhum órfão novo")
