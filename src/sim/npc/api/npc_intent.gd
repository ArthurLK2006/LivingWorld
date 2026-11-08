class_name NpcIntent
extends RefCounted
## Intenção que a simulação emite para um NPC em S0 (LW-070; contrato em docs/modules/npc.md, seção 6): "vá a este local" ou "faça a
## ação neste local". A apresentação a cumpre com o corpo e devolve um NpcActionResult com o MESMO `action_serial`. Só dados, em
## unidades da simulação (centímetros e minutos). O nome difere de propósito do `BridgeIntent`, que é o caminho contrário (do jogador
## para a simulação). Não diz QUAL ação é (comer, trabalhar...): o contrato só prevê "ir" e "agir no local".

enum Kind { MOVE_TO_PLACE, ACT_AT_PLACE }

var npc_id: int
## Contador de ações do NPC (NpcState.action_serial) no começo desta ação: casa o resultado com a intenção certa.
var action_serial: int
var kind: Kind
## Local da ação; vazio quando a ação vale em qualquer lugar (o destino é então a posição atual do corpo).
var place_id: String
## Destino no plano, em centímetros (x e z).
var destination_cm: Vector2i
## Duração planejada da ação, em minutos de simulação (a apresentação ajusta o ritmo do corpo a ela).
var expected_minutes: int


func _init(intent_npc_id: int, intent_action_serial: int, intent_kind: Kind, intent_place_id: String, intent_destination_cm: Vector2i, intent_expected_minutes: int) -> void:
	npc_id = intent_npc_id
	action_serial = intent_action_serial
	kind = intent_kind
	place_id = intent_place_id
	destination_cm = intent_destination_cm
	expected_minutes = intent_expected_minutes


## Cópia independente: o módulo só entrega cópias das intenções pendentes.
func copy() -> NpcIntent:
	return NpcIntent.new(npc_id, action_serial, kind, place_id, destination_cm, expected_minutes)
