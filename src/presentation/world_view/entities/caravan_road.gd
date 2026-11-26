class_name CaravanRoad
extends RefCounted
## LW-099f (curvas naturais, EXPERIMENTAL; só apresentação, atrás de um interruptor que nasce DESLIGADO): a ESTRADA de um trecho como uma lista de RETAS e ARCOS no
## plano (x, z), em metros, e as contas puras sobre ela. Sem nó, ponte nem relógio; nada escreve na simulação, e `s` é só a posição da tela: o tempo, o `length_m` da rota
## e a posição lógica seguem na simulação. Cada quina da polilinha vira um arco de raio efetivo R = o maior R <= o pedido que cabe: a tangente R tan(θ/2) não passa
## da METADE do trecho adjacente mais curto, então duas quinas vizinhas nunca disputam o mesmo trecho.
## Convenções: `s` (m) é a distância sobre o EIXO desde o começo do trecho (0 = o mercado de saída). Antes de 0 e depois do fim a estrada CONTINUA em reta (as partes de trás
## de um veículo comprido e as medidas pedem isso; o corpo da frente anda de 0 a `length_m()`). A FAIXA fica à DIREITA da marcha, o mesmo `Vector2(-t.y, t.x)` do
## `CaravanPath` (para quem vai a +X, a direita é +Z). O giro (`atan2(-t.x, -t.y)`: a frente do corpo é -Z local) é de quem usa: aqui só saem PONTOS e TANGENTES.
## `s` não finito (NaN, INF) vale 0 em toda consulta; nenhuma consulta devolve valor não finito, guarda estado ou aloca (só `corners()` devolve a lista da estrada).
## Precisão: o `Vector2` do Godot é float32 (perto de 300 m a resolução é de uns 3e-5 m); os escalares (comprimentos, tangentes, `s`, o ponto fixo de `entering`) são em duplas.

## Dois pontos mais perto que isto (m) são o mesmo ponto: o trecho nulo sai da polilinha (a mesma regra do `CaravanPath`).
const MIN_SEGMENT_M: float = 0.001
## Virada (rad) até a qual a quina conta como reta: sem arco.
const FLAT_TURN_RAD: float = 1e-6
## O raio efetivo pode ficar este tanto (m) abaixo do pedido e ainda assim "caber".
const FIT_TOLERANCE_M: float = 1e-6
## Velocidade da faixa (m de faixa por m de eixo) abaixo da qual ela não tem direção (a ponta de uma volta fechada): vale a tangente do eixo.
const MIN_LANE_SPEED: float = 1e-6
## [HIP] `solve_behind`: a varredura anda `distância / SOLVE_SWEEP_DIVISIONS` por passo, até 2 distâncias mais `SOLVE_REACH_MARGIN_M` para trás de `hi`.
const SOLVE_SWEEP_DIVISIONS: float = 12.0
const SOLVE_REACH_MARGIN_M: float = 2.0
## Teto de passos da varredura (distâncias minúsculas alargam o passo em vez de virar milhões de passos).
const SOLVE_MAX_SWEEP_STEPS: int = 512
## Passos da bisseção no último intervalo: a corda fica a menos de 1e-5 m da distância pedida (o teste mede).
const SOLVE_BISECTIONS: int = 18
## `entering`: número FIXO de passos do ponto fixo do vértice (cada passo corta o erro pela metade ou mais), parada antecipada quando o passo muda menos que
## `ENTRY_SETTLED_M`, e a maior virada (175 graus) que a conta do vértice aceita (a volta de 180 graus tem tangente infinita).
const ENTRY_ITERATIONS: int = 32
const ENTRY_SETTLED_M: float = 1e-10
const ENTRY_MAX_TURN_RAD: float = PI * 175.0 / 180.0
## A tangente de uma estrada vazia: a frente do giro 0 do `CaravanPath` (-Z).
const EMPTY_TANGENT: Vector2 = Vector2(0.0, -1.0)

var _pieces: Array[Piece] = []
var _corners: Array[CaravanRoad.Corner] = []
var _length_m: float = 0.0
var _lane_m: float = 0.0
var _ramp_m: float = 0.0


## A estrada de uma polilinha (ponta A, pontos de passagem, ponta B): retas, com um ARCO de raio efetivo `min(radius_m, room / tan(θ/2))` em cada quina interna (`room` =
## a metade do trecho adjacente mais curto). `radius_m` <= 0 (ou não finito) deixa as quinas vivas: a estrada de hoje. Ponto repetido (a 0,001 m ou menos do anterior) é
## ignorado; ponto não finito, ou menos de 2 pontos distintos, dá a estrada VAZIA (comprimento 0; o ponto vem na origem e a tangente em -Z).
static func through(points: PackedVector2Array, radius_m: float) -> CaravanRoad:
	var pts: PackedVector2Array = PackedVector2Array()
	for point: Vector2 in points:
		if not point.is_finite():
			return CaravanRoad.new()
		if pts.is_empty() or point.distance_to(pts[pts.size() - 1]) > MIN_SEGMENT_M:
			pts.append(point)
	if pts.size() < 2:
		return CaravanRoad.new()
	var radius: float = _sane_radius(radius_m)
	var turns: Array[CaravanRoad.Corner] = []
	for index: int in range(1, pts.size() - 1):
		var leg_in: Vector2 = pts[index] - pts[index - 1]
		var leg_out: Vector2 = pts[index + 1] - pts[index]
		var side: int = 1 if leg_in.cross(leg_out) >= 0.0 else -1
		turns.append(_fit_corner(_turn_between(leg_in, leg_out), side, radius, 0.5 * minf(leg_in.length(), leg_out.length())))
	return _assemble(pts, turns, Vector2.ZERO)


## O trecho que SAI de um povoado de passagem: começa RETO em `start` (s = 0) com a tangente `arrival_dir` (a direção em que a caravana chegou; unitária, ou normalizada),
## faz o arco até a reta que vai a `end` e termina em `end`. Antes de 0 a estrada é a reta de chegada (a extensão em reta, como em `through`). `arrival_dir` nula ou
## não finita, ou `radius_m` <= 0, é o mesmo que `through([start, end], radius_m)`. O vértice da quina fica em `start + arrival_dir * T`, com T = R tan(θ/2) e θ a virada
## NO VÉRTICE (que depende de T): ponto fixo em `ENTRY_ITERATIONS` passos no máximo, em duplas. T nunca passa da METADE do trecho de saída (a regra de `through`) e θ vale
## no máximo 175 graus NESSA conta: a volta de 180 graus não gera tangente infinita; o arco encolhe (raio efetivo menor, `fits` falso) e a estrada segue passando por `start`.
## Virada que dá tangente de 1 mm ou menos fica sem arco (a estrada reta de `start` a `end`).
## `straight_m` > 0 faz o trecho seguir RETO na direção de chegada por `straight_m` metros depois do mercado (s = 0 continua no mercado) e só então começar o arco: serve a um
## corpo que anda à FRENTE da origem do líder (o apoio da frente do cavalo, a +1,2 m), que na troca de trecho ainda estaria na reta de chegada. O vértice passa a ser
## `start + arrival_dir * (straight_m + T)`, com a mesma iteração e os mesmos limites vistos do ponto onde o arco começa (T não passa da metade do trecho de saída e o arco nunca
## começa antes dele). `straight_m` não finito ou <= 0 vale 0 (o comportamento sem o parâmetro, bit a bit) e o teto é a METADE da distância de `start` a `end`.
static func entering(arrival_dir: Vector2, start: Vector2, end: Vector2, radius_m: float, straight_m: float = 0.0) -> CaravanRoad:
	var radius: float = _sane_radius(radius_m)
	var dir_in: Vector2 = arrival_dir.normalized() if arrival_dir.is_finite() else Vector2.ZERO
	var plain: PackedVector2Array = PackedVector2Array([start, end])
	if radius <= 0.0 or dir_in == Vector2.ZERO or not start.is_finite() or not end.is_finite() or start.distance_to(end) <= MIN_SEGMENT_M:
		return through(plain, radius)
	var anchor: Vector2 = start
	if is_finite(straight_m) and straight_m > 0.0:
		anchor = start + dir_in * minf(straight_m, 0.5 * start.distance_to(end))
	var rel: Vector2 = end - anchor
	var cross: float = dir_in.x * rel.y - dir_in.y * rel.x
	var ahead: float = dir_in.x * rel.x + dir_in.y * rel.y
	var reach_m: float = 0.0
	for _step: int in ENTRY_ITERATIONS:
		var gap: float = ahead - reach_m
		var turn: float = minf(atan2(absf(cross), gap), ENTRY_MAX_TURN_RAD)
		var next_m: float = minf(radius * tan(0.5 * turn), 0.5 * sqrt(gap * gap + cross * cross))
		var settled: bool = absf(next_m - reach_m) < ENTRY_SETTLED_M
		reach_m = next_m
		if settled:
			break
	var vertex: Vector2 = anchor + dir_in * reach_m
	var leg_out: Vector2 = end - vertex
	if reach_m <= MIN_SEGMENT_M or leg_out.length() <= MIN_SEGMENT_M:
		return through(plain, radius)
	var gap_out: float = ahead - reach_m
	var room_m: float = minf(reach_m, 0.5 * sqrt(gap_out * gap_out + cross * cross))
	var turns: Array[CaravanRoad.Corner] = [_fit_corner(atan2(absf(cross), gap_out), 1 if cross >= 0.0 else -1, radius, room_m)]
	return _assemble(PackedVector2Array([start, vertex, end]), turns, dir_in)


## Põe a faixa na estrada e a devolve: `offset_m` metros à DIREITA do eixo (negativo: à esquerda; não finito: 0). `ramp_m` > 0 faz o fator da faixa subir de 0 a 1 em `ramp_m`
## metros a partir de cada ponta do trecho (s = 0 e s = `length_m()`), em SMOOTHSTEP (derivada 0 nas pontas: sem dobra, a "rampa suave"). Fora de 0..`length_m()` o fator
## é o de min(|s|, |s - length|): simétrico, então a pose do fim de um trecho é IGUAL à do começo do trecho seguinte. `ramp_m` <= 0 ou não finito: faixa cheia em todo o trecho.
## Trecho menor que 2 rampas: o fator nunca chega a 1 e tem uma crista (dobra) no meio; quem usa deve limitar a rampa à metade do trecho.
func with_lane(offset_m: float, ramp_m: float) -> CaravanRoad:
	_lane_m = offset_m if is_finite(offset_m) else 0.0
	_ramp_m = ramp_m if is_finite(ramp_m) and ramp_m > 0.0 else 0.0
	return self


## O comprimento do EIXO (m); zero na estrada vazia. Com arcos é MENOR que a polilinha (o arco corta a quina): a posição lógica da viagem segue o `length_m` da rota.
func length_m() -> float:
	return _length_m


## A faixa pedida em `with_lane` (m; positivo = direita).
func lane_m() -> float:
	return _lane_m


## Uma entrada por quina interna da polilinha (depois de tirar os pontos repetidos), na ordem da marcha. É a lista da própria estrada: só leia.
func corners() -> Array[CaravanRoad.Corner]:
	return _corners


## O ponto do EIXO a `s` metros do começo do trecho.
func axis_point(s: float) -> Vector2:
	if _pieces.is_empty():
		return Vector2.ZERO
	var along: float = _finite(s)
	return _offset_point(_piece_at(along), along, 0.0)


## A tangente (unitária, no sentido da marcha) do EIXO a `s` metros.
func axis_tangent(s: float) -> Vector2:
	if _pieces.is_empty():
		return EMPTY_TANGENT
	var along: float = _finite(s)
	return _tangent_on(_piece_at(along), along)


## A tangente do EIXO no fim do trecho: a "direção de chegada" que o trecho seguinte usa em `entering`.
func end_tangent() -> Vector2:
	return axis_tangent(_length_m)


## O ponto da FAIXA a `s` metros: o que o veículo segue. Sem faixa é o eixo. `s` continua sendo a posição no EIXO.
func sample(s: float) -> Vector2:
	if _pieces.is_empty():
		return Vector2.ZERO
	var along: float = _finite(s)
	var offset_m: float = 0.0 if _lane_m == 0.0 else _lane_m * _lane_factor(along)
	return _offset_point(_piece_at(along), along, offset_m)


## A tangente (unitária) da FAIXA a `s` metros, em forma fechada: a derivada de `sample`, t (1 - lado L f / R) + n L f', com t a tangente do eixo, n a sua normal à direita,
## L a faixa, f o fator da rampa e R o raio do arco (só nos arcos; `lado` é +1 se o arco vira à direita). Substitui a corda de 0,1 m: aquela erra até ~1e-3 rad onde a
## curvatura salta (as junções reta-arco) e custa duas amostras; esta é exata e usa uma só peça (o teste compara as duas com uma diferença fina). Sem faixa, ou com a
## faixa dobrada sobre si (a ponta de uma volta fechada), é a do eixo. Num trecho menor que 2 rampas o fator tem uma crista (dobra) no meio: no ponto exato da crista vale a derivada da rampa de saída.
func tangent(s: float) -> Vector2:
	if _pieces.is_empty():
		return EMPTY_TANGENT
	var along: float = _finite(s)
	var piece: Piece = _piece_at(along)
	var axis_dir: Vector2 = _tangent_on(piece, along)
	if _lane_m == 0.0:
		return axis_dir
	var stretch: float = 1.0
	if piece.is_arc:
		stretch = 1.0 - piece.turn * _lane_m * _lane_factor(along) / piece.radius
	var velocity: Vector2 = axis_dir * stretch + Vector2(-axis_dir.y, axis_dir.x) * (_lane_m * _lane_slope(along))
	var speed: float = velocity.length()
	return velocity / speed if speed > MIN_LANE_SPEED else axis_dir


## O `s` do ponto da FAIXA a `distance_m` de `q`, procurado PARA TRÁS de `hi` (pré-condição: o ponto de `hi` está mais perto que `distance_m` de `q`, e há um ponto a
## `distance_m` ou mais até 2 distâncias mais 2 m atrás de `hi`). Varre para trás em passos de `distance_m / 12` até o PRIMEIRO ponto a `distance_m` ou mais (a estrada que
## volta sobre si não engana a bisseção) e bisseciona o último intervalo. Sem a pré-condição devolve um palpite finito. `distance_m` não positivo ou não finito, `q` não
## finito ou estrada vazia: devolve `hi`. Numa quina VIVA (raio 0) a faixa dá um salto no vértice: uma corda que cai no salto não tem solução exata e sai o ponto do salto.
func solve_behind(q: Vector2, distance_m: float, hi: float) -> float:
	var top: float = _finite(hi)
	if _pieces.is_empty() or not q.is_finite() or not is_finite(distance_m) or distance_m <= 0.0:
		return top
	var low: float = top - 2.0 * distance_m - SOLVE_REACH_MARGIN_M
	var step_m: float = maxf(distance_m / SOLVE_SWEEP_DIVISIONS, (top - low) / float(SOLVE_MAX_SWEEP_STEPS))
	var squared: float = distance_m * distance_m
	var nearer: float = top
	var probe: float = top
	for _sweep: int in ceili((top - low) / step_m):
		probe -= step_m
		if sample(probe).distance_squared_to(q) >= squared:
			low = probe
			top = nearer
			break
		nearer = probe
	for _bisection: int in SOLVE_BISECTIONS:
		var middle: float = 0.5 * (low + top)
		if sample(middle).distance_squared_to(q) > squared:
			low = middle
		else:
			top = middle
	return 0.5 * (low + top)


## (distância ao EIXO, lado com sinal; positivo = DIREITA da marcha) de um ponto; as retas das pontas se estendem. Estrada vazia ou ponto não finito: (0, 0).
func axis_offset(point: Vector2) -> Vector2:
	if _pieces.is_empty() or not point.is_finite():
		return Vector2.ZERO
	var best_m: float = INF
	var signed_m: float = 0.0
	var last: int = _pieces.size() - 1
	for index: int in _pieces.size():
		var piece: Piece = _pieces[index]
		var side_m: float
		if piece.is_arc:
			var swept: float = piece.turn * angle_difference(piece.angle0, (point - piece.origin).angle())
			if swept < 0.0 or swept > piece.length / piece.radius:
				continue
			side_m = piece.turn * (piece.radius - point.distance_to(piece.origin))
		else:
			var along: float = clampf((point - piece.origin).dot(piece.dir), -INF if index == 0 else 0.0, INF if index == last else piece.length)
			var off: Vector2 = point - (piece.origin + piece.dir * along)
			side_m = off.length() if piece.dir.cross(off) >= 0.0 else -off.length()
		if absf(side_m) < best_m:
			best_m = absf(side_m)
			signed_m = side_m
	return Vector2(best_m, signed_m) if is_finite(best_m) else Vector2.ZERO


static func _finite(value: float) -> float:
	return value if is_finite(value) else 0.0


static func _sane_radius(radius_m: float) -> float:
	return radius_m if is_finite(radius_m) and radius_m > 0.0 else 0.0


## O ângulo (rad, de 0 a PI) entre dois trechos, em duplas (`Vector2.angle_to` devolve float32).
static func _turn_between(leg_in: Vector2, leg_out: Vector2) -> float:
	return absf(atan2(leg_in.cross(leg_out), leg_in.dot(leg_out)))


## O fator da faixa (0 a 1) a `s`: smoothstep da distância à ponta mais próxima do trecho (valendo também antes de 0 e depois do fim).
func _lane_factor(s: float) -> float:
	if _ramp_m <= 0.0:
		return 1.0
	return smoothstep(0.0, _ramp_m, minf(absf(s), absf(s - _length_m)))


## A derivada de `_lane_factor` em `s` (por metro): 6 u (1 - u) / rampa, com o sinal de quem se afasta da ponta mais próxima.
func _lane_slope(s: float) -> float:
	if _ramp_m <= 0.0:
		return 0.0
	var from_start: bool = absf(s) <= absf(s - _length_m)
	var near_m: float = absf(s) if from_start else absf(s - _length_m)
	var u: float = minf(near_m, _ramp_m) / _ramp_m
	return 6.0 * u * (1.0 - u) / _ramp_m * (signf(s) if from_start else signf(s - _length_m))


## A peça que cobre `s`; antes de 0 é a primeira (sempre uma reta) e depois do fim a última (também reta). Só com a estrada não vazia.
func _piece_at(s: float) -> Piece:
	if s <= 0.0:
		return _pieces[0]
	for piece: Piece in _pieces:
		if s < piece.start_s + piece.length:
			return piece
	return _pieces[_pieces.size() - 1]


## O ponto da peça a `s`, deslocado `offset_m` para a DIREITA do eixo. No arco o deslocamento é radial: o centro fica à direita quando `turn` é +1.
func _offset_point(piece: Piece, s: float, offset_m: float) -> Vector2:
	var along: float = s - piece.start_s
	if piece.is_arc:
		var angle: float = piece.angle0 + piece.turn * along / piece.radius
		return piece.origin + Vector2(cos(angle), sin(angle)) * (piece.radius - piece.turn * offset_m)
	return piece.origin + piece.dir * along + Vector2(-piece.dir.y, piece.dir.x) * offset_m


func _tangent_on(piece: Piece, s: float) -> Vector2:
	if piece.is_arc:
		var angle: float = piece.angle0 + piece.turn * (s - piece.start_s) / piece.radius
		return Vector2(-sin(angle), cos(angle)) * piece.turn
	return piece.dir


## O que a estrada faz numa quina de virada `turn_rad` para o lado `side`; `room_m` é quanto o arco pode comer de cada trecho. Sem arco quando o raio pedido é 0 (quina
## viva: raio efetivo 0) ou a quina é reta (virada <= `FLAT_TURN_RAD`: nada limita o raio, o efetivo é o pedido e `fits` fica verdadeiro).
static func _fit_corner(turn_rad: float, side: int, radius: float, room_m: float) -> CaravanRoad.Corner:
	var corner: CaravanRoad.Corner = CaravanRoad.Corner.new()
	corner.turn_rad = turn_rad
	corner.side = side
	corner.radius_req_m = radius
	if turn_rad <= FLAT_TURN_RAD:
		corner.radius_eff_m = radius
	elif radius > 0.0:
		var half_tan: float = tan(0.5 * turn_rad)
		corner.radius_eff_m = minf(radius, room_m / half_tan)
		corner.tangent_m = corner.radius_eff_m * half_tan
		corner.fits = corner.radius_eff_m >= radius - FIT_TOLERANCE_M
	return corner


## Monta as peças: uma reta por trecho (menos as tangentes das quinas das duas pontas) e um arco por quina com tangente; completa o que cada `Corner` conta da estrada.
## `first_dir` (unitário, ou zero) é a direção EXATA do primeiro trecho quando a polilinha foi montada em volta dela (o vértice de `entering` é arredondado em float32).
static func _assemble(pts: PackedVector2Array, turns: Array[CaravanRoad.Corner], first_dir: Vector2) -> CaravanRoad:
	var road: CaravanRoad = CaravanRoad.new()
	var travelled: float = 0.0
	for index: int in pts.size() - 1:
		var leg: Vector2 = pts[index + 1] - pts[index]
		var leg_m: float = leg.length()
		var dir: Vector2 = first_dir if index == 0 and first_dir != Vector2.ZERO else leg / leg_m
		var cut_in: float = turns[index - 1].tangent_m if index >= 1 else 0.0
		var cut_out: float = turns[index].tangent_m if index < turns.size() else 0.0
		var line: Piece = Piece.new()
		line.origin = pts[index] + dir * cut_in
		line.dir = dir
		line.start_s = travelled
		line.length = maxf(leg_m - cut_in - cut_out, 0.0)
		road._pieces.append(line)
		travelled += line.length
		if index >= turns.size():
			continue
		var corner: CaravanRoad.Corner = turns[index]
		corner.apex_s = travelled
		if corner.tangent_m <= 0.0:
			continue
		var arc: Piece = Piece.new()
		var entry: Vector2 = pts[index + 1] - dir * corner.tangent_m
		arc.is_arc = true
		arc.start_s = travelled
		arc.radius = corner.radius_eff_m
		arc.turn = float(corner.side)
		arc.length = arc.radius * corner.turn_rad
		arc.origin = entry + Vector2(-dir.y, dir.x) * (arc.turn * arc.radius)
		arc.angle0 = atan2(-dir.x * arc.turn, dir.y * arc.turn)
		road._pieces.append(arc)
		corner.arc_m = arc.length
		corner.cut_m = 2.0 * corner.tangent_m - arc.length
		corner.apex_s = travelled + 0.5 * arc.length
		corner.apex_off_m = arc.radius * (1.0 / cos(0.5 * corner.turn_rad) - 1.0)
		travelled += arc.length
	road._corners = turns
	road._length_m = travelled
	return road


## Uma peça da estrada (interna): uma reta ou um arco, de `start_s` até `start_s + length` sobre o eixo.
class Piece:
	extends RefCounted

	var is_arc: bool = false
	var start_s: float = 0.0
	var length: float = 0.0
	## Reta: o ponto inicial. Arco: o CENTRO.
	var origin: Vector2 = Vector2.ZERO
	## Reta: a direção (unitária).
	var dir: Vector2 = Vector2.RIGHT
	var radius: float = 0.0
	## Arco: o ângulo (rad) do ponto inicial visto do centro; andando `d` metros o ângulo muda `turn * d / radius`.
	var angle0: float = 0.0
	## Arco: +1 vira para a DIREITA (o centro fica à direita), -1 para a esquerda.
	var turn: float = 1.0


## O que a estrada faz numa quina da polilinha.
class Corner:
	extends RefCounted

	## A virada (rad, >= 0) entre o trecho que chega e o que sai.
	var turn_rad: float = 0.0
	## +1 se vira para a DIREITA da marcha (o lado da faixa positiva), -1 para a esquerda.
	var side: int = 1
	## O raio pedido e o efetivo (m). Sem arco o efetivo é 0 (quina viva) ou o pedido (quina reta: nada o limita).
	var radius_req_m: float = 0.0
	var radius_eff_m: float = 0.0
	## Quanto o arco come de cada trecho (m): R tan(θ/2) com o raio efetivo.
	var tangent_m: float = 0.0
	## O comprimento do arco (m) e quanto ele ENCURTA a estrada: duas tangentes menos o arco.
	var arc_m: float = 0.0
	var cut_m: float = 0.0
	## O `s` do meio do arco (ou da quina viva) e a distância (m) do meio do arco ao vértice da polilinha.
	var apex_s: float = 0.0
	var apex_off_m: float = 0.0
	## O raio efetivo é o pedido?
	var fits: bool = true
