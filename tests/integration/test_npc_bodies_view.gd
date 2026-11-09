extends GutTest
## LW-072c: o conjunto S0 na tela (`NpcBodiesView`), sem janela e com o jogo montado como o real: dados reais de res://data, os 100 NPCs (60 no
## assentamento A e 40 no B), a ponte real e uma `TerrainView` de verdade. Ninguém move os corpos (o andar é da LW-072d). Confere que os corpos
## ativos são sempre os NPCs em S0, a cada passo de um dia com o jogador andando, que as saídas vêm antes das entradas, que a morte devolve o
## corpo, que o corpo nasce onde a ponte manda e fica escondido sem terreno, o interruptor e a falha.

const DATA_DIR: String = "res://data"
const WORLD_SEED: int = 5
const MAX_S0: int = 50
const PREWARM: int = 60
const DAY: int = SimClock.MINUTES_PER_DAY
const CHUNK_M: float = 64.0
const A_M: Vector3 = Vector3(320.0, 10.0, 540.0)
const B_M: Vector3 = Vector3(800.0, 10.0, 660.0)
const FAR_M: Vector3 = Vector3(600.0, 10.0, 900.0)
## O dia do jogador: de A a B, de B para longe dos dois e de volta a A, 480 minutos em cada trecho.
const WALK: Array[Vector3] = [A_M, B_M, FAR_M, A_M]
const LEG_MINUTES: float = 480.0
const FOOD_PLACES: Array[String] = ["test_settlement_a", "test_settlement_b"]
## Fome do teste da morte: nasce crítica (95), enfraquece em 1 h e mata em 2 h, e a comida é zerada.
const HUNGER: int = 0
const HUNGER_START: int = 95
const WEAKEN_HOURS: int = 1
const LETHAL_HOURS: int = 2

var _data: NpcLifeCheck.GameData
var _host: SimulationHostNode
var _bridge: SimBridge
var _terrain_view: TerrainView
var _view: NpcBodiesView
var _actor_id: int = 0


## Ponte que pode passar a falhar na consulta dos corpos (o caminho de falha da view).
class FlakyBridge:
	extends SimBridge

	var is_failing: bool = false

	func peek_npc_bodies() -> BridgeReplies.NpcBodiesReply:
		if is_failing:
			return BridgeReplies.NpcBodiesReply.new(Result.failure("TEST_BRIDGE_DOWN", "ponte de teste fora do ar."), [])
		return super()


func before_all() -> void:
	_data = NpcLifeCheck.load_game_data()
	assert_eq(_data.problem, "", "Os dados reais do jogo carregam.")


func after_each() -> void:
	if _view != null:
		_view.release()
	if _host != null:
		_host.runner.finish()
		_host.free()
	_view = null
	_host = null


## Jogo novo igual ao real, a ponte, um ator e a view ligada (o que liga o interruptor de corpos). `deadly` (build de desenvolvimento) faz a
## fome matar em 2 h e zera a comida; `flaky` usa uma ponte que pode falhar.
func _start(deadly: bool = false, flaky: bool = false) -> void:
	var setup: NpcSetup = NpcSetup.from_dir(DATA_DIR, SettlementService.new(_data.settlements, _data.places), deadly)
	assert_true(setup.result.ok, setup.result.message)
	if deadly:
		var hunger: NeedDef = setup.need_defs[HUNGER]
		hunger.start_value = HUNGER_START
		hunger.weaken_after_hours = WEAKEN_HOURS
		hunger.lethal_after_hours = LETHAL_HOURS
	_host = SimulationHostNode.new()
	_host.start_new_game(WORLD_SEED, _data.terrain, _data.points, setup)
	if deadly:
		for settlement_id: String in FOOD_PLACES:
			var emptied: Result = _host.npc.request_set_food_stock(settlement_id, 0)
			assert_true(emptied.ok, emptied.message)
	_bridge = FlakyBridge.new(_host, _data.terrain, _data.places, _host.npc) if flaky else SimBridge.new(_host, _data.terrain, _data.places, _host.npc)
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


func _s0() -> Array[int]:
	return _host.npc.lod.s0_ids()


func _walker_at(minute: int) -> Vector3:
	var leg: int = mini(floori(float(minute) / LEG_MINUTES), WALK.size() - 2)
	return WALK[leg].lerp(WALK[leg + 1], float(minute) / LEG_MINUTES - float(leg))


func test_setup_turns_the_switch_on_and_release_turns_it_off_and_returns_every_body() -> void:
	_start()
	assert_true(_host.npc.debug_summary()["bodies_available"], "A view liga o interruptor de corpos da simulação.")
	assert_eq([_view.is_active(), _view.pool().created, _view.get_child_count()], [true, PREWARM, PREWARM], "E cria a reserva escondida.")
	_tick(A_M)
	assert_gt(_view.active_ids().size(), 0, "Junto do assentamento há corpos.")
	_view.release()
	assert_eq([_view.is_active(), _view.active_ids().size(), _s0().size(), _host.npc.debug_summary()["bodies_available"]], [false, 0, 0, false])
	_tick(A_M)
	assert_eq([_view.active_ids().size(), _s0().size()], [0, 0], "Depois do release ninguém volta, nem com o jogador no mesmo lugar.")


func test_the_active_bodies_are_the_s0_set_at_every_step_of_a_day_with_the_player_walking_around() -> void:
	_start()
	var biggest: int = 0
	var empty_steps: int = 0
	for minute: int in DAY:
		_tick(_walker_at(minute))
		assert_eq(_view.active_ids(), _s0(), "Os corpos ativos são os NPCs em S0 no minuto %d." % minute)
		biggest = maxi(biggest, _s0().size())
		empty_steps += 1 if _s0().is_empty() else 0
	var pool: NpcViewPool = _view.pool()
	assert_eq(biggest, MAX_S0, "Junto de A a lista chega ao limite de S0.")
	assert_gt(empty_steps, 0, "E há trechos sem ninguém em S0 (o jogador longe dos dois povoados).")
	assert_eq([pool.created, pool.empty_hits, pool.duplicate_requests, pool.lost_count()], [PREWARM, 0, 0, 0], "A reserva não cresceu, sem duplicados nem perdidos.")
	assert_eq(pool.taken, pool.returned + pool.active_count(), "Todo corpo retirado ou está em uso ou voltou.")
	assert_gt(pool.returned, 0, "Houve saídas de S0 ao longo do dia.")


func test_a_full_swap_in_one_step_returns_the_old_bodies_before_taking_the_new_ones() -> void:
	_start()
	_tick(A_M)
	var at_a: int = _view.active_ids().size()
	_tick(B_M)
	assert_gt(at_a + _view.active_ids().size(), PREWARM, "Precondição: com as entradas antes das saídas a reserva teria de crescer.")
	assert_eq(_view.active_ids(), _s0(), "Os corpos de A saíram e os de B entraram no mesmo quadro.")
	assert_eq([_view.pool().created, _view.pool().empty_hits, _view.pool().peak_active <= MAX_S0], [PREWARM, 0, true], "Nunca houve mais de 50 corpos ao mesmo tempo.")


func test_the_death_of_npcs_in_s0_returns_their_bodies() -> void:
	_start(true)
	var peak: int = 0
	for _minute: int in (LETHAL_HOURS + 1) * SimClock.MINUTES_PER_HOUR:
		_tick(A_M)
		assert_eq(_view.active_ids(), _s0(), "Os corpos ativos continuam sendo os NPCs em S0.")
		peak = maxi(peak, _view.active_ids().size())
	var dead: int = 0
	for npc_id: int in _host.npc.peek_npc_ids():
		if not _host.npc.peek_npc(npc_id).is_alive:
			dead += 1
			assert_null(_view.pool().body_of(npc_id), "O NPC %d morreu e não tem mais corpo." % npc_id)
	var pool: NpcViewPool = _view.pool()
	assert_gte(dead, MAX_S0, "Sem comida, a fome matou os 50 que estavam em S0.")
	assert_eq([peak, pool.returned >= MAX_S0, pool.taken], [MAX_S0, true, pool.returned + pool.active_count()], "Cada morte devolveu o corpo à reserva.")


func test_a_body_is_born_where_the_bridge_says_and_stays_hidden_until_its_terrain_chunk_is_drawn() -> void:
	_start()
	_tick(A_M)
	var listed: BridgeReplies.NpcBodiesReply = _bridge.peek_npc_bodies()
	assert_gt(listed.bodies.size(), 0)
	var chunks: Dictionary[Vector2i, bool] = {}
	for body: BridgeReplies.NpcBodyReply in listed.bodies:
		assert_eq(_view.pool().body_of(body.npc_id).position, body.position, "O corpo nasce na posição da ponte (NPC %d)." % body.npc_id)
		assert_false(_view.pool().body_of(body.npc_id).visible, "Sem terreno desenhado o corpo fica escondido.")
		chunks[Vector2i(floori(body.position.x / CHUNK_M), floori(body.position.z / CHUNK_M))] = true
	for coord: Vector2i in chunks:
		assert_true(_terrain_view.build_chunk(coord))
	_view.reconcile()
	for body: BridgeReplies.NpcBodyReply in listed.bodies:
		assert_true(_view.pool().body_of(body.npc_id).visible, "Com o terreno do chunk desenhado o corpo aparece (NPC %d)." % body.npc_id)


func test_setup_refuses_a_null_terrain_and_a_bridge_without_the_npc_module() -> void:
	_start()
	var bare: NpcBodiesView = NpcBodiesView.new()
	add_child_autofree(bare)
	assert_false(bare.setup(_bridge, null))
	assert_push_error("nulo")
	assert_false(bare.setup(SimBridge.new(_host, _data.terrain, _data.places), _terrain_view), "Ponte sem o módulo `npc` recusa o interruptor.")
	assert_push_error(SimBridge.CODE_NO_NPC)
	assert_eq([bare.is_active(), bare.active_ids().size(), bare.pool()], [false, 0, null], "Nenhum corpo e a view inativa.")


func test_a_failing_bridge_means_no_bodies_and_the_switch_off_until_a_new_setup() -> void:
	_start(false, true)
	_tick(A_M)
	assert_gt(_view.active_ids().size(), 0)
	(_bridge as FlakyBridge).is_failing = true
	_view.reconcile()
	assert_push_error("corpos indisponíveis")
	assert_eq([_view.is_active(), _view.active_ids().size(), _s0().size(), _host.npc.debug_summary()["bodies_available"]], [false, 0, 0, false], "Sem corpos e com o interruptor desligado.")
	(_bridge as FlakyBridge).is_failing = false
	_tick(A_M)
	assert_eq([_view.active_ids().size(), _s0().size()], [0, 0], "A view não volta sozinha.")
	assert_true(_view.setup(_bridge, _terrain_view), "Só um novo setup a liga de novo.")
	_tick(A_M)
	assert_eq(_view.active_ids(), _s0())
	assert_gt(_view.active_ids().size(), 0)
