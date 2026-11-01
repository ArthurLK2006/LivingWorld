extends SceneTree
## SPIKE SP5 (LW-028) — mede salvar e carregar o mundo do SP1 (NPCs de mentira), sem janela.
## Uso: tests/soak/run_sp5 [--days N] [--npcs N] [--rounds N]. Descartável.
## Os tempos usam o relógio do sistema APENAS para medir; nada disso entra no estado.

const DEFAULT_DAYS: int = 30
const DEFAULT_NPCS: int = 1000
const DEFAULT_ROUNDS: int = 5
const WORLD_SEED: int = 1
const SAVE_BUDGET_MS: float = 100.0
const LOAD_BUDGET_MS: float = 3000.0
const SLOT: int = 0
const GAME_VERSION: String = "0.0.1-sp5"


func _initialize() -> void:
	var days: int = DEFAULT_DAYS
	var npcs: int = DEFAULT_NPCS
	var rounds: int = DEFAULT_ROUNDS
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var index: int = 0
	while index + 1 < args.size():
		var value: int = args[index + 1].to_int()
		match args[index]:
			"--days":
				days = value
			"--npcs":
				npcs = value
			"--rounds":
				rounds = value
		index += 2
	var directory: DirAccess = DirAccess.create_temp("sp5")
	var store: SaveStore = SaveStore.new(directory.get_current_dir(), JsonSaveCodec.new())
	var codec: JsonSaveCodec = JsonSaveCodec.new()
	var runner: SimulationRunner = _new_runner(npcs)
	runner.start_new_game()
	runner.run_days(days)
	print("SP5 — dias: %d, NPCs: %d, rodadas: %d, motor %s" % [days, npcs, rounds, Engine.get_version_info()["string"]])
	var capture_ms: Array[float] = []
	var encode_ms: Array[float] = []
	var save_ms: Array[float] = []
	var read_decode_ms: Array[float] = []
	var restore_ms: Array[float] = []
	var payload: Dictionary = {}
	var bytes_size: int = 0
	var json_size: int = 0
	for _round: int in rounds:
		var t0: int = Time.get_ticks_usec()
		payload = runner.capture_game()
		var t1: int = Time.get_ticks_usec()
		var bytes: PackedByteArray = codec.encode(payload, GAME_VERSION)
		var t2: int = Time.get_ticks_usec()
		var save_result: Result = store.save(SLOT, payload, GAME_VERSION)
		var t3: int = Time.get_ticks_usec()
		var decoded: DecodedSave = store.load_slot(SLOT)
		var t4: int = Time.get_ticks_usec()
		var restored: SimulationRunner = _new_runner(npcs)
		var load_result: Result = restored.load_game(decoded.payload)
		var t5: int = Time.get_ticks_usec()
		if not save_result.ok or not decoded.result.ok or not load_result.ok:
			print("FALHA: %s | %s | %s" % [save_result.message, decoded.result.message, load_result.message])
			quit(1)
			return
		capture_ms.append((t1 - t0) / 1000.0)
		encode_ms.append((t2 - t1) / 1000.0)
		save_ms.append((t3 - t2) / 1000.0)
		read_decode_ms.append((t4 - t3) / 1000.0)
		restore_ms.append((t5 - t4) / 1000.0)
		bytes_size = bytes.size()
		json_size = JSON.stringify(payload, "", true, true).length()
		if _round == rounds - 1:
			_check_equivalence(runner, restored)
		restored.finish()
	print("Tamanho do estado em JSON: %d bytes | arquivo comprimido: %d bytes (%.1f%%)" % [json_size, bytes_size, 100.0 * bytes_size / json_size])
	_line("capturar estado (serialize)", capture_ms)
	_line("codificar (JSON+checksum+gzip)", encode_ms)
	_line("SaveStore.save completo (codifica+grava+confere+gira backups)", save_ms, SAVE_BUDGET_MS)
	_line("ler arquivo + decodificar", read_decode_ms)
	_line("restaurar mundo (load_game)", restore_ms)
	var total_load: Array[float] = []
	for round_index: int in rounds:
		total_load.append(read_decode_ms[round_index] + restore_ms[round_index])
	_line("CARREGAR total (ler+decodificar+restaurar)", total_load, LOAD_BUDGET_MS)
	_failure_simulation(store, runner, payload)
	runner.finish()
	for file_name: String in directory.get_files():
		directory.remove(file_name)
	DirAccess.remove_absolute(directory.get_current_dir())
	quit(0)


func _new_runner(npcs: int) -> SimulationRunner:
	var runner: SimulationRunner = SimulationRunner.new(WORLD_SEED)
	runner.register_module("npcs", FakeNpcPopulation.new(npcs))
	return runner


func _line(label: String, samples: Array[float], budget_ms: float = -1.0) -> void:
	var total: float = 0.0
	var lowest: float = samples[0]
	var highest: float = samples[0]
	for value: float in samples:
		total += value
		lowest = minf(lowest, value)
		highest = maxf(highest, value)
	var verdict: String = ""
	if budget_ms > 0.0:
		verdict = " | orçamento %.0f ms: %s" % [budget_ms, "DENTRO" if highest <= budget_ms else "FORA"]
	print("%s: média %.1f ms, mín %.1f, máx %.1f%s" % [label, total / samples.size(), lowest, highest, verdict])


func _check_equivalence(original: SimulationRunner, restored: SimulationRunner) -> void:
	var same_now: bool = original.world.state_hash() == restored.world.state_hash()
	print("Hash idêntico logo após carregar: %s" % ("SIM" if same_now else "NÃO"))
	original.run_days(1)
	restored.run_days(1)
	var same_later: bool = original.world.state_hash() == restored.world.state_hash()
	print("Hash idêntico depois de mais 1 dia simulado nos dois: %s" % ("SIM" if same_later else "NÃO"))
	print("state_hash (original): %s" % original.world.state_hash())


func _failure_simulation(store: SaveStore, runner: SimulationRunner, payload: Dictionary) -> void:
	var before: DecodedSave = store.load_slot(SLOT)
	var steps: Array[String] = [SaveStore.STEP_TMP_WRITTEN, SaveStore.STEP_TMP_VERIFIED, SaveStore.STEP_BACKUPS_ROTATED, SaveStore.STEP_FINAL_REPLACED]
	var preserved: int = 0
	for step: String in steps:
		store.fault_injector = func(done_step: String) -> bool: return done_step == step
		store.save(SLOT, runner.capture_game(), GAME_VERSION)
		var after: DecodedSave = store.load_slot(SLOT)
		if after.result.ok and not after.payload.is_empty():
			preserved += 1
	store.fault_injector = Callable()
	print("Falha simulada depois de cada um dos %d passos: save carregável em %d de %d casos (before ok: %s)" % [steps.size(), preserved, steps.size(), str(before.result.ok)])
