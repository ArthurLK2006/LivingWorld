extends GutTest
## ART-2b: a praça de mercado no jogo, sem janela, com o terreno e os locais reais de res://data (como o teste da PlaceBoxesView) e a ponte real: uma praça por mercado no x e no z do local e na altura do terreno, escondida até o chunk dela existir, com as peças esperadas,
## dentro do orçamento, sem colisão, igual em duas montagens e longe das caixas dos vizinhos; as caixas de mercado escondidas (e ainda existentes) na cena principal; e, num terreno inclinado sintético, as peças no chão e a escala do encaixe.

const BLOCKOUT_DIR: String = "res://data/world"
const MAIN_SCENE_PATH: String = "res://scenes/main.tscn"
const TOLERANCE_M: float = 0.001
const GAP_TOLERANCE_M: float = 0.02
## Orçamento por praça: triângulos e chamadas de desenho estimadas (uma por superfície de malha).
const MAX_TRIANGLES: int = 70000
const MAX_DRAW_CALLS: int = 400
## Vizinhos do encaixe: os locais a menos disto do mercado.
const NEAR_M: float = 25.0
## As bandeirolas ficam numa altura fixa da origem da praça (ART-2a): só casam com os postes se o chão deles está a menos disto da origem.
const MAX_POST_RISE_M: float = 0.3
const ABSENT_PIECES: Array[String] = ["Ground", "Tree0", "Rock0", "House0", "Grass", "Flowers0"]
## Terreno inclinado sintético: 32 x 24 células de 2 m, o chão sobe 20 cm a cada nó em x (10 cm por metro); o mercado em x = 32 e uma casa 12 m a leste.
const SLOPE_CELLS: Vector2i = Vector2i(32, 24)
const CELL_CM: int = 200
const CHUNK_CELLS: int = 8
const SURFACE_CODE: int = 5
const RISE_CM_PER_NODE: int = 20
const RISE_PER_M: float = 0.1
const SLOPE_Z_M: float = 24.0
const MARKET_X_M: float = 32.0
const HOME_X_M: float = 44.0
const HOME_HALF_M: float = 2.5

var _places: Array[Place] = []
var _markets: Array[Place] = []
var _bridge: SimBridge
var _chunk_size_m: float
var _view: MarketPlazaView


func before_all() -> void:
	var terrain_loaded: TerrainLoader.LoadResult = TerrainLoader.load_dir(BLOCKOUT_DIR)
	assert_true(terrain_loaded.result.ok, terrain_loaded.result.message)
	var loaded: SettlementLoader.LoadResult = SettlementLoader.load_dir(BLOCKOUT_DIR, terrain_loaded.terrain)
	assert_true(loaded.result.ok, loaded.result.message)
	_places = loaded.places
	for place: Place in _places:
		if place.kind == Place.KIND_MARKET:
			_markets.append(place)
	_bridge = SimBridge.new(null, terrain_loaded.terrain, _places)
	var layout: BridgeReplies.TerrainLayoutReply = _bridge.peek_terrain_layout()
	_chunk_size_m = float(layout.chunk_cells) * layout.cell_size_m


func before_each() -> void:
	_view = MarketPlazaView.new()
	assert_true(_view.setup(_bridge))


func after_each() -> void:
	_view.free()


func _chunk_of(place: Place) -> Vector2i:
	return Vector2i(floori(place.position.x / _chunk_size_m), floori(place.position.z / _chunk_size_m))


## Os nós que a praça do jogo tem (sem os adereços, que são 5 por barraca): estruturas, bandeirolas, poço e mancha.
func _expected_pieces() -> Array[String]:
	var names: Array[String] = ["Well", "PlazaPatch"]
	for index: int in PlazaData.STALL_SPOTS.size():
		names.append("Stall%d" % index)
	for index: int in PlazaData.LAMP_SPOTS.size():
		names.append_array(["LampPost%d" % index, "Bunting%d" % index])
	for index: int in PlazaData.TORCH_SPOTS.size():
		names.append("Torch%d" % index)
	return names


## Os vértices das malhas da praça no quadro local dela (escala 1; as malhas são filhas diretas da praça).
func _local_points(plaza: Node3D) -> PackedVector3Array:
	var points: PackedVector3Array = PackedVector3Array()
	for piece: Node in plaza.find_children("*", "MeshInstance3D", true, false):
		var instance: MeshInstance3D = piece as MeshInstance3D
		for point: Vector3 in instance.mesh.get_faces():
			points.append(instance.transform * point)
	return points


## Menor folga (m) entre os vértices da praça, no mundo, e as caixas dos locais que não são mercado perto dele: negativa se algum vértice entra numa caixa.
func _min_gap(plaza: Node3D, market: Place) -> float:
	var worst: float = INF
	var points: PackedVector3Array = _local_points(plaza)
	for other: Place in _places:
		if other.kind == Place.KIND_MARKET or other.position.distance_to(market.position) > NEAR_M:
			continue
		var half: Vector3 = PlacePalette.SIZES[other.kind] * 0.5
		for point: Vector3 in points:
			var world: Vector3 = plaza.transform * point
			worst = minf(worst, maxf(absf(world.x - other.position.x) - half.x, absf(world.z - other.position.z) - half.z))
	return worst


## Resumo da geometria e da ordem dos nós de todas as praças.
func _digest(view: MarketPlazaView) -> int:
	var digest: int = 0
	for plaza: Node in view.get_children():
		digest = hash([digest, plaza.name, (plaza as Node3D).transform])
		for piece: Node in plaza.find_children("*", "MeshInstance3D", true, false):
			var instance: MeshInstance3D = piece as MeshInstance3D
			digest = hash([digest, instance.name, instance.transform])
			for surface: int in instance.mesh.get_surface_count():
				digest = hash([digest, instance.mesh.surface_get_arrays(surface)])
	return digest


func _ramp_place(place_id: String, kind: String, x_m: float) -> Place:
	return Place.new(place_id, "t", kind, Vector3(x_m, x_m * RISE_PER_M, SLOPE_Z_M), 5)


func _ramp_bridge(places: Array[Place]) -> SimBridge:
	var nodes: Vector2i = SLOPE_CELLS + Vector2i.ONE
	var heights: PackedInt64Array = PackedInt64Array()
	heights.resize(nodes.x * nodes.y)
	for index: int in heights.size():
		heights[index] = (index % nodes.x) * RISE_CM_PER_NODE
	var surfaces: PackedInt64Array = PackedInt64Array()
	surfaces.resize(SLOPE_CELLS.x * SLOPE_CELLS.y)
	surfaces.fill(SURFACE_CODE)
	var ids: Dictionary[int, String] = {SURFACE_CODE: "grass"}
	return SimBridge.new(null, TerrainData.new(SLOPE_CELLS, CELL_CM, CHUNK_CELLS, heights, surfaces, ids, Vector2i.ZERO), places)


func test_there_is_one_plaza_per_market_at_its_x_and_z_on_the_terrain_with_the_expected_pieces_and_no_collision() -> void:
	assert_gt(_markets.size(), 0, "Os dados têm mercados.")
	assert_eq(_view.plaza_count(), _markets.size())
	assert_eq(_view.get_child_count(), _markets.size())
	var pieces: Array[String] = _expected_pieces()
	for market: Place in _markets:
		var plaza: Node3D = _view.plaza_of(market.id)
		assert_eq(plaza.name, StringName("MarketPlaza_" + market.id))
		assert_eq(Vector2(plaza.position.x, plaza.position.z), Vector2(market.position.x, market.position.z), "Posição de '%s'." % market.id)
		assert_almost_eq(plaza.position.y, _bridge.peek_height(market.position.x, market.position.z).height_m, TOLERANCE_M, "A origem da praça fica na altura do terreno do centro.")
		assert_eq(plaza.get_child_count(), pieces.size() + PlazaData.STALL_SPOTS.size() * PlazaData.PROP_KINDS.size(), "Peças de '%s'." % market.id)
		for piece: String in pieces:
			assert_true(plaza.has_node(NodePath(piece)), "%s em '%s'." % [piece, market.id])
		for absent: String in ABSENT_PIECES:
			assert_false(plaza.has_node(NodePath(absent)), "Sem %s: o terreno do jogo é o chão." % absent)
		assert_eq(plaza.find_children("*", "OmniLight3D", true, false).size(), PlazaData.LAMP_SPOTS.size() + PlazaData.TORCH_SPOTS.size(), "As luzes dos lampiões e das tochas.")
	assert_null(_view.plaza_of("local_que_nao_existe"))
	assert_eq(_view.find_children("*", "CollisionObject3D", true, false).size(), 0)


func test_plazas_start_hidden_and_a_chunk_shows_and_hides_only_its_own() -> void:
	var chunk: Vector2i = _chunk_of(_markets[0])
	for market: Place in _markets:
		assert_false(_view.plaza_of(market.id).visible, "Nasce escondida, até o terreno do chunk existir.")
	_view.set_chunk_visible(chunk, true)
	for market: Place in _markets:
		assert_eq(_view.plaza_of(market.id).visible, _chunk_of(market) == chunk, "Praça de '%s'." % market.id)
	_view.set_chunk_visible(chunk, false)
	_view.set_chunk_visible(Vector2i(-5, -5), true)
	for market: Place in _markets:
		assert_false(_view.plaza_of(market.id).visible)


func test_a_hidden_kind_of_box_stays_hidden_through_chunk_changes_and_the_boxes_still_exist() -> void:
	var boxes: PlaceBoxesView = PlaceBoxesView.new()
	assert_true(boxes.setup(_bridge))
	boxes.set_kind_hidden(PlacePalette.KIND_MARKET, true)
	var chunk: Vector2i = _chunk_of(_markets[0])
	boxes.set_chunk_visible(chunk, true)
	assert_eq(boxes.box_count(), _places.size(), "As caixas continuam existindo e contando.")
	for place: Place in _places:
		assert_eq(boxes.box_of(place.id).visible, _chunk_of(place) == chunk and place.kind != Place.KIND_MARKET, "Caixa de '%s'." % place.id)
	boxes.set_kind_hidden(PlacePalette.KIND_MARKET, false)
	assert_true(boxes.box_of(_markets[0].id).visible, "Ao desfazer, a caixa volta no chunk mostrado.")
	boxes.set_chunk_visible(chunk, false)
	boxes.set_kind_hidden(PlacePalette.KIND_MARKET, true)
	boxes.set_kind_hidden(PlacePalette.KIND_MARKET, false)
	assert_false(boxes.box_of(_markets[0].id).visible, "Chunk não mostrado: a caixa segue escondida.")
	boxes.free()


func test_the_main_scene_swaps_the_market_boxes_for_the_plazas_wired_to_the_terrain_chunks() -> void:
	var main: Node = add_child_autofree((load(MAIN_SCENE_PATH) as PackedScene).instantiate())
	var views: Array[Node] = main.find_children("*", "MarketPlazaView", true, false)
	assert_eq(views.size(), 1)
	var scene_plazas: MarketPlazaView = views[0] as MarketPlazaView
	assert_eq(scene_plazas.name, &"MarketPlazaView")
	assert_eq(scene_plazas.plaza_count(), _markets.size(), "O GameApp real entregou os locais à ponte.")
	var scene_boxes: PlaceBoxesView = main.find_children("*", "PlaceBoxesView", true, false)[0] as PlaceBoxesView
	var terrain: TerrainView = main.find_children("*", "TerrainView", true, false)[0] as TerrainView
	var market: Place = _markets[0]
	terrain.chunk_loaded.emit(_chunk_of(market))
	assert_true(scene_plazas.plaza_of(market.id).visible, "A cena liga chunk_loaded às praças.")
	assert_false(scene_boxes.box_of(market.id).visible, "A caixa branca do mercado fica escondida.")
	for place: Place in _places:
		if place.kind != Place.KIND_MARKET and _chunk_of(place) == _chunk_of(market):
			assert_true(scene_boxes.box_of(place.id).visible, "As outras caixas do chunk aparecem como antes: '%s'." % place.id)
	assert_eq(scene_boxes.box_count(), _places.size())
	terrain.chunk_unloaded.emit(_chunk_of(market))
	assert_false(scene_plazas.plaza_of(market.id).visible, "E chunk_unloaded também.")


func test_each_plaza_fits_the_triangle_and_draw_call_budget() -> void:
	for market: Place in _markets:
		var triangles: int = 0
		var draw_calls: int = 0
		for piece: Node in _view.plaza_of(market.id).find_children("*", "MeshInstance3D", true, false):
			var mesh: Mesh = (piece as MeshInstance3D).mesh
			triangles += int(mesh.get_faces().size() / 3.0)
			draw_calls += mesh.get_surface_count()
		assert_between(triangles, 1, MAX_TRIANGLES, "Triângulos da praça de '%s'." % market.id)
		assert_between(draw_calls, 1, MAX_DRAW_CALLS, "Chamadas de desenho estimadas da praça de '%s'." % market.id)


func test_two_assemblies_of_the_same_world_are_identical() -> void:
	var first: int = _digest(_view)
	assert_ne(first, 0, "A montagem produziu geometria.")
	var other: MarketPlazaView = MarketPlazaView.new()
	assert_true(other.setup(_bridge))
	assert_eq(_digest(other), first, "Duas montagens iguais.")
	other.free()


func test_the_footprint_is_the_extent_of_the_pieces_in_the_plaza_frame() -> void:
	var points: PackedVector3Array = _local_points(_view.plaza_of(_markets[0].id))
	var extent: Rect2 = Rect2(Vector2(points[0].x, points[0].z), Vector2.ZERO)
	for point: Vector3 in points:
		extent = extent.expand(Vector2(point.x, point.z))
	assert_true(MarketPlazaView.FOOTPRINT_M.grow(TOLERANCE_M).encloses(extent), "O retângulo do encaixe cobre as peças.")
	assert_almost_eq(extent.position, MarketPlazaView.FOOTPRINT_M.position, Vector2.ONE * GAP_TOLERANCE_M, "E é justo, nos dois cantos.")
	assert_almost_eq(extent.end, MarketPlazaView.FOOTPRINT_M.end, Vector2.ONE * GAP_TOLERANCE_M)


func test_no_piece_enters_the_box_of_a_neighbor_and_the_scale_is_the_largest_that_fits() -> void:
	for market: Place in _markets:
		var plaza: Node3D = _view.plaza_of(market.id)
		assert_between(plaza.scale.x, MarketPlazaView.MIN_SCALE, 1.0, "Escala da praça de '%s'." % market.id)
		assert_eq(plaza.scale, Vector3.ONE * plaza.scale.x, "A escala é uniforme.")
		var gap: float = _min_gap(plaza, market)
		assert_gte(gap, MarketPlazaView.NEIGHBOR_MARGIN_M - TOLERANCE_M, "Folga da praça de '%s' às caixas vizinhas." % market.id)
		if plaza.scale.x < 1.0:
			assert_almost_eq(gap, MarketPlazaView.NEIGHBOR_MARGIN_M, GAP_TOLERANCE_M, "A escala não é menor que o necessário.")


func test_the_ground_under_every_post_stays_within_the_bunting_tolerance_of_the_plaza_origin() -> void:
	for market: Place in _markets:
		var plaza: Node3D = _view.plaza_of(market.id)
		var posts: Array[Node] = plaza.find_children("LampPost*", "", true, false)
		posts.append_array(plaza.find_children("Torch*", "", true, false))
		assert_eq(posts.size(), PlazaData.LAMP_SPOTS.size() + PlazaData.TORCH_SPOTS.size())
		for post: Node in posts:
			assert_lt(absf((post as Node3D).position.y * plaza.scale.y), MAX_POST_RISE_M, "%s em '%s'." % [post.name, market.id])


func test_pieces_stand_on_the_slope_and_the_plaza_shrinks_to_clear_the_neighbor() -> void:
	var places: Array[Place] = [_ramp_place("t_market_01", Place.KIND_MARKET, MARKET_X_M), _ramp_place("t_home_01", Place.KIND_HOME, HOME_X_M)]
	var bridge: SimBridge = _ramp_bridge(places)
	var view: MarketPlazaView = MarketPlazaView.new()
	add_child_autofree(view)
	assert_true(view.setup(bridge))
	var plaza: Node3D = view.plaza_of("t_market_01")
	assert_almost_eq(plaza.scale.x, (HOME_X_M - MARKET_X_M - HOME_HALF_M - MarketPlazaView.NEIGHBOR_MARGIN_M) / MarketPlazaView.FOOTPRINT_M.end.x, TOLERANCE_M, "Escala do encaixe com a casa a 12 m.")
	var lowest: float = INF
	var highest: float = -INF
	for piece: Node in plaza.get_children():
		if piece.name == &"PlazaPatch" or String(piece.name).begins_with("Bunting"):
			continue
		var world: Vector3 = plaza.transform * (piece as Node3D).position
		assert_almost_eq(world.y, bridge.peek_height(world.x, world.z).height_m, TOLERANCE_M, "%s no chão." % piece.name)
		lowest = minf(lowest, world.y)
		highest = maxf(highest, world.y)
	assert_gt(highest - lowest, 1.0, "O terreno é de fato inclinado sob as peças.")


func test_a_bad_bridge_builds_nothing_with_a_visible_error_and_setup_twice_does_not_duplicate() -> void:
	assert_true(_view.setup(_bridge))
	assert_eq(_view.get_child_count(), _markets.size(), "Nada ficou duplicado.")
	var other: MarketPlazaView = MarketPlazaView.new()
	assert_false(other.setup(null))
	assert_push_error("MarketPlazaView.setup: ponte nula")
	assert_false(other.setup(SimBridge.new(null, null, _places)))
	assert_push_error("MarketPlazaView.setup")
	assert_eq(other.plaza_count(), 0)
	other.free()
