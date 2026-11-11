class_name EconomyModule
extends SimModule
## Módulo `economy` (contrato em docs/modules/economy.md). LW-088a: a casca, registrada no `World` ANTES do `npc` (o `npc` vai abrir as contas ao criar NPCs) e dona do bloco `economy` do save (DEC-172).
## LW-088: o cadastro de donos (`OwnerBook`) e o livro-razão (`Ledger`). LW-089c: o inventário por dono (`GoodsStore`) e as definições (`EconomyDefinitions`, pelo construtor). LW-090c: os mercados (`MarketBook`):
## um por assentamento dos dados, criado no jogo novo (dono do tipo `market`, com o saldo inicial do tipo e o estoque inicial de cada bem), com o preço andando ao FIM DE CADA DIA do relógio e os eventos
## `PriceChanged`, `ShortageDeclared` e `ShortageEnded` publicados. LW-092c: os locais de produção (`ProductionBook`): um por linha de `production_sites.json`, criado no jogo novo (dono do tipo `site`, com o saldo inicial do tipo), com a
## HORA de produção a cada hora cheia do relógio e o fim do dia depois dos mercados; os trabalhadores entram quando o `npc` abre a conta com o `work_place_id` e saem no `NpcDied`; `peek_site`, `peek_site_at` e `peek_sites_of`. Esta é a PORTA: `request_open_owner` (com o `work_place_id` opcional), `request_transfer_goods`, `request_set_stock` (só em build de desenvolvimento), `request_trade`, `peek_quote`, `peek_terms`, `peek_balance`,
## `peek_conservation`, `peek_ledger_totals`, `peek_inventory`, `peek_goods_conservation`, `peek_market_of`, `peek_market`, `peek_price` e `peek_stock`. As operações de saldo e de criar e destruir bens NÃO são da
## porta: quem as usa são as partes internas da economia (comércio, produção, salário), cada uma na sua tarefa. O `npc` só pode citar classes desta pasta (regra E do `tools/check_architecture`, DEC-171) e a porta
## devolve só cópia (tipos de `EconomyReplies`). A economia ouve `NpcDied` pelo NOME do evento (não importa o `npc`, DEC-132) e fecha a conta e o inventário do NPC morto (DEC-146). O bloco do save só ganha
## conteúdo quando há estado (sem dono e sem movimento continua `{}`); `goods`, `markets` e `production` só entram quando há bens, mercados ou locais de produção.
## LW-092f: o módulo foi dividido sem mudar comportamento: o estado vivo está no `EconomyState`, as consultas no `EconomyQueries`, o jogo novo e o tempo no `EconomyRuntime` e o save, o `validate` e o resumo de depuração
## no `EconomyPersistence` (pasta `support/`); aqui ficam o ciclo de vida do `SimModule`, os comandos, o relógio e o aviso de morte. Cada `peek_*` é uma linha que chama a classe de apoio.

const CODE_INVALID_SAVE: String = EconomyCodes.INVALID_SAVE
const KEY_OWNERS: String = EconomyPersistence.KEY_OWNERS
const KEY_LEDGER: String = EconomyPersistence.KEY_LEDGER
const KEY_GOODS: String = EconomyPersistence.KEY_GOODS
const KEY_MARKETS: String = EconomyPersistence.KEY_MARKETS
const KEY_PRODUCTION: String = EconomyPersistence.KEY_PRODUCTION
const NPC_DIED: String = "NpcDied"
## Tipo do dono que o `npc` abre (id em `owner_kinds.json`); só para o aviso de morte, que fecha o dono desse tipo.
const KIND_NPC: String = "npc"

var _record_history: bool
var _definitions: EconomyDefinitions
var _events: EventBus
var _ids: IdGenerator
var _clock: SimClock
var _subscription: int = EventBus.NO_SUBSCRIPTION
var _rules: TradeRules
var _state: EconomyState
## A última hora cheia do relógio já processada (a produção anda por hora; o fim do dia é a hora que vira múltiplo de 24). Não vai no save: o relógio é restaurado pelo `core` antes dos módulos, e a cada passo a hora já processada é a do relógio.
var _last_hour: int = 0


## `record_history`: modo de teste do `Ledger` (guarda cada lançamento). `definitions`: o conteúdo já lido (vazio por padrão: sem bens, sem mercados, qualquer tipo de dono).
func _init(record_history: bool = false, definitions: EconomyDefinitions = null) -> void:
	_record_history = record_history
	_definitions = definitions if definitions != null else EconomyDefinitions.new()
	_rules = _definitions.trade_rules if _definitions.trade_rules != null else NeutralTradeRules.new()
	_state = EconomyState.create(_definitions, _rules, _record_history)


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
	_last_hour = _current_hour()
	EconomyRuntime.open_new_game(_state, _ids)


## A cada hora cheia que passa: se ela vira um dia, o fim do dia (mercados, depois locais de produção) vem primeiro; depois a hora de produção. Os eventos saem.
func tick(_elapsed_minutes: int) -> void:
	if _state.markets == null or _clock == null:
		return
	var hour: int = _current_hour()
	while _last_hour < hour:
		_last_hour += 1
		if _last_hour % SimClock.HOURS_PER_DAY == 0:
			EconomyRuntime.close_day(_state, _events)
		EconomyRuntime.run_production_hour(_state, _events)


## Sem dono e sem movimento: bloco vazio (nada entra no hash além da presença do módulo).
func serialize() -> Dictionary:
	return EconomyPersistence.serialize(_state)


## Aceita o bloco vazio ou os campos conhecidos (`owners` e `ledger` sempre; `goods`, `markets` e `production` quando há), tudo conferido antes de trocar o estado; qualquer outra chave é recusada com mensagem clara.
func on_load(data: Dictionary) -> Result:
	if data.is_empty():
		_state = EconomyState.create(_definitions, _rules, _record_history)
		return Result.success()
	var fresh: EconomyState = EconomyState.new(_definitions, _rules, _record_history)
	var loaded: Result = EconomyPersistence.load_into(fresh, data)
	if not loaded.ok:
		return loaded
	_state = fresh
	_last_hour = _current_hour()
	return Result.success()


func validate() -> Array[String]:
	return EconomyPersistence.validation_problems(_state)


## Resumo para o painel de depuração (backlog I4; revisão independente I1): só números e se a conservação do dinheiro e dos bens fecha. Não vai para o save nem para o hash.
func debug_summary() -> Dictionary:
	return EconomyPersistence.summary(_state)


## Abre o dono (conta e inventário) e, se o tipo tem saldo inicial, faz o `mint` `game_start` (LW-093, DEC-170; só na abertura). Idempotente: quem já existe fica como está. Falhas: `ECON_UNKNOWN_OWNER` (ID fora da faixa) e `ECON_DATA_INVALID` (tipo vazio ou, havendo definições, tipo que não existe). `work_place_id` (opcional) só vale
## para o tipo `npc` e só na ABERTURA da conta: o NPC é atribuído ao local de produção desse local; sem local de produção ali, ninguém é atribuído (e não é erro). Depois disso o emprego só muda por vaga aceita (LW-096) ou morte.
func request_open_owner(owner_id: int, kind: String, work_place_id: String = "") -> Result:
	if not _state.definitions.kinds.is_empty() and not kind.is_empty():
		var known: Array[String] = _state.known_kinds()
		if not known.has(kind):
			return Result.failure(EconomyCodes.DATA_INVALID, "EconomyModule.request_open_owner: o tipo de dono '%s' não existe; esperado um de: %s." % [kind, ", ".join(known)])
	var is_new: bool = not _state.book.has_owner(owner_id)
	var opened: Result = _state.book.open_owner(owner_id, kind)
	if opened.ok and is_new:
		opened = EconomyRuntime.mint_initial_balance(_state, owner_id, kind)
	if opened.ok and is_new and kind == KIND_NPC and not work_place_id.is_empty():
		return _assign_to_workplace(owner_id, work_place_id)
	return opened


## O NPC consome comida do inventário dele (LW-093; contrato, seção 7): destrói o bem (`consumed`) e devolve o alívio para o `npc` aplicar à necessidade (`EconomyReplies.ConsumeResult`).
func request_consume(owner_id: int, good_id: String, quantity: int) -> EconomyReplies.ConsumeResult:
	return EconomyCommands.consume(_state, owner_id, good_id, quantity)


## Move bens entre donos, sem criar nem destruir; tudo ou nada. Falhas: `ECON_UNKNOWN_GOOD`, `ECON_BAD_QUANTITY`, `ECON_UNKNOWN_OWNER`, `ECON_OWNER_CLOSED`, `ECON_INSUFFICIENT_GOODS` e `ECON_CAPACITY_EXCEEDED`.
func request_transfer_goods(from_id: int, to_id: int, good_id: String, quantity: int) -> Result:
	return _state.goods.transfer(from_id, to_id, good_id, quantity)


## Comando de DEPURAÇÃO (só em build de desenvolvimento, `EconomyDefinitions.is_development_build`; fora dele `ECON_DEV_ONLY`): põe o estoque do bem no mercado em `quantity`, criando (`produced`) ou
## destruindo (`consumed`) a diferença, para testar escassez. Mesmas falhas dos bens e `ECON_UNKNOWN_MARKET`.
func request_set_stock(market_id: int, good_id: String, quantity: int) -> Result:
	if not _state.definitions.is_development_build:
		return Result.failure(EconomyCodes.DEV_ONLY, "EconomyModule.request_set_stock: comando só existe em build de desenvolvimento (EconomyDefinitions.is_development_build).")
	if _state.markets == null or not _state.markets.has_market(market_id):
		return Result.failure(EconomyCodes.UNKNOWN_MARKET, "EconomyModule.request_set_stock: o mercado %d não existe." % market_id)
	if quantity < 0:
		return Result.failure(EconomyCodes.BAD_QUANTITY, "EconomyModule.request_set_stock: quantidade %d inválida; esperado 0 ou mais." % quantity)
	var current: int = _state.goods.quantity_of(market_id, good_id)
	if quantity > current:
		return _state.goods.create(market_id, good_id, quantity - current, GoodsStore.REASON_PRODUCED)
	if quantity < current:
		return _state.goods.destroy(market_id, good_id, current - quantity, GoodsStore.REASON_CONSUMED)
	return Result.success()


## A ordem de compra (`buy`) ou de venda (`sell`) de um ator num mercado: ATÔMICA, pelo `TradeEngine` (docs/modules/economy.md, seção 5). Falhas: `ECON_UNKNOWN_MARKET`, `ECON_UNKNOWN_GOOD`, `ECON_BAD_QUANTITY`, `ECON_TRADE_BANNED`,
## `ECON_UNKNOWN_OWNER`, `ECON_OWNER_CLOSED`, `ECON_INSUFFICIENT_STOCK`, `ECON_MARKET_FULL`, `ECON_INSUFFICIENT_FUNDS`, `ECON_MARKET_NO_FUNDS`, `ECON_INSUFFICIENT_GOODS` e `ECON_CAPACITY_EXCEEDED`; nada muda se falha.
func request_trade(actor_id: int, market_id: int, good_id: String, quantity: int, side: String) -> EconomyReplies.TradeResult:
	if _state.engine == null:
		return EconomyReplies.TradeResult.new(Result.failure(EconomyCodes.UNKNOWN_MARKET, "EconomyModule.request_trade: o mercado %d não existe (o módulo não tem mercados)." % market_id), 0, 0, 0)
	var outcome: TradeEngine.Outcome = _state.engine.execute(actor_id, market_id, good_id, quantity, side)
	return EconomyReplies.TradeResult.new(outcome.result, outcome.quantity, outcome.total, outcome.tariff)


## A mesma conta de `request_trade`, sem executar, PARA O ATOR (as regras de comércio podem depender de quem compra: proibição, tarifa, licença); serve à interface e ao `npc` para decidirem antes de pedir.
func peek_quote(actor_id: int, market_id: int, good_id: String, quantity: int, side: String) -> EconomyReplies.QuoteQuery:
	return EconomyQueries.peek_quote(_state, actor_id, market_id, good_id, quantity, side)


## A pergunta da `TradeRules` para o bem no mercado e o ator (a neutra devolve tudo livre).
func peek_terms(good_id: String, market_id: int, actor_id: int) -> EconomyReplies.TermsQuery:
	return EconomyQueries.peek_terms(_state, good_id, market_id, actor_id)


## O local de produção `site_id` (`ECON_UNKNOWN_OWNER` se não existe): receita, estado e motivo de parada, equipe, eficiência, manutenção e estoque (seções 6 e 8 do contrato).
func peek_site(site_id: int) -> EconomyReplies.SiteQuery:
	return EconomyQueries.peek_site(_state, site_id)


## O local de produção que ocupa o local `place_id` (`ECON_UNKNOWN_OWNER` se não há).
func peek_site_at(place_id: String) -> EconomyReplies.SiteQuery:
	return EconomyQueries.peek_site_at(_state, place_id)


## Os locais de produção do assentamento, por ID crescente (lista vazia se não há).
func peek_sites_of(settlement_id: String) -> EconomyReplies.SitesQuery:
	return EconomyQueries.peek_sites_of(_state, settlement_id)


func peek_balance(owner_id: int) -> EconomyReplies.BalanceQuery:
	return EconomyQueries.peek_balance(_state, owner_id)


func peek_conservation() -> EconomyReplies.ConservationQuery:
	return EconomyQueries.peek_conservation(_state)


func peek_ledger_totals() -> EconomyReplies.LedgerTotals:
	return EconomyQueries.peek_ledger_totals(_state)


func peek_inventory(owner_id: int) -> EconomyReplies.InventoryQuery:
	return EconomyQueries.peek_inventory(_state, owner_id)


func peek_goods_conservation() -> EconomyReplies.GoodsConservationQuery:
	return EconomyQueries.peek_goods_conservation(_state)


## O mercado do assentamento (`ECON_UNKNOWN_MARKET` se o assentamento não tem).
func peek_market_of(settlement_id: String) -> EconomyReplies.MarketQuery:
	return EconomyQueries.peek_market_of(_state, settlement_id)


## Uma linha por bem negociado (`good_id`, `stock`, `target_stock`, `price`, `ask`, `bid`, `in_shortage`), por `good_id` crescente.
func peek_market(market_id: int) -> EconomyReplies.MarketQuery:
	return EconomyQueries.peek_market(_state, market_id)


## O preço de tabela do bem no mercado (`ECON_UNKNOWN_MARKET` ou `ECON_UNKNOWN_GOOD` se o mercado não existe ou não negocia o bem).
func peek_price(market_id: int, good_id: String) -> EconomyReplies.ValueQuery:
	return EconomyQueries.peek_price(_state, market_id, good_id)


## A ficha do bem (`ECON_UNKNOWN_GOOD` se não existe): `need_id` e `need_relief` (só a comida os tem), `base_value` e `weight` (LW-093; o `npc` valoriza comida com isto).
func peek_good(good_id: String) -> EconomyReplies.GoodQuery:
	return EconomyQueries.peek_good(_state, good_id)


## Os bens que aliviam a necessidade (por `good_id` crescente; lista vazia se nenhum).
func peek_goods_for_need(need_id: String) -> EconomyReplies.GoodsQuery:
	return EconomyQueries.peek_goods_for_need(_state, need_id)


## O estoque do bem no mercado (a quantidade do dono mercado), com as mesmas falhas de `peek_price`.
func peek_stock(market_id: int, good_id: String) -> EconomyReplies.ValueQuery:
	return EconomyQueries.peek_stock(_state, market_id, good_id)


## `NpcDied` (DEC-146): fecha o dono do NPC, se ele existe e é do tipo `npc`. NPC que nunca abriu conta não é erro. O evento é lido pelo campo `npc_id`, sem citar a classe do `npc`.
func _on_npc_died(event: SimEvent) -> void:
	# Variant: campo cru do evento; o tipo é conferido na linha seguinte.
	var raw_id: Variant = event.get("npc_id")
	if typeof(raw_id) != TYPE_INT:
		return
	var owner_id: int = raw_id
	if _state.production != null:
		_state.production.remove_worker(owner_id)
	if _state.posts != null:
		_state.posts.remove_worker(owner_id)
	if _state.book.has_owner(owner_id) and _state.book.kind_of(owner_id) == KIND_NPC:
		_state.book.close_owner(owner_id)


## Atribui o NPC ao local de produção ou ao posto de serviço que ocupa `work_place_id`; sem nenhum dos dois ninguém é atribuído (e não é erro).
func _assign_to_workplace(npc_id: int, work_place_id: String) -> Result:
	if _state.production != null:
		var site_id: int = _state.production.site_at(work_place_id)
		if site_id != IdGenerator.NO_ID:
			return _state.production.assign_worker(site_id, npc_id)
	if _state.posts != null:
		var post_id: int = _state.posts.post_at(work_place_id)
		if post_id != IdGenerator.NO_ID:
			return _state.posts.assign_worker(post_id, npc_id)
	return Result.success()


func _current_hour() -> int:
	return IntMath.floor_div(_clock.total_minutes(), SimClock.MINUTES_PER_HOUR) if _clock != null else 0
