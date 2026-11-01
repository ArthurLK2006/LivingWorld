extends GutTest

const STREAM: String = "test_stream"


func _draw(rng: WorldRng, stream_name: String, count: int) -> Array[int]:
	var values: Array[int] = []
	for _i: int in count:
		values.append(rng.range_int(stream_name, 0, 1000000))
	return values


func test_same_seed_gives_same_sequence() -> void:
	assert_eq(_draw(WorldRng.new(42), STREAM, 100), _draw(WorldRng.new(42), STREAM, 100))


func test_different_seeds_give_different_sequences() -> void:
	assert_ne(_draw(WorldRng.new(42), STREAM, 20), _draw(WorldRng.new(43), STREAM, 20))


func test_different_stream_names_give_different_sequences() -> void:
	var rng: WorldRng = WorldRng.new(42)
	assert_ne(_draw(rng, "stream_a", 20), _draw(rng, "stream_b", 20))


func test_streams_do_not_interfere_with_each_other() -> void:
	var alone: WorldRng = WorldRng.new(7)
	var expected: Array[int] = _draw(alone, "stream_a", 30)
	var mixed: WorldRng = WorldRng.new(7)
	var actual: Array[int] = []
	for _i: int in 30:
		actual.append(mixed.range_int("stream_a", 0, 1000000))
		mixed.range_int("stream_b", 0, 1000000)
		mixed.range_int("stream_b", 0, 1000000)
	assert_eq(actual, expected, "Sortear em outro fluxo não pode alterar a sequência de um fluxo.")


func test_stream_seed_is_derived_by_sha256_of_seed_and_name() -> void:
	var expected: int = "7:stream_a".sha256_buffer().decode_s64(0)
	assert_eq(WorldRng.derive_stream_seed(7, "stream_a"), expected)
	assert_ne(WorldRng.derive_stream_seed(7, "stream_a"), WorldRng.derive_stream_seed(8, "stream_a"))


func test_saved_state_continues_the_exact_sequence() -> void:
	var original: WorldRng = WorldRng.new(99)
	_draw(original, "stream_a", 13)
	_draw(original, "stream_b", 5)
	var restored: WorldRng = WorldRng.new(0)
	var result: Result = restored.on_load(original.serialize())
	assert_true(result.ok, result.message)
	assert_eq(restored.world_seed, 99)
	assert_eq(_draw(restored, "stream_a", 50), _draw(original, "stream_a", 50))
	assert_eq(_draw(restored, "stream_b", 50), _draw(original, "stream_b", 50))


func test_state_survives_json_round_trip_with_64_bit_values() -> void:
	var original: WorldRng = WorldRng.new(-9223372036854775807)
	_draw(original, STREAM, 7)
	var parsed: Variant = JSON.parse_string(JSON.stringify(original.serialize()))
	var restored: WorldRng = WorldRng.new(1)
	var result: Result = restored.on_load(parsed)
	assert_true(result.ok, result.message)
	assert_eq(restored.world_seed, -9223372036854775807)
	assert_eq(_draw(restored, STREAM, 40), _draw(original, STREAM, 40))


func test_stream_created_after_restore_matches_a_fresh_generator() -> void:
	var original: WorldRng = WorldRng.new(5)
	_draw(original, "stream_a", 3)
	var restored: WorldRng = WorldRng.new(0)
	restored.on_load(original.serialize())
	assert_eq(_draw(restored, "new_stream", 10), _draw(WorldRng.new(5), "new_stream", 10))


func test_on_load_rejects_invalid_data_without_changing_state() -> void:
	var rng: WorldRng = WorldRng.new(11)
	var expected: Array[int] = _draw(WorldRng.new(11), STREAM, 5)
	var bad_inputs: Array[Dictionary] = [
		{},
		{"world_seed": 5, "streams": {}},
		{"world_seed": "abc", "streams": {}},
		{"world_seed": "007", "streams": {}},
		{"world_seed": "5", "streams": []},
		{"world_seed": "5", "streams": {"s": 3}},
		{"world_seed": "5", "streams": {"s": {"seed": "1"}}},
		{"world_seed": "5", "streams": {"s": {"seed": "1", "state": "99999999999999999999"}}},
	]
	for bad: Dictionary in bad_inputs:
		var result: Result = rng.on_load(bad)
		assert_false(result.ok, "Deveria rejeitar %s" % str(bad))
		assert_string_contains(result.message, "WorldRng.on_load")
	assert_eq(rng.world_seed, 11, "Dado inválido não pode alterar a semente.")
	assert_eq(_draw(rng, STREAM, 5), expected, "Dado inválido não pode alterar os fluxos.")


func test_range_int_respects_bounds_including_single_value() -> void:
	var rng: WorldRng = WorldRng.new(3)
	for _i: int in 500:
		var value: int = rng.range_int(STREAM, -3, 4)
		assert_between(value, -3, 4)
	assert_eq(rng.range_int(STREAM, 9, 9), 9)


func test_inverted_range_and_unnamed_stream_report_errors() -> void:
	var rng: WorldRng = WorldRng.new(3)
	assert_eq(rng.range_int(STREAM, 5, 1), 5)
	assert_push_error("faixa invertida")
	rng.range_int("", 0, 1)
	assert_push_error("fluxo sem nome")


func test_validate_and_debug_summary() -> void:
	var rng: WorldRng = WorldRng.new(21)
	_draw(rng, "stream_b", 1)
	_draw(rng, "stream_a", 1)
	assert_eq(rng.validate().size(), 0)
	assert_eq(rng.debug_summary(), {"world_seed": 21, "streams": ["stream_a", "stream_b"]})
	var tampered: Dictionary = rng.serialize()
	tampered["world_seed"] = "22"
	var other: WorldRng = WorldRng.new(0)
	other.on_load(tampered)
	assert_eq(other.validate().size(), 2, "Semente do mundo trocada deve ser apontada por fluxo.")


func test_seed_text_accepts_64_bit_limits_and_rejects_overflow() -> void:
	var rng: WorldRng = WorldRng.new(1)
	assert_true(rng.on_load({"world_seed": "9223372036854775807", "streams": {}}).ok)
	assert_true(rng.on_load({"world_seed": "-9223372036854775808", "streams": {}}).ok)
	assert_eq(rng.world_seed, -9223372036854775808)
	assert_false(rng.on_load({"world_seed": "9223372036854775808", "streams": {}}).ok)
	assert_false(rng.on_load({"world_seed": "-9223372036854775809", "streams": {}}).ok)
	assert_false(rng.on_load({"world_seed": "+5", "streams": {}}).ok)
	assert_false(rng.on_load({"world_seed": "-", "streams": {}}).ok)
	assert_eq(rng.world_seed, -9223372036854775808, "Rejeições não alteram o estado.")


func test_golden_values_for_pinned_godot_version() -> void:
	# Valores de referência do Godot 4.7.2 (DEC-012). Se este teste falhar após trocar de versão
	# do Godot, o algoritmo do gerador mudou: regerar saves e hashes de referência (arquitetura 21.5).
	var rng: WorldRng = WorldRng.new(12345)
	var values: Array[int] = []
	for _i: int in 3:
		values.append(rng.range_int("golden", 0, 999999))
	assert_eq(values, [639886, 319399, 389407])
