extends GutTest
## LW-072h: a medição de 7 dias dos corpos contra o gêmeo sem corpos, versão LONGA, fora do tools/check_all (cerca de um minuto). Roda com `tests/soak/run_npc_bodies_7d`
## e imprime a tabela S1 contra S0. O nome do arquivo não começa com `test_` de propósito, para o GUT não o achar sozinho ao varrer as pastas. A versão curta (1 dia)
## está em test_npc_bodies_twin.gd. A velocidade 8 do relógio só encurta a medição: o corpo anda os mesmos 5 m por minuto de jogo em qualquer velocidade.

const WORLD_SEED: int = 11
const DAYS: int = 7
const SPEED: int = 8


func test_seven_days_of_bodies_against_the_twin_without_bodies() -> void:
	var data: NpcLifeCheck.GameData = NpcLifeCheck.load_game_data()
	assert_eq(data.problem, "", "Os dados reais do jogo carregam.")
	var solo: NpcBodiesTwin.Run = NpcBodiesTwin.run(data, NpcBodiesTwin.Mode.SOLO, WORLD_SEED, DAYS, SPEED)
	var twin: NpcBodiesTwin.Run = NpcBodiesTwin.run(data, NpcBodiesTwin.Mode.GEMEO, WORLD_SEED, DAYS, SPEED)
	var bodies: NpcBodiesTwin.Run = NpcBodiesTwin.run(data, NpcBodiesTwin.Mode.CORPOS, WORLD_SEED, DAYS, SPEED)
	print(NpcBodiesTwin.table(solo, twin, bodies, DAYS, SPEED))
	assert_eq([solo.problems, twin.problems, bodies.problems], [[], [], []] as Array[Array], "Os três mundos montam e andam sem problema.")
	assert_eq(twin.state_hash, solo.state_hash, "O S1 gêmeo é o mesmo mundo do S1 sozinho.")
