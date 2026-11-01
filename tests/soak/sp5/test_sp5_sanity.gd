extends GutTest
## Teste rápido do código do spike SP5 (100 NPCs, 1 dia) para ele não apodrecer; a medição de
## verdade roda com tests/soak/run_sp5 e não faz parte do check_all.


func _runner() -> SimulationRunner:
	var runner: SimulationRunner = SimulationRunner.new(1)
	runner.register_module("npcs", FakeNpcPopulation.new(100))
	return runner


func test_spike_world_survives_save_and_load_with_identical_hash() -> void:
	var original: SimulationRunner = _runner()
	original.start_new_game()
	original.run_days(1)
	var codec: JsonSaveCodec = JsonSaveCodec.new()
	var decoded: DecodedSave = codec.decode(codec.encode(original.capture_game(), "test"))
	assert_true(decoded.result.ok, decoded.result.message)
	var restored: SimulationRunner = _runner()
	var result: Result = restored.load_game(decoded.payload)
	assert_true(result.ok, result.message)
	assert_eq(restored.world.state_hash(), original.world.state_hash())
	original.run_steps(60)
	restored.run_steps(60)
	assert_eq(restored.world.state_hash(), original.world.state_hash(), "Depois de carregar, o mundo segue igual ao que não foi salvo.")
	original.finish()
	restored.finish()


func test_spike_population_rejects_a_save_with_wrong_size() -> void:
	var population: FakeNpcPopulation = FakeNpcPopulation.new(100)
	var result: Result = population.on_load({"npc_ids": [1], "hunger": [], "energy": [], "social": [], "action": [], "last_update": [], "ring": []})
	assert_false(result.ok)
	assert_eq(result.code, "FAKE_NPC_INVALID_SAVE")
