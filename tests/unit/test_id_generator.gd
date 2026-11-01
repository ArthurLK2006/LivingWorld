extends GutTest


func test_first_id_is_not_the_no_id_value() -> void:
	var ids: IdGenerator = IdGenerator.new()
	assert_eq(ids.next_id(), IdGenerator.FIRST_ID)
	assert_ne(IdGenerator.FIRST_ID, IdGenerator.NO_ID)


func test_ids_are_increasing_and_unique() -> void:
	var ids: IdGenerator = IdGenerator.new()
	var seen: Dictionary = {}
	var previous: int = IdGenerator.NO_ID
	for _i: int in 1000:
		var id: int = ids.next_id()
		assert_gt(id, previous, "ID deve ser maior que o anterior.")
		assert_false(seen.has(id), "ID repetido: %d" % id)
		seen[id] = true
		previous = id


func test_discarded_id_is_never_issued_again() -> void:
	var ids: IdGenerator = IdGenerator.new()
	var discarded: int = ids.next_id()
	var later: Array[int] = [ids.next_id(), ids.next_id(), ids.next_id()]
	assert_does_not_have(later, discarded, "Um ID descartado não pode voltar.")


func test_saved_and_restored_state_continues_the_sequence() -> void:
	var original: IdGenerator = IdGenerator.new()
	for _i: int in 5:
		original.next_id()
	var restored: IdGenerator = IdGenerator.new()
	var result: Result = restored.on_load(original.serialize())
	assert_true(result.ok, result.message)
	assert_eq(restored.next_id(), original.next_id(), "A sequência deve continuar do mesmo ponto.")


func test_state_survives_a_json_round_trip() -> void:
	var original: IdGenerator = IdGenerator.new()
	for _i: int in 41:
		original.next_id()
	var parsed: Variant = JSON.parse_string(JSON.stringify(original.serialize()))
	var restored: IdGenerator = IdGenerator.new()
	var result: Result = restored.on_load(parsed)
	assert_true(result.ok, result.message)
	assert_eq(restored.next_id(), 42)


func test_on_load_rejects_invalid_data_without_changing_state() -> void:
	var ids: IdGenerator = IdGenerator.new()
	ids.next_id()
	var bad_inputs: Array[Dictionary] = [
		{},
		{"next_id": "7"},
		{"next_id": 2.5},
		{"next_id": 0},
		{"next_id": IdGenerator.MAX_ID + 1},
	]
	for bad: Dictionary in bad_inputs:
		var result: Result = ids.on_load(bad)
		assert_false(result.ok, "Deveria rejeitar %s" % str(bad))
		assert_string_contains(result.message, "IdGenerator.on_load")
	assert_eq(ids.next_id(), 2, "Dado inválido não pode alterar o contador.")


func test_exhausted_generator_returns_no_id_and_reports_error() -> void:
	var ids: IdGenerator = IdGenerator.new()
	assert_true(ids.on_load({"next_id": IdGenerator.MAX_ID - 1}).ok)
	assert_eq(ids.next_id(), IdGenerator.MAX_ID - 1, "O último ID válido ainda é entregue.")
	assert_eq(ids.next_id(), IdGenerator.NO_ID)
	assert_push_error("IDs esgotados")


func test_validate_and_debug_summary() -> void:
	var ids: IdGenerator = IdGenerator.new()
	ids.next_id()
	ids.next_id()
	assert_eq(ids.validate().size(), 0)
	assert_eq(ids.debug_summary(), {"next_id": 3, "issued_count": 2})
