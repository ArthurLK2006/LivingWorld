class_name SimScheduler
extends RefCounted

var _jobs: Array[Dictionary] = []
var _pending: Array[int] = []
var _now: Callable


func _init(now: Callable = Time.get_ticks_usec) -> void:
	_now = now


func register_job(frequency: int, work: Callable, job_id: String = "") -> bool:
	if frequency < 1 or not work.is_valid():
		return false
	var stable_id: String = job_id if not job_id.is_empty() else "%s:%d" % [work.get_method(), _jobs.size()]
	for existing: Dictionary in _jobs:
		if existing["id"] == stable_id:
			return false
	_jobs.append({"id": stable_id, "frequency": frequency, "work": work})
	return true


func schedule_minute(minute: int) -> bool:
	if minute < 1 or not _pending.is_empty():
		return false
	for index: int in range(_jobs.size()):
		var job: Dictionary = _jobs[index]
		if minute % int(job["frequency"]) == 0:
			_pending.append(index)
	return true


func run_budget(budget_us: int) -> SimResult:
	if budget_us < 1:
		return SimResult.new(false, "INVALID_BUDGET", "O orçamento deve ser positivo.")
	var start: int = _now.call()
	while not _pending.is_empty():
		if int(_now.call()) - start >= budget_us:
			break
		var work: Callable = _jobs[_pending[0]]["work"]
		var completed: bool = work.call()
		if completed:
			_pending.pop_front()
	return SimResult.new(true)


func has_pending() -> bool:
	return not _pending.is_empty()


func serialize() -> Dictionary:
	var jobs: Array[Dictionary] = []
	for job: Dictionary in _jobs:
		jobs.append({"id": job["id"], "frequency": job["frequency"]})
	return {"jobs": jobs, "pending": _pending.duplicate()}


func on_load(data: Dictionary) -> bool:
	if not data.get("jobs") is Array or not data.get("pending") is Array:
		return false
	var jobs: Array = data["jobs"]
	var pending: Array = data["pending"]
	if jobs.size() != _jobs.size():
		return false
	for index: int in range(jobs.size()):
		if not jobs[index] is Dictionary or jobs[index].get("id") != _jobs[index]["id"] or jobs[index].get("frequency") != _jobs[index]["frequency"]:
			return false
	for index: Variant in pending:
		if not index is int or index < 0 or index >= _jobs.size():
			return false
	_pending.clear()
	for index: int in pending:
		_pending.append(index)
	return true
