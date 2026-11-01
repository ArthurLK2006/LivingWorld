class_name World
extends RefCounted
## Contêiner da simulação (arquitetura 4.5 e 5.1): registra os módulos e chama o ciclo de vida
## de todos eles em ORDEM DECLARADA (a ordem de registro; mudar a ordem muda o mundo).
## Também é o dono do estado do núcleo (relógio, aleatoriedade, IDs, eventos) no save.
## `tick` aqui roda todos os módulos; a frequência por módulo vem com o agendador (LW-019).

enum Phase { REGISTERING, SET_UP, TORN_DOWN }

const KEY_CORE: String = "core"
const KEY_MODULES: String = "modules"
const KEY_CLOCK: String = "clock"
const KEY_RNG: String = "rng"
const KEY_IDS: String = "ids"
const KEY_EVENTS: String = "events"

var context: SimContext
var _phase: Phase = Phase.REGISTERING
var _module_names: Array[String] = []
var _modules: Array[SimModule] = []


func _init(sim_context: SimContext) -> void:
	context = sim_context


## Registra um módulo; a ordem das chamadas define a ordem do ciclo de vida. Só antes de `setup`.
func register_module(module_name: String, module: SimModule) -> Result:
	if _phase != Phase.REGISTERING:
		return Result.failure("WORLD_REGISTRATION_CLOSED", "World.register_module('%s'): registro só é permitido antes de setup()." % module_name)
	if module_name.is_empty() or module == null:
		return Result.failure("WORLD_INVALID_MODULE", "World.register_module: nome vazio ou módulo nulo.")
	if _module_names.has(module_name):
		return Result.failure("WORLD_DUPLICATE_MODULE", "World.register_module: módulo '%s' já registrado." % module_name)
	_module_names.append(module_name)
	_modules.append(module)
	return Result.success()


func module_names() -> Array[String]:
	return _module_names.duplicate()


func setup() -> void:
	if _phase != Phase.REGISTERING:
		push_error("World.setup: já executado ou mundo encerrado.")
		return
	_phase = Phase.SET_UP
	for module: SimModule in _modules:
		module.setup(context)


func post_setup() -> void:
	for module: SimModule in _modules:
		module.post_setup()


func on_new_game(world_seed: int) -> void:
	for module: SimModule in _modules:
		module.on_new_game(world_seed)


func tick(elapsed_minutes: int) -> void:
	for module: SimModule in _modules:
		module.tick(elapsed_minutes)


## Roda o tick de um único módulo (usado pelo agendador, que decide quem roda em cada passo).
func tick_module(module_name: String, elapsed_minutes: int) -> Result:
	var index: int = _module_names.find(module_name)
	if index < 0:
		return Result.failure("WORLD_UNKNOWN_MODULE", "World.tick_module: módulo '%s' não registrado." % module_name)
	_modules[index].tick(elapsed_minutes)
	return Result.success()


## Núcleo e módulos, cada módulo sob o nome com que foi registrado.
func serialize() -> Dictionary:
	var modules_data: Dictionary = {}
	for index: int in _modules.size():
		modules_data[_module_names[index]] = _modules[index].serialize()
	var core_data: Dictionary = {
		KEY_CLOCK: context.clock.serialize(),
		KEY_RNG: context.rng.serialize(),
		KEY_IDS: context.ids.serialize(),
		KEY_EVENTS: context.events.serialize(),
	}
	return {KEY_CORE: core_data, KEY_MODULES: modules_data}


## Impressão digital do estado do mundo: SHA-256 do JSON canônico (chaves ordenadas, decimais com
## precisão total) de `serialize()`. Nunca `hash()` do Godot: tem 32 bits e depende da ordem das chaves.
## Serve ao teste de determinismo: mesma semente e mesmos comandos devem dar o mesmo hash.
func state_hash() -> String:
	return JSON.stringify(serialize(), "", true, true).sha256_text()


## Restaura núcleo e módulos. O formato é conferido antes de qualquer alteração (todos os módulos
## registrados precisam ter dados e não pode sobrar dado de módulo desconhecido). Cada parte
## é atômica; se uma falhar no meio, este World deve ser descartado, não reaproveitado: quem
## carrega um save usa um World novo e só troca o antigo depois do sucesso (AGENTS 12.6).
func on_load(data: Dictionary) -> Result:
	var core_variant: Variant = data.get(KEY_CORE)
	var modules_variant: Variant = data.get(KEY_MODULES)
	if typeof(core_variant) != TYPE_DICTIONARY or typeof(modules_variant) != TYPE_DICTIONARY:
		return Result.failure("WORLD_INVALID_SAVE", "World.on_load: '%s' e '%s' devem ser objetos." % [KEY_CORE, KEY_MODULES])
	var core_data: Dictionary = core_variant
	var modules_data: Dictionary = modules_variant
	for module_name: String in _module_names:
		if not modules_data.has(module_name) or typeof(modules_data[module_name]) != TYPE_DICTIONARY:
			return Result.failure("WORLD_MODULE_DATA_MISSING", "World.on_load: dados do módulo '%s' ausentes ou inválidos." % module_name)
	for key: Variant in modules_data.keys():
		if not _module_names.has(str(key)):
			return Result.failure("WORLD_UNKNOWN_MODULE", "World.on_load: o save contém o módulo '%s', que não está registrado." % str(key))
	var core_result: Result = _load_core(core_data)
	if not core_result.ok:
		return core_result
	for index: int in _modules.size():
		var module_data: Dictionary = modules_data[_module_names[index]]
		var result: Result = _modules[index].on_load(module_data)
		if not result.ok:
			return Result.failure(result.code, "módulo '%s': %s" % [_module_names[index], result.message])
	return Result.success()


## Problemas do núcleo e de todos os módulos, cada um com o nome de quem o relatou.
func validate() -> Array[String]:
	var problems: Array[String] = []
	for problem: String in context.clock.validate():
		problems.append("[core] " + problem)
	for problem: String in context.rng.validate():
		problems.append("[core] " + problem)
	for problem: String in context.ids.validate():
		problems.append("[core] " + problem)
	for problem: String in context.events.validate():
		problems.append("[core] " + problem)
	for index: int in _modules.size():
		for problem: String in _modules[index].validate():
			problems.append("[%s] %s" % [_module_names[index], problem])
	return problems


func debug_summary() -> Dictionary:
	var modules_summary: Dictionary = {}
	for index: int in _modules.size():
		modules_summary[_module_names[index]] = _modules[index].debug_summary()
	return {
		"clock": context.clock.debug_summary(),
		"events": context.events.debug_summary(),
		"modules": modules_summary,
		"problems": validate(),
	}


## Encerra os módulos em ordem INVERSA à do registro e depois solta o barramento.
func teardown() -> void:
	if _phase == Phase.TORN_DOWN:
		return
	# Módulos que nunca passaram por setup() não têm o que soltar: não chamar o teardown deles.
	if _phase == Phase.SET_UP:
		for index: int in range(_modules.size() - 1, -1, -1):
			_modules[index].teardown()
	context.events.teardown()
	_phase = Phase.TORN_DOWN


func _load_core(core_data: Dictionary) -> Result:
	var parts: Array[Dictionary] = []
	for key: String in [KEY_CLOCK, KEY_RNG, KEY_IDS, KEY_EVENTS]:
		var part: Variant = core_data.get(key)
		if typeof(part) != TYPE_DICTIONARY:
			return Result.failure("WORLD_INVALID_SAVE", "World.on_load: parte '%s' do núcleo ausente ou inválida." % key)
		parts.append(part)
	var results: Array[Result] = [
		context.clock.on_load(parts[0]),
		context.rng.on_load(parts[1]),
		context.ids.on_load(parts[2]),
		context.events.on_load(parts[3]),
	]
	for index: int in results.size():
		if not results[index].ok:
			return Result.failure(results[index].code, "núcleo: %s" % results[index].message)
	return Result.success()
