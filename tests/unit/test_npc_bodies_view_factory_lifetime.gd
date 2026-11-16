extends GutTest
## ART-12, 7b-2 (regressão da revisão independente): `source.make` é um `Callable` de método de um `RefCounted`, e um `Callable` NÃO segura o objeto. Como na `main_world_view._setup_npc_bodies`, onde a fonte é local e só `source.make` vai à view, a fonte morria ao fim do preparo e a fábrica ficava inválida: o NPC da área seguia cápsula e o log trazia `SCRIPT ERROR: Attempt to call function 'null::make (Callable)'`. A view tem de guardar o DONO da fábrica. Jogo montado como o real (dados reais, 100 NPCs, ponte real e `TerrainView` de verdade).

const DATA_DIR: String = "res://data"
const WORLD_SEED: int = 5
const A_M: Vector3 = Vector3(320.0, 10.0, 540.0)
const FIGURE_ID: String = "synthetic"
const AREA_JSON: String = '{"version": 1, "entries": [{"npc_id": %d, "figure": "%s"}]}'

var _data: NpcLifeCheck.GameData
var _host: SimulationHostNode
var _bridge: SimBridge
var _view: NpcBodiesView
var _actor_id: int = 0
var _chosen: int = 0
var _built: int = 0
var _source_ref: WeakRef


func before_all() -> void:
	_data = NpcLifeCheck.load_game_data()
	assert_eq(_data.problem, "", "Os dados reais do jogo carregam.")


func after_each() -> void:
	if _view != null:
		_view.release()
	if _host != null:
		_host.runner.finish()
		_host.free()
	_view = null
	_host = null


func _builder(_figure_id: String) -> Node3D:
	_built += 1
	return Node3D.new()


func _exists(_path: String) -> bool:
	return true


func _area_text(_path: String) -> String:
	return AREA_JSON % [_chosen, FIGURE_ID]


## Como a `main_world_view`: a fonte só existe nesta função, e a view recebe apenas `source.make`.
func _setup_like_the_scene(terrain: TerrainView, area: CharacterArea) -> bool:
	var catalog: CharacterCatalog = CharacterCatalog.from_file(CharacterCatalog.DEFAULT_PATH, _exists).catalog
	var source: CharacterFigureSource = CharacterFigureSource.prepare(area, catalog, _builder)
	_source_ref = weakref(source)
	return _view.setup(_bridge, terrain, area, source.make)


func _tick() -> void:
	assert_true(_bridge.request_report_position(_actor_id, A_M, 0.0).ok)
	_host.runner.step_once()
	_view.reconcile()


func test_the_figure_arrives_when_the_view_is_the_only_holder_of_the_source() -> void:
	var setup: NpcSetup = NpcSetup.from_dir(DATA_DIR, SettlementService.new(_data.settlements, _data.places))
	_host = SimulationHostNode.new()
	_host.start_new_game(WORLD_SEED, _data.terrain, _data.points, setup)
	_bridge = SimBridge.new(_host, _data.terrain, _data.places, _host.npc)
	_actor_id = _bridge.request_spawn_character().actor_id
	var terrain: TerrainView = TerrainView.new()
	add_child_autofree(terrain)
	terrain.setup(_bridge)
	terrain.set_process(false)
	_view = NpcBodiesView.new()
	add_child_autofree(_view)
	assert_true(_view.setup(_bridge, terrain))
	_tick()
	assert_false(_view.active_ids().is_empty(), "Com o jogador em A há NPCs em S0.")
	_chosen = _view.active_ids()[0]
	assert_true(_setup_like_the_scene(terrain, CharacterArea.from_files([CharacterArea.DEFAULT_PATH], _area_text)))
	_tick()
	assert_true(_view.active_ids().has(_chosen), "O NPC escolhido continua em S0.")
	assert_true(_view.pool().body_of(_chosen).has_figure(), "A figura chega mesmo com a fonte fora de escopo.")
	assert_eq(_built, 1, "A figura foi preparada UMA vez.")
	assert_not_null(_source_ref.get_ref(), "A view segura o dono da fábrica: a fonte segue viva.")
	assert_false(_view.setup(null, terrain), "Um `setup` que falha (ponte nula)...")
	assert_push_error("ponte ou TerrainView nulo")
	assert_null(_source_ref.get_ref(), "...solta o dono da fábrica, porque o `_clear` o zera antes de qualquer falha.")
