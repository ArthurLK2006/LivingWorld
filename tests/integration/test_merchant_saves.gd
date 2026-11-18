extends GutTest
## LW-098h5 (docs/modules/economy.md, 9.15.5; opção A aprovada por Arthur em 18/11/2026): o jogo REAL jogado com os seis comerciantes (dados de `res://data`; economia e rotas; semente e hora do jogo novo do `GameApp`) e os SAVES. Prova
## (1) determinismo e ida e volta (hash do fim igual com e sem salvar no meio); (2) SAVE ANTIGO (feito sem comerciantes) carrega nos dados novos sem criar ninguém e segue com o hash do mundo antigo; (3) SAVE COM COMERCIANTES feito com uma
## caravana em viagem: o registro, o comerciante e a carga voltam iguais e a chegada acontece depois de carregar. O mundo ANTIGO é montado em memória, tirando as três linhas `merchant` da população (as seis casas novas só acrescentam
## locais: os 132 de antes ficam com as mesmas casas). Cada save passa pelo codec JSON (bytes) como o do jogo. O limite de reversibilidade (save novo carregado com dados originais) é medido à parte e NÃO é fixado aqui.

const DATA_DIR: String = "res://data"
const WORLD_DIR: String = "res://data/world"
const GAME_VERSION: String = "0.0.1-test"
const MERCHANT: String = "merchant"
const DAY: int = SimClock.MINUTES_PER_DAY
## Metade do dia (o ponto em que o teste de determinismo salva); escrito como horas para não dividir inteiros.
const HALF_DAY: int = 12 * SimClock.MINUTES_PER_HOUR
## Prazo para o primeiro comerciante partir em viagem no jogo novo (a semente e a hora do jogo real o fazem no 1º dia); passou disso, o teste diz que a premissa mudou.
const TRIP_SEARCH_LIMIT: int = 2 * DAY
## Minutos andados na estrada antes de salvar: a caravana já tem progresso, mas ainda está longe da chegada.
const MINUTES_ON_ROAD: int = 10
const ARRIVAL_LIMIT: int = 600
## Passos depois da chegada em que o jogo carregado ainda tem de coincidir com o direto.
const AFTER_ARRIVAL: int = 60

var _data: NpcLifeCheck.GameData
var _runners: Array[SimulationRunner] = []


class Game:
	extends RefCounted

	var runner: SimulationRunner
	var npc: NpcModule
	var economy: EconomyModule


func before_all() -> void:
	_data = NpcLifeCheck.load_game_data()
	assert_eq(_data.problem, "", "Os dados reais do jogo carregam.")


func after_each() -> void:
	for runner: SimulationRunner in _runners:
		runner.finish()
	_runners.clear()


# ---------------------------------------------------------------------------------------------------- montagem

## O jogo montado como o `GameApp` monta (dados reais, economia e rotas, semente e hora do jogo novo). `with_merchants` falso: o mundo ANTIGO, sem as três linhas `merchant` da população.
func _build(with_merchants: bool) -> Game:
	var setup: NpcSetup = NpcSetup.from_dir(DATA_DIR, SettlementService.new(_data.settlements, _data.places))
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
	game.economy = modules.economy
	return game


func _new_game(with_merchants: bool = true) -> Game:
	var game: Game = _build(with_merchants)
	game.runner.start_new_game()
	return game


## O save como o jogo grava: o codec JSON, em bytes.
func _encode(game: Game) -> PackedByteArray:
	assert_true(game.runner.can_capture_game(), "Só se salva entre passos, com a fila de eventos vazia.")
	return JsonSaveCodec.new().encode(game.runner.capture_game(), GAME_VERSION)


## Carrega `bytes` num jogo NOVO montado com os dados de hoje (`with_merchants` verdadeiro: as três linhas `merchant` na população).
func _load(bytes: PackedByteArray, with_merchants: bool = true) -> Game:
	var decoded: DecodedSave = JsonSaveCodec.new().decode(bytes)
	assert_true(decoded.result.ok, decoded.result.message)
	var game: Game = _build(with_merchants)
	var loaded: Result = game.runner.load_game(decoded.payload)
	assert_true(loaded.ok, loaded.message)
	return game


func _hash(game: Game) -> String:
	return game.runner.world.state_hash()


func _merchants(game: Game) -> Array[int]:
	var ids: Array[int] = []
	for npc_id: int in game.npc.peek_npc_ids():
		if game.npc.peek_npc(npc_id).occupation_id == MERCHANT:
			ids.append(npc_id)
	return ids


## O jogo está são: `alive` vivos e nenhum morto, `merchants` comerciantes, `validate` do mundo e do `npc` vazios, dinheiro e bens conservados.
func _assert_sound(game: Game, alive: int, merchants: int, label: String) -> void:
	var counts: Dictionary = game.npc.peek_counts()
	assert_eq([counts[NpcModule.COUNT_ALIVE], counts[NpcModule.COUNT_DEAD], _merchants(game).size()], [alive, 0, merchants], "%s: vivos, mortos e comerciantes." % label)
	assert_eq(game.runner.world.validate() + game.npc.validate(), [] as Array[String], "%s: validate vazio." % label)
	assert_true(game.economy.peek_conservation().ok, "%s: o dinheiro se conserva." % label)
	assert_true(game.economy.peek_goods_conservation().ok, "%s: os bens se conservam." % label)


# ---------------------------------------------------------------------------------------------------- determinismo e ida e volta

func test_a_world_with_the_merchants_is_deterministic_and_survives_a_save_and_load() -> void:
	var first: Game = _new_game()
	_assert_sound(first, 138, 6, "jogo novo")
	first.runner.run_steps(HALF_DAY)
	var saved: PackedByteArray = _encode(first)
	var saved_hash: String = _hash(first)
	first.runner.run_steps(HALF_DAY)
	var direct_hash: String = _hash(first)
	_assert_sound(first, 138, 6, "fim do dia, execução direta")
	var second: Game = _new_game()
	second.runner.run_steps(HALF_DAY)
	assert_eq(_encode(second), saved, "Duas execuções iguais gravam os MESMOS bytes no meio do dia.")
	second.runner.run_steps(HALF_DAY)
	assert_eq(_hash(second), direct_hash, "Duas execuções iguais dão o MESMO hash no fim.")
	var restored: Game = _load(saved)
	assert_eq(_hash(restored), saved_hash, "Carregar devolve o hash do instante salvo.")
	_assert_sound(restored, 138, 6, "carregado no meio do dia")
	restored.runner.run_steps(HALF_DAY)
	assert_eq(_hash(restored), direct_hash, "Salvar no meio e carregar dá o MESMO hash do fim que a execução direta.")
	_assert_sound(restored, 138, 6, "fim do dia, carregado")


# ---------------------------------------------------------------------------------------------------- save antigo

func test_an_old_save_without_the_merchants_loads_in_the_new_data_and_creates_nobody() -> void:
	var old_world: Game = _new_game(false)
	_assert_sound(old_world, 132, 0, "mundo antigo")
	old_world.runner.run_steps(DAY)
	var saved: PackedByteArray = _encode(old_world)
	var saved_hash: String = _hash(old_world)
	var saved_ids: Array[int] = old_world.npc.peek_npc_ids()
	var saved_next_id: Dictionary = old_world.runner.world.context.ids.serialize()
	old_world.runner.run_steps(2 * DAY)
	var uninterrupted_hash: String = _hash(old_world)
	var loaded: Game = _load(saved, true)
	assert_eq(loaded.npc.peek_npc_ids(), saved_ids, "Nenhum NPC criado de novo: os mesmos 132 IDs, na mesma ordem.")
	assert_eq(loaded.runner.world.context.ids.serialize(), saved_next_id, "Nem um ID gasto: o gerador volta onde estava.")
	assert_eq(_hash(loaded), saved_hash, "Mesmo hash ao carregar.")
	_assert_sound(loaded, 132, 0, "save antigo carregado nos dados novos")
	loaded.runner.run_steps(2 * DAY)
	assert_eq(_hash(loaded), uninterrupted_hash, "Mais 2 dias: o MESMO hash de uma execução ininterrupta do mundo antigo.")
	_assert_sound(loaded, 132, 0, "2 dias depois")


# ---------------------------------------------------------------------------------------------------- save com comerciantes

## Anda o jogo até algum comerciante estar em viagem (`travelling`), no máximo `limit` minutos; devolve o ID dele, ou NO_ID se nenhum partiu.
func _run_until_travelling(game: Game, merchants: Array[int], limit: int) -> int:
	for _minute: int in limit:
		game.runner.step_once()
		for trader: int in merchants:
			var caravan: CaravanReplies.CaravanQuery = game.economy.peek_caravan(trader)
			if caravan.found and caravan.state == Caravan.STATE_TRAVELLING:
				return trader
	return IdGenerator.NO_ID


## Tudo o que identifica a caravana na consulta, em ordem fixa (o registro salvo, sem o que o relógio recalcula).
func _caravan_fields(game: Game, trader: int) -> Array:
	var caravan: CaravanReplies.CaravanQuery = game.economy.peek_caravan(trader)
	return [caravan.found, caravan.state, caravan.origin_market_id, caravan.destination_market_id, caravan.route_ids, caravan.leg_index, caravan.current_route_id, caravan.eta_minute, caravan.progress_m, caravan.good_id, caravan.quantity, caravan.cost_paid, caravan.departed_at]


## O comerciante como o `npc` o guarda (ofício, casa, trabalho, posição, ação e necessidades) mais a conta e a carga que a `economy` guarda dele.
func _merchant_fields(game: Game, trader: int) -> Array:
	var npc: NpcModule.NpcQuery = game.npc.peek_npc(trader)
	return [npc.is_alive, npc.occupation_id, npc.settlement_id, npc.home_place_id, npc.work_place_id, npc.place_id, npc.x_cm, npc.z_cm, npc.action_id, npc.next_think_time, npc.needs_updated_at, Array(npc.need_values), game.economy.peek_balance(trader).balance, game.economy.peek_inventory(trader).rows]


func test_a_save_made_with_the_merchants_keeps_every_merchant_and_a_caravan_in_transit() -> void:
	var direct: Game = _new_game()
	var merchants: Array[int] = _merchants(direct)
	assert_eq(merchants.size(), 6, "Seis comerciantes no jogo novo.")
	var trader: int = _run_until_travelling(direct, merchants, TRIP_SEARCH_LIMIT)
	assert_ne(trader, IdGenerator.NO_ID, "Semente %d e hora do jogo novo: algum comerciante parte em viagem em até 2 dias (a premissa deste teste)." % GameAppNode.DEFAULT_WORLD_SEED)
	direct.runner.run_steps(MINUTES_ON_ROAD)
	var in_transit: Array = _caravan_fields(direct, trader)
	assert_eq([in_transit[0], in_transit[1]], [true, Caravan.STATE_TRAVELLING], "No instante de salvar a caravana segue em viagem.")
	assert_gt(in_transit[8], 0, "Já andou na estrada: há progresso na etapa.")
	assert_eq(direct.economy.peek_inventory(trader).rows.size(), 1, "O comerciante leva carga de um só bem.")
	var saved_hash: String = _hash(direct)
	var restored: Game = _load(_encode(direct))
	assert_eq(_merchants(restored), merchants, "Os mesmos seis comerciantes, com os mesmos IDs.")
	assert_eq(_caravan_fields(restored, trader), in_transit, "O registro da caravana volta igual.")
	assert_eq(restored.economy.serialize().get("caravans", []), direct.economy.serialize().get("caravans", []), "E o livro de caravanas inteiro (o que o save grava; a chave só existe com caravana).")
	for merchant: int in merchants:
		assert_eq(_merchant_fields(restored, merchant), _merchant_fields(direct, merchant), "O comerciante %d volta igual (casa, trabalho, posição, ação, conta e carga)." % merchant)
	assert_eq(_hash(restored), saved_hash, "Carregar devolve o hash do instante salvo.")
	_assert_sound(restored, 138, 6, "carregado em viagem")
	var balance_before: int = restored.economy.peek_balance(trader).balance
	var eta: int = int(in_transit[7])
	for game: Game in [direct, restored]:
		var arrived: bool = false
		for _minute: int in ARRIVAL_LIMIT:
			if not game.economy.peek_caravan(trader).found:
				arrived = true
				break
			game.runner.step_once()
		assert_true(arrived, "A caravana chega (o registro some) antes de %d minutos." % ARRIVAL_LIMIT)
		assert_eq(game.runner.world.context.clock.total_minutes(), eta, "Chega no minuto do ETA, também depois de carregar.")
	assert_eq(restored.economy.peek_inventory(trader).rows, [] as Array[Dictionary], "A carga foi entregue e vendida: o comerciante volta sem ela.")
	assert_gt(restored.economy.peek_balance(trader).balance, balance_before, "A venda pagou o comerciante.")
	assert_eq(_merchant_fields(restored, trader), _merchant_fields(direct, trader), "Conta e carga na chegada: as da execução direta.")
	_assert_sound(restored, 138, 6, "depois da chegada")
	assert_eq(_hash(restored), _hash(direct), "Na chegada o hash do jogo carregado é o da execução direta.")
	restored.runner.run_steps(AFTER_ARRIVAL)
	direct.runner.run_steps(AFTER_ARRIVAL)
	assert_eq(_hash(restored), _hash(direct), "E %d minutos depois também." % AFTER_ARRIVAL)
