class_name EconomyPersistence
extends RefCounted
## O save, a validação e o resumo de depuração da economia (LW-092f; divisão do `EconomyModule`, sem mudar comportamento). `serialize`: o bloco `economy` do save, vazio quando não há estado; `load_into`: aceita o bloco vazio
## ou os campos conhecidos, TUDO conferido antes de trocar o estado (o `EconomyState` alvo só recebe os livros no fim, se nada falhou); `validation_problems` e `summary`: o `validate()` e o `debug_summary()` do módulo.

const CODE_INVALID_SAVE: String = EconomyCodes.INVALID_SAVE
const KEY_OWNERS: String = "owners"
const KEY_LEDGER: String = "ledger"
const KEY_GOODS: String = "goods"
const KEY_MARKETS: String = "markets"
const KEY_PRODUCTION: String = "production"
const KEY_POSTS: String = ServicePostBook.KEY_POSTS
const KEY_CONTRACTS: String = ContractBook.KEY_CONTRACTS


## Sem dono e sem movimento: bloco vazio (nada entra no hash além da presença do módulo).
static func serialize(state: EconomyState) -> Dictionary:
	if state.book.is_empty() and state.ledger.is_pristine() and state.goods.is_pristine():
		return {}
	var block: Dictionary = {KEY_OWNERS: state.book.serialize(), KEY_LEDGER: state.ledger.serialize()}
	if not state.goods.is_pristine():
		block[KEY_GOODS] = state.goods.serialize()
	if state.markets != null and not state.markets.is_pristine():
		block[KEY_MARKETS] = state.markets.serialize()
	if state.production != null and not state.production.is_pristine():
		block[KEY_PRODUCTION] = state.production.serialize()
	if state.posts != null and not state.posts.is_pristine():
		block[KEY_POSTS] = state.posts.serialize()
	if not state.contracts.is_pristine():
		block[KEY_CONTRACTS] = state.contracts.serialize()
	return block


## Aceita o bloco vazio ou os campos conhecidos (`owners` e `ledger` sempre; `goods`, `markets` e `production` quando há), tudo conferido antes de trocar o estado; qualquer outra chave é recusada com mensagem clara.
static func load_into(target: EconomyState, data: Dictionary) -> Result:
	var names: PackedStringArray = PackedStringArray()
	for key: Variant in data.keys():
		names.append(str(key))
	names.sort()
	for name: String in names:
		if not [KEY_OWNERS, KEY_LEDGER, KEY_GOODS, KEY_MARKETS, KEY_PRODUCTION, KEY_POSTS, KEY_CONTRACTS].has(name):
			return Result.failure(CODE_INVALID_SAVE, "EconomyModule.on_load: o bloco 'economy' do save tem %d chave(s) (%s); esperado vazio ou só '%s', '%s', '%s', '%s', '%s', '%s' e '%s'." % [names.size(), ", ".join(names), KEY_OWNERS, KEY_LEDGER, KEY_GOODS, KEY_MARKETS, KEY_PRODUCTION, KEY_POSTS, KEY_CONTRACTS])
	# Variant: valores crus do save (JSON); o tipo é conferido na linha seguinte.
	var raw_owners: Variant = data.get(KEY_OWNERS)
	var raw_ledger: Variant = data.get(KEY_LEDGER)
	var raw_goods: Variant = data.get(KEY_GOODS, {})
	var raw_markets: Variant = data.get(KEY_MARKETS, {})
	var raw_production: Variant = data.get(KEY_PRODUCTION, {})
	var raw_posts: Variant = data.get(KEY_POSTS, {})
	var raw_contracts: Variant = data.get(KEY_CONTRACTS, {})
	if typeof(raw_owners) != TYPE_DICTIONARY or typeof(raw_ledger) != TYPE_DICTIONARY or typeof(raw_goods) != TYPE_DICTIONARY or typeof(raw_markets) != TYPE_DICTIONARY or typeof(raw_production) != TYPE_DICTIONARY or typeof(raw_posts) != TYPE_DICTIONARY or typeof(raw_contracts) != TYPE_DICTIONARY:
		return Result.failure(CODE_INVALID_SAVE, "EconomyModule.on_load: '%s' e '%s' devem ser objetos e estar os dois no bloco 'economy' (e '%s', '%s', '%s', '%s' e '%s', se houver, também objetos)." % [KEY_OWNERS, KEY_LEDGER, KEY_GOODS, KEY_MARKETS, KEY_PRODUCTION, KEY_POSTS, KEY_CONTRACTS])
	var market_data: Dictionary = raw_markets
	var book: OwnerBook = OwnerBook.new()
	var loaded: Result = book.load_from(raw_owners)
	if not loaded.ok:
		return loaded
	var kind_problems: Array[String] = target.unknown_kind_problems(book)
	if not kind_problems.is_empty():
		return Result.failure(CODE_INVALID_SAVE, "EconomyModule.on_load: %s." % kind_problems[0])
	var ledger: Ledger = Ledger.new(book, target.record_history)
	loaded = ledger.load_from(raw_ledger)
	if not loaded.ok:
		return loaded
	var goods: GoodsStore = GoodsStore.new(book, target.definitions.goods, target.definitions.kinds)
	var goods_data: Dictionary = raw_goods
	if not goods_data.is_empty():
		loaded = goods.load_from(goods_data)
		if not loaded.ok:
			return loaded
	var markets: MarketBook = EconomyState.new_market_book(target.definitions, book, goods)
	if not market_data.is_empty():
		if markets == null:
			return Result.failure(CODE_INVALID_SAVE, "EconomyModule.on_load: o save tem mercados, mas este módulo não recebeu as constantes de preço.")
		loaded = markets.load_from(market_data)
		if not loaded.ok:
			return loaded
	var engine: TradeEngine = EconomyState.new_engine(target.definitions, target.rules, book, ledger, goods, markets)
	var production: ProductionBook = EconomyState.new_production_book(target.definitions, book, goods, markets, engine, ledger)
	var production_data: Dictionary = raw_production
	if not production_data.is_empty():
		if production == null:
			return Result.failure(CODE_INVALID_SAVE, "EconomyModule.on_load: o save tem locais de produção, mas este módulo não recebeu as receitas, as constantes dos locais e os mercados.")
		loaded = production.load_from(production_data)
		if not loaded.ok:
			return loaded
	var posts: ServicePostBook = EconomyState.new_post_book(book, markets, ledger)
	var posts_data: Dictionary = raw_posts
	if not posts_data.is_empty():
		if posts == null:
			return Result.failure(CODE_INVALID_SAVE, "EconomyModule.on_load: o save tem postos de serviço, mas este módulo não recebeu as constantes de preço (sem mercado não há folha).")
		loaded = posts.load_from(posts_data)
		if not loaded.ok:
			return loaded
	var contracts: ContractBook = ContractBook.new(book, ledger, goods, production, posts)
	var contracts_data: Dictionary = raw_contracts
	if not contracts_data.is_empty():
		loaded = contracts.load_from(contracts_data)
		if not loaded.ok:
			return loaded
	target.book = book
	target.ledger = ledger
	target.goods = goods
	target.markets = markets
	target.engine = engine
	target.production = production
	target.posts = posts
	target.contracts = contracts
	return Result.success()


static func validation_problems(state: EconomyState) -> Array[String]:
	var problems: Array[String] = []
	for problem: String in state.book.validate():
		problems.append("[owners] " + problem)
	for problem: String in state.unknown_kind_problems(state.book):
		problems.append("[owners] " + problem)
	for problem: String in state.ledger.validate():
		problems.append("[ledger] " + problem)
	for problem: String in state.goods.validate():
		problems.append("[goods] " + problem)
	if state.markets != null:
		for problem: String in state.markets.validate():
			problems.append("[markets] " + problem)
	if state.production != null:
		for problem: String in state.production.validate():
			problems.append("[production] " + problem)
	if state.posts != null:
		for problem: String in state.posts.validate():
			problems.append("[posts] " + problem)
	for problem: String in state.contracts.validate():
		problems.append("[contracts] " + problem)
	return problems


## Resumo para o painel de depuração (backlog I4; revisão independente I1): só números e se a conservação do dinheiro e dos bens fecha. Não vai para o save nem para o hash.
static func summary(state: EconomyState) -> Dictionary:
	var report: Dictionary = {
		"owners": state.book.owner_ids().size(),
		"balances_sum": state.ledger.sum_of_balances(),
		"money_created": state.ledger.total_created(),
		"money_destroyed": state.ledger.total_destroyed(),
		"money_conserved": state.ledger.is_conserved(),
		"goods_conserved": state.goods.is_conserved(),
		"production_sites": 0 if state.production == null else state.production.site_ids().size(),
	}
	# Os postos de serviço (R8-M2; AGENTS 4.15): a chave só aparece quando há postos, porque `test_economy_debug_and_kinds.gd` compara o resumo inteiro em três pontos (sem postos) e nenhum teste existente pode mudar.
	if state.posts != null and not state.posts.is_pristine():
		report["service_posts"] = state.posts.post_ids().size()
	return report
