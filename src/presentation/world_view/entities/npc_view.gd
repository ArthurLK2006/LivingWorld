class_name NpcView
extends Node3D
## Corpo provisório de um NPC em S0 (LW-072b): uma cápsula azul-acinzentada com um "nariz" que mostra a frente (-Z local, como no `look_at`).
## A origem fica nos pés, como no `PlayerBody`. SÓ VISUAL: sem colisão, sem física e sem regra de jogo. Parado fica imóvel; andando quica na
## vertical e se inclina um pouco para a frente. Não conhece o `npc`: guarda só o ID do NPC a que está ligado. Contrato: docs/modules/presentation.md.

## Cápsula [HIP] (m): a mesma do jogador, com poucos segmentos (até 50 corpos na tela; estilo low-poly).
const CAPSULE_RADIUS_M: float = 0.4
const CAPSULE_HEIGHT_M: float = 1.8
const CAPSULE_RADIAL_SEGMENTS: int = 8
const CAPSULE_RINGS: int = 2
## Cores [HIP], iguais para todos os NPCs: corpo azul-acinzentado (longe do laranja do jogador) e nariz claro.
const BODY_COLOR: Color = Color(0.45, 0.55, 0.70)
const NOSE_COLOR: Color = Color(0.92, 0.92, 0.85)
## Nariz [HIP]: lado do cubo (m) e altura dele como fração da altura do corpo.
const NOSE_SIZE_M: float = 0.2
const NOSE_HEIGHT_RATIO: float = 0.8
## Andar [HIP]: quiques por segundo, altura do quique (m) e inclinação para a frente (graus).
const WALK_BOUNCES_PER_SECOND: float = 2.5
const WALK_BOUNCE_HEIGHT_M: float = 0.06
const WALK_TILT_DEGREES: float = 4.0
const VISUAL_NAME: String = "Visual"
const CAPSULE_NAME: String = "Capsule"
const NOSE_NAME: String = "Nose"
const HALF: float = 0.5

## NPC a que o corpo está ligado (IdGenerator.NO_ID = livre, esperando no pool).
var npc_id: int = IdGenerator.NO_ID

## Parte que balança: a cápsula e o nariz ficam nela, para o nó do corpo guardar sempre a posição lógica (os pés no chão).
var _visual: Node3D
var _is_walking: bool = false
var _bounce_phase: float = 0.0


func _init() -> void:
	_visual = Node3D.new()
	_visual.name = VISUAL_NAME
	add_child(_visual)
	var capsule: CapsuleMesh = CapsuleMesh.new()
	capsule.radius = CAPSULE_RADIUS_M
	capsule.height = CAPSULE_HEIGHT_M
	capsule.radial_segments = CAPSULE_RADIAL_SEGMENTS
	capsule.rings = CAPSULE_RINGS
	_visual.add_child(_new_part(CAPSULE_NAME, capsule, BODY_COLOR, Vector3(0.0, CAPSULE_HEIGHT_M * HALF, 0.0)))
	var nose: BoxMesh = BoxMesh.new()
	nose.size = Vector3.ONE * NOSE_SIZE_M
	# O nariz fica à frente (-Z local), na altura da cabeça.
	_visual.add_child(_new_part(NOSE_NAME, nose, NOSE_COLOR, Vector3(0.0, CAPSULE_HEIGHT_M * NOSE_HEIGHT_RATIO, -CAPSULE_RADIUS_M)))


## A Godot liga o `_process` sozinha quando o nó entra na árvore (o script tem `_process`); o corpo só processa andando.
func _ready() -> void:
	set_process(_is_walking)


## Liga o corpo ao NPC, parado, olhando para -Z, com os pés em `ground_position` (metros, mundo), e o mostra.
func attach(new_npc_id: int, ground_position: Vector3) -> void:
	set_walking(false)
	npc_id = new_npc_id
	position = ground_position
	rotation = Vector3.ZERO
	visible = true


## Solta o NPC: o corpo some e fica livre para o pool.
func detach() -> void:
	set_walking(false)
	npc_id = IdGenerator.NO_ID
	visible = false


## Liga ou desliga o andar. Parar devolve o corpo à posição de pé (sem quique nem inclinação).
func set_walking(walking: bool) -> void:
	if walking == _is_walking:
		return
	_is_walking = walking
	_bounce_phase = 0.0
	_visual.position = Vector3.ZERO
	_visual.rotation = Vector3(-deg_to_rad(WALK_TILT_DEGREES), 0.0, 0.0) if walking else Vector3.ZERO
	set_process(walking)


func is_walking() -> bool:
	return _is_walking


## Avança o quique em `delta` segundos. Parado não faz nada. O quique nunca afunda o corpo no chão: vai de 0 até WALK_BOUNCE_HEIGHT_M.
func advance_animation(delta: float) -> void:
	if not _is_walking:
		return
	_bounce_phase = fmod(_bounce_phase + delta * WALK_BOUNCES_PER_SECOND * PI, PI)
	_visual.position.y = sin(_bounce_phase) * WALK_BOUNCE_HEIGHT_M


func _process(delta: float) -> void:
	advance_animation(delta)


static func _new_part(part_name: String, mesh: PrimitiveMesh, color: Color, at: Vector3) -> MeshInstance3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	mesh.material = material
	var part: MeshInstance3D = MeshInstance3D.new()
	part.name = part_name
	part.mesh = mesh
	part.position = at
	return part
