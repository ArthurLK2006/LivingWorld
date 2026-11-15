class_name CharacterAppearance
extends RefCounted
## A ficha de aparência de UM NPC (ART-12, entrega 3; só dados, sem Node nem visual): função PURA do `npc_id` e das tabelas do catálogo e das paletas, por hash de inteiros, sem sorteio, sem relógio e sem ordem de carga. O mesmo `npc_id` dá a mesma ficha a cada carregamento e em cada máquina. Profissão e facção não entram (a consulta de corpos só traz id e posição). Contrato: docs/modules/presentation.md.
## A ORDEM das tabelas é entrada: a escolha é por índice, então reordenar ou inserir no meio de uma tabela muda as fichas; acrescente só no fim.
## O hash: `mix32` mistura 32 bits (xorshift e multiplicação, duas rodadas) e MASCARA para 32 bits depois de cada passo. Os multiplicadores são ímpares de 31 bits, então o produto de um valor de 32 bits cabe em 63 bits e o resultado nunca depende de estouro de inteiro. Cada campo usa o hash com o PRÓPRIO SAL (`hash_field`: o sal entra entre as duas misturas), então os campos não se correlacionam.

const MASK_32: int = 0xFFFFFFFF
const MIX_MULTIPLIER_A: int = 0x21F0AAAD
const MIX_MULTIPLIER_B: int = 0x735A2D97
const MIX_SHIFT_A: int = 16
const MIX_SHIFT_B: int = 15
## Um sal por campo: os oito primeiros múltiplos de 0x9E3779B9 (razão áurea) módulo 2^32.
const SALT_BODY: int = 0x9E3779B9
const SALT_OUTFIT: int = 0x3C6EF372
const SALT_HAIR: int = 0xDAA66D2B
const SALT_EYEBROW: int = 0x78DDE6E4
const SALT_CLOTH: int = 0x1715609D
const SALT_SKIN: int = 0xB54CDA56
const SALT_HAIR_TONE: int = 0x5384540F
const SALT_SCALE: int = 0xF1BBCDC8
## Escala pequena do corpo, em milésimos [HIP].
const SCALE_MIN_PERMILLE: int = 960
const SCALE_MAX_PERMILLE: int = 1040
const NEUTRAL_SCALE_PERMILLE: int = 1000

var npc_id: int = 0
var body_id: String = ""
var gender: String = ""
var outfit_id: String = ""
var hair_id: String = ""
var eyebrow_id: String = ""
var cloth_palette_index: int = 0
var skin_index: int = 0
var hair_tone_index: int = 0
var scale_permille: int = NEUTRAL_SCALE_PERMILLE


## A ficha do NPC `target_id` (qualquer inteiro: 0 e negativos também têm ficha, pelo mesmo hash). Catálogo ou paletas não carregados: a ficha vem sem peças (`is_resolved()` falso).
static func of(target_id: int, catalog: CharacterCatalog, palettes: CharacterPalettes) -> CharacterAppearance:
	var sheet: CharacterAppearance = CharacterAppearance.new()
	sheet.npc_id = target_id
	if not catalog.is_ready() or not palettes.is_ready():
		return sheet
	var body: Dictionary = _choose(catalog.bodies(), target_id, SALT_BODY)
	sheet.body_id = body["id"]
	sheet.gender = body["gender"]
	sheet.outfit_id = _choose(catalog.outfits_for(sheet.gender), target_id, SALT_OUTFIT)["id"]
	sheet.hair_id = _choose(catalog.hair_for(sheet.gender), target_id, SALT_HAIR)["id"]
	sheet.eyebrow_id = _choose(catalog.eyebrows(), target_id, SALT_EYEBROW)["id"]
	sheet.cloth_palette_index = pick(target_id, SALT_CLOTH, palettes.count(CharacterPalettes.CLOTH))
	sheet.skin_index = pick(target_id, SALT_SKIN, palettes.count(CharacterPalettes.SKIN))
	sheet.hair_tone_index = pick(target_id, SALT_HAIR_TONE, palettes.count(CharacterPalettes.HAIR))
	sheet.scale_permille = SCALE_MIN_PERMILLE + pick(target_id, SALT_SCALE, SCALE_MAX_PERMILLE - SCALE_MIN_PERMILLE + 1)
	return sheet


## Mistura de 32 bits: o mesmo valor dá sempre o mesmo resultado, sem estado. Entrada fora de 32 bits (negativa, por exemplo) vale pelos 32 bits de baixo.
static func mix32(value: int) -> int:
	var mixed: int = value & MASK_32
	mixed = mixed ^ (mixed >> MIX_SHIFT_A)
	mixed = (mixed * MIX_MULTIPLIER_A) & MASK_32
	mixed = mixed ^ (mixed >> MIX_SHIFT_B)
	mixed = (mixed * MIX_MULTIPLIER_B) & MASK_32
	return mixed ^ (mixed >> MIX_SHIFT_B)


static func hash_field(target_id: int, salt: int) -> int:
	return mix32(mix32(target_id) ^ salt)


## Um índice de 0 a size-1 para o par (id, sal); 0 se a tabela estiver vazia.
static func pick(target_id: int, salt: int, size: int) -> int:
	if size <= 0:
		return 0
	return hash_field(target_id, salt) % size


## Há ficha de verdade (o catálogo e as paletas estavam carregados).
func is_resolved() -> bool:
	return not body_id.is_empty()


## Texto estável da APARÊNCIA (sem o `npc_id`: dois NPCs de aparência igual têm o mesmo texto), para os testes.
func fingerprint() -> String:
	return "%s|%s|%s|%s|%d|%d|%d|%d" % [body_id, outfit_id, hair_id, eyebrow_id, cloth_palette_index, skin_index, hair_tone_index, scale_permille]


static func _choose(options: Array[Dictionary], target_id: int, salt: int) -> Dictionary:
	return options[pick(target_id, salt, options.size())]
