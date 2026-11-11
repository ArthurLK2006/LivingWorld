class_name EconomyDefinitions
extends RefCounted
## Definições (conteúdo de `data/economy/`, SÓ LEITURA) que o `EconomyModule` recebe pelo construtor, já lidas e validadas (sem global nem autoload, arquitetura 4.3). Cada tarefa da economia acrescenta
## a sua tabela aqui; na LW-089c são os bens e os tipos de dono. Vazia (o padrão) é um módulo sem bens: tudo que cita um bem falha com `ECON_UNKNOWN_GOOD`, e qualquer tipo de dono é aceito.

var goods: Array[GoodDef] = []
var kinds: Array[OwnerKindDef] = []


func _init(good_defs: Array[GoodDef] = [], kind_defs: Array[OwnerKindDef] = []) -> void:
	goods = good_defs
	kinds = kind_defs
