extends GutTest
## LW-107h: a estimativa de custo e resultado na aba "Contratos" da `MarketView`, sem janela, com o jogo REAL (`res://data`: três mercados, build de desenvolvimento para o `request_set_stock`), a ponte real, os textos reais e o postador DESLIGADO (os contratos são postados DIRETO na economia,
## `request_post_contract`, como em `test_contracts_tab.gd`; o contrato do pão de 5 por 53 é o da opção B da LW-107c3). Confere as situações do contrato de interface: (i) escassez (pão com estoque 5 nos 3 mercados): possível prejuízo e saldo insuficiente no A; (ii) pão normal no A: possível prejuízo pequeno; (iii) o mesmo
## contrato aceito e a tela no B com o pão barato: margem estimada positiva (e a faixa da margem pequena); (iv) já tem os itens: sem custo e sem aviso; (v) sem estoque: custo indisponível; (vi) linha terminada: nada; (vii) as consultas de cotação só existem com a aba Contratos visível; (viii) abrir, atualizar, pausar e
## trocar de aba não mudam o `state_hash`, os eventos nem enviam pedido. Os números vêm do oráculo (`peek_quote` da economia e o saldo), nunca fixados; as frases, das chaves reais.

const WORLD_DIR: String = "res://data/world"
const SEED: int = 107
const SETTLEMENT_A: String = "test_settlement_a"
const SETTLEMENT_B: String = "test_settlement_b"
const SETTLEMENT_C: String = "test_settlement_c"
const BREAD: String = "bread"
const REWARD: int = 53
const QUANTITY: int = 5
const BIG_QUANTITY: int = 15
const LONG_MINUTES: int = 600
const SCARCE_STOCK: int = 5
const FLOODED_STOCK: int = 100
const BUY: String = BridgePlayerEconomyReplies.SIDE_BUY
const TAB_MARKET: String = "MarketTabMarket"
const TAB_CONTRACTS: String = "MarketTabContracts"
const OPEN_LIST: String = "ContractsOpen"
const MINE_LIST: String = "ContractsMine"

var _terrain: TerrainData
var _places: Array[Place] = []
var _setup: EconomySetup
var _texts: UiText
var _center_a: Vector3
var _host: SimulationHostNode
var _bridge: QuoteSpyBridge
var _economy: EconomyModule
var _actor_id: int = 0
var _market_a: int = 0
var _market_b: int = 0
var _market_c: int = 0
var _view: MarketView


## Ponte que ANOTA cada cotação pedida e todo pedido (`request_*`) que sai: a estimativa só informa e nunca pede nada.
class QuoteSpyBridge:
	extends SimBridge

	var asked: Array[Array] = []
	var sent: Array[String] = []

	func peek_trade_quote(actor_id: int, market_id: int, good_id: String, quantity: int, side: String) -> BridgePlayerEconomyReplies.TradeQuoteReply:
		asked.append([market_id, good_id, quantity])
		return super(actor_id, market_id, good_id, quantity, side)

	func request_trade(actor_id: int, market_id: int, good_id: String, quantity: int, side: String) -> BridgePlayerEconomyReplies.PlayerTradeReply:
		sent.append("trade")
		return super(actor_id, market_id, good_id, quantity, side)

	func request_contract_accept(actor_id: int, contract_id: int) -> BridgePlayerContractsReplies.ContractActionReply:
		sent.append("accept")
		return super(actor_id, contract_id)

	func request_contract_deliver(actor_id: int, contract_id: int) -> BridgePlayerContractsReplies.ContractActionReply:
		sent.append("deliver")
		return super(actor_id, contract_id)

	func request_contract_abandon(actor_id: int, contract_id: int) -> BridgePlayerContractsReplies.ContractActionReply:
		sent.append("abandon")
		return super(actor_id, contract_id)


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
	_setup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR, true)
	assert_true(_setup.result.ok, _setup.result.message)
	var texts: UiText.LoadResult = UiText.from_file(UiText.DEFAULT_PATH)
	assert_true(texts.result.ok, texts.result.message)
	_texts = texts.texts


## Um jogo só com o personagem e a economia (sem NPCs), com o jogador junto ao mercado A, a conta aberta (saldo 100) e a tela FECHADA, ligada a uma ponte espiã.
func before_each() -> void:
	_host = SimulationHostNode.new()
	_host.start_new_game(SEED, _terrain, [], null, 0, _setup)
	_bridge = QuoteSpyBridge.new(_host, _terrain, _places)
	_economy = _host.economy
	_actor_id = _bridge.request_spawn_character().actor_id
	assert_true(_bridge.request_report_position(_actor_id, _center_a, 0.0).ok, "O jogador começa junto ao mercado A.")
	assert_true(_bridge.request_open_player_account(_actor_id).ok)
	_market_a = _economy.peek_market_of(SETTLEMENT_A).market_id
	_market_b = _economy.peek_market_of(SETTLEMENT_B).market_id
	_market_c = _economy.peek_market_of(SETTLEMENT_C).market_id
	_view = MarketView.new()
	add_child_autofree(_view)
	assert_true(_view.setup(_bridge, _texts, _actor_id, [] as Array[Node]))


func after_each() -> void:
	_host.runner.finish()
	_host.free()


func _say(key: String, values: Dictionary = {}) -> String:
	return _texts.get_text("ui.contracts." + key, values)


func _node(node_name: String) -> Node:
	return _view.find_child(node_name, true, false)


func _label(node_name: String) -> Label:
	return _node(node_name) as Label


func _press(button_name: String) -> void:
	(_node(button_name) as Button).pressed.emit()


## Abre a tela sobre o mercado `market_id` e escolhe a aba "Contratos" (a primeira linha da lista já vem escolhida).
func _open_contracts(market_id: int) -> void:
	_view.open(market_id)
	_press(TAB_CONTRACTS)


## Escolhe a linha do contrato em qualquer das duas listas.
func _select(contract_id: int) -> void:
	for list_name: String in [OPEN_LIST, MINE_LIST]:
		for item: TreeItem in (_node(list_name) as Tree).get_root().get_children():
			if item.get_metadata(ContractsLayout.COLUMN_LINE) == contract_id:
				item.select(ContractsLayout.COLUMN_LINE)


## Posta o pão de 5 por 53 do emissor A ao destino `destination` direto na economia (o postador está desligado).
func _post(destination: int, reward: int = REWARD, quantity: int = QUANTITY) -> int:
	var posted: EconomyReplies.PostContractResult = _economy.request_post_contract(ContractBook.DELIVERY, _market_a, reward, _bridge.peek_time().total_minutes + LONG_MINUTES, {"good_id": BREAD, "quantity": quantity, "destination_id": destination})
	assert_true(posted.result.ok, posted.result.message)
	return posted.contract_id


func _accept(contract_id: int) -> void:
	var accepted: Result = _economy.request_accept_contract(contract_id, _actor_id)
	assert_true(accepted.ok, accepted.message)


func _quote(market_id: int, quantity: int = QUANTITY) -> int:
	var quoted: EconomyReplies.QuoteQuery = _economy.peek_quote(_actor_id, market_id, BREAD, quantity, BUY)
	assert_true(quoted.result.ok, quoted.result.message)
	return quoted.total


## O que a tela mostra nas três linhas: o texto e se está visível (e, no aviso, o matiz).
func _shown() -> Array:
	return [_label("ContractsEstimate").text, _label("ContractsVerdict").text, _label("ContractsEstimateHint").text, [_label("ContractsEstimate").visible, _label("ContractsVerdict").visible, _label("ContractsEstimateHint").visible], _label("ContractsVerdict").self_modulate]


func _numbers(cost: int, result: int) -> String:
	return ContractsPage.FACT_SEPARATOR.join(PackedStringArray([_say("estimate_cost", {"cost": cost}), _say("estimate_result", {"result": result})]))


func test_in_the_scarcity_the_open_order_at_the_issuer_shows_the_loss_and_the_missing_funds() -> void:
	for market_id: int in [_market_a, _market_b, _market_c]:
		assert_true(_economy.request_set_stock(market_id, BREAD, SCARCE_STOCK).ok, "Pão com estoque 5 nos três mercados.")
	var funds: int = _bridge.peek_player_economy(_actor_id).funds
	var cost: int = _quote(_market_a)
	_post(_market_a)
	assert_true(cost > funds and cost > REWARD, "Com os dados de hoje, na escassez 5 pães custam mais que o saldo e que a recompensa.")
	_open_contracts(_market_a)
	var loss: String = _say("verdict_loss", {"loss": cost - REWARD}) + ContractsPage.SENTENCE_SEPARATOR + _say("verdict_funds", {"short": cost - funds})
	assert_eq(_shown(), [_numbers(cost, REWARD - cost), loss, _say("hint_estimate"), [true, true, true], ContractsLayout.DANGER_TINT], "Custo e resultado, o prejuízo com o saldo que falta e a nota; o aviso vai com o matiz de perigo.")
	assert_eq(_bridge.asked, [[_market_a, BREAD, QUANTITY]] as Array[Array], "Uma só cotação, das 5 unidades que faltam, no mercado da tela.")


func test_with_the_normal_bread_the_order_at_the_issuer_is_a_small_loss_without_a_funds_warning() -> void:
	var cost: int = _quote(_market_a)
	_post(_market_a)
	assert_true(cost > REWARD and cost <= _bridge.peek_player_economy(_actor_id).funds, "Com os dados de hoje, 5 pães custam um pouco mais que 53 no A, e o saldo cobre.")
	_open_contracts(_market_a)
	assert_eq(_shown(), [_numbers(cost, REWARD - cost), _say("verdict_loss", {"loss": cost - REWARD}), _say("hint_estimate"), [true, true, true], ContractsLayout.DANGER_TINT], "Possível prejuízo, sem a frase do saldo.")


func test_the_same_order_accepted_with_the_screen_at_a_cheaper_market_shows_the_margin_and_the_small_band() -> void:
	var contract_id: int = _post(_market_a)
	_accept(contract_id)
	assert_true(_economy.request_set_stock(_market_b, BREAD, FLOODED_STOCK).ok, "O B com muito pão: mais barato.")
	var cost: int = _quote(_market_b)
	assert_true(cost < REWARD, "No B barato as 5 unidades custam menos que a recompensa.")
	var small_margin: int = IntMath.floor_div(cost, 10)
	var small_id: int = _post(_market_a, cost + small_margin)
	_accept(small_id)
	_open_contracts(_market_b)
	_select(contract_id)
	assert_eq(_shown(), [_numbers(cost, REWARD - cost), _say("verdict_margin", {"margin": REWARD - cost}), _say("hint_estimate"), [true, true, true], Color.WHITE], "Margem estimada, com a frase dos preços e sem matiz de perigo.")
	_select(small_id)
	assert_eq(_shown(), [_numbers(cost, small_margin), _say("verdict_margin_small", {"margin": small_margin}), _say("hint_estimate"), [true, true, true], Color.WHITE], "Uma recompensa que deixa um décimo do custo (abaixo de 10% dela): margem pequena, também sem matiz.")
	_select(contract_id)
	assert_eq(_label("ContractsVerdict").text, _say("verdict_margin", {"margin": REWARD - cost}), "Voltar à primeira linha refaz o aviso e tira o matiz.")


func test_missing_funds_with_a_positive_margin_still_warns_with_the_funds_sentence_and_the_danger_tint() -> void:
	var funds: int = _bridge.peek_player_economy(_actor_id).funds
	var cost: int = _quote(_market_a, BIG_QUANTITY)
	assert_gt(cost, funds, "Com os dados de hoje, 15 pães custam mais que o saldo inicial.")
	_post(_market_a, 2 * cost, BIG_QUANTITY)
	_open_contracts(_market_a)
	var warning: String = _say("verdict_margin", {"margin": cost}) + ContractsPage.SENTENCE_SEPARATOR + _say("verdict_funds", {"short": cost - funds})
	assert_eq(_shown(), [_numbers(cost, cost), warning, _say("hint_estimate"), [true, true, true], ContractsLayout.DANGER_TINT], "A margem é positiva e grande (não é prejuízo nem margem pequena), mas o saldo não cobre a compra: a frase do saldo e o matiz de perigo vão no aviso.")


func test_a_result_of_exactly_zero_is_a_small_margin_without_the_danger_tint() -> void:
	var cost: int = _quote(_market_a)
	assert_lte(cost, _bridge.peek_player_economy(_actor_id).funds, "O saldo cobre a compra: nenhuma frase de saldo.")
	_post(_market_a, cost)
	_open_contracts(_market_a)
	assert_eq(_shown(), [_numbers(cost, 0), _say("verdict_margin_small", {"margin": 0}), _say("hint_estimate"), [true, true, true], Color.WHITE], "Recompensa igual ao custo: resultado 0 não é prejuízo (cai na margem pequena) e não leva o matiz de perigo.")


func test_already_holding_the_items_shows_no_cost_and_no_warning_and_asks_nothing() -> void:
	var contract_id: int = _post(_market_a)
	_accept(contract_id)
	assert_true(_economy.request_transfer_goods(_market_c, _actor_id, BREAD, QUANTITY).ok)
	_open_contracts(_market_a)
	assert_eq(_shown(), [_say("estimate_have"), "", "", [true, false, false], Color.WHITE], "Só a linha 'você já tem os itens': sem aviso, sem nota e sem veredito de margem.")
	assert_eq(_bridge.asked, [] as Array[Array], "Nada a comprar: nenhuma cotação.")


func test_a_market_without_enough_stock_says_the_cost_is_unavailable_never_zero() -> void:
	_post(_market_a)
	assert_true(_economy.request_set_stock(_market_a, BREAD, QUANTITY - 1).ok)
	_open_contracts(_market_a)
	assert_eq(_shown(), [_say("estimate_unknown"), "", "", [true, false, false], Color.WHITE], "Custo indisponível, sem resultado, sem aviso e sem nota.")
	assert_false(_label("ContractsEstimate").text.contains(_say("estimate_cost", {"cost": 0})), "Nunca um custo zero.")


func test_a_finished_row_shows_nothing_and_choosing_rows_moves_the_lines() -> void:
	var abandoned: int = _post(_market_a)
	_accept(abandoned)
	assert_true(_economy.request_abandon_contract(abandoned, _actor_id).ok)
	var active: int = _post(_market_a)
	_open_contracts(_market_a)
	assert_eq(_label("ContractsEstimate").visible, true, "A linha aberta e no prazo tem estimativa.")
	_select(abandoned)
	assert_eq(_shown(), ["", "", "", [false, false, false], Color.WHITE], "O abandonado não tem estimativa: as três linhas somem, vazias e sem matiz.")
	_select(active)
	assert_true(_label("ContractsVerdict").visible, "Escolher a ativa de novo traz a estimativa de volta.")
	assert_eq(_bridge.asked.size(), 1, "Só a linha ativa foi cotada, e escolher linha não consulta nada.")


func test_quotes_are_asked_only_while_the_contracts_page_is_visible_once_on_switching_and_once_per_refresh() -> void:
	_post(_market_a)
	_view.open(_market_a)
	simulate(_view, 3, MarketView.REFRESH_INTERVAL_S)
	assert_eq(_bridge.asked.size(), 0, "Na aba Mercado, mesmo com a tela atualizando sozinha, nenhuma cotação.")
	_press(TAB_CONTRACTS)
	assert_eq([_bridge.asked.size(), _label("ContractsEstimate").visible], [1, true], "Ao trocar para a aba, UMA cotação e a estimativa já aparece.")
	simulate(_view, 2, MarketView.REFRESH_INTERVAL_S)
	assert_eq(_bridge.asked.size(), 3, "Com a aba visível, uma cotação por encomenda ativa a cada atualização da tela.")
	_press(TAB_MARKET)
	simulate(_view, 3, MarketView.REFRESH_INTERVAL_S)
	assert_eq(_bridge.asked.size(), 3, "De volta ao Mercado, as cotações param.")
	_view.close()
	_view.refresh()
	assert_eq(_bridge.asked.size(), 3, "Com a tela fechada na aba Mercado, nenhuma consulta nova de cotação.")


func test_a_closed_screen_asks_no_quotes_even_with_the_contracts_tab_still_chosen() -> void:
	_post(_market_a)
	_open_contracts(_market_a)
	assert_eq(_bridge.asked.size(), 1, "Aberta na aba Contratos: a cotação da encomenda.")
	_view.close()
	_view.refresh()
	simulate(_view, 2, MarketView.REFRESH_INTERVAL_S)
	_press(TAB_CONTRACTS)
	assert_eq([_bridge.asked.size(), _node("ContractsPage").visible], [1, true], "A tela fechada deixa o `visible` da página ligado, mas nada se vê: nem a atualização nem o clique na aba pedem cotação (a guarda é `is_visible_in_tree`).")


func test_opening_refreshing_pausing_and_switching_tabs_never_change_the_state_hash_and_send_nothing() -> void:
	var contract_id: int = _post(_market_a)
	_accept(contract_id)
	_post(_market_a)
	var before: Array = [_host.runner.world.state_hash(), int(_host.runner.world.context.events.debug_summary()["pending"]), _bridge.peek_time().total_minutes]
	_open_contracts(_market_a)
	_view.refresh()
	simulate(_view, 2, MarketView.REFRESH_INTERVAL_S)
	assert_true(_bridge.request_pause(true).ok)
	_view.refresh()
	assert_true(_label("ContractsEstimate").visible, "Relógio pausado: a leitura continua e a estimativa segue na tela.")
	assert_true(_bridge.request_pause(false).ok)
	_press(TAB_MARKET)
	_press(TAB_CONTRACTS)
	_view.close()
	assert_gt(_bridge.asked.size(), 0, "Houve cotações.")
	assert_eq([_host.runner.world.state_hash(), int(_host.runner.world.context.events.debug_summary()["pending"]), _bridge.peek_time().total_minutes, _bridge.sent], before + [[] as Array[String]], "Só leituras: o `state_hash`, os eventos e o relógio ficam como estavam e nenhum pedido sai.")
