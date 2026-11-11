class_name OwnerKindDef
extends RefCounted
## Tipo de dono da economia (LW-089; `data/economy/owner_kinds.json`; docs/modules/economy.md, seção 3), SÓ LEITURA depois de montado: a capacidade de peso do inventário (0 = sem inventário, como o contrato,
## que só tem conta) e o saldo inicial, que vira o `mint` `game_start` ao abrir o dono (o do `npc`, na LW-093). Valores [HIP] em dados.

var id: String
var weight_capacity: int
var initial_balance: int


func _init(kind_id: String, capacity: int, balance: int) -> void:
	id = kind_id
	weight_capacity = capacity
	initial_balance = balance
