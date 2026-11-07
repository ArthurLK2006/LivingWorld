class_name HudView
extends Label
## HUD mínimo (LW-051): título e versão do jogo, data e hora simuladas, indicador de PAUSA ou de velocidade (1x e 2x) e a dica da tecla de
## pausa. Lê SÓ a ponte (`peek_time`, uma CÓPIA da hora e do ritmo: o ViewModel); nenhuma regra de jogo mora aqui e todo texto vem de
## chaves de data/text/pt_br.json (UiText). Só reescreve o texto quando algo muda (minuto simulado, pausa ou velocidade). Trata as ações de
## velocidade (`speed_normal` e `speed_double`) pedindo `request_speed` pela ponte; a ação de pausa continua tratada pelo GameApp. Ele
## SUBSTITUI a linha provisória de status (LW-021) que o GameApp montava. Contrato: docs/modules/presentation.md.

## Velocidades que a tela oferece [HIP]; o relógio aceita de 1 a 8, a tela só 1x e 2x.
const SPEED_NORMAL: int = 1
const SPEED_DOUBLE: int = 2
const KEY_TITLE: String = "ui.hud_title"
const KEY_CLOCK: String = "ui.hud_clock"
const KEY_DATE: String = "ui.hud_date"
const KEY_PAUSE_HINT: String = "ui.hud_pause_hint"
const KEY_PACE_PAUSED: String = "ui.hud_pace_paused"
const KEY_PACE_SPEED: String = "ui.hud_pace_speed"

## Quantas vezes o texto foi reescrito (público para os testes: provar que só muda quando o relógio muda).
var update_count: int = 0

var _bridge: SimBridge
var _texts: UiText
var _game_title: String = ""
var _game_version: String = ""
var _shown: String = ""
var _has_reported_time_error: bool = false


func _ready() -> void:
	set_process(false)


## Liga o HUD à ponte e aos textos, com o título e a versão do jogo, e desenha já. Peça nula: push_error e nada acontece (devolve falso).
func setup(bridge: SimBridge, texts: UiText, game_title: String, game_version: String) -> bool:
	if bridge == null or texts == null:
		push_error("HudView.setup: ponte ou textos nulos; esperado os dois.")
		return false
	_bridge = bridge
	_texts = texts
	_game_title = game_title
	_game_version = game_version
	_shown = ""
	_has_reported_time_error = false
	set_process(true)
	refresh()
	return true


func _process(_delta: float) -> void:
	refresh()


## Lê a hora e o ritmo pela ponte e reescreve o texto SÓ se mudaram. Hora indisponível: push_error uma vez e o texto fica como está.
func refresh() -> void:
	if _bridge == null:
		return
	var time: SimBridge.TimeSnapshot = _bridge.peek_time()
	if not time.result.ok:
		if not _has_reported_time_error:
			_has_reported_time_error = true
			push_error("HudView: hora simulada indisponível (%s): %s" % [time.result.code, time.result.message])
		return
	var signature: String = "%d|%d|%d|%d|%s|%d" % [time.year, time.day_of_year, time.hour_of_day, time.minute_of_hour, str(time.is_paused), time.speed]
	if signature == _shown:
		return
	_shown = signature
	update_count += 1
	text = _compose(time)


## Trata as ações de velocidade; devolve se o evento era de uma delas (e foi tratado). Repetição de tecla não conta.
func handle_action(event: InputEvent) -> bool:
	if _bridge == null:
		return false
	if event.is_action_pressed(InputActions.SPEED_NORMAL):
		_request_speed(SPEED_NORMAL)
		return true
	if event.is_action_pressed(InputActions.SPEED_DOUBLE):
		_request_speed(SPEED_DOUBLE)
		return true
	return false


func _unhandled_input(event: InputEvent) -> void:
	if handle_action(event):
		get_viewport().set_input_as_handled()


func _request_speed(speed: int) -> void:
	var outcome: Result = _bridge.request_speed(speed)
	if not outcome.ok:
		push_error("HudView: velocidade %d recusada (%s): %s" % [speed, outcome.code, outcome.message])


## Três linhas: título e versão, data e ritmo, dica da tecla de pausa. Tudo por chaves.
func _compose(time: SimBridge.TimeSnapshot) -> String:
	var pace: String = _texts.get_text(KEY_PACE_PAUSED) if time.is_paused else _texts.get_text(KEY_PACE_SPEED, {"speed": time.speed})
	var date: String = _texts.get_text(KEY_DATE, {"year": time.year, "day": time.day_of_year, "hour": "%02d" % time.hour_of_day, "minute": "%02d" % time.minute_of_hour})
	var lines: PackedStringArray = PackedStringArray([
		_texts.get_text(KEY_TITLE, {"title": _game_title, "version": _game_version}),
		_texts.get_text(KEY_CLOCK, {"date": date, "pace": pace}),
		_texts.get_text(KEY_PAUSE_HINT, {"key": _action_key_label(InputActions.PAUSE)}),
	])
	return "\n".join(lines)


## Tecla da ação para a dica, lida do InputMap (primeira palavra do texto do evento, ex.: "P").
func _action_key_label(action: StringName) -> String:
	var events: Array[InputEvent] = InputMap.action_get_events(action)
	return events[0].as_text().get_slice(" ", 0) if not events.is_empty() else "?"
