extends GutTest
## LW-107c2 (propriedade (c) da proteção, docs/modules/economy.md, seção 8): com os modelos de partida (o arquivo de exemplo `contract_templates.initial.json`, os mesmos 3 modelos do `dados.md`) e os mercados e bens REAIS, com o estoque de todo
## bem posto por `request_set_stock` em 0%, 10%, 30%, 60%, 100%, 150% e 200% do alvo (o teto de compra), todo contrato postado tem `reward` menor ou igual ao `ask` de hoje vezes a quantidade e, quando o estoque cobre o lote, menor ou igual ao total que
## `peek_quote` devolve para comprá-lo ali; o que viola a regra (b) não é postado (estoque farto: o pão, que o preço de tabela barateia, fica sem contrato). Cada contrato é conferido no instante em que o `ContractOffered` sai (mesmo minuto da postagem).

const SEED: int = 108
const MINUTES_PER_HOUR: int = 60
const HOURS_PER_DAY: int = 24
const SHORTAGE_DAYS: int = 10
const EXAMPLE_PATH: String = "res://data/economy/contract_templates.initial.json"
const SETTLEMENTS: Array[String] = ["test_settlement_a", "test_settlement_b", "test_settlement_c"]
const STOCK_LEVELS_PCT: Array[int] = [0, 10, 30, 60, 100, 150, 200]
const PERCENT: int = 100
const FULL_STOCK_PCT: int = 100
const ABUNDANT_STOCK_PCT: int = 200
const ACTOR: int = 5000


func _templates() -> Array[ContractTemplateDef]:
	var templates: Array[ContractTemplateDef] = []
	var rows: Array = JSON.parse_string(FileAccess.get_file_as_string(EXAMPLE_PATH))
	for row: Dictionary in rows:
		templates.append(ContractTemplateDef.new(str(row["id"]), str(row["kind"]), str(row["good_id"]), int(row["quantity"]), str(row["trigger"]), int(row["reward_margin_bp"]), int(row["deadline_hours"]), int(row["max_open"])))
	return templates


func _world() -> Array:
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
	assert_true(economy.request_open_owner(ACTOR, "player").ok)
	return [world, economy]


func _ask_of(economy: EconomyModule, market_id: int, good_id: String) -> int:
	for row: Dictionary in economy.peek_market(market_id).rows:
		if row["good_id"] == good_id:
			return int(row["ask"])
	return 0


## Confere o contrato no mesmo minuto em que foi postado (o evento sai na mesma passagem, antes de qualquer outra mudança).
func _on_offer(event: SimEvent, economy: EconomyModule, tally: Dictionary) -> void:
	var contract: EconomyReplies.ContractQuery = economy.peek_contract((event as ContractOffered).contract_id)
	tally["posted"] += 1
	var ask_cost: int = _ask_of(economy, contract.issuer_id, contract.good_id) * contract.quantity
	if contract.reward > ask_cost:
		tally["violations"].append("contrato %d: recompensa %d acima do ask x lote %d" % [contract.contract_id, contract.reward, ask_cost])
	var quote: EconomyReplies.QuoteQuery = economy.peek_quote(ACTOR, contract.issuer_id, contract.good_id, contract.quantity, "buy")
	if quote.result.ok:
		tally["quoted"] += 1
		if contract.reward > quote.total:
			tally["violations"].append("contrato %d: recompensa %d acima do total da compra %d" % [contract.contract_id, contract.reward, quote.total])


## Estoque de todo bem em `level_pct` % do alvo e 241 horas (a escassez só é declarada no décimo fechamento de dia abaixo de 30% do alvo); devolve o que foi visto (`bread`: quantos mercados tiveram contrato de pão).
func _observe(level_pct: int) -> Dictionary:
	var parts: Array = _world()
	var world: World = parts[0]
	var economy: EconomyModule = parts[1]
	for settlement_id: String in SETTLEMENTS:
		var market_id: int = economy.peek_market_of(settlement_id).market_id
		for row: Dictionary in economy.peek_market(market_id).rows:
			assert_true(economy.request_set_stock(market_id, str(row["good_id"]), IntMath.floor_div(int(row["target_stock"]) * level_pct, PERCENT)).ok)
	var tally: Dictionary = {"posted": 0, "quoted": 0, "violations": []}
	world.context.events.subscribe("ContractOffered", _on_offer.bind(economy, tally))
	for _minute: int in (SHORTAGE_DAYS * HOURS_PER_DAY + 1) * MINUTES_PER_HOUR:
		world.context.clock.advance_step()
		world.tick(1)
		world.context.events.dispatch()
	var bread_markets: Dictionary[int, bool] = {}
	for contract: EconomyReplies.ContractQuery in economy.peek_contracts().contracts:
		if contract.good_id == "bread":
			bread_markets[contract.issuer_id] = true
	tally["bread"] = bread_markets.size()
	world.teardown()
	return tally


func test_no_posted_contract_pays_more_than_buying_the_lot_at_the_issuer_at_any_stock() -> void:
	var posted: int = 0
	var quoted: int = 0
	for level_pct: int in STOCK_LEVELS_PCT:
		var tally: Dictionary = _observe(level_pct)
		assert_eq(tally["violations"], [], "Estoque em %d%% do alvo." % level_pct)
		posted += int(tally["posted"])
		quoted += int(tally["quoted"])
		if level_pct == FULL_STOCK_PCT:
			assert_eq(tally["bread"], SETTLEMENTS.size(), "No estoque-alvo o pão cabe na regra (b) nos três mercados.")
		if level_pct == ABUNDANT_STOCK_PCT:
			assert_eq(tally["bread"], 0, "Com o pão farto e barato a regra (b) recusa o contrato fixo: o quadro fica sem ele.")
	assert_gt(posted, 0, "A propriedade não vale no vazio: houve contrato postado.")
	assert_gt(quoted, 0, "E houve contrato conferido contra o total de `peek_quote`.")
