extends GutTest
## LW-107f4a, item (c): a `ContractsPage` com o botão Abandonar, a capacidade e os rótulos novos (docs/modules/presentation.md, "Encomendas por objetivo: abandonar, confirmar e capacidade"), sem janela. A página é montada de verdade (`ContractsLayout`, `ContractsViewModel`, os textos reais
## de `data/text/pt_br.json`) sobre a ponte do jogo REAL (montado como o `GameApp` monta; os contratos são postados DIRETO na economia, aceitados e abandonados pela ponte) e o relógio anda pelo `runner`. Confere: Abandonar só na linha certa, com o relógio andando, e o sinal `abandon_asked` com o ID
## da linha escolhida (só avisa: ninguém o ouve ainda); Aceitar desativado na capacidade (só dica); a linha "n de N" escondida sem limite; "Abandonado", "Falhou" e "Vencido" diferentes entre si, com a nota certa. O `failed` sem motivo e a linha `accepted` de outro ator só se obtêm trocando a resposta
## real da ponte (`EditedBridge`): nenhuma entrega produz o primeiro hoje e a ponte real nunca devolve a segunda.

const WORLD_DIR: String = "res://data/world"
const SEED: int = 107
const SETTLEMENT_A: String = "test_settlement_a"
const SETTLEMENT_B: String = "test_settlement_b"
const BREAD: String = "bread"
const MINUTES_PER_HOUR: int = 60
## Os números dos contratos do teste (os do jogo são [HIP]) e o limite do dado real (3). O tempo anda 40 minutos depois da montagem: o prazo curto (30) passa e a hora cheia seguinte (60) ainda não.
const REWARD: int = 12
const QUANTITY: int = 2
const LONG_MINUTES: int = 600
const SHORT_MINUTES: int = 30
const LATE_MINUTES: int = 40
const LIMIT: int = 3
const ABANDON: String = "ContractsAbandon"
const ACCEPT: String = "ContractsAccept"
const CONFIRM: String = "ContractsConfirm"
const CONFIRM_YES: String = "ContractsConfirmYes"
const CONFIRM_BACK: String = "ContractsConfirmBack"

var _host: SimulationHostNode
var _app: GameAppNode
var _bridge: SimBridge
var _economy: EconomyModule
var _texts: UiText
var _actor_id: int = 0
var _market_a: int = 0
var _market_b: int = 0
var _holder: Control
var _page: ContractsPage


## A ponte do jogo, com a linha do quadro trocada por `edit` (recebe a `ContractBoardRow`): as outras duas consultas do modelo vão direto à ponte real.
class EditedBridge:
	extends SimBridge

	var real: SimBridge
	var edit: Callable

	func peek_contract_board(actor_id: int, market_id: int) -> BridgePlayerContractsReplies.ContractBoardReply:
		var reply: BridgePlayerContractsReplies.ContractBoardReply = real.peek_contract_board(actor_id, market_id)
		for row: BridgePlayerContractsReplies.ContractBoardRow in reply.rows:
			edit.call(row)
		return reply

	func peek_player_economy(actor_id: int) -> BridgePlayerEconomyReplies.PlayerEconomyReply:
		return real.peek_player_economy(actor_id)

	func peek_economy_markets() -> BridgeEconomyReplies.EconomyMarketsReply:
		return real.peek_economy_markets()


func before_each() -> void:
	var loaded: UiText.LoadResult = UiText.from_file(UiText.DEFAULT_PATH)
	assert_true(loaded.result.ok, loaded.result.message)
	_texts = loaded.texts
	_host = SimulationHostNode.new()
	_app = GameAppNode.new()
	_app.bind_host(_host)
	_app.start_default_game(_host)
	_begin(_app.peek_bridge())


func after_each() -> void:
	_end()


func _end() -> void:
	if _app != null:
		_app.free()
		_app = null
	if _host.runner != null:
		_host.runner.finish()
	_host.free()


## Põe em campo o jogo `_host` (já iniciado) e a ponte dele: o jogador nasce com a conta aberta junto ao centro do mercado A (o aceite da ponte pede alcance) e o relógio fica na hora cheia.
func _begin(bridge: SimBridge) -> void:
	_bridge = bridge
	_economy = _host.economy
	_actor_id = _bridge.request_spawn_character().actor_id
	assert_true(_bridge.request_open_player_account(_actor_id).ok)
	_market_a = _economy.peek_market_of(SETTLEMENT_A).market_id
	_market_b = _economy.peek_market_of(SETTLEMENT_B).market_id
	_host.runner.run_steps((MINUTES_PER_HOUR - _bridge.peek_time().total_minutes % MINUTES_PER_HOUR) % MINUTES_PER_HOUR)
	for place: BridgeReplies.PlaceReply in _bridge.peek_places().places:
		if place.kind == Place.KIND_MARKET and place.settlement_id == SETTLEMENT_A:
			assert_true(_bridge.request_report_position(_actor_id, Vector3(place.x, place.y, place.z), 0.0).ok)


## Posta um contrato de entrega direto na economia: o mercado A paga a recompensa para a custódia, o prazo é `minutes` depois de agora e o destino é o mercado B.
func _post(minutes: int) -> int:
	var posted: EconomyReplies.PostContractResult = _economy.request_post_contract(ContractBook.DELIVERY, _market_a, REWARD, _bridge.peek_time().total_minutes + minutes, {"good_id": BREAD, "quantity": QUANTITY, "destination_id": _market_b})
	assert_true(posted.result.ok, posted.result.message)
	return posted.contract_id


## Posta um contrato e o jogador o aceita pela ponte.
func _hold(minutes: int) -> int:
	var contract_id: int = _post(minutes)
	var accepted: BridgePlayerContractsReplies.ContractActionReply = _bridge.request_contract_accept(_actor_id, contract_id)
	assert_true(accepted.result.ok, accepted.result.message)
	return contract_id


## O jogador abandona pela ponte o contrato que aceitou.
func _drop(contract_id: int) -> int:
	var abandoned: BridgePlayerContractsReplies.ContractActionReply = _bridge.request_contract_abandon(_actor_id, contract_id)
	assert_true(abandoned.result.ok, abandoned.result.message)
	return contract_id


## Monta a página sobre `bridge`, com a tela de mercado fictícia (um `Control`) como pai, e a lê já (o relógio andando).
func _show(bridge: SimBridge) -> void:
	_holder = Control.new()
	add_child_autofree(_holder)
	_page = ContractsPage.new()
	_page.setup(bridge, _texts, _actor_id, _holder)
	watch_signals(_page)
	_page.refresh(_market_a, false)


## Um quadro com um contrato de cada situação, lido 40 minutos depois da hora cheia e mostrado pela página: `held` (aceito, no prazo), `late` (aceito, com o prazo passado e ainda `accepted`), `dropped` (abandonado) e `fresh` (aberto).
func _build_board() -> Dictionary[String, int]:
	var ids: Dictionary[String, int] = {}
	ids["held"] = _hold(LONG_MINUTES)
	ids["late"] = _hold(SHORT_MINUTES)
	ids["dropped"] = _drop(_hold(LONG_MINUTES))
	ids["fresh"] = _post(LONG_MINUTES)
	_host.runner.run_steps(LATE_MINUTES)
	_show(_bridge)
	return ids


func _node(node_name: String) -> Node:
	return _holder.find_child(node_name, true, false)


func _off(button_name: String) -> bool:
	return (_node(button_name) as Button).disabled


func _say(key: String, values: Dictionary = {}) -> String:
	return _texts.get_text("ui.contracts." + key, values)


## A linha do contrato nas listas da página.
func _item(contract_id: int) -> TreeItem:
	for tree_name: String in ["ContractsOpen", "ContractsMine"]:
		for item: TreeItem in (_node(tree_name) as Tree).get_root().get_children():
			if item.get_metadata(ContractsLayout.COLUMN_LINE) == contract_id:
				return item
	assert_true(false, "O contrato %d não está nas listas." % contract_id)
	return null


## Escolhe a linha e devolve [Abandonar desativado, Aceitar desativado].
func _buttons_on(contract_id: int) -> Array[bool]:
	_item(contract_id).select(ContractsLayout.COLUMN_LINE)
	return [_off(ABANDON), _off(ACCEPT)]


## O que a linha mostra na terceira coluna e, no detalhe da escolhida, quais textos aparecem: [rótulo "Abandonado", "Falhou", "Vencido", nota do abandono, nota do prazo].
func _shown_of(contract_id: int) -> Array:
	_item(contract_id).select(ContractsLayout.COLUMN_LINE)
	var detail: String = (_node("ContractsDetail") as Label).text
	var keys: Array[String] = ["state.abandoned", "state.failed", "state.expired", "abandoned_note", "expired_note"]
	return [_item(contract_id).get_text(ContractsLayout.COLUMN_WHEN), keys.map(func(key: String) -> bool: return detail.contains(_say(key)))]


## A linha da capacidade como a página a escreve e como a chave manda escrevê-la para `accepted` aceitos.
func _shown_capacity() -> String:
	return (_node("ContractsCapacity") as Label).text


func _expected_capacity(accepted: int) -> String:
	return _say("capacity", {"accepted": accepted, "limit": LIMIT})


func _edited(edit: Callable) -> EditedBridge:
	var edited: EditedBridge = EditedBridge.new(_host, null)
	edited.real = _bridge
	edited.edit = edit
	return edited


func test_abandon_is_enabled_only_for_my_accepted_contract_in_time_with_the_clock_running_and_announces_that_contract() -> void:
	var ids: Dictionary[String, int] = _build_board()
	assert_eq([(_node(ABANDON) as Button).text, _say("abandon").is_empty()], [_say("abandon"), false], "O texto do botão vem da chave.")
	assert_eq([_buttons_on(ids["held"]), _buttons_on(ids["late"]), _buttons_on(ids["dropped"]), _buttons_on(ids["fresh"])], [[false, true], [true, true], [true, true], [true, false]], "[Abandonar, Aceitar] desativados: só o aceito no prazo se abandona, e só o aberto se aceita.")
	_buttons_on(ids["held"])
	(_node(ABANDON) as Button).pressed.emit()
	assert_signal_emitted_with_parameters(_page, "abandon_asked", [ids["held"]])
	_buttons_on(ids["fresh"])
	(_node(ABANDON) as Button).pressed.emit()
	assert_eq(get_signal_emit_count(_page, "abandon_asked"), 1, "Desativado, o botão nem avisa.")
	_buttons_on(ids["held"])
	_page.refresh(_market_a, true)
	assert_true(_off(ABANDON), "Relógio pausado: desativado.")
	_show(_edited(func(row: BridgePlayerContractsReplies.ContractBoardRow) -> void: row.is_mine = false))
	assert_eq(_buttons_on(ids["held"]), [true, true] as Array[bool], "A linha `accepted` de outro ator (`is_mine` falso) não se abandona.")


func test_accept_is_held_back_at_the_capacity_and_the_capacity_line_counts_n_of_n_without_the_expired_one() -> void:
	var ids: Dictionary[String, int] = _build_board()
	assert_eq([_shown_capacity(), _buttons_on(ids["fresh"])[1]], [_expected_capacity(1), false], "Um aceito no prazo (o vencido não conta): 1 de 3, e Aceitar habilitado.")
	_hold(LONG_MINUTES)
	_hold(LONG_MINUTES)
	_page.refresh(_market_a, false)
	assert_eq([_shown_capacity(), _buttons_on(ids["fresh"])[1]], [_expected_capacity(LIMIT), true], "Na capacidade (3 de 3), Aceitar fica desativado.")
	_drop(ids["held"])
	_page.refresh(_market_a, false)
	assert_eq([_shown_capacity(), _buttons_on(ids["fresh"])[1]], [_expected_capacity(LIMIT - 1), false], "Abandonar liberou uma vaga: 2 de 3, e Aceitar volta.")


func test_the_capacity_line_is_hidden_without_a_limit_and_accept_is_never_held_back_by_a_count() -> void:
	_end()
	var terrain: TerrainData = TerrainLoader.load_dir(WORLD_DIR).terrain
	var setup: EconomySetup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR)
	setup.definitions.contract_limits.clear()
	_host = SimulationHostNode.new()
	_host.start_new_game(SEED, terrain, [], null, 0, setup)
	_begin(SimBridge.new(_host, terrain, SettlementLoader.load_dir(WORLD_DIR, terrain).places))
	for _index: int in LIMIT + 1:
		_hold(LONG_MINUTES)
	var fresh: int = _post(LONG_MINUTES)
	_show(_bridge)
	assert_eq([(_node("ContractsCapacity") as Label).visible, _shown_capacity()], [false, ""], "Sem limite definido, a linha fica escondida e vazia.")
	assert_eq(_buttons_on(fresh)[1], false, "Quatro aceitos e Aceitar habilitado: sem limite, nenhuma conta o segura.")


func test_the_new_keys_exist_and_the_three_labels_differ_and_the_expired_note_no_longer_says_failed() -> void:
	for key: String in ["abandon", "capacity", "state.abandoned", "state.failed", "abandoned_note", "expired_note"]:
		assert_true(_texts.has_key("ui.contracts." + key), "Falta a chave 'ui.contracts.%s'." % key)
	var labels: Dictionary = {}
	for key: String in ["state.abandoned", "state.failed", "state.expired"]:
		labels[_say(key)] = true
	assert_eq(labels.size(), 3, "\"Abandonado\", \"Falhou\" e \"Vencido\" são três textos diferentes.")
	assert_false(_say("expired_note").contains(_say("state.failed")), "A nota do vencido não diz \"Falhou\" (a palavra é da falha real).")


func test_each_finished_row_shows_its_own_label_and_note_and_the_abandon_is_never_failed_or_expired() -> void:
	var ids: Dictionary[String, int] = _build_board()
	var shown: Array = [_shown_of(ids["dropped"]), _shown_of(ids["late"])]
	_show(_edited(func(row: BridgePlayerContractsReplies.ContractBoardRow) -> void: row.closed_reason = ""))
	shown.append(_shown_of(ids["dropped"]))
	assert_eq(shown, [[_say("state.abandoned"), [true, false, false, true, false]], [_say("state.expired"), [false, false, true, false, true]], [_say("state.failed"), [false, true, false, false, false]]], "Abandonado (com a nota de que não há multa), Vencido (com a nota do prazo) e Falhou (sem nota): cada um com o seu rótulo, na lista e no detalhe.")


## LW-107f4b: a ligação do painel de confirmação (`AbandonConfirm`, testado a fundo em `test_abandon_confirm.gd`) na página. Mostra a página e a lê com o relógio andando.
func _show_page() -> void:
	_show(_bridge)
	_page.set_shown(true)


## Escolhe a linha do contrato e aperta o Abandonar da página (o botão, não o sinal).
func _ask(contract_id: int) -> void:
	_buttons_on(contract_id)
	_press(ABANDON)


func _press(button_name: String) -> void:
	(_node(button_name) as Button).pressed.emit()


func _is_asking() -> bool:
	return (_node(CONFIRM) as Control).visible


func test_asking_opens_the_panel_for_the_asked_contract_and_only_its_abandonar_makes_the_page_request_it() -> void:
	var first: int = _hold(LONG_MINUTES)
	var second: int = _hold(LONG_MINUTES)
	_show_page()
	var world: String = _host.runner.world.state_hash()
	assert_false(_is_asking(), "O painel nasce fechado.")
	_ask(second)
	assert_eq([_is_asking(), get_signal_emit_count(_page, "abandon_asked"), get_signal_emit_count(_page, "abandon_requested")], [true, 1, 0], "Abandonar só abre o painel: nada é pedido ainda.")
	_press(CONFIRM_BACK)
	assert_eq([_is_asking(), get_signal_emit_count(_page, "abandon_requested")], [false, 0], "Voltar fecha o painel sem pedir nada.")
	_ask(first)
	_buttons_on(second)
	_press(CONFIRM_YES)
	assert_signal_emitted_with_parameters(_page, "abandon_requested", [first])
	assert_eq([_is_asking(), get_signal_emit_count(_page, "abandon_requested")], [false, 1], "O \"Abandonar\" do painel pede UMA vez, com o contrato PERGUNTADO (a escolha da lista mudou depois).")
	_press(CONFIRM_YES)
	assert_eq(get_signal_emit_count(_page, "abandon_requested"), 1, "Fechado, o painel não reenvia.")
	assert_eq([_economy.peek_contract(first).state, _economy.peek_contract(second).state, _host.runner.world.state_hash()], [ContractBook.STATE_ACCEPTED, ContractBook.STATE_ACCEPTED, world], "A página só pede: nenhum contrato mudou e o mundo é o mesmo (quem envia é a `MarketView`).")


func test_the_refresh_closes_the_panel_without_requesting_when_the_line_stops_being_abandonable_and_hiding_the_page_or_the_screen_does_too() -> void:
	var held: int = _hold(LONG_MINUTES)
	var short: int = _hold(SHORT_MINUTES)
	_show_page()
	_ask(held)
	_page.refresh(_market_a, false)
	assert_true(_is_asking(), "Ainda abandonável: a leitura seguinte mantém o painel.")
	_page.refresh(_market_a, true)
	assert_false(_is_asking(), "Relógio pausado: o painel fecha sozinho.")
	_page.refresh(_market_a, false)
	_ask(held)
	_drop(held)
	_page.refresh(_market_a, false)
	assert_false(_is_asking(), "Abandonado em outro lugar: fecha sozinho.")
	_ask(short)
	_host.runner.run_steps(LATE_MINUTES)
	_page.refresh(_market_a, false)
	assert_false(_is_asking(), "Prazo vencido: fecha sozinho.")
	var again: int = _hold(LONG_MINUTES)
	_page.refresh(_market_a, false)
	_ask(again)
	_page.set_shown(false)
	assert_false(_is_asking(), "A página esconde: o painel fecha.")
	_page.set_shown(true)
	_ask(again)
	_holder.visible = false
	assert_false(_is_asking(), "A tela esconde: o painel fecha.")
	_holder.visible = true
	assert_false(_is_asking(), "E não reaparece quando ela volta.")
	assert_signal_not_emitted(_page, "abandon_requested")


func test_the_page_passes_escape_and_interact_to_the_panel_only_while_it_is_open() -> void:
	var held: int = _hold(LONG_MINUTES)
	_show_page()
	var events: Array[InputEventAction] = []
	for action: StringName in [&"ui_cancel", InputActions.INTERACT]:
		var event: InputEventAction = InputEventAction.new()
		event.action = action
		event.pressed = true
		events.append(event)
	assert_eq([_page.consume_cancel(events[0]), _page.consume_cancel(events[1])], [false, false], "Sem painel aberto, a página não consome nada.")
	for event: InputEventAction in events:
		_ask(held)
		assert_eq([_page.consume_cancel(event), _is_asking()], [true, false], "Com o painel aberto, Esc e `interact` o cancelam e a página consome o evento.")
	assert_signal_not_emitted(_page, "abandon_requested")
