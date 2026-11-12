class_name BridgePlayerEconomy
extends RefCounted
## O repasse do JOGADOR à economia na ponte (LW-105; contrato em docs/modules/bridge.md, "Jogador na economia", e docs/modules/economy.md, seção 3). O `SimBridge` só delega para
## cá, porque ele já passa de 300 linhas. Sem estado e sem regra de jogo: a conta, o dinheiro e os bens do jogador são da `economy` (DEC-130; o saldo vem do `Ledger`), e o jogador é um
## personagem GUARDADO no `character`, com o mesmo ID de ator (todo ID vem do mesmo gerador, então o ID do personagem serve de dono na economia). Só cita a `economy/api`.
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
static func view(character: CharacterModule, economy: EconomyModule, actor_id: int) -> BridgeEconomyReplies.PlayerEconomyReply:
	var known: CharacterQuery = character.peek_character(actor_id)
	if not known.result.ok:
		return BridgeEconomyReplies.PlayerEconomyReply.new(known.result)
	var balance: EconomyReplies.BalanceQuery = economy.peek_balance(actor_id)
	if not balance.result.ok:
		return BridgeEconomyReplies.PlayerEconomyReply.new(balance.result)
	var inventory: EconomyReplies.InventoryQuery = economy.peek_inventory(actor_id)
	if not inventory.result.ok:
		return BridgeEconomyReplies.PlayerEconomyReply.new(inventory.result)
	var goods: Array[Dictionary] = []
	for row: Dictionary in inventory.rows:
		goods.append(row.duplicate())
	return BridgeEconomyReplies.PlayerEconomyReply.new(Result.success(), balance.balance, inventory.weight, inventory.capacity, goods)


## A ordem de compra (`buy`) ou de venda (`sell`) do jogador num mercado: repasse a `EconomyModule.request_trade`, que é ATÔMICO (tudo ou nada; a economia confere dono aberto, estoque, fundos, teto de compra
## e capacidade de peso, e o saldo e os bens só mudam pelo `Ledger` e pelo `GoodsStore`). Só vale para um ator que o `character` conhece: um ID solto, de NPC ou de outro dono (o próprio mercado, por exemplo)
## é recusado antes, com o código do `character`, então a ponte nunca move bens de quem não é o jogador. A resposta traz sempre a chave do texto.
static func trade(character: CharacterModule, economy: EconomyModule, actor_id: int, market_id: int, good_id: String, quantity: int, side: String) -> BridgeEconomyReplies.PlayerTradeReply:
	var known: CharacterQuery = character.peek_character(actor_id)
	if not known.result.ok:
		return BridgeEconomyReplies.PlayerTradeReply.new(known.result, 0, 0, side)
	var traded: EconomyReplies.TradeResult = economy.request_trade(actor_id, market_id, good_id, quantity, side)
	return BridgeEconomyReplies.PlayerTradeReply.new(traded.result, traded.quantity, traded.total, side)
