extends GutTest
## LW-097c: o `world` como módulo registrado, com o ESTADO de cada rota (`open` ou `closed`), os comandos `request_close_route` e
## `request_open_route` (só em build de desenvolvimento), o evento `RouteStateChanged`, o caminho só pelas rotas abertas e o save
## (`serialize`, `on_load`, `validate`; só a lista das rotas fechadas). Contrato: docs/modules/world.md, "Extensão da Fase 3".
## Os valores esperados estão escritos à mão a partir do contrato; o triângulo real é A-B, A-C e B-C (data/world/routes.json).

const BLOCKOUT_DIR: String = "res://data/world"
const WORLD_SEED: int = 5
const GAME_VERSION: String = "0.0.1-test"
const ROUTE_AB: String = "route_a_b"
const ROUTE_AC: String = "route_a_c"
const ROUTE_BC: String = "route_b_c"
const SETTLEMENT_A: String = "test_settlement_a"
const SETTLEMENT_B: String = "test_settlement_b"
const ROUTE_STATE_CHANGED: String = "RouteStateChanged"
const TRIGGER: String = "TestTrigger"

var _terrain: TerrainData
var _settlements: Array[Settlement] = []
var _codec: JsonSaveCodec = JsonSaveCodec.new()
var _runners: Array[SimulationRunner] = []
var _modules: GameModules
var _seen: Array[RouteStateChanged] = []


func before_all() -> void:
	var terrain_loaded: TerrainLoader.LoadResult = TerrainLoader.load_dir(BLOCKOUT_DIR)
	assert_true(terrain_loaded.result.ok, terrain_loaded.result.message)
	_terrain = terrain_loaded.terrain
	var loaded: SettlementLoader.LoadResult = SettlementLoader.load_dir(BLOCKOUT_DIR, _terrain)
	assert_true(loaded.result.ok, loaded.result.message)
	_settlements = loaded.settlements


func after_each() -> void:
	for runner: SimulationRunner in _runners:
		runner.finish()
	_runners.clear()
	_seen.clear()


## Um mundo com o `world` registrado e as rotas reais; `is_development_build` liga os comandos de desenvolvimento. `start` False deixa o
## mundo sem iniciar, para carregar um save nele.
func _new_game(is_development_build: bool = true, start: bool = true) -> SimulationRunner:
	var runner: SimulationRunner = SimulationRunner.new(WORLD_SEED)
	_runners.append(runner)
	var setup: WorldSetup = WorldSetup.from_dir(BLOCKOUT_DIR, _settlements, is_development_build)
	assert_true(setup.result.ok, setup.result.message)
	_modules = GameModules.register(runner, _terrain, [], null, null, setup)
	assert_true(_modules.result.ok, _modules.result.message)
	runner.world.context.events.subscribe(ROUTE_STATE_CHANGED, func(event: SimEvent) -> void: _seen.append(event as RouteStateChanged))
	if start:
		runner.start_new_game()
	return runner


func _dispatch(runner: SimulationRunner) -> void:
	runner.world.context.events.dispatch()


func test_the_world_is_a_registered_module_and_a_new_game_has_every_route_open_with_nothing_to_save() -> void:
	var runner: SimulationRunner = _new_game()
	var saved: Dictionary = runner.capture_game()
	assert_true(saved["world"]["modules"].has(GameModules.WORLD_NAME), "O `world` é um módulo registrado e tem a sua chave no save.")
	assert_eq(saved["world"]["modules"][GameModules.WORLD_NAME], {}, "Todas abertas: nada para salvar.")
	for route_id: String in [ROUTE_AB, ROUTE_AC, ROUTE_BC]:
		var query: WorldModule.RouteStateQuery = _modules.world.peek_route(route_id)
		assert_true(query.result.ok, query.result.message)
		assert_eq(query.state, WorldModule.STATE_OPEN)
	assert_eq(_modules.world.validate().size(), 0)
	assert_eq(_modules.world.peek_routes_of(SETTLEMENT_A).routes.size(), 2)


func test_closing_a_route_changes_the_path_and_closing_the_only_one_left_gives_no_path() -> void:
	var runner: SimulationRunner = _new_game()
	var world: WorldModule = _modules.world
	assert_eq(world.peek_path(SETTLEMENT_A, SETTLEMENT_B).route_ids, [ROUTE_AB] as Array[String])
	assert_true(world.request_close_route(ROUTE_AB).ok)
	assert_eq(world.peek_route(ROUTE_AB).state, WorldModule.STATE_CLOSED)
	var around: RouteService.PathQuery = world.peek_path(SETTLEMENT_A, SETTLEMENT_B)
	assert_eq(around.route_ids, [ROUTE_AC, ROUTE_BC] as Array[String], "Fechada a rota direta, o caminho passa pelo terceiro povoado.")
	assert_gt(around.total_length_m, 0)
	assert_true(world.request_close_route(ROUTE_AC).ok)
	assert_eq(world.peek_path(SETTLEMENT_A, SETTLEMENT_B).result.code, RouteService.CODE_NO_PATH, "A não tem mais nenhuma rota aberta.")
	assert_true(world.request_open_route(ROUTE_AB).ok)
	assert_eq(world.peek_path(SETTLEMENT_A, SETTLEMENT_B).route_ids, [ROUTE_AB] as Array[String], "Reaberta, a rota direta volta.")
	_dispatch(runner)
	assert_eq(runner.world.validate().size(), 0, "Com os eventos entregues, o mundo não tem problema.")


func test_the_commands_only_exist_in_a_development_build_and_change_nothing_otherwise() -> void:
	var runner: SimulationRunner = _new_game(false)
	var refused: Result = _modules.world.request_close_route(ROUTE_AB)
	assert_false(refused.ok)
	assert_eq(refused.code, WorldModule.CODE_DEV_ONLY)
	assert_eq(_modules.world.request_open_route(ROUTE_AB).code, WorldModule.CODE_DEV_ONLY)
	_dispatch(runner)
	assert_eq(_modules.world.peek_route(ROUTE_AB).state, WorldModule.STATE_OPEN)
	assert_eq(_seen.size(), 0, "Comando recusado não publica evento.")


func test_an_unknown_route_is_a_handled_error_and_asking_for_the_current_state_is_a_success_without_event() -> void:
	var runner: SimulationRunner = _new_game()
	assert_eq(_modules.world.request_close_route("route_zz").code, RouteService.CODE_ROUTE_UNKNOWN)
	assert_eq(_modules.world.request_open_route("route_zz").code, RouteService.CODE_ROUTE_UNKNOWN)
	assert_true(_modules.world.request_open_route(ROUTE_AB).ok, "Abrir uma rota que já está aberta é sucesso sem efeito.")
	assert_true(_modules.world.request_close_route(ROUTE_AB).ok)
	assert_true(_modules.world.request_close_route(ROUTE_AB).ok, "Fechar de novo também é sucesso sem efeito.")
	_dispatch(runner)
	assert_eq(_seen.size(), 1, "Um evento por mudança real, nunca por pedido repetido.")


func test_each_real_change_publishes_one_route_state_changed_with_the_route_and_the_new_state() -> void:
	var runner: SimulationRunner = _new_game()
	_modules.world.request_close_route(ROUTE_BC)
	_modules.world.request_open_route(ROUTE_BC)
	_dispatch(runner)
	assert_eq(_seen.size(), 2)
	assert_eq([_seen[0].route_id, _seen[0].new_state, _seen[1].route_id, _seen[1].new_state], [ROUTE_BC, WorldModule.STATE_CLOSED, ROUTE_BC, WorldModule.STATE_OPEN])
	assert_eq(_seen[0].type, ROUTE_STATE_CHANGED)


func test_an_event_caused_by_another_one_carries_its_cause_id() -> void:
	var runner: SimulationRunner = _new_game()
	var bus: EventBus = runner.world.context.events
	bus.subscribe(TRIGGER, func(_event: SimEvent) -> void: _modules.world.request_close_route(ROUTE_AB))
	var trigger: SimEvent = SimEvent.new(TRIGGER)
	bus.publish(trigger)
	_dispatch(runner)
	assert_eq(_seen.size(), 1)
	assert_eq(_seen[0].cause_id, trigger.id, "Publicado no tratamento de outro evento, leva o `cause_id` dele (regra do EventBus).")


func test_the_save_keeps_only_the_closed_routes_and_the_loaded_world_has_the_same_state_and_hash() -> void:
	var original: SimulationRunner = _new_game()
	var open_hash: String = original.world.state_hash()
	_modules.world.request_close_route(ROUTE_BC)
	_modules.world.request_close_route(ROUTE_AB)
	assert_ne(original.world.state_hash(), open_hash, "Uma rota fechada muda o hash do mundo.")
	var saved: Dictionary = original.capture_game()
	assert_eq(saved["world"]["modules"][GameModules.WORLD_NAME], {"closed_routes": [ROUTE_AB, ROUTE_BC]}, "Só os ids das rotas fechadas, em ordem crescente.")
	var decoded: DecodedSave = _codec.decode(_codec.encode(saved, GAME_VERSION))
	assert_true(decoded.result.ok, decoded.result.message)
	var restored: SimulationRunner = _new_game(true, false)
	var loaded: Result = restored.load_game(decoded.payload)
	assert_true(loaded.ok, loaded.message)
	assert_eq(restored.world.state_hash(), original.world.state_hash(), "O mundo carregado tem o hash do salvamento.")
	assert_eq(_modules.world.peek_route(ROUTE_AB).state, WorldModule.STATE_CLOSED)
	assert_eq(_modules.world.peek_route(ROUTE_AC).state, WorldModule.STATE_OPEN)
	assert_eq(restored.world.validate().size(), 0)


func test_a_save_with_an_unknown_duplicated_or_badly_typed_route_is_refused_before_changing_anything() -> void:
	_new_game()
	var world: WorldModule = _modules.world
	world.request_close_route(ROUTE_AC)
	for bad: Dictionary in [{"closed_routes": ["route_zz"]}, {"closed_routes": [ROUTE_AB, ROUTE_AB]}, {"closed_routes": [7]}, {"closed_routes": "route_a_b"}]:
		var refused: Result = world.on_load(bad)
		assert_false(refused.ok, "Deveria recusar: %s" % str(bad))
		assert_eq(refused.code, WorldModule.CODE_INVALID_SAVE)
		assert_string_contains(refused.message, "closed_routes")
		assert_eq(world.peek_route(ROUTE_AC).state, WorldModule.STATE_CLOSED, "Save recusado não muda o estado.")
	assert_true(world.on_load({}).ok, "Sem a chave: todas abertas.")
	assert_eq(world.peek_route(ROUTE_AC).state, WorldModule.STATE_OPEN)


func test_a_world_without_route_data_still_registers_and_answers_with_handled_errors() -> void:
	var runner: SimulationRunner = SimulationRunner.new(WORLD_SEED)
	_runners.append(runner)
	var modules: GameModules = GameModules.register(runner, _terrain)
	assert_true(modules.result.ok, modules.result.message)
	assert_eq(modules.world.peek_route(ROUTE_AB).result.code, RouteService.CODE_ROUTE_UNKNOWN)
	assert_eq(modules.world.request_close_route(ROUTE_AB).code, WorldModule.CODE_DEV_ONLY, "Sem a flag de desenvolvimento, o comando não existe.")
	runner.start_new_game()
	assert_eq(runner.capture_game()["world"]["modules"][GameModules.WORLD_NAME], {})


func test_the_setup_reads_the_real_routes_and_a_broken_folder_is_one_handled_failure() -> void:
	var setup: WorldSetup = WorldSetup.from_dir(BLOCKOUT_DIR, _settlements)
	assert_true(setup.result.ok, setup.result.message)
	assert_eq(setup.routes.peek_routes_of(SETTLEMENT_A).routes.size(), 2)
	assert_false(setup.is_development_build, "Padrão: não é build de desenvolvimento.")
	var broken: WorldSetup = WorldSetup.from_dir("res://tests/fixtures/world/pasta_que_nao_existe", _settlements)
	assert_false(broken.result.ok)
	assert_eq(broken.result.code, WorldSetup.CODE_INVALID)
	assert_string_contains(broken.result.message, "routes.json")
	var runner: SimulationRunner = SimulationRunner.new(WORLD_SEED)
	_runners.append(runner)
	assert_false(GameModules.register(runner, _terrain, [], null, null, broken).result.ok, "Dados de rota inválidos param o registro com a mensagem do carregador.")
