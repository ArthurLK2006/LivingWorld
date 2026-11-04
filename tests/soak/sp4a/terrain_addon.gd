class_name Sp4aTerrainAddon
extends Node3D
## SPIKE descartável (LW-033/SP4a). Variante "addon": importa as MESMAS alturas de
## Sp4aTerrainData para o Terrain3D (addons/terrain_3d/, baixado conforme autorização de Arthur,
## NÃO versionado — por isso este arquivo NÃO pode usar "Terrain3D" como tipo estático: um clone
## novo sem o addon falharia até para COMPILAR o script, derrubando o check_all inteiro. Testei
## isso de propósito (ver relatório, seção 4): sem o addon, `var x: Terrain3D` dá "Parse Error:
## Could not find type". Por isso uso Object e chamadas dinâmicas (call/set) aqui.
##
## API confirmada por teste curto antes de escrever este arquivo: Terrain3DData.import_images
## (imagens, posição, offset, escala) devolve void (não Error) e espera SEMPRE 3 imagens (altura,
## controle, cor; as duas últimas podem ser null).

const HEIGHT_RESOLUTION: float = 1.0  ## 1 pixel do mapa de altura = 1 metro, fixo

var terrain_data: Sp4aTerrainData
var load_error: String = ""
var import_time_usec: int = 0

var _terrain: Object


static func is_available() -> bool:
	return ClassDB.class_exists("Terrain3D")


## Async: precisa de alguns quadros depois de add_child() para o Terrain3D terminar _ready() e
## expor a propriedade "data" (confirmado por teste curto antes de escrever este arquivo: sem
## esperar, _terrain.get("data") volta null — ver relatório, seção 4).
func setup(data: Sp4aTerrainData) -> bool:
	terrain_data = data
	if not is_available():
		load_error = "Classe Terrain3D não registrada (addon não carregou)."
		return false

	var start_usec: int = Time.get_ticks_usec()
	_terrain = ClassDB.instantiate("Terrain3D")
	add_child(_terrain)
	await get_tree().process_frame
	await get_tree().process_frame

	# Image.set_pixel() por pixel é lento demais para ~1 milhão de pixels (medido: minutos, não
	# segundos). Em vez disso monta um PackedByteArray e cria a imagem de uma vez (Image.
	# create_from_data), testado antes de escrever este arquivo (ver relatório, seção 4).
	var side: int = int(Sp4aTerrainData.MAP_SIZE / HEIGHT_RESOLUTION) + 1
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(side * side * 4)
	for zi: int in range(side):
		for xi: int in range(side):
			var height: float = terrain_data.get_height(xi * HEIGHT_RESOLUTION, zi * HEIGHT_RESOLUTION)
			bytes.encode_float((zi * side + xi) * 4, height)
	var image: Image = Image.create_from_data(side, side, false, Image.FORMAT_RF, bytes)

	var images: Array[Image] = [image, null, null]
	var terrain_data_object: Object = _terrain.get("data")
	if terrain_data_object == null or not terrain_data_object.has_method("import_images"):
		load_error = "Terrain3D.data não tem import_images (API do addon mudou?)."
		return false
	terrain_data_object.call("import_images", images, Vector3.ZERO, 0.0, 1.0)
	import_time_usec = Time.get_ticks_usec() - start_usec

	# collision_mode padrão é "Dynamic / Game" (1): só gera colisão perto de um collision_target,
	# que nunca é setado aqui, e o teste de colisão dava 0/36 batendo mesmo trocando para
	# "Full / Game" (3) antes do import. Setar DEPOIS do import_images e esperar mais quadros
	# (achado ao rodar com janela de verdade — ver relatório, seção 4; limitação se isso também
	# não bastar: fica registrado, não investigo mais que isso).
	_terrain.set("collision_mode", 3)
	for _frame_wait: int in range(5):
		await get_tree().process_frame
	return true


func set_vertex_spacing(spacing: float) -> void:
	if _terrain != null:
		_terrain.set("vertex_spacing", spacing)


func set_camera(camera: Camera3D) -> void:
	if _terrain != null and _terrain.has_method("set_camera"):
		_terrain.call("set_camera", camera)
