class_name GoodsStore
extends RefCounted
## Inventário por dono da economia (LW-089b; docs/modules/economy.md, seção 3): a quantidade inteira de cada bem em poder de cada dono do `OwnerBook`, com peso total ATÉ a capacidade do tipo do dono (0 = sem
## inventário). O jogo só MOVE bens (`transfer`) ou os cria e destrói em dois pontos únicos, com motivo de um conjunto fechado: criar (`produced`, `game_start`) e destruir (`consumed`, `maintenance`, `spoiled`).
## Falha devolve `Result` e NÃO muda nada. Conservação por bem: soma de todos os donos = criado − destruído, inclusive o destruído por `maintenance`. Dono fechado (o NPC que morreu) não aceita operação, mas
## os bens dele continuam na soma. Quantidade zero não é guardada (um estado, uma forma, um hash). O dinheiro NÃO passa por aqui: é do `Ledger`.

const REASON_PRODUCED: String = "produced"
const REASON_GAME_START: String = "game_start"
const REASON_CONSUMED: String = "consumed"
const REASON_MAINTENANCE: String = "maintenance"
const REASON_SPOILED: String = "spoiled"
const CREATE_REASONS: Array[String] = [REASON_PRODUCED, REASON_GAME_START]
const DESTROY_REASONS: Array[String] = [REASON_CONSUMED, REASON_MAINTENANCE, REASON_SPOILED]
const KEY_STOCK: String = "stock"
const KEY_CREATED: String = "created"
const KEY_DESTROYED: String = "destroyed"

var _book: OwnerBook
var _goods: Dictionary[String, GoodDef] = {}
var _kinds: Dictionary[String, OwnerKindDef] = {}
var _stock: Dictionary[int, Dictionary] = {}
var _created: Dictionary[String, Dictionary] = {}
var _destroyed: Dictionary[String, Dictionary] = {}


func _init(book: OwnerBook, goods: Array[GoodDef], kinds: Array[OwnerKindDef]) -> void:
	_book = book
	for good: GoodDef in goods:
		_goods[good.id] = good
	for kind: OwnerKindDef in kinds:
		_kinds[kind.id] = kind


func has_good(good_id: String) -> bool:
	return _goods.has(good_id)


func quantity_of(owner_id: int, good_id: String) -> int:
	var owned: Dictionary = _stock.get(owner_id, {})
	return int(owned.get(good_id, 0))


func weight_of(owner_id: int) -> int:
	return _weight_of_table(_stock.get(owner_id, {}))


## Capacidade de peso do tipo do dono (0 se o tipo não tem definição ou não tem inventário).
func capacity_of(owner_id: int) -> int:
	var kind: OwnerKindDef = _kinds.get(_book.kind_of(owner_id))
	return kind.weight_capacity if kind != null else 0


## Os bens do dono, por `good_id` crescente: `good_id` e `quantity` (cópia).
func inventory_rows(owner_id: int) -> Array[Dictionary]:
	var owned: Dictionary = _stock.get(owner_id, {})
	var ids: Array[String] = []
	ids.assign(owned.keys())
	ids.sort()
	var rows: Array[Dictionary] = []
	for good_id: String in ids:
		rows.append({"good_id": good_id, "quantity": owned[good_id]})
	return rows


func create(owner_id: int, good_id: String, quantity: int, reason: String) -> Result:
	var checked: Result = _check("create", good_id, quantity, reason, CREATE_REASONS)
	if checked.ok:
		checked = _check_owner("create", owner_id)
	if checked.ok:
		checked = _check_room("create", owner_id, good_id, quantity)
	if not checked.ok:
		return checked
	_set_quantity(owner_id, good_id, quantity_of(owner_id, good_id) + quantity)
	_bump(_created, good_id, reason, quantity)
	return Result.success()


func destroy(owner_id: int, good_id: String, quantity: int, reason: String) -> Result:
	var checked: Result = _check("destroy", good_id, quantity, reason, DESTROY_REASONS)
	if checked.ok:
		checked = _check_owner("destroy", owner_id)
	if checked.ok:
		checked = _check_has("destroy", owner_id, good_id, quantity)
	if not checked.ok:
		return checked
	_set_quantity(owner_id, good_id, quantity_of(owner_id, good_id) - quantity)
	_bump(_destroyed, good_id, reason, quantity)
	return Result.success()


## Move bens de um dono para outro, sem criar nem destruir. Tudo ou nada.
func transfer(from_id: int, to_id: int, good_id: String, quantity: int) -> Result:
	var checked: Result = _check("transfer", good_id, quantity, "", [""])
	if checked.ok:
		checked = _check_owner("transfer", from_id)
	if checked.ok:
		checked = _check_owner("transfer", to_id)
	if checked.ok:
		checked = _check_has("transfer", from_id, good_id, quantity)
	if checked.ok and from_id != to_id:
		checked = _check_room("transfer", to_id, good_id, quantity)
	if not checked.ok:
		return checked
	if from_id != to_id:
		_set_quantity(from_id, good_id, quantity_of(from_id, good_id) - quantity)
		_set_quantity(to_id, good_id, quantity_of(to_id, good_id) + quantity)
	return Result.success()


## Uma linha por bem que já teve movimento: `good_id`, `in_stock` (soma dos donos), `created`, `destroyed` e `ok` (em estoque = criado − destruído), por `good_id` crescente.
func conservation_rows() -> Array[Dictionary]:
	var ids: Array[String] = []
	ids.assign(_goods.keys())
	ids.sort()
	var rows: Array[Dictionary] = []
	for good_id: String in ids:
		var in_stock: int = _total_in_stock(good_id)
		var created: int = _sum_of(_created.get(good_id, {}))
		var destroyed: int = _sum_of(_destroyed.get(good_id, {}))
		if in_stock + created + destroyed > 0:
			rows.append({"good_id": good_id, "in_stock": in_stock, "created": created, "destroyed": destroyed, "ok": in_stock == created - destroyed})
	return rows


func is_conserved() -> bool:
	for row: Dictionary in conservation_rows():
		if not row["ok"]:
			return false
	return true


## Quanto de um bem foi criado ou destruído por um motivo (para os testes e o painel).
func total_by_reason(good_id: String, reason: String) -> int:
	var table: Dictionary[String, Dictionary] = _created if CREATE_REASONS.has(reason) else _destroyed
	return int(table.get(good_id, {}).get(reason, 0))


func is_pristine() -> bool:
	return _stock.is_empty() and _created.is_empty() and _destroyed.is_empty()


func serialize() -> Dictionary:
	var stock: Dictionary = {}
	var owner_ids: Array[int] = []
	owner_ids.assign(_stock.keys())
	owner_ids.sort()
	for owner_id: int in owner_ids:
		stock[str(owner_id)] = _sorted_copy(_stock[owner_id])
	return {KEY_STOCK: stock, KEY_CREATED: _sorted_nested(_created), KEY_DESTROYED: _sorted_nested(_destroyed)}


## Confere tudo antes de alterar o estado: formato, donos e bens existentes, motivos do conjunto, capacidade e a conservação por bem. Se algo for inválido, o inventário fica como estava.
func load_from(data: Dictionary) -> Result:
	var stock: Dictionary[int, Dictionary] = {}
	var created: Dictionary[String, Dictionary] = {}
	var destroyed: Dictionary[String, Dictionary] = {}
	var parsed: Result = _parse_stock(data.get(KEY_STOCK), stock)
	if parsed.ok:
		parsed = _parse_totals(data.get(KEY_CREATED), KEY_CREATED, CREATE_REASONS, created)
	if parsed.ok:
		parsed = _parse_totals(data.get(KEY_DESTROYED), KEY_DESTROYED, DESTROY_REASONS, destroyed)
	if not parsed.ok:
		return parsed
	for good_id: String in _goods:
		var in_stock: int = 0
		for owner_id: int in stock:
			in_stock += int(stock[owner_id].get(good_id, 0))
		if in_stock != _sum_of(created.get(good_id, {})) - _sum_of(destroyed.get(good_id, {})):
			return _invalid_save("a conservação do bem '%s' não fecha: em estoque %d, criado %d e destruído %d" % [good_id, in_stock, _sum_of(created.get(good_id, {})), _sum_of(destroyed.get(good_id, {}))])
	_stock = stock
	_created = created
	_destroyed = destroyed
	return Result.success()


func validate() -> Array[String]:
	var problems: Array[String] = []
	for owner_id: int in _stock:
		if not _book.has_owner(owner_id):
			problems.append("inventário de um dono que não existe (%d)" % owner_id)
		elif weight_of(owner_id) > capacity_of(owner_id):
			problems.append("o dono %d carrega peso %d, acima da capacidade %d" % [owner_id, weight_of(owner_id), capacity_of(owner_id)])
	for row: Dictionary in conservation_rows():
		if not row["ok"]:
			problems.append("a conservação do bem '%s' não fecha: em estoque %d, criado %d, destruído %d" % [row["good_id"], row["in_stock"], row["created"], row["destroyed"]])
	return problems


func _check(operation: String, good_id: String, quantity: int, reason: String, reasons: Array[String]) -> Result:
	if not _goods.has(good_id):
		return Result.failure(EconomyCodes.UNKNOWN_GOOD, "GoodsStore.%s: o bem '%s' não existe; esperado um de: %s." % [operation, good_id, ", ".join(_goods.keys())])
	if quantity < 1 or quantity > EconomyJson.MAX_SAFE_INTEGER:
		return Result.failure(EconomyCodes.BAD_QUANTITY, "GoodsStore.%s: quantidade %d inválida; esperado um inteiro de 1 a %d." % [operation, quantity, EconomyJson.MAX_SAFE_INTEGER])
	if not reasons.has(reason):
		return Result.failure(EconomyCodes.DATA_INVALID, "GoodsStore.%s: motivo '%s' fora do conjunto fechado (%s)." % [operation, reason, ", ".join(reasons)])
	return Result.success()


func _check_owner(operation: String, owner_id: int) -> Result:
	var open: Result = _book.check_open(owner_id)
	if open.ok:
		return open
	return Result.failure(open.code, "GoodsStore.%s: %s" % [operation, open.message])


func _check_has(operation: String, owner_id: int, good_id: String, quantity: int) -> Result:
	if quantity_of(owner_id, good_id) < quantity:
		return Result.failure(EconomyCodes.INSUFFICIENT_GOODS, "GoodsStore.%s: o dono %d tem %d de '%s' e não cobre %d." % [operation, owner_id, quantity_of(owner_id, good_id), good_id, quantity])
	return Result.success()


## Cabe no peso? A quantidade é comparada com a capacidade ANTES de multiplicar pelo peso (o produto nunca estoura o inteiro).
func _check_room(operation: String, owner_id: int, good_id: String, quantity: int) -> Result:
	var capacity: int = capacity_of(owner_id)
	if quantity > capacity or weight_of(owner_id) + quantity * _goods[good_id].weight > capacity:
		return Result.failure(EconomyCodes.CAPACITY_EXCEEDED, "GoodsStore.%s: o dono %d (capacidade %d, carrega %d) não comporta %d de '%s' (peso %d cada)." % [operation, owner_id, capacity, weight_of(owner_id), quantity, good_id, _goods[good_id].weight])
	return Result.success()


## Quantidade zero não fica guardada, nem o dono sem bens.
func _set_quantity(owner_id: int, good_id: String, value: int) -> void:
	var owned: Dictionary = _stock.get(owner_id, {})
	if value == 0:
		owned.erase(good_id)
	else:
		owned[good_id] = value
	if owned.is_empty():
		_stock.erase(owner_id)
	else:
		_stock[owner_id] = owned


func _bump(table: Dictionary[String, Dictionary], good_id: String, reason: String, quantity: int) -> void:
	var by_reason: Dictionary = table.get(good_id, {})
	by_reason[reason] = int(by_reason.get(reason, 0)) + quantity
	table[good_id] = by_reason


func _total_in_stock(good_id: String) -> int:
	var total: int = 0
	for owner_id: int in _stock:
		total += int(_stock[owner_id].get(good_id, 0))
	return total


func _sum_of(by_reason: Dictionary) -> int:
	var total: int = 0
	for reason: String in by_reason:
		total += int(by_reason[reason])
	return total


func _sorted_copy(table: Dictionary) -> Dictionary:
	var keys: Array[String] = []
	keys.assign(table.keys())
	keys.sort()
	var copy: Dictionary = {}
	for key: String in keys:
		copy[key] = table[key]
	return copy


func _sorted_nested(table: Dictionary[String, Dictionary]) -> Dictionary:
	var copy: Dictionary = {}
	for good_id: String in _sorted_copy(table):
		copy[good_id] = _sorted_copy(table[good_id])
	return copy


## `raw_value` é o valor CRU do save; cada função confere o tipo antes de usá-lo.
func _parse_stock(raw_value: Variant, stock: Dictionary[int, Dictionary]) -> Result:
	if typeof(raw_value) != TYPE_DICTIONARY:
		return _invalid_save("campo '%s' ausente ou não é um objeto" % KEY_STOCK)
	var raw_stock: Dictionary = raw_value
	for key: Variant in raw_stock.keys():
		var owner_id: int = EconomyJson.id_of_key(key)
		var raw_owned: Variant = raw_stock[key]
		if not _book.has_owner(owner_id) or typeof(raw_owned) != TYPE_DICTIONARY:
			return _invalid_save("'%s' tem a entrada '%s' inválida; esperado o ID de um dono existente e um objeto de bens" % [KEY_STOCK, str(key)])
		var owned: Dictionary = {}
		var raw_goods: Dictionary = raw_owned
		for good_key: Variant in raw_goods.keys():
			var raw_quantity: Variant = raw_goods[good_key]
			if typeof(good_key) != TYPE_STRING or not _goods.has(str(good_key)) or not EconomyJson.is_int_like(raw_quantity) or EconomyJson.to_int(raw_quantity) < 1:
				return _invalid_save("dono %d: o bem '%s' ou a quantidade é inválido; esperado um bem existente e um inteiro de 1 ou mais" % [owner_id, str(good_key)])
			owned[str(good_key)] = EconomyJson.to_int(raw_quantity)
		stock[owner_id] = owned
		if _weight_of_table(owned) > capacity_of(owner_id):
			return _invalid_save("o dono %d carrega peso acima da capacidade do tipo dele" % owner_id)
	return Result.success()


func _weight_of_table(owned: Dictionary) -> int:
	var total: int = 0
	for good_id: String in owned:
		total += int(owned[good_id]) * _goods[good_id].weight
	return total


func _parse_totals(raw_value: Variant, field: String, reasons: Array[String], table: Dictionary[String, Dictionary]) -> Result:
	if typeof(raw_value) != TYPE_DICTIONARY:
		return _invalid_save("campo '%s' ausente ou não é um objeto" % field)
	var raw_table: Dictionary = raw_value
	for good_key: Variant in raw_table.keys():
		var raw_reasons: Variant = raw_table[good_key]
		if typeof(good_key) != TYPE_STRING or not _goods.has(str(good_key)) or typeof(raw_reasons) != TYPE_DICTIONARY:
			return _invalid_save("'%s' tem a entrada '%s' inválida; esperado um bem existente e um objeto de motivos" % [field, str(good_key)])
		var by_reason: Dictionary = {}
		var raw_by_reason: Dictionary = raw_reasons
		for reason_key: Variant in raw_by_reason.keys():
			var raw_quantity: Variant = raw_by_reason[reason_key]
			if typeof(reason_key) != TYPE_STRING or not reasons.has(str(reason_key)) or not EconomyJson.is_int_like(raw_quantity) or EconomyJson.to_int(raw_quantity) < 1:
				return _invalid_save("'%s', bem '%s': o motivo '%s' ou a quantidade é inválido; esperado um motivo de %s e um inteiro de 1 ou mais" % [field, str(good_key), str(reason_key), ", ".join(reasons)])
			by_reason[str(reason_key)] = EconomyJson.to_int(raw_quantity)
		table[str(good_key)] = by_reason
	return Result.success()


func _invalid_save(detail: String) -> Result:
	return Result.failure(EconomyCodes.INVALID_SAVE, "GoodsStore.load_from: %s." % detail)
