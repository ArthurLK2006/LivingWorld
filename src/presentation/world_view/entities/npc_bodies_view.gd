class_name NpcBodiesView
extends Node3D
## Os corpos dos NPCs em S0 (LW-072c). A cada quadro CONSULTA a ponte (`peek_npc_bodies`, sem sinal) e mantém um `NpcView` por NPC em S0, nem
## mais nem menos. As SAÍDAS vêm antes das ENTRADAS: o corpo de quem saiu (afastou-se ou morreu) volta à reserva antes de o próximo pegar um, e
## uma troca grande de uma vez (o jogador salta de um povoado a outro) nunca faz a reserva crescer. O corpo nasce na posição da ponte e fica
## ESCONDIDO enquanto o terreno do seu chunk não está desenhado (`TerrainView.has_chunk`). `setup` liga o interruptor de corpos da simulação e
## `release` o desliga; ponte que falha = nenhum corpo e interruptor desligado, até outro `setup`. O corpo fica parado onde nasceu (o andar é da
## LW-072d) e a cena ainda não cria a view (LW-072f). Contrato: docs/modules/presentation.md.

var _bridge: SimBridge
var _terrain: TerrainView
var _pool: NpcViewPool
var _chunk_size_m: float = 0.0
var _chunk_count: Vector2i = Vector2i.ZERO
var _is_active: bool = false


## Liga a view à ponte e ao terreno, cria a reserva de corpos e liga o interruptor de corpos da simulação. Ponte ou terreno nulo, ponte sem
## terreno ou interruptor recusado: push_error, nenhum corpo e a view fica inativa (devolve falso).
func setup(bridge: SimBridge, terrain: TerrainView) -> bool:
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
			_pool.take(body.npc_id, body.position)
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
