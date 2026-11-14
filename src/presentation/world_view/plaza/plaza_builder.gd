class_name PlazaBuilder
extends RefCounted
## Monta a praça de mercado procedural (cerca de 30 x 30 m), nascida na cena de teste de renderizadores (ARTE-F0) e promovida ao jogo na ART-1. Fachada fina: compõe os componentes (materiais, chão e estruturas; os números e as cores ficam em PlazaData) na ordem de criação de sempre e devolve o que a cena precisa guardar. Tudo procedural e facetado (cor por vértice, sem textura), variação por hash de inteiros; formas e lugares são [HIP] de composição, a calibrar olhando a cena.


## O que a montagem deixa para a cena mexer depois: materiais (por nome) e as luzes pequenas dos lampiões e das tochas.
class Built extends RefCounted:
	var materials: Dictionary[StringName, Material] = {}
	var lamp_lights: Array[OmniLight3D] = []
	var torch_lights: Array[OmniLight3D] = []


## O que montar e com que altura (ART-2a). O padrão (tudo, com o relevo da demonstração) é o `build(root)` de sempre. `height_provider(x, z) -> float` dá a altura do chão em coordenadas LOCAIS da raiz da praça (quem monta põe a raiz no mundo e o provedor converte). Interruptores: `has_ground` = o chão; `has_vegetation` = grama, flores, árvores e rochas; `has_structures` = barracas, adereços, postes, bandeirolas e a peça central; `has_houses` = as casas.
## `variant` (ART-3) é a identidade da praça: a ficha de PlazaVariants (padrão = a praça de hoje, a variante A).
class Options extends RefCounted:
	var height_provider: Callable = PlazaGround.ground_height
	var has_ground: bool = true
	var has_vegetation: bool = true
	var has_structures: bool = true
	var has_houses: bool = true
	var variant: PlazaVariants.Spec = PlazaVariants.named(PlazaVariants.DEFAULT)


## Cria as partes pedidas em `options` (padrão: todas, como antes) como filhos de `root` e devolve o que a cena precisa guardar. A ordem das chamadas é a ordem dos nós filhos (e dos nomes), então não a troque; desligar uma parte só tira os nós dela.
func build(root: Node3D, options: Options = null) -> Built:
	var chosen: Options = options if options != null else Options.new()
	var built: Built = Built.new()
	built.materials = PlazaMaterials.create()
	var ground: PlazaGround = PlazaGround.new(root, built.materials, chosen.height_provider)
	var structures: PlazaStructures = PlazaStructures.new(ground, built.materials, chosen.variant)
	if chosen.has_ground:
		ground.add_floor()
	if chosen.has_structures:
		structures.add_stalls()
		structures.add_props()
		structures.add_lamps()
		structures.add_torches()
		structures.add_center()
	if chosen.has_houses:
		structures.add_houses()
	if chosen.has_vegetation:
		ground.add_trees()
		ground.add_rocks()
		ground.add_scatter()
	built.lamp_lights = structures.lamp_lights
	built.torch_lights = structures.torch_lights
	return built
