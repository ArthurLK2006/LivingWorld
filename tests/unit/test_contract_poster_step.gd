extends GutTest
## LW-107c2 (prazo pela hora cheia; docs/modules/economy.md, seção 8; decisão de Arthur de 15/11/2026): a hora cheia é processada no primeiro passo que a alcança, e com passos de 1, 7 ou 60 minutos isso cai em minutos diferentes (60, 63, 60). O prazo
## do contrato postado conta do INÍCIO da hora cheia (`agora - agora % 60`), então o prazo, os contratos e o hash do mundo são os mesmos com os 3 passos. Modelos montados pelo PRÓPRIO TESTE (um `standing` e um `shortage`), sem depender do arquivo
## padrão (hoje vazio). 14700 minutos (múltiplo de 1, 7 e 60) cobrem o pão do começo, o vencimento e a repostagem de 48 em 48 horas e a escassez de grão DECLARADA no décimo dia (o fechamento do dia 10 cai na hora 240).

const SEED: int = 109
const STEPS: Array[int] = [1, 7, 60]
const TOTAL_MINUTES: int = 14700
const MINUTES_PER_HOUR: int = 60
const DEADLINE_HOURS: int = 48
const SETTLEMENT_A: String = "test_settlement_a"


func _templates() -> Array[ContractTemplateDef]:
	var templates: Array[ContractTemplateDef] = []
	templates.append(ContractTemplateDef.new("bread_standing", ContractBook.DELIVERY, "bread", 5, ContractTemplateDef.TRIGGER_STANDING, 500, DEADLINE_HOURS, 1))
	templates.append(ContractTemplateDef.new("grain_shortage", ContractBook.DELIVERY, "grain", 10, ContractTemplateDef.TRIGGER_SHORTAGE, 2500, DEADLINE_HOURS, 1))
	return templates


## Mundo novo (mercados reais, sem locais de produção nem postos), grão do mercado A em 0 e `TOTAL_MINUTES` minutos andados de `step` em `step`: o relógio avança o passo inteiro e o módulo recebe UM tick, como num passo grande do jogo.
func _run(step: int) -> Dictionary:
	var setup: EconomySetup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR)
	assert_true(setup.result.ok, setup.result.message)
	var definitions: EconomyDefinitions = setup.definitions
	definitions.is_development_build = true
	var no_sites: Array[SiteDef] = []
	definitions.production_sites = no_sites
	var no_posts: Array[PostDef] = []
	definitions.service_posts = no_posts
	definitions.contract_templates = _templates()
	var economy: EconomyModule = EconomyModule.new(false, definitions)
	var clock: SimClock = SimClock.new()
	var world: World = World.new(SimContext.new(clock, EventBus.new(clock), WorldRng.new(SEED), IdGenerator.new()))
	assert_true(world.register_module("economy", economy).ok)
	world.setup()
	world.post_setup()
	world.on_new_game(SEED)
	assert_true(economy.request_set_stock(economy.peek_market_of(SETTLEMENT_A).market_id, "grain", 0).ok)
	for _tick: int in IntMath.floor_div(TOTAL_MINUTES, step):
		for _minute: int in step:
			clock.advance_step()
		world.tick(step)
		world.context.events.dispatch()
	var rows: Array = []
	for row: EconomyReplies.ContractQuery in economy.peek_contracts().contracts:
		rows.append([row.contract_id, row.issuer_id, row.good_id, row.reward, row.deadline, row.state])
	var result: Dictionary = {"rows": rows, "hash": world.state_hash()}
	world.teardown()
	return result


func test_the_deadline_the_contracts_and_the_world_hash_are_the_same_with_steps_of_one_seven_and_sixty_minutes() -> void:
	var first: Dictionary = _run(STEPS[0])
	var goods: Array[String] = []
	for row: Array in first["rows"]:
		goods.append(str(row[2]))
		assert_eq(int(row[4]) % MINUTES_PER_HOUR, 0, "O prazo do contrato %d cai no início de uma hora cheia." % int(row[0]))
	assert_eq(first["rows"][0][4], (1 + DEADLINE_HOURS) * MINUTES_PER_HOUR, "O primeiro contrato, postado na hora 1, vence 48 horas depois do início dela.")
	assert_true(goods.has("bread") and goods.has("grain"), "O teste cobre o `standing` e o `shortage`.")
	for step: int in STEPS.slice(1):
		var other: Dictionary = _run(step)
		assert_eq(other["rows"], first["rows"], "Passo de %d minutos: os mesmos contratos, com os mesmos prazos." % step)
		assert_eq(other["hash"], first["hash"], "Passo de %d minutos: o mesmo hash do mundo." % step)
