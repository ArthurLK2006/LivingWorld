extends RefCounted
## Gravação da versão PREPARADA do Ice Warrior (ferramenta de arte). Tudo vai para art_samples/ice_figure/, FORA do Git, enquanto Arthur avalia; nada em assets/. Grava: `ice_figure.scn` (raiz, `Skeleton3D` com os 65 ossos no repouso em T e a pose de bind, um `MeshInstance3D` com a malha do CORPO (até 2 superfícies), a `Skin` com os binds e os materiais com a paleta própria em filtro NEAREST, e a ESPADA, de entrega 6d: um `MeshInstance3D` de 1 superfície, sem pele, filho de um `BoneAttachment3D` do osso da mão), `ice_palette.png`, `ice_figure.json` (altura, fator para 1,80 m, os 65 ossos, a pose de bind de cada osso, o clipe de referência e os SHA-256) e `PROVENIENCIA.txt` (título como fornecido, origem da paleta, crédito CC BY 4.0 e a lista das mudanças).
## O esqueleto do `Rig` passa a pertencer à cena gravada e é LIBERADO aqui: não use o `Rig` depois de gravar.
## A pose gravada dos ossos é a de bind (a figura estática é a malha original); o REPOUSO (rest) é o T que o `CharacterRetarget` lê.
const Source = preload("res://tools/visual/ice_figure/ice_source.gd")
const Palette = preload("res://tools/visual/ice_figure/ice_palette.gd")
const Skel = preload("res://tools/visual/ice_figure/ice_skeleton.gd")
const Weights = preload("res://tools/visual/ice_figure/ice_weights.gd")
const OUT_DIR: String = "res://art_samples/ice_figure"
const SCENE_FILE: String = "ice_figure.scn"
const PALETTE_FILE: String = "ice_palette.png"
const DATA_FILE: String = "ice_figure.json"
const PROVENANCE_FILE: String = "PROVENIENCIA.txt"
const ROOT_NAME: String = "IceFigure"
const MESH_NAME: String = "IceMesh"
const ATTACHMENT_NODE: String = "SwordAttachment"
const SWORD_NODE: String = "Sword"
const BODY_M: float = 1.8
const CULL_MARGIN_M: float = 0.5
const REFERENCE_CLIP: String = "idle"
const DECIMALS: float = 0.000001
const AUTHOR_URL: String = "https://sketchfab.com/HaydzBooter"
const WORK_URL: String = "https://sketchfab.com/3d-models/icewarrior-lowpoly-character-6ab111d17c6a40ecbda2b782de7f6dad"
const LICENSE_URL: String = "http://creativecommons.org/licenses/by/4.0/"
const CREDIT: String = "Ice Warrior: HaydzBooter, CC BY 4.0, com alterações"
const TITLE: String = "IceWarrior - Lowpoly character"
const CHANGES: PackedStringArray = [
	"esqueleto de 65 ossos (mesmos nomes e hierarquia da UAL) e pesos de pele por regra; a malha NÃO foi editada (mesmas posições e índices; as normais só passam pela codificação de 16 bits do Godot, desvio de até 2,0e-4 contra o GLB original, 1,2e-4 contra a fonte já importada pelo Godot)",
	"paleta própria, gerada por script a partir das cores por face do original, no lugar da textura de 1024 px",
	"espada separada: a ilha da espada (ilha 3 do original, 456 triângulos) é uma malha PRÓPRIA de 1 superfície, filha de um BoneAttachment3D ligado ao osso da mão direita (hand_r), com a transformação local igual ao inverso da pose de bind da mão: na pose de bind ela fica exatamente onde estava e a geometria não muda (as posições e os índices do corpo e da espada, juntos, são os da fonte); a espada segue a mão como corpo rígido",
	"pesos do casaco por lado: a ilha do casaco (ilha 1) pesa PREDOMINANTEMENTE na coxa do próprio lado (a esquerda segue a coxa esquerda e a direita, a direita), com uma rampa linear de 25 cm de cada lado do plano do meio (a 10 cm do meio cerca de 30% do peso ainda segue a outra coxa, e na borda do casaco cerca de 8%), e a aba da frente à direita (ilha 18) pesa só na coxa direita; só os pesos mudam, a malha não",
	"escala para o corpo de 1,80 m (o fator está em ice_figure.json; a cena gravada fica na escala do arquivo)",
	"escala e posição embutidas nos vértices: a transformação dos nós do arquivo importado (escala 0,1104 = 0,01 de cm para m vezes 11,04 do nó Cube_001, mais a rotação e a posição dos nós) é aplicada aos vértices, e a malha desce 5,44 mm na vertical para os pés ficarem em y = 0; a escala é uniforme, as proporções não mudam",
]


## A cena preparada EM MEMÓRIA, sem gravar nada (os testes não tocam o disco): o corpo com pele e, se há equipamento, a espada presa ao osso da mão. O esqueleto do `Rig` passa a pertencer à cena e é LIBERADO aqui.
static func build_scene(surfs: Array[Source.Surf], found: Source.IslandSet, built: Palette.Built, assigned: Weights.Assigned, rig: Skel.Rig) -> PackedScene:
	var texture: ImageTexture = ImageTexture.create_from_image(built.image)
	var materials: Array[Material] = []
	for surf: Source.Surf in surfs:
		materials.append(Palette.material_for(surf.material, texture))
	var carried: PackedInt32Array = PackedInt32Array(assigned.equipment.keys())
	var carrier: String = "" if assigned.equipment.is_empty() else assigned.equipment.values()[0]
	var gear: Source.Subset = Source.subset(surfs, found, carried, true)
	return _scene(_mesh(Source.subset(surfs, found, carried, false), built, materials, assigned), rig, null if gear.surfs.is_empty() else _mesh(gear, built, materials), carrier)


## Grava a versão preparada em `dir` e devolve as mensagens de falha (vazio = gravou tudo).
static func write(dir: String, surfs: Array[Source.Surf], found: Source.IslandSet, built: Palette.Built, assigned: Weights.Assigned, rig: Skel.Rig, source_sha: String) -> PackedStringArray:
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir)) != OK:
		rig.skeleton.free()
		return PackedStringArray(["não consegui criar a pasta %s" % dir])
	var errors: PackedStringArray = PackedStringArray()
	var png_path: String = "%s/%s" % [dir, PALETTE_FILE]
	if built.image.save_png(png_path) != OK:
		errors.append("não consegui gravar %s" % png_path)
	var palette_sha: String = FileAccess.get_sha256(png_path)
	var data: Dictionary = _data(surfs, built, rig, palette_sha, source_sha)
	var carrier: String = "" if assigned.equipment.is_empty() else assigned.equipment.values()[0]
	for bone_name: String in assigned.equipment.values():
		if bone_name != carrier:
			errors.append("o equipamento separado precisa de um só osso (%s e %s)" % [carrier, bone_name])
	var scene: PackedScene = build_scene(surfs, found, built, assigned, rig)
	if ResourceSaver.save(scene, "%s/%s" % [dir, SCENE_FILE]) != OK:
		errors.append("não consegui gravar %s" % SCENE_FILE)
	errors.append_array(_save_text("%s/%s" % [dir, DATA_FILE], JSON.stringify(data, "\t") + "\n"))
	errors.append_array(_save_text("%s/%s" % [dir, PROVENANCE_FILE], provenance(source_sha, palette_sha, built, data["height_m"])))
	return errors


## Os 12 números de uma transformação: eixos x, y e z (3 cada) e a origem, arredondados a DECIMALS.
static func transform_numbers(transform: Transform3D) -> Array[float]:
	var numbers: Array[float] = []
	for vector: Vector3 in [transform.basis.x, transform.basis.y, transform.basis.z, transform.origin]:
		for value: float in [vector.x, vector.y, vector.z]:
			numbers.append(snappedf(value, DECIMALS))
	return numbers


## O texto de proveniência: título como fornecido (TITLE, o `extras.title` do GLB), origem da paleta (método, script e SHA-256), crédito e licença CC BY 4.0, SHA-256 do original e a lista das mudanças.
static func provenance(source_sha: String, palette_sha: String, built: Palette.Built, height_m: float) -> String:
	var lines: PackedStringArray = PackedStringArray([
		"Ice Warrior, versão preparada. FORA do Git: avaliação técnica e visual privada (15/11/2026); não redistribuir nem publicar sem aceite expresso.",
		CREDIT,
		"Título: %s (como fornecido no original)" % TITLE,
		"Autor: HaydzBooter (%s)" % AUTHOR_URL,
		"Obra original: %s" % WORK_URL,
		"Licença: CC BY 4.0 (%s)" % LICENSE_URL,
		"SHA-256 do original (IceWarrior.glb): %s" % source_sha,
		"",
		"ORIGEM DA PALETA (ice_palette.png, SHA-256 %s):" % palette_sha,
		"- método: cada cor é a cor amostrada no centro da UV de cada face do original (média das UVs dos vértices da face); a imagem original varia dentro de algumas faces e a fidelidade total foi medida por render; a imagem original só foi lida para obter essas cores e NÃO é usada na versão preparada",
		"- grade de células de %d px, uma por cor única (%d cores, imagem de %d px), em ordem crescente de cor; as UVs de cada face apontam para o centro da célula da sua cor; filtro NEAREST" % [Palette.CELL_PX, built.colors.size(), built.image.get_width()],
		"- script: tools/visual/ice_figure/ice_palette.gd, chamado por tools/visual/ice_figure/ice_prepare.gd (determinístico: a mesma fonte dá o mesmo arquivo)",
		"- escala: altura do corpo %.4f m na malha; fator %.4f para %.2f m" % [height_m, BODY_M / height_m, BODY_M],
		"",
		"MUDANÇAS em relação ao original:",
	])
	for change: String in CHANGES:
		lines.append("- " + change)
	return "\n".join(lines) + "\n"


## A malha de um subconjunto, com os UVs da paleta e o material de cada superfície de origem; com `assigned`, também ossos e pesos (o corpo); sem ele, rígida (a espada).
static func _mesh(part: Source.Subset, built: Palette.Built, materials: Array[Material], assigned: Weights.Assigned = null) -> ArrayMesh:
	var picked: Array[Material] = []
	for source: int in part.from_surface:
		picked.append(materials[source])
	var uvs: Array[PackedVector2Array] = []
	uvs.assign(part.pick(built.uvs))
	if assigned == null:
		return Source.mesh_of(part.surfs, uvs, picked)
	var bones: Array[PackedInt32Array] = []
	bones.assign(part.pick(assigned.bones, Weights.SLOTS))
	var weights: Array[PackedFloat32Array] = []
	weights.assign(part.pick(assigned.weights, Weights.SLOTS))
	return Source.mesh_of(part.surfs, uvs, picked, bones, weights)


## A espada em malha PRÓPRIA (sem pele), filha de um `BoneAttachment3D` do osso que a segura; a transformação local é o inverso da pose de bind desse osso (a mesma conta da `Skin`): na pose de bind a espada fica exatamente onde estava na malha original e, com o osso em movimento, segue rígida a ele.
static func _attach(root: Node3D, rig: Skel.Rig, sword: ArrayMesh, bone_name: String) -> void:
	var carrier: BoneAttachment3D = BoneAttachment3D.new()
	carrier.name = ATTACHMENT_NODE
	carrier.bone_name = bone_name
	rig.skeleton.add_child(carrier)
	var blade: MeshInstance3D = MeshInstance3D.new()
	blade.name = SWORD_NODE
	blade.mesh = sword
	blade.transform = rig.bind[rig.skeleton.find_bone(bone_name)].affine_inverse()
	carrier.add_child(blade)
	carrier.owner = root
	blade.owner = root


static func _scene(mesh: ArrayMesh, rig: Skel.Rig, sword: ArrayMesh, carrier: String) -> PackedScene:
	var root: Node3D = Node3D.new()
	root.name = ROOT_NAME
	rig.skeleton.name = CharacterRetarget.SKELETON_NODE
	root.add_child(rig.skeleton)
	for bone: int in rig.skeleton.get_bone_count():
		var local: Transform3D = rig.bind_local(bone)
		rig.skeleton.set_bone_pose_position(bone, local.origin)
		rig.skeleton.set_bone_pose_rotation(bone, local.basis.get_rotation_quaternion())
	var holder: MeshInstance3D = MeshInstance3D.new()
	holder.name = MESH_NAME
	holder.mesh = mesh
	holder.skin = Weights.skin_of(rig)
	holder.extra_cull_margin = CULL_MARGIN_M
	rig.skeleton.add_child(holder)
	holder.skeleton = NodePath("..")
	rig.skeleton.owner = root
	holder.owner = root
	if sword != null:
		_attach(root, rig, sword, carrier)
	var scene: PackedScene = PackedScene.new()
	scene.pack(root)
	root.free()
	return scene


static func _data(surfs: Array[Source.Surf], built: Palette.Built, rig: Skel.Rig, palette_sha: String, source_sha: String) -> Dictionary:
	var height: float = 0.0
	var triangles: int = 0
	for surf: Source.Surf in surfs:
		triangles += surf.triangles()
		for point: Vector3 in surf.positions:
			height = maxf(height, point.y)
	var names: Array[String] = []
	var poses: Dictionary = {}
	for bone: int in rig.skeleton.get_bone_count():
		names.append(rig.skeleton.get_bone_name(bone))
		poses[names[bone]] = transform_numbers(rig.bind[bone])
	return {
		"version": 1, "figure": "ice_warrior", "credit": CREDIT, "reference_clip": REFERENCE_CLIP,
		"height_m": snappedf(height, DECIMALS), "body_m": BODY_M, "scale_to_body": snappedf(BODY_M / height, DECIMALS),
		"surfaces": surfs.size(), "triangles": triangles, "bones": names,
		"bind_pose_order": "x_axis(3), y_axis(3), z_axis(3), origin(3); global, em metros do arquivo, pés em y = 0",
		"bind_pose": poses,
		"palette": {"file": PALETTE_FILE, "sha256": palette_sha, "cell_px": Palette.CELL_PX, "colors": built.colors.size(), "size_px": built.image.get_width()},
		"source": {"file": "IceWarrior.glb", "sha256": source_sha},
	}


static func _save_text(path: String, text: String) -> PackedStringArray:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return PackedStringArray(["não consegui gravar %s" % path])
	file.store_string(text)
	return PackedStringArray()
