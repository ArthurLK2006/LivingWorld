extends GutTest
## LW-072a: a ponte entrega à apresentação os CORPOS que ela deve manter (os NPCs em S0) e repassa o interruptor de corpos ao `npc`. Sem
## janela, com os dados reais do jogo (terreno, assentamentos e os 100 NPCs). A ponte não tem regra de jogo: quem decide quem está em S0 é o
## LOD do `npc` (testado em test_npc_lod.gd); aqui se confere o repasse, que a lista é exatamente o conjunto S0 em ordem crescente, as unidades
## (metros e altura do terreno), que são cópias e os códigos de falha.

const DATA_DIR: String = "res://data"
const WORLD_SEED: int = 5
## Assentamento A: centro em (320, 540) m, e o jogador a 30 m dele. B: centro em (800, 660) m. Um ponto longe dos dois (mais de 120 m de todo NPC).
const NEAR_A_M: Vector3 = Vector3(350.0, 10.0, 540.0)
const NEAR_B_M: Vector3 = Vector3(830.0, 10.0, 660.0)
const FAR_FROM_BOTH_M: Vector3 = Vector3(600.0, 10.0, 900.0)
const MAX_S0: int = 50
const TOLERANCE_M: float = 0.001
const CM_PER_METER: float = 100.0

var _terrain: TerrainData
var _points: Array[PointOfInterest] = []
var _settlements: Array[Settlement] = []
var _places: Array[Place] = []
var _host: SimulationHostNode
var _bridge: SimBridge


func before_all() -> void:
	var data: NpcLifeCheck.GameData = NpcLifeCheck.load_game_data()
	assert_eq(data.problem, "", "Os dados reais do jogo carregam.")
	_terrain = data.terrain
	_points = data.points
	_settlements = data.settlements
	_places = data.places


func before_each() -> void:
	var setup: NpcSetup = NpcSetup.from_dir(DATA_DIR, SettlementService.new(_settlements, _places))
	assert_true(setup.result.ok, setup.result.message)
	_host = SimulationHostNode.new()
	_host.start_new_game(WORLD_SEED, _terrain, _points, setup)
	_bridge = SimBridge.new(_host, _terrain, _places, _host.npc)


func after_each() -> void:
	if _host.runner != null:
		_host.runner.finish()
	_host.free()


## Ator que relata `focus_m` pela ponte (o foco do LOD vale desde o relato) e um passo, que reclassifica os NPCs.
func _report_focus_and_step(actor_id: int, focus_m: Vector3) -> void:
	var reported: Result = _bridge.request_report_position(actor_id, focus_m, 0.0)
	assert_true(reported.ok, reported.message)
	_host.runner.step_once()


func _spawned_actor() -> int:
	var spawned: BridgeReplies.SpawnCharacterReply = _bridge.request_spawn_character()
	assert_true(spawned.result.ok, spawned.result.message)
	return spawned.actor_id


func _bodies() -> BridgeReplies.NpcBodiesReply:
	var listed: BridgeReplies.NpcBodiesReply = _bridge.peek_npc_bodies()
	assert_true(listed.result.ok, listed.result.message)
	return listed


func _body_ids(listed: BridgeReplies.NpcBodiesReply) -> Array[int]:
	var ids: Array[int] = []
	for body: BridgeReplies.NpcBodyReply in listed.bodies:
		ids.append(body.npc_id)
	return ids


func _switch_on() -> void:
	var switched: Result = _bridge.request_set_bodies_available(true)
	assert_true(switched.ok, switched.message)


# ---------------------------------------------------------------------------------------------------- o interruptor

func test_the_game_is_born_without_bodies_and_the_list_stays_empty_next_to_the_settlement() -> void:
	var actor_id: int = _spawned_actor()
	_report_focus_and_step(actor_id, NEAR_A_M)
	assert_eq(_host.npc.lod.focus_count(), 1, "O foco chegou ao LOD pela ponte.")
	var listed: BridgeReplies.NpcBodiesReply = _bodies()
	assert_eq(listed.bodies.size(), 0, "Antes de a apresentação ligar os corpos ninguém está em S0, mesmo com o jogador a 30 m.")
	assert_eq(_host.npc.lod.s0_ids().size(), 0)


func test_turning_the_bodies_on_is_forwarded_to_the_npc_module_and_repeating_it_is_accepted() -> void:
	assert_false(_host.npc.debug_summary()["bodies_available"], "O jogo nasce sem corpos.")
	_switch_on()
	assert_true(_host.npc.debug_summary()["bodies_available"], "O interruptor chegou ao `npc`.")
	assert_true(_bridge.request_set_bodies_available(true).ok, "Repetir o estado atual é aceito.")
	assert_true(_bridge.request_set_bodies_available(false).ok)
	assert_false(_host.npc.debug_summary()["bodies_available"], "E desligar também chega ao `npc`.")


func test_the_failure_of_the_npc_module_comes_back_as_it_is() -> void:
	var loose_module: NpcModule = NpcModule.new()
	var bridge: SimBridge = SimBridge.new(_host, _terrain, _places, loose_module)
	var switched: Result = bridge.request_set_bodies_available(true)
	assert_false(switched.ok, "Módulo sem setup() recusa o interruptor.")
	assert_eq(switched.code, NpcModule.CODE_NOT_READY, "E o código é o do `npc`, sem tradução.")


# ---------------------------------------------------------------------------------------------------- a lista de corpos

func test_with_the_bodies_on_the_list_is_the_s0_set_in_ascending_order_with_ground_height() -> void:
	_switch_on()
	_report_focus_and_step(_spawned_actor(), NEAR_A_M)
	var s0_ids: Array[int] = _host.npc.lod.s0_ids()
	var listed: BridgeReplies.NpcBodiesReply = _bodies()
	assert_gt(s0_ids.size(), 0, "Com o jogador a 30 m do assentamento há NPCs com corpo.")
	assert_lte(s0_ids.size(), MAX_S0, "E nunca mais que o limite de S0.")
	assert_eq(_body_ids(listed), s0_ids, "A lista de corpos é exatamente o conjunto S0, em ordem crescente de NPC.")
	for body: BridgeReplies.NpcBodyReply in listed.bodies:
		var spot_cm: Vector2i = _host.npc.lod.position_of(body.npc_id)
		assert_almost_eq(body.position.x, float(spot_cm.x) / CM_PER_METER, TOLERANCE_M, "x em metros, do LOD (NPC %d)." % body.npc_id)
		assert_almost_eq(body.position.z, float(spot_cm.y) / CM_PER_METER, TOLERANCE_M, "z em metros, do LOD (NPC %d)." % body.npc_id)
		var ground: BridgeReplies.HeightReply = _bridge.peek_height(body.position.x, body.position.z)
		assert_true(ground.result.ok, ground.result.message)
		assert_almost_eq(body.position.y, ground.height_m, TOLERANCE_M, "y é a altura do terreno ali (NPC %d)." % body.npc_id)


func test_the_bodies_are_copies_and_changing_them_does_not_touch_the_simulation() -> void:
	_switch_on()
	_report_focus_and_step(_spawned_actor(), NEAR_A_M)
	var first: BridgeReplies.NpcBodiesReply = _bodies()
	assert_gt(first.bodies.size(), 0)
	var kept_id: int = first.bodies[0].npc_id
	var kept_position: Vector3 = first.bodies[0].position
	first.bodies[0].position = Vector3(-1.0, -1.0, -1.0)
	first.bodies[0].npc_id = -1
	first.bodies.clear()
	var second: BridgeReplies.NpcBodiesReply = _bodies()
	assert_eq(second.bodies[0].npc_id, kept_id, "Mexer na cópia não mexe no que a ponte entrega depois.")
	assert_eq(second.bodies[0].position, kept_position)
	assert_eq(_body_ids(second), _host.npc.lod.s0_ids(), "Nem no LOD.")
	assert_ne(_bodies().bodies[0], second.bodies[0], "Cada consulta entrega objetos novos.")


func test_turning_the_bodies_off_empties_the_list_and_turning_them_on_again_brings_them_back() -> void:
	_switch_on()
	_report_focus_and_step(_spawned_actor(), NEAR_A_M)
	var before: Array[int] = _body_ids(_bodies())
	assert_gt(before.size(), 0)
	assert_true(_bridge.request_set_bodies_available(false).ok)
	assert_eq(_bodies().bodies.size(), 0, "Desligar tira todos os corpos na hora (o `npc` solta todos de S0).")
	assert_eq(_host.npc.lod.s0_ids().size(), 0)
	_host.runner.step_once()
	assert_eq(_bodies().bodies.size(), 0, "E o passo seguinte não os traz de volta com o interruptor desligado.")
	_switch_on()
	_host.runner.step_once()
	assert_eq(_body_ids(_bodies()), _host.npc.lod.s0_ids(), "Ligar de novo traz de volta o conjunto S0 (os focos ficaram guardados).")
	assert_gt(_bodies().bodies.size(), 0)


func test_the_list_follows_the_player_around_and_never_passes_the_limit() -> void:
	_switch_on()
	var actor_id: int = _spawned_actor()
	var stops: Array[Vector3] = [NEAR_A_M, FAR_FROM_BOTH_M, NEAR_B_M, FAR_FROM_BOTH_M, NEAR_A_M]
	var sizes: Array[int] = []
	for focus_m: Vector3 in stops:
		_report_focus_and_step(actor_id, focus_m)
		var listed: BridgeReplies.NpcBodiesReply = _bodies()
		assert_eq(_body_ids(listed), _host.npc.lod.s0_ids(), "A lista é o conjunto S0 em %s." % str(focus_m))
		assert_lte(listed.bodies.size(), MAX_S0)
		sizes.append(listed.bodies.size())
	assert_gt(sizes[0], 0, "Junto de A há corpos.")
	assert_eq(sizes[1], 0, "Longe dos dois assentamentos não há nenhum.")
	assert_gt(sizes[2], 0, "Junto de B há corpos (outros NPCs).")
	assert_eq(sizes[3], 0)
	assert_gt(sizes[4], 0, "E voltando a A eles voltam.")


# ---------------------------------------------------------------------------------------------------- falhas

func test_a_bridge_without_terrain_fails_the_list_with_no_terrain_and_returns_no_bodies() -> void:
	var bridge: SimBridge = SimBridge.new(_host, null, _places, _host.npc)
	var listed: BridgeReplies.NpcBodiesReply = bridge.peek_npc_bodies()
	assert_false(listed.result.ok)
	assert_eq(listed.result.code, SimBridge.CODE_NO_TERRAIN)
	assert_eq(listed.bodies.size(), 0)


func test_a_bridge_without_the_npc_module_fails_both_calls_with_no_npc() -> void:
	var bridge: SimBridge = SimBridge.new(_host, _terrain, _places)
	var listed: BridgeReplies.NpcBodiesReply = bridge.peek_npc_bodies()
	assert_eq(listed.result.code, SimBridge.CODE_NO_NPC)
	assert_eq(listed.bodies.size(), 0)
	assert_eq(bridge.request_set_bodies_available(true).code, SimBridge.CODE_NO_NPC)


func test_a_bridge_with_neither_reports_the_terrain_first_on_the_list_and_the_npc_on_the_switch() -> void:
	var bridge: SimBridge = SimBridge.new(null, null)
	assert_eq(bridge.peek_npc_bodies().result.code, SimBridge.CODE_NO_TERRAIN)
	assert_eq(bridge.request_set_bodies_available(true).code, SimBridge.CODE_NO_NPC)
