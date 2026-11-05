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


## Revisão da Parte A, H1 e item 1a: o vencimento (a,c,b)/(b,c,d) dava normais para BAIXO (achado
## com um teste igual a este, antes de corrigir — ver relatório, seção 4). Confere terreno quase
## plano (longe de colina/vale/caminho) E uma encosta de verdade (perto da colina).
func test_chunk_normals_point_up_on_flat_and_slope() -> void:
	var data: Sp4aTerrainData = Sp4aTerrainData.new()
	var own: Sp4aTerrainOwn = Sp4aTerrainOwn.new()
	own.setup(data, 4.0, 2)
	var hill_focus: Vector3 = Vector3(Sp4aTerrainData.HILL_CENTER.x, 0.0, Sp4aTerrainData.HILL_CENTER.y)
	for focus: Vector3 in [Vector3(50.0, 0.0, 950.0), hill_focus]:
		own.set_focus(focus)
		var checked_any: bool = false
		for chunk_root: Node in own.get_children():
			for child: Node in chunk_root.get_children():
				if child is MeshInstance3D:
					var mesh: ArrayMesh = (child as MeshInstance3D).mesh
					var arrays: Array = mesh.surface_get_arrays(0)
					var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
					for n: Vector3 in normals:
						checked_any = true
						assert_true(n.y > 0.0, "Normal deveria apontar para cima; obteve %s perto de %s" % [n, focus])
		assert_true(checked_any, "Deveria ter conferido ao menos uma normal perto de %s" % focus)
	own.clear_all()
	own.free()


## Item 1b da revisão: todo cenário começa com a câmera acima do terreno por uma margem nomeada
## (CAMERA_MARGIN_*) e com orientação definida (não a padrão/identidade — achado H3: "caminhada"
## e "colisão" moviam a câmera sem nunca chamar look_at, herdando a orientação do cenário
## anterior; ver relatório, seção 4).
func test_every_scenario_starts_camera_above_ground_with_orientation() -> void:
	var data: Sp4aTerrainData = Sp4aTerrainData.new()
	var scene_root: Node3D = autofree(Node3D.new())
	add_child_autofree(scene_root)
	var camera: Sp4aFreeCamera = autofree(Sp4aFreeCamera.new())
	scene_root.add_child(camera)

	var runner: Sp4aScenarioRunner = Sp4aScenarioRunner.new()
	runner.scene_root = scene_root
	runner.camera = camera
	runner.terrain_data = data
	runner.renderer_label = "teste"
	runner.machine_label = "teste"
	runner.result_writer = Sp4aResultWriter.new()

	for cenario: String in Sp4aScenarioRunner.SCENARIOS:
		camera.global_transform = Transform3D.IDENTITY  # reseta entre cenários, para o teste valer sozinho
		await runner._run_single_pass("proprio", cenario, 0.001)
		var ground_height: float = data.get_height(camera.global_position.x, camera.global_position.z)
		assert_true(
			camera.global_position.y > ground_height,
			"Cenário %s: câmera em y=%s deveria estar acima do chão (%s)" % [cenario, camera.global_position.y, ground_height]
		)
		assert_ne(
			camera.global_transform.basis, Basis.IDENTITY,
			"Cenário %s: orientação da câmera deveria estar definida (diferente da identidade)" % cenario
		)


## Item 1c: --renderer-label precisa ser lido corretamente (H4 — ProjectSettings não reflete
## --rendering-method da linha de comando; ver relatório, seção 4).
func test_scenario_runner_parses_renderer_label() -> void:
	var args: Dictionary = Sp4aScenarioRunner.parse_args(PackedStringArray(["--renderer-label", "forward_plus"]))
	assert_eq(args["renderer_label"], "forward_plus")
	var default_args: Dictionary = Sp4aScenarioRunner.parse_args(PackedStringArray([]))
	assert_eq(default_args["renderer_label"], "gl_compatibility")


## H5: sample_frame() agora recebe o delta real (varia a cada quadro), em vez de derivar de
## Performance.TIME_FPS (atualiza ~1x/s e fazia "FPS mín" e "1% pior" saírem sempre iguais).
func test_metrics_frame_times_vary_with_real_delta() -> void:
	var metrics: Sp4aMetrics = Sp4aMetrics.new()
	metrics.start_window()
	# Deltas bem diferentes entre si (ao contrário de um TIME_FPS constante por ~1s).
	for delta_ms: Array in [[0.010], [0.012], [0.200], [0.011], [0.013]]:
		metrics.sample_frame(delta_ms[0])
	var stats: Dictionary = metrics.finish()
	assert_true(stats["fps_min"] < stats["fps_medio"], "Com deltas variados, o mínimo deveria ficar abaixo da média")
	assert_almost_eq(stats["fps_1pct_pior"], stats["fps_min"], 0.01, "Com só 5 amostras, o 1% pior ainda deve coincidir com o mínimo")


## H6: toda consulta de métricas registra se a janela estava com foco (DisplayServer.
## window_is_focused()); o campo precisa existir para a rodada poder ser marcada INVÁLIDA.
func test_metrics_reports_focus_field() -> void:
	var metrics: Sp4aMetrics = Sp4aMetrics.new()
	metrics.start_window()
	metrics.sample_frame(0.016)
	var stats: Dictionary = metrics.finish()
	assert_true(stats.has("invalida_por_foco"))
	assert_true(stats.has("amostras_sem_foco"))


## H2: vertex_spacing do Terrain3D muda a ESCALA DO MUNDO (achado e corrigido — ver relatório,
## seção 4), então fica FIXO; só mesh_size/mesh_lods variam por nível (não deslocam o mundo).
func test_addon_quality_levels_do_not_vary_world_scale() -> void:
	for level_name: String in Sp4aQualityLevels.ORDER:
		var level: Dictionary = Sp4aQualityLevels.get_level(level_name)
		assert_true(level.has("addon_mesh_size"), "Nível %s precisa de addon_mesh_size" % level_name)
		assert_true(level.has("addon_mesh_lods"), "Nível %s precisa de addon_mesh_lods" % level_name)
	assert_eq(Sp4aTerrainAddon.FIXED_VERTEX_SPACING, 1.0)
