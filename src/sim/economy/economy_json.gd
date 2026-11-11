class_name EconomyJson
extends RefCounted
## Leitura de números e de chaves de ID que vêm do JSON do save da `economy` (LW-088). O JSON devolve todo número como decimal, então inteiro vale se for inteiro ou decimal sem fração
## dentro da faixa exata (2^53 − 1). `Variant` aqui é o valor CRU do arquivo; cada função confere o tipo antes de usá-lo. Nada ao jogo: só validação de dado de arquivo (AGENTS 12.6).

const MAX_SAFE_INTEGER: int = 9007199254740991


static func is_int_like(raw_value: Variant) -> bool:
	if typeof(raw_value) == TYPE_INT:
		return true
	if typeof(raw_value) != TYPE_FLOAT:
		return false
	var number: float = raw_value
	return is_finite(number) and number == floorf(number) and absf(number) <= float(MAX_SAFE_INTEGER)


## Só vale depois de `is_int_like`.
static func to_int(raw_value: Variant) -> int:
	if typeof(raw_value) == TYPE_INT:
		return raw_value
	var number: float = raw_value
	return int(number)


## Chave de objeto JSON que é um ID: texto de inteiro em forma canônica ("12", nunca "012" ou "+12") e dentro da faixa do `IdGenerator`. `IdGenerator.NO_ID` se não for.
static func id_of_key(key: Variant) -> int:
	if typeof(key) != TYPE_STRING:
		return IdGenerator.NO_ID
	var text: String = key
	if not text.is_valid_int():
		return IdGenerator.NO_ID
	var value: int = text.to_int()
	if value < IdGenerator.FIRST_ID or value > IdGenerator.MAX_ID or str(value) != text:
		return IdGenerator.NO_ID
	return value
