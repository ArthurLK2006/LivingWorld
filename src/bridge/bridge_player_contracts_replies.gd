class_name BridgePlayerContractsReplies
extends RefCounted
## Tipos de resposta do QUADRO DE CONTRATOS do jogador na ponte (LW-107b1, a consulta; a resposta de aceitar e entregar é da LW-107b2; contrato em docs/modules/bridge.md, "Quadro de contratos do jogador"). Ficam à parte do `BridgePlayerEconomyReplies`. Como nele, cada resposta traz um `Result` e CÓPIAS dos valores, para a
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
