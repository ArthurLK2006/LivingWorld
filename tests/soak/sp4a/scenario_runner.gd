class_name Sp4aScenarioRunner
extends RefCounted
## SPIKE descartável (LW-033/SP4a). Orquestra os cenários (item 6 da tarefa) para UM processo do
## Godot. O `--rendering-method` só pode ser escolhido ao abrir o processo (não muda em tempo de
## execução, confirmado por teste curto): por isso tests/soak/run_sp4a chama o Godot UMA VEZ POR
## RENDERIZADOR pedido, e cada processo acumula suas linhas no mesmo arquivo JSON (item 12),
## passado por --acumular-em. A resolução da janela, ao contrário, muda em tempo de execução
## (DisplayServer.window_set_size), então os níveis de qualidade não precisam de novo processo.

const SCENARIOS: Array[String] = ["parado", "caminhada", "subida", "colisao"]
const TERRAINS: Array[String] = ["proprio", "addon"]
## Medido com janela de verdade (ver relatório, seção 4): os valores originais somavam >9 min
## para as 6 combinações do modo rápido (meta: ~5 min). Reduzidos para caber com folga.
const DEFAULT_DURATIONS_RAPIDO: Dictionary = {"parado": 2.0, "caminhada": 5.0, "subida": 1.5, "colisao": 1.5}
## "subida" roda SUBIDA_CYCLES (3) vezes com esta duração CADA; os valores originais (10/60/20/5)
## davam 10 combinações (6 + 2 no forward_plus + 2 no mobile, não só 6) x 4 passes x 135 s por
## passe = ~90 min, bem acima da meta de ~30 min do prompt. Reduzidos, mantendo bem mais longos
## que o modo rápido (e as 3 repetições continuam as mesmas, como o texto da tarefa pede).
const DEFAULT_DURATIONS_COMPLETO: Dictionary = {"parado": 5.0, "caminhada": 15.0, "subida": 3.0, "colisao": 3.0}
const SUBIDA_CYCLES: int = 3
const SUBIDA_MAX_HEIGHT: float = 1000.0  ## [HIP]
const WALK_PATH_START: Vector2 = Vector2(120.0, 120.0)
const WALK_PATH_END: Vector2 = Vector2(900.0, 900.0)
const COLLISION_GRID_STEP: float = 64.0  ## [HIP] amostra a cada chunk

var scene_root: Node3D
var camera: Sp4aFreeCamera
var terrain_data: Sp4aTerrainData
var result_writer: Sp4aResultWriter
var renderer_label: String
var machine_label: String

var _own_terrain: Sp4aTerrainOwn
var _addon_terrain: Sp4aTerrainAddon


static func parse_args(args: PackedStringArray) -> Dictionary:
	var parsed: Dictionary = {
		"modo": "rapido", "terreno": "ambos", "qualidade": "todas", "cenario": "todos",
		"repeticoes": 3, "duracao": -1.0, "acumular_em": "", "run_id": "",
	}
	var i: int = 0
	while i < args.size():
		var key: String = args[i]
		var value: String = args[i + 1] if i + 1 < args.size() else ""
		match key:
			"--modo": parsed["modo"] = value
			"--terreno": parsed["terreno"] = value
			"--qualidade": parsed["qualidade"] = value
			"--cenario": parsed["cenario"] = value
			"--repeticoes": parsed["repeticoes"] = value.to_int()
			"--duracao": parsed["duracao"] = value.to_float()
			"--acumular-em": parsed["acumular_em"] = value
			"--run-id": parsed["run_id"] = value
		i += 2
	if parsed["modo"] == "rapido":
		parsed["repeticoes"] = 1
	return parsed


static func _expand(value: String, all_values: Array[String]) -> Array[String]:
	if value == "todos" or value == "todas" or value == "ambos":
		return all_values.duplicate()
	return [value]


func run(args: Dictionary) -> void:
	var terrenos: Array[String] = _expand(args["terreno"], TERRAINS)
	var qualidades: Array[String] = _expand(args["qualidade"], Sp4aQualityLevels.ORDER)
	var cenarios: Array[String] = _expand(args["cenario"], SCENARIOS)
	var duration_overrides: Dictionary = DEFAULT_DURATIONS_RAPIDO if args["modo"] == "rapido" else DEFAULT_DURATIONS_COMPLETO

	if "addon" in terrenos and not Sp4aTerrainAddon.is_available():
		print("AVISO: Terrain3D não disponível; pulando a variante addon.")
		terrenos.erase("addon")

	for terreno: String in terrenos:
		await _setup_terrain_variant(terreno)
		for qualidade: String in qualidades:
			var quality: Dictionary = Sp4aQualityLevels.get_level(qualidade)
			DisplayServer.window_set_size(Vector2i(quality["largura"], quality["altura"]))
			_apply_quality(terreno, quality)
			await scene_root.get_tree().process_frame
			for cenario: String in cenarios:
				var duration: float = args["duracao"] if args["duracao"] > 0.0 else duration_overrides[cenario]
				await _run_combo(terreno, qualidade, cenario, duration, args["repeticoes"])
		_teardown_terrain_variant(terreno)


func _setup_terrain_variant(terreno: String) -> void:
	if terreno == "proprio":
		_own_terrain = Sp4aTerrainOwn.new()
		_own_terrain.setup(terrain_data, 2.0, 5)
		scene_root.add_child(_own_terrain)
	else:
		_addon_terrain = Sp4aTerrainAddon.new()
		# add_child ANTES de setup(): Sp4aTerrainAddon.setup() usa get_tree() (precisa esperar
		# quadros), e isso só funciona depois que o nó já está na árvore (achado ao testar com
		# janela de verdade — ver relatório, seção 4).
		scene_root.add_child(_addon_terrain)
		var ok: bool = await _addon_terrain.setup(terrain_data)
		if not ok:
			print("ADDON FALHOU: ", _addon_terrain.load_error)
		else:
			_addon_terrain.set_camera(camera)


func _teardown_terrain_variant(terreno: String) -> void:
	if terreno == "proprio" and _own_terrain != null:
		_own_terrain.clear_all()
		_own_terrain.queue_free()
		_own_terrain = null
	elif terreno == "addon" and _addon_terrain != null:
		_addon_terrain.queue_free()
		_addon_terrain = null


func _apply_quality(terreno: String, quality: Dictionary) -> void:
	if terreno == "proprio" and _own_terrain != null:
		_own_terrain.vertex_spacing = quality["espaco_vertice"]
		_own_terrain.view_distance_chunks = quality["distancia_chunks"]
	elif terreno == "addon" and _addon_terrain != null:
		_addon_terrain.set_vertex_spacing(quality["espaco_vertice"])
	# Sombras e MSAA são ajustados pela composição de ambiente (LW-041); fora do escopo do SP4a,
	# que mede terreno. Registrado como limitação no relatório.


func _run_combo(terreno: String, qualidade: String, cenario: String, duration: float, repeticoes: int) -> void:
	# Aquecimento descartado (item 7).
	await _run_single_pass(terreno, cenario, duration)
	var fps_medios: Array[float] = []
	var fps_mins: Array[float] = []
	var last_stats: Dictionary = {}
	var observation: String = ""
	for repeticao: int in range(repeticoes):
		var pass_result: Dictionary = await _run_single_pass(terreno, cenario, duration)
		last_stats = pass_result["stats"]
		observation = pass_result["observacao"]
		if last_stats.get("amostras", 0) > 0:
			fps_medios.append(last_stats["fps_medio"])
			fps_mins.append(last_stats["fps_min"])
	if repeticoes > 1 and not fps_medios.is_empty():
		var spread_medio: Dictionary = Sp4aMetrics.describe_repetitions(fps_medios)
		var spread_min: Dictionary = Sp4aMetrics.describe_repetitions(fps_mins)
		observation += " | %d repetições: FPS médio de %.1f a %.1f, FPS mín de %.1f a %.1f" % [
			repeticoes, spread_medio["minimo"], spread_medio["maximo"], spread_min["minimo"], spread_min["maximo"],
		]
	result_writer.add_row(renderer_label, qualidade, terreno, cenario, last_stats, observation)
	print("Concluído: %s / %s / %s / %s" % [renderer_label, qualidade, terreno, cenario])


func _run_single_pass(terreno: String, cenario: String, duration: float) -> Dictionary:
	var metrics: Sp4aMetrics = Sp4aMetrics.new()
	metrics.start_window()
	var observation: String = ""
	match cenario:
		"parado":
			var spawn: Vector3 = terrain_data.peek_spawn_point()
			camera.global_position = spawn + Vector3(0.0, 8.0, 15.0)
			camera.look_at(spawn, Vector3.UP)
			if terreno == "proprio" and _own_terrain != null:
				_own_terrain.set_focus(camera.global_position)
			await scene_root.get_tree().process_frame
			var elapsed: float = 0.0
			while elapsed < duration:
				await scene_root.get_tree().process_frame
				metrics.sample_frame()
				elapsed += scene_root.get_process_delta_time()
		"caminhada":
			var elapsed_walk: float = 0.0
			while elapsed_walk < duration:
				await scene_root.get_tree().process_frame
				var t: float = fmod(elapsed_walk / duration, 1.0)
				var ping_pong: float = 1.0 - absf(2.0 * t - 1.0)
				var ground_pos: Vector2 = WALK_PATH_START.lerp(WALK_PATH_END, ping_pong)
				var height: float = terrain_data.get_height(ground_pos.x, ground_pos.y)
				camera.global_position = Vector3(ground_pos.x, height + 2.0, ground_pos.y)
				if terreno == "proprio" and _own_terrain != null:
					_own_terrain.set_focus(camera.global_position)
				metrics.sample_frame()
				elapsed_walk += scene_root.get_process_delta_time()
		"subida":
			observation = await _run_subida(metrics, duration)
		"colisao":
			observation = await _run_colisao(terreno, metrics, duration)
	return {"stats": metrics.finish(), "observacao": observation}


func _run_subida(metrics: Sp4aMetrics, cycle_duration: float) -> String:
	var spawn: Vector3 = terrain_data.peek_spawn_point()
	var base_xz: Vector2 = Vector2(spawn.x, spawn.z)
	var fps_below_30_height: float = -1.0
	var height_buckets: Dictionary = {}  # faixa de 100 m -> lista de fps
	for cycle: int in range(SUBIDA_CYCLES):
		var elapsed: float = 0.0
		while elapsed < cycle_duration:
			await scene_root.get_tree().process_frame
			var t: float = elapsed / cycle_duration
			var ping_pong: float = 1.0 - absf(2.0 * t - 1.0)
			var height: float = lerpf(2.0, SUBIDA_MAX_HEIGHT, ping_pong)
			camera.global_position = Vector3(base_xz.x, height, base_xz.y)
			camera.look_at(Vector3(base_xz.x, 0.0, base_xz.y), Vector3.FORWARD)
			metrics.sample_frame()
			var fps: float = Performance.get_monitor(Performance.TIME_FPS)
			var bucket: int = int(height / 100.0) * 100
			if not height_buckets.has(bucket):
				height_buckets[bucket] = []
			height_buckets[bucket].append(fps)
			if fps < 30.0 and fps > 0.0 and (fps_below_30_height < 0.0 or height < fps_below_30_height):
				fps_below_30_height = height
			elapsed += scene_root.get_process_delta_time()
	var bucket_summary: Array[String] = []
	for bucket: int in height_buckets.keys():
		var values: Array = height_buckets[bucket]
		var total: float = 0.0
		for v: float in values:
			total += v
		bucket_summary.append("%dm:%.0ffps" % [bucket, total / values.size()])
	var quebra: String = ("quebra <30fps em ~%.0fm" % fps_below_30_height) if fps_below_30_height > 0.0 else "nunca ficou <30fps"
	return "%s; por faixa: %s" % [quebra, ", ".join(bucket_summary)]


## A grade só pode cobrir a área que o terreno próprio realmente carrega perto do foco (streaming
## por distância): testar o mapa inteiro sem focar lá dava 0/256 batendo, porque não havia malha
## nenhuma fora do que já estava carregado (achado ao rodar com janela de verdade — ver relatório,
## seção 4). Por isso foca perto do nascimento e testa só essa vizinhança.
func _run_colisao(terreno: String, metrics: Sp4aMetrics, duration: float) -> String:
	var spawn: Vector3 = terrain_data.peek_spawn_point()
	camera.global_position = spawn + Vector3(0.0, 10.0, 0.0)
	if terreno == "proprio" and _own_terrain != null:
		_own_terrain.set_focus(spawn)
	await scene_root.get_tree().process_frame
	var mismatches: int = 0
	var checked: int = 0
	var half_span: float = COLLISION_GRID_STEP * 3.0
	var min_x: float = clampf(spawn.x - half_span, 0.0, Sp4aTerrainData.MAP_SIZE)
	var max_x: float = clampf(spawn.x + half_span, 0.0, Sp4aTerrainData.MAP_SIZE)
	var min_z: float = clampf(spawn.z - half_span, 0.0, Sp4aTerrainData.MAP_SIZE)
	var max_z: float = clampf(spawn.z + half_span, 0.0, Sp4aTerrainData.MAP_SIZE)
	var x: float = min_x
	while x <= max_x:
		var z: float = min_z
		while z <= max_z:
			checked += 1
			var expected: float = terrain_data.get_height(x, z)
			var space_state: PhysicsDirectSpaceState3D = scene_root.get_world_3d().direct_space_state
			var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
				Vector3(x, 2000.0, z), Vector3(x, -100.0, z)
			)
			var hit: Dictionary = space_state.intersect_ray(query)
			if hit.is_empty() or absf(hit["position"].y - expected) > 0.5:
				mismatches += 1
			z += COLLISION_GRID_STEP
		await scene_root.get_tree().physics_frame
		metrics.sample_frame()
		x += COLLISION_GRID_STEP

	var body: CharacterBody3D = CharacterBody3D.new()
	var shape: CollisionShape3D = CollisionShape3D.new()
	shape.shape = CapsuleShape3D.new()
	body.add_child(shape)
	# global_position só funciona depois que o nó está na árvore (achado ao rodar com janela de
	# verdade — "Condition '!is_inside_tree()' is true"; ver relatório, seção 4).
	scene_root.add_child(body)
	body.global_position = spawn + Vector3(0.0, 2.0, 0.0)
	var target: Vector3 = spawn + Vector3(30.0, 0.0, 0.0)
	var walk_duration_msec: int = int(minf(duration, 5.0) * 1000.0)
	var start_pos: Vector3 = body.global_position
	# Tempo de relógio real (Time.get_ticks_msec), não get_process_delta_time(): o laço espera
	# physics_frame, e medir com o delta do _process é um descompasso que quase nunca fecha a
	# condição (achado ao rodar com janela de verdade — ver relatório, seção 4).
	var walk_start_msec: int = Time.get_ticks_msec()
	while Time.get_ticks_msec() - walk_start_msec < walk_duration_msec:
		await scene_root.get_tree().physics_frame
		var direction: Vector3 = (Vector3(target.x, body.global_position.y, target.z) - body.global_position)
		direction.y = 0.0
		var velocity: Vector3 = direction.normalized() * 4.0 if direction.length() > 0.5 else Vector3.ZERO
		velocity.y = -9.8
		body.velocity = velocity
		body.move_and_slide()
	var moved_xz: float = Vector2(body.global_position.x - start_pos.x, body.global_position.z - start_pos.z).length()
	var stuck: bool = moved_xz < 1.0
	var sank: bool = body.global_position.y < terrain_data.get_height(body.global_position.x, body.global_position.z) - 1.0
	body.queue_free()

	return "colisão: %d/%d alturas batem; cápsula %s%s" % [
		checked - mismatches, checked,
		"travou" if stuck else "andou (%.1fm)" % moved_xz,
		" e afundou" if sank else "",
	]
