class_name Sp2Trials
extends RefCounted
## LW-071 (SP2, DESCARTÁVEL): os ensaios do spike e o bloco "RESULTADO PARA COLAR". O jogador de verdade anda por ações do InputMap
## (precedente: game_release_node.gd): a cada quadro o spike aperta a combinação de teclas cuja direção, vista pela câmera, mais aponta
## para o próximo ponto da rota. Ensaios: alternancia (entra e sai do raio do povoado A e oscila 20 s na faixa de histerese), carga (100
## em S0 com dois focos e, depois, os 100 aglomerados no povoado A), relogio (1x, 2x, 4x, 8x e pausa, nas políticas P1 e P2) e ver.

const MOVE_COMBOS: Array[Vector2] = [Vector2(0, -1), Vector2(1, -1), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1), Vector2(-1, 1), Vector2(-1, 0), Vector2(-1, -1)]

var _main: Sp2Main
var _lines: PackedStringArray = PackedStringArray()
var _is_headless: bool = DisplayServer.get_name() == "headless"


func _init(main: Sp2Main) -> void:
	_main = main


func run(mode: String, trials: PackedStringArray) -> void:
	_header(mode)
	_route_bench()
	await _wait_ready()
	if mode == "ver":
		await _measure("VER %.0f s (Arthur anda à vontade)" % Sp2Constants.VIEW_SECONDS, Sp2Constants.VIEW_SECONDS, Vector2.INF)
	elif mode == "headless":
		await _alternation(Sp2Constants.HEADLESS_WAYPOINTS, false)
	else:
		if trials.has("alternancia"):
			await _alternation(Sp2Constants.ROUTE_WAYPOINTS, true)
		if trials.has("carga"):
			await _load_trial()
		if trials.has("relogio"):
			await _clock_trial()
	_finish()


func _header(mode: String) -> void:
	_lines.append("LW-071 (SP2): corpos e LOD de NPCs — modo %s" % mode)
	_lines.append("build de depuração: %s" % ("sim" if OS.is_debug_build() else "não"))
	_lines.append("Motor: Godot %s, %s, %s" % [Engine.get_version_info()["string"], OS.get_name(), RenderingServer.get_video_adapter_name()])
	_lines.append("Renderização: driver %s, método %s" % [RenderingServer.get_current_rendering_driver_name(), RenderingServer.get_current_rendering_method()])


## Rotas r1 a r4 com N1 e N2: resultado, pontos, comprimento, pedra no caminho e tempo de cálculo (médio e pior de BENCH_REPEATS).
func _route_bench() -> void:
	var nav: Sp2Nav = Sp2Nav.new(_main.terrain)
	_lines.append("ROTAS (terreno real; tempo de cálculo de %d repetições; a 1ª N2 de cada trecho preenche o cache das células)" % Sp2Constants.BENCH_REPEATS)
	for entry: Array in Sp2Constants.BENCH_ROUTES:
		for kind: Sp2Nav.Kind in [Sp2Nav.Kind.N1_STRAIGHT, Sp2Nav.Kind.N2_GRID]:
			var worst: int = 0
			var total: int = 0
			var points: PackedVector2Array = PackedVector2Array()
			for _repeat: int in Sp2Constants.BENCH_REPEATS:
				points = nav.route(kind, entry[1], entry[2])
				total += nav.last_route_usec
				worst = maxi(worst, nav.last_route_usec)
			_lines.append("  %s, %s: %s, %d pontos, %.0f m, %d amostras em pedra, cálculo médio %.2f ms, pior %.2f ms" % [entry[0], Sp2Nav.label(kind), "sem caminho" if points.is_empty() else "chega", points.size(), _path_length(entry[1], points), _rock_samples(entry[1], points), float(total) / 1000.0 / float(Sp2Constants.BENCH_REPEATS), float(worst) / 1000.0])


static func _path_length(start: Vector2, points: PackedVector2Array) -> float:
	var length: float = 0.0
	var at: Vector2 = start
	for point: Vector2 in points:
		length += at.distance_to(point)
		at = point
	return length


## Amostras a cada 2 m pelo caminho que caem em superfície rock.
func _rock_samples(start: Vector2, points: PackedVector2Array) -> int:
	var count: int = 0
	var at: Vector2 = start
	for point: Vector2 in points:
		var steps: int = maxi(1, ceili(at.distance_to(point) / Sp2Constants.N1_SAMPLE_STEP_M))
		for index: int in range(1, steps + 1):
			var sample: Vector2 = at.lerp(point, float(index) / float(steps))
			var surface: TerrainData.SurfaceQuery = _main.terrain.peek_surface(sample.x, sample.y)
			count += 1 if surface.result.ok and surface.surface_id == Sp2Constants.ROCK_SURFACE_ID else 0
		at = point
	return count


func _wait_ready() -> void:
	var start_us: int = Time.get_ticks_usec()
	await _main.get_tree().process_frame
	var view: TerrainView = _main.terrain_view
	while (view.pending_count() + view.free_pending_count() + view.collision_pending_count() > 0 or not _main.player.is_spawned()) and _seconds_since(start_us) < Sp2Constants.SETTLE_TIMEOUT_SECONDS:
		await _main.get_tree().process_frame
	_lines.append("terreno assentou em %.1f s (%d chunks); jogador nasceu: %s" % [_seconds_since(start_us), view.loaded_chunks().size(), "sim" if _main.player.is_spawned() else "não"])
	await _wait(Sp2Constants.AFTER_SETTLE_SECONDS, Vector2.INF)


## Corre pela rota; no ensaio completo, depois da rota oscila na faixa de histerese e conta as trocas de LOD por NPC.
func _alternation(waypoints: Array[Vector2], with_band: bool) -> void:
	var metrics: Sp2Metrics = Sp2Metrics.new()
	metrics.begin("ALTERNÂNCIA (rota pelo povoado A, correndo)", INF, _snapshot())
	Input.action_press(InputActions.RUN)
	for point: Vector2 in waypoints:
		while _flat_player().distance_to(point) > Sp2Constants.WAYPOINT_REACHED_M:
			_steer(point)
			await _main.get_tree().process_frame
			metrics.frame(_snapshot)
	if with_band:
		await _steer_until(Sp2Constants.HYSTERESIS_POINTS[0], metrics)
		metrics.mark_middle(_snapshot())
		_main.world.reset_lod_change_counts()
		var band_start: int = Time.get_ticks_usec()
		var at: int = 1
		while _seconds_since(band_start) < Sp2Constants.HYSTERESIS_SECONDS:
			if _flat_player().distance_to(Sp2Constants.HYSTERESIS_POINTS[at]) <= Sp2Constants.WAYPOINT_REACHED_M:
				at = 1 - at
			_steer(Sp2Constants.HYSTERESIS_POINTS[at])
			await _main.get_tree().process_frame
			metrics.frame(_snapshot)
		_lines.append("faixa de histerese (%.0f s): maior número de LodChanged de um NPC = %d" % [Sp2Constants.HYSTERESIS_SECONDS, _main.world.max_lod_changes_per_npc()])
		await _steer_until(Sp2Constants.ROUTE_EXIT, metrics)
	_release_all()
	metrics.close(_snapshot())
	_lines.append_array(metrics.report_lines(_is_headless))
	_lines.append("  duração do ensaio: %.1f s" % metrics.elapsed_s())


## 100 em S0 (max_s0 = 100 em código): jogador no povoado A e foco fixo no B; depois, os 100 nascidos em A.
func _load_trial() -> void:
	if not _main.replace_world(Sp2World.new(_main.terrain, Sp2Constants.LOAD_TEST_MAX_S0)):
		return
	await _steer_until(Vector2(320.0, 513.0), null)
	_main.extra_foci[Sp2Constants.FIXED_FOCUS_ID] = Vector3(800.0, 0.0, 660.0)
	await _wait(2.0, Vector2.INF)
	await _measure("CARGA 30 s, dois focos (jogador no povoado A, foco fixo no B)", Sp2Constants.LOAD_SECONDS, Vector2.INF)
	_lines.append("  NPCs em S0: %d · corpos à vista da câmera: %d" % [_main.world.module.lod.s0_ids().size(), _visible_bodies()])
	_main.extra_foci.clear()
	if not _main.replace_world(Sp2World.new(_main.terrain, Sp2Constants.LOAD_TEST_MAX_S0, true)):
		return
	await _wait(2.0, Vector2.INF)
	await _measure("CARGA 30 s, os 100 aglomerados no povoado A (pior caso de desenho)", Sp2Constants.LOAD_SECONDS, Vector2.INF)
	_lines.append("  NPCs em S0: %d · corpos à vista da câmera: %d" % [_main.world.module.lod.s0_ids().size(), _visible_bodies()])


## 20 s em cada velocidade e 20 s em pausa, para P1 e depois P2, parado no povoado A (o relógio do jogo é mudado pela ponte).
func _clock_trial() -> void:
	await _steer_until(Vector2(320.0, 513.0), null)
	for policy: Sp2SpeedPolicy.Policy in [Sp2SpeedPolicy.Policy.P1_NATURAL, Sp2SpeedPolicy.Policy.P2_FROM_CLOCK]:
		_main.embodiment.policy = policy
		for speed: int in Sp2Constants.CLOCK_SPEEDS:
			_main.bridge.request_speed(speed)
			await _segment("RELÓGIO %s a %dx" % [Sp2SpeedPolicy.label(policy), speed])
		_main.bridge.request_pause(true)
		await _segment("RELÓGIO %s em PAUSA" % Sp2SpeedPolicy.label(policy))
		_main.bridge.request_pause(false)
	_main.bridge.request_speed(1)


func _segment(label: String) -> void:
	var embodied: Sp2Embodiment = _main.embodiment
	var before: Array = [embodied.arrived, embodied.done, _main.world.intent_counters()["timed_out_intents"], _main.world.intent_counters()["discarded_results"], embodied.walked_m, embodied.walking_seconds, embodied.ratio_sum, embodied.ratio_count, embodied.late_arrivals, embodied.ceiling_short, _main.world.now()]
	await _measure(label, Sp2Constants.CLOCK_SEGMENT_SECONDS, Vector2.INF)
	var counters: Dictionary = _main.world.intent_counters()
	var walked: float = embodied.walked_m - float(before[4])
	var seconds: float = embodied.walking_seconds - float(before[5])
	var ratios: int = embodied.ratio_count - int(before[7])
	_lines.append("  minutos de jogo: %d · chegadas %d · feitas %d · tempos limite %d · descartados %d · atrasadas %d · teto curto %d · velocidade vista %.2f m/s · levado/previsto %.2f" % [
		_main.world.now() - int(before[10]), embodied.arrived - int(before[0]), embodied.done - int(before[1]), int(counters["timed_out_intents"]) - int(before[2]), int(counters["discarded_results"]) - int(before[3]),
		embodied.late_arrivals - int(before[8]), embodied.ceiling_short - int(before[9]), walked / maxf(seconds, 0.001), (embodied.ratio_sum - float(before[6])) / float(maxi(ratios, 1))])


func _measure(label: String, seconds: float, target: Vector2) -> void:
	var metrics: Sp2Metrics = Sp2Metrics.new()
	metrics.begin(label, seconds, _snapshot())
	while true:
		if target != Vector2.INF:
			_steer(target)
		await _main.get_tree().process_frame
		if metrics.frame(_snapshot):
			break
	_lines.append_array(metrics.report_lines(_is_headless))


func _wait(seconds: float, target: Vector2) -> void:
	var start_us: int = Time.get_ticks_usec()
	while _seconds_since(start_us) < seconds:
		if target != Vector2.INF:
			_steer(target)
		await _main.get_tree().process_frame


func _steer_until(point: Vector2, metrics: Sp2Metrics) -> void:
	Input.action_press(InputActions.RUN)
	while _flat_player().distance_to(point) > Sp2Constants.WAYPOINT_REACHED_M:
		_steer(point)
		await _main.get_tree().process_frame
		if metrics != null:
			metrics.frame(_snapshot)
	_release_all()


## Aperta a combinação de teclas de andar cuja direção no mundo (pela câmera, como o PlayerBody calcula) mais aponta para o ponto.
func _steer(point: Vector2) -> void:
	var wanted: Vector2 = (point - _flat_player()).normalized()
	var yaw: Basis = Basis(Vector3.UP, _main.camera.global_rotation.y)
	var best: Vector2 = MOVE_COMBOS[0]
	var best_dot: float = -2.0
	for combo: Vector2 in MOVE_COMBOS:
		var world_dir: Vector3 = (yaw * Vector3(combo.x, 0.0, combo.y)).normalized()
		var dot: float = Vector2(world_dir.x, world_dir.z).dot(wanted)
		if dot > best_dot:
			best_dot = dot
			best = combo
	_set_action(InputActions.MOVE_RIGHT, best.x > 0.0)
	_set_action(InputActions.MOVE_LEFT, best.x < 0.0)
	_set_action(InputActions.MOVE_BACK, best.y > 0.0)
	_set_action(InputActions.MOVE_FORWARD, best.y < 0.0)


func _set_action(action: StringName, is_down: bool) -> void:
	if is_down:
		Input.action_press(action)
	else:
		Input.action_release(action)


func _release_all() -> void:
	for action: StringName in [InputActions.MOVE_FORWARD, InputActions.MOVE_BACK, InputActions.MOVE_LEFT, InputActions.MOVE_RIGHT, InputActions.RUN]:
		Input.action_release(action)


func _flat_player() -> Vector2:
	return Vector2(_main.player.global_position.x, _main.player.global_position.z)


func _visible_bodies() -> int:
	var seen: int = 0
	for npc_id: int in _main.embodiment.pool.active_ids():
		seen += 1 if _main.camera.is_position_in_frustum(_main.embodiment.pool.body_of(npc_id).position) else 0
	return seen


func _snapshot() -> String:
	return "%d nós, %d chunks, %d em S0" % [int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)), _main.terrain_view.loaded_chunks().size(), _main.world.module.lod.s0_ids().size()]


func _seconds_since(start_us: int) -> float:
	return float(Time.get_ticks_usec() - start_us) / 1000000.0


func _finish() -> void:
	var embodied: Sp2Embodiment = _main.embodiment
	_lines.append("CONTADORES")
	_lines.append("  invariantes: " + embodied.checker.summary())
	_lines.append("  pool: " + embodied.pool.summary() + ", corpos perdidos %d" % embodied.pool.lost_bodies())
	_lines.append("  corpos: " + embodied.summary())
	_lines.append("  " + _main.sim_cost_text())
	_lines.append("  protocolo S0: %s · diretor: começos abstratos %d, corpóreos %d, recusas %s" % [str(_main.world.intent_counters()), _main.world.director.begun_abstract, _main.world.director.begun_embodied, str(_main.world.director.refusals)])
	_lines.append("  política final: %s · navegação final: %s" % [Sp2SpeedPolicy.label(embodied.policy), Sp2Nav.label(embodied.nav_kind)])
	print("==== RESULTADO PARA COLAR (LW-071, SP2) ====")
	for line: String in _lines:
		print(line)
	print("==== FIM DO RESULTADO ====")
	_main.world.finish()
	_main.get_tree().quit(0)
