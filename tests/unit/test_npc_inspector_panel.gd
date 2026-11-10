extends GutTest
## LW-082f: os nós do painel de depuração de NPC (src/tools/npc_inspector/npc_inspector_panel.gd; contrato em docs/modules/tools.md), sem janela e com o jogo
## real (terreno, assentamentos e os 100 NPCs, em build de desenvolvimento) e os textos reais de data/text/pt_br.json. Confere que o painel começa fechado, lista
## TODOS os NPCs, mostra os contadores e, do NPC selecionado, os dados de cada seção; que a tecla de marcar liga e desliga o rastro; que o painel acompanha o jogo
## pelo ritmo; e que todas as chaves de texto existem.

const DATA_DIR: String = "res://data"
const WORLD_SEED: int = 5
const WARMUP_STEPS: int = 60

var _terrain: TerrainData
var _points: Array[PointOfInterest] = []
var _settlements: Array[Settlement] = []
var _places: Array[Place] = []
var _texts: UiText
var _host: SimulationHostNode
var _bridge: SimBridge
var _panel: NpcInspectorPanel


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


func before_each() -> void:
	var setup: NpcSetup = NpcSetup.from_dir(DATA_DIR, SettlementService.new(_settlements, _places), true)
	assert_true(setup.result.ok, setup.result.message)
	_host = SimulationHostNode.new()
	_host.start_new_game(WORLD_SEED, _terrain, _points, setup)
	_bridge = SimBridge.new(_host, _terrain, _places, _host.npc)
	_panel = NpcInspectorPanel.new()
	add_child_autofree(_panel)
	assert_true(_panel.setup(_bridge, _texts))


func after_each() -> void:
	_host.runner.finish()
	_host.free()


func _step(count: int) -> void:
	for _index: int in count:
		_host.runner.step_once()


## Nenhum texto do painel pode ter sobrado um `{valor}` sem trocar nem uma chave sem frase (que aparece como "[chave]").
func _assert_clean(text: String) -> void:
	assert_false(text.contains("{"), "Sem valor por trocar.")
	assert_false(text.contains("[tools."), "Sem chave sem frase.")


func test_the_panel_starts_closed_opens_and_closes_and_refuses_null_parts() -> void:
	assert_false(_panel.is_open(), "Começa fechado.")
	_panel.open()
	assert_true(_panel.is_open())
	_panel.toggle()
	assert_false(_panel.is_open())
	_panel.toggle()
	_panel.close()
	assert_false(_panel.is_open())
	assert_false(autofree(NpcInspectorPanel.new()).setup(null, _texts))
	assert_false(autofree(NpcInspectorPanel.new()).setup(_bridge, null))
	assert_push_error_count(2)


func test_opening_lists_every_npc_and_the_world_counters_before_anyone_is_selected() -> void:
	_panel.open()
	var ids: Array[int] = _host.npc.peek_npc_ids()
	assert_eq(_panel.list_row_count(), ids.size(), "Uma linha por NPC, inclusive os sem corpo.")
	assert_string_contains(_panel.summary_text(), "NPCs: %d" % ids.size())
	assert_string_contains(_panel.detail_text(), _texts.get_text(NpcInspectorPanel.KEY_NO_SELECTION), "Sem seleção, o painel diz como escolher.")
	_assert_clean(_panel.summary_text())
	_assert_clean(_panel.detail_text())


func test_selecting_an_npc_shows_its_needs_action_occupation_and_the_empty_sections() -> void:
	_step(WARMUP_STEPS)
	_panel.open()
	_panel.select_next()
	var npc_id: int = _panel.model().selected_id()
	assert_eq(npc_id, _host.npc.peek_npc_ids()[0], "O primeiro da lista.")
	var query: NpcModule.NpcQuery = _host.npc.peek_npc(npc_id)
	var text: String = _panel.detail_text()
	assert_string_contains(text, _texts.get_text(NpcInspectorPanel.KEY_SELECTED_HEADER, {"name": _texts.get_text(query.name_key, {"number": query.name_number}), "id": npc_id}))
	assert_string_contains(text, "hunger: %d" % query.need_values[0], "A necessidade com o id cru e o valor.")
	assert_string_contains(text, query.occupation_id, "O ofício, com o id cru.")
	for key: String in [NpcInspectorPanel.KEY_SECTION_TRACE, NpcInspectorPanel.KEY_SECTION_MEMORIES, NpcInspectorPanel.KEY_SECTION_RELATIONS, NpcInspectorModel.KEY_TRACE_NOT_MARKED, NpcInspectorModel.KEY_MEMORY_NONE, NpcInspectorModel.KEY_RELATION_NONE]:
		assert_string_contains(text, _texts.get_text(key), "A seção mostra %s." % key)
	_assert_clean(text)
	_panel.select_previous()
	assert_eq(_panel.model().selected_id(), _host.npc.peek_npc_ids()[-1], "O anterior do primeiro volta ao fim.")


func test_clicking_a_row_of_the_list_selects_that_npc() -> void:
	_panel.open()
	var lists: Array[Node] = _panel.find_children("*", "ItemList", true, false)
	assert_eq(lists.size(), 1)
	(lists[0] as ItemList).item_selected.emit(2)
	assert_eq(_panel.model().selected_id(), _host.npc.peek_npc_ids()[2])
	assert_string_contains(_panel.detail_text(), "hunger")


func test_the_trace_key_marks_and_unmarks_and_the_trace_shows_the_thoughts() -> void:
	_panel.open()
	_panel.toggle_trace()
	assert_false(_bridge.peek_npc_trace(_host.npc.peek_npc_ids()[0]).result.ok, "Sem seleção, a tecla não marca ninguém.")
	_panel.select_next()
	_panel.toggle_trace()
	assert_true(_panel.model().is_traced(), "Marcado pela tecla.")
	_step(WARMUP_STEPS)
	_panel.refresh()
	assert_string_contains(_panel.detail_text(), "escolheu", "Depois de pensar, o rastro mostra o que o NPC escolheu.")
	_assert_clean(_panel.detail_text())
	_panel.toggle_trace()
	assert_false(_panel.model().is_traced(), "Desmarcado pela mesma tecla.")
	assert_string_contains(_panel.detail_text(), _texts.get_text(NpcInspectorModel.KEY_TRACE_NOT_MARKED))


func test_the_panel_follows_the_game_by_its_rhythm_while_open() -> void:
	_panel.open()
	var before: String = _panel.summary_text()
	_step(WARMUP_STEPS)
	assert_eq(_panel.summary_text(), before, "Sem passar o ritmo, o painel não atualiza.")
	_panel._process(NpcInspectorPanel.SUMMARY_INTERVAL_S + 0.1)
	assert_ne(_panel.summary_text(), before, "Passado o ritmo, a hora do resumo acompanha o jogo.")


func test_every_text_key_of_the_panel_and_of_the_model_exists_in_the_text_file() -> void:
	var count: int = 0
	for source: Script in [NpcInspectorPanel, NpcInspectorModel]:
		var constants: Dictionary = source.get_script_constant_map()
		for constant_name: String in constants:
			if constant_name.begins_with("KEY_") and constant_name != "KEY_PREFIX":
				assert_true(_texts.has_key(str(constants[constant_name])), "A chave %s existe em data/text/pt_br.json." % constants[constant_name])
				count += 1
	assert_gt(count, 20, "O teste enxerga as chaves.")
