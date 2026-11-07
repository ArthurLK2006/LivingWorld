class_name Sp6Rules
extends RefCounted
## LW-152 (SP6, DESCARTÁVEL): regras puras do duelo contra o boneco de treino parado. Sem Node, sem tempo do motor, sem sorteio.
## O estado avança só por step(delta_ms), em ticks de 1 ms: assim o golpe cai no milissegundo exato do fim do preparo e o resultado
## não depende do tamanho do quadro. Tudo inteiro; a estamina fica em milésimos para a regeneração não perder fração. A apresentação
## só informa a geometria (distância e ângulo), repassa as teclas e lê estado e eventos; não decide nada.

enum Phase { IDLE, WINDUP, RECOVERY }
enum Group { FRONT, SIDE, BACK }
enum SlotState { READY, WINDUP, RECOVERY, NO_STAMINA, TOO_FAR, NO_TARGET, BUSY }
enum EventType { HIT, MISS, NO_STAMINA, TOO_FAR, NO_TARGET, DEFEATED, RESPAWNED }

var _dummy_hp: int = Sp6Constants.DUMMY_MAX_HP
var _is_dummy_alive: bool = true
var _respawn_left_ms: int = 0
var _armor: int = 0
var _has_target: bool = false
var _stamina_milli: int
var _since_spend_ms: int = Sp6Constants.STAMINA_REGEN_DELAY_MS
var _auto_elapsed_ms: int = Sp6Constants.AUTO_INTERVAL_MS
var _phase: int = Phase.IDLE
var _skill: int = Sp6Constants.NO_SKILL
var _phase_left_ms: int = 0
var _buffered: int = Sp6Constants.NO_SKILL
var _distance_cm: int = 0
var _angle_deg: float = 0.0
var _events: Array[CombatEvent] = []


## Fato que a apresentação desenha no mesmo quadro: acerto (com dano e grupo de posição), erro, falha de início, queda, ressurgimento.
class CombatEvent:
	extends RefCounted

	var type: int
	var skill: int
	var damage: int
	var group: int

	func _init(event_type: int, event_skill: int, event_damage: int, event_group: int) -> void:
		type = event_type
		skill = event_skill
		damage = event_damage
		group = event_group


## `start_stamina` em pontos (padrão: cheia); os testes usam valores menores para chegar a custos exatos.
func _init(start_stamina: int = Sp6Constants.STAMINA_MAX) -> void:
	_stamina_milli = start_stamina * Sp6Constants.MILLI_PER_POINT


## Dano final = base x posição% x (100 - redução)% / 10.000, em inteiros, com mínimo de 1 quando o golpe acerta.
static func final_damage(base: int, position_pct: int, reduction_pct: int) -> int:
	return maxi(Sp6Constants.MIN_DAMAGE, IntMath.floor_div(base * position_pct * (Sp6Constants.PERCENT - reduction_pct), Sp6Constants.DAMAGE_DIVISOR))


## Grupo de posição pelo ângulo; 60 e 120 graus exatos contam como o grupo de MENOR bônus.
static func group_of(angle_deg: float) -> int:
	if angle_deg <= Sp6Constants.FRONT_MAX_ANGLE_DEG:
		return Group.FRONT
	return Group.SIDE if angle_deg <= Sp6Constants.SIDE_MAX_ANGLE_DEG else Group.BACK


func set_geometry(distance_cm: int, angle_deg: float) -> void:
	_distance_cm = distance_cm
	_angle_deg = angle_deg


## Escolhe o boneco como alvo; só existe alvo se ele estiver de pé.
func select_target() -> bool:
	_has_target = _is_dummy_alive
	return _has_target


func clear_target() -> void:
	_has_target = false


func cycle_armor() -> void:
	_armor = posmod(_armor + 1, Sp6Constants.ARMOR_NAMES.size())


## Aperto da tecla de uma habilidade. Livre: tenta começar (a estamina sai agora). Na recuperação: só guarda se faltarem
## INPUT_BUFFER_MS ou menos (a mais nova substitui). No preparo ou antes disso: ignora.
func request_skill(slot: int) -> void:
	if slot < 0 or slot >= Sp6Constants.SKILL_COUNT:
		push_error("Sp6Rules.request_skill: habilidade %d inexistente; esperado de 0 a %d." % [slot, Sp6Constants.SKILL_COUNT - 1])
	elif _phase == Phase.IDLE:
		_try_start(slot)
	elif _phase == Phase.RECOVERY and _phase_left_ms <= Sp6Constants.INPUT_BUFFER_MS:
		_buffered = slot


func step(delta_ms: int) -> void:
	for _tick: int in delta_ms:
		_tick_clocks()
		_advance_phase()
		_try_auto_attack()


## Aplica um golpe ao boneco (NO_SKILL = ataque automático) com a armadura e a posição do momento. Boneco caído: não conta, devolve 0.
func deal_hit(skill: int) -> int:
	if not _is_dummy_alive:
		return 0
	var is_auto: bool = skill == Sp6Constants.NO_SKILL
	var ignored_pct: int = 0 if is_auto else Sp6Constants.SKILL_ARMOR_IGNORED_PCT[skill]
	var reduction_pct: int = IntMath.floor_div(Sp6Constants.ARMOR_REDUCTION_PCT[_armor] * (Sp6Constants.PERCENT - ignored_pct), Sp6Constants.PERCENT)
	var group: int = group_of(_angle_deg)
	var damage: int = final_damage(Sp6Constants.AUTO_DAMAGE if is_auto else Sp6Constants.SKILL_DAMAGE[skill], Sp6Constants.POSITION_PCT[group], reduction_pct)
	_dummy_hp = maxi(_dummy_hp - damage, 0)
	_events.append(CombatEvent.new(EventType.HIT, skill, damage, group))
	if _dummy_hp == 0:
		_is_dummy_alive = false
		_has_target = false
		_respawn_left_ms = Sp6Constants.DUMMY_RESPAWN_MS
		_events.append(CombatEvent.new(EventType.DEFEATED, skill, 0, group))
	return damage


## Entrega os eventos acumulados e esvazia a fila.
func take_events() -> Array[CombatEvent]:
	var taken: Array[CombatEvent] = _events
	_events = []
	return taken


func dummy_hp() -> int:
	return _dummy_hp


func is_dummy_alive() -> bool:
	return _is_dummy_alive


func has_target() -> bool:
	return _has_target


func armor() -> int:
	return _armor


func stamina_milli() -> int:
	return _stamina_milli


func stamina() -> int:
	return IntMath.floor_div(_stamina_milli, Sp6Constants.MILLI_PER_POINT)


func phase() -> int:
	return _phase


func active_skill() -> int:
	return _skill


func position_group() -> int:
	return group_of(_angle_deg)


## Quanto da fase atual já passou, de 0 a 100: o preparo enche, a recuperação esvazia.
func phase_progress_pct() -> int:
	if _phase == Phase.WINDUP:
		return Sp6Constants.PERCENT - IntMath.floor_div(_phase_left_ms * Sp6Constants.PERCENT, Sp6Constants.SKILL_WINDUP_MS[_skill])
	if _phase == Phase.RECOVERY:
		return IntMath.floor_div(_phase_left_ms * Sp6Constants.PERCENT, Sp6Constants.SKILL_RECOVERY_MS[_skill])
	return 0


## Estado de um espaço de habilidade; é o mesmo teste que decide se o aperto começa a habilidade.
func slot_state(slot: int) -> int:
	if _phase != Phase.IDLE:
		if slot != _skill:
			return SlotState.BUSY
		return SlotState.WINDUP if _phase == Phase.WINDUP else SlotState.RECOVERY
	if not _has_target:
		return SlotState.NO_TARGET
	if _stamina_milli < Sp6Constants.SKILL_STAMINA[slot] * Sp6Constants.MILLI_PER_POINT:
		return SlotState.NO_STAMINA
	return SlotState.TOO_FAR if _distance_cm > Sp6Constants.RANGE_CM else SlotState.READY


## Resumo do estado inteiro em texto, para o teste de determinismo comparar duas execuções.
func state_signature() -> String:
	return "hp=%d alive=%s respawn=%d armor=%d target=%s stamina=%d since=%d auto=%d phase=%d skill=%d left=%d buffered=%d" % [
		_dummy_hp, str(_is_dummy_alive), _respawn_left_ms, _armor, str(_has_target), _stamina_milli, _since_spend_ms, _auto_elapsed_ms,
		_phase, _skill, _phase_left_ms, _buffered]


func _try_start(slot: int) -> void:
	var state: int = slot_state(slot)
	if state == SlotState.READY:
		_spend(Sp6Constants.SKILL_STAMINA[slot])
		_phase = Phase.WINDUP
		_skill = slot
		_phase_left_ms = Sp6Constants.SKILL_WINDUP_MS[slot]
	elif state == SlotState.NO_TARGET:
		_events.append(CombatEvent.new(EventType.NO_TARGET, slot, 0, 0))
	elif state == SlotState.NO_STAMINA:
		_events.append(CombatEvent.new(EventType.NO_STAMINA, slot, 0, 0))
	else:
		_events.append(CombatEvent.new(EventType.TOO_FAR, slot, 0, 0))


func _spend(points: int) -> void:
	_stamina_milli -= points * Sp6Constants.MILLI_PER_POINT
	_since_spend_ms = 0


## Relógios de 1 ms: regeneração (só depois de STAMINA_REGEN_DELAY_MS sem gastar), intervalo do ataque automático (corre sempre, até
## o limite) e contagem do ressurgimento.
func _tick_clocks() -> void:
	_since_spend_ms = mini(_since_spend_ms + 1, Sp6Constants.STAMINA_REGEN_DELAY_MS + 1)
	if _since_spend_ms > Sp6Constants.STAMINA_REGEN_DELAY_MS:
		_stamina_milli = mini(_stamina_milli + Sp6Constants.STAMINA_REGEN_MILLI_PER_MS, Sp6Constants.STAMINA_MAX * Sp6Constants.MILLI_PER_POINT)
	_auto_elapsed_ms = mini(_auto_elapsed_ms + 1, Sp6Constants.AUTO_INTERVAL_MS)
	if not _is_dummy_alive:
		_respawn_left_ms -= 1
		if _respawn_left_ms <= 0:
			_dummy_hp = Sp6Constants.DUMMY_MAX_HP
			_is_dummy_alive = true
			_events.append(CombatEvent.new(EventType.RESPAWNED, Sp6Constants.NO_SKILL, 0, 0))


## Fim do preparo = o golpe cai (só acerta se o boneco existe e está no alcance + tolerância); fim da recuperação = livre, e a
## habilidade guardada, se houver, começa neste mesmo tick.
func _advance_phase() -> void:
	if _phase == Phase.IDLE:
		return
	_phase_left_ms -= 1
	if _phase_left_ms > 0:
		return
	if _phase == Phase.WINDUP:
		if _is_dummy_alive and _distance_cm <= Sp6Constants.RANGE_CM + Sp6Constants.IMPACT_RANGE_GRACE_CM:
			deal_hit(_skill)
		else:
			_events.append(CombatEvent.new(EventType.MISS, _skill, 0, 0))
		_phase = Phase.RECOVERY
		_phase_left_ms = Sp6Constants.SKILL_RECOVERY_MS[_skill]
		return
	var next_skill: int = _buffered
	_buffered = Sp6Constants.NO_SKILL
	_skill = Sp6Constants.NO_SKILL
	_phase = Phase.IDLE
	if next_skill != Sp6Constants.NO_SKILL:
		_try_start(next_skill)


## Ataque automático: só com alvo, no alcance, fora de preparo e recuperação, com o intervalo cumprido e estamina.
func _try_auto_attack() -> void:
	if _phase != Phase.IDLE or not _has_target or _auto_elapsed_ms < Sp6Constants.AUTO_INTERVAL_MS or _distance_cm > Sp6Constants.RANGE_CM:
		return
	if _stamina_milli < Sp6Constants.AUTO_STAMINA * Sp6Constants.MILLI_PER_POINT:
		return
	_spend(Sp6Constants.AUTO_STAMINA)
	_auto_elapsed_ms = 0
	deal_hit(Sp6Constants.NO_SKILL)
