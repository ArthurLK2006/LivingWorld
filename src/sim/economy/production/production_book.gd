class_name ProductionBook
extends RefCounted
## Os locais de produção da economia (LW-092b; docs/modules/economy.md, seção 6). O `site_id` é o ID do dono do tipo `site` (a conta e o inventário dele são do `Ledger` e do `GoodsStore`). Aqui mora o que é do local: a receita, a equipe
## (`worker_ids`, em ordem crescente), a eficiência, o progresso do lote, o estado (produzindo ou parado, com o MOTIVO) e há quantos dias cada regra de manutenção foi paga. A cada HORA (`hour_step`), por local em ordem de ID: (1) compra do mercado
## do povoado o que falta (insumos dos lotes que a equipe faz e o bem de uma regra vencida), pelo mesmo `TradeEngine`; (2) confere a equipe (`NO_WORKER`), os insumos (`NO_INPUT`) e o espaço (`OUTPUT_FULL`); (4) faz os lotes (`consumed` e `produced`);
## (5) vende ao mercado o produto, até o espaço do teto de compra. O passo 3, a folha de pagamento, é da LW-095 (daí `NO_FUNDS` ainda não existir). Ao FIM DO DIA (`end_of_day`) cada regra de manutenção cujo prazo venceu e cujas peças o local tem é
## paga (as peças são destruídas com o motivo `maintenance`); com regra vencida e não paga a eficiência cai um degrau (nunca abaixo do piso, que é maior que 0), senão sobe um degrau. Eventos só na MUDANÇA de estado. Nunca sorteia nem olha o relógio. O save (`serialize`, `load_from`, `validate`) é do módulo: o bloco `production` da economia.

const NO_WORKER: String = "NO_WORKER"
const NO_INPUT: String = "NO_INPUT"
const OUTPUT_FULL: String = "OUTPUT_FULL"
const REASONS: Array[String] = [NO_WORKER, NO_INPUT, OUTPUT_FULL]
## Id do tipo de dono do local de produção (`owner_kinds.json`).
const KIND_SITE: String = "site"
const FULL_EFFICIENCY_BP: int = 10000
const KEY_SITES: String = "sites"
const KEY_SETTLEMENT: String = "settlement_id"
const KEY_PLACE: String = "place_id"
const KEY_RECIPE: String = "recipe_id"
const KEY_WANTED: String = "workers_wanted"
const KEY_WORKERS: String = "worker_ids"
const KEY_EFFICIENCY: String = "efficiency_bp"
const KEY_PROGRESS: String = "batch_progress_bp"
const KEY_STOPPED: String = "stopped"
const KEY_REASON: String = "reason"
const KEY_UPKEEP: String = "upkeep_days"

var _recipes: Dictionary[String, RecipeDef]
var _params: SiteParams
var _max_order: int
var _book: OwnerBook
var _goods: GoodsStore
var _markets: MarketBook
var _engine: TradeEngine
var _sites: Dictionary[int, Dictionary] = {}


func _init(book: OwnerBook, goods: GoodsStore, markets: MarketBook, engine: TradeEngine, recipes: Dictionary[String, RecipeDef], params: SiteParams, max_order_quantity: int) -> void:
	_book = book
	_goods = goods
	_markets = markets
	_engine = engine
	_recipes = recipes
	_params = params
	_max_order = max_order_quantity


## Registra o local `site_id` (dono do tipo `site` já aberto): produzindo, eficiência cheia, sem equipe, nenhuma regra paga ainda.
func register_site(site_id: int, definition: SiteDef) -> Result:
	if not _book.has_owner(site_id) or _book.kind_of(site_id) != KIND_SITE:
		return Result.failure(EconomyCodes.UNKNOWN_OWNER, "ProductionBook.register_site: o dono %d não existe ou não é do tipo '%s'; esperado um dono desse tipo, já aberto." % [site_id, KIND_SITE])
	if not _recipes.has(definition.recipe_id):
		return Result.failure(EconomyCodes.DATA_INVALID, "ProductionBook.register_site: a receita '%s' do local '%s' não existe; esperada uma de: %s." % [definition.recipe_id, definition.id, ", ".join(_recipes.keys())])
	var upkeep: Dictionary = {}
	for rule: UpkeepRule in _recipes[definition.recipe_id].upkeep:
		upkeep[rule.good_id] = 0
	_sites[site_id] = {KEY_SETTLEMENT: definition.settlement_id, KEY_PLACE: definition.place_id, KEY_RECIPE: definition.recipe_id, KEY_WANTED: definition.workers_wanted, KEY_WORKERS: [], KEY_EFFICIENCY: FULL_EFFICIENCY_BP, KEY_PROGRESS: 0, KEY_STOPPED: false, KEY_REASON: "", KEY_UPKEEP: upkeep}
	return Result.success()


func has_site(site_id: int) -> bool:
	return _sites.has(site_id)


## Os locais, por ID crescente.
func site_ids() -> Array[int]:
	var ids: Array[int] = []
	ids.assign(_sites.keys())
	ids.sort()
	return ids


## O local de produção que ocupa o local `place_id` (`IdGenerator.NO_ID` se nenhum).
func site_at(place_id: String) -> int:
	for site_id: int in site_ids():
		if _sites[site_id][KEY_PLACE] == place_id:
			return site_id
	return IdGenerator.NO_ID


func sites_of(settlement_id: String) -> Array[int]:
	var ids: Array[int] = []
	for site_id: int in site_ids():
		if _sites[site_id][KEY_SETTLEMENT] == settlement_id:
			ids.append(site_id)
	return ids


func assign_worker(site_id: int, worker_id: int) -> Result:
	if not _sites.has(site_id):
		return Result.failure(EconomyCodes.UNKNOWN_OWNER, "ProductionBook.assign_worker: o local de produção %d não existe." % site_id)
	var workers: Array = _sites[site_id][KEY_WORKERS]
	if not workers.has(worker_id):
		workers.append(worker_id)
		workers.sort()
	return Result.success()


## Tira o trabalhador de todo local (morte ou troca de emprego): quem não está em nenhum não é erro.
func remove_worker(worker_id: int) -> void:
	for site_id: int in site_ids():
		(_sites[site_id][KEY_WORKERS] as Array).erase(worker_id)


## Uma cópia do estado do local: o que o `peek_site` mostra.
func state_of(site_id: int) -> Dictionary:
	var state: Dictionary = (_sites.get(site_id, {}) as Dictionary).duplicate(true)
	if not state.is_empty():
		state["running"] = not state[KEY_STOPPED]
	return state


## A HORA de produção de todos os locais; devolve os eventos (`ProductionStopped` e `ProductionResumed`, só na mudança) para quem chama publicar.
func hour_step() -> Array[SimEvent]:
	var events: Array[SimEvent] = []
	for site_id: int in site_ids():
		var state: Dictionary = _sites[site_id]
		var recipe: RecipeDef = _recipes[state[KEY_RECIPE]]
		_buy_what_is_missing(site_id, state, recipe)
		var reason: String = _stop_reason(site_id, state, recipe)
		if reason.is_empty():
			_run_batches(site_id, state, recipe)
		_sell_surplus(site_id, state, recipe)
		var was_stopped: bool = state[KEY_STOPPED]
		state[KEY_STOPPED] = not reason.is_empty()
		state[KEY_REASON] = reason
		if not was_stopped and not reason.is_empty():
			events.append(ProductionStopped.new(site_id, state[KEY_SETTLEMENT], state[KEY_RECIPE], reason))
		elif was_stopped and reason.is_empty():
			events.append(ProductionResumed.new(site_id, state[KEY_SETTLEMENT], state[KEY_RECIPE]))
	return events


## O FIM DO DIA: paga a manutenção vencida de quem tem as peças e move a eficiência um degrau.
func end_of_day() -> void:
	for site_id: int in site_ids():
		var state: Dictionary = _sites[site_id]
		var unpaid_due: bool = false
		var upkeep: Dictionary = state[KEY_UPKEEP]
		for rule: UpkeepRule in _recipes[state[KEY_RECIPE]].upkeep:
			var days: int = int(upkeep[rule.good_id]) + 1
			if days >= rule.period_days:
				if _goods.destroy(site_id, rule.good_id, rule.quantity, GoodsStore.REASON_MAINTENANCE).ok:
					days = 0
				else:
					unpaid_due = true
			upkeep[rule.good_id] = days
		var efficiency: int = state[KEY_EFFICIENCY]
		state[KEY_EFFICIENCY] = maxi(_params.min_efficiency_bp, efficiency - _params.efficiency_step_bp) if unpaid_due else mini(FULL_EFFICIENCY_BP, efficiency + _params.efficiency_recover_bp)


func is_pristine() -> bool:
	return _sites.is_empty()


func serialize() -> Dictionary:
	var sites: Dictionary = {}
	for site_id: int in site_ids():
		sites[str(site_id)] = _sites[site_id].duplicate(true)
	return {KEY_SITES: sites}


## Confere tudo antes de alterar o estado: o local é um dono do tipo `site`, a receita existe, a equipe é uma lista de IDs sem repetição, a eficiência está entre o piso e 10000, o progresso é menor que um lote, o estado e o motivo
## combinam e as regras de manutenção são exatamente as da receita. Se algo for inválido, o livro fica como estava.
func load_from(data: Dictionary) -> Result:
	var raw_sites: Variant = data.get(KEY_SITES)
	if typeof(raw_sites) != TYPE_DICTIONARY:
		return _invalid_save("campo '%s' ausente ou não é um objeto" % KEY_SITES)
	var sites: Dictionary[int, Dictionary] = {}
	var places: Dictionary[String, int] = {}
	var raw_table: Dictionary = raw_sites
	for key: Variant in raw_table.keys():
		var site_id: int = EconomyJson.id_of_key(key)
		var parsed: Variant = _parse_site(site_id, raw_table[key])
		if typeof(parsed) == TYPE_STRING:
			return _invalid_save("local '%s': %s" % [str(key), str(parsed)])
		var state: Dictionary = parsed
		if places.has(state[KEY_PLACE]):
			return _invalid_save("local '%s': o local '%s' já tem um local de produção (%d)" % [str(key), state[KEY_PLACE], places[state[KEY_PLACE]]])
		places[state[KEY_PLACE]] = site_id
		sites[site_id] = state
	_sites = sites
	return Result.success()


func validate() -> Array[String]:
	var problems: Array[String] = []
	for site_id: int in site_ids():
		if not _book.has_owner(site_id) or _book.kind_of(site_id) != KIND_SITE:
			problems.append("o local de produção %d não é um dono do tipo '%s'" % [site_id, KIND_SITE])
	return problems


func _market_of(state: Dictionary) -> int:
	return _markets.market_of(state[KEY_SETTLEMENT])


func _batches_by_workers(state: Dictionary, recipe: RecipeDef) -> int:
	return mini(recipe.max_batches_per_hour, IntMath.floor_div((state[KEY_WORKERS] as Array).size(), recipe.workers_per_batch))


## (1) Compra o que falta: os insumos dos lotes que a equipe faz e o bem de uma regra de manutenção vencida.
func _buy_what_is_missing(site_id: int, state: Dictionary, recipe: RecipeDef) -> void:
	var market_id: int = _market_of(state)
	if market_id == IdGenerator.NO_ID:
		return
	var batches: int = _batches_by_workers(state, recipe)
	for good_id: String in _sorted(recipe.inputs):
		_buy(site_id, market_id, good_id, recipe.inputs[good_id] * batches - _goods.quantity_of(site_id, good_id))
	var upkeep: Dictionary = state[KEY_UPKEEP]
	for rule: UpkeepRule in recipe.upkeep:
		if int(upkeep[rule.good_id]) >= rule.period_days:
			_buy(site_id, market_id, rule.good_id, rule.quantity - _goods.quantity_of(site_id, rule.good_id))


## Compra `missing` unidades em ordens de até a ordem máxima; para na primeira que falhar (o que falta aparece como `NO_INPUT` ou como manutenção não paga).
func _buy(site_id: int, market_id: int, good_id: String, missing: int) -> void:
	var left: int = missing
	while left > 0:
		var quantity: int = mini(left, _max_order)
		if not _engine.execute(site_id, market_id, good_id, quantity, TradeEngine.SIDE_BUY).result.ok:
			return
		left -= quantity


## (2) Por que o local não produz nesta hora (texto vazio = produz): equipe, insumos de um lote e espaço para os produtos de um lote.
func _stop_reason(site_id: int, state: Dictionary, recipe: RecipeDef) -> String:
	if _batches_by_workers(state, recipe) < 1:
		return NO_WORKER
	for good_id: String in recipe.inputs:
		if _goods.quantity_of(site_id, good_id) < recipe.inputs[good_id]:
			return NO_INPUT
	if not _goods.has_room_for(site_id, recipe.outputs):
		return OUTPUT_FULL
	return ""


## (4) Soma `eficiência × lotes por hora` ao progresso e faz um lote por 10000 acumulados, até onde os insumos e o espaço deixam; o resto passa para a hora seguinte.
func _run_batches(site_id: int, state: Dictionary, recipe: RecipeDef) -> void:
	var progress: int = int(state[KEY_PROGRESS]) + int(state[KEY_EFFICIENCY]) * _batches_by_workers(state, recipe)
	while progress >= FULL_EFFICIENCY_BP and _batch_is_possible(site_id, recipe):
		for good_id: String in recipe.inputs:
			_goods.destroy(site_id, good_id, recipe.inputs[good_id], GoodsStore.REASON_CONSUMED)
		for good_id: String in recipe.outputs:
			_goods.create(site_id, good_id, recipe.outputs[good_id], GoodsStore.REASON_PRODUCED)
		progress -= FULL_EFFICIENCY_BP
	state[KEY_PROGRESS] = mini(progress, FULL_EFFICIENCY_BP - 1)


func _batch_is_possible(site_id: int, recipe: RecipeDef) -> bool:
	for good_id: String in recipe.inputs:
		if _goods.quantity_of(site_id, good_id) < recipe.inputs[good_id]:
			return false
	var freed: int = 0
	for good_id: String in recipe.inputs:
		freed += recipe.inputs[good_id] * _goods_weight(good_id)
	var needed: int = 0
	for good_id: String in recipe.outputs:
		needed += recipe.outputs[good_id] * _goods_weight(good_id)
	return _goods.weight_of(site_id) - freed + needed <= _goods.capacity_of(site_id)


func _goods_weight(good_id: String) -> int:
	return _goods.weight_per_unit(good_id)


## (5) Vende ao mercado do povoado o produto que o local tem, até o espaço que o teto de compra deixa; o que sobra fica no inventário do local.
func _sell_surplus(site_id: int, state: Dictionary, recipe: RecipeDef) -> void:
	var market_id: int = _market_of(state)
	if market_id == IdGenerator.NO_ID:
		return
	for good_id: String in _sorted(recipe.outputs):
		var space: int = _markets.buy_cap_of(market_id, good_id) - _goods.quantity_of(market_id, good_id)
		var left: int = mini(_goods.quantity_of(site_id, good_id), space)
		while left > 0:
			var quantity: int = mini(left, _max_order)
			if not _engine.execute(site_id, market_id, good_id, quantity, TradeEngine.SIDE_SELL).result.ok:
				return
			left -= quantity


func _sorted(table: Dictionary[String, int]) -> Array[String]:
	var keys: Array[String] = []
	keys.assign(table.keys())
	keys.sort()
	return keys


## Devolve o estado montado, ou o TEXTO do problema (o chamador o prefixa com o local).
func _parse_site(site_id: int, raw_entry: Variant) -> Variant:
	if not _book.has_owner(site_id) or _book.kind_of(site_id) != KIND_SITE or typeof(raw_entry) != TYPE_DICTIONARY:
		return "esperado o ID de um dono do tipo '%s' e um objeto" % KIND_SITE
	var entry: Dictionary = raw_entry
	var recipe_id: Variant = entry.get(KEY_RECIPE)
	if typeof(recipe_id) != TYPE_STRING or not _recipes.has(str(recipe_id)):
		return "'%s' deve ser o id de uma receita (%s)" % [KEY_RECIPE, ", ".join(_recipes.keys())]
	var recipe: RecipeDef = _recipes[str(recipe_id)]
	for field: String in [KEY_SETTLEMENT, KEY_PLACE]:
		if typeof(entry.get(field)) != TYPE_STRING or str(entry[field]).is_empty():
			return "'%s' deve ser texto não vazio" % field
	for field: String in [KEY_WANTED, KEY_EFFICIENCY, KEY_PROGRESS]:
		if not EconomyJson.is_int_like(entry.get(field)):
			return "'%s' deve ser um inteiro" % field
	var wanted: int = EconomyJson.to_int(entry[KEY_WANTED])
	var efficiency: int = EconomyJson.to_int(entry[KEY_EFFICIENCY])
	var progress: int = EconomyJson.to_int(entry[KEY_PROGRESS])
	if wanted < 1 or efficiency < _params.min_efficiency_bp or efficiency > FULL_EFFICIENCY_BP or progress < 0 or progress >= FULL_EFFICIENCY_BP:
		return "'%s' deve ser 1 ou mais, '%s' de %d a %d e '%s' de 0 a %d" % [KEY_WANTED, KEY_EFFICIENCY, _params.min_efficiency_bp, FULL_EFFICIENCY_BP, KEY_PROGRESS, FULL_EFFICIENCY_BP - 1]
	var stopped: Variant = entry.get(KEY_STOPPED)
	var reason: Variant = entry.get(KEY_REASON)
	if typeof(stopped) != TYPE_BOOL or typeof(reason) != TYPE_STRING or bool(stopped) != REASONS.has(str(reason)) or (not bool(stopped) and not str(reason).is_empty()):
		return "'%s' deve ser verdadeiro ou falso e '%s' um motivo de %s só quando parado" % [KEY_STOPPED, KEY_REASON, ", ".join(REASONS)]
	var workers: Array[int] = []
	var raw_workers: Variant = entry.get(KEY_WORKERS)
	if typeof(raw_workers) != TYPE_ARRAY:
		return "'%s' deve ser uma lista de IDs" % KEY_WORKERS
	for raw_worker: Variant in raw_workers:
		if not EconomyJson.is_int_like(raw_worker) or EconomyJson.to_int(raw_worker) < IdGenerator.FIRST_ID or (workers.size() > 0 and EconomyJson.to_int(raw_worker) <= workers[workers.size() - 1]):
			return "'%s' deve ter IDs inteiros positivos, em ordem crescente e sem repetição" % KEY_WORKERS
		workers.append(EconomyJson.to_int(raw_worker))
	var raw_upkeep: Variant = entry.get(KEY_UPKEEP)
	if typeof(raw_upkeep) != TYPE_DICTIONARY or (raw_upkeep as Dictionary).size() != recipe.upkeep.size():
		return "'%s' deve ter exatamente as %d regras de manutenção da receita" % [KEY_UPKEEP, recipe.upkeep.size()]
	var upkeep: Dictionary = {}
	for rule: UpkeepRule in recipe.upkeep:
		var days: Variant = (raw_upkeep as Dictionary).get(rule.good_id)
		if not EconomyJson.is_int_like(days) or EconomyJson.to_int(days) < 0:
			return "'%s' deve ter um inteiro de 0 ou mais para '%s'" % [KEY_UPKEEP, rule.good_id]
		upkeep[rule.good_id] = EconomyJson.to_int(days)
	return {KEY_SETTLEMENT: str(entry[KEY_SETTLEMENT]), KEY_PLACE: str(entry[KEY_PLACE]), KEY_RECIPE: str(recipe_id), KEY_WANTED: wanted, KEY_WORKERS: workers, KEY_EFFICIENCY: efficiency, KEY_PROGRESS: progress, KEY_STOPPED: bool(stopped), KEY_REASON: str(reason), KEY_UPKEEP: upkeep}


func _invalid_save(detail: String) -> Result:
	return Result.failure(EconomyCodes.INVALID_SAVE, "ProductionBook.load_from: %s." % detail)
