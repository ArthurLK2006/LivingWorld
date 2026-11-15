# Diretriz de arte global do Living World

**Status:** APROVADA por Arthur em 15/11/2026 (chat), a partir das duas mensagens dele de 15/11/2026 (direção global e complemento), com as três ressalvas dele incorporadas (seções 1, 3 e 7). Documento de arte: não altera código, dado, contrato, roadmap, `project.godot`, `AGENTS.md` nem `DECISIONS.md`. A proposta de entrada para `DECISIONS.md` (seção 8) segue NÃO registrada. Valores marcados **[HIP]** são hipóteses a calibrar na demonstração; não são requisitos.

## 1. Decisão
A referência do guerreiro low poly com espada, enviada por Arthur, é a **identidade visual do Living World inteiro**, não só dos personagens: um mundo de fantasia estilizado, de **low poly maduro, facetado, visualmente rico e coerente**, humano e heroico, sem aparência de brinquedo. Vale para personagens e NPCs (comerciantes, guardas, aldeões), criaturas futuras, casas, barracas, adereços, mercado, vegetação, rochas, caminhos, biomas e o mundo em geral. A imagem é de terceiros: **não entra no repositório** (ele é público) e serve só como referência de linguagem, nunca para copiar modelo, personagem ou arte de outros (DEC-280).

Não significa mais polígonos, reescrita de sistemas, troca simultânea de todos os assets nem mudança no roadmap. Muda a direção artística final; a disciplina do projeto (testes, CI, contratos, determinismo, medição) fica.

**A referência é linguagem, não molde nem paleta única.** Culturas, regiões, facções, construções e personagens têm variedade e identidade próprias dentro de um estilo visual coerente (ressalva de Arthur, 15/11/2026).

## 2. Linguagem visual
| Eixo | Regra |
|---|---|
| Geometria | Low poly intencional: planos angulares, arestas vivas, chanfros pequenos e silhueta bem construída. "Simplicidade geométrica inteligente", sem sacrificar a qualidade. Nada excessivamente arredondado. |
| Anatomia | Humana, estilizada e convincente; cabeça pequena; rosto sério e natural. Proibido: chibi, olho de brinquedo, bochecha rosada, rosto fofo ou arredondado demais. |
| Roupa, armadura e equipamento | Volumes definidos e camadas visíveis (couro, metal e pano como peças separadas), com presença; uma peça de assinatura diz o papel (guarda, comerciante, aldeão). |
| Material e textura | Materiais estilizados, nunca fotográficos. Low poly NÃO exclui textura nem detalhe: cor por vértice, atlas ou textura estilizada, escolhidos caso a caso pela aparência e pela medição; poucos materiais por personagem e por cena. |
| Paleta | Sóbria e harmoniosa: pouca saturação nas grandes superfícies (pedra, madeira, chão, pano base) e cor viva só em acentos, abaixo da faixa atual do guia (0,35 a 0,45 [HIP]), valor a calibrar; variações por cultura, região e facção (kits de 4 a 6 cores e um acento); pele natural. |
| Arquitetura | Medieval-fantástica, em madeira, pedra e telhados trabalhados (vigas, fiadas de pedra, beirais, telhas), em planos facetados e no módulo de 1 m. |
| Vegetação, relevo e rochas | A mesma linguagem: copas, pedras e relevo em planos e camadas, com silhueta clara. |
| Criaturas e animais | Mesmo nível de desenvolvimento e a mesma linguagem; entram depois, por fatias. |
| Câmeras | A identidade lê em terceira pessoa, isométrica e estratégica (detalhe a 4 m, silhueta a 40 m, mancha de cor a 60 m); cada peça é aprovada nas três. |

## 3. Qualidade não é complexidade
Mais polígonos não são melhor arte: prefere-se um modelo excelente e relativamente simples a um detalhado que prejudique o desempenho. Cada alternativa se compara por **medição real**, não só pela aparência: triângulos por personagem e objeto; materiais e chamadas de desenho; complexidade da animação; LOD por distância; reutilização de malhas, materiais e peças; custo de luz e sombra; legibilidade nas câmeras do jogo. Os orçamentos seguem [HIP] (`GUIA_VISUAL.md`, seções 4 e 10; DEC-119). As ferramentas já existem: `tools/visual/run_renderer_test`, `run_game_capture` e o script de quadros da LW-053A. Também não se trata de reduzir polígonos até o modelo ficar grosseiro: busca-se a melhor relação entre estética, desempenho e esforço de desenvolvimento, avaliada junto (ressalva de Arthur, 15/11/2026).

## 4. Relação com o que já está aprovado
- **DEC-280 e DEC-020** (low poly facetado, rico em detalhes): continuam valendo. Esta diretriz refina o `GUIA_VISUAL.md` e a DEC-280 em três pontos: as "formas gordas" do guia passam a "robustas e angulares"; as "cores equilibradas" da DEC-280 passam a "paleta sóbria por cultura, região e facção" (a luz quente e atmosférica fica); a textura estilizada, que o guia restringia a cor por vértice ou paleta e atlas, é permitida onde aparência e medição a justificarem (a DEC-280 já fala em "texturas de aparência artística").
- **DEC-021** (fonte de arte híbrida): os modelos Quaternius CC0 seguem como base técnica, modelo provisório ou recurso final adaptado, conforme a qualidade obtida.
- **DEC-119** (desempenho) e o renderer Mobile (PR #63, aprovado por Arthur em 15/11/2026): valem; nada aqui depende de um renderer.
- **Contrato dos personagens animados** (`docs/modules/presentation.md`, aprovado por Arthur no PR #59): preserva o visual original da Quaternius, sem normais planas nem troca de textura. A hipótese da D1 (decimar, normais planas, cor por face) vai contra essa linha: se a D1 for aceita, o contrato precisa de um aditivo (classe 3, com o aceite de Arthur) ANTES de qualquer adoção. A D1 é isolada e não entra no jogo.
- Nada altera `AGENTS.md`, `DECISIONS.md`, contratos, roadmap ou arquivos protegidos (o aditivo acima só vem depois do aceite da D1). A proposta de entrada para `DECISIONS.md` está na seção 8.

## 5. O que se preserva, adapta, suspende e substitui
| | O quê |
|---|---|
| **Preservar** | Simulação, economia, facções, NPCs, ponte, saves e determinismo. Testes, CI, contratos, arquitetura e manifesto de licenças. Renderer Mobile e a calibração de luz; LOD (`data/lod_params.json`), pool e cápsula como reserva; ferramentas de captura e medição. **O pipeline procedural da praça**: o `PlazaMeshKit` já gera malhas facetadas (normal plana por triângulo, cor por vértice, oclusão barata, sem textura) e alimenta o chão, as barracas, as estruturas, as árvores, as rochas e os arbustos da praça; o terreno e a decoração do mundo têm código próprio, ainda não conferido quanto à forma. **Personagens**: ativos Quaternius CC0 no repositório (esqueleto de 65 ossos, clipes de idle e walk), catálogo de peças, aparência por hash, paletas, montador e barba (estes dois em curso). |
| **Adaptar** | Paleta da praça A (hoje quente e saturada: toldos vermelhos, laranja e amarelos, bandeirolas ciano; as variantes B e C já são mais frias e sóbrias) e a do resto do mundo, para sóbria, com acentos e variação por região, cultura e facção. Arquitetura e adereços: chanfros intencionais, camadas e silhueta (vigas, fiadas de pedra, telhas, beirais), "robustas e angulares". Vegetação e rochas: planos e camadas. **Personagens**: a Quaternius é semirrealista e suave; hipótese [HIP] a demonstrar: decimar com o LOD do importador, normais planas, cor por face em um material e peças rígidas de armadura sobre os ossos. Textos: `GUIA_VISUAL.md` (pontos da seção 4) e `BRIEF_PERSONAGENS.md`. Dados: `character_palettes.json` e as paletas da praça e do terreno. |
| **Suspender** (até o aceite da D1, a demonstração da seção 6) | O shader de paleta de pano no Mobile (4b) e a integração visível dos personagens animados no mundo real (4c), as duas partes da entrega 4 do contrato dos personagens animados: a cápsula segue como está. ART-6b e ART-7 (caminhos e adereços de povoado, "em espera" na FILA): esperam a paleta e as regras de forma. O humanoide procedural do zero (protótipo do guarda, pausado) só retoma se a D1 mostrar que a base não serve; a ART-9 segue suspensa. |
| **Substituir** | Nada funcional. A cápsula só sai de cena quando houver personagem aceito, e continua como reserva. |

## 6. Adoção por etapas
| Etapa | O que | Saída | Aceite |
|---|---|---|---|
| 1 | Definir a linguagem visual compartilhada | este documento, regras de forma e paletas-base | Arthur |
| 2 | Validar UM personagem representativo (o guarda) | capturas e medição | Arthur |
| 3 | Validar um pequeno conjunto de arquitetura e objetos (uma barraca, o poço, cerca de 6 adereços) | capturas e medição | Arthur |
| 4 | Pequena cena com o estilo atual e a nova linguagem lado a lado (a mesma praça) | 3 câmeras x 3 luzes | Arthur |
| 5 | Medir qualidade visual e desempenho (Mobile, release) | tabela de custo e recomendação | Arthur |
| 6 | Expandir aos poucos (personagens, construções, vegetação, criaturas, ambientes), em paralelo ao roadmap funcional | uma fatia por vez, até cerca de 450 linhas de código, com contrato e aceite | Arthur |

**Primeira demonstração (D1 = etapas 2 a 5, autorizada por Arthur em 15/11/2026):** uma cena isolada de teste (nada entra no jogo), com a praça A dividida em "atual" e "nova linguagem": (a) o guarda, a partir da base Quaternius, em duas camadas, perto (cerca de 4 a 6 mil triângulos) e longe (cerca de 1 mil), com a mesma ficha e a mesma animação [HIP]; (b) uma barraca, o poço e cerca de 6 adereços com paleta sóbria, chanfros e camadas, só por parâmetros e dados dos geradores atuais; (c) 3 câmeras x 3 luzes e medição em release no Mobile (triângulos, chamadas de desenho, ms por quadro, memória de vídeo). O aceite é visual, de Arthur, com a medição ao lado (qualidade e desempenho avaliados juntos); a DEC-119 é piso. Se a base Quaternius não servir, o próximo passo é híbrido (peças próprias só onde faltar), nunca uma nova rodada do estilo rejeitado.

## 7. O que depende de Arthur
1. O texto foi aceito em 15/11/2026. Falta, se ele quiser, **pedir expressamente** o registro da proposta da seção 8 em `DECISIONS.md` (arquivo protegido: sem esse pedido não o altero).
2. O início da D1 foi autorizado por Arthur no chat de 15/11/2026 ("Autorizo a D1") e mantido na aprovação desta diretriz ("Mantenha a D1 em andamento"); está em andamento.
3. O aceite visual da D1 e, depois, de cada fatia, antes de qualquer expansão e antes de personagem no mundo real. **Aprovar esta diretriz NÃO aprova antecipadamente os modelos, a praça nem a paleta da D1:** as capturas e as medições passam pelo aceite visual de Arthur antes de qualquer adoção visual no jogo principal (ressalva dele, 15/11/2026).

Não dependem dele: o Mandato 1, as entregas funcionais já autorizadas (contratos, comerciante, montador e catálogo), revisões e CI. Nenhuma tarefa nova entra no roadmap sem uma proposta objetiva e a aprovação dele (a proposta vem depois da etapa 5).

## 8. Proposta de entrada para `DECISIONS.md` (não registrada)
**DEC-NNN — Direção artística global: low poly maduro e facetado (refina a DEC-280).**
- **Contexto:** em 15/11/2026 Arthur definiu que a referência do guerreiro low poly com espada é a identidade visual do jogo inteiro, com estética madura, facetada, humana e heroica, sem aparência infantil ou de brinquedo, e paleta sóbria.
- **Decisão:** a direção de `docs/arte/DIRETRIZ_ARTE_GLOBAL.md` vale para personagens, criaturas, construções, adereços, vegetação, rochas, caminhos e biomas, adotada por etapas e sempre com aceite visual de Arthur; a qualidade é medida por aparência e por medição, não por contagem de polígonos.
- **Justificativa:** coerência de identidade; refina a DEC-280 (continua facetada e rica em detalhes) sem refazer sistemas.
- **Consequências:** `GUIA_VISUAL.md` e `BRIEF_PERSONAGENS.md` seguem a diretriz; nada muda em `AGENTS.md`, contratos, roadmap ou renderer; as entregas visíveis de personagens (4b e 4c, partes da entrega 4 do contrato dos personagens animados) e ART-6b e ART-7 esperam o aceite da D1.
- **Relações:** DEC-020, DEC-021, DEC-119, DEC-280.

## 9. Rastreio
- 13/11/2026: DEC-280 e o guia visual. 14/11/2026: DEC-021 aprovada; brief de personagens proposto; base Quaternius CC0 aprovada (abordagem A agora, C híbrida depois); mandato dos personagens animados.
- 15/11/2026: renderer Mobile aprovado como oficial; contrato dos personagens animados mesclado (PR #59); esta diretriz proposta e APROVADA por Arthur no mesmo dia, com três ressalvas incorporadas.
