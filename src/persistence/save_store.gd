class_name SaveStore
extends RefCounted
## Grava e lê saves em disco com segurança (arquitetura 18.4 e 18.5), por slot:
##   save_slot_N.lwsave        arquivo final
##   save_slot_N.lwsave.tmp    gravação em andamento / pronta para promover
##   save_slot_N.lwsave.bakK   backups rotativos (bak1 = o save anterior mais recente)
## Sequência de salvar: (1) grava .tmp, (2) relê e confere pelo codec, (3) gira os backups e move
## o final para bak1, (4) renomeia .tmp para final. "Renomear sobre o final" não é atômico no
## Windows, por isso o final nunca é sobrescrito: ele é movido antes. Ao carregar, tenta-se
## final, .tmp, bak1... e usa-se o primeiro válido. O Godot não oferece fsync: uma queda de
## energia exatamente durante a gravação física pode perder o save mais novo (limitação).

const STEP_TMP_WRITTEN: String = "tmp_written"
const STEP_TMP_VERIFIED: String = "tmp_verified"
const STEP_BACKUPS_ROTATED: String = "backups_rotated"
const STEP_FINAL_REPLACED: String = "final_replaced"
## [HIP] Quantos backups manter (arquitetura 18.4: "ex.: os 3 últimos").
const DEFAULT_BACKUP_COUNT: int = 3
const FILE_PREFIX: String = "save_slot_"
const FILE_EXTENSION: String = ".lwsave"
const TMP_SUFFIX: String = ".tmp"
const BACKUP_SUFFIX: String = ".bak"

## Gancho de TESTE: recebe o nome do passo concluído e devolve verdadeiro para simular uma falha
## logo depois dele (o salvar para ali, deixando os arquivos como estão). Nunca é definido no jogo.
var fault_injector: Callable = Callable()

var _directory: String
var _codec: SaveCodec
var _backup_count: int


func _init(directory: String, codec: SaveCodec, backup_count: int = DEFAULT_BACKUP_COUNT) -> void:
	_directory = directory
	_codec = codec
	_backup_count = maxi(backup_count, 0)


func save(slot: int, payload: Dictionary, game_version: String) -> Result:
	if slot < 0:
		return Result.failure("SAVE_INVALID_SLOT", "SaveStore.save: slot %d inválido (use 0 ou maior)." % slot)
	_recover_unfinished_save(slot)
	var final_file: String = _final_path(slot)
	var tmp_path: String = final_file + TMP_SUFFIX
	var bytes: PackedByteArray = _codec.encode(payload, game_version)
	var write_result: Result = _write_file(tmp_path, bytes)
	if not write_result.ok:
		return write_result
	if _injected(STEP_TMP_WRITTEN):
		return _injected_failure(STEP_TMP_WRITTEN)
	var check: DecodedSave = _codec.decode(FileAccess.get_file_as_bytes(tmp_path))
	if not check.result.ok:
		DirAccess.remove_absolute(tmp_path)
		return Result.failure("SAVE_VERIFY_FAILED", "SaveStore.save: o arquivo gravado não passou na conferência (%s). O save anterior foi mantido." % check.result.message)
	if _injected(STEP_TMP_VERIFIED):
		return _injected_failure(STEP_TMP_VERIFIED)
	var rotate_result: Result = _rotate_backups(final_file)
	if not rotate_result.ok:
		return rotate_result
	if _injected(STEP_BACKUPS_ROTATED):
		return _injected_failure(STEP_BACKUPS_ROTATED)
	var rename_error: Error = DirAccess.rename_absolute(tmp_path, final_file)
	if rename_error != OK:
		return Result.failure("SAVE_RENAME_FAILED", "SaveStore.save: não foi possível promover '%s' a '%s' (erro %d). O save anterior está em backup." % [tmp_path, final_file, rename_error])
	if _injected(STEP_FINAL_REPLACED):
		return _injected_failure(STEP_FINAL_REPLACED)
	return Result.success()


## Lê o slot: primeiro válido entre final, .tmp e backups. `warnings` conta o que foi descartado.
func load_slot(slot: int) -> DecodedSave:
	if slot < 0:
		return DecodedSave.failed("SAVE_INVALID_SLOT", "SaveStore.load_slot: slot %d inválido." % slot)
	var warnings: Array[String] = []
	var found_any: bool = false
	for candidate: Array in _candidates(slot):
		var path: String = candidate[1]
		if not FileAccess.file_exists(path):
			continue
		found_any = true
		var decoded: DecodedSave = _codec.decode(FileAccess.get_file_as_bytes(path))
		if decoded.result.ok:
			decoded.source = candidate[0]
			decoded.warnings = warnings
			return decoded
		warnings.append("%s descartado: %s" % [candidate[0], decoded.result.message])
	if not found_any:
		return DecodedSave.failed("SAVE_SLOT_EMPTY", "Não existe save no slot %d." % slot)
	return DecodedSave.failed("SAVE_NO_VALID_FILE", "Nenhum arquivo do slot %d é válido: %s" % [slot, "; ".join(warnings)])


## Slots que têm algum arquivo de save, em ordem crescente.
func list_slots() -> Array[int]:
	var slots: Array[int] = []
	var directory: DirAccess = DirAccess.open(_directory)
	if directory == null:
		return slots
	for file_name: String in directory.get_files():
		if not file_name.begins_with(FILE_PREFIX):
			continue
		var rest: String = file_name.trim_prefix(FILE_PREFIX)
		var number_text: String = rest.get_slice(FILE_EXTENSION, 0)
		if number_text.is_valid_int() and rest.contains(FILE_EXTENSION) and not slots.has(number_text.to_int()):
			slots.append(number_text.to_int())
	slots.sort()
	return slots


## Remove o final, o .tmp e todos os backups do slot.
func delete(slot: int) -> Result:
	if slot < 0:
		return Result.failure("SAVE_INVALID_SLOT", "SaveStore.delete: slot %d inválido." % slot)
	for candidate: Array in _candidates(slot):
		var path: String = candidate[1]
		if FileAccess.file_exists(path):
			var error: Error = DirAccess.remove_absolute(path)
			if error != OK:
				return Result.failure("SAVE_DELETE_FAILED", "SaveStore.delete: não foi possível remover '%s' (erro %d)." % [path, error])
	return Result.success()


func backup_path(slot: int, index: int) -> String:
	return _final_path(slot) + BACKUP_SUFFIX + str(index)


func final_path(slot: int) -> String:
	return _final_path(slot)


func _final_path(slot: int) -> String:
	return _directory.path_join("%s%d%s" % [FILE_PREFIX, slot, FILE_EXTENSION])


## Pares [nome, caminho] na ordem de preferência ao carregar.
func _candidates(slot: int) -> Array[Array]:
	var list: Array[Array] = [["final", _final_path(slot)], ["tmp", _final_path(slot) + TMP_SUFFIX]]
	for index: int in range(1, _backup_count + 1):
		list.append(["bak%d" % index, backup_path(slot, index)])
	return list


## Se uma gravação anterior parou depois de mover o final e antes de promover o .tmp, o slot está
## sem final mas com .tmp válido: promove-o agora, para o próximo salvamento não o sobrescrever.
func _recover_unfinished_save(slot: int) -> void:
	var final_file: String = _final_path(slot)
	var tmp_file: String = final_file + TMP_SUFFIX
	if FileAccess.file_exists(final_file) or not FileAccess.file_exists(tmp_file):
		return
	if _codec.decode(FileAccess.get_file_as_bytes(tmp_file)).result.ok:
		DirAccess.rename_absolute(tmp_file, final_file)


func _rotate_backups(final_file: String) -> Result:
	if _backup_count == 0:
		return _remove(final_file)
	var oldest: String = final_file + BACKUP_SUFFIX + str(_backup_count)
	var remove_result: Result = _remove(oldest)
	if not remove_result.ok:
		return remove_result
	for index: int in range(_backup_count - 1, 0, -1):
		var from_path: String = final_file + BACKUP_SUFFIX + str(index)
		if FileAccess.file_exists(from_path):
			var error: Error = DirAccess.rename_absolute(from_path, final_file + BACKUP_SUFFIX + str(index + 1))
			if error != OK:
				return Result.failure("SAVE_ROTATE_FAILED", "SaveStore.save: não foi possível girar o backup '%s' (erro %d)." % [from_path, error])
	if FileAccess.file_exists(final_file):
		var move_error: Error = DirAccess.rename_absolute(final_file, final_file + BACKUP_SUFFIX + "1")
		if move_error != OK:
			return Result.failure("SAVE_ROTATE_FAILED", "SaveStore.save: não foi possível mover '%s' para backup (erro %d)." % [final_file, move_error])
	return Result.success()


func _remove(path: String) -> Result:
	if not FileAccess.file_exists(path):
		return Result.success()
	var error: Error = DirAccess.remove_absolute(path)
	if error != OK:
		return Result.failure("SAVE_ROTATE_FAILED", "SaveStore.save: não foi possível remover '%s' (erro %d)." % [path, error])
	return Result.success()


func _write_file(path: String, bytes: PackedByteArray) -> Result:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return Result.failure("SAVE_WRITE_FAILED", "SaveStore.save: não foi possível abrir '%s' para escrita (erro %d)." % [path, FileAccess.get_open_error()])
	var stored: bool = file.store_buffer(bytes)
	file.close()
	if not stored:
		return Result.failure("SAVE_WRITE_FAILED", "SaveStore.save: gravação incompleta em '%s'." % path)
	return Result.success()


func _injected(step: String) -> bool:
	return fault_injector.is_valid() and fault_injector.call(step)


func _injected_failure(step: String) -> Result:
	return Result.failure("SAVE_INJECTED_FAILURE", "Falha simulada depois do passo '%s'." % step)
