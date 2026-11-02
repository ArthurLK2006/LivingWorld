class_name EntityIds
extends RefCounted

var _next_id: int = 1


func allocate() -> int:
	var result: int = _next_id
	_next_id += 1
	return result


func release(entity_id: int) -> bool:
	return entity_id > 0 and entity_id < _next_id


func serialize() -> Dictionary:
	return {"next_id": _next_id}


func on_load(data: Dictionary) -> bool:
	if not data.has("next_id") or not data["next_id"] is int or data["next_id"] < 1:
		return false
	_next_id = data["next_id"]
	return true


func validate() -> bool:
	return _next_id >= 1


func debug_summary() -> String:
	return "Próximo ID: %d" % _next_id
