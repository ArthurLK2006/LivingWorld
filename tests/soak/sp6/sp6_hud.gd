class_name Sp6Hud
extends Control
## LW-152 (SP6, DESCARTÁVEL): a tela do teste de combate, em português. Só LÊ as regras e desenha: barra de vida do alvo (com a armadura),
## linha de posição, três espaços de habilidade (tecla, nome, estado e progresso do preparo e da recuperação), barra de estamina e
## mensagens curtas. Nenhum controle captura o mouse, para o clique no boneco chegar ao jogo. Textos literais de propósito: o spike não
## mexe em data/text/pt_br.json (autorização A3 de Arthur).

const PANEL_WIDTH_PX: float = 560.0
const SLOT_WIDTH_PX: float = 180.0
const BAR_HEIGHT_PX: float = 16.0
const TOP_MARGIN_PX: int = 112
const BOTTOM_MARGIN_PX: int = 16
const FONT_SIZE: int = 20
const MESSAGE_FONT_SIZE: int = 44
const OUTLINE_SIZE: int = 6
const HELP_FONT_SIZE: int = 16
const MESSAGE_HALF_WIDTH_PX: float = 300.0
## A mensagem fica logo abaixo do jogador e do boneco, longe da barra de vida e dos números de dano.
const MESSAGE_BELOW_CENTER_PX: float = 70.0
const HELP_LINES: Array[String] = [
	"Clique no boneco: alvo  |  Q R F: habilidades  |  T: armadura do boneco",
	"Esc: soltar alvo  |  Botão direito e arrastar: girar a câmera",
]
const HP_COLOR: Color = Color(0.95, 0.2, 0.15)
const STAMINA_COLOR: Color = Color(0.25, 0.9, 0.3)
const WINDUP_COLOR: Color = Color(1.0, 0.65, 0.2)
const RECOVERY_COLOR: Color = Color(0.45, 0.65, 1.0)
const BAR_BACKGROUND_COLOR: Color = Color(0.05, 0.05, 0.08, 0.85)
## Cor do texto de cada estado de espaço, na ordem de Sp6Rules.SlotState.
const STATE_COLORS: Array[Color] = [
	Color(1.0, 1.0, 1.0), Color(1.0, 0.65, 0.2), Color(0.55, 0.7, 1.0), Color(1.0, 0.4, 0.35),
	Color(1.0, 0.4, 0.35), Color(0.7, 0.7, 0.7), Color(0.7, 0.7, 0.7),
]
const MS_PER_SECOND: float = 1000.0

var _hp_label: Label
var _hp_bar: ProgressBar
var _position_label: Label
var _message_label: Label
var _stamina_label: Label
var _stamina_bar: ProgressBar
var _slot_labels: Array[Label] = []
var _slot_bars: Array[ProgressBar] = []
var _message_left_s: float = 0.0


func _ready() -> void:
	# Só set_anchors_preset deixou o painel com tamanho 0 x 0 (medido numa execução com janela); set_anchors_and_offsets_preset o ajusta.
	_fit_to_screen()
	get_viewport().size_changed.connect(_fit_to_screen)
	var top: VBoxContainer = _column(Control.PRESET_CENTER_TOP, Control.GROW_DIRECTION_END, TOP_MARGIN_PX)
	_hp_label = _label(top, FONT_SIZE)
	_hp_bar = _bar(top, HP_COLOR, Sp6Constants.DUMMY_MAX_HP)
	_position_label = _label(top, FONT_SIZE)
	var bottom: VBoxContainer = _column(Control.PRESET_CENTER_BOTTOM, Control.GROW_DIRECTION_BEGIN, BOTTOM_MARGIN_PX)
	var slots: HBoxContainer = HBoxContainer.new()
	bottom.add_child(slots)
	for _slot: int in Sp6Constants.SKILL_COUNT:
		var slot_box: VBoxContainer = VBoxContainer.new()
		slot_box.custom_minimum_size.x = SLOT_WIDTH_PX
		slots.add_child(slot_box)
		_slot_labels.append(_label(slot_box, FONT_SIZE))
		_slot_bars.append(_bar(slot_box, Color.WHITE, Sp6Constants.PERCENT))
	_stamina_label = _label(bottom, FONT_SIZE)
	_stamina_bar = _bar(bottom, STAMINA_COLOR, Sp6Constants.STAMINA_MAX)
	for line: String in HELP_LINES:
		_label(bottom, HELP_FONT_SIZE).text = line
	_message_label = _label(self, MESSAGE_FONT_SIZE)
	_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message_label.set_anchors_preset(Control.PRESET_CENTER)
	_message_label.offset_left = -MESSAGE_HALF_WIDTH_PX
	_message_label.offset_right = MESSAGE_HALF_WIDTH_PX
	_message_label.offset_top = MESSAGE_BELOW_CENTER_PX
	# O próprio painel (que cobre a tela toda) também precisa ignorar o mouse; find_children não o inclui.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for control: Control in find_children("*", "Control", true, false):
		control.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _fit_to_screen() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func show_message(text_to_show: String) -> void:
	_message_label.text = text_to_show
	_message_left_s = float(Sp6Constants.MESSAGE_MS) / MS_PER_SECOND


func refresh(rules: Sp6Rules) -> void:
	_hp_label.text = "%sBoneco de treino  |  armadura %s  |  vida %d/%d" % [
		"ALVO: " if rules.has_target() else "", Sp6Constants.ARMOR_NAMES[rules.armor()], rules.dummy_hp(), Sp6Constants.DUMMY_MAX_HP]
	_hp_bar.value = rules.dummy_hp()
	_position_label.visible = rules.has_target()
	var names: PackedStringArray = PackedStringArray()
	var multipliers: PackedStringArray = PackedStringArray()
	for group: int in Sp6Constants.POSITION_NAMES.size():
		names.append("[%s]" % Sp6Constants.POSITION_NAMES[group] if group == rules.position_group() else Sp6Constants.POSITION_NAMES[group])
		multipliers.append("x%d,%02d" % [IntMath.floor_div(Sp6Constants.POSITION_PCT[group], Sp6Constants.PERCENT), posmod(Sp6Constants.POSITION_PCT[group], Sp6Constants.PERCENT)])
	_position_label.text = "Posição: %s  (%s)" % [" | ".join(names), " | ".join(multipliers)]
	for slot: int in Sp6Constants.SKILL_COUNT:
		var state: int = rules.slot_state(slot)
		_slot_labels[slot].text = "[%s] %s\n%s" % [Sp6Constants.SKILL_KEYS[slot], Sp6Constants.SKILL_NAMES[slot], Sp6Constants.SLOT_STATE_NAMES[state]]
		_slot_labels[slot].modulate = STATE_COLORS[state]
		_slot_bars[slot].value = rules.phase_progress_pct() if slot == rules.active_skill() else 0
		_slot_bars[slot].modulate = RECOVERY_COLOR if state == Sp6Rules.SlotState.RECOVERY else WINDUP_COLOR
	_stamina_label.text = "Estamina %d/%d" % [rules.stamina(), Sp6Constants.STAMINA_MAX]
	_stamina_bar.value = float(rules.stamina_milli()) / float(Sp6Constants.MILLI_PER_POINT)


func _process(delta: float) -> void:
	if _message_left_s > 0.0:
		_message_left_s -= delta
		if _message_left_s <= 0.0:
			_message_label.text = ""


## Coluna ancorada no topo ou na base, centrada; cresce para dentro da tela (para baixo no topo, para cima na base).
func _column(preset: Control.LayoutPreset, grow: Control.GrowDirection, margin_px: int) -> VBoxContainer:
	var column: VBoxContainer = VBoxContainer.new()
	column.custom_minimum_size.x = PANEL_WIDTH_PX
	add_child(column)
	column.set_anchors_and_offsets_preset(preset, Control.PRESET_MODE_MINSIZE, margin_px)
	column.grow_horizontal = Control.GROW_DIRECTION_BOTH
	column.grow_vertical = grow
	return column


func _label(parent: Control, font_size: int) -> Label:
	var label: Label = Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_constant_override("outline_size", OUTLINE_SIZE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	parent.add_child(label)
	return label


## Barra com preenchimento vivo sobre fundo escuro (o estilo padrão dava pouco contraste); a cor dos espaços de habilidade muda por `modulate`.
func _bar(parent: Control, fill_color: Color, max_value: int) -> ProgressBar:
	var bar: ProgressBar = ProgressBar.new()
	bar.show_percentage = false
	bar.max_value = max_value
	bar.custom_minimum_size.y = BAR_HEIGHT_PX
	var fill: StyleBoxFlat = StyleBoxFlat.new()
	fill.bg_color = fill_color
	var background: StyleBoxFlat = StyleBoxFlat.new()
	background.bg_color = BAR_BACKGROUND_COLOR
	bar.add_theme_stylebox_override("fill", fill)
	bar.add_theme_stylebox_override("background", background)
	parent.add_child(bar)
	return bar
