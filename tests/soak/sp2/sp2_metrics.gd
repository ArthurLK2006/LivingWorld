class_name Sp2Metrics
extends RefCounted
## LW-071 (SP2, DESCARTÁVEL): métricas de quadros no MESMO formato do tests/soak/game_release (LW-053A), copiadas daquele código pequeno
## (o original não muda). Os 3 primeiros quadros ficam fora; quadros acima de 16,7 ms e de 33 ms com o instante de cada um; nós e chunks
## no começo, meio e fim. Se a janela perder o foco durante a medição, a linha sai marcada INVÁLIDA (precedente do SP4a).

const SKIPPED_FRAMES: int = 3
const BUDGET_60_HZ_MS: float = 16.7
const BUDGET_30_HZ_MS: float = 33.0
const SUSPENDED_MS: float = 1000.0
const US_PER_MS: float = 1000.0
const US_PER_SECOND: float = 1000000.0

var label: String = ""
var _frames_ms: Array[float] = []
var _stamps_s: Array[float] = []
var _snapshots: PackedStringArray = PackedStringArray(["", "", ""])
var _start_us: int = 0
var _last_us: int = 0
var _seconds: float = 0.0
var _lost_focus: bool = false


func begin(trial_label: String, seconds: float, snapshot: String) -> void:
	label = trial_label
	_seconds = seconds
	_frames_ms.clear()
	_stamps_s.clear()
	_snapshots = PackedStringArray(["começo: " + snapshot, "", ""])
	_start_us = Time.get_ticks_usec()
	_last_us = _start_us
	_lost_focus = false


## Um quadro medido. Devolve true quando o ensaio terminou.
func frame(snapshot_now: Callable) -> bool:
	var now_us: int = Time.get_ticks_usec()
	_frames_ms.append(float(now_us - _last_us) / US_PER_MS)
	_stamps_s.append(elapsed_s())
	_last_us = now_us
	if not DisplayServer.window_is_focused():
		_lost_focus = true
	if _snapshots[1].is_empty() and elapsed_s() >= _seconds / 2.0:
		_snapshots[1] = "meio: " + str(snapshot_now.call())
	if elapsed_s() < _seconds:
		return false
	_snapshots[2] = "fim: " + str(snapshot_now.call())
	return true


## Ensaio sem duração fixa (rota): marca o meio e o fim à mão.
func mark_middle(snapshot: String) -> void:
	_snapshots[1] = "meio: " + snapshot


func close(snapshot: String) -> void:
	_snapshots[2] = "fim: " + snapshot


func elapsed_s() -> float:
	return float(_last_us - _start_us) / US_PER_SECOND


## As linhas do relatório do ensaio (mesmo texto do game_release, mais a marca de validade).
func report_lines(is_headless: bool) -> PackedStringArray:
	var lines: PackedStringArray = PackedStringArray(["ENSAIO %s%s" % [label, " — INVÁLIDO: a janela perdeu o foco" if _lost_focus and not is_headless else ""]])
	var counted: Array[float] = _frames_ms.slice(SKIPPED_FRAMES)
	if counted.is_empty():
		lines.append("  sem quadros medidos")
		return lines
	var sorted: Array[float] = counted.duplicate()
	sorted.sort()
	var sum: float = 0.0
	var over_60: int = 0
	var over_30: int = 0
	var slow_list: PackedStringArray = PackedStringArray()
	for index: int in counted.size():
		sum += counted[index]
		over_60 += 1 if counted[index] > BUDGET_60_HZ_MS else 0
		if counted[index] > BUDGET_30_HZ_MS:
			over_30 += 1
			slow_list.append("%.1f ms em %.1f s" % [counted[index], _stamps_s[index + SKIPPED_FRAMES]])
	var mean_ms: float = sum / float(counted.size())
	lines.append("  quadros %d, média %.2f ms, mediana %.2f ms, percentil 99 %.2f ms, pior (sem os %d primeiros) %.1f ms" % [counted.size(), mean_ms, sorted[IntMath.floor_div(sorted.size(), 2)], sorted[mini(int(float(sorted.size()) * 0.99), sorted.size() - 1)], SKIPPED_FRAMES, sorted[sorted.size() - 1]])
	lines.append("  acima de 16,7 ms: %d · acima de 33 ms: %d%s" % [over_60, over_30, "" if slow_list.is_empty() else " (" + "; ".join(slow_list) + ")"])
	lines.append("  %s | %s | %s" % [_snapshots[0], _snapshots[1], _snapshots[2]])
	var verdict: String = "dentro" if mean_ms <= 1000.0 / 60.0 and over_30 == 0 else "fora"
	lines.append("  régua da DEC-119 (média de 60 quadros/s ou mais e nenhum acima de 33 ms; só vale em release, na tomada): %s" % verdict)
	if sorted[sorted.size() - 1] > SUSPENDED_MS:
		lines.append("  ATENÇÃO: quadro de mais de 1 s; o Mac pode ter suspendido, estes números não valem.")
	return lines
