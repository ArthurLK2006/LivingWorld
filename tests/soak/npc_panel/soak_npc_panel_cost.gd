extends GutTest
## LW-085c: o CUSTO do painel de depuração de NPC com 300 NPCs [HIP] (item I-3 da revisão cruzada da LW-085): o painel real (`NpcInspectorPanel`, com a ponte, os textos e os nós) lê a
## ponte a cada 0,25 s (`refresh`: a lista dos 300 e, do selecionado, o detalhe, o rastro, as memórias e as relações) e o resumo do mundo, que chama `world.validate()`, a cada ~1 s
## (`refresh_summary`). SÓ MEDE e imprime números (média, p99 e máximo em microssegundos e a conta por segundo): não reprova por tempo e não altera o `src/`. O mundo é o do soak da LW-084
## (`NpcYearMeter.scaled_setup`, 40 notáveis) depois de LW_PANEL_DAYS dias de jogo (30), para as memórias e relações dos notáveis estarem cheias. Fora do `check_all`: `tests/soak/run_npc_panel_cost`.

const WORLD_SEED: int = 11
const DEFAULT_DAYS: int = 30
const SAMPLES: int = 300
const US_PER_MS: float = 1000.0
const US_PER_S: float = 1000000.0
## Régua de quadro do jogo (DEC-119): 60 quadros por segundo.
const FRAME_BUDGET_US: float = 16667.0

var _data: NpcLifeCheck.GameData
var _texts: UiText


func before_all() -> void:
	_data = NpcLifeCheck.load_game_data()
	assert_eq(_data.problem, "", "Os dados reais do jogo carregam.")
	var loaded: UiText.LoadResult = UiText.from_file(UiText.DEFAULT_PATH)
	assert_true(loaded.result.ok, loaded.result.message)
	_texts = loaded.texts


## Tempo de cada chamada de `action`, em microssegundos.
func _time(action: Callable) -> PackedInt32Array:
	var spent: PackedInt32Array = PackedInt32Array()
	spent.resize(SAMPLES)
	for index: int in SAMPLES:
		var started: int = Time.get_ticks_usec()
		action.call()
		spent[index] = Time.get_ticks_usec() - started
	return spent


func _mean(spent: PackedInt32Array) -> float:
	var sum: int = 0
	for value: int in spent:
		sum += value
	return float(sum) / float(spent.size())


func _max(spent: PackedInt32Array) -> int:
	var sorted: PackedInt32Array = spent.duplicate()
	sorted.sort()
	return sorted[sorted.size() - 1]


func _show(label: String, spent: PackedInt32Array) -> void:
	var sorted: PackedInt32Array = spent.duplicate()
	sorted.sort()
	print("%s: média %.0f us | p99 %d | máximo %d" % [label, _mean(spent), sorted[int(float(SAMPLES) * 0.99)], _max(spent)])


func test_the_panel_cost_with_300_npcs_is_measured() -> void:
	var days_text: String = OS.get_environment("LW_PANEL_DAYS")
	var days: int = int(days_text) if days_text.is_valid_int() else DEFAULT_DAYS
	var setup: NpcSetup = NpcYearMeter.scaled_setup(_data, true)
	assert_true(setup.result.ok, setup.result.message)
	var host: SimulationHostNode = SimulationHostNode.new()
	host.start_new_game(WORLD_SEED, _data.terrain, _data.points, setup)
	var ids: Array[int] = host.npc.peek_npc_ids()
	for index: int in mini(NpcYearMeter.NOTABLES, ids.size()):
		host.npc.request_promote(ids[index], NpcState.TIER_NOTABLE)
	host.runner.run_days(days)
	var bridge: SimBridge = SimBridge.new(host, _data.terrain, _data.places, host.npc)
	var panel: NpcInspectorPanel = NpcInspectorPanel.new()
	add_child_autofree(panel)
	assert_true(panel.setup(bridge, _texts))
	panel.open()
	assert_eq(panel.list_row_count(), ids.size(), "A lista tem todos os NPCs.")
	var busiest: int = ids[0]
	var most: int = -1
	for index: int in mini(NpcYearMeter.NOTABLES, ids.size()):
		var size: int = host.npc.peek_memories(ids[index]).records.size() + host.npc.peek_relations(ids[index]).entries.size()
		busiest = ids[index] if size > most else busiest
		most = maxi(size, most)
	var citizen: int = ids[ids.size() - 1]
	print("painel: %d NPCs, %d dias de jogo | build de depuração: %s | o notável com mais registros tem %d (memórias mais relações)" % [ids.size(), days, "sim" if OS.is_debug_build() else "não", most])
	var validate: PackedInt32Array = _time(func() -> void: host.runner.world.validate())
	var summary: PackedInt32Array = _time(func() -> void: bridge.peek_simulation_summary())
	var summary_panel: PackedInt32Array = _time(func() -> void: panel.refresh_summary())
	assert_true(panel.model().select(busiest))
	var refresh_notable: PackedInt32Array = _time(func() -> void: panel.refresh())
	assert_true(panel.model().select(citizen))
	var refresh_citizen: PackedInt32Array = _time(func() -> void: panel.refresh())
	_show("world.validate()", validate)
	_show("peek_simulation_summary (a ponte)", summary)
	_show("refresh_summary (o painel)", summary_panel)
	_show("refresh com um notável selecionado", refresh_notable)
	_show("refresh com um cidadão selecionado", refresh_citizen)
	var per_second_us: float = _mean(refresh_notable) / NpcInspectorPanel.REFRESH_INTERVAL_S + _mean(summary_panel) / NpcInspectorPanel.SUMMARY_INTERVAL_S
	var worst_frame_us: float = float(_max(refresh_notable) + _max(summary_panel))
	print("custo por segundo com o painel aberto: %.2f ms (%.2f%% de 1 s) | quadro em que as duas atualizações caem juntas, no pior caso: %.2f ms (%.0f%% do quadro de %.1f ms, DEC-119)" % [per_second_us / US_PER_MS, per_second_us / US_PER_S * 100.0, worst_frame_us / US_PER_MS, worst_frame_us / FRAME_BUDGET_US * 100.0, FRAME_BUDGET_US / US_PER_MS])
	host.runner.finish()
	host.free()
