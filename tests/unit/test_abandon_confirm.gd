extends GutTest
## LW-107f4b, item (d): o painel de confirmação `AbandonConfirm` (docs/modules/presentation.md, "Encomendas por objetivo: abandonar, confirmar e capacidade"), sem janela de verdade. Os nós, o tema `MarketTheme` e os textos de `data/text/pt_br.json` são os REAIS, numa `SubViewport` de 1280 x 720: os cliques e as
## teclas entram por ela (`push_input`), pelo mesmo caminho de foco e de botão do Godot. O mundo é o jogo REAL (`GameAppNode.start_default_game`), com um contrato aceito pelo jogador, e quem ouve `confirmed` faz o que a `MarketView` fará na 107f4c: `request_contract_abandon` pela ponte; o `state_hash` e o
## estado do contrato na economia mostram o que cada caminho mudou. Confere: confirmar envia UMA vez; cancelar por botão, Esc, `interact` e Enter (o foco inicial é "Voltar") não envia nem altera; fechar sozinho (linha que deixa de ser abandonável, tela escondida) não envia; o fundo engole o clique; Tab e as
## quatro setas só circulam entre os dois botões (há botões de isca nos quatro lados); `consume_cancel`; textos por chave, tema e matiz de perigo; o painel não desloca os irmãos e cobre a tela. A ligação na página (`abandon_asked`, `abandon_requested`, `keep_if` no `refresh`) está em `test_contracts_page_abandon.gd`.

const SETTLEMENT_A: String = "test_settlement_a"
const SETTLEMENT_B: String = "test_settlement_b"
const BREAD: String = "bread"
const REWARD: int = 12
const QUANTITY: int = 2
const LONG_MINUTES: int = 600
const ABANDONED: String = "abandoned"
const KEY_PREFIX: String = "ui.contracts."
const KEY_FOR_MISSING_TEXT: String = "\\[[a-z_]+(\\.[a-z_]+)+\\]"
const VEIL: String = "ContractsConfirm"
const PANEL: String = "ContractsConfirmPanel"
const TEXT: String = "ContractsConfirmText"
const YES: String = "ContractsConfirmYes"
const BACK: String = "ContractsConfirmBack"
const SCREEN: Vector2 = Vector2(1280.0, 720.0)
## O botão de baixo do painel (no canto, sob o fundo) e as quatro iscas (acima, abaixo, à esquerda e à direita do centro: se uma seta vazasse do painel, teria para onde ir).
const DECOY_SIZE: Vector2 = Vector2(80.0, 32.0)
const DECOY_AT: Array[Vector2] = [Vector2(600.0, 120.0), Vector2(600.0, 580.0), Vector2(120.0, 340.0), Vector2(1060.0, 340.0)]

var _texts: UiText
var _host: SimulationHostNode
var _app: GameAppNode
var _bridge: SimBridge
var _economy: EconomyModule
var _actor_id: int = 0
var _contract_id: int = 0
var _view: SubViewport
var _screen: Control
var _flow: VBoxContainer
var _below: Button
var _confirm: AbandonConfirm
var _below_presses: int = 0
var _sent: Array[int] = []


func before_each() -> void:
	var loaded: UiText.LoadResult = UiText.from_file(UiText.DEFAULT_PATH)
	assert_true(loaded.result.ok, loaded.result.message)
	_texts = loaded.texts
	_sent.clear()
	_below_presses = 0
	_host = SimulationHostNode.new()
	_app = GameAppNode.new()
	_app.bind_host(_host)
	_app.start_default_game(_host)
	_bridge = _app.peek_bridge()
	_economy = _host.economy
	_actor_id = _bridge.request_spawn_character().actor_id
	assert_true(_bridge.request_open_player_account(_actor_id).ok)
	for place: BridgeReplies.PlaceReply in _bridge.peek_places().places:
		if place.kind == Place.KIND_MARKET and place.settlement_id == SETTLEMENT_A:
			assert_true(_bridge.request_report_position(_actor_id, Vector3(place.x, place.y, place.z), 0.0).ok)
	var posted: EconomyReplies.PostContractResult = _economy.request_post_contract(ContractBook.DELIVERY, _economy.peek_market_of(SETTLEMENT_A).market_id, REWARD, _bridge.peek_time().total_minutes + LONG_MINUTES, {"good_id": BREAD, "quantity": QUANTITY, "destination_id": _economy.peek_market_of(SETTLEMENT_B).market_id})
	assert_true(posted.result.ok, posted.result.message)
	_contract_id = posted.contract_id
	assert_true(_bridge.request_contract_accept(_actor_id, _contract_id).result.ok)
	_view = SubViewport.new()
	_view.size = Vector2i(SCREEN)
	add_child_autofree(_view)
	_screen = Control.new()
	_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_screen.theme = MarketTheme.build()
	_view.add_child(_screen)
	_flow = VBoxContainer.new()
	_screen.add_child(_flow)
	_below = _decoy(_flow, Vector2.ZERO)
	_below.pressed.connect(func() -> void: _below_presses += 1)
	for at: Vector2 in DECOY_AT:
		_decoy(_screen, at)
	_confirm = AbandonConfirm.new()
	_confirm.build(_flow, _texts)
	_confirm.confirmed.connect(_abandon_for_real)
	watch_signals(_confirm)
	await wait_process_frames(2)


func after_each() -> void:
	_app.free()
	_host.runner.finish()
	_host.free()


func _decoy(parent: Control, at: Vector2) -> Button:
	var button: Button = Button.new()
	button.custom_minimum_size = DECOY_SIZE
	button.position = at
	parent.add_child(button)
	return button


## O que a `MarketView` fará com `confirmed` (LW-107f4c): pedir o abandono pela ponte, que aqui tem de dar certo (um segundo pedido do mesmo contrato seria recusado).
func _abandon_for_real(contract_id: int) -> void:
	_sent.append(contract_id)
	assert_true(_bridge.request_contract_abandon(_actor_id, contract_id).result.ok, "O abandono do contrato %d foi recusado." % contract_id)


func _open() -> void:
	_confirm.open(_contract_id)
	await wait_process_frames(2)


func _button(button_name: String) -> Button:
	return _view.find_child(button_name, true, false) as Button


func _focus_name() -> String:
	var focused: Control = _view.gui_get_focus_owner()
	return "(nenhum)" if focused == null else String(focused.name)


func _mouse(at: Vector2, is_pressed: bool) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = at
	event.global_position = at
	event.pressed = is_pressed
	if is_pressed:
		event.button_mask = MOUSE_BUTTON_MASK_LEFT
	_view.push_input(event)


## Um clique de verdade no centro do controle: aperta e solta.
func _click(control: Control) -> void:
	_mouse(control.get_global_rect().get_center(), true)
	_mouse(control.get_global_rect().get_center(), false)


func _key(keycode: Key, shift: bool = false, is_pressed: bool = true) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = keycode
	event.pressed = is_pressed
	event.shift_pressed = shift
	_view.push_input(event)


## A tecla que o jogador aperta para a ação, tirada do `InputMap` (a ligação de verdade; nenhuma tecla escrita aqui).
func _press_of(action: StringName) -> InputEventKey:
	var event: InputEventKey = InputMap.action_get_events(action)[0].duplicate() as InputEventKey
	event.pressed = true
	return event


func _cancel_by(way: String) -> void:
	match way:
		"back":
			_click(_button(BACK))
		"escape":
			assert_true(_confirm.consume_cancel(_press_of(&"ui_cancel")), "Esc cancela o painel aberto.")
		"interact":
			assert_true(_confirm.consume_cancel(_press_of(InputActions.INTERACT)), "`interact` cancela o painel aberto.")
		"enter":
			_key(KEY_ENTER)
			_key(KEY_ENTER, false, false)


func _flow_layout() -> Array:
	return [_flow.get_combined_minimum_size(), _below.get_global_rect(), _flow.get_global_rect()]


func test_opening_puts_the_focus_on_back_and_confirming_sends_once_and_a_second_click_does_not_resend() -> void:
	_below.grab_focus()
	await _open()
	assert_eq([_confirm.is_open(), _confirm.asked_contract_id(), _view.gui_get_focus_owner()], [true, _contract_id, _button(BACK)], "Aberto para o contrato, com o foco inicial em \"Voltar\" (o Enter acidental não abandona).")
	_click(_button(YES))
	assert_eq([_sent, _confirm.is_open(), _confirm.asked_contract_id(), _view.gui_get_focus_owner()], [[_contract_id] as Array[int], false, IdGenerator.NO_ID, _below], "O clique em \"Abandonar\" envia UMA vez, fecha o painel e devolve o foco a quem o tinha.")
	_click(_button(YES))
	_button(YES).pressed.emit()
	assert_eq([_sent, get_signal_emit_count(_confirm, "confirmed"), get_signal_emit_count(_confirm, "cancelled")], [[_contract_id] as Array[int], 1, 0], "Um segundo clique (ou um `pressed` à mão) não reenvia, e confirmar não é cancelar.")
	assert_signal_emitted_with_parameters(_confirm, "confirmed", [_contract_id])
	var contract: EconomyReplies.ContractQuery = _economy.peek_contract(_contract_id)
	assert_eq([contract.state, contract.closed_reason], [ContractBook.STATE_FAILED, ABANDONED], "Só o \"Abandonar\" do painel levou o contrato, na economia real, a abandonado.")


func test_cancelling_by_button_escape_interact_and_enter_on_the_initial_focus_sends_nothing_and_changes_nothing() -> void:
	var world: String = _host.runner.world.state_hash()
	for way: String in ["back", "escape", "interact", "enter"]:
		_below.grab_focus()
		await _open()
		_cancel_by(way)
		assert_eq([_confirm.is_open(), _sent, get_signal_emit_count(_confirm, "confirmed"), _economy.peek_contract(_contract_id).state, _host.runner.world.state_hash(), _view.gui_get_focus_owner()], [false, [] as Array[int], 0, ContractBook.STATE_ACCEPTED, world, _below], "Cancelar por '%s' fecha o painel sem enviar: o contrato segue aceito, o mundo é o mesmo e o foco volta a quem o tinha." % way)
	assert_eq(get_signal_emit_count(_confirm, "cancelled"), 4, "Cada jeito de cancelar avisa `cancelled` UMA vez.")


func test_the_panel_closes_by_itself_without_sending_when_the_row_stops_being_abandonable_or_the_screen_hides() -> void:
	await _open()
	_confirm.keep_if(true)
	assert_true(_confirm.is_open(), "Ainda abandonável: o painel fica.")
	_confirm.keep_if(false)
	assert_eq([_confirm.is_open(), _confirm.asked_contract_id()], [false, IdGenerator.NO_ID], "A linha deixou de ser abandonável: o painel fecha sozinho.")
	await _open()
	_screen.visible = false
	assert_false(_confirm.is_open(), "A tela de mercado esconde: o painel fecha.")
	_screen.visible = true
	await wait_process_frames(1)
	assert_eq([_confirm.is_open(), _button(YES).is_visible_in_tree()], [false, false], "E não reaparece quando a tela volta.")
	assert_eq([_sent, get_signal_emit_count(_confirm, "confirmed"), get_signal_emit_count(_confirm, "cancelled")], [[] as Array[int], 0, 0], "Fechar sozinho não envia nada e não conta como decisão do jogador.")


func test_the_background_swallows_the_click_so_the_control_below_never_receives_it() -> void:
	_click(_below)
	assert_eq(_below_presses, 1, "Controle: com o painel fechado o clique chega ao botão de baixo.")
	await _open()
	_click(_below)
	assert_eq(_below_presses, 1, "Aberto, o fundo engole o clique: o botão de baixo não recebe.")
	_click(_button(BACK))
	_click(_below)
	assert_eq(_below_presses, 2, "Fechado de novo, o clique volta a chegar.")


func test_tab_and_the_four_arrows_circulate_only_between_the_two_buttons() -> void:
	await _open()
	var trace: Array[String] = []
	for press: Array in [[KEY_TAB, false], [KEY_TAB, true], [KEY_LEFT, false], [KEY_RIGHT, false], [KEY_UP, false], [KEY_DOWN, false]]:
		for _step: int in 2:
			_key(press[0], press[1])
			trace.append(_focus_name())
	var cycle: Array[String] = [YES, BACK, YES, BACK, YES, BACK, YES, BACK, YES, BACK, YES, BACK]
	assert_eq(trace, cycle, "Tab, Shift+Tab e as quatro setas só trocam o foco entre \"Abandonar\" e \"Voltar\" (com botões de isca nos quatro lados, nenhum o recebe).")
	for pair: Array in [[_button(YES), _button(BACK)], [_button(BACK), _button(YES)]]:
		var button: Button = pair[0]
		for path: NodePath in [button.focus_next, button.focus_previous, button.focus_neighbor_left, button.focus_neighbor_right, button.focus_neighbor_top, button.focus_neighbor_bottom]:
			assert_eq(button.get_node(path), pair[1], "Os seis vizinhos de foco de '%s' apontam para o outro botão: o painel os fecha em si mesmo, sem depender da travessia do motor." % button.name)


func test_consume_cancel_is_true_only_with_the_panel_open_and_for_escape_or_interact() -> void:
	assert_eq([_confirm.consume_cancel(_press_of(&"ui_cancel")), _confirm.consume_cancel(_press_of(InputActions.INTERACT))], [false, false], "Fechado: nada a consumir, a tela de mercado segue o caminho dela.")
	await _open()
	assert_false(_confirm.consume_cancel(_press_of(&"ui_accept")), "Outra ação não cancela.")
	var released: InputEventKey = _press_of(&"ui_cancel")
	released.pressed = false
	assert_false(_confirm.consume_cancel(released), "Soltar a tecla não cancela.")
	assert_true(_confirm.is_open(), "O painel segue aberto.")
	assert_eq([_confirm.consume_cancel(_press_of(&"ui_cancel")), _confirm.is_open()], [true, false], "Esc cancela e consome.")
	await _open()
	assert_eq([_confirm.consume_cancel(_press_of(InputActions.INTERACT)), _confirm.is_open()], [true, false], "`interact` também só cancela o painel.")
	assert_eq([get_signal_emit_count(_confirm, "cancelled"), _sent], [2, [] as Array[int]], "Duas decisões de cancelar, nada enviado.")


func test_the_texts_come_by_key_the_panel_uses_the_market_theme_and_only_abandonar_has_the_danger_tint() -> void:
	var missing: RegEx = RegEx.create_from_string(KEY_FOR_MISSING_TEXT)
	for pair: Array in [[TEXT, KEY_PREFIX + "confirm_text"], [YES, KEY_PREFIX + "confirm_yes"], [BACK, KEY_PREFIX + "confirm_back"]]:
		var node_name: String = pair[0]
		var key: String = pair[1]
		var shown: String = str(_view.find_child(node_name, true, false).get("text"))
		assert_true(_texts.has_key(key), "Falta a chave '%s'." % key)
		assert_eq(shown, _texts.get_text(key), "O texto de %s vem da chave." % node_name)
		assert_null(missing.search(shown), "Texto de chave que falta: %s." % shown)
	assert_ne(_texts.get_text(KEY_PREFIX + "confirm_yes"), _texts.get_text(KEY_PREFIX + "confirm_back"), "Os dois botões dizem coisas diferentes.")
	var panel_box: StyleBoxFlat = (_view.find_child(PANEL, true, false) as PanelContainer).get_theme_stylebox(&"panel") as StyleBoxFlat
	assert_eq([panel_box.bg_color, (_view.find_child(TEXT, true, false) as Label).theme_type_variation], [MarketTheme.COLOR_PANEL, MarketTheme.STATUS], "O painel e a frase usam o estilo do `MarketTheme` (nenhum estilo local).")
	assert_eq([_button(YES).self_modulate, _button(BACK).self_modulate], [ContractsLayout.DANGER_TINT, Color.WHITE], "Só o \"Abandonar\" leva o matiz de perigo.")


func test_the_open_panel_covers_the_whole_screen_in_the_middle_without_moving_the_siblings_in_its_box() -> void:
	var veil: Control = _view.find_child(VEIL, true, false) as Control
	assert_eq([veil.visible, veil.top_level, veil.mouse_filter], [false, true, Control.MOUSE_FILTER_STOP], "Nasce escondido, fora do fluxo da caixa (`top_level`) e engolindo o clique: um `Control` da página, não uma `Window`.")
	var before: Array = _flow_layout()
	await _open()
	assert_eq(_flow_layout(), before, "Aberto, o painel não ocupa espaço nem muda a posição dos irmãos.")
	assert_eq(veil.get_global_rect(), Rect2(Vector2.ZERO, SCREEN), "O fundo cobre a tela inteira.")
	assert_almost_eq((_view.find_child(PANEL, true, false) as Control).get_global_rect().get_center(), SCREEN / 2.0, Vector2(1.0, 1.0), "E o painel fica no centro dela.")


func test_build_with_a_null_parent_reports_an_error_and_open_does_nothing() -> void:
	var empty: AbandonConfirm = AbandonConfirm.new()
	empty.build(null, _texts)
	assert_push_error("raiz nula")
	empty.open(_contract_id)
	assert_eq([empty.is_open(), empty.consume_cancel(_press_of(&"ui_cancel"))], [false, false], "Sem nós, o painel nunca abre.")


func test_the_panel_is_already_closed_when_it_announces_the_confirmation() -> void:
	var open_when_heard: Array[bool] = []
	_confirm.confirmed.connect(func(_asked: int) -> void: open_when_heard.append(_confirm.is_open()))
	await _open()
	_click(_button(YES))
	assert_eq(open_when_heard, [false], "`close` vem ANTES de `confirmed`: quem ouve já encontra o painel fechado, então um clique feito de dentro do ouvinte não reenvia.")
