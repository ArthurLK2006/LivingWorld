class_name BridgePlayerContractsReplies
extends RefCounted
## Tipos de resposta do QUADRO DE CONTRATOS do jogador na ponte (LW-107b; contrato em docs/modules/bridge.md, "Quadro de contratos do jogador"). Ficam à parte do `BridgePlayerEconomyReplies`. Como nele, cada resposta traz um `Result` e CÓPIAS dos valores, para a
## apresentação nunca citar tipo de `sim/`. Sem estado e sem método de regra: é só o lugar dos tipos.


## Uma linha do quadro (`peek_contract_board`): cópia dos campos do contrato na economia, com os nomes do `ContractQuery`. `is_mine`: o aceitante é o ator. `place_id`, `minutes` e `worked_minutes` só valem no `labor` (LW-107f): ficam no contrato para ele não mudar; na entrega vêm no valor vazio.
class ContractBoardRow:
	extends RefCounted

	var contract_id: int = IdGenerator.NO_ID
	var kind: String = ""
	var state: String = ""
	var is_mine: bool = false
	var issuer_id: int = IdGenerator.NO_ID
	var reward: int = 0
	var deadline: int = 0
	var good_id: String = ""
	var quantity: int = 0
	var destination_id: int = IdGenerator.NO_ID
	var place_id: String = ""
	var minutes: int = 0
	var worked_minutes: int = 0


## `peek_contract_board`: o mercado consultado (`market_id`) e o assentamento dele, `now` (o `total_minutes` do relógio lido na MESMA consulta, para a tela calcular o prazo restante sem outro relógio) e as linhas, por `contract_id` crescente. Só valem se `result.ok`;
## quadro vazio é sucesso (`result.ok` com `rows` vazio).
class ContractBoardReply:
	extends RefCounted

	var result: Result
	var market_id: int
	var settlement_id: String
	var now: int
	var rows: Array[ContractBoardRow]

	func _init(reply_result: Result, id_of_market: int = IdGenerator.NO_ID, id_of_settlement: String = "", total_minutes: int = 0, board_rows: Array[ContractBoardRow] = []) -> void:
		result = reply_result
		market_id = id_of_market
		settlement_id = id_of_settlement
		now = total_minutes
		rows = board_rows


## `request_contract_accept` e `request_contract_deliver`: o desfecho do pedido do jogador. `contract_id` é sempre o contrato pedido. `reward` (inteiro, em dinheiro do jogo) só vale se `result.ok`: no `accept` a que será paga, no `deliver` a paga (lida do contrato antes de entregar); na recusa, 0.
## `text_key` é SEMPRE a chave do texto a mostrar, nunca o texto (DEC-036): no sucesso, a de aceite ou de entrega; na recusa, a do código de falha (`FAILURE_KEYS`, que inclui o `PLACE_TOO_FAR` do `world`: longe do mercado); código sem chave própria (os demais da ponte, os do `character` e `ECON_UNKNOWN_OWNER`) usa
## `FALLBACK_KEY`. O texto em `data/text/pt_br.json` é da LW-107e2: aqui só existe a chave.
class ContractActionReply:
	extends RefCounted

	const KEY_ACCEPTED: String = "economy.contract.accepted"
	const KEY_DELIVERED: String = "economy.contract.delivered"
	const FALLBACK_KEY: String = "economy.contract.failed"
	const FAILURE_KEYS: Dictionary[String, String] = {
		EconomyCodes.CONTRACT_NOT_OPEN: "economy.contract.not_open",
		EconomyCodes.UNKNOWN_CONTRACT: "economy.contract.unknown",
		EconomyCodes.CONTRACT_IMPOSSIBLE: "economy.contract.impossible",
		EconomyCodes.INSUFFICIENT_GOODS: "economy.contract.no_goods",
		EconomyCodes.CAPACITY_EXCEEDED: "economy.contract.destination_full",
		MarketReach.CODE_PLACE_TOO_FAR: "economy.contract.too_far",
		BridgePlayerContracts.CODE_NOT_YOURS: "economy.contract.not_yours",
		BridgePlayerContracts.CODE_EXPIRED: "economy.contract.expired",
	}

	var result: Result
	var contract_id: int
	var reward: int
	var text_key: String

	func _init(reply_result: Result, id_of_contract: int, success_key: String = KEY_ACCEPTED, paid_reward: int = 0) -> void:
		result = reply_result
		contract_id = id_of_contract
		if reply_result.ok:
			reward = paid_reward
			text_key = success_key
		else:
			reward = 0
			text_key = FAILURE_KEYS.get(reply_result.code, FALLBACK_KEY)
