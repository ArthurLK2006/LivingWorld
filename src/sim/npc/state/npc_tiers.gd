class_name NpcTiers
extends RefCounted
## Promoção e rebaixamento entre T1 (cidadão) e T2 (notável) (LW-077; contrato em docs/modules/npc.md, seção 7). Funções sem estado próprio: o
## `NpcModule` entrega o NPC, a contagem de notáveis vivos e o teto, e este arquivo decide e muda SÓ o `tier`; por isso identidade, ofício,
## rotina e ação em andamento ficam como estavam. Hoje ser T2 ainda não muda o comportamento: memória e relações chegam nas LW-078 e LW-079,
## que usam o ponto de extensão `on_demote` (resumir em traços ao rebaixar). Não existe T3 nesta fase.

const CODE_INVALID_TIER: String = "NPC_INVALID_TIER"
const CODE_DEAD: String = "NPC_DEAD"
const CODE_T2_LIMIT_REACHED: String = "NPC_T2_LIMIT_REACHED"


## Quantos NPCs VIVOS são notáveis (T2): é o que o teto limita, e a morte libera a vaga.
static func count_notable_alive(states: Dictionary[int, NpcState]) -> int:
	var count: int = 0
	for state: NpcState in states.values():
		if state.is_alive and state.tier == NpcState.TIER_NOTABLE:
			count += 1
	return count


## Cabe mais um notável? `max_t2` 0 = sem teto configurado (o padrão dos testes); com teto, cabe enquanto houver menos notáveis que ele.
static func has_room(notable_alive: int, max_t2: int) -> bool:
	return max_t2 <= 0 or notable_alive < max_t2


## Promove de T1 a T2. `to_tier` precisa ser T2. NPC morto é recusado; NPC que já é T2 não precisa de nada (sucesso, sem gastar vaga). Com o
## teto cheio recusa com `NPC_T2_LIMIT_REACHED` e NÃO expulsa ninguém [PROPOSTA, Q10].
static func promote(state: NpcState, to_tier: int, notable_alive: int, max_t2: int) -> Result:
	if to_tier != NpcState.TIER_NOTABLE:
		return Result.failure(CODE_INVALID_TIER, "NpcTiers.promote: tier de destino %d; esperado %d (T2), a única promoção que existe nesta fase." % [to_tier, NpcState.TIER_NOTABLE])
	if not state.is_alive:
		return Result.failure(CODE_DEAD, "NpcTiers.promote: o NPC %d está morto; esperado um NPC vivo." % state.npc_id)
	if state.tier == NpcState.TIER_NOTABLE:
		return Result.success()
	if not has_room(notable_alive, max_t2):
		return Result.failure(CODE_T2_LIMIT_REACHED, "NpcTiers.promote: já há %d NPC(s) notável(is) vivo(s) e o teto (max_t2) é %d; o NPC %d continua T1 e ninguém foi rebaixado." % [notable_alive, max_t2, state.npc_id])
	state.tier = NpcState.TIER_NOTABLE
	return Result.success()


## Rebaixa de T2 a T1. `to_tier` precisa ser T1. NPC morto é recusado; NPC que já é T1 não precisa de nada (sucesso, sem chamar o ponto de
## extensão). Rebaixamento de verdade: chama `on_demote(npc_id)` ANTES de mudar o tier (o NPC ainda é notável, então a LW-078 e a LW-079
## ainda enxergam memória e relações para resumir em traços) e só então muda. `on_demote` inválido (nenhum) = não faz nada.
static func demote(state: NpcState, to_tier: int, on_demote: Callable) -> Result:
	if to_tier != NpcState.TIER_NORMAL:
		return Result.failure(CODE_INVALID_TIER, "NpcTiers.demote: tier de destino %d; esperado %d (T1), o único rebaixamento que existe nesta fase." % [to_tier, NpcState.TIER_NORMAL])
	if not state.is_alive:
		return Result.failure(CODE_DEAD, "NpcTiers.demote: o NPC %d está morto; esperado um NPC vivo." % state.npc_id)
	if state.tier == NpcState.TIER_NORMAL:
		return Result.success()
	if on_demote.is_valid():
		on_demote.call(state.npc_id)
	state.tier = NpcState.TIER_NORMAL
	return Result.success()


## Problema do teto para o `validate()` (texto vazio se está tudo certo): mais notáveis vivos que o teto configurado.
static func limit_problem(notable_alive: int, max_t2: int) -> String:
	if max_t2 > 0 and notable_alive > max_t2:
		return "Há %d NPCs notáveis (T2) vivos, mais que o teto max_t2 %d." % [notable_alive, max_t2]
	return ""
