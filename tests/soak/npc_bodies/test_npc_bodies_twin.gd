extends GutTest
## LW-072h: a medição dos corpos contra o gêmeo sem corpos, versão CURTA (1 dia de jogo a 8x, no tools/check_all; a de 7 dias é tests/soak/npc_bodies/soak_npc_bodies_7d.gd).
## Serve para a medição não quebrar em silêncio: os três mundos rodam sem problema, o S1 gêmeo é o MESMO mundo do S1 sozinho (mesmo hash), ninguém dispara alarme, o que o
## amostrador conta como tempo limite é o que o sim contou, os corpos andam e a tabela sai.

const WORLD_SEED: int = 11
const DAYS: int = 1
const SPEED: int = 8


func test_one_day_of_the_measurement_runs_clean_and_the_twin_is_the_same_world_as_the_solo_s1() -> void:
	var data: NpcLifeCheck.GameData = NpcLifeCheck.load_game_data()
	assert_eq(data.problem, "", "Os dados reais do jogo carregam.")
	var solo: NpcBodiesTwin.Run = NpcBodiesTwin.run(data, NpcBodiesTwin.Mode.SOLO, WORLD_SEED, DAYS, SPEED)
	var twin: NpcBodiesTwin.Run = NpcBodiesTwin.run(data, NpcBodiesTwin.Mode.GEMEO, WORLD_SEED, DAYS, SPEED)
	var bodies: NpcBodiesTwin.Run = NpcBodiesTwin.run(data, NpcBodiesTwin.Mode.CORPOS, WORLD_SEED, DAYS, SPEED)
	assert_eq([solo.problems, twin.problems, bodies.problems], [[], [], []] as Array[Array], "Os três mundos montam e andam sem problema.")
	assert_eq([solo.minutes, twin.minutes, bodies.minutes], [DAYS * SimClock.MINUTES_PER_DAY, DAYS * SimClock.MINUTES_PER_DAY, DAYS * SimClock.MINUTES_PER_DAY])
	assert_eq(twin.state_hash, solo.state_hash, "O S1 gêmeo (amostrado a cada minuto) é o mesmo mundo do S1 sozinho.")
	assert_ne(bodies.state_hash, solo.state_hash, "Com corpos o mundo é outro (senão a medição não mediu nada).")
	assert_gt(bodies.exposed.size(), 0, "Houve NPCs em S0.")
	assert_gt(bodies.walks_ok.size(), 0, "Corpos andaram até o local e chegaram.")
	assert_eq(bodies.total("tempo_limite"), bodies.count["tempo_limite_sim"], "O que o amostrador conta como tempo limite é o que o sim contou.")
	assert_eq([twin.count.get("alarmes", 0), bodies.count.get("alarmes", 0)], [0, 0], "Nenhum alarme.")
	assert_true(NpcBodiesTwin.table(solo, twin, bodies, DAYS, SPEED).contains("(6)"), "A tabela sai.")
