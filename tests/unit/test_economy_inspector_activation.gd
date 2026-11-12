extends GutTest
## LW-108d: a ativação do painel de depuração da economia (src/tools/economy_inspector/economy_inspector_mount.gd e `handle_action` do painel; contrato em docs/modules/tools.md, "Painel econômico"), sem janela
## e com o jogo real. Confere que Shift+Tab (a ação `inspector_toggle_alt` COM o Shift) abre e fecha só o painel da economia, que o Tab sozinho segue sendo só do painel de NPC, que os dois convivem na mesma
## árvore sem um abrir o outro (a entrega da entrada passa pelo viewport, na ordem em que o jogo monta os painéis), que o painel só é montado em build de desenvolvimento (o sinal entra por parâmetro)
## e que a cena principal o monta pelo gancho, DEPOIS do painel de NPC. A tecla em si (Tab) está em tests/unit/test_input_actions.gd.

const MAIN_VIEW_SOURCE: String = "res://src/presentation/world_view/main_world_view.gd"
const NPC_MOUNT_CALL: String = "NpcInspectorMount.mount(self, bridge, _texts, OS.is_debug_build())"
const ECONOMY_MOUNT_CALL: String = "EconomyInspectorMount.mount(self, bridge, _texts, OS.is_debug_build())"

var _texts: UiText
var _host: SimulationHostNode
var _app: GameAppNode
var _bridge: SimBridge
var _npc_panel: NpcInspectorPanel
var _economy_panel: EconomyInspectorPanel


func before_all() -> void:
	var loaded: UiText.LoadResult = UiText.from_file(UiText.DEFAULT_PATH)
	assert_true(loaded.result.ok, loaded.result.message)
	_texts = loaded.texts


func before_each() -> void:
	_host = SimulationHostNode.new()
	_app = GameAppNode.new()
	_app.bind_host(_host)
	_app.start_default_game(_host)
	_bridge = _app.peek_bridge()
	var holder: Node = Node.new()
	add_child_autofree(holder)
	# Na mesma ordem da cena principal: o painel de NPC primeiro e o da economia depois.
	_npc_panel = NpcInspectorMount.mount(holder, _bridge, _texts, true)
	_economy_panel = EconomyInspectorMount.mount(holder, _bridge, _texts, true)


func after_each() -> void:
	_app.free()
	if _host.runner != null:
		_host.runner.finish()
	_host.free()


func _tab(with_shift: bool) -> InputEventKey:
	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = KEY_TAB
	event.pressed = true
	event.shift_pressed = with_shift
	return event


## Entrega a tecla pelo viewport, como o jogo faz: passa pela entrada não tratada de cada nó da árvore, do último para o primeiro, até alguém consumir o evento.
func _send(event: InputEvent) -> void:
	get_viewport().push_input(event)


func _action(action: StringName) -> InputEventAction:
	var event: InputEventAction = InputEventAction.new()
	event.action = action
	event.pressed = true
	return event


func test_shift_tab_opens_and_closes_only_the_economy_panel() -> void:
	assert_false(_economy_panel.is_open(), "Começa fechado.")
	_send(_tab(true))
	assert_true(_economy_panel.is_open(), "Shift+Tab abre o painel da economia.")
	assert_false(_npc_panel.is_open(), "E o painel de NPC não abre junto.")
	_send(_tab(true))
	assert_false(_economy_panel.is_open(), "Shift+Tab fecha.")
	assert_false(_npc_panel.is_open())


func test_plain_tab_still_belongs_only_to_the_npc_panel() -> void:
	_send(_tab(false))
	assert_true(_npc_panel.is_open(), "Tab abre o painel de NPC, como antes.")
	assert_false(_economy_panel.is_open(), "E o da economia não se mexe.")
	_send(_tab(false))
	assert_false(_npc_panel.is_open(), "Tab fecha o painel de NPC.")
	assert_false(_economy_panel.is_open())


func test_the_two_panels_can_be_open_together_and_each_key_only_moves_its_own() -> void:
	_send(_tab(false))
	_send(_tab(true))
	assert_true(_npc_panel.is_open() and _economy_panel.is_open(), "Os dois abertos ao mesmo tempo.")
	_send(_tab(true))
	assert_true(_npc_panel.is_open(), "Shift+Tab fechou só o da economia.")
	assert_false(_economy_panel.is_open())
	_send(_tab(false))
	assert_false(_npc_panel.is_open(), "Tab fechou só o de NPC.")


func test_handle_action_needs_the_toggle_action_with_the_shift_and_nothing_else_opens_it() -> void:
	assert_false(_economy_panel.handle_action(_action(InputActions.INSPECTOR_TOGGLE_ALT)), "A ação sozinha, sem tecla e sem Shift, não é do painel da economia.")
	assert_false(_economy_panel.handle_action(_tab(false)), "Tab sem Shift deixa o evento passar.")
	for other: StringName in [InputActions.INSPECTOR_TOGGLE, InputActions.INSPECTOR_NEXT, InputActions.INSPECTOR_PREVIOUS, InputActions.INSPECTOR_TRACE, InputActions.JUMP, InputActions.PAUSE]:
		assert_false(_economy_panel.handle_action(_action(other)), "'%s' não é do painel da economia." % other)
	assert_false(_economy_panel.is_open(), "Nada disso abriu o painel.")
	assert_true(_economy_panel.handle_action(_tab(true)), "Shift+Tab é do painel da economia.")
	assert_true(_economy_panel.is_open())


func test_the_panel_is_only_mounted_in_a_development_build() -> void:
	var holder: Node = Node.new()
	add_child_autofree(holder)
	assert_null(EconomyInspectorMount.mount(holder, _bridge, _texts, false), "Fora de desenvolvimento nada é criado.")
	assert_eq(holder.get_child_count(), 0, "Nenhum nó foi posto na cena.")
	assert_null(EconomyInspectorMount.mount(holder, null, _texts, true), "Com ponte nula a ligação falha e nada fica na cena.")
	assert_push_error("EconomyInspectorPanel.setup")
	assert_eq(holder.get_child_count(), 0)
	var panel: EconomyInspectorPanel = EconomyInspectorMount.mount(holder, _bridge, _texts, true)
	assert_not_null(panel)
	assert_eq([holder.get_child_count(), panel.name], [1, EconomyInspectorMount.PANEL_NAME as StringName])
	assert_false(panel.is_open(), "Montado, começa fechado.")


func test_the_main_scene_mounts_the_economy_panel_after_the_npc_panel_with_the_engine_debug_signal() -> void:
	var source: String = FileAccess.get_file_as_string(MAIN_VIEW_SOURCE)
	assert_false(source.is_empty(), "Não foi possível ler %s." % MAIN_VIEW_SOURCE)
	assert_true(source.contains(ECONOMY_MOUNT_CALL), "Com o sinal de build de desenvolvimento do motor.")
	assert_gt(source.find(ECONOMY_MOUNT_CALL), source.find(NPC_MOUNT_CALL), "Depois do painel de NPC: é a ordem que faz o Shift+Tab chegar primeiro ao painel da economia.")
	assert_eq(source.count("EconomyInspectorMount.mount("), 1, "Um único ponto de montagem.")
