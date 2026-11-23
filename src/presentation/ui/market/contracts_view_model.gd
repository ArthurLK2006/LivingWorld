class_name ContractsViewModel
extends RefCounted
## Os DADOS da aba "Contratos" da tela de mercado do jogador (LW-107d; contrato em docs/modules/presentation.md, "Quadro de contratos (LW-107)"). Sem nó e sem texto: só números, códigos e ids, que a `MarketView` troca
## por frases e desenha (LW-107e). `refresh` lê a ponte (`peek_contract_board`, `peek_player_economy` e `peek_economy_markets`) e COPIA o que precisa: nenhuma resposta da ponte é guardada. Só lê e não tem regra de jogo:
## não calcula recompensa, custo nem regra de prazo, só SUBTRAI e COMPARA com o `now` que veio na MESMA resposta da ponte (nunca outro relógio; o modelo não lê relógio nenhum). Falhou? O modelo fica VAZIO e inválido, com o
## código da recusa em `error_code()`: um número da leitura anterior nunca aparece como se fosse atual. Quem decide QUANDO atualizar é a tela; ela mostra `ui.contracts.unavailable` quando o modelo é inválido.
## LW-107f4a (docs/modules/presentation.md, "Encomendas por objetivo: abandonar, confirmar e capacidade"): a linha ganha `closed_reason` e `can_abandon`, o `display_state` distingue o abandono, e o modelo expõe `accepted_count()` e `capacity()` (o `accepted_limit` da ponte).
## LW-107h (custo e resultado estimados, contrato de interface da aba Contratos): `refresh_estimates` e `estimate_of` dão, por linha ativa, o custo estimado de COMPRAR o que falta no mercado mostrado e o resultado (recompensa menos custo). O custo vem da economia, pela ponte (`peek_trade_quote`, a cotação real das unidades que faltam, nunca `ask x N`): o modelo só SUBTRAI e COMPARA e não promete nada.

## Os estados do contrato com o texto da ponte (o da economia; um teste confere). Em `Row.display_state` são os estados que a tela MOSTRA: `expired` é o "Vencido". `STATE_ABANDONED` só existe em `display_state` (LW-107f4a): é o
## `failed` cujo `closed_reason` é `REASON_ABANDONED` (o texto da economia); o `failed` sem motivo (a falha real) segue `failed`.
const STATE_OPEN: String = "open"
const STATE_ACCEPTED: String = "accepted"
const STATE_COMPLETED: String = "completed"
const STATE_EXPIRED: String = "expired"
const STATE_FAILED: String = "failed"
const STATE_ABANDONED: String = "abandoned"
const REASON_ABANDONED: String = "abandoned"
## Os tipos da estimativa de uma linha (LW-107h): `NONE` (linha terminada, vencida, sem leitura ou sem estimativa pedida: nenhum número), `HELD` (já tem todas as unidades: sem custo de compra e SEM veredito, porque o que o jogador pagou antes não está salvo), `UNKNOWN` (a cotação foi recusada: o custo é DESCONHECIDO, nunca zero) e `KNOWN`.
enum EstimateKind { NONE, HELD, UNKNOWN, KNOWN }
## [HIP] A faixa única da "margem pequena": o resultado estimado de 0 até esta porcentagem da recompensa.
const SMALL_MARGIN_PERCENT: int = 10


## Uma linha da aba: um contrato de entrega do quadro. `state` é o da ponte; `display_state` é o que a tela MOSTRA (`expired` para todo contrato `open` ou `accepted` com o prazo passado, ainda que a economia só o encerre na hora
## cheia, e para o que ela já encerrou; `abandoned` para o `failed` com `closed_reason` `abandoned` (nunca "Falhou" nem "Vencido"); nos demais casos, o próprio `state`). `minutes_left` é `deadline - now`, SEM limite: zero ou negativo com o prazo passado,
## e a tela só o mostra quando `display_state` é `open` ou `accepted`. `is_overdue` olha SÓ o prazo (`deadline <= now`), nunca o estado: um `completed` com o prazo passado tem `is_overdue` verdadeiro e `display_state` `completed`, então a tela decide por `display_state`.
## `owned` é quanto o jogador tem do bem. `can_deliver` e `can_abandon` (a linha é minha, está `accepted` e o prazo não passou) são só DICAS para habilitar os botões (quem decide é a ponte e a economia). `closed_reason` é o da ponte, CRU (vazio se não há).
## `destination_settlement_id` é o povoado do destino, para o nome por chave (vazio se o destino não é mercado).
class Row:
	extends RefCounted

	var contract_id: int = IdGenerator.NO_ID
	var state: String = ""
	var is_mine: bool = false
	var good_id: String = ""
	var quantity: int = 0
	var reward: int = 0
	var deadline: int = 0
	var destination_id: int = IdGenerator.NO_ID
	var destination_settlement_id: String = ""
	var minutes_left: int = 0
	var is_overdue: bool = false
	var display_state: String = ""
	var closed_reason: String = ""
	var owned: int = 0
	var can_deliver: bool = false
	var can_abandon: bool = false


## A estimativa de uma linha ativa (LW-107h). `missing` é quantas unidades faltam COMPRAR (a quantidade menos as livres em mãos); `cost` é o `total` da cotação de COMPRA de `missing` unidades no mercado mostrado; `result` é a recompensa menos `cost` (negativo = possível prejuízo); `funds_short` é quanto falta do saldo para o `cost` (0 se o saldo cobre);
## `is_small_margin` é o `result` de 0 até `SMALL_MARGIN_PERCENT` da recompensa. Só `KNOWN` tem `cost`, `result`, `funds_short` e `is_small_margin` (nos outros tipos ficam em zero e não devem ser lidos); `missing` vale também para `HELD` (zero) e `UNKNOWN`.
class Estimate:
	extends RefCounted

	var kind: ContractsViewModel.EstimateKind = ContractsViewModel.EstimateKind.NONE
	var missing: int = 0
	var cost: int = 0
	var result: int = 0
	var funds_short: int = 0
	var is_small_margin: bool = false


var _is_valid: bool = false
var _error_code: String = ""
var _market_id: int = IdGenerator.NO_ID
var _accepted_limit: int = 0
var _funds: int = 0
var _rows: Array[Row] = []
var _estimates: Dictionary[int, Estimate] = {}


## Refaz o modelo inteiro (nunca soma à leitura anterior) para o jogador `actor_id` diante do mercado `market_id`. Devolve falso, com o modelo vazio e o código em `error_code()`, se a ponte é nula (`BRIDGE_NO_GAME`) ou se qualquer
## das três consultas é recusada (sem jogo, sem personagem, sem economia, ator que não é personagem, mercado que não existe ou jogador sem conta). Quadro vazio NÃO é falha: devolve verdadeiro e nenhuma linha.
func refresh(bridge: SimBridge, actor_id: int, market_id: int) -> bool:
	_clear()
	if bridge == null:
		_error_code = SimBridge.CODE_NO_GAME
		return false
	var board: BridgePlayerContractsReplies.ContractBoardReply = bridge.peek_contract_board(actor_id, market_id)
	if not board.result.ok:
		return _refuse(board.result)
	var player: BridgePlayerEconomyReplies.PlayerEconomyReply = bridge.peek_player_economy(actor_id)
	if not player.result.ok:
		return _refuse(player.result)
	var markets: BridgeEconomyReplies.EconomyMarketsReply = bridge.peek_economy_markets()
	if not markets.result.ok:
		return _refuse(markets.result)
	var owned_by_good: Dictionary[String, int] = {}
	for held: Dictionary in player.goods:
		owned_by_good[str(held["good_id"])] = int(held["quantity"])
	var settlement_of: Dictionary[int, String] = {}
	for entry: BridgeEconomyReplies.EconomyMarketEntry in markets.markets:
		settlement_of[entry.market_id] = entry.settlement_id
	for source: BridgePlayerContractsReplies.ContractBoardRow in board.rows:
		var owned: int = owned_by_good.get(source.good_id, 0)
		var settlement_id: String = settlement_of.get(source.destination_id, "")
		_rows.append(_row_of(source, board.now, board.market_id, owned, settlement_id))
	_market_id = board.market_id
	_accepted_limit = board.accepted_limit
	_funds = player.funds
	_is_valid = true
	return true


## Verdadeiro só depois de um `refresh` que deu certo (e até o próximo `refresh`).
func is_valid() -> bool:
	return _is_valid


## O código da recusa do último `refresh` que falhou (o da ponte, sem tradução); vazio se o modelo é válido ou nunca foi atualizado.
func error_code() -> String:
	return _error_code


## O mercado que o modelo mostra (`IdGenerator.NO_ID` se está vazio).
func shown_market_id() -> int:
	return _market_id


## Todas as linhas, na ORDEM DA PONTE (`contract_id` crescente), numa CÓPIA da lista (a tela não mexe na do modelo); vazia se o modelo é inválido ou o quadro está vazio.
func rows() -> Array[Row]:
	return _rows.duplicate()


## "Disponíveis neste mercado": as linhas `open` da ponte, inclusive a de prazo passado (a tela a mostra como "Vencido", sem ação), na ordem da ponte.
func available() -> Array[Row]:
	var listed: Array[Row] = []
	for row: Row in _rows:
		if row.state == STATE_OPEN:
			listed.append(row)
	return listed


## "Meus contratos": primeiro as `accepted` da ponte (inclusive a de prazo passado) e depois as terminadas (`completed`, `expired` e `failed`, o abandono entre elas), cada grupo na ordem da ponte. Junto com `available()` cobre toda linha, uma vez só.
func mine() -> Array[Row]:
	var listed: Array[Row] = []
	for row: Row in _rows:
		if row.state == STATE_ACCEPTED:
			listed.append(row)
	for row: Row in _rows:
		if row.state != STATE_OPEN and row.state != STATE_ACCEPTED:
			listed.append(row)
	return listed


## Quantos contratos o jogador tem aceitos AGORA: as linhas de `display_state` `accepted`, isto é, as `accepted` que NÃO venceram (a MESMA conta da ponte, que não deixa o vencido ocupar vaga). Zero se o modelo é inválido.
func accepted_count() -> int:
	return _rows.filter(func(row: Row) -> bool: return row.display_state == STATE_ACCEPTED).size()


## O limite de contratos de entrega aceitos ao mesmo tempo, o `accepted_limit` da leitura (0 = sem limite definido; o modelo não tem número nenhum). Zero se o modelo é inválido.
func capacity() -> int:
	return _accepted_limit


## LW-107h: refaz as estimativas das linhas ATIVAS (`display_state` `open` ou `accepted`, isto é, no prazo; as terminadas e as vencidas nunca têm), para o jogador `actor_id` e o mercado mostrado, A PARTIR da leitura do último `refresh` (mesmas linhas, mesmo `owned`, mesmo saldo): a única consulta nova é a cotação de COMPRA (`peek_trade_quote`)
## das unidades que FALTAM de cada linha, no máximo uma por linha ativa. As unidades em mãos NÃO contam duas vezes: as encomendas `accepted` (minhas, no prazo) as consomem primeiro, por `contract_id` crescente; as `open` só veem a sobra (cada uma a mesma, pois nenhuma está aceita). Nada a comprar: `HELD`, sem consulta. Cotação recusada (sem estoque, lote acima do limite
## por ordem, bem banido, qualquer outra): `UNKNOWN`, nunca zero. Modelo inválido ou ponte nula: nenhuma estimativa. O `refresh` apaga as estimativas, então quem as quer chama este método depois dele; só a tela decide quando (só com a aba visível).
func refresh_estimates(bridge: SimBridge, actor_id: int) -> void:
	_estimates.clear()
	if not _is_valid or bridge == null:
		return
	var spare: Dictionary[String, int] = {}
	for row: Row in _rows:
		spare[row.good_id] = row.owned
	var in_hand: Dictionary[int, int] = {}
	for row: Row in _rows:
		if row.display_state == STATE_ACCEPTED and row.is_mine:
			in_hand[row.contract_id] = mini(row.quantity, spare[row.good_id])
			spare[row.good_id] -= in_hand[row.contract_id]
	for row: Row in _rows:
		if row.display_state == STATE_OPEN:
			in_hand[row.contract_id] = mini(row.quantity, spare[row.good_id])
	for row: Row in _rows:
		if in_hand.has(row.contract_id):
			_estimates[row.contract_id] = _estimate_of_row(bridge, actor_id, row, row.quantity - in_hand[row.contract_id])


## A estimativa da linha `contract_id` na última chamada de `refresh_estimates`; de tipo `NONE` (nenhum número) se a linha não tem (terminada, vencida, inexistente), se `refresh_estimates` não rodou depois do último `refresh` ou se o modelo é inválido.
func estimate_of(contract_id: int) -> Estimate:
	if _estimates.has(contract_id):
		return _estimates[contract_id]
	return Estimate.new()


func _clear() -> void:
	_is_valid = false
	_error_code = ""
	_market_id = IdGenerator.NO_ID
	_accepted_limit = 0
	_funds = 0
	_rows.clear()
	_estimates.clear()


func _refuse(refused: Result) -> bool:
	_error_code = refused.code
	return false


## A estimativa de uma linha com `missing` unidades por comprar: `HELD` se não falta nenhuma (sem consulta), `UNKNOWN` se a cotação de compra é recusada e `KNOWN` com o total dela. Só subtrai (recompensa menos custo, custo menos saldo) e compara (a faixa da margem pequena, em inteiros: sem divisão).
func _estimate_of_row(bridge: SimBridge, actor_id: int, row: Row, missing: int) -> Estimate:
	var estimate: Estimate = Estimate.new()
	estimate.missing = missing
	if missing <= 0:
		estimate.kind = EstimateKind.HELD
		return estimate
	var quoted: BridgePlayerEconomyReplies.TradeQuoteReply = bridge.peek_trade_quote(actor_id, _market_id, row.good_id, missing, BridgePlayerEconomyReplies.SIDE_BUY)
	if not quoted.result.ok:
		estimate.kind = EstimateKind.UNKNOWN
		return estimate
	estimate.kind = EstimateKind.KNOWN
	estimate.cost = quoted.total
	estimate.result = row.reward - quoted.total
	estimate.funds_short = maxi(0, quoted.total - _funds)
	estimate.is_small_margin = estimate.result >= 0 and estimate.result * 100 <= row.reward * SMALL_MARGIN_PERCENT
	return estimate


## Copia a linha da ponte e acrescenta só o que sai de uma subtração ou comparação com o `now` da MESMA resposta.
static func _row_of(source: BridgePlayerContractsReplies.ContractBoardRow, now: int, market_id: int, owned: int, settlement_id: String) -> Row:
	var row: Row = Row.new()
	row.contract_id = source.contract_id
	row.state = source.state
	row.is_mine = source.is_mine
	row.good_id = source.good_id
	row.quantity = source.quantity
	row.reward = source.reward
	row.deadline = source.deadline
	row.destination_id = source.destination_id
	row.destination_settlement_id = settlement_id
	row.minutes_left = source.deadline - now
	row.is_overdue = source.deadline <= now
	row.closed_reason = source.closed_reason
	row.display_state = _display_state_of(source.state, row.is_overdue, source.closed_reason)
	row.owned = owned
	row.can_deliver = source.is_mine and source.state == STATE_ACCEPTED and source.destination_id == market_id and owned >= source.quantity and not row.is_overdue
	row.can_abandon = source.is_mine and source.state == STATE_ACCEPTED and not row.is_overdue
	return row


## O estado que a tela mostra: o contrato que ainda consta `open` ou `accepted` mas já passou do prazo é "Vencido"; o `failed` que o jogador largou (`closed_reason` `abandoned`) é "Abandonado" e o `failed` sem motivo segue `failed`; o `state` da economia nunca é mexido.
static func _display_state_of(state: String, is_overdue: bool, closed_reason: String) -> String:
	var is_held: bool = state == STATE_OPEN or state == STATE_ACCEPTED
	if state == STATE_EXPIRED or (is_held and is_overdue):
		return STATE_EXPIRED
	if state == STATE_FAILED and closed_reason == REASON_ABANDONED:
		return STATE_ABANDONED
	return state
