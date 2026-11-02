extends Node


func status_text() -> String:
	if SimulationHost.runner == null:
		return "Inicializando"
	var minutes: int = SimulationHost.runner.context.clock.total_minutes()
	var state: String = "Pausado" if SimulationHost.paused else "Em andamento"
	return "Dia %d · %02d:%02d · %s" % [minutes / 1440 + 1, (minutes / 60) % 24, minutes % 60, state]
