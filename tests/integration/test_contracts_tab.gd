extends GutTest
## LW-107e1 (critérios C7 e C8): a aba "Contratos" da `MarketView` (src/presentation/ui/market/market_view.gd; contrato em docs/modules/presentation.md, "Quadro de contratos (LW-107)"), SÓ LEITURA, sem janela, com o jogo REAL (`res://data`),
## a ponte real e os textos reais (`data/text/pt_br.json`), montados como em `test_market_view.gd` e `test_contracts_view_model.gd`: o jogador junto ao mercado A, com a conta aberta, os contratos postados DIRETO na economia (o jogador não
## posta) e o relógio andando pelo `runner` do jogo. Confere: o cabeçalho "Mercado | Contratos" troca a página só por `visible` e toda abertura começa na aba "Mercado"; as listas mostram as linhas da consulta, com a recompensa e o prazo
## restante (dias, horas e minutos); o quadro vazio mostra `ui.contracts.empty` e a aba segue utilizável; a linha de prazo passado (`open`, `accepted` ou `expired` da economia) mostra "Vencido" no lugar do prazo, e a `completed` de prazo
## passado só o estado; nenhum texto é `[chave]`; Aceitar e Entregar ficam SEMPRE desativados e nada além das consultas vai à ponte; relógio pausado, jogo sem conta e sem jogo dizem "indisponível" sem quebrar; e abrir, trocar de aba, atualizar
## e fechar não mudam o `state_hash`. Os nós da tela são achados pelos nomes fixos dos layouts: a tela não os expõe.

const WORLD_DIR: String = "res://data/world"
const SEED: int = 107
const SETTLEMENT_A: String = "test_settlement_a"
const SETTLEMENT_B: String = "test_settlement_b"
const SETTLEMENT_C: String = "test_settlement_c"
const BREAD: String = "bread"
const WOOD: String = "wood"
## Os números dos contratos do teste (os do jogo são [HIP]): recompensa, quantidade e prazos em minutos depois de agora. O quadro de `_build_board` é lido no minuto 100: o curto já venceu, o médio ainda consta aberto ou aceito (a
## economia só vence na hora cheia 120) e o longo falta 500 min (0 d 8 h 20 min). O contrato `FAR_MINUTES` tem 1 dia, 2 horas e 3 minutos.
const REWARD: int = 12
const QUANTITY: int = 2
const SHORT_MINUTES: int = 40
const MEDIUM_MINUTES: int = 90
const LONG_MINUTES: int = 600
const FAR_MINUTES: int = 1563
const BOARD_MINUTE: int = 100
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
const MINE_LIST: String = "ContractsMine"
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
var _market_b: int = 0
var _market_c: int = 0
var _view: MarketView
## As frases dos contratos do teste, escritas à mão a partir das chaves (o jogador não tem bem nenhum): o oráculo da tela.
var _p: Dictionary[String, String] = {}


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
	_market_b = _economy.peek_market_of(SETTLEMENT_B).market_id
	_market_c = _economy.peek_market_of(SETTLEMENT_C).market_id
	_view = _make_view(_bridge, _actor_id)
	_p = {
		"line": _say("line", {"quantity": QUANTITY, "good": _text("good.bread.name")}),
		"wood_line": _say("line", {"quantity": 1, "good": _text("good.wood.name")}),
		"reward": _say("reward", {"reward": REWARD}),
		"owned": _say("owned", {"owned": 0, "quantity": QUANTITY}),
		"to_b": _say("destination", {"destination": _text("settlement.%s.name" % SETTLEMENT_B)}),
		"to_c": _say("destination", {"destination": _text("settlement.%s.name" % SETTLEMENT_C)}),
		"accepted": _say("state.accepted"),
		"completed": _say("state.completed"),
		"expired": _say("state.expired"),
		"note": _say("expired_note"),
		"left_500": _left(0, 8, 20),
	}


func after_each() -> void:
	_host.runner.finish()
	_host.free()


func _make_view(bridge: SimBridge, actor_id: int) -> MarketView:
	var view: MarketView = MarketView.new()
	add_child_autofree(view)
	assert_true(view.setup(bridge, _texts, actor_id, [] as Array[Node]))
	return view


func _text(key: String, values: Dictionary = {}) -> String:
	return _texts.get_text(key, values)


func _say(key: String, values: Dictionary = {}) -> String:
	return _text(KEY_PREFIX + key, values)


func _left(days: int, hours: int, minutes: int) -> String:
	return _say("deadline", {"d": days, "h": hours, "m": minutes})


func _node(node_name: String) -> Node:
	return _view.find_child(node_name, true, false)


func _tree(list_name: String) -> Tree:
	return _node(list_name) as Tree


func _press(button_name: String) -> void:
	(_node(button_name) as Button).pressed.emit()


func _is_off(button_name: String) -> bool:
	return (_node(button_name) as Button).disabled


func _detail_text() -> String:
	return (_node("ContractsDetail") as Label).text


func _result_text() -> String:
	return (_node("ContractsResult") as Label).text


func _action(action: StringName) -> InputEventAction:
	var event: InputEventAction = InputEventAction.new()
	event.action = action
	event.pressed = true
	return event


## Abre a tela sobre o mercado A e escolhe a aba "Contratos".
func _open_contracts() -> void:
	_view.open(_market_a)
	_press(TAB_CONTRACTS)


func _items(tree: Tree) -> Array[TreeItem]:
	return tree.get_root().get_children() if tree.get_root() != null else ([] as Array[TreeItem])


## Os `contract_id` de uma lista, na ordem em que a tela os mostra (a linha da mensagem de lista vazia não tem id).
func _ids_of(list_name: String) -> Array[int]:
	var ids: Array[int] = []
	for item: TreeItem in _items(_tree(list_name)):
		if item.get_metadata(ContractsLayout.COLUMN_LINE) != null:
			ids.append(int(item.get_metadata(ContractsLayout.COLUMN_LINE)))
	return ids


## O texto das três colunas de cada linha de uma lista.
func _cells(list_name: String) -> Array:
	var cells: Array = []
	for item: TreeItem in _items(_tree(list_name)):
		var row: Array = []
		for column: int in ContractsLayout.COLUMN_COUNT:
			row.append(item.get_text(column))
		cells.append(row)
	return cells


## A linha do contrato, em qualquer das duas listas (nula se a tela não a mostra).
func _row_of(contract_id: int) -> TreeItem:
	for list_name: String in [OPEN_LIST, MINE_LIST]:
		for item: TreeItem in _items(_tree(list_name)):
			if item.get_metadata(ContractsLayout.COLUMN_LINE) == contract_id:
				return item
	return null


## A coluna do prazo (ou do estado) da linha do contrato.
func _when_of(contract_id: int) -> String:
	return _row_of(contract_id).get_text(ContractsLayout.COLUMN_WHEN)


func _select(contract_id: int) -> void:
	_row_of(contract_id).select(ContractsLayout.COLUMN_LINE)


func _visible_children() -> Array[String]:
	var names: Array[String] = []
	for child: Node in _node("MarketColumn").get_children():
		if (child as Control).visible:
			names.append(String(child.name))
	return names


func _pressed_tabs() -> Array:
	return [(_node(TAB_MARKET) as Button).button_pressed, (_node(TAB_CONTRACTS) as Button).button_pressed]


## Todo texto que a tela mostra agora: rótulos, botões (inclusive o cabeçalho) e as células de todas as tabelas e listas.
func _shown_texts() -> Array[String]:
	var shown: Array[String] = []
	for node: Node in _view.find_children("*", "", true, false):
		if node is Label or node is Button:
			shown.append(str(node.get("text")))
		elif node is Tree:
			for item: TreeItem in _items(node as Tree):
				for column: int in (node as Tree).columns:
					shown.append(item.get_text(column))
	return shown


## Posta um contrato de entrega direto na economia: `issuer` paga a recompensa para a custódia e o prazo é `minutes` depois de agora.
func _post(issuer: int, destination: int, minutes: int, good_id: String = BREAD, quantity: int = QUANTITY) -> int:
	var now: int = _bridge.peek_time().total_minutes
	var posted: EconomyReplies.PostContractResult = _economy.request_post_contract(ContractBook.DELIVERY, issuer, REWARD, now + minutes, {"good_id": good_id, "quantity": quantity, "destination_id": destination})
	assert_true(posted.result.ok, posted.result.message)
	return posted.contract_id


func _accept(contract_id: int) -> void:
	var accepted: Result = _economy.request_accept_contract(contract_id, _actor_id)
	assert_true(accepted.ok, accepted.message)


## Põe `quantity` do bem no inventário do jogador (tirado do mercado A, direto na economia, sem passar por compra).
func _give(good_id: String, quantity: int) -> void:
	var moved: Result = _economy.request_transfer_goods(_market_a, _actor_id, good_id, quantity)
	assert_true(moved.ok, moved.message)


## Posta, aceita e entrega na hora um contrato de pão de A para B: fica `completed`, com o prazo (`minutes` depois de agora) já passado ou por vir quando o quadro é lido.
func _complete(minutes: int) -> int:
	var contract_id: int = _post(_market_a, _market_b, minutes)
	_accept(contract_id)
	_give(BREAD, QUANTITY)
	var delivered: Result = _economy.request_deliver_contract(contract_id)
	assert_true(delivered.ok, delivered.message)
	return contract_id


## Um quadro com um contrato de cada situação, lido no minuto 100 (a mesma montagem de `test_contracts_view_model.gd`): `completed` (entregue no minuto 0, prazo já passado, A para B), `failed` (aceito e vencido pela economia na hora 60,
## A para B), `late_accepted` (aceito, prazo passado, ainda `accepted` na economia, C para C), `carried` (aceito, no prazo, C para C), `late_open` (aberto, prazo passado, ainda `open`, A para B) e `fresh_open` (aberto, no prazo, C para A;
## pede madeira). Devolve os IDs por nome.
func _build_board() -> Dictionary[String, int]:
	var ids: Dictionary[String, int] = {}
	ids["completed"] = _complete(SHORT_MINUTES)
	ids["failed"] = _post(_market_a, _market_b, SHORT_MINUTES)
	_accept(ids["failed"])
	ids["late_accepted"] = _post(_market_c, _market_c, MEDIUM_MINUTES)
	_accept(ids["late_accepted"])
	ids["carried"] = _post(_market_c, _market_c, LONG_MINUTES)
	_accept(ids["carried"])
	ids["late_open"] = _post(_market_a, _market_b, MEDIUM_MINUTES)
	ids["fresh_open"] = _post(_market_c, _market_a, LONG_MINUTES, WOOD, 1)
	_host.runner.run_steps(BOARD_MINUTE)
	return ids


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


func test_the_lists_show_the_boards_rows_with_their_reward_and_remaining_time_in_the_two_sections() -> void:
	var ids: Dictionary[String, int] = _build_board()
	_give(BREAD, 1)
	var board: BridgePlayerContractsReplies.ContractBoardReply = _bridge.peek_contract_board(_actor_id, _market_a)
	_open_contracts()
	assert_eq(board.now, BOARD_MINUTE, "Pré-condição: o relógio da consulta.")
	for source: BridgePlayerContractsReplies.ContractBoardRow in board.rows:
		assert_eq([_row_of(source.contract_id).get_text(ContractsLayout.COLUMN_REWARD), source.deadline - board.now > 0], [_say("reward", {"reward": source.reward}), source.contract_id in [ids["carried"], ids["fresh_open"]]], "A recompensa é a da consulta; só `carried` e `fresh_open` têm prazo a correr.")
	assert_eq([_ids_of(OPEN_LIST), _ids_of(MINE_LIST)], [[ids["late_open"], ids["fresh_open"]] as Array[int], [ids["late_accepted"], ids["carried"], ids["completed"], ids["failed"]] as Array[int]], "As duas seções, como o modelo as divide.")
	assert_eq(_cells(OPEN_LIST), [[_p["line"], _p["reward"], _p["expired"]], [_p["wood_line"], _p["reward"], _p["left_500"]]], "Disponíveis: o vencido mostra \"Vencido\"; o outro, o prazo (500 min = 0 d 8 h 20 min).")
	assert_eq(_cells(MINE_LIST), [[_p["line"], _p["reward"], _p["expired"]], [_p["line"], _p["reward"], _p["left_500"]], [_p["line"], _p["reward"], _p["completed"]], [_p["line"], _p["reward"], _p["expired"]]], "Meus contratos: aceitos primeiro, depois os terminados.")
	assert_true(_shown_texts().has(_say("title")) and _shown_texts().has(_say("section_open")) and _shown_texts().has(_say("section_mine")), "O título e os nomes das duas seções estão na tela.")
	assert_eq(_tree(OPEN_LIST).get_selected().get_metadata(ContractsLayout.COLUMN_LINE), ids["late_open"], "Sem escolha, a primeira linha da primeira lista.")
	_select(ids["carried"])
	assert_true(_tree(OPEN_LIST).get_selected() == null and _tree(MINE_LIST).get_selected() != null, "Uma escolha só, nas duas listas.")
	assert_eq(_detail_text(), MarketView.FACT_SEPARATOR.join([_p["line"], _p["reward"], _p["left_500"], _p["to_c"], _say("owned", {"owned": 1, "quantity": QUANTITY}), _p["accepted"]]), "O detalhe: bem, recompensa, prazo, destino, \"você tem 1 de 2\" e estado.")


func test_an_empty_board_shows_the_empty_messages_and_the_tab_stays_usable() -> void:
	_open_contracts()
	assert_eq(_say("empty"), "Nenhum contrato agora: os mercados estão abastecidos", "O texto do contrato.")
	assert_eq([_cells(OPEN_LIST), _cells(MINE_LIST)], [[[_say("empty"), "", ""]], [[_say("empty_mine"), "", ""]]], "As duas listas vazias dizem por que, numa linha só.")
	assert_false(_items(_tree(OPEN_LIST))[0].is_selectable(ContractsLayout.COLUMN_LINE), "A mensagem não se escolhe.")
	assert_eq([_ids_of(OPEN_LIST), _detail_text(), _result_text(), _is_off(ACCEPT), _is_off(DELIVER)], [[] as Array[int], "", "", true, true], "Quadro vazio não é erro: sem escolha, sem detalhe e sem aviso de indisponível.")
	_press(TAB_MARKET)
	_press(TAB_CONTRACTS)
	assert_eq([_visible_children(), _tree(OPEN_LIST).has_focus(), _cells(OPEN_LIST).size()], [CONTRACTS_PAGE, true, 1], "A aba segue utilizável: trocar de aba e voltar mostra a mesma coisa.")


func test_a_row_past_its_deadline_says_vencido_in_place_of_the_deadline_and_the_buttons_stay_off() -> void:
	var ids: Dictionary[String, int] = _build_board()
	_open_contracts()
	for contract_name: String in ["late_open", "late_accepted", "failed"]:
		_select(ids[contract_name])
		var destination: String = _p["to_c"] if contract_name == "late_accepted" else _p["to_b"]
		assert_eq(_detail_text(), MarketView.FACT_SEPARATOR.join([_p["line"], _p["reward"], destination, _p["owned"], _p["expired"], _p["note"]]), "'%s': \"Vencido\" no lugar do prazo, com a nota." % contract_name)
		assert_eq([_when_of(ids[contract_name]), _is_off(ACCEPT), _is_off(DELIVER)], [_p["expired"], true, true], "'%s': \"Vencido\" na lista e os dois botões desativados." % contract_name)
	_press(ACCEPT)
	_press(DELIVER)
	assert_eq(_bridge.sent, [] as Array[String], "Nada foi enviado.")


func test_the_remaining_time_counts_days_hours_and_minutes_and_turns_into_vencido_exactly_at_the_deadline() -> void:
	var far: int = _post(_market_a, _market_b, FAR_MINUTES)
	var soon_open: int = _post(_market_a, _market_b, SHORT_MINUTES)
	var soon_accepted: int = _post(_market_c, _market_c, SHORT_MINUTES)
	_accept(soon_accepted)
	_open_contracts()
	assert_eq([_when_of(far), _when_of(soon_open), _when_of(soon_accepted)], [_left(1, 2, 3), _left(0, 0, SHORT_MINUTES), _left(0, 0, SHORT_MINUTES)], "No minuto 0: dias, horas e minutos.")
	_host.runner.run_steps(SHORT_MINUTES - 1)
	_view.refresh()
	assert_eq([_when_of(far), _when_of(soon_open), _when_of(soon_accepted)], [_left(1, 1, 24), _left(0, 0, 1), _left(0, 0, 1)], "Um minuto antes do prazo: falta 1.")
	_host.runner.step_once()
	_view.refresh()
	assert_eq([_when_of(far), _when_of(soon_open), _when_of(soon_accepted)], [_left(1, 1, 23), _p["expired"], _p["expired"]], "No minuto do prazo o `open` e o `accepted` já são \"Vencido\", ainda que a economia só os vença na hora cheia.")


func test_a_completed_row_shows_only_its_state_never_vencido_or_a_deadline_with_the_deadline_past_or_still_to_come() -> void:
	var ids: Dictionary[String, int] = _build_board()
	var ahead: int = _complete(LONG_MINUTES)
	var board: BridgePlayerContractsReplies.ContractBoardReply = _bridge.peek_contract_board(_actor_id, _market_a)
	_open_contracts()
	for source: BridgePlayerContractsReplies.ContractBoardRow in board.rows:
		if source.contract_id in [ids["completed"], ahead]:
			assert_eq([source.state, source.deadline <= board.now], [ContractBook.STATE_COMPLETED, source.contract_id == ids["completed"]], "Pré-condição: os dois estão concluídos, um com o prazo passado e o outro com o prazo por vir.")
	for contract_id: int in [ids["completed"], ahead]:
		_select(contract_id)
		assert_eq([_when_of(contract_id), _detail_text()], [_p["completed"], MarketView.FACT_SEPARATOR.join([_p["line"], _p["reward"], _p["to_b"], _p["owned"], _p["completed"]])], "Só o estado: nem \"Vencido\", nem prazo, nem a nota.")


func test_every_contract_key_exists_and_no_text_of_the_tab_is_a_missing_key() -> void:
	assert_eq(CONTRACT_KEYS.size(), 22, "As 22 chaves do contrato.")
	for key: String in CONTRACT_KEYS:
		assert_true(_texts.has_key(KEY_PREFIX + key), "Falta a chave '%s%s' em data/text/pt_br.json." % [KEY_PREFIX, key])
	var ids: Dictionary[String, int] = _build_board()
	_open_contracts()
	var everything: Array[String] = _shown_texts()
	for contract_id: int in ids.values():
		_select(contract_id)
		everything.append(_detail_text())
	var missing: RegEx = RegEx.create_from_string(KEY_FOR_MISSING_TEXT)
	assert_gt(everything.size(), 2 * ids.size() + 10, "A varredura enxerga rótulos, botões, linhas das tabelas e os seis detalhes.")
	for shown: String in everything:
		assert_null(missing.search(shown), "Texto de chave que falta: %s." % shown)


func test_opening_switching_tabs_refreshing_and_closing_never_change_the_state_hash_and_nothing_is_sent() -> void:
	_build_board()
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
	assert_eq([_host.runner.world.state_hash(), _bridge.peek_time().total_minutes, _bridge.sent], [hash_before, minutes_before, [] as Array[String]], "Só consultas: o `state_hash` e o relógio ficam como estavam e nenhum pedido sai.")


func test_a_paused_clock_keeps_the_buttons_off_and_a_game_without_account_or_without_game_says_unavailable() -> void:
	_build_board()
	assert_true(_bridge.request_pause(true).ok)
	_open_contracts()
	assert_eq([_ids_of(OPEN_LIST).size(), _ids_of(MINE_LIST).size(), _is_off(ACCEPT), _is_off(DELIVER)], [2, 4, true, true], "Pausado, a aba mostra o quadro e os botões seguem desativados.")
	_press(ACCEPT)
	_press(DELIVER)
	assert_true(_bridge.request_pause(false).ok)
	_host.economy = null
	_view.refresh()
	assert_eq([_result_text(), _items(_tree(OPEN_LIST)).size(), _items(_tree(MINE_LIST)).size(), _detail_text()], [_say("unavailable"), 0, 0, ""], "A consulta passa a falhar: a aba apaga as linhas e o detalhe da leitura anterior.")
	_host.economy = _economy
	_view.open(_market_a)
	assert_eq([_result_text(), _ids_of(OPEN_LIST).size(), _ids_of(MINE_LIST).size()], ["", 2, 4], "Abrir de novo limpa o aviso e a aba volta a mostrar o quadro.")
	var idle_host: SimulationHostNode = SimulationHostNode.new()
	var unopened: int = _bridge.request_spawn_character().actor_id
	for pair: Array in [[SimBridge.new(idle_host, _terrain, _places), _actor_id], [_bridge, unopened]]:
		_view = _make_view(pair[0], pair[1])
		_open_contracts()
		assert_eq([_result_text(), _items(_tree(OPEN_LIST)).size(), _items(_tree(MINE_LIST)).size(), _detail_text(), _is_off(ACCEPT), _is_off(DELIVER)], [_say("unavailable"), 0, 0, "", true, true], "Sem jogo ou sem conta: indisponível, sem linhas nem número velho.")
		_view.close()
	assert_eq(_bridge.sent, [] as Array[String], "Nada foi enviado.")
	idle_host.free()


func test_the_tab_refreshes_by_itself_every_second_and_keeps_the_choice_and_the_focus() -> void:
	var ids: Dictionary[String, int] = _build_board()
	_open_contracts()
	_select(ids["carried"])
	_tree(MINE_LIST).grab_focus()
	_accept(ids["fresh_open"])
	simulate(_view, 1, MarketView.REFRESH_INTERVAL_S * 0.4)
	assert_eq(_ids_of(OPEN_LIST), [ids["late_open"], ids["fresh_open"]] as Array[int], "Dentro do intervalo a aba ainda mostra a leitura antiga.")
	simulate(_view, 1, MarketView.REFRESH_INTERVAL_S * 0.7)
	assert_eq([_ids_of(OPEN_LIST), _ids_of(MINE_LIST)], [[ids["late_open"]] as Array[int], [ids["late_accepted"], ids["carried"], ids["fresh_open"], ids["completed"], ids["failed"]] as Array[int]], "Passado o intervalo o contrato aceito de fora foi para Meus contratos.")
	assert_eq([_tree(MINE_LIST).get_selected().get_metadata(ContractsLayout.COLUMN_LINE), _tree(OPEN_LIST).get_selected() == null, _tree(MINE_LIST).has_focus()], [ids["carried"], true, true], "A escolha (por contrato, uma só nas duas listas) e o foco sobrevivem.")
	assert_string_contains(_detail_text(), _p["accepted"])
