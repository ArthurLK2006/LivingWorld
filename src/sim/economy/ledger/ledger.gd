class_name Ledger
extends RefCounted
## Livro-razão da economia (LW-088; docs/modules/economy.md, seção 2; arquitetura 11.4): o ÚNICO lugar que escreve saldo (a regra F do tools/check_architecture reprova o resto). Uma conta por dono do
## `OwnerBook`, com saldo inteiro, nunca negativo (sem crédito). Três operações: `transfer`, `mint` (cria dinheiro) e `burn` (destrói), cada uma com um motivo de um conjunto FECHADO. Falha devolve `Result`
## e NÃO muda nada (toda conferência vem antes da primeira escrita). Guarda totais por motivo (movimentado, criado, destruído), que vão ao save; a lista completa de lançamentos só existe em modo de teste
## e não é salva. Conservação: soma dos saldos = criado − destruído. Saldo zero não é guardado, para o mesmo estado ter uma só forma (e um só hash).

const REASON_GAME_START: String = "game_start"
const REASON_TRADE: String = "trade"
const REASON_SALARY: String = "salary"
const REASON_CONTRACT_ESCROW: String = "contract_escrow"
const REASON_CONTRACT_PAYOUT: String = "contract_payout"
const REASON_CONTRACT_REFUND: String = "contract_refund"
## Conjunto fechado de motivos (seção 2 do contrato). O jogo da Fase 3 não chama `burn`: o dinheiro só circula.
const REASONS: Array[String] = [REASON_GAME_START, REASON_TRADE, REASON_SALARY, REASON_CONTRACT_ESCROW, REASON_CONTRACT_PAYOUT, REASON_CONTRACT_REFUND]
## Teto exato do JSON (2^53 − 1): nenhum saldo nem total passa disso, para sobreviver ao save sem perder um centavo.
const MAX_AMOUNT: int = 9007199254740991
const KEY_BALANCES: String = "balances"
const KEY_MOVED: String = "moved"
const KEY_CREATED: String = "created"
const KEY_DESTROYED: String = "destroyed"

var _book: OwnerBook
var _record_history: bool
var _balances: Dictionary[int, int] = {}
var _moved: Dictionary[String, int] = {}
var _created: Dictionary[String, int] = {}
var _destroyed: Dictionary[String, int] = {}
var _history: Array[Dictionary] = []


## `book`: o cadastro de donos (existência e fechamento). `record_history`: modo de teste, guarda cada lançamento.
func _init(book: OwnerBook, record_history: bool = false) -> void:
	_book = book
	_record_history = record_history


## Confere a transferência SEM executar (as mesmas falhas de `transfer`): quem precisa de tudo ou nada em duas partes (o comércio) confere aqui antes de mexer em qualquer uma.
func check_transfer(from_id: int, to_id: int, amount: int, reason: String) -> Result:
	var checked: Result = _check_operation("transfer", amount, reason)
	if checked.ok:
		checked = _check_owner("transfer", from_id)
	if checked.ok:
		checked = _check_owner("transfer", to_id)
	if not checked.ok:
		return checked
	var from_after: int = balance_of(from_id) - amount
	if from_after < 0:
		return Result.failure(EconomyCodes.INSUFFICIENT_FUNDS, "Ledger.transfer: o dono %d tem saldo %d e não cobre %d (%s) para o dono %d." % [from_id, balance_of(from_id), amount, reason, to_id])
	var to_after: int = (from_after if to_id == from_id else balance_of(to_id)) + amount
	if to_after > MAX_AMOUNT or int(_moved.get(reason, 0)) + amount > MAX_AMOUNT:
		return _over_limit("transfer", amount, reason)
	return Result.success()


func transfer(from_id: int, to_id: int, amount: int, reason: String) -> Result:
	var checked: Result = check_transfer(from_id, to_id, amount, reason)
	if not checked.ok:
		return checked
	var from_after: int = balance_of(from_id) - amount
	var to_after: int = (from_after if to_id == from_id else balance_of(to_id)) + amount
	_set_balance(from_id, from_after)
	_set_balance(to_id, to_after)
	_moved[reason] = int(_moved.get(reason, 0)) + amount
	_record("transfer", from_id, to_id, amount, reason)
	return Result.success()


## Cria dinheiro na conta de `to_id` (o inicial de cada dono, motivo `game_start`).
func mint(to_id: int, amount: int, reason: String) -> Result:
	var checked: Result = _check_operation("mint", amount, reason)
	if checked.ok:
		checked = _check_owner("mint", to_id)
	if not checked.ok:
		return checked
	var to_after: int = balance_of(to_id) + amount
	var counter_after: int = int(_created.get(reason, 0)) + amount
	if to_after > MAX_AMOUNT or counter_after > MAX_AMOUNT:
		return _over_limit("mint", amount, reason)
	_set_balance(to_id, to_after)
	_created[reason] = counter_after
	_record("mint", IdGenerator.NO_ID, to_id, amount, reason)
	return Result.success()


## Destrói dinheiro da conta de `from_id`.
func burn(from_id: int, amount: int, reason: String) -> Result:
	var checked: Result = _check_operation("burn", amount, reason)
	if checked.ok:
		checked = _check_owner("burn", from_id)
	if not checked.ok:
		return checked
	var from_after: int = balance_of(from_id) - amount
	if from_after < 0:
		return Result.failure(EconomyCodes.INSUFFICIENT_FUNDS, "Ledger.burn: o dono %d tem saldo %d e não cobre destruir %d (%s)." % [from_id, balance_of(from_id), amount, reason])
	var counter_after: int = int(_destroyed.get(reason, 0)) + amount
	if counter_after > MAX_AMOUNT:
		return _over_limit("burn", amount, reason)
	_set_balance(from_id, from_after)
	_destroyed[reason] = counter_after
	_record("burn", from_id, IdGenerator.NO_ID, amount, reason)
	return Result.success()


## Saldo do dono (0 se não tem nada; quem pergunta confere antes se o dono existe).
func balance_of(owner_id: int) -> int:
	return int(_balances.get(owner_id, 0))


func sum_of_balances() -> int:
	var total: int = 0
	for owner_id: int in _balances:
		total += _balances[owner_id]
	return total


func total_created() -> int:
	return _sum_of(_created)


func total_destroyed() -> int:
	return _sum_of(_destroyed)


## O teste de ouro: soma de todas as contas = criado − destruído.
func is_conserved() -> bool:
	return sum_of_balances() == total_created() - total_destroyed()


## Uma linha por motivo que já teve movimento (`reason`, `moved`, `created`, `destroyed`), por motivo em ordem alfabética.
func totals_rows() -> Array[Dictionary]:
	var reasons: Array[String] = REASONS.duplicate()
	reasons.sort()
	var rows: Array[Dictionary] = []
	for reason: String in reasons:
		var moved: int = int(_moved.get(reason, 0))
		var created: int = int(_created.get(reason, 0))
		var destroyed: int = int(_destroyed.get(reason, 0))
		if moved + created + destroyed > 0:
			rows.append({"reason": reason, "moved": moved, "created": created, "destroyed": destroyed})
	return rows


## Os lançamentos, do mais antigo ao mais novo (cópia). Vazia fora do modo de teste.
func peek_history() -> Array[Dictionary]:
	return _history.duplicate(true)


## Nenhuma conta com saldo e nenhum total: o estado de um jogo em que ninguém movimentou dinheiro.
func is_pristine() -> bool:
	return _balances.is_empty() and _moved.is_empty() and _created.is_empty() and _destroyed.is_empty()


func serialize() -> Dictionary:
	var balances: Dictionary = {}
	var ids: Array[int] = []
	ids.assign(_balances.keys())
	ids.sort()
	for owner_id: int in ids:
		balances[str(owner_id)] = _balances[owner_id]
	return {KEY_BALANCES: balances, KEY_MOVED: _sorted_copy(_moved), KEY_CREATED: _sorted_copy(_created), KEY_DESTROYED: _sorted_copy(_destroyed)}


## Confere tudo antes de alterar o estado: formato, donos existentes, motivos do conjunto e a conservação. Se algo for inválido, o livro fica como estava.
func load_from(data: Dictionary) -> Result:
	var balances: Dictionary[int, int] = {}
	var totals: Dictionary[String, Dictionary] = {}
	for field: String in [KEY_BALANCES, KEY_MOVED, KEY_CREATED, KEY_DESTROYED]:
		var raw_table: Variant = data.get(field)
		if typeof(raw_table) != TYPE_DICTIONARY:
			return _invalid_save("campo '%s' ausente ou não é um objeto" % field)
		var table: Dictionary = raw_table
		var parsed: Dictionary = {}
		for key: Variant in table.keys():
			var raw_amount: Variant = table[key]
			var is_balance: bool = field == KEY_BALANCES
			var name: String = str(key)
			var valid_key: bool = _book.has_owner(EconomyJson.id_of_key(key)) if is_balance else REASONS.has(name)
			if not valid_key or not EconomyJson.is_int_like(raw_amount) or EconomyJson.to_int(raw_amount) < 1 or EconomyJson.to_int(raw_amount) > MAX_AMOUNT:
				return _invalid_save("'%s' tem a entrada '%s' inválida; esperado %s e um inteiro de 1 a %d" % [field, name, "o ID de um dono existente" if is_balance else "um motivo de %s" % ", ".join(REASONS), MAX_AMOUNT])
			parsed[name] = EconomyJson.to_int(raw_amount)
		totals[field] = parsed
	for name: String in totals[KEY_BALANCES]:
		balances[name.to_int()] = totals[KEY_BALANCES][name]
	var sum: int = 0
	for amount: int in balances.values():
		sum += amount
	var created: int = _sum_of_values(totals[KEY_CREATED])
	var destroyed: int = _sum_of_values(totals[KEY_DESTROYED])
	if sum != created - destroyed:
		return _invalid_save("a conservação não fecha: soma dos saldos %d, criado %d e destruído %d" % [sum, created, destroyed])
	_balances = balances
	_moved = _typed_totals(totals[KEY_MOVED])
	_created = _typed_totals(totals[KEY_CREATED])
	_destroyed = _typed_totals(totals[KEY_DESTROYED])
	_history.clear()
	return Result.success()


func validate() -> Array[String]:
	var problems: Array[String] = []
	for owner_id: int in _balances:
		if not _book.has_owner(owner_id):
			problems.append("saldo %d de um dono que não existe (%d)" % [_balances[owner_id], owner_id])
		if _balances[owner_id] < 1:
			problems.append("o dono %d tem saldo %d; só se guarda saldo positivo" % [owner_id, _balances[owner_id]])
	if not is_conserved():
		problems.append("a conservação do dinheiro não fecha: soma dos saldos %d, criado %d, destruído %d" % [sum_of_balances(), total_created(), total_destroyed()])
	return problems


func _check_operation(operation: String, amount: int, reason: String) -> Result:
	if amount < 1 or amount > MAX_AMOUNT:
		return Result.failure(EconomyCodes.BAD_AMOUNT, "Ledger.%s: valor %d inválido; esperado um inteiro de 1 a %d." % [operation, amount, MAX_AMOUNT])
	if not REASONS.has(reason):
		return Result.failure(EconomyCodes.DATA_INVALID, "Ledger.%s: motivo '%s' fora do conjunto fechado (%s)." % [operation, reason, ", ".join(REASONS)])
	return Result.success()


func _check_owner(operation: String, owner_id: int) -> Result:
	var open: Result = _book.check_open(owner_id)
	if open.ok:
		return open
	return Result.failure(open.code, "Ledger.%s: %s" % [operation, open.message])


func _over_limit(operation: String, amount: int, reason: String) -> Result:
	return Result.failure(EconomyCodes.BAD_AMOUNT, "Ledger.%s: %d (%s) levaria um saldo ou um total acima de %d, o limite exato do save." % [operation, amount, reason, MAX_AMOUNT])


## Saldo zero não fica guardado.
func _set_balance(owner_id: int, value: int) -> void:
	if value == 0:
		_balances.erase(owner_id)
	else:
		_balances[owner_id] = value


func _record(kind: String, from_id: int, to_id: int, amount: int, reason: String) -> void:
	if _record_history:
		_history.append({"kind": kind, "from_id": from_id, "to_id": to_id, "amount": amount, "reason": reason})


func _sum_of(table: Dictionary[String, int]) -> int:
	var total: int = 0
	for reason: String in table:
		total += table[reason]
	return total


func _sum_of_values(table: Dictionary) -> int:
	var total: int = 0
	for amount: int in table.values():
		total += amount
	return total


## Cópia com as chaves em ordem alfabética (o save não depende da ordem em que os motivos apareceram).
func _sorted_copy(table: Dictionary[String, int]) -> Dictionary:
	var keys: Array[String] = []
	keys.assign(table.keys())
	keys.sort()
	var copy: Dictionary = {}
	for reason: String in keys:
		copy[reason] = table[reason]
	return copy


func _typed_totals(parsed: Dictionary) -> Dictionary[String, int]:
	var typed: Dictionary[String, int] = {}
	for reason: String in parsed:
		typed[reason] = parsed[reason]
	return typed


func _invalid_save(detail: String) -> Result:
	return Result.failure(EconomyCodes.INVALID_SAVE, "Ledger.load_from: %s." % detail)
