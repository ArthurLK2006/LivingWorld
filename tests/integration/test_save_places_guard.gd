extends GutTest
## LW-098h5-G (AGENTS 12.6; opção B de Arthur em 18/11/2026): o jogo REAL (`res://data`, montado como o `GameApp` monta: economia, rotas, semente e hora do jogo novo) salvo em DISCO (`SaveStore` com o codec JSON, pasta
## temporária) e carregado num jogo cujos locais NÃO têm uma casa que NPCs vivos citam (o defeito medido: NPCs órfãos que carregavam em silêncio e morriam de fome dias depois). Prova: (1) o carregamento FALHA com `NPC_INVALID_SAVE`, com o
## nome do módulo (`npc`) e a mensagem clara; (2) o mundo ORIGINAL, em execução, fica intacto (mesmo hash, nenhum NPC a menos) e roda mais 1 dia; (3) o arquivo do save tem o MESMO md5 e a pasta os MESMOS arquivos; (4) o MESMO save
## carrega sem erro com os dados completos, com o hash do instante salvo e, mais 1 dia depois, o MESMO hash do mundo que não recarregou (save antigo VÁLIDO preservado). O instante do save é o de NPCs andando (`go_to_place`): a
## viagem a um local que existe, com o alvo preenchido, não pode ser recusada. A caravana em viagem do comerciante (098h5) é conferida no ramo dela.

const DATA_DIR: String = "res://data"
const WORLD_DIR: String = "res://data/world"
const GAME_VERSION: String = "0.0.1-test"
const SLOT: int = 0
## Prazo, depois do 1º dia, para alguém estar andando; passou disso, a premissa do teste (rotina da manhã) mudou.
const WALK_SEARCH_LIMIT_MIN: int = 360

var _data: NpcLifeCheck.GameData
var _runners: Array[SimulationRunner] = []
var _dir: DirAccess
var _store: SaveStore


class Game:
	extends RefCounted

	var runner: SimulationRunner
	var npc: NpcModule


func before_all() -> void:
	_data = NpcLifeCheck.load_game_data()
	assert_eq(_data.problem, "", "Os dados reais do jogo carregam.")


func before_each() -> void:
	_dir = DirAccess.create_temp("lw098h5g")
	_store = SaveStore.new(_dir.get_current_dir(), JsonSaveCodec.new())


func after_each() -> void:
	for runner: SimulationRunner in _runners:
		runner.finish()
	_runners.clear()
	for file_name: String in _dir.get_files():
		_dir.remove(file_name)
	DirAccess.remove_absolute(_dir.get_current_dir())


# ---------------------------------------------------------------------------------------------------- montagem

## O jogo montado como o `GameApp` monta, com os locais `places` (os de `res://data` ou uma lista sem algum deles) no serviço do `npc`.
func _build(places: Array[Place]) -> Game:
	var setup: NpcSetup = NpcSetup.from_dir(DATA_DIR, SettlementService.new(_data.settlements, places))
	assert_true(setup.result.ok, setup.result.message)
	var game: Game = Game.new()
	game.runner = SimulationRunner.new(GameAppNode.DEFAULT_WORLD_SEED, GameAppNode.NEW_GAME_START_MINUTE)
	_runners.append(game.runner)
	var modules: GameModules = GameModules.register(game.runner, _data.terrain, _data.points, setup, EconomySetup.from_dir(EconomySetup.DEFAULT_DIR), WorldSetup.from_dir(WORLD_DIR, _data.settlements))
	assert_true(modules.result.ok, modules.result.message)
	game.npc = modules.npc
	return game


func _places_without(place_id: String) -> Array[Place]:
	var kept: Array[Place] = []
	for place: Place in _data.places:
		if place.id != place_id:
			kept.append(place)
	return kept


func _walking(game: Game) -> int:
	var walking: int = 0
	for npc_id: int in game.npc.peek_npc_ids():
		walking += 1 if game.npc.peek_npc(npc_id).action_id == ActionRunner.GO_TO_PLACE_ID else 0
	return walking


## O jogo novo andado 1 dia e depois até alguém andar (`go_to_place`).
func _walking_game() -> Game:
	var game: Game = _build(_data.places)
	game.runner.start_new_game()
	game.runner.run_days(1)
	var minutes: int = 0
	while _walking(game) == 0 and minutes < WALK_SEARCH_LIMIT_MIN:
		game.runner.step_once()
		minutes += 1
	assert_gt(_walking(game), 0, "Premissa: depois do 1º dia, em até %d minutos alguém está andando." % WALK_SEARCH_LIMIT_MIN)
	assert_true(game.runner.can_capture_game(), "Só se salva entre passos, com a fila de eventos vazia.")
	return game


# ---------------------------------------------------------------------------------------------------- o teste

func test_a_save_citing_a_missing_home_is_refused_keeps_the_world_and_the_file_and_the_full_data_still_loads() -> void:
	var original: Game = _walking_game()
	var saved: Result = _store.save(SLOT, original.runner.capture_game(), GAME_VERSION)
	assert_true(saved.ok, saved.message)
	var path: String = _store.final_path(SLOT)
	var md5_before: String = FileAccess.get_md5(path)
	var files_before: PackedStringArray = _dir.get_files()
	var saved_hash: String = original.runner.world.state_hash()
	var ids_before: Array[int] = original.npc.peek_npc_ids()
	var counts_before: Dictionary = original.npc.peek_counts()
	var first_id: int = ids_before[0]
	var missing_home: String = original.npc.peek_npc(first_id).home_place_id
	assert_ne(missing_home, "", "Premissa: o primeiro NPC mora em algum lugar.")
	# O carregamento num jogo SEM essa casa: recusado, com o código do módulo, o nome dele e a mensagem clara.
	var candidate: Game = _build(_places_without(missing_home))
	var refused: Result = candidate.runner.load_game(_store.load_slot(SLOT).payload)
	assert_false(refused.ok, "Save que cita a casa '%s', que não existe nos dados: não carrega em silêncio." % missing_home)
	assert_eq(refused.code, NpcModule.CODE_INVALID_SAVE)
	assert_string_contains(refused.message, "módulo 'npc'")
	assert_string_contains(refused.message, "NPC %d, campo 'home_place_id', local '%s'" % [first_id, missing_home])
	assert_string_contains(refused.message, "faltam casas ou locais")
	assert_eq(candidate.npc.peek_npc_ids(), [] as Array[int], "O jogo candidato não ficou com NPC nenhum: nada carregou pela metade.")
	# O mundo original segue como estava e roda mais 1 dia; o arquivo e a pasta não mudaram.
	assert_eq([original.runner.world.state_hash(), original.npc.peek_npc_ids(), original.npc.peek_counts()], [saved_hash, ids_before, counts_before], "O mundo em execução: mesmo hash, nenhum NPC a menos.")
	assert_eq([FileAccess.get_md5(path), _dir.get_files()], [md5_before, files_before], "O arquivo do save tem o mesmo md5 e a pasta os mesmos arquivos.")
	original.runner.run_days(1)
	assert_eq(original.runner.world.validate(), [] as Array[String], "O mundo original continua são depois de mais 1 dia.")
	assert_eq(original.npc.peek_counts()[NpcModule.COUNT_DEAD], 0, "Ninguém morreu.")
	# O MESMO arquivo, com os dados completos: carrega, com o hash do instante salvo, e segue como o mundo que não recarregou.
	var restored: Game = _build(_data.places)
	var loaded: Result = restored.runner.load_game(_store.load_slot(SLOT).payload)
	assert_true(loaded.ok, loaded.message)
	assert_eq(restored.runner.world.validate(), [] as Array[String], "Save válido: validate vazio.")
	assert_eq(restored.runner.world.state_hash(), saved_hash, "Carregar devolve o hash do instante salvo.")
	assert_eq(restored.npc.peek_npc_ids(), ids_before, "Todos os NPCs voltam, os que andavam com o alvo incluídos.")
	restored.runner.run_days(1)
	assert_eq(restored.runner.world.state_hash(), original.runner.world.state_hash(), "Salvar e carregar dá o MESMO hash que o mundo que seguiu direto.")
	assert_eq(FileAccess.get_md5(path), md5_before, "Depois de carregar de verdade, o arquivo continua igual.")
