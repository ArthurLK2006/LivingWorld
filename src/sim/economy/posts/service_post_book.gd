class_name ServicePostBook
extends RefCounted
## Os postos de serviço da economia (LW-095; docs/modules/economy.md, seção 6; DEC-164 e DEC-174): locais de trabalho SEM receita para os ofícios `guard` e `innkeeper`, com a folha paga pela conta do MERCADO do povoado. O `post_id` é um ID do
## `core` (o posto NÃO é dono: não tem conta nem inventário). Aqui mora o que é do posto: assentamento, local, ofício esperado, equipe desejada, salário por hora, trabalhadores (`worker_ids`, em ordem crescente) e o estado (pago ou parado
## por `NO_FUNDS`). A cada HORA (`hour_step`), por posto em ordem de `post_id` e ANTES dos locais de produção (passo 0): o mercado paga `wage_per_hour` a cada trabalhador, tudo ou nada (`WagePayer`, motivo `salary`), e o posto anuncia UM
## `WagesPaid`; se a conta do mercado não cobre a folha DAQUELE posto, ele para por `NO_FUNDS` e ninguém recebe naquela hora (sem evento: o posto não publica `ProductionStopped`). Provisório até a Fase 4, SEM marca `TEMP-LW-` (regra de jogo).
## Nunca sorteia nem olha o relógio.

const NO_FUNDS: String = "NO_FUNDS"
const KEY_POSTS: String = "posts"
const KEY_SETTLEMENT: String = "settlement_id"
const KEY_PLACE: String = "place_id"
const KEY_OCCUPATION: String = "occupation_id"
const KEY_WANTED: String = "workers_wanted"
const KEY_WAGE: String = "wage_per_hour"
const KEY_WORKERS: String = "worker_ids"
const KEY_STOPPED: String = "stopped"

var _markets: MarketBook
var _payer: WagePayer
var _posts: Dictionary[int, Dictionary] = {}


func _init(market_book: MarketBook, wage_payer: WagePayer) -> void:
	_markets = market_book
	_payer = wage_payer


## Registra o posto `post_id`: pago, sem equipe. Falha se o ID ou o local já têm posto.
func register_post(post_id: int, definition: PostDef) -> Result:
	if _posts.has(post_id):
		return Result.failure(EconomyCodes.DATA_INVALID, "ServicePostBook.register_post: o posto %d já existe." % post_id)
	if post_at(definition.place_id) != IdGenerator.NO_ID:
		return Result.failure(EconomyCodes.DATA_INVALID, "ServicePostBook.register_post: o local '%s' do posto '%s' já tem o posto %d; esperado um por local." % [definition.place_id, definition.id, post_at(definition.place_id)])
	_posts[post_id] = {KEY_SETTLEMENT: definition.settlement_id, KEY_PLACE: definition.place_id, KEY_OCCUPATION: definition.occupation_id, KEY_WANTED: definition.workers_wanted, KEY_WAGE: definition.wage_per_hour, KEY_WORKERS: [], KEY_STOPPED: false}
	return Result.success()


func has_post(post_id: int) -> bool:
	return _posts.has(post_id)


## Os postos, por ID crescente.
func post_ids() -> Array[int]:
	var ids: Array[int] = []
	ids.assign(_posts.keys())
	ids.sort()
	return ids


## O posto que ocupa o local `place_id` (`IdGenerator.NO_ID` se nenhum).
func post_at(place_id: String) -> int:
	for post_id: int in post_ids():
		if _posts[post_id][KEY_PLACE] == place_id:
			return post_id
	return IdGenerator.NO_ID


func posts_of(settlement_id: String) -> Array[int]:
	var ids: Array[int] = []
	for post_id: int in post_ids():
		if _posts[post_id][KEY_SETTLEMENT] == settlement_id:
			ids.append(post_id)
	return ids


func assign_worker(post_id: int, worker_id: int) -> Result:
	if not _posts.has(post_id):
		return Result.failure(EconomyCodes.UNKNOWN_OWNER, "ServicePostBook.assign_worker: o posto %d não existe." % post_id)
	var workers: Array = _posts[post_id][KEY_WORKERS]
	if not workers.has(worker_id):
		workers.append(worker_id)
		workers.sort()
	return Result.success()


## Tira o trabalhador de todo posto (morte ou troca de emprego): quem não está em nenhum não é erro.
func remove_worker(worker_id: int) -> void:
	for post_id: int in post_ids():
		(_posts[post_id][KEY_WORKERS] as Array).erase(worker_id)


## Uma cópia do estado do posto (vazia se não existe); `running` é o contrário de `stopped`.
func state_of(post_id: int) -> Dictionary:
	var state: Dictionary = (_posts.get(post_id, {}) as Dictionary).duplicate(true)
	if not state.is_empty():
		state["running"] = not state[KEY_STOPPED]
	return state


## A folha da hora de TODOS os postos; devolve um `WagesPaid` por posto pago para quem chama publicar. Sem equipe ou com salário 0 não há folha nem evento (e o posto não está parado).
func hour_step() -> Array[SimEvent]:
	var events: Array[SimEvent] = []
	for post_id: int in post_ids():
		var state: Dictionary = _posts[post_id]
		var workers: Array = state[KEY_WORKERS]
		var wage: int = state[KEY_WAGE]
		if workers.is_empty() or wage <= 0:
			state[KEY_STOPPED] = false
			continue
		var market_id: int = _markets.market_of(state[KEY_SETTLEMENT])
		if market_id == IdGenerator.NO_ID or not _payer.can_pay(market_id, wage, workers) or not _payer.pay(market_id, wage, workers).ok:
			state[KEY_STOPPED] = true
			continue
		state[KEY_STOPPED] = false
		events.append(WagesPaid.new(post_id, wage))
	return events


func is_pristine() -> bool:
	return _posts.is_empty()


func serialize() -> Dictionary:
	var posts: Dictionary = {}
	for post_id: int in post_ids():
		posts[str(post_id)] = _posts[post_id].duplicate(true)
	return {KEY_POSTS: posts}


## Confere tudo antes de alterar o estado: textos não vazios, equipe desejada de 1 ou mais, salário de 0 ou mais, `stopped` verdadeiro ou falso, a equipe como lista de IDs positivos em ordem crescente e sem repetição, um posto por local.
## Se algo for inválido, o livro fica como estava.
func load_from(data: Dictionary) -> Result:
	var raw_posts: Variant = data.get(KEY_POSTS)
	if typeof(raw_posts) != TYPE_DICTIONARY:
		return _invalid_save("campo '%s' ausente ou não é um objeto" % KEY_POSTS)
	var posts: Dictionary[int, Dictionary] = {}
	var places: Dictionary[String, int] = {}
	var raw_table: Dictionary = raw_posts
	for key: Variant in raw_table.keys():
		var post_id: int = EconomyJson.id_of_key(key)
		var parsed: Variant = _parse_post(post_id, raw_table[key])
		if typeof(parsed) == TYPE_STRING:
			return _invalid_save("posto '%s': %s" % [str(key), str(parsed)])
		var state: Dictionary = parsed
		if places.has(state[KEY_PLACE]):
			return _invalid_save("posto '%s': o local '%s' já tem o posto %d" % [str(key), state[KEY_PLACE], places[state[KEY_PLACE]]])
		places[state[KEY_PLACE]] = post_id
		posts[post_id] = state
	_posts = posts
	return Result.success()


func validate() -> Array[String]:
	var problems: Array[String] = []
	for post_id: int in post_ids():
		if post_id < IdGenerator.FIRST_ID:
			problems.append("o posto %d tem um ID fora da faixa" % post_id)
	return problems


## Devolve o estado montado, ou o TEXTO do problema (o chamador o prefixa com o posto).
func _parse_post(post_id: int, raw_entry: Variant) -> Variant:
	if post_id < IdGenerator.FIRST_ID or typeof(raw_entry) != TYPE_DICTIONARY:
		return "esperado um ID positivo e um objeto"
	var entry: Dictionary = raw_entry
	for field: String in [KEY_SETTLEMENT, KEY_PLACE, KEY_OCCUPATION]:
		if typeof(entry.get(field)) != TYPE_STRING or str(entry[field]).is_empty():
			return "'%s' deve ser texto não vazio" % field
	for field: String in [KEY_WANTED, KEY_WAGE]:
		if not EconomyJson.is_int_like(entry.get(field)):
			return "'%s' deve ser um inteiro" % field
	var wanted: int = EconomyJson.to_int(entry[KEY_WANTED])
	var wage: int = EconomyJson.to_int(entry[KEY_WAGE])
	if wanted < 1 or wage < 0:
		return "'%s' deve ser 1 ou mais e '%s' 0 ou mais" % [KEY_WANTED, KEY_WAGE]
	if typeof(entry.get(KEY_STOPPED)) != TYPE_BOOL:
		return "'%s' deve ser verdadeiro ou falso" % KEY_STOPPED
	var raw_workers: Variant = entry.get(KEY_WORKERS)
	if typeof(raw_workers) != TYPE_ARRAY:
		return "'%s' deve ser uma lista de IDs" % KEY_WORKERS
	var workers: Array[int] = []
	for raw_worker: Variant in raw_workers:
		if not EconomyJson.is_int_like(raw_worker) or EconomyJson.to_int(raw_worker) < IdGenerator.FIRST_ID or (workers.size() > 0 and EconomyJson.to_int(raw_worker) <= workers[workers.size() - 1]):
			return "'%s' deve ter IDs inteiros positivos, em ordem crescente e sem repetição" % KEY_WORKERS
		workers.append(EconomyJson.to_int(raw_worker))
	return {KEY_SETTLEMENT: str(entry[KEY_SETTLEMENT]), KEY_PLACE: str(entry[KEY_PLACE]), KEY_OCCUPATION: str(entry[KEY_OCCUPATION]), KEY_WANTED: wanted, KEY_WAGE: wage, KEY_WORKERS: workers, KEY_STOPPED: bool(entry[KEY_STOPPED])}


func _invalid_save(detail: String) -> Result:
	return Result.failure(EconomyCodes.INVALID_SAVE, "ServicePostBook.load_from: %s." % detail)
