class_name BridgeIntent
extends RefCounted
## Base de toda intenção que a apresentação enfileira na ponte (arquitetura 6.3: comandos tipados).
## Nenhuma intenção concreta existe ainda: cada tarefa futura cria a sua subclasse. Sempre leva o
## identificador do ator que age (nunca "o jogador" no singular).

var actor_id: int


func _init(for_actor_id: int) -> void:
	actor_id = for_actor_id
