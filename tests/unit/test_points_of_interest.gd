extends GutTest
## LW-049: pontos de interesse (conteúdo de data/world/pois.json) e o comando de interação com validação de distância, sem janela.
## Os valores esperados estão ESCRITOS À MÃO a partir do envio: alcance de 3 m (inclusive no limite), distância horizontal, os dois
## pontos de teste perto do caminho que sai do nascimento (cerca de 20 m e cerca de 120 m) e o evento InteractionPerformed.

const BLOCKOUT_DIR: String = "res://data/world"
const WORLD_SEED: int = 3
const ACTOR_ID: int = 7
const REACH_M: float = 3.0
## Posições exatas em 32 bits (inteiros e meios): o limite do alcance é comparado sem arredondamento.
const NEAR_POINT: Vector3 = Vector3(120.0, 10.0, 513.0)
const FAR_POINT: Vector3 = Vector3(220.0, 10.0, 513.0)
const ONE_MILLIMETER_M: float = 0.001
const NEAR_MIN_M: float = 10.0
const NEAR_MAX_M: float = 40.0
const FAR_MIN_M: float = 90.0
const FAR_MAX_M: float = 150.0
const HEIGHT_TOLERANCE_M: float = 0.001
const HIGH_ABOVE_M: float = 100.0
const EVENT_TYPE: String = "InteractionPerformed"

var _terrain: TerrainData
var _points: Array[PointOfInterest] = []
var _runner: SimulationRunner
var _service: InteractionService
var _received: Array[InteractionPerformed] = []
var _temp_dirs: Array[DirAccess] = []


## Evento de prova, só para testar o cause_id em cadeia (publicado fora de src/, não entra no catálogo do jogo).
class ProbeEvent:
	extends SimEvent

	func _init() -> void:
		super("ProbeEvent")


func before_all() -> void:
	var terrain_loaded: TerrainLoader.LoadResult = TerrainLoader.load_dir(BLOCKOUT_DIR)
	assert_true(terrain_loaded.result.ok, terrain_loaded.result.message)
	_terrain = terrain_loaded.terrain
	var points_loaded: PointOfInterestLoader.LoadResult = PointOfInterestLoader.load_dir(BLOCKOUT_DIR, _terrain)
	assert_true(points_loaded.result.ok, points_loaded.result.message)
	_points = points_loaded.points


func before_each() -> void:
	_received.clear()
	_runner = SimulationRunner.new(WORLD_SEED)
	var modules: GameModules = GameModules.register(_runner, _terrain, _points)
	assert_true(modules.result.ok, modules.result.message)
	_service = modules.interaction
	_runner.start_new_game()
	_runner.world.context.events.subscribe(EVENT_TYPE, _on_interaction)


func after_each() -> void:
	_runner.finish()
	for dir: DirAccess in _temp_dirs:
		for file_name: String in dir.get_files():
			dir.remove(file_name)
		DirAccess.remove_absolute(dir.get_current_dir())
	_temp_dirs.clear()


func _on_interaction(event: SimEvent) -> void:
	_received.append(event as InteractionPerformed)


func _deliver() -> int:
	return _runner.world.context.events.dispatch()


## Pasta temporária com um pois.json de conteúdo `text`; devolve a pasta.
func _dir_with(text: String) -> String:
	var dir: DirAccess = DirAccess.create_temp("lw049")
	_temp_dirs.append(dir)
	var file: FileAccess = FileAccess.open(dir.get_current_dir().path_join("pois.json"), FileAccess.WRITE)
	file.store_string(text)
	file.close()
	return dir.get_current_dir()


func _assert_invalid(text: String, expected_parts: Array[String]) -> void:
	var loaded: PointOfInterestLoader.LoadResult = PointOfInterestLoader.load_dir(_dir_with(text), _terrain)
	assert_false(loaded.result.ok, "Arquivo inválido deveria falhar: " + text)
	assert_eq(loaded.result.code, PointOfInterestLoader.CODE_INVALID)
	assert_eq(loaded.points.size(), 0, "Falha não devolve ponto nenhum.")
	for part: String in expected_parts:
		assert_string_contains(loaded.result.message, part)


# ---------------------------------------------------------------- dados reais

func test_the_real_file_has_the_two_test_markers_inside_the_map_with_ground_height() -> void:
	assert_eq(_points.size(), 2)
	assert_eq(_points[0].id, "test_marker_near")
	assert_eq(_points[1].id, "test_marker_far")
	assert_eq(_points[0].kind, "test_marker")
	assert_eq(_points[1].kind, "test_marker")
	assert_eq(_points[0].text_key, "poi.test_marker_near")
	assert_eq(_points[1].text_key, "poi.test_marker_far")
	for point: PointOfInterest in _points:
		var ground: TerrainData.HeightQuery = _terrain.peek_height(point.position.x, point.position.z)
		assert_true(ground.result.ok, "O ponto '%s' está dentro do mapa." % point.id)
		assert_almost_eq(point.position.y, ground.height_m, HEIGHT_TOLERANCE_M, "A altura vem do terreno, não do arquivo.")


func test_the_markers_are_near_the_path_that_starts_at_the_spawn_point() -> void:
	var spawn: Vector3 = _terrain.peek_spawn_point()
	var near_m: float = Vector2(_points[0].position.x - spawn.x, _points[0].position.z - spawn.z).length()
	var far_m: float = Vector2(_points[1].position.x - spawn.x, _points[1].position.z - spawn.z).length()
	assert_between(near_m, NEAR_MIN_M, NEAR_MAX_M, "O marco perto fica a %s m do nascimento." % str(near_m))
	assert_between(far_m, FAR_MIN_M, FAR_MAX_M, "O marco longe fica a %s m do nascimento." % str(far_m))


func test_loading_twice_gives_the_same_points() -> void:
	var again: PointOfInterestLoader.LoadResult = PointOfInterestLoader.load_dir(BLOCKOUT_DIR, _terrain)
	assert_true(again.result.ok, again.result.message)
	assert_eq(again.points.size(), _points.size())
	for index: int in _points.size():
		assert_eq(again.points[index].id, _points[index].id)
		assert_eq(again.points[index].kind, _points[index].kind)
		assert_eq(again.points[index].position, _points[index].position)
		assert_eq(again.points[index].text_key, _points[index].text_key)


func test_loading_the_points_does_not_change_the_state_hash() -> void:
	var bare: SimulationRunner = SimulationRunner.new(WORLD_SEED)
	assert_true(GameModules.register(bare, _terrain).result.ok)
	bare.start_new_game()
	assert_eq(_runner.world.state_hash(), bare.world.state_hash(), "Os pontos são conteúdo: não entram no hash nem no save.")
	assert_false(_runner.capture_game()["world"]["modules"].has("interaction"), "O serviço de interação não é módulo salvo.")
	bare.finish()


# ---------------------------------------------------------------- arquivo inválido

func test_a_missing_field_is_reported_with_file_item_and_field() -> void:
	_assert_invalid('[{"id": "a_point", "kind": "test_marker", "x_cm": 12000, "z_cm": 51300}]', ["pois.json", "a_point", "text_key", "campo obrigatório ausente"])


func test_an_unknown_field_is_reported() -> void:
	_assert_invalid('[{"id": "a_point", "kind": "test_marker", "x_cm": 12000, "z_cm": 51300, "text_key": "k", "color": "red"}]', ["pois.json", "a_point", "color", "campo desconhecido"])


func test_a_repeated_id_is_reported() -> void:
	var line: String = '{"id": "same_id", "kind": "test_marker", "x_cm": 12000, "z_cm": 51300, "text_key": "k"}'
	_assert_invalid("[%s, %s]" % [line, line], ["pois.json", "same_id", "id", "duplicado"])


func test_a_point_outside_the_map_is_reported() -> void:
	_assert_invalid('[{"id": "far_away", "kind": "test_marker", "x_cm": 200000, "z_cm": 51300, "text_key": "k"}]', ["pois.json", "far_away", "x_cm", "fora do mapa"])


func test_an_empty_text_key_is_reported() -> void:
	_assert_invalid('[{"id": "a_point", "kind": "test_marker", "x_cm": 12000, "z_cm": 51300, "text_key": "  "}]', ["pois.json", "a_point", "text_key", "vazia"])


func test_a_kind_that_is_not_snake_case_is_reported() -> void:
	_assert_invalid('[{"id": "a_point", "kind": "Test Marker", "x_cm": 12000, "z_cm": 51300, "text_key": "k"}]', ["pois.json", "a_point", "kind", "snake_case"])


func test_a_coordinate_that_is_not_an_integer_is_reported() -> void:
	_assert_invalid('[{"id": "a_point", "kind": "test_marker", "x_cm": 12.5, "z_cm": 51300, "text_key": "k"}]', ["pois.json", "a_point", "x_cm", "tipo inválido"])


func test_malformed_json_and_a_missing_file_are_reported() -> void:
	_assert_invalid("[{", ["pois.json", "JSON inválido"])
	var missing: PointOfInterestLoader.LoadResult = PointOfInterestLoader.load_dir("res://tests/fixtures/world/pasta_que_nao_existe", _terrain)
	assert_false(missing.result.ok)
	assert_string_contains(missing.result.message, "arquivo não encontrado")


func test_a_null_terrain_is_refused_without_crashing() -> void:
	var refused: PointOfInterestLoader.LoadResult = PointOfInterestLoader.load_dir(BLOCKOUT_DIR, null)
	assert_false(refused.result.ok)
	assert_string_contains(refused.result.message, "terreno nulo")


# ---------------------------------------------------------------- interação

func test_a_short_distance_is_accepted_and_publishes_the_event_with_the_ids_and_no_cause() -> void:
	var outcome: InteractionService.InteractionResult = _service.request_interact(ACTOR_ID, NEAR_POINT + Vector3(1.0, 0.0, 0.0), "test_marker_near")
	assert_true(outcome.result.ok, outcome.result.message)
	assert_eq(outcome.poi_id, "test_marker_near")
	assert_eq(outcome.text_key, "poi.test_marker_near", "A simulação devolve só a chave do texto.")
	assert_eq(_received.size(), 0, "Publicar só enfileira: a entrega é no dispatch do passo.")
	assert_eq(_deliver(), 1)
	assert_eq(_received.size(), 1)
	assert_eq(_received[0].actor_id, ACTOR_ID)
	assert_eq(_received[0].poi_id, "test_marker_near")
	assert_eq(_received[0].kind, "test_marker")
	assert_eq(_received[0].type, EVENT_TYPE)
	assert_eq(_received[0].cause_id, SimEvent.NO_CAUSE, "Ninguém provocou este evento.")
	assert_gt(_received[0].id, 0)


func test_a_long_distance_is_refused_with_too_far_and_publishes_nothing() -> void:
	var outcome: InteractionService.InteractionResult = _service.request_interact(ACTOR_ID, NEAR_POINT + Vector3(10.0, 0.0, 0.0), "test_marker_near")
	assert_false(outcome.result.ok)
	assert_eq(outcome.result.code, InteractionService.CODE_TOO_FAR)
	assert_string_contains(outcome.result.message, "muito longe")
	assert_string_contains(outcome.result.message, "10", "A mensagem traz a distância.")
	assert_string_contains(outcome.result.message, "3", "E o alcance.")
	assert_eq(_deliver(), 0)
	assert_eq(_received.size(), 0)


func test_exactly_at_the_reach_is_accepted_and_one_millimeter_beyond_is_refused() -> void:
	var at_limit: InteractionService.InteractionResult = _service.request_interact(ACTOR_ID, NEAR_POINT + Vector3(REACH_M, 0.0, 0.0), "test_marker_near")
	assert_true(at_limit.result.ok, "A 3,000 m exatos vale (inclusive no limite): " + at_limit.result.message)
	var beyond: InteractionService.InteractionResult = _service.request_interact(ACTOR_ID, NEAR_POINT + Vector3(REACH_M + ONE_MILLIMETER_M, 0.0, 0.0), "test_marker_near")
	assert_false(beyond.result.ok, "A 3,001 m já não vale.")
	assert_eq(beyond.result.code, InteractionService.CODE_TOO_FAR)
	var inside_by_a_millimeter: InteractionService.InteractionResult = _service.request_interact(ACTOR_ID, NEAR_POINT + Vector3(0.0, 0.0, -(REACH_M - ONE_MILLIMETER_M)), "test_marker_near")
	assert_true(inside_by_a_millimeter.result.ok, "A 2,999 m vale, também no eixo z.")
	assert_eq(_deliver(), 2, "Só as duas aceitas publicaram.")


func test_only_the_horizontal_distance_counts_the_height_does_not() -> void:
	var outcome: InteractionService.InteractionResult = _service.request_interact(ACTOR_ID, NEAR_POINT + Vector3(1.0, HIGH_ABOVE_M, 0.0), "test_marker_near")
	assert_true(outcome.result.ok, "Um ator 100 m acima, mas a 1 m na horizontal, alcança o ponto: " + outcome.result.message)
	var diagonal: InteractionService.InteractionResult = _service.request_interact(ACTOR_ID, NEAR_POINT + Vector3(2.4, 0.0, 1.8), "test_marker_near")
	assert_true(diagonal.result.ok, "Em diagonal, 2,4 e 1,8 dão 3 m: " + diagonal.result.message)
	var diagonal_beyond: InteractionService.InteractionResult = _service.request_interact(ACTOR_ID, NEAR_POINT + Vector3(2.5, 0.0, 1.8), "test_marker_near")
	assert_false(diagonal_beyond.result.ok, "Em diagonal, 2,5 e 1,8 passam de 3 m.")


func test_each_marker_answers_with_its_own_text_key() -> void:
	var near: InteractionService.InteractionResult = _service.request_interact(ACTOR_ID, NEAR_POINT, "test_marker_near")
	var far: InteractionService.InteractionResult = _service.request_interact(ACTOR_ID, FAR_POINT, "test_marker_far")
	assert_eq(near.text_key, "poi.test_marker_near")
	assert_eq(far.text_key, "poi.test_marker_far")
	assert_ne(near.text_key, far.text_key)


func test_an_unknown_point_an_invalid_actor_and_a_non_finite_position_are_handled_errors() -> void:
	var unknown: InteractionService.InteractionResult = _service.request_interact(ACTOR_ID, NEAR_POINT, "no_such_point")
	assert_false(unknown.result.ok)
	assert_eq(unknown.result.code, InteractionService.CODE_UNKNOWN_POI)
	assert_string_contains(unknown.result.message, "no_such_point")
	assert_string_contains(unknown.result.message, "test_marker_near", "A mensagem lista os pontos que existem.")
	var no_actor: InteractionService.InteractionResult = _service.request_interact(IdGenerator.NO_ID, NEAR_POINT, "test_marker_near")
	assert_eq(no_actor.result.code, InteractionService.CODE_INVALID_ACTOR)
	var negative_actor: InteractionService.InteractionResult = _service.request_interact(-3, NEAR_POINT, "test_marker_near")
	assert_eq(negative_actor.result.code, InteractionService.CODE_INVALID_ACTOR)
	var not_a_number: InteractionService.InteractionResult = _service.request_interact(ACTOR_ID, Vector3(NAN, 0.0, 0.0), "test_marker_near")
	assert_eq(not_a_number.result.code, InteractionService.CODE_INVALID_POSITION)
	var infinite: InteractionService.InteractionResult = _service.request_interact(ACTOR_ID, Vector3(INF, 0.0, 0.0), "test_marker_near")
	assert_eq(infinite.result.code, InteractionService.CODE_INVALID_POSITION)
	assert_eq(_deliver(), 0, "Nenhuma recusa publica evento.")


func test_an_empty_point_list_refuses_every_interaction() -> void:
	var empty_runner: SimulationRunner = SimulationRunner.new(WORLD_SEED)
	var modules: GameModules = GameModules.register(empty_runner, _terrain)
	var outcome: InteractionService.InteractionResult = modules.interaction.request_interact(ACTOR_ID, NEAR_POINT, "test_marker_near")
	assert_eq(outcome.result.code, InteractionService.CODE_UNKNOWN_POI)
	assert_eq(modules.interaction.peek_points().size(), 0)
	empty_runner.finish()


func test_two_requests_publish_two_events_in_order() -> void:
	assert_true(_service.request_interact(ACTOR_ID, NEAR_POINT, "test_marker_near").result.ok)
	assert_true(_service.request_interact(ACTOR_ID, FAR_POINT, "test_marker_far").result.ok)
	assert_eq(_deliver(), 2)
	assert_eq(_received.size(), 2)
	assert_eq(_received[0].poi_id, "test_marker_near")
	assert_eq(_received[1].poi_id, "test_marker_far")
	assert_lt(_received[0].id, _received[1].id, "IDs de evento crescentes, na ordem do pedido.")


func test_an_interaction_published_while_another_event_is_handled_gets_that_event_as_its_cause() -> void:
	var events: EventBus = _runner.world.context.events
	var probe_ids: Array[int] = []
	events.subscribe("ProbeEvent", func(event: SimEvent) -> void:
		probe_ids.append(event.id)
		_service.request_interact(ACTOR_ID, NEAR_POINT, "test_marker_near"))
	events.publish(ProbeEvent.new())
	assert_eq(_deliver(), 2, "O evento de prova e a interação que ele provocou.")
	assert_eq(_received.size(), 1)
	assert_eq(_received[0].cause_id, probe_ids[0], "O EventBus preenche o cause_id com o evento em tratamento.")


func test_peek_points_returns_copies_in_file_order() -> void:
	var first: Array[PointOfInterest] = _service.peek_points()
	assert_eq(first.size(), 2)
	assert_eq(first[0].id, "test_marker_near")
	first[0].text_key = "alterado"
	first[0].position = Vector3.ZERO
	first.clear()
	var second: Array[PointOfInterest] = _service.peek_points()
	assert_eq(second.size(), 2)
	assert_eq(second[0].text_key, "poi.test_marker_near", "Mexer na cópia não altera o conteúdo.")
	assert_ne(second[0].position, Vector3.ZERO)
