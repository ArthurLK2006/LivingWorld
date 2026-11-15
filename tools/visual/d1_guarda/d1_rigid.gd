extends RefCounted
## D1-A (estudo isolado): as peças RÍGIDAS do guarda, feitas com o PlazaMeshKit (por instância) em coordenadas do repouso do personagem (T-pose, pés no chão, de frente para +Z), cada uma indo para o osso indicado. `level` 0 = perto (mais placas e detalhes), 1 = longe.
const PETROL: Color = Color("2B7A8C")
const SLATE: Color = Color("7D9BA0")
const WINE_D: Color = Color("6A2E2C")
const WINE_L: Color = Color("8B4A3C")
const CREAM: Color = Color("D9CFB4")
const CHARCOAL: Color = Color("2A2C31")
const STEEL: Color = Color("A9B4B8")

var _kit: PlazaMeshKit = PlazaMeshKit.new()
var _out: Array[Dictionary] = []
var _tick: int = 0


func pieces(level: int) -> Array[Dictionary]:
	_out.clear()
	_kit.is_shaded = false
	for side: float in [1.0, -1.0]:
		var tag: String = "_l" if side > 0.0 else "_r"
		_pauldron(side, tag, 4 if level == 0 else 3)
		_boot(side, tag, level)
		if level == 0:
			_knee(side, tag)
	_tabard(5 if level == 0 else 3)
	_sword(level)
	if level == 0:
		_kit.frustum(Vector3.ZERO, 0.04, 0.04, 0.02, 6, STEEL)
		_emit("spine_01", Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0.0, 1.18, 0.146)))
		_slab(Vector3(0.0, 1.335, 0.128), Vector3(0.44, 0.05, 0.014), Basis(Vector3.BACK, atan2(-0.33, -0.29)), WINE_D)
		_emit("spine_03")
		_slab(Vector3(-0.225, 1.02, 0.03), Vector3(0.05, 0.11, 0.10), Basis.IDENTITY, WINE_D)
		_slab(Vector3(-0.225, 1.085, 0.03), Vector3(0.058, 0.04, 0.108), Basis.IDENTITY, WINE_L)
		_emit("pelvis")
	return _out


## Ombreira de placas escalonadas sobre o ombro (osso da clavícula): cada placa é uma lâmina na tangente de um arco.
func _pauldron(side: float, tag: String, plates: int) -> void:
	for k: int in plates:
		var phi: float = deg_to_rad(lerpf(100.0, 4.0, k / float(plates - 1)))
		var radius: float = 0.122 + 0.006 * k
		var center: Vector3 = Vector3(side * (0.20 + radius * cos(phi)), 1.45 + radius * sin(phi), -0.065)
		_slab(center, Vector3(0.15, 0.026, lerpf(0.22, 0.30, k / float(plates - 1))), Basis(Vector3.BACK, side * (phi - PI * 0.5)), SLATE.darkened(0.12 * (k % 2)))
	_emit("clavicle" + tag)


## Bota de cano dobrado: cano e aba (osso da perna) mais pé e sola (osso do pé).
func _boot(side: float, tag: String, level: int) -> void:
	var sides: int = 6 if level == 0 else 4
	_kit.frustum(Vector3.ZERO, 0.058, 0.073, 0.38, sides, WINE_D, 0.0, false)
	if level == 0:
		_kit.frustum(Vector3(0.0, 0.31, 0.0), 0.084, 0.094, 0.08, sides, WINE_L.lightened(0.15), 0.0, false)
	_emit("calf" + tag, Transform3D(Basis(Vector3.RIGHT, deg_to_rad(6.5)), Vector3(side * 0.091, 0.085, -0.088)))
	_slab(Vector3(side * 0.091, 0.065, 0.0275), Vector3(0.105, 0.07, 0.26), Basis.IDENTITY, WINE_D)
	_slab(Vector3(side * 0.091, 0.015, 0.0275), Vector3(0.115, 0.03, 0.30), Basis.IDENTITY, CHARCOAL)
	_emit("foot" + tag)


## Joelheira em três camadas escalonadas: a de cima na coxa, as duas de baixo na canela.
func _knee(side: float, tag: String) -> void:
	for layer: int in 3:
		_slab(Vector3(side * 0.091, 0.625 - 0.048 * layer, 0.068 - 0.012 * layer), Vector3(0.11 - 0.012 * layer, 0.052, 0.03), Basis(Vector3.RIGHT, deg_to_rad(-12.0 + 10.0 * layer)), SLATE.darkened(0.12 * layer))
		_emit(("thigh" if layer == 0 else "calf") + tag)


## Tabardo de tiras verticais com barra em ponta (creme, carvão e petróleo), penduradas do cinto; as tiras dos lados seguem a coxa.
func _tabard(strips: int) -> void:
	var width: float = 0.44 / strips
	for k: int in strips:
		var x: float = (k - (strips - 1) * 0.5) * width
		var front: Array[Vector3] = []
		var back: Array[Vector3] = []
		for corner: Vector2 in [Vector2(-0.45, 1.12), Vector2(0.45, 1.12), Vector2(0.45, 0.62), Vector2(0.0, 0.55), Vector2(-0.45, 0.62)]:
			var z: float = lerpf(0.098, 0.148, (corner.y - 0.62) / 0.5)
			front.append(Vector3(x + corner.x * width, corner.y, z + 0.007))
			back.append(Vector3(x + corner.x * width, corner.y, z - 0.007))
		var color: Color = [PETROL, CREAM, CHARCOAL][absi(k - (strips >> 1))]
		var inside: Vector3 = Vector3(x, 0.87, 0.123)
		for face: Array in [[0, 1, 2], [0, 2, 4], [4, 2, 3]]:
			_kit.tri(front[face[0]], front[face[1]], front[face[2]], _tone(color), inside)
			_kit.tri(back[face[0]], back[face[1]], back[face[2]], _tone(color), inside)
		for edge: int in 5:
			_kit.quad(front[edge], front[(edge + 1) % 5], back[(edge + 1) % 5], back[edge], _tone(color), inside)
		_emit("pelvis")
		if absf(x) > 0.02:
			_out[_out.size() - 1].merge({"bone2": "thigh_r" if x < 0.0 else "thigh_l", "y0": 1.12, "y1": 0.60})


## Espada grande e plana na mão direita: o braço solto do idle a deixa apontando para baixo e um pouco à frente.
func _sword(level: int) -> void:
	var dir: Vector3 = Vector3(-0.743, 0.0, 0.669)
	var normal: Vector3 = Vector3(0.669, 0.0, 0.743)
	var frame: Basis = Basis(dir, normal, dir.cross(normal))
	var grip: Vector3 = Vector3(-0.75, 1.45, -0.06)
	var parts: Array = [[0.085, 0.03, 0.045, 0.24, STEEL.darkened(0.3)], [0.55, 0.9, 0.02, 0.12, STEEL.darkened(0.12)]]
	if level == 0:
		parts.append_array([[-0.115, 0.04, 0.05, 0.05, CHARCOAL], [-0.01, 0.16, 0.034, 0.034, WINE_D]])
	for part: Array in parts:
		_slab(grip + dir * part[0], Vector3(part[1], part[2], part[3]), frame, part[4])
	var tip: Vector3 = grip + dir * 1.12
	var base: Array[Vector3] = [grip + dir * 1.0 + frame * Vector3(0.0, 0.01, 0.06), grip + dir * 1.0 + frame * Vector3(0.0, -0.01, 0.06), grip + dir * 1.0 + frame * Vector3(0.0, -0.01, -0.06), grip + dir * 1.0 + frame * Vector3(0.0, 0.01, -0.06)]
	for corner: int in 4:
		_kit.tri(base[corner], base[(corner + 1) % 4], tip, _tone(STEEL.darkened(0.12)), grip + dir * 0.9)
	_emit("hand_r")


func _slab(center: Vector3, size: Vector3, basis: Basis, color: Color) -> void:
	var corners: Array[Vector3] = []
	for index: int in 8:
		corners.append(center + basis * Vector3(size.x * (float(index & 1) - 0.5), size.y * (float((index >> 1) & 1) - 0.5), size.z * (float((index >> 2) & 1) - 0.5)))
	for first: int in range(0, PlazaMeshKit.BOX_QUADS.size(), 4):
		var quad: PackedInt32Array = PlazaMeshKit.BOX_QUADS.slice(first, first + 4)
		_kit.quad(corners[quad[0]], corners[quad[1]], corners[quad[2]], corners[quad[3]], _tone(color), center)


## Pequena variação de tom entre planos vizinhos (determinística, pelo hash do kit).
func _tone(color: Color) -> Color:
	_tick += 1
	var scale: float = PlazaMeshKit.between(_tick, 31, 0.94, 1.06)
	return Color(color.r * scale, color.g * scale, color.b * scale)


## Fecha a peça: leva os vértices do kit para o lugar (`placement`) e guarda para o osso.
func _emit(bone: String, placement: Transform3D = Transform3D.IDENTITY) -> void:
	var arrays: Array = _kit.finish(ArrayMesh.new(), null).surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var norms: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	for point: int in verts.size():
		verts[point] = placement * verts[point]
		norms[point] = placement.basis * norms[point]
	_out.append({"bone": bone, "v": verts, "n": norms, "c": arrays[Mesh.ARRAY_COLOR]})
