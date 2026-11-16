extends GutTest
## ART-12, entrega 6d: as contas do medidor da figura do Ice Warrior (`ice_metrics.gd`) com dados SINTÉTICOS e respostas conhecidas, sem o ativo: a pose de um instante do clipe, o eixo da espada e a menor distância entre segmentos (a conta da lâmina contra a cápsula da coxa), a pele em CPU, o esticamento por triângulo e o ponto mais baixo (pés).

const Metrics = preload("res://tools/visual/ice_figure/ice_metrics.gd")
const TOLERANCE: float = 0.00001
const HALF_TURN_RAD: float = PI / 2.0
## Cada caso: [p1, q1, p2, q2, a distância esperada].
const SEGMENTS: Array = [
	[Vector3(-1, 0, 0), Vector3(1, 0, 0), Vector3(0, -1, 0.5), Vector3(0, 1, 0.5), 0.5],
	[Vector3(-1, 0, 0), Vector3(1, 0, 0), Vector3(0, -1, 0), Vector3(0, 1, 0), 0.0],
	[Vector3(0, 0, 0), Vector3(2, 0, 0), Vector3(0, 1, 0), Vector3(2, 1, 0), 1.0],
	[Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(3, 1, 0), Vector3(4, 1, 0), sqrt(5.0)],
	[Vector3(0, 0, 0), Vector3(2, 0, 0), Vector3(1, 3, 0), Vector3(1, 1, 0), 1.0],
	[Vector3(0, 0, 0), Vector3(2, 0, 0), Vector3(1, 2, 0), Vector3(1, 2, 0), 2.0],
	[Vector3(5, 5, 0), Vector3(5, 5, 0), Vector3(5, 0, 0), Vector3(0, 0, 0), 5.0],
	[Vector3(1, 1, 1), Vector3(1, 1, 1), Vector3(1, 1, 3), Vector3(1, 1, 3), 2.0],
	[Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(2, 0, 0), Vector3(3, 0, 0), 1.0],
]


func test_segment_distance_covers_crossing_parallel_end_to_side_degenerate_and_collinear_cases() -> void:
	for case: Array in SEGMENTS:
		assert_almost_eq(Metrics.segment_distance(case[0], case[1], case[2], case[3]), case[4], TOLERANCE, str(case))
		assert_almost_eq(Metrics.segment_distance(case[2], case[3], case[0], case[1]), case[4], TOLERANCE, "simétrica: " + str(case))
		assert_almost_eq(Metrics.segment_distance(case[1], case[0], case[3], case[2]), case[4], TOLERANCE, "invertida: " + str(case))


func test_blade_ends_are_the_pommel_and_the_tip_not_the_guard() -> void:
	var points: PackedVector3Array = PackedVector3Array([Vector3(0.08, 0.0, 0.1), Vector3(0.0, 0.0, -0.04), Vector3(-0.08, 0.0, 0.1), Vector3(0.0, 0.0, 1.0), Vector3(0.0, 0.01, 0.5)])
	assert_eq(Metrics.blade_ends(points, Vector3.ZERO), PackedVector3Array([Vector3(0.0, 0.0, -0.04), Vector3(0.0, 0.0, 1.0)]), "o ponto mais longe da mão é a ponta; o mais longe da ponta, o pomo")


func test_pose_at_samples_rotation_and_translation_tracks_at_the_requested_time() -> void:
	var skeleton: Skeleton3D = add_child_autofree(Skeleton3D.new())
	for bone_name: String in ["root", "arm", "hand"]:
		skeleton.add_bone(bone_name)
	for bone: int in [1, 2]:
		skeleton.set_bone_parent(bone, bone - 1)
		skeleton.set_bone_rest(bone, Transform3D(Basis.IDENTITY, Vector3.UP))
	skeleton.reset_bone_poses()
	var clip: Animation = Animation.new()
	clip.length = 1.0
	var turn: int = clip.add_track(Animation.TYPE_ROTATION_3D)
	clip.track_set_path(turn, NodePath("Skeleton3D:arm"))
	clip.rotation_track_insert_key(turn, 0.0, Quaternion.IDENTITY)
	clip.rotation_track_insert_key(turn, 1.0, Quaternion(Vector3.BACK, HALF_TURN_RAD))
	var move: int = clip.add_track(Animation.TYPE_POSITION_3D)
	clip.track_set_path(move, NodePath("Skeleton3D:root"))
	clip.position_track_insert_key(move, 0.0, Vector3.ZERO)
	clip.position_track_insert_key(move, 1.0, Vector3(2.0, 0.0, 0.0))
	var lost: int = clip.add_track(Animation.TYPE_ROTATION_3D)
	clip.track_set_path(lost, NodePath("Skeleton3D:nao_existe"))
	clip.rotation_track_insert_key(lost, 0.0, Quaternion.IDENTITY)
	await wait_process_frames(1)
	Metrics.pose_at(skeleton, clip, 0.5)
	var half: float = HALF_TURN_RAD / 2.0
	assert_almost_eq(skeleton.get_bone_pose_rotation(1).angle_to(Quaternion.IDENTITY), half, TOLERANCE, "meia volta do quarto de volta")
	assert_almost_eq(skeleton.get_bone_global_pose(2).origin, Vector3(1.0 - sin(half), 1.0 + cos(half), 0.0), Vector3.ONE * TOLERANCE, "a translação da raiz e a rotação do braço levam a mão")
	Metrics.pose_at(skeleton, clip, 0.0)
	assert_almost_eq(skeleton.get_bone_global_pose(2).origin, Vector3(0.0, 2.0, 0.0), Vector3.ONE * TOLERANCE, "no instante 0 é o repouso")


func test_skinned_applies_weights_times_bone_pose_times_inverse_bind() -> void:
	var skeleton: Skeleton3D = add_child_autofree(Skeleton3D.new())
	for bone_name: String in ["root", "arm"]:
		skeleton.add_bone(bone_name)
	skeleton.set_bone_parent(1, 0)
	skeleton.set_bone_rest(1, Transform3D(Basis.IDENTITY, Vector3.UP))
	skeleton.reset_bone_poses()
	var skin: Skin = Skin.new()
	skin.add_named_bind("root", Transform3D.IDENTITY)
	skin.add_named_bind("arm", Transform3D(Basis.IDENTITY, Vector3.DOWN))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([Vector3(0.0, 2.0, 0.0), Vector3(0.0, 2.0, 0.0)])
	arrays[Mesh.ARRAY_BONES] = PackedInt32Array([1, 0, 0, 0, 0, 1, 0, 0])
	arrays[Mesh.ARRAY_WEIGHTS] = PackedFloat32Array([1.0, 0.0, 0.0, 0.0, 0.5, 0.5, 0.0, 0.0])
	await wait_process_frames(1)
	skeleton.set_bone_pose_rotation(1, Quaternion(Vector3.BACK, HALF_TURN_RAD))
	skeleton.force_update_all_bone_transforms()
	var posed: PackedVector3Array = Metrics.skinned(skeleton, skin, arrays)
	assert_almost_eq(posed[0], Vector3(-1.0, 1.0, 0.0), Vector3.ONE * TOLERANCE, "só o braço: gira em torno da articulação (0, 1, 0)")
	assert_almost_eq(posed[1], Vector3(-0.5, 1.5, 0.0), Vector3.ONE * TOLERANCE, "metade raiz (parada), metade braço")


func test_stretch_is_longest_posed_edge_over_longest_rest_edge_per_triangle_and_survives_a_degenerate_rest() -> void:
	var rest: PackedVector3Array = PackedVector3Array([Vector3.ZERO, Vector3.RIGHT, Vector3.UP, Vector3.ZERO, Vector3.ZERO, Vector3.ZERO])
	var posed: PackedVector3Array = PackedVector3Array([Vector3.ZERO, Vector3.RIGHT * 3.0, Vector3.UP, Vector3.ZERO, Vector3.ZERO, Vector3.RIGHT * 0.001])
	var ratios: PackedFloat32Array = Metrics.stretch(rest, posed, PackedInt32Array([0, 1, 2, 3, 4, 5]))
	assert_almost_eq(ratios[0], sqrt(10.0) / sqrt(2.0), TOLERANCE, "maior aresta de sqrt(10) sobre sqrt(2)")
	assert_true(is_finite(ratios[1]) and ratios[1] > 0.0, "triângulo sem tamanho no bind não divide por zero")


func test_lowest_is_the_minimum_y_among_marked_points_and_infinite_without_marks() -> void:
	var points: PackedVector3Array = PackedVector3Array([Vector3(0, 5, 0), Vector3(0, -2, 0), Vector3(0, 1, 0), Vector3(0, -9, 0)])
	assert_eq(Metrics.lowest(points, PackedByteArray([1, 0, 1, 0])), 1.0, "o -2 e o -9 não contam")
	assert_eq(Metrics.lowest(points, PackedByteArray([0, 0, 0, 0])), INF)
