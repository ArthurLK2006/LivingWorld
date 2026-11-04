class_name Sp4aMetrics
extends RefCounted
## SPIKE descartável (LW-033/SP4a). Amostra quadros reais (Performance, RenderingServer) durante
## um cenário e calcula as estatísticas pedidas pela tarefa. APIs confirmadas por teste curto
## antes de escrever este arquivo (ver relatório da LW-033, seção 4): Performance.TIME_FPS,
## RENDER_TOTAL_DRAW_CALLS_IN_FRAME, RENDER_TOTAL_PRIMITIVES_IN_FRAME, RENDER_VIDEO_MEM_USED,
## MEMORY_STATIC, OBJECT_NODE_COUNT; OS.get_processor_name/get_processor_count/get_name/
## get_version; RenderingServer.get_video_adapter_name.

## Cabeçalho de máquina para cada resultado. PRIVACIDADE (DEC-016, repositório público): nenhum
## nome de computador, usuário, caminho pessoal, endereço de rede ou número de série.
static func machine_header(renderer_name: String, resolution: Vector2i) -> Dictionary:
	return {
		"sistema": OS.get_name(),
		"versao_sistema": OS.get_version(),
		"processador": OS.get_processor_name(),
		"nucleos": OS.get_processor_count(),
		"memoria_total_mb": roundi(OS.get_memory_info().get("physical", 0) / 1048576.0),
		"placa_video": RenderingServer.get_video_adapter_name(),
		"versao_godot": Engine.get_version_info().get("string", ""),
		"renderizador": renderer_name,
		"resolucao": "%dx%d" % [resolution.x, resolution.y],
	}


var _frame_times_ms: Array[float] = []
var _draw_calls: Array[int] = []
var _primitives: Array[int] = []
var _node_count_start: int = 0
var _node_count_end: int = 0
var _static_mem_mb: float = 0.0
var _video_mem_mb: float = 0.0


func start_window() -> void:
	_frame_times_ms.clear()
	_draw_calls.clear()
	_primitives.clear()
	_node_count_start = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))


## Chamar uma vez por quadro (_process) durante o cenário.
func sample_frame() -> void:
	var fps: float = Performance.get_monitor(Performance.TIME_FPS)
	if fps > 0.0:
		_frame_times_ms.append(1000.0 / fps)
	_draw_calls.append(int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
	_primitives.append(int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)))
	_static_mem_mb = Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0
	_video_mem_mb = Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0


## Encerra a janela de amostragem e devolve as métricas pedidas pela tarefa (item 8).
func finish() -> Dictionary:
	_node_count_end = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	if _frame_times_ms.is_empty():
		return {"amostras": 0}
	var fps_values: Array[float] = []
	for ms: float in _frame_times_ms:
		fps_values.append(1000.0 / ms)
	var sorted_ms: Array[float] = _frame_times_ms.duplicate()
	sorted_ms.sort()
	var sorted_fps: Array[float] = fps_values.duplicate()
	sorted_fps.sort()
	var worst_1pct_count: int = maxi(1, int(sorted_fps.size() * 0.01))
	var fps_1pct_pior: float = _average(sorted_fps.slice(0, worst_1pct_count))
	return {
		"amostras": _frame_times_ms.size(),
		"fps_medio": _average(fps_values),
		"fps_min": sorted_fps[0],
		"fps_1pct_pior": fps_1pct_pior,
		"p95_ms": sorted_ms[int(sorted_ms.size() * 0.95)],
		"p99_ms": sorted_ms[int(sorted_ms.size() * 0.99)],
		"engasgos_33ms": _count_above(sorted_ms, 33.0),
		"engasgos_50ms": _count_above(sorted_ms, 50.0),
		"memoria_mb": _static_mem_mb,
		"video_mb": _video_mem_mb,
		"draw_calls_medio": _average_int(_draw_calls),
		"primitivas_media": _average_int(_primitives),
		"nos_inicio": _node_count_start,
		"nos_fim": _node_count_end,
	}


static func _average(values: Array[float]) -> float:
	if values.is_empty():
		return 0.0
	var total: float = 0.0
	for v: float in values:
		total += v
	return total / values.size()


static func _average_int(values: Array[int]) -> float:
	if values.is_empty():
		return 0.0
	var total: int = 0
	for v: int in values:
		total += v
	return float(total) / values.size()


static func _count_above(sorted_values: Array[float], threshold: float) -> int:
	var count: int = 0
	for v: float in sorted_values:
		if v > threshold:
			count += 1
	return count


## Média, mínimo, máximo de uma lista de repetições (item 7 da tarefa: estabilidade entre rodadas).
static func describe_repetitions(values: Array[float]) -> Dictionary:
	if values.is_empty():
		return {"media": 0.0, "minimo": 0.0, "maximo": 0.0}
	var minimum: float = values[0]
	var maximum: float = values[0]
	for v: float in values:
		minimum = minf(minimum, v)
		maximum = maxf(maximum, v)
	return {"media": _average(values), "minimo": minimum, "maximo": maximum}
