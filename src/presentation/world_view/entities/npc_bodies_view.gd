class_name NpcBodiesView
extends Node3D
## Os corpos dos NPCs em S0 (LW-072c). A cada quadro CONSULTA a ponte (`peek_npc_bodies`, sem sinal) e mantém um `NpcView` por NPC em S0 que não está em viagem, nem
## mais nem menos. As SAÍDAS vêm antes das ENTRADAS: o corpo de quem saiu (afastou-se ou morreu) volta à reserva antes de o próximo pegar um, e
## uma troca grande de uma vez (o jogador salta de um povoado a outro) nunca faz a reserva crescer. O corpo nasce na posição da ponte e fica
## ESCONDIDO enquanto o terreno do seu chunk não está desenhado (`TerrainView.has_chunk`). `setup` liga o interruptor de corpos da simulação e
## `release` o desliga; ponte que falha = nenhum corpo e interruptor desligado, até outro `setup`. O corpo fica parado onde nasceu (o andar é da
## LW-072d) e a cena ainda não cria a view (LW-072f). Contrato: docs/modules/presentation.md.
## CHEGADA SUAVE (LW-099h): com uma fonte de pontos de chegada (`set_arrival_spots`, a `take_arrival_spot` da vista das caravanas), o corpo do comerciante que acaba de chegar de viagem nasce na DOCA onde a caravana terminou, e não na posição da ponte (o centro do mercado), e o motorista o leva andando até o destino de sempre; ponto a menos de `MIN_ARRIVAL_GAP_M` da posição da ponte (o dado sem docas) ou a mais de `MAX_ARRIVAL_GAP_M` dela é ignorado (nasce na posição da ponte, como sempre). Só a apresentação muda.
## FIGURA INTEIRA (ART-12, 7b-2): com uma área de figuras (`CharacterArea`, não vazia) e uma fábrica (`figure_factory(figure_id) -> Node3D`), o NPC da área que ENTRA em S0 recebe a figura no corpo que acaba de sair da reserva (`NpcView.attach_figure`); fábrica que devolve null deixa a cápsula e dá UM aviso por NPC. Sair de S0 e o `release` devolvem a cápsula (o `give_back` do pool chama `detach`, que libera a figura); a reserva não guarda figura. Sem área, com área vazia ou sem fábrica a view é a de sempre.

## [HIP] Um ponto de chegada vale só se ficar a MAIS de tanto (m) da posição da ponte (menos que isso é o mesmo lugar, e o corpo nasce na posição da ponte, bit a bit como sempre) e a NO MÁXIMO tanto (m) dela (a doca fica a até 6 m do centro do mercado; mais longe que isto o corpo nunca nasce, para não ficar longe de onde a simulação põe o NPC).
const MIN_ARRIVAL_GAP_M: float = 0.25
const MAX_ARRIVAL_GAP_M: float = 15.0

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
## A fonte dos pontos de chegada: `(npc_id: int) -> Vector2` (x e z em metros; não finito = sem ponto). Inválida = nenhum ponto.
var _arrival_spots: Callable = Callable()


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
	for npc_id: int in _pool.active_ids():
		if not wanted.has(npc_id):
			_pool.give_back(npc_id)
	for body: BridgeReplies.NpcBodyReply in reply.bodies:
		if _pool.body_of(body.npc_id) == null:
			var entered: NpcView = _pool.take(body.npc_id, _birth_position(body))
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
	var switched: Result = _bridge.request_set_bodies_available(false)
	if not switched.ok:
		push_warning("NpcBodiesView.release: interruptor de corpos não desligado (%s): %s" % [switched.code, switched.message])


func is_active() -> bool:
	return _is_active


## Liga a fonte dos pontos de chegada (a cena passa a `take_arrival_spot` da `CaravanBodiesView`): `source.call(npc_id) -> Vector2` com x e z em metros, ou um vetor não finito se não há ponto. Chame DEPOIS de `setup` (ele a solta). Fonte inválida (ou nenhuma, o padrão) = todo corpo nasce na posição da ponte.
func set_arrival_spots(source: Callable) -> void:
	_arrival_spots = source


func has_arrival_spots() -> bool:
	return _arrival_spots.is_valid()


## IDs dos NPCs com corpo, em ordem crescente.
func active_ids() -> Array[int]:
	var ids: Array[int] = []
	if _pool != null:
		ids = _pool.active_ids()
	return ids


## A reserva de corpos (contadores de criados, retirados, devolvidos, pico, pool vazio e duplicados); nula antes de um `setup` que deu certo.
func pool() -> NpcViewPool:
	return _pool


func _process(_delta: float) -> void:
	reconcile()


func _exit_tree() -> void:
	release()


func _chunk_of(point: Vector3) -> Vector2i:
	return Vector2i(clampi(floori(point.x / _chunk_size_m), 0, _chunk_count.x - 1), clampi(floori(point.z / _chunk_size_m), 0, _chunk_count.y - 1))


## Onde o corpo que entra nasce: na posição da ponte, ou, se a fonte dá um ponto de chegada que vale (entre `MIN_ARRIVAL_GAP_M` e `MAX_ARRIVAL_GAP_M` da posição da ponte), nele, com os pés na altura do terreno ali. Altura ilegível ou resposta torta da fonte: a posição da ponte (a altura nunca é inventada).
func _birth_position(body: BridgeReplies.NpcBodyReply) -> Vector3:
	if not _arrival_spots.is_valid():
		return body.position
	# Variant na fronteira com o Callable: o tipo da resposta é conferido antes de usar.
	var answer: Variant = _arrival_spots.call(body.npc_id)
	if typeof(answer) != TYPE_VECTOR2:
		return body.position
	var spot: Vector2 = answer
	if not spot.is_finite():
		return body.position
	var gap_m: float = spot.distance_to(Vector2(body.position.x, body.position.z))
	if gap_m <= MIN_ARRIVAL_GAP_M or gap_m > MAX_ARRIVAL_GAP_M:
		return body.position
	var ground: BridgeReplies.HeightReply = _bridge.peek_height(spot.x, spot.y)
	if not ground.result.ok:
		return body.position
	return Vector3(spot.x, ground.height_m, spot.y)


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
	_arrival_spots = Callable()
	_warned_npcs.clear()
