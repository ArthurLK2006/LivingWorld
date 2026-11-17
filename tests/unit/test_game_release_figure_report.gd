extends GutTest
## ART-12, 7c-1: o texto do relatório do medidor de quadros sobre a figura (tests/soak/game_release/figure_report.gd), sem janela, nó nem relógio: a linha da área (vazia, inválida, com figura), a
## carga à parte, as figuras ativas e os AVISOS (0 figuras, NPC sem corpo, cápsula, NPC que não andou no POVOADO). Mais uma guarda de TEXTO do script tests/soak/run_game_release, que não roda
## em teste (exige janela): a cópia de art_samples/ nasce DESLIGADA e a opção só aceita 0 ou 1.

const SCRIPT_PATH: String = "res://tests/soak/run_game_release"
const NPC: int = 37


## O que o medidor viu: `figures` corpos com figura, `area_bodies` corpos de NPCs da área (o NPC 37 se houve algum) e se algum andou.
func _seen(figures: int, area_bodies: int, walked: bool) -> FigureReport.Seen:
	var seen: FigureReport.Seen = FigureReport.Seen.new()
	seen.record(figures, area_bodies, NPC if area_bodies > 0 else IdGenerator.NO_ID, walked)
	return seen


func test_the_area_line_tells_which_round_this_is() -> void:
	assert_eq(FigureReport.area_line(true, PackedStringArray(), ""), "figuras: nenhuma (a área local está vazia; o jogo roda só com cápsulas)")
	var with_figure: String = FigureReport.area_line(false, PackedStringArray(["ice_warrior"]), "")
	assert_string_contains(with_figure, "a figura 'ice_warrior'")
	assert_string_contains(with_figure, "DEC-119 (média de 60 fps ou mais e nenhum quadro acima de 33 ms)")
	assert_string_contains(with_figure, "o delta de UMA figura é só informativo")
	assert_string_contains(FigureReport.area_line(true, PackedStringArray(), "campo desconhecido"), "INVÁLIDA e o jogo roda só com cápsulas: campo desconhecido")


func test_the_header_lists_the_scene_load_first_and_the_area_second() -> void:
	var lines: PackedStringArray = FigureReport.header_lines(FigureReport.load_line(12.34, 56.78), true, PackedStringArray(), "")
	assert_eq(lines.size(), 2)
	assert_eq(lines[0], "carga da cena principal (fora das seções do quadro; o preparo da figura acontece aqui): ler o arquivo 12.3 ms, instanciar e adicionar 56.8 ms")
	assert_eq(lines[1], FigureReport.area_line(true, PackedStringArray(), ""))


func test_seen_keeps_the_maximum_the_last_look_the_npc_and_whether_it_walked() -> void:
	var seen: FigureReport.Seen = FigureReport.Seen.new()
	seen.record(1, 1, NPC, true)
	seen.record(0, 0, IdGenerator.NO_ID, false)
	assert_eq([seen.max_figures, seen.last_figures, seen.area_bodies, seen.npc_id, seen.walked], [1, 0, 1, NPC, true], "O máximo fica, o fim é a última olhada, o NPC não se apaga e andar uma vez basta.")


func test_one_figure_that_walks_prints_the_active_line_and_no_warning() -> void:
	var lines: PackedStringArray = FigureReport.summary_lines(true, true, 38, _seen(1, 1, true))
	assert_eq(lines, PackedStringArray(["  figuras ativas: máximo 1, no fim 1, de no máximo 38 corpos; NPC da figura: 37"]))


func test_the_active_line_shows_the_maximum_and_the_last_look_apart() -> void:
	var seen: FigureReport.Seen = _seen(1, 1, true)
	seen.record(0, 1, NPC, true)
	assert_eq(FigureReport.summary_lines(true, false, 7, seen)[0], "  figuras ativas: máximo 1, no fim 0, de no máximo 7 corpos; NPC da figura: 37", "A figura saiu de S0 no fim: o máximo continua 1 e o fim é 0.")


func test_a_round_without_figure_in_the_area_prints_nothing_more() -> void:
	assert_eq(FigureReport.summary_lines(false, true, 38, _seen(0, 0, false)).size(), 0, "Área vazia: nenhuma linha, nem aviso de 0 figuras.")


func test_zero_figures_with_a_figure_in_the_area_warns_and_says_the_npc_had_no_body() -> void:
	var lines: PackedStringArray = FigureReport.summary_lines(true, false, 12, _seen(0, 0, false))
	assert_eq(lines.size(), 2)
	assert_eq(lines[0], "  figuras ativas: máximo 0, no fim 0, de no máximo 12 corpos; o NPC da figura não teve corpo")
	assert_eq(lines[1], FigureReport.WARN_NO_FIGURE)


func test_the_settlement_warns_when_the_figure_npc_had_no_body() -> void:
	assert_eq(FigureReport.warnings(true, _seen(0, 0, false)), PackedStringArray([FigureReport.WARN_NO_BODY_SETTLEMENT]))


func test_a_body_without_figure_warns_that_it_is_a_capsule() -> void:
	assert_eq(FigureReport.warnings(true, _seen(0, 1, true)), PackedStringArray([FigureReport.WARN_CAPSULE]), "O corpo andou, mas é cápsula: o aviso é o da cápsula.")


func test_the_settlement_warns_when_the_figure_never_walked_and_other_trials_do_not() -> void:
	assert_eq(FigureReport.warnings(true, _seen(1, 1, false)), PackedStringArray([FigureReport.WARN_NOT_WALKING]))
	assert_eq(FigureReport.warnings(false, _seen(1, 1, false)).size(), 0, "Fora do POVOADO a figura parada é normal.")
	assert_eq(FigureReport.warnings(true, _seen(1, 1, true)).size(), 0, "Andou: nada a avisar.")


func test_the_art_samples_copy_is_off_by_default_and_the_option_only_takes_zero_or_one() -> void:
	var script: String = FileAccess.get_file_as_string(SCRIPT_PATH)
	assert_string_contains(script, "LW_ART_SAMPLES=${LW_ART_SAMPLES:-0}")
	assert_string_contains(script, "case \"$LW_ART_SAMPLES\" in 0|1) ;; *) fail")
	assert_string_contains(script, "if [ \"$LW_ART_SAMPLES\" = 1 ]; then")
