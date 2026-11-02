class_name WorldRng
extends RefCounted

var _world_seed: int
var _streams: Dictionary = {}


func _init(world_seed: int = 0) -> void:
	_world_seed = world_seed


func next_int(stream_name: String) -> int:
	return _stream(stream_name).randi()


func _stream(stream_name: String) -> RandomNumberGenerator:
	if not _streams.has(stream_name):
		var generator: RandomNumberGenerator = RandomNumberGenerator.new()
		var digest: PackedByteArray = (str(_world_seed) + ":" + stream_name).sha256_buffer()
		generator.seed = digest.decode_s64(0)
		_streams[stream_name] = generator
	return _streams[stream_name] as RandomNumberGenerator


func serialize() -> Dictionary:
	var states: Dictionary = {}
	for stream_name: String in _streams:
		var generator: RandomNumberGenerator = _streams[stream_name] as RandomNumberGenerator
		states[stream_name] = str(generator.state)
	return {"world_seed": str(_world_seed), "streams": states}


func on_load(data: Dictionary) -> bool:
	if not data.has("world_seed") or not data["world_seed"] is String or not data["world_seed"].is_valid_int() or not data.has("streams") or not data["streams"] is Dictionary:
		return false
	var states: Dictionary = data["streams"]
	for stream_name: Variant in states:
		if not stream_name is String or not states[stream_name] is String or not states[stream_name].is_valid_int():
			return false
	_world_seed = int(data["world_seed"])
	_streams.clear()
	for stream_name: String in states:
		_stream(stream_name).state = int(states[stream_name])
	return true


func validate() -> bool:
	return true


func debug_summary() -> String:
	return "Fluxos aleatórios: %d" % _streams.size()
