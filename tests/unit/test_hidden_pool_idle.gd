extends GutTest
## LW-099e (guarda; só apresentação): a RESERVA OCULTA não processa nada. Os corpos LIVRES da `CaravanViewPool` (8, dado real) e do `NpcViewPool` (60), recém-criados e depois de um ciclo de entrega e devolução (`take`, pose, andar, `give_back`),
## não têm nenhum nó da árvore do corpo com processamento ligado (process, physics_process, os internos, a entrada de teclado, de atalho e a não tratada) nem nó de animação, de tempo ou de partículas (`AnimationPlayer`, `AnimationTree`, `Timer`,
## `GPUParticles3D`, `CPUParticles3D`, `Skeleton3D`, `AudioStreamPlayer3D`). O teste olha o ESTADO (o que está ligado), não a existência de `_process`: o corpo pode ter o método, contanto que fique DESLIGADO fora de uso (o `NpcView` só liga andando).
## Medido em 25/11/2026: 8 corpos de caravana (152 nós) e 60 de NPC (240 nós) livres = 0 nós processando; só os NPCs ativos andando processam (o quique da cápsula). O primeiro teste é o MUTANTE: prova que o detector reprova cada defeito.
## REGRA para a integração de corpos animados (modelos com `AnimationPlayer` ou `AnimationTree`): `visible = false` NÃO para a animação (o último teste mostra); ao devolver à reserva, esconder E pôr `process_mode = PROCESS_MODE_DISABLED`; ao entregar, restaurar
## `PROCESS_MODE_INHERIT` antes da 1ª pose. Se um corpo animado passar a FICAR na reserva com o nó de animação (hoje o `NpcView.detach` solta e libera a figura), este guarda deve ser estendido NA MESMA mudança para aceitar só o nó que não processa (`can_process()` falso).
## Contrato: docs/modules/presentation.md.

## Classes que, num corpo livre, custariam quadro mesmo escondido.
const FORBIDDEN_CLASSES: PackedStringArray = ["AnimationMixer", "AnimationPlayer", "AnimationTree", "Timer", "GPUParticles3D", "CPUParticles3D", "Skeleton3D", "AudioStreamPlayer3D"]
## Os mutantes de processamento: cada um liga UM tipo de processamento no corpo (o último, num nó fundo da árvore).
const MUTANT_PROCESS: String = "process"
const MUTANT_PHYSICS: String = "physics_process"
const MUTANT_INTERNAL: String = "process_internal"
const MUTANT_PHYSICS_INTERNAL: String = "physics_process_internal"
const MUTANT_INPUT: String = "input"
const MUTANT_UNHANDLED_INPUT: String = "unhandled_input"
const MUTANT_SHORTCUT: String = "shortcut_input"
const MUTANT_UNHANDLED_KEY: String = "unhandled_key_input"
const MUTANT_DEEP: String = "process_in_a_deep_node"
const PROCESS_MUTANTS: PackedStringArray = [MUTANT_PROCESS, MUTANT_PHYSICS, MUTANT_INTERNAL, MUTANT_PHYSICS_INTERNAL, MUTANT_INPUT, MUTANT_UNHANDLED_INPUT, MUTANT_SHORTCUT, MUTANT_UNHANDLED_KEY, MUTANT_DEEP]
const POINT: Vector3 = Vector3(20.0, 10.0, 40.0)
const NEXT_POINT: Vector3 = Vector3(24.0, 10.0, 43.0)
const TRADERS: int = 6
const NPCS: int = 50
const FIGURE_NPC_ID: int = 77
const ROUNDS: int = 3
const GOOD_ID: String = "grain"
const LOAD_PERMILLE: int = 900
const WAIT_FRAMES: int = 4
const CLIP: String = "walk"
const CLIP_SECONDS: float = 10.0

var _routes: CaravanRoutesReader
var _parent: Node3D


func before_all() -> void:
	var loaded: CaravanRoutesReader.LoadResult = CaravanRoutesReader.from_file()
	assert_true(loaded.result.ok, loaded.result.message)
	_routes = loaded.data


func before_each() -> void:
	_parent = Node3D.new()
	add_child_autofree(_parent)


## Os nós da árvore do corpo: ele e todos os descendentes (também os sem dono, que são os criados por código).
func _tree_of(body: Node) -> Array[Node]:
	var nodes: Array[Node] = [body]
	nodes.append_array(body.find_children("*", "", true, false))
	return nodes


## Os tipos de processamento que estão ligados neste nó (vazio = nenhum).
func _flags_on(node: Node) -> PackedStringArray:
	var flags: PackedStringArray = []
	if node.is_processing():
		flags.append(MUTANT_PROCESS)
	if node.is_physics_processing():
		flags.append(MUTANT_PHYSICS)
	if node.is_processing_internal():
		flags.append(MUTANT_INTERNAL)
	if node.is_physics_processing_internal():
		flags.append(MUTANT_PHYSICS_INTERNAL)
	if node.is_processing_input():
		flags.append(MUTANT_INPUT)
	if node.is_processing_unhandled_input():
		flags.append(MUTANT_UNHANDLED_INPUT)
	if node.is_processing_shortcut_input():
		flags.append(MUTANT_SHORTCUT)
	if node.is_processing_unhandled_key_input():
		flags.append(MUTANT_UNHANDLED_KEY)
	return flags


## O detector: um achado por defeito (processamento ligado ou nó proibido) em qualquer nó da árvore do corpo. Vazio = o corpo está ocioso.
func _findings(body: Node) -> Array[String]:
	var found: Array[String] = []
	for node: Node in _tree_of(body):
		var where: String = "%s (%s)" % [body.get_path_to(node), node.get_class()]
		for flag: String in _flags_on(node):
			found.append("%s: %s ligado" % [where, flag])
		for forbidden: String in FORBIDDEN_CLASSES:
			if node.is_class(forbidden):
				found.append("%s: nó proibido num corpo livre (%s)" % [where, forbidden])
				break
	return found


## Confere que todos os `bodies` estão ociosos e devolve quantos nós olhou (para o teste provar que não olhou o vazio).
func _assert_idle(bodies: Array[Node], what: String) -> int:
	var seen: int = 0
	for body: Node in bodies:
		assert_eq(_findings(body), [] as Array[String], "%s: o corpo %s está ocioso" % [what, body.name])
		seen += _tree_of(body).size()
	return seen


## Estraga o corpo de UM jeito: liga um tipo de processamento (no corpo, ou num nó fundo) ou acrescenta um nó da classe proibida `mutant`.
func _mutate(body: Node, mutant: String) -> void:
	match mutant:
		MUTANT_PROCESS:
			body.set_process(true)
		MUTANT_PHYSICS:
			body.set_physics_process(true)
		MUTANT_INTERNAL:
			body.set_process_internal(true)
		MUTANT_PHYSICS_INTERNAL:
			body.set_physics_process_internal(true)
		MUTANT_INPUT:
			body.set_process_input(true)
		MUTANT_UNHANDLED_INPUT:
			body.set_process_unhandled_input(true)
		MUTANT_SHORTCUT:
			body.set_process_shortcut_input(true)
		MUTANT_UNHANDLED_KEY:
			body.set_process_unhandled_key_input(true)
		MUTANT_DEEP:
			body.find_child(NpcView.CAPSULE_NAME, true, false).set_process(true)
		_:
			body.add_child(ClassDB.instantiate(mutant) as Node)


## Figura sintética com um `AnimationPlayer` e um clipe `walk` em laço (só em memória; nenhum ativo de terceiros).
func _synthetic_figure() -> Node3D:
	var figure: Node3D = Node3D.new()
	figure.add_child(MeshInstance3D.new())
	var animation: Animation = Animation.new()
	animation.length = CLIP_SECONDS
	animation.loop_mode = Animation.LOOP_LINEAR
	var library: AnimationLibrary = AnimationLibrary.new()
	library.add_animation(StringName(CLIP), animation)
	var player: AnimationPlayer = AnimationPlayer.new()
	figure.add_child(player)
	player.add_animation_library("", library)
	return figure


func _wait_frames(count: int) -> void:
	for _frame: int in count:
		await get_tree().process_frame


# ---------------------------------------------------------------------------------------------------- o detector (mutantes)

func test_the_detector_reports_every_mutant_on_both_kinds_of_body_and_clears_the_clean_ones() -> void:
	var kinds: PackedStringArray = PROCESS_MUTANTS.duplicate()
	for forbidden: String in FORBIDDEN_CLASSES:
		if ClassDB.can_instantiate(forbidden):
			kinds.append(forbidden)
	assert_gt(kinds.size(), PROCESS_MUTANTS.size(), "as classes proibidas entram como mutantes")
	var clean_caravan: CaravanView = CaravanView.new(_routes)
	var clean_npc: NpcView = NpcView.new()
	_parent.add_child(clean_caravan)
	_parent.add_child(clean_npc)
	assert_eq(_findings(clean_caravan), [] as Array[String], "controle: o corpo de caravana livre e novo está limpo")
	assert_eq(_findings(clean_npc), [] as Array[String], "controle: o corpo de NPC livre e novo está limpo")
	for mutant: String in kinds:
		var caravan: CaravanView = CaravanView.new(_routes)
		var npc: NpcView = NpcView.new()
		_parent.add_child(caravan)
		_parent.add_child(npc)
		_mutate(caravan, mutant)
		_mutate(npc, mutant)
		assert_false(_findings(caravan).is_empty(), "mutante %s no corpo de caravana: o detector reprova" % mutant)
		assert_false(_findings(npc).is_empty(), "mutante %s no corpo de NPC: o detector reprova" % mutant)


# ---------------------------------------------------------------------------------------------------- a reserva de caravanas

func test_the_new_caravan_reserve_is_idle() -> void:
	var pool: CaravanViewPool = CaravanViewPool.new(_parent, _routes)
	assert_gt(pool.created, 0, "o dado real tem reserva")
	var bodies: Array[Node] = _parent.get_children()
	assert_eq(bodies.size(), pool.free_count(), "todos os corpos estão livres")
	var seen: int = _assert_idle(bodies, "reserva recém-criada")
	assert_gt(seen, bodies.size(), "olhou os nós de dentro dos corpos, não só as raízes")


func test_the_caravan_reserve_is_idle_again_after_each_take_pose_walk_and_give_back() -> void:
	var pool: CaravanViewPool = CaravanViewPool.new(_parent, _routes)
	for round_index: int in ROUNDS:
		for trader_id: int in range(1, TRADERS + 1):
			var body: CaravanView = pool.take(trader_id)
			body.apply_pose(POINT, 0.5, 0.1)
			body.apply_state(true, GOOD_ID, LOAD_PERMILLE)
			body.apply_pose(NEXT_POINT, 0.6, 0.1)
			assert_true(body.visible and body.merchant().is_walking(), "o ciclo de verdade: o corpo %d aparece e anda" % trader_id)
		for trader_id: int in range(1, TRADERS + 1):
			assert_true(pool.give_back(trader_id))
		assert_eq([pool.free_count(), pool.returned], [pool.created, TRADERS * (round_index + 1)], "a volta %d devolveu todos" % round_index)
		_assert_idle(_parent.get_children(), "reserva depois da volta %d" % round_index)


# ---------------------------------------------------------------------------------------------------- a reserva de NPCs

func test_the_new_npc_reserve_is_idle() -> void:
	var pool: NpcViewPool = NpcViewPool.new(_parent)
	assert_eq([pool.created, pool.free_count()], [NpcViewPool.PREWARM_COUNT, NpcViewPool.PREWARM_COUNT])
	var seen: int = _assert_idle(_parent.get_children(), "reserva recém-criada")
	assert_gt(seen, pool.created, "olhou os nós de dentro dos corpos, não só as raízes")


func test_the_npc_reserve_is_idle_again_after_walking_bodies_are_given_back() -> void:
	var pool: NpcViewPool = NpcViewPool.new(_parent)
	for round_index: int in ROUNDS:
		for npc_id: int in range(1, NPCS + 1):
			var body: NpcView = pool.take(npc_id, POINT)
			body.set_walking(true)
			assert_true(body.is_processing(), "o ciclo de verdade: o NPC %d anda e o quique liga o processamento" % npc_id)
		for npc_id: int in range(1, NPCS + 1):
			assert_true(pool.give_back(npc_id))
		assert_eq([pool.free_count(), pool.returned], [pool.created, NPCS * (round_index + 1)], "a volta %d devolveu todos" % round_index)
		_assert_idle(_parent.get_children(), "reserva depois da volta %d" % round_index)


func test_a_npc_body_that_wore_an_animated_figure_is_idle_right_after_the_give_back() -> void:
	var pool: NpcViewPool = NpcViewPool.new(_parent, 1)
	var body: NpcView = pool.take(FIGURE_NPC_ID, POINT)
	var figure: Node3D = _synthetic_figure()
	body.attach_figure(figure)
	body.set_walking(true)
	assert_false(_findings(body).is_empty(), "controle: com a figura animada o detector acha o player e o processamento dele")
	assert_true(pool.give_back(FIGURE_NPC_ID))
	assert_eq(_findings(body), [] as Array[String], "na hora da devolução (antes de o queue_free rodar) a figura já saiu da árvore do corpo")
	await _wait_frames(WAIT_FRAMES)
	assert_false(is_instance_valid(figure), "e a figura foi liberada")
	assert_eq(_findings(body), [] as Array[String], "o corpo segue ocioso depois dos quadros")


# ---------------------------------------------------------------------------------------------------- a premissa da REGRA

func test_hiding_does_not_stop_an_animation_but_process_mode_disabled_does() -> void:
	var body: Node3D = _synthetic_figure()
	_parent.add_child(body)
	var player: AnimationPlayer = body.find_children("*", "AnimationPlayer", false, false)[0] as AnimationPlayer
	player.play(StringName(CLIP))
	body.visible = false
	await _wait_frames(WAIT_FRAMES)
	var hidden_at: float = player.current_animation_position
	assert_gt(hidden_at, 0.0, "escondido (visible = false) o clipe CONTINUA andando")
	body.process_mode = Node.PROCESS_MODE_DISABLED
	assert_false(player.can_process(), "com o corpo em DISABLED o player não processa")
	var frozen_at: float = player.current_animation_position
	await _wait_frames(WAIT_FRAMES)
	assert_eq(player.current_animation_position, frozen_at, "e o clipe parou onde estava")
	body.process_mode = Node.PROCESS_MODE_INHERIT
	await _wait_frames(WAIT_FRAMES)
	assert_gt(player.current_animation_position, frozen_at, "com INHERIT de volta o clipe anda de novo")
