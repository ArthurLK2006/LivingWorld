extends GutTest
## LW-098h1 (docs/modules/economy.md, 9.15.3): o verificador de NPC travado (`NpcLifeCheck.check_npcs`) distingue o comerciante em trânsito do erro. Montagem como a de test_npc_merchant.gd: o jogo como o real
## (`GameModules`, dados de `res://data`, economia e rotas reais, build de desenvolvimento), SEM população e só com os NPCs que cada caso cria. As viagens de V1 e V5 são as REAIS (a `haul` da agenda, o relógio
## andando); o que a viagem sozinha não produz (registro inconsistente, `held` com rotas abertas, a chegada num instante escolhido) entra pelo save da economia, como em test_economy_caravan_start.gd, e aí o relógio
## NÃO anda (o NPC criado não pensa e segue sem ação; o `minute` de cada amostra é só o argumento). Casos V1 a V8 do contrato, mais o `with_economy` do `run` e o `is_transit_exempt` com um morto.

const DATA_DIR: String = "res://data"
const WORLD_DIR: String = "res://data/world"
const SEED: int = 98
const SETTLEMENT_A: String = "test_settlement_a"
const SETTLEMENT_B: String = "test_settlement_b"
const MARKET_A: String = "a_market_01"
const HOME_A: String = "a_home_01"
const MERCHANT: String = "merchant"
const GUARD: String = "guard"
const BREAD: String = "bread"
## 17:00: a `haul` da agenda do comerciante parte logo (a viagem do A ao B leva 143 minutos).
const EVENING: int = 17 * 60
const SAMPLE: int = NpcLifeCheck.SAMPLE_EVERY_MIN
## A margem do contrato (D2, [HIP]: uma amostra, 15 min), escrita AQUI de propósito: o teste não pode seguir a constante do verificador, senão mudá-la mudaria os dois lados juntos.
const MARGIN: int = 15
## A 5ª amostra seguida sem ação (75 min, mais que os MAX_IDLE_MIN 60) é a que o verificador acusa.
const FLAGGED_AT: int = 5

var _data: NpcLifeCheck.GameData
var _places: SettlementService
var _runners: Array[SimulationRunner] = []


class Rig:
	extends RefCounted

	var runner: SimulationRunner
	var economy: EconomyModule
	var routes: WorldModule
	var npc: NpcModule
	var market_a: int
	var market_b: int


func before_all() -> void:
	_data = NpcLifeCheck.load_game_data()
	assert_eq(_data.problem, "", "Os dados reais do jogo carregam.")
	_places = SettlementService.new(_data.settlements, _data.places)


func after_each() -> void:
	for runner: SimulationRunner in _runners:
		runner.finish()
	_runners.clear()


# ---------------------------------------------------------------------------------------------------- montagem

## O jogo como o real, sem população, com o pão a 120 no A e a 15 no B (há lucro: o comerciante parte pela `haul`).
func _rig(start_minute: int) -> Rig:
	var setup: NpcSetup = NpcSetup.from_dir(DATA_DIR, _places, true)
	assert_true(setup.result.ok, setup.result.message)
	setup.definitions.population = null
	var rig: Rig = Rig.new()
	rig.runner = SimulationRunner.new(SEED, start_minute)
	_runners.append(rig.runner)
	var modules: GameModules = GameModules.register(rig.runner, _data.terrain, _data.points, setup, EconomySetup.from_dir(EconomySetup.DEFAULT_DIR, true), WorldSetup.from_dir(WORLD_DIR, _data.settlements, true))
	assert_true(modules.result.ok, modules.result.message)
	rig.runner.start_new_game()
	rig.economy = modules.economy
	rig.routes = modules.world
	rig.npc = modules.npc
	rig.market_a = rig.economy.peek_market_of(SETTLEMENT_A).market_id
	rig.market_b = rig.economy.peek_market_of(SETTLEMENT_B).market_id
	assert_true(rig.economy.request_set_stock(rig.market_a, BREAD, 120).ok)
	assert_true(rig.economy.request_set_stock(rig.market_b, BREAD, 15).ok)
	return rig


## Cria um NPC no mercado do A (o comerciante com o emprego lá). Devolve o ID.
func _spawn(rig: Rig, occupation_id: String) -> int:
	var spot: Vector3 = _places.peek_place(MARKET_A).place.position
	var spec: NpcSpec = NpcSpec.new()
	spec.name_key = "npc.name.villager"
	spec.name_number = 1
	spec.occupation_id = occupation_id
	spec.settlement_id = SETTLEMENT_A
	spec.place_id = MARKET_A
	spec.home_place_id = HOME_A
	spec.work_place_id = MARKET_A if occupation_id == MERCHANT else ""
	spec.x_cm = roundi(spot.x * TerrainData.CM_PER_METER)
	spec.z_cm = roundi(spot.z * TerrainData.CM_PER_METER)
	var created: NpcModule.CreateResult = rig.npc.request_create_npc(spec)
	assert_true(created.result.ok, created.result.message)
	return created.npc_id


func _now(rig: Rig) -> int:
	return rig.runner.world.context.clock.total_minutes()


func _departed(rig: Rig, trader: int) -> bool:
	return rig.economy.peek_caravan(trader).found


func _run_until(rig: Rig, done: Callable, limit: int) -> bool:
	for _minute: int in limit:
		if done.call():
			return true
		rig.runner.step_once()
	return done.call()


## Põe no livro, pelo save, a caravana de `trader` (A ao B pelo C, rotas reais) saindo agora, com `changes` por cima; o save só confere os tipos e o resto é do `validate`.
func _load_caravan(rig: Rig, trader: int, changes: Dictionary = {}) -> void:
	var record: Dictionary = {"trader_id": trader, "state": Caravan.STATE_TRAVELLING, "origin_market_id": rig.market_a, "destination_market_id": rig.market_b, "route_ids": ["route_a_c", "route_b_c"], "leg_index": 0, "leg_started_at": _now(rig), "leg_minutes": 124, "elapsed_at_hold": 0, "good_id": BREAD, "quantity": 1, "cost_paid": 1, "departed_at": _now(rig)}
	record.merge(changes, true)
	var block: Dictionary = rig.economy.serialize()
	block["caravans"] = [record]
	assert_true(rig.economy.on_load(block).ok)


## A chegada sem o ETA: o livro sem nenhuma caravana (a chegada real apaga o registro).
func _unload_caravans(rig: Rig) -> void:
	var block: Dictionary = rig.economy.serialize()
	block.erase("caravans")
	assert_true(rig.economy.on_load(block).ok)


## Uma amostra do verificador em `minute`; `economy` nulo = o verificador de hoje, sem economia nem rotas.
func _check(rig: Rig, idle: Dictionary[int, int], report: NpcLifeCheck.LifeReport, minute: int, economy: EconomyModule, alive: int = 1) -> void:
	NpcLifeCheck.check_npcs(rig.npc, alive, idle, report, minute, economy, rig.routes if economy != null else null)


## `count` amostras seguidas (de SAMPLE em SAMPLE minutos desde `start`) com o contador zerado.
func _samples(rig: Rig, start: int, economy: EconomyModule, count: int = FLAGGED_AT, alive: int = 1) -> NpcLifeCheck.LifeReport:
	var report: NpcLifeCheck.LifeReport = NpcLifeCheck.LifeReport.new()
	var idle: Dictionary[int, int] = {}
	for index: int in count:
		_check(rig, idle, report, start + index * SAMPLE, economy, alive)
	return report


## O contador de ociosidade do NPC depois de UMA amostra em `minute` com a economia do jogo: 0 = isento, 1 = contou.
func _counter(rig: Rig, npc_id: int, minute: int) -> int:
	var idle: Dictionary[int, int] = {}
	_check(rig, idle, NpcLifeCheck.LifeReport.new(), minute, rig.economy)
	return idle[npc_id]


# ---------------------------------------------------------------------------------------------------- V1 a V3

func test_a_merchant_in_transit_within_the_eta_is_not_flagged() -> void:
	var rig: Rig = _rig(EVENING)
	var merchant: int = _spawn(rig, MERCHANT)
	assert_true(_run_until(rig, _departed.bind(rig, merchant), 60), "A `haul` da agenda parte com lucro.")
	assert_eq(rig.npc.peek_npc(merchant).action_id, "", "Em trânsito o comerciante não tem ação (9.3).")
	var report: NpcLifeCheck.LifeReport = NpcLifeCheck.LifeReport.new()
	var today: NpcLifeCheck.LifeReport = NpcLifeCheck.LifeReport.new()
	var idle: Dictionary[int, int] = {}
	var idle_today: Dictionary[int, int] = {}
	var in_transit: int = 0
	var only_reads: bool = true
	while _departed(rig, merchant) and in_transit < 20:
		rig.runner.run_steps(SAMPLE)
		if not _departed(rig, merchant):
			break
		var before: String = rig.runner.world.state_hash()
		_check(rig, idle, report, _now(rig), rig.economy)
		_check(rig, idle_today, today, _now(rig), null)
		only_reads = only_reads and rig.runner.world.state_hash() == before
		in_transit += 1
	assert_gt(in_transit, FLAGGED_AT, "A viagem tem mais amostras sem ação que as %d que o verificador de hoje aceita." % (FLAGGED_AT - 1))
	assert_eq([report.problems, idle[merchant], report.max_idle_min], [[] as Array[String], 0, 0], "Em trânsito, dentro do ETA: 0 problemas e o contador em zero.")
	assert_gt(today.problems.size(), 0, "Sem a isenção as MESMAS amostras acusam o comerciante (o falso positivo que a tarefa elimina).")
	assert_true(only_reads, "O verificador só lê: o hash do mundo não muda ao amostrar.")
	assert_true(rig.npc.peek_npc(merchant).is_alive)


func test_an_ordinary_npc_idle_is_still_flagged() -> void:
	var rig: Rig = _rig(EVENING)
	var guard: int = _spawn(rig, GUARD)
	assert_eq(rig.npc.peek_npc(guard).action_id, "")
	assert_eq(_samples(rig, EVENING + SAMPLE, rig.economy, FLAGGED_AT - 1).problems.size(), 0, "Até a 4ª amostra (60 min) ainda cabe.")
	var report: NpcLifeCheck.LifeReport = _samples(rig, EVENING + SAMPLE, rig.economy)
	assert_eq(report.problems.size(), 1, "5 amostras sem ação: 1 problema, como hoje (com economia e rotas).")
	assert_string_contains(report.problems[0], "o NPC %d está sem ação há mais de %d minutos" % [guard, NpcLifeCheck.MAX_IDLE_MIN])


func test_a_merchant_idle_out_of_transit_is_flagged() -> void:
	var rig: Rig = _rig(EVENING)
	var merchant: int = _spawn(rig, MERCHANT)
	var peeked: CaravanReplies.CaravanQuery = rig.economy.peek_caravan(merchant)
	assert_eq([peeked.result.ok, peeked.found, rig.npc.peek_npc(merchant).occupation_id], [true, false, MERCHANT], "Comerciante parado, sem caravana.")
	assert_eq(_samples(rig, EVENING + SAMPLE, rig.economy, FLAGGED_AT - 1).problems.size(), 0)
	assert_eq(_samples(rig, EVENING + SAMPLE, rig.economy).problems.size(), 1, "Ser comerciante não isenta: sem caravana é um NPC como os outros.")


# ---------------------------------------------------------------------------------------------------- V4 e V5

func test_a_merchant_past_the_eta_plus_margin_is_flagged() -> void:
	var rig: Rig = _rig(EVENING)
	var merchant: int = _spawn(rig, MERCHANT)
	var started: CaravanReplies.StartResult = rig.economy.request_start_caravan(merchant, rig.market_a, rig.market_b, BREAD, 1)
	assert_true(started.result.ok, started.result.message)
	var eta: int = started.eta_minute
	assert_eq(rig.economy.peek_caravan(merchant).eta_minute, eta)
	assert_eq(NpcLifeCheck.TRANSIT_MARGIN_MIN, MARGIN, "A margem de trânsito é a do contrato (D2): 15 minutos, uma amostra.")
	for minute: int in [_now(rig), eta, eta + MARGIN]:
		assert_eq(_counter(rig, merchant, minute), 0, "Até o ETA mais a margem (inclusive) é trânsito: minuto %d." % minute)
	assert_eq(_counter(rig, merchant, eta + MARGIN + 1), 1, "Um minuto além da margem a amostra conta.")
	assert_eq(_samples(rig, eta + MARGIN + 1, rig.economy).problems.size(), 1, "A chegada impedida (o relógio parado no registro): passou do ETA mais a margem, acusado.")


func test_a_held_merchant_is_exempt_only_while_a_route_is_closed() -> void:
	var rig: Rig = _rig(EVENING)
	var merchant: int = _spawn(rig, MERCHANT)
	assert_true(_run_until(rig, _departed.bind(rig, merchant), 60))
	rig.runner.run_steps(30)
	assert_true(rig.routes.request_close_route(rig.economy.peek_caravan(merchant).current_route_id).ok, "Build de desenvolvimento: o comando de fechar vale.")
	rig.runner.step_once()
	var held: CaravanReplies.CaravanQuery = rig.economy.peek_caravan(merchant)
	assert_eq([held.state, held.eta_minute], [Caravan.STATE_HELD, 0], "A rota fechada sob a caravana a segura (eta_minute 0 em `held`).")
	var report: NpcLifeCheck.LifeReport = NpcLifeCheck.LifeReport.new()
	var idle: Dictionary[int, int] = {}
	for _sample: int in FLAGGED_AT + 1:
		rig.runner.run_steps(SAMPLE)
		_check(rig, idle, report, _now(rig), rig.economy)
	assert_eq([report.problems, idle[merchant]], [[] as Array[String], 0], "Parado na estrada com a rota fechada: isento.")


func test_a_held_record_is_exempt_only_with_a_closed_route_from_its_current_leg_on() -> void:
	var rig: Rig = _rig(EVENING)
	var merchant: int = _spawn(rig, MERCHANT)
	_load_caravan(rig, merchant, {"state": Caravan.STATE_HELD, "elapsed_at_hold": 40, "leg_index": 1})
	assert_eq(_samples(rig, EVENING + SAMPLE, rig.economy).problems.size(), 1, "`held` com todas as rotas abertas: a retomada falhou, acusado.")
	assert_true(rig.routes.request_close_route("route_a_c").ok)
	assert_eq(_samples(rig, EVENING + SAMPLE, rig.economy).problems.size(), 1, "Só a rota JÁ ANDADA fechada (antes do trecho atual): não segura ninguém.")
	assert_true(rig.routes.request_close_route("route_b_c").ok)
	assert_eq(_samples(rig, EVENING + SAMPLE, rig.economy).problems.size(), 0, "A rota do trecho atual fechada: parado de verdade, isento.")
	assert_false(NpcLifeCheck.is_transit_exempt(rig.npc.peek_npc(merchant), rig.economy, null, EVENING + SAMPLE), "Sem o `world` não há como conferir a rota fechada: não é isento.")
	for leg_index: int in [-1, 2]:
		_load_caravan(rig, merchant, {"state": Caravan.STATE_HELD, "elapsed_at_hold": 40, "leg_index": leg_index})
		assert_eq(_samples(rig, EVENING + SAMPLE, rig.economy).problems.size(), 1, "`leg_index` %d fora da lista de rotas (registro inconsistente): acusado mesmo com as rotas fechadas." % leg_index)


func test_a_held_record_is_also_exempt_when_only_a_later_leg_is_closed() -> void:
	var rig: Rig = _rig(EVENING)
	var merchant: int = _spawn(rig, MERCHANT)
	assert_true(rig.routes.request_close_route("route_b_c").ok)
	_load_caravan(rig, merchant, {"state": Caravan.STATE_HELD, "elapsed_at_hold": 0, "leg_index": 0})
	assert_eq(_samples(rig, EVENING + SAMPLE, rig.economy).problems.size(), 0, "Do trecho atual em diante: com o trecho atual (route_a_c) aberto e um trecho POSTERIOR (route_b_c) fechado, a retomada não tem por onde seguir: isento.")


# ---------------------------------------------------------------------------------------------------- V6 e V7

func test_an_inconsistent_record_is_flagged() -> void:
	var rig: Rig = _rig(EVENING)
	var merchant: int = _spawn(rig, MERCHANT)
	var start: int = EVENING + SAMPLE
	_load_caravan(rig, merchant)
	assert_eq(_samples(rig, start, rig.economy).problems.size(), 0, "Controle: o registro sem defeito é isento.")
	assert_eq(_samples(rig, start, EconomyModule.new()).problems.size(), 1, "`peek_caravan` com falha (a economia não conhece o dono): acusado.")
	assert_true(rig.routes.request_close_route("route_a_c").ok)
	_load_caravan(rig, merchant, {"state": "lost"})
	assert_eq(_samples(rig, start, rig.economy).problems.size(), 1, "Estado desconhecido: acusado (nem com uma rota do caminho fechada ele vira `held`).")
	_load_caravan(rig, merchant, {"departed_at": EVENING + 10 * SAMPLE})
	assert_eq(_samples(rig, start, rig.economy).problems.size(), 1, "`departed_at` no futuro: acusado.")
	var other: Rig = _rig(EVENING)
	var guard: int = _spawn(other, GUARD)
	_load_caravan(other, guard)
	assert_true(_departed(other, guard), "O registro de quem não é comerciante entrou no livro.")
	assert_eq(_samples(other, start, other.economy).problems.size(), 1, "Caravana de quem não é comerciante: acusado.")
	_load_caravan(rig, merchant)
	var living: NpcModule.NpcQuery = rig.npc.peek_npc(merchant)
	var saved: Dictionary = rig.npc.serialize()
	var entry: Dictionary = saved["npcs"][str(merchant)]
	entry["is_alive"] = false
	entry["death_cause"] = "hunger"
	entry["died_at"] = 10
	assert_true(rig.npc.on_load(saved).ok)
	var dead: NpcModule.NpcQuery = rig.npc.peek_npc(merchant)
	assert_eq([NpcLifeCheck.is_transit_exempt(living, rig.economy, rig.routes, start), NpcLifeCheck.is_transit_exempt(dead, rig.economy, rig.routes, start)], [true, false], "Com a caravana no livro, só o vivo é isento.")
	var report: NpcLifeCheck.LifeReport = _samples(rig, start, rig.economy, 1, 0)
	assert_eq(report.problems.size(), 1, "O morto, com a caravana no livro: 1 problema (o do morto).")
	assert_string_contains(report.problems[0], "está morto")


func test_the_idle_counter_restarts_after_the_arrival() -> void:
	var rig: Rig = _rig(EVENING)
	var merchant: int = _spawn(rig, MERCHANT)
	var report: NpcLifeCheck.LifeReport = NpcLifeCheck.LifeReport.new()
	var idle: Dictionary[int, int] = {}
	var minute: int = EVENING
	for _before: int in 3:
		minute += SAMPLE
		_check(rig, idle, report, minute, rig.economy)
	assert_eq(idle[merchant], 3, "Antes de partir: 3 amostras sem ação contadas (45 min, ainda sem problema).")
	_load_caravan(rig, merchant)
	for _transit: int in 6:
		minute += SAMPLE
		_check(rig, idle, report, minute, rig.economy)
	assert_eq([idle[merchant], report.problems.size()], [0, 0], "Em trânsito o contador zera.")
	_unload_caravans(rig)
	assert_false(_departed(rig, merchant))
	for sample: int in FLAGGED_AT - 1:
		minute += SAMPLE
		_check(rig, idle, report, minute, rig.economy)
		assert_eq([idle[merchant], report.problems.size()], [sample + 1, 0], "Depois da chegada a contagem recomeça do zero: amostra %d." % (sample + 1))
	minute += SAMPLE
	_check(rig, idle, report, minute, rig.economy)
	assert_eq(report.problems.size(), 1, "Só a 5ª amostra sem ação contada da chegada acusa.")


# ---------------------------------------------------------------------------------------------------- V8 e o `run`

func test_without_economy_the_check_is_the_one_of_today() -> void:
	var rig: Rig = _rig(EVENING)
	var merchant: int = _spawn(rig, MERCHANT)
	_load_caravan(rig, merchant)
	var today: NpcLifeCheck.LifeReport = _samples(rig, EVENING + SAMPLE, null)
	assert_eq([today.problems.size(), today.max_idle_min, today.min_alive], [1, 75, 1], "`economy` nula: nenhuma isenção, o relatório de sempre.")
	assert_string_contains(today.problems[0], "minuto %d: o NPC %d está sem ação há mais de %d minutos" % [EVENING + FLAGGED_AT * SAMPLE, merchant, NpcLifeCheck.MAX_IDLE_MIN])
	assert_eq(_samples(rig, EVENING + SAMPLE, rig.economy).problems.size(), 0, "O mesmo registro e as mesmas amostras, com a economia: isento.")


func test_the_run_is_the_one_of_today_and_with_economy_builds_the_real_game_and_survives_a_reload() -> void:
	var plain: NpcLifeCheck.LifeReport = NpcLifeCheck.run(_data, SEED, 2)
	var setup: NpcSetup = NpcSetup.from_dir(NpcLifeCheck.DATA_DIR, _places)
	var runner: SimulationRunner = SimulationRunner.new(SEED)
	_runners.append(runner)
	assert_true(GameModules.register(runner, _data.terrain, _data.points, setup).result.ok)
	runner.start_new_game()
	runner.run_days(2)
	assert_eq(plain.state_hash, runner.world.state_hash(), "Sem `with_economy` o `run` monta o mundo de sempre (sem economia nem rotas dos dados): mesmo hash.")
	var direct: NpcLifeCheck.LifeReport = NpcLifeCheck.run(_data, SEED, 2, 0, true)
	assert_eq([direct.problems, direct.min_alive], [[] as Array[String], NpcLifeCheck.EXPECTED_POPULATION], "Com `with_economy` os 138 vivem e nada é acusado.")
	assert_ne(direct.state_hash, plain.state_hash, "A economia e as rotas dos dados entram no mundo, como no jogo real.")
	var reloaded: NpcLifeCheck.LifeReport = NpcLifeCheck.run(_data, SEED, 2, 1, true)
	assert_eq([reloaded.problems, reloaded.state_hash], [[] as Array[String], direct.state_hash], "Salvar e carregar no dia 1 com a economia não muda o resultado.")
