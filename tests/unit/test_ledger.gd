extends GutTest
## LW-088b: o livro-razão (`Ledger`) e o cadastro de donos (`OwnerBook`) (docs/modules/economy.md, seção 2). O teste de ouro (soma das contas = criado − destruído) roda depois de milhares de operações
## aleatórias contra um modelo escrito aqui, à parte; falha devolve `Result` e não muda nada. O save do livro, a porta do módulo e a regra de arquitetura são da LW-088c. Valores esperados escritos à mão.

const WORLD_SEED: int = 11
const STREAM: String = "ledger_test"
const OPERATIONS: int = 6000
const OWNER_COUNT: int = 6
const MAX_AMOUNT: int = 9007199254740991


func _book(owners: int = OWNER_COUNT) -> OwnerBook:
	var book: OwnerBook = OwnerBook.new()
	for owner_id: int in range(1, owners + 1):
		assert_true(book.open_owner(owner_id, "npc").ok)
	return book


## Tudo o que dá para ver de fora do livro: saldos dos donos 0 a OWNER_COUNT + 1, os totais por motivo, o criado e o destruído.
func _snapshot(ledger: Ledger) -> Array:
	var balances: Array[int] = []
	for owner_id: int in range(0, OWNER_COUNT + 2):
		balances.append(ledger.balance_of(owner_id))
	return [balances, ledger.totals_rows(), ledger.total_created(), ledger.total_destroyed()]


func test_mint_transfer_and_burn_move_the_balances_and_the_totals() -> void:
	var ledger: Ledger = Ledger.new(_book())
	assert_true(ledger.mint(1, 100, Ledger.REASON_GAME_START).ok)
	assert_true(ledger.transfer(1, 2, 30, Ledger.REASON_TRADE).ok)
	assert_true(ledger.burn(2, 10, Ledger.REASON_SALARY).ok)
	assert_eq([ledger.balance_of(1), ledger.balance_of(2), ledger.balance_of(3)], [70, 20, 0])
	assert_eq([ledger.sum_of_balances(), ledger.total_created(), ledger.total_destroyed()], [90, 100, 10])
	assert_true(ledger.is_conserved())
	assert_eq(ledger.totals_rows(), [{"reason": "game_start", "moved": 0, "created": 100, "destroyed": 0}, {"reason": "salary", "moved": 0, "created": 0, "destroyed": 10}, {"reason": "trade", "moved": 30, "created": 0, "destroyed": 0}] as Array[Dictionary])


func test_a_transfer_or_burn_without_funds_returns_an_error_and_changes_nothing() -> void:
	var ledger: Ledger = Ledger.new(_book())
	ledger.mint(1, 50, Ledger.REASON_GAME_START)
	var before: Array = _snapshot(ledger)
	var short_transfer: Result = ledger.transfer(1, 2, 51, Ledger.REASON_TRADE)
	assert_eq(short_transfer.code, EconomyCodes.INSUFFICIENT_FUNDS)
	assert_string_contains(short_transfer.message, "o dono 1 tem saldo 50 e não cobre 51")
	var short_burn: Result = ledger.burn(2, 1, Ledger.REASON_SALARY)
	assert_eq(short_burn.code, EconomyCodes.INSUFFICIENT_FUNDS)
	assert_eq(_snapshot(ledger), before, "Falha não muda saldo nem total.")
	assert_true(ledger.transfer(1, 2, 50, Ledger.REASON_TRADE).ok, "Exatamente o saldo cabe.")
	assert_eq([ledger.balance_of(1), ledger.balance_of(2)], [0, 50])


func test_invalid_calls_are_refused_with_the_right_code_and_change_nothing() -> void:
	var book: OwnerBook = _book()
	var ledger: Ledger = Ledger.new(book)
	ledger.mint(1, 40, Ledger.REASON_GAME_START)
	book.close_owner(3)
	var before: Array = _snapshot(ledger)
	var cases: Array[Dictionary] = [
		{"label": "valor zero", "result": ledger.transfer(1, 2, 0, Ledger.REASON_TRADE), "code": EconomyCodes.BAD_AMOUNT},
		{"label": "valor negativo", "result": ledger.mint(1, -5, Ledger.REASON_GAME_START), "code": EconomyCodes.BAD_AMOUNT},
		{"label": "valor acima do teto", "result": ledger.burn(1, MAX_AMOUNT + 1, Ledger.REASON_SALARY), "code": EconomyCodes.BAD_AMOUNT},
		{"label": "motivo fora do conjunto", "result": ledger.transfer(1, 2, 5, "gift"), "code": EconomyCodes.DATA_INVALID},
		{"label": "origem inexistente", "result": ledger.transfer(99, 2, 5, Ledger.REASON_TRADE), "code": EconomyCodes.UNKNOWN_OWNER},
		{"label": "destino inexistente", "result": ledger.transfer(1, 99, 5, Ledger.REASON_TRADE), "code": EconomyCodes.UNKNOWN_OWNER},
		{"label": "mint em dono inexistente", "result": ledger.mint(0, 5, Ledger.REASON_GAME_START), "code": EconomyCodes.UNKNOWN_OWNER},
		{"label": "destino fechado", "result": ledger.transfer(1, 3, 5, Ledger.REASON_TRADE), "code": EconomyCodes.OWNER_CLOSED},
		{"label": "origem fechada", "result": ledger.transfer(3, 1, 5, Ledger.REASON_TRADE), "code": EconomyCodes.OWNER_CLOSED},
		{"label": "mint em dono fechado", "result": ledger.mint(3, 5, Ledger.REASON_GAME_START), "code": EconomyCodes.OWNER_CLOSED},
		{"label": "burn em dono fechado", "result": ledger.burn(3, 5, Ledger.REASON_SALARY), "code": EconomyCodes.OWNER_CLOSED},
	]
	for test_case: Dictionary in cases:
		var result: Result = test_case["result"]
		assert_false(result.ok, "%s: deveria falhar." % test_case["label"])
		assert_eq(result.code, test_case["code"], test_case["label"])
		assert_true(result.message.begins_with("Ledger."), "%s: a mensagem diz de onde veio." % test_case["label"])
	assert_eq(_snapshot(ledger), before, "Nenhuma falha muda o livro.")


func test_the_exact_json_limit_and_closed_owners_that_keep_their_money() -> void:
	var book: OwnerBook = _book()
	var ledger: Ledger = Ledger.new(book)
	assert_true(ledger.mint(1, MAX_AMOUNT, Ledger.REASON_GAME_START).ok, "O teto exato cabe.")
	assert_eq(ledger.mint(1, 1, Ledger.REASON_GAME_START).code, EconomyCodes.BAD_AMOUNT, "Um a mais passaria do limite exato do save.")
	assert_true(ledger.mint(2, 1, Ledger.REASON_SALARY).ok)
	assert_eq(ledger.transfer(1, 2, MAX_AMOUNT, Ledger.REASON_TRADE).code, EconomyCodes.BAD_AMOUNT, "A conta de destino também não passa do limite.")
	assert_eq([ledger.balance_of(1), ledger.balance_of(2)], [MAX_AMOUNT, 1], "A recusa não moveu nada.")
	assert_true(ledger.transfer(1, 2, MAX_AMOUNT - 1, Ledger.REASON_TRADE).ok)
	assert_eq([ledger.balance_of(1), ledger.balance_of(2)], [1, MAX_AMOUNT])
	book.close_owner(2)
	assert_eq([ledger.balance_of(2), ledger.sum_of_balances(), ledger.is_conserved()], [MAX_AMOUNT, MAX_AMOUNT + 1, true], "O dono fechado continua com o saldo e na soma da conservação.")
	assert_eq(ledger.transfer(1, 1, 2, Ledger.REASON_TRADE).code, EconomyCodes.INSUFFICIENT_FUNDS, "Transferir para si mesmo também exige saldo.")


func test_thousands_of_random_operations_keep_the_gold_test_against_a_separate_model() -> void:
	var book: OwnerBook = _book()
	book.close_owner(OWNER_COUNT)
	var ledger: Ledger = Ledger.new(book)
	var rng: WorldRng = WorldRng.new(WORLD_SEED)
	var model: Dictionary[int, int] = {}
	var created: int = 0
	var destroyed: int = 0
	var failures: int = 0
	for _step: int in OPERATIONS:
		var kind: int = rng.range_int(STREAM, 0, 2)
		var first: int = rng.range_int(STREAM, 1, OWNER_COUNT + 1)
		var second: int = rng.range_int(STREAM, 1, OWNER_COUNT + 1)
		var amount: int = rng.range_int(STREAM, 1, 200)
		var reason: String = Ledger.REASONS[rng.range_int(STREAM, 0, Ledger.REASONS.size() - 1)]
		var first_ok: bool = first <= OWNER_COUNT - 1
		var second_ok: bool = second <= OWNER_COUNT - 1
		var result: Result
		if kind == 0:
			result = ledger.mint(first, amount, reason)
			if first_ok:
				model[first] = int(model.get(first, 0)) + amount
				created += amount
		elif kind == 1:
			result = ledger.burn(first, amount, reason)
			if first_ok and int(model.get(first, 0)) >= amount:
				model[first] = int(model.get(first, 0)) - amount
				destroyed += amount
		else:
			result = ledger.transfer(first, second, amount, reason)
			if first_ok and second_ok and int(model.get(first, 0)) >= amount:
				model[first] = int(model.get(first, 0)) - amount
				model[second] = int(model.get(second, 0)) + amount
		if not result.ok:
			failures += 1
		assert_true(ledger.is_conserved(), "A conservação fecha a cada operação.")
	for owner_id: int in range(1, OWNER_COUNT + 1):
		assert_eq(ledger.balance_of(owner_id), int(model.get(owner_id, 0)), "Saldo do dono %d igual ao do modelo." % owner_id)
	assert_eq([ledger.total_created(), ledger.total_destroyed()], [created, destroyed])
	assert_eq(ledger.sum_of_balances(), created - destroyed, "Soma das contas = inicial + criado − destruído.")
	assert_gt(failures, 100, "O sorteio inclui donos inexistentes, fechados e saldo curto: muitas falhas, todas sem efeito.")


func test_history_is_kept_only_in_test_mode_and_only_for_posted_entries() -> void:
	var recording: Ledger = Ledger.new(_book(), true)
	var quiet: Ledger = Ledger.new(_book())
	for ledger: Ledger in [recording, quiet]:
		ledger.mint(1, 10, Ledger.REASON_GAME_START)
		ledger.transfer(1, 2, 4, Ledger.REASON_SALARY)
		ledger.transfer(1, 2, 400, Ledger.REASON_SALARY)
		ledger.burn(2, 1, Ledger.REASON_TRADE)
	assert_eq(recording.peek_history(), [
		{"kind": "mint", "from_id": 0, "to_id": 1, "amount": 10, "reason": "game_start"},
		{"kind": "transfer", "from_id": 1, "to_id": 2, "amount": 4, "reason": "salary"},
		{"kind": "burn", "from_id": 2, "to_id": 0, "amount": 1, "reason": "trade"},
	] as Array[Dictionary], "A que falhou não entra; as outras saem por ordem.")
	assert_eq(quiet.peek_history(), [] as Array[Dictionary], "No jogo só os totais por motivo existem.")
	assert_eq(_snapshot(recording), _snapshot(quiet), "O histórico não muda saldo nem total.")


func test_the_owner_book_opens_idempotently_closes_for_good_and_lists_in_order() -> void:
	var book: OwnerBook = OwnerBook.new()
	for owner_id: int in [3, 1, 2]:
		assert_true(book.open_owner(owner_id, "npc").ok)
	assert_eq(book.owner_ids(), [1, 2, 3] as Array[int], "Sempre por ID crescente.")
	assert_true(book.open_owner(2, "market").ok, "Abrir de novo é inofensivo e não troca o tipo.")
	assert_eq(book.kind_of(2), "npc")
	assert_eq(book.open_owner(0, "npc").code, EconomyCodes.UNKNOWN_OWNER)
	assert_eq(book.open_owner(MAX_AMOUNT + 1, "npc").code, EconomyCodes.UNKNOWN_OWNER)
	assert_eq(book.open_owner(7, "").code, EconomyCodes.DATA_INVALID)
	assert_false(book.has_owner(7), "O pedido recusado não abre nada.")
	assert_eq(book.close_owner(9).code, EconomyCodes.UNKNOWN_OWNER)
	assert_true(book.close_owner(2).ok)
	assert_true(book.close_owner(2).ok, "Fechar duas vezes é inofensivo.")
	assert_eq([book.is_closed(2), book.is_closed(1), book.is_closed(9)], [true, false, false])
	assert_eq([book.check_open(1).ok, book.check_open(2).code, book.check_open(9).code], [true, EconomyCodes.OWNER_CLOSED, EconomyCodes.UNKNOWN_OWNER])
