class_name InhabitantsV8Shots
extends RefCounted
## Capturas da ART-9e (ferramenta de arte, protótipo isolado, fora de `src/`): chamada pela cena de demonstração com `--set=v8`, na vila da Kenney. Escolhe por varredura 12 pessoas bem diferentes (4 por papel, um por subarquétipo, as de cor mais distante entre si) e grava: `matriz_arquetipos` (3 linhas, uma por papel, 4 colunas, fundo neutro, de frente), `lineup_variedade`, `comparacao_arquetipos` (e `_perto`), `silhuetas` (as 12 em preto chapado contra o céu), `rostos` (folha de 8 rostos), `grupo_misto_vila` (e `_tarde`), `antes_depois` (a v7 congelada à esquerda e a v8 à direita, os MESMOS ids) e as multidões de 132. O resumo ganha os triângulos reais por papel, nível e subarquétipo (varredura de SWEEP_IDS ids) e as 12 escolhidas.

const SWEEP_IDS: int = 40
const PICK_IDS: int = 60
const ROW_SPACING_M: float = 1.4
const ROW_VIEW: Vector4 = Vector4(9.0, 0.0, 0.0, 26.0)
const ROW_BAND: Vector2i = Vector2i(130, 410)
const NEUTRAL: Color = Color("B9B5AD")
const SKY_COLOR: Color = Color("CFE4F5")
const GROUP_VIEW: Vector4 = Vector4(12.0, 11.0, 0.0, 42.0)
const GROUP_AIM: Vector3 = Vector3(0.0, 0.85, -0.6)
const STAGGER_M: float = 0.6
const ROW_DEPTH_M: float = 1.5
const THREE_QUARTER_YAW: float = PI + 0.5
const COMPARE_VIEWS: Array[Vector4] = [Vector4(5.2, 8.0, -12.0, 40.0), Vector4(2.9, 6.0, -12.0, 40.0)]
const COMPARE_PICKS: Array = [[InhabitantSpec.VILLAGER, 1], [InhabitantSpec.MERCHANT, 0], [InhabitantSpec.GUARD, 2]]
const FACE_PICKS: Array = [[InhabitantSpec.VILLAGER, 1], [InhabitantSpec.VILLAGER, 2], [InhabitantSpec.VILLAGER, 3], [InhabitantSpec.VILLAGER, 0], [InhabitantSpec.MERCHANT, 1], [InhabitantSpec.MERCHANT, 3], [InhabitantSpec.GUARD, 0], [InhabitantSpec.GUARD, 1]]
const FACE_VIEW: Vector4 = Vector4(1.9, 4.0, 0.0, 38.0)
const FACE_AIM_FRACTION: float = 0.8
const FACE_CROP: Rect2i = Rect2i(320, 0, 640, 720)
const FACE_CELL: Vector2i = Vector2i(320, 360)
const BEFORE_AFTER_PICKS: Array = [[InhabitantSpec.VILLAGER, 1], [InhabitantSpec.MERCHANT, 0], [InhabitantSpec.GUARD, 2]]
const BLOCK_X_M: float = 3.1

var _scene: InhabitantsDemoScene
var _picks: Dictionary[StringName, Array] = {}
var _saved: Array = []


func _init(scene: InhabitantsDemoScene) -> void:
	_scene = scene


func run(out_path: String, suffix: String) -> void:
	_scene.village.root.visible = true
	_pick()
	if suffix.is_empty():
		_sweep()
	await _group("grupo_misto_vila" + suffix, out_path, _all(), GROUP_VIEW)
	await _compare(out_path, suffix)
	if not suffix.is_empty():
		return
	await _rows(out_path, "matriz_arquetipos", false)
	await _lineup(out_path)
	await _faces(out_path)
	await _before_after(out_path)
	await _rows(out_path, "silhuetas", true)
	await _scene.shoot_crowds(out_path, suffix)


func _entry(role: StringName, sub: int) -> Array:
	var ids: Array = _picks[role]
	return [ids[sub], role]


func _all() -> Array:
	var list: Array = []
	for role: StringName in InhabitantSpec.ROLES:
		for sub: int in 4:
			list.append(_entry(role, sub))
	return list


func _spec(entry: Array) -> InhabitantSpec:
	return InhabitantSpec.for_inhabitant(entry[0], entry[1])


## Para cada papel e subarquétipo, o id (1 a PICK_IDS) cujas cores mais se afastam das já escolhidas do papel.
func _pick() -> void:
	for role: StringName in InhabitantSpec.ROLES:
		var chosen: Array[int] = []
		var taken: Array[InhabitantSpec] = []
		for sub: int in 4:
			var best_id: int = 0
			var best_score: float = -1.0
			for id: int in range(1, PICK_IDS + 1):
				var spec: InhabitantSpec = InhabitantSpec.for_inhabitant(id, role)
				if spec.archetype != sub:
					continue
				var score: float = 0.0
				for other: InhabitantSpec in taken:
					score += _gap(spec.top, other.top) + _gap(spec.cover_color, other.cover_color) + _gap(spec.skin, other.skin) * 0.5
				if score > best_score:
					best_score = score
					best_id = id
			chosen.append(best_id)
			taken.append(InhabitantSpec.for_inhabitant(best_id, role))
		_picks[role] = chosen


func _gap(first: Color, second: Color) -> float:
	return pow(first.r - second.r, 2.0) + pow(first.g - second.g, 2.0) + pow(first.b - second.b, 2.0)


func _triangles(spec: InhabitantSpec, lod: int) -> int:
	return int(InhabitantBuilder.build(spec, lod, _scene.material).get_faces().size() / 3.0)


## Triângulos reais por papel e nível (mínimo, média, máximo) e por subarquétipo no LOD 0, e as 12 pessoas escolhidas.
func _sweep() -> void:
	for role: StringName in InhabitantSpec.ROLES:
		var cells: Array[String] = []
		for lod: int in 3:
			var low: int = 1000000
			var high: int = 0
			var total: int = 0
			for id: int in range(1, SWEEP_IDS + 1):
				var count: int = _triangles(InhabitantSpec.for_inhabitant(id, role), lod)
				low = mini(low, count)
				high = maxi(high, count)
				total += count
			cells.append("LOD %d: %d / %d / %d" % [lod, low, int(total / float(SWEEP_IDS)), high])
		_scene.lines.append("triângulos de %s (ids 1 a %d, mínimo / média / máximo): %s" % [role, SWEEP_IDS, " | ".join(cells)])
		for sub: int in 4:
			var parts: Array[String] = []
			for lod: int in 3:
				var high: int = 0
				for id: int in range(1, SWEEP_IDS + 1):
					var spec: InhabitantSpec = InhabitantSpec.for_inhabitant(id, role)
					if spec.archetype == sub:
						high = maxi(high, _triangles(spec, lod))
				parts.append("LOD %d máx %d" % [lod, high])
			_scene.lines.append("  %s / %s: %s" % [role, InhabitantArchetypes.entry(role, sub)["name"], " | ".join(parts)])
	for entry: Array in _all():
		var spec: InhabitantSpec = _spec(entry)
		_scene.lines.append("escolhida: %s id %d (%s): altura %.2f m, largura %.2f m, barriga %.2f, constituição %d, idade %d, LOD 0 %d triângulos" % [entry[1], entry[0], spec.archetype_name, spec.height_m, spec.width_m, spec.belly, spec.build, spec.age, _triangles(spec, 0)])


## Duas fileiras escalonadas dos `entries`, em 3/4 para a câmera.
func _group(label: String, out_path: String, entries: Array, view: Vector4) -> void:
	_scene.clear_actors()
	var per_row: int = int(ceil(entries.size() / 2.0))
	for index: int in entries.size():
		var row: int = index % 2
		var column: int = index >> 1
		var spot: Vector3 = Vector3((column - (per_row - 1) * 0.5) * 1.75 + row * STAGGER_M, 0.0, -row * ROW_DEPTH_M)
		_scene.place(_spec(entries[index]), InhabitantBuilder.LOD_NEAR, spot, THREE_QUARTER_YAW)
	_scene.aim(view, GROUP_AIM)
	await _scene.shoot(label, out_path, 0)


func _lineup(out_path: String) -> void:
	var mixed: Array = []
	for sub: int in 4:
		for role: StringName in InhabitantSpec.ROLES:
			mixed.append(_entry(role, sub))
	await _group("lineup_variedade", out_path, mixed.slice(0, 10), Vector4(11.0, 10.0, 0.0, 42.0))


## Os três papéis, um de cada: de corpo inteiro e de perto.
func _compare(out_path: String, suffix: String) -> void:
	var names: Array[String] = ["comparacao_arquetipos", "comparacao_arquetipos_perto"]
	for index: int in COMPARE_VIEWS.size():
		if index > 0 and not suffix.is_empty():
			return
		_scene.clear_actors()
		for slot: int in COMPARE_PICKS.size():
			var pick: Array = COMPARE_PICKS[slot]
			_scene.place(_spec(_entry(pick[0], pick[1])), InhabitantBuilder.LOD_NEAR, Vector3((slot - 1) * 1.45, 0.0, 0.0), PI + 0.18 * (slot - 1))
		_scene.aim(COMPARE_VIEWS[index], Vector3(0.0, 0.95 if index == 0 else 1.15, 0.0))
		await _scene.shoot(names[index] + suffix, out_path, 0)


func _grab() -> Image:
	for frame: int in InhabitantsDemoScene.SETTLE_FRAMES:
		await _scene.get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image: Image = _scene.get_viewport().get_texture().get_image()
	if image.get_size() != InhabitantsDemoScene.CAPTURE_SIZE:
		image.resize(InhabitantsDemoScene.CAPTURE_SIZE.x, InhabitantsDemoScene.CAPTURE_SIZE.y, Image.INTERPOLATE_BILINEAR)
	return image


func _save(image: Image, name: String, out_path: String) -> void:
	if image.save_png(out_path.path_join(name + ".png")) != OK:
		push_error("InhabitantsV8Shots: não foi possível gravar '%s'." % name)
	_scene.lines.append(" | ".join([name, "-", "-", "-", "-", str(_scene.actors.get_child_count()), "-", name + ".png"]))


## Fundo liso (neutro ou céu) sem vila, névoa nem brilho; `restore` devolve o cenário.
func _backdrop(color: Color, is_flat: bool) -> void:
	var environment: Environment = _scene.environment
	_saved = [environment.background_mode, environment.background_color, environment.fog_enabled, environment.glow_enabled]
	environment.glow_enabled = false
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = color
	environment.fog_enabled = false
	_scene.village.root.visible = false
	if is_flat:
		var black: StandardMaterial3D = StandardMaterial3D.new()
		black.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		black.albedo_color = Color.BLACK
		for view: Node in _scene.actors.get_children():
			(view.get_child(0) as MeshInstance3D).material_override = black


func _restore() -> void:
	var environment: Environment = _scene.environment
	environment.background_mode = _saved[0] as Environment.BGMode
	environment.background_color = _saved[1]
	environment.fog_enabled = _saved[2]
	environment.glow_enabled = _saved[3]
	_scene.village.root.visible = true


## 3 linhas (uma por papel) x 4 colunas (um por subarquétipo), de frente, em fundo liso: uma captura por linha, recortada e empilhada numa só imagem.
func _rows(out_path: String, name: String, is_flat: bool) -> void:
	var sheet: Image = null
	var roles: Array[StringName] = InhabitantSpec.ROLES
	for row: int in roles.size():
		_scene.clear_actors()
		for sub: int in 4:
			_scene.place(_spec(_entry(roles[row], sub)), InhabitantBuilder.LOD_NEAR, Vector3((sub - 1.5) * ROW_SPACING_M, 0.0, 0.0), PI)
		_backdrop(SKY_COLOR if is_flat else NEUTRAL, is_flat)
		_scene.aim(ROW_VIEW, Vector3(0.0, 0.95, 0.0))
		var image: Image = await _grab()
		_restore()
		if sheet == null:
			sheet = Image.create(image.get_width(), ROW_BAND.y * roles.size(), false, image.get_format())
		sheet.blit_rect(image, Rect2i(0, ROW_BAND.x, image.get_width(), ROW_BAND.y), Vector2i(0, row * ROW_BAND.y))
	_save(sheet, name, out_path)


## Folha de contato com 8 rostos de perto (4 x 2): suavidade da pele, idade e expressão.
func _faces(out_path: String) -> void:
	var sheet: Image = Image.create(FACE_CELL.x * 4, FACE_CELL.y * 2, false, Image.FORMAT_RGBA8)
	for index: int in FACE_PICKS.size():
		var pick: Array = FACE_PICKS[index]
		var spec: InhabitantSpec = _spec(_entry(pick[0], pick[1]))
		_scene.clear_actors()
		_scene.place(spec, InhabitantBuilder.LOD_NEAR, Vector3.ZERO, PI)
		_scene.aim(FACE_VIEW, Vector3(0.0, spec.height_m * FACE_AIM_FRACTION, 0.0))
		var image: Image = await _grab()
		var cell: Image = image.get_region(FACE_CROP)
		cell.resize(FACE_CELL.x, FACE_CELL.y, Image.INTERPOLATE_BILINEAR)
		cell.convert(Image.FORMAT_RGBA8)
		sheet.blit_rect(cell, Rect2i(Vector2i.ZERO, FACE_CELL), Vector2i((index % 4) * FACE_CELL.x, (index >> 2) * FACE_CELL.y))
	_save(sheet, "rostos", out_path)


## A v7 congelada (esquerda) e a v8 (direita) para os MESMOS ids: dois blocos de três, um por papel, em fileira.
func _before_after(out_path: String) -> void:
	_scene.clear_actors()
	for block: int in 2:
		for index: int in BEFORE_AFTER_PICKS.size():
			var pick: Array = BEFORE_AFTER_PICKS[index]
			var entry: Array = _entry(pick[0], pick[1])
			var spot: Vector3 = Vector3((block * 2 - 1) * BLOCK_X_M + (index - 1) * 1.45, 0.0, 0.0)
			var view: InhabitantView = _scene.place(_spec(entry), InhabitantBuilder.LOD_NEAR, spot, THREE_QUARTER_YAW)
			if block == 0:
				(view.get_child(0) as MeshInstance3D).mesh = V7InhabitantBuilder.build(V7InhabitantSpec.for_inhabitant(entry[0], entry[1]), V7InhabitantBuilder.LOD_NEAR, _scene.material)
	_scene.aim(Vector4(8.4, 9.0, 0.0, 40.0), Vector3(0.0, 0.9, 0.0))
	await _scene.shoot("antes_depois", out_path, 0)
