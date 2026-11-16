extends GutTest
## LW-107c3 (passos longos; pendência aberta na LW-107c2; decisão de Arthur de 16/11/2026: corrigir sem mudar regra econômica): num passo que cobre várias horas cheias (cadência de 180 ou 720 minutos) a economia processa cada hora atrasada com o
## relógio DAQUELA hora (hora x 60), não com o do fim do passo. Assim o prazo do contrato que o postador abre, o vencimento (`expire`), os contratos, os eventos e o hash do mundo saem iguais aos de passos de 1, 7 e 60 minutos. O `expire` também olha a hora
## certa quando o prazo cai FORA da hora cheia (contrato postado por comando): antes da correção o passo de 7 minutos já o vencia na hora 2 e o de 1 minuto na hora 3. Economia REAL (mercados, locais de produção e postos dos dados) com os modelos que o PRÓPRIO
## TESTE monta: o arquivo padrão do jogo (hoje `[]`) não entra aqui. O relógio avança o passo inteiro e o módulo recebe UM tick por passo, como num passo grande do jogo.

const SEED: int = 110
const STEPS: Array[int] = [1, 7, 60, 180, 720]
## 14 dias: múltiplo de todos os passos (o mmc de 7 e 720 é 5040) e além do fechamento do décimo dia (hora 240), quando a escassez de grão do mercado A é declarada.
const TOTAL_MINUTES: int = 20160
## 3,5 dias: também múltiplo de todos os passos.
const CHAIN_MINUTES: int = 5040
const MINUTES_PER_HOUR: int = 60
const SETTLEMENT_A: String = "test_settlement_a"
const BREAD_HOURS: int = 24
const FLOUR_HOURS: int = 7
const GRAIN_HOURS: int = 72
const SHORTAGE_HOUR: int = 240
const CHAIN_HOURS: int = 5
## Prazo FORA da hora cheia, UM minuto depois dela (a hora 2 está em 120 e a hora 3 em 180): o primeiro `expire` com o relógio de uma hora cheia que o alcança é o da hora 3, e um relógio da hora adiantado em 1, 2 ou 3 minutos já o venceria na hora 2.
const API_DEADLINE: int = 121
const API_REWARD: int = 20
const LOT: int = 5


func _template(good_id: String, quantity: int, trigger: String, deadline_hours: int, max_open: int) -> ContractTemplateDef:
	return ContractTemplateDef.new("%s_%s" % [good_id, trigger], ContractBook.DELIVERY, good_id, quantity, trigger, 500, deadline_hours, max_open)


## Três modelos com prazos e limites diferentes (pão: 24 h e 2 abertos; farinha: 7 h e 1; grão: 72 h e 1, só na escassez), para os prazos caírem em horas variadas dentro de um passo longo.
func _templates() -> Array[ContractTemplateDef]:
	var templates: Array[ContractTemplateDef] = []
	templates.append(_template("bread", LOT, ContractTemplateDef.TRIGGER_STANDING, BREAD_HOURS, 2))
	templates.append(_template("flour", 10, ContractTemplateDef.TRIGGER_STANDING, FLOUR_HOURS, 1))
	templates.append(_template("grain", 10, ContractTemplateDef.TRIGGER_SHORTAGE, GRAIN_HOURS, 1))
	return templates


func _chain_template() -> Array[ContractTemplateDef]:
	var templates: Array[ContractTemplateDef] = []
	templates.append(_template("bread", LOT, ContractTemplateDef.TRIGGER_STANDING, CHAIN_HOURS, 1))
	return templates


## O grão do mercado A em 0: a escassez é declarada no fechamento do décimo dia.
func _starve_grain(economy: EconomyModule) -> void:
	assert_true(economy.request_set_stock(economy.peek_market_of(SETTLEMENT_A).market_id, "grain", 0).ok)


## Um contrato de entrega que o próprio mercado A posta ANTES da primeira hora cheia, com prazo fora da hora cheia: ele conta como o do modelo do pão (emissor e destino iguais) e segura o postador até vencer.
func _post_by_api(economy: EconomyModule) -> void:
	var market_id: int = economy.peek_market_of(SETTLEMENT_A).market_id
	var posted: EconomyReplies.PostContractResult = economy.request_post_contract(ContractBook.DELIVERY, market_id, API_REWARD, API_DEADLINE, {ContractBook.KEY_GOOD: "bread", ContractBook.KEY_QUANTITY: LOT, ContractBook.KEY_DESTINATION: market_id})
	assert_true(posted.result.ok, posted.result.message)


## Mundo novo com `templates` e `total` minutos andados de `step` em `step`; `prepare` (opcional) mexe na economia antes do primeiro passo. Devolve os contratos (todos os tipos, por ID), os eventos de oferta e de falha (na ordem em que saíram), o hash do mundo e o mercado A.
func _run(step: int, templates: Array[ContractTemplateDef], total: int, prepare: Callable = Callable()) -> Dictionary:
	var setup: EconomySetup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR)
	assert_true(setup.result.ok, setup.result.message)
	var definitions: EconomyDefinitions = setup.definitions
	definitions.is_development_build = true
	definitions.contract_templates = templates
	var economy: EconomyModule = EconomyModule.new(false, definitions)
	var clock: SimClock = SimClock.new()
	var world: World = World.new(SimContext.new(clock, EventBus.new(clock), WorldRng.new(SEED), IdGenerator.new()))
	assert_true(world.register_module("economy", economy).ok)
	world.setup()
	world.post_setup()
	world.on_new_game(SEED)
	var offers: Array[ContractOffered] = []
	var failures: Array[ContractFailed] = []
	world.context.events.subscribe("ContractOffered", func(event: SimEvent) -> void: offers.append(event))
	world.context.events.subscribe("ContractFailed", func(event: SimEvent) -> void: failures.append(event))
	if prepare.is_valid():
		prepare.call(economy)
	for _tick: int in IntMath.floor_div(total, step):
		for _minute: int in step:
			clock.advance_step()
		world.tick(step)
		world.context.events.dispatch()
	var offer_rows: Array = []
	for offer: ContractOffered in offers:
		offer_rows.append([offer.contract_id, offer.kind, offer.issuer_id, offer.reward, offer.deadline])
	var failure_rows: Array = []
	for failure: ContractFailed in failures:
		failure_rows.append([failure.contract_id, failure.issuer_id, failure.reason])
	var market_a: int = economy.peek_market_of(SETTLEMENT_A).market_id
	var result: Dictionary = {"rows": _rows(economy), "offers": offer_rows, "failures": failure_rows, "hash": world.state_hash(), "market_a": market_a}
	world.teardown()
	return result


func _rows(economy: EconomyModule) -> Array:
	var rows: Array = []
	for row: EconomyReplies.ContractQuery in economy.peek_contracts().contracts:
		rows.append([row.contract_id, row.kind, row.issuer_id, row.good_id, row.reward, row.deadline, row.state])
	return rows


## Os pares [prazo, estado] dos contratos de entrega do mercado A, por ID.
func _deadlines_of_a(run: Dictionary) -> Array:
	var pairs: Array = []
	for row: Array in run["rows"]:
		if row[1] == ContractBook.DELIVERY and row[2] == run["market_a"]:
			pairs.append([row[5], row[6]])
	return pairs


func test_the_hash_the_deadlines_and_the_expiries_are_the_same_with_steps_of_one_seven_sixty_one_eighty_and_seven_twenty_minutes() -> void:
	var first: Dictionary = _run(STEPS[0], _templates(), TOTAL_MINUTES, _starve_grain)
	var first_deadline: Dictionary = {}
	var expired_goods: Dictionary = {}
	for row: Array in first["rows"]:
		if row[1] != ContractBook.DELIVERY:
			continue
		if row[2] == first["market_a"] and not first_deadline.has(row[3]):
			first_deadline[row[3]] = row[5]
		if row[6] == ContractBook.STATE_EXPIRED:
			expired_goods[row[3]] = true
	assert_eq(first_deadline, {"bread": (1 + BREAD_HOURS) * MINUTES_PER_HOUR, "flour": (1 + FLOUR_HOURS) * MINUTES_PER_HOUR, "grain": (SHORTAGE_HOUR + GRAIN_HOURS) * MINUTES_PER_HOUR}, "O primeiro contrato de cada modelo no mercado A sai na hora do gatilho, com o `deadline_hours` do modelo (o passo de 1 minuto é a referência).")
	var goods_with_expiry: Array = expired_goods.keys()
	goods_with_expiry.sort()
	assert_eq(goods_with_expiry, ["bread", "flour", "grain"], "Cada modelo teve contrato vencido no período: o `expire` e a repostagem foram exercitados.")
	assert_gt(first["failures"].size(), 0, "Houve `ContractFailed`.")
	for step: int in STEPS.slice(1):
		var other: Dictionary = _run(step, _templates(), TOTAL_MINUTES, _starve_grain)
		assert_eq(other["rows"], first["rows"], "Passo de %d minutos: os mesmos contratos, com os mesmos prazos e estados." % step)
		assert_eq(other["offers"], first["offers"], "Passo de %d minutos: as mesmas ofertas, na mesma ordem." % step)
		assert_eq(other["failures"], first["failures"], "Passo de %d minutos: os mesmos vencimentos, na mesma ordem." % step)
		assert_eq(other["hash"], first["hash"], "Passo de %d minutos: o mesmo hash do mundo." % step)


func test_a_contract_expires_in_the_first_whole_hour_that_reaches_its_deadline_and_the_replacement_gets_the_deadline_of_that_hour() -> void:
	var expiry_hour: int = PriceMath.ceil_div(API_DEADLINE, MINUTES_PER_HOUR)
	var replacements: int = IntMath.floor_div(IntMath.floor_div(CHAIN_MINUTES, MINUTES_PER_HOUR) - expiry_hour, CHAIN_HOURS) + 1
	var expected: Array = [[API_DEADLINE, ContractBook.STATE_EXPIRED]]
	for index: int in replacements:
		expected.append([(expiry_hour + CHAIN_HOURS * (index + 1)) * MINUTES_PER_HOUR, ContractBook.STATE_EXPIRED if index < replacements - 1 else ContractBook.STATE_OPEN])
	assert_eq([expected.size(), expected.slice(0, 3)], [18, [[121, ContractBook.STATE_EXPIRED], [480, ContractBook.STATE_EXPIRED], [780, ContractBook.STATE_EXPIRED]]], "A conta do esperado, em números soltos: o de prazo 121 vence na hora 3; o 1º repostado sai ali (prazo 480) e vence na hora 8, que posta o de prazo 780.")
	for step: int in STEPS:
		var run: Dictionary = _run(step, _chain_template(), CHAIN_MINUTES, _post_by_api)
		assert_eq(_deadlines_of_a(run), expected, "Passo de %d minutos: o contrato de prazo 121 vence na hora 3 (e não na hora 2 nem na primeira hora do passo) e cada repostado leva o prazo da hora em que saiu, cinco horas depois." % step)
		var failed_by_a: int = 0
		for failure: Array in run["failures"]:
			failed_by_a += 1 if failure[1] == run["market_a"] else 0
		assert_eq(failed_by_a, replacements, "Passo de %d minutos: um `ContractFailed` por vencimento do mercado A (o de prazo 121 e os repostados, menos o último)." % step)


func test_each_delayed_hour_of_one_long_tick_posts_with_the_deadline_of_its_own_hour() -> void:
	var templates: Array[ContractTemplateDef] = []
	templates.append(_template("bread", LOT, ContractTemplateDef.TRIGGER_STANDING, CHAIN_HOURS * 2, 3))
	var run: Dictionary = _run(3 * MINUTES_PER_HOUR, templates, 3 * MINUTES_PER_HOUR)
	var expected: Array = []
	for hour: int in [1, 2, 3]:
		expected.append([(hour + CHAIN_HOURS * 2) * MINUTES_PER_HOUR, ContractBook.STATE_OPEN])
	assert_eq(_deadlines_of_a(run), expected, "UM tick de 3 horas (a 1, a 2 e a 3): cada hora atrasada posta com o prazo contado da PRÓPRIA hora, não da última.")
