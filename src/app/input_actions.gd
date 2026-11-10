class_name InputActions
extends RefCounted
## Nomes das ações de entrada (LW-044; decisões E1 e E2 de Arthur; DEC-116). O código de jogo lê SÓ estes nomes: as teclas
## padrão ficam na seção [input] do project.godot, por tecla física, e nenhuma tecla é escrita no código (tools/check_input_keys).
## O movimento do mouse NÃO é ação do InputMap (quem o trata é a câmera, LW-046); o botão direito (camera_orbit) e a roda
## (zoom_in e zoom_out) são ações de mouse da câmera (decisão D3 do lote 3). Gamepad: DEC-024 PENDENTE, fora do lote.
## A pausa é tratada pelo GameApp, o movimento pelo PlayerBody e as ações de olhar, órbita e zoom pela câmera (LW-046); as de
## velocidade só EXISTEM: quem as usa é o HUD (LW-051).

const MOVE_FORWARD: StringName = &"move_forward"
const MOVE_BACK: StringName = &"move_back"
const MOVE_LEFT: StringName = &"move_left"
const MOVE_RIGHT: StringName = &"move_right"
const RUN: StringName = &"run"
const JUMP: StringName = &"jump"
const INTERACT: StringName = &"interact"
const PAUSE: StringName = &"pause"
const LOOK_LEFT: StringName = &"look_left"
const LOOK_RIGHT: StringName = &"look_right"
const LOOK_UP: StringName = &"look_up"
const LOOK_DOWN: StringName = &"look_down"
const SPEED_NORMAL: StringName = &"speed_normal"
const SPEED_DOUBLE: StringName = &"speed_double"
const CAMERA_ORBIT: StringName = &"camera_orbit"
const ZOOM_IN: StringName = &"zoom_in"
const ZOOM_OUT: StringName = &"zoom_out"
## Painel de depuração de NPC (LW-082g; só em build de desenvolvimento): F3 e Tab abrem e fecham (duas ações, uma tecla cada), N e B trocam de NPC e T marca o rastro [HIP].
const INSPECTOR_TOGGLE: StringName = &"inspector_toggle"
const INSPECTOR_TOGGLE_ALT: StringName = &"inspector_toggle_alt"
const INSPECTOR_NEXT: StringName = &"inspector_next"
const INSPECTOR_PREVIOUS: StringName = &"inspector_previous"
const INSPECTOR_TRACE: StringName = &"inspector_trace"

const ALL: Array[StringName] = [
	MOVE_FORWARD, MOVE_BACK, MOVE_LEFT, MOVE_RIGHT, RUN, JUMP, INTERACT, PAUSE,
	LOOK_LEFT, LOOK_RIGHT, LOOK_UP, LOOK_DOWN, SPEED_NORMAL, SPEED_DOUBLE, CAMERA_ORBIT, ZOOM_IN, ZOOM_OUT,
	INSPECTOR_TOGGLE, INSPECTOR_TOGGLE_ALT, INSPECTOR_NEXT, INSPECTOR_PREVIOUS, INSPECTOR_TRACE,
]
