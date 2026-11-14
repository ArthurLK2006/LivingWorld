extends GutTest
## ART-5a: as luzes dos lampiões e das tochas da praça acendem e apagam com a hora. Sem janela, com o terreno e os locais reais de res://data e a ponte real (como test_market_plaza_view): o fator de luz (0 a 1) da MarketPlazaView
## e, na cena principal real, o estado de luz que a AmbientRig aplica e o sinal dela que o entrega às praças.
const BLOCKOUT_DIR: String = "res://data/world"
const MAIN_SCENE_PATH: String = "res://scenes/main.tscn"
const TOLERANCE: float = 0.0001
## A energia que a montagem dá a cada luz (a padrão da OmniLight3D): o fator a multiplica.
const BASE_ENERGY: float = 1.0
const LIGHTS_PER_PLAZA: int = 7
const HALF: float = 0.5
const NOON: float = 12.0
const MIDNIGHT: float = 0.0
## Sol a 9 graus (hora dourada pura).
const GOLDEN_HOUR: float = 17.425

var _bridge: SimBridge
var _markets: Array[Place] = []
var _chunk_size_m: float
var _view: MarketPlazaView


func before_all() -> void:
	var terrain_loaded: TerrainLoader.LoadResult = TerrainLoader.load_dir(BLOCKOUT_DIR)
	assert_true(terrain_loaded.result.ok, terrain_loaded.result.message)
	var loaded: SettlementLoader.LoadResult = SettlementLoader.load_dir(BLOCKOUT_DIR, terrain_loaded.terrain)
	assert_true(loaded.result.ok, loaded.result.message)
	for place: Place in loaded.places:
		if place.kind == Place.KIND_MARKET:
			_markets.append(place)
	_bridge = SimBridge.new(null, terrain_loaded.terrain, loaded.places)
	var layout: BridgeReplies.TerrainLayoutReply = _bridge.peek_terrain_layout()
	_chunk_size_m = float(layout.chunk_cells) * layout.cell_size_m


func before_each() -> void:
	_view = MarketPlazaView.new()
	add_child_autofree(_view)
	assert_true(_view.setup(_bridge))


func _lights(root: Node) -> Array[Node]:
	return root.find_children("*", "OmniLight3D", true, false)


## Todas as luzes abaixo de `root` (7 por praça) estão com o `visible` e a energia esperados.
func _assert_lights(root: Node, shown: bool, energy: float, label: String) -> void:
	var lights: Array[Node] = _lights(root)
	assert_eq(lights.size(), _markets.size() * LIGHTS_PER_PLAZA, "Luzes (%s)." % label)
	for node: Node in lights:
		assert_eq((node as OmniLight3D).visible, shown, "Visível (%s)." % label)
		assert_almost_eq((node as OmniLight3D).light_energy, energy, TOLERANCE, "Energia (%s)." % label)


func test_the_lamp_factor_scales_the_base_energy_and_hides_the_lights_of_every_plaza() -> void:
	var nodes_before: int = _view.find_children("*", "", true, false).size()
	_assert_lights(_view, false, 0.0, "praça recém-montada: fator 0")
	_view.set_lamp_factor(1.0)
	_assert_lights(_view, true, BASE_ENERGY, "fator 1")
	_view.set_lamp_factor(HALF)
	_assert_lights(_view, true, BASE_ENERGY * HALF, "fator 0,5")
	_view.set_lamp_factor(0.0)
	_assert_lights(_view, false, 0.0, "fator 0")
	_view.set_lamp_factor(MarketPlazaView.LAMP_ON_THRESHOLD)
	_assert_lights(_view, false, BASE_ENERGY * MarketPlazaView.LAMP_ON_THRESHOLD, "fator no limiar: escondida")
	_view.set_lamp_factor(MarketPlazaView.LAMP_ON_THRESHOLD * 2.0)
	_assert_lights(_view, true, BASE_ENERGY * MarketPlazaView.LAMP_ON_THRESHOLD * 2.0, "fator acima do limiar: visível")
	_view.set_lamp_factor(2.0)
	_assert_lights(_view, true, BASE_ENERGY, "fator acima de 1: limitado a 1")
	_view.set_lamp_factor(-1.0)
	_assert_lights(_view, false, 0.0, "fator abaixo de 0: limitado a 0")
	assert_eq(_view.find_children("*", "", true, false).size(), nodes_before, "Nenhum nó criado nem perdido.")


func test_the_lights_of_hidden_plazas_are_already_right_when_the_chunk_loads_and_a_new_assembly_is_born_with_the_factor() -> void:
	var market: Place = _markets[0]
	var chunk: Vector2i = Vector2i(floori(market.position.x / _chunk_size_m), floori(market.position.z / _chunk_size_m))
	_view.set_lamp_factor(1.0)
	_assert_lights(_view, true, BASE_ENERGY, "praças escondidas")
	for light: Node in _lights(_view.plaza_of(market.id)):
		assert_false((light as OmniLight3D).is_visible_in_tree(), "Praça escondida: a luz acesa não aparece.")
	_view.set_chunk_visible(chunk, true)
	for light: Node in _lights(_view.plaza_of(market.id)):
		assert_true((light as OmniLight3D).is_visible_in_tree(), "Ao carregar o chunk a luz já está acesa.")
	_view.set_lamp_factor(HALF)
	assert_true(_view.setup(_bridge))
	_assert_lights(_view, true, BASE_ENERGY * HALF, "montagem nova com o fator em vigor")
	_view.set_lamp_factor(1.0)
	_assert_lights(_view, true, BASE_ENERGY, "e a montagem nova segue os fatores seguintes")


func test_the_main_scene_lights_start_right_and_follow_the_light_the_rig_applies() -> void:
	var main: Node = add_child_autofree((load(MAIN_SCENE_PATH) as PackedScene).instantiate())
	var rig: AmbientRig = main.get_node("AmbientRig") as AmbientRig
	rig.set_process(false)
	var plazas: MarketPlazaView = main.get_node("MarketPlazaView") as MarketPlazaView
	assert_eq(plazas.plaza_count(), _markets.size())
	_assert_lights(plazas, true, BASE_ENERGY, "início do jogo, à meia-noite: a cena deu o fator inicial da rig")
	assert_true(rig.apply_state(DayNightCycle.state_at(rig.config, NOON)))
	_assert_lights(plazas, false, 0.0, "meio-dia")
	assert_true(rig.apply_state(DayNightCycle.state_at(rig.config, MIDNIGHT)))
	_assert_lights(plazas, true, BASE_ENERGY, "meia-noite")
	var golden: DayNightCycle.LightState = DayNightCycle.state_at(rig.config, GOLDEN_HOUR)
	assert_true(rig.apply_state(golden))
	_assert_lights(plazas, golden.lamp_factor > MarketPlazaView.LAMP_ON_THRESHOLD, BASE_ENERGY * golden.lamp_factor, "hora dourada: o fator do estado")
