extends GutTest
## LW-072f: o jogo liga os corpos dos NPCs, sem janela. A cena principal REAL (res://scenes/main.tscn) é montada com os dados reais (100 NPCs) e um GameApp de teste no
## lugar do autoload, que entrega a ponte do teste (conta os pedidos do interruptor de corpos) e não recomeça o mundo do autoload. O mundo é do teste: ele o avança passo
## a passo e move o foco do jogador pela ponte. Confere que os corpos na tela são exatamente os NPCs em S0, que sair e voltar de S0 não vaza nem duplica corpo, que o
## interruptor é ligado uma vez e desligado ao sair da cena, e que a ponte sem `npc` e o jogador longe de tudo não derrubam nada.

const DATA_DIR: String = "res://data"
const MAIN_SCENE: String = "res://scenes/main.tscn"
const WORLD_SEED: int = 5
const A_M: Vector3 = Vector3(320.0, 10.0, 540.0)
## Longe dos três povoados (o C, da LW-097d, fica em 560 m, 860 m; o raio de saída do S0 é de 120 m).
const FAR_M: Vector3 = Vector3(700.0, 10.0, 960.0)
const MAX_S0: int = 50
const PREWARM: int = 60
const STEPS: int = 5

var _data: NpcLifeCheck.GameData
var _host: SimulationHostNode
var _bridge: CountingBridge
var _real_app: Node
var _real_index: int = 0
var _stub: StubApp
var _main: Node


## Ponte que conta os pedidos do interruptor de corpos.
class CountingBridge:
	extends SimBridge

	var switch_calls: Array[bool] = []

	func request_set_bodies_available(available: bool) -> Result:
		switch_calls.append(available)
		return super(available)


## GameApp de teste: entrega a ponte do teste e NÃO inicia jogo nenhum (o `_ready` do autoload recomeçaria o mundo do autoload).
class StubApp:
	extends GameAppNode

	var stub_bridge: SimBridge

	func _ready() -> void:
		pass

	func peek_bridge() -> SimBridge:
		return stub_bridge


func before_all() -> void:
	_data = NpcLifeCheck.load_game_data()
	assert_eq(_data.problem, "", "Os dados reais do jogo carregam.")


func after_each() -> void:
	if _main != null and is_instance_valid(_main):
		if _main.is_inside_tree():
			_main.get_parent().remove_child(_main)
		_main.free()
	if _stub != null:
		get_tree().root.remove_child(_stub)
		_stub.free()
		get_tree().root.add_child(_real_app)
		get_tree().root.move_child(_real_app, _real_index)
	if _host != null:
		_host.runner.finish()
		_host.free()
	_main = null
	_stub = null
	_host = null


## O jogo real e a cena principal montada sobre ele. `with_npc` falso: a ponte nasce sem o módulo `npc`.
func _start(with_npc: bool = true) -> void:
	var setup: NpcSetup = NpcSetup.from_dir(DATA_DIR, SettlementService.new(_data.settlements, _data.places))
	_host = SimulationHostNode.new()
	_host.start_new_game(WORLD_SEED, _data.terrain, _data.points, setup)
	_bridge = CountingBridge.new(_host, _data.terrain, _data.places, _host.npc if with_npc else null)
	_stub = StubApp.new()
	_stub.name = "GameApp"
	_stub.stub_bridge = _bridge
	_real_app = get_tree().root.get_node("GameApp")
	_real_index = _real_app.get_index()
	get_tree().root.remove_child(_real_app)
	get_tree().root.add_child(_stub)
	_main = (load(MAIN_SCENE) as PackedScene).instantiate()
	add_child(_main)


func _bodies() -> NpcBodiesView:
	return _main.get_node("NpcBodiesView") as NpcBodiesView


## Põe o foco do jogador em `spot_m` pela ponte (o corpo físico do jogador fica parado, senão relataria a posição dele por cima) e deixa passar `minutes` passos e
## dois quadros, para a view e o motorista da cena trabalharem sozinhos.
func _move_focus_and_wait(spot_m: Vector3, minutes: int) -> void:
	var player: PlayerBody = _main.get_node("PlayerBody") as PlayerBody
	player.set_physics_process(false)
	assert_true(_bridge.request_report_position(player.get_actor_id(), spot_m, 0.0).ok)
	_host.runner.run_steps(minutes)
	await wait_process_frames(2)


func _count(node: Node) -> int:
	var total: int = 1
	for child: Node in node.get_children():
		total += _count(child)
	return total


func test_the_scene_turns_the_bodies_on_once_and_the_bodies_on_screen_are_exactly_the_s0_set() -> void:
	_start()
	assert_eq(_bridge.switch_calls, [true] as Array[bool], "O interruptor foi ligado uma vez, ao montar a cena.")
	assert_eq([_bodies().is_active(), _bodies().pool().created], [true, PREWARM], "A view está ligada e a reserva pré-aquecida.")
	await _move_focus_and_wait(A_M, STEPS)
	var s0: Array[int] = _host.npc.lod.s0_ids()
	assert_between(s0.size(), 1, MAX_S0, "Com o jogador no povoado há NPCs em S0, no máximo 50.")
	assert_eq(_bodies().active_ids(), s0, "Os corpos na tela são exatamente os NPCs em S0.")
	assert_eq(_bridge.switch_calls, [true] as Array[bool], "E o interruptor continuou ligado uma vez só.")


func test_leaving_and_returning_to_s0_neither_leaks_nor_duplicates_a_body() -> void:
	_start()
	await _move_focus_and_wait(A_M, STEPS)
	var nodes: int = _count(_bodies())
	for _cycle: int in 2:
		await _move_focus_and_wait(FAR_M, 1)
		assert_eq(_bodies().active_ids().size(), 0, "Longe do povoado nenhum corpo fica ativo.")
		await _move_focus_and_wait(A_M, 1)
		assert_eq(_bodies().active_ids(), _host.npc.lod.s0_ids(), "De volta, os corpos são de novo os NPCs em S0.")
	var pool: NpcViewPool = _bodies().pool()
	assert_eq([pool.created, pool.empty_hits, pool.duplicate_requests, pool.lost_count(), _count(_bodies())], [PREWARM, 0, 0, 0, nodes], "A reserva não cresceu e a contagem de nós é a mesma.")


func test_leaving_the_scene_turns_the_bodies_off() -> void:
	_start()
	await _move_focus_and_wait(A_M, STEPS)
	assert_gt(_host.npc.lod.s0_ids().size(), 0)
	_main.get_parent().remove_child(_main)
	assert_eq([_bridge.switch_calls, _host.npc.lod.s0_ids().size()], [[true, false] as Array[bool], 0], "Sair da cena desliga os corpos e solta todos de S0.")


func test_a_bridge_without_the_npc_module_logs_once_and_nothing_runs() -> void:
	_start(false)
	assert_push_error(SimBridge.CODE_NO_NPC)
	await wait_process_frames(2)
	var driver: NpcBodyDriver = _main.get_node("NpcBodyDriver") as NpcBodyDriver
	assert_eq([_bodies().is_active(), _bodies().pool(), driver.job_count()], [false, null, 0], "A view fica inativa, sem reserva, e o motorista sem trabalho.")
	assert_eq(_bridge.switch_calls, [true] as Array[bool], "Houve um só pedido do interruptor, e ele foi recusado.")


func test_with_the_player_far_from_every_settlement_no_body_appears() -> void:
	_start()
	await _move_focus_and_wait(FAR_M, STEPS)
	var driver: NpcBodyDriver = _main.get_node("NpcBodyDriver") as NpcBodyDriver
	assert_eq([_host.npc.lod.s0_ids().size(), _bodies().active_ids().size(), driver.job_count(), _bodies().pool().free_count()], [0, 0, 0, PREWARM], "Ninguém em S0, nenhum corpo, nenhum trabalho; a reserva intacta.")
