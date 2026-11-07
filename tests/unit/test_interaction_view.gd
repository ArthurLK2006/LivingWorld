extends GutTest
## LW-050: interação na tela, sem janela. Mundo do jogo real (host com terreno e pontos reais), PlayerBody real e InteractionView com rótulos
## reais. A posição do corpo é posta à mão e o relato à simulação é feito pela ponte, sem esperar quadros de física (o corpo só relataria a
## cada 6 quadros). Valores esperados escritos à mão a partir do envio: alcance de 3 m, texto por 5 s, "[E] Interagir".

const BLOCKOUT_DIR: String = "res://data/world"
const WORLD_SEED: int = 3
const NEAR_POINT: Vector3 = Vector3(120.0, 10.0, 513.0)
const FAR_POINT: Vector3 = Vector3(220.0, 10.0, 513.0)
const FAR_FROM_MARKERS: Vector3 = Vector3(900.0, 10.0, 100.0)
const REACH_M: float = 3.0
const JUST_OUT_M: float = 3.2
const HUGE_BUDGET_MS: float = 1.0e9
const COLLISION_FRAMES: int = 4
const HEIGHT_TOLERANCE_M: float = 0.001
const MARKER_HALF_HEIGHT_M: float = 1.25
const TEXT_SECONDS: float = 5.0

var _terrain: TerrainData
var _points: Array[PointOfInterest] = []
var _host: SimulationHostNode
var _bridge: SimBridge
var _view: TerrainView
var _reference: Node3D
var _texts: UiText
var _body: PlayerBody
var _prompt: Label
var _result: Label
var _interaction: InteractionView


func before_all() -> void:
	var terrain_loaded: TerrainLoader.LoadResult = TerrainLoader.load_dir(BLOCKOUT_DIR)
	assert_true(terrain_loaded.result.ok, terrain_loaded.result.message)
	_terrain = terrain_loaded.terrain
	var points_loaded: PointOfInterestLoader.LoadResult = PointOfInterestLoader.load_dir(BLOCKOUT_DIR, _terrain)
	assert_true(points_loaded.result.ok, points_loaded.result.message)
	_points = points_loaded.points
	var texts_loaded: UiText.LoadResult = UiText.from_file(UiText.DEFAULT_PATH)
	assert_true(texts_loaded.result.ok, texts_loaded.result.message)
	_texts = texts_loaded.texts
	_host = SimulationHostNode.new()
	_host.start_new_game(WORLD_SEED, _terrain, _points)
	_bridge = SimBridge.new(_host, _terrain)
	_reference = Node3D.new()
	add_child(_reference)
	_view = TerrainView.new()
	add_child(_view)
	_view.setup(_bridge)
	_view.set_focus(NEAR_POINT)
	_view.process_budget(HUGE_BUDGET_MS)
	for _frame: int in range(COLLISION_FRAMES):
		await get_tree().physics_frame


func after_all() -> void:
	_host.runner.finish()
	_host.free()
	_view.free()
	_reference.free()


func before_each() -> void:
	_host.start_new_game(WORLD_SEED, _terrain, _points)
	_body = PlayerBody.new()
	add_child_autofree(_body)
	assert_true(_body.setup(_bridge, _view, _reference))
	_prompt = Label.new()
	_result = Label.new()
	add_child_autofree(_prompt)
	add_child_autofree(_result)
	_interaction = InteractionView.new()
	add_child_autofree(_interaction)
	assert_true(_interaction.setup(_bridge, _body, _view, _texts, _prompt, _result))


## Põe o corpo em `point` e relata a posição à simulação (o que o corpo faria a cada 6 quadros), sem avançar a física.
func _stand_at(point: Vector3) -> void:
	_body.global_position = point
	var reported: Result = _bridge.request_report_position(_body.get_actor_id(), point, 0.0)
	assert_true(reported.ok, reported.message)
	_interaction.refresh()


func test_one_marker_is_created_per_point_once_and_sits_on_the_terrain_height() -> void:
	assert_eq(_interaction.marker_count(), 2)
	for _round: int in range(3):
		_interaction.refresh()
	assert_eq(_interaction.marker_count(), 2, "Os marcadores são criados uma vez, não a cada quadro.")
	for point: PointOfInterest in _points:
		var marker: MeshInstance3D = _interaction.marker_of(point.id)
		assert_not_null(marker, "Marcador do ponto '%s'." % point.id)
		var ground: SimBridge.HeightReply = _bridge.peek_height(point.position.x, point.position.z)
		assert_almost_eq(marker.global_position.x, point.position.x, HEIGHT_TOLERANCE_M)
		assert_almost_eq(marker.global_position.z, point.position.z, HEIGHT_TOLERANCE_M)
		assert_almost_eq(marker.global_position.y - MARKER_HALF_HEIGHT_M, ground.height_m, HEIGHT_TOLERANCE_M, "A base do marcador toca o chão.")
	assert_null(_interaction.marker_of("nao_existe"))


func test_a_marker_is_visible_only_where_the_ground_exists() -> void:
	_interaction.refresh()
	assert_true(_interaction.marker_of("test_marker_near").visible, "O chão do marco perto foi construído.")
	_view.set_focus(FAR_FROM_MARKERS)
	_view.process_budget(HUGE_BUDGET_MS)
	for _frame: int in range(COLLISION_FRAMES):
		await get_tree().physics_frame
	_interaction.refresh()
	assert_false(_interaction.marker_of("test_marker_near").visible, "Sem o chão do chunk (descartado), o marcador não flutua no vazio.")
	assert_false(_interaction.marker_of("test_marker_far").visible)
	_view.set_focus(NEAR_POINT)
	_view.process_budget(HUGE_BUDGET_MS)
	for _frame: int in range(COLLISION_FRAMES):
		await get_tree().physics_frame
	_interaction.refresh()
	assert_true(_interaction.marker_of("test_marker_near").visible, "Com o chão de volta, o marcador reaparece.")


func test_the_prompt_appears_only_inside_the_reach_and_disappears_outside() -> void:
	_stand_at(NEAR_POINT + Vector3(REACH_M + 30.0, 0.0, 0.0))
	assert_false(_prompt.visible, "A 33 m não há aviso.")
	_stand_at(NEAR_POINT + Vector3(JUST_OUT_M, 0.0, 0.0))
	assert_false(_prompt.visible, "A 3,2 m não há aviso.")
	_stand_at(NEAR_POINT + Vector3(REACH_M, 0.0, 0.0))
	assert_true(_prompt.visible, "A 3 m exatos há aviso (inclusive no limite).")
	assert_eq(_prompt.text, "[E] Interagir", "A tecla vem da ação interact no InputMap.")
	assert_eq(_interaction.nearest_point_id(), "test_marker_near")
	_stand_at(NEAR_POINT)
	assert_true(_prompt.visible)
	_stand_at(NEAR_POINT + Vector3(0.0, 0.0, -JUST_OUT_M))
	assert_false(_prompt.visible, "Saindo do alcance (no eixo z) o aviso some.")
	assert_eq(_interaction.nearest_point_id(), "")


func test_the_prompt_works_for_the_far_point_too_and_only_for_its_own_reach() -> void:
	_stand_at(FAR_POINT + Vector3(1.0, 0.0, 0.0))
	assert_true(_prompt.visible)
	assert_eq(_interaction.nearest_point_id(), "test_marker_far")
	_stand_at(NEAR_POINT + Vector3(1.0, 0.0, 0.0))
	assert_eq(_interaction.nearest_point_id(), "test_marker_near")


func test_interacting_shows_the_text_of_the_right_point() -> void:
	_stand_at(NEAR_POINT + Vector3(1.0, 0.0, 0.0))
	assert_true(_interaction.interact())
	assert_true(_result.visible)
	assert_eq(_result.text, _texts.get_text("poi.test_marker_near"))
	assert_string_contains(_result.text, "pedra")
	_stand_at(FAR_POINT + Vector3(1.0, 0.0, 0.0))
	assert_true(_interaction.interact())
	assert_eq(_result.text, _texts.get_text("poi.test_marker_far"))
	assert_string_contains(_result.text, "fogueira")
	assert_ne(_texts.get_text("poi.test_marker_near"), _result.text, "Os dois pontos dão textos diferentes.")


func test_interacting_out_of_reach_shows_the_error_text_and_publishes_nothing() -> void:
	var received: Array[SimEvent] = []
	_host.runner.world.context.events.subscribe("InteractionPerformed", func(event: SimEvent) -> void: received.append(event))
	_stand_at(NEAR_POINT + Vector3(40.0, 0.0, 0.0))
	assert_false(_prompt.visible)
	assert_false(_interaction.interact())
	assert_true(_result.visible)
	assert_eq(_result.text, "Chegue mais perto.", "A simulação recusa por distância e a tela mostra o texto da chave de erro.")
	_host.runner.step_once()
	assert_eq(received.size(), 0)


func test_when_the_body_looks_close_but_the_stored_position_is_far_the_simulation_decides() -> void:
	_body.global_position = NEAR_POINT + Vector3(1.0, 0.0, 0.0)
	_interaction.refresh()
	assert_true(_prompt.visible, "Pela posição do corpo o ponto está ao alcance (dica visual).")
	assert_false(_interaction.interact(), "Mas o último relato, guardado na simulação, é do nascimento, a cerca de 20 m: quem decide é ela.")
	assert_eq(_result.text, _texts.get_text("ui.interact_too_far"))


func test_the_text_disappears_after_five_seconds() -> void:
	_stand_at(NEAR_POINT + Vector3(1.0, 0.0, 0.0))
	assert_true(_interaction.interact())
	_interaction.tick(TEXT_SECONDS - 0.1)
	assert_true(_result.visible, "Aos 4,9 s o texto ainda está na tela.")
	_interaction.tick(0.2)
	assert_false(_result.visible, "Depois de 5 s ele some.")
	assert_eq(InteractionView.RESULT_TEXT_SECONDS, TEXT_SECONDS)


func test_a_second_interaction_restarts_the_five_seconds() -> void:
	_stand_at(NEAR_POINT + Vector3(1.0, 0.0, 0.0))
	assert_true(_interaction.interact())
	_interaction.tick(4.0)
	assert_true(_interaction.interact())
	_interaction.tick(4.0)
	assert_true(_result.visible, "O tempo recomeça a cada interação.")
	_interaction.tick(1.1)
	assert_false(_result.visible)


func test_a_missing_text_key_shows_the_key_in_brackets_and_warns_once() -> void:
	var empty: UiText = UiText.new()
	var view: InteractionView = InteractionView.new()
	add_child_autofree(view)
	assert_true(view.setup(_bridge, _body, _view, empty, _prompt, _result))
	_stand_at(NEAR_POINT + Vector3(1.0, 0.0, 0.0))
	view.refresh()
	assert_eq(_prompt.text, "[ui.interact_prompt]")
	view.refresh()
	assert_true(view.interact())
	assert_eq(_result.text, "[poi.test_marker_near]")
	assert_push_warning("ui.interact_prompt")
	assert_push_warning("poi.test_marker_near")


func test_the_error_codes_the_view_reads_are_the_ones_of_the_simulation() -> void:
	assert_eq(InteractionView.CODE_TOO_FAR, InteractionService.CODE_TOO_FAR)
	assert_eq(InteractionView.CODE_UNKNOWN_POI, InteractionService.CODE_UNKNOWN_POI)


func test_setup_with_a_missing_piece_reports_the_error_and_creates_nothing() -> void:
	var view: InteractionView = InteractionView.new()
	add_child_autofree(view)
	assert_false(view.setup(null, _body, _view, _texts, _prompt, _result))
	assert_push_error("InteractionView.setup")
	assert_false(view.setup(_bridge, _body, _view, null, _prompt, _result))
	assert_push_error("InteractionView.setup")
	assert_eq(view.marker_count(), 0)
	var no_game: SimBridge = SimBridge.new(null, _terrain)
	assert_false(view.setup(no_game, _body, _view, _texts, _prompt, _result))
	assert_push_error("pontos de interesse indisponíveis")
	assert_eq(view.marker_count(), 0)
