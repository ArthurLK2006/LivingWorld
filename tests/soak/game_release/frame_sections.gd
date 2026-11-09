class_name FrameSections
extends RefCounted
## LW-072g: o custo por SEÇÃO do quadro, para a medição em release (tests/soak/game_release). Quem mede lê o relógio de parede (Time.get_ticks_usec) em volta de cada
## seção e chama `add`; no fim de cada quadro chama `end_frame` com a duração do quadro. A seção "resto do quadro" é o que sobra (quadro menos as seções medidas, nunca
## negativo). O que se soma em `add` zera a cada `end_frame`. Código de teste: não usa relógio nenhum, só soma o que recebe.

const REST: String = "resto do quadro"
const US_PER_MS: float = 1000.0

var _names: Array[String] = []
var _open_us: Dictionary[String, int] = {}
var _series: Dictionary[String, PackedFloat64Array] = {}


## Soma `microseconds` à seção no quadro em curso (a seção passa a existir na primeira chamada, mesmo com zero).
func add(section: String, microseconds: int) -> void:
	if not _series.has(section):
		_names.append(section)
		_series[section] = PackedFloat64Array()
	_open_us[section] = _open_us.get(section, 0) + microseconds


## Fecha o quadro de `frame_ms` milissegundos: guarda o custo de cada seção e o resto, e zera o que estava aberto.
func end_frame(frame_ms: float) -> void:
	var measured_ms: float = 0.0
	for section: String in _names:
		var section_ms: float = float(_open_us.get(section, 0)) / US_PER_MS
		_series[section].append(section_ms)
		measured_ms += section_ms
	if not _series.has(REST):
		_series[REST] = PackedFloat64Array()
	_series[REST].append(maxf(frame_ms - measured_ms, 0.0))
	_open_us.clear()


## Começa de novo (os quadros guardados e o que estava aberto).
func reset() -> void:
	_open_us.clear()
	for section: String in _series:
		_series[section].clear()


func frame_count() -> int:
	return _series[REST].size() if _series.has(REST) else 0


## Média, em ms por quadro, da seção sem os `skip` primeiros quadros (0 se não sobrou quadro).
func mean_ms(section: String, skip: int) -> float:
	var kept: PackedFloat64Array = _series.get(section, PackedFloat64Array()).slice(skip)
	var sum: float = 0.0
	for value: float in kept:
		sum += value
	return sum / float(maxi(kept.size(), 1))


## Pior quadro, em ms, da seção sem os `skip` primeiros quadros (0 se não sobrou quadro).
func worst_ms(section: String, skip: int) -> float:
	var worst: float = 0.0
	for value: float in _series.get(section, PackedFloat64Array()).slice(skip):
		worst = maxf(worst, value)
	return worst


## A linha do relatório: média e pior quadro de cada seção, na ordem em que apareceram, e o resto por último.
func line(skip: int) -> String:
	var parts: PackedStringArray = PackedStringArray()
	var sections: Array[String] = _names.duplicate()
	sections.append(REST)
	for section: String in sections:
		parts.append("%s %.2f / %.2f" % [section, mean_ms(section, skip), worst_ms(section, skip)])
	return "  custo por seção, em ms por quadro (média / pior): %s" % " | ".join(parts)
