class_name RendererPresets
extends RefCounted
## Predefinições de luz, câmeras e suporte de efeitos da cena de teste de renderizadores (ARTE-F0). Valores [HIP] do guia visual (docs/arte/GUIA_VISUAL.md, seção 6), a calibrar na janela.
## As tabelas são dados: cada predefinição é um Dictionary de campos de tipos diversos (Color, float, int), então a leitura de cada campo é um Variant (fronteira de dados).

## Efeitos que dependem do renderer. `volumetric` não tem tecla: acompanha a névoa.
const EFFECTS: Array[StringName] = [&"bloom", &"ssao", &"fog", &"dof", &"volumetric"]
## [HIP] O que cada método de renderização aceita. O que o Compatibility aceita na 4.7.2 será CONFIRMADO em janela; método desconhecido (inclusive o do modo sem janela) não liga nada.
const SUPPORTED: Dictionary[String, Array] = {
	"forward_plus": [&"bloom", &"ssao", &"fog", &"dof", &"volumetric"],
	"gl_compatibility": [&"bloom", &"fog"],
}
## Ponto olhado pelas três câmeras (a do jogo olha 1,5 m acima dos pés do alvo; third_person_camera.gd) e vistas que a imitam: distância de 4 a 40 m e ângulo para baixo de 10 a 75 graus
## no jogo (a estratégica passa disso de propósito). `dof_far_m` é onde começa o desfoque do fundo; 0 = sem profundidade de campo nesta vista.
const AIM_POINT_M: Vector3 = Vector3(0.0, 1.5, 0.0)
const VIEWS: Array[Dictionary] = [
	{"name": "near", "distance": 5.0, "pitch": 12.0, "dof_far_m": 8.0},
	{"name": "isometric", "distance": 22.0, "pitch": 50.0, "dof_far_m": 0.0},
	{"name": "strategic", "distance": 60.0, "pitch": 70.0, "dof_far_m": 0.0},
]
## Sol: `sun_pitch` é a elevação acima do horizonte e `sun_yaw` o giro (180 = vem do fundo, contraluz para a câmera). `lamp`, `torch` e `accent` são energias (0 = apagado).
const PRESETS: Array[Dictionary] = [
	{
		"name": "day", "sun_color": Color("FFF2D9"), "sun_energy": 1.15, "sun_pitch": 55.0, "sun_yaw": -35.0, "sun_angle": 0.6, "shadow_blur": 1.5,
		"ambient_color": Color("A8B8D0"), "ambient_energy": 0.6, "sky_top": Color("5A8CC8"), "sky_horizon": Color("BCD2E6"), "sky_ground": Color("6A7A5A"),
		"fog_color": Color("C8D8E4"), "fog_density": 0.0025, "fog_scatter": 0.05, "volumetric_density": 0.004, "volumetric_color": Color("FFFFFF"),
		"tonemap": Environment.TONE_MAPPER_FILMIC, "exposure": 1.0, "white": 6.0, "brightness": 1.0, "contrast": 1.05, "saturation": 1.15,
		"glow": 0.4, "glow_threshold": 1.1, "bloom": 0.03, "ssao": 1.6, "dof": 0.1, "lamp": 0.0, "torch": 0.0, "accent": 0.0,
	},
	{
		"name": "golden", "sun_color": Color("FFB873"), "sun_energy": 1.7, "sun_pitch": 9.0, "sun_yaw": 165.0, "sun_angle": 1.5, "shadow_blur": 2.5,
		"ambient_color": Color("503030"), "ambient_energy": 0.9, "sky_top": Color("4A5A8A"), "sky_horizon": Color("FFB070"), "sky_ground": Color("302020"),
		"fog_color": Color("E8A870"), "fog_density": 0.006, "fog_scatter": 0.4, "volumetric_density": 0.03, "volumetric_color": Color("FFC890"),
		"tonemap": Environment.TONE_MAPPER_ACES, "exposure": 1.0, "white": 6.0, "brightness": 1.0, "contrast": 1.1, "saturation": 1.1,
		"glow": 0.8, "glow_threshold": 0.8, "bloom": 0.12, "ssao": 2.0, "dof": 0.18, "lamp": 1.2, "torch": 0.0, "accent": 0.0,
	},
	{
		"name": "dusk", "sun_color": Color("7080D0"), "sun_energy": 0.5, "sun_pitch": 3.0, "sun_yaw": 150.0, "sun_angle": 2.0, "shadow_blur": 3.0,
		"ambient_color": Color("505090"), "ambient_energy": 1.0, "sky_top": Color("2A2A66"), "sky_horizon": Color("705090"), "sky_ground": Color("201830"),
		"fog_color": Color("5A5A9A"), "fog_density": 0.008, "fog_scatter": 0.1, "volumetric_density": 0.04, "volumetric_color": Color("6068B8"),
		"tonemap": Environment.TONE_MAPPER_FILMIC, "exposure": 1.1, "white": 6.0, "brightness": 1.0, "contrast": 1.1, "saturation": 1.2,
		"glow": 1.0, "glow_threshold": 0.7, "bloom": 0.2, "ssao": 2.2, "dof": 0.25, "lamp": 1.4, "torch": 1.6, "accent": 2.5,
	},
]


## Que efeitos o método de renderização aceita (tabela SUPPORTED, [HIP]); método desconhecido não aceita nenhum.
static func supported_effects(method: String) -> Dictionary[StringName, bool]:
	var result: Dictionary[StringName, bool] = {}
	var allowed: Array = SUPPORTED.get(method, [])
	for effect: StringName in EFFECTS:
		result[effect] = allowed.has(effect)
	return result


## Aplica a predefinição ao sol, ao ambiente e ao céu. `active` diz que efeitos estão LIGADOS (aceitos pelo renderer e não desligados por tecla).
static func apply(preset: Dictionary, sun: DirectionalLight3D, environment: Environment, sky: ProceduralSkyMaterial, active: Dictionary[StringName, bool]) -> void:
	sun.light_color = preset["sun_color"]
	sun.light_energy = preset["sun_energy"]
	sun.light_angular_distance = preset["sun_angle"]
	sun.shadow_blur = preset["shadow_blur"]
	sun.rotation_degrees = Vector3(-float(preset["sun_pitch"]), float(preset["sun_yaw"]), 0.0)
	environment.ambient_light_color = preset["ambient_color"]
	environment.ambient_light_energy = preset["ambient_energy"]
	sky.sky_top_color = preset["sky_top"]
	sky.sky_horizon_color = preset["sky_horizon"]
	sky.ground_horizon_color = preset["sky_horizon"]
	sky.ground_bottom_color = preset["sky_ground"]
	environment.fog_enabled = active[&"fog"]
	environment.fog_light_color = preset["fog_color"]
	environment.fog_density = preset["fog_density"]
	environment.fog_sun_scatter = preset["fog_scatter"]
	environment.volumetric_fog_enabled = active[&"fog"] and active[&"volumetric"]
	environment.volumetric_fog_density = preset["volumetric_density"]
	environment.volumetric_fog_albedo = preset["volumetric_color"]
	environment.tonemap_mode = preset["tonemap"]
	environment.tonemap_exposure = preset["exposure"]
	environment.tonemap_white = preset["white"]
	environment.adjustment_brightness = preset["brightness"]
	environment.adjustment_contrast = preset["contrast"]
	environment.adjustment_saturation = preset["saturation"]
	environment.glow_enabled = active[&"bloom"]
	environment.glow_intensity = preset["glow"]
	environment.glow_hdr_threshold = preset["glow_threshold"]
	environment.glow_bloom = preset["bloom"]
	environment.ssao_enabled = active[&"ssao"]
	environment.ssao_intensity = preset["ssao"]


## Põe a câmera como a do jogo (distância e ângulo para baixo sobre o ponto de mira) e liga a profundidade de campo só nas vistas que a pedem.
static func apply_view(view: Dictionary, camera: Camera3D, attributes: CameraAttributesPractical, dof_amount: float, is_dof_active: bool) -> void:
	var pitch: float = deg_to_rad(float(view["pitch"]))
	var arm: Vector3 = Vector3(0.0, sin(pitch), cos(pitch)) * float(view["distance"])
	camera.transform = Transform3D(Basis.looking_at(-arm, Vector3.UP), AIM_POINT_M + arm)
	var far_m: float = view["dof_far_m"]
	attributes.dof_blur_far_enabled = is_dof_active and far_m > 0.0
	attributes.dof_blur_far_distance = far_m
	attributes.dof_blur_far_transition = far_m
	attributes.dof_blur_amount = dof_amount
