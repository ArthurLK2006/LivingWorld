class_name PlazaVariants
extends RefCounted
## ART-3: a identidade de cada praça de mercado como dados. A `MarketPlazaView` escolhe a ficha pelo id do mercado (`for_market`) e a montagem (`PlazaStructures`) a lê: lugar e quantidade das barracas e a altura delas, os adereços, a cor e o material dos panos, a peça central e as cores das casas.
## Nenhum sorteio novo: a variação de cada peça segue o hash de sempre (PlazaMeshKit.unit). A variante A é a praça de hoje (as constantes de sempre de PlazaData) e a de qualquer id fora da tabela; B (mercado de rua, frio e arrumado) e C (praça rústica e sóbria) trocam os dados [HIP], a calibrar olhando a cena.

enum Center { WELL, FOUNTAIN, ROTUNDA }

## Mercado (id do local) -> variante.
const BY_MARKET: Dictionary[String, StringName] = {"a_market_01": &"a", "b_market_01": &"b", "c_market_01": &"c"}
const DEFAULT: StringName = &"a"
## O nome do nó da peça central de cada `Center`.
const CENTER_NAMES: Array[String] = ["Well", "Fountain", "Rotunda"]


## A ficha de uma variante, o que a montagem lê. Os padrões são os da praça de hoje (A).
class Spec extends RefCounted:
	## Barracas: (x, z, giro em rad).
	var stalls: Array[Vector3] = PlazaVariants.facing_center(PlazaData.STALL_SPOTS)
	var stall_post_m: float = PlazaData.STALL_POST_M
	var prop_kinds: Array[int] = PlazaData.PROP_KINDS
	var cloth_colors: Array[Color] = PlazaData.CLOTH_COLORS
	## Materiais dos panos (toldo, tiras e bandeirolas): a peça `item` vai para a superfície `item % tamanho`. O primeiro leva a cor por vértice (e o toldo); os outros são acentos emissivos.
	var cloth_materials: Array[StringName] = [&"cloth", &"accent_warm", &"accent_cyan"]
	var center: PlazaVariants.Center = PlazaVariants.Center.WELL
	var wall_colors: Array[Color] = PlazaData.WALL_COLORS
	var roof_colors: Array[Color] = PlazaData.ROOF_COLORS


## A ficha do mercado `market_id`; id fora da tabela dá a de hoje.
static func for_market(market_id: String) -> Spec:
	return named(BY_MARKET.get(market_id, DEFAULT) as StringName)


## A ficha da variante `variant_id`; id desconhecido dá a de hoje (A).
static func named(variant_id: StringName) -> Spec:
	var spec: Spec = Spec.new()
	match variant_id:
		&"b":
			spec.stalls = PlazaData.STALL_POSES_B
			spec.prop_kinds = PlazaData.PROP_KINDS_B
			spec.cloth_colors = PlazaData.CLOTH_COLORS_B
			spec.cloth_materials = [&"cloth", &"accent_cyan"]
			spec.center = Center.FOUNTAIN
			spec.wall_colors = PlazaData.WALL_COLORS_B
			spec.roof_colors = PlazaData.ROOF_COLORS_B
		&"c":
			spec.stalls = facing_center(PlazaData.STALL_SPOTS_C)
			spec.stall_post_m = PlazaData.STALL_POST_C_M
			spec.prop_kinds = PlazaData.PROP_KINDS_C
			spec.cloth_colors = PlazaData.CLOTH_COLORS_C
			spec.cloth_materials = [&"cloth"]
			spec.center = Center.ROTUNDA
			spec.wall_colors = PlazaData.WALL_COLORS_C
			spec.roof_colors = PlazaData.ROOF_COLORS_C
	return spec


## Barracas nos lugares `spots` (x, z), todas viradas para o centro da praça: (x, z, giro em rad).
static func facing_center(spots: Array[Vector2]) -> Array[Vector3]:
	var poses: Array[Vector3] = []
	for spot: Vector2 in spots:
		poses.append(Vector3(spot.x, spot.y, atan2(-spot.x, -spot.y)))
	return poses
