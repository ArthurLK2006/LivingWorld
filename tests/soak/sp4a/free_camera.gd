class_name Sp4aFreeCamera
extends Camera3D
## SPIKE descartável (LW-033/SP4a). Câmera livre: usada pelo "modo ver" (interativa, teclado e
## mouse) e pelos cenários scriptados (a posição é escrita direto por scenario_runner.gd; o modo
## interativo fica desligado nesses casos). Sem regra de jogo: é só uma ferramenta de medição.

const MOVE_SPEED: float = 20.0  ## [HIP] m/s, só para o "modo ver"
const VERTICAL_SPEED: float = 15.0  ## [HIP]
const MOUSE_SENSITIVITY: float = 0.0025  ## [HIP]

var interactive: bool = false
var _yaw: float = 0.0
var _pitch: float = 0.0


func _unhandled_input(event: InputEvent) -> void:
	if not interactive:
		return
	var motion: InputEventMouseMotion = event as InputEventMouseMotion
	if motion != null and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_yaw -= motion.relative.x * MOUSE_SENSITIVITY
		_pitch = clampf(_pitch - motion.relative.y * MOUSE_SENSITIVITY, -1.5, 1.5)
		rotation = Vector3(_pitch, _yaw, 0.0)
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button != null and button.pressed and button.button_index == MOUSE_BUTTON_LEFT:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var key: InputEventKey = event as InputEventKey
	if key != null and key.pressed and key.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _process(delta: float) -> void:
	if not interactive:
		return
	var direction: Vector3 = Vector3.ZERO
	if Input.is_key_pressed(KEY_W):
		direction -= transform.basis.z
	if Input.is_key_pressed(KEY_S):
		direction += transform.basis.z
	if Input.is_key_pressed(KEY_A):
		direction -= transform.basis.x
	if Input.is_key_pressed(KEY_D):
		direction += transform.basis.x
	if Input.is_key_pressed(KEY_E):
		direction += Vector3.UP
	if Input.is_key_pressed(KEY_Q):
		direction -= Vector3.UP
	if direction.length_squared() > 0.0:
		position += direction.normalized() * MOVE_SPEED * delta
