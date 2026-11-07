class_name BlockoutTerrainGenerator
extends RefCounted
## Gera o terreno de blockout (LW-037, DEC-118): planície, uma colina, um vale, um caminho plano e (LW-047A) um morro de teste com um
## lado muito íngreme, em
## data/world/. Ferramenta de USO ÚNICO e fora do jogo: o jogo não gera mundo, só lê o resultado.
## O relevo é uma fórmula, sem aleatoriedade, calculada só com inteiros (centímetros e permilagem),
## para o arquivo sair idêntico em qualquer máquina. Todo valor de forma abaixo é HIPÓTESE [HIP]:
## Arthur ajusta depois, olhando a tela (LW-038). Descrição: docs/world/relevo-do-terreno-de-blockout.md.

const TERRAIN_ID: String = "blockout_terrain"
const TERRAIN_FILE: String = "terrain.json"
const SURFACE_FILE: String = "surface_types.json"
const DEFAULT_OUT_DIR: String = "res://data/world"
const USAGE: String = "Uso: tools/make_blockout_terrain [--out <pasta>] [--check]"
const CODE_USAGE: String = "BLOCKOUT_USAGE"
const CODE_BAD_OUT_DIR: String = "BLOCKOUT_BAD_OUT_DIR"
const CODE_WRITE_FAILED: String = "BLOCKOUT_WRITE_FAILED"
const CODE_CHECK_DIFFERS: String = "BLOCKOUT_CHECK_DIFFERS"

# --- Grade (decisão de Arthur, 05/11/2026; DEC-118): 512 x 512 células de 2 m = 1.024 m; chunks de 64 m. ---
const CELLS_PER_SIDE: int = 512
const CELL_SIZE_CM: int = 200
const CHUNK_CELLS: int = 32

# --- Relevo [HIP]. Distâncias e alturas em cm. ---
const PLAIN_HEIGHT_CM: int = 1000
const HILL_CENTER_CM: Vector2i = Vector2i(70000, 30000)
const HILL_RADIUS_CM: int = 16000
const HILL_RISE_CM: int = 3000
const VALLEY_CENTER_CM: Vector2i = Vector2i(30000, 75000)
const VALLEY_RADIUS_CM: int = 14000
const VALLEY_DEPTH_CM: int = 1200
## Morro de teste íngreme (LW-047A), para o limite de inclinação do jogador (40°) aparecer no jogo: um lado muito íngreme (oeste, de frente
## para o nascimento) e o oposto suave (leste). Mesma fórmula suave da colina, com raios diferentes dos dois lados do pico; a inclinação
## máxima de cada direção é ~1,54 x subida / raio (o máximo da fórmula): 1,54 x 15,2 m / 19,4 m = 1,21 (cerca de 50°) a oeste,
## 1,54 x 15,2 m / 38,5 m = 0,61 (cerca de 31°) a leste e 1,54 x 15,2 m / 33 m = 0,71 (cerca de 35°) nos flancos norte e sul. A subida de 15,2 m
## (e não 15,0) é para o pico, que não cai num nó da grade, passar de 15 m depois da interpolação. Fica a cerca de
## 80 m do nascimento, a 10 m do caminho (a pegada vai até z = 500 m; o caminho começa em 510 m) e a mais de 30 m dos dois pontos de
## interesse. O centro foi escolhido para nenhuma ÁRVORE de data/world/decorations.json cair na pegada dele, de modo que o arquivo de
## decoração segue idêntico (a ferramenta o confere). Altura, raios e centro são [HIP].
const STEEP_HILL_CENTER_CM: Vector2i = Vector2i(16800, 46900)
const STEEP_HILL_RISE_CM: int = 1520
const STEEP_HILL_WEST_RADIUS_CM: int = 1940
const STEEP_HILL_EAST_RADIUS_CM: int = 3850
const STEEP_HILL_NORTH_SOUTH_RADIUS_CM: int = 3300
## Caminho de oeste a leste. 512 m cai sobre uma linha da grade e uma faixa simétrica ali teria 4 m ou
## 8 m; para ter os 6 m pedidos, o eixo fica em 513 m (meio da célula): 3 células, de 510 m a 516 m.
const PATH_AXIS_Z_CM: int = 51300
const PATH_HALF_WIDTH_CM: int = 300
## Pedra: célula cuja inclinação média passa de 27 %, ou cujo topo passa de 26 m acima da planície.
## Fora isso (e fora do caminho), grama. Hipótese a ajustar olhando a tela.
const ROCK_SLOPE_LIMIT_PERMILLE: int = 270
const ROCK_RISE_LIMIT_CM: int = 2600
## Ponto de nascimento: sobre o caminho, a oeste.
const SPAWN_CM: Vector2i = Vector2i(10000, 51200)

# --- Códigos de superfície gravados em surface_types.json ---
const SURFACE_GRASS: int = 1
const SURFACE_PATH: int = 2
const SURFACE_ROCK: int = 3
const PERMILLE: int = 1000
## Escala inteira da forma (10000 = 100 %). Com 1000 o arredondamento criava degraus de até ~4 cm entre
## nós vizinhos (medido: 30,5 % de inclinação onde a fórmula dá 28,9 %); com 10000 o erro é de ~1 cm.
## O maior produto, amplitude * escala², fica em ~3·10¹¹, bem abaixo do limite exato de IntMath (9·10¹⁵).
const RELIEF_SCALE: int = 10000


## Altura (cm) do nó em (x, z) cm. O caminho é achatado na altura da planície, mesmo que a colina
## ou o vale um dia cheguem até ele.
static func node_height_cm(x_cm: int, z_cm: int) -> int:
	if absi(z_cm - PATH_AXIS_Z_CM) <= PATH_HALF_WIDTH_CM:
		return PLAIN_HEIGHT_CM
	var hill: int = _bump_cm(x_cm, z_cm, HILL_CENTER_CM, HILL_RADIUS_CM, HILL_RISE_CM)
	var valley: int = _bump_cm(x_cm, z_cm, VALLEY_CENTER_CM, VALLEY_RADIUS_CM, VALLEY_DEPTH_CM)
	return PLAIN_HEIGHT_CM + hill + _steep_hill_cm(x_cm, z_cm) - valley


## Saliência suave, em inteiros: amplitude * (1 - d²/R²)², com d²/R² na escala RELIEF_SCALE; zero a
## partir do raio. Tem topo arredondado e acaba sem degrau na borda.
static func _bump_cm(x_cm: int, z_cm: int, center_cm: Vector2i, radius_cm: int, amplitude_cm: int) -> int:
	var delta_x: int = x_cm - center_cm.x
	var delta_z: int = z_cm - center_cm.y
	var distance_sq: int = delta_x * delta_x + delta_z * delta_z
	var radius_sq: int = radius_cm * radius_cm
	if distance_sq >= radius_sq:
		return 0
	var inside: int = RELIEF_SCALE - IntMath.floor_div(RELIEF_SCALE * distance_sq, radius_sq)
	return IntMath.floor_div(amplitude_cm * inside * inside, RELIEF_SCALE * RELIEF_SCALE)


## Subida (cm) do morro íngreme no nó (x, z): a mesma saliência suave, amplitude * (1 - s²)², com s² = (dx / raio_x)² + (dz / raio_z)² na
## escala RELIEF_SCALE, mas o raio em x é o do lado oeste ou o do lado leste do pico. As duas metades têm derivada zero no pico, então não
## há quina. Zero a partir de s² = 1. Só inteiros (cada produto cabe com folga nos 64 bits).
static func _steep_hill_cm(x_cm: int, z_cm: int) -> int:
	var delta_x: int = x_cm - STEEP_HILL_CENTER_CM.x
	var delta_z: int = z_cm - STEEP_HILL_CENTER_CM.y
	var radius_x: int = STEEP_HILL_WEST_RADIUS_CM if delta_x < 0 else STEEP_HILL_EAST_RADIUS_CM
	var radius_z: int = STEEP_HILL_NORTH_SOUTH_RADIUS_CM
	var distance_sq: int = IntMath.floor_div(RELIEF_SCALE * delta_x * delta_x, radius_x * radius_x) + IntMath.floor_div(RELIEF_SCALE * delta_z * delta_z, radius_z * radius_z)
	if distance_sq >= RELIEF_SCALE:
		return 0
	var inside: int = RELIEF_SCALE - distance_sq
	return IntMath.floor_div(STEEP_HILL_RISE_CM * inside * inside, RELIEF_SCALE * RELIEF_SCALE)


## Alturas de todos os nós, por linhas de z (convenção de docs/modules/world.md).
static func build_heights() -> PackedInt64Array:
	var nodes_per_side: int = CELLS_PER_SIDE + 1
	var heights: PackedInt64Array = PackedInt64Array()
	heights.resize(nodes_per_side * nodes_per_side)
	for node_z: int in nodes_per_side:
		for node_x: int in nodes_per_side:
			heights[node_z * nodes_per_side + node_x] = node_height_cm(node_x * CELL_SIZE_CM, node_z * CELL_SIZE_CM)
	return heights


## Superfície de cada célula, por linhas de z: caminho na faixa do caminho; senão pedra ou grama.
static func build_surfaces(heights: PackedInt64Array) -> PackedInt64Array:
	var nodes_per_side: int = CELLS_PER_SIDE + 1
	var surfaces: PackedInt64Array = PackedInt64Array()
	surfaces.resize(CELLS_PER_SIDE * CELLS_PER_SIDE)
	for cell_z: int in CELLS_PER_SIDE:
		var is_path_row: bool = absi(cell_z * CELL_SIZE_CM + IntMath.floor_div(CELL_SIZE_CM, 2) - PATH_AXIS_Z_CM) <= PATH_HALF_WIDTH_CM
		for cell_x: int in CELLS_PER_SIDE:
			var surface: int = SURFACE_PATH if is_path_row else _natural_surface(heights, cell_z * nodes_per_side + cell_x, nodes_per_side)
			surfaces[cell_z * CELLS_PER_SIDE + cell_x] = surface
	return surfaces


## Pedra ou grama. A inclinação é a média da célula nos dois eixos (módulo do gradiente), que não
## depende da direção da encosta; os desníveis são dobrados para ficar em inteiros, daí o fator 4.
static func _natural_surface(heights: PackedInt64Array, first_node: int, nodes_per_side: int) -> int:
	var near_left: int = heights[first_node]
	var near_right: int = heights[first_node + 1]
	var far_left: int = heights[first_node + nodes_per_side]
	var far_right: int = heights[first_node + nodes_per_side + 1]
	var slope_x_twice: int = (near_right + far_right) - (near_left + far_left)
	var slope_z_twice: int = (far_left + far_right) - (near_left + near_right)
	var steepness: int = (slope_x_twice * slope_x_twice + slope_z_twice * slope_z_twice) * PERMILLE * PERMILLE
	var steepness_limit: int = 4 * ROCK_SLOPE_LIMIT_PERMILLE * ROCK_SLOPE_LIMIT_PERMILLE * CELL_SIZE_CM * CELL_SIZE_CM
	var highest: int = maxi(maxi(near_left, near_right), maxi(far_left, far_right))
	if steepness > steepness_limit or highest - PLAIN_HEIGHT_CM > ROCK_RISE_LIMIT_CM:
		return SURFACE_ROCK
	return SURFACE_GRASS


## Texto dos dois arquivos (nome -> conteúdo). Mesmos dados, mesmo texto, byte a byte.
static func render_files(heights: PackedInt64Array, surfaces: PackedInt64Array) -> Dictionary[String, String]:
	var terrain_lines: PackedStringArray = [
		"[",
		"\t{",
		"\t\t\"id\": \"%s\"," % TERRAIN_ID,
		"\t\t\"cells_x\": %d," % CELLS_PER_SIDE,
		"\t\t\"cells_z\": %d," % CELLS_PER_SIDE,
		"\t\t\"cell_size_cm\": %d," % CELL_SIZE_CM,
		"\t\t\"chunk_cells\": %d," % CHUNK_CELLS,
		"\t\t\"spawn_x_cm\": %d," % SPAWN_CM.x,
		"\t\t\"spawn_z_cm\": %d," % SPAWN_CM.y,
		"\t\t\"heights_cm\": [",
		_render_rows(heights, CELLS_PER_SIDE + 1),
		"\t\t],",
		"\t\t\"surfaces\": [",
		_render_rows(surfaces, CELLS_PER_SIDE),
		"\t\t]",
		"\t}",
		"]",
		"",
	]
	var surface_lines: PackedStringArray = [
		"[",
		"\t{\"id\": \"grass\", \"code\": %d}," % SURFACE_GRASS,
		"\t{\"id\": \"path\", \"code\": %d}," % SURFACE_PATH,
		"\t{\"id\": \"rock\", \"code\": %d}" % SURFACE_ROCK,
		"]",
		"",
	]
	var files: Dictionary[String, String] = {}
	files[TERRAIN_FILE] = "\n".join(terrain_lines)
	files[SURFACE_FILE] = "\n".join(surface_lines)
	return files


## Uma linha do arquivo por linha de z da grade, para o diff do Git ficar legível.
static func _render_rows(values: PackedInt64Array, per_row: int) -> String:
	var rows: PackedStringArray = PackedStringArray()
	for first: int in range(0, values.size(), per_row):
		var texts: PackedStringArray = PackedStringArray()
		for position: int in range(first, first + per_row):
			texts.append(str(values[position]))
		rows.append("\t\t\t" + ", ".join(texts))
	return ",\n".join(rows)


## Resumo em português: tamanho, nós, células, chunks, alturas e ponto de nascimento.
static func describe(heights: PackedInt64Array, surfaces: PackedInt64Array) -> PackedStringArray:
	var lowest: int = heights[0]
	var highest: int = heights[0]
	for height: int in heights:
		lowest = mini(lowest, height)
		highest = maxi(highest, height)
	var counts: Dictionary[int, int] = {SURFACE_GRASS: 0, SURFACE_PATH: 0, SURFACE_ROCK: 0}
	for code: int in surfaces:
		counts[code] = counts.get(code, 0) + 1
	var side_m: float = _meters(CELLS_PER_SIDE * CELL_SIZE_CM)
	var chunks_per_side: int = IntMath.floor_div(CELLS_PER_SIDE, CHUNK_CELLS)
	var lines: PackedStringArray = PackedStringArray()
	lines.append("Terreno de blockout '%s' (dados de teste, DEC-118)" % TERRAIN_ID)
	lines.append("Tamanho: %.0f m x %.0f m (%d x %d células de %.0f m)" % [side_m, side_m, CELLS_PER_SIDE, CELLS_PER_SIDE, _meters(CELL_SIZE_CM)])
	lines.append("Chunks: %d x %d, de %.0f m (%d células por lado)" % [chunks_per_side, chunks_per_side, _meters(CHUNK_CELLS * CELL_SIZE_CM), CHUNK_CELLS])
	lines.append("Nós: %d · células: %d" % [heights.size(), surfaces.size()])
	lines.append("Alturas: mínima %.2f m · máxima %.2f m" % [_meters(lowest), _meters(highest)])
	lines.append("Superfícies (células): grass %d · path %d · rock %d" % [counts[SURFACE_GRASS], counts[SURFACE_PATH], counts[SURFACE_ROCK]])
	lines.append("Ponto de nascimento: (%.0f m, %.0f m), altura %.2f m" % [_meters(SPAWN_CM.x), _meters(SPAWN_CM.y), _meters(node_height_cm(SPAWN_CM.x, SPAWN_CM.y))])
	return lines


static func _meters(centimeters: int) -> float:
	return float(centimeters) / TerrainData.CM_PER_METER


## Executa a ferramenta com os argumentos da linha de comando. Sucesso: `message` traz o relatório.
## Falha: código e mensagem dizem o que houve. Fica aqui (e não no script de entrada) para os testes
## chamarem direto, sem abrir outro Godot.
static func run(arguments: PackedStringArray) -> Result:
	var options: Options = _parse_arguments(arguments)
	if not options.error.is_empty():
		return Result.failure(CODE_USAGE, "%s\n%s" % [options.error, USAGE])
	if not DirAccess.dir_exists_absolute(options.out_dir):
		return Result.failure(CODE_BAD_OUT_DIR, "pasta de saída inexistente: %s (a ferramenta não cria pastas; crie-a antes)." % options.out_dir)
	var heights: PackedInt64Array = build_heights()
	var surfaces: PackedInt64Array = build_surfaces(heights)
	var files: Dictionary[String, String] = render_files(heights, surfaces)
	var report: PackedStringArray = describe(heights, surfaces)
	if options.check_only:
		return _check_files(options.out_dir, files, report)
	return _write_files(options.out_dir, files, report)


static func _parse_arguments(arguments: PackedStringArray) -> Options:
	var options: Options = Options.new()
	var index: int = 0
	while index < arguments.size():
		var flag: String = arguments[index]
		if flag == "--check":
			options.check_only = true
			index += 1
		elif flag == "--out" and index + 1 < arguments.size():
			options.out_dir = _resolve_dir(arguments[index + 1])
			index += 2
		elif flag == "--out":
			options.error = "a opção --out precisa de uma pasta."
			break
		else:
			options.error = "opção desconhecida: '%s'." % flag
			break
	return options


## Caminho relativo vale a partir da raiz do projeto (o Godot roda com --path nela).
static func _resolve_dir(path: String) -> String:
	if path.is_absolute_path():
		return path
	return "res://".path_join(path)


static func _write_files(out_dir: String, files: Dictionary[String, String], report: PackedStringArray) -> Result:
	var lines: PackedStringArray = report.duplicate()
	for file_name: String in files:
		var path: String = out_dir.path_join(file_name)
		var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
		if file == null:
			return Result.failure(CODE_WRITE_FAILED, "não foi possível abrir %s para gravar (erro %d)." % [path, FileAccess.get_open_error()])
		var is_stored: bool = file.store_string(files[file_name])
		file.close()
		if not is_stored:
			return Result.failure(CODE_WRITE_FAILED, "falha ao gravar o conteúdo de %s." % path)
		lines.append("Gravado: %s (%d bytes)" % [path, files[file_name].to_utf8_buffer().size()])
	return Result.new(true, "", "\n".join(lines))


## Não grava: só confere se os arquivos existentes são idênticos ao que seria gerado.
static func _check_files(out_dir: String, files: Dictionary[String, String], report: PackedStringArray) -> Result:
	var differences: PackedStringArray = PackedStringArray()
	for file_name: String in files:
		var path: String = out_dir.path_join(file_name)
		if not FileAccess.file_exists(path):
			differences.append("%s: arquivo ausente" % path)
		elif FileAccess.get_file_as_string(path) != files[file_name]:
			differences.append("%s: conteúdo diferente do que a ferramenta geraria" % path)
	if not differences.is_empty():
		return Result.failure(CODE_CHECK_DIFFERS, "\n".join(differences))
	return Result.new(true, "", "\n".join(report) + "\nConferido: os arquivos de %s são idênticos ao que a ferramenta geraria." % out_dir)


## Opções já lidas da linha de comando; `error` vazio significa que estão certas.
class Options:
	extends RefCounted

	var out_dir: String = BlockoutTerrainGenerator.DEFAULT_OUT_DIR
	var check_only: bool = false
	var error: String = ""
