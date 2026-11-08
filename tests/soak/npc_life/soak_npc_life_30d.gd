extends GutTest
## LW-068: a vida dos 100 NPCs sem jogador, versão LONGA (30 dias de jogo), fora do tools/check_all porque leva cerca de um minuto (três
## execuções de 30 dias). Roda com `tests/soak/run_npc_life_30d`. O nome do arquivo não começa com `test_` de propósito, para o GUT não o
## achar sozinho ao varrer as pastas. Mesmo verificador da versão curta (test_npc_life_7d.gd, no check_all): todos vivos; necessidades de 0 a
## 100; comida nunca negativa; ninguém parado sem ação por mais de uma hora; validate() limpo ao fim de cada dia; pensamentos por passo dentro
## do teto; mesma semente dá o mesmo hash; salvar e carregar no meio não muda nada.

const WORLD_SEED: int = 11
const DAYS: int = 30
const RELOAD_AFTER_DAYS: int = 15
const THINK_CAP: int = 20


func test_thirty_days_without_a_player_keep_every_invariant_and_the_run_is_reproducible() -> void:
	var data: NpcLifeCheck.GameData = NpcLifeCheck.load_game_data()
	assert_eq(data.problem, "", "Os dados reais do jogo carregam.")
	var first: NpcLifeCheck.LifeReport = NpcLifeCheck.run(data, WORLD_SEED, DAYS)
	print(first.summary())
	assert_eq(first.problems.size(), 0, str(first.problems))
	assert_eq(first.minutes, DAYS * SimClock.MINUTES_PER_DAY, "Trinta dias de jogo.")
	assert_eq(first.min_alive, 100, "Todos vivos o tempo todo.")
	assert_true(first.max_idle_min <= NpcLifeCheck.MAX_IDLE_MIN, "Maior tempo parado: %d min." % first.max_idle_min)
	assert_true(first.max_thinks_in_a_step > 0 and first.max_thinks_in_a_step <= THINK_CAP, "Pensamentos por passo no máximo %d (veio %d)." % [THINK_CAP, first.max_thinks_in_a_step])
	var again: NpcLifeCheck.LifeReport = NpcLifeCheck.run(data, WORLD_SEED, DAYS)
	print(again.summary())
	assert_eq(again.problems.size(), 0, str(again.problems))
	assert_eq(again.state_hash, first.state_hash, "Mesma semente, mesmo hash depois de 30 dias.")
	var reloaded: NpcLifeCheck.LifeReport = NpcLifeCheck.run(data, WORLD_SEED, DAYS, RELOAD_AFTER_DAYS)
	print(reloaded.summary())
	assert_eq(reloaded.problems.size(), 0, str(reloaded.problems))
	assert_eq(reloaded.state_hash, first.state_hash, "Salvar e carregar no dia %d não muda o resultado." % RELOAD_AFTER_DAYS)
