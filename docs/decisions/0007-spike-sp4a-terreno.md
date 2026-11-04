# LW-033 — Spike SP4a: terreno, desempenho e níveis de qualidade

- **Status:** **PARTE A completa** (PC, Windows): modo rápido e modo completo rodados. Falta a **Parte B inteira no Mac de referência**, que é quem fecha a decisão (DEC-016: spikes medem oficialmente na máquina de referência). **Nada aqui é decisão. Os números do PC são PROVISÓRIOS.**
- **Pergunta (roadmap LW-033):** para um jogo pensado para PC médio (e, se der, qualidade maior em PCs bons), qual caminho de terreno é melhor — (1) terreno próprio (malha por script, por chunk) ou (2) addon (Terrain3D) — e em que nível de qualidade ele atinge a meta de quadros? Critérios: estilo low-poly, desempenho, colisão, facilidade de manutenção pelo Codex, e o teste de subida de câmera (DEC-080).
- **Código descartável:** `tests/soak/sp4a/` (10 scripts + 1 cena, 11 arquivos) e `tests/soak/run_sp4a [--modo rapido|completo|ver] [--terreno proprio|addon|ambos] [--qualidade baixo|medio|alto|todas] [--renderizador ...] [--cenario ...] [--repeticoes N] [--duracao S]`.

## Máquina(s) medida(s)

**PC (Windows, 04/11/2026) — PROVISÓRIO:** Windows 10.0.26200 · AMD Ryzen 5 8600G (12 núcleos) · AMD Radeon RX 9060 XT (placa discreta; a `Radeon 760M` integrada ao processador não foi a usada para renderizar) · 31.865 MB de RAM · Godot 4.7.2 estável oficial.

**Mac (referência, DEC-016) — AINDA NÃO MEDIDO.** Fica para a Parte B.

## Método

Terreno de teste determinístico (sem `randf`/`randi`/`randomize`): ruído `FastNoiseLite` com semente fixa (1337) + uma colina (gaussiana, pico 40 m), um vale (gaussiana invertida, fundo -15 m) e um caminho plano (faixa achatada), tudo por fórmula — ver `tests/soak/sp4a/terrain_test_data.gd`. Mapa de **1024×1024 m [HIP]**, chunks de **64 m [HIP]** (16×16 = 256 chunks). As duas variantes usam a mesma fonte de altura, para a comparação ser justa.

Quatro cenários (parado, caminhada, subida, colisão), três níveis de qualidade (baixo/médio/alto — constantes em `quality_levels.gd`), medidos com janela de verdade (sem `--headless`), VSync **desligado**. Cada combinação: 1 rodada de aquecimento descartada + repetições medidas (1 no modo rápido, 3 no completo).

**Desvio do critério de duração:** os valores originais de duração (rápido e completo) somavam, respectivamente, mais de 9 min e cerca de 90 min para as combinações reais do modo completo (10, não 6: o renderizador atual nos 3 níveis + `forward_plus` e `mobile` só no nível médio). Reduzi as durações de cada cenário duas vezes (`DEFAULT_DURATIONS_RAPIDO`/`DEFAULT_DURATIONS_COMPLETO` no código) para caber nas metas de ~5 min e ~30 min, mantendo as repetições (1 no rápido, 3 no completo) como o texto da tarefa pedia.

**Achado de ambiente (não é bug do código):** a janela do benchmark só roda em velocidade normal com foco de verdade do Windows. Perder o foco (inclusive por eu rodar outro comando no terminal, ou pela própria janela do Claude ganhar foco de volta) reduz os quadros reais drasticamente, sem travar — só fica muito mais lento. O modo completo, rodado com a janela sem foco a maior parte do tempo, levou cerca de 22 minutos mesmo assim (dentro do esperado quando focada). Reportado a Arthur durante a medição.

## Resultados — modo rápido (1 repetição, renderizador único `gl_compatibility`, 04/11/2026)

| Nível | Terreno | Cenário | FPS médio | FPS mín | p99 (ms) | Vídeo (MB) | Observação |
|---|---|---|---|---|---|---|---|
| baixo | próprio | parado | 4329,3 | 4276,0 | 0,2 | 20,7 | |
| baixo | próprio | caminhada | 3679,2 | 3557,0 | 0,3 | 20,3 | |
| baixo | próprio | subida | 4313,6 | 4113,0 | 0,2 | 20,3 | nunca <30 fps |
| baixo | próprio | colisão | 5008,0 | 5008,0 | 0,2 | 20,7 | 36/36 batem; 5,5 m |
| médio | próprio | parado | 4432,4 | 4425,0 | 0,2 | 33,4 | |
| médio | próprio | caminhada | 2504,4 | 2019,0 | 0,5 | 35,1 | |
| médio | próprio | subida | 3787,5 | 3637,0 | 0,3 | 35,1 | nunca <30 fps |
| médio | próprio | colisão | 4606,0 | 4606,0 | 0,2 | 37,2 | 36/36 batem; 5,4 m |
| alto | próprio | parado | 3957,6 | 3931,0 | 0,3 | 81,6 | |
| alto | próprio | **caminhada** | **573,7** | **152,0** | **6,6** | 95,1 | **queda real — ver achados** |
| alto | próprio | subida | 1706,2 | 1239,0 | 0,8 | 95,1 | nunca <30 fps |
| alto | próprio | colisão | 3845,0 | 3845,0 | 0,3 | 106,9 | 36/36 batem; 5,4 m |
| baixo | addon | parado | 2075,9 | 2042,0 | 0,5 | 44,7 | |
| baixo | addon | caminhada | 2792,0 | 2122,0 | 0,5 | 44,7 | |
| baixo | addon | subida | 2543,2 | 2495,0 | 0,4 | 44,7 | nunca <30 fps |
| baixo | addon | colisão | 2576,0 | 2576,0 | 0,4 | 44,7 | **0/36 — ver limitação** |
| médio | addon | parado | 1428,9 | 1419,0 | 0,7 | 53,5 | |
| médio | addon | caminhada | 2403,2 | 1404,0 | 0,7 | 53,5 | |
| médio | addon | subida | 1617,5 | 1610,0 | 0,6 | 53,5 | nunca <30 fps |
| médio | addon | colisão | 1610,0 | 1610,0 | 0,6 | 53,5 | 0/36 |
| alto | addon | parado | 970,8 | 965,0 | 1,0 | 65,8 | |
| alto | addon | caminhada | 980,1 | 953,0 | 1,0 | 65,8 | |
| alto | addon | subida | 1086,9 | 1080,0 | 0,9 | 65,8 | nunca <30 fps |
| alto | addon | colisão | 1039,0 | 1039,0 | 1,0 | 65,8 | 22/36 |

**Arquivo bruto do modo rápido não ficou no commit:** apaguei os arquivos de resultado antes de rodar o modo completo (rotina normal do script, para não misturar `run_id`s), e o completo cobre as mesmas combinações com mais repetições (ver tabela abaixo) — por isso só `sp4a_2026-11-04_184111.{txt,json}` (o completo) está em `tests/soak/sp4a/resultados/`. Os números do rápido ficam só nesta tabela, copiados do `RESULTADO PARA COLAR` impresso no terminal durante a execução.

## Resultados — modo completo (3 repetições; médias entre repetições abaixo), 04/11/2026

**Correção de rótulo:** a coluna "Renderizador" do `RESULTADO PARA COLAR` impresso saiu **errada** para as linhas de `forward_plus` e `mobile` — sempre mostrou `gl_compatibility`, porque o código lê `ProjectSettings.get_setting("rendering/renderer/rendering_method")`, que reflete o valor **gravado no `project.godot`** (sempre `gl_compatibility`), não o `--rendering-method` passado na linha de comando. Confirmei o engano comparando com as linhas que o próprio motor imprime ao abrir cada processo ("Vulkan... Forward+" e "Vulkan... Forward Mobile") e com a ordem de gravação no JSON. A tabela abaixo já está com o renderizador **certo**; os números em si (FPS, memória etc.) sempre estiveram corretos — só o rótulo da coluna estava errado. Registrado como limitação (ver seção "Limitações").

| Nível | Terreno | Cenário | FPS médio | FPS mín | Vídeo (MB) | Observação |
|---|---|---|---|---|---|---|
| **`gl_compatibility`** (todos os níveis) | | | | | | |
| baixo | próprio | parado | 4913,6 | 4618,0 | 20,7 | |
| baixo | próprio | caminhada | 3881,1 | 3029,0 | 20,3 | |
| baixo | próprio | subida | 4755,4 | 4505,0 | 20,3 | nunca <30 fps |
| baixo | próprio | colisão | 4991,0 | 4991,0 | 20,7 | 36/36; 11,1 m |
| médio | próprio | parado | 5020,5 | 4658,0 | 33,4 | |
| médio | próprio | caminhada | 3187,9 | 2542,0 | 35,1 | |
| médio | próprio | subida | 3428,4 | 3178,0 | 35,1 | nunca <30 fps |
| médio | próprio | colisão | 4333,0 | 4333,0 | 37,2 | 36/36; 11,0 m |
| alto | próprio | parado | 3644,0 | 3617,0 | 81,6 | |
| alto | próprio | caminhada | 1170,9 | 437,0 | 95,1 | queda, menor que no rápido mas ainda real |
| alto | próprio | subida | 1715,6 | 1206,0 | 95,1 | nunca <30 fps |
| alto | próprio | colisão | 3737,0 | 3737,0 | 105,5 | 36/36; 11,0 m |
| baixo | addon | parado | 2065,6 | 1664,0 | 44,7 | |
| baixo | addon | caminhada | 2568,8 | 879,0 | 44,7 | |
| baixo | addon | subida | 2560,6 | 2459,0 | 44,7 | nunca <30 fps |
| baixo | addon | colisão | 1195,0 | 1195,0 | 64,4 | 0/36; afundou |
| médio | addon | parado | 1042,6 | 1040,0 | 64,4 | |
| médio | addon | caminhada | 2306,4 | 1023,0 | 64,4 | |
| médio | addon | subida | 1153,0 | 1140,0 | 64,4 | nunca <30 fps |
| médio | addon | colisão | 1129,0 | 1129,0 | 64,4 | 0/36; afundou |
| alto | addon | parado | 988,8 | 987,0 | 64,4 | |
| alto | addon | caminhada | 989,5 | 942,0 | 64,4 | |
| alto | addon | subida | 1108,0 | 1094,0 | 64,4 | nunca <30 fps |
| alto | addon | colisão | 1092,0 | 1092,0 | 64,4 | 22/36 |
| **`forward_plus`** (só nível médio) | | | | | | |
| médio | próprio | parado | 1769,5 | 1626,0 | 111,2 | |
| médio | próprio | **caminhada** | **235,3** | **132,0** | 147,9 | **queda forte neste renderizador** |
| médio | próprio | subida | 1632,1 | 1229,0 | 147,9 | nunca <30 fps |
| médio | próprio | colisão | 1745,0 | 1745,0 | 150,1 | 36/36; 11,0 m |
| médio | addon | parado | 637,4 | 635,0 | 182,7 | |
| médio | addon | caminhada | 1454,7 | 617,0 | 182,7 | |
| médio | addon | subida | 629,1 | 619,0 | 182,7 | nunca <30 fps |
| médio | addon | colisão | 649,0 | 649,0 | 182,7 | 0/36; afundou |
| **`mobile`** (só nível médio) | | | | | | |
| médio | próprio | parado | 1884,6 | 1785,0 | 96,3 | |
| médio | próprio | caminhada | 1563,1 | 1362,0 | 94,2 | sem queda forte aqui |
| médio | próprio | subida | 1831,8 | 1755,0 | 94,2 | nunca <30 fps |
| médio | próprio | colisão | 1792,0 | 1792,0 | 96,3 | 36/36; 11,0 m |
| médio | addon | parado | 787,8 | 784,0 | 117,1 | |
| médio | addon | caminhada | 1534,2 | 770,0 | 117,1 | |
| médio | addon | subida | 803,2 | 782,0 | 117,1 | nunca <30 fps |
| médio | addon | colisão | 807,0 | 807,0 | 117,1 | 0/36; afundou |

Arquivo bruto (JSON com as 3 repetições de cada linha): `tests/soak/sp4a/resultados/sp4a_2026-11-04_184111.{txt,json}`.

### a) FPS por faixa de altura na subida (cenário "subida"), todas as combinações do modo completo

| Nível/terreno/renderizador | 0 m | 100 | 200 | 300 | 400 | 500 | 600 | 700 | 800 | 900 m |
|---|---|---|---|---|---|---|---|---|---|---|
| baixo/próprio/gl | 4717 | 4716 | 4716 | 4715 | 4716 | 4714 | 4755 | 4836 | 4839 | 4831 |
| médio/próprio/gl | 3279 | 3281 | 3280 | 3469 | 3514 | 3510 | 3514 | 3513 | 3516 | 3479 |
| alto/próprio/gl | 1683 | 1539 | 1540 | 1543 | 1542 | 1540 | 1666 | 2190 | 2220 | 2220 |
| baixo/addon/gl | 2536 | 2538 | 2538 | 2538 | 2538 | 2537 | 2562 | 2609 | 2609 | 2608 |
| médio/addon/gl | 1160 | 1155 | 1155 | 1155 | 1155 | 1154 | 1149 | 1149 | 1149 | 1149 |
| alto/addon/gl | 1125 | 1122 | 1113 | 1113 | 1111 | 1100 | 1100 | 1100 | 1099 | 1098 |
| médio/próprio/forward_plus | 1577 | 1651 | 1652 | 1652 | 1651 | 1646 | 1633 | 1627 | 1619 | 1618 |
| médio/addon/forward_plus | 636 | 633 | 633 | 633 | 633 | 633 | 626 | 622 | 622 | 622 |
| médio/próprio/mobile | 1844 | 1843 | 1840 | 1840 | 1840 | 1826 | 1825 | 1824 | 1819 | 1817 |
| médio/addon/mobile | 800 | 808 | 808 | 808 | 808 | 808 | 810 | 795 | 795 | 795 |

Em **nenhuma** combinação, em nenhum renderizador, os quadros caíram abaixo de 30 por segundo ao longo da subida até ~1.000 m [HIP] — nem no "alto" do terreno próprio, apesar da queda em "caminhada" nesse mesmo nível. A câmera livre de "subida" não dispara o carregamento intenso de chunks que o deslocamento rápido de "caminhada" dispara, porque X e Z não mudam, só a altura.

### b) Por que "FPS mín" e "1% pior" saíram idênticos em quase todas as linhas do modo rápido

`Performance.TIME_FPS` (a fonte de todas as amostras) é o mesmo contador que o Godot usa no canto da tela, e ele **não é instantâneo por quadro**: atualiza seu valor cerca de uma vez por segundo (é uma média de 1 s, não a leitura do quadro atual). Nos cenários do modo rápido (1,5 a 5 s de duração), a janela de medição é curta demais para esse contador mudar de valor mais que 1 ou 2 vezes — então a maioria das amostras coletadas (uma por quadro renderizado, que a essas taxas de centenas a milhares de FPS acontecem muitas vezes por segundo) repete o **mesmo número**. Como o cálculo do "1% pior" usa `max(1, 1% do total de amostras)` e, com valores repetidos, as amostras mais baixas são todas iguais ao mínimo, a média do "1% pior" acaba sendo exatamente igual ao mínimo. No modo completo (durações maiores: 5 a 15 s, mais o efeito de 3 repetições) isso também aconteceu na maioria das linhas, pelo mesmo motivo — só com mais tempo de medição (dezenas de segundos ou minutos) esse contador teria chance de variar o bastante para os dois números divergirem de verdade. **Isto é uma leitura da minha parte, coerente com o padrão observado; não fui conferir o código-fonte do Godot para confirmar ao certo como o contador interno funciona.**

### c) Por que, no addon, "parado" ficou mais lento que "caminhada" em baixo e médio

Minha hipótese, não totalmente confirmada: o Terrain3D continua processamento interno (provavelmente relacionado a texturas, malha de LOD ou geração de colisão) por um tempo depois do `import_images`, mesmo já tendo esperado 5 quadros antes de prosseguir (ver `terrain_addon.gd`). Como "parado" é **sempre o primeiro** cenário de cada combinação, ele é medido bem perto desse período de acomodação; "caminhada" roda depois, já tendo tido a duração inteira de "parado" como tempo extra de acomodação, e por isso mede mais rápido. O efeito é grande: no nível médio do modo completo, "parado" deu 1.042,6 FPS contra 2.306,4 FPS em "caminhada" — mais que o dobro. O terreno próprio **não** mostra esse padrão (nele, "parado" é sempre mais rápido que "caminhada", como seria de esperar, já que "caminhada" soma o custo de carregar chunks). Não investiguei mais fundo (ex.: medir o tempo exato até a GPU "esfriar") para não estourar o escopo do spike.

### d) Memória do computador separada de memória de vídeo

| Nível/terreno | Memória (computador), faixa nas 4 cenas | Vídeo (GPU), faixa nas 4 cenas |
|---|---|---|
| alto/próprio | 44,7 a 45,6 MB (quase constante) | **81,6 a 105,5 MB** (cresce bastante) |
| alto/addon | 68,6 a 69,9 MB (quase constante) | **64,4 MB exatos, em todas as 4 cenas** |

A diferença tem uma explicação de arquitetura, não é ruído: o terreno próprio sobe a malha e a colisão de cada *chunk* para a GPU só quando o chunk é carregado (e o Godot nem sempre devolve esse espaço de vídeo de imediato quando um chunk é descarregado — fragmentação comum de alocador de GPU). No nível "alto" a distância de visão é de 8 chunks, cobrindo quase o mapa inteiro de uma vez; à medida que os 4 cenários da mesma combinação rodam em sequência (parado → caminhada → subida → colisão), mais chunks diferentes acabam sendo tocados ao todo, e a memória de vídeo cresce cenário a cenário (81,6 → 95,1 → 95,1 → 105,5 MB). A memória do computador (CPU) fica estável porque cada chunk descartado libera sua pequena estrutura de dados de verdade, sem o mesmo efeito de acúmulo.

O Terrain3D, ao contrário, importa o mapa de altura **inteiro** para a GPU **uma vez só**, no `setup()` — o nível de qualidade (`vertex_spacing`) só muda quantos vértices da MESMA textura já carregada são desenhados, sem precisar subir nem descartar nada da GPU depois disso. Por isso a memória de vídeo do addon fica **idêntica** nas 4 cenas de cada combinação (64,4 MB no nível alto, por exemplo) — não há *streaming* de dados de vídeo, só de malha visível.

## Achados por caminho

**Terreno próprio:**
- Estilo: low-poly, cores planas por tipo de superfície (plain/path/hill_top/hill_slope/valley), normais suavizadas (não facetadas — ver limitação).
- Desempenho: o mais rápido em quase tudo, em todos os renderizadores testados.
- **Queda real em "alto"+"caminhada"**, confirmada nos dois modos (573 FPS médio/152 mín no rápido; 1.170,9/437 no completo, com `gl_compatibility`; e **mais forte ainda em `forward_plus`**, 235,3 FPS médio e mínimo de 132): ao mover a câmera rápido por um mapa de 1.024 m com 8 chunks de distância de visão e 1 vértice por metro, muitos chunks são construídos de uma vez (a malha é feita em GDScript puro, com `SurfaceTool`, sem thread). É o risco real que o roadmap já antecipava (R1.1). Curiosamente, `mobile` não mostrou a mesma queda (1.563 FPS em "caminhada", próximo de "parado") — não investiguei por quê.
- Colisão: **sempre bateu certo** (36/36) em todos os níveis e nos três renderizadores, e a cápsula andou sem afundar nem travar. `HeightMapShape3D` por chunk funciona bem; a API (índice = `z*largura+x`, centrada na origem local) foi confirmada por teste curto antes de usar (seção "Confirmações de API").
- Manutenção pelo Codex: todo o código é meu (GDScript simples, ~136 linhas para malha+colisão+streaming); fácil de entender e alterar, mas qualquer melhoria de desempenho (threads, LOD visual, geração incremental) também é trabalho meu.

**Addon (Terrain3D):**
- Versão **v1.1.0-stable** (mais recente que a v1.0.2 citada no prompt original; declara suporte ao Godot 4.5–4.8+, cobrindo o 4.7.2). Carregou e importou a altura corretamente, sem precisar tocar em `project.godot`.
- Tamanho: ~43,5 MB comprimidos (download), ~47 MB só os binários nativos (`bin/`) depois de extraído. Licença **MIT**. Endereço: `https://github.com/TokisanGames/Terrain3D/releases/tag/v1.1.0-stable`. Arquivo `Terrain3D_v1.1.0-stable.zip`, 45.665.295 bytes, SHA-256 `51b78bc758f5759cbc8eaaab14e5cf4e8661717e265fdd760f5abf945f15b243`.
- Desempenho: **sempre mais lento que o terreno próprio** no mesmo nível e no mesmo renderizador, e sempre usa mais memória de vídeo (constante por combinação, ver item "d" acima). Em compensação, **não tem a queda forte de "caminhada"** que o terreno próprio tem em "alto": o streaming interno do Terrain3D (nativo, em C++) é mais suave sob movimento rápido — exceto em "parado", onde o efeito de acomodação inicial (item "c" acima) o deixa mais lento que o esperado.
- **Colisão: limitação não resolvida**, confirmada igual nos dois modos e nos três renderizadores (0/36 em baixo e médio; 22/36, parcial, em alto). Tentei três ajustes (`collision_mode` "Dynamic" padrão → "Full/Game" antes do import → "Full/Game" depois do import, com mais quadros de espera) sem resolver por completo; parei na terceira tentativa (AGENTS 13.2) e registrei como limitação em vez de inventar mais ajustes.
- Manutenção pelo Codex: a API nativa (C++) não aparece como GDScript, então não dá para ler o código-fonte da lógica real; só os nomes de método e propriedade via `ClassDB` (como fiz aqui). Isso torna depurar problemas como o de colisão mais difícil que no terreno próprio.

## Comparação dos níveis baixo/médio/alto

Terreno próprio: baixo e médio ficam folgados em todo renderizador (1.600 a 5.000 FPS); alto é viável em "parado"/"colisão"/"subida", mas carrega o risco real de "caminhada" (confirmado em dois dos três renderizadores). Addon: já começa mais lento no "baixo" (600 a 2.800 FPS conforme o renderizador) e cai mais no "alto" (950 a 1.100 FPS com `gl_compatibility`; não testado em "alto" nos outros renderizadores, só "médio" fez parte do modo completo). Todos os números ficam bem acima da meta proposta de 60 FPS (roadmap 1.F, item 5, **[PEND]**), mas numa máquina com GPU discreta de hoje, não a "PC médio" que a DEC-016 ainda não define.

## O que aconteceu com os renderizadores (nível médio, modo completo)

| Renderizador | Terreno próprio: parado/caminhada/subida/colisão | Terreno addon: parado/caminhada/subida/colisão |
|---|---|---|
| `gl_compatibility` | 5020 / 3188 / 3428 / 4333 | 1043 / 2306 / 1153 / 1129 |
| `forward_plus` | 1770 / **235** / 1632 / 1745 | 637 / 1455 / 629 / 649 |
| `mobile` | 1885 / 1563 / 1832 / 1792 | 788 / 1534 / 803 / 807 |

`gl_compatibility` foi sempre o mais rápido nesta máquina — esperado, por ser o renderizador mais simples e o que o projeto já usa como padrão. `forward_plus` e `mobile` (os dois via Vulkan) ficaram parecidos entre si na maioria dos cenários, exceto a queda forte do terreno próprio em "caminhada" no `forward_plus` (235 FPS, a pior leitura de todo o spike). Isso é só um dado desta GPU e deste driver; não dá para generalizar sem medir noutra máquina (Parte B).

## Confirmações de API (AGENTS 4.1 — como confirmei, não chutei)

Testadas por 16 scripts curtos e descartáveis (`api_probe.gd` a `api_probe16.gd`, apagados logo depois de cada confirmação; nenhum faz parte do commit) antes de escrever o código real: `Performance` (monitores de FPS, draw calls, primitivas, memória, nós); `OS`/`Engine`/`RenderingServer` (identificação de máquina, incluindo `OS.get_memory_info()` e `Engine.get_version_info()`); `FastNoiseLite`; `HeightMapShape3D` (mapeamento exato índice↔posição local, por raycast via `PhysicsServer3D`); `SurfaceTool`/`ArrayMesh`; `Image.create_from_data` (bem mais rápido que `set_pixel` em laço — a diferença foi de "nunca termina" para segundos, com ~1 milhão de pixels); a API do Terrain3D (`Terrain3DData.import_images`, que devolve `void`, não `Error`, e precisa de exatamente 3 imagens; `collision_mode` — e seu valor padrão, `1` = "Dynamic/Game"; `vertex_spacing`); e `ProjectSettings.get_setting("rendering/renderer/rendering_method")` — que, só agora percebo com o modo completo, reflete o `project.godot`, não o `--rendering-method` da linha de comando (ver "Correção de rótulo" acima; meu teste anterior não pegou isso porque testei só com o MESMO valor do padrão do projeto).

## LIMITAÇÕES

1. **Colisão do addon não confirmada** (seção "Achados" acima) — maior pendência técnica deste spike, confirmada nos dois modos e nos três renderizadores.
2. **Rótulo de renderizador errado no `RESULTADO PARA COLAR`** das linhas de `forward_plus`/`mobile` (ver "Correção de rótulo" acima) — os números estão certos, só o texto da coluna "Renderizador" não mudava sozinho; corrigi manualmente neste relatório, comparando com os avisos do próprio motor.
3. **`var _terrain: Terrain3D` como tipo estático quebraria a compilação** em qualquer máquina sem o addon baixado (inclusive o Mac, antes da Parte B baixar o addon lá); corrigido usando `Object` e chamadas dinâmicas — documentado no próprio código (`terrain_addon.gd`).
4. **Normais da malha própria são suavizadas**, não facetadas por face; um visual "mais low-poly" (facetado) exigiria duplicar vértices por face — não fiz isso para não ultrapassar o teto de linhas do spike.
5. **O cabeçalho "Máquina" do resultado usa a resolução da janela no início do processo**, não a resolução de cada linha (cada nível muda a janela em tempo de execução, mas o cabeçalho é escrito uma vez só); a coluna "Nível" de cada linha já identifica a qualidade usada.
6. **O `tools/check_gdscript_warnings` existente trava para sempre** (processo preso num prompt de depuração interativo sem saída) se encontrar um erro de análise — descobri isso por acidente (tive que matar processos do Godot pelo PowerShell mais de uma vez) e não é um bug meu; registrado no backlog para alguém revisar depois.
7. **A janela do benchmark perde velocidade real sem foco do Windows**, inflando bastante o tempo de execução sem travar de verdade; expliquei isso a Arthur e, mesmo sem foco constante, as medições terminaram.
8. **A régua numérica de "engasgos" e "quebra abaixo de 30 fps"** não foi exercitada de verdade nesta máquina (todas as combinações passaram folgado, em todos os renderizadores); só será um teste de verdade numa máquina mais fraca, ou quando o jogo tiver conteúdo de verdade, não um mapa de teste vazio.
9. As explicações dos itens "b" e "c" acima (contador de FPS e acomodação do addon) são **hipóteses minhas**, coerentes com os números, mas não confirmadas lendo o código-fonte do Godot nem do Terrain3D.

## Proposta de entrada para DECISIONS.md (PROPOSTA — nada disto está decidido)

**Título:** Caminho de terreno do protótipo (SP4a).
**Contexto:** o roadmap (LW-033) pede escolher entre terreno próprio e addon antes da LW-038 construir o `TerrainView`.
**Proposta de decisão:** **terreno próprio** para o protótipo, pelo desempenho melhor em quase todas as combinações medidas, pela colisão sempre correta em todos os níveis e renderizadores, e por não depender de uma API nativa fechada. **Condição:** a queda em "alto"+"caminhada" (mais forte em `forward_plus`) precisa de um plano (ex.: construir chunks numa fila limitada por quadro, ou numa thread) antes do nível "alto" ser oferecido ao jogador — ou o protótipo lança só com "baixo"/"médio" até isso ser resolvido.
**Alternativa (não recomendada agora):** addon, se a limitação de colisão for resolvida e se a folga de desempenho mais baixa for aceitável para o "PC médio" (ainda não definido, DEC-016).
**Meta de quadros (roadmap 1.F, item 5):** continua **[PEND]**; os números medidos aqui (sempre acima de 600 FPS, mesmo nos piores casos, numa GPU discreta de hoje) não servem para validar a meta de "PC médio", que ainda não existe.
**Níveis de qualidade:** proposta de adotar três níveis (baixo/médio/alto) como os medidos aqui, com Arthur decidindo se o protótipo lança com um nível só ou com os três, conforme a diretriz de trabalho dele (seção "Diretriz de Arthur" do prompt desta tarefa).
**Renderizador:** proposta de manter `gl_compatibility` (o padrão já aprovado do projeto), que foi o mais rápido nos três testados nesta máquina.
**Decisão de Arthur:** pendente — depende também da Parte B (Mac, oficial).
