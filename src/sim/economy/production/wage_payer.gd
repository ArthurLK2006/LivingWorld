class_name WagePayer
extends RefCounted
## A folha de pagamento por hora (LW-095; docs/modules/economy.md, seção 6): `payer_id` (a conta do local de produção ou do mercado do povoado) paga `wage` a CADA trabalhador, pelo `Ledger` (motivo `salary`). Tudo ou nada:
## `can_pay` confere o saldo para a folha inteira e se todas as contas dos trabalhadores estão abertas, e só então `pay` move o dinheiro. Quem chama decide o que fazer quando não cabe (o local para por `NO_FUNDS`).

var _book: OwnerBook
var _ledger: Ledger


func _init(owner_book: OwnerBook, money_ledger: Ledger) -> void:
	_book = owner_book
	_ledger = money_ledger


## A folha da hora cabe? Saldo de `wage` vezes o número de trabalhadores, todos com a conta aberta e cada transferência aceita pelo `Ledger` (por exemplo o teto de saldo de quem recebe). Salário 0 (ou ninguém para pagar) sempre cabe.
func can_pay(payer_id: int, wage: int, worker_ids: Array) -> bool:
	if wage <= 0 or worker_ids.is_empty():
		return true
	if _ledger.balance_of(payer_id) < wage * worker_ids.size():
		return false
	for worker_id: int in worker_ids:
		if not _book.has_owner(worker_id) or _book.is_closed(worker_id):
			return false
		if not _ledger.check_transfer(payer_id, worker_id, wage, Ledger.REASON_SALARY).ok:
			return false
	return true


## Paga `wage` a cada trabalhador, em ordem, TUDO OU NADA (R8-M1): confere o saldo da folha inteira e cada transferência ANTES de mover a primeira, então um pagamento que falharia no meio não deixa ninguém pago pela metade; a primeira conferência que falhar
## devolve o erro dela e nada muda.
func pay(payer_id: int, wage: int, worker_ids: Array) -> Result:
	if wage <= 0:
		return Result.success()
	if _ledger.balance_of(payer_id) < wage * worker_ids.size():
		return Result.failure(EconomyCodes.INSUFFICIENT_FUNDS, "WagePayer.pay: o pagador %d tem saldo %d e não cobre a folha de %d (%d trabalhador(es) × %d)." % [payer_id, _ledger.balance_of(payer_id), wage * worker_ids.size(), worker_ids.size(), wage])
	for worker_id: int in worker_ids:
		var checked: Result = _ledger.check_transfer(payer_id, worker_id, wage, Ledger.REASON_SALARY)
		if not checked.ok:
			return checked
	for worker_id: int in worker_ids:
		var paid: Result = _ledger.transfer(payer_id, worker_id, wage, Ledger.REASON_SALARY)
		if not paid.ok:
			return paid
	return Result.success()
