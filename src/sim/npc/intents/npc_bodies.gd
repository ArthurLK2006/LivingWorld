class_name NpcBodies
extends RefCounted
## Corpos dos NPCs (LW-069, LW-070 a LW-070d; docs/modules/npc.md, seção 6): o LOD lógico, o quadro de Intents, o interruptor de corpos, o relato do
## resultado do corpo e a espera do corpo atrasado. LW-081a (passo 1): o código saiu do `NpcModule` sem mudar de comportamento; o módulo segue sendo
## a única porta (`request_*` e `peek_*`) e só delega aqui. O LOD e o quadro de Intents continuam sendo os do módulo (ele os expõe como `lod` e `intents`);
## a classe os recebe prontos, junto com a tabela de NPCs (a mesma, por referência). Sem estado global, sem aleatoriedade e sem relógio fora do core.

var _lod: NpcLod
var _intents: NpcIntentBoard
var _npcs: Dictionary[int, NpcState]
var _ctx: SimContext
## Interruptor de corpos (LW-070b): só a apresentação sabe se existem corpos para os NPCs. Sem eles, um NPC perto do jogador esperaria para sempre um
## resultado que ninguém dá, e o mundo passaria a mudar só porque o jogador olhou. Com os corpos INDISPONÍVEIS o LOD fica inerte (ninguém entra em S0,
## nenhum LodChanged sai, nenhuma ação nasce com Intent, `peek_pending_intents` fica vazio) e o hash do mundo não depende do foco. É estado SÓ de memória:
## não é salvo nem entra no hash. O LOD que vem das `Definitions` (o jogo) nasce SEM corpos, e a apresentação (LW-072) o liga; um módulo montado à mão, sem
## `Definitions` (os bancos de ensaio do LOD e do protocolo, onde o teste faz o papel da apresentação), nasce com corpos, como era antes.
var _bodies_available: bool = true


func _init(lod: NpcLod, intents: NpcIntentBoard, npcs: Dictionary[int, NpcState]) -> void:
	_lod = lod
	_intents = intents
	_npcs = npcs


## Passou o `setup` do módulo: guarda o contexto e liga o LOD com os parâmetros das definições (nulos = LOD desligado, como nos testes que montam o módulo
## sem elas). Fica no `setup` e não no ponto do pensador porque o primeiro relato de posição do jogador chega ANTES do primeiro passo (o pensador só é
## montado no primeiro `tick`) e o foco falharia com NPC_LOD_NOT_CONFIGURED.
func setup(ctx: SimContext, lod_params: LodParams) -> void:
	_ctx = ctx
	if lod_params == null:
		return
	# LW-070b: o LOD do jogo nasce SEM corpos; só a apresentação sabe se eles existem (request_set_bodies_available).
	_bodies_available = false
	var linked: Result = _lod.configure(lod_params)
	if not linked.ok:
		push_error("NpcModule.setup: LOD não ligado: %s" % linked.message)


func is_available() -> bool:
	return _bodies_available


## O NPC começa a ação com corpo? Sim se há corpos, o protocolo de Intents está ligado e o LOD o pôs em S0 (usado por `_start_action`).
func is_embodied(npc_id: int) -> bool:
	return _bodies_available and _intents.is_configured() and _lod.level_of(npc_id) == NpcLod.LEVEL_S0


## Liga ou desliga os corpos. Desligar tira TODOS de S0 pelo mesmo caminho de quem se afasta (um LodChanged por NPC), solta os Intents pendentes e deixa
## cada ação seguir abstrata com o tempo que falta; os focos ficam guardados. Repetir o estado atual não faz nada. Módulo sem `setup()`: NPC_NOT_READY.
func set_available(available: bool) -> Result:
	if _ctx == null:
		return Result.failure(NpcModule.CODE_NOT_READY, "NpcModule.request_set_bodies_available: módulo sem setup() (sem relógio nem barramento de eventos); esperado um módulo registrado no World.")
	if available == _bodies_available:
		return Result.success()
	_bodies_available = available
	if not available:
		var now: int = _ctx.clock.total_minutes()
		_publish_lod_changes(_lod.release_all(_npcs, now))
		_intents.expire(now)
	return Result.success()


## LW-070a: liga o protocolo de Intents ao MESMO `ActionRunner` do pensador (nunca a um segundo: um só caminho de efeitos). Sem parâmetros de Intent
## nas definições nenhuma ação nasce com Intent. Texto vazio = ligou (ou não havia o que ligar); senão, o motivo.
func link_intents(runner: ActionRunner, places: SettlementService, params: NpcIntentParams) -> String:
	if params == null:
		return ""
	var linked: Result = _intents.configure(runner, _npcs, places, params)
	return "" if linked.ok else "Intents (modo S0): %s" % linked.message


## Resultado que a apresentação devolve de um Intent (pela ponte). Sucesso só MARCA o fim da ação e acorda o NPC: os efeitos entram no pensamento
## seguinte, pela função única do runner (LW-070d); BLOCKED e CANCELLED cancelam a ação na hora, sem efeito; resultado de ação velha é descartado
## e contado (NPC_RESULT_STALE).
func report_result(result: NpcActionResult) -> Result:
	if _ctx == null:
		return Result.failure(NpcModule.CODE_NOT_READY, "NpcModule.request_report_npc_result: módulo sem setup() (sem relógio); esperado um módulo registrado no World.")
	var now: int = _ctx.clock.total_minutes()
	var npc_id: int = result.npc_id if result != null else IdGenerator.NO_ID
	var was_embodied: bool = _intents.has_pending(npc_id)
	var reported: Result = _intents.report_result(result, now)
	# LW-070a: o Intent acabou (sucesso, BLOCKED ou CANCELLED): o NPC volta a pensar no minuto seguinte, no máximo. Resultado descartado ou
	# recusado não mexe em nada.
	if was_embodied and not _intents.has_pending(npc_id):
		_wake_thinking(npc_id, now)
	return reported


## LOD e Intents de cada passo (LW-069 e LW-070), chamados pelo começo do `tick` do módulo: reclassifica os NPCs (S1 e S0), publica LodChanged só nas
## trocas e vence os Intents sem resultado. NÃO depende de `Definitions` (os testes do LOD montam o módulo sem elas). Com os corpos indisponíveis
## (LW-070b) não faz nada: o LOD inerte não gasta nem ID de evento. Devolve os NPCs cujo Intent venceu por tempo neste passo (em ordem crescente de ID; a ação
## deles já foi cancelada): o detector de impasse (LW-073b) os lê.
func tick() -> Array[int]:
	var expired: Array[int] = []
	if _ctx == null or not _bodies_available:
		return expired
	var now: int = _ctx.clock.total_minutes()
	_publish_lod_changes(_lod.update(_npcs, now))
	# LW-070: depois da reclassificação, vence os Intents sem resultado e solta os de quem saiu de S0.
	expired = _intents.expire(now)
	_hold_embodied_thinking(now)
	return expired


## Tira UM NPC de S0 (LW-073b, o detector de impasse): o corpo volta ao pool pelo mesmo `LodChanged` de quem se afasta, e o NPC volta a S0 no passo seguinte se
## ainda estiver perto do foco. Sem efeito se ele não está em S0.
func release_body(npc_id: int) -> void:
	if _ctx == null:
		return
	_publish_lod_changes(_lod.release(_npcs, npc_id, _ctx.clock.total_minutes()))


func _publish_lod_changes(changes: Array[NpcLod.Change]) -> void:
	for change: NpcLod.Change in changes:
		_ctx.events.publish(LodChanged.new(change.npc_id, change.from_level, change.to_level))


## LW-070b (antes, LW-070a: o NPC com Intent pendente nunca pensava): o NPC com corpo PENSA como qualquer outro enquanto a ação está dentro do
## tempo previsto, para reavaliar por necessidade urgente ou crítica, alarme, fim do bloco da rotina e morte (o `EmbodiedActionRunner` faz o
## pensador respeitar o corpo: o tempo não encerra a ação e trocá-la é cancelá-la). Passado o FIM PREVISTO o corpo está atrasado: aí o NPC só
## espera o resultado ou o tempo limite do Intent, e o próximo pensamento dele fica no minuto seguinte (o pensador encerraria a ação pelo
## relógio, ou a trocaria por uma de quem ainda não chegou). Quando o Intent acaba, ele já está no ponto de pensar: por resultado,
## `report_result` o acorda; por tempo limite ou saída de S0, `expire` (acima) o libera e ele pensa neste mesmo passo, porque o pensador roda depois.
func _hold_embodied_thinking(now: int) -> void:
	for npc_id: int in _intents.pending_ids():
		var state: NpcState = _npcs.get(npc_id)
		if state != null and state.action_ends_at <= now:
			state.next_think_time = now + 1


## LW-070a: o Intent do NPC acabou por resultado; ele volta a pensar no minuto seguinte, no máximo.
func _wake_thinking(npc_id: int, now: int) -> void:
	var state: NpcState = _npcs.get(npc_id)
	if state != null:
		state.next_think_time = mini(state.next_think_time, now + 1)
