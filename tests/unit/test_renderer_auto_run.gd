extends GutTest

## ARTE-F0, modo automático da cena de teste (sem renderizar): argumentos da linha de comando e as peças do resumo (cabeçalho, linha da tabela, medição de cor e gravação). A captura de imagem só existe com janela e não é testada aqui.
const SCENE_PATH: String = "res://scenes/demo/renderer_test.tscn"


func _build() -> RendererTestScene:
	var scene: RendererTestScene = (load(SCENE_PATH) as PackedScene).instantiate()
	add_child_autofree(scene)
	return scene


func test_auto_mode_arguments() -> void:
	var args: PackedStringArray = PackedStringArray(["--auto", "--out=/tmp/saida"])
	assert_true(RendererAutoRun.is_requested(args), "--auto")
	assert_eq(RendererAutoRun.out_dir(args), "/tmp/saida", "--out=<pasta>")
	assert_false(RendererAutoRun.is_requested(PackedStringArray()), "sem argumentos a cena fica interativa")
	assert_eq(RendererAutoRun.out_dir(PackedStringArray(["--auto"])), "", "sem --out a pasta vem vazia")


func test_auto_mode_report_pieces() -> void:
	var scene: RendererTestScene = _build()
	var auto_run: RendererAutoRun = RendererAutoRun.new()
	var header: Array[String] = auto_run._header(scene)
	assert_eq(header.size(), 5, "cabeçalho do resumo")
	assert_string_contains(header[0], "renderer: %s" % scene.rendering_method)
	assert_string_contains(header[2], "triângulos")
	assert_eq(header[4], RendererAutoRun.TABLE_HEADER, "tabela")
	var shot: RendererAutoRun.Shot = RendererAutoRun.Shot.new()
	shot.label = "day_near"
	shot.fps = 123.456
	assert_string_contains(shot.to_line(), "day_near | 123.5 | 0.0 | 0 | 0 | 0 | 0.0 | 0.000 | 0.000 | ")
	var image: Image = Image.create(8, 8, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.8, 0.4, 0.2))
	auto_run._measure_color(image, shot)
	assert_almost_eq(shot.saturation, 0.75, 0.02, "saturação de uma cor lisa")
	assert_almost_eq(shot.brightness, 0.8, 0.02, "brilho de uma cor lisa")
	var directory: DirAccess = DirAccess.create_temp("lw_arte_f0")
	var summary: String = directory.get_current_dir().path_join(RendererAutoRun.SUMMARY_FILE)
	auto_run._write(summary, ["a", "b"])
	assert_eq(FileAccess.get_file_as_string(summary), "a\nb\n", "resumo gravado")
	DirAccess.remove_absolute(summary)
	DirAccess.remove_absolute(directory.get_current_dir())
