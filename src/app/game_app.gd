class_name GameAppNode
extends Node
## Script do autoload `GameApp` (arquitetura 4.3): ciclo de vida do aplicativo. Por enquanto
## inicia um mundo de desenvolvimento, monta o texto de estado, trata a tecla de pausa e cria e guarda a
## ponte com a apresentação (peek_bridge). Não guarda estado do mundo. A apresentação lê o texto e o sinal
## daqui e pede a ponte por aqui (decisão D1 de Arthur, 06/11/2026: sem autoload novo).

## Avisa quando o texto de estado muda (a apresentação só redesenha nesse caso).
signal status_changed(text: String)

## Provisórios até existirem a tela de novo jogo e o versionamento (Fase 0).
const DEFAULT_WORLD_SEED: int = 1
const GAME_VERSION: String = "0.0.1-dev"
const PAUSE_KEY: Key = KEY_SPACE
## Pasta dos arquivos de terreno lidos na primeira chamada de peek_bridge().
const TERRAIN_DIR: String = "res://data/world"

## Pasta lida por peek_bridge(). Pública só para o teste de falha trocá-la; mudar depois da primeira chamada
## não recarrega nada.
var terrain_dir: String = TERRAIN_DIR

var _host: SimulationHostNode
var _last_status_text: String = ""
var _bridge: SimBridge


func _ready() -> void:
	var host: SimulationHostNode = get_node_or_null("/root/SimulationHost") as SimulationHostNode
	if host == null:
		push_error("GameApp: autoload SimulationHost não encontrado.")
		return
	bind_host(host)
	host.start_new_game(DEFAULT_WORLD_SEED)


func bind_host(host: SimulationHostNode) -> void:
	_host = host


## Ponte da apresentação com a simulação. PREGUIÇOSA de propósito: só na primeira chamada lê o terreno (arquivo
## de cerca de 2,3 MB) e cria a ponte com o host já ligado; as chamadas seguintes devolvem a MESMA instância.
## Quem nunca a pede (testes, tools/run_sim) não paga a leitura. Terreno que não carrega não derruba o jogo:
## push_error com o motivo e ponte sem terreno, cujas consultas falham com BRIDGE_NO_TERRAIN.
func peek_bridge() -> SimBridge:
	if _bridge == null:
		_bridge = SimBridge.new(_host, _load_terrain())
	return _bridge


## Terreno de terrain_dir, ou nulo (depois de push_error) se não carregar. Sem `quit`: o GameApp também roda
## dentro de testes e ferramentas.
func _load_terrain() -> TerrainData:
	var loaded: TerrainLoader.LoadResult = TerrainLoader.load_dir(terrain_dir)
	if not loaded.result.ok:
		push_error("GameApp.peek_bridge: terreno não carregado de '%s': %s" % [terrain_dir, loaded.result.message])
		return null
	return loaded.terrain


## Texto de estado para a tela: título, versão, data simulada, velocidade ou pausa e a tecla.
func status_text() -> String:
	if _host == null or _host.runner == null:
		return ""
	var clock: SimClock = _host.runner.world.context.clock
	var pace: String = "PAUSADO" if clock.is_paused() else "%dx" % clock.get_speed()
	var title: String = str(ProjectSettings.get_setting("application/config/name", "Living World"))
	return "%s · versão %s\nData simulada: %s · %s\n[Espaço] pausar ou continuar" % [title, GAME_VERSION, _host.runner.format_clock_line(), pace]


func toggle_pause() -> void:
	if _host == null or _host.runner == null:
		return
	var clock: SimClock = _host.runner.world.context.clock
	clock.set_paused(not clock.is_paused())


func _process(_delta: float) -> void:
	var text: String = status_text()
	if text != _last_status_text:
		_last_status_text = text
		status_changed.emit(text)


## Trata a tecla de pausa; devolve verdadeiro se o evento era dela e foi consumido.
func handle_key(event: InputEvent) -> bool:
	var key_event: InputEventKey = event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo or key_event.keycode != PAUSE_KEY:
		return false
	toggle_pause()
	return true


func _unhandled_input(event: InputEvent) -> void:
	if handle_key(event):
		get_viewport().set_input_as_handled()
