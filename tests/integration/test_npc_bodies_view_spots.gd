extends GutTest
## LW-099c: o rastreio do ponto em que cada corpo de NPC estava em pé ao ser devolvido (`NpcBodiesView.track_last_spots`), no jogo real, sem janela, com o jogador andando de A a B, ao longe e de volta a A (os corpos entram e saem de S0). Desligado (o padrão): nada é guardado.
## Ligado: cada corpo devolvido deixa o ponto onde estava e a entrada some quando o NPC volta a ter corpo; desligar ou soltar a view esquece tudo; e a `state` da simulação, os contadores da reserva e os corpos são os mesmos com e sem o rastreio (o caminho dos NPCs não muda).

const DATA_DIR: String = "res://data"
const WORLD_SEED: int = 5
const A_M: Vector3 = Vector3(320.0, 10.0, 540.0)
const B_M: Vector3 = Vector3(800.0, 10.0, 660.0)
const FAR_M: Vector3 = Vector3(600.0, 10.0, 900.0)
const WALK: Array[Vector3] = [A_M, B_M, FAR_M, A_M]
const LEG_MINUTES: float = 480.0
const WALK_MINUTES: int = 1440
const CHECK_EVERY: int = 120
const SETTLE_TICKS: int = 5
const UNKNOWN_NPC: int = 999999

var _data: NpcLifeCheck.GameData
var _host: SimulationHostNode
var _bridge: SimBridge
var _terrain_view: TerrainView
var _view: NpcBodiesView
var _actor_id: int = 0


func before_all() -> void:
	_data = NpcLifeCheck.load_game_data()
	assert_eq(_data.problem, "", "Os dados reais do jogo carregam.")


func after_each() -> void:
	_stop()


## Solta a view e o jogo (o teste pode montar mais de um por vez, um depois do outro).
func _stop() -> void:
	if _view != null:
		_view.release()
	if _host != null:
		_host.runner.finish()
		_host.free()
	_view = null
	_host = null


## Jogo novo igual ao real, a ponte, um ator e a view ligada (o que liga o interruptor de corpos), com o rastreio como nasce: desligado.
func _start() -> void:
	var setup: NpcSetup = NpcSetup.from_dir(DATA_DIR, SettlementService.new(_data.settlements, _data.places))
	assert_true(setup.result.ok, setup.result.message)
	_host = SimulationHostNode.new()
	_host.start_new_game(WORLD_SEED, _data.terrain, _data.points, setup)
	_bridge = SimBridge.new(_host, _data.terrain, _data.places, _host.npc)
	_actor_id = _bridge.request_spawn_character().actor_id
	_terrain_view = TerrainView.new()
	add_child_autofree(_terrain_view)
	_terrain_view.setup(_bridge)
	_terrain_view.set_process(false)
	_view = NpcBodiesView.new()
	add_child_autofree(_view)
	assert_true(_view.setup(_bridge, _terrain_view))


## O jogador vai a `spot_m`, um passo da simulação e a view em dia: o quadro do jogo, em miniatura.
func _tick(spot_m: Vector3) -> void:
	assert_true(_bridge.request_report_position(_actor_id, spot_m, 0.0).ok)
	_host.runner.step_once()
	_view.reconcile()


func _walker_at(minute: int) -> Vector3:
	var leg: int = mini(floori(float(minute) / LEG_MINUTES), WALK.size() - 2)
	return WALK[leg].lerp(WALK[leg + 1], float(minute) / LEG_MINUTES - float(leg))


## Onde (x, z) está cada corpo em uso agora.
func _spots() -> Dictionary[int, Vector2]:
	var found: Dictionary[int, Vector2] = {}
	for npc_id: int in _view.active_ids():
		var body: NpcView = _view.pool().body_of(npc_id)
		found[npc_id] = Vector2(body.position.x, body.position.z)
	return found


func test_it_is_off_by_default_and_remembers_nothing() -> void:
	_start()
	assert_false(_view.tracks_last_spots(), "Nasce desligado.")
	for minute: int in WALK_MINUTES:
		_tick(_walker_at(minute))
	assert_eq(_view.remembered_spots(), 0, "Desligado, depois de um roteiro em que corpos entram e saem de S0, nada foi guardado.")
	assert_eq(_view.standing_spot_of(UNKNOWN_NPC), NpcBodiesView.NO_SPOT, "NPC que nunca teve corpo: sem ponto.")


func test_with_the_tracking_on_a_returned_body_leaves_its_last_spot_until_the_npc_has_a_body_again() -> void:
	_start()
	_view.track_last_spots(true)
	var expected: Dictionary[int, Vector2] = {}
	var gone_total: int = 0
	for minute: int in WALK_MINUTES:
		var before: Dictionary[int, Vector2] = _spots()
		_tick(_walker_at(minute))
		var now: Dictionary[int, Vector2] = _spots()
		for npc_id: int in before:
			if not now.has(npc_id):
				expected[npc_id] = before[npc_id]
				gone_total += 1
		for npc_id: int in now:
			expected.erase(npc_id)
		assert_eq(_view.remembered_spots(), expected.size(), "Minuto %d: um ponto por NPC devolvido que ainda não voltou a ter corpo." % minute)
		if minute % CHECK_EVERY == 0:
			for npc_id: int in expected:
				assert_eq(_view.standing_spot_of(npc_id), expected[npc_id], "Minuto %d: o NPC %d ficou em pé onde o corpo dele estava ao ser devolvido." % [minute, npc_id])
	assert_gt(gone_total, 0, "O roteiro devolveu corpos (o teste não rodou no vazio).")
	for npc_id: int in _view.active_ids():
		var body: NpcView = _view.pool().body_of(npc_id)
		assert_eq(_view.standing_spot_of(npc_id), Vector2(body.position.x, body.position.z), "Quem tem corpo está em pé onde o corpo está.")
	assert_true(_view.remembered_spots() <= _host.npc.peek_npc_ids().size(), "Limite documentado: no máximo uma entrada por NPC (os IDs não se repetem); quem morre ou sai do alcance fora de uma viagem deixa a sua até voltar a ter corpo, desligar o rastreio ou soltar a view.")
	_view.forget_last_spot(expected.keys()[0] if not expected.is_empty() else UNKNOWN_NPC)
	assert_eq(_view.remembered_spots(), maxi(expected.size() - 1, 0), "`forget_last_spot` esquece o ponto de quem o leu.")


## O roteiro inteiro com o rastreio `tracking`; devolve os contadores da reserva, a sequência de quantos corpos havia a cada minuto, o `state_hash` no fim e quantos pontos ficaram guardados.
func _walk(tracking: bool) -> Array:
	_start()
	_view.track_last_spots(tracking)
	var sizes: Array[int] = []
	for minute: int in WALK_MINUTES:
		_tick(_walker_at(minute))
		sizes.append(_view.active_ids().size())
	var pool: NpcViewPool = _view.pool()
	var result: Array = [[pool.created, pool.taken, pool.returned, pool.peak_active, pool.empty_hits, pool.duplicate_requests], sizes, _host.runner.world.state_hash(), _view.remembered_spots()]
	_stop()
	return result


func test_the_pool_counters_the_bodies_and_the_state_hash_are_the_same_with_and_without_the_tracking() -> void:
	var off: Array = _walk(false)
	var on: Array = _walk(true)
	assert_gt(on[0][2], 0, "Corpos foram devolvidos no roteiro (o teste não rodou no vazio).")
	assert_eq(on[0], off[0], "Os contadores da reserva (criados, retirados, devolvidos, pico, reserva vazia, duplicados) são os mesmos.")
	assert_eq(on[1], off[1], "Quantos corpos havia a cada minuto: o mesmo.")
	assert_eq(on[2], off[2], "O `state_hash` no fim: o mesmo.")
	assert_eq([off[3], on[3] > 0], [0, true], "Só o rastreio ligado guardou pontos.")


func test_turning_the_tracking_off_or_releasing_the_view_forgets_every_spot() -> void:
	_start()
	_view.track_last_spots(true)
	for _tick_index: int in SETTLE_TICKS:
		_tick(A_M)
	assert_gt(_view.active_ids().size(), 0, "Premissa: com o jogador em A há corpos.")
	_tick(FAR_M)
	assert_gt(_view.remembered_spots(), 0, "Premissa: ao ir para longe os corpos voltam à reserva e deixam o ponto.")
	_view.track_last_spots(false)
	assert_eq([_view.tracks_last_spots(), _view.remembered_spots()], [false, 0], "Desligar esquece tudo.")
	_view.track_last_spots(true)
	for _tick_index: int in SETTLE_TICKS:
		_tick(A_M)
	_tick(FAR_M)
	assert_gt(_view.remembered_spots(), 0, "Ligado de novo, volta a guardar.")
	_view.release()
	assert_eq(_view.remembered_spots(), 0, "Soltar a view esquece os pontos.")
