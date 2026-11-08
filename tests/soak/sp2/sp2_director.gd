class_name Sp2Director
extends RefCounted
## LW-071 (SP2, DESCARTÁVEL): população e "diretor" do spike. NÃO é a população da LW-067 nem o pensamento da LW-063: só uma rotina fixa
## e curta (trabalho -> convívio -> descanso -> casa), com ações do catálogo real que não dependem de comida nem de dinheiro. A cada
## minuto de jogo, para cada NPC: se a ação dele é abstrata (S1, ou S0 sem Intent), o ActionRunner a avança; se está livre, começa a
## próxima etapa: fora do local da etapa, `go_to_place`; no local, a ação da etapa. NPC em S1 começa pelo runner abstrato (begin); NPC em
## S0, por NpcIntentBoard.begin_embodied (e só termina com o resultado do corpo). Os efeitos entram sempre pela função única do runner.

var _world: Sp2World
## NPC -> índice da etapa da rotina e os locais de cada etapa (mesma ordem de ROUTINE_KINDS).
var _stage: Dictionary[int, int] = {}
var _stage_places: Dictionary[int, PackedStringArray] = {}
var begun_abstract: int = 0
var begun_embodied: int = 0
## Recusas ao começar, por código (a rotina tenta de novo no minuto seguinte).
var refusals: Dictionary[String, int] = {}


func _init(owner: Sp2World) -> void:
	_world = owner


## 60 NPCs no povoado A (12 casas x 5) e 40 no B (8 casas x 5), ou os 100 em A. Devolve o primeiro problema (vazio se deu certo).
func populate(all_places: Array[Place], all_in_a: bool) -> String:
	var plan: Array[String] = [Sp2Constants.SETTLEMENT_A, Sp2Constants.SETTLEMENT_B]
	var counts: Array[int] = [60, 40]
	if all_in_a:
		counts = [100, 0]
	var index: int = 0
	for settlement_at: int in plan.size():
		var by_kind: Dictionary[String, Array] = _places_by_kind(all_places, plan[settlement_at])
		var homes: Array = by_kind.get(Place.KIND_HOME, [])
		for local: int in counts[settlement_at]:
			var home: Place = homes[IntMath.floor_div(local, Sp2Constants.PEOPLE_PER_HOME) % homes.size()]
			var created: String = _create(home, by_kind, local, index)
			if not created.is_empty():
				return created
			index += 1
	return ""


func on_minute(now: int) -> void:
	var waiting: Dictionary[int, bool] = {}
	for intent: NpcIntent in _world.module.peek_pending_intents():
		waiting[intent.npc_id] = true
	for npc_id: int in _world.module.peek_npc_ids():
		if waiting.has(npc_id):
			continue
		var query: NpcModule.NpcQuery = _world.module.peek_npc(npc_id)
		if not query.action_id.is_empty():
			_world.actions.advance(npc_id, now)
			query = _world.module.peek_npc(npc_id)
		if query.action_id.is_empty():
			_begin_next(npc_id, query, now)


func stage_of(npc_id: int) -> int:
	return _stage.get(npc_id, 0)


func _begin_next(npc_id: int, query: NpcModule.NpcQuery, now: int) -> void:
	var stage: int = stage_of(npc_id)
	var target: String = _stage_places[npc_id][stage]
	var action_id: String = ActionRunner.GO_TO_PLACE_ID if query.place_id != target else Sp2Constants.ROUTINE_ACTIONS[stage]
	var is_embodied: bool = _world.module.lod.level_of(npc_id) == NpcLod.LEVEL_S0
	var started: Result = _world.module.intents.begin_embodied(npc_id, action_id, target, now) if is_embodied else _world.actions.begin(npc_id, action_id, target, now)
	if not started.ok:
		refusals[started.code] = refusals.get(started.code, 0) + 1
		return
	if is_embodied:
		begun_embodied += 1
	else:
		begun_abstract += 1
	# Começou a ação do local: a próxima vez que ficar livre, segue para a etapa seguinte (feita ou cancelada).
	if action_id != ActionRunner.GO_TO_PLACE_ID:
		_stage[npc_id] = (stage + 1) % Sp2Constants.ROUTINE_KINDS.size()


func _create(home: Place, by_kind: Dictionary[String, Array], local: int, index: int) -> String:
	var spec: NpcSpec = NpcSpec.new()
	spec.name_key = Sp2Constants.NAME_KEY
	spec.name_number = index + 1
	spec.x_cm = roundi(home.position.x * TerrainData.CM_PER_METER)
	spec.z_cm = roundi(home.position.z * TerrainData.CM_PER_METER)
	spec.settlement_id = home.settlement_id
	spec.place_id = home.id
	spec.home_place_id = home.id
	var created: NpcModule.CreateResult = _world.module.request_create_npc(spec)
	if not created.result.ok:
		return "Sp2Director: o módulo recusou o NPC %d: %s" % [index + 1, created.result.message]
	var stage_places: PackedStringArray = PackedStringArray()
	for kind: String in Sp2Constants.ROUTINE_KINDS:
		var options: Array = by_kind.get(kind, [])
		if kind == Place.KIND_HOME:
			stage_places.append(home.id)
		elif options.is_empty():
			return "Sp2Director: o povoado '%s' não tem local do tipo '%s'." % [home.settlement_id, kind]
		else:
			stage_places.append((options[local % options.size()] as Place).id)
	_stage_places[created.npc_id] = stage_places
	# Etapas desencontradas (arranjo fixo, sem sorteio): nem todos trabalham ao mesmo tempo.
	_stage[created.npc_id] = index % Sp2Constants.ROUTINE_KINDS.size()
	return ""


static func _places_by_kind(all_places: Array[Place], settlement_id: String) -> Dictionary[String, Array]:
	var found: Dictionary[String, Array] = {}
	for place: Place in all_places:
		if place.settlement_id != settlement_id:
			continue
		if not found.has(place.kind):
			found[place.kind] = []
		found[place.kind].append(place)
	return found
