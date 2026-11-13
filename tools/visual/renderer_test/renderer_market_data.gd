class_name RendererMarketData
extends RefCounted
## Dados da praça de mercado procedural (cerca de 30 x 30 m) da cena de teste de renderizadores (ARTE-F0): contagens, lugares, medidas, paleta e canais de hash. Só constantes, sem lógica: os componentes de montagem (materiais, chão e estruturas) leem daqui, e o teste e o resumo da cena leem as contagens. Formas e lugares são [HIP] de composição, a calibrar olhando a cena.

## Contagens da cena (o teste e o resumo usam estas constantes).
const GROUND_HALF_M: int = 18
const GRASS_COUNT: int = 6000
const FLOWERS_PER_COLOR: int = 240
const TREE_COUNT: int = 12
const ROCK_COUNT: int = 8
const FLAGS_PER_STRING: int = 14
const STRIPS_PER_STALL: int = 9
const WELL_STONES: int = 8
const BLADES_PER_TUFT: int = 3
const SCATTER_ATTEMPTS: int = 6
const SCATTER_KEY_STRIDE: int = 100000
## Lugares (x, z em metros; as casas levam o giro em rad no terceiro valor). Os postes estão em ordem de laço: as bandeirolas ligam cada um ao seguinte.
const STALL_SPOTS: Array[Vector2] = [Vector2(-9.5, -2.0), Vector2(-5.5, -4.8), Vector2(0.0, -6.0), Vector2(5.5, -4.8), Vector2(9.5, -2.0)]
const LAMP_SPOTS: Array[Vector2] = [Vector2(-11.0, 9.0), Vector2(11.0, 9.0), Vector2(11.0, -7.0), Vector2(-11.0, -7.0)]
const TORCH_SPOTS: Array[Vector2] = [Vector2(-2.5, 7.0), Vector2(2.5, 7.0), Vector2(3.2, -2.0)]
const HOUSE_SPOTS: Array[Vector3] = [Vector3(-10.5, -11.5, 0.08), Vector3(0.5, -12.0, -0.05), Vector3(10.5, -11.5, 0.1)]
## Adereços de cada barraca: 0 = caixote, 1 = barril, 2 = saco (2 caixotes, 1 barril e 2 sacos por barraca).
const PROP_KINDS: Array[int] = [0, 0, 1, 2, 2]
const PROP_NAMES: Array[String] = ["Crate", "Barrel", "Sack"]
## Árvores de cones empilhados, 3 variações: (níveis de copa, raio da base, altura de cada nível).
const TREE_VARIANTS: Array[Vector3] = [Vector3(4.0, 1.5, 1.6), Vector3(3.0, 1.9, 1.9), Vector3(2.0, 2.3, 2.3)]
const TREE_RADII_M: Vector2 = Vector2(16.3, 17.4)
const ROCK_RADII_M: Vector2 = Vector2(10.5, 16.5)
## Arco das rochas (rad): só a metade da frente e as laterais, longe das casas do fundo.
const ROCK_ARC: Vector2 = Vector2(-0.47, 3.61)
## Medidas em metros [HIP].
const LAMP_HEIGHT_M: float = 5.2
const TORCH_HEIGHT_M: float = 1.8
const LAMP_RANGE_M: float = 7.5
const TORCH_RANGE_M: float = 5.0
const STALL_POST_M: float = 2.4
const CANOPY_RADIUS_M: float = 2.8
const CANOPY_RISE_M: float = 0.8
const FLAG_DROP_M: float = 0.55
const CATENARY_PARAM_M: float = 60.0
const WELL_RADIUS_M: float = 1.05
const HOUSE_WALL_M: float = 3.4
const HOUSE_ROOF_M: float = 1.7
const HOUSE_DEPTH_M: float = 4.6
const HOUSE_FOUNDATION_M: float = 0.8
const TRUNK_HEIGHT_M: float = 1.4
const FLOWER_STEM_M: float = 0.33
## Relevo suave (plano perto do poço), caminho de terra sinuoso de norte a sul e clareira de terra em volta do poço.
const RELIEF_AMPLITUDE_M: float = 0.45
const RELIEF_FLAT_RADIUS_M: float = 7.0
const RELIEF_RAMP_M: float = 6.0
const PATH_SWAY_M: float = 3.0
const PATH_WAVE: float = 0.18
const PATH_HALF_WIDTH_M: float = 1.6
const PATH_EDGE_M: float = 1.8
const PLAZA_RADIUS_M: float = 9.0
const GROUND_FLOOR_M: float = -50.0
## A grama some onde o chão é caminho de terra: a partir deste desgaste ela vai encolhendo.
const SCATTER_FADE_FROM: float = 0.4
## Paleta do guia visual (docs/arte/GUIA_VISUAL.md): ocre #B09050, marrons #907030 e #705030, oliva #909030, emissivos #FFB347, #FF9A3C e #3FE0E0.
const DIRT: Color = Color("B09050")
const DIRT_DARK: Color = Color("907030")
const GRASS: Color = Color("909030")
const GRASS_DARK: Color = Color("707028")
const WOOD: Color = Color("705030")
const WOOD_LIGHT: Color = Color("907030")
const STONE: Color = Color("8A8678")
const SACK: Color = Color("C8B078")
const WATER: Color = Color("2A3A48")
const TRUNK: Color = Color("5A3C28")
const LAMP_COLOR: Color = Color("FFB347")
const TORCH_COLOR: Color = Color("FF9A3C")
const CYAN: Color = Color("3FE0E0")
const GRASS_LOW: Color = Color("586020")
const GRASS_HIGH: Color = Color("A0A838")
const FLOWER_STEM: Color = Color("5A7A30")
const FLOWER_COLORS: Array[Color] = [Color("F0E8D0"), Color("E8C040"), Color("D060A0")]
const CLOTH_COLORS: Array[Color] = [Color("C04030"), Color("D88030"), Color("D0A030"), Color("A03858"), Color("3C7088")]
const WALL_COLORS: Array[Color] = [Color("C8B088"), Color("B89868"), Color("D0C0A0")]
const ROOF_COLORS: Array[Color] = [Color("503050"), Color("705030"), Color("A04830")]
const TREE_GREENS: Array[Color] = [Color("587838"), Color("48683A"), Color("688840")]
const SURFACE_ROUGHNESS: float = 0.85
const RIM_STRENGTH: float = 0.2
## Cada canal é uma sequência independente do hash (RendererMeshKit.unit). ROCK_RADIUS e TREE_RADIUS vêm logo depois do ângulo: `_ring_spot` usa canal e canal + 1.
enum Channel { PATCH, DIRT, GRASS, PROP_X, PROP_Z, PROP_YAW, PROP_SCALE, STRIP, HOUSE, STONE, TREE_ANGLE, TREE_RADIUS, TREE_YAW, TREE_SCALE, ROCK_ANGLE, ROCK_RADIUS, ROCK_SIZE, ROCK_YAW, SCATTER_X, SCATTER_Z, SCATTER_ACCEPT, SCATTER_SIZE, SCATTER_YAW }
## Grama e flores: lâmina de 5 pontos (3 triângulos) e quatro diagonais do chão alternadas.
const BLADE_POINTS: PackedVector3Array = [Vector3(-0.04, 0.0, 0.0), Vector3(0.04, 0.0, 0.0), Vector3(-0.025, 0.18, 0.0), Vector3(0.025, 0.18, 0.0), Vector3(0.0, 0.38, 0.03)]
const BLADE_INDICES: PackedInt32Array = [0, 1, 3, 0, 3, 2, 2, 3, 4]
const DIAGONAL_A: PackedInt32Array = [0, 1, 2, 0, 2, 3]
const DIAGONAL_B: PackedInt32Array = [0, 1, 3, 1, 2, 3]
