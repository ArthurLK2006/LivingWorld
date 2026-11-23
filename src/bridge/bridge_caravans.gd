class_name BridgeCaravans
extends RefCounted
## A conta da consulta das caravanas da ponte (LW-099b1; contrato da LW-099, seção 6, PROPOSTO no PR #158: docs/economia/contrato-lw-099-viagem-visivel.md). O `SimBridge` só delega para cá, porque ele já passa de 300 linhas. Sem estado e sem regra de jogo: só LÊ o módulo `economy` por consultas (`peek_caravans`, `peek_good`,
## `peek_inventory`) e usa a fração de passo do relógio que quem chama entrega, e devolve CÓPIAS com tipos da ponte, para a apresentação nunca citar tipo de `sim/`. Quem confere a ponte sem jogo ou sem `economy` é o `SimBridge`, antes de chamar. Só cita classes de `src/sim/economy/api/`
## (a regra D do `tools/check_architecture` confere). Nenhuma escrita: nem `request_*`, nem evento, nem estado; o ponto no mundo (a estrada), a altura do terreno e o alcance são da apresentação.

## O milésimo cheio da faixa de carga (o lote enche o carrinho).
const FULL_PERMILLE: int = 1000


## Uma cópia por caravana da economia (todas: andando, paradas no meio do trecho e paradas num povoado), em ordem crescente de `trader_id`. `step_fraction`: a fração de passo do relógio (`SimClock.step_fraction`), em [0, 1), que só entra na fração `u` de quem anda.
static func bodies(economy: EconomyModule, step_fraction: float) -> BridgeReplies.CaravanBodiesReply:
	var copies: Array[BridgeReplies.CaravanBodyReply] = []
	for row: CaravanReplies.CaravanQuery in economy.peek_caravans().caravans:
		var body: BridgeReplies.CaravanBodyReply = BridgeReplies.CaravanBodyReply.new()
		body.trader_id = row.trader_id
		body.route_id = row.current_route_id
		body.from_settlement_id = row.leg_from_settlement_id
		body.to_settlement_id = row.leg_to_settlement_id
		body.state = row.state
		body.u = progress_of(row, step_fraction)
		body.good_id = row.good_id
		body.quantity = row.quantity
		body.load_permille = load_permille_of(economy, row)
		copies.append(body)
	return BridgeReplies.CaravanBodiesReply.new(Result.success(), copies)


## A fração `u` do trecho já andada: `(minutos andados + fração de passo) ÷ duração do trecho`, cortada em [0, 1]. Parada (`held`) vale `minutos andados ÷ duração`, FIXA: a fração de passo não conta (a caravana não anda). Sem a duração do trecho (economia sem a porta de rotas) vale 0.
static func progress_of(row: CaravanReplies.CaravanQuery, step_fraction: float) -> float:
	if row.leg_minutes < 1:
		return 0.0
	var walked: float = float(row.leg_walked_min)
	if row.state == BridgeReplies.CaravanBodyReply.STATE_TRAVELLING:
		walked += step_fraction
	return clampf(walked / float(row.leg_minutes), 0.0, 1.0)


## A faixa de carga em milésimos, de 0 a 1000: `quantity` do lote vezes o peso unitário do bem, sobre a capacidade de peso do comerciante (as duas vêm da economia: `peek_good` e `peek_inventory`; nada fixo aqui). Inteiros, sem a contagem exata. Bem ou comerciante que a economia não conhece, ou capacidade menor que 1: 0.
static func load_permille_of(economy: EconomyModule, row: CaravanReplies.CaravanQuery) -> int:
	var good: EconomyReplies.GoodQuery = economy.peek_good(row.good_id)
	var inventory: EconomyReplies.InventoryQuery = economy.peek_inventory(row.trader_id)
	if not good.result.ok or not inventory.result.ok or inventory.capacity < 1:
		return 0
	return clampi(IntMath.floor_div(FULL_PERMILLE * row.quantity * good.weight, inventory.capacity), 0, FULL_PERMILLE)
