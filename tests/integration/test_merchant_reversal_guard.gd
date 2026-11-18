extends GutTest
## LW-098h5-G (opção B de Arthur, 18/11/2026; AGENTS 12.6) sobre os 6 comerciantes: a REVERSÃO dos dados. Um save feito COM os comerciantes e as 6 casas novas e carregado com os dados ORIGINAIS (sem as casas) NÃO carrega em silêncio:
## o `load_game` do runner NOVO FALHA com a mensagem clara (NPC_INVALID_SAVE, módulo `npc`), antes de o mundo rodar, e o mundo original segue intacto; antes da proteção esse save carregava sem aviso e 3 NPCs (os 2 comerciantes do A e o último
## pastor do B, que moram em `a_home_13` e `b_home_10`) morriam de fome cerca de 3 dias depois. O caminho SEGURO (reverter só a população e MANTER as casas) carrega. Dados reais de `res://data`, montagem como a do `GameApp`.

const DATA_DIR: String = "res://data"
const WORLD_DIR: String = "res://data/world"
const GAME_VERSION: String = "0.0.1-test"
const MERCHANT: String = "merchant"
const DAY: int = SimClock.MINUTES_PER_DAY
## As 6 casas que a opção A acrescenta (data/world/places.json).
const NEW_HOMES: Array[String] = ["a_home_13", "a_home_14", "b_home_10", "b_home_11", "c_home_09", "c_home_10"]

var _data: NpcLifeCheck.GameData
var _runners: Array[SimulationRunner] = []


class Game:
	extends RefCounted

	var runner: SimulationRunner
	var npc: NpcModule


func before_all() -> void:
	_data = NpcLifeCheck.load_game_data()
	assert_eq(_data.problem, "", "Os dados reais do jogo carregam.")


func after_each() -> void:
	for runner: SimulationRunner in _runners:
		runner.finish()
	_runners.clear()


## O jogo montado como o `GameApp` monta. `with_merchants` falso: a população SEM as três linhas `merchant` (a reversão de `population.json`); `with_new_homes` falso: os locais SEM as 6 casas novas (a reversão de `places.json`).
func _build(with_merchants: bool, with_new_homes: bool) -> Game:
	var places: Array[Place] = []
	for place: Place in _data.places:
		if with_new_homes or not NEW_HOMES.has(place.id):
			places.append(place)
	var setup: NpcSetup = NpcSetup.from_dir(DATA_DIR, SettlementService.new(_data.settlements, places))
	assert_true(setup.result.ok, setup.result.message)
	if not with_merchants:
		var rows: Array[PopulationPlan.PopulationRow] = []
		for row: PopulationPlan.PopulationRow in setup.definitions.population.peek_rows():
			if row.occupation_id != MERCHANT:
				rows.append(row)
		setup.definitions.population = PopulationPlan.new(rows)
	var game: Game = Game.new()
	game.runner = SimulationRunner.new(GameAppNode.DEFAULT_WORLD_SEED, GameAppNode.NEW_GAME_START_MINUTE)
	_runners.append(game.runner)
	var modules: GameModules = GameModules.register(game.runner, _data.terrain, _data.points, setup, EconomySetup.from_dir(EconomySetup.DEFAULT_DIR), WorldSetup.from_dir(WORLD_DIR, _data.settlements))
	assert_true(modules.result.ok, modules.result.message)
	game.npc = modules.npc
	return game


## Um dia do jogo real COM os comerciantes e as casas novas, e o save como o jogo grava (codec JSON, em bytes).
func _saved_world_with_the_merchants() -> Dictionary:
	var game: Game = _build(true, true)
	game.runner.start_new_game()
	game.runner.run_steps(DAY)
	assert_true(game.runner.can_capture_game(), "Só se salva entre passos, com a fila de eventos vazia.")
	var bytes: PackedByteArray = JsonSaveCodec.new().encode(game.runner.capture_game(), GAME_VERSION)
	return {"game": game, "bytes": bytes}


func _load(bytes: PackedByteArray, with_merchants: bool, with_new_homes: bool) -> Dictionary:
	var decoded: DecodedSave = JsonSaveCodec.new().decode(bytes)
	assert_true(decoded.result.ok, decoded.result.message)
	var candidate: Game = _build(with_merchants, with_new_homes)
	return {"game": candidate, "result": candidate.runner.load_game(decoded.payload)}


## O que o save cita e os dados SEM as casas novas não têm: `references` (um texto por NPC vivo e campo, em ordem de id e dos campos, como a conferência os lista) e `npc_ids` (os NPCs vivos afetados). Derivado do próprio jogo que gravou o save, não de ids fixos.
class Missing:
	extends RefCounted

	var references: Array[String] = []
	var npc_ids: Array[int] = []


func _note_new_home(missing: Missing, npc_id: int, field: String, place_id: String) -> void:
	if NEW_HOMES.has(place_id):
		missing.references.append("NPC %d, campo '%s', local '%s'" % [npc_id, field, place_id])


func _missing_without_the_new_homes(game: Game) -> Missing:
	var missing: Missing = Missing.new()
	for npc_id: int in game.npc.peek_npc_ids():
		var npc: NpcModule.NpcQuery = game.npc.peek_npc(npc_id)
		if not npc.is_alive:
			continue
		var before: int = missing.references.size()
		_note_new_home(missing, npc_id, "home_place_id", npc.home_place_id)
		_note_new_home(missing, npc_id, "work_place_id", npc.work_place_id)
		_note_new_home(missing, npc_id, "place_id", npc.place_id)
		_note_new_home(missing, npc_id, "action_target_place_id", npc.action_target_place_id)
		if missing.references.size() > before:
			missing.npc_ids.append(npc_id)
	return missing


func test_a_save_with_the_merchants_is_refused_clearly_by_the_original_data_without_their_homes() -> void:
	var saved: Dictionary = _saved_world_with_the_merchants()
	var original: Game = saved["game"]
	var bytes: PackedByteArray = saved["bytes"]
	var hash_before: String = original.runner.world.state_hash()
	var alive_before: int = original.npc.peek_counts()[NpcModule.COUNT_ALIVE]
	var bytes_before: PackedByteArray = bytes.duplicate()
	var missing: Missing = _missing_without_the_new_homes(original)
	assert_gt(missing.npc_ids.size(), 0, "Premissa: depois de 1 dia há NPCs vivos que moram nas casas novas (as que a reversão dos dados tira).")
	var attempt: Dictionary = _load(bytes, false, false)
	var result: Result = attempt["result"]
	assert_false(result.ok, "O save com comerciantes NÃO carrega nos dados originais, sem as casas.")
	assert_eq(result.code, NpcModule.CODE_INVALID_SAVE, "A recusa tem o código do save inválido do `npc`.")
	for expected: String in ["módulo 'npc'", "%d referência(s) em %d NPC(s) vivo(s)" % [missing.references.size(), missing.npc_ids.size()], "restaure os dados com que o save foi criado"]:
		assert_string_contains(result.message, expected, "A mensagem é clara: diz o módulo, as contagens e o que fazer.")
	var listed: int = mini(missing.references.size(), NpcPersistence.MAX_LISTED_MISSING_PLACES)
	var first_references: Array[String] = []
	first_references.assign(missing.references.slice(0, listed))
	assert_string_contains(result.message, "; ".join(first_references), "A mensagem diz, em ordem de NPC e de campo (casa, trabalho, onde está, alvo da ação), o NPC, o campo e o local que não existe; o NPC com ação em curso lista também o `place_id` e o alvo.")
	if missing.references.size() > listed:
		assert_string_contains(result.message, "e mais %d" % (missing.references.size() - listed), "O que passa do limite listado vira uma contagem.")
	assert_eq(bytes, bytes_before, "Os bytes do save ficam intactos.")
	# O mundo ORIGINAL (o jogo que gravou o save) segue como estava e roda mais um dia sem perder ninguém (o candidato é que se descarta).
	assert_eq(original.runner.world.state_hash(), hash_before, "A tentativa de carregar não tocou o mundo em execução.")
	original.runner.run_steps(DAY)
	assert_eq(original.npc.peek_counts()[NpcModule.COUNT_ALIVE], alive_before, "Ninguém foi removido nem morreu por causa da tentativa.")
	assert_eq(original.runner.world.validate() + original.npc.validate(), [] as Array[String], "O mundo original segue válido.")


func test_reverting_only_the_population_and_keeping_the_homes_loads_the_save_with_everyone() -> void:
	var saved: Dictionary = _saved_world_with_the_merchants()
	var original: Game = saved["game"]
	var attempt: Dictionary = _load(saved["bytes"], false, true)
	var result: Result = attempt["result"]
	assert_true(result.ok, "O caminho SEGURO da reversão (só `population.json`, com as casas mantidas) carrega o save: %s" % result.message)
	var loaded: Game = attempt["game"]
	assert_eq(loaded.runner.world.state_hash(), original.runner.world.state_hash(), "O jogo carregado é o do instante salvo.")
	assert_eq(loaded.npc.peek_counts()[NpcModule.COUNT_ALIVE], original.npc.peek_counts()[NpcModule.COUNT_ALIVE], "Ninguém some: os 138 seguem vivos.")
	assert_eq(loaded.runner.world.validate() + loaded.npc.validate(), [] as Array[String], "O jogo carregado é válido.")
