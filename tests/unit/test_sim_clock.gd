extends GutTest

const SMALL_YEAR_DAYS: int = 10
const MS_PER_MINUTE: int = 1000


func _clock() -> SimClock:
	return SimClock.new(SMALL_YEAR_DAYS, MS_PER_MINUTE)


func _advance(clock: SimClock, steps: int) -> void:
	for _i: int in steps:
		clock.advance_step()


func test_new_clock_starts_at_year_1_day_1_midnight() -> void:
	var clock: SimClock = _clock()
	assert_eq(clock.total_minutes(), 0)
	assert_eq([clock.year(), clock.day_of_year(), clock.hour_of_day(), clock.minute_of_hour()], [1, 1, 0, 0])


func test_n_steps_advance_exactly_n_minutes() -> void:
	var clock: SimClock = _clock()
	_advance(clock, 137)
	assert_eq(clock.total_minutes(), 137 * SimClock.MINUTES_PER_STEP)
	assert_eq(clock.total_minutes(), 137, "O passo base é de 1 minuto.")


func test_calendar_rolls_over_hour_day_and_year() -> void:
	var clock: SimClock = _clock()
	_advance(clock, 59)
	assert_eq([clock.hour_of_day(), clock.minute_of_hour()], [0, 59])
	clock.advance_step()
	assert_eq([clock.hour_of_day(), clock.minute_of_hour()], [1, 0])
	_advance(clock, SimClock.MINUTES_PER_DAY - 60)
	assert_eq([clock.day_of_year(), clock.hour_of_day(), clock.minute_of_hour()], [2, 0, 0])
	_advance(clock, SimClock.MINUTES_PER_DAY * (SMALL_YEAR_DAYS - 1) - 1)
	assert_eq([clock.year(), clock.day_of_year(), clock.hour_of_day(), clock.minute_of_hour()], [1, 10, 23, 59])
	clock.advance_step()
	assert_eq([clock.year(), clock.day_of_year(), clock.hour_of_day(), clock.minute_of_hour()], [2, 1, 0, 0])


func test_paused_clock_produces_no_steps() -> void:
	var clock: SimClock = _clock()
	clock.set_paused(true)
	assert_true(clock.is_paused())
	assert_eq(clock.steps_for_frame(5000), 0)
	clock.set_paused(false)
	assert_eq(clock.steps_for_frame(MS_PER_MINUTE), 1, "Pausar não pode acumular tempo escondido.")


func test_speed_changes_steps_per_frame_but_not_step_duration() -> void:
	var clock: SimClock = _clock()
	assert_eq(clock.steps_for_frame(MS_PER_MINUTE), 1)
	assert_true(clock.set_speed(4).ok)
	assert_eq(clock.steps_for_frame(MS_PER_MINUTE), 4)
	var before: int = clock.total_minutes()
	clock.advance_step()
	assert_eq(clock.total_minutes() - before, SimClock.MINUTES_PER_STEP, "Cada passo continua valendo 1 minuto.")


func test_total_steps_do_not_depend_on_how_real_time_is_split_into_frames() -> void:
	var one_big: SimClock = _clock()
	var many_small: SimClock = _clock()
	var odd_frames: SimClock = _clock()
	one_big.set_speed(2)
	many_small.set_speed(2)
	odd_frames.set_speed(2)
	var big_total: int = one_big.steps_for_frame(10000)
	var small_total: int = 0
	for _i: int in 1000:
		small_total += many_small.steps_for_frame(10)
	var odd_total: int = 0
	for delta: int in [7, 333, 1, 9659, 0]:
		odd_total += odd_frames.steps_for_frame(delta)
	assert_eq(big_total, 20)
	assert_eq(small_total, 20)
	assert_eq(odd_total, 20)


func test_invalid_speed_is_rejected_and_keeps_previous_speed() -> void:
	var clock: SimClock = _clock()
	clock.set_speed(2)
	for bad: int in [0, -1, SimClock.MAX_SPEED + 1]:
		var result: Result = clock.set_speed(bad)
		assert_false(result.ok)
		assert_eq(result.code, "CLOCK_INVALID_SPEED")
	assert_eq(clock.get_speed(), 2)


func test_negative_frame_delta_reports_error() -> void:
	var clock: SimClock = _clock()
	assert_eq(clock.steps_for_frame(-5), 0)
	assert_push_error("delta negativo")


func test_serialized_time_restores_and_survives_json() -> void:
	var original: SimClock = _clock()
	_advance(original, 3000)
	var parsed: Variant = JSON.parse_string(JSON.stringify(original.serialize()))
	var restored: SimClock = _clock()
	var result: Result = restored.on_load(parsed)
	assert_true(result.ok, result.message)
	assert_eq(restored.total_minutes(), 3000)
	assert_eq(restored.debug_summary()["day_of_year"], original.debug_summary()["day_of_year"])
	restored.advance_step()
	original.advance_step()
	assert_eq(restored.total_minutes(), original.total_minutes())


func test_pacing_is_not_part_of_the_saved_state() -> void:
	var clock: SimClock = _clock()
	_advance(clock, 5)
	var baseline: Dictionary = clock.serialize()
	clock.set_speed(8)
	clock.set_paused(true)
	clock.steps_for_frame(123)
	assert_eq(clock.serialize(), baseline, "Pausa, velocidade e acumulador não podem mudar o save/hash.")


func test_on_load_rejects_invalid_data_without_changing_state() -> void:
	var clock: SimClock = _clock()
	_advance(clock, 10)
	var bad_inputs: Array[Dictionary] = [
		{},
		{"total_minutes": "10"},
		{"total_minutes": 1.5},
		{"total_minutes": -1},
		{"total_minutes": SimClock.MAX_TOTAL_MINUTES + 1},
	]
	for bad: Dictionary in bad_inputs:
		var result: Result = clock.on_load(bad)
		assert_false(result.ok, "Deveria rejeitar %s" % str(bad))
		assert_string_contains(result.message, "SimClock.on_load")
	assert_eq(clock.total_minutes(), 10)


func test_validate_and_debug_summary() -> void:
	var clock: SimClock = _clock()
	_advance(clock, 61)
	assert_eq(clock.validate().size(), 0)
	assert_eq(clock.debug_summary(), {"total_minutes": 61, "year": 1, "day_of_year": 1, "hour": 1, "minute": 1, "speed": 1, "is_paused": false})
