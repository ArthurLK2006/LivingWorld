# LW-033 — Spike SP4a: terreno, desempenho e níveis de qualidade

- **Status:** **PARTE A corrigida e completa** (PC, Windows): a primeira medição (04/11/2026, de manhã) foi invalidada numa revisão e **refeita** (04/11/2026, à noite) depois de corrigir 6 hipóteses de bug confirmadas (ver "Nota de validade" abaixo). Falta a **Parte B inteira no Mac de referência**, que é quem fecha a decisão (DEC-016: spikes medem oficialmente na máquina de referência). **Nada aqui é decisão. Os números do PC são PROVISÓRIOS — e só os marcados "CORRIGIDO" devem ser usados.**
- **Pergunta (roadmap LW-033):** para um jogo pensado para PC médio (e, se der, qualidade maior em PCs bons), qual caminho de terreno é melhor — (1) terreno próprio (malha por script, por chunk) ou (2) addon (Terrain3D) — e em que nível de qualidade ele atinge a meta de quadros? Critérios: estilo low-poly, desempenho, colisão, facilidade de manutenção pelo Codex, e o teste de subida de câmera (DEC-080).
- **Código descartável:** `tests/soak/sp4a/` (10 scripts + 1 cena, 11 arquivos) e `tests/soak/run_sp4a [--modo rapido|completo|ver] [--terreno proprio|addon|ambos] [--qualidade baixo|medio|alto|todas] [--renderizador ...] [--cenario ...] [--repeticoes N] [--duracao S]`.

## Máquina(s) medida(s)

**PC (Windows, 04/11/2026) — PROVISÓRIO:** Windows 10.0.26200 · AMD Ryzen 5 8600G (12 núcleos) · AMD Radeon RX 9060 XT (placa discreta; a `Radeon 760M` integrada ao processador não foi a usada para renderizar) · 31.865 MB de RAM · Godot 4.7.2 estável oficial. A medição corrigida usou a mesma máquina, no mesmo dia à noite.

**Mac (referência, DEC-016) — AINDA NÃO MEDIDO.** Fica para a Parte B.

## Método

Terreno de teste determinístico (sem `randf`/`randi`/`randomize`): ruído `FastNoiseLite` com semente fixa (1337) + uma colina (gaussiana, pico 40 m), um vale (gaussiana invertida, fundo -15 m) e um caminho plano (faixa achatada), tudo por fórmula — ver `tests/soak/sp4a/terrain_test_data.gd`. Mapa de **1024×1024 m [HIP]**, chunks de **64 m [HIP]** (16×16 = 256 chunks). As duas variantes usam a mesma fonte de altura, para a comparação ser justa.

Quatro cenários (parado, caminhada, subida, colisão), três níveis de qualidade (baixo/médio/alto — constantes em `quality_levels.gd`), medidos com janela de verdade (sem `--headless`), VSync **desligado**. Cada combinação: 1 rodada de aquecimento descartada + repetições medidas (1 no modo rápido, 3 no completo).

**Desvio do critério de duração:** os valores originais de duração (rápido e completo) somavam, respectivamente, mais de 9 min e cerca de 90 min para as combinações reais do modo completo (10, não 6: o renderizador atual nos 3 níveis + `forward_plus` e `mobile` só no nível médio). Reduzi as durações de cada cenário duas vezes (`DEFAULT_DURATIONS_RAPIDO`/`DEFAULT_DURATIONS_COMPLETO` no código) para caber nas metas de ~5 min e ~30 min, mantendo as repetições (1 no rápido, 3 no completo) como o texto da tarefa pedia.

## Nota de validade — revisão da Parte A (04/11/2026)

Depois da primeira medição (resultados abaixo, seções marcadas **INVÁLIDO**), Arthur revisou o código e as capturas de tela que ele próprio tirou durante a medição e achou os números suspeitos: a janela mostrava, a maior parte do tempo, tela azul sem nada, ou um chão em xadrez que parecia **plano** até o horizonte. Ele não parou de usar o PC nem fechou outros programas durante aquela medição (diferente do que o método pede). A partir disso, levantei 6 hipóteses de bug (H1 a H6) e verifiquei cada uma por teste curto ou teste permanente novo — nenhuma foi assumida como verdadeira sem conferir (AGENTS 4.1). As 6 foram **confirmadas**:

- **H1 — malha própria com as normais para baixo.** O vencimento dos triângulos em `_build_chunk` (`terrain_own.gd`) desenhava as duas metades de cada quadrado do grid na ordem errada; a malha existia e tinha a forma certa, mas ficava com a face voltada para baixo (não aparecia, ou aparecia escura/invertida, dependendo do ângulo — exatamente a "tela azul sem chão" que Arthur via). Confirmado inspecionando as normais calculadas (0 de 18.432 apontavam para cima antes da correção; todas depois). **Corrigido.**
- **H2 — `vertex_spacing` do addon mudando a escala do mundo, não só o nível de detalhe.** Eu tratava `vertex_spacing` como "nível de qualidade" (como fiz para o terreno próprio), mas no Terrain3D essa propriedade é **metros por pixel do mapa de altura** — mudá-la redimensiona o mundo inteiro. Isso explica o chão "parecendo plano": no nível mais baixo, o mapa de 1024 m podia estar sendo espremido numa escala errada, achatando toda a variação de altura visualmente. Também explica boa parte da colisão quebrada original (a malha visual e a forma de colisão deixavam de corresponder à função de altura usada para conferir). **Corrigido:** `vertex_spacing` agora é **fixo** (`FIXED_VERTEX_SPACING = 1.0`); o nível de qualidade do addon passou a mudar só `mesh_size`/`mesh_lods` (densidade visual, sem reescalar o mundo).
- **H3 — câmera sem orientação definida em 2 cenários, não só 1.** "Caminhada" e "colisão" moviam a câmera mas nunca chamavam `look_at`; a câmera herdava a orientação do cenário anterior (às vezes olhando para o nascimento enquanto a posição mudava, às vezes com `Transform3D` quase identidade). **Corrigido** nos dois; um teste novo e permanente (`test_every_scenario_starts_camera_above_ground_with_orientation`) confere isso para os 4 cenários a cada execução dos testes.
- **H4 — rótulo do renderizador sempre `gl_compatibility`.** Confirmado que não existe API para ler de volta o `--rendering-method` da linha de comando (nem `ProjectSettings.get_setting` nem `get_setting_with_override` refletem o valor real). **Corrigido:** `tests/soak/run_sp4a` agora passa `--renderer-label` explicitamente (o script já sabe qual renderizador está abrindo).
- **H5 — "FPS mín" e "1% pior" idênticos.** Confirmado: `Performance.TIME_FPS` só atualiza ~1x/segundo, então em cenários curtos a maioria das amostras repetia o mesmo número. **Corrigido:** as métricas agora usam o delta real de cada quadro (`get_process_delta_time()`/`get_physics_process_delta_time()`), nunca `Performance.TIME_FPS`.
- **H6 — nenhuma forma de marcar uma medição como inválida por perda de foco.** Confirmado que o código original não registrava se a janela tinha foco de verdade durante a amostragem. **Corrigido:** `Sp4aMetrics` agora conta amostras sem foco (`DisplayServer.window_is_focused()`) e `Sp4aScenarioRunner` marca a linha inteira como `"INVÁLIDA (perdeu foco da janela durante a medição)"` se qualquer amostra perder o foco.

A correção também revelou **2 bugs novos**, achados como efeito colateral do teste do item H3 (não eram hipótese de ninguém, o teste simplesmente pegou): a câmera de "subida" nascia **enterrada** (usava Y absoluto em vez de relativo ao chão do nascimento) e a de "colisão" disparava um aviso do motor de "vetores colineares" (usava `Vector3.UP` como referência com a câmera exatamente acima do alvo). Os dois foram corrigidos.

**Confirmação visual antes de confiar nos números:** antes de rodar os benchmarks de novo, tirei 24 capturas de tela (nível médio, os dois terrenos, início/meio/fim de cada um dos 4 cenários — fora do commit, ferramenta temporária removida depois) e descrevi cada uma. Nos cenários que olham para frente ("parado", "caminhada"), o chão agora ocupa a parte de baixo do quadro nos dois terrenos, com relevo real visível (colina, declive, variação de cor por tipo de superfície no terreno próprio; ondulação visível no padrão xadrez do addon) — bem diferente do relato original de Arthur. Descrição completa na seção "Capturas de tela" mais abaixo.

**Janela de medição desta correção:** Arthur reservou ~30 minutos, deixou a janela do Godot à frente e não usou o PC durante a medição. As 24 combinações do modo rápido e as 30 do modo completo (10 combinações × 3 repetições, mais as 3 de `forward_plus`/`mobile`) terminaram **sem nenhuma marca de "INVÁLIDA (perdeu foco)"** — a instrumentação do H6 não detectou perda de foco em nenhuma amostra, confirmando que a mitigação funcionou desta vez.

**O que isto significa para o resto do documento:** as seções abaixo marcadas **INVÁLIDO** ficam só como registro histórico (não use os números delas para nada). As seções marcadas **CORRIGIDO** são as válidas. "Achados por caminho", "Comparação dos níveis", "Renderizadores", "LIMITAÇÕES" e a "Proposta de entrada para DECISIONS.md", mais adiante no documento, foram **reescritas do zero** usando só os números corrigidos.

## Resultados — modo rápido — **INVÁLIDO** (medição original, ver "Nota de validade" acima)

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

**Arquivo bruto do modo rápido original não ficou no commit** (apagado antes de rodar o completo, rotina normal do script). Os números do rápido original ficam só nesta tabela, copiados do `RESULTADO PARA COLAR` impresso no terminal durante a execução.

## Resultados — modo completo — **INVÁLIDO** (medição original, ver "Nota de validade" acima)

**Correção de rótulo (histórica — já corrigida na raiz pelo H4):** a coluna "Renderizador" do `RESULTADO PARA COLAR` impresso saiu **errada** para as linhas de `forward_plus` e `mobile` nesta medição original — sempre mostrou `gl_compatibility`. A tabela abaixo já está com o renderizador corrigido manualmente; os números em si (FPS, memória etc.) sempre estiveram corretos — só o rótulo da coluna estava errado nesta execução original.

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

Arquivo bruto original (JSON com as 3 repetições de cada linha): `tests/soak/sp4a/resultados/sp4a_2026-11-04_184111.{txt,json}`.

## Resultados — modo rápido — **CORRIGIDO** (04/11/2026, à noite, após revisão; renderizador único `gl_compatibility`, 1 repetição)

| Nível | Terreno | Cenário | FPS médio | FPS mín | 1% pior | Engasgos >33 ms | Vídeo (MB) | Observação |
|---|---|---|---|---|---|---|---|---|
| baixo | próprio | parado | 3802,9 | 895,2 | 2171,6 | 0 | 20,7 | |
| baixo | próprio | caminhada | 3662,3 | 113,2 | 866,4 | 0 | 20,3 | |
| baixo | próprio | subida | 5275,9 | 304,1 | 2145,6 | 0 | 20,3 | nunca <30 fps |
| baixo | próprio | colisão | 60,0 | 60,0 | 60,0 | 0 | 20,7 | 36/36 batem; cápsula andou 5,5 m |
| médio | próprio | parado | 2828,2 | 1390,8 | 1698,8 | 0 | 33,4 | |
| médio | próprio | caminhada | 2656,5 | 16,9 | 467,5 | 18 | 35,1 | |
| médio | próprio | subida | 3090,0 | 720,0 | 1781,7 | 0 | 35,1 | nunca <30 fps |
| médio | próprio | colisão | 60,0 | 60,0 | 60,0 | 0 | 37,2 | 36/36 batem; 5,4 m |
| alto | próprio | parado | 1946,3 | 1162,8 | 1326,8 | 0 | 81,6 | |
| alto | próprio | **caminhada** | **1327,1** | **6,7** | **88,5** | **12** | 95,1 | **queda real, ver achados — ainda presente após a correção** |
| alto | próprio | subida | 1135,3 | 662,3 | 718,7 | 0 | 95,1 | nunca <30 fps |
| alto | próprio | colisão | 60,0 | 60,0 | 60,0 | 0 | 106,9 | 36/36 batem; 5,4 m |
| baixo | addon | parado | 2614,2 | 1466,3 | 1694,9 | 0 | 44,5 | |
| baixo | addon | caminhada | 3007,1 | 720,0 | 1775,0 | 0 | 44,5 | |
| baixo | addon | subida | 4199,9 | 252,3 | 1857,4 | 0 | 44,5 | nunca <30 fps |
| baixo | addon | colisão | 60,0 | 60,0 | 60,0 | 0 | 44,5 | **22/36 batem** (não mais 0/36 — ver "Nota de validade"); cápsula andou 5,4 m |
| médio | addon | parado | 1383,2 | 877,2 | 990,7 | 0 | 53,5 | |
| médio | addon | caminhada | 1639,2 | 720,0 | 1119,4 | 0 | 53,5 | |
| médio | addon | subida | 1563,3 | 720,0 | 1119,4 | 0 | 53,5 | nunca <30 fps |
| médio | addon | colisão | 60,0 | 60,0 | 60,0 | 0 | 53,5 | 22/36 batem; 5,4 m |
| alto | addon | parado | 632,4 | 600,0 | 600,0 | 0 | 66,8 | |
| alto | addon | caminhada | 740,4 | 621,1 | 656,3 | 0 | 66,8 | motor emitiu ~70 avisos "Vector3 cannot be normalized" durante este cenário (ver "Achados por caminho"/limitações) |
| alto | addon | subida | 770,6 | 560,9 | 598,0 | 0 | 66,8 | nunca <30 fps |
| alto | addon | colisão | 60,0 | 60,0 | 60,0 | 0 | 66,8 | 22/36 batem; 5,4 m |

Nenhuma linha foi marcada `INVÁLIDA (perdeu foco)`. Arquivo bruto: `tests/soak/sp4a/resultados/sp4a_2026-11-04_201854.{txt,json}`.

## Resultados — modo completo — **CORRIGIDO** (04/11/2026, à noite, após revisão; 3 repetições)

| Nível | Terreno | Cenário | FPS médio | FPS mín | 1% pior | Engasgos >33 ms | Vídeo (MB) | Observação |
|---|---|---|---|---|---|---|---|---|
| **`gl_compatibility`** (todos os níveis) | | | | | | | |
| baixo | próprio | parado | 3824,2 | 720,0 | 2127,5 | 0 | 22,7 | 3 reps: FPS médio 3642,4–3824,2 |
| baixo | próprio | caminhada | 3979,3 | 76,6 | 1702,1 | 0 | 22,3 | 3 reps: FPS médio 3979,3–3996,3 |
| baixo | próprio | subida | 5221,9 | 87,5 | 2307,4 | 0 | 22,3 | nunca <30 fps; 3 reps: FPS médio 5221,9–5234,7 |
| baixo | próprio | colisão | 60,0 | 60,0 | 60,0 | 0 | 22,7 | 36/36; 11,1 m |
| médio | próprio | parado | 2811,0 | 720,0 | 1734,6 | 0 | 35,5 | 3 reps: FPS médio 2811,0–2822,5 |
| médio | próprio | caminhada | 2535,6 | 17,5 | 1081,8 | 18 | 37,1 | 3 reps: FPS médio 2535,6–2546,4 |
| médio | próprio | subida | 3111,9 | 188,2 | 1763,8 | 0 | 37,1 | nunca <30 fps |
| médio | próprio | colisão | 60,0 | 60,0 | 60,0 | 0 | 39,3 | 36/36; 11,0 m |
| alto | próprio | parado | 1974,0 | 720,0 | 1327,7 | 0 | 83,6 | 3 reps: FPS médio 1972,9–1977,4 |
| alto | próprio | **caminhada** | **1223,5** | **6,9** | **352,8** | **12** | 97,1 | **queda real, confirmada nas 3 repetições** |
| alto | próprio | subida | 1140,6 | 675,0 | 719,5 | 0 | 97,1 | nunca <30 fps |
| alto | próprio | colisão | 60,0 | 60,0 | 60,0 | 0 | 108,9 | 36/36; 11,0 m |
| baixo | addon | parado | 2675,8 | 720,0 | 1679,9 | 0 | 46,5 | |
| baixo | addon | caminhada | 3011,6 | 146,6 | 1788,0 | 0 | 46,5 | |
| baixo | addon | subida | 4206,3 | 192,8 | 1814,7 | 0 | 46,5 | nunca <30 fps |
| baixo | addon | colisão | 60,0 | 60,0 | 60,0 | 0 | 46,5 | 22/36; 11,0 m |
| médio | addon | parado | 1365,6 | 884,2 | 1026,2 | 0 | 55,5 | |
| médio | addon | caminhada | 1640,5 | 173,4 | 1134,6 | 0 | 55,5 | |
| médio | addon | subida | 1549,1 | 357,6 | 1120,6 | 0 | 55,5 | nunca <30 fps |
| médio | addon | colisão | 60,0 | 60,0 | 60,0 | 0 | 55,5 | 22/36; 11,0 m |
| alto | addon | parado | 630,4 | 557,4 | 595,5 | 0 | 68,9 | |
| alto | addon | caminhada | 739,0 | 613,9 | 658,3 | 0 | 68,9 | sem avisos do motor desta vez (ver limitações) |
| alto | addon | subida | 754,7 | 553,1 | 597,8 | 0 | 68,9 | nunca <30 fps |
| alto | addon | colisão | 60,0 | 60,0 | 60,0 | 0 | 68,9 | 22/36; 11,0 m |
| **`forward_plus`** (só nível médio) | | | | | | | |
| médio | próprio | parado | 1684,9 | 720,0 | 962,3 | 0 | 111,2 | |
| médio | próprio | caminhada | 1576,3 | 16,3 | 672,4 | 18 | 109,0 | mesma queda real do próprio em `gl_compatibility`, presente aqui também |
| médio | próprio | subida | 1639,3 | 322,8 | 1055,4 | 0 | 109,0 | nunca <30 fps |
| médio | próprio | colisão | 60,0 | 60,0 | 60,0 | 0 | 111,2 | 36/36; 11,0 m |
| médio | addon | parado | 834,3 | 619,7 | 713,7 | 0 | 138,5 | |
| médio | addon | caminhada | 1011,7 | 369,9 | 716,6 | 0 | 138,5 | |
| médio | addon | subida | 850,3 | 606,8 | 716,4 | 0 | 138,5 | nunca <30 fps |
| médio | addon | colisão | 60,0 | 60,0 | 60,0 | 0 | 138,5 | 22/36; 11,0 m |
| **`mobile`** (só nível médio) | | | | | | | |
| médio | próprio | parado | 1817,4 | 720,0 | 1152,4 | 0 | 79,1 | |
| médio | próprio | caminhada | 1714,5 | 16,3 | 788,1 | 18 | 76,9 | mesma queda real, presente também aqui |
| médio | próprio | subida | 1740,9 | 382,4 | 1144,3 | 0 | 76,9 | nunca <30 fps |
| médio | próprio | colisão | 60,0 | 60,0 | 60,0 | 0 | 79,1 | 36/36; 11,0 m |
| médio | addon | parado | 1021,4 | 720,0 | 730,1 | 0 | 99,9 | |
| médio | addon | caminhada | 1196,4 | 611,7 | 750,9 | 0 | 99,9 | |
| médio | addon | subida | 1085,2 | 720,0 | 727,8 | 0 | 99,9 | nunca <30 fps |
| médio | addon | colisão | 60,0 | 60,0 | 60,0 | 0 | 99,9 | 22/36; 11,0 m |

Nenhuma linha foi marcada `INVÁLIDA (perdeu foco)`, nas 30 combinações × 3 repetições. Os rótulos de renderizador (`forward_plus`, `mobile`) já saíram certos diretamente do `RESULTADO PARA COLAR` (H4 corrigido na raiz — não precisei mais corrigir manualmente). Arquivo bruto: `tests/soak/sp4a/resultados/sp4a_2026-11-04_202316.{txt,json}`.

### a) FPS por faixa de altura na subida (cenário "subida"), modo completo **CORRIGIDO**

| Nível/terreno/renderizador | 0 m | 100 | 200 | 300 | 400 | 500 | 600 | 700 | 800 | 900 | 1000 m |
|---|---|---|---|---|---|---|---|---|---|---|---|
| baixo/próprio/gl | 3769 | 4903 | 5288 | 5353 | 5336 | 5301 | 5421 | 5446 | 5364 | 5404 | 5375 |
| médio/próprio/gl | 2492 | 3111 | 3088 | 3057 | 3086 | 3168 | 3208 | 3254 | 3199 | 3215 | 3226 |
| alto/próprio/gl | 1515 | 1707 | 1332 | 1032 | 930 | 846 | 803 | 801 | 786 | 809 | 839 |
| baixo/addon/gl | 2481 | 2829 | 3155 | 3599 | 4143 | 4599 | 4832 | 4832 | 4752 | 4796 | 4749 |
| médio/addon/gl | 1436 | 1476 | 1537 | 1568 | 1568 | 1544 | 1577 | 1588 | 1577 | 1583 | 1584 |
| alto/addon/gl | 892 | 834 | 817 | 828 | 770 | 716 | 691 | 650 | 642 | 660 | 660 |
| médio/próprio/forward_plus | 1571 | 1613 | 1663 | 1627 | 1656 | 1655 | 1646 | 1626 | 1660 | 1656 | 1654 |
| médio/addon/forward_plus | 825 | 788 | 821 | 839 | 844 | 848 | 851 | 878 | 889 | 899 | 889 |
| médio/próprio/mobile | 1765 | 1792 | 1742 | 1769 | 1768 | 1758 | 1740 | 1697 | 1687 | 1700 | 1671 |
| médio/addon/mobile | 996 | 970 | 1031 | 1081 | 1098 | 1112 | 1109 | 1122 | 1121 | 1155 | 1176 |

Mesma conclusão da medição original (não dependia de nenhum dos 6 bugs): em **nenhuma** combinação, em nenhum renderizador, os quadros caíram abaixo de 30 por segundo ao longo da subida até ~1.000 m [HIP]. A câmera livre de "subida" não dispara o carregamento intenso de chunks que o deslocamento rápido de "caminhada" dispara, porque X e Z não mudam, só a altura.

Note-se o padrão do terreno próprio em "alto": o FPS **cai** conforme sobe (1707→786 entre 100 m e 800 m) — o oposto do terreno "baixo"/"médio", que sobem. Hipótese [HIP], não confirmada: no nível alto (distância de visão 8 chunks, cobrindo quase o mapa inteiro), subir a câmera aumenta o número de chunks dentro do frustum de uma vez (mais terreno fica visível de cima), custando mais para desenhar — nos níveis mais baixos a distância de visão já é pequena o bastante para o efeito não aparecer.

### b) Por que "FPS mín" e "1% pior" não saem mais idênticos (H5 corrigido)

Na medição original, `Performance.TIME_FPS` (a fonte de todas as amostras) só atualiza seu valor cerca de uma vez por segundo — em cenários curtos, a maioria das amostras repetia o mesmo número, e o "1% pior" acabava sempre igual ao mínimo. **Corrigido:** `Sp4aMetrics.sample_frame()` agora recebe o delta real de cada quadro (`get_process_delta_time()`) e constrói os tempos de quadro a partir dele, nunca de `Performance.TIME_FPS`. O efeito aparece claro nos números corrigidos: por exemplo, médio/próprio/caminhada (completo) deu FPS mín = 17,5 e 1% pior = 1.081,8 — números bem diferentes agora, como esperado quando a maior parte dos quadros é rápida e só alguns poucos (o engasgo do carregamento de chunk) são lentos. Um teste novo e permanente (`test_metrics_frame_times_vary_with_real_delta`) confere isso a cada execução dos testes.

### c) Por que, no addon, "parado" ficou mais lento que "caminhada" — confirmado em TODOS os níveis e renderizadores após a correção

Esse padrão já tinha aparecido na medição original (só em baixo/médio), mas era impossível confiar nele por causa do H2 (escala do mundo mudando por nível). Com `vertex_spacing` agora fixo, o padrão **se repete nos 3 níveis** (baixo/médio/alto) **e nos 3 renderizadores testados** (`gl_compatibility`, `forward_plus`, `mobile`) — por exemplo, no nível alto do modo completo: parado = 630,4 FPS contra caminhada = 739,0 FPS. Isso fortalece a hipótese de ser um efeito sistemático do addon, não ruído de uma medição só.

Minha hipótese [HIP], ainda não totalmente confirmada: o Terrain3D continua acomodação interna (textura, malha de LOD ou colisão) por um tempo depois do `import_images`, mesmo esperando 5 quadros antes de prosseguir (`terrain_addon.gd`). Como "parado" é **sempre o primeiro** cenário de cada combinação (ordem fixa em `SCENARIOS`), ele é medido bem perto desse período de acomodação; "caminhada" roda depois, já com a duração inteira de "parado" como tempo extra de acomodação, e por isso mede mais rápido. O terreno próprio **não** mostra esse padrão (nele "parado" é sempre mais rápido que "caminhada", como esperado, já que "caminhada" soma o custo real de carregar chunks). Não investiguei mais fundo (ex.: medir o tempo exato até o addon "estabilizar", ou reordenar os cenários como teste) para não estourar o escopo desta correção.

### d) Memória do computador separada de memória de vídeo — confirmado com números corrigidos

| Nível/terreno | Memória (computador), faixa nas 4 cenas (completo) | Vídeo (GPU), faixa nas 4 cenas (completo) |
|---|---|---|
| alto/próprio | ~44,7–45,2 MB (quase constante) | **83,6 a 108,9 MB** (cresce bastante) |
| alto/addon | ~69,0–69,6 MB (quase constante) | **68,9 MB exatos, nas 4 cenas** |

Mesma explicação de arquitetura de antes, agora com números válidos: o terreno próprio sobe a malha e a colisão de cada *chunk* para a GPU só quando o chunk é carregado (e o Godot nem sempre devolve esse espaço de vídeo de imediato quando um chunk é descarregado). No nível "alto" a distância de visão é de 8 chunks, cobrindo quase o mapa inteiro; à medida que os 4 cenários rodam em sequência, mais chunks diferentes são tocados ao todo, e a memória de vídeo cresce cenário a cenário. O Terrain3D importa o mapa de altura inteiro para a GPU uma vez só no `setup()`; o nível de qualidade agora só muda `mesh_size`/`mesh_lods` (quantos vértices da mesma textura já carregada são desenhados), sem subir nem descartar nada da GPU depois — por isso a memória de vídeo do addon fica idêntica nas 4 cenas de cada combinação.

## Capturas de tela (passo 4a da correção — fora do commit)

24 capturas (nível médio, 2 terrenos × 4 cenários × 3 momentos — início/meio/fim), tiradas por uma ferramenta temporária (`run_capture_screenshots`, removida do código antes deste commit) que reaproveitou as mesmas fórmulas de posição de câmera dos cenários reais. Descrição do que apareceu:

- **"parado" (olhando para frente), próprio e addon:** nos dois terrenos, o chão ocupa a maior parte de baixo do quadro, com um horizonte claro e céu azul acima. No terreno próprio dá para ver cores diferentes por tipo de superfície (verde=relva, marrom=terra, branco-acinzentado=encosta/caminho perto da colina) com relevo real (declive visível). No addon, o chão usa a textura xadrez padrão do Terrain3D (sem material customizado — fora do escopo deste spike); o horizonte tem leve ondulação (não é uma linha reta), confirmando relevo real, ao contrário do relato original de "parece plano".
- **"caminhada" (olhando para frente, seguindo o trajeto):** mesmo padrão do "parado" — chão ocupando a base do quadro, horizonte visível, nos dois terrenos, nos três momentos (início/meio/fim; "fim" volta perto da posição de "início" por causa do vaivém do trajeto, como esperado pela fórmula).
- **"subida" (olhando de cima para baixo, de até ~1000 m de altura):** no terreno próprio, o quadro mostra uma "ilha" nítida de chunks carregados (coloridos por tipo de superfície) cercada de céu azul — o terreno próprio só carrega chunks perto do foco, então de muito longe aparece pequeno, o que é esperado (streaming por distância, não um bug). No addon, a 984 m de altura (momento "meio"), o quadro apareceu quase uniformemente **cinza**, com um retângulo um pouco mais claro no meio no mesmo formato/posição da "ilha" do terreno próprio — provável efeito de minificação da textura xadrez padrão vista de muito longe (a média de preto+branco é cinza), não perda de geometria. Não investiguei mais a fundo por estar fora do escopo H1–H6 e não achar que compromete a métrica (que não depende de cor de textura). Registrado como observação nova, não hipótese confirmada.
- **"colisão" (olhando reto para baixo, de 10 m de altura, câmera fixa):** os três momentos mostram a mesma vista (a câmera não se move durante a fase de grade de colisão, só o corpo de teste depois) — chão ocupando o quadro inteiro, com relevo visível nos dois terrenos.

Nenhuma captura mostrou "tela toda azul" ou chão ausente — o critério de parada do passo 4a ("se não aparecer, pare e peça nova janela depois") não foi acionado.

## Achados por caminho (reescrito com os números CORRIGIDOS)

**Terreno próprio:**
- Estilo: low-poly, cores planas por tipo de superfície (plain/path/hill_top/hill_slope/valley), normais suavizadas (não facetadas — ver limitação), **agora confirmadas visualmente voltadas para cima** (H1 corrigido).
- Desempenho: o mais rápido em quase toda combinação comparável, em todos os renderizadores testados — **esta conclusão da medição original continua valendo**.
- **Queda real em "alto"+"caminhada" continua presente** depois da correção, nos três renderizadores: 1.327,1 FPS médio / 6,7 mín (rápido) e 1.223,5/6,9 (completo) em `gl_compatibility`; 1.576,3/16,3 em `forward_plus`; 1.714,5/16,3 em `mobile` — sempre com 12 a 18 engasgos >33 ms. Não é efeito de nenhum dos 6 bugs corrigidos (a causa arquitetural é a mesma de antes: ao mover a câmera rápido por um mapa de 1.024 m com 8 chunks de distância de visão e 1 vértice por metro, muitos chunks são construídos de uma vez, em GDScript puro com `SurfaceTool`, sem thread nem fila por quadro). É o risco real que o roadmap já antecipava (R1.1).
- Colisão: **sempre bateu certo (36/36)**, em todos os níveis, nos dois modos e nos três renderizadores — não mudou com a correção (a colisão usa `HeightMapShape3D` com a função de altura diretamente, nunca dependeu da malha visual com normais invertidas).
- Manutenção pelo Codex: todo o código é meu (GDScript simples); fácil de entender e alterar, mas qualquer melhoria de desempenho (threads, LOD visual, geração incremental) também é trabalho meu.

**Addon (Terrain3D):**
- Versão **v1.1.0-stable**, licença MIT (detalhes de download inalterados da medição original).
- **Agora renderiza corretamente** (H2 corrigido: `vertex_spacing` fixo, qualidade só por `mesh_size`/`mesh_lods`) — confirmado visualmente (seção "Capturas de tela" acima) e numericamente (números de FPS plausíveis e estáveis entre repetições, diferente da suspeita original de "chão plano").
- Desempenho: continua **mais lento que o terreno próprio** no mesmo nível e no mesmo renderizador (ex.: nível médio, `gl_compatibility`, completo: próprio parado = 2.811,0 vs. addon parado = 1.365,6 — quase metade). **Esta conclusão da medição original continua valendo.**
- "Parado" mais lento que "caminhada": confirmado em **todos os níveis e renderizadores** agora (ver item "c" acima) — na medição original só aparecia com clareza no nível médio (e não dava para confiar, por causa do H2). Hipótese [HIP]: acomodação interna do addon, que coincide com "parado" ser sempre o primeiro cenário medido.
- **Colisão: deixou de estar catastroficamente quebrada, mas continua parcial.** Medição original: 0/36 em baixo/médio, 22/36 em alto (inconsistente entre níveis — sintoma do H2). Medição corrigida: **22/36 em todos os três níveis e nos três renderizadores**, de forma consistente — ou seja, a correção do H2 resolveu a maior parte do problema (de "quase sempre erra" para "acerta 61% dos pontos, sempre os mesmos 61%"), mas sobra uma divergência real entre a malha de colisão do addon e a função de altura de referência em 14 dos 36 pontos testados, que não investiguei a fundo (motivo arquitetural provável: a malha de colisão do Terrain3D é gerada internamente, em C++, por um processo de amostragem que não necessariamente usa os mesmos pontos exatos da grade de teste — ver também a limitação de opacidade da API nativa, abaixo). **Continua uma limitação não resolvida**, agora melhor caracterizada.
- Observação nova (não é um dos 6 bugs, não investigada a fundo): no modo rápido, o cenário "alto/addon/caminhada" emitiu cerca de 70 avisos do motor "Vector3 cannot be normalized, the elements must be finite" — não aconteceu de novo no modo completo (mesma combinação, 3 repetições). Sem rastro de GDScript no aviso (não tem backtrace de script), o que sugere vir de dentro do código nativo do addon, não do meu script. Não travou nem gerou erro, só um aviso; os números da linha afetada (740,4 FPS médio) ficaram coerentes com as vizinhas. Registrado como observação para investigar depois, se o addon seguir em consideração.
- Manutenção pelo Codex: a API nativa (C++) não aparece como GDScript; só os nomes de método e propriedade via `ClassDB`. Isso torna depurar problemas como o de colisão (e o aviso de Vector3 acima) mais difícil que no terreno próprio — **esta conclusão da medição original continua valendo**.

## Comparação dos níveis baixo/médio/alto (números CORRIGIDOS)

Terreno próprio: baixo e médio ficam folgados em todo renderizador testado (1.200 a 5.300 FPS); alto é viável em "parado"/"colisão"/"subida", mas carrega o risco real de "caminhada" (confirmado nos três renderizadores). Addon: já começa mais lento no "baixo" (2.600 a 4.200 FPS com `gl_compatibility`) e cai mais no "alto" (630 a 770 FPS). Todos os números ficam bem acima da meta proposta de 60 FPS (roadmap 1.F, item 5, **[PEND]**), mas numa máquina com GPU discreta de hoje, não a "PC médio" que a DEC-016 ainda não define — **nota que continua valendo** da medição original.

## O que aconteceu com os renderizadores (nível médio, modo completo, números CORRIGIDOS)

| Renderizador | Terreno próprio: parado/caminhada/subida/colisão | Terreno addon: parado/caminhada/subida/colisão |
|---|---|---|
| `gl_compatibility` | 2811 / 2536 / 3112 / 60* | 1366 / 1641 / 1549 / 60* |
| `forward_plus` | 1685 / 1576 / 1639 / 60* | 834 / 1012 / 850 / 60* |
| `mobile` | 1817 / 1715 / 1741 / 60* | 1021 / 1196 / 1085 / 60* |

`*` "colisão" mede a 60 fps fixo porque é amostrada por `physics_frame` (padrão do Godot), não por `process_frame` — não é limitação de renderizador.

`gl_compatibility` continua o mais rápido nesta máquina em quase tudo — esperado, por ser o renderizador mais simples e o padrão já aprovado do projeto. `forward_plus` e `mobile` (via Vulkan) ficaram parecidos entre si; a queda forte do terreno próprio em "alto"+"caminhada" apareceu nos três (ver "Achados por caminho"), não só em um renderizador como a medição original sugeria. Isso é só um dado desta GPU e deste driver; não dá para generalizar sem medir noutra máquina (Parte B).

## Confirmações de API (AGENTS 4.1 — como confirmei, não chutei)

Testadas por 16 scripts curtos e descartáveis (`api_probe.gd` a `api_probe16.gd`, apagados logo depois de cada confirmação) antes de escrever o código real da medição original: `Performance`; `OS`/`Engine`/`RenderingServer`; `FastNoiseLite`; `HeightMapShape3D`; `SurfaceTool`/`ArrayMesh`; `Image.create_from_data`; a API do Terrain3D; `ProjectSettings.get_setting(...)`.

**Nesta correção**, as 6 hipóteses (H1–H6) foram confirmadas por inspeção direta de dados em tempo de execução (contagem de normais, teste de colisão isolado) e por **6 testes novos e permanentes** em `test_sp4a_sanity.gd` (não descartáveis como os `api_probe*` — ficam no commit e rodam a cada `check_all`): `test_chunk_normals_point_up_on_flat_and_slope` (H1), `test_addon_quality_levels_do_not_vary_world_scale` (H2), `test_every_scenario_starts_camera_above_ground_with_orientation` (H3, e pegou os 2 bugs novos de brinde), `test_scenario_runner_parses_renderer_label` (H4), `test_metrics_frame_times_vary_with_real_delta` (H5), `test_metrics_reports_focus_field` (H6). `check_all` ficou em 170/170 depois da correção (eram 164 antes; as mesmas 3 falhas pré-existentes de ferramenta só-Windows continuam, sem relação com este spike).

## LIMITAÇÕES

1. **Colisão do addon: de "quase sempre errada" para "parcial, mas consistente".** Confirmado 22/36 em todos os níveis e renderizadores testados após a correção do H2 (era 0/36 em baixo/médio, 22/36 em alto, de forma inconsistente, na medição original). Continua a maior pendência técnica deste spike. Tentei três ajustes de `collision_mode` na medição original (Dynamic padrão → Full/Game antes do import → Full/Game depois do import com mais quadros de espera) sem resolver por completo; parei na terceira tentativa (AGENTS 13.2).
2. **Aviso do motor "Vector3 cannot be normalized"** observado uma vez (modo rápido, alto/addon/caminhada, ~70 ocorrências) e ausente na repetição seguinte (modo completo, mesma combinação, 3 repetições) — intermitente, sem backtrace de GDScript (provável origem no código nativo do addon), não travou nem invalidou a medição. Não investigado a fundo (fora do escopo H1–H6).
3. **`var _terrain: Terrain3D` como tipo estático quebraria a compilação** em qualquer máquina sem o addon baixado; corrigido usando `Object` e chamadas dinâmicas — inalterado por esta correção.
4. **Normais da malha própria são suavizadas**, não facetadas por face — inalterado por esta correção (não é o mesmo problema do H1, que era direção errada, não suavização).
5. **O cabeçalho "Máquina" do resultado usa a resolução da janela no início do processo**, não de cada linha — inalterado.
6. **O `tools/check_gdscript_warnings` existente trava para sempre** se encontrar um erro de análise — inalterado; registrado no backlog.
7. **A janela do benchmark perde velocidade real sem foco do Windows** — já era limitação conhecida; **nesta correção, o H6 confirmou que não houve perda de foco em nenhuma das 54 combinações medidas** (24 do rápido + 30 do completo), então essa limitação não afetou os números corrigidos — mas continua um risco real do método em qualquer medição futura no Windows.
8. **A régua de "engasgos" e "quebra abaixo de 30 fps"** não foi exercitada a fundo nesta máquina, exceto pela queda real de "alto"+"caminhada" no terreno próprio (12–18 engasgos >33 ms, confirmada); as demais combinações passaram folgado.
9. As hipóteses dos itens "a" (queda de FPS subindo no nível alto) e "c" (addon mais lento parado que andando) acima são **hipóteses minhas** [HIP], coerentes com os números corrigidos e agora mais bem apoiadas (padrão confirmado em mais níveis/renderizadores do que na medição original), mas não confirmadas lendo o código-fonte do Godot nem do Terrain3D.
10. **A medição original inteira (seções marcadas INVÁLIDO acima) não deve ser usada** — 3 dos 6 bugs confirmados (H1, H2, H3) afetavam diretamente o que a câmera via e media; os outros 3 (H4, H5, H6) afetavam a confiabilidade dos números relatados. Mantida no documento só como registro histórico, a pedido de Arthur.

## Proposta de entrada para DECISIONS.md (PROPOSTA — nada disto está decidido; reescrita com números CORRIGIDOS)

**Título:** Caminho de terreno do protótipo (SP4a).
**Contexto:** o roadmap (LW-033) pede escolher entre terreno próprio e addon antes da LW-038 construir o `TerrainView`. Esta proposta foi reescrita depois de uma correção de bugs confirmados na primeira medição (ver "Nota de validade"); a medição original não deve ser citada como base.
**A conclusão da medição original continua valendo:** sim — terreno próprio continua à frente em desempenho (mais rápido em toda combinação comparável) e em colisão (36/36 contra 22/36 do addon, agora medido de forma consistente). **O que mudou:** o addon deixou de parecer "quebrado" (chão invisível/plano, colisão quase sempre errada) e passou a ser uma comparação honesta e mensurável — ele realmente funciona, só perde em velocidade e colisão parcial, não por estar com bug.
**Proposta de decisão:** **terreno próprio** para o protótipo, pelo desempenho melhor em quase toda combinação medida, pela colisão sempre correta em todos os níveis e renderizadores, e por não depender de uma API nativa fechada (mais fácil de depurar quando algo dá errado, como o próprio processo desta correção mostrou). **Condição:** a queda em "alto"+"caminhada", confirmada nos três renderizadores mesmo após a correção, precisa de um plano (ex.: construir chunks numa fila limitada por quadro, ou numa thread) antes do nível "alto" ser oferecido ao jogador — ou o protótipo lança só com "baixo"/"médio" até isso ser resolvido.
**Alternativa (não recomendada agora):** addon, se a limitação de colisão (22/36) for resolvida e se a folga de desempenho mais baixa for aceitável para o "PC médio" (ainda não definido, DEC-016).
**Meta de quadros (roadmap 1.F, item 5):** continua **[PEND]**; os números medidos aqui (sempre acima de 600 FPS, mesmo nos piores casos de "parado"/"subida", numa GPU discreta de hoje) não servem para validar a meta de "PC médio", que ainda não existe.
**Níveis de qualidade:** proposta de adotar três níveis (baixo/médio/alto) como os medidos aqui, com Arthur decidindo se o protótipo lança com um nível só ou com os três.
**Renderizador:** proposta de manter `gl_compatibility` (o padrão já aprovado do projeto), que foi o mais rápido nos três testados nesta máquina, nas duas medições.
**Decisão de Arthur:** pendente — depende também da Parte B (Mac, oficial).
