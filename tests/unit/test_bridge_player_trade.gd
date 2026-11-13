extends GutTest
## LW-105 (parte b): o jogador compra e vende pela ponte (`SimBridge.request_trade`), sem janela, com a economia REAL (`data/economy`, três povoados, mercados com o estoque inicial dos dados) e o terreno real. O saldo vem do `Ledger` e as quantidades e o
## peso, do inventário da `economy` (DEC-130); a ordem é atômica (uma recusa não muda nada) e a ponte só atende quem o `character` conhece. Os números do jogo (saldo inicial 100, capacidade 60, preços) são [HIP] e vêm dos dados: o teste os LÊ
## ou confere antes de usá-los, em vez de fixá-los. Cada recusa volta com a chave do texto (nunca o texto) e toda chave existe em `data/text/pt_br.json`.

const WORLD_DIR: String = "res://data/world"
const GAME_VERSION: String = "0.0.1-test"
const SEED: int = 105
const SETTLEMENT: String = "test_settlement_a"
const BREAD: String = "bread"
const WOOD: String = "wood"
const TOOL: String = "tool"
const UNKNOWN_ID: int = 999999
const TOOLS_TOO_MANY: int = 5

var _terrain: TerrainData
var _setup: EconomySetup
var _host: SimulationHostNode
var _bridge: SimBridge
var _economy: EconomyModule
var _actor_id: int = 0
var _market_id: int = 0
var _codec: JsonSaveCodec = JsonSaveCodec.new()


func before_all() -> void:
	var loaded: TerrainLoader.LoadResult = TerrainLoader.load_dir(WORLD_DIR)
	assert_true(loaded.result.ok, loaded.result.message)
	_terrain = loaded.terrain
	_setup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR)
	assert_true(_setup.result.ok, _setup.result.message)


## Um jogo só com o personagem e a economia (sem NPCs), com o jogador já nascido e com a conta aberta.
func before_each() -> void:
	_host = SimulationHostNode.new()
	_host.start_new_game(SEED, _terrain, [], null, 0, _setup)
	_bridge = SimBridge.new(_host, _terrain)
	_economy = _host.economy
	_actor_id = _bridge.request_spawn_character().actor_id
	assert_true(_bridge.request_open_player_account(_actor_id).ok)
	_market_id = _economy.peek_market_of(SETTLEMENT).market_id


func after_each() -> void:
	_host.runner.finish()
	_host.free()


func _buy(good_id: String, quantity: int) -> BridgePlayerEconomyReplies.PlayerTradeReply:
	return _bridge.request_trade(_actor_id, _market_id, good_id, quantity, BridgePlayerEconomyReplies.SIDE_BUY)


func _sell(good_id: String, quantity: int) -> BridgePlayerEconomyReplies.PlayerTradeReply:
	return _bridge.request_trade(_actor_id, _market_id, good_id, quantity, BridgePlayerEconomyReplies.SIDE_SELL)


## Tudo o que uma ordem pode mexer, numa cópia: os dois saldos, o estoque do mercado, o inventário do jogador e o peso dele.
func _state(good_id: String) -> Dictionary:
	var inventory: EconomyReplies.InventoryQuery = _economy.peek_inventory(_actor_id)
	var owned: int = 0
	for row: Dictionary in inventory.rows:
		if row["good_id"] == good_id:
			owned = int(row["quantity"])
	return {
		"player_balance": _economy.peek_balance(_actor_id).balance,
		"market_balance": _economy.peek_balance(_market_id).balance,
		"market_stock": _economy.peek_stock(_market_id, good_id).value,
		"player_quantity": owned,
		"player_weight": inventory.weight,
	}


func _assert_books_close() -> void:
	assert_true(_economy.peek_conservation().ok, "O dinheiro continua contado.")
	assert_true(_economy.peek_goods_conservation().ok, "Os bens continuam contados.")
	assert_eq(_economy.validate(), [] as Array[String])


func test_the_player_buys_and_the_balance_the_stock_and_the_inventory_move_together() -> void:
	var before: Dictionary = _state(BREAD)
	var bought: BridgePlayerEconomyReplies.PlayerTradeReply = _buy(BREAD, 2)
	assert_true(bought.result.ok, bought.result.message)
	assert_eq([bought.quantity, bought.text_key], [2, BridgePlayerEconomyReplies.PlayerTradeReply.KEY_BOUGHT])
	assert_gt(bought.total, 0, "Comprar custa dinheiro.")
	var after: Dictionary = _state(BREAD)
	assert_eq(after["player_balance"], before["player_balance"] - bought.total, "O saldo do jogador (do `Ledger`) caiu o total.")
	assert_eq(after["market_balance"], before["market_balance"] + bought.total, "O dinheiro foi para o mercado.")
	assert_eq([after["market_stock"], after["player_quantity"]], [before["market_stock"] - 2, 2], "Dois pães saíram do mercado e entraram no inventário.")
	var view: BridgePlayerEconomyReplies.PlayerEconomyReply = _bridge.peek_player_economy(_actor_id)
	assert_eq([view.funds, view.weight], [after["player_balance"], 2 * _economy.peek_good(BREAD).weight], "A ponte mostra o saldo do `Ledger` e o peso de dois pães.")
	_assert_books_close()


func test_the_player_sells_back_and_receives_the_money() -> void:
	assert_true(_buy(BREAD, 3).result.ok)
	var before: Dictionary = _state(BREAD)
	var sold: BridgePlayerEconomyReplies.PlayerTradeReply = _sell(BREAD, 2)
	assert_true(sold.result.ok, sold.result.message)
	assert_eq([sold.quantity, sold.text_key], [2, BridgePlayerEconomyReplies.PlayerTradeReply.KEY_SOLD])
	assert_gt(sold.total, 0, "O mercado paga pelo que compra.")
	var after: Dictionary = _state(BREAD)
	assert_eq([after["player_balance"], after["market_balance"]], [before["player_balance"] + sold.total, before["market_balance"] - sold.total], "O dinheiro voltou do mercado para o jogador.")
	assert_eq([after["market_stock"], after["player_quantity"]], [before["market_stock"] + 2, 1], "Dois pães voltaram ao mercado; sobrou um com o jogador.")
	_assert_books_close()


func test_the_maximum_weight_is_respected_exactly_at_the_limit_and_one_more_is_refused_without_changes() -> void:
	var capacity: int = _bridge.peek_player_economy(_actor_id).capacity
	var unit_weight: int = _economy.peek_good(WOOD).weight
	var fits: int = 0
	while (fits + 1) * unit_weight <= capacity:
		fits += 1
	var quote: EconomyReplies.QuoteQuery = _economy.peek_quote(_actor_id, _market_id, WOOD, fits, BridgePlayerEconomyReplies.SIDE_BUY)
	assert_true(quote.result.ok and quote.total <= _state(WOOD)["player_balance"], "Pré-condição dos dados: o jogador paga a lenha que cabe no limite (%s)." % quote.result.message)
	var filled: BridgePlayerEconomyReplies.PlayerTradeReply = _buy(WOOD, fits)
	assert_true(filled.result.ok, filled.result.message)
	var view: BridgePlayerEconomyReplies.PlayerEconomyReply = _bridge.peek_player_economy(_actor_id)
	assert_true(view.weight <= view.capacity, "O peso carregado nunca passa da capacidade.")
	assert_eq(view.weight, fits * unit_weight)
	var one_more: EconomyReplies.QuoteQuery = _economy.peek_quote(_actor_id, _market_id, WOOD, 1, BridgePlayerEconomyReplies.SIDE_BUY)
	assert_true(one_more.result.ok and one_more.total <= view.funds, "Pré-condição: sobra dinheiro, então só o peso recusa (%s)." % one_more.result.message)
	var before: Dictionary = _state(WOOD)
	var refused: BridgePlayerEconomyReplies.PlayerTradeReply = _buy(WOOD, 1)
	assert_eq([refused.result.code, refused.text_key], [EconomyCodes.CAPACITY_EXCEEDED, "economy.trade.too_heavy"], "Uma unidade a mais passa do limite de peso.")
	assert_eq(_state(WOOD), before, "A recusa não mudou nada: nem saldos, nem estoque, nem inventário.")
	_assert_books_close()


func test_refusals_come_with_the_right_key_and_change_nothing() -> void:
	var before: Dictionary = _state(TOOL)
	var quote: EconomyReplies.QuoteQuery = _economy.peek_quote(_actor_id, _market_id, TOOL, TOOLS_TOO_MANY, BridgePlayerEconomyReplies.SIDE_BUY)
	assert_true(quote.result.ok and quote.total > before["player_balance"], "Pré-condição dos dados: %d ferramentas custam mais do que o jogador tem." % TOOLS_TOO_MANY)
	var poor: BridgePlayerEconomyReplies.PlayerTradeReply = _buy(TOOL, TOOLS_TOO_MANY)
	assert_eq([poor.result.code, poor.text_key, poor.quantity, poor.total], [EconomyCodes.INSUFFICIENT_FUNDS, "economy.trade.no_funds", 0, 0], "Sem dinheiro.")
	var nothing: BridgePlayerEconomyReplies.PlayerTradeReply = _sell(TOOL, 1)
	assert_eq([nothing.result.code, nothing.text_key], [EconomyCodes.INSUFFICIENT_GOODS, "economy.trade.no_goods"], "Vender o que não tem.")
	var too_much: BridgePlayerEconomyReplies.PlayerTradeReply = _buy(TOOL, before["market_stock"] + 1)
	assert_eq([too_much.result.code, too_much.text_key], [EconomyCodes.INSUFFICIENT_STOCK, "economy.trade.no_stock"], "O mercado não tem tanto.")
	assert_eq(_state(TOOL), before, "Nenhuma das três recusas mudou algo.")
	_assert_books_close()


func test_other_refusals_use_the_generic_key() -> void:
	var unopened: int = _bridge.request_spawn_character().actor_id
	var cases: Array = [
		[_bridge.request_trade(unopened, _market_id, BREAD, 1, BridgePlayerEconomyReplies.SIDE_BUY), EconomyCodes.UNKNOWN_OWNER],
		[_bridge.request_trade(_actor_id, UNKNOWN_ID, BREAD, 1, BridgePlayerEconomyReplies.SIDE_BUY), EconomyCodes.UNKNOWN_MARKET],
		[_bridge.request_trade(_actor_id, _market_id, "no_such_good", 1, BridgePlayerEconomyReplies.SIDE_BUY), EconomyCodes.UNKNOWN_GOOD],
		[_buy(BREAD, 0), EconomyCodes.BAD_QUANTITY],
	]
	for pair: Array in cases:
		var reply: BridgePlayerEconomyReplies.PlayerTradeReply = pair[0]
		assert_eq([reply.result.code, reply.text_key], [pair[1], BridgePlayerEconomyReplies.PlayerTradeReply.FALLBACK_KEY])
	assert_false(_bridge.request_trade(_actor_id, _market_id, BREAD, 1, "swap").result.ok, "Lado que não é nem compra nem venda.")


func test_only_a_character_can_trade_so_a_market_or_a_stranger_as_actor_is_refused() -> void:
	var before: Dictionary = _state(BREAD)
	for stranger: int in [_market_id, UNKNOWN_ID]:
		var refused: BridgePlayerEconomyReplies.PlayerTradeReply = _bridge.request_trade(stranger, _market_id, BREAD, 1, BridgePlayerEconomyReplies.SIDE_SELL)
		assert_eq([refused.result.code, refused.text_key], [CharacterModule.CODE_UNKNOWN_ACTOR, BridgePlayerEconomyReplies.PlayerTradeReply.FALLBACK_KEY], "O ator %d não é um personagem." % stranger)
	assert_eq(_state(BREAD), before, "O mercado não foi tocado.")


func test_without_a_game_or_without_the_economy_the_trade_fails_with_a_code() -> void:
	var idle_host: SimulationHostNode = SimulationHostNode.new()
	var without_game: BridgePlayerEconomyReplies.PlayerTradeReply = SimBridge.new(idle_host, null).request_trade(1, 1, BREAD, 1, BridgePlayerEconomyReplies.SIDE_BUY)
	assert_eq([without_game.result.code, without_game.text_key], [SimBridge.CODE_NO_GAME, BridgePlayerEconomyReplies.PlayerTradeReply.FALLBACK_KEY])
	idle_host.free()
	_host.economy = null
	assert_eq(_buy(BREAD, 1).result.code, SimBridge.CODE_NO_ECONOMY, "Há personagem, mas o jogo não tem economia.")
	_host.economy = _economy


func test_every_key_exists_in_the_text_file_and_the_sides_are_the_engines() -> void:
	var texts: UiText = UiText.from_file(UiText.DEFAULT_PATH).texts
	var keys: Array[String] = [BridgePlayerEconomyReplies.PlayerTradeReply.KEY_BOUGHT, BridgePlayerEconomyReplies.PlayerTradeReply.KEY_SOLD, BridgePlayerEconomyReplies.PlayerTradeReply.FALLBACK_KEY]
	keys.append_array(BridgePlayerEconomyReplies.PlayerTradeReply.FAILURE_KEYS.values())
	for key: String in keys:
		assert_true(key.begins_with("economy.trade."), "A chave %s tem o prefixo economy.trade." % key)
		assert_true(texts.has_key(key), "Falta a chave '%s' em data/text/pt_br.json." % key)
		assert_ne(texts.get_text(key), "[%s]" % key, "A chave '%s' devolveu a própria chave." % key)
	assert_eq([BridgePlayerEconomyReplies.SIDE_BUY, BridgePlayerEconomyReplies.SIDE_SELL], [TradeEngine.SIDE_BUY, TradeEngine.SIDE_SELL], "Os lados da ponte são os do motor.")


func test_the_players_account_balance_and_inventory_survive_the_save() -> void:
	assert_true(_buy(WOOD, 3).result.ok)
	assert_true(_buy(BREAD, 2).result.ok)
	var view: BridgePlayerEconomyReplies.PlayerEconomyReply = _bridge.peek_player_economy(_actor_id)
	assert_true(_host.runner.can_capture_game(), "Entre passos a fila de eventos está vazia.")
	var decoded: DecodedSave = _codec.decode(_codec.encode(_host.runner.capture_game(), GAME_VERSION))
	assert_true(decoded.result.ok, decoded.result.message)
	var restored: SimulationRunner = SimulationRunner.new(SEED)
	var modules: GameModules = GameModules.register(restored, _terrain, [], null, _setup)
	assert_true(modules.result.ok, modules.result.message)
	var loaded: Result = restored.load_game(decoded.payload)
	assert_true(loaded.ok, loaded.message)
	assert_eq(restored.world.state_hash(), _host.runner.world.state_hash(), "O mundo carregado tem o hash do momento do salvamento.")
	var economy: EconomyModule = modules.economy
	var inventory: EconomyReplies.InventoryQuery = economy.peek_inventory(_actor_id)
	assert_eq([economy.peek_balance(_actor_id).balance, inventory.rows, inventory.weight, inventory.capacity], [view.funds, view.goods, view.weight, view.capacity], "Saldo, bens, peso e capacidade do jogador voltam iguais.")
	assert_true(economy.peek_conservation().ok and economy.peek_goods_conservation().ok)
	assert_true(economy.request_trade(_actor_id, _market_id, BREAD, 1, BridgePlayerEconomyReplies.SIDE_SELL).result.ok, "O mesmo jogador continua negociando no mundo carregado.")
	restored.finish()
