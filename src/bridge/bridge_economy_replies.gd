class_name BridgeEconomyReplies
extends RefCounted
## Tipos de resposta do JOGADOR NA ECONOMIA da ponte (LW-105; contrato em docs/modules/bridge.md, "Jogador na economia"). Como em `BridgeReplies`, cada resposta traz um
## `Result` e CÓPIAS dos valores, para a apresentação nunca citar tipo de `sim/`. Sem estado e sem método de regra: é só o lugar dos tipos.


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
