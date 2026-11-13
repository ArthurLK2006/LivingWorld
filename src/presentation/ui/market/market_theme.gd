class_name MarketTheme
extends RefCounted
## TODO o estilo da tela de mercado, em UM lugar (LW-106d1; contrato em docs/modules/presentation.md, "Interface de mercado"): `build()` devolve um `Theme` provisório e NEUTRO (cinza escuro
## translúcido, texto claro). Nenhum outro componente da tela define cor, fonte, margem ou StyleBox: o `MarketLayout` só aponta o papel de cada nó pelas variações de tipo abaixo e a `MarketView` põe
## o `Theme` no `Control` raiz. A identidade artística definitiva troca ESTE arquivo (ou o `Theme` inteiro) sem tocar o layout nem a lógica.

## Variações de tipo de `Label`: o PAPEL do nó, usado pelo layout em `theme_type_variation`. `VARIATIONS` lista todas (o `build` e os testes a percorrem).
const TITLE: StringName = &"MarketTitle"
const STATUS: StringName = &"MarketStatus"
const RESULT: StringName = &"MarketResult"
const HINT: StringName = &"MarketHint"
const VARIATIONS: Array[StringName] = [TITLE, STATUS, RESULT, HINT]

## Cores [HIP] (valores visuais de trabalho, não requisitos): painel escuro translúcido, tabela mais escura, cinzas neutros e um único destaque azul-acinzentado (foco e seleção).
const COLOR_PANEL: Color = Color(0.09, 0.10, 0.12, 0.94)
const COLOR_TABLE: Color = Color(0.05, 0.06, 0.07, 0.90)
const COLOR_HEADER: Color = Color(0.17, 0.18, 0.21)
const COLOR_BUTTON: Color = Color(0.20, 0.22, 0.26)
const COLOR_BUTTON_HOVER: Color = Color(0.27, 0.29, 0.34)
const COLOR_BUTTON_PRESSED: Color = Color(0.13, 0.14, 0.17)
const COLOR_BUTTON_DISABLED: Color = Color(0.14, 0.15, 0.17, 0.60)
const COLOR_BORDER: Color = Color(0.30, 0.32, 0.36)
const COLOR_ACCENT: Color = Color(0.40, 0.58, 0.82)
const COLOR_SELECTION: Color = Color(0.22, 0.33, 0.48)
const COLOR_TEXT: Color = Color(0.90, 0.91, 0.93)
const COLOR_TITLE: Color = Color(0.98, 0.98, 0.99)
const COLOR_RESULT: Color = Color(0.78, 0.87, 0.97)
const COLOR_MUTED: Color = Color(0.62, 0.64, 0.68)
const COLOR_DISABLED: Color = Color(0.48, 0.50, 0.54)

## Tamanhos [HIP], em pixels: fontes, margem do painel, separação entre filhos, bordas, cantos, respiro interno dos botões e das células da tabela e separação entre as linhas.
const FONT_SIZE_TITLE: int = 24
const FONT_SIZE_BODY: int = 16
const FONT_SIZE_SMALL: int = 13
const MARGIN_PX: int = 16
const SEPARATION_PX: int = 8
const BORDER_PX: int = 1
const FOCUS_BORDER_PX: int = 2
const CORNER_RADIUS_PX: int = 4
const BUTTON_PADDING_PX: int = 8
const CELL_PADDING_PX: int = 3
const ROW_SEPARATION_PX: int = 1


static func build() -> Theme:
	var theme: Theme = Theme.new()
	theme.default_font_size = FONT_SIZE_BODY
	theme.set_stylebox(&"panel", &"PanelContainer", _box(COLOR_PANEL, COLOR_BORDER, 0))
	for side: String in ["left", "top", "right", "bottom"]:
		theme.set_constant("margin_" + side, &"MarginContainer", MARGIN_PX)
		theme.set_constant("inner_item_margin_" + side, &"Tree", CELL_PADDING_PX)
	for box_type: StringName in [&"VBoxContainer", &"HBoxContainer"]:
		theme.set_constant(&"separation", box_type, SEPARATION_PX)
	theme.set_constant(&"v_separation", &"Tree", ROW_SEPARATION_PX)
	theme.set_font_size(&"font_size", &"Label", FONT_SIZE_BODY)
	theme.set_color(&"font_color", &"Label", COLOR_TEXT)
	theme.set_stylebox(&"normal", &"Label", StyleBoxEmpty.new())
	_label_role(theme, TITLE, FONT_SIZE_TITLE, COLOR_TITLE)
	_label_role(theme, STATUS, FONT_SIZE_BODY, COLOR_TEXT)
	_label_role(theme, RESULT, FONT_SIZE_BODY, COLOR_RESULT)
	_label_role(theme, HINT, FONT_SIZE_SMALL, COLOR_MUTED)
	_style_buttons(theme)
	_style_table(theme)
	_style_field(theme)
	return theme


static func _box(fill: Color, border: Color, padding: int, border_px: int = BORDER_PX) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(border_px)
	box.set_corner_radius_all(CORNER_RADIUS_PX)
	box.set_content_margin_all(padding)
	return box


static func _label_role(theme: Theme, role: StringName, font_size: int, color: Color) -> void:
	theme.set_type_variation(role, &"Label")
	theme.set_font_size(&"font_size", role, font_size)
	theme.set_color(&"font_color", role, color)


static func _style_buttons(theme: Theme) -> void:
	theme.set_font_size(&"font_size", &"Button", FONT_SIZE_BODY)
	theme.set_color(&"font_color", &"Button", COLOR_TEXT)
	theme.set_color(&"font_disabled_color", &"Button", COLOR_DISABLED)
	theme.set_stylebox(&"normal", &"Button", _box(COLOR_BUTTON, COLOR_BORDER, BUTTON_PADDING_PX))
	theme.set_stylebox(&"hover", &"Button", _box(COLOR_BUTTON_HOVER, COLOR_BORDER, BUTTON_PADDING_PX))
	theme.set_stylebox(&"pressed", &"Button", _box(COLOR_BUTTON_PRESSED, COLOR_BORDER, BUTTON_PADDING_PX))
	theme.set_stylebox(&"disabled", &"Button", _box(COLOR_BUTTON_DISABLED, COLOR_BORDER, BUTTON_PADDING_PX))
	theme.set_stylebox(&"focus", &"Button", _box(Color.TRANSPARENT, COLOR_ACCENT, BUTTON_PADDING_PX, FOCUS_BORDER_PX))


static func _style_table(theme: Theme) -> void:
	theme.set_font_size(&"font_size", &"Tree", FONT_SIZE_BODY)
	theme.set_font_size(&"title_button_font_size", &"Tree", FONT_SIZE_BODY)
	theme.set_color(&"font_color", &"Tree", COLOR_TEXT)
	theme.set_color(&"font_selected_color", &"Tree", COLOR_TITLE)
	theme.set_color(&"title_button_color", &"Tree", COLOR_TITLE)
	theme.set_stylebox(&"panel", &"Tree", _box(COLOR_TABLE, COLOR_BORDER, BORDER_PX))
	theme.set_stylebox(&"focus", &"Tree", _box(Color.TRANSPARENT, COLOR_ACCENT, BORDER_PX, FOCUS_BORDER_PX))
	theme.set_stylebox(&"cursor", &"Tree", _box(Color.TRANSPARENT, COLOR_ACCENT, 0, FOCUS_BORDER_PX))
	theme.set_stylebox(&"cursor_unfocused", &"Tree", _box(Color.TRANSPARENT, COLOR_BORDER, 0, FOCUS_BORDER_PX))
	for selected: StringName in [&"selected", &"selected_focus"]:
		theme.set_stylebox(selected, &"Tree", _box(COLOR_SELECTION, COLOR_SELECTION, 0))
	for header: StringName in [&"title_button_normal", &"title_button_hover", &"title_button_pressed"]:
		theme.set_stylebox(header, &"Tree", _box(COLOR_HEADER, COLOR_BORDER, CELL_PADDING_PX))


## O campo de texto do `SpinBox` da quantidade é um `LineEdit`: sem isto ele ficaria com o visual de fábrica do Godot.
static func _style_field(theme: Theme) -> void:
	theme.set_color(&"font_color", &"LineEdit", COLOR_TEXT)
	theme.set_color(&"caret_color", &"LineEdit", COLOR_TITLE)
	theme.set_color(&"selection_color", &"LineEdit", COLOR_SELECTION)
	theme.set_stylebox(&"normal", &"LineEdit", _box(COLOR_TABLE, COLOR_BORDER, CELL_PADDING_PX))
	theme.set_stylebox(&"focus", &"LineEdit", _box(COLOR_TABLE, COLOR_ACCENT, CELL_PADDING_PX, FOCUS_BORDER_PX))
