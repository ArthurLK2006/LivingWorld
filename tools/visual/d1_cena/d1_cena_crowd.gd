class_name D1CenaCrowd
extends RefCounted
## D1-C (estudo isolado, nada entra no jogo): os habitantes da praça da cena integrada, nos MESMOS lugares dos dois lados de cada par. Um habitante é "capsule" (o NpcView, a cápsula que o jogo mostra hoje), "orig" (o personagem Quaternius original, montado pelo CharacterAssembler), "near" (o guarda facetado do D1-A, PERTO, 4.326 triângulos) ou "far" (LONGE, 1.176). A receita do guarda e as constantes vêm de tools/visual/d1_guarda/d1_main.gd (D1-A).

const Guard = preload("res://tools/visual/d1_guarda/d1_main.gd")
const WALK_CLIP: String = "walk"
const IDLE_CLIP: String = "idle"
const POSE_BASE_S: float = 0.35
const POSE_STEP_S: float = 0.13
const POSE_PHASES: int = 7
const YAW_STEP_DEG: int = 137
const FULL_TURN_DEG: int = 360
## Grade da medição: passo (m), centro, raio livre em volta do poço e a linha das barracas (só z maior que ela).
const GRID_STEP_M: float = 2.0
const GRID_CENTER: Vector2 = Vector2(0.0, 3.0)
const WELL_CLEAR_M: float = 2.3
const STALLS_Z_M: float = -2.5
const GRID_ROWS: Vector2i = Vector2i(-2, 5)
const GRID_COLUMNS: Vector2i = Vector2i(-4, 5)
## Pontos da captura (x, z em m, giro em graus com 0 = olhando para a câmera e 1 = andando no quarto valor): os dois primeiros são os PERTO (junto do poço e diante da barraca do meio, em (0, -6)); os dez seguintes, os LONGE espalhados pela praça, nenhum a menos de 7 m da câmera próxima (0, 2,5, 4,9), para o LONGE não aparecer onde o jogo mostraria o PERTO.
const SPOTS: Array[Vector4] = [
	Vector4(-1.6, 1.4, 30.0, 0.0), Vector4(1.0, -3.7, 20.0, 0.0),
	Vector4(-3.6, -2.0, 150.0, 0.0), Vector4(4.4, -3.4, -120.0, 1.0), Vector4(-1.0, -3.4, 200.0, 1.0), Vector4(2.6, -1.2, -60.0, 1.0), Vector4(-6.8, 2.6, 70.0, 0.0),
	Vector4(6.8, 3.4, 250.0, 1.0), Vector4(-7.4, -1.2, 100.0, 0.0), Vector4(7.2, -0.6, -100.0, 1.0), Vector4(-3.8, 6.6, 140.0, 0.0), Vector4(4.0, 7.4, 210.0, 1.0),
]
## Cenários: variante da praça (D1MundoOptions), quantos habitantes, onde (`spots` = os pontos fixos; falso = a grade), quantos são PERTO e o tipo de cada grupo. atual/nova são os pares da captura; i a iv, a medição.
const SCENARIOS: Dictionary[String, Dictionary] = {
	"atual": {"variant": "a", "count": 12, "spots": true, "near": 2, "near_kind": "capsule", "far_kind": "capsule"},
	"nova": {"variant": "d", "count": 12, "spots": true, "near": 2, "near_kind": "near", "far_kind": "far"},
	"i": {"variant": "a", "count": 25, "spots": false, "near": 0, "near_kind": "capsule", "far_kind": "capsule"},
	"ii": {"variant": "a", "count": 25, "spots": false, "near": 0, "near_kind": "orig", "far_kind": "orig"},
	"iii": {"variant": "d", "count": 25, "spots": false, "near": 5, "near_kind": "near", "far_kind": "far"},
	"iv": {"variant": "d", "count": 50, "spots": false, "near": 0, "near_kind": "near", "far_kind": "far"},
}


## Cria o grupo "Crowd" sob `scene` com os habitantes do cenário. `animated` falso = pose parada (a captura); verdadeiro = andando e respirando de verdade (a medição).
static func populate(scene: Node3D, scenario: Dictionary, animated: bool) -> Node3D:
	var crowd: Node3D = Node3D.new()
	crowd.name = "Crowd"
	scene.add_child(crowd)
	var templates: Dictionary[String, Node3D] = {}
	var plan: Array[Vector4] = spots(int(scenario["count"]), bool(scenario["spots"]))
	for index: int in plan.size():
		var kind: String = scenario["near_kind"] if index < int(scenario["near"]) else scenario["far_kind"]
		var spot: Vector4 = plan[index]
		var actor: Node3D = _actor(kind, templates)
		var feet: Vector3 = Vector3(spot.x, PlazaGround.ground_height(spot.x, spot.y), spot.y)
		crowd.add_child(actor)
		if actor is NpcView:
			(actor as NpcView).attach(index, feet)
			(actor as NpcView).set_walking(spot.w > 0.5)
			actor.rotation.y = deg_to_rad(spot.z) + PI
		else:
			actor.position = feet
			actor.rotation.y = deg_to_rad(spot.z)
			_animate(actor, spot.w > 0.5, index, animated)
	for template: Node3D in templates.values():
		template.free()
	return crowd


## Os pontos dos habitantes: os `SPOTS` fixos ou, na grade, os `count` mais perto do centro (fora do poço e das barracas), andando e parados alternados.
static func spots(count: int, fixed: bool) -> Array[Vector4]:
	if fixed:
		return SPOTS.slice(0, count)
	var cells: Array[Vector4] = []
	for row: int in range(GRID_ROWS.x, GRID_ROWS.y):
		for column: int in range(GRID_COLUMNS.x, GRID_COLUMNS.y):
			var at: Vector2 = GRID_CENTER + Vector2(column, row) * GRID_STEP_M
			if at.length() > WELL_CLEAR_M and at.y > STALLS_Z_M:
				cells.append(Vector4(at.x, at.y, float((cells.size() * YAW_STEP_DEG) % FULL_TURN_DEG), float(cells.size() % 2)))
	cells.sort_custom(func(a: Vector4, b: Vector4) -> bool: return Vector2(a.x, a.y).distance_to(GRID_CENTER) < Vector2(b.x, b.y).distance_to(GRID_CENTER))
	return cells.slice(0, count)


static func _actor(kind: String, templates: Dictionary[String, Node3D]) -> Node3D:
	if kind == "capsule":
		return NpcView.new()
	if not templates.has(kind):
		templates[kind] = _guard(kind)
	return templates[kind].duplicate()


## Anda ou respira (animado) ou fica numa pose parada que muda de um habitante para o outro.
static func _animate(actor: Node3D, walking: bool, index: int, animated: bool) -> void:
	var player: AnimationPlayer = actor.find_children("*", "AnimationPlayer", true, false)[0]
	player.play(WALK_CLIP if walking else IDLE_CLIP)
	player.seek(POSE_BASE_S + POSE_STEP_S * float(index % POSE_PHASES), true)
	if not animated:
		player.pause()


## O guarda de uma versão ("orig", "near" ou "far"), como o `_character` do D1-A: o montador do ramo da 4a (homem, Ranger sem o capuz, cabelo curto e barba acoplada) e, nas facetadas, a malha única no lugar das malhas do catálogo.
static func _guard(version: String) -> Node3D:
	var look: CharacterAppearance = CharacterAppearance.new()
	look.body_id = "male_a"
	look.outfit_id = "ranger_m"
	look.hair_id = "buzzed"
	look.eyebrow_id = "brow_regular"
	var assembler: CharacterAssembler = CharacterAssembler.new()
	assembler.build(look, CharacterCatalog.from_file().catalog)
	assembler.swap_part("extra_0", "")
	assembler.swap_part("beard", Guard.BEARD)
	if version != "orig":
		for slot: String in Guard.SLOTS:
			assembler.swap_part(slot, "")
		var node: MeshInstance3D = MeshInstance3D.new()
		node.mesh = load(Guard.MESH_DIR + "guard_%s.res" % version)
		node.skin = load(Guard.MESH_DIR + "guard_skin.res")
		CharacterSceneLoader.skeleton_of(assembler).add_child(node)
		node.skeleton = NodePath("..")
	return assembler
