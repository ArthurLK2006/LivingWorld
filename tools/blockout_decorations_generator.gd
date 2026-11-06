class_name BlockoutDecorationsGenerator
extends RefCounted
## Gera data/world/decorations.json (LW-043): árvores e pedras de blockout, só visuais (não são recurso de jogo, não
## entram no state_hash nem no save). Ferramenta de USO ÚNICO e fora do jogo. Determinística: só WorldRng (semente
## constante, fluxo nomeado) e inteiros, então o arquivo sai idêntico em qualquer máquina. Todo número abaixo é [HIP].
## Lê o terreno de data/world pelo TerrainLoader. Formato (um objeto por linha): docs/modules/world.md.

const DECORATIONS_FILE: String = "decorations.json"
const TERRAIN_DIR: String = "res://data/world"
const USAGE: String = "Uso: tools/make_blockout_decorations [--out <pasta>] [--check]"
const CODE_USAGE: String = "DECORATIONS_USAGE"
const CODE_BAD_OUT_DIR: String = "DECORATIONS_BAD_OUT_DIR"
const CODE_TERRAIN: String = "DECORATIONS_TERRAIN"
const CODE_PLACEMENT: String = "DECORATIONS_PLACEMENT"
const CODE_WRITE_FAILED: String = "DECORATIONS_WRITE_FAILED"
const CODE_CHECK_DIFFERS: String = "DECORATIONS_CHECK_DIFFERS"

const WORLD_SEED: int = 4301
const RNG_STREAM: String = "decorations"
const TREE_COUNT: int = 1200
const ROCK_COUNT: int = 600
## Árvore: célula "grass" com inclinação de até 25 graus (tan 25° = 466 por mil). Pedra: "grass" ou "rock".
const MAX_TREE_SLOPE_PERMILLE: int = 466
const SURFACE_GRASS: String = "grass"
const SURFACE_ROCK: String = "rock"
## Distâncias em cm: nada a menos de 20 m do nascimento, 3 m entre instâncias e 2 m das bordas do mapa.
const SPAWN_CLEAR_CM: int = 2000
const MIN_SPACING_CM: int = 300
const EDGE_MARGIN_CM: int = 200
const MAX_ATTEMPTS_PER_ITEM: int = 400
const PERMILLE: int = 1000
const CM_PER_METER: float = 100.0


## Todas as decorações (árvores e depois pedras). Lista incompleta (depois de push_error) se faltar lugar.
static func generate(terrain: TerrainData) -> Array[DecorationReader.Item]:
	var rng: WorldRng = WorldRng.new(WORLD_SEED)
	var size_m: Vector2 = terrain.peek_size_m()
	var size_cm: Vector2i = Vector2i(roundi(size_m.x * CM_PER_METER), roundi(size_m.y * CM_PER_METER))
	var occupied: Dictionary[Vector2i, Array] = {}
	var items: Array[DecorationReader.Item] = []
	var plan: Dictionary[String, int] = {DecorationReader.KIND_TREE: TREE_COUNT, DecorationReader.KIND_ROCK: ROCK_COUNT}
	for kind: String in plan:
		for index: int in range(plan[kind]):
			var item: DecorationReader.Item = _place(terrain, rng, kind, size_cm, occupied)
			if item == null:
				push_error("BlockoutDecorationsGenerator: sem lugar para a %s %d depois de %d tentativas." % [kind, index, MAX_ATTEMPTS_PER_ITEM])
				return items
			items.append(item)
	return items


static func _place(terrain: TerrainData, rng: WorldRng, kind: String, size_cm: Vector2i, occupied: Dictionary[Vector2i, Array]) -> DecorationReader.Item:
	for attempt: int in range(MAX_ATTEMPTS_PER_ITEM):
		var x_cm: int = rng.range_int(RNG_STREAM, EDGE_MARGIN_CM, size_cm.x - EDGE_MARGIN_CM)
		var z_cm: int = rng.range_int(RNG_STREAM, EDGE_MARGIN_CM, size_cm.y - EDGE_MARGIN_CM)
		if not _is_allowed(terrain, kind, x_cm, z_cm, occupied):
			continue
		var item: DecorationReader.Item = DecorationReader.Item.new()
		item.kind = kind
		item.x_cm = x_cm
		item.z_cm = z_cm
		item.yaw_deg = rng.range_int(RNG_STREAM, DecorationReader.MIN_YAW_DEG, DecorationReader.MAX_YAW_DEG)
		item.scale_pct = rng.range_int(RNG_STREAM, DecorationReader.MIN_SCALE_PCT, DecorationReader.MAX_SCALE_PCT)
		var cell: Vector2i = _spacing_cell(x_cm, z_cm)
		if not occupied.has(cell):
			occupied[cell] = []
		occupied[cell].append(Vector2i(x_cm, z_cm))
		return item
	return null


static func _is_allowed(terrain: TerrainData, kind: String, x_cm: int, z_cm: int, occupied: Dictionary[Vector2i, Array]) -> bool:
	var spawn: Vector3 = terrain.peek_spawn_point()
	var from_spawn: Vector2i = Vector2i(x_cm - roundi(spawn.x * CM_PER_METER), z_cm - roundi(spawn.z * CM_PER_METER))
	if from_spawn.x * from_spawn.x + from_spawn.y * from_spawn.y < SPAWN_CLEAR_CM * SPAWN_CLEAR_CM:
		return false
	var surface: String = terrain.peek_surface(float(x_cm) / CM_PER_METER, float(z_cm) / CM_PER_METER).surface_id
	if surface != SURFACE_GRASS and (kind == DecorationReader.KIND_TREE or surface != SURFACE_ROCK):
		return false
	if kind == DecorationReader.KIND_TREE and not _is_gentle(terrain, x_cm, z_cm):
		return false
	return _is_spaced(occupied, x_cm, z_cm)


## Inclinação média da célula nos dois eixos (como no gerador do terreno), em inteiros: dois desníveis dobrados.
static func _is_gentle(terrain: TerrainData, x_cm: int, z_cm: int) -> bool:
	var cell_cm: int = roundi(terrain.peek_cell_size_m() * CM_PER_METER)
	var left: int = IntMath.floor_div(x_cm, cell_cm) * cell_cm
	var near: int = IntMath.floor_div(z_cm, cell_cm) * cell_cm
	var near_left: int = _height_cm(terrain, left, near)
	var near_right: int = _height_cm(terrain, left + cell_cm, near)
	var far_left: int = _height_cm(terrain, left, near + cell_cm)
	var far_right: int = _height_cm(terrain, left + cell_cm, near + cell_cm)
	var slope_x_twice: int = (near_right + far_right) - (near_left + far_left)
	var slope_z_twice: int = (far_left + far_right) - (near_left + near_right)
	var steepness: int = (slope_x_twice * slope_x_twice + slope_z_twice * slope_z_twice) * PERMILLE * PERMILLE
	return steepness <= 4 * MAX_TREE_SLOPE_PERMILLE * MAX_TREE_SLOPE_PERMILLE * cell_cm * cell_cm


static func _height_cm(terrain: TerrainData, x_cm: int, z_cm: int) -> int:
	return roundi(terrain.peek_height(float(x_cm) / CM_PER_METER, float(z_cm) / CM_PER_METER).height_m * CM_PER_METER)


static func _spacing_cell(x_cm: int, z_cm: int) -> Vector2i:
	return Vector2i(IntMath.floor_div(x_cm, MIN_SPACING_CM), IntMath.floor_div(z_cm, MIN_SPACING_CM))


## Grade espacial: só as 9 casas em volta podem ter alguém a menos de MIN_SPACING_CM.
static func _is_spaced(occupied: Dictionary[Vector2i, Array], x_cm: int, z_cm: int) -> bool:
	var home: Vector2i = _spacing_cell(x_cm, z_cm)
	for delta_z: int in range(-1, 2):
		for delta_x: int in range(-1, 2):
			var others: Array = occupied.get(home + Vector2i(delta_x, delta_z), [])
			for other: Vector2i in others:
				if (other.x - x_cm) * (other.x - x_cm) + (other.y - z_cm) * (other.y - z_cm) < MIN_SPACING_CM * MIN_SPACING_CM:
					return false
	return true


## Texto do arquivo: um objeto por linha, para o diff do Git ficar legível.
static func render(items: Array[DecorationReader.Item]) -> String:
	var lines: PackedStringArray = PackedStringArray([DecorationReader.ARRAY_OPEN])
	for index: int in range(items.size()):
		var item: DecorationReader.Item = items[index]
		var separator: String = "," if index < items.size() - 1 else ""
		lines.append("\t{\"kind\": \"%s\", \"x_cm\": %d, \"z_cm\": %d, \"yaw_deg\": %d, \"scale_pct\": %d}%s" % [item.kind, item.x_cm, item.z_cm, item.yaw_deg, item.scale_pct, separator])
	lines.append(DecorationReader.ARRAY_CLOSE)
	lines.append("")
	return "\n".join(lines)


## Executa a ferramenta com os argumentos da linha de comando. Sucesso: `message` traz o relatório.
static func run(arguments: PackedStringArray) -> Result:
	var out_dir: String = TERRAIN_DIR
	var check_only: bool = false
	var index: int = 0
	while index < arguments.size():
		if arguments[index] == "--check":
			check_only = true
			index += 1
		elif arguments[index] == "--out" and index + 1 < arguments.size():
			out_dir = arguments[index + 1] if arguments[index + 1].is_absolute_path() else "res://".path_join(arguments[index + 1])
			index += 2
		else:
			return Result.failure(CODE_USAGE, "opção inválida ou incompleta: '%s'.\n%s" % [arguments[index], USAGE])
	if not DirAccess.dir_exists_absolute(out_dir):
		return Result.failure(CODE_BAD_OUT_DIR, "pasta de saída inexistente: %s (a ferramenta não cria pastas)." % out_dir)
	var loaded: TerrainLoader.LoadResult = TerrainLoader.load_dir(TERRAIN_DIR)
	if not loaded.result.ok:
		return Result.failure(CODE_TERRAIN, loaded.result.message)
	var items: Array[DecorationReader.Item] = generate(loaded.terrain)
	if items.size() != TREE_COUNT + ROCK_COUNT:
		return Result.failure(CODE_PLACEMENT, "só foi possível colocar %d de %d decorações." % [items.size(), TREE_COUNT + ROCK_COUNT])
	var path: String = out_dir.path_join(DECORATIONS_FILE)
	var text: String = render(items)
	var report: String = "Decorações de blockout (LW-043): %d árvores e %d pedras, semente %d." % [TREE_COUNT, ROCK_COUNT, WORLD_SEED]
	if check_only:
		if not FileAccess.file_exists(path):
			return Result.failure(CODE_CHECK_DIFFERS, "%s: arquivo ausente" % path)
		if FileAccess.get_file_as_string(path) != text:
			return Result.failure(CODE_CHECK_DIFFERS, "%s: conteúdo diferente do que a ferramenta geraria" % path)
		return Result.new(true, "", "%s\nConferido: %s idêntico." % [report, path])
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return Result.failure(CODE_WRITE_FAILED, "não foi possível abrir %s para gravar (erro %d)." % [path, FileAccess.get_open_error()])
	var is_stored: bool = file.store_string(text)
	file.close()
	if not is_stored:
		return Result.failure(CODE_WRITE_FAILED, "falha ao gravar o conteúdo de %s." % path)
	return Result.new(true, "", "%s\nGravado: %s (%d bytes)." % [report, path, text.to_utf8_buffer().size()])
