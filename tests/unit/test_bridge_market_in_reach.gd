extends GutTest
## LW-106b: `SimBridge.peek_market_in_reach(actor_id)` (docs/modules/bridge.md, "Mercado ao alcance"): o mercado ao alcance do jogador, SÓ LEITURA, na posição GUARDADA no `character`. A REGRA e o alcance são do `world` (`MarketReach`, testado em `test_market_reach.gd`
## e, no `request_trade`, em `test_bridge_market_reach.gd`); aqui se confere só o que a ponte faz, sem janela e com a economia, o terreno e os locais REAIS (`data/economy`, `data/world`: três mercados, a centenas de metros uns dos outros): o `market_id` e o assentamento
## certos no centro de cada um, `PLACE_TOO_FAR` do `world` (sem tradução) longe e no nascimento, o `character` antes do alcance, os códigos da ponte, a equivalência com o `request_trade` numa grade de posições, a ordem crescente de `market_id` (com locais montados para
## deixar mais de um mercado ao alcance do mesmo ponto, o que os dados reais nunca fazem) e nenhuma mudança no estado. As distâncias são relativas ao alcance [HIP] do `world` (3 m): 2,0 m é perto e 3,5 m é longe; o limite sai da própria constante do `world`.

const WORLD_DIR: String = "res://data/world"
const SEED: int = 106
const MARKET_COUNT: int = 3
const BREAD: String = "bread"
const UNKNOWN_ID: int = 999999
const BUY: String = BridgePlayerEconomyReplies.SIDE_BUY
const SELL: String = BridgePlayerEconomyReplies.SIDE_SELL
## Distâncias (m) do centro do mercado: dentro e fora do alcance, o relato "longe" e o menor passo além do limite (1 mm).
const NEAR_M: float = 2.0
const FAR_M: float = 3.5
const REPORTED_FAR_M: float = 12.0
const LIMIT_STEP_M: float = 0.001
## A grade ao redor do centro de cada mercado: de -6 m a +6 m, de metro em metro, nos eixos x e z (passa do alcance de 3 m para os dois lados).
const GRID_RADIUS_M: int = 6

var _terrain: TerrainData
var _places: Array[Place] = []
var _market_places: Array[Place] = []
var _setup: EconomySetup
var _host: SimulationHostNode
var _bridge: SimBridge
var _economy: EconomyModule
var _actor_id: int = 0
var _spawn_position: Vector3


func before_all() -> void:
	var terrain_loaded: TerrainLoader.LoadResult = TerrainLoader.load_dir(WORLD_DIR)
	assert_true(terrain_loaded.result.ok, terrain_loaded.result.message)
	_terrain = terrain_loaded.terrain
	var settlements: SettlementLoader.LoadResult = SettlementLoader.load_dir(WORLD_DIR, _terrain)
	assert_true(settlements.result.ok, settlements.result.message)
	_places = settlements.places
	for place: Place in _places:
		if place.kind == Place.KIND_MARKET:
			_market_places.append(place)
	assert_eq(_market_places.size(), MARKET_COUNT, "Pré-condição dos dados: os locais reais têm três mercados.")
	_setup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR)
	assert_true(_setup.result.ok, _setup.result.message)


## Um jogo só com o personagem e a economia (sem NPCs), a ponte com os locais reais, o jogador nascido (no ponto de nascimento, longe de todo mercado) e com a conta aberta.
func before_each() -> void:
	_start_game()


func after_each() -> void:
	_finish_game()


func _start_game() -> void:
	_host = SimulationHostNode.new()
	_host.start_new_game(SEED, _terrain, [], null, 0, _setup)
	_bridge = SimBridge.new(_host, _terrain, _places)
	_economy = _host.economy
	_actor_id = _bridge.request_spawn_character().actor_id
	_spawn_position = _bridge.peek_character(_actor_id).position
	assert_true(_bridge.request_open_player_account(_actor_id).ok)


func _finish_game() -> void:
	_host.runner.finish()
	_host.free()


## Relata a posição do jogador pela ponte: o personagem GUARDA o valor, e é de lá que a ponte lê.
func _report(spot: Vector3) -> void:
	var reported: Result = _bridge.request_report_position(_actor_id, spot, 0.0)
	assert_true(reported.ok, reported.message)


func _market_id_of(settlement_id: String) -> int:
	return _economy.peek_market_of(settlement_id).market_id


func _market_before(first: Place, second: Place) -> bool:
	return _market_id_of(first.settlement_id) < _market_id_of(second.settlement_id)


## Os locais reais com os mercados dos ids dados levados para as posições dadas (o resto fica onde está).
func _with_markets_at(spots: Dictionary[String, Vector3]) -> Array[Place]:
	var moved: Array[Place] = []
	for place: Place in _places:
		moved.append(Place.new(place.id, place.settlement_id, place.kind, spots[place.id], place.capacity) if spots.has(place.id) else place)
	return moved


func _assert_too_far(reply: BridgePlayerEconomyReplies.MarketInReachReply, label: String) -> void:
	assert_false(reply.result.ok, label)
	assert_eq(reply.result.code, MarketReach.CODE_PLACE_TOO_FAR, label)


func _assert_in_reach(reply: BridgePlayerEconomyReplies.MarketInReachReply, market: Place, label: String) -> void:
	assert_true(reply.result.ok, "%s %s" % [label, reply.result.message])
	assert_eq([reply.market_id, reply.settlement_id], [_market_id_of(market.settlement_id), market.settlement_id], label)


## Tudo o que uma consulta NÃO pode mexer: o `state_hash`, o resumo do mundo (relógio, fila de eventos e módulos), o sorteio, os IDs, o save da economia e a posição guardada do personagem.
func _snapshot() -> Dictionary:
	var world: World = _host.runner.world
	var character: BridgeReplies.CharacterReply = _bridge.peek_character(_actor_id)
	return {
		"hash": world.state_hash(),
		"summary": world.debug_summary(),
		"pending_events": int(world.context.events.debug_summary()["pending"]),
		"rng": world.context.rng.debug_summary(),
		"ids": world.context.ids.debug_summary(),
		"economy": _economy.serialize(),
		"character": [character.position, character.yaw],
	}


func test_at_the_center_of_each_market_the_reply_is_ok_with_that_market_and_its_settlement() -> void:
	var listed: Dictionary[String, int] = {}
	for entry: BridgeEconomyReplies.EconomyMarketEntry in _bridge.peek_economy_markets().markets:
		listed[entry.settlement_id] = entry.market_id
	assert_eq(listed.size(), MARKET_COUNT, "Pré-condição dos dados: a economia lista três mercados.")
	var found: Array[int] = []
	for market: Place in _market_places:
		_report(market.position)
		var reply: BridgePlayerEconomyReplies.MarketInReachReply = _bridge.peek_market_in_reach(_actor_id)
		_assert_in_reach(reply, market, "No centro de %s." % market.id)
		assert_eq(reply.market_id, listed.get(market.settlement_id), "O mercado é o que `peek_economy_markets` lista para o assentamento de %s." % market.id)
		found.append(reply.market_id)
	found.sort()
	assert_eq(found.size(), MARKET_COUNT)
	assert_ne(found[0], found[1], "Os três mercados são diferentes (o teste distingue um do outro).")
	assert_ne(found[1], found[2], "Os três mercados são diferentes (o teste distingue um do outro).")


func test_the_reply_follows_the_stored_position_at_each_call_with_no_memory_of_the_last_one() -> void:
	var market: Place = _market_places[0]
	for step: int in range(2):
		_report(market.position)
		_assert_in_reach(_bridge.peek_market_in_reach(_actor_id), market, "Junto ao mercado (volta %d)." % step)
		_report(market.position + Vector3(REPORTED_FAR_M, 0.0, 0.0))
		_assert_too_far(_bridge.peek_market_in_reach(_actor_id), "A 12 m do mercado (volta %d)." % step)


func test_3_5_m_from_each_center_and_at_the_spawn_point_the_reply_is_place_too_far_from_the_world() -> void:
	_assert_too_far(_bridge.peek_market_in_reach(_actor_id), "Recém-nascido, sem ter relatado posição: o ponto de nascimento.")
	for market: Place in _market_places:
		var spawn_gap: float = Vector2(_spawn_position.x - market.position.x, _spawn_position.z - market.position.z).length()
		assert_gt(spawn_gap, FAR_M, "Pré-condição: o ponto de nascimento fica longe de %s." % market.id)
		_report(market.position + Vector3(FAR_M, 0.0, 0.0))
		_assert_too_far(_bridge.peek_market_in_reach(_actor_id), "A %s m do centro de %s." % [str(FAR_M), market.id])
	_report(_spawn_position)
	_assert_too_far(_bridge.peek_market_in_reach(_actor_id), "Relatado o ponto de nascimento.")


func test_the_limit_is_the_one_of_the_world_the_reach_passes_and_one_millimeter_more_does_not() -> void:
	assert_true(NEAR_M < MarketReach.MARKET_REACH_M and MarketReach.MARKET_REACH_M < FAR_M, "Pré-condição: o alcance [HIP] do `world` está entre as distâncias do teste; se mudou, ajuste NEAR_M e FAR_M.")
	for market: Place in _market_places:
		_report(market.position + Vector3(MarketReach.MARKET_REACH_M, 0.0, 0.0))
		_assert_in_reach(_bridge.peek_market_in_reach(_actor_id), market, "Exatamente no alcance de %s passa." % market.id)
		_report(market.position + Vector3(MarketReach.MARKET_REACH_M + LIMIT_STEP_M, 0.0, 0.0))
		_assert_too_far(_bridge.peek_market_in_reach(_actor_id), "Um milímetro além do alcance de %s recusa." % market.id)


func test_in_the_real_game_an_npc_a_loose_id_and_a_market_are_not_characters_even_at_a_market_center() -> void:
	var host: SimulationHostNode = SimulationHostNode.new()
	var app: GameAppNode = GameAppNode.new()
	app.bind_host(host)
	app.start_default_game(host)
	var bridge: SimBridge = app.peek_bridge()
	var player: int = bridge.request_spawn_character().actor_id
	assert_true(bridge.request_open_player_account(player).ok)
	_assert_too_far(bridge.peek_market_in_reach(player), "O nascimento do jogo real fica longe de todo mercado.")
	var market: Place = _market_places[0]
	assert_true(bridge.request_report_position(player, market.position, 0.0).ok)
	var market_id: int = host.economy.peek_market_of(market.settlement_id).market_id
	var in_reach: BridgePlayerEconomyReplies.MarketInReachReply = bridge.peek_market_in_reach(player)
	assert_true(in_reach.result.ok, in_reach.result.message)
	assert_eq([in_reach.market_id, in_reach.settlement_id], [market_id, market.settlement_id], "No centro do mercado do jogo real.")
	var npc_id: int = host.npc.peek_npc_ids()[0]
	for stranger: int in [npc_id, UNKNOWN_ID, market_id]:
		assert_eq(bridge.peek_market_in_reach(stranger).result.code, CharacterModule.CODE_UNKNOWN_ACTOR, "O ator %d (NPC, ID solto ou o mercado) não é um personagem." % stranger)
	app.free()
	host.runner.finish()
	host.free()


func test_the_bridge_codes_come_first_and_in_the_order_game_then_character_then_economy_even_at_a_market() -> void:
	_report(_market_places[0].position)
	var idle_host: SimulationHostNode = SimulationHostNode.new()
	assert_eq(SimBridge.new(idle_host, null, _places).peek_market_in_reach(_actor_id).result.code, SimBridge.CODE_NO_GAME, "Sem jogo.")
	idle_host.free()
	assert_eq(SimBridge.new(null, null, _places).peek_market_in_reach(_actor_id).result.code, SimBridge.CODE_NO_GAME, "Sem host.")
	var character: CharacterModule = _host.character
	_host.character = null
	_host.economy = null
	assert_eq(_bridge.peek_market_in_reach(_actor_id).result.code, SimBridge.CODE_NO_CHARACTER, "Sem personagem e sem economia: o do personagem vem primeiro.")
	_host.character = character
	assert_eq(_bridge.peek_market_in_reach(_actor_id).result.code, SimBridge.CODE_NO_ECONOMY, "Jogo sem o módulo da economia.")
	_host.economy = _economy
	assert_true(_bridge.peek_market_in_reach(_actor_id).result.ok, "Com os módulos de volta, a consulta funciona.")


func test_without_any_market_to_list_the_reply_is_place_too_far_even_at_a_market_center() -> void:
	_report(_market_places[0].position)
	var no_places: Array[Place] = []
	_assert_too_far(SimBridge.new(_host, _terrain, no_places).peek_market_in_reach(_actor_id), "A ponte sem locais não lista mercado algum.")
	var without_markets: Array[Place] = []
	for place: Place in _places:
		if place.kind != Place.KIND_MARKET:
			without_markets.append(place)
	_assert_too_far(SimBridge.new(_host, _terrain, without_markets).peek_market_in_reach(_actor_id), "Locais sem nenhum do tipo mercado.")


func test_on_a_grid_around_each_market_ok_means_a_valid_order_is_not_refused_for_distance() -> void:
	for index: int in range(_market_places.size()):
		if index > 0:
			_finish_game()
			_start_game()
		var market: Place = _market_places[index]
		var market_id: int = _market_id_of(market.settlement_id)
		# Compra e vende, alternando, para a grade inteira não gastar o dinheiro nem o peso do jogador: perto do mercado a ordem é sempre VÁLIDA.
		var holding: bool = false
		var inside: int = 0
		var outside: int = 0
		for dx: int in range(-GRID_RADIUS_M, GRID_RADIUS_M + 1):
			for dz: int in range(-GRID_RADIUS_M, GRID_RADIUS_M + 1):
				var label: String = "%s a (%d, %d) m do centro" % [market.id, dx, dz]
				_report(market.position + Vector3(dx, 0.0, dz))
				var reply: BridgePlayerEconomyReplies.MarketInReachReply = _bridge.peek_market_in_reach(_actor_id)
				var order: BridgePlayerEconomyReplies.PlayerTradeReply = _bridge.request_trade(_actor_id, market_id, BREAD, 1, SELL if holding else BUY)
				assert_eq(reply.result.ok, order.result.code != MarketReach.CODE_PLACE_TOO_FAR, "Ao alcance equivale a o `request_trade` não recusar por distância: %s." % label)
				if reply.result.ok:
					inside += 1
					_assert_in_reach(reply, market, "O mercado certo: %s." % label)
					assert_true(order.result.ok, "A ordem do teste é válida perto do mercado (%s): %s" % [label, order.result.message])
					if order.result.ok:
						holding = not holding
				else:
					outside += 1
					assert_eq(reply.result.code, MarketReach.CODE_PLACE_TOO_FAR, "Longe: %s." % label)
		assert_gt(inside, 0, "A grade de %s tem pontos ao alcance." % market.id)
		assert_gt(outside, 0, "A grade de %s tem pontos fora do alcance." % market.id)


func test_with_several_markets_in_reach_the_lowest_market_id_wins_not_the_nearest_nor_the_last() -> void:
	var by_id: Array[Place] = []
	by_id.assign(_market_places)
	by_id.sort_custom(_market_before)
	var low: Place = by_id[0]
	var mid: Place = by_id[1]
	var high: Place = by_id[2]
	var spot: Vector3 = high.position
	_report(spot)
	var all_three: Dictionary[String, Vector3] = {low.id: spot, mid.id: spot, high.id: spot}
	_assert_in_reach(SimBridge.new(_host, _terrain, _with_markets_at(all_three)).peek_market_in_reach(_actor_id), low, "Os três mercados no mesmo ponto: vale o de menor `market_id`.")
	var upper_two: Dictionary[String, Vector3] = {mid.id: spot, high.id: spot}
	_assert_in_reach(SimBridge.new(_host, _terrain, _with_markets_at(upper_two)).peek_market_in_reach(_actor_id), mid, "O de menor id está longe: vale o menor id ENTRE os que estão ao alcance.")
	var low_is_farthest: Dictionary[String, Vector3] = {low.id: spot + Vector3(NEAR_M, 0.0, 0.0), mid.id: spot, high.id: spot}
	_assert_in_reach(SimBridge.new(_host, _terrain, _with_markets_at(low_is_farthest)).peek_market_in_reach(_actor_id), low, "O de menor id é o mais longe (ainda ao alcance): vale ele, não o mais perto.")
	var low_out_of_reach: Dictionary[String, Vector3] = {low.id: spot + Vector3(FAR_M, 0.0, 0.0), mid.id: spot + Vector3(NEAR_M, 0.0, 0.0), high.id: spot}
	_assert_in_reach(SimBridge.new(_host, _terrain, _with_markets_at(low_out_of_reach)).peek_market_in_reach(_actor_id), mid, "O de menor id passa do alcance: vale o seguinte por id, não o mais perto.")


func test_the_query_changes_neither_the_hash_the_events_the_rng_the_ids_the_economy_nor_the_character() -> void:
	var spots: Array[Vector3] = [_spawn_position]
	for market: Place in _market_places:
		spots.append(market.position)
		spots.append(market.position + Vector3(FAR_M, 0.0, 0.0))
	for spot: Vector3 in spots:
		_report(spot)
		var before: Dictionary = _snapshot()
		for actor: int in [_actor_id, UNKNOWN_ID]:
			_bridge.peek_market_in_reach(actor)
		assert_eq(_snapshot(), before, "Consultar a partir de %s não muda nada." % str(spot))


func test_a_character_without_an_open_account_also_gets_the_market() -> void:
	var unopened: int = _bridge.request_spawn_character().actor_id
	assert_eq(_bridge.peek_player_economy(unopened).result.code, EconomyCodes.UNKNOWN_OWNER, "Pré-condição: o segundo personagem não abriu conta.")
	assert_true(_bridge.request_report_position(unopened, _market_places[0].position, 0.0).ok)
	_assert_in_reach(_bridge.peek_market_in_reach(unopened), _market_places[0], "Sem conta aberta, junto ao mercado.")


func test_the_reply_has_neither_a_place_nor_a_text_key() -> void:
	var names: Array[String] = []
	# Variant: `get_property_list()` devolve dicionários, e o nome é conferido por conversão.
	for property: Dictionary in _bridge.peek_market_in_reach(_actor_id).get_property_list():
		names.append(str(property["name"]))
	assert_true(names.has("result") and names.has("market_id") and names.has("settlement_id"), "Pré-condição: a resposta tem `result`, `market_id` e `settlement_id`.")
	assert_false(names.has("place_id") or names.has("text_key"), "O contrato não dá à resposta `place_id` nem `text_key`.")
