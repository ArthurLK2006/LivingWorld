class_name SimClock
extends RefCounted
## Relógio único da simulação (arquitetura 5.4 e 6.4). O passo é fixo: 1 minuto simulado.
## O calendário usa só hora, dia e ano (DEC-060: sem estações no protótipo).
##
## Duas partes separadas:
## - Tempo simulado (`_total_minutes`): é o que entra no save e no hash do mundo.
## - Ritmo (pausa, velocidade e acumulador): só decide QUANTOS passos rodar por quadro.
##   Não afeta o resultado do mundo e por isso NÃO é salvo (senão o hash dependeria do FPS).

const MINUTES_PER_HOUR: int = 60
const HOURS_PER_DAY: int = 24
const MINUTES_PER_DAY: int = 1440
## Duração de um passo; mudar a velocidade nunca altera isto, só quantos passos cabem num quadro.
const MINUTES_PER_STEP: int = 1
const MIN_SPEED: int = 1
const MAX_SPEED: int = 8
## Limite para o tempo sobreviver ao JSON sem perder exatidão (abaixo de 2^53).
const MAX_TOTAL_MINUTES: int = 9007199254740991
## [HIP] Dias por ano: o GDD não define; 360 é só um valor de trabalho e pode ser trocado no construtor.
const DEFAULT_DAYS_PER_YEAR: int = 360
## [HIP] Milissegundos reais por minuto simulado a 1x: 1 dia de jogo ≈ 30 min reais (arquitetura 6.4).
const DEFAULT_REAL_MS_PER_MINUTE: int = 1250
const KEY_TOTAL_MINUTES: String = "total_minutes"

var _total_minutes: int = 0
var _days_per_year: int
var _real_ms_per_minute: int
var _is_paused: bool = false
var _speed: int = MIN_SPEED
## Milissegundos reais já multiplicados pela velocidade e ainda não convertidos em passos.
var _pending_scaled_ms: int = 0


func _init(days_per_year: int = DEFAULT_DAYS_PER_YEAR, real_ms_per_minute: int = DEFAULT_REAL_MS_PER_MINUTE) -> void:
	assert(days_per_year >= 1 and real_ms_per_minute >= 1, "SimClock: dias por ano e ms por minuto devem ser positivos.")
	_days_per_year = days_per_year
	_real_ms_per_minute = real_ms_per_minute


## Avança exatamente um passo (1 minuto simulado). Quem chama é o SimulationHost.
func advance_step() -> void:
	_total_minutes += MINUTES_PER_STEP


## Converte o tempo real de um quadro em número de passos a rodar. Não avança o relógio.
## Pausado, não acumula nada. A conta é em inteiros: o total de passos não depende de como o
## tempo foi dividido em quadros.
func steps_for_frame(frame_delta_ms: int) -> int:
	if frame_delta_ms < 0:
		push_error("SimClock.steps_for_frame: delta negativo (%d ms)." % frame_delta_ms)
		return 0
	if _is_paused:
		return 0
	_pending_scaled_ms += frame_delta_ms * _speed
	var steps: int = _pending_scaled_ms / _real_ms_per_minute
	_pending_scaled_ms -= steps * _real_ms_per_minute
	return steps


func set_paused(paused: bool) -> void:
	_is_paused = paused


func is_paused() -> bool:
	return _is_paused


## Multiplicador inteiro de velocidade (1 a MAX_SPEED).
func set_speed(multiplier: int) -> Result:
	if multiplier < MIN_SPEED or multiplier > MAX_SPEED:
		return Result.failure("CLOCK_INVALID_SPEED", "SimClock.set_speed: %d fora da faixa [%d, %d]." % [multiplier, MIN_SPEED, MAX_SPEED])
	_speed = multiplier
	return Result.success()


func get_speed() -> int:
	return _speed


func total_minutes() -> int:
	return _total_minutes


func minute_of_hour() -> int:
	return _total_minutes % MINUTES_PER_HOUR


func hour_of_day() -> int:
	return (_total_minutes / MINUTES_PER_HOUR) % HOURS_PER_DAY


## Dia dentro do ano, começando em 1.
func day_of_year() -> int:
	return (_total_minutes / MINUTES_PER_DAY) % _days_per_year + 1


## Ano, começando em 1.
func year() -> int:
	return (_total_minutes / MINUTES_PER_DAY) / _days_per_year + 1


func serialize() -> Dictionary:
	return {KEY_TOTAL_MINUTES: _total_minutes}


## Restaura o tempo simulado. Só altera o estado se o dado for válido; o ritmo é reiniciado.
func on_load(data: Dictionary) -> Result:
	if not data.has(KEY_TOTAL_MINUTES):
		return Result.failure("CLOCK_MISSING_FIELD", "SimClock.on_load: campo '%s' ausente." % KEY_TOTAL_MINUTES)
	# Variant: valor cru do JSON, que grava todo número como decimal.
	var raw_value: Variant = data[KEY_TOTAL_MINUTES]
	var value: int = 0
	if typeof(raw_value) == TYPE_INT:
		value = raw_value
	elif typeof(raw_value) == TYPE_FLOAT and raw_value == floorf(raw_value) and absf(raw_value) <= MAX_TOTAL_MINUTES:
		value = int(raw_value)
	else:
		return Result.failure("CLOCK_INVALID_TYPE", "SimClock.on_load: '%s' deve ser inteiro, veio %s (%s)." % [KEY_TOTAL_MINUTES, type_string(typeof(raw_value)), str(raw_value)])
	if value < 0 or value > MAX_TOTAL_MINUTES:
		return Result.failure("CLOCK_OUT_OF_RANGE", "SimClock.on_load: '%s' = %d fora da faixa [0, %d]." % [KEY_TOTAL_MINUTES, value, MAX_TOTAL_MINUTES])
	_total_minutes = value
	_pending_scaled_ms = 0
	return Result.success()


func validate() -> Array[String]:
	var problems: Array[String] = []
	if _total_minutes < 0 or _total_minutes > MAX_TOTAL_MINUTES:
		problems.append("SimClock: tempo %d fora da faixa [0, %d]." % [_total_minutes, MAX_TOTAL_MINUTES])
	if _speed < MIN_SPEED or _speed > MAX_SPEED:
		problems.append("SimClock: velocidade %d fora da faixa [%d, %d]." % [_speed, MIN_SPEED, MAX_SPEED])
	if _pending_scaled_ms < 0 or _pending_scaled_ms >= _real_ms_per_minute:
		problems.append("SimClock: acumulador %d fora da faixa [0, %d)." % [_pending_scaled_ms, _real_ms_per_minute])
	return problems


func debug_summary() -> Dictionary:
	return {
		"total_minutes": _total_minutes,
		"year": year(),
		"day_of_year": day_of_year(),
		"hour": hour_of_day(),
		"minute": minute_of_hour(),
		"speed": _speed,
		"is_paused": _is_paused,
	}
