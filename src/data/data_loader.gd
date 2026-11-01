class_name DataLoader
extends RefCounted
## Lê os arquivos JSON de conteúdo e os valida (arquitetura 16.2 e 16.3).
## Formato de cada arquivo (proposta, DEC-082): uma lista de objetos, cada um com `id`.
## Nunca carrega recursos nem executa nada vindo do arquivo; só dados simples.


## Lê todas as tabelas descritas em `schemas` a partir de `base_dir` e valida o conjunto.
static func load_all(base_dir: String, schemas: Array[DataSchema]) -> DataBundle:
	var bundle: DataBundle = DataBundle.new()
	for schema: DataSchema in schemas:
		_read_table(bundle, base_dir.path_join(schema.file_name), schema)
	DataValidator.new().validate(bundle, schemas)
	return bundle


static func _read_table(bundle: DataBundle, file_path: String, schema: DataSchema) -> void:
	if not FileAccess.file_exists(file_path):
		bundle.add_issue(file_path, "", "", "arquivo não encontrado")
		return
	var text: String = FileAccess.get_file_as_string(file_path)
	var open_error: Error = FileAccess.get_open_error()
	if open_error != OK:
		bundle.add_issue(file_path, "", "", "não foi possível ler o arquivo (erro %d)" % open_error)
		return
	var parser: JSON = JSON.new()
	if parser.parse(text) != OK:
		bundle.add_issue(file_path, "", "", "JSON inválido na linha %d: %s" % [parser.get_error_line(), parser.get_error_message()])
		return
	# Variant é inevitável aqui: é a fronteira com o JSON, tipada logo abaixo.
	var root: Variant = parser.data
	if typeof(root) != TYPE_ARRAY:
		bundle.add_issue(file_path, "", "", "a raiz do arquivo deve ser uma lista de registros")
		return
	var records: Array[Dictionary] = []
	var root_list: Array = root
	for index: int in root_list.size():
		var entry: Variant = root_list[index]
		if typeof(entry) != TYPE_DICTIONARY:
			bundle.add_issue(file_path, "#%d" % index, "", "cada registro deve ser um objeto")
			continue
		var record: Dictionary = entry
		records.append(record)
	bundle.tables[schema.table_id] = records
	bundle.file_paths[schema.table_id] = file_path
