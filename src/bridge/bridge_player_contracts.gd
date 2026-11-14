class_name BridgePlayerContracts
extends RefCounted
## O quadro de contratos do JOGADOR na ponte (LW-107b1, a consulta; contrato em docs/modules/bridge.md, "Quadro de contratos do jogador", e docs/modules/economy.md, seção 8). O `SimBridge` só delega para cá, porque ele já estava perto de 300 linhas. Sem estado e sem regra de jogo: contratos, custódia, dinheiro e
## bens são da `economy` (a ponte só lê por `peek_*`). Aceitar e entregar são da LW-107b2. Só cita classes de `economy/api/`; os textos de tipo e de estado abaixo são os da economia (`tests/unit/test_bridge_player_contracts.gd` confere). Ponte sem jogo, sem `character` ou sem `economy` é o `SimBridge`, antes de chamar. Nenhum evento novo.

## Quantos contratos terminados (`completed` ou `expired`) do ator o quadro mostra: os de maior `contract_id` [HIP].
const FINISHED_LIMIT: int = 5
## O tipo e os estados do contrato, com o texto da economia (`ContractBook`, interna dela: a ponte cita só a `api/`).
const KIND_DELIVERY: String = "delivery"
const STATE_OPEN: String = "open"
const STATE_ACCEPTED: String = "accepted"
const STATE_COMPLETED: String = "completed"
const STATE_EXPIRED: String = "expired"


## O quadro do mercado `market_id` para o ator, SÓ LEITURA e SEM exigir alcance. (1) O ator é um personagem do `character` (ID solto ou de NPC: o código dele) e o mercado existe (`ECON_UNKNOWN_MARKET`). (2) Entram, em ordem crescente de `contract_id` e numa lista só, só contratos de `delivery`:
## (a) em `open` cujo emissor ou destino é o mercado; (b) do ator em `accepted`, de qualquer mercado; (c) os `FINISHED_LIMIT` mais recentes do ator em `completed` ou `expired`. Ficam fora o `labor` (LW-107f), a vaga e o que é de outro ator. O `open` com o prazo já passado continua na lista (a tela o mostra "Vencido").
## `now` vem do relógio, lido pela ponte na mesma consulta. Quadro vazio é sucesso.
static func board(character: CharacterModule, economy: EconomyModule, now: int, actor_id: int, market_id: int) -> BridgePlayerContractsReplies.ContractBoardReply:
	var known: CharacterQuery = character.peek_character(actor_id)
	if not known.result.ok:
		return BridgePlayerContractsReplies.ContractBoardReply.new(known.result)
	var market: EconomyReplies.MarketQuery = economy.peek_market(market_id)
	if not market.result.ok:
		return BridgePlayerContractsReplies.ContractBoardReply.new(market.result)
	var listed: Array[EconomyReplies.ContractQuery] = economy.peek_contracts().contracts
	var recent: Array[int] = _recent_finished(listed, actor_id)
	var rows: Array[BridgePlayerContractsReplies.ContractBoardRow] = []
	for contract: EconomyReplies.ContractQuery in listed:
		if contract.kind == KIND_DELIVERY and (_is_open_at(contract, market_id) or _is_carried_by(contract, actor_id) or recent.has(contract.contract_id)):
			rows.append(_row_of(contract, actor_id))
	return BridgePlayerContractsReplies.ContractBoardReply.new(Result.success(), market_id, market.settlement_id, now, rows)


## (a) o contrato `open` que o mercado emitiu ou espera como destino.
static func _is_open_at(contract: EconomyReplies.ContractQuery, market_id: int) -> bool:
	return contract.state == STATE_OPEN and (contract.issuer_id == market_id or contract.destination_id == market_id)


## (b) o contrato `accepted` do ator, de qualquer mercado (é o que ele carrega e para onde levar).
static func _is_carried_by(contract: EconomyReplies.ContractQuery, actor_id: int) -> bool:
	return contract.state == STATE_ACCEPTED and contract.acceptor_id == actor_id


## (c) os IDs dos `FINISHED_LIMIT` contratos de entrega terminados do ator (`completed` ou `expired`) de MAIOR `contract_id`; `listed` vem em ordem crescente, então se lê de trás para frente.
static func _recent_finished(listed: Array[EconomyReplies.ContractQuery], actor_id: int) -> Array[int]:
	var ids: Array[int] = []
	for index: int in range(listed.size() - 1, -1, -1):
		var contract: EconomyReplies.ContractQuery = listed[index]
		var is_finished: bool = contract.state == STATE_COMPLETED or contract.state == STATE_EXPIRED
		if ids.size() < FINISHED_LIMIT and is_finished and contract.kind == KIND_DELIVERY and contract.acceptor_id == actor_id:
			ids.append(contract.contract_id)
	return ids


static func _row_of(contract: EconomyReplies.ContractQuery, actor_id: int) -> BridgePlayerContractsReplies.ContractBoardRow:
	var row: BridgePlayerContractsReplies.ContractBoardRow = BridgePlayerContractsReplies.ContractBoardRow.new()
	row.contract_id = contract.contract_id
	row.kind = contract.kind
	row.state = contract.state
	row.is_mine = contract.acceptor_id == actor_id
	row.issuer_id = contract.issuer_id
	row.reward = contract.reward
	row.deadline = contract.deadline
	row.good_id = contract.good_id
	row.quantity = contract.quantity
	row.destination_id = contract.destination_id
	row.place_id = contract.place_id
	row.minutes = contract.minutes
	row.worked_minutes = contract.worked_minutes
	return row
