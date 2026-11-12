class_name ContractRefundMarket
extends RefCounted
## Para onde vai a custódia de um contrato que venceu com o emissor MORTO (LW-096n; decisão de Arthur de 12/11/2026, opção B): a conta do MERCADO do povoado do contrato. O povoado de um `labor` é o do local de trabalho (local de produção ou posto) e o de
## um `delivery` é o do destino (o próprio mercado ou um local de produção). Só consulta: quem move o dinheiro é o `ContractBook`, pelo `Ledger`. Povoado que a economia não conhece (destino que é um NPC, economia sem mercados) ou mercado fechado: devolve
## `IdGenerator.NO_ID` e a custódia continua retida na conta do contrato [LIM].

var _book: OwnerBook
var _production: ProductionBook
var _posts: ServicePostBook
var _markets: MarketBook


## `production`, `posts` e `markets` podem ser nulos (economia sem eles): então não há povoado conhecido por aquele caminho.
func _init(owner_book: OwnerBook, production_book: ProductionBook, post_book: ServicePostBook, market_book: MarketBook) -> void:
	_book = owner_book
	_production = production_book
	_posts = post_book
	_markets = market_book


## O mercado aberto do povoado do local de trabalho `place_id` (de produção ou posto); `IdGenerator.NO_ID` se não há.
func of_place(place_id: String) -> int:
	if _production != null:
		var site_id: int = _production.site_at(place_id)
		if site_id != IdGenerator.NO_ID:
			return _open_market_of(str(_production.state_of(site_id)[ProductionBook.KEY_SETTLEMENT]))
	if _posts != null:
		var post_id: int = _posts.post_at(place_id)
		if post_id != IdGenerator.NO_ID:
			return _open_market_of(str(_posts.state_of(post_id)[ServicePostBook.KEY_SETTLEMENT]))
	return IdGenerator.NO_ID


## O mercado aberto do povoado do dono de destino `owner_id`: ele mesmo, se é um mercado, ou o do povoado do local de produção. Um NPC (ou qualquer outro dono) não tem povoado: `IdGenerator.NO_ID`.
func of_owner(owner_id: int) -> int:
	if _markets != null and _markets.has_market(owner_id):
		return _open_market_of(_markets.settlement_of(owner_id))
	if _production != null and _production.has_site(owner_id):
		return _open_market_of(str(_production.state_of(owner_id)[ProductionBook.KEY_SETTLEMENT]))
	return IdGenerator.NO_ID


func _open_market_of(settlement_id: String) -> int:
	if _markets == null:
		return IdGenerator.NO_ID
	var market_id: int = _markets.market_of(settlement_id)
	return market_id if _book.check_open(market_id).ok else IdGenerator.NO_ID
