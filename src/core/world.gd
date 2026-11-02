class_name SimWorld
extends RefCounted

var _modules: Dictionary = {}
var _context: SimContext


func _init(context: SimContext) -> void:
	_context = context


func register_module(module_name: String, module: SimModule) -> bool:
	if module_name.is_empty() or _modules.has(module_name) or module == null:
		return false
	_modules[module_name] = module
	return true


func setup() -> void:
	for module: SimModule in _modules.values():
		module.setup(_context)
	for module: SimModule in _modules.values():
		module.post_setup()


func on_new_game(world_seed: int) -> void:
	for module: SimModule in _modules.values():
		module.on_new_game(world_seed)


func on_load(data: Dictionary) -> void:
	for module_name: String in _modules:
		var module: SimModule = _modules[module_name]
		module.on_load(data.get(module_name, {}))


func tick(dt_sim: float) -> void:
	for module: SimModule in _modules.values():
		module.tick(dt_sim)


func serialize() -> Dictionary:
	var result: Dictionary = {}
	for module_name: String in _modules:
		var module: SimModule = _modules[module_name]
		result[module_name] = module.serialize()
	return result


func state_hash() -> String:
	var state: Dictionary = {
		"core": {
			"clock": _context.clock.serialize(),
			"ids": _context.ids.serialize(),
			"rng": _context.rng.serialize(),
			"events": _context.events.serialize(),
			"scheduler": _context.scheduler.serialize(),
			"runner_progress": _context.runner_progress.duplicate(),
		},
		"modules": serialize(),
	}
	return JSON.stringify(state, "", true, true).sha256_text()


func validate() -> Array[String]:
	var errors: Array[String] = []
	for module_name: String in _modules:
		var module: SimModule = _modules[module_name]
		for error: String in module.validate():
			errors.append(module_name + ": " + error)
	return errors


func debug_summary() -> Dictionary:
	var result: Dictionary = {}
	for module_name: String in _modules:
		var module: SimModule = _modules[module_name]
		result[module_name] = module.debug_summary()
	return result


func teardown() -> void:
	var modules: Array = _modules.values()
	modules.reverse()
	for module: SimModule in modules:
		module.teardown()
