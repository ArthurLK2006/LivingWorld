extends Node3D
## Script da cena principal: entrega a ponte à TerrainView e posiciona a câmera provisória. Sem regra de jogo.

## Câmera PROVISÓRIA até a LW-046 (câmera de jogo, DEC-115): fixa, acima do ponto de nascimento, olhando para
## leste ao longo do caminho. Alturas e ângulos são [HIP].
const CAMERA_HEIGHT_ABOVE_SPAWN_M: float = 25.0
const CAMERA_PITCH_DEGREES: float = -20.0
## Em Godot a câmera olha para -Z; girar -90° em Y a faz olhar para +X (leste).
const CAMERA_YAW_EAST_DEGREES: float = -90.0

@onready var _terrain_view: TerrainView = $TerrainView
@onready var _camera: Camera3D = $Camera


func _ready() -> void:
	var app: GameAppNode = get_node_or_null("/root/GameApp") as GameAppNode
	if app == null:
		push_error("MainWorldView: autoload GameApp não encontrado; o terreno não será desenhado.")
		return
	var bridge: SimBridge = app.peek_bridge()
	_terrain_view.setup(bridge)
	var spawn: SimBridge.SpawnReply = bridge.peek_spawn_point()
	if spawn.result.ok:
		_camera.position = spawn.point + Vector3(0.0, CAMERA_HEIGHT_ABOVE_SPAWN_M, 0.0)
		_camera.rotation_degrees = Vector3(CAMERA_PITCH_DEGREES, CAMERA_YAW_EAST_DEGREES, 0.0)
