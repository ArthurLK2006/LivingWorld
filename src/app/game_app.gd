class_name GameAppNode
extends Node
## Script do autoload `GameApp` (arquitetura 4.3): ciclo de vida do aplicativo. Por enquanto
## inicia um mundo de desenvolvimento, monta o texto de estado e trata a tecla de pausa.
## Não guarda estado do mundo. A apresentação lê só o texto e o sinal daqui.

## Avisa quando o texto de estado muda (a apresentação só redesenha nesse caso).
signal status_changed(text: String)

## Provisórios até existirem a tela de novo jogo e o versionamento (Fase 0).
const DEFAULT_WORLD_SEED: int = 1
const GAME_VERSION: String = "0.0.1-dev"
const PAUSE_KEY: Key = KEY_SPACE

var _host: SimulationHostNode
var _last_status_text: String = ""


func _ready() -> void:
	var host: SimulationHostNode = get_node_or_null("/root/SimulationHost") as SimulationHostNode
	if host == null:
		push_error("GameApp: autoload SimulationHost não encontrado.")
		return
	bind_host(host)
	host.start_new_game(DEFAULT_WORLD_SEED)


func bind_host(host: SimulationHostNode) -> void:
	_host = host


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
