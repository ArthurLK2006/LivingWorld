class_name AmbientConfig
extends Resource
## Configuração visual do ambiente do dia, em UM recurso editável (LW-041, decisão E5 de Arthur; AGENTS 4.4):
## sol, sombras, céu, luz ambiente e névoa. TODOS os valores são [HIP]: Arthur ajusta olhando a tela.
## Instância editável: assets/environment/ambient_default.tres. Quem aplica: AmbientRig. Contrato: docs/modules/presentation.md.

## Faixas aceitas (mínimo, máximo) dos campos numéricos; `validate()` confere.
const RANGES: Dictionary[String, Vector2] = {
	"sun_energy": Vector2(0.0, 8.0),
	"sun_elevation_degrees": Vector2(0.0, 90.0),
	"sun_yaw_degrees": Vector2(-180.0, 180.0),
	"shadow_max_distance_m": Vector2(1.0, 1000.0),
	"shadow_bias": Vector2(0.0, 10.0),
	"shadow_normal_bias": Vector2(0.0, 10.0),
	"shadow_blur": Vector2(0.0, 8.0),
	"ambient_energy": Vector2(0.0, 8.0),
	"fog_density": Vector2(0.0, 1.0),
	"fog_sky_affect": Vector2(0.0, 1.0),
}

@export_group("Sol")
@export var sun_color: Color = Color(1.0, 0.95, 0.85)
@export var sun_energy: float = 0.42
## Inclinação: graus acima do horizonte (a luz roda no eixo x em -inclinação).
@export var sun_elevation_degrees: float = 55.0
## Giro em torno do eixo vertical, em graus.
@export var sun_yaw_degrees: float = -30.0
@export_group("Sombras")
@export var shadows_enabled: bool = true
## Uma só divisão: a sombra mais barata e sem faixas de transição.
@export var shadow_mode: DirectionalLight3D.ShadowMode = DirectionalLight3D.SHADOW_ORTHOGONAL
@export var shadow_max_distance_m: float = 150.0
@export var shadow_bias: float = 0.1
@export var shadow_normal_bias: float = 1.0
@export var shadow_blur: float = 1.0
@export_group("Céu")
@export var sky_top_color: Color = Color(0.30, 0.50, 0.80)
@export var sky_horizon_color: Color = Color(0.72, 0.82, 0.90)
@export var ground_horizon_color: Color = Color(0.72, 0.82, 0.90)
@export var ground_bottom_color: Color = Color(0.28, 0.36, 0.26)
@export_group("Luz ambiente")
@export var ambient_color: Color = Color(0.72, 0.76, 0.80)
@export var ambient_energy: float = 0.30
@export_group("Névoa")
@export var fog_enabled: bool = true
@export var fog_color: Color = Color(0.72, 0.82, 0.90)
## Densidade exponencial da névoa (por metro).
@export var fog_density: float = 0.0004
@export var fog_sky_affect: float = 0.3


## Campos fora de faixa (vazia se estiver tudo certo).
func validate() -> Array[String]:
	var problems: Array[String] = []
	for property_name: String in RANGES:
		var value: float = get(property_name)
		var limits: Vector2 = RANGES[property_name]
		if is_nan(value) or value < limits.x or value > limits.y:
			problems.append("%s = %s fora da faixa %s a %s" % [property_name, str(value), str(limits.x), str(limits.y)])
	return problems
