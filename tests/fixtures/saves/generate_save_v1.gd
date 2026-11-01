extends SceneTree
## Gera a fixture `save_v1.lwsave` (formato da versão 1: o payload é o estado do World direto,
## sem o agendador) e o hash esperado. Só roda quando um humano pede, nunca no check_all:
##   godot --headless --path . -s res://tests/fixtures/saves/generate_save_v1.gd
## A fixture é versionada para os testes de migração (arquitetura 18.6); não a regenere sem motivo.

const OUTPUT_DIR: String = "res://tests/fixtures/saves"
const FIXTURE_SEED: int = 11
const FIXTURE_DAYS: int = 3


func _initialize() -> void:
	var runner: SimulationRunner = SimulationRunner.new(FIXTURE_SEED)
	runner.register_module("walker", WalkerModule.new())
	runner.start_new_game(func(scheduler: Scheduler) -> void: scheduler.configure_module("walker", 7, 3))
	runner.run_days(FIXTURE_DAYS)
	var world_state: Dictionary = runner.world.serialize()
	var bytes: PackedByteArray = JsonSaveCodec.new().encode_with_version(world_state, "0.0.1-dev", 1)
	var save_file: FileAccess = FileAccess.open(OUTPUT_DIR + "/save_v1.lwsave", FileAccess.WRITE)
	save_file.store_buffer(bytes)
	save_file.close()
	var hash_file: FileAccess = FileAccess.open(OUTPUT_DIR + "/save_v1.expected_hash", FileAccess.WRITE)
	hash_file.store_string(runner.world.state_hash())
	hash_file.close()
	print("Fixture gerada: %d bytes, hash %s" % [bytes.size(), runner.world.state_hash()])
	runner.finish()
	quit(0)
