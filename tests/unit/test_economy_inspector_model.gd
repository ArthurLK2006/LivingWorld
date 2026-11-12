extends GutTest
## LW-108c: o modelo do painel de depuração da economia (src/tools/economy_inspector/economy_inspector_model.gd; contrato em docs/modules/tools.md, "Painel econômico"), sem nó e com respostas FALSAS da ponte
## (os tipos de `BridgeEconomyReplies` montados à mão). Confere o veredito verde e vermelho da conservação, os bens que não fecham, os problemas do `validate()` cortados no limite, a resposta que falha apagar o que
## havia, as linhas por povoado (mercado e locais de produção, com os quatro motivos de parada), a marca de falta, a eficiência em por cento inteiro e que toda chave de texto das linhas existe em `pt_br.json`.

const SETTLEMENT_A: String = "test_settlement_a"
const SETTLEMENT_B: String = "test_settlement_b"
const SETTLEMENT_C: String = "test_settlement_c"
const STOP_REASONS: Array[String] = ["NO_WORKER", "NO_INPUT", "OUTPUT_FULL", "NO_FUNDS"]
const FAILURE_CODE: String = "BRIDGE_NO_GAME"
const PROBLEM_COUNT: int = 12

var _model: EconomyInspectorModel
var _texts: UiText


func before_all() -> void:
	var loaded: UiText.LoadResult = UiText.from_file(UiText.DEFAULT_PATH)
	assert_true(loaded.result.ok, loaded.result.message)
	_texts = loaded.texts


func before_each() -> void:
	_model = EconomyInspectorModel.new()


func _overview(money_is_ok: bool = true, goods_are_ok: bool = true, problems: Array[String] = []) -> BridgeEconomyReplies.EconomyOverviewReply:
	var reply: BridgeEconomyReplies.EconomyOverviewReply = BridgeEconomyReplies.EconomyOverviewReply.new(Result.success())
	reply.money_sum = 1000 if money_is_ok else 1010
	reply.money_created = 1100
	reply.money_destroyed = 100
	reply.is_money_ok = money_is_ok
	reply.is_goods_ok = goods_are_ok
	for good_id: String in ["bread", "grain"]:
		var row: BridgeEconomyReplies.EconomyGoodsRow = BridgeEconomyReplies.EconomyGoodsRow.new()
		row.good_id = good_id
		row.in_stock = 50
		row.created = 60
		row.destroyed = 10
		row.is_ok = goods_are_ok or good_id == "grain"
		reply.goods.append(row)
	for reason: String in ["game_start", "salary"]:
		var line: BridgeEconomyReplies.EconomyLedgerRow = BridgeEconomyReplies.EconomyLedgerRow.new()
		line.reason = reason
		line.moved = 5
		line.created = 1100 if reason == "game_start" else 0
		line.destroyed = 0
		reply.ledger.append(line)
	reply.problems.assign(problems)
	return reply


func _market(market_id: int, settlement_id: String, shortage_good: String = "") -> BridgeEconomyReplies.EconomyMarketEntry:
	var entry: BridgeEconomyReplies.EconomyMarketEntry = BridgeEconomyReplies.EconomyMarketEntry.new()
	entry.market_id = market_id
	entry.settlement_id = settlement_id
	entry.cash = 2000 + market_id
	for good_id: String in ["bread", "grain"]:
		var row: BridgeEconomyReplies.EconomyMarketRow = BridgeEconomyReplies.EconomyMarketRow.new()
		row.good_id = good_id
		row.stock = 40
		row.target_stock = 100
		row.price = 10
		row.ask = 11
		row.bid = 9
		row.is_in_shortage = good_id == shortage_good
		entry.rows.append(row)
	return entry


func _site(site_id: int, settlement_id: String, reason: String = "", efficiency_bp: int = 10000) -> BridgeEconomyReplies.EconomySiteEntry:
	var entry: BridgeEconomyReplies.EconomySiteEntry = BridgeEconomyReplies.EconomySiteEntry.new()
	entry.site_id = site_id
	entry.settlement_id = settlement_id
	entry.place_id = "place_%d" % site_id
	entry.recipe_id = "grow_grain"
	entry.occupation_id = "farmer"
	entry.wage_per_hour = 2
	entry.workers_wanted = 4
	entry.workers_assigned = 3
	entry.is_running = reason.is_empty()
	entry.reason = reason
	entry.efficiency_bp = efficiency_bp
	return entry


func _markets_reply(markets: Array[BridgeEconomyReplies.EconomyMarketEntry]) -> BridgeEconomyReplies.EconomyMarketsReply:
	return BridgeEconomyReplies.EconomyMarketsReply.new(Result.success(), markets)


func _sites_reply(sites: Array[BridgeEconomyReplies.EconomySiteEntry]) -> BridgeEconomyReplies.EconomySitesReply:
	return BridgeEconomyReplies.EconomySitesReply.new(Result.success(), sites)


func _keys(lines: Array[EconomyInspectorModel.Line]) -> Array[String]:
	var keys: Array[String] = []
	for line: EconomyInspectorModel.Line in lines:
		keys.append(line.key)
	return keys


func _failure() -> Result:
	return Result.failure(FAILURE_CODE, "sem jogo")


func test_a_healthy_economy_gives_a_green_conservation_verdict() -> void:
	_model.apply_overview(_overview())
	assert_true(_model.is_conservation_ok())
	var lines: Array[EconomyInspectorModel.Line] = _model.verdict_lines()
	assert_eq(_keys(lines), [EconomyInspectorModel.KEY_CONSERVATION_OK, EconomyInspectorModel.KEY_MONEY_OK, EconomyInspectorModel.KEY_GOODS_OK, EconomyInspectorModel.KEY_PROBLEMS_NONE] as Array[String])
	for line: EconomyInspectorModel.Line in lines:
		assert_eq(line.severity, EconomyInspectorModel.Severity.OK, "%s é verde." % line.key)
	assert_eq(lines[1].values, {"circulating": 1000, "created": 1100, "destroyed": 100, "expected": 1000}, "O dinheiro mostra soma, criado, destruído e o esperado.")
	assert_eq(lines[2].values, {"count": 2}, "Os dois bens com movimento.")


func test_money_that_does_not_close_turns_the_verdict_red_and_shows_what_was_expected() -> void:
	_model.apply_overview(_overview(false))
	assert_false(_model.is_conservation_ok())
	var lines: Array[EconomyInspectorModel.Line] = _model.verdict_lines()
	assert_eq(lines[0].key, EconomyInspectorModel.KEY_CONSERVATION_BAD)
	assert_eq(lines[0].severity, EconomyInspectorModel.Severity.PROBLEM)
	assert_eq(lines[1].key, EconomyInspectorModel.KEY_MONEY_BAD)
	assert_eq(lines[1].severity, EconomyInspectorModel.Severity.PROBLEM)
	assert_eq(lines[1].values["circulating"], 1010)
	assert_eq(lines[1].values["expected"], 1000, "O esperado é o criado menos o destruído.")
	assert_eq(lines[2].key, EconomyInspectorModel.KEY_GOODS_OK, "Os bens seguem verdes: só o dinheiro falhou.")


func test_goods_that_do_not_close_turn_the_verdict_red_and_list_each_failing_good() -> void:
	_model.apply_overview(_overview(true, false))
	assert_false(_model.is_conservation_ok())
	var lines: Array[EconomyInspectorModel.Line] = _model.verdict_lines()
	assert_eq(_keys(lines), [EconomyInspectorModel.KEY_CONSERVATION_BAD, EconomyInspectorModel.KEY_MONEY_OK, EconomyInspectorModel.KEY_GOODS_BAD, EconomyInspectorModel.KEY_GOODS_BAD_ROW, EconomyInspectorModel.KEY_PROBLEMS_NONE] as Array[String], "Só o pão não fecha (o grão fecha) e ganha a sua linha.")
	assert_eq(lines[2].values, {"count": 1, "total": 2})
	assert_eq(lines[3].values["good"], "bread")
	assert_eq(lines[3].values["expected"], 50, "Criado 60 menos destruído 10.")
	assert_eq(lines[3].severity, EconomyInspectorModel.Severity.PROBLEM)


func test_the_problems_of_validate_are_listed_and_cut_at_the_limit() -> void:
	var problems: Array[String] = []
	for index: int in PROBLEM_COUNT:
		problems.append("problema %d" % index)
	_model.apply_overview(_overview(true, true, problems))
	var lines: Array[EconomyInspectorModel.Line] = _model.verdict_lines()
	var some: EconomyInspectorModel.Line = lines[lines.size() - EconomyInspectorModel.MAX_PROBLEMS_SHOWN - 2]
	assert_eq([some.key, some.values], [EconomyInspectorModel.KEY_PROBLEMS_SOME, {"count": PROBLEM_COUNT}])
	assert_eq(some.severity, EconomyInspectorModel.Severity.PROBLEM)
	assert_eq(lines[lines.size() - 1].key, EconomyInspectorModel.KEY_PROBLEMS_MORE)
	assert_eq(lines[lines.size() - 1].values, {"count": PROBLEM_COUNT - EconomyInspectorModel.MAX_PROBLEMS_SHOWN}, "O resto vira 'e mais N'.")
	assert_eq(lines[lines.size() - 2].values, {"text": "problema %d" % (EconomyInspectorModel.MAX_PROBLEMS_SHOWN - 1)}, "A última mensagem por extenso é a do limite.")
	assert_true(_model.is_conservation_ok(), "Problema do validate não muda o veredito da conservação (ele tem a linha dele).")


func test_a_failed_reply_erases_what_was_known_and_shows_a_no_data_line() -> void:
	_model.apply_overview(_overview())
	_model.apply_markets(_markets_reply([_market(1, SETTLEMENT_A)]))
	_model.apply_sites(_sites_reply([_site(1, SETTLEMENT_A)]))
	assert_true(_model.is_conservation_ok())
	_model.apply_overview(BridgeEconomyReplies.EconomyOverviewReply.new(_failure()))
	assert_false(_model.is_conservation_ok(), "Sem dados nunca fica verde.")
	var verdict: Array[EconomyInspectorModel.Line] = _model.verdict_lines()
	assert_eq(_keys(verdict), [EconomyInspectorModel.KEY_NO_DATA_OVERVIEW] as Array[String], "O número velho some.")
	assert_eq(verdict[0].values, {"code": FAILURE_CODE})
	assert_eq(verdict[0].severity, EconomyInspectorModel.Severity.PROBLEM)
	assert_eq(_model.money_lines().size(), 0)
	_model.apply_markets(BridgeEconomyReplies.EconomyMarketsReply.new(_failure()))
	_model.apply_sites(BridgeEconomyReplies.EconomySitesReply.new(_failure()))
	assert_eq(_keys(_model.settlement_lines()), [EconomyInspectorModel.KEY_NO_DATA_MARKETS, EconomyInspectorModel.KEY_NO_DATA_SITES] as Array[String], "Mercados e locais também somem e dizem por quê.")
	_model.apply_overview(_overview())
	assert_true(_model.is_conservation_ok(), "Uma resposta boa depois da falha volta a valer.")


func test_the_money_lines_show_the_totals_and_one_row_per_ledger_reason() -> void:
	_model.apply_overview(_overview())
	var lines: Array[EconomyInspectorModel.Line] = _model.money_lines()
	assert_eq(_keys(lines), [EconomyInspectorModel.KEY_MONEY_TOTALS, EconomyInspectorModel.KEY_LEDGER_HEADER, EconomyInspectorModel.KEY_LEDGER_ROW, EconomyInspectorModel.KEY_LEDGER_ROW] as Array[String])
	assert_eq(lines[0].values, {"circulating": 1000, "created": 1100, "destroyed": 100})
	assert_eq(lines[2].values["reason"], "game_start")
	assert_eq(lines[2].values["reason_key"], "tools.economy_inspector.ledger.game_start")
	assert_eq([lines[2].values["moved"], lines[2].values["created"], lines[2].values["destroyed"]], [5, 1100, 0])
	var without_ledger: BridgeEconomyReplies.EconomyOverviewReply = _overview()
	without_ledger.ledger.clear()
	_model.apply_overview(without_ledger)
	assert_eq(_keys(_model.money_lines()), [EconomyInspectorModel.KEY_MONEY_TOTALS] as Array[String], "Sem movimento, só os totais.")


func test_each_settlement_gets_its_market_rows_and_its_sites_with_the_stop_reason() -> void:
	_model.apply_markets(_markets_reply([_market(1, SETTLEMENT_A)]))
	var sites: Array[BridgeEconomyReplies.EconomySiteEntry] = [_site(1, SETTLEMENT_A)]
	for index: int in STOP_REASONS.size():
		sites.append(_site(index + 2, SETTLEMENT_A, STOP_REASONS[index]))
	_model.apply_sites(_sites_reply(sites))
	var lines: Array[EconomyInspectorModel.Line] = _model.settlement_lines()
	assert_eq(_keys(lines), [EconomyInspectorModel.KEY_SETTLEMENT_MARKET, EconomyInspectorModel.KEY_MARKET_ROW, EconomyInspectorModel.KEY_MARKET_ROW, EconomyInspectorModel.KEY_SITES_HEADER, EconomyInspectorModel.KEY_SITE_RUNNING, EconomyInspectorModel.KEY_SITE_STOPPED, EconomyInspectorModel.KEY_SITE_STOPPED, EconomyInspectorModel.KEY_SITE_STOPPED, EconomyInspectorModel.KEY_SITE_STOPPED] as Array[String])
	assert_eq(lines[0].values, {"settlement_key": "settlement.test_settlement_a.name", "settlement": SETTLEMENT_A, "cash": 2001})
	assert_eq(lines[1].values, {"good_key": "good.bread.name", "good": "bread", "stock": 40, "target": 100, "price": 10, "ask": 11, "bid": 9})
	assert_eq(lines[1].severity, EconomyInspectorModel.Severity.INFO)
	assert_eq(lines[4].values, {"recipe_key": "recipe.grow_grain.name", "recipe": "grow_grain", "occupation": "farmer", "assigned": 3, "wanted": 4, "efficiency": 100})
	assert_eq(lines[4].severity, EconomyInspectorModel.Severity.OK, "Rodando é verde.")
	for index: int in STOP_REASONS.size():
		var stopped: EconomyInspectorModel.Line = lines[5 + index]
		assert_eq(stopped.severity, EconomyInspectorModel.Severity.WARNING, "Parado é âmbar, não vermelho: não é erro de conta.")
		assert_eq([stopped.values["reason"], stopped.values["reason_key"]], [STOP_REASONS[index], "tools.economy_inspector.stop.%s" % STOP_REASONS[index].to_lower()], "O motivo '%s' tem a sua chave." % STOP_REASONS[index])


func test_a_good_in_shortage_is_marked_with_its_own_line() -> void:
	_model.apply_markets(_markets_reply([_market(1, SETTLEMENT_A, "grain")]))
	_model.apply_sites(_sites_reply([] as Array[BridgeEconomyReplies.EconomySiteEntry]))
	var lines: Array[EconomyInspectorModel.Line] = _model.settlement_lines()
	assert_eq(_keys(lines), [EconomyInspectorModel.KEY_SETTLEMENT_MARKET, EconomyInspectorModel.KEY_MARKET_ROW, EconomyInspectorModel.KEY_MARKET_ROW_SHORTAGE, EconomyInspectorModel.KEY_SITES_NONE] as Array[String], "O pão normal, o grão em falta, e o povoado sem locais de produção diz isso.")
	assert_eq(lines[2].severity, EconomyInspectorModel.Severity.WARNING)
	assert_eq(lines[2].values["good"], "grain")


func test_settlements_with_a_market_come_first_then_the_ones_with_only_sites_by_id() -> void:
	_model.apply_markets(_markets_reply([_market(2, SETTLEMENT_B), _market(5, SETTLEMENT_A)]))
	_model.apply_sites(_sites_reply([_site(1, SETTLEMENT_C), _site(2, SETTLEMENT_A), _site(3, "a_settlement_without_market")]))
	var headers: Array[String] = []
	for line: EconomyInspectorModel.Line in _model.settlement_lines():
		if line.key == EconomyInspectorModel.KEY_SETTLEMENT_MARKET or line.key == EconomyInspectorModel.KEY_SETTLEMENT_NO_MARKET:
			headers.append("%s:%s" % [line.key.trim_prefix(EconomyInspectorModel.KEY_PREFIX), line.values["settlement"]])
	assert_eq(headers, ["settlement_market:test_settlement_b", "settlement_market:test_settlement_a", "settlement_no_market:a_settlement_without_market", "settlement_no_market:test_settlement_c"] as Array[String], "Mercados na ordem deles; depois, sem mercado, por id.")


func test_the_efficiency_shows_in_whole_percent_rounded_down() -> void:
	_model.apply_markets(_markets_reply([_market(1, SETTLEMENT_A)]))
	_model.apply_sites(_sites_reply([_site(1, SETTLEMENT_A, "", 8765), _site(2, SETTLEMENT_A, "", 99), _site(3, SETTLEMENT_A, "", 0)]))
	var efficiencies: Array[int] = []
	for line: EconomyInspectorModel.Line in _model.settlement_lines():
		if line.key == EconomyInspectorModel.KEY_SITE_RUNNING:
			efficiencies.append(line.values["efficiency"])
	assert_eq(efficiencies, [87, 0, 0] as Array[int], "8765 pontos-base são 87%; 99 são 0%; 0 é 0%.")


func test_the_scarcity_limit_line_is_always_there() -> void:
	assert_eq(_keys(_model.limit_lines()), [EconomyInspectorModel.KEY_LIMIT_SCARCITY] as Array[String])
	assert_eq(_model.verdict_lines().size(), 1, "Sem nenhuma resposta ainda, o veredito só diz que faltam dados.")
	assert_eq(_model.settlement_lines().size(), 2, "E os povoados dizem que faltam os mercados e os locais.")


func test_every_text_key_of_every_line_exists_and_every_name_key_resolves() -> void:
	var markets: Array[BridgeEconomyReplies.EconomyMarketEntry] = [_market(1, SETTLEMENT_A, "grain")]
	var sites: Array[BridgeEconomyReplies.EconomySiteEntry] = [_site(1, SETTLEMENT_A), _site(2, SETTLEMENT_C)]
	for reason: String in STOP_REASONS:
		sites.append(_site(10, SETTLEMENT_A, reason))
	var many_problems: Array[String] = []
	many_problems.resize(PROBLEM_COUNT)
	many_problems.fill("p")
	_model.apply_overview(_overview(false, false, many_problems))
	_model.apply_markets(_markets_reply(markets))
	_model.apply_sites(_sites_reply(sites))
	var lines: Array[EconomyInspectorModel.Line] = _model.verdict_lines()
	lines.append_array(_model.money_lines())
	lines.append_array(_model.settlement_lines())
	lines.append_array(_model.limit_lines())
	assert_gt(lines.size(), 20)
	for line: EconomyInspectorModel.Line in lines:
		assert_true(_texts.has_key(line.key), "A chave '%s' existe em pt_br.json." % line.key)
		for value_name: Variant in line.values:
			if str(value_name).ends_with("_key"):
				assert_true(_texts.has_key(str(line.values[value_name])), "O nome '%s' da linha '%s' tem frase." % [line.values[value_name], line.key])
