extends SceneTree
## Valida uma pasta de dados e sai com código 0 (válida) ou 1 (problemas listados).
## Uso: tools/validate_data [pasta]. Sem argumento, valida os dados de teste do spike SP3.

const DEFAULT_DIR: String = "res://tests/fixtures/data/ok"


func _initialize() -> void:
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	var data_dir: String = arguments[0] if not arguments.is_empty() else DEFAULT_DIR
	var bundle: DataBundle = DataLoader.load_all(data_dir, PipelineSchemas.build())
	if bundle.is_valid():
		print("DADOS: válidos (%d tabelas) em %s" % [bundle.tables.size(), data_dir])
		quit(0)
		return
	print("DADOS: INVÁLIDOS em %s (%d problemas)\n%s" % [data_dir, bundle.issues.size(), bundle.describe_issues()])
	quit(1)
