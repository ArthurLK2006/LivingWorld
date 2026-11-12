extends GutTest
## LW-108d: o painel de depuração da economia SÓ LÊ (docs/modules/tools.md, "Painel econômico"; roadmap, LW-108), sem nenhuma exceção (o painel de NPC tem a marca do rastro; este não tem escrita nenhuma). Três
## camadas, sem janela e com o jogo real: (1) JOGOS GÊMEOS: mesma semente e mesmos passos, um com o painel exercitado (abrir, atualizar pelo ritmo, Shift+Tab, fechar) e outro sem, e o hash, o save da economia, o
## resumo do mundo, o RNG e os IDs saem IGUAIS; (2) PONTE ESPIÃ: o painel não chama nenhum `request_*`, `submit_intent` nem `take_pending_intents`; (3) VARREDURA de src/tools/economy_inspector/ (a pasta não tem as
## verificações do `check_architecture` nem do `check_literal_text`): só `peek_*` da ponte, nenhuma classe de src/sim/, nada de `OS.` nem de avaliação dinâmica, COM um controle que prova que a varredura enxerga
## uma violação.

const STEPS_PER_ROUND: int = 60
const ROUNDS: int = 6
const TOOLS_DIR: String = "res://src/tools/economy_inspector"
const SIM_DIR: String = "res://src/sim"
const BRIDGE_CALL_PATTERN: String = "\\b_?bridge\\.([a-z_]+)\\("
const WRITE_PATTERN: String = "\\b(request_[a-z_]+|submit_intent|take_pending_intents)\\b"
const FORBIDDEN_PATTERN: String = "\\b(OS|Expression|GDScript|ResourceLoader|FileAccess|DirAccess)\\b|\\b(load|preload|execute|set_script)\\s*\\("

var _data: NpcLifeCheck.GameData
var _texts: UiText
var _games: Array[Game] = []


## Um jogo real inteiro: o host, o GameApp que o iniciou e a ponte. Idêntico em toda chamada.
class Game:
	extends RefCounted

	var host: SimulationHostNode
	var app: GameAppNode
	var bridge: SimBridge


## Ponte que ANOTA toda chamada de escrita e repassa à de verdade. Se a `SimBridge` ganhar outro `request_*`, o teste da cobertura abaixo acusa.
class SpyBridge:
	extends SimBridge

	var calls: Dictionary[String, int] = {}

	func _note(method: String) -> void:
		calls[method] = calls.get(method, 0) + 1

	func request_pause(is_paused: bool) -> Result:
		_note("request_pause")
		return super.request_pause(is_paused)

	func request_speed(speed: int) -> Result:
		_note("request_speed")
		return super.request_speed(speed)

	func request_interact(actor_id: int, poi_id: String) -> BridgeReplies.InteractReply:
		_note("request_interact")
		return super.request_interact(actor_id, poi_id)

	func request_converse(actor_id: int, npc_id: int) -> BridgeReplies.ConverseReply:
		_note("request_converse")
		return super.request_converse(actor_id, npc_id)

	func request_spawn_character() -> BridgeReplies.SpawnCharacterReply:
		_note("request_spawn_character")
		return super.request_spawn_character()

	func request_report_position(actor_id: int, position: Vector3, yaw: float) -> Result:
		_note("request_report_position")
		return super.request_report_position(actor_id, position, yaw)

	func request_report_npc_result(npc_id: int, action_serial: int, outcome: BridgeReplies.NpcOutcome, final_position: Vector3) -> Result:
		_note("request_report_npc_result")
		return super.request_report_npc_result(npc_id, action_serial, outcome, final_position)

	func request_report_npc_positions(positions: Dictionary[int, Vector3]) -> Result:
		_note("request_report_npc_positions")
		return super.request_report_npc_positions(positions)

	func request_set_bodies_available(available: bool) -> Result:
		_note("request_set_bodies_available")
		return super.request_set_bodies_available(available)

	func request_set_npc_traced(npc_id: int, is_traced: bool) -> Result:
		_note("request_set_npc_traced")
		return super.request_set_npc_traced(npc_id, is_traced)

	func submit_intent(intent: BridgeIntent) -> Result:
		_note("submit_intent")
		return super.submit_intent(intent)

	func take_pending_intents() -> Array[BridgeIntent]:
		_note("take_pending_intents")
		return super.take_pending_intents()


func before_all() -> void:
	_data = NpcLifeCheck.load_game_data()
	assert_eq(_data.problem, "", "Os dados reais do jogo carregam.")
	var loaded: UiText.LoadResult = UiText.from_file(UiText.DEFAULT_PATH)
	assert_true(loaded.result.ok, loaded.result.message)
	_texts = loaded.texts


func after_each() -> void:
	for game: Game in _games:
		game.app.free()
		if game.host.runner != null:
			game.host.runner.finish()
		game.host.free()
	_games.clear()


func _new_game() -> Game:
	var game: Game = Game.new()
	game.host = SimulationHostNode.new()
	game.app = GameAppNode.new()
	game.app.bind_host(game.host)
	game.app.start_default_game(game.host)
	game.bridge = game.app.peek_bridge()
	_games.append(game)
	return game


func _step(game: Game, count: int) -> void:
	for _index: int in count:
		game.host.runner.step_once()


func _shift_tab() -> InputEventKey:
	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = KEY_TAB
	event.pressed = true
	event.shift_pressed = true
	return event


## Exercita o painel de todos os jeitos que ele tem: abre pela tecla, atualiza na hora e pelo ritmo, e fecha.
func _exercise(panel: EconomyInspectorPanel) -> void:
	assert_true(panel.handle_action(_shift_tab()), "Shift+Tab abre.")
	panel.refresh()
	panel._process(EconomyInspectorPanel.REFRESH_INTERVAL_S * 2.0)
	assert_true(panel.is_open())
	assert_true(panel.handle_action(_shift_tab()), "Shift+Tab fecha.")
	panel.open()
	panel.close()


func _mount(bridge: SimBridge) -> EconomyInspectorPanel:
	var holder: Node = Node.new()
	add_child_autofree(holder)
	var panel: EconomyInspectorPanel = EconomyInspectorMount.mount(holder, bridge, _texts, true)
	assert_not_null(panel)
	return panel


# ---------------------------------------------------------------------------------------------------- camada 1: jogos gêmeos

func test_exercising_the_panel_changes_nothing_at_all_in_the_game() -> void:
	var with_panel: Game = _new_game()
	var without_panel: Game = _new_game()
	var panel: EconomyInspectorPanel = _mount(with_panel.bridge)
	for _round: int in ROUNDS:
		_step(with_panel, STEPS_PER_ROUND)
		_step(without_panel, STEPS_PER_ROUND)
		_exercise(panel)
	var world_with: World = with_panel.host.runner.world
	var world_without: World = without_panel.host.runner.world
	assert_eq(world_with.state_hash(), world_without.state_hash(), "O hash do mundo é o mesmo com e sem o painel.")
	assert_eq(with_panel.host.economy.serialize(), without_panel.host.economy.serialize(), "O save da economia é o mesmo.")
	assert_eq(world_with.debug_summary(), world_without.debug_summary(), "O resumo de depuração do mundo (relógio, eventos, módulos) é o mesmo.")
	assert_eq(world_with.context.rng.debug_summary(), world_without.context.rng.debug_summary(), "Nenhum sorteio foi gasto a mais.")
	assert_eq(world_with.context.ids.debug_summary(), world_without.context.ids.debug_summary(), "Nenhum ID foi gerado a mais.")
	assert_eq(with_panel.host.npc.peek_pending_intents().size(), without_panel.host.npc.peek_pending_intents().size(), "Os Intents pendentes são os mesmos.")
	assert_eq(with_panel.host.economy.peek_conservation().sum, without_panel.host.economy.peek_conservation().sum, "E o dinheiro em circulação também.")


func test_the_panel_open_through_all_the_steps_still_changes_nothing() -> void:
	var with_panel: Game = _new_game()
	var without_panel: Game = _new_game()
	var panel: EconomyInspectorPanel = _mount(with_panel.bridge)
	panel.open()
	for _round: int in ROUNDS:
		_step(with_panel, STEPS_PER_ROUND)
		_step(without_panel, STEPS_PER_ROUND)
		panel._process(EconomyInspectorPanel.REFRESH_INTERVAL_S)
	assert_eq(with_panel.host.runner.world.state_hash(), without_panel.host.runner.world.state_hash(), "Aberto o tempo todo e atualizando a cada intervalo: o hash é o mesmo.")
	assert_string_contains(panel.plain_text(), "CONSERVAÇÃO: OK")


# ---------------------------------------------------------------------------------------------------- camada 2: ponte espiã

func test_the_spy_bridge_sees_no_write_at_all() -> void:
	var game: Game = _new_game()
	var spy: SpyBridge = SpyBridge.new(game.host, _data.terrain, _data.places, game.host.npc)
	var panel: EconomyInspectorPanel = _mount(spy)
	_exercise(panel)
	_step(game, STEPS_PER_ROUND)
	_exercise(panel)
	assert_string_contains(panel.plain_text(), "CONSERVAÇÃO", "O painel leu de verdade pela ponte espiã.")
	assert_eq(spy.calls.keys(), [] as Array, "Nenhuma chamada de escrita: nem uma exceção, como tem o painel de NPC.")


func test_the_spy_covers_every_write_style_method_of_the_bridge() -> void:
	var real: Array[String] = _write_methods(SimBridge.new(null, null))
	var spied: Array[String] = _write_methods(SpyBridge.new(null, null))
	assert_gt(real.size(), 8, "O teste enxerga os métodos de escrita da ponte.")
	for method: String in real:
		assert_true(spied.has(method), "A ponte espiã cobre '%s' (um novo `request_*` na ponte precisa entrar aqui)." % method)


func _write_methods(bridge: SimBridge) -> Array[String]:
	var names: Array[String] = []
	for method: Dictionary in bridge.get_script().get_script_method_list():
		var method_name: String = method["name"]
		if method_name.begins_with("request_") or method_name == "submit_intent" or method_name == "take_pending_intents":
			names.append(method_name)
	return names


# ---------------------------------------------------------------------------------------------------- camada 3: varredura de src/tools/economy_inspector

func _gd_files(dir_path: String) -> Array[String]:
	var found: Array[String] = []
	for file_name: String in DirAccess.get_files_at(dir_path):
		if file_name.ends_with(".gd"):
			found.append(dir_path.path_join(file_name))
	for folder: String in DirAccess.get_directories_at(dir_path):
		found.append_array(_gd_files(dir_path.path_join(folder)))
	found.sort()
	return found


## Só o código: linha inteira de comentário e o que vem depois de um `#` não contam.
func _code_of(text: String) -> String:
	var kept: PackedStringArray = PackedStringArray()
	for line: String in text.split("\n"):
		var cut: int = line.find("#")
		var code: String = line if cut < 0 else line.substr(0, cut)
		if not code.strip_edges().is_empty():
			kept.append(code)
	return "\n".join(kept)


func _sim_class_names() -> Array[String]:
	var names: Array[String] = []
	var declaration: RegEx = RegEx.create_from_string("(?m)^class_name\\s+(\\w+)")
	for path: String in _gd_files(SIM_DIR):
		var found: RegExMatch = declaration.search(FileAccess.get_file_as_string(path))
		if found != null:
			names.append(found.get_string(1))
	return names


## Tudo que a pasta do painel econômico não pode ter: chamada da ponte que não seja `peek_*`, qualquer `request_*`/`submit_intent`/`take_pending_intents`, classe de src/sim/, e `OS.`, avaliação dinâmica ou
## carga de recurso. Sem exceção nenhuma. Devolve um texto por violação ("arquivo: motivo: trecho").
func _violations(sources: Dictionary, sim_classes: Array[String]) -> Array[String]:
	var found: Array[String] = []
	var bridge_call: RegEx = RegEx.create_from_string(BRIDGE_CALL_PATTERN)
	var write: RegEx = RegEx.create_from_string(WRITE_PATTERN)
	var sim_class: RegEx = RegEx.create_from_string("\\b(%s)\\b" % "|".join(sim_classes))
	var forbidden: RegEx = RegEx.create_from_string(FORBIDDEN_PATTERN)
	for path: String in sources:
		var code: String = sources[path]
		for called: RegExMatch in bridge_call.search_all(code):
			if not called.get_string(1).begins_with("peek_"):
				found.append("%s: chamada da ponte que não é peek_: %s" % [path.get_file(), called.get_string(1)])
		for writing: RegExMatch in write.search_all(code):
			found.append("%s: escrita: %s" % [path.get_file(), writing.get_string(1)])
		for named: RegExMatch in sim_class.search_all(code):
			found.append("%s: classe de src/sim/: %s" % [path.get_file(), named.get_string(1)])
		for banned: RegExMatch in forbidden.search_all(code):
			found.append("%s: proibido: %s" % [path.get_file(), banned.get_string(0).strip_edges()])
	return found


func test_the_scan_of_the_economy_panel_finds_only_peek_calls_and_no_write_at_all() -> void:
	var sources: Dictionary = {}
	for path: String in _gd_files(TOOLS_DIR):
		sources[path] = _code_of(FileAccess.get_file_as_string(path))
	assert_eq(sources.size(), 3, "A varredura enxerga os três arquivos (modelo, painel e montagem).")
	var sim_classes: Array[String] = _sim_class_names()
	assert_gt(sim_classes.size(), 50, "A varredura conhece as classes de src/sim/.")
	assert_true(sim_classes.has("EconomyModule"))
	assert_eq(_violations(sources, sim_classes), [] as Array[String], "O painel econômico só lê pela ponte.")
	var panel_code: String = sources[TOOLS_DIR.path_join("economy_inspector_panel.gd")]
	for call_name: String in ["peek_economy_overview", "peek_economy_markets", "peek_economy_sites"]:
		assert_eq(panel_code.count("_bridge.%s(" % call_name), 1, "'%s' tem um único ponto de chamada." % call_name)


func test_control_the_scan_flags_each_kind_of_violation_and_ignores_comments() -> void:
	var sim_classes: Array[String] = _sim_class_names()
	var violating: Dictionary = {
		"res://x/writes.gd": _code_of("func f() -> void:\n\t_bridge.request_converse(1, 2)\n\t_bridge.submit_intent(null)\n\tbridge.peek_economy_sites()"),
		"res://x/trace.gd": _code_of("func g() -> void:\n\t_bridge.request_set_npc_traced(1, true)"),
		"res://x/sim.gd": _code_of("var module: EconomyModule"),
		"res://x/engine.gd": _code_of("var debug: bool = OS.is_debug_build()\nvar e: Expression = Expression.new()"),
		"res://x/innocent.gd": _code_of("## request_pause EconomyModule OS.is_debug_build()\nfunc h() -> void:\n\tbridge.peek_economy_sites() # request_speed"),
	}
	var found: Array[String] = _violations(violating, sim_classes)
	var files: Array[String] = []
	for text: String in found:
		var file_name: String = text.split(":")[0]
		if not files.has(file_name):
			files.append(file_name)
	files.sort()
	assert_eq(files, ["engine.gd", "sim.gd", "trace.gd", "writes.gd"] as Array[String], "A varredura acusa a escrita (inclusive a marca do rastro, que aqui não é permitida), a classe da simulação e o uso do motor; o arquivo inocente passa.")
	assert_gte(found.size(), 6, "Chamada da ponte que não é peek_, escritas, classe de src/sim/ e dois usos proibidos do motor.")
