extends SceneTree


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() != 4 or args[0] != "--days" or args[2] != "--seed" or not args[1].is_valid_int() or not args[3].is_valid_int():
		printerr("Uso: --days N --seed S")
		quit(1)
		return
	var days: int = int(args[1])
	var runner: SimulationRunner = SimulationRunner.new(int(args[3]))
	var result: SimResult = runner.run_days(days)
	if not result.ok:
		printerr(result.code + ": " + result.message)
		quit(1)
		return
	var minutes: int = runner.context.clock.total_minutes()
	print("Dia %d, %02d:%02d; módulos: %s" % [minutes / 1440 + 1, (minutes / 60) % 24, minutes % 60, runner.world.debug_summary()])
	quit(0)
