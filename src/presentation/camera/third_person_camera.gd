class_name ThirdPersonCamera
extends Camera3D
## Câmera de terceira pessoa ELEVADA (LW-046; DEC-115, APROVADA): a câmera única do jogo, que gira 360° em volta do jogador e tem
## zoom. Olha para um ponto de mira acima dos pés do alvo, de uma distância e de um ângulo para baixo [HIP]. Controles da decisão
## D3 de Arthur: botão direito do mouse arrastado gira, roda dá zoom, setas giram; o cursor fica livre. A posição seguida é
## atualizada no quadro de FÍSICA, junto com o alvo, para a cápsula não tremer na tela quando os relógios da física e dos quadros
## diferem; ângulos e zoom suavizam a cada quadro. Colisão com o terreno SEM física, por peek_height: a câmera nunca fica abaixo do
## terreno mais uma folga e o terreno nunca fica entre ela e o alvo (a altura da ponte é exata e não depende de a colisão já
## existir). Só apresentação: nada é salvo. Contrato: docs/modules/presentation.md.

## Valores [HIP], calibrados olhando a tela. Ângulos em graus e distâncias em metros.
const DEFAULT_DISTANCE_M: float = 12.0
const MIN_DISTANCE_M: float = 4.0
const MAX_DISTANCE_M: float = 40.0
## Ângulo PARA BAIXO com que a câmera olha o alvo (0 = horizontal, 90 = de cima).
const DEFAULT_PITCH_DEGREES: float = 35.0
const MIN_PITCH_DEGREES: float = 10.0
const MAX_PITCH_DEGREES: float = 75.0
## Em Godot a câmera olha para -Z; girar -90° em Y a faz olhar para +X (leste, ao longo do caminho).
const DEFAULT_YAW_DEGREES: float = -90.0
## Altura do ponto de mira acima dos pés do alvo.
const AIM_HEIGHT_M: float = 1.5
## Cada clique da roda multiplica ou divide a distância por este fator.
const ZOOM_STEP_FACTOR: float = 1.15
const ORBIT_DEGREES_PER_PIXEL: float = 0.25
const LOOK_KEY_DEGREES_PER_SECOND: float = 90.0
## Constantes de tempo (s) das suavizações exponenciais.
const FOLLOW_TIME_S: float = 0.10
const TURN_TIME_S: float = 0.05
const ARM_RECOVER_TIME_S: float = 0.25
## Terreno: folga mínima entre a câmera e o chão, passo da busca ao longo do braço, refinos por bisseção e braço mínimo.
const GROUND_MARGIN_M: float = 0.5
const ARM_STEP_M: float = 1.0
const ARM_REFINE_STEPS: int = 4
const MIN_ARM_M: float = 1.0

## Valores desejados pelo jogador (a câmera mostra versões suavizadas deles). Públicos para os testes e para a cena.
var yaw_rad: float = deg_to_rad(DEFAULT_YAW_DEGREES)
var pitch_rad: float = deg_to_rad(DEFAULT_PITCH_DEGREES)
var distance_m: float = DEFAULT_DISTANCE_M

var _bridge: SimBridge
var _target: Node3D
var _map_size_m: Vector2 = Vector2.ZERO
var _is_following: bool = false
var _follow_m: Vector3 = Vector3.ZERO
var _yaw_shown: float = 0.0
var _pitch_shown: float = 0.0
var _distance_shown: float = 0.0
var _arm_m: float = 0.0
var _has_reported_height_error: bool = false


func _ready() -> void:
	set_process(false)
	set_physics_process(false)


## Liga a câmera à ponte (alturas) e ao nó a seguir, volta aos valores padrão e a põe no lugar na hora. O nó precisa estar na árvore.
## Ponte nula, sem terreno, alvo nulo ou câmera fora da árvore: push_error e a câmera fica onde está. Devolve se passou a seguir.
func setup(bridge: SimBridge, target: Node3D) -> bool:
	_is_following = false
	set_process(false)
	set_physics_process(false)
	if bridge == null:
		push_error("ThirdPersonCamera.setup: ponte nula; esperado uma SimBridge.")
		return false
	if target == null:
		push_error("ThirdPersonCamera.setup: alvo nulo; esperado o nó a seguir.")
		return false
	if not is_inside_tree():
		push_error("ThirdPersonCamera.setup: a câmera precisa estar na árvore de cena antes do setup.")
		return false
	var layout: SimBridge.TerrainLayoutReply = bridge.peek_terrain_layout()
	if not layout.result.ok:
		push_error("ThirdPersonCamera.setup: formato do terreno indisponível (%s): %s" % [layout.result.code, layout.result.message])
		return false
	_bridge = bridge
	_target = target
	_map_size_m = layout.size_m
	yaw_rad = deg_to_rad(DEFAULT_YAW_DEGREES)
	pitch_rad = deg_to_rad(DEFAULT_PITCH_DEGREES)
	distance_m = DEFAULT_DISTANCE_M
	_yaw_shown = yaw_rad
	_pitch_shown = pitch_rad
	_distance_shown = distance_m
	_arm_m = distance_m
	_follow_m = target.global_position
	_is_following = true
	view_step(0.0)
	set_process(true)
	set_physics_process(true)
	return true


func is_following() -> bool:
	return _is_following


## Gira os valores desejados (radianos): o giro dá a volta completa; a inclinação fica entre os limites.
func orbit_by(yaw_delta_rad: float, pitch_delta_rad: float) -> void:
	yaw_rad = wrapf(yaw_rad + yaw_delta_rad, -PI, PI)
	pitch_rad = clampf(pitch_rad + pitch_delta_rad, deg_to_rad(MIN_PITCH_DEGREES), deg_to_rad(MAX_PITCH_DEGREES))


## Zoom em cliques da roda: positivo aproxima, negativo afasta; a distância fica entre os limites.
func zoom_by(notches: float) -> void:
	distance_m = clampf(distance_m * pow(ZOOM_STEP_FACTOR, -notches), MIN_DISTANCE_M, MAX_DISTANCE_M)


## Um passo da posição seguida (a cada quadro de física, depois de o alvo andar): ela alcança o alvo aos poucos.
func follow_step(delta: float) -> void:
	if not _is_following:
		return
	_follow_m = _follow_m.lerp(_target.global_position, _smoothing(delta, FOLLOW_TIME_S))


## Um passo da imagem (a cada quadro): setas, suavização de ângulos e zoom, braço contra o terreno e a posição e o giro da câmera.
func view_step(delta: float) -> void:
	if not _is_following:
		return
	_read_look_keys(delta)
	var turn: float = _smoothing(delta, TURN_TIME_S)
	_yaw_shown = lerp_angle(_yaw_shown, yaw_rad, turn)
	_pitch_shown = lerpf(_pitch_shown, pitch_rad, turn)
	_distance_shown = lerpf(_distance_shown, distance_m, turn)
	var aim_m: Vector3 = _follow_m + Vector3(0.0, AIM_HEIGHT_M, 0.0)
	var direction: Vector3 = _arm_direction(_yaw_shown, _pitch_shown)
	var free_length_m: float = _free_arm_length(aim_m, direction, _distance_shown)
	# Encurta na hora (nunca entra no terreno) e volta aos poucos quando o caminho libera.
	_arm_m = free_length_m if free_length_m < _arm_m else lerpf(_arm_m, free_length_m, _smoothing(delta, ARM_RECOVER_TIME_S))
	var camera_m: Vector3 = aim_m + direction * _arm_m
	camera_m.y = maxf(camera_m.y, _ground_at(camera_m) + GROUND_MARGIN_M)
	global_position = camera_m
	global_rotation = Vector3(-_pitch_shown, _yaw_shown, 0.0)


func _physics_process(delta: float) -> void:
	follow_step(delta)


func _process(delta: float) -> void:
	view_step(delta)


func _unhandled_input(event: InputEvent) -> void:
	if not _is_following:
		return
	var motion: InputEventMouseMotion = event as InputEventMouseMotion
	if motion != null:
		if Input.is_action_pressed(InputActions.CAMERA_ORBIT):
			var radians_per_pixel: float = deg_to_rad(ORBIT_DEGREES_PER_PIXEL)
			orbit_by(-motion.relative.x * radians_per_pixel, motion.relative.y * radians_per_pixel)
		return
	if event.is_action_pressed(InputActions.ZOOM_IN):
		zoom_by(1.0)
	elif event.is_action_pressed(InputActions.ZOOM_OUT):
		zoom_by(-1.0)


## Suavização exponencial que não depende da taxa de quadros: fração do caminho percorrida em `delta` segundos.
func _smoothing(delta: float, time_s: float) -> float:
	return 1.0 - exp(-delta / time_s)


## Setas: esquerda soma ao giro (em Godot, girar para a esquerda é positivo) e para baixo aumenta a inclinação.
func _read_look_keys(delta: float) -> void:
	var yaw_axis: float = Input.get_axis(InputActions.LOOK_RIGHT, InputActions.LOOK_LEFT)
	var pitch_axis: float = Input.get_axis(InputActions.LOOK_UP, InputActions.LOOK_DOWN)
	if yaw_axis != 0.0 or pitch_axis != 0.0:
		var step_rad: float = deg_to_rad(LOOK_KEY_DEGREES_PER_SECOND) * delta
		orbit_by(yaw_axis * step_rad, pitch_axis * step_rad)


## Vetor unitário do ponto de mira até a câmera: atrás (oposto ao que a câmera olha) e acima.
func _arm_direction(yaw: float, pitch: float) -> Vector3:
	return Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch))


## Maior comprimento do braço, até `length_m`, sem que ele entre no terreno (mais a folga). Busca de metro em metro e refina o
## primeiro trecho bloqueado por bisseção.
func _free_arm_length(aim_m: Vector3, direction: Vector3, length_m: float) -> float:
	var free_m: float = 0.0
	var steps: int = ceili(length_m / ARM_STEP_M)
	for index: int in range(1, steps + 1):
		var probe_m: float = minf(float(index) * ARM_STEP_M, length_m)
		if not _is_blocked(aim_m + direction * probe_m):
			free_m = probe_m
			continue
		var blocked_m: float = probe_m
		for _refine: int in range(ARM_REFINE_STEPS):
			var middle_m: float = (free_m + blocked_m) * 0.5
			if _is_blocked(aim_m + direction * middle_m):
				blocked_m = middle_m
			else:
				free_m = middle_m
		return maxf(free_m, minf(MIN_ARM_M, length_m))
	return length_m


func _is_blocked(point_m: Vector3) -> bool:
	return point_m.y < _ground_at(point_m) + GROUND_MARGIN_M


## Altura do terreno sob o ponto; fora do mapa vale a da borda mais próxima (a câmera pode ficar além da borda).
func _ground_at(point_m: Vector3) -> float:
	var reply: SimBridge.HeightReply = _bridge.peek_height(clampf(point_m.x, 0.0, _map_size_m.x), clampf(point_m.z, 0.0, _map_size_m.y))
	if reply.result.ok:
		return reply.height_m
	if not _has_reported_height_error:
		_has_reported_height_error = true
		push_error("ThirdPersonCamera: altura indisponível em (x=%s, z=%s): %s" % [str(point_m.x), str(point_m.z), reply.result.message])
	return -INF
