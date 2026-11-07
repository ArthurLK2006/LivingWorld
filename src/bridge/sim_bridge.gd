class_name SimBridge
extends RefCounted
## Ponte mínima entre a apresentação e a simulação (arquitetura 6.7; contrato em docs/modules/bridge.md).
## Não é dona de dado nenhum e não tem regra de jogo: repassa consultas somente-leitura, pedidos de
## pausa e velocidade, o nascimento e o relato de posição do personagem (LW-048) e guarda a fila de intenções. NÃO avança a simulação: o SimulationHost já faz
## isso no seu _process (decisão de Arthur de 05/11/2026). As respostas são tipos próprios, com os
## valores copiados, para a apresentação nunca precisar citar tipos de `sim/`.

const CODE_NO_GAME: String = "BRIDGE_NO_GAME"
const CODE_NO_TERRAIN: String = "BRIDGE_NO_TERRAIN"
const CODE_NULL_INTENT: String = "BRIDGE_NULL_INTENT"
const CODE_INVALID_ACTOR: String = "BRIDGE_INVALID_ACTOR"
## Há jogo iniciado, mas ele não tem o módulo do personagem (começou sem terreno).
const CODE_NO_CHARACTER: String = "BRIDGE_NO_CHARACTER"

var _host: SimulationHostNode
var _terrain: TerrainData
## Intenções na ordem de chegada. É estrutura de apresentação: não é salva nem entra no state_hash.
var _pending_intents: Array[BridgeIntent] = []


## `host` e `terrain` podem ser nulos: as chamadas que dependem deles falham com código, sem derrubar o jogo.
func _init(host: SimulationHostNode, terrain: TerrainData) -> void:
	_host = host
	_terrain = terrain


## Altura do chão (metros) em (x, z). Fora do mapa ou coordenada não numérica: falha tratada do `world`.
func peek_height(x: float, z: float) -> HeightReply:
	if _terrain == null:
		return HeightReply.new(_missing_terrain("peek_height"), 0.0)
	var query: TerrainData.HeightQuery = _terrain.peek_height(x, z)
	return HeightReply.new(query.result, query.height_m)


func peek_surface(x: float, z: float) -> SurfaceReply:
	if _terrain == null:
		return SurfaceReply.new(_missing_terrain("peek_surface"), TerrainData.NO_SURFACE_CODE, "")
	var query: TerrainData.SurfaceQuery = _terrain.peek_surface(x, z)
	return SurfaceReply.new(query.result, query.surface_code, query.surface_id)


func peek_spawn_point() -> SpawnReply:
	if _terrain == null:
		return SpawnReply.new(_missing_terrain("peek_spawn_point"), Vector3.ZERO)
	return SpawnReply.new(Result.success(), _terrain.peek_spawn_point())


## Formato do terreno (células, tamanho da célula, chunks): é o que a TerrainView precisa para saber quantos
## chunks existem e onde ficam. Valores copiados do TerrainData.
func peek_terrain_layout() -> TerrainLayoutReply:
	if _terrain == null:
		return TerrainLayoutReply.new(_missing_terrain("peek_terrain_layout"), null)
	return TerrainLayoutReply.new(Result.success(), _terrain)


## Cópia da hora simulada e do ritmo no momento da chamada.
func peek_time() -> TimeSnapshot:
	var clock: SimClock = _clock()
	if clock == null:
		return TimeSnapshot.new(_missing_game("peek_time"), null)
	return TimeSnapshot.new(Result.success(), clock)


func request_pause(is_paused: bool) -> Result:
	if _host == null:
		return _missing_game("request_pause")
	return _host.request_pause(is_paused)


## Velocidade de 1 a 8; a faixa é validada pelo relógio e o Result dele é devolvido.
func request_speed(speed: int) -> Result:
	if _host == null:
		return _missing_game("request_speed")
	return _host.request_speed(speed)


## Pede o nascimento de um personagem (ID novo, no ponto de nascimento do terreno). Quem pede é quem guarda o `actor_id`: a ponte
## não é dona de "o jogador" e pode atender vários atores. `actor_id` só vale se `result.ok`.
func request_spawn_character() -> SpawnCharacterReply:
	var character: CharacterModule = _character()
	if character == null:
		return SpawnCharacterReply.new(_missing_character("request_spawn_character"), IdGenerator.NO_ID)
	var spawn: SpawnResult = character.request_spawn()
	return SpawnCharacterReply.new(spawn.result, spawn.actor_id)


## Repassa ao personagem a posição (metros) e a orientação (radianos) que o corpo físico informa. A simulação nunca devolve posição
## ao corpo: o fluxo é de um sentido só (arquitetura 6.2). Valor não finito, fora do mapa ou ator desconhecido: falha tratada do módulo.
func request_report_position(actor_id: int, position: Vector3, yaw: float) -> Result:
	var character: CharacterModule = _character()
	if character == null:
		return _missing_character("request_report_position")
	return character.report_position(actor_id, position, yaw)


## Cópia da posição e da orientação guardadas na simulação para o ator. Ator desconhecido: falha tratada, sem derrubar.
func peek_character(actor_id: int) -> CharacterReply:
	var character: CharacterModule = _character()
	if character == null:
		return CharacterReply.new(_missing_character("peek_character"), Vector3.ZERO, 0.0)
	var query: CharacterQuery = character.peek_character(actor_id)
	return CharacterReply.new(query.result, query.position, query.yaw)


## Enfileira uma intenção. Recusa intenção nula e ator sem ID válido. Nada a consome ainda.
func submit_intent(intent: BridgeIntent) -> Result:
	if intent == null:
		return Result.failure(CODE_NULL_INTENT, "SimBridge.submit_intent: intenção nula; esperado um BridgeIntent.")
	if intent.actor_id <= IdGenerator.NO_ID:
		return Result.failure(CODE_INVALID_ACTOR, "SimBridge.submit_intent: actor_id %d inválido; esperado um ID maior que %d." % [intent.actor_id, IdGenerator.NO_ID])
	_pending_intents.append(intent)
	return Result.success()


## Entrega as intenções pendentes na ordem de chegada e esvazia a fila.
func take_pending_intents() -> Array[BridgeIntent]:
	var taken: Array[BridgeIntent] = _pending_intents
	_pending_intents = []
	return taken


func pending_intent_count() -> int:
	return _pending_intents.size()


func _clock() -> SimClock:
	if _host == null or _host.runner == null:
		return null
	return _host.runner.world.context.clock


## Módulo do personagem do jogo atual, ou nulo (sem host, sem jogo ou jogo sem terreno).
func _character() -> CharacterModule:
	if _host == null or _host.runner == null:
		return null
	return _host.character


func _missing_character(caller: String) -> Result:
	if _host == null or _host.runner == null:
		return _missing_game(caller)
	return Result.failure(CODE_NO_CHARACTER, "SimBridge.%s: o jogo atual não tem o módulo do personagem; esperado um jogo iniciado com terreno (SimulationHost.start_new_game(seed, terreno))." % caller)


func _missing_game(caller: String) -> Result:
	return Result.failure(CODE_NO_GAME, "SimBridge.%s: sem jogo iniciado no SimulationHost; esperado um host com start_new_game já chamado." % caller)


func _missing_terrain(caller: String) -> Result:
	return Result.failure(CODE_NO_TERRAIN, "SimBridge.%s: terreno não carregado; esperado um TerrainData ao criar a ponte." % caller)


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
