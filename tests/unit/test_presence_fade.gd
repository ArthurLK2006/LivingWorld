extends GutTest
## LW-099d: a dissolução de 0,4 s, sem janela. As curvas de `PresenceFade` (linear, presa entre 0 e 1), a propriedade `transparency` em TODO descendente `GeometryInstance3D` (qualquer profundidade, e na própria raiz), e o `NpcView.set_fade` na cápsula, no
## nariz e na figura. O corpo reaproveitado da reserva NUNCA volta transparente (`attach`, `detach`, `clear_figure` e `give_back`). Só se confere o VALOR da propriedade; como a transparência aparece (e as sombras) é da janela de Arthur.

const EPS: float = 0.0001


func _geometry(root: Node, found: Array[GeometryInstance3D] = []) -> Array[GeometryInstance3D]:
	if root is GeometryInstance3D:
		found.append(root as GeometryInstance3D)
	for child: Node in root.get_children():
		_geometry(child, found)
	return found


func _values(root: Node) -> Array[float]:
	var values: Array[float] = []
	for part: GeometryInstance3D in _geometry(root):
		values.append(part.transparency)
	return values


## Todos os valores estão a `EPS` de `expected` (a propriedade guarda 32 bits: 0,8 volta como 0,80000001).
func _all_near(values: Array[float], expected: float, count: int) -> bool:
	for value: float in values:
		if absf(value - expected) > EPS:
			return false
	return values.size() == count


func _figure() -> Node3D:
	var figure: Node3D = Node3D.new()
	var skin: Node3D = Node3D.new()
	figure.add_child(skin)
	skin.add_child(MeshInstance3D.new())
	figure.add_child(MeshInstance3D.new())
	return figure


func test_the_curves_are_linear_clamped_and_complementary() -> void:
	assert_eq(PresenceFade.DURATION_S, 0.4, "a duração escolhida por Arthur: cerca de 0,4 s")
	assert_eq([PresenceFade.in_amount(0.0), PresenceFade.in_amount(PresenceFade.DURATION_S), PresenceFade.in_amount(9.0), PresenceFade.in_amount(INF)], [1.0, 0.0, 0.0, 0.0], "quem aparece vai de 1 a 0 e fica em 0")
	assert_eq([PresenceFade.out_amount(0.0), PresenceFade.out_amount(PresenceFade.DURATION_S), PresenceFade.out_amount(9.0), PresenceFade.out_amount(INF)], [0.0, 1.0, 1.0, 1.0], "quem some vai de 0 a 1 e fica em 1")
	assert_eq([PresenceFade.in_amount(-3.0), PresenceFade.out_amount(-3.0), PresenceFade.in_amount(NAN), PresenceFade.out_amount(NAN)], [1.0, 0.0, 1.0, 0.0], "tempo negativo e NaN valem 0 s")
	assert_almost_eq(PresenceFade.in_amount(0.1), 0.75, EPS, "linear: a um quarto do tempo, um quarto do caminho")
	assert_almost_eq(PresenceFade.out_amount(0.2), 0.5, EPS, "e na metade, a metade")
	var previous_in: float = 2.0
	var previous_out: float = -1.0
	for step: int in 61:
		var elapsed: float = float(step) * 0.01
		assert_lte(PresenceFade.in_amount(elapsed), previous_in, "quem aparece nunca volta atrás")
		assert_gte(PresenceFade.out_amount(elapsed), previous_out, "quem some nunca volta atrás")
		assert_almost_eq(PresenceFade.in_amount(elapsed) + PresenceFade.out_amount(elapsed), 1.0, EPS, "as duas curvas somam 1 (dissolução cruzada)")
		previous_in = PresenceFade.in_amount(elapsed)
		previous_out = PresenceFade.out_amount(elapsed)


func test_apply_reaches_every_geometry_at_any_depth_and_the_root_and_clamps() -> void:
	var root: MeshInstance3D = MeshInstance3D.new()
	var mid: Node3D = Node3D.new()
	var deep: MeshInstance3D = MeshInstance3D.new()
	var deeper: Label3D = Label3D.new()
	root.add_child(mid)
	mid.add_child(deep)
	deep.add_child(deeper)
	root.add_child(Node3D.new())
	add_child_autofree(root)
	PresenceFade.apply(root, 0.6)
	assert_eq(_values(root).size(), 3, "a raiz, o neto e o bisneto são geometria")
	for value: float in _values(root):
		assert_almost_eq(value, 0.6, EPS, "todos recebem o mesmo valor")
	PresenceFade.apply(root, 7.0)
	assert_eq(_values(root), [1.0, 1.0, 1.0] as Array[float], "acima de 1 vale 1")
	PresenceFade.apply(root, -2.0)
	assert_eq(_values(root), [0.0, 0.0, 0.0] as Array[float], "abaixo de 0 vale 0")
	PresenceFade.apply(root, 0.3)
	PresenceFade.apply(root, NAN)
	PresenceFade.apply(null, 0.5)
	for value: float in _values(root):
		assert_almost_eq(value, 0.3, EPS, "NaN e raiz nula não mudam nada")
	var plain: Node3D = Node3D.new()
	var mesh: MeshInstance3D = MeshInstance3D.new()
	var shared: BoxMesh = BoxMesh.new()
	mesh.mesh = shared
	plain.add_child(mesh)
	add_child_autofree(plain)
	PresenceFade.apply(plain, 0.5)
	assert_almost_eq(mesh.transparency, 0.5, EPS, "raiz que não é geometria: os filhos recebem")
	assert_same(mesh.mesh, shared, "a transparência é da instância: a malha (e o material) não são trocados")


func test_set_fade_dissolves_the_capsule_the_nose_and_the_figure_together() -> void:
	var view: NpcView = NpcView.new()
	add_child_autofree(view)
	assert_eq([view.fade(), _values(view)], [0.0, [0.0, 0.0] as Array[float]], "o corpo nasce opaco: cápsula e nariz")
	view.position = Vector3(3.0, 1.0, 2.0)
	view.set_fade(0.5)
	assert_eq([view.fade(), _values(view)], [0.5, [0.5, 0.5] as Array[float]], "cápsula e nariz")
	var figure: Node3D = _figure()
	view.attach_figure(figure)
	assert_eq(_values(view), [0.5, 0.5, 0.5, 0.5] as Array[float], "a figura que entra com o corpo já meio dissolvido nasce igual (dois meshes aninhados)")
	view.set_fade(0.8)
	assert_true(_all_near(_values(view), 0.8, 4), "cápsula, nariz e a figura inteira (dois meshes aninhados)")
	view.set_fade(2.0)
	assert_eq(view.fade(), 1.0, "preso em 1")
	view.set_fade(NAN)
	assert_eq(view.fade(), 1.0, "NaN é ignorado")
	assert_eq([view.visible, view.position], [true, Vector3(3.0, 1.0, 2.0)], "só a transparência muda: nem `visible` nem a posição")


func test_a_recycled_body_never_comes_back_transparent() -> void:
	var parent: Node3D = Node3D.new()
	add_child_autofree(parent)
	var pool: NpcViewPool = NpcViewPool.new(parent, 2)
	var view: NpcView = pool.take(7, Vector3(1.0, 2.0, 3.0))
	view.attach_figure(_figure())
	view.set_fade(0.7)
	assert_true(pool.give_back(7), "o corpo volta à reserva no meio da dissolução")
	assert_eq([view.fade(), _values(view)], [0.0, [0.0, 0.0] as Array[float]], "o `give_back` (o `detach`) volta a cápsula a opaca e solta a figura")
	var again: NpcView = pool.take(8, Vector3.ZERO)
	assert_same(again, view, "o pedido seguinte reaproveita o mesmo corpo")
	assert_eq([again.fade(), _values(again)], [0.0, [0.0, 0.0] as Array[float]], "e ele sai opaco")
	again.set_fade(0.9)
	again.attach(9, Vector3.ZERO)
	assert_eq([again.fade(), _values(again)], [0.0, [0.0, 0.0] as Array[float]], "`attach` também volta a opaco")
	again.set_fade(0.4)
	again.clear_figure()
	assert_eq(again.fade(), 0.0, "`clear_figure` também")
	again.set_fade(0.4)
	again.detach()
	assert_eq([again.fade(), _values(again), again.visible], [0.0, [0.0, 0.0] as Array[float], false], "`detach` também (e o corpo fica escondido)")
	await wait_process_frames(1)
