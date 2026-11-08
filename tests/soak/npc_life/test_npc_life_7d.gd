extends GutTest
## LW-068: a vida dos 100 NPCs sem jogador, versão CURTA (7 dias de jogo), que roda no tools/check_all (a de 30 dias está em
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
	assert_eq(first.min_alive, 100, "Todos vivos o tempo todo.")
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


func test_the_problem_list_is_capped_so_the_report_stays_readable() -> void:
	var report: NpcLifeCheck.LifeReport = NpcLifeCheck.LifeReport.new()
	for index: int in NpcLifeCheck.MAX_PROBLEMS + 20:
		NpcLifeCheck.add_problem(report, "problema %d" % index)
	assert_eq(report.problems.size(), NpcLifeCheck.MAX_PROBLEMS)
