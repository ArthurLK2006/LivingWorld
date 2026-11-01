extends GutTest

const GAME_VERSION: String = "0.0.1-test"
const STEPS: Array[String] = [SaveStore.STEP_TMP_WRITTEN, SaveStore.STEP_TMP_VERIFIED, SaveStore.STEP_BACKUPS_ROTATED, SaveStore.STEP_FINAL_REPLACED]

var _dir: DirAccess
var _store: SaveStore


func before_each() -> void:
	_dir = DirAccess.create_temp("lw027")
	_store = SaveStore.new(_dir.get_current_dir(), JsonSaveCodec.new())


func after_each() -> void:
	for file_name: String in _dir.get_files():
		_dir.remove(file_name)
	DirAccess.remove_absolute(_dir.get_current_dir())


func _payload(marker: int) -> Dictionary:
	return {"world": {"marker": marker}, "scheduler": {}}


func _marker_of(decoded: DecodedSave) -> int:
	return int(decoded.payload["world"]["marker"])


func _inject_at(step: String) -> void:
	_store.fault_injector = func(done_step: String) -> bool: return done_step == step


func _corrupt(path: String) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string("lixo que não é um save")
	file.close()


func test_save_then_load_returns_the_same_payload() -> void:
	assert_true(_store.save(1, _payload(10), GAME_VERSION).ok)
	var decoded: DecodedSave = _store.load_slot(1)
	assert_true(decoded.result.ok, decoded.result.message)
	assert_eq(_marker_of(decoded), 10)
	assert_eq(decoded.source, "final")
	assert_eq(decoded.warnings.size(), 0)
	assert_false(FileAccess.file_exists(_store.final_path(1) + SaveStore.TMP_SUFFIX), "Depois de salvar não sobra .tmp.")


func test_failure_injected_after_each_step_never_loses_the_previous_save() -> void:
	after_each()
	for step: String in STEPS:
		_dir = DirAccess.create_temp("lw027")
		_store = SaveStore.new(_dir.get_current_dir(), JsonSaveCodec.new())
		assert_true(_store.save(0, _payload(1), GAME_VERSION).ok)
		_inject_at(step)
		var result: Result = _store.save(0, _payload(2), GAME_VERSION)
		var expected_new: bool = step == SaveStore.STEP_FINAL_REPLACED
		assert_eq(result.code, "SAVE_INJECTED_FAILURE", step)
		var decoded: DecodedSave = _store.load_slot(0)
		assert_true(decoded.result.ok, "Depois de falha em '%s' o slot precisa carregar: %s" % [step, decoded.result.message])
		var marker: int = _marker_of(decoded)
		var is_old_or_new: bool = marker == 1 or marker == 2
		assert_true(is_old_or_new, "Falha em '%s': só o save antigo ou o novo, nunca estado inventado." % step)
		if step == SaveStore.STEP_TMP_WRITTEN or step == SaveStore.STEP_TMP_VERIFIED:
			assert_eq(marker, 1, "Antes de mexer no final, o save antigo segue intacto (%s)." % step)
			assert_eq(decoded.source, "final")
		if step == SaveStore.STEP_BACKUPS_ROTATED:
			assert_eq(decoded.source, "tmp", "Sem final, usa o .tmp verificado, que é o save mais novo.")
			assert_eq(marker, 2)
		if expected_new:
			assert_eq(marker, 2)
		after_each()
	_dir = DirAccess.create_temp("lw027")


func test_next_save_after_an_interrupted_one_promotes_the_pending_file_and_keeps_history() -> void:
	assert_true(_store.save(0, _payload(1), GAME_VERSION).ok)
	_inject_at(SaveStore.STEP_BACKUPS_ROTATED)
	assert_false(_store.save(0, _payload(2), GAME_VERSION).ok)
	_store.fault_injector = Callable()
	assert_true(_store.save(0, _payload(3), GAME_VERSION).ok)
	assert_eq(_marker_of(_store.load_slot(0)), 3)
	var backup: DecodedSave = JsonSaveCodec.new().decode(FileAccess.get_file_as_bytes(_store.backup_path(0, 1)))
	assert_eq(_marker_of(backup), 2, "O save interrompido (2) foi promovido e virou o backup mais recente.")


func test_backups_rotate_and_respect_the_limit() -> void:
	for marker: int in range(1, 6):
		assert_true(_store.save(2, _payload(marker), GAME_VERSION).ok)
	var codec: JsonSaveCodec = JsonSaveCodec.new()
	assert_eq(_marker_of(codec.decode(FileAccess.get_file_as_bytes(_store.final_path(2)))), 5)
	for index: int in range(1, SaveStore.DEFAULT_BACKUP_COUNT + 1):
		assert_eq(_marker_of(codec.decode(FileAccess.get_file_as_bytes(_store.backup_path(2, index)))), 5 - index)
	assert_false(FileAccess.file_exists(_store.backup_path(2, SaveStore.DEFAULT_BACKUP_COUNT + 1)), "Nunca mais que o limite de backups.")


func test_corrupt_main_file_falls_back_to_the_latest_backup_with_a_warning() -> void:
	assert_true(_store.save(0, _payload(1), GAME_VERSION).ok)
	assert_true(_store.save(0, _payload(2), GAME_VERSION).ok)
	_corrupt(_store.final_path(0))
	var decoded: DecodedSave = _store.load_slot(0)
	assert_true(decoded.result.ok, decoded.result.message)
	assert_eq(_marker_of(decoded), 1)
	assert_eq(decoded.source, "bak1")
	assert_eq(decoded.warnings.size(), 1)
	assert_string_contains(decoded.warnings[0], "final descartado")


func test_checksum_failure_of_the_main_file_also_falls_back() -> void:
	assert_true(_store.save(0, _payload(1), GAME_VERSION).ok)
	assert_true(_store.save(0, _payload(2), GAME_VERSION).ok)
	var text: String = FileAccess.get_file_as_bytes(_store.final_path(0)).decompress_dynamic(JsonSaveCodec.MAX_UNCOMPRESSED_BYTES, FileAccess.COMPRESSION_GZIP).get_string_from_utf8()
	var file: FileAccess = FileAccess.open(_store.final_path(0), FileAccess.WRITE)
	file.store_buffer(text.replace("\"marker\":2", "\"marker\":9").to_utf8_buffer().compress(FileAccess.COMPRESSION_GZIP))
	file.close()
	var decoded: DecodedSave = _store.load_slot(0)
	assert_eq(_marker_of(decoded), 1)
	assert_string_contains(decoded.warnings[0], "checksum")


func test_all_files_invalid_and_empty_slot_report_clear_errors() -> void:
	assert_eq(_store.load_slot(0).result.code, "SAVE_SLOT_EMPTY")
	assert_true(_store.save(0, _payload(1), GAME_VERSION).ok)
	_corrupt(_store.final_path(0))
	var decoded: DecodedSave = _store.load_slot(0)
	assert_eq(decoded.result.code, "SAVE_NO_VALID_FILE")
	assert_string_contains(decoded.result.message, "final descartado")


func test_list_slots_and_delete() -> void:
	assert_eq(_store.list_slots(), [] as Array[int])
	assert_true(_store.save(3, _payload(1), GAME_VERSION).ok)
	assert_true(_store.save(1, _payload(1), GAME_VERSION).ok)
	assert_true(_store.save(1, _payload(2), GAME_VERSION).ok)
	assert_eq(_store.list_slots(), [1, 3] as Array[int])
	assert_true(_store.delete(1).ok)
	assert_eq(_store.list_slots(), [3] as Array[int])
	assert_eq(_store.load_slot(1).result.code, "SAVE_SLOT_EMPTY")
	assert_true(_store.delete(1).ok, "Apagar slot vazio não é erro.")


func test_invalid_slot_and_unwritable_directory_are_reported() -> void:
	assert_eq(_store.save(-1, _payload(1), GAME_VERSION).code, "SAVE_INVALID_SLOT")
	assert_eq(_store.load_slot(-1).result.code, "SAVE_INVALID_SLOT")
	assert_eq(_store.delete(-1).code, "SAVE_INVALID_SLOT")
	var missing: SaveStore = SaveStore.new(_dir.get_current_dir().path_join("nao_existe"), JsonSaveCodec.new())
	var result: Result = missing.save(0, _payload(1), GAME_VERSION)
	assert_eq(result.code, "SAVE_WRITE_FAILED")
	assert_string_contains(result.message, "nao_existe")
	assert_eq(missing.list_slots(), [] as Array[int])


func test_store_without_backups_keeps_only_the_final_file() -> void:
	var lean: SaveStore = SaveStore.new(_dir.get_current_dir(), JsonSaveCodec.new(), 0)
	assert_true(lean.save(0, _payload(1), GAME_VERSION).ok)
	assert_true(lean.save(0, _payload(2), GAME_VERSION).ok)
	assert_eq(_marker_of(lean.load_slot(0)), 2)
	assert_false(FileAccess.file_exists(lean.backup_path(0, 1)))
