class_name PlazaVariants
extends RefCounted
## ART-3: a identidade de cada praça de mercado como dados. A `MarketPlazaView` escolhe a ficha pelo id do mercado (`for_market`) e a montagem (`PlazaStructures`, `PlazaGround` e `PlazaMaterials`) a lê: lugar e quantidade das barracas, a altura e o arquétipo de cada uma (ART-5b1: tenda, toldo de uma água, mesa com guarda-sol ou carroça), os adereços, a cor e o material dos panos, a peça central e as cores das casas.
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
	## O arquétipo de cada barraca (PlazaData.StallKind), na ordem de `stalls`; a que fica sem entrada é a tenda piramidal de hoje. A altura dos postes (`stall_post_m`) vale só para as tendas.
	var stall_kinds: Array[int] = []
	var prop_kinds: Array[int] = PlazaData.PROP_KINDS
	var cloth_colors: Array[Color] = PlazaData.CLOTH_COLORS
	## Materiais dos panos (toldo, tiras e bandeirolas): a peça `item` vai para a superfície `item % tamanho`. O primeiro leva a cor por vértice (e o toldo); os outros são acentos emissivos.
	var cloth_materials: Array[StringName] = [&"cloth", &"accent_warm", &"accent_cyan"]
	var center: PlazaVariants.Center = PlazaVariants.Center.WELL
	var wall_colors: Array[Color] = PlazaData.WALL_COLORS
	var roof_colors: Array[Color] = PlazaData.ROOF_COLORS
	## ART-6a, a vegetação (padrões = os da praça de hoje). Árvores: forma, medidas e verde de cada tipo, repartidos por índice. Lugares (x, z) das árvores, das rochas e dos arbustos: vazios, as árvores e rochas ficam no anel de hoje e não há arbustos. Rochas: escala e cor. Flores: as cores e quantas de cada. Grama: quantidade, tamanho do tufo e cores (base e ponta). `scatter_half_m`: metade da área onde grama e flores nascem.
	var tree_shapes: Array[int] = PlazaData.TREE_SHAPES
	var tree_forms: Array[Vector3] = PlazaData.TREE_VARIANTS
	var tree_greens: Array[Color] = PlazaData.TREE_GREENS
	var tree_spots: Array[Vector2] = []
	var rock_spots: Array[Vector2] = []
	var rock_size: float = 1.0
	var rock_color: Color = PlazaData.STONE
	var bush_spots: Array[Vector2] = []
	var flower_colors: Array[Color] = PlazaData.FLOWER_COLORS
	var flowers_per_color: int = PlazaData.FLOWERS_PER_COLOR
	var grass_count: int = PlazaData.GRASS_COUNT
	var grass_size: Vector2 = PlazaData.GRASS_SIZE
	var grass_colors: Array[Color] = PlazaData.GRASS_COLORS
	var scatter_half_m: Vector2 = PlazaData.SCATTER_HALF_M
	## Verdadeiro se a vegetação cabe no FOOTPRINT_M: a praça do jogo a leva. A A traz a da demonstração (o anel de 10 a 17 m) e fica sem.
	var plants_in_footprint: bool = false
	## D1: as cores do chão da demonstração (terra e verde, cada par é claro e escuro). Os padrões são os de hoje.
	var ground_dirt: Array[Color] = [PlazaData.DIRT, PlazaData.DIRT_DARK]
	var ground_greens: Array[Color] = [PlazaData.GRASS, PlazaData.GRASS_DARK]
	## D1: a ficha de estilo da nova linguagem (PlazaStyle); nula = a linguagem de sempre.
	var style: PlazaStyle = null


	## O arquétipo da barraca `index` (um de PlazaData.StallKind).
	func stall_kind(index: int) -> int:
		return stall_kinds[index] if index < stall_kinds.size() else PlazaData.StallKind.TENT


## A ficha do mercado `market_id`; id fora da tabela dá a de hoje.
static func for_market(market_id: String) -> Spec:
	return named(BY_MARKET.get(market_id, DEFAULT) as StringName)


## A ficha da variante `variant_id`; id desconhecido dá a de hoje (A).
static func named(variant_id: StringName) -> Spec:
	var spec: Spec = Spec.new()
	match variant_id:
		&"b":
			spec.stalls = PlazaData.STALL_POSES_B
			spec.stall_kinds = PlazaData.STALL_KINDS_B
			spec.prop_kinds = PlazaData.PROP_KINDS_B
			spec.cloth_colors = PlazaData.CLOTH_COLORS_B
			spec.cloth_materials = [&"cloth", &"accent_cyan"]
			spec.center = Center.FOUNTAIN
			spec.wall_colors = PlazaData.WALL_COLORS_B
			spec.roof_colors = PlazaData.ROOF_COLORS_B
			_plant_b(spec)
		&"c":
			spec.stalls = facing_center(PlazaData.STALL_SPOTS_C)
			spec.stall_post_m = PlazaData.STALL_POST_C_M
			spec.stall_kinds = PlazaData.STALL_KINDS_C
			spec.prop_kinds = PlazaData.PROP_KINDS_C
			spec.cloth_colors = PlazaData.CLOTH_COLORS_C
			spec.cloth_materials = [&"cloth"]
			spec.center = Center.ROTUNDA
			spec.wall_colors = PlazaData.WALL_COLORS_C
			spec.roof_colors = PlazaData.ROOF_COLORS_C
			_plant_c(spec)
		&"d":
			_north(spec)
	return spec


## D (D1, estudo isolado): a planta da A com a paleta "norte sóbrio" [HIP]: panos só de cor por vértice (sem os acentos emissivos), terra e verde dessaturados, coníferas frias e flores raras com um acento ocre.
static func _north(spec: Spec) -> void:
	spec.cloth_colors = PlazaData.CLOTH_COLORS_D
	spec.cloth_materials = [&"cloth"]
	spec.wall_colors = PlazaData.WALL_COLORS_D
	spec.roof_colors = PlazaData.ROOF_COLORS_D
	spec.tree_greens = PlazaData.TREE_GREENS_D
	spec.rock_color = PlazaData.STONE_D
	spec.flower_colors = PlazaData.FLOWER_COLORS_D
	spec.grass_colors = PlazaData.GRASS_COLORS_D
	spec.ground_dirt = PlazaData.GROUND_DIRT_D
	spec.ground_greens = PlazaData.GROUND_GREENS_D
	spec.style = PlazaStyle.new()


## B, arrumada (ART-6a): árvores redondas e baixas em duplas, poucas rochas, flores azuis e brancas, grama curta e uniforme.
static func _plant_b(spec: Spec) -> void:
	spec.plants_in_footprint = true
	spec.tree_shapes = PlazaData.TREE_SHAPES_B
	spec.tree_forms = PlazaData.TREE_FORMS_B
	spec.tree_greens = PlazaData.TREE_GREENS_B
	spec.tree_spots = PlazaData.TREE_SPOTS_B
	spec.rock_spots = PlazaData.ROCK_SPOTS_B
	spec.rock_size = PlazaData.ROCK_SIZE_B
	spec.rock_color = PlazaData.STONE_B
	spec.flower_colors = PlazaData.FLOWER_COLORS_B
	spec.flowers_per_color = PlazaData.FLOWERS_B
	spec.grass_count = PlazaData.GRASS_COUNT_B
	spec.grass_size = PlazaData.GRASS_SIZE_B
	spec.grass_colors = PlazaData.GRASS_COLORS_B
	spec.scatter_half_m = PlazaData.SCATTER_HALF_PLANTED_M


## C, rústica (ART-6a): coníferas e árvore grande, mais rochas e arbustos, flores raras em ocre, grama alta e seca.
static func _plant_c(spec: Spec) -> void:
	spec.plants_in_footprint = true
	spec.tree_shapes = PlazaData.TREE_SHAPES_C
	spec.tree_forms = PlazaData.TREE_FORMS_C
	spec.tree_greens = PlazaData.TREE_GREENS_C
	spec.tree_spots = PlazaData.TREE_SPOTS_C
	spec.rock_spots = PlazaData.ROCK_SPOTS_C
	spec.rock_size = PlazaData.ROCK_SIZE_C
	spec.rock_color = PlazaData.STONE_C
	spec.bush_spots = PlazaData.BUSH_SPOTS_C
	spec.flower_colors = PlazaData.FLOWER_COLORS_C
	spec.flowers_per_color = PlazaData.FLOWERS_C
	spec.grass_count = PlazaData.GRASS_COUNT_C
	spec.grass_size = PlazaData.GRASS_SIZE_C
	spec.grass_colors = PlazaData.GRASS_COLORS_C
	spec.scatter_half_m = PlazaData.SCATTER_HALF_PLANTED_M


## Barracas nos lugares `spots` (x, z), todas viradas para o centro da praça: (x, z, giro em rad).
static func facing_center(spots: Array[Vector2]) -> Array[Vector3]:
	var poses: Array[Vector3] = []
	for spot: Vector2 in spots:
		poses.append(Vector3(spot.x, spot.y, atan2(-spot.x, -spot.y)))
	return poses
