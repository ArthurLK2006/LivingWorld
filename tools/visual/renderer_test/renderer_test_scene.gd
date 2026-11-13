class_name RendererTestScene
extends Node3D
## Cena de TESTE dos renderizadores Compatibility (`gl_compatibility`, o do projeto) e Forward+ (`forward_plus`) (ARTE-F0): uma praça de mercado procedural isolada, sem ligação com a simulação, a ponte, o
## `main.tscn` nem autoload, e sem mexer no `project.godot`. Ferramenta de desenvolvimento isolada, fora de `src/` (não lê a ponte; o teste da LW-082h exige que `src/tools` só leia pela ponte). Rode com `tools/visual/run_renderer_test` (abre janela; automático, dois
## renderers em sequência) ou à mão: `godot --path . --rendering-method forward_plus res://scenes/demo/renderer_test.tscn`.
## Teclas (dados da cena, ver `key_bindings`): 1, 2 e 3 trocam a luz (dia, hora dourada, crepúsculo); Q, W e E trocam a câmera (próxima, isométrica, estratégica); B bloom, O oclusão ambiente, F névoa e
## D profundidade de campo ligam e desligam o efeito. Argumentos de usuário (depois de `--`): `--auto --out=<pasta>` (modo automático, ver RendererAutoRun) e `--force-effects` (liga todos os efeitos mesmo
## que a tabela de suporte do renderer diga que ele não os aceita: serve para CONFIRMAR em janela o que a tabela supõe).

const TRIANGLE_BUDGET: int = 100000
## Guia visual, seção 5: no máximo cerca de 12 materiais compartilhados por cena.
const MAX_MATERIALS: int = 12
const LOG_PREFIX: String = "RENDERER_TEST: "
const ARG_FORCE_EFFECTS: String = "--force-effects"
const SHADOW_DISTANCE_M: float = 150.0
const CAMERA_FAR_M: float = 600.0
## Quanto a emissão dos lampiões e tochas sobe por unidade de energia da luz (o brilho forte é o que alimenta o bloom).
const EMISSION_PER_ENERGY: float = 3.0
const LIGHT_ACTIONS: Array[StringName] = [&"light_day", &"light_golden", &"light_dusk"]
const VIEW_ACTIONS: Array[StringName] = [&"view_near", &"view_isometric", &"view_strategic"]

## Teclas da cena: um InputEvent por nome de ação, GUARDADO NA CENA (dado de autoria, como o [input] do project.godot) e não no código (tools/check_input_keys), sem tocar o `project.godot`.
@export var key_bindings: Dictionary[StringName, InputEvent] = {}

var preset_index: int = 0
var view_index: int = 0
var rendering_method: String = ""
## Efeitos que o renderer aceita (RendererPresets.SUPPORTED, [HIP]) e chaves ligadas pelo jogador; o efeito só fica ligado se as duas coisas valem.
var supported: Dictionary[StringName, bool] = {}
var switches: Dictionary[StringName, bool] = {&"bloom": true, &"ssao": true, &"fog": true, &"dof": true}
var built: PlazaBuilder.Built
var sun: DirectionalLight3D
var environment: Environment
var camera: Camera3D

var _sky_material: ProceduralSkyMaterial
var _attributes: CameraAttributesPractical


func _ready() -> void:
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	rendering_method = RenderingServer.get_current_rendering_method()
	supported = RendererPresets.supported_effects(rendering_method)
	_register_support(arguments.has(ARG_FORCE_EFFECTS))
	_build_rig()
	built = PlazaBuilder.new().build(self)
	apply_preset(0)
	if RendererAutoRun.is_requested(arguments):
		await RendererAutoRun.new().run(self, RendererAutoRun.out_dir(arguments))


func _unhandled_input(event: InputEvent) -> void:
	var action: StringName = action_for(event)
	if action != &"":
		run_action(action)
		get_viewport().set_input_as_handled()


## Ação ligada à tecla do evento (vazia se não há ou se o evento é solto ou repetido).
func action_for(event: InputEvent) -> StringName:
	if event.is_pressed() and not event.is_echo():
		for action: StringName in key_bindings:
			if key_bindings[action].is_match(event):
				return action
	return &""


func run_action(action: StringName) -> void:
	if LIGHT_ACTIONS.has(action):
		apply_preset(LIGHT_ACTIONS.find(action))
	elif VIEW_ACTIONS.has(action):
		apply_view(VIEW_ACTIONS.find(action))
	elif switches.has(action):
		toggle_effect(action)


## Efeitos realmente ligados: aceitos pelo renderer e (quando têm tecla) não desligados por ela.
func active_effects() -> Dictionary[StringName, bool]:
	var active: Dictionary[StringName, bool] = {}
	for effect: StringName in RendererPresets.EFFECTS:
		active[effect] = supported[effect] and switches.get(effect, true)
	return active


func apply_preset(index: int) -> void:
	preset_index = index
	var preset: Dictionary = RendererPresets.PRESETS[index]
	RendererPresets.apply(preset, sun, environment, _sky_material, active_effects())
	_set_lights(built.lamp_lights, built.materials[&"lantern"], preset["lamp"])
	_set_lights(built.torch_lights, built.materials[&"flame"], preset["torch"])
	for key: StringName in [&"accent_warm", &"accent_cyan"]:
		(built.materials[key] as StandardMaterial3D).emission_energy_multiplier = preset["accent"]
	apply_view(view_index)
	_log("luz '%s' (renderer %s)" % [preset["name"], rendering_method])


func apply_view(index: int) -> void:
	view_index = index
	var dof_amount: float = RendererPresets.PRESETS[preset_index]["dof"]
	RendererPresets.apply_view(RendererPresets.VIEWS[index], camera, _attributes, dof_amount, active_effects()[&"dof"])
	_log("câmera '%s'" % RendererPresets.VIEWS[index]["name"])


func toggle_effect(effect: StringName) -> void:
	switches[effect] = not switches[effect]
	apply_preset(preset_index)
	_log("efeito '%s' %s%s" % [effect, "ligado" if switches[effect] else "desligado", "" if supported[effect] else " (sem efeito: o renderer não o aceita)"])


## Triângulos da cena: malhas soltas mais as instâncias dos MultiMesh vezes o tamanho da malha de cada uma.
func triangle_count() -> int:
	var vertices: int = 0
	for node: Node in find_children("*", "MeshInstance3D", true, false):
		vertices += (node as MeshInstance3D).mesh.get_faces().size()
	for node: Node in find_children("*", "MultiMeshInstance3D", true, false):
		var multimesh: MultiMesh = (node as MultiMeshInstance3D).multimesh
		vertices += multimesh.instance_count * multimesh.mesh.get_faces().size()
	return int(vertices / 3.0)


## Resumo numérico de toda a geometria (malhas, posições e instâncias): duas montagens iguais dão o mesmo número.
func fingerprint() -> int:
	var digest: int = 0
	for node: Node in find_children("*", "MeshInstance3D", true, false):
		var instance: MeshInstance3D = node as MeshInstance3D
		digest = hash([digest, instance.transform])
		for surface: int in instance.mesh.get_surface_count():
			digest = hash([digest, instance.mesh.surface_get_arrays(surface)])
	for node: Node in find_children("*", "MultiMeshInstance3D", true, false):
		digest = hash([digest, (node as MultiMeshInstance3D).multimesh.buffer])
	return digest


## Registra no log o que ficou desligado e por quê (e força tudo ligado com --force-effects).
func _register_support(is_forced: bool) -> void:
	for effect: StringName in RendererPresets.EFFECTS:
		if is_forced:
			supported[effect] = true
		elif not supported[effect]:
			_log("efeito '%s' DESLIGADO: o renderer '%s' não o aceita (tabela [HIP], a confirmar em janela; %s tenta ligar mesmo assim)." % [effect, rendering_method, ARG_FORCE_EFFECTS])
	if is_forced:
		_log("%s: todos os efeitos ligados à força no renderer '%s'." % [ARG_FORCE_EFFECTS, rendering_method])


func _build_rig() -> void:
	sun = DirectionalLight3D.new()
	sun.name = "Sun"
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = SHADOW_DISTANCE_M
	add_child(sun)
	_sky_material = ProceduralSkyMaterial.new()
	var sky: Sky = Sky.new()
	sky.sky_material = _sky_material
	environment = Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.adjustment_enabled = true
	var world_environment: WorldEnvironment = WorldEnvironment.new()
	world_environment.environment = environment
	add_child(world_environment)
	_attributes = CameraAttributesPractical.new()
	camera = Camera3D.new()
	camera.attributes = _attributes
	camera.far = CAMERA_FAR_M
	add_child(camera)
	camera.make_current()


func _set_lights(lights: Array[OmniLight3D], material: Material, energy: float) -> void:
	for light: OmniLight3D in lights:
		light.light_energy = energy
		light.visible = energy > 0.0
	(material as StandardMaterial3D).emission_energy_multiplier = energy * EMISSION_PER_ENERGY


func _log(message: String) -> void:
	print(LOG_PREFIX + message)
