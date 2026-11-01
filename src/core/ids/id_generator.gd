class_name IdGenerator
extends RefCounted
## Gerador de IDs de entidade: inteiros crescentes, nunca reutilizados (arquitetura 7.3).
## O contador só sobe, então um ID descartado jamais volta a ser entregue. O contador vai no save.

## Valor que significa "sem ID"; nunca é entregue como ID real.
const NO_ID: int = 0
const FIRST_ID: int = 1
## Limite abaixo de 2^53, para o ID sobreviver ao JSON sem perder exatidão (arquitetura 18).
const MAX_ID: int = 9007199254740991
const KEY_NEXT_ID: String = "next_id"

var _next_id: int = FIRST_ID


## Entrega um ID novo. Se o limite acabar, registra erro e devolve NO_ID.
func next_id() -> int:
	if _next_id >= MAX_ID:
		push_error("IdGenerator: IDs esgotados (limite %d)." % MAX_ID)
		return NO_ID
	var issued: int = _next_id
	_next_id += 1
	return issued


func serialize() -> Dictionary:
	return {KEY_NEXT_ID: _next_id}


## Restaura o contador. Só altera o estado se o dado for válido.
func on_load(data: Dictionary) -> Result:
	if not data.has(KEY_NEXT_ID):
		return Result.failure("IDS_MISSING_FIELD", "IdGenerator.on_load: campo '%s' ausente." % KEY_NEXT_ID)
	# Variant: valor cru vindo do JSON, que grava todo número como decimal.
	var raw_value: Variant = data[KEY_NEXT_ID]
	var value: int = NO_ID
	if typeof(raw_value) == TYPE_INT:
		value = raw_value
	elif typeof(raw_value) == TYPE_FLOAT and raw_value == floorf(raw_value) and absf(raw_value) <= MAX_ID:
		value = int(raw_value)
	else:
		return Result.failure("IDS_INVALID_TYPE", "IdGenerator.on_load: '%s' deve ser inteiro, veio %s (%s)." % [KEY_NEXT_ID, type_string(typeof(raw_value)), str(raw_value)])
	if value < FIRST_ID or value > MAX_ID:
		return Result.failure("IDS_OUT_OF_RANGE", "IdGenerator.on_load: '%s' = %d fora da faixa [%d, %d]." % [KEY_NEXT_ID, value, FIRST_ID, MAX_ID])
	_next_id = value
	return Result.success()


func validate() -> Array[String]:
	var problems: Array[String] = []
	if _next_id < FIRST_ID or _next_id > MAX_ID:
		problems.append("IdGenerator: contador %d fora da faixa [%d, %d]." % [_next_id, FIRST_ID, MAX_ID])
	return problems


func debug_summary() -> Dictionary:
	return {"next_id": _next_id, "issued_count": _next_id - FIRST_ID}
