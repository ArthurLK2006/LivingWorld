class_name DecodedSave
extends RefCounted
## Resultado de ler um save: `result.ok` diz se deu certo; só então os outros campos valem.
## `payload` já está migrado para a versão atual do formato.

var result: Result
var save_version: int = 0
var game_version: String = ""
var payload: Dictionary = {}
## Preenchidos pelo SaveStore: de qual arquivo veio ("final", "tmp", "bak1"...) e avisos de
## arquivos descartados no caminho (ex.: o principal estava corrompido).
var source: String = ""
var warnings: Array[String] = []


func _init(decode_result: Result) -> void:
	result = decode_result


static func failed(code: String, message: String) -> DecodedSave:
	return DecodedSave.new(Result.failure(code, message))
