class_name SaveMigrations
extends RefCounted
## Cadeia de migrações do save (arquitetura 18.6): cada passo leva a versão N para N+1, alterando
## o `payload` no lugar. Toda mudança de formato acrescenta aqui um passo e um teste com a
## fixture da versão anterior (`tests/fixtures/saves/`). Até o "save congelado" (DEC-083) saves
## antigos ainda podem ser recusados; o mecanismo existe desde já.

var _steps: Dictionary[int, Callable] = {}


func _init() -> void:
	_steps[1] = _migrate_1_to_2


## Leva `payload` de `from_version` até `to_version`, passo a passo.
func migrate(payload: Dictionary, from_version: int, to_version: int) -> Result:
	for version: int in range(from_version, to_version):
		if not _steps.has(version):
			return Result.failure("SAVE_NO_MIGRATION", "Não existe migração do save da versão %d para %d." % [version, version + 1])
		var step_result: Result = _steps[version].call(payload)
		if not step_result.ok:
			return Result.failure(step_result.code, "Migração %d->%d: %s" % [version, version + 1, step_result.message])
	return Result.success()


## v1: o payload era o estado do World direto. v2: `{world, scheduler}`, porque o agendador também
## precisa ser salvo. Um save v1 não tem estado do agendador; assume-se que todos os módulos
## vencem no minuto seguinte ao salvo (retomada segura, sem perder execuções).
func _migrate_1_to_2(payload: Dictionary) -> Result:
	var core_variant: Variant = payload.get("core")
	var modules_variant: Variant = payload.get("modules")
	if typeof(core_variant) != TYPE_DICTIONARY or typeof(modules_variant) != TYPE_DICTIONARY:
		return Result.failure("SAVE_INVALID_PAYLOAD", "payload v1 sem 'core' e 'modules'.")
	var clock_variant: Variant = (core_variant as Dictionary).get("clock")
	if typeof(clock_variant) != TYPE_DICTIONARY or not (clock_variant as Dictionary).has("total_minutes"):
		return Result.failure("SAVE_INVALID_PAYLOAD", "payload v1 sem 'core.clock.total_minutes'.")
	var raw_minutes: Variant = (clock_variant as Dictionary)["total_minutes"]
	if typeof(raw_minutes) != TYPE_FLOAT and typeof(raw_minutes) != TYPE_INT:
		return Result.failure("SAVE_INVALID_PAYLOAD", "'core.clock.total_minutes' deve ser número.")
	var minutes: int = int(raw_minutes)
	var scheduler_modules: Dictionary = {}
	for module_name: Variant in (modules_variant as Dictionary).keys():
		scheduler_modules[str(module_name)] = {"last_run": minutes, "next_due": minutes + 1}
	var world_state: Dictionary = payload.duplicate(true)
	payload.clear()
	payload["world"] = world_state
	payload["scheduler"] = {"modules": scheduler_modules}
	return Result.success()
