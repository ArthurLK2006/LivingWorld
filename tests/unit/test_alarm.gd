extends GutTest
## LW-076: personalidade e alarme (docs/modules/npc.md, seção 8), sem janela. `request_raise_alarm` (só em build de desenvolvimento) publica
## `AlarmRaised`; os NPCs vivos no raio PENSAM JÁ, com a pressão de `safety` somada e as ações `flee` e `help` entre as candidatas, e a ação em
## andamento é interrompida com efeito proporcional se uma reação vencer; quem ignora segue a vida e quem reage volta à rotina depois. O mesmo
## alarme faz o NPC cauteloso fugir, o leal e sociável ajudar e o frio ignorar. Mundo de teste montado à mão, com contas fáceis de conferir:
## cada NPC tem a nota de cada reação calculada no comentário do teste.

const VILLAGE: String = "village_a"
const HOME: String = "home_a1"
const WORK: String = "work_a1"
const NEED_IDS: Array[String] = ["hunger", "rest", "safety", "income", "social"]
const TRAIT_IDS: Array[String] = ["caution", "sociability", "ambition", "loyalty"]
const REST: int = 1
const SAFETY: int = 2
const HOME_X_CM: int = 8400
const WORK_X_CM: int = 18400
const THINK_INTERVAL: int = 10
const RADIUS_M: int = 150
const PRESSURE: int = 40
const WINDOW_MIN: int = 30
const DATA_DIR: String = "res://data"
const WORLD_DIR: String = "res://data/world"
## Traços (cautela, sociabilidade, ambição, lealdade).
const COWARD: Array[int] = [95, 10, 50, 10]
const HELPER: Array[int] = [5, 90, 50, 95]
const STOIC: Array[int] = [5, 5, 50, 5]


# ---------------------------------------------------------------------------------------------------- mundo de teste

func _need_defs() -> Array[NeedDef]:
	var defs: Array[NeedDef] = []
	for position: int in NEED_IDS.size():
		if position == SAFETY:
			defs.append(NeedDef.new(NEED_IDS[position], position, 0, 0, 30, 60, 85))
		else:
			defs.append(NeedDef.new(NEED_IDS[position], position, 0, 0, 40, 65, 90))
	return defs


func _action(action_id: String, duration: int, place_kind: String, risk: int = 0) -> ActionDef:
	return ActionDef.new(action_id, duration, place_kind, risk, true)


func _catalog() -> Array[ActionDef]:
	var work: ActionDef = _action("work", 240, "work", 5)
	work.effects.append(ActionDef.ActionEffect.new("rest", 5))
	var flee: ActionDef = _action("flee", 20, "home")
	flee.effects.append(ActionDef.ActionEffect.new("safety", -40))
	flee.trait_weights.append(ActionDef.ActionTraitWeight.new("caution", 20))
	var help: ActionDef = _action("help", 20, "", 10)
	help.effects.append(ActionDef.ActionEffect.new("safety", -20))
	help.trait_weights.append(ActionDef.ActionTraitWeight.new("loyalty", 20))
	help.trait_weights.append(ActionDef.ActionTraitWeight.new("sociability", 10))
	help.trait_weights.append(ActionDef.ActionTraitWeight.new("caution", -10))
	return [work, flee, help, _action("wait", 10, ""), _action(ActionRunner.GO_TO_PLACE_ID, 0, "")]


func _routine() -> RoutineTable:
	var occupations: Array[RoutineTable.OccupationDef] = [RoutineTable.OccupationDef.new("tester", "work")]
	var blocks: Array[RoutineTable.RoutineBlock] = [RoutineTable.RoutineBlock.new("t", "tester", 0, 24, "work")]
	return RoutineTable.new(occupations, blocks)


func _places() -> SettlementService:
	var settlements: Array[Settlement] = [Settlement.new(VILLAGE, "settlement.a", Vector3.ZERO)]
	var places: Array[Place] = [
		Place.new(HOME, VILLAGE, Place.KIND_HOME, Vector3(84.0, 0.0, 0.0), 5), Place.new(WORK, VILLAGE, Place.KIND_WORK, Vector3(184.0, 0.0, 0.0), 5),
		Place.new("rest_a1", VILLAGE, Place.KIND_REST, Vector3(300.0, 0.0, 0.0), 5),
	]
	return SettlementService.new(settlements, places)


func _params(top_k: int = 1, margin: int = 0) -> NpcParams:
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
	params.decision_top_k = top_k
	params.decision_margin = margin
	params.alarm_radius_m = RADIUS_M
	params.alarm_safety_pressure = PRESSURE
	params.alarm_window_min = WINDOW_MIN
	return params


func _module(is_development_build: bool = true, top_k: int = 1, margin: int = 0) -> NpcModule:
	var definitions: NpcModule.Definitions = NpcModule.Definitions.new()
	definitions.actions = _catalog()
	var traits: Array[TraitLoader.TraitDef] = []
	for position: int in TRAIT_IDS.size():
		traits.append(TraitLoader.TraitDef.new(TRAIT_IDS[position], position))
	definitions.traits = traits
	definitions.params = _params(top_k, margin)
	definitions.places = _places()
	definitions.is_development_build = is_development_build
	return NpcModule.new(_need_defs(), _routine(), definitions)


func _world(module: NpcModule, world_seed: int = 3) -> World:
	var clock: SimClock = SimClock.new()
	var world: World = World.new(SimContext.new(clock, EventBus.new(clock), WorldRng.new(world_seed), IdGenerator.new()))
	assert_true(world.register_module("npc", module).ok)
	world.setup()
	world.post_setup()
	return world


## NPC em casa (ou em `x_cm`) com os traços dados; sem ofício ele só espera, com ofício "tester" segue a rotina de trabalho.
func _spawn(module: NpcModule, traits: Array[int], occupation_id: String = "", x_cm: int = HOME_X_CM) -> int:
	var spec: NpcSpec = NpcSpec.new()
	spec.name_key = "npc.name.villager"
	spec.occupation_id = occupation_id
	spec.settlement_id = VILLAGE
	spec.place_id = HOME
	spec.home_place_id = HOME
	spec.work_place_id = WORK
	spec.x_cm = x_cm
	spec.traits = PackedInt64Array(traits)
	var created: NpcModule.CreateResult = module.request_create_npc(spec)
	assert_true(created.result.ok, created.result.message)
	return created.npc_id


## Um minuto por vez, como o SimulationRunner: relógio, módulos e entrega dos eventos (é aí que o alarme chega ao `npc`).
func _run(world: World, minutes: int) -> void:
	for _step: int in minutes:
		world.context.clock.advance_step()
		world.tick(1)
		world.context.events.dispatch()


func _entry(module: NpcModule, npc_id: int) -> Dictionary:
	var entries: Dictionary = module.serialize()["npcs"]
	var entry: Dictionary = entries[str(npc_id)]
	return entry


# ---------------------------------------------------------------------------------------------------- o comando

func test_only_development_builds_can_raise_an_alarm_and_the_request_is_validated() -> void:
	var production: NpcModule = _module(false)
	var production_world: World = _world(production)
	var refused: Result = production.request_raise_alarm(18400, 0, 1)
	assert_eq(refused.code, NpcModule.CODE_DEV_ONLY)
	assert_eq(NpcModule.new().request_raise_alarm(1, 1, 1).code, NpcModule.CODE_DEV_ONLY, "Módulo sem definições também não é desenvolvimento.")
	var development: NpcModule = _module(true)
	var world: World = _world(development)
	var heard: Array[AlarmRaised] = []
	world.context.events.subscribe("AlarmRaised", func(event: SimEvent) -> void: heard.append(event as AlarmRaised))
	for bad: Array in [[18400, 0, 0], [18400, 0, 11], [-1, 0, 1], [18400, -1, 1], [NpcState.MAX_COORDINATE_CM + 1, 0, 1], [0, NpcState.MAX_COORDINATE_CM + 1, 1]]:
		var invalid: Result = development.request_raise_alarm(bad[0], bad[1], bad[2])
		assert_false(invalid.ok, "Pedido %s deveria ser recusado." % str(bad))
		assert_eq(invalid.code, NpcModule.CODE_INVALID_ALARM)
	world.context.events.dispatch()
	assert_eq(heard.size(), 0, "Pedido recusado não publica nada.")
	assert_true(development.request_raise_alarm(18400, 0, 3).ok)
	world.context.events.dispatch()
	assert_eq(heard.size(), 1)
	assert_eq([heard[0].type, heard[0].x_cm, heard[0].z_cm, heard[0].severity], ["AlarmRaised", 18400, 0, 3], "A gravidade vai no campo severity do evento.")
	production_world.teardown()
	world.teardown()


# ---------------------------------------------------------------------------------------------------- a personalidade decide

## Notas de cada NPC parado em casa quando o alarme soa a 100 m (ponto do trabalho), gravidade 1 (segurança 0 + 40: atenção, peso 1):
## fugir = alívio 40 x 1 + piso((cautela - 50) x 20 / 50); ajudar = alívio 20 x 1 + personalidade (lealdade 20, sociabilidade 10, cautela -10) - distância 2 - risco 10;
## continuar esperando = inércia 25.   Covarde: fugir 40 + 18 = 58, ajudar 20 - 33 - 12 = -25, esperar 25 -> FOGE.
## Leal e sociável: fugir 40 - 18 = 22, ajudar 20 + 35 - 12 = 43, esperar 25 -> AJUDA.   Frio: fugir 22, ajudar 20 - 18 - 12 = -10, esperar 25 -> IGNORA.
func test_the_same_alarm_makes_the_coward_flee_the_helper_help_and_the_stoic_ignore() -> void:
	var module: NpcModule = _module()
	var world: World = _world(module)
	var coward: int = _spawn(module, COWARD)
	var helper: int = _spawn(module, HELPER)
	var stoic: int = _spawn(module, STOIC)
	_run(world, 14)
	var serial_before: int = module.peek_npc(stoic).action_serial
	assert_eq(module.peek_npc(stoic).action_id, "wait", "Antes do alarme os três esperam.")
	assert_true(module.request_raise_alarm(WORK_X_CM, 0, 1).ok)
	_run(world, 1)
	var fled: NpcModule.NpcQuery = module.peek_npc(coward)
	assert_eq([fled.action_id, fled.action_target_place_id, fled.need_values[SAFETY]], ["flee", HOME, PRESSURE], "O cauteloso foge: já está em casa, começa a fuga.")
	var helping: NpcModule.NpcQuery = module.peek_npc(helper)
	assert_eq([helping.action_id, helping.action_target_place_id, helping.need_values[SAFETY]], [ActionRunner.GO_TO_PLACE_ID, WORK, PRESSURE], "O leal e sociável vai ajudar: primeiro anda até o local mais próximo do ponto do alarme.")
	var ignoring: NpcModule.NpcQuery = module.peek_npc(stoic)
	assert_eq([ignoring.action_id, ignoring.action_serial, ignoring.need_values[SAFETY]], ["wait", serial_before, PRESSURE], "O frio ignora: a espera continua, a mesma ação, mas a pressão subiu.")
	_run(world, 3)
	var arrived: NpcModule.NpcQuery = module.peek_npc(helper)
	assert_eq([arrived.action_id, arrived.place_id], ["help", WORK], "Chegou e começou a ajudar (a janela do alarme manteve a reação viva depois do primeiro pensamento).")
	world.teardown()


func test_the_reaction_follows_the_personality_not_the_order_of_the_npcs() -> void:
	var trait_sets: Array[Array] = [COWARD, HELPER, STOIC]
	var actions_by_traits: Dictionary = {}
	for shift: int in 3:
		var module: NpcModule = _module()
		var world: World = _world(module)
		var ids: Array[int] = []
		for index: int in 3:
			var traits: Array[int] = []
			traits.assign(trait_sets[(index + shift) % 3])
			ids.append(_spawn(module, traits))
		_run(world, 14)
		assert_true(module.request_raise_alarm(WORK_X_CM, 0, 1).ok)
		_run(world, 1)
		for index: int in 3:
			actions_by_traits[str(trait_sets[(index + shift) % 3])] = module.peek_npc(ids[index]).action_id
		world.teardown()
	assert_eq(actions_by_traits[str(COWARD)], "flee")
	assert_eq(actions_by_traits[str(HELPER)], ActionRunner.GO_TO_PLACE_ID)
	assert_eq(actions_by_traits[str(STOIC)], "wait")


# ---------------------------------------------------------------------------------------------------- raio, gravidade, quem não reage

func test_the_radius_is_inclusive_and_only_living_npcs_inside_it_react() -> void:
	var module: NpcModule = _module()
	var world: World = _world(module)
	var radius_cm: int = RADIUS_M * 100
	var inside_edge: int = _spawn(module, COWARD, "", WORK_X_CM - radius_cm)
	var outside_edge: int = _spawn(module, COWARD, "", WORK_X_CM - radius_cm - 1)
	var dead: int = _spawn(module, COWARD)
	var saved: Dictionary = module.serialize()
	var entries: Dictionary = saved["npcs"]
	var dead_entry: Dictionary = entries[str(dead)]
	dead_entry["is_alive"] = false
	dead_entry["death_cause"] = "hunger"
	dead_entry["died_at"] = 1
	assert_true(module.on_load(saved).ok)
	_run(world, 14)
	assert_true(module.request_raise_alarm(WORK_X_CM, 0, 1).ok)
	_run(world, 1)
	assert_eq(module.peek_npc(inside_edge).need_values[SAFETY], PRESSURE, "Exatamente no raio: reage.")
	assert_eq(_entry(module, inside_edge)["alarm_until"], 15 + WINDOW_MIN)
	assert_eq(module.peek_npc(outside_edge).need_values[SAFETY], 0, "1 cm além do raio: nada.")
	assert_eq(_entry(module, outside_edge)["alarm_until"], NpcState.NO_TIME)
	assert_eq(module.peek_npc(dead).need_values[SAFETY], 0, "Morto não reage.")
	assert_eq([_entry(module, dead)["alarm_until"], _entry(module, dead)["alarm_place_id"]], [NpcState.NO_TIME, ""], "Morto também não guarda a janela do alarme.")
	assert_eq(module.validate().size(), 0, str(module.validate()))
	world.teardown()


func test_severity_multiplies_the_pressure_and_the_value_never_passes_100() -> void:
	var module: NpcModule = _module()
	var world: World = _world(module)
	var first: int = _spawn(module, STOIC)
	_run(world, 14)
	assert_true(module.request_raise_alarm(WORK_X_CM, 0, 2).ok)
	_run(world, 1)
	assert_eq(module.peek_npc(first).need_values[SAFETY], 2 * PRESSURE, "Gravidade 2: o dobro da pressão do arquivo.")
	assert_true(module.request_raise_alarm(WORK_X_CM, 0, 10).ok)
	_run(world, 1)
	assert_eq(module.peek_npc(first).need_values[SAFETY], 100, "Gravidade 10: limitada a 100.")
	world.teardown()


# ---------------------------------------------------------------------------------------------------- interrupção e retomada da rotina

## Covarde com ofício, trabalhando desde o minuto 4 (anda de 2 a 4). O alarme soa no minuto 60: o trabalho tem 56 de 240 minutos cumpridos
## (progresso 233 de 1000, descanso +1), a fuga (58 - 2 de distância = 56) vence a continuação do trabalho (25 + 40 - 8 - 5 = 52), ele anda até
## casa (2 min), foge por 20 min e, passada a fuga (segurança volta a 0), a rotina de trabalho volta.
func test_a_working_coward_is_interrupted_with_a_proportional_effect_flees_and_then_the_routine_returns() -> void:
	var module: NpcModule = _module()
	var world: World = _world(module)
	var coward: int = _spawn(module, COWARD, "tester")
	assert_true(module.request_set_traced(coward, true).ok)
	_run(world, 59)
	assert_eq(module.peek_npc(coward).action_id, "work")
	assert_eq(module.peek_npc(coward).need_values[REST], 0)
	assert_true(module.request_raise_alarm(WORK_X_CM, 0, 1).ok)
	_run(world, 1)
	var interrupted: NpcModule.NpcQuery = module.peek_npc(coward)
	assert_eq(interrupted.action_id, ActionRunner.GO_TO_PLACE_ID, "Interrompeu o trabalho e saiu para casa.")
	assert_eq(interrupted.action_target_place_id, HOME)
	assert_eq(interrupted.need_values[REST], 1, "O trabalho interrompido aplicou o efeito proporcional: piso de 5 x 233 / 1000.")
	assert_eq(interrupted.need_values[SAFETY], PRESSURE)
	_run(world, 2)
	var fleeing: NpcModule.NpcQuery = module.peek_npc(coward)
	assert_eq([fleeing.action_id, fleeing.place_id], ["flee", HOME], "Em casa, a fuga começa (a janela do alarme manteve a reação).")
	_run(world, 20)
	assert_eq(module.peek_npc(coward).need_values[SAFETY], 0, "A fuga acabou e aliviou a segurança.")
	_run(world, 40)
	var back: NpcModule.NpcQuery = module.peek_npc(coward)
	assert_eq(back.action_id, "work", "Passada a reação, o pensamento seguinte devolve a rotina da hora.")
	assert_eq(back.place_id, WORK)
	var reasons: Array[String] = []
	for record: DecisionTracer.DecisionRecord in module.explain_decision(coward).records:
		reasons.append(record.reason)
	assert_true(reasons.has(DecisionTracer.REASON_ROUTINE), "O rastro mostra a rotina de volta: %s" % str(reasons))
	world.teardown()


func test_the_trace_marks_the_reaction_as_interruption_and_lists_flee_and_help() -> void:
	var module: NpcModule = _module()
	var world: World = _world(module)
	var coward: int = _spawn(module, COWARD)
	assert_true(module.request_set_traced(coward, true).ok)
	_run(world, 14)
	assert_true(module.request_raise_alarm(WORK_X_CM, 0, 1).ok)
	_run(world, 1)
	var records: Array[DecisionTracer.DecisionRecord] = module.explain_decision(coward).records
	var last: DecisionTracer.DecisionRecord = records[records.size() - 1]
	assert_eq([last.reason, last.chosen_action_id], [DecisionTracer.REASON_INTERRUPTION, "flee"])
	var sources: Dictionary = {}
	for candidate: DecisionTracer.CandidateRecord in last.candidates:
		sources[candidate.action_id] = candidate.source
	assert_eq(sources.get("flee"), DecisionTracer.REASON_INTERRUPTION)
	assert_eq(sources.get("help"), DecisionTracer.REASON_INTERRUPTION)
	assert_eq(sources.get("wait"), DecisionTracer.REASON_INERTIA, "Continuar esperando (ignorar) também estava entre as candidatas.")
	assert_eq(last.candidates[0].action_id, "flee", "A melhor nota vem primeiro.")
	world.teardown()


func test_a_second_alarm_during_the_flight_keeps_the_same_flight() -> void:
	var module: NpcModule = _module()
	var world: World = _world(module)
	var coward: int = _spawn(module, COWARD)
	assert_true(module.request_set_traced(coward, true).ok)
	_run(world, 14)
	assert_true(module.request_raise_alarm(WORK_X_CM, 0, 1).ok)
	_run(world, 1)
	var serial: int = module.peek_npc(coward).action_serial
	assert_eq(module.peek_npc(coward).action_id, "flee")
	_run(world, 5)
	assert_true(module.request_raise_alarm(WORK_X_CM, 0, 1).ok)
	_run(world, 1)
	var again: NpcModule.NpcQuery = module.peek_npc(coward)
	assert_eq([again.action_id, again.action_serial], ["flee", serial], "A fuga em andamento não recomeça.")
	assert_eq(again.need_values[SAFETY], 2 * PRESSURE, "Mas a pressão do segundo alarme se soma.")
	var records: Array[DecisionTracer.DecisionRecord] = module.explain_decision(coward).records
	var flee_candidates: Array[DecisionTracer.CandidateRecord] = []
	for candidate: DecisionTracer.CandidateRecord in records[records.size() - 1].candidates:
		if candidate.action_id == "flee":
			flee_candidates.append(candidate)
	assert_eq(flee_candidates.size(), 1, "Quem já está fugindo não ganha uma segunda candidata de fuga igual.")
	assert_true(flee_candidates[0].is_current, "A única candidata é a própria fuga em andamento (a segurança está urgente, então ela entra como alívio da necessidade).")
	world.teardown()


# ---------------------------------------------------------------------------------------------------- save, determinismo e dados reais

func _hash_of_a_busy_run(world_seed: int, save_at_minute: int) -> String:
	var module: NpcModule = _module(true, 3, 15)
	var world: World = _world(module, world_seed)
	for traits: Array in [COWARD, HELPER, STOIC, COWARD, HELPER]:
		var typed: Array[int] = []
		typed.assign(traits)
		_spawn(module, typed, "tester")
	var active_world: World = world
	_run(active_world, 40)
	assert_true(module.request_raise_alarm(WORK_X_CM, 0, 1).ok)
	_run(active_world, save_at_minute - 40 if save_at_minute > 0 else 120)
	if save_at_minute > 0:
		var parsed: Variant = JSON.parse_string(JSON.stringify(active_world.serialize(), "", true, true))
		var saved: Dictionary = parsed
		var other_module: NpcModule = _module(true, 3, 15)
		var other_world: World = _world(other_module, world_seed)
		var loaded: Result = other_world.on_load(saved)
		assert_true(loaded.ok, loaded.message)
		active_world.teardown()
		active_world = other_world
		_run(active_world, 120 - (save_at_minute - 40))
	var result: String = active_world.state_hash()
	active_world.teardown()
	return result


func test_the_same_seed_gives_the_same_world_and_saving_in_the_middle_of_a_flight_changes_nothing() -> void:
	var direct: String = _hash_of_a_busy_run(7, 0)
	assert_eq(_hash_of_a_busy_run(7, 0), direct, "Mesma semente, mesmo mundo com alarme.")
	assert_eq(_hash_of_a_busy_run(7, 50), direct, "Salvar e carregar durante a reação (a janela do alarme vai no save) dá o mesmo mundo.")


func test_the_alarm_window_goes_into_the_save_and_old_saves_load_without_it() -> void:
	var module: NpcModule = _module()
	var world: World = _world(module)
	var coward: int = _spawn(module, COWARD)
	_run(world, 14)
	assert_true(module.request_raise_alarm(WORK_X_CM, 0, 1).ok)
	_run(world, 1)
	var entry: Dictionary = _entry(module, coward)
	assert_eq([entry["alarm_until"], entry["alarm_place_id"]], [15 + WINDOW_MIN, WORK])
	var saved: Dictionary = module.serialize()
	var entries: Dictionary = saved["npcs"]
	var raw: Dictionary = entries[str(coward)]
	raw.erase("alarm_until")
	raw.erase("alarm_place_id")
	assert_true(module.on_load(saved).ok, "Save de antes da LW-076 carrega.")
	assert_eq([_entry(module, coward)["alarm_until"], _entry(module, coward)["alarm_place_id"]], [NpcState.NO_TIME, ""])
	raw["alarm_until"] = "logo"
	assert_string_contains(module.on_load(saved).message, "alarm_until")
	raw["alarm_until"] = 5
	raw["alarm_place_id"] = 7
	assert_string_contains(module.on_load(saved).message, "alarm_place_id")
	raw["alarm_place_id"] = ""
	raw["alarm_until"] = -7
	assert_true(module.on_load(saved).ok)
	assert_string_contains(str(module.validate()), "alarm_until -7 inválido")
	world.teardown()


func test_the_real_world_a_village_reacts_the_other_far_away_does_not_and_life_goes_on() -> void:
	var terrain_loaded: TerrainLoader.LoadResult = TerrainLoader.load_dir(WORLD_DIR)
	assert_true(terrain_loaded.result.ok, terrain_loaded.result.message)
	var settlements_loaded: SettlementLoader.LoadResult = SettlementLoader.load_dir(WORLD_DIR, terrain_loaded.terrain)
	assert_true(settlements_loaded.result.ok, settlements_loaded.result.message)
	var setup: NpcSetup = NpcSetup.from_dir(DATA_DIR, SettlementService.new(settlements_loaded.settlements, settlements_loaded.places), true)
	assert_true(setup.result.ok, setup.result.message)
	var runner: SimulationRunner = SimulationRunner.new(5)
	var modules: GameModules = GameModules.register(runner, terrain_loaded.terrain, [], setup)
	assert_true(modules.result.ok, modules.result.message)
	runner.start_new_game()
	runner.run_steps(600)
	var center_x: int = 32000
	var center_z: int = 54000
	assert_true(modules.npc.request_raise_alarm(center_x, center_z, 1).ok)
	runner.step_once()
	var reacting: int = 0
	var fleeing_or_helping: int = 0
	var calm_ids: int = 0
	for npc_id: int in modules.npc.peek_npc_ids():
		var query: NpcModule.NpcQuery = modules.npc.peek_npc(npc_id)
		var entry: Dictionary = _entry(modules.npc, npc_id)
		if query.settlement_id == "test_settlement_a":
			if int(entry["alarm_until"]) > 0:
				reacting += 1
			if query.action_id == "flee" or query.action_id == "help" or (query.action_id == ActionRunner.GO_TO_PLACE_ID and query.need_values[SAFETY] > 0):
				fleeing_or_helping += 1
			else:
				calm_ids += 1
		else:
			assert_eq(int(entry["alarm_until"]), NpcState.NO_TIME, "O NPC %d do povoado distante não reage." % npc_id)
			assert_eq(query.need_values[SAFETY], 0)
	assert_eq(reacting, 60, "O povoado inteiro está no raio do alarme.")
	assert_gt(fleeing_or_helping, 0, "Alguns fogem ou ajudam.")
	assert_gt(calm_ids, 0, "Outros ignoram e seguem a vida.")
	runner.run_steps(180)
	for npc_id: int in modules.npc.peek_npc_ids():
		var later: NpcModule.NpcQuery = modules.npc.peek_npc(npc_id)
		assert_true(later.is_alive)
		assert_false(later.action_id.is_empty(), "NPC %d continua com alguma coisa a fazer três horas depois." % npc_id)
	assert_eq(runner.world.validate().size(), 0, str(runner.world.validate()))
	runner.finish()
