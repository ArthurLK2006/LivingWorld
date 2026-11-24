class_name NpcBodiesView
extends Node3D
## Os corpos dos NPCs em S0 (LW-072c). A cada quadro CONSULTA a ponte (`peek_npc_bodies`, sem sinal) e mantém um `NpcView` por NPC em S0 que não está em viagem, nem
## mais nem menos. As SAÍDAS vêm antes das ENTRADAS: o corpo de quem saiu (afastou-se ou morreu) volta à reserva antes de o próximo pegar um, e
## uma troca grande de uma vez (o jogador salta de um povoado a outro) nunca faz a reserva crescer. O corpo nasce na posição da ponte e fica
## ESCONDIDO enquanto o terreno do seu chunk não está desenhado (`TerrainView.has_chunk`). `setup` liga o interruptor de corpos da simulação e
## `release` o desliga; ponte que falha = nenhum corpo e interruptor desligado, até outro `setup`. O corpo fica parado onde nasceu (o andar é da
## LW-072d) e a cena ainda não cria a view (LW-072f). Contrato: docs/modules/presentation.md.
## FIGURA INTEIRA (ART-12, 7b-2): com uma área de figuras (`CharacterArea`, não vazia) e uma fábrica (`figure_factory(figure_id) -> Node3D`), o NPC da área que ENTRA em S0 recebe a figura no corpo que acaba de sair da reserva (`NpcView.attach_figure`); fábrica que devolve null deixa a cápsula e dá UM aviso por NPC. Sair de S0 e o `release` devolvem a cápsula (o `give_back` do pool chama `detach`, que libera a figura); a reserva não guarda figura. Sem área, com área vazia ou sem fábrica a view é a de sempre.
## DESPEDIDA (LW-099d, opção A de Arthur em 24/11/2026; só apresentação; DESLIGADA por padrão): com `set_departure_fade(true)`, o NPC que sai de `peek_npc_bodies` POR TER CARAVANA (a partida do comerciante) NÃO volta à reserva na hora: o corpo fica ONDE ESTÁ por
## `PresenceFade.DURATION_S` (0,4 s de tempo real, avançado pelo `_process` e por `advance_departures(delta)`), cada vez mais transparente (`NpcView.set_fade`), enquanto a `CaravanView` surge no ponto de saída: uma dissolução cruzada em vez do "pulo". É a EXCEÇÃO
## DELIBERADA à regra "o NPC em viagem não tem corpo" (o filtro da ponte segue valendo: a consulta nunca o lista); durante a despedida o corpo conta em `active_ids()` (também em `fading_ids()` e `is_departing`), no laço de visibilidade por chunk e na reserva (não é devolvido antes), mas NÃO é interativo (a `InteractionView` o ignora).
## Quem sai por OUTRO motivo (alcance, morte) volta NA HORA, como sempre: a reserva nunca cresce numa troca grande. Como saber o motivo: só quando alguém fica sem lugar na lista há UMA consulta `peek_caravan_bodies` por quadro (o `trader_id` de cada linha, em
## viagem ou parada, é o id do NPC); quem já está em despedida não consulta de novo, e consulta que falha manda todos de volta na hora. Se o NPC volta à lista durante a despedida, ela é cancelada e o corpo volta opaco. `release`, `setup` e o desligar da opção
## encerram as despedidas (os corpos voltam à reserva, opacos). Desligada, nada disto existe e a view é a de sempre: nenhuma consulta a mais.

var _bridge: SimBridge
var _terrain: TerrainView
var _pool: NpcViewPool
var _chunk_size_m: float = 0.0
var _chunk_count: Vector2i = Vector2i.ZERO
var _is_active: bool = false
## A área das figuras (null = nenhuma: vazia ou sem fábrica), a fábrica e os NPCs cuja figura falhou e já foram avisados.
var _area: CharacterArea
var _figure_factory: Callable
## O DONO da fábrica: um `Callable` de método de um `RefCounted` (a `source.make` da cena) NÃO segura o objeto, e a fonte, local na cena, morreria ao fim do preparo com a fábrica já inválida. Quem a segura é esta view, até o próximo `setup`.
var _figure_owner: RefCounted
var _warned_npcs: Dictionary[int, bool] = {}
## A despedida (LW-099d): a opção (desligada por padrão; sobrevive ao `setup`), os NPCs em despedida (id -> segundos desde o começo) e duas listas reaproveitadas (quem saiu neste quadro e quem terminou a despedida).
var _departure_fade: bool = false
var _departing: Dictionary[int, float] = {}
var _leavers: Array[int] = []
var _finished: Array[int] = []


## Liga a view à ponte e ao terreno, cria a reserva de corpos e liga o interruptor de corpos da simulação. Ponte ou terreno nulo, ponte sem
## terreno ou interruptor recusado: push_error, nenhum corpo e a view fica inativa (devolve falso). `area` e `figure_factory` são opcionais (ver o cabeçalho): só valem juntos, com área não vazia e fábrica válida.
func setup(bridge: SimBridge, terrain: TerrainView, area: CharacterArea = null, figure_factory: Callable = Callable()) -> bool:
	_clear()
	if bridge == null or terrain == null:
		push_error("NpcBodiesView.setup: ponte ou TerrainView nulo; esperado os dois.")
		return false
	var layout: BridgeReplies.TerrainLayoutReply = bridge.peek_terrain_layout()
	if not layout.result.ok:
		return _fail("formato do terreno indisponível", layout.result)
	var switched: Result = bridge.request_set_bodies_available(true)
	if not switched.ok:
		return _fail("interruptor de corpos recusado", switched)
	_bridge = bridge
	_terrain = terrain
	_chunk_size_m = float(layout.chunk_cells) * layout.cell_size_m
	_chunk_count = layout.chunk_count
	_pool = NpcViewPool.new(self)
	_area = area if area != null and not area.is_empty() and figure_factory.is_valid() else null
	_figure_factory = figure_factory
	_figure_owner = figure_factory.get_object() as RefCounted
	_is_active = true
	return true


## Põe os corpos em dia com a simulação: devolve os de quem saiu de S0, entrega os de quem entrou (na posição de nascimento) e mostra só os
## que têm terreno desenhado. Falha da ponte: push_error e `release`.
func reconcile() -> void:
	if not _is_active:
		return
	var reply: BridgeReplies.NpcBodiesReply = _bridge.peek_npc_bodies()
	if not reply.result.ok:
		push_error("NpcBodiesView.reconcile: corpos indisponíveis (%s): %s Os corpos saem e o interruptor é desligado." % [reply.result.code, reply.result.message])
		release()
		return
	var wanted: Dictionary[int, bool] = {}
	for body: BridgeReplies.NpcBodyReply in reply.bodies:
		wanted[body.npc_id] = true
	_send_off_leavers(wanted)
	for body: BridgeReplies.NpcBodyReply in reply.bodies:
		if _pool.body_of(body.npc_id) == null:
			var entered: NpcView = _pool.take(body.npc_id, body.position)
			if entered != null and _area != null:
				_attach_figure_of(entered, body.npc_id)
	for npc_id: int in _pool.active_ids():
		var view: NpcView = _pool.body_of(npc_id)
		view.visible = _terrain.has_chunk(_chunk_of(view.position))


## Devolve todos os corpos e desliga o interruptor de corpos da simulação (o `npc` solta todos de S0). Não faz nada se a view está inativa.
func release() -> void:
	if not _is_active:
		return
	_is_active = false
	for npc_id: int in _pool.active_ids():
		_pool.give_back(npc_id)
	_departing.clear()
	var switched: Result = _bridge.request_set_bodies_available(false)
	if not switched.ok:
		push_warning("NpcBodiesView.release: interruptor de corpos não desligado (%s): %s" % [switched.code, switched.message])


func is_active() -> bool:
	return _is_active


## IDs dos NPCs com corpo, em ordem crescente.
func active_ids() -> Array[int]:
	var ids: Array[int] = []
	if _pool != null:
		ids = _pool.active_ids()
	return ids


## A reserva de corpos (contadores de criados, retirados, devolvidos, pico, pool vazio e duplicados); nula antes de um `setup` que deu certo.
func pool() -> NpcViewPool:
	return _pool


## Liga ou desliga a DESPEDIDA da partida da caravana (ver o cabeçalho); nasce DESLIGADA e sobrevive ao `setup`. Desligar encerra já as despedidas em curso (os corpos voltam à reserva, opacos).
func set_departure_fade(enabled: bool) -> void:
	_departure_fade = enabled
	if not enabled:
		_end_departures()


func departure_fade_enabled() -> bool:
	return _departure_fade


## IDs dos NPCs em despedida (o corpo ainda na tela, sumindo), em ordem crescente; eles também estão em `active_ids()`.
func fading_ids() -> Array[int]:
	var ids: Array[int] = []
	ids.assign(_departing.keys())
	ids.sort()
	return ids


## Se o NPC está em despedida (o corpo ainda na tela, sumindo): consulta O(1) no dicionário, sem alocar. O corpo em despedida NÃO é interativo: a `InteractionView` o ignora ao escolher o alvo.
func is_departing(npc_id: int) -> bool:
	return _departing.has(npc_id)


## Avança as despedidas em `delta` segundos de tempo REAL: cada corpo fica mais transparente (`PresenceFade.out_amount`) e, ao completar `PresenceFade.DURATION_S`, volta à reserva (opaco e escondido). Sem despedida, ou com `delta` NaN, não faz nada;
## `delta` negativo conta como 0.
func advance_departures(delta: float) -> void:
	if _departing.is_empty() or is_nan(delta):
		return
	_finished.clear()
	for npc_id: int in _departing:
		var view: NpcView = _pool.body_of(npc_id)
		var elapsed_s: float = _departing[npc_id] + maxf(delta, 0.0)
		_departing[npc_id] = elapsed_s
		if view == null or elapsed_s >= PresenceFade.DURATION_S:
			_finished.append(npc_id)
		else:
			view.set_fade(PresenceFade.out_amount(elapsed_s))
	for npc_id: int in _finished:
		_departing.erase(npc_id)
		_pool.give_back(npc_id)
	_finished.clear()


func _process(delta: float) -> void:
	reconcile()
	advance_departures(delta)


func _exit_tree() -> void:
	release()


func _chunk_of(point: Vector3) -> Vector2i:
	return Vector2i(clampi(floori(point.x / _chunk_size_m), 0, _chunk_count.x - 1), clampi(floori(point.z / _chunk_size_m), 0, _chunk_count.y - 1))


## As SAÍDAS do quadro: quem tem corpo e não está na lista `wanted` volta à reserva na hora, MENOS quem saiu por ter caravana com a despedida ligada (começa a sumir, no lugar onde está); quem está em despedida e voltou à lista tem a despedida cancelada.
## Só se alguém saiu e a despedida está ligada é que há UMA consulta das caravanas; quem já está em despedida não entra na conta.
func _send_off_leavers(wanted: Dictionary[int, bool]) -> void:
	_leavers.clear()
	for npc_id: int in _pool.active_ids():
		if wanted.has(npc_id):
			if _departing.has(npc_id):
				_cancel_departure(npc_id)
		elif not _departing.has(npc_id):
			_leavers.append(npc_id)
	if _leavers.is_empty():
		return
	var travelling: Dictionary[int, bool] = {}
	if _departure_fade:
		travelling = _caravan_traders()
	for npc_id: int in _leavers:
		if travelling.has(npc_id):
			_departing[npc_id] = 0.0
		else:
			_pool.give_back(npc_id)
	_leavers.clear()


## Os comerciantes com caravana agora (em viagem ou parada: o `trader_id` das linhas é o id do NPC). Consulta que falha: ninguém (todo mundo volta na hora, como sem a despedida).
func _caravan_traders() -> Dictionary[int, bool]:
	var traders: Dictionary[int, bool] = {}
	var reply: BridgeReplies.CaravanBodiesReply = _bridge.peek_caravan_bodies()
	if reply.result.ok:
		for row: BridgeReplies.CaravanBodyReply in reply.bodies:
			traders[row.trader_id] = true
	return traders


## O NPC voltou à lista durante a despedida: ela acaba e o corpo volta a ficar opaco, onde estava.
func _cancel_departure(npc_id: int) -> void:
	_departing.erase(npc_id)
	_pool.body_of(npc_id).set_fade(PresenceFade.OPAQUE)


## Encerra todas as despedidas: os corpos voltam à reserva (opacos e escondidos).
func _end_departures() -> void:
	if _pool != null:
		for npc_id: int in _departing.keys():
			_pool.give_back(npc_id)
	_departing.clear()


## Põe no corpo que acaba de entrar a figura que a área dá a esse NPC (se ele está nela). Fábrica que devolve null: o corpo segue cápsula e o NPC recebe UM aviso, nunca um por quadro (nem a cada reentrada em S0).
func _attach_figure_of(view: NpcView, npc_id: int) -> void:
	var figure_id: String = _area.figure_for(npc_id)
	if figure_id.is_empty():
		return
	var figure: Node3D = _figure_factory.call(figure_id) as Node3D
	if figure != null:
		view.attach_figure(figure)
	elif not _warned_npcs.has(npc_id):
		_warned_npcs[npc_id] = true
		push_warning("NpcBodiesView: o NPC %d segue cápsula: a fábrica não devolveu a figura '%s'." % [npc_id, figure_id])


func _fail(what: String, failure: Result) -> bool:
	push_error("NpcBodiesView.setup: %s (%s): %s" % [what, failure.code, failure.message])
	return false


## Solta a reserva antiga (os corpos são filhos desta view) e deixa a view inativa.
func _clear() -> void:
	release()
	for child: Node in get_children():
		remove_child(child)
		child.free()
	_pool = null
	_area = null
	_figure_factory = Callable()
	_figure_owner = null
	_warned_npcs.clear()
	_departing.clear()
