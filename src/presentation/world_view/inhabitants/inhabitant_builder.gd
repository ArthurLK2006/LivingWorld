class_name InhabitantBuilder
extends RefCounted
## Malha de UM habitante (ART-9, 9b, 9c e 9d, protótipo isolado, só apresentação): o orquestrador. Monta, na ordem, o corpo (InhabitantBody), a cabeça e o rosto (InhabitantHead), a roupa em camadas (InhabitantClothes), a cobertura da cabeça (InhabitantHeadwear) e os acessórios (InhabitantGear), todos sobre as medidas e a superfície do InhabitantRig e as formas loftadas do InhabitantShapes. UMA superfície, UM material (o `solid` da praça se vier nulo; o mesmo material para todos os habitantes de uma cena os faz dividir um só), facetada e com cor por vértice, pés em y = 0, origem entre os pés, frente para -Z (como `look_at`; +X é a direita dele). Três níveis [HIP]: LOD 0 (perto, até 22 m, cerca de 1.800 triângulos) leva rosto, mãos e todos os detalhes; LOD 1 (22 a 45 m, cerca de 450), as formas e as cores principais; LOD 2 (além, cerca de 120), a silhueta.

const LOD_NEAR: int = InhabitantRig.LOD_NEAR
const LOD_MID: int = InhabitantRig.LOD_MID
const LOD_FAR: int = InhabitantRig.LOD_FAR


## A malha do habitante `spec` no nível `lod` (0, 1 ou 2), com `material` (o `solid` da praça se vier nulo).
static func build(spec: InhabitantSpec, lod: int, material: Material = null) -> ArrayMesh:
	var surface_material: Material = material if material != null else PlazaMaterials.create()[&"solid"]
	var rig: InhabitantRig = InhabitantRig.new(spec, lod)
	InhabitantBody.new(rig).build()
	InhabitantHead.new(rig).build()
	InhabitantClothes.new(rig).build()
	InhabitantHeadwear.new(rig).build()
	InhabitantGear.new(rig).build()
	return rig.shapes.kit.finish(ArrayMesh.new(), surface_material)
