extends GutTest
## LW-068: a vida dos 138 NPCs sem jogador, versão CURTA (7 dias de jogo), que roda no tools/check_all (a de 30 dias está em
## tests/soak/npc_life/soak_npc_life_30d.gd, fora do check_all porque leva cerca de um minuto). Mesmo verificador das duas (NpcLifeCheck):
## todos vivos; necessidades de 0 a 100; comida nunca negativa; ninguém parado sem ação por mais de uma hora; world.validate() e npc.validate()
## limpos ao fim de cada dia; pensamentos por passo dentro do teto. Repetido com a mesma semente dá o mesmo hash, e salvar e carregar no
## meio não muda nada. Os testes do final provam que o próprio verificador ACUSA cada violação (sem eles o teste poderia passar vazio).

const WORLD_SEED: int = 11
const DAYS: int = 7
const RELOAD_AFTER_DAYS: int = 3
const THINK_CAP: int = 20

var _data: NpcLifeCheck.GameData


func before_all() -> void:
	_data = NpcLifeCheck.load_game_data()
	assert_eq(_data.problem, "", "Os dados reais do jogo carregam.")


func test_seven_days_without_a_player_keep_every_invariant_and_the_run_is_reproducible() -> void:
	var first: NpcLifeCheck.LifeReport = NpcLifeCheck.run(_data, WORLD_SEED, DAYS)
	print(first.summary())
	assert_eq(first.problems.size(), 0, str(first.problems))
	assert_eq(first.minutes, DAYS * SimClock.MINUTES_PER_DAY, "Sete dias de jogo.")
	assert_eq(first.min_alive, NpcLifeCheck.EXPECTED_POPULATION, "Todos vivos o tempo todo.")
	assert_true(first.max_idle_min <= NpcLifeCheck.MAX_IDLE_MIN, "Maior tempo parado: %d min." % first.max_idle_min)
	assert_gt(first.max_thinks_in_a_step, 0, "Os NPCs pensaram.")
	assert_true(first.max_thinks_in_a_step <= THINK_CAP, "No máximo %d pensamentos por passo (teto de data/npc_params.json)." % THINK_CAP)
	var again: NpcLifeCheck.LifeReport = NpcLifeCheck.run(_data, WORLD_SEED, DAYS)
	assert_eq(again.problems.size(), 0, str(again.problems))
	assert_eq(again.state_hash, first.state_hash, "Mesma semente, mesmo hash depois de 7 dias.")
	var reloaded: NpcLifeCheck.LifeReport = NpcLifeCheck.run(_data, WORLD_SEED, DAYS, RELOAD_AFTER_DAYS)
	assert_eq(reloaded.problems.size(), 0, str(reloaded.problems))
	assert_eq(reloaded.state_hash, first.state_hash, "Salvar e carregar no dia %d não muda o resultado." % RELOAD_AFTER_DAYS)
	var other: NpcLifeCheck.LifeReport = NpcLifeCheck.run(_data, WORLD_SEED + 1, 1)
	var same_day: NpcLifeCheck.LifeReport = NpcLifeCheck.run(_data, WORLD_SEED, 1)
	assert_ne(other.state_hash, same_day.state_hash, "Outra semente, outro mundo.")


## LW-098h5 (docs/modules/economy.md 9.15.3, V9): os mesmos 7 dias, agora com a economia e as rotas dos dados (`with_economy`) e os 6 comerciantes REAIS: os 138 vivem, nada é acusado
## (o comerciante em trânsito legítimo é isento) e repetir dá o mesmo hash. `transit_exempt_samples` maior que 0 prova que a isenção foi usada, isto é, que houve viagem de verdade.
func test_seven_days_with_the_economy_and_the_real_merchants_keep_everyone_alive_and_the_run_is_reproducible() -> void:
	var first: NpcLifeCheck.LifeReport = NpcLifeCheck.run(_data, WORLD_SEED, DAYS, 0, true)
	print(first.summary())
	assert_eq(first.problems.size(), 0, str(first.problems))
	assert_eq(first.min_alive, NpcLifeCheck.EXPECTED_POPULATION, "Todos vivos o tempo todo, os 6 comerciantes incluídos.")
	assert_gt(first.transit_exempt_samples, 0, "Pelo menos um comerciante viajou: a isenção de trânsito legítimo foi usada.")
	assert_true(first.max_idle_min <= NpcLifeCheck.MAX_IDLE_MIN, "Maior tempo parado: %d min." % first.max_idle_min)
	var again: NpcLifeCheck.LifeReport = NpcLifeCheck.run(_data, WORLD_SEED, DAYS, 0, true)
	assert_eq(again.problems.size(), 0, str(again.problems))
	assert_eq(again.state_hash, first.state_hash, "Mesma semente, mesmo hash depois de 7 dias com a economia.")
	assert_eq(again.transit_exempt_samples, first.transit_exempt_samples, "As mesmas amostras de trânsito nas duas execuções.")


## Estabilidade de longo prazo (o soak manual de 90 dias é tests/soak/npc_life/soak_npc_life_90d_with_economy.gd): salvar e carregar COM caravana em viagem (`reload_in_transit_after_days`) não muda nada. Em 1 dia com a
## economia, a recarga no primeiro minuto com caravana em viagem dá o MESMO hash, as mesmas chegadas e as mesmas amostras de trânsito que a execução direta. Casos de erro: sem a economia, e sem viagem até o fim do horizonte, o verificador ACUSA.
func test_a_reload_with_a_caravan_travelling_changes_nothing_and_the_option_flags_its_misuse() -> void:
	var direct: NpcLifeCheck.LifeReport = NpcLifeCheck.run(_data, WORLD_SEED, 1, 0, true)
	assert_gt(direct.caravan_arrivals, 0, "Já no primeiro dia os comerciantes viajam e chegam.")
	var reloaded: NpcLifeCheck.LifeReport = NpcLifeCheck.run(_data, WORLD_SEED, 1, 0, true, 0)
	assert_eq(reloaded.problems.size(), 0, str(reloaded.problems))
	assert_gt(reloaded.reload_travelling, 0, "A recarga aconteceu com caravana em viagem.")
	assert_true(reloaded.reload_minute > 0 and reloaded.reload_minute < SimClock.MINUTES_PER_DAY, "No dia 0 (minuto %d)." % reloaded.reload_minute)
	assert_false(reloaded.reload_hash_differs, "O mundo carregado tem o hash do salvo.")
	assert_eq(reloaded.state_hash, direct.state_hash, "Salvar e carregar com caravana em viagem não muda o hash.")
	assert_eq(reloaded.caravan_arrivals, direct.caravan_arrivals, "Nem as chegadas de caravana.")
	assert_eq(reloaded.transit_exempt_samples, direct.transit_exempt_samples, "Nem as amostras de trânsito.")
	assert_string_contains(reloaded.summary(), "recarga em trânsito no minuto %d" % reloaded.reload_minute)
	var without_economy: NpcLifeCheck.LifeReport = NpcLifeCheck.run(_data, WORLD_SEED, 1, 0, false, 0)
	assert_string_contains(str(without_economy.problems), "exige a economia")
	var no_horizon: NpcLifeCheck.LifeReport = NpcLifeCheck.run(_data, WORLD_SEED, 0, 0, true, 0)
	assert_string_contains(str(no_horizon.problems), "nenhuma caravana em viagem depois do dia 0")
	assert_eq(no_horizon.reload_minute, -1, "Sem viagem, sem recarga.")


# ---------------------------------------------------------------------------------------------------- o verificador acusa

## Estoque de comida de teste: o assentamento "s" começa com 3, teto 10.
func _tiny_food() -> FoodStub:
	var food_rules: Array[FoodStub.FoodRule] = [FoodStub.FoodRule.new("s", 3, 10, 1, "farmer", 1)]
	return FoodStub.new(food_rules)


## Dois NPCs num módulo mínimo, para provocar cada violação sem rodar o jogo inteiro.
func _tiny_module(food: FoodStub) -> NpcModule:
	var definitions: NpcModule.Definitions = NpcModule.Definitions.new()
	definitions.food = food
	var needs: Array[NeedDef] = []
	for position: int in NpcState.NEED_COUNT:
		needs.append(NeedDef.new("need_%d" % position, position, 0, 0, 40, 65, 90))
	var module: NpcModule = NpcModule.new(needs, null, definitions)
	var clock: SimClock = SimClock.new()
	var world: World = World.new(SimContext.new(clock, EventBus.new(clock), WorldRng.new(1), IdGenerator.new()))
	assert_true(world.register_module("npc", module).ok)
	world.setup()
	for _index: int in 2:
		var spec: NpcSpec = NpcSpec.new()
		spec.name_key = "npc.name.villager"
		assert_true(module.request_create_npc(spec).result.ok)
	return module


func test_the_checker_accepts_a_healthy_sample_and_flags_each_violation() -> void:
	var module: NpcModule = _tiny_module(_tiny_food())
	var healthy: NpcLifeCheck.LifeReport = NpcLifeCheck.LifeReport.new()
	var idle: Dictionary[int, int] = {}
	NpcLifeCheck.check_npcs(module, 2, idle, healthy, 15)
	assert_eq(healthy.problems.size(), 0, "Duas amostras de 15 minutos sem ação ainda não passam de uma hora: %s" % str(healthy.problems))
	assert_eq(healthy.min_alive, 2)
	assert_eq(healthy.max_idle_min, NpcLifeCheck.SAMPLE_EVERY_MIN)
	# Parado por mais de uma hora: 5 amostras seguidas sem ação.
	var stuck: NpcLifeCheck.LifeReport = NpcLifeCheck.LifeReport.new()
	var stuck_idle: Dictionary[int, int] = {}
	for sample: int in 5:
		NpcLifeCheck.check_npcs(module, 2, stuck_idle, stuck, (sample + 1) * NpcLifeCheck.SAMPLE_EVERY_MIN)
	assert_eq(stuck.problems.size(), 2, "Os dois NPCs ficaram parados na 5ª amostra: %s" % str(stuck.problems))
	assert_string_contains(stuck.problems[0], "sem ação há mais de 60 minutos")
	assert_eq(stuck.max_idle_min, 75)
	# Morto e contagem errada.
	var saved: Dictionary = module.serialize()
	var entries: Dictionary = saved["npcs"]
	var first: Dictionary = entries["1"]
	first["is_alive"] = false
	first["death_cause"] = "hunger"
	first["died_at"] = 10
	assert_true(module.on_load(saved).ok)
	var dead: NpcLifeCheck.LifeReport = NpcLifeCheck.LifeReport.new()
	var dead_idle: Dictionary[int, int] = {}
	NpcLifeCheck.check_npcs(module, 2, dead_idle, dead, 30)
	assert_gt(dead.problems.size(), 0)
	assert_string_contains(dead.problems[0], "o NPC 1 está morto")
	assert_string_contains(str(dead.problems), "1 NPC(s) vivo(s); esperado 2")
	assert_eq(dead.min_alive, 1)
	# Necessidade fora da faixa.
	var second: Dictionary = entries["2"]
	var values: Array = second["need_values"]
	values[0] = 101
	assert_true(module.on_load(saved).ok, "O módulo carrega; quem aponta a faixa é o validate() e o verificador.")
	var out_of_range: NpcLifeCheck.LifeReport = NpcLifeCheck.LifeReport.new()
	var range_idle: Dictionary[int, int] = {}
	NpcLifeCheck.check_npcs(module, 1, range_idle, out_of_range, 45)
	assert_string_contains(str(out_of_range.problems), "fora de 0 a 100")


func test_the_checker_flags_a_food_stock_outside_its_range_and_counts_the_zero_minutes() -> void:
	var food: FoodStub = _tiny_food()
	var module: NpcModule = _tiny_module(food)
	var report: NpcLifeCheck.LifeReport = NpcLifeCheck.LifeReport.new()
	var ids: Array[String] = ["s"]
	NpcLifeCheck.check_food(module, ids, report)
	assert_eq(report.problems.size(), 0)
	assert_eq(report.food_min, {"s": 3})
	assert_eq(report.food_zero_minutes.size(), 0)
	food.load_save({"s": 0})
	NpcLifeCheck.check_food(module, ids, report)
	NpcLifeCheck.check_food(module, ids, report)
	assert_eq(report.food_zero_minutes, {"s": 2}, "Dois passos com a comida em zero.")
	assert_eq(report.food_min, {"s": 0})
	assert_eq(report.problems.size(), 0, "Zero é permitido; só negativo ou acima do teto é defeito.")
	food.load_save({"s": -1})
	NpcLifeCheck.check_food(module, ids, report)
	assert_eq(report.problems.size(), 1)
	assert_string_contains(report.problems[0], "fora da faixa")
	food.load_save({"s": 11})
	NpcLifeCheck.check_food(module, ids, report)
	assert_eq(report.problems.size(), 2)
	var unknown: Array[String] = ["nowhere"]
	NpcLifeCheck.check_food(module, unknown, report)
	assert_eq(report.problems.size(), 3, "Assentamento sem regra de comida também é acusado.")


## Estabilidade de longo prazo: as contas SEM teto. Uma mortandade enche `problems` (teto MAX_PROBLEMS) e esconderia o resto, mas os mortos vistos, o minuto do primeiro e os problemas de validação do fim de dia continuam contando.
func test_the_uncapped_counts_keep_counting_when_the_problem_list_is_full() -> void:
	var module: NpcModule = _tiny_module(_tiny_food())
	var report: NpcLifeCheck.LifeReport = NpcLifeCheck.LifeReport.new()
	for index: int in NpcLifeCheck.MAX_PROBLEMS:
		NpcLifeCheck.add_problem(report, "problema %d" % index)
	var saved: Dictionary = module.serialize()
	var entries: Dictionary = saved["npcs"]
	var dead: Dictionary = entries["1"]
	dead["is_alive"] = false
	dead["death_cause"] = "hunger"
	dead["died_at"] = 10
	var living: Dictionary = entries["2"]
	var values: Array = living["need_values"]
	values[0] = 101
	assert_true(module.on_load(saved).ok, "O módulo carrega; quem aponta a faixa é o validate().")
	var idle: Dictionary[int, int] = {}
	NpcLifeCheck.check_npcs(module, 2, idle, report, 30)
	NpcLifeCheck.check_npcs(module, 2, idle, report, 45)
	assert_eq(report.problems.size(), NpcLifeCheck.MAX_PROBLEMS, "A lista continua no teto.")
	assert_eq(report.dead_seen.size(), 1, "O morto conta uma vez, mesmo visto em duas amostras.")
	assert_eq(int(report.dead_seen[1]), 30, "No minuto da primeira amostra em que estava morto.")
	assert_eq(report.first_death_minute, 30)
	var game: NpcLifeCheck.Game = NpcLifeCheck.Game.new()
	game.runner = SimulationRunner.new(1)
	game.npc = module
	NpcLifeCheck._check_day_end(game, report, SimClock.MINUTES_PER_DAY)
	assert_gt(report.day_end_problem_count, 0, "O fim de dia acusou a necessidade fora da faixa.")
	assert_eq(report.problems.size(), NpcLifeCheck.MAX_PROBLEMS, "Mesmo com a lista cheia.")
	assert_string_contains(report.summary(), "mortos 1 (o primeiro visto no minuto 30)")
	game.runner.finish()
	var healthy: NpcLifeCheck.LifeReport = NpcLifeCheck.LifeReport.new()
	var healthy_game: NpcLifeCheck.Game = NpcLifeCheck.Game.new()
	healthy_game.runner = SimulationRunner.new(1)
	healthy_game.npc = _tiny_module(_tiny_food())
	NpcLifeCheck._check_day_end(healthy_game, healthy, SimClock.MINUTES_PER_DAY)
	assert_eq(healthy.day_end_problem_count, 0, "Mundo são, nenhuma conta.")
	assert_false(healthy.summary().contains("mortos"), "Sem mortos, o resumo não os cita.")
	healthy_game.runner.finish()


func test_the_problem_list_is_capped_so_the_report_stays_readable() -> void:
	var report: NpcLifeCheck.LifeReport = NpcLifeCheck.LifeReport.new()
	for index: int in NpcLifeCheck.MAX_PROBLEMS + 20:
		NpcLifeCheck.add_problem(report, "problema %d" % index)
	assert_eq(report.problems.size(), NpcLifeCheck.MAX_PROBLEMS)
