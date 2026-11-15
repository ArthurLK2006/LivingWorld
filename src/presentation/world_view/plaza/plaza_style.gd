class_name PlazaStyle
extends RefCounted
## D1 (estudo isolado, nada entra no jogo): a ficha de estilo da nova linguagem da praça, low poly maduro e facetado [HIP]: as cores da madeira, da pedra, do ferro, da corda e do linho (o kit "norte", sóbrio) e as medidas das arestas e das camadas. A `PlazaVariants.Spec` a leva em `style` (nula = a linguagem de sempre) e a `PlazaCrafted` a lê; nada aqui sorteia.

## Madeira (escura, média e clara), pedra de ardósia, ferro, corda, linho do saco e telha.
var wood_dark: Color = Color("4C3B36")
var wood: Color = Color("6B584E")
var wood_light: Color = Color("8C7A6B")
var stone: Color = Color("808C88")
var iron: Color = Color("2E3033")
var rope: Color = Color("9E8B6F")
var linen: Color = Color("B3A58A")
var shingle: Color = Color("36484C")
## Chanfro das arestas, quanto cada tábua sobrepõe a de baixo e quanto cada telha, em metros.
var chamfer_m: float = 0.03
var lap_m: float = 0.022
var shingle_lap_m: float = 0.035
