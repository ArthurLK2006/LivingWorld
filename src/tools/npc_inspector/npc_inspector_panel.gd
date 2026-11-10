class_name NpcInspectorPanel
extends CanvasLayer
## Os nós do painel de depuração de NPC (LW-082f; contrato em docs/modules/tools.md): lista rolável de TODOS os NPCs (inclusive os sem corpo), os contadores
## do mundo e, do NPC selecionado, necessidades, ação, ofício, rastro, memórias e relações. Fica na lateral direita, semitransparente, e o jogo continua
## rodando. Só LÊ: consulta a ponte (`peek_*`) e entrega as respostas ao `NpcInspectorModel`, que decide o que mostrar; a ÚNICA escrita é `toggle_trace`, que
## marca ou desmarca o NPC para o rastro (`request_set_npc_traced`; decisão de Arthur). Todo texto vem de data/text/pt_br.json (`UiText`); os ids dos dados
## aparecem crus. Começa FECHADO. Quem abre, fecha e troca de NPC por tecla é a LW-082g; aqui só estão os métodos.

## Valores [HIP]: a camada fica acima do HUD, a largura é a fração da tela e a cor é de fundo semitransparente. 4 atualizações por segundo e o resumo do
## mundo, que é mais caro, cerca de 1 vez por segundo (decisão de Arthur, Q6).
const LAYER_INDEX: int = 20
const WIDTH_RATIO: float = 0.35
const BACKGROUND_COLOR: Color = Color(0.04, 0.05, 0.08, 0.82)
const REFRESH_INTERVAL_S: float = 0.25
const SUMMARY_INTERVAL_S: float = 1.0
const MARGIN_PX: int = 8
## Chaves de texto do próprio painel (as do modelo estão em `NpcInspectorModel`).
const KEY_TITLE: String = NpcInspectorModel.KEY_PREFIX + "title"
const KEY_HINT: String = NpcInspectorModel.KEY_PREFIX + "hint"
const KEY_NO_SELECTION: String = NpcInspectorModel.KEY_PREFIX + "no_selection"
const KEY_SELECTED_HEADER: String = NpcInspectorModel.KEY_PREFIX + "selected_header"
const KEY_SECTION_TRACE: String = NpcInspectorModel.KEY_PREFIX + "section_trace"
const KEY_SECTION_MEMORIES: String = NpcInspectorModel.KEY_PREFIX + "section_memories"
const KEY_SECTION_RELATIONS: String = NpcInspectorModel.KEY_PREFIX + "section_relations"
const KEY_LIST_ROW: String = NpcInspectorModel.KEY_PREFIX + "list_row"
const KEY_LIST_ROW_DEAD: String = NpcInspectorModel.KEY_PREFIX + "list_row_dead"

var _bridge: SimBridge
var _texts: UiText
var _model: NpcInspectorModel = NpcInspectorModel.new()
var _frame: PanelContainer
var _summary_label: Label
var _list: ItemList
var _detail_label: RichTextLabel
var _list_rows: PackedStringArray = PackedStringArray()
var _refresh_left_s: float = 0.0
var _summary_left_s: float = 0.0


func _init() -> void:
	layer = LAYER_INDEX
	visible = false
	set_process(false)
	_frame = PanelContainer.new()
	_frame.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	_frame.anchor_left = 1.0 - WIDTH_RATIO
	_frame.offset_left = 0.0
	var background: StyleBoxFlat = StyleBoxFlat.new()
	background.bg_color = BACKGROUND_COLOR
	background.set_content_margin_all(MARGIN_PX)
	_frame.add_theme_stylebox_override("panel", background)
	add_child(_frame)
	var column: VBoxContainer = VBoxContainer.new()
	_frame.add_child(column)
	_summary_label = Label.new()
	_list = ItemList.new()
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.item_selected.connect(_on_list_item_selected)
	_detail_label = RichTextLabel.new()
	_detail_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail_label.scroll_following = false
	for node: Control in [_summary_label, _list, _detail_label]:
		column.add_child(node)


## Liga o painel à ponte e aos textos. Qualquer um nulo: push_error e nada acontece (devolve falso).
func setup(bridge: SimBridge, texts: UiText) -> bool:
	if bridge == null or texts == null:
		push_error("NpcInspectorPanel.setup: ponte ou textos nulos; esperado os dois.")
		return false
	_bridge = bridge
	_texts = texts
	return true


func model() -> NpcInspectorModel:
	return _model


func is_open() -> bool:
	return visible


## Abre o painel e atualiza tudo na hora (sem esperar o ritmo).
func open() -> void:
	if _bridge == null:
		return
	visible = true
	set_process(true)
	refresh_summary()
	refresh()


func close() -> void:
	visible = false
	set_process(false)


func toggle() -> void:
	if visible:
		close()
	else:
		open()


func select_next() -> void:
	_model.select_next()
	refresh()


func select_previous() -> void:
	_model.select_previous()
	refresh()


## A ÚNICA escrita do painel (decisão de Arthur): marca o NPC selecionado para o rastro, ou desmarca se já está marcado. Sem seleção não faz nada.
## Em build que não é de desenvolvimento a ponte recusa (NPC_DEV_ONLY) e nada muda.
func toggle_trace() -> void:
	if _bridge == null or _model.selected_id() == NpcInspectorModel.NO_NPC:
		return
	_bridge.request_set_npc_traced(_model.selected_id(), not _model.is_traced())
	refresh()


## Consulta a ponte (lista, e do selecionado o detalhe, o rastro, as memórias e as relações), entrega ao modelo e redesenha.
func refresh() -> void:
	if _bridge == null:
		return
	_model.apply_roster(_bridge.peek_npc_roster())
	var selected: int = _model.selected_id()
	if selected != NpcInspectorModel.NO_NPC:
		_model.apply_detail(_bridge.peek_npc_detail(selected))
		_model.apply_trace(_bridge.peek_npc_trace(selected))
		_model.apply_memories(_bridge.peek_npc_memories(selected))
		_model.apply_relations(_bridge.peek_npc_relations(selected))
	_redraw()


## O resumo global (o `validate()` do mundo inteiro) tem custo que não foi medido: por isso vem num ritmo mais lento.
func refresh_summary() -> void:
	if _bridge != null:
		_model.apply_summary(_bridge.peek_simulation_summary())
		_summary_label.text = _join(_model.summary_lines())


func summary_text() -> String:
	return _summary_label.text


func detail_text() -> String:
	return _detail_label.text


func list_row_count() -> int:
	return _list.item_count


func _process(delta: float) -> void:
	_refresh_left_s -= delta
	_summary_left_s -= delta
	if _summary_left_s <= 0.0:
		_summary_left_s = SUMMARY_INTERVAL_S
		refresh_summary()
	if _refresh_left_s <= 0.0:
		_refresh_left_s = REFRESH_INTERVAL_S
		refresh()


func _on_list_item_selected(index: int) -> void:
	var roster: Array[BridgeInspectReplies.NpcRosterEntry] = _model.roster()
	if index >= 0 and index < roster.size() and _model.select(roster[index].npc_id):
		refresh()


func _redraw() -> void:
	_redraw_list()
	var selected: BridgeInspectReplies.NpcRosterEntry = _model.selected_entry()
	var sections: PackedStringArray = PackedStringArray([_texts.get_text(KEY_TITLE), _texts.get_text(KEY_HINT)])
	if selected == null:
		sections.append(_texts.get_text(KEY_NO_SELECTION))
	else:
		sections.append(_texts.get_text(KEY_SELECTED_HEADER, {"name": _name_of(selected), "id": selected.npc_id}))
		sections.append(_join(_model.detail_lines()))
		sections.append(_texts.get_text(KEY_SECTION_TRACE) + "\n" + _join(_model.trace_lines()))
		sections.append(_texts.get_text(KEY_SECTION_MEMORIES) + "\n" + _join(_model.memory_lines()))
		sections.append(_texts.get_text(KEY_SECTION_RELATIONS) + "\n" + _join(_model.relation_lines()))
	_detail_label.text = "\n\n".join(sections)


## Só refaz a lista se as linhas mudaram (senão a rolagem e a seleção do jogador voltariam ao começo a cada atualização).
func _redraw_list() -> void:
	var rows: PackedStringArray = PackedStringArray()
	for entry: BridgeInspectReplies.NpcRosterEntry in _model.roster():
		var level: String = "S0" if entry.level == BridgeInspectReplies.NpcLevel.S0 else "S1"
		if entry.is_alive:
			rows.append(_texts.get_text(KEY_LIST_ROW, {"name": _name_of(entry), "occupation": _raw(entry.occupation_id), "action": _raw(entry.action_id), "level": level}))
		else:
			rows.append(_texts.get_text(KEY_LIST_ROW_DEAD, {"name": _name_of(entry), "level": level}))
	if rows != _list_rows:
		var scroll: float = _list.get_v_scroll_bar().value
		_list.clear()
		for row: String in rows:
			_list.add_item(row)
		_list_rows = rows
		_list.get_v_scroll_bar().value = scroll
	var position: int = _model.roster().find(_model.selected_entry())
	if position >= 0:
		_list.select(position)
		_list.ensure_current_is_visible()


func _name_of(entry: BridgeInspectReplies.NpcRosterEntry) -> String:
	return _texts.get_text(entry.name_key, {"number": entry.name_number})


func _join(lines: Array[NpcInspectorModel.Line]) -> String:
	var texts: PackedStringArray = PackedStringArray()
	for line: NpcInspectorModel.Line in lines:
		texts.append(_texts.get_text(line.key, line.values))
	return "\n".join(texts)


static func _raw(text: String) -> String:
	return text if not text.is_empty() else NpcInspectorModel.EMPTY_MARK
