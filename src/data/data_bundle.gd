class_name DataBundle
extends RefCounted
## Conteúdo lido de `data/` mais a lista de problemas encontrados.
## Só deve ser usado pelo jogo se `is_valid()` for verdadeiro; senão o boot para (arquitetura 16.3).

## table_id -> registros (Array[Dictionary]) já com números convertidos para os tipos do esquema.
var tables: Dictionary[String, Array] = {}
## table_id -> caminho do arquivo de origem, para mensagens de erro.
var file_paths: Dictionary[String, String] = {}
var issues: Array[Issue] = []


func add_issue(file: String, item: String, field: String, message: String) -> void:
	issues.append(Issue.new(file, item, field, message))


func is_valid() -> bool:
	return issues.is_empty()


func describe_issues() -> String:
	var lines: PackedStringArray = PackedStringArray()
	for issue: Issue in issues:
		lines.append(issue.describe())
	return "\n".join(lines)


func to_result() -> Result:
	if is_valid():
		return Result.success()
	return Result.failure("DATA_INVALID", describe_issues())


class Issue:
	extends RefCounted

	var file: String
	var item: String
	var field: String
	var message: String

	func _init(issue_file: String, issue_item: String, issue_field: String, issue_message: String) -> void:
		file = issue_file
		item = issue_item
		field = issue_field
		message = issue_message

	func describe() -> String:
		var parts: PackedStringArray = PackedStringArray([file])
		if not item.is_empty():
			parts.append("item '%s'" % item)
		if not field.is_empty():
			parts.append("campo '%s'" % field)
		parts.append(message)
		return " | ".join(parts)
