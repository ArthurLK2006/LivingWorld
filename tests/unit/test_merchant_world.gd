extends GutTest
## LW-098h5 (docs/modules/economy.md, 9.15.5; opção A aprovada por Arthur em 18/11/2026): o plano de população REAL (`res://data`) com os seis comerciantes, dois por povoado. Cada um tem casa do próprio povoado e trabalha no
## mercado dele; as seis casas novas (capacidade 5) é que abrem a vaga: sem as duas do A, 62 moradores para 60 vagas, o plano falha com `NPC_POPULATION_NO_ROOM`, erro de DADO (nenhum NPC nasce). As contagens são LITERAIS de
## propósito (conferir o dado contra ele mesmo seria tautologia). O jogo jogado (dias, save, carga em viagem) fica em tests/integration/test_merchant_saves.gd.

const DATA_DIR: String = "res://data"
const WORLD_SEED: int = 1
const MERCHANT: String = "merchant"
const SETTLEMENT_A: String = "test_settlement_a"
const SETTLEMENT_B: String = "test_settlement_b"
const SETTLEMENT_C: String = "test_settlement_c"
## O local de trabalho do comerciante de cada povoado: o mercado (data/population.json, uma linha `merchant` por povoado).
const MARKETS: Dictionary[String, String] = {SETTLEMENT_A: "a_market_01", SETTLEMENT_B: "b_market_01", SETTLEMENT_C: "c_market_01"}
## As seis casas que a opção A acrescenta a data/world/places.json, com o povoado de cada uma.
const NEW_HOMES: Dictionary[String, String] = {"a_home_13": SETTLEMENT_A, "a_home_14": SETTLEMENT_A, "b_home_10": SETTLEMENT_B, "b_home_11": SETTLEMENT_B, "c_home_09": SETTLEMENT_C, "c_home_10": SETTLEMENT_C}
const NEW_HOME_CAPACITY: int = 5

var _data: NpcLifeCheck.GameData
var _places: SettlementService
var _plan: PopulationPlan
var _routine: RoutineTable


func before_all() -> void:
	_data = NpcLifeCheck.load_game_data()
	assert_eq(_data.problem, "", "Os dados reais do jogo carregam.")
	_places = SettlementService.new(_data.settlements, _data.places)
	var plan_loaded: PopulationLoader.LoadResult = PopulationLoader.load_dir(DATA_DIR)
	assert_true(plan_loaded.result.ok, plan_loaded.result.message)
	_plan = plan_loaded.plan
	var routine_loaded: RoutineLoader.LoadResult = RoutineLoader.load_dir(DATA_DIR)
	assert_true(routine_loaded.result.ok, routine_loaded.result.message)
	_routine = routine_loaded.table


## Os pedidos de criação do plano real com a semente do jogo, nos locais reais menos os de `missing_place_ids` (tirados só em memória).
func _build_specs(missing_place_ids: Array[String] = []) -> PopulationPlan.BuildResult:
	var places: Array[Place] = []
	for place: Place in _data.places:
		if not missing_place_ids.has(place.id):
			places.append(place)
	return _plan.build_specs(SettlementService.new(_data.settlements, places), _routine, WorldRng.new(WORLD_SEED))


func _count_by(specs: Array[NpcSpec], only_merchants: bool) -> Dictionary[String, int]:
	var counts: Dictionary[String, int] = {}
	for spec: NpcSpec in specs:
		if spec.occupation_id == MERCHANT or not only_merchants:
			counts[spec.settlement_id] = int(counts.get(spec.settlement_id, 0)) + 1
	return counts


func test_the_real_plan_has_six_merchants_two_per_settlement_each_with_a_home_and_the_market_as_its_work_place() -> void:
	assert_eq(_plan.total(), 138, "132 de antes mais os seis comerciantes.")
	var built: PopulationPlan.BuildResult = _build_specs()
	assert_true(built.result.ok, built.result.message)
	assert_ne(built.result.code, PopulationPlan.CODE_NO_ROOM, "Nenhum NPC_POPULATION_NO_ROOM: todos têm casa com vaga.")
	assert_eq(built.specs.size(), 138)
	assert_eq(_count_by(built.specs, false), {SETTLEMENT_A: 62, SETTLEMENT_B: 46, SETTLEMENT_C: 30} as Dictionary[String, int], "A 62, B 46 e C 30.")
	assert_eq(_count_by(built.specs, true), {SETTLEMENT_A: 2, SETTLEMENT_B: 2, SETTLEMENT_C: 2} as Dictionary[String, int], "Exatamente seis comerciantes, dois por povoado.")
	assert_eq(_routine.peek_work_place_kind(MERCHANT), Place.KIND_MARKET, "O ofício de comerciante trabalha em local do tipo mercado.")
	var residents: Dictionary[String, int] = {}
	var a_merchant_homes: Array[String] = []
	for spec: NpcSpec in built.specs:
		residents[spec.home_place_id] = int(residents.get(spec.home_place_id, 0)) + 1
		if spec.occupation_id != MERCHANT:
			continue
		var home: SettlementService.PlaceQuery = _places.peek_place(spec.home_place_id)
		assert_true(home.result.ok, "O comerciante de '%s' tem casa existente (casa '%s')." % [spec.settlement_id, spec.home_place_id])
		if home.result.ok:
			assert_eq([home.place.kind, home.place.settlement_id], [Place.KIND_HOME, spec.settlement_id], "A casa do comerciante é uma casa do próprio povoado.")
		assert_eq(spec.work_place_id, MARKETS[spec.settlement_id], "O comerciante trabalha no mercado do próprio povoado.")
		assert_eq(_places.peek_place(spec.work_place_id).place.kind, Place.KIND_MARKET)
		if spec.settlement_id == SETTLEMENT_A:
			a_merchant_homes.append(spec.home_place_id)
	assert_eq(a_merchant_homes, ["a_home_13", "a_home_13"] as Array[String], "Os dois do A são os últimos moradores e ocupam a casa nova a_home_13 (é o que torna as casas novas necessárias).")
	for home_id: String in residents:
		var resident_home: SettlementService.PlaceQuery = _places.peek_place(home_id)
		assert_true(resident_home.result.ok and residents[home_id] <= resident_home.place.capacity, "A casa '%s' existe e não passa da capacidade." % home_id)


func test_the_six_new_homes_exist_as_homes_of_capacity_five_and_the_settlements_have_the_real_home_counts() -> void:
	for home_id: String in NEW_HOMES:
		var home: SettlementService.PlaceQuery = _places.peek_place(home_id)
		assert_true(home.result.ok, "A casa nova '%s' existe." % home_id)
		assert_eq([home.place.kind, home.place.settlement_id, home.place.capacity], [Place.KIND_HOME, NEW_HOMES[home_id], NEW_HOME_CAPACITY], "'%s': casa, do povoado certo, capacidade 5." % home_id)
	var homes: Dictionary[String, int] = {}
	var seats: int = 0
	for settlement_id: String in MARKETS:
		var found: SettlementService.PlacesQuery = _places.peek_places_of_kind(settlement_id, Place.KIND_HOME)
		homes[settlement_id] = found.places.size()
		for place: Place in found.places:
			seats += place.capacity
	assert_eq(homes, {SETTLEMENT_A: 14, SETTLEMENT_B: 11, SETTLEMENT_C: 10} as Dictionary[String, int], "Casas por povoado: 14, 11 e 10.")
	assert_eq(seats, 175, "175 vagas nas casas (138 moradores).")


func test_the_two_new_homes_of_a_are_what_makes_room_for_the_merchants() -> void:
	var rng: WorldRng = WorldRng.new(WORLD_SEED)
	var before: Dictionary = rng.serialize()
	var homes_of_a: Array[String] = ["a_home_13", "a_home_14"]
	var without_both: Array[Place] = []
	for place: Place in _data.places:
		if not homes_of_a.has(place.id):
			without_both.append(place)
	var refused: PopulationPlan.BuildResult = _plan.build_specs(SettlementService.new(_data.settlements, without_both), _routine, rng)
	assert_false(refused.result.ok, "Sem as duas casas novas do A, 62 moradores para 60 vagas: o plano não fecha.")
	assert_eq(refused.result.code, PopulationPlan.CODE_NO_ROOM, "É erro de DADO (falta de vaga), não NPC sem casa.")
	assert_string_contains(refused.result.message, "'test_settlement_a'")
	assert_string_contains(refused.result.message, "nº 61")
	assert_string_contains(refused.result.message, "60 vaga")
	assert_eq(refused.specs.size(), 0, "Nenhum NPC nasce.")
	assert_eq(rng.serialize(), before, "Plano recusado não gastou nenhum sorteio.")
	assert_true(_build_specs().result.ok, "Com as duas casas novas, as 70 vagas do A comportam os 62.")
	assert_true(_build_specs(["a_home_14"] as Array[String]).result.ok, "Caso-limite: só a a_home_13 (65 vagas) já basta para os 62.")
	assert_true(_build_specs(["a_home_13"] as Array[String]).result.ok, "E só a a_home_14 também: o limite de vagas é conferido, não a casa pelo nome.")
