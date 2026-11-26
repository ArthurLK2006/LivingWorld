class_name CaravanChain
extends RefCounted
## LW-099f (curvas naturais, EXPERIMENTAL; só apresentação, atrás de um interruptor que nasce DESLIGADO): a CADEIA de corpos rígidos de um veículo sobre a
## estrada com arcos (`CaravanRoad`). Cada corpo (o comerciante com o carrinho, o cavalo, a carroça) é rígido e se apoia em DOIS pontos da faixa da estrada
## (como duas rodas); os corpos se ligam pelo ENGATE, que é um ponto do corpo da frente, sem esticar. O líder anda em `s` (metros sobre o EIXO da estrada, a
## posição lógica que não muda) e todo o resto sai só de `s`: funções PURAS, sem estado, nó nem relógio (a pose em `s` é a mesma em quadros de 1/60 s e de 1 s,
## na pausa e depois de carregar um save). Esta é a S2b do estudo (a cadeia exata): nenhum apoio sai da faixa, nenhum corpo se deforma e nada teletransporta.
## Convenções: plano `Vector2(x, z)` em metros; `z` dos apoios, dos engates e das caixas é medido NA MARCHA a partir da origem do líder (positivo à frente,
## negativo atrás); o giro é o do jogo, `atan2(-dir.x, -dir.y)` (a frente do corpo é -Z local); lateral positiva = DIREITA da marcha (a faixa da `CaravanRoad`
## também é à direita). Sem alocação por quadro: quem usa cria as poses UMA vez (`make_poses`) e `poses_into` as preenche. Entrada ruim (estrada nula ou vazia,
## veículo sem corpo): poses neutras e finitas, nunca NaN; `s` não finito conta como 0 (a mesma regra da `CaravanRoad`).

## Medidas [HIP] do veículo comprido de referência (cavalo e carroça de 4 rodas, 9,1 m), em metros. O cavalo apoia-se a 1,2 m para a frente e para trás da origem do líder.
const HORSE_SUPPORT_M: float = 1.2
const HORSE_HALF_LENGTH_M: float = 1.4
const HORSE_HALF_WIDTH_M: float = 0.46
## O engate fica no corpo do cavalo, a 1,976 m atrás da origem do líder; o eixo da frente da carroça fica a um timão dele e o de trás a um entre-eixos.
const HITCH_Z_M: float = -1.976
const WAGON_WHEELBASE_M: float = 2.46
const WAGON_TONGUE_M: float = 2.807
const WAGON_HALF_WIDTH_M: float = 1.005
const WAGON_REAR_OVERHANG_M: float = 0.50
const WAGON_FRONT_OVERHANG_M: float = 0.44
## A escolta atrás da carroça (caixa de 0,9 m, a 0,164 m do balanço de trás).
const ESCORT_GAP_M: float = 0.164
const ESCORT_LENGTH_M: float = 0.9
const ESCORT_HALF_WIDTH_M: float = 0.30
## O conjunto comerciante + carrinho avança 0,3 m à frente da origem do líder (a caixa de varredura do "hoje").
const CART_FRONT_M: float = 0.3
## Distância menor que isto (m) não tem solução útil na estrada: o apoio fica onde está, sem chamar a busca (nenhuma conta divide por zero).
const MIN_DISTANCE_M: float = 1e-6
## Dois apoios mais perto que isto (m, ao quadrado) não dão direção: o giro vem da tangente da estrada.
const MIN_SPAN_SQ_M2: float = 1e-12
## `max_axis_offset_m`: passo mínimo (m) e número máximo de amostras, para a medida nunca virar laço sem fim.
const MIN_STEP_M: float = 0.001
const MAX_SAMPLES: int = 200000


## Um corpo rígido do veículo. `ref_front_m` e `ref_rear_m` são os DOIS apoios sobre a faixa (o da frente primeiro). `hitch_m` é o `z` do engate, no corpo
## ANTERIOR, onde este corpo se prende (ignorado no líder); `tongue_m` é a distância do engate ao apoio da frente deste corpo (ignorada no líder e no `is_pivot`).
## `is_pivot`: corpo de 2 rodas preso no engate (a frente é o próprio engate, que não está na estrada; só o eixo de trás é achado na faixa, a `ref_front_m - ref_rear_m`
## do engate). `boxes`: caixas de varredura, cada uma `Vector3(z de trás, z da frente, meia-largura)`, no referencial do líder.
class Body:
	extends RefCounted

	var ref_front_m: float = 0.0
	var ref_rear_m: float = 0.0
	var hitch_m: float = 0.0
	var tongue_m: float = 0.0
	var is_pivot: bool = false
	var boxes: Array[Vector3] = []


## Um veículo: o rótulo (para os relatórios) e os corpos, o líder primeiro.
class Spec:
	extends RefCounted

	var label: String = ""
	var bodies: Array[Body] = []


## A pose de UM corpo: `mid` é o ponto médio dos dois apoios no mundo, `dir` a frente (unitária) e `mid_z_m` o `z` desse ponto médio no referencial do líder.
class RigidPose:
	extends RefCounted

	var mid: Vector2 = Vector2.ZERO
	var dir: Vector2 = Vector2.UP
	var mid_z_m: float = 0.0

	## O ponto do mundo que, no referencial do líder, está em `z_m` (positivo à frente) e `lateral_m` metros à DIREITA da marcha.
	func at_lead_frame(z_m: float, lateral_m: float = 0.0) -> Vector2:
		return mid + dir * (z_m - mid_z_m) + Vector2(-dir.y, dir.x) * lateral_m

	## O giro do corpo em torno de Y, na convenção do jogo (a frente é -Z local).
	func yaw() -> float:
		return atan2(-dir.x, -dir.y)

	## Onde estaria a origem do líder se ESTE corpo fosse o líder (`z` 0 do referencial do líder).
	func origin() -> Vector2:
		return at_lead_frame(0.0)


## O veículo de HOJE: o comerciante e o carrinho como UM corpo rígido, apoiado nos pés do comerciante (z 0) e no EIXO (`CART_BACK_M` atrás).
static func cart_spec() -> Spec:
	var body: Body = Body.new()
	body.ref_front_m = 0.0
	body.ref_rear_m = -CaravanView.CART_BACK_M
	var half_width_m: float = CaravanView.WHEEL_SIDE_M + CaravanView.WHEEL_THICKNESS_M * 0.5
	body.boxes.append(Vector3(-(CaravanView.CART_BACK_M + CaravanView.BED_SIZE_M.z * 0.5), CART_FRONT_M, half_width_m))
	var spec: Spec = Spec.new()
	spec.label = "carrinho de hoje (comerciante e carrinho, um corpo rígido)"
	spec.bodies.append(body)
	return spec


## O veículo comprido de referência (cavalo e carroça de 4 rodas, 9,1 m); com `escort`, a escolta atrás (10,2 m).
static func wagon_spec(escort: bool = false) -> Spec:
	return wagon_spec_with(WAGON_WHEELBASE_M, WAGON_TONGUE_M, escort)


## O mesmo veículo com outro entre-eixos e outro timão (m), para os veículos maiores da tabela do estudo. O engate e as medidas do cavalo não mudam.
static func wagon_spec_with(wheelbase_m: float, tongue_m: float, escort: bool = false) -> Spec:
	var horse: Body = Body.new()
	horse.ref_front_m = HORSE_SUPPORT_M
	horse.ref_rear_m = -HORSE_SUPPORT_M
	horse.boxes.append(Vector3(-HORSE_HALF_LENGTH_M, HORSE_HALF_LENGTH_M, HORSE_HALF_WIDTH_M))
	var wagon: Body = Body.new()
	wagon.ref_front_m = HITCH_Z_M - tongue_m
	wagon.ref_rear_m = wagon.ref_front_m - wheelbase_m
	wagon.hitch_m = HITCH_Z_M
	wagon.tongue_m = tongue_m
	var back_m: float = wagon.ref_rear_m - WAGON_REAR_OVERHANG_M
	wagon.boxes.append(Vector3(back_m, wagon.ref_front_m + WAGON_FRONT_OVERHANG_M, WAGON_HALF_WIDTH_M))
	if escort:
		wagon.boxes.append(Vector3(back_m - ESCORT_GAP_M - ESCORT_LENGTH_M, back_m - ESCORT_GAP_M, ESCORT_HALF_WIDTH_M))
	var spec: Spec = Spec.new()
	spec.label = "cavalo e carroça de 4 rodas (entre-eixos %.2f m, timão %.3f m%s)" % [wheelbase_m, tongue_m, ", com escolta" if escort else ""]
	spec.bodies.append(horse)
	spec.bodies.append(wagon)
	return spec


## As poses de um veículo, uma por corpo, já neutras (a origem do líder em (0, 0), a frente para -Z). Cria o que for preciso UMA vez; depois é só `poses_into`.
static func make_poses(spec: Spec) -> Array[RigidPose]:
	var poses: Array[RigidPose] = []
	if spec == null:
		return poses
	for body: Body in spec.bodies:
		var pose: RigidPose = RigidPose.new()
		pose.mid_z_m = (body.ref_front_m + body.ref_rear_m) * 0.5
		_set_neutral(pose)
		poses.append(pose)
	return poses


## Preenche `out` (criado por `make_poses` para o MESMO `spec`) com a pose de cada corpo quando o líder está a `s` metros da saída, sobre o EIXO. O corpo da
## frente apoia-se na faixa em `s + ref_front_m`; o apoio de trás é o ponto da faixa a um entre-eixos exato, para trás; o engate de cada corpo seguinte é o ponto
## do corpo ANTERIOR em `hitch_m`; o apoio da frente dele é o ponto da faixa a um timão exato do engate e o de trás a um entre-eixos exato (corpos rígidos, engate
## sem esticar, todos os apoios SOBRE a faixa). Só a parte comum de `out` e `spec.bodies` é preenchida. Estrada nula ou vazia: poses neutras.
static func poses_into(road: CaravanRoad, spec: Spec, s: float, out: Array[RigidPose]) -> void:
	if spec == null:
		return
	var count: int = mini(spec.bodies.size(), out.size())
	var lead_s: float = s if is_finite(s) else 0.0
	var usable: bool = road != null and road.length_m() > 0.0
	for index: int in count:
		var body: Body = spec.bodies[index]
		var pose: RigidPose = out[index]
		pose.mid_z_m = (body.ref_front_m + body.ref_rear_m) * 0.5
		if not usable:
			_set_neutral(pose)
			continue
		var front: Vector2
		var reach: float = lead_s + body.ref_front_m
		if index == 0:
			front = road.sample(reach)
		else:
			var hitch: Vector2 = out[index - 1].at_lead_frame(body.hitch_m)
			reach = lead_s + body.hitch_m
			if body.is_pivot:
				front = hitch
			else:
				reach = _behind(road, hitch, body.tongue_m, reach)
				front = road.sample(reach)
		var rear: Vector2 = road.sample(_behind(road, front, body.ref_front_m - body.ref_rear_m, reach))
		_place(pose, front, rear, road, reach)


## O ângulo (rad, de 0 a PI) entre o giro de dois corpos: a articulação do engate.
static func articulation_rad(front: RigidPose, back: RigidPose) -> float:
	return absf(atan2(front.dir.cross(back.dir), front.dir.dot(back.dir)))


## Preenche `out` com os 4 cantos (no mundo) de cada caixa de cada corpo, na ordem dos corpos e das caixas. O que sobrar de `out` é descartado.
static func swept_corners(spec: Spec, poses: Array[RigidPose], out: PackedVector2Array) -> void:
	out.clear()
	if spec == null:
		return
	for index: int in mini(spec.bodies.size(), poses.size()):
		var pose: RigidPose = poses[index]
		for box: Vector3 in spec.bodies[index].boxes:
			out.append(pose.at_lead_frame(box.x, -box.z))
			out.append(pose.at_lead_frame(box.x, box.z))
			out.append(pose.at_lead_frame(box.y, box.z))
			out.append(pose.at_lead_frame(box.y, -box.z))


## O maior afastamento (m, em valor absoluto) de qualquer canto de caixa do veículo em relação ao EIXO da estrada, com o líder andando de `from_s` a `to_s` de
## `step_m` em `step_m` (no mínimo 1 mm; no máximo 200 mil amostras; as duas pontas sempre entram). Estrada vazia ou entrada não finita: 0.
static func max_axis_offset_m(road: CaravanRoad, spec: Spec, from_s: float, to_s: float, step_m: float) -> float:
	if road == null or spec == null or road.length_m() <= 0.0 or not (is_finite(from_s) and is_finite(to_s) and is_finite(step_m)):
		return 0.0
	var step: float = maxf(step_m, MIN_STEP_M)
	var span: float = maxf(to_s - from_s, 0.0)
	var count: int = mini(ceili(span / step), MAX_SAMPLES)
	var poses: Array[RigidPose] = make_poses(spec)
	var corners: PackedVector2Array = PackedVector2Array()
	var worst: float = 0.0
	for k: int in count + 1:
		poses_into(road, spec, from_s + minf(float(k) * step, span), poses)
		swept_corners(spec, poses, corners)
		for corner: Vector2 in corners:
			worst = maxf(worst, road.axis_offset(corner).x)
	return worst


## A busca da estrada a `distance_m` de `q`, para trás de `hi`; distância sem sentido (zero, negativa, não finita) não busca nada e fica em `hi`.
static func _behind(road: CaravanRoad, q: Vector2, distance_m: float, hi: float) -> float:
	if not is_finite(distance_m) or distance_m <= MIN_DISTANCE_M:
		return hi
	return road.solve_behind(q, distance_m, hi)


## A pose de um corpo apoiado em `front` e `rear`: o ponto médio e a direção da corda. Apoios coincidentes dão o giro da estrada em `s_ref`; nada não finito sai.
static func _place(pose: RigidPose, front: Vector2, rear: Vector2, road: CaravanRoad, s_ref: float) -> void:
	var span: Vector2 = front - rear
	if span.length_squared() > MIN_SPAN_SQ_M2:
		pose.dir = span.normalized()
	else:
		var heading: Vector2 = road.tangent(s_ref)
		pose.dir = heading.normalized() if heading.length_squared() > MIN_SPAN_SQ_M2 else Vector2.UP
	pose.mid = (front + rear) * 0.5
	if not (pose.mid.is_finite() and pose.dir.is_finite()):
		_set_neutral(pose)


## A pose neutra: a origem do líder em (0, 0) e a frente para -Z (giro 0), com o ponto médio no seu `z`.
static func _set_neutral(pose: RigidPose) -> void:
	pose.dir = Vector2.UP
	pose.mid = Vector2.UP * pose.mid_z_m
