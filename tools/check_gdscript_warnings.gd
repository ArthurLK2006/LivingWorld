extends SceneTree
## Carrega TODOS os scripts do projeto (src, tests, tools) para o Godot compilá-los. Rodado com
## --debug (ver tools/check_gdscript_warnings), o depurador local imprime os avisos de compilação
## do GDScript, que sem ele nunca aparecem em execuções sem janela. Argumentos opcionais (após --):
## pastas a varrer, em vez das padrão.

const DEFAULT_DIRS: Array[String] = ["res://src", "res://tests", "res://tools"]


func _initialize() -> void:
	var pending: Array[String] = []
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	if arguments.is_empty():
		pending.append_array(DEFAULT_DIRS)
	else:
		for argument: String in arguments:
			pending.append(argument)
	var own_path: String = get_script().resource_path
	var count: int = 0
	while not pending.is_empty():
		var dir_path: String = pending.pop_back()
		var dir: DirAccess = DirAccess.open(dir_path)
		if dir == null:
			continue
		for sub_dir: String in dir.get_directories():
			pending.append(dir_path.path_join(sub_dir))
		for file_name: String in dir.get_files():
			var script_path: String = dir_path.path_join(file_name)
			# Recarregar o script que está rodando derruba o Godot. Ele não fica sem cobertura: o Godot o
			# compila ao iniciar e, com --debug, imprime os avisos dele (provado em tests/test_check_gdscript_warnings.sh).
			if file_name.ends_with(".gd") and script_path != own_path:
				ResourceLoader.load(script_path, "", ResourceLoader.CACHE_MODE_IGNORE)
				count += 1
	print("SCRIPTS_VERIFICADOS: %d" % count)
	quit(0)
