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


## `peek_inventory`: os bens de um dono (`good_id` e `quantity`, por `good_id` crescente), o peso carregado e a capacidade do tipo; `result` falha com `ECON_UNKNOWN_OWNER` se o dono não existe.
class InventoryQuery:
	extends RefCounted

	var result: Result
	var rows: Array[Dictionary]
	var weight: int
	var capacity: int

	func _init(query_result: Result, owner_rows: Array[Dictionary], carried_weight: int, weight_capacity: int) -> void:
		result = query_result
		rows = owner_rows
		weight = carried_weight
		capacity = weight_capacity


## `peek_goods_conservation`: uma linha por bem que já teve movimento (`good_id`, `in_stock`, `created`, `destroyed`, `ok`); `ok` quando TODAS fecham (em estoque = criado − destruído, inclusive o destruído por `maintenance`).
class GoodsConservationQuery:
	extends RefCounted

	var rows: Array[Dictionary]
	var ok: bool

	func _init(conservation_rows: Array[Dictionary]) -> void:
		rows = conservation_rows
		ok = true
		for row: Dictionary in conservation_rows:
			ok = ok and bool(row["ok"])
