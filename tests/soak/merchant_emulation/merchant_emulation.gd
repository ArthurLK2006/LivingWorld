class_name MerchantEmulation
extends RefCounted
## LW-098h0a (docs/modules/economy.md 9.15): a EMULAÇÃO de comerciantes no jogo REAL e o custo do passo inteiro; ferramenta de teste, nada em `src/` nem em `data/`. O mundo real só terá comerciantes na 098h5, e os aceites da 098h0, 098h3a e 098h3b
## precisam deles. Monta o jogo como o `GameApp` monta (dados de `res://data`; a mesma sequência do `tools/measure_economy` com semente), cria N comerciantes pela API pública do `npc` (2 por povoado, no mercado, na primeira casa que JÁ existe; a agenda
## `haul` e o saldo do tipo de dono `merchant` vêm dos dados do ofício), roda D dias e devolve, por comerciante, vivo ou morto, a fome máxima, as horas em fome crítica, as chegadas e o lucro; as conservações de dinheiro e de bens de cada dia; e o custo
## do PASSO inteiro de 1 minuto. A diferença de preço "Q7" (`spread`) vai nos `initial_stock` das definições, em memória, ANTES de o jogo começar: `request_set_stock` só existe em build de depuração (`ECON_DEV_ONLY`), e a primeira medição em release
## rodou com o preço real achando que era a Q7. Uma emulação, uma execução (`run` assina a chegada de caravanas e não se repete). Usa o relógio do sistema só para medir (código de teste).

const OCCUPATION: String = "merchant"
const NAME_KEY: String = "npc.name.villager"
## O número do nome entra no `state_hash`; o mesmo da medição de 17/11/2026, para o hash de 6 comerciantes poder ser comparado com o dela. A apresentação nunca roda aqui.
const NAME_NUMBER: int = 1
const NEED_HUNGER: String = "hunger"
const ARRIVED_EVENT: String = "CaravanArrived"
const SPREAD_NONE: String = "none"
const SPREAD_Q7: String = "q7"
## [HIP] A diferença "Q7" da medição de 17/11/2026: o estoque inicial de pão, lã e madeira rotacionado entre os povoados (ordem alfabética: A, B, C), tudo dentro do teto de compra.
const Q7_STOCKS: Dictionary[String, Array] = {"bread": [90, 30, 60], "wool": [20, 40, 10], "wood": [30, 10, 50]}
## Um quadro a 60 por segundo e o limite da DEC-119, em microssegundos.
const FRAME_USEC: int = 16700
const PEAK_USEC: int = 33000
const USEC_PER_MS: float = 1000.0
const USEC_PER_S: float = 1000000.0

var host: SimulationHostNode
var runner: SimulationRunner
var economy: EconomyModule
var npc: NpcModule
var places: SettlementService
## Os povoados em ordem alfabética: os comerciantes e a Q7 seguem esta ordem.
var settlements: Array[String] = []
var rows: Array[Row] = []


class Row:
	extends RefCounted

	var npc_id: int
	var settlement_id: String
	var alive: bool = true
	var death_minute: int = -1
	var death_cause: String = ""
	var hunger_max: int = 0
	var critical_minutes: int = 0
	var arrivals: int = 0
	var profit: int = 0

	func _init(id_of_npc: int, id_of_settlement: String) -> void:
		npc_id = id_of_npc
		settlement_id = id_of_settlement

	## Um minuto de observação. O valor é o da última atualização das necessidades do NPC (ele a faz ao pensar, e não pensa em trânsito). Morto não conta mais fome.
	func observe(query: NpcModule.NpcQuery, hunger_index: int, minute: int) -> void:
		if not alive:
			return
		if not query.is_alive:
			alive = false
			death_minute = minute
			death_cause = query.death_cause
			return
		hunger_max = maxi(hunger_max, query.need_values[hunger_index])
		critical_minutes += 1 if query.need_urgencies[hunger_index] >= NeedMath.URGENCY_CRITICAL else 0

	## A morte sai como `d<dia>_<hh>:<mm>` (dia = minuto total dividido por 1440, a convenção do diagnóstico de 17/11/2026: `d9_01:22`).
	func describe() -> String:
		var day: int = IntMath.floor_div(death_minute, SimClock.MINUTES_PER_DAY)
		var in_day: int = death_minute - day * SimClock.MINUTES_PER_DAY
		var died: String = "-" if alive else "d%d_%02d:%02d" % [day, IntMath.floor_div(in_day, SimClock.MINUTES_PER_HOUR), in_day % SimClock.MINUTES_PER_HOUR]
		return "MERCHANT id=%d settlement=%s alive=%s death=%s cause=%s hunger_max=%d critical_hours=%.1f arrivals=%d profit=%d" % [npc_id, settlement_id, alive, died, death_cause if death_cause != "" else "-", hunger_max, float(critical_minutes) / SimClock.MINUTES_PER_HOUR, arrivals, profit]


class Report:
	extends RefCounted

	var rows: Array[MerchantEmulation.Row] = []
	var steps_usec: PackedInt64Array = PackedInt64Array()
	var money_ok: bool = true
	var goods_ok: bool = true
	var checks: int = 0
	var validate_problems: int = 0
	var state_hash: String = ""

	func alive_count() -> int:
		return rows.filter(func(row: MerchantEmulation.Row) -> bool: return row.alive).size()

	func arrivals() -> int:
		return rows.reduce(func(total: int, row: MerchantEmulation.Row) -> int: return total + row.arrivals, 0)

	func profit() -> int:
		return rows.reduce(func(total: int, row: MerchantEmulation.Row) -> int: return total + row.profit, 0)

	func total_usec() -> int:
		var total: int = 0
		for usec: int in steps_usec:
			total += usec
		return total

	## Posto (de 0 a 1) pelo método do posto mais próximo, sobre o custo de cada passo.
	func percentile_usec(fraction: float) -> int:
		if steps_usec.is_empty():
			return 0
		var sorted: PackedInt64Array = steps_usec.duplicate()
		sorted.sort()
		return sorted[clampi(ceili(fraction * sorted.size()) - 1, 0, sorted.size() - 1)]

	func steps_over(limit_usec: int) -> int:
		var count: int = 0
		for usec: int in steps_usec:
			count += 1 if usec > limit_usec else 0
		return count

	## A conferência passou: dinheiro e bens conservados a cada dia e `validate()` vazio.
	func is_sound() -> bool:
		return money_ok and goods_ok and validate_problems == 0

	func summary() -> String:
		var lines: PackedStringArray = PackedStringArray()
		for row: MerchantEmulation.Row in rows:
			lines.append(row.describe())
		lines.append("SUMMARY alive_merchants=%d/%d arrivals=%d profit=%d money_conserved=%s goods_conserved=%s conservation_checks=%d validate_problems=%d state_hash=%s" % [alive_count(), rows.size(), arrivals(), profit(), money_ok, goods_ok, checks, validate_problems, state_hash])
		lines.append("STEPS n=%d total_s=%.3f median_ms=%.3f p95_ms=%.3f p99_ms=%.3f max_ms=%.3f over_16_7ms=%d over_33ms=%d" % [steps_usec.size(), total_usec() / MerchantEmulation.USEC_PER_S, percentile_usec(0.5) / MerchantEmulation.USEC_PER_MS, percentile_usec(0.95) / MerchantEmulation.USEC_PER_MS, percentile_usec(0.99) / MerchantEmulation.USEC_PER_MS, percentile_usec(1.0) / MerchantEmulation.USEC_PER_MS, steps_over(MerchantEmulation.FRAME_USEC), steps_over(MerchantEmulation.PEAK_USEC)])
		return "\n".join(lines)


## Monta o jogo novo com a semente dada e a diferença de preço `spread` (`none` ou `q7`). Devolve o erro, ou "" se deu certo.
func start(world_seed: int, spread: String) -> String:
	if spread != SPREAD_NONE and spread != SPREAD_Q7:
		return "spread '%s' inválido; esperado '%s' ou '%s'" % [spread, SPREAD_NONE, SPREAD_Q7]
	var terrain: TerrainLoader.LoadResult = TerrainLoader.load_dir(GameAppNode.TERRAIN_DIR)
	if not terrain.result.ok:
		return "terreno: " + terrain.result.message
	var points: PointOfInterestLoader.LoadResult = PointOfInterestLoader.load_dir(GameAppNode.TERRAIN_DIR, terrain.terrain)
	var loaded: SettlementLoader.LoadResult = SettlementLoader.load_dir(GameAppNode.TERRAIN_DIR, terrain.terrain)
	places = SettlementService.new(loaded.settlements, loaded.places)
	var is_development: bool = OS.is_debug_build()
	var npc_setup: NpcSetup = NpcSetup.from_dir(GameAppNode.NPC_DATA_DIR, places, is_development)
	var world_setup: WorldSetup = WorldSetup.from_dir(GameAppNode.TERRAIN_DIR, loaded.settlements, is_development)
	var economy_setup: EconomySetup = EconomySetup.from_dir(EconomySetup.DEFAULT_DIR, is_development)
	for result: Result in [points.result, loaded.result, npc_setup.result, world_setup.result, economy_setup.result]:
		if not result.ok:
			return "dados: " + result.message
	for settlement: Settlement in loaded.settlements:
		settlements.append(settlement.id)
	settlements.sort()
	if spread == SPREAD_Q7:
		for target: MarketTargetDef in economy_setup.definitions.market_targets:
			if Q7_STOCKS.has(target.good_id):
				target.initial_stock = Q7_STOCKS[target.good_id][settlements.find(target.settlement_id) % Q7_STOCKS[target.good_id].size()]
	host = SimulationHostNode.new()
	host.start_new_game(world_seed, terrain.terrain, points.points, npc_setup, GameAppNode.NEW_GAME_START_MINUTE, economy_setup, world_setup)
	if host.economy == null or host.npc == null:
		return "o jogo começou sem os módulos economy e npc"
	runner = host.runner
	economy = host.economy
	npc = host.npc
	return ""


## Cria `count` comerciantes, um por vez nos povoados em ordem (2 por povoado com 3 povoados e 6 comerciantes). Devolve o erro, ou "".
func create_merchants(count: int) -> String:
	for index: int in count:
		var site: String = settlements[index % settlements.size()]
		var market: Place = places.peek_places_of_kind(site, Place.KIND_MARKET).places[0]
		var spec: NpcSpec = NpcSpec.new()
		spec.name_key = NAME_KEY
		spec.name_number = NAME_NUMBER
		spec.occupation_id = OCCUPATION
		spec.settlement_id = site
		spec.place_id = market.id
		spec.work_place_id = market.id
		spec.home_place_id = places.peek_places_of_kind(site, Place.KIND_HOME).places[0].id
		spec.x_cm = roundi(market.position.x * TerrainData.CM_PER_METER)
		spec.z_cm = roundi(market.position.z * TerrainData.CM_PER_METER)
		var created: NpcModule.CreateResult = npc.request_create_npc(spec)
		if not created.result.ok:
			return created.result.message
		rows.append(Row.new(created.npc_id, site))
	return ""


## Roda `days` dias de 1 minuto por passo. O relógio mede SÓ o `step_once`; a observação dos comerciantes e a conferência do fim do dia ficam fora do passo.
func run(days: int) -> Report:
	var report: Report = Report.new()
	report.rows = rows
	var by_id: Dictionary[int, Row] = {}
	for row: Row in rows:
		by_id[row.npc_id] = row
	runner.world.context.events.subscribe(ARRIVED_EVENT, func(event: SimEvent) -> void:
		var arrived: CaravanArrived = event as CaravanArrived
		if by_id.has(arrived.trader_id):
			by_id[arrived.trader_id].arrivals += 1
			by_id[arrived.trader_id].profit += arrived.revenue - arrived.cost_paid)
	var hunger: int = npc.peek_need_ids().find(NEED_HUNGER)
	report.steps_usec.resize(days * SimClock.MINUTES_PER_DAY)
	for step: int in report.steps_usec.size():
		var started: int = Time.get_ticks_usec()
		runner.step_once()
		report.steps_usec[step] = Time.get_ticks_usec() - started
		for row: Row in rows:
			row.observe(npc.peek_npc(row.npc_id), hunger, runner.world.context.clock.total_minutes())
		if (step + 1) % SimClock.MINUTES_PER_DAY == 0:
			report.checks += 1
			report.money_ok = report.money_ok and economy.peek_conservation().ok
			report.goods_ok = report.goods_ok and economy.peek_goods_conservation().ok
	report.validate_problems = runner.world.validate().size()
	report.state_hash = runner.world.state_hash()
	return report


func finish() -> void:
	runner.finish()
	host.free()
