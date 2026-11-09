extends GutTest
## LW-042b: a hora em que o mundo NOVO começa. O `SimulationRunner` aceita um tempo inicial opcional (padrão 0), o host o repassa e o `GameApp` usa a
## constante NEW_GAME_START_MINUTE [HIP]. Quem não passa o parâmetro segue começando em 00:00, e carregar um save restaura o tempo salvo.

const WORLD_SEED: int = 3
## 05:45, a hora do exemplo dos testes de runner (não é a do jogo, que vem da constante do GameApp).
const DAWN_MINUTE: int = 345
const STEPS_TO_SIX: int = 15
const HASH_STEPS: int = 60
const SAVED_STEPS: int = 10
const OTHER_START_MINUTE: int = 100

var _hosts: Array[SimulationHostNode] = []
var _apps: Array[GameAppNode] = []


func after_each() -> void:
	for host: SimulationHostNode in _hosts:
		host.runner.finish()
		host.free()
	for app: GameAppNode in _apps:
		app.free()
	_hosts.clear()
	_apps.clear()


func _new_host() -> SimulationHostNode:
	var host: SimulationHostNode = SimulationHostNode.new()
	_hosts.append(host)
	return host


func test_a_runner_starts_at_the_given_minute_and_starting_the_game_keeps_it() -> void:
	var runner: SimulationRunner = SimulationRunner.new(WORLD_SEED, DAWN_MINUTE)
	assert_eq(runner.world.context.clock.total_minutes(), DAWN_MINUTE)
	assert_eq(runner.format_clock_line(), "ano 1, dia 1, 05:45")
	runner.start_new_game()
	assert_eq(runner.format_clock_line(), "ano 1, dia 1, 05:45", "Começar o jogo não mexe no tempo.")
	runner.run_steps(STEPS_TO_SIX)
	assert_eq(runner.format_clock_line(), "ano 1, dia 1, 06:00", "O tempo anda a partir da hora inicial.")
	runner.finish()


func test_the_default_start_is_midnight_and_passing_zero_changes_nothing_in_the_world() -> void:
	var by_default: SimulationRunner = SimulationRunner.new(WORLD_SEED)
	var explicit_zero: SimulationRunner = SimulationRunner.new(WORLD_SEED, 0)
	assert_eq(by_default.format_clock_line(), "ano 1, dia 1, 00:00")
	for runner: SimulationRunner in [by_default, explicit_zero]:
		runner.start_new_game()
		runner.run_steps(HASH_STEPS)
	assert_eq(explicit_zero.world.state_hash(), by_default.world.state_hash(), "Sem o parâmetro e com 0 o mundo é o mesmo (nenhum hash existente muda).")
	by_default.finish()
	explicit_zero.finish()


func test_a_start_minute_outside_the_clock_range_is_rejected_with_an_error_and_the_clock_stays_at_zero() -> void:
	for invalid_minute: int in [-1, SimClock.MAX_TOTAL_MINUTES + 1]:
		var runner: SimulationRunner = SimulationRunner.new(WORLD_SEED, invalid_minute)
		assert_push_error("tempo inicial")
		assert_eq(runner.world.context.clock.total_minutes(), 0, "Tempo inicial %d: o relógio fica em 0." % invalid_minute)


func test_the_limits_of_the_clock_range_are_accepted() -> void:
	for limit_minute: int in [0, SimClock.MAX_TOTAL_MINUTES]:
		var runner: SimulationRunner = SimulationRunner.new(WORLD_SEED, limit_minute)
		assert_eq(runner.world.context.clock.total_minutes(), limit_minute)


func test_the_host_passes_the_start_minute_to_the_runner_and_defaults_to_midnight() -> void:
	var host: SimulationHostNode = _new_host()
	host.start_new_game(WORLD_SEED)
	assert_eq(host.runner.world.context.clock.total_minutes(), 0, "Sem o parâmetro o host começa em 00:00.")
	host.start_new_game(WORLD_SEED, null, [], null, DAWN_MINUTE)
	assert_eq(host.runner.world.context.clock.total_minutes(), DAWN_MINUTE, "Com o parâmetro o host repassa a hora ao runner.")


func test_the_game_app_starts_the_new_game_at_the_new_game_start_minute() -> void:
	var host: SimulationHostNode = _new_host()
	var app: GameAppNode = GameAppNode.new()
	_apps.append(app)
	app.bind_host(host)
	app.start_default_game(host)
	assert_not_null(host.npc, "É o jogo de verdade: com o terreno e os NPCs.")
	assert_eq(host.runner.world.context.clock.total_minutes(), GameAppNode.NEW_GAME_START_MINUTE, "O jogo novo usa a constante.")


func test_loading_a_save_restores_the_saved_time_over_the_start_minute() -> void:
	var saved: SimulationRunner = SimulationRunner.new(WORLD_SEED, DAWN_MINUTE)
	saved.start_new_game()
	saved.run_steps(SAVED_STEPS)
	assert_true(saved.can_capture_game())
	var loaded: SimulationRunner = SimulationRunner.new(WORLD_SEED, OTHER_START_MINUTE)
	var outcome: Result = loaded.load_game(saved.capture_game())
	assert_true(outcome.ok, outcome.message)
	assert_eq(loaded.world.context.clock.total_minutes(), DAWN_MINUTE + SAVED_STEPS, "O tempo salvo vale, não o tempo inicial do runner novo.")
	saved.finish()
	loaded.finish()
