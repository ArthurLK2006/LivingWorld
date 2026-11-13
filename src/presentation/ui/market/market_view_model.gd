class_name MarketViewModel
extends RefCounted
## Os DADOS da tela de mercado do jogador (LW-106c; contrato em docs/modules/presentation.md, "Interface de mercado (LW-106)"). Sem nó e sem texto: só números e ids, que a `MarketView` troca por frases e desenha.
## `refresh` lê a ponte (`peek_economy_markets` e `peek_player_economy`) e COPIA o que precisa: nenhuma resposta da ponte é guardada. Só lê: não escreve nada, não tem regra de jogo e NÃO calcula total (a ordem anda
## pela curva de preço, então o total de N unidades não é N vezes o preço da unidade; o total real vem na resposta de `request_trade`, decisão de Arthur de 13/11/2026). Falhou? O modelo fica VAZIO e inválido:
## um número da leitura anterior nunca aparece como se fosse atual. Quem decide QUANDO atualizar é a tela (a cada intervalo e depois de cada pedido); o modelo não tem relógio.


## Uma linha da tela: um bem do mercado, com o preço da UNIDADE para comprar (`ask`) e para vender (`bid`), o estoque do mercado, quanto o jogador tem (`owned`, 0 se não tem) e a marca de falta.
class Row:
	extends RefCounted

	var good_id: String
	var ask: int
	var bid: int
	var stock: int
	var owned: int
	var is_in_shortage: bool

	func _init(row_good_id: String, row_ask: int, row_bid: int, row_stock: int, row_owned: int, row_is_in_shortage: bool) -> void:
		good_id = row_good_id
		ask = row_ask
		bid = row_bid
		stock = row_stock
		owned = row_owned
		is_in_shortage = row_is_in_shortage


var _is_valid: bool = false
var _market_id: int = IdGenerator.NO_ID
var _funds: int = 0
var _weight: int = 0
var _capacity: int = 0
var _rows: Array[Row] = []


## Refaz o modelo inteiro (nunca soma à leitura anterior) para o jogador `actor_id` diante do mercado `market_id`. Devolve falso, com o modelo vazio, se a ponte é nula, se a consulta da economia falha (sem jogo ou sem
## economia), se o mercado não existe ou se a consulta do jogador falha (ator que não é o jogador, ou sem conta). As linhas são as dos bens DO MERCADO, em ordem crescente de `good_id`.
func refresh(bridge: SimBridge, actor_id: int, market_id: int) -> bool:
	_clear()
	if bridge == null:
		return false
	var market: BridgeEconomyReplies.EconomyMarketEntry = _market_of(bridge.peek_economy_markets(), market_id)
	if market == null:
		return false
	var player: BridgePlayerEconomyReplies.PlayerEconomyReply = bridge.peek_player_economy(actor_id)
	if not player.result.ok:
		return false
	var owned_by_good: Dictionary[String, int] = {}
	for held: Dictionary in player.goods:
		owned_by_good[str(held["good_id"])] = int(held["quantity"])
	for source: BridgeEconomyReplies.EconomyMarketRow in market.rows:
		var owned: int = owned_by_good.get(source.good_id, 0)
		_rows.append(Row.new(source.good_id, source.ask, source.bid, source.stock, owned, source.is_in_shortage))
	_rows.sort_custom(_row_before)
	_market_id = market.market_id
	_funds = player.funds
	_weight = player.weight
	_capacity = player.capacity
	_is_valid = true
	return true


## Verdadeiro só depois de um `refresh` que deu certo (e até o próximo `refresh`); a tela mostra `ui.market.unavailable` quando é falso.
func is_valid() -> bool:
	return _is_valid


## O mercado que o modelo mostra (`IdGenerator.NO_ID` se está vazio). O nome evita `market_id`, que é o parâmetro de `refresh`.
func shown_market_id() -> int:
	return _market_id


## O dinheiro do jogador (o saldo do `Ledger`, copiado pela ponte).
func funds() -> int:
	return _funds


## O peso que o jogador carrega e a capacidade dele.
func weight() -> int:
	return _weight


func capacity() -> int:
	return _capacity


## As linhas por `good_id` crescente, numa CÓPIA da lista (a tela não mexe na do modelo); vazia se o modelo é inválido.
func rows() -> Array[Row]:
	return _rows.duplicate()


func _clear() -> void:
	_is_valid = false
	_market_id = IdGenerator.NO_ID
	_funds = 0
	_weight = 0
	_capacity = 0
	_rows.clear()


static func _market_of(reply: BridgeEconomyReplies.EconomyMarketsReply, market_id: int) -> BridgeEconomyReplies.EconomyMarketEntry:
	if reply.result.ok:
		for entry: BridgeEconomyReplies.EconomyMarketEntry in reply.markets:
			if entry.market_id == market_id:
				return entry
	return null


static func _row_before(first: Row, second: Row) -> bool:
	return first.good_id < second.good_id
