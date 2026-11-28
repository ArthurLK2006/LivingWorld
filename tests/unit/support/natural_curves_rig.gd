class_name NaturalCurvesRig
extends RefCounted
## Ajudante dos testes das curvas naturais da `CaravanBodiesView` (LW-099f, experimental): o mundo REAL de teste (terreno, locais e dado de apresentação), a ponte roteirizada, o terreno desenhado em volta do foco e a vista; mais as contas de REFERÊNCIA da estrada reta (a faixa e a corda do
## carrinho), escritas aqui em duplas e sem usar a estrada que se testa. Convenção: quem anda de `from` a `to` tem a faixa à DIREITA, `Vector2(-dir.y, dir.x)`; o giro é o do jogo, `atan2(-dir.x, -dir.y)`.

const WORLD_DIR: String = "res://data/world"
const A: String = "test_settlement_a"
const B: String = "test_settlement_b"
const C: String = "test_settlement_c"
const TRADER: int = 100
const OTHER: int = 101
## Os mercados dos três povoados (data/world/places.json, em metros).
const MARKETS: Dictionary[String, Vector2] = {A: Vector2(313.0, 556.0), B: Vector2(807.0, 653.0), C: Vector2(567.0, 853.0)}
const GROUND_M: float = 10.0
const CHUNK_M: float = 64.0
## A faixa e a rampa [HIP] do dado e da vista; o passeio a 2,9 m/s a 1x e o quadro de 1/60 s.
const LANE_M: float = 1.2
const RAMP_M: float = 12.0
const WALK_MPS: float = 2.9
const FRAME_S: float = 1.0 / 60.0
const SEARCH_ITERATIONS: int = 60
## A varredura fina da velocidade da faixa: o passo da amostra e a diferença (m); a diferença é larga de propósito (o `Vector2` é float32: 3e-5 m de ruído).
const SPEED_STEP_M: float = 0.25
const SPEED_SPAN_M: float = 0.25

var failure: String = ""
var terrain: TerrainData
var places: Array[Place] = []
var routes: CaravanRoutesReader
var bridge: ScriptedCaravanBridge
var terrain_view: TerrainView
var view: CaravanBodiesView
var _custom: bool = false


## Carrega o mundo de teste e o dado de apresentação; `failure` diz o que falhou (vazio = tudo certo).
static func load_world() -> NaturalCurvesRig:
	var rig: NaturalCurvesRig = NaturalCurvesRig.new()
	var loaded_terrain: TerrainLoader.LoadResult = TerrainLoader.load_dir(WORLD_DIR)
	if not loaded_terrain.result.ok:
		rig.failure = loaded_terrain.result.message
		return rig
	rig.terrain = loaded_terrain.terrain
	var settlements: SettlementLoader.LoadResult = SettlementLoader.load_dir(WORLD_DIR, rig.terrain)
	if not settlements.result.ok:
		rig.failure = settlements.result.message
		return rig
	rig.places = settlements.places
	var loaded_routes: CaravanRoutesReader.LoadResult = CaravanRoutesReader.from_file()
	if not loaded_routes.result.ok:
		rig.failure = loaded_routes.result.message
		return rig
	rig.routes = loaded_routes.data
	return rig


## Monta a ponte, o terreno e a vista (filhos do teste `host`, soltos no fim dele), com o modo das curvas naturais posto ANTES do `setup`; `only_places` troca os locais do mundo por outros (estradas de teste). Chamado de novo no MESMO teste com os locais do mundo, reaproveita a ponte e o
## terreno já desenhado (zera as linhas, o declive e a cegueira) e só cria uma vista nova.
func start(host: GutTest, natural: bool = true, only_places: Array[Place] = []) -> bool:
	var reuse: bool = only_places.is_empty() and not _custom and terrain_view != null and is_instance_valid(terrain_view) and terrain_view.get_parent() == host
	if view != null and is_instance_valid(view):
		view.free()
	if reuse:
		bridge.rows.clear()
		bridge.slope_x = 0.0
		bridge.is_blind = false
		bridge.is_failing = false
	else:
		_custom = not only_places.is_empty()
		bridge = ScriptedCaravanBridge.new(null, terrain, only_places if _custom else places)
		terrain_view = TerrainView.new()
		host.add_child_autofree(terrain_view)
		terrain_view.setup(bridge)
		terrain_view.set_process(false)
	view = CaravanBodiesView.new()
	host.add_child_autofree(view)
	view.set_natural_curves(natural)
	return view.setup(bridge, terrain_view, routes)


## Desenha o terreno em volta do foco (o chunk dele e os oito vizinhos), põe as linhas `rows` na ponte, o foco do jogador ali (todas no alcance) e consulta.
func show(rows: Array, focus_m: Vector2) -> void:
	var center: Vector2i = Vector2i(floori(focus_m.x / CHUNK_M), floori(focus_m.y / CHUNK_M))
	for dz: int in range(-1, 2):
		for dx: int in range(-1, 2):
			var coord: Vector2i = center + Vector2i(dx, dz)
			if not terrain_view.has_chunk(coord):
				terrain_view.build_chunk(coord)
	bridge.rows.assign(rows)
	terrain_view.set_focus(Vector3(focus_m.x, GROUND_M, focus_m.y))
	view.reconcile()


## Mostra UMA caravana no trecho de `from_id` a `to_id` na fração `u` (o foco no ponto da estrada reta), consulta e devolve o corpo dela (nulo se não tem).
func go(from_id: String, to_id: String, u: float, trader_id: int = TRADER, state: String = BridgeReplies.CaravanBodyReply.STATE_TRAVELLING) -> CaravanView:
	var along: float = 0.0 if is_nan(u) else clampf(u, 0.0, 1.0)
	show([ScriptedCaravanBridge.row_of(trader_id, u, route_of(from_id, to_id), from_id, to_id, state)], MARKETS[from_id].lerp(MARKETS[to_id], along))
	return view.body_of(trader_id)


## A rota (do dado) que liga dois povoados, em qualquer sentido.
static func route_of(x: String, y: String) -> String:
	return "route_%s_%s" % [x.right(1), y.right(1)] if x < y else "route_%s_%s" % [y.right(1), x.right(1)]


static func spot_of(body: CaravanView) -> Vector2:
	return Vector2(body.position.x, body.position.z)


## O giro de quem anda na direção `heading`.
static func yaw_of(heading: Vector2) -> float:
	return atan2(-heading.x, -heading.y)


## O fator da faixa (0 a 1) a `s` metros de uma estrada de `length_m`: smoothstep da distância à ponta mais próxima, valendo também antes de 0 e depois do fim.
static func lane_factor(s: float, length_m: float) -> float:
	return smoothstep(0.0, RAMP_M, minf(absf(s), absf(s - length_m)))


## O ponto da FAIXA da estrada reta de `from` a `to`, a `s` metros do começo.
static func lane_point(from: Vector2, to: Vector2, s: float) -> Vector2:
	var dir: Vector2 = (to - from).normalized()
	return from + dir * s + Vector2(-dir.y, dir.x) * (LANE_M * lane_factor(s, from.distance_to(to)))


## O quanto um ponto está FORA da faixa da estrada reta (m, na direção da direita da marcha): zero é sobre a faixa.
static func lane_error_m(from: Vector2, to: Vector2, point: Vector2) -> float:
	var dir: Vector2 = (to - from).normalized()
	var rel: Vector2 = point - from
	return absf(rel.dot(Vector2(-dir.y, dir.x)) - LANE_M * lane_factor(rel.dot(dir), from.distance_to(to)))


## O apoio de trás do carrinho na estrada reta: o ponto da faixa a `CART_BACK_M` de CORDA atrás dos pés em `s` (bisseção).
static func rear_point(from: Vector2, to: Vector2, s: float) -> Vector2:
	var feet: Vector2 = lane_point(from, to, s)
	var near_s: float = s
	var far_s: float = s - CaravanView.CART_BACK_M - 1.0
	for _step: int in SEARCH_ITERATIONS:
		var middle: float = 0.5 * (near_s + far_s)
		if lane_point(from, to, middle).distance_to(feet) < CaravanView.CART_BACK_M:
			near_s = middle
		else:
			far_s = middle
	return lane_point(from, to, 0.5 * (near_s + far_s))


## O maior `|d sample / d s|` da FAIXA da estrada (quanto o ponto da faixa anda por metro de eixo andado), por varredura fina; no mínimo 1.
static func max_lane_speed(road: CaravanRoad) -> float:
	var worst: float = 1.0
	var s: float = 0.0
	while s <= road.length_m():
		worst = maxf(worst, road.sample(s + SPEED_SPAN_M).distance_to(road.sample(s)) / SPEED_SPAN_M)
		s += SPEED_STEP_M
	return worst
