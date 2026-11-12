extends GutTest
## LW-108d: os nós do painel de depuração da economia (src/tools/economy_inspector/economy_inspector_panel.gd; contrato em docs/modules/tools.md, "Painel econômico"), sem janela e com o jogo real
## (`GameApp.start_default_game`: 3 mercados e 14 locais de produção) e os textos reais de data/text/pt_br.json. Confere que o painel começa fechado, mostra a conferência da conservação em verde, o dinheiro,
## cada povoado com o preço e o estoque de cada bem batendo com as CONSULTAS DA PRÓPRIA ECONOMIA, os 14 locais com a equipe e o estado, o vermelho quando a conservação falha (com uma ponte falsa), a
## limitação das causas de escassez, que o painel acompanha o jogo pelo ritmo, e que nenhuma chave de texto fica sem frase.

const SETTLEMENTS: Array[String] = ["test_settlement_a", "test_settlement_b", "test_settlement_c"]
const SETTLEMENT_NAMES: Array[String] = ["Povoado A", "Povoado B", "Povoado C"]
const SITE_COUNT: int = 14
const GOOD_COUNT: int = 10
const WARMUP_STEPS: int = 120
const ONE_DAY_AND_MORE_STEPS: int = 1500
var _green_tag: String = "[color=#%s]" % EconomyInspectorPanel.COLOR_OK.to_html(false)
var _red_tag: String = "[color=#%s]" % EconomyInspectorPanel.COLOR_PROBLEM.to_html(false)
const STOCK_TO_SET: int = 7

var _texts: UiText
var _host: SimulationHostNode
var _app: GameAppNode
var _bridge: SimBridge
var _panel: EconomyInspectorPanel


## Ponte que mente: devolve uma visão geral em que o dinheiro NÃO fecha, para o painel mostrar o vermelho (o jogo real é são e não deixa fabricar o erro).
class BrokenMoneyBridge:
	extends SimBridge

	func peek_economy_overview() -> BridgeEconomyReplies.EconomyOverviewReply:
		var reply: BridgeEconomyReplies.EconomyOverviewReply = BridgeEconomyReplies.EconomyOverviewReply.new(Result.success())
		reply.money_sum = 1010
		reply.money_created = 1100
		reply.money_destroyed = 100
		reply.is_money_ok = false
		reply.problems.append("[mercado 3] o saldo não fecha")
		return reply

	func peek_economy_markets() -> BridgeEconomyReplies.EconomyMarketsReply:
		return BridgeEconomyReplies.EconomyMarketsReply.new(Result.success())

	func peek_economy_sites() -> BridgeEconomyReplies.EconomySitesReply:
		return BridgeEconomyReplies.EconomySitesReply.new(Result.success())


func before_all() -> void:
	var loaded: UiText.LoadResult = UiText.from_file(UiText.DEFAULT_PATH)
	assert_true(loaded.result.ok, loaded.result.message)
	_texts = loaded.texts


func before_each() -> void:
	_host = SimulationHostNode.new()
	_app = GameAppNode.new()
	_app.bind_host(_host)
	_app.start_default_game(_host)
	_bridge = _app.peek_bridge()
	_panel = EconomyInspectorPanel.new()
	add_child_autofree(_panel)
	assert_true(_panel.setup(_bridge, _texts))


func after_each() -> void:
	_app.free()
	if _host.runner != null:
		_host.runner.finish()
	_host.free()


func _step(count: int) -> void:
	for _index: int in count:
		_host.runner.step_once()


func _count_of(text: String, part: String) -> int:
	return text.count(part)


func test_the_panel_starts_closed_opens_and_closes_and_refuses_null_parts() -> void:
	assert_false(_panel.is_open(), "Começa fechado.")
	_panel.open()
	assert_true(_panel.is_open())
	_panel.toggle()
	assert_false(_panel.is_open())
	_panel.toggle()
	_panel.close()
	assert_false(_panel.is_open())
	assert_false(autofree(EconomyInspectorPanel.new()).setup(null, _texts))
	assert_false(autofree(EconomyInspectorPanel.new()).setup(_bridge, null))
	assert_push_error_count(2)
	var unbound: EconomyInspectorPanel = autofree(EconomyInspectorPanel.new())
	unbound.open()
	assert_false(unbound.is_open(), "Sem ponte, abrir não faz nada.")


func test_a_healthy_game_shows_a_green_conservation_the_money_and_the_limitation() -> void:
	_panel.open()
	var text: String = _panel.plain_text()
	var marked: String = _panel.marked_text()
	assert_string_contains(text, "CONSERVAÇÃO: OK")
	assert_string_contains(marked, "%s[b]CONSERVAÇÃO: OK" % _green_tag, "A conferência sai em verde e em negrito.")
	assert_false(marked.contains(_red_tag), "Jogo são: nada em vermelho.")
	var money: EconomyReplies.ConservationQuery = _host.economy.peek_conservation()
	assert_string_contains(text, "Em circulação: %d · Criado: %d · Destruído: %d" % [money.sum, money.created, money.destroyed])
	assert_string_contains(text, "nenhum problema")
	assert_string_contains(text, "LW-104", "A limitação das causas de escassez fica escrita na tela.")
	assert_string_contains(text, "dinheiro inicial do jogo", "O motivo do livro-razão vem em português.")


func test_each_settlement_shows_its_market_with_the_price_and_stock_of_every_good_as_the_economy_says() -> void:
	_step(WARMUP_STEPS)
	_panel.open()
	var text: String = _panel.plain_text()
	for settlement_name: String in SETTLEMENT_NAMES:
		assert_string_contains(text, "%s · mercado com " % settlement_name)
	var rows_checked: int = 0
	for settlement_id: String in SETTLEMENTS:
		var market: EconomyReplies.MarketQuery = _host.economy.peek_market_of(settlement_id)
		assert_true(market.result.ok, market.result.message)
		assert_string_contains(text, "mercado com %d de dinheiro" % _host.economy.peek_balance(market.market_id).balance)
		assert_eq(market.rows.size(), GOOD_COUNT)
		for row: Dictionary in market.rows:
			var expected: String = "estoque %d de %d · preço %d (comprar %d, vender %d)" % [row["stock"], row["target_stock"], row["price"], row["ask"], row["bid"]]
			assert_string_contains(text, expected, "%s, %s: os números da tela são os da economia." % [settlement_id, row["good_id"]])
			rows_checked += 1
	assert_eq(rows_checked, SETTLEMENTS.size() * GOOD_COUNT, "Os 30 bens dos 3 mercados conferidos.")
	assert_string_contains(text, "Grão: estoque", "Os nomes dos bens saem em português, não em id.")


func test_the_fourteen_production_sites_show_the_team_and_either_running_or_the_stop_reason() -> void:
	_step(WARMUP_STEPS)
	_panel.open()
	var text: String = _panel.plain_text()
	assert_eq(_count_of(text, "equipe "), SITE_COUNT, "Uma linha por local de produção.")
	var running: int = 0
	var stopped: int = 0
	for settlement_id: String in SETTLEMENTS:
		for site: EconomyReplies.SiteQuery in _host.economy.peek_sites_of(settlement_id).sites:
			assert_string_contains(text, "equipe %d de %d" % [site.workers_assigned, site.workers_wanted])
			if site.running:
				running += 1
			else:
				stopped += 1
	assert_eq(_count_of(text, "rodando · eficiência"), running, "Os que rodam dizem a eficiência.")
	assert_eq(_count_of(text, "PARADO: "), stopped, "Os parados dizem o motivo em português.")
	assert_eq(running + stopped, SITE_COUNT)
	for raw_reason: String in ["NO_WORKER", "NO_INPUT", "OUTPUT_FULL", "NO_FUNDS"]:
		assert_false(text.contains(raw_reason), "O id cru '%s' não aparece: tem texto." % raw_reason)


func test_money_that_does_not_close_shows_red_with_the_word_error_and_escapes_the_brackets() -> void:
	var broken: BrokenMoneyBridge = BrokenMoneyBridge.new(null, null)
	var panel: EconomyInspectorPanel = EconomyInspectorPanel.new()
	add_child_autofree(panel)
	assert_true(panel.setup(broken, _texts))
	panel.open()
	var text: String = panel.plain_text()
	assert_string_contains(text, "CONSERVAÇÃO: ERRO", "A palavra, além da cor.")
	assert_string_contains(panel.marked_text(), "%s[b]CONSERVAÇÃO: ERRO" % _red_tag)
	assert_string_contains(text, "a soma das contas é 1010, mas o criado (1100) menos o destruído (100) dá 1000")
	assert_string_contains(text, "[mercado 3] o saldo não fecha", "O colchete da mensagem aparece como colchete, sem virar marca de cor.")
	assert_false(panel.model().is_conservation_ok())


func test_a_bridge_that_fails_shows_the_no_data_lines_in_red() -> void:
	var without_game: SimBridge = SimBridge.new(null, null)
	var panel: EconomyInspectorPanel = EconomyInspectorPanel.new()
	add_child_autofree(panel)
	assert_true(panel.setup(without_game, _texts))
	panel.open()
	assert_string_contains(panel.plain_text(), "ERRO: sem dados da conferência da economia (falha: BRIDGE_NO_GAME)")
	assert_string_contains(panel.plain_text(), "sem dados dos mercados")
	assert_string_contains(panel.plain_text(), "sem dados dos locais de produção")
	assert_false(panel.model().is_conservation_ok(), "Sem dados nunca é verde.")


func test_the_panel_follows_the_game_by_the_refresh_pace_and_not_faster() -> void:
	_panel.open()
	var market_id: int = _host.economy.peek_market_of(SETTLEMENTS[0]).market_id
	assert_true(_host.economy.request_set_stock(market_id, "bread", STOCK_TO_SET).ok, "O comando de depuração da economia existe no teste (build de desenvolvimento).")
	_panel._process(EconomyInspectorPanel.REFRESH_INTERVAL_S / 4.0)
	assert_false(_panel.plain_text().contains("Pão: estoque %d de" % STOCK_TO_SET), "Antes do intervalo o painel ainda mostra o de antes.")
	_panel._process(EconomyInspectorPanel.REFRESH_INTERVAL_S)
	assert_string_contains(_panel.plain_text(), "Pão: estoque %d de" % STOCK_TO_SET, "Depois do intervalo, o número novo.")
	_step(ONE_DAY_AND_MORE_STEPS)
	_panel.refresh()
	var money: EconomyReplies.ConservationQuery = _host.economy.peek_conservation()
	assert_string_contains(_panel.plain_text(), "Em circulação: %d · Criado: %d · Destruído: %d" % [money.sum, money.created, money.destroyed], "Depois de um dia o dinheiro da tela é o da economia.")
	assert_string_contains(_panel.plain_text(), "CONSERVAÇÃO: OK", "E a conservação continua fechando.")


func test_every_text_key_of_the_panel_exists_and_nothing_is_left_unresolved_on_screen() -> void:
	for key: String in [EconomyInspectorPanel.KEY_TITLE, EconomyInspectorPanel.KEY_HINT, EconomyInspectorPanel.KEY_SECTION_VERDICT, EconomyInspectorPanel.KEY_SECTION_MONEY, EconomyInspectorPanel.KEY_SECTION_SETTLEMENTS, EconomyInspectorPanel.KEY_SECTION_LIMITS]:
		assert_true(_texts.has_key(key), "A chave '%s' existe em pt_br.json." % key)
	_step(WARMUP_STEPS)
	_panel.open()
	var text: String = _panel.plain_text()
	assert_false(text.contains("{"), "Sem valor por trocar.")
	assert_false(text.contains("[tools."), "Sem chave sem frase.")
	assert_false(text.contains("[good.") or text.contains("[recipe.") or text.contains("[settlement."), "Sem nome sem frase.")
	assert_false(text.contains("test_settlement_"), "Nenhum povoado aparece como id cru.")
	assert_false(text.contains("grow_grain"), "Nenhuma receita aparece como id cru.")
