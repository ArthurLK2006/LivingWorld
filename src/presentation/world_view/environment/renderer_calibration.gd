class_name RendererCalibration
extends Resource
## Ajuste de luz POR RENDERER (M1, avaliação do renderer Mobile; docs/arte/COMPARACAO_RENDERERS.md): multiplicadores sobre o que o AmbientRig aplicaria sem ajuste (1 = neutro). Só valem quando o renderer em uso é o do campo `renderer`;
## com outro renderer (Compatibility, o aprovado) a luz sai EXATAMENTE como o AmbientConfig a define, então voltar ao Compatibility (uma linha do project.godot) não exige desfazer nada aqui.
## Medido no jogo real (praça A e ponto de nascimento, 12 h, 17h30 e 19 h, 3 câmeras, a mesma luz): sem ajuste o Mobile sai MAIS ESCURO que o Compatibility (brilho médio 0,64 contra 0,79 ao meio-dia), porque o sol e a luz ambiente
## do mesmo recurso rendem menos nele: sol x 2,6 e ambiente x 1,2 fecham o erro médio por pixel de 0,13 para 0,018 (dia), de 0,083 para 0,025 (hora dourada) e de 0,020 para 0,008 (noite). Os campos de exposição, saturação e bloom ficam neutros:
## foram testados de 0,5 a 3 vezes e não melhoraram o ajuste. Instância do Mobile: assets/environment/renderer_calibration_mobile.tres. Quem aplica: AmbientRig. Todos os valores são [HIP]: Arthur ajusta olhando a tela.

## Faixas aceitas (mínimo, máximo) dos multiplicadores; `validate()` confere.
const RANGES: Dictionary[String, Vector2] = {
	"sun_energy_scale": Vector2(0.0, 8.0),
	"ambient_energy_scale": Vector2(0.0, 8.0),
	"exposure_scale": Vector2(0.0, 4.0),
	"saturation_scale": Vector2(0.0, 2.0),
	"glow_intensity_scale": Vector2(0.0, 8.0),
	"glow_bloom_scale": Vector2(0.0, 8.0),
	"glow_threshold_scale": Vector2(0.0, 8.0),
}

## Nome do método de renderização a que o ajuste vale (`RenderingServer.get_current_rendering_method()`): "mobile", "forward_plus" ou "gl_compatibility".
@export var renderer: String = "mobile"
## Energia do sol (a que o AmbientRig aplicaria) x este valor.
@export var sun_energy_scale: float = 1.0
## Energia da luz ambiente x este valor.
@export var ambient_energy_scale: float = 1.0
## Exposição do tonemap x este valor.
@export var exposure_scale: float = 1.0
## Saturação do ajuste de cor x este valor.
@export var saturation_scale: float = 1.0
## Bloom: intensidade, força e limiar (brilho a partir do qual um pixel brilha) x estes valores.
@export var glow_intensity_scale: float = 1.0
@export var glow_bloom_scale: float = 1.0
@export var glow_threshold_scale: float = 1.0


## Campos fora de faixa (vazia se estiver tudo certo).
func validate() -> Array[String]:
	var problems: Array[String] = []
	if renderer.is_empty():
		problems.append("renderer vazio")
	for property_name: String in RANGES:
		var value: float = get(property_name)
		var limits: Vector2 = RANGES[property_name]
		if is_nan(value) or value < limits.x or value > limits.y:
			problems.append("%s = %s fora da faixa %s a %s" % [property_name, str(value), str(limits.x), str(limits.y)])
	return problems
