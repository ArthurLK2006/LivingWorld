class_name NpcBodiesTwin
extends RefCounted
## LW-072h: os corpos contra o gêmeo sem corpos, sem janela (método em tests/soak/README.md; os números vão no relatório da tarefa). Monta o MESMO jogo (dados reais,
## 100 NPCs, mesma semente, jogador parado no centro de A) em três modos: SOLO (nada em volta, só `run_steps`), GEMEO (S1: corpos desligados, amostrado a cada
## minuto) e CORPOS (S0: `NpcBodiesView` e `NpcBodyDriver`, os 50 mais perto com corpo andando a 4 m/s vezes a velocidade do relógio, como será na LW-072f). A cada
## minuto amostra os 100 NPCs só por consultas e, quando o contador de ações de um muda, diz como a anterior terminou. Usa o relógio do sistema só para o tempo de parede.

enum Mode { SOLO, GEMEO, CORPOS }

const DATA_DIR: String = "res://data"
const AT_A_M: Vector3 = Vector3(320.0, 10.0, 540.0)
## Um minuto de jogo dura 1,25 s reais a 1x: 75 quadros de física a 60 Hz, e 75 / velocidade nas outras.
const FRAMES_PER_MINUTE_AT_1X: float = 75.0
const PHYSICS_DELTA: float = 1.0 / 60.0
const DAY: int = SimClock.MINUTES_PER_DAY
## Quantos NPCs de A (os primeiros por ID) viram notáveis (T2) no começo, nos três mundos: só eles têm memória e relações (data/npc_params.json: teto 40).
const NOTABLES: int = 40
const REST: int = 1


## Resultado de uma execução. `count`: "causa:ação" (canceladas), "efeito:causa:ação" (o `rest` aplicado pelo sono cancelado) e contadores avulsos.
class Run:
	extends RefCounted

	var minutes: int = 0
	var wall_ms: int = 0
	var state_hash: String = ""
	var problems: Array[String] = []
	var count: Dictionary[String, int] = {}
	var walks_late: Array[float] = []
	var walks_ok: Array[float] = []
	var needs: Dictionary[int, PackedInt64Array] = {}
	var exposed: Dictionary[int, bool] = {}
	var memory_by_day: Array[int] = []
	var relations: int = 0
	var relation_sum: int = 0

	func add(key: String, amount: int = 1) -> void:
		count[key] = count.get(key, 0) + amount

	func total(prefix: String) -> int:
		var sum: int = 0
		for key: String in count:
			sum += count[key] if key.begins_with(prefix + ":") else 0
		return sum

	func on_alarm(_event: SimEvent) -> void:
		add("alarmes")

	func on_lod(event: SimEvent) -> void:
		var change: LodChanged = event as LodChanged
		if change.to_level == NpcLod.LEVEL_S0:
			exposed[change.npc_id] = true
		else:
			add("saidas_s0")


## Ponte espiã: guarda o que o motorista viu ("npc:contador" -> fim previsto, caminhada até a borda e tipo) e o que relatou (desfecho, minuto, ok).
class SpyBridge:
	extends SimBridge

	var module: NpcModule
	var halves: Dictionary[String, Vector2] = {}
	var seen: Dictionary[String, Dictionary] = {}
	var reported: Dictionary[String, Dictionary] = {}
	var live: Dictionary[String, bool] = {}

	func peek_pending_npc_intents() -> BridgeReplies.NpcIntentsReply:
		var listed: BridgeReplies.NpcIntentsReply = super()
		live.clear()
		for intent: BridgeReplies.NpcIntentReply in listed.intents:
			var key: String = "%d:%d" % [intent.npc_id, intent.action_serial]
			live[key] = true
			if not seen.has(key):
				var npc: NpcModule.NpcQuery = module.peek_npc(intent.npc_id)
				var from: Vector2 = Vector2(npc.x_cm, npc.z_cm) / TerrainData.CM_PER_METER
				var stop: Vector2 = NpcRoute.stop_point(from, Vector2(intent.destination.x, intent.destination.z), halves.get(intent.place_id, Vector2.ZERO))
				seen[key] = {"planned": npc.action_ends_at, "walk": from.distance_to(stop), "kind": intent.kind}
		return listed

	func request_report_npc_result(npc_id: int, action_serial: int, outcome: BridgeReplies.NpcOutcome, final_position: Vector3) -> Result:
		var answer: Result = super(npc_id, action_serial, outcome, final_position)
		reported["%d:%d" % [npc_id, action_serial]] = {"outcome": outcome, "minute": peek_time().total_minutes, "ok": answer.ok}
		return answer


## Amostrador: segue cada NPC de um minuto para o outro. Quando o contador de ações muda, a anterior foi CANCELADA por BLOQUEIO (o corpo relatou BLOCKED), por TEMPO LIMITE
## (o Intent venceu sem relato) ou por REAVALIAÇÃO (trocada antes do fim previsto: COM corpo se o Intent ainda estava pendente no passo anterior, senão abstrata, que aplica
## o efeito proporcional); senão terminou normalmente. Do sono cancelado mede o `rest` aplicado: a variação além da deriva (a conta do sim sem o resto: ruído de 1).
class Meter:
	extends RefCounted

	var npc: NpcModule
	var run: Run
	var spy: SpyBridge
	var rates: Array[int] = []
	var timeout_min: int = 0
	var pending_before: Dictionary[String, bool] = {}
	var _last: Dictionary[int, NpcModule.NpcQuery] = {}
	var _planned: Dictionary[int, int] = {}

	func sample(now: int) -> void:
		for npc_id: int in npc.peek_npc_ids():
			var after: NpcModule.NpcQuery = npc.peek_npc(npc_id)
			var before: NpcModule.NpcQuery = _last.get(npc_id)
			if before == null or before.action_serial != after.action_serial:
				if before != null and not before.action_id.is_empty():
					_classify(before, after, _planned[npc_id], now)
				_planned[npc_id] = after.action_ends_at
			_last[npc_id] = after

	func _classify(before: NpcModule.NpcQuery, after: NpcModule.NpcQuery, planned: int, now: int) -> void:
		var key: String = "%d:%d" % [before.npc_id, before.action_serial]
		var cause: String = ""
		if spy != null and spy.reported.has(key):
			cause = "bloqueada" if spy.reported[key]["outcome"] == BridgeReplies.NpcOutcome.BLOCKED else ""
		elif pending_before.has(key) and now >= planned + timeout_min:
			cause = "tempo_limite"
			if spy.seen[key]["kind"] == BridgeReplies.NpcIntentKind.MOVE_TO_PLACE:
				run.walks_late.append(spy.seen[key]["walk"])
		elif now < planned:
			cause = "reavaliacao_corpo" if pending_before.has(key) else "reavaliacao_abstrata"
		if cause.is_empty():
			return
		var applied: int = 0
		if before.action_id == "sleep":
			applied = absi(after.need_values[REST] - NeedMath.advance(before.need_values[REST], 0, rates[REST], after.needs_updated_at - before.needs_updated_at).value)
		run.add("%s:%s" % [cause, before.action_id])
		run.add("efeito:%s:%s" % [cause, before.action_id], applied)


## O jogo de uma execução e o que está ligado a ele.
class Rig:
	extends RefCounted

	var host: SimulationHostNode
	var spy: SpyBridge
	var setup: NpcSetup
	var terrain_view: TerrainView
	var bodies: NpcBodiesView
	var driver: NpcBodyDriver


static func run(data: NpcLifeCheck.GameData, mode: Mode, world_seed: int, days: int, speed: int) -> Run:
	var started_usec: int = Time.get_ticks_usec()
	var result: Run = Run.new()
	var rig: Rig = _build(data, mode, world_seed, speed, result)
	if mode == Mode.SOLO:
		rig.host.runner.run_steps(days * DAY)
	else:
		_walk(rig, result, days, speed)
		_finish(rig, result, days)
	result.minutes = rig.host.runner.world.context.clock.total_minutes()
	result.state_hash = rig.host.runner.world.state_hash()
	if rig.bodies != null:
		rig.bodies.release()
		for node: Node in [rig.driver, rig.bodies, rig.terrain_view]:
			node.free()
	rig.host.runner.finish()
	rig.host.free()
	result.wall_ms = IntMath.floor_div(Time.get_ticks_usec() - started_usec, 1000)
	return result


static func _build(data: NpcLifeCheck.GameData, mode: Mode, world_seed: int, speed: int, result: Run) -> Rig:
	var rig: Rig = Rig.new()
	rig.setup = NpcSetup.from_dir(DATA_DIR, SettlementService.new(data.settlements, data.places))
	rig.host = SimulationHostNode.new()
	rig.host.start_new_game(world_seed, data.terrain, data.points, rig.setup)
	rig.spy = SpyBridge.new(rig.host, data.terrain, data.places, rig.host.npc)
	rig.spy.module = rig.host.npc
	for place: Place in data.places:
		if PlacePalette.is_drawn(place.kind):
			rig.spy.halves[place.id] = Vector2(PlacePalette.SIZES[place.kind].x, PlacePalette.SIZES[place.kind].z) * 0.5
	var actor_id: int = rig.spy.request_spawn_character().actor_id
	var steps: Array[Result] = [rig.spy.request_speed(speed), rig.spy.request_report_position(actor_id, AT_A_M, 0.0)]
	for npc_id: int in rig.host.npc.peek_npc_ids().slice(0, NOTABLES):
		steps.append(rig.host.npc.request_promote(npc_id, 2))
	for step: Result in steps:
		if not step.ok:
			result.problems.append(step.message)
	rig.host.runner.world.context.events.subscribe("AlarmRaised", result.on_alarm)
	rig.host.runner.world.context.events.subscribe("LodChanged", result.on_lod)
	if mode == Mode.CORPOS:
		rig.terrain_view = TerrainView.new()
		rig.terrain_view.setup(rig.spy)
		rig.bodies = NpcBodiesView.new()
		rig.driver = NpcBodyDriver.new()
		if not (rig.bodies.setup(rig.spy, rig.terrain_view) and rig.driver.setup(rig.spy, rig.bodies)):
			result.problems.append("os corpos ou o motorista não ligaram")
	return rig


## Anda `days` dias, um minuto por vez: o passo da simulação, os corpos em dia, os quadros de física do minuto e a amostra.
static func _walk(rig: Rig, result: Run, days: int, speed: int) -> void:
	var meter: Meter = Meter.new()
	meter.npc = rig.host.npc
	meter.run = result
	meter.spy = rig.spy if rig.bodies != null else null
	for def: NeedDef in rig.setup.need_defs:
		meter.rates.append(def.rate_per_hour)
	meter.timeout_min = rig.setup.definitions.intent_params.intent_timeout_min
	var frames: float = 0.0
	for minute: int in days * DAY:
		meter.pending_before = rig.spy.live.duplicate()
		rig.host.runner.step_once()
		if rig.bodies != null:
			rig.bodies.reconcile()
			frames += FRAMES_PER_MINUTE_AT_1X / float(speed)
			for _frame: int in int(frames):
				rig.driver.advance(PHYSICS_DELTA)
			frames -= floorf(frames)
		meter.sample(minute + 1)
		if (minute + 1) % DAY == 0:
			result.memory_by_day.append(int(rig.host.npc.debug_summary()["memory_records"]))


## Números do fim da execução: ações iniciadas, necessidades de cada NPC levadas ao último minuto, relações e, nos corpos, atrasos e caminhadas.
static func _finish(rig: Rig, result: Run, days: int) -> void:
	var npc: NpcModule = rig.host.npc
	var ids: Array[int] = npc.peek_npc_ids()
	for npc_id: int in ids:
		var query: NpcModule.NpcQuery = npc.peek_npc(npc_id)
		result.add("iniciadas", query.action_serial)
		result.needs[npc_id] = PackedInt64Array()
		for index: int in NpcState.NEED_COUNT:
			result.needs[npc_id].append(NeedMath.advance(query.need_values[index], 0, rig.setup.need_defs[index].rate_per_hour, days * DAY - query.needs_updated_at).value)
	result.relations = int(npc.debug_summary()["relations"])
	for first: int in ids:
		for second: int in ids.slice(ids.find(first) + 1):
			for value: int in npc.peek_opinion(first, second).values:
				result.relation_sum += value
	if rig.bodies == null:
		return
	result.count["tempo_limite_sim"] = int(npc.intents.debug_summary()["timed_out_intents"])
	for key: String in rig.spy.reported:
		var report: Dictionary = rig.spy.reported[key]
		if report["ok"] and rig.spy.seen.has(key) and report["outcome"] != BridgeReplies.NpcOutcome.BLOCKED:
			var arrived: bool = report["outcome"] == BridgeReplies.NpcOutcome.ARRIVED
			var delay: int = report["minute"] - rig.spy.seen[key]["planned"]
			var kind: String = "atraso_arrived" if arrived else "atraso_done"
			result.add("%s:%s" % [kind, "0" if delay <= 0 else ("1" if delay == 1 else ("2a5" if delay <= 5 else "mais_de_5"))])
			result.count["%s:maximo" % kind] = maxi(result.count.get("%s:maximo" % kind, 0), delay)
			if arrived:
				result.walks_ok.append(rig.spy.seen[key]["walk"])

