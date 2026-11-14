class_name InhabitantsDemoScene
extends RendererTestScene
## Cena de DEMONSTRAÇÃO dos habitantes (ART-9 e 9b, protótipo isolado, só apresentação; fora de `src/`, sem ligação com a simulação, a ponte, o `NpcView` nem o `main.tscn`): a luz e a câmera da cena de teste de renderizadores (RendererTestScene, herdada) e os habitantes do InhabitantView em primeiro plano, sobre dois cenários: a praça procedural sem barracas (conjunto `praca`) e a vila de teste com peças da Kenney (conjunto `kenney`, KenneyVillage; na cena `inhabitants_kenney_demo.tscn` ele é o único). Rode com `tools/visual/run_inhabitants_demo [pasta] [praca|kenney]` (abre janela; automático: com `--auto --out=<pasta>` grava os PNGs de 1280 x 720 (prefixo do conjunto), as folhas de contato e o `resumo.txt` com as medidas e encerra; sem `--set=` faz os dois conjuntos). Sem `--auto` mostra o alinhamento dos seis. Ferramenta de desenvolvimento: mede, não decide.

const SETTLE_FRAMES: int = 30
const MEASURE_FRAMES: int = 180
const SUMMARY_FILE: String = "resumo.txt"
const SUMMARY_COLUMNS: String = "captura | fps médio | pior quadro (ms) | chamadas de desenho | primitivos | habitantes | triângulos dos habitantes | arquivo"
const CAPTURE_SIZE: Vector2i = Vector2i(1280, 720)
const SET_PLAZA: String = "praca"
const SET_VILLAGE: String = "kenney"
const ARG_SET: String = "--set="
const PREFIX_FORMAT: String = "%s_"
const CONTACT_CELL: Vector2i = Vector2i(640, 360)
const MICROSECONDS_PER_SECOND: float = 1000000.0
const MICROSECONDS_PER_MS: float = 1000.0
const TRIANGLE_VERTICES: float = 3.0
## Os seis do alinhamento (id, papel), escolhidos por varredura da faixa de IDs para bater com a descrição: aldeão alto e magro de capuz com cesta, aldeão baixo e redondo de boné com saco, comerciante redondo de chapéu largo e bolsa, comerciante alto de avental e bolsinha, guarda alto de elmo e lança, guarda parrudo de elmo e cajado de guarda.
const LINEUP: Array = [[526, &"villager"], [365, &"villager"], [188, &"merchant"], [100, &"merchant"], [100, &"guard"], [114, &"guard"]]
## Closes (índice no alinhamento, nome): o aldeão de capuz, o de boné, o comerciante redondo e o guarda parrudo; os três primeiros nomes sem número entram na folha de contato (alinhamento e três closes, 2 x 2).
const HEROES: Array = [[0, "aldeao"], [1, "aldeao_2"], [2, "comerciante"], [5, "guarda"]]
const CONTACT_HEROES: Array[String] = ["aldeao", "comerciante", "guarda"]
## Folha de variação: o mesmo papel com os IDs SHEET_FIRST_ID a SHEET_FIRST_ID + 5, lado a lado (sufixo do nome do arquivo por papel).
const SHEET_FIRST_ID: int = 1
const SHEET_SIZE: int = 6
const SHEET_SUFFIX: Dictionary[StringName, String] = {InhabitantSpec.VILLAGER: "", InhabitantSpec.MERCHANT: "_comerciante", InhabitantSpec.GUARD: "_guarda"}
const SPACING_M: float = 1.1
## Câmeras dos closes (distância em m, inclinação, giro e campo de visão em graus) sobre o ponto de mira; as da multidão são as do jogo (RendererPresets.VIEWS).
const LINEUP_VIEW: Vector4 = Vector4(5.4, 12.0, -22.0, 55.0)
const HERO_VIEW: Vector4 = Vector4(2.2, 8.0, -25.0, 55.0)
const SHEET_VIEW: Vector4 = Vector4(5.6, 12.0, -22.0, 55.0)
const GAME_FOV: float = 75.0
const AIM_Y_M: float = 0.95
const DEFAULT_AIM: Vector3 = Vector3(0.0, AIM_Y_M, 0.0)
## Catálogo da Kenney: origem longe da vila, ponto de mira (relativo à origem), câmera (distância, inclinação, giro, campo de visão) e o habitante de comparação (1,72 m).
const CATALOG_ORIGIN: Vector3 = Vector3(400.0, 0.0, 0.0)
const CATALOG_AIM: Vector3 = Vector3(0.0, 1.0, -8.5)
const CATALOG_VIEW: Vector4 = Vector4(26.5, 27.0, 0.0, 55.0)
const CATALOG_DETAIL_AIM: Vector3 = Vector3(0.0, 0.9, -1.0)
const CATALOG_DETAIL_VIEW: Vector4 = Vector4(9.0, 14.0, -15.0, 55.0)
const CATALOG_HUMAN: Array = [304, &"merchant"]
const FACING_RAD: float = PI
const ISOMETRIC_VIEW: int = 1
const STRATEGIC_VIEW: int = 2
## Luz do meio-dia (predefinição 0) e do fim de tarde (1, com o sol girado para bater de frente nos habitantes em vez de contraluz).
const LIGHTS: Array[Dictionary] = [{"preset": 0, "suffix": ""}, {"preset": 1, "suffix": "_tarde"}]
const AFTERNOON_SUN_YAW_DEG: float = -50.0
## Multidão do teste da DEC-119: quantidade, primeiro id, raio do espalhamento (m), mistura de papéis (aldeão abaixo de x, comerciante abaixo de y, o resto guarda) e a distância até a qual o habitante leva o LOD 0 [HIP]: a da própria câmera isométrica (22 m), então só a metade da frente da multidão leva o LOD 0 (o caso mais pesado; o guia visual, seção 4, pede 15 m para o primeiro nível).
const CROWD_SIZE: int = 132
const CROWD_FIRST_ID: int = 1000
const CROWD_RADIUS_M: float = 12.0
const CROWD_MIX: Vector2 = Vector2(0.55, 0.85)
const LOD_NEAR_M: float = 22.0
const CROWD_CHANNELS: Vector3i = Vector3i(1, 2, 3)
## Área da multidão (centro x, centro z, raio x, raio z): o círculo da praça; na vila, uma elipse na rua que deixa as casas livres ao fundo.
const PLAZA_CROWD_AREA: Vector4 = Vector4(0.0, 0.0, CROWD_RADIUS_M, CROWD_RADIUS_M)
const VILLAGE_CROWD_AREA: Vector4 = Vector4(0.0, 2.0, 14.0, 7.0)

## Na cena da Kenney (`inhabitants_kenney_demo.tscn`) só a vila existe, sem a praça.
@export var start_in_village: bool = false

var _actors: Node3D
var _material: Material
var _lines: Array[String] = []
var _plaza_nodes: Array[Node] = []
var _village: KenneyVillage
var _catalog: KenneyVillage
var _catalog_front: Vector3 = Vector3.ZERO
var _prefix: String = ""
var _crowd_area: Vector4 = PLAZA_CROWD_AREA
var _ground_height: Callable = PlazaGround.ground_height
var _contact: Array[Image] = []


func _ready() -> void:
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	var sets: Array[String] = _sets_of(arguments)
	rendering_method = RenderingServer.get_current_rendering_method()
	supported = RendererPresets.supported_effects(rendering_method)
	_build_rig()
	var options: PlazaBuilder.Options = PlazaBuilder.Options.new()
	options.has_structures = false
	options.has_ground = sets.has(SET_PLAZA)
	options.has_vegetation = options.has_ground
	options.has_houses = options.has_ground
	var before: int = get_child_count()
	built = PlazaBuilder.new().build(self, options)
	for index: int in range(before, get_child_count()):
		_plaza_nodes.append(get_child(index))
	_material = built.materials[&"solid"]
	_actors = Node3D.new()
	_actors.name = "Inhabitants"
	add_child(_actors)
	apply_preset(0)
	_enter(sets[0])
	stage(LINEUP, InhabitantBuilder.LOD_NEAR)
	_aim(LINEUP_VIEW)
	if RendererAutoRun.is_requested(arguments):
		await _run(RendererAutoRun.out_dir(arguments), sets)


## Os conjuntos pedidos (`--set=praca` ou `--set=kenney`); sem argumento, os dois (só a vila, na cena da Kenney).
func _sets_of(arguments: PackedStringArray) -> Array[String]:
	var found: Array[String] = []
	for argument: String in arguments:
		if argument.begins_with(ARG_SET):
			found.append(argument.trim_prefix(ARG_SET))
	if found.is_empty():
		found.append(SET_VILLAGE if start_in_village else SET_PLAZA)
		if not start_in_village:
			found.append(SET_VILLAGE)
	return found


## Mostra o cenário do conjunto (a praça ou a vila, que é montada na primeira vez), com o prefixo dos PNGs, a área da multidão e a altura do chão dele.
func _enter(set_id: String) -> void:
	var is_village: bool = set_id == SET_VILLAGE
	_prefix = PREFIX_FORMAT % set_id
	for node: Node in _plaza_nodes:
		if node is Node3D:
			(node as Node3D).visible = not is_village
	if is_village and _village == null:
		_village = KenneyVillage.new(self, "KenneyVillage")
		_village.build_village()
		_village.merge_static()
		_catalog = KenneyVillage.new(self, "KenneyCatalog", CATALOG_ORIGIN)
		_catalog_front = _catalog.build_catalog()
		_catalog.root.visible = false
	if _village != null:
		_village.root.visible = is_village
	_crowd_area = VILLAGE_CROWD_AREA if is_village else PLAZA_CROWD_AREA
	_ground_height = (func(_x: float, _z: float) -> float: return 0.0) if is_village else PlazaGround.ground_height


## Troca os habitantes por `entries` ([id, papel]), lado a lado e de frente para a câmera, todos no LOD `lod`.
func stage(entries: Array, lod: int) -> void:
	_clear()
	for index: int in entries.size():
		var spot: Vector3 = Vector3((index - (entries.size() - 1) * 0.5) * SPACING_M, 0.0, 0.0)
		_place(InhabitantSpec.for_inhabitant(entries[index][0], entries[index][1]), lod, spot, FACING_RAD)


## A multidão: CROWD_SIZE habitantes de papéis misturados, espalhados por hash no chão do cenário e com o LOD pela distância até a câmera ATUAL.
func stage_crowd() -> void:
	_clear()
	for index: int in CROWD_SIZE:
		var mix: float = PlazaMeshKit.unit(index, CROWD_CHANNELS.x)
		var role: StringName = InhabitantSpec.VILLAGER if mix < CROWD_MIX.x else (InhabitantSpec.MERCHANT if mix < CROWD_MIX.y else InhabitantSpec.GUARD)
		var angle: float = TAU * PlazaMeshKit.unit(index, CROWD_CHANNELS.y)
		var radius: float = sqrt(PlazaMeshKit.unit(index, CROWD_CHANNELS.z))
		var spot: Vector3 = Vector3(_crowd_area.x + cos(angle) * radius * _crowd_area.z, 0.0, _crowd_area.y + sin(angle) * radius * _crowd_area.w)
		spot.y = float(_ground_height.call(spot.x, spot.z))
		var lod: int = InhabitantBuilder.LOD_NEAR if camera.global_position.distance_to(spot) < LOD_NEAR_M else InhabitantBuilder.LOD_FAR
		_place(InhabitantSpec.for_inhabitant(CROWD_FIRST_ID + index, role), lod, spot, TAU * PlazaMeshKit.unit(index, CROWD_CHANNELS.z + 1))


## Triângulos de todas as malhas dos habitantes da cena.
func actors_triangles() -> int:
	var vertices: int = 0
	for view: Node in _actors.get_children():
		vertices += ((view as InhabitantView).get_child(0) as MeshInstance3D).mesh.get_faces().size()
	return int(vertices / TRIANGLE_VERTICES)


func _clear() -> void:
	for view: Node in _actors.get_children():
		_actors.remove_child(view)
		view.free()


func _place(spec: InhabitantSpec, lod: int, spot: Vector3, yaw: float) -> void:
	var view: InhabitantView = InhabitantView.new()
	_actors.add_child(view)
	view.spawn(spec, lod, _material)
	view.position = spot
	view.rotation.y = yaw


func _aim(view: Vector4, target: Vector3 = DEFAULT_AIM) -> void:
	var pitch: float = deg_to_rad(view.y)
	var arm: Vector3 = (Vector3(0.0, sin(pitch), cos(pitch)) * view.x).rotated(Vector3.UP, deg_to_rad(view.z))
	camera.transform = Transform3D(Basis.looking_at(-arm, Vector3.UP), target + arm)
	camera.fov = view.w


func _run(out_path: String, sets: Array[String]) -> void:
	if DisplayServer.get_name() == RendererAutoRun.HEADLESS_DISPLAY or out_path.is_empty() or DirAccess.make_dir_recursive_absolute(out_path) != OK:
		push_error("InhabitantsDemoScene._run: precisa de janela e de uma pasta de saída válida (--out=<pasta>); recebeu '%s'." % out_path)
		get_tree().quit(1)
		return
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	_lines.append("renderer: %s | driver: %s | placa: %s | godot: %s | build de %s" % [rendering_method, RenderingServer.get_current_rendering_driver_name(), RenderingServer.get_video_adapter_name(), Engine.get_version_info()["string"], "depuração" if OS.is_debug_build() else "release"])
	_lines.append("janela: %s | vsync desligado | %d quadros de acomodação por captura e mais %d medidos nas multidões | conjuntos: %s" % [DisplayServer.window_get_size(), SETTLE_FRAMES, MEASURE_FRAMES, ", ".join(sets)])
	_lines.append(SUMMARY_COLUMNS)
	for set_id: String in sets:
		_enter(set_id)
		for light: Dictionary in LIGHTS:
			apply_preset(light["preset"])
			if light["preset"] == 1:
				sun.rotation_degrees.y = AFTERNOON_SUN_YAW_DEG
			if set_id == SET_VILLAGE:
				await _shoot_village(out_path, light["suffix"])
			else:
				await _shoot_plaza(out_path, light["suffix"])
	if _village != null:
		_lines.append("vila da Kenney: %d peças montadas (%d triângulos), catálogo com %d peças (%d triângulos), fator de escala %.1f" % [_village.pieces, _village.triangles, _catalog.pieces, _catalog.triangles, KenneyVillage.SCALE])
	var file: FileAccess = FileAccess.open(out_path.path_join(SUMMARY_FILE), FileAccess.WRITE)
	if file != null:
		file.store_string("\n".join(_lines) + "\n")
	get_tree().quit()


func _shoot_plaza(out_path: String, suffix: String) -> void:
	stage(LINEUP, InhabitantBuilder.LOD_NEAR)
	_aim(LINEUP_VIEW)
	await _shoot("alinhamento" + suffix, out_path, 0, true)
	stage(LINEUP, InhabitantBuilder.LOD_FAR)
	await _shoot("alinhamento_lod1" + suffix, out_path, 0)
	await _shoot_heroes(out_path, suffix)
	for role: StringName in SHEET_SUFFIX:
		var sheet: Array = []
		for index: int in SHEET_SIZE:
			sheet.append([SHEET_FIRST_ID + index, role])
		stage(sheet, InhabitantBuilder.LOD_NEAR)
		_aim(SHEET_VIEW)
		await _shoot("folha_de_variacao%s%s" % [SHEET_SUFFIX[role], suffix], out_path, 0)
	await _shoot_crowds(out_path, suffix)
	_save_contact(out_path, "contato" + suffix)


## A vila: alinhamento, closes, multidões e, por último, o catálogo das 37 peças ao lado de um habitante de 1,72 m.
func _shoot_village(out_path: String, suffix: String) -> void:
	stage(LINEUP, InhabitantBuilder.LOD_NEAR)
	_aim(LINEUP_VIEW)
	await _shoot("alinhamento" + suffix, out_path, 0, true)
	await _shoot_heroes(out_path, suffix)
	await _shoot_crowds(out_path, suffix)
	_save_contact(out_path, "contato" + suffix)
	_village.root.visible = false
	_catalog.root.visible = true
	_clear()
	_place(InhabitantSpec.for_inhabitant(CATALOG_HUMAN[0], CATALOG_HUMAN[1]), InhabitantBuilder.LOD_NEAR, _catalog_front, FACING_RAD)
	_aim(CATALOG_VIEW, CATALOG_ORIGIN + CATALOG_AIM)
	await _shoot("catalogo" + suffix, out_path, 0)
	_aim(CATALOG_DETAIL_VIEW, _catalog_front + CATALOG_DETAIL_AIM)
	await _shoot("catalogo_detalhe" + suffix, out_path, 0)
	_catalog.root.visible = false
	_village.root.visible = true


func _shoot_heroes(out_path: String, suffix: String) -> void:
	for hero: Array in HEROES:
		stage([LINEUP[hero[0]]], InhabitantBuilder.LOD_NEAR)
		_aim(HERO_VIEW)
		await _shoot("heroi_%s%s" % [hero[1], suffix], out_path, 0, CONTACT_HEROES.has(hero[1]))


func _shoot_crowds(out_path: String, suffix: String) -> void:
	camera.fov = GAME_FOV
	for crowd_view: Array in [[ISOMETRIC_VIEW, "multidao_iso"], [STRATEGIC_VIEW, "multidao_estrategica"]]:
		apply_view(crowd_view[0])
		stage_crowd()
		await _shoot(crowd_view[1] + suffix, out_path, MEASURE_FRAMES)


## Espera os quadros de acomodação e os medidos (só a multidão mede), depois do desenho do último lê os monitores, salva o PNG (com o prefixo do conjunto) e anota a linha do resumo; `is_contact` guarda a imagem para a folha de contato.
func _shoot(label: String, out_path: String, measure_frames: int, is_contact: bool = false) -> void:
	var total_us: int = 0
	var worst_us: int = 0
	var last_us: int = Time.get_ticks_usec()
	for frame: int in SETTLE_FRAMES + measure_frames:
		await get_tree().process_frame
		var now_us: int = Time.get_ticks_usec()
		if frame >= SETTLE_FRAMES:
			total_us += now_us - last_us
			worst_us = maxi(worst_us, now_us - last_us)
		last_us = now_us
	await RenderingServer.frame_post_draw
	var image: Image = get_viewport().get_texture().get_image()
	if image.get_size() != CAPTURE_SIZE:
		image.resize(CAPTURE_SIZE.x, CAPTURE_SIZE.y, Image.INTERPOLATE_BILINEAR)
	var file: String = "%s%s.png" % [_prefix, label]
	if image.save_png(out_path.path_join(file)) != OK:
		push_error("InhabitantsDemoScene._shoot: não foi possível gravar '%s'." % file)
	if is_contact:
		_contact.append(image)
	var fps: String = "-" if measure_frames == 0 else "%.1f" % (float(measure_frames) * MICROSECONDS_PER_SECOND / float(maxi(total_us, 1)))
	var worst: String = "-" if measure_frames == 0 else "%.1f" % (float(worst_us) / MICROSECONDS_PER_MS)
	_lines.append(" | ".join([_prefix + label, fps, worst, str(int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))), str(int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))), str(_actors.get_child_count()), str(actors_triangles()), file]))


## Monta as imagens guardadas (até quatro) numa folha 2 x 2 em meia resolução, para olhar vários closes de uma vez.
func _save_contact(out_path: String, label: String) -> void:
	if _contact.is_empty():
		return
	var cell: Vector2i = CONTACT_CELL
	var sheet: Image = Image.create(CAPTURE_SIZE.x, CAPTURE_SIZE.y, false, _contact[0].get_format())
	for index: int in _contact.size():
		_contact[index].resize(cell.x, cell.y, Image.INTERPOLATE_BILINEAR)
		sheet.blit_rect(_contact[index], Rect2i(Vector2i.ZERO, cell), Vector2i((index % 2) * cell.x, (index >> 1) * cell.y))
	_contact.clear()
	if sheet.save_png(out_path.path_join("%s%s.png" % [_prefix, label])) != OK:
		push_error("InhabitantsDemoScene._save_contact: não foi possível gravar a folha de contato '%s'." % label)
