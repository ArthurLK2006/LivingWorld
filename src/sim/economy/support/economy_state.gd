class_name EconomyState
extends RefCounted
## O estado vivo da economia (LW-092f; divisão do `EconomyModule`, sem mudar comportamento): os livros que ela possui (donos, dinheiro, bens, mercados, locais de produção), o motor de comércio e o que os criou (as definições, a regra
## de comércio e o modo de teste do `Ledger`). `create` monta tudo vazio; um save que carrega recebe os livros por `EconomyPersistence.load_into`. Só guarda e monta: as regras estão nos livros. `markets`, `engine` e `production`
## são `null` quando as definições não têm o que eles precisam (sem constantes de preço, sem receitas).

var definitions: EconomyDefinitions
var rules: TradeRules
var record_history: bool
var book: OwnerBook
var ledger: Ledger
var goods: GoodsStore
var markets: MarketBook
var engine: TradeEngine
var production: ProductionBook
var posts: ServicePostBook


func _init(economy_definitions: EconomyDefinitions, trade_rules: TradeRules, history: bool) -> void:
	definitions = economy_definitions
	rules = trade_rules
	record_history = history


## Um estado vazio e completo: sem dono, sem dinheiro, sem bem.
static func create(economy_definitions: EconomyDefinitions, trade_rules: TradeRules, history: bool) -> EconomyState:
	var state: EconomyState = EconomyState.new(economy_definitions, trade_rules, history)
	state.book = OwnerBook.new()
	state.ledger = Ledger.new(state.book, history)
	state.goods = GoodsStore.new(state.book, economy_definitions.goods, economy_definitions.kinds)
	state.markets = new_market_book(economy_definitions, state.book, state.goods)
	state.engine = new_engine(economy_definitions, trade_rules, state.book, state.ledger, state.goods, state.markets)
	state.production = new_production_book(economy_definitions, state.book, state.goods, state.markets, state.engine, state.ledger)
	state.posts = new_post_book(state.book, state.markets, state.ledger)
	return state


static func new_market_book(economy_definitions: EconomyDefinitions, owner_book: OwnerBook, goods_store: GoodsStore) -> MarketBook:
	if economy_definitions.price_params == null:
		return null
	return MarketBook.new(owner_book, goods_store, economy_definitions.goods, economy_definitions.market_targets, economy_definitions.price_params)


static func new_engine(economy_definitions: EconomyDefinitions, trade_rules: TradeRules, owner_book: OwnerBook, money_ledger: Ledger, goods_store: GoodsStore, market_book: MarketBook) -> TradeEngine:
	return null if market_book == null else TradeEngine.new(owner_book, money_ledger, goods_store, market_book, trade_rules, economy_definitions.price_params)


## Sem as receitas, as constantes dos locais ou o motor de comércio (que vem dos mercados), não há locais de produção.
static func new_production_book(economy_definitions: EconomyDefinitions, owner_book: OwnerBook, goods_store: GoodsStore, market_book: MarketBook, trade_engine: TradeEngine, money_ledger: Ledger) -> ProductionBook:
	if trade_engine == null or economy_definitions.recipes.is_empty() or economy_definitions.site_params == null:
		return null
	return ProductionBook.new(owner_book, goods_store, market_book, trade_engine, economy_definitions.recipes, economy_definitions.site_params, economy_definitions.price_params.max_order_quantity, money_ledger)


## Sem mercados não há de onde pagar a folha dos postos de serviço (a conta do mercado do povoado), então não há livro de postos.
static func new_post_book(owner_book: OwnerBook, market_book: MarketBook, money_ledger: Ledger) -> ServicePostBook:
	return null if market_book == null else ServicePostBook.new(market_book, WagePayer.new(owner_book, money_ledger))


## Os ids dos tipos de dono das definições (`owner_kinds.json`).
func known_kinds() -> Array[String]:
	var known: Array[String] = []
	for kind_def: OwnerKindDef in definitions.kinds:
		known.append(kind_def.id)
	return known


## Os donos do cadastro cujo tipo não está em `owner_kinds.json` (AGENTS 12.6: validar referência de arquivo). Sem tipos nas definições qualquer tipo vale, como em `request_open_owner`.
func unknown_kind_problems(owner_book: OwnerBook) -> Array[String]:
	var problems: Array[String] = []
	if definitions.kinds.is_empty():
		return problems
	var known: Array[String] = known_kinds()
	for owner_id: int in owner_book.owner_ids():
		if not known.has(owner_book.kind_of(owner_id)):
			problems.append("dono %d: o tipo '%s' não existe em owner_kinds.json; esperado um de: %s" % [owner_id, owner_book.kind_of(owner_id), ", ".join(known)])
	return problems
