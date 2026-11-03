extends GutTest
## Cadeia COMPLETA de salvamento, só com o que o jogo usa (LW-029A; achado I3 da LW-029; arquitetura 18.4 e 18.5):
## SimulationRunner.capture_game -> SaveStore.save (disco, pasta temporária) -> SaveStore.load_slot ->
## SimulationRunner.load_game -> hash. Antes essa cadeia só existia no código descartável
## tests/soak/sp5/run_sp5.gd, fora do check_all.

const GAME_VERSION: String = "0.0.1-test"
const SLOT: int = 0
const WORLD_SEED: int = 5
const WALKER_EVERY: int = 7
const WALKER_COST: int = 3
const DAYS_BEFORE_SAVE: int = 2
const EXTRA_STEPS_BEFORE_SAVE: int = 13
const STEPS_BETWEEN_SAVES: int = 40
const STEPS_AFTER_LOAD: int = 500

var _dir: DirAccess
var _store: SaveStore


func before_each() -> void:
	_dir = DirAccess.create_temp("lw029a")
	_store = SaveStore.new(_dir.get_current_dir(), JsonSaveCodec.new())


func after_each() -> void:
	for file_name: String in _dir.get_files():
		_dir.remove(file_name)
	DirAccess.remove_absolute(_dir.get_current_dir())


func _configure(scheduler: Scheduler) -> void:
	scheduler.configure_module("walker", WALKER_EVERY, WALKER_COST)


func _new_runner() -> SimulationRunner:
	var runner: SimulationRunner = SimulationRunner.new(WORLD_SEED)
	assert_true(runner.register_module("walker", WalkerModule.new()).ok)
	return runner


func _started_runner() -> SimulationRunner:
	var runner: SimulationRunner = _new_runner()
	runner.start_new_game(_configure)
	return runner


func _loaded_runner(decoded: DecodedSave) -> SimulationRunner:
	var runner: SimulationRunner = _new_runner()
	var result: Result = runner.load_game(decoded.payload, _configure)
	assert_true(result.ok, result.message)
	return runner


func _corrupt(path: String) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string("lixo que não é um save")
	file.close()


func test_runner_to_disk_to_runner_keeps_the_hash_and_the_future() -> void:
	var original: SimulationRunner = _started_runner()
	original.run_days(DAYS_BEFORE_SAVE)
	original.run_steps(EXTRA_STEPS_BEFORE_SAVE)
	assert_true(original.can_capture_game(), "Entre passos a fila de eventos está vazia.")
	var hash_before: String = original.world.state_hash()
	var scheduler_before: Dictionary = original.scheduler.serialize()
	var saved: Result = _store.save(SLOT, original.capture_game(), GAME_VERSION)
	assert_true(saved.ok, saved.message)
	var decoded: DecodedSave = _store.load_slot(SLOT)
	assert_true(decoded.result.ok, decoded.result.message)
	assert_eq(decoded.source, "final")
	assert_eq(decoded.warnings.size(), 0)
	var restored: SimulationRunner = _loaded_runner(decoded)
	assert_eq(restored.world.state_hash(), hash_before, "Carregado do disco, o mundo tem de ter o hash do momento em que foi salvo.")
	assert_eq(restored.scheduler.serialize(), scheduler_before, "O controle de frequência do agendador também volta igual.")
	original.run_steps(STEPS_AFTER_LOAD)
	restored.run_steps(STEPS_AFTER_LOAD)
	assert_eq(restored.world.state_hash(), original.world.state_hash(), "O mundo carregado e o que seguiu direto têm de continuar iguais.")
	assert_eq(restored.scheduler.serialize(), original.scheduler.serialize())
	original.finish()
	restored.finish()


## Caso de erro 1: o arquivo final é corrompido no disco; o jogo recorre ao save anterior e avisa.
func test_corrupted_final_file_recovers_the_previous_save_and_the_world_matches_it() -> void:
	var runner: SimulationRunner = _started_runner()
	runner.run_steps(STEPS_BETWEEN_SAVES)
	var hash_first_save: String = runner.world.state_hash()
	assert_true(_store.save(SLOT, runner.capture_game(), GAME_VERSION).ok)
	runner.run_steps(STEPS_BETWEEN_SAVES)
	var hash_second_save: String = runner.world.state_hash()
	assert_true(_store.save(SLOT, runner.capture_game(), GAME_VERSION).ok)
	assert_ne(hash_first_save, hash_second_save, "Os dois saves precisam ser diferentes para o teste provar a recuperação.")
	_corrupt(_store.final_path(SLOT))
	var decoded: DecodedSave = _store.load_slot(SLOT)
	assert_true(decoded.result.ok, decoded.result.message)
	assert_eq(decoded.source, "bak1", "Com o arquivo final corrompido o jogo recorre ao backup mais recente.")
	assert_eq(decoded.warnings.size(), 1, "O jogador precisa ser avisado do arquivo descartado.")
	var restored: SimulationRunner = _loaded_runner(decoded)
	assert_eq(restored.world.state_hash(), hash_first_save, "O mundo recuperado é o do save anterior, não o do arquivo corrompido.")
	runner.finish()
	restored.finish()


## Caso de erro 2: arquivo válido com estado inválido dentro. O carregamento é recusado e o mundo em curso segue intacto.
func test_invalid_state_inside_a_valid_file_is_rejected_and_the_running_world_survives() -> void:
	var running: SimulationRunner = _started_runner()
	running.run_steps(25)
	var hash_before: String = running.world.state_hash()
	var empty_state: Dictionary = {"world": {"core": {}, "modules": {}}, "scheduler": {"modules": {}}}
	assert_true(_store.save(SLOT, empty_state, GAME_VERSION).ok)
	var decoded: DecodedSave = _store.load_slot(SLOT)
	assert_true(decoded.result.ok, "O arquivo em si é válido; o que está dentro dele não é.")
	var candidate: SimulationRunner = _new_runner()
	var result: Result = candidate.load_game(decoded.payload, _configure)
	assert_false(result.ok)
	assert_eq(result.code, "WORLD_MODULE_DATA_MISSING")
	candidate.finish()
	assert_eq(running.world.state_hash(), hash_before, "Carga recusada não pode mexer no mundo em curso.")
	running.run_steps(5)
	assert_eq(running.world.validate().size(), 0)
	running.finish()


## Caso-limite: mundo recém-criado (minuto 0), no slot 0, salvo antes do primeiro passo.
func test_saving_a_brand_new_world_before_any_step_round_trips() -> void:
	var original: SimulationRunner = _started_runner()
	var hash_before: String = original.world.state_hash()
	assert_true(_store.save(SLOT, original.capture_game(), GAME_VERSION).ok)
	var decoded: DecodedSave = _store.load_slot(SLOT)
	assert_true(decoded.result.ok, decoded.result.message)
	var restored: SimulationRunner = _loaded_runner(decoded)
	assert_eq(restored.world.state_hash(), hash_before)
	original.run_days(1)
	restored.run_days(1)
	assert_eq(restored.world.state_hash(), original.world.state_hash(), "Salvo no minuto 0, o mundo carregado segue igual ao que não foi salvo.")
	original.finish()
	restored.finish()
