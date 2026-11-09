extends GutTest
## LW-072g: o acumulador de custo por seção do quadro (tests/soak/game_release/frame_sections.gd), sem janela e sem relógio. Contas à mão: soma dentro do quadro, zera
## entre quadros, o "resto do quadro" é a duração menos as seções (nunca negativo), a média e o pior ignoram os primeiros quadros pedidos e a linha sai como o relatório
## precisa.

const TOLERANCE: float = 0.0001
const VIEW: String = "NpcBodiesView"
const DRIVER: String = "NpcBodyDriver"


## Três quadros: (1) a view gasta 1,0 + 0,5 ms e o motorista 2,0 ms num quadro de 5 ms; (2) ninguém mede nada num quadro de 4 ms; (3) a view gasta 3,0 ms num quadro de 2 ms.
func _three_frames() -> FrameSections:
	var sections: FrameSections = FrameSections.new()
	sections.add(VIEW, 1000)
	sections.add(VIEW, 500)
	sections.add(DRIVER, 2000)
	sections.end_frame(5.0)
	sections.end_frame(4.0)
	sections.add(VIEW, 3000)
	sections.end_frame(2.0)
	return sections


func test_the_sections_add_up_inside_a_frame_and_the_rest_is_what_is_left() -> void:
	var sections: FrameSections = _three_frames()
	assert_eq(sections.frame_count(), 3)
	assert_almost_eq(sections.worst_ms(VIEW, 0), 3.0, TOLERANCE, "1,0 + 0,5 no primeiro quadro e 3,0 no terceiro: o pior é 3,0.")
	assert_almost_eq(sections.mean_ms(VIEW, 0), 1.5, TOLERANCE, "(1,5 + 0 + 3,0) / 3.")
	assert_almost_eq(sections.mean_ms(DRIVER, 0), 2.0 / 3.0, TOLERANCE)
	assert_almost_eq(sections.worst_ms(FrameSections.REST, 0), 4.0, TOLERANCE, "O quadro sem medida inteiro é resto.")
	assert_almost_eq(sections.mean_ms(FrameSections.REST, 0), (1.5 + 4.0 + 0.0) / 3.0, TOLERANCE, "5 - 3,5 = 1,5; 4 - 0; e 2 - 3 vira 0, nunca negativo.")


func test_what_was_added_is_zeroed_at_the_end_of_each_frame() -> void:
	var sections: FrameSections = FrameSections.new()
	sections.add(VIEW, 2000)
	sections.end_frame(3.0)
	sections.end_frame(3.0)
	assert_almost_eq(sections.worst_ms(VIEW, 1), 0.0, TOLERANCE, "O segundo quadro não herdou os 2,0 ms do primeiro.")
	assert_almost_eq(sections.mean_ms(FrameSections.REST, 1), 3.0, TOLERANCE)


func test_the_first_frames_can_be_skipped_and_an_empty_series_is_zero_not_an_error() -> void:
	var sections: FrameSections = _three_frames()
	assert_almost_eq(sections.mean_ms(VIEW, 1), 1.5, TOLERANCE, "Sem o primeiro quadro: (0 + 3,0) / 2.")
	assert_almost_eq(sections.worst_ms(DRIVER, 1), 0.0, TOLERANCE, "O motorista só gastou no primeiro quadro.")
	assert_eq([sections.mean_ms(VIEW, 3), sections.worst_ms(VIEW, 3), sections.mean_ms("não existe", 0)], [0.0, 0.0, 0.0], "Pular todos os quadros, ou uma seção que não existe, dá zero.")
	assert_eq(FrameSections.new().frame_count(), 0)


func test_the_report_line_lists_each_section_in_order_with_the_rest_last_and_reset_starts_over() -> void:
	var sections: FrameSections = _three_frames()
	assert_eq(sections.line(0), "  custo por seção, em ms por quadro (média / pior): NpcBodiesView 1.50 / 3.00 | NpcBodyDriver 0.67 / 2.00 | resto do quadro 1.83 / 4.00")
	sections.reset()
	assert_eq(sections.frame_count(), 0, "Depois do reset não sobra quadro.")
	sections.add(VIEW, 1000)
	sections.end_frame(2.0)
	assert_eq(sections.line(0), "  custo por seção, em ms por quadro (média / pior): NpcBodiesView 1.00 / 1.00 | NpcBodyDriver 0.00 / 0.00 | resto do quadro 1.00 / 1.00", "As seções já vistas continuam na linha, e o que estava aberto antes do reset não volta.")
