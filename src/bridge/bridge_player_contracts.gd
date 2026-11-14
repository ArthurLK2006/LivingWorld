class_name BridgePlayerContracts
extends RefCounted
## O quadro de contratos do JOGADOR na ponte (LW-107b; contrato em docs/modules/bridge.md, "Quadro de contratos do jogador", e docs/modules/economy.md, seção 8). O `SimBridge` só delega para cá, porque ele já estava perto de 300 linhas (292) e com a delegação vai a 316. Sem estado e sem regra de jogo: contrato, custódia, dinheiro e
## bens são da `economy` (a ponte só lê por `peek_*` e comanda por `request_*`, que são atômicos). O que a ponte COORDENA: a posição GUARDADA do jogador (do `character`, nunca a da apresentação), o alcance do mercado (do `world`, `MarketReach`: a ponte não tem constante de alcance nem conta de distância),
## o prazo do `accept` (decisão de Arthur de 14/11/2026: contrato vencido não se aceita) e a chave do texto. Só cita classes de `economy/api/`; os textos de tipo e de estado abaixo são os da economia (`tests/unit/test_bridge_player_contracts.gd` confere). Quem confere a ponte sem jogo, sem `character`
## ou sem `economy` é o `SimBridge`, antes de chamar. Nenhum evento novo: o `ContractCompleted` do `deliver` é da economia.

## O contrato do jogador não é dele (no `deliver`: não é de entrega ou o aceitante é outro) ou venceu (no `accept`: `deadline` menor ou igual a `now`, ou já `expired`). Códigos da ponte, sem tradução da economia.
const CODE_NOT_YOURS: String = "BRIDGE_CONTRACT_NOT_YOURS"
const CODE_EXPIRED: String = "BRIDGE_CONTRACT_EXPIRED"
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


## Aceitar o contrato de entrega, na ORDEM do contrato (docs/modules/bridge.md, item (ii)). (1) Ponte sem jogo, sem `character` ou sem `economy`: o `SimBridge`. (2) O ator é um personagem do `character` (ID solto, NPC ou mercado como ator: o código dele, mesmo longe), e dele vem a posição GUARDADA. (3) O contrato
## existe (`ECON_UNKNOWN_CONTRACT`: o erro da economia). (4) É de entrega, senão `ECON_CONTRACT_IMPOSSIBLE` (o jogador não tem como cumprir o `labor` nem a vaga). (5) O ator está ao alcance do mercado do emissor OU do destino, o que for mercado (`MarketReach`; nenhum é mercado: `ECON_CONTRACT_IMPOSSIBLE`;
## longe: `PLACE_TOO_FAR` do `world`, sem tradução, ANTES de tudo que vem abaixo: longe vence "já aceito" e "prazo vencido"). (6) O prazo: contrato `expired`, ou `open` com `deadline` menor ou igual a `now` (o `total_minutes` do relógio), é recusado com `BRIDGE_CONTRACT_EXPIRED` SEM chamar a economia; sem conferência de custo
## nem de bens (a proteção contra exploração é só da postagem). (7) `request_accept_contract` da economia, atômico (confere `open` e o dono aberto que não é o emissor; não confere prazo). A recusa não muda nada e não publica evento.
static func accept(character: CharacterModule, economy: EconomyModule, places: Array[Place], now: int, actor_id: int, contract_id: int) -> BridgePlayerContractsReplies.ContractActionReply:
	var contract: EconomyReplies.ContractQuery = economy.peek_contract(contract_id)
	var checked: Result = _check(character.peek_character(actor_id), contract, economy, places, actor_id, false)
	if checked.ok and _is_expired(contract, now):
		checked = Result.failure(CODE_EXPIRED, "BridgePlayerContracts.accept: o contrato %d venceu (prazo %d, agora %d); esperado um contrato com prazo depois de agora." % [contract_id, contract.deadline, now])
	if not checked.ok:
		return BridgePlayerContractsReplies.ContractActionReply.new(checked, contract_id)
	var accepted: Result = economy.request_accept_contract(contract_id, actor_id)
	return BridgePlayerContractsReplies.ContractActionReply.new(accepted, contract_id, BridgePlayerContractsReplies.ContractActionReply.KEY_ACCEPTED, contract.reward)


## Entregar o contrato de entrega que o ator aceitou, na ORDEM do contrato: os passos (1) a (5) do `accept`, com duas diferenças: no passo (4) o contrato que não é de entrega, ou cujo aceitante é outro, devolve `BRIDGE_CONTRACT_NOT_YOURS`; no passo (5) o alcance é só o do mercado DESTINO (destino que não é mercado:
## `ECON_CONTRACT_IMPOSSIBLE`). Não há passo de prazo: o prazo vencido é da economia (`ECON_CONTRACT_IMPOSSIBLE`). (7) `request_deliver_contract` da economia, atômico: confere `accepted`, o prazo, os bens do aceitante, a capacidade do destino e a custódia; os bens vão do inventário do jogador para o estoque do destino e a custódia paga
## a recompensa (um `ContractCompleted`, da economia). A recompensa da resposta é lida do contrato antes de entregar.
static func deliver(character: CharacterModule, economy: EconomyModule, places: Array[Place], actor_id: int, contract_id: int) -> BridgePlayerContractsReplies.ContractActionReply:
	var contract: EconomyReplies.ContractQuery = economy.peek_contract(contract_id)
	var checked: Result = _check(character.peek_character(actor_id), contract, economy, places, actor_id, true)
	if not checked.ok:
		return BridgePlayerContractsReplies.ContractActionReply.new(checked, contract_id)
	var delivered: Result = economy.request_deliver_contract(contract_id)
	return BridgePlayerContractsReplies.ContractActionReply.new(delivered, contract_id, BridgePlayerContractsReplies.ContractActionReply.KEY_DELIVERED, contract.reward)


## Os passos (2) a (5) do `accept` e do `deliver` (`delivering`): o que a ponte confere ANTES de qualquer comando da economia, na ordem. Devolve o sucesso ou a primeira recusa.
static func _check(known: CharacterQuery, contract: EconomyReplies.ContractQuery, economy: EconomyModule, places: Array[Place], actor_id: int, delivering: bool) -> Result:
	if not known.result.ok:
		return known.result
	if not contract.result.ok:
		return contract.result
	var caller: String = "BridgePlayerContracts.deliver" if delivering else "BridgePlayerContracts.accept"
	if contract.kind != KIND_DELIVERY:
		return Result.failure(CODE_NOT_YOURS if delivering else EconomyCodes.CONTRACT_IMPOSSIBLE, "%s: o contrato %d é '%s'; esperado '%s' (o jogador só opera contratos de entrega)." % [caller, contract.contract_id, contract.kind, KIND_DELIVERY])
	if delivering and contract.acceptor_id != actor_id:
		return Result.failure(CODE_NOT_YOURS, "%s: o contrato %d foi aceito por %d; esperado o próprio ator %d." % [caller, contract.contract_id, contract.acceptor_id, actor_id])
	var markets: Array[int] = [contract.destination_id]
	if not delivering:
		markets.push_front(contract.issuer_id)
	return _within_reach(economy, places, known.position, markets, caller, contract.contract_id)


## O passo (5): vale o PRIMEIRO dos mercados de `candidates` (os que a economia conhece) ao alcance da posição, e a recusa é a do primeiro mercado ao qual o ator estava longe (`PLACE_TOO_FAR` do `world`, sem tradução). Nenhum candidato é mercado: `ECON_CONTRACT_IMPOSSIBLE`.
static func _within_reach(economy: EconomyModule, places: Array[Place], position: Vector3, candidates: Array[int], caller: String, contract_id: int) -> Result:
	var too_far: Result = null
	for candidate: int in candidates:
		var market: EconomyReplies.MarketQuery = economy.peek_market(candidate)
		if not market.result.ok:
			continue
		var reach: Result = MarketReach.peek_within_reach(places, market.settlement_id, position)
		if reach.ok:
			return reach
		if too_far == null:
			too_far = reach
	if too_far == null:
		return Result.failure(EconomyCodes.CONTRACT_IMPOSSIBLE, "%s: nenhum de %s (contrato %d) é mercado; esperado ao menos um deles (o jogador só opera contrato ao alcance de um mercado)." % [caller, str(candidates), contract_id])
	return too_far


## O contrato vencido para o jogador: já `expired`, ou ainda `open` (a economia só o encerra na hora cheia) com `deadline` menor ou igual a `now`. Sem tolerância depois do prazo.
static func _is_expired(contract: EconomyReplies.ContractQuery, now: int) -> bool:
	return contract.state == STATE_EXPIRED or (contract.state == STATE_OPEN and contract.deadline <= now)


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
