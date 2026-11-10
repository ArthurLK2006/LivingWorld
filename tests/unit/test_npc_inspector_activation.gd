extends GutTest
## LW-082g: a ativação do painel de depuração de NPC (src/tools/npc_inspector/npc_inspector_mount.gd e `handle_action` do painel; contrato em docs/modules/tools.md),
## sem janela e com o jogo real em build de desenvolvimento. Confere que F3 e Tab (duas ações) abrem e fecham, que N, B e T só valem com o painel ABERTO, que o painel
## só é montado em build de desenvolvimento (o sinal entra por parâmetro) e que a cena principal o monta pelo gancho com `OS.is_debug_build()`. As teclas em si
## (F3, Tab, N, B e T, sem repetir em outra ação) estão em tests/unit/test_input_actions.gd.

const DATA_DIR: String = "res://data"
const WORLD_SEED: int = 5
const MAIN_VIEW_SOURCE: String = "res://src/presentation/world_view/main_world_view.gd"
const MOUNT_CALL: String = "NpcInspectorMount.mount(self, bridge, _texts, OS.is_debug_build())"

var _texts: UiText
var _host: SimulationHostNode
var _bridge: SimBridge


func before_all() -> void:
	var loaded: UiText.LoadResult = UiText.from_file(UiText.DEFAULT_PATH)
	assert_true(loaded.result.ok, loaded.result.message)
	_texts = loaded.texts


func before_each() -> void:
	var data: NpcLifeCheck.GameData = NpcLifeCheck.load_game_data()
	assert_eq(data.problem, "", "Os dados reais do jogo carregam.")
	var setup: NpcSetup = NpcSetup.from_dir(DATA_DIR, SettlementService.new(data.settlements, data.places), true)
	assert_true(setup.result.ok, setup.result.message)
	_host = SimulationHostNode.new()
	_host.start_new_game(WORLD_SEED, data.terrain, data.points, setup)
	_bridge = SimBridge.new(_host, data.terrain, data.places, _host.npc)


func after_each() -> void:
	_host.runner.finish()
	_host.free()


func _press(panel: NpcInspectorPanel, action: StringName) -> bool:
	var event: InputEventAction = InputEventAction.new()
	event.action = action
	event.pressed = true
	return panel.handle_action(event)


func _mounted(is_development_build: bool = true) -> NpcInspectorPanel:
	var holder: Node = Node.new()
	add_child_autofree(holder)
	return NpcInspectorMount.mount(holder, _bridge, _texts, is_development_build)


func test_f3_and_tab_open_and_close_and_the_other_actions_only_work_while_it_is_open() -> void:
	var panel: NpcInspectorPanel = _mounted()
	var ids: Array[int] = _host.npc.peek_npc_ids()
	assert_false(panel.is_open(), "Começa fechado.")
	for closed_action: StringName in [InputActions.INSPECTOR_NEXT, InputActions.INSPECTOR_PREVIOUS, InputActions.INSPECTOR_TRACE, InputActions.JUMP]:
		assert_false(_press(panel, closed_action), "Fechado, '%s' deixa o evento passar." % closed_action)
	assert_eq(panel.model().selected_id(), NpcInspectorModel.NO_NPC, "E nada mudou.")
	assert_true(_press(panel, InputActions.INSPECTOR_TOGGLE))
	assert_true(panel.is_open(), "F3 abre.")
	assert_true(_press(panel, InputActions.INSPECTOR_NEXT))
	assert_true(_press(panel, InputActions.INSPECTOR_NEXT))
	assert_eq(panel.model().selected_id(), ids[1], "N vai ao próximo.")
	assert_true(_press(panel, InputActions.INSPECTOR_PREVIOUS))
	assert_eq(panel.model().selected_id(), ids[0], "B volta ao anterior.")
	assert_true(_press(panel, InputActions.INSPECTOR_TRACE))
	assert_true(panel.model().is_traced(), "T marca o NPC selecionado para o rastro.")
	assert_false(_press(panel, InputActions.JUMP), "Aberto, uma ação que não é do painel também passa.")
	assert_true(_press(panel, InputActions.INSPECTOR_TOGGLE_ALT))
	assert_false(panel.is_open(), "Tab fecha.")


func test_the_panel_is_only_mounted_in_a_development_build() -> void:
	assert_null(_mounted(false), "Fora de desenvolvimento nada é criado.")
	var holder: Node = Node.new()
	add_child_autofree(holder)
	assert_null(NpcInspectorMount.mount(holder, _bridge, _texts, false))
	assert_eq(holder.get_child_count(), 0, "Nenhum nó foi posto na cena.")
	var panel: NpcInspectorPanel = NpcInspectorMount.mount(holder, _bridge, _texts, true)
	assert_not_null(panel)
	assert_eq([holder.get_child_count(), panel.name], [1, NpcInspectorMount.PANEL_NAME as StringName])
	assert_false(panel.is_open())
	assert_null(NpcInspectorMount.mount(holder, null, _texts, true), "Ponte nula: sem painel.")
	assert_push_error("NpcInspectorPanel.setup")
	assert_eq(holder.get_child_count(), 1, "E nada sobrou na cena.")


func test_the_main_scene_mounts_the_panel_once_with_the_engine_development_flag() -> void:
	var source: String = FileAccess.get_file_as_string(MAIN_VIEW_SOURCE)
	assert_false(source.is_empty(), "Não foi possível ler %s." % MAIN_VIEW_SOURCE)
	assert_eq(source.count("NpcInspectorMount.mount("), 1, "Um só ponto monta o painel.")
	assert_true(source.contains(MOUNT_CALL), "Com o sinal de build de desenvolvimento do motor.")
