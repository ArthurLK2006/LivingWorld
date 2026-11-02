extends GutTest

var fake_time: int = 0

class ResumableWork extends SimModule:
	var completed_chunks: int = 0
	var advance_time: Callable
	func _init(clock_callback: Callable) -> void:
		advance_time = clock_callback
	func work() -> bool:
		completed_chunks += 1
		advance_time.call()
		return completed_chunks >= 2
	func serialize() -> Dictionary:
		return {"completed_chunks": completed_chunks}
	func on_load(data: Dictionary) -> void:
		completed_chunks = data["completed_chunks"]


func _now() -> int:
	return fake_time


func _pending_work() -> bool:
	fake_time += 4000
	return false


func _advance_time() -> void:
	fake_time += 4000


func _run_hash(world_seed: int) -> String:
	var runner: SimulationRunner = SimulationRunner.new(world_seed)
	var result: SimResult = runner.run_days(30)
	if not result.ok:
		return ""
	return runner.world.state_hash()


func test_same_seed_and_time_give_stable_hash() -> void:
	var first: String = _run_hash(101)
	assert_eq(first.length(), 64)
	assert_eq(_run_hash(101), first)
	assert_eq(_run_hash(101), first)
	assert_ne(_run_hash(102), first)


func test_core_state_changes_hash() -> void:
	var runner: SimulationRunner = SimulationRunner.new(1)
	var initial: String = runner.world.state_hash()
	runner.context.ids.allocate()
	assert_ne(runner.world.state_hash(), initial)


func test_pending_scheduler_state_is_serializable_and_hashed() -> void:
	fake_time = 0
	var first: SimulationRunner = SimulationRunner.new(101)
	first.scheduler = SimScheduler.new(_now)
	assert_true(first.scheduler.register_job(1, _pending_work))
	var before: String = first.world.state_hash()
	assert_eq(first.advance_minute().code, "WORK_PENDING")
	var pending_hash: String = first.world.state_hash()
	assert_ne(pending_hash, before)
	var saved: Dictionary = first.scheduler.serialize()
	var second: SimulationRunner = SimulationRunner.new(101)
	second.scheduler = SimScheduler.new(_now)
	assert_true(second.scheduler.register_job(1, _pending_work))
	assert_true(second.scheduler.on_load(saved))
	assert_true(second.context.clock.on_load(first.context.clock.serialize()))
	second.context.runner_progress = first.context.runner_progress.duplicate(true)
	assert_eq(second.world.state_hash(), pending_hash)
	var invalid: Dictionary = {"jobs": [{"id": "_pending_work:0", "frequency": 1}], "pending": [2]}
	assert_false(second.scheduler.on_load(invalid))
	assert_eq(second.world.state_hash(), pending_hash)
	var different_seed: SimulationRunner = SimulationRunner.new(102)
	different_seed.scheduler = SimScheduler.new(_now)
	assert_true(different_seed.scheduler.register_job(1, _pending_work))
	assert_true(different_seed.scheduler.on_load(saved))
	assert_true(different_seed.context.clock.on_load(first.context.clock.serialize()))
	different_seed.context.runner_progress = first.context.runner_progress.duplicate(true)
	assert_ne(different_seed.world.state_hash(), pending_hash)


func test_restored_pending_work_reproduces_continuation() -> void:
	fake_time = 0
	var first: SimulationRunner = SimulationRunner.new(7)
	first.scheduler = SimScheduler.new(_now)
	var first_work: ResumableWork = ResumableWork.new(_advance_time)
	assert_true(first.world.register_module("work", first_work))
	assert_true(first.scheduler.register_job(1, first_work.work, "work"))
	assert_eq(first.advance_minute().code, "WORK_PENDING")
	var second: SimulationRunner = SimulationRunner.new(7)
	second.scheduler = SimScheduler.new(_now)
	var second_work: ResumableWork = ResumableWork.new(_advance_time)
	assert_true(second.world.register_module("work", second_work))
	assert_true(second.scheduler.register_job(1, second_work.work, "work"))
	second.world.on_load(first.world.serialize())
	assert_true(second.context.clock.on_load(first.context.clock.serialize()))
	assert_true(second.scheduler.on_load(first.scheduler.serialize()))
	second.context.runner_progress = first.context.runner_progress.duplicate(true)
	assert_eq(first.world.state_hash(), second.world.state_hash())
	assert_true(first.advance_minute().ok)
	assert_true(second.advance_minute().ok)
	assert_eq(first_work.completed_chunks, 2)
	assert_eq(second_work.completed_chunks, 2)
	assert_eq(first.world.state_hash(), second.world.state_hash())
