extends GutTest
## LW-107c2 (ordem da hora de `EconomyRuntime.run_production_hour`: postos, locais de produção, vencimentos, vagas e, por último, o postador): na mesma hora cheia o ID da vaga do local (`vacancy`) é MENOR que o do `delivery` que o postador posta. Na ativação (LW-107c3) essa
## ordem decide os IDs e o hash do mundo. Mundo com 1 local de produção (4 vagas, sem trabalhador) e 1 modelo `standing` montados pelo PRÓPRIO TESTE (o padrão do jogo é vazio), com UM tick de 60 minutos.

const SEED: int = 109


func test_the_vacancy_of_the_hour_gets_a_smaller_id_than_the_delivery_the_poster_posts_in_the_same_hour() -> void:
	var setup: EconomySetup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR)
	assert_true(setup.result.ok, setup.result.message)
	var sites: Array[SiteDef] = [SiteDef.new("site_bread", "test_settlement_a", "a_work_01", "bake_bread", 4)]
	setup.definitions.production_sites = sites
	var templates: Array[ContractTemplateDef] = [ContractTemplateDef.new("bread_standing", ContractBook.DELIVERY, "bread", 5, ContractTemplateDef.TRIGGER_STANDING, 500, 48, 1)]
	setup.definitions.contract_templates = templates
	var economy: EconomyModule = EconomyModule.new(false, setup.definitions)
	var clock: SimClock = SimClock.new()
	var world: World = World.new(SimContext.new(clock, EventBus.new(clock), WorldRng.new(SEED), IdGenerator.new()))
	assert_true(world.register_module("economy", economy).ok)
	world.setup()
	world.post_setup()
	world.on_new_game(SEED)
	for _minute: int in SimClock.MINUTES_PER_HOUR:
		clock.advance_step()
	world.tick(SimClock.MINUTES_PER_HOUR)
	var vacancies: Array[int] = []
	var deliveries: Array[int] = []
	for row: EconomyReplies.ContractQuery in economy.peek_contracts().contracts:
		(vacancies if row.kind == ContractBook.VACANCY else deliveries).append(row.contract_id)
	assert_eq(vacancies.size(), 1, "A hora cheia abriu a vaga do local.")
	assert_false(deliveries.is_empty(), "E o postador postou na mesma hora.")
	assert_lt(vacancies[0], deliveries.min(), "A vaga vem antes do postador: o ID dela é menor que o de todo `delivery`.")
	world.teardown()
