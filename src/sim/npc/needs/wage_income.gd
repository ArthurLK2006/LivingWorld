class_name WageIncome
extends RefCounted
## O `npc` ouve o salário (LW-095; docs/modules/npc.md, 14.4; DEC-152): a cada `WagesPaid` (UM por local de trabalho e por hora, publicado pela economia) alivia a necessidade `income` DOS NPCs DELE que trabalham ali, em proporção ao
## salário de cada um (`amount_each`). A lista de trabalhadores vem da porta da economia (`peek_site` do local de produção ou `peek_post` do posto, em ordem de ID); NPC que o `npc` não conhece (ou morto) é ignorado. O alívio entra levando as
## necessidades até o minuto atual (`NeedMath.settle`) e somando a pressão negativa (`NeedMath.add_pressure`, limitada a 0..100), como o alarme faz com `safety`. O `npc` nunca cria nem move dinheiro: só lê a economia e mexe no que é dele.
## Hora parada (sem folha) não gera evento e `income` volta a subir pela taxa da própria necessidade. Desde a LW-095f é o ÚNICO alívio da `income` (a renda simbólica provisória saiu).

const NEED_ID: String = "income"
## [HIP] Pontos de `income` aliviados por moeda de salário. Com 1, o salário de 2 por hora anula a subida de 2 por hora da necessidade (data/needs.json). Passa para `data/` com a distribuição dos povoados.
const RELIEF_PER_COIN: int = 1

var _npcs: Dictionary[int, NpcState]
var _need_defs: Array[NeedDef]
var _economy: EconomyModule


func _init(npcs: Dictionary[int, NpcState], need_defs: Array[NeedDef], economy: EconomyModule) -> void:
	_npcs = npcs
	_need_defs = need_defs
	_economy = economy


## Reação ao `WagesPaid`; `now` é o minuto atual da simulação. Desde a LW-094b (PROPOSTA) alivia só os da lista dos pagos do evento quando ela vem preenchida (folha parcial); vazia, todos os do local, como antes. Evento de outro tipo, sem economia ou sem a necessidade `income` nas definições: não faz nada.
func on_wages_paid(event: SimEvent, now: int) -> void:
	var paid: WagesPaid = event as WagesPaid
	if paid == null or _economy == null:
		return
	var workers: Array[int] = paid.paid_worker_ids if not paid.paid_worker_ids.is_empty() else _workers_of(paid.workplace_id)
	for worker_id: int in workers:
		var state: NpcState = _npcs.get(worker_id)
		relieve_coins(state, paid.amount_each, now)


## Alivia `income` de UM NPC em `coins` moedas (`RELIEF_PER_COIN` pontos por moeda): o salário do `WagesPaid` e, desde a LW-098g, o lucro realizado de uma viagem (`MerchantArrival`). É o escritor de `income` do `npc` fora das ações: um só
## lugar para a conta. NPC nulo, morto ou sem como levar as necessidades até `now`: não faz nada.
func relieve_coins(state: NpcState, coins: int, now: int) -> void:
	if state == null or not state.is_alive or not NeedMath.settle(state, _need_defs, now).ok:
		return
	NeedMath.add_pressure(state, _need_defs, NEED_ID, -(coins * RELIEF_PER_COIN))


## Os trabalhadores do local de trabalho (o `site_id` ou o `post_id`), em ordem crescente; lista vazia se nenhum dos dois existe.
func _workers_of(workplace_id: int) -> Array[int]:
	var site: EconomyReplies.SiteQuery = _economy.peek_site(workplace_id)
	if site.result.ok:
		return site.worker_ids
	var post: EconomyReplies.PostQuery = _economy.peek_post(workplace_id)
	return post.worker_ids if post.result.ok else ([] as Array[int])
