# Guia visual do Living World

**Status:** PROPOSTA de trabalho (Fase 0 de arte, 13/11/2026), baseada na decisão de Arthur de 13/11/2026 (DEC-280). Não altera código nem o `project.godot`. Valores marcados **[HIP]** são hipóteses a calibrar na cena demonstrativa; não são requisitos.

## 1. Direção em uma frase
Fantasia medieval 3D estilizada: modelos low-poly facetados e ricos em detalhes, materiais de aparência artística (não fotográfica), cidades e mercados elaborados, vegetação volumosa, luz quente e atmosférica, cores equilibradas e coerência entre as câmeras próxima, isométrica e estratégica.

## 2. As três referências (o que cada uma ensina)
| Referência | Linguagem | Lição |
|---|---|---|
| 1. Vila do Albion Online, vista de cima | chão pintado (terra ocre #B09050, manchas de grama oliva), sombras longas, suaves e frias, objetos "gordos", fundo azul-acinzentado desbotado, um acento saturado pequeno | composição por manchas de cor; chão aberto para descansar o olhar |
| 2. Barraca de mercado, câmera baixa | low-poly facetado com muito detalhe pequeno (pano em tiras, parafusos, rolos de tecido, sacos, bandeirolas, lampiões), contraluz quente, bloom, fundo desfocado | o "rico" vem de adereços e de luz |
| 3. Floresta ao crepúsculo | base fria roxo-azulada, acentos quentes e ciano que brilham, pinheiros em camadas, rochas monolíticas, grama em lâminas, primeiro plano desfocado | cores complementares; luzes pequenas como pontos focais |

Uso: só como referência de linguagem. É proibido copiar modelo, personagem, marca ou arte de outros jogos (DEC-280).

## 3. Princípios
1. Riqueza = densidade de adereços pequenos + paleta disciplinada + luz forte com sombra suave e colorida + emissivos como focos. Não é mais polígonos.
2. Silhueta primeiro: a peça tem de ser lida a 40 m e recompensar o olhar a 4 m.
3. Uma cor dominante e um acento por cena; saturação média de 0,35 a 0,45 [HIP].
4. Chão aberto nos caminhos, detalhe concentrado nos focos (poço, barracas, portas).
5. Tudo reproduzível por script e com licença registrada.

## 4. Modelagem
- Facetado (normais planas), formas robustas ("gordas"), quinas expostas com chanfro pequeno, beirais e toldos exagerados.
- Módulo de 1 m (parede de 4 m, piso de 3 m); pivô na base; escala em metros; um arquivo glTF/GLB por peça; nomes em `snake_case`.
- Orçamento de triângulos por peça [HIP]: casa de 1,5 a 4 mil; barraca de 0,8 a 1,5 mil; adereço de 100 a 600; árvore de 0,4 a 1,2 mil; arbusto de 150 a 400; rocha de 80 a 300.
- LOD em 3 níveis [HIP]: até 15 m, até 40 m e até 120 m (silhueta simples); sombras até 100 a 150 m.
- Variação: 2 a 3 variantes por peça; escala, giro e cor determinísticos pelo id do local (nada de aleatório fora do `core`).
- Pegada: toda peça de local declara a pegada (hoje, as caixas do `PlacePalette`; o mercado tem 4 x 4 m) para preservar rotas de NPC e colisão.

## 5. Materiais e cor
- Sem textura fotográfica: cor por vértice ou paleta/atlas por kit; no máximo cerca de 12 materiais compartilhados por cena.
- Rugosidade de 0,7 a 0,95; metal só em detalhes; realce de borda (rim) sutil.
- Oclusão ambiente nos vértices (escurece base e junções); gradiente vertical suave (mais claro no topo).
- Emissivos (lampião, tocha, janela, cristal) sempre pequenos; com bloom quando o renderer suportar.

## 6. Luz e atmosfera (3 predefinições; valores iniciais [HIP])
| | Dia | Hora dourada | Crepúsculo |
|---|---|---|---|
| Base de cor | ocre #B09050, marrons #907030 e #705030, oliva #909030 | sombras #303030 e #503030, rosa-poeira #705050 | azul-roxo #505090 e #705090, ameixa #503050 |
| Sol | alto (45 a 60°), quente (#FFF2D9) | baixo (8 a 15°), contraluz (#FFB873) | muito baixo, frio |
| Ambiente | claro e frio | quente e escuro | frio e profundo |
| Acentos | poucos | lampiões acesos (#FFB347) | tochas (#FF9A3C) e ciano (#3FE0E0) |
| Névoa | clara | quente | fria |

- Sombra suave e colorida (nunca preta); luzes locais (lampião, tocha) curtas, sem sombra e em número limitado; oscilação leve.
- Atmosfera: névoa com cor (perspectiva atmosférica), bloom em emissivos, profundidade de campo e vinheta só em tomadas próximas e se o renderer suportar.
- As predefinições são pontos-chave do ciclo de dia (LW-042a), interpoladas pela hora, quando tecnicamente adequado.

## 7. Vegetação
- Árvores: copas em camadas facetadas com gradiente vertical nos vértices; 3 espécies, 2 a 3 variantes; vento por shader (máscara por cor de vértice).
- Chão: grama em lâminas e tufos por instanciamento (`MultiMeshInstance3D`) com recuo por distância; flores como acentos; arbustos; rochas com musgo; manchas de terra.
- Densidade volumosa nas bordas e aberta nos caminhos. O terreno segue a malha própria (DEC-057); mistura de cores, ruído e decalques entram depois.

## 8. Composição de um mercado
- Ponto focal (poço ou estandarte) e três planos de profundidade: adereços no primeiro, barracas no meio, casas e colinas na névoa ao fundo.
- Toldos de cores quentes sobre pedra e madeira neutras; bandeirolas e lampiões como linhas de condução; caminhos que levam ao foco.
- Repetição com variação (cor do toldo, adereços); elementos verticais (estandartes, postes); multidão de NPCs como elemento vivo.

## 9. Câmeras (coerência)
| Câmera | Alvo | O que tem de funcionar |
|---|---|---|
| Próxima (4 a 8 m) | adereços e materiais | detalhe de superfície; profundidade de campo e vinheta se suportado |
| Isométrica (~20 m, pitch ~50°) | silhueta de telhados e manchas de cor | sombras longas legíveis |
| Estratégica (~60 m) | massa e cor | LOD agressivo, névoa de distância, sem detalhe fino |

Cada peça é aprovada vista nas três.

## 10. Desempenho (DEC-119)
- Meta: média de 60 quadros por segundo ou mais e nenhum quadro acima de 33 ms, no Mac de referência, em release.
- Orçamento visível por cena [HIP]: 400 a 800 mil triângulos e 800 a 1.500 chamadas de desenho; instanciamento para grama e adereços repetidos; um atlas por kit.
- Medição: `tools/visual/run_renderer_test` (cena isolada) e o script de quadros da LW-053A.

## 11. Produção e licenças
- Reuso primeiro: kits CC0 (ver `MANIFESTO_LICENCAS.md`). Uma passada por script normaliza paleta, materiais, oclusão nos vértices, pivô e escala. Nenhuma peça sem licença registrada. Sem serviços de IA 3D de terceiros (conta, licença incerta, qualidade irregular).
- A IA (Claude e agentes) escreve importadores, shaders, regras de espalhamento, luzes e verificações; não pinta à mão. Texturas pintadas, se vierem, vêm de fontes CC0 estilizadas por shader.
- Cada pacote usado entra no manifesto com fonte, autor, licença, versão, data e modificações.

## 12. Plano da pequena cena demonstrativa: Praça do Mercado
- Escopo: praça de cerca de 40 x 40 m, ~10 barracas, poço, 6 a 8 casas ao fundo, ~25 adereços, ~12 árvores, grama e flores, NPCs atuais, 3 predefinições de luz e 3 câmeras.
- Fases: (0) guia, kits e manifesto, e teste de renderers com cena procedural [esta fase]; (1) importação e esqueleto com 1 a 2 kits; (2) montagem e vegetação por script; (3) luz, grade de cor e shaders; (4) medição e relatório.
- Aceite: leitura lado a lado com as referências; DEC-119 cumprida; orçamentos respeitados; manifesto completo; nenhuma mudança na simulação, em autoload ou no `project.godot` sem aprovação.
- Integração futura: substituir as caixas por kits por meio de uma tabela de dados (tipo de local, cena, pegada, variantes), só na apresentação.
- Fora do plano: reforma do cenário atual, personagens e montarias animados, troca definitiva de renderer.

## 13. Renderers
A comparação está em `COMPARACAO_RENDERERS.md`. Nenhuma troca definitiva de renderer está autorizada; o projeto segue em Compatibility.
