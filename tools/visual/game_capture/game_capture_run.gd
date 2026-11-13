class_name GameCaptureRun
extends RefCounted
## CAP, ferramenta de desenvolvimento: abre o JOGO REAL (scenes/main.tscn) e, para cada local x hora x câmera, põe o jogador no local, força a luz da hora, enquadra a câmera, espera os quadros, mede e grava um PNG e, no fim, o resumo.txt.
## Precisa de janela e de renderer de verdade (sem janela recusa). Só usa os nós e as chamadas públicas do jogo, nada dele é alterado; só mede, não decide. Opções e nomes: GameCaptureOptions; resumo: GameCaptureReport.

const SCENE_PATH: String = "res://scenes/main.tscn"
const GAME_APP_NAME: String = "GameApp"
const PLAYER_NODE: String = "PlayerBody"
const CAMERA_NODE: String = "Camera"
const RIG_NODE: String = "AmbientRig"
const TERRAIN_NODE: String = "TerrainView"
## Quadros esperando o terreno em volta do jogador montar (20 s a 60 quadros por segundo); estourou, o mundo não montou e a captura daquele local falha com erro.
const ASSEMBLY_FRAME_LIMIT: int = 1200
## Passo de tempo grande dado à câmera para ela chegar ao lugar na hora, em vez de deslizar: as suavizações dela são exponenciais e a mais lenta leva 0,25 s.
const SNAP_DELTA_S: float = 10.0

var _tree: SceneTree
var _bridge: SimBridge
var _player: PlayerBody
var _camera: ThirdPersonCamera
var _rig: AmbientRig
var _terrain: TerrainView
var _has_failed: bool = false


## Motivo de a captura não poder rodar ("" se pode): sem janela (`display_name` é o de DisplayServer.get_name()), argumentos inválidos ou sem pasta de saída.
func refusal(options: GameCaptureOptions, display_name: String) -> String:
	if display_name == RendererAutoRun.HEADLESS_DISPLAY:
		return "a captura do jogo precisa de janela e renderer de verdade; sem janela (--headless) não há quadro desenhado nem imagem para medir. Rode tools/visual/run_game_capture."
	if not options.errors.is_empty():
		return " ".join(PackedStringArray(options.errors))
	if options.out_dir.is_empty():
		return "pasta de saída ausente; esperado --out=<pasta>."
	return ""


## Roda todas as combinações, grava o resumo em `options.out_dir` e encerra o jogo (código 1 se algo falhou).
func run(tree: SceneTree, options: GameCaptureOptions) -> void:
	var problem: String = refusal(options, DisplayServer.get_name())
	if problem.is_empty() and DirAccess.make_dir_recursive_absolute(options.out_dir) != OK:
		problem = "não foi possível criar a pasta de saída '%s'." % options.out_dir
	var markets: Dictionary[String, Vector2] = {}
	if problem.is_empty():
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		await tree.process_frame
		var main: Node = (load(SCENE_PATH) as PackedScene).instantiate()
		tree.root.add_child(main)
		problem = bind(main)
		if problem.is_empty():
			markets = market_positions()
			problem = options.market_problem(markets)
	if not problem.is_empty():
		_fail(problem)
		tree.quit(1)
		return
	var shots: Array[RendererAutoRun.Shot] = await _visit_all(options, markets)
	_write_summary(options, shots)
	tree.quit(1 if _has_failed else 0)


## Acha as peças do jogo (nós da main.tscn e a ponte do autoload GameApp) e desliga o relógio de luz do rig, para a hora forçada não ser sobrescrita pela da simulação. Devolve o problema ("" se achou tudo).
func bind(main: Node) -> String:
	_tree = main.get_tree()
	var app: GameAppNode = _tree.root.get_node_or_null(GAME_APP_NAME) as GameAppNode
	_bridge = app.peek_bridge() if app != null else null
	_player = main.get_node_or_null(PLAYER_NODE) as PlayerBody
	_camera = main.get_node_or_null(CAMERA_NODE) as ThirdPersonCamera
	_rig = main.get_node_or_null(RIG_NODE) as AmbientRig
	_terrain = main.get_node_or_null(TERRAIN_NODE) as TerrainView
	var parts: Dictionary[String, Object] = {GAME_APP_NAME: _bridge, PLAYER_NODE: _player, CAMERA_NODE: _camera, RIG_NODE: _rig, TERRAIN_NODE: _terrain}
	var missing: Array[String] = []
	for part_name: String in parts:
		if parts[part_name] == null:
			missing.append(part_name)
	if not missing.is_empty():
		return "peças do jogo não encontradas: %s (esperado o autoload e os nós da scenes/main.tscn)." % ", ".join(PackedStringArray(missing))
	if not (_player.is_spawned() and _camera.is_following() and _rig.config != null):
		return "o jogador não nasceu, a câmera não o segue ou o AmbientRig está sem AmbientConfig (veja os erros do jogo acima)."
	_rig.set_process(false)
	return ""


## Os mercados do jogo (id -> x, z em metros), lidos de peek_places.
func market_positions() -> Dictionary[String, Vector2]:
	var markets: Dictionary[String, Vector2] = {}
	for place: BridgeReplies.PlaceReply in _bridge.peek_places().places:
		if place.kind == Place.KIND_MARKET:
			markets[place.id] = Vector2(place.x, place.z)
	return markets


## Põe o jogador em (x, z) sobre a altura do terreno e espera o mundo em volta montar. Só o NÓ se move: o relato à ponte e o foco do terreno seguem sozinhos, como no jogo (o foco é informado
## aqui também para a fila nova já existir quando a espera olhar). Falso, depois de erro, se a altura falhar ou o terreno não montar em ASSEMBLY_FRAME_LIMIT quadros.
func go_to(xz_m: Vector2) -> bool:
	var ground: BridgeReplies.HeightReply = _bridge.peek_height(xz_m.x, xz_m.y)
	if not ground.result.ok:
		return _fail("altura do terreno indisponível em (x=%s, z=%s): %s" % [str(xz_m.x), str(xz_m.y), ground.result.message])
	_player.global_position = Vector3(xz_m.x, ground.height_m + PlayerBody.SPAWN_CLEARANCE_M, xz_m.y)
	_player.velocity = Vector3.ZERO
	_terrain.set_focus(_player.global_position)
	for _frame: int in ASSEMBLY_FRAME_LIMIT:
		if _terrain.pending_count() + _terrain.collision_pending_count() + _terrain.free_pending_count() == 0:
			return true
		await _tree.process_frame
	return _fail("o terreno em volta de (x=%s, z=%s) não montou em %d quadros (ASSEMBLY_FRAME_LIMIT)." % [str(xz_m.x), str(xz_m.y), ASSEMBLY_FRAME_LIMIT])


## Força a luz da hora (o relógio do rig está desligado, então ela fica) e enquadra a câmera na vista, que chega ao lugar na hora. Falso, depois de erro, se o rig recusar a luz.
func stage(hour: float, camera: String) -> bool:
	if not _rig.apply_state(DayNightCycle.state_at(_rig.config, hour)):
		return _fail("o AmbientRig recusou a luz das %s." % GameCaptureOptions.hour_label(hour))
	var view: Vector3 = GameCaptureOptions.CAMERA_VIEWS[camera]
	_camera.distance_m = view.x
	_camera.pitch_rad = deg_to_rad(view.y)
	_camera.yaw_rad = deg_to_rad(view.z)
	_camera.follow_step(SNAP_DELTA_S)
	_camera.view_step(SNAP_DELTA_S)
	return true


## Espera os quadros, mede o tempo de cada um (os de acomodação não contam) e, depois do desenho do último, lê os monitores, grava o PNG `file_name` em `out_dir` e mede a cor.
func capture(out_dir: String, file_name: String) -> RendererAutoRun.Shot:
	var shot: RendererAutoRun.Shot = RendererAutoRun.Shot.new()
	shot.label = file_name.get_basename()
	var total_us: int = 0
	var worst_us: int = 0
	var last_us: int = Time.get_ticks_usec()
	for frame: int in RendererAutoRun.SETTLE_FRAMES + RendererAutoRun.MEASURE_FRAMES:
		await _tree.process_frame
		var now_us: int = Time.get_ticks_usec()
		if frame >= RendererAutoRun.SETTLE_FRAMES:
			total_us += now_us - last_us
			worst_us = maxi(worst_us, now_us - last_us)
		last_us = now_us
	await RenderingServer.frame_post_draw
	shot.fps = float(RendererAutoRun.MEASURE_FRAMES) * RendererAutoRun.MICROSECONDS_PER_SECOND / float(maxi(total_us, 1))
	shot.worst_ms = float(worst_us) / RendererAutoRun.MICROSECONDS_PER_MS
	shot.draw_calls = int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	shot.primitives = int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	shot.objects = int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))
	shot.video_mb = Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / RendererAutoRun.BYTES_PER_MB
	var image: Image = _tree.root.get_texture().get_image()
	if image == null or image.is_empty():
		_fail("a captura '%s' veio vazia (renderer sem imagem, como o modo sem janela)." % shot.label)
		return shot
	var path: String = out_dir.path_join(file_name)
	if image.save_png(path) == OK:
		shot.file = file_name
	else:
		_fail("não foi possível gravar o PNG '%s'." % path)
	var means: Vector2 = GameCaptureReport.color_means(image)
	shot.saturation = means.x
	shot.brightness = means.y
	return shot


## Local por local (o terreno é a espera mais cara), hora por hora e câmera por câmera.
func _visit_all(options: GameCaptureOptions, markets: Dictionary[String, Vector2]) -> Array[RendererAutoRun.Shot]:
	var spawn: Vector3 = _bridge.peek_spawn_point().point
	var shots: Array[RendererAutoRun.Shot] = []
	for spot: GameCaptureOptions.Spot in options.spots:
		if not await go_to(spot.position_m(markets, Vector2(spawn.x, spawn.z))):
			continue
		for hour: float in options.hours:
			for camera: String in options.cameras:
				if stage(hour, camera):
					shots.append(await capture(options.out_dir, GameCaptureOptions.shot_file(hour, spot, camera)))
	return shots


func _write_summary(options: GameCaptureOptions, shots: Array[RendererAutoRun.Shot]) -> void:
	var environment: String = "renderer: %s | driver: %s | placa: %s | godot: %s" % [RenderingServer.get_current_rendering_method(), RenderingServer.get_current_rendering_driver_name(), RenderingServer.get_video_adapter_name(), Engine.get_version_info()["string"]]
	var path: String = options.out_dir.path_join(RendererAutoRun.SUMMARY_FILE)
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_fail("não foi possível gravar '%s' (%s)." % [path, error_string(FileAccess.get_open_error())])
		return
	file.store_string(GameCaptureReport.text(environment, _tree.root.size, options, shots))
	file.close()


func _fail(message: String) -> bool:
	_has_failed = true
	push_error("GameCaptureRun: %s" % message)
	return false
