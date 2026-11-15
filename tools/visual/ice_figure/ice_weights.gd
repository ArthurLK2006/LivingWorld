extends RefCounted
## Pesos de pele do Ice Warrior (ferramenta de arte, fora do jogo). A geometria NÃO muda: só se acrescentam ossos e pesos à mesma malha.
## Ilhas RÍGIDAS (ombreiras, botas, cinto, espada, cabeça, bolsas, tiras) recebem peso 1 num osso. Ilhas de PANO ou de peça única grande (o tronco com os braços e as mãos, a saia/casaco, as pernas) recebem pesos SUAVES por vértice: inverso da distância (potência POWER) aos segmentos dos K_NEAREST ossos candidatos mais próximos, normalizados. Nos ossos da perna o peso cresce numa rampa com a queda abaixo do quadril (RAMP_M): na cintura a saia só acompanha a pélvis, senão a cintura rasga quando a coxa balança.
## Os papéis vêm de `ice_island_roles.json`, por índice de ilha, e cada linha é CONFERIDA contra a ilha (triângulos e posição do centroide): se a fonte for outra, `errors` diz qual ilha não bate. "~nome" = suave com o conjunto "nome" da tabela ("@" no osso vira o lado); nome de osso = rígido (sem sufixo, o lado vem do centroide); um alias (como `sword`) vira o osso da tabela. Ilha fora da tabela: osso mais próximo do centroide, entre o conjunto "auto".
## GANCHO PARA A 6d: `side_of` decide o lado de uma ilha ou de um ponto. Hoje é o sinal do X do centroide da ilha; o casaco por lado e a espada separada só trocam esta decisão e o destino do papel `sword`, sem mexer no resto.
const Source = preload("res://tools/visual/ice_figure/ice_source.gd")
const Skel = preload("res://tools/visual/ice_figure/ice_skeleton.gd")
const ROLES_PATH: String = "res://tools/visual/ice_figure/ice_island_roles.json"
const K_NEAREST: int = 3
const POWER: float = 2.0
const EPSILON_M: float = 0.004
const MIN_WEIGHT: float = 0.04
const RAMP_M: float = 0.12
const SLOTS: int = 4
const SOFT: String = "~"
const SIDE_MARK: String = "@"
const FALLBACK_BONE: String = "pelvis"
const AUTO_SET: String = "auto"
const MIN_SEGMENT_SQ: float = 0.0000001
const LEG_BONES: PackedStringArray = ["thigh", "calf", "foot"]


## Por superfície: 4 ossos e 4 pesos por vértice; `roles` é o papel final de cada ilha; `errors` são as linhas da tabela que não batem.
class Assigned:
	extends RefCounted
	var bones: Array[PackedInt32Array] = []
	var weights: Array[PackedFloat32Array] = []
	var roles: Dictionary[int, String] = {}
	var errors: PackedStringArray = PackedStringArray()


## Início e fim (pose de bind) do segmento de cada osso candidato e a altura do quadril.
class Segments:
	extends RefCounted
	var heads: Dictionary[String, Vector3] = {}
	var tails: Dictionary[String, Vector3] = {}
	var hip_y: float = 0.0


## Lê a tabela de papéis; vazia se faltar ou estiver malformada. O JSON é a fronteira de dados: o resultado do parser é Variant.
static func load_table(path: String = ROLES_PATH) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


## O lado ("_l" ou "_r") de uma ilha ou de um ponto dela; esquerdo = +X. Gancho da 6d.
static func side_of(_point: Vector3, island: Source.Island) -> String:
	return Skel.LEFT if island.center.x >= 0.0 else Skel.RIGHT


static func assign(surfs: Array[Source.Surf], found: Source.IslandSet, rig: Skel.Rig, table: Dictionary) -> Assigned:
	var segs: Segments = _segments(rig)
	var out: Assigned = Assigned.new()
	out.roles = _roles(found, rig, segs, table, out.errors)
	var sets: Dictionary = table["sets"]
	for surf: Source.Surf in surfs:
		var bones: PackedInt32Array = PackedInt32Array()
		var weights: PackedFloat32Array = PackedFloat32Array()
		bones.resize(surf.positions.size() * SLOTS)
		weights.resize(surf.positions.size() * SLOTS)
		for index: int in surf.positions.size():
			var id: int = found.of_vertex[surf.offset + index]
			var blend: Dictionary[String, float] = {FALLBACK_BONE: 1.0}
			if id >= 0 and out.roles[id].begins_with(SOFT):
				var side: String = side_of(surf.positions[index], found.list[id])
				blend = _blend(surf.positions[index], _candidates(sets, out.roles[id].trim_prefix(SOFT), side), segs)
			elif id >= 0:
				blend = {out.roles[id]: 1.0}
			var slot: int = 0
			for bone_name: String in blend:
				bones[index * SLOTS + slot] = rig.skeleton.find_bone(bone_name)
				weights[index * SLOTS + slot] = blend[bone_name]
				slot += 1
		out.bones.append(bones)
		out.weights.append(weights)
	return out


static func skin_of(rig: Skel.Rig) -> Skin:
	var skin: Skin = Skin.new()
	for bone: int in rig.skeleton.get_bone_count():
		skin.add_named_bind(rig.skeleton.get_bone_name(bone), rig.bind[bone].affine_inverse())
	return skin


static func _roles(found: Source.IslandSet, rig: Skel.Rig, segs: Segments, table: Dictionary, errors: PackedStringArray) -> Dictionary[int, String]:
	var rows: Dictionary[int, Dictionary] = {}
	for row: Dictionary in table["roles"]:
		rows[int(row["island"])] = row
		if int(row["island"]) >= found.list.size():
			errors.append("a tabela de papéis tem a ilha %d, mas a fonte só tem %d ilhas" % [int(row["island"]), found.list.size()])
	var aliases: Dictionary = table["aliases"]
	var roles: Dictionary[int, String] = {}
	for island: Source.Island in found.list:
		var role: String = ""
		if rows.has(island.id):
			role = rows[island.id]["role"]
			var wanted: Vector3 = Skel.vec(rows[island.id]["center_cm"]) * Skel.CM
			var apart_cm: float = wanted.distance_to(island.center) / Skel.CM
			if int(rows[island.id]["triangles"]) != island.tris or apart_cm > float(table["center_tolerance_cm"]):
				errors.append("a ilha %d não bate com a tabela de papéis: %d triângulos (tabela %d), centro a %.1f cm do esperado" % [island.id, island.tris, int(rows[island.id]["triangles"]), apart_cm])
		else:
			role = _nearest(island.center, _candidates(table["sets"], AUTO_SET, ""), segs)
		role = aliases.get(role, role)
		if not role.begins_with(SOFT) and rig.skeleton.find_bone(role) < 0:
			role += side_of(island.center, island)
		var known: bool = (table["sets"] as Dictionary).has(role.trim_prefix(SOFT)) if role.begins_with(SOFT) else rig.skeleton.find_bone(role) >= 0
		if not known:
			errors.append("a ilha %d tem um papel desconhecido: %s" % [island.id, role])
		roles[island.id] = role
	return roles


static func _candidates(sets: Dictionary, set_name: String, side: String) -> PackedStringArray:
	var names: PackedStringArray = PackedStringArray()
	for bone_name: String in sets[set_name]:
		names.append(bone_name.replace(SIDE_MARK, side))
	return names


static func _segments(rig: Skel.Rig) -> Segments:
	var segs: Segments = Segments.new()
	segs.hip_y = rig.origin("thigh" + Skel.LEFT).y
	for bone: int in rig.skeleton.get_bone_count():
		var bone_name: String = rig.skeleton.get_bone_name(bone)
		var side: String = Skel.side_suffix(bone_name)
		var base: String = bone_name.trim_suffix(side)
		if rig.tips.has(bone_name):
			segs.tails[bone_name] = rig.tips[bone_name]
		elif rig.axis_child.has(base):
			segs.tails[bone_name] = rig.origin(rig.axis_child[base] + side)
		else:
			continue
		segs.heads[bone_name] = rig.origin(bone_name)
	return segs


static func _nearest(point: Vector3, names: PackedStringArray, segs: Segments) -> String:
	var best: String = names[0]
	var best_distance: float = INF
	for bone_name: String in names:
		var distance: float = _distance(point, segs.heads[bone_name], segs.tails[bone_name])
		if distance < best_distance:
			best_distance = distance
			best = bone_name
	return best


## Pesos suaves de um ponto: inverso da distância aos segmentos candidatos, só os K_NEAREST maiores, sem pesos abaixo de MIN_WEIGHT, normalizados.
static func _blend(point: Vector3, names: PackedStringArray, segs: Segments) -> Dictionary[String, float]:
	var drop: float = clampf((segs.hip_y - point.y) / RAMP_M, 0.0, 1.0)
	var ramp: float = drop * drop * (3.0 - 2.0 * drop)
	var raw: Dictionary[String, float] = {}
	for bone_name: String in names:
		var weight: float = 1.0 / pow(_distance(point, segs.heads[bone_name], segs.tails[bone_name]) + EPSILON_M, POWER)
		raw[bone_name] = weight * ramp if LEG_BONES.has(bone_name.trim_suffix(Skel.side_suffix(bone_name))) else weight
	var keys: Array = raw.keys()
	keys.sort_custom(func(left: String, right: String) -> bool: return raw[left] > raw[right])
	var kept: Dictionary[String, float] = {}
	var total: float = 0.0
	for index: int in mini(K_NEAREST, keys.size()):
		kept[keys[index]] = raw[keys[index]]
		total += raw[keys[index]]
	if total <= 0.0:
		return {FALLBACK_BONE: 1.0}
	var result: Dictionary[String, float] = {}
	var second_total: float = 0.0
	for bone_name: String in kept:
		if kept[bone_name] / total >= MIN_WEIGHT:
			result[bone_name] = kept[bone_name]
			second_total += kept[bone_name]
	for bone_name: String in result:
		result[bone_name] /= second_total
	return result


static func _distance(point: Vector3, from: Vector3, to: Vector3) -> float:
	var along: Vector3 = to - from
	var t: float = clampf((point - from).dot(along) / maxf(along.length_squared(), MIN_SEGMENT_SQ), 0.0, 1.0)
	return point.distance_to(from + along * t)
