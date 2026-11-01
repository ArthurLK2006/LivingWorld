class_name FakeNpcPopulation
extends SimModule
## SPIKE SP1 (LW-023) — código DESCARTÁVEL. Mil NPCs "de mentira": três necessidades e quatro
## ações simples. Cada NPC "pensa" a cada 5 a 15 minutos, escalonado (arquitetura 6.4 e 8.5),
## e só os NPCs que vencem no minuto são processados (anel de 16 listas), então o custo por
## passo acompanha quem pensa, não o total. Dados quentes em PackedInt32Array.

const NEED_MAX: int = 1000
const RING_SIZE: int = 16
const RING_MASK: int = 15
const MIN_THINK_DELAY: int = 5
const THINK_DELAY_SPAN: int = 11
const HUNGER_PER_MINUTE: int = 1
const ENERGY_LOSS_PER_MINUTE: int = 1
const SOCIAL_LOSS_PER_MINUTE: int = 1
const EAT_RELIEF: int = 600
const SLEEP_RELIEF: int = 500
const SOCIAL_RELIEF: int = 400
const WORK_BASELINE: int = 300
const SCORE_NOISE: int = 50
const STARVING_LEVEL: int = 950
## Carga de teste do barramento: 1 de cada 50 pensamentos publica um evento (~2 por passo; pessimista).
const EVENT_EVERY_N_THOUGHTS: int = 50
const STREAM_INIT: String = "npc_init"
const STREAM_THINK: String = "npc_think"

enum Action { EAT, SLEEP, SOCIALIZE, WORK }

var npc_count: int
var thoughts_total: int = 0
var starving_events_seen: int = 0
var _ctx: SimContext
var _npc_ids: PackedInt32Array = PackedInt32Array()
var _hunger: PackedInt32Array = PackedInt32Array()
var _energy: PackedInt32Array = PackedInt32Array()
var _social: PackedInt32Array = PackedInt32Array()
var _action: PackedInt32Array = PackedInt32Array()
var _last_update: PackedInt32Array = PackedInt32Array()
var _ring: Array[PackedInt32Array] = []
var _subscription: int = 0


func _init(population: int) -> void:
	npc_count = population


func setup(context: SimContext) -> void:
	_ctx = context


func post_setup() -> void:
	_subscription = _ctx.events.subscribe("NpcStarvingSpike", _on_starving)


func on_new_game(_world_seed: int) -> void:
	_npc_ids.resize(npc_count)
	_hunger.resize(npc_count)
	_energy.resize(npc_count)
	_social.resize(npc_count)
	_action.resize(npc_count)
	_last_update.resize(npc_count)
	_ring = []
	for _i: int in RING_SIZE:
		_ring.append(PackedInt32Array())
	for npc: int in npc_count:
		_npc_ids[npc] = _ctx.ids.next_id()
		_hunger[npc] = _ctx.rng.range_int(STREAM_INIT, 0, NEED_MAX / 2)
		_energy[npc] = _ctx.rng.range_int(STREAM_INIT, NEED_MAX / 2, NEED_MAX)
		_social[npc] = _ctx.rng.range_int(STREAM_INIT, NEED_MAX / 2, NEED_MAX)
		_action[npc] = Action.WORK
		_last_update[npc] = 0
		_ring[(1 + npc % THINK_DELAY_SPAN) & RING_MASK].append(npc)


func tick(_elapsed_minutes: int) -> void:
	var now: int = _ctx.clock.total_minutes()
	var slot: int = now & RING_MASK
	var due: PackedInt32Array = _ring[slot]
	for npc: int in due:
		_think(npc, now)
	_ring[slot].clear()


func _think(npc: int, now: int) -> void:
	var elapsed: int = now - _last_update[npc]
	var hunger: int = mini(NEED_MAX, _hunger[npc] + elapsed * HUNGER_PER_MINUTE)
	var energy: int = maxi(0, _energy[npc] - elapsed * ENERGY_LOSS_PER_MINUTE)
	var social: int = maxi(0, _social[npc] - elapsed * SOCIAL_LOSS_PER_MINUTE)
	var noise: int = _ctx.rng.range_int(STREAM_THINK, 0, SCORE_NOISE)
	var best: int = Action.WORK
	var best_score: int = WORK_BASELINE + noise
	var eat_score: int = hunger * 2 + noise
	if eat_score > best_score:
		best = Action.EAT
		best_score = eat_score
	var sleep_score: int = (NEED_MAX - energy) + noise
	if sleep_score > best_score:
		best = Action.SLEEP
		best_score = sleep_score
	var social_score: int = (NEED_MAX - social) + noise
	if social_score > best_score:
		best = Action.SOCIALIZE
	match best:
		Action.EAT:
			hunger = maxi(0, hunger - EAT_RELIEF)
		Action.SLEEP:
			energy = mini(NEED_MAX, energy + SLEEP_RELIEF)
		Action.SOCIALIZE:
			social = mini(NEED_MAX, social + SOCIAL_RELIEF)
	_hunger[npc] = hunger
	_energy[npc] = energy
	_social[npc] = social
	_action[npc] = best
	_last_update[npc] = now
	thoughts_total += 1
	if hunger >= STARVING_LEVEL or (npc + now) % EVENT_EVERY_N_THOUGHTS == 0:
		_ctx.events.publish(TestEvent.new("NpcStarvingSpike"))
	_ring[(now + MIN_THINK_DELAY + (npc + now) % THINK_DELAY_SPAN) & RING_MASK].append(npc)


func serialize() -> Dictionary:
	var ring_data: Array = []
	for slot: PackedInt32Array in _ring:
		ring_data.append(Array(slot))
	return {
		"npc_ids": Array(_npc_ids),
		"hunger": Array(_hunger),
		"energy": Array(_energy),
		"social": Array(_social),
		"action": Array(_action),
		"last_update": Array(_last_update),
		"ring": ring_data,
		"thoughts_total": thoughts_total,
		"starving_events_seen": starving_events_seen,
	}


## Restaura o estado salvo (usado pelo spike SP5). Números do JSON chegam como decimais.
func on_load(data: Dictionary) -> Result:
	var hot_columns: Array[String] = ["npc_ids", "hunger", "energy", "social", "action", "last_update"]
	for column: String in hot_columns:
		if typeof(data.get(column)) != TYPE_ARRAY or (data[column] as Array).size() != npc_count:
			return Result.failure("FAKE_NPC_INVALID_SAVE", "FakeNpcPopulation.on_load: coluna '%s' ausente ou com tamanho diferente de %d." % [column, npc_count])
	if typeof(data.get("ring")) != TYPE_ARRAY or (data["ring"] as Array).size() != RING_SIZE:
		return Result.failure("FAKE_NPC_INVALID_SAVE", "FakeNpcPopulation.on_load: 'ring' deve ter %d listas." % RING_SIZE)
	_npc_ids = _to_ints(data["npc_ids"])
	_hunger = _to_ints(data["hunger"])
	_energy = _to_ints(data["energy"])
	_social = _to_ints(data["social"])
	_action = _to_ints(data["action"])
	_last_update = _to_ints(data["last_update"])
	_ring = []
	for slot_data: Array in data["ring"]:
		_ring.append(_to_ints(slot_data))
	thoughts_total = int(data["thoughts_total"])
	starving_events_seen = int(data["starving_events_seen"])
	return Result.success()


func _to_ints(values: Array) -> PackedInt32Array:
	var converted: PackedInt32Array = PackedInt32Array()
	converted.resize(values.size())
	for index: int in values.size():
		converted[index] = int(values[index])
	return converted


func debug_summary() -> Dictionary:
	return {"npcs": npc_count, "thoughts_total": thoughts_total, "starving_events_seen": starving_events_seen}


func teardown() -> void:
	_ctx.events.unsubscribe(_subscription)


func _on_starving(_event: SimEvent) -> void:
	starving_events_seen += 1
