extends GutTest
## LW-056: os dados REAIS dos dois assentamentos de teste (data/world/settlements.json e places.json) sobre o terreno de blockout, sem
## janela. As coordenadas são [HIP] e NÃO são conferidas por número: confere-se o que importa (dentro do mapa, perto do centro, chão plano
## por inclinação, fora do caminho, locais afastados entre si) e o que o contrato manda (contagens, capacidades, chaves de texto).
## Os casos de arquivo inválido e as consultas estão em tests/unit/test_settlements.gd.

const BLOCKOUT_DIR: String = "res://data/world"
const SETTLEMENT_A: String = "test_settlement_a"
const SETTLEMENT_B: String = "test_settlement_b"
## Contrato [HIP]: A com 12 casas de capacidade 5, B com 8; locais de trabalho para os cinco ofícios; 1 a 2 de descanso e de convívio; 1 de mercado.
const HOMES_A: int = 12
const HOMES_B: int = 8
const HOME_CAPACITY: int = 5
const WORK_PLACES: int = 5
const NPC_COUNT_OF_THE_SOAK: int = 100
const HEIGHT_TOLERANCE_M: float = 0.001
## Chão plano [HIP]: a inclinação medida entre o centro do local e pontos num círculo à volta (a caixa provisória cabe nele) fica abaixo disto.
const FOOTPRINT_RADIUS_M: float = 6.0
const SLOPE_SAMPLES: int = 8
const MAX_SLOPE_DEG: float = 5.0
## Dois locais a menos que isto um do outro se sobrepõem na tela (a maior caixa provisória tem cerca de 8 m).
const MIN_SPACING_M: float = 10.0
const GRASS_ID: String = "grass"
## Pontos de controle do blockout (docs/world/relevo-do-terreno-de-blockout.md): a encosta da colina, a cerca de 75 m do centro dela (700 m, 300 m), e o eixo do caminho.
const HILL_FLANK_X_M: float = 625.0
const HILL_FLANK_Z_M: float = 300.0
const PATH_AXIS_Z_M: float = 513.0

var _terrain: TerrainData
var _loaded: SettlementLoader.LoadResult
var _service: SettlementService


func before_all() -> void:
	var terrain_loaded: TerrainLoader.LoadResult = TerrainLoader.load_dir(BLOCKOUT_DIR)
	assert_true(terrain_loaded.result.ok, terrain_loaded.result.message)
	_terrain = terrain_loaded.terrain
	_loaded = SettlementLoader.load_dir(BLOCKOUT_DIR, _terrain)
	assert_true(_loaded.result.ok, _loaded.result.message)
	_service = SettlementService.new(_loaded.settlements, _loaded.places)


## Maior inclinação (graus) entre o centro e pontos num círculo de `radius_m`, lida só de `peek_height`.
func _max_slope_deg(center_x: float, center_z: float, radius_m: float) -> float:
	var center_height: float = _terrain.peek_height(center_x, center_z).height_m
	var worst_deg: float = 0.0
	for index: int in SLOPE_SAMPLES:
		var angle: float = TAU * float(index) / float(SLOPE_SAMPLES)
		var sample: TerrainData.HeightQuery = _terrain.peek_height(center_x + radius_m * cos(angle), center_z + radius_m * sin(angle))
		assert_true(sample.result.ok, "O chão à volta do local está dentro do mapa.")
		worst_deg = maxf(worst_deg, rad_to_deg(atan2(absf(sample.height_m - center_height), radius_m)))
	return worst_deg


## Quantos dos pontos do círculo à volta NÃO são grama (caminho ou pedra): a caixa não deve ficar sobre eles.
func _non_grass_samples(center_x: float, center_z: float, radius_m: float) -> int:
	var count: int = 0
	for index: int in SLOPE_SAMPLES:
		var angle: float = TAU * float(index) / float(SLOPE_SAMPLES)
		var surface: TerrainData.SurfaceQuery = _terrain.peek_surface(center_x + radius_m * cos(angle), center_z + radius_m * sin(angle))
		if surface.surface_id != GRASS_ID:
			count += 1
	return count


func _count_of_kind(settlement_id: String, kind: String) -> int:
	return _service.peek_places_of_kind(settlement_id, kind).places.size()


func test_the_real_files_have_the_two_test_settlements_inside_the_map_with_ground_height() -> void:
	assert_eq(_loaded.settlements.size(), 2)
	assert_eq(_loaded.settlements[0].id, SETTLEMENT_A)
	assert_eq(_loaded.settlements[1].id, SETTLEMENT_B)
	for settlement: Settlement in _loaded.settlements:
		var ground: TerrainData.HeightQuery = _terrain.peek_height(settlement.position.x, settlement.position.z)
		assert_true(ground.result.ok, "O centro de '%s' está dentro do mapa." % settlement.id)
		assert_almost_eq(settlement.position.y, ground.height_m, HEIGHT_TOLERANCE_M, "A altura vem do terreno, não do arquivo.")


func test_each_settlement_has_the_places_the_contract_asks_for_and_room_for_the_100_npcs() -> void:
	assert_eq(_count_of_kind(SETTLEMENT_A, Place.KIND_HOME), HOMES_A)
	assert_eq(_count_of_kind(SETTLEMENT_B, Place.KIND_HOME), HOMES_B)
	var home_capacity: int = 0
	for settlement_id: String in [SETTLEMENT_A, SETTLEMENT_B]:
		for home: Place in _service.peek_places_of_kind(settlement_id, Place.KIND_HOME).places:
			assert_eq(home.capacity, HOME_CAPACITY, "Casa '%s': capacidade de 5 moradores." % home.id)
			home_capacity += home.capacity
		assert_gte(_count_of_kind(settlement_id, Place.KIND_WORK), WORK_PLACES, "Locais de trabalho para os cinco ofícios.")
		assert_between(_count_of_kind(settlement_id, Place.KIND_REST), 1, 2)
		assert_between(_count_of_kind(settlement_id, Place.KIND_SOCIAL), 1, 2)
		assert_eq(_count_of_kind(settlement_id, Place.KIND_MARKET_RESERVED), 1)
	assert_gte(home_capacity, NPC_COUNT_OF_THE_SOAK, "As casas comportam os 100 NPCs da LW-068.")


func test_every_place_is_near_its_settlement_center_inside_the_map_and_at_ground_height() -> void:
	var centers: Dictionary[String, Vector2] = {}
	for settlement: Settlement in _loaded.settlements:
		centers[settlement.id] = Vector2(settlement.position.x, settlement.position.z)
	assert_gt(_loaded.places.size(), 0)
	for place: Place in _loaded.places:
		var ground: TerrainData.HeightQuery = _terrain.peek_height(place.position.x, place.position.z)
		assert_true(ground.result.ok, "O local '%s' está dentro do mapa." % place.id)
		assert_almost_eq(place.position.y, ground.height_m, HEIGHT_TOLERANCE_M, "A altura vem do terreno, não do arquivo.")
		assert_lte(Vector2(place.position.x, place.position.z).distance_to(centers[place.settlement_id]), SettlementLoader.SETTLEMENT_MAX_RADIUS_M, "'%s' fica perto do centro do seu assentamento." % place.id)
		assert_between(place.capacity, Place.MIN_CAPACITY, Place.MAX_CAPACITY)


func test_every_place_stands_on_flat_grass_away_from_the_path_and_apart_from_the_others() -> void:
	for place: Place in _loaded.places:
		assert_lt(_max_slope_deg(place.position.x, place.position.z, FOOTPRINT_RADIUS_M), MAX_SLOPE_DEG, "O local '%s' fica em chão plano." % place.id)
		assert_eq(_non_grass_samples(place.position.x, place.position.z, FOOTPRINT_RADIUS_M), 0, "O local '%s' fica só sobre grama (nem caminho nem pedra)." % place.id)
	for first: int in _loaded.places.size():
		for second: int in range(first + 1, _loaded.places.size()):
			var apart_m: float = Vector2(_loaded.places[first].position.x, _loaded.places[first].position.z).distance_to(Vector2(_loaded.places[second].position.x, _loaded.places[second].position.z))
			assert_gte(apart_m, MIN_SPACING_M, "'%s' e '%s' ficam afastados." % [_loaded.places[first].id, _loaded.places[second].id])


func test_the_slope_and_surface_checks_do_see_a_real_hill_and_the_path() -> void:
	assert_gt(_max_slope_deg(HILL_FLANK_X_M, HILL_FLANK_Z_M, FOOTPRINT_RADIUS_M), MAX_SLOPE_DEG, "A encosta da colina passa do limite: a medida enxerga inclinação.")
	assert_gt(_non_grass_samples(HILL_FLANK_X_M, PATH_AXIS_Z_M, FOOTPRINT_RADIUS_M), 0, "Em cima do caminho há pontos que não são grama: a medida enxerga o caminho.")


func test_the_settlement_names_exist_in_the_text_file() -> void:
	var texts: UiText.LoadResult = UiText.from_file(UiText.DEFAULT_PATH)
	assert_true(texts.result.ok, texts.result.message)
	for settlement: Settlement in _loaded.settlements:
		assert_true(texts.texts.has_key(settlement.name_key), "Falta a chave '%s' em data/text/pt_br.json." % settlement.name_key)
		assert_ne(texts.texts.get_text(settlement.name_key), "[%s]" % settlement.name_key)
	assert_ne(texts.texts.get_text(_loaded.settlements[0].name_key), texts.texts.get_text(_loaded.settlements[1].name_key), "Os dois nomes são diferentes.")
