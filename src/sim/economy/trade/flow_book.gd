class_name FlowBook
extends RefCounted
## O livro do fluxo agregado por rota (LW-100c1; docs/modules/economy.md, 9.16.2 e 9.16.6): a estrutura (LW-100c1), ligada ao `EconomyState` e ao save na LW-100c2 e preenchida pelo `FlowRunner` (LW-100d1a) só depois que um comando de desenvolvimento liga a chave de uma rota, então o jogo é igual ao de hoje. Guarda o dono-trânsito (`holder_id`, 0 = ainda não aberto), o contador PRÓPRIO de lotes
## (`next_lot_id`, de 1 em diante: não gasta `ctx.ids` e nunca devolve um id), uma linha por rota já ligada alguma vez (`RouteRow`) e os lotes a caminho (`Lot`). Sem preço, dinheiro nem cópia de estoque: os bens do lote estão no inventário do dono-trânsito. Tempo em minutos de simulação; nunca sorteia nem olha o relógio.
## O livro VIRGEM (`is_pristine`: `holder_id` 0, nenhuma linha e nenhum lote) é a guarda de "desligado = nada muda" (9.16.6): não tem o que gravar e o `serialize` devolve `{}` (a chave `trade_flow` do save só existe para o livro que NÃO é virgem). O save é um objeto com `holder_id`, `next_lot_id` e duas LISTAS (`routes` por `route_id` e
## `lots` por `lot_id`, crescentes), só com inteiros, textos e booleanos. O `load_from` confere tudo o que o livro sabe sozinho (tipos, campos, faixas, ids e a linha de rota de cada lote) e é TUDO OU NADA; o `validate` (LW-100c2) confere o livro contra o dono-trânsito, os mercados, os bens e o estoque dele, e a rota contra o `world` fica para a LW-100d1 (só ela terá a porta de rotas, como `CaravanRunner.route_problems`). Aqui NÃO há envio, entrega, retenção nem retomada (LW-100d1 e LW-100d2).

const KEY_HOLDER: String = "holder_id"
const KEY_NEXT_LOT: String = "next_lot_id"
const KEY_ROUTES: String = "routes"
const KEY_LOTS: String = "lots"
## O resto de risco de uma rota vai de 0 a 9999 pontos-base: 10000 já vira um corte inteiro (9.16.3).
const MAX_CARRY_BP: int = 9999
## Id do tipo de dono do dono-trânsito (`owner_kinds.json`; 9.16.3): peso 5000 e saldo 0 [HIP]. Peso 0 não serve: no `GoodsStore` quer dizer "não carrega nada", não "sem limite".
const KIND_FLOW: String = "flow"

var _holder_id: int = IdGenerator.NO_ID
var _next_lot_id: int = IdGenerator.FIRST_ID
var _routes: Dictionary[String, RouteRow] = {}
var _lots: Dictionary[int, Lot] = {}
## Os livros de fora, só para as conferências cruzadas do `validate` (LW-100c2); sem eles o livro guarda e serializa igual. `_markets` é nulo na economia sem constantes de preço (então nenhum mercado é conhecido).
var _owners: OwnerBook
var _markets: MarketBook
var _store: GoodsStore


func _init(owner_book: OwnerBook = null, market_book: MarketBook = null, goods_store: GoodsStore = null) -> void:
	_owners = owner_book
	_markets = market_book
	_store = goods_store


## A linha de uma rota já ligada alguma vez (9.16.6): a chave `enabled` e o resto de risco (`risk_carry_bp`, de 0 a 9999) que o próximo envio soma (9.16.3).
class RouteRow:
	extends RefCounted

	const KEY_ID: String = "route_id"
	const KEY_ENABLED: String = "enabled"
	const KEY_CARRY: String = "risk_carry_bp"

	var route_id: String = ""
	var enabled: bool = false
	var risk_carry_bp: int = 0

	func serialize() -> Dictionary:
		return {KEY_ID: route_id, KEY_ENABLED: enabled, KEY_CARRY: risk_carry_bp}

	## O texto do problema de TIPO do registro cru do save (vazio se está certo).
	static func shape_problem(record: Dictionary) -> String:
		if typeof(record.get(KEY_ID)) != TYPE_STRING:
			return "'%s' deve ser texto" % KEY_ID
		if typeof(record.get(KEY_ENABLED)) != TYPE_BOOL:
			return "'%s' deve ser verdadeiro ou falso" % KEY_ENABLED
		if not EconomyJson.is_int_like(record.get(KEY_CARRY)):
			return "'%s' deve ser um inteiro" % KEY_CARRY
		return ""

	## Monta a linha de um `record` com os tipos já conferidos (`shape_problem`): número de JSON (decimal sem fração) vira inteiro.
	static func from_record(record: Dictionary) -> RouteRow:
		var row: RouteRow = RouteRow.new()
		row.route_id = str(record[KEY_ID])
		row.enabled = bool(record[KEY_ENABLED])
		row.risk_carry_bp = EconomyJson.to_int(record[KEY_CARRY])
		return row

	func copy() -> RouteRow:
		return RouteRow.from_record(serialize())


## O registro de um lote a caminho (9.16.2): de onde, para onde, o bem e a quantidade (o que está no dono-trânsito para esse lote), o `state` (`travelling` ou `held`) e os minutos: `departed_at` e `arrives_at` (0 em `held`) e `remaining_minutes` (só em `held`). Os nomes dos campos são os das chaves do save.
class Lot:
	extends RefCounted

	const STATE_TRAVELLING: String = "travelling"
	const STATE_HELD: String = "held"
	const STATES: Array[String] = [STATE_TRAVELLING, STATE_HELD]
	## Os campos do registro salvo, na ordem de 9.16.2; só os três de texto não são inteiros.
	const KEYS: Array[String] = ["lot_id", "route_id", "origin_market_id", "destination_market_id", "good_id", "quantity", "state", "departed_at", "arrives_at", "remaining_minutes"]
	const TEXT_KEYS: Array[String] = ["route_id", "good_id", "state"]

	var lot_id: int = IdGenerator.NO_ID
	var route_id: String = ""
	var origin_market_id: int = IdGenerator.NO_ID
	var destination_market_id: int = IdGenerator.NO_ID
	var good_id: String = ""
	var quantity: int = 0
	var state: String = STATE_TRAVELLING
	var departed_at: int = 0
	var arrives_at: int = 0
	var remaining_minutes: int = 0

	func serialize() -> Dictionary:
		return {"lot_id": lot_id, "route_id": route_id, "origin_market_id": origin_market_id, "destination_market_id": destination_market_id, "good_id": good_id, "quantity": quantity, "state": state, "departed_at": departed_at, "arrives_at": arrives_at, "remaining_minutes": remaining_minutes}

	## O texto do problema de TIPO do registro cru do save (vazio se está certo).
	static func shape_problem(record: Dictionary) -> String:
		for key: String in KEYS:
			if TEXT_KEYS.has(key) and typeof(record.get(key)) != TYPE_STRING:
				return "'%s' deve ser texto" % key
			if not TEXT_KEYS.has(key) and not EconomyJson.is_int_like(record.get(key)):
				return "'%s' deve ser um inteiro" % key
		return ""

	## Monta o lote de um `record` com os tipos já conferidos (`shape_problem`): número de JSON (decimal sem fração) vira inteiro.
	static func from_record(record: Dictionary) -> Lot:
		var lot: Lot = Lot.new()
		lot.lot_id = EconomyJson.to_int(record["lot_id"])
		lot.route_id = str(record["route_id"])
		lot.origin_market_id = EconomyJson.to_int(record["origin_market_id"])
		lot.destination_market_id = EconomyJson.to_int(record["destination_market_id"])
		lot.good_id = str(record["good_id"])
		lot.quantity = EconomyJson.to_int(record["quantity"])
		lot.state = str(record["state"])
		lot.departed_at = EconomyJson.to_int(record["departed_at"])
		lot.arrives_at = EconomyJson.to_int(record["arrives_at"])
		lot.remaining_minutes = EconomyJson.to_int(record["remaining_minutes"])
		return lot

	func copy() -> Lot:
		return Lot.from_record(serialize())

	## O texto do problema de FAIXA (vazio se está certo): `lot_id` e `quantity` de 1 ou mais, `state` conhecido, e em `held` `arrives_at` 0 e `remaining_minutes` de 0 ou mais, em `travelling` `remaining_minutes` 0.
	func range_problem() -> String:
		if lot_id < 1:
			return "'lot_id' é %d; esperado 1 ou mais" % lot_id
		if quantity < 1:
			return "'quantity' é %d; esperado 1 ou mais" % quantity
		if not STATES.has(state):
			return "o estado '%s' não é válido; esperado um de: %s" % [state, ", ".join(STATES)]
		if state == STATE_HELD and arrives_at != 0:
			return "em '%s', 'arrives_at' é %d; esperado 0" % [state, arrives_at]
		if state == STATE_HELD and remaining_minutes < 0:
			return "em '%s', 'remaining_minutes' é %d; esperado 0 ou mais" % [state, remaining_minutes]
		if state == STATE_TRAVELLING and remaining_minutes != 0:
			return "em '%s', 'remaining_minutes' é %d; esperado 0" % [state, remaining_minutes]
		return ""


## O dono-trânsito (`IdGenerator.NO_ID` = ainda não aberto).
func holder_id() -> int:
	return _holder_id


## O id que o PRÓXIMO lote recebe: sempre maior que todo `lot_id` já usado, mesmo o dos lotes retirados.
func next_lot_id() -> int:
	return _next_lot_id


func is_pristine() -> bool:
	return _holder_id == IdGenerator.NO_ID and _routes.is_empty() and _lots.is_empty()


## As rotas com linha, por `route_id` crescente.
func route_ids() -> Array[String]:
	var ids: Array[String] = []
	ids.assign(_routes.keys())
	ids.sort()
	return ids


## Os lotes a caminho, por `lot_id` crescente.
func lot_ids() -> Array[int]:
	var ids: Array[int] = []
	ids.assign(_lots.keys())
	ids.sort()
	return ids


## Uma CÓPIA da linha (`null` se a rota nunca foi ligada).
func route_of(route_id: String) -> RouteRow:
	return _routes[route_id].copy() if _routes.has(route_id) else null


## Uma CÓPIA do lote (`null` se não existe).
func lot_of(lot_id: int) -> Lot:
	return _lots[lot_id].copy() if _lots.has(lot_id) else null


## Registra o lote que SAIU (a LW-100d1 o chama depois de conferir tudo: aqui não há recusa): guarda uma CÓPIA com o próximo id do contador (o `lot_id` que vier é ignorado) e devolve esse id.
func add_lot(lot: Lot) -> int:
	var stored: Lot = lot.copy()
	stored.lot_id = _next_lot_id
	_next_lot_id += 1
	_lots[stored.lot_id] = stored
	return stored.lot_id


## O lote some (entregue por inteiro, LW-100d1). O contador NÃO volta: o id retirado nunca é reaproveitado.
func remove_lot(lot_id: int) -> void:
	_lots.erase(lot_id)


## Grava o dono-trânsito (LW-100d1a), UMA vez: só vale com o livro ainda sem dono e um id de 1 ou mais; devolve se gravou. Abrir o dono no `OwnerBook` é de quem chama (o `FlowRunner`).
func set_holder(owner_id: int) -> bool:
	if _holder_id != IdGenerator.NO_ID or owner_id < IdGenerator.FIRST_ID:
		return false
	_holder_id = owner_id
	return true


## Liga ou desliga a chave da rota (LW-100d1a). A primeira vez cria a linha (resto 0); idempotente.
func set_enabled(route_id: String, enabled: bool) -> void:
	if not _routes.has(route_id):
		var row: RouteRow = RouteRow.new()
		row.route_id = route_id
		_routes[route_id] = row
	_routes[route_id].enabled = enabled


## Grava o resto de risco da rota (LW-100d1a; 9.16.3), de 0 a 9999; rota sem linha ou resto fora da faixa: nada muda. Devolve se gravou.
func set_carry(route_id: String, carry_bp: int) -> bool:
	if not _routes.has(route_id) or carry_bp < 0 or carry_bp > MAX_CARRY_BP:
		return false
	_routes[route_id].risk_carry_bp = carry_bp
	return true


## Entrega PARCIAL (LW-100d1a): tira `delivered` unidades da `quantity` do lote; chegando a 0 o lote sai (`remove_lot`). Lote que não existe ou `delivered` fora de 1 a `quantity`: nada muda. Devolve se mudou.
func reduce_lot(lot_id: int, delivered: int) -> bool:
	if not _lots.has(lot_id) or delivered < 1 or delivered > _lots[lot_id].quantity:
		return false
	_lots[lot_id].quantity -= delivered
	if _lots[lot_id].quantity == 0:
		remove_lot(lot_id)
	return true


## SEGURA o lote que a rota fechada interrompeu (LW-100d2; 9.16.4): `travelling` vira `held` com os minutos que faltavam (`remaining_minutes`, 0 ou mais; quem chama os calcula como `arrives_at` menos agora) e `arrives_at` 0; os bens seguem no dono-trânsito. Lote que não existe, que não está a caminho ou minutos negativos: nada muda. Devolve se mudou.
func hold_lot(lot_id: int, remaining_minutes: int) -> bool:
	if not _lots.has(lot_id) or _lots[lot_id].state != Lot.STATE_TRAVELLING or remaining_minutes < 0:
		return false
	_lots[lot_id].state = Lot.STATE_HELD
	_lots[lot_id].arrives_at = 0
	_lots[lot_id].remaining_minutes = remaining_minutes
	return true


## RETOMA o lote segurado (LW-100d2; 9.16.4): `held` volta a `travelling` com a nova chegada `arrives_at` (1 ou mais: agora mais os minutos que faltavam) e `remaining_minutes` 0. Lote que não existe, que não está `held` ou chegada menor que 1: nada muda. Devolve se mudou.
func resume_lot(lot_id: int, arrives_at: int) -> bool:
	if not _lots.has(lot_id) or _lots[lot_id].state != Lot.STATE_HELD or arrives_at < 1:
		return false
	_lots[lot_id].state = Lot.STATE_TRAVELLING
	_lots[lot_id].arrives_at = arrives_at
	_lots[lot_id].remaining_minutes = 0
	return true


## O que desse bem já está a caminho do mercado (LW-100d1a): a soma das `quantity` dos lotes com esse destino, em qualquer estado. É o espaço do destino já reservado no envio (9.16.2); só leitura.
func incoming_of(destination_market_id: int, good_id: String) -> int:
	var total: int = 0
	for lot: Lot in _lots.values():
		if lot.destination_market_id == destination_market_id and lot.good_id == good_id:
			total += lot.quantity
	return total


## `{}` no livro virgem (nada a gravar); senão `holder_id`, `next_lot_id`, `routes` (por `route_id`) e `lots` (por `lot_id`), uma lista de registros cada, os mesmos bytes para os mesmos dados em qualquer ordem de entrada.
func serialize() -> Dictionary:
	if is_pristine():
		return {}
	var routes: Array[Dictionary] = []
	for route_id: String in route_ids():
		routes.append(_routes[route_id].serialize())
	var lots: Array[Dictionary] = []
	for lot_id: int in lot_ids():
		lots.append(_lots[lot_id].serialize())
	return {KEY_HOLDER: _holder_id, KEY_NEXT_LOT: _next_lot_id, KEY_ROUTES: routes, KEY_LOTS: lots}


## Troca o estado pelo `data` (o formato de `serialize`) SE tudo conferir; senão o livro fica como estava (TUDO OU NADA: a leitura é feita num livro de rascunho). Os quatro campos são obrigatórios: `{}` (o que o livro virgem serializa) é recusado, porque o save nem leva a chave quando o livro é virgem.
func load_from(data: Dictionary) -> Result:
	var staged: FlowBook = FlowBook.new()
	var problem: String = staged._load(data)
	if not problem.is_empty():
		return Result.failure(EconomyCodes.INVALID_SAVE, "FlowBook.load_from: %s." % problem)
	_holder_id = staged._holder_id
	_next_lot_id = staged._next_lot_id
	_routes = staged._routes
	_lots = staged._lots
	return Result.success()


## As conferências do livro (9.16.6), uma frase por problema: o `EconomyPersistence` as chama no `validate()` (prefixo `[trade_flow]`) e antes de trocar o estado ao carregar o save. Livro virgem: nada a conferir. Repete, sobre o livro vivo, o que o `load_from` confere (reusa o `_load` num rascunho do próprio `serialize`: só o primeiro problema dele) e acrescenta o que o contrato e o molde da caravana pedem: dono-trânsito aberto
## se há linha de rota ou lote; tempos de 0 ou mais e origem diferente do destino; o dono-trânsito existe, está aberto e é do tipo `flow`; os dois mercados de cada lote existem e negociam o bem; e, por bem, o estoque do dono-trânsito é a soma das `quantity` dos lotes (lote sem bem e bem sem lote são erro). A rota contra o `world` NÃO é daqui (o livro não tem a porta de rotas; LW-100d1). Sem o `OwnerBook` e o `GoodsStore` (livro avulso) só valem as conferências próprias.
func validate() -> Array[String]:
	var problems: Array[String] = []
	if is_pristine():
		return problems
	var internal: String = FlowBook.new()._load(serialize())
	if not internal.is_empty():
		problems.append(internal)
	if _holder_id == IdGenerator.NO_ID:
		problems.append("há linha de rota ou lote, mas '%s' é 0: ligar a chave abre o dono-trânsito e cria a linha de uma vez (9.16.7)" % KEY_HOLDER)
	for lot_id: int in lot_ids():
		problems.append_array(_lot_problems(_lots[lot_id]))
	if _owners == null or _store == null or _holder_id == IdGenerator.NO_ID:
		return problems
	var holder_problem: String = _holder_problem()
	if holder_problem.is_empty():
		problems.append_array(_stock_problems())
	else:
		problems.append(holder_problem)
	return problems


## Lê o `data` para ESTE livro e devolve o primeiro problema, uma frase (vazio se tudo confere).
func _load(data: Dictionary) -> String:
	for key: String in [KEY_HOLDER, KEY_NEXT_LOT]:
		if not EconomyJson.is_int_like(data.get(key)):
			return "'%s' deve ser um inteiro" % key
	for key: String in [KEY_ROUTES, KEY_LOTS]:
		if typeof(data.get(key)) != TYPE_ARRAY:
			return "'%s' deve ser uma lista" % key
	_holder_id = EconomyJson.to_int(data[KEY_HOLDER])
	_next_lot_id = EconomyJson.to_int(data[KEY_NEXT_LOT])
	if _holder_id < 0:
		return "'%s' é %d; esperado 0 ou mais" % [KEY_HOLDER, _holder_id]
	if _next_lot_id < 1:
		return "'%s' é %d; esperado 1 ou mais" % [KEY_NEXT_LOT, _next_lot_id]
	var raw_routes: Array = data[KEY_ROUTES]
	for index: int in raw_routes.size():
		var problem: String = _read_route(raw_routes[index])
		if not problem.is_empty():
			return "linha de rota %d: %s" % [index, problem]
	var raw_lots: Array = data[KEY_LOTS]
	for index: int in raw_lots.size():
		var problem: String = _read_lot(raw_lots[index])
		if not problem.is_empty():
			return "registro de lote %d: %s" % [index, problem]
	return _link_problem()


## Guarda a linha do registro cru e devolve o problema dela (vazio se está certa): tipos, resto de 0 a 9999 e uma só linha por rota.
func _read_route(raw_entry: Variant) -> String:
	if typeof(raw_entry) != TYPE_DICTIONARY:
		return "esperado um objeto"
	var entry: Dictionary = raw_entry
	var problem: String = RouteRow.shape_problem(entry)
	if not problem.is_empty():
		return problem
	var row: RouteRow = RouteRow.from_record(entry)
	if row.risk_carry_bp < 0 or row.risk_carry_bp > MAX_CARRY_BP:
		return "'%s' é %d; esperado de 0 a %d" % [RouteRow.KEY_CARRY, row.risk_carry_bp, MAX_CARRY_BP]
	if _routes.has(row.route_id):
		return "a rota '%s' tem mais de uma linha" % row.route_id
	_routes[row.route_id] = row
	return ""


## Guarda o lote do registro cru e devolve o problema dele (vazio se está certo): tipos, faixas e id único.
func _read_lot(raw_entry: Variant) -> String:
	if typeof(raw_entry) != TYPE_DICTIONARY:
		return "esperado um objeto"
	var entry: Dictionary = raw_entry
	var problem: String = Lot.shape_problem(entry)
	if not problem.is_empty():
		return problem
	var lot: Lot = Lot.from_record(entry)
	problem = lot.range_problem()
	if not problem.is_empty():
		return problem
	if _lots.has(lot.lot_id):
		return "o id %d está repetido" % lot.lot_id
	_lots[lot.lot_id] = lot
	return ""


## O problema ENTRE as partes (vazio se não há): o contador acima de todo lote, uma linha para a rota de cada lote e o dono-trânsito aberto se há lote.
func _link_problem() -> String:
	var ids: Array[int] = lot_ids()
	if not ids.is_empty() and _next_lot_id <= ids[-1]:
		return "'%s' é %d; esperado maior que o maior lote (%d)" % [KEY_NEXT_LOT, _next_lot_id, ids[-1]]
	for lot_id: int in ids:
		if not _routes.has(_lots[lot_id].route_id):
			return "o lote %d é da rota '%s', que não tem linha" % [lot_id, _lots[lot_id].route_id]
	if _holder_id == IdGenerator.NO_ID and not ids.is_empty():
		return "há lotes, mas '%s' é 0 (o dono-trânsito não foi aberto)" % KEY_HOLDER
	return ""


## O dono-trânsito existe, está aberto e é do tipo `flow` (vazio se está certo); só com `holder_id` diferente de 0 (o 0 é problema do `validate`).
func _holder_problem() -> String:
	var opened: Result = _owners.check_open(_holder_id)
	if not opened.ok:
		return "o dono-trânsito: %s" % opened.message.trim_suffix(".")
	if _owners.kind_of(_holder_id) != KIND_FLOW:
		return "o dono-trânsito %d é do tipo '%s'; esperado '%s'" % [_holder_id, _owners.kind_of(_holder_id), KIND_FLOW]
	return ""


## O que o lote precisa além do `load_from` (como a caravana, 9.3): tempos de 0 ou mais, origem diferente do destino e, com os livros de fora, os dois mercados existem e negociam o bem.
func _lot_problems(lot: Lot) -> Array[String]:
	var problems: Array[String] = []
	if lot.departed_at < 0:
		problems.append("o lote %d: 'departed_at' é %d; esperado 0 ou mais" % [lot.lot_id, lot.departed_at])
	if lot.arrives_at < 0:
		problems.append("o lote %d: 'arrives_at' é %d; esperado 0 ou mais" % [lot.lot_id, lot.arrives_at])
	if lot.origin_market_id == lot.destination_market_id:
		problems.append("o lote %d: a origem e o destino são o mesmo mercado (%d)" % [lot.lot_id, lot.origin_market_id])
	if _owners == null or _store == null:
		return problems
	var sides: Dictionary[String, int] = {"origem": lot.origin_market_id, "destino": lot.destination_market_id}
	for side: String in sides:
		if _markets == null or not _markets.has_market(sides[side]):
			problems.append("o lote %d: o mercado de %s %d não existe" % [lot.lot_id, side, sides[side]])
		elif not _markets.is_traded(sides[side], lot.good_id):
			problems.append("o lote %d: o bem '%s' não é negociado no mercado de %s %d" % [lot.lot_id, lot.good_id, side, sides[side]])
	return problems


## Por bem, o estoque do dono-trânsito é a soma das `quantity` dos lotes (9.16.6): a soma dos lotes de cada bem contra o que o dono tem, nos bens de uns e de outros.
func _stock_problems() -> Array[String]:
	var wanted: Dictionary[String, int] = {}
	for lot_id: int in lot_ids():
		wanted[_lots[lot_id].good_id] = int(wanted.get(_lots[lot_id].good_id, 0)) + _lots[lot_id].quantity
	for row: Dictionary in _store.inventory_rows(_holder_id):
		wanted[str(row["good_id"])] = int(wanted.get(str(row["good_id"]), 0))
	var good_ids: Array[String] = []
	good_ids.assign(wanted.keys())
	good_ids.sort()
	var problems: Array[String] = []
	for good_id: String in good_ids:
		if _store.quantity_of(_holder_id, good_id) != wanted[good_id]:
			problems.append("o dono-trânsito tem %d de '%s' e os lotes somam %d" % [_store.quantity_of(_holder_id, good_id), good_id, wanted[good_id]])
	return problems
