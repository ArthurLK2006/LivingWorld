extends GutTest
## Frente de estabilidade (Arthur, 21/11/2026): o dinheiro do JOGADOR na RECARGA do jogo (hipótese do backlog, "Cada `setup` do `PlayerBody` cria um personagem NOVO e, portanto, uma conta nova com `mint`"; revisão do PR #7).
## O jogo é o REAL (`res://data`, montado como o `GameApp` monta). O jogador nasce pela ponte, como `PlayerBody._spawn_character` faz (`request_spawn_character` e `request_open_player_account`), o jogo é salvo (codec JSON, bytes)
## e carregado num jogo NOVO (`SimulationRunner.load_game`). Dois testes: (1) PROTEÇÃO, passa e deve continuar passando: carregar SOZINHO não cunha nada e devolve o jogador e a conta como estavam (o save já guarda o
## personagem no `character` e a conta na `economy`). (2) CARACTERIZAÇÃO DE UMA LACUNA CONHECIDA, NÃO a aprova: o `setup` seguinte do corpo (a cena refeita sobre o mundo carregado) pede um personagem NOVO (o `request_spawn` sempre
## gasta um ID) e a economia, que só conhece "dono novo", faz outro `mint` `game_start` do tipo `player`: o dinheiro total SOBE o saldo inicial, passa a haver DOIS donos `player` e DOIS personagens (a conta antiga fica órfã) e
## a conservação continua fechando, porque o `mint` é contabilizado (por isso o teste de ouro não vê). HOJE é inalcançável no jogo real: não há fluxo de carregar no `GameApp` (só o `SimulationRunner.load_game`, usado por testes)
## e o único `setup` do corpo é o de `MainWorldView._ready`. Passa a valer quando o carregar existir e a cena refizer as views (`docs/modules/app.md`, A4). A correção exige contrato e/ou save (como o mundo carregado identifica
## "o jogador": opções no `docs/backlog.md`), então NÃO foi feita aqui: este teste afirma o comportamento ATUAL. Quando a decisão de Arthur for implementada, inverta as duas asserções marcadas com INVERTER (dinheiro e `mint`
## iguais ao de antes, um dono `player` e um personagem só) e tire `known_gap` do nome.

const DATA_DIR: String = "res://data"
const WORLD_DIR: String = "res://data/world"
const GAME_VERSION: String = "0.0.1-test"
const GAME_START_REASON: String = "game_start"
## Minutos andados com o jogador já criado, antes de salvar (o save é de um mundo que já rodou).
const MINUTES_BEFORE_SAVE: int = 60

var _data: NpcLifeCheck.GameData
var _kind: OwnerKindDef
var _runners: Array[SimulationRunner] = []
var _hosts: Array[SimulationHostNode] = []


class Game:
	extends RefCounted

	var runner: SimulationRunner
	var bridge: SimBridge
	var character: CharacterModule
	var economy: EconomyModule
	## Só no jogo de `_played_game`: o ID do jogador e o que o `mint` `game_start` tinha criado ANTES de ele nascer.
	var player: int = IdGenerator.NO_ID
	var created_before_player: int = 0


func before_all() -> void:
	_data = NpcLifeCheck.load_game_data()
	assert_eq(_data.problem, "", "Os dados reais do jogo carregam.")
	var economy_setup: EconomySetup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR)
	assert_true(economy_setup.result.ok, economy_setup.result.message)
	for kind: OwnerKindDef in economy_setup.definitions.kinds:
		if kind.id == BridgePlayerEconomy.OWNER_KIND:
			_kind = kind
	assert_not_null(_kind, "O tipo `player` existe nos dados da economia: o teste LÊ o saldo inicial deles em vez de fixá-lo.")


func after_each() -> void:
	for runner: SimulationRunner in _runners:
		runner.finish()
	_runners.clear()
	for host: SimulationHostNode in _hosts:
		host.free()
	_hosts.clear()


# ---------------------------------------------------------------------------------------------------- montagem

## O jogo montado como o `GameApp` monta (dados reais, economia e rotas, semente e hora do jogo novo), com um host à mão para a ponte (o host do jogo só tem `start_new_game`; o carregar não existe nele).
func _build() -> Game:
	var setup: NpcSetup = NpcSetup.from_dir(DATA_DIR, SettlementService.new(_data.settlements, _data.places))
	assert_true(setup.result.ok, setup.result.message)
	var game: Game = Game.new()
	game.runner = SimulationRunner.new(GameAppNode.DEFAULT_WORLD_SEED, GameAppNode.NEW_GAME_START_MINUTE)
	_runners.append(game.runner)
	var modules: GameModules = GameModules.register(game.runner, _data.terrain, _data.points, setup, EconomySetup.from_dir(EconomySetup.DEFAULT_DIR), WorldSetup.from_dir(WORLD_DIR, _data.settlements))
	assert_true(modules.result.ok, modules.result.message)
	var host: SimulationHostNode = SimulationHostNode.new()
	_hosts.append(host)
	host.runner = game.runner
	host.character = modules.character
	host.interaction = modules.interaction
	host.npc = modules.npc
	host.economy = modules.economy
	game.bridge = SimBridge.new(host, _data.terrain, _data.places, modules.npc)
	game.character = modules.character
	game.economy = modules.economy
	return game


## O jogo NOVO com o jogador criado (`player`) e `MINUTES_BEFORE_SAVE` minutos andados.
func _played_game() -> Game:
	var game: Game = _build()
	game.runner.start_new_game()
	game.created_before_player = _game_start_created(game)
	game.player = _spawn_player(game)
	game.runner.run_steps(MINUTES_BEFORE_SAVE)
	return game


## Salva o jogo como o jogo grava (codec JSON, em bytes) e o carrega num jogo NOVO montado com os mesmos dados.
func _save_and_load(game: Game) -> Game:
	assert_true(game.runner.can_capture_game(), "Só se salva entre passos, com a fila de eventos vazia.")
	var decoded: DecodedSave = JsonSaveCodec.new().decode(JsonSaveCodec.new().encode(game.runner.capture_game(), GAME_VERSION))
	assert_true(decoded.result.ok, decoded.result.message)
	var loaded_game: Game = _build()
	var loaded: Result = loaded_game.runner.load_game(decoded.payload)
	assert_true(loaded.ok, loaded.message)
	return loaded_game


## O que o `PlayerBody` faz ao nascer: pede o personagem e abre a conta pela ponte. Devolve o ID do personagem.
func _spawn_player(game: Game) -> int:
	var spawned: BridgeReplies.SpawnCharacterReply = game.bridge.request_spawn_character()
	assert_true(spawned.result.ok, spawned.result.message)
	var opened: Result = game.bridge.request_open_player_account(spawned.actor_id)
	assert_true(opened.ok, opened.message)
	return spawned.actor_id


# ---------------------------------------------------------------------------------------------------- medidas

func _player_owners(game: Game) -> int:
	var owners: Dictionary = game.economy.serialize().get(EconomyModule.KEY_OWNERS, {})
	var count: int = 0
	for owner_id: String in owners:
		if str((owners[owner_id] as Dictionary).get(OwnerBook.KEY_KIND, "")) == BridgePlayerEconomy.OWNER_KIND:
			count += 1
	return count


func _game_start_created(game: Game) -> int:
	for row: Dictionary in game.economy.peek_ledger_totals().rows:
		if row["reason"] == GAME_START_REASON:
			return int(row["created"])
	return 0


## O dinheiro total (soma dos saldos), o criado pelo `mint` `game_start`, os donos `player` e os personagens: o que a recarga não pode mexer.
func _snapshot(game: Game) -> Dictionary:
	return {"money": game.economy.peek_conservation().sum, "game_start_created": _game_start_created(game), "player_owners": _player_owners(game), "characters": game.character.debug_summary()["actor_ids"]}


func _assert_sound(game: Game, label: String) -> void:
	assert_eq(game.runner.world.validate() + game.economy.validate(), [] as Array[String], "%s: validate vazio." % label)
	assert_true(game.economy.peek_conservation().ok, "%s: o dinheiro se conserva (o `mint` é contabilizado)." % label)


# ---------------------------------------------------------------------------------------------------- os testes

func test_saving_and_loading_alone_restores_the_player_and_creates_no_money() -> void:
	var first: Game = _played_game()
	var player: int = first.player
	var before: Dictionary = _snapshot(first)
	assert_eq([before["player_owners"], before["characters"], before["game_start_created"] - first.created_before_player], [1, [player], _kind.initial_balance], "Premissa: um jogador, um personagem, e o `mint` dele é um saldo inicial do tipo.")
	var account: BridgePlayerEconomyReplies.PlayerEconomyReply = first.bridge.peek_player_economy(player)
	var where: BridgeReplies.CharacterReply = first.bridge.peek_character(player)
	var restored: Game = _save_and_load(first)
	assert_eq(_snapshot(restored), before, "Carregar sozinho não cria nada: o mesmo dinheiro, o mesmo `mint`, o mesmo dono `player` e o mesmo personagem.")
	var restored_account: BridgePlayerEconomyReplies.PlayerEconomyReply = restored.bridge.peek_player_economy(player)
	assert_eq([restored_account.result.ok, restored_account.funds, restored_account.weight, restored_account.capacity, restored_account.goods], [true, account.funds, account.weight, account.capacity, account.goods], "A conta do jogador volta igual (saldo, peso, capacidade e bens), com o MESMO ID.")
	var restored_where: BridgeReplies.CharacterReply = restored.bridge.peek_character(player)
	assert_eq([restored_where.result.ok, restored_where.position, restored_where.yaw], [true, where.position, where.yaw], "O personagem volta na mesma posição e orientação.")
	_assert_sound(restored, "carregado")


func test_known_gap_spawning_the_player_again_on_a_loaded_world_mints_another_initial_balance() -> void:
	var first: Game = _played_game()
	var player: int = first.player
	var before: Dictionary = _snapshot(first)
	var old_funds: int = first.bridge.peek_player_economy(player).funds
	var restored: Game = _save_and_load(first)
	assert_eq(_snapshot(restored), before, "Premissa: o mundo carregado tem o jogador de antes (um dono `player`, um personagem).")
	var reborn: int = _spawn_player(restored)
	var after: Dictionary = _snapshot(restored)
	assert_ne(reborn, player, "O `request_spawn` sempre gasta um ID: o corpo da cena refeita ganha um personagem NOVO, não o do save.")
	# INVERTER (depois da decisão de Arthur): o dinheiro total e o `mint` ficam IGUAIS aos de antes (`before`), e `player_owners` e `characters` não mudam.
	assert_eq(after["money"], before["money"] + _kind.initial_balance, "LACUNA ATUAL: o dinheiro total sobe o saldo inicial do tipo `player` a cada novo nascimento.")
	assert_eq(after["game_start_created"], before["game_start_created"] + _kind.initial_balance, "LACUNA ATUAL: o `mint` game_start do jogador se repete.")
	assert_eq([after["player_owners"], after["characters"]], [2, [player, reborn]], "LACUNA ATUAL: dois donos `player` e dois personagens (a conta antiga fica órfã).")
	assert_eq(restored.bridge.peek_player_economy(player).funds, old_funds, "A conta antiga não muda: o dinheiro dela fica preso num personagem sem corpo.")
	assert_eq(restored.bridge.peek_player_economy(reborn).funds, _kind.initial_balance, "O corpo novo começa com o saldo inicial, recém-criado.")
	_assert_sound(restored, "depois do novo nascimento")
