extends Node

# Hipótese inicial de calibração: um dia em aproximadamente 30 minutos reais.
const SIM_MINUTES_PER_SECOND: float = 0.8
var runner: SimulationRunner
var paused: bool = false
var _accumulator: float = 0.0


func _ready() -> void:
	runner = SimulationRunner.new(1)


func _process(delta: float) -> void:
	if paused:
		return
	_accumulator += delta * SIM_MINUTES_PER_SECOND
	while _accumulator >= 1.0:
		var result: SimResult = runner.advance_minute()
		if not result.ok:
			push_error("Simulação: " + result.code + " — " + result.message)
			set_process(false)
			return
		if result.code == "WORK_PENDING":
			return
		_accumulator -= 1.0
