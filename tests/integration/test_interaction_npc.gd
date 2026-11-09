extends GutTest
## LW-083e: a mesma tecla `interact` alcança o ponto de interesse OU o NPC (InteractionTarget e InteractionView), sem janela. A escolha pura (o mais perto vence, o
## NPC ganha o empate exato, alcance de 3 m) é testada à mão; a tela, com o jogo real de res://data às 07:00 (a ponte real, os 100 NPCs, a NpcBodiesView e o PlayerBody):
## o texto mostrado é o da chave da resposta, o NPC para, a pausa não envia nada e, sem `set_npc_bodies`, o NPC é ignorado. O que a conversa faz no mundo é do npc.

const DATA_DIR: String = "res://data"
const WORLD_SEED: int = 5
const START_MIN: int = 7 * SimClock.MINUTES_PER_HOUR
const A_M: Vector3 = Vector3(320.0, 10.0, 540.0)
const WARMUP_MIN: int = 30
const HUGE_BUDGET_MS: float = 1.0e9
const COLLISION_FRAMES: int = 4
const REACH_M: float = 3.0
const CLOSE_M: float = 1.5
const WORK: String = "work"
const TALK: String = "talk_player"
const ORIGIN: Vector2 = Vector2(10.0, 10.0)

var _data: NpcLifeCheck.GameData
var _texts: UiText
var _host: SimulationHostNode
var _bridge: SimBridge
var _terrain_view: TerrainView
var _bodies: NpcBodiesView
var _player: PlayerBody
var _reference: Node3D
var _prompt: Label
var _result: Label
var _view: InteractionView
var _npc_id: int = 0


func before_all() -> void:
	_data = NpcLifeCheck.load_game_data()
	assert_eq(_data.problem, "", "Os dados reais do jogo carregam.")
	var loaded: UiText.LoadResult = UiText.from_file(UiText.DEFAULT_PATH)
	assert_true(loaded.result.ok, loaded.result.message)
	_texts = loaded.texts


func after_each() -> void:
	if _host != null:
		_bodies.release()
		_host.runner.finish()
		_host.free()
	_host = null


## Um ponto de interesse à mão (alcance de 3 m, o de InteractionService).
func _point(point_id: String, east_m: float) -> BridgeReplies.PointReply:
	return BridgeReplies.PointReply.new(PointOfInterest.new(point_id, "marker", Vector3(ORIGIN.x + east_m, 0.0, ORIGIN.y), "poi.test_marker_near"))


func _npc_at(east_m: float) -> Vector3:
	return Vector3(ORIGIN.x + east_m, 0.0, ORIGIN.y)


# ---------------------------------------------------------------------------------------------------- a escolha pura

func test_the_nearest_inside_the_reach_wins_and_the_npc_wins_the_exact_tie() -> void:
	var points: Array[BridgeReplies.PointReply] = [_point("poi_a", 2.0)]
	var closer_npc: InteractionTarget = InteractionTarget.choose(ORIGIN, points, {7: _npc_at(1.0)})
	assert_eq([closer_npc.kind, closer_npc.npc_id, closer_npc.point_id], [InteractionTarget.Kind.NPC, 7, "poi_a"], "NPC mais perto: o NPC vence, e o ponto segue dado como o mais próximo dos pontos.")
	var closer_point: InteractionTarget = InteractionTarget.choose(ORIGIN, points, {7: _npc_at(2.5)})
	assert_eq([closer_point.kind, closer_point.point_id], [InteractionTarget.Kind.POINT, "poi_a"], "Ponto mais perto: o ponto vence.")
	var tie: InteractionTarget = InteractionTarget.choose(ORIGIN, points, {7: _npc_at(2.0)})
	assert_eq([tie.kind, tie.npc_id], [InteractionTarget.Kind.NPC, 7], "Empate exato: o NPC ganha.")
	var two_npcs: InteractionTarget = InteractionTarget.choose(ORIGIN, [] as Array[BridgeReplies.PointReply], {9: _npc_at(1.0), 8: _npc_at(-1.0)})
	assert_eq(two_npcs.npc_id, 9, "Dois NPCs à mesma distância: vence o primeiro da lista.")


func test_the_npc_reach_is_three_meters_inclusive_and_nothing_outside_is_a_target() -> void:
	assert_eq(InteractionTarget.NPC_REACH_M, NpcPlayerTalk.TALK_REACH_M, "A dica da tela usa o mesmo alcance da simulação.")
	var none: Array[BridgeReplies.PointReply] = []
	assert_eq(InteractionTarget.choose(ORIGIN, none, {7: _npc_at(REACH_M)}).kind, InteractionTarget.Kind.NPC, "Exatamente 3,00 m alcança.")
	var outside: InteractionTarget = InteractionTarget.choose(ORIGIN, [_point("poi_far", 4.0)] as Array[BridgeReplies.PointReply], {7: _npc_at(REACH_M + 0.01)})
	assert_eq([outside.kind, outside.point_id], [InteractionTarget.Kind.NONE, ""], "Além do alcance, nem NPC nem ponto.")
	assert_eq(InteractionTarget.choose(ORIGIN, none, {}).kind, InteractionTarget.Kind.NONE)


# ---------------------------------------------------------------------------------------------------- a tela

## O jogo real às 07:00 com o jogador em A e a view ligada; anda 30 min até haver NPCs em S0 e põe o jogador a 1,5 m de um deles que esteja trabalhando.
func _start(link_bodies: bool = true) -> void:
	var setup: NpcSetup = NpcSetup.from_dir(DATA_DIR, SettlementService.new(_data.settlements, _data.places))
	assert_true(setup.result.ok, setup.result.message)
	_host = SimulationHostNode.new()
	_host.start_new_game(WORLD_SEED, _data.terrain, _data.points, setup, START_MIN)
	_bridge = SimBridge.new(_host, _data.terrain, _data.places, _host.npc)
	_reference = Node3D.new()
	add_child_autofree(_reference)
	_terrain_view = TerrainView.new()
	add_child_autofree(_terrain_view)
	_terrain_view.setup(_bridge)
	_terrain_view.set_process(false)
	_bodies = NpcBodiesView.new()
	add_child_autofree(_bodies)
	assert_true(_bodies.setup(_bridge, _terrain_view))
	_terrain_view.set_focus(A_M)
	_terrain_view.process_budget(HUGE_BUDGET_MS)
	for _frame: int in COLLISION_FRAMES:
		await get_tree().physics_frame
	_player = PlayerBody.new()
	add_child_autofree(_player)
	assert_true(_player.setup(_bridge, _terrain_view, _reference))
	for _minute: int in WARMUP_MIN:
		assert_true(_bridge.request_report_position(_player.get_actor_id(), A_M, 0.0).ok)
		_host.runner.step_once()
		_bodies.reconcile()
	for candidate: int in _host.npc.lod.s0_ids():
		if _npc_id == 0 and _host.npc.peek_npc(candidate).action_id == WORK:
			_npc_id = candidate
	assert_ne(_npc_id, 0, "Há um NPC com corpo trabalhando junto de A.")
	var spot: Vector3 = _bodies.pool().body_of(_npc_id).global_position + Vector3(CLOSE_M, 0.0, 0.0)
	_terrain_view.set_focus(spot)
	_terrain_view.process_budget(HUGE_BUDGET_MS)
	_bodies.reconcile()
	_prompt = Label.new()
	_result = Label.new()
	add_child_autofree(_prompt)
	add_child_autofree(_result)
	_view = InteractionView.new()
	add_child_autofree(_view)
	assert_true(_view.setup(_bridge, _player, _terrain_view, _texts, _prompt, _result))
	if link_bodies:
		_view.set_npc_bodies(_bodies)
	_player.global_position = spot
	assert_true(_bridge.request_report_position(_player.get_actor_id(), spot, 0.0).ok)
	_view.refresh()


func test_interacting_next_to_an_npc_starts_the_talk_and_shows_the_text_of_the_reply_key() -> void:
	await _start()
	assert_true(_prompt.visible, "Junto do NPC o aviso aparece.")
	assert_true(_view.interact(), "A conversa começou.")
	assert_eq(_result.text, _texts.get_text(NpcPlayerTalk.TEXT_KEY_FIRST), "O texto é o da chave da conversa (first).")
	assert_eq([_host.npc.peek_npc(_npc_id).action_id, _host.npc.peek_npc(_npc_id).tier], [TALK, NpcState.TIER_NOTABLE], "O NPC parou para conversar e virou T2.")
	assert_false(_view.interact(), "Logo depois o NPC não atende de novo.")
	assert_eq(_result.text, _texts.get_text("npc.talk.cooldown"), "O texto da recusa é o da chave do código (cooldown).")


func test_a_paused_clock_sends_nothing_and_shows_nothing() -> void:
	await _start()
	assert_true(_bridge.request_pause(true).ok)
	var before: String = JSON.stringify(_host.npc.serialize())
	assert_false(_view.interact())
	assert_false(_result.visible, "Nada na tela.")
	assert_eq(JSON.stringify(_host.npc.serialize()), before, "E nada foi enviado à simulação.")


func test_without_the_bodies_linked_the_npc_is_ignored() -> void:
	await _start(false)
	assert_false(_prompt.visible, "Sem set_npc_bodies o aviso não aparece por causa de NPC.")
	assert_eq(_view.nearest_point_id(), "", "E não há ponto por perto.")
	assert_false(_view.interact(), "A tecla cai no comportamento antigo (nenhum ponto ao alcance: a falha de sempre).")
	assert_ne(_host.npc.peek_npc(_npc_id).action_id, TALK, "O NPC não parou.")
