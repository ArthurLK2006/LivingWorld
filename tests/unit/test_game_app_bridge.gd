extends GutTest
## LW-037B: o GameApp cria e guarda a ponte (peek_bridge), de forma preguiçosa e sem autoload novo.

## Terreno de teste pequeno (rápido de ler) para os casos que não dependem do terreno de blockout.
const SMALL_TERRAIN_DIR: String = "res://tests/fixtures/world/terrain_ok"
const MISSING_TERRAIN_DIR: String = "res://tests/fixtures/world/pasta_que_nao_existe"
## Folga para comparar o ponto de nascimento com a altura do mesmo ponto (metros).
const HEIGHT_TOLERANCE_M: float = 0.001

var _host: SimulationHostNode
var _app: GameAppNode


func before_each() -> void:
	_host = SimulationHostNode.new()
	_host.start_new_game(3)
	_app = GameAppNode.new()
	_app.bind_host(_host)


func after_each() -> void:
	_app.free()
	_host.runner.finish()
	_host.free()


func test_two_calls_return_the_same_instance() -> void:
	_app.terrain_dir = SMALL_TERRAIN_DIR
	var first: SimBridge = _app.peek_bridge()
	assert_not_null(first)
	assert_same(_app.peek_bridge(), first, "A segunda chamada devolve a mesma ponte, não uma nova.")


func test_with_the_real_data_the_spawn_point_matches_the_height_at_the_same_place() -> void:
	var bridge: SimBridge = _app.peek_bridge()
	var spawn: SimBridge.SpawnReply = bridge.peek_spawn_point()
	assert_true(spawn.result.ok, spawn.result.message)
	var height: SimBridge.HeightReply = bridge.peek_height(spawn.point.x, spawn.point.z)
	assert_true(height.result.ok, height.result.message)
	assert_almost_eq(spawn.point.y, height.height_m, HEIGHT_TOLERANCE_M, "y do nascimento = altura do chão no mesmo ponto.")
	var layout: SimBridge.TerrainLayoutReply = bridge.peek_terrain_layout()
	assert_true(layout.result.ok, "Os dados reais de data/world foram carregados: " + layout.result.message)
	assert_eq(layout.chunk_count, Vector2i(16, 16))


func test_missing_terrain_folder_gives_a_bridge_without_terrain_and_a_visible_error() -> void:
	_app.terrain_dir = MISSING_TERRAIN_DIR
	var bridge: SimBridge = _app.peek_bridge()
	assert_not_null(bridge, "A ponte é devolvida mesmo sem terreno.")
	assert_push_error("GameApp.peek_bridge: terreno não carregado")
	var height: SimBridge.HeightReply = bridge.peek_height(1.0, 1.0)
	assert_false(height.result.ok)
	assert_eq(height.result.code, SimBridge.CODE_NO_TERRAIN)
	assert_eq(bridge.peek_terrain_layout().result.code, SimBridge.CODE_NO_TERRAIN)
	assert_true(bridge.peek_time().result.ok, "O que não depende do terreno continua funcionando.")


func test_without_a_bound_host_the_bridge_is_returned_and_time_fails() -> void:
	var unbound: GameAppNode = GameAppNode.new()
	unbound.terrain_dir = SMALL_TERRAIN_DIR
	var bridge: SimBridge = unbound.peek_bridge()
	assert_not_null(bridge)
	var time: SimBridge.TimeSnapshot = bridge.peek_time()
	assert_false(time.result.ok)
	assert_eq(time.result.code, SimBridge.CODE_NO_GAME)
	assert_true(bridge.peek_height(1.0, 1.0).result.ok, "O terreno não depende de haver host.")
	unbound.free()


func test_the_bridge_sees_the_host_bound_before_the_first_call() -> void:
	_app.terrain_dir = SMALL_TERRAIN_DIR
	var bridge: SimBridge = _app.peek_bridge()
	_host.runner.run_steps(5)
	var time: SimBridge.TimeSnapshot = bridge.peek_time()
	assert_true(time.result.ok, time.result.message)
	assert_eq(time.total_minutes, 5, "A ponte lê o relógio do host que o GameApp tinha ligado.")


func test_the_folder_is_read_only_on_the_first_call() -> void:
	_app.terrain_dir = MISSING_TERRAIN_DIR
	_app.terrain_dir = SMALL_TERRAIN_DIR
	var bridge: SimBridge = _app.peek_bridge()
	assert_true(bridge.peek_terrain_layout().result.ok, "Nada foi lido antes da primeira chamada: vale a pasta de então.")
	_app.terrain_dir = MISSING_TERRAIN_DIR
	assert_same(_app.peek_bridge(), bridge, "Trocar a pasta depois não recarrega nem recria a ponte.")
	assert_true(bridge.peek_terrain_layout().result.ok)
