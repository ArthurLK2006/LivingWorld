extends GutTest
## LW-099d (revisão R8): o corpo em DESPEDIDA (a partida da caravana, 0,4 s) NÃO é interativo: a `InteractionView` escolhe o NPC mais perto entre os corpos visíveis que NÃO estão em despedida (`NpcBodiesView.is_departing`). Jogo real de res://data
## (a ponte real, só com a lista de corpos e as caravanas roteirizadas), o jogador em pé num ponto longe dos povoados (nenhum ponto de interesse por perto) e dois NPCs a 1 m e a 2 m dele. Chama `_choose_target` direto: o alvo é privado e a
## `InteractionView` não ganhou API nova. Controle: sem o filtro, o corpo em despedida (1 m) seria o alvo.

const DATA_DIR: String = "res://data"
const WORLD_SEED: int = 5
const START_MIN: int = 7 * SimClock.MINUTES_PER_HOUR
const SPOT_M: Vector3 = Vector3(700.0, 10.0, 960.0)
const CLOSE_ID: int = 11
const NEXT_ID: int = 12
const CLOSE_M: float = 1.0
const NEXT_M: float = 2.0

var _data: NpcLifeCheck.GameData
var _texts: UiText
var _host: SimulationHostNode
var _bridge: ScriptedBridge
var _bodies: NpcBodiesView
var _view: InteractionView


## A ponte do teste: a lista de corpos e as linhas de caravana são as que o teste põe; o resto é o jogo real.
class ScriptedBridge:
	extends SimBridge

	var npc_rows: Array[BridgeReplies.NpcBodyReply] = []
	var caravan_rows: Array[BridgeReplies.CaravanBodyReply] = []

	func request_set_bodies_available(_available: bool) -> Result:
		return Result.success()

	func peek_npc_bodies() -> BridgeReplies.NpcBodiesReply:
		return BridgeReplies.NpcBodiesReply.new(Result.success(), npc_rows)

	func peek_caravan_bodies() -> BridgeReplies.CaravanBodiesReply:
		return BridgeReplies.CaravanBodiesReply.new(Result.success(), caravan_rows)


## O terreno do teste: o chunk está sempre desenhado (todo corpo é visível).
class DrawnTerrain:
	extends TerrainView

	func has_chunk(_coord: Vector2i) -> bool:
		return true


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


## O jogo real, a view dos corpos (sem `_process`; a opção da despedida em `fade`) e a `InteractionView` ligada a ela, com o jogador em `SPOT_M`.
func _start(fade: bool) -> void:
	var setup: NpcSetup = NpcSetup.from_dir(DATA_DIR, SettlementService.new(_data.settlements, _data.places))
	assert_true(setup.result.ok, setup.result.message)
	_host = SimulationHostNode.new()
	_host.start_new_game(WORLD_SEED, _data.terrain, _data.points, setup, START_MIN)
	_bridge = ScriptedBridge.new(_host, _data.terrain, _data.places, _host.npc)
	var terrain: DrawnTerrain = DrawnTerrain.new()
	add_child_autofree(terrain)
	_bodies = NpcBodiesView.new()
	add_child_autofree(_bodies)
	_bodies.set_process(false)
	assert_true(_bodies.setup(_bridge, terrain))
	_bodies.set_departure_fade(fade)
	var player: PlayerBody = PlayerBody.new()
	add_child_autofree(player)
	player.global_position = SPOT_M
	var prompt: Label = Label.new()
	var result: Label = Label.new()
	add_child_autofree(prompt)
	add_child_autofree(result)
	_view = InteractionView.new()
	add_child_autofree(_view)
	assert_true(_view.setup(_bridge, player, terrain, _texts, prompt, result))
	_view.set_process(false)
	_view.set_npc_bodies(_bodies)


## A ponte lista estes NPCs (CLOSE_ID a 1 m do jogador, os outros a 2 m) e a view dos corpos fica em dia.
func _list(ids: Array[int]) -> void:
	_bridge.npc_rows.clear()
	for npc_id: int in ids:
		_bridge.npc_rows.append(BridgeReplies.NpcBodyReply.new(npc_id, SPOT_M + Vector3(CLOSE_M if npc_id == CLOSE_ID else NEXT_M, 0.0, 0.0)))
	_bodies.reconcile()


## O comerciante CLOSE_ID passa a ter caravana.
func _give_caravan_to_the_close_one() -> void:
	var row: BridgeReplies.CaravanBodyReply = BridgeReplies.CaravanBodyReply.new()
	row.trader_id = CLOSE_ID
	_bridge.caravan_rows.append(row)


## [tipo do alvo, id do NPC] como a `InteractionView` escolhe agora.
func _target() -> Array:
	var target: InteractionTarget = _view._choose_target()
	return [target.kind, target.npc_id]


func test_without_a_departure_the_nearest_body_is_the_target_as_always_with_the_option_on_or_off() -> void:
	for fade: bool in [true, false]:
		_start(fade)
		_list([CLOSE_ID, NEXT_ID])
		assert_eq(_target(), [InteractionTarget.Kind.NPC, CLOSE_ID], "O corpo mais perto (1 m) é o alvo; opção da despedida: %s." % fade)
		assert_eq([_bodies.is_departing(CLOSE_ID), _bodies.is_departing(NEXT_ID)], [false, false], "Ninguém em despedida.")
		after_each()


func test_a_body_in_departure_is_not_a_target_and_the_second_nearest_one_is() -> void:
	_start(true)
	_give_caravan_to_the_close_one()
	_list([CLOSE_ID, NEXT_ID])
	_list([NEXT_ID])
	var leaving: NpcView = _bodies.pool().body_of(CLOSE_ID)
	assert_true(_bodies.is_departing(CLOSE_ID) and leaving != null and leaving.visible, "Premissa: o comerciante que parte segue na tela, em despedida, a 1 m do jogador.")
	var control: InteractionTarget = InteractionTarget.choose(Vector2(SPOT_M.x, SPOT_M.z), [] as Array[BridgeReplies.PointReply], {CLOSE_ID: leaving.global_position, NEXT_ID: _bodies.pool().body_of(NEXT_ID).global_position})
	assert_eq(control.npc_id, CLOSE_ID, "Controle: sem o filtro o corpo em despedida (o mais perto) seria o alvo.")
	assert_eq(_target(), [InteractionTarget.Kind.NPC, NEXT_ID], "Em despedida ele NÃO é alvo; o segundo mais perto passa a ser.")
	_bodies.advance_departures(0.2)
	assert_eq(_target(), [InteractionTarget.Kind.NPC, NEXT_ID], "No meio da despedida nada muda.")
	_bodies.advance_departures(0.4)
	assert_eq([_bodies.is_departing(CLOSE_ID), _bodies.pool().body_of(CLOSE_ID)], [false, null], "Terminada a despedida o corpo voltou à reserva...")
	assert_eq(_target(), [InteractionTarget.Kind.NPC, NEXT_ID], "...e o alvo segue o mesmo: nada muda.")


func test_a_lone_body_in_departure_leaves_nothing_to_talk_to() -> void:
	_start(true)
	_give_caravan_to_the_close_one()
	_list([CLOSE_ID])
	_list([])
	assert_true(_bodies.is_departing(CLOSE_ID), "Premissa: o único corpo ao alcance está em despedida.")
	assert_eq(_target(), [InteractionTarget.Kind.NONE, IdGenerator.NO_ID], "Sem mais ninguém, não há alvo.")
