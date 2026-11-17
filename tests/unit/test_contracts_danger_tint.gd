extends GutTest
## LW-107f4a, item (b): o botão "Abandonar" do `ContractsLayout` e o matiz LOCAL de perigo dele (docs/modules/presentation.md, "Encomendas por objetivo: abandonar, confirmar e capacidade"; o `MarketTheme` NÃO muda e o layout não usa `add_theme_*`: o `self_modulate` não é item de tema).
## O CONTRASTE: a razão de luminância relativa (a conta do WCAG 2.x, ≥ 4,5:1 [HIP]) do texto contra o fundo do botão em `normal`, `hover` e `pressed` (o `disabled`, inativo, não conta), calculada sobre `MarketTheme.COLOR_TEXT` e `COLOR_BUTTON*` MULTIPLICADAS por
## `DANGER_TINT` (o `self_modulate` multiplica tudo que o botão desenha: o texto e o fundo), e a mesma conta nos botões comuns como REFERÊNCIA (o piso de 4,5:1 é o que o tema já cumpre; o matiz só escurece, então o do botão de perigo é MENOR que o do comum, e o teste
## cobra o piso, não a igualdade). Depois, o botão no layout real: o nome, o lugar entre Entregar e Fechar (a ordem de Tab é a de criação), o espaçador fixo, o nascimento desativado, o matiz só nele, e `mark_as_danger` mexendo só no `self_modulate`. Sem janela.

const MIN_RATIO: float = 4.5
## O limiar da conta do WCAG 2.x e o desvio das duas luminâncias (a luz refletida pelo ambiente).
const LINEAR_THRESHOLD: float = 0.03928
const FLARE: float = 0.05
## O fundo do botão em cada estado em que o texto tem de ser lido (o desativado não conta).
const FILLS: Dictionary[String, Color] = {"normal": MarketTheme.COLOR_BUTTON, "hover": MarketTheme.COLOR_BUTTON_HOVER, "pressed": MarketTheme.COLOR_BUTTON_PRESSED}
const ROW_ORDER: Array[String] = ["ContractsAccept", "ContractsDeliver", "ContractsActionGap", "ContractsAbandon", "ContractsClose"]

var _layout: ContractsLayout


func before_each() -> void:
	var root: Control = Control.new()
	add_child_autofree(root)
	_layout = ContractsLayout.new()
	_layout.build(root)


func _channel(value: float) -> float:
	return value / 12.92 if value <= LINEAR_THRESHOLD else pow((value + 0.055) / 1.055, 2.4)


func _luminance(color: Color) -> float:
	return 0.2126 * _channel(color.r) + 0.7152 * _channel(color.g) + 0.0722 * _channel(color.b)


func _ratio(text: Color, fill: Color) -> float:
	return (maxf(_luminance(text), _luminance(fill)) + FLARE) / (minf(_luminance(text), _luminance(fill)) + FLARE)


func test_the_contrast_formula_gives_the_known_extremes_of_the_wcag() -> void:
	assert_almost_eq(_ratio(Color.WHITE, Color.BLACK), 21.0, 0.001, "Branco sobre preto é 21:1.")
	assert_almost_eq(_ratio(Color.GRAY, Color.GRAY), 1.0, 0.001, "A mesma cor é 1:1.")
	assert_lt(_ratio(Color(0.6, 0.6, 0.6), Color.WHITE), MIN_RATIO, "Cinza médio sobre branco (2,8:1) está abaixo do piso: a conta separa o que passa do que não passa.")


func test_the_danger_tint_keeps_the_button_text_at_4_5_to_1_or_more_in_normal_hover_and_pressed_like_the_common_buttons() -> void:
	for state: String in FILLS:
		var fill: Color = FILLS[state]
		assert_gte(_ratio(MarketTheme.COLOR_TEXT, fill), MIN_RATIO, "Referência: o botão comum em '%s'." % state)
		assert_gte(_ratio(MarketTheme.COLOR_TEXT * ContractsLayout.DANGER_TINT, fill * ContractsLayout.DANGER_TINT), MIN_RATIO, "O botão de perigo em '%s'." % state)


func test_the_tint_is_a_reddish_color_that_changes_the_button_and_mark_as_danger_only_sets_the_self_modulate() -> void:
	var tint: Color = ContractsLayout.DANGER_TINT
	assert_true(tint != Color.WHITE and tint.r > tint.g and tint.r > tint.b and tint.a == 1.0, "Um matiz avermelhado e opaco, diferente de branco: o botão se distingue do comum.")
	var button: Button = Button.new()
	add_child_autofree(button)
	var before: Array = [button.theme, button.theme_type_variation, button.modulate, button.disabled, button.text, button.self_modulate]
	ContractsLayout.mark_as_danger(button)
	assert_eq([button.theme, button.theme_type_variation, button.modulate, button.disabled, button.text, button.self_modulate], [before[0], before[1], before[2], before[3], before[4], tint], "Só o `self_modulate` muda.")


func test_the_abandon_button_sits_between_deliver_and_close_after_a_fixed_gap_born_disabled_and_the_only_tinted_one() -> void:
	var row: Node = _layout.abandon_button.get_parent()
	var names: Array[String] = []
	for child: Node in row.get_children():
		names.append(String(child.name))
	assert_eq([row.name, names], [&"ContractsActionRow", ROW_ORDER], "O botão fica na linha de ações, depois de Entregar (e do espaçador) e antes de Fechar.")
	assert_eq([_layout.abandon_button.disabled, _layout.abandon_button.text], [true, ""], "Desativado e sem texto ao nascer (quem escreve é a página).")
	assert_eq([_layout.action_gap.get_class(), _layout.action_gap.custom_minimum_size.x, _layout.action_gap.focus_mode], ["Control", ContractsLayout.ACTION_GAP_PX, Control.FOCUS_NONE], "O espaçador é um `Control` simples, de largura fixa e fora da ordem de Tab.")
	assert_gt(ContractsLayout.ACTION_GAP_PX, 0.0)
	assert_eq([_layout.abandon_button.self_modulate, _layout.accept_button.self_modulate, _layout.deliver_button.self_modulate, _layout.close_button.self_modulate], [ContractsLayout.DANGER_TINT, Color.WHITE, Color.WHITE, Color.WHITE], "Só o Abandonar tem o matiz.")
	assert_null(_layout.abandon_button.theme, "O botão não tem tema próprio: o estilo continua só do `MarketTheme`.")
