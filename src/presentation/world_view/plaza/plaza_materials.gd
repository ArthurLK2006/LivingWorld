class_name PlazaMaterials
extends RefCounted
## Materiais compartilhados da praça (guia visual, seção 5: poucos materiais por cena) e o shader de vento da grama e das flores. Sem textura: a cor vem do vértice (sólido e pano) ou dos uniformes do shader.

## Vento simples: a ponta se move mais que a base; cor da base à ponta por uniformes `source_color` (o motor cuida do espaço de cor em cada renderer) e o alfa do vértice marca a cabeça da flor.
const WIND_SHADER: String = """
shader_type spatial;
render_mode cull_disabled;
uniform vec3 low_color : source_color;
uniform vec3 high_color : source_color;
uniform vec3 accent_color : source_color;
uniform float sway_amount = 0.35;
uniform float sway_speed = 1.7;
uniform float sway_scale = 0.4;
varying vec3 tint;
void vertex() {
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float phase = TIME * sway_speed + (world.x + world.z * 0.7) * sway_scale;
	VERTEX.x += sin(phase) * sway_amount * VERTEX.y;
	VERTEX.z += cos(phase * 0.8) * sway_amount * 0.5 * VERTEX.y;
	NORMAL = vec3(0.0, 1.0, 0.0);
	tint = mix(mix(low_color, high_color, clamp(VERTEX.y / 0.4, 0.0, 1.0)), accent_color, COLOR.a);
}
void fragment() {
	ALBEDO = tint;
	ROUGHNESS = 0.95;
}
"""


## Cria os materiais por nome, na ordem de sempre: sólido e pano (cor por vértice), os quatro emissivos (lampião, chama e os dois acentos), a grama e uma flor por cor. O Shader de vento é um só, compartilhado pelos quatro materiais de vento.
static func create() -> Dictionary[StringName, Material]:
	var wind_shader: Shader = Shader.new()
	wind_shader.code = WIND_SHADER
	var materials: Dictionary[StringName, Material] = {}
	materials[&"solid"] = _standard(Color.WHITE, true, BaseMaterial3D.CULL_BACK)
	materials[&"cloth"] = _standard(Color.WHITE, true, BaseMaterial3D.CULL_DISABLED)
	materials[&"lantern"] = _standard(PlazaData.LAMP_COLOR, false, BaseMaterial3D.CULL_DISABLED)
	materials[&"flame"] = _standard(PlazaData.TORCH_COLOR, false, BaseMaterial3D.CULL_DISABLED)
	materials[&"accent_warm"] = _standard(PlazaData.TORCH_COLOR, false, BaseMaterial3D.CULL_DISABLED)
	materials[&"accent_cyan"] = _standard(PlazaData.CYAN, false, BaseMaterial3D.CULL_DISABLED)
	for key: StringName in [&"lantern", &"flame", &"accent_warm", &"accent_cyan"]:
		var emissive: StandardMaterial3D = materials[key] as StandardMaterial3D
		emissive.emission_enabled = true
		emissive.emission = emissive.albedo_color
	materials[&"grass"] = _wind(wind_shader, PlazaData.GRASS_LOW, PlazaData.GRASS_HIGH, Color.BLACK)
	for index: int in PlazaData.FLOWER_COLORS.size():
		materials[StringName("flower%d" % index)] = _wind(wind_shader, PlazaData.FLOWER_STEM, PlazaData.FLOWER_STEM, PlazaData.FLOWER_COLORS[index])
	return materials


static func _standard(albedo: Color, uses_vertex_color: bool, cull: BaseMaterial3D.CullMode) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = albedo
	material.vertex_color_use_as_albedo = uses_vertex_color
	material.vertex_color_is_srgb = true
	material.roughness = PlazaData.SURFACE_ROUGHNESS
	material.rim_enabled = true
	material.rim = PlazaData.RIM_STRENGTH
	material.cull_mode = cull
	return material


static func _wind(shader: Shader, low: Color, high: Color, accent: Color) -> ShaderMaterial:
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter(&"low_color", low)
	material.set_shader_parameter(&"high_color", high)
	material.set_shader_parameter(&"accent_color", accent)
	return material
