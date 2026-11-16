extends GutTest
## ART-12, 7b-2: a `NpcBodiesView` põe a figura (SINTÉTICA, em memória, por uma fábrica injetada) no corpo do NPC da área ao entrar em S0, com o jogo montado como o real (dados reais, 100 NPCs, ponte real e `TerrainView` de verdade): exatamente aquele NPC tem figura e os demais, cápsula; sair de S0 e o `release` devolvem a cápsula; a reserva não vaza nem duplica e o corpo reciclado não herda a figura; fábrica que devolve null = cápsula e UM aviso por NPC; área vazia ou fábrica inválida = a view de sempre.

const DATA_DIR: String = "res://data"
const WORLD_SEED: int = 5
const A_M: Vector3 = Vector3(320.0, 10.0, 540.0)
## Longe dos três povoados: todo NPC sai de S0 (o raio de saída é de 120 m).
const FAR_M: Vector3 = Vector3(700.0, 10.0, 960.0)
const FIGURE_ID: String = "synthetic"
const AREA_JSON: String = '{"version": 1, "entries": [{"npc_id": %d, "figure": "%s"}]}'

var _data: NpcLifeCheck.GameData
var _host: SimulationHostNode
var _bridge: SimBridge
var _terrain: TerrainView
var _view: NpcBodiesView
var _actor_id: int = 0
var _chosen: int = 0
var _calls: int = 0
var _delivers: bool = true
var _made: Array[Node3D] = []


func before_all() -> void:
	_data = NpcLifeCheck.load_game_data()
	assert_eq(_data.problem, "", "Os dados reais do jogo carregam.")


## O GUT usa uma só instância do script em todos os testes: o estado volta ao zero antes de cada um.
func before_each() -> void:
	_calls = 0
	_delivers = true
	_made.clear()


func after_each() -> void:
	if _view != null:
		_view.release()
	if _host != null:
		_host.runner.finish()
		_host.free()
	_view = null
	_host = null


## A fábrica sintética: conta as chamadas, confere o id e entrega uma figura solta (ou null, se `_delivers` é falso).
func _factory(figure_id: String) -> Node3D:
	_calls += 1
	assert_eq(figure_id, FIGURE_ID, "A fábrica recebe o id da figura da área.")
	if not _delivers:
		return null
	var figure: Node3D = Node3D.new()
	_made.append(figure)
	return figure


func _area_text(_path: String) -> String:
	return AREA_JSON % [_chosen, FIGURE_ID]


## Jogo novo igual ao real, o jogador em A e a view ligada duas vezes: a 1ª, sem área, só para escolher um NPC que está em S0; a 2ª, com a área desse NPC e a fábrica sintética (ou sem uma delas).
func _start(with_area: bool = true, with_factory: bool = true) -> void:
	var setup: NpcSetup = NpcSetup.from_dir(DATA_DIR, SettlementService.new(_data.settlements, _data.places))
	assert_true(setup.result.ok, setup.result.message)
	_host = SimulationHostNode.new()
	_host.start_new_game(WORLD_SEED, _data.terrain, _data.points, setup)
	_bridge = SimBridge.new(_host, _data.terrain, _data.places, _host.npc)
	_actor_id = _bridge.request_spawn_character().actor_id
	_terrain = TerrainView.new()
	add_child_autofree(_terrain)
	_terrain.setup(_bridge)
	_terrain.set_process(false)
	_view = NpcBodiesView.new()
	add_child_autofree(_view)
	assert_true(_view.setup(_bridge, _terrain))
	_tick(A_M)
	assert_false(_view.active_ids().is_empty(), "Com o jogador em A há NPCs em S0.")
	_chosen = _view.active_ids()[0]
	var area: CharacterArea = CharacterArea.from_files([CharacterArea.DEFAULT_PATH], _area_text) if with_area else CharacterArea.new()
	assert_true(_view.setup(_bridge, _terrain, area, _factory if with_factory else Callable()))
	_tick(A_M)
	assert_true(_view.active_ids().has(_chosen), "O NPC escolhido continua em S0.")


## O jogador vai a `spot_m`, um passo da simulação e a view em dia.
func _tick(spot_m: Vector3) -> void:
	assert_true(_bridge.request_report_position(_actor_id, spot_m, 0.0).ok)
	_host.runner.step_once()
	_view.reconcile()


## Quantos corpos da reserva (ativos e livres) têm figura.
func _figured() -> int:
	var count: int = 0
	for child: Node in _view.get_children():
		if child is NpcView and (child as NpcView).has_figure():
			count += 1
	return count


func test_only_the_npc_of_the_area_gets_the_figure_as_a_child_of_its_body() -> void:
	_start()
	for npc_id: int in _view.active_ids():
		assert_eq(_view.pool().body_of(npc_id).has_figure(), npc_id == _chosen, "NPC %d: figura só no da área." % npc_id)
	assert_eq([_calls, _made.size(), _figured()], [1, 1, 1], "A fábrica roda UMA vez e só um corpo tem figura.")
	assert_true(_made[0].get_parent() == _view.pool().body_of(_chosen), "A figura é filha do corpo do NPC da área.")


func test_leaving_s0_and_release_return_the_capsule_and_the_reserve_neither_leaks_nor_duplicates() -> void:
	_start()
	var pool: NpcViewPool = _view.pool()
	var body: NpcView = pool.body_of(_chosen)
	var figure: Node3D = _made[0]
	_tick(FAR_M)
	assert_eq(_view.active_ids().size(), 0, "O jogador longe: ninguém em S0.")
	assert_true(not body.has_figure() and figure.get_parent() == null and figure.is_queued_for_deletion(), "Sair de S0 devolve a cápsula e libera a figura.")
	assert_true((body.get_node(NpcView.VISUAL_NAME) as Node3D).visible, "A cápsula do corpo reciclado volta.")
	assert_eq(_figured(), 0, "A reserva não guarda figura.")
	_tick(A_M)
	assert_eq([_calls, _made.size(), _made[1] != figure, _figured()], [2, 2, true, 1], "Ao voltar a S0 a fábrica entrega uma figura NOVA e só o NPC da área a tem: o corpo reciclado não herda a antiga.")
	assert_eq([pool.created, pool.duplicate_requests, pool.lost_count(), pool.taken - pool.returned], [NpcViewPool.PREWARM_COUNT, 0, 0, pool.active_count()], "A reserva não cresce, não duplica e não perde corpo.")
	_view.release()
	assert_true(_figured() == 0 and _made[1].get_parent() == null and _made[1].is_queued_for_deletion(), "O `release` devolve a cápsula e libera a figura.")


func test_a_factory_that_returns_null_leaves_the_capsule_and_warns_once_per_npc() -> void:
	_delivers = false
	_start()
	assert_eq([_calls, _view.pool().body_of(_chosen).has_figure()], [1, false], "Fábrica que devolve null: cápsula.")
	for _frame: int in 3:
		_view.reconcile()
	_tick(FAR_M)
	_tick(A_M)
	assert_eq([_calls, _figured()], [2, 0], "Ao reentrar a fábrica é tentada de novo, e a cápsula fica.")
	assert_push_warning("o NPC %d segue cápsula" % _chosen)
	assert_push_warning_count(1, "UM aviso por NPC: nem um por quadro nem um por reentrada.")


func test_an_empty_area_leaves_every_body_a_capsule_and_never_calls_the_factory() -> void:
	_start(false, true)
	assert_eq([_calls, _figured()], [0, 0], "Área vazia: a fábrica nunca roda.")
	assert_push_warning_count(0, "Nenhum aviso.")


func test_an_invalid_factory_leaves_every_body_a_capsule_without_warnings() -> void:
	_start(true, false)
	assert_eq([_calls, _figured()], [0, 0], "Sem fábrica válida a área não vale.")
	assert_push_warning_count(0, "Nenhum aviso.")
