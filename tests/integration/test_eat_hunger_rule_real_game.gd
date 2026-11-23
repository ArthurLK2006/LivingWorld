extends GutTest
## LW-094 (B8, regra da refeição por DADO; autorização de Arthur de 21/11/2026, só em ramo isolado): o jogo REAL (dados de `res://data`, economia e rotas, semente e hora do
## jogo novo do `GameApp`) com a condição `eat_hungry` (fome de 40 ou mais para a `eat` começar). Prova: (1) em 3 dias cada NPC faz as refeições que a necessidade pede (cerca de 2
## por dia; sem a regra eram 8 no 1º dia) e ninguém passa fome crítica tendo comida e dinheiro; (2) determinismo; (3) saves: salvar no meio e carregar dá o MESMO hash do fim direto, um
## save feito ANTES da regra (montado em memória, sem a condição) carrega nos dados de hoje e o formato do save não ganha nem perde chave. Cada save passa pelo codec JSON (bytes)
## como o do jogo. O save de `tests/fixtures/` (versão 1, sem NPC) continua coberto por `test_save_codec.gd`. As medições de subalimentação (7 dias, limiares 40 e 60, com e sem
## FoodStub) estão no pacote da tarefa, não aqui.

const DATA_DIR: String = "res://data"
const WORLD_DIR: String = "res://data/world"
const GAME_VERSION: String = "0.0.1-test"
const DAY: int = SimClock.MINUTES_PER_DAY
const HALF_DAY: int = 12 * SimClock.MINUTES_PER_HOUR
const OBSERVED_DAYS: int = 3
const HUNGER: int = 0
## O limiar do dado `eat_hungry` e a fome crítica de data/needs.json.
const THRESHOLD: int = 40
const CRITICAL: int = 90
## Preço-base do grão, a comida mais barata (data/economy/goods.json): com menos dinheiro que isso o NPC não compra nada.
const MIN_MONEY: int = 4
const FOODS: Array[String] = ["grain", "bread"]
## [HIP] A necessidade é de 120 de fome por dia (5 por hora) para 60 por refeição: 2 refeições por dia. A faixa deixa folga para a 1ª refeição do dia 1 (a fome nasce em 20 e o
## jogo começa às 5h45) e para os dias com 3 blocos de `eat`; sem a regra a média do dia 1 era 8,1 (diagnóstico da LW-094).
const MEALS_PER_NPC_DAY_MIN: float = 1.5
const MEALS_PER_NPC_DAY_MAX: float = 3.0
const MAX_MEALS_ONE_NPC_ONE_DAY: int = 4

var _data: NpcLifeCheck.GameData
var _rate: int = 0
var _runners: Array[SimulationRunner] = []


class Game:
	extends RefCounted

	var runner: SimulationRunner
	var npc: NpcModule
	var economy: EconomyModule


func before_all() -> void:
	_data = NpcLifeCheck.load_game_data()
	assert_eq(_data.problem, "", "Os dados reais do jogo carregam.")
	_rate = NeedLoader.load_dir().needs[HUNGER].rate_per_hour


func after_each() -> void:
	for runner: SimulationRunner in _runners:
		runner.finish()
	_runners.clear()


# ---------------------------------------------------------------------------------------------------- montagem

## O jogo montado como o `GameApp` monta. `with_rule` falso: o mundo ANTIGO, sem a condição `need_at_least` da `eat` (só `has_food`), exatamente os dados de antes da regra.
func _build(with_rule: bool) -> Game:
	var setup: NpcSetup = NpcSetup.from_dir(DATA_DIR, SettlementService.new(_data.settlements, _data.places))
	assert_true(setup.result.ok, setup.result.message)
	if not with_rule:
		for action: ActionDef in setup.definitions.actions:
			if action.id == "eat":
				var kept: Array[ActionDef.ActionCondition] = []
				for condition: ActionDef.ActionCondition in action.conditions:
					if condition.kind != ActionDef.CONDITION_NEED_AT_LEAST:
						kept.append(condition)
				assert_eq(kept.size(), action.conditions.size() - 1, "Existe exatamente uma condição de fome para tirar.")
				action.conditions = kept
	var game: Game = Game.new()
	game.runner = SimulationRunner.new(GameAppNode.DEFAULT_WORLD_SEED, GameAppNode.NEW_GAME_START_MINUTE)
	_runners.append(game.runner)
	var modules: GameModules = GameModules.register(game.runner, _data.terrain, _data.points, setup, EconomySetup.from_dir(EconomySetup.DEFAULT_DIR), WorldSetup.from_dir(WORLD_DIR, _data.settlements))
	assert_true(modules.result.ok, modules.result.message)
	game.npc = modules.npc
	game.economy = modules.economy
	return game


func _new_game(with_rule: bool = true) -> Game:
	var game: Game = _build(with_rule)
	game.runner.start_new_game()
	return game


func _encode(game: Game) -> PackedByteArray:
	assert_true(game.runner.can_capture_game(), "Só se salva entre passos, com a fila de eventos vazia.")
	return JsonSaveCodec.new().encode(game.runner.capture_game(), GAME_VERSION)


func _load(bytes: PackedByteArray, with_rule: bool = true) -> Game:
	var decoded: DecodedSave = JsonSaveCodec.new().decode(bytes)
	assert_true(decoded.result.ok, decoded.result.message)
	var game: Game = _build(with_rule)
	var loaded: Result = game.runner.load_game(decoded.payload)
	assert_true(loaded.ok, loaded.message)
	return game


func _hash(game: Game) -> String:
	return game.runner.world.state_hash()


func _assert_sound(game: Game, label: String) -> void:
	var counts: Dictionary = game.npc.peek_counts()
	assert_eq([counts[NpcModule.COUNT_ALIVE], counts[NpcModule.COUNT_DEAD]], [138, 0], "%s: todos vivos." % label)
	assert_eq(game.runner.world.validate() + game.npc.validate(), [] as Array[String], "%s: validate vazio." % label)
	assert_true(game.economy.peek_conservation().ok, "%s: o dinheiro se conserva." % label)
	assert_true(game.economy.peek_goods_conservation().ok, "%s: os bens se conservam." % label)


## Comida ou meios de comprar? Mochila ou estoque do assentamento com comida; senão, dinheiro para o grão e comida no mercado do assentamento.
func _has_means(game: Game, npc_id: int, settlement_id: String) -> bool:
	for row: Dictionary in game.economy.peek_inventory(npc_id).rows:
		if FOODS.has(str(row["good_id"])) and int(row["quantity"]) > 0:
			return true
	var settlement_food: FoodStub.StockQuery = game.npc.peek_food_stock(settlement_id)
	if settlement_food.result.ok and settlement_food.stock > 0:
		return true
	if game.economy.peek_balance(npc_id).balance < MIN_MONEY:
		return false
	var market: EconomyReplies.MarketQuery = game.economy.peek_market_of(settlement_id)
	if not market.result.ok:
		return false
	for good_id: String in FOODS:
		if game.economy.peek_stock(market.market_id, good_id).value > 0:
			return true
	return false


## Anda `days` dias, UM MINUTO por passo, e observa cada NPC vivo: as refeições começadas (uma ação `eat` nova = um `action_serial` novo) por NPC e por dia, a menor fome com que uma
## refeição começou e os minutos em fome crítica (total e tendo comida ou dinheiro). A fome vem projetada ao minuto (o valor guardado só muda quando o NPC pensa).
func _observe(game: Game, days: int) -> Dictionary:
	var ids: Array[int] = game.npc.peek_npc_ids()
	var clock: SimClock = game.runner.world.context.clock
	var start: int = clock.total_minutes()
	var last_serial: Dictionary = {}
	var meals: Dictionary = {}
	for npc_id: int in ids:
		var per_day: Array[int] = []
		per_day.resize(days)
		per_day.fill(0)
		meals[npc_id] = per_day
	var seen: Dictionary = {"lowest_start": 100, "meals": 0, "critical_minutes": 0, "critical_with_means": 0, "start_not_stored": 0}
	for _step: int in days * DAY:
		game.runner.step_once()
		var now: int = clock.total_minutes()
		for npc_id: int in ids:
			var q: NpcModule.NpcQuery = game.npc.peek_npc(npc_id)
			if not q.is_alive:
				continue
			if q.action_id == "eat" and last_serial.get(npc_id, -1) != q.action_serial:
				last_serial[npc_id] = q.action_serial
				meals[npc_id][IntMath.floor_div(q.action_started_at - start, DAY)] += 1
				seen["meals"] += 1
				if q.needs_updated_at != q.action_started_at:
					seen["start_not_stored"] += 1
				seen["lowest_start"] = mini(seen["lowest_start"], q.need_values[HUNGER])
			if NeedMath.advance(q.need_values[HUNGER], 0, _rate, maxi(0, now - q.needs_updated_at)).value >= CRITICAL:
				seen["critical_minutes"] += 1
				# Dentro da refeição o alívio só vem ao FIM dos 20 minutos (a fome sobe até lá): quem começa a comer com 88 passa dos 90 comendo. Isso não é passar fome.
				if q.action_id != "eat" and _has_means(game, npc_id, q.settlement_id):
					seen["critical_with_means"] += 1
	seen["per_npc_day"] = meals
	return seen


# ---------------------------------------------------------------------------------------------------- refeições, fome e consequências

func test_over_three_days_each_npc_eats_what_the_need_asks_and_nobody_is_critically_hungry_with_means() -> void:
	var game: Game = _new_game()
	_assert_sound(game, "jogo novo")
	var seen: Dictionary = _observe(game, OBSERVED_DAYS)
	_assert_sound(game, "3 dias depois")
	var per_npc_day: Dictionary = seen["per_npc_day"]
	var highest: int = 0
	for npc_id: int in per_npc_day:
		for count: int in per_npc_day[npc_id]:
			highest = maxi(highest, count)
	var average: float = float(seen["meals"]) / (per_npc_day.size() * OBSERVED_DAYS)
	assert_between(average, MEALS_PER_NPC_DAY_MIN, MEALS_PER_NPC_DAY_MAX, "Média de refeições por NPC e por dia (%.2f): a necessidade é de cerca de 2, não 8." % average)
	assert_lte(highest, MAX_MEALS_ONE_NPC_ONE_DAY, "Nenhum NPC faz mais de %d refeições em um dia (o maior fez %d)." % [MAX_MEALS_ONE_NPC_ONE_DAY, highest])
	assert_gte(seen["lowest_start"], THRESHOLD, "Nenhuma refeição começa com fome abaixo do limiar (a menor foi %d)." % seen["lowest_start"])
	assert_eq(seen["start_not_stored"], 0, "A fome guardada ao ver a refeição é a do começo dela (a medição acima é exata).")
	assert_eq(seen["critical_with_means"], 0, "Ninguém fica em fome crítica (90 ou mais) FORA da refeição tendo comida na mochila ou no assentamento, ou dinheiro e comida no mercado (minutos críticos no total, comendo inclusive: %d)." % seen["critical_minutes"])
	assert_lte(seen["critical_minutes"], seen["meals"] * 20, "Todo minuto crítico cabe dentro de uma refeição (20 minutos cada): nada de fome crítica prolongada.")


# ---------------------------------------------------------------------------------------------------- determinismo e save

func test_the_real_game_with_the_rule_is_deterministic_and_survives_a_save_and_load() -> void:
	var first: Game = _new_game()
	first.runner.run_steps(HALF_DAY)
	var saved: PackedByteArray = _encode(first)
	var saved_hash: String = _hash(first)
	first.runner.run_steps(HALF_DAY)
	var direct_hash: String = _hash(first)
	_assert_sound(first, "fim do dia, execução direta")
	var second: Game = _new_game()
	second.runner.run_steps(HALF_DAY)
	assert_eq(_encode(second), saved, "Duas execuções iguais gravam os MESMOS bytes no meio do dia.")
	second.runner.run_steps(HALF_DAY)
	assert_eq(_hash(second), direct_hash, "Duas execuções iguais dão o MESMO hash no fim.")
	var restored: Game = _load(saved)
	assert_eq(_hash(restored), saved_hash, "Carregar devolve o hash do instante salvo.")
	restored.runner.run_steps(HALF_DAY)
	assert_eq(_hash(restored), direct_hash, "Salvar no meio e carregar dá o MESMO hash do fim que a execução direta.")
	_assert_sound(restored, "fim do dia, carregado")


func test_a_save_made_before_the_rule_loads_in_todays_data_and_the_save_format_is_unchanged() -> void:
	var old_world: Game = _new_game(false)
	old_world.runner.run_steps(HALF_DAY)
	var old_bytes: PackedByteArray = _encode(old_world)
	var old_hash: String = _hash(old_world)
	var old_payload: Dictionary = old_world.runner.capture_game()
	var current: Game = _new_game()
	current.runner.run_steps(HALF_DAY)
	assert_ne(_hash(current), old_hash, "A regra muda o caminho do jogo (premissa do teste: os dois mundos divergiram em meio dia).")
	assert_eq(_format_of(current.runner.capture_game()), _format_of(old_payload), "O formato do save não muda: as mesmas chaves no topo, no módulo `npc` e em cada NPC.")
	var loaded: Game = _load(old_bytes, true)
	assert_eq(_hash(loaded), old_hash, "O save antigo carrega nos dados novos com o mesmo hash (a regra é dado, não estado).")
	_assert_sound(loaded, "save antigo carregado")
	loaded.runner.run_steps(HALF_DAY)
	_assert_sound(loaded, "meio dia depois")
	var again: Game = _load(old_bytes, true)
	again.runner.run_steps(HALF_DAY)
	assert_eq(_hash(again), _hash(loaded), "Carregar o mesmo save antigo duas vezes e andar o mesmo tempo dá o MESMO hash.")


## As chaves do save (topo, seção do `npc` e de um NPC), em ordem, para provar que o formato não mudou.
func _format_of(payload: Dictionary) -> Array:
	var section: Dictionary = payload["world"]["modules"]["npc"]
	var npcs: Variant = section["npcs"]
	var first: Dictionary = npcs[0] if npcs is Array else npcs[(npcs as Dictionary).keys()[0]]
	var shape: Array = [payload.keys(), (payload["world"] as Dictionary).keys(), (payload["world"]["modules"] as Dictionary).keys(), section.keys(), first.keys()]
	for part: Array in shape:
		part.sort()
	return shape
