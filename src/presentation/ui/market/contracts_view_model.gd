class_name ContractsViewModel
extends RefCounted
## Os DADOS da aba "Contratos" da tela de mercado do jogador (LW-107d; contrato em docs/modules/presentation.md, "Quadro de contratos (LW-107)"). Sem nó e sem texto: só números, códigos e ids, que a `MarketView` troca
## por frases e desenha (LW-107e). `refresh` lê a ponte (`peek_contract_board`, `peek_player_economy` e `peek_economy_markets`) e COPIA o que precisa: nenhuma resposta da ponte é guardada. Só lê e não tem regra de jogo:
## não calcula recompensa, custo nem regra de prazo, só SUBTRAI e COMPARA com o `now` que veio na MESMA resposta da ponte (nunca outro relógio; o modelo não lê relógio nenhum). Falhou? O modelo fica VAZIO e inválido, com o
## código da recusa em `error_code()`: um número da leitura anterior nunca aparece como se fosse atual. Quem decide QUANDO atualizar é a tela; ela mostra `ui.contracts.unavailable` quando o modelo é inválido.
## LW-107f4a (docs/modules/presentation.md, "Encomendas por objetivo: abandonar, confirmar e capacidade"): a linha ganha `closed_reason` e `can_abandon`, o `display_state` distingue o abandono, e o modelo expõe `accepted_count()` e `capacity()` (o `accepted_limit` da ponte).

## Os estados do contrato com o texto da ponte (o da economia; um teste confere). Em `Row.display_state` são os estados que a tela MOSTRA: `expired` é o "Vencido". `STATE_ABANDONED` só existe em `display_state` (LW-107f4a): é o
## `failed` cujo `closed_reason` é `REASON_ABANDONED` (o texto da economia); o `failed` sem motivo (a falha real) segue `failed`.
const STATE_OPEN: String = "open"
const STATE_ACCEPTED: String = "accepted"
const STATE_COMPLETED: String = "completed"
const STATE_EXPIRED: String = "expired"
const STATE_FAILED: String = "failed"
const STATE_ABANDONED: String = "abandoned"
const REASON_ABANDONED: String = "abandoned"


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


var _is_valid: bool = false
var _error_code: String = ""
var _market_id: int = IdGenerator.NO_ID
var _accepted_limit: int = 0
var _rows: Array[Row] = []


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


func _clear() -> void:
	_is_valid = false
	_error_code = ""
	_market_id = IdGenerator.NO_ID
	_accepted_limit = 0
	_rows.clear()


func _refuse(refused: Result) -> bool:
	_error_code = refused.code
	return false


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
