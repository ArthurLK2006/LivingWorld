class_name SpawnResult
extends RefCounted
## Resultado de `request_spawn`: `result.ok` diz se deu certo; só então `actor_id` vale
## (mesmo padrão de DecodedSave e de HeightQuery).

var result: Result
var actor_id: int


func _init(spawn_result: Result, new_actor_id: int) -> void:
	result = spawn_result
	actor_id = new_actor_id
