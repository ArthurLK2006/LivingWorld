extends Node3D
## Script da cena principal: entrega a ponte à TerrainView e à DecorationView, faz o PlayerBody nascer, informa o foco do terreno
## (a posição do PlayerBody; antes dele existir, a da câmera provisória; D1 de Arthur: direto, sem passar pela ponte) e posiciona
## a câmera provisória, que também é a referência de direção do PlayerBody até a LW-046. Sem regra de jogo.

## Câmera PROVISÓRIA até a LW-046 (câmera de jogo, DEC-115): fixa, acima do ponto de nascimento, olhando para
## leste ao longo do caminho. Alturas e ângulos são [HIP].
const CAMERA_HEIGHT_ABOVE_SPAWN_M: float = 25.0
const CAMERA_PITCH_DEGREES: float = -20.0
## Em Godot a câmera olha para -Z; girar -90° em Y a faz olhar para +X (leste).
const CAMERA_YAW_EAST_DEGREES: float = -90.0

## Árvores e pedras de blockout (LW-043): dados em data/world, só visuais.
const DECORATIONS_PATH: String = "res://data/world/decorations.json"

@onready var _terrain_view: TerrainView = $TerrainView
@onready var _decoration_view: DecorationView = $DecorationView
@onready var _camera: Camera3D = $Camera
@onready var _player: PlayerBody = $PlayerBody
## Só informa o foco depois de a TerrainView ter sido ligada a uma ponte.
var _is_terrain_ready: bool = false


func _ready() -> void:
	set_process(false)
	var app: GameAppNode = get_node_or_null("/root/GameApp") as GameAppNode
	if app == null:
		push_error("MainWorldView: autoload GameApp não encontrado; o terreno não será desenhado.")
		return
	var bridge: SimBridge = app.peek_bridge()
	_terrain_view.chunk_loaded.connect(_decoration_view.set_chunk_visible.bind(true))
	_terrain_view.chunk_unloaded.connect(_decoration_view.set_chunk_visible.bind(false))
	_terrain_view.setup(bridge)
	var decorations: DecorationReader.ReadResult = DecorationReader.read_file(DECORATIONS_PATH)
	if decorations.result.ok:
		_decoration_view.setup(bridge, decorations.items)
	else:
		push_error("MainWorldView: %s Nenhuma decoração será desenhada." % decorations.result.message)
	var spawn: SimBridge.SpawnReply = bridge.peek_spawn_point()
	if spawn.result.ok:
		_camera.position = spawn.point + Vector3(0.0, CAMERA_HEIGHT_ABOVE_SPAWN_M, 0.0)
		_camera.rotation_degrees = Vector3(CAMERA_PITCH_DEGREES, CAMERA_YAW_EAST_DEGREES, 0.0)
	_player.setup(bridge, _terrain_view, _camera)
	_terrain_view.set_focus(_focus_position())
	_is_terrain_ready = true
	set_process(true)


func _process(_delta: float) -> void:
	if _is_terrain_ready:
		_terrain_view.set_focus(_focus_position())


## De onde o terreno é carregado: do jogador, se ele nasceu; senão da câmera provisória.
func _focus_position() -> Vector3:
	return _player.global_position if _player.is_spawned() else _camera.position
