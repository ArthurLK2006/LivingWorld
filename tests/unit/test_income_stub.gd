extends GutTest
## TEMP-LW-066: a renda simbólica de quem trabalha (IncomeStub; docs/modules/npc.md, seção 9), sem janela. SAI NA LW-095, junto com o stub, e
## este teste com ele. Sem dinheiro, preço, Ledger ou mercado. Mundo de teste montado à mão, com números fáceis de conferir: o agricultor tira
## 30 pontos de renda por trabalho completo e o lenhador 12; o guarda não está na tabela. Cobre: trabalhar alivia a renda; sem trabalhar ela
## cresce pela taxa da própria necessidade; proporcional ao progresso se o trabalho for interrompido; só `work` e só ofício da tabela; nunca
## abaixo de 0; efeito extra numa necessidade inexistente é recusado sem aplicar nada; dado do arquivo (válido e inválido, marca em cada
## linha); referências do módulo; e a marca TEMP-LW-066 em cada arquivo do provisório.

const VILLAGE: String = "village_a"
const HOME: String = "home_a"
const WORK: String = "work_a"
const NEED_IDS: Array[String] = ["hunger", "rest", "safety", "income", "social"]
const TRAIT_IDS: Array[String] = ["caution", "sociability", "ambition", "loyalty"]
const REST: int = 1
const INCOME: int = 3
const HOME_CM: int = 8400
const FILE_LABEL: String = "res://data/income_stub.json"
const ISSUE_CODE: String = "NPC_INCOME_STUB_INVALID"
const INCOME_DIR: String = "res://src/sim/npc/income"


# ---------------------------------------------------------------------------------------------------- mundo de teste

func _need_defs(income_rate_per_hour: int = 0, income_id: String = "income") -> Array[NeedDef]:
	var defs: Array[NeedDef] = []
	for position: int in NEED_IDS.size():
		var need_id: String = income_id if position == INCOME else NEED_IDS[position]
		defs.append(NeedDef.new(need_id, position, 30 if position == INCOME else 0, income_rate_per_hour if position == INCOME else 0, 40, 65, 90))
	return defs


func _action(action_id: String, duration: int, place_kind: String, risk: int = 0) -> ActionDef:
	return ActionDef.new(action_id, duration, place_kind, risk, true)


func _catalog() -> Array[ActionDef]:
	var work: ActionDef = _action("work", 240, "work", 5)
	work.effects.append(ActionDef.ActionEffect.new("rest", 5))
	return [work, _action("wait", 10, ""), _action(ActionRunner.GO_TO_PLACE_ID, 0, "")]


func _routine() -> RoutineTable:
	var occupations: Array[RoutineTable.OccupationDef] = [
		RoutineTable.OccupationDef.new("farmer", "work"), RoutineTable.OccupationDef.new("lumberjack", "work"), RoutineTable.OccupationDef.new("guard", "work"),
	]
	var blocks: Array[RoutineTable.RoutineBlock] = [
		RoutineTable.RoutineBlock.new("f", "farmer", 0, 24, "work"), RoutineTable.RoutineBlock.new("l", "lumberjack", 0, 24, "work"),
		RoutineTable.RoutineBlock.new("g", "guard", 0, 24, "work"),
	]
	return RoutineTable.new(occupations, blocks)


func _places() -> SettlementService:
	var settlements: Array[Settlement] = [Settlement.new(VILLAGE, "settlement.a", Vector3.ZERO)]
	var places: Array[Place] = [Place.new(HOME, VILLAGE, Place.KIND_HOME, Vector3(84.0, 0.0, 0.0), 5), Place.new(WORK, VILLAGE, Place.KIND_WORK, Vector3(184.0, 0.0, 0.0), 5)]
	return SettlementService.new(settlements, places)


func _income_rules() -> Array[IncomeStub.IncomeRule]:
	return [IncomeStub.IncomeRule.new("farmer", 30), IncomeStub.IncomeRule.new("lumberjack", 12)]


func _income() -> IncomeStub:
	return IncomeStub.new(_income_rules())


func _params() -> NpcParams:
	var params: NpcParams = NpcParams.new()
	params.urgency_weight_attention = 1
	params.urgency_weight_urgent = 3
	params.urgency_weight_critical = 6
	params.time_cost_per_hour = 2
	params.distance_cost_per_100m = 2
	params.risk_cost_percent = 100
	params.inertia_bonus = 25
	params.routine_bonus = 40
	params.think_interval_min = 10
	params.max_thinks_per_step = 20
	params.decision_top_k = 1
	return params


func _definitions(income: IncomeStub) -> NpcModule.Definitions:
	var definitions: NpcModule.Definitions = NpcModule.Definitions.new()
	definitions.actions = _catalog()
	var traits: Array[TraitLoader.TraitDef] = []
	for position: int in TRAIT_IDS.size():
		traits.append(TraitLoader.TraitDef.new(TRAIT_IDS[position], position))
	definitions.traits = traits
	definitions.params = _params()
	definitions.places = _places()
	definitions.income = income
	return definitions


func _module(income: IncomeStub, income_rate_per_hour: int = 0, income_id: String = "income") -> NpcModule:
	return NpcModule.new(_need_defs(income_rate_per_hour, income_id), _routine(), _definitions(income))


func _world(module: NpcModule) -> World:
	var clock: SimClock = SimClock.new()
	var world: World = World.new(SimContext.new(clock, EventBus.new(clock), WorldRng.new(3), IdGenerator.new()))
	assert_true(world.register_module("npc", module).ok)
	world.setup()
	world.post_setup()
	return world


func _spawn(module: NpcModule, occupation_id: String) -> int:
	var spec: NpcSpec = NpcSpec.new()
	spec.name_key = "npc.name.villager"
	spec.occupation_id = occupation_id
	spec.settlement_id = VILLAGE
	spec.place_id = HOME
	spec.home_place_id = HOME
	spec.work_place_id = WORK
	spec.x_cm = HOME_CM
	var created: NpcModule.CreateResult = module.request_create_npc(spec)
	assert_true(created.result.ok, created.result.message)
	return created.npc_id


func _run(world: World, minutes: int) -> void:
	for _step: int in minutes:
		world.context.clock.advance_step()
		world.tick(1)


## Provedor que pede um efeito extra numa necessidade que não existe.
class GhostProvider:
	extends ActionConditionProvider

	func extra_effects(_action_id: String, _occupation_id: String) -> Array[ActionDef.ActionEffect]:
		return [ActionDef.ActionEffect.new("ghost", -5)]


## Runner solto com um provedor dado (o IncomeStub entra pelo provedor do módulo; aqui, direto, por um provedor que o repassa).
class IncomeProvider:
	extends ActionConditionProvider

	var income: IncomeStub

	func extra_effects(action_id: String, occupation_id: String) -> Array[ActionDef.ActionEffect]:
		return income.extra_effects(action_id, occupation_id)


class RunnerParts:
	extends RefCounted

	var runner: ActionRunner
	var states: Dictionary[int, NpcState] = {}


func _runner_parts(provider: ActionConditionProvider) -> RunnerParts:
	var parts: RunnerParts = RunnerParts.new()
	parts.runner = ActionRunner.new(parts.states, _catalog(), _need_defs(), _places(), provider)
	assert_eq(parts.runner.peek_problem(), "")
	return parts


func _income_provider() -> IncomeProvider:
	var provider: IncomeProvider = IncomeProvider.new()
	provider.income = _income()
	return provider


func _add_npc(parts: RunnerParts, npc_id: int, occupation_id: String, income: int = 80) -> NpcState:
	var state: NpcState = NpcState.new(npc_id)
	state.occupation_id = occupation_id
	state.settlement_id = VILLAGE
	state.place_id = HOME
	state.x_cm = HOME_CM
	state.need_values = PackedInt64Array([0, 10, 0, income, 0])
	parts.states[npc_id] = state
	return state


# ---------------------------------------------------------------------------------------------------- a regra

func test_the_stub_gives_one_extra_effect_only_for_work_by_an_occupation_in_the_table() -> void:
	var income: IncomeStub = _income()
	var farmer: Array[ActionDef.ActionEffect] = income.extra_effects("work", "farmer")
	assert_eq(farmer.size(), 1)
	assert_eq([farmer[0].need_id, farmer[0].delta], ["income", -30], "O alívio é uma queda da necessidade `income`.")
	assert_eq(income.extra_effects("work", "lumberjack")[0].delta, -12, "A regra é por ofício.")
	assert_eq(income.extra_effects("work", "guard").size(), 0, "Guarda não está na tabela.")
	assert_eq(income.extra_effects("work", "").size(), 0, "Sem ofício, nada.")
	assert_eq(income.extra_effects("wait", "farmer").size(), 0, "Só o trabalho alivia a renda.")
	assert_eq([income.peek_relief("farmer"), income.peek_relief("guard")], [30, 0])
	var duplicated: IncomeStub = IncomeStub.new([IncomeStub.IncomeRule.new("farmer", 5), IncomeStub.IncomeRule.new("farmer", 99)])
	assert_eq(duplicated.peek_relief("farmer"), 5, "Linha repetida: a primeira vence (o carregador nem deixa chegar aqui).")
	var expected_ids: Array[String] = ["farmer", "lumberjack"]
	assert_eq(income.occupation_ids(), expected_ids)


func test_a_completed_work_takes_the_ruled_relief_from_income_and_the_table_effect_still_applies() -> void:
	var parts: RunnerParts = _runner_parts(_income_provider())
	var farmer: NpcState = _add_npc(parts, 1, "farmer", 80)
	assert_true(parts.runner.begin(1, "work", WORK, 100).ok)
	assert_eq(parts.runner.advance(1, 339).outcome, ActionRunner.Outcome.RUNNING)
	assert_eq(farmer.need_values[INCOME], 80, "Trabalhando ainda não alivia.")
	assert_eq(parts.runner.advance(1, 340).outcome, ActionRunner.Outcome.COMPLETED)
	assert_eq(farmer.need_values[INCOME], 50, "80 - 30.")
	assert_eq(farmer.need_values[REST], 15, "O efeito da tabela de ações (+5 de cansaço) continua valendo.")
	var lumberjack: NpcState = _add_npc(parts, 2, "lumberjack", 80)
	assert_true(parts.runner.begin(2, "work", WORK, 400).ok)
	assert_eq(parts.runner.advance(2, 640).outcome, ActionRunner.Outcome.COMPLETED)
	assert_eq(lumberjack.need_values[INCOME], 68, "80 - 12.")


func test_an_interrupted_work_relieves_in_proportion_to_the_time_done_and_never_the_full_amount() -> void:
	# Trabalho de 240 minutos, alívio 30: progresso = piso de (minutos x 1000 / 240), no máximo 999; o efeito é o piso de (-30 x progresso / 1000),
	# que num valor negativo arredonda para MAIS alívio (progresso 125 -> -3,75 -> -4), a mesma conta de todos os efeitos de ação.
	var worked: Array[int] = [0, 30, 120, 239, 240]
	var expected: Array[int] = [80, 76, 65, 50, 50]
	for index: int in worked.size():
		var parts: RunnerParts = _runner_parts(_income_provider())
		var farmer: NpcState = _add_npc(parts, 1, "farmer", 80)
		assert_true(parts.runner.begin(1, "work", WORK, 100).ok)
		assert_true(parts.runner.interrupt(1, 100 + worked[index]).ok)
		assert_eq(farmer.need_values[INCOME], expected[index], "Interrompido após %d de 240 minutos." % worked[index])


func test_only_work_relieves_income_and_without_a_provider_nothing_changes() -> void:
	var parts: RunnerParts = _runner_parts(_income_provider())
	var guard: NpcState = _add_npc(parts, 1, "guard", 80)
	var idler: NpcState = _add_npc(parts, 2, "farmer", 80)
	assert_true(parts.runner.begin(1, "work", WORK, 100).ok)
	assert_eq(parts.runner.advance(1, 340).outcome, ActionRunner.Outcome.COMPLETED)
	assert_eq(guard.need_values[INCOME], 80, "Guarda trabalha e a renda não muda: ele não está na tabela.")
	assert_true(parts.runner.begin(2, "wait", "", 100).ok)
	assert_eq(parts.runner.advance(2, 110).outcome, ActionRunner.Outcome.COMPLETED)
	assert_eq(idler.need_values[INCOME], 80, "Esperar não alivia a renda, mesmo sendo agricultor.")
	var bare: RunnerParts = _runner_parts(null)
	var farmer: NpcState = _add_npc(bare, 3, "farmer", 80)
	assert_true(bare.runner.begin(3, "work", WORK, 100).ok)
	assert_eq(bare.runner.advance(3, 340).outcome, ActionRunner.Outcome.COMPLETED)
	assert_eq(farmer.need_values[INCOME], 80, "Sem provedor não há alívio de renda.")


func test_income_never_goes_below_zero() -> void:
	var parts: RunnerParts = _runner_parts(_income_provider())
	var farmer: NpcState = _add_npc(parts, 1, "farmer", 10)
	assert_true(parts.runner.begin(1, "work", WORK, 100).ok)
	assert_eq(parts.runner.advance(1, 340).outcome, ActionRunner.Outcome.COMPLETED)
	assert_eq(farmer.need_values[INCOME], 0, "10 - 30 fica em 0, não em -20.")


func test_an_extra_effect_on_an_unknown_need_is_refused_without_applying_anything() -> void:
	var parts: RunnerParts = _runner_parts(GhostProvider.new())
	var farmer: NpcState = _add_npc(parts, 1, "farmer", 80)
	var before: Dictionary = farmer.to_dict()
	var refused: Result = parts.runner.apply_effects(1, "work", WORK, ActionRunner.FULL_PROGRESS)
	assert_false(refused.ok)
	assert_eq(refused.code, ActionRunner.CODE_UNKNOWN_NEED)
	assert_string_contains(refused.message, "'ghost'")
	assert_eq(farmer.to_dict(), before, "Nem o efeito da tabela (+5 de cansaço) foi aplicado: tudo ou nada.")


# ---------------------------------------------------------------------------------------------------- no módulo

func test_working_lowers_income_and_not_working_lets_it_grow() -> void:
	var module: NpcModule = _module(_income(), 12)
	var world: World = _world(module)
	var farmer_id: int = _spawn(module, "farmer")
	var idler_id: int = _spawn(module, "")
	assert_eq([farmer_id, idler_id], [1, 2])
	# O agricultor (fase 2) anda 2 minutos e trabalha de 4 a 244; o ocioso (fase 3) só espera. Taxa 12 por hora: 30 + 48 = 78 aos 244 min.
	_run(world, 243)
	assert_eq(module.peek_npc(idler_id).need_values[INCOME], 78, "Sem trabalhar a renda cresce pela taxa da necessidade (30 + 48).")
	assert_eq(module.peek_npc(farmer_id).need_values[INCOME], 30 + 46, "O agricultor ainda trabalha: sem alívio (só o crescimento até o último pensamento, no minuto 234).")
	_run(world, 1)
	assert_eq(module.peek_npc(farmer_id).need_values[INCOME], 48, "Aos 244 min o trabalho completo tirou 30 dos 78.")
	assert_eq(module.validate().size(), 0, str(module.validate()))
	world.teardown()


func test_a_table_naming_a_missing_occupation_or_a_missing_need_turns_the_decisions_off_with_the_reason() -> void:
	var for_wizard: Array[IncomeStub.IncomeRule] = [IncomeStub.IncomeRule.new("wizard", 10)]
	var wizard_module: NpcModule = _module(IncomeStub.new(for_wizard))
	var wizard_world: World = _world(wizard_module)
	_spawn(wizard_module, "farmer")
	_run(wizard_world, 5)
	var wizard_summary: Dictionary = wizard_module.debug_summary()
	assert_false(wizard_summary["decision_enabled"])
	assert_string_contains(wizard_summary["decision_problem"], "TEMP-LW-066")
	assert_string_contains(wizard_summary["decision_problem"], "'wizard'")
	var no_income_module: NpcModule = _module(_income(), 0, "money")
	var no_income_world: World = _world(no_income_module)
	_spawn(no_income_module, "farmer")
	_run(no_income_world, 5)
	var no_income_summary: Dictionary = no_income_module.debug_summary()
	assert_false(no_income_summary["decision_enabled"])
	assert_string_contains(no_income_summary["decision_problem"], "'income'")
	wizard_world.teardown()
	no_income_world.teardown()


# ---------------------------------------------------------------------------------------------------- dado e marca

func _valid_record() -> Dictionary:
	return {"id": "income_farmer", "temp_mark": "TEMP-LW-066", "occupation_id": "farmer", "income_relief": 30}


func _load_records(records: Array[Dictionary]) -> IncomeStubLoader.LoadResult:
	var bundle: DataBundle = DataBundle.new()
	bundle.tables[IncomeStubLoader.INCOME_TABLE] = records
	bundle.file_paths[IncomeStubLoader.INCOME_TABLE] = FILE_LABEL
	DataValidator.new().validate(bundle, [IncomeStubLoader.build_schema()])
	return IncomeStubLoader.from_bundle(bundle)


func _expect_failure(label: String, records: Array[Dictionary], fragments: Array[String]) -> void:
	var loaded: IncomeStubLoader.LoadResult = _load_records(records)
	assert_false(loaded.result.ok, "%s: deveria falhar." % label)
	assert_eq(loaded.result.code, ISSUE_CODE, label)
	assert_null(loaded.stub, "%s: falha não devolve tabela." % label)
	for fragment: String in fragments:
		assert_string_contains(loaded.result.message, fragment, "%s: a mensagem deveria citar '%s'." % [label, fragment])


func _read_json_rows(path: String) -> Array:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert_eq(typeof(parsed), TYPE_ARRAY, "%s deve ser uma lista." % path)
	var rows: Array = parsed if typeof(parsed) == TYPE_ARRAY else []
	return rows


func test_the_real_file_loads_and_every_row_carries_the_temp_mark_and_a_real_occupation() -> void:
	var loaded: IncomeStubLoader.LoadResult = IncomeStubLoader.load_dir()
	assert_true(loaded.result.ok, loaded.result.message)
	var rows: Array = _read_json_rows("res://data/income_stub.json")
	assert_gt(rows.size(), 0)
	var occupation_ids: Array = []
	for row: Variant in _read_json_rows("res://data/occupations.json"):
		var occupation: Dictionary = row
		occupation_ids.append(occupation.get("id"))
	for row: Variant in rows:
		var record: Dictionary = row
		assert_eq(record.get("temp_mark"), "TEMP-LW-066", "Linha '%s': a marca TEMP-LW-066 é obrigatória." % record.get("id"))
		assert_true(occupation_ids.has(record.get("occupation_id")), "Linha '%s': o ofício existe em data/occupations.json." % record.get("id"))
		assert_gt(loaded.stub.peek_relief(str(record.get("occupation_id"))), 0, "Linha '%s': trabalhar alivia alguma renda." % record.get("id"))
	assert_eq(loaded.stub.occupation_ids().size(), rows.size())


func test_the_in_memory_path_builds_the_rules_from_the_rows() -> void:
	var second: Dictionary = _valid_record()
	second["id"] = "income_guard"
	second["occupation_id"] = "guard"
	second["income_relief"] = 0
	var loaded: IncomeStubLoader.LoadResult = _load_records([_valid_record(), second])
	assert_true(loaded.result.ok, loaded.result.message)
	assert_eq([loaded.stub.peek_relief("farmer"), loaded.stub.peek_relief("guard")], [30, 0], "Alívio 0 é permitido (o ofício existe e não alivia).")
	var top: Dictionary = _valid_record()
	top["income_relief"] = 100
	assert_true(_load_records([top]).result.ok, "100 é o maior alívio possível (a faixa de uma necessidade).")


func test_invalid_data_fails_pointing_at_file_item_and_field() -> void:
	for field: String in ["temp_mark", "occupation_id", "income_relief"]:
		var missing: Dictionary = _valid_record()
		missing.erase(field)
		_expect_failure("%s ausente" % field, [missing], [FILE_LABEL, "item 'income_farmer'", "campo '%s'" % field, "obrigatório ausente"])
	var wrong_mark: Dictionary = _valid_record()
	wrong_mark["temp_mark"] = "TEMP-LW-065"
	_expect_failure("marca errada", [wrong_mark], [FILE_LABEL, "campo 'temp_mark'", "esperado exatamente 'TEMP-LW-066'"])
	var negative: Dictionary = _valid_record()
	negative["income_relief"] = -1
	_expect_failure("alívio negativo", [negative], [FILE_LABEL, "campo 'income_relief'", "abaixo do mínimo"])
	var too_much: Dictionary = _valid_record()
	too_much["income_relief"] = 101
	_expect_failure("alívio acima de 100", [too_much], [FILE_LABEL, "campo 'income_relief'", "acima do máximo"])
	var as_text: Dictionary = _valid_record()
	as_text["income_relief"] = "30"
	_expect_failure("alívio como texto", [as_text], [FILE_LABEL, "campo 'income_relief'", "tipo inválido"])
	var fraction: Dictionary = _valid_record()
	fraction["income_relief"] = 7.5
	_expect_failure("alívio com fração", [fraction], [FILE_LABEL, "campo 'income_relief'", "tipo inválido"])
	var empty_occupation: Dictionary = _valid_record()
	empty_occupation["occupation_id"] = ""
	_expect_failure("ofício vazio", [empty_occupation], [FILE_LABEL, "campo 'occupation_id'", "não pode ficar vazio"])
	var money: Dictionary = _valid_record()
	money["salary"] = 10
	_expect_failure("campo desconhecido (salário não existe aqui)", [money], [FILE_LABEL, "campo 'salary'", "campo desconhecido"])
	var twin: Dictionary = _valid_record()
	twin["id"] = "income_twin"
	_expect_failure("dois alívios para o mesmo ofício", [_valid_record(), twin], [FILE_LABEL, "item 'income_twin'", "campo 'occupation_id'", "já tem regra na linha 'income_farmer'"])
	_expect_failure("nenhuma linha", [], [FILE_LABEL, "esperada ao menos 1 linha"])


func test_a_missing_file_fails_pointing_at_the_file() -> void:
	var loaded: IncomeStubLoader.LoadResult = IncomeStubLoader.load_dir("res://tests/fixtures/data/ok")
	assert_false(loaded.result.ok)
	assert_eq(loaded.result.code, ISSUE_CODE)
	assert_string_contains(loaded.result.message, "income_stub.json")
	assert_string_contains(loaded.result.message, "arquivo não encontrado")


func test_the_temp_mark_is_in_every_file_of_the_stub_and_in_the_docs_and_the_wiring() -> void:
	var scripts: Array[String] = []
	for file_name: String in DirAccess.get_files_at(INCOME_DIR):
		if file_name.ends_with(".gd"):
			scripts.append(file_name)
	assert_gte(scripts.size(), 2, "A pasta do provisório tem a tabela e o carregador.")
	for file_name: String in scripts:
		assert_string_contains(FileAccess.get_file_as_string(INCOME_DIR.path_join(file_name)), IncomeStub.TEMP_MARK, "%s precisa da marca %s." % [file_name, IncomeStub.TEMP_MARK])
	assert_string_contains(FileAccess.get_file_as_string("res://docs/modules/npc.md"), IncomeStub.TEMP_MARK, "A marca também está nos documentos.")
	assert_string_contains(FileAccess.get_file_as_string("res://src/sim/npc/api/npc_module.gd"), IncomeStub.TEMP_MARK, "As linhas do módulo que ligam o IncomeStub levam a marca (a LW-095 as acha por ela).")
	assert_string_contains(FileAccess.get_file_as_string("res://data/income_stub.json"), IncomeStub.TEMP_MARK)
