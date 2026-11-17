extends GutTest
## LW-098h4 (docs/modules/economy.md, 9.15.5): as colunas de comerciantes do `tools/measure_economy` (`MerchantCells`) num jogo MONTADO como o real (`GameModules`, dados de `res://data`, build de desenvolvimento,
## a montagem de `test_npc_merchant_arrival.gd`) e SEM a população dos dados: quem nasce é quem o teste cria. Cobre: sem comerciante tudo vale 0 e a fome de quem não é comerciante não entra; com cinco comerciantes
## (duas viagens com lucro, uma com prejuízo, uma caravana `held` e um parado) as células batem com a economia e o `npc`; viagens e lucro acumulam (SOMAM) os `CaravanArrived` REAIS (o prejuízo conta a viagem e não o lucro);
## quem morre sai de `vivos`, de `em viagem` e da maior fome; ler as células não muda o estado. As células saem na ordem: vivos, em viagem, `held`, viagens, lucro e maior fome.

const DATA_DIR: String = "res://data"
const WORLD_DIR: String = "res://data/world"
const SEED: int = 98
const SETTLEMENT_A: String = "test_settlement_a"
const SETTLEMENT_B: String = "test_settlement_b"
const SETTLEMENT_C: String = "test_settlement_c"
const MARKET_A: String = "a_market_01"
const MARKET_B: String = "b_market_01"
const HOME_A: String = "a_home_01"
const FARM_A: String = "a_work_01"
const ROUTE_A_C: String = "route_a_c"
const ROUTE_B_C: String = "route_b_c"
const MERCHANT: String = "merchant"
const FARMER: String = "farmer"
const BREAD: String = "bread"
const HUNGER: int = 0
const MORNING: int = 7 * 60
const EVENING: int = 17 * 60
const NAMES: Array[String] = ["merchants_alive", "merchants_travelling", "merchants_held", "merchants_trips", "merchants_profit", "merchants_hunger_max"]

var _data: NpcLifeCheck.GameData
var _places: SettlementService
var _runners: Array[SimulationRunner] = []


class Rig:
	extends RefCounted

	var runner: SimulationRunner
	var setup: NpcSetup
	var economy: EconomyModule
	var npc: NpcModule
	var world: WorldModule
	var cells: MerchantCells
	var market_a: int
	var market_b: int
	var market_c: int
	var arrivals: Array[CaravanArrived] = []


func before_all() -> void:
	_data = NpcLifeCheck.load_game_data()
	assert_eq(_data.problem, "", "Os dados reais do jogo carregam.")
	_places = SettlementService.new(_data.settlements, _data.places)


func after_each() -> void:
	for runner: SimulationRunner in _runners:
		runner.finish()
	_runners.clear()


# ---------------------------------------------------------------------------------------------------- montagem

## O jogo como o real, sem população, com pão 120 no A e 15 no B (A para B dá lucro; B para A dá prejuízo). `deadly`: a fome crítica mata em 2 h. As células nascem logo depois do início, como no `measure_economy`.
func _rig(start_minute: int, deadly: bool = false) -> Rig:
	var rig: Rig = Rig.new()
	rig.setup = NpcSetup.from_dir(DATA_DIR, _places, true)
	assert_true(rig.setup.result.ok, rig.setup.result.message)
	rig.setup.definitions.population = null
	if deadly:
		rig.setup.need_defs[HUNGER].weaken_after_hours = 1
		rig.setup.need_defs[HUNGER].lethal_after_hours = 2
	rig.runner = SimulationRunner.new(SEED, start_minute)
	_runners.append(rig.runner)
	var modules: GameModules = GameModules.register(rig.runner, _data.terrain, _data.points, rig.setup, EconomySetup.from_dir(EconomySetup.DEFAULT_DIR, true), WorldSetup.from_dir(WORLD_DIR, _data.settlements, true))
	assert_true(modules.result.ok, modules.result.message)
	rig.runner.start_new_game()
	var events: EventBus = rig.runner.world.context.events
	events.subscribe("CaravanArrived", func(event: SimEvent) -> void: rig.arrivals.append(event))
	rig.cells = MerchantCells.new(modules.npc, modules.economy, events)
	rig.economy = modules.economy
	rig.npc = modules.npc
	rig.world = modules.world
	rig.market_a = rig.economy.peek_market_of(SETTLEMENT_A).market_id
	rig.market_b = rig.economy.peek_market_of(SETTLEMENT_B).market_id
	rig.market_c = rig.economy.peek_market_of(SETTLEMENT_C).market_id
	assert_true(rig.economy.request_set_stock(rig.market_a, BREAD, 120).ok)
	assert_true(rig.economy.request_set_stock(rig.market_b, BREAD, 15).ok)
	return rig


## Cria um NPC no local dado, com a casa no A e a fome inicial pedida (muda o `start_value` das definições, que o módulo compartilha). Devolve o ID.
func _spawn(rig: Rig, occupation_id: String, settlement_id: String, place_id: String, work_place_id: String, hunger: int) -> int:
	rig.setup.need_defs[HUNGER].start_value = hunger
	var spot: Vector3 = _places.peek_place(place_id).place.position
	var spec: NpcSpec = NpcSpec.new()
	spec.name_key = "npc.name.villager"
	spec.name_number = 1
	spec.occupation_id = occupation_id
	spec.settlement_id = settlement_id
	spec.place_id = place_id
	spec.home_place_id = HOME_A
	spec.work_place_id = work_place_id
	spec.x_cm = roundi(spot.x * TerrainData.CM_PER_METER)
	spec.z_cm = roundi(spot.z * TerrainData.CM_PER_METER)
	var created: NpcModule.CreateResult = rig.npc.request_create_npc(spec)
	assert_true(created.result.ok, created.result.message)
	assert_eq(rig.npc.peek_npc(created.npc_id).need_values[HUNGER], hunger, "O NPC nasce com a fome pedida.")
	return created.npc_id


## O comerciante parte do mercado de origem ao de destino com pão, pela porta da economia (sem plano): devolve o ETA.
func _depart(rig: Rig, merchant: int, from_market: int, to_market: int, quantity: int) -> int:
	var started: CaravanReplies.StartResult = rig.economy.request_start_caravan(merchant, from_market, to_market, BREAD, quantity)
	assert_true(started.result.ok, started.result.message)
	return started.eta_minute


## Fecha a rota no `world` e entrega o `RouteStateChanged` agora, sem passo (como `test_economy_caravan_route_state.gd`): nenhum minuto anda e nenhum NPC pensa.
func _close_route(rig: Rig, route_id: String) -> void:
	assert_true(rig.world.request_close_route(route_id).ok)
	rig.runner.world.context.events.dispatch()


func _now(rig: Rig) -> int:
	return rig.runner.world.context.clock.total_minutes()


## As seis células de agora como inteiros, na ordem das colunas.
func _numbers(rig: Rig) -> Array[int]:
	var numbers: Array[int] = []
	for cell: String in rig.cells.row():
		numbers.append(int(cell))
	return numbers


func _hunger_of(rig: Rig, npc_id: int) -> int:
	return rig.npc.peek_npc(npc_id).need_values[HUNGER]


# ---------------------------------------------------------------------------------------------------- o que a ferramenta imprime

func test_the_columns_are_the_six_named_ones_in_order_and_each_row_has_one_cell_per_column() -> void:
	var rig: Rig = _rig(MORNING)
	assert_eq(MerchantCells.COLUMNS, NAMES, "Os nomes e a ordem que o relatório da 098h6 lê.")
	assert_eq(rig.cells.row().size(), NAMES.size(), "Uma célula por coluna, nem uma a mais nem a menos.")


## O ofício `merchant` é um literal da classe (o `npc` não expõe o `owner_kind` do ofício): esta guarda confere nos dados de hoje que ele é o ÚNICO ofício de comerciante.
func test_the_merchant_literal_is_the_only_occupation_of_the_merchant_owner_kind_in_the_data() -> void:
	var rows: Array = JSON.parse_string(FileAccess.get_file_as_string(DATA_DIR + "/occupations.json"))
	var merchant_ids: Array[String] = []
	for row: Dictionary in rows:
		if row.get("owner_kind", "") == EconomyModule.KIND_MERCHANT:
			merchant_ids.append(str(row["id"]))
	assert_eq(merchant_ids, [MerchantCells.OCCUPATION_ID], "Nos dados, o único ofício de dono merchant é o literal que a classe conta.")


func test_a_game_without_merchants_reads_zero_even_with_a_hungry_non_merchant() -> void:
	var rig: Rig = _rig(MORNING)
	var farmer: int = _spawn(rig, FARMER, SETTLEMENT_A, MARKET_A, FARM_A, 80)
	assert_eq(_numbers(rig), [0, 0, 0, 0, 0, 0] as Array[int], "Sem comerciante tudo vale 0; a fome 80 do lavrador não entra.")
	rig.runner.run_steps(120)
	assert_gt(_hunger_of(rig, farmer), 0, "O lavrador segue com fome: o zero acima não é falta de fome.")
	assert_eq(_numbers(rig), [0, 0, 0, 0, 0, 0] as Array[int], "Duas horas depois, com o lavrador vivo e agindo, tudo segue 0.")


func test_the_cells_count_alive_travelling_held_trips_profit_and_the_hunger_of_merchants_only() -> void:
	var rig: Rig = _rig(MORNING)
	var first: int = _spawn(rig, MERCHANT, SETTLEMENT_A, MARKET_A, MARKET_A, 30)
	var losing: int = _spawn(rig, MERCHANT, SETTLEMENT_B, MARKET_B, MARKET_B, 60)
	var parked: int = _spawn(rig, MERCHANT, SETTLEMENT_A, MARKET_A, MARKET_A, 45)
	var idle: int = _spawn(rig, MERCHANT, SETTLEMENT_B, MARKET_B, MARKET_B, 20)
	var second: int = _spawn(rig, MERCHANT, SETTLEMENT_A, MARKET_A, MARKET_A, 35)
	_spawn(rig, FARMER, SETTLEMENT_A, MARKET_A, FARM_A, 80)
	var eta: int = _depart(rig, first, rig.market_a, rig.market_b, 2)
	assert_eq([_depart(rig, losing, rig.market_b, rig.market_a, 2), _depart(rig, second, rig.market_a, rig.market_b, 3)], [eta, eta] as Array[int], "As três viagens do A-B (uma no sentido contrário) chegam no mesmo minuto.")
	_depart(rig, parked, rig.market_a, rig.market_c, 2)
	_close_route(rig, ROUTE_B_C)
	_close_route(rig, ROUTE_A_C)
	assert_eq([rig.economy.peek_caravan(first).state, rig.economy.peek_caravan(losing).state, rig.economy.peek_caravan(parked).state, rig.economy.peek_caravan(second).state, rig.economy.peek_caravan(idle).found], ["travelling", "travelling", "held", "travelling", false] as Array, "Sem caminho aberto ao C, só a caravana do A ao C ficou parada.")
	var before: String = rig.runner.world.state_hash()
	assert_eq(_numbers(rig), [5, 3, 1, 0, 0, 60] as Array[int], "5 vivos; 3 em viagem e 1 `held` (separados); nenhuma viagem; a maior fome é a do comerciante de 60, não a do lavrador de 80.")
	assert_eq(rig.runner.world.state_hash(), before, "Ler as células não muda o estado.")
	rig.runner.run_steps(eta - _now(rig))
	assert_eq(rig.arrivals.size(), 3, "As três viagens do A-B chegaram.")
	var profit: int = 0
	for arrived: CaravanArrived in rig.arrivals:
		if arrived.trader_id == losing:
			assert_lt(arrived.revenue, arrived.cost_paid, "A do B ao A deu prejuízo.")
		else:
			assert_gt(arrived.revenue, arrived.cost_paid, "As duas do A ao B deram lucro realizado.")
			profit += arrived.revenue - arrived.cost_paid
	assert_false(rig.economy.peek_caravan(idle).found, "O parado não saiu por conta própria.")
	var expected_hunger: int = 0
	for merchant: int in [first, losing, parked, idle, second]:
		expected_hunger = maxi(expected_hunger, _hunger_of(rig, merchant))
	assert_eq(_numbers(rig), [5, 0, 1, 3, profit, expected_hunger] as Array[int], "Três viagens concluídas; o lucro SOMA as duas boas e o prejuízo não entra; sobra a caravana `held`.")
	assert_gt(expected_hunger, 60, "Em viagem a fome subiu: a coluna acompanha o dia seguinte.")


func test_a_merchant_who_dies_on_the_road_leaves_alive_travelling_and_the_highest_hunger() -> void:
	var rig: Rig = _rig(EVENING, true)
	var victim: int = _spawn(rig, MERCHANT, SETTLEMENT_A, MARKET_A, MARKET_A, 95)
	var survivor: int = _spawn(rig, MERCHANT, SETTLEMENT_B, MARKET_B, MARKET_B, 30)
	var eta: int = _depart(rig, victim, rig.market_a, rig.market_b, 1)
	assert_eq(_numbers(rig), [2, 1, 0, 0, 0, 95] as Array[int], "Os dois vivos, um em viagem; a maior fome é a de 95.")
	for _minute: int in eta - EVENING - 1:
		if not rig.npc.peek_npc(victim).is_alive:
			break
		rig.runner.run_steps(1)
	assert_false(rig.npc.peek_npc(victim).is_alive, "Em viagem ele não age e a fome crítica o mata em 2 h, antes do ETA.")
	assert_true(rig.npc.peek_npc(survivor).is_alive and not rig.economy.peek_caravan(survivor).found, "O outro segue vivo e parado.")
	assert_gte(_hunger_of(rig, victim), 95, "O morto continua com a fome alta no estado.")
	assert_eq(_numbers(rig), [1, 0, 0, 0, 0, _hunger_of(rig, survivor)] as Array[int], "O morto sai de vivos, de em viagem (a caravana some com ele) e da maior fome; sem chegada, sem viagem.")
