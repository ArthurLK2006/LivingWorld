class_name DataSchema
extends RefCounted
## Esquema de uma tabela de conteúdo (arquitetura 16.3): quais campos existem,
## seus tipos, faixas e referências a outras tabelas. Todo registro tem ainda
## o campo implícito `id` (texto em snake_case, único na tabela).

enum FieldType { STRING, INT, FLOAT, BOOL, INT_LIST }

## Tamanho máximo de um campo INT_LIST quando o esquema não define outro: protege contra arquivo gigante. [HIP]
const DEFAULT_MAX_LIST_LENGTH: int = 4194304

var table_id: String
var file_name: String
var fields: Array[Field] = []


func _init(table: String, file: String) -> void:
	table_id = table
	file_name = file


func add_field(field_name: String, type: FieldType, is_required: bool = true) -> Field:
	var field: Field = Field.new(field_name, type, is_required)
	fields.append(field)
	return field


func find_field(field_name: String) -> Field:
	for field: Field in fields:
		if field.name == field_name:
			return field
	return null


class Field:
	extends RefCounted

	var name: String
	var type: DataSchema.FieldType
	var is_required: bool
	var min_value: float = -INF
	var max_value: float = INF
	var ref_table: String = ""
	var max_length: int = DataSchema.DEFAULT_MAX_LIST_LENGTH

	func _init(field_name: String, field_type: DataSchema.FieldType, required: bool) -> void:
		name = field_name
		type = field_type
		is_required = required

	## Faixa permitida (inclusive) para campos numéricos.
	func set_range(lowest: float, highest: float) -> Field:
		min_value = lowest
		max_value = highest
		return self

	## Tamanho máximo da lista (INT_LIST); a faixa de `set_range` vale para cada elemento.
	func set_max_length(length: int) -> Field:
		max_length = length
		return self

	## Marca o campo (STRING) como referência ao `id` de um registro de outra tabela.
	func set_ref(table: String) -> Field:
		ref_table = table
		return self
