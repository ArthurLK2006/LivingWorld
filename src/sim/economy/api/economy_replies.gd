class_name EconomyReplies
extends RefCounted
## Tipos de resposta da `economy` (docs/modules/economy.md, seção 10): a porta devolve CÓPIAS destes tipos, nunca um objeto interno (lição da LW-085a). Só os da LW-088; cada
## tarefa acrescenta os seus. Todas as listas saem por ordem crescente.


## `peek_balance`: o saldo de um dono; `result` falha com `ECON_UNKNOWN_OWNER` se o dono não existe (então `balance` não vale).
class BalanceQuery:
	extends RefCounted

	var result: Result
	var balance: int

	func _init(query_result: Result, owner_balance: int) -> void:
		result = query_result
		balance = owner_balance


## `peek_conservation`: a soma de todas as contas, o dinheiro criado e o destruído; `ok` quando soma = criado − destruído (o teste de ouro).
class ConservationQuery:
	extends RefCounted

	var sum: int
	var created: int
	var destroyed: int
	var ok: bool

	func _init(balances_sum: int, total_created: int, total_destroyed: int) -> void:
		sum = balances_sum
		created = total_created
		destroyed = total_destroyed
		ok = balances_sum == total_created - total_destroyed


## `peek_ledger_totals`: uma linha por motivo (`reason`, `moved`, `created`, `destroyed`), por motivo em ordem alfabética; só os motivos que já tiveram movimento.
class LedgerTotals:
	extends RefCounted

	var rows: Array[Dictionary]

	func _init(totals_rows: Array[Dictionary]) -> void:
		rows = totals_rows
