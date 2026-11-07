extends Node
## LW-152 (SP6, DESCARTÁVEL): cena do teste de combate. Carrega a cena principal REAL do jogo (precedente: tests/soak/game_release) e
## acrescenta por cima o boneco, a tela e as regras (Sp6Rules). O PlayerBody, a câmera e o terreno NÃO mudam e nada é escrito na
## simulação: o spike só LÊ a posição do jogador, a ponte e a pausa. As teclas do spike são registradas SÓ em tempo de execução
## (autorização A3 de Arthur): nada no project.godot nem no InputActions. Ao fechar a janela imprime o resumo da sessão.

const GAME_SCENE: String = "res://scenes/main.tscn"
const SKILL_ACTIONS: Array[StringName] = [&"sp6_skill_q", &"sp6_skill_r", &"sp6_skill_f"]
const SKILL_KEYS: Array[Key] = [KEY_Q, KEY_R, KEY_F]
const ARMOR_ACTION: StringName = &"sp6_armor"
const CLEAR_ACTION: StringName = &"sp6_clear"
const SELECT_ACTION: StringName = &"sp6_select"
const MS_PER_SECOND: float = 1000.0
const SLOW_FRAME_MS: float = 33.0

var _rules: Sp6Rules = Sp6Rules.new()
var _bridge: SimBridge
var _player: PlayerBody
var _terrain: TerrainView
var _dummy: Sp6Dummy
var _hud: Sp6Hud
## Fração de milissegundo que sobrou do quadro anterior: o relógio das regras é inteiro e não perde tempo.
var _carry_ms: float = 0.0
var _frames: int = 0
## Os quadros só entram no "pior quadro" depois que o terreno da partida terminou de ser montado (precedente da LW-053A).
var _has_settled: bool = false
var _session_s: float = 0.0
var _auto_hits: int = 0
var _skill_hits: int = 0
var _misses: int = 0
var _damage_total: int = 0
var _min_stamina_milli: int = 0
var _worst_frame_ms: float = 0.0
var _slow_frames: int = 0


func _ready() -> void:
	_register_actions()
	var game: Node = (load(GAME_SCENE) as PackedScene).instantiate()
	add_child(game)
	_player = game.get_node("PlayerBody") as PlayerBody
	_terrain = game.get_node("TerrainView") as TerrainView
	_bridge = (get_node("/root/GameApp") as GameAppNode).peek_bridge()
	_dummy = Sp6Dummy.new()
	add_child(_dummy)
	if not _place_dummy():
		set_process(false)
		set_process_unhandled_input(false)
		return
	var layer: CanvasLayer = CanvasLayer.new()
	_hud = Sp6Hud.new()
	layer.add_child(_hud)
	add_child(layer)
	_min_stamina_milli = _rules.stamina_milli()
	_after_rules()
	DisplayServer.window_move_to_foreground()


func _process(delta: float) -> void:
	_track_frame(delta)
	if _is_paused():
		return
	_update_geometry()
	_carry_ms += delta * MS_PER_SECOND
	var whole_ms: int = int(_carry_ms)
	_carry_ms -= float(whole_ms)
	_rules.step(mini(whole_ms, Sp6Constants.MAX_STEP_MS))
	_after_rules()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion or _is_paused():
		return
	_update_geometry()
	for slot: int in Sp6Constants.SKILL_COUNT:
		if event.is_action_pressed(SKILL_ACTIONS[slot]):
			_rules.request_skill(slot)
	if event.is_action_pressed(ARMOR_ACTION):
		_rules.cycle_armor()
	if event.is_action_pressed(CLEAR_ACTION):
		_rules.clear_target()
	if event.is_action_pressed(SELECT_ACTION):
		_select_by_click((event as InputEventMouseButton).position)
	_after_rules()


## Resumo da sessão para o relatório (a única saída por print do spike).
func _exit_tree() -> void:
	print("RESUMO DA SESSÃO (LW-152, SP6)")
	print("  duração %.0f s, %d quadros, build de depuração: %s" % [_session_s, _frames, "sim" if OS.is_debug_build() else "não"])
	print("  golpes dados: %d (automáticos %d, habilidades %d) · erros: %d · dano total: %d" % [_auto_hits + _skill_hits, _auto_hits, _skill_hits, _misses, _damage_total])
	print("  menor estamina: %.1f de %d · pior quadro: %.1f ms (depois do terreno assentar) · quadros acima de %.0f ms: %d" % [
		float(_min_stamina_milli) / float(Sp6Constants.MILLI_PER_POINT), Sp6Constants.STAMINA_MAX, _worst_frame_ms, SLOW_FRAME_MS, _slow_frames])


## O boneco fica à frente do nascimento (a leste, no caminho), na altura do chão que a ponte informa.
func _place_dummy() -> bool:
	if not _player.is_spawned():
		push_error("Sp6Main: o PlayerBody não nasceu; o teste de combate não pode rodar.")
		return false
	var spawn: BridgeReplies.SpawnReply = _bridge.peek_spawn_point()
	if not spawn.result.ok:
		push_error("Sp6Main: ponto de nascimento indisponível (%s): %s" % [spawn.result.code, spawn.result.message])
		return false
	var x_m: float = spawn.point.x + Sp6Constants.DUMMY_DISTANCE_M
	var ground: BridgeReplies.HeightReply = _bridge.peek_height(x_m, spawn.point.z)
	if not ground.result.ok:
		push_error("Sp6Main: altura do chão indisponível em x=%s, z=%s (%s): %s" % [str(x_m), str(spawn.point.z), ground.result.code, ground.result.message])
		return false
	_dummy.position = Vector3(x_m, ground.height_m, spawn.point.z)
	return true


func _is_paused() -> bool:
	var time: BridgeReplies.TimeSnapshot = _bridge.peek_time()
	return time.result.ok and time.is_paused


## Leva as posições do mundo aos dois números das regras: distância horizontal (cm) e ângulo em relação à frente do boneco.
func _update_geometry() -> void:
	_rules.set_geometry(
		Sp6Geometry.horizontal_distance_cm(_player.global_position, _dummy.position),
		Sp6Geometry.angle_from_front_deg(Sp6Constants.DUMMY_FRONT, _dummy.position, _player.global_position))


## Clique esquerdo: raio da câmera contra uma esfera em volta do boneco (sem física); no vazio solta o alvo.
func _select_by_click(point: Vector2) -> void:
	var camera: Camera3D = get_viewport().get_camera_3d()
	var center: Vector3 = _dummy.position + Vector3(0.0, Sp6Constants.PICK_HEIGHT_M, 0.0)
	if Sp6Geometry.ray_hits_sphere(camera.project_ray_origin(point), camera.project_ray_normal(point), center, Sp6Constants.PICK_RADIUS_M):
		_rules.select_target()
	else:
		_rules.clear_target()


## Desenha o resultado das regras NO MESMO QUADRO em que elas o resolveram (logo depois do step ou do aperto da tecla).
func _after_rules() -> void:
	for event: Sp6Rules.CombatEvent in _rules.take_events():
		match event.type:
			Sp6Rules.EventType.HIT:
				_dummy.flash()
				_dummy.pop_number(event.damage, event.group)
				_damage_total += event.damage
				if event.skill == Sp6Constants.NO_SKILL:
					_auto_hits += 1
				else:
					_skill_hits += 1
			Sp6Rules.EventType.MISS:
				_misses += 1
			Sp6Rules.EventType.DEFEATED:
				_dummy.set_alive(false)
			Sp6Rules.EventType.RESPAWNED:
				_dummy.set_alive(true)
		var message: String = Sp6Constants.EVENT_MESSAGES[event.type]
		if not message.is_empty():
			_hud.show_message(message)
	_dummy.show_ring(_rules.has_target())
	_hud.refresh(_rules)
	_min_stamina_milli = mini(_min_stamina_milli, _rules.stamina_milli())


func _track_frame(delta: float) -> void:
	_frames += 1
	_session_s += delta
	if not _has_settled:
		_has_settled = _terrain.pending_count() + _terrain.collision_pending_count() == 0
	else:
		_worst_frame_ms = maxf(_worst_frame_ms, delta * MS_PER_SECOND)
		_slow_frames += 1 if delta * MS_PER_SECOND > SLOW_FRAME_MS else 0


func _register_actions() -> void:
	for slot: int in Sp6Constants.SKILL_COUNT:
		_register(SKILL_ACTIONS[slot], _key_event(SKILL_KEYS[slot]))
	_register(ARMOR_ACTION, _key_event(KEY_T))
	_register(CLEAR_ACTION, _key_event(KEY_ESCAPE))
	var click: InputEventMouseButton = InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	_register(SELECT_ACTION, click)


func _key_event(key: Key) -> InputEventKey:
	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = key
	return event


## Cria a ação só em tempo de execução e recusa (push_error) a tecla que já pertença a uma das ações oficiais do jogo.
func _register(action: StringName, event: InputEvent) -> void:
	for official: StringName in InputActions.ALL:
		if InputMap.action_has_event(official, event):
			push_error("Sp6Main: a entrada da ação '%s' já pertence à ação oficial '%s'." % [action, official])
			return
	InputMap.add_action(action)
	InputMap.action_add_event(action, event)
