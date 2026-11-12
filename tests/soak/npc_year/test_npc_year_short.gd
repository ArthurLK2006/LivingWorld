extends GutTest
## LW-084a: versão CURTA do soak longo (1 dia de jogo, 396 NPCs [HIP]: os 132 do jogo vezes a escala 3), que roda no tools/check_all; a de um ano é tests/soak/npc_year/soak_npc_year.gd (fora do
## check_all). Mesmo medidor das duas (NpcYearMeter): 300 NPCs nascem, 40 viram T2, o foco do ator alterna entre A, B e longe (corpos S1 <-> S0), nenhum erro de
## validate() e nenhuma morte contada como falha (a morte só é REGISTRADA, decisão de Arthur). Repetir dá o mesmo hash, e salvar e carregar com o foco longe também.
## Os últimos testes provam que o medidor ACUSA o que deve (dado ruim, padrão inválido) e que 0 dias não quebra nada.

const WORLD_SEED: int = 11
const DAY: int = SimClock.MINUTES_PER_DAY
## Dentro do trecho "longe" do padrão base (minutos 960 a 1439): nenhum NPC com corpo, que o save não guarda.
const RELOAD_AT_MIN: int = 1200
## Teto do LOD (data/lod_params.json, max_s0).
const MAX_S0: int = 50
## [HIP] Crescimento máximo da memória estática em 1 dia: 2 MiB. Medição de 10/11/2026 (build de depuração, 300 NPCs, padrão base): +1,71 MiB em 7 dias e +1,89 MiB em
## 30 (a curva achata) e +0,29 MiB em 1 dia dentro do GUT; um dia não pode custar mais do que 30 custaram. NÃO é a régua definitiva de "sem crescimento": essa sai da
## primeira medição de um ano.
const MAX_MEMORY_GROWTH_BYTES: int = 2 * 1048576

var _data: NpcLifeCheck.GameData
var _base: NpcYearMeter.Report


func before_all() -> void:
	_data = NpcLifeCheck.load_game_data()
	assert_eq(_data.problem, "", "Os dados reais do jogo carregam.")
	_base = NpcYearMeter.run(_data, _config(NpcYearMeter.PATTERN_BASE_MIN))
	print(_base.summary())


func _config(leg_minutes: int, reload_at_minute: int = 0) -> NpcYearMeter.Config:
	var config: NpcYearMeter.Config = NpcYearMeter.Config.new()
	config.world_seed = WORLD_SEED
	config.days = 1
	config.leg_minutes = leg_minutes
	config.reload_at_minute = reload_at_minute
	return config


func test_one_day_with_300_npcs_and_alternating_bodies_keeps_every_invariant() -> void:
	assert_eq(_base.problems.size(), 0, str(_base.problems))
	assert_eq([_base.npcs, _base.minutes, _base.step_usec.size()], [NpcLifeCheck.EXPECTED_POPULATION * NpcYearMeter.SCALE, DAY, DAY], "132 NPCs vezes a escala (396) e 1 dia, um tempo por passo.")
	assert_eq(_base.min_alive, _base.npcs, "Ninguém morreu neste dia (o número de mortos só é registrado: %d)." % _base.dead)
	assert_true(_base.s0_peak > 0 and _base.s0_peak <= MAX_S0, "Houve corpos, no máximo %d (veio %d)." % [MAX_S0, _base.s0_peak])
	assert_gt(_base.s0_entries, 0, "A alternância trouxe NPCs a S0.")
	assert_eq([_base.memory_by_day.size(), _base.objects_by_day.size(), _base.save_bytes.size()], [2, 2, 1], "Começo e fim do dia, e o tamanho do save no fim.")
	assert_gt(_base.save_bytes[0], 0, "O jogo capturado tem conteúdo.")
	assert_gt(_base.save_raw_bytes[0], _base.save_bytes[0], "O save sem comprimir é maior que o comprimido.")
	assert_eq(_base.notable_memories.size(), NpcYearMeter.NOTABLES, "Os 40 notáveis são contados no fim.")
	assert_true(_base.notable_memories.size() == _base.notable_traits.size() and _base.notable_memories.size() == _base.notable_relations.size())
	assert_true(_base.memory_growth() <= MAX_MEMORY_GROWTH_BYTES, "A memória cresceu %d bytes em 1 dia (limite %d [HIP])." % [_base.memory_growth(), MAX_MEMORY_GROWTH_BYTES])
	assert_gt(_base.mean_step_usec(), 0.0, "Cada passo foi cronometrado.")
	assert_true(_base.modules.has("npc"), "O agendador conta o módulo npc.")


func test_the_same_seed_gives_the_same_hash_and_saving_with_the_focus_far_does_not_change_it() -> void:
	var again: NpcYearMeter.Report = NpcYearMeter.run(_data, _config(NpcYearMeter.PATTERN_BASE_MIN))
	assert_eq(again.problems.size(), 0, str(again.problems))
	assert_eq(again.state_hash, _base.state_hash, "Mesma semente, mesmo hash.")
	var reloaded: NpcYearMeter.Report = NpcYearMeter.run(_data, _config(NpcYearMeter.PATTERN_BASE_MIN, RELOAD_AT_MIN))
	assert_eq(reloaded.problems.size(), 0, str(reloaded.problems))
	assert_eq(reloaded.state_hash, _base.state_hash, "Salvar e carregar no minuto %d (foco longe) não muda o resultado." % RELOAD_AT_MIN)


func test_the_stress_pattern_brings_npcs_to_bodies_more_often_than_the_base_pattern() -> void:
	var stress: NpcYearMeter.Report = NpcYearMeter.run(_data, _config(NpcYearMeter.PATTERN_STRESS_MIN))
	assert_eq(stress.problems.size(), 0, str(stress.problems))
	assert_gt(stress.s0_entries, _base.s0_entries, "Trechos de 30 min trocam os corpos mais vezes (%d contra %d entradas)." % [stress.s0_entries, _base.s0_entries])
	assert_true(stress.s0_peak <= MAX_S0)


func test_bad_data_and_a_bad_pattern_are_reported_and_zero_days_run_clean() -> void:
	var broken: NpcLifeCheck.GameData = NpcLifeCheck.GameData.new()
	broken.problem = "arquivo ruim"
	var bad_data: NpcYearMeter.Report = NpcYearMeter.run(broken, _config(NpcYearMeter.PATTERN_BASE_MIN))
	assert_string_contains(str(bad_data.problems), "arquivo ruim")
	var bad_pattern: NpcYearMeter.Report = NpcYearMeter.run(_data, _config(0))
	assert_string_contains(str(bad_pattern.problems), "configuração inválida")
	var empty_config: NpcYearMeter.Config = _config(NpcYearMeter.PATTERN_BASE_MIN)
	empty_config.days = 0
	var empty: NpcYearMeter.Report = NpcYearMeter.run(_data, empty_config)
	assert_eq([empty.problems.size(), empty.minutes, empty.step_usec.size(), empty.mean_step_usec(), empty.percentile_usec(0.999), empty.slowest_minute()], [0, 0, 0, 0.0, 0, -1], "Zero dias: nada a medir, nada quebra.")
	assert_string_contains(empty.summary(), "%d NPCs" % (NpcLifeCheck.EXPECTED_POPULATION * NpcYearMeter.SCALE))
