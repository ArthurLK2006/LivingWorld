extends GutTest

## CAP, captura do jogo real, sem janela: argumentos e padrões, tabela de câmeras, nomes de arquivo, resumo.txt, recusa e, no jogo de verdade (sem desenhar), as peças achadas, o jogador no mercado, a luz forçada e a câmera enquadrada.
## A captura de imagem só existe com janela e não é testada aqui.
const MAIN_SCENE_PATH: String = "res://scenes/main.tscn"
const MARKET_ID: String = "a_market_01"
const NOON: float = 12.0
const TOLERANCE: float = 0.001
const SETTLE_FRAMES: int = 5
const BAD_ARGUMENTS: Array[String] = ["--hours=24", "--hours=abc", "--hours=-1", "--cams=wide", "--spots=xz:5", "--spots=xz:5,spawn", "--spots=market:", "--spots=garden:1", "--hour=12", "stray"]


func _parse(arguments: Array[String]) -> GameCaptureOptions:
	return GameCaptureOptions.parse(PackedStringArray(arguments))


func test_defaults_are_the_market_and_the_spawn_at_noon_dusk_and_night_with_the_three_views() -> void:
	var options: GameCaptureOptions = _parse(["--out=/tmp/saida"])
	assert_eq(options.errors.size(), 0, "sem erros")
	assert_eq(options.out_dir, "/tmp/saida")
	assert_eq(options.spots.size(), 2)
	assert_eq(options.spots[0].kind, GameCaptureOptions.KIND_MARKET)
	assert_eq(options.spots[0].place_id, MARKET_ID)
	assert_eq(options.spots[1].kind, GameCaptureOptions.KIND_SPAWN)
	assert_eq(",".join(PackedStringArray(options.hours.map(GameCaptureOptions.hour_label))), "12h00,17h30,19h00")
	assert_eq(",".join(PackedStringArray(options.cameras)), "near,iso,strategic")


func test_lists_are_read_and_xz_takes_the_next_item_as_z() -> void:
	var options: GameCaptureOptions = _parse(["--out=/tmp/a", "--spots=xz:10.5,20,market:b_market_01,spawn", "--hours=6,23.5", "--cams=iso,near"])
	assert_eq(options.errors.size(), 0, "sem erros")
	assert_eq(options.spots.size(), 3)
	assert_eq(options.spots[0].kind, GameCaptureOptions.KIND_XZ)
	var no_markets: Dictionary[String, Vector2] = {}
	assert_eq(options.spots[0].position_m(no_markets, Vector2.ZERO), Vector2(10.5, 20.0))
	assert_eq(options.spots[1].place_id, "b_market_01")
	assert_eq(options.hours.size(), 2)
	assert_eq(options.hours[1], 23.5)
	assert_eq(",".join(PackedStringArray(options.cameras)), "iso,near")


func test_invalid_arguments_are_reported_and_an_empty_list_too() -> void:
	for bad: String in BAD_ARGUMENTS:
		assert_gt(_parse([bad]).errors.size(), 0, bad)
	assert_eq(_parse(["--hours="]).errors.size(), 1, "lista vazia")


func test_the_camera_table_keeps_the_distance_and_the_pitch_of_the_demo() -> void:
	assert_eq(",".join(PackedStringArray(GameCaptureOptions.CAMERA_VIEWS.keys())), "near,iso,strategic")
	for demo: Dictionary in RendererPresets.VIEWS:
		var demo_name: String = demo["name"]
		var view_name: String = "iso" if demo_name == "isometric" else demo_name
		assert_eq(GameCaptureOptions.CAMERA_VIEWS[view_name].x, float(demo["distance"]), view_name)
		assert_eq(GameCaptureOptions.CAMERA_VIEWS[view_name].y, float(demo["pitch"]), view_name)


func test_file_names_carry_the_hour_the_spot_and_the_camera() -> void:
	var market: GameCaptureOptions.Spot = GameCaptureOptions.Spot.new(GameCaptureOptions.KIND_MARKET, MARKET_ID)
	var spawn: GameCaptureOptions.Spot = GameCaptureOptions.Spot.new(GameCaptureOptions.KIND_SPAWN)
	var point: GameCaptureOptions.Spot = GameCaptureOptions.Spot.new(GameCaptureOptions.KIND_XZ, "", 313.5, 556.0)
	assert_eq(GameCaptureOptions.shot_file(NOON, market, "near"), "12h00_a_market_01_near.png")
	assert_eq(GameCaptureOptions.shot_file(17.5, market, "iso"), "17h30_a_market_01_iso.png")
	assert_eq(GameCaptureOptions.shot_file(19.0, spawn, "strategic"), "19h00_spawn_strategic.png")
	assert_eq(GameCaptureOptions.shot_file(0.0, point, "near"), "00h00_xz_313_5_556_near.png")
	assert_eq(GameCaptureOptions.hour_label(23.999), "00h00", "o minuto arredondado passa da meia-noite e volta a zero")


func test_a_market_that_does_not_exist_is_reported_with_the_ones_that_do() -> void:
	var markets: Dictionary[String, Vector2] = {MARKET_ID: Vector2(313.0, 556.0)}
	var problem: String = _parse(["--spots=market:nope"]).market_problem(markets)
	assert_string_contains(problem, "'nope'")
	assert_string_contains(problem, MARKET_ID)
	assert_eq(_parse([]).market_problem(markets), "", "o mercado padrão existe")
	var spot: GameCaptureOptions.Spot = GameCaptureOptions.Spot.new(GameCaptureOptions.KIND_MARKET, MARKET_ID)
	assert_eq(spot.position_m(markets, Vector2.ZERO), Vector2(313.0, 556.0))
	assert_eq(GameCaptureOptions.Spot.new(GameCaptureOptions.KIND_SPAWN).position_m(markets, Vector2(1.0, 2.0)), Vector2(1.0, 2.0))


func test_the_summary_has_the_environment_the_options_the_table_header_and_one_line_per_shot() -> void:
	var options: GameCaptureOptions = _parse(["--spots=market:a_market_01,spawn", "--hours=12,17.5", "--cams=near"])
	var shot: RendererAutoRun.Shot = RendererAutoRun.Shot.new()
	shot.label = "12h00_a_market_01_near"
	shot.fps = 123.456
	shot.file = "12h00_a_market_01_near.png"
	var shots: Array[RendererAutoRun.Shot] = [shot]
	var lines: PackedStringArray = GameCaptureReport.text("renderer: teste", Vector2i(1280, 720), options, shots).split("\n")
	assert_eq(lines.size(), 6, "quatro linhas de cabeçalho, uma por captura e o fim de linha final")
	assert_eq(lines[0], "renderer: teste")
	assert_string_contains(lines[1], "(1280, 720)")
	assert_string_contains(lines[1], "30 de acomodação e 180 medidos")
	assert_eq(lines[2], "jogo real | locais: a_market_01, spawn | horas: 12h00, 17h30 | câmeras: near")
	assert_eq(lines[3], RendererAutoRun.TABLE_HEADER)
	assert_eq(lines[4], shot.to_line())
	assert_string_contains(lines[4], "12h00_a_market_01_near | 123.5 | ")
	assert_eq(lines[5], "")


func test_the_color_means_come_from_a_reduced_copy() -> void:
	var image: Image = Image.create(8, 8, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.8, 0.4, 0.2))
	var means: Vector2 = GameCaptureReport.color_means(image)
	assert_almost_eq(means.x, 0.75, 0.02, "saturação de uma cor lisa")
	assert_almost_eq(means.y, 0.8, 0.02, "brilho de uma cor lisa")
	assert_eq(image.get_width(), 8, "a imagem original não é reduzida")


func test_the_run_refuses_without_a_window_and_with_bad_arguments() -> void:
	var run: GameCaptureRun = GameCaptureRun.new()
	var options: GameCaptureOptions = _parse(["--out=/tmp/saida"])
	assert_string_contains(run.refusal(options, RendererAutoRun.HEADLESS_DISPLAY), "precisa de janela")
	assert_eq(run.refusal(options, "macos"), "", "com janela e argumentos bons roda")
	assert_string_contains(run.refusal(_parse(["--out=/tmp/saida", "--hours=99"]), "macos"), "hora inválida")
	assert_string_contains(run.refusal(_parse([]), "macos"), "--out=<pasta>")


func test_the_run_finds_the_parts_places_the_player_forces_the_light_and_frames_the_camera() -> void:
	var main: Node = (load(MAIN_SCENE_PATH) as PackedScene).instantiate()
	add_child_autofree(main)
	var run: GameCaptureRun = GameCaptureRun.new()
	assert_eq(run.bind(main), "", "as peças do jogo foram achadas")
	var markets: Dictionary[String, Vector2] = run.market_positions()
	assert_true(markets.has(MARKET_ID), "o mercado padrão está nos locais da ponte")
	assert_true(await run.go_to(markets[MARKET_ID]), "o mundo monta em volta do mercado")
	var player: PlayerBody = main.get_node("PlayerBody") as PlayerBody
	assert_almost_eq(player.global_position.x, markets[MARKET_ID].x, 0.01, "o jogador está no mercado (x)")
	assert_almost_eq(player.global_position.z, markets[MARKET_ID].y, 0.01, "o jogador está no mercado (z)")
	assert_true(run.stage(NOON, "strategic"))
	for frame: int in range(SETTLE_FRAMES):
		await get_tree().process_frame
	var rig: AmbientRig = main.get_node("AmbientRig") as AmbientRig
	var sun: DirectionalLight3D = main.get_node("Sun") as DirectionalLight3D
	assert_almost_eq(sun.light_energy, DayNightCycle.state_at(rig.config, NOON).sun_energy, TOLERANCE, "a luz do meio-dia fica, embora o jogo nasça à meia-noite: o relógio do rig está desligado")
	var camera: ThirdPersonCamera = main.get_node("Camera") as ThirdPersonCamera
	var aim: Vector3 = player.global_position + Vector3(0.0, ThirdPersonCamera.AIM_HEIGHT_M, 0.0)
	assert_almost_eq(camera.global_position.distance_to(aim), GameCaptureOptions.CAMERA_VIEWS["strategic"].x, 0.5, "a câmera está na distância da vista")
	assert_almost_eq(camera.global_rotation.x, -deg_to_rad(GameCaptureOptions.CAMERA_VIEWS["strategic"].y), 0.01, "e no ângulo dela")
