extends SceneTree
## ART-9c, ferramenta de arte (protótipo isolado): recolore a paleta do Fantasy Town Kit 2.0 da Kenney (CC0 permite modificar). A textura de 512 x 512 é uma grade de PARES de colunas de 64 px (32 px de cor chapada e 32 px do mesmo tom em gradiente vertical, do claro ao escuro), em três faixas de 128 px a partir de y = 128; os 23 pares estão em NEW_COLORS na ordem de leitura (faixa, coluna). Cada pixel de um par vira a cor nova vezes a razão de luminância que ele tinha sobre a cor chapada original: o gradiente (o sombreamento) de cada coluna fica e só o tom muda; a sombra ainda ganha um pouco de saturação. Lê a original (variation-a.original.png, nunca alterada) e grava a textura que os GLB usam (glb/Textures/colormap.png). Uso, sem janela: `godot --headless --path . --script res://tools/visual/inhabitants_demo/recolor_kenney_palette.gd` e depois `godot --headless --path . --import`. As cores são [HIP] de arte, a calibrar olhando a vila de teste.

const ORIGINAL_PATH: String = "res://art_samples/kenney_fantasy_town/variation-a.original.png"
const OUTPUT_PATH: String = "res://art_samples/kenney_fantasy_town/glb/Textures/colormap.png"
const PAIR_WIDTH_PX: int = 64
const FLAT_PROBE_PX: int = 2
const FIRST_BAND_Y: int = 128
const BAND_HEIGHT_PX: int = 128
const PAIRS_PER_BAND: Array[int] = [7, 8, 8]
const SHADOW_SATURATION: float = 0.25
const LUMA: Vector3 = Vector3(0.2126, 0.7152, 0.0722)
## Cor nova do tom chapado de cada par, na ordem de leitura: par 15 = telhado e toldo vermelho-terracota, 16 = telhado verde-azulado, 18 = árvores e sebe (verde-floresta), 19 e 20 = madeira clara e escura, 8 = reboco, rocha e calçada (bege-cinza quente), 22 = pedra escura. A luz da praça clareia as cores cerca de 1,3 vez, então os valores são mais escuros do que o resultado que se quer ver.
const NEW_COLORS: Array[Color] = [
	Color("A87A22"), Color("98441E"), Color("3B5870"), Color("2D465C"), Color("9DB6BC"), Color("6E2A2C"), Color("B89678"),
	Color("3A332E"), Color("8A8173"), Color("D8D0BC"), Color("98532F"), Color("6E3C25"), Color("B88A6A"), Color("C9B68F"), Color("7C2F2D"),
	Color("9C3524"), Color("2B5F5B"), Color("B08A4E"), Color("496A2B"), Color("80552F"), Color("5E3820"), Color("2C2622"), Color("6E655A"),
]


func _init() -> void:
	var image: Image = Image.load_from_file(ORIGINAL_PATH)
	if image == null or image.is_empty():
		push_error("Sem a original: %s" % ORIGINAL_PATH)
		quit(1)
		return
	image.convert(Image.FORMAT_RGBA8)
	var pair: int = 0
	for band: int in PAIRS_PER_BAND.size():
		for column: int in PAIRS_PER_BAND[band]:
			var area: Rect2i = Rect2i(column * PAIR_WIDTH_PX, FIRST_BAND_Y + band * BAND_HEIGHT_PX, PAIR_WIDTH_PX, BAND_HEIGHT_PX)
			print("par %2d: %s -> %s" % [pair, _recolor(image, area, NEW_COLORS[pair]).to_html(false), NEW_COLORS[pair].to_html(false)])
			pair += 1
	var error: int = image.save_png(OUTPUT_PATH)
	if error != OK:
		push_error("Não gravou %s (erro %d)" % [OUTPUT_PATH, error])
	quit(0 if error == OK else 1)


## Recolore o par em `area` para o tom `target` e devolve a cor chapada original.
func _recolor(image: Image, area: Rect2i, target: Color) -> Color:
	var flat_color: Color = image.get_pixel(area.position.x + FLAT_PROBE_PX, area.position.y + FLAT_PROBE_PX)
	var flat: float = _luma(flat_color)
	for y: int in range(area.position.y, area.end.y):
		for x: int in range(area.position.x, area.end.x):
			var ratio: float = _luma(image.get_pixel(x, y)) / flat
			var color: Color = Color(minf(target.r * ratio, 1.0), minf(target.g * ratio, 1.0), minf(target.b * ratio, 1.0), 1.0)
			if ratio < 1.0:
				color.s = minf(color.s * (1.0 + SHADOW_SATURATION * (1.0 - ratio)), 1.0)
			image.set_pixel(x, y, color)
	return flat_color


func _luma(color: Color) -> float:
	return color.r * LUMA.x + color.g * LUMA.y + color.b * LUMA.z
