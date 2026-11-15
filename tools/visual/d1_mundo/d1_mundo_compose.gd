extends SceneTree
## D1-B (só imagens, roda com --headless): para cada PNG da pasta --a que também existe na pasta --b, grava em --out a imagem lado a lado (esquerda = a, direita = b), cada metade reduzida a --w pixels de largura (padrão 960).
## Uso: godot --headless --path <projeto> -s res://tools/visual/d1_mundo/d1_mundo_compose.gd -- --a=<pasta> --b=<pasta> --out=<pasta> [--w=960]

const GAP_PX: int = 4
const SAMPLE_PX: Vector2i = Vector2i(160, 90)


func _initialize() -> void:
	var dir_a: String = ""
	var dir_b: String = ""
	var dir_out: String = ""
	var width: int = 960
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--a="):
			dir_a = argument.trim_prefix("--a=")
		elif argument.begins_with("--b="):
			dir_b = argument.trim_prefix("--b=")
		elif argument.begins_with("--out="):
			dir_out = argument.trim_prefix("--out=")
		elif argument.begins_with("--w="):
			width = int(argument.trim_prefix("--w="))
	if dir_a.is_empty() or dir_b.is_empty() or DirAccess.make_dir_recursive_absolute(dir_out) != OK:
		push_error("d1_mundo_compose: esperado --a=, --b= e --out=.")
		quit(1)
		return
	var written: int = 0
	for file_name: String in DirAccess.get_files_at(dir_a):
		if file_name.ends_with(".png") and FileAccess.file_exists(dir_b.path_join(file_name)):
			written += 1 if _compose(dir_a.path_join(file_name), dir_b.path_join(file_name), dir_out.path_join(file_name), width) else 0
	print("d1_mundo_compose: %d pares gravados em %s" % [written, dir_out])
	quit()


func _compose(path_a: String, path_b: String, path_out: String, width: int) -> bool:
	var image_a: Image = Image.load_from_file(path_a)
	var image_b: Image = Image.load_from_file(path_b)
	if image_a == null or image_b == null:
		return false
	var height: int = int(round(float(width) * float(image_a.get_height()) / float(image_a.get_width())))
	var mean_a: Vector2 = _mean(image_a)
	var mean_b: Vector2 = _mean(image_b)
	print("%s | saturação média (HSV) a %.3f, b %.3f | brilho médio a %.3f, b %.3f" % [path_out.get_file(), mean_a.x, mean_b.x, mean_a.y, mean_b.y])
	for image: Image in [image_a, image_b]:
		image.convert(Image.FORMAT_RGB8)
		image.resize(width, height, Image.INTERPOLATE_LANCZOS)
	var canvas: Image = Image.create(width * 2 + GAP_PX, height, false, Image.FORMAT_RGB8)
	canvas.fill(Color.WHITE)
	canvas.blit_rect(image_a, Rect2i(0, 0, width, height), Vector2i(0, 0))
	canvas.blit_rect(image_b, Rect2i(0, 0, width, height), Vector2i(width + GAP_PX, 0))
	return canvas.save_png(path_out) == OK


## Saturação e brilho médios (HSV) da imagem, de uma cópia reduzida a SAMPLE_PX (como o modo automático do renderer_test faz).
func _mean(image: Image) -> Vector2:
	var sample: Image = image.duplicate()
	sample.convert(Image.FORMAT_RGB8)
	sample.resize(SAMPLE_PX.x, SAMPLE_PX.y, Image.INTERPOLATE_BILINEAR)
	var total: Vector2 = Vector2.ZERO
	for y: int in SAMPLE_PX.y:
		for x: int in SAMPLE_PX.x:
			var pixel: Color = sample.get_pixel(x, y)
			total += Vector2(pixel.s, pixel.v)
	return total / float(SAMPLE_PX.x * SAMPLE_PX.y)
