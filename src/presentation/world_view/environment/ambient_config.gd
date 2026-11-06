class_name AmbientConfig
extends Resource
## Configuração visual do ambiente, em UM recurso editável (LW-041, decisão E5 de Arthur; AGENTS 4.4): sol, sombras,
## céu, luz ambiente e névoa do DIA, mais as cores da NOITE e os números da curva do dia (LW-042; DEC-059 é PROPOSTA).
## TODOS os valores são [HIP]: Arthur ajusta olhando a tela.
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
	"night_ambient_energy": Vector2(0.0, 8.0),
	"sun_max_elevation_degrees": Vector2(1.0, 90.0),
	"daylight_from_degrees": Vector2(-90.0, 90.0),
	"daylight_to_degrees": Vector2(-90.0, 90.0),
}

@export_group("Sol")
@export var sun_color: Color = Color(1.0, 0.95, 0.85)
@export var sun_energy: float = 0.42
## Inclinação FIXA do sol, usada quando não há hora simulada; com o ciclo de dia e noite vale a curva (LW-042).
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
@export_group("Noite")
## Azul-escura e legível, NÃO preta: o ambiente mínimo da noite é a cor e a energia daqui.
@export var night_sky_top_color: Color = Color(0.02, 0.03, 0.10)
@export var night_sky_horizon_color: Color = Color(0.07, 0.10, 0.22)
@export var night_ground_horizon_color: Color = Color(0.07, 0.10, 0.22)
@export var night_ground_bottom_color: Color = Color(0.03, 0.05, 0.07)
@export var night_ambient_color: Color = Color(0.45, 0.55, 0.85)
@export var night_ambient_energy: float = 0.50
@export var night_fog_color: Color = Color(0.05, 0.07, 0.15)
@export_group("Curva do dia")
## Elevação do sol ao meio-dia (12:00); 06:00 e 18:00 ficam no horizonte e 00:00 em menos este valor.
@export var sun_max_elevation_degrees: float = 60.0
## O dia vale 0 com o sol abaixo de `from` e 1 acima de `to` (smoothstep): faixa do amanhecer e do anoitecer.
@export var daylight_from_degrees: float = -2.0
@export var daylight_to_degrees: float = 12.0


## Campos fora de faixa (vazia se estiver tudo certo).
func validate() -> Array[String]:
	var problems: Array[String] = []
	for property_name: String in RANGES:
		var value: float = get(property_name)
		var limits: Vector2 = RANGES[property_name]
		if is_nan(value) or value < limits.x or value > limits.y:
			problems.append("%s = %s fora da faixa %s a %s" % [property_name, str(value), str(limits.x), str(limits.y)])
	if daylight_from_degrees >= daylight_to_degrees:
		problems.append("daylight_from_degrees (%s) deve ser menor que daylight_to_degrees (%s)" % [str(daylight_from_degrees), str(daylight_to_degrees)])
	return problems
