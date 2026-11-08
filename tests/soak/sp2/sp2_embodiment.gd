class_name Sp2Embodiment
extends RefCounted
## LW-071 (SP2, DESCARTÁVEL): liga os corpos aos Intents (o papel da apresentação na arquitetura 6.2). Ao entrar em S0 o corpo sai do pool
## na posição reconstruída (NpcLod); ao sair, volta ao pool (o LOD já levou o último relato para a posição lógica). A cada quadro: pega os
## Intents pendentes, calcula a rota (N1 ou N2) e anda pela política de velocidade (P1 ou P2); chegada vira ARRIVED, ação no local vira
## DONE quando o relógio passa do fim previsto, rota impossível vira BLOCKED. Posições em lote a cada 6 quadros de física. Não aplica
## efeito nenhum: só devolve o resultado ao módulo.

var policy: Sp2SpeedPolicy.Policy = Sp2SpeedPolicy.Policy.P1_NATURAL
var nav_kind: Sp2Nav.Kind = Sp2Nav.Kind.N1_STRAIGHT
var pool: Sp2BodyPool
var checker: Sp2Checker = Sp2Checker.new()
var nav: Sp2Nav
var are_numbers_shown: bool = false
## Contadores de resultados e de medição.
var arrived: int = 0
var done: int = 0
var blocked: int = 0
var stale: int = 0
var refused: int = 0
var intents_lost: int = 0
var late_arrivals: int = 0
var ceiling_short: int = 0
var inherited_actions: int = 0
var route_count: int = 0
var route_usec_total: int = 0
var route_usec_worst: int = 0
var walked_m: float = 0.0
var walking_seconds: float = 0.0
var ratio_sum: float = 0.0
var ratio_count: int = 0
var body_usec_total: int = 0
var body_frames: int = 0
var body_usec_worst: int = 0

var _world: Sp2World
var _parent: Node
var _physics_frames: int = 0


func _init(world: Sp2World, parent: Node) -> void:
	_world = world
	_parent = parent
	pool = Sp2BodyPool.new(parent)
	nav = Sp2Nav.new(world.terrain)


## Troca o mundo (ensaio de carga com outra população): devolve todos os corpos antes.
func swap_world(world: Sp2World) -> void:
	for npc_id: int in pool.active_ids():
		pool.give_back(npc_id)
		checker.forget(npc_id)
	_world = world


## Cria e devolve corpos conforme as trocas de LOD do passo. Primeiro as saídas, depois as entradas: o pico de corpos ativos não passa
## do limite de S0 quando um NPC perde a vaga para outro no mesmo passo.
func apply_lod_changes(changes: Array[LodChanged]) -> void:
	for pass_level: int in [NpcLod.LEVEL_S1, NpcLod.LEVEL_S0]:
		for change: LodChanged in changes:
			if change.to_level == pass_level:
				_apply_change(change)


func _apply_change(change: LodChanged) -> void:
	if change.to_level == NpcLod.LEVEL_S0:
		var spot: Vector2i = _world.module.lod.position_of(change.npc_id)
		var at: Vector3 = _ground(Vector2(spot) / TerrainData.CM_PER_METER)
		var body: Sp2Body = pool.take(change.npc_id, at)
		if body != null:
			body.show_number(are_numbers_shown)
			checker.on_spawn(change.npc_id, at, spot, _world.now())
	else:
		var leaving: Sp2Body = pool.body_of(change.npc_id)
		if leaving != null:
			var logical: Vector2i = _world.exit_position_of(change.npc_id)
			if logical == LodReconstruction.NO_POSITION:
				# NPC removido: não há posição lógica para conferir.
				checker.forget(change.npc_id)
			else:
				checker.on_return(change.npc_id, leaving, logical, _world.now())
			pool.give_back(change.npc_id)


## Entrega aos corpos os Intents novos e solta os que sumiram (tempo limite ou NPC fora de S0).
func sync_intents(clock_speed: int) -> void:
	var pending: Dictionary[int, NpcIntent] = {}
	for intent: NpcIntent in _world.module.peek_pending_intents():
		pending[intent.npc_id] = intent
	for npc_id: int in pool.active_ids():
		var body: Sp2Body = pool.body_of(npc_id)
		var intent: NpcIntent = pending.get(npc_id) as NpcIntent
		if intent == null:
			if body.has_intent():
				intents_lost += 1
				body.clear_intent()
			_follow_inherited(body)
		elif intent.action_serial != body.action_serial:
			_assign(body, intent, clock_speed)


## Um quadro de física: anda, relata resultados e, a cada 6 quadros, as posições em lote.
func physics_step(delta: float, clock_speed: int, is_paused: bool) -> void:
	var start_us: int = Time.get_ticks_usec()
	var now: int = _world.now()
	var max_speed: float = Sp2SpeedPolicy.max_speed_mps(policy, clock_speed)
	for npc_id: int in pool.active_ids():
		var body: Sp2Body = pool.body_of(npc_id)
		if not is_paused:
			_step_body(body, delta, clock_speed, now)
		checker.on_moved(npc_id, body.position, delta, max_speed, now)
	_physics_frames += 1
	if not is_paused and _physics_frames % Sp2Constants.REPORT_EVERY_PHYSICS_FRAMES == 0:
		_report_positions()
	body_usec_total += Time.get_ticks_usec() - start_us
	body_usec_worst = maxi(body_usec_worst, Time.get_ticks_usec() - start_us)
	body_frames += 1


func check_invariants() -> void:
	var bodies: Array[Sp2Body] = []
	for child: Node in _parent.get_children():
		if child is Sp2Body:
			bodies.append(child as Sp2Body)
	checker.check(_world.module.lod.s0_ids(), pool, bodies, _world.now())


func set_numbers_shown(is_shown: bool) -> void:
	are_numbers_shown = is_shown
	pool.show_numbers(is_shown)


func summary() -> String:
	var mean_route_ms: float = float(route_usec_total) / 1000.0 / float(maxi(route_count, 1))
	return "chegadas %d, feitas %d, bloqueadas %d, descartadas (velhas) %d, recusadas %d, Intents sumidos %d, atrasadas %d, teto curto %d, ações herdadas %d | rotas %d (média %.3f ms, pior %.3f ms) | velocidade vista %.2f m/s | tempo levado/previsto %.2f | custo dos corpos %.1f µs por quadro de física (pior %.2f ms)" % [
		arrived, done, blocked, stale, refused, intents_lost, late_arrivals, ceiling_short, inherited_actions, route_count, mean_route_ms, float(route_usec_worst) / 1000.0,
		walked_m / maxf(walking_seconds, 0.001), ratio_sum / float(maxi(ratio_count, 1)), float(body_usec_total) / float(maxi(body_frames, 1)), float(body_usec_worst) / 1000.0]


func _assign(body: Sp2Body, intent: NpcIntent, clock_speed: int) -> void:
	var query: NpcModule.NpcQuery = _world.module.peek_npc(intent.npc_id)
	body.action_serial = intent.action_serial
	body.kind = intent.kind
	body.ends_at = query.action_ends_at
	body.received_at = _world.now()
	body.expected_minutes = intent.expected_minutes
	var destination: Vector2 = Vector2(intent.destination_cm) / TerrainData.CM_PER_METER
	body.path = PackedVector2Array()
	body.path_index = 0
	if body.flat_position().distance_to(destination) > Sp2Constants.ARRIVE_TOLERANCE_M:
		body.path = nav.route(nav_kind, body.flat_position(), destination)
		route_count += 1
		route_usec_total += nav.last_route_usec
		route_usec_worst = maxi(route_usec_worst, nav.last_route_usec)
		if body.path.is_empty():
			_send(body, NpcActionResult.Outcome.BLOCKED)
			return
	if policy == Sp2SpeedPolicy.Policy.P2_FROM_CLOCK and body.kind == NpcIntent.Kind.MOVE_TO_PLACE:
		if Sp2SpeedPolicy.is_ceiling_short(body.remaining_m(), float(body.ends_at - body.received_at), clock_speed):
			ceiling_short += 1
	body.set_state(Sp2Body.State.WALKING if not body.path.is_empty() else Sp2Body.State.ACTING)


## NPC em S0 com ação abstrata herdada (entrou em S0 no meio dela; contrato LW-070, limitação 4): o corpo anda até o destino dela só
## para não ficar parado; quem termina a ação é o runner abstrato.
func _follow_inherited(body: Sp2Body) -> void:
	if body.state != Sp2Body.State.IDLE or not body.path.is_empty():
		return
	var query: NpcModule.NpcQuery = _world.module.peek_npc(body.npc_id)
	if query.action_id != ActionRunner.GO_TO_PLACE_ID or query.place_id == query.action_target_place_id:
		return
	var found: SettlementService.PlaceQuery = _world.places.peek_place(query.action_target_place_id)
	if not found.result.ok:
		return
	inherited_actions += 1
	body.path = nav.route(nav_kind, body.flat_position(), Vector2(found.place.position.x, found.place.position.z))
	body.path_index = 0
	body.ends_at = query.action_ends_at
	body.received_at = _world.now()


func _step_body(body: Sp2Body, delta: float, clock_speed: int, now: int) -> void:
	if body.path_index < body.path.size():
		var remaining: float = body.remaining_m()
		var speed: float = Sp2SpeedPolicy.speed_mps(policy, remaining, float(body.ends_at - now), clock_speed, false)
		var before: Vector3 = body.position
		var reached: bool = body.walk(speed * delta, _height_of)
		walked_m += Vector2(before.x, before.z).distance_to(body.flat_position())
		walking_seconds += delta
		if not reached:
			return
		if not body.has_intent():
			body.path = PackedVector2Array()
			body.path_index = 0
			return
		if body.kind == NpcIntent.Kind.MOVE_TO_PLACE:
			_send(body, NpcActionResult.Outcome.ARRIVED)
			return
		body.set_state(Sp2Body.State.ACTING)
	if body.has_intent() and body.kind == NpcIntent.Kind.ACT_AT_PLACE and now >= body.ends_at:
		_send(body, NpcActionResult.Outcome.DONE)


func _send(body: Sp2Body, outcome: NpcActionResult.Outcome) -> void:
	var now: int = _world.now()
	var outcome_result: Result = _world.module.request_report_npc_result(NpcActionResult.new(body.npc_id, body.action_serial, outcome, body.position))
	if outcome_result.ok:
		body.last_reported = body.position
		body.has_reported = true
		match outcome:
			NpcActionResult.Outcome.ARRIVED:
				arrived += 1
				late_arrivals += 1 if now > body.ends_at else 0
				ratio_sum += float(now - body.received_at) / float(maxi(body.expected_minutes, 1))
				ratio_count += 1
			NpcActionResult.Outcome.DONE:
				done += 1
			NpcActionResult.Outcome.BLOCKED:
				blocked += 1
	elif outcome_result.code == NpcIntentBoard.CODE_STALE_RESULT:
		stale += 1
	else:
		refused += 1
	body.clear_intent()


func _report_positions() -> void:
	var batch: Dictionary[int, Vector3] = {}
	for npc_id: int in pool.active_ids():
		batch[npc_id] = pool.body_of(npc_id).position
	if batch.is_empty():
		return
	_world.module.request_report_npc_positions(batch)
	for npc_id: int in batch:
		var body: Sp2Body = pool.body_of(npc_id)
		body.last_reported = batch[npc_id]
		body.has_reported = true


func _ground(flat: Vector2) -> Vector3:
	return Vector3(flat.x, _height_of(flat), flat.y)


func _height_of(flat: Vector2) -> float:
	return nav.height_m(flat)
