extends GutTest
## LW-097d: a coluna OPCIONAL `work_place_id` de data/population.json (DEC-167; docs/modules/npc.md, Q23): uma linha com `count` ocupa aquele
## local de trabalho; falta de vaga segue `NPC_POPULATION_NO_ROOM`; sem a coluna vale o comportamento de antes (primeiro local com vaga). Aqui o
## carregador (arquivo inválido aponta arquivo, item e campo) e o plano (local de outro povoado, desconhecido ou de outro tipo é referência
## inválida; linhas com e sem a coluna dividem os locais sem passar da capacidade). Os dados reais estão em tests/unit/test_population.gd.

const WORLD_SEED: int = 11
const DATA_DIR: String = "res://data"
const TOWN: String = "s"
const OTHER_TOWN: String = "t"

var _temp_dirs: Array[DirAccess] = []


func after_each() -> void:
	for dir: DirAccess in _temp_dirs:
		for file_name: String in dir.get_files():
			dir.remove(file_name)
		DirAccess.remove_absolute(dir.get_current_dir())
	_temp_dirs.clear()


## Dois povoados mínimos: `s` com duas casas, dois locais de trabalho de capacidade 4 e um de descanso; `t` com uma casa e um local de trabalho.
func _places() -> SettlementService:
	var settlements: Array[Settlement] = [Settlement.new(TOWN, "k.s", Vector3.ZERO), Settlement.new(OTHER_TOWN, "k.t", Vector3(500.0, 0.0, 0.0))]
	var places: Array[Place] = []
	for entry: Array in [["s_home_1", TOWN, Place.KIND_HOME, 5], ["s_home_2", TOWN, Place.KIND_HOME, 5], ["s_work_1", TOWN, Place.KIND_WORK, 4], ["s_work_2", TOWN, Place.KIND_WORK, 4], ["s_rest_1", TOWN, Place.KIND_REST, 4], ["t_home_1", OTHER_TOWN, Place.KIND_HOME, 5], ["t_work_1", OTHER_TOWN, Place.KIND_WORK, 4]]:
		places.append(Place.new(entry[0], entry[1], entry[2], Vector3(float(places.size()), 0.0, 0.0), entry[3]))
	return SettlementService.new(settlements, places)


func _routine() -> RoutineTable:
	var loaded: RoutineLoader.LoadResult = RoutineLoader.load_dir(DATA_DIR)
	assert_true(loaded.result.ok, loaded.result.message)
	return loaded.table


func _row(occupation_id: String, count: int, work_place_id: String = "", settlement_id: String = TOWN) -> PopulationPlan.PopulationRow:
	return PopulationPlan.PopulationRow.new(settlement_id, occupation_id, count, work_place_id)


func _build(rows: Array[PopulationPlan.PopulationRow]) -> PopulationPlan.BuildResult:
	return PopulationPlan.new(rows).build_specs(_places(), _routine(), WorldRng.new(WORLD_SEED))


func _works_of(specs: Array[NpcSpec]) -> Array[String]:
	var works: Array[String] = []
	for spec: NpcSpec in specs:
		works.append(spec.work_place_id)
	return works


func _load(text: String) -> PopulationLoader.LoadResult:
	var dir: DirAccess = DirAccess.create_temp("lw097d")
	_temp_dirs.append(dir)
	var file: FileAccess = FileAccess.open(dir.get_current_dir().path_join(PopulationLoader.DEFAULT_FILE), FileAccess.WRITE)
	file.store_string(text)
	file.close()
	return PopulationLoader.load_dir(dir.get_current_dir())


# ---------------------------------------------------------------- o plano

func test_a_row_with_a_work_place_puts_everyone_of_the_row_there_not_in_the_first_place_with_room() -> void:
	var built: PopulationPlan.BuildResult = _build([_row("farmer", 3, "s_work_2")])
	assert_true(built.result.ok, built.result.message)
	assert_eq(_works_of(built.specs), ["s_work_2", "s_work_2", "s_work_2"] as Array[String])


func test_two_rows_of_the_same_occupation_can_use_two_places_in_place_order() -> void:
	var built: PopulationPlan.BuildResult = _build([_row("farmer", 3, "s_work_2"), _row("farmer", 4, "s_work_1")])
	assert_true(built.result.ok, built.result.message)
	assert_eq(_works_of(built.specs), ["s_work_1", "s_work_1", "s_work_1", "s_work_1", "s_work_2", "s_work_2", "s_work_2"] as Array[String], "A ordem é povoado, ofício e local, qualquer que seja a ordem dada.")


func test_a_row_that_does_not_fit_its_place_is_a_data_error_with_no_room_and_nothing_drawn() -> void:
	var rng: WorldRng = WorldRng.new(WORLD_SEED)
	var before: Dictionary = rng.serialize()
	var built: PopulationPlan.BuildResult = PopulationPlan.new([_row("farmer", 5, "s_work_1")]).build_specs(_places(), _routine(), rng)
	assert_false(built.result.ok)
	assert_eq(built.result.code, PopulationPlan.CODE_NO_ROOM)
	assert_string_contains(built.result.message, "s_work_1")
	assert_eq(rng.serialize(), before, "Erro de dado acontece antes de gastar sorteio.")


func test_a_place_of_another_settlement_an_unknown_one_or_of_the_wrong_kind_is_an_invalid_reference() -> void:
	for bad_place: String in ["t_work_1", "nowhere", "s_home_1"]:
		var built: PopulationPlan.BuildResult = _build([_row("farmer", 1, bad_place)])
		assert_false(built.result.ok, "Deveria recusar o local '%s'." % bad_place)
		assert_eq(built.result.code, PopulationPlan.CODE_INVALID_REFERENCE)
		assert_string_contains(built.result.message, bad_place)


func test_rows_with_and_without_a_place_share_the_work_places_without_passing_the_capacity() -> void:
	var built: PopulationPlan.BuildResult = _build([_row("guard", 3, "s_work_1"), _row("farmer", 4)])
	assert_true(built.result.ok, built.result.message)
	var per_place: Dictionary = {}
	for spec: NpcSpec in built.specs:
		per_place[spec.work_place_id] = int(per_place.get(spec.work_place_id, 0)) + 1
	assert_eq(per_place, {"s_work_1": 4, "s_work_2": 3}, "Os 3 guardas ficam no s_work_1; os lavradores sem coluna usam a vaga que sobra e depois o s_work_2.")


func test_the_same_places_in_a_different_order_give_the_same_population() -> void:
	var first: PopulationPlan.BuildResult = _build([_row("farmer", 2, "s_work_1"), _row("guard", 2, "s_work_2")])
	var second: PopulationPlan.BuildResult = _build([_row("guard", 2, "s_work_2"), _row("farmer", 2, "s_work_1")])
	assert_eq(_works_of(first.specs), _works_of(second.specs))
	assert_eq(first.specs[0].traits, second.specs[0].traits, "Mesma semente, mesmos traços.")


# ---------------------------------------------------------------- o arquivo

func test_the_loader_accepts_the_optional_column_and_keeps_rows_without_it() -> void:
	var loaded: PopulationLoader.LoadResult = _load('[{"id": "p1", "settlement_id": "s", "occupation_id": "farmer", "count": 2, "work_place_id": "s_work_1"}, {"id": "p2", "settlement_id": "s", "occupation_id": "guard", "count": 1}]')
	assert_true(loaded.result.ok, loaded.result.message)
	var rows: Array[PopulationPlan.PopulationRow] = loaded.plan.peek_rows()
	assert_eq([rows[0].occupation_id, rows[0].work_place_id, rows[1].occupation_id, rows[1].work_place_id], ["farmer", "s_work_1", "guard", ""], "Sem a coluna, o local fica vazio e vale o comportamento de antes.")


func test_an_empty_work_place_id_is_reported_with_file_item_and_field() -> void:
	var loaded: PopulationLoader.LoadResult = _load('[{"id": "p1", "settlement_id": "s", "occupation_id": "farmer", "count": 2, "work_place_id": ""}]')
	assert_false(loaded.result.ok)
	assert_eq(loaded.result.code, PopulationLoader.CODE_INVALID)
	for part: String in ["population.json", "p1", "work_place_id", "omitir a coluna"]:
		assert_string_contains(loaded.result.message, part)


func test_the_same_pair_may_repeat_with_different_places_but_not_with_the_same_place_or_without_any() -> void:
	var two_places: String = '[{"id": "p1", "settlement_id": "s", "occupation_id": "farmer", "count": 2, "work_place_id": "s_work_1"}, {"id": "p2", "settlement_id": "s", "occupation_id": "farmer", "count": 2, "work_place_id": "s_work_2"}]'
	assert_true(_load(two_places).result.ok, "Dois locais, duas linhas.")
	var same_place: PopulationLoader.LoadResult = _load(two_places.replace('"s_work_2"', '"s_work_1"'))
	assert_false(same_place.result.ok)
	assert_string_contains(same_place.result.message, "p2")
	var no_place_twice: PopulationLoader.LoadResult = _load('[{"id": "p1", "settlement_id": "s", "occupation_id": "farmer", "count": 2}, {"id": "p2", "settlement_id": "s", "occupation_id": "farmer", "count": 2}]')
	assert_false(no_place_twice.result.ok, "Sem a coluna continua uma linha por par.")
