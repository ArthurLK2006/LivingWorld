class_name EconomyInspectorModel
extends RefCounted
## Modelo do painel de depuração da economia (LW-108c; contrato em docs/modules/tools.md, "Painel econômico"). Sem nó, sem ponte e sem texto: recebe as RESPOSTAS da ponte já feitas (`apply_*`; quem
## consulta a ponte é o painel, na LW-108d) e devolve o que mostrar, como LINHAS com chave de texto, valores e gravidade (`Line`): o painel troca a chave pela frase (`UiText`) e a gravidade pela cor. Valor cujo
## nome termina em `_key` é uma chave de texto de um nome (bem, receita, povoado, motivo): o painel a troca pelo nome, e o id cru continua no valor de mesmo nome sem o `_key`, para aparecer se a chave não existir.
## Resposta que FALHA apaga o que o modelo guardava daquele assunto e vira uma linha "sem dados": um número velho nunca aparece como se fosse atual. Só lê o que a ponte entrega: nada aqui escreve.

## Gravidade da linha, para a cor: `OK` (verde: conferido e certo), `PROBLEM` (vermelho: não fecha ou falhou), `WARNING` (âmbar: parado ou em falta, que não é erro de conta) e `INFO` (sem cor).
enum Severity { INFO, OK, PROBLEM, WARNING }

## Quantos problemas do `validate()` aparecem por extenso (o resto vira uma linha "e mais N"). [HIP]
const MAX_PROBLEMS_SHOWN: int = 10
## Pontos-base por cento (a eficiência dos locais vem em pontos-base, 10000 = 100%).
const BP_PER_PERCENT: int = 100
## Chaves de texto (data/text/pt_br.json, acrescentadas na LW-108c); os valores de cada uma estão em `values` da linha.
const KEY_PREFIX: String = "tools.economy_inspector."
const KEY_CONSERVATION_OK: String = KEY_PREFIX + "conservation_ok"
const KEY_CONSERVATION_BAD: String = KEY_PREFIX + "conservation_bad"
const KEY_NO_DATA_OVERVIEW: String = KEY_PREFIX + "no_data_overview"
const KEY_NO_DATA_MARKETS: String = KEY_PREFIX + "no_data_markets"
const KEY_NO_DATA_SITES: String = KEY_PREFIX + "no_data_sites"
const KEY_MONEY_OK: String = KEY_PREFIX + "money_ok"
const KEY_MONEY_BAD: String = KEY_PREFIX + "money_bad"
const KEY_GOODS_OK: String = KEY_PREFIX + "goods_ok"
const KEY_GOODS_BAD: String = KEY_PREFIX + "goods_bad"
const KEY_GOODS_BAD_ROW: String = KEY_PREFIX + "goods_bad_row"
const KEY_PROBLEMS_NONE: String = KEY_PREFIX + "problems_none"
const KEY_PROBLEMS_SOME: String = KEY_PREFIX + "problems_some"
const KEY_PROBLEM_ITEM: String = KEY_PREFIX + "problem_item"
const KEY_PROBLEMS_MORE: String = KEY_PREFIX + "problems_more"
const KEY_MONEY_TOTALS: String = KEY_PREFIX + "money_totals"
const KEY_LEDGER_HEADER: String = KEY_PREFIX + "ledger_header"
const KEY_LEDGER_ROW: String = KEY_PREFIX + "ledger_row"
const KEY_SETTLEMENT_MARKET: String = KEY_PREFIX + "settlement_market"
const KEY_SETTLEMENT_NO_MARKET: String = KEY_PREFIX + "settlement_no_market"
const KEY_MARKET_ROW: String = KEY_PREFIX + "market_row"
const KEY_MARKET_ROW_SHORTAGE: String = KEY_PREFIX + "market_row_shortage"
const KEY_SITES_HEADER: String = KEY_PREFIX + "sites_header"
const KEY_SITES_NONE: String = KEY_PREFIX + "sites_none"
const KEY_SITE_RUNNING: String = KEY_PREFIX + "site_running"
const KEY_SITE_STOPPED: String = KEY_PREFIX + "site_stopped"
const KEY_LIMIT_SCARCITY: String = KEY_PREFIX + "limit_scarcity"
## Pedaços das chaves dos nomes (existem em data/text/pt_br.json fora do painel: bens, receitas e povoados; os motivos são do painel).
const KEY_GOOD_NAME: String = "good.%s.name"
const KEY_RECIPE_NAME: String = "recipe.%s.name"
const KEY_SETTLEMENT_NAME: String = "settlement.%s.name"
const KEY_STOP_REASON: String = KEY_PREFIX + "stop.%s"
const KEY_LEDGER_REASON: String = KEY_PREFIX + "ledger.%s"

var _overview: BridgeEconomyReplies.EconomyOverviewReply
var _markets: BridgeEconomyReplies.EconomyMarketsReply
var _sites: BridgeEconomyReplies.EconomySitesReply
var _overview_code: String = ""
var _markets_code: String = ""
var _sites_code: String = ""


## Uma linha a mostrar: a chave do texto, os valores que entram nos `{nome}` dele (texto ou número) e a gravidade (a cor).
class Line:
	extends RefCounted

	var key: String
	var values: Dictionary
	var severity: EconomyInspectorModel.Severity

	func _init(line_key: String, line_values: Dictionary = {}, line_severity: EconomyInspectorModel.Severity = EconomyInspectorModel.Severity.INFO) -> void:
		key = line_key
		values = line_values
		severity = line_severity


## Guarda a visão geral; resposta que falhou apaga a anterior e guarda o código da falha.
func apply_overview(reply: BridgeEconomyReplies.EconomyOverviewReply) -> void:
	_overview = reply if reply.result.ok else null
	_overview_code = "" if reply.result.ok else reply.result.code


func apply_markets(reply: BridgeEconomyReplies.EconomyMarketsReply) -> void:
	_markets = reply if reply.result.ok else null
	_markets_code = "" if reply.result.ok else reply.result.code


func apply_sites(reply: BridgeEconomyReplies.EconomySitesReply) -> void:
	_sites = reply if reply.result.ok else null
	_sites_code = "" if reply.result.ok else reply.result.code


## Verdadeiro só se há dados e o dinheiro e os bens fecham: é o veredito da conservação (sem dados, falso).
func is_conservation_ok() -> bool:
	return _overview != null and _overview.is_money_ok and _overview.is_goods_ok


## O veredito, em destaque: a conservação (dinheiro e bens), a de cada um por extenso e os problemas do `validate()` da economia.
func verdict_lines() -> Array[Line]:
	var lines: Array[Line] = []
	if _overview == null:
		lines.append(Line.new(KEY_NO_DATA_OVERVIEW, {"code": _overview_code}, Severity.PROBLEM))
		return lines
	lines.append(Line.new(KEY_CONSERVATION_OK if is_conservation_ok() else KEY_CONSERVATION_BAD, {}, Severity.OK if is_conservation_ok() else Severity.PROBLEM))
	var money_values: Dictionary = {"circulating": _overview.money_sum, "created": _overview.money_created, "destroyed": _overview.money_destroyed, "expected": _overview.money_created - _overview.money_destroyed}
	lines.append(Line.new(KEY_MONEY_OK if _overview.is_money_ok else KEY_MONEY_BAD, money_values, Severity.OK if _overview.is_money_ok else Severity.PROBLEM))
	lines.append_array(_goods_lines())
	lines.append_array(_problem_lines())
	return lines


## O dinheiro total (em circulação, criado, destruído) e o movimento por motivo.
func money_lines() -> Array[Line]:
	var lines: Array[Line] = []
	if _overview == null:
		return lines
	lines.append(Line.new(KEY_MONEY_TOTALS, {"circulating": _overview.money_sum, "created": _overview.money_created, "destroyed": _overview.money_destroyed}))
	if _overview.ledger.is_empty():
		return lines
	lines.append(Line.new(KEY_LEDGER_HEADER))
	for row: BridgeEconomyReplies.EconomyLedgerRow in _overview.ledger:
		lines.append(Line.new(KEY_LEDGER_ROW, {"reason_key": KEY_LEDGER_REASON % row.reason, "reason": row.reason, "moved": row.moved, "created": row.created, "destroyed": row.destroyed}))
	return lines


## Por povoado: o mercado (dinheiro da conta e, de cada bem, estoque contra o alvo, preço, compra e venda, com a marca de falta) e os locais de produção. Os povoados com mercado vêm primeiro, na ordem dos
## mercados; os que só têm local de produção vêm depois, por id.
func settlement_lines() -> Array[Line]:
	var lines: Array[Line] = []
	if _markets == null:
		lines.append(Line.new(KEY_NO_DATA_MARKETS, {"code": _markets_code}, Severity.PROBLEM))
	if _sites == null:
		lines.append(Line.new(KEY_NO_DATA_SITES, {"code": _sites_code}, Severity.PROBLEM))
	for settlement_id: String in _settlement_ids():
		lines.append_array(_settlement_block(settlement_id))
	return lines


## A limitação que fica escrita na tela: as cadeias de causa de escassez dependem da LW-104, que não existe.
func limit_lines() -> Array[Line]:
	return [Line.new(KEY_LIMIT_SCARCITY)]


func _goods_lines() -> Array[Line]:
	var lines: Array[Line] = []
	if _overview.is_goods_ok:
		lines.append(Line.new(KEY_GOODS_OK, {"count": _overview.goods.size()}, Severity.OK))
		return lines
	var failing: Array[BridgeEconomyReplies.EconomyGoodsRow] = []
	for row: BridgeEconomyReplies.EconomyGoodsRow in _overview.goods:
		if not row.is_ok:
			failing.append(row)
	lines.append(Line.new(KEY_GOODS_BAD, {"count": failing.size(), "total": _overview.goods.size()}, Severity.PROBLEM))
	for row: BridgeEconomyReplies.EconomyGoodsRow in failing:
		lines.append(Line.new(KEY_GOODS_BAD_ROW, {"good_key": KEY_GOOD_NAME % row.good_id, "good": row.good_id, "in_stock": row.in_stock, "created": row.created, "destroyed": row.destroyed, "expected": row.created - row.destroyed}, Severity.PROBLEM))
	return lines


func _problem_lines() -> Array[Line]:
	var lines: Array[Line] = []
	if _overview.problems.is_empty():
		lines.append(Line.new(KEY_PROBLEMS_NONE, {}, Severity.OK))
		return lines
	lines.append(Line.new(KEY_PROBLEMS_SOME, {"count": _overview.problems.size()}, Severity.PROBLEM))
	for index: int in mini(_overview.problems.size(), MAX_PROBLEMS_SHOWN):
		lines.append(Line.new(KEY_PROBLEM_ITEM, {"text": _overview.problems[index]}, Severity.PROBLEM))
	if _overview.problems.size() > MAX_PROBLEMS_SHOWN:
		lines.append(Line.new(KEY_PROBLEMS_MORE, {"count": _overview.problems.size() - MAX_PROBLEMS_SHOWN}, Severity.PROBLEM))
	return lines


## Os povoados a mostrar: os dos mercados na ordem deles, depois os que só aparecem nos locais de produção, por id.
func _settlement_ids() -> Array[String]:
	var ids: Array[String] = []
	if _markets != null:
		for market: BridgeEconomyReplies.EconomyMarketEntry in _markets.markets:
			ids.append(market.settlement_id)
	var extra: Array[String] = []
	if _sites != null:
		for site: BridgeEconomyReplies.EconomySiteEntry in _sites.sites:
			if not ids.has(site.settlement_id) and not extra.has(site.settlement_id):
				extra.append(site.settlement_id)
	extra.sort()
	ids.append_array(extra)
	return ids


func _settlement_block(settlement_id: String) -> Array[Line]:
	var lines: Array[Line] = []
	var names: Dictionary = {"settlement_key": KEY_SETTLEMENT_NAME % settlement_id, "settlement": settlement_id}
	var market: BridgeEconomyReplies.EconomyMarketEntry = _market_of(settlement_id)
	if market == null:
		lines.append(Line.new(KEY_SETTLEMENT_NO_MARKET, names))
	else:
		var header: Dictionary = names.duplicate()
		header["cash"] = market.cash
		lines.append(Line.new(KEY_SETTLEMENT_MARKET, header))
		for row: BridgeEconomyReplies.EconomyMarketRow in market.rows:
			var values: Dictionary = {"good_key": KEY_GOOD_NAME % row.good_id, "good": row.good_id, "stock": row.stock, "target": row.target_stock, "price": row.price, "ask": row.ask, "bid": row.bid}
			lines.append(Line.new(KEY_MARKET_ROW_SHORTAGE if row.is_in_shortage else KEY_MARKET_ROW, values, Severity.WARNING if row.is_in_shortage else Severity.INFO))
	if _sites != null:
		lines.append_array(_sites_block(settlement_id, names))
	return lines


func _sites_block(settlement_id: String, names: Dictionary) -> Array[Line]:
	var lines: Array[Line] = []
	var settlement_sites: Array[BridgeEconomyReplies.EconomySiteEntry] = []
	for site: BridgeEconomyReplies.EconomySiteEntry in _sites.sites:
		if site.settlement_id == settlement_id:
			settlement_sites.append(site)
	if settlement_sites.is_empty():
		lines.append(Line.new(KEY_SITES_NONE, names))
		return lines
	lines.append(Line.new(KEY_SITES_HEADER, names))
	for site: BridgeEconomyReplies.EconomySiteEntry in settlement_sites:
		var values: Dictionary = {"recipe_key": KEY_RECIPE_NAME % site.recipe_id, "recipe": site.recipe_id, "occupation": site.occupation_id, "assigned": site.workers_assigned, "wanted": site.workers_wanted, "efficiency": IntMath.floor_div(site.efficiency_bp, BP_PER_PERCENT)}
		if site.is_running:
			lines.append(Line.new(KEY_SITE_RUNNING, values, Severity.OK))
		else:
			values["reason_key"] = KEY_STOP_REASON % site.reason.to_lower()
			values["reason"] = site.reason
			lines.append(Line.new(KEY_SITE_STOPPED, values, Severity.WARNING))
	return lines


func _market_of(settlement_id: String) -> BridgeEconomyReplies.EconomyMarketEntry:
	if _markets == null:
		return null
	for market: BridgeEconomyReplies.EconomyMarketEntry in _markets.markets:
		if market.settlement_id == settlement_id:
			return market
	return null
