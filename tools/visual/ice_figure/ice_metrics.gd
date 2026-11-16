extends RefCounted
## Contas do medidor da figura do Ice Warrior (ferramenta de arte, entrega 6d; só funções puras sobre poses e listas de pontos, testáveis com dados sintéticos; quem monta a figura e imprime a tabela é `ice_measure.gd`). Tudo em metros e na escala do arquivo, a menos que a função diga o contrário.
const MIN_LENGTH_SQ: float = 0.0000000001
const SLOTS: int = 4
const TRI: int = 3
const MIN_EDGE_M: float = 0.00001


## Põe o esqueleto na pose do instante `time` do clipe (rotações e translações das trilhas, o que o `AnimationPlayer` aplicaria sem mistura) e atualiza as poses globais.
static func pose_at(skeleton: Skeleton3D, clip: Animation, time: float) -> void:
	for track: int in clip.get_track_count():
		var bone: int = skeleton.find_bone(clip.track_get_path(track).get_concatenated_subnames())
		if bone < 0:
			continue
		if clip.track_get_type(track) == Animation.TYPE_ROTATION_3D:
			skeleton.set_bone_pose_rotation(bone, clip.rotation_track_interpolate(track, time))
		elif clip.track_get_type(track) == Animation.TYPE_POSITION_3D:
			skeleton.set_bone_pose_position(bone, clip.position_track_interpolate(track, time))
	skeleton.force_update_all_bone_transforms()


## O eixo da espada: [base, ponta]. A ponta é o ponto mais longe de `pivot` (a mão que a segura) e a base é o ponto mais longe da ponta; vale para uma lâmina bem mais longa que a guarda.
static func blade_ends(points: PackedVector3Array, pivot: Vector3) -> PackedVector3Array:
	var tip: Vector3 = points[0]
	for point: Vector3 in points:
		if point.distance_squared_to(pivot) > tip.distance_squared_to(pivot):
			tip = point
	var base: Vector3 = points[0]
	for point: Vector3 in points:
		if point.distance_squared_to(tip) > base.distance_squared_to(tip):
			base = point
	return PackedVector3Array([base, tip])


## A menor distância entre dois segmentos (p1 a q1 e p2 a q2); cobre segmentos paralelos e degenerados (um ponto).
static func segment_distance(p1: Vector3, q1: Vector3, p2: Vector3, q2: Vector3) -> float:
	var d1: Vector3 = q1 - p1
	var d2: Vector3 = q2 - p2
	var r: Vector3 = p1 - p2
	var a: float = d1.length_squared()
	var e: float = d2.length_squared()
	var f: float = d2.dot(r)
	var s: float = 0.0
	var t: float = 0.0
	if a > MIN_LENGTH_SQ and e > MIN_LENGTH_SQ:
		var c: float = d1.dot(r)
		var b: float = d1.dot(d2)
		var denominator: float = a * e - b * b
		s = clampf((b * f - c * e) / denominator, 0.0, 1.0) if denominator > MIN_LENGTH_SQ else 0.0
		t = (b * s + f) / e
		if t < 0.0:
			t = 0.0
			s = clampf(-c / a, 0.0, 1.0)
		elif t > 1.0:
			t = 1.0
			s = clampf((b - c) / a, 0.0, 1.0)
	elif a > MIN_LENGTH_SQ:
		s = clampf(-d1.dot(r) / a, 0.0, 1.0)
	elif e > MIN_LENGTH_SQ:
		t = clampf(f / e, 0.0, 1.0)
	return (p1 + d1 * s).distance_to(p2 + d2 * t)


## Os pontos de uma superfície (`arrays`, como em `surface_get_arrays`: vértices, ossos e pesos, 4 por vértice) na pose atual do esqueleto: a pele em CPU, a mesma conta do renderizador (soma dos pesos x pose global do osso x inverso do bind).
static func skinned(skeleton: Skeleton3D, skin: Skin, arrays: Array) -> PackedVector3Array:
	var matrices: Array[Transform3D] = []
	for bind: int in skin.get_bind_count():
		matrices.append(skeleton.get_bone_global_pose(skeleton.find_bone(skin.get_bind_name(bind))) * skin.get_bind_pose(bind))
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	var out: PackedVector3Array = PackedVector3Array()
	out.resize(vertices.size())
	for index: int in vertices.size():
		var point: Vector3 = Vector3.ZERO
		for slot: int in SLOTS:
			if weights[index * SLOTS + slot] > 0.0:
				point += (matrices[bones[index * SLOTS + slot]] * vertices[index]) * weights[index * SLOTS + slot]
		out[index] = point
	return out


## A razão, por triângulo, entre a maior aresta posada e a maior aresta dele no bind (o critério do `ice_selftest.gd` da prova de movimento); `rest` e `posed` são os vértices nas duas poses e `indices`, os triângulos.
static func stretch(rest: PackedVector3Array, posed: PackedVector3Array, indices: PackedInt32Array) -> PackedFloat32Array:
	var ratios: PackedFloat32Array = PackedFloat32Array()
	for first: int in range(0, indices.size(), TRI):
		ratios.append(_longest(posed, indices, first) / maxf(_longest(rest, indices, first), MIN_EDGE_M))
	return ratios


## O menor y entre os pontos marcados em `mask` (1 = conta); INF se nenhum.
static func lowest(points: PackedVector3Array, mask: PackedByteArray) -> float:
	var low: float = INF
	for index: int in points.size():
		if mask[index] == 1:
			low = minf(low, points[index].y)
	return low


static func _longest(points: PackedVector3Array, indices: PackedInt32Array, first: int) -> float:
	var a: Vector3 = points[indices[first]]
	var b: Vector3 = points[indices[first + 1]]
	var c: Vector3 = points[indices[first + 2]]
	return maxf(a.distance_to(b), maxf(b.distance_to(c), c.distance_to(a)))
