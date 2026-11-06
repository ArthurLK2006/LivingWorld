class_name CharacterState
extends RefCounted
## Estado lógico mínimo de um personagem (LW-035): posição em metros e orientação em radianos.
## Só dados; quem guarda e valida é o CharacterModule. O corpo físico pertence à apresentação.

var position: Vector3
## Radianos, número finito, guardado como veio (sem normalizar).
var yaw: float


func _init(start_position: Vector3, start_yaw: float) -> void:
	position = start_position
	yaw = start_yaw
