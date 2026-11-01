class_name WorldRng
extends RefCounted
## Único gerador aleatório do projeto (AGENTS 4.9; arquitetura 21.5). Tem uma semente de mundo
## e vários fluxos nomeados, um por finalidade (ex.: "economy", "combat"): sortear num fluxo
## não altera os outros. O algoritmo do Godot (PCG32) é detalhe de implementação e pode mudar
## entre versões; sequências e saves valem só para a versão fixada (DEC-012).

const KEY_WORLD_SEED: String = "world_seed"
const KEY_STREAMS: String = "streams"
const KEY_STREAM_SEED: String = "seed"
const KEY_STREAM_STATE: String = "state"
## Limites de 64 bits com sinal, em dígitos, para validar o texto antes de converter.
const INT64_MAX_DIGITS: String = "9223372036854775807"
const INT64_MIN_DIGITS: String = "9223372036854775808"

var world_seed: int
var _streams: Dictionary[String, RandomNumberGenerator] = {}


func _init(initial_world_seed: int) -> void:
	world_seed = initial_world_seed


## Semente de um fluxo: primeiros 8 bytes do SHA-256 de "semente_do_mundo:nome_do_fluxo".
## Nunca `semente + 1`, que deixaria fluxos vizinhos parecidos.
static func derive_stream_seed(for_world_seed: int, stream_name: String) -> int:
	var digest: PackedByteArray = ("%d:%s" % [for_world_seed, stream_name]).sha256_buffer()
	return digest.decode_s64(0)


## Inteiro sorteado entre `lowest` e `highest`, ambos inclusos, no fluxo `stream_name`.
func range_int(stream_name: String, lowest: int, highest: int) -> int:
	if lowest > highest:
		push_error("WorldRng.range_int: faixa invertida [%d, %d] no fluxo '%s'." % [lowest, highest, stream_name])
		return lowest
	return _stream(stream_name).randi_range(lowest, highest)


func serialize() -> Dictionary:
	var streams: Dictionary = {}
	for stream_name: String in _sorted_stream_names():
		var stream: RandomNumberGenerator = _streams[stream_name]
		# 64 bits não cabem com exatidão no número do JSON (2^53); por isso vão como texto decimal.
		streams[stream_name] = {KEY_STREAM_SEED: str(stream.seed), KEY_STREAM_STATE: str(stream.state)}
	return {KEY_WORLD_SEED: str(world_seed), KEY_STREAMS: streams}


## Restaura semente e fluxos. Só altera o estado se todo o dado for válido.
func on_load(data: Dictionary) -> Result:
	# Variant: valores crus vindos do JSON, convertidos e conferidos por _parse_int_text.
	var loaded_seed: Variant = _parse_int_text(data.get(KEY_WORLD_SEED))
	if loaded_seed == null:
		return Result.failure("RNG_INVALID_SEED", "WorldRng.on_load: '%s' deve ser inteiro em texto decimal." % KEY_WORLD_SEED)
	var raw_streams: Variant = data.get(KEY_STREAMS)
	if typeof(raw_streams) != TYPE_DICTIONARY:
		return Result.failure("RNG_INVALID_STREAMS", "WorldRng.on_load: '%s' deve ser um objeto." % KEY_STREAMS)
	var streams_data: Dictionary = raw_streams
	var restored: Dictionary[String, RandomNumberGenerator] = {}
	for stream_name: String in _sorted_keys(streams_data):
		var entry: Variant = streams_data[stream_name]
		if typeof(entry) != TYPE_DICTIONARY:
			return Result.failure("RNG_INVALID_STREAM", "WorldRng.on_load: fluxo '%s' deve ser um objeto." % stream_name)
		var entry_data: Dictionary = entry
		var stream_seed: Variant = _parse_int_text(entry_data.get(KEY_STREAM_SEED))
		var stream_state: Variant = _parse_int_text(entry_data.get(KEY_STREAM_STATE))
		if stream_seed == null or stream_state == null:
			return Result.failure("RNG_INVALID_STREAM", "WorldRng.on_load: fluxo '%s' precisa de '%s' e '%s' como inteiros em texto decimal." % [stream_name, KEY_STREAM_SEED, KEY_STREAM_STATE])
		var stream: RandomNumberGenerator = RandomNumberGenerator.new()
		stream.seed = stream_seed
		stream.state = stream_state
		restored[stream_name] = stream
	world_seed = loaded_seed
	_streams = restored
	return Result.success()


func validate() -> Array[String]:
	var problems: Array[String] = []
	for stream_name: String in _sorted_stream_names():
		var expected_seed: int = derive_stream_seed(world_seed, stream_name)
		if _streams[stream_name].seed != expected_seed:
			problems.append("WorldRng: semente do fluxo '%s' não corresponde à semente do mundo %d." % [stream_name, world_seed])
	return problems


func debug_summary() -> Dictionary:
	return {"world_seed": world_seed, "streams": _sorted_stream_names()}


func _stream(stream_name: String) -> RandomNumberGenerator:
	if _streams.has(stream_name):
		return _streams[stream_name]
	if stream_name.is_empty():
		push_error("WorldRng: fluxo sem nome; dê um nome por finalidade.")
	var stream: RandomNumberGenerator = RandomNumberGenerator.new()
	stream.seed = derive_stream_seed(world_seed, stream_name)
	_streams[stream_name] = stream
	return stream


func _sorted_stream_names() -> Array[String]:
	return _sorted_keys(_streams)


func _sorted_keys(source: Dictionary) -> Array[String]:
	var names: Array[String] = []
	for key: Variant in source.keys():
		names.append(str(key))
	names.sort()
	return names


## Aceita só texto decimal canônico de um inteiro de 64 bits; devolve o inteiro ou null.
## O tamanho é conferido antes de converter, porque `to_int()` gera erro interno ao estourar.
func _parse_int_text(raw: Variant) -> Variant:
	if typeof(raw) != TYPE_STRING:
		return null
	var text: String = raw
	var is_negative: bool = text.begins_with("-")
	var digits: String = text.trim_prefix("-")
	if digits.is_empty() or not digits.is_valid_int() or digits.begins_with("+"):
		return null
	var limit: String = INT64_MIN_DIGITS if is_negative else INT64_MAX_DIGITS
	if digits.length() > limit.length() or (digits.length() == limit.length() and digits > limit):
		return null
	var parsed: int = text.to_int()
	if str(parsed) != text:
		return null
	return parsed
