class_name Sp2Main
extends Node
## LW-071 (SP2, DESCARTÁVEL): cena do spike de corpos e LOD de NPCs. Carrega a cena principal REAL do jogo (precedentes: game_release e
## sp6) para chão, câmera e jogador, e monta por cima o mundo próprio do spike (Sp2World: 100 NPCs, LOD e protocolo S0), os corpos
## (Sp2Embodiment) e a medição (Sp2Trials). O jogador entrega o foco do LOD a cada quadro pela API pública (request_set_focus). As teclas
## do spike são registradas SÓ em tempo de execução (autorização A3): N navegação, M política, B números, H painel. Argumentos depois de
## "--": --modo ver|medir|headless, --ensaios alternancia,carga,relogio, --politica P1|P2, --nav N1|N2.

const GAME_SCENE: String = "res://scenes/main.tscn"
const WORLD_DIR: String = "res://data/world"
const NAV_ACTION: StringName = &"sp2_nav"
const POLICY_ACTION: StringName = &"sp2_policy"
const NUMBERS_ACTION: StringName = &"sp2_numbers"
const PANEL_ACTION: StringName = &"sp2_panel"
const MS_PER_SECOND: float = 1000.0

var world: Sp2World
var embodiment: Sp2Embodiment
var player: PlayerBody
var terrain_view: TerrainView
var camera: Camera3D
var bridge: SimBridge
var terrain: TerrainData
var problem: String = ""
## Focos extras (ensaio de carga): ID -> posição em metros.
var extra_foci: Dictionary[int, Vector3] = {}
var sim_usec_total: int = 0
var sim_frames: int = 0
var sim_usec_worst: int = 0
var frames_seen: int = 0

var _panel: Label = Label.new()
var _carry_ms: float = 0.0
var _trials: Sp2Trials


func _ready() -> void:
	_register_actions()
	var game: Node = (load(GAME_SCENE) as PackedScene).instantiate()
	add_child(game)
	player = game.get_node("PlayerBody") as PlayerBody
	terrain_view = game.get_node("TerrainView") as TerrainView
	camera = game.get_node("Camera") as Camera3D
	bridge = (get_node("/root/GameApp") as GameAppNode).peek_bridge()
	var loaded: TerrainLoader.LoadResult = TerrainLoader.load_dir(WORLD_DIR)
	if not loaded.result.ok:
		_fail("terreno: " + loaded.result.message)
		return
	terrain = loaded.terrain
	var bodies_root: Node3D = Node3D.new()
	bodies_root.name = "Sp2Bodies"
	add_child(bodies_root)
	world = Sp2World.new(terrain)
	if not world.problem.is_empty():
		_fail(world.problem)
		return
	embodiment = Sp2Embodiment.new(world, bodies_root)
	var args: PackedStringArray = OS.get_cmdline_user_args()
	embodiment.policy = Sp2SpeedPolicy.Policy.P2_FROM_CLOCK if _arg(args, "--politica", "P1") == "P2" else Sp2SpeedPolicy.Policy.P1_NATURAL
	embodiment.nav_kind = Sp2Nav.Kind.N2_GRID if _arg(args, "--nav", "N1") == "N2" else Sp2Nav.Kind.N1_STRAIGHT
	var layer: CanvasLayer = CanvasLayer.new()
	_panel.position = Vector2(16.0, 120.0)
	layer.add_child(_panel)
	add_child(layer)
	DisplayServer.window_move_to_foreground()
	_trials = Sp2Trials.new(self)
	_trials.run(_arg(args, "--modo", "ver"), _arg(args, "--ensaios", "alternancia,carga,relogio").split(","))


## Troca o mundo do spike (ensaio de carga): devolve os corpos, encerra o mundo velho e monta o novo.
func replace_world(new_world: Sp2World) -> bool:
	if not new_world.problem.is_empty():
		_fail(new_world.problem)
		return false
	embodiment.swap_world(new_world)
	world.finish()
	world = new_world
	return true


func _process(delta: float) -> void:
	if world == null or not problem.is_empty():
		return
	frames_seen += 1
	var time: BridgeReplies.TimeSnapshot = bridge.peek_time()
	if player.is_spawned():
		world.module.request_set_focus(player.get_actor_id(), player.global_position)
	for focus_id: int in extra_foci:
		world.module.request_set_focus(focus_id, extra_foci[focus_id])
	_carry_ms += delta * MS_PER_SECOND
	var whole_ms: int = int(_carry_ms)
	_carry_ms -= float(whole_ms)
	var start_us: int = Time.get_ticks_usec()
	world.advance(whole_ms, time.is_paused, time.speed)
	embodiment.apply_lod_changes(world.take_changes())
	embodiment.sync_intents(time.speed)
	sim_usec_total += Time.get_ticks_usec() - start_us
	sim_usec_worst = maxi(sim_usec_worst, Time.get_ticks_usec() - start_us)
	sim_frames += 1
	if frames_seen % Sp2Constants.CHECK_EVERY_FRAMES == 0:
		embodiment.check_invariants()
	if _panel.visible:
		_panel.text = panel_text(time)


func _physics_process(delta: float) -> void:
	if world == null or not problem.is_empty():
		return
	var time: BridgeReplies.TimeSnapshot = bridge.peek_time()
	embodiment.physics_step(delta, time.speed, time.is_paused)


func _unhandled_input(event: InputEvent) -> void:
	if embodiment == null:
		return
	if event.is_action_pressed(NAV_ACTION):
		embodiment.nav_kind = Sp2Nav.Kind.N2_GRID if embodiment.nav_kind == Sp2Nav.Kind.N1_STRAIGHT else Sp2Nav.Kind.N1_STRAIGHT
	elif event.is_action_pressed(POLICY_ACTION):
		embodiment.policy = Sp2SpeedPolicy.Policy.P2_FROM_CLOCK if embodiment.policy == Sp2SpeedPolicy.Policy.P1_NATURAL else Sp2SpeedPolicy.Policy.P1_NATURAL
	elif event.is_action_pressed(NUMBERS_ACTION):
		embodiment.set_numbers_shown(not embodiment.are_numbers_shown)
	elif event.is_action_pressed(PANEL_ACTION):
		_panel.visible = not _panel.visible


func panel_text(time: BridgeReplies.TimeSnapshot) -> String:
	var counters: Dictionary = world.intent_counters()
	var checker: Sp2Checker = embodiment.checker
	return "SP2 (H esconde)\nNPCs em S0: %d · corpos ativos: %d · livres no pool: %d\nduplicados %d · órfãos %d · teleportes %d\nchegadas %d · feitas %d · bloqueadas %d · tempos limite %d\npolítica (M): %s · navegação (N): %s\nrelógio: %s · quadros/s: %.0f" % [
		world.module.lod.s0_ids().size(), embodiment.pool.active_count(), embodiment.pool.free_count(), checker.duplicates, checker.orphans, checker.teleports,
		embodiment.arrived, embodiment.done, embodiment.blocked, counters["timed_out_intents"], Sp2SpeedPolicy.label(embodiment.policy), Sp2Nav.label(embodiment.nav_kind),
		"PAUSADO" if time.is_paused else "%dx" % time.speed, Engine.get_frames_per_second()]


func sim_cost_text() -> String:
	return "custo do mundo do spike (passos, diretor, LOD, Intents, trocas de corpo) %.1f µs por quadro, pior quadro %.2f ms" % [float(sim_usec_total) / float(maxi(sim_frames, 1)), float(sim_usec_worst) / 1000.0]


func _fail(why: String) -> void:
	problem = why
	push_error("Sp2Main: " + why)
	get_tree().quit(1)


static func _arg(args: PackedStringArray, flag: String, fallback: String) -> String:
	var at: int = args.find(flag)
	return args[at + 1] if at >= 0 and at + 1 < args.size() else fallback


func _register_actions() -> void:
	_register(NAV_ACTION, KEY_N)
	_register(POLICY_ACTION, KEY_M)
	_register(NUMBERS_ACTION, KEY_B)
	_register(PANEL_ACTION, KEY_H)


## Cria a ação só em tempo de execução e recusa (push_error) a tecla que já pertença a uma das ações oficiais (precedente do sp6).
func _register(action: StringName, key: Key) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = key
	for official: StringName in InputActions.ALL:
		if InputMap.action_has_event(official, event):
			push_error("Sp2Main: a tecla da ação '%s' já pertence à ação oficial '%s'." % [action, official])
			return
	InputMap.add_action(action)
	InputMap.action_add_event(action, event)
