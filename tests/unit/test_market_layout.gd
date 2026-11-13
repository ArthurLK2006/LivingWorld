extends GutTest
## LW-106d1: o MarketLayout cria os nós por campos nomeados, sem texto e sem estilo; o MarketTheme define todo o estilo (contrato em docs/modules/presentation.md, "Interface de mercado").

const MARKET_DIR: String = "res://src/presentation/ui/market"

var _root: Control
var _layout: MarketLayout


func before_each() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child_autofree(_root)
	_layout = MarketLayout.new()
	_layout.build(_root)


## Cada campo nomeado com a classe esperada.
func _fields() -> Dictionary:
	return {_layout.panel: PanelContainer, _layout.title: Label, _layout.funds: Label, _layout.weight: Label, _layout.goods: Tree, _layout.quantity: SpinBox,
		_layout.buy_button: Button, _layout.sell_button: Button, _layout.close_button: Button, _layout.result: Label, _layout.hints: Label}


## Os controles criados pelo layout, descendo só pelos filhos públicos (o SpinBox e a Tree têm nós internos que não são do layout).
func _controls(from: Node) -> Array[Control]:
	var found: Array[Control] = []
	for child: Node in from.get_children():
		found.append_array(_controls(child))
		if child is Control:
			found.append(child as Control)
	return found


func test_build_creates_every_named_field_with_its_type_under_the_parent() -> void:
	var fields: Dictionary = _fields()
	var names: Dictionary = {}
	for node: Node in fields:
		assert_is(node, fields[node], "Campo com o tipo esperado.")
		assert_true(_root.is_ancestor_of(node), "O nó '%s' fica sob o parent." % node.name)
		names[node.name] = true
	assert_eq(names.size(), fields.size(), "Os nomes são únicos.")
	var goods: Tree = _layout.goods
	assert_eq([MarketLayout.COLUMN_NAME, MarketLayout.COLUMN_ASK, MarketLayout.COLUMN_BID, MarketLayout.COLUMN_STOCK, MarketLayout.COLUMN_OWNED, MarketLayout.COLUMN_COUNT], [0, 1, 2, 3, 4, 5])
	assert_eq(goods.columns, 5, "A tabela tem 5 colunas.")
	assert_eq(goods.select_mode, Tree.SELECT_ROW, "A seleção é por linha.")
	assert_true(goods.column_titles_visible and goods.hide_root, "Cabeçalho visível e raiz escondida.")


func test_quantity_goes_from_1_to_99_and_starts_at_1() -> void:
	var quantity: SpinBox = _layout.quantity
	assert_eq([quantity.min_value, quantity.max_value, quantity.step, quantity.value], [1.0, 99.0, 1.0, 1.0], "Mínimo, máximo, passo e valor inicial.")


func test_the_layout_writes_no_text_and_sets_no_theme_only_role_variations() -> void:
	assert_null(_root.theme, "O parent não recebe tema.")
	assert_gte(_controls(_root).size(), _fields().size(), "A varredura enxerga ao menos os campos nomeados.")
	for control: Control in _controls(_root):
		assert_true(String(control.name).begins_with("Market"), "O nome '%s' é fixo e legível." % control.name)
		assert_null(control.theme, "O nó '%s' não tem tema próprio." % control.name)
		assert_true(control.theme_type_variation.is_empty() or MarketTheme.VARIATIONS.has(control.theme_type_variation), "'%s' só usa variações do MarketTheme." % control.name)
		assert_true(control.get("text") in [null, ""], "O nó '%s' nasce sem texto (ou nem tem a propriedade)." % control.name)
	for column: int in MarketLayout.COLUMN_COUNT:
		assert_eq(_layout.goods.get_column_title(column), "", "A coluna %d nasce sem título." % column)
	var roles: Dictionary = {_layout.title: MarketTheme.TITLE, _layout.funds: MarketTheme.STATUS, _layout.weight: MarketTheme.STATUS, _layout.result: MarketTheme.RESULT, _layout.hints: MarketTheme.HINT}
	for label: Label in roles:
		assert_eq(label.theme_type_variation, roles[label], "O papel de '%s'." % label.name)


func test_tab_goes_through_table_quantity_buy_sell_and_close_and_the_panel_is_centered() -> void:
	var current: Control = _layout.goods
	for next: Control in [_layout.quantity.get_line_edit(), _layout.buy_button, _layout.sell_button, _layout.close_button, _layout.goods]:
		current = current.find_next_valid_focus()
		assert_eq(current, next, "Tab segue a ordem lógica.")
	await wait_process_frames(2)
	assert_almost_eq(_layout.panel.get_global_rect().get_center(), _root.get_global_rect().get_center(), Vector2(1.0, 1.0))
	assert_true(_layout.panel.size.x >= MarketLayout.PANEL_MIN_SIZE.x and _layout.panel.size.y >= MarketLayout.PANEL_MIN_SIZE.y, "O painel respeita o tamanho mínimo.")


func test_build_with_a_null_root_reports_an_error_and_creates_nothing() -> void:
	var empty: MarketLayout = MarketLayout.new()
	empty.build(null)
	assert_push_error("raiz nula")
	assert_null(empty.panel)


func test_the_theme_defines_fonts_styleboxes_and_every_exposed_variation() -> void:
	var theme: Theme = MarketTheme.build()
	for type_name: StringName in [&"Label", &"Button", &"Tree"]:
		assert_true(theme.has_font_size(&"font_size", type_name), "%s tem tamanho de fonte." % type_name)
	var styleboxes: Dictionary = {&"Label": [&"normal"], &"PanelContainer": [&"panel"], &"Tree": [&"panel", &"focus", &"selected", &"title_button_normal"],
		&"Button": [&"normal", &"hover", &"pressed", &"disabled", &"focus"]}
	for type_name: StringName in styleboxes:
		for item: StringName in styleboxes[type_name]:
			assert_true(theme.has_stylebox(item, type_name), "%s tem a StyleBox '%s'." % [type_name, item])
	for value: Variant in (load(MARKET_DIR.path_join("market_theme.gd")) as GDScript).get_script_constant_map().values():
		assert_true(typeof(value) != TYPE_STRING_NAME or MarketTheme.VARIATIONS.has(value), "Toda constante de variação está em VARIATIONS.")
	for role: StringName in MarketTheme.VARIATIONS:
		assert_eq(theme.get_type_variation_base(role), &"Label", "'%s' é variação de Label." % role)
		assert_true(theme.has_font_size(&"font_size", role) and theme.has_color(&"font_color", role), "'%s' define fonte e cor." % role)
	_root.theme = theme
	assert_eq(_layout.title.get_theme_font_size(&"font_size"), MarketTheme.FONT_SIZE_TITLE, "Aplicado ao parent, o título pega a variação TITLE.")
	_root.theme = null
	_layout.panel.theme = theme
	assert_eq(_layout.hints.get_theme_font_size(&"font_size"), MarketTheme.FONT_SIZE_SMALL, "Aplicado ao painel do layout, a dica pega a variação HINT.")
	await wait_process_frames(2)


func test_no_gd_file_in_the_market_folder_styles_a_node_by_hand() -> void:
	var comment_lines: RegEx = RegEx.create_from_string("(?m)^\\s*#.*$")
	var scanned: Array[String] = []
	for file_name: String in DirAccess.get_files_at(MARKET_DIR):
		if file_name.ends_with(".gd"):
			scanned.append(file_name)
			var code: String = comment_lines.sub(FileAccess.get_file_as_string(MARKET_DIR.path_join(file_name)), "", true)
			assert_false(code.contains("add_theme_"), "%s define estilo por nó; o estilo é só do MarketTheme." % file_name)
	assert_true(scanned.has("market_theme.gd") and scanned.has("market_layout.gd"), "A varredura enxerga o tema e o layout.")
