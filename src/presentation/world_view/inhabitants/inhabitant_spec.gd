class_name InhabitantSpec
extends RefCounted
## Ficha de UM habitante (ART-9, 9d e 9e, protótipo isolado, só apresentação): dado puro, escolhido por hash de inteiros a partir de (id, papel), sem sorteio da engine, então o mesmo par dá sempre a mesma ficha e a mesma malha. A MATRIZ de arquétipos (papel x subarquétipo: faixas de morfologia, roupas, equipamento e postura) é um dado legível em InhabitantArchetypes; a morfologia (altura, constituição, anatomia, idade, postura) sai de InhabitantMorph; aqui ficam a ficha, as paletas e o vestir. Cada campo tem o seu canal de hash.

enum Garment { TUNIC, LONG_COAT, TABARD, DRESS, SHORT_TUNIC }
enum HeadCover { NONE, HOOD, CAP, WIDE_HAT, OPEN_HELM, HOOD_CAP, SCARF, STRAW_HAT, BERET, WOOL_CAP }
enum Mood { GENTLE, CURIOUS, TIRED, SEVERE }
enum Beard { NONE, SHORT, FULL, MOUSTACHE }
enum Fabric { PLAIN, STRIPED, PATCHED }
enum Apron { NONE, SHORT, LONG }
enum Crest { NONE, RIDGE, PLUME }
enum Age { YOUNG, ADULT, OLD }
enum Build { LEAN, THIN, AVERAGE, STOCKY, STRONG, HEAVY }
enum HeadShape { ROUND, LONG, SQUARE, SMALL_CHIN }
enum Posture { UPRIGHT, STOOPED, LEANING }
enum Sleeve { LONG, SHORT, ROLLED, PUFFED }
enum Hair { BALD, CROP, SHORT, LONG, BUN, MESSY }
enum Waist { LEATHER, SASH, ROPE }
enum Wrap { NONE, SHAWL, SCARF }
enum Channel { HEIGHT, WIDTH, HEAD, SKIN, HAIR, OUTFIT, TOP, BOTTOM, TRIM, BOOTS, COVER, EXPRESSION, BEARD, FABRIC, APRON, CREST, SHIELD, BELLY, DROOP, LEAN, ALT, COLLAR, BUNDLE, BUILD, AGE, SHAPE, POSTURE, STOOP, SHOULDER, CHEST, HIP, NECK, LIMBS, LEGS, GIRTH, SLEEVE, HAIRSTYLE, WRAP, WAIST, FEATHER }

const VILLAGER: StringName = &"villager"
const MERCHANT: StringName = &"merchant"
const GUARD: StringName = &"guard"
const ROLES: Array[StringName] = [VILLAGER, MERCHANT, GUARD]
## Cada tom varia um pouco por habitante (fração de claro ou de escuro), com um canal de hash próprio (canal da cor + deslocamento).
const TINT_RANGE: float = 0.08
const TINT_CHANNEL_SHIFT: int = 32
## Chance de pena no chapéu largo e o cabelo branco do idoso (mistura com o branco).
const FEATHER_CHANCE: float = 0.7
const WHITE_HAIR: Color = Color("E4E0D8")
const OLD_WHITE: float = 0.85
const SKIN_TONES: Array[Color] = [Color("EDBB9A"), Color("E5A783"), Color("D79B72"), Color("C48862"), Color("B27A52"), Color("98653F")]
const HAIR_TONES: Array[Color] = [Color("3E2B20"), Color("5C3B23"), Color("8A5A2B"), Color("C79A4A"), Color("A8A29A"), Color("7A3B20")]
const BOOT_TONES: Array[Color] = [Color("5A3C2B"), Color("4A3326"), Color("6A4A34")]
## Paletas por papel: peça de cima, de baixo, debrum (cinto), cobertura da cabeça, tom de apoio (listra, remendo, faixa, avental) e gola. Aldeão = tons terrosos; comerciante = cores mais ricas; guarda = tabardo azul-marinho com ouro e aço (a farda que o distingue de longe).
const PALETTES: Dictionary[StringName, Array] = {
	VILLAGER: [
		[Color("A8703C"), Color("8E5E34"), Color("B98B45"), Color("7C8445"), Color("9B5B3A"), Color("6F8466")],
		[Color("6E8A3E"), Color("5C6F3A"), Color("7A5A3A"), Color("4F5E6A")], [Color("6A4630"), Color("54382A"), Color("7A5535")],
		[Color("8B6446"), Color("6A8E4A"), Color("7A5A44"), Color("8A7A3C"), Color("6B9A3F")],
		[Color("C9A25A"), Color("8C6A4A"), Color("7A8F5A"), Color("B8603C")], [Color("E8DFC8"), Color("D8CDB0"), Color("EDE4CC")],
	],
	MERCHANT: [
		[Color("A93A3F"), Color("2F7F86"), Color("B8692F"), Color("7B3F80"), Color("C8962E"), Color("3F7D4A")],
		[Color("5A4632"), Color("3E3A52"), Color("5E5A3A")], [Color("D4A93A"), Color("E8DCC0"), Color("A87A3A")],
		[Color("7A4A2E"), Color("A23E3E"), Color("335D8F"), Color("5A7A3A"), Color("D2B060")],
		[Color("E8D8A8"), Color("F0E0C0"), Color("D8B050")], [Color("F2EBD8"), Color("E6D8B8"), Color("F6F0DE")],
	],
	GUARD: [
		[Color("2F4E8A"), Color("345F9C"), Color("2B4A7E")], [Color("4A5568"), Color("55606E"), Color("3F4856")],
		[Color("D4AF3A"), Color("C8A030"), Color("E0C050")], [Color("B6BEC8"), Color("A9B2BC"), Color("C4CCD6")],
		[Color("D4AF3A"), Color("C8A030")], [Color("C8CCD4"), Color("B8BEC8")],
	],
}

var id: int = 0
var role: StringName = VILLAGER
var archetype: int = 0
var archetype_name: String = ""
var height_m: float = 0.0
var width_m: float = 0.0
var head_scale: float = 1.0
var skin: Color = Color.WHITE
var hair: Color = Color.WHITE
var top: Color = Color.WHITE
var bottom: Color = Color.WHITE
var trim: Color = Color.WHITE
var boots: Color = Color.WHITE
var cover_color: Color = Color.WHITE
var alt: Color = Color.WHITE
var collar: Color = Color.WHITE
var garment: int = Garment.TUNIC
var head_cover: int = HeadCover.NONE
var accessories: Array[StringName] = []
var expression: int = Mood.GENTLE
var beard: int = Beard.NONE
var fabric: int = Fabric.PLAIN
var apron: int = Apron.NONE
var crest: int = Crest.NONE
var has_pauldrons: bool = false
var has_shield: bool = false
var halberd: bool = false
var has_feather: bool = false
var helm_scale: float = 1.0
var pauldron_scale: float = 1.0
var plume_scale: float = 1.0
var bundle_size: float = 1.0
var age: int = Age.ADULT
var build: int = Build.AVERAGE
var girth: float = 1.0
var shoulder: float = 1.0
var chest: float = 1.0
var belly: float = 1.0
var hip: float = 1.0
var neck: float = 1.0
var limbs: float = 1.0
var legs: float = 1.0
var head_shape: int = HeadShape.ROUND
var posture: int = Posture.UPRIGHT
var stoop: float = 0.0
var droop: float = 0.0
var lean: float = 0.0
var sleeve: int = Sleeve.LONG
var hair_style: int = Hair.SHORT
var waist: int = Waist.LEATHER
var neck_wrap: int = Wrap.NONE


## A ficha do habitante `inhabitant_id` no papel `role_name` (papel desconhecido vira aldeão). O mesmo par dá sempre a mesma ficha.
static func for_inhabitant(inhabitant_id: int, role_name: StringName) -> InhabitantSpec:
	var kind: StringName = role_name if ROLES.has(role_name) else VILLAGER
	var key: int = inhabitant_id * ROLES.size() + ROLES.find(kind)
	var spec: InhabitantSpec = InhabitantSpec.new()
	spec.id = inhabitant_id
	spec.role = kind
	spec.archetype = InhabitantArchetypes.pick(kind, inhabitant_id)
	var entry: Dictionary = InhabitantArchetypes.entry(kind, spec.archetype)
	spec.archetype_name = entry["name"]
	var outfits: Array = entry["outfits"]
	var outfit: Array = outfits[_index(outfits.size(), key, Channel.OUTFIT)]
	spec.garment = outfit[0]
	spec.head_cover = outfit[1]
	spec.accessories.assign(outfit.slice(2))
	InhabitantMorph.apply(spec, entry, key)
	var palette: Array = PALETTES[kind]
	spec.skin = _tone(SKIN_TONES, key, Channel.SKIN)
	spec.hair = _tone(HAIR_TONES, key, Channel.HAIR)
	if spec.age == Age.OLD:
		spec.hair = spec.hair.lerp(WHITE_HAIR, OLD_WHITE)
	spec.boots = _tone(BOOT_TONES, key, Channel.BOOTS)
	spec.top = _tone(palette[0], key, Channel.TOP)
	spec.bottom = _tone(palette[1], key, Channel.BOTTOM)
	spec.trim = _tone(palette[2], key, Channel.TRIM)
	spec.cover_color = _tone(palette[3], key, Channel.COVER)
	spec.alt = _tone(palette[4], key, Channel.ALT)
	spec.collar = _tone(palette[5], key, Channel.COLLAR)
	_dress(spec, entry, kind, key)
	return spec


func has_accessory(kind: StringName) -> bool:
	return accessories.has(kind)


## Os campos de vestir (cada um com o seu canal): rosto, barba, cabelo, mangas, tecido, avental, cinto, agasalho, pena, equipamento do guarda e trouxa do mascate.
static func _dress(spec: InhabitantSpec, entry: Dictionary, kind: StringName, key: int) -> void:
	spec.expression = _choice(entry["mood"], key, Channel.EXPRESSION)
	spec.beard = _choice(entry["beard"], key, Channel.BEARD)
	spec.fabric = _choice(entry["fabric"], key, Channel.FABRIC)
	spec.sleeve = _choice(entry["sleeves"], key, Channel.SLEEVE)
	spec.hair_style = _choice(entry["hair"], key, Channel.HAIRSTYLE)
	spec.waist = _choice(entry["waist"], key, Channel.WAIST)
	spec.neck_wrap = _choice(entry["wrap"], key, Channel.WRAP)
	if spec.has_accessory(&"apron"):
		spec.apron = Apron.LONG
	elif kind == VILLAGER:
		spec.apron = _choice(entry["apron"], key, Channel.APRON)
	spec.has_feather = spec.head_cover == HeadCover.WIDE_HAT and PlazaMeshKit.unit(key, Channel.FEATHER) < FEATHER_CHANCE
	spec.bundle_size = entry.get("load", 1.0)
	if kind == GUARD:
		spec.has_pauldrons = true
		spec.crest = _choice(entry["crest"], key, Channel.CREST)
		spec.has_shield = spec.has_accessory(&"spear") and PlazaMeshKit.unit(key, Channel.SHIELD) < float(entry["shield"])
		spec.halberd = entry["halberd"]
		spec.helm_scale = entry["helm"]
		spec.pauldron_scale = entry["pauldron"]
		spec.plume_scale = entry["plume"]


static func _index(size: int, key: int, channel: int) -> int:
	return mini(int(PlazaMeshKit.unit(key, channel) * size), size - 1)


static func _choice(list: Array, key: int, channel: int) -> int:
	return list[_index(list.size(), key, channel)]


## Um tom da tabela, mais claro ou mais escuro por hash.
static func _tone(table: Array, key: int, channel: int) -> Color:
	var base: Color = table[_index(table.size(), key, channel)]
	var shift: float = PlazaMeshKit.between(key, channel + TINT_CHANNEL_SHIFT, -TINT_RANGE, TINT_RANGE)
	return base.lightened(shift) if shift > 0.0 else base.darkened(-shift)
