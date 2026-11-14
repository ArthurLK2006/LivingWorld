class_name CaravanBook
extends RefCounted
## O livro de caravanas (LW-098c; docs/modules/economy.md, 9.3, 9.4 e 9.10): um `Caravan` por comerciante em viagem, por `trader_id`; sem registro = parado. NASCE VAZIO; só a partida (`add`, LW-098d1) o preenche (a chegada é da 098d2, a parada e o desvio da 098e): aqui
## estão o estado, o save (`serialize` e `load_from`), `add` e `remove` (o `NpcDied` do comerciante apaga o registro) e as invariantes (`validate`). Não guarda dinheiro nem bem (`cost_paid` é informação; saldo e carga ficam na conta e no inventário do comerciante, dono do tipo `merchant`),
## então não mexe nas duas conservações. Nunca sorteia nem olha o relógio. O save é a LISTA dos registros por `trader_id` crescente; `load_from` confere só os TIPOS e as invariantes (faixas, dono, mercados) são do `validate`, que o `SimulationRunner` chama logo depois de carregar o save.

## Id do tipo de dono do comerciante (`owner_kinds.json`).
const KIND_MERCHANT: String = "merchant"

var _book: OwnerBook
var _markets: MarketBook
var _caravans: Dictionary[int, Caravan] = {}


## `market_book` pode ser nulo (economia sem constantes de preço): então nenhum mercado é conhecido e nenhuma caravana é válida.
func _init(owner_book: OwnerBook, market_book: MarketBook = null) -> void:
	_book = owner_book
	_markets = market_book


## Os comerciantes com caravana, por ID crescente.
func trader_ids() -> Array[int]:
	var ids: Array[int] = []
	ids.assign(_caravans.keys())
	ids.sort()
	return ids


## Uma CÓPIA do registro (`null` se o comerciante está parado).
func caravan_of(trader_id: int) -> Caravan:
	return _caravans[trader_id].copy() if _caravans.has(trader_id) else null


func has_caravan(trader_id: int) -> bool:
	return _caravans.has(trader_id)


## Registra a caravana que PARTIU (LW-098d1; 9.4, primeira linha): guarda uma cópia. Só a partida a chama, DEPOIS de conferir tudo, inclusive que o comerciante não tem registro (`has_caravan`): aqui não há recusa, para a compra do lote nunca ficar sem o registro dela.
func add(caravan: Caravan) -> void:
	_caravans[caravan.trader_id] = caravan.copy()


## O registro some (`NpcDied` do comerciante, 9.4): saldo e carga ficam na conta e no inventário fechados, e a soma se mantém (DEC-146).
func remove(trader_id: int) -> void:
	_caravans.erase(trader_id)


func is_pristine() -> bool:
	return _caravans.is_empty()


func serialize() -> Array[Dictionary]:
	var records: Array[Dictionary] = []
	for trader_id: int in trader_ids():
		records.append(_caravans[trader_id].serialize())
	return records


## Confere os TIPOS de tudo antes de alterar o estado: cada registro é um objeto com os campos de `Caravan` (inteiros, textos e a lista de rotas) e há um só por comerciante. Se algo for inválido, o livro fica como estava.
func load_from(records: Array) -> Result:
	var caravans: Dictionary[int, Caravan] = {}
	for index: int in records.size():
		var problem: String = _shape_problem(records[index])
		if not problem.is_empty():
			return _invalid_save("registro %d: %s" % [index, problem])
		var caravan: Caravan = Caravan.from_record(records[index] as Dictionary)
		if caravans.has(caravan.trader_id):
			return _invalid_save("o comerciante %d tem mais de um registro" % caravan.trader_id)
		caravans[caravan.trader_id] = caravan
	_caravans = caravans
	return Result.success()


## Invariantes de 9.3, uma frase por problema: o comerciante existe, está aberto e é do tipo `merchant`; `state` válido; `route_ids` não vazia; `leg_index` dentro da lista; `leg_minutes` de 1 ou mais; `elapsed_at_hold` entre 0 e `leg_minutes` e diferente de 0 só em `held`;
## `quantity` de 1 ou mais; `cost_paid`, `departed_at` e `leg_started_at` de 0 ou mais (LW-098d1: passam a ser usados); origem diferente do destino, os dois mercados e `good_id` negociado nos dois. (No máximo um registro por comerciante vale pela estrutura do livro. As rotas contra o `world` são
## conferidas pela porta de rotas de 9.2, que o livro não tem: `CaravanRunner.route_problems`.)
func validate() -> Array[String]:
	var problems: Array[String] = []
	for trader_id: int in trader_ids():
		for problem: String in _problems_of(_caravans[trader_id]):
			problems.append("a caravana do comerciante %d: %s" % [trader_id, problem])
	return problems


func _problems_of(caravan: Caravan) -> Array[String]:
	var problems: Array[String] = []
	var opened: Result = _book.check_open(caravan.trader_id)
	if not opened.ok:
		problems.append(opened.message.trim_suffix("."))
	elif _book.kind_of(caravan.trader_id) != KIND_MERCHANT:
		problems.append("o dono %d é do tipo '%s'; esperado '%s'" % [caravan.trader_id, _book.kind_of(caravan.trader_id), KIND_MERCHANT])
	if not Caravan.STATES.has(caravan.state):
		problems.append("o estado '%s' não é válido; esperado um de: %s" % [caravan.state, ", ".join(Caravan.STATES)])
	if caravan.route_ids.is_empty() or caravan.route_ids.has(""):
		problems.append("'%s' deve ter ao menos uma rota, todas com id" % Caravan.KEY_ROUTES)
	if caravan.leg_index < 0 or caravan.leg_index >= caravan.route_ids.size():
		problems.append("o trecho %d não existe: o caminho tem %d rota(s)" % [caravan.leg_index, caravan.route_ids.size()])
	if caravan.leg_minutes < 1:
		problems.append("'%s' é %d; esperado 1 ou mais" % [Caravan.KEY_LEG_MINUTES, caravan.leg_minutes])
	if caravan.elapsed_at_hold < 0 or caravan.elapsed_at_hold > caravan.leg_minutes:
		problems.append("'%s' é %d; esperado de 0 a %d (os minutos do trecho)" % [Caravan.KEY_ELAPSED, caravan.elapsed_at_hold, caravan.leg_minutes])
	elif caravan.elapsed_at_hold != 0 and caravan.state != Caravan.STATE_HELD:
		problems.append("'%s' é %d; só '%s' pode ter minutos parados" % [Caravan.KEY_ELAPSED, caravan.elapsed_at_hold, Caravan.STATE_HELD])
	if caravan.quantity < 1:
		problems.append("'%s' é %d; esperado 1 ou mais" % [Caravan.KEY_QUANTITY, caravan.quantity])
	var times_and_cost: Dictionary[String, int] = {Caravan.KEY_COST: caravan.cost_paid, Caravan.KEY_DEPARTED: caravan.departed_at, Caravan.KEY_LEG_STARTED: caravan.leg_started_at}
	for key: String in times_and_cost:
		if times_and_cost[key] < 0:
			problems.append("'%s' é %d; esperado 0 ou mais" % [key, times_and_cost[key]])
	if caravan.origin_market_id == caravan.destination_market_id:
		problems.append("a origem e o destino são o mesmo mercado (%d)" % caravan.origin_market_id)
	for market_id: int in [caravan.origin_market_id, caravan.destination_market_id]:
		if _markets == null or not _markets.has_market(market_id):
			problems.append("%d não é um mercado" % market_id)
		elif not _markets.is_traded(market_id, caravan.good_id):
			problems.append("o bem '%s' não é negociado no mercado %d" % [caravan.good_id, market_id])
	return problems


## O texto do problema de TIPO do registro cru do save (vazio se está certo).
func _shape_problem(raw_entry: Variant) -> String:
	if typeof(raw_entry) != TYPE_DICTIONARY:
		return "esperado um objeto"
	var entry: Dictionary = raw_entry
	for key: String in Caravan.INT_KEYS:
		if not EconomyJson.is_int_like(entry.get(key)):
			return "'%s' deve ser um inteiro" % key
	for key: String in Caravan.TEXT_KEYS:
		if typeof(entry.get(key)) != TYPE_STRING:
			return "'%s' deve ser texto" % key
	# Variant: lista crua do save (e cada rota dela); o tipo e o conteúdo são conferidos na linha seguinte.
	var routes: Variant = entry.get(Caravan.KEY_ROUTES)
	if typeof(routes) != TYPE_ARRAY or (routes as Array).any(func(route_id: Variant) -> bool: return typeof(route_id) != TYPE_STRING):
		return "'%s' deve ser uma lista de textos" % Caravan.KEY_ROUTES
	return ""


func _invalid_save(detail: String) -> Result:
	return Result.failure(EconomyCodes.INVALID_SAVE, "CaravanBook.load_from: %s." % detail)
