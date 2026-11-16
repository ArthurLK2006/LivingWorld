extends RefCounted
## Os pontos de CONTATO das botas do Ice Warrior (entrega 6e; ferramenta de arte, SEM janela; só lê os dados em memória do preparo e não grava nada). A trava de chão da 6a mede o osso do pé, mas a sola da bota fica abaixo da origem do osso e afunda no walk: os pontos medidos na MALHA dizem onde a bota apoia. Para cada osso do pé, pega os vértices que ele pesa em pelo menos FOOT_WEIGHT e, em cada direção de PITCHES (giro de ponta e calcanhar) por ROLLS (giro lateral), o mais extremo para baixo (o ponto de apoio da bota naquela inclinação, sem repetição, do mais baixo ao mais alto); os pontos saem no espaço LOCAL do osso (pelo inverso da pose de bind) e entram no campo `ground_points` dos metadados (6e), que `CharacterFigure` lê para `CharacterRetarget.Options.ground_points`.
const Source = preload("res://tools/visual/ice_figure/ice_source.gd")
const Skel = preload("res://tools/visual/ice_figure/ice_skeleton.gd")
const Weights = preload("res://tools/visual/ice_figure/ice_weights.gd")
const FOOT_BONES: PackedStringArray = ["foot_l", "foot_r"]
## [HIP] O peso mínimo no osso do pé para o vértice ser da bota, os giros de ponta e calcanhar e os giros laterais (graus) das 33 direções de apoio (11 pontos por bota na malha do Ice Warrior) e o arredondamento dos números gravados.
const FOOT_WEIGHT: float = 0.9
const PITCHES: Array[float] = [-60.0, -45.0, -30.0, -20.0, -10.0, 0.0, 10.0, 20.0, 30.0, 45.0, 60.0]
const ROLLS: Array[float] = [-30.0, 0.0, 30.0]
const DECIMALS: float = 0.00001


## osso do pé -> lista de pontos [x, y, z] de apoio (espaço local do osso), pronta para o JSON. Use antes de gravar: a gravação libera o esqueleto do `Rig`.
static func points_of(surfs: Array[Source.Surf], assigned: Weights.Assigned, rig: Skel.Rig) -> Dictionary:
	var table: Dictionary = {}
	for bone_name: String in FOOT_BONES:
		var bone: int = rig.skeleton.find_bone(bone_name)
		var boot: PackedVector3Array = PackedVector3Array()
		for index: int in surfs.size() if bone >= 0 else 0:
			boot.append_array(heavy_vertices(surfs[index].positions, assigned.bones[index], assigned.weights[index], bone))
		table[bone_name] = support(boot, rig.bind[bone].affine_inverse() if bone >= 0 else Transform3D.IDENTITY)
	return table


## Os vértices (posição na malha) cujo peso somado no osso `bone` é de pelo menos FOOT_WEIGHT; `bones` e `weights` têm `Weights.SLOTS` entradas por vértice.
static func heavy_vertices(positions: PackedVector3Array, bones: PackedInt32Array, weights: PackedFloat32Array, bone: int) -> PackedVector3Array:
	var found: PackedVector3Array = PackedVector3Array()
	for vertex: int in positions.size():
		var weight: float = 0.0
		for slot: int in Weights.SLOTS:
			weight += weights[vertex * Weights.SLOTS + slot] if bones[vertex * Weights.SLOTS + slot] == bone else 0.0
		if weight >= FOOT_WEIGHT:
			found.append(positions[vertex])
	return found


## Os pontos de apoio de `vertices`: o mais baixo em cada direção de apoio (empate: o primeiro vértice), sem repetição e do mais baixo ao mais alto, em `to_local` (da malha para o espaço do osso) e arredondados a DECIMALS; [] se não há vértice.
static func support(vertices: PackedVector3Array, to_local: Transform3D) -> Array:
	var chosen: Dictionary[int, bool] = {}
	for pitch: float in PITCHES if not vertices.is_empty() else []:
		for roll: float in ROLLS:
			var down: Vector3 = Basis(Vector3.BACK, deg_to_rad(roll)) * Basis(Vector3.RIGHT, deg_to_rad(pitch)) * Vector3.DOWN
			var best: int = 0
			for index: int in vertices.size():
				best = index if vertices[index].dot(down) > vertices[best].dot(down) else best
			chosen[best] = true
	var ordered: Array[int] = chosen.keys()
	ordered.sort_custom(func(first: int, second: int) -> bool: return vertices[first].y < vertices[second].y)
	var points: Array = []
	for index: int in ordered:
		var local: Vector3 = to_local * vertices[index]
		points.append([snappedf(local.x, DECIMALS), snappedf(local.y, DECIMALS), snappedf(local.z, DECIMALS)])
	return points
