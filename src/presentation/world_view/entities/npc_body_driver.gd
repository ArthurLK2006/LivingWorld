class_name NpcBodyDriver
extends Node
## O laço Intent -> corpo -> resultado dos NPCs em S0 (LW-072e). A cada quadro de física lê o relógio e os Intents pela ponte e, para cada Intent novo
## de um NPC com corpo, traça a rota N1 (`NpcRoute`) e leva o corpo por ela a 4 m/s vezes a velocidade do relógio (zero em pausa), ligando o andar do
## `NpcView`. ARRIVED ao chegar (ir a um local); nas outras ações, DONE com o corpo no local depois do FIM ESTIMADO, que é o minuto de jogo em que o motorista
## VIU o Intent mais `expected_minutes` (decisão de Arthur, opção C: o Intent não traz o minuto de fim); BLOCKED se a rota é recusada. Larga o trabalho, sem
## enviar nada, se o Intent some da lista ou o NPC perde o corpo (saiu de S0). Posições em lote só dos corpos que andaram, no máximo a cada 6 quadros. Resultado
## velho (`NPC_RESULT_STALE`) e `NPC_ACTION_FAILED` não são erro; outra recusa é erro visível (uma vez por código) e o Intent recusado não é tentado de novo.
## Só os testes o criam: o jogo real ainda não tem motorista (LW-072f). Contrato: docs/modules/presentation.md.

## Posições em lote [HIP]: a cada tantos quadros de física (6 = 10 por segundo a 60 Hz), como o `PlayerBody`.
const REPORT_EVERY_PHYSICS_FRAMES: int = 6
## Códigos da simulação tratados como "largar o trabalho": a apresentação não cita classes de src/sim, então eles são copiados como texto (um teste
## confere que seguem iguais).
const CODE_STALE: String = "NPC_RESULT_STALE"
const CODE_NOT_IN_S0: String = "NPC_NOT_IN_S0"
const CODE_ACTION_FAILED: String = "NPC_ACTION_FAILED"
const NO_SERIAL: int = -1

var _bridge: SimBridge
var _bodies: NpcBodiesView
## Meia-medida (x e z) da caixa de cada local desenhado; local sem caixa não está aqui (o corpo vai ao centro).
var _half_boxes: Dictionary[String, Vector2] = {}
## Um trabalho por Intent, até o Intent sair da lista: mesmo respondido ou recusado ele fica (`is_reported`), e assim não é tentado de novo.
var _jobs: Dictionary[int, Job] = {}
## NPCs cujo corpo andou desde o último lote de posições.
var _moved: Dictionary[int, bool] = {}
var _frames_since_report: int = 0
var _warned_codes: Dictionary[String, bool] = {}
var _is_ready: bool = false


## O trabalho de um corpo: cumprir UM Intent.
class Job:
	extends RefCounted

	var intent: BridgeReplies.NpcIntentReply
	var route: NpcRoute
	var traveled_m: float = 0.0
	var ends_at_minute: int
	var is_reported: bool = false

	func _init(planned: BridgeReplies.NpcIntentReply, planned_route: NpcRoute, seen_minute: int) -> void:
		intent = planned
		route = planned_route
		ends_at_minute = seen_minute + planned.expected_minutes


## Liga o motorista à ponte e aos corpos (a `NpcBodiesView` já ligada) e lê as caixas dos locais; chame uma vez. Ponte nula, corpos nulos ou inativos, ou
## locais indisponíveis: push_error e o motorista fica parado (devolve falso).
func setup(bridge: SimBridge, bodies: NpcBodiesView) -> bool:
	_is_ready = false
	if bridge == null or bodies == null or not bodies.is_active():
		push_error("NpcBodyDriver.setup: ponte nula, NpcBodiesView nula ou inativa; esperado uma SimBridge e uma NpcBodiesView com setup que deu certo.")
		return false
	var places: BridgeReplies.PlacesReply = bridge.peek_places()
	if not places.result.ok:
		push_error("NpcBodyDriver.setup: locais indisponíveis (%s): %s" % [places.result.code, places.result.message])
		return false
	for place: BridgeReplies.PlaceReply in places.places:
		if PlacePalette.is_drawn(place.kind):
			_half_boxes[place.id] = Vector2(PlacePalette.SIZES[place.kind].x, PlacePalette.SIZES[place.kind].z) * NpcView.HALF
	_bridge = bridge
	_bodies = bodies
	_is_ready = true
	set_physics_process(true)
	return true


## Um quadro de física de `delta` segundos: põe os trabalhos em dia com os Intents, anda os corpos e, a cada 6 quadros, relata as posições em lote.
func advance(delta: float) -> void:
	if not _is_ready:
		return
	var time: BridgeReplies.TimeSnapshot = _bridge.peek_time()
	var listed: BridgeReplies.NpcIntentsReply = _bridge.peek_pending_npc_intents()
	if not time.result.ok or not listed.result.ok:
		_warn_once(listed.result if time.result.ok else time.result, "relógio ou Intents indisponíveis")
		return
	_sync_jobs(listed.intents, time.total_minutes)
	var step_m: float = NpcRoute.speed_mps(time.speed, time.is_paused) * delta
	for job: Job in _jobs.values():
		_step_job(job, step_m, time.total_minutes)
	_frames_since_report += 1
	if _frames_since_report >= REPORT_EVERY_PHYSICS_FRAMES:
		_report_positions()


func job_count() -> int:
	return _jobs.size()


## Contador de ação do Intent que o NPC tem em mãos (em curso ou já respondido), ou NO_SERIAL se ele não tem.
func job_serial_of(npc_id: int) -> int:
	return _jobs[npc_id].intent.action_serial if _jobs.has(npc_id) else NO_SERIAL


func _ready() -> void:
	set_physics_process(_is_ready)


func _physics_process(delta: float) -> void:
	advance(delta)


## Larga o trabalho de quem perdeu o Intent ou o corpo e começa o dos Intents novos que já têm corpo.
func _sync_jobs(intents: Array[BridgeReplies.NpcIntentReply], now: int) -> void:
	var serials: Dictionary[int, int] = {}
	for intent: BridgeReplies.NpcIntentReply in intents:
		serials[intent.npc_id] = intent.action_serial
	for npc_id: int in _jobs.keys():
		var gone: NpcView = _body_of(npc_id)
		if serials.get(npc_id, NO_SERIAL) != _jobs[npc_id].intent.action_serial or gone == null:
			_jobs.erase(npc_id)
			if gone != null:
				gone.set_walking(false)
	for intent: BridgeReplies.NpcIntentReply in intents:
		var view: NpcView = _body_of(intent.npc_id)
		if view != null and not _jobs.has(intent.npc_id):
			_start_job(intent, view, now)


func _start_job(intent: BridgeReplies.NpcIntentReply, view: NpcView, now: int) -> void:
	var half_box: Vector2 = _half_boxes.get(intent.place_id, Vector2.ZERO)
	var job: Job = Job.new(intent, NpcRoute.plan(view.position, intent.destination, half_box, _ground_height), now)
	_jobs[intent.npc_id] = job
	if job.route.is_blocked:
		_report(job, view, BridgeReplies.NpcOutcome.BLOCKED)
	elif job.route.length_m > 0.0:
		view.rotation.y = NpcRoute.facing_yaw(job.route.points[job.route.points.size() - 1] - job.route.points[0])


## Anda o corpo `step_m` metros pela rota (zero em pausa) e, se terminou o que cabe a ele, devolve o resultado.
func _step_job(job: Job, step_m: float, now: int) -> void:
	if job.is_reported:
		return
	var view: NpcView = _body_of(job.intent.npc_id)
	var can_move: bool = step_m > 0.0 and job.traveled_m < job.route.length_m
	if can_move:
		job.traveled_m = minf(job.traveled_m + step_m, job.route.length_m)
		view.position = job.route.position_at(job.traveled_m)
		_moved[job.intent.npc_id] = true
	view.set_walking(can_move and job.traveled_m < job.route.length_m)
	if job.traveled_m < job.route.length_m:
		return
	if job.intent.kind == BridgeReplies.NpcIntentKind.MOVE_TO_PLACE:
		_report(job, view, BridgeReplies.NpcOutcome.ARRIVED)
	elif now >= job.ends_at_minute:
		_report(job, view, BridgeReplies.NpcOutcome.DONE)


func _report(job: Job, view: NpcView, outcome: BridgeReplies.NpcOutcome) -> void:
	view.set_walking(false)
	job.is_reported = true
	var sent: Result = _bridge.request_report_npc_result(job.intent.npc_id, job.intent.action_serial, outcome, view.position)
	if sent.ok:
		_moved.erase(job.intent.npc_id)
	elif sent.code != CODE_STALE and sent.code != CODE_NOT_IN_S0 and sent.code != CODE_ACTION_FAILED:
		_warn_once(sent, "resultado recusado")


## Lote com a posição dos corpos que andaram desde o último lote. Ninguém andou: nada é enviado.
func _report_positions() -> void:
	_frames_since_report = 0
	var batch: Dictionary[int, Vector3] = {}
	for npc_id: int in _moved.keys():
		var view: NpcView = _body_of(npc_id)
		if view != null:
			batch[npc_id] = view.position
	_moved.clear()
	if batch.is_empty():
		return
	var sent: Result = _bridge.request_report_npc_positions(batch)
	if not sent.ok and sent.code != CODE_NOT_IN_S0:
		_warn_once(sent, "posições recusadas")


func _body_of(npc_id: int) -> NpcView:
	return _bodies.pool().body_of(npc_id)


## Altura do terreno para a rota; NAN se a ponte não souber (a rota é recusada).
func _ground_height(x: float, z: float) -> float:
	var ground: BridgeReplies.HeightReply = _bridge.peek_height(x, z)
	return ground.height_m if ground.result.ok else NAN


func _warn_once(failure: Result, what: String) -> void:
	if _warned_codes.has(failure.code):
		return
	_warned_codes[failure.code] = true
	push_error("NpcBodyDriver: %s (%s): %s" % [what, failure.code, failure.message])
