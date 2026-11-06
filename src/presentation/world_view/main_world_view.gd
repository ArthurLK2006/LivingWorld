extends Node3D
## Script da cena principal: entrega a ponte à TerrainView e à DecorationView, faz o PlayerBody nascer, liga a câmera de terceira
## pessoa ao jogador (e o jogador à câmera, que é a referência de direção dele) e informa o foco do terreno: a posição do
## PlayerBody; se ele não nascer, a da câmera, que fica onde a cena a pôs (D1 de Arthur: direto, sem passar pela ponte).
## Sem regra de jogo.

## Árvores e pedras de blockout (LW-043): dados em data/world, só visuais.
const DECORATIONS_PATH: String = "res://data/world/decorations.json"

@onready var _terrain_view: TerrainView = $TerrainView
@onready var _decoration_view: DecorationView = $DecorationView
@onready var _camera: ThirdPersonCamera = $Camera
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
	if _player.setup(bridge, _terrain_view, _camera):
		_camera.setup(bridge, _player)
	_terrain_view.set_focus(_focus_position())
	_is_terrain_ready = true
	set_process(true)


func _process(_delta: float) -> void:
	if _is_terrain_ready:
		_terrain_view.set_focus(_focus_position())


## De onde o terreno é carregado: do jogador, se ele nasceu; senão da câmera, que ficou onde a cena a pôs.
func _focus_position() -> Vector3:
	return _player.global_position if _player.is_spawned() else _camera.position
