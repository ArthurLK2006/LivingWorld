extends GutTest
## LW-099c: as JUNTAS da caravana vistas pela `CaravanBodiesView` (ponte roteirizada, dados e mercados reais): o deslocamento lateral que sobe de 0 e desce a 0 nas pontas do trecho, e o giro limitado por metro andado na troca de trecho (viagem de dois trechos).
## MEDIDAS (24/11/2026; último quadro de A para C e primeiro de C para B, as duas estradas reais): ANTES da rampa e do limite de giro, posição 1,69 m e giro 89,3 graus (A para C chega a -139,5 graus e C para B parte a -50,2). DEPOIS, no quadro da troca: posição 0,00 m e giro
## 0,0 graus (a quina é o mesmo ponto e o giro só anda com o corpo andando); a estrada nova é alcançada em 7 passos de 0,5 m (3,1 m) e nenhum passo gira mais que 0,25 rad (14,3 graus). A rampa e o limite são [HIP] provisórios: a janela de Arthur afina.
## ÂNCORA da partida (a `NpcBodiesView` passada ao `setup`, aqui uma de mentira que responde onde o comerciante estava em pé e conta as perguntas): só a caravana RECÉM-NASCIDA (depois da 1ª consulta), andando e nos primeiros 12 m, e o ponto é perguntado UMA vez. O jogo real está em tests/integration/test_caravan_visual_jumps.gd.

const WORLD_DIR: String = "res://data/world"
const A: String = "test_settlement_a"
const B: String = "test_settlement_b"
const C: String = "test_settlement_c"
const ROUTE_A_B: String = "route_a_b"
const ROUTE_A_C: String = "route_a_c"
const ROUTE_B_C: String = "route_b_c"
const TRADER: int = 100
const MARKETS: Dictionary[String, Vector2] = {A: Vector2(313.0, 556.0), B: Vector2(807.0, 653.0), C: Vector2(567.0, 853.0)}
const GROUND_M: float = 10.0
const CHUNK_M: float = 64.0
const LATERAL_M: float = 1.2
const POSE_TOLERANCE_M: float = 0.01
const ANGLE_TOLERANCE: float = 0.0001
## Salto pequeno (de Arthur e do Maestro): até 0,5 m de posição e 15 graus de giro.
const SMALL_JUMP_M: float = 0.5
const SMALL_TURN_DEG: float = 15.0
const STEP_M: float = 0.5
const TRAVELLING: String = BridgeReplies.CaravanBodyReply.STATE_TRAVELLING
const NEAR_SPOT_M: Vector2 = Vector2(2.0, 1.0)
const FAR_SPOT_M: Vector2 = Vector2(20.0, 0.0)
const STEPS_WALKED: int = 12

var _terrain: TerrainData
var _places: Array[Place] = []
var _routes: CaravanRoutesReader
var _bridge: ScriptedCaravanBridge
var _terrain_view: TerrainView
var _view: CaravanBodiesView


## A `NpcBodiesView` de mentira: responde onde cada NPC estava em pé e conta as perguntas e os esquecimentos (a conta de verdade, com a reserva e o jogo real, está em test_npc_bodies_view_spots.gd).
class StandingBodies:
	extends NpcBodiesView

	var spots: Dictionary[int, Vector2] = {}
	var asked: int = 0
	var forgotten: int = 0

	func standing_spot_of(npc_id: int) -> Vector2:
		asked += 1
		return spots.get(npc_id, NpcBodiesView.NO_SPOT)

	func forget_last_spot(_npc_id: int) -> void:
		forgotten += 1


func before_all() -> void:
	var terrain: TerrainLoader.LoadResult = TerrainLoader.load_dir(WORLD_DIR)
	assert_true(terrain.result.ok, terrain.result.message)
	_terrain = terrain.terrain
	var settlements: SettlementLoader.LoadResult = SettlementLoader.load_dir(WORLD_DIR, _terrain)
	assert_true(settlements.result.ok, settlements.result.message)
	_places = settlements.places
	var loaded: CaravanRoutesReader.LoadResult = CaravanRoutesReader.from_file()
	assert_true(loaded.result.ok, loaded.result.message)
	_routes = loaded.data


func _start(bodies: NpcBodiesView = null) -> void:
	_bridge = ScriptedCaravanBridge.new(null, _terrain, _places)
	_terrain_view = TerrainView.new()
	add_child_autofree(_terrain_view)
	_terrain_view.setup(_bridge)
	_terrain_view.set_process(false)
	_view = CaravanBodiesView.new()
	add_child_autofree(_view)
	assert_true(_view.setup(_bridge, _terrain_view, _routes, bodies))


func _draw_terrain_around(spot: Vector2) -> void:
	var center: Vector2i = Vector2i(floori(spot.x / CHUNK_M), floori(spot.y / CHUNK_M))
	for dz: int in range(-1, 2):
		for dx: int in range(-1, 2):
			var coord: Vector2i = center + Vector2i(dx, dz)
			if not _terrain_view.has_chunk(coord):
				assert_true(_terrain_view.build_chunk(coord), "O chunk %s foi desenhado." % coord)


## Mostra a caravana no trecho de `from_id` a `to_id` na fração `u`, com o foco do jogador no ponto da estrada, consulta e devolve o corpo.
func _show(route_id: String, from_id: String, to_id: String, u: float, state: String = TRAVELLING) -> CaravanView:
	var focus_m: Vector2 = MARKETS[from_id].lerp(MARKETS[to_id], u)
	_draw_terrain_around(focus_m)
	_bridge.rows.assign([ScriptedCaravanBridge.row_of(TRADER, u, route_id, from_id, to_id, state)])
	_terrain_view.set_focus(Vector3(focus_m.x, GROUND_M, focus_m.y))
	_view.reconcile()
	return _view.body_of(TRADER)


func _spot_of(view: CaravanView) -> Vector2:
	return Vector2(view.position.x, view.position.z)


## O giro de quem anda de `from_id` para `to_id` (a convenção do `CaravanPath`: a frente é -Z).
func _heading_yaw(from_id: String, to_id: String) -> float:
	var heading: Vector2 = (MARKETS[to_id] - MARKETS[from_id]).normalized()
	return atan2(-heading.x, -heading.y)


func test_the_lateral_offset_rises_from_zero_and_falls_to_zero_over_the_ramp_at_both_ends() -> void:
	_start()
	var length_m: float = MARKETS[A].distance_to(MARKETS[B])
	for walked_m: float in [0.0, 3.0, 6.0, 12.0, 100.0, length_m * 0.5, length_m - 12.0, length_m - 6.0, length_m - 3.0, length_m]:
		var u: float = walked_m / length_m
		var body: CaravanView = _show(ROUTE_A_B, A, B, u)
		var share: float = clampf(minf(walked_m, length_m - walked_m) / CaravanBodiesView.LATERAL_RAMP_M, 0.0, 1.0)
		assert_almost_eq(_spot_of(body).distance_to(MARKETS[A].lerp(MARKETS[B], u)), LATERAL_M * share, POSE_TOLERANCE_M, "A %.1f m da ponta o corpo está a %.2f do eixo (a fração %.2f da rampa)." % [minf(walked_m, length_m - walked_m), LATERAL_M * share, share])


func test_the_joint_between_two_legs_has_no_gap_and_the_turn_takes_a_few_metres_of_walking() -> void:
	_start()
	var arriving: CaravanView = _show(ROUTE_A_C, A, C, 1.0)
	var spot_before: Vector2 = _spot_of(arriving)
	var yaw_before: float = arriving.rotation.y
	assert_almost_eq(yaw_before, _heading_yaw(A, C), ANGLE_TOLERANCE, "Premissa: o fim do trecho de A a C olha para C.")
	var leaving: CaravanView = _show(ROUTE_B_C, C, B, 0.0)
	assert_eq(leaving, arriving, "O mesmo corpo atravessa o povoado de passagem.")
	assert_lt(_spot_of(leaving).distance_to(spot_before), SMALL_JUMP_M, "TROCA DE TRECHO: a posição não salta (antes 1,69 m: o lado do deslocamento lateral virava de uma vez).")
	assert_lt(rad_to_deg(absf(angle_difference(yaw_before, leaving.rotation.y))), SMALL_TURN_DEG, "TROCA DE TRECHO: o giro não estala no quadro da troca (antes 89,3 graus).")
	_show(ROUTE_B_C, C, B, 0.0)
	assert_almost_eq(leaving.rotation.y, yaw_before, ANGLE_TOLERANCE, "Parado na quina (a mesma pose de novo) o corpo não gira.")
	var target: float = _heading_yaw(C, B)
	var road_m: float = MARKETS[C].distance_to(MARKETS[B])
	var previous: float = leaving.rotation.y
	var turned_at: int = 0
	var worst_deg: float = 0.0
	for step: int in range(1, STEPS_WALKED + 1):
		var body: CaravanView = _show(ROUTE_B_C, C, B, float(step) * STEP_M / road_m)
		worst_deg = maxf(worst_deg, rad_to_deg(absf(angle_difference(previous, body.rotation.y))))
		previous = body.rotation.y
		if turned_at == 0 and absf(angle_difference(body.rotation.y, target)) < ANGLE_TOLERANCE:
			turned_at = step
	assert_lt(worst_deg, SMALL_TURN_DEG, "Andando 0,5 m por quadro, nenhum quadro gira 15 graus ou mais.")
	var expected_steps: int = ceili(absf(angle_difference(yaw_before, target)) / (CaravanBodiesView.TURN_RAD_PER_M * STEP_M))
	assert_between(turned_at, expected_steps, expected_steps + 1, "A estrada nova é alcançada no passo que o limite de giro por metro andado dá (7 passos de 0,5 m, uns 3 m), nem antes nem muito depois.")
	assert_almost_eq(previous, target, ANGLE_TOLERANCE, "E o corpo termina olhando para onde a estrada nova vai.")


func test_the_first_pose_of_a_caravan_takes_the_heading_of_the_road_with_no_turn_limit() -> void:
	_start()
	var body: CaravanView = _show(ROUTE_B_C, C, B, 0.5)
	assert_almost_eq(body.rotation.y, _heading_yaw(C, B), ANGLE_TOLERANCE, "Sem pose anterior não há giro a limitar: a primeira pose já olha para o destino.")


## Uma consulta sem ninguém (a 1ª do jogo): as caravanas que aparecem depois são recém-nascidas.
func _consult_empty() -> void:
	_bridge.rows.clear()
	_view.reconcile()


## Uma caravana no começo (ou em `u`) do trecho A para B, com o comerciante em pé em `stand` (NO_SPOT: o NPC nunca teve corpo) e, se `after_query`, depois de uma consulta vazia; devolve [1ª pose no plano, a `NpcBodiesView` de mentira].
func _born(stand: Vector2, u: float = 0.0, state: String = TRAVELLING, after_query: bool = true) -> Array:
	var bodies: StandingBodies = StandingBodies.new()
	autofree(bodies)
	if stand != NpcBodiesView.NO_SPOT:
		bodies.spots[TRADER] = stand
	_start(bodies)
	if after_query:
		_consult_empty()
	return [_spot_of(_show(ROUTE_A_B, A, B, u, state)), bodies]


func test_a_newborn_caravan_leaves_from_where_the_merchant_stood_and_the_offset_fades_over_the_ramp() -> void:
	var bodies: StandingBodies = StandingBodies.new()
	autofree(bodies)
	_start(bodies)
	assert_true(bodies.tracks_last_spots(), "Ligar a vista com a `NpcBodiesView` liga o rastreio dela.")
	var stand: Vector2 = MARKETS[A] + Vector2(-1.5, 2.0)
	bodies.spots[TRADER] = stand
	_consult_empty()
	var length_m: float = MARKETS[A].distance_to(MARKETS[B])
	var heading: Vector2 = (MARKETS[B] - MARKETS[A]).normalized()
	var right: Vector2 = Vector2(-heading.y, heading.x)
	var previous_along: float = -INF
	var widest: float = 0.0
	for walked_m: float in [0.0, 0.5, 3.0, 6.0, 9.0, 12.0, 20.0]:
		var u: float = walked_m / length_m
		var spot: Vector2 = _spot_of(_show(ROUTE_A_B, A, B, u))
		var share: float = clampf(walked_m / CaravanBodiesView.LATERAL_RAMP_M, 0.0, 1.0)
		var expected: Vector2 = MARKETS[A].lerp(MARKETS[B], u) + right * LATERAL_M * share + (stand - MARKETS[A]) * (1.0 - share)
		assert_almost_eq(spot.distance_to(expected), 0.0, POSE_TOLERANCE_M, "A %.1f m andados: o ponto em pé que some em linha reta na rampa de 12 m e o deslocamento lateral que sobe." % walked_m)
		assert_gt((spot - MARKETS[A]).dot(heading), previous_along, "A %.1f m andados: nunca anda para trás ao longo da estrada." % walked_m)
		previous_along = (spot - MARKETS[A]).dot(heading)
		widest = maxf(widest, absf((spot - MARKETS[A]).cross(heading)))
	assert_lt(widest, LATERAL_M + stand.distance_to(MARKETS[A]) + POSE_TOLERANCE_M, "Nunca passa de 1,2 m + o deslocamento inicial.")
	assert_almost_eq(_spot_of(_show(ROUTE_B_C, B, C, 0.0)).distance_to(MARKETS[B]), 0.0, POSE_TOLERANCE_M, "No trecho seguinte a âncora não volta: sai do eixo.")
	assert_eq([bodies.asked, bodies.forgotten], [1, 1], "UMA pergunta por caravana nova, com o ponto esquecido uma vez, em todos os quadros e na troca de trecho.")


func test_no_anchor_for_a_caravan_found_mid_road_in_the_first_query_held_or_without_a_usable_spot() -> void:
	var near: Vector2 = MARKETS[A] + NEAR_SPOT_M
	var heading: Vector2 = (MARKETS[B] - MARKETS[A]).normalized()
	var found: Array = _born(near, 0.5)
	assert_almost_eq((found[0] as Vector2).distance_to(MARKETS[A].lerp(MARKETS[B], 0.5) + Vector2(-heading.y, heading.x) * LATERAL_M), 0.0, POSE_TOLERANCE_M, "A que o jogador encontra no meio da estrada: pose de sempre, com o deslocamento lateral cheio.")
	assert_eq([found[1].asked, found[1].forgotten], [0, 1], "...sem nem perguntar (o ponto guardado é só esquecido).")
	var loaded: Array = _born(near, 0.0, TRAVELLING, false)
	assert_lt((loaded[0] as Vector2).distance_to(MARKETS[A]), POSE_TOLERANCE_M, "Vista na 1ª consulta (jogo carregado no meio da viagem): sai do eixo.")
	assert_eq(loaded[1].asked, 0, "...sem perguntar.")
	var held: Array = _born(near, 0.0, BridgeReplies.CaravanBodyReply.STATE_HELD)
	assert_lt((held[0] as Vector2).distance_to(MARKETS[A]), POSE_TOLERANCE_M, "Parada (`held`): sai do eixo.")
	assert_eq(held[1].asked, 0, "...sem perguntar.")
	var unknown: Array = _born(NpcBodiesView.NO_SPOT)
	assert_lt((unknown[0] as Vector2).distance_to(MARKETS[A]), POSE_TOLERANCE_M, "NPC que nunca teve corpo (sem ponto): sai do eixo, sem erro.")
	assert_eq(unknown[1].asked, 1, "...e a pergunta foi uma só.")
	var far: Array = _born(MARKETS[A] + FAR_SPOT_M)
	assert_lt((far[0] as Vector2).distance_to(MARKETS[A]), POSE_TOLERANCE_M, "Ponto longe demais do mercado (20 m): não vale como \"em pé no mercado\"; sai do eixo.")
