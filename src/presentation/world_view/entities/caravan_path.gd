class_name CaravanPath
extends RefCounted
## LW-099a (viagem visível dos comerciantes; só apresentação): a estrada de uma rota como POLILINHA no plano (x, z, em metros) e as contas puras do corpo
## da caravana sobre ela. Sem nó, ponte nem relógio; nada escreve na simulação. A polilinha só desenha: o TEMPO e a posição lógica seguem o `length_m` da
## rota (contrato LW-099, seção 3), então a tela usa a FRAÇÃO `u` de 0 a 1 do comprimento da POLILINHA (não do `length_m`). A polilinha vem guardada no
## sentido de `settlement_a_id` para `settlement_b_id`; `forward` falso é o trecho no sentido contrário. A altura (y) e a inclinação vêm do terreno, na vista.
## O giro segue a direção da CORDA do ponto até `LOOKAHEAD_M` à frente (a tangente média dos próximos metros): contínuo nas quinas e sem estado. O
## deslocamento lateral usa essa MESMA direção, à direita da marcha (a esquerda de quem vai e de quem volta não se cruza). Convenção do giro: a de
## `NpcRoute.facing_yaw` (a frente do corpo é -Z local, como no `look_at`). `sample_into` preenche a `Pose` do chamador: sem alocação por chamada.

## [HIP] Até onde (m) o giro olha à frente.
const LOOKAHEAD_M: float = 2.0
## Dois pontos mais perto que isto (m) são o mesmo ponto: o trecho nulo sai da polilinha e nenhuma conta divide por zero.
const MIN_SEGMENT_M: float = 0.001

var _points: PackedVector2Array = PackedVector2Array()
var _along: PackedFloat64Array = PackedFloat64Array()
var _length_m: float = 0.0


## A polilinha ordenada (ponta A, pontos de passagem, ponta B). Ponto repetido é ignorado; ponto não finito deixa o caminho VAZIO (comprimento zero),
## nunca um valor não finito na tela.
func _init(polyline: PackedVector2Array = PackedVector2Array()) -> void:
	for point: Vector2 in polyline:
		if not point.is_finite():
			_points.clear()
			_along.clear()
			_length_m = 0.0
			return
		if not _points.is_empty():
			var gap: float = point.distance_to(_points[_points.size() - 1])
			if gap <= MIN_SEGMENT_M:
				continue
			_length_m += gap
		_points.append(point)
		_along.append(_length_m)


## A polilinha de uma rota: da ponta `start` pelos pontos de passagem `via` (pode ser vazio: reta) até a ponta `end`.
static func through(start: Vector2, via: PackedVector2Array, end: Vector2) -> CaravanPath:
	var line: PackedVector2Array = PackedVector2Array([start])
	line.append_array(via)
	line.append(end)
	return CaravanPath.new(line)


## Inclinação (rad; positiva com a frente mais alta) de um corpo apoiado em duas alturas do terreno a `spacing_m` uma da outra, limitada a `max_deg` para
## cima e para baixo. Entrada que não presta (espaço não positivo, valor não finito): nivelado.
static func pitch_from_heights(h_back: float, h_front: float, spacing_m: float, max_deg: float) -> float:
	if spacing_m <= 0.0 or not (is_finite(h_back) and is_finite(h_front) and is_finite(spacing_m) and is_finite(max_deg)):
		return 0.0
	var limit: float = deg_to_rad(maxf(max_deg, 0.0))
	return clampf(atan2(h_front - h_back, spacing_m), -limit, limit)


## O comprimento da polilinha (m); zero sem ao menos dois pontos distintos.
func length_m() -> float:
	return _length_m


## Preenche `out` com a posição e o giro a `u` (de 0 a 1; fora disso é cortado, e NaN conta como 0) do comprimento da polilinha, no sentido da marcha
## (`forward` falso: da ponta B para a A), com `lateral_m` metros à DIREITA da marcha (negativo, à esquerda). Sem trecho, fica no único ponto (ou na origem).
## Meia-volta de 180 graus em menos de `LOOKAHEAD_M` tem corda nula: giro 0 e sem deslocamento lateral (o dado de estrada não deve ter isso).
func sample_into(u: float, forward: bool, lateral_m: float, out: Pose) -> void:
	if _points.size() < 2:
		out.position = _points[0] if _points.size() == 1 else Vector2.ZERO
		out.yaw = 0.0
		return
	var travelled: float = 0.0 if is_nan(u) else clampf(u, 0.0, 1.0) * _length_m
	var reach: float = minf(travelled + LOOKAHEAD_M, _length_m)
	var heading: Vector2 = (_at(reach, forward) - _at(maxf(reach - LOOKAHEAD_M, 0.0), forward)).normalized()
	var offset: float = lateral_m if is_finite(lateral_m) else 0.0
	out.position = _at(travelled, forward) + Vector2(-heading.y, heading.x) * offset
	out.yaw = atan2(-heading.x, -heading.y) if heading != Vector2.ZERO else 0.0


## O ponto da polilinha a `distance` metros da saída, no sentido da marcha (`forward` falso conta a partir da outra ponta).
func _at(distance: float, forward: bool) -> Vector2:
	var stored: float = distance if forward else _length_m - distance
	var index: int = 0
	while index < _points.size() - 2 and _along[index + 1] <= stored:
		index += 1
	var fraction: float = clampf((stored - _along[index]) / (_along[index + 1] - _along[index]), 0.0, 1.0)
	return _points[index].lerp(_points[index + 1], fraction)


## Posição (x, z) e giro (rad, em torno de Y) de uma amostra; o chamador cria UMA e a reaproveita a cada quadro.
class Pose:
	extends RefCounted

	var position: Vector2 = Vector2.ZERO
	var yaw: float = 0.0
