extends GutTest

var time_us: int = 0
var calls: Array[String] = []
var remaining: int = 0


func _now() -> int:
	return time_us


func _single() -> bool:
	calls.append("single")
	time_us += 1
	return true


func _chunk() -> bool:
	calls.append("chunk")
	remaining -= 1
	time_us += 1
	return remaining == 0


func test_frequency_and_order() -> void:
	time_us = 0
	calls.clear()
	var scheduler: SimScheduler = SimScheduler.new(_now)
	assert_true(scheduler.register_job(10, _single))
	assert_true(scheduler.register_job(10, _single))
	assert_false(scheduler.register_job(0, _single))
	for minute: int in range(1, 11):
		assert_true(scheduler.schedule_minute(minute))
		assert_true(scheduler.run_budget(10).ok)
	assert_eq(calls, ["single", "single"])


func test_work_is_resumed_without_loss() -> void:
	time_us = 0
	calls.clear()
	remaining = 3
	var scheduler: SimScheduler = SimScheduler.new(_now)
	assert_true(scheduler.register_job(1, _chunk))
	assert_true(scheduler.register_job(1, _single))
	assert_true(scheduler.schedule_minute(1))
	assert_true(scheduler.run_budget(2).ok)
	assert_true(scheduler.has_pending())
	assert_false(scheduler.schedule_minute(2))
	assert_true(scheduler.run_budget(2).ok)
	assert_false(scheduler.has_pending())
	assert_eq(calls, ["chunk", "chunk", "chunk", "single"])
	assert_eq(scheduler.run_budget(0).code, "INVALID_BUDGET")
