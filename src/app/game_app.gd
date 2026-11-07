class_name GameAppNode
extends Node
## Script do autoload `GameApp` (arquitetura 4.3): ciclo de vida do aplicativo. Por enquanto
## inicia um mundo de desenvolvimento (com o terreno lido e os módulos do jogo, LW-048), monta o texto de estado, trata a ação de
## pausa e cria e guarda a ponte com a apresentação (peek_bridge). Não guarda estado do mundo. A apresentação lê o texto e o sinal
## daqui e pede a ponte por aqui (decisão D1 de Arthur, 06/11/2026: sem autoload novo).

## Avisa quando o texto de estado muda (a apresentação só redesenha nesse caso).
signal status_changed(text: String)

## Provisórios até existirem a tela de novo jogo e o versionamento (Fase 0).
const DEFAULT_WORLD_SEED: int = 1
const GAME_VERSION: String = "0.0.1-dev"
## Chaves de texto da linha de status (as frases moram em data/text/pt_br.json).
const KEY_TITLE: String = "ui.status_title"
const KEY_CLOCK: String = "ui.status_clock"
const KEY_DATE: String = "ui.status_date"
const KEY_PAUSE_HINT: String = "ui.status_pause_hint"
const KEY_PACE_PAUSED: String = "ui.pace_paused"
const KEY_PACE_SPEED: String = "ui.pace_speed"
## Pasta dos arquivos de terreno lidos na primeira chamada de peek_bridge().
const TERRAIN_DIR: String = "res://data/world"

## Pasta lida por peek_bridge(). Pública só para o teste de falha trocá-la; mudar depois da primeira chamada
## não recarrega nada.
var terrain_dir: String = TERRAIN_DIR

## Resolve uma chave de texto (e seus valores {nome}) em frase, para a linha de status (LW-050). Quem o define é a apresentação, dona dos
## textos (UiText); o app não cita a classe dela (camadas). Sem ele, a linha mostra as próprias chaves. Um Callable não segura o objeto
## vivo: quem define o provider precisa guardar o UiText numa variável própria.
var text_provider: Callable = Callable():
	set(value):
		text_provider = value
		# Texto novo à vista: o próximo quadro reemite o estado, mesmo que o texto por extenso coincida com o último emitido (quem
		# ouve pode ter nascido com um provider antigo, já liberado, e estar mostrando chaves).
		_last_status_text = ""

var _host: SimulationHostNode
var _last_status_text: String = ""
var _bridge: SimBridge
## Terreno lido uma vez só (no _ready do jogo ou na primeira peek_bridge dos testes); nulo se não carregou.
var _terrain: TerrainData
var _is_terrain_loaded: bool = false


func _ready() -> void:
	var host: SimulationHostNode = get_node_or_null("/root/SimulationHost") as SimulationHostNode
	if host == null:
		push_error("GameApp: autoload SimulationHost não encontrado.")
		return
	bind_host(host)
	host.start_new_game(DEFAULT_WORLD_SEED, _terrain_or_load(), _load_points())


func bind_host(host: SimulationHostNode) -> void:
	_host = host


## Ponte da apresentação com a simulação: cria a ponte com o host já ligado e o MESMO terreno que o mundo do jogo usa; as chamadas
## seguintes devolvem a MESMA instância. O terreno (arquivo de cerca de 2,3 MB, cerca de 0,45 s para ler) é lido uma só vez: no
## _ready do autoload, porque o módulo do personagem precisa dele antes de o jogo começar (LW-048), ou aqui, na primeira chamada,
## quando o GameApp é criado à mão (testes). Terreno que não carrega não derruba o jogo: push_error com o motivo e ponte sem terreno,
## cujas consultas falham com BRIDGE_NO_TERRAIN.
func peek_bridge() -> SimBridge:
	if _bridge == null:
		_bridge = SimBridge.new(_host, _terrain_or_load())
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


## Terreno de terrain_dir, ou nulo (depois de push_error) se não carregar. Sem `quit`: o GameApp também roda
## dentro de testes e ferramentas.
func _load_terrain() -> TerrainData:
	var loaded: TerrainLoader.LoadResult = TerrainLoader.load_dir(terrain_dir)
	if not loaded.result.ok:
		push_error("GameApp.peek_bridge: terreno não carregado de '%s': %s" % [terrain_dir, loaded.result.message])
		return null
	return loaded.terrain


## Texto de estado para a tela: título, versão, data simulada, velocidade ou pausa e a tecla da ação de pausa. As frases vêm de chaves
## (data/text/pt_br.json) pelo `text_provider`; este código não tem texto de tela. A LW-051 troca esta linha pelo HUD.
func status_text() -> String:
	if _host == null or _host.runner == null:
		return ""
	var clock: SimClock = _host.runner.world.context.clock
	var pace: String = _text(KEY_PACE_PAUSED) if clock.is_paused() else _text(KEY_PACE_SPEED, {"speed": clock.get_speed()})
	var date: String = _text(KEY_DATE, {"year": clock.year(), "day": clock.day_of_year(), "hour": "%02d" % clock.hour_of_day(), "minute": "%02d" % clock.minute_of_hour()})
	var title: String = str(ProjectSettings.get_setting("application/config/name", ""))
	var lines: PackedStringArray = PackedStringArray([
		_text(KEY_TITLE, {"title": title, "version": GAME_VERSION}),
		_text(KEY_CLOCK, {"date": date, "pace": pace}),
		_text(KEY_PAUSE_HINT, {"key": _pause_key_label()}),
	])
	return "\n".join(lines)


## Frase da chave pelo provider; sem provider, a própria chave.
func _text(key: String, values: Dictionary = {}) -> String:
	if text_provider.is_valid():
		return str(text_provider.call(key, values))
	return key


func toggle_pause() -> void:
	if _host == null or _host.runner == null:
		return
	var clock: SimClock = _host.runner.world.context.clock
	var outcome: Result = _host.request_pause(not clock.is_paused())
	if not outcome.ok:
		push_error("GameApp.toggle_pause: %s" % outcome.message)


func _process(_delta: float) -> void:
	var text: String = status_text()
	if text != _last_status_text:
		_last_status_text = text
		status_changed.emit(text)


## Trata a AÇÃO de pausa (InputActions.PAUSE, tecla no project.godot); sem tecla fixa. Devolve verdadeiro se o evento
## era dela e foi consumido. O nome é histórico: vale para qualquer evento que o InputMap ligue à ação. Repetição não conta.
func handle_key(event: InputEvent) -> bool:
	if not event.is_action_pressed(InputActions.PAUSE):
		return false
	toggle_pause()
	return true


## Tecla da ação de pausa para a dica da tela, lida do InputMap (primeira palavra do texto do evento, ex.: "P").
func _pause_key_label() -> String:
	var events: Array[InputEvent] = InputMap.action_get_events(InputActions.PAUSE)
	return events[0].as_text().get_slice(" ", 0) if not events.is_empty() else "?"


func _unhandled_input(event: InputEvent) -> void:
	if handle_key(event):
		get_viewport().set_input_as_handled()
