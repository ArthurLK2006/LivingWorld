extends GutTest
## LW-152 (SP6, DESCARTÁVEL): testa as regras puras do duelo (Sp6Rules) e a geometria (Sp6Geometry) sem janela. Os valores esperados estão
## ESCRITOS À MÃO a partir das hipóteses [HIP] de Sp6Constants (Q 30/700/900/30, R 10/200/400/12, F 16/400/600/20, automático 6/1500/4,
## alcance 250 cm + 50 de tolerância, buffer 200 ms, estamina 100 com 12 por segundo depois de 1000 ms). Roda no tools/check_all
## (tools/run_tests varre tests/soak). Convenção: t = milissegundos desde o começo do cenário; o aperto acontece depois do tick de t.

const HEAVY: int = 0
const QUICK: int = 1
const PIERCING: int = 2
const AUTO: int = Sp6Constants.NO_SKILL
const IN_RANGE_CM: int = 200
const LONG_RUN_MS: int = 6000
const EVENT_HIT: int = Sp6Rules.EventType.HIT


## Duelo pronto: boneco de pé, alvo escolhido, jogador à frente dele e dentro do alcance.
func _duel(start_stamina: int = Sp6Constants.STAMINA_MAX, distance_cm: int = IN_RANGE_CM, angle_deg: float = 0.0) -> Sp6Rules:
	var rules: Sp6Rules = Sp6Rules.new(start_stamina)
	rules.set_geometry(distance_cm, angle_deg)
	rules.select_target()
	return rules


func _types(events: Array[Sp6Rules.CombatEvent]) -> Array[int]:
	var types: Array[int] = []
	for event: Sp6Rules.CombatEvent in events:
		types.append(event.type)
	return types


## Danos dos acertos, na ordem em que aconteceram.
func _damages(events: Array[Sp6Rules.CombatEvent]) -> Array[int]:
	var damages: Array[int] = []
	for event: Sp6Rules.CombatEvent in events:
		if event.type == EVENT_HIT:
			damages.append(event.damage)
	return damages


## (a) Critério: sequência scriptada reduz a vida exatamente como calculado à mão (armadura nenhuma, de frente).
## t=1: automático 6 -> 194 (estamina 96). Q em t=1: gasta 30 (66); acerta em t=701 -> 164; recuperação até t=1601.
## t=1601: automático (pronto desde 1501) -> 158; estamina 66 + 600 ms x 12 (regenera de t=1002 a 1601) = 73,2 - 4 = 69,2.
## R em t=1601: gasta 12 (57,2); acerta em t=1801 -> 148; livre em t=2201. F em t=2201: gasta 20 (37,2); acerta em t=2601 -> 132;
## livre em t=3201: automático -> 126 (sem regeneração: só 1000 ms desde o gasto, e ela exige mais que isso); estamina 37,2 - 4 = 33,2.
## Soma: 6+30+6+10+16+6 = 74; 200 - 74 = 126.
func test_scripted_sequence_matches_hand_calculation() -> void:
	var rules: Sp6Rules = _duel()
	var all_events: Array[Sp6Rules.CombatEvent] = []
	rules.step(1)
	assert_eq(rules.dummy_hp(), 194)
	rules.request_skill(HEAVY)
	rules.step(699)
	assert_eq(rules.dummy_hp(), 194, "Q ainda em preparo em t=700.")
	rules.step(1)
	assert_eq(rules.dummy_hp(), 164)
	rules.step(899)
	assert_eq(rules.dummy_hp(), 164, "Recuperação até t=1600 trava o automático.")
	rules.step(1)
	assert_eq([rules.dummy_hp(), rules.stamina_milli()], [158, 69200])
	rules.request_skill(QUICK)
	rules.step(200)
	assert_eq([rules.dummy_hp(), rules.stamina_milli()], [148, 57200])
	rules.step(400)
	rules.request_skill(PIERCING)
	rules.step(400)
	assert_eq(rules.dummy_hp(), 132)
	rules.step(600)
	assert_eq([rules.dummy_hp(), rules.stamina_milli()], [126, 33200])
	all_events = rules.take_events()
	assert_eq(_damages(all_events), [6, 30, 6, 10, 16, 6])
	assert_eq(_types(all_events).count(EVENT_HIT), 6)


## (b) Armadura: 0%, 25% e 50%; o F ignora metade da redução (25 / 2 = 12 em divisão inteira). Valores de frente (100%):
## nenhuma Q30 R10 F16 auto6; leve Q 30x75/100=22 R 7 F 16x88/100=14 auto 4; pesada Q15 R5 F 16x75/100=12 auto 3.
func test_armor_reduction_and_piercing_half() -> void:
	var expected: Array = [[30, 10, 16, 6], [22, 7, 14, 4], [15, 5, 12, 3]]
	for armor: int in 3:
		var rules: Sp6Rules = _duel()
		for _cycle: int in armor:
			rules.cycle_armor()
		var got: Array[int] = [rules.deal_hit(HEAVY), rules.deal_hit(QUICK), rules.deal_hit(PIERCING), rules.deal_hit(AUTO)]
		assert_eq(got, expected[armor], "Armadura %d." % armor)
	var rules_after_cycle: Sp6Rules = _duel()
	for _cycle: int in 3:
		rules_after_cycle.cycle_armor()
	assert_eq(rules_after_cycle.armor(), 0, "O ciclo volta a 'nenhuma'.")


## (c) Posição: 0, 60 e 61, 120 e 121, 180 graus; Q de 30 vale 30, 30, 37, 37, 45, 45 (x1,00 x1,25 x1,50 com divisão inteira).
func test_position_groups_at_exact_limits() -> void:
	var cases: Array = [[0.0, 0, 30], [60.0, 0, 30], [61.0, 1, 37], [120.0, 1, 37], [121.0, 2, 45], [180.0, 2, 45]]
	for entry: Array in cases:
		var rules: Sp6Rules = _duel(Sp6Constants.STAMINA_MAX, IN_RANGE_CM, entry[0] as float)
		assert_eq(Sp6Rules.group_of(entry[0] as float), entry[1], "Grupo a %s graus." % str(entry[0]))
		assert_eq(rules.deal_hit(HEAVY), entry[2], "Dano a %s graus." % str(entry[0]))


## (d) Estamina: gasta ao apertar (Q: 100 -> 70 antes de qualquer tick); custo exatamente igual começa; um ponto a menos não começa.
func test_stamina_is_spent_on_press_and_checked_exactly() -> void:
	var rules: Sp6Rules = _duel()
	rules.request_skill(HEAVY)
	assert_eq([rules.stamina(), rules.phase()], [70, Sp6Rules.Phase.WINDUP])
	var exact: Sp6Rules = _duel(30)
	exact.request_skill(HEAVY)
	assert_eq([exact.stamina_milli(), exact.phase()], [0, Sp6Rules.Phase.WINDUP])
	var short: Sp6Rules = _duel(29)
	short.request_skill(HEAVY)
	assert_eq([short.stamina_milli(), short.phase()], [29000, Sp6Rules.Phase.IDLE])
	assert_eq(_types(short.take_events()), [Sp6Rules.EventType.NO_STAMINA])
	assert_eq(short.slot_state(HEAVY), Sp6Rules.SlotState.NO_STAMINA)
	assert_eq(short.slot_state(QUICK), Sp6Rules.SlotState.READY, "R custa 12 e há 29.")


## (d) Regeneração: só depois de 1000 ms do último gasto, 12 por segundo e sem perder fração (12 milésimos por ms).
## F gasta 20 (80); o alvo é solto para o automático não gastar (e o golpe já iniciado continua valendo: 200 - 16 = 184). t=1000: 80 (nada);
## +1 ms: 80,012; t=2000: 92; depois sobe até o teto 100.
## Fração: 83 ms de regeneração = 996 milésimos (ainda 80 pontos); 84 ms = 1008 (81 pontos).
func test_stamina_regenerates_after_delay_without_losing_fraction() -> void:
	var rules: Sp6Rules = _duel()
	rules.request_skill(PIERCING)
	rules.clear_target()
	rules.step(1000)
	assert_eq([rules.stamina_milli(), rules.dummy_hp()], [80000, 184], "Em 1000 ms exatos ainda não regenera; o F iniciado acertou.")
	rules.step(1)
	assert_eq(rules.stamina_milli(), 80012)
	rules.step(999)
	assert_eq(rules.stamina_milli(), 92000)
	rules.step(5000)
	assert_eq(rules.stamina_milli(), 100000, "Teto de 100 pontos.")
	var fraction: Sp6Rules = _duel()
	fraction.request_skill(PIERCING)
	fraction.clear_target()
	fraction.step(1000 + 83)
	assert_eq([fraction.stamina_milli(), fraction.stamina()], [80996, 80])
	fraction.step(1)
	assert_eq([fraction.stamina_milli(), fraction.stamina()], [81008, 81])


## (e) Tempo: o golpe só cai no FIM do preparo (Q em t=700, R em t=200), nem um ms antes.
func test_hit_lands_only_at_end_of_windup() -> void:
	for entry: Array in [[HEAVY, 700, 170], [QUICK, 200, 190]]:
		var rules: Sp6Rules = _duel()
		rules.request_skill(entry[0] as int)
		rules.step((entry[1] as int) - 1)
		assert_eq([rules.dummy_hp(), rules.take_events().size(), rules.phase()], [200, 0, Sp6Rules.Phase.WINDUP])
		rules.step(1)
		assert_eq([rules.dummy_hp(), rules.phase()], [entry[2], Sp6Rules.Phase.RECOVERY])


## (e) Recuperação trava; buffer de 200 ms: Q acerta em t=700 e libera em t=1600. R apertado com 900 e com 201 ms restantes é ignorado;
## com 200 restantes fica guardado e começa em t=1600. A estamina (70 depois do Q) regenera 12 por ms de milésimo a partir de t=1002,
## então nada gasto vale 70.000 + 12 x ms: t=1399 -> 399 ms = 74.788; t=1599 -> 599 ms = 77.188; t=1600 -> 600 ms = 77.200 e o R
## guardado gasta 12.000 = 65.200 (se o guardado fosse o F: 77.200 - 20.000 = 57.200). Duas guardadas: a mais nova (F) substitui.
func test_recovery_locks_and_input_buffer_holds_one_newest_skill() -> void:
	var rules: Sp6Rules = _duel()
	rules.request_skill(HEAVY)
	rules.step(700)
	rules.request_skill(QUICK)
	rules.step(699)
	rules.request_skill(QUICK)
	assert_eq([rules.stamina_milli(), rules.phase()], [74788, Sp6Rules.Phase.RECOVERY], "Com 201 ms restantes ainda trava e nada é gasto.")
	rules.step(1)
	rules.request_skill(QUICK)
	rules.step(199)
	assert_eq([rules.stamina_milli(), rules.phase()], [77188, Sp6Rules.Phase.RECOVERY], "Guardado: nada gasto até a recuperação acabar.")
	rules.step(1)
	assert_eq([rules.stamina_milli(), rules.phase(), rules.active_skill()], [65200, Sp6Rules.Phase.WINDUP, QUICK])
	var newest: Sp6Rules = _duel()
	newest.request_skill(HEAVY)
	newest.step(700 + 700)
	newest.request_skill(QUICK)
	newest.request_skill(PIERCING)
	newest.step(200)
	assert_eq([newest.stamina_milli(), newest.active_skill()], [57200, PIERCING])


## (e/erro) Habilidade guardada que não pode começar quando a recuperação acaba avisa "sem fôlego" e não trava o jogo.
## Estamina 40: Q gasta 30 (10); em t=1600 há 10 + 600 x 12 = 17,2 < 20 do F guardado.
func test_buffered_skill_without_stamina_fails_visibly() -> void:
	var rules: Sp6Rules = _duel(40)
	rules.request_skill(HEAVY)
	rules.step(1400)
	rules.request_skill(PIERCING)
	rules.take_events()
	rules.step(200)
	assert_true(_types(rules.take_events()).has(Sp6Rules.EventType.NO_STAMINA))
	assert_ne(rules.phase(), Sp6Rules.Phase.WINDUP)


## (f) Alcance: começar exige até 250 cm (251 recusa, sem gastar); no impacto vale até 250 + 50 (300 acerta, 301 erra) e quem erra
## não recebe a estamina de volta (continua 70).
func test_range_at_start_and_at_impact() -> void:
	var far: Sp6Rules = _duel(Sp6Constants.STAMINA_MAX, 251)
	far.request_skill(HEAVY)
	assert_eq([far.stamina_milli(), far.phase()], [100000, Sp6Rules.Phase.IDLE])
	assert_eq(_types(far.take_events()), [Sp6Rules.EventType.TOO_FAR])
	for entry: Array in [[300, 170, Sp6Rules.EventType.HIT], [301, 200, Sp6Rules.EventType.MISS]]:
		var rules: Sp6Rules = _duel(Sp6Constants.STAMINA_MAX, 250)
		rules.request_skill(HEAVY)
		rules.step(699)
		rules.set_geometry(entry[0] as int, 0.0)
		rules.step(1)
		assert_eq([rules.dummy_hp(), rules.stamina_milli(), _types(rules.take_events())[0]], [entry[1], 70000, entry[2]], "Distância %d." % entry[0])
		assert_eq(rules.phase(), Sp6Rules.Phase.RECOVERY, "Errar também gasta a recuperação.")


## (g) Limites: 6 Q (180) deixam 20; o 7º zera a vida: um HIT e um DEFEATED, alvo solto. Golpe em alvo caído não conta (devolve 0, sem
## evento). Apertar sem alvo avisa e não gasta. Em 2999 ms ainda caído; em 3000 volta com 200 de vida, sem alvo escolhido.
func test_defeat_fallen_target_and_respawn() -> void:
	var rules: Sp6Rules = _duel()
	for _hit: int in 6:
		rules.deal_hit(HEAVY)
	assert_eq([rules.dummy_hp(), rules.is_dummy_alive()], [20, true])
	rules.take_events()
	rules.deal_hit(HEAVY)
	assert_eq(_types(rules.take_events()), [EVENT_HIT, Sp6Rules.EventType.DEFEATED])
	assert_eq([rules.dummy_hp(), rules.is_dummy_alive(), rules.has_target(), rules.select_target()], [0, false, false, false])
	assert_eq([rules.deal_hit(HEAVY), rules.take_events().size()], [0, 0])
	rules.request_skill(HEAVY)
	assert_eq([rules.stamina_milli(), _types(rules.take_events())], [100000, [Sp6Rules.EventType.NO_TARGET]])
	rules.step(2999)
	assert_eq([rules.is_dummy_alive(), rules.take_events().size()], [false, 0])
	rules.step(1)
	assert_eq([rules.dummy_hp(), rules.is_dummy_alive(), rules.has_target(), _types(rules.take_events())], [200, true, false, [Sp6Rules.EventType.RESPAWNED]])


## (g) Se o boneco cai durante o preparo, o golpe erra (o alvo não existe mais) e a vida continua 0. Dano mínimo 1: 1 x 100 x 50 / 10.000 = 0 -> 1.
func test_hit_on_target_that_fell_during_windup_misses_and_minimum_damage_is_one() -> void:
	var rules: Sp6Rules = _duel()
	rules.request_skill(HEAVY)
	for _hit: int in 7:
		rules.deal_hit(HEAVY)
	rules.take_events()
	rules.step(700)
	assert_eq([rules.dummy_hp(), _types(rules.take_events())], [0, [Sp6Rules.EventType.MISS]])
	assert_eq(Sp6Rules.final_damage(1, 100, 50), 1)
	assert_eq(Sp6Rules.final_damage(6, 100, 50), 3)


## Ataque automático: sem alvo ou fora do alcance não bate; com alvo bate já no 1º tick (t=1) e de novo em t=1501; sem estamina espera
## (3 pontos + 12 milésimos por ms chegam a 4,008 no tick 84; no 83 são 3,996).
func test_auto_attack_conditions() -> void:
	var no_target: Sp6Rules = Sp6Rules.new()
	no_target.set_geometry(IN_RANGE_CM, 0.0)
	no_target.step(5000)
	assert_eq(no_target.dummy_hp(), 200)
	var far: Sp6Rules = _duel(Sp6Constants.STAMINA_MAX, 251)
	far.step(5000)
	assert_eq(far.dummy_hp(), 200)
	var rules: Sp6Rules = _duel()
	rules.step(1)
	assert_eq(rules.dummy_hp(), 194)
	rules.step(1499)
	assert_eq(rules.dummy_hp(), 194, "O intervalo só se cumpre em t=1501.")
	rules.step(1)
	assert_eq(rules.dummy_hp(), 188)
	var winded: Sp6Rules = _duel(3)
	winded.step(83)
	assert_eq(winded.dummy_hp(), 200)
	winded.step(1)
	assert_eq([winded.dummy_hp(), winded.stamina_milli()], [194, 8])


## O que a tela lê: estado de cada espaço e progresso da fase (Q a meio do preparo: 50; início da recuperação: 100).
func test_slot_states_and_phase_progress() -> void:
	var far: Sp6Rules = _duel(Sp6Constants.STAMINA_MAX, 251)
	assert_eq(far.slot_state(HEAVY), Sp6Rules.SlotState.TOO_FAR)
	var no_target: Sp6Rules = Sp6Rules.new()
	assert_eq(no_target.slot_state(HEAVY), Sp6Rules.SlotState.NO_TARGET)
	var rules: Sp6Rules = _duel()
	assert_eq(rules.slot_state(HEAVY), Sp6Rules.SlotState.READY)
	rules.request_skill(HEAVY)
	rules.step(350)
	assert_eq([rules.slot_state(HEAVY), rules.slot_state(QUICK), rules.phase_progress_pct()], [Sp6Rules.SlotState.WINDUP, Sp6Rules.SlotState.BUSY, 50])
	rules.step(350)
	assert_eq([rules.slot_state(HEAVY), rules.phase_progress_pct()], [Sp6Rules.SlotState.RECOVERY, 100])


## (h) Determinismo: a mesma sequência duas vezes dá o mesmo estado e os mesmos eventos; e o resultado não depende do tamanho do passo
## (6000 ms de uma vez, em passos de 1 ms e em passos de 16 ms, só com o automático).
func test_same_sequence_same_result_and_independent_of_step_size() -> void:
	var first: String = _scripted_signature()
	assert_eq(_scripted_signature(), first)
	var signatures: Array[String] = []
	for chunk_ms: int in [LONG_RUN_MS, 1, 16]:
		var rules: Sp6Rules = _duel()
		for _chunk: int in IntMath.floor_div(LONG_RUN_MS, chunk_ms):
			rules.step(chunk_ms)
		signatures.append(rules.state_signature() + str(_damages(rules.take_events())))
	assert_eq(signatures[1], signatures[0])
	assert_eq(signatures[2], signatures[0])


func _scripted_signature() -> String:
	var rules: Sp6Rules = _duel(Sp6Constants.STAMINA_MAX, IN_RANGE_CM, 90.0)
	rules.cycle_armor()
	for slot: int in [HEAVY, QUICK, PIERCING, HEAVY]:
		rules.request_skill(slot)
		rules.step(1300)
	return rules.state_signature() + str(_damages(rules.take_events()))


## Geometria: ângulo a 0, 90 e 180 graus (boneco olhando para oeste), distância horizontal e seleção por raio.
func test_geometry_angle_distance_and_ray() -> void:
	var dummy: Vector3 = Vector3(108.0, 10.0, 512.0)
	for entry: Array in [[Vector3(100.0, 10.0, 512.0), 0.0], [Vector3(108.0, 10.0, 520.0), 90.0], [Vector3(108.0, 10.0, 504.0), 90.0], [Vector3(116.0, 10.0, 512.0), 180.0], [dummy, 0.0]]:
		assert_almost_eq(Sp6Geometry.angle_from_front_deg(Sp6Constants.DUMMY_FRONT, dummy, entry[0] as Vector3), entry[1] as float, 0.001)
	assert_eq(Sp6Geometry.horizontal_distance_cm(Vector3(100.0, 10.0, 512.0), dummy), 800)
	assert_eq(Sp6Geometry.horizontal_distance_cm(Vector3.ZERO, Vector3(3.0, 99.0, 4.0)), 500, "A altura não conta (3-4-5).")
	var origin: Vector3 = Vector3.ZERO
	assert_true(Sp6Geometry.ray_hits_sphere(origin, Vector3.RIGHT, Vector3(10.0, 0.0, 0.5), 1.0))
	assert_false(Sp6Geometry.ray_hits_sphere(origin, Vector3.RIGHT, Vector3(10.0, 0.0, 1.5), 1.0))
	assert_false(Sp6Geometry.ray_hits_sphere(origin, Vector3.RIGHT, Vector3(-10.0, 0.0, 0.0), 1.0), "Esfera atrás do raio.")
