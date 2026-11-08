class_name Sp2SpeedPolicy
extends RefCounted
## LW-071 (SP2, DESCARTÁVEL): as duas políticas de velocidade do corpo (pergunta P-d), em funções puras para o teste conferir as contas
## à mão. Velocidades em metros por segundo REAL. O corpo respeita a velocidade do relógio: tudo é multiplicado por `clock_speed`
## (1 a 8) e pausa é velocidade zero. P1: passo natural (o NPC só termina quando o corpo chega). P2: o passo sai do relógio, distância
## restante / (minutos que faltam para o fim previsto x segundos reais por minuto na velocidade atual), entre um piso e um teto.

enum Policy { P1_NATURAL, P2_FROM_CLOCK }


## Velocidade do corpo agora. `minutes_left`: minutos de jogo até o fim previsto da ação (pode ser zero ou negativo: atrasado).
static func speed_mps(policy: Policy, distance_m: float, minutes_left: float, clock_speed: int, is_paused: bool) -> float:
	if is_paused or clock_speed <= 0:
		return 0.0
	var scale: float = float(clock_speed)
	if policy == Policy.P1_NATURAL:
		return Sp2Constants.NATURAL_SPEED_MPS * scale
	var ceiling: float = Sp2Constants.PLAYER_RUN_MPS * scale
	if minutes_left <= 0.0:
		return ceiling
	var seconds_left: float = minutes_left * Sp2Constants.REAL_SECONDS_PER_GAME_MINUTE / scale
	return clampf(distance_m / seconds_left, Sp2Constants.P2_FLOOR_MPS * scale, ceiling)


## A P2 precisou do teto e mesmo assim não chega a tempo (o corpo vai chegar depois do previsto).
static func is_ceiling_short(distance_m: float, minutes_left: float, clock_speed: int) -> bool:
	if clock_speed <= 0:
		return false
	var ceiling: float = Sp2Constants.PLAYER_RUN_MPS * float(clock_speed)
	var seconds_left: float = maxf(minutes_left, 0.0) * Sp2Constants.REAL_SECONDS_PER_GAME_MINUTE / float(clock_speed)
	return distance_m > ceiling * seconds_left


## Velocidade máxima possível do corpo nesta velocidade do relógio (para o detector de teleporte).
static func max_speed_mps(policy: Policy, clock_speed: int) -> float:
	var base: float = Sp2Constants.NATURAL_SPEED_MPS if policy == Policy.P1_NATURAL else Sp2Constants.PLAYER_RUN_MPS
	return base * float(maxi(clock_speed, 0))


static func label(policy: Policy) -> String:
	return "P1 passo natural" if policy == Policy.P1_NATURAL else "P2 passo do relógio"
