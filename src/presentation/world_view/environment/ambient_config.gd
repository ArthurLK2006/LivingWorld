class_name AmbientConfig
extends Resource
## Configuração visual do ambiente, em UM recurso editável (LW-041, decisão E5 de Arthur; AGENTS 4.4): sol, sombras,
## céu, luz ambiente e névoa do DIA, mais as cores da NOITE e os números da curva do dia (LW-042; DEC-059 é PROPOSTA).
## ART-4: o dia, a HORA DOURADA e o CREPÚSCULO são as predefinições aprovadas da cena demonstrativa (tools/visual/renderer_test), com o bloom; ART-4b: e com o tonemap e o ajuste de cor.
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
	"golden_hour_degrees": Vector2(-90.0, 90.0),
	"full_day_degrees": Vector2(-90.0, 90.0),
	"glow_intensity": Vector2(0.0, 8.0),
	"glow_hdr_threshold": Vector2(0.0, 8.0),
	"glow_bloom": Vector2(0.0, 1.0),
	"golden_sun_energy": Vector2(0.0, 8.0),
	"golden_sun_yaw_degrees": Vector2(-180.0, 180.0),
	"golden_ambient_energy": Vector2(0.0, 8.0),
	"golden_fog_density": Vector2(0.0, 1.0),
	"golden_glow_intensity": Vector2(0.0, 8.0),
	"golden_glow_hdr_threshold": Vector2(0.0, 8.0),
	"golden_glow_bloom": Vector2(0.0, 1.0),
	"dusk_sun_energy": Vector2(0.0, 8.0),
	"dusk_sun_yaw_degrees": Vector2(-180.0, 180.0),
	"dusk_ambient_energy": Vector2(0.0, 8.0),
	"dusk_fog_density": Vector2(0.0, 1.0),
	"dusk_glow_intensity": Vector2(0.0, 8.0),
	"dusk_glow_hdr_threshold": Vector2(0.0, 8.0),
	"dusk_glow_bloom": Vector2(0.0, 1.0),
	# Tonemap e ajuste de cor (ART-4b): as faixas do Inspector da Godot 4.7.2 (confirmadas por experimento), com o contraste alargado de 0,75 a 1,25 para 0,5 a 2 (a calibração pode precisar de folga).
	"tonemap_white": Vector2(1.0, 16.0),
	"exposure": Vector2(0.0, 4.0),
	"brightness": Vector2(0.0, 2.0),
	"contrast": Vector2(0.5, 2.0),
	"saturation": Vector2(0.0, 2.0),
	"golden_exposure": Vector2(0.0, 4.0),
	"golden_brightness": Vector2(0.0, 2.0),
	"golden_contrast": Vector2(0.5, 2.0),
	"golden_saturation": Vector2(0.0, 2.0),
	"dusk_exposure": Vector2(0.0, 4.0),
	"dusk_brightness": Vector2(0.0, 2.0),
	"dusk_contrast": Vector2(0.5, 2.0),
	"dusk_saturation": Vector2(0.0, 2.0),
}

@export_group("Sol")
## Os campos sem prefixo (sol, céu, ambiente, névoa e bloom) são a predefinição de DIA da cena demonstrativa; a hora dourada e o crepúsculo têm os seus grupos abaixo.
@export var sun_color: Color = Color8(255, 242, 217)
@export var sun_energy: float = 1.15
## Inclinação FIXA do sol, usada quando não há hora simulada; com o ciclo de dia e noite vale a curva (LW-042).
@export var sun_elevation_degrees: float = 55.0
## Giro em torno do eixo vertical, em graus.
@export var sun_yaw_degrees: float = -35.0
@export_group("Sombras")
@export var shadows_enabled: bool = true
## Uma só divisão: a sombra mais barata e sem faixas de transição.
@export var shadow_mode: DirectionalLight3D.ShadowMode = DirectionalLight3D.SHADOW_ORTHOGONAL
@export var shadow_max_distance_m: float = 150.0
@export var shadow_bias: float = 0.1
@export var shadow_normal_bias: float = 1.0
@export var shadow_blur: float = 1.0
@export_group("Céu")
@export var sky_top_color: Color = Color8(90, 140, 200)
@export var sky_horizon_color: Color = Color8(188, 210, 230)
@export var ground_horizon_color: Color = Color8(188, 210, 230)
@export var ground_bottom_color: Color = Color8(106, 122, 90)
@export_group("Luz ambiente")
@export var ambient_color: Color = Color8(168, 184, 208)
@export var ambient_energy: float = 0.60
@export_group("Névoa")
@export var fog_enabled: bool = true
@export var fog_color: Color = Color8(200, 216, 228)
## Densidade exponencial da névoa do DIA (por metro): é a escala da névoa do jogo (mundo de cerca de 1 km). As densidades da hora dourada e do crepúsculo mantêm a razão da cena demonstrativa (dia : dourada : crepúsculo = 0,0025 : 0,006 : 0,008 = 1 : 2,4 : 3,2); a noite usa esta.
@export var fog_density: float = 0.0004
@export var fog_sky_affect: float = 0.3
@export_group("Bloom")
## Liga o bloom (Environment.glow). No Compatibility só valem estes três números, que a cena demonstrativa já usa.
@export var glow_enabled: bool = true
@export var glow_intensity: float = 0.4
## Brilho (HDR) a partir do qual um pixel entra no bloom: baixo = mais coisas brilham.
@export var glow_hdr_threshold: float = 1.1
@export var glow_bloom: float = 0.03
@export_group("Tonemap e cor")
## UM modo de tonemap para o ciclo inteiro, FILMIC: o tonemap comprime os realces (sem ele o dia estoura e fica pastel) e o modo é uma escolha discreta, que não se mistura entre paletas (trocá-lo no meio do dia faria a imagem saltar).
## FILMIC é o modo do dia e do crepúsculo da cena demonstrativa e o mais suave; a hora dourada usa ACES lá, mas aqui ela fica com o mesmo modo e só o contraste e a saturação dela.
@export var tonemap_mode: Environment.ToneMapper = Environment.TONE_MAPPER_FILMIC
## Branco de referência do tonemap: a cena usa 6,0 nas três predefinições, então vale para o ciclo inteiro.
@export var tonemap_white: float = 6.0
## Exposição, brilho, contraste e saturação do DIA; a hora dourada e o crepúsculo têm os seus nos grupos deles e a noite herda os do crepúsculo. O padrão é o NEUTRO (1): um recurso novo não muda a imagem;
## os valores da cena demonstrativa (dia 1,0 / 1,0 / 1,05 / 1,15) estão no .tres e são [HIP] a calibrar olhando o jogo real. Brilho, contraste e saturação todos neutros desligam o ajuste de cor no Environment.
@export var exposure: float = 1.0
@export var brightness: float = 1.0
@export var contrast: float = 1.0
@export var saturation: float = 1.0
@export_group("Noite")
## Azul-escura e legível, NÃO preta: o ambiente mínimo da noite é a cor e a energia daqui.
@export var night_sky_top_color: Color = Color(0.02, 0.03, 0.10)
@export var night_sky_horizon_color: Color = Color(0.07, 0.10, 0.22)
@export var night_ground_horizon_color: Color = Color(0.07, 0.10, 0.22)
@export var night_ground_bottom_color: Color = Color(0.03, 0.05, 0.07)
@export var night_ambient_color: Color = Color(0.45, 0.55, 0.85)
@export var night_ambient_energy: float = 0.50
@export var night_fog_color: Color = Color(0.05, 0.07, 0.15)
@export_group("Hora dourada")
## Predefinição "golden" da cena demonstrativa; vale exatamente com o sol a `golden_hour_degrees`. O chão do horizonte tem a cor do horizonte, como na cena.
@export var golden_sun_color: Color = Color8(255, 184, 115)
@export var golden_sun_energy: float = 1.7
@export var golden_sun_yaw_degrees: float = 165.0
@export var golden_sky_top_color: Color = Color8(74, 90, 138)
@export var golden_sky_horizon_color: Color = Color8(255, 176, 112)
@export var golden_ground_bottom_color: Color = Color8(48, 32, 32)
@export var golden_ambient_color: Color = Color8(80, 48, 48)
@export var golden_ambient_energy: float = 0.9
@export var golden_fog_color: Color = Color8(232, 168, 112)
@export var golden_fog_density: float = 0.00096
@export var golden_glow_intensity: float = 0.8
@export var golden_glow_hdr_threshold: float = 0.8
@export var golden_glow_bloom: float = 0.12
## Exposição, brilho, contraste e saturação da hora dourada (padrão neutro; os da cena estão no .tres). O modo de tonemap é o do ciclo (`tonemap_mode`).
@export var golden_exposure: float = 1.0
@export var golden_brightness: float = 1.0
@export var golden_contrast: float = 1.0
@export var golden_saturation: float = 1.0
@export_group("Crepúsculo")
## Predefinição "dusk" da cena demonstrativa; vale exatamente com o sol a `daylight_to_degrees`. À noite o sol (cor, giro) e o bloom herdam esta (a energia do sol é 0).
@export var dusk_sun_color: Color = Color8(112, 128, 208)
@export var dusk_sun_energy: float = 0.5
@export var dusk_sun_yaw_degrees: float = 150.0
@export var dusk_sky_top_color: Color = Color8(42, 42, 102)
@export var dusk_sky_horizon_color: Color = Color8(112, 80, 144)
@export var dusk_ground_bottom_color: Color = Color8(32, 24, 48)
@export var dusk_ambient_color: Color = Color8(80, 80, 144)
@export var dusk_ambient_energy: float = 1.0
@export var dusk_fog_color: Color = Color8(90, 90, 154)
@export var dusk_fog_density: float = 0.00128
@export var dusk_glow_intensity: float = 1.0
@export var dusk_glow_hdr_threshold: float = 0.7
@export var dusk_glow_bloom: float = 0.2
## Exposição, brilho, contraste e saturação do crepúsculo (padrão neutro; os da cena estão no .tres); a noite herda estes, como o bloom.
@export var dusk_exposure: float = 1.0
@export var dusk_brightness: float = 1.0
@export var dusk_contrast: float = 1.0
@export var dusk_saturation: float = 1.0
@export_group("Curva do dia")
## Elevação do sol ao meio-dia (12:00); 06:00 e 18:00 ficam no horizonte e 00:00 em menos este valor.
@export var sun_max_elevation_degrees: float = 60.0
## A luz do dia vale 0 com o sol abaixo de `from` e 1 acima de `to` (smoothstep): a faixa do amanhecer e do anoitecer, onde a noite se mistura com o crepúsculo. `to` é também a elevação em que o
## CREPÚSCULO vale exatamente [HIP]: a da cena demonstrativa (3 graus, "muito baixo"); `from` não mudou (-2).
@export var daylight_from_degrees: float = -2.0
@export var daylight_to_degrees: float = 3.0
## [HIP] Elevação em que a HORA DOURADA vale exatamente: a da cena demonstrativa (9 graus; o guia fala em 8 a 15). Entre `daylight_to_degrees` e ela o ar vai do crepúsculo à hora dourada.
@export var golden_hour_degrees: float = 9.0
## [HIP] Do dia pleno para cima o ar é o do DIA (a cena demonstrativa usa 45 a 60 graus; o sol do jogo chega a `sun_max_elevation_degrees`). Entre `golden_hour_degrees` e ela o ar vai da hora dourada ao dia.
@export var full_day_degrees: float = 45.0


## Campos fora de faixa (vazia se estiver tudo certo).
func validate() -> Array[String]:
	var problems: Array[String] = []
	for property_name: String in RANGES:
		var value: float = get(property_name)
		var limits: Vector2 = RANGES[property_name]
		if is_nan(value) or value < limits.x or value > limits.y:
			problems.append("%s = %s fora da faixa %s a %s" % [property_name, str(value), str(limits.x), str(limits.y)])
	if tonemap_mode < Environment.TONE_MAPPER_LINEAR or tonemap_mode > Environment.TONE_MAPPER_AGX:
		problems.append("tonemap_mode = %d não é um tonemapper da Godot (%d a %d)" % [tonemap_mode, Environment.TONE_MAPPER_LINEAR, Environment.TONE_MAPPER_AGX])
	if daylight_from_degrees >= daylight_to_degrees:
		problems.append("daylight_from_degrees (%s) deve ser menor que daylight_to_degrees (%s)" % [str(daylight_from_degrees), str(daylight_to_degrees)])
	if daylight_to_degrees >= golden_hour_degrees or golden_hour_degrees >= full_day_degrees:
		problems.append("daylight_to_degrees (%s), golden_hour_degrees (%s) e full_day_degrees (%s) devem crescer nessa ordem" % [str(daylight_to_degrees), str(golden_hour_degrees), str(full_day_degrees)])
	return problems
