class_name InhabitantsCompareShots
extends RefCounted
## Capturas de COMPARAÇÃO da ART-9d (ferramenta de arte, protótipo isolado, fora de `src/`): a v6 (cópia congelada em `legacy/`) e a v7 lado a lado, os MESMOS seis ids, na vila da Kenney. Chamada pela cena de demonstração com `--set=v7`: `comparacao_grupo` (v6 à esquerda, v7 à direita, 3/4 frontal), `comparacao_rosto_<papel>` (rosto e ombros), `corpo_<papel>_<n>` (corpo inteiro 3/4, só v7), `grupo_vila` (os seis da v7), `silhuetas` (preto chapado contra o céu) e as multidões de 132; no fim de tarde só o grupo e a comparação. O resumo ganha os triângulos reais por papel e por nível (varredura de SWEEP_IDS ids).

const SWEEP_IDS: int = 40
const GROUP_VIEW: Vector4 = Vector4(7.6, 12.0, 0.0, 42.0)
const GROUP_AIM: Vector3 = Vector3(0.0, 0.85, -0.6)
const BLOCK_X_M: float = 2.75
const SPACING_M: float = 1.25
const STAGGER_M: float = 0.6
const ROW_DEPTH_M: float = 1.5
const THREE_QUARTER_YAW: float = PI + 0.5
const FACE_VIEW: Vector4 = Vector4(1.9, 4.0, 0.0, 38.0)
const FACE_X_M: float = 0.58
const FACE_AIM_FRACTION: float = 0.8
const BODY_VIEW: Vector4 = Vector4(3.9, 6.0, -28.0, 38.0)
const BODY_AIM_FRACTION: float = 0.52
const SILHOUETTE_VIEW: Vector4 = Vector4(6.6, 0.0, 0.0, 45.0)
const SILHOUETTE_SPACING_M: float = 1.15
const SILHOUETTE_COLOR: Color = Color.BLACK
const SKY_COLOR: Color = Color("CFE4F5")
const FACES: Array = [[0, "aldeao"], [2, "comerciante"], [4, "guarda"]]
const BODIES: Array = [[0, "aldeao_1"], [1, "aldeao_2"], [2, "comerciante_1"], [3, "comerciante_2"], [4, "guarda_1"], [5, "guarda_2"]]

var _scene: InhabitantsDemoScene


func _init(scene: InhabitantsDemoScene) -> void:
	_scene = scene


## Todas as capturas da v7 num passe de luz: o meio-dia faz tudo; o fim de tarde, só o grupo e a comparação.
func run(out_path: String, suffix: String) -> void:
	_scene.village.root.visible = true
	if suffix.is_empty():
		_sweep()
	await _group(out_path, suffix)
	if not suffix.is_empty():
		_scene.stage(InhabitantsDemoScene.LINEUP, InhabitantBuilder.LOD_NEAR)
		_scene.aim(InhabitantsDemoScene.LINEUP_VIEW)
		await _scene.shoot("grupo_vila" + suffix, out_path, 0)
		return
	await _faces(out_path)
	await _bodies(out_path)
	_scene.stage(InhabitantsDemoScene.LINEUP, InhabitantBuilder.LOD_NEAR)
	_scene.aim(InhabitantsDemoScene.LINEUP_VIEW)
	await _scene.shoot("grupo_vila", out_path, 0)
	await _silhouettes(out_path)
	await _scene.shoot_crowds(out_path, suffix)


## Triângulos reais por papel e por nível (mínimo, média e máximo da varredura).
func _sweep() -> void:
	for role: StringName in InhabitantSpec.ROLES:
		var cells: Array[String] = []
		for lod: int in 3:
			var low: int = 1000000
			var high: int = 0
			var total: int = 0
			for id: int in range(1, SWEEP_IDS + 1):
				var count: int = int(InhabitantBuilder.build(InhabitantSpec.for_inhabitant(id, role), lod, _scene.material).get_faces().size() / 3.0)
				low = mini(low, count)
				high = maxi(high, count)
				total += count
			cells.append("LOD %d: %d / %d / %d" % [lod, low, int(total / float(SWEEP_IDS)), high])
		_scene.lines.append("triângulos de %s (ids 1 a %d, mínimo / média / máximo): %s" % [role, SWEEP_IDS, " | ".join(cells)])


## A fileira da v6 (esquerda) e a da v7 (direita): dois blocos de três em duas filas, os mesmos ids na mesma ordem, todos em 3/4.
func _group(out_path: String, suffix: String) -> void:
	_scene.clear_actors()
	for block: int in 2:
		for index: int in InhabitantsDemoScene.LINEUP.size():
			var row: int = index % 2
			var spot: Vector3 = Vector3((block * 2 - 1) * BLOCK_X_M + ((index >> 1) - 1) * SPACING_M + row * STAGGER_M, 0.0, -row * ROW_DEPTH_M)
			if block == 0:
				_place_legacy(InhabitantsDemoScene.LINEUP[index], spot)
			else:
				_place_new(InhabitantsDemoScene.LINEUP[index], spot)
	_scene.aim(GROUP_VIEW, GROUP_AIM)
	await _scene.shoot("comparacao_grupo" + suffix, out_path, 0)


func _faces(out_path: String) -> void:
	for pair: Array in FACES:
		var entry: Array = InhabitantsDemoScene.LINEUP[pair[0]]
		_scene.clear_actors()
		_place_legacy(entry, Vector3(-FACE_X_M, 0.0, 0.0))
		var spec: InhabitantSpec = _place_new(entry, Vector3(FACE_X_M, 0.0, 0.0))
		_scene.aim(FACE_VIEW, Vector3(0.0, spec.height_m * FACE_AIM_FRACTION, 0.0))
		await _scene.shoot("comparacao_rosto_%s" % pair[1], out_path, 0)


func _bodies(out_path: String) -> void:
	for pair: Array in BODIES:
		var entry: Array = InhabitantsDemoScene.LINEUP[pair[0]]
		_scene.clear_actors()
		var spec: InhabitantSpec = _place_new(entry, Vector3.ZERO)
		_scene.aim(BODY_VIEW, Vector3(0.0, spec.height_m * BODY_AIM_FRACTION, 0.0))
		await _scene.shoot("corpo_%s" % pair[1], out_path, 0)


## Os seis de frente em preto chapado (sem luz nem cor) contra o céu liso: só a forma conta.
func _silhouettes(out_path: String) -> void:
	_scene.clear_actors()
	var entries: Array = InhabitantsDemoScene.LINEUP
	for index: int in entries.size():
		var spot: Vector3 = Vector3((index - (entries.size() - 1) * 0.5) * SILHOUETTE_SPACING_M, 0.0, 0.0)
		var spec: InhabitantSpec = InhabitantSpec.for_inhabitant(entries[index][0], entries[index][1])
		_scene.place(spec, InhabitantBuilder.LOD_NEAR, spot, PI)
	var black: StandardMaterial3D = StandardMaterial3D.new()
	black.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	black.albedo_color = SILHOUETTE_COLOR
	for view: Node in _scene.actors.get_children():
		(view.get_child(0) as MeshInstance3D).material_override = black
	var environment: Environment = _scene.environment
	var background: int = environment.background_mode
	var is_foggy: bool = environment.fog_enabled
	var is_glowing: bool = environment.glow_enabled
	environment.glow_enabled = false
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = SKY_COLOR
	environment.fog_enabled = false
	_scene.village.root.visible = false
	_scene.aim(SILHOUETTE_VIEW, Vector3(0.0, 0.95, 0.0))
	await _scene.shoot("silhuetas", out_path, 0)
	environment.background_mode = background as Environment.BGMode
	environment.fog_enabled = is_foggy
	environment.glow_enabled = is_glowing
	_scene.village.root.visible = true


func _place_new(entry: Array, spot: Vector3) -> InhabitantSpec:
	var id: int = entry[0]
	var role: StringName = entry[1]
	var spec: InhabitantSpec = InhabitantSpec.for_inhabitant(id, role)
	_scene.place(spec, InhabitantBuilder.LOD_NEAR, spot, THREE_QUARTER_YAW)
	return spec


## A v6 do mesmo id: a ficha congelada e o construtor congelado (a malha entra no lugar da nova).
func _place_legacy(entry: Array, spot: Vector3) -> void:
	var id: int = entry[0]
	var role: StringName = entry[1]
	var view: InhabitantView = _scene.place(InhabitantSpec.for_inhabitant(id, role), InhabitantBuilder.LOD_NEAR, spot, THREE_QUARTER_YAW)
	(view.get_child(0) as MeshInstance3D).mesh = LegacyInhabitantBuilder.build(LegacyInhabitantSpec.for_inhabitant(id, role), LegacyInhabitantBuilder.LOD_NEAR, _scene.material)
