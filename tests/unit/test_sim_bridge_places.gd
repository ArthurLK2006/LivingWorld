extends GutTest
## LW-074: a ponte expõe todos os locais (`peek_places`) em cópias, em ordem crescente de id e com a altura do terreno. Sem janela.

const BLOCKOUT_DIR: String = "res://data/world"
const HEIGHT_TOLERANCE_M: float = 0.001
const CHANGED_CAPACITY: int = 99

var _terrain: TerrainData
var _places: Array[Place] = []


func before_all() -> void:
	var terrain_loaded: TerrainLoader.LoadResult = TerrainLoader.load_dir(BLOCKOUT_DIR)
	assert_true(terrain_loaded.result.ok, terrain_loaded.result.message)
	_terrain = terrain_loaded.terrain
	var loaded: SettlementLoader.LoadResult = SettlementLoader.load_dir(BLOCKOUT_DIR, _terrain)
	assert_true(loaded.result.ok, loaded.result.message)
	_places = loaded.places


func test_every_place_comes_back_in_ascending_id_order_with_the_data_and_the_ground_height() -> void:
	var bridge: SimBridge = SimBridge.new(null, _terrain, _places)
	var reply: BridgeReplies.PlacesReply = bridge.peek_places()
	assert_true(reply.result.ok, reply.result.message)
	var expected_ids: Array[String] = []
	var originals: Dictionary[String, Place] = {}
	for place: Place in _places:
		expected_ids.append(place.id)
		originals[place.id] = place
	expected_ids.sort()
	var got_ids: Array[String] = []
	for copy: BridgeReplies.PlaceReply in reply.places:
		got_ids.append(copy.id)
		var original: Place = originals[copy.id]
		assert_eq([copy.settlement_id, copy.kind, copy.x, copy.z, copy.capacity], [original.settlement_id, original.kind, original.position.x, original.position.z, original.capacity])
		assert_almost_eq(copy.y, bridge.peek_height(copy.x, copy.z).height_m, HEIGHT_TOLERANCE_M, "A altura é a do terreno.")
	assert_eq(got_ids, expected_ids, "O arquivo não está em ordem de id; a ponte entrega em ordem crescente.")


func test_the_reply_is_a_copy_and_emptying_the_input_list_does_not_change_the_bridge() -> void:
	var given: Array[Place] = []
	given.assign(_places)
	var bridge: SimBridge = SimBridge.new(null, _terrain, given)
	bridge.peek_places().places[0].capacity = CHANGED_CAPACITY
	given.clear()
	var again: BridgeReplies.PlacesReply = bridge.peek_places()
	assert_eq(again.places.size(), _places.size())
	assert_ne(again.places[0].capacity, CHANGED_CAPACITY, "Mexer na cópia não altera a próxima resposta.")


func test_without_places_the_list_is_empty_and_without_terrain_it_fails_with_the_bridge_code() -> void:
	var empty: BridgeReplies.PlacesReply = SimBridge.new(null, _terrain).peek_places()
	assert_true(empty.result.ok, empty.result.message)
	assert_eq(empty.places.size(), 0)
	var without_terrain: BridgeReplies.PlacesReply = SimBridge.new(null, null, _places).peek_places()
	assert_eq(without_terrain.result.code, SimBridge.CODE_NO_TERRAIN)
	assert_string_contains(without_terrain.result.message, "peek_places")
	assert_eq(without_terrain.places.size(), 0)


func test_the_real_boot_gives_the_game_bridge_all_the_places_of_the_data() -> void:
	var reply: BridgeReplies.PlacesReply = (get_node("/root/GameApp") as GameAppNode).peek_bridge().peek_places()
	assert_true(reply.result.ok, reply.result.message)
	assert_eq(reply.places.size(), _places.size(), "O GameApp leu settlements.json e places.json ao iniciar o jogo.")
