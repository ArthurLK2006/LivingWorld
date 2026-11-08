class_name GameAppNode
extends Node
## Script do autoload `GameApp` (arquitetura 4.3): ciclo de vida do aplicativo. Por enquanto
## inicia um mundo de desenvolvimento (com o terreno lido e os módulos do jogo, LW-048), trata a ação de pausa e cria e guarda a ponte
## com a apresentação (peek_bridge). Não guarda estado do mundo. A apresentação pede a ponte por aqui (decisão D1 de Arthur,
## 06/11/2026: sem autoload novo). O texto de estado da tela saiu na LW-051: o HUD (presentation) lê a hora e o ritmo pela ponte.

## Provisórios até existirem a tela de novo jogo e o versionamento (Fase 0).
const DEFAULT_WORLD_SEED: int = 1
const GAME_VERSION: String = "0.0.1-dev"
## Pasta dos arquivos de terreno lidos na primeira chamada de peek_bridge().
const TERRAIN_DIR: String = "res://data/world"
## Pasta dos arquivos de dados do `npc` (necessidades, ações, ofícios, parâmetros, provisórios e população), lida no `_ready` (LW-067).
const NPC_DATA_DIR: String = "res://data"

## Pasta lida por peek_bridge(). Pública só para o teste de falha trocá-la; mudar depois da primeira chamada
## não recarrega nada.
var terrain_dir: String = TERRAIN_DIR

var _host: SimulationHostNode
var _bridge: SimBridge
## Terreno lido uma vez só (no _ready do jogo ou na primeira peek_bridge dos testes); nulo se não carregou.
var _terrain: TerrainData
var _is_terrain_loaded: bool = false
## Locais dos assentamentos (LW-074), lidos no `_ready` do autoload e entregues à ponte; vazio num GameApp criado à mão (testes).
var _places: Array[Place] = []
## Assentamentos lidos junto com os locais; o `npc` (LW-067) monta com eles o serviço de consultas do `world`.
var _settlements: Array[Settlement] = []


func _ready() -> void:
	var host: SimulationHostNode = get_node_or_null("/root/SimulationHost") as SimulationHostNode
	if host == null:
		push_error("GameApp: autoload SimulationHost não encontrado.")
		return
	bind_host(host)
	_places = _load_places()
	host.start_new_game(DEFAULT_WORLD_SEED, _terrain_or_load(), _load_points(), _load_npc_setup())


func bind_host(host: SimulationHostNode) -> void:
	_host = host


## Ponte da apresentação com a simulação: cria a ponte com o host já ligado e o MESMO terreno que o mundo do jogo usa; as chamadas
## seguintes devolvem a MESMA instância. O terreno (arquivo de cerca de 2,3 MB, cerca de 0,45 s para ler) é lido uma só vez: no
## _ready do autoload, porque o módulo do personagem precisa dele antes de o jogo começar (LW-048), ou aqui, na primeira chamada,
## quando o GameApp é criado à mão (testes). Terreno que não carrega não derruba o jogo: push_error com o motivo e ponte sem terreno,
## cujas consultas falham com BRIDGE_NO_TERRAIN.
func peek_bridge() -> SimBridge:
	if _bridge == null:
		_bridge = SimBridge.new(_host, _terrain_or_load(), _places)
	return _bridge


## Lê o terreno na primeira chamada e guarda o resultado (inclusive a falha, para o erro aparecer uma vez só).
func _terrain_or_load() -> TerrainData:
	if not _is_terrain_loaded:
		_is_terrain_loaded = true
		_terrain = _load_terrain()
	return _terrain


## Pontos de interesse de terrain_dir (LW-049), conferidos contra o mapa do terreno já lido; lista vazia (depois de push_error) se o arquivo
## não carregar ou se não houver terreno: o jogo segue, sem pontos para interagir.
func _load_points() -> Array[PointOfInterest]:
	var terrain: TerrainData = _terrain_or_load()
	if terrain == null:
		return []
	var loaded: PointOfInterestLoader.LoadResult = PointOfInterestLoader.load_dir(terrain_dir, terrain)
	if not loaded.result.ok:
		push_error("GameApp: pontos de interesse não carregados de '%s': %s" % [terrain_dir, loaded.result.message])
		return []
	return loaded.points


## Locais dos assentamentos de terrain_dir (LW-074); lista vazia (depois de push_error) se não carregarem ou se não houver terreno.
func _load_places() -> Array[Place]:
	var terrain: TerrainData = _terrain_or_load()
	if terrain == null:
		return []
	var loaded: SettlementLoader.LoadResult = SettlementLoader.load_dir(terrain_dir, terrain)
	if not loaded.result.ok:
		push_error("GameApp: assentamentos e locais não carregados de '%s': %s" % [terrain_dir, loaded.result.message])
		return []
	_settlements = loaded.settlements
	return loaded.places


## Dados do `npc` de NPC_DATA_DIR (LW-067), com o serviço de locais montado dos assentamentos já lidos; nulo (depois de push_error) se não
## carregarem, e o jogo segue sem NPCs. Sem assentamentos e locais (não carregaram, e o motivo já foi registrado) não há onde pôr NPCs:
## nulo, sem erro novo.
func _load_npc_setup() -> NpcSetup:
	if _settlements.is_empty() or _places.is_empty():
		return null
	var setup: NpcSetup = NpcSetup.from_dir(NPC_DATA_DIR, SettlementService.new(_settlements, _places), OS.is_debug_build())
	if not setup.result.ok:
		push_error("GameApp: dados do npc não carregados de '%s': %s" % [NPC_DATA_DIR, setup.result.message])
		return null
	return setup


## Terreno de terrain_dir, ou nulo (depois de push_error) se não carregar. Sem `quit`: o GameApp também roda
## dentro de testes e ferramentas.
func _load_terrain() -> TerrainData:
	var loaded: TerrainLoader.LoadResult = TerrainLoader.load_dir(terrain_dir)
	if not loaded.result.ok:
		push_error("GameApp.peek_bridge: terreno não carregado de '%s': %s" % [terrain_dir, loaded.result.message])
		return null
	return loaded.terrain


func toggle_pause() -> void:
	if _host == null or _host.runner == null:
		return
	var clock: SimClock = _host.runner.world.context.clock
	var outcome: Result = _host.request_pause(not clock.is_paused())
	if not outcome.ok:
		push_error("GameApp.toggle_pause: %s" % outcome.message)


## Trata a AÇÃO de pausa (InputActions.PAUSE, tecla no project.godot); sem tecla fixa. Devolve verdadeiro se o evento
## era dela e foi consumido. O nome é histórico: vale para qualquer evento que o InputMap ligue à ação. Repetição não conta.
func handle_key(event: InputEvent) -> bool:
	if not event.is_action_pressed(InputActions.PAUSE):
		return false
	toggle_pause()
	return true


func _unhandled_input(event: InputEvent) -> void:
	if handle_key(event):
		get_viewport().set_input_as_handled()
