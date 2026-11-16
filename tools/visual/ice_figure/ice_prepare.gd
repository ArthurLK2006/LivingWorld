extends SceneTree
## Ferramenta de preparo do Ice Warrior (ferramenta de arte, fora do jogo): lê o original, confere que é a fonte esperada, gera a paleta própria, o esqueleto e os pesos e grava a versão preparada em art_samples/ice_figure/ (FORA do Git). Sem janela:
## godot --headless --path <projeto> -s res://tools/visual/ice_figure/ice_prepare.gd
## Termina com código 1 e a mensagem se algo não bate (fonte diferente, tabela que não bate com as ilhas, paleta que não cabe).
## OPÇÕES (6e; sem elas a saída é a de sempre), depois do `--`: `--damping` grava o campo `damping` com a tabela `ice_damping.json` (ou `--damping=<arquivo>`: um JSON osso -> fator de 0 a 1); `--contact` grava `ground_points`, os pontos de contato das botas medidos na malha (`ice_contact.gd`); `--meta=<nome>` grava o JSON com esse nome (a variante), no lugar de `ice_figure.json`. A variante B (só amortecimento) é `--damping=<tabela com os pés>`; a C (recomendada) é `--damping --contact`. `--symmetric` (6h) grava `symmetric_reference` (`SYMMETRIC_PARTS`: coxa, canela, pé e base do pé), a referência simétrica das pernas, para corrigir o passo manco (o `Idle` da UAL tem uma perna à frente); a variante G (a corrigida) é `--damping --contact --symmetric`. `--jog` (6j) grava `"jog": true`: a figura ganha também o clipe de corrida `jog` (a trava de chão SÓ DE PISO, montado pelo `CharacterFigure`); `--locomotion` (7a) grava `locomotion` com a tabela `ice_locomotion.json` (clipe -> m/s em que o pé de apoio fica colado ao chão: `walk` 0,73 e `jog` 4,1, [medido] no estudo local de 16/11/2026 com a figura de 1,8 m; os scripts dessa medição NÃO estão no repositório) e exige `--jog`, porque a tabela tem `jog`; a variante final do Ice Warrior é `--damping --contact --symmetric --jog --locomotion`.
const Source = preload("res://tools/visual/ice_figure/ice_source.gd")
const Palette = preload("res://tools/visual/ice_figure/ice_palette.gd")
const Skel = preload("res://tools/visual/ice_figure/ice_skeleton.gd")
const Weights = preload("res://tools/visual/ice_figure/ice_weights.gd")
const Writer = preload("res://tools/visual/ice_figure/ice_writer.gd")
const Contact = preload("res://tools/visual/ice_figure/ice_contact.gd")
const DAMPING_ARG: String = "--damping"
const CONTACT_ARG: String = "--contact"
const SYMMETRIC_ARG: String = "--symmetric"
const JOG_ARG: String = "--jog"
const LOCOMOTION_ARG: String = "--locomotion"
## Os prefixos dos pares de ossos `<parte>_l` e `<parte>_r` das pernas cuja referência `--symmetric` simetriza.
const SYMMETRIC_PARTS: Array[String] = ["thigh", "calf", "foot", "ball"]
const DAMPING_FILE: String = "res://tools/visual/ice_figure/ice_damping.json"
const LOCOMOTION_FILE: String = "res://tools/visual/ice_figure/ice_locomotion.json"


func _initialize() -> void:
	var errors: PackedStringArray = _prepare()
	for line: String in errors:
		print("FALHA: %s" % line)
	quit(1 if not errors.is_empty() else 0)


func _prepare() -> PackedStringArray:
	var option_errors: PackedStringArray = _locomotion_errors(OS.get_cmdline_user_args())
	if not option_errors.is_empty():
		return option_errors
	if not FileAccess.file_exists(Source.SOURCE_PATH):
		return PackedStringArray(["fonte ausente (fica fora do Git): %s" % Source.SOURCE_PATH])
	var table: Dictionary = Weights.load_table()
	var landmarks: Dictionary = Skel.load_landmarks()
	if table.is_empty() or landmarks.is_empty():
		return PackedStringArray(["tabela de papéis ou de articulações ausente ou malformada"])
	var source_sha: String = FileAccess.get_sha256(Source.SOURCE_PATH)
	if source_sha != table["source"]["sha256"]:
		return PackedStringArray(["fonte inesperada: SHA-256 %s (esperado %s)" % [source_sha, table["source"]["sha256"]]])
	var surfs: Array[Source.Surf] = Source.load_surfaces()
	var found: Source.IslandSet = Source.islands(surfs)
	var errors: PackedStringArray = Source.validate(surfs, found)
	if not errors.is_empty():
		return errors
	var images: Array[Image] = []
	for surf: Source.Surf in surfs:
		images.append(Palette.image_of(surf.material))
	var built: Palette.Built = Palette.build(surfs, images)
	if not built.error.is_empty():
		return PackedStringArray([built.error])
	var rig: Skel.Rig = Skel.build(CharacterCatalog.from_file().catalog, landmarks)
	var assigned: Weights.Assigned = Weights.assign(surfs, found, rig, table)
	if not assigned.errors.is_empty():
		rig.skeleton.free()
		return assigned.errors
	var bones: int = rig.skeleton.get_bone_count()
	var presentation: Dictionary = {}
	var damping_path: String = _damping_path()
	if not damping_path.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(damping_path))  # Variant: fronteira com o JSON, conferido em _damping_errors
		var factors: Dictionary = parsed if typeof(parsed) == TYPE_DICTIONARY else {}
		errors = _damping_errors(factors, rig)
		if not errors.is_empty():
			rig.skeleton.free()
			return errors
		presentation["damping"] = factors
	if OS.get_cmdline_user_args().has(CONTACT_ARG):
		presentation["ground_points"] = Contact.points_of(surfs, assigned, rig)
	presentation.merge(_symmetric_field(OS.get_cmdline_user_args()))
	presentation.merge(_jog_field(OS.get_cmdline_user_args()))
	presentation.merge(_locomotion_field(OS.get_cmdline_user_args()))
	errors = Writer.write(Writer.OUT_DIR, surfs, found, built, assigned, rig, source_sha, presentation, Writer.meta_file())
	if errors.is_empty():
		print("preparado em %s: %d superfícies, %d ilhas, %d ossos, paleta de %d cores (%d px)" % [Writer.OUT_DIR, surfs.size(), found.list.size(), bones, built.colors.size(), built.image.get_width()])
	return errors


## O campo `symmetric_reference` com as partes das pernas se `arguments` tem `--symmetric`; vazio (nada a gravar) se não.
static func _symmetric_field(arguments: PackedStringArray) -> Dictionary:
	return {"symmetric_reference": SYMMETRIC_PARTS} if arguments.has(SYMMETRIC_ARG) else {}


## O campo `jog` (6j) se `arguments` tem `--jog`; vazio (nada a gravar) se não.
static func _jog_field(arguments: PackedStringArray) -> Dictionary:
	return {"jog": true} if arguments.has(JOG_ARG) else {}


## O campo `locomotion` (7a) com a tabela de `ice_locomotion.json` (clipe -> m/s) se `arguments` tem `--locomotion`; vazio (nada a gravar) se não.
static func _locomotion_field(arguments: PackedStringArray) -> Dictionary:
	return {"locomotion": _locomotion_table()} if arguments.has(LOCOMOTION_ARG) else {}


## Os problemas da opção `--locomotion` (vazio = nada a corrigir, inclusive sem a opção): a tabela tem `jog`, que só vale com o campo `jog` verdadeiro (`--jog`), e a tabela do repositório não pode faltar, estar vazia nem malformada.
static func _locomotion_errors(arguments: PackedStringArray) -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if not arguments.has(LOCOMOTION_ARG):
		return errors
	if not arguments.has(JOG_ARG):
		errors.append("%s exige %s: a tabela de locomoção tem a velocidade do jog, e a figura só tem o clipe jog com o campo jog verdadeiro" % [LOCOMOTION_ARG, JOG_ARG])
	if _locomotion_table().is_empty():
		errors.append("tabela de locomoção ausente, vazia ou malformada: %s" % LOCOMOTION_FILE)
	return errors


## A tabela clipe -> m/s do repositório; {} se o arquivo falta ou não é um objeto JSON.
static func _locomotion_table() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(LOCOMOTION_FILE))  # Variant: fronteira com o JSON, conferido logo abaixo
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}


## O arquivo da tabela de amortecimento pedida por `--damping` ("" = não pedida; sem valor, a do repositório).
static func _damping_path() -> String:
	for argument: String in OS.get_cmdline_user_args():
		if argument == DAMPING_ARG:
			return DAMPING_FILE
		if argument.begins_with(DAMPING_ARG + "="):
			return argument.trim_prefix(DAMPING_ARG + "=")
	return ""


## Os problemas da tabela osso -> fator: ausente, vazia ou malformada, osso que o esqueleto não tem e fator que não é número de 0 a 1.
static func _damping_errors(table: Dictionary, rig: Skel.Rig) -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if table.is_empty():
		errors.append("tabela de amortecimento ausente, vazia ou malformada")
	for bone_name: String in table:
		var factor: Variant = table[bone_name]  # Variant: fronteira com o JSON, conferido logo abaixo
		if rig.skeleton.find_bone(bone_name) < 0 or typeof(factor) != TYPE_FLOAT or float(factor) < 0.0 or float(factor) > 1.0:
			errors.append("amortecimento inválido: %s (esperado um osso do esqueleto com um fator de 0 a 1)" % bone_name)
	return errors
