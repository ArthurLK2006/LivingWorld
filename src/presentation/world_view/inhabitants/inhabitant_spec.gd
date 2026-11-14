class_name InhabitantSpec
extends RefCounted
## Ficha de UM habitante (ART-9, protótipo isolado, só apresentação): dado puro, escolhido por hash de inteiros a partir de (id, papel), sem sorteio da engine, então o mesmo par dá sempre a mesma ficha e a mesma malha. Faixas, tabelas e paletas são [HIP] de arte, a calibrar olhando a cena de demonstração; cada campo tem o seu canal de hash.

enum Garment { TUNIC, LONG_COAT, TABARD }
enum HeadCover { NONE, HOOD, CAP, WIDE_HAT, OPEN_HELM }
enum Channel { HEIGHT, WIDTH, HEAD, SKIN, HAIR, OUTFIT, TOP, BOTTOM, TRIM, BOOTS, COVER }

const VILLAGER: StringName = &"villager"
const MERCHANT: StringName = &"merchant"
const GUARD: StringName = &"guard"
const ROLES: Array[StringName] = [VILLAGER, MERCHANT, GUARD]
## Faixas por papel: altura (m) e largura TOTAL, com os braços (m); a escala da cabeça vale para todos.
const HEIGHT_M: Dictionary[StringName, Vector2] = {VILLAGER: Vector2(1.42, 1.76), MERCHANT: Vector2(1.4, 1.72), GUARD: Vector2(1.72, 1.86)}
const WIDTH_M: Dictionary[StringName, Vector2] = {VILLAGER: Vector2(0.76, 0.88), MERCHANT: Vector2(0.8, 0.9), GUARD: Vector2(0.76, 0.88)}
const HEAD_SCALE: Vector2 = Vector2(0.92, 1.1)
## Cada tom varia um pouco por habitante (fração de claro ou de escuro), com um canal de hash próprio (canal da cor + deslocamento).
const TINT_RANGE: float = 0.08
const TINT_CHANNEL_SHIFT: int = 32
## Conjuntos de roupa por papel: [roupa, cobertura da cabeça, acessórios...]. Cada um já tem o que define o papel (guarda: elmo e lança ou cajado de guarda; comerciante: bolsa ou bolsinha e avental ou chapéu largo; aldeão: sem elmo nem lança).
const OUTFITS: Dictionary[StringName, Array] = {
	VILLAGER: [
		[Garment.TUNIC, HeadCover.HOOD, &"basket"], [Garment.TUNIC, HeadCover.CAP, &"sack"], [Garment.TUNIC, HeadCover.HOOD, &"staff", &"satchel"],
		[Garment.TUNIC, HeadCover.NONE, &"basket"], [Garment.TUNIC, HeadCover.CAP, &"lantern"], [Garment.TUNIC, HeadCover.NONE, &"sack"],
	],
	MERCHANT: [
		[Garment.LONG_COAT, HeadCover.WIDE_HAT, &"satchel"], [Garment.TUNIC, HeadCover.CAP, &"apron", &"coin_pouch"],
		[Garment.LONG_COAT, HeadCover.WIDE_HAT, &"coin_pouch", &"apron"], [Garment.TUNIC, HeadCover.WIDE_HAT, &"satchel", &"coin_pouch"],
	],
	GUARD: [[Garment.TABARD, HeadCover.OPEN_HELM, &"spear"], [Garment.TABARD, HeadCover.OPEN_HELM, &"guard_staff"], [Garment.TABARD, HeadCover.OPEN_HELM, &"spear", &"lantern"]],
}
const SKIN_TONES: Array[Color] = [Color("EDBB9A"), Color("E5A783"), Color("D79B72"), Color("C48862"), Color("B27A52"), Color("98653F")]
const HAIR_TONES: Array[Color] = [Color("3E2B20"), Color("5C3B23"), Color("8A5A2B"), Color("C79A4A"), Color("A8A29A"), Color("7A3B20")]
const BOOT_TONES: Array[Color] = [Color("5A3C2B"), Color("4A3326"), Color("6A4A34")]
## Paletas por papel: peça de cima, de baixo, debrum (cinto) e cobertura da cabeça. Aldeão = tons terrosos; comerciante = cores mais ricas; guarda = tabardo cinza-azulado e aço.
const PALETTES: Dictionary[StringName, Array] = {
	VILLAGER: [
		[Color("A8703C"), Color("8E5E34"), Color("B98B45"), Color("7C8445"), Color("9B5B3A"), Color("6F8466")],
		[Color("6E8A3E"), Color("5C6F3A"), Color("7A5A3A"), Color("4F5E6A")], [Color("6A4630"), Color("54382A"), Color("7A5535")],
		[Color("8B6446"), Color("6A8E4A"), Color("7A5A44"), Color("8A7A3C"), Color("6B9A3F")],
	],
	MERCHANT: [
		[Color("A93A3F"), Color("2F7F86"), Color("3A5CA0"), Color("7B3F80"), Color("C8962E"), Color("3F7D4A")],
		[Color("5A4632"), Color("3E3A52"), Color("5E5A3A")], [Color("D4A93A"), Color("E8DCC0"), Color("A87A3A")],
		[Color("7A4A2E"), Color("A23E3E"), Color("335D8F"), Color("5A7A3A"), Color("D2B060")],
	],
	GUARD: [
		[Color("6F819A"), Color("7A8CA3"), Color("66788F")], [Color("4A5568"), Color("55606E"), Color("3F4856")],
		[Color("C8B070"), Color("B0B8C0"), Color("D8C890")], [Color("8795A8"), Color("7E8CA0"), Color("94A1B2")],
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
var garment: int = Garment.TUNIC
var head_cover: int = HeadCover.NONE
var accessories: Array[StringName] = []


## A ficha do habitante `inhabitant_id` no papel `role` (papel desconhecido vira aldeão). O mesmo par dá sempre a mesma ficha.
static func for_inhabitant(inhabitant_id: int, role_name: StringName) -> InhabitantSpec:
	var kind: StringName = role_name if ROLES.has(role_name) else VILLAGER
	var key: int = inhabitant_id * ROLES.size() + ROLES.find(kind)
	var spec: InhabitantSpec = InhabitantSpec.new()
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
	return spec


func has_accessory(kind: StringName) -> bool:
	return accessories.has(kind)


static func _index(size: int, key: int, channel: int) -> int:
	return mini(int(PlazaMeshKit.unit(key, channel) * size), size - 1)


## Um tom da tabela, mais claro ou mais escuro por hash.
static func _tone(table: Array, key: int, channel: int) -> Color:
	var base: Color = table[_index(table.size(), key, channel)]
	var shift: float = PlazaMeshKit.between(key, channel + TINT_CHANNEL_SHIFT, -TINT_RANGE, TINT_RANGE)
	return base.lightened(shift) if shift > 0.0 else base.darkened(-shift)
