extends GutTest
## LW-107h: a cotação do jogador na ponte (`SimBridge.peek_trade_quote`, `BridgePlayerEconomy.quote` e `BridgePlayerEconomyReplies.TradeQuoteReply`), sem janela, no jogo REAL (`GameApp.start_default_game`: terreno, NPCs e economia reais), como `test_bridge_player_account.gd`. É um repasse FINO do `EconomyModule.peek_quote`: `result`,
## `total`, `average_price` e `tariff` iguais aos dele (a mesma conta de `request_trade` no mesmo instante), `quantity` a pedida; toda recusa vai com o código de quem recusou, SEM tradução e SEM chave de texto (as da ponte: ID solto, NPC, outro dono, sem jogo, sem economia; as da economia: sem conta, mercado, bem e quantidade);
## NÃO exige alcance (consultar não é negociar, ao contrário de `request_trade`); e consultar não muda nada (`state_hash`, eventos, saldos, estoque e inventário).

const UNKNOWN_ID: int = 999999
const SETTLEMENT: String = "test_settlement_a"
const BREAD: String = "bread"
const WOOD: String = "wood"
const BUY: String = BridgePlayerEconomyReplies.SIDE_BUY
const SELL: String = BridgePlayerEconomyReplies.SIDE_SELL

var _host: SimulationHostNode
var _app: GameAppNode
var _bridge: SimBridge
var _economy: EconomyModule
var _actor_id: int = 0
var _market_id: int = 0


## O jogo real, com o jogador nascido e a conta aberta; ele nasce no ponto de partida, longe de qualquer mercado (o teste do alcance confere isso).
func before_each() -> void:
	_host = SimulationHostNode.new()
	_app = GameAppNode.new()
	_app.bind_host(_host)
	_app.start_default_game(_host)
	_bridge = _app.peek_bridge()
	_economy = _host.economy
	_actor_id = _spawn()
	assert_true(_bridge.request_open_player_account(_actor_id).ok)
	_market_id = _economy.peek_market_of(SETTLEMENT).market_id


func after_each() -> void:
	_app.free()
	if _host.runner != null:
		_host.runner.finish()
	_host.free()


func _spawn() -> int:
	var spawned: BridgeReplies.SpawnCharacterReply = _bridge.request_spawn_character()
	assert_true(spawned.result.ok, spawned.result.message)
	return spawned.actor_id


## O que nenhuma consulta pode mudar: o `state_hash`, os eventos pendentes, o saldo e o inventário do jogador e o estoque e o saldo do mercado.
func _snapshot() -> Array:
	var player: BridgePlayerEconomyReplies.PlayerEconomyReply = _bridge.peek_player_economy(_actor_id)
	return [_host.runner.world.state_hash(), int(_host.runner.world.context.events.debug_summary()["pending"]), player.funds, player.goods, _economy.peek_stock(_market_id, BREAD).value, _economy.peek_balance(_market_id).balance]


func test_the_quote_is_the_economys_peek_quote_for_both_sides_and_keeps_the_requested_quantity() -> void:
	for good_id: String in [BREAD, WOOD]:
		for quantity: int in [1, 5]:
			for side: String in [BUY, SELL]:
				var reply: BridgePlayerEconomyReplies.TradeQuoteReply = _bridge.peek_trade_quote(_actor_id, _market_id, good_id, quantity, side)
				var oracle: EconomyReplies.QuoteQuery = _economy.peek_quote(_actor_id, _market_id, good_id, quantity, side)
				assert_true(reply.result.ok, reply.result.message)
				assert_eq([reply.result.ok, reply.quantity, reply.total, reply.average_price, reply.tariff], [oracle.result.ok, quantity, oracle.total, oracle.average_price, oracle.tariff], "%s de %d %s: a ponte devolve a conta da economia, sem mudar nada." % [side, quantity, good_id])
				assert_gt(reply.total, 0, "Uma ordem custa (ou paga) dinheiro.")
	var bought: BridgePlayerEconomyReplies.TradeQuoteReply = _bridge.peek_trade_quote(_actor_id, _market_id, BREAD, 5, BUY)
	assert_eq(bought.average_price, IntMath.floor_div(bought.total, 5), "O preço médio é o total dividido pela quantidade, para baixo (a conta da economia).")


func test_every_refusal_keeps_the_code_of_who_refused_with_no_text_key_and_zeros() -> void:
	var stranger: int = _spawn()
	var npc_id: int = _host.npc.peek_npc_ids()[0]
	var refusals: Array = [
		[npc_id, _market_id, BREAD, 1, BUY, CharacterModule.CODE_UNKNOWN_ACTOR], [UNKNOWN_ID, _market_id, BREAD, 1, BUY, CharacterModule.CODE_UNKNOWN_ACTOR],
		[_market_id, _market_id, BREAD, 1, BUY, CharacterModule.CODE_UNKNOWN_ACTOR], [stranger, _market_id, BREAD, 1, BUY, EconomyCodes.UNKNOWN_OWNER],
		[_actor_id, UNKNOWN_ID, BREAD, 1, BUY, EconomyCodes.UNKNOWN_MARKET], [_actor_id, _market_id, "no_such_good", 1, BUY, EconomyCodes.UNKNOWN_GOOD],
		[_actor_id, _market_id, BREAD, 0, BUY, EconomyCodes.BAD_QUANTITY], [_actor_id, _market_id, BREAD, 51, BUY, EconomyCodes.BAD_QUANTITY],
	]
	for refusal: Array in refusals:
		var reply: BridgePlayerEconomyReplies.TradeQuoteReply = _bridge.peek_trade_quote(refusal[0], refusal[1], refusal[2], refusal[3], refusal[4])
		assert_eq([reply.result.ok, reply.result.code], [false, refusal[5]], "A recusa de %s mantém o código de quem recusou, sem tradução." % [refusal])
		assert_eq([reply.quantity, reply.total, reply.average_price, reply.tariff, reply.get("text_key")], [0, 0, 0, 0, null], "Recusada: tudo zero e nenhuma chave de texto (é consulta, não ordem).")
		if refusal[5] != CharacterModule.CODE_UNKNOWN_ACTOR:
			assert_eq(reply.result.code, _economy.peek_quote(refusal[0], refusal[1], refusal[2], refusal[3], refusal[4]).result.code, "O código é o da economia, repassado.")


func test_without_a_game_or_without_an_economy_the_bridge_refuses_with_its_own_code() -> void:
	var idle_host: SimulationHostNode = SimulationHostNode.new()
	assert_eq(SimBridge.new(idle_host, null, [] as Array[Place]).peek_trade_quote(_actor_id, _market_id, BREAD, 1, BUY).result.code, SimBridge.CODE_NO_GAME, "Sem jogo iniciado.")
	idle_host.free()
	_host.economy = null
	assert_eq(_bridge.peek_trade_quote(_actor_id, _market_id, BREAD, 1, BUY).result.code, SimBridge.CODE_NO_ECONOMY, "Há personagem, mas o jogo não tem economia.")
	_host.economy = _economy
	assert_true(_bridge.peek_trade_quote(_actor_id, _market_id, BREAD, 1, BUY).result.ok, "Com a economia de volta, a consulta volta a responder.")


func test_the_quote_needs_no_reach_but_the_order_does() -> void:
	assert_eq(_bridge.peek_market_in_reach(_actor_id).result.code, MarketReach.CODE_PLACE_TOO_FAR, "O jogador nasce longe de qualquer mercado.")
	var quoted: BridgePlayerEconomyReplies.TradeQuoteReply = _bridge.peek_trade_quote(_actor_id, _market_id, BREAD, 2, BUY)
	assert_true(quoted.result.ok, "A cotação não exige alcance: é leitura, como `peek_contract_board`.")
	var ordered: BridgePlayerEconomyReplies.PlayerTradeReply = _bridge.request_trade(_actor_id, _market_id, BREAD, 2, BUY)
	assert_eq(ordered.result.code, MarketReach.CODE_PLACE_TOO_FAR, "A ordem real continua exigindo o alcance.")


func test_quoting_changes_nothing() -> void:
	var before: Array = _snapshot()
	for side: String in [BUY, SELL]:
		for quantity: int in [0, 1, 5, 51]:
			_bridge.peek_trade_quote(_actor_id, _market_id, BREAD, quantity, side)
	_bridge.peek_trade_quote(UNKNOWN_ID, _market_id, BREAD, 1, BUY)
	assert_eq(_snapshot(), before, "Nem o `state_hash`, nem os eventos, nem o saldo, o inventário ou o estoque mudaram: consultar não negocia.")
	assert_true(_economy.peek_conservation().ok)
	assert_true(_economy.peek_goods_conservation().ok)
