extends GutTest
## LW-099b1: a consulta `SimBridge.peek_caravan_bodies` (contrato da LW-099, seção 6; contrato da ponte): por caravana, em ordem de `trader_id`, a rota e os povoados do trecho atual, o estado, a fração `u` do trecho JÁ PRONTA (a fração de passo do relógio dentro dela, só para quem anda), o bem, a quantidade e a faixa
## de carga em milésimos. Só `peek`, só tipos da ponte. Os valores esperados saem da mão (do cenário e do relógio), não de uma segunda cópia da regra. Economia e `world` REAIS pelo `CaravanRig` (o host só guarda o `runner` e a `economy`; sem terreno nem `npc`).

const TRADER: int = 100
const OTHER: int = 101
const THIRD: int = 102
const TRADERS: Array[int] = [TRADER, OTHER, THIRD]
const START: int = CaravanRig.START_MINUTE
const SETTLEMENT_A: String = CaravanRig.SETTLEMENT_A
const SETTLEMENT_B: String = CaravanRig.SETTLEMENT_B
const SETTLEMENT_C: String = CaravanRig.SETTLEMENT_C
## 100 ms de tempo real a 1x são 0,08 do minuto simulado (1250 ms por minuto).
const FRAME_MS: int = 100
const FRAME_MINUTES: float = 0.08
const EPSILON: float = 0.000001

var _routes: RouteService
var _rigs: Array[CaravanRig] = []
var _hosts: Array[SimulationHostNode] = []


func before_all() -> void:
	_routes = CaravanRig.load_routes()


func after_each() -> void:
	for rig: CaravanRig in _rigs:
		rig.release()
	_rigs.clear()
	for host: SimulationHostNode in _hosts:
		host.free()
	_hosts.clear()


func _rig() -> CaravanRig:
	var rig: CaravanRig = CaravanRig.build(_routes)
	rig.start_new_game(TRADERS)
	_rigs.append(rig)
	return rig


func _bodies(rig: CaravanRig) -> Array[BridgeReplies.CaravanBodyReply]:
	var reply: BridgeReplies.CaravanBodiesReply = rig.bridge.peek_caravan_bodies()
	assert_true(reply.result.ok, reply.result.message)
	return reply.bodies


func _row(body: BridgeReplies.CaravanBodyReply) -> Array:
	return [body.trader_id, body.route_id, body.from_settlement_id, body.to_settlement_id, body.state, body.good_id, body.quantity, body.load_permille]


func test_the_bridge_refuses_without_a_game_and_without_the_economy() -> void:
	var rig: CaravanRig = _rig()
	var empty_host: SimulationHostNode = SimulationHostNode.new()
	_hosts.append(empty_host)
	rig.host.economy = null
	for refused: Array in [[SimBridge.new(null, null), SimBridge.CODE_NO_GAME], [SimBridge.new(empty_host, null), SimBridge.CODE_NO_GAME], [rig.bridge, SimBridge.CODE_NO_ECONOMY]]:
		var bridge: SimBridge = refused[0]
		var reply: BridgeReplies.CaravanBodiesReply = bridge.peek_caravan_bodies()
		assert_eq([reply.result.ok, reply.result.code, reply.bodies.size()], [false, refused[1], 0], "Sem host, host sem jogo: BRIDGE_NO_GAME; jogo sem o módulo da economia: BRIDGE_NO_ECONOMY; lista vazia.")


func test_nobody_travelling_gives_an_empty_list_that_is_not_an_error() -> void:
	assert_eq(_bodies(_rig()).size(), 0)


func test_the_bodies_equal_the_derivation_of_the_scenario_and_carry_only_bridge_types() -> void:
	var rig: CaravanRig = _rig()
	rig.three_states(TRADER, OTHER, THIRD)
	assert_eq(rig.runner.advance_frame(500), 0, "500 ms a 1x: nenhum passo, a fração de passo vai a 0,4.")
	assert_almost_eq(rig.clock().step_fraction(), 0.4, EPSILON)
	var bodies: Array[BridgeReplies.CaravanBodyReply] = _bodies(rig)
	assert_eq(bodies.map(_row), [
		[TRADER, "route_a_c", SETTLEMENT_A, SETTLEMENT_C, "travelling", "bread", CaravanRig.LOT, 100],
		[OTHER, "route_b_c", SETTLEMENT_B, SETTLEMENT_C, "held", "bread", CaravanRig.LOT, 100],
		[THIRD, "route_b_c", SETTLEMENT_C, SETTLEMENT_B, "held", "bread", CaravanRig.LOT, 100]], "Por `trader_id`; o trecho no sentido da marcha (a parada no C vai do C ao B); 12 pães de peso 1 sobre a capacidade 120: 100 milésimos.")
	assert_eq(bodies.map(func(body: BridgeReplies.CaravanBodyReply) -> int: return body.trader_id), rig.module.peek_caravans().caravans.map(func(row: CaravanReplies.CaravanQuery) -> int: return row.trader_id), "O mesmo conjunto e a mesma ordem de `peek_caravans`.")
	assert_almost_eq(bodies[0].u, (100.0 + 0.4) / 124.0, EPSILON, "Andando: (minutos andados + fração de passo) ÷ duração do trecho.")
	assert_almost_eq(bodies[1].u, 20.0 / 96.0, EPSILON, "Parada no meio do trecho: os minutos andados ÷ duração, SEM a fração de passo.")
	assert_eq(bodies[2].u, 0.0, "Parada num povoado: u = 0, na ponta de partida do trecho bloqueado.")
	for body: BridgeReplies.CaravanBodyReply in bodies:
		var types: Array[int] = [typeof(body.trader_id), typeof(body.route_id), typeof(body.from_settlement_id), typeof(body.to_settlement_id), typeof(body.state), typeof(body.u), typeof(body.good_id), typeof(body.quantity), typeof(body.load_permille)]
		assert_eq(types, [TYPE_INT, TYPE_STRING, TYPE_STRING, TYPE_STRING, TYPE_STRING, TYPE_FLOAT, TYPE_STRING, TYPE_INT, TYPE_INT] as Array[int], "Só números e textos: nenhum objeto da simulação.")
	assert_eq([BridgeReplies.CaravanBodyReply.STATE_TRAVELLING, BridgeReplies.CaravanBodyReply.STATE_HELD], [Caravan.STATE_TRAVELLING, Caravan.STATE_HELD], "Os textos de estado da ponte são os do registro da economia.")
	bodies[0].quantity = 999
	assert_eq([_bodies(rig)[0].quantity, rig.module.peek_caravan(TRADER).quantity], [CaravanRig.LOT, CaravanRig.LOT], "A resposta é cópia: mexer nela não toca a ponte nem a economia.")


func test_u_grows_linearly_with_real_time_from_zero_at_the_departure_to_almost_one_at_the_end() -> void:
	var rig: CaravanRig = _rig()
	rig.depart(TRADER, rig.market_a, rig.market_b)
	var samples: Array[float] = []
	for _frame: int in 3000:
		var bodies: Array[BridgeReplies.CaravanBodyReply] = _bodies(rig)
		if bodies.is_empty():
			break
		samples.append(bodies[0].u)
		rig.runner.advance_frame(FRAME_MS)
	assert_eq(samples[0], 0.0, "u vale 0 na saída.")
	assert_between(samples[-1], 0.99, 0.9999999, "No último quadro antes da chegada u está perto de 1 (a caravana some ao chegar).")
	var off: Array[int] = []
	for index: int in range(1, samples.size()):
		if absf(samples[index] - samples[index - 1] - FRAME_MINUTES / 143.0) > EPSILON / 100.0:
			off.append(index)
	assert_eq(off, [] as Array[int], "A cada quadro de 100 ms u cresce 0,08 ÷ 143, exatamente: monótona no tempo e na fração de passo, sem saltos nem recuos, também quando o quadro passa de um minuto ao outro.")
	assert_eq(samples.size(), ceili(143.0 * 1250.0 / FRAME_MS), "143 minutos de 1250 ms em quadros de 100 ms: a viagem leva 1788 quadros e a última amostra é a do quadro anterior à chegada.")


func test_u_is_fixed_while_held_and_does_not_move_while_the_clock_is_paused() -> void:
	var rig: CaravanRig = _rig()
	rig.three_states(TRADER, OTHER, THIRD)
	var held: Array[float] = []
	var walking: Array[float] = []
	for _frame: int in 20:
		rig.runner.advance_frame(500)
		var bodies: Array[BridgeReplies.CaravanBodyReply] = _bodies(rig)
		walking.append(bodies[0].u)
		held.append_array([bodies[1].u, bodies[2].u])
	assert_eq(held, _repeat([20.0 / 96.0, 0.0] as Array[float], 20), "As duas paradas ficam exatamente onde estavam, com a fração de passo andando e os minutos passando.")
	var stalled: Array[int] = []
	for index: int in range(1, walking.size()):
		if walking[index] <= walking[index - 1]:
			stalled.append(index)
	assert_eq(stalled, [] as Array[int], "Quem anda só cresce.")
	rig.clock().set_paused(true)
	var before: float = _bodies(rig)[0].u
	for _frame: int in 5:
		assert_eq(rig.runner.advance_frame(500), 0, "Pausado, nenhum passo.")
		assert_eq(_bodies(rig)[0].u, before, "Em pausa a fração de passo não anda e a caravana também não.")
	rig.clock().set_paused(false)
	rig.runner.advance_frame(500)
	assert_gt(_bodies(rig)[0].u, before, "Despausado, volta a andar.")


func test_progress_of_clamps_to_zero_and_one_and_ignores_the_step_fraction_when_held() -> void:
	var row: CaravanReplies.CaravanQuery = CaravanReplies.CaravanQuery.new(Result.success())
	assert_eq(BridgeCaravans.progress_of(row, 0.5), 0.0, "Sem a duração do trecho (economia sem a porta de rotas): 0.")
	row.state = Caravan.STATE_TRAVELLING
	row.leg_minutes = 100
	for case: Array in [[0, 0.0, 0.0], [0, 0.5, 0.005], [99, 0.999, 0.99999], [100, 0.0, 1.0], [100, 0.9, 1.0]]:
		row.leg_walked_min = case[0]
		assert_almost_eq(BridgeCaravans.progress_of(row, case[1]), case[2], EPSILON, "%d de 100 minutos andados e fração %s." % [case[0], str(case[1])])
	row.state = Caravan.STATE_HELD
	row.leg_walked_min = 40
	assert_eq([BridgeCaravans.progress_of(row, 0.0), BridgeCaravans.progress_of(row, 0.99)], [0.4, 0.4], "`held`: minutos andados ÷ duração, a fração de passo não vale.")


func test_the_load_band_comes_from_the_economy_weights_and_is_cut_at_a_full_cart() -> void:
	var rig: CaravanRig = _rig()
	var row: CaravanReplies.CaravanQuery = CaravanReplies.CaravanQuery.new(Result.success())
	row.trader_id = TRADER
	for lot: Array in [["bread", 12, 100], ["bread", 120, 1000], ["wood", 12, 500], ["wood", 24, 1000], ["wood", 50, 1000], ["bread", 0, 0], ["no_such_good", 12, 0]]:
		row.good_id = lot[0]
		row.quantity = lot[1]
		assert_eq(BridgeCaravans.load_permille_of(rig.module, row), lot[2], "%d de '%s' sobre a capacidade 120: peso unitário da economia (pão 1, madeira 5)." % [lot[1], lot[0]])
	row.trader_id = 999
	row.good_id = "bread"
	row.quantity = 12
	assert_eq(BridgeCaravans.load_permille_of(rig.module, row), 0, "Comerciante que a economia não conhece: 0.")


## `values` repetido `times` vezes, em sequência (a lista esperada das paradas).
func _repeat(values: Array[float], times: int) -> Array[float]:
	var repeated: Array[float] = []
	for _index: int in times:
		repeated.append_array(values)
	return repeated
