class_name InhabitantView
extends Node3D
## Um habitante na cena (ART-9, protótipo isolado, só apresentação): UM MeshInstance3D com a malha do InhabitantBuilder, como a ficha manda, e uma respiração leve parado (o corpo cresce e encolhe um pouco e balança de leve; sem andar por enquanto). Só o LOD 0 respira (de longe ninguém vê). A fase vem do id e o tempo, do `delta`: nada de relógio do sistema nem sorteio.

const BREATH_SPEED: float = 2.1
const BREATH_AMOUNT: float = 0.012
const SWAY_RAD: float = 0.018
const SWAY_SLOWDOWN: float = 0.5
const PHASE_CHANNEL: int = 99

var spec: InhabitantSpec
var lod: int = InhabitantBuilder.LOD_NEAR

var _body: MeshInstance3D
var _phase: float = 0.0


## Monta (ou remonta, trocando só a malha) o habitante da ficha `inhabitant` no LOD `level`; `material` compartilhado (opcional) faz todos da cena dividirem um só.
func spawn(inhabitant: InhabitantSpec, level: int, material: Material = null) -> void:
	spec = inhabitant
	lod = level
	if _body == null:
		_body = MeshInstance3D.new()
		_body.name = "Body"
		add_child(_body)
	_body.mesh = InhabitantBuilder.build(inhabitant, level, material)
	_phase = TAU * PlazaMeshKit.unit(inhabitant.id, PHASE_CHANNEL)
	set_process(level == InhabitantBuilder.LOD_NEAR)


func _process(delta: float) -> void:
	_phase += delta * BREATH_SPEED
	_body.scale = Vector3(1.0, 1.0 + BREATH_AMOUNT * sin(_phase), 1.0)
	_body.rotation.z = SWAY_RAD * sin(_phase * SWAY_SLOWDOWN)
