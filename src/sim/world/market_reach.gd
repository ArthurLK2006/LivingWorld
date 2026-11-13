class_name MarketReach
extends RefCounted
## Alcance do mercado (LW-105d1; contrato em docs/modules/world.md, item "Alcance do mercado"). Responde se o ator está perto o bastante
## de um local `market` do assentamento para negociar ali. A REGRA mora no `world` (decisão de Arthur, 12/11/2026): a ponte só coordena
## e nunca calcula distância. Mesmo desenho do InteractionService (LW-049): só leitura, sem estado, sem evento, fora do save e do
## state_hash. A posição do ator vem como argumento porque quem a conhece é o `character` (camada 3), que o `world` (camada 2) não pode
## citar; é a ponte que a lê do personagem, nunca a apresentação.

## Alcance do mercado [HIP, experimental] (metros, inclusive no limite). Valor de trabalho a ajustar depois de jogar: não é requisito
## e pode virar dado. Comparar quadrados (como no InteractionService) deixa o limite exato: 3,000 m passa e 3,001 m não.
const MARKET_REACH_M: float = 3.0
## Código das três recusas (longe demais, posição não finita, assentamento sem mercado): para quem chama, em todas o ator não está ao
## alcance de um mercado, e a mensagem diz qual foi. Prefixo PLACE_ como o CODE_PLACE_UNKNOWN do SettlementService.
const CODE_PLACE_TOO_FAR: String = "PLACE_TOO_FAR"


## Confere se `actor_position` (metros) está ao alcance de um local `market` do assentamento `settlement_id` entre os `places`. Só vale o
## mercado MAIS PRÓXIMO (empate: o de menor id); locais de outro assentamento e de outro tipo são ignorados. Longe demais, posição não
## finita e assentamento sem mercado falham com PLACE_TOO_FAR (mensagem com o que falhou, onde e o esperado). Não altera `places`.
static func peek_within_reach(places: Array[Place], settlement_id: String, actor_position: Vector3) -> Result:
	if not actor_position.is_finite():
		return Result.failure(CODE_PLACE_TOO_FAR, "MarketReach.peek_within_reach: assentamento '%s', posição %s não finita; esperado números finitos." % [settlement_id, str(actor_position)])
	var nearest: Place = _nearest_market(places, settlement_id, actor_position)
	if nearest == null:
		return Result.failure(CODE_PLACE_TOO_FAR, "MarketReach.peek_within_reach: o assentamento '%s' não tem local do tipo '%s' entre os %d locais recebidos; esperado ao menos um." % [settlement_id, Place.KIND_MARKET, places.size()])
	var squared_distance: float = _horizontal_squared_distance(actor_position, nearest.position)
	# Passa só se a conta fecha dentro do alcance: qualquer outro resultado (inclusive não numérico) recusa.
	if squared_distance <= MARKET_REACH_M * MARKET_REACH_M:
		return Result.success()
	return Result.failure(CODE_PLACE_TOO_FAR, "MarketReach.peek_within_reach: ator muito longe do mercado '%s' do assentamento '%s' (%s m, alcance de %s m); esperado chegar a %s m ou menos." % [nearest.id, settlement_id, str(snappedf(sqrt(squared_distance), 0.001)), str(MARKET_REACH_M), str(MARKET_REACH_M)])


## O local `market` do assentamento mais perto do ator no plano x, z (empate: menor id) ou null se o assentamento não tem nenhum. O
## empate decide pelo id, nunca pela ordem da lista recebida.
static func _nearest_market(places: Array[Place], settlement_id: String, actor_position: Vector3) -> Place:
	var nearest: Place = null
	var nearest_squared_distance: float = INF
	for place: Place in places:
		if place.settlement_id != settlement_id or place.kind != Place.KIND_MARKET:
			continue
		var squared_distance: float = _horizontal_squared_distance(actor_position, place.position)
		if nearest == null or squared_distance < nearest_squared_distance or (squared_distance == nearest_squared_distance and place.id < nearest.id):
			nearest = place
			nearest_squared_distance = squared_distance
	return nearest


## Quadrado da distância no plano x, z (a altura não conta: o ator pode estar num degrau acima ou abaixo do centro do local). Comparar
## quadrados evita a raiz e deixa o limite exato: com o alcance de 3 m, uma diferença de exatos 3 m dá 9 contra 9.
static func _horizontal_squared_distance(actor_position: Vector3, place_position: Vector3) -> float:
	var delta_x: float = actor_position.x - place_position.x
	var delta_z: float = actor_position.z - place_position.z
	return delta_x * delta_x + delta_z * delta_z
