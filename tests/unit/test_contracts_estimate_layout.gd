extends GutTest
## LW-107h: o leiaute e o texto da estimativa da aba Contratos, sem janela e sem jogo. Os três rótulos novos (`ContractsEstimate`, `ContractsVerdict`, `ContractsEstimateHint`) são filhos da PÁGINA, entre o detalhe e a linha de ações, só com papéis do `MarketTheme` e sem texto nem `add_theme_*`, e a `MarketColumn` não ganha filho;
## o matiz de perigo vale também para o rótulo (`mark_as_danger` e `clear_danger`, só o `self_modulate`) e o texto avermelhado sobre o painel passa de 4,5:1 (a mesma conta de `test_contracts_danger_tint.gd`); sem jogo a página os deixa vazios e escondidos; as nove chaves `ui.contracts.*` existem, toda chave da página existe,
## nenhum texto promete lucro, ganho ou garantia e todo prejuízo e toda margem trazem a frase de que os preços podem mudar. A estimativa em si (números, avisos e matiz no jogo real) é de `tests/integration/test_contracts_estimate.gd`.

const MIN_RATIO: float = 4.5
## O limiar da conta do WCAG 2.x e o desvio das duas luminâncias.
const LINEAR_THRESHOLD: float = 0.03928
const FLARE: float = 0.05
const PAGE_ORDER: Array[String] = ["ContractsDetail", "ContractsEstimate", "ContractsVerdict", "ContractsEstimateHint", "ContractsActionRow"]
const NEW_KEYS: Array[String] = [
	"ui.contracts.estimate_cost", "ui.contracts.estimate_result", "ui.contracts.estimate_have", "ui.contracts.estimate_unknown", "ui.contracts.verdict_loss",
	"ui.contracts.verdict_margin", "ui.contracts.verdict_margin_small", "ui.contracts.verdict_funds", "ui.contracts.hint_estimate",
]
const FORBIDDEN_WORDS: Array[String] = ["lucro", "ganho", "garant"]
const PRICES_PHRASE: String = "preços podem mudar"

var _root: Control
var _market: MarketLayout
var _layout: ContractsLayout
var _texts: UiText


func before_each() -> void:
	_root = Control.new()
	add_child_autofree(_root)
	_market = MarketLayout.new()
	_market.build(_root)
	_layout = ContractsLayout.new()
	_layout.build(_market.column)
	var loaded: UiText.LoadResult = UiText.from_file(UiText.DEFAULT_PATH)
	assert_true(loaded.result.ok, loaded.result.message)
	_texts = loaded.texts


func _channel(value: float) -> float:
	return value / 12.92 if value <= LINEAR_THRESHOLD else pow((value + 0.055) / 1.055, 2.4)


func _luminance(color: Color) -> float:
	return 0.2126 * _channel(color.r) + 0.7152 * _channel(color.g) + 0.0722 * _channel(color.b)


func _ratio(text: Color, fill: Color) -> float:
	return (maxf(_luminance(text), _luminance(fill)) + FLARE) / (minf(_luminance(text), _luminance(fill)) + FLARE)


func test_the_three_labels_are_children_of_the_page_between_the_detail_and_the_actions_with_theme_roles_and_no_text() -> void:
	var names: Array[String] = []
	for child: Node in _layout.page.get_children():
		names.append(String(child.name))
	var from: int = names.find("ContractsDetail")
	assert_eq(names.slice(from, from + PAGE_ORDER.size()), PAGE_ORDER, "Entre o detalhe e a linha de ações, nesta ordem.")
	var roles: Dictionary = {_layout.estimate: MarketTheme.STATUS, _layout.verdict: MarketTheme.RESULT, _layout.estimate_hint: MarketTheme.HINT}
	for label: Label in roles:
		assert_eq([label.get_parent(), label.theme_type_variation, label.text], [_layout.page, roles[label], ""], "'%s' é filho da página, só com o papel do tema e sem texto." % label.name)
		assert_null(label.theme, "O rótulo não tem tema próprio: o estilo é só do `MarketTheme`.")
		assert_eq([label.has_theme_color_override(&"font_color"), label.has_theme_font_size_override(&"font_size"), label.has_theme_stylebox_override(&"normal"), label.self_modulate], [false, false, false, Color.WHITE], "Nenhum `add_theme_*` e nenhum matiz ao nascer.")
		assert_false(_market.column.get_children().has(label), "A coluna do painel não ganha filho.")


func test_the_danger_tint_works_on_a_label_changes_only_the_self_modulate_and_keeps_the_text_over_the_panel_at_4_5_to_1() -> void:
	var before: Array = [_layout.verdict.theme, _layout.verdict.theme_type_variation, _layout.verdict.modulate, _layout.verdict.text, _layout.verdict.visible]
	ContractsLayout.mark_as_danger(_layout.verdict)
	assert_eq([_layout.verdict.theme, _layout.verdict.theme_type_variation, _layout.verdict.modulate, _layout.verdict.text, _layout.verdict.visible, _layout.verdict.self_modulate], before + [ContractsLayout.DANGER_TINT], "Só o `self_modulate` muda.")
	ContractsLayout.clear_danger(_layout.verdict)
	assert_eq(_layout.verdict.self_modulate, Color.WHITE, "Sem perigo, a cor volta ao papel do tema.")
	assert_gte(_ratio(MarketTheme.COLOR_RESULT, MarketTheme.COLOR_PANEL), MIN_RATIO, "Referência: o aviso sem matiz sobre o painel.")
	assert_gte(_ratio(MarketTheme.COLOR_RESULT * ContractsLayout.DANGER_TINT, MarketTheme.COLOR_PANEL), MIN_RATIO, "O aviso de prejuízo, avermelhado, sobre o painel.")
	var button: Button = Button.new()
	add_child_autofree(button)
	ContractsLayout.mark_as_danger(button)
	assert_eq(button.self_modulate, ContractsLayout.DANGER_TINT, "O botão Abandonar segue usando o mesmo matiz pela mesma função.")


func test_without_a_game_the_page_leaves_the_three_labels_empty_and_hidden() -> void:
	var idle_host: SimulationHostNode = SimulationHostNode.new()
	var holder: Control = Control.new()
	add_child_autofree(holder)
	var page: ContractsPage = ContractsPage.new()
	page.setup(SimBridge.new(idle_host, null, [] as Array[Place]), _texts, 1, holder)
	var labels: Array[Label] = []
	for label_name: String in ["ContractsEstimate", "ContractsVerdict", "ContractsEstimateHint"]:
		labels.append(holder.find_child(label_name, true, false) as Label)
	_assert_empty_and_hidden(labels, "depois do setup")
	page.refresh(1, false)
	_assert_empty_and_hidden(labels, "depois do refresh sem jogo")
	page.set_shown(true)
	_assert_empty_and_hidden(labels, "com a página mostrada")
	idle_host.free()


func _assert_empty_and_hidden(labels: Array[Label], moment: String) -> void:
	for label: Label in labels:
		assert_not_null(label, "O rótulo existe na página.")
		assert_eq([label.visible, label.text, label.self_modulate], [false, "", Color.WHITE], "'%s' fica vazio, escondido e sem matiz sem jogo (%s)." % [label.name, moment])


func test_the_nine_new_keys_exist_and_every_key_of_the_page_exists() -> void:
	for key: String in NEW_KEYS:
		assert_true(_texts.has_key(key), key)
		assert_false(_texts.get_text(key).is_empty(), key)
	var constants: Dictionary = ContractsPage.new().get_script().get_script_constant_map()
	var checked: Array[String] = []
	for constant_name: String in constants:
		var value: Variant = constants[constant_name]
		if constant_name.begins_with("KEY_") and value is String and not String(value).ends_with(".") and not String(value).contains("%"):
			assert_true(_texts.has_key(value), "A chave %s (%s) existe em pt_br.json." % [constant_name, value])
			checked.append(value)
	for table_name: String in ["KEY_NOTES", "KEY_HINTS"]:
		for value: String in (constants[table_name] as Dictionary).values():
			assert_true(_texts.has_key(value), "A chave %s existe em pt_br.json." % value)
	assert_gte(checked.size(), 25, "A varredura enxerga as chaves da página.")
	for key: String in NEW_KEYS:
		assert_true(checked.has(key), "A página usa a chave %s." % key)


func test_no_contracts_text_promises_profit_and_every_margin_and_loss_carries_the_prices_phrase() -> void:
	var with_phrase: int = 0
	for key: String in NEW_KEYS:
		var text: String = _texts.get_text(key).to_lower()
		for word: String in FORBIDDEN_WORDS:
			assert_false(text.contains(word), "'%s' não pode conter '%s'." % [key, word])
		if text.contains("margem") or text.contains("prejuízo"):
			assert_true(text.contains(PRICES_PHRASE), "'%s' traz a frase de que os preços podem mudar." % key)
			with_phrase += 1
	assert_eq(with_phrase, 3, "Os três avisos (prejuízo, margem e margem pequena) trazem a frase.")
	var filled: Array[String] = [
		_texts.get_text("ui.contracts.estimate_cost", {"cost": 55}), _texts.get_text("ui.contracts.estimate_result", {"result": -2}), _texts.get_text("ui.contracts.verdict_loss", {"loss": 2}),
		_texts.get_text("ui.contracts.verdict_margin", {"margin": 5}), _texts.get_text("ui.contracts.verdict_margin_small", {"margin": 5}), _texts.get_text("ui.contracts.verdict_funds", {"short": 60}),
	]
	for text: String in filled:
		assert_false(text.contains("{") or text.contains("}"), "Todo marcador é preenchido: %s" % text)
