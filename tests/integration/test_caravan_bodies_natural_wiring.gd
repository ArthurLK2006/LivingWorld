extends GutTest
## LW-099f (curvas naturais, EXPERIMENTAL): a LIGAÇÃO do interruptor `caravan_natural_curves` na cena principal (`main_world_view.gd`), sem janela, como em `test_caravan_bodies_wiring.gd` (a cena REAL de res://data, a ponte real e um GameApp de teste no lugar do autoload). O interruptor nasce DESLIGADO e só tem efeito com `caravans_visible` ligado: com os dois
## a vista nasce com o modo das curvas naturais ligado; só com `caravans_visible` a vista é a de sempre (modo desligado); sem `caravans_visible` nada da viagem visível é criado, mesmo com o interruptor das curvas ligado.

const WORLD_DIR: String = "res://data/world"
const MAIN_SCENE: String = "res://scenes/main.tscn"
const SEED: int = 99
const VISIBLE: StringName = &"caravans_visible"
const NATURAL: StringName = &"caravan_natural_curves"
const VIEW_NAME: String = "CaravanBodiesView"

var _terrain: TerrainData
var _places: Array[Place] = []
var _points: Array[PointOfInterest] = []
var _economy: EconomySetup
var _host: SimulationHostNode
var _stub: StubApp
var _real_app: Node
var _real_index: int = 0
var _main: Node


## GameApp de teste: entrega a ponte do teste e NÃO inicia jogo nenhum (o `_ready` do autoload recomeçaria o mundo do autoload).
class StubApp:
	extends GameAppNode

	var stub_bridge: SimBridge

	func _ready() -> void:
		pass

	func peek_bridge() -> SimBridge:
		return stub_bridge


func before_all() -> void:
	var terrain: TerrainLoader.LoadResult = TerrainLoader.load_dir(WORLD_DIR)
	assert_true(terrain.result.ok, terrain.result.message)
	_terrain = terrain.terrain
	var settlements: SettlementLoader.LoadResult = SettlementLoader.load_dir(WORLD_DIR, _terrain)
	assert_true(settlements.result.ok, settlements.result.message)
	_places = settlements.places
	var points: PointOfInterestLoader.LoadResult = PointOfInterestLoader.load_dir(WORLD_DIR, _terrain)
	assert_true(points.result.ok, points.result.message)
	_points = points.points
	_economy = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR)
	assert_true(_economy.result.ok, _economy.result.message)


func after_each() -> void:
	if _main != null and is_instance_valid(_main):
		if _main.is_inside_tree():
			_main.get_parent().remove_child(_main)
		_main.free()
	if _stub != null:
		get_tree().root.remove_child(_stub)
		_stub.free()
		get_tree().root.add_child(_real_app)
		get_tree().root.move_child(_real_app, _real_index)
	if _host != null:
		_host.runner.finish()
		_host.free()
	_main = null
	_stub = null
	_host = null


## O jogo real e a cena principal montada sobre ele; `visible` e `natural` são os valores dos interruptores postos ANTES de a cena entrar na árvore (o `_ready` os lê); `null` deixa o valor de nascença.
func _start(visible: Variant = null, natural: Variant = null) -> void:
	_host = SimulationHostNode.new()
	_host.start_new_game(SEED, _terrain, _points, null, 0, _economy)
	_stub = StubApp.new()
	_stub.name = "GameApp"
	_stub.stub_bridge = SimBridge.new(_host, _terrain, _places)
	_real_app = get_tree().root.get_node("GameApp")
	_real_index = _real_app.get_index()
	get_tree().root.remove_child(_real_app)
	get_tree().root.add_child(_stub)
	_main = (load(MAIN_SCENE) as PackedScene).instantiate()
	if visible != null:
		_main.set(VISIBLE, visible)
	if natural != null:
		_main.set(NATURAL, natural)
	add_child(_main)
	assert_push_error(SimBridge.CODE_NO_NPC)


func _caravan_nodes_in(node: Node) -> int:
	var count: int = 1 if node is CaravanBodiesView or node is CaravanView else 0
	for child: Node in node.get_children():
		count += _caravan_nodes_in(child)
	return count


func test_the_curves_switch_is_born_off_and_with_only_the_trip_visible_the_view_is_the_usual_one() -> void:
	_start(true)
	assert_eq(_main.get(NATURAL), false, "O interruptor das curvas nasce DESLIGADO.")
	var view: CaravanBodiesView = _main.get_node_or_null(VIEW_NAME) as CaravanBodiesView
	assert_not_null(view, "Com a viagem visível a vista existe.")
	assert_false(view.natural_curves(), "Só com `caravans_visible`, a vista fica no modo de sempre.")
	assert_eq(view.curve_radius_m(), CaravanBodiesView.CURVE_PATH_RADIUS_M, "O raio nasce na referência de 6 m.")
	view.reconcile()
	assert_eq([view.failed_queries, view.active_ids().size()], [0, 0], "A consulta funciona no modo de sempre.")


func test_with_both_switches_on_the_view_is_born_with_the_natural_curves() -> void:
	_start(true, true)
	var view: CaravanBodiesView = _main.get_node_or_null(VIEW_NAME) as CaravanBodiesView
	assert_not_null(view, "Ligados os dois, a vista existe.")
	assert_true(view.is_active(), "Ligada à ponte e ao terreno.")
	assert_true(view.natural_curves(), "E nasce com as curvas naturais ligadas.")
	view.reconcile()
	assert_eq([view.failed_queries, view.active_ids().size(), view.pool().lost_count()], [0, 0, 0], "A consulta funciona também no modo novo.")


func test_without_the_trip_visible_nothing_is_created_even_with_the_curves_switch_on() -> void:
	_start(null, true)
	assert_eq(_main.get(NATURAL), true, "Premissa: o interruptor das curvas foi ligado.")
	assert_null(_main.get_node_or_null(VIEW_NAME), "Sem `caravans_visible` a cena não cria a vista...")
	assert_eq(_caravan_nodes_in(_main), 0, "...nem corpo nenhum.")
