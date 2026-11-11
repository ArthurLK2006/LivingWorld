class_name EconomyModule
extends SimModule
## Módulo `economy` (contrato em docs/modules/economy.md). LW-088a: a casca, registrada no `World` ANTES do `npc` (o `npc` vai abrir as contas ao criar NPCs) e dona do bloco `economy` do save (DEC-172).
## LW-088: o cadastro de donos (`OwnerBook`) e o livro-razão (`Ledger`). LW-089c: o inventário por dono (`GoodsStore`) e as definições (`EconomyDefinitions`, pelo construtor). LW-090c: os mercados (`MarketBook`):
## um por assentamento dos dados, criado no jogo novo (dono do tipo `market`, com o saldo inicial do tipo e o estoque inicial de cada bem), com o preço andando ao FIM DE CADA DIA do relógio e os eventos
## `PriceChanged`, `ShortageDeclared` e `ShortageEnded` publicados. Esta é a PORTA: `request_open_owner`, `request_transfer_goods`, `request_set_stock` (só em build de desenvolvimento), `peek_balance`,
## `peek_conservation`, `peek_ledger_totals`, `peek_inventory`, `peek_goods_conservation`, `peek_market_of`, `peek_market`, `peek_price` e `peek_stock`. As operações de saldo e de criar e destruir bens NÃO são da
## porta: quem as usa são as partes internas da economia (comércio, produção, salário), cada uma na sua tarefa. O `npc` só pode citar classes desta pasta (regra E do `tools/check_architecture`, DEC-171) e a porta
## devolve só cópia (tipos de `EconomyReplies`). A economia ouve `NpcDied` pelo NOME do evento (não importa o `npc`, DEC-132) e fecha a conta e o inventário do NPC morto (DEC-146). O bloco do save só ganha
## conteúdo quando há estado (sem dono e sem movimento continua `{}`); `goods` e `markets` só entram quando há bens ou mercados.

const CODE_INVALID_SAVE: String = EconomyCodes.INVALID_SAVE
const KEY_OWNERS: String = "owners"
const KEY_LEDGER: String = "ledger"
const KEY_GOODS: String = "goods"
const KEY_MARKETS: String = "markets"
const NPC_DIED: String = "NpcDied"
## Tipo do dono que o `npc` abre (id em `owner_kinds.json`); só para o aviso de morte, que fecha o dono desse tipo.
const KIND_NPC: String = "npc"

var _record_history: bool
var _definitions: EconomyDefinitions
var _events: EventBus
var _ids: IdGenerator
var _clock: SimClock
var _subscription: int = EventBus.NO_SUBSCRIPTION
var _book: OwnerBook
var _ledger: Ledger
var _goods: GoodsStore
var _markets: MarketBook
## O último dia do relógio cujo fim já foi processado. Não vai no save: o relógio é restaurado pelo `core` antes dos módulos, e a cada passo o dia já processado é o do relógio.
var _last_day: int = 0


## `record_history`: modo de teste do `Ledger` (guarda cada lançamento). `definitions`: o conteúdo já lido (vazio por padrão: sem bens, sem mercados, qualquer tipo de dono).
func _init(record_history: bool = false, definitions: EconomyDefinitions = null) -> void:
	_record_history = record_history
	_definitions = definitions if definitions != null else EconomyDefinitions.new()
	_reset()


func setup(ctx: SimContext) -> void:
	_events = ctx.events
	_ids = ctx.ids
	_clock = ctx.clock


func post_setup() -> void:
	_subscription = _events.subscribe(NPC_DIED, _on_npc_died)


func teardown() -> void:
	if _events != null and _subscription != EventBus.NO_SUBSCRIPTION:
		_events.unsubscribe(_subscription)
	_subscription = EventBus.NO_SUBSCRIPTION


## Jogo novo: um mercado por assentamento dos dados, com o saldo inicial do tipo `market` (motivo `game_start`) e o estoque inicial de cada bem. Falha visível (`push_error`) se um dado não couber.
func on_new_game(_world_seed: int) -> void:
	_last_day = _current_day()
	if _markets == null:
		return
	for settlement_id: String in _markets.settlement_ids():
		var market_id: int = _ids.next_id()
		var opened: Result = _book.open_owner(market_id, MarketBook.KIND_MARKET)
		if opened.ok:
			opened = _fund_market(market_id, settlement_id)
		if not opened.ok:
			push_error("EconomyModule.on_new_game: o mercado de '%s' não abriu: %s" % [settlement_id, opened.message])
			continue
		_markets.register_market(settlement_id, market_id)


## Ao virar o dia do relógio, cada dia que passou fecha com `end_of_day` dos mercados e os eventos saem.
func tick(_elapsed_minutes: int) -> void:
	if _markets == null or _clock == null:
		return
	var day: int = _current_day()
	while _last_day < day:
		_last_day += 1
		for event: SimEvent in _markets.end_of_day():
			_events.publish(event)


## Sem dono e sem movimento: bloco vazio (nada entra no hash além da presença do módulo).
func serialize() -> Dictionary:
	if _book.is_empty() and _ledger.is_pristine() and _goods.is_pristine():
		return {}
	var block: Dictionary = {KEY_OWNERS: _book.serialize(), KEY_LEDGER: _ledger.serialize()}
	if not _goods.is_pristine():
		block[KEY_GOODS] = _goods.serialize()
	if _markets != null and not _markets.is_pristine():
		block[KEY_MARKETS] = _markets.serialize()
	return block


## Aceita o bloco vazio ou os campos conhecidos (`owners` e `ledger` sempre; `goods` e `markets` quando há), tudo conferido antes de trocar o estado; qualquer outra chave é recusada com mensagem clara.
func on_load(data: Dictionary) -> Result:
	if data.is_empty():
		_reset()
		return Result.success()
	var names: PackedStringArray = PackedStringArray()
	for key: Variant in data.keys():
		names.append(str(key))
	names.sort()
	for name: String in names:
		if not [KEY_OWNERS, KEY_LEDGER, KEY_GOODS, KEY_MARKETS].has(name):
			return Result.failure(CODE_INVALID_SAVE, "EconomyModule.on_load: o bloco 'economy' do save tem %d chave(s) (%s); esperado vazio ou só '%s', '%s', '%s' e '%s'." % [names.size(), ", ".join(names), KEY_OWNERS, KEY_LEDGER, KEY_GOODS, KEY_MARKETS])
	# Variant: valores crus do save (JSON); o tipo é conferido na linha seguinte.
	var raw_owners: Variant = data.get(KEY_OWNERS)
	var raw_ledger: Variant = data.get(KEY_LEDGER)
	var raw_goods: Variant = data.get(KEY_GOODS, {})
	var raw_markets: Variant = data.get(KEY_MARKETS, {})
	if typeof(raw_owners) != TYPE_DICTIONARY or typeof(raw_ledger) != TYPE_DICTIONARY or typeof(raw_goods) != TYPE_DICTIONARY or typeof(raw_markets) != TYPE_DICTIONARY:
		return Result.failure(CODE_INVALID_SAVE, "EconomyModule.on_load: '%s' e '%s' devem ser objetos e estar os dois no bloco 'economy' (e '%s' e '%s', se houver, também objetos)." % [KEY_OWNERS, KEY_LEDGER, KEY_GOODS, KEY_MARKETS])
	var market_data: Dictionary = raw_markets
	var book: OwnerBook = OwnerBook.new()
	var loaded: Result = book.load_from(raw_owners)
	if not loaded.ok:
		return loaded
	var ledger: Ledger = Ledger.new(book, _record_history)
	loaded = ledger.load_from(raw_ledger)
	if not loaded.ok:
		return loaded
	var goods: GoodsStore = GoodsStore.new(book, _definitions.goods, _definitions.kinds)
	var goods_data: Dictionary = raw_goods
	if not goods_data.is_empty():
		loaded = goods.load_from(goods_data)
		if not loaded.ok:
			return loaded
	var markets: MarketBook = _new_market_book(book, goods)
	if not market_data.is_empty():
		if markets == null:
			return Result.failure(CODE_INVALID_SAVE, "EconomyModule.on_load: o save tem mercados, mas este módulo não recebeu as constantes de preço.")
		loaded = markets.load_from(market_data)
		if not loaded.ok:
			return loaded
	_book = book
	_ledger = ledger
	_goods = goods
	_markets = markets
	_last_day = _current_day()
	return Result.success()


func validate() -> Array[String]:
	var problems: Array[String] = []
	for problem: String in _book.validate():
		problems.append("[owners] " + problem)
	for problem: String in _ledger.validate():
		problems.append("[ledger] " + problem)
	for problem: String in _goods.validate():
		problems.append("[goods] " + problem)
	if _markets != null:
		for problem: String in _markets.validate():
			problems.append("[markets] " + problem)
	return problems


## Abre o dono (conta e inventário). Idempotente: quem já existe fica como está. Falhas: `ECON_UNKNOWN_OWNER` (ID fora da faixa) e `ECON_DATA_INVALID` (tipo vazio ou, havendo definições, tipo que não existe).
func request_open_owner(owner_id: int, kind: String) -> Result:
	if not _definitions.kinds.is_empty() and not kind.is_empty():
		var known: Array[String] = []
		for kind_def: OwnerKindDef in _definitions.kinds:
			known.append(kind_def.id)
		if not known.has(kind):
			return Result.failure(EconomyCodes.DATA_INVALID, "EconomyModule.request_open_owner: o tipo de dono '%s' não existe; esperado um de: %s." % [kind, ", ".join(known)])
	return _book.open_owner(owner_id, kind)


## Move bens entre donos, sem criar nem destruir; tudo ou nada. Falhas: `ECON_UNKNOWN_GOOD`, `ECON_BAD_QUANTITY`, `ECON_UNKNOWN_OWNER`, `ECON_OWNER_CLOSED`, `ECON_INSUFFICIENT_GOODS` e `ECON_CAPACITY_EXCEEDED`.
func request_transfer_goods(from_id: int, to_id: int, good_id: String, quantity: int) -> Result:
	return _goods.transfer(from_id, to_id, good_id, quantity)


## Comando de DEPURAÇÃO (só em build de desenvolvimento, `EconomyDefinitions.is_development_build`; fora dele `ECON_DEV_ONLY`): põe o estoque do bem no mercado em `quantity`, criando (`produced`) ou
## destruindo (`consumed`) a diferença, para testar escassez. Mesmas falhas dos bens e `ECON_UNKNOWN_MARKET`.
func request_set_stock(market_id: int, good_id: String, quantity: int) -> Result:
	if not _definitions.is_development_build:
		return Result.failure(EconomyCodes.DEV_ONLY, "EconomyModule.request_set_stock: comando só existe em build de desenvolvimento (EconomyDefinitions.is_development_build).")
	if _markets == null or not _markets.has_market(market_id):
		return Result.failure(EconomyCodes.UNKNOWN_MARKET, "EconomyModule.request_set_stock: o mercado %d não existe." % market_id)
	if quantity < 0:
		return Result.failure(EconomyCodes.BAD_QUANTITY, "EconomyModule.request_set_stock: quantidade %d inválida; esperado 0 ou mais." % quantity)
	var current: int = _goods.quantity_of(market_id, good_id)
	if quantity > current:
		return _goods.create(market_id, good_id, quantity - current, GoodsStore.REASON_PRODUCED)
	if quantity < current:
		return _goods.destroy(market_id, good_id, current - quantity, GoodsStore.REASON_CONSUMED)
	return Result.success()


func peek_balance(owner_id: int) -> EconomyReplies.BalanceQuery:
	if not _book.has_owner(owner_id):
		return EconomyReplies.BalanceQuery.new(Result.failure(EconomyCodes.UNKNOWN_OWNER, "EconomyModule.peek_balance: o dono %d não existe." % owner_id), 0)
	return EconomyReplies.BalanceQuery.new(Result.success(), _ledger.balance_of(owner_id))


func peek_conservation() -> EconomyReplies.ConservationQuery:
	return EconomyReplies.ConservationQuery.new(_ledger.sum_of_balances(), _ledger.total_created(), _ledger.total_destroyed())


func peek_ledger_totals() -> EconomyReplies.LedgerTotals:
	return EconomyReplies.LedgerTotals.new(_ledger.totals_rows())


func peek_inventory(owner_id: int) -> EconomyReplies.InventoryQuery:
	if not _book.has_owner(owner_id):
		return EconomyReplies.InventoryQuery.new(Result.failure(EconomyCodes.UNKNOWN_OWNER, "EconomyModule.peek_inventory: o dono %d não existe." % owner_id), [], 0, 0)
	return EconomyReplies.InventoryQuery.new(Result.success(), _goods.inventory_rows(owner_id), _goods.weight_of(owner_id), _goods.capacity_of(owner_id))


func peek_goods_conservation() -> EconomyReplies.GoodsConservationQuery:
	return EconomyReplies.GoodsConservationQuery.new(_goods.conservation_rows())


## O mercado do assentamento (`ECON_UNKNOWN_MARKET` se o assentamento não tem).
func peek_market_of(settlement_id: String) -> EconomyReplies.MarketQuery:
	var market_id: int = IdGenerator.NO_ID if _markets == null else _markets.market_of(settlement_id)
	if market_id == IdGenerator.NO_ID:
		return EconomyReplies.MarketQuery.new(Result.failure(EconomyCodes.UNKNOWN_MARKET, "EconomyModule.peek_market_of: o assentamento '%s' não tem mercado." % settlement_id), IdGenerator.NO_ID, "", [])
	return peek_market(market_id)


## Uma linha por bem negociado (`good_id`, `stock`, `target_stock`, `price`, `ask`, `bid`, `in_shortage`), por `good_id` crescente.
func peek_market(market_id: int) -> EconomyReplies.MarketQuery:
	if _markets == null or not _markets.has_market(market_id):
		return EconomyReplies.MarketQuery.new(Result.failure(EconomyCodes.UNKNOWN_MARKET, "EconomyModule.peek_market: o mercado %d não existe." % market_id), IdGenerator.NO_ID, "", [])
	var settlement_id: String = _markets.settlement_of(market_id)
	var rows: Array[Dictionary] = []
	for good_id: String in _markets.traded_goods(settlement_id):
		rows.append({"good_id": good_id, "stock": _goods.quantity_of(market_id, good_id), "target_stock": _markets.target_of(market_id, good_id), "price": _markets.price_of(market_id, good_id), "ask": _markets.ask_of(market_id, good_id), "bid": _markets.bid_of(market_id, good_id), "in_shortage": _markets.is_in_shortage(market_id, good_id)})
	return EconomyReplies.MarketQuery.new(Result.success(), market_id, settlement_id, rows)


## O preço de tabela do bem no mercado (`ECON_UNKNOWN_MARKET` ou `ECON_UNKNOWN_GOOD` se o mercado não existe ou não negocia o bem).
func peek_price(market_id: int, good_id: String) -> EconomyReplies.ValueQuery:
	var checked: Result = _check_traded(market_id, good_id, "peek_price")
	return EconomyReplies.ValueQuery.new(checked, _markets.price_of(market_id, good_id) if checked.ok else 0)


## O estoque do bem no mercado (a quantidade do dono mercado), com as mesmas falhas de `peek_price`.
func peek_stock(market_id: int, good_id: String) -> EconomyReplies.ValueQuery:
	var checked: Result = _check_traded(market_id, good_id, "peek_stock")
	return EconomyReplies.ValueQuery.new(checked, _goods.quantity_of(market_id, good_id) if checked.ok else 0)


## `NpcDied` (DEC-146): fecha o dono do NPC, se ele existe e é do tipo `npc`. NPC que nunca abriu conta não é erro. O evento é lido pelo campo `npc_id`, sem citar a classe do `npc`.
func _on_npc_died(event: SimEvent) -> void:
	# Variant: campo cru do evento; o tipo é conferido na linha seguinte.
	var raw_id: Variant = event.get("npc_id")
	if typeof(raw_id) != TYPE_INT:
		return
	var owner_id: int = raw_id
	if _book.has_owner(owner_id) and _book.kind_of(owner_id) == KIND_NPC:
		_book.close_owner(owner_id)


func _check_traded(market_id: int, good_id: String, operation: String) -> Result:
	if _markets == null or not _markets.has_market(market_id):
		return Result.failure(EconomyCodes.UNKNOWN_MARKET, "EconomyModule.%s: o mercado %d não existe." % [operation, market_id])
	if not _markets.is_traded(market_id, good_id):
		return Result.failure(EconomyCodes.UNKNOWN_GOOD, "EconomyModule.%s: o bem '%s' não é negociado no mercado %d." % [operation, good_id, market_id])
	return Result.success()


## Saldo inicial do tipo `market` (se o tipo tem) e o estoque inicial de cada bem negociado no assentamento.
func _fund_market(market_id: int, settlement_id: String) -> Result:
	for kind: OwnerKindDef in _definitions.kinds:
		if kind.id == MarketBook.KIND_MARKET and kind.initial_balance > 0:
			var minted: Result = _ledger.mint(market_id, kind.initial_balance, Ledger.REASON_GAME_START)
			if not minted.ok:
				return minted
	for good_id: String in _markets.traded_goods(settlement_id):
		var initial_stock: int = _markets.initial_stock_of(settlement_id, good_id)
		if initial_stock > 0:
			var created: Result = _goods.create(market_id, good_id, initial_stock, GoodsStore.REASON_GAME_START)
			if not created.ok:
				return created
	return Result.success()


func _current_day() -> int:
	return IntMath.floor_div(_clock.total_minutes(), SimClock.MINUTES_PER_DAY) if _clock != null else 0


func _new_market_book(book: OwnerBook, goods: GoodsStore) -> MarketBook:
	if _definitions.price_params == null:
		return null
	return MarketBook.new(book, goods, _definitions.goods, _definitions.market_targets, _definitions.price_params)


func _reset() -> void:
	_book = OwnerBook.new()
	_ledger = Ledger.new(_book, _record_history)
	_goods = GoodsStore.new(_book, _definitions.goods, _definitions.kinds)
	_markets = _new_market_book(_book, _goods)
