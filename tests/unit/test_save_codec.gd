extends GutTest

const GAME_VERSION: String = "0.0.1-test"
const FIXTURE_DIR: String = "res://tests/fixtures/saves"
const WALKER_EVERY: int = 7
const WALKER_COST: int = 3

var _codec: JsonSaveCodec


func before_each() -> void:
	_codec = JsonSaveCodec.new()


func _configure(scheduler: Scheduler) -> void:
	scheduler.configure_module("walker", WALKER_EVERY, WALKER_COST)


func _new_runner(world_seed: int) -> SimulationRunner:
	var runner: SimulationRunner = SimulationRunner.new(world_seed)
	assert_true(runner.register_module("walker", WalkerModule.new()).ok)
	return runner


func _started_runner(world_seed: int) -> SimulationRunner:
	var runner: SimulationRunner = _new_runner(world_seed)
	runner.start_new_game(_configure)
	return runner


func _loaded_runner(decoded: DecodedSave) -> SimulationRunner:
	var runner: SimulationRunner = _new_runner(0)
	var result: Result = runner.load_game(decoded.payload, _configure)
	assert_true(result.ok, result.message)
	return runner


func _read_fixture(file_name: String) -> PackedByteArray:
	return FileAccess.get_file_as_bytes(FIXTURE_DIR + "/" + file_name)


func test_round_trip_preserves_state_hash_and_scheduler() -> void:
	var original: SimulationRunner = _started_runner(5)
	original.run_days(2)
	var decoded: DecodedSave = _codec.decode(_codec.encode(original.capture_game(), GAME_VERSION))
	assert_true(decoded.result.ok, decoded.result.message)
	assert_eq(decoded.save_version, JsonSaveCodec.CURRENT_SAVE_VERSION)
	assert_eq(decoded.game_version, GAME_VERSION)
	var restored: SimulationRunner = _loaded_runner(decoded)
	assert_eq(restored.world.state_hash(), original.world.state_hash())
	assert_eq(restored.scheduler.serialize(), original.scheduler.serialize())
	original.finish()
	restored.finish()


func test_saving_and_loading_in_the_middle_does_not_change_the_final_hash() -> void:
	var straight: SimulationRunner = _started_runner(9)
	straight.run_days(4)
	var interrupted: SimulationRunner = _started_runner(9)
	interrupted.run_days(2)
	interrupted.run_steps(13)
	var decoded: DecodedSave = _codec.decode(_codec.encode(interrupted.capture_game(), GAME_VERSION))
	interrupted.finish()
	var resumed: SimulationRunner = _loaded_runner(decoded)
	resumed.run_steps(2 * SimClock.MINUTES_PER_DAY - 13)
	assert_eq(resumed.world.state_hash(), straight.world.state_hash(), "Salvar e carregar no meio não pode mudar o hash final.")
	assert_eq(resumed.scheduler.serialize(), straight.scheduler.serialize())
	straight.finish()
	resumed.finish()


func test_tampered_payload_is_rejected_by_checksum() -> void:
	var runner: SimulationRunner = _started_runner(5)
	runner.run_steps(30)
	var bytes: PackedByteArray = _codec.encode(runner.capture_game(), GAME_VERSION)
	runner.finish()
	var text: String = bytes.decompress_dynamic(JsonSaveCodec.MAX_UNCOMPRESSED_BYTES, FileAccess.COMPRESSION_GZIP).get_string_from_utf8()
	var tampered: String = text.replace("\"total_minutes\":30", "\"total_minutes\":31")
	assert_ne(tampered, text, "O teste precisa realmente alterar o conteúdo.")
	var decoded: DecodedSave = _codec.decode(tampered.to_utf8_buffer().compress(FileAccess.COMPRESSION_GZIP))
	assert_false(decoded.result.ok)
	assert_eq(decoded.result.code, "SAVE_CHECKSUM_MISMATCH")


func test_garbage_empty_text_and_resource_files_are_rejected() -> void:
	assert_eq(_codec.decode(PackedByteArray()).result.code, "SAVE_NOT_GZIP")
	assert_eq(_codec.decode("não sou um save".to_utf8_buffer()).result.code, "SAVE_NOT_GZIP")
	var resource_text: String = "[gd_resource type=\"Resource\" format=3]\n[ext_resource type=\"Script\" path=\"res://evil.gd\" id=\"1\"]\n[resource]\nscript = ExtResource(\"1\")\n"
	assert_eq(_codec.decode(resource_text.to_utf8_buffer()).result.code, "SAVE_NOT_GZIP", "Um .tres nunca é carregado como save.")
	var compressed_resource: DecodedSave = _codec.decode(resource_text.to_utf8_buffer().compress(FileAccess.COMPRESSION_GZIP))
	assert_false(compressed_resource.result.ok)
	assert_eq(compressed_resource.result.code, "SAVE_CORRUPT")


func test_truncated_file_is_rejected() -> void:
	var runner: SimulationRunner = _started_runner(5)
	var bytes: PackedByteArray = _codec.encode(runner.capture_game(), GAME_VERSION)
	runner.finish()
	var decoded: DecodedSave = _codec.decode(bytes.slice(0, bytes.size() / 2))
	assert_false(decoded.result.ok)
	assert_true(decoded.result.code in ["SAVE_CORRUPT", "SAVE_CHECKSUM_MISMATCH"], decoded.result.code)
	assert_engine_error_count(1)


func test_newer_unknown_and_invalid_versions_are_rejected() -> void:
	var payload: Dictionary = {"world": {}, "scheduler": {}}
	var newer: DecodedSave = _codec.decode(_codec.encode_with_version(payload, GAME_VERSION, JsonSaveCodec.CURRENT_SAVE_VERSION + 1))
	assert_eq(newer.result.code, "SAVE_VERSION_NEWER")
	assert_string_contains(newer.result.message, "Atualize o jogo")
	assert_eq(_codec.decode(_codec.encode_with_version(payload, GAME_VERSION, 0)).result.code, "SAVE_CORRUPT")
	assert_eq(_codec.decode(_codec.encode_with_version(payload, GAME_VERSION, -3)).result.code, "SAVE_CORRUPT")


func test_header_with_wrong_format_or_fields_is_rejected() -> void:
	var header: String = JSON.stringify({"format": "outro", "save_version": 2, "game_version": "x", "checksum": "0".repeat(64), "payload_bytes": 2})
	var wrong_format: DecodedSave = _codec.decode((header + "\n{}").to_utf8_buffer().compress(FileAccess.COMPRESSION_GZIP))
	assert_eq(wrong_format.result.code, "SAVE_WRONG_FORMAT")
	var bad_fields: String = JSON.stringify({"format": "lwsave", "save_version": "2", "game_version": "x", "checksum": "abc", "payload_bytes": 2})
	assert_eq(_codec.decode((bad_fields + "\n{}").to_utf8_buffer().compress(FileAccess.COMPRESSION_GZIP)).result.code, "SAVE_CORRUPT")


func test_previous_version_fixture_is_migrated_and_loads_with_the_expected_hash() -> void:
	var decoded: DecodedSave = _codec.decode(_read_fixture("save_v1.lwsave"))
	assert_true(decoded.result.ok, decoded.result.message)
	assert_eq(decoded.save_version, 1, "A fixture é de um save da versão 1.")
	assert_true(decoded.payload.has("world") and decoded.payload.has("scheduler"), "A migração 1->2 separa mundo e agendador.")
	var restored: SimulationRunner = _loaded_runner(decoded)
	var expected_hash: String = FileAccess.get_file_as_string(FIXTURE_DIR + "/save_v1.expected_hash")
	assert_eq(restored.world.state_hash(), expected_hash)
	restored.run_days(1)
	assert_eq(restored.world.validate().size(), 0, "O mundo migrado segue simulando sem problemas.")
	restored.finish()


func test_migration_errors_are_reported() -> void:
	var migrations: SaveMigrations = SaveMigrations.new()
	assert_eq(migrations.migrate({}, 0, 2).code, "SAVE_NO_MIGRATION")
	var broken: Result = migrations.migrate({"core": {}, "modules": {}}, 1, 2)
	assert_false(broken.ok)
	assert_eq(broken.code, "SAVE_INVALID_PAYLOAD")
	assert_string_contains(broken.message, "Migração 1->2")
	assert_true(migrations.migrate({}, 2, 2).ok, "Mesma versão não precisa de migração.")


func test_values_that_look_like_resources_stay_plain_text() -> void:
	var payload: Dictionary = {"world": {"note": "res://evil.tres", "script": "Object(Node)"}, "scheduler": {}}
	var decoded: DecodedSave = _codec.decode(_codec.encode(payload, GAME_VERSION))
	assert_true(decoded.result.ok)
	assert_eq(typeof(decoded.payload["world"]["note"]), TYPE_STRING)
	assert_eq(decoded.payload["world"]["script"], "Object(Node)")


func test_load_game_rejects_incomplete_payload_and_reused_runner() -> void:
	var runner: SimulationRunner = _new_runner(1)
	assert_eq(runner.load_game({}).code, "LOAD_INVALID_PAYLOAD")
	var started: SimulationRunner = _started_runner(1)
	assert_eq(started.load_game(started.capture_game()).code, "RUNNER_ALREADY_STARTED")
	started.finish()
	runner.finish()


func test_cannot_capture_while_events_are_pending() -> void:
	var runner: SimulationRunner = _started_runner(1)
	assert_true(runner.can_capture_game())
	runner.world.context.events.publish(TestEvent.new("TestPinged"))
	assert_false(runner.can_capture_game(), "Fila de eventos não vazia: não pode salvar (arquitetura 18.4).")
	runner.finish()
