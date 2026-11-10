extends GutTest
## LW-084a: o soak LONGO (roadmap LW-084): 300 NPCs [HIP] por 360 dias de jogo (um ano), com a alternância S1 <-> S0, medindo o tempo de cada passo, a memória, os objetos, o save
## e os mortos (só REGISTRADOS: reprova só por erro de validate(), exceção ou hash diferente entre as execuções). Fora do tools/check_all: leva de 10 a 20 minutos por execução.
## Roda com `tests/soak/run_npc_year [base|stress]`, que repassa os parâmetros por variáveis de ambiente (o arquivo não começa com `test_` para o GUT não o achar sozinho):
## LW_YEAR_DAYS (360), LW_YEAR_RUNS (1 = só a execução direta; 3 = direta, repetida e com salvar e carregar no meio) e LW_YEAR_PATTERN (base ou stress).

const WORLD_SEED: int = 11
const DEFAULT_DAYS: int = 360
const DEFAULT_RUNS: int = 3
const FULL_RUNS: int = 3


func _env_int(variable: String, fallback: int) -> int:
	var text: String = OS.get_environment(variable)
	return int(text) if text.is_valid_int() else fallback


func _config(days: int, reload_at_minute: int) -> NpcYearMeter.Config:
	var config: NpcYearMeter.Config = NpcYearMeter.Config.new()
	config.world_seed = WORLD_SEED
	config.days = days
	config.leg_minutes = NpcYearMeter.PATTERN_STRESS_MIN if OS.get_environment("LW_YEAR_PATTERN") == "stress" else NpcYearMeter.PATTERN_BASE_MIN
	config.reload_at_minute = reload_at_minute
	config.progress = true
	return config


func test_the_long_soak_keeps_every_invariant_and_the_runs_agree() -> void:
	var days: int = _env_int("LW_YEAR_DAYS", DEFAULT_DAYS)
	var runs: int = _env_int("LW_YEAR_RUNS", DEFAULT_RUNS)
	assert_true(days >= 1 and (runs == 1 or runs == FULL_RUNS), "LW_YEAR_DAYS precisa ser 1 ou mais e LW_YEAR_RUNS, 1 ou %d." % FULL_RUNS)
	var data: NpcLifeCheck.GameData = NpcLifeCheck.load_game_data()
	assert_eq(data.problem, "", "Os dados reais do jogo carregam.")
	var first: NpcYearMeter.Report = NpcYearMeter.run(data, _config(days, 0))
	print(first.summary())
	assert_eq(first.problems.size(), 0, str(first.problems))
	assert_eq(first.minutes, days * SimClock.MINUTES_PER_DAY, "Os dias pedidos.")
	if runs == 1:
		return
	var again: NpcYearMeter.Report = NpcYearMeter.run(data, _config(days, 0))
	print(again.summary())
	assert_eq(again.problems.size(), 0, str(again.problems))
	assert_eq(again.state_hash, first.state_hash, "Mesma semente, mesmo hash.")
	# Sempre numa virada de dia: o fim de um trecho "longe" em qualquer dos dois padrões, sem corpos (o save não os guarda).
	var reload_at: int = maxi(IntMath.floor_div(days, 2), 1) * SimClock.MINUTES_PER_DAY
	var reloaded: NpcYearMeter.Report = NpcYearMeter.run(data, _config(days, reload_at))
	print(reloaded.summary())
	assert_eq(reloaded.problems.size(), 0, str(reloaded.problems))
	assert_eq(reloaded.state_hash, first.state_hash, "Salvar e carregar no minuto %d não muda o resultado." % reload_at)
