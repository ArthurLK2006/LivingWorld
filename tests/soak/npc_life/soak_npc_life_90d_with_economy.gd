extends GutTest
## Estabilidade de longo prazo: a vida dos 138 NPCs sem jogador por 90 dias de jogo, com a ECONOMIA e os 6 comerciantes REAIS (dados de res://data, `with_economy`). Soak MANUAL, fora do tools/check_all porque leva
## de 12 a 20 minutos (três execuções de 90 dias, de 4 a 7 minutos cada, conforme a carga do Mac; com `LW_SOAK_DAYS=30`, cerca de 5 no total). Roda com `tests/soak/run_npc_life_90d_with_economy`. O nome do arquivo não começa com `test_` de propósito, para o GUT não o achar sozinho ao
## varrer as pastas. Mesmo verificador da versão curta (test_npc_life_7d.gd, V9) e da de 30 dias sem economia (soak_npc_life_30d.gd). Três execuções: DIRETA; com salvar e carregar no dia 45 (meia-noite); e com salvar e
## carregar no primeiro minuto depois do dia 10 em que há caravana em VIAGEM (`reload_in_transit_after_days`; o comércio real para por volta do dia 21, então a recarga em trânsito tem de vir cedo). Cada execução diz
## o minuto da recarga e quantas caravanas viajavam. ESTABILIDADE (tudo isto vale em qualquer horizonte): `world.validate()` e `npc.validate()` limpos ao fim de cada dia (inclui a CONSERVAÇÃO do dinheiro, dos bens e o
## livro de caravanas; contado sem o teto de problemas); ninguém parado sem ação por mais de uma hora, salvo o comerciante em trânsito legítimo; necessidades de 0 a 100; pensamentos por passo dentro do teto; as duas recargas
## dão o MESMO hash final, as mesmas chegadas de caravana, as mesmas amostras de trânsito, os mesmos mortos (determinismo e continuidade das caravanas). SOBREVIVÊNCIA (critério estrito, nunca afrouxado): todos vivos o
## tempo todo e nenhum problema acusado. FALHA CONHECIDA até a LW-094 (medida em 21/11/2026, sementes 11 e 1): em 90 dias morrem 30 NPCs de fome, a população INTEIRA do povoado C (sem produtores de comida), entre os dias 31 e 40 (o `FoodStub` do C fica quase
## sempre em zero desde o dia 26 e as caravanas já pararam no dia 21), então as asserções de sobrevivência falham HOJE e as de estabilidade passam; o resumo mostra os mortos e o minuto do primeiro. A semente é a 11 (`LW_SOAK_SEED=1` troca) e
## `LW_SOAK_DAYS=30` encurta o horizonte para a janela em que hoje tudo passa (recarga no meio; trânsito depois do dia 10).

const DEFAULT_SEED: int = 11
const SEED_ENV: String = "LW_SOAK_SEED"
const DEFAULT_DAYS: int = 90
const DAYS_ENV: String = "LW_SOAK_DAYS"
const TRANSIT_AFTER_DAYS: int = 10
const THINK_CAP: int = 20
## Os trechos das duas mensagens de morte do verificador (`check_npcs`): o resto da lista de problemas é estabilidade.
const DEATH_MARK: String = "está morto"
const ALIVE_COUNT_MARK: String = "vivo(s); esperado"


func test_ninety_days_with_the_economy_and_the_real_merchants_keep_every_invariant_and_survive_a_reload() -> void:
	var world_seed: int = _env_int(SEED_ENV, DEFAULT_SEED)
	var days: int = _env_int(DAYS_ENV, DEFAULT_DAYS)
	var reload_after_days: int = IntMath.floor_div(days, 2)
	var data: NpcLifeCheck.GameData = NpcLifeCheck.load_game_data()
	assert_eq(data.problem, "", "Os dados reais do jogo carregam.")
	var first: NpcLifeCheck.LifeReport = NpcLifeCheck.run(data, world_seed, days, 0, true)
	print("semente %d, %d dias, direta: %s" % [world_seed, days, first.summary()])
	_assert_stable(first, days, "direta")
	assert_gt(first.transit_exempt_samples, 0, "Houve viagem de verdade: a isenção de trânsito legítimo foi usada.")
	assert_gt(first.caravan_arrivals, 0, "Houve chegadas de caravana.")
	_assert_survived(first, "direta")
	var reloaded: NpcLifeCheck.LifeReport = NpcLifeCheck.run(data, world_seed, days, reload_after_days, true)
	print("semente %d, %d dias, recarga no dia %d: %s" % [world_seed, days, reload_after_days, reloaded.summary()])
	_assert_stable(reloaded, days, "recarga no dia %d" % reload_after_days)
	_assert_same_run(first, reloaded, "Salvar e carregar no dia %d" % reload_after_days)
	var in_transit: NpcLifeCheck.LifeReport = NpcLifeCheck.run(data, world_seed, days, 0, true, TRANSIT_AFTER_DAYS)
	print("semente %d, %d dias, recarga em trânsito depois do dia %d: %s" % [world_seed, days, TRANSIT_AFTER_DAYS, in_transit.summary()])
	_assert_stable(in_transit, days, "recarga em trânsito")
	assert_gt(in_transit.reload_travelling, 0, "A recarga aconteceu com caravana em viagem.")
	assert_true(in_transit.reload_minute >= TRANSIT_AFTER_DAYS * SimClock.MINUTES_PER_DAY, "A recarga em trânsito veio depois do dia %d." % TRANSIT_AFTER_DAYS)
	_assert_same_run(first, in_transit, "Salvar e carregar com caravana em viagem (minuto %d)" % in_transit.reload_minute)


## ESTABILIDADE de uma execução, independente de quem sobrevive: o horizonte inteiro, a validação do fim de dia (conservação), o maior tempo parado, o teto de pensamentos e a comida dentro da faixa.
func _assert_stable(report: NpcLifeCheck.LifeReport, days: int, what: String) -> void:
	assert_eq(report.minutes, days * SimClock.MINUTES_PER_DAY, "%s: o horizonte inteiro." % what)
	assert_eq(report.day_end_problem_count, 0, "%s: world.validate() e npc.validate() limpos ao fim de cada dia (conservação incluída)." % what)
	assert_true(report.max_idle_min <= NpcLifeCheck.MAX_IDLE_MIN, "%s: maior tempo parado %d min." % [what, report.max_idle_min])
	assert_true(report.max_thinks_in_a_step > 0 and report.max_thinks_in_a_step <= THINK_CAP, "%s: pensamentos por passo no máximo %d (veio %d)." % [what, THINK_CAP, report.max_thinks_in_a_step])
	for settlement_id: String in report.food_min:
		assert_true(int(report.food_min[settlement_id]) >= 0, "%s: a comida de '%s' nunca fica negativa." % [what, settlement_id])
	var other_problems: Array[String] = []
	for problem: String in report.problems:
		if not problem.contains(DEATH_MARK) and not problem.contains(ALIVE_COUNT_MARK):
			other_problems.append(problem)
	assert_eq(other_problems.size(), 0, "%s: nenhum problema além de mortes (a lista enche em 30, e uma mortandade a enche cedo; as contas sem teto acima cobrem o resto): %s" % [what, str(other_problems)])


## SOBREVIVÊNCIA, estrita: todos vivos o tempo todo e nenhum problema acusado (falha conhecida até a LW-094; ver o cabeçalho).
func _assert_survived(report: NpcLifeCheck.LifeReport, what: String) -> void:
	assert_eq(report.min_alive, NpcLifeCheck.EXPECTED_POPULATION, "%s: todos vivos o tempo todo (mortos %d, o primeiro no minuto %d)." % [what, report.dead_seen.size(), report.first_death_minute])
	assert_eq(report.problems.size(), 0, "%s: %s" % [what, str(report.problems)])


## A execução com recarga é a mesma da direta: o hash final, as chegadas de caravana, as amostras de trânsito, os vivos e os mortos.
func _assert_same_run(direct: NpcLifeCheck.LifeReport, other: NpcLifeCheck.LifeReport, what: String) -> void:
	assert_false(other.reload_hash_differs, "%s: o hash do mundo carregado é o do salvo (conferido sem o teto de problemas)." % what)
	assert_eq(other.state_hash, direct.state_hash, "%s não muda o hash final." % what)
	assert_eq(other.caravan_arrivals, direct.caravan_arrivals, "%s não muda as chegadas de caravana." % what)
	assert_eq(other.transit_exempt_samples, direct.transit_exempt_samples, "%s não muda as amostras de trânsito." % what)
	assert_eq(other.min_alive, direct.min_alive, "%s não muda quantos estão vivos." % what)
	assert_eq(other.dead_seen, direct.dead_seen, "%s não muda quem morre nem quando." % what)


func _env_int(variable: String, fallback: int) -> int:
	var text: String = OS.get_environment(variable)
	return int(text) if text.is_valid_int() else fallback
