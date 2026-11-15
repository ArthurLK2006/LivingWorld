class_name CharacterPaintShaders
extends RefCounted
## Os sombreadores da paleta dos personagens (ART-12, entrega 4b; só apresentação). Dois, com o MESMO cabeçalho e a MESMA saída (textura pintada, normal map, rugosidade em G e metal em B do mapa ORM, como os materiais da Quaternius; face dupla sempre (`cull_disabled`, como todos os materiais da Quaternius) e cor de vértice só onde o material original usa), e só a função `paint` muda: o PANO gira o matiz e escala saturação e valor, ponderado por máscaras suaves (couro = marrom SATURADO, porque o cáqui do Peasant tem saturação ~0,35 e é pano; metal pelo canal B do ORM; as peças inteiras de couro, como botas e cintos, levam `leather_piece` = 1 e só mudam o valor do couro) para não sujar a textura; a PELE e o CABELO só multiplicam a cor (o multiplicador do `albedo_color`, já em linear). A cor da ficha entra por `instance uniform` (`pal` e `leather_val` no pano, `tint` na pele e no cabelo): o material é UM por classe e por conjunto de texturas, e cada malha leva os próprios valores. Os valores padrão dos `instance uniform` são os neutros (o visual original).

const CLOTH: String = CharacterPalettes.CLOTH
const HEAD: String = """
shader_type spatial;
render_mode cull_disabled;
uniform sampler2D tex_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D tex_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D tex_orm : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float rough_factor = 1.0;
uniform float metal_factor = 0.0;
uniform float use_vertex_color = 0.0;
"""
const CLOTH_PAINT: String = """
instance uniform vec4 pal = vec4(0.0, 1.0, 1.0, 0.0);
instance uniform float leather_val = 1.0;
instance uniform float leather_piece = 0.0;
const float GAMMA = 2.2;
const float EPSILON = 0.0001;
const vec2 BROWN_SAT = vec2(0.45, 0.58);
const vec2 BROWN_HUE_FADE = vec2(0.045, 0.085);
const float BROWN_HUE = 0.075;
const vec2 BROWN_VAL = vec2(0.2, 0.35);
const vec2 SAT_ADD_VAL = vec2(0.25, 0.5);
vec3 rgb2hsv(vec3 c) {
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + EPSILON)), d / (q.x + EPSILON), q.x);
}
vec3 hsv2rgb(vec3 c) {
	vec3 p = abs(fract(c.xxx + vec3(0.0, 2.0 / 3.0, 1.0 / 3.0)) * 6.0 - 3.0);
	return c.z * mix(vec3(1.0), clamp(p - 1.0, 0.0, 1.0), c.y);
}
vec3 paint(vec3 lin, vec3 orm) {
	vec3 hsv = rgb2hsv(pow(lin, vec3(1.0 / GAMMA)));
	float brown = smoothstep(BROWN_SAT.x, BROWN_SAT.y, hsv.y) * (1.0 - smoothstep(BROWN_HUE_FADE.x, BROWN_HUE_FADE.y, abs(hsv.x - BROWN_HUE))) * smoothstep(BROWN_VAL.x, BROWN_VAL.y, hsv.z);
	float leather = max(brown, leather_piece);
	float cloth = (1.0 - leather) * (1.0 - orm.b);
	float h = fract(hsv.x + pal.x * cloth);
	float s = clamp(hsv.y * mix(1.0, pal.y, cloth) + pal.w * cloth * smoothstep(SAT_ADD_VAL.x, SAT_ADD_VAL.y, hsv.z), 0.0, 1.0);
	float v = clamp(hsv.z * mix(1.0, pal.z, cloth) * mix(1.0, leather_val, leather), 0.0, 1.0);
	return pow(hsv2rgb(vec3(h, s, v)), vec3(GAMMA));
}
"""
const TINT_PAINT: String = """
instance uniform vec3 tint = vec3(1.0);
vec3 paint(vec3 lin, vec3 orm) {
	return lin * tint;
}
"""
const TAIL: String = """
void fragment() {
	vec3 orm = texture(tex_orm, UV).rgb;
	vec3 base = texture(tex_albedo, UV).rgb * mix(vec3(1.0), COLOR.rgb, use_vertex_color);
	ALBEDO = paint(base, orm);
	NORMAL_MAP = texture(tex_normal, UV).rgb;
	ROUGHNESS = rough_factor * orm.g;
	METALLIC = metal_factor * orm.b;
}
"""


## O sombreador da classe (`CharacterPalettes.CLOTH`: o do pano; qualquer outra: o de multiplicar a cor).
static func build(kind: String) -> Shader:
	var shader: Shader = Shader.new()
	shader.code = HEAD + (CLOTH_PAINT if kind == CLOTH else TINT_PAINT) + TAIL
	return shader
