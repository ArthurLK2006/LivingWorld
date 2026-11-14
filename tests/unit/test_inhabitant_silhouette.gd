extends GutTest

## ART-9d, protótipo isolado dos habitantes (sem renderizar): a SILHUETA de cada papel é diferente (aldeão = pera de ombro caído, comerciante = sino, guarda = trapézio de ombros largos), medida pela largura por fatia de altura (extensão em x dos vértices de cada décimo da altura, em fração da altura) e pela proporção da caixa; a diferença entre quaisquer dois papéis tem de passar de um limite, e a de ids do mesmo papel fica abaixo dela.
const SLICES: int = 10
const SAMPLE_IDS: int = 8
const MIN_ROLE_GAP: float = 0.05
const MIN_BOX_GAP: float = 0.04
const MIN_GUARD_TALLER_M: float = 0.1


func _curve(mesh: ArrayMesh) -> Array[float]:
	var height: float = mesh.get_aabb().size.y
	var low: Array[float] = []
	var high: Array[float] = []
	for slice: int in SLICES:
		low.append(1000.0)
		high.append(-1000.0)
	for vertex: Vector3 in mesh.get_faces():
		var index: int = clampi(int(vertex.y / height * SLICES), 0, SLICES - 1)
		low[index] = minf(low[index], vertex.x)
		high[index] = maxf(high[index], vertex.x)
	var curve: Array[float] = []
	for slice: int in SLICES:
		curve.append(maxf(high[slice] - low[slice], 0.0) / height)
	return curve


## A curva média de largura por fatia de um papel e a altura média (m).
func _profile(role: StringName) -> Dictionary:
	var mean: Array[float] = []
	for slice: int in SLICES:
		mean.append(0.0)
	var heights: float = 0.0
	var aspects: float = 0.0
	for id: int in range(1, SAMPLE_IDS + 1):
		var mesh: ArrayMesh = InhabitantBuilder.build(InhabitantSpec.for_inhabitant(id, role), InhabitantBuilder.LOD_NEAR)
		var curve: Array[float] = _curve(mesh)
		for slice: int in SLICES:
			mean[slice] += curve[slice] / SAMPLE_IDS
		heights += mesh.get_aabb().size.y / SAMPLE_IDS
		aspects += mesh.get_aabb().size.x / mesh.get_aabb().size.y / SAMPLE_IDS
	return {"curve": mean, "height": heights, "aspect": aspects}


func _gap(first: Array[float], second: Array[float]) -> float:
	var total: float = 0.0
	for slice: int in SLICES:
		total += absf(first[slice] - second[slice])
	return total / SLICES


func test_roles_have_clearly_different_silhouettes() -> void:
	var profiles: Dictionary = {}
	for role: StringName in InhabitantSpec.ROLES:
		profiles[role] = _profile(role)
	var roles: Array[StringName] = InhabitantSpec.ROLES
	for first: int in roles.size():
		for second: int in range(first + 1, roles.size()):
			var gap: float = _gap(profiles[roles[first]]["curve"], profiles[roles[second]]["curve"])
			assert_gt(gap, MIN_ROLE_GAP, "silhueta de %s x %s: largura por fatia de altura" % [roles[first], roles[second]])
			gut.p("diferença de silhueta %s x %s: %.3f (limite %.2f); proporção da caixa %.2f x %.2f" % [roles[first], roles[second], gap, MIN_ROLE_GAP, profiles[roles[first]]["aspect"], profiles[roles[second]]["aspect"]])
	assert_gt(absf(float(profiles[InhabitantSpec.GUARD]["aspect"]) - float(profiles[InhabitantSpec.VILLAGER]["aspect"])), MIN_BOX_GAP, "proporção da caixa: guarda x aldeão")
	assert_gt(float(profiles[InhabitantSpec.GUARD]["height"]) - float(profiles[InhabitantSpec.VILLAGER]["height"]), MIN_GUARD_TALLER_M, "o guarda é mais alto")


## Onde cada papel é mais largo: o aldeão na barriga (fatia de baixo), o comerciante na barra e o guarda nos ombros (fatia de cima).
func test_widest_slice_differs_by_role() -> void:
	var widest: Dictionary = {}
	for role: StringName in InhabitantSpec.ROLES:
		var curve: Array[float] = _profile(role)["curve"]
		widest[role] = curve.find(curve.max())
	assert_gt(widest[InhabitantSpec.GUARD], widest[InhabitantSpec.VILLAGER], "o guarda é mais largo mais acima que o aldeão")
	assert_gt(widest[InhabitantSpec.GUARD], widest[InhabitantSpec.MERCHANT], "o guarda é mais largo mais acima que o comerciante")


func test_silhouette_is_deterministic() -> void:
	for role: StringName in InhabitantSpec.ROLES:
		var spec: InhabitantSpec = InhabitantSpec.for_inhabitant(11, role)
		assert_eq(_curve(InhabitantBuilder.build(spec, InhabitantBuilder.LOD_NEAR)), _curve(InhabitantBuilder.build(spec, InhabitantBuilder.LOD_NEAR)), "mesma silhueta de %s" % role)
