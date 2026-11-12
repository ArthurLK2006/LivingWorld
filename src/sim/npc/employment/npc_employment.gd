class_name NpcEmployment
extends RefCounted
## O NPC aceita vaga (LW-096a; docs/modules/npc.md, 14.4; DEC-165 e DEC-169): quando a economia publica `ContractOffered` de uma `vacancy`, os NPCs do mesmo povoado a pontuam PELA UTILIDADE e o melhor candidato a aceita
## (`request_accept_contract`); aceitar muda o `work_place_id` dele NA MESMA PASSAGEM (um dono por dado: o `npc` é dono do `work_place_id`, a economia da lista de trabalhadores). Utilidade da vaga = o salário por hora vezes as horas
## pagas por dia, menos o custo da caminhada de casa ao trabalho (o custo de distância dos parâmetros), mais o bônus de trabalhar no próprio ofício. O desempregado aceita se a utilidade é positiva; o empregado só TROCA se a utilidade da vaga passar
## da do emprego atual por mais que a HISTERESE (senão dois locais de salário parecido passariam o mesmo NPC de um para o outro em laço); o emprego só termina por morte (`NpcDied`; a economia tira o NPC da lista e a vaga reaparece) ou por
## aceitar outra vaga. Empate: o menor ID (nunca sorteia). Só lê a economia pela porta (`economy/api`) e mexe no que é do `npc`. As constantes abaixo são [HIP] e ficam NOMEADAS no código (nenhum dado novo nesta tarefa).

const VACANCY_KIND: String = "vacancy"
const OPEN_STATE: String = "open"
## [HIP] Horas pagas por dia que o salário por hora vale na utilidade (o local só paga nas horas em que produz; a incerteza pesa aqui, npc.md 14.4).
const PAID_HOURS_PER_DAY: int = 8
## [HIP] Caminhadas de casa ao trabalho por dia (ida e volta) que o custo de distância pesa.
const COMMUTES_PER_DAY: int = 2
## [HIP] Bônus de utilidade por trabalhar no próprio ofício (a economia não obriga o ofício esperado).
const OCCUPATION_MATCH_BONUS: int = 10
## [HIP] Quanto a utilidade da vaga precisa passar da do emprego atual para o NPC trocar de emprego (histerese).
const HYSTERESIS: int = 20
const CM_PER_100_M: int = 10000

var _npcs: Dictionary[int, NpcState]
var _economy: EconomyModule
var _places: SettlementService
var _params: NpcParams


## `places` e `params` podem ser nulos (módulo sem definições): então a distância não pesa.
func _init(npcs: Dictionary[int, NpcState], economy: EconomyModule, places: SettlementService, params: NpcParams) -> void:
	_npcs = npcs
	_economy = economy
	_places = places
	_params = params


## Reação ao `ContractOffered`: só a vaga interessa.
func on_contract_offered(event: SimEvent) -> void:
	var offered: ContractOffered = event as ContractOffered
	if offered != null and offered.kind == VACANCY_KIND:
		consider(offered.contract_id)


## Pontua a vaga para cada NPC vivo do povoado, em ordem de ID, e o melhor candidato a aceita. A vaga que não existe, não está aberta ou não é vaga não faz nada; uma recusa da economia (a vaga foi preenchida) também não.
func consider(contract_id: int) -> void:
	var vacancy: EconomyReplies.ContractQuery = _economy.peek_contract(contract_id)
	if not vacancy.result.ok or vacancy.kind != VACANCY_KIND or vacancy.state != OPEN_STATE:
		return
	var best_id: int = IdGenerator.NO_ID
	var best_margin: int = 0
	for npc_id: int in _sorted_ids():
		var state: NpcState = _npcs[npc_id]
		if not state.is_alive or state.settlement_id != vacancy.settlement_id:
			continue
		var candidate: int = _utility(state, vacancy.place_id, vacancy.wage_per_hour, vacancy.occupation_id)
		var current: Employment = _current_employment(state)
		var margin: int = candidate - current.utility
		var needed: int = HYSTERESIS if current.employed else 0
		if candidate > 0 and margin > needed and margin > best_margin:
			best_id = npc_id
			best_margin = margin
	if best_id == IdGenerator.NO_ID:
		return
	if _economy.request_accept_contract(contract_id, best_id).ok:
		_npcs[best_id].work_place_id = vacancy.place_id


## A utilidade de trabalhar no local `place_id` com salário `wage_per_hour` e ofício esperado `occupation_id` para o NPC (inteiro; pode ser negativa).
func _utility(state: NpcState, place_id: String, wage_per_hour: int, occupation_id: String) -> int:
	var utility: int = wage_per_hour * PAID_HOURS_PER_DAY - _commute_cost(state, place_id)
	if state.occupation_id == occupation_id:
		utility += OCCUPATION_MATCH_BONUS
	return utility


## O custo da caminhada de casa ao local de trabalho, por dia: a distância (cm) vezes o custo por 100 m dos parâmetros, vezes as caminhadas por dia. Sem lugares ou parâmetros, 0.
func _commute_cost(state: NpcState, place_id: String) -> int:
	if _places == null or _params == null or state.home_place_id.is_empty():
		return 0
	var home: SettlementService.PlaceQuery = _places.peek_place(state.home_place_id)
	var work: SettlementService.PlaceQuery = _places.peek_place(place_id)
	if not home.result.ok or not work.result.ok:
		return 0
	var delta_x: int = roundi((home.place.position.x - work.place.position.x) * TerrainData.CM_PER_METER)
	var delta_z: int = roundi((home.place.position.z - work.place.position.z) * TerrainData.CM_PER_METER)
	var distance_cm: int = ceili(sqrt(float(delta_x * delta_x + delta_z * delta_z)))
	return IntMath.floor_div(distance_cm * _params.distance_cost_per_100m * COMMUTES_PER_DAY, CM_PER_100_M)


## O emprego de agora: se a economia lista o NPC na equipe do local de produção ou do posto do `work_place_id` dele, a utilidade desse emprego; senão ele está desempregado (utilidade 0).
func _current_employment(state: NpcState) -> Employment:
	var employment: Employment = Employment.new()
	if state.work_place_id.is_empty():
		return employment
	var site: EconomyReplies.SiteQuery = _economy.peek_site_at(state.work_place_id)
	if site.result.ok and site.worker_ids.has(state.npc_id):
		employment.employed = true
		employment.utility = _utility(state, site.place_id, site.wage_per_hour, site.occupation_id)
		return employment
	var post: EconomyReplies.PostQuery = _economy.peek_post_at(state.work_place_id)
	if post.result.ok and post.worker_ids.has(state.npc_id):
		employment.employed = true
		employment.utility = _utility(state, post.place_id, post.wage_per_hour, post.occupation_id)
	return employment


func _sorted_ids() -> Array[int]:
	var ids: Array[int] = []
	ids.assign(_npcs.keys())
	ids.sort()
	return ids


## O emprego atual de um NPC: se há e quanto vale para ele.
class Employment:
	extends RefCounted

	var employed: bool = false
	var utility: int = 0
