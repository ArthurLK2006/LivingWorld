class_name PhysicsBoost
extends RefCounted
## Ajudante dos testes de física com o corpo do jogador (LW-048; mesmo mecanismo do tests/unit/test_player_body.gd). O motor avança a
## física em tempo real (60 quadros por segundo): para um cenário de 10 s não levar 10 s, acelera-se o relógio do motor com
## Engine.time_scale e physics_ticks_per_second na MESMA proporção, o que mantém cada passo de física em 1/60 s. O SimulationHost
## real (autoload) fica sem processar enquanto a velocidade muda, porque a troca dá um quadro com delta negativo, que o relógio da
## simulação recusa com erro. Uso: `await boost.enable(get_tree())` no before_all e `await boost.restore(get_tree())` no after_all.

const ACCELERATION: float = 10.0
const HOST_NAME: String = "SimulationHost"
## Quadros de processo esperados depois de trocar a velocidade do motor.
const SPEED_CHANGE_FRAMES: int = 3

var _host: Node
var _original_scale: float = 1.0
var _original_ticks: int = 60
var _is_enabled: bool = false


func enable(tree: SceneTree) -> void:
	if _is_enabled:
		return
	_is_enabled = true
	_host = tree.root.get_node_or_null(HOST_NAME)
	if _host != null:
		_host.set_process(false)
	_original_scale = Engine.time_scale
	_original_ticks = Engine.physics_ticks_per_second
	Engine.time_scale = ACCELERATION
	Engine.physics_ticks_per_second = int(float(_original_ticks) * ACCELERATION)
	for _frame: int in range(SPEED_CHANGE_FRAMES):
		await tree.process_frame


func restore(tree: SceneTree) -> void:
	if not _is_enabled:
		return
	_is_enabled = false
	Engine.time_scale = _original_scale
	Engine.physics_ticks_per_second = _original_ticks
	for _frame: int in range(SPEED_CHANGE_FRAMES):
		await tree.process_frame
	if _host != null:
		_host.set_process(true)
