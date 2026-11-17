extends GutTest
## LW-098h0 (aceite do `npc`): a correção do pensador (o comerciante com comida na mochila não repete a compra; `plan_food` respeita a capacidade) no jogo REAL emulado pelo `MerchantEmulation` (dados de `res://data`, a mesma montagem do `GameApp`): 3 comerciantes (um por povoado),
## diferença de preço Q7, 10 dias, semente 1. Todos vivos e nenhum passa de 24 horas em fome crítica (REGRA DE PARADA de Arthur, D1); antes da correção o `npc` 151 morria de fome com 120 pães na mochila. As viagens acontecem (não é um mundo parado) e as conservações fecham.

const SEED: int = 1
const MERCHANTS: int = 3
const DAYS: int = 10
const MAX_CRITICAL_HOURS: int = 24


func test_the_three_merchants_of_the_q7_emulation_survive_ten_days_and_never_pass_24_hours_in_critical_hunger() -> void:
	var emulation: MerchantEmulation = MerchantEmulation.new()
	assert_eq(emulation.start(SEED, MerchantEmulation.SPREAD_Q7), "", "O jogo real monta.")
	assert_eq(emulation.create_merchants(MERCHANTS), "", "Os comerciantes nascem.")
	var report: MerchantEmulation.Report = emulation.run(DAYS)
	assert_eq(report.alive_count(), MERCHANTS, "Todos vivos depois de 10 dias.\n" + report.summary())
	for row: MerchantEmulation.Row in report.rows:
		assert_true(row.critical_minutes <= MAX_CRITICAL_HOURS * SimClock.MINUTES_PER_HOUR, "Fome crítica acima de 24 horas: " + row.describe())
	assert_true(report.arrivals() > 0, "Os comerciantes viajam e chegam (a emulação não é um mundo parado).")
	assert_true(report.is_sound(), "Dinheiro e bens conservados a cada dia e `validate()` vazio.")
	emulation.finish()
