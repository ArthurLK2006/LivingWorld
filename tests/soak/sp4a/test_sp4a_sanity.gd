extends GutTest
## Teste rápido do código do spike SP4a (sem janela) para ele não apodrecer; a medição de
## verdade roda com tests/soak/run_sp4a e não faz parte do check_all.


func test_height_is_deterministic() -> void:
	var a: Sp4aTerrainData = Sp4aTerrainData.new()
	var b: Sp4aTerrainData = Sp4aTerrainData.new()
	assert_eq(a.get_height(123.0, 456.0), b.get_height(123.0, 456.0))
	assert_eq(a.peek_spawn_point(), b.peek_spawn_point())


func test_surface_is_deterministic() -> void:
	var a: Sp4aTerrainData = Sp4aTerrainData.new()
	var b: Sp4aTerrainData = Sp4aTerrainData.new()
	assert_eq(a.get_surface(300.0, 300.0), b.get_surface(300.0, 300.0))
	assert_eq(a.get_surface(300.0, 300.0), "hill_top")


func test_query_outside_map_reports_error() -> void:
	var data: Sp4aTerrainData = Sp4aTerrainData.new()
	var height_query: Dictionary = data.peek_height(-1.0, 0.0)
	assert_false(height_query["result"].ok)
	assert_eq(height_query["result"].code, "SP4A_OUT_OF_MAP")
	var surface_query: Dictionary = data.peek_surface(Sp4aTerrainData.MAP_SIZE + 1.0, 0.0)
	assert_false(surface_query["result"].ok)


func test_query_inside_map_succeeds() -> void:
	var data: Sp4aTerrainData = Sp4aTerrainData.new()
	var height_query: Dictionary = data.peek_height(0.0, 0.0)
	assert_true(height_query["result"].ok)
	var surface_query: Dictionary = data.peek_surface(0.0, 0.0)
	assert_true(surface_query["result"].ok)


func test_chunk_count_matches_grid() -> void:
	var data: Sp4aTerrainData = Sp4aTerrainData.new()
	assert_eq(data.chunk_count(), Sp4aTerrainData.CHUNKS_PER_SIDE * Sp4aTerrainData.CHUNKS_PER_SIDE)
	assert_eq(data.chunk_count(), 256)


func test_quality_levels_are_all_defined() -> void:
	for level_name: String in Sp4aQualityLevels.ORDER:
		assert_true(Sp4aQualityLevels.is_valid(level_name), "Nível %s deveria existir" % level_name)
		var level: Dictionary = Sp4aQualityLevels.get_level(level_name)
		assert_true(level.has("espaco_vertice"))
		assert_true(level.has("distancia_chunks"))


func test_terrain_own_builds_chunks_without_crashing() -> void:
	var data: Sp4aTerrainData = Sp4aTerrainData.new()
	var own: Sp4aTerrainOwn = Sp4aTerrainOwn.new()
	own.setup(data, 4.0, 2)
	own.set_focus(data.peek_spawn_point())
	assert_true(own.chunk_node_count() > 0)
	own.clear_all()
	assert_eq(own.chunk_node_count(), 0)
	own.free()


func test_metrics_describe_repetitions() -> void:
	var stats: Dictionary = Sp4aMetrics.describe_repetitions([10.0, 20.0, 30.0])
	assert_eq(stats["media"], 20.0)
	assert_eq(stats["minimo"], 10.0)
	assert_eq(stats["maximo"], 30.0)


func test_scenario_runner_parses_cli_args() -> void:
	var args: Dictionary = Sp4aScenarioRunner.parse_args(PackedStringArray(["--modo", "completo", "--terreno", "proprio", "--repeticoes", "5"]))
	assert_eq(args["modo"], "completo")
	assert_eq(args["terreno"], "proprio")
	assert_eq(args["repeticoes"], 5)


func test_scenario_runner_rapido_forces_one_repetition() -> void:
	var args: Dictionary = Sp4aScenarioRunner.parse_args(PackedStringArray(["--modo", "rapido", "--repeticoes", "7"]))
	assert_eq(args["repeticoes"], 1)
