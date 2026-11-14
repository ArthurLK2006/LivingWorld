class_name V7InhabitantBuilder
extends RefCounted
## [v7 CONGELADA, só para a cena de comparação] Malha de UM habitante (ART-9, 9b, 9c e 9d, protótipo isolado, só apresentação): o orquestrador. Monta, na ordem, o corpo (V7InhabitantBody), a cabeça e o rosto (V7InhabitantHead), a roupa em camadas (V7InhabitantClothes), a cobertura da cabeça (V7InhabitantHeadwear) e os acessórios (V7InhabitantGear), todos sobre as medidas e a superfície do V7InhabitantRig e as formas loftadas do V7InhabitantShapes. UMA superfície, UM material (o `solid` da praça se vier nulo; o mesmo material para todos os habitantes de uma cena os faz dividir um só), facetada e com cor por vértice, pés em y = 0, origem entre os pés, frente para -Z (como `look_at`; +X é a direita dele). Três níveis [HIP]: LOD 0 (perto, até 22 m, cerca de 1.800 triângulos) leva rosto, mãos e todos os detalhes; LOD 1 (22 a 45 m, cerca de 450), as formas e as cores principais; LOD 2 (além, cerca de 120), a silhueta.

const LOD_NEAR: int = V7InhabitantRig.LOD_NEAR
const LOD_MID: int = V7InhabitantRig.LOD_MID
const LOD_FAR: int = V7InhabitantRig.LOD_FAR


## A malha do habitante `spec` no nível `lod` (0, 1 ou 2), com `material` (o `solid` da praça se vier nulo).
static func build(spec: V7InhabitantSpec, lod: int, material: Material = null) -> ArrayMesh:
	var surface_material: Material = material if material != null else PlazaMaterials.create()[&"solid"]
	var rig: V7InhabitantRig = V7InhabitantRig.new(spec, lod)
	V7InhabitantBody.new(rig).build()
	V7InhabitantHead.new(rig).build()
	V7InhabitantClothes.new(rig).build()
	V7InhabitantHeadwear.new(rig).build()
	V7InhabitantGear.new(rig).build()
	return rig.shapes.kit.finish(ArrayMesh.new(), surface_material)
