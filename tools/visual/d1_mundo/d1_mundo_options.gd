class_name D1MundoOptions
extends RefCounted
## D1-B (estudo isolado, nada entra no jogo): as variantes que as ferramentas de captura e medição comparam. `a` é a praça de hoje; `a_lean` é a de hoje com o toldo de uma água (o arquétipo que já existia no kit) em todas as barracas, para isolar o que é linguagem e o que é só trocar de arquétipo; `d` é a nova linguagem.

const LEAN_TO_STALLS: Array[int] = [PlazaData.StallKind.LEAN_TO, PlazaData.StallKind.LEAN_TO, PlazaData.StallKind.LEAN_TO, PlazaData.StallKind.LEAN_TO, PlazaData.StallKind.LEAN_TO]


## As opções da praça de demonstração da variante `variant_id` (id desconhecido dá a de hoje).
static func for_variant(variant_id: String) -> PlazaBuilder.Options:
	var options: PlazaBuilder.Options = PlazaBuilder.Options.new()
	if variant_id == "a_lean":
		options.variant = PlazaVariants.named(&"a")
		options.variant.stall_kinds = LEAN_TO_STALLS
	else:
		options.variant = PlazaVariants.named(StringName(variant_id))
	return options
