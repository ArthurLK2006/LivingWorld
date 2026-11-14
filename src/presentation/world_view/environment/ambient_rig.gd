class_name AmbientRig
extends Node
## Aplica o AmbientConfig ao WorldEnvironment e ao Sol (DirectionalLight3D) da cena principal (LW-041) e, com uma
## ponte, a luz do dia e da noite pela hora simulada (LW-042). A luz é função da hora (DayNightCycle): nada é guardado,
## nada entra em save nem em state_hash. A simulação não sabe de luz; a hora vem SÓ da ponte (peek_time).
## ART-5a: a cada estado aplicado ele emite `state_applied` (as luzes dos lampiões da praça o seguem) e guarda só o fator dos lampiões do último, para a cena dar o fator inicial.

## Emitido cada vez que um estado de luz é APLICADO com sucesso: a cada quadro com o relógio andando e, parado ou pausado, só quando a hora usada muda. Quem o ouve compara com o que já tem se o custo importar.
signal state_applied(state: DayNightCycle.LightState)

@export var config: AmbientConfig
@export var environment_path: NodePath = ^"../Environment"
@export var sun_path: NodePath = ^"../Sun"

## [HIP] Segundos reais de um minuto simulado a 1x: o ritmo do relógio (SimClock.DEFAULT_REAL_MS_PER_MINUTE = 1250 ms), copiado
## aqui só para a fração do minuto andar na mesma velocidade; a hora oficial continua vindo da ponte.
const REAL_SECONDS_PER_MINUTE_AT_1X: float = 1.25
## Brilho, contraste e saturação em 1 não mudam a imagem: com os três assim o ajuste de cor fica desligado no Environment.
const NEUTRAL_ADJUSTMENT: float = 1.0

var _bridge: SimBridge
## Minuto simulado da última luz aplicada.
var _last_total_minutes: int = -1
## Quanto do minuto simulado atual já passou (0 a 1, exclusive), contado pelos quadros; zera a cada virada de minuto.
var _minute_fraction: float = 0.0
var _time_failure_reported: bool = false
## O fator dos lampiões do último estado aplicado (0 de dia enquanto nenhum foi).
var _lamp_factor: float = 0.0


## Liga a ponte de onde sai a hora. Sem chamar, o `_ready` pede a ponte ao GameApp.
func setup(bridge: SimBridge) -> void:
	_bridge = bridge


func _ready() -> void:
	apply()
	if _bridge == null:
		var app: GameAppNode = get_node_or_null("/root/GameApp") as GameAppNode
		if app != null:
			_bridge = app.peek_bridge()
	refresh()


func _process(delta: float) -> void:
	refresh(delta)


## Quanto do minuto simulado atual já passou (0 a 1, exclusive).
func minute_fraction() -> float:
	return _minute_fraction


## O fator dos lampiões e das tochas (0 a 1, `LightState.lamp_factor`) do último estado aplicado; 0 (dia) se nenhum foi.
func lamp_factor() -> float:
	return _lamp_factor


## Lê a hora pela ponte e aplica a luz da curva do dia e da noite. A hora usada é a oficial mais a fração do minuto, que
## cresce com `frame_delta` (segundos reais do quadro) na velocidade atual e CONGELA pausado; a virada de minuto zera a fração.
## Só reaplica quando a hora usada muda. Se a hora falhar: push_error uma vez e a luz fica como está. Devolve falso se nada foi aplicado.
func refresh(frame_delta: float = 0.0) -> bool:
	if _bridge == null:
		return false
	var time: BridgeReplies.TimeSnapshot = _bridge.peek_time()
	if not time.result.ok:
		if not _time_failure_reported:
			_time_failure_reported = true
			push_error("AmbientRig: hora simulada indisponível (%s): %s A luz fica como está." % [time.result.code, time.result.message])
		return false
	_time_failure_reported = false
	var fraction: float = 0.0
	if time.total_minutes == _last_total_minutes:
		fraction = _minute_fraction
		if not time.is_paused:
			fraction += maxf(frame_delta, 0.0) * float(time.speed) / REAL_SECONDS_PER_MINUTE_AT_1X
		fraction = clampf(fraction, 0.0, DayNightCycle.MAX_MINUTE_FRACTION)
		if fraction == _minute_fraction:
			return true
	_last_total_minutes = time.total_minutes
	_minute_fraction = fraction
	return apply_state(DayNightCycle.state_at(config, DayNightCycle.fractional_hour(time.hour_of_day, time.minute_of_hour, fraction)))


## Resolve os nós pelos caminhos e aplica o recurso. Falha visível (push_error) se faltar nó ou recurso válido.
func apply() -> bool:
	var world_environment: WorldEnvironment = get_node_or_null(environment_path) as WorldEnvironment
	var sun: DirectionalLight3D = get_node_or_null(sun_path) as DirectionalLight3D
	if world_environment == null or sun == null:
		push_error("AmbientRig: WorldEnvironment em '%s' ou DirectionalLight3D em '%s' não encontrado." % [str(environment_path), str(sun_path)])
		return false
	return apply_to(world_environment, sun)


## Aplica o dia pleno com a inclinação fixa do recurso (sem hora simulada).
func apply_to(world_environment: WorldEnvironment, sun: DirectionalLight3D) -> bool:
	return apply_state_to(world_environment, sun, DayNightCycle.day_state(config) if config != null else null)


## Aplica um estado de luz da curva (sol, céu, ambiente, névoa, bloom, tonemap e ajuste de cor) pelos caminhos da cena.
func apply_state(state: DayNightCycle.LightState) -> bool:
	var world_environment: WorldEnvironment = get_node_or_null(environment_path) as WorldEnvironment
	var sun: DirectionalLight3D = get_node_or_null(sun_path) as DirectionalLight3D
	if world_environment == null or sun == null:
		push_error("AmbientRig: WorldEnvironment em '%s' ou DirectionalLight3D em '%s' não encontrado." % [str(environment_path), str(sun_path)])
		return false
	return apply_state_to(world_environment, sun, state)


func apply_state_to(world_environment: WorldEnvironment, sun: DirectionalLight3D, state: DayNightCycle.LightState) -> bool:
	if config == null:
		push_error("AmbientRig: sem AmbientConfig; esperado o recurso em assets/environment/.")
		return false
	var problems: Array[String] = config.validate()
	if not problems.is_empty():
		push_error("AmbientRig: AmbientConfig inválido: %s." % "; ".join(problems))
		return false
	_apply_sun(sun, state)
	_apply_environment(world_environment, state)
	_lamp_factor = state.lamp_factor
	state_applied.emit(state)
	return true


func _apply_sun(sun: DirectionalLight3D, state: DayNightCycle.LightState) -> void:
	sun.light_color = state.sun_color
	sun.light_energy = state.sun_energy
	sun.rotation_degrees = Vector3(-state.elevation_degrees, state.sun_yaw_degrees, 0.0)
	sun.shadow_enabled = config.shadows_enabled
	sun.directional_shadow_mode = config.shadow_mode
	sun.directional_shadow_max_distance = config.shadow_max_distance_m
	sun.shadow_bias = config.shadow_bias
	sun.shadow_normal_bias = config.shadow_normal_bias
	sun.shadow_blur = config.shadow_blur


## Cria o que faltar (Environment, Sky e material do céu) e grava os valores do recurso, sem acrescentar nada.
func _apply_environment(world_environment: WorldEnvironment, state: DayNightCycle.LightState) -> void:
	var environment: Environment = world_environment.environment
	if environment == null:
		environment = Environment.new()
		world_environment.environment = environment
	if environment.sky == null:
		environment.sky = Sky.new()
	var sky_material: ProceduralSkyMaterial = environment.sky.sky_material as ProceduralSkyMaterial
	if sky_material == null:
		sky_material = ProceduralSkyMaterial.new()
		environment.sky.sky_material = sky_material
	environment.background_mode = Environment.BG_SKY
	sky_material.sky_top_color = state.sky_top_color
	sky_material.sky_horizon_color = state.sky_horizon_color
	sky_material.ground_horizon_color = state.ground_horizon_color
	sky_material.ground_bottom_color = state.ground_bottom_color
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = state.ambient_color
	environment.ambient_light_energy = state.ambient_energy
	environment.fog_enabled = config.fog_enabled
	environment.fog_light_color = state.fog_color
	environment.fog_density = state.fog_density
	environment.fog_sky_affect = config.fog_sky_affect
	environment.glow_enabled = config.glow_enabled
	environment.glow_intensity = state.glow_intensity
	environment.glow_hdr_threshold = state.glow_hdr_threshold
	environment.glow_bloom = state.glow_bloom
	_apply_color_grade(environment, state)


## Tonemap (modo e branco são do recurso, um só para o ciclo) e, da hora, a exposição e o ajuste de cor. O ajuste só liga se brilho, contraste ou saturação saem do neutro.
func _apply_color_grade(environment: Environment, state: DayNightCycle.LightState) -> void:
	environment.tonemap_mode = config.tonemap_mode
	environment.tonemap_white = config.tonemap_white
	environment.tonemap_exposure = state.exposure
	var is_neutral: bool = is_equal_approx(state.brightness, NEUTRAL_ADJUSTMENT) and is_equal_approx(state.contrast, NEUTRAL_ADJUSTMENT) and is_equal_approx(state.saturation, NEUTRAL_ADJUSTMENT)
	environment.adjustment_enabled = not is_neutral
	environment.adjustment_brightness = state.brightness
	environment.adjustment_contrast = state.contrast
	environment.adjustment_saturation = state.saturation
