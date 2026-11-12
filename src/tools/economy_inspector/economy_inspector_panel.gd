class_name EconomyInspectorPanel
extends CanvasLayer
## Os nós do painel de depuração da economia (LW-108d; contrato em docs/modules/tools.md, "Painel econômico"): um texto rolável na lateral ESQUERDA, semitransparente, com a conferência da conservação (verde ou
## vermelha), o dinheiro total, e por povoado o mercado (preço e estoque de cada bem) e os locais de produção com o motivo de parada. O jogo continua rodando. SÓ LÊ: consulta a ponte (`peek_economy_*`),
## entrega as respostas ao `EconomyInspectorModel`, que decide o que mostrar, e desenha; NÃO tem nenhuma escrita (nem a marca de rastro do painel de NPC). Todo texto vem de data/text/pt_br.json (`UiText`);
## o id cru de um bem, receita ou povoado aparece só quando a chave do nome não existe. Começa FECHADO. Abre e fecha com Shift+Tab (a ação `inspector_toggle_alt` com o Shift apertado; decisão técnica da
## LW-108, relatada). A cor nunca é a única pista: as linhas de veredito e de parada têm a palavra ("OK", "ERRO", "PARADO").

## Valores [HIP]: a camada fica acima do painel de NPC, a largura é a fração da tela, a cor de fundo é semitransparente e as cores do veredito. 1 atualização por segundo (a economia só muda por hora de jogo).
const LAYER_INDEX: int = 21
const WIDTH_RATIO: float = 0.40
const BACKGROUND_COLOR: Color = Color(0.04, 0.06, 0.05, 0.84)
const COLOR_OK: Color = Color(0.45, 0.85, 0.45)
const COLOR_PROBLEM: Color = Color(1.0, 0.42, 0.42)
const COLOR_WARNING: Color = Color(0.96, 0.75, 0.29)
const REFRESH_INTERVAL_S: float = 1.0
const MARGIN_PX: int = 8
## Sufixo dos valores que são chave de texto de um nome (convenção do modelo) e o escape do colchete do BBCode.
const NAME_KEY_SUFFIX: String = "_key"
const BBCODE_OPEN_BRACKET: String = "[lb]"
## Chaves de texto do próprio painel (as das linhas estão em `EconomyInspectorModel`).
const KEY_TITLE: String = EconomyInspectorModel.KEY_PREFIX + "title"
const KEY_HINT: String = EconomyInspectorModel.KEY_PREFIX + "hint"
const KEY_SECTION_VERDICT: String = EconomyInspectorModel.KEY_PREFIX + "section_verdict"
const KEY_SECTION_MONEY: String = EconomyInspectorModel.KEY_PREFIX + "section_money"
const KEY_SECTION_SETTLEMENTS: String = EconomyInspectorModel.KEY_PREFIX + "section_settlements"
const KEY_SECTION_LIMITS: String = EconomyInspectorModel.KEY_PREFIX + "section_limits"

var _bridge: SimBridge
var _texts: UiText
var _model: EconomyInspectorModel = EconomyInspectorModel.new()
var _frame: PanelContainer
var _label: RichTextLabel
var _refresh_left_s: float = 0.0


func _init() -> void:
	layer = LAYER_INDEX
	visible = false
	set_process(false)
	_frame = PanelContainer.new()
	_frame.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	_frame.anchor_right = WIDTH_RATIO
	_frame.offset_right = 0.0
	var background: StyleBoxFlat = StyleBoxFlat.new()
	background.bg_color = BACKGROUND_COLOR
	background.set_content_margin_all(MARGIN_PX)
	_frame.add_theme_stylebox_override("panel", background)
	add_child(_frame)
	_label = RichTextLabel.new()
	_label.bbcode_enabled = true
	_label.scroll_following = false
	_label.focus_mode = Control.FOCUS_NONE
	_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_frame.add_child(_label)


## Liga o painel à ponte e aos textos. Qualquer um nulo: push_error e nada acontece (devolve falso).
func setup(bridge: SimBridge, texts: UiText) -> bool:
	if bridge == null or texts == null:
		push_error("EconomyInspectorPanel.setup: ponte ou textos nulos; esperado os dois.")
		return false
	_bridge = bridge
	_texts = texts
	return true


func model() -> EconomyInspectorModel:
	return _model


func is_open() -> bool:
	return visible


## Abre o painel e atualiza tudo na hora (sem esperar o ritmo).
func open() -> void:
	if _bridge == null:
		return
	visible = true
	set_process(true)
	_refresh_left_s = REFRESH_INTERVAL_S
	refresh()


func close() -> void:
	visible = false
	set_process(false)


func toggle() -> void:
	if visible:
		close()
	else:
		open()


## Trata a ação de entrada e devolve verdadeiro se o evento era dela: Shift+Tab (a ação `inspector_toggle_alt` COM o Shift apertado) abre e fecha. O Tab sozinho NÃO é dele (é do painel de NPC) e deixa o evento passar.
func handle_action(event: InputEvent) -> bool:
	if not event.is_action_pressed(InputActions.INSPECTOR_TOGGLE_ALT) or not _has_shift(event):
		return false
	toggle()
	return true


## Consulta a ponte (visão geral, mercados e locais), entrega ao modelo e redesenha.
func refresh() -> void:
	if _bridge == null:
		return
	_model.apply_overview(_bridge.peek_economy_overview())
	_model.apply_markets(_bridge.peek_economy_markets())
	_model.apply_sites(_bridge.peek_economy_sites())
	_label.text = _document()


## O texto que está na tela, sem as marcas de cor (para os testes e para conferir os números).
func plain_text() -> String:
	return _label.get_parsed_text()


## O texto com as marcas de cor (BBCode), como foi entregue ao `RichTextLabel`.
func marked_text() -> String:
	return _label.text


## A frase de uma linha do modelo: troca a chave pelo texto e cada nome (`good_key` e afins) pelo nome da chave, ou deixa o id cru se a chave não existe.
func text_of(line: EconomyInspectorModel.Line) -> String:
	var values: Dictionary = line.values.duplicate()
	for value_name: Variant in line.values:
		var field: String = str(value_name)
		if field.ends_with(NAME_KEY_SUFFIX) and _texts.has_key(str(line.values[value_name])):
			values[field.trim_suffix(NAME_KEY_SUFFIX)] = _texts.get_text(str(line.values[value_name]))
	return _texts.get_text(line.key, values)


func _process(delta: float) -> void:
	_refresh_left_s -= delta
	if _refresh_left_s <= 0.0:
		_refresh_left_s = REFRESH_INTERVAL_S
		refresh()


func _unhandled_input(event: InputEvent) -> void:
	if handle_action(event):
		get_viewport().set_input_as_handled()


## O Shift apertado no evento (só eventos com modificadores o têm; uma ação sem tecla não tem).
static func _has_shift(event: InputEvent) -> bool:
	return event is InputEventWithModifiers and (event as InputEventWithModifiers).shift_pressed


func _document() -> String:
	var parts: PackedStringArray = PackedStringArray()
	parts.append("[b]%s[/b]" % _escaped(_texts.get_text(KEY_TITLE)))
	parts.append(_escaped(_texts.get_text(KEY_HINT)))
	parts.append(_section(KEY_SECTION_VERDICT, _model.verdict_lines()))
	parts.append(_section(KEY_SECTION_MONEY, _model.money_lines()))
	parts.append(_section(KEY_SECTION_SETTLEMENTS, _model.settlement_lines()))
	parts.append(_section(KEY_SECTION_LIMITS, _model.limit_lines()))
	return "\n\n".join(parts)


func _section(title_key: String, lines: Array[EconomyInspectorModel.Line]) -> String:
	var rows: PackedStringArray = PackedStringArray([_escaped(_texts.get_text(title_key)).to_upper()])
	for line: EconomyInspectorModel.Line in lines:
		rows.append(_colored(line))
	return "\n".join(rows)


## A linha pronta: a frase, o colchete escapado (as mensagens do `validate()` podem ter) e a cor da gravidade; a conferência da conservação sai em negrito.
func _colored(line: EconomyInspectorModel.Line) -> String:
	var text: String = _escaped(text_of(line))
	if line.key == EconomyInspectorModel.KEY_CONSERVATION_OK or line.key == EconomyInspectorModel.KEY_CONSERVATION_BAD:
		text = "[b]%s[/b]" % text
	match line.severity:
		EconomyInspectorModel.Severity.OK:
			return "[color=#%s]%s[/color]" % [COLOR_OK.to_html(false), text]
		EconomyInspectorModel.Severity.PROBLEM:
			return "[color=#%s]%s[/color]" % [COLOR_PROBLEM.to_html(false), text]
		EconomyInspectorModel.Severity.WARNING:
			return "[color=#%s]%s[/color]" % [COLOR_WARNING.to_html(false), text]
	return text


static func _escaped(text: String) -> String:
	return text.replace("[", BBCODE_OPEN_BRACKET)
