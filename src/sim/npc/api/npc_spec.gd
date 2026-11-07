class_name NpcSpec
extends RefCounted
## Pedido de criação de um NPC (`NpcModule.request_create_npc`, LW-057). Só dados. O módulo confere o pedido inteiro ANTES de gastar
## um ID. Valores de partida: T1, traços todos neutros (50), posição na origem, sem ofício, casa nem local de trabalho. Os ids de
## ofício e de locais são texto de conteúdo; a conferência de que existem é de cada tarefa que cria esse dado (LW-056 e LW-061).

## Chave de texto do nome (a apresentação monta "Aldeão 001"); não pode ser vazia.
var name_key: String = ""
var name_number: int = 0
var tier: int = NpcState.TIER_NORMAL
## Um valor de 0 a 100 por traço, na posição `order` de traits.json.
var traits: PackedInt64Array = PackedInt64Array()
var x_cm: int = 0
var z_cm: int = 0
var settlement_id: String = ""
var place_id: String = ""
var occupation_id: String = ""
var home_place_id: String = ""
var work_place_id: String = ""


func _init() -> void:
	traits = NpcState.neutral_traits()
