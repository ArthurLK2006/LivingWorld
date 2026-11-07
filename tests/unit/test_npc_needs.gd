extends GutTest
## LW-058: necessidades do NPC (docs/modules/npc.md, seção 2), sem janela. data/needs.json carrega pelo módulo `data` (NeedLoader); a
## conta (NeedMath) é por hora, em inteiros, exata e limitada a 0..100; os limiares mudam a urgência; dado inválido falha apontando
## arquivo, item e campo (casos montados em memória: nada é gravado em disco). Os valores esperados da conta estão ESCRITOS À MÃO a
## partir da fórmula do contrato, com taxas de teste; os números [HIP] do arquivo real NÃO são fixados aqui (só suas propriedades).

const FILE_LABEL: String = "res://data/needs.json"
const ISSUE_CODE: String = "NEED_DATA_INVALID"
const WORLD_SEED: int = 3
## Limiares de teste (atenção, urgente, crítica).
const ATTENTION: int = 40
const URGENT: int = 65
const CRITICAL: int = 90
const MINUTES_PER_HOUR: int = 60
const NEED_IDS: Array[String] = ["hunger", "rest", "safety", "income", "social"]


func _def(need_id: String, order: int, start_value: int, rate: int, attention: int = ATTENTION, urgent: int = URGENT, critical: int = CRITICAL) -> NeedDef:
	return NeedDef.new(need_id, order, start_value, rate, attention, urgent, critical)


## Cinco definições com as taxas dadas (uma por posição) e os mesmos limiares de teste.
func _defs(rates: Array[int], start_value: int = 0) -> Array[NeedDef]:
	var defs: Array[NeedDef] = []
	for position: int in rates.size():
		defs.append(_def(NEED_IDS[position], position, start_value, rates[position]))
	return defs


func _state(values: Array[int], updated_at: int = 0) -> NpcState:
	var state: NpcState = NpcState.new(1)
	state.need_values = PackedInt64Array(values)
	state.needs_updated_at = updated_at
	return state


func _record(need_id: String, order: int) -> Dictionary:
	return {"id": need_id, "order": order, "start_value": 20, "rate_per_hour": 5, "attention": 40, "urgent": 65, "critical": 90}


func _valid_records() -> Array[Dictionary]:
	var records: Array[Dictionary] = []
	for position: int in NEED_IDS.size():
		records.append(_record(NEED_IDS[position], position))
	return records


## Mesmo caminho do carregador de arquivo: o `data` valida o pacote e o NeedLoader confere o resto e monta.
func _load_records(records: Array[Dictionary]) -> NeedLoader.LoadResult:
	var bundle: DataBundle = DataBundle.new()
	bundle.tables[NeedLoader.NEEDS_TABLE] = records
	bundle.file_paths[NeedLoader.NEEDS_TABLE] = FILE_LABEL
	DataValidator.new().validate(bundle, [NeedLoader.build_schema()])
	return NeedLoader.from_bundle(bundle)


func _new_world(module: NpcModule) -> World:
	var clock: SimClock = SimClock.new()
	var world: World = World.new(SimContext.new(clock, EventBus.new(clock), WorldRng.new(WORLD_SEED), IdGenerator.new()))
	assert_true(world.register_module("npc", module).ok)
	world.setup()
	return world


func _basic_spec() -> NpcSpec:
	var spec: NpcSpec = NpcSpec.new()
	spec.name_key = "npc.name.villager"
	return spec


# ---------------------------------------------------------------------------------------------------- dados reais

func test_the_real_file_loads_five_needs_in_order_with_sane_values() -> void:
	var loaded: NeedLoader.LoadResult = NeedLoader.load_dir()
	assert_true(loaded.result.ok, loaded.result.message)
	assert_eq(loaded.needs.size(), 5)
	assert_eq(loaded.needs.size(), NpcState.NEED_COUNT, "Uma linha por posição do estado.")
	for position: int in NEED_IDS.size():
		var def: NeedDef = loaded.needs[position]
		assert_eq(def.id, NEED_IDS[position], "Necessidade na posição %d." % position)
		assert_eq(def.order, position)
		assert_true(def.start_value >= 0 and def.start_value <= 100, "%s: valor inicial dentro de 0 a 100." % def.id)
		assert_true(absi(def.rate_per_hour) <= NeedLoader.MAX_RATE_PER_HOUR, "%s: taxa dentro da faixa." % def.id)
		assert_true(def.attention >= 0 and def.attention < def.urgent and def.urgent < def.critical and def.critical <= 100, "%s: limiares crescentes dentro de 0 a 100." % def.id)
	assert_gt(loaded.needs[0].rate_per_hour, 0, "A fome sobe com o tempo.")
	assert_lt(loaded.needs[2].rate_per_hour, 0, "A pressão de segurança desce devagar (taxa negativa).")


func test_loading_twice_gives_the_same_result() -> void:
	var first: NeedLoader.LoadResult = NeedLoader.load_dir()
	var second: NeedLoader.LoadResult = NeedLoader.load_dir()
	assert_eq(first.needs.size(), second.needs.size())
	for position: int in first.needs.size():
		assert_eq(first.needs[position].id, second.needs[position].id)
		assert_eq(first.needs[position].rate_per_hour, second.needs[position].rate_per_hour)
		assert_eq(first.needs[position].critical, second.needs[position].critical)


func test_records_out_of_file_order_are_returned_by_position() -> void:
	var shuffled: Array[Dictionary] = _valid_records()
	shuffled.reverse()
	var loaded: NeedLoader.LoadResult = _load_records(shuffled)
	assert_true(loaded.result.ok, loaded.result.message)
	assert_eq(loaded.needs[0].id, "hunger")
	assert_eq(loaded.needs[4].id, "social")


func test_the_real_needs_work_with_the_module_and_the_world_validates() -> void:
	var loaded: NeedLoader.LoadResult = NeedLoader.load_dir()
	assert_true(loaded.result.ok, loaded.result.message)
	var module: NpcModule = NpcModule.new(loaded.needs)
	var world: World = _new_world(module)
	var created: NpcModule.CreateResult = module.request_create_npc(_basic_spec())
	assert_true(created.result.ok, created.result.message)
	var query: NpcModule.NpcQuery = module.peek_npc(created.npc_id)
	for position: int in loaded.needs.size():
		assert_eq(query.need_values[position], loaded.needs[position].start_value, "Valor inicial de %s vem dos dados." % loaded.needs[position].id)
		assert_eq(query.need_urgencies[position], NeedMath.urgency(loaded.needs[position].start_value, loaded.needs[position]))
	assert_eq(world.validate().size(), 0, str(world.validate()))
	world.teardown()


# ---------------------------------------------------------------------------------------------------- urgência

func test_urgency_changes_exactly_at_the_thresholds() -> void:
	var def: NeedDef = _def("hunger", 0, 0, 5)
	var expected_by_value: Dictionary = {
		0: 0, ATTENTION - 1: 0, ATTENTION: 1, URGENT - 1: 1, URGENT: 2, CRITICAL - 1: 2, CRITICAL: 3, 100: 3,
	}
	for value: int in expected_by_value:
		assert_eq(NeedMath.urgency(value, def), expected_by_value[value], "Valor %d." % value)


func test_other_thresholds_change_the_urgency_of_the_same_value() -> void:
	var strict: NeedDef = _def("hunger", 0, 0, 5, 10, 20, 30)
	var relaxed: NeedDef = _def("hunger", 0, 0, 5, 60, 80, 95)
	assert_eq(NeedMath.urgency(50, strict), NeedMath.URGENCY_CRITICAL)
	assert_eq(NeedMath.urgency(50, relaxed), NeedMath.URGENCY_COMFORTABLE)
	assert_eq(NeedMath.urgency(60, relaxed), NeedMath.URGENCY_ATTENTION)


# ---------------------------------------------------------------------------------------------------- variação por hora

func test_the_rate_per_hour_gives_the_hand_calculated_points() -> void:
	var one_hour: NeedMath.Advanced = NeedMath.advance(10, 0, 5, MINUTES_PER_HOUR)
	assert_eq(one_hour.value, 15, "5 pontos por hora, 1 hora.")
	assert_eq(one_hour.remainder, 0)
	var ten_hours: NeedMath.Advanced = NeedMath.advance(0, 0, 5, 10 * MINUTES_PER_HOUR)
	assert_eq(ten_hours.value, 50)
	var slow: NeedMath.Advanced = NeedMath.advance(0, 0, 6, 10 * MINUTES_PER_HOUR)
	assert_eq(slow.value, 60, "6 por hora = 0,1 por minuto: 600 minutos dão 60.")


func test_the_remainder_carries_the_fraction_between_calls() -> void:
	var first: NeedMath.Advanced = NeedMath.advance(20, 0, 5, 7)
	assert_eq(first.value, 20, "7 minutos a 5 por hora: 35/60, ainda nenhum ponto.")
	assert_eq(first.remainder, 35)
	var second: NeedMath.Advanced = NeedMath.advance(first.value, first.remainder, 5, 5)
	assert_eq(second.value, 21, "Mais 5 minutos: 25 + 35 = 60 = 1 ponto.")
	assert_eq(second.remainder, 0)


func test_a_negative_rate_rounds_down_and_the_remainder_compensates() -> void:
	var first: NeedMath.Advanced = NeedMath.advance(50, 0, -6, 1)
	assert_eq(first.value, 49, "Taxa negativa: o piso de -6/60 é -1.")
	assert_eq(first.remainder, 54)
	var rest: NeedMath.Advanced = NeedMath.advance(first.value, first.remainder, -6, 9)
	assert_eq(rest.value, 49, "-54 + 54 = 0: nenhum ponto a mais; no total 10 minutos tiraram 1 ponto.")
	assert_eq(rest.remainder, 0)
	var at_once: NeedMath.Advanced = NeedMath.advance(50, 0, -6, 10)
	assert_eq(at_once.value, 49)
	assert_eq(at_once.remainder, 0)


func test_values_are_clamped_to_0_and_100() -> void:
	var up: NeedMath.Advanced = NeedMath.advance(99, 0, 60, 5)
	assert_eq(up.value, 100)
	var down: NeedMath.Advanced = NeedMath.advance(1, 0, -60, 5)
	assert_eq(down.value, 0)
	var already_full: NeedMath.Advanced = NeedMath.advance(100, 0, 100, 600)
	assert_eq(already_full.value, 100)
	assert_true(already_full.remainder >= 0 and already_full.remainder <= NeedMath.MAX_REMAINDER)


func test_settle_updates_every_need_and_the_update_minute() -> void:
	var defs: Array[NeedDef] = _defs([6, 12, -6, 0, 30])
	var state: NpcState = _state([10, 10, 50, 10, 10], 100)
	var settled: Result = NeedMath.settle(state, defs, 220)
	assert_true(settled.ok, settled.message)
	assert_eq(state.need_values, PackedInt64Array([22, 34, 38, 10, 70]), "2 horas: +12, +24, -12, 0 e +60.")
	assert_eq(state.need_remainders, PackedInt64Array([0, 0, 0, 0, 0]))
	assert_eq(state.needs_updated_at, 220)


func test_splitting_the_interval_gives_exactly_the_same_result() -> void:
	var rates: Array[int] = [-100, -37, -6, -1, 0, 1, 5, 7, 59, 60, 61, 100]
	var starts: Array[int] = [0, 1, 50, 99, 100]
	var step_sizes: Array[int] = [1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144]
	var total_minutes: int = 1000
	for rate: int in rates:
		var defs: Array[NeedDef] = _defs([rate, rate, rate, rate, rate])
		var at_once: NpcState = _state(starts)
		assert_true(NeedMath.settle(at_once, defs, total_minutes).ok)
		var in_pieces: NpcState = _state(starts)
		var now: int = 0
		var index: int = 0
		while now < total_minutes:
			now = mini(now + step_sizes[index % step_sizes.size()], total_minutes)
			assert_true(NeedMath.settle(in_pieces, defs, now).ok)
			index += 1
		assert_eq(in_pieces.need_values, at_once.need_values, "Valores com taxa %d." % rate)
		assert_eq(in_pieces.need_remainders, at_once.need_remainders, "Restos com taxa %d." % rate)


func test_values_stay_inside_the_range_and_remainders_below_60_over_a_long_sweep() -> void:
	var defs: Array[NeedDef] = _defs([-100, -7, 3, 59, 100])
	var state: NpcState = _state([100, 0, 50, 99, 1])
	for minute: int in range(1, 3000):
		assert_true(NeedMath.settle(state, defs, minute * 7).ok)
		for position: int in 5:
			assert_true(state.need_values[position] >= 0 and state.need_values[position] <= 100, "Minuto %d, posição %d: valor %d." % [minute * 7, position, state.need_values[position]])
			assert_true(state.need_remainders[position] >= 0 and state.need_remainders[position] <= NeedMath.MAX_REMAINDER)


func test_no_elapsed_time_changes_nothing() -> void:
	var state: NpcState = _state([10, 20, 30, 40, 50], 500)
	assert_true(NeedMath.settle(state, _defs([5, 5, 5, 5, 5]), 500).ok)
	assert_eq(state.need_values, PackedInt64Array([10, 20, 30, 40, 50]))
	assert_eq(state.need_remainders, PackedInt64Array([0, 0, 0, 0, 0]))
	assert_eq(state.needs_updated_at, 500)


func test_settle_refuses_time_going_back_and_bad_definitions_without_changing_the_state() -> void:
	var state: NpcState = _state([10, 20, 30, 40, 50], 500)
	var back: Result = NeedMath.settle(state, _defs([5, 5, 5, 5, 5]), 499)
	assert_false(back.ok)
	assert_eq(back.code, NeedMath.CODE_TIME_WENT_BACK)
	assert_string_contains(back.message, "NPC 1")
	var four: Array[NeedDef] = _defs([5, 5, 5, 5])
	var misordered: Array[NeedDef] = _defs([5, 5, 5, 5, 5])
	misordered.reverse()
	for bad_defs: Array[NeedDef] in [[] as Array[NeedDef], four, misordered]:
		var refused: Result = NeedMath.settle(state, bad_defs, 600)
		assert_false(refused.ok)
		assert_eq(refused.code, NeedMath.CODE_NO_DEFINITIONS)
	assert_eq(state.need_values, PackedInt64Array([10, 20, 30, 40, 50]))
	assert_eq(state.needs_updated_at, 500)


# ---------------------------------------------------------------------------------------------------- módulo

func test_a_module_with_definitions_starts_npcs_at_the_start_values_with_their_urgency() -> void:
	var defs: Array[NeedDef] = [_def("hunger", 0, 0, 5), _def("rest", 1, ATTENTION, 4), _def("safety", 2, URGENT, -5), _def("income", 3, CRITICAL, 2), _def("social", 4, 100, 2)]
	var module: NpcModule = NpcModule.new(defs)
	var world: World = _new_world(module)
	var created: NpcModule.CreateResult = module.request_create_npc(_basic_spec())
	assert_true(created.result.ok, created.result.message)
	var query: NpcModule.NpcQuery = module.peek_npc(created.npc_id)
	assert_eq(query.need_values, PackedInt64Array([0, ATTENTION, URGENT, CRITICAL, 100]))
	assert_eq(query.need_urgencies, PackedInt64Array([0, 1, 2, 3, 3]))
	assert_eq(world.validate().size(), 0, str(world.validate()))
	world.teardown()


func test_the_data_thresholds_decide_the_urgency_of_a_loaded_npc() -> void:
	var entry: Dictionary = {
		"name_key": "npc.name.villager", "name_number": 1, "tier": 1, "is_alive": true, "death_cause": "", "died_at": -1,
		"traits": [50, 50, 50, 50], "need_values": [50, 50, 50, 50, 50], "need_remainders": [0, 0, 0, 0, 0], "needs_updated_at": 0,
		"x_cm": 0, "z_cm": 0, "settlement_id": "", "place_id": "", "occupation_id": "", "home_place_id": "", "work_place_id": "",
		"action_id": "", "action_target_place_id": "", "action_started_at": 0, "action_ends_at": 0, "action_serial": 0,
	}
	var strict_module: NpcModule = NpcModule.new(_defs_with_thresholds(10, 20, 30))
	var relaxed_module: NpcModule = NpcModule.new(_defs_with_thresholds(60, 80, 95))
	for module: NpcModule in [strict_module, relaxed_module]:
		assert_true(module.on_load({"npcs": {"5": entry}}).ok)
	assert_eq(strict_module.peek_npc(5).need_urgencies, PackedInt64Array([3, 3, 3, 3, 3]), "Valor 50 com limiares 10/20/30.")
	assert_eq(relaxed_module.peek_npc(5).need_urgencies, PackedInt64Array([0, 0, 0, 0, 0]), "O mesmo valor com limiares 60/80/95.")


func _defs_with_thresholds(attention: int, urgent: int, critical: int) -> Array[NeedDef]:
	var defs: Array[NeedDef] = []
	for position: int in NEED_IDS.size():
		defs.append(_def(NEED_IDS[position], position, 0, 5, attention, urgent, critical))
	return defs


func test_a_module_without_definitions_still_works_with_zero_urgency() -> void:
	var module: NpcModule = NpcModule.new()
	var world: World = _new_world(module)
	var created: NpcModule.CreateResult = module.request_create_npc(_basic_spec())
	assert_true(created.result.ok, created.result.message)
	var query: NpcModule.NpcQuery = module.peek_npc(created.npc_id)
	assert_eq(query.need_values, PackedInt64Array([0, 0, 0, 0, 0]))
	assert_eq(query.need_urgencies, PackedInt64Array([0, 0, 0, 0, 0]))
	assert_eq(module.validate().size(), 0)
	world.teardown()


func test_a_module_with_bad_definitions_refuses_creation_without_spending_an_id() -> void:
	var misordered: Array[NeedDef] = _defs([5, 5, 5, 5, 5])
	misordered.reverse()
	for bad_defs: Array[NeedDef] in [_defs([5, 5, 5, 5]), misordered]:
		var module: NpcModule = NpcModule.new(bad_defs)
		var world: World = _new_world(module)
		var counter_before: int = world.context.ids.debug_summary()["next_id"]
		var created: NpcModule.CreateResult = module.request_create_npc(_basic_spec())
		assert_false(created.result.ok)
		assert_eq(created.result.code, NpcModule.CODE_NOT_READY)
		assert_string_contains(created.result.message, "definições de necessidades inválidas")
		assert_eq(world.context.ids.debug_summary()["next_id"], counter_before, "Recusa não gasta ID.")
		assert_eq(module.validate().size(), 1)
		assert_string_contains(module.validate()[0], "Definições de necessidades inválidas")
		world.teardown()


func test_validate_reports_a_remainder_outside_0_to_59() -> void:
	var module: NpcModule = NpcModule.new()
	var world: World = _new_world(module)
	var entry: Dictionary = {
		"name_key": "npc.name.villager", "name_number": 1, "tier": 1, "is_alive": true, "death_cause": "", "died_at": -1,
		"traits": [50, 50, 50, 50], "need_values": [0, 0, 0, 0, 0], "need_remainders": [0, 60, 0, -1, 59], "needs_updated_at": 0,
		"x_cm": 0, "z_cm": 0, "settlement_id": "", "place_id": "", "occupation_id": "", "home_place_id": "", "work_place_id": "",
		"action_id": "", "action_target_place_id": "", "action_started_at": 0, "action_ends_at": 0, "action_serial": 0,
	}
	world.context.ids.next_id()
	assert_true(module.on_load({"npcs": {"1": entry}}).ok)
	var problems: Array[String] = module.validate()
	assert_eq(problems.size(), 2, str(problems))
	assert_string_contains("\n".join(problems), "NPC 1: resto de necessidade na posição 1 fora de 0 a 59 (valor 60)")
	assert_string_contains("\n".join(problems), "NPC 1: resto de necessidade na posição 3 fora de 0 a 59 (valor -1)")
	world.teardown()


# ---------------------------------------------------------------------------------------------------- dado inválido

func test_invalid_tables_fail_pointing_at_file_item_and_field() -> void:
	var cases: Array[Dictionary] = []
	for field: String in ["order", "start_value", "rate_per_hour", "attention", "urgent", "critical"]:
		var missing: Array[Dictionary] = _valid_records()
		missing[2].erase(field)
		cases.append({"label": "%s ausente" % field, "records": missing, "expect": [FILE_LABEL, "item 'safety'", "campo '%s'" % field, "obrigatório ausente"]})
	var start_high: Array[Dictionary] = _valid_records()
	start_high[0]["start_value"] = 101
	cases.append({"label": "valor inicial acima de 100", "records": start_high, "expect": [FILE_LABEL, "item 'hunger'", "campo 'start_value'", "acima do máximo"]})
	var start_low: Array[Dictionary] = _valid_records()
	start_low[0]["start_value"] = -1
	cases.append({"label": "valor inicial negativo", "records": start_low, "expect": [FILE_LABEL, "item 'hunger'", "campo 'start_value'", "abaixo do mínimo"]})
	var rate_high: Array[Dictionary] = _valid_records()
	rate_high[1]["rate_per_hour"] = 101
	cases.append({"label": "taxa acima da faixa", "records": rate_high, "expect": [FILE_LABEL, "item 'rest'", "campo 'rate_per_hour'", "acima do máximo"]})
	var rate_low: Array[Dictionary] = _valid_records()
	rate_low[1]["rate_per_hour"] = -101
	cases.append({"label": "taxa abaixo da faixa", "records": rate_low, "expect": [FILE_LABEL, "item 'rest'", "campo 'rate_per_hour'", "abaixo do mínimo"]})
	var critical_high: Array[Dictionary] = _valid_records()
	critical_high[3]["critical"] = 101
	cases.append({"label": "limiar crítico acima de 100", "records": critical_high, "expect": [FILE_LABEL, "item 'income'", "campo 'critical'", "acima do máximo"]})
	var attention_low: Array[Dictionary] = _valid_records()
	attention_low[3]["attention"] = -1
	cases.append({"label": "limiar de atenção negativo", "records": attention_low, "expect": [FILE_LABEL, "item 'income'", "campo 'attention'", "abaixo do mínimo"]})
	var equal_low: Array[Dictionary] = _valid_records()
	equal_low[4]["urgent"] = 40
	cases.append({"label": "urgente igual à atenção", "records": equal_low, "expect": [FILE_LABEL, "item 'social'", "campo 'urgent'", "limiares precisam crescer", "urgent 40 não é maior que attention 40"]})
	var decreasing: Array[Dictionary] = _valid_records()
	decreasing[4]["attention"] = 70
	cases.append({"label": "atenção acima da urgente", "records": decreasing, "expect": [FILE_LABEL, "item 'social'", "campo 'urgent'", "urgent 65 não é maior que attention 70"]})
	var equal_high: Array[Dictionary] = _valid_records()
	equal_high[0]["critical"] = 65
	cases.append({"label": "crítico igual ao urgente", "records": equal_high, "expect": [FILE_LABEL, "item 'hunger'", "campo 'critical'", "critical 65 não é maior que urgent 65"]})
	var repeated_order: Array[Dictionary] = _valid_records()
	repeated_order[3]["order"] = 2
	cases.append({"label": "order repetida", "records": repeated_order, "expect": [FILE_LABEL, "item 'income'", "campo 'order'", "já usada pela necessidade 'safety'"]})
	var order_too_high: Array[Dictionary] = _valid_records()
	order_too_high[4]["order"] = 5
	cases.append({"label": "order acima da faixa", "records": order_too_high, "expect": [FILE_LABEL, "item 'social'", "campo 'order'", "acima do máximo"]})
	var fraction: Array[Dictionary] = _valid_records()
	fraction[0]["rate_per_hour"] = 1.5
	cases.append({"label": "taxa com fração", "records": fraction, "expect": [FILE_LABEL, "item 'hunger'", "campo 'rate_per_hour'", "tipo inválido"]})
	var as_text: Array[Dictionary] = _valid_records()
	as_text[2]["attention"] = "30"
	cases.append({"label": "limiar como texto", "records": as_text, "expect": [FILE_LABEL, "item 'safety'", "campo 'attention'", "tipo inválido"]})
	var repeated_id: Array[Dictionary] = _valid_records()
	repeated_id[1]["id"] = "hunger"
	cases.append({"label": "id repetido", "records": repeated_id, "expect": [FILE_LABEL, "item 'hunger'", "campo 'id'", "id duplicado"]})
	var unknown_field: Array[Dictionary] = _valid_records()
	unknown_field[0]["weight_urgent"] = 3
	cases.append({"label": "campo desconhecido", "records": unknown_field, "expect": [FILE_LABEL, "item 'hunger'", "campo 'weight_urgent'", "campo desconhecido"]})
	var too_few: Array[Dictionary] = _valid_records()
	too_few.pop_back()
	cases.append({"label": "quatro necessidades", "records": too_few, "expect": [FILE_LABEL, "esperado 5 necessidades", "encontradas 4"]})
	var too_many: Array[Dictionary] = _valid_records()
	too_many.append(_record("thirst", 0))
	cases.append({"label": "seis necessidades", "records": too_many, "expect": [FILE_LABEL, "esperado 5 necessidades", "encontradas 6", "item 'thirst'", "campo 'order'"]})
	for test_case: Dictionary in cases:
		var records: Array[Dictionary] = []
		records.assign(test_case["records"])
		var loaded: NeedLoader.LoadResult = _load_records(records)
		assert_false(loaded.result.ok, "%s: deveria falhar." % test_case["label"])
		assert_eq(loaded.result.code, ISSUE_CODE, test_case["label"])
		assert_eq(loaded.needs.size(), 0, "Falha não devolve necessidades.")
		for fragment: String in test_case["expect"]:
			assert_string_contains(loaded.result.message, fragment, "%s: a mensagem deveria citar '%s'." % [test_case["label"], fragment])


func test_a_valid_in_memory_table_passes() -> void:
	var loaded: NeedLoader.LoadResult = _load_records(_valid_records())
	assert_true(loaded.result.ok, loaded.result.message)
	assert_eq(loaded.needs.size(), 5)


func test_a_missing_file_fails_pointing_at_the_file() -> void:
	var loaded: NeedLoader.LoadResult = NeedLoader.load_dir("res://tests/fixtures/data/ok")
	assert_false(loaded.result.ok)
	assert_eq(loaded.result.code, ISSUE_CODE)
	assert_string_contains(loaded.result.message, "needs.json")
	assert_string_contains(loaded.result.message, "arquivo não encontrado")
