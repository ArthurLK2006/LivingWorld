class_name PlazaBuilder
extends RefCounted
## Monta a praça de mercado procedural (cerca de 30 x 30 m), nascida na cena de teste de renderizadores (ARTE-F0) e promovida ao jogo na ART-1. Fachada fina: compõe os componentes (materiais, chão e estruturas; os números e as cores ficam em PlazaData) na ordem de criação de sempre e devolve o que a cena precisa guardar. Tudo procedural e facetado (cor por vértice, sem textura), variação por hash de inteiros; formas e lugares são [HIP] de composição, a calibrar olhando a cena.


## O que a montagem deixa para a cena mexer depois: materiais (por nome) e as luzes pequenas dos lampiões e das tochas.
class Built extends RefCounted:
	var materials: Dictionary[StringName, Material] = {}
	var lamp_lights: Array[OmniLight3D] = []
	var torch_lights: Array[OmniLight3D] = []


## Cria tudo como filhos de `root` e devolve o que a cena precisa guardar. A ordem das chamadas é a ordem dos nós filhos (e dos nomes), então não a troque.
func build(root: Node3D) -> Built:
	var built: Built = Built.new()
	built.materials = PlazaMaterials.create()
	var ground: PlazaGround = PlazaGround.new(root, built.materials)
	var structures: PlazaStructures = PlazaStructures.new(ground, built.materials)
	ground.add_floor()
	structures.add_stalls()
	structures.add_props()
	structures.add_lamps()
	structures.add_torches()
	structures.add_well()
	structures.add_houses()
	ground.add_trees()
	ground.add_rocks()
	ground.add_scatter()
	built.lamp_lights = structures.lamp_lights
	built.torch_lights = structures.torch_lights
	return built
