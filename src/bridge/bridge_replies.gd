class_name BridgeReplies
extends RefCounted
## Tipos de resposta da ponte (`SimBridge`; contrato em docs/modules/bridge.md). Cada resposta copia os valores
## da simulação, para a apresentação nunca precisar citar tipos de `sim/`.
## Moram num arquivo próprio, e não dentro do `SimBridge`, porque ocupavam quase metade dele e o deixaram acima do
## limite de cerca de 300 linhas do AGENTS 4.5. A Fase 2 vai acrescentar à ponte consultas sobre gente, com
## respostas novas: elas entram aqui, e o arquivo da ponte fica só com os métodos (LW-053B, achado M1 do parecer
## da LW-053). Esta classe só serve de espaço de nomes: não tem estado nem métodos e não é instanciada.
## Uso: `BridgeReplies.HeightReply`, `BridgeReplies.TimeSnapshot` etc.


## Resposta de `peek_height`: `height_m` só vale se `result.ok`.
class HeightReply:
	extends RefCounted

	var result: Result
	var height_m: float

	func _init(reply_result: Result, value_m: float) -> void:
		result = reply_result
		height_m = value_m


## Resposta de `peek_surface`: só vale se `result.ok`. `surface_id` é o id de conteúdo (texto).
class SurfaceReply:
	extends RefCounted

	var result: Result
	var surface_code: int
	var surface_id: String

	func _init(reply_result: Result, code: int, id: String) -> void:
		result = reply_result
		surface_code = code
		surface_id = id


## Resposta de `peek_spawn_point`: `point` em metros (y = altura do chão), só vale se `result.ok`.
class SpawnReply:
	extends RefCounted

	var result: Result
	var point: Vector3

	func _init(reply_result: Result, value: Vector3) -> void:
		result = reply_result
		point = value


## Resposta de `request_spawn_character`: `actor_id` só vale se `result.ok`.
class SpawnCharacterReply:
	extends RefCounted

	var result: Result
	var actor_id: int

	func _init(reply_result: Result, new_actor_id: int) -> void:
		result = reply_result
		actor_id = new_actor_id


## Resposta de `peek_character`: cópia de `position` (metros) e `yaw` (radianos), só vale se `result.ok`.
class CharacterReply:
	extends RefCounted

	var result: Result
	var position: Vector3
	var yaw: float

	func _init(reply_result: Result, current_position: Vector3, current_yaw: float) -> void:
		result = reply_result
		position = current_position
		yaw = current_yaw


## Um ponto de interesse copiado: posição em metros (y = altura do terreno) e o alcance da interação. Só dados, sem tipos de `sim/`.
class PointReply:
	extends RefCounted

	var id: String
	var kind: String
	var x: float
	var y: float
	var z: float
	var text_key: String
	var reach_m: float

	func _init(point: PointOfInterest) -> void:
		id = point.id
		kind = point.kind
		x = point.position.x
		y = point.position.y
		z = point.position.z
		text_key = point.text_key
		reach_m = InteractionService.INTERACT_REACH_M


## Resposta de `peek_points_of_interest`: `points` na ordem do arquivo, só vale se `result.ok`.
class PointsReply:
	extends RefCounted

	var result: Result
	var points: Array[PointReply]

	func _init(reply_result: Result, copies: Array[PointReply]) -> void:
		result = reply_result
		points = copies


## Um local copiado: posição em metros (y = altura do terreno) e capacidade. Só dados, sem tipos de `sim/`.
class PlaceReply:
	extends RefCounted

	var id: String
	var settlement_id: String
	var kind: String
	var x: float
	var y: float
	var z: float
	var capacity: int

	func _init(place: Place) -> void:
		id = place.id
		settlement_id = place.settlement_id
		kind = place.kind
		x = place.position.x
		y = place.position.y
		z = place.position.z
		capacity = place.capacity


## Resposta de `peek_places`: `places` em ordem crescente de id, só vale se `result.ok`.
class PlacesReply:
	extends RefCounted

	var result: Result
	var places: Array[PlaceReply]

	func _init(reply_result: Result, copies: Array[PlaceReply]) -> void:
		result = reply_result
		places = copies


## Resposta de `request_interact`: `poi_id` e `text_key` (a CHAVE do texto, não o texto) só valem se `result.ok`.
class InteractReply:
	extends RefCounted

	var result: Result
	var poi_id: String
	var text_key: String

	func _init(reply_result: Result, reached_poi_id: String, reached_text_key: String) -> void:
		result = reply_result
		poi_id = reached_poi_id
		text_key = reached_text_key


## Resposta de `peek_terrain_layout`: só vale se `result.ok`. `cells` e `chunk_count` são (x, z); `size_m` é o
## tamanho do mapa em metros. Convenções de nós, células e chunks em docs/modules/world.md.
class TerrainLayoutReply:
	extends RefCounted

	var result: Result
	var cells: Vector2i = Vector2i.ZERO
	var cell_size_m: float = 0.0
	var chunk_cells: int = 0
	var chunk_count: Vector2i = Vector2i.ZERO
	var size_m: Vector2 = Vector2.ZERO

	func _init(reply_result: Result, terrain: TerrainData) -> void:
		result = reply_result
		if terrain == null:
			return
		cells = terrain.peek_cells()
		cell_size_m = terrain.peek_cell_size_m()
		chunk_cells = terrain.peek_chunk_cells()
		chunk_count = terrain.peek_chunk_count()
		size_m = terrain.peek_size_m()


## Hora simulada e ritmo copiados do relógio; os campos só valem se `result.ok`.
class TimeSnapshot:
	extends RefCounted

	var result: Result
	var year: int = 0
	var day_of_year: int = 0
	var hour_of_day: int = 0
	var minute_of_hour: int = 0
	var total_minutes: int = 0
	var is_paused: bool = false
	var speed: int = 0

	func _init(reply_result: Result, clock: SimClock) -> void:
		result = reply_result
		if clock == null:
			return
		year = clock.year()
		day_of_year = clock.day_of_year()
		hour_of_day = clock.hour_of_day()
		minute_of_hour = clock.minute_of_hour()
		total_minutes = clock.total_minutes()
		is_paused = clock.is_paused()
		speed = clock.get_speed()


## Tipo de uma intenção de NPC (LW-070), espelho de `NpcIntent.Kind` com nomes da ponte: a apresentação nunca cita tipo de `sim/`.
enum NpcIntentKind { MOVE_TO_PLACE, ACT_AT_PLACE }

## Desfecho que a apresentação devolve de uma intenção (LW-070), espelho de `NpcActionResult.Outcome`. ARRIVED vale para MOVE_TO_PLACE e
## DONE para ACT_AT_PLACE (os dois são o sucesso); BLOCKED e CANCELLED não aplicam efeito.
enum NpcOutcome { ARRIVED, DONE, BLOCKED, CANCELLED }


## Uma intenção de NPC em S0 que a apresentação ainda não cumpriu (LW-070), em CÓPIA e em unidades de tela: `destination` em metros
## (x e z do local, y = altura do terreno) e `expected_minutes` em minutos de simulação. `action_serial` volta no resultado.
class NpcIntentReply:
	extends RefCounted

	var npc_id: int
	var action_serial: int
	var kind: BridgeReplies.NpcIntentKind
	var place_id: String
	var destination: Vector3
	var expected_minutes: int

	func _init(intent: NpcIntent, ground_destination: Vector3) -> void:
		npc_id = intent.npc_id
		action_serial = intent.action_serial
		kind = BridgeReplies.NpcIntentKind.MOVE_TO_PLACE if intent.kind == NpcIntent.Kind.MOVE_TO_PLACE else BridgeReplies.NpcIntentKind.ACT_AT_PLACE
		place_id = intent.place_id
		destination = ground_destination
		expected_minutes = intent.expected_minutes


## Resposta de `peek_pending_npc_intents`: `intents` só vale se `result.ok`; em ordem crescente de NPC.
class NpcIntentsReply:
	extends RefCounted

	var result: Result
	var intents: Array[NpcIntentReply]

	func _init(reply_result: Result, copies: Array[NpcIntentReply]) -> void:
		result = reply_result
		intents = copies


## Um corpo que a apresentação deve manter (LW-072a), em CÓPIA e em metros: x e z vêm do LOD e y é a altura do terreno ali.
class NpcBodyReply:
	extends RefCounted

	var npc_id: int
	var position: Vector3

	func _init(body_npc_id: int, ground_position: Vector3) -> void:
		npc_id = body_npc_id
		position = ground_position


## Resposta de `peek_npc_bodies`: `bodies` só vale se `result.ok`; em ordem crescente de NPC.
class NpcBodiesReply:
	extends RefCounted

	var result: Result
	var bodies: Array[NpcBodyReply]

	func _init(reply_result: Result, copies: Array[NpcBodyReply]) -> void:
		result = reply_result
		bodies = copies
