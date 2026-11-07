class_name InteractionService
extends RefCounted
## Comando de interação com pontos de interesse (LW-049; contrato em docs/modules/world.md). VALIDA A DISTÂNCIA: a distância
## HORIZONTAL (x, z) entre o ator e o ponto precisa ser de até INTERACT_REACH_M, inclusive no limite. Quem sabe onde o ator está é o
## `character` (camada 3), que o `world` (camada 2) não pode citar; por isso o pedido recebe a posição do ator como argumento e é a
## ponte que a lê do personagem (nunca da apresentação). Em caso de sucesso publica `InteractionPerformed` no barramento (entregue no
## `dispatch()` do passo); devolve só a CHAVE do texto, porque texto de jogo não existe na simulação. Os pontos são conteúdo: o serviço
## não tem estado salvo, não é módulo registrado no `World` e não entra no state_hash.

## Alcance da interação [HIP] (metros, inclusive no limite).
const INTERACT_REACH_M: float = 3.0
const CODE_UNKNOWN_POI: String = "INTERACTION_UNKNOWN_POI"
const CODE_TOO_FAR: String = "INTERACTION_TOO_FAR"
const CODE_INVALID_ACTOR: String = "INTERACTION_INVALID_ACTOR"
const CODE_INVALID_POSITION: String = "INTERACTION_INVALID_POSITION"

var _ctx: SimContext
## Pontos por id (conteúdo, somente leitura) e a ordem do arquivo, para listar sempre na mesma ordem.
var _points: Dictionary[String, PointOfInterest] = {}
var _order: Array[String] = []


func _init(points: Array[PointOfInterest], ctx: SimContext) -> void:
	_ctx = ctx
	for point: PointOfInterest in points:
		_points[point.id] = point
		_order.append(point.id)


## Tenta a interação do ator `actor_id`, que está em `actor_position` (metros), com o ponto `poi_id`. Ponto desconhecido, ator sem ID
## válido, posição não finita e ator longe demais devolvem falha tratada (código próprio e mensagem com o que falhou, onde e o
## esperado) e NÃO publicam evento.
func request_interact(actor_id: int, actor_position: Vector3, poi_id: String) -> InteractionResult:
	if actor_id <= IdGenerator.NO_ID:
		return _failure(CODE_INVALID_ACTOR, "InteractionService.request_interact: actor_id %d inválido; esperado um ID maior que %d." % [actor_id, IdGenerator.NO_ID])
	if not actor_position.is_finite():
		return _failure(CODE_INVALID_POSITION, "InteractionService.request_interact: ator %d, posição %s não finita; esperado números finitos." % [actor_id, str(actor_position)])
	if not _points.has(poi_id):
		return _failure(CODE_UNKNOWN_POI, "InteractionService.request_interact: o ponto '%s' não existe; esperado um dos %d pontos carregados (%s)." % [poi_id, _order.size(), ", ".join(_order)])
	var point: PointOfInterest = _points[poi_id]
	var squared_distance: float = _horizontal_squared_distance(actor_position, point.position)
	if squared_distance > INTERACT_REACH_M * INTERACT_REACH_M:
		return _failure(CODE_TOO_FAR, "InteractionService.request_interact: ator %d muito longe do ponto '%s' (%s m, alcance de %s m); esperado chegar a %s m ou menos." % [actor_id, poi_id, str(snappedf(sqrt(squared_distance), 0.001)), str(INTERACT_REACH_M), str(INTERACT_REACH_M)])
	_ctx.events.publish(InteractionPerformed.new(actor_id, point.id, point.kind))
	return InteractionResult.new(Result.success(), point.id, point.text_key)


## Cópias dos pontos, na ordem do arquivo. Mexer nelas não altera o conteúdo carregado.
func peek_points() -> Array[PointOfInterest]:
	var copies: Array[PointOfInterest] = []
	for poi_id: String in _order:
		var point: PointOfInterest = _points[poi_id]
		copies.append(PointOfInterest.new(point.id, point.kind, point.position, point.text_key))
	return copies


func debug_summary() -> Dictionary:
	return {"count": _points.size(), "ids": _order.duplicate(), "reach_m": INTERACT_REACH_M}


## Quadrado da distância no plano x, z (a altura não conta: o ator pode estar num degrau acima ou abaixo do ponto). Comparar quadrados
## evita a raiz e deixa o limite exato: com o alcance de 3 m, uma diferença de exatos 3 m dá 9 contra 9.
func _horizontal_squared_distance(actor_position: Vector3, point_position: Vector3) -> float:
	var delta_x: float = actor_position.x - point_position.x
	var delta_z: float = actor_position.z - point_position.z
	return delta_x * delta_x + delta_z * delta_z


func _failure(code: String, message: String) -> InteractionResult:
	return InteractionResult.new(Result.failure(code, message), "", "")


## Resposta de `request_interact`: `poi_id` e `text_key` só valem se `result.ok`.
class InteractionResult:
	extends RefCounted

	var result: Result
	var poi_id: String
	var text_key: String

	func _init(interact_result: Result, reached_poi_id: String, reached_text_key: String) -> void:
		result = interact_result
		poi_id = reached_poi_id
		text_key = reached_text_key
