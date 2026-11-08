class_name Sp2Body
extends Node3D
## LW-071 (SP2, DESCARTÁVEL): protótipo do corpo de um NPC em S0 (o NpcView definitivo é da LW-072). Cápsula simples (DEC-120) com um
## "nariz" que mostra a direção e cor por estado; SEM física do motor: segue a altura do TerrainData (fora do raio fino não existe colisão
## e o S0 chega a 80 m, pergunta P-e). Só guarda o que o corpo precisa para cumprir UM Intent; quem decide é a simulação.

enum State { IDLE, WALKING, ACTING }

var npc_id: int = 0
## Contador da ação do Intent em curso (0 = nenhum).
var action_serial: int = 0
var kind: NpcIntent.Kind = NpcIntent.Kind.MOVE_TO_PLACE
var path: PackedVector2Array = PackedVector2Array()
var path_index: int = 0
## Fim previsto da ação (minuto de jogo) e minuto em que o corpo recebeu o Intent.
var ends_at: int = 0
var received_at: int = 0
var expected_minutes: int = 0
var state: State = State.IDLE
## Última posição relatada à simulação (vira a posição lógica ao sair de S0).
var last_reported: Vector3 = Vector3.ZERO
var has_reported: bool = false

var _material: StandardMaterial3D = StandardMaterial3D.new()
var _label: Label3D = Label3D.new()


func _init() -> void:
	var capsule: CapsuleMesh = CapsuleMesh.new()
	capsule.radius = Sp2Constants.BODY_RADIUS_M
	capsule.height = Sp2Constants.BODY_HEIGHT_M
	capsule.radial_segments = 8
	capsule.rings = 2
	var body_mesh: MeshInstance3D = MeshInstance3D.new()
	body_mesh.mesh = capsule
	body_mesh.position.y = Sp2Constants.BODY_HEIGHT_M * 0.5
	body_mesh.material_override = _material
	add_child(body_mesh)
	var nose_box: BoxMesh = BoxMesh.new()
	nose_box.size = Vector3.ONE * Sp2Constants.NOSE_SIZE_M
	var nose: MeshInstance3D = MeshInstance3D.new()
	nose.mesh = nose_box
	# O nariz fica à frente (-Z local), na altura da cabeça: look_at aponta -Z para o destino.
	nose.position = Vector3(0.0, Sp2Constants.BODY_HEIGHT_M * 0.8, -Sp2Constants.BODY_RADIUS_M)
	add_child(nose)
	_label.font_size = Sp2Constants.LABEL_FONT_SIZE
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.position.y = Sp2Constants.LABEL_HEIGHT_M
	_label.visible = false
	add_child(_label)
	set_state(State.IDLE)


## Liga o corpo a um NPC (ao sair do pool).
func attach(new_npc_id: int, at: Vector3) -> void:
	npc_id = new_npc_id
	position = at
	last_reported = at
	has_reported = false
	clear_intent()
	_label.text = str(new_npc_id)
	visible = true


## Solta o NPC (ao voltar ao pool).
func detach() -> void:
	npc_id = 0
	clear_intent()
	visible = false


func clear_intent() -> void:
	action_serial = 0
	path = PackedVector2Array()
	path_index = 0
	set_state(State.IDLE)


func has_intent() -> bool:
	return action_serial != 0


func set_state(new_state: State) -> void:
	state = new_state
	var colors: Array[Color] = [Sp2Constants.COLOR_IDLE, Sp2Constants.COLOR_WALKING, Sp2Constants.COLOR_ACTING]
	_material.albedo_color = colors[new_state]


func show_number(is_shown: bool) -> void:
	_label.visible = is_shown


func flat_position() -> Vector2:
	return Vector2(position.x, position.z)


## Distância que falta até o fim do caminho (metros, no plano).
func remaining_m() -> float:
	if path_index >= path.size():
		return 0.0
	var total: float = flat_position().distance_to(path[path_index])
	for index: int in range(path_index, path.size() - 1):
		total += path[index].distance_to(path[index + 1])
	return total


## Anda `step_m` pelo caminho; a altura vem de `height_of` (x, z -> y). Devolve true quando chega ao fim do caminho.
func walk(step_m: float, height_of: Callable) -> bool:
	var left: float = step_m
	var flat: Vector2 = flat_position()
	while path_index < path.size() and left > 0.0:
		var target: Vector2 = path[path_index]
		var gap: float = flat.distance_to(target)
		if gap <= left:
			flat = target
			left -= gap
			path_index += 1
		else:
			flat = flat.move_toward(target, left)
			left = 0.0
	var next: Vector3 = Vector3(flat.x, float(height_of.call(flat)), flat.y)
	if path_index < path.size():
		var ahead: Vector3 = Vector3(path[path_index].x, next.y, path[path_index].y)
		if ahead.distance_to(next) > Sp2Constants.ARRIVE_TOLERANCE_M:
			look_at_from_position(next, ahead, Vector3.UP)
	position = next
	return path_index >= path.size()
