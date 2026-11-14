extends GutTest
## LW-107e1, parte A (a ESTRUTURA): a aba "Contratos" da `MarketView` (src/presentation/ui/market/market_view.gd; contrato em docs/modules/presentation.md, "Quadro de contratos (LW-107)"), SÓ LEITURA, sem janela, com o jogo REAL (`res://data`),
## a ponte real e os textos reais (`data/text/pt_br.json`), montados como em `test_market_view.gd`: o jogador junto ao mercado A, com a conta aberta. Confere: o cabeçalho "Mercado | Contratos" troca a página só por `visible` e toda abertura
## começa na aba "Mercado"; a página de contratos tem o botão Fechar (que fecha como o do mercado) e a linha de dicas vazia e escondida; as 22 chaves `ui.contracts.*` existem e nenhum rótulo ou botão mostra `[chave]`; e abrir, trocar de aba,
## atualizar e fechar não mudam o `state_hash` nem enviam pedido (Aceitar e Entregar ficam SEMPRE desativados). As listas, as linhas, o prazo, o quadro vazio, "Vencido" e a indisponibilidade são da parte B. Os nós são achados pelos nomes fixos dos layouts.

const WORLD_DIR: String = "res://data/world"
const SEED: int = 107
const SETTLEMENT_A: String = "test_settlement_a"
const KEY_PREFIX: String = "ui.contracts."
const KEY_FOR_MISSING_TEXT: String = "\\[[a-z_]+(\\.[a-z_]+)+\\]"
## As 22 chaves da aba, sem o prefixo.
const CONTRACT_KEYS: Array[String] = [
	"tab_market", "tab_contracts", "title", "section_open", "section_mine", "empty", "empty_mine", "line", "reward", "deadline", "destination", "owned",
	"state.open", "state.accepted", "state.completed", "state.expired", "expired_note", "accept", "deliver", "hint_accept", "hint_deliver", "unavailable",
]
const TAB_MARKET: String = "MarketTabMarket"
const TAB_CONTRACTS: String = "MarketTabContracts"
const GOODS: String = "MarketGoods"
const OPEN_LIST: String = "ContractsOpen"
const ACCEPT: String = "ContractsAccept"
const DELIVER: String = "ContractsDeliver"
const CLOSE: String = "ContractsClose"
## Os filhos visíveis da coluna do painel em cada aba: a página do mercado é a da LW-106 inteira; a de contratos é uma só.
const MARKET_PAGE: Array[String] = ["MarketTabs", "MarketTitle", "MarketStatusRow", "MarketGoods", "MarketActionRow", "MarketResult", "MarketHints"]
const CONTRACTS_PAGE: Array[String] = ["MarketTabs", "ContractsPage"]

var _terrain: TerrainData
var _places: Array[Place] = []
var _setup: EconomySetup
var _texts: UiText
var _center_a: Vector3
var _host: SimulationHostNode
var _bridge: SpyBridge
var _economy: EconomyModule
var _actor_id: int = 0
var _market_a: int = 0
var _view: MarketView


## Ponte que ANOTA todo pedido (a aba só lê: nenhum pode sair) e repassa à de verdade.
class SpyBridge:
	extends SimBridge

	var sent: Array[String] = []

	func request_trade(actor_id: int, market_id: int, good_id: String, quantity: int, side: String) -> BridgePlayerEconomyReplies.PlayerTradeReply:
		sent.append("trade")
		return super(actor_id, market_id, good_id, quantity, side)

	func request_contract_accept(actor_id: int, contract_id: int) -> BridgePlayerContractsReplies.ContractActionReply:
		sent.append("accept")
		return super(actor_id, contract_id)

	func request_contract_deliver(actor_id: int, contract_id: int) -> BridgePlayerContractsReplies.ContractActionReply:
		sent.append("deliver")
		return super(actor_id, contract_id)


func before_all() -> void:
	var loaded: TerrainLoader.LoadResult = TerrainLoader.load_dir(WORLD_DIR)
	assert_true(loaded.result.ok, loaded.result.message)
	_terrain = loaded.terrain
	var settlements: SettlementLoader.LoadResult = SettlementLoader.load_dir(WORLD_DIR, _terrain)
	assert_true(settlements.result.ok, settlements.result.message)
	_places = settlements.places
	for place: Place in _places:
		if place.kind == Place.KIND_MARKET and place.settlement_id == SETTLEMENT_A:
			_center_a = place.position
	_setup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR)
	assert_true(_setup.result.ok, _setup.result.message)
	var texts: UiText.LoadResult = UiText.from_file(UiText.DEFAULT_PATH)
	assert_true(texts.result.ok, texts.result.message)
	_texts = texts.texts


## Um jogo só com o personagem e a economia (sem NPCs), com o jogador junto ao mercado A e a conta aberta (o relógio está no minuto 0), e a tela FECHADA, ligada a uma ponte espiã.
func before_each() -> void:
	_host = SimulationHostNode.new()
	_host.start_new_game(SEED, _terrain, [], null, 0, _setup)
	_bridge = SpyBridge.new(_host, _terrain, _places)
	_economy = _host.economy
	_actor_id = _bridge.request_spawn_character().actor_id
	assert_true(_bridge.request_report_position(_actor_id, _center_a, 0.0).ok, "O jogador começa junto ao mercado A.")
	assert_true(_bridge.request_open_player_account(_actor_id).ok)
	_market_a = _economy.peek_market_of(SETTLEMENT_A).market_id
	_view = MarketView.new()
	add_child_autofree(_view)
	assert_true(_view.setup(_bridge, _texts, _actor_id, [] as Array[Node]))


func after_each() -> void:
	_host.runner.finish()
	_host.free()


func _text(key: String, values: Dictionary = {}) -> String:
	return _texts.get_text(key, values)


func _say(key: String) -> String:
	return _text(KEY_PREFIX + key)


func _node(node_name: String) -> Node:
	return _view.find_child(node_name, true, false)


func _tree(list_name: String) -> Tree:
	return _node(list_name) as Tree


func _press(button_name: String) -> void:
	(_node(button_name) as Button).pressed.emit()


func _is_off(button_name: String) -> bool:
	return (_node(button_name) as Button).disabled


func _action(action: StringName) -> InputEventAction:
	var event: InputEventAction = InputEventAction.new()
	event.action = action
	event.pressed = true
	return event


## Abre a tela sobre o mercado A e escolhe a aba "Contratos".
func _open_contracts() -> void:
	_view.open(_market_a)
	_press(TAB_CONTRACTS)


func _visible_children() -> Array[String]:
	var names: Array[String] = []
	for child: Node in _node("MarketColumn").get_children():
		if (child as Control).visible:
			names.append(String(child.name))
	return names


func _pressed_tabs() -> Array:
	return [(_node(TAB_MARKET) as Button).button_pressed, (_node(TAB_CONTRACTS) as Button).button_pressed]


func test_the_header_switches_the_pages_only_by_visibility_and_every_opening_starts_on_the_market_page() -> void:
	assert_eq([(_node(TAB_MARKET) as Button).text, (_node(TAB_CONTRACTS) as Button).text], [_say("tab_market"), _say("tab_contracts")], "Os dois botões do cabeçalho têm texto por chave.")
	_view.open(_market_a)
	assert_eq([_visible_children(), _pressed_tabs(), _tree(GOODS).has_focus()], [MARKET_PAGE, [true, false], true], "Ao abrir: a página do mercado inteira, a aba Mercado escolhida e a tabela com o foco.")
	_press(TAB_CONTRACTS)
	assert_eq([_visible_children(), _pressed_tabs(), _tree(OPEN_LIST).has_focus()], [CONTRACTS_PAGE, [false, true], true], "Na aba Contratos: só a página dela, a aba escolhida e o foco na primeira lista.")
	_press(TAB_MARKET)
	assert_eq([_visible_children(), _pressed_tabs(), _tree(GOODS).has_focus()], [MARKET_PAGE, [true, false], true], "De volta ao Mercado: o foco volta à tabela.")
	_press(TAB_CONTRACTS)
	_view._input(_action(MarketView.ACTION_CANCEL))
	assert_false(_view.is_open(), "ui_cancel fecha também com a aba Contratos escolhida.")
	_view.open(_market_a)
	assert_eq([_visible_children(), _pressed_tabs()], [MARKET_PAGE, [true, false]], "Toda abertura começa na aba Mercado.")


func test_the_contracts_page_has_a_close_button_like_the_markets_and_its_hints_line_stays_empty_and_hidden() -> void:
	watch_signals(_view)
	_open_contracts()
	var hints: Label = _node("ContractsHints") as Label
	assert_eq([(_node(CLOSE) as Button).text, hints.text, hints.visible], [_text("ui.market.close"), "", false], "Fechar reaproveita `ui.market.close`; a linha de dicas da LW-107e2 existe, vazia e escondida.")
	_press(CLOSE)
	assert_false(_view.is_open(), "O clique fecha a tela, como o botão do mercado.")
	_view.open(_market_a)
	_press("MarketClose")
	assert_false(_view.is_open())
	assert_signal_emit_count(_view, "closed", 2)


func test_every_contract_key_exists_and_no_label_or_button_shows_a_missing_key() -> void:
	assert_eq(CONTRACT_KEYS.size(), 22, "As 22 chaves do contrato.")
	for key: String in CONTRACT_KEYS:
		assert_true(_texts.has_key(KEY_PREFIX + key), "Falta a chave '%s%s' em data/text/pt_br.json." % [KEY_PREFIX, key])
	_open_contracts()
	var missing: RegEx = RegEx.create_from_string(KEY_FOR_MISSING_TEXT)
	var shown: Array[String] = []
	for node: Node in _view.find_children("*", "", true, false):
		if node is Label or node is Button:
			shown.append(str(node.get("text")))
	assert_true(shown.has(_say("title")) and shown.has(_say("section_open")) and shown.has(_say("section_mine")) and shown.has(_say("accept")) and shown.has(_say("deliver")), "O título, as duas seções e os botões estão na tela, com o texto da chave.")
	for text: String in shown:
		assert_null(missing.search(text), "Texto de chave que falta: %s." % text)


func test_opening_switching_tabs_refreshing_and_closing_never_change_the_state_hash_and_nothing_is_sent() -> void:
	var hash_before: String = _host.runner.world.state_hash()
	var minutes_before: int = _bridge.peek_time().total_minutes
	_view.open(_market_a)
	_press(TAB_CONTRACTS)
	_view.refresh()
	simulate(_view, 1, MarketView.REFRESH_INTERVAL_S)
	_press(ACCEPT)
	_press(DELIVER)
	_press(TAB_MARKET)
	_press(TAB_CONTRACTS)
	_view.close()
	assert_eq([_host.runner.world.state_hash(), _bridge.peek_time().total_minutes, _bridge.sent, _is_off(ACCEPT), _is_off(DELIVER)], [hash_before, minutes_before, [] as Array[String], true, true], "Só consultas: o `state_hash` e o relógio ficam como estavam, nenhum pedido sai e os dois botões seguem desativados.")
