class_name NpcYearMeter
extends RefCounted
## LW-084a: o medidor do soak longo (roadmap LW-084, arquitetura cap. 20): 300 NPCs [HIP] por quantos dias de jogo se pedir, SEM jogador de verdade, com a alternância
## S1 <-> S0 (o foco do ator anda em ciclo entre o povoado A, o B e um ponto longe de tudo) e um corpo FALSO que só cumpre o protocolo dos Intents (chega e termina na hora
## prevista; sem Node, sem janela). Mede o tempo de cada passo, a memória estática e os objetos de cada dia, o tamanho do save, os NPCs mortos e os com corpo, e guarda o hash.
## Os 300 NASCEM NO CÓDIGO: a capacidade dos locais e a população são multiplicadas em memória (data/ não muda). A conversa do jogador não entra aqui. Código de teste: usa o
## relógio do sistema só para medir. A versão curta (test_npc_year_short.gd) roda no check_all; a longa (soak_npc_year.gd), com tests/soak/run_npc_year.

const DATA_DIR: String = "res://data"
const GAME_VERSION: String = "0.0.1-test"
## [HIP] (DEC-040 PENDENTE): fator que leva os 100 NPCs do jogo a 300, na capacidade dos locais e na população. Só em memória.
const SCALE: int = 3
## Quantos NPCs (os primeiros por ID) viram notáveis (T2): o teto de data/npc_params.json. Só eles têm memória e relações.
const NOTABLES: int = 40
## [HIP] Padrões de alternância: quantos minutos de jogo o foco do ator fica em cada ponto de SPOTS antes de passar ao seguinte (A, B, longe, A...).
const PATTERN_BASE_MIN: int = 480
const PATTERN_STRESS_MIN: int = 30
## Povoado A, povoado B e um ponto a mais de 120 m (o raio de saída do LOD) de qualquer um dos dois, em metros.
const SPOTS: Array[Vector3] = [Vector3(320.0, 10.0, 540.0), Vector3(800.0, 10.0, 660.0), Vector3(700.0, 10.0, 960.0)]
## [HIP] Régua desta medição (decisão de Arthur, 10/11/2026; a DEC-071 é PROPOSTA): passo médio dentro de ~3 ms e nenhum passo acima de ~10 ms.
const STEP_BUDGET_USEC: int = 3000
const STEP_PEAK_USEC: int = 10000
## De quantos em quantos dias se guarda o tamanho do save e se imprime o andamento.
const SAMPLE_EVERY_DAYS: int = 30
## Chave de um Intent: npc_id * este valor + contador de ações (o contador de um NPC nunca chega perto disso num ano).
const SERIAL_STRIDE: int = 1000000
const MIB: float = 1048576.0


class Config:
	extends RefCounted

	var world_seed: int = 11
	var days: int = 1
	var leg_minutes: int = NpcYearMeter.PATTERN_BASE_MIN
	## Salva (codec JSON) e carrega num runner novo depois deste passo; 0 = não recarrega. Escolha um minuto com o foco longe: o save não guarda corpos.
	var reload_at_minute: int = 0
	var progress: bool = false


class Report:
	extends RefCounted

	var problems: Array[String] = []
	var npcs: int = 0
	var minutes: int = 0
	var state_hash: String = ""
	var wall_ms: int = 0
	## Duração de cada passo (microssegundos), pré-alocada: não pesa na memória medida.
	var step_usec: PackedInt32Array = PackedInt32Array()
	## Memória estática e objetos no começo (índice 0) e no fim de cada dia.
	var memory_by_day: PackedInt64Array = PackedInt64Array()
	var objects_by_day: PackedInt64Array = PackedInt64Array()
	var save_bytes: PackedInt64Array = PackedInt64Array()
	## O mesmo save sem comprimir (o JSON do payload), medido junto do comprimido.
	var save_raw_bytes: PackedInt64Array = PackedInt64Array()
	## No fim, de cada notável (T2) vivo: registros de memória, traços permanentes e relações.
	var notable_memories: PackedInt32Array = PackedInt32Array()
	var notable_traits: PackedInt32Array = PackedInt32Array()
	var notable_relations: PackedInt32Array = PackedInt32Array()
	var min_alive: int = -1
	var dead: int = 0
	var s0_peak: int = 0
	var s0_sum: int = 0
	var s0_entries: int = 0
	## Por módulo do agendador: execuções, tempo total e máximo (us) e execuções acima do limite.
	var modules: Dictionary = {}

	func add_problem(text: String) -> void:
		if problems.size() < NpcLifeCheck.MAX_PROBLEMS:
			problems.append(text)

	func mean_step_usec() -> float:
		var sum: int = 0
		for value: int in step_usec:
			sum += value
		return float(sum) / float(maxi(step_usec.size(), 1))

	func steps_over(limit_usec: int) -> int:
		var count: int = 0
		for value: int in step_usec:
			count += 1 if value > limit_usec else 0
		return count

	## Passo no percentil `fraction` (0 a 1); 0 sem passos.
	func percentile_usec(fraction: float) -> int:
		if step_usec.is_empty():
			return 0
		var sorted: PackedInt32Array = step_usec.duplicate()
		sorted.sort()
		return sorted[mini(sorted.size() - 1, int(float(sorted.size()) * fraction))]

	## Índice do passo mais lento (o minuto de jogo, contado do começo da execução); -1 sem passos.
	func slowest_minute() -> int:
		var slowest: int = -1
		var peak: int = -1
		for index: int in step_usec.size():
			if step_usec[index] > peak:
				peak = step_usec[index]
				slowest = index
		return slowest

	## Quanto a memória estática cresceu do começo ao fim, em bytes.
	func memory_growth() -> int:
		return 0 if memory_by_day.size() < 2 else memory_by_day[memory_by_day.size() - 1] - memory_by_day[0]

	func summary() -> String:
		var lines: Array[String] = []
		lines.append("soak: %d NPCs | %d min de jogo | %d ms de parede | vivos no mínimo %d, mortos %d | problemas %d | hash %s" % [npcs, minutes, wall_ms, min_alive, dead, problems.size(), state_hash.left(12)])
		lines.append("passo (us): média %.1f | p99,9 %d | máximo %d (passo %d) | acima de %d us: %d | acima de %d us: %d" % [mean_step_usec(), percentile_usec(0.999), percentile_usec(1.0), slowest_minute(), STEP_BUDGET_USEC, steps_over(STEP_BUDGET_USEC), STEP_PEAK_USEC, steps_over(STEP_PEAK_USEC)])
		lines.append("memória estática (MiB) a cada %d dias: %s | crescimento %.2f MiB" % [SAMPLE_EVERY_DAYS, _every(memory_by_day, MIB), float(memory_growth()) / MIB])
		lines.append("objetos a cada %d dias: %s | save comprimido (KiB): %s | save sem comprimir (KiB): %s" % [SAMPLE_EVERY_DAYS, _every(objects_by_day, 1.0), _every(save_bytes, 1024.0, 1), _every(save_raw_bytes, 1024.0, 1)])
		lines.append("%d notáveis no fim (mín/média/máx): memórias %s | traços %s | relações %s" % [notable_memories.size(), _span(notable_memories), _span(notable_traits), _span(notable_relations)])
		lines.append("corpos: pico %d | média %.1f | entradas em S0 %d" % [s0_peak, float(s0_sum) / float(maxi(minutes, 1)), s0_entries])
		for module_name: String in modules:
			lines.append("agendador, %s: %s" % [module_name, JSON.stringify(modules[module_name])])
		return "\n".join(lines)

	static func _span(values: PackedInt32Array) -> String:
		if values.is_empty():
			return "-"
		var sum: int = 0
		var lowest: int = values[0]
		var highest: int = values[0]
		for value: int in values:
			sum += value
			lowest = mini(lowest, value)
			highest = maxi(highest, value)
		return "%d/%.1f/%d" % [lowest, float(sum) / float(values.size()), highest]

	## De `step` em `step` valores, mais o último.
	static func _every(values: PackedInt64Array, unit: float, step: int = SAMPLE_EVERY_DAYS) -> String:
		var shown: Array[String] = []
		for index: int in range(0, values.size(), step):
			shown.append("%.1f" % (float(values[index]) / unit))
		if not values.is_empty() and (values.size() - 1) % step != 0:
			shown.append("%.1f" % (float(values[values.size() - 1]) / unit))
		return ", ".join(shown)


## O jogo de uma execução, o ator que o move e o estado do corpo falso.
class Rig:
	extends RefCounted

	var runner: SimulationRunner
	var modules: GameModules
	var npc: NpcModule
	var actor_id: int = 0
	var started_at: Dictionary[int, int] = {}
	var in_s0: Dictionary[int, bool] = {}


static func run(data: NpcLifeCheck.GameData, config: Config) -> Report:
	var report: Report = Report.new()
	if config.leg_minutes < 1 or config.days < 0:
		report.add_problem("configuração inválida: padrão de %d min, %d dias" % [config.leg_minutes, config.days])
		return report
	var started_usec: int = Time.get_ticks_usec()
	var rig: Rig = _new_game(data, config.world_seed, report)
	if rig == null:
		return report
	var total: int = config.days * SimClock.MINUTES_PER_DAY
	report.npcs = rig.npc.peek_npc_ids().size()
	report.step_usec.resize(total)
	_sample_day(rig, report, 0, config)
	for minute: int in total:
		_move_focus(rig, config.leg_minutes, minute)
		var began_usec: int = Time.get_ticks_usec()
		rig.runner.step_once()
		report.step_usec[minute] = Time.get_ticks_usec() - began_usec
		# Salvar e amostrar vêm ANTES do corpo falso: os relatos dele deixam eventos na fila, e a fila precisa estar vazia para capturar o jogo.
		if config.reload_at_minute > 0 and minute + 1 == config.reload_at_minute:
			rig = _reload(rig, data, config.world_seed, report)
			if rig == null:
				return report
		if (minute + 1) % SimClock.MINUTES_PER_DAY == 0:
			_sample_day(rig, report, IntMath.floor_div(minute + 1, SimClock.MINUTES_PER_DAY), config)
		_drive_bodies(rig, report)
	report.minutes = rig.runner.world.context.clock.total_minutes()
	report.state_hash = rig.runner.world.state_hash()
	report.modules = _module_stats(rig.runner.scheduler.debug_summary())
	_count_notables(rig, report)
	rig.runner.finish()
	report.wall_ms = IntMath.floor_div(Time.get_ticks_usec() - started_usec, 1000)
	return report


## Dados do jogo com a capacidade dos locais e a população multiplicadas por SCALE (só em memória). Público desde a LW-085c (a medição do painel usa o mesmo mundo);
## `development_build` liga o que só existe em build de desenvolvimento.
static func scaled_setup(data: NpcLifeCheck.GameData, development_build: bool = false) -> NpcSetup:
	var places: Array[Place] = []
	for place: Place in data.places:
		places.append(Place.new(place.id, place.settlement_id, place.kind, place.position, place.capacity * SCALE))
	var setup: NpcSetup = NpcSetup.from_dir(DATA_DIR, SettlementService.new(data.settlements, places), development_build)
	if setup.result.ok:
		var rows: Array[PopulationPlan.PopulationRow] = []
		for row: PopulationPlan.PopulationRow in setup.definitions.population.peek_rows():
			rows.append(PopulationPlan.PopulationRow.new(row.settlement_id, row.occupation_id, row.count * SCALE))
		setup.definitions.population = PopulationPlan.new(rows)
	return setup


## Runner e módulos do jogo real, ainda sem mundo (jogo novo ou carga vêm depois); null se algo falhar.
static func _build(data: NpcLifeCheck.GameData, world_seed: int, report: Report) -> Rig:
	if not data.problem.is_empty():
		report.add_problem("dados do jogo: %s" % data.problem)
		return null
	var setup: NpcSetup = scaled_setup(data)
	if not setup.result.ok:
		report.add_problem("dados do npc: %s" % setup.result.message)
		return null
	var rig: Rig = Rig.new()
	rig.runner = SimulationRunner.new(world_seed)
	rig.modules = GameModules.register(rig.runner, data.terrain, data.points, setup)
	if not rig.modules.result.ok:
		report.add_problem("módulos do jogo: %s" % rig.modules.result.message)
		return null
	rig.npc = rig.modules.npc
	return rig


static func _new_game(data: NpcLifeCheck.GameData, world_seed: int, report: Report) -> Rig:
	var rig: Rig = _build(data, world_seed, report)
	if rig == null:
		return null
	rig.runner.start_new_game()
	var ids: Array[int] = rig.npc.peek_npc_ids()
	for index: int in mini(NOTABLES, ids.size()):
		rig.npc.request_promote(ids[index], NpcState.TIER_NOTABLE)
	rig.actor_id = rig.modules.character.request_spawn().actor_id
	rig.npc.request_set_bodies_available(true)
	return rig


## Salva o jogo (codec JSON) e o carrega num runner NOVO; o hash do mundo carregado precisa ser o do salvo.
static func _reload(old: Rig, data: NpcLifeCheck.GameData, world_seed: int, report: Report) -> Rig:
	if not old.runner.can_capture_game():
		report.add_problem("salvar e carregar: há eventos na fila; o jogo não pode ser capturado agora")
		return null
	var hash_before: String = old.runner.world.state_hash()
	var codec: JsonSaveCodec = JsonSaveCodec.new()
	var decoded: DecodedSave = codec.decode(codec.encode(old.runner.capture_game(), GAME_VERSION))
	if not decoded.result.ok:
		report.add_problem("salvar e carregar: %s" % decoded.result.message)
		return null
	var fresh: Rig = _build(data, world_seed, report)
	if fresh == null:
		return null
	var loaded: Result = fresh.runner.load_game(decoded.payload)
	if not loaded.ok:
		report.add_problem("salvar e carregar: %s" % loaded.message)
		return null
	if fresh.runner.world.state_hash() != hash_before:
		report.add_problem("salvar e carregar: o hash do mundo carregado difere do salvo")
	fresh.actor_id = old.actor_id
	fresh.npc.request_set_bodies_available(true)
	old.runner.finish()
	return fresh


## O ator vai ao ponto do trecho atual (o personagem guarda a posição; o npc recebe o foco).
static func _move_focus(rig: Rig, leg_minutes: int, minute: int) -> void:
	var spot: Vector3 = SPOTS[IntMath.floor_div(minute, leg_minutes) % SPOTS.size()]
	rig.modules.character.report_position(rig.actor_id, spot, 0.0)
	rig.npc.request_set_focus(rig.actor_id, spot)


## O corpo falso: todo Intent de ir chega na hora; o de agir termina depois da duração prevista. Guarda só os Intents ainda pendentes.
static func _drive_bodies(rig: Rig, report: Report) -> void:
	var now: int = rig.runner.world.context.clock.total_minutes()
	var live: Dictionary[int, int] = {}
	for intent: NpcIntent in rig.npc.peek_pending_intents():
		var key: int = intent.npc_id * SERIAL_STRIDE + intent.action_serial
		var at: Vector3 = Vector3(float(intent.destination_cm.x) / NpcLod.CM_PER_METER_FLOAT, 0.0, float(intent.destination_cm.y) / NpcLod.CM_PER_METER_FLOAT)
		var began: int = rig.started_at.get(key, now)
		if intent.kind == NpcIntent.Kind.MOVE_TO_PLACE:
			rig.npc.request_report_npc_result(NpcActionResult.new(intent.npc_id, intent.action_serial, NpcActionResult.Outcome.ARRIVED, at))
		elif now >= began + intent.expected_minutes:
			rig.npc.request_report_npc_result(NpcActionResult.new(intent.npc_id, intent.action_serial, NpcActionResult.Outcome.DONE, at))
		else:
			live[key] = began
	rig.started_at = live
	var current: Dictionary[int, bool] = {}
	for npc_id: int in rig.npc.lod.s0_ids():
		current[npc_id] = true
		report.s0_entries += 0 if rig.in_s0.has(npc_id) else 1
	rig.in_s0 = current
	report.s0_peak = maxi(report.s0_peak, current.size())
	report.s0_sum += current.size()


## Memória e objetos (dia 0 = começo); do dia 1 em diante também vivos e mortos, a validação do mundo e do módulo e, a cada SAMPLE_EVERY_DAYS e no último dia, o tamanho do save.
static func _sample_day(rig: Rig, report: Report, day: int, config: Config) -> void:
	report.memory_by_day.append(int(Performance.get_monitor(Performance.MEMORY_STATIC)))
	report.objects_by_day.append(int(Performance.get_monitor(Performance.OBJECT_COUNT)))
	if day == 0:
		return
	var counts: Dictionary = rig.npc.peek_counts()
	var alive: int = int(counts[NpcModule.COUNT_ALIVE])
	report.dead = int(counts[NpcModule.COUNT_DEAD])
	report.min_alive = alive if report.min_alive < 0 else mini(report.min_alive, alive)
	for problem: String in rig.runner.world.validate():
		report.add_problem("fim do dia %d: world.validate: %s" % [day, problem])
	for problem: String in rig.npc.validate():
		report.add_problem("fim do dia %d: npc.validate: %s" % [day, problem])
	if day % SAMPLE_EVERY_DAYS == 0 or day == config.days:
		var payload: Dictionary = rig.runner.capture_game()
		report.save_bytes.append(JsonSaveCodec.new().encode(payload, GAME_VERSION).size())
		report.save_raw_bytes.append(JSON.stringify(payload, "", true, true).to_utf8_buffer().size())
		if config.progress:
			print("dia %d: memória %.1f MiB, objetos %d, mortos %d, corpos agora %d" % [day, float(report.memory_by_day[day]) / MIB, report.objects_by_day[day], report.dead, rig.in_s0.size()])


## Memórias, traços e relações de cada notável (T2) vivo, só por consultas `peek_*`.
static func _count_notables(rig: Rig, report: Report) -> void:
	for npc_id: int in rig.npc.peek_npc_ids():
		var state: NpcModule.NpcQuery = rig.npc.peek_npc(npc_id)
		if state.is_alive and state.tier == NpcState.TIER_NOTABLE:
			var memories: NpcModule.MemoriesQuery = rig.npc.peek_memories(npc_id)
			report.notable_memories.append(memories.records.size())
			report.notable_traits.append(memories.traits.size())
			report.notable_relations.append(rig.npc.peek_relations(npc_id).entries.size())


static func _module_stats(scheduler_summary: Dictionary) -> Dictionary:
	var stats: Dictionary = {}
	var by_module: Dictionary = scheduler_summary["modules"]
	for module_name: String in by_module:
		var entry: Dictionary = by_module[module_name]
		stats[module_name] = {"runs": entry["runs"], "total_us": entry["total_usec"], "max_us": entry["max_usec"], "over_limit": entry["over_limit"]}
	return stats
