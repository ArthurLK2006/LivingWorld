class_name CharacterPainter
extends RefCounted
## Pinta um personagem montado com a paleta da ficha (ART-12, entrega 4b; só apresentação): o pano, a pele e o cabelo (a barba e a sobrancelha seguem o cabelo). O material de cada superfície é UM `ShaderMaterial` compartilhado, derivado do material ORIGINAL da peça (mesma textura pintada, mesmo normal map, mesma rugosidade e metal) e guardado por classe e por conjunto de texturas; a cor vem dos `instance uniform` de cada malha. Então pintar mais um personagem não cria material nenhum, e pintar de novo (um NPC novo no mesmo visual) só troca dois ou três valores por malha. A classe vem do NOME do material original (convenção da Quaternius, tabela `MATERIAL_CLASSES`); os olhos e todo material desconhecido ficam como estão. A paleta fica guardada no montador e vale também para a peça trocada depois (`CharacterAssembler.swap_part`), até o próximo `clear()` ou montagem. O pintor precisa viver enquanto o montador for usado (o montador só guarda uma chamada para ele). Contrato: docs/modules/presentation.md.
## Paleta neutra (o `sand` do pano, `base` e `natural`) deixa os valores neutros e o visual igual ao original. Os valores seguem as tabelas de `CharacterPalettes`: graus viram voltas e milésimos viram decimais aqui, e o multiplicador de pele e cabelo vai para o espaço linear (como o `albedo_color` do material faria; o `instance uniform` não converte um vetor). Dois limites conhecidos da base provisória da Quaternius, isolados aqui (ajuste pedido por Arthur em 15/11/2026): o giro de matiz da tabela do pano foi calibrado no Peasant (cáqui) e NÃO vale no Ranger (base verde, onde o mesmo giro dá roxo e índigo), que só muda saturação e valor (`HUE_LOCKED`); e a pele multiplica a textura da Quaternius, que é a mais escura do pacote, então a tabela de pele só escurece e não há tons claros (`base` é o original).

const CLOTH: String = CharacterPalettes.CLOTH
const SKIN: String = CharacterPalettes.SKIN
const HAIR: String = CharacterPalettes.HAIR
## Os `instance uniform` dos sombreadores (`CharacterPaintShaders`).
const PAL: StringName = &"pal"
const LEATHER_VALUE: StringName = &"leather_val"
const TINT: StringName = &"tint"
const LEATHER_PIECE: StringName = &"leather_piece"
## Peças inteiras de couro e metal (uma destas palavras no nome da malha): o pano não muda de cor nelas. Medido na ART-12 4b: as botas do Peasant são marrom ESCURO, igual ao colete e à calça, e nenhuma máscara por cor as separa.
const LEATHER_PIECES: PackedStringArray = ["Feet", "Belt", "Bracer", "Pauldron"]
## Roupas (prefixo do nome do material original) onde o giro de matiz da tabela não vale: o Ranger, de base verde, só muda saturação e valor. Medido na ART-12 4b: slate dava roxo e petrol, índigo.
const HUE_LOCKED: PackedStringArray = ["MI_Ranger"]
const DEGREES_PER_TURN: float = 360.0
const PERMILLE: float = 1000.0
## Prefixo do nome do material original -> classe.
const MATERIAL_CLASSES: Dictionary[String, String] = {
	"MI_Peasant": CLOTH,
	"MI_Ranger": CLOTH,
	"MI_Superhero": SKIN,
	"MI_Regular": SKIN,
	"MI_Hair": HAIR,
}

var _palettes: CharacterPalettes
var _shaders: Dictionary[String, Shader] = {}
var _shared: Dictionary[String, ShaderMaterial] = {}


func _init(palettes: CharacterPalettes) -> void:
	_palettes = palettes


## Pinta o personagem montado e guarda a paleta no montador. Falso, sem mudar nada, se o montador está vazio, a ficha não tem peças ou as paletas não estão carregadas ou não têm o índice da ficha.
func apply(assembler: CharacterAssembler, appearance: CharacterAppearance) -> bool:
	if assembler == null or appearance == null or not appearance.is_resolved():
		return false
	var meshes: Array[MeshInstance3D] = CharacterSceneLoader.meshes_of(assembler)
	var look: Dictionary[String, Dictionary] = _look(appearance)
	if meshes.is_empty() or look.is_empty():
		return false
	assembler.set_paint(_paint.bind(look))
	_paint(meshes, look)
	return true


## Os valores de cada classe prontos para o sombreador (nome do `instance uniform` -> valor); vazio se as paletas não servem à ficha.
func _look(appearance: CharacterAppearance) -> Dictionary[String, Dictionary]:
	var look: Dictionary[String, Dictionary] = {}
	if _palettes == null or not _palettes.is_ready():
		return look
	var cloth: Dictionary = _palettes.entry(CLOTH, appearance.cloth_palette_index)
	var skin: Dictionary = _palettes.entry(SKIN, appearance.skin_index)
	var hair: Dictionary = _palettes.entry(HAIR, appearance.hair_tone_index)
	if cloth.is_empty() or skin.is_empty() or hair.is_empty():
		return look
	var shift: Vector4 = Vector4(float(cloth["hue_deg"]) / DEGREES_PER_TURN, float(cloth["sat_permille"]) / PERMILLE, float(cloth["val_permille"]) / PERMILLE, float(cloth["sat_add_permille"]) / PERMILLE)
	look[CLOTH] = {PAL: shift, LEATHER_VALUE: float(cloth["leather_val_permille"]) / PERMILLE}
	look[SKIN] = {TINT: _tint(skin)}
	look[HAIR] = {TINT: _tint(hair)}
	return look


static func _tint(row: Dictionary) -> Vector3:
	var factor: Color = Color(float(row["r_permille"]) / PERMILLE, float(row["g_permille"]) / PERMILLE, float(row["b_permille"]) / PERMILLE).srgb_to_linear()
	return Vector3(factor.r, factor.g, factor.b)


## Põe o material compartilhado e os valores da classe em cada superfície conhecida das malhas. O material da malha (`mesh.mesh`) é o original e fica intacto: o que muda é só a cobertura da instância.
func _paint(meshes: Array[MeshInstance3D], look: Dictionary[String, Dictionary]) -> void:
	for mesh: MeshInstance3D in meshes:
		if mesh.mesh == null:
			continue
		for surface: int in mesh.mesh.get_surface_count():
			var original: BaseMaterial3D = mesh.mesh.surface_get_material(surface) as BaseMaterial3D
			var kind: String = _class_of(original)
			if kind.is_empty():
				continue
			mesh.set_surface_override_material(surface, _shared_material(kind, original))
			var values: Dictionary = look[kind]
			var locked: bool = kind == CLOTH and _is_hue_locked(original)
			for uniform_name: StringName in values:
				var value: Variant = values[uniform_name]
				if locked and uniform_name == PAL:
					var shift: Vector4 = value
					value = Vector4(0.0, shift.y, shift.z, shift.w)
				mesh.set_instance_shader_parameter(uniform_name, value)
			if kind == CLOTH:
				mesh.set_instance_shader_parameter(LEATHER_PIECE, 1.0 if _is_leather_piece(mesh) else 0.0)


static func _is_leather_piece(mesh: MeshInstance3D) -> bool:
	for word: String in LEATHER_PIECES:
		if String(mesh.name).contains(word):
			return true
	return false


static func _is_hue_locked(material: BaseMaterial3D) -> bool:
	for prefix: String in HUE_LOCKED:
		if material.resource_name.begins_with(prefix):
			return true
	return false


static func _class_of(material: BaseMaterial3D) -> String:
	if material == null:
		return ""
	for prefix: String in MATERIAL_CLASSES:
		if material.resource_name.begins_with(prefix):
			return MATERIAL_CLASSES[prefix]
	return ""


## O material compartilhado da classe para as texturas e fatores do original (um por combinação, não um por personagem nem por peça).
func _shared_material(kind: String, original: BaseMaterial3D) -> ShaderMaterial:
	var key: String = "%s|%d|%d|%d|%s|%s|%s" % [kind, _id_of(original.albedo_texture), _id_of(original.normal_texture), _id_of(original.roughness_texture), original.roughness, original.metallic, original.vertex_color_use_as_albedo]
	if not _shared.has(key):
		_shared[key] = _derive(kind, original)
	return _shared[key]


static func _id_of(texture: Texture2D) -> int:
	return texture.get_instance_id() if texture != null else 0


func _derive(kind: String, original: BaseMaterial3D) -> ShaderMaterial:
	if not _shaders.has(kind):
		_shaders[kind] = CharacterPaintShaders.build(kind)
	var material: ShaderMaterial = ShaderMaterial.new()
	material.resource_name = original.resource_name + "_" + kind
	material.shader = _shaders[kind]
	material.set_shader_parameter(&"tex_albedo", original.albedo_texture)
	material.set_shader_parameter(&"tex_normal", original.normal_texture if original.normal_enabled else null)
	material.set_shader_parameter(&"tex_orm", original.roughness_texture)
	material.set_shader_parameter(&"rough_factor", original.roughness)
	material.set_shader_parameter(&"metal_factor", original.metallic)
	material.set_shader_parameter(&"use_vertex_color", 1.0 if original.vertex_color_use_as_albedo else 0.0)
	return material
