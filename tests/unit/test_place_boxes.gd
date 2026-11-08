extends GutTest
## LW-074: uma caixa provisória por local, montada pelos dados que a ponte devolve, sem janela: contagem, posição, base no chão, cor e
## tamanho por tipo, escondida até o chunk existir, sem colisão. O tipo reservado (mercado) não é desenhado.

const BLOCKOUT_DIR: String = "res://data/world"
const MAIN_SCENE_PATH: String = "res://scenes/main.tscn"
const TOLERANCE_M: float = 0.001
const HALF: float = 0.5

var _places: Array[Place] = []
var _bridge: SimBridge
var _chunk_size_m: float
var _view: PlaceBoxesView


func before_all() -> void:
	var terrain_loaded: TerrainLoader.LoadResult = TerrainLoader.load_dir(BLOCKOUT_DIR)
	assert_true(terrain_loaded.result.ok, terrain_loaded.result.message)
	var loaded: SettlementLoader.LoadResult = SettlementLoader.load_dir(BLOCKOUT_DIR, terrain_loaded.terrain)
	assert_true(loaded.result.ok, loaded.result.message)
	_places = loaded.places
	_bridge = SimBridge.new(null, terrain_loaded.terrain, _places)
	var layout: BridgeReplies.TerrainLayoutReply = _bridge.peek_terrain_layout()
	_chunk_size_m = float(layout.chunk_cells) * layout.cell_size_m


func before_each() -> void:
	_view = PlaceBoxesView.new()
	assert_true(_view.setup(_bridge))


func after_each() -> void:
	_view.free()


func _drawn_places() -> Array[Place]:
	var drawn: Array[Place] = []
	for place: Place in _places:
		if place.kind != Place.KIND_MARKET_RESERVED:
			drawn.append(place)
	return drawn


func _chunk_of(place: Place) -> Vector2i:
	return Vector2i(floori(place.position.x / _chunk_size_m), floori(place.position.z / _chunk_size_m))


func test_there_is_one_box_per_drawn_place_and_none_for_the_reserved_market_and_no_collision() -> void:
	var drawn: Array[Place] = _drawn_places()
	assert_lt(drawn.size(), _places.size(), "Os dados têm locais de mercado reservado, que não são desenhados.")
	assert_eq(_view.box_count(), drawn.size())
	assert_eq(_view.get_child_count(), drawn.size())
	for place: Place in _places:
		assert_eq(_view.box_of(place.id) != null, place.kind != Place.KIND_MARKET_RESERVED, "Caixa do local '%s'." % place.id)
	assert_eq(_view.find_children("*", "CollisionObject3D", true, false).size(), 0)


func test_each_box_is_where_the_data_says_on_the_ground_with_the_color_and_size_of_its_kind() -> void:
	var colors_by_kind: Dictionary[String, Color] = {}
	for place: Place in _drawn_places():
		var box: MeshInstance3D = _view.box_of(place.id)
		var mesh: BoxMesh = box.mesh as BoxMesh
		var color: Color = (mesh.material as StandardMaterial3D).albedo_color
		assert_eq(Vector2(box.position.x, box.position.z), Vector2(place.position.x, place.position.z), "Posição de '%s'." % place.id)
		assert_almost_eq(box.position.y - mesh.size.y * HALF, place.position.y, TOLERANCE_M, "A base da caixa fica na altura do terreno.")
		assert_eq(mesh.size, PlacePalette.SIZES[place.kind])
		assert_eq(color, PlacePalette.COLORS[place.kind])
		colors_by_kind[place.kind] = color
	assert_eq(colors_by_kind.size(), 4, "Os dados têm os quatro tipos desenhados.")
	for color: Color in colors_by_kind.values():
		assert_eq(colors_by_kind.values().count(color), 1, "Cada tipo tem a sua cor.")
	assert_eq([PlacePalette.KIND_HOME, PlacePalette.KIND_WORK, PlacePalette.KIND_REST, PlacePalette.KIND_SOCIAL], [Place.KIND_HOME, Place.KIND_WORK, Place.KIND_REST, Place.KIND_SOCIAL], "Os tipos da paleta são os do world.")
	for kind: String in Place.KINDS:
		assert_eq(PlacePalette.is_drawn(kind), kind != Place.KIND_MARKET_RESERVED)


func test_boxes_start_hidden_and_a_chunk_shows_and_hides_only_its_own_boxes() -> void:
	var chunk: Vector2i = _chunk_of(_drawn_places()[0])
	for place: Place in _drawn_places():
		assert_false(_view.box_of(place.id).visible, "Nasce escondida, até o terreno do chunk existir.")
	_view.set_chunk_visible(chunk, true)
	for place: Place in _drawn_places():
		assert_eq(_view.box_of(place.id).visible, _chunk_of(place) == chunk, "Caixa de '%s'." % place.id)
	_view.set_chunk_visible(chunk, false)
	_view.set_chunk_visible(Vector2i(-5, -5), true)
	for place: Place in _drawn_places():
		assert_false(_view.box_of(place.id).visible)


func test_a_bad_bridge_builds_nothing_with_a_visible_error_and_setup_twice_does_not_duplicate() -> void:
	assert_true(_view.setup(_bridge))
	assert_eq(_view.get_child_count(), _drawn_places().size(), "Nada ficou duplicado.")
	var other: PlaceBoxesView = PlaceBoxesView.new()
	assert_false(other.setup(null))
	assert_push_error("PlaceBoxesView.setup: ponte nula")
	assert_false(other.setup(SimBridge.new(null, null, _places)))
	assert_push_error("PlaceBoxesView.setup")
	assert_eq(other.box_count(), 0)
	other.free()


func test_the_main_scene_has_one_box_view_with_the_boxes_wired_to_the_terrain_chunks() -> void:
	var main: Node = add_child_autofree((load(MAIN_SCENE_PATH) as PackedScene).instantiate())
	var views: Array[Node] = main.find_children("*", "PlaceBoxesView", true, false)
	assert_eq(views.size(), 1)
	var scene_view: PlaceBoxesView = views[0] as PlaceBoxesView
	assert_eq(scene_view.box_count(), _drawn_places().size(), "O GameApp real entregou os locais à ponte.")
	var terrain: TerrainView = main.find_children("*", "TerrainView", true, false)[0] as TerrainView
	var place: Place = _drawn_places()[0]
	terrain.chunk_loaded.emit(_chunk_of(place))
	assert_true(scene_view.box_of(place.id).visible, "A cena liga chunk_loaded às caixas.")
	terrain.chunk_unloaded.emit(_chunk_of(place))
	assert_false(scene_view.box_of(place.id).visible, "E chunk_unloaded também.")
