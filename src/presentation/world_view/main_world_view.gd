extends Node3D
## Script da cena principal: entrega a ponte à TerrainView e à DecorationView, faz o PlayerBody nascer, liga a câmera de terceira
## pessoa ao jogador (e o jogador à câmera, que é a referência de direção dele) e informa o foco do terreno: a posição do
## PlayerBody; se ele não nascer, a da câmera, que fica onde a cena a pôs (D1 de Arthur: direto, sem passar pela ponte). Carrega os
## textos de jogo (UiText) e os entrega ao HUD (LW-051) e à InteractionView (LW-050). Sem regra de jogo.

## Árvores e pedras de blockout (LW-043): dados em data/world, só visuais.
const DECORATIONS_PATH: String = "res://data/world/decorations.json"
## Configuração do projeto de onde vem o título do jogo mostrado no HUD.
const GAME_NAME_SETTING: String = "application/config/name"
const PLACE_VIEW_NAME: String = "PlaceBoxesView"

@onready var _terrain_view: TerrainView = $TerrainView
@onready var _decoration_view: DecorationView = $DecorationView
@onready var _camera: ThirdPersonCamera = $Camera
@onready var _player: PlayerBody = $PlayerBody
@onready var _hud: HudView = $HUD/StatusLabel
@onready var _interaction_view: InteractionView = $InteractionView
@onready var _prompt_label: Label = $HUD/InteractionPrompt
@onready var _result_label: Label = $HUD/InteractionText
## As caixas provisórias dos locais (LW-074), criadas aqui em código: acompanham o terreno como a decoração.
var _place_view: PlaceBoxesView
## Os textos de jogo, guardados aqui para viverem tanto quanto a cena.
var _texts: UiText
## Só informa o foco depois de a TerrainView ter sido ligada a uma ponte.
var _is_terrain_ready: bool = false


func _ready() -> void:
	set_process(false)
	var app: GameAppNode = get_node_or_null("/root/GameApp") as GameAppNode
	if app == null:
		push_error("MainWorldView: autoload GameApp não encontrado; o terreno não será desenhado.")
		return
	_texts = _load_texts()
	var bridge: SimBridge = app.peek_bridge()
	_hud.setup(bridge, _texts, str(ProjectSettings.get_setting(GAME_NAME_SETTING, "")), GameAppNode.GAME_VERSION)
	_terrain_view.chunk_loaded.connect(_decoration_view.set_chunk_visible.bind(true))
	_terrain_view.chunk_unloaded.connect(_decoration_view.set_chunk_visible.bind(false))
	_place_view = PlaceBoxesView.new()
	_place_view.name = PLACE_VIEW_NAME
	add_child(_place_view)
	_place_view.setup(bridge)
	_terrain_view.chunk_loaded.connect(_place_view.set_chunk_visible.bind(true))
	_terrain_view.chunk_unloaded.connect(_place_view.set_chunk_visible.bind(false))
	_terrain_view.setup(bridge)
	var decorations: DecorationReader.ReadResult = DecorationReader.read_file(DECORATIONS_PATH)
	if decorations.result.ok:
		_decoration_view.setup(bridge, decorations.items)
	else:
		push_error("MainWorldView: %s Nenhuma decoração será desenhada." % decorations.result.message)
	if _player.setup(bridge, _terrain_view, _camera):
		_camera.setup(bridge, _player)
		_interaction_view.setup(bridge, _player, _terrain_view, _texts, _prompt_label, _result_label)
	_terrain_view.set_focus(_focus_position())
	_is_terrain_ready = true
	set_process(true)


## Textos de data/text/pt_br.json. Arquivo inválido: push_error com arquivo e chave e textos vazios (cada chave aparece como [chave]).
func _load_texts() -> UiText:
	var loaded: UiText.LoadResult = UiText.from_file(UiText.DEFAULT_PATH)
	if not loaded.result.ok:
		push_error("MainWorldView: %s Os textos aparecerão como [chave]." % loaded.result.message)
	return loaded.texts


func _process(_delta: float) -> void:
	if _is_terrain_ready:
		_terrain_view.set_focus(_focus_position())


## De onde o terreno é carregado: do jogador, se ele nasceu; senão da câmera, que ficou onde a cena a pôs.
func _focus_position() -> Vector3:
	return _player.global_position if _player.is_spawned() else _camera.position
