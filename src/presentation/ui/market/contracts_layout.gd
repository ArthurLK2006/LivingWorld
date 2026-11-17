class_name ContractsLayout
extends RefCounted
## A CRIAÇÃO dos nós da aba "Contratos" da tela de mercado, em código (LW-107e1; contrato em docs/modules/presentation.md, "Quadro de contratos (LW-107)"): sob o `Control` que a `MarketView` entrega (a coluna do painel do
## mercado, onde a página é IRMÃ da do mercado), monta a página (`VBoxContainer`, ESCONDIDA ao nascer) com o título, a linha da capacidade (LW-107f4a: quem a escreve e a mostra é a página), as listas `Tree` "Disponíveis neste mercado" e "Meus contratos", o detalhe da linha escolhida, os botões
## Aceitar, Entregar, Abandonar (LW-107f4a, desativado ao nascer e separado do Entregar pelo espaçador `ContractsActionGap`) e Fechar, a linha de resultado e a de dicas (esta nasce vazia: quem a preenche é a LW-107e2), e os entrega por CAMPOS nomeados e tipados. NÃO escreve texto (a tela escreve, por chave), NÃO lê a ponte, NÃO tem regra de jogo e NÃO define estilo: só aponta o papel
## de cada nó por `theme_type_variation`, com os nomes do `MarketTheme` (o único lugar do estilo); o `Theme` vem do `Control` raiz da tela. A ÚNICA exceção é o matiz local de perigo do botão Abandonar (`DANGER_TINT`, aplicado por `mark_as_danger` em `self_modulate`, que não é item de tema: nota de projeto de
## docs/modules/presentation.md, "Encomendas por objetivo"). Quem liga e desliga os botões é a tela. A ordem de Tab é a ordem de criação.

## Colunas das listas, sem títulos (cada texto já traz a sua palavra): o bem e a quantidade, a recompensa e o prazo (ou o estado, quando não há prazo a mostrar).
const COLUMN_LINE: int = 0
const COLUMN_REWARD: int = 1
const COLUMN_WHEN: int = 2
const COLUMN_COUNT: int = 3
## Valores [HIP]: altura mínima de cada lista (cabem umas 4 linhas) e proporção das colunas (a do bem é mais larga).
const LIST_MIN_HEIGHT: float = 96.0
const LINE_COLUMN_RATIO: int = 3
const OTHER_COLUMN_RATIO: int = 2
## Valores [HIP] do botão Abandonar (LW-107f4a): o matiz que multiplica a cor do botão (avermelhado, só para distingui-lo; o contraste do texto é conferido por teste) e a largura do espaçador que o afasta do Entregar (próximo, mas não colado).
const DANGER_TINT: Color = Color(1.0, 0.60, 0.60)
const ACTION_GAP_PX: float = 24.0

var page: VBoxContainer
var title: Label
var capacity: Label
var open_title: Label
var open_list: Tree
var mine_title: Label
var mine_list: Tree
var detail: Label
var accept_button: Button
var deliver_button: Button
var action_gap: Control
var abandon_button: Button
var close_button: Button
var result: Label
var hints: Label


## Cria todos os nós sob `parent` e preenche os campos. Chamar uma vez por tela. Raiz nula: push_error e nada é criado.
func build(parent: Control) -> void:
	if parent == null:
		push_error("ContractsLayout.build: raiz nula; esperado o Control onde a página se pendura.")
		return
	page = _add(parent, VBoxContainer.new(), "ContractsPage") as VBoxContainer
	page.visible = false
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	title = _label(page, "ContractsTitle", MarketTheme.TITLE)
	capacity = _label(page, "ContractsCapacity", MarketTheme.STATUS)
	open_title = _label(page, "ContractsOpenTitle", MarketTheme.STATUS)
	open_list = _list(page, "ContractsOpen")
	mine_title = _label(page, "ContractsMineTitle", MarketTheme.STATUS)
	mine_list = _list(page, "ContractsMine")
	detail = _label(page, "ContractsDetail", MarketTheme.STATUS)
	var action_row: Node = _add(page, HBoxContainer.new(), "ContractsActionRow")
	accept_button = _button(action_row, "ContractsAccept")
	deliver_button = _button(action_row, "ContractsDeliver")
	action_gap = _add(action_row, Control.new(), "ContractsActionGap") as Control
	action_gap.custom_minimum_size.x = ACTION_GAP_PX
	abandon_button = _button(action_row, "ContractsAbandon")
	abandon_button.disabled = true
	mark_as_danger(abandon_button)
	close_button = _button(action_row, "ContractsClose")
	result = _label(page, "ContractsResult", MarketTheme.RESULT)
	hints = _label(page, "ContractsHints", MarketTheme.HINT)


## O matiz local de perigo (`DANGER_TINT`) no botão: só o `self_modulate` muda, nenhum item de tema (o estilo continua só do `MarketTheme`). Pública e estática para o "Abandonar" do painel de confirmação (LW-107f4b) usar o mesmo matiz.
static func mark_as_danger(button: Button) -> void:
	button.self_modulate = DANGER_TINT


## Dá o nome fixo ao nó, pendura-o no pai e o devolve.
static func _add(parent: Node, node: Node, node_name: String) -> Node:
	node.name = node_name
	parent.add_child(node)
	return node


static func _label(parent: Node, node_name: String, role: StringName) -> Label:
	var label: Label = _add(parent, Label.new(), node_name) as Label
	label.theme_type_variation = role
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


static func _button(parent: Node, node_name: String) -> Button:
	var button: Button = _add(parent, Button.new(), node_name) as Button
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return button


static func _list(parent: Node, node_name: String) -> Tree:
	var tree: Tree = _add(parent, Tree.new(), node_name) as Tree
	tree.columns = COLUMN_COUNT
	tree.hide_root = true
	tree.select_mode = Tree.SELECT_ROW
	tree.column_titles_visible = false
	tree.custom_minimum_size.y = LIST_MIN_HEIGHT
	tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for index: int in COLUMN_COUNT:
		tree.set_column_expand_ratio(index, LINE_COLUMN_RATIO if index == COLUMN_LINE else OTHER_COLUMN_RATIO)
	return tree
