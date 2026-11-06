class_name PlayerBody
extends CharacterBody3D
## Corpo provisório do jogador (LW-045): uma cápsula visível que anda, corre e pula sobre o terreno. A FÍSICA FICA NA
## APRESENTAÇÃO (arquitetura 15): a posição daqui não é estado da simulação e nada é relatado a ela nesta tarefa (o relato é a
## LW-048). Lê o teclado só por ações nomeadas (InputActions). A direção do movimento é relativa ao giro do nó de referência
## (hoje a câmera provisória). Enquanto o chão sob o corpo não tem colisão que valha (TerrainView.has_collision_at) ele fica
## parado, sem cair nem andar. Contrato: docs/modules/presentation.md.

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
## Cor provisória da cápsula [HIP]: laranja, para não se confundir com o terreno.
const CAPSULE_COLOR: Color = Color(0.95, 0.45, 0.10)
const GRAVITY_SETTING: String = "physics/3d/default_gravity"
## Valor padrão da Godot, usado só se a configuração não existir.
const DEFAULT_GRAVITY_MPS2: float = 9.8
const CAPSULE_NAME: String = "Capsule"
const COLLISION_SHAPE_NAME: String = "Shape"
const HALF: float = 0.5

var _terrain: TerrainView
var _direction_reference: Node3D
var _is_spawned: bool = false
var _was_jump_down: bool = false
var _gravity_mps2: float = DEFAULT_GRAVITY_MPS2


func _ready() -> void:
	_gravity_mps2 = float(ProjectSettings.get_setting(GRAVITY_SETTING, DEFAULT_GRAVITY_MPS2))
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(PLAYER_PHYSICS_LAYER, true)
	set_collision_mask_value(TerrainView.TERRAIN_PHYSICS_LAYER, true)
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
	var spawn: SimBridge.SpawnReply = bridge.peek_spawn_point()
	if not spawn.result.ok:
		push_error("PlayerBody.setup: ponto de nascimento indisponível (%s): %s" % [spawn.result.code, spawn.result.message])
		return false
	_terrain = terrain
	_direction_reference = direction_reference
	global_position = spawn.point + Vector3(0.0, SPAWN_CLEARANCE_M, 0.0)
	velocity = Vector3.ZERO
	_was_jump_down = Input.is_action_pressed(InputActions.JUMP)
	_is_spawned = true
	visible = true
	set_physics_process(true)
	return true


func is_spawned() -> bool:
	return _is_spawned


func _physics_process(delta: float) -> void:
	if not _terrain.has_collision_at(global_position):
		velocity = Vector3.ZERO
		return
	_apply_horizontal_input()
	_apply_vertical_motion(delta)
	move_and_slide()


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
