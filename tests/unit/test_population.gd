extends GutTest
## LW-067: a população inicial do `npc` (PopulationPlan, PopulationLoader e NpcModule.on_new_game; docs/modules/npc.md, seção 1), sem janela.
## Cobre o aceite do roadmap (contagens conferem com os dados, todos têm casa e trabalho válidos, mesma semente gera a mesma população),
## um caso de erro (falta de vaga é erro de DADO, nunca NPC sem casa) e casos-limite (a população cabe EXATAMENTE nas vagas dos dados reais).
## Usa os dados reais de data/ (população, locais e ofícios), montados à mão a partir dos arquivos para não depender do terreno.

const WORLD_SEED: int = 11
const FILE_LABEL: String = "res://data/population.json"
const ISSUE_CODE: String = "NPC_POPULATION_INVALID"
const DATA_DIR: String = "res://data"
const WORLD_DIR: String = "res://data/world"
const SETTLEMENT_A: String = "test_settlement_a"
const SETTLEMENT_B: String = "test_settlement_b"
const SETTLEMENT_C: String = "test_settlement_c"


# ---------------------------------------------------------------------------------------------------- dados reais montados à mão

func _read_rows(path: String) -> Array:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert_eq(typeof(parsed), TYPE_ARRAY, "%s deve ser uma lista." % path)
	var rows: Array = parsed if typeof(parsed) == TYPE_ARRAY else []
	return rows


## Assentamentos e locais reais (altura 0: só x e z importam aqui).
func _real_places() -> SettlementService:
	var settlements: Array[Settlement] = []
	for row: Variant in _read_rows(WORLD_DIR.path_join("settlements.json")):
		var record: Dictionary = row
		settlements.append(Settlement.new(str(record["id"]), str(record["name_key"]), Vector3(float(record["x_cm"]) / 100.0, 0.0, float(record["z_cm"]) / 100.0)))
	var places: Array[Place] = []
	for row: Variant in _read_rows(WORLD_DIR.path_join("places.json")):
		var record: Dictionary = row
		places.append(Place.new(str(record["id"]), str(record["settlement_id"]), str(record["kind"]), Vector3(float(record["x_cm"]) / 100.0, 0.0, float(record["z_cm"]) / 100.0), int(record["capacity"])))
	return SettlementService.new(settlements, places)


func _real_routine() -> RoutineTable:
	var loaded: RoutineLoader.LoadResult = RoutineLoader.load_dir(DATA_DIR)
	assert_true(loaded.result.ok, loaded.result.message)
	return loaded.table


func _real_plan() -> PopulationPlan:
	var loaded: PopulationLoader.LoadResult = PopulationLoader.load_dir(DATA_DIR)
	assert_true(loaded.result.ok, loaded.result.message)
	return loaded.plan


func _row(settlement_id: String, occupation_id: String, count: int) -> PopulationPlan.PopulationRow:
	return PopulationPlan.PopulationRow.new(settlement_id, occupation_id, count)


func _plan_of(rows: Array[PopulationPlan.PopulationRow]) -> PopulationPlan:
	return PopulationPlan.new(rows)


## Os pedidos de criação do plano real com a semente dada.
func _real_specs(world_seed: int) -> Array[NpcSpec]:
	var built: PopulationPlan.BuildResult = _real_plan().build_specs(_real_places(), _real_routine(), WorldRng.new(world_seed))
	assert_true(built.result.ok, built.result.message)
	return built.specs


## Um pedido como dados simples, para comparar populações.
func _flat(spec: NpcSpec) -> Dictionary:
	return {
		"name_key": spec.name_key, "name_number": spec.name_number, "traits": Array(spec.traits), "settlement": spec.settlement_id,
		"occupation": spec.occupation_id, "home": spec.home_place_id, "work": spec.work_place_id, "place": spec.place_id, "x": spec.x_cm, "z": spec.z_cm,
	}


func _flat_all(specs: Array[NpcSpec]) -> Array:
	var flat: Array = []
	for spec: NpcSpec in specs:
		flat.append(_flat(spec))
	return flat


# ---------------------------------------------------------------------------------------------------- o arquivo

func test_the_real_file_has_the_provisional_scale_by_settlement_and_occupation() -> void:
	var plan: PopulationPlan = _real_plan()
	assert_eq(plan.total(), 132, "Escala provisória [HIP]: 132 NPCs (DEC-040 pendente).")
	var per_settlement: Dictionary = {}
	var per_pair: Dictionary = {}
	for row: PopulationPlan.PopulationRow in plan.peek_rows():
		per_settlement[row.settlement_id] = int(per_settlement.get(row.settlement_id, 0)) + row.count
		per_pair["%s/%s" % [row.settlement_id, row.occupation_id]] = int(per_pair.get("%s/%s" % [row.settlement_id, row.occupation_id], 0)) + row.count
	assert_eq(per_settlement, {SETTLEMENT_A: 60, SETTLEMENT_B: 44, SETTLEMENT_C: 28})
	var expected: Dictionary = {
		"test_settlement_a/farmer": 24, "test_settlement_a/lumberjack": 10, "test_settlement_a/artisan": 12, "test_settlement_a/guard": 8, "test_settlement_a/innkeeper": 6,
		"test_settlement_b/farmer": 16, "test_settlement_b/lumberjack": 8, "test_settlement_b/artisan": 8, "test_settlement_b/shepherd": 4, "test_settlement_b/guard": 5, "test_settlement_b/innkeeper": 3,
		"test_settlement_c/miner": 8, "test_settlement_c/artisan": 12, "test_settlement_c/guard": 5, "test_settlement_c/innkeeper": 3,
	}
	assert_eq(per_pair, expected, "As contagens do arquivo são as do cartão ([HIP] o C e os pastores do B: LW-097d).")
	var used_places: Dictionary[String, bool] = {}
	for row: PopulationPlan.PopulationRow in plan.peek_rows():
		assert_false(row.work_place_id.is_empty(), "Toda linha real cita o local de trabalho que ocupa (DEC-167): %s/%s." % [row.settlement_id, row.occupation_id])
		assert_false(used_places.has(row.work_place_id), "Uma linha por local: '%s'." % row.work_place_id)
		used_places[row.work_place_id] = true
	assert_eq(used_places.size(), 20, "Os 20 locais de trabalho (A 7, B 8, C 5), um por linha.")


func test_rows_come_out_in_settlement_then_occupation_order_whatever_the_order_given() -> void:
	var scrambled: Array[PopulationPlan.PopulationRow] = [_row("b", "guard", 1), _row("a", "farmer", 1), _row("b", "artisan", 1), _row("a", "artisan", 1)]
	var order: Array[String] = []
	for row: PopulationPlan.PopulationRow in _plan_of(scrambled).peek_rows():
		order.append("%s/%s" % [row.settlement_id, row.occupation_id])
	var expected: Array[String] = ["a/artisan", "a/farmer", "b/artisan", "b/guard"]
	assert_eq(order, expected)


func _valid_record() -> Dictionary:
	return {"id": "pop_a_farmer", "settlement_id": SETTLEMENT_A, "occupation_id": "farmer", "count": 24}


func _load_records(records: Array[Dictionary]) -> PopulationLoader.LoadResult:
	var bundle: DataBundle = DataBundle.new()
	bundle.tables[PopulationLoader.POPULATION_TABLE] = records
	bundle.file_paths[PopulationLoader.POPULATION_TABLE] = FILE_LABEL
	DataValidator.new().validate(bundle, [PopulationLoader.build_schema()])
	return PopulationLoader.from_bundle(bundle)


func _expect_failure(label: String, records: Array[Dictionary], fragments: Array[String]) -> void:
	var loaded: PopulationLoader.LoadResult = _load_records(records)
	assert_false(loaded.result.ok, "%s: deveria falhar." % label)
	assert_eq(loaded.result.code, ISSUE_CODE, label)
	assert_null(loaded.plan, "%s: falha não devolve plano." % label)
	for fragment: String in fragments:
		assert_string_contains(loaded.result.message, fragment, "%s: a mensagem deveria citar '%s'." % [label, fragment])


func test_invalid_data_fails_pointing_at_file_item_and_field() -> void:
	for field: String in ["settlement_id", "occupation_id", "count"]:
		var missing: Dictionary = _valid_record()
		missing.erase(field)
		_expect_failure("%s ausente" % field, [missing], [FILE_LABEL, "item 'pop_a_farmer'", "campo '%s'" % field, "obrigatório ausente"])
	var none: Dictionary = _valid_record()
	none["count"] = 0
	_expect_failure("contagem zero", [none], [FILE_LABEL, "campo 'count'", "abaixo do mínimo"])
	var too_many: Dictionary = _valid_record()
	too_many["count"] = 10001
	_expect_failure("contagem acima do máximo", [too_many], [FILE_LABEL, "campo 'count'", "acima do máximo"])
	var as_text: Dictionary = _valid_record()
	as_text["count"] = "24"
	_expect_failure("contagem como texto", [as_text], [FILE_LABEL, "campo 'count'", "tipo inválido"])
	var empty_settlement: Dictionary = _valid_record()
	empty_settlement["settlement_id"] = ""
	_expect_failure("assentamento vazio", [empty_settlement], [FILE_LABEL, "campo 'settlement_id'", "não pode ficar vazio"])
	var empty_occupation: Dictionary = _valid_record()
	empty_occupation["occupation_id"] = ""
	_expect_failure("ofício vazio", [empty_occupation], [FILE_LABEL, "campo 'occupation_id'", "não pode ficar vazio"])
	var unknown: Dictionary = _valid_record()
	unknown["level"] = 3
	_expect_failure("campo desconhecido", [unknown], [FILE_LABEL, "campo 'level'", "campo desconhecido"])
	var twin: Dictionary = _valid_record()
	twin["id"] = "pop_twin"
	_expect_failure("mesmo par duas vezes", [_valid_record(), twin], [FILE_LABEL, "item 'pop_twin'", "campo 'occupation_id'", "já tem linha no assentamento 'test_settlement_a' (linha 'pop_a_farmer')"])
	_expect_failure("nenhuma linha", [], [FILE_LABEL, "esperada ao menos 1 linha"])


func test_a_missing_file_fails_pointing_at_the_file() -> void:
	var loaded: PopulationLoader.LoadResult = PopulationLoader.load_dir("res://tests/fixtures/data/ok")
	assert_false(loaded.result.ok)
	assert_eq(loaded.result.code, ISSUE_CODE)
	assert_string_contains(loaded.result.message, "population.json")
	assert_string_contains(loaded.result.message, "arquivo não encontrado")


func test_the_provisional_name_has_a_text_key_with_the_number_placeholder() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/text/pt_br.json"))
	var texts: Dictionary = parsed
	assert_true(texts.has(PopulationPlan.NAME_KEY), "A chave do nome provisório (DEC-100) existe no catálogo de textos.")
	assert_string_contains(str(texts[PopulationPlan.NAME_KEY]), "{number}")


# ---------------------------------------------------------------------------------------------------- montar os pedidos

func test_the_real_plan_builds_the_whole_population_with_valid_homes_and_work_places() -> void:
	var places: SettlementService = _real_places()
	var routine: RoutineTable = _real_routine()
	var specs: Array[NpcSpec] = _real_specs(WORLD_SEED)
	assert_eq(specs.size(), 132)
	var per_pair: Dictionary = {}
	var used: Dictionary = {}
	for index: int in specs.size():
		var spec: NpcSpec = specs[index]
		per_pair["%s/%s" % [spec.settlement_id, spec.occupation_id]] = int(per_pair.get("%s/%s" % [spec.settlement_id, spec.occupation_id], 0)) + 1
		assert_eq(spec.name_key, PopulationPlan.NAME_KEY)
		assert_eq(spec.name_number, index + 1, "Os números dos nomes são 1, 2, 3... na ordem de criação.")
		var home: SettlementService.PlaceQuery = places.peek_place(spec.home_place_id)
		assert_true(home.result.ok, "NPC %d: casa '%s' existe." % [index + 1, spec.home_place_id])
		assert_eq([home.place.kind, home.place.settlement_id], [Place.KIND_HOME, spec.settlement_id], "NPC %d: a casa é uma casa do próprio assentamento." % (index + 1))
		var work: SettlementService.PlaceQuery = places.peek_place(spec.work_place_id)
		assert_true(work.result.ok, "NPC %d: local de trabalho '%s' existe." % [index + 1, spec.work_place_id])
		assert_eq([work.place.kind, work.place.settlement_id], [routine.peek_work_place_kind(spec.occupation_id), spec.settlement_id], "NPC %d: o local de trabalho é do tipo do ofício e do próprio assentamento." % (index + 1))
		used[spec.home_place_id] = int(used.get(spec.home_place_id, 0)) + 1
		used[spec.work_place_id] = int(used.get(spec.work_place_id, 0)) + 1
		assert_eq(spec.place_id, spec.home_place_id, "O NPC nasce em casa.")
		assert_eq([spec.x_cm, spec.z_cm], [roundi(home.place.position.x * 100.0), roundi(home.place.position.z * 100.0)], "E na posição da casa.")
		assert_eq(spec.traits.size(), NpcState.TRAIT_COUNT)
		for value: int in spec.traits:
			assert_true(value >= NpcState.VALUE_MIN and value <= NpcState.VALUE_MAX, "Traço %d de 0 a 100." % value)
	for place_id: String in used:
		assert_true(int(used[place_id]) <= places.peek_place(place_id).place.capacity, "O local '%s' respeita a capacidade." % place_id)
	var plan_pairs: Dictionary = {}
	for row: PopulationPlan.PopulationRow in _real_plan().peek_rows():
		plan_pairs["%s/%s" % [row.settlement_id, row.occupation_id]] = int(plan_pairs.get("%s/%s" % [row.settlement_id, row.occupation_id], 0)) + row.count
	assert_eq(per_pair, plan_pairs, "As contagens dos pedidos são as do arquivo.")


func test_each_npc_gets_the_first_home_with_room_and_the_work_place_of_its_row() -> void:
	var specs: Array[NpcSpec] = _real_specs(WORLD_SEED)
	assert_eq(specs[0].home_place_id, "a_home_01")
	assert_eq(specs[4].home_place_id, "a_home_01", "A casa 1 tem 5 vagas.")
	assert_eq(specs[5].home_place_id, "a_home_02")
	assert_eq(specs[59].home_place_id, "a_home_12", "O último do A enche a última casa.")
	assert_eq(specs[60].home_place_id, "b_home_01", "O B recomeça nas casas dele.")
	assert_eq(specs[99].home_place_id, "b_home_08")
	assert_eq(specs[103].home_place_id, "b_home_09", "Os 44 do B passam das 8 casas de antes: a nona recebe os 4 últimos.")
	assert_eq(specs[104].home_place_id, "c_home_01", "O C recomeça nas casas dele.")
	assert_eq(specs[131].home_place_id, "c_home_06", "Os 28 do C enchem 5 casas e 3 vagas da sexta.")
	assert_eq(specs[0].work_place_id, "a_work_04", "A ordem é povoado, ofício e local: os artesãos do `a_work_04` vêm primeiro.")
	assert_eq(specs[5].work_place_id, "a_work_04")
	assert_eq(specs[6].work_place_id, "a_work_05")
	assert_eq(specs[12].work_place_id, "a_work_01", "Os lavradores do `a_work_01`, com a equipe de 12 da linha.")
	assert_eq(specs[24].work_place_id, "a_work_02")
	assert_eq(specs[59].work_place_id, "a_work_03", "O último do A é lenhador, no `a_work_03`.")
	assert_eq(specs[60].work_place_id, "b_work_04")
	assert_eq(specs[103].work_place_id, "b_work_06", "O último do B é o pastor, no `b_work_06`.")
	assert_eq(specs[104].work_place_id, "c_work_02")
	assert_eq(specs[131].work_place_id, "c_work_01", "O último do C é mineiro, no `c_work_01`.")
	var occupations: Array[String] = []
	for index: int in range(0, 60):
		if occupations.is_empty() or occupations[occupations.size() - 1] != specs[index].occupation_id:
			occupations.append(specs[index].occupation_id)
	var expected_order: Array[String] = ["artisan", "farmer", "guard", "innkeeper", "lumberjack"]
	assert_eq(occupations, expected_order, "Dentro de um assentamento, os ofícios saem em ordem alfabética.")
	assert_eq(specs[0].settlement_id, SETTLEMENT_A)
	assert_eq(specs[60].settlement_id, SETTLEMENT_B)


func test_the_same_seed_gives_the_same_population_and_another_seed_other_traits() -> void:
	var first: Array = _flat_all(_real_specs(WORLD_SEED))
	assert_eq(_flat_all(_real_specs(WORLD_SEED)), first, "Mesma semente, mesma população.")
	var other: Array = _flat_all(_real_specs(WORLD_SEED + 1))
	assert_ne(other, first, "Outra semente, outros traços.")
	for index: int in first.size():
		var one: Dictionary = first[index]
		var two: Dictionary = other[index]
		assert_eq([one["home"], one["work"], one["occupation"], one["name_number"]], [two["home"], two["work"], two["occupation"], two["name_number"]], "Casa, trabalho e ofício não dependem da semente.")
	var distinct: Dictionary = {}
	for entry: Variant in first:
		var flat: Dictionary = entry
		distinct[str(flat["traits"])] = true
	assert_gt(distinct.size(), 90, "Os traços variam de um NPC para outro (média de dois sorteios).")


func test_the_row_order_in_the_file_does_not_change_the_population() -> void:
	var rows: Array[PopulationPlan.PopulationRow] = _real_plan().peek_rows()
	var reversed_rows: Array[PopulationPlan.PopulationRow] = []
	for index: int in range(rows.size() - 1, -1, -1):
		reversed_rows.append(rows[index])
	var built: PopulationPlan.BuildResult = _plan_of(reversed_rows).build_specs(_real_places(), _real_routine(), WorldRng.new(WORLD_SEED))
	assert_true(built.result.ok, built.result.message)
	assert_eq(_flat_all(built.specs), _flat_all(_real_specs(WORLD_SEED)))


func test_a_plan_with_no_room_fails_as_a_data_error_and_spends_no_random_numbers() -> void:
	var rng: WorldRng = WorldRng.new(WORLD_SEED)
	var before: Dictionary = rng.serialize()
	var too_many: Array[PopulationPlan.PopulationRow] = [_row(SETTLEMENT_A, "farmer", 61)]
	var no_home: PopulationPlan.BuildResult = _plan_of(too_many).build_specs(_real_places(), _real_routine(), rng)
	assert_false(no_home.result.ok)
	assert_eq(no_home.result.code, PopulationPlan.CODE_NO_ROOM)
	assert_string_contains(no_home.result.message, "'test_settlement_a'")
	assert_string_contains(no_home.result.message, "nº 61")
	assert_string_contains(no_home.result.message, "60 vaga")
	assert_eq(no_home.specs.size(), 0)
	assert_eq(rng.serialize(), before, "Plano recusado não gastou nenhum sorteio.")
	# Casas de sobra, mas poucos locais de trabalho: dois locais de 1 vaga e 3 NPCs.
	var settlements: Array[Settlement] = [Settlement.new("s", "settlement.s", Vector3.ZERO)]
	var places: Array[Place] = [
		Place.new("s_home", "s", Place.KIND_HOME, Vector3(1.0, 0.0, 1.0), 5), Place.new("s_work_1", "s", Place.KIND_WORK, Vector3(2.0, 0.0, 1.0), 1),
		Place.new("s_work_2", "s", Place.KIND_WORK, Vector3(3.0, 0.0, 1.0), 1),
	]
	var small: SettlementService = SettlementService.new(settlements, places)
	var three: Array[PopulationPlan.PopulationRow] = [_row("s", "farmer", 3)]
	var no_work: PopulationPlan.BuildResult = _plan_of(three).build_specs(small, _real_routine(), rng)
	assert_eq(no_work.result.code, PopulationPlan.CODE_NO_ROOM)
	assert_string_contains(no_work.result.message, "local de trabalho 'work'")
	assert_string_contains(no_work.result.message, "2 vaga")
	var two: Array[PopulationPlan.PopulationRow] = [_row("s", "farmer", 2)]
	assert_true(_plan_of(two).build_specs(small, _real_routine(), rng).result.ok, "Caso-limite: 2 NPCs cabem exatamente nas 2 vagas.")


func test_unknown_settlement_or_occupation_fails_naming_it() -> void:
	var ghost_settlement: Array[PopulationPlan.PopulationRow] = [_row("nowhere", "farmer", 1)]
	var unknown_settlement: PopulationPlan.BuildResult = _plan_of(ghost_settlement).build_specs(_real_places(), _real_routine(), WorldRng.new(1))
	assert_eq(unknown_settlement.result.code, PopulationPlan.CODE_INVALID_REFERENCE)
	assert_string_contains(unknown_settlement.result.message, "'nowhere'")
	var ghost_occupation: Array[PopulationPlan.PopulationRow] = [_row(SETTLEMENT_A, "wizard", 1)]
	var unknown_occupation: PopulationPlan.BuildResult = _plan_of(ghost_occupation).build_specs(_real_places(), _real_routine(), WorldRng.new(1))
	assert_eq(unknown_occupation.result.code, PopulationPlan.CODE_INVALID_REFERENCE)
	assert_string_contains(unknown_occupation.result.message, "'wizard'")
	assert_string_contains(unknown_occupation.result.message, "farmer", "A mensagem lista os ofícios que existem.")


func test_the_work_place_kind_comes_from_the_occupation() -> void:
	var occupations: Array[RoutineTable.OccupationDef] = [RoutineTable.OccupationDef.new("keeper", Place.KIND_REST)]
	var blocks: Array[RoutineTable.RoutineBlock] = [RoutineTable.RoutineBlock.new("k", "keeper", 0, 24, "wait")]
	var one: Array[PopulationPlan.PopulationRow] = [_row(SETTLEMENT_A, "keeper", 1)]
	var built: PopulationPlan.BuildResult = _plan_of(one).build_specs(_real_places(), RoutineTable.new(occupations, blocks), WorldRng.new(1))
	assert_true(built.result.ok, built.result.message)
	assert_eq(built.specs[0].work_place_id, "a_rest_01", "Ofício cujo trabalho é num local de descanso vai para um local de descanso.")


# ---------------------------------------------------------------------------------------------------- no módulo

func _setup() -> NpcSetup:
	var setup: NpcSetup = NpcSetup.from_dir(DATA_DIR, _real_places())
	assert_true(setup.result.ok, setup.result.message)
	return setup


func _new_world(module: NpcModule, world_seed: int) -> World:
	var clock: SimClock = SimClock.new()
	var world: World = World.new(SimContext.new(clock, EventBus.new(clock), WorldRng.new(world_seed), IdGenerator.new()))
	assert_true(world.register_module("npc", module).ok)
	world.setup()
	world.post_setup()
	return world


func _populated_module() -> NpcModule:
	var setup: NpcSetup = _setup()
	return NpcModule.new(setup.need_defs, setup.routine, setup.definitions)


func test_a_new_game_creates_the_whole_population_in_order_and_it_is_valid() -> void:
	var module: NpcModule = _populated_module()
	var world: World = _new_world(module, WORLD_SEED)
	assert_eq(module.peek_counts()["total"], 0, "Antes do jogo novo ninguém existe.")
	world.on_new_game(WORLD_SEED)
	var counts: Dictionary = module.peek_counts()
	assert_eq([counts["total"], counts["alive"], counts["dead"]], [132, 132, 0])
	var ids: Array[int] = module.peek_npc_ids()
	assert_eq([ids[0], ids[131]], [1, 132], "IDs de 1 a 132, do contador do core.")
	var first: NpcModule.NpcQuery = module.peek_npc(1)
	assert_eq([first.name_key, first.name_number, first.occupation_id, first.settlement_id], [PopulationPlan.NAME_KEY, 1, "artisan", SETTLEMENT_A])
	assert_eq([first.home_place_id, first.work_place_id, first.place_id], ["a_home_01", "a_work_04", "a_home_01"])
	assert_eq(first.need_values[0], 20, "Nasce com os valores iniciais de data/needs.json (fome 20).")
	assert_eq(module.peek_npc(100).settlement_id, SETTLEMENT_B)
	assert_eq(module.peek_npc(105).settlement_id, SETTLEMENT_C)
	assert_eq(module.validate().size(), 0, str(module.validate()))
	assert_eq(world.validate().size(), 0, str(world.validate()))
	assert_eq(module.debug_summary()["population_problem"], "")
	assert_eq(module.debug_summary()["by_occupation"], {"artisan": 32, "farmer": 40, "guard": 18, "innkeeper": 12, "lumberjack": 18, "miner": 8, "shepherd": 4})
	world.teardown()


func test_the_same_seed_gives_the_same_world_hash_and_another_seed_a_different_one() -> void:
	var hashes: Array[String] = []
	for world_seed: int in [WORLD_SEED, WORLD_SEED, WORLD_SEED + 1]:
		var module: NpcModule = _populated_module()
		var world: World = _new_world(module, world_seed)
		world.on_new_game(world_seed)
		hashes.append(world.state_hash())
		world.teardown()
	assert_eq(hashes[0], hashes[1], "Mesma semente, mesmo hash do mundo.")
	assert_ne(hashes[0], hashes[2], "Outra semente, outro hash.")


func test_the_populated_world_survives_a_save_and_load_without_creating_anyone_again() -> void:
	var module: NpcModule = _populated_module()
	var world: World = _new_world(module, WORLD_SEED)
	world.on_new_game(WORLD_SEED)
	for _step: int in 90:
		world.context.clock.advance_step()
		world.tick(1)
	var parsed: Variant = JSON.parse_string(JSON.stringify(world.serialize(), "", true, true))
	var saved: Dictionary = parsed
	var other: NpcModule = _populated_module()
	var other_world: World = _new_world(other, WORLD_SEED)
	var loaded: Result = other_world.on_load(saved)
	assert_true(loaded.ok, loaded.message)
	assert_eq(other.peek_counts()["total"], 132, "Carregar não cria população de novo.")
	assert_eq(other_world.state_hash(), world.state_hash(), "O mundo carregado é o mesmo que foi salvo.")
	world.teardown()
	other_world.teardown()


func test_no_plan_means_nobody_is_created() -> void:
	var setup: NpcSetup = _setup()
	setup.definitions.population = null
	var module: NpcModule = NpcModule.new(setup.need_defs, setup.routine, setup.definitions)
	var world: World = _new_world(module, WORLD_SEED)
	world.on_new_game(WORLD_SEED)
	assert_eq(module.peek_counts()["total"], 0)
	assert_eq(module.debug_summary()["population_problem"], "")
	var plain: NpcModule = NpcModule.new()
	var plain_world: World = _new_world(plain, WORLD_SEED)
	plain_world.on_new_game(WORLD_SEED)
	assert_eq(plain.peek_counts()["total"], 0, "Módulo sem definições também não cria ninguém (o padrão dos outros testes).")
	world.teardown()
	plain_world.teardown()


func test_a_plan_that_does_not_fit_creates_nobody_logs_the_error_and_reports_it() -> void:
	var setup: NpcSetup = _setup()
	var too_many: Array[PopulationPlan.PopulationRow] = [_row(SETTLEMENT_A, "farmer", 61)]
	setup.definitions.population = _plan_of(too_many)
	var module: NpcModule = NpcModule.new(setup.need_defs, setup.routine, setup.definitions)
	var world: World = _new_world(module, WORLD_SEED)
	world.on_new_game(WORLD_SEED)
	assert_push_error("população inicial não criada")
	assert_eq(module.peek_counts()["total"], 0, "Nenhum NPC nasce sem casa.")
	assert_string_contains(module.debug_summary()["population_problem"], "sem casa com vaga")
	world.teardown()
