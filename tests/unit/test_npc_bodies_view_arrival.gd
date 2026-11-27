extends GutTest
## LW-099h (chegada suave; só apresentação): o NASCIMENTO do corpo no ponto de chegada, no `NpcBodiesView`, sem janela, com uma ponte roteirizada (os corpos que a ponte manda são os do teste; formato do terreno e altura, os reais). Sem fonte, ou com ponto que não vale, o corpo nasce
## onde a ponte manda, BIT A BIT como sempre; com um ponto que vale (a mais de 0,25 m e a no máximo 15 m da posição da ponte) nasce nele, com os pés na altura do terreno AQUI (nunca a de lá). A fonte só é perguntada quando o corpo nasce (não por quadro) e uma vez por corpo.

const WORLD_DIR: String = "res://data/world"
const NPC: int = 7
const OTHER_NPC: int = 8
## O centro do mercado (a posição lógica) e uma doca a 6 m dele.
const LOGICAL: Vector3 = Vector3(807.0, 10.0, 653.0)
const DOCK: Vector2 = Vector2(801.0, 653.0)
const SLOPE_PER_M: float = 0.01
const JUST_INSIDE_M: float = 0.26
const JUST_OUTSIDE_M: float = 15.01
const AT_THE_LIMIT_M: float = 15.0
const AT_THE_FLOOR_M: float = 0.25
const ONE_CM: float = 0.01

var _terrain: TerrainData
var _places: Array[Place] = []
var _bridge: BodiesBridge
var _terrain_view: TerrainView
var _view: NpcBodiesView
## O que a fonte devolve por NPC (sem entrada: sem ponto) e quem ela foi perguntada, na ordem.
var _spots: Dictionary[int, Variant] = {}
var _asked: Array[int] = []


## Ponte roteirizada: `bodies` são os corpos de `peek_npc_bodies` e o interruptor de corpos aceita tudo; a altura (com rampa e cegueira de `ScriptedCaravanBridge`) é a do terreno real.
class BodiesBridge:
	extends ScriptedCaravanBridge

	var bodies: Array[BridgeReplies.NpcBodyReply] = []

	func peek_npc_bodies() -> BridgeReplies.NpcBodiesReply:
		return BridgeReplies.NpcBodiesReply.new(Result.success(), bodies)

	func request_set_bodies_available(_available: bool) -> Result:
		return Result.success()


func before_all() -> void:
	var terrain: TerrainLoader.LoadResult = TerrainLoader.load_dir(WORLD_DIR)
	assert_true(terrain.result.ok, terrain.result.message)
	_terrain = terrain.terrain
	var settlements: SettlementLoader.LoadResult = SettlementLoader.load_dir(WORLD_DIR, _terrain)
	assert_true(settlements.result.ok, settlements.result.message)
	_places = settlements.places


func before_each() -> void:
	_spots.clear()
	_asked.clear()
	_bridge = BodiesBridge.new(null, _terrain, _places)
	_terrain_view = TerrainView.new()
	add_child_autofree(_terrain_view)
	_terrain_view.setup(_bridge)
	_terrain_view.set_process(false)
	_view = NpcBodiesView.new()
	add_child_autofree(_view)
	assert_true(_view.setup(_bridge, _terrain_view))


## A fonte do teste: devolve o que `_spots` guarda para o NPC (ou o `NO_SPOT`) e lembra quem perguntou.
func _source(npc_id: int) -> Variant:
	_asked.append(npc_id)
	return _spots.get(npc_id, CaravanBodiesView.NO_SPOT)


func _enter(npc_ids: Array[int], logical: Vector3 = LOGICAL) -> void:
	var rows: Array[BridgeReplies.NpcBodyReply] = []
	for npc_id: int in npc_ids:
		rows.append(BridgeReplies.NpcBodyReply.new(npc_id, logical))
	_bridge.bodies.assign(rows)
	_view.reconcile()


## O ponto a `gap_m` metros da posição lógica, para o lado da doca.
func _spot_at(gap_m: float) -> Vector2:
	return Vector2(LOGICAL.x - gap_m, LOGICAL.z)


func test_without_a_source_the_body_is_born_where_the_bridge_says_bit_for_bit() -> void:
	assert_false(_view.has_arrival_spots(), "Premissa: nenhuma fonte ligada (o padrão).")
	_enter([NPC])
	assert_eq(_view.pool().body_of(NPC).position, LOGICAL, "Sem fonte: a posição da ponte, igual a antes.")


func test_a_valid_spot_moves_the_birth_to_the_dock_with_the_feet_on_the_ground_there() -> void:
	_bridge.slope_x = SLOPE_PER_M
	_view.set_arrival_spots(_source)
	assert_true(_view.has_arrival_spots(), "A fonte ficou ligada.")
	_spots[NPC] = DOCK
	var logical: Vector3 = Vector3(LOGICAL.x, _bridge.peek_height(LOGICAL.x, LOGICAL.z).height_m, LOGICAL.z)
	_enter([NPC], logical)
	var ground_m: float = _bridge.peek_height(DOCK.x, DOCK.y).height_m
	assert_ne(ground_m, logical.y, "Premissa: com a rampa a altura na doca é outra que a do centro.")
	assert_eq(_view.pool().body_of(NPC).position, Vector3(DOCK.x, ground_m, DOCK.y), "O corpo nasce na doca, na altura do terreno da doca.")
	_view.reconcile()
	_view.reconcile()
	assert_eq(_asked, [NPC] as Array[int], "A fonte é perguntada UMA vez, quando o corpo nasce (não a cada quadro).")
	assert_eq(_view.active_ids(), [NPC] as Array[int], "E há um corpo só.")


func test_a_spot_on_the_logical_position_is_ignored_so_the_data_of_today_changes_nothing() -> void:
	_view.set_arrival_spots(_source)
	_spots[NPC] = Vector2(LOGICAL.x + ONE_CM * 0.5, LOGICAL.z)
	_spots[OTHER_NPC] = _spot_at(AT_THE_FLOOR_M)
	_enter([NPC, OTHER_NPC])
	assert_eq(_view.pool().body_of(NPC).position, LOGICAL, "Meio centímetro da posição lógica (o arredondamento do `x_cm`): é o mesmo lugar, nasce na posição da ponte, bit a bit.")
	assert_eq(_view.pool().body_of(OTHER_NPC).position, LOGICAL, "Exatamente no piso (0,25 m) ainda não vale: o ponto precisa ficar a MAIS que isso.")
	_spots[NPC] = _spot_at(JUST_INSIDE_M)
	_view.release()
	assert_true(_view.setup(_bridge, _terrain_view), "Nova ligação para nascer de novo.")
	_view.set_arrival_spots(_source)
	_enter([NPC])
	assert_almost_eq(_view.pool().body_of(NPC).position.x, LOGICAL.x - JUST_INSIDE_M, ONE_CM * 0.1, "Logo acima do piso o ponto vale.")


func test_a_spot_too_far_from_the_logical_position_is_ignored() -> void:
	_view.set_arrival_spots(_source)
	_spots[NPC] = _spot_at(AT_THE_LIMIT_M)
	_spots[OTHER_NPC] = _spot_at(JUST_OUTSIDE_M)
	_enter([NPC, OTHER_NPC])
	assert_eq(_view.pool().body_of(NPC).position.x, LOGICAL.x - AT_THE_LIMIT_M, "A 15 m (o limite) o ponto ainda vale.")
	assert_eq(_view.pool().body_of(OTHER_NPC).position, LOGICAL, "Mais longe que isso o corpo nunca nasce: fica onde a simulação o põe.")


func test_a_bad_answer_or_an_unreadable_ground_falls_back_to_the_bridge_position() -> void:
	_view.set_arrival_spots(_source)
	_spots[NPC] = Vector2(NAN, 1.0)
	_spots[OTHER_NPC] = "not a vector"
	_enter([NPC, OTHER_NPC])
	assert_eq(_view.pool().body_of(NPC).position, LOGICAL, "Ponto não finito: a posição da ponte.")
	assert_eq(_view.pool().body_of(OTHER_NPC).position, LOGICAL, "Resposta que não é um ponto: a posição da ponte.")
	_view.release()
	assert_true(_view.setup(_bridge, _terrain_view))
	assert_false(_view.has_arrival_spots(), "Um novo `setup` solta a fonte (ligue depois dele).")
	_view.set_arrival_spots(_source)
	_spots[NPC] = DOCK
	_bridge.is_blind = true
	_enter([NPC])
	assert_eq(_view.pool().body_of(NPC).position, LOGICAL, "Altura do terreno ilegível na doca: a posição da ponte (a altura nunca é inventada).")


func test_only_the_merchant_who_has_a_spot_is_moved_and_nobody_gets_two_bodies() -> void:
	_view.set_arrival_spots(_source)
	_spots[NPC] = DOCK
	_enter([NPC, OTHER_NPC])
	assert_eq(_view.pool().body_of(NPC).position.x, DOCK.x, "Quem tem ponto nasce na doca...")
	assert_eq(_view.pool().body_of(OTHER_NPC).position, LOGICAL, "...e quem não tem, onde a ponte manda.")
	assert_eq([_view.active_ids(), _view.pool().duplicate_requests, _view.pool().lost_count()], [[NPC, OTHER_NPC] as Array[int], 0, 0], "Um corpo por NPC, sem pedido repetido nem corpo perdido.")
