class_name PlayerBody
extends CharacterBody3D
## Corpo provisório do jogador (LW-045): uma cápsula visível que anda, corre e pula sobre o terreno. A FÍSICA FICA NA
## APRESENTAÇÃO (arquitetura 15): quem manda na posição é este corpo. Ao nascer ele pede à simulação um personagem (pela ponte) e,
## a cada poucos quadros de física, RELATA a posição e a orientação (LW-048); a simulação guarda o que foi relatado e nunca devolve
## posição ao corpo (fluxo de um sentido só). Lê o teclado só por ações nomeadas (InputActions). A direção do movimento é relativa ao giro do nó de referência
## (a câmera de terceira pessoa). Enquanto o chão sob o corpo não tem colisão que valha (TerrainView.has_collision_at) ele fica
## parado, sem cair nem andar. LIMITES (LW-047): encostas acima da inclinação máxima o bloqueiam, ele não passa da borda do mapa
## e, se cair abaixo do terreno, é posto de volta sobre o chão. PAUSA (LW-051, decisão D1 de Arthur): com o relógio da simulação
## pausado o corpo congela (velocidade zero, sem gravidade, sem pulo, sem andar, sem relato); ao despausar tudo volta de onde parou.
## Contrato: docs/modules/presentation.md.

## Velocidades e impulso do pulo [HIP] (m/s).
const WALK_SPEED_MPS: float = 4.0
const RUN_SPEED_MPS: float = 7.0
const JUMP_IMPULSE_MPS: float = 5.0
## Cápsula [HIP] (m). A origem do corpo fica nos pés.
const CAPSULE_RADIUS_M: float = 0.4
const CAPSULE_HEIGHT_M: float = 1.8
## Camada de física do jogador [HIP]: a segunda (a primeira é a do terreno).
const PLAYER_PHYSICS_LAYER: int = 2
## Quanto acima do chão o corpo nasce [HIP] (m); ele assenta sozinho.
const SPAWN_CLEARANCE_M: float = 0.05
## Limites do jogador [HIP] (LW-047): inclinação máxima caminhável (graus; encosta mais íngreme vira parede), margem até a borda
## do mapa (m) e quanto abaixo do terreno (m) o corpo precisa estar para ser reposto sobre o chão.
const MAX_WALKABLE_SLOPE_DEGREES: float = 40.0
const BORDER_MARGIN_M: float = 1.0
const RECOVERY_DEPTH_M: float = 2.0
## Relato de posição [HIP] (LW-048): a cada tantos quadros de física (6 = 10 por segundo a 60 Hz) e uma vez ao nascer.
const REPORT_EVERY_PHYSICS_FRAMES: int = 6
## Cor provisória da cápsula [HIP]: laranja, para não se confundir com o terreno.
const CAPSULE_COLOR: Color = Color(0.95, 0.45, 0.10)
const GRAVITY_SETTING: String = "physics/3d/default_gravity"
## Valor padrão da Godot, usado só se a configuração não existir.
const DEFAULT_GRAVITY_MPS2: float = 9.8
const CAPSULE_NAME: String = "Capsule"
const COLLISION_SHAPE_NAME: String = "Shape"
const HALF: float = 0.5

var _terrain: TerrainView
var _bridge: SimBridge
var _world_size_m: Vector2 = Vector2.ZERO
var _spawn_point: Vector3 = Vector3.ZERO
var _has_reported_height_error: bool = false
var _direction_reference: Node3D
var _is_spawned: bool = false
var _was_jump_down: bool = false
var _gravity_mps2: float = DEFAULT_GRAVITY_MPS2
## Congelado pela pausa do relógio; guarda a velocidade vertical para o pulo ou a queda continuarem de onde pararam.
var _is_frozen: bool = false
var _frozen_vertical_mps: float = 0.0
## Personagem deste corpo na simulação (IdGenerator.NO_ID = não nasceu lá; o corpo anda do mesmo jeito, só não relata).
var _actor_id: int = IdGenerator.NO_ID
var _frames_since_report: int = 0
## Códigos de falha já avisados no log: cada código avisa uma vez só, para uma falha repetida não encher o log.
var _warned_codes: Dictionary[String, bool] = {}


func _ready() -> void:
	_gravity_mps2 = float(ProjectSettings.get_setting(GRAVITY_SETTING, DEFAULT_GRAVITY_MPS2))
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(PLAYER_PHYSICS_LAYER, true)
	set_collision_mask_value(TerrainView.TERRAIN_PHYSICS_LAYER, true)
	floor_max_angle = deg_to_rad(MAX_WALKABLE_SLOPE_DEGREES)
	_add_capsule()
	visible = false
	set_physics_process(false)


## Faz o corpo nascer no ponto de nascimento da ponte, um pouco acima do chão. Chamar com o nó já na árvore. Ponte nula, ponte sem
## terreno, nó nulo ou nó fora da árvore: push_error e o corpo NÃO nasce (invisível, sem física). Devolve se nasceu.
func setup(bridge: SimBridge, terrain: TerrainView, direction_reference: Node3D) -> bool:
	_is_spawned = false
	visible = false
	set_physics_process(false)
	if bridge == null:
		push_error("PlayerBody.setup: ponte nula; esperado uma SimBridge.")
		return false
	if terrain == null or direction_reference == null:
		push_error("PlayerBody.setup: TerrainView ou nó de referência nulo; esperado os dois.")
		return false
	if not is_inside_tree():
		push_error("PlayerBody.setup: o corpo precisa estar na árvore de cena antes do setup.")
		return false
	var spawn: BridgeReplies.SpawnReply = bridge.peek_spawn_point()
	if not spawn.result.ok:
		push_error("PlayerBody.setup: ponto de nascimento indisponível (%s): %s" % [spawn.result.code, spawn.result.message])
		return false
	var layout: BridgeReplies.TerrainLayoutReply = bridge.peek_terrain_layout()
	if not layout.result.ok:
		push_error("PlayerBody.setup: formato do terreno indisponível (%s): %s" % [layout.result.code, layout.result.message])
		return false
	_terrain = terrain
	_bridge = bridge
	_world_size_m = layout.size_m
	_spawn_point = spawn.point
	_has_reported_height_error = false
	_is_frozen = false
	_direction_reference = direction_reference
	_place_at(spawn.point)
	_was_jump_down = Input.is_action_pressed(InputActions.JUMP)
	_is_spawned = true
	visible = true
	set_physics_process(true)
	_spawn_character()
	return true


func is_spawned() -> bool:
	return _is_spawned


## ID do personagem deste corpo na simulação, ou IdGenerator.NO_ID se ele não nasceu lá (ponte sem jogo ou sem personagem).
func get_actor_id() -> int:
	return _actor_id


func _physics_process(delta: float) -> void:
	if _is_frozen_by_pause():
		return
	if not _terrain.has_collision_at(global_position):
		velocity = Vector3.ZERO
		return
	_apply_horizontal_input()
	_apply_vertical_motion(delta)
	move_and_slide()
	_keep_inside_world()
	_recover_if_below_terrain()
	_frames_since_report += 1
	if _frames_since_report >= REPORT_EVERY_PHYSICS_FRAMES:
		_report_position()


## Pausa do relógio da simulação (lida pela ponte: `peek_time().is_paused`) congela o corpo: velocidade zero, sem andar, sem gravidade,
## sem pulo e sem relato. A tecla de pulo continua sendo lida, para segurá-la durante a pausa não disparar um pulo ao despausar. Ao
## despausar a velocidade vertical de antes volta, e a posição não salta (o corpo nunca foi movido). Hora indisponível (ponte sem jogo)
## conta como não pausado. Devolve se o corpo está congelado agora.
func _is_frozen_by_pause() -> bool:
	var time: BridgeReplies.TimeSnapshot = _bridge.peek_time()
	if time.result.ok and time.is_paused:
		if not _is_frozen:
			_is_frozen = true
			_frozen_vertical_mps = velocity.y
		velocity = Vector3.ZERO
		_was_jump_down = Input.is_action_pressed(InputActions.JUMP)
		return true
	if _is_frozen:
		_is_frozen = false
		velocity.y = _frozen_vertical_mps
	return false


## Ações move_* dão o vetor das teclas (já normalizado), girado pelo yaw do nó de referência: "para frente" é para onde ele olha.
func _apply_horizontal_input() -> void:
	var keys: Vector2 = Input.get_vector(InputActions.MOVE_LEFT, InputActions.MOVE_RIGHT, InputActions.MOVE_FORWARD, InputActions.MOVE_BACK)
	var speed_mps: float = RUN_SPEED_MPS if Input.is_action_pressed(InputActions.RUN) else WALK_SPEED_MPS
	var yaw: Basis = Basis(Vector3.UP, _direction_reference.global_rotation.y)
	var direction: Vector3 = yaw * Vector3(keys.x, 0.0, keys.y)
	velocity.x = direction.x * speed_mps
	velocity.z = direction.z * speed_mps


## No chão o pulo só dispara na descida da tecla (segurá-la não repete o pulo); no ar, a gravidade puxa para baixo.
func _apply_vertical_motion(delta: float) -> void:
	var is_jump_down: bool = Input.is_action_pressed(InputActions.JUMP)
	if is_on_floor():
		velocity.y = JUMP_IMPULSE_MPS if is_jump_down and not _was_jump_down else 0.0
	else:
		velocity.y -= _gravity_mps2 * delta
	_was_jump_down = is_jump_down


## O corpo não passa da borda do mapa: x e z ficam a pelo menos BORDER_MARGIN_M dela (e o corpo desliza ao longo da borda).
func _keep_inside_world() -> void:
	var inside: Vector3 = global_position
	inside.x = clampf(inside.x, BORDER_MARGIN_M, _world_size_m.x - BORDER_MARGIN_M)
	inside.z = clampf(inside.z, BORDER_MARGIN_M, _world_size_m.y - BORDER_MARGIN_M)
	if inside != global_position:
		global_position = inside


## Se o corpo caiu mais de RECOVERY_DEPTH_M abaixo do terreno (a colisão só tem a face de cima), volta para cima do chão no mesmo
## x e z; se a altura do terreno não puder ser lida, volta ao ponto de nascimento. Os dois casos avisam no log.
func _recover_if_below_terrain() -> void:
	var ground: BridgeReplies.HeightReply = _bridge.peek_height(global_position.x, global_position.z)
	if not ground.result.ok:
		if not _has_reported_height_error:
			_has_reported_height_error = true
			push_warning("PlayerBody: altura do terreno indisponível em (x=%s, z=%s): %s; o corpo volta ao ponto de nascimento." % [str(global_position.x), str(global_position.z), ground.result.message])
		_place_at(_spawn_point)
	elif global_position.y < ground.height_m - RECOVERY_DEPTH_M:
		push_warning("PlayerBody: corpo %s m abaixo do terreno em (x=%s, z=%s); reposto sobre o chão." % [str(ground.height_m - global_position.y), str(global_position.x), str(global_position.z)])
		_place_at(Vector3(global_position.x, ground.height_m, global_position.z))


## Pede à simulação um personagem para este corpo e relata a posição de nascimento. Falha (ponte sem jogo ou sem módulo do
## personagem): um aviso no log e o corpo segue sem relatar; nunca derruba nem trava o corpo.
func _spawn_character() -> void:
	_actor_id = IdGenerator.NO_ID
	_frames_since_report = 0
	_warned_codes.clear()
	var reply: BridgeReplies.SpawnCharacterReply = _bridge.request_spawn_character()
	if not reply.result.ok:
		_warn_once(reply.result, "o personagem não nasceu na simulação")
		return
	_actor_id = reply.actor_id
	_report_position()


## Envia a posição dos pés e o giro horizontal do nó de referência de direção (a câmera) ao personagem. Resposta recusada: aviso uma
## vez por código; o corpo não é afetado.
func _report_position() -> void:
	_frames_since_report = 0
	if _actor_id == IdGenerator.NO_ID:
		return
	var outcome: Result = _bridge.request_report_position(_actor_id, global_position, _direction_reference.global_rotation.y)
	if not outcome.ok:
		_warn_once(outcome, "relato de posição recusado")


func _warn_once(failure: Result, what: String) -> void:
	if _warned_codes.has(failure.code):
		return
	_warned_codes[failure.code] = true
	push_warning("PlayerBody: %s (%s): %s" % [what, failure.code, failure.message])


## Põe o corpo sobre o ponto (o chão), com a folga de nascimento, e para o movimento.
func _place_at(ground_point: Vector3) -> void:
	global_position = ground_point + Vector3(0.0, SPAWN_CLEARANCE_M, 0.0)
	velocity = Vector3.ZERO


## Cápsula visível e forma de colisão do mesmo tamanho, com o centro a meia altura (a origem do corpo fica nos pés).
func _add_capsule() -> void:
	var center: Vector3 = Vector3(0.0, CAPSULE_HEIGHT_M * HALF, 0.0)
	var mesh: CapsuleMesh = CapsuleMesh.new()
	mesh.radius = CAPSULE_RADIUS_M
	mesh.height = CAPSULE_HEIGHT_M
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = CAPSULE_COLOR
	mesh.material = material
	var visual: MeshInstance3D = MeshInstance3D.new()
	visual.name = CAPSULE_NAME
	visual.mesh = mesh
	visual.position = center
	add_child(visual)
	var shape: CapsuleShape3D = CapsuleShape3D.new()
	shape.radius = CAPSULE_RADIUS_M
	shape.height = CAPSULE_HEIGHT_M
	var collision: CollisionShape3D = CollisionShape3D.new()
	collision.name = COLLISION_SHAPE_NAME
	collision.shape = shape
	collision.position = center
	add_child(collision)
