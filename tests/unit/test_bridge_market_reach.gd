extends GutTest
## LW-105d: a ponte COORDENA a proximidade do mercado no `request_trade` do jogador (docs/modules/bridge.md, "Proximidade do mercado"). A REGRA e o alcance são do `world` (`MarketReach`, testado em `test_market_reach.gd`); aqui se confere só o
## que a ponte faz, sem janela e com a economia, o terreno e os locais REAIS (`data/economy`, `data/world`; o mercado `a_market_01` fica em 313,00 m x 556,00 m): longe devolve o código do `world` (`PLACE_TOO_FAR`) com a chave
## `economy.trade.too_far` e NADA muda; perto compra e vende; a ordem das verificações; a posição vem do personagem; nenhum evento novo. As distâncias são relativas ao alcance [HIP] do `world` (3 m): 2,0 m é perto, 3,5 m é longe e o
## limite sai da própria constante, então ajustar o alcance depois de jogar só pede rever NEAR_M e FAR_M.

const WORLD_DIR: String = "res://data/world"
const GAME_VERSION: String = "0.0.1-test"
const SEED: int = 105
const SETTLEMENT: String = "test_settlement_a"
const MARKET_PLACE_ID: String = "a_market_01"
const BREAD: String = "bread"
const TOOL: String = "tool"
const UNKNOWN_ID: int = 999999
const TOOLS_TOO_MANY: int = 5
const TOO_FAR_KEY: String = "economy.trade.too_far"
const BUY: String = BridgePlayerEconomyReplies.SIDE_BUY
const SELL: String = BridgePlayerEconomyReplies.SIDE_SELL
## Distâncias (m) do centro do mercado: dentro e fora do alcance, o relato "longe" do teste da posição guardada e o menor passo além do limite (1 mm).
const NEAR_M: float = 2.0
const FAR_M: float = 3.5
const REPORTED_FAR_M: float = 12.0
const LIMIT_STEP_M: float = 0.001

var _terrain: TerrainData
var _places: Array[Place] = []
var _setup: EconomySetup
var _center: Vector3
var _host: SimulationHostNode
var _bridge: SimBridge
var _economy: EconomyModule
var _actor_id: int = 0
var _market_id: int = 0
var _spawn_position: Vector3
var _codec: JsonSaveCodec = JsonSaveCodec.new()


func before_all() -> void:
	var terrain_loaded: TerrainLoader.LoadResult = TerrainLoader.load_dir(WORLD_DIR)
	assert_true(terrain_loaded.result.ok, terrain_loaded.result.message)
	_terrain = terrain_loaded.terrain
	var settlements: SettlementLoader.LoadResult = SettlementLoader.load_dir(WORLD_DIR, _terrain)
	assert_true(settlements.result.ok, settlements.result.message)
	_places = settlements.places
	for place: Place in _places:
		if place.id == MARKET_PLACE_ID:
			_center = place.position
	_setup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR)
	assert_true(_setup.result.ok, _setup.result.message)


## Um jogo só com o personagem e a economia (sem NPCs), a ponte com os locais reais, o jogador nascido (no ponto de nascimento, longe do mercado) e com a conta aberta.
func before_each() -> void:
	_host = SimulationHostNode.new()
	_host.start_new_game(SEED, _terrain, [], null, 0, _setup)
	_bridge = SimBridge.new(_host, _terrain, _places)
	_economy = _host.economy
	_actor_id = _bridge.request_spawn_character().actor_id
	_spawn_position = _bridge.peek_character(_actor_id).position
	assert_true(_bridge.request_open_player_account(_actor_id).ok)
	_market_id = _economy.peek_market_of(SETTLEMENT).market_id


func after_each() -> void:
	_host.runner.finish()
	_host.free()


## Relata a posição do ator pela ponte: o personagem GUARDA o valor, e é de lá que a ponte lê.
func _report(actor_id: int, spot: Vector3) -> void:
	var reported: Result = _bridge.request_report_position(actor_id, spot, 0.0)
	assert_true(reported.ok, reported.message)


## O jogador a `distance_m` metros do centro do mercado, no eixo x (a altura não conta para o alcance).
func _stand_at(distance_m: float) -> void:
	_report(_actor_id, _center + Vector3(distance_m, 0.0, 0.0))


func _trade(actor_id: int, good_id: String, quantity: int, side: String) -> BridgePlayerEconomyReplies.PlayerTradeReply:
	return _bridge.request_trade(actor_id, _market_id, good_id, quantity, side)


func _buy(quantity: int) -> BridgePlayerEconomyReplies.PlayerTradeReply:
	return _trade(_actor_id, BREAD, quantity, BUY)


func _sell(quantity: int) -> BridgePlayerEconomyReplies.PlayerTradeReply:
	return _trade(_actor_id, BREAD, quantity, SELL)


## Tudo o que uma ordem pode mexer, numa cópia: os dois saldos, o estoque do mercado, o inventário e o peso do jogador e o `state_hash` do mundo.
func _state() -> Dictionary:
	var inventory: EconomyReplies.InventoryQuery = _economy.peek_inventory(_actor_id)
	return {
		"player_balance": _economy.peek_balance(_actor_id).balance,
		"market_balance": _economy.peek_balance(_market_id).balance,
		"market_stock": _economy.peek_stock(_market_id, BREAD).value,
		"inventory": inventory.rows,
		"weight": inventory.weight,
		"hash": _host.runner.world.state_hash(),
	}


## A recusa por distância: o código do `world` SEM tradução, a chave própria e nada negociado.
func _assert_too_far(reply: BridgePlayerEconomyReplies.PlayerTradeReply, label: String) -> void:
	assert_eq([reply.result.code, reply.text_key, reply.quantity, reply.total], [MarketReach.CODE_PLACE_TOO_FAR, TOO_FAR_KEY, 0, 0], label)


func test_inside_the_reach_the_player_buys_and_sells_and_the_books_move() -> void:
	_stand_at(NEAR_M)
	var before: Dictionary = _state()
	var bought: BridgePlayerEconomyReplies.PlayerTradeReply = _buy(2)
	assert_true(bought.result.ok, bought.result.message)
	assert_eq(bought.text_key, BridgePlayerEconomyReplies.PlayerTradeReply.KEY_BOUGHT)
	var after_buy: Dictionary = _state()
	var unit_weight: int = _economy.peek_good(BREAD).weight
	assert_eq([after_buy["player_balance"], after_buy["market_stock"], after_buy["weight"]], [before["player_balance"] - bought.total, before["market_stock"] - 2, 2 * unit_weight], "Perto, a compra mexeu no saldo, no estoque e no peso.")
	assert_ne(after_buy["inventory"], before["inventory"], "O pão entrou no inventário.")
	var sold: BridgePlayerEconomyReplies.PlayerTradeReply = _sell(1)
	assert_true(sold.result.ok, sold.result.message)
	assert_eq(sold.text_key, BridgePlayerEconomyReplies.PlayerTradeReply.KEY_SOLD)
	var after_sell: Dictionary = _state()
	assert_eq([after_sell["player_balance"], after_sell["market_stock"], after_sell["weight"]], [after_buy["player_balance"] + sold.total, after_buy["market_stock"] + 1, unit_weight], "Perto, a venda também.")


func test_outside_the_reach_both_sides_are_refused_with_the_too_far_key_and_nothing_changes() -> void:
	assert_gt(_spawn_position.distance_to(_center), FAR_M, "Pré-condição: o ponto de nascimento fica longe do mercado.")
	_stand_at(NEAR_M)
	assert_true(_buy(2).result.ok, "Pré-condição: o jogador compra perto e passa a ter pão para vender.")
	for spot: Vector3 in [_center + Vector3(FAR_M, 0.0, 0.0), _spawn_position]:
		_report(_actor_id, spot)
		var before: Dictionary = _state()
		_assert_too_far(_buy(1), "Comprar em %s." % str(spot))
		_assert_too_far(_sell(1), "Vender em %s." % str(spot))
		assert_eq(_state(), before, "Saldos, estoque, inventário, peso e `state_hash` ficam iguais em %s." % str(spot))


func test_the_limit_is_exact_so_the_reach_passes_and_one_millimeter_more_is_refused() -> void:
	assert_true(NEAR_M < MarketReach.MARKET_REACH_M and MarketReach.MARKET_REACH_M < FAR_M, "Pré-condição: o alcance [HIP] do `world` está entre as distâncias do teste; se mudou, ajuste NEAR_M e FAR_M.")
	_stand_at(MarketReach.MARKET_REACH_M)
	var at_limit: BridgePlayerEconomyReplies.PlayerTradeReply = _buy(1)
	assert_true(at_limit.result.ok, "Exatamente no alcance passa: %s" % at_limit.result.message)
	_stand_at(MarketReach.MARKET_REACH_M + LIMIT_STEP_M)
	_assert_too_far(_buy(1), "Um milímetro além do alcance recusa.")


func test_an_unknown_market_returns_what_the_economy_returns_near_or_far_and_never_too_far() -> void:
	for distance: float in [NEAR_M, FAR_M]:
		_stand_at(distance)
		var direct: Result = _economy.request_trade(_actor_id, UNKNOWN_ID, BREAD, 1, BUY).result
		var reply: BridgePlayerEconomyReplies.PlayerTradeReply = _bridge.request_trade(_actor_id, UNKNOWN_ID, BREAD, 1, BUY)
		assert_eq(direct.code, EconomyCodes.UNKNOWN_MARKET, "Pré-condição: a economia recusa o mercado que não existe.")
		assert_eq([reply.result.code, reply.result.message, reply.text_key], [direct.code, direct.message, BridgePlayerEconomyReplies.PlayerTradeReply.FALLBACK_KEY], "A ponte não responde: devolve o que a economia devolve, a %s m do mercado dos dados." % str(distance))


func test_the_order_of_the_checks_is_the_character_then_the_reach_then_the_economy() -> void:
	var unopened: int = _bridge.request_spawn_character().actor_id
	var quote: EconomyReplies.QuoteQuery = _economy.peek_quote(_actor_id, _market_id, TOOL, TOOLS_TOO_MANY, BUY)
	assert_true(quote.result.ok and quote.total > _economy.peek_balance(_actor_id).balance, "Pré-condição dos dados: %d ferramentas custam mais do que o jogador tem." % TOOLS_TOO_MANY)
	_stand_at(FAR_M)
	_report(unopened, _center + Vector3(FAR_M, 0.0, 0.0))
	for stranger: int in [UNKNOWN_ID, _market_id]:
		assert_eq(_trade(stranger, BREAD, 1, BUY).result.code, CharacterModule.CODE_UNKNOWN_ACTOR, "O ator %d não é um personagem: isso vence a distância." % stranger)
	_assert_too_far(_trade(_actor_id, TOOL, TOOLS_TOO_MANY, BUY), "Longe e sem dinheiro: a distância vence.")
	_assert_too_far(_trade(unopened, BREAD, 1, BUY), "Longe e sem conta: a distância vence.")
	_stand_at(NEAR_M)
	_report(unopened, _center + Vector3(NEAR_M, 0.0, 0.0))
	assert_eq(_trade(_actor_id, TOOL, TOOLS_TOO_MANY, BUY).result.code, EconomyCodes.INSUFFICIENT_FUNDS, "Perto e sem dinheiro: o erro é o da economia.")
	assert_eq(_trade(unopened, BREAD, 1, BUY).result.code, EconomyCodes.UNKNOWN_OWNER, "Perto e sem conta: o erro é o da economia.")


func test_without_a_game_a_character_or_the_economy_the_bridge_codes_come_first_even_far_from_the_market() -> void:
	var idle_host: SimulationHostNode = SimulationHostNode.new()
	assert_eq(SimBridge.new(idle_host, null, _places).request_trade(_actor_id, _market_id, BREAD, 1, BUY).result.code, SimBridge.CODE_NO_GAME, "Sem jogo.")
	idle_host.free()
	var character: CharacterModule = _host.character
	_host.character = null
	assert_eq(_buy(1).result.code, SimBridge.CODE_NO_CHARACTER, "Jogo sem o módulo do personagem.")
	_host.character = character
	_host.economy = null
	assert_eq(_buy(1).result.code, SimBridge.CODE_NO_ECONOMY, "Jogo sem economia, com o jogador longe do mercado.")
	_host.economy = _economy


func test_the_position_used_is_the_one_stored_in_the_character() -> void:
	_stand_at(REPORTED_FAR_M)
	_assert_too_far(_buy(1), "Relatar 12 m na mesma ponte: a posição guardada manda e recusa.")
	_stand_at(NEAR_M)
	assert_eq(_bridge.peek_character(_actor_id).position, _center + Vector3(NEAR_M, 0.0, 0.0), "A posição guardada é a relatada.")
	assert_true(_buy(1).result.ok, "Relatar 2 m na mesma ponte aceita.")


func test_a_refusal_publishes_no_event_and_changes_neither_hash_rng_ids_nor_clock() -> void:
	_stand_at(FAR_M)
	var world: World = _host.runner.world
	var pending_before: int = int(world.context.events.debug_summary()["pending"])
	var hash_before: String = world.state_hash()
	var save_before: Dictionary = _economy.serialize()
	var summary_before: Dictionary = world.debug_summary()
	var rng_before: Dictionary = world.context.rng.debug_summary()
	var ids_before: Dictionary = world.context.ids.debug_summary()
	_assert_too_far(_buy(1), "Comprar longe.")
	_assert_too_far(_sell(1), "Vender longe.")
	assert_eq(int(world.context.events.debug_summary()["pending"]), pending_before, "A recusa não publicou evento.")
	assert_eq(world.state_hash(), hash_before, "O hash do mundo não muda.")
	assert_eq(_economy.serialize(), save_before, "O save da economia não muda.")
	assert_eq(world.debug_summary(), summary_before, "O resumo do mundo (relógio, eventos, módulos) não muda.")
	assert_eq(world.context.rng.debug_summary(), rng_before, "Nenhum sorteio é gasto.")
	assert_eq(world.context.ids.debug_summary(), ids_before, "Nenhum ID é gerado.")


func test_after_the_save_and_the_load_the_player_keeps_trading_and_the_distance_still_counts() -> void:
	_stand_at(NEAR_M)
	assert_true(_buy(2).result.ok)
	var decoded: DecodedSave = _codec.decode(_codec.encode(_host.runner.capture_game(), GAME_VERSION))
	assert_true(decoded.result.ok, decoded.result.message)
	var restored: SimulationRunner = SimulationRunner.new(SEED)
	var modules: GameModules = GameModules.register(restored, _terrain, [], null, _setup)
	assert_true(modules.result.ok, modules.result.message)
	var loaded: Result = restored.load_game(decoded.payload)
	assert_true(loaded.ok, loaded.message)
	var loaded_host: SimulationHostNode = SimulationHostNode.new()
	loaded_host.runner = restored
	loaded_host.character = modules.character
	loaded_host.economy = modules.economy
	var bridge: SimBridge = SimBridge.new(loaded_host, _terrain, _places)
	assert_true(bridge.request_report_position(_actor_id, _center + Vector3(NEAR_M, 0.0, 0.0), 0.0).ok, "O corpo relata a posição de novo, como no jogo.")
	var sold: BridgePlayerEconomyReplies.PlayerTradeReply = bridge.request_trade(_actor_id, _market_id, BREAD, 1, SELL)
	assert_true(sold.result.ok, sold.result.message)
	assert_true(bridge.request_report_position(_actor_id, _center + Vector3(FAR_M, 0.0, 0.0), 0.0).ok)
	_assert_too_far(bridge.request_trade(_actor_id, _market_id, BREAD, 1, SELL), "No mundo carregado, longe do mercado, recusa.")
	restored.finish()
	loaded_host.free()


func test_in_the_real_game_the_player_is_refused_at_the_spawn_point_and_an_npc_is_not_a_character() -> void:
	var host: SimulationHostNode = SimulationHostNode.new()
	var app: GameAppNode = GameAppNode.new()
	app.bind_host(host)
	app.start_default_game(host)
	var bridge: SimBridge = app.peek_bridge()
	var player: int = bridge.request_spawn_character().actor_id
	assert_true(bridge.request_open_player_account(player).ok)
	var market: int = host.economy.peek_market_of(SETTLEMENT).market_id
	_assert_too_far(bridge.request_trade(player, market, BREAD, 1, BUY), "O nascimento do jogo real fica longe do mercado.")
	var npc_id: int = host.npc.peek_npc_ids()[0]
	assert_eq(bridge.request_trade(npc_id, market, BREAD, 1, BUY).result.code, CharacterModule.CODE_UNKNOWN_ACTOR, "Um NPC não é personagem, nem longe.")
	assert_true(bridge.request_report_position(player, _center, 0.0).ok)
	var bought: BridgePlayerEconomyReplies.PlayerTradeReply = bridge.request_trade(player, market, BREAD, 1, BUY)
	assert_true(bought.result.ok, bought.result.message)
	app.free()
	host.runner.finish()
	host.free()
