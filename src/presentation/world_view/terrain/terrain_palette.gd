class_name TerrainPalette
extends RefCounted
## Cor de cada tipo de superfície do terreno (cores planas do blockout). Mapeia o id de CONTEÚDO de
## data/world/surface_types.json para a cor que a apresentação desenha. Os valores são [HIP]: Arthur ajusta
## olhando a tela (LW-038, decisão D7), não são requisitos.

const GRASS_COLOR: Color = Color(0.36, 0.58, 0.30)
const PATH_COLOR: Color = Color(0.62, 0.52, 0.38)
const ROCK_COLOR: Color = Color(0.50, 0.50, 0.52)
## Magenta de propósito: superfície sem cor definida (ou consulta que falhou) tem de aparecer na tela.
const UNKNOWN_COLOR: Color = Color(1.0, 0.0, 1.0)
const COLORS_BY_SURFACE_ID: Dictionary[String, Color] = {
	"grass": GRASS_COLOR,
	"path": PATH_COLOR,
	"rock": ROCK_COLOR,
}


static func color_for(surface_id: String) -> Color:
	var color: Color = COLORS_BY_SURFACE_ID.get(surface_id, UNKNOWN_COLOR)
	return color
