# LW-033 — Spike SP4a: terreno, desempenho e níveis de qualidade

- **Status:** **PRONTA PARA REVISÃO (Parte B no Mac concluída em 05/11/2026).** **PARTE A corrigida e completa** (PC, Windows): a primeira medição (04/11/2026, de manhã) foi invalidada numa revisão e **refeita** (04/11/2026, à noite) depois de corrigir 6 hipóteses de bug confirmadas (ver "Nota de validade" abaixo). A **Parte B (Mac de referência, DEC-016, medição oficial)** foi feita em 05/11/2026 e está na seção "PARTE B — Mac" abaixo. **A única decisão registrada aqui é a de Arthur sobre o caminho de terreno (seção "Decisão de Arthur"), dada por mensagem em 05/11/2026; ela AINDA NÃO está em `DECISIONS.md`.** Os números do PC são PROVISÓRIOS (só os marcados "CORRIGIDO" valem). Os do Mac são os oficiais, mas com limitações importantes (Godot em modo depuração e energia do Mac incerta), então servem para COMPARAR os terrenos, não para fixar meta de quadros.**
- **Pergunta (roadmap LW-033):** para um jogo pensado para PC médio (e, se der, qualidade maior em PCs bons), qual caminho de terreno é melhor — (1) terreno próprio (malha por script, por chunk) ou (2) addon (Terrain3D) — e em que nível de qualidade ele atinge a meta de quadros? Critérios: estilo low-poly, desempenho, colisão, facilidade de manutenção pelo Codex, e o teste de subida de câmera (DEC-080).
- **Código descartável:** `tests/soak/sp4a/` (10 scripts + 1 cena, 11 arquivos) e `tests/soak/run_sp4a [--modo rapido|completo|ver] [--terreno proprio|addon|ambos] [--qualidade baixo|medio|alto|todas] [--renderizador ...] [--cenario ...] [--repeticoes N] [--duracao S]`. Na Parte B o `run_sp4a` estava salvo no Git sem permissão de execução (modo 100644, vindo do Windows) e o macOS recusou rodá-lo (erro 126, nenhuma janela abriu); a correção mínima de portabilidade foi `chmod +x` (modo 100755), **sem mudar nenhuma linha de conteúdo**.

## Máquina(s) medida(s)

**PC (Windows, 04/11/2026) — PROVISÓRIO:** Windows 10.0.26200 · AMD Ryzen 5 8600G (12 núcleos) · AMD Radeon RX 9060 XT (placa discreta; a `Radeon 760M` integrada ao processador não foi a usada para renderizar) · 31.865 MB de RAM · Godot 4.7.2 estável oficial. A medição corrigida usou a mesma máquina, no mesmo dia à noite.

**Mac (referência, DEC-016, medição OFICIAL, 05/11/2026):** MacBook Air M3 (Apple M3, 8 núcleos, 16.384 MB de RAM, GPU integrada Apple M3 via Metal) · macOS 26.6.2 · Godot 4.7.2 estável oficial · **binário de depuração** (o título da janela mostra "(DEBUG)"; não é uma versão de release) · janela de 1152×648 no início do processo (cada nível muda a resolução durante a medição, como no PC). Detalhes e limitações na seção "PARTE B — Mac".

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

## PARTE B — Mac (medição OFICIAL, DEC-016), 05/11/2026

**Resumo em palavras simples.** O Mac confirmou o padrão do PC, com números bem menores: o terreno próprio tem FPS médio maior que o Terrain3D em todas as combinações comparáveis (9 de 9 em `gl_compatibility` e 6 de 6 nos outros dois renderizadores, nas duas máquinas); o terreno próprio **engasga ao andar** nos níveis médio e alto (11 a 19 quadros acima de 33 ms; o pior quadro chega a ~148 ms no nível alto); o Terrain3D anda liso (0 engasgos); e a colisão do addon acerta os mesmos 22 de 36 pontos do PC. O aviso do motor "Vector3 cannot be normalized" **não** apareceu nas duas medições do Mac (apareceu 2 vezes numa janela extra de observação). **Limitações pesadas:** Godot em modo depuração, energia do Mac incerta, comparação visual impossível (Terrain3D sem material). Por isso estes números servem para **comparar os terrenos**, **não** para fixar meta de quadros.

### Condições da medição (fatos, cada um com a fonte)

- **Sincronia com o PC:** ramo `spike-lw-033` na ponta `cea00a46594b6a7fcbd8f93d027d96b7ff120b9d` (a mesma da Parte A); `origin/main` em `821d5481fbe9d683a0f6b82f199d9b39660cb75e`. O Git do Mac enviou um teste de push (`--dry-run`) com sucesso antes de medir.
- **Addon:** Terrain3D v1.1.0-stable baixado de github.com, fora do Git (`addons/terrain_3d/`), 45.665.295 bytes e SHA-256 iguais aos da Parte A. O macOS carregou o addon sem bloqueio: importação sem janela com código 0 e `ClassDB.class_exists("Terrain3D")` verdadeiro.
- **Linha de base antes de medir:** `tools/check_all` **verde, 170 de 170 testes** (22 scripts; o mesmo número do PC) e `tools/check_gdscript_warnings` sem avisos (70 scripts).
- **Como rodou:** `caffeinate -dims tests/soak/run_sp4a --modo rapido` e depois `--modo completo`, VSync desligado, janela do Godot à frente e Arthur parado. **Nenhuma linha marcada "INVÁLIDA (perdeu foco)"** (rápido: 0 de 24; completo: 0 de 40).
- **Horários (hora do Mac, Brasília, UTC-3):** rápido 18:20:04 a 18:22:49 (2 min 45 s); completo 18:23:13 a 18:45:09 (21 min 56 s). A primeira tentativa do rápido (18:19:32) falhou na hora com erro 126, por causa do modo de arquivo do `run_sp4a` (ver "Código descartável"); não gerou resultado.
- **Energia (limitação, ver LIMITAÇÕES 11):** por linha de comando (`pmset`, `ioreg`, `system_profiler`), o macOS respondeu "sem adaptador" (bateria) em leituras feitas entre 18:05 e 18:19, antes das duas medições, e de novo às 19:37, depois delas. **Não li o adaptador durante cada modo.** A bateria ficou em 100% do início ao fim dos dois modos. Na captura de tela que Arthur enviou às 19:36, o ícone da bateria mostra o símbolo de carregamento, o que contradiz a leitura por linha de comando; **não resolvi a contradição**. Modo de Baixo Consumo: desligado. `pmset -g therm`: nenhum aviso térmico nem de desempenho registrado antes e depois de cada modo.
- **Arquivos brutos (novos, o PC não foi tocado):** `tests/soak/sp4a/resultados/sp4a_2026-11-05_182005.{txt,json}` (rápido) e `sp4a_2026-11-05_182313.{txt,json}` (completo). O completo tem 3 cabeçalhos de máquina (um por processo/renderizador) e 40 linhas.

### Resultados — Mac, modo rápido (1 repetição, renderizador `gl_compatibility`)

| Nível | Terreno | Cenário | FPS médio | FPS mín | 1% pior | Engasgos >33 ms | Vídeo (MB) | Observação |
|---|---|---|---|---|---|---|---|---|
| baixo | próprio | parado | 691,0 | 278,1 | 340,3 | 0 | 14,6 |  |
| baixo | próprio | caminhada | 783,8 | 111,2 | 412,8 | 0 | 14,2 |  |
| baixo | próprio | subida | 808,0 | 259,6 | 327,4 | 0 | 14,2 | nunca <30 fps |
| baixo | próprio | colisão | 60,0 | 60,0 | 60,0 | 0 | 14,6 | 36/36 batem; 5,6 m |
| médio | próprio | parado | 514,2 | 480,0 | 480,0 | 0 | 27,3 |  |
| médio | próprio | caminhada | 490,1 | 23,9 | 35,5 | 12 | 29,0 |  |
| médio | próprio | subida | 392,0 | 154,8 | 169,3 | 0 | 29,0 | nunca <30 fps |
| médio | próprio | colisão | 60,0 | 60,0 | 60,0 | 0 | 31,1 | 36/36 batem; 5,5 m |
| alto | próprio | parado | 332,3 | 246,3 | 249,2 | 0 | 75,5 |  |
| alto | próprio | caminhada | 265,6 | 6,7 | 7,0 | 12 | 89,0 |  |
| alto | próprio | subida | 123,8 | 60,5 | 60,9 | 0 | 89,0 | nunca <30 fps |
| alto | próprio | colisão | 60,0 | 60,0 | 60,0 | 0 | 100,8 | 36/36 batem; 5,4 m |
| baixo | addon | parado | 419,5 | 360,0 | 373,5 | 0 | 38,4 |  |
| baixo | addon | caminhada | 484,1 | 323,8 | 357,3 | 0 | 38,4 |  |
| baixo | addon | subida | 346,6 | 121,6 | 144,6 | 0 | 38,4 | nunca <30 fps |
| baixo | addon | colisão | 60,0 | 60,0 | 60,0 | 0 | 38,4 | 22/36 batem; 5,4 m |
| médio | addon | parado | 150,3 | 96,7 | 97,6 | 0 | 47,4 |  |
| médio | addon | caminhada | 145,4 | 79,2 | 82,4 | 0 | 47,4 |  |
| médio | addon | subida | 104,4 | 60,0 | 60,0 | 0 | 47,4 | nunca <30 fps |
| médio | addon | colisão | 60,0 | 60,0 | 60,0 | 0 | 47,4 | 22/36 batem; 5,5 m |
| alto | addon | parado | 84,3 | 84,0 | 84,0 | 0 | 60,7 |  |
| alto | addon | caminhada | 101,0 | 83,0 | 85,3 | 0 | 60,7 |  |
| alto | addon | subida | 83,7 | 60,0 | 60,0 | 0 | 60,7 | nunca <30 fps |
| alto | addon | colisão | 60,0 | 60,0 | 60,0 | 0 | 60,7 | 22/36 batem; 5,4 m |

Colunas como nas tabelas do PC. "Cenário colisão" tem FPS fixo em 60 porque é amostrado por `physics_frame` (60 por segundo), nas duas máquinas: **não é desempenho**.

### Resultados — Mac, modo completo (3 repetições; a linha mostra a 3ª repetição)

O arquivo guarda as estatísticas completas só da **última** repetição e, na observação, a faixa (mínimo a máximo) do FPS médio das 3.

| Nível | Terreno | Cenário | FPS médio | FPS mín | 1% pior | Engasgos >33 ms | Vídeo (MB) | Observação |
|---|---|---|---|---|---|---|---|---|
| **`gl_compatibility`** (todos os níveis) | | | | | | | | |
| baixo | próprio | parado | 689,7 | 391,4 | 514,9 | 0 | 14,6 | 3 reps: FPS médio 686,6–689,7 |
| baixo | próprio | caminhada | 748,9 | 75,9 | 361,0 | 0 | 14,2 | 3 reps: FPS médio 724,1–748,9 |
| baixo | próprio | subida | 672,4 | 230,1 | 333,1 | 0 | 14,2 | nunca <30 fps; 3 reps: FPS médio 592,6–672,4 |
| baixo | próprio | colisão | 60,0 | 60,0 | 60,0 | 0 | 14,6 | 36/36 batem; 11,1 m; 3 reps: FPS médio 60,0–60,0 |
| médio | próprio | parado | 528,7 | 366,0 | 465,2 | 0 | 27,3 | 3 reps: FPS médio 522,6–528,7 |
| médio | próprio | caminhada | 492,6 | 21,2 | 116,3 | 11 | 29,0 | 3 reps: FPS médio 489,2–492,6 |
| médio | próprio | subida | 285,2 | 113,0 | 121,2 | 0 | 29,0 | nunca <30 fps; 3 reps: FPS médio 285,2–388,4 |
| médio | próprio | colisão | 60,0 | 60,0 | 60,0 | 0 | 31,1 | 36/36 batem; 11,0 m; 3 reps: FPS médio 60,0–60,0 |
| alto | próprio | parado | 331,8 | 299,4 | 319,3 | 0 | 75,5 | 3 reps: FPS médio 328,9–331,8 |
| alto | próprio | caminhada | 253,8 | 6,8 | 60,1 | 12 | 89,0 | 3 reps: FPS médio 249,4–253,8 |
| alto | próprio | subida | 124,8 | 60,0 | 61,3 | 0 | 89,0 | nunca <30 fps; 3 reps: FPS médio 124,8–146,6 |
| alto | próprio | colisão | 60,0 | 60,0 | 60,0 | 0 | 100,8 | 36/36 batem; 11,0 m; 3 reps: FPS médio 60,0–60,0 |
| baixo | addon | parado | 207,8 | 106,9 | 108,9 | 0 | 38,4 | 3 reps: FPS médio 207,8–420,0 |
| baixo | addon | caminhada | 487,9 | 305,0 | 416,6 | 0 | 38,4 | 3 reps: FPS médio 485,1–489,0 |
| baixo | addon | subida | 364,5 | 110,2 | 118,7 | 0 | 38,4 | nunca <30 fps; 3 reps: FPS médio 364,5–367,8 |
| baixo | addon | colisão | 60,0 | 60,0 | 60,0 | 0 | 38,4 | 22/36 batem; 11,0 m; 3 reps: FPS médio 60,0–60,0 |
| médio | addon | parado | 130,9 | 85,0 | 88,8 | 0 | 47,4 | 3 reps: FPS médio 113,1–130,9 |
| médio | addon | caminhada | 144,9 | 92,4 | 99,0 | 0 | 47,4 | 3 reps: FPS médio 120,0–144,9 |
| médio | addon | subida | 151,5 | 65,6 | 77,1 | 0 | 47,4 | nunca <30 fps; 3 reps: FPS médio 140,1–152,8 |
| médio | addon | colisão | 60,0 | 60,0 | 60,0 | 0 | 47,4 | 22/36 batem; 11,0 m; 3 reps: FPS médio 60,0–60,0 |
| alto | addon | parado | 84,1 | 76,7 | 78,4 | 0 | 60,7 | 3 reps: FPS médio 84,1–84,8 |
| alto | addon | caminhada | 100,0 | 80,1 | 84,5 | 0 | 60,7 | 3 reps: FPS médio 100,0–100,4 |
| alto | addon | subida | 82,6 | 60,0 | 60,0 | 0 | 60,7 | nunca <30 fps; 3 reps: FPS médio 82,6–83,3 |
| alto | addon | colisão | 60,0 | 60,0 | 60,0 | 0 | 60,7 | 22/36 batem; 11,0 m; 3 reps: FPS médio 60,0–60,0 |
| **`forward_plus`** (só nível médio) | | | | | | | | |
| médio | próprio | parado | 399,2 | 267,6 | 352,5 | 0 | 140,6 | 3 reps: FPS médio 392,4–399,2 |
| médio | próprio | caminhada | 411,4 | 14,1 | 107,6 | 18 | 138,3 | 3 reps: FPS médio 406,3–411,4 |
| médio | próprio | subida | 472,7 | 52,9 | 285,2 | 0 | 138,3 | nunca <30 fps; 3 reps: FPS médio 463,2–472,7 |
| médio | próprio | colisão | 60,0 | 60,0 | 60,0 | 0 | 140,7 | 36/36 batem; 11,0 m; 3 reps: FPS médio 60,0–60,0 |
| médio | addon | parado | 193,2 | 169,3 | 178,8 | 0 | 165,8 | 3 reps: FPS médio 193,2–195,8 |
| médio | addon | caminhada | 199,5 | 173,2 | 179,5 | 0 | 165,8 | 3 reps: FPS médio 199,5–222,8 |
| médio | addon | subida | 164,3 | 140,4 | 143,2 | 0 | 165,8 | nunca <30 fps; 3 reps: FPS médio 160,0–164,3 |
| médio | addon | colisão | 60,0 | 60,0 | 60,0 | 0 | 165,8 | 22/36 batem; 11,0 m; 3 reps: FPS médio 60,0–60,0 |
| **`mobile`** (só nível médio) | | | | | | | | |
| médio | próprio | parado | 604,8 | 98,5 | 367,9 | 0 | 103,7 | 3 reps: FPS médio 566,5–610,1 |
| médio | próprio | caminhada | 561,1 | 13,3 | 93,1 | 19 | 101,4 | 3 reps: FPS médio 549,3–561,1 |
| médio | próprio | subida | 794,3 | 196,5 | 374,8 | 0 | 101,4 | nunca <30 fps; 3 reps: FPS médio 793,4–808,1 |
| médio | próprio | colisão | 60,0 | 60,0 | 60,0 | 0 | 103,7 | 36/36 batem; 11,0 m; 3 reps: FPS médio 60,0–60,0 |
| médio | addon | parado | 258,6 | 84,9 | 172,8 | 0 | 123,3 | 3 reps: FPS médio 258,6–260,0 |
| médio | addon | caminhada | 248,3 | 33,1 | 57,1 | 0 | 123,3 | 3 reps: FPS médio 248,3–306,4 |
| médio | addon | subida | 190,0 | 57,7 | 59,8 | 0 | 123,3 | nunca <30 fps; 3 reps: FPS médio 190,0–203,5 |
| médio | addon | colisão | 60,0 | 60,0 | 60,0 | 0 | 123,3 | 22/36 batem; 11,0 m; 3 reps: FPS médio 60,0–60,0 |

### Renderizadores — Mac, nível médio, modo completo (FPS médio)

| Renderizador | Terreno próprio: parado/caminhada/subida/colisão | Terreno addon: parado/caminhada/subida/colisão |
|---|---|---|
| `gl_compatibility` | 529 / 493 / 285 / 60* | 131 / 145 / 151 / 60* |
| `forward_plus` | 399 / 411 / 473 / 60* | 193 / 199 / 164 / 60* |
| `mobile` | 605 / 561 / 794 / 60* | 259 / 248 / 190 / 60* |

`*` "colisão" mede 60 fps fixo (amostrada por `physics_frame`), não é limitação de renderizador.

### FPS por faixa de altura na subida — Mac, modo completo (3ª repetição)

| Nível/terreno/renderizador | 0 | 100 | 200 | 300 | 400 | 500 | 600 | 700 | 800 | 900 | 1000 m |
|---|---|---|---|---|---|---|---|---|---|---|---|
| baixo/próprio/gl | 580 | 679 | 849 | 720 | 720 | 647 | 634 | 622 | 612 | 605 | 625 |
| médio/próprio/gl | 255 | 231 | 218 | 227 | 241 | 271 | 299 | 317 | 332 | 357 | 367 |
| alto/próprio/gl | 200 | 158 | 113 | 91 | 87 | 84 | 84 | 92 | 110 | 131 | 131 |
| baixo/addon/gl | 174 | 180 | 182 | 209 | 246 | 333 | 398 | 437 | 485 | 490 | 354 |
| médio/addon/gl | 197 | 161 | 143 | 146 | 146 | 139 | 139 | 141 | 146 | 151 | 148 |
| alto/addon/gl | 121 | 107 | 86 | 75 | 71 | 69 | 68 | 66 | 65 | 66 | 66 |
| médio/próprio/forward_plus | 429 | 432 | 410 | 411 | 423 | 457 | 471 | 517 | 539 | 557 | 562 |
| médio/addon/forward_plus | 151 | 151 | 153 | 160 | 164 | 165 | 166 | 174 | 174 | 176 | 178 |
| médio/próprio/mobile | 811 | 1062 | 787 | 657 | 680 | 778 | 698 | 746 | 844 | 844 | 632 |
| médio/addon/mobile | 163 | 165 | 175 | 185 | 203 | 184 | 181 | 203 | 212 | 208 | 204 |

Em **nenhuma** combinação, em nenhum renderizador, os quadros médios por faixa caíram abaixo de 30 por segundo até ~1.000 m [HIP: só até 1.000 m foi testado]. O padrão do PC se repete: no nível alto o terreno próprio **perde** FPS ao subir (200 → 84 entre 0 e 500 m) e depois recupera (131 a 1.000 m); o addon no nível alto também cai (121 → 66). Causa **não investigada** [HIP].

### Engasgos em "caminhada" e pior quadro (Mac)

"Pior quadro (ms)" = 1000 ÷ FPS mín, ou seja, o quadro mais lento daquela repetição.

| Modo | Renderizador | Nível | Terreno | Engasgos >33 ms | FPS mín | Pior quadro (ms) | p99 (ms) |
|---|---|---|---|---|---|---|---|
| rápido | `gl_compatibility` | baixo | próprio | 0 | 111,2 | 9,0 | 1,7 |
| rápido | `gl_compatibility` | médio | próprio | 12 | 23,9 | 41,8 | 11,1 |
| rápido | `gl_compatibility` | alto | próprio | 12 | 6,7 | 149,2 | 134,6 |
| rápido | `gl_compatibility` | baixo | addon | 0 | 323,8 | 3,1 | 2,8 |
| rápido | `gl_compatibility` | médio | addon | 0 | 79,2 | 12,6 | 11,7 |
| rápido | `gl_compatibility` | alto | addon | 0 | 83,0 | 12,1 | 11,5 |
| completo | `gl_compatibility` | baixo | próprio | 0 | 75,9 | 13,2 | 2,4 |
| completo | `gl_compatibility` | médio | próprio | 11 | 21,2 | 47,1 | 4,2 |
| completo | `gl_compatibility` | alto | próprio | 12 | 6,8 | 148,0 | 8,3 |
| completo | `gl_compatibility` | baixo | addon | 0 | 305,0 | 3,3 | 2,4 |
| completo | `gl_compatibility` | médio | addon | 0 | 92,4 | 10,8 | 10,0 |
| completo | `gl_compatibility` | alto | addon | 0 | 80,1 | 12,5 | 11,7 |
| completo | `forward_plus` | médio | próprio | 18 | 14,1 | 70,9 | 4,2 |
| completo | `forward_plus` | médio | addon | 0 | 173,2 | 5,8 | 5,6 |
| completo | `mobile` | médio | próprio | 19 | 13,3 | 75,5 | 4,9 |
| completo | `mobile` | médio | addon | 0 | 33,1 | 30,2 | 16,7 |

- O terreno próprio engasga em "caminhada" em **todos os renderizadores** testados no nível médio e em `gl_compatibility` no nível alto, (completo: 11 no médio e 12 no alto em `gl_compatibility`, 18 em `forward_plus`, 19 em `mobile`; rápido: 12 e 12). No nível baixo, 0. É o mesmo padrão do PC (18 no médio e 12 no alto). O arquivo guarda só a 3ª repetição, então **não verifiquei** se o número se repete entre as repetições.
- O Terrain3D teve **0 engasgos** em todas as combinações; o pior quadro dele fica em 3 a 30 ms (30 ms em `mobile`, o único perto do limite de 33 ms).
- Hipótese [HIP] da Parte A, **continua não confirmada**: construção de muitos pedaços de terreno de uma vez, em GDScript, sem fila nem thread. Não investiguei (esta tarefa só mede).

### Repetições e aquecimento (a 1ª comparada com a 3ª)

- **O que NÃO consigo fazer:** comparar a 1ª com a 3ª repetição **da mesma combinação**. O arquivo de resultado guarda só a 3ª (as estatísticas completas) e a faixa (mínimo a máximo) do FPS médio das 3; não guarda qual repetição foi qual. Medir isso exigiria mudar o código do spike, o que esta tarefa não autoriza. Cada combinação tem 1 rodada de aquecimento descartada antes das 3 medidas.
- **O que consigo dizer:** das 40 linhas do completo, **32 têm variação menor que 10%** entre as 3 repetições (28 delas menor que 3%, sendo 10 as linhas de colisão, que ficam em 60 fps fixos). **8 têm variação maior que 10%**; nelas a 3ª repetição ficou no **pior** extremo da faixa em 5 e no **melhor** em 3:

| Renderizador | Nível | Terreno | Cenário | 3ª repetição (FPS médio) | Faixa das 3 | Variação | 3ª está |
|---|---|---|---|---|---|---|---|
| `gl_compatibility` | baixo | próprio | subida | 672,4 | 592,6–672,4 | 11,9% | no melhor extremo |
| `gl_compatibility` | médio | próprio | subida | 285,2 | 285,2–388,4 | 26,6% | no pior extremo |
| `gl_compatibility` | alto | próprio | subida | 124,8 | 124,8–146,6 | 14,9% | no pior extremo |
| `gl_compatibility` | baixo | addon | parado | 207,8 | 207,8–420,0 | 50,5% | no pior extremo |
| `gl_compatibility` | médio | addon | parado | 130,9 | 113,1–130,9 | 13,6% | no melhor extremo |
| `gl_compatibility` | médio | addon | caminhada | 144,9 | 120,0–144,9 | 17,2% | no melhor extremo |
| `forward_plus` | médio | addon | caminhada | 199,5 | 199,5–222,8 | 10,5% | no pior extremo |
| `mobile` | médio | addon | caminhada | 248,3 | 248,3–306,4 | 19,0% | no pior extremo |

- **Conclusão (inconclusiva, [HIP]):** não há sinal sistemático de queda de desempenho com o tempo (a 3ª não é sempre a pior), e o `pmset` não registrou aviso térmico. Não dá para excluir uma limitação térmica leve: o MacBook Air não tem ventoinha e as ferramentas que mostrariam isso exigem acesso de administrador, que não foi usado. A linha de maior variação (**baixo/addon/parado**, 50,5%) combina com a hipótese [HIP] da Parte A: "parado" é o primeiro cenário medido depois de montar o addon, e o addon continua se acomodando.

### Avisos e erros do motor (contagem)

| Onde | "Vector3 cannot be normalized" | "free_editor_textures requires Assets be saved" (Terrain3D, inofensivo) | Outros |
|---|---|---|---|
| Modo rápido (24 linhas) | 0 | 1 | 0 |
| Modo completo (40 linhas, 3 processos) | 0 | 3 (um por processo) | 0 |
| Janelas extras de observação, terreno próprio (2) | 0 | – | 0 |
| Janelas extras de observação, Terrain3D (2; a 2ª foi fechada após ~9 s, saída normal) | **2** (na 2ª janela, nível médio, trajeto de caminhada) | 2 (1 em cada janela) | 0 |

Ou seja, o aviso do PC (intermitente, sem backtrace de GDScript) **reapareceu no Mac uma vez**, fora das medições oficiais. Os resultados dessas janelas extras não entram nas tabelas e seus arquivos foram apagados (eram meus). Não investiguei a origem.

### Colisão (Mac)

- **Terreno próprio: 36 de 36** alturas batem, em todos os níveis e renderizadores, no rápido e no completo.
- **Terrain3D: 22 de 36**, **em todos os níveis e renderizadores**, no rápido e no completo; a cápsula de teste andou ~5,4 m (rápido) e ~11 m (completo) sem travar. **Idêntico ao PC.** Não foi reinvestigado (ver LIMITAÇÕES 13).

### PC × Mac — lado a lado (colunas separadas por máquina; nunca misturadas)

PC = **provisório** (`sp4a_2026-11-04_202316`, modo completo corrigido). Mac = **oficial** (`sp4a_2026-11-05_182313`, modo completo). `gl_compatibility`; o cenário "colisão" fica de fora (60 fps fixos nas duas máquinas).

| Nível | Terreno | Cenário | FPS médio PC (provisório) | FPS médio Mac (oficial) | FPS mín PC | FPS mín Mac | Engasgos >33 ms PC | Engasgos >33 ms Mac |
|---|---|---|---|---|---|---|---|---|
| baixo | próprio | parado | 3824,2 | 689,7 | 720,0 | 391,4 | 0 | 0 |
| baixo | próprio | caminhada | 3979,3 | 748,9 | 76,6 | 75,9 | 0 | 0 |
| baixo | próprio | subida | 5221,9 | 672,4 | 87,5 | 230,1 | 0 | 0 |
| médio | próprio | parado | 2811,0 | 528,7 | 720,0 | 366,0 | 0 | 0 |
| médio | próprio | caminhada | 2535,6 | 492,6 | 17,5 | 21,2 | 18 | 11 |
| médio | próprio | subida | 3111,9 | 285,2 | 188,2 | 113,0 | 0 | 0 |
| alto | próprio | parado | 1974,0 | 331,8 | 720,0 | 299,4 | 0 | 0 |
| alto | próprio | caminhada | 1223,5 | 253,8 | 6,9 | 6,8 | 12 | 12 |
| alto | próprio | subida | 1140,6 | 124,8 | 675,0 | 60,0 | 0 | 0 |
| baixo | addon | parado | 2675,8 | 207,8 | 720,0 | 106,9 | 0 | 0 |
| baixo | addon | caminhada | 3011,6 | 487,9 | 146,6 | 305,0 | 0 | 0 |
| baixo | addon | subida | 4206,3 | 364,5 | 192,8 | 110,2 | 0 | 0 |
| médio | addon | parado | 1365,6 | 130,9 | 884,2 | 85,0 | 0 | 0 |
| médio | addon | caminhada | 1640,5 | 144,9 | 173,4 | 92,4 | 0 | 0 |
| médio | addon | subida | 1549,1 | 151,5 | 357,6 | 65,6 | 0 | 0 |
| alto | addon | parado | 630,4 | 84,1 | 557,4 | 76,7 | 0 | 0 |
| alto | addon | caminhada | 739,0 | 100,0 | 613,9 | 80,1 | 0 | 0 |
| alto | addon | subida | 754,7 | 82,6 | 553,1 | 60,0 | 0 | 0 |

Fora de `gl_compatibility` (nível médio, modo completo):

| Renderizador | Terreno | Cenário | FPS médio PC (provisório) | FPS médio Mac (oficial) | Engasgos >33 ms PC | Engasgos >33 ms Mac |
|---|---|---|---|---|---|---|
| `forward_plus` | próprio | parado | 1684,9 | 399,2 | 0 | 0 |
| `forward_plus` | próprio | caminhada | 1576,3 | 411,4 | 18 | 18 |
| `forward_plus` | próprio | subida | 1639,3 | 472,7 | 0 | 0 |
| `forward_plus` | addon | parado | 834,3 | 193,2 | 0 | 0 |
| `forward_plus` | addon | caminhada | 1011,7 | 199,5 | 0 | 0 |
| `forward_plus` | addon | subida | 850,3 | 164,3 | 0 | 0 |
| `mobile` | próprio | parado | 1817,4 | 604,8 | 0 | 0 |
| `mobile` | próprio | caminhada | 1714,5 | 561,1 | 18 | 19 |
| `mobile` | próprio | subida | 1740,9 | 794,3 | 0 | 0 |
| `mobile` | addon | parado | 1021,4 | 258,6 | 0 | 0 |
| `mobile` | addon | caminhada | 1196,4 | 248,3 | 0 | 0 |
| `mobile` | addon | subida | 1085,2 | 190,0 | 0 | 0 |

**O que se repete nas duas máquinas:** (1) o terreno próprio tem FPS médio maior que o addon em **9 de 9** combinações; (2) o terreno próprio engasga em "caminhada" (médio e alto) e o addon não; (3) colisão: próprio 36 de 36, addon 22 de 36; (4) o addon cai muito do nível baixo para o alto (parado: PC 2.676 → 630; Mac 208 → 84). **O que muda:** o Mac fez entre ~8% e ~21% do FPS médio do PC (o PC tem placa de vídeo dedicada; o Mac tem GPU integrada). Mesmo assim, o Mac passa dos 60 FPS médios em todas as combinações, mas com **folga pequena no nível alto do addon** (83 a 100 FPS médios) e com mínimos de **60,0** em linhas como alto/addon/subida.

### Observações do desenvolvedor sobre o Mac (fatos e hipóteses rotulados)

1. **Piso de 60,0 FPS.** Várias linhas mostram FPS mín e "1% pior" exatamente **60,0** (e a janela do modo ver mostrou "FPS: 61"). Hipótese [HIP], **não testada**: sincronização com a tela de 60 Hz do macOS mesmo com o VSync desligado no Godot. Por isso um "mínimo de 60,0" **não deve ser lido** como o limite do renderizador.
2. **Modo depuração.** O título da janela mostra "(DEBUG)": as medições (Mac e, pelo mesmo `run_sp4a`, provavelmente o PC) usaram o binário do Godot com recursos de depuração, mais lento que um build de release. A Parte A não registrou o tipo de binário que usou [limitação].
3. **Modo ver e níveis.** No modo ver as teclas 1, 2 e 3 só mudam o espaçamento de vértice dos pedaços de terreno **construídos depois** do aperto; o terreno já carregado não é refeito até sair do campo de visão (~380 m). O modo ver também não muda distância de visão, resolução, sombras nem suavização das bordas. Logo, ele **não** mostra os níveis como a medição automática os aplica, e o "tudo parece igual" de Arthur deve ser lido com isso em mente. O modo ver mostra **só o terreno próprio** (não tem o addon).
4. **"Frestinha" entre níveis vizinhos [HIP].** Na captura de tela de Arthur (nível médio, modo ver), numa faixa do caminho há uma faixa de terreno mais lisa e, nas bordas dela, **quatro pontinhos azul-claros** (o céu aparecendo). Hipótese [HIP], **não confirmada por teste controlado**: frestas entre pedaços vizinhos com espaçamento de vértice diferente (Arthur trocou de nível durante o voo e cada pedaço novo nasce no nível escolhido). O terreno próprio **não tem tratamento de emenda** entre níveis diferentes; com um nível único as bordas coincidem e não racham. A captura é local e **fica fora do commit**.
5. **Textura.** O terreno próprio usa cores chapadas por tipo de superfície (só teste, sem arte). O Terrain3D foi usado **sem material**, então mostra só o xadrez padrão. A comparação visual entre os dois **não foi possível**.
6. **Ordem do Mac nos renderizadores (nível médio).** Aqui `gl_compatibility` **não** foi o mais rápido: `mobile` ficou acima dele nos três cenários e nos dois terrenos; `forward_plus` ficou acima dele com o addon nos três cenários e, com o terreno próprio, só em "subida". No PC `gl_compatibility` ganhava quase sempre. Cuidado: `gl_compatibility` foi o **primeiro** processo do modo completo (e o mais longo), e os três rodaram em sequência, então efeito de ordem ou de tempo **não pode ser excluído** [HIP]. A proposta de manter `gl_compatibility` (padrão já aprovado do projeto) **continua válida pela simplicidade**, mas a justificativa "foi o mais rápido" **não vale mais no Mac**.

### Observações de Arthur (palavras dele, sem interpretar; modo ver e janelas extras, 05/11/2026)

- **(0) o chão aparece, com relevo, ocupando a parte de baixo da tela?** — "ja andei por tudo,. Chao aparece, relevo tbm"
- **(a) o estilo low-poly agrada em cada nível?** — "Pra mim tudo parece igual."
- **(b) a diferença entre baixo, médio e alto é visível?** — "Não vejo diferença" (resposta por botão)
- **(c) em que altura começa a ver defeito?** — "Nao é defeito exatamente, é essa textura crua e feia, mas acho que é só de teste,n é?" (enviou uma captura de tela, guardada só localmente)
- **(d) o terreno próprio e o Terrain3D parecem diferentes? Qual prefere?** — "nesse terrain 3d aparece apenas quadriculado, sem cores nem nada...." e, depois: "se vc nao colocar os 2 iguais, como vou comparar? Nao da pra comparar um terreno xadres com um que simula terreno de verdade..." **Registro: sem base para preferência visual** (o Terrain3D estava sem material).
- **(e) alguma queda de fluidez que sentiu?** — "nao senti nada"
- **(f) calibragem da câmera:** **sem observação de Arthur** (pulada por ele; a câmera média elevada já foi decidida e será calibrada na LW-046).

### Decisão de Arthur — caminho de terreno (mensagem de 05/11/2026)

**Arthur escolheu o TERRENO PRÓPRIO para o protótipo.** Decisão **dele**, dada por mensagem em 05/11/2026, **ainda não registrada em `DECISIONS.md`** (ver "Proposta de entrada para DECISIONS.md — versão da Parte B"). Condições:

(a) resolver os engasgos ao andar antes de oferecer o nível "alto" ao jogador;
(b) confirmar ou corrigir a "frestinha" entre níveis de detalhe vizinhos;
(c) o terreno fica só na camada de apresentação, para poder trocar depois sem mexer na simulação;
(d) reavaliar o Terrain3D na LW-040 ou na revisão arquitetural da Fase 1 (LW-053) se ocorrer qualquer um destes gatilhos: os engasgos persistirem depois de construir os pedaços aos poucos; as frestas não tiverem conserto simples; ou a decisão do tamanho do mundo (DEC-055) exigir um mapa de vários quilômetros antes da Fase 5;
(e) a primeira medição do jogo real deve ser em modo release e com o Mac na tomada.

**Não decididos por Arthur (seguem como estavam):** DEC-058 (terreno em pedaços com níveis de detalhe) segue **PROPOSTA** em validação; DEC-055 (dimensões do mundo) segue **PENDENTE**; **meta de quadros** e **níveis de qualidade** seguem como **PROPOSTA**.

## Achados por caminho (reescrito com os números CORRIGIDOS — medição do PC; os do Mac estão na "PARTE B" acima)

**Terreno próprio:**
- Estilo: low-poly, cores planas por tipo de superfície (plain/path/hill_top/hill_slope/valley), normais suavizadas (não facetadas — ver limitação), **agora confirmadas visualmente voltadas para cima** (H1 corrigido).
- Desempenho: o mais rápido em quase toda combinação comparável, em todos os renderizadores testados — **esta conclusão da medição original continua valendo**.
- **Queda real em "alto"+"caminhada" continua presente** depois da correção, nos três renderizadores: 1.327,1 FPS médio / 6,7 mín (rápido) e 1.223,5/6,9 (completo) em `gl_compatibility`; 1.576,3/16,3 em `forward_plus`; 1.714,5/16,3 em `mobile` — sempre com 12 a 18 engasgos >33 ms. Não é efeito de nenhum dos 6 bugs corrigidos (a causa arquitetural é a mesma de antes: ao mover a câmera rápido por um mapa de 1.024 m com 8 chunks de distância de visão e 1 vértice por metro, muitos chunks são construídos de uma vez, em GDScript puro com `SurfaceTool`, sem thread nem fila por quadro). É o risco real que o roadmap já antecipava (R1.1).
- Colisão: **sempre bateu certo (36/36)**, em todos os níveis, nos dois modos e nos três renderizadores — não mudou com a correção (a colisão usa `HeightMapShape3D` com a função de altura diretamente, nunca dependeu da malha visual com normais invertidas).
- Manutenção pelo Codex: todo o código é meu (GDScript simples); fácil de entender e alterar, mas qualquer melhoria de desempenho (threads, LOD visual, geração incremental) também é trabalho meu.

**Addon (Terrain3D):**
- Versão **v1.1.0-stable**, licença **MIT**. Endereço: `https://github.com/TokisanGames/Terrain3D/releases/tag/v1.1.0-stable`. Arquivo `Terrain3D_v1.1.0-stable.zip`, 45.665.295 bytes, SHA-256 `51b78bc758f5759cbc8eaaab14e5cf4e8661717e265fdd760f5abf945f15b243`. (Estes dados constavam da primeira versão deste documento, no commit `129d6a4`, e se perderam na reescrita da Parte A; foram restaurados na Parte B. O download feito no Mac, em 05/11/2026, tem exatamente o mesmo tamanho e o mesmo SHA-256.)
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

`gl_compatibility` continua o mais rápido nesta máquina em quase tudo — esperado, por ser o renderizador mais simples e o padrão já aprovado do projeto. `forward_plus` e `mobile` (via Vulkan) ficaram parecidos entre si; a queda forte do terreno próprio em "alto"+"caminhada" apareceu nos três (ver "Achados por caminho"), não só em um renderizador como a medição original sugeria. Isso é só um dado desta GPU e deste driver; não dá para generalizar sem medir noutra máquina (Parte B). **Parte B feita:** no Mac `gl_compatibility` **não** foi o mais rápido em tudo (ver "Observações do desenvolvedor sobre o Mac", item 6).

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
11. **Modo depuração e energia do Mac incerta (vale para o modo rápido e, por inferência, para o completo).** A medição do Mac foi feita com o Godot em modo depuração (título "(DEBUG)"). O macOS, por linha de comando, respondeu "sem adaptador" (bateria) em leituras feitas **antes do modo rápido** (18:05 a 18:19) e **depois do completo** (19:37); **não li o adaptador durante cada modo**, mas a bateria ficou em 100% do início ao fim dos dois modos e não houve leitura intermediária. A captura de tela de Arthur às 19:36 mostra o ícone de carregamento, o que contradiz a linha de comando e **não foi resolvido**. Estes números servem para **COMPARAR** os terrenos, **não** para fixar a meta de quadros.
12. **A comparação visual não foi possível.** O Terrain3D foi usado sem material (só o xadrez padrão); o terreno próprio tem cores chapadas pintadas pelo spike. Arthur não teve base para uma preferência visual. A parte opcional de pintar os dois igual **não foi feita** (não autorizada).
13. **As 3 tentativas de `collision_mode` foram feitas na medição original (INVÁLIDA), com o mundo em escala errada (H2).** O 22/36 **não foi reinvestigado** depois do conserto do H2. Hipótese [HIP], levantada por Claude no chat com Arthur e **NÃO testada** pelo dev na Parte B: desalinhamento entre a grade do teste e a do Terrain3D, e não defeito do addon.
14. **O terreno foi testado só em ~1 km²** (1.024 × 1.024 m [HIP], chunks de 64 m [HIP]). **Não há prova para um mundo maior.**
15. **O modo ver não representa os níveis como a medição os aplica** (nível só vale para pedaços novos; sem distância de visão, resolução, sombras nem suavização) e **só mostra o terreno próprio**. Respostas de Arthur sobre a diferença entre níveis têm este limite.
16. **O arquivo de resultado guarda só a 3ª repetição** (estatísticas completas) e a faixa do FPS médio; a comparação da 1ª com a 3ª repetição **não é calculável** sem mudar o código do spike.
17. **O aviso "Vector3 cannot be normalized" reapareceu no Mac uma vez**, numa janela extra (Terrain3D, nível médio, caminhada, 2 ocorrências), fora das medições oficiais, sem backtrace de GDScript. Não investigado.
18. **A "frestinha" entre níveis vizinhos é hipótese [HIP]** vista numa captura de tela, não confirmada por teste controlado (ver "Observações do desenvolvedor sobre o Mac", item 4).
19. **O Mac tem 16 GB de RAM e GPU integrada**, e é uma única máquina de referência; o hardware mínimo (DEC-016) continua **PENDENTE** e nada aqui o define.

## Proposta de entrada para DECISIONS.md — versão da Parte A (SUPERADA pela versão da Parte B, no fim deste documento; mantida só como registro)

**Título:** Caminho de terreno do protótipo (SP4a).
**Contexto:** o roadmap (LW-033) pede escolher entre terreno próprio e addon antes da LW-038 construir o `TerrainView`. Esta proposta foi reescrita depois de uma correção de bugs confirmados na primeira medição (ver "Nota de validade"); a medição original não deve ser citada como base.
**A conclusão da medição original continua valendo:** sim — terreno próprio continua à frente em desempenho (mais rápido em toda combinação comparável) e em colisão (36/36 contra 22/36 do addon, agora medido de forma consistente). **O que mudou:** o addon deixou de parecer "quebrado" (chão invisível/plano, colisão quase sempre errada) e passou a ser uma comparação honesta e mensurável — ele realmente funciona, só perde em velocidade e colisão parcial, não por estar com bug.
**Proposta de decisão:** **terreno próprio** para o protótipo, pelo desempenho melhor em quase toda combinação medida, pela colisão sempre correta em todos os níveis e renderizadores, e por não depender de uma API nativa fechada (mais fácil de depurar quando algo dá errado, como o próprio processo desta correção mostrou). **Condição:** a queda em "alto"+"caminhada", confirmada nos três renderizadores mesmo após a correção, precisa de um plano (ex.: construir chunks numa fila limitada por quadro, ou numa thread) antes do nível "alto" ser oferecido ao jogador — ou o protótipo lança só com "baixo"/"médio" até isso ser resolvido.
**Alternativa (não recomendada agora):** addon, se a limitação de colisão (22/36) for resolvida e se a folga de desempenho mais baixa for aceitável para o "PC médio" (ainda não definido, DEC-016).
**Meta de quadros (roadmap 1.F, item 5):** continua **[PEND]**; os números medidos aqui (sempre acima de 600 FPS, mesmo nos piores casos de "parado"/"subida", numa GPU discreta de hoje) não servem para validar a meta de "PC médio", que ainda não existe.
**Níveis de qualidade:** proposta de adotar três níveis (baixo/médio/alto) como os medidos aqui, com Arthur decidindo se o protótipo lança com um nível só ou com os três.
**Renderizador:** proposta de manter `gl_compatibility` (o padrão já aprovado do projeto), que foi o mais rápido nos três testados nesta máquina, nas duas medições.
**Decisão de Arthur:** (versão da Parte A) pendente — **superada**: Arthur escolheu o terreno próprio em 05/11/2026 (ver a seção "Decisão de Arthur" e a proposta abaixo).

## Proposta de entrada para DECISIONS.md — versão da Parte B (para Arthur ou o auditor registrarem; o dev NÃO escreve em `DECISIONS.md`)

**DEC-057 — Terreno: solução própria ou addon** (a entrada hoje está PENDENTE; proposta de nova redação):

| Campo | Conteúdo |
|---|---|
| **Status** | **APROVADA — decisão de Arthur, dada por mensagem em 05/11/2026** (só passa a valer no registro quando Arthur ou o auditor a escreverem em `DECISIONS.md`) |
| **Contexto** | A câmera seamless (DEC-026) exige terreno em níveis de detalhe. O spike SP4a (LW-033, `docs/decisions/0007-spike-sp4a-terreno.md`) mediu terreno próprio e addon (Terrain3D v1.1.0-stable, MIT) no PC (provisório) e no Mac de referência (oficial, DEC-016). Nas duas máquinas o terreno próprio foi mais rápido em 9 de 9 combinações e acertou a colisão em 36 de 36; o addon andou liso (0 engasgos) mas acertou 22 de 36 na colisão, causa não investigada. O terreno próprio engasgou ao andar (médio e alto). A comparação visual não foi possível (addon sem material). Medição do Mac em modo depuração, com energia incerta: serve para comparar, não para fixar meta de quadros. |
| **Decisão** | **Terreno próprio** (malha por script, por chunk) para o protótipo. |
| **Justificativa** | Mais rápido nas duas máquinas, colisão sempre correta, código nosso e fácil de depurar pelo Codex, sem depender de API nativa fechada. Não é uma escolha sobre o visual final. |
| **Consequências (condições de Arthur)** | (a) resolver os engasgos ao andar antes de oferecer o nível "alto" ao jogador; (b) confirmar ou corrigir a "frestinha" entre níveis de detalhe vizinhos; (c) o terreno fica só na camada de apresentação, para poder trocar depois sem mexer na simulação; (d) reavaliar o Terrain3D na LW-040 ou na revisão arquitetural da Fase 1 (LW-053) se ocorrer qualquer um destes gatilhos: os engasgos persistirem depois de construir os pedaços aos poucos; as frestas não tiverem conserto simples; ou a decisão do tamanho do mundo (DEC-055) exigir um mapa de vários quilômetros antes da Fase 5; (e) a primeira medição do jogo real deve ser em modo release e com o Mac na tomada. |
| **Data / versão** | RM 0.1 LW-033 · SP4a Parte A (PC, 04/11/2026) e Parte B (Mac, 05/11/2026) · mensagem de Arthur de 05/11/2026 |
| **Relações** | DEC-026, DEC-028, DEC-055, DEC-058, DEC-080 |

**Sem decisão de Arthur (seguem como estavam):**
- **DEC-058** (terreno em chunks com níveis de detalhe): segue **PROPOSTA** em validação (a "frestinha" entre níveis vizinhos é hipótese [HIP] a confirmar).
- **DEC-055** (dimensões do mundo): segue **PENDENTE**. O spike só testou ~1 km² [HIP].
- **Meta de quadros** (roadmap 1.F, item 5): segue **PROPOSTA/[PEND]**, não decidida. Os números do Mac (modo depuração, energia incerta, piso de 60,0 FPS visto) não servem para fixá-la.
- **Níveis de qualidade** (baixo/médio/alto, constantes em `quality_levels.gd`): seguem **PROPOSTA**; todos os valores são [HIP].
- **Renderizador:** proposta de manter `gl_compatibility` (padrão já aprovado do projeto) **pela simplicidade**; no Mac ele não foi o mais rápido em tudo (ver "Observações do desenvolvedor sobre o Mac", item 6).
- **Hardware mínimo** (DEC-016): segue PENDENTE.
