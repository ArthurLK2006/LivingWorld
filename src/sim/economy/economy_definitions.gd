class_name EconomyDefinitions
extends RefCounted
## Definições (conteúdo de `data/economy/`, SÓ LEITURA) que o `EconomyModule` recebe pelo construtor, já lidas e validadas (sem global nem autoload, arquitetura 4.3). Cada tarefa da economia acrescenta a sua tabela
## aqui: bens e tipos de dono (LW-089c), alvos de mercado e constantes de preço (LW-090c), a regra de comércio (LW-091b) e as receitas, as constantes e as linhas dos locais de produção (LW-092c) e os parâmetros da caravana (LW-098d1). Vazia (o padrão) é um módulo sem bens nem mercados: tudo que cita um bem falha com `ECON_UNKNOWN_GOOD`, qualquer tipo de
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
## Os parâmetros do comerciante e da caravana (LW-098d1; `caravan_params.json`, lido pelo `CaravanParamsLoader`): OPCIONAIS. Sem eles não há caravana (`ECON_NO_ROUTE`, 9.2); ler o arquivo e pô-lo aqui no jogo real é a fiação do `app` (LW-098d3).
var caravan_params: CaravanParams


func _init(good_defs: Array[GoodDef] = [], kind_defs: Array[OwnerKindDef] = [], targets: Array[MarketTargetDef] = [], params: PriceParams = null, development_build: bool = false, rules: TradeRules = null, recipe_defs: Dictionary[String, RecipeDef] = {}, params_of_sites: SiteParams = null, site_defs: Array[SiteDef] = [], post_defs: Array[PostDef] = [], caravan: CaravanParams = null) -> void:
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
