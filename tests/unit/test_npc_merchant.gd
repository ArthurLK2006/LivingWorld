extends GutTest
## LW-098f2 (docs/modules/economy.md 9.12 e 9.13; docs/modules/npc.md 14.11): a ação `haul`, a decisão e o emprego do comerciante no `npc`, sem nenhum comerciante no jogo real (população em memória, como a LW-093b). O jogo é MONTADO como o real
## (`GameModules`, dados de `res://data`, rotas e economia reais, build de desenvolvimento) e SEM população: quem nasce é o comerciante que o teste cria. Cenário de lucro: pão barato no A (120) e caro no B (15), como nas tarefas da economia; sem ele
## os preços nascem iguais (dia 0, nenhum par dá lucro). Cobre: o dado (`haul` e a agenda; serialização, compatibilidade e determinismo); só viaja com lucro e fica parado sem diferença; o valor da `haul` é só o `net_profit` do MELHOR plano (mesmo quando não é o primeiro da lista; o `total` do rastro o soma); T1 (a viagem
## não é ação do runner e o NPC em trânsito não pensa, mas a morte vale); T2 (fora de casa); `haul` nunca é candidata a quem não é comerciante; a partida que a economia recusa falha por regra; o ofício `market` não aceita vaga de produção e o NPC em trânsito
## também não; determinismo. Dos números [HIP] só se fixam os de contrato (conta 300, 100%); o resto sai da economia (o plano é a fonte da verdade).

const DATA_DIR: String = "res://data"
const WORLD_DIR: String = "res://data/world"
const BLOCKS_FILE: String = "routine_blocks.json"
const SEED: int = 98
const SETTLEMENT_A: String = "test_settlement_a"
const SETTLEMENT_B: String = "test_settlement_b"
const SETTLEMENT_C: String = "test_settlement_c"
const MARKET_A: String = "a_market_01"
const MARKET_B: String = "b_market_01"
const HOME_A: String = "a_home_01"
const REST_B: String = "b_rest_01"
const MERCHANT: String = "merchant"
const HAUL: String = "haul"
const BREAD: String = "bread"
const HUNGER: int = 0
## Fome com que nasce o comerciante que PRECISA comer no teste (`_rig(..., hungry)`). Desde a regra da refeição (LW-094/B8: condição `eat_hungry`, `need_at_least` na fome, em `data/action_conditions.json`) a `eat` só começa com fome de 40 ou mais, e a fome de partida dos dados é 20:
## o comerciante nasceria sem poder comer ao meio-dia e o T2 (que trata de ONDE ele come, não de quanta fome tem) não teria o que provar. 50 = 10 pontos acima do limiar de 40 (a fome sobe 5 por hora) e abaixo do nível urgente (65).
const HUNGRY_START: int = 50
const SAFETY: int = 2
const MINUTES_PER_HOUR: int = 60
## 17:00: a viagem do A ao B (143 minutos) atravessa as 18h (refeição) e as 19h (conversa) da agenda.
const EVENING: int = 17 * MINUTES_PER_HOUR
const MORNING: int = 7 * MINUTES_PER_HOUR
const EARLY: int = 6 * MINUTES_PER_HOUR + 30
## A agenda do comerciante hora a hora: `haul` no lugar do trabalho (7 a 12 e 13 a 18), refeições às 6, 12 e 18, conversa 19 a 21 e `rest` à noite.
const AGENDA: Array[String] = ["rest", "rest", "rest", "rest", "rest", "rest", "eat", "haul", "haul", "haul", "haul", "haul", "eat", "haul", "haul", "haul", "haul", "haul", "eat", "talk", "talk", "rest", "rest", "rest"]
const OLD_OCCUPATIONS: Array[String] = ["farmer", "lumberjack", "artisan", "guard", "innkeeper", "miner", "shepherd"]

var _data: NpcLifeCheck.GameData
var _places: SettlementService
var _runners: Array[SimulationRunner] = []


class Rig:
	extends RefCounted

	var runner: SimulationRunner
	var economy: EconomyModule
	var npc: NpcModule
	var market_a: int
	var market_b: int
	var arrivals: Array[CaravanArrived] = []


func before_all() -> void:
	_data = NpcLifeCheck.load_game_data()
	assert_eq(_data.problem, "", "Os dados reais do jogo carregam.")
	_places = SettlementService.new(_data.settlements, _data.places)


func after_each() -> void:
	for runner: SimulationRunner in _runners:
		runner.finish()
	_runners.clear()


# ---------------------------------------------------------------------------------------------------- montagem

## O jogo como o real, sem população. `spread`: o cenário de lucro (pão 120 no A e 15 no B); falso = preços iguais. `percent`: o `haul_value_percent` (-1 = o dos dados). `routine`: a tabela de rotina (nulo = a real). `starving`: a fome já nasce crítica e letal em 2 h (a real leva dias; a viagem dura 143 min). `hungry`: a fome nasce em `HUNGRY_START` (a `eat` exige fome de 40 ou mais).
func _rig(start_minute: int, spread: bool = true, percent: int = -1, routine: RoutineTable = null, starving: bool = false, hungry: bool = false) -> Rig:
	var setup: NpcSetup = NpcSetup.from_dir(DATA_DIR, _places, true)
	assert_true(setup.result.ok, setup.result.message)
	setup.definitions.population = null
	if percent >= 0:
		setup.definitions.params.haul_value_percent = percent
	if routine != null:
		setup.routine = routine
	if starving:
		setup.need_defs[HUNGER].start_value = 95
		setup.need_defs[HUNGER].weaken_after_hours = 1
		setup.need_defs[HUNGER].lethal_after_hours = 2
	if hungry:
		setup.need_defs[HUNGER].start_value = HUNGRY_START
	var rig: Rig = Rig.new()
	rig.runner = SimulationRunner.new(SEED, start_minute)
	_runners.append(rig.runner)
	var modules: GameModules = GameModules.register(rig.runner, _data.terrain, _data.points, setup, EconomySetup.from_dir(EconomySetup.DEFAULT_DIR, true), WorldSetup.from_dir(WORLD_DIR, _data.settlements, true))
	assert_true(modules.result.ok, modules.result.message)
	rig.runner.start_new_game()
	rig.runner.world.context.events.subscribe("CaravanArrived", func(event: SimEvent) -> void: rig.arrivals.append(event))
	rig.economy = modules.economy
	rig.npc = modules.npc
	rig.market_a = rig.economy.peek_market_of(SETTLEMENT_A).market_id
	rig.market_b = rig.economy.peek_market_of(SETTLEMENT_B).market_id
	if spread:
		_set_bread(rig, 120, 15)
	return rig


## `in_c` negativo = o mercado do C fica como está.
func _set_bread(rig: Rig, in_a: int, in_b: int, in_c: int = -1) -> void:
	assert_true(rig.economy.request_set_stock(rig.market_a, BREAD, in_a).ok)
	assert_true(rig.economy.request_set_stock(rig.market_b, BREAD, in_b).ok)
	if in_c >= 0:
		assert_true(rig.economy.request_set_stock(rig.economy.peek_market_of(SETTLEMENT_C).market_id, BREAD, in_c).ok)


## Cria um NPC no local dado, com a casa no A (`work_place_id` vazio = sem emprego). Devolve o ID.
func _spawn(rig: Rig, occupation_id: String, settlement_id: String, place_id: String, work_place_id: String = "") -> int:
	var spot: Vector3 = _places.peek_place(place_id).place.position
	var spec: NpcSpec = NpcSpec.new()
	spec.name_key = "npc.name.villager"
	spec.name_number = 1
	spec.occupation_id = occupation_id
	spec.settlement_id = settlement_id
	spec.place_id = place_id
	spec.home_place_id = HOME_A
	spec.work_place_id = work_place_id
	spec.x_cm = roundi(spot.x * TerrainData.CM_PER_METER)
	spec.z_cm = roundi(spot.z * TerrainData.CM_PER_METER)
	var created: NpcModule.CreateResult = rig.npc.request_create_npc(spec)
	assert_true(created.result.ok, created.result.message)
	return created.npc_id


## Anda até `done` valer, no máximo `limit` minutos; devolve se valeu.
func _run_until(rig: Rig, done: Callable, limit: int) -> bool:
	for _minute: int in limit:
		if done.call():
			return true
		rig.runner.step_once()
	return done.call()


func _now(rig: Rig) -> int:
	return rig.runner.world.context.clock.total_minutes()


func _departed(rig: Rig, merchant: int) -> bool:
	return rig.economy.peek_caravan(merchant).found


func _doing(rig: Rig, npc_id: int, action_id: String) -> bool:
	return rig.npc.peek_npc(npc_id).action_id == action_id


## O plano de maior `net_profit` do comerciante no mercado do A (a conta é da economia; o teste só a lê).
func _best_plan(rig: Rig, merchant: int) -> CaravanReplies.PlanQuery:
	var best: CaravanReplies.PlanQuery = null
	for plan: CaravanReplies.PlanQuery in rig.economy.peek_trade_plans(merchant, rig.market_a).plans:
		if best == null or plan.net_profit > best.net_profit:
			best = plan
	return best


func _bread_of(rig: Rig, npc_id: int) -> int:
	for row: Dictionary in rig.economy.peek_inventory(npc_id).rows:
		if row["good_id"] == BREAD:
			return int(row["quantity"])
	return 0


func _conserved(rig: Rig) -> bool:
	return rig.economy.peek_conservation().ok and rig.economy.peek_goods_conservation().ok and rig.economy.validate().is_empty()


## As tabelas de ofício e rotina reais, copiadas, para cada caso poder mudá-las.
func _tables() -> Dictionary[String, Array]:
	var bundle: DataBundle = DataLoader.load_all(DATA_DIR, RoutineLoader.build_schemas())
	assert_true(bundle.is_valid(), bundle.describe_issues())
	var copy: Dictionary[String, Array] = {}
	for table_id: String in bundle.tables:
		copy[table_id] = bundle.tables[table_id].duplicate(true)
	return copy


func _row(tables: Dictionary[String, Array], table_id: String, row_id: String) -> Dictionary:
	for record: Dictionary in tables[table_id]:
		if record["id"] == row_id:
			return record
	fail_test("A linha '%s' não existe em '%s'." % [row_id, table_id])
	return {}


## A rotina real mais dois ofícios só de teste, os dois com `haul` o dia todo: `peddler` (local `market`, conta `npc`: NÃO é comerciante) e `hauler` (local `work`, conta `merchant`: comerciante que pode aceitar vaga de produção).
func _routine_with_extras() -> RoutineTable:
	var tables: Dictionary[String, Array] = _tables()
	tables["occupations"].append({"id": "peddler", "work_place_kind": "market"})
	tables["occupations"].append({"id": "hauler", "work_place_kind": "work", "owner_kind": EconomyModule.KIND_MERCHANT})
	for occupation_id: String in ["peddler", "hauler"]:
		tables["routine_blocks"].append({"id": "%s_00_24" % occupation_id, "occupation_id": occupation_id, "from_hour": 0, "to_hour": 24, "action_id": HAUL})
	var loaded: RoutineLoader.LoadResult = RoutineLoader.from_tables(tables, DATA_DIR)
	assert_true(loaded.result.ok, loaded.result.message)
	return loaded.table


# ---------------------------------------------------------------------------------------------------- dado: `haul` e a agenda

## Tudo que a tabela diz de cada ofício: a ação das 24 horas.
func _digest(table: RoutineTable) -> Array:
	return table.peek_occupation_ids().map(func(occupation_id: String) -> Array: return [occupation_id, range(24).map(func(hour: int) -> String: return table.peek_action(occupation_id, hour).action_id)])


func test_the_haul_row_and_the_merchant_agenda_are_valid_data_that_round_trips_and_stays_compatible() -> void:
	var tables: Dictionary[String, Array] = _tables()
	var table: RoutineTable = RoutineLoader.load_dir().table
	var haul: Dictionary = _row(tables, "actions", HAUL)
	var buy: Dictionary = _row(tables, "actions", "buy")
	assert_eq([haul["place_kind"], haul["duration_min"], haul["risk"]], ["market", buy["duration_min"], buy["risk"]], "Local de mercado e duração e risco baixos como os de `buy`: é o ato de partir.")
	var action: ActionDef = ActionCatalogLoader.load_dir().actions.filter(func(candidate: ActionDef) -> bool: return candidate.id == HAUL)[0]
	assert_eq([action.effects.size(), action.conditions.size(), action.trait_weights.size()], [0, 0, 0], "Sem efeito, condição nem peso de traço na tabela: o valor é derivado e a condição `has_trade_plan` é do provedor.")
	assert_eq(range(24).map(func(hour: int) -> String: return table.peek_action(MERCHANT, hour).action_id), AGENDA as Array, "A agenda do comerciante.")
	for occupation_id: String in OLD_OCCUPATIONS:
		assert_false(range(24).any(func(hour: int) -> bool: return table.peek_action(occupation_id, hour).action_id == HAUL), "%s: só o comerciante tem `haul` na agenda." % occupation_id)
	var rewritten: Dictionary[String, Array] = {}
	for table_id: String in tables:
		var parsed: Variant = JSON.parse_string(JSON.stringify(tables[table_id]))
		assert_eq(typeof(parsed), TYPE_ARRAY)
		rewritten[table_id] = parsed if typeof(parsed) == TYPE_ARRAY else []
	assert_eq(_digest(RoutineLoader.from_tables(rewritten, DATA_DIR).table), _digest(table), "Serialização: as linhas reescritas em JSON e relidas dão a mesma agenda.")
	assert_eq(_digest(RoutineLoader.load_dir().table), _digest(table), "Determinismo: carregar duas vezes dá o mesmo resultado.")
	var old: Dictionary[String, Array] = _tables()
	old["actions"] = old["actions"].filter(func(record: Dictionary) -> bool: return record["id"] != HAUL)
	for block_id: String in ["merchant_07_12", "merchant_13_18"]:
		_row(old, "routine_blocks", block_id)["action_id"] = "rest"
	var before: RoutineLoader.LoadResult = RoutineLoader.from_tables(old, DATA_DIR)
	assert_true(before.result.ok, "Compatibilidade: o catálogo e a agenda de antes da 098f2 (sem `haul`, horas de trabalho em `rest`) seguem válidos: %s" % before.result.message)
	assert_eq(_digest(before.table).filter(func(row: Array) -> bool: return row[0] != MERCHANT), _digest(table).filter(func(row: Array) -> bool: return row[0] != MERCHANT), "Os outros ofícios ficam iguais.")
	var missing: Dictionary[String, Array] = _tables()
	missing["actions"] = missing["actions"].filter(func(record: Dictionary) -> bool: return record["id"] != HAUL)
	var failed: RoutineLoader.LoadResult = RoutineLoader.from_tables(missing, DATA_DIR)
	assert_false(failed.result.ok, "A agenda com `haul` só carrega com a ação no catálogo.")
	for fragment: String in [BLOCKS_FILE, "item 'merchant_07_12'", "campo 'action_id'"]:
		assert_string_contains(failed.result.message, fragment)


# ---------------------------------------------------------------------------------------------------- só viaja com lucro

func test_the_merchant_departs_with_the_best_plan_and_the_value_of_haul_is_only_its_net_profit() -> void:
	for percent: int in [100, 50]:
		var rig: Rig = _rig(EVENING, true, percent)
		var merchant: int = _spawn(rig, MERCHANT, SETTLEMENT_A, MARKET_A, MARKET_A)
		var plan: CaravanReplies.PlanQuery = _best_plan(rig, merchant)
		assert_not_null(plan, "Com a diferença de preço há plano.")
		assert_gt(plan.risk_discount + plan.minutes, 0, "O plano já traz o tempo e o risco da viagem.")
		assert_true(rig.npc.request_set_traced(merchant, true).ok)
		assert_true(_run_until(rig, _doing.bind(rig, merchant, HAUL), 40), "A `haul` é a ação da agenda e o comerciante a escolhe.")
		var record: DecisionTracer.DecisionRecord = rig.npc.explain_decision(merchant).records.back()
		var candidate: DecisionTracer.CandidateRecord = record.candidates.filter(func(row: DecisionTracer.CandidateRecord) -> bool: return row.action_id == HAUL)[0]
		assert_eq([record.chosen_action_id, candidate.source, candidate.benefit], [HAUL, DecisionTracer.REASON_ROUTINE, IntMath.floor_div(plan.net_profit * percent, 100)], "%d%%: o benefício da `haul` é o `net_profit` do melhor plano vezes o percentual, sem descontar tempo e risco de novo." % percent)
		assert_true(_run_until(rig, _departed.bind(rig, merchant), 20), "Ao completar a `haul` a economia recebe a partida.")
		var caravan: CaravanReplies.CaravanQuery = rig.economy.peek_caravan(merchant)
		assert_eq([caravan.destination_market_id, caravan.good_id, caravan.quantity, caravan.cost_paid], [plan.destination_market_id, plan.good_id, plan.quantity, plan.cost], "Parte com o melhor plano.")
		assert_eq([rig.economy.peek_balance(merchant).balance, _conserved(rig)], [300 - plan.cost, true], "O dinheiro sai só pela compra do lote (conta de comerciante: 300).")


## A economia lista os planos por destino crescente (B, depois C) e aqui o melhor é o SEGUNDO (pão caro no C): quem pegasse o primeiro da lista valeria e partiria errado. O `total` do rastro é o que a escolha usa (compete com a inércia e com `rest`): tem de somar o valor da `haul`.
func test_the_best_plan_is_the_one_of_highest_net_profit_even_when_it_is_not_the_first_of_the_list() -> void:
	var rig: Rig = _rig(EVENING, false, 50)
	_set_bread(rig, 120, 20, 60)
	var merchant: int = _spawn(rig, MERCHANT, SETTLEMENT_A, MARKET_A, MARKET_A)
	var plans: Array[CaravanReplies.PlanQuery] = rig.economy.peek_trade_plans(merchant, rig.market_a).plans
	assert_eq(plans.size(), 2, "Há plano para o B e para o C.")
	assert_lt(plans[0].net_profit, plans[1].net_profit, "O melhor plano (o do C) NÃO é o primeiro da lista.")
	assert_true(rig.npc.request_set_traced(merchant, true).ok)
	assert_true(_run_until(rig, _doing.bind(rig, merchant, HAUL), 40))
	var record: DecisionTracer.DecisionRecord = rig.npc.explain_decision(merchant).records.back()
	var candidate: DecisionTracer.CandidateRecord = record.candidates.filter(func(row: DecisionTracer.CandidateRecord) -> bool: return row.action_id == HAUL)[0]
	assert_eq(candidate.benefit, IntMath.floor_div(plans[1].net_profit * 50, 100), "O valor da `haul` é o `net_profit` do MELHOR plano vezes 50%, não o do primeiro da lista.")
	assert_eq(candidate.total, candidate.benefit + candidate.personality - candidate.time_cost - candidate.distance_cost - candidate.risk_cost + candidate.inertia_bonus + candidate.routine_bonus, "O `total` que a escolha usa soma o valor da `haul`, não só o `benefit` do rastro.")
	assert_true(_run_until(rig, _departed.bind(rig, merchant), 20))
	assert_eq(rig.economy.peek_caravan(merchant).destination_market_id, plans[1].destination_market_id, "Parte para o destino do melhor plano (o C).")


func test_a_value_of_zero_makes_haul_no_candidate_and_the_merchant_stays_put() -> void:
	var rig: Rig = _rig(MORNING, true, 0)
	var merchant: int = _spawn(rig, MERCHANT, SETTLEMENT_A, MARKET_A, MARKET_A)
	assert_not_null(_best_plan(rig, merchant), "Há plano, mas ele não vale nada para o NPC.")
	var tried: bool = _run_until(rig, func() -> bool: return _departed(rig, merchant) or _doing(rig, merchant, HAUL), 4 * MINUTES_PER_HOUR)
	assert_false(tried, "`haul_value_percent` 0: a `haul` não é candidata (nem começa) e o comerciante fica parado.")
	assert_true(_doing(rig, merchant, "wait"), "Parado: espera.")


func test_without_a_price_difference_the_merchant_never_travels_in_three_days() -> void:
	var rig: Rig = _rig(EARLY, false)
	var merchant: int = _spawn(rig, MERCHANT, SETTLEMENT_A, MARKET_A, MARKET_A)
	assert_true(rig.economy.peek_trade_plans(merchant, rig.market_a).plans.is_empty(), "Preços iguais: nenhum plano passa dos limiares.")
	var moved: bool = _run_until(rig, func() -> bool: return _departed(rig, merchant) or _doing(rig, merchant, HAUL) or rig.npc.peek_npc(merchant).settlement_id != SETTLEMENT_A, 3 * 24 * MINUTES_PER_HOUR)
	assert_false(moved, "Sem diferença não há `haul` nem viagem em três dias (não oscila).")
	assert_eq([rig.arrivals.size(), rig.npc.peek_npc(merchant).is_alive, _conserved(rig)], [0, true, true])


func test_a_spread_that_closes_before_the_departure_completes_fails_by_rule_and_nothing_moves() -> void:
	var rig: Rig = _rig(EVENING)
	var merchant: int = _spawn(rig, MERCHANT, SETTLEMENT_A, MARKET_A, MARKET_A)
	assert_true(_run_until(rig, _doing.bind(rig, merchant, HAUL), 40))
	_set_bread(rig, 60, 40)
	var closed: bool = _run_until(rig, func() -> bool: return not _doing(rig, merchant, HAUL), 30)
	assert_true(closed, "A `haul` termina (a economia não recebe partida nenhuma).")
	assert_eq([_departed(rig, merchant), rig.economy.peek_balance(merchant).balance, rig.economy.peek_inventory(merchant).rows.size(), _conserved(rig)], [false, 300, 0, true], "Falha por regra: sem plano ao completar, nada é comprado e o comerciante fica livre.")


# ---------------------------------------------------------------------------------------------------- T1 e T2

func test_t1_the_trip_is_no_runner_action_and_the_merchant_in_transit_does_not_think() -> void:
	var rig: Rig = _rig(EVENING)
	var merchant: int = _spawn(rig, MERCHANT, SETTLEMENT_A, MARKET_A, MARKET_A)
	assert_true(_run_until(rig, _departed.bind(rig, merchant), 40))
	var start: NpcModule.NpcQuery = rig.npc.peek_npc(merchant)
	var eta: int = rig.economy.peek_caravan(merchant).eta_minute
	assert_eq([start.action_id, start.place_id, rig.npc.peek_routine_action(MERCHANT, 18).action_id, rig.npc.peek_routine_action(MERCHANT, 19).action_id], ["", MARKET_A, "eat", "talk"], "A viagem não é uma ação do runner e as horas seguintes da agenda mandariam comer e conversar.")
	assert_gt(eta, 19 * MINUTES_PER_HOUR, "A viagem atravessa as 18h e as 19h.")
	var calm: bool = true
	var alarmed: bool = false
	while _now(rig) < eta - 1:
		if not alarmed and _now(rig) >= eta - 60:
			assert_true(rig.npc.request_raise_alarm(start.x_cm, start.z_cm, 5).ok)
			alarmed = true
		rig.runner.step_once()
		var now: NpcModule.NpcQuery = rig.npc.peek_npc(merchant)
		calm = calm and _departed(rig, merchant) and [now.action_id, now.place_id, now.x_cm, now.z_cm, now.need_values[SAFETY]] == ["", MARKET_A, start.x_cm, start.z_cm, 0]
	assert_true(calm, "Em trânsito: nenhuma ação, a posição lógica não muda e nem o alarme no ponto dele o faz pensar.")
	assert_eq(rig.npc.serialize()[NpcModule.KEY_NPCS][str(merchant)][NpcState.KEY_ALARM_UNTIL], NpcState.NO_TIME, "O alarme nem abriu janela para ele.")
	assert_gt(rig.npc.peek_npc(merchant).needs_updated_at, start.needs_updated_at, "As necessidades seguem sendo levadas adiante (e a morte seguiria valendo).")
	rig.runner.step_once()
	assert_eq([_departed(rig, merchant), rig.arrivals.size()], [false, 1], "No minuto do ETA a economia encerra a caravana.")
	assert_true(_run_until(rig, func() -> bool: return not _doing(rig, merchant, ""), 20), "Livre da viagem, o comerciante volta a pensar (a agenda das 19h).")
	assert_true(_conserved(rig))


## A morte vale em trânsito: o `think` leva as necessidades e a checagem letal ANTES de pular o NPC em viagem. Cenário mínimo: a fome nasce crítica e letal em 2 h e a caravana parte pela economia antes do 1º pensamento (que vê a fome crítica); o comerciante tem de morrer 2 h depois, antes do ETA (143 min).
func test_a_starving_merchant_in_transit_still_dies_before_the_trip_ends() -> void:
	var rig: Rig = _rig(EVENING, false, -1, null, true)
	var merchant: int = _spawn(rig, MERCHANT, SETTLEMENT_A, MARKET_A, MARKET_A)
	var started: CaravanReplies.StartResult = rig.economy.request_start_caravan(merchant, rig.market_a, rig.market_b, BREAD, 1)
	assert_true(started.result.ok, started.result.message)
	var died: bool = _run_until(rig, func() -> bool: return not rig.npc.peek_npc(merchant).is_alive, started.eta_minute - _now(rig) - 1)
	assert_true(died, "Em trânsito o pensador ainda leva as necessidades e faz a checagem letal (só depois pula): a fome crítica há 2 h mata antes do ETA.")
	assert_eq([rig.npc.peek_npc(merchant).death_cause, rig.arrivals.size(), _conserved(rig)], ["hunger", 0, true], "Morreu de fome com a caravana ainda na estrada (nada chegou) e a conservação da economia segue valendo.")


func test_t2_away_from_home_the_merchant_rests_where_it_is_and_heads_home_to_eat_from_its_own_cargo() -> void:
	var night: Rig = _rig(0, false)
	var merchant: int = _spawn(night, MERCHANT, SETTLEMENT_B, MARKET_B, MARKET_B)
	var places: Array[String] = []
	for _minute: int in 90:
		night.runner.step_once()
		places.append(night.npc.peek_npc(merchant).settlement_id)
	assert_eq([places.filter(func(settlement_id: String) -> bool: return settlement_id != SETTLEMENT_B), night.npc.peek_npc(merchant).place_id], [[], REST_B], "À noite a agenda manda `rest`, que vale no povoado onde ele está: não anda até a casa em outro povoado.")
	var meal: Rig = _rig(12 * MINUTES_PER_HOUR - 5, false, -1, null, false, true)
	var away: int = _spawn(meal, MERCHANT, SETTLEMENT_B, MARKET_B, MARKET_B)
	assert_true(meal.economy.request_transfer_goods(meal.market_b, away, BREAD, 3).ok)
	assert_true(_run_until(meal, _doing.bind(meal, away, "go_to_place"), 30))
	assert_eq(meal.npc.peek_npc(away).action_target_place_id, HOME_A, "`eat` exige a casa: longe dela o comerciante parte para lá pelo `go_to_place` (o runner serve a qualquer local), sem contrato novo.")
	assert_true(_run_until(meal, func() -> bool: return meal.npc.peek_npc(away).settlement_id == SETTLEMENT_A, 150), "A caminhada atravessa o povoado e a chegada o põe no A.")
	var home: Rig = _rig(12 * MINUTES_PER_HOUR - 5, false, -1, null, false, true)
	var local: int = _spawn(home, MERCHANT, SETTLEMENT_A, MARKET_A, MARKET_A)
	assert_true(home.economy.request_transfer_goods(home.market_a, local, BREAD, 3).ok)
	var hunger: int = home.npc.peek_npc(local).need_values[HUNGER]
	assert_true(_run_until(home, _doing.bind(home, local, "eat"), 40))
	assert_true(_run_until(home, func() -> bool: return _bread_of(home, local) < 3, 30), "A primeira refeição termina.")
	assert_eq([_bread_of(home, local), home.npc.peek_npc(local).need_values[HUNGER] < hunger, _conserved(home)], [2, true, true], "Em casa o consumo sai do inventário dele (`consumed`, legítimo): uma unidade por refeição, e a fome alivia.")


# ---------------------------------------------------------------------------------------------------- quem não é comerciante

func test_haul_is_never_a_candidate_for_a_non_merchant_and_a_refused_completion_changes_nothing() -> void:
	var rig: Rig = _rig(MORNING, true, -1, _routine_with_extras())
	var merchant: int = _spawn(rig, MERCHANT, SETTLEMENT_A, MARKET_A, MARKET_A)
	var peddler: int = _spawn(rig, "peddler", SETTLEMENT_A, MARKET_A, MARKET_A)
	var states: Dictionary[int, NpcState] = {}
	for npc_id: int in [merchant, peddler]:
		states[npc_id] = NpcState.new(npc_id)
		states[npc_id].settlement_id = SETTLEMENT_A
	var trade: MerchantTrade = MerchantTrade.new(rig.economy, states, 100)
	assert_eq([trade.has_trade_plan(peddler), trade.haul_value(peddler), trade.best_plan(IdGenerator.NO_ID), trade.in_transit(IdGenerator.NO_ID), trade.has_trade_plan(merchant)], [false, 0, null, false, true], "Só o comerciante tem plano.")
	assert_eq(trade.haul_value(merchant), _best_plan(rig, merchant).net_profit, "Com 100% o valor é o `net_profit`.")
	var before: String = rig.runner.world.state_hash()
	for npc_id: int in [peddler, IdGenerator.NO_ID]:
		assert_ne(trade.complete(npc_id).problem, "", "Sem plano a conclusão falha por regra.")
	assert_eq(rig.runner.world.state_hash(), before, "A recusa não muda nada.")
	assert_eq(trade.complete(merchant).problem, "")
	assert_true(trade.in_transit(merchant))
	var busy: String = rig.runner.world.state_hash()
	assert_ne(trade.complete(merchant).problem, "", "Já em viagem a economia recusa a segunda partida (`ECON_CARAVAN_BUSY`).")
	assert_eq(rig.runner.world.state_hash(), busy, "A recusa não muda nada.")
	var traveller: bool = _run_until(rig, func() -> bool: return _doing(rig, peddler, HAUL) or _departed(rig, peddler), 5 * MINUTES_PER_HOUR)
	assert_false(traveller, "Mesmo com `haul` na agenda dele o NPC de conta `npc` nunca a escolhe nem parte.")
	assert_true(_conserved(rig))


# ---------------------------------------------------------------------------------------------------- emprego

## A economia já recusa a vaga de quem não é do tipo `npc` (`ECON_CONTRACT_IMPOSSIBLE`); o que o `npc` precisa evitar é o comerciante ser o MELHOR candidato e, recusado, tomar a vez de quem aceitaria: sem o filtro, no empate de utilidade
## ganha o menor ID e a vaga fica sem ninguém. Por isso o comerciante nasce ANTES do guarda (menor ID, sem emprego os dois, sem bônus de ofício para nenhum) e o teste confere que o guarda pega a vaga.
func test_the_merchant_does_not_take_a_production_vacancy_nor_the_turn_of_a_worker_who_would() -> void:
	var rig: Rig = _rig(MORNING, false)
	var merchant: int = _spawn(rig, MERCHANT, SETTLEMENT_A, MARKET_A)
	var guard: int = _spawn(rig, "guard", SETTLEMENT_A, MARKET_A)
	assert_true(_run_until(rig, func() -> bool: return not rig.npc.peek_npc(guard).work_place_id.is_empty(), 3 * MINUTES_PER_HOUR), "O guarda sem emprego pega uma vaga (a economia as posta na primeira hora).")
	assert_eq(rig.npc.peek_npc(merchant).work_place_id, "", "O comerciante (ofício de local `market`) continua sem vaga de produção e continua comerciante.")


func test_a_merchant_in_transit_does_not_take_the_turn_of_a_worker_on_a_vacancy() -> void:
	var rig: Rig = _rig(MORNING, true, -1, _routine_with_extras())
	var hauler: int = _spawn(rig, "hauler", SETTLEMENT_A, MARKET_A)
	var guard: int = _spawn(rig, "guard", SETTLEMENT_A, MARKET_A)
	assert_true(_run_until(rig, _departed.bind(rig, hauler), 60), "O `hauler` (ofício de local `work` e conta `merchant`, só de teste) parte.")
	var eta: int = rig.economy.peek_caravan(hauler).eta_minute
	assert_true(_run_until(rig, func() -> bool: return not rig.npc.peek_npc(guard).work_place_id.is_empty() or _now(rig) >= eta - 1, 4 * MINUTES_PER_HOUR))
	assert_true(_departed(rig, hauler) and _now(rig) < eta - 1, "O guarda pega a vaga que a economia postou às 8h com o comerciante ainda em viagem: em trânsito ele não concorre (menor ID, ofício `work`: sem isso ganharia o empate).")
	assert_eq(rig.npc.peek_npc(hauler).work_place_id, "")


# ---------------------------------------------------------------------------------------------------- determinismo

func test_the_same_world_gives_the_same_trips_and_the_same_hash() -> void:
	var digests: Array = []
	for _run: int in 2:
		var rig: Rig = _rig(MORNING)
		var merchant: int = _spawn(rig, MERCHANT, SETTLEMENT_A, MARKET_A, MARKET_A)
		rig.runner.run_days(1)
		digests.append([rig.runner.world.state_hash(), rig.arrivals.size(), rig.economy.peek_balance(merchant).balance, _conserved(rig)])
	assert_eq(digests[0], digests[1], "Mesma semente e mesmos pedidos dão o mesmo mundo.")
	assert_gt(digests[0][1], 0, "O comerciante viajou e chegou.")
