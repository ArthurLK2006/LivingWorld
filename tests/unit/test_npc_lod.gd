extends GutTest
## LW-069: o LOD lógico S1/S0 (NpcLod, LodReconstruction), sem janela e sem módulo: a lógica sozinha, com NpcState montados à mão. Os valores
## esperados estão ESCRITOS À MÃO a partir do contrato (docs/modules/npc.md, seção 6): entra a até 80 m do foco mais próximo (inclusive),
## sai só acima de 120 m, no máximo 50 em S0 (aqui, limites menores nos testes de vaga), desempate pelo ID menor. Contas em centímetros.
## Em S0 o NPC é medido pela posição do CORPO (relatos); em S1, pela posição lógica ou pela derivada da ação e da hora.

const ENTER_CM: int = 8000
const EXIT_CM: int = 12000
const FOCUS_ID: int = 1
const SECOND_FOCUS_ID: int = 2
const FOCUS: Vector3 = Vector3(1000.0, 10.0, 1000.0)
const FOCUS_CM: Vector2i = Vector2i(100000, 100000)
const NOW: int = 100
const S0: int = NpcLod.LEVEL_S0
const S1: int = NpcLod.LEVEL_S1

var _lod: NpcLod
var _npcs: Dictionary[int, NpcState] = {}


func before_each() -> void:
	_lod = NpcLod.new(LodParams.new(80, 120, 50))
	_npcs = {}
	assert_true(_lod.set_focus(FOCUS_ID, FOCUS).ok)


## NPC `npc_id` a `distance_cm` do foco, no eixo x.
func _add(npc_id: int, distance_cm: int) -> NpcState:
	var state: NpcState = NpcState.new(npc_id)
	state.x_cm = FOCUS_CM.x + distance_cm
	state.z_cm = FOCUS_CM.y
	_npcs[npc_id] = state
	return state


## Põe o NPC a `distance_cm` do foco do jeito que cada nível entende: em S0 o corpo relata a posição; em S1 muda a posição lógica.
func _move_to(npc_id: int, distance_cm: int) -> void:
	if _lod.level_of(npc_id) == S0:
		assert_true(_lod.report_position(npc_id, Vector2i(FOCUS_CM.x + distance_cm, FOCUS_CM.y)).ok)
	else:
		_npcs[npc_id].x_cm = FOCUS_CM.x + distance_cm


func _update(now_minutes: int = NOW) -> Array[NpcLod.Change]:
	return _lod.update(_npcs, now_minutes)


## Trocas em texto curto ("3:1>0" = NPC 3 foi de S1 para S0), para comparar de uma vez.
func _text_of(changes: Array[NpcLod.Change]) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for change: NpcLod.Change in changes:
		parts.append("%d:%d>%d" % [change.npc_id, change.from_level, change.to_level])
	return ",".join(parts)


## NPC em trânsito: sai de (1000, 2000) cm às 100 e chega ao destino às 200 (o `action_target_place_id` difere do `place_id`).
func _traveler() -> NpcState:
	var state: NpcState = NpcState.new(9)
	state.x_cm = 1000
	state.z_cm = 2000
	state.action_id = "go_to_place"
	state.action_target_place_id = "work_1"
	state.action_started_at = 100
	state.action_ends_at = 200
	state.action_serial = 4
	return state


# ---------------------------------------------------------------- níveis e histerese

func test_without_a_focus_everyone_stays_s1_and_nothing_changes() -> void:
	var bare: NpcLod = NpcLod.new(LodParams.new(80, 120, 50))
	_add(1, 0)
	assert_eq(_text_of(bare.update(_npcs, NOW)), "", "Sem foco, ninguém muda.")
	assert_eq(bare.level_of(1), S1)
	assert_eq(bare.s0_ids().size(), 0)
	assert_eq(_text_of(_update()), "1:1>0", "Com foco, o NPC em cima dele vira S0.")
	assert_true(_lod.clear_focus(FOCUS_ID).ok)
	assert_eq(_text_of(_update()), "1:0>1", "Sem foco de novo, todos voltam a S1.")
	assert_eq(_lod.level_of(1), S1)


func test_it_enters_at_exactly_the_enter_radius_and_not_one_centimeter_beyond() -> void:
	_add(1, ENTER_CM)
	_add(2, ENTER_CM + 1)
	assert_eq(_text_of(_update()), "1:1>0", "A 80,00 m exatos vale (inclusive); a 80,01 m não.")
	assert_eq(_lod.level_of(1), S0)
	assert_eq(_lod.level_of(2), S1)


func test_hysteresis_keeps_it_in_s0_up_to_exactly_the_exit_radius_and_it_never_enters_between_the_radii() -> void:
	_add(1, 7000)
	_add(2, 10000)
	assert_eq(_text_of(_update()), "1:1>0", "Entra a 70 m; o de 100 m (entre os raios) não entra.")
	_move_to(1, EXIT_CM)
	assert_eq(_text_of(_update()), "", "A 120,00 m exatos ainda é S0.")
	_move_to(1, EXIT_CM + 1)
	assert_eq(_text_of(_update()), "1:0>1", "A 120,01 m volta a S1.")
	_move_to(1, 10000)
	assert_eq(_text_of(_update()), "", "Entre os raios, quem saiu não volta sozinho.")
	_move_to(1, ENTER_CM)
	assert_eq(_text_of(_update()), "1:1>0", "Só volta ao chegar ao raio de entrada.")
	assert_eq(_lod.level_of(2), S1, "O que nunca esteve em S0 segue em S1 entre os raios.")


func test_an_npc_on_the_border_does_not_oscillate() -> void:
	_add(1, 7900)
	var changes: Array[NpcLod.Change] = _update()
	assert_eq(changes.size(), 1, "Entra uma vez.")
	for step: int in 10:
		_move_to(1, 8100 if step % 2 == 0 else 7900)
		changes.append_array(_update(NOW + step))
	assert_eq(changes.size(), 1, "Oscilar em volta do raio de entrada não gera mais nenhuma troca.")
	for step: int in 10:
		_move_to(1, 12100 if step % 2 == 0 else 11900)
		changes.append_array(_update(NOW + 20 + step))
	assert_eq(_text_of(changes), "1:1>0,1:0>1", "Em volta do raio de saída: sai uma vez e não volta, porque 119 m está entre os raios.")


func test_the_same_state_gives_no_new_change() -> void:
	_add(1, 1000)
	assert_eq(_text_of(_update()), "1:1>0")
	for step: int in 5:
		assert_eq(_text_of(_update(NOW + step)), "", "A troca sai uma vez só.")


# ---------------------------------------------------------------- vagas, vários focos, mortos

func test_max_s0_keeps_the_closest_and_breaks_ties_by_the_lowest_id() -> void:
	_lod = NpcLod.new(LodParams.new(80, 120, 3))
	assert_true(_lod.set_focus(FOCUS_ID, FOCUS).ok)
	for npc_id: int in [5, 3, 4, 2, 1]:
		_add(npc_id, 3000)
	assert_eq(_text_of(_update()), "1:1>0,2:1>0,3:1>0", "Cinco empatados a 30 m e três vagas: os de menor ID.")
	var first_three: Array[int] = [1, 2, 3]
	assert_eq(_lod.s0_ids(), first_three)
	_add(9, 1000)
	assert_eq(_text_of(_update()), "3:0>1,9:1>0", "O mais perto toma a vaga do último dos empatados (o de maior ID entre os que estavam).")
	var with_closest: Array[int] = [1, 2, 9]
	assert_eq(_lod.s0_ids(), with_closest)
	_npcs.erase(9)
	assert_eq(_text_of(_update()), "3:1>0,9:0>1", "Sem o mais perto, o 3 recupera a vaga.")
	assert_lte(_lod.s0_ids().size(), 3, "O limite vale o tempo todo.")


func test_several_foci_use_the_nearest_one_and_clearing_one_releases_only_its_npcs() -> void:
	assert_true(_lod.set_focus(SECOND_FOCUS_ID, Vector3(2000.0, 10.0, 1000.0)).ok)
	_add(1, 5000)
	var near_second: NpcState = NpcState.new(2)
	near_second.x_cm = 200000 + 6000
	near_second.z_cm = 100000
	_npcs[2] = near_second
	var far_from_both: NpcState = NpcState.new(3)
	far_from_both.x_cm = 150000
	far_from_both.z_cm = 100000
	_npcs[3] = far_from_both
	assert_eq(_text_of(_update()), "1:1>0,2:1>0", "Cada um entra pelo foco que está mais perto; o que está longe dos dois não entra.")
	assert_eq(_lod.focus_count(), 2)
	assert_true(_lod.clear_focus(FOCUS_ID).ok)
	assert_eq(_text_of(_update()), "1:0>1", "Tirar o primeiro foco só solta quem dependia dele.")
	assert_true(_lod.clear_focus(SECOND_FOCUS_ID).ok)
	assert_eq(_text_of(_update()), "2:0>1")
	assert_eq(_lod.focus_count(), 0)


func test_dead_and_removed_npcs_leave_s0_with_a_change_and_dead_ones_do_not_enter() -> void:
	var to_die: NpcState = _add(1, 1000)
	_add(2, 1000)
	var dead_from_start: NpcState = _add(3, 1000)
	dead_from_start.is_alive = false
	assert_eq(_text_of(_update()), "1:1>0,2:1>0", "Quem já nasceu morto não entra.")
	to_die.is_alive = false
	_npcs.erase(2)
	assert_eq(_text_of(_update()), "1:0>1,2:0>1", "Morto e removido saem de S0, com a troca.")
	assert_eq(_lod.s0_ids().size(), 0)


func test_the_same_input_gives_the_same_changes_and_levels() -> void:
	var other: NpcLod = NpcLod.new(LodParams.new(80, 120, 50))
	assert_true(other.set_focus(FOCUS_ID, FOCUS).ok)
	for npc_id: int in [4, 1, 3, 2]:
		_add(npc_id, 500 * npc_id)
	assert_eq(_text_of(other.update(_npcs, NOW)), _text_of(_update()))
	assert_eq(other.s0_ids(), _lod.s0_ids())


# ---------------------------------------------------------------- pedidos de foco e de relato

func test_focus_requests_refuse_bad_input_with_a_handled_error_and_change_nothing() -> void:
	for bad_id: int in [0, -1]:
		var refused: Result = _lod.set_focus(bad_id, FOCUS)
		assert_false(refused.ok)
		assert_eq(refused.code, NpcLod.CODE_INVALID_FOCUS)
		assert_string_contains(refused.message, "focus_id")
	for bad_position: Vector3 in [Vector3(NAN, 0.0, 0.0), Vector3(0.0, 0.0, INF), Vector3(-1.0, 0.0, 5.0), Vector3(5.0, 0.0, 1000000.0)]:
		assert_eq(_lod.set_focus(7, bad_position).code, NpcLod.CODE_INVALID_FOCUS, "Posição %s." % str(bad_position))
	assert_eq(_lod.focus_count(), 1, "Nenhum pedido recusado criou foco.")
	var unknown: Result = _lod.clear_focus(99)
	assert_eq(unknown.code, NpcLod.CODE_UNKNOWN_FOCUS)
	assert_string_contains(unknown.message, "99")
	assert_true(_lod.set_focus(FOCUS_ID, Vector3(1500.0, 0.0, 1500.0)).ok)
	assert_eq(_lod.focus_count(), 1, "Pôr o mesmo foco de novo só o move.")
	assert_true(_lod.set_focus(7, Vector3(0.0, 0.0, 0.0)).ok, "O canto do mapa vale.")


func test_without_valid_params_the_lod_is_off_and_says_why() -> void:
	var off: NpcLod = NpcLod.new()
	_add(1, 0)
	assert_eq(off.set_focus(FOCUS_ID, FOCUS).code, NpcLod.CODE_NOT_CONFIGURED)
	assert_eq(off.clear_focus(FOCUS_ID).code, NpcLod.CODE_NOT_CONFIGURED)
	assert_eq(_text_of(off.update(_npcs, NOW)), "")
	var invalid: Result = off.configure(LodParams.new(120, 80, 50))
	assert_eq(invalid.code, NpcLod.CODE_NOT_CONFIGURED)
	assert_string_contains(invalid.message, "precisa ser maior")
	assert_string_contains(off.set_focus(FOCUS_ID, FOCUS).message, "precisa ser maior", "O pedido seguinte repete o motivo.")
	assert_eq(off.configure(null).code, NpcLod.CODE_NOT_CONFIGURED)
	assert_true(off.configure(LodParams.new(80, 120, 50)).ok)
	assert_true(off.set_focus(FOCUS_ID, FOCUS).ok)


func test_a_body_report_moves_the_s0_position_and_is_refused_outside_s0_or_out_of_range() -> void:
	_add(1, 1000)
	_add(2, 20000)
	_update()
	assert_eq(_lod.position_of(1), Vector2i(FOCUS_CM.x + 1000, FOCUS_CM.y), "A posição do corpo nasce na do NPC (parado).")
	assert_true(_lod.report_position(1, Vector2i(123456, 654321)).ok)
	assert_eq(_lod.position_of(1), Vector2i(123456, 654321))
	assert_eq(_lod.report_position(2, Vector2i(1, 1)).code, NpcLod.CODE_NOT_IN_S0)
	assert_eq(_lod.position_of(2), LodReconstruction.NO_POSITION)
	for bad: Vector2i in [Vector2i(-1, 5), Vector2i(5, -1), Vector2i(NpcState.MAX_COORDINATE_CM + 1, 5)]:
		assert_eq(_lod.report_position(1, bad).code, NpcLod.CODE_INVALID_POSITION)
	assert_eq(_lod.position_of(1), Vector2i(123456, 654321), "Relato recusado não muda nada.")


# ---------------------------------------------------------------- preservação ao entrar e sair

func test_entering_and_leaving_without_a_report_keeps_the_npc_state_exactly_as_it_was() -> void:
	var state: NpcState = _add(1, 1000)
	state.settlement_id = "village_a"
	state.place_id = "home_a_1"
	state.action_id = "sleep"
	state.action_target_place_id = "home_a_1"
	state.action_started_at = 40
	state.action_ends_at = 520
	state.action_serial = 6
	var before: Dictionary = state.to_dict()
	assert_eq(_text_of(_update()), "1:1>0")
	assert_eq(state.to_dict(), before, "Entrar em S0 não mexe no estado: o nível não é dado do NPC.")
	assert_true(_lod.clear_focus(FOCUS_ID).ok)
	assert_eq(_text_of(_update()), "1:0>1")
	assert_eq(state.to_dict(), before, "Sair de S0 sem relato do corpo deixa ação, local, tempos e posição como estavam.")


func test_the_last_report_becomes_the_logical_position_on_leaving_and_the_action_goes_on() -> void:
	var state: NpcState = _add(1, 1000)
	state.place_id = "market_1"
	state.action_id = "talk"
	state.action_target_place_id = "market_1"
	state.action_started_at = 90
	state.action_ends_at = 120
	state.action_serial = 3
	_update()
	assert_true(_lod.report_position(1, Vector2i(FOCUS_CM.x + 30000, FOCUS_CM.y + 40)).ok)
	assert_true(_lod.clear_focus(FOCUS_ID).ok)
	assert_eq(_text_of(_update(110)), "1:0>1")
	assert_eq([state.x_cm, state.z_cm], [FOCUS_CM.x + 30000, FOCUS_CM.y + 40], "O último relato do corpo virou a posição lógica.")
	assert_eq([state.place_id, state.action_id, state.action_target_place_id, state.action_started_at, state.action_ends_at, state.action_serial], ["market_1", "talk", "market_1", 90, 120, 3], "Ação e local preservados; falta (fim - agora) = 10 minutos.")


# ---------------------------------------------------------------- reconstrução da posição

func test_the_position_is_the_logical_one_when_stopped_or_without_action_or_without_a_destination() -> void:
	var state: NpcState = _traveler()
	state.place_id = "work_1"
	assert_eq(LodReconstruction.position_at(state, 150, Vector2i(5000, 6000), 100), Vector2i(1000, 2000), "Já no local da ação: parado.")
	state.place_id = ""
	state.action_id = ""
	assert_eq(LodReconstruction.position_at(state, 150, Vector2i(5000, 6000), 100), Vector2i(1000, 2000), "Sem ação: parado.")
	state.action_id = "go_to_place"
	assert_eq(LodReconstruction.position_at(state, 150, LodReconstruction.NO_POSITION, 100), Vector2i(1000, 2000), "Destino desconhecido: a posição lógica, sem inventar caminho.")
	assert_false(LodReconstruction.is_in_transit(NpcState.new(5)))
	assert_true(LodReconstruction.is_in_transit(state))


func test_in_transit_the_position_is_interpolated_between_origin_and_destination_by_the_hour() -> void:
	var state: NpcState = _traveler()
	var destination: Vector2i = Vector2i(5001, 1000)
	assert_eq(LodReconstruction.position_at(state, 100, destination, 100), Vector2i(1000, 2000), "No começo: a origem.")
	assert_eq(LodReconstruction.position_at(state, 150, destination, 100), Vector2i(3000, 1500), "Na metade: 1000 + 4001/2 = 3000 (piso) e 2000 - 1000/2 = 1500.")
	assert_eq(LodReconstruction.position_at(state, 125, destination, 100), Vector2i(2000, 1750), "A 25%: 1000 + 4001/4 = 2000 e 2000 - 250 = 1750.")
	assert_eq(LodReconstruction.position_at(state, 200, destination, 100), destination, "No fim: o destino.")
	assert_eq(LodReconstruction.position_at(state, 900, destination, 100), destination, "Depois do fim: o destino.")
	assert_eq(LodReconstruction.position_at(state, 40, destination, 100), Vector2i(1000, 2000), "Antes do começo: a origem.")
	assert_eq(LodReconstruction.position_at(state, 150, Vector2i(1000 - 4001, 2000), 100), Vector2i(1000 - 2001, 2000), "Para o lado negativo o piso arredonda para baixo: -4001/2 = -2001.")


func test_a_leg_that_ends_before_it_starts_or_is_absurdly_long_is_handled_without_overflow() -> void:
	var state: NpcState = _traveler()
	state.action_ends_at = 100
	assert_eq(LodReconstruction.position_at(state, 100, Vector2i(5000, 6000), 100), Vector2i(5000, 6000), "Trecho de duração zero: já chegou.")
	state.action_ends_at = 100 + LodReconstruction.MAX_LEG_MINUTES + 1
	assert_eq(LodReconstruction.position_at(state, 5000, Vector2i(5000, 6000), 100), Vector2i(1000, 2000), "Trecho absurdo: a posição lógica.")
	state.action_ends_at = 100 + LodReconstruction.MAX_LEG_MINUTES
	var far_destination: Vector2i = Vector2i(NpcState.MAX_COORDINATE_CM, NpcState.MAX_COORDINATE_CM)
	assert_eq(LodReconstruction.position_at(state, 100 + LodReconstruction.MAX_LEG_MINUTES - 1, far_destination, 100).x, NpcState.MAX_COORDINATE_CM - 1, "No limite do teto a conta continua exata (quase no fim).")


func test_on_entering_s0_the_body_is_reconstructed_from_the_place_and_the_hour() -> void:
	var state: NpcState = _traveler()
	_npcs[9] = state
	state.x_cm = FOCUS_CM.x + 5000
	state.z_cm = FOCUS_CM.y
	_lod.place_position_cm = func(place_id: String) -> Vector2i:
		return Vector2i(FOCUS_CM.x + 1000, FOCUS_CM.y) if place_id == "work_1" else LodReconstruction.NO_POSITION
	assert_eq(_text_of(_update(150)), "9:1>0", "Em trânsito, a posição derivada (a meio caminho) já está perto do foco.")
	assert_eq(_lod.position_of(9), Vector2i(FOCUS_CM.x + 3000, FOCUS_CM.y), "Metade do caminho entre 5000 e 1000 cm do foco.")
	assert_eq([state.x_cm, state.z_cm], [FOCUS_CM.x + 5000, FOCUS_CM.y], "O estado do NPC continua com a origem.")
	assert_true(_lod.clear_focus(FOCUS_ID).ok)
	assert_eq(_text_of(_update(151)), "9:0>1")
	assert_eq([state.x_cm, state.z_cm], [FOCUS_CM.x + 5000, FOCUS_CM.y], "Sair sem relato do corpo não grava a posição reconstruída: a origem do trecho continua valendo.")


func test_an_s1_traveler_enters_exactly_when_its_derived_position_reaches_the_enter_radius() -> void:
	var state: NpcState = _traveler()
	_npcs[9] = state
	state.x_cm = FOCUS_CM.x + 40000
	state.z_cm = FOCUS_CM.y
	_lod.place_position_cm = func(_place_id: String) -> Vector2i:
		return FOCUS_CM
	assert_eq(_text_of(_update(110)), "", "Aos 10% do caminho está a 360 m do foco.")
	assert_eq(_text_of(_update(179)), "", "Aos 79%: 400 m x 21% = 84 m, ainda fora.")
	assert_eq(_text_of(_update(180)), "9:1>0", "Aos 80%: 400 m x 20% = 80,00 m exatos, entra.")
	assert_eq(_lod.position_of(9), Vector2i(FOCUS_CM.x + 8000, FOCUS_CM.y), "O corpo nasce onde a hora diz que o NPC está.")
	assert_eq(state.x_cm, FOCUS_CM.x + 40000, "A posição lógica segue sendo a origem enquanto não há relato.")


func test_re_entering_mid_transit_after_a_reported_exit_continues_from_the_reported_point_without_overshoot() -> void:
	var state: NpcState = _traveler()
	_npcs[9] = state
	state.x_cm = FOCUS_CM.x
	state.z_cm = FOCUS_CM.y
	_lod.place_position_cm = func(_place_id: String) -> Vector2i:
		return Vector2i(FOCUS_CM.x + 10000, FOCUS_CM.y)
	assert_eq(_text_of(_update(130)), "9:1>0", "Aos 30% do caminho (3000 cm) está a 30 m do foco: entra.")
	assert_true(_lod.report_position(9, Vector2i(FOCUS_CM.x + 5500, FOCUS_CM.y)).ok, "O corpo, mais lento, só chegou a 5500 cm.")
	assert_true(_lod.clear_focus(FOCUS_ID).ok)
	assert_eq(_text_of(_update(160)), "9:0>1", "Aos 60% o foco sai e o corpo também.")
	assert_eq(state.x_cm, FOCUS_CM.x + 5500, "O relato virou a origem do que falta do trecho.")
	assert_true(_lod.set_focus(FOCUS_ID, Vector3(1050.0, 10.0, 1000.0)).ok)
	assert_eq(_text_of(_update(180)), "9:1>0")
	assert_eq(_lod.position_of(9), Vector2i(FOCUS_CM.x + 5500 + 2250, FOCUS_CM.y), "De 5500 a 10000 entre 160 e 200: a 180 falta metade dos 4500: 5500 + 2250 (sem contar o trecho duas vezes).")
