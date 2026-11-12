extends GutTest
## LW-070a: a ligação do LOD e dos Intents ao jogo (docs/modules/app.md e npc.md), sem janela: o `NpcSetup` lê os dois arquivos de parâmetros
## e falha com o nome do arquivo; o módulo liga o LOD no `setup` (o foco do jogador vale antes do primeiro passo) e os Intents no ponto do
## pensador; sem os parâmetros tudo fica desligado, como nos testes antigos; o host expõe o módulo `npc`; o `GameApp` o entrega à ponte; e a
## cadeia inteira (jogador, ponte, LOD, decisão, Intent, ponte, resultado) funciona com os dados reais. Os fluxos longos estão em
## tests/integration/test_npc_s0_flow.gd.

const DATA_DIR: String = "res://data"
const WORLD_DIR: String = "res://data/world"
const WORLD_SEED: int = 5
const FOCUS_A_M: Vector3 = Vector3(320.0, 10.0, 540.0)
const FIRST_THINKS_DONE: int = 12
## LW-070b: às 6h a rotina troca o sono por `eat` (20 min) e o NPC em S0 reavalia como em S1; 6h12 = todos já têm o Intent de `eat`.
const AFTER_THE_ROUTINE_SWAP: int = 6 * 60 + 12
const HUNGER: int = 0
const MAX_S0: int = 50
const TEMP_ROOT: String = "res://.godot/lw070a_data_tests"

var _terrain: TerrainData
var _points: Array[PointOfInterest] = []
var _settlements: Array[Settlement] = []
var _places: Array[Place] = []
var _temp_dirs: Array[String] = []
var _hosts: Array[SimulationHostNode] = []


func before_all() -> void:
	var data: NpcLifeCheck.GameData = NpcLifeCheck.load_game_data()
	assert_eq(data.problem, "", "Os dados reais do jogo carregam.")
	_terrain = data.terrain
	_points = data.points
	_settlements = data.settlements
	_places = data.places


func after_each() -> void:
	for host: SimulationHostNode in _hosts:
		if host.runner != null:
			host.runner.finish()
		host.free()
	_hosts.clear()
	for dir_path: String in _temp_dirs:
		for file_name: String in DirAccess.get_files_at(dir_path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(dir_path.path_join(file_name)))
		DirAccess.remove_absolute(ProjectSettings.globalize_path(dir_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP_ROOT))
	_temp_dirs.clear()


func _setup(data_dir: String = DATA_DIR) -> NpcSetup:
	return NpcSetup.from_dir(data_dir, SettlementService.new(_settlements, _places))


func _good_setup() -> NpcSetup:
	var setup: NpcSetup = _setup()
	assert_true(setup.result.ok, setup.result.message)
	return setup


## Distância no plano, em metros, de um ponto ao foco (centro do assentamento A).
func _distance_to_focus_m(point: Vector3) -> float:
	return Vector2(point.x, point.z).distance_to(Vector2(FOCUS_A_M.x, FOCUS_A_M.z))


## Copia os .json de res://data para uma pasta de teste, trocando o texto de `replaced_file` (e pulando `skipped_file`).
func _copy_data(replaced_file: String = "", replacement: String = "", skipped_file: String = "") -> String:
	var dir_path: String = "%s/case_%d" % [TEMP_ROOT, _temp_dirs.size()]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir_path))
	for file_name: String in DirAccess.get_files_at(DATA_DIR):
		if not file_name.ends_with(".json") or file_name == skipped_file:
			continue
		var text: String = replacement if file_name == replaced_file else FileAccess.get_file_as_string(DATA_DIR.path_join(file_name))
		var file: FileAccess = FileAccess.open(dir_path.path_join(file_name), FileAccess.WRITE)
		file.store_string(text)
		file.close()
	_temp_dirs.append(dir_path)
	return dir_path


# ---------------------------------------------------------------------------------------------------- os dados

func test_the_real_setup_carries_the_lod_and_intent_parameters() -> void:
	var definitions: NpcModule.Definitions = _good_setup().definitions
	assert_not_null(definitions.lod_params)
	assert_eq([definitions.lod_params.lod_enter_radius_m, definitions.lod_params.lod_exit_radius_m, definitions.lod_params.max_s0], [80, 120, 50])
	assert_not_null(definitions.intent_params)
	assert_eq(definitions.intent_params.intent_timeout_min, 30)


func test_a_copy_of_the_data_loads_and_a_broken_parameter_file_stops_the_setup_naming_the_file() -> void:
	var good: NpcSetup = _setup(_copy_data())
	assert_true(good.result.ok, "Sanidade: a cópia dos dados serve. " + good.result.message)
	var bad_lod: NpcSetup = _setup(_copy_data("lod_params.json", '[{"id": "lod", "lod_enter_radius_m": 120, "lod_exit_radius_m": 80, "max_s0": 50}]'))
	assert_false(bad_lod.result.ok)
	assert_eq(bad_lod.result.code, NpcSetup.CODE_INVALID)
	assert_string_contains(bad_lod.result.message, "lod_params.json")
	var bad_intents: NpcSetup = _setup(_copy_data("intent_params.json", '[{"id": "intents", "intent_timeout_min": 0}]'))
	assert_false(bad_intents.result.ok)
	assert_string_contains(bad_intents.result.message, "intent_params.json")
	var no_lod: NpcSetup = _setup(_copy_data("", "", "lod_params.json"))
	assert_false(no_lod.result.ok, "Arquivo ausente falha em vez de ligar o jogo com o LOD desligado em silêncio.")
	assert_string_contains(no_lod.result.message, "lod_params.json")


# ---------------------------------------------------------------------------------------------------- o módulo

func test_the_focus_is_accepted_before_the_first_step_and_the_intents_come_with_the_thinker() -> void:
	var host: SimulationHostNode = SimulationHostNode.new()
	_hosts.append(host)
	host.start_new_game(WORLD_SEED, _terrain, _points, _good_setup())
	var npc: NpcModule = host.npc
	assert_not_null(npc)
	var focused: Result = npc.request_set_focus(77, FOCUS_A_M)
	assert_true(focused.ok, "O jogador relata a posição antes do primeiro passo: " + focused.message)
	assert_false(npc.intents.is_configured(), "Os Intents ligam no ponto em que o pensador é montado (no primeiro passo).")
	host.runner.step_once()
	assert_true(npc.intents.is_configured(), "Depois do primeiro passo o protocolo está ligado ao runner do pensador.")
	assert_eq(npc.debug_summary()["decision_enabled"], true)


func test_without_the_parameters_the_lod_and_the_intents_stay_off() -> void:
	var setup: NpcSetup = _good_setup()
	setup.definitions.lod_params = null
	setup.definitions.intent_params = null
	var host: SimulationHostNode = SimulationHostNode.new()
	_hosts.append(host)
	host.start_new_game(WORLD_SEED, _terrain, _points, setup)
	var refused: Result = host.npc.request_set_focus(77, FOCUS_A_M)
	assert_eq(refused.code, NpcLod.CODE_NOT_CONFIGURED, "Sem parâmetros do LOD o foco é recusado, como antes.")
	host.runner.run_steps(FIRST_THINKS_DONE)
	assert_false(host.npc.intents.is_configured())
	assert_eq(host.npc.peek_pending_intents().size(), 0)
	assert_eq(host.npc.debug_summary()["decision_enabled"], true, "O pensador funciona sem eles (modo S1 para todos).")
	var counts: Dictionary = host.npc.peek_counts()
	assert_eq(counts["alive"], 132)


func test_intent_parameters_without_lod_never_put_an_npc_in_s0() -> void:
	var setup: NpcSetup = _good_setup()
	setup.definitions.lod_params = null
	var host: SimulationHostNode = SimulationHostNode.new()
	_hosts.append(host)
	host.start_new_game(WORLD_SEED, _terrain, _points, setup)
	host.runner.run_steps(FIRST_THINKS_DONE)
	assert_true(host.npc.intents.is_configured(), "Os Intents estão ligados, mas ninguém tem corpo.")
	assert_eq(host.npc.peek_pending_intents().size(), 0, "Sem LOD ninguém está em S0: toda ação nasce abstrata.")


# ---------------------------------------------------------------------------------------------------- o host, o GameApp e a ponte

func test_the_host_exposes_the_npc_module_and_clears_it_on_a_world_without_modules() -> void:
	var host: SimulationHostNode = SimulationHostNode.new()
	_hosts.append(host)
	assert_null(host.npc, "Antes de iniciar um jogo não há módulo.")
	host.start_new_game(WORLD_SEED, _terrain, _points, _good_setup())
	assert_not_null(host.npc)
	assert_eq(host.npc.peek_counts()["total"], 132, "É o módulo do jogo, com a população inicial.")
	host.start_new_game(WORLD_SEED)
	assert_null(host.npc, "Um mundo sem terreno nasce só com o núcleo: o módulo antigo não fica pendurado no host.")


func test_the_game_app_hands_the_npc_to_the_bridge_and_the_whole_chain_works() -> void:
	var host: SimulationHostNode = SimulationHostNode.new()
	_hosts.append(host)
	host.start_new_game(WORLD_SEED, _terrain, _points, _good_setup())
	assert_true(host.npc.request_set_bodies_available(true).ok, "LW-070b: o teste faz o papel da apresentação e declara que há corpos.")
	var app: GameAppNode = autofree(GameAppNode.new())
	app.bind_host(host)
	var bridge: SimBridge = app.peek_bridge()
	var spawned: BridgeReplies.SpawnCharacterReply = bridge.request_spawn_character()
	assert_true(spawned.result.ok, spawned.result.message)
	var reported: Result = bridge.request_report_position(spawned.actor_id, FOCUS_A_M, 0.0)
	assert_true(reported.ok, "O foco do jogador chega ao LOD já no primeiro relato: " + reported.message)
	host.runner.run_steps(AFTER_THE_ROUTINE_SWAP)
	var listed: BridgeReplies.NpcIntentsReply = bridge.peek_pending_npc_intents()
	assert_true(listed.result.ok, listed.result.message)
	assert_eq(listed.intents.size(), MAX_S0, "A ponte do GameApp entrega os Intents dos 50 NPCs com corpo.")
	# O NPC mais perto do foco: é o último a perder a vaga de S0 (os de fora andam a partir das 7h; ver test_npc_s0_flow.gd).
	var first: BridgeReplies.NpcIntentReply = listed.intents[0]
	for candidate: BridgeReplies.NpcIntentReply in listed.intents:
		if _distance_to_focus_m(candidate.destination) < _distance_to_focus_m(first.destination):
			first = candidate
	assert_almost_eq(first.destination.y, bridge.peek_height(first.destination.x, first.destination.z).height_m, 0.001, "O destino leva a altura do terreno.")
	var before: NpcModule.NpcQuery = host.npc.peek_npc(first.npc_id)
	host.runner.run_steps(before.action_ends_at - host.runner.world.context.clock.total_minutes())
	var count_before: int = bridge.peek_pending_npc_intents().intents.size()
	var answered: Result = bridge.request_report_npc_result(first.npc_id, first.action_serial, BridgeReplies.NpcOutcome.DONE, first.destination)
	assert_true(answered.ok, answered.message)
	var after: NpcModule.NpcQuery = host.npc.peek_npc(first.npc_id)
	assert_eq(after.action_id, before.action_id, "Logo depois do relato a ação só tem o fim marcado (LW-070d).")
	assert_gt(after.need_values[HUNGER], 0, "E o efeito de `eat` ainda não entrou.")
	assert_eq(bridge.peek_pending_npc_intents().intents.size(), count_before - 1, "E o Intent cumprido saiu da lista da ponte.")
	host.runner.step_once()
	var closed: NpcModule.NpcQuery = host.npc.peek_npc(first.npc_id)
	assert_eq(closed.action_serial, first.action_serial + 1, "O pensamento seguinte encerrou a ação e começou a próxima.")
	assert_eq(closed.need_values[HUNGER], 0, "E o alívio de `eat` entrou (`hunger`).")
	var stale: Result = bridge.request_report_npc_result(first.npc_id, first.action_serial, BridgeReplies.NpcOutcome.DONE, first.destination)
	assert_eq(stale.code, NpcIntentBoard.CODE_STALE_RESULT, "O código do `npc` chega à apresentação como está.")
