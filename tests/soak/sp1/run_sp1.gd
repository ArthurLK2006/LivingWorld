extends SceneTree
## Ponto de entrada de linha de comando do spike SP1 (ver sp1_benchmark.gd): tests/soak/run_sp1.


func _initialize() -> void:
	quit(Sp1Benchmark.new().run(OS.get_cmdline_user_args()))
