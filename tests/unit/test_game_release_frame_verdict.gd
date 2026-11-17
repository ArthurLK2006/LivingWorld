extends GutTest
## ART-12, 7c-1b: o veredito da DEC-119 do medidor de quadros (tests/soak/game_release/frame_verdict.gd): média de 60 fps ou mais E nenhum quadro acima de 33 ms, sem flexibilizar; o ensaio CURTO só valida o instrumento.


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
