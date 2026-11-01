class_name DataValidator
extends RefCounted
## Confere registros lidos contra os esquemas: id, campos obrigatórios, tipos,
## faixas, campos desconhecidos e referências entre tabelas (arquitetura 16.3).
## Converte números do JSON (sempre decimais) para os tipos do esquema.

const ID_FIELD: String = "id"
## `\z` é o fim do texto; evita o caractere de cifrão, que `check_architecture` reserva a atalhos de nós.
const ID_PATTERN: String = "^[a-z][a-z0-9_]*\\z"
## Maior inteiro que um decimal de 64 bits representa sem perder precisão.
const MAX_SAFE_INTEGER: float = 9007199254740992.0

var _id_regex: RegEx


func _init() -> void:
	_id_regex = RegEx.create_from_string(ID_PATTERN)


## Acrescenta ao `bundle` os problemas encontrados; não lança erro.
func validate(bundle: DataBundle, schemas: Array[DataSchema]) -> void:
	var ids_by_table: Dictionary[String, Dictionary] = {}
	for schema: DataSchema in schemas:
		if bundle.tables.has(schema.table_id):
			ids_by_table[schema.table_id] = _check_table(bundle, schema)
	for schema: DataSchema in schemas:
		if bundle.tables.has(schema.table_id):
			_check_references(bundle, schema, schemas, ids_by_table)


## Valida uma tabela e devolve o conjunto de ids vistos (id -> true).
func _check_table(bundle: DataBundle, schema: DataSchema) -> Dictionary:
	var file_path: String = bundle.file_paths[schema.table_id]
	var seen_ids: Dictionary = {}
	var records: Array = bundle.tables[schema.table_id]
	for index: int in records.size():
		var record: Dictionary = records[index]
		var item: String = _check_id(bundle, file_path, record, index, seen_ids)
		for key: Variant in record.keys():
			if str(key) != ID_FIELD and schema.find_field(str(key)) == null:
				bundle.add_issue(file_path, item, str(key), "campo desconhecido (erro de digitação?)")
		for field: DataSchema.Field in schema.fields:
			_check_field(bundle, file_path, item, record, field)
	return seen_ids


## Valida o `id` do registro e devolve o rótulo usado nas mensagens.
func _check_id(bundle: DataBundle, file_path: String, record: Dictionary, index: int, seen_ids: Dictionary) -> String:
	var fallback_item: String = "#%d" % index
	if not record.has(ID_FIELD):
		bundle.add_issue(file_path, fallback_item, ID_FIELD, "campo obrigatório ausente")
		return fallback_item
	# Variant: valor cru do JSON, o tipo é conferido na linha seguinte.
	var raw_id: Variant = record[ID_FIELD]
	if typeof(raw_id) != TYPE_STRING:
		bundle.add_issue(file_path, fallback_item, ID_FIELD, "tipo inválido: esperado texto, encontrado %s" % type_string(typeof(raw_id)))
		return fallback_item
	var id: String = raw_id
	if _id_regex.search(id) == null:
		bundle.add_issue(file_path, id, ID_FIELD, "id inválido: use snake_case iniciado por letra minúscula")
	if seen_ids.has(id):
		bundle.add_issue(file_path, id, ID_FIELD, "id duplicado na tabela")
	seen_ids[id] = true
	return id


func _check_field(bundle: DataBundle, file_path: String, item: String, record: Dictionary, field: DataSchema.Field) -> void:
	if not record.has(field.name):
		if field.is_required:
			bundle.add_issue(file_path, item, field.name, "campo obrigatório ausente")
		return
	# Variant: valor cru do JSON; null sinaliza falha de conversão.
	var raw_value: Variant = record[field.name]
	var value: Variant = _convert(raw_value, field.type)
	if value == null:
		bundle.add_issue(file_path, item, field.name, "tipo inválido: esperado %s, encontrado %s (%s)" % [_type_name(field.type), type_string(typeof(raw_value)), str(raw_value)])
		return
	if field.type == DataSchema.FieldType.INT or field.type == DataSchema.FieldType.FLOAT:
		var number: float = value
		if number < field.min_value:
			bundle.add_issue(file_path, item, field.name, "valor %s abaixo do mínimo %s" % [str(value), str(field.min_value)])
			return
		if number > field.max_value:
			bundle.add_issue(file_path, item, field.name, "valor %s acima do máximo %s" % [str(value), str(field.max_value)])
			return
	record[field.name] = value


## Devolve o valor no tipo do esquema ou null se não for possível.
func _convert(value: Variant, type: DataSchema.FieldType) -> Variant:
	var value_type: int = typeof(value)
	match type:
		DataSchema.FieldType.STRING:
			return value if value_type == TYPE_STRING else null
		DataSchema.FieldType.BOOL:
			return value if value_type == TYPE_BOOL else null
		DataSchema.FieldType.FLOAT:
			return float(value) if value_type == TYPE_INT or value_type == TYPE_FLOAT else null
		DataSchema.FieldType.INT:
			if value_type == TYPE_INT:
				return value
			if value_type == TYPE_FLOAT:
				var number: float = value
				if number == floorf(number) and absf(number) <= MAX_SAFE_INTEGER:
					return int(number)
	return null


func _check_references(bundle: DataBundle, schema: DataSchema, schemas: Array[DataSchema], ids_by_table: Dictionary[String, Dictionary]) -> void:
	var file_path: String = bundle.file_paths[schema.table_id]
	for field: DataSchema.Field in schema.fields:
		if field.ref_table.is_empty():
			continue
		if not _declares_table(schemas, field.ref_table):
			bundle.add_issue(file_path, "", field.name, "esquema referencia a tabela '%s', que não foi declarada" % field.ref_table)
			continue
		if not ids_by_table.has(field.ref_table):
			continue # a tabela referenciada falhou ao carregar; o erro já foi relatado
		var target_ids: Dictionary = ids_by_table[field.ref_table]
		var records: Array = bundle.tables[schema.table_id]
		for index: int in records.size():
			var record: Dictionary = records[index]
			# Variant: valor ainda cru se a conversão falhou antes.
			var reference: Variant = record.get(field.name)
			if typeof(reference) == TYPE_STRING and not target_ids.has(reference):
				var item: String = str(record.get(ID_FIELD, "#%d" % index))
				bundle.add_issue(file_path, item, field.name, "referência a id inexistente '%s' na tabela '%s'" % [reference, field.ref_table])


func _declares_table(schemas: Array[DataSchema], table_id: String) -> bool:
	for schema: DataSchema in schemas:
		if schema.table_id == table_id:
			return true
	return false


func _type_name(type: DataSchema.FieldType) -> String:
	match type:
		DataSchema.FieldType.STRING:
			return "texto"
		DataSchema.FieldType.INT:
			return "inteiro"
		DataSchema.FieldType.FLOAT:
			return "número"
		DataSchema.FieldType.BOOL:
			return "verdadeiro/falso"
	return "desconhecido"
