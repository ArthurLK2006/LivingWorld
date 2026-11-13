extends GutTest
## LW-106d2: a `MarketView` (src/presentation/ui/market/market_view.gd; contrato em docs/modules/presentation.md, "Interface de mercado (LW-106)"), sem janela, com o jogo REAL (`res://data`), a ponte real e os textos reais (`data/text/pt_br.json`), montados
## como em `test_bridge_player_trade.gd`: o jogador junto ao mercado `a_market_01`, com a conta aberta. Confere que a tela mostra o mesmo que as consultas da ponte e nenhum texto de chave que falta; que comprar e vender mexem em saldo, estoque,
## peso e "você tem" com o texto da chave e o total da resposta; que cada recusa (longe, sem dinheiro, sem o bem, sem estoque, pesado demais) mostra o texto da sua chave sem mudar nada; que, pausado, nada é enviado; que os nós de `frozen`
## param e voltam ao fechar; que `ui_cancel`, `interact` e o botão fecham e `closed` sai uma vez; que sem jogo ou sem conta a tela diz que está indisponível; e que abrir, atualizar e fechar não mudam o `state_hash` (só comprar e vender mudam).
## Os nós da tela são achados pelos nomes fixos do `MarketLayout`: a tela não expõe o layout.

const WORLD_DIR: String = "res://data/world"
const SEED: int = 106
const SETTLEMENT: String = "test_settlement_a"
const MARKET_PLACE_ID: String = "a_market_01"
const BREAD: String = "bread"
const WOOD: String = "wood"
const TOOL: String = "tool"
const TOOLS_TOO_MANY: int = 5
const TOO_FAR_M: float = 3.5
const KEY_FOR_MISSING_TEXT: String = "\\[[a-z_]+(\\.[a-z_]+)+\\]"
const NAME_TITLE: String = "MarketTitle"
const NAME_FUNDS: String = "MarketFunds"
const NAME_WEIGHT: String = "MarketWeight"
const NAME_GOODS: String = "MarketGoods"
const NAME_QUANTITY: String = "MarketQuantity"
const NAME_BUY: String = "MarketBuy"
const NAME_SELL: String = "MarketSell"
const NAME_CLOSE: String = "MarketClose"
const NAME_RESULT: String = "MarketResult"
const NAME_HINTS: String = "MarketHints"

var _terrain: TerrainData
var _places: Array[Place] = []
var _center: Vector3
var _setup: EconomySetup
var _texts: UiText
var _host: SimulationHostNode
var _bridge: SpyBridge
var _economy: EconomyModule
var _actor_id: int = 0
var _market_id: int = 0
var _frozen: Array[Node] = []
var _view: MarketView


## Ponte que ANOTA cada `request_trade` (argumentos e resposta) e repassa à de verdade: prova o que a tela enviou e dá o `total` da resposta.
class SpyBridge:
	extends SimBridge

	var calls: Array[Array] = []
	var replies: Array[BridgePlayerEconomyReplies.PlayerTradeReply] = []

	func request_trade(actor_id: int, market_id: int, good_id: String, quantity: int, side: String) -> BridgePlayerEconomyReplies.PlayerTradeReply:
		var reply: BridgePlayerEconomyReplies.PlayerTradeReply = super.request_trade(actor_id, market_id, good_id, quantity, side)
		calls.append([actor_id, market_id, good_id, quantity, side])
		replies.append(reply)
		return reply


## Ponte que declara todos os bens em falta (a escassez real leva dias sem estoque; a tela só copia a marca).
class ShortageBridge:
	extends SimBridge

	func peek_economy_markets() -> BridgeEconomyReplies.EconomyMarketsReply:
		var reply: BridgeEconomyReplies.EconomyMarketsReply = super()
		for entry: BridgeEconomyReplies.EconomyMarketEntry in reply.markets:
			for row: BridgeEconomyReplies.EconomyMarketRow in entry.rows:
				row.is_in_shortage = true
		return reply


func before_all() -> void:
	var loaded: TerrainLoader.LoadResult = TerrainLoader.load_dir(WORLD_DIR)
	assert_true(loaded.result.ok, loaded.result.message)
	_terrain = loaded.terrain
	var settlements: SettlementLoader.LoadResult = SettlementLoader.load_dir(WORLD_DIR, _terrain)
	assert_true(settlements.result.ok, settlements.result.message)
	_places = settlements.places
	for place: Place in _places:
		if place.id == MARKET_PLACE_ID:
			_center = place.position
	_setup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR)
	assert_true(_setup.result.ok, _setup.result.message)
	var texts: UiText.LoadResult = UiText.from_file(UiText.DEFAULT_PATH)
	assert_true(texts.result.ok, texts.result.message)
	_texts = texts.texts


## Um jogo só com o personagem e a economia (sem NPCs), com o jogador junto ao mercado e a conta aberta, dois `Node3D` para a tela parar e a tela FECHADA, ligada a uma ponte espiã.
func before_each() -> void:
	_host = SimulationHostNode.new()
	_host.start_new_game(SEED, _terrain, [], null, 0, _setup)
	_bridge = SpyBridge.new(_host, _terrain, _places)
	_economy = _host.economy
	_actor_id = _bridge.request_spawn_character().actor_id
	assert_true(_bridge.request_report_position(_actor_id, _center, 0.0).ok, "O jogador começa junto ao mercado.")
	assert_true(_bridge.request_open_player_account(_actor_id).ok)
	_market_id = _economy.peek_market_of(SETTLEMENT).market_id
	_frozen.clear()
	for _index: int in 2:
		var body: Node3D = Node3D.new()
		add_child_autofree(body)
		_frozen.append(body)
	_view = _make_view(_bridge, _actor_id)


func after_each() -> void:
	_host.runner.finish()
	_host.free()


func _make_view(bridge: SimBridge, actor_id: int) -> MarketView:
	var view: MarketView = MarketView.new()
	add_child_autofree(view)
	assert_true(view.setup(bridge, _texts, actor_id, _frozen))
	watch_signals(view)
	return view


func _text(key: String, values: Dictionary = {}) -> String:
	return _texts.get_text(key, values)


func _node(node_name: String) -> Node:
	return _view.find_child(node_name, true, false)


func _tree() -> Tree:
	return _node(NAME_GOODS) as Tree


func _items() -> Array[TreeItem]:
	return _tree().get_root().get_children() if _tree().get_root() != null else ([] as Array[TreeItem])


## A linha da tabela do bem, como a tela a mostra: nome, compra, venda, estoque e "você tem".
func _row_of(good_id: String) -> Array[String]:
	var shown: Array[String] = []
	for item: TreeItem in _items():
		if item.get_text(MarketLayout.COLUMN_NAME) == _text("good.%s.name" % good_id):
			for column: int in MarketLayout.COLUMN_COUNT:
				shown.append(item.get_text(column))
	return shown


func _select(good_id: String, quantity: int) -> void:
	for item: TreeItem in _items():
		if item.get_text(MarketLayout.COLUMN_NAME) == _text("good.%s.name" % good_id):
			item.select(MarketLayout.COLUMN_NAME)
	(_node(NAME_QUANTITY) as SpinBox).value = quantity


func _press(button_name: String) -> void:
	(_node(button_name) as Button).pressed.emit()


func _result_text() -> String:
	return (_node(NAME_RESULT) as Label).text


func _is_off(button_name: String) -> bool:
	return (_node(button_name) as Button).disabled


func _action(action: StringName) -> InputEventAction:
	var event: InputEventAction = InputEventAction.new()
	event.action = action
	event.pressed = true
	return event


## O mercado e o jogador como a PONTE os vê, de um bem: o que a tela deve mostrar. A linha do mercado sai da consulta `peek_economy_markets`.
func _state(good_id: String) -> Dictionary:
	var player: BridgePlayerEconomyReplies.PlayerEconomyReply = _bridge.peek_player_economy(_actor_id)
	var owned: int = 0
	for held: Dictionary in player.goods:
		if held["good_id"] == good_id:
			owned = int(held["quantity"])
	var state: Dictionary = {"funds": player.funds, "weight": player.weight, "capacity": player.capacity, "owned": owned}
	for entry: BridgeEconomyReplies.EconomyMarketEntry in _bridge.peek_economy_markets().markets:
		for row: BridgeEconomyReplies.EconomyMarketRow in entry.rows if entry.market_id == _market_id else ([] as Array[BridgeEconomyReplies.EconomyMarketRow]):
			if row.good_id == good_id:
				state.merge({"ask": row.ask, "bid": row.bid, "stock": row.stock, "shortage": row.is_in_shortage})
	return state


## A tela inteira (dinheiro, peso e as 10 linhas) é igual ao que a ponte diz agora.
func _assert_screen_matches_the_bridge() -> void:
	var player: Dictionary = _state(BREAD)
	assert_eq((_node(NAME_FUNDS) as Label).text, _text("ui.market.funds", {"funds": player["funds"]}))
	assert_eq((_node(NAME_WEIGHT) as Label).text, _text("ui.market.weight", {"weight": player["weight"], "capacity": player["capacity"]}))
	assert_eq(_items().size(), 10, "Uma linha por bem do mercado.")
	for item: TreeItem in _items():
		var good_id: String = str(item.get_metadata(MarketLayout.COLUMN_NAME))
		var state: Dictionary = _state(good_id)
		var stock: String = _text("ui.market.shortage", {"stock": state["stock"]}) if state["shortage"] else str(state["stock"])
		assert_eq(_row_of(good_id), [_text("good.%s.name" % good_id), str(state["ask"]), str(state["bid"]), stock, str(state["owned"])], "A linha de %s." % good_id)


## Recusa: a tela mostra o texto da chave, o pedido saiu uma vez, e nada mudou (a ponte, a tela e o `state_hash`).
func _assert_refusal(good_id: String, quantity: int, is_buy: bool, key: String) -> void:
	var state: Dictionary = _state(good_id)
	var hash_before: String = _host.runner.world.state_hash()
	var calls_before: int = _bridge.calls.size()
	_select(good_id, quantity)
	if is_buy:
		_view.buy()
	else:
		_view.sell()
	assert_eq(_bridge.calls.size(), calls_before + 1, "O pedido saiu (%s)." % key)
	assert_eq(_result_text(), _text(key), "O texto da recusa.")
	assert_false(_bridge.replies[-1].result.ok)
	assert_eq([_state(good_id), _host.runner.world.state_hash()], [state, hash_before], "A recusa não mudou nada (%s)." % key)
	_assert_screen_matches_the_bridge()


func test_setup_refuses_null_parts_and_a_new_view_is_closed_hidden_and_not_processing() -> void:
	var bare: MarketView = MarketView.new()
	add_child_autofree(bare)
	assert_false(bare.setup(null, _texts, _actor_id, _frozen))
	assert_push_error("MarketView.setup")
	assert_false(bare.setup(_bridge, null, _actor_id, _frozen))
	assert_push_error("MarketView.setup")
	bare.open(_market_id)
	assert_false(bare.is_open(), "Sem `setup` nada abre.")
	assert_eq([_view.is_open(), _view.visible, _view.is_processing(), _view.layer], [false, false, false, MarketView.LAYER_INDEX])
	assert_not_null((_node("MarketRoot") as Control).theme, "O tema é posto no Control raiz.")
	_view.open(_market_id)
	assert_eq([_view.is_open(), _view.visible, _view.is_processing()], [true, true, true], "Aberta: visível e atualizando sozinha.")
	_view.close()
	assert_eq([_view.is_open(), _view.visible, _view.is_processing()], [false, false, false], "Fechada de novo: invisível e sem processar.")


func test_open_shows_what_the_bridge_says_and_no_text_of_a_missing_key() -> void:
	assert_true(_bridge.request_trade(_actor_id, _market_id, BREAD, 2, BridgePlayerEconomyReplies.SIDE_BUY).result.ok)
	_view.open(_market_id)
	_assert_screen_matches_the_bridge()
	assert_eq(_row_of(BREAD)[MarketLayout.COLUMN_OWNED], "2", "Os 2 pães comprados aparecem em `você tem`.")
	assert_eq(_result_text(), "", "A linha de resultado nasce limpa.")
	assert_true(_tree().has_focus() and _tree().get_selected() != null, "A tabela tem o foco e uma linha escolhida.")
	var expected: Dictionary = {NAME_TITLE: "ui.market.title", NAME_BUY: "ui.market.buy", NAME_SELL: "ui.market.sell", NAME_CLOSE: "ui.market.close"}
	var interface_texts: Array[String] = [(_node(NAME_QUANTITY) as SpinBox).prefix, (_node(NAME_HINTS) as Label).text]
	for node_name: String in expected:
		interface_texts.append((_node(node_name) as Control).get("text"))
		assert_eq(interface_texts[-1], _text(expected[node_name]), "O texto de %s." % node_name)
	for column: int in MarketLayout.COLUMN_COUNT:
		interface_texts.append(_tree().get_column_title(column))
	assert_eq(_tree().get_column_title(MarketLayout.COLUMN_NAME), _text("ui.market.column_name"))
	var missing: RegEx = RegEx.create_from_string(KEY_FOR_MISSING_TEXT)
	for node: Node in _view.find_children("*", "", true, false):
		if node is Label:
			interface_texts.append((node as Label).text)
	for text: String in interface_texts:
		assert_false(text.is_empty() and text != _result_text(), "Texto da tela vazio.")
		assert_null(missing.search(text), "Texto de chave que falta: %s." % text)
	assert_string_contains((_node(NAME_HINTS) as Label).text, "[E]")


func test_buying_and_selling_move_balance_stock_owned_and_weight_with_the_text_and_the_total() -> void:
	_view.open(_market_id)
	var before: Dictionary = _state(BREAD)
	_select(BREAD, 2)
	_press(NAME_BUY)
	var bought: BridgePlayerEconomyReplies.PlayerTradeReply = _bridge.replies[-1]
	assert_true(bought.result.ok, bought.result.message)
	assert_eq(_bridge.calls, [[_actor_id, _market_id, BREAD, 2, BridgePlayerEconomyReplies.SIDE_BUY]] as Array[Array], "A tela pediu 2 pães, só isso.")
	var after: Dictionary = _state(BREAD)
	assert_eq([after["funds"], after["stock"], after["owned"]], [before["funds"] - bought.total, before["stock"] - 2, before["owned"] + 2], "Saldo, estoque e `você tem`.")
	assert_gt(after["weight"], before["weight"], "O peso subiu.")
	assert_eq(_result_text(), "%s %s" % [_text("economy.trade.bought"), _text("ui.market.total", {"total": bought.total})], "O texto da compra e o total da resposta.")
	_assert_screen_matches_the_bridge()
	_select(BREAD, 1)
	_press(NAME_SELL)
	var sold: BridgePlayerEconomyReplies.PlayerTradeReply = _bridge.replies[-1]
	assert_true(sold.result.ok, sold.result.message)
	var final: Dictionary = _state(BREAD)
	assert_eq([final["funds"], final["stock"], final["owned"]], [after["funds"] + sold.total, after["stock"] + 1, after["owned"] - 1], "Venda: o saldo sobe o total.")
	assert_eq(_result_text(), "%s %s" % [_text("economy.trade.sold"), _text("ui.market.total", {"total": sold.total})])
	_assert_screen_matches_the_bridge()


func test_each_refusal_shows_the_text_of_its_own_key_and_changes_nothing() -> void:
	_view.open(_market_id)
	assert_lt(MarketReach.MARKET_REACH_M, TOO_FAR_M, "Pré-condição: 3,5 m passa do alcance do mercado.")
	assert_true(_bridge.request_report_position(_actor_id, _center + Vector3(TOO_FAR_M, 0.0, 0.0), 0.0).ok)
	_assert_refusal(BREAD, 1, true, "economy.trade.too_far")
	assert_true(_bridge.request_report_position(_actor_id, _center, 0.0).ok, "De volta ao centro.")
	var quote: EconomyReplies.QuoteQuery = _economy.peek_quote(_actor_id, _market_id, TOOL, TOOLS_TOO_MANY, BridgePlayerEconomyReplies.SIDE_BUY)
	assert_true(quote.result.ok and quote.total > _state(TOOL)["funds"], "Pré-condição dos dados: %d ferramentas custam mais do que o jogador tem." % TOOLS_TOO_MANY)
	_assert_refusal(TOOL, TOOLS_TOO_MANY, true, "economy.trade.no_funds")
	_assert_refusal(TOOL, 1, false, "economy.trade.no_goods")
	var tool_stock: int = _state(TOOL)["stock"]
	assert_lt(tool_stock, MarketLayout.QUANTITY_MAX, "Pré-condição: dá para pedir mais ferramentas do que o mercado tem.")
	_assert_refusal(TOOL, tool_stock + 1, true, "economy.trade.no_stock")
	var capacity: int = _state(WOOD)["capacity"]
	var fits: int = IntMath.floor_div(capacity, _economy.peek_good(WOOD).weight)
	var filling: EconomyReplies.QuoteQuery = _economy.peek_quote(_actor_id, _market_id, WOOD, fits + 1, BridgePlayerEconomyReplies.SIDE_BUY)
	assert_true(fits <= MarketLayout.QUANTITY_MAX and filling.result.ok and filling.total <= _state(WOOD)["funds"], "Pré-condição dos dados: o jogador paga a lenha até o limite de peso e mais uma (%s)." % filling.result.message)
	_select(WOOD, fits)
	_view.buy()
	assert_eq(_result_text().begins_with(_text("economy.trade.bought")), true, "Encheu a capacidade de peso.")
	_assert_refusal(WOOD, 1, true, "economy.trade.too_heavy")


func test_a_paused_clock_turns_both_buttons_off_and_nothing_is_sent() -> void:
	_view.open(_market_id)
	assert_false(_is_off(NAME_BUY) or _is_off(NAME_SELL), "Controle: com o relógio andando os dois botões estão ativos.")
	assert_true(_bridge.request_pause(true).ok)
	_select(BREAD, 1)
	_view.buy()
	assert_eq(_bridge.calls.size(), 0, "Pausado há instantes, antes de a tela atualizar: nada é enviado.")
	_view.refresh()
	_view.sell()
	assert_true(_is_off(NAME_BUY) and _is_off(NAME_SELL), "Pausado: Comprar e Vender desativados.")
	assert_eq(_bridge.calls.size(), 0, "Nada foi enviado.")
	assert_true(_bridge.request_pause(false).ok)
	_view.refresh()
	assert_false(_is_off(NAME_BUY) or _is_off(NAME_SELL), "O relógio voltou a andar.")
	_view.buy()
	assert_eq(_bridge.calls.size(), 1, "Voltou a enviar.")


func test_open_freezes_the_nodes_and_close_gives_back_the_mode_they_had() -> void:
	_frozen[0].process_mode = Node.PROCESS_MODE_ALWAYS
	_view.open(_market_id)
	_view.open(_market_id)
	for node: Node in _frozen:
		assert_eq(node.process_mode, Node.PROCESS_MODE_DISABLED, "Parado com a tela aberta.")
	_view.close()
	assert_eq([_frozen[0].process_mode, _frozen[1].process_mode], [Node.PROCESS_MODE_ALWAYS, Node.PROCESS_MODE_INHERIT], "Cada um volta ao modo que tinha (abrir de novo não sobrescreve o guardado).")


func test_cancel_interact_and_the_close_button_close_the_screen_and_closed_comes_out_once_each() -> void:
	_view._input(_action(InputActions.INTERACT))
	assert_false(get_viewport().is_input_handled(), "Fechada, a tela não toca a tecla (a `InteractionView` ainda a lê).")
	_view.open(_market_id)
	_view._input(_action(MarketView.ACTION_CANCEL))
	assert_false(_view.is_open())
	assert_true(get_viewport().is_input_handled(), "A tecla que fecha é dada como tratada.")
	_view.open(_market_id)
	_view._input(_action(InputActions.INTERACT))
	assert_false(_view.is_open())
	_view.open(_market_id)
	_press(NAME_CLOSE)
	assert_false(_view.is_open())
	_view.close()
	assert_signal_emit_count(_view, "closed", 3)


func test_without_a_game_or_an_account_the_screen_says_unavailable_and_both_buttons_are_off() -> void:
	var idle_host: SimulationHostNode = SimulationHostNode.new()
	var unopened: int = _bridge.request_spawn_character().actor_id
	for pair: Array in [[SimBridge.new(idle_host, _terrain, _places), _actor_id], [_bridge, unopened]]:
		_view = _make_view(pair[0], pair[1])
		_view.open(_market_id)
		assert_eq(_result_text(), _text("ui.market.unavailable"))
		assert_true(_is_off(NAME_BUY) and _is_off(NAME_SELL))
		assert_eq([_items().size(), (_node(NAME_FUNDS) as Label).text], [0, ""], "Sem linhas e sem número da leitura anterior.")
		_view.buy()
		_view.close()
	assert_eq(_bridge.calls.size(), 0, "Nada foi enviado.")
	idle_host.free()


func test_opening_refreshing_and_closing_never_change_the_state_hash_only_trading_does() -> void:
	var hash_before: String = _host.runner.world.state_hash()
	var time_before: BridgeReplies.TimeSnapshot = _bridge.peek_time()
	_view.open(_market_id)
	_view.refresh()
	simulate(_view, 1, MarketView.REFRESH_INTERVAL_S)
	_view.close()
	var time_after: BridgeReplies.TimeSnapshot = _bridge.peek_time()
	assert_eq(_host.runner.world.state_hash(), hash_before, "Abrir, atualizar e fechar não escrevem na simulação.")
	assert_eq([time_after.is_paused, time_after.speed, time_after.total_minutes], [time_before.is_paused, time_before.speed, time_before.total_minutes], "A tela não pausa nem muda a velocidade.")
	_view.open(_market_id)
	_select(BREAD, 1)
	_view.buy()
	var after_buy: String = _host.runner.world.state_hash()
	assert_ne(after_buy, hash_before, "Comprar muda o mundo.")
	_view.sell()
	assert_ne(_host.runner.world.state_hash(), after_buy, "Vender muda o mundo.")


func test_it_refreshes_by_itself_every_second_and_keeps_the_choice_and_the_focus() -> void:
	_view.open(_market_id)
	_select(WOOD, 1)
	var bread_before: Array[String] = _row_of(BREAD)
	assert_true(_economy.request_trade(_actor_id, _market_id, BREAD, 1, BridgePlayerEconomyReplies.SIDE_BUY).result.ok, "Uma mudança de fora (outro comprador).")
	simulate(_view, 1, MarketView.REFRESH_INTERVAL_S * 0.4)
	assert_eq(_row_of(BREAD), bread_before, "Dentro do intervalo a tela ainda mostra a leitura antiga.")
	simulate(_view, 1, MarketView.REFRESH_INTERVAL_S * 0.7)
	_assert_screen_matches_the_bridge()
	assert_ne(_row_of(BREAD), bread_before, "Passado o intervalo a tela mostra a nova.")
	assert_eq(_tree().get_selected().get_text(MarketLayout.COLUMN_NAME), _text("good.wood.name"), "A escolha (por bem) sobrevive à atualização.")
	assert_true(_tree().has_focus(), "O foco também.")


func test_a_good_in_shortage_shows_the_shortage_text_in_the_stock_cell() -> void:
	_view = _make_view(ShortageBridge.new(_host, _terrain, _places), _actor_id)
	_view.open(_market_id)
	assert_eq(_items().size(), 10, "Uma linha por bem do mercado.")
	for item: TreeItem in _items():
		var good_id: String = str(item.get_metadata(MarketLayout.COLUMN_NAME))
		assert_eq(_row_of(good_id)[MarketLayout.COLUMN_STOCK], _text("ui.market.shortage", {"stock": _state(good_id)["stock"]}), "A célula de estoque de %s mostra a falta, com o estoque real." % good_id)
