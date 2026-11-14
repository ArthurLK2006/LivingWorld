class_name InhabitantArchetypes
extends RefCounted
## A MATRIZ de arquétipos dos habitantes (ART-9e, protótipo isolado, só apresentação): papel x subarquétipo, 3 x 4 = 12 pessoas comuns de uma vila medieval fantástica, um dado legível por linha. Cada linha traz as faixas de MORFOLOGIA (altura em m; ombros, peito, barriga, quadril, pescoço, braços, pernas e cabeça são multiplicadores do molde médio), constituições, idades, formas de cabeça, posturas, conjuntos [roupa, cobertura, acessórios...], mangas, cabelo, barba, humor, tecido, cinto e agasalho; o guarda leva ainda cristas, chance de escudo, alabarda e escalas de elmo, ombreira e penacho, e o mascate, o tamanho da trouxa. O hash escolhe o valor dentro de cada faixa (nunca um sorteio), e a ordem dos quatro subarquétipos vem embaralhada por hash em blocos de quatro ids: quatro ids seguidos de um papel mostram os quatro. Tudo [HIP] de arte, a calibrar olhando as capturas.

const SLOTS: int = 4
const ORDER_CHANNEL: int = 200
const LEAN: int = InhabitantSpec.Build.LEAN
const THIN: int = InhabitantSpec.Build.THIN
const AVERAGE: int = InhabitantSpec.Build.AVERAGE
const STOCKY: int = InhabitantSpec.Build.STOCKY
const STRONG: int = InhabitantSpec.Build.STRONG
const HEAVY: int = InhabitantSpec.Build.HEAVY
const YOUNG: int = InhabitantSpec.Age.YOUNG
const ADULT: int = InhabitantSpec.Age.ADULT
const OLD: int = InhabitantSpec.Age.OLD
const ROUND: int = InhabitantSpec.HeadShape.ROUND
const LONG_HEAD: int = InhabitantSpec.HeadShape.LONG
const SQUARE: int = InhabitantSpec.HeadShape.SQUARE
const SMALL_CHIN: int = InhabitantSpec.HeadShape.SMALL_CHIN
const UPRIGHT: int = InhabitantSpec.Posture.UPRIGHT
const STOOPED: int = InhabitantSpec.Posture.STOOPED
const LEANING: int = InhabitantSpec.Posture.LEANING
const TUNIC: int = InhabitantSpec.Garment.TUNIC
const LONG_COAT: int = InhabitantSpec.Garment.LONG_COAT
const TABARD: int = InhabitantSpec.Garment.TABARD
const DRESS: int = InhabitantSpec.Garment.DRESS
const SHORT_TUNIC: int = InhabitantSpec.Garment.SHORT_TUNIC
const BARE: int = InhabitantSpec.HeadCover.NONE
const HOOD: int = InhabitantSpec.HeadCover.HOOD
const CAP: int = InhabitantSpec.HeadCover.CAP
const WIDE_HAT: int = InhabitantSpec.HeadCover.WIDE_HAT
const HELM: int = InhabitantSpec.HeadCover.OPEN_HELM
const KERCHIEF: int = InhabitantSpec.HeadCover.SCARF
const STRAW: int = InhabitantSpec.HeadCover.STRAW_HAT
const BERET: int = InhabitantSpec.HeadCover.BERET
const WOOL: int = InhabitantSpec.HeadCover.WOOL_CAP
const LONG_SLEEVE: int = InhabitantSpec.Sleeve.LONG
const SHORT_SLEEVE: int = InhabitantSpec.Sleeve.SHORT
const ROLLED: int = InhabitantSpec.Sleeve.ROLLED
const PUFFED: int = InhabitantSpec.Sleeve.PUFFED
const BALD: int = InhabitantSpec.Hair.BALD
const CROP: int = InhabitantSpec.Hair.CROP
const SHORT_HAIR: int = InhabitantSpec.Hair.SHORT
const LONG_HAIR: int = InhabitantSpec.Hair.LONG
const BUN: int = InhabitantSpec.Hair.BUN
const MESSY: int = InhabitantSpec.Hair.MESSY
const CLEAN: int = InhabitantSpec.Beard.NONE
const SHORT_BEARD: int = InhabitantSpec.Beard.SHORT
const FULL_BEARD: int = InhabitantSpec.Beard.FULL
const MOUSTACHE: int = InhabitantSpec.Beard.MOUSTACHE
const GENTLE: int = InhabitantSpec.Mood.GENTLE
const CURIOUS: int = InhabitantSpec.Mood.CURIOUS
const TIRED: int = InhabitantSpec.Mood.TIRED
const SEVERE: int = InhabitantSpec.Mood.SEVERE
const PLAIN: int = InhabitantSpec.Fabric.PLAIN
const STRIPED: int = InhabitantSpec.Fabric.STRIPED
const PATCHED: int = InhabitantSpec.Fabric.PATCHED
const NO_APRON: int = InhabitantSpec.Apron.NONE
const SHORT_APRON: int = InhabitantSpec.Apron.SHORT
const LONG_APRON: int = InhabitantSpec.Apron.LONG
const LEATHER: int = InhabitantSpec.Waist.LEATHER
const SASH: int = InhabitantSpec.Waist.SASH
const ROPE: int = InhabitantSpec.Waist.ROPE
const NO_WRAP: int = InhabitantSpec.Wrap.NONE
const SHAWL: int = InhabitantSpec.Wrap.SHAWL
const NECKCLOTH: int = InhabitantSpec.Wrap.SCARF
const RIDGE: int = InhabitantSpec.Crest.RIDGE
const PLUME: int = InhabitantSpec.Crest.PLUME
## A matriz: por papel, os quatro subarquétipos (o índice é o da linha).
const TABLE: Dictionary[StringName, Array] = {
	InhabitantSpec.VILLAGER: [
		{
			"name": "camponês forte e largo", "height": Vector2(1.68, 1.82), "build": [STRONG, STOCKY], "age": [ADULT], "shoulder": Vector2(1.2, 1.34), "chest": Vector2(1.1, 1.25),
			"belly": Vector2(0.98, 1.18), "hip": Vector2(0.98, 1.1), "neck": Vector2(0.55, 0.8), "limbs": Vector2(1.2, 1.38), "legs": Vector2(1.15, 1.3), "head": Vector2(0.97, 1.06),
			"shapes": [SQUARE, ROUND, SQUARE], "posture": [UPRIGHT], "sleeves": [ROLLED, SHORT_SLEEVE, ROLLED], "hair": [CROP, SHORT_HAIR], "beard": [CLEAN, SHORT_BEARD, FULL_BEARD, SHORT_BEARD],
			"outfits": [[SHORT_TUNIC, STRAW, &"sack"], [SHORT_TUNIC, BARE, &"basket"], [TUNIC, WOOL, &"sack"], [SHORT_TUNIC, STRAW, &"basket"]],
			"mood": [GENTLE, TIRED, SEVERE], "fabric": [PLAIN, PATCHED, PLAIN], "apron": [NO_APRON, SHORT_APRON], "waist": [LEATHER, ROPE], "wrap": [NO_WRAP],
		},
		{
			"name": "idoso curvado de bengala", "height": Vector2(1.46, 1.62), "build": [THIN, AVERAGE], "age": [OLD], "shoulder": Vector2(0.82, 0.95), "chest": Vector2(0.85, 1.0),
			"belly": Vector2(0.9, 1.1), "hip": Vector2(0.9, 1.0), "neck": Vector2(0.8, 1.1), "limbs": Vector2(0.78, 0.92), "legs": Vector2(0.8, 0.95), "head": Vector2(1.0, 1.1),
			"shapes": [LONG_HEAD, SMALL_CHIN, ROUND], "posture": [STOOPED], "sleeves": [LONG_SLEEVE], "hair": [BALD, SHORT_HAIR, CROP], "beard": [FULL_BEARD, CLEAN, SHORT_BEARD, FULL_BEARD],
			"outfits": [[TUNIC, WOOL, &"cane"], [TUNIC, BARE, &"cane"], [TUNIC, HOOD, &"cane"], [TUNIC, WOOL, &"cane", &"satchel"]],
			"mood": [TIRED, GENTLE], "fabric": [PLAIN, PATCHED], "apron": [NO_APRON], "waist": [ROPE, LEATHER], "wrap": [SHAWL, NO_WRAP, NECKCLOTH],
		},
		{
			"name": "jovem esguio", "height": Vector2(1.66, 1.8), "build": [LEAN], "age": [YOUNG], "shoulder": Vector2(0.88, 1.0), "chest": Vector2(0.85, 0.95),
			"belly": Vector2(0.82, 0.92), "hip": Vector2(0.86, 0.96), "neck": Vector2(1.15, 1.5), "limbs": Vector2(0.78, 0.9), "legs": Vector2(0.8, 0.9), "head": Vector2(0.94, 1.02),
			"shapes": [SMALL_CHIN, ROUND, LONG_HEAD], "posture": [LEANING, UPRIGHT], "sleeves": [PUFFED, SHORT_SLEEVE, LONG_SLEEVE], "hair": [MESSY, SHORT_HAIR, LONG_HAIR], "beard": [CLEAN],
			"outfits": [[SHORT_TUNIC, BERET, &"satchel"], [SHORT_TUNIC, CAP, &"lantern"], [TUNIC, BARE, &"satchel"], [SHORT_TUNIC, WOOL, &"sack"]],
			"mood": [CURIOUS, GENTLE], "fabric": [STRIPED, PLAIN, PATCHED], "apron": [NO_APRON], "waist": [SASH, ROPE, LEATHER], "wrap": [NECKCLOTH, NO_WRAP],
		},
		{
			"name": "mulher robusta de lenço e cesta", "height": Vector2(1.52, 1.66), "build": [HEAVY, STOCKY], "age": [ADULT], "shoulder": Vector2(0.98, 1.1), "chest": Vector2(1.15, 1.3),
			"belly": Vector2(1.05, 1.22), "hip": Vector2(1.1, 1.22), "neck": Vector2(0.65, 0.95), "limbs": Vector2(1.0, 1.18), "legs": Vector2(1.0, 1.15), "head": Vector2(1.0, 1.08),
			"shapes": [ROUND, SMALL_CHIN], "posture": [UPRIGHT], "sleeves": [ROLLED, LONG_SLEEVE], "hair": [BUN, LONG_HAIR], "beard": [CLEAN],
			"outfits": [[DRESS, KERCHIEF, &"basket"], [DRESS, KERCHIEF, &"basket"], [DRESS, BARE, &"basket"], [DRESS, KERCHIEF, &"sack"]],
			"mood": [GENTLE, CURIOUS], "fabric": [PLAIN, PATCHED, STRIPED], "apron": [LONG_APRON, SHORT_APRON], "waist": [ROPE, LEATHER], "wrap": [SHAWL, NO_WRAP],
		},
	],
	InhabitantSpec.MERCHANT: [
		{
			"name": "negociante gordo", "height": Vector2(1.56, 1.74), "build": [HEAVY], "age": [ADULT], "shoulder": Vector2(1.02, 1.14), "chest": Vector2(1.2, 1.32),
			"belly": Vector2(1.45, 1.72), "hip": Vector2(1.0, 1.12), "neck": Vector2(0.5, 0.75), "limbs": Vector2(1.05, 1.2), "legs": Vector2(1.0, 1.15), "head": Vector2(1.02, 1.12),
			"shapes": [ROUND, SQUARE], "posture": [UPRIGHT], "sleeves": [LONG_SLEEVE, PUFFED], "hair": [SHORT_HAIR, CROP], "beard": [CLEAN],
			"outfits": [[LONG_COAT, WIDE_HAT, &"coin_pouch", &"satchel"], [LONG_COAT, WIDE_HAT, &"coin_pouch"], [TUNIC, WIDE_HAT, &"satchel", &"coin_pouch"]],
			"mood": [GENTLE, CURIOUS], "fabric": [STRIPED, PLAIN], "apron": [NO_APRON], "waist": [SASH, LEATHER], "wrap": [NO_WRAP, NECKCLOTH],
		},
		{
			"name": "magro astuto", "height": Vector2(1.7, 1.88), "build": [THIN, LEAN], "age": [ADULT, OLD], "shoulder": Vector2(0.88, 0.98), "chest": Vector2(0.82, 0.92),
			"belly": Vector2(0.8, 0.92), "hip": Vector2(0.85, 0.95), "neck": Vector2(1.2, 1.55), "limbs": Vector2(0.75, 0.88), "legs": Vector2(0.78, 0.9), "head": Vector2(0.92, 1.0),
			"shapes": [LONG_HEAD, SMALL_CHIN], "posture": [LEANING, UPRIGHT], "sleeves": [LONG_SLEEVE], "hair": [SHORT_HAIR, LONG_HAIR], "beard": [CLEAN],
			"outfits": [[LONG_COAT, WIDE_HAT, &"satchel"], [LONG_COAT, WIDE_HAT, &"satchel", &"coin_pouch"], [TUNIC, WIDE_HAT, &"coin_pouch", &"satchel"]],
			"mood": [CURIOUS, SEVERE], "fabric": [PLAIN, STRIPED], "apron": [NO_APRON], "waist": [LEATHER], "wrap": [NECKCLOTH, NO_WRAP],
		},
		{
			"name": "mascate de trouxa enorme", "height": Vector2(1.5, 1.7), "build": [AVERAGE, LEAN], "age": [YOUNG, ADULT], "shoulder": Vector2(0.95, 1.08), "chest": Vector2(0.95, 1.05),
			"belly": Vector2(0.9, 1.05), "hip": Vector2(0.95, 1.05), "neck": Vector2(0.8, 1.1), "limbs": Vector2(0.9, 1.05), "legs": Vector2(0.95, 1.1), "head": Vector2(0.98, 1.06),
			"shapes": [ROUND, LONG_HEAD], "posture": [STOOPED, LEANING], "sleeves": [ROLLED, LONG_SLEEVE], "hair": [MESSY, SHORT_HAIR], "beard": [CLEAN], "load": 2.2,
			"outfits": [[TUNIC, WIDE_HAT, &"coin_pouch", &"bundle"], [SHORT_TUNIC, WIDE_HAT, &"satchel", &"bundle"]],
			"mood": [CURIOUS, TIRED], "fabric": [PATCHED, STRIPED], "apron": [NO_APRON], "waist": [ROPE, SASH], "wrap": [NECKCLOTH, NO_WRAP],
		},
		{
			"name": "vendedora de barraca de avental", "height": Vector2(1.5, 1.7), "build": [AVERAGE, STOCKY], "age": [ADULT], "shoulder": Vector2(0.95, 1.05), "chest": Vector2(1.05, 1.2),
			"belly": Vector2(1.0, 1.2), "hip": Vector2(1.08, 1.2), "neck": Vector2(0.8, 1.05), "limbs": Vector2(0.95, 1.08), "legs": Vector2(0.95, 1.08), "head": Vector2(0.98, 1.06),
			"shapes": [ROUND, SMALL_CHIN], "posture": [UPRIGHT], "sleeves": [ROLLED, PUFFED, LONG_SLEEVE], "hair": [BUN, LONG_HAIR], "beard": [CLEAN],
			"outfits": [[DRESS, KERCHIEF, &"apron", &"coin_pouch"], [DRESS, BARE, &"apron", &"coin_pouch"], [TUNIC, KERCHIEF, &"apron", &"coin_pouch"]],
			"mood": [CURIOUS, GENTLE], "fabric": [STRIPED, PLAIN], "apron": [NO_APRON], "waist": [LEATHER, SASH], "wrap": [NO_WRAP, SHAWL],
		},
	],
	InhabitantSpec.GUARD: [
		{
			"name": "veterano grande e barbudo", "height": Vector2(1.82, 1.95), "build": [STRONG, HEAVY], "age": [ADULT, OLD], "shoulder": Vector2(1.2, 1.32), "chest": Vector2(1.2, 1.3),
			"belly": Vector2(1.0, 1.1), "hip": Vector2(0.98, 1.06), "neck": Vector2(0.55, 0.8), "limbs": Vector2(1.2, 1.35), "legs": Vector2(1.15, 1.3), "head": Vector2(0.95, 1.02),
			"shapes": [SQUARE], "posture": [UPRIGHT], "sleeves": [LONG_SLEEVE], "hair": [SHORT_HAIR], "beard": [FULL_BEARD],
			"outfits": [[TABARD, HELM, &"spear"]], "mood": [SEVERE, TIRED], "fabric": [PLAIN], "apron": [NO_APRON], "waist": [LEATHER], "wrap": [NO_WRAP],
			"crest": [RIDGE], "shield": 0.8, "halberd": false, "helm": 1.0, "pauldron": 1.0, "plume": 1.0,
		},
		{
			"name": "recruta jovem de elmo grande demais", "height": Vector2(1.7, 1.8), "build": [LEAN, THIN], "age": [YOUNG], "shoulder": Vector2(0.9, 1.0), "chest": Vector2(0.9, 1.0),
			"belly": Vector2(0.85, 0.95), "hip": Vector2(0.9, 1.0), "neck": Vector2(1.1, 1.4), "limbs": Vector2(0.82, 0.95), "legs": Vector2(0.85, 0.95), "head": Vector2(0.9, 0.96),
			"shapes": [SMALL_CHIN, ROUND], "posture": [LEANING, UPRIGHT], "sleeves": [LONG_SLEEVE], "hair": [MESSY, CROP], "beard": [CLEAN],
			"outfits": [[TABARD, HELM, &"spear"]], "mood": [CURIOUS, GENTLE], "fabric": [PLAIN], "apron": [NO_APRON], "waist": [LEATHER], "wrap": [NO_WRAP],
			"crest": [PLUME], "shield": 0.3, "halberd": false, "helm": 1.2, "pauldron": 0.8, "plume": 0.7,
		},
		{
			"name": "capitão largo de ombros e crista", "height": Vector2(1.8, 1.92), "build": [STRONG, AVERAGE], "age": [ADULT], "shoulder": Vector2(1.36, 1.48), "chest": Vector2(1.18, 1.3),
			"belly": Vector2(0.8, 0.9), "hip": Vector2(0.86, 0.94), "neck": Vector2(0.7, 0.95), "limbs": Vector2(1.15, 1.3), "legs": Vector2(1.05, 1.2), "head": Vector2(0.95, 1.0),
			"shapes": [SQUARE, ROUND], "posture": [UPRIGHT], "sleeves": [LONG_SLEEVE], "hair": [SHORT_HAIR], "beard": [MOUSTACHE, CLEAN],
			"outfits": [[TABARD, HELM, &"spear"], [TABARD, HELM, &"guard_staff"]], "mood": [SEVERE, GENTLE], "fabric": [PLAIN], "apron": [NO_APRON], "waist": [LEATHER], "wrap": [NO_WRAP],
			"crest": [PLUME], "shield": 0.5, "halberd": false, "helm": 1.0, "pauldron": 1.15, "plume": 1.55,
		},
		{
			"name": "vigia parrudo de lanterna e alabarda", "height": Vector2(1.72, 1.82), "build": [HEAVY, STOCKY], "age": [ADULT, OLD], "shoulder": Vector2(1.08, 1.2), "chest": Vector2(1.15, 1.3),
			"belly": Vector2(1.35, 1.55), "hip": Vector2(1.18, 1.3), "neck": Vector2(0.55, 0.8), "limbs": Vector2(1.1, 1.25), "legs": Vector2(1.1, 1.25), "head": Vector2(1.0, 1.08),
			"shapes": [ROUND, SQUARE], "posture": [UPRIGHT, LEANING], "sleeves": [LONG_SLEEVE], "hair": [SHORT_HAIR, BALD], "beard": [SHORT_BEARD, CLEAN],
			"outfits": [[TABARD, HELM, &"guard_staff", &"lantern"]], "mood": [TIRED, GENTLE], "fabric": [PLAIN], "apron": [NO_APRON], "waist": [LEATHER], "wrap": [NO_WRAP],
			"crest": [RIDGE], "shield": 0.0, "halberd": true, "helm": 1.0, "pauldron": 1.05, "plume": 1.0,
		},
	],
}


## O subarquétipo (0 a 3) do habitante `inhabitant_id` no papel `role`: em cada bloco de quatro ids seguidos os quatro aparecem, numa ordem embaralhada por hash de inteiros.
static func pick(role: StringName, inhabitant_id: int) -> int:
	var slot: int = posmod(inhabitant_id - 1, SLOTS)
	var block: int = floori(float(inhabitant_id - 1 - slot) / SLOTS)
	var mix: int = block * InhabitantSpec.ROLES.size() + InhabitantSpec.ROLES.find(role)
	var order: Array[int] = [0, 1, 2, 3]
	for index: int in range(SLOTS - 1, 0, -1):
		var other: int = mini(int(PlazaMeshKit.unit(mix, ORDER_CHANNEL + index) * (index + 1)), index)
		var kept: int = order[index]
		order[index] = order[other]
		order[other] = kept
	return order[slot]


## A linha da matriz do papel `role` e do subarquétipo `index`.
static func entry(role: StringName, index: int) -> Dictionary:
	var rows: Array = TABLE[role]
	return rows[index]
