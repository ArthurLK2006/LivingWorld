# Comparação dos renderizadores: Compatibility e Forward+

**Status:** **resultados de 13/11/2026** (executado com janela por ordem de Arthur: Apple M3, Godot 4.7.2, 1280 x 720, vsync desligado, uma execução por renderer). Cena demonstrativa isolada, sem modificar o `project.godot`. Nenhuma troca definitiva de renderer está autorizada; o jogo segue em Compatibility (`gl_compatibility`).

## Por que comparar
As três referências (DEC-280) dependem de efeitos que, pelo que se sabe, são de Forward+ ou Mobile: bloom, profundidade de campo, névoa volumétrica e oclusão ambiente em tempo real. O projeto está em Compatibility, sem decisão registrada que o justifique. O que o Compatibility aceita na Godot 4.7.2 **será confirmado por teste**, não por memória.

## Como rodar (1 comando, abre uma janela por cerca de 2 minutos)
`tools/visual/run_renderer_test [pasta-de-saída]`: roda a cena `scenes/demo/renderer_test.tscn` duas vezes, com `--rendering-method gl_compatibility` e depois `--rendering-method forward_plus`, em modo automático (3 predefinições de luz x 3 câmeras), e grava PNGs e `resumo.txt` por renderer. Não altera o `project.godot`.
Teclas na cena interativa: `1`, `2`, `3` luz (dia, hora dourada, crepúsculo); `Q`, `W`, `E` câmera (próxima, isométrica, estratégica); `B` bloom, `O` oclusão ambiente, `F` névoa, `D` profundidade de campo.

## Onde está o código
- Cena: `scenes/demo/renderer_test.tscn`; código: `tools/visual/renderer_test/` (3 componentes: predefinições, cena e modo automático) e, desde a ART-1, `src/presentation/world_view/plaza/` (6 componentes: kit de malhas, dados, materiais, chão, estruturas e fachada); executor: `tools/visual/run_renderer_test`; testes sem janela: `tests/unit/test_renderer_*.gd` e `tests/unit/test_plaza_*.gd` (7 arquivos, 22 testes). A cena demonstrativa fica FORA de `src/`: não lê a simulação nem a ponte, não é montada pelo jogo, não tem autoload e não altera o `project.godot` (o teste da LW-082h exige que `src/tools` só leia pela ponte, e o `tools/check_input_keys` proíbe teclas fixas em `src/`); os componentes da praça, em `src/presentation/world_view/plaza/`, também não leem a simulação nem a ponte e ainda não são montados pelo jogo.
- Teclas (1, 2, 3 luz; Q, W, E câmera; B, O, F, D efeitos): guardadas como `InputEventKey` na própria cena, porque o `project.godot` é protegido (não há ações novas para elas). A cena mede 63.948 triângulos, 10 materiais, 4 `MultiMeshInstance3D` e 7 luzes pontuais.
- Tamanho: entregue em 5 partes empilhadas (kit e predefinições; dados e materiais; chão e vegetação; barracas, casas e fachada; cena, modo automático e executor), cada uma dentro do limite do AGENTS 5.2 (a maior, a parte 5, tem 429 linhas, dentro da tolerância de 1,5x). A praça gerada é idêntica à da versão em um arquivo só (impressão digital SHA-256 igual antes e depois).

## Achados sem janela (13/11/2026, Godot 4.7.2, headless)
- Em headless, `get_current_rendering_method()` devolve `gl_compatibility`. A cena mede 63.948 triângulos, 80 nós, 66 malhas, 4 `MultiMeshInstance3D` (6.000 tufos de grama e 720 flores), 10 materiais e 7 luzes pontuais.
- Ao ligar no Compatibility, a engine IMPRIME ERRO para a névoa volumétrica ("só Forward+") e para a profundidade de campo ("só Forward+ ou Mobile"): confirmado por experimento. Para a oclusão ambiente e o bloom o setter não imprime nada, e isso NÃO prova que funcionem: só a janela mostra. A tabela de suporte da cena (`RendererPresets.SUPPORTED`) é hipótese [HIP] até a execução com janela; `--force-effects` liga tudo para conferir.

## Medições (13/11/2026; 180 quadros por captura depois de 30 de acomodação)
Compatibility: `opengl3`, efeitos ligados: bloom e névoa (a tabela [HIP] desliga oclusão ambiente, profundidade de campo e névoa volumétrica). Forward+: `metal`, todos os efeitos ligados.

| captura | Compat fps | Compat pior (ms) | F+ fps | F+ pior (ms) | Compat sat./brilho | F+ sat./brilho |
|---|---|---|---|---|---|---|
| dia, próxima | 276 | 8,4 | 132 | 17,9 | 0,33 / 0,78 | 0,36 / 0,67 |
| dia, isométrica | 167 | 11,8 | 77 | 26,4 | 0,23 / 0,79 | 0,24 / 0,69 |
| dia, estratégica | 245 | 11,7 | 506 | 3,0 | 0,10 / 0,81 | 0,10 / 0,76 |
| hora dourada, próxima | 348 | 7,2 | 82 | 25,0 | 0,72 / 0,74 | 0,85 / 0,60 |
| hora dourada, isométrica | 242 | 9,7 | 74 | 19,8 | 0,57 / 0,79 | 0,79 / 0,83 |
| hora dourada, estratégica | 324 | 8,2 | 188 | **38,1** | 0,41 / 0,96 | 0,77 / 0,89 |
| crepúsculo, próxima | 235 | 10,2 | 107 | 25,7 | 0,42 / 0,50 | 0,53 / 0,33 |
| crepúsculo, isométrica | 191 | 10,0 | 93 | 23,1 | 0,42 / 0,60 | 0,71 / 0,36 |
| crepúsculo, estratégica | 290 | 9,4 | 171 | 17,8 | 0,43 / 0,74 | 0,84 / 0,35 |

Chamadas de desenho: 150 a 408 (Compat) e 112 a 296 (F+); memória de vídeo: **22,8 MB** (Compat) contra **162,4 MB** (F+); 63.948 triângulos nos dois. As 18 capturas e os 2 `resumo.txt` ficaram FORA do repositório (pasta `.worktrees/capturas-arte-13-11/` no Mac de Arthur).

## Critérios e leitura
| # | Critério | Compatibility | Forward+ |
|---|---|---|---|
| 1 | Fidelidade visual às referências | Reconhece-se as referências: o dia isométrico lembra a vila da referência 1 (chão ocre, manchas de grama, barracas de toldo colorido) e a hora dourada e o crepúsculo têm contraluz, bandeirolas e lampiões que brilham (bloom), como as referências 2 e 3. Faltam profundidade de campo, névoa volumétrica e oclusão ambiente. Formas facetadas nítidas. | Mais cinematográfico nas tomadas próximas (profundidade de campo e névoa volumétrica das referências 2 e 3) e cores do dia mais ricas; porém as tomadas próximas ficam mais escuras, enevoadas e com granulação no chão, e a nitidez facetada some no fundo desfocado. |
| 2 | Qualidade da iluminação | Sol direcional com sombras, névoa de profundidade e bloom funcionam (lampiões e bandeirolas brilham; a luz local forma uma poça quente). Sem névoa volumétrica nem oclusão ambiente. | Tudo do Compatibility mais oclusão ambiente, névoa volumétrica e profundidade de campo; a hora dourada fica pesada (brilho 0,60 na próxima). |
| 3 | Sombras e materiais | Sombras suaves e nítidas, sem vazamento visível; materiais facetados limpos. | Sombras de contato mais ricas (oclusão ambiente), mas aparece granulação no chão das tomadas próximas (causa não isolada: névoa volumétrica ou oclusão ambiente, a testar ligando um efeito de cada vez). |
| 4 | Vegetação e detalhes | Grama em lâminas (6.000 tufos), flores (720), árvores e adereços aparecem; o shader de vento compilou sem erro. | Igual: aparecem, sem erro de shader. A animação do vento NÃO foi conferida (as capturas são imagens estáticas). |
| 5 | Desempenho (DEC-119: média de 60 fps e nenhum quadro acima de 33 ms) | **Cumpre com folga nas 9 capturas**: 167 a 348 fps, pior quadro 7,2 a 11,8 ms, 22,8 MB de vídeo. | Média acima de 60 fps nas 9 (mínimo 74), mas **1 de 9 passa de 33 ms (38,1 ms)** e 5 de 9 passam de 20 ms; na próxima e na isométrica custa 2 a 4 vezes mais; 162 MB de vídeo (7 vezes). |
| 6 | Compatibilidade com as câmeras | Próxima, isométrica e estratégica leem bem; a isométrica é a mais próxima da referência 1. Na estratégica da hora dourada e do crepúsculo a névoa lava as cores, mas a praça segue legível. | Diferença visual na próxima (profundidade de campo e névoa) e na isométrica (só cor e oclusão). **Na estratégica o dia é quase igual, mas na hora dourada e no crepúsculo a névoa volumétrica e a escuridão engolem a praça, que fica quase ilegível**; é também onde está o quadro de 38,1 ms. |
| 7 | Complexidade de manutenção | É o renderer do projeto: nada muda. Não tem profundidade de campo, névoa volumétrica nem oclusão ambiente. | Exige trocar o `project.godot` (protegido: aprovação específica), reafinar luz e materiais para outra aparência (e manter os dois caminhos, se o jogo quiser suportar os dois), 7 vezes mais memória de vídeo e uma GPU com Metal, Vulkan ou D3D12. |

**Limites da medição:** uma execução por renderer, em build do editor (não de release); o pior quadro de 38,1 ms pode ser um quadro isolado (por exemplo, compilação de shader da troca de luz) e deve ser repetido com mais quadros antes de decidir; a causa da granulação do Forward+ é hipótese.

## Calibração das predefinições de luz (achado do teste, vale para os dois renderers)
Alvos medidos nas referências (saturação / brilho): dia 0,44 / 0,59; hora dourada 0,36 / 0,48. **O dia está claro e pálido demais** (Compatibility 0,23 a 0,33 de saturação e 0,78 a 0,81 de brilho; Forward+ chega a 0,67 a 0,76 de brilho) e **a hora dourada está saturada e clara demais** (Compatibility 0,41 a 0,72 e 0,74 a 0,96; Forward+ 0,77 a 0,85 e 0,60 a 0,89). Isso é calibração das luzes e do ambiente, não do renderer: o próximo passo natural é afinar essas duas predefinições (sol, ambiente e névoa) e medir de novo. **A densidade da névoa também precisa de ajuste por câmera**: na estratégica da hora dourada ela lava a praça no Compatibility e a faz sumir no Forward+, e no crepúsculo o Forward+ deixa a tomada quase preta.

## Como decidir depois dos resultados
- Se o Compatibility entregar o essencial das referências dentro da DEC-119, mantém-se e o guia usa só o que ele suporta.
- Se o ganho do Forward+ for grande e o custo de quadros couber na DEC-119, propõe-se a troca em PR separado (mexe no `project.godot`, arquivo protegido: precisa da aprovação específica de Arthur).
- Qualquer troca exige rodar o `tools/check_all` e a medição de quadros da LW-053A nos dois caminhos.

## Leitura dos resultados (recomendação; a decisão é de Arthur)
- O Compatibility entrega o essencial das referências (formas facetadas, paleta quente, bloom nos emissivos, névoa) com folga na DEC-119 (167 fps ou mais, pior quadro de 11,8 ms). **Recomendação: manter o Compatibility como renderer do jogo** e usar o guia só com o que ele suporta.
- O Forward+ acrescenta profundidade de campo, névoa volumétrica e oclusão ambiente nas tomadas próximas, a 2 a 4 vezes o custo, com um quadro de 38,1 ms em uma das 9 capturas e 7 vezes a memória de vídeo; com a calibração atual, a câmera estratégica fica quase ilegível nele em 2 das 3 luzes. **Reavaliar** só se, depois de calibrar as luzes, as tomadas próximas ainda pedirem esses efeitos; a troca seria um PR à parte (mexe no `project.godot`) com a aprovação específica de Arthur.
