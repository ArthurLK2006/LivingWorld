class_name Result
extends RefCounted
## Resultado de um comando que pode falhar (arquitetura 17.6).
## GDScript não usa exceções no fluxo normal: quem chama sempre confere `ok`.

## Código usado quando uma falha é criada sem código, para que o erro nunca seja anônimo.
const UNSPECIFIED_CODE: String = "UNSPECIFIED_ERROR"

var ok: bool
var code: String
var message: String


func _init(is_ok: bool, error_code: String, error_message: String) -> void:
	ok = is_ok
	code = error_code
	message = error_message


static func success() -> Result:
	return Result.new(true, "", "")


static func failure(error_code: String, error_message: String) -> Result:
	var final_code: String = error_code if not error_code.is_empty() else UNSPECIFIED_CODE
	return Result.new(false, final_code, error_message)
