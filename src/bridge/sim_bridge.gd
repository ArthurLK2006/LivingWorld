class_name SimBridge
extends RefCounted
## Ponte mínima entre a apresentação e a simulação (arquitetura 6.7; contrato em docs/modules/bridge.md).
## Não é dona de dado nenhum e não tem regra de jogo: repassa consultas somente-leitura, pedidos de
## pausa e velocidade, o nascimento e o relato de posição do personagem (LW-048) e guarda a fila de intenções. NÃO avança a simulação: o SimulationHost já faz
## isso no seu _process (decisão de Arthur de 05/11/2026). As respostas são tipos próprios, com os
## valores copiados, para a apresentação nunca precisar citar tipos de `sim/`. Esses tipos moram em `BridgeReplies`
## (bridge_replies.gd), fora deste arquivo, para ele não passar do limite de tamanho (LW-053B).
## LW-070: repasses finos do protocolo de NPC em S0 (intenções pendentes, resultado e posições do corpo) ao `NpcModule`, que a ponte recebe
## no construtor (opcional), e a entrega do foco do LOD a cada relato de posição do ator. Nenhuma regra de jogo aqui.
## LW-072a: o interruptor de corpos e a consulta dos corpos a manter (os NPCs em S0), para a apresentação desenhar os NPCs.
## LW-108b: três consultas de leitura da economia (`peek_economy_*`) para o painel econômico de depuração; a conta fica em `BridgeEconomyInspect`.

const CODE_NO_GAME: String = "BRIDGE_NO_GAME"
const CODE_NO_TERRAIN: String = "BRIDGE_NO_TERRAIN"
const CODE_NULL_INTENT: String = "BRIDGE_NULL_INTENT"
const CODE_INVALID_ACTOR: String = "BRIDGE_INVALID_ACTOR"
## Há jogo iniciado, mas ele não tem o módulo do personagem (começou sem terreno).
const CODE_NO_CHARACTER: String = "BRIDGE_NO_CHARACTER"
## Há jogo iniciado, mas ele não tem o serviço de interação (começou sem terreno).
const CODE_NO_INTERACTION: String = "BRIDGE_NO_INTERACTION"
## A ponte foi criada sem o módulo `npc` (LW-070): as chamadas de NPC falham com este código.
const CODE_NO_NPC: String = "BRIDGE_NO_NPC"
## O desfecho recebido não é um dos quatro de `BridgeReplies.NpcOutcome` (só acontece com conversão forçada de inteiro).
const CODE_INVALID_OUTCOME: String = "BRIDGE_INVALID_OUTCOME"
## Há jogo iniciado, mas ele não tem o módulo da economia (começou sem terreno): as consultas `peek_economy_*` falham com este código (LW-108b).
const CODE_NO_ECONOMY: String = "BRIDGE_NO_ECONOMY"

var _host: SimulationHostNode
var _terrain: TerrainData
## Locais dos assentamentos (LW-074): conteúdo somente leitura, em ordem crescente de id. Não é salvo nem entra no state_hash.
var _places: Array[Place] = []
## Módulo `npc` (LW-070), opcional: sem ele as chamadas de NPC falham com BRIDGE_NO_NPC e o relato de posição não entrega foco.
var _npc: NpcModule
## Intenções na ordem de chegada. É estrutura de apresentação: não é salva nem entra no state_hash.
var _pending_intents: Array[BridgeIntent] = []


## `host` e `terrain` podem ser nulos: as chamadas que dependem deles falham com código, sem derrubar o jogo. `places` é opcional
## (sem ele, `peek_places` devolve lista vazia) e fica guardado em ordem crescente de id. `npc` (LW-070) também é opcional.
func _init(host: SimulationHostNode, terrain: TerrainData, places: Array[Place] = [], npc: NpcModule = null) -> void:
	_host = host
	_terrain = terrain
	_places.assign(places)
	_places.sort_custom(_is_before)
	_npc = npc


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


## Pede ao NPC para conversar com o ator (LW-083d). Como em `request_interact`, a posição do ator vem SEMPRE do que está guardado no personagem, nunca da
## apresentação; o resto é do `npc` (`NpcModule.request_converse`). A resposta traz sempre a chave do texto: a da conversa (`first`, `known`) ou a da recusa, pelo código.
## Sem `npc`: BRIDGE_NO_NPC; sem o personagem ou ator desconhecido: a falha dele. Em todas as falhas a chave é a da recusa ou a genérica.
func request_converse(actor_id: int, npc_id: int) -> BridgeReplies.ConverseReply:
	if _npc == null:
		return BridgeReplies.ConverseReply.new(_missing_npc("request_converse"), "", false)
	var character: CharacterModule = _character()
	if character == null:
		return BridgeReplies.ConverseReply.new(_missing_character("request_converse"), "", false)
	var stored: CharacterQuery = character.peek_character(actor_id)
	if not stored.result.ok:
		return BridgeReplies.ConverseReply.new(stored.result, "", false)
	var outcome: NpcModule.ConverseResult = _npc.request_converse(actor_id, stored.position, npc_id)
	return BridgeReplies.ConverseReply.new(outcome.result, outcome.text_key, outcome.was_promoted)


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
## LW-070: com o relato aceito e a ponte ligada ao `npc`, repassa a ele o FOCO do LOD (`request_set_focus`) com a posição que ficou
## GUARDADA no personagem (como em request_interact), nunca o valor cru. Se o `npc` recusar o foco (ex.: LOD sem parâmetros) a falha dele
## é devolvida, mas o relato do personagem já foi guardado.
func request_report_position(actor_id: int, position: Vector3, yaw: float) -> Result:
	var character: CharacterModule = _character()
	if character == null:
		return _missing_character("request_report_position")
	var reported: Result = character.report_position(actor_id, position, yaw)
	if not reported.ok or _npc == null:
		return reported
	return _npc.request_set_focus(actor_id, character.peek_character(actor_id).position)


## Cópia da posição e da orientação guardadas na simulação para o ator. Ator desconhecido: falha tratada, sem derrubar.
func peek_character(actor_id: int) -> BridgeReplies.CharacterReply:
	var character: CharacterModule = _character()
	if character == null:
		return BridgeReplies.CharacterReply.new(_missing_character("peek_character"), Vector3.ZERO, 0.0)
	var query: CharacterQuery = character.peek_character(actor_id)
	return BridgeReplies.CharacterReply.new(query.result, query.position, query.yaw)


## Intenções de NPC em S0 que a apresentação ainda não cumpriu (LW-070), em CÓPIAS, em ordem crescente de NPC, com o destino em metros e a
## altura do terreno. A ponte só repassa: quem decide o que é uma intenção é o `npc`. Sem terreno: BRIDGE_NO_TERRAIN; sem `npc`: BRIDGE_NO_NPC.
func peek_pending_npc_intents() -> BridgeReplies.NpcIntentsReply:
	if _terrain == null:
		return BridgeReplies.NpcIntentsReply.new(_missing_terrain("peek_pending_npc_intents"), [])
	if _npc == null:
		return BridgeReplies.NpcIntentsReply.new(_missing_npc("peek_pending_npc_intents"), [])
	var copies: Array[BridgeReplies.NpcIntentReply] = []
	for intent: NpcIntent in _npc.peek_pending_intents():
		var x_m: float = float(intent.destination_cm.x) / TerrainData.CM_PER_METER
		var z_m: float = float(intent.destination_cm.y) / TerrainData.CM_PER_METER
		var ground: TerrainData.HeightQuery = _terrain.peek_height(x_m, z_m)
		if not ground.result.ok:
			return BridgeReplies.NpcIntentsReply.new(ground.result, [])
		copies.append(BridgeReplies.NpcIntentReply.new(intent, Vector3(x_m, ground.height_m, z_m)))
	return BridgeReplies.NpcIntentsReply.new(Result.success(), copies)


## Repassa ao `npc` o resultado que a apresentação devolve de uma intenção (LW-070): o contador da ação que veio na intenção, o desfecho e a
## posição final do corpo em metros. A ponte não decide nada: sucesso, descarte de ação velha e falhas são do `npc` e os códigos dele passam.
func request_report_npc_result(npc_id: int, action_serial: int, outcome: BridgeReplies.NpcOutcome, final_position: Vector3) -> Result:
	if _npc == null:
		return _missing_npc("request_report_npc_result")
	var mapped: NpcActionResult.Outcome = NpcActionResult.Outcome.CANCELLED
	match outcome:
		BridgeReplies.NpcOutcome.ARRIVED:
			mapped = NpcActionResult.Outcome.ARRIVED
		BridgeReplies.NpcOutcome.DONE:
			mapped = NpcActionResult.Outcome.DONE
		BridgeReplies.NpcOutcome.BLOCKED:
			mapped = NpcActionResult.Outcome.BLOCKED
		BridgeReplies.NpcOutcome.CANCELLED:
			mapped = NpcActionResult.Outcome.CANCELLED
		_:
			return Result.failure(CODE_INVALID_OUTCOME, "SimBridge.request_report_npc_result: desfecho %d desconhecido; esperado ARRIVED, DONE, BLOCKED ou CANCELLED (BridgeReplies.NpcOutcome)." % outcome)
	return _npc.request_report_npc_result(NpcActionResult.new(npc_id, action_serial, mapped, final_position))


## Repassa ao `npc` as posições dos corpos em S0, em lote (NPC -> posição em metros; o corpo relata no máximo a cada 6 quadros de física
## [HIP]). Cada posição vale por si: as válidas valem mesmo se outra do lote for recusada, e a falha devolvida é a da primeira recusada.
func request_report_npc_positions(positions: Dictionary[int, Vector3]) -> Result:
	if _npc == null:
		return _missing_npc("request_report_npc_positions")
	return _npc.request_report_npc_positions(positions)


## Repassa ao `npc` se a apresentação tem corpos para os NPCs em S0 (LW-072a). Sem corpos o `npc` mantém todos em S1; o jogo nasce sem eles e a
## apresentação os liga. A ponte não decide nada: o Result do `npc` volta como está. Sem `npc`: BRIDGE_NO_NPC.
func request_set_bodies_available(available: bool) -> Result:
	if _npc == null:
		return _missing_npc("request_set_bodies_available")
	return _npc.request_set_bodies_available(available)


## Os corpos que a apresentação deve manter agora (LW-072a): os NPCs em S0, em CÓPIAS e em ordem crescente de NPC, com a posição em metros
## (x e z do LOD, y = altura do terreno). Lista vazia enquanto não há corpos ou ninguém está perto. A apresentação CONSULTA a cada quadro (sem
## sinal); quem decide quem está em S0 é o LOD do `npc`. Sem terreno: BRIDGE_NO_TERRAIN; sem `npc`: BRIDGE_NO_NPC.
func peek_npc_bodies() -> BridgeReplies.NpcBodiesReply:
	if _terrain == null:
		return BridgeReplies.NpcBodiesReply.new(_missing_terrain("peek_npc_bodies"), [])
	if _npc == null:
		return BridgeReplies.NpcBodiesReply.new(_missing_npc("peek_npc_bodies"), [])
	var copies: Array[BridgeReplies.NpcBodyReply] = []
	for npc_id: int in _npc.lod.s0_ids():
		var spot_m: Vector2 = Vector2(_npc.lod.position_of(npc_id)) / TerrainData.CM_PER_METER
		var ground: TerrainData.HeightQuery = _terrain.peek_height(spot_m.x, spot_m.y)
		if not ground.result.ok:
			return BridgeReplies.NpcBodiesReply.new(ground.result, [])
		copies.append(BridgeReplies.NpcBodyReply.new(npc_id, Vector3(spot_m.x, ground.height_m, spot_m.y)))
	return BridgeReplies.NpcBodiesReply.new(Result.success(), copies)


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


func _missing_npc(caller: String) -> Result:
	return Result.failure(CODE_NO_NPC, "SimBridge.%s: a ponte foi criada sem o módulo `npc`; esperado SimBridge.new(host, terreno, locais, módulo npc)." % caller)


## Módulo da economia do jogo atual, ou nulo (sem host, sem jogo ou jogo sem terreno). Como `character` e `interaction`, vem do host a cada chamada.
func _economy() -> EconomyModule:
	if _host == null or _host.runner == null:
		return null
	return _host.economy


func _missing_economy(caller: String) -> Result:
	if _host == null or _host.runner == null:
		return _missing_game(caller)
	return Result.failure(CODE_NO_ECONOMY, "SimBridge.%s: o jogo atual não tem o módulo da economia; esperado um jogo iniciado com terreno (SimulationHost.start_new_game(seed, terreno, ...))." % caller)


func _missing_game(caller: String) -> Result:
	return Result.failure(CODE_NO_GAME, "SimBridge.%s: sem jogo iniciado no SimulationHost; esperado um host com start_new_game já chamado." % caller)


func _missing_terrain(caller: String) -> Result:
	return Result.failure(CODE_NO_TERRAIN, "SimBridge.%s: terreno não carregado; esperado um TerrainData ao criar a ponte." % caller)



# ---------------------------------------------------------------------------------------------------- Inspeção de NPC (LW-082c)
# Consultas só de leitura para o painel de depuração (docs/modules/bridge.md, "Inspeção de NPC"; docs/modules/tools.md). A conta fica em `BridgeNpcInspect`;
# aqui só se confere a ponte sem `npc` ou sem jogo e se delega. Cada resposta traz cópias e nenhuma exige terreno.

## A lista de todos os NPCs, inclusive os mortos e os sem corpo, em ordem crescente de id. Sem `npc`: BRIDGE_NO_NPC.
func peek_npc_roster() -> BridgeInspectReplies.NpcRosterReply:
	if _npc == null:
		return BridgeInspectReplies.NpcRosterReply.new(_missing_npc("peek_npc_roster"))
	return BridgeNpcInspect.roster(_npc)


## O detalhe de um NPC (necessidades, ação, ofício, nível S0 ou S1 e a ação da rotina agora). Sem `npc`: BRIDGE_NO_NPC; sem jogo: BRIDGE_NO_GAME (a hora
## vem do relógio da simulação); NPC inexistente: NPC_UNKNOWN, do `npc`.
func peek_npc_detail(npc_id: int) -> BridgeInspectReplies.NpcDetailReply:
	if _npc == null:
		return BridgeInspectReplies.NpcDetailReply.new(_missing_npc("peek_npc_detail"))
	var clock: SimClock = _clock()
	if clock == null:
		return BridgeInspectReplies.NpcDetailReply.new(_missing_game("peek_npc_detail"))
	return BridgeNpcInspect.detail(_npc, npc_id, clock.hour_of_day())


## Os contadores globais: hora, NPCs por camada e nível, vivos e mortos, Intents pendentes e os problemas do `validate()` do mundo. Sem `npc`:
## BRIDGE_NO_NPC; sem jogo: BRIDGE_NO_GAME. [LIM] o custo do `validate()` do mundo inteiro não foi medido.
func peek_simulation_summary() -> BridgeInspectReplies.SimSummaryReply:
	if _npc == null:
		return BridgeInspectReplies.SimSummaryReply.new(_missing_npc("peek_simulation_summary"))
	var time: BridgeReplies.TimeSnapshot = peek_time()
	if not time.result.ok:
		return BridgeInspectReplies.SimSummaryReply.new(time.result)
	return BridgeNpcInspect.summary(_npc, time, _host.runner.world.validate())


## O rastro de decisão do NPC MARCADO (cópias, do mais antigo ao mais novo). NPC não marcado: NPC_NOT_TRACED, do `npc`, que o painel lê como "sem marca";
## inexistente: NPC_UNKNOWN. Sem `npc`: BRIDGE_NO_NPC.
func peek_npc_trace(npc_id: int) -> BridgeInspectReplies.NpcTraceReply:
	if _npc == null:
		return BridgeInspectReplies.NpcTraceReply.new(_missing_npc("peek_npc_trace"))
	return BridgeNpcInspect.trace(_npc, npc_id)


## As memórias e os traços permanentes do NPC (cópias; só o notável T2 tem registros). Sem `npc`: BRIDGE_NO_NPC; inexistente: NPC_UNKNOWN.
func peek_npc_memories(npc_id: int) -> BridgeInspectReplies.NpcMemoriesReply:
	if _npc == null:
		return BridgeInspectReplies.NpcMemoriesReply.new(_missing_npc("peek_npc_memories"))
	return BridgeNpcInspect.memories(_npc, npc_id)


## As relações do NPC (cópias, em ordem crescente do id da outra pessoa). Sem `npc`: BRIDGE_NO_NPC; inexistente: NPC_UNKNOWN.
func peek_npc_relations(npc_id: int) -> BridgeInspectReplies.NpcRelationsReply:
	if _npc == null:
		return BridgeInspectReplies.NpcRelationsReply.new(_missing_npc("peek_npc_relations"))
	return BridgeNpcInspect.relations(_npc, npc_id)


## COMANDO DE DEPURAÇÃO, a ÚNICA escrita da inspeção (decisão de Arthur, 09/11/2026): marca ou desmarca o NPC para o rastro de decisão. Repassa a
## `request_set_traced` do `npc` e devolve o `Result` dele como está: NPC_DEV_ONLY fora de build de desenvolvimento (e nada muda), NPC_UNKNOWN para NPC
## inexistente. Só mexe no sinalizador volátil de depuração: não é salvo e não entra no `state_hash`. Sem `npc`: BRIDGE_NO_NPC.
func request_set_npc_traced(npc_id: int, is_traced: bool) -> Result:
	if _npc == null:
		return _missing_npc("request_set_npc_traced")
	return _npc.request_set_traced(npc_id, is_traced)


# ---------------------------------------------------------------------------------------------------- Inspeção da economia (LW-108b)
# Consultas só de leitura para o painel econômico de depuração (docs/modules/bridge.md, "Inspeção da economia"; docs/modules/tools.md, "Painel econômico"). A conta fica em
# `BridgeEconomyInspect`; aqui só se confere a ponte sem jogo ou sem economia e se delega. Cada resposta traz cópias e nenhuma exige terreno nem `npc`. Nenhuma escrita.

## O dinheiro (em circulação, criado e destruído), os bens que já tiveram movimento, o livro-razão por motivo, a conferência de cada um e os problemas do `validate()` da economia.
## Sem jogo: BRIDGE_NO_GAME; sem economia: BRIDGE_NO_ECONOMY. [LIM] o custo do `validate()` da economia inteira é medido na LW-108b (relatório).
func peek_economy_overview() -> BridgeEconomyReplies.EconomyOverviewReply:
	var economy: EconomyModule = _economy()
	if economy == null:
		return BridgeEconomyReplies.EconomyOverviewReply.new(_missing_economy("peek_economy_overview"))
	return BridgeEconomyInspect.overview(economy)


## Os mercados (um por assentamento que tem), em ordem crescente de `market_id`: dinheiro da conta e, de cada bem, estoque, alvo, preço, compra, venda e escassez.
## Os assentamentos vêm dos locais que a ponte guarda. Sem jogo: BRIDGE_NO_GAME; sem economia: BRIDGE_NO_ECONOMY.
func peek_economy_markets() -> BridgeEconomyReplies.EconomyMarketsReply:
	var economy: EconomyModule = _economy()
	if economy == null:
		return BridgeEconomyReplies.EconomyMarketsReply.new(_missing_economy("peek_economy_markets"))
	return BridgeEconomyInspect.markets(economy, BridgeEconomyInspect.settlement_ids_of(_places))


## Os locais de produção, em ordem crescente de `site_id`: receita, ofício, equipe, se rodam e o motivo da parada. Sem jogo: BRIDGE_NO_GAME; sem economia: BRIDGE_NO_ECONOMY.
func peek_economy_sites() -> BridgeEconomyReplies.EconomySitesReply:
	var economy: EconomyModule = _economy()
	if economy == null:
		return BridgeEconomyReplies.EconomySitesReply.new(_missing_economy("peek_economy_sites"))
	return BridgeEconomyInspect.sites(economy, BridgeEconomyInspect.settlement_ids_of(_places))
