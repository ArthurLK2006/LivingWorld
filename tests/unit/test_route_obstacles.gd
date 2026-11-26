extends GutTest
## LW-099g: a PROVA do ajudante `RouteObstacles` (tests/unit/support/route_obstacles.gd), sem janela: o teste de folga dos trajetos (`test_caravan_route_clearance.gd`) só vale se os obstáculos e o carrinho forem o que a tela desenha. Conferido aqui: (1) a conta de folga entre polígonos
## convexos (casos de conta feita à mão); (2) o retângulo do carrinho contém TODOS os vértices do `CaravanView` desenhado (menos o comerciante) em qualquer giro, e é justo atrás e nos lados; (3) as caixas dos locais; (4) as peças das praças estão ONDE as constantes de `plaza_data.gd` e
## `plaza_variants.gd` mandam (origem + ponto do lugar x escala de encaixe, que é a conta do `MarketPlazaView` refeita aqui), na quantidade certa, e o casco de cada tipo bate com a medida que a praça usa (copa da tenda, guarda-sol, toldo, árvore).

const WORLD_DIR: String = "res://data/world"
const PLACES_FILE: String = "res://data/world/places.json"
const DECORATIONS_FILE: String = "res://data/world/decorations.json"
const POSITION_TOLERANCE_M: float = 0.01
const HALF: float = 0.5
const CART_YAWS: Array[float] = [0.0, 0.7, -2.0, 3.0]
## Um bem de cada forma de volume (saco, barril, caixa e feixe), no peso máximo (3 volumes à mostra).
const CARGOS: PackedStringArray = ["grain", "flour", "bread", "wood"]
const FULL_LOAD_PERMILLE: int = 1000
const SQUARE: PackedVector2Array = [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]

var _terrain: TerrainData
var _places: Array[Place] = []
var _rows: Array = []
var _obstacles: RouteObstacles


func before_all() -> void:
	var terrain: TerrainLoader.LoadResult = TerrainLoader.load_dir(WORLD_DIR)
	assert_true(terrain.result.ok, terrain.result.message)
	_terrain = terrain.terrain
	var settlements: SettlementLoader.LoadResult = SettlementLoader.load_dir(WORLD_DIR, _terrain)
	assert_true(settlements.result.ok, settlements.result.message)
	_places = settlements.places
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PLACES_FILE))  # Variant: fronteira com o JSON, conferido abaixo
	assert_eq(typeof(parsed), TYPE_ARRAY, "places.json é uma lista")
	_rows = parsed
	_obstacles = RouteObstacles.build(ScriptedCaravanBridge.new(null, _terrain, _places))


func _moved(polygon: PackedVector2Array, by: Vector2) -> PackedVector2Array:
	var moved: PackedVector2Array = PackedVector2Array()
	for point: Vector2 in polygon:
		moved.append(point + by)
	return moved


func _market_rows() -> Array:
	return _rows.filter(func(row: Dictionary) -> bool: return str(row["kind"]) == "market")


func _origin_of(row: Dictionary) -> Vector2:
	return Vector2(float(row["x_cm"]), float(row["z_cm"])) / RouteObstacles.CM_PER_M


## A escala de encaixe da praça, refeita aqui da regra do `MarketPlazaView` (a maior escala, até 1 e no mínimo MIN_SCALE, que deixa a praça a NEIGHBOR_MARGIN_M da caixa de cada local desenhado que não é mercado).
func _fit_scale(market: Vector2) -> float:
	var fit: float = 1.0
	var foot: Rect2 = MarketPlazaView.FOOTPRINT_M
	for row: Dictionary in _rows:
		var kind: String = str(row["kind"])
		if kind == PlacePalette.KIND_MARKET or not PlacePalette.is_drawn(kind):
			continue
		var half: Vector2 = Vector2(PlacePalette.SIZES[kind].x, PlacePalette.SIZES[kind].z) * HALF + Vector2.ONE * MarketPlazaView.NEIGHBOR_MARGIN_M
		var relative: Vector2 = _origin_of(row) - market
		fit = minf(fit, maxf(_separating(relative.x, half.x, foot.position.x, foot.end.x), _separating(relative.y, half.y, foot.position.y, foot.end.y)))
	return maxf(fit, MarketPlazaView.MIN_SCALE)


func _separating(center: float, half: float, low: float, high: float) -> float:
	if center - half > 0.0:
		return (center - half) / high
	if center + half < 0.0:
		return (center + half) / low
	return 0.0


## O maior afastamento (m) dos vértices do casco em relação à origem da peça.
func _farthest(entry: RouteObstacles.Item) -> float:
	var farthest: float = 0.0
	for point: Vector2 in entry.hull:
		farthest = maxf(farthest, point.distance_to(entry.origin))
	return farthest


## Os vértices do casco no quadro local da peça (a origem dela, desfeito o giro `yaw` em torno de Y).
func _local_hull(entry: RouteObstacles.Item, yaw: float) -> PackedVector2Array:
	var local: PackedVector2Array = PackedVector2Array()
	for point: Vector2 in entry.hull:
		var offset: Vector2 = point - entry.origin
		local.append(Vector2(offset.x * cos(yaw) - offset.y * sin(yaw), offset.x * sin(yaw) + offset.y * cos(yaw)))
	return local


func test_the_gap_between_convex_polygons_matches_hand_made_cases() -> void:
	assert_almost_eq(RouteObstacles.gap_between(SQUARE, _moved(SQUARE, Vector2(3, 0))), 2.0, 0.000001, "lado a lado, 2 m entre eles")
	assert_almost_eq(RouteObstacles.gap_between(SQUARE, _moved(SQUARE, Vector2(2, 2))), sqrt(2.0), 0.000001, "canto contra canto: a diagonal")
	assert_eq(RouteObstacles.gap_between(SQUARE, _moved(SQUARE, Vector2(1, 0))), 0.0, "encostados: zero")
	assert_almost_eq(RouteObstacles.gap_between(SQUARE, _moved(SQUARE, Vector2(0.75, 0.25))), -0.25, 0.000001, "cruzados: menos a menor penetração (0,25 m no eixo y)")
	var diamond: PackedVector2Array = [Vector2(3, 2), Vector2(4, 3), Vector2(3, 4), Vector2(2, 3)]
	assert_almost_eq(RouteObstacles.gap_between(SQUARE, diamond), 3.0 / sqrt(2.0), 0.000001, "um losango girado: do canto do quadrado à aresta dele (a reta x + y = 5)")
	assert_almost_eq(RouteObstacles.gap_between(diamond, SQUARE), 3.0 / sqrt(2.0), 0.000001, "e a ordem dos dois não importa")
	assert_true(RouteObstacles.contains(SQUARE, Vector2(0.5, 0.5)) and not RouteObstacles.contains(SQUARE, Vector2(1.5, 0.5)) and RouteObstacles.contains(SQUARE, Vector2(1.005, 0.5), 0.01), "ponto dentro, fora e dentro da tolerância")
	assert_almost_eq(RouteObstacles.point_gap(SQUARE, Vector2(4, 0.5)), 3.0, 0.000001, "distância de um ponto ao polígono")


func test_the_cart_rectangle_holds_every_vertex_of_the_drawn_cart_and_is_tight_at_the_back_and_sides() -> void:
	var loaded: CaravanRoutesReader.LoadResult = CaravanRoutesReader.from_file()
	assert_true(loaded.result.ok, loaded.result.message)
	for yaw: float in CART_YAWS:
		var view: CaravanView = CaravanView.new(loaded.data)
		add_child_autofree(view)
		view.bind(1)
		var feet: Vector2 = Vector2(100.0, 200.0)
		view.apply_pose(Vector3(feet.x, 0.0, feet.y), yaw, 0.0)
		var polygon: PackedVector2Array = RouteObstacles.cart_polygon(feet, yaw)
		for good: String in CARGOS:
			view.apply_state(true, good, FULL_LOAD_PERMILLE)
			var extent: Vector2 = Vector2.ZERO
			var vertices: int = 0
			for spot: Vector2 in _drawn_cart(view):
				vertices += 1
				assert_true(RouteObstacles.contains(polygon, spot, POSITION_TOLERANCE_M), "giro %s, carga %s: o vértice %s do carrinho desenhado está dentro do retângulo" % [yaw, good, spot])
				var offset: Vector2 = spot - feet
				extent = Vector2(maxf(extent.x, absf(offset.x * cos(yaw) - offset.y * sin(yaw))), maxf(extent.y, offset.x * sin(yaw) + offset.y * cos(yaw)))
			assert_gt(vertices, 100, "giro %s: o carrinho tem malhas (o teste não olhou para o vazio)" % yaw)
			assert_almost_eq(extent.y, RouteObstacles.CART_BEHIND_M, 2.0 * POSITION_TOLERANCE_M, "giro %s, carga %s: o retângulo termina onde o leito termina, atrás dos pés (2,9 m)" % [yaw, good])
			assert_almost_eq(extent.x, RouteObstacles.CART_HALF_WIDTH_M, 2.0 * POSITION_TOLERANCE_M, "giro %s, carga %s: e na ponta do raio das rodas (0,625 m)" % [yaw, good])


## Os vértices (x, z no mundo) de tudo o que se VÊ do carrinho: as malhas visíveis de tudo o que não é o comerciante (a cápsula dele é outro corpo).
func _drawn_cart(view: CaravanView) -> PackedVector2Array:
	var spots: PackedVector2Array = PackedVector2Array()
	var stack: Array[Node] = []
	for child: Node in view.get_children():
		if str(child.name) != CaravanView.MERCHANT_NAME:
			stack.append(child)
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		stack.append_array(node.get_children())
		var mesh_node: MeshInstance3D = node as MeshInstance3D
		if mesh_node == null or mesh_node.mesh == null or not mesh_node.is_visible_in_tree():
			continue
		for surface: int in mesh_node.mesh.get_surface_count():
			var points: PackedVector3Array = mesh_node.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
			for vertex: Vector3 in points:
				var world: Vector3 = mesh_node.global_transform * vertex
				spots.append(Vector2(world.x, world.z))
	return spots


func test_the_place_boxes_are_the_axis_aligned_rectangles_of_places_json_without_the_market() -> void:
	var boxes: int = 0
	for row: Dictionary in _rows:
		var kind: String = str(row["kind"])
		var entry: RouteObstacles.Item = _obstacles.item(str(row["id"]))
		if kind == PlacePalette.KIND_MARKET:
			assert_null(entry, "%s: a caixa branca do mercado não é obstáculo (a praça a esconde)" % row["id"])
			continue
		boxes += 1
		assert_not_null(entry, "%s: tem caixa" % row["id"])
		var half: Vector2 = Vector2(PlacePalette.SIZES[kind].x, PlacePalette.SIZES[kind].z) * HALF
		assert_eq([entry.origin, entry.bounds.size, entry.hull.size()], [_origin_of(row), half * 2.0, 4], "%s: centro, tamanho e quatro cantos" % row["id"])
	assert_eq(_obstacles.items.filter(func(entry: RouteObstacles.Item) -> bool: return entry.id.find("/") < 0 and not entry.is_circle).size(), boxes, "uma caixa por local desenhado, nem uma a mais")


func test_the_plaza_pieces_are_where_the_plaza_constants_put_them_in_the_right_number() -> void:
	assert_eq(_market_rows().size(), 3, "três mercados")
	for row: Dictionary in _market_rows():
		var market_id: String = str(row["id"])
		var origin: Vector2 = _origin_of(row)
		var scale: float = _fit_scale(origin)
		assert_almost_eq(float(_obstacles.plaza_scale[market_id]), scale, 0.0001, "%s: a escala de encaixe da praça" % market_id)
		var spec: PlazaVariants.Spec = PlazaVariants.for_market(market_id)
		var expected: Dictionary[String, Vector2] = {PlazaVariants.CENTER_NAMES[spec.center]: origin}
		for index: int in spec.stalls.size():
			expected["Stall%d" % index] = origin + Vector2(spec.stalls[index].x, spec.stalls[index].y) * scale
		for index: int in PlazaData.LAMP_SPOTS.size():
			expected["LampPost%d" % index] = origin + PlazaData.LAMP_SPOTS[index] * scale
		for index: int in PlazaData.TORCH_SPOTS.size():
			expected["Torch%d" % index] = origin + PlazaData.TORCH_SPOTS[index] * scale
		if spec.plants_in_footprint:
			for index: int in spec.tree_spots.size():
				expected["Tree%d" % index] = origin + spec.tree_spots[index] * scale
			for index: int in spec.rock_spots.size():
				expected["Rock%d" % index] = origin + spec.rock_spots[index] * scale
		for node_name: String in expected:
			var entry: RouteObstacles.Item = _obstacles.item("%s/%s" % [market_id, node_name])
			assert_not_null(entry, "%s/%s: a praça tem a peça" % [market_id, node_name])
			if entry != null:
				assert_lt(entry.origin.distance_to(expected[node_name]), POSITION_TOLERANCE_M, "%s/%s: está onde a constante manda (lugar x escala), a menos de 1 cm" % [market_id, node_name])
				assert_true(RouteObstacles.contains(entry.hull, entry.origin, POSITION_TOLERANCE_M), "%s/%s: o casco contém a origem da peça" % [market_id, node_name])
		var majors: int = _obstacles.items.filter(func(entry: RouteObstacles.Item) -> bool: return entry.id.begins_with(market_id + "/") and not entry.is_minor).size()
		assert_eq(majors, expected.size(), "%s: nem uma peça principal a mais nem a menos" % market_id)
	assert_true(_obstacles.items.any(func(entry: RouteObstacles.Item) -> bool: return entry.is_minor), "os adereços e arbustos existem à parte (só informam)")


func test_the_hull_of_each_kind_of_piece_matches_the_measure_the_plaza_uses() -> void:
	var scale_a: float = _obstacles.plaza_scale["a_market_01"]
	var scale_b: float = _obstacles.plaza_scale["b_market_01"]
	var scale_c: float = _obstacles.plaza_scale["c_market_01"]
	assert_almost_eq(_farthest(_obstacles.item("a_market_01/Stall0")), PlazaData.CANOPY_RADIUS_M * scale_a, POSITION_TOLERANCE_M, "tenda: o canto da copa está a CANOPY_RADIUS_M da origem")
	assert_almost_eq(_farthest(_obstacles.item("b_market_01/Stall1")), PlazaData.PARASOL_RADIUS_M * scale_b, POSITION_TOLERANCE_M, "guarda-sol: a borda está a PARASOL_RADIUS_M")
	var lean_to: RouteObstacles.Item = _obstacles.item("b_market_01/Stall0")
	var extent: Rect2 = Rect2(_local_hull(lean_to, PlazaData.STALL_POSES_B[0].z)[0], Vector2.ZERO)
	for point: Vector2 in _local_hull(lean_to, PlazaData.STALL_POSES_B[0].z):
		extent = extent.expand(point)
	assert_almost_eq(extent.size.x, 2.0 * (PlazaData.LEAN_TO_HALF_WIDTH_M + PlazaData.LEAN_TO_OVERHANG_M) * scale_b, 2.0 * POSITION_TOLERANCE_M, "toldo: a largura do teto, no quadro local da barraca (2 cm: os remendos do pano saem 1,5 cm da face, MEND_LIFT_M)")
	assert_almost_eq(extent.size.y, 2.0 * (PlazaData.LEAN_TO_HALF_DEPTH_M + PlazaData.LEAN_TO_OVERHANG_M) * scale_b, 2.0 * POSITION_TOLERANCE_M, "toldo: e a profundidade")
	var tree_scale: float = PlazaMeshKit.between(0, PlazaData.Channel.TREE_SCALE, 0.85, 1.15)
	assert_almost_eq(_farthest(_obstacles.item("c_market_01/Tree0")), PlazaData.TREE_FORMS_C[0].y * tree_scale * scale_c, POSITION_TOLERANCE_M, "conífera de C: o raio da base de baixo x a escala por hash x a da praça")
	for entry: RouteObstacles.Item in [_obstacles.item("a_market_01/Well"), _obstacles.item("b_market_01/Fountain"), _obstacles.item("c_market_01/Rotunda")]:
		assert_gt(_farthest(entry), 1.0, "%s: a peça central tem mais de 1 m de raio" % entry.id)
	assert_gt(_farthest(_obstacles.item("b_market_01/Fountain")), PlazaData.FOUNTAIN_RADIUS_M * scale_b, "fonte: o casco passa do raio do anel de pedras (as pedras têm largura)")
	assert_gt(_farthest(_obstacles.item("c_market_01/Rotunda")), PlazaData.ROTUNDA_RADIUS_M * scale_c, "rotunda: idem")


func test_nearest_finds_the_closest_main_obstacle_with_its_id_and_gap() -> void:
	var feet: Vector2 = Vector2(285.0 + 2.5 + RouteObstacles.CART_HALF_WIDTH_M + 0.7, 541.0)
	var hit: RouteObstacles.Hit = _obstacles.nearest(RouteObstacles.cart_polygon(feet, 0.0))
	assert_eq(hit.item.id if hit.item != null else "", "a_home_01", "o vizinho mais perto é a casa a_home_01")
	assert_almost_eq(hit.gap_m, 0.7, 0.0001, "a 0,7 m da parede")
	var far: RouteObstacles.Hit = _obstacles.nearest(RouteObstacles.cart_polygon(Vector2(5.0, 5.0), 0.0))
	assert_true(far.item == null and is_inf(far.gap_m), "longe de tudo: nenhum obstáculo ao alcance")


## As árvores e pedras do mundo: os obstáculos são as MESMAS que a `DecorationView` desenha (a conta e todas as posições e escalas, no centímetro), com o raio da copa e o da pedra.
func test_the_decorations_are_the_same_ones_the_decoration_view_draws() -> void:
	var read: DecorationReader.ReadResult = DecorationReader.read_file(DECORATIONS_FILE)
	assert_true(read.result.ok, read.result.message)
	var view: DecorationView = DecorationView.new()
	view.setup(ScriptedCaravanBridge.new(null, _terrain, _places), read.items)
	var drawn: PackedStringArray = PackedStringArray()
	for instance: MultiMeshInstance3D in view.multimesh_instances():
		var base_m: float = DecorationShapes.CROWN_RADIUS_M if str(instance.name).begins_with("Deco_" + DecorationReader.KIND_TREE) else DecorationShapes.ROCK_RADIUS_M
		for placement: Transform3D in view.transforms_of(instance):
			drawn.append("%d,%d,%d" % [roundi(placement.origin.x * RouteObstacles.CM_PER_M), roundi(placement.origin.z * RouteObstacles.CM_PER_M), roundi(base_m * placement.basis.get_scale().x * 1000.0)])
	var listed: PackedStringArray = PackedStringArray()
	var trees: int = 0
	var rocks: int = 0
	for entry: RouteObstacles.Item in _obstacles.items:
		if entry.is_circle:
			trees += 1 if entry.type == DecorationReader.KIND_TREE else 0
			rocks += 1 if entry.type == DecorationReader.KIND_ROCK else 0
			listed.append("%d,%d,%d" % [roundi(entry.origin.x * RouteObstacles.CM_PER_M), roundi(entry.origin.y * RouteObstacles.CM_PER_M), roundi(entry.radius * 1000.0)])
	assert_eq([trees, rocks], [view.instance_count(DecorationReader.KIND_TREE), view.instance_count(DecorationReader.KIND_ROCK)], "a mesma conta de árvores e de pedras que a vista desenha")
	assert_gt(trees + rocks, 1000, "e são milhares (o teste não olhou para o vazio)")
	drawn.sort()
	listed.sort()
	assert_eq(listed, drawn, "mesmas posições (ao centímetro) e mesmos raios (ao milímetro): copa 1,3 m e pedra 0,9 m vezes a escala de cada uma")
	view.free()
