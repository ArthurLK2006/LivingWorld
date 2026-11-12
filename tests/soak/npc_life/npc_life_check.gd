class_name NpcLifeCheck
extends RefCounted
## LW-068: a vida dos 100 NPCs do jogo SEM jogador, sem janela (docs/modules/npc.md, seção 12). Monta o MESMO mundo do jogo (GameModules,
## terreno, pontos e dados reais de data/), anda minuto a minuto e confere os invariantes do roadmap: todos vivos; necessidades de 0 a
## 100; FoodStub nunca negativo nem acima do teto (conferido a CADA passo); nenhum NPC parado sem ação por mais de MAX_IDLE_MIN; o
## `world.validate()` e o `validate()` do módulo limpos ao fim de cada dia; o máximo de pensamentos por passo dentro do teto (linha I5
## do backlog). Devolve um relatório com os problemas achados e com números para o relatório da tarefa (quanto tempo a comida ficou em zero,
## o maior tempo parado, o hash final). Usado pela versão curta (check_all) e pela de 30 dias (tests/soak). Código de teste: usa o relógio
## do sistema só para medir o tempo de parede.

const DATA_DIR: String = "res://data"
const WORLD_DIR: String = "res://data/world"
const GAME_VERSION: String = "0.0.1-test"
## De quanto em quanto tempo (minutos de jogo) os NPCs são amostrados. Conferir os 100 a cada passo custaria dezenas de segundos.
const SAMPLE_EVERY_MIN: int = 15
## [HIP] Maior tempo (minutos de jogo) que um NPC pode ficar sem NENHUMA ação: entre o fim de uma ação e o pensamento seguinte passam até
## o intervalo de pensamento (10 min) e a espera na fila; uma hora é folga larga. Parado por mais que isso é defeito.
const MAX_IDLE_MIN: int = 60
## Para não encher o relatório com o mesmo defeito repetido a cada passo.
const MAX_PROBLEMS: int = 30
## Quantos NPCs devem estar vivos o tempo todo (a população do jogo, data/population.json).
const EXPECTED_POPULATION: int = 132


## Terreno, pontos e assentamentos reais, lidos uma vez (cerca de meio segundo) e reaproveitados por todas as execuções.
class GameData:
	extends RefCounted

	var terrain: TerrainData
	var points: Array[PointOfInterest] = []
	var settlements: Array[Settlement] = []
	var places: Array[Place] = []
	var problem: String = ""


## Números e problemas de uma execução.
class LifeReport:
	extends RefCounted

	var problems: Array[String] = []
	var minutes: int = 0
	var state_hash: String = ""
	## Menor número de NPCs vivos em uma amostra; -1 enquanto nenhuma amostra foi conferida.
	var min_alive: int = -1
	var max_idle_min: int = 0
	var max_thinks_in_a_step: int = 0
	## Por assentamento: o menor estoque visto e quantos minutos o estoque ficou em zero.
	var food_min: Dictionary = {}
	var food_zero_minutes: Dictionary = {}
	var wall_ms: int = 0

	func summary() -> String:
		return "vida sem jogador: %d min | vivos no mínimo %d | maior tempo parado %d min | pensamentos por passo no máximo %d | comida mínima %s | minutos com comida zero %s | hash %s | %d ms | problemas %d" % [
			minutes, min_alive, max_idle_min, max_thinks_in_a_step, str(food_min), str(food_zero_minutes), state_hash.left(12), wall_ms, problems.size(),
		]


## O jogo em andamento: o runner e o módulo `npc` dele.
class Game:
	extends RefCounted

	var runner: SimulationRunner
	var npc: NpcModule


static func load_game_data() -> GameData:
	var data: GameData = GameData.new()
	var terrain_loaded: TerrainLoader.LoadResult = TerrainLoader.load_dir(WORLD_DIR)
	if not terrain_loaded.result.ok:
		data.problem = terrain_loaded.result.message
		return data
	data.terrain = terrain_loaded.terrain
	var points_loaded: PointOfInterestLoader.LoadResult = PointOfInterestLoader.load_dir(WORLD_DIR, data.terrain)
	if not points_loaded.result.ok:
		data.problem = points_loaded.result.message
		return data
	data.points = points_loaded.points
	var settlements_loaded: SettlementLoader.LoadResult = SettlementLoader.load_dir(WORLD_DIR, data.terrain)
	if not settlements_loaded.result.ok:
		data.problem = settlements_loaded.result.message
		return data
	data.settlements = settlements_loaded.settlements
	data.places = settlements_loaded.places
	return data


## Anda `days` dias de jogo e confere os invariantes. `reload_after_days` maior que zero: nesse dia salva (codec JSON), carrega num runner NOVO
## e segue dali (o hash final precisa ser o mesmo da execução direta).
static func run(data: GameData, world_seed: int, days: int, reload_after_days: int = 0) -> LifeReport:
	var report: LifeReport = LifeReport.new()
	var started_usec: int = Time.get_ticks_usec()
	var game: Game = _new_game(data, world_seed, report)
	if game == null:
		return report
	var codec: JsonSaveCodec = JsonSaveCodec.new()
	var settlement_ids: Array[String] = []
	for settlement: Settlement in data.settlements:
		settlement_ids.append(settlement.id)
	var idle_samples: Dictionary[int, int] = {}
	for minute: int in days * SimClock.MINUTES_PER_DAY:
		if reload_after_days > 0 and minute == reload_after_days * SimClock.MINUTES_PER_DAY:
			game = _reload(game, data, world_seed, codec, report)
			if game == null:
				return report
		game.runner.step_once()
		check_food(game.npc, settlement_ids, report)
		if (minute + 1) % SAMPLE_EVERY_MIN == 0:
			check_npcs(game.npc, EXPECTED_POPULATION, idle_samples, report, minute + 1)
		if (minute + 1) % SimClock.MINUTES_PER_DAY == 0:
			_check_day_end(game, report, minute + 1)
	report.minutes = game.runner.world.context.clock.total_minutes()
	report.max_thinks_in_a_step = int(game.npc.debug_summary().get("max_thinks_in_a_step", 0))
	report.state_hash = game.runner.world.state_hash()
	game.runner.finish()
	report.wall_ms = IntMath.floor_div(Time.get_ticks_usec() - started_usec, 1000)
	return report


## Estoque de comida de cada assentamento: dentro de 0 ao teto. Conta os minutos em zero e guarda o menor valor.
static func check_food(npc: NpcModule, settlement_ids: Array[String], report: LifeReport) -> void:
	for settlement_id: String in settlement_ids:
		var stock: FoodStub.StockQuery = npc.peek_food_stock(settlement_id)
		if not stock.result.ok:
			add_problem(report, "comida: %s" % stock.result.message)
			continue
		if stock.stock < 0 or stock.stock > stock.max_stock:
			add_problem(report, "comida fora da faixa: '%s' tem %d (de 0 a %d)" % [settlement_id, stock.stock, stock.max_stock])
		if not report.food_min.has(settlement_id) or stock.stock < int(report.food_min[settlement_id]):
			report.food_min[settlement_id] = stock.stock
		if stock.stock == 0:
			report.food_zero_minutes[settlement_id] = int(report.food_zero_minutes.get(settlement_id, 0)) + 1


## Amostra os NPCs: todos vivos, necessidades de 0 a 100 e nenhum parado sem ação por mais de MAX_IDLE_MIN. `idle_samples` guarda, por NPC,
## quantas amostras seguidas ele ficou sem ação.
static func check_npcs(npc: NpcModule, expected_alive: int, idle_samples: Dictionary[int, int], report: LifeReport, minute: int) -> void:
	var alive: int = 0
	for npc_id: int in npc.peek_npc_ids():
		var query: NpcModule.NpcQuery = npc.peek_npc(npc_id)
		if not query.is_alive:
			add_problem(report, "minuto %d: o NPC %d está morto (causa '%s')" % [minute, npc_id, query.death_cause])
			continue
		alive += 1
		for position: int in query.need_values.size():
			if query.need_values[position] < NpcState.VALUE_MIN or query.need_values[position] > NpcState.VALUE_MAX:
				add_problem(report, "minuto %d: o NPC %d tem a necessidade %d em %d (fora de 0 a 100)" % [minute, npc_id, position, query.need_values[position]])
		if query.action_id.is_empty():
			idle_samples[npc_id] = int(idle_samples.get(npc_id, 0)) + 1
			report.max_idle_min = maxi(report.max_idle_min, idle_samples[npc_id] * SAMPLE_EVERY_MIN)
			if idle_samples[npc_id] * SAMPLE_EVERY_MIN > MAX_IDLE_MIN:
				add_problem(report, "minuto %d: o NPC %d está sem ação há mais de %d minutos" % [minute, npc_id, MAX_IDLE_MIN])
		else:
			idle_samples[npc_id] = 0
	report.min_alive = alive if report.min_alive < 0 else mini(report.min_alive, alive)
	if alive != expected_alive:
		add_problem(report, "minuto %d: %d NPC(s) vivo(s); esperado %d" % [minute, alive, expected_alive])


static func add_problem(report: LifeReport, text: String) -> void:
	if report.problems.size() < MAX_PROBLEMS:
		report.problems.append(text)


## Jogo novo igual ao do jogo real: conjunto de dados do `npc` novo a cada execução (o FoodStub tem estado e não pode ser dividido).
static func _new_game(data: GameData, world_seed: int, report: LifeReport) -> Game:
	if not data.problem.is_empty():
		add_problem(report, "dados do jogo: %s" % data.problem)
		return null
	var setup: NpcSetup = NpcSetup.from_dir(DATA_DIR, SettlementService.new(data.settlements, data.places))
	if not setup.result.ok:
		add_problem(report, "dados do npc: %s" % setup.result.message)
		return null
	var game: Game = Game.new()
	game.runner = SimulationRunner.new(world_seed)
	var modules: GameModules = GameModules.register(game.runner, data.terrain, data.points, setup)
	if not modules.result.ok:
		add_problem(report, "módulos do jogo: %s" % modules.result.message)
		return null
	game.npc = modules.npc
	game.runner.start_new_game()
	return game


## Salva o jogo atual (codec JSON), carrega num runner NOVO com os mesmos módulos e dados novos, e descarta o antigo.
static func _reload(old: Game, data: GameData, world_seed: int, codec: JsonSaveCodec, report: LifeReport) -> Game:
	var hash_before: String = old.runner.world.state_hash()
	var decoded: DecodedSave = codec.decode(codec.encode(old.runner.capture_game(), GAME_VERSION))
	if not decoded.result.ok:
		add_problem(report, "salvar e carregar: %s" % decoded.result.message)
		return null
	var setup: NpcSetup = NpcSetup.from_dir(DATA_DIR, SettlementService.new(data.settlements, data.places))
	var restored: SimulationRunner = SimulationRunner.new(world_seed)
	var modules: GameModules = GameModules.register(restored, data.terrain, data.points, setup)
	if not modules.result.ok:
		add_problem(report, "salvar e carregar, módulos: %s" % modules.result.message)
		return null
	var loaded: Result = restored.load_game(decoded.payload)
	if not loaded.ok:
		add_problem(report, "salvar e carregar: %s" % loaded.message)
		return null
	if restored.world.state_hash() != hash_before:
		add_problem(report, "salvar e carregar: o hash do mundo carregado difere do salvo")
	old.runner.finish()
	var game: Game = Game.new()
	game.runner = restored
	game.npc = modules.npc
	return game


## Ao fim de cada dia: o mundo e o módulo sem nenhum problema de validação.
static func _check_day_end(game: Game, report: LifeReport, minute: int) -> void:
	for problem: String in game.runner.world.validate():
		add_problem(report, "fim do dia (minuto %d): world.validate: %s" % [minute, problem])
	for problem: String in game.npc.validate():
		add_problem(report, "fim do dia (minuto %d): npc.validate: %s" % [minute, problem])
