class_name GameCaptureReport
extends RefCounted
## Resumo da captura do jogo real (CAP, resumo.txt): o ambiente, as opções, a tabela de medidas do modo automático da demonstração de renderizadores (RendererAutoRun) e uma linha por captura, mais a medida de cor da imagem. Peças puras, sem janela.


## Texto do resumo.txt: `environment` é a linha do renderer e da placa (lida do motor por quem chama), `window` o tamanho da janela.
static func text(environment: String, window: Vector2i, options: GameCaptureOptions, shots: Array[RendererAutoRun.Shot]) -> String:
	var spot_labels: PackedStringArray = PackedStringArray()
	for spot: GameCaptureOptions.Spot in options.spots:
		spot_labels.append(spot.label())
	var hour_labels: PackedStringArray = PackedStringArray()
	for hour: float in options.hours:
		hour_labels.append(GameCaptureOptions.hour_label(hour))
	var lines: Array[String] = [environment]
	lines.append("janela: %s | vsync: desligado | quadros por captura: %d de acomodação e %d medidos" % [window, RendererAutoRun.SETTLE_FRAMES, RendererAutoRun.MEASURE_FRAMES])
	lines.append("jogo real | locais: %s | horas: %s | câmeras: %s" % [", ".join(spot_labels), ", ".join(hour_labels), ", ".join(PackedStringArray(options.cameras))])
	lines.append(RendererAutoRun.TABLE_HEADER)
	for shot: RendererAutoRun.Shot in shots:
		lines.append(shot.to_line())
	return "\n".join(lines) + "\n"


## Saturação (x) e brilho (y) médios da imagem, medidos numa cópia reduzida como no modo automático da demonstração (alvo do dia: 0,44 e 0,59).
static func color_means(image: Image) -> Vector2:
	var sample: Image = image.duplicate() as Image
	sample.resize(RendererAutoRun.COLOR_SAMPLE.x, RendererAutoRun.COLOR_SAMPLE.y, Image.INTERPOLATE_BILINEAR)
	var saturation_sum: float = 0.0
	var brightness_sum: float = 0.0
	for y: int in sample.get_height():
		for x: int in sample.get_width():
			var pixel: Color = sample.get_pixel(x, y)
			saturation_sum += pixel.s
			brightness_sum += pixel.v
	return Vector2(saturation_sum, brightness_sum) / float(sample.get_width() * sample.get_height())
