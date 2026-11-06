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
## Quantos elementos inválidos de uma mesma lista são detalhados um a um; o resto vira uma linha de resumo. [HIP]
const MAX_ELEMENT_ISSUES: int = 10

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
	if field.type == DataSchema.FieldType.INT_LIST:
		_check_int_list(bundle, file_path, item, record, field)
		return
	# Variant: valor cru do JSON; null sinaliza falha de conversão.
	var raw_value: Variant = record[field.name]
	var value: Variant = _convert(raw_value, field.type)
	if value == null:
		bundle.add_issue(file_path, item, field.name, "tipo inválido: esperado %s, encontrado %s (%s)" % [_type_name(field.type), type_string(typeof(raw_value)), str(raw_value)])
		return
	if field.type == DataSchema.FieldType.INT or field.type == DataSchema.FieldType.FLOAT:
		var problem: String = _range_problem(value, field)
		if not problem.is_empty():
			bundle.add_issue(file_path, item, field.name, problem)
			return
	record[field.name] = value


## Lista de inteiros: confere o tamanho e cada elemento e, estando tudo certo, guarda a lista como
## PackedInt64Array. Cada problema traz a posição do elemento (a partir de 0); só os primeiros
## MAX_ELEMENT_ISSUES são detalhados, para um arquivo todo errado não gerar milhões de linhas.
func _check_int_list(bundle: DataBundle, file_path: String, item: String, record: Dictionary, field: DataSchema.Field) -> void:
	# Variant: valor cru do JSON; o tipo é conferido na linha seguinte.
	var raw_value: Variant = record[field.name]
	if typeof(raw_value) != TYPE_ARRAY:
		bundle.add_issue(file_path, item, field.name, "tipo inválido: esperado %s, encontrado %s" % [_type_name(field.type), type_string(typeof(raw_value))])
		return
	var raw_list: Array = raw_value
	if raw_list.size() > field.max_length:
		bundle.add_issue(file_path, item, field.name, "lista com %d elementos, acima do limite de %d" % [raw_list.size(), field.max_length])
		return
	var converted: PackedInt64Array = PackedInt64Array()
	converted.resize(raw_list.size())
	var bad_count: int = 0
	for position: int in raw_list.size():
		var problem: String = _element_problem(raw_list[position], field)
		if problem.is_empty():
			converted[position] = int(raw_list[position])
			continue
		bad_count += 1
		if bad_count <= MAX_ELEMENT_ISSUES:
			bundle.add_issue(file_path, item, field.name, "elemento na posição %d: %s" % [position, problem])
	if bad_count == 0:
		record[field.name] = converted
	elif bad_count > MAX_ELEMENT_ISSUES:
		bundle.add_issue(file_path, item, field.name, "mais %d elementos inválidos não detalhados (total %d)" % [bad_count - MAX_ELEMENT_ISSUES, bad_count])


## Problema de um elemento de lista de inteiros (texto vazio se estiver certo).
func _element_problem(raw_element: Variant, field: DataSchema.Field) -> String:
	# Variant: elemento cru do JSON; null sinaliza falha de conversão.
	var element: Variant = _convert(raw_element, DataSchema.FieldType.INT)
	if element == null:
		return "tipo inválido: esperado inteiro, encontrado %s (%s)" % [type_string(typeof(raw_element)), str(raw_element)]
	return _range_problem(element, field)


## Problema de faixa de um número já convertido (texto vazio se estiver dentro dela).
## `value` é Variant porque pode ser int ou float, conforme o tipo do campo.
func _range_problem(value: Variant, field: DataSchema.Field) -> String:
	var number: float = value
	if number < field.min_value:
		return "valor %s abaixo do mínimo %s" % [str(value), str(field.min_value)]
	if number > field.max_value:
		return "valor %s acima do máximo %s" % [str(value), str(field.max_value)]
	return ""


## Devolve o valor no tipo do esquema ou null se não for possível.
func _convert(value: Variant, type: DataSchema.FieldType) -> Variant:
	var value_type: int = typeof(value)
	match type:
		DataSchema.FieldType.STRING:
			return value if value_type == TYPE_STRING else null
		DataSchema.FieldType.BOOL:
			return value if value_type == TYPE_BOOL else null
		DataSchema.FieldType.FLOAT:
			if value_type == TYPE_INT or value_type == TYPE_FLOAT:
				return float(value)
			return null
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
			var reference_value: Variant = record.get(field.name)
			if typeof(reference_value) == TYPE_STRING and not target_ids.has(reference_value):
				var item: String = str(record.get(ID_FIELD, "#%d" % index))
				bundle.add_issue(file_path, item, field.name, "referência a id inexistente '%s' na tabela '%s'" % [reference_value, field.ref_table])


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
		DataSchema.FieldType.INT_LIST:
			return "lista de inteiros"
	return "desconhecido"
