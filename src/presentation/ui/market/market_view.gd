class_name MarketView
extends CanvasLayer
## A ORQUESTRAÇÃO da tela de mercado do jogador (LW-106d2; contrato em docs/modules/presentation.md, "Interface de mercado (LW-106)"): liga o `MarketViewModel` (dados), o `MarketLayout` (nós) e o `MarketTheme` (estilo, posto SÓ no
## `Control` raiz), escreve os textos (só por chave, `UiText`) e decide quando abrir, fechar, atualizar, comprar e vender. É a ÚNICA que envia pedidos (`request_trade`) e a única que mexe em outros nós: os de `frozen` ficam parados
## (`process_mode` desligado) enquanto a tela está aberta e voltam ao valor anterior ao fechar. NÃO tem regra de jogo, não calcula total nem distância: só consultas e `request_trade`, e a recusa é o `text_key` da resposta. O tempo
## do mundo continua andando (a tela não pausa nada). Nasce FECHADA; `setup` só uma vez.
## LW-107e1 (contrato em "Quadro de contratos (LW-107)"): a tela ganha a aba "Contratos", SÓ LEITURA. Liga o `ContractsViewModel` (dados) e o `ContractsLayout` (nós), escreve os textos por chave e refaz a consulta de contratos no
## MESMO ritmo da tela (junto do `refresh`). O cabeçalho "Mercado | Contratos" troca a página só por `visible`; ao abrir, a aba "Mercado" vem escolhida. Aceitar e Entregar existem e ficam SEMPRE desativados: a LW-107e2 liga as
## regras e o envio dos pedidos (nada além das consultas vai à ponte). Fechar, na aba, fecha a tela como o do mercado. A divisão em "Disponíveis" e "Meus contratos" e o estado mostrado (`display_state`) são do modelo: a tela só os escreve.

## Valores [HIP]: a camada (acima do HUD) e o intervalo das consultas com a tela aberta (preço, estoque e dinheiro mudam sozinhos).
const LAYER_INDEX: int = 10
const REFRESH_INTERVAL_S: float = 1.0
## A ação padrão do Godot que fecha a tela (a outra é `InputActions.INTERACT`).
const ACTION_CANCEL: StringName = &"ui_cancel"
const ROOT_NAME: String = "MarketRoot"
## Chaves de texto usadas aqui (as frases moram em data/text/pt_br.json).
const KEY_TITLE: String = "ui.market.title"
const KEY_FUNDS: String = "ui.market.funds"
const KEY_WEIGHT: String = "ui.market.weight"
const KEY_BUY: String = "ui.market.buy"
const KEY_SELL: String = "ui.market.sell"
const KEY_CLOSE: String = "ui.market.close"
const KEY_SHORTAGE: String = "ui.market.shortage"
const KEY_TOTAL: String = "ui.market.total"
const KEY_UNAVAILABLE: String = "ui.market.unavailable"
const KEY_QUANTITY_PREFIX: String = "ui.market.quantity_prefix"
const KEY_HINTS: String = "ui.market.hints"
const KEY_GOOD_NAME: String = "good.%s.name"
## Chaves de texto da aba "Contratos" (LW-107e1); o estado mostrado entra pelo prefixo (`ui.contracts.state.open`, `accepted`, `completed` e `expired`).
const KEY_TAB_MARKET: String = "ui.contracts.tab_market"
const KEY_TAB_CONTRACTS: String = "ui.contracts.tab_contracts"
const KEY_CONTRACTS_TITLE: String = "ui.contracts.title"
const KEY_SECTION_OPEN: String = "ui.contracts.section_open"
const KEY_SECTION_MINE: String = "ui.contracts.section_mine"
const KEY_EMPTY: String = "ui.contracts.empty"
const KEY_EMPTY_MINE: String = "ui.contracts.empty_mine"
const KEY_LINE: String = "ui.contracts.line"
const KEY_REWARD: String = "ui.contracts.reward"
const KEY_DEADLINE: String = "ui.contracts.deadline"
const KEY_DESTINATION: String = "ui.contracts.destination"
const KEY_OWNED: String = "ui.contracts.owned"
const KEY_STATE_PREFIX: String = "ui.contracts.state."
const KEY_EXPIRED_NOTE: String = "ui.contracts.expired_note"
const KEY_ACCEPT: String = "ui.contracts.accept"
const KEY_DELIVER: String = "ui.contracts.deliver"
const KEY_CONTRACTS_UNAVAILABLE: String = "ui.contracts.unavailable"
const KEY_SETTLEMENT_NAME: String = "settlement.%s.name"
## Separador das informações do detalhe da linha escolhida (como na linha de dicas do mercado).
const FACT_SEPARATOR: String = " · "
const COLUMN_KEYS: Dictionary[int, String] = {
	MarketLayout.COLUMN_NAME: "ui.market.column_name",
	MarketLayout.COLUMN_ASK: "ui.market.column_ask",
	MarketLayout.COLUMN_BID: "ui.market.column_bid",
	MarketLayout.COLUMN_STOCK: "ui.market.column_stock",
	MarketLayout.COLUMN_OWNED: "ui.market.column_owned",
}

## Sai uma vez cada vez que a tela fecha (só se estava aberta).
signal closed

var _bridge: SimBridge
var _texts: UiText
var _actor_id: int = IdGenerator.NO_ID
var _market_id: int = IdGenerator.NO_ID
var _frozen: Array[Node] = []
var _previous_modes: Dictionary[Node, Node.ProcessMode] = {}
var _layout: MarketLayout = MarketLayout.new()
var _model: MarketViewModel = MarketViewModel.new()
var _contracts_layout: ContractsLayout = ContractsLayout.new()
var _contracts_model: ContractsViewModel = ContractsViewModel.new()
var _contract_rows: Dictionary[int, ContractsViewModel.Row] = {}
var _chosen_contract: int = IdGenerator.NO_ID
var _items: Dictionary[String, TreeItem] = {}
var _refresh_left_s: float = 0.0


func _init() -> void:
	layer = LAYER_INDEX
	visible = false


func _ready() -> void:
	set_process(false)


## Liga a tela à ponte, aos textos, ao jogador (`actor_id`) e aos nós que ficam parados enquanto ela está aberta (`frozen`; a cena passa o `PlayerBody` e a câmera), e cria os nós. Ponte ou textos nulos: push_error e falso.
func setup(bridge: SimBridge, texts: UiText, actor_id: int, frozen: Array[Node]) -> bool:
	if bridge == null or texts == null:
		push_error("MarketView.setup: ponte ou textos nulos; esperado os dois.")
		return false
	_bridge = bridge
	_texts = texts
	_actor_id = actor_id
	_frozen.assign(frozen)
	var root: Control = Control.new()
	root.name = ROOT_NAME
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.theme = MarketTheme.build()
	add_child(root)
	_layout.build(root)
	_layout.title.text = _texts.get_text(KEY_TITLE)
	_layout.buy_button.text = _texts.get_text(KEY_BUY)
	_layout.sell_button.text = _texts.get_text(KEY_SELL)
	_layout.close_button.text = _texts.get_text(KEY_CLOSE)
	_layout.quantity.prefix = _texts.get_text(KEY_QUANTITY_PREFIX)
	for column: int in COLUMN_KEYS:
		_layout.goods.set_column_title(column, _texts.get_text(COLUMN_KEYS[column]))
	_layout.buy_button.pressed.connect(buy)
	_layout.sell_button.pressed.connect(sell)
	_layout.close_button.pressed.connect(close)
	_setup_contracts()
	return true


func is_open() -> bool:
	return visible


## Abre a tela sobre o mercado `market_id`: para os nós de `frozen` (guarda o `process_mode` de cada um), mostra, escolhe a aba "Mercado", limpa as linhas de resultado, refaz as consultas e dá o foco à tabela, com a primeira linha
## escolhida se nenhuma estava. Já aberta, só troca de mercado, volta à aba "Mercado" e refaz as consultas. Sem `setup`: nada acontece.
func open(market_id: int) -> void:
	if _bridge == null:
		return
	if market_id != _market_id:
		_clear_rows()
	_market_id = market_id
	if not visible:
		for node: Node in _frozen:
			if is_instance_valid(node):
				_previous_modes[node] = node.process_mode
				node.process_mode = Node.PROCESS_MODE_DISABLED
		visible = true
		set_process(true)
	_layout.result.text = ""
	_contracts_layout.result.text = ""
	_layout.hints.text = _texts.get_text(KEY_HINTS, {"cancel_key": _key_of(ACTION_CANCEL), "interact_key": _key_of(InputActions.INTERACT)})
	_show_page(false)
	refresh()
	_layout.goods.grab_focus()


## Fecha a tela: devolve o `process_mode` guardado a cada nó de `frozen`, esconde e emite `closed`. Fechada, não faz nada.
func close() -> void:
	if not visible:
		return
	visible = false
	set_process(false)
	for node: Node in _previous_modes:
		if is_instance_valid(node):
			node.process_mode = _previous_modes[node]
	_previous_modes.clear()
	closed.emit()


## Refaz as consultas (modelo, textos e linhas), PRESERVANDO a escolha (por `good_id`) e o foco: as linhas são atualizadas no lugar. Falhou (sem jogo ou sem conta): sem linhas, com `ui.market.unavailable` na linha de resultado.
## Comprar e Vender só ficam ativos com a tela válida e o relógio andando. Refaz também a consulta de contratos da aba (LW-107e1), no mesmo ritmo, esteja ela escolhida ou não.
func refresh() -> void:
	if _bridge == null:
		return
	_refresh_left_s = REFRESH_INTERVAL_S
	var is_valid: bool = _model.refresh(_bridge, _actor_id, _market_id)
	if is_valid:
		_layout.funds.text = _texts.get_text(KEY_FUNDS, {"funds": _model.funds()})
		_layout.weight.text = _texts.get_text(KEY_WEIGHT, {"weight": _model.weight(), "capacity": _model.capacity()})
		_show_rows(_model.rows())
	else:
		_layout.funds.text = ""
		_layout.weight.text = ""
		_clear_rows()
		_layout.result.text = _texts.get_text(KEY_UNAVAILABLE)
	_layout.buy_button.disabled = not is_valid or _is_game_paused()
	_layout.sell_button.disabled = _layout.buy_button.disabled
	_refresh_contracts()


## Pede a COMPRA do bem escolhido, na quantidade do campo. Sem bem escolhido, tela inválida, relógio pausado ou tela fechada: não envia nada.
func buy() -> void:
	_trade(BridgePlayerEconomyReplies.SIDE_BUY)


## Pede a VENDA do bem escolhido, na quantidade do campo (mesmas condições de `buy`).
func sell() -> void:
	_trade(BridgePlayerEconomyReplies.SIDE_SELL)


func _process(delta: float) -> void:
	_refresh_left_s -= delta
	if _refresh_left_s <= 0.0:
		refresh()


## `_input` e não `_unhandled_input`: o campo de quantidade tem o foco e consumiria a tecla antes. Aberta, `ui_cancel` e `interact` fecham e o evento é dado como tratado; fechada, nada é tocado (a `InteractionView` ainda lê a tecla).
func _input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed(ACTION_CANCEL) or event.is_action_pressed(InputActions.INTERACT)):
		close()
		get_viewport().set_input_as_handled()


func _trade(side: String) -> void:
	var good_id: String = _selected_good_id()
	if not visible or good_id.is_empty() or not _model.is_valid() or _is_game_paused():
		return
	var reply: BridgePlayerEconomyReplies.PlayerTradeReply = _bridge.request_trade(_actor_id, _market_id, good_id, int(_layout.quantity.value), side)
	var message: String = _texts.get_text(reply.text_key)
	if reply.result.ok:
		message = "%s %s" % [message, _texts.get_text(KEY_TOTAL, {"total": reply.total})]
	_layout.result.text = message
	refresh()


## Pausa do relógio, lida pela ponte; hora indisponível conta como não pausado.
func _is_game_paused() -> bool:
	var time: BridgeReplies.TimeSnapshot = _bridge.peek_time()
	return time.result.ok and time.is_paused


func _selected_good_id() -> String:
	var item: TreeItem = _layout.goods.get_selected()
	return str(item.get_metadata(MarketLayout.COLUMN_NAME)) if item != null else ""


## Uma linha por bem, cada uma criada uma vez e depois atualizada no lugar (a escolha, o foco e a rolagem da tabela sobrevivem); a primeira linha é escolhida se nenhuma está.
func _show_rows(rows: Array[MarketViewModel.Row]) -> void:
	var tree: Tree = _layout.goods
	if tree.get_root() == null:
		tree.create_item()
	for row: MarketViewModel.Row in rows:
		var item: TreeItem = _items.get(row.good_id) as TreeItem
		if item == null:
			item = tree.create_item(tree.get_root())
			_items[row.good_id] = item
		item.set_metadata(MarketLayout.COLUMN_NAME, row.good_id)
		item.set_text(MarketLayout.COLUMN_NAME, _texts.get_text(KEY_GOOD_NAME % row.good_id))
		item.set_text(MarketLayout.COLUMN_ASK, str(row.ask))
		item.set_text(MarketLayout.COLUMN_BID, str(row.bid))
		item.set_text(MarketLayout.COLUMN_STOCK, _texts.get_text(KEY_SHORTAGE, {"stock": row.stock}) if row.is_in_shortage else str(row.stock))
		item.set_text(MarketLayout.COLUMN_OWNED, str(row.owned))
	var first: TreeItem = tree.get_root().get_first_child()
	if tree.get_selected() == null and first != null:
		first.select(MarketLayout.COLUMN_NAME)


func _clear_rows() -> void:
	_layout.goods.clear()
	_items.clear()


## A aba "Contratos" (LW-107e1): cria a página irmã da do mercado, escreve os textos, liga os cliques e escolhe a aba "Mercado". Só leitura: Aceitar e Entregar ficam DESATIVADOS (a LW-107e2 liga as regras e o envio dos pedidos). Fechar usa o
## texto `ui.market.close` e o MESMO `close` do botão do mercado; a linha de dicas fica vazia e ESCONDIDA (a LW-107e2 a preenche, com `hint_accept` e `hint_deliver`, e a mostra).
func _setup_contracts() -> void:
	var page: ContractsLayout = _contracts_layout
	page.build(_layout.column)
	_layout.market_tab.text = _texts.get_text(KEY_TAB_MARKET)
	_layout.contracts_tab.text = _texts.get_text(KEY_TAB_CONTRACTS)
	page.title.text = _texts.get_text(KEY_CONTRACTS_TITLE)
	page.open_title.text = _texts.get_text(KEY_SECTION_OPEN)
	page.mine_title.text = _texts.get_text(KEY_SECTION_MINE)
	page.accept_button.text = _texts.get_text(KEY_ACCEPT)
	page.deliver_button.text = _texts.get_text(KEY_DELIVER)
	page.accept_button.disabled = true
	page.deliver_button.disabled = true
	page.close_button.text = _texts.get_text(KEY_CLOSE)
	page.hints.visible = false
	_layout.market_tab.pressed.connect(_show_page.bind(false))
	_layout.contracts_tab.pressed.connect(_show_page.bind(true))
	page.close_button.pressed.connect(close)
	page.open_list.item_selected.connect(_choose.bind(page.open_list))
	page.mine_list.item_selected.connect(_choose.bind(page.mine_list))
	_show_page(false)


## Mostra UMA das duas páginas (a do mercado ou a de contratos), marca a aba escolhida e, com a tela aberta, dá o foco à lista principal da página. Só `visible` muda: nenhum nó muda de pai.
func _show_page(is_contracts: bool) -> void:
	for node: Control in _layout.market_page:
		node.visible = not is_contracts
	_contracts_layout.page.visible = is_contracts
	_layout.market_tab.set_pressed_no_signal(not is_contracts)
	_layout.contracts_tab.set_pressed_no_signal(is_contracts)
	if visible:
		(_contracts_layout.open_list if is_contracts else _layout.goods).grab_focus()


## Refaz a consulta de contratos e as duas listas, PRESERVANDO a escolha (por `contract_id`; uma só nas duas listas; sem escolha válida, a primeira linha) e o foco. Falhou (sem jogo ou sem conta): listas vazias, sem
## número da leitura anterior, e `ui.contracts.unavailable` na linha de resultado da aba. Aceitar e Entregar seguem desativados.
func _refresh_contracts() -> void:
	var is_valid: bool = _contracts_model.refresh(_bridge, _actor_id, _market_id)
	var open_rows: Array[ContractsViewModel.Row] = _contracts_model.available()
	var mine_rows: Array[ContractsViewModel.Row] = _contracts_model.mine()
	var listed: Array[ContractsViewModel.Row] = open_rows + mine_rows
	_contract_rows.clear()
	for row: ContractsViewModel.Row in listed:
		_contract_rows[row.contract_id] = row
	if not _contract_rows.has(_chosen_contract):
		_chosen_contract = listed[0].contract_id if not listed.is_empty() else IdGenerator.NO_ID
	if is_valid:
		_fill_list(_contracts_layout.open_list, open_rows, KEY_EMPTY)
		_fill_list(_contracts_layout.mine_list, mine_rows, KEY_EMPTY_MINE)
	else:
		_contracts_layout.open_list.clear()
		_contracts_layout.mine_list.clear()
		_contracts_layout.result.text = _texts.get_text(KEY_CONTRACTS_UNAVAILABLE)
	_show_detail()


## Refaz uma lista: uma linha por contrato (o `contract_id` fica no metadado da primeira coluna) e a escolhida volta a ser escolhida; lista vazia mostra a mensagem da chave, numa linha que não se escolhe. [LIM] Refazer a lista reinicia a rolagem (aceito: a escolha e
## o foco sobrevivem).
func _fill_list(tree: Tree, rows: Array[ContractsViewModel.Row], empty_key: String) -> void:
	tree.clear()
	var root: TreeItem = tree.create_item()
	if rows.is_empty():
		var note: TreeItem = tree.create_item(root)
		note.set_text(ContractsLayout.COLUMN_LINE, _texts.get_text(empty_key))
		note.set_expand_right(ContractsLayout.COLUMN_LINE, true)
		for column: int in ContractsLayout.COLUMN_COUNT:
			note.set_selectable(column, false)
		return
	for row: ContractsViewModel.Row in rows:
		var item: TreeItem = tree.create_item(root)
		var deadline: String = _deadline_of(row)
		item.set_metadata(ContractsLayout.COLUMN_LINE, row.contract_id)
		item.set_text(ContractsLayout.COLUMN_LINE, _line_of(row))
		item.set_text(ContractsLayout.COLUMN_REWARD, _reward_of(row))
		item.set_text(ContractsLayout.COLUMN_WHEN, deadline if not deadline.is_empty() else _state_of(row))
		if row.contract_id == _chosen_contract:
			item.select(ContractsLayout.COLUMN_LINE)


## A linha que acabou de ser escolhida numa das listas passa a ser A escolhida: a escolha da outra lista sai e o detalhe mostra a nova.
func _choose(tree: Tree) -> void:
	var item: TreeItem = tree.get_selected()
	if item == null:
		return
	_chosen_contract = int(item.get_metadata(ContractsLayout.COLUMN_LINE))
	var other: Tree = _contracts_layout.mine_list if tree == _contracts_layout.open_list else _contracts_layout.open_list
	other.deselect_all()
	_show_detail()


func _show_detail() -> void:
	var row: ContractsViewModel.Row = _contract_rows.get(_chosen_contract) as ContractsViewModel.Row
	_contracts_layout.detail.text = "" if row == null else _facts_of(row)


## As informações do detalhe da linha escolhida, na ordem do contrato: bem e quantidade, recompensa, prazo restante (só se há), destino (só se é um mercado), "você tem X de Y", estado e, no vencido, a nota da falha por prazo.
func _facts_of(row: ContractsViewModel.Row) -> String:
	var destination: String = ""
	if not row.destination_settlement_id.is_empty():
		destination = _texts.get_text(KEY_DESTINATION, {"destination": _texts.get_text(KEY_SETTLEMENT_NAME % row.destination_settlement_id)})
	var note: String = _texts.get_text(KEY_EXPIRED_NOTE) if row.display_state == ContractsViewModel.STATE_EXPIRED else ""
	var owned: String = _texts.get_text(KEY_OWNED, {"owned": row.owned, "quantity": row.quantity})
	var shown: PackedStringArray = []
	for fact: String in [_line_of(row), _reward_of(row), _deadline_of(row), destination, owned, _state_of(row), note]:
		if not fact.is_empty():
			shown.append(fact)
	return FACT_SEPARATOR.join(shown)


func _line_of(row: ContractsViewModel.Row) -> String:
	return _texts.get_text(KEY_LINE, {"quantity": row.quantity, "good": _texts.get_text(KEY_GOOD_NAME % row.good_id)})


func _reward_of(row: ContractsViewModel.Row) -> String:
	return _texts.get_text(KEY_REWARD, {"reward": row.reward})


## O estado que a tela MOSTRA (`display_state`): "Vencido" para todo contrato de prazo passado.
func _state_of(row: ContractsViewModel.Row) -> String:
	return _texts.get_text(KEY_STATE_PREFIX + row.display_state)


## O prazo restante em dias, horas e minutos, SÓ para a linha `open` ou `accepted` que NÃO venceu (a regra usa `display_state`, nunca `is_overdue` sozinho); vazio nas demais: a `expired` mostra "Vencido" no lugar dele e a `completed`
## não mostra prazo nenhum, mesmo com o prazo passado.
func _deadline_of(row: ContractsViewModel.Row) -> String:
	if row.display_state != ContractsViewModel.STATE_OPEN and row.display_state != ContractsViewModel.STATE_ACCEPTED:
		return ""
	var day: int = IntMath.floor_div(row.minutes_left, SimClock.MINUTES_PER_DAY)
	var hour: int = IntMath.floor_div(row.minutes_left % SimClock.MINUTES_PER_DAY, SimClock.MINUTES_PER_HOUR)
	return _texts.get_text(KEY_DEADLINE, {"d": day, "h": hour, "m": row.minutes_left % SimClock.MINUTES_PER_HOUR})


## Tecla da ação para a linha de dicas, lida do InputMap (primeira palavra do texto do evento, ex.: "E"), como a `InteractionView` faz com `interact`.
static func _key_of(action: StringName) -> String:
	var events: Array[InputEvent] = InputMap.action_get_events(action)
	return events[0].as_text().get_slice(" ", 0) if not events.is_empty() else "?"
