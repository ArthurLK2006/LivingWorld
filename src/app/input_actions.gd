class_name InputActions
extends RefCounted
## Nomes das ações de entrada (LW-044; decisões E1 e E2 de Arthur; DEC-116). O código de jogo lê SÓ estes nomes: as teclas
## padrão ficam na seção [input] do project.godot, por tecla física, e nenhuma tecla é escrita no código (tools/check_input_keys).
## O movimento do mouse NÃO é ação do InputMap (quem o trata é a câmera, LW-046). Gamepad: DEC-024 PENDENTE, fora do lote.
## Hoje só a pausa é tratada (GameApp). As ações de olhar e de velocidade só EXISTEM: quem as usa é a câmera (LW-046) e o HUD (LW-051).

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

const ALL: Array[StringName] = [
	MOVE_FORWARD, MOVE_BACK, MOVE_LEFT, MOVE_RIGHT, RUN, JUMP, INTERACT, PAUSE,
	LOOK_LEFT, LOOK_RIGHT, LOOK_UP, LOOK_DOWN, SPEED_NORMAL, SPEED_DOUBLE,
]
