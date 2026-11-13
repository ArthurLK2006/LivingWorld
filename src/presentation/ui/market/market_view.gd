class_name MarketView
extends CanvasLayer
## A ORQUESTRAÇÃO da tela de mercado do jogador (LW-106d2; contrato em docs/modules/presentation.md, "Interface de mercado (LW-106)"): liga o `MarketViewModel` (dados), o `MarketLayout` (nós) e o `MarketTheme` (estilo, posto SÓ no
## `Control` raiz), escreve os textos (só por chave, `UiText`) e decide quando abrir, fechar, atualizar, comprar e vender. É a ÚNICA que envia pedidos (`request_trade`) e a única que mexe em outros nós: os de `frozen` ficam parados
## (`process_mode` desligado) enquanto a tela está aberta e voltam ao valor anterior ao fechar. NÃO tem regra de jogo, não calcula total nem distância: só consultas e `request_trade`, e a recusa é o `text_key` da resposta. O tempo
## do mundo continua andando (a tela não pausa nada). Nasce FECHADA; `setup` só uma vez.

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
	return true


func is_open() -> bool:
	return visible


## Abre a tela sobre o mercado `market_id`: para os nós de `frozen` (guarda o `process_mode` de cada um), mostra, limpa a linha de resultado, refaz as consultas e dá o foco à tabela, com a primeira linha escolhida se nenhuma estava.
## Já aberta, só troca de mercado e refaz as consultas. Sem `setup`: nada acontece.
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
	_layout.hints.text = _texts.get_text(KEY_HINTS, {"cancel_key": _key_of(ACTION_CANCEL), "interact_key": _key_of(InputActions.INTERACT)})
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
## Comprar e Vender só ficam ativos com a tela válida e o relógio andando.
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


## Tecla da ação para a linha de dicas, lida do InputMap (primeira palavra do texto do evento, ex.: "E"), como a `InteractionView` faz com `interact`.
static func _key_of(action: StringName) -> String:
	var events: Array[InputEvent] = InputMap.action_get_events(action)
	return events[0].as_text().get_slice(" ", 0) if not events.is_empty() else "?"
