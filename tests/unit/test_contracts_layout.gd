extends GutTest
## LW-107e1: o ContractsLayout cria os nós da aba "Contratos" por campos nomeados, sem texto e sem estilo (o MarketTheme é o único lugar do estilo), e o MarketLayout ganha SÓ o cabeçalho de abas, sem mudar o pai de nenhum nó da página
## do mercado (contrato em docs/modules/presentation.md, "Quadro de contratos (LW-107)"). Sem janela.

var _root: Control
var _market: MarketLayout
var _layout: ContractsLayout


## O layout do mercado sob a raiz e o de contratos pendurado na coluna dele, como a `MarketView` os monta.
func before_each() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child_autofree(_root)
	_market = MarketLayout.new()
	_market.build(_root)
	_layout = ContractsLayout.new()
	_layout.build(_market.column)


## Cada campo nomeado com a classe esperada.
func _fields() -> Dictionary:
	return {_layout.page: VBoxContainer, _layout.title: Label, _layout.open_title: Label, _layout.open_list: Tree, _layout.mine_title: Label, _layout.mine_list: Tree, _layout.detail: Label,
		_layout.accept_button: Button, _layout.deliver_button: Button, _layout.close_button: Button, _layout.result: Label, _layout.hints: Label}


## Os controles da página de contratos, descendo só pelos filhos públicos (a Tree tem nós internos que não são do layout).
func _controls(from: Node) -> Array[Control]:
	var found: Array[Control] = []
	for child: Node in from.get_children():
		found.append_array(_controls(child))
		if child is Control:
			found.append(child as Control)
	return found


func test_build_creates_every_named_field_with_its_type_as_the_last_hidden_child_of_the_market_column() -> void:
	var fields: Dictionary = _fields()
	var names: Dictionary = {}
	for node: Node in fields:
		assert_is(node, fields[node], "Campo com o tipo esperado.")
		assert_true(_layout.page == node or _layout.page.is_ancestor_of(node), "O nó '%s' fica na página." % node.name)
		assert_true(String(node.name).begins_with("Contracts"), "O nome '%s' é fixo e legível." % node.name)
		names[node.name] = true
	assert_eq(names.size(), fields.size(), "Os nomes são únicos.")
	assert_eq([_layout.page.get_parent(), _layout.page.get_index(), _layout.page.visible], [_market.column, _market.column.get_child_count() - 1, false], "Irmã da página do mercado, depois dela, e escondida ao nascer.")
	for list: Tree in [_layout.open_list, _layout.mine_list]:
		assert_eq([list.columns, list.select_mode, list.hide_root, list.column_titles_visible], [ContractsLayout.COLUMN_COUNT, Tree.SELECT_ROW, true, false], "Lista de três colunas, sem títulos, uma linha por escolha.")
	assert_eq([ContractsLayout.COLUMN_LINE, ContractsLayout.COLUMN_REWARD, ContractsLayout.COLUMN_WHEN, ContractsLayout.COLUMN_COUNT], [0, 1, 2, 3])


func test_the_layout_writes_no_text_and_sets_no_theme_only_role_variations() -> void:
	assert_null(_root.theme, "A raiz não recebe tema.")
	assert_gte(_controls(_layout.page).size(), _fields().size() - 1, "A varredura enxerga ao menos os campos nomeados (menos a própria página).")
	for control: Control in _controls(_layout.page):
		assert_null(control.theme, "O nó '%s' não tem tema próprio." % control.name)
		assert_true(control.theme_type_variation.is_empty() or MarketTheme.VARIATIONS.has(control.theme_type_variation), "'%s' só usa variações do MarketTheme." % control.name)
		assert_true(control.get("text") in [null, ""], "O nó '%s' nasce sem texto (ou nem tem a propriedade)." % control.name)
	var roles: Dictionary = {_layout.title: MarketTheme.TITLE, _layout.open_title: MarketTheme.STATUS, _layout.mine_title: MarketTheme.STATUS, _layout.detail: MarketTheme.STATUS, _layout.result: MarketTheme.RESULT, _layout.hints: MarketTheme.HINT}
	for label: Label in roles:
		assert_eq(label.theme_type_variation, roles[label], "O papel de '%s'." % label.name)


func test_the_market_layout_only_gains_the_tab_header_and_its_page_nodes_keep_their_parent_and_tab_cycle() -> void:
	var tabs: Node = _market.market_tab.get_parent()
	assert_eq([_market.column.get_child(0), _market.contracts_tab.get_parent(), _market.market_tab.toggle_mode, _market.contracts_tab.toggle_mode], [tabs, tabs, true, true], "O cabeçalho é o primeiro filho da coluna, com dois botões de alternância.")
	assert_eq([_market.market_tab.text, _market.contracts_tab.text], ["", ""], "Os botões nascem sem texto: quem escreve é a tela.")
	var column_children: Array[Node] = [tabs]
	column_children.append_array(_market.market_page)
	column_children.append(_layout.page)
	assert_eq(_market.column.get_children(), column_children, "A coluna tem o cabeçalho, a página do mercado (seis nós, nenhum mudou de pai) e a de contratos.")
	assert_eq(_market.market_page.size(), 6, "Título, estado, tabela, ações, resultado e dicas.")
	assert_eq([_market.close_button.find_next_valid_focus(), _market.goods.find_prev_valid_focus(), _market.contracts_tab.find_next_valid_focus()], [_market.goods, _market.contracts_tab, _market.goods], "O ciclo de Tab da página do mercado é o da LW-106; o cabeçalho se alcança com Shift+Tab.")


func test_with_the_market_page_hidden_tab_goes_through_the_header_the_two_lists_and_the_three_buttons_and_wraps() -> void:
	for node: Control in _market.market_page:
		node.visible = false
	_layout.page.visible = true
	var current: Control = _market.market_tab
	for next: Control in [_market.contracts_tab, _layout.open_list, _layout.mine_list, _layout.accept_button, _layout.deliver_button, _layout.close_button, _market.market_tab]:
		current = current.find_next_valid_focus()
		assert_eq(current, next, "Tab segue a ordem de criação, sem passar pelo que está escondido.")


func test_build_with_a_null_root_reports_an_error_and_creates_nothing() -> void:
	var empty: ContractsLayout = ContractsLayout.new()
	empty.build(null)
	assert_push_error("raiz nula")
	assert_null(empty.page)
