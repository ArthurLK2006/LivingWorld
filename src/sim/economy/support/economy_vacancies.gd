class_name EconomyVacancies
extends RefCounted
## As vagas (LW-096; docs/modules/economy.md, seção 8; DEC-165): quando um local de produção ou um posto de serviço tem MENOS trabalhadores atribuídos do que `workers_wanted`, a própria economia posta UMA `vacancy` dele (emissor: o local; sem
## custódia, sem prazo) e publica `ContractOffered`; a cada hora a vaga é conferida de novo (a vaga que não faz mais falta, porque outro NPC preencheu o lugar, falha em silêncio; se ainda falta gente e não há vaga aberta, nasce outra). Quem aceita a vaga é
## um NPC (`request_accept_contract`): `accept` o atribui ao local, TIRA a atribuição anterior (que pode gerar uma vaga lá na hora seguinte), conclui o contrato na hora e devolve o resultado para o `ContractCompleted` sair (recompensa 0). Na Fase 3 não há
## nascimento, então a vaga só nasce depois de uma morte ou de uma troca de emprego. O local sem dinheiro para a folha PARA e NÃO demite ninguém (DEC-169): a equipe continua atribuída e não gera vaga. Funções estáticas sobre o `EconomyState`.

## Tipo do dono que aceita vaga: o NPC (id em `owner_kinds.json`).
const ACTOR_KIND: String = "npc"


## A visão do local de trabalho `workplace_id` (o `site_id` ou o `post_id`): `place_id`, `settlement_id`, `occupation_id`, `wage_per_hour`, `workers_wanted` e `worker_ids`; vazio se não existe nenhum dos dois.
static func workplace_view(state: EconomyState, workplace_id: int) -> Dictionary:
	if state.production != null and state.production.has_site(workplace_id):
		var site: Dictionary = state.production.state_of(workplace_id)
		var recipe: RecipeDef = state.definitions.recipes[site[ProductionBook.KEY_RECIPE]]
		return {"place_id": site[ProductionBook.KEY_PLACE], "settlement_id": site[ProductionBook.KEY_SETTLEMENT], "occupation_id": recipe.occupation_id, "wage_per_hour": recipe.wage_per_hour, "workers_wanted": site[ProductionBook.KEY_WANTED], "worker_ids": site[ProductionBook.KEY_WORKERS]}
	if state.posts != null and state.posts.has_post(workplace_id):
		var post: Dictionary = state.posts.state_of(workplace_id)
		return {"place_id": post[ServicePostBook.KEY_PLACE], "settlement_id": post[ServicePostBook.KEY_SETTLEMENT], "occupation_id": post[ServicePostBook.KEY_OCCUPATION], "wage_per_hour": post[ServicePostBook.KEY_WAGE], "workers_wanted": post[ServicePostBook.KEY_WANTED], "worker_ids": post[ServicePostBook.KEY_WORKERS]}
	return {}


## A conferência da hora: por local de trabalho (os locais de produção e depois os postos, por ID crescente), posta a vaga se falta gente e não há vaga aberta, e deixa falhar a vaga aberta que não faz mais falta.
static func refresh(state: EconomyState, ids: IdGenerator, events: EventBus) -> void:
	var workplaces: Array[int] = []
	if state.production != null:
		workplaces.append_array(state.production.site_ids())
	if state.posts != null:
		workplaces.append_array(state.posts.post_ids())
	for workplace_id: int in workplaces:
		var view: Dictionary = workplace_view(state, workplace_id)
		var missing: int = int(view["workers_wanted"]) - (view["worker_ids"] as Array).size()
		var open_id: int = state.contracts.open_vacancy_of(workplace_id)
		if missing > 0 and open_id == IdGenerator.NO_ID:
			var contract_id: int = ids.next_id()
			if state.contracts.post_vacancy(contract_id, workplace_id).ok:
				events.publish(ContractOffered.new(contract_id, ContractBook.VACANCY, workplace_id, 0, 0))
		elif missing <= 0 and open_id != IdGenerator.NO_ID:
			state.contracts.cancel_vacancy(open_id)


## O NPC aceita a vaga: confere TUDO antes de mudar qualquer coisa e então o atribui ao local, tira a atribuição anterior e conclui o contrato. Falhas: `ECON_UNKNOWN_CONTRACT`, `ECON_CONTRACT_NOT_OPEN`, `ECON_UNKNOWN_OWNER`, `ECON_OWNER_CLOSED`,
## `ECON_CONTRACT_IMPOSSIBLE` (não é NPC, já trabalha ali, a vaga já foi preenchida ou o local não existe mais; nos dois últimos casos a vaga falha).
static func accept(state: EconomyState, contract_id: int, actor_id: int) -> ContractBook.Outcome:
	if not state.contracts.has_contract(contract_id):
		return ContractBook.Outcome.failed(Result.failure(EconomyCodes.UNKNOWN_CONTRACT, "EconomyVacancies.accept: o contrato %d não existe." % contract_id))
	var contract: Dictionary = state.contracts.state_of(contract_id)
	if contract[ContractBook.KEY_STATE] != ContractBook.STATE_OPEN:
		return ContractBook.Outcome.failed(Result.failure(EconomyCodes.CONTRACT_NOT_OPEN, "EconomyVacancies.accept: a vaga %d está '%s'; esperado '%s'." % [contract_id, contract[ContractBook.KEY_STATE], ContractBook.STATE_OPEN]))
	var checked: Result = state.book.check_open(actor_id)
	if not checked.ok:
		return ContractBook.Outcome.failed(checked)
	if state.book.kind_of(actor_id) != ACTOR_KIND:
		return ContractBook.Outcome.failed(Result.failure(EconomyCodes.CONTRACT_IMPOSSIBLE, "EconomyVacancies.accept: o dono %d é do tipo '%s'; só o '%s' aceita vaga." % [actor_id, state.book.kind_of(actor_id), ACTOR_KIND]))
	var workplace_id: int = contract[ContractBook.KEY_WORKPLACE]
	var view: Dictionary = workplace_view(state, workplace_id)
	if view.is_empty():
		state.contracts.cancel_vacancy(contract_id)
		return ContractBook.Outcome.failed(Result.failure(EconomyCodes.CONTRACT_IMPOSSIBLE, "EconomyVacancies.accept: o local de trabalho %d da vaga %d não existe mais." % [workplace_id, contract_id]))
	var workers: Array = view["worker_ids"]
	if workers.has(actor_id):
		return ContractBook.Outcome.failed(Result.failure(EconomyCodes.CONTRACT_IMPOSSIBLE, "EconomyVacancies.accept: o NPC %d já trabalha no local %d." % [actor_id, workplace_id]))
	if int(view["workers_wanted"]) - workers.size() < 1:
		state.contracts.cancel_vacancy(contract_id)
		return ContractBook.Outcome.failed(Result.failure(EconomyCodes.CONTRACT_IMPOSSIBLE, "EconomyVacancies.accept: a vaga %d já foi preenchida (o local %d tem a equipe completa)." % [contract_id, workplace_id]))
	_leave_current_workplace(state, actor_id)
	_assign(state, workplace_id, actor_id)
	return state.contracts.complete_vacancy(contract_id, actor_id)


## Tira o NPC da equipe de todo local de produção e posto (a vaga que isso abre nasce na conferência da hora).
static func _leave_current_workplace(state: EconomyState, actor_id: int) -> void:
	if state.production != null:
		state.production.remove_worker(actor_id)
	if state.posts != null:
		state.posts.remove_worker(actor_id)


static func _assign(state: EconomyState, workplace_id: int, actor_id: int) -> void:
	if state.production != null and state.production.has_site(workplace_id):
		state.production.assign_worker(workplace_id, actor_id)
	elif state.posts != null:
		state.posts.assign_worker(workplace_id, actor_id)
