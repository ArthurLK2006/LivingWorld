extends SceneTree
## Ponto de entrada de tools/make_blockout_decorations: chama o gerador e sai com código 0 (tudo certo) ou 1 (erro
## ou, com --check, arquivo diferente). A lógica fica em BlockoutDecorationsGenerator, que os testes chamam direto.


func _initialize() -> void:
	var outcome: Result = BlockoutDecorationsGenerator.run(OS.get_cmdline_user_args())
	if outcome.ok:
		print(outcome.message)
		quit(0)
		return
	print("ERRO [%s]: %s" % [outcome.code, outcome.message])
	quit(1)
