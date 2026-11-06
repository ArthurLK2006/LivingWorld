class_name CharacterModule
extends SimModule
## Estado lógico mínimo do jogador (LW-035; contrato em docs/modules/character.md): identidade,
## posição e orientação de cada personagem, num Dictionary indexado por actor_id (o módulo não
## supõe um jogador só). O corpo físico é da apresentação; aqui fica só a posição lógica.
## O terreno entra pelo construtor e só é consultado: a regra de "dentro do mapa" é do world.

const CODE_NOT_READY: String = "CHARACTER_NOT_READY"
const CODE_UNKNOWN_ACTOR: String = "CHARACTER_UNKNOWN_ACTOR"
const CODE_OUT_OF_BOUNDS: String = "CHARACTER_OUT_OF_BOUNDS"
const CODE_INVALID_VALUE: String = "CHARACTER_INVALID_VALUE"
const CODE_INVALID_SAVE: String = "CHARACTER_INVALID_SAVE"
const CODE_NO_ID: String = "CHARACTER_NO_ID"
const CODE_DUPLICATE_ID: String = "CHARACTER_DUPLICATE_ID"
## Orientação de quem acaba de nascer, em radianos. [HIP]
const SPAWN_YAW: float = 0.0
const KEY_CHARACTERS: String = "characters"
const KEY_POSITION: String = "position"
const KEY_YAW: String = "yaw"
## Números da posição salva: um por eixo (x, y, z).
const POSITION_AXES: int = 3

var _terrain: TerrainData
var _ctx: SimContext
## Motivo de o terreno não servir (vazio = serve). Calculado uma vez em setup(), porque
## TerrainData.validate() varre a grade inteira e não pode rodar a cada comando.
var _terrain_problem: String = "setup() ainda não foi chamado"
var _characters: Dictionary[int, CharacterState] = {}


func _init(terrain: TerrainData) -> void:
	_terrain = terrain


func setup(ctx: SimContext) -> void:
	_ctx = ctx
	if _terrain == null:
		_terrain_problem = "terreno ausente (nulo)"
		return
	var problems: Array[String] = _terrain.validate()
	_terrain_problem = "" if problems.is_empty() else "terreno inválido: %s" % problems[0]


## Cria um personagem novo (ID novo de ctx.ids) no ponto de nascimento do terreno.
func request_spawn() -> SpawnResult:
	var status: Result = _ready_status("request_spawn")
	if not status.ok:
		return SpawnResult.new(status, IdGenerator.NO_ID)
	var actor_id: int = _ctx.ids.next_id()
	if actor_id == IdGenerator.NO_ID:
		return SpawnResult.new(Result.failure(CODE_NO_ID, "CharacterModule.request_spawn: o contador de IDs esgotou; não há ID novo."), IdGenerator.NO_ID)
	if _characters.has(actor_id):
		return SpawnResult.new(Result.failure(CODE_DUPLICATE_ID, "CharacterModule.request_spawn: o ID novo %d já pertence a um personagem (save inconsistente); nada foi sobrescrito." % actor_id), IdGenerator.NO_ID)
	_characters[actor_id] = CharacterState.new(_terrain.peek_spawn_point(), SPAWN_YAW)
	return SpawnResult.new(Result.success(), actor_id)


## Informa a posição e a orientação atuais. Recusa valor não finito e posição fora do mapa; uma
## recusa não altera o estado. A altura Y só precisa ser finita (o personagem pode estar no ar).
func report_position(actor_id: int, pos: Vector3, yaw: float) -> Result:
	var status: Result = _ready_status("report_position")
	if not status.ok:
		return status
	if not _characters.has(actor_id):
		return _unknown_actor("report_position", actor_id)
	if not pos.is_finite() or not is_finite(yaw):
		return Result.failure(CODE_INVALID_VALUE, "CharacterModule.report_position: ator %d, valor não finito (posição %s, yaw %s); esperado números finitos." % [actor_id, str(pos), str(yaw)])
	var ground: TerrainData.HeightQuery = _terrain.peek_height(pos.x, pos.z)
	if not ground.result.ok:
		return Result.failure(CODE_OUT_OF_BOUNDS, "CharacterModule.report_position: ator %d, posição %s recusada pelo terreno (%s: %s)" % [actor_id, str(pos), ground.result.code, ground.result.message])
	var state: CharacterState = _characters[actor_id]
	state.position = pos
	state.yaw = yaw
	return Result.success()


## Posição e orientação atuais, em cópia. ID inexistente devolve falha tratada.
func peek_character(actor_id: int) -> CharacterQuery:
	if not _characters.has(actor_id):
		return CharacterQuery.new(_unknown_actor("peek_character", actor_id), Vector3.ZERO, 0.0)
	var state: CharacterState = _characters[actor_id]
	return CharacterQuery.new(Result.success(), state.position, state.yaw)


## IDs viram texto (assim o JSON guarda chaves) e entram em ordem crescente do número.
func serialize() -> Dictionary:
	var saved: Dictionary = {}
	for actor_id: int in _sorted_ids():
		var state: CharacterState = _characters[actor_id]
		saved[str(actor_id)] = {KEY_POSITION: [state.position.x, state.position.y, state.position.z], KEY_YAW: state.yaw}
	return {KEY_CHARACTERS: saved}


## Confere tudo antes de alterar o estado: se algo for inválido, o estado fica como estava.
func on_load(data: Dictionary) -> Result:
	# Variant: valor cru do save (JSON); o tipo é conferido na linha seguinte.
	var raw_characters: Variant = data.get(KEY_CHARACTERS)
	if typeof(raw_characters) != TYPE_DICTIONARY:
		return _invalid_save("campo '%s' ausente ou não é um objeto (veio %s)" % [KEY_CHARACTERS, type_string(typeof(raw_characters))])
	var entries: Dictionary = raw_characters
	var keys: Array = entries.keys()
	keys.sort()
	var loaded: Dictionary[int, CharacterState] = {}
	for key: Variant in keys:
		var actor_id: int = _read_actor_id(str(key))
		if actor_id == IdGenerator.NO_ID:
			return _invalid_save("chave de ator '%s' inválida; esperado um inteiro de %d a %d" % [str(key), IdGenerator.FIRST_ID, IdGenerator.MAX_ID])
		if loaded.has(actor_id):
			return _invalid_save("o ator %d aparece duas vezes (chave '%s')" % [actor_id, str(key)])
		var state: CharacterState = _read_state(entries[key])
		if state == null:
			return _invalid_save("ator %d: esperado {%s: [x, y, z], %s} com números finitos" % [actor_id, KEY_POSITION, KEY_YAW])
		loaded[actor_id] = state
	_characters = loaded
	return Result.success()


## Problemas do estado (lista vazia se estiver tudo certo). Posição fora do mapa é apontada aqui,
## não recusada em on_load.
func validate() -> Array[String]:
	var problems: Array[String] = []
	if not _terrain_problem.is_empty():
		problems.append("terreno indisponível: %s" % _terrain_problem)
	for actor_id: int in _sorted_ids():
		var state: CharacterState = _characters[actor_id]
		if actor_id < IdGenerator.FIRST_ID or actor_id > IdGenerator.MAX_ID:
			problems.append("personagem %d: ID fora da faixa [%d, %d]." % [actor_id, IdGenerator.FIRST_ID, IdGenerator.MAX_ID])
		if not state.position.is_finite() or not is_finite(state.yaw):
			problems.append("personagem %d: valor não finito (posição %s, yaw %s)." % [actor_id, str(state.position), str(state.yaw)])
		elif _terrain_problem.is_empty() and not _terrain.peek_height(state.position.x, state.position.z).result.ok:
			problems.append("personagem %d: posição %s fora do mapa." % [actor_id, str(state.position)])
	return problems


func debug_summary() -> Dictionary:
	return {"count": _characters.size(), "actor_ids": _sorted_ids(), "terrain_ready": _terrain_problem.is_empty()}


## Nunca visitar o Dictionary pela ordem natural (muda depois de carregar um save).
func _sorted_ids() -> Array[int]:
	var ids: Array[int] = []
	ids.assign(_characters.keys())
	ids.sort()
	return ids


func _ready_status(caller: String) -> Result:
	if _terrain_problem.is_empty():
		return Result.success()
	return Result.failure(CODE_NOT_READY, "CharacterModule.%s: módulo não está pronto (%s)." % [caller, _terrain_problem])


func _unknown_actor(caller: String, actor_id: int) -> Result:
	return Result.failure(CODE_UNKNOWN_ACTOR, "CharacterModule.%s: o ator %d não existe; esperado um ID devolvido por request_spawn (há %d personagem(ns))." % [caller, actor_id, _characters.size()])


func _invalid_save(detail: String) -> Result:
	return Result.failure(CODE_INVALID_SAVE, "CharacterModule.on_load: %s." % detail)


## ID de ator a partir do texto da chave; NO_ID se não for um inteiro na faixa válida.
func _read_actor_id(key_text: String) -> int:
	if not key_text.is_valid_int():
		return IdGenerator.NO_ID
	var value: int = key_text.to_int()
	return value if value >= IdGenerator.FIRST_ID and value <= IdGenerator.MAX_ID else IdGenerator.NO_ID


## Estado a partir de um registro salvo; null se faltar campo, houver tipo errado ou valor não finito.
## `raw_entry` é Variant porque vem cru do JSON; o tipo é conferido logo abaixo.
func _read_state(raw_entry: Variant) -> CharacterState:
	if typeof(raw_entry) != TYPE_DICTIONARY:
		return null
	var entry: Dictionary = raw_entry
	# Variant: lista crua do JSON; o tipo e o tamanho são conferidos na linha seguinte.
	var raw_position: Variant = entry.get(KEY_POSITION)
	if typeof(raw_position) != TYPE_ARRAY or raw_position.size() != POSITION_AXES:
		return null
	var axes: Array = raw_position
	var position: Vector3 = Vector3(_to_number(axes[0]), _to_number(axes[1]), _to_number(axes[2]))
	var yaw: float = _to_number(entry.get(KEY_YAW))
	# Vector3 tem 32 bits: um decimal enorme, finito em 64 bits, vira infinito aqui e é recusado.
	if not position.is_finite() or not is_finite(yaw):
		return null
	return CharacterState.new(position, yaw)


## Número vindo do save (JSON dá decimal; teste pode dar inteiro); qualquer outra coisa vira NaN.
## `raw_value` é Variant porque vem cru do JSON.
func _to_number(raw_value: Variant) -> float:
	if typeof(raw_value) != TYPE_FLOAT and typeof(raw_value) != TYPE_INT:
		return NAN
	var number: float = raw_value
	return number
