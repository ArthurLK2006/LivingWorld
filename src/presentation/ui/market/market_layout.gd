class_name MarketLayout
extends RefCounted
## A CRIAÇÃO dos nós da tela de mercado, em código (LW-106d1; contrato em docs/modules/presentation.md, "Interface de mercado"): sob o `Control` raiz que a `MarketView` entrega, monta um painel
## centralizado (`PanelContainer` > `MarginContainer` > `VBoxContainer`) com o título, o dinheiro, o peso, a tabela dos bens (`Tree`), a quantidade (`SpinBox`), os botões Comprar, Vender e Fechar, a linha de
## resultado e a de dicas, e os entrega por CAMPOS nomeados e tipados. NÃO escreve texto (rótulos, botões e títulos de coluna ficam vazios: quem escreve é a tela), NÃO lê a ponte, NÃO tem regra de jogo e NÃO
## define estilo: só aponta o papel de cada nó por `theme_type_variation`, com os nomes do `MarketTheme`; o `Theme` é posto pela `MarketView` no `Control` raiz. A ordem de Tab é a ordem de criação:
## tabela, quantidade, Comprar, Vender, Fechar (a tabela receber o foco ao abrir é decisão da tela).

## Colunas da tabela dos bens (a tela escreve os títulos e preenche as linhas).
const COLUMN_NAME: int = 0
const COLUMN_ASK: int = 1
const COLUMN_BID: int = 2
const COLUMN_STOCK: int = 3
const COLUMN_OWNED: int = 4
const COLUMN_COUNT: int = 5

## Valores [HIP]: tamanho mínimo do painel, intervalo da quantidade e proporção das colunas (o nome do bem é mais largo que os números).
const PANEL_MIN_SIZE: Vector2 = Vector2(640.0, 580.0)
const QUANTITY_MIN: int = 1
const QUANTITY_MAX: int = 99
const QUANTITY_STEP: int = 1
const QUANTITY_DEFAULT: int = 1
const NAME_COLUMN_RATIO: int = 3
const NUMBER_COLUMN_RATIO: int = 1

var panel: PanelContainer
var title: Label
var funds: Label
var weight: Label
var goods: Tree
var quantity: SpinBox
var buy_button: Button
var sell_button: Button
var close_button: Button
var result: Label
var hints: Label


## Cria todos os nós sob `parent` e preenche os campos. Chamar uma vez por tela. Raiz nula: push_error e nada é criado.
func build(parent: Control) -> void:
	if parent == null:
		push_error("MarketLayout.build: raiz nula; esperado o Control raiz da tela.")
		return
	panel = _add(parent, PanelContainer.new(), "MarketPanel") as PanelContainer
	panel.custom_minimum_size = PANEL_MIN_SIZE
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	var margin: Node = _add(panel, MarginContainer.new(), "MarketMargin")
	var column: Node = _add(margin, VBoxContainer.new(), "MarketColumn")
	title = _label(column, "MarketTitle", MarketTheme.TITLE)
	var status_row: Node = _add(column, HBoxContainer.new(), "MarketStatusRow")
	funds = _label(status_row, "MarketFunds", MarketTheme.STATUS)
	weight = _label(status_row, "MarketWeight", MarketTheme.STATUS)
	weight.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	goods = _add(column, Tree.new(), "MarketGoods") as Tree
	goods.columns = COLUMN_COUNT
	goods.hide_root = true
	goods.select_mode = Tree.SELECT_ROW
	goods.column_titles_visible = true
	goods.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for index: int in COLUMN_COUNT:
		goods.set_column_expand_ratio(index, NAME_COLUMN_RATIO if index == COLUMN_NAME else NUMBER_COLUMN_RATIO)
	var action_row: Node = _add(column, HBoxContainer.new(), "MarketActionRow")
	quantity = _add(action_row, SpinBox.new(), "MarketQuantity") as SpinBox
	quantity.min_value = QUANTITY_MIN
	quantity.max_value = QUANTITY_MAX
	quantity.step = QUANTITY_STEP
	quantity.value = QUANTITY_DEFAULT
	buy_button = _button(action_row, "MarketBuy")
	sell_button = _button(action_row, "MarketSell")
	close_button = _button(action_row, "MarketClose")
	result = _label(column, "MarketResult", MarketTheme.RESULT)
	hints = _label(column, "MarketHints", MarketTheme.HINT)
	for line: Label in [result, hints]:
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


## Dá o nome fixo ao nó, pendura-o no pai e o devolve.
static func _add(parent: Node, node: Node, node_name: String) -> Node:
	node.name = node_name
	parent.add_child(node)
	return node


static func _label(parent: Node, node_name: String, role: StringName) -> Label:
	var label: Label = _add(parent, Label.new(), node_name) as Label
	label.theme_type_variation = role
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label


static func _button(parent: Node, node_name: String) -> Button:
	var button: Button = _add(parent, Button.new(), node_name) as Button
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return button
