extends GutTest
## LW-082h: o painel de depuração de NPC SÓ LÊ (docs/modules/tools.md; npc.md, seção 12), com UMA exceção declarada por Arthur: marcar ou desmarcar o NPC para o rastro
## (`request_set_npc_traced`). Três camadas, sem janela e com o jogo real em build de desenvolvimento: (1) JOGOS GÊMEOS: mesma semente e mesmos passos, um com o painel exercitado
## (NPCs T1, T2, morto, S0 e S1; seleção, atualização, abrir e fechar e a marcação do rastro) e outro sem, e o hash, o save, o resumo do mundo, os Intents, o RNG, os IDs e o LOD saem
## IGUAIS; (2) PONTE ESPIÃ: o painel não chama nenhum `request_*`, `submit_intent` nem `take_pending_intents`, a não ser a marcação; (3) VARREDURA de src/tools/ (a pasta não tem as
## verificações do `check_architecture` nem do `check_literal_text`): só `peek_*` da ponte e a marcação, nenhuma classe de src/sim/, nada de `OS.` nem de avaliação dinâmica, COM um controle
## que prova que a varredura enxerga uma violação.

const DATA_DIR: String = "res://data"
const WORLD_SEED: int = 5
const NEAR_A_M: Vector3 = Vector3(350.0, 10.0, 540.0)
const ROUNDS: int = 9
const MINUTES_PER_ROUND: int = 10
const TRACE_ROUNDS: Array[int] = [2, 6]
const TOOLS_DIR: String = "res://src/tools"
const SIM_DIR: String = "res://src/sim"
const ALLOWED_WRITE: String = "request_set_npc_traced"
const BRIDGE_CALL_PATTERN: String = "\\b_?bridge\\.([a-z_]+)\\("
const WRITE_PATTERN: String = "\\b(request_[a-z_]+|submit_intent|take_pending_intents)\\b"
const FORBIDDEN_PATTERN: String = "\\b(OS|Expression|GDScript|ResourceLoader|FileAccess|DirAccess)\\b|\\b(load|preload|execute|set_script)\\s*\\("

var _terrain: TerrainData
var _points: Array[PointOfInterest] = []
var _settlements: Array[Settlement] = []
var _places: Array[Place] = []
var _texts: UiText
var _hosts: Array[SimulationHostNode] = []


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
	var data: NpcLifeCheck.GameData = NpcLifeCheck.load_game_data()
	assert_eq(data.problem, "", "Os dados reais do jogo carregam.")
	_terrain = data.terrain
	_points = data.points
	_settlements = data.settlements
	_places = data.places
	var loaded: UiText.LoadResult = UiText.from_file(UiText.DEFAULT_PATH)
	assert_true(loaded.result.ok, loaded.result.message)
	_texts = loaded.texts


func after_each() -> void:
	for host: SimulationHostNode in _hosts:
		host.runner.finish()
		host.free()
	_hosts.clear()


## Um jogo em build de desenvolvimento, com corpos ligados e um ator perto do assentamento A (NPCs em S0 e em S1), dois notáveis e um NPC morto. Idêntico em toda chamada.
func _prepared_game() -> SimulationHostNode:
	var setup: NpcSetup = NpcSetup.from_dir(DATA_DIR, SettlementService.new(_settlements, _places), true)
	assert_true(setup.result.ok, setup.result.message)
	var host: SimulationHostNode = SimulationHostNode.new()
	host.start_new_game(WORLD_SEED, _terrain, _points, setup)
	_hosts.append(host)
	var bridge: SimBridge = _bridge_of(host)
	assert_true(bridge.request_set_bodies_available(true).ok)
	var spawned: BridgeReplies.SpawnCharacterReply = bridge.request_spawn_character()
	assert_true(bridge.request_report_position(spawned.actor_id, NEAR_A_M, 0.0).ok)
	var ids: Array[int] = host.npc.peek_npc_ids()
	assert_true(host.npc.request_promote(ids[0], NpcState.TIER_NOTABLE).ok)
	assert_true(host.npc.request_promote(ids[1], NpcState.TIER_NOTABLE).ok)
	var saved: Dictionary = host.npc.serialize()
	var saved_npcs: Dictionary = saved["npcs"]
	saved_npcs[str(ids[2])]["is_alive"] = false
	saved_npcs[str(ids[2])]["death_cause"] = "hunger"
	saved_npcs[str(ids[2])]["died_at"] = 1
	assert_true(host.npc.on_load(saved).ok)
	host.runner.step_once()
	return host


func _bridge_of(host: SimulationHostNode) -> SimBridge:
	return SimBridge.new(host, _terrain, _places, host.npc)


func _step(host: SimulationHostNode, count: int) -> void:
	for _index: int in count:
		host.runner.step_once()


func _mount(bridge: SimBridge) -> NpcInspectorPanel:
	var holder: Node = Node.new()
	add_child_autofree(holder)
	var panel: NpcInspectorPanel = NpcInspectorMount.mount(holder, bridge, _texts, true)
	assert_not_null(panel)
	return panel


## Passa por TODOS os NPCs da lista (anotando o que o painel viu: T1, T2, morto, S0 e S1) e depois anda ROUNDS rodadas, mexendo no painel a cada uma. `with_trace` liga a tecla de marcar.
func _exercise(panel: NpcInspectorPanel, host: SimulationHostNode, with_trace: bool) -> Dictionary:
	var seen: Dictionary = {}
	panel.open()
	for _index: int in host.npc.peek_npc_ids().size():
		panel.select_next()
		var entry: BridgeInspectReplies.NpcRosterEntry = panel.model().selected_entry()
		seen["t2" if entry.tier == BridgeInspectReplies.TIER_NOTABLE else "t1"] = true
		seen["s0" if entry.level == BridgeInspectReplies.NpcLevel.S0 else "s1"] = true
		if not entry.is_alive:
			seen["dead"] = true
	for round_index: int in ROUNDS:
		_step(host, MINUTES_PER_ROUND)
		panel._process(NpcInspectorPanel.SUMMARY_INTERVAL_S + 0.1)
		panel.select_next()
		panel.select_previous()
		panel.select_next()
		if with_trace and TRACE_ROUNDS.has(round_index):
			panel.toggle_trace()
	panel.close()
	return seen


## Tudo que o painel NÃO pode mudar: o hash do mundo, o save do `npc`, o resumo do mundo, os Intents pendentes, o RNG, os IDs gerados e o LOD.
func _fingerprint(host: SimulationHostNode) -> Dictionary:
	var world: World = host.runner.world
	var intents: Array = []
	for intent: NpcIntent in host.npc.peek_pending_intents():
		intents.append([intent.npc_id, intent.action_serial, intent.kind, intent.place_id, intent.destination_cm, intent.expected_minutes])
	return {"hash": world.state_hash(), "save": host.npc.serialize(), "summary": world.debug_summary(), "intents": intents, "rng": world.context.rng.debug_summary(), "ids": world.context.ids.debug_summary(), "lod": host.npc.lod.debug_summary()}


## Os caminhos (separados por barra) onde dois resultados diferem; vazio se são iguais.
func _diff_paths(first: Variant, second: Variant, path: String) -> Array[String]:
	var found: Array[String] = []
	if typeof(first) == TYPE_DICTIONARY and typeof(second) == TYPE_DICTIONARY:
		var keys: Array = (first as Dictionary).keys()
		for key: Variant in (second as Dictionary).keys():
			if not keys.has(key):
				keys.append(key)
		for key: Variant in keys:
			found.append_array(_diff_paths((first as Dictionary).get(key), (second as Dictionary).get(key), "%s/%s" % [path, str(key)]))
	elif first != second:
		found.append(path)
	return found


## O jogo sem painel e o jogo com o painel exercitado, pelos mesmos minutos: devolve as duas impressões digitais (sem painel primeiro).
func _twins(with_trace: bool) -> Array[Dictionary]:
	var plain: SimulationHostNode = _prepared_game()
	var watched: SimulationHostNode = _prepared_game()
	var seen: Dictionary = _exercise(_mount(_bridge_of(watched)), watched, with_trace)
	for flag: String in ["t1", "t2", "dead", "s0", "s1"]:
		assert_true(seen.has(flag), "O painel passou por NPC '%s'." % flag)
	_step(plain, ROUNDS * MINUTES_PER_ROUND)
	assert_gt(_bridge_of(watched).peek_npc_roster().entries.size(), 0, "O jogo observado continua de pé.")
	return [_fingerprint(plain), _fingerprint(watched)]


# ---------------------------------------------------------------------------------------------------- camada 1: jogos gêmeos

func test_exercising_the_panel_without_the_trace_key_changes_nothing_at_all() -> void:
	var results: Array[Dictionary] = _twins(false)
	for part: String in results[0]:
		assert_eq(results[1][part], results[0][part], "Depois de %d minutos, '%s' é igual com e sem o painel." % [ROUNDS * MINUTES_PER_ROUND, part])


## Com a tecla de marcar, o hash, o save, os Intents, o RNG, os IDs e o LOD continuam iguais; do resumo de depuração só mudam os dois contadores do próprio rastro,
## que são justamente o efeito da marcação (a exceção declarada).
func test_with_the_trace_key_only_the_two_trace_counters_of_the_debug_summary_differ() -> void:
	var results: Array[Dictionary] = _twins(true)
	for part: String in results[0]:
		if part != "summary":
			assert_eq(results[1][part], results[0][part], "Mesmo marcando o rastro, '%s' é igual." % part)
	var differing: Array[String] = _diff_paths(results[0]["summary"], results[1]["summary"], "summary")
	differing.sort()
	assert_eq(differing, ["summary/modules/npc/trace_records_made", "summary/modules/npc/traced_npcs"] as Array[String], "Só os contadores de rastro do `npc` mudam.")
	assert_eq([results[0]["summary"]["modules"]["npc"]["traced_npcs"], results[1]["summary"]["modules"]["npc"]["traced_npcs"] > 0], [0, true], "E mudam porque o rastro foi marcado.")


# ---------------------------------------------------------------------------------------------------- camada 2: ponte espiã

func test_the_spy_bridge_sees_no_write_unless_the_trace_key_is_pressed() -> void:
	var host: SimulationHostNode = _prepared_game()
	var quiet: SpyBridge = SpyBridge.new(host, _terrain, _places, host.npc)
	_exercise(_mount(quiet), host, false)
	assert_eq(quiet.calls, {}, "Sem a tecla de marcar, o painel não chama nenhum `request_*`, `submit_intent` nem `take_pending_intents`.")
	var marking: SpyBridge = SpyBridge.new(host, _terrain, _places, host.npc)
	_exercise(_mount(marking), host, true)
	assert_eq(marking.calls.keys(), [ALLOWED_WRITE], "Com a tecla, só a marcação aprovada...")
	assert_eq(marking.calls[ALLOWED_WRITE], TRACE_ROUNDS.size(), "...uma vez por aperto.")


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


# ---------------------------------------------------------------------------------------------------- camada 3: varredura de src/tools

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


## Tudo que a pasta `tools` não pode ter: chamada da ponte que não seja `peek_*` (salvo a marcação), qualquer `request_*`/`submit_intent`/`take_pending_intents` (salvo a marcação),
## classe de src/sim/, e `OS.`, avaliação dinâmica ou carga de recurso. Devolve um texto por violação ("arquivo: motivo: trecho").
func _violations(sources: Dictionary, sim_classes: Array[String]) -> Array[String]:
	var found: Array[String] = []
	var bridge_call: RegEx = RegEx.create_from_string(BRIDGE_CALL_PATTERN)
	var write: RegEx = RegEx.create_from_string(WRITE_PATTERN)
	var sim_class: RegEx = RegEx.create_from_string("\\b(%s)\\b" % "|".join(sim_classes))
	var forbidden: RegEx = RegEx.create_from_string(FORBIDDEN_PATTERN)
	for path: String in sources:
		var code: String = sources[path]
		for called: RegExMatch in bridge_call.search_all(code):
			if not called.get_string(1).begins_with("peek_") and called.get_string(1) != ALLOWED_WRITE:
				found.append("%s: chamada da ponte que não é peek_: %s" % [path.get_file(), called.get_string(1)])
		for writing: RegExMatch in write.search_all(code):
			if writing.get_string(1) != ALLOWED_WRITE:
				found.append("%s: escrita: %s" % [path.get_file(), writing.get_string(1)])
		for named: RegExMatch in sim_class.search_all(code):
			found.append("%s: classe de src/sim/: %s" % [path.get_file(), named.get_string(1)])
		for banned: RegExMatch in forbidden.search_all(code):
			found.append("%s: proibido: %s" % [path.get_file(), banned.get_string(0).strip_edges()])
	return found


func test_the_scan_of_src_tools_finds_only_peek_calls_and_the_one_allowed_write() -> void:
	var sources: Dictionary = {}
	for path: String in _gd_files(TOOLS_DIR):
		sources[path] = _code_of(FileAccess.get_file_as_string(path))
	assert_gt(sources.size(), 2, "A varredura enxerga os arquivos de src/tools (modelo, painel e montagem).")
	var sim_classes: Array[String] = _sim_class_names()
	assert_gt(sim_classes.size(), 50, "A varredura conhece as classes de src/sim/.")
	assert_true(sim_classes.has("NpcModule"))
	assert_eq(_violations(sources, sim_classes), [] as Array[String], "src/tools só lê pela ponte.")
	var panel_code: String = sources[TOOLS_DIR.path_join("npc_inspector").path_join("npc_inspector_panel.gd")]
	assert_eq(panel_code.count("_bridge.%s(" % ALLOWED_WRITE), 1, "A marcação do rastro tem um único ponto de chamada.")


func test_control_the_scan_flags_each_kind_of_violation_and_ignores_comments() -> void:
	var sim_classes: Array[String] = _sim_class_names()
	var violating: Dictionary = {
		"res://x/writes.gd": _code_of("func f() -> void:\n\t_bridge.request_converse(1, 2)\n\t_bridge.submit_intent(null)\n\tbridge.peek_npc_roster()"),
		"res://x/sim.gd": _code_of("var module: NpcModule"),
		"res://x/engine.gd": _code_of("var debug: bool = OS.is_debug_build()\nvar e: Expression = Expression.new()"),
		"res://x/innocent.gd": _code_of("## request_pause NpcModule OS.is_debug_build()\nfunc g() -> void:\n\tbridge.peek_npc_roster()\n\t_bridge.request_set_npc_traced(1, true) # NpcModule"),
	}
	var found: Array[String] = _violations(violating, sim_classes)
	var files: Array[String] = []
	for text: String in found:
		var file_name: String = text.split(":")[0]
		if not files.has(file_name):
			files.append(file_name)
	files.sort()
	assert_eq(files, ["engine.gd", "sim.gd", "writes.gd"] as Array[String], "A varredura acusa a escrita, a classe da simulação e o uso do motor; o arquivo inocente passa.")
	assert_gte(found.size(), 5, "Chamada da ponte que não é peek_, escrita, classe de src/sim/ e dois usos proibidos do motor.")
