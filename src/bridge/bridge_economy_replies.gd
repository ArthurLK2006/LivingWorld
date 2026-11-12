class_name BridgeEconomyReplies
extends RefCounted
## Tipos de resposta do JOGADOR NA ECONOMIA da ponte (LW-105; contrato em docs/modules/bridge.md, "Jogador na economia"). Como em `BridgeReplies`, cada resposta traz um
## `Result` e CÓPIAS dos valores, para a apresentação nunca citar tipo de `sim/`. Sem estado e sem método de regra: é só o lugar dos tipos.

## Os dois lados de uma ordem, com o texto que `EconomyModule.request_trade` espera (docs/modules/economy.md, seção 5). `tests/unit/test_bridge_player_trade.gd` confere que são os do motor.
const SIDE_BUY: String = "buy"
const SIDE_SELL: String = "sell"


## `peek_player_economy`: `funds`, o saldo do jogador (CÓPIA do saldo do `Ledger`; o nome evita `balance`, que a regra F do `tools/check_architecture` reserva ao `Ledger` fora de `economy/api/`), o peso carregado e a capacidade de peso (do inventário na `economy`) e uma linha por bem que o jogador tem
## (`good_id`, `quantity`, por `good_id` crescente). Só valem se `result.ok`.
class PlayerEconomyReply:
	extends RefCounted

	var result: Result
	var funds: int = 0
	var weight: int = 0
	var capacity: int = 0
	var goods: Array[Dictionary] = []

	func _init(reply_result: Result, owner_funds: int = 0, carried_weight: int = 0, weight_capacity: int = 0, owned_goods: Array[Dictionary] = []) -> void:
		result = reply_result
		funds = owner_funds
		weight = carried_weight
		capacity = weight_capacity
		goods = owned_goods


## `request_trade`: o desfecho da ordem do jogador. `quantity` e `total` (inteiros, em dinheiro do jogo) só valem se `result.ok`. `text_key` é SEMPRE a chave do texto a mostrar, nunca o texto (DEC-036):
## no sucesso, a de compra ou de venda; na recusa, a do código de falha (`FAILURE_KEYS`); código sem chave própria (os da ponte, os do `character` e os de ordem inválida) usa `FALLBACK_KEY`.
class PlayerTradeReply:
	extends RefCounted

	const KEY_BOUGHT: String = "economy.trade.bought"
	const KEY_SOLD: String = "economy.trade.sold"
	const FALLBACK_KEY: String = "economy.trade.failed"
	const FAILURE_KEYS: Dictionary[String, String] = {
		EconomyCodes.INSUFFICIENT_FUNDS: "economy.trade.no_funds",
		EconomyCodes.INSUFFICIENT_STOCK: "economy.trade.no_stock",
		EconomyCodes.INSUFFICIENT_GOODS: "economy.trade.no_goods",
		EconomyCodes.CAPACITY_EXCEEDED: "economy.trade.too_heavy",
		EconomyCodes.MARKET_FULL: "economy.trade.market_full",
		EconomyCodes.MARKET_NO_FUNDS: "economy.trade.market_no_funds",
		EconomyCodes.TRADE_BANNED: "economy.trade.banned",
	}

	var result: Result
	var quantity: int
	var total: int
	var text_key: String

	func _init(reply_result: Result, traded_quantity: int, traded_total: int, side: String) -> void:
		result = reply_result
		quantity = traded_quantity
		total = traded_total
		if reply_result.ok:
			text_key = KEY_BOUGHT if side == BridgeEconomyReplies.SIDE_BUY else KEY_SOLD
		else:
			text_key = FAILURE_KEYS.get(reply_result.code, FALLBACK_KEY)
