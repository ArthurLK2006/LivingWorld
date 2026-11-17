extends GutTest
## LW-107f4c (itens (e), (f) e (g) de docs/modules/presentation.md, "Encomendas por objetivo: abandonar, confirmar e capacidade"): a fiação da `MarketView` do abandono, do CLIQUE até a RESPOSTA, sem janela de verdade e pelo caminho real. O jogo é o REAL (`GameAppNode.start_default_game`: dados de `res://data`, NPCs, o limite de 3 encomendas), com os textos reais
## (`data/text/pt_br.json`); a ponte é a `SpyBridge`, o `SimBridge` com os mesmos argumentos que o `GameApp` lhe dá, que ANOTA cada pedido de contrato que a tela envia e repassa à de verdade; a `MarketView` é a de verdade, aberta junto do mercado A numa `SubViewport` de 1280 x 720 (como `test_contracts_actions.gd`: os contratos são postados DIRETO na economia e o relógio anda ou
## pára pela ponte). Os cliques e as teclas entram pela `SubViewport` (`push_input`), o Esc e o `interact` com os eventos do `InputMap` e pelo `_input` da própria tela (nunca por `consume_cancel` direto); o `Probe` mede o que sobra para quem ouve o evento depois da tela (`_unhandled_input`, onde a `InteractionView` lê o `interact`). Confere: o botão "Abandonar" (matiz de perigo, desativado sem linha
## abandonável), a capacidade "n de 3" e "Aceitar" desativado no limite (e a recusa `economy.contract.limit` mostrada quando a leitura é velha); o clique abre o painel e SÓ o "Abandonar" dele envia, UMA vez, com a frase de `economy.contract.abandoned`, o contrato `failed` com `closed_reason` `abandoned`, saldo, inventário e custódia certos e a linha "Abandonado" (nem "Falhou" nem "Vencido"); uma recusa da ponte (`not_open`: abandonado em outro lugar depois da leitura) mostra a frase da própria chave e nada muda; "Voltar", Esc e `interact`
## cancelam sem enviar e a tela só fecha na tecla seguinte; relógio pausado (o clique antes da leitura não envia e o painel fecha sozinho na seguinte); tela fechada leva o painel; abrir, trocar de aba e cancelar não mudam o `state_hash`; e nenhum rótulo mostra `[chave]`.

const WORLD_DIR: String = "res://data/world"
const SETTLEMENT_A: String = "test_settlement_a"
const SETTLEMENT_B: String = "test_settlement_b"
const BREAD: String = "bread"
const ABANDONED: String = "abandoned"
## Os números dos contratos do teste (os do jogo são [HIP]) e o limite do dado real (`data/economy/contract_limits.json`).
const REWARD: int = 12
const QUANTITY: int = 2
const LONG_MINUTES: int = 600
const LIMIT: int = 3
const SCREEN: Vector2i = Vector2i(1280, 720)
const KEY_FOR_MISSING_TEXT: String = "\\[[a-z_]+(\\.[a-z_]+)+\\]"
## As 13 chaves `economy.contract.*` (sem o prefixo): as 11 de antes e as 2 da LW-107f4c (`abandoned` e `limit`).
const REPLY_KEYS: Array[String] = ["accepted", "delivered", "not_open", "unknown", "impossible", "no_goods", "destination_full", "too_far", "not_yours", "expired", "failed", "abandoned", "limit"]
const TAB_CONTRACTS: String = "MarketTabContracts"
const TAB_MARKET: String = "MarketTabMarket"
const OPEN_LIST: String = "ContractsOpen"
const MINE_LIST: String = "ContractsMine"
const ACCEPT: String = "ContractsAccept"
const ABANDON: String = "ContractsAbandon"
const CAPACITY: String = "ContractsCapacity"
const RESULT: String = "ContractsResult"
const CONFIRM: String = "ContractsConfirm"
const CONFIRM_YES: String = "ContractsConfirmYes"
const CONFIRM_BACK: String = "ContractsConfirmBack"

var _terrain: TerrainData
var _places: Array[Place] = []
var _texts: UiText
var _center_a: Vector3
var _host: SimulationHostNode
var _app: GameAppNode
var _bridge: SpyBridge
var _economy: EconomyModule
var _actor_id: int = 0
var _market_a: int = 0
var _market_b: int = 0
var _screen: SubViewport
var _probe: Probe
var _view: MarketView


## Ponte que ANOTA todo pedido de contrato (`sent`, com o ID) e repassa à de verdade: o que a tela envia e o que NÃO envia.
class SpyBridge:
	extends SimBridge

	var sent: Array[String] = []

	func request_contract_accept(actor_id: int, contract_id: int) -> BridgePlayerContractsReplies.ContractActionReply:
		sent.append("accept %d" % contract_id)
		return super(actor_id, contract_id)

	func request_contract_deliver(actor_id: int, contract_id: int) -> BridgePlayerContractsReplies.ContractActionReply:
		sent.append("deliver %d" % contract_id)
		return super(actor_id, contract_id)

	func request_contract_abandon(actor_id: int, contract_id: int) -> BridgePlayerContractsReplies.ContractActionReply:
		sent.append("abandon %d" % contract_id)
		return super(actor_id, contract_id)


## Conta as teclas que a tela de mercado NÃO tratou (chegam a `_unhandled_input`, como à `InteractionView` do jogo).
class Probe:
	extends Node

	var keys_seen: int = 0

	func _unhandled_input(event: InputEvent) -> void:
		if event is InputEventKey:
			keys_seen += 1


func before_all() -> void:
	var loaded: TerrainLoader.LoadResult = TerrainLoader.load_dir(WORLD_DIR)
	assert_true(loaded.result.ok, loaded.result.message)
	_terrain = loaded.terrain
	var settlements: SettlementLoader.LoadResult = SettlementLoader.load_dir(WORLD_DIR, _terrain)
	assert_true(settlements.result.ok, settlements.result.message)
	_places = settlements.places
	for place: Place in _places:
		if place.kind == Place.KIND_MARKET and place.settlement_id == SETTLEMENT_A:
			_center_a = place.position
	var texts: UiText.LoadResult = UiText.from_file(UiText.DEFAULT_PATH)
	assert_true(texts.result.ok, texts.result.message)
	_texts = texts.texts


## O jogo real com o jogador junto ao mercado A e a conta aberta, e a tela FECHADA, ligada à ponte espiã, dentro de uma `SubViewport`.
func before_each() -> void:
	_host = SimulationHostNode.new()
	_app = GameAppNode.new()
	_app.bind_host(_host)
	_app.start_default_game(_host)
	_bridge = SpyBridge.new(_host, _terrain, _places, _host.npc)
	_economy = _host.economy
	_actor_id = _bridge.request_spawn_character().actor_id
	assert_true(_bridge.request_report_position(_actor_id, _center_a, 0.0).ok, "O jogador começa junto ao mercado A.")
	assert_true(_bridge.request_open_player_account(_actor_id).ok)
	_market_a = _economy.peek_market_of(SETTLEMENT_A).market_id
	_market_b = _economy.peek_market_of(SETTLEMENT_B).market_id
	_screen = SubViewport.new()
	_screen.size = SCREEN
	add_child_autofree(_screen)
	_probe = Probe.new()
	_screen.add_child(_probe)
	_view = MarketView.new()
	_screen.add_child(_view)
	assert_true(_view.setup(_bridge, _texts, _actor_id, [] as Array[Node]))
	watch_signals(_view)


func after_each() -> void:
	_app.free()
	_host.runner.finish()
	_host.free()


func _text(key: String, values: Dictionary = {}) -> String:
	return _texts.get_text(key, values)


func _say(key: String, values: Dictionary = {}) -> String:
	return _text("ui.contracts." + key, values)


func _node(node_name: String) -> Node:
	return _view.find_child(node_name, true, false)


func _tree(list_name: String) -> Tree:
	return _node(list_name) as Tree


func _is_off(button_name: String) -> bool:
	return (_node(button_name) as Button).disabled


func _label(label_name: String) -> String:
	return (_node(label_name) as Label).text


## A flag `visible` do painel de confirmação (não a visibilidade na árvore): é o que `close` e o `hidden` mexem.
func _confirm_open() -> bool:
	return (_node(CONFIRM) as Control).visible


func _funds() -> int:
	return _bridge.peek_player_economy(_actor_id).funds


func _state_of(contract_id: int) -> String:
	return _economy.peek_contract(contract_id).state


func _row_of(list_name: String, contract_id: int) -> TreeItem:
	for item: TreeItem in _tree(list_name).get_root().get_children():
		if item.get_metadata(ContractsLayout.COLUMN_LINE) == contract_id:
			return item
	return null


## Posta um contrato de pão de A para `destination`, direto na economia (A paga a recompensa para a custódia), e devolve o ID.
func _post(destination: int) -> int:
	var now: int = _bridge.peek_time().total_minutes
	var posted: EconomyReplies.PostContractResult = _economy.request_post_contract(ContractBook.DELIVERY, _market_a, REWARD, now + LONG_MINUTES, {"good_id": BREAD, "quantity": QUANTITY, "destination_id": destination})
	assert_true(posted.result.ok, posted.result.message)
	return posted.contract_id


## O jogador aceita o contrato direto na economia (a montagem; a ponte não vê, então `sent` só traz o que a TELA envia).
func _take(contract_id: int) -> void:
	var accepted: Result = _economy.request_accept_contract(contract_id, _actor_id)
	assert_true(accepted.ok, accepted.message)


func _hold() -> int:
	var contract_id: int = _post(_market_b)
	_take(contract_id)
	return contract_id


## Põe `QUANTITY` de pão no inventário do jogador (tirado do mercado A, direto na economia).
func _give_bread() -> void:
	var moved: Result = _economy.request_transfer_goods(_market_a, _actor_id, BREAD, QUANTITY)
	assert_true(moved.ok, moved.message)


## Abre a tela sobre o mercado A e escolhe a aba "Contratos" por um clique. O `_process` fica desligado: a leitura de 1 s só acontece quando o teste a pede (`refresh` ou `simulate`), nunca entre dois passos.
func _open_contracts() -> void:
	_view.open(_market_a)
	_view.set_process(false)
	await wait_process_frames(2)
	await _click(_node(TAB_CONTRACTS) as Control)


## Um clique de verdade (aperta e solta) em `at`, pela `SubViewport`, e dois quadros para o leiaute assentar.
func _click_at(at: Vector2) -> void:
	for is_pressed: bool in [true, false]:
		var event: InputEventMouseButton = InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = at
		event.global_position = at
		event.pressed = is_pressed
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if is_pressed else 0
		_screen.push_input(event)
	await wait_process_frames(2)


func _click(control: Control) -> void:
	await _click_at(control.get_global_rect().get_center())


## Clica na linha do contrato, na lista `list_name`, e confere que a página a escolheu.
func _click_row(list_name: String, contract_id: int) -> void:
	await wait_process_frames(2)
	var tree: Tree = _tree(list_name)
	await _click_at(tree.get_global_rect().position + tree.get_item_area_rect(_row_of(list_name, contract_id), ContractsLayout.COLUMN_LINE).get_center())
	var picked: TreeItem = tree.get_selected()
	assert_true(picked != null and picked.get_metadata(ContractsLayout.COLUMN_LINE) == contract_id, "O clique escolheu a linha do contrato %d." % contract_id)


## A tecla que o jogador aperta para a ação, tirada do `InputMap` (a ligação de verdade), entregue pela `SubViewport` ao `_input` da tela.
func _press(action: StringName) -> void:
	var event: InputEventKey = InputMap.action_get_events(action)[0].duplicate() as InputEventKey
	event.pressed = true
	_screen.push_input(event)


## Os textos que a tela mostra (rótulos, botões e células das listas) que são chave faltando (`[chave]`).
func _missing_texts() -> Array[String]:
	var missing: RegEx = RegEx.create_from_string(KEY_FOR_MISSING_TEXT)
	var shown: Array[String] = []
	for node: Node in _view.find_children("*", "", true, false):
		if node is Label:
			shown.append((node as Label).text)
		elif node is Button:
			shown.append((node as Button).text)
		elif node is Tree and (node as Tree).get_root() != null:
			for item: TreeItem in (node as Tree).get_root().get_children():
				for column: int in (node as Tree).columns:
					shown.append(item.get_text(column))
	return shown.filter(func(text: String) -> bool: return missing.search(text) != null)


func test_the_abandon_button_is_tinted_and_disabled_until_a_row_of_mine_can_be_abandoned() -> void:
	await _open_contracts()
	assert_eq([_is_off(ABANDON), (_node(ABANDON) as Button).self_modulate, (_node(ACCEPT) as Button).self_modulate], [true, ContractsLayout.DANGER_TINT, Color.WHITE], "Sem encomenda nenhuma, \"Abandonar\" está desativado e leva o matiz de perigo (o \"Aceitar\" não).")
	var open_id: int = _post(_market_b)
	var mine_id: int = _hold()
	_view.refresh()
	await _click_row(OPEN_LIST, open_id)
	assert_true(_is_off(ABANDON), "Uma linha aberta, que ainda não é minha, não se abandona.")
	await _click_row(MINE_LIST, mine_id)
	assert_eq([_is_off(ABANDON), _bridge.sent], [false, [] as Array[String]], "A minha, aceita e no prazo: ativo. Escolher a linha não envia nada.")


func test_the_capacity_reads_n_of_3_and_accept_is_off_at_the_limit_and_a_stale_accept_shows_the_limit_refusal() -> void:
	assert_eq(_economy.peek_contract_limit(ContractBook.DELIVERY), LIMIT, "O dado real limita a 3 encomendas de entrega aceitas ao mesmo tempo (`data/economy/contract_limits.json`).")
	var ids: Array[int] = []
	for _n: int in LIMIT + 1:
		ids.append(_post(_market_b))
	_take(ids[0])
	_take(ids[1])
	await _open_contracts()
	assert_eq([(_node(CAPACITY) as Label).visible, _label(CAPACITY)], [true, _say("capacity", {"accepted": 2, "limit": LIMIT})], "Duas de três encomendas aceitas.")
	_take(ids[2])
	await _click_row(OPEN_LIST, ids[3])
	assert_false(_is_off(ACCEPT), "A leitura é anterior ao terceiro aceite: o botão ainda está ativo.")
	await _click(_node(ACCEPT) as Control)
	assert_eq([_bridge.sent, _label(RESULT), _state_of(ids[3])], [["accept %d" % ids[3]] as Array[String], _text("economy.contract.limit"), ContractBook.STATE_OPEN], "A ponte recusa o 4º com `economy.contract.limit` e a tela mostra a frase dela.")
	assert_eq([_label(CAPACITY), _is_off(ACCEPT)], [_say("capacity", {"accepted": LIMIT, "limit": LIMIT}), true], "Refeita a leitura: 3 de 3 e \"Aceitar\" desativado.")


func test_the_click_opens_the_panel_and_only_its_abandon_sends_once_and_the_screen_shows_the_reply_and_the_row_reads_abandoned() -> void:
	var contract_id: int = _hold()
	_give_bread()
	await _open_contracts()
	await _click_row(MINE_LIST, contract_id)
	var funds: int = _funds()
	var inventory: Array[Dictionary] = _economy.peek_inventory(_actor_id).rows
	var issuer_cash: int = _economy.peek_balance(_market_a).balance
	var world: String = _host.runner.world.state_hash()
	await _click(_node(ABANDON) as Control)
	assert_eq([_confirm_open(), _bridge.sent, _state_of(contract_id), _host.runner.world.state_hash()], [true, [] as Array[String], ContractBook.STATE_ACCEPTED, world], "O clique em \"Abandonar\" da página só abre o painel: nada é enviado e o mundo é o mesmo.")
	await _click(_node(CONFIRM_YES) as Control)
	assert_eq([_bridge.sent, _confirm_open(), _label(RESULT)], [["abandon %d" % contract_id] as Array[String], false, _text("economy.contract.abandoned")], "Só o \"Abandonar\" do painel envia, UMA vez, e a tela mostra a frase de `economy.contract.abandoned`.")
	var contract: EconomyReplies.ContractQuery = _economy.peek_contract(contract_id)
	assert_eq([contract.state, contract.closed_reason], [ContractBook.STATE_FAILED, ABANDONED], "O contrato virou `failed` com o motivo `abandoned`.")
	assert_eq([_funds(), _economy.peek_inventory(_actor_id).rows], [funds, inventory], "O saldo e o inventário do jogador ficam iguais.")
	assert_eq([_economy.peek_balance(contract_id).balance, _economy.peek_balance(_market_a).balance], [0, issuer_cash + REWARD], "A custódia voltou ao emissor.")
	var shown: String = _row_of(MINE_LIST, contract_id).get_text(ContractsLayout.COLUMN_WHEN)
	assert_eq(shown, _say("state.abandoned"), "A lista mostra \"Abandonado\".")
	assert_false([_say("state.failed"), _say("state.expired")].has(shown), "E não \"Falhou\" nem \"Vencido\".")
	(_node(CONFIRM_YES) as Button).pressed.emit()
	assert_eq([_bridge.sent.size(), _missing_texts()], [1, [] as Array[String]], "Um segundo \"Abandonar\" (o painel já fechou) não reenvia, e nenhum rótulo mostra `[chave]`.")


func test_an_abandon_the_bridge_refuses_shows_the_text_of_its_own_key_and_changes_nothing() -> void:
	var contract_id: int = _hold()
	await _open_contracts()
	await _click_row(MINE_LIST, contract_id)
	await _click(_node(ABANDON) as Control)
	var elsewhere: Result = _economy.request_abandon_contract(contract_id, _actor_id)
	assert_true(elsewhere.ok, elsewhere.message)
	var world: String = _host.runner.world.state_hash()
	await _click(_node(CONFIRM_YES) as Control)
	assert_eq([_bridge.sent, _label(RESULT), _host.runner.world.state_hash()], [["abandon %d" % contract_id] as Array[String], _text("economy.contract.not_open"), world], "O contrato já foi abandonado em outro lugar depois da leitura: a ponte recusa com `not_open`, a tela mostra a frase dessa chave e nada muda.")
	assert_eq(_row_of(MINE_LIST, contract_id).get_text(ContractsLayout.COLUMN_WHEN), _say("state.abandoned"), "Refeita a leitura, a linha mostra o que a economia tem: \"Abandonado\".")


func test_back_escape_and_interact_cancel_the_panel_without_sending_and_the_screen_only_closes_on_the_next_press() -> void:
	var contract_id: int = _hold()
	var world: String = _host.runner.world.state_hash()
	await _open_contracts()
	await _click_row(MINE_LIST, contract_id)
	await _click(_node(ABANDON) as Control)
	await _click(_node(CONFIRM_BACK) as Control)
	assert_eq([_confirm_open(), _view.is_open(), _bridge.sent], [false, true, [] as Array[String]], "\"Voltar\" cancela o painel sem enviar e a tela de mercado segue aberta.")
	var closed: int = 0
	for action: StringName in [&"ui_cancel", InputActions.INTERACT]:
		await _open_contracts()
		await _click_row(MINE_LIST, contract_id)
		await _click(_node(ABANDON) as Control)
		_press(action)
		assert_eq([_confirm_open(), _view.is_open(), get_signal_emit_count(_view, "closed"), _bridge.sent, _probe.keys_seen], [false, true, closed, [] as Array[String], 0], "'%s' com o painel aberto só o cancela: a tela segue aberta e a tecla é dada como tratada." % action)
		_press(action)
		closed += 1
		assert_eq([_view.is_open(), get_signal_emit_count(_view, "closed"), _probe.keys_seen], [false, closed, 0], "'%s' com o painel já fechado fecha a tela." % action)
		_press(action)
		assert_eq([get_signal_emit_count(_view, "closed"), _probe.keys_seen], [closed, 1], "Com a tela fechada nada é tocado e a tecla ainda chega a quem a ouve depois.")
		_probe.keys_seen = 0
	assert_eq([_bridge.sent, _state_of(contract_id), _host.runner.world.state_hash()], [[] as Array[String], ContractBook.STATE_ACCEPTED, world], "Cancelar nunca enviou nem mudou o contrato.")


func test_with_the_clock_paused_a_click_before_the_next_reading_sends_nothing_and_the_panel_closes_by_itself_on_the_next_one() -> void:
	var contract_id: int = _hold()
	await _open_contracts()
	await _click_row(MINE_LIST, contract_id)
	await _click(_node(ABANDON) as Control)
	assert_true(_confirm_open(), "Pré-condição: o painel está aberto.")
	assert_true(_bridge.request_pause(true).ok)
	var world: String = _host.runner.world.state_hash()
	await _click(_node(CONFIRM_YES) as Control)
	assert_eq([_bridge.sent, _confirm_open(), _state_of(contract_id), _host.runner.world.state_hash()], [[] as Array[String], false, ContractBook.STATE_ACCEPTED, world], "A pausa veio DEPOIS da última leitura (o painel ainda estava aberto): a tela confere a pausa na hora de enviar e não envia nada.")
	assert_true(_bridge.request_pause(false).ok)
	_view.refresh()
	await _click(_node(ABANDON) as Control)
	assert_true(_confirm_open(), "Andando de novo, o painel abre.")
	assert_true(_bridge.request_pause(true).ok)
	simulate(_view, 1, MarketView.REFRESH_INTERVAL_S)
	assert_eq([_confirm_open(), _is_off(ABANDON), _bridge.sent, _state_of(contract_id)], [false, true, [] as Array[String], ContractBook.STATE_ACCEPTED], "Na leitura seguinte o painel fecha sozinho, sem enviar, e \"Abandonar\" fica desativado.")
	assert_true(_bridge.request_pause(false).ok)
	_view.refresh()
	assert_false(_is_off(ABANDON), "Andando de novo, a linha escolhida volta a poder ser abandonada.")


func test_closing_the_screen_closes_the_panel_without_sending_and_reopening_finds_it_closed() -> void:
	var contract_id: int = _hold()
	await _open_contracts()
	await _click_row(MINE_LIST, contract_id)
	await _click(_node(ABANDON) as Control)
	assert_true(_confirm_open(), "Pré-condição: o painel está aberto.")
	_view.close()
	assert_eq([_confirm_open(), _bridge.sent, _state_of(contract_id)], [false, [] as Array[String], ContractBook.STATE_ACCEPTED], "A tela fecha e leva o painel junto, sem enviar nada.")
	await _open_contracts()
	assert_eq([_confirm_open(), _bridge.sent], [false, [] as Array[String]], "Ao reabrir a tela, o painel não reaparece.")


func test_opening_switching_tabs_and_asking_do_not_change_the_state_hash_and_the_two_new_texts_exist_and_differ_from_the_others() -> void:
	var contract_id: int = _hold()
	var world: String = _host.runner.world.state_hash()
	await _open_contracts()
	await _click(_node(TAB_MARKET) as Control)
	await _click(_node(TAB_CONTRACTS) as Control)
	await _click_row(MINE_LIST, contract_id)
	await _click(_node(ABANDON) as Control)
	assert_eq(_missing_texts(), [] as Array[String], "Com o painel aberto nenhum rótulo mostra `[chave]`.")
	await _click(_node(CONFIRM_BACK) as Control)
	simulate(_view, 1, MarketView.REFRESH_INTERVAL_S)
	assert_eq([_host.runner.world.state_hash(), _bridge.sent], [world, [] as Array[String]], "Só consultas e um painel aberto e cancelado: o `state_hash` fica como estava e nenhum pedido sai.")
	var phrases: Dictionary[String, bool] = {}
	for key: String in REPLY_KEYS:
		var phrase: String = _text("economy.contract." + key, {"reward": REWARD})
		phrases[phrase] = true
		assert_true(_texts.has_key("economy.contract." + key) and not phrase.is_empty() and not phrase.contains("{"), "A chave 'economy.contract.%s' existe, tem texto e não deixa campo por preencher." % key)
	assert_eq(phrases.size(), REPLY_KEYS.size(), "Cada uma das 13 chaves tem a sua frase.")
	assert_true(_text("economy.contract.abandoned").contains("abandonada") and _text("economy.contract.limit").contains("máximo"), "Cada uma das duas frases novas diz o que a sua chave é (o abandono e o limite não se trocam).")


func test_a_closed_screen_sends_nothing_even_when_the_page_signals_are_emitted_by_code() -> void:
	var contract_id: int = _hold()
	await _open_contracts()
	await _click_row(MINE_LIST, contract_id)
	_view.close()
	var page: ContractsPage = _view._contracts
	page.abandon_requested.emit(contract_id)
	page.accept_requested.emit(contract_id)
	page.deliver_requested.emit(contract_id)
	assert_eq([_bridge.sent, _state_of(contract_id)], [[] as Array[String], ContractBook.STATE_ACCEPTED], "Tela fechada: os três sinais da página, emitidos por código, não enviam nada e o contrato segue aceito.")
