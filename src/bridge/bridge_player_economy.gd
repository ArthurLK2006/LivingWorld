class_name BridgePlayerEconomy
extends RefCounted
## O repasse do JOGADOR à economia na ponte (LW-105; contrato em docs/modules/bridge.md, "Jogador na economia", e docs/modules/economy.md, seção 3). O `SimBridge` só delega para
## cá, porque ele já passa de 300 linhas. Sem estado e sem regra de jogo: a conta, o dinheiro e os bens do jogador são da `economy` (DEC-130; o saldo vem do `Ledger`), e o jogador é um
## personagem GUARDADO no `character`, com o mesmo ID de ator (todo ID vem do mesmo gerador, então o ID do personagem serve de dono na economia). Cita a `economy/api` e, desde a LW-105d, o
## `MarketReach` do `world`: a proximidade do mercado é REGRA do `world` (decisão de Arthur, 12/11/2026) e a ponte só coordena, sem constante de alcance nem conta de distância.
## Quem confere a ponte sem jogo, sem `character` ou sem `economy` é o `SimBridge`, antes de chamar.

## O tipo de dono do jogador em `data/economy/owner_kinds.json` (capacidade de peso e saldo inicial por tipo, [HIP]).
const OWNER_KIND: String = "player"


## Abre a conta de dinheiro e o inventário do jogador na economia (idempotente: quem já tem conta fica como está, sem novo `mint`). Só abre para um ator que o `character` conhece;
## um ID solto ou de NPC é recusado com o código do `character`, sem abrir conta nenhuma.
static func open_account(character: CharacterModule, economy: EconomyModule, actor_id: int) -> Result:
	var known: CharacterQuery = character.peek_character(actor_id)
	if not known.result.ok:
		return known.result
	return economy.request_open_owner(actor_id, OWNER_KIND)


## O saldo, o peso e os bens do jogador, em cópia. Ator desconhecido para o `character`, ou sem conta aberta na economia: falha tratada, com o código de quem recusou.
static func view(character: CharacterModule, economy: EconomyModule, actor_id: int) -> BridgePlayerEconomyReplies.PlayerEconomyReply:
	var known: CharacterQuery = character.peek_character(actor_id)
	if not known.result.ok:
		return BridgePlayerEconomyReplies.PlayerEconomyReply.new(known.result)
	var balance: EconomyReplies.BalanceQuery = economy.peek_balance(actor_id)
	if not balance.result.ok:
		return BridgePlayerEconomyReplies.PlayerEconomyReply.new(balance.result)
	var inventory: EconomyReplies.InventoryQuery = economy.peek_inventory(actor_id)
	if not inventory.result.ok:
		return BridgePlayerEconomyReplies.PlayerEconomyReply.new(inventory.result)
	var goods: Array[Dictionary] = []
	for row: Dictionary in inventory.rows:
		goods.append(row.duplicate())
	return BridgePlayerEconomyReplies.PlayerEconomyReply.new(Result.success(), balance.balance, inventory.weight, inventory.capacity, goods)


## A ordem de compra (`buy`) ou de venda (`sell`) do jogador num mercado, na ORDEM do contrato (docs/modules/bridge.md, "Proximidade do mercado"). (1) O ator é um personagem do `character`: um ID solto, de NPC ou de outro dono
## (o próprio mercado, por exemplo) é recusado com o código do `character`, então a ponte nunca move bens de quem não é o jogador, e dele vem a posição GUARDADA, nunca a da apresentação. (2) O mercado dá o assentamento; mercado
## inexistente: a ponte não responde e deixa a economia devolver o erro de sempre. (3) O jogador está ao alcance de um mercado desse assentamento: a regra e o alcance são do `world` (`MarketReach`) e a recusa volta com o código dele
## (`PLACE_TOO_FAR`), sem tradução, ANTES de qualquer erro da economia (longe vence sem dinheiro e sem conta), sem mudar nada e sem publicar evento. (4) `EconomyModule.request_trade`, que é ATÔMICO (tudo ou nada; a economia confere
## dono aberto, estoque, fundos, teto de compra e capacidade de peso, e o saldo e os bens só mudam pelo `Ledger` e pelo `GoodsStore`). A resposta traz sempre a chave do texto.
static func trade(character: CharacterModule, economy: EconomyModule, places: Array[Place], actor_id: int, market_id: int, good_id: String, quantity: int, side: String) -> BridgePlayerEconomyReplies.PlayerTradeReply:
	var known: CharacterQuery = character.peek_character(actor_id)
	if not known.result.ok:
		return BridgePlayerEconomyReplies.PlayerTradeReply.new(known.result, 0, 0, side)
	var market: EconomyReplies.MarketQuery = economy.peek_market(market_id)
	if market.result.ok:
		var reach: Result = MarketReach.peek_within_reach(places, market.settlement_id, known.position)
		if not reach.ok:
			return BridgePlayerEconomyReplies.PlayerTradeReply.new(reach, 0, 0, side)
	var traded: EconomyReplies.TradeResult = economy.request_trade(actor_id, market_id, good_id, quantity, side)
	return BridgePlayerEconomyReplies.PlayerTradeReply.new(traded.result, traded.quantity, traded.total, side)


## O mercado ao alcance do jogador (LW-106b; contrato em docs/modules/bridge.md, "Mercado ao alcance"), SÓ LEITURA: nada muda e nada é publicado. (1) O ator é um personagem do `character` (ID solto ou de NPC: o código do `character`, como no `trade`), e dele
## vem a posição GUARDADA, nunca a da apresentação. (2) Os mercados são os de `peek_economy_markets` (a mesma lista: `BridgeEconomyInspect.markets`, em ordem crescente de `market_id`); para cada um a ponte faz ao `world` (`MarketReach`, dono da regra e do alcance) a
## mesma pergunta do `trade` sobre o assentamento dele, e vale o PRIMEIRO que passa: a ponte não tem constante de alcance nem conta de distância. (3) Nenhum ao alcance (inclusive sem mercado algum): `PLACE_TOO_FAR` do `world`, sem tradução e sem chave de texto.
static func market_in_reach(character: CharacterModule, economy: EconomyModule, places: Array[Place], actor_id: int) -> BridgePlayerEconomyReplies.MarketInReachReply:
	var known: CharacterQuery = character.peek_character(actor_id)
	if not known.result.ok:
		return BridgePlayerEconomyReplies.MarketInReachReply.new(known.result)
	var listed: BridgeEconomyReplies.EconomyMarketsReply = BridgeEconomyInspect.markets(economy, BridgeEconomyInspect.settlement_ids_of(places))
	for market: BridgeEconomyReplies.EconomyMarketEntry in listed.markets:
		if MarketReach.peek_within_reach(places, market.settlement_id, known.position).ok:
			return BridgePlayerEconomyReplies.MarketInReachReply.new(Result.success(), market.market_id, market.settlement_id)
	var too_far: String = "BridgePlayerEconomy.market_in_reach: o ator %d, na posição guardada %s, não está ao alcance de nenhum dos %d mercados da economia; esperado estar ao alcance de um deles (regra do `world`: MarketReach)." % [actor_id, str(known.position), listed.markets.size()]
	return BridgePlayerEconomyReplies.MarketInReachReply.new(Result.failure(MarketReach.CODE_PLACE_TOO_FAR, too_far))
