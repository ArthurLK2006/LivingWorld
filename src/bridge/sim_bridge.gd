class_name SimBridge
extends RefCounted
## Ponte mínima entre a apresentação e a simulação (arquitetura 6.7; contrato em docs/modules/bridge.md).
## Não é dona de dado nenhum e não tem regra de jogo: repassa consultas somente-leitura, pedidos de
## pausa e velocidade, o nascimento e o relato de posição do personagem (LW-048) e guarda a fila de intenções. NÃO avança a simulação: o SimulationHost já faz
## isso no seu _process (decisão de Arthur de 05/11/2026). As respostas são tipos próprios, com os
## valores copiados, para a apresentação nunca precisar citar tipos de `sim/`. Esses tipos moram em `BridgeReplies`
## (bridge_replies.gd), fora deste arquivo, para ele não passar do limite de tamanho (LW-053B).

const CODE_NO_GAME: String = "BRIDGE_NO_GAME"
const CODE_NO_TERRAIN: String = "BRIDGE_NO_TERRAIN"
const CODE_NULL_INTENT: String = "BRIDGE_NULL_INTENT"
const CODE_INVALID_ACTOR: String = "BRIDGE_INVALID_ACTOR"
## Há jogo iniciado, mas ele não tem o módulo do personagem (começou sem terreno).
const CODE_NO_CHARACTER: String = "BRIDGE_NO_CHARACTER"
## Há jogo iniciado, mas ele não tem o serviço de interação (começou sem terreno).
const CODE_NO_INTERACTION: String = "BRIDGE_NO_INTERACTION"

var _host: SimulationHostNode
var _terrain: TerrainData
## Locais dos assentamentos (LW-074): conteúdo somente leitura, em ordem crescente de id. Não é salvo nem entra no state_hash.
var _places: Array[Place] = []
## Intenções na ordem de chegada. É estrutura de apresentação: não é salva nem entra no state_hash.
var _pending_intents: Array[BridgeIntent] = []


## `host` e `terrain` podem ser nulos: as chamadas que dependem deles falham com código, sem derrubar o jogo. `places` é opcional
## (sem ele, `peek_places` devolve lista vazia) e fica guardado em ordem crescente de id.
func _init(host: SimulationHostNode, terrain: TerrainData, places: Array[Place] = []) -> void:
	_host = host
	_terrain = terrain
	_places.assign(places)
	_places.sort_custom(_is_before)


## Altura do chão (metros) em (x, z). Fora do mapa ou coordenada não numérica: falha tratada do `world`.
func peek_height(x: float, z: float) -> BridgeReplies.HeightReply:
	if _terrain == null:
		return BridgeReplies.HeightReply.new(_missing_terrain("peek_height"), 0.0)
	var query: TerrainData.HeightQuery = _terrain.peek_height(x, z)
	return BridgeReplies.HeightReply.new(query.result, query.height_m)


func peek_surface(x: float, z: float) -> BridgeReplies.SurfaceReply:
	if _terrain == null:
		return BridgeReplies.SurfaceReply.new(_missing_terrain("peek_surface"), TerrainData.NO_SURFACE_CODE, "")
	var query: TerrainData.SurfaceQuery = _terrain.peek_surface(x, z)
	return BridgeReplies.SurfaceReply.new(query.result, query.surface_code, query.surface_id)


func peek_spawn_point() -> BridgeReplies.SpawnReply:
	if _terrain == null:
		return BridgeReplies.SpawnReply.new(_missing_terrain("peek_spawn_point"), Vector3.ZERO)
	return BridgeReplies.SpawnReply.new(Result.success(), _terrain.peek_spawn_point())


## Formato do terreno (células, tamanho da célula, chunks): é o que a TerrainView precisa para saber quantos
## chunks existem e onde ficam. Valores copiados do TerrainData.
func peek_terrain_layout() -> BridgeReplies.TerrainLayoutReply:
	if _terrain == null:
		return BridgeReplies.TerrainLayoutReply.new(_missing_terrain("peek_terrain_layout"), null)
	return BridgeReplies.TerrainLayoutReply.new(Result.success(), _terrain)


## Cópia da hora simulada e do ritmo no momento da chamada.
func peek_time() -> BridgeReplies.TimeSnapshot:
	var clock: SimClock = _clock()
	if clock == null:
		return BridgeReplies.TimeSnapshot.new(_missing_game("peek_time"), null)
	return BridgeReplies.TimeSnapshot.new(Result.success(), clock)


func request_pause(is_paused: bool) -> Result:
	if _host == null:
		return _missing_game("request_pause")
	return _host.request_pause(is_paused)


## Velocidade de 1 a 8; a faixa é validada pelo relógio e o Result dele é devolvido.
func request_speed(speed: int) -> Result:
	if _host == null:
		return _missing_game("request_speed")
	return _host.request_speed(speed)


## Pontos de interesse do mundo, em CÓPIAS (id, tipo, posição com a altura do terreno, chave de texto e alcance da interação), para a
## apresentação desenhar e detectar o ponto próximo. É só dica visual: quem decide se a interação vale é `request_interact`.
func peek_points_of_interest() -> BridgeReplies.PointsReply:
	var interaction: InteractionService = _interaction()
	if interaction == null:
		return BridgeReplies.PointsReply.new(_missing_interaction("peek_points_of_interest"), [])
	var copies: Array[BridgeReplies.PointReply] = []
	for point: PointOfInterest in interaction.peek_points():
		copies.append(BridgeReplies.PointReply.new(point))
	return BridgeReplies.PointsReply.new(Result.success(), copies)


## TODOS os locais dos assentamentos, em CÓPIAS e em ordem crescente de id (id, assentamento, tipo, posição com a altura do terreno e
## capacidade), para a apresentação desenhar. Não depende do host. Ponte sem terreno: falha `BRIDGE_NO_TERRAIN`; sem locais: lista vazia.
func peek_places() -> BridgeReplies.PlacesReply:
	if _terrain == null:
		return BridgeReplies.PlacesReply.new(_missing_terrain("peek_places"), [])
	var copies: Array[BridgeReplies.PlaceReply] = []
	for place: Place in _places:
		copies.append(BridgeReplies.PlaceReply.new(place))
	return BridgeReplies.PlacesReply.new(Result.success(), copies)


## Pede a interação do ator com o ponto. A posição do ator vem SEMPRE do que está guardado no personagem (o último relato do corpo),
## nunca da apresentação: a simulação confere a distância (alcance de InteractionService.INTERACT_REACH_M). Sucesso: a chave do texto
## do ponto e o evento InteractionPerformed (entregue no próximo passo). Ator desconhecido: falha do personagem; ponto desconhecido
## ou longe demais: falha da interação.
func request_interact(actor_id: int, poi_id: String) -> BridgeReplies.InteractReply:
	var interaction: InteractionService = _interaction()
	if interaction == null:
		return BridgeReplies.InteractReply.new(_missing_interaction("request_interact"), "", "")
	var character: CharacterModule = _character()
	if character == null:
		return BridgeReplies.InteractReply.new(_missing_character("request_interact"), "", "")
	var stored: CharacterQuery = character.peek_character(actor_id)
	if not stored.result.ok:
		return BridgeReplies.InteractReply.new(stored.result, "", "")
	var outcome: InteractionService.InteractionResult = interaction.request_interact(actor_id, stored.position, poi_id)
	return BridgeReplies.InteractReply.new(outcome.result, outcome.poi_id, outcome.text_key)


## Pede o nascimento de um personagem (ID novo, no ponto de nascimento do terreno). Quem pede é quem guarda o `actor_id`: a ponte
## não é dona de "o jogador" e pode atender vários atores. `actor_id` só vale se `result.ok`.
func request_spawn_character() -> BridgeReplies.SpawnCharacterReply:
	var character: CharacterModule = _character()
	if character == null:
		return BridgeReplies.SpawnCharacterReply.new(_missing_character("request_spawn_character"), IdGenerator.NO_ID)
	var spawn: SpawnResult = character.request_spawn()
	return BridgeReplies.SpawnCharacterReply.new(spawn.result, spawn.actor_id)


## Repassa ao personagem a posição (metros) e a orientação (radianos) que o corpo físico informa. A simulação nunca devolve posição
## ao corpo: o fluxo é de um sentido só (arquitetura 6.2). Valor não finito, fora do mapa ou ator desconhecido: falha tratada do módulo.
func request_report_position(actor_id: int, position: Vector3, yaw: float) -> Result:
	var character: CharacterModule = _character()
	if character == null:
		return _missing_character("request_report_position")
	return character.report_position(actor_id, position, yaw)


## Cópia da posição e da orientação guardadas na simulação para o ator. Ator desconhecido: falha tratada, sem derrubar.
func peek_character(actor_id: int) -> BridgeReplies.CharacterReply:
	var character: CharacterModule = _character()
	if character == null:
		return BridgeReplies.CharacterReply.new(_missing_character("peek_character"), Vector3.ZERO, 0.0)
	var query: CharacterQuery = character.peek_character(actor_id)
	return BridgeReplies.CharacterReply.new(query.result, query.position, query.yaw)


## Enfileira uma intenção. Recusa intenção nula e ator sem ID válido. Nada a consome ainda.
func submit_intent(intent: BridgeIntent) -> Result:
	if intent == null:
		return Result.failure(CODE_NULL_INTENT, "SimBridge.submit_intent: intenção nula; esperado um BridgeIntent.")
	if intent.actor_id <= IdGenerator.NO_ID:
		return Result.failure(CODE_INVALID_ACTOR, "SimBridge.submit_intent: actor_id %d inválido; esperado um ID maior que %d." % [intent.actor_id, IdGenerator.NO_ID])
	_pending_intents.append(intent)
	return Result.success()


## Entrega as intenções pendentes na ordem de chegada e esvazia a fila.
func take_pending_intents() -> Array[BridgeIntent]:
	var taken: Array[BridgeIntent] = _pending_intents
	_pending_intents = []
	return taken


func pending_intent_count() -> int:
	return _pending_intents.size()


static func _is_before(first: Place, second: Place) -> bool:
	return first.id < second.id


func _clock() -> SimClock:
	if _host == null or _host.runner == null:
		return null
	return _host.runner.world.context.clock


## Módulo do personagem do jogo atual, ou nulo (sem host, sem jogo ou jogo sem terreno).
func _character() -> CharacterModule:
	if _host == null or _host.runner == null:
		return null
	return _host.character


## Serviço de interação do jogo atual, ou nulo (sem host, sem jogo ou jogo sem terreno).
func _interaction() -> InteractionService:
	if _host == null or _host.runner == null:
		return null
	return _host.interaction


func _missing_interaction(caller: String) -> Result:
	if _host == null or _host.runner == null:
		return _missing_game(caller)
	return Result.failure(CODE_NO_INTERACTION, "SimBridge.%s: o jogo atual não tem pontos de interesse; esperado um jogo iniciado com terreno (SimulationHost.start_new_game(seed, terreno, pontos))." % caller)


func _missing_character(caller: String) -> Result:
	if _host == null or _host.runner == null:
		return _missing_game(caller)
	return Result.failure(CODE_NO_CHARACTER, "SimBridge.%s: o jogo atual não tem o módulo do personagem; esperado um jogo iniciado com terreno (SimulationHost.start_new_game(seed, terreno))." % caller)


func _missing_game(caller: String) -> Result:
	return Result.failure(CODE_NO_GAME, "SimBridge.%s: sem jogo iniciado no SimulationHost; esperado um host com start_new_game já chamado." % caller)


func _missing_terrain(caller: String) -> Result:
	return Result.failure(CODE_NO_TERRAIN, "SimBridge.%s: terreno não carregado; esperado um TerrainData ao criar a ponte." % caller)
