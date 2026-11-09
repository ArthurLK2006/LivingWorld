extends GutTest
## LW-081: consequências da necessidade crítica (docs/modules/npc.md, seção 8), sem janela. Fome crítica há `weaken_after_hours` enfraquece (o
## `work` rende `weak_effect_percent` por cento) e há `lethal_after_hours` mata: `is_alive` falso, ação cancelada sem efeito, local liberado e o
## evento `NpcDied(npc_id, cause, tier)` publicado. Com comida o NPC não morre. Salvar e carregar com NPC morto funciona; consultas ao morto não
## falham. Mundo de teste montado à mão; os limites de teste são 24 h (enfraquece) e 72 h (morre), os mesmos de data/needs.json.

## Velocidade de caminhada fixada na antiga (8400 cm/min): este teste mede a lógica, não a velocidade padrão; a velocidade padrão (500 cm/min, DEC-123) é coberta em test_action_runner.gd.
const WALK_SPEED_CM_PER_MIN: int = 8400
const VILLAGE: String = "village_a"
const HOME: String = "home_a1"
const WORK: String = "work_a1"
const NEED_IDS: Array[String] = ["hunger", "rest", "safety", "income", "social"]
const TRAIT_IDS: Array[String] = ["caution", "sociability", "ambition", "loyalty"]
const HUNGER: int = 0
const REST: int = 1
const INCOME: int = 3
const HOME_X_CM: int = 8400
const THINK_INTERVAL: int = 10
const WEAKEN_HOURS: int = 24
const LETHAL_HOURS: int = 72
const WEAK_PERCENT: int = 50
const MINUTES_PER_HOUR: int = 60
const FILE_LABEL: String = "res://data/needs.json"
const ISSUE_CODE: String = "NEED_DATA_INVALID"


## Provedor de comida de teste: com `food` falso nenhuma ação que exija comida começa.
class FakeFood:
	extends ActionConditionProvider

	var food: bool = true

	func has_food(_settlement_id: String) -> bool:
		return food


# ---------------------------------------------------------------------------------------------------- mundo de teste

## Necessidades de teste: só a fome é letal (24 h para enfraquecer, 72 h para morrer, rendimento 50%); a fome sobe `hunger_rate` por hora.
func _need_defs(start_hunger: int, hunger_rate: int = 0) -> Array[NeedDef]:
	var defs: Array[NeedDef] = []
	for position: int in NEED_IDS.size():
		if position == HUNGER:
			defs.append(NeedDef.new(NEED_IDS[position], position, start_hunger, hunger_rate, 40, 65, 90, WEAKEN_HOURS, LETHAL_HOURS, WEAK_PERCENT))
		else:
			defs.append(NeedDef.new(NEED_IDS[position], position, 0, 0, 40, 65, 90))
	return defs


func _action(action_id: String, duration: int, place_kind: String, risk: int = 0) -> ActionDef:
	return ActionDef.new(action_id, duration, place_kind, risk, true)


func _catalog() -> Array[ActionDef]:
	var eat: ActionDef = _action("eat", 20, "home")
	eat.effects.append(ActionDef.ActionEffect.new("hunger", -60))
	eat.conditions.append(ActionDef.ActionCondition.new(ActionDef.CONDITION_HAS_FOOD, "", ActionDef.ABSENT, ActionDef.ABSENT))
	var work: ActionDef = _action("work", 240, "work", 5)
	work.effects.append(ActionDef.ActionEffect.new("rest", 5))
	return [eat, work, _action("wait", 10, ""), _action(ActionRunner.GO_TO_PLACE_ID, 0, "")]


func _routine() -> RoutineTable:
	var occupations: Array[RoutineTable.OccupationDef] = [RoutineTable.OccupationDef.new("farmer", "work")]
	var blocks: Array[RoutineTable.RoutineBlock] = [RoutineTable.RoutineBlock.new("f", "farmer", 0, 24, "work")]
	return RoutineTable.new(occupations, blocks)


func _places() -> SettlementService:
	var settlements: Array[Settlement] = [Settlement.new(VILLAGE, "settlement.a", Vector3.ZERO)]
	var places: Array[Place] = [Place.new(HOME, VILLAGE, Place.KIND_HOME, Vector3(84.0, 0.0, 0.0), 5), Place.new(WORK, VILLAGE, Place.KIND_WORK, Vector3(184.0, 0.0, 0.0), 5)]
	return SettlementService.new(settlements, places)


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
	params.think_interval_min = THINK_INTERVAL
	params.max_thinks_per_step = 20
	params.decision_top_k = 1
	return params


func _module(food: ActionConditionProvider, start_hunger: int = 95, hunger_rate: int = 0) -> NpcModule:
	var definitions: NpcModule.Definitions = NpcModule.Definitions.new()
	definitions.actions = _catalog()
	var traits: Array[TraitLoader.TraitDef] = []
	for position: int in TRAIT_IDS.size():
		traits.append(TraitLoader.TraitDef.new(TRAIT_IDS[position], position))
	definitions.traits = traits
	definitions.params = _params()
	definitions.walk_speed_cm_per_min = WALK_SPEED_CM_PER_MIN
	definitions.places = _places()
	definitions.food = food
	return NpcModule.new(_need_defs(start_hunger, hunger_rate), _routine(), definitions)


func _world(module: NpcModule, world_seed: int = 3) -> World:
	var clock: SimClock = SimClock.new()
	var world: World = World.new(SimContext.new(clock, EventBus.new(clock), WorldRng.new(world_seed), IdGenerator.new()))
	assert_true(world.register_module("npc", module).ok)
	world.setup()
	world.post_setup()
	return world


## NPC sem ofício (só espera) ou agricultor, em casa.
func _spawn(module: NpcModule, occupation_id: String = "") -> int:
	var spec: NpcSpec = NpcSpec.new()
	spec.name_key = "npc.name.villager"
	spec.tier = NpcState.TIER_NOTABLE
	spec.occupation_id = occupation_id
	spec.settlement_id = VILLAGE
	spec.place_id = HOME
	spec.home_place_id = HOME
	spec.work_place_id = WORK
	spec.x_cm = HOME_X_CM
	var created: NpcModule.CreateResult = module.request_create_npc(spec)
	assert_true(created.result.ok, created.result.message)
	return created.npc_id


## Um minuto por vez, como o SimulationRunner: relógio, módulos e entrega dos eventos.
func _run(world: World, minutes: int) -> void:
	for _step: int in minutes:
		world.context.clock.advance_step()
		world.tick(1)
		world.context.events.dispatch()


func _saved_entry(module: NpcModule, npc_id: int) -> Dictionary:
	var entries: Dictionary = module.serialize()["npcs"]
	var entry: Dictionary = entries[str(npc_id)]
	return entry


func _first_think(npc_id: int) -> int:
	return 1 + npc_id % THINK_INTERVAL


# ---------------------------------------------------------------------------------------------------- a conta

func _state(hunger: int, rest: int = 0) -> NpcState:
	var state: NpcState = NpcState.new(1)
	state.need_values = PackedInt64Array([hunger, rest, 0, 0, 0])
	return state


func test_critical_since_starts_at_the_first_sight_stays_while_critical_and_clears_when_it_stops() -> void:
	var defs: Array[NeedDef] = _need_defs(0)
	var state: NpcState = _state(89)
	NeedMath.update_critical(state, defs, 50)
	assert_eq(state.critical_since, NpcState.NO_TIME, "89 ainda não é crítico (o limiar é 90).")
	state.need_values[HUNGER] = 90
	NeedMath.update_critical(state, defs, 100)
	assert_eq(state.critical_since, 100, "Valor igual ao limiar já é crítico.")
	NeedMath.update_critical(state, defs, 200)
	assert_eq(state.critical_since, 100, "Continua crítico: o começo não muda.")
	state.need_values[HUNGER] = 30
	NeedMath.update_critical(state, defs, 300)
	assert_eq(state.critical_since, NpcState.NO_TIME, "Saiu do nível crítico: zera.")
	state.need_values[HUNGER] = 100
	NeedMath.update_critical(state, defs, 400)
	assert_eq(state.critical_since, 400, "Voltou a ficar crítico: conta de novo.")


func test_a_critical_need_that_is_not_lethal_changes_nothing() -> void:
	var defs: Array[NeedDef] = _need_defs(0)
	var state: NpcState = _state(0, 99)
	NeedMath.update_critical(state, defs, 10)
	assert_eq(state.critical_since, NpcState.NO_TIME, "O cansaço crítico não é letal.")
	assert_eq(NeedMath.lethal_cause(state, defs, 100000), "")
	assert_eq(NeedMath.work_effect_percent(state, defs, 100000), 100)


func test_the_lethal_limit_is_exact_in_minutes() -> void:
	var defs: Array[NeedDef] = _need_defs(0)
	var state: NpcState = _state(100)
	state.critical_since = 1000
	assert_eq(NeedMath.lethal_cause(state, defs, 1000 + LETHAL_HOURS * MINUTES_PER_HOUR - 1), "", "Um minuto antes do limite: vivo.")
	assert_eq(NeedMath.lethal_cause(state, defs, 1000 + LETHAL_HOURS * MINUTES_PER_HOUR), "hunger", "No minuto do limite: morre, com a causa.")
	state.need_values[HUNGER] = 40
	assert_eq(NeedMath.lethal_cause(state, defs, 1000 + LETHAL_HOURS * MINUTES_PER_HOUR + 500), "", "Se a fome já baixou do crítico, não morre.")


func test_the_weak_percent_applies_from_the_weaken_hour_on_and_only_while_critical() -> void:
	var defs: Array[NeedDef] = _need_defs(0)
	var state: NpcState = _state(100)
	assert_eq(NeedMath.work_effect_percent(state, defs, 5000), 100, "Sem critical_since não está enfraquecido.")
	state.critical_since = 0
	assert_eq(NeedMath.work_effect_percent(state, defs, WEAKEN_HOURS * MINUTES_PER_HOUR - 1), 100, "Um minuto antes do limite de enfraquecer.")
	assert_eq(NeedMath.work_effect_percent(state, defs, WEAKEN_HOURS * MINUTES_PER_HOUR), WEAK_PERCENT)
	state.need_values[HUNGER] = 20
	assert_eq(NeedMath.work_effect_percent(state, defs, WEAKEN_HOURS * MINUTES_PER_HOUR + 100), 100, "Comeu: volta a render por inteiro.")


func test_definitions_with_incoherent_limits_are_reported() -> void:
	var cases: Array[Dictionary] = [
		{"weaken": 72, "lethal": 72, "percent": 50, "fragment": "0 < weaken_after_hours (72) < lethal_after_hours (72)"},
		{"weaken": 0, "lethal": 72, "percent": 50, "fragment": "0 < weaken_after_hours (0)"},
		{"weaken": 10, "lethal": 0, "percent": 50, "fragment": "sem ser letal"},
		{"weaken": 24, "lethal": 72, "percent": 0, "fragment": "weak_effect_percent 0"},
		{"weaken": 24, "lethal": 72, "percent": 101, "fragment": "weak_effect_percent 101"},
		{"weaken": -1, "lethal": 72, "percent": 50, "fragment": "horas negativas"},
	]
	for row: Dictionary in cases:
		var defs: Array[NeedDef] = _need_defs(0)
		defs[HUNGER].weaken_after_hours = row["weaken"]
		defs[HUNGER].lethal_after_hours = row["lethal"]
		defs[HUNGER].weak_effect_percent = row["percent"]
		assert_string_contains(NeedMath.definitions_problem(defs), str(row["fragment"]))
	assert_eq(NeedMath.definitions_problem(_need_defs(0)), "", "A configuração de teste é coerente.")


# ---------------------------------------------------------------------------------------------------- os dados

func _records(overrides: Dictionary) -> Array[Dictionary]:
	var rows: Array[Dictionary] = [
		{"id": "hunger", "order": 0, "start_value": 20, "rate_per_hour": 5, "attention": 40, "urgent": 65, "critical": 90},
		{"id": "rest", "order": 1, "start_value": 10, "rate_per_hour": 4, "attention": 50, "urgent": 75, "critical": 90},
		{"id": "safety", "order": 2, "start_value": 0, "rate_per_hour": -5, "attention": 30, "urgent": 60, "critical": 85},
		{"id": "income", "order": 3, "start_value": 30, "rate_per_hour": 2, "attention": 50, "urgent": 75, "critical": 95},
		{"id": "social", "order": 4, "start_value": 30, "rate_per_hour": 2, "attention": 50, "urgent": 75, "critical": 90},
	]
	for key: Variant in overrides:
		rows[0][key] = overrides[key]
	return rows


func _load_records(records: Array[Dictionary]) -> NeedLoader.LoadResult:
	var bundle: DataBundle = DataBundle.new()
	bundle.tables[NeedLoader.NEEDS_TABLE] = records
	bundle.file_paths[NeedLoader.NEEDS_TABLE] = FILE_LABEL
	DataValidator.new().validate(bundle, [NeedLoader.build_schema()])
	return NeedLoader.from_bundle(bundle)


func test_the_real_file_makes_only_hunger_lethal() -> void:
	var loaded: NeedLoader.LoadResult = NeedLoader.load_dir()
	assert_true(loaded.result.ok, loaded.result.message)
	for def: NeedDef in loaded.needs:
		if def.id == "hunger":
			assert_true(def.lethal_after_hours > 0 and def.weaken_after_hours > 0 and def.weaken_after_hours < def.lethal_after_hours, "A fome é letal e enfraquece antes de matar.")
			assert_true(def.weak_effect_percent >= 1 and def.weak_effect_percent < 100, "Enfraquecido rende menos que por inteiro.")
		else:
			assert_eq([def.weaken_after_hours, def.lethal_after_hours, def.weak_effect_percent], [0, 0, 100], "Só a fome é letal na Fase 2 (%s)." % def.id)


func test_optional_fields_default_to_no_consequence_and_the_rest_are_validated() -> void:
	var plain: NeedLoader.LoadResult = _load_records(_records({}))
	assert_true(plain.result.ok, plain.result.message)
	assert_eq([plain.needs[HUNGER].weaken_after_hours, plain.needs[HUNGER].lethal_after_hours, plain.needs[HUNGER].weak_effect_percent], [0, 0, 100], "Sem os campos: sem consequência (o formato antigo continua valendo).")
	var lethal: NeedLoader.LoadResult = _load_records(_records({"weaken_after_hours": 24, "lethal_after_hours": 72, "weak_effect_percent": 50}))
	assert_true(lethal.result.ok, lethal.result.message)
	assert_eq([lethal.needs[HUNGER].weaken_after_hours, lethal.needs[HUNGER].lethal_after_hours, lethal.needs[HUNGER].weak_effect_percent], [24, 72, 50])
	var bad_rows: Array[Dictionary] = [
		{"label": "letal sem enfraquecer", "over": {"lethal_after_hours": 72}, "fragments": ["campo 'weaken_after_hours'", "precisa de weaken_after_hours maior que 0 e menor que o limite letal"]},
		{"label": "enfraquecer depois de matar", "over": {"weaken_after_hours": 72, "lethal_after_hours": 72}, "fragments": ["campo 'weaken_after_hours'", "menor que o limite letal"]},
		{"label": "enfraquecer sem ser letal", "over": {"weaken_after_hours": 5}, "fragments": ["campo 'weaken_after_hours'", "sem necessidade letal"]},
		{"label": "rendimento zero", "over": {"weaken_after_hours": 24, "lethal_after_hours": 72, "weak_effect_percent": 0}, "fragments": ["campo 'weak_effect_percent'", "abaixo do mínimo"]},
		{"label": "rendimento acima de 100", "over": {"weaken_after_hours": 24, "lethal_after_hours": 72, "weak_effect_percent": 101}, "fragments": ["campo 'weak_effect_percent'", "acima do máximo"]},
		{"label": "horas negativas", "over": {"weaken_after_hours": -1, "lethal_after_hours": 72}, "fragments": ["campo 'weaken_after_hours'", "abaixo do mínimo"]},
		{"label": "horas como texto", "over": {"lethal_after_hours": "72"}, "fragments": ["campo 'lethal_after_hours'", "tipo inválido"]},
	]
	for row: Dictionary in bad_rows:
		var over: Dictionary = row["over"]
		var failed: NeedLoader.LoadResult = _load_records(_records(over))
		assert_false(failed.result.ok, "%s: deveria falhar." % row["label"])
		assert_eq(failed.result.code, ISSUE_CODE, str(row["label"]))
		for fragment: Variant in row["fragments"]:
			assert_string_contains(failed.result.message, str(fragment), "%s: deveria citar '%s'." % [row["label"], str(fragment)])
		assert_string_contains(failed.result.message, "item 'hunger'")


# ---------------------------------------------------------------------------------------------------- o enfraquecido rende menos

func test_a_weakened_npc_gets_the_weak_percent_of_a_work_and_a_healthy_one_gets_all() -> void:
	var income_rules: Array[IncomeStub.IncomeRule] = [IncomeStub.IncomeRule.new("farmer", 30)]
	var income: IncomeStub = IncomeStub.new(income_rules)
	var results: Array[int] = []
	for starving: bool in [false, true]:
		var states: Dictionary[int, NpcState] = {}
		var state: NpcState = NpcState.new(1)
		state.occupation_id = "farmer"
		state.settlement_id = VILLAGE
		state.place_id = HOME
		state.need_values = PackedInt64Array([95 if starving else 0, 10, 0, 80, 0])
		if starving:
			state.critical_since = 0
		state.needs_updated_at = WEAKEN_HOURS * MINUTES_PER_HOUR + 100
		states[1] = state
		var provider: IncomeProviderForTest = IncomeProviderForTest.new()
		provider.income = income
		var runner: ActionRunner = ActionRunner.new(states, _catalog(), _need_defs(0), _places(), provider)
		var start: int = state.needs_updated_at
		assert_true(runner.begin(1, "work", WORK, start).ok)
		assert_eq(runner.advance(1, start + 240).outcome, ActionRunner.Outcome.COMPLETED)
		results.append(state.need_values[INCOME])
		results.append(state.need_values[REST])
	var expected: Array[int] = [50, 15, 65, 12]
	assert_eq(results, expected, "Saudável: renda 80 - 30 e cansaço 10 + 5. Enfraquecido (50%): renda 80 - 15 e cansaço 10 + 2.")


## Provedor que repassa o alívio de renda do IncomeStub.
class IncomeProviderForTest:
	extends ActionConditionProvider

	var income: IncomeStub

	func extra_effects(action_id: String, occupation_id: String) -> Array[ActionDef.ActionEffect]:
		return income.extra_effects(action_id, occupation_id)


# ---------------------------------------------------------------------------------------------------- morrer de fome, ou não

func test_without_food_the_npc_is_weakened_then_dies_at_the_limit_with_the_event() -> void:
	var food: FakeFood = FakeFood.new()
	food.food = false
	var module: NpcModule = _module(food)
	var world: World = _world(module)
	var received: Array[NpcDied] = []
	world.context.events.subscribe("NpcDied", func(event: SimEvent) -> void: received.append(event as NpcDied))
	var npc_id: int = _spawn(module)
	var first: int = _first_think(npc_id)
	_run(world, first)
	assert_eq(_saved_entry(module, npc_id)["critical_since"], first, "O primeiro pensamento viu a fome crítica (95).")
	var death_minute: int = first + LETHAL_HOURS * MINUTES_PER_HOUR
	_run(world, death_minute - first - 1)
	assert_true(module.peek_npc(npc_id).is_alive, "Um minuto antes do limite: vivo.")
	assert_eq(received.size(), 0)
	_run(world, 1)
	var dead: NpcModule.NpcQuery = module.peek_npc(npc_id)
	assert_false(dead.is_alive, "No minuto do limite: morto.")
	assert_eq(dead.death_cause, "hunger", "A causa é o id da necessidade.")
	assert_eq(received.size(), 1, "O evento NpcDied foi publicado uma vez.")
	assert_eq([received[0].npc_id, received[0].cause, received[0].tier], [npc_id, "hunger", NpcState.TIER_NOTABLE])
	var entry: Dictionary = _saved_entry(module, npc_id)
	assert_eq(entry["died_at"], death_minute)
	assert_eq([dead.action_id, dead.place_id], ["", ""], "Ação cancelada e local liberado.")
	assert_eq(entry["critical_since"], NpcState.NO_TIME)
	assert_eq(module.validate().size(), 0, str(module.validate()))
	var counts: Dictionary = module.peek_counts()
	assert_eq([counts["alive"], counts["dead"]], [0, 1])
	_run(world, 600)
	assert_eq(received.size(), 1, "O morto não morre de novo nem pensa.")
	assert_eq(_saved_entry(module, npc_id)["died_at"], death_minute)
	world.teardown()


func test_with_food_the_npc_never_dies() -> void:
	var module: NpcModule = _module(FakeFood.new())
	var world: World = _world(module)
	var received: Array[NpcDied] = []
	world.context.events.subscribe("NpcDied", func(event: SimEvent) -> void: received.append(event as NpcDied))
	var npc_id: int = _spawn(module)
	_run(world, 5 * 1440)
	assert_true(module.peek_npc(npc_id).is_alive)
	assert_eq(received.size(), 0)
	assert_eq(_saved_entry(module, npc_id)["critical_since"], NpcState.NO_TIME, "Comeu e saiu do nível crítico.")
	world.teardown()


func test_food_that_arrives_after_the_weakening_but_before_the_limit_saves_the_npc() -> void:
	var food: FakeFood = FakeFood.new()
	food.food = false
	var module: NpcModule = _module(food)
	var world: World = _world(module)
	var npc_id: int = _spawn(module)
	_run(world, (WEAKEN_HOURS + 10) * MINUTES_PER_HOUR)
	assert_true(module.peek_npc(npc_id).is_alive, "Enfraquecido há 10 horas, mas vivo.")
	assert_gte(int(_saved_entry(module, npc_id)["critical_since"]), 0)
	food.food = true
	_run(world, 120)
	assert_true(module.peek_npc(npc_id).is_alive)
	assert_eq(_saved_entry(module, npc_id)["critical_since"], NpcState.NO_TIME, "Comeu: o contador zerou.")
	_run(world, LETHAL_HOURS * MINUTES_PER_HOUR)
	assert_true(module.peek_npc(npc_id).is_alive, "E o relógio da morte recomeçou do zero.")
	world.teardown()


func test_queries_about_the_dead_never_fail_and_the_dead_can_be_removed() -> void:
	var food: FakeFood = FakeFood.new()
	food.food = false
	var module: NpcModule = _module(food)
	var world: World = _world(module)
	var npc_id: int = _spawn(module)
	var other: int = _spawn(module, "farmer")
	_run(world, 5 * 1440)
	assert_false(module.peek_npc(npc_id).is_alive)
	var query: NpcModule.NpcQuery = module.peek_npc(npc_id)
	assert_true(query.result.ok, "Consultar um morto não falha.")
	assert_eq([query.name_key, query.tier, query.death_cause], ["npc.name.villager", NpcState.TIER_NOTABLE, "hunger"], "Ficam a identidade e a causa.")
	var expected_ids: Array[int] = [npc_id, other]
	assert_eq(module.peek_npc_ids(), expected_ids)
	assert_eq(module.validate().size(), 0, str(module.validate()))
	assert_eq(world.validate().size(), 0, str(world.validate()))
	assert_true(module.request_remove_npc(npc_id).ok, "O morto pode ser removido.")
	assert_eq(module.peek_npc(npc_id).result.code, NpcModule.CODE_UNKNOWN)
	world.teardown()


# ---------------------------------------------------------------------------------------------------- salvar, validar, repetir

func test_a_dead_npc_and_a_critical_one_survive_a_save_and_load_exactly() -> void:
	var food: FakeFood = FakeFood.new()
	food.food = false
	var module: NpcModule = _module(food)
	var world: World = _world(module)
	var first_id: int = _spawn(module)
	_run(world, LETHAL_HOURS * MINUTES_PER_HOUR + 20)
	assert_false(module.peek_npc(first_id).is_alive)
	var second_id: int = _spawn(module)
	_run(world, 60)
	assert_gte(int(_saved_entry(module, second_id)["critical_since"]), 0, "O segundo NPC está em nível crítico agora.")
	var parsed: Variant = JSON.parse_string(JSON.stringify(world.serialize(), "", true, true))
	var saved: Dictionary = parsed
	var other_food: FakeFood = FakeFood.new()
	other_food.food = false
	var other: NpcModule = _module(other_food)
	var other_world: World = _world(other)
	var loaded: Result = other_world.on_load(saved)
	assert_true(loaded.ok, loaded.message)
	assert_eq(other_world.state_hash(), world.state_hash(), "Ida e volta sem diferença.")
	assert_false(other.peek_npc(first_id).is_alive)
	assert_eq(_saved_entry(other, second_id)["critical_since"], _saved_entry(module, second_id)["critical_since"])
	assert_eq(other.validate().size(), 0, str(other.validate()))
	_run(world, 600)
	_run(other_world, 600)
	assert_eq(other_world.state_hash(), world.state_hash(), "Continuar depois de carregar dá o mesmo.")
	world.teardown()
	other_world.teardown()


func test_a_save_without_critical_since_loads_as_none_and_a_bad_one_is_refused() -> void:
	var module: NpcModule = _module(FakeFood.new(), 0)
	var world: World = _world(module)
	var npc_id: int = _spawn(module)
	var saved: Dictionary = module.serialize()
	var entries: Dictionary = saved["npcs"]
	var entry: Dictionary = entries[str(npc_id)]
	entry.erase("critical_since")
	assert_true(module.on_load(saved).ok, "Save de antes da LW-081 (sem o campo) carrega.")
	assert_eq(_saved_entry(module, npc_id)["critical_since"], NpcState.NO_TIME)
	entry["critical_since"] = "ontem"
	var refused: Result = module.on_load(saved)
	assert_false(refused.ok)
	assert_string_contains(refused.message, "critical_since")
	entry["critical_since"] = -5
	assert_true(module.on_load(saved).ok, "O formato é aceito; a coerência é do validate().")
	assert_string_contains(str(module.validate()), "critical_since -5 inválido")
	entry["critical_since"] = 7
	entry["is_alive"] = false
	entry["death_cause"] = "hunger"
	entry["died_at"] = 9
	assert_true(module.on_load(saved).ok)
	assert_string_contains(str(module.validate()), "morto, mas com critical_since 7")
	world.teardown()


func _hash_after_starving(world_seed: int) -> String:
	var food: FakeFood = FakeFood.new()
	food.food = false
	var module: NpcModule = _module(food, 70, 3)
	var world: World = _world(module, world_seed)
	for _index: int in 4:
		_spawn(module)
	_spawn(module, "farmer")
	_run(world, 6 * 1440)
	var result: String = world.state_hash()
	assert_gt(module.peek_counts()["dead"], 0, "No cenário alguém morreu.")
	world.teardown()
	return result


func test_a_world_where_npcs_starve_is_reproducible_with_the_same_seed() -> void:
	assert_eq(_hash_after_starving(5), _hash_after_starving(5))


# ---------------------------------------------------------------------------------------------------- pensar atrasado não muda as necessidades

## Um NPC com fome subindo 1 ponto por minuto come de 2 a 22 e a fome chega a 100 (limite) antes do fim. Num mundo o relógio anda um minuto por
## vez e o NPC pensa no minuto 22; no outro o relógio anda de 2 a 32 SEM o módulo rodar e o NPC só pensa no 32 (atrasado). No minuto 32 as
## necessidades têm que ser as mesmas: a refeição é contada no minuto em que acabou (fome 100 - 60 = 40 no 22, 50 no 32), e não no 32 (100 - 60 = 40).
func test_a_delayed_think_gives_the_same_needs_as_an_on_time_one() -> void:
	var on_time_module: NpcModule = _module(FakeFood.new(), 95, 60)
	var on_time_world: World = _world(on_time_module)
	var on_time_id: int = _spawn(on_time_module)
	var delayed_module: NpcModule = _module(FakeFood.new(), 95, 60)
	var delayed_world: World = _world(delayed_module)
	var delayed_id: int = _spawn(delayed_module)
	var first: int = _first_think(on_time_id)
	_run(on_time_world, first)
	_run(delayed_world, first)
	assert_eq(on_time_module.peek_npc(on_time_id).action_id, "eat", "Os dois começaram a comer no mesmo minuto.")
	assert_eq(delayed_module.peek_npc(delayed_id).action_id, "eat")
	var late_minute: int = first + 30
	_run(on_time_world, 30)
	for _step: int in 30:
		delayed_world.context.clock.advance_step()
	delayed_world.tick(1)
	delayed_world.context.events.dispatch()
	assert_eq(delayed_world.context.clock.total_minutes(), late_minute)
	var on_time_hunger: int = on_time_module.peek_npc(on_time_id).need_values[HUNGER]
	assert_eq(delayed_module.peek_npc(delayed_id).need_values[HUNGER], on_time_hunger, "A fome no minuto %d é a mesma, pensando na hora ou atrasado." % late_minute)
	assert_eq(on_time_hunger, 100 - 60 + (late_minute - (first + 20)), "100 no fim da refeição, menos 60, mais 1 por minuto desde então.")
	on_time_world.teardown()
	delayed_world.teardown()


# ---------------------------------------------------------------------------------------------------- morrer no meio de uma ação

func test_an_npc_that_dies_in_the_middle_of_a_work_has_the_action_cancelled_without_its_effects() -> void:
	var food: FakeFood = FakeFood.new()
	food.food = false
	var module: NpcModule = _module(food)
	var world: World = _world(module)
	var npc_id: int = _spawn(module, "farmer")
	_run(world, 40)
	var working: NpcModule.NpcQuery = module.peek_npc(npc_id)
	assert_eq(working.action_id, "work", "Sem comida o agricultor faminto segue a rotina e está trabalhando no minuto 40.")
	var rest_before: int = working.need_values[REST]
	# Adianta o relógio da morte: o limite de 72 horas cai no pensamento do minuto 54, com o trabalho ainda em andamento (vai até o 244).
	var saved: Dictionary = module.serialize()
	var entries: Dictionary = saved["npcs"]
	var entry: Dictionary = entries[str(npc_id)]
	entry["critical_since"] = 45 - LETHAL_HOURS * MINUTES_PER_HOUR
	assert_true(module.on_load(saved).ok)
	_run(world, 20)
	var dead: NpcModule.NpcQuery = module.peek_npc(npc_id)
	assert_false(dead.is_alive)
	assert_eq([dead.action_id, dead.place_id, dead.action_ends_at], ["", "", 0], "Ação cancelada e local liberado.")
	assert_eq(dead.need_values[REST], rest_before, "O trabalho interrompido pela morte não aplicou efeito nenhum (nem o cansaço).")
	assert_eq(_saved_entry(module, npc_id)["died_at"], 54)
	world.teardown()
