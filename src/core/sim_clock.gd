class_name SimClock
extends RefCounted

const MINUTES_PER_HOUR: int = 60
const HOURS_PER_DAY: int = 24
var _minutes: int = 0
var _paused: bool = false
var _speed: int = 1


func advance_steps(available_steps: int) -> int:
	if _paused:
		return 0
	if available_steps < 0:
		return 0
	var steps: int = available_steps * _speed
	_minutes += steps
	return steps


func requested_steps() -> int:
	return 0 if _paused else _speed


func advance_single_step() -> void:
	_minutes += 1


func set_paused(paused: bool) -> void:
	_paused = paused


func set_speed(speed: int) -> bool:
	if speed not in [1, 2, 4, 8]:
		return false
	_speed = speed
	return true


func total_minutes() -> int:
	return _minutes


func calendar(days_per_year: int) -> Dictionary:
	if days_per_year < 1:
		return {}
	var days: int = _minutes / (MINUTES_PER_HOUR * HOURS_PER_DAY)
	return {"minute": _minutes % MINUTES_PER_HOUR, "hour": (_minutes / MINUTES_PER_HOUR) % HOURS_PER_DAY, "day": days % days_per_year + 1, "year": days / days_per_year + 1}


func serialize() -> Dictionary:
	return {"minutes": _minutes, "paused": _paused, "speed": _speed}


func on_load(data: Dictionary) -> bool:
	if not data.has("minutes") or not data["minutes"] is int or data["minutes"] < 0 or not data.has("paused") or not data["paused"] is bool or not data.has("speed") or not data["speed"] is int or data["speed"] not in [1, 2, 4, 8]:
		return false
	_minutes = data["minutes"]
	_paused = data["paused"]
	_speed = data["speed"]
	return true


func validate() -> bool:
	return _minutes >= 0 and _speed in [1, 2, 4, 8]


func debug_summary() -> String:
	return "Minutos: %d; pausa: %s; velocidade: %d" % [_minutes, _paused, _speed]
