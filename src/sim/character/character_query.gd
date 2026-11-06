class_name CharacterQuery
extends RefCounted
## Resultado de `peek_character`: `result.ok` diz se deu certo; só então `position` e `yaw` valem.
## Traz uma CÓPIA dos valores (Vector3 e float são valores), nunca o objeto interno do módulo.

var result: Result
var position: Vector3
var yaw: float


func _init(query_result: Result, current_position: Vector3, current_yaw: float) -> void:
	result = query_result
	position = current_position
	yaw = current_yaw
