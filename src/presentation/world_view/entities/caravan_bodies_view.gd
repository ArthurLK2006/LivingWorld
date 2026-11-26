class_name CaravanBodiesView
extends Node3D
## LW-099b2b (viagem visível dos comerciantes; só apresentação): a VISTA que decide quem aparece. A cada quadro faz UMA consulta à ponte (`peek_caravan_bodies`, sem sinal; só leitura: esta view nunca escreve na simulação) e mantém,
## na `CaravanViewPool`, um `CaravanView` por caravana que está no ALCANCE do jogador, nem mais nem menos. ESTRADA: a polilinha do trecho (`CaravanPath.through`) vai do mercado do povoado de saída ao do de chegada, no sentido da marcha
## (os mercados vêm de `peek_places`; a apresentação não conhece a simulação), e é montada UMA vez por trecho de cada caravana, não por quadro; a fração `u` que a ponte entrega é a fração dessa polilinha, e o ponto sai de `sample_into`
## (uma `Pose` só, reaproveitada). ALTURA: a do terreno (`peek_height`) sob os PÉS do comerciante (a origem do corpo); INCLINAÇÃO: a que liga os pés ao EIXO do carrinho, `CaravanView.CART_BACK_M` atrás ao longo da frente (as duas alturas em que o corpo
## rígido se apoia: o carrinho desce `CART_BACK_M * sen(inclinação)` e o comerciante inclina junto), limitada por `max_pitch_deg`. ALCANCE: a
## distância no plano do FOCO do jogador (o mesmo que a cena dá ao `TerrainView`: `focus()`) ao ponto DERIVADO (não à posição lógica do comerciante, que fica no mercado de partida), com histerese: entra a `enter_m` e só sai acima de `exit_m`
## (o dado de apresentação). Sem o terreno do chunk desenhado (`TerrainView.has_chunk`) o corpo fica ESCONDIDO e NENHUMA pose é aplicada (a última pose boa fica, e a altura nunca é inventada: rodas e pisada contam a distância 3D entre poses,
## então uma altura provisória seguida da real as giraria de uma vez); a pose é aplicada ANTES de mostrar, no mesmo quadro em que o terreno aparece. `CaravanView.apply_pose` mostra o corpo na 1ª pose, por isso `visible` é escrito DEPOIS dela, a cada quadro.
## ORDEM por quadro: as SAÍDAS (`give_back`) antes das ENTRADAS (`take`), depois estado e pose dos ativos. Quando a caravana some da consulta (a chegada) o corpo volta à reserva no mesmo quadro, e o `NpcView` do comerciante volta
## pelo LOD (o filtro da ponte tira o NPC em viagem de `peek_npc_bodies`). NUNCA dois corpos do mesmo comerciante: a reserva dá no máximo um `CaravanView` por `trader_id` e o `NpcView` do comerciante em viagem não existe.
## Reserva vazia: `take` devolve nulo, a reserva conta (`empty_hits`), `waiting` mostra quantas caravanas ficaram sem corpo e a próxima consulta tenta de novo. Consulta que falha: os corpos ficam como estão (UM aviso por sequência de
## falhas). Trecho sem mercado conhecido numa das pontas: sem estrada e sem corpo (`unplaced`). Pontos de passagem (`points_m`) no dado: ver `_via_of` (lacuna aberta). Contrato: docs/economia/contrato-lw-099-viagem-visivel.md, seções 2, 3 e 6.
## JUNTAS (LW-099c; medidas em tests/integration/test_caravan_visual_jumps.gd e tests/unit/test_caravan_bodies_view_joints.gd): o deslocamento lateral sobe de 0 nos primeiros `LATERAL_RAMP_M` metros e desce a 0 nos últimos, então a caravana sai e chega no
## EIXO da estrada (o mercado), onde o `NpcView` reaparece na chegada, e a troca de trecho não salta de lado; o giro anda no máximo `TURN_RAD_PER_M` radianos por metro andado entre duas poses (a primeira pose de uma caravana é o giro da estrada, sem limite), então a
## quina no povoado de passagem vira uma curva de poucos metros em vez de um estalo. Só a pose mostrada muda: a fração `u`, o tempo e a velocidade são os da simulação.
## CURVAS NATURAIS (LW-099f, EXPERIMENTAL; só apresentação; `set_natural_curves`, DESLIGADO por padrão: desligado nada disto roda e o jogo é o de hoje, bit a bit). Ligado, a estrada do trecho é uma `CaravanRoad` (retas e ARCOS no lugar da quina viva), o ponto é o da FAIXA a `s = u * comprimento da estrada` e a pose vem
## da `CaravanChain.cart_spec` (o comerciante e o carrinho como UM corpo rígido apoiado nos pés e no EIXO): o giro é o da corda entre os pés e o eixo, sem limite de giro por metro (a pose é função pura de `s`, não de estado entre quadros), e a inclinação usa a altura sob o EIXO real. O trecho que SAI de um povoado de passagem nasce reto na
## direção de chegada do anterior (`CaravanRoad.entering`) se a vista lembra dela: o trecho anterior terminou nesse povoado e a última `u` vista nele foi >= `ARRIVAL_MEMORY_U`; é memória da própria vista (nada vem da ponte). Sem ela (caravana vista pela 1ª vez no meio da viagem, trecho que mudou antes do fim) a estrada é a reta de sempre.

## [HIP] Metros andados (a partir de cada ponta do trecho) em que o deslocamento lateral sobe de 0 ao valor do dado e desce de volta: 4 s a 1x.
const LATERAL_RAMP_M: float = 12.0
## [HIP] Giro máximo (rad) por metro andado entre duas poses: 0,5 é uma curva de cerca de 2 m de raio (uma quina de 90 graus leva uns 3 m).
const TURN_RAD_PER_M: float = 0.5
## [HIP] CURVAS NATURAIS: o raio (m) do CAMINHO do veículo nas quinas; 6 m é a referência de Arthur para o veículo comprido (para o carrinho de hoje 3 m bastaria; os limites do estudo são 4,1 m duro, 8 e 10 m). A estrada é montada pelo EIXO e o veículo anda na FAIXA, `lateral_offset_m` à direita: numa quina para a direita a faixa fica DENTRO da curva
## (o raio dela é o do eixo menos a faixa) e numa para a esquerda FORA (o do eixo mais a faixa); por isso o eixo pede `raio do caminho + faixa` (6 + 1,2 = 7,2 m) e a curva pelo lado da faixa nunca fecha mais que o caminho pedido (pela esquerda ela abre, 8,4 m).
const CURVE_PATH_RADIUS_M: float = 6.0
## [HIP] A caravana "chegou" ao fim do trecho se a última fração `u` vista nele foi igual ou maior que isto: só então o trecho seguinte da mesma viagem herda a direção de chegada.
const ARRIVAL_MEMORY_U: float = 0.9

## Consultas que falharam (os corpos ficaram como estavam).
var failed_queries: int = 0
## Caravanas sem estrada no último `reconcile` (povoado de saída ou de chegada sem mercado conhecido): ficam sem corpo.
var unplaced: int = 0
## Caravanas no alcance que ficaram sem corpo no último `reconcile` (reserva vazia).
var waiting: int = 0
## Quadros em que a altura do ponto não pôde ser lida (a pose daquele corpo não mudou).
var ground_misses: int = 0

var _bridge: SimBridge
var _terrain: TerrainView
var _routes: CaravanRoutesReader
var _pool: CaravanViewPool
var _chunk_size_m: float = 0.0
var _chunk_count: Vector2i = Vector2i.ZERO
## O mercado (x, z em metros) de cada povoado: as pontas da estrada.
var _markets: Dictionary[String, Vector2] = {}
## O que a view guarda de cada caravana vista (por `trader_id`): a estrada do trecho, a pose do quadro e se está no alcance.
var _tracks: Dictionary[int, Track] = {}
## Rotas com pontos de passagem no dado que já foram avisadas (UM aviso por rota).
var _warned_routes: Dictionary[String, bool] = {}
## Os `trader_id` que sumiram da consulta neste quadro (reaproveitado).
var _gone: Array[int] = []
var _pose: CaravanPath.Pose = CaravanPath.Pose.new()
var _stamp: int = 0
var _is_active: bool = false
var _is_failing: bool = false
## CURVAS NATURAIS: o modo (nasce DESLIGADO), o raio do caminho do veículo (m; 0 = quinas vivas) e o veículo e as poses dele, criados UMA vez na 1ª vez que o modo liga.
var _natural_curves: bool = false
var _curve_radius_m: float = CURVE_PATH_RADIUS_M
var _cart: CaravanChain.Spec
var _poses: Array[CaravanChain.RigidPose] = []


## Liga a view à ponte, ao terreno (o foco do jogador e os chunks desenhados) e ao dado de apresentação (`routes`, já carregado), lê os mercados e cria a reserva de corpos (`routes.pool_size`, escondidos). Nenhum pedido à simulação.
## Qualquer um dos três nulo (ou o dado não carregado), terreno ou locais indisponíveis, ou nenhum mercado: push_error, nenhum corpo e a view fica inativa (devolve falso).
func setup(bridge: SimBridge, terrain: TerrainView, routes: CaravanRoutesReader) -> bool:
	_clear()
	if bridge == null or terrain == null or routes == null or not routes.is_ready():
		push_error("CaravanBodiesView.setup: ponte, TerrainView ou dado de apresentação nulo ou não carregado; esperado os três.")
		return false
	var layout: BridgeReplies.TerrainLayoutReply = bridge.peek_terrain_layout()
	if not layout.result.ok:
		return _fail("formato do terreno indisponível", layout.result)
	var places: BridgeReplies.PlacesReply = bridge.peek_places()
	if not places.result.ok:
		return _fail("locais indisponíveis", places.result)
	for place: BridgeReplies.PlaceReply in places.places:
		if place.kind == PlacePalette.KIND_MARKET and not _markets.has(place.settlement_id):
			_markets[place.settlement_id] = Vector2(place.x, place.z)
	if _markets.is_empty():
		push_error("CaravanBodiesView.setup: nenhum mercado nos locais; sem as pontas não há estrada.")
		return false
	_bridge = bridge
	_terrain = terrain
	_routes = routes
	_chunk_size_m = float(layout.chunk_cells) * layout.cell_size_m
	_chunk_count = layout.chunk_count
	_pool = CaravanViewPool.new(self, routes)
	_is_active = true
	return true


## Põe os corpos em dia com a simulação: devolve os de quem saiu do alcance ou chegou, entrega os de quem entrou e aplica estado e pose em todos os ativos. Consulta que falha: nada muda.
func reconcile() -> void:
	if not _is_active:
		return
	var reply: BridgeReplies.CaravanBodiesReply = _bridge.peek_caravan_bodies()
	if not reply.result.ok:
		_note_failure(reply.result)
		return
	_is_failing = false
	_stamp += 1
	unplaced = 0
	waiting = 0
	var focus_m: Vector2 = _terrain.focus()
	for row: BridgeReplies.CaravanBodyReply in reply.bodies:
		if row.trader_id > IdGenerator.NO_ID:
			_locate(row, focus_m)
	_give_back_leavers()
	_take_newcomers(reply)
	_apply_to_active(reply)


## Devolve todos os corpos à reserva e deixa a view inativa (a reserva e os corpos escondidos seguem como filhos). Não faz nada se a view está inativa.
func release() -> void:
	if not _is_active:
		return
	_is_active = false
	for trader_id: int in _pool.active_ids():
		_pool.give_back(trader_id)
	_tracks.clear()


func is_active() -> bool:
	return _is_active


## IDs dos comerciantes com corpo, em ordem crescente.
func active_ids() -> Array[int]:
	var ids: Array[int] = []
	if _pool != null:
		ids = _pool.active_ids()
	return ids


## O corpo da caravana do comerciante, ou nulo se ele não tem.
func body_of(trader_id: int) -> CaravanView:
	return _pool.body_of(trader_id) if _pool != null else null


## A reserva de corpos (contadores de criados, retirados, devolvidos, pico, reserva vazia e duplicados); nula antes de um `setup` que deu certo.
func pool() -> CaravanViewPool:
	return _pool


## Liga ou desliga as CURVAS NATURAIS (ver o cabeçalho; padrão: desligado). Trocar o modo descarta as estradas já montadas e a memória de chegada dos trechos em andamento (refeitas no próximo `reconcile`, sem memória: retas) e põe as rodas dos corpos no modo certo; não precisa de `setup` nem de pose.
func set_natural_curves(enabled: bool) -> void:
	if enabled == _natural_curves:
		return
	_natural_curves = enabled
	if enabled and _cart == null:
		_cart = CaravanChain.cart_spec()
		_poses = CaravanChain.make_poses(_cart)
	if not enabled:
		for child: Node in get_children():
			var body: CaravanView = child as CaravanView
			if body != null:
				body.set_wheel_differential(false)
	_discard_roads(true)


func natural_curves() -> bool:
	return _natural_curves


## O raio (m) do CAMINHO do veículo nas quinas das curvas naturais (padrão `CURVE_PATH_RADIUS_M`); não finito ou negativo vira 0: quinas vivas, sem arco. Trocar o raio, com o modo ligado, descarta as estradas montadas (refeitas no próximo `reconcile`; a direção de chegada do trecho em andamento é lembrada). Desligado, só guarda o valor.
func set_curve_radius_m(radius_m: float) -> void:
	var radius: float = radius_m if is_finite(radius_m) and radius_m > 0.0 else 0.0
	if radius == _curve_radius_m:
		return
	_curve_radius_m = radius
	if _natural_curves:
		_discard_roads(false)


func curve_radius_m() -> float:
	return _curve_radius_m


## A estrada com arcos do trecho atual da caravana (só nas curvas naturais), ou nulo: modo desligado, caravana desconhecida ou trecho sem estrada. Só leitura, para testes e diagnóstico.
func road_of(trader_id: int) -> CaravanRoad:
	var track: Track = _tracks.get(trader_id) as Track
	return track.road if track != null else null


func _process(_delta: float) -> void:
	reconcile()


func _exit_tree() -> void:
	release()


## Acha ou cria o registro da caravana, garante a estrada do trecho e decide o alcance com histerese a partir do ponto DERIVADO. Sem estrada a caravana não entra no alcance.
func _locate(row: BridgeReplies.CaravanBodyReply, focus_m: Vector2) -> void:
	var track: Track = _tracks.get(row.trader_id) as Track
	if track == null:
		track = Track.new()
		_tracks[row.trader_id] = track
	track.seen = _stamp
	if not (_locate_on_road(track, row) if _natural_curves else _locate_on_path(track, row)):
		track.inside = false
		unplaced += 1
		return
	var gap_m: float = track.position.distance_to(focus_m)
	track.inside = gap_m <= _routes.enter_m or (track.inside and gap_m <= _routes.exit_m)


## As saídas: o corpo de quem saiu do alcance volta à reserva, e quem sumiu da consulta (chegou, ou morreu na estrada) perde corpo e registro.
func _give_back_leavers() -> void:
	_gone.clear()
	for trader_id: int in _tracks:
		var track: Track = _tracks[trader_id]
		if track.seen != _stamp:
			_gone.append(trader_id)
		elif not track.inside and _pool.give_back(trader_id):
			track.posed = false
	for trader_id: int in _gone:
		_pool.give_back(trader_id)
		_tracks.erase(trader_id)


## As entradas, em ordem crescente de comerciante (a da consulta): quem está no alcance e não tem corpo pega um. Reserva vazia: sem erro, `waiting` conta e o próximo quadro tenta de novo.
func _take_newcomers(reply: BridgeReplies.CaravanBodiesReply) -> void:
	for row: BridgeReplies.CaravanBodyReply in reply.bodies:
		var track: Track = _tracks.get(row.trader_id) as Track
		if track == null or not track.inside or _pool.body_of(row.trader_id) != null:
			continue
		if _pool.take(row.trader_id) == null:
			waiting += 1


## Estado (andando ou parada, carga) e pose de cada corpo ativo. O corpo só tem pose, e só aparece, com o terreno do chunk desenhado e depois da primeira pose; sem o terreno nenhuma pose é aplicada.
func _apply_to_active(reply: BridgeReplies.CaravanBodiesReply) -> void:
	for row: BridgeReplies.CaravanBodyReply in reply.bodies:
		var view: CaravanView = _pool.body_of(row.trader_id)
		if view == null:
			continue
		var track: Track = _tracks[row.trader_id]
		view.apply_state(row.state == BridgeReplies.CaravanBodyReply.STATE_TRAVELLING, row.good_id, row.load_permille)
		if _natural_curves:
			view.set_wheel_differential(true)
		var is_drawn: bool = _terrain.has_chunk(_chunk_of(track.position))
		if is_drawn:
			if _natural_curves:
				_pose_on_road(view, track)
			else:
				_pose_on_ground(view, track)
		view.visible = is_drawn and track.posed


## Põe o corpo no chão: os pés na altura do terreno no ponto e a inclinação que liga os pés ao eixo do carrinho (ver o cabeçalho), limitada por `max_pitch_deg`. Altura dos pés ilegível: a pose não muda neste quadro (contada); altura do eixo
## ilegível: nivelado.
func _pose_on_ground(view: CaravanView, track: Track) -> void:
	var feet_m: float = _ground_at(track.position)
	if is_nan(feet_m):
		ground_misses += 1
		return
	var behind: Vector2 = Vector2(sin(track.yaw), cos(track.yaw)) * CaravanView.CART_BACK_M
	var pitch: float = CaravanPath.pitch_from_heights(_ground_at(track.position + behind), feet_m, CaravanView.CART_BACK_M, _routes.max_pitch_deg)
	view.apply_pose(Vector3(track.position.x, feet_m, track.position.y), track.yaw, pitch)
	track.posed = true


## O modo de sempre: o ponto e o giro (limitado por metro andado) da polilinha do trecho. Falso se o trecho não tem estrada.
func _locate_on_path(track: Track, row: BridgeReplies.CaravanBodyReply) -> bool:
	if not _follow_leg(track, row):
		return false
	track.path.sample_into(row.u, true, _routes.lateral_offset_m, _pose, LATERAL_RAMP_M)
	track.yaw = _turned(track.yaw, _pose.yaw, track.position.distance_to(_pose.position)) if track.has_yaw else _pose.yaw
	track.has_yaw = true
	track.position = _pose.position
	return true


## CURVAS NATURAIS: o ponto da FAIXA a `s = u * comprimento da estrada` (é ele que decide o alcance e o chunk); `u` fora de 0 a 1 é cortado e NaN conta como 0. Falso se o trecho não tem estrada.
func _locate_on_road(track: Track, row: BridgeReplies.CaravanBodyReply) -> bool:
	if not _follow_road(track, row):
		return false
	track.last_u = 0.0 if is_nan(row.u) else clampf(row.u, 0.0, 1.0)
	track.s_m = track.last_u * track.road.length_m()
	track.position = track.road.sample(track.s_m)
	return true


## CURVAS NATURAIS: garante a estrada do trecho atual, montada de novo SÓ quando o trecho muda (ou depois de descartada). O trecho novo que sai do povoado onde o anterior terminou (a última `u` vista nele >= `ARRIVAL_MEMORY_U`) nasce reto na direção de chegada
## do anterior (`CaravanRoad.entering`); sem essa memória é a reta do mercado de saída ao de chegada (os pontos de passagem do dado seguem ignorados, com o mesmo aviso). Sempre com a faixa `lateral_offset_m` e a rampa SUAVE (`LATERAL_RAMP_M`, no máximo a metade do
## trecho: sem dobra). Falso se um dos povoados não tem mercado conhecido ou a estrada não tem comprimento.
func _follow_road(track: Track, row: BridgeReplies.CaravanBodyReply) -> bool:
	var same_leg: bool = track.route_id == row.route_id and track.from_id == row.from_settlement_id and track.to_id == row.to_settlement_id
	if same_leg and track.road != null:
		return true
	if not same_leg:
		var arrived: bool = track.road != null and track.to_id == row.from_settlement_id and track.last_u >= ARRIVAL_MEMORY_U
		track.arrival = track.road.end_tangent() if arrived else Vector2.ZERO
		track.route_id = row.route_id
		track.from_id = row.from_settlement_id
		track.to_id = row.to_settlement_id
	track.road = null
	if not _markets.has(row.from_settlement_id) or not _markets.has(row.to_settlement_id):
		return false
	var start: Vector2 = _markets[row.from_settlement_id]
	var finish: Vector2 = _markets[row.to_settlement_id]
	var line: PackedVector2Array = PackedVector2Array([start])
	line.append_array(_via_of(row.route_id))
	line.append(finish)
	var radius_m: float = _axis_radius_m()
	var road: CaravanRoad = CaravanRoad.entering(track.arrival, start, finish, radius_m) if track.arrival != Vector2.ZERO else CaravanRoad.through(line, radius_m)
	if road.length_m() <= 0.0:
		return false
	track.road = road.with_lane(_routes.lateral_offset_m, minf(LATERAL_RAMP_M, 0.5 * road.length_m()))
	return true


## O raio do EIXO que se pede à estrada: o do caminho mais a faixa (a conta está em `CURVE_PATH_RADIUS_M`); raio do caminho 0 são quinas vivas.
func _axis_radius_m() -> float:
	return (_curve_radius_m + absf(_routes.lateral_offset_m)) if _curve_radius_m > 0.0 else 0.0


## CURVAS NATURAIS: o corpo no chão. Os pés ficam no ponto da faixa (na altura do terreno), o giro é o da corda entre os pés e o EIXO do carrinho (`CaravanChain`, função pura de `s`) e a inclinação liga a altura dos pés à do terreno sob o EIXO real. Altura dos pés ilegível: a pose não muda (contada).
func _pose_on_road(view: CaravanView, track: Track) -> void:
	if track.road == null:
		return
	var feet_m: float = _ground_at(track.position)
	if is_nan(feet_m):
		ground_misses += 1
		return
	CaravanChain.poses_into(track.road, _cart, track.s_m, _poses)
	var body: CaravanChain.RigidPose = _poses[0]
	var axle: Vector2 = body.at_lead_frame(-CaravanView.CART_BACK_M)
	var pitch: float = CaravanPath.pitch_from_heights(_ground_at(axle), feet_m, CaravanView.CART_BACK_M, _routes.max_pitch_deg)
	view.apply_pose(Vector3(track.position.x, feet_m, track.position.y), body.yaw(), pitch)
	track.posed = true


## Esquece as estradas com arcos montadas; `switch_mode` (troca de modo) esquece também a polilinha, o giro e a memória de chegada. A próxima consulta monta tudo de novo, no modo e com o raio de agora.
func _discard_roads(switch_mode: bool) -> void:
	for trader_id: int in _tracks:
		var track: Track = _tracks[trader_id]
		track.road = null
		if switch_mode:
			track.path = null
			track.has_yaw = false
			track.arrival = Vector2.ZERO
			track.last_u = 0.0


## A altura do terreno no ponto (x, z), ou NAN se a ponte não a der.
func _ground_at(point: Vector2) -> float:
	var ground: BridgeReplies.HeightReply = _bridge.peek_height(point.x, point.y)
	return ground.height_m if ground.result.ok else NAN


## Garante a estrada do trecho atual (a polilinha do mercado de saída ao de chegada), montada de novo SÓ quando o trecho muda. Falso se um dos dois povoados não tem mercado conhecido (ou a estrada não tem comprimento).
func _follow_leg(track: Track, row: BridgeReplies.CaravanBodyReply) -> bool:
	if track.path != null and track.route_id == row.route_id and track.from_id == row.from_settlement_id and track.to_id == row.to_settlement_id:
		return true
	track.route_id = row.route_id
	track.from_id = row.from_settlement_id
	track.to_id = row.to_settlement_id
	track.path = null
	if not _markets.has(row.from_settlement_id) or not _markets.has(row.to_settlement_id):
		return false
	var road: CaravanPath = CaravanPath.through(_markets[row.from_settlement_id], _via_of(row.route_id), _markets[row.to_settlement_id])
	track.path = road if road.length_m() > 0.0 else null
	return track.path != null


## Os pontos de passagem da estrada, no sentido da marcha. LACUNA ABERTA: o dado os guarda de `settlement_a_id` para `settlement_b_id`, e a ponte (`peek_caravan_bodies`) só diz de onde para onde o trecho vai, não qual povoado é o `a` da rota,
## então não dá para saber se é preciso invertê-los. Sem pontos (o dado de hoje, as três rotas) a estrada é a reta e o sentido não importa; COM pontos a estrada cai na reta e UM aviso por rota diz o porquê, em vez de desenhar o caminho de trás
## para a frente. A correção está no relatório da LW-099b2b (a ponte informar o sentido do trecho em relação à rota).
func _via_of(route_id: String) -> PackedVector2Array:
	var stored: PackedVector2Array = _routes.points_of(route_id)
	if not stored.is_empty() and not _warned_routes.has(route_id):
		_warned_routes[route_id] = true
		push_warning("CaravanBodiesView: a rota '%s' tem pontos de passagem, mas a ponte não diz o sentido do trecho em relação a ela; a estrada fica reta até isso existir." % route_id)
	return PackedVector2Array()


## O giro `from` levado até `to` pelo lado mais curto, no máximo `TURN_RAD_PER_M` por metro andado (`travelled_m`): sem andar, o giro não muda. Resultado entre -PI e PI.
static func _turned(from: float, to: float, travelled_m: float) -> float:
	var limit: float = TURN_RAD_PER_M * travelled_m
	return wrapf(from + clampf(angle_difference(from, to), -limit, limit), -PI, PI)


## O chunk do terreno sob o ponto (x, z), limitado ao mapa (a conta do `NpcBodiesView`).
func _chunk_of(point: Vector2) -> Vector2i:
	return Vector2i(clampi(floori(point.x / _chunk_size_m), 0, _chunk_count.x - 1), clampi(floori(point.y / _chunk_size_m), 0, _chunk_count.y - 1))


## Consulta que falhou: os corpos ficam como estão; UM aviso por sequência de falhas (nunca um por quadro).
func _note_failure(failure: Result) -> void:
	failed_queries += 1
	if not _is_failing:
		_is_failing = true
		push_warning("CaravanBodiesView.reconcile: caravanas indisponíveis (%s): %s Os corpos ficam como estão até a consulta voltar." % [failure.code, failure.message])


func _fail(what: String, failure: Result) -> bool:
	push_error("CaravanBodiesView.setup: %s (%s): %s" % [what, failure.code, failure.message])
	return false


## Solta a reserva antiga (os corpos são filhos desta view), esquece o que viu e deixa a view inativa.
func _clear() -> void:
	release()
	for child: Node in get_children():
		remove_child(child)
		child.free()
	_pool = null
	_tracks.clear()
	_markets.clear()
	_warned_routes.clear()
	_is_failing = false
	failed_queries = 0
	unplaced = 0
	waiting = 0
	ground_misses = 0


## O que a view guarda de UMA caravana vista: o trecho (rota e povoados) cuja estrada está montada, a pose (x, z e giro) do último quadro, se está no alcance, se o corpo que ela tem agora já recebeu a primeira pose e em que
## consulta foi vista (quem não foi vista na última chegou).
class Track:
	extends RefCounted

	var seen: int = 0
	var inside: bool = false
	var posed: bool = false
	## O giro já tem um valor de uma amostra anterior (a primeira amostra de uma caravana não é limitada).
	var has_yaw: bool = false
	var route_id: String = ""
	var from_id: String = ""
	var to_id: String = ""
	var path: CaravanPath
	var position: Vector2 = Vector2.ZERO
	var yaw: float = 0.0
	## CURVAS NATURAIS (nada disto é lido no modo de sempre): a estrada com arcos do trecho, a distância andada sobre o EIXO dela, a última fração `u` vista e a direção de chegada que o trecho herdou (zero: nenhuma).
	var road: CaravanRoad
	var s_m: float = 0.0
	var last_u: float = 0.0
	var arrival: Vector2 = Vector2.ZERO
