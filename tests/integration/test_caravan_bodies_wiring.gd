extends GutTest
## LW-099b2b: a LIGAÇÃO da vista das caravanas na cena principal (`main_world_view.gd`), sem janela. A cena REAL (res://scenes/main.tscn) é montada sobre o jogo real de res://data (terreno, locais, pontos e economia) e a ponte real, sem o módulo `npc`, como em
## `test_market_open.gd`: um GameApp de teste no lugar do autoload. O interruptor `caravans_visible` nasce DESLIGADO e, desligado, a cena não cria nada da viagem visível (nem a vista, nem a reserva de corpos); ligado, cria a `CaravanBodiesView` ligada à ponte e ao
## terreno, com a reserva de corpos escondidos (o tamanho vem do dado de apresentação) e a consulta das caravanas funcionando; e o resto da cena segue igual.

const WORLD_DIR: String = "res://data/world"
const MAIN_SCENE: String = "res://scenes/main.tscn"
const SEED: int = 99
const SWITCH: StringName = &"caravans_visible"
const VIEW_NAME: String = "CaravanBodiesView"
const NPC_VIEW_NAME: String = "NpcBodiesView"

var _terrain: TerrainData
var _places: Array[Place] = []
var _points: Array[PointOfInterest] = []
var _economy: EconomySetup
var _routes: CaravanRoutesReader
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
	var routes: CaravanRoutesReader.LoadResult = CaravanRoutesReader.from_file()
	assert_true(routes.result.ok, routes.result.message)
	_routes = routes.data


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


## O jogo real e a cena principal montada sobre ele; `visible` é o valor do interruptor posto ANTES de a cena entrar na árvore (o `_ready` o lê); `null` deixa o valor de nascença.
func _start(visible: Variant = null) -> void:
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
		_main.set(SWITCH, visible)
	add_child(_main)
	assert_push_error(SimBridge.CODE_NO_NPC)


## Quantos nós de corpo de caravana (a vista ou um corpo da reserva) a cena tem, em qualquer profundidade.
func _caravan_nodes_in(node: Node) -> int:
	var count: int = 1 if node is CaravanBodiesView or node is CaravanView else 0
	for child: Node in node.get_children():
		count += _caravan_nodes_in(child)
	return count


func test_the_switch_is_born_off_and_off_the_scene_creates_nothing_of_the_visible_trip() -> void:
	_start()
	assert_eq(_main.get(SWITCH), false, "O interruptor nasce DESLIGADO.")
	assert_null(_main.get_node_or_null(VIEW_NAME), "Desligado, a cena não cria a vista das caravanas.")
	assert_eq(_caravan_nodes_in(_main), 0, "Nem a reserva de corpos: nenhum `CaravanView` na cena.")
	assert_not_null(_main.get_node_or_null(NPC_VIEW_NAME), "O resto da cena segue como sempre (a vista dos NPCs está lá).")


func test_off_by_name_is_the_same_as_the_default() -> void:
	_start(false)
	assert_null(_main.get_node_or_null(VIEW_NAME), "Desligado de propósito: o mesmo que o valor de nascença (nenhuma vista)...")
	assert_eq(_caravan_nodes_in(_main), 0, "...e nenhum corpo de caravana.")


func test_on_the_scene_creates_the_view_with_its_hidden_pool_and_a_working_query() -> void:
	_start(true)
	var view: CaravanBodiesView = _main.get_node_or_null(VIEW_NAME) as CaravanBodiesView
	assert_not_null(view, "Ligado, a cena cria a vista das caravanas.")
	assert_true(view.is_active(), "Ligada à ponte e ao terreno.")
	assert_eq(view.pool().created, _routes.pool_size, "Com a reserva do tamanho do dado de apresentação.")
	assert_eq(_caravan_nodes_in(_main), _routes.pool_size + 1, "A vista e os corpos da reserva (filhos dela).")
	for trader_id: int in view.active_ids():
		fail_test("Sem ninguém em viagem nenhum corpo está em uso (comerciante %d)." % trader_id)
	view.reconcile()
	assert_eq([view.failed_queries, view.active_ids().size(), view.pool().lost_count()], [0, 0, 0], "A consulta das caravanas à ponte real funciona e não lista ninguém.")
	for child: Node in view.get_children():
		assert_false((child as Node3D).visible, "Todo corpo da reserva nasce escondido.")
	assert_not_null(_main.get_node_or_null(NPC_VIEW_NAME), "E o resto da cena segue como sempre.")
