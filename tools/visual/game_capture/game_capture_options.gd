class_name GameCaptureOptions
extends RefCounted
## Opções da captura do jogo real (CAP, ferramenta de desenvolvimento): lê os argumentos de usuário (depois de `--`), aplica os padrões e dá nome aos arquivos. Peça pura, sem nó nem janela; quem abre o jogo é a GameCaptureRun.

const ARG_SPOTS_PREFIX: String = "--spots="
const ARG_HOURS_PREFIX: String = "--hours="
const ARG_CAMS_PREFIX: String = "--cams="
const KNOWN_PREFIXES: Array[String] = [RendererAutoRun.ARG_OUT_PREFIX, ARG_SPOTS_PREFIX, ARG_HOURS_PREFIX, ARG_CAMS_PREFIX]
## Itens de uma lista se separam por vírgula; o `xz:<x>,<z>` leva o item seguinte como o z.
const LIST_SEPARATOR: String = ","
const KIND_SEPARATOR: String = ":"
const KIND_MARKET: String = "market"
const KIND_XZ: String = "xz"
const KIND_SPAWN: String = "spawn"
const DEFAULT_SPOTS: String = "market:a_market_01,spawn"
const DEFAULT_HOURS: String = "12,17.5,19"
const SHOT_EXTENSION: String = ".png"
## Vistas da câmera do jogo: x = distância (m), y = ângulo para baixo (graus), z = giro (graus; 0 = câmera ao sul do alvo, olhando para -Z). Distância e ângulo são os da demonstração de renderizadores (RendererPresets.VIEWS, [HIP]);
## a câmera do jogo só chega a 40 m e 75 graus pelo zoom e pelo giro do jogador, mas as propriedades dela aceitam mais, e a estratégica passa disso de propósito.
const CAMERA_VIEWS: Dictionary[String, Vector3] = {
	"near": Vector3(5.0, 12.0, 0.0),
	"iso": Vector3(22.0, 50.0, 0.0),
	"strategic": Vector3(60.0, 70.0, 0.0),
}


## Um local onde o jogador fica para a captura: um mercado (pelo id), um ponto x,z do mapa (metros) ou o ponto de nascimento.
class Spot:
	extends RefCounted

	var kind: String = ""
	var place_id: String = ""
	var x_m: float = 0.0
	var z_m: float = 0.0

	func _init(spot_kind: String, id: String = "", x: float = 0.0, z: float = 0.0) -> void:
		kind = spot_kind
		place_id = id
		x_m = x
		z_m = z

	## Parte do nome dos arquivos: o id do mercado, "spawn" ou "xz_<x>_<z>" (metros, como "xz_313_5_556").
	func label() -> String:
		match kind:
			GameCaptureOptions.KIND_MARKET:
				return place_id
			GameCaptureOptions.KIND_XZ:
				return "xz_%s_%s" % [GameCaptureOptions.meters_label(x_m), GameCaptureOptions.meters_label(z_m)]
		return GameCaptureOptions.KIND_SPAWN

	## Onde o jogador fica (x, z em metros): a posição do mercado (lida da ponte pela GameCaptureRun), a dada em `xz`, ou o ponto de nascimento.
	func position_m(markets: Dictionary[String, Vector2], spawn_m: Vector2) -> Vector2:
		match kind:
			GameCaptureOptions.KIND_MARKET:
				return markets.get(place_id, spawn_m)
			GameCaptureOptions.KIND_XZ:
				return Vector2(x_m, z_m)
		return spawn_m


## Pasta de saída (vazia = não veio), locais, horas (0 <= h < 24) e nomes das vistas, já com os padrões. `errors` diz o que não foi entendido: com erro o jogo nem abre.
var out_dir: String = ""
var spots: Array[Spot] = []
var hours: Array[float] = []
var cameras: Array[String] = []
var errors: Array[String] = []


static func parse(args: PackedStringArray) -> GameCaptureOptions:
	var options: GameCaptureOptions = GameCaptureOptions.new()
	options.out_dir = RendererAutoRun.out_dir(args)
	for argument: String in args:
		if not _is_known(argument):
			options.errors.append("argumento desconhecido '%s'; esperado --out=<pasta>, --spots=<lista>, --hours=<lista> ou --cams=<lista>." % argument)
	options._read_spots(_list(args, ARG_SPOTS_PREFIX, DEFAULT_SPOTS))
	options._read_hours(_list(args, ARG_HOURS_PREFIX, DEFAULT_HOURS))
	options._read_cameras(_list(args, ARG_CAMS_PREFIX, LIST_SEPARATOR.join(PackedStringArray(CAMERA_VIEWS.keys()))))
	if options.errors.is_empty() and (options.spots.is_empty() or options.hours.is_empty() or options.cameras.is_empty()):
		options.errors.append("lista vazia: --spots, --hours e --cams precisam de ao menos um item.")
	return options


## "17h30" para 17,5 (minutos arredondados; 24h vale 00h00): nome sem ponto, seguro em arquivo.
static func hour_label(hour: float) -> String:
	var minutes_per_hour: int = roundi(DayNightCycle.MINUTES_PER_HOUR)
	var minutes: int = posmod(roundi(hour * DayNightCycle.MINUTES_PER_HOUR), roundi(DayNightCycle.HOURS_PER_DAY) * minutes_per_hour)
	return "%02dh%02d" % [floori(float(minutes) / float(minutes_per_hour)), posmod(minutes, minutes_per_hour)]


## Metros com uma casa decimal no máximo, sem ".0" no fim e sem ponto: 313.5 vira "313_5" e 556.0 vira "556".
static func meters_label(value_m: float) -> String:
	return String.num(value_m, 1).trim_suffix(".0").replace(".", "_")


## Nome do PNG de uma captura: "<hora>_<local>_<câmera>.png", como "17h30_a_market_01_near.png".
static func shot_file(hour: float, spot: Spot, camera: String) -> String:
	return "%s_%s_%s%s" % [hour_label(hour), spot.label(), camera, SHOT_EXTENSION]


## O que falta no jogo para os locais pedidos ("" se nada falta): um mercado que não existe. A mensagem lista os que existem.
func market_problem(markets: Dictionary[String, Vector2]) -> String:
	for spot: Spot in spots:
		if spot.kind == KIND_MARKET and not markets.has(spot.place_id):
			return "mercado '%s' não existe; os do jogo são: %s." % [spot.place_id, ", ".join(PackedStringArray(markets.keys()))]
	return ""


static func _is_known(argument: String) -> bool:
	for prefix: String in KNOWN_PREFIXES:
		if argument.begins_with(prefix):
			return true
	return false


## Itens do primeiro argumento com o prefixo; sem ele, os do padrão.
static func _list(args: PackedStringArray, prefix: String, fallback: String) -> PackedStringArray:
	for argument: String in args:
		if argument.begins_with(prefix):
			return argument.trim_prefix(prefix).split(LIST_SEPARATOR, false)
	return fallback.split(LIST_SEPARATOR, false)


func _read_spots(items: PackedStringArray) -> void:
	var index: int = 0
	while index < items.size():
		var item: String = items[index]
		var kind: String = item.get_slice(KIND_SEPARATOR, 0)
		var value: String = item.get_slice(KIND_SEPARATOR, 1)
		index += 1
		if item == KIND_SPAWN:
			spots.append(Spot.new(KIND_SPAWN))
		elif kind == KIND_MARKET and not value.is_empty():
			spots.append(Spot.new(KIND_MARKET, value))
		elif kind == KIND_XZ and value.is_valid_float() and index < items.size() and items[index].is_valid_float():
			spots.append(Spot.new(KIND_XZ, "", value.to_float(), items[index].to_float()))
			index += 1
		else:
			errors.append("local inválido '%s'; esperado market:<id>, xz:<x>,<z> (metros) ou spawn." % item)


func _read_hours(items: PackedStringArray) -> void:
	for item: String in items:
		if item.is_valid_float() and item.to_float() >= 0.0 and item.to_float() < DayNightCycle.HOURS_PER_DAY:
			hours.append(item.to_float())
		else:
			errors.append("hora inválida '%s'; esperado um número de 0 a 24 (exclusive), como 17.5." % item)


func _read_cameras(items: PackedStringArray) -> void:
	for item: String in items:
		if CAMERA_VIEWS.has(item):
			cameras.append(item)
		else:
			errors.append("câmera desconhecida '%s'; esperado %s." % [item, ", ".join(PackedStringArray(CAMERA_VIEWS.keys()))])
