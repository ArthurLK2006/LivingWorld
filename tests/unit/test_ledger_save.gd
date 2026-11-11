extends GutTest
## LW-088c: o save do cadastro de donos (`OwnerBook`) e do livro-razão (`Ledger`): ida e volta pelo JSON, forma única do mesmo estado (saldo zero não é guardado) e dado inválido recusado,
## sempre deixando o estado como estava (AGENTS 12.6). As operações do `Ledger` ficam em test_ledger.gd (LW-088b). Valores esperados escritos à mão.

const OWNER_COUNT: int = 6


func _book() -> OwnerBook:
	var book: OwnerBook = OwnerBook.new()
	for owner_id: int in range(1, OWNER_COUNT + 1):
		assert_true(book.open_owner(owner_id, "npc").ok)
	return book


func _through_json(data: Dictionary) -> Dictionary:
	# Variant: o JSON devolve qualquer tipo; aqui o formato é conhecido (um objeto).
	var parsed: Variant = JSON.parse_string(JSON.stringify(data))
	assert_eq(typeof(parsed), TYPE_DICTIONARY)
	var copy: Dictionary = parsed
	return copy


func _hash_of(data: Dictionary) -> String:
	return JSON.stringify(data, "", true, true).sha256_text()


func test_save_round_trip_through_json_keeps_balances_totals_and_the_hash() -> void:
	var book: OwnerBook = _book()
	var ledger: Ledger = Ledger.new(book)
	ledger.mint(1, 500, Ledger.REASON_GAME_START)
	ledger.transfer(1, 4, 120, Ledger.REASON_SALARY)
	ledger.burn(4, 20, Ledger.REASON_TRADE)
	book.close_owner(4)
	var restored_book: OwnerBook = OwnerBook.new()
	assert_true(restored_book.load_from(_through_json(book.serialize())).ok)
	var restored: Ledger = Ledger.new(restored_book)
	var loaded: Result = restored.load_from(_through_json(ledger.serialize()))
	assert_true(loaded.ok, loaded.message)
	assert_eq(_hash_of(restored.serialize()), _hash_of(ledger.serialize()), "Mesmo estado, mesma impressão digital.")
	assert_eq([restored.balance_of(1), restored.balance_of(4), restored_book.is_closed(4), restored_book.kind_of(1)], [380, 100, true, "npc"])
	assert_eq(restored.totals_rows(), ledger.totals_rows())
	assert_eq(restored.validate(), [] as Array[String])
	assert_eq(restored_book.validate(), [] as Array[String])


func test_the_same_state_has_one_form_zero_balances_are_not_saved_and_history_is_not() -> void:
	var recording: Ledger = Ledger.new(_book(), true)
	var quiet: Ledger = Ledger.new(_book())
	assert_true(quiet.is_pristine(), "Sem movimento o livro é virgem.")
	for ledger: Ledger in [recording, quiet]:
		ledger.mint(1, 30, Ledger.REASON_GAME_START)
		ledger.transfer(1, 2, 30, Ledger.REASON_TRADE)
	assert_false(quiet.is_pristine())
	assert_eq(quiet.serialize()[Ledger.KEY_BALANCES], {"2": 30}, "O dono 1 ficou com zero e não aparece.")
	assert_eq(recording.serialize(), quiet.serialize(), "O histórico (modo de teste) não faz parte do save.")
	var order_a: Ledger = Ledger.new(_book())
	var order_b: Ledger = Ledger.new(_book())
	order_a.mint(1, 5, Ledger.REASON_GAME_START)
	order_a.mint(2, 7, Ledger.REASON_SALARY)
	order_b.mint(2, 7, Ledger.REASON_SALARY)
	order_b.mint(1, 5, Ledger.REASON_GAME_START)
	assert_eq(_hash_of(order_a.serialize()), _hash_of(order_b.serialize()), "A ordem em que os motivos apareceram não muda o save.")


func test_loading_refuses_invalid_data_and_keeps_the_previous_state() -> void:
	var ledger: Ledger = Ledger.new(_book())
	ledger.mint(1, 10, Ledger.REASON_GAME_START)
	var good: Dictionary = ledger.serialize()
	var cases: Array[Dictionary] = [
		{"label": "campo ausente", "mutate": func(data: Dictionary) -> void: data.erase(Ledger.KEY_MOVED), "fragment": "campo 'moved' ausente"},
		{"label": "campo que não é objeto", "mutate": func(data: Dictionary) -> void: data[Ledger.KEY_CREATED] = [], "fragment": "campo 'created' ausente ou não é um objeto"},
		{"label": "dono inexistente", "mutate": func(data: Dictionary) -> void: data[Ledger.KEY_BALANCES] = {"99": 10}, "fragment": "o ID de um dono existente"},
		{"label": "chave de ID fora da forma canônica", "mutate": func(data: Dictionary) -> void: data[Ledger.KEY_BALANCES] = {"01": 10}, "fragment": "o ID de um dono existente"},
		{"label": "motivo fora do conjunto", "mutate": func(data: Dictionary) -> void: data[Ledger.KEY_CREATED] = {"gift": 10}, "fragment": "um motivo de game_start"},
		{"label": "valor com fração", "mutate": func(data: Dictionary) -> void: data[Ledger.KEY_BALANCES] = {"1": 1.5}, "fragment": "um inteiro de 1 a"},
		{"label": "valor zero", "mutate": func(data: Dictionary) -> void: data[Ledger.KEY_MOVED] = {"trade": 0}, "fragment": "um inteiro de 1 a"},
		{"label": "valor como texto", "mutate": func(data: Dictionary) -> void: data[Ledger.KEY_BALANCES] = {"1": "10"}, "fragment": "um inteiro de 1 a"},
		{"label": "conservação que não fecha", "mutate": func(data: Dictionary) -> void: data[Ledger.KEY_BALANCES] = {"1": 11}, "fragment": "a conservação não fecha: soma dos saldos 11, criado 10 e destruído 0"},
	]
	for test_case: Dictionary in cases:
		var data: Dictionary = good.duplicate(true)
		var mutate: Callable = test_case["mutate"]
		mutate.call(data)
		var result: Result = ledger.load_from(data)
		assert_false(result.ok, "%s: deveria falhar." % test_case["label"])
		assert_eq(result.code, EconomyCodes.INVALID_SAVE, test_case["label"])
		assert_string_contains(result.message, test_case["fragment"], test_case["label"])
		assert_eq(ledger.serialize(), good, "%s: o livro continua como estava." % test_case["label"])


func test_the_owner_book_save_round_trips_and_refuses_invalid_entries() -> void:
	var book: OwnerBook = OwnerBook.new()
	assert_true(book.is_empty())
	book.open_owner(12, "market")
	book.open_owner(3, "npc")
	book.close_owner(3)
	assert_eq(book.serialize().keys(), ["3", "12"], "Por ID crescente, não por texto.")
	var restored: OwnerBook = OwnerBook.new()
	assert_true(restored.load_from(_through_json(book.serialize())).ok)
	assert_eq([restored.owner_ids(), restored.kind_of(12), restored.is_closed(3), restored.is_closed(12)], [[3, 12] as Array[int], "market", true, false])
	var cases: Array[Dictionary] = [
		{"label": "chave zero", "data": {"0": {"kind": "npc", "closed": false}}},
		{"label": "chave fora da forma canônica", "data": {"012": {"kind": "npc", "closed": false}}},
		{"label": "entrada que não é objeto", "data": {"1": "npc"}},
		{"label": "tipo vazio", "data": {"1": {"kind": "", "closed": false}}},
		{"label": "tipo que não é texto", "data": {"1": {"kind": 4, "closed": false}}},
		{"label": "fechado que não é booleano", "data": {"1": {"kind": "npc", "closed": 0}}},
	]
	for test_case: Dictionary in cases:
		var refused: Result = restored.load_from(test_case["data"])
		assert_eq(refused.code, EconomyCodes.INVALID_SAVE, test_case["label"])
		assert_eq(restored.owner_ids(), [3, 12] as Array[int], "%s: o cadastro continua como estava." % test_case["label"])
