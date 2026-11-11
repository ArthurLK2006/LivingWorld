class_name EconomyDefinitions
extends RefCounted
## Definições (conteúdo de `data/economy/`, SÓ LEITURA) que o `EconomyModule` recebe pelo construtor, já lidas e validadas (sem global nem autoload, arquitetura 4.3). Cada tarefa da economia acrescenta a sua tabela
## aqui: bens e tipos de dono (LW-089c) e alvos de mercado e constantes de preço (LW-090c). Vazia (o padrão) é um módulo sem bens nem mercados: tudo que cita um bem falha com `ECON_UNKNOWN_GOOD`, qualquer tipo de
## dono é aceito e nenhum mercado nasce. `is_development_build` vem da fronteira do app (`OS.is_debug_build()`); a simulação nunca lê `OS`: liga os comandos de depuração (`request_set_stock`).

var goods: Array[GoodDef] = []
var kinds: Array[OwnerKindDef] = []
var market_targets: Array[MarketTargetDef] = []
var price_params: PriceParams
var is_development_build: bool = false


func _init(good_defs: Array[GoodDef] = [], kind_defs: Array[OwnerKindDef] = [], targets: Array[MarketTargetDef] = [], params: PriceParams = null, development_build: bool = false) -> void:
	goods = good_defs
	kinds = kind_defs
	market_targets = targets
	price_params = params
	is_development_build = development_build
