extends GutTest
## Teste rápido do código do spike SP1 (100 NPCs, 2 dias) para ele não apodrecer; a medição de
## verdade (1.000 NPCs, 1 ano) roda com tests/soak/run_sp1 e não faz parte do check_all.


func _hash_and_thoughts(world_seed: int) -> Array:
	var runner: SimulationRunner = SimulationRunner.new(world_seed)
	var population: FakeNpcPopulation = FakeNpcPopulation.new(100)
	assert_true(runner.register_module("npcs", population).ok)
	runner.start_new_game()
	runner.run_days(2)
	var result: Array = [runner.world.state_hash(), population.thoughts_total, runner.world.validate().size()]
	runner.finish()
	return result


func test_spike_population_is_deterministic_and_valid() -> void:
	var first: Array = _hash_and_thoughts(1)
	assert_eq(_hash_and_thoughts(1), first)
	assert_ne(_hash_and_thoughts(2)[0], first[0])
	assert_eq(first[2], 0, "O mundo do spike deve validar.")
	assert_gt(first[1], IntMath.floor_div(100 * 2 * SimClock.MINUTES_PER_DAY, 15) - 100, "Cada NPC pensa a cada 5 a 15 minutos.")
