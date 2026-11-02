extends Node
## Ponto de entrada do spike SP1 como CENA PRINCIPAL. O binário de release ignora `-s`, então a
## medição em release roda esta cena (sp1_main.tscn) como cena principal de uma cópia do projeto.


func _ready() -> void:
	get_tree().quit(Sp1Benchmark.new().run(OS.get_cmdline_user_args()))
