class_name PopulationPlan
extends RefCounted
## População inicial do `npc` (LW-067; docs/modules/npc.md, seção 1): quantos NPCs de cada ofício nascem em cada assentamento, lido de
## data/population.json (PopulationLoader) e entregue ao módulo por `NpcModule.Definitions.population`. LW-097d (DEC-167): uma linha pode citar o local de
## trabalho que ocupa (`work_place_id`); sem ele vale o primeiro local do tipo do ofício com vaga, como antes. `build_specs` monta, SEM criar
## nada, os pedidos de criação em ordem fixa (assentamento, ofício, sequência). Antes de gastar qualquer sorteio ele confere que os
## assentamentos e os ofícios existem e que há casa e local de trabalho com vaga para todos (`NPC_POPULATION_NO_ROOM`: erro de DADO, nunca
## NPC sem casa). Cada NPC recebe a primeira casa com vaga e o primeiro local de trabalho do tipo do ofício com vaga (ordem de id), nasce
## em casa e tem os traços sorteados no fluxo `npc.population` do ctx.rng. Nome provisório e genérico (DEC-100): uma chave de texto e um
## número. A escala de 100 NPCs é provisória (DEC-040 pendente). Nada aqui conhece tela, relógio ou arquivo.

## Chave de texto do nome (a apresentação monta "Aldeão 001").
const NAME_KEY: String = "npc.name.villager"
## Fluxo do sorteio dos traços (único gerador permitido, AGENTS 4.9); outro que o da decisão, para uma não mexer na outra.
const RNG_STREAM: String = "npc.population"
const CODE_INVALID_REFERENCE: String = "NPC_POPULATION_INVALID_REFERENCE"
const CODE_NO_ROOM: String = "NPC_POPULATION_NO_ROOM"

var _rows: Array[PopulationRow] = []


## `rows`: uma por (assentamento, ofício). Ficam em ordem de assentamento e depois de ofício, qualquer que seja a ordem do arquivo.
func _init(rows: Array[PopulationRow] = []) -> void:
	_rows = rows.duplicate()
	_rows.sort_custom(func(first: PopulationRow, second: PopulationRow) -> bool:
		if first.settlement_id != second.settlement_id:
			return first.settlement_id < second.settlement_id
		if first.occupation_id != second.occupation_id:
			return first.occupation_id < second.occupation_id
		return first.work_place_id < second.work_place_id)


## Quantos NPCs nascem ao todo.
func total() -> int:
	var sum: int = 0
	for row: PopulationRow in _rows:
		sum += row.count
	return sum


## As linhas, em ordem de criação (cópia da lista; as linhas são só dados).
func peek_rows() -> Array[PopulationRow]:
	return _rows.duplicate()


## Os pedidos de criação, em ordem. Confere tudo ANTES de sortear: se algo falha, nada foi gasto do gerador de números.
func build_specs(places: SettlementService, routine: RoutineTable, rng: WorldRng) -> BuildResult:
	var reference_problem: String = _reference_problem(places, routine)
	if not reference_problem.is_empty():
		return BuildResult.new(Result.failure(CODE_INVALID_REFERENCE, "PopulationPlan.build_specs: %s." % reference_problem), [])
	var assignment: Assignment = _assign(places, routine)
	if not assignment.result.ok:
		return BuildResult.new(assignment.result, [])
	return BuildResult.new(Result.success(), _specs(assignment, rng))


## Primeiro problema de referência (texto vazio = tudo existe): assentamento no `world`, ofício na tabela de rotina e, se a linha cita um local,
## que ele exista, seja do mesmo assentamento e do tipo de local do ofício.
func _reference_problem(places: SettlementService, routine: RoutineTable) -> String:
	for row: PopulationRow in _rows:
		if not places.peek_settlement(row.settlement_id).result.ok:
			return "o assentamento '%s' da linha de população não existe no `world`" % row.settlement_id
		if not routine.has_occupation(row.occupation_id):
			return "o ofício '%s' da linha de população não existe nos dados de ofícios (esperado um de: %s)" % [row.occupation_id, ", ".join(routine.peek_occupation_ids())]
		if not row.work_place_id.is_empty():
			var cited: SettlementService.PlaceQuery = places.peek_place(row.work_place_id)
			if not cited.result.ok:
				return "o local de trabalho '%s' da linha de população não existe no `world`" % row.work_place_id
			if cited.place.settlement_id != row.settlement_id or cited.place.kind != routine.peek_work_place_kind(row.occupation_id):
				return "o local '%s' (assentamento '%s', tipo '%s') não serve à linha de '%s' em '%s': esperado um local do mesmo assentamento e do tipo '%s'" % [row.work_place_id, cited.place.settlement_id, cited.place.kind, row.occupation_id, row.settlement_id, routine.peek_work_place_kind(row.occupation_id)]
	return ""


## Casa e local de trabalho de cada NPC, na ordem de criação: sempre o primeiro (por id) que ainda tem vaga.
func _assign(places: SettlementService, routine: RoutineTable) -> Assignment:
	var used: Dictionary[String, int] = {}
	var assignment: Assignment = Assignment.new()
	assignment.result = _reserve_cited_places(places, used)
	if not assignment.result.ok:
		return assignment
	var number: int = 0
	for row: PopulationRow in _rows:
		var homes: Array[Place] = _places_by_id(places, row.settlement_id, Place.KIND_HOME)
		var work_kind: String = routine.peek_work_place_kind(row.occupation_id)
		var workplaces: Array[Place] = _places_by_id(places, row.settlement_id, work_kind)
		for _sequence: int in row.count:
			number += 1
			var home: Place = _first_with_room(homes, used)
			if home == null:
				assignment.result = Result.failure(CODE_NO_ROOM, "PopulationPlan.build_specs: no assentamento '%s' o NPC nº %d (ofício '%s') ficou sem casa com vaga; as casas do assentamento somam %d vaga(s)." % [row.settlement_id, number, row.occupation_id, _capacity_of(homes)])
				return assignment
			used[home.id] = int(used.get(home.id, 0)) + 1
			var workplace: Place = places.peek_place(row.work_place_id).place if not row.work_place_id.is_empty() else _first_with_room(workplaces, used)
			if workplace == null:
				assignment.result = Result.failure(CODE_NO_ROOM, "PopulationPlan.build_specs: no assentamento '%s' o NPC nº %d (ofício '%s') ficou sem local de trabalho '%s' com vaga; esses locais somam %d vaga(s)." % [row.settlement_id, number, row.occupation_id, work_kind, _capacity_of(workplaces)])
				return assignment
			if row.work_place_id.is_empty():
				used[workplace.id] = int(used.get(workplace.id, 0)) + 1
			assignment.homes.append(home)
			assignment.workplaces.append(workplace)
	return assignment


## Reserva as vagas dos locais citados pelas linhas ANTES de distribuir as outras (assim a ordem das linhas não decide quem fica sem vaga) e falha com
## `NPC_POPULATION_NO_ROOM` se as linhas pedem mais que a capacidade de um local.
func _reserve_cited_places(places: SettlementService, used: Dictionary[String, int]) -> Result:
	for row: PopulationRow in _rows:
		if not row.work_place_id.is_empty():
			used[row.work_place_id] = int(used.get(row.work_place_id, 0)) + row.count
	for place_id: String in used:
		var capacity: int = places.peek_place(place_id).place.capacity
		if used[place_id] > capacity:
			return Result.failure(CODE_NO_ROOM, "PopulationPlan.build_specs: o local de trabalho '%s' tem capacidade %d e as linhas de população pedem %d vaga(s)." % [place_id, capacity, used[place_id]])
	return Result.success()


## Pedidos de criação com nome, traços sorteados e posição de casa. Só roda depois de `_assign` aprovar.
func _specs(assignment: Assignment, rng: WorldRng) -> Array[NpcSpec]:
	var specs: Array[NpcSpec] = []
	var index: int = 0
	for row: PopulationRow in _rows:
		for _sequence: int in row.count:
			var home: Place = assignment.homes[index]
			var spec: NpcSpec = NpcSpec.new()
			spec.name_key = NAME_KEY
			spec.name_number = index + 1
			spec.traits = _roll_traits(rng)
			spec.settlement_id = row.settlement_id
			spec.occupation_id = row.occupation_id
			spec.home_place_id = home.id
			spec.work_place_id = assignment.workplaces[index].id
			spec.place_id = home.id
			spec.x_cm = roundi(home.position.x * TerrainData.CM_PER_METER)
			spec.z_cm = roundi(home.position.z * TerrainData.CM_PER_METER)
			specs.append(spec)
			index += 1
	return specs


## Um valor de 0 a 100 por traço: a média inteira de dois sorteios, para a maioria ficar perto do meio e poucos nos extremos [HIP].
func _roll_traits(rng: WorldRng) -> PackedInt64Array:
	var traits: PackedInt64Array = PackedInt64Array()
	traits.resize(NpcState.TRAIT_COUNT)
	for position: int in NpcState.TRAIT_COUNT:
		var first: int = rng.range_int(RNG_STREAM, NpcState.VALUE_MIN, NpcState.VALUE_MAX)
		var second: int = rng.range_int(RNG_STREAM, NpcState.VALUE_MIN, NpcState.VALUE_MAX)
		traits[position] = IntMath.floor_div(first + second, 2)
	return traits


## Locais do assentamento e do tipo dados, em ordem de id (nunca a ordem do arquivo). Lista vazia se o tipo não existe ou não há nenhum.
func _places_by_id(places: SettlementService, settlement_id: String, kind: String) -> Array[Place]:
	var found: SettlementService.PlacesQuery = places.peek_places_of_kind(settlement_id, kind)
	var sorted: Array[Place] = []
	if found.result.ok:
		sorted.assign(found.places)
		sorted.sort_custom(func(first: Place, second: Place) -> bool: return first.id < second.id)
	return sorted


func _first_with_room(candidates: Array[Place], used: Dictionary[String, int]) -> Place:
	for place: Place in candidates:
		if int(used.get(place.id, 0)) < place.capacity:
			return place
	return null


func _capacity_of(candidates: Array[Place]) -> int:
	var sum: int = 0
	for place: Place in candidates:
		sum += place.capacity
	return sum


## Uma linha de data/population.json: quantos NPCs do ofício nascem no assentamento.
class PopulationRow:
	extends RefCounted

	var settlement_id: String
	var occupation_id: String
	var count: int
	## O local de trabalho que a linha ocupa; vazio = o primeiro local com vaga (LW-097d, DEC-167).
	var work_place_id: String

	func _init(row_settlement_id: String, row_occupation_id: String, row_count: int, row_work_place_id: String = "") -> void:
		settlement_id = row_settlement_id
		occupation_id = row_occupation_id
		count = row_count
		work_place_id = row_work_place_id


## Casa e local de trabalho de cada NPC, na ordem de criação; `result` falha com `NPC_POPULATION_NO_ROOM` se faltar vaga.
class Assignment:
	extends RefCounted

	var result: Result = Result.success()
	var homes: Array[Place] = []
	var workplaces: Array[Place] = []


## Resultado de `build_specs`: `specs` só vale se `result.ok`.
class BuildResult:
	extends RefCounted

	var result: Result
	var specs: Array[NpcSpec]

	func _init(build_result: Result, built_specs: Array[NpcSpec]) -> void:
		result = build_result
		specs = built_specs
