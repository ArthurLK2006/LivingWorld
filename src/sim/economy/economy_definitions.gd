class_name EconomyDefinitions
extends RefCounted
## Definições (conteúdo de `data/economy/`, SÓ LEITURA) que o `EconomyModule` recebe pelo construtor, já lidas e validadas (sem global nem autoload, arquitetura 4.3). Cada tarefa da economia acrescenta a sua tabela
## aqui: bens e tipos de dono (LW-089c), alvos de mercado e constantes de preço (LW-090c), a regra de comércio (LW-091b) e as receitas, as constantes e as linhas dos locais de produção (LW-092c). Vazia (o padrão) é um módulo sem bens nem mercados: tudo que cita um bem falha com `ECON_UNKNOWN_GOOD`, qualquer tipo de
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


func _init(good_defs: Array[GoodDef] = [], kind_defs: Array[OwnerKindDef] = [], targets: Array[MarketTargetDef] = [], params: PriceParams = null, development_build: bool = false, rules: TradeRules = null, recipe_defs: Dictionary[String, RecipeDef] = {}, params_of_sites: SiteParams = null, site_defs: Array[SiteDef] = []) -> void:
	goods = good_defs
	kinds = kind_defs
	market_targets = targets
	price_params = params
	is_development_build = development_build
	trade_rules = rules
	recipes = recipe_defs
	site_params = params_of_sites
	production_sites = site_defs
