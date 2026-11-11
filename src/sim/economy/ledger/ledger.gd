class_name Ledger
extends RefCounted
## Livro-razão da economia (LW-088; docs/modules/economy.md, seção 2; arquitetura 11.4): o ÚNICO lugar que escreve saldo (a regra F do tools/check_architecture reprova o resto). Uma conta por dono do
## `OwnerBook`, com saldo inteiro, nunca negativo (sem crédito). Três operações: `transfer`, `mint` (cria dinheiro) e `burn` (destrói), cada uma com um motivo de um conjunto FECHADO. Falha devolve `Result`
## e NÃO muda nada (toda conferência vem antes da primeira escrita). Guarda totais por motivo (movimentado, criado, destruído); a lista completa de lançamentos só existe em modo de teste. O save do livro é da LW-088c. Conservação: soma dos saldos = criado − destruído. Saldo zero não é guardado, para o mesmo estado ter uma só forma.

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


func transfer(from_id: int, to_id: int, amount: int, reason: String) -> Result:
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
	var counter_after: int = int(_moved.get(reason, 0)) + amount
	if to_after > MAX_AMOUNT or counter_after > MAX_AMOUNT:
		return _over_limit("transfer", amount, reason)
	_set_balance(from_id, from_after)
	_set_balance(to_id, to_after)
	_moved[reason] = counter_after
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
