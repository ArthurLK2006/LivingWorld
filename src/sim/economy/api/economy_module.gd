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
## LW-098c: o tipo de dono `merchant` (o `NpcDied` fecha também o dono desse tipo e apaga a caravana dele) e o livro de caravanas (`CaravanBook`), que NASCE VAZIO; a porta ganha `peek_caravan` e `peek_caravans_on` (respostas em `CaravanReplies`).
## LW-098d1: a PARTIDA (`request_start_caravan`) e os planos (`peek_trade_plans`), feitos pelo `CaravanRunner`, e a porta de rotas do `world` pelo construtor (parâmetro OPCIONAL, 9.2); sem ela, ou sem os parâmetros da caravana nas definições, não há caravana (`ECON_NO_ROUTE`) e nada muda. O jogo real segue sem comerciante.
## LW-098d2: a CHEGADA: o `tick` confere as caravanas a cada passo (`EconomyRuntime.check_arrivals`); ao fim do último trecho o `CaravanRunner` vende o lote, apaga o registro e a economia publica o `CaravanArrived` (em `api/`). Sem caravana no livro nada muda.
## LW-098e: a economia OUVE `RouteStateChanged` pelo NOME do evento (como o `NpcDied`; não publica evento novo): rota fechada sob a caravana a segura (`held`), rota reaberta a retoma e o fim de trecho com a rota seguinte fechada desvia (`CaravanRunner`). Sem caravana no livro nada muda.

const CODE_INVALID_SAVE: String = EconomyCodes.INVALID_SAVE
const KEY_OWNERS: String = EconomyPersistence.KEY_OWNERS
const KEY_LEDGER: String = EconomyPersistence.KEY_LEDGER
const KEY_GOODS: String = EconomyPersistence.KEY_GOODS
const KEY_MARKETS: String = EconomyPersistence.KEY_MARKETS
const KEY_PRODUCTION: String = EconomyPersistence.KEY_PRODUCTION
const NPC_DIED: String = "NpcDied"
## O evento do `world` que a economia ouve (LW-098e), pelo NOME, lido pelos campos `route_id` e `new_state` (9.2).
const ROUTE_STATE_CHANGED: String = "RouteStateChanged"
## Tipo do dono que o `npc` abre (id em `owner_kinds.json`); só para o aviso de morte, que fecha o dono desse tipo.
const KIND_NPC: String = "npc"
## Tipo do dono do comerciante (id em `owner_kinds.json`; LW-098c): carrinho de peso 120 e saldo 300 [HIP]. O `NpcDied` o fecha como fecha o `npc`.
const KIND_MERCHANT: String = CaravanBook.KIND_MERCHANT

var _record_history: bool
var _definitions: EconomyDefinitions
var _events: EventBus
var _ids: IdGenerator
var _clock: SimClock
var _subscription: int = EventBus.NO_SUBSCRIPTION
var _route_subscription: int = EventBus.NO_SUBSCRIPTION
var _rules: TradeRules
var _state: EconomyState
## A porta de rotas do `world` (LW-098d1; 9.2): `peek_route` e `peek_path`. Nula nos testes sem `world`; no jogo montado o `GameModules` a passa desde a LW-098d3 (sem ela não há caravana).
var _world: WorldModule
## A última hora cheia do relógio já processada (a produção anda por hora; o fim do dia é a hora que vira múltiplo de 24). Não vai no save: o relógio é restaurado pelo `core` antes dos módulos, e a cada passo a hora já processada é a do relógio.
var _last_hour: int = 0


## `record_history`: modo de teste do `Ledger` (guarda cada lançamento). `definitions`: o conteúdo já lido (vazio por padrão: sem bens, sem mercados, qualquer tipo de dono). `world_module`: a porta de rotas (LW-098d1; opcional, como o `npc` recebe a economia).
func _init(record_history: bool = false, definitions: EconomyDefinitions = null, world_module: WorldModule = null) -> void:
	_record_history = record_history
	_world = world_module
	_definitions = definitions if definitions != null else EconomyDefinitions.new()
	_rules = _definitions.trade_rules if _definitions.trade_rules != null else NeutralTradeRules.new()
	_state = EconomyState.create(_definitions, _rules, _record_history)


func setup(ctx: SimContext) -> void:
	_events = ctx.events
	_ids = ctx.ids
	_clock = ctx.clock


func post_setup() -> void:
	_subscription = _events.subscribe(NPC_DIED, _on_npc_died)
	_route_subscription = _events.subscribe(ROUTE_STATE_CHANGED, _on_route_state_changed)


func teardown() -> void:
	if _events != null:
		for subscription: int in [_subscription, _route_subscription]:
			if subscription != EventBus.NO_SUBSCRIPTION:
				_events.unsubscribe(subscription)
	_subscription = EventBus.NO_SUBSCRIPTION
	_route_subscription = EventBus.NO_SUBSCRIPTION


## Jogo novo: um mercado por assentamento dos dados, com o saldo inicial do tipo `market` (motivo `game_start`) e o estoque inicial de cada bem. Falha visível (`push_error`) se um dado não couber.
func on_new_game(_world_seed: int) -> void:
	_last_hour = _current_hour()
	EconomyRuntime.open_new_game(_state, _ids)


## A CADA passo, antes das horas cheias: as chegadas das caravanas (LW-098d2; a chegada é por minuto, e com o livro vazio isto sai na hora). Depois, a cada hora cheia que passa: se ela vira um dia, o fim do dia (mercados, depois locais de produção) vem primeiro; depois a hora de produção. Os eventos saem.
## LW-107c3: cada hora é processada com o relógio DAQUELA hora (`hora x 60`), não com o do fim do passo: num passo que cobre várias horas (cadência de 180 minutos, por exemplo) as horas atrasadas dão o mesmo prazo de contrato, o mesmo vencimento e o mesmo hash que passos de 1, 7 ou 60 minutos. Com passos de 1 minuto os dois relógios são o mesmo.
func tick(_elapsed_minutes: int) -> void:
	if _state.markets == null or _clock == null:
		return
	EconomyRuntime.check_arrivals(_state, _world, _events, _clock.total_minutes())
	var hour: int = _current_hour()
	while _last_hour < hour:
		_last_hour += 1
		if _last_hour % SimClock.HOURS_PER_DAY == 0:
			EconomyRuntime.close_day(_state, _events)
		EconomyRuntime.run_production_hour(_state, _events, _ids, _last_hour * SimClock.MINUTES_PER_HOUR)


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
	var problems: Array[String] = EconomyPersistence.validation_problems(_state)
	for problem: String in _caravan_runner().route_problems():
		problems.append("[caravans] " + problem)
	return problems


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


## Posta um contrato `labor` ou `delivery` (LW-096; seção 8 do contrato): o emissor paga a recompensa para a custódia (`contract_escrow`) e o `ContractOffered` sai. `objective`: `labor` com `place_id` e `minutes`; `delivery` com `good_id`, `quantity` e `destination_id`.
## `deadline` é um minuto de simulação depois de agora. Tudo ou nada; falhas: `ECON_UNKNOWN_OWNER`, `ECON_OWNER_CLOSED`, `ECON_BAD_AMOUNT`, `ECON_CONTRACT_IMPOSSIBLE`, `ECON_INSUFFICIENT_FUNDS`. A recusa NUNCA gasta ID (a validação vem antes de pedir o ID; R13-I1). Sem `setup` do `World` (sem relógio nem IDs) nada é postado.
func request_post_contract(kind: String, issuer_id: int, reward: int, deadline: int, objective: Dictionary) -> EconomyReplies.PostContractResult:
	if _ids == null or _events == null or _clock == null:
		return EconomyReplies.PostContractResult.new(Result.failure(EconomyCodes.CONTRACT_IMPOSSIBLE, "EconomyModule.request_post_contract: módulo sem setup (sem relógio, IDs nem barramento); esperado um módulo registrado no World."), IdGenerator.NO_ID)
	var refused: Result = _state.contracts.check_post(kind, issuer_id, reward, deadline, _clock.total_minutes(), objective)
	if not refused.ok:
		return EconomyReplies.PostContractResult.new(refused, IdGenerator.NO_ID)
	var contract_id: int = _ids.next_id()
	var posted: Result = _state.contracts.post(contract_id, kind, issuer_id, reward, deadline, _clock.total_minutes(), objective)
	if not posted.ok:
		return EconomyReplies.PostContractResult.new(posted, IdGenerator.NO_ID)
	_events.publish(ContractOffered.new(contract_id, kind, issuer_id, reward, deadline))
	return EconomyReplies.PostContractResult.new(posted, contract_id)


## Registra `minutes` de trabalho no local `place_id` para o contrato `labor` que o trabalhador aceitou ali (LW-096; seção 8): ao completar os minutos do contrato, dentro do prazo, a custódia o paga e o `ContractCompleted` sai. SÓ para contrato `labor`:
## recusado com `ECON_WORKER_ALREADY_ASSIGNED` se o trabalhador já é atribuído ao local (a folha o paga). Tudo ou nada. Outras falhas: `ECON_UNKNOWN_OWNER`, `ECON_OWNER_CLOSED`, `ECON_CONTRACT_IMPOSSIBLE`, `ECON_UNKNOWN_CONTRACT`.
func request_work_shift(place_id: String, worker_id: int, minutes: int) -> Result:
	if _clock == null or _events == null:
		return Result.failure(EconomyCodes.CONTRACT_IMPOSSIBLE, "EconomyModule.request_work_shift: módulo sem setup (sem relógio nem barramento); esperado um módulo registrado no World.")
	return _announce(_state.contracts.work_shift(place_id, worker_id, minutes, _clock.total_minutes()))


## Entrega os bens do contrato `delivery` aceito ao destino e a custódia paga o aceitante (LW-096). Tudo ou nada; falhas: `ECON_UNKNOWN_CONTRACT`, `ECON_CONTRACT_NOT_OPEN`, `ECON_CONTRACT_IMPOSSIBLE` e as dos bens.
func request_deliver_contract(contract_id: int) -> Result:
	if _clock == null or _events == null:
		return Result.failure(EconomyCodes.CONTRACT_IMPOSSIBLE, "EconomyModule.request_deliver_contract: módulo sem setup (sem relógio nem barramento); esperado um módulo registrado no World.")
	return _announce(_state.contracts.deliver(contract_id, _clock.total_minutes()))


## Aceita o contrato (LW-096): só `open` e dentro do prazo (`agora < prazo`, pelo relógio determinístico, a mesma regra da entrega; correção de 14/11/2026), um aceitante aberto que não é o emissor. A VAGA é aceita por um NPC: o atribui ao local de trabalho, tira a atribuição anterior e conclui o contrato na hora (`ContractCompleted`, recompensa 0). Falhas: `ECON_UNKNOWN_CONTRACT`, `ECON_CONTRACT_NOT_OPEN`, `ECON_UNKNOWN_OWNER`, `ECON_OWNER_CLOSED`, `ECON_CONTRACT_IMPOSSIBLE` (inclui o prazo vencido; a vaga não tem prazo).
func request_accept_contract(contract_id: int, actor_id: int) -> Result:
	if _state.contracts.state_of(contract_id).get(ContractBook.KEY_KIND) == ContractBook.VACANCY:
		if _events == null:
			return Result.failure(EconomyCodes.CONTRACT_IMPOSSIBLE, "EconomyModule.request_accept_contract: módulo sem setup (sem barramento); esperado um módulo registrado no World.")
		return _announce(EconomyVacancies.accept(_state, contract_id, actor_id))
	if _clock == null:
		return Result.failure(EconomyCodes.CONTRACT_IMPOSSIBLE, "EconomyModule.request_accept_contract: módulo sem setup (sem relógio); esperado um módulo registrado no World.")
	return _state.contracts.accept(contract_id, actor_id, _clock.total_minutes())


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


## A PARTIDA da caravana (LW-098d1; 9.4 e 9.8), ATÔMICA: compra o lote no mercado de origem (o mesmo `TradeEngine.execute` do `request_trade`) e registra a caravana, ou nada muda. Devolve o minuto previsto da chegada (`eta_minute`) e o que o lote custou (`cost_paid`).
## NÃO exige lucro (a decisão de partir é do `npc`); a chegada e a venda vêm depois, no `tick` (LW-098d2). Falhas: `ECON_NO_ROUTE` (sem caminho aberto, origem igual ao destino, sem a porta de rotas, sem os parâmetros ou sem `setup`), `ECON_CARAVAN_BUSY`, `ECON_TRADER_NOT_ALLOWED` e as do comércio: `ECON_UNKNOWN_OWNER`,
## `ECON_OWNER_CLOSED`, `ECON_UNKNOWN_MARKET`, `ECON_UNKNOWN_GOOD`, `ECON_BAD_QUANTITY`, `ECON_TRADE_BANNED`, `ECON_INSUFFICIENT_STOCK`, `ECON_INSUFFICIENT_FUNDS` e `ECON_CAPACITY_EXCEEDED`.
func request_start_caravan(trader_id: int, origin_market_id: int, destination_market_id: int, good_id: String, quantity: int) -> CaravanReplies.StartResult:
	if _clock == null:
		return CaravanReplies.StartResult.new(Result.failure(EconomyCodes.NO_ROUTE, "EconomyModule.request_start_caravan: módulo sem setup (sem relógio); esperado um módulo registrado no World."))
	return _caravan_runner().start(trader_id, origin_market_id, destination_market_id, good_id, quantity, _clock.total_minutes())


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


## O posto de serviço `post_id` (`ECON_UNKNOWN_OWNER` se não existe): ofício, salário por hora, equipe e se a folha está paga (`NO_FUNDS` quando não está; seção 6 do contrato).
func peek_post(post_id: int) -> EconomyReplies.PostQuery:
	return EconomyQueries.peek_post(_state, post_id)


## O posto de serviço que ocupa o local `place_id` (`ECON_UNKNOWN_OWNER` se não há).
func peek_post_at(place_id: String) -> EconomyReplies.PostQuery:
	return EconomyQueries.peek_post_at(_state, place_id)


## Os postos de serviço do assentamento, por ID crescente (lista vazia se não há).
func peek_posts_of(settlement_id: String) -> EconomyReplies.PostsQuery:
	return EconomyQueries.peek_posts_of(_state, settlement_id)


## O contrato `contract_id` (`ECON_UNKNOWN_CONTRACT` se não existe): tipo, emissor, recompensa, prazo, estado, aceitante e o objetivo do tipo (seção 8 do contrato).
func peek_contract(contract_id: int) -> EconomyReplies.ContractQuery:
	return EconomyQueries.peek_contract(_state, contract_id)


## Os contratos que passam pelo filtro (estado, emissor e local de trabalho; os valores vazios deixam passar), por ID crescente.
func peek_contracts(state_filter: String = "", issuer_id: int = IdGenerator.NO_ID, place_id: String = "") -> EconomyReplies.ContractsQuery:
	return EconomyQueries.peek_contracts(_state, state_filter, issuer_id, place_id)


## A caravana do comerciante (LW-098c): `found` falso = parado; `ECON_UNKNOWN_OWNER` se o dono não existe (cópia, 9.8). Com a porta de rotas e os parâmetros (LW-098d1), os cinco campos derivados (o trecho, a posição pelo relógio e o ETA, 9.3) vêm preenchidos.
func peek_caravan(trader_id: int) -> CaravanReplies.CaravanQuery:
	if not _state.book.has_owner(trader_id):
		return CaravanReplies.CaravanQuery.new(Result.failure(EconomyCodes.UNKNOWN_OWNER, "EconomyModule.peek_caravan: o dono %d não existe." % trader_id))
	var caravan: Caravan = _state.caravans.caravan_of(trader_id)
	if caravan == null:
		return CaravanReplies.CaravanQuery.new(Result.success())
	return _caravan_runner().row_of(caravan, _now())


## As caravanas na estrada (andando, ou paradas no meio do trecho) cujo trecho atual é a rota, por `trader_id` crescente (pedido do `military.md` 7).
func peek_caravans_on(route_id: String) -> CaravanReplies.CaravansQuery:
	var runner: CaravanRunner = _caravan_runner()
	var rows: Array[CaravanReplies.CaravanQuery] = []
	for trader_id: int in _state.caravans.trader_ids():
		var caravan: Caravan = _state.caravans.caravan_of(trader_id)
		if caravan.is_on_road() and caravan.current_route_id() == route_id:
			rows.append(runner.row_of(caravan, _now()))
	return CaravanReplies.CaravansQuery.new(rows)


## O melhor plano de viagem do comerciante saindo da origem, um por destino com caminho aberto, só os que passam dos limiares de 9.5 e por `destination_market_id` crescente (LW-098d1; 9.8): é a conta do `TradePlanner` (098b) e NÃO muda estado.
## Falhas: `ECON_NO_ROUTE` (sem a porta de rotas, sem os parâmetros ou sem mercados), `ECON_UNKNOWN_OWNER`, `ECON_OWNER_CLOSED`, `ECON_TRADER_NOT_ALLOWED` (o dono não é `merchant`) e `ECON_UNKNOWN_MARKET`.
func peek_trade_plans(trader_id: int, origin_market_id: int) -> CaravanReplies.PlansQuery:
	return _caravan_runner().plans(trader_id, origin_market_id)


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


## `NpcDied` (DEC-146): fecha o dono do NPC, se ele existe e é do tipo `npc` ou `merchant` (LW-098c), e apaga a caravana do comerciante (o saldo e a carga ficam na conta fechada, na soma). NPC que nunca abriu conta não é erro. O evento é lido pelo campo `npc_id`, sem citar a classe do `npc`.
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
	_state.caravans.remove(owner_id)
	if _state.book.has_owner(owner_id) and [KIND_NPC, KIND_MERCHANT].has(_state.book.kind_of(owner_id)):
		_state.book.close_owner(owner_id)


## `RouteStateChanged` (LW-098e; 9.7): a rota fechou ou reabriu; o `CaravanRunner` segura, retoma ou refaz o caminho das caravanas, em ordem de `trader_id`. Os campos são lidos pelo nome, sem citar a classe do `world`; carga de outro tipo é ignorada e, com o livro vazio, sai logo.
func _on_route_state_changed(event: SimEvent) -> void:
	# Variant: campos crus do evento; o tipo é conferido na linha seguinte.
	var raw_route: Variant = event.get("route_id")
	var raw_state: Variant = event.get("new_state")
	if typeof(raw_route) != TYPE_STRING or typeof(raw_state) != TYPE_STRING or _state.caravans.is_pristine():
		return
	var route_id: String = raw_route
	var new_state: String = raw_state
	_caravan_runner().route_state_changed(route_id, new_state, _now())


## Publica o `ContractCompleted` se o comando concluiu o contrato e devolve o resultado dele.
func _announce(outcome: ContractBook.Outcome) -> Result:
	if outcome.completed:
		_events.publish(ContractCompleted.new(outcome.contract_id, outcome.acceptor_id, outcome.reward))
	return outcome.result


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


## O minuto de simulação de agora (0 sem `setup`).
func _now() -> int:
	return _clock.total_minutes() if _clock != null else 0


## O executor das caravanas sobre o estado de agora (o `on_load` troca o `_state`, então ele é montado a cada uso; é só referência).
func _caravan_runner() -> CaravanRunner:
	return CaravanRunner.new(_state, _world)
