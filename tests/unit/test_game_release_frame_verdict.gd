extends GutTest
## ART-12, 7c-1b: o veredito da DEC-119 do medidor de quadros (tests/soak/game_release/frame_verdict.gd): média de 60 fps ou mais E nenhum quadro acima de 33 ms, sem flexibilizar; o ensaio CURTO só valida o instrumento.

const NODE_SCRIPT_PATH: String = "res://tests/soak/game_release/game_release_node.gd"


func test_it_passes_with_60_fps_or_more_and_no_frame_above_33_ms() -> void:
	assert_string_contains(FrameVerdict.line(16.0, 0, 0.0), "VEREDITO DEC-119: PASSA (média 62.5 fps, 0 quadros acima de 33 ms")


func test_it_fails_when_the_average_is_below_60_fps() -> void:
	assert_string_contains(FrameVerdict.line(16.7, 0, 0.0), "FALHA (média 59.9 fps", "16,7 ms são 59,9 fps: a régua é 60 fps, não o orçamento de 16,7 ms.")


func test_it_fails_with_one_frame_above_33_ms_even_with_a_great_average() -> void:
	assert_string_contains(FrameVerdict.line(8.0, 1, 0.0), "FALHA (média 125.0 fps, 1 quadros acima de 33 ms")


func test_a_short_trial_only_validates_the_instrument_and_gives_no_verdict() -> void:
	var line: String = FrameVerdict.line(8.0, 0, 10.0)
	assert_string_contains(line, "VALIDAÇÃO DO INSTRUMENTO: sem veredito DEC-119 (ensaio CURTO de 10 s")
	assert_false(line.contains("VEREDITO"), "Nem passa nem falha: sem veredito.")


## 1000 / ms NUNCA dá exatamente 60.0 num float (o ms de 60 fps, 16,666..., não existe: os dois floats vizinhos dão 60.00000000000001 e 59.99999999999999): o par vizinho fixa a régua "60 fps ou mais" no menor passo possível.
func test_the_60_fps_boundary_passes_at_the_float_just_above_and_fails_just_below() -> void:
	assert_string_contains(FrameVerdict.line(16.666666666666664, 0, 0.0), "VEREDITO DEC-119: PASSA (média 60.0 fps", "O float logo ACIMA de 60 fps passa: 60 fps ou mais.")
	assert_string_contains(FrameVerdict.line(16.666666666666668, 0, 0.0), "VEREDITO DEC-119: FALHA (média 60.0 fps", "O float logo ABAIXO de 60 fps falha, mesmo que a linha arredonde para 60.0.")


func test_59_99_fps_fails_and_60_01_passes_even_though_the_line_rounds_both_to_60_0() -> void:
	assert_string_contains(FrameVerdict.line(1000.0 / 59.99, 0, 0.0), "FALHA (média 60.0 fps", "59,99 fps é abaixo de 60: FALHA (a linha mostra uma casa decimal e arredonda para 60.0).")
	assert_string_contains(FrameVerdict.line(1000.0 / 60.01, 0, 0.0), "PASSA (média 60.0 fps", "60,01 fps passa.")


## A DEC-119 diz "nenhum quadro ACIMA de 33 ms": o veredito só recebe a CONTAGEM dos quadros acima do limite (quem conta é o nó do medidor, que exige janela), então um quadro de EXATAMENTE 33,0 ms não entra nela.
## Guarda de TEXTO do nó (como a do tests/unit/test_game_release_figure_report.gd): o limite é 33.0 e a contagem é estritamente maior (">"), nunca ">=".
func test_a_frame_of_exactly_33_ms_is_not_counted_as_above_the_limit() -> void:
	var node_script: String = FileAccess.get_file_as_string(NODE_SCRIPT_PATH)
	assert_string_contains(node_script, "const BUDGET_30_HZ_MS: float = 33.0")
	assert_string_contains(node_script, "if counted[index] > BUDGET_30_HZ_MS:", "Só o quadro ACIMA de 33 ms conta: '>' e nunca '>='.")
	assert_false(node_script.contains("counted[index] >= BUDGET_30_HZ_MS"), "33,0 ms exatos não são 'acima de 33 ms'.")
	assert_string_contains(FrameVerdict.line(16.0, 0, 0.0), "PASSA (média 62.5 fps, 0 quadros acima de 33 ms", "Com 0 quadros acima do limite (o de exatamente 33,0 ms não conta) o veredito passa.")
