class_name WagePayer
extends RefCounted
## A folha de pagamento por hora (LW-095; docs/modules/economy.md, seção 6): `payer_id` (a conta do local de produção ou do mercado do povoado) paga `wage` a CADA trabalhador, pelo `Ledger` (motivo `salary`). Tudo ou nada:
## `can_pay` confere o saldo para a folha inteira e se todas as contas dos trabalhadores estão abertas, e só então `pay` move o dinheiro. Quem chama decide o que fazer quando não cabe (o local para por `NO_FUNDS`).

var _book: OwnerBook
var _ledger: Ledger


func _init(owner_book: OwnerBook, money_ledger: Ledger) -> void:
	_book = owner_book
	_ledger = money_ledger


## A folha da hora cabe? Saldo de `wage` vezes o número de trabalhadores e todos com a conta aberta. Salário 0 (ou ninguém para pagar) sempre cabe.
func can_pay(payer_id: int, wage: int, worker_ids: Array) -> bool:
	if wage <= 0 or worker_ids.is_empty():
		return true
	if _ledger.balance_of(payer_id) < wage * worker_ids.size():
		return false
	for worker_id: int in worker_ids:
		if not _book.has_owner(worker_id) or _book.is_closed(worker_id):
			return false
	return true


## Paga `wage` a cada trabalhador, em ordem. Só vale depois de `can_pay`; a primeira transferência que falhar devolve o erro dela.
func pay(payer_id: int, wage: int, worker_ids: Array) -> Result:
	if wage <= 0:
		return Result.success()
	for worker_id: int in worker_ids:
		var paid: Result = _ledger.transfer(payer_id, worker_id, wage, Ledger.REASON_SALARY)
		if not paid.ok:
			return paid
	return Result.success()
