class_name ContractPoster
extends RefCounted
## O postador de contratos de entrega (LW-107c2; docs/modules/economy.md, seção 8, e docs/economy/dados.md): a cada hora cheia, por mercado (ID crescente) e por modelo de `contract_templates.json` (`id` crescente), a PRÓPRIA economia posta UM contrato
## `delivery` cujo emissor e destino são o mercado, quando o gatilho vale (`shortage`: a escassez declarada no mercado; `standing`: sempre), há espaço (`max_open` em `open` ou `accepted`) e a proteção contra exploração permite: a recompensa NÃO passa do `ask`
## de hoje do bem naquele mercado vezes a quantidade (regra (b): comprar no emissor e entregar no mesmo mercado nunca dá lucro NA HORA DE POSTAR). Funções estáticas sobre o `EconomyState`, sem sorteio e sem estado próprio: o "já existe" sai do
## `ContractBook`, que já é salvo. O contrato já postado não é cancelado quando o gatilho deixa de valer. Recusa do livro (por exemplo, mercado sem fundos) ou regra (b) violada: não posta, NÃO gasta ID e tenta de novo na hora seguinte, em silêncio.
## O aceite não ganha restrição nova. O prazo conta do INÍCIO da hora cheia da publicação (`agora - agora % 60`), não do minuto em que o evento horário é processado (60, 63 ou 60 com passos de 1, 7 ou 60 minutos): o prazo e o hash do mundo
## ficam iguais com qualquer passo (decisão de Arthur de 15/11/2026). Sem modelo (o padrão do jogo, por ora) sai na hora, sem tocar em nada.


## A conferência da hora (`now` é o minuto de simulação): depois das vagas, um contrato vencido nesta hora já abriu espaço para o próximo.
static func post_due(state: EconomyState, ids: IdGenerator, events: EventBus, now: int) -> void:
	var templates: Array[ContractTemplateDef] = []
	templates.assign(state.definitions.contract_templates)
	if templates.is_empty() or state.markets == null:
		return
	templates.sort_custom(func(left: ContractTemplateDef, right: ContractTemplateDef) -> bool: return left.id < right.id)
	var open_counts: Dictionary[String, int] = _open_counts(state)
	for market_id: int in state.markets.market_ids():
		for template: ContractTemplateDef in templates:
			_post_if_due(state, ids, events, now, market_id, template, open_counts)


## Os contratos `delivery` em `open` ou `accepted` por mercado e bem (é "do modelo" o que tem emissor e destino iguais ao mercado e o `good_id` do modelo): uma só passada pelo livro por hora.
static func _open_counts(state: EconomyState) -> Dictionary[String, int]:
	var counts: Dictionary[String, int] = {}
	for contract_id: int in state.contracts.contract_ids():
		var contract: Dictionary = state.contracts.state_of(contract_id)
		var is_live: bool = contract[ContractBook.KEY_STATE] == ContractBook.STATE_OPEN or contract[ContractBook.KEY_STATE] == ContractBook.STATE_ACCEPTED
		if contract[ContractBook.KEY_KIND] != ContractBook.DELIVERY or not is_live or contract[ContractBook.KEY_ISSUER] != contract[ContractBook.KEY_DESTINATION]:
			continue
		var key: String = _key(int(contract[ContractBook.KEY_ISSUER]), str(contract[ContractBook.KEY_GOOD]))
		counts[key] = int(counts.get(key, 0)) + 1
	return counts


static func _key(market_id: int, good_id: String) -> String:
	return "%d|%s" % [market_id, good_id]


static func _post_if_due(state: EconomyState, ids: IdGenerator, events: EventBus, now: int, market_id: int, template: ContractTemplateDef, open_counts: Dictionary[String, int]) -> void:
	var good_id: String = template.good_id
	if not state.markets.is_traded(market_id, good_id):
		return
	if template.trigger == ContractTemplateDef.TRIGGER_SHORTAGE and not state.markets.is_in_shortage(market_id, good_id):
		return
	var key: String = _key(market_id, good_id)
	if int(open_counts.get(key, 0)) >= template.max_open:
		return
	var reward: int = _reward_of(state, template)
	if reward > state.markets.ask_of(market_id, good_id) * template.quantity:
		return
	var hour_start: int = now - now % SimClock.MINUTES_PER_HOUR
	var deadline: int = hour_start + template.deadline_hours * SimClock.MINUTES_PER_HOUR
	var objective: Dictionary = {ContractBook.KEY_GOOD: good_id, ContractBook.KEY_QUANTITY: template.quantity, ContractBook.KEY_DESTINATION: market_id}
	if not state.contracts.check_post(ContractBook.DELIVERY, market_id, reward, deadline, now, objective).ok:
		return
	var contract_id: int = ids.next_id()
	if state.contracts.post(contract_id, ContractBook.DELIVERY, market_id, reward, deadline, now, objective).ok:
		open_counts[key] = int(open_counts.get(key, 0)) + 1
		events.publish(ContractOffered.new(contract_id, ContractBook.DELIVERY, market_id, reward, deadline))


## `ceil_div(quantity × base_value × (10000 + reward_margin_bp), 10000)`, com o valor-base do bem em `goods.json` (0 se o bem não existe: o carregador já recusa esse modelo).
static func _reward_of(state: EconomyState, template: ContractTemplateDef) -> int:
	for good: GoodDef in state.definitions.goods:
		if good.id == template.good_id:
			return PriceMath.ceil_div(template.quantity * good.base_value * (PriceMath.BASIS + template.reward_margin_bp), PriceMath.BASIS)
	return 0
