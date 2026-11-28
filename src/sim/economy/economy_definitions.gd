class_name EconomyDefinitions
extends RefCounted
## Definições (conteúdo de `data/economy/`, SÓ LEITURA) que o `EconomyModule` recebe pelo construtor, já lidas e validadas (sem global nem autoload, arquitetura 4.3). Cada tarefa da economia acrescenta a sua tabela
## aqui: bens e tipos de dono (LW-089c), alvos de mercado e constantes de preço (LW-090c), a regra de comércio (LW-091b) e as receitas, as constantes e as linhas dos locais de produção (LW-092c), os parâmetros da caravana (LW-098d1), os modelos de contrato do postador (LW-107c1) e os limites de encomendas por categoria (LW-107f2). Vazia (o padrão) é um módulo sem bens nem mercados: tudo que cita um bem falha com `ECON_UNKNOWN_GOOD`, qualquer tipo de
## dono é aceito e nenhum mercado nasce. `is_development_build` vem da fronteira do app (`OS.is_debug_build()`); a simulação nunca lê `OS`: liga os comandos de depuração (`request_set_stock`).

var goods: Array[GoodDef] = []
var kinds: Array[OwnerKindDef] = []
var market_targets: Array[MarketTargetDef] = []
var price_params: PriceParams
var is_development_build: bool = false
## A regra de comércio (DEC-049), entregue pronta ao construtor da economia; sem ela vale a neutra (`NeutralTradeRules`). Na Fase 4 o módulo `politics` entrega a sua.
var trade_rules: TradeRules
var recipes: Dictionary[String, RecipeDef] = {}
var site_params: SiteParams
var production_sites: Array[SiteDef] = []
## Os postos de serviço (LW-095): locais de trabalho sem receita, com a folha paga pela conta do mercado do povoado.
var service_posts: Array[PostDef] = []
## Os parâmetros do comerciante e da caravana (LW-098d1; `caravan_params.json`, lido pelo `CaravanParamsLoader`): OPCIONAIS. Sem eles não há caravana (`ECON_NO_ROUTE`, 9.2); o `EconomySetup` lê o arquivo e o põe aqui no jogo montado desde a LW-098d3.
var caravan_params: CaravanParams
## Os modelos de contrato do postador (LW-107c1; `contract_templates.json`, lido pelo `ContractTemplateLoader`): OPCIONAIS. Sem o arquivo a lista é vazia e o postador (LW-107c2) não posta nada; nenhum código a lê ainda.
var contract_templates: Array[ContractTemplateDef] = []
## Os limites de encomendas aceitas ao mesmo tempo, uma linha por categoria (LW-107f2; `contract_limits.json`, lido pelo `ContractLimitLoader`): OPCIONAIS. Sem o arquivo a lista é vazia (nenhuma categoria tem limite definido); só `EconomyModule.peek_contract_limit` a lê.
var contract_limits: Array[ContractLimitDef] = []
## Os parâmetros PRÓPRIOS do fluxo agregado por rota (LW-100d1a; `flow_params.json`, lido pelo `FlowParamsLoader`): OPCIONAIS e fora do construtor. Nulo = sem fluxo (`request_set_flow_enabled` devolve `ECON_NO_ROUTE`). Nada os põe no jogo montado ainda (é da LW-100e); os testes os põem direto.
var flow_params: FlowParams


func _init(good_defs: Array[GoodDef] = [], kind_defs: Array[OwnerKindDef] = [], targets: Array[MarketTargetDef] = [], params: PriceParams = null, development_build: bool = false, rules: TradeRules = null, recipe_defs: Dictionary[String, RecipeDef] = {}, params_of_sites: SiteParams = null, site_defs: Array[SiteDef] = [], post_defs: Array[PostDef] = [], caravan: CaravanParams = null, template_defs: Array[ContractTemplateDef] = [], limit_defs: Array[ContractLimitDef] = []) -> void:
	goods = good_defs
	kinds = kind_defs
	market_targets = targets
	price_params = params
	is_development_build = development_build
	trade_rules = rules
	recipes = recipe_defs
	site_params = params_of_sites
	production_sites = site_defs
	service_posts = post_defs
	caravan_params = caravan
	contract_templates = template_defs
	contract_limits = limit_defs
