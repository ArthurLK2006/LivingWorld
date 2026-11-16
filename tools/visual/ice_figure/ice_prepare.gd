extends SceneTree
## Ferramenta de preparo do Ice Warrior (ferramenta de arte, fora do jogo): lê o original, confere que é a fonte esperada, gera a paleta própria, o esqueleto e os pesos e grava a versão preparada em art_samples/ice_figure/ (FORA do Git). Sem janela:
## godot --headless --path <projeto> -s res://tools/visual/ice_figure/ice_prepare.gd
## Termina com código 1 e a mensagem se algo não bate (fonte diferente, tabela que não bate com as ilhas, paleta que não cabe).
const Source = preload("res://tools/visual/ice_figure/ice_source.gd")
const Palette = preload("res://tools/visual/ice_figure/ice_palette.gd")
const Skel = preload("res://tools/visual/ice_figure/ice_skeleton.gd")
const Weights = preload("res://tools/visual/ice_figure/ice_weights.gd")
const Writer = preload("res://tools/visual/ice_figure/ice_writer.gd")


func _initialize() -> void:
	var errors: PackedStringArray = _prepare()
	for line: String in errors:
		print("FALHA: %s" % line)
	quit(1 if not errors.is_empty() else 0)


func _prepare() -> PackedStringArray:
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
	errors = Writer.write(Writer.OUT_DIR, surfs, found, built, assigned, rig, source_sha)
	if errors.is_empty():
		print("preparado em %s: %d superfícies, %d ilhas, %d ossos, paleta de %d cores (%d px)" % [Writer.OUT_DIR, surfs.size(), found.list.size(), bones, built.colors.size(), built.image.get_width()])
	return errors
