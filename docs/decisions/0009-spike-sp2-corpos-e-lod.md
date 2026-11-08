# LW-071 — Spike SP2: corpos e LOD de NPCs

- **Status:** **proposta (Fase A pronta para revisão; medição de Arthur de 08/11/2026 registrada; a medição limpa ainda falta).** Ramo `spike-lw-071`, a partir de `origin/lw-069-lod-e-intencoes` em `f40209d` (o `main`, em `d7e233a`, ainda não continha a LW-069/LW-070 em 08/11/2026).
- **Data e tarefa:** 08/11/2026 (Brasília), LW-071 (roadmap Fase 2; arquitetura 6.2, 15.3 e 26.3, linha do SP2).
- **Rótulos:** **fato** (com origem), **[HIP]** (valor de trabalho do spike), **interpretação** (leitura minha de ponto aberto), **limitação**, **NÃO MEDIDO**.
- **Teto de código:** o envio estimava cerca de 1.200 linhas (parada em 1.560, +30%); o código ficou com **1.807 linhas em 13 arquivos `.gd`**. O teto era uma **estimativa de Claude**; Arthur **aceitou por escrito** em 08/11/2026 e fixou o novo teto de parada em 1.900 linhas e 16 arquivos.

## Contexto e problema (pergunta e critério)

Dá para alternar NPCs entre S1 (sem corpo) e S0 (com corpo e navegação) sem teleporte, sem duplicação e sem queda de quadros, antes do `NpcView` definitivo (LW-072)? Critério do roadmap: sem duplicar, sem teleporte, quadros estáveis (régua da **DEC-119, APROVADA**: média ≥ 60 quadros/s e nenhum quadro > 33 ms, no Mac de Arthur, na tomada, em release), abordagem de navegação escolhida e decisão registrada. Plano B (26.3): reduzir o raio S0, simplificar a navegação, menos NPCs corpóreos. Perguntas:

- **P-a** duplicação, corpo órfão, teleporte; **P-b** quadros e custo por NPC; **P-c** a navegação mais simples que passa; **P-d** passo do corpo × relógio e tempo limite; **P-e** raio S0 × terreno; **P-f** corpo quando o Intent vence ou o NPC sai de S0.

Decisões citadas: DEC-016 APROVADA (só o hardware de referência), DEC-035 APROVADA, DEC-039 PROPOSTA, **DEC-040 PENDENTE** (os 100 NPCs são [HIP] do spike, não fixam número), DEC-057 APROVADA, DEC-119 APROVADA, DEC-120 APROVADA.

## Método

- **Código descartável** em `tests/soak/sp2/` (13 `.gd` + `sp2_main.tscn`) e `tests/soak/run_sp2`. Nada em `src/`, `data/`, `scenes/`, `project.godot`, contratos, eventos ou autoloads.
- **Mundo próprio do spike (fato):** o jogo real registra o `npc`, mas não liga o LOD nem o protocolo S0 nem entrega o `npc` à ponte (limitações 3 e 5 da LW-069/LW-070 em `docs/modules/npc.md`). Ligar isso exigiria mexer em `src/`. O spike monta um `SimulationRunner` com o `NpcModule` (precedente `tests/unit/test_npc_intents.gd`) e os dados **reais** (terreno, locais, necessidades, catálogo, `lod_params.json`, `intent_params.json`) e chama só a API pública: `request_create_npc`, `request_set_focus`, `create_action_runner`, `configure_intents`, `peek_pending_intents`, `request_report_npc_result`, `request_report_npc_positions`, `intents.begin_embodied`, `lod.position_of/s0_ids` e `lod.place_position_cm` (membro público que "quem monta o módulo liga"). A cena real (`scenes/main.tscn`) dá chão, câmera e jogador. O relógio do mundo do spike **copia a pausa e a velocidade** do relógio do jogo (`peek_time`). **Consequência:** o custo medido é o do jogo **mais** um segundo mundo pequeno; a ponte não é exercitada (ela só repassa; testada na LW-070).
- **População e diretor:** 100 NPCs por `request_create_npc` (60 em A, 12 casas × 5; 40 em B, 8 × 5; locais de `data/world/places.json`). Rotina fixa trabalho → convívio → descanso → casa (`go_to_place`, `work`, `talk`, `rest`, `wait`), etapas desencontradas pelo índice (sem sorteio). S1 usa `begin`/`advance` do runner; S0 usa `begin_embodied` e só termina com o resultado do corpo.
- **Corpos e pool:** cápsula com nariz e cor por estado, sem física, altura por `TerrainData.peek_height`; pool pré-aquecido; relato de posições em lote a cada 6 quadros de física; resultados ARRIVED, DONE, BLOCKED com o `action_serial`.
- **Invariantes** (a cada 30 quadros e ao fim) e **detector de teleporte** (a cada quadro de física), como pedido.
- **Ensaios:** `alternancia` (rota pelo povoado A, 3 entradas e 3 saídas, mais 20 s na faixa de histerese), `carga` (max_s0 = 100 em código; dois focos; depois os 100 nascidos em A), `relogio` (1x, 2x, 4x, 8x e pausa, P1 depois P2), `ver` (3 min livres) e `headless`.

## Máquina e build

- Mac de Arthur (DEC-016), Godot 4.7.2 estável. **O que eu rodei:** só sem janela e em **depuração** (`build de depuração: sim`, driver opengl3 / gl_compatibility no headless). **Release, janela e tomada: NÃO EXECUTADOS** (são de Arthur). Binário de release encontrado: `$HOME/lw-release-probe/bin/godot_macos_release.universal`.

## Constantes [HIP] (todas em `Sp2Constants`)

| Grupo | Valor |
|---|---|
| Passo natural (P1) | 4 m/s × velocidade do relógio (= `PlayerBody.WALK_SPEED_MPS`) |
| P2 | teto 7 m/s × vel. (= `RUN_SPEED_MPS`), piso 0,8 m/s × vel. |
| Chegada / tolerância das invariantes | 0,3 m / 0,05 m |
| Teleporte | vel. máx. × delta × 1,5 + 0,05 m |
| Pool | 60 corpos pré-aquecidos |
| Invariantes | a cada 30 quadros |
| N1 | amostra a cada 2 m; limite 40° (`MAX_WALKABLE_SLOPE_DEGREES`) |
| N2 | célula 4 m, margem 64 m; bloqueia 40° e `rock` |
| Ensaios | carga 30 s; relógio 20 s por segmento; histerese 20 s; ver 180 s |
| Rota de alternância | pelo caminho z = 513 m: x 330 → 490 → 330 → 490 → 330; histerese entre x 440 e 452 |
| Foco fixo da carga | (800, 660) m, ID 900000 |

## Resultados de Claude (sem janela, depuração; só para comparar)

Duas execuções de `--headless` (alternância curta: x 330 → 490 → 330, cerca de 77 s):

| | Execução 1 | Execução 2 |
|---|---|---|
| Quadros: média / p99 / pior | 6,96 / 9,47 / 96,7 ms | 6,90 / 8,43 / 9,9 ms |
| Acima de 33 ms | 5 (20,7 s; 38,0 s; 41,9 s; 42,0 s; 42,1 s) | 0 |
| Invariantes | 0 em tudo (382 conferências) | 0 em tudo (385 conferências) |
| Pool | criados 60, retirados 114, devolvidos 64, pool vazio 0, perdidos 0 | igual |
| Corpos | 15 chegadas, 15 atrasadas, levado/previsto 2,00, 3,99 m/s | igual |
| Custo dos corpos | 135,5 µs por quadro de física | 40,2 µs (pior 0,66 ms) |
| Custo do mundo do spike | 436,3 µs por quadro | 160,0 µs (pior 3,88 ms) |

- **P-a (fato, teste e headless):** zero duplicados, órfãos, teleportes e posições fora (nascimento e saída). O teste (a) faz 20 ciclos de entrada e saída dos 100 NPCs sem nenhuma violação; corpos ativos == NPCs em S0 em todos os passos.
- **P-b:** custo por NPC, só depuração sem janela: com cerca de 50 em S0, 40 a 136 µs por quadro de física para todos (≈ 1 a 3 µs por NPC) mais 160 a 436 µs do mundo do spike. Release: ver "Medição de Arthur".
- **(c) Os 5 quadros acima de 33 ms da execução 1:** o pool **não** criou corpo novo (criados 60 = o pré-aquecimento, "pool vazio 0"; o pico foi 52). Os corpos foram reaproveitados ou saíram do pré-aquecimento. A causa dos quadros lentos **não sei**: não medi por seção naquele instante (o pior custo por seção só foi medido na execução 2, onde não houve quadro lento). Nos instantes 20,7 s e cerca de 42 s o jogador entrava no raio do povoado A (interpretação pelo tempo da rota).
- **max_s0 = 50** (dados) com 60 NPCs em A: 10 ficam em S1 mesmo perto; o limite trocou vagas no mesmo passo (pico de 52 corpos antes de eu passar a tratar as saídas antes das entradas).

## Navegação (P-c)

Rotas no terreno real, medidas por Arthur em release (execução 1; as execuções 2 e 3 e o "ver" deram os mesmos resultados de chegar ou não, de pontos e de distância; os tempos variam pouco). 5 repetições; a 1ª N2 de cada trecho preenche o cache de células. A r4 já é a versão (520, 300) → (880, 300), a do commit `1ac7aee`.

| Rota | N1 (reta) | N2 (grade A*) |
|---|---|---|
| r1 povoado A (75 m) | chega · 0,07 ms (pior 0,09) | chega, 81 m · média 4,44 ms, pior 21,43 ms |
| r2 de A a B (495 m) | chega · 0,45 ms (pior 0,46) | chega, 531 m · média 17,94 ms, pior 85,70 ms |
| r3 morro íngreme (LW-047A) | **sem caminho** · 0,02 ms | chega, 112 m, contornando · média 3,11 ms, pior 14,85 ms |
| r4 pedra (360 m) | chega **por cima de 82 amostras de pedra** · 0,32 ms | **sem caminho** · média 7,13 ms, pior 33,76 ms |

- **O pior da 1ª N2 em r2** foi 85,7 ms em release (126,6 ms na minha depuração). Pela conta sobre as médias, quase tudo é a montagem do cache de células (as chamadas seguintes custam cerca de 1 ms; conta minha, a separação exata NÃO MEDIDA).
- **N1** passa em tudo o que a rotina usa (r1, r2), recusa o morro (r3) e ignora a pedra (r4). **N2** contorna o morro, mas a 1ª rota de uma região dá um tranco de dezenas de ms. **N3: não construída.**
- **Limitação:** construções e água não são obstáculo em nenhuma candidata.

## Relógio × corpo (P-d)

- Contas à mão do teste (d) (`test_speed_policies_by_hand`, verde): P1 a 1x = 4 m/s; P1 a 8x = 4 × 8 = **32 m/s**; P2 a 1x, 10 m com 8 min = 10 ÷ (8 × 1,25) = **1 m/s**; P2 a 8x, 10 m com 8 min = 10 ÷ (8 × 1,25 ÷ 8) = **8 m/s**; P2 com teto, 100 m com 2 min = 40 m/s → **7 m/s** e chega atrasado (100 > 7 × 2,5 = 17,5 m); P2 com piso, 1 m com 10 min = 0,08 → **0,8 m/s**; P2 atrasado a 2x = 7 × 2 = **14 m/s**; pausa = **0** nas duas.
- **Interpretação:** "o corpo respeita a velocidade do relógio" = as velocidades são multiplicadas pela velocidade do relógio (a 8x o corpo anda 8 vezes mais rápido na tela). Assim, em minutos de jogo, o corpo cobre o mesmo chão em qualquer velocidade.
- **Conta no papel (não medida):** o `go_to_place` do S1 planeja 8400 cm/min (≈ 67 m/s reais a 1x). Nenhum corpo acompanha: toda caminhada em S0 chega atrasada (o headless viu 15 de 15, levado/previsto 2,00). O tempo limite é o fim planejado + 30 min. P1 cobre 4 × 1,25 = 5 m por minuto de jogo → ~155 m em 31 min; P2 no teto, 8,75 m/min → ~271 m. Logo, **r2 (495 m) vence o tempo limite nas duas**, em qualquer velocidade; as caminhadas do povoado (≤ ~80 m) cabem.
- **Tabela por velocidade e política:** ver "Medição de Arthur", abaixo. **P3:** ver a proposta DEC-123, abaixo.
- **Limitação (fato, `action_runner.gd`):** a duração do `go_to_place` sai de `x_cm/z_cm` lógicos; em S0 eles ficam velhos até a saída, então a duração prevista pode partir do lugar errado.

## Medição de Arthur (08/11/2026)

**Validade (fato, pelas saídas e pelo envio de Arthur):** release, Mac na tomada, commit `1ac7aee`.
- "ver" (180 s): quadros **INVÁLIDOS** ("a janela perdeu o foco"). Invariantes, rotas e protocolo valem.
- "medir", execuções 1 e 2: sem aviso de foco, quadros válidos. **Mas** as conversas A e B estavam provavelmente ativas (commits às 11h41, 11h43, 12h02 e 12h11). Por isso **a régua da DEC-119 não é dada aqui como medição oficial.**
- "medir", execução 3: quadros **INVÁLIDOS** em todos os ensaios. Dela valem só os contadores que não dependem de quadros; saíram iguais aos das execuções 1 e 2. **Nenhuma conclusão deste registro usa quadros da execução 3.**

### Quadros por ensaio (execuções 1 e 2; ms; "régua" = linha da DEC-119 que o teste imprime)

| Ensaio | Exec. 1: média / p99 / pior · >16,7 · >33 · régua | Exec. 2: média / p99 / pior · >16,7 · >33 · régua |
|---|---|---|
| Alternância (≈162 s) | 8,39 / 13,41 / **366,2** · 25 · 2 (366,2 em 16,0 s; 56,4 em 126,1 s) · fora | 8,38 / 13,27 / 44,7 · 27 · 2 (36,6 em 16,0 s; 44,7 em 88,8 s) · fora |
| Carga, dois focos (100 em S0) | 8,38 / 13,52 / 39,1 · 9 · 2 (ambos em 12,7 s) · fora | 8,33 / 12,01 / 12,7 · 0 · 0 · dentro |
| Carga, 100 aglomerados em A | 8,33 / 12,57 / 14,6 · 0 · 0 · dentro | 8,33 / 12,42 / 13,9 · 0 · 0 · dentro |
| Relógio P1 1x | 8,33 / 12,47 / 13,2 · 0 · 0 · dentro | 8,33 / 12,52 / 13,2 · 0 · 0 · dentro |
| Relógio P1 2x | 8,33 / 12,36 / 12,5 · 0 · 0 · dentro | 8,33 / 12,25 / 12,6 · 0 · 0 · dentro |
| Relógio P1 4x | 8,33 / 12,46 / 13,9 · 0 · 0 · dentro | 8,33 / 12,47 / 13,7 · 0 · 0 · dentro |
| Relógio P1 8x | 8,34 / 12,15 / 13,2 · 0 · 0 · dentro | 8,33 / 13,29 / 15,1 · 0 · 0 · dentro |
| Relógio P1 pausa | 8,33 / 11,95 / 12,2 · 0 · 0 · dentro | 8,33 / 13,18 / 13,5 · 0 · 0 · dentro |
| Relógio P2 1x | 8,33 / 12,19 / 13,2 · 0 · 0 · dentro | 8,33 / 13,27 / 13,9 · 0 · 0 · dentro |
| Relógio P2 2x | 8,33 / 12,18 / 13,4 · 0 · 0 · dentro | 8,34 / 13,06 / 19,2 · 1 · 0 · dentro |
| Relógio P2 4x | 8,33 / 12,08 / 12,3 · 0 · 0 · dentro | 8,35 / 13,41 / 35,4 · 2 · 1 (5,3 s) · fora |
| Relógio P2 8x | 8,33 / 12,20 / 13,1 · 0 · 0 · dentro | 8,33 / 13,56 / 14,1 · 0 · 0 · dentro |
| Relógio P2 pausa | 8,33 / 12,30 / 13,0 · 0 · 0 · dentro | 8,33 / 13,15 / 13,7 · 0 · 0 · dentro |
| Execução 3 | **INVÁLIDA em quadros** (não usada) | — |

- Custo (execuções 1 e 2, release, com 100 em S0 na maior parte do tempo): corpos 174,3 µs por quadro de física (pior 1,41 e 1,26 ms), cerca de 1,7 µs por NPC (conta minha); mundo do spike 282,7 e 272,0 µs por quadro (pior 15,71 e 6,43 ms).
- **Interpretação:** com os 100 corpos aglomerados e nos segmentos de relógio, quase tudo ficou dentro da linha nas duas execuções; o que sai da linha são **trancos isolados**, sobretudo na **entrada no povoado A** (alternância, aos 16,0 s, nas duas execuções). A média de 8,33 ms não mede folga (ver resposta 1).

### Contadores (as três execuções e o "ver")

| | Execuções 1, 2 e 3 | "ver" |
|---|---|---|
| Invariantes (duplicados, órfãos, contagem, nascimento fora, saída fora, teleportes) | **0 em tudo** (1804, 1805 e 2155 conferências) | 0 em tudo (587) |
| Pool | criados 100, retirados 380, devolvidos 280, pico 100, **pool vazio 40**, duplicados 0, perdidos 0 | criados 60, retirados 164, devolvidos 114, pico 50, pool vazio 0 |
| Corpos | 691 chegadas, 558 feitas, 0 bloqueadas, 0 velhas, 0 recusadas, 0 Intents sumidos, **613 atrasadas**, 354 teto curto, 0 herdadas | 65 chegadas, 65 atrasadas, levado/previsto 6,14 |
| Protocolo S0 ao fim | pending 100, discarded 0, timed_out 0 | pending 18, discarded 0, timed_out 0 |
| Histerese (20 s) | maior número de LodChanged de um NPC = 1 | NÃO MEDIDO |

### P1 contra P2 por velocidade do relógio (iguais nas três execuções, salvo onde indicado)

| Segmento (20 s reais) | Velocidade vista | Atrasadas / chegadas | Levado ÷ previsto | Teto curto | Tempos limite |
|---|---|---|---|---|---|
| P1 1x | 3,99 m/s | 15 / 15 | 5,33 | 0 | 0 |
| P1 2x | 7,97 m/s | 22 / 22 | 2,45 | 0 | 0 |
| P1 4x | 15,93 m/s | 92 / 92 | 7,21 (exec. 2: 7,22) | 0 | 0 |
| P1 8x | 31,55 m/s | 35 / 35 | 3,77 (exec. 3: 3,83) | 0 | 0 |
| P1 pausa | 0,00 | 0 / 0 | 0,00 | 0 | 0 |
| P2 1x | 6,98 m/s | 14 / 15 | 3,93 | 4 | 0 |
| P2 2x | 13,82 m/s | 25 / 50 | 3,00 | 50 | 0 |
| P2 4x | 27,76 a 27,78 m/s | 114 / 132 | 3,45 | 153 | 0 |
| P2 8x | 55,02 a 55,07 m/s | 134 / 168 | 3,85 | 147 | 0 |
| P2 pausa | 0,00 | 0 / 0 | 0,00 | 0 | 0 |

- **Fato:** P1 anda a 4 m/s × velocidade e **todas** as caminhadas chegam atrasadas; P2 anda quase sempre no teto (7 m/s × velocidade) e ainda atrasa a maioria. Nenhum tempo limite venceu nestes ensaios (nenhum fez a rota longa A → B; a conta de que ela venceria continua só no papel). Na pausa, os corpos pararam nas duas políticas.

## Respostas de Arthur ao "ver" (08/11/2026, 11h31, palavra por palavra)

1. Aparecem e somem de forma natural? — "NPCs normais, mas como eles ainda sao cilindros fica meio dificil de distinguir. Como o mapa é muito cru, nao da pra dizer que eles andam e somem de forma bem natural, mas da pro gasto, claro que eles vao interarir entre si, comigo, com o terreno etc."
2. O jeito de andar parece de gente? — "A caminhada, como eu disse, é de um cilindro, entao é dificil de afirmar qualquer coisa"
3. Algum NPC pulou de lugar ou apareceu duplicado? — "Nao verifiquei nada pulando ou duplicado, tirando o fato de todos serem iguais"
4. O jogo continua fluido com todo mundo em volta? — "Tudo normal. Nao percebi nenhum gap assim."
5. A velocidade combina com o relógio quando você acelera? — "Sim, velocidade deles aumentos e diminuiu normalmente."

**Ressalva:** na resposta 4, as conversas A e B estavam rodando junto.

## Perguntas de Arthur sobre a medição (respostas só por leitura do código e dos dados)

1. **8,33 ms constantes.** Fato: nem o `project.godot` nem o código do spike definem `max_fps` ou vsync (a busca por `max_fps`, `vsync` e `fps` não achou nada), então valem os padrões do Godot (vsync ligado, sem limite de quadros). 8,33 ms = 120 quadros/s. **Hipótese:** é o **ritmo da tela (vsync a 120 Hz)**, não o do jogo. Os 6,90 ms da execução 3 (sem foco) coincidem com os 6,90 a 6,96 ms que eu vi sem janela; a causa desse valor **NÃO SEI**. Consequência: a média só diz que o jogo acompanhou a tela; **a folga real não aparece na média**. O que informa são o percentil 99, o pior quadro e as contagens acima de 16,7 e 33 ms.
2. **Tranco aos 16,0 s da alternância.** Fato pelo código e pela saída: no começo da alternância o jogador anda do ponto de nascimento até x = 330 m, dentro do raio do povoado A. O pool já tinha 60 corpos, e nesse ensaio o limite é 50, então não cria corpo novo. O começo marca 0 em S0 e 76 pedaços de terreno; o meio, 22 em S0 e 132 pedaços. **Hipótese:** nesse instante coincidem muitas entradas em S0 (corpos tirados do pool e ficando visíveis) e o terreno indo de 76 para 132 pedaços, com colisão nos pedaços finos. O teste não mede por seção, então **NÃO SEI** qual parte pesa mais. Os 5 quadros lentos da minha execução sem janela também caíram em entradas no povoado A (20,7 s e cerca de 42 s, pelo tempo da rota). **Hipótese:** é o mesmo tipo de evento; não comprovado.
3. **"pool vazio 40".** Fato (`sp2_body_pool.gd`, função `take`): conta as vezes em que um corpo foi pedido sem corpo livre. Nesse caso o pool **cria um corpo novo na hora** e segue. O pool começa com 60; no ensaio de carga o limite sobe para 100 em S0, então 40 corpos foram criados na hora (criados 100). No "ver" o limite é 50, logo 0.
4. **N2 sem caminho na r4.** Fato: com margem de 64 m, a grade vai de x 456 a 944 m e de z 236 a 364 m, dentro do mapa de 1024 m; **a margem não corta** os pontos. A função devolve "sem caminho" tanto quando a célula de destino (880, 300) está bloqueada quanto quando nenhuma passagem cruza a faixa de pedra ou de encosta; a saída não separa os dois casos. A N1 viu 82 de cerca de 180 amostras em pedra. Qual dos dois casos é: **NÃO SEI.**
5. **Uma execução só, em release:** existe, pela variável `RUNS` do `run_sp2`: `RUNS=1 caffeinate -i tests/soak/run_sp2 --release` (rodado dentro da pasta `.worktrees/lw-071` do projeto). A numeração continua: o arquivo novo será `sp2_release_run_4.txt`.
6. A lista "o que o spike NÃO cobre" foi atualizada abaixo.

## P-e (raio S0 × terreno)

- Fato (`terrain_streaming.gd`): carga de 384 m (+64 de histerese), fino de 128 m (+64); colisão só em chunk fino (`terrain_view.gd`). S0 entra a 80 m e sai a 120 m do foco: dentro do fino, se o foco for o jogador. O corpo **não precisa** de colisão (segue `peek_height`), então não cai fora dela.
- Fora do raio fino, a malha grossa (passo de 4 m) difere da altura bilinear de 2 m: o corpo pode flutuar ou afundar um pouco. **NÃO MEDIDO.**
- Com um **segundo foco** (ensaio de carga, povoado B a ~495 m do jogador), os corpos de B ficam **fora do raio de carga** do terreno: sem chão desenhado. Funciona, mas desenharia gente no vazio se a câmera os visse.

## P-f (tempo limite e saída de S0)

- Fato (contrato LW-070 e testes): Intent vencido → a ação é cancelada sem efeito; o corpo vê o Intent sumir, fica parado e espera o próximo (contado como "Intents sumidos"); resultado tardio vira `NPC_RESULT_STALE` (teste (f)).
- NPC que sai de S0 no meio da caminhada: o corpo volta ao pool, o último relato vira a posição lógica e a ação segue abstrata até chegar (teste (g)); NPC removido devolve o corpo.
- NPC que entra em S0 no meio de uma ação abstrata não recebe Intent (limitação 4 da LW-070): o corpo anda até o destino só para não ficar parado, e quem termina a ação é o runner abstrato ("ações herdadas").

## Testes (cobertura pedida)

`tests/soak/sp2/test_sp2_logic.gd`, 8 testes, roda no `tools/check_all`: população real; (a)+(b) 20 ciclos, pool sem corpo novo depois do aquecimento e sem vazamento de nós; (c) teleporte; (d) políticas à mão; (e) N1 segue a altura e recusa r3, N2 contorna e diz "sem caminho"; (f) resultado velho e tempo limite; (g) saída no meio da caminhada e remoção; (h) determinismo (hash do mundo e contadores, duas vezes).

## O que o spike NÃO cobre

- Ligação com o jogo real e a ponte de verdade (conversa A); pensamento e população de verdade (LW-063, LW-067).
- Construções e água como obstáculo; animação de verdade; 300 NPCs; multidão; jogador parado muito tempo em área densa; outro hardware.
- **Quadros em release medidos com o Mac livre** (A, B e C paradas): ainda falta; a régua oficial depende disso.
- **Folga real por quadro:** o vsync esconde a folga na média (resposta 1).
- **Causa dos trancos** na entrada do povoado (pool, LOD ou terreno): sem medição por seção.
- **Caminhada longa A → B em S0** e o tempo limite: nenhum ensaio fez; continua só na conta.
- **Por que a N2 falha na r4** (resposta 4).
- **Sensação:** com cilindros iguais e mapa cru, Arthur disse ser difícil julgar a naturalidade e a caminhada.
- Corpos do 2º foco (povoado B) fora do raio de carga do terreno: sem chão desenhado.

## ROTEIRO PARA ARTHUR (ver)

1. Na tomada, tampa aberta, conversas A e B paradas. 2. Rode `tests/soak/run_sp2 --ver`. 3. Ande até o povoado A (a leste, pelo caminho) e volte. 4. Aperte H (painel), B (números), M (política), N (navegação). Velocidade do relógio: só 1 e 2 pelo jogo (4x e 8x ficam para o ensaio `relogio`). 5. Depois de 3 min, o resultado sai no Terminal.

Respostas: ver "Respostas de Arthur ao ver", acima.

## Plano B (26.3), se algum número falhar

Quadros fora: raio S0 de 80 → 50 m e `max_s0` de 50 → 30 (valores sugeridos [HIP]). Navegação cara: ficar na N1 e não usar a N2 em execução (só como cálculo pré-feito). Tempo limite em rotas longas: P3, ou tempo limite proporcional à distância (decisão de Arthur).

## Conclusão

- **P-a:** zero duplicados, órfãos e teleportes em todas as execuções (contadores, que valem nas três) e nos testes.
- **P-b:** com 100 em S0, os corpos custam cerca de 0,17 ms por quadro de física. Nas execuções 1 e 2 houve trancos isolados acima de 33 ms, sobretudo na entrada no povoado A. A régua oficial **não está dada**, porque a máquina não estava livre.
- **P-c e P-d:** decididas por Arthur (abaixo). **Relógio contra corpo:** a direção é a P3, registrada como proposta separada.

## Proposta de entrada para DECISIONS.md (número provisório DEC-122; SÓ proposta)

- **Título:** navegação e velocidade dos corpos S0 (resultado do SP2).
- **Contexto:** SP2 (este registro); decisão de Arthur pelo painel em 08/11/2026.
- **Decisão proposta:** (1) navegação **N1** (rota reta por pontos, recusa acima de 40°) por ora; revisar quando as construções entrarem como obstáculo (LW-073 e LW-074). (2) velocidade do corpo **P1**: passo natural de 4 m/s [HIP] × velocidade do relógio.
- **Justificativa:** a N1 passa nas rotas da rotina com 0,07 a 0,45 ms em release; a N2 dá trancos de até 85,7 ms na 1ª rota. A P1 é a mais simples, e Arthur viu a velocidade acompanhar o relógio; a P2 andou quase sempre no teto e ainda atrasou a maioria.
- **Consequências:** a N1 atravessa pedra e recusa morro íngreme sem desvio; a P1 chega sempre atrasada enquanto a DEC-123 não for resolvida.

## Proposta separada (número provisório DEC-123; SÓ proposta): relógio contra corpo

- **Problema (fato, medição de Arthur):** a simulação planeja a caminhada a 8400 cm por minuto de jogo (`src/sim/npc/actions/action_runner.gd:27`), cerca de 67 m/s a 1x; o corpo anda 4 m/s. Resultado: 613 de 691 chegadas atrasadas; com P1, 100% atrasadas, com levado ÷ previsto de 2,45 a 7,22.
- **Direção de Arthur: P3.** A simulação passa a acompanhar o corpo, com caminhada em torno de **500 cm/min [HIP]**. Conta: 500 cm/min = 5 m por minuto de jogo; a 1x, 1 minuto = 1,25 s, então 5 ÷ 1,25 = **4 m/s**. A rota A → B (495 m) = 495 ÷ 5 ≈ **99 min de jogo** ≈ 99 × 1,25 ≈ **124 s reais** a 1x. É direção, **não tarefa**: a velocidade só muda depois do teste de 30 dias e de DEC nova. O spike **não** muda nada.
- **O que mudaria (visto neste ramo):** todos os tempos de caminhada da simulação, que ficariam 16,8 vezes mais longos. Arquivos e valores:
  - `action_runner.gd:27` (`DEFAULT_WALK_SPEED_CM_PER_MIN = 8400`), o parâmetro padrão na linha 50 e o cálculo da linha 266;
  - `tests/unit/test_action_runner.gd` (a linha 79 usa o padrão; teste da linha 357);
  - `data/intent_params.json` (`intent_timeout_min` = 30 [HIP]). Com P3 ele vira margem sobre um plano já realista, mas o valor deve ser revisto.

  A mudança exige o `test_npc_life_30d` (citado em `docs/modules/npc.md`, LW-068; **o arquivo não está neste ramo: NÃO VERIFICADO**) e DEC nova. Outros pontos que dependam do tempo de caminhada: **NÃO VERIFICADO**.
- **Alternativas rejeitadas por Arthur:** manter os 8400 e aceitar o atraso; tempo limite proporcional ao corpo (quebra a regra de que o mundo não muda porque o jogador olha).

## Limitações

Minhas execuções: só depuração sem janela. Medição de Arthur: release na tomada, mas com A e B ativas (execuções 1 e 2) e sem foco (execução 3 e "ver"); a régua oficial falta. A ponte não foi usada; o mundo do spike soma ao custo do jogo.

- **Relação com DEC-NNN:** DEC-016, DEC-035, DEC-039, DEC-040, DEC-119, DEC-120.
