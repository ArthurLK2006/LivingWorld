extends GutTest
## LW-098h2 (docs/modules/economy.md 9.15.2, casos A1 a A5): "nada de comida infinita" no comerciante. Decisão de Arthur (D1, opção E): nenhuma regra nova de alimentação em viagem; o comerciante come como todo NPC (em casa, o inventário antes do `FoodStub`, `buy` urgente),
## a viagem não o alimenta, a fome sobe em trânsito e, sem dinheiro nem comida, vale a regra de sobrevivência do mundo, inclusive a morte. O jogo é MONTADO como o real (`GameModules`, dados de `res://data`, rotas e economia reais, build de desenvolvimento) e SEM população:
## quem nasce é o comerciante que o teste cria (a montagem de `test_npc_merchant.gd`). O `consumed` é motivo de destruição do livro de bens (não é evento): sai do `serialize` da economia. A1 a A4 fecham com as duas conservações; A5 é a varredura do código de `src/` (sem mundo).

const DATA_DIR: String = "res://data"
const POSTED_ESCROW: int = 53 ## O pão que o postador de encomendas põe em cada mercado (LW-107c3, opção B: 5 pães de valor-base 10 mais 5%): o mercado retém 53 na custódia enquanto o contrato dele está aberto.
const WORLD_DIR: String = "res://data/world"
const SRC_DIR: String = "res://src"
const FOOD_STUB_FILE: String = "res://src/sim/npc/food/food_stub.gd"
const SEED: int = 98
const SETTLEMENT_A: String = "test_settlement_a"
const SETTLEMENT_B: String = "test_settlement_b"
const SETTLEMENT_C: String = "test_settlement_c"
const MARKET_A: String = "a_market_01"
const HOME_A: String = "a_home_01"
const MERCHANT: String = "merchant"
const BREAD: String = "bread"
const HUNGER: int = 0
const MINUTES_PER_HOUR: int = 60
const MORNING: int = 7 * MINUTES_PER_HOUR
const BEFORE_NOON: int = 12 * MINUTES_PER_HOUR - 5
const EVENING: int = 17 * MINUTES_PER_HOUR
const SETTLEMENTS: Array[String] = [SETTLEMENT_A, SETTLEMENT_B, SETTLEMENT_C]
## Quem pode chamar o quê em `src/` ("arquivo:função"): o consumo do inventário da economia é só da `_complete_eat`; o do estoque provisório (a chamada sem dono) e a colheita, só do `on_action_completed`; o resto é o comando de teste, e o carregar do save.
const EXPECTED_USES: Dictionary = {
	"\\.request_consume\\s*\\(": ["npc_trade.gd:_complete_eat"],
	"_economy\\.request_consume\\s*\\(": ["npc_trade.gd:_complete_eat"],
	"(?<![.\\w\"])request_consume\\s*\\(": ["food_stub.gd:on_action_completed"],
	"\"request_consume\"": ["food_stub.gd:request_consume"],
	"\\brequest_add\\s*\\(": ["food_stub.gd:on_action_completed"],
	"\"request_add\"": ["food_stub.gd:request_add"],
	"\\brequest_set_stock\\s*\\(": ["npc_module.gd:request_set_food_stock"],
	"\"request_set_stock\"": ["food_stub.gd:request_set_stock"],
	"\\breset_to_start\\s*\\(": ["npc_persistence.gd:_load_food_stock"],
	"\\bload_save\\s*\\(": ["npc_persistence.gd:_load_food_stock"],
}
const STOCK_WRITE_PATTERN: String = "(?<!\\w)_stock(\\[[^\\]]*\\])?\\s*[-+]?=[^=]"
const STOCK_WRITERS: Array = ["food_stub.gd:_init", "food_stub.gd:load_save", "food_stub.gd:request_add", "food_stub.gd:request_consume", "food_stub.gd:request_set_stock", "food_stub.gd:reset_to_start"]

var _data: NpcLifeCheck.GameData
var _places: SettlementService
var _runners: Array[SimulationRunner] = []


class Rig:
	extends RefCounted

	var runner: SimulationRunner
	var economy: EconomyModule
	var npc: NpcModule
	var hunger: NeedDef
	var market_a: int
	var market_b: int
	var arrivals: Array[CaravanArrived] = []
	var deaths: Array[SimEvent] = []


func before_all() -> void:
	_data = NpcLifeCheck.load_game_data()
	assert_eq(_data.problem, "", "Os dados reais do jogo carregam.")
	_places = SettlementService.new(_data.settlements, _data.places)


func after_each() -> void:
	for runner: SimulationRunner in _runners:
		runner.finish()
	_runners.clear()


# ---------------------------------------------------------------------------------------------------- montagem

## O jogo como o real, sem população. `spread`: pão 120 no A e 15 no B (o cenário de lucro; sem ele os preços nascem iguais e ninguém viaja). `hunger_start`: a fome inicial (-1 = a dos dados). `funds`: o saldo inicial do comerciante (-1 = o dos dados, 300). `starving`: a fome
## nasce crítica e letal em 2 h (a real leva 86 horas para matar; a viagem dura 143 minutos).
func _rig(start_minute: int, spread: bool = false, hunger_start: int = -1, funds: int = -1, starving: bool = false) -> Rig:
	var setup: NpcSetup = NpcSetup.from_dir(DATA_DIR, _places, true)
	assert_true(setup.result.ok, setup.result.message)
	setup.definitions.population = null
	if hunger_start >= 0:
		setup.need_defs[HUNGER].start_value = hunger_start
	if starving:
		setup.need_defs[HUNGER].start_value = 95
		setup.need_defs[HUNGER].weaken_after_hours = 1
		setup.need_defs[HUNGER].lethal_after_hours = 2
	var economy_setup: EconomySetup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR, true)
	for kind: OwnerKindDef in economy_setup.definitions.kinds:
		if kind.id == MERCHANT and funds >= 0:
			kind.initial_balance = funds
	var rig: Rig = Rig.new()
	rig.hunger = setup.need_defs[HUNGER]
	rig.runner = SimulationRunner.new(SEED, start_minute)
	_runners.append(rig.runner)
	var modules: GameModules = GameModules.register(rig.runner, _data.terrain, _data.points, setup, economy_setup, WorldSetup.from_dir(WORLD_DIR, _data.settlements, true))
	assert_true(modules.result.ok, modules.result.message)
	rig.runner.start_new_game()
	rig.runner.world.context.events.subscribe("CaravanArrived", func(event: SimEvent) -> void: rig.arrivals.append(event))
	rig.runner.world.context.events.subscribe("NpcDied", func(event: SimEvent) -> void: rig.deaths.append(event))
	rig.economy = modules.economy
	rig.npc = modules.npc
	rig.market_a = rig.economy.peek_market_of(SETTLEMENT_A).market_id
	rig.market_b = rig.economy.peek_market_of(SETTLEMENT_B).market_id
	if spread:
		assert_true(rig.economy.request_set_stock(rig.market_a, BREAD, 120).ok)
		assert_true(rig.economy.request_set_stock(rig.market_b, BREAD, 15).ok)
	return rig


## Cria o comerciante no local dado do A (a casa dele é a `a_home_01` e o trabalho, o mercado do A). Devolve o ID.
func _spawn(rig: Rig, place_id: String) -> int:
	var spot: Vector3 = _places.peek_place(place_id).place.position
	var spec: NpcSpec = NpcSpec.new()
	spec.name_key = "npc.name.villager"
	spec.name_number = 1
	spec.occupation_id = MERCHANT
	spec.settlement_id = SETTLEMENT_A
	spec.place_id = place_id
	spec.home_place_id = HOME_A
	spec.work_place_id = MARKET_A
	spec.x_cm = roundi(spot.x * TerrainData.CM_PER_METER)
	spec.z_cm = roundi(spot.z * TerrainData.CM_PER_METER)
	var created: NpcModule.CreateResult = rig.npc.request_create_npc(spec)
	assert_true(created.result.ok, created.result.message)
	return created.npc_id


func _run_until(rig: Rig, done: Callable, limit: int) -> bool:
	for _minute: int in limit:
		if done.call():
			return true
		rig.runner.step_once()
	return done.call()


func _now(rig: Rig) -> int:
	return rig.runner.world.context.clock.total_minutes()


func _departed(rig: Rig, merchant: int) -> bool:
	return rig.economy.peek_caravan(merchant).found


func _held(rig: Rig, owner_id: int, good_id: String) -> int:
	for row: Dictionary in rig.economy.peek_inventory(owner_id).rows:
		if row["good_id"] == good_id:
			return int(row["quantity"])
	return 0


func _hunger(rig: Rig, npc_id: int) -> int:
	return rig.npc.peek_npc(npc_id).need_values[HUNGER]


## O `consumed` do bem no livro de bens do mundo inteiro (o consumo do inventário; o teste nunca baixa estoque de mercado depois de medir).
func _consumed(rig: Rig, good_id: String) -> int:
	var goods: Dictionary = rig.economy.serialize()[EconomyModule.KEY_GOODS]
	var destroyed: Dictionary = goods[GoodsStore.KEY_DESTROYED]
	var by_reason: Dictionary = destroyed.get(good_id, {})
	return int(by_reason.get(GoodsStore.REASON_CONSUMED, 0))


## O estoque provisório de comida (`FoodStub`) dos três povoados.
func _stubs(rig: Rig) -> Array[int]:
	var stocks: Array[int] = []
	for settlement_id: String in SETTLEMENTS:
		stocks.append(rig.npc.peek_food_stock(settlement_id).stock)
	return stocks


## A fome do NPC como o estado a guarda: valor, resto da conta por hora e o minuto da última atualização (as necessidades são levadas adiante preguiçosamente, a cada pensamento).
func _need(rig: Rig, npc_id: int) -> Array[int]:
	var saved: Dictionary = rig.npc.serialize()[NpcModule.KEY_NPCS][str(npc_id)]
	var values: Variant = saved[NpcState.KEY_NEED_VALUES]
	var remainders: Variant = saved[NpcState.KEY_NEED_REMAINDERS]
	return [int(values[HUNGER]), int(remainders[HUNGER]), int(saved[NpcState.KEY_NEEDS_UPDATED_AT])]


## O que o mercado do B tem de pão e de moedas.
func _destination(rig: Rig) -> Array[int]:
	return [rig.economy.peek_stock(rig.market_b, BREAD).value, rig.economy.peek_balance(rig.market_b).balance]


## A linha do pão no livro de bens (em estoque, criado e destruído no mundo inteiro).
func _bread_book(rig: Rig) -> Dictionary:
	for row: Dictionary in rig.economy.peek_goods_conservation().rows:
		if row["good_id"] == BREAD:
			return row
	return {}


func _conserved(rig: Rig) -> bool:
	return rig.economy.peek_conservation().ok and rig.economy.peek_goods_conservation().ok and rig.economy.validate().is_empty()


# ---------------------------------------------------------------------------------------------------- A1 a A4: o jogo montado

## A1: a viagem real (a `haul` da agenda, o plano e a partida da economia) do A ao B, com a fome cruzando o nível urgente NA ESTRADA e pão na carga. Quem comesse em trânsito mexeria na carga, no `consumed`, no `FoodStub` e na conta da fome.
func test_a_merchant_in_transit_is_never_fed_by_the_trip() -> void:
	var rig: Rig = _rig(EVENING, true, 58)
	var merchant: int = _spawn(rig, MARKET_A)
	var start: Array[int] = _need(rig, merchant)
	var consumed: int = _consumed(rig, BREAD)
	var stocks: Array[int] = _stubs(rig)
	assert_true(_run_until(rig, _departed.bind(rig, merchant), 40), "Parte pela `haul`: a agenda, o plano e a partida da economia, como no jogo.")
	var trip: CaravanReplies.CaravanQuery = rig.economy.peek_caravan(merchant)
	assert_eq(trip.eta_minute - trip.departed_at, 143, "A viagem real do A ao B leva 143 minutos.")
	var cargo: int = _held(rig, merchant, BREAD)
	assert_gt(cargo, 0, "Leva pão na mochila: a carga é comida.")
	var last: int = _hunger(rig, merchant)
	var steady: bool = true
	while _now(rig) < trip.eta_minute - 1:
		rig.runner.step_once()
		steady = steady and _departed(rig, merchant) and _hunger(rig, merchant) >= last
		last = _hunger(rig, merchant)
	var end: Array[int] = _need(rig, merchant)
	assert_true(steady, "Em trânsito a caravana segue na estrada e a fome só sobe.")
	var moved: NeedMath.Advanced = NeedMath.advance(start[0], start[1], rig.hunger.rate_per_hour, end[2] - start[2])
	assert_eq([end[0], end[1]], [moved.value, moved.remainder], "A fome subiu pela conta exata do `NeedMath` (taxa por hora, sem refeição nenhuma).")
	assert_true(start[0] < rig.hunger.urgent and end[0] >= rig.hunger.urgent, "Cruzou o nível urgente na estrada, com pão na carga: a viagem não alimenta.")
	assert_eq([_held(rig, merchant, BREAD), _consumed(rig, BREAD) - consumed, _stubs(rig)], [cargo, 0, stocks], "Nenhum `consumed`, a carga intacta e o `FoodStub` igual nos três povoados.")
	rig.runner.step_once()
	assert_eq(rig.arrivals.size(), 1, "A caravana chegou no ETA (a viagem foi real).")
	assert_eq([_hunger(rig, merchant) >= last, _consumed(rig, BREAD) - consumed, _stubs(rig)], [true, 0, stocks], "A chegada também não alimenta: a fome não baixou, nenhum `consumed` desde o spawn (a partida inclusive) e o `FoodStub` igual.")
	assert_true(_conserved(rig), "As conservações de dinheiro e de bens fecham.")


## A2: em casa, a refeição sai do inventário antes do `FoodStub` (uma unidade por vez); sem pão, ela cai no `FoodStub` (a regra comum, `eat_cost` 1).
func test_a_meal_comes_from_the_inventory_before_the_foodstub() -> void:
	var rig: Rig = _rig(BEFORE_NOON)
	var merchant: int = _spawn(rig, MARKET_A)
	assert_true(rig.economy.request_transfer_goods(rig.market_a, merchant, BREAD, 3).ok)
	var stocks: Array[int] = _stubs(rig)
	var base: int = _consumed(rig, BREAD)
	var meals: Array = []
	for left: int in [2, 1, 0]:
		assert_true(_run_until(rig, func() -> bool: return _held(rig, merchant, BREAD) == left, 14 * MINUTES_PER_HOUR), "Uma refeição por vez: sobram %d pães." % left)
		meals.append([_consumed(rig, BREAD) - base, _stubs(rig)])
	assert_eq(meals, [[1, stocks], [2, stocks], [3, stocks]], "Com pão na mochila cada refeição sobe o `consumed` em 1 e o `FoodStub` fica igual.")
	assert_true(_run_until(rig, func() -> bool: return _stubs(rig) != stocks, 14 * MINUTES_PER_HOUR), "Sem pão a refeição seguinte cai no `FoodStub`.")
	assert_eq([_stubs(rig), _consumed(rig, BREAD) - base, _held(rig, merchant, BREAD)], [[stocks[0] - 1, stocks[1], stocks[2]], 3, 0], "Caiu 1 no povoado dele (`eat_cost`), os outros ficaram e o `consumed` parou nos 3 pães.")
	assert_true(_conserved(rig), "As conservações de dinheiro e de bens fecham.")


## A3: sem dinheiro (o saldo nasce 0: a compra urgente não tem como pagar), sem pão e com o `FoodStub` do povoado a zero, a fome só sobe, chega ao crítico e ele morre de `hunger` depois de `lethal_after_hours` (72). Não depende da correção do pensador da 098h0.
func test_a_merchant_without_money_or_food_starves_by_the_world_rule() -> void:
	var rig: Rig = _rig(MORNING, false, -1, 0)
	var merchant: int = _spawn(rig, MARKET_A)
	assert_true(rig.npc.request_set_food_stock(SETTLEMENT_A, 0).ok)
	var stocks: Array[int] = _stubs(rig)
	var base: int = _consumed(rig, BREAD)
	var last: int = _hunger(rig, merchant)
	var crossed: int = -1
	var dead_at: int = -1
	var rose: bool = true
	var passive: bool = true
	for _minute: int in 100 * MINUTES_PER_HOUR:
		rig.runner.step_once()
		var now: NpcModule.NpcQuery = rig.npc.peek_npc(merchant)
		if not now.is_alive:
			dead_at = _now(rig)
			break
		rose = rose and now.need_values[HUNGER] >= last
		last = now.need_values[HUNGER]
		crossed = _now(rig) if crossed < 0 and last >= rig.hunger.critical else crossed
		passive = passive and now.settlement_id == SETTLEMENT_A and not ["eat", "buy", "haul"].has(now.action_id) and not _departed(rig, merchant)
	assert_gt(dead_at, 0, "Morre dentro de 100 horas.")
	assert_eq([rig.npc.peek_npc(merchant).death_cause, rig.deaths.size()], ["hunger", 1], "Morreu de fome, a regra do mundo, sem exceção para o comerciante.")
	assert_between(dead_at - crossed, rig.hunger.lethal_after_hours * MINUTES_PER_HOUR, rig.hunger.lethal_after_hours * MINUTES_PER_HOUR + MINUTES_PER_HOUR, "A fome chegou ao crítico (%d) e a morte veio `lethal_after_hours` horas depois." % rig.hunger.critical)
	assert_true(rose and passive, "A fome só subiu: ele nunca comeu, comprou ou viajou e ficou no povoado dele.")
	assert_eq([_held(rig, merchant, BREAD), rig.economy.peek_balance(merchant).balance, _consumed(rig, BREAD) - base, _stubs(rig)], [0, 0, 0, stocks], "Sem pão, sem moeda, nenhum `consumed` e o `FoodStub` seguiu em zero (nada o encheu).")
	assert_true(_conserved(rig), "As conservações de dinheiro e de bens fecham.")


## A4: a fome letal o mata na estrada (a economia recebe a partida como a da `haul`, antes do 1º pensamento): a caravana some com o dono, nada chega ao B e a carga fica na conta fechada, sem criar nem destruir bem.
func test_a_merchant_dying_on_the_road_leaves_the_cargo_in_the_closed_account() -> void:
	var rig: Rig = _rig(EVENING, true, -1, -1, true)
	var merchant: int = _spawn(rig, MARKET_A)
	var started: CaravanReplies.StartResult = rig.economy.request_start_caravan(merchant, rig.market_a, rig.market_b, BREAD, 20)
	assert_true(started.result.ok, started.result.message)
	var cargo: int = _held(rig, merchant, BREAD)
	var purse: int = rig.economy.peek_balance(merchant).balance
	var market: Array[int] = _destination(rig)
	var book: Dictionary = _bread_book(rig)
	assert_gt(cargo, 0, "Leva pão na carga.")
	assert_true(_run_until(rig, func() -> bool: return not rig.npc.peek_npc(merchant).is_alive, started.eta_minute - _now(rig) - 1), "Morre antes do ETA, com a caravana na estrada.")
	assert_eq([rig.npc.peek_npc(merchant).death_cause, rig.economy.peek_caravan(merchant).found], ["hunger", false], "Morreu de fome e a caravana sumiu com o dono.")
	rig.runner.run_steps(started.eta_minute - _now(rig) + 10)
	var market_after_the_post: Array[int] = [market[0], market[1] - POSTED_ESCROW]
	assert_eq([rig.arrivals.size(), _destination(rig)], [0, market_after_the_post], "Nada chegou ao B: nem a carga, nem o dinheiro dela (o saldo só está menor pelo pão do postador).")
	assert_eq([_held(rig, merchant, BREAD), rig.economy.peek_balance(merchant).balance, _bread_book(rig)], [cargo, purse, book], "A carga e o saldo ficam na conta fechada do dono morto, sem criar nem destruir pão.")
	assert_true(_conserved(rig), "As conservações de dinheiro e de bens fecham.")


# ---------------------------------------------------------------------------------------------------- A5: varredura do código

func _gd_files(dir_path: String) -> Array[String]:
	var found: Array[String] = []
	for file_name: String in DirAccess.get_files_at(dir_path):
		if file_name.ends_with(".gd"):
			found.append(dir_path.path_join(file_name))
	for folder: String in DirAccess.get_directories_at(dir_path):
		found.append_array(_gd_files(dir_path.path_join(folder)))
	found.sort()
	return found


## Só as linhas de código: o que vem depois de um `#` não conta.
func _code_of(text: String) -> String:
	var kept: PackedStringArray = PackedStringArray()
	for line: String in text.split("\n"):
		var cut: int = line.find("#")
		kept.append(line if cut < 0 else line.substr(0, cut))
	return "\n".join(kept)


func _sources() -> Dictionary:
	var sources: Dictionary = {}
	for path: String in _gd_files(SRC_DIR):
		sources[path] = _code_of(FileAccess.get_file_as_string(path))
	return sources


## "arquivo:função" de cada linha de CÓDIGO que casa o padrão (a definição `func` não conta): a função é a `func` mais próxima acima da linha. Em ordem, com repetição.
func _uses(sources: Dictionary, pattern: String) -> Array:
	var matcher: RegEx = RegEx.create_from_string(pattern)
	var header: RegEx = RegEx.create_from_string("^\\s*(?:static\\s+)?func\\s+(\\w+)")
	var found: Array = []
	for path: String in sources:
		var current: String = ""
		var code: String = sources[path]
		for line: String in code.split("\n"):
			var head: RegExMatch = header.search(line)
			var text: String = line
			if head != null:
				current = head.get_string(1)
				text = line.substr(head.get_end())
			for _hit: RegExMatch in matcher.search_all(text):
				found.append("%s:%s" % [path.get_file(), current])
	found.sort()
	return found


## A5: não nasceu fonte nova de comida. Em `src/`, só a `NpcTrade._complete_eat` consome inventário da economia (`EconomyModule.request_consume`); a `request_consume` sem dono é OUTRO método, o do estoque provisório, chamada só pelo `FoodStub.on_action_completed`
## (a refeição, quando a comida não saiu do inventário) e a colheita é a única entrada por obra; o resto é o comando de teste (dev) e o carregar do save. A lista é exata: um chamador ou um gravador novo, em qualquer arquivo, derruba o teste.
func test_no_new_food_source() -> void:
	var sources: Dictionary = _sources()
	assert_gt(sources.size(), 100, "A varredura enxerga o código de `src/` (senão passaria vazia).")
	for pattern: String in EXPECTED_USES:
		assert_eq(_uses(sources, pattern), EXPECTED_USES[pattern], "Quem chama `%s` em src/." % pattern)
	var food_source: Dictionary = {FOOD_STUB_FILE: sources[FOOD_STUB_FILE]}
	assert_eq(_uses(food_source, STOCK_WRITE_PATTERN), STOCK_WRITERS, "Quem grava o estoque provisório: só estas funções do `FoodStub`.")


func test_control_the_scan_flags_a_second_caller_and_ignores_comments() -> void:
	var calling: String = "func _complete_eat() -> void:\n\t_economy.request_consume(1, \"bread\", 1)\nfunc _extra() -> void:\n\t_economy.request_consume(2, \"bread\", 1) # sem efeito\nfunc _one_liner(): _economy.request_consume (3, \"bread\", 1)\n"
	var quiet: String = "## request_consume(1) numa linha de comentário\nfunc _other() -> void:\n\tpass # request_consume(2)\n"
	var sources: Dictionary = {"res://x/npc_trade.gd": _code_of(calling), "res://x/other.gd": _code_of(quiet)}
	assert_eq(_uses(sources, "\\.request_consume\\s*\\("), ["npc_trade.gd:_complete_eat", "npc_trade.gd:_extra", "npc_trade.gd:_one_liner"], "A varredura acusa o segundo chamador, mesmo no mesmo arquivo, em função de uma linha ou com espaço antes do parêntese, e ignora comentários.")
	assert_eq(_uses({"res://x/food_stub.gd": _code_of("func _init() -> void:\n\t_stock[1] = 2\nfunc has_food() -> bool:\n\treturn _stock[1] >= 1 and _stock[1] == 2\n")}, STOCK_WRITE_PATTERN), ["food_stub.gd:_init"], "Só a gravação conta: comparar (`>=`, `==`) não é gravar.")
