extends SceneTree
## Roda o mundo sem janela: `tools/run_sim --days N --seed S`. Sai com 0 se tudo validar, 1 se não.

const DEFAULT_DAYS: int = 30
const DEFAULT_SEED: int = 1


func _initialize() -> void:
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	var days: int = DEFAULT_DAYS
	var world_seed: int = DEFAULT_SEED
	var index: int = 0
	while index < arguments.size():
		var flag: String = arguments[index]
		var value: String = arguments[index + 1] if index + 1 < arguments.size() else ""
		if (flag != "--days" and flag != "--seed") or not value.is_valid_int():
			_fail("argumento inválido: '%s %s'. Uso: tools/run_sim --days N --seed S" % [flag, value])
			return
		if flag == "--days":
			days = value.to_int()
		else:
			world_seed = value.to_int()
		index += 2
	if days < 0:
		_fail("--days deve ser zero ou positivo, veio %d" % days)
		return
	var runner: SimulationRunner = SimulationRunner.new(world_seed)
	runner.start_new_game()
	runner.run_days(days)
	print("Dias simulados: %d" % days)
	print(runner.describe_state())
	var is_valid: bool = runner.world.validate().is_empty()
	runner.finish()
	quit(0 if is_valid else 1)


func _fail(message: String) -> void:
	print("ERRO: " + message)
	quit(1)
