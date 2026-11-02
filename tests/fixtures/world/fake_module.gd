class_name FakeModule
extends SimModule
## Módulo falso só para testes do World: registra cada chamada num call_log compartilhado.

var module_name: String
var call_log: Array[String]
var problems: Array[String] = []
var value: int = 0
var fails_on_load: bool = false


func _init(name_in_log: String, shared_log: Array[String]) -> void:
	module_name = name_in_log
	call_log = shared_log


func setup(_ctx: SimContext) -> void:
	call_log.append("%s.setup" % module_name)


func post_setup() -> void:
	call_log.append("%s.post_setup" % module_name)


func on_new_game(world_seed: int) -> void:
	call_log.append("%s.on_new_game(%d)" % [module_name, world_seed])


func on_load(data: Dictionary) -> Result:
	call_log.append("%s.on_load" % module_name)
	if fails_on_load:
		return Result.failure("FAKE_LOAD_FAILED", "falha simulada")
	value = int(data["value"])
	return Result.success()


func tick(elapsed_minutes: int) -> void:
	call_log.append("%s.tick(%d)" % [module_name, elapsed_minutes])
	value += elapsed_minutes


func serialize() -> Dictionary:
	return {"value": value}


func validate() -> Array[String]:
	return problems


func debug_summary() -> Dictionary:
	return {"value": value}


func teardown() -> void:
	call_log.append("%s.teardown" % module_name)
