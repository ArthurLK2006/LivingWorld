extends GutTest

var fake_time: int = 0
var chunks: int = 0


func _now() -> int:
	return fake_time


func _work() -> bool:
	chunks += 1
	fake_time += 2000
	return chunks == 3


func test_run_days_and_invalid_input() -> void:
	var runner: SimulationRunner = SimulationRunner.new(42)
	assert_true(runner.run_days(1).ok)
	assert_eq(runner.context.clock.total_minutes(), 1440)
	assert_eq(runner.world.debug_summary(), {})
	assert_eq(runner.run_days(-1).code, "INVALID_DAYS")
	assert_eq(runner.context.clock.total_minutes(), 1440)


func test_runner_resumes_work_before_next_minute() -> void:
	fake_time = 0
	chunks = 0
	var runner: SimulationRunner = SimulationRunner.new(42)
	runner.scheduler = SimScheduler.new(_now)
	assert_true(runner.scheduler.register_job(1, _work))
	var first: SimResult = runner.advance_minute()
	assert_true(first.ok)
	assert_eq(first.code, "WORK_PENDING")
	assert_eq(runner.context.clock.total_minutes(), 1)
	assert_true(runner.advance_minute().ok)
	assert_eq(chunks, 3)
	assert_eq(runner.context.clock.total_minutes(), 1)
