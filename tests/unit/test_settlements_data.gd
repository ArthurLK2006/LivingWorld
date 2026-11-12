extends GutTest
## LW-056 e LW-097a: os dados REAIS dos três assentamentos de teste (data/world/settlements.json e places.json) sobre o terreno de blockout,
## sem janela. As coordenadas são [HIP] e NÃO são conferidas por número: confere-se o que importa (dentro do mapa, perto do centro, chão plano
## por inclinação, fora do caminho, locais afastados entre si) e o que o contrato manda (contagens, capacidades, chaves de texto).
## Os casos de arquivo inválido e as consultas estão em tests/unit/test_settlements.gd.

const BLOCKOUT_DIR: String = "res://data/world"
const SETTLEMENT_A: String = "test_settlement_a"
const SETTLEMENT_B: String = "test_settlement_b"
const SETTLEMENT_C: String = "test_settlement_c"
## Contrato [HIP]: A com 12 casas de capacidade 5, B com 9 (a nona veio com a LW-097d: 44 pessoas) e C com 8; locais de trabalho para os cinco ofícios; 1 a 2 de descanso e de convívio; 1 de mercado.
const HOMES_A: int = 12
const HOMES_B: int = 9
const HOMES_C: int = 8
const HOME_CAPACITY: int = 5
const WORK_PLACES: int = 5
## LW-097a (docs/modules/world.md, Extensão da Fase 3; docs/economy/dados.md): um local `work` para cada local de produção e cada posto de
## serviço, então A 7, B 8 e C 5 (20 ao todo, 10 novos); os 10 de antes ficam como eram (A: 5 de capacidade 12; B: 5 de capacidade 8).
const WORK_A: int = 7
const WORK_B: int = 8
const WORK_C: int = 5
const WORK_CAPACITY_A: int = 12
const WORK_CAPACITY_B: int = 8
const WORK_CAPACITY_C: int = 8
const OLD_WORK_PER_SETTLEMENT: int = 5
## Dois povoados a menos que o dobro do raio um do outro teriam áreas que se sobrepõem.
const MIN_SETTLEMENT_SPACING_M: float = SettlementLoader.SETTLEMENT_MAX_RADIUS_M * 2.0
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


func test_the_real_files_have_the_three_test_settlements_inside_the_map_with_ground_height() -> void:
	assert_eq(_loaded.settlements.size(), 3)
	assert_eq(_loaded.settlements[0].id, SETTLEMENT_A)
	assert_eq(_loaded.settlements[1].id, SETTLEMENT_B)
	assert_eq(_loaded.settlements[2].id, SETTLEMENT_C)
	for settlement: Settlement in _loaded.settlements:
		var ground: TerrainData.HeightQuery = _terrain.peek_height(settlement.position.x, settlement.position.z)
		assert_true(ground.result.ok, "O centro de '%s' está dentro do mapa." % settlement.id)
		assert_almost_eq(settlement.position.y, ground.height_m, HEIGHT_TOLERANCE_M, "A altura vem do terreno, não do arquivo.")


func test_each_settlement_has_the_places_the_contract_asks_for_and_room_for_the_100_npcs() -> void:
	assert_eq(_count_of_kind(SETTLEMENT_A, Place.KIND_HOME), HOMES_A)
	assert_eq(_count_of_kind(SETTLEMENT_B, Place.KIND_HOME), HOMES_B)
	assert_eq(_count_of_kind(SETTLEMENT_C, Place.KIND_HOME), HOMES_C)
	var home_capacity: int = 0
	for settlement_id: String in [SETTLEMENT_A, SETTLEMENT_B, SETTLEMENT_C]:
		for home: Place in _service.peek_places_of_kind(settlement_id, Place.KIND_HOME).places:
			assert_eq(home.capacity, HOME_CAPACITY, "Casa '%s': capacidade de 5 moradores." % home.id)
			home_capacity += home.capacity
		assert_gte(_count_of_kind(settlement_id, Place.KIND_WORK), WORK_PLACES, "Locais de trabalho para os cinco ofícios.")
		assert_between(_count_of_kind(settlement_id, Place.KIND_REST), 1, 2)
		assert_between(_count_of_kind(settlement_id, Place.KIND_SOCIAL), 1, 2)
		assert_eq(_count_of_kind(settlement_id, Place.KIND_MARKET), 1)
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


func test_the_work_places_match_the_20_the_economy_needs_and_the_old_ten_are_unchanged() -> void:
	assert_eq([_count_of_kind(SETTLEMENT_A, Place.KIND_WORK), _count_of_kind(SETTLEMENT_B, Place.KIND_WORK), _count_of_kind(SETTLEMENT_C, Place.KIND_WORK)], [WORK_A, WORK_B, WORK_C])
	var capacity_by_settlement: Dictionary[String, int] = {SETTLEMENT_A: WORK_CAPACITY_A, SETTLEMENT_B: WORK_CAPACITY_B, SETTLEMENT_C: WORK_CAPACITY_C}
	for settlement_id: String in capacity_by_settlement:
		for work: Place in _service.peek_places_of_kind(settlement_id, Place.KIND_WORK).places:
			assert_eq(work.capacity, capacity_by_settlement[settlement_id], "O local '%s' tem a capacidade do seu povoado." % work.id)
	for old_id: String in ["a_work_01", "a_work_02", "a_work_03", "a_work_04", "a_work_05", "b_work_01", "b_work_02", "b_work_03", "b_work_04", "b_work_05"]:
		assert_true(_service.peek_place(old_id).result.ok, "O local '%s' de antes continua existindo." % old_id)
	for index: int in OLD_WORK_PER_SETTLEMENT:
		var suffix: String = "work_%02d" % (index + 1)
		assert_eq(_service.peek_place("a_%s" % suffix).place.capacity, WORK_CAPACITY_A)
		assert_eq(_service.peek_place("b_%s" % suffix).place.capacity, WORK_CAPACITY_B)
	for new_id: String in ["a_work_06", "a_work_07", "b_work_06", "b_work_07", "b_work_08", "c_work_01", "c_work_02", "c_work_03", "c_work_04", "c_work_05"]:
		assert_true(_service.peek_place(new_id).result.ok, "O local novo '%s' existe." % new_id)


func test_the_new_work_places_sort_after_the_old_ones_so_the_current_population_keeps_its_workplaces() -> void:
	for settlement_id: String in [SETTLEMENT_A, SETTLEMENT_B]:
		var ids: Array[String] = []
		for work: Place in _service.peek_places_of_kind(settlement_id, Place.KIND_WORK).places:
			ids.append(work.id)
		ids.sort()
		var letter: String = settlement_id.right(1)
		var old_ids: Array[String] = []
		for index: int in OLD_WORK_PER_SETTLEMENT:
			old_ids.append("%s_work_%02d" % [letter, index + 1])
		assert_eq(ids.slice(0, OLD_WORK_PER_SETTLEMENT), old_ids, "Os locais de antes vêm primeiro na ordem de id: quem preenche por vaga continua escolhendo os mesmos.")


func test_the_three_settlements_stand_apart_and_the_third_one_is_on_flat_ground_inside_its_radius() -> void:
	for first: int in _loaded.settlements.size():
		for second: int in range(first + 1, _loaded.settlements.size()):
			var apart_m: float = Vector2(_loaded.settlements[first].position.x, _loaded.settlements[first].position.z).distance_to(Vector2(_loaded.settlements[second].position.x, _loaded.settlements[second].position.z))
			assert_gte(apart_m, MIN_SETTLEMENT_SPACING_M, "'%s' e '%s' ficam afastados." % [_loaded.settlements[first].id, _loaded.settlements[second].id])
	var center: Vector3 = _loaded.settlements[2].position
	assert_lt(_max_slope_deg(center.x, center.z, FOOTPRINT_RADIUS_M), MAX_SLOPE_DEG, "O centro do terceiro povoado fica em chão plano.")
	assert_eq(_non_grass_samples(center.x, center.z, FOOTPRINT_RADIUS_M), 0, "O centro do terceiro povoado fica só sobre grama.")
	for place: Place in _service.peek_places_of_kind(SETTLEMENT_C, Place.KIND_WORK).places:
		assert_lte(Vector2(place.position.x, place.position.z).distance_to(Vector2(center.x, center.z)), SettlementLoader.SETTLEMENT_MAX_RADIUS_M)


func test_the_slope_and_surface_checks_do_see_a_real_hill_and_the_path() -> void:
	assert_gt(_max_slope_deg(HILL_FLANK_X_M, HILL_FLANK_Z_M, FOOTPRINT_RADIUS_M), MAX_SLOPE_DEG, "A encosta da colina passa do limite: a medida enxerga inclinação.")
	assert_gt(_non_grass_samples(HILL_FLANK_X_M, PATH_AXIS_Z_M, FOOTPRINT_RADIUS_M), 0, "Em cima do caminho há pontos que não são grama: a medida enxerga o caminho.")


func test_the_settlement_names_exist_in_the_text_file() -> void:
	var texts: UiText.LoadResult = UiText.from_file(UiText.DEFAULT_PATH)
	assert_true(texts.result.ok, texts.result.message)
	for settlement: Settlement in _loaded.settlements:
		assert_true(texts.texts.has_key(settlement.name_key), "Falta a chave '%s' em data/text/pt_br.json." % settlement.name_key)
		assert_ne(texts.texts.get_text(settlement.name_key), "[%s]" % settlement.name_key)
	assert_ne(texts.texts.get_text(_loaded.settlements[0].name_key), texts.texts.get_text(_loaded.settlements[1].name_key), "Os nomes de A e B são diferentes.")
	assert_ne(texts.texts.get_text(_loaded.settlements[2].name_key), texts.texts.get_text(_loaded.settlements[0].name_key), "Os nomes de C e A são diferentes.")
	assert_ne(texts.texts.get_text(_loaded.settlements[2].name_key), texts.texts.get_text(_loaded.settlements[1].name_key), "Os nomes de C e B são diferentes.")
