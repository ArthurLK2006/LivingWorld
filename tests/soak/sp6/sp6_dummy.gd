class_name Sp6Dummy
extends Node3D
## LW-152 (SP6, DESCARTÁVEL): o boneco de treino. Só DESENHA (não decide regra): corpo, cone na frente (para onde ele olha), brilho
## ao levar golpe, anel amarelo de alvo e número de dano subindo. Formas simples feitas em código (DEC-020); cores e tamanhos [HIP].

const RADIUS_M: float = 0.45
const HEIGHT_M: float = 1.8
const CONE_RADIUS_M: float = 0.3
const CONE_LENGTH_M: float = 0.8
const CONE_OFFSET_M: float = 0.7
const CONE_HEIGHT_FRACTION: float = 0.6
const RING_INNER_M: float = 0.8
const RING_OUTER_M: float = 0.95
const RING_LIFT_M: float = 0.05
const BODY_COLOR: Color = Color(0.8, 0.68, 0.4)
const CONE_COLOR: Color = Color(1.0, 0.25, 0.15)
## O jogo nasce à meia-noite: sem um pouco de emissão o boneco some no escuro (legibilidade vem antes do realismo).
const EMISSION_ENERGY: float = 0.6
## Os números ficam inteiros na primeira metade da vida e só então somem.
const NUMBER_FADE_SPEED: float = 2.0
const FLASH_COLOR: Color = Color(1.0, 1.0, 1.0)
const RING_COLOR: Color = Color(1.0, 0.85, 0.1)
const NUMBER_COLORS: Array[Color] = [Color(1.0, 1.0, 1.0), Color(1.0, 0.65, 0.2), Color(1.0, 0.25, 0.2)]
const NUMBER_START_M: float = 2.2
const NUMBER_FONT_SIZE: int = 64
const NUMBER_OUTLINE_SIZE: int = 14
const NUMBER_PIXEL_SIZE: float = 0.012
const MS_PER_SECOND: float = 1000.0

var _body: Node3D
var _body_material: StandardMaterial3D
var _ring: MeshInstance3D
var _flash_left_s: float = 0.0
var _numbers: Array[Label3D] = []
var _number_ages_s: Array[float] = []


func _ready() -> void:
	_body = Node3D.new()
	add_child(_body)
	_body_material = _material(BODY_COLOR, false)
	var capsule: CapsuleMesh = CapsuleMesh.new()
	capsule.radius = RADIUS_M
	capsule.height = HEIGHT_M
	_add_part(_body, capsule, _body_material, Vector3(0.0, HEIGHT_M * 0.5, 0.0), Quaternion.IDENTITY)
	var cone: CylinderMesh = CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = CONE_RADIUS_M
	cone.height = CONE_LENGTH_M
	var cone_position: Vector3 = Sp6Constants.DUMMY_FRONT * CONE_OFFSET_M + Vector3(0.0, HEIGHT_M * CONE_HEIGHT_FRACTION, 0.0)
	# A ponta do cilindro (topo, raio 0) aponta para +Y; o giro leva +Y para a frente do boneco.
	_add_part(_body, cone, _material(CONE_COLOR, false), cone_position, Quaternion(Vector3.UP, Sp6Constants.DUMMY_FRONT))
	var torus: TorusMesh = TorusMesh.new()
	torus.inner_radius = RING_INNER_M
	torus.outer_radius = RING_OUTER_M
	_ring = _add_part(self, torus, _material(RING_COLOR, true), Vector3(0.0, RING_LIFT_M, 0.0), Quaternion.IDENTITY)
	_ring.visible = false


func show_ring(is_shown: bool) -> void:
	_ring.visible = is_shown


## O boneco caído some até ressurgir; o anel e os números ficam fora do corpo e não somem junto.
func set_alive(is_alive: bool) -> void:
	_body.visible = is_alive


## Brilho no MESMO quadro em que a regra resolve o golpe (quem chama é o nó principal, logo depois do step).
func flash() -> void:
	_flash_left_s = float(Sp6Constants.HIT_FLASH_MS) / MS_PER_SECOND
	_paint(_body_material, FLASH_COLOR)


func pop_number(damage: int, group: int) -> void:
	var label: Label3D = Label3D.new()
	label.text = str(damage)
	label.font_size = NUMBER_FONT_SIZE
	label.outline_size = NUMBER_OUTLINE_SIZE
	label.pixel_size = NUMBER_PIXEL_SIZE
	label.modulate = NUMBER_COLORS[group]
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.position = Vector3(0.0, NUMBER_START_M, 0.0)
	add_child(label)
	_numbers.append(label)
	_number_ages_s.append(0.0)


func _process(delta: float) -> void:
	if _flash_left_s > 0.0:
		_flash_left_s -= delta
		if _flash_left_s <= 0.0:
			_paint(_body_material, BODY_COLOR)
	var life_s: float = float(Sp6Constants.DAMAGE_NUMBER_MS) / MS_PER_SECOND
	for index: int in range(_numbers.size() - 1, -1, -1):
		_number_ages_s[index] += delta
		var label: Label3D = _numbers[index]
		if _number_ages_s[index] >= life_s:
			label.queue_free()
			_numbers.remove_at(index)
			_number_ages_s.remove_at(index)
			continue
		label.position.y = NUMBER_START_M + Sp6Constants.DAMAGE_NUMBER_RISE_MPS * _number_ages_s[index]
		label.modulate.a = minf(1.0, (1.0 - _number_ages_s[index] / life_s) * NUMBER_FADE_SPEED)


func _material(color: Color, is_unshaded: bool) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	if is_unshaded:
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.emission_enabled = not is_unshaded
	material.emission_energy_multiplier = EMISSION_ENERGY
	_paint(material, color)
	return material


func _paint(material: StandardMaterial3D, color: Color) -> void:
	material.albedo_color = color
	material.emission = color


func _add_part(parent: Node3D, mesh: Mesh, material: Material, offset: Vector3, rotation_quaternion: Quaternion) -> MeshInstance3D:
	var part: MeshInstance3D = MeshInstance3D.new()
	part.mesh = mesh
	part.material_override = material
	part.position = offset
	part.quaternion = rotation_quaternion
	parent.add_child(part)
	return part
