class_name RouteCost
extends RefCounted
## O custo de uma rota para o comerciante (LW-098b; docs/modules/economy.md, 9.3 e 9.5), funções puras em INTEIROS (DEC-150): sem estado, relógio nem sorteio. Recebe o caminho JÁ resolvido, uma lista de `Leg` (a rota com o `length_m`, a `difficulty` e o `risk` dela): quem consulta o `world` é o
## módulo (LW-098d1), e assim o `TradeFlow` (LW-100) e o SP7 reusam a mesma conta. Os números vêm de `CaravanParams`. Tempo e risco são só desconto de DECISÃO: nenhum dinheiro se move por eles (Q3 e 9.6).

const CENTIMETERS_PER_METER: int = 100
const MINUTES_PER_HOUR: int = 60


## Um trecho do caminho: o que a conta precisa da rota (o `route_id` só o identifica no plano).
class Leg:
	extends RefCounted

	var route_id: String
	var length_m: int
	var difficulty: int
	var risk: int

	func _init(leg_route_id: String, leg_length_m: int, leg_difficulty: int, leg_risk: int) -> void:
		route_id = leg_route_id
		length_m = leg_length_m
		difficulty = leg_difficulty
		risk = leg_risk


## Os minutos do trecho: `ceil_div(length_cm × (10000 + difficulty × difficulty_slowdown_bp), speed_cm_per_min × 10000)`; com trecho de 1 m ou mais, são 1 ou mais.
static func leg_minutes(leg: Leg, params: CaravanParams) -> int:
	var length_cm: int = leg.length_m * CENTIMETERS_PER_METER
	return PriceMath.ceil_div(length_cm * (PriceMath.BASIS + leg.difficulty * params.difficulty_slowdown_bp), params.speed_cm_per_min * PriceMath.BASIS)


## A soma dos `leg_minutes` do caminho (0 se vazio).
static func path_minutes(legs: Array[Leg], params: CaravanParams) -> int:
	var minutes: int = 0
	for leg: Leg in legs:
		minutes += leg_minutes(leg, params)
	return minutes


## A soma do `risk` das rotas do caminho (`soma_risk` de 9.5).
static func path_risk_points(legs: Array[Leg]) -> int:
	var points: int = 0
	for leg: Leg in legs:
		points += leg.risk
	return points


## O custo de oportunidade da viagem: `ceil_div(minutos × time_cost_per_hour, 60) + fixed_cost`.
static func time_cost(minutes: int, params: CaravanParams) -> int:
	return PriceMath.ceil_div(minutes * params.time_cost_per_hour, MINUTES_PER_HOUR) + params.fixed_cost


## O desconto de risco sobre a receita: `ceil_div(receita × soma_risk × risk_bp_per_point, 10000)`.
static func risk_discount(revenue: int, risk_points: int, params: CaravanParams) -> int:
	return PriceMath.ceil_div(revenue * risk_points * params.risk_bp_per_point, PriceMath.BASIS)
