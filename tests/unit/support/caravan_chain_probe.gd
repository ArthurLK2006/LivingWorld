class_name CaravanChainProbe
extends RefCounted
## Ajudante dos testes e do estudo da cadeia de corpos (LW-099f, curvas naturais): estradas de teste, medidas ao longo de um passeio do líder, a leitura dos mercados
## REAIS do `world` e as passagens por um povoado de passagem (X para Y para Z). Só contas, sem nó nem janela; o dono do teste decide o que afirmar.
## Convenção do passeio: `g` é a posição do líder ao longo do caminho inteiro (trecho de chegada e depois o de saída), em metros sobre o EIXO; `shift_m` é quanto o
## `s` da estrada fica atrás de `g` (0 = o `s` é a ORIGEM do líder; `ref_front_m` do líder = o `s` é o apoio da FRENTE do líder).

const PLACES_PATH: String = "res://data/world/places.json"
const KIND_MARKET: String = "market"
const CM_PER_M: float = 100.0
## A faixa à direita (m) e a rampa suave (m) [HIP] da LW-099f; o passeio a 2,9 m/s e o quadro de 1/60 s.
const LANE_M: float = 1.2
const RAMP_M: float = 12.0
const SPEED_MPS: float = 2.9
const FRAME_S: float = 1.0 / 60.0
## Passos (m): a varredura grossa de `lane_distance`, a diferença de `lane_speed_range` e o menor passo de um passeio.
const COARSE_M: float = 0.01
const SLOPE_STEP_M: float = 0.02
const MIN_WALK_STEP_M: float = 1e-4
const REFINE_ITERATIONS: int = 60
## `line_road` começa tantos metros atrás da origem (m).
const BACK_M: float = 100.0


## O que um passeio mediu: maiores passos entre quadros, giro por quadro, articulação, erro do engate e afastamento das estradas oficiais.
class Walk:
	extends RefCounted

	var frames: int = 0
	var finite: bool = true
	var max_center_step_m: float = 0.0
	var max_tail_step_m: float = 0.0
	var max_yaw_step_rad: float = 0.0
	var max_articulation_rad: float = 0.0
	var max_articulation_step_rad: float = 0.0
	var max_hitch_error_m: float = 0.0
	var max_official_offset_m: float = 0.0


## Uma passagem por um povoado de passagem: de `from_point` (X) por `corner` (Y) até `to_point` (Z); `turn_deg` é a virada em Y, com sinal (positivo = à DIREITA).
class Passage:
	extends RefCounted

	var label: String = ""
	var from_point: Vector2 = Vector2.ZERO
	var corner: Vector2 = Vector2.ZERO
	var to_point: Vector2 = Vector2.ZERO
	var turn_deg: float = 0.0


## Uma reta de `length_m` na direção `direction`, com a faixa pedida (0 = sem faixa; rampa 0 = faixa cheia). Ela COMEÇA `BACK_M` atrás da origem: o `s` de `BACK_M` metros é a origem,
## assim as contas dos testes ficam perto de (0, 0), onde o `Vector2` de 32 bits tem resolução de poucos micrômetros (a 100 m são 7,6 micrômetros por unidade; a 800 m, 61).
static func line_road(direction: Vector2, length_m: float, lane_m: float, ramp_m: float) -> CaravanRoad:
	var unit: Vector2 = direction.normalized()
	return CaravanRoad.through(PackedVector2Array([-unit * BACK_M, unit * (length_m - BACK_M)]), 0.0).with_lane(lane_m, ramp_m)


## Uma quina de `turn_deg` graus (positivo = à DIREITA no jogo): chega em +X por `lead_m` metros até a origem e sai por `exit_m` metros.
static func corner_road(turn_deg: float, lead_m: float, exit_m: float, radius_m: float, lane_m: float, ramp_m: float) -> CaravanRoad:
	var points: PackedVector2Array = PackedVector2Array([Vector2(-lead_m, 0.0), Vector2.ZERO, Vector2.from_angle(deg_to_rad(turn_deg)) * exit_m])
	return CaravanRoad.through(points, radius_m).with_lane(lane_m, ramp_m)


## O `z` da ponta de trás do último corpo (a CAUDA), no referencial do líder.
static func tail_z(spec: CaravanChain.Spec) -> float:
	var last: CaravanChain.Body = spec.bodies[spec.bodies.size() - 1]
	var tail: float = last.ref_rear_m
	for box: Vector3 in last.boxes:
		tail = minf(tail, box.x)
	return tail


## A distância (m) de um ponto à FAIXA da estrada, procurada em `around_s` ± `reach_m`: varredura grossa de 1 cm e refino por busca ternária. Independente de `solve_behind`.
static func lane_distance(road: CaravanRoad, point: Vector2, around_s: float, reach_m: float) -> float:
	var best_s: float = around_s - reach_m
	var best_gap: float = INF
	var s: float = around_s - reach_m
	while s <= around_s + reach_m:
		var gap: float = road.sample(s).distance_squared_to(point)
		if gap < best_gap:
			best_gap = gap
			best_s = s
		s += COARSE_M
	var low: float = best_s - COARSE_M
	var high: float = best_s + COARSE_M
	for _step: int in REFINE_ITERATIONS:
		var left: float = low + (high - low) / 3.0
		var right: float = high - (high - low) / 3.0
		if road.sample(left).distance_squared_to(point) < road.sample(right).distance_squared_to(point):
			high = right
		else:
			low = left
	return road.sample(0.5 * (low + high)).distance_to(point)


## O menor e o maior `|d faixa / d s|` em [from_s, to_s]: o fator de velocidade na tela (o caminho da faixa sobre o do eixo). Sem faixa vale 1.
static func lane_speed_range(road: CaravanRoad, from_s: float, to_s: float) -> Vector2:
	var lowest: float = INF
	var highest: float = 0.0
	var s: float = from_s
	while s < to_s:
		var ratio: float = road.sample(s + SLOPE_STEP_M).distance_to(road.sample(s)) / SLOPE_STEP_M
		lowest = minf(lowest, ratio)
		highest = maxf(highest, ratio)
		s += SLOPE_STEP_M
	return Vector2(lowest, highest)


## As poses do veículo com o líder em `g`: a estrada de chegada até o fim dela e depois a de saída (`leave` nulo: só uma estrada). O `s` é `g - shift_m`.
static func poses_global(arrival: CaravanRoad, leave: CaravanRoad, spec: CaravanChain.Spec, shift_m: float, g: float, out: Array[CaravanChain.RigidPose]) -> void:
	if leave == null or g <= arrival.length_m():
		CaravanChain.poses_into(arrival, spec, g - shift_m, out)
	else:
		CaravanChain.poses_into(leave, spec, g - arrival.length_m() - shift_m, out)


## Um passeio do líder de `from_g` a `to_g`, de `step_m` em `step_m` (a última amostra cai em `to_g`). `official` (X, Y, Z) liga o afastamento das duas estradas oficiais (retas X-Y e Y-Z).
static func walk(arrival: CaravanRoad, leave: CaravanRoad, spec: CaravanChain.Spec, shift_m: float, from_g: float, to_g: float, step_m: float, official: PackedVector2Array = PackedVector2Array()) -> Walk:
	var result: Walk = Walk.new()
	var poses: Array[CaravanChain.RigidPose] = CaravanChain.make_poses(spec)
	var count: int = poses.size()
	if count == 0 or step_m < MIN_WALK_STEP_M or to_g < from_g:
		return result
	var tail_z_m: float = tail_z(spec)
	var before_mid: PackedVector2Array = PackedVector2Array()
	var before_dir: PackedVector2Array = PackedVector2Array()
	before_mid.resize(count)
	before_dir.resize(count)
	var before_tail: Vector2 = Vector2.ZERO
	var before_art: float = 0.0
	var corners: PackedVector2Array = PackedVector2Array()
	var total: int = ceili((to_g - from_g) / step_m)
	for k: int in total + 1:
		poses_global(arrival, leave, spec, shift_m, minf(from_g + float(k) * step_m, to_g), poses)
		var tail: Vector2 = poses[count - 1].at_lead_frame(tail_z_m)
		var art: float = 0.0
		for i: int in count:
			var pose: CaravanChain.RigidPose = poses[i]
			result.finite = result.finite and pose.mid.is_finite() and pose.dir.is_finite()
			if i > 0:
				art = maxf(art, CaravanChain.articulation_rad(poses[i - 1], pose))
				var body: CaravanChain.Body = spec.bodies[i]
				if not body.is_pivot:
					var hitch_gap: float = pose.at_lead_frame(body.ref_front_m).distance_to(poses[i - 1].at_lead_frame(body.hitch_m))
					result.max_hitch_error_m = maxf(result.max_hitch_error_m, absf(hitch_gap - body.tongue_m))
			if k > 0:
				result.max_center_step_m = maxf(result.max_center_step_m, pose.mid.distance_to(before_mid[i]))
				result.max_yaw_step_rad = maxf(result.max_yaw_step_rad, absf(atan2(before_dir[i].cross(pose.dir), before_dir[i].dot(pose.dir))))
			before_mid[i] = pose.mid
			before_dir[i] = pose.dir
		result.max_articulation_rad = maxf(result.max_articulation_rad, art)
		if k > 0:
			result.max_tail_step_m = maxf(result.max_tail_step_m, tail.distance_to(before_tail))
			result.max_articulation_step_rad = maxf(result.max_articulation_step_rad, absf(art - before_art))
		before_tail = tail
		before_art = art
		if official.size() >= 3:
			CaravanChain.swept_corners(spec, poses, corners)
			for corner: Vector2 in corners:
				var near_m: float = minf(_segment_gap(corner, official[0], official[1]), _segment_gap(corner, official[1], official[2]))
				result.max_official_offset_m = maxf(result.max_official_offset_m, near_m)
	result.frames = total + 1
	return result


## A diferença das poses de todos os corpos na troca de trecho: (chegada, fim) contra (saída, começo), com o `s` deslocado de `shift_m`. x = maior distância (m); y = maior giro (rad).
static func junction_gap(arrival: CaravanRoad, leave: CaravanRoad, spec: CaravanChain.Spec, shift_m: float) -> Vector2:
	var before: Array[CaravanChain.RigidPose] = CaravanChain.make_poses(spec)
	var after: Array[CaravanChain.RigidPose] = CaravanChain.make_poses(spec)
	CaravanChain.poses_into(arrival, spec, arrival.length_m() - shift_m, before)
	CaravanChain.poses_into(leave, spec, -shift_m, after)
	var gap: Vector2 = Vector2.ZERO
	for i: int in before.size():
		gap.x = maxf(gap.x, before[i].mid.distance_to(after[i].mid))
		gap.y = maxf(gap.y, CaravanChain.articulation_rad(before[i], after[i]))
	return gap


## Os mercados REAIS de `data/world/places.json` (tipo `market`), em metros, na ordem do id (a, b, c).
static func markets() -> PackedVector2Array:
	var found: Array[Dictionary] = []
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PLACES_PATH))
	if parsed is Array:
		for row: Variant in parsed:
			if row is Dictionary and String((row as Dictionary).get("kind", "")) == KIND_MARKET:
				found.append(row as Dictionary)
	found.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a["id"]) < String(b["id"]))
	var points: PackedVector2Array = PackedVector2Array()
	for place: Dictionary in found:
		points.append(Vector2(float(place["x_cm"]), float(place["z_cm"])) / CM_PER_M)
	return points


## As passagens de cada canto nos dois sentidos: com 3 mercados, 6 (X para Y para Z). O nome dos mercados é A, B, C na ordem do id.
static func passages(points: PackedVector2Array) -> Array[Passage]:
	var result: Array[Passage] = []
	for corner: int in points.size():
		var others: Array[int] = []
		for other: int in points.size():
			if other != corner:
				others.append(other)
		for order: int in 2:
			var from_index: int = others[order]
			var to_index: int = others[1 - order]
			var passage: Passage = Passage.new()
			passage.label = "%s>%s>%s" % [String.chr(65 + from_index), String.chr(65 + corner), String.chr(65 + to_index)]
			passage.from_point = points[from_index]
			passage.corner = points[corner]
			passage.to_point = points[to_index]
			var leg_in: Vector2 = (passage.corner - passage.from_point).normalized()
			var leg_out: Vector2 = (passage.to_point - passage.corner).normalized()
			passage.turn_deg = rad_to_deg(atan2(leg_in.cross(leg_out), leg_in.dot(leg_out)))
			result.append(passage)
	return result


## O raio do EIXO que dá `path_radius_m` como PISO do raio do CAMINHO do veículo (a faixa é à direita): curva à direita (por dentro) pede `R + faixa`; à esquerda (por fora), o próprio `R`.
static func axis_radius(passage: Passage, path_radius_m: float) -> float:
	return path_radius_m + LANE_M if passage.turn_deg > 0.0 else path_radius_m


## Os dois trechos de uma passagem, ambos com a faixa e a rampa suave: a chegada reta (X, Y) e a saída com arco, que começa na direção de chegada em Y.
static func legs(passage: Passage, path_radius_m: float) -> Array[CaravanRoad]:
	var arrival: CaravanRoad = CaravanRoad.through(PackedVector2Array([passage.from_point, passage.corner]), 0.0).with_lane(LANE_M, RAMP_M)
	var leave: CaravanRoad = CaravanRoad.entering(arrival.end_tangent(), passage.corner, passage.to_point, axis_radius(passage, path_radius_m)).with_lane(LANE_M, RAMP_M)
	var roads: Array[CaravanRoad] = [arrival, leave]
	return roads


static func _segment_gap(point: Vector2, a: Vector2, b: Vector2) -> float:
	return Geometry2D.get_closest_point_to_segment(point, a, b).distance_to(point)
