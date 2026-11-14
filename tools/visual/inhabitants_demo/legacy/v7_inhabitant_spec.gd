class_name V7InhabitantSpec
extends RefCounted
## [v7 CONGELADA, só para a cena de comparação] Ficha de UM habitante (ART-9 e ART-9d, protótipo isolado, só apresentação): dado puro, escolhido por hash de inteiros a partir de (id, papel), sem sorteio da engine, então o mesmo par dá sempre a mesma ficha e a mesma malha. Faixas, tabelas e paletas são [HIP] de arte, a calibrar olhando as capturas; cada campo tem o seu canal de hash. Os campos da ART-9 (altura, cores, roupa, cobertura, acessórios) saem dos mesmos canais de antes, então o mesmo id mantém o mesmo conjunto; os da ART-9d (expressão, barba, tecido, avental, ombreiras, crista, escudo, corpo) usam canais novos, no fim.

enum Garment { TUNIC, LONG_COAT, TABARD }
enum HeadCover { NONE, HOOD, CAP, WIDE_HAT, OPEN_HELM, HOOD_CAP }
enum Mood { GENTLE, CURIOUS, TIRED, SEVERE }
enum Beard { NONE, SHORT, FULL }
enum Fabric { PLAIN, STRIPED, PATCHED }
enum Apron { NONE, SHORT, LONG }
enum Crest { NONE, RIDGE, PLUME }
enum Channel { HEIGHT, WIDTH, HEAD, SKIN, HAIR, OUTFIT, TOP, BOTTOM, TRIM, BOOTS, COVER, EXPRESSION, BEARD, FABRIC, APRON, CREST, SHIELD, BELLY, DROOP, LEAN, ALT, COLLAR, BUNDLE }

const VILLAGER: StringName = &"villager"
const MERCHANT: StringName = &"merchant"
const GUARD: StringName = &"guard"
const ROLES: Array[StringName] = [VILLAGER, MERCHANT, GUARD]
## Faixas por papel: altura (m) e largura TOTAL, com os braços (m); a escala da cabeça vale para todos. O guarda é o mais alto e de ombros largos (a ombreira some na largura).
const HEIGHT_M: Dictionary[StringName, Vector2] = {VILLAGER: Vector2(1.42, 1.76), MERCHANT: Vector2(1.4, 1.72), GUARD: Vector2(1.74, 1.86)}
const WIDTH_M: Dictionary[StringName, Vector2] = {VILLAGER: Vector2(0.9, 1.02), MERCHANT: Vector2(0.94, 1.04), GUARD: Vector2(0.84, 0.96)}
const HEAD_SCALE: Vector2 = Vector2(0.92, 1.1)
## Cada tom varia um pouco por habitante (fração de claro ou de escuro), com um canal de hash próprio (canal da cor + deslocamento).
const TINT_RANGE: float = 0.08
const TINT_CHANNEL_SHIFT: int = 32
## Corpo: a barriga e o ombro caído variam por hash (a barriga multiplica o raio; o ombro caído vai de 0 a 1).
const BELLY_RANGE: Vector2 = Vector2(0.94, 1.08)
## Conjuntos de roupa por papel: [roupa, cobertura da cabeça, acessórios...] (a mesma tabela da ART-9: o mesmo id mantém o conjunto). Cada um já tem o que define o papel (guarda: elmo e lança ou cajado de guarda; comerciante: bolsa ou bolsinha e avental ou chapéu largo; aldeão: sem elmo nem lança; capuz com boné é a combinação da referência de Arthur).
const OUTFITS: Dictionary[StringName, Array] = {
	VILLAGER: [
		[Garment.TUNIC, HeadCover.HOOD, &"basket"], [Garment.TUNIC, HeadCover.CAP, &"sack"], [Garment.TUNIC, HeadCover.HOOD, &"staff", &"satchel"],
		[Garment.TUNIC, HeadCover.NONE, &"basket"], [Garment.TUNIC, HeadCover.CAP, &"lantern"], [Garment.TUNIC, HeadCover.NONE, &"sack"],
		[Garment.TUNIC, HeadCover.HOOD_CAP, &"satchel"],
	],
	MERCHANT: [
		[Garment.LONG_COAT, HeadCover.WIDE_HAT, &"satchel"], [Garment.TUNIC, HeadCover.CAP, &"apron", &"coin_pouch"],
		[Garment.LONG_COAT, HeadCover.WIDE_HAT, &"coin_pouch", &"apron"], [Garment.TUNIC, HeadCover.WIDE_HAT, &"satchel", &"coin_pouch"],
	],
	GUARD: [[Garment.TABARD, HeadCover.OPEN_HELM, &"spear"], [Garment.TABARD, HeadCover.OPEN_HELM, &"guard_staff"], [Garment.TABARD, HeadCover.OPEN_HELM, &"spear", &"lantern"]],
}
## Expressão por papel (o índice sai do hash): aldeão gentil ou curioso, comerciante curioso ou gentil, guarda severo ou cansado.
const EXPRESSIONS: Dictionary[StringName, Array] = {
	VILLAGER: [Mood.GENTLE, Mood.CURIOUS, Mood.TIRED, Mood.GENTLE],
	MERCHANT: [Mood.CURIOUS, Mood.GENTLE, Mood.CURIOUS, Mood.SEVERE],
	GUARD: [Mood.SEVERE, Mood.TIRED, Mood.SEVERE, Mood.GENTLE],
}
## Sorteios por hash (fração de 0 a 1): barba curta e cheia só de aldeões, tecido listrado e remendado, avental curto do aldeão, trouxa do comerciante, crista de pluma do guarda e escudo do guarda de lança.
const BEARD_SHORT: float = 0.2
const BEARD_FULL: float = 0.35
const FABRIC_PATCHED: float = 0.25
const FABRIC_STRIPED: float = 0.5
const SHORT_APRON: float = 0.4
const BUNDLE_CHANCE: float = 0.5
const PLUME_CHANCE: float = 0.5
const SHIELD_CHANCE: float = 0.6
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
var belly: float = 1.0
var droop: float = 0.0
var lean: float = 0.0


## A ficha do habitante `inhabitant_id` no papel `role_name` (papel desconhecido vira aldeão). O mesmo par dá sempre a mesma ficha.
static func for_inhabitant(inhabitant_id: int, role_name: StringName) -> V7InhabitantSpec:
	var kind: StringName = role_name if ROLES.has(role_name) else VILLAGER
	var key: int = inhabitant_id * ROLES.size() + ROLES.find(kind)
	var spec: V7InhabitantSpec = V7InhabitantSpec.new()
	spec.id = inhabitant_id
	spec.role = kind
	spec.height_m = PlazaMeshKit.between(key, Channel.HEIGHT, HEIGHT_M[kind].x, HEIGHT_M[kind].y)
	spec.width_m = PlazaMeshKit.between(key, Channel.WIDTH, WIDTH_M[kind].x, WIDTH_M[kind].y)
	spec.head_scale = PlazaMeshKit.between(key, Channel.HEAD, HEAD_SCALE.x, HEAD_SCALE.y)
	var outfits: Array = OUTFITS[kind]
	var outfit: Array = outfits[_index(outfits.size(), key, Channel.OUTFIT)]
	spec.garment = outfit[0]
	spec.head_cover = outfit[1]
	spec.accessories.assign(outfit.slice(2))
	var palette: Array = PALETTES[kind]
	spec.skin = _tone(SKIN_TONES, key, Channel.SKIN)
	spec.hair = _tone(HAIR_TONES, key, Channel.HAIR)
	spec.boots = _tone(BOOT_TONES, key, Channel.BOOTS)
	spec.top = _tone(palette[0], key, Channel.TOP)
	spec.bottom = _tone(palette[1], key, Channel.BOTTOM)
	spec.trim = _tone(palette[2], key, Channel.TRIM)
	spec.cover_color = _tone(palette[3], key, Channel.COVER)
	spec.alt = _tone(palette[4], key, Channel.ALT)
	spec.collar = _tone(palette[5], key, Channel.COLLAR)
	_dress(spec, kind, key)
	return spec


func has_accessory(kind: StringName) -> bool:
	return accessories.has(kind)


## Os campos da ART-9d (cada um com o seu canal): rosto, tecido, avental, equipamento do guarda, trouxa do comerciante e corpo.
static func _dress(spec: V7InhabitantSpec, kind: StringName, key: int) -> void:
	var expressions: Array = EXPRESSIONS[kind]
	spec.expression = expressions[_index(expressions.size(), key, Channel.EXPRESSION)]
	var beard_roll: float = PlazaMeshKit.unit(key, Channel.BEARD)
	if kind == VILLAGER:
		spec.beard = Beard.SHORT if beard_roll < BEARD_SHORT else (Beard.FULL if beard_roll < BEARD_FULL else Beard.NONE)
	var fabric_roll: float = PlazaMeshKit.unit(key, Channel.FABRIC)
	if kind == VILLAGER:
		spec.fabric = Fabric.PATCHED if fabric_roll < FABRIC_PATCHED else (Fabric.STRIPED if fabric_roll < FABRIC_STRIPED else Fabric.PLAIN)
	elif kind == MERCHANT:
		spec.fabric = Fabric.STRIPED if fabric_roll < FABRIC_STRIPED else Fabric.PLAIN
	if spec.has_accessory(&"apron"):
		spec.apron = Apron.LONG
	elif kind == VILLAGER and PlazaMeshKit.unit(key, Channel.APRON) < SHORT_APRON:
		spec.apron = Apron.SHORT
	if kind == MERCHANT and PlazaMeshKit.unit(key, Channel.BUNDLE) < BUNDLE_CHANCE:
		spec.accessories.append(&"bundle")
	if kind == GUARD:
		spec.has_pauldrons = true
		spec.crest = Crest.PLUME if PlazaMeshKit.unit(key, Channel.CREST) < PLUME_CHANCE else Crest.RIDGE
		spec.has_shield = spec.has_accessory(&"spear") and PlazaMeshKit.unit(key, Channel.SHIELD) < SHIELD_CHANCE
	spec.belly = PlazaMeshKit.between(key, Channel.BELLY, BELLY_RANGE.x, BELLY_RANGE.y)
	spec.droop = PlazaMeshKit.unit(key, Channel.DROOP)
	spec.lean = PlazaMeshKit.between(key, Channel.LEAN, -1.0, 1.0)


static func _index(size: int, key: int, channel: int) -> int:
	return mini(int(PlazaMeshKit.unit(key, channel) * size), size - 1)


## Um tom da tabela, mais claro ou mais escuro por hash.
static func _tone(table: Array, key: int, channel: int) -> Color:
	var base: Color = table[_index(table.size(), key, channel)]
	var shift: float = PlazaMeshKit.between(key, channel + TINT_CHANNEL_SHIFT, -TINT_RANGE, TINT_RANGE)
	return base.lightened(shift) if shift > 0.0 else base.darkened(-shift)
